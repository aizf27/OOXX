import { GameKind, GameSession, MatchRecord, MatchResult, Settings } from '../model/AppModels';
import { Board, Mark, Move, oppositeMark, Puzzle } from '../model/GameModels';
import { RecordRepository } from '../repository/GameRepository';
import { GameEngine } from '../service/GameEngine';
import { LogicBoard, LogicPuzzleEngine } from '../service/LogicPuzzleEngine';

export enum MoveHandling {
  LOCAL_APPLIED = 'LOCAL_APPLIED',
  REMOTE_REQUIRED = 'REMOTE_REQUIRED',
  REJECTED = 'REJECTED'
}

export class MoveDecision {
  readonly handling: MoveHandling;
  readonly message: string;

  constructor(handling: MoveHandling, message: string) {
    this.handling = handling;
    this.message = message;
  }
}

export class GameStore {
  private readonly engine: GameEngine;
  private readonly records: RecordRepository;
  private history: GameSession[] = [];
  private recorded: boolean = false;
  session: GameSession = new GameSession();
  result: MatchResult | null = null;
  settings: Settings = new Settings();

  constructor(records: RecordRepository, engine: GameEngine = new GameEngine()) {
    this.records = records;
    this.engine = engine;
  }

  setSettings(settings: Settings): void {
    this.settings = settings;
  }

  fallbackPuzzle(): Puzzle {
    return this.engine.fallbackPuzzle();
  }

  generateUniquePuzzle(): Puzzle {
    return this.engine.generateUniquePuzzle();
  }

  start(kind: GameKind, puzzle: Puzzle | null = null): void {
    this.history = [];
    this.recorded = false;
    this.result = null;
    if (kind === GameKind.AI_5X5) {
      this.session = new GameSession(new Board(5, 4), Mark.X, Mark.X, kind);
      return;
    }
    if (kind === GameKind.LOGIC_6X6) {
      const logic = LogicPuzzleEngine.classic6x6();
      this.session = new GameSession(new Board(), Mark.X, Mark.X, kind, 0,
        LogicPuzzleEngine.status(logic), null, null, false, logic, []);
      return;
    }
    if (kind === GameKind.DAILY) {
      const daily = puzzle ?? this.engine.fallbackPuzzle();
      this.session = new GameSession(daily.board, daily.next, daily.next, kind, 0,
        '请选择唯一最优的一步', daily.answer);
      return;
    }
    let message = '轮到你了';
    if (kind === GameKind.NETWORK || kind === GameKind.BLUETOOTH) {
      message = '等待跨端连接';
    } else if (kind === GameKind.LOCAL) {
      message = '轮到 X';
    }
    this.session = new GameSession(new Board(), Mark.X, Mark.X, kind, 0, message);
  }

  async play(move: Move): Promise<MoveDecision> {
    if (this.session.kind === GameKind.NETWORK || this.session.kind === GameKind.BLUETOOTH) {
      return new MoveDecision(MoveHandling.REMOTE_REQUIRED, '落子需由连接层发送并等待权威状态');
    }
    if (this.session.kind === GameKind.LOGIC_6X6) {
      return this.playLogicMove(move);
    }
    if (this.result !== null || this.session.isAiThinking || !this.session.board.isEmpty(move)) {
      return new MoveDecision(MoveHandling.REJECTED, '当前不能在此处落子');
    }
    if (this.engine.winner(this.session.board) !== null || this.engine.isDraw(this.session.board)) {
      return new MoveDecision(MoveHandling.REJECTED, '对局已经结束');
    }
    this.history.push(this.session);
    if (this.session.kind === GameKind.DAILY) {
      const solved = this.session.puzzleAnswer !== null && this.session.puzzleAnswer.equals(move);
      const board: Board = this.session.board.place(move, this.session.turn);
      this.session = this.copySession(board, this.session.turn, 1,
        solved ? '唯一解正确！' : '这一步不是唯一最优解', solved, false);
      await this.finish(solved ? MatchResult.WIN : MatchResult.LOSS);
      return new MoveDecision(MoveHandling.LOCAL_APPLIED, this.session.message);
    }
    const board: Board = this.session.board.place(move, this.session.turn);
    const nextTurn = oppositeMark(this.session.turn);
    const isAi = this.session.kind === GameKind.AI_3X3 || this.session.kind === GameKind.AI_5X5;
    this.session = this.copySession(board, nextTurn, this.session.moves + 1,
      isAi ? '对手思考中…' : `轮到 ${nextTurn}`, null, isAi);
    if (await this.completeIfNeeded()) {
      return new MoveDecision(MoveHandling.LOCAL_APPLIED, this.session.message);
    }
    return new MoveDecision(MoveHandling.LOCAL_APPLIED, this.session.message);
  }

