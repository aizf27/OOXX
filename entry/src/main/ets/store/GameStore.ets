import { GameKind, GameSession, MatchRecord, MatchResult } from '../model/AppModels';
import { Board, Mark, Move, Puzzle, oppositeMark } from '../model/GameModels';
import { RecordRepository } from '../repository/GameRepository';
import { GameEngine } from '../service/GameEngine';

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

  constructor(records: RecordRepository, engine: GameEngine = new GameEngine()) {
    this.records = records;
    this.engine = engine;
  }

  start(kind: GameKind, puzzle: Puzzle | null = null): void {
    this.history = [];
    this.recorded = false;
    this.result = null;
    if (kind === GameKind.AI_5X5) {
      this.session = new GameSession(new Board(5, 4), Mark.X, Mark.X, kind);
      return;
    }
    if (kind === GameKind.DAILY) {
      const daily = puzzle ?? this.engine.fallbackPuzzle();
      this.session = new GameSession(daily.board, daily.next, daily.next, kind, 0,
        '请选择唯一最优的一步', daily.answer);
      return;
    }
    const message = kind === GameKind.NETWORK || kind === GameKind.BLUETOOTH ? '等待跨端连接' : '轮到你了';
    this.session = new GameSession(new Board(), Mark.X, Mark.X, kind, 0, message);
  }

  async play(move: Move): Promise<MoveDecision> {
    if (this.session.kind === GameKind.NETWORK || this.session.kind === GameKind.BLUETOOTH) {
      return new MoveDecision(MoveHandling.REMOTE_REQUIRED, '落子需由连接层发送并等待权威状态');
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
      const board = this.session.board.place(move, this.session.turn);
      this.session = this.copySession(board, this.session.turn, 1,
        solved ? '唯一解正确！' : '这一步不是唯一最优解', solved, false);
      await this.finish(solved ? MatchResult.WIN : MatchResult.LOSS);
      return new MoveDecision(MoveHandling.LOCAL_APPLIED, this.session.message);
    }
    const board = this.session.board.place(move, this.session.turn);
    const nextTurn = oppositeMark(this.session.turn);
    const isAi = this.session.kind === GameKind.AI_3X3 || this.session.kind === GameKind.AI_5X5;
    this.session = this.copySession(board, nextTurn, this.session.moves + 1,
      isAi ? '对手思考中…' : `轮到 ${nextTurn}`, null, isAi);
    if (await this.completeIfNeeded()) {
      return new MoveDecision(MoveHandling.LOCAL_APPLIED, this.session.message);
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
    const board = this.session.board.place(move, this.session.turn);
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

  async applyAuthoritativeState(session: GameSession, result: MatchResult | null): Promise<void> {
    if (session.kind !== GameKind.NETWORK) {
      throw new Error('只有网络对局允许应用服务器权威状态');
    }
    this.session = session;
    this.result = result;
    if (result !== null) {
      await this.saveRecord(result);
    }
  }

  private copySession(board: Board, turn: Mark, moves: number, message: string,
    puzzleSolved: boolean | null, isAiThinking: boolean): GameSession {
    return new GameSession(board, turn, this.session.playerMark, this.session.kind, moves, message,
      this.session.puzzleAnswer, puzzleSolved, isAiThinking);
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
    if (this.session.kind === GameKind.LOCAL) {
      return '双人同屏';
    }
    if (this.session.kind === GameKind.DAILY) {
      return '每日挑战';
    }
    if (this.session.kind === GameKind.NETWORK) {
      return '网络房间';
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
    if (this.session.kind === GameKind.NETWORK) {
      return '在线玩家';
    }
    if (this.session.kind === GameKind.BLUETOOTH) {
      return '附近玩家';
    }
    if (this.session.kind === GameKind.DAILY) {
      return '每日题目';
    }
    return 'AI 棋手';
  }
}