  private playLogicMove(move: Move): MoveDecision {
    const current = this.session.logicBoard;
    if (current === null || this.result !== null) {
      return new MoveDecision(MoveHandling.REJECTED, '当前不能在此处落子');
    }
    const next = current.cycle(move);
    if (next === current) {
      return new MoveDecision(MoveHandling.REJECTED, '题面不可修改');
    }
    this.history.push(this.session);
    const updated = this.session.copy({
      logicBoard: next,
      logicHistory: this.session.logicHistory.concat([current]),
      moves: this.session.moves + 1,
      message: LogicPuzzleEngine.status(next)
    });
    this.session = updated;
    if (LogicPuzzleEngine.isSolved(next)) {
      this.finish(MatchResult.WIN).catch(() => {
        // ignore
      });
    }
    return new MoveDecision(MoveHandling.LOCAL_APPLIED, this.session.message);
  }

  async playAiTurn(): Promise<boolean> {
    if (!this.session.isAiThinking || this.result !== null) {
      return false;
    }
    const move = this.engine.bestMove(this.session.board, this.session.turn);
    if (move === null) {
      this.session = this.copySession(this.session.board, this.session.turn, this.session.moves,
        '没有可用落点', null, false);
      return false;
    }
    const board: Board = this.session.board.place(move, this.session.turn);
    this.session = this.copySession(board, oppositeMark(this.session.turn), this.session.moves + 1,
      '轮到你了', null, false);
    await this.completeIfNeeded();
    return true;
  }

  undo(): boolean {
    if (this.result !== null || this.session.isAiThinking || this.session.kind === GameKind.DAILY ||
      this.session.kind === GameKind.NETWORK || this.session.kind === GameKind.BLUETOOTH || this.history.length === 0) {
      return false;
    }
    if (this.session.kind === GameKind.LOGIC_6X6) {
      const previous = this.session.logicHistory[this.session.logicHistory.length - 1];
      if (previous === undefined) {
        return false;
      }
      this.session = this.session.copy({
        logicBoard: previous,
        logicHistory: this.session.logicHistory.slice(0, -1),
        moves: Math.max(0, this.session.moves - 1),
        message: LogicPuzzleEngine.status(previous)
      });
      return true;
    }
    const previous = this.history.pop();
    if (previous === undefined) {
      return false;
    }
    this.session = previous;
    return true;
  }

  async surrender(): Promise<MoveHandling> {
    if (this.session.kind === GameKind.NETWORK || this.session.kind === GameKind.BLUETOOTH) {
      return MoveHandling.REMOTE_REQUIRED;
    }
    if (this.result !== null) {
      return MoveHandling.REJECTED;
    }
    await this.finish(MatchResult.LOSS);
    return MoveHandling.LOCAL_APPLIED;
  }

  applyAuthoritativeState(session: GameSession, result: MatchResult | null): void {
    this.session = session;
    this.result = result;
    if (result !== null) {
      this.saveRecord(result).catch(() => {
        // ignore persistence errors
      });
    }
  }

  private copySession(board: Board, turn: Mark, moves: number, message: string,
    puzzleSolved: boolean | null, isAiThinking: boolean): GameSession {
    return new GameSession(board, turn, this.session.playerMark, this.session.kind, moves, message,
      this.session.puzzleAnswer, puzzleSolved, isAiThinking, this.session.logicBoard, this.session.logicHistory);
  }

  private async completeIfNeeded(): Promise<boolean> {
    const winner = this.engine.winner(this.session.board);
    if (winner !== null) {
      const result = this.session.kind === GameKind.LOCAL || winner === this.session.playerMark
        ? MatchResult.WIN : MatchResult.LOSS;
      await this.finish(result);
      return true;
    }
    if (this.engine.isDraw(this.session.board)) {
      await this.finish(MatchResult.DRAW);
      return true;
    }
    return false;
  }

  private async finish(result: MatchResult): Promise<void> {
    this.result = result;
    await this.saveRecord(result);
  }

  private async saveRecord(result: MatchResult): Promise<void> {
    if (this.recorded) {
      return;
    }
    this.recorded = true;
    await this.records.save(new MatchRecord(result, this.modeName(), this.opponentName(),
      Date.now(), this.session.moves));
  }

  private modeName(): string {
    if (this.session.kind === GameKind.AI_5X5) {
      return '进阶 5×5';
    }
    if (this.session.kind === GameKind.LOGIC_6X6) {
      return '逻辑 OOXX 6×6';
    }
    if (this.session.kind === GameKind.LOCAL) {
      return '双人同屏';
    }
    if (this.session.kind === GameKind.DAILY) {
      return '每日挑战';
    }
    if (this.session.kind === GameKind.NETWORK) {
      return '网络对战';
    }
    if (this.session.kind === GameKind.BLUETOOTH) {
      return '蓝牙对战';
    }
    return '经典 3×3';
  }

  private opponentName(): string {
    if (this.session.kind === GameKind.LOCAL) {
      return '本地玩家';
    }
    if (this.session.kind === GameKind.NETWORK || this.session.kind === GameKind.BLUETOOTH) {
      return this.session.opponentName ?? '在线玩家';
    }
    if (this.session.kind === GameKind.DAILY || this.session.kind === GameKind.LOGIC_6X6) {
      return '逻辑谜题';
    }
    return 'AI 棋手';
  }
}
