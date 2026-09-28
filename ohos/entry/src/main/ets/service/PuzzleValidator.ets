import { Board, Mark, Move, Puzzle } from '../model/GameModels';
import { DailyPuzzlePayload } from '../network/ApiContracts';
import { GameEngine } from './GameEngine';

export class PuzzleValidator {
  private readonly engine: GameEngine;

  constructor(engine: GameEngine = new GameEngine()) {
    this.engine = engine;
  }

  validate(payload: DailyPuzzlePayload): Puzzle {
    if (payload.size < 3 || payload.winLength < 3 || payload.winLength > payload.size) {
      throw new Error('题目尺寸无效');
    }
    if (payload.board.length !== payload.size * payload.size) {
      throw new Error('题目棋盘长度无效');
    }
    const cells: Mark[] = [];
    for (let index = 0; index < payload.board.length; index++) {
      cells.push(this.parseMark(payload.board[index]));
    }
    const next = this.parsePlayer(payload.next);
    const board = new Board(payload.size, payload.winLength, cells);
    const declared = new Move(payload.answer.row, payload.answer.col);
    if (!board.isEmpty(declared)) {
      throw new Error('题目答案位置无效');
    }
    const calculated = this.engine.uniqueBestMove(board, next);
    if (calculated === null || !calculated.equals(declared)) {
      throw new Error('题目答案不是唯一最优解');
    }
    return new Puzzle(payload.id, payload.title, board, next, declared);
  }

  private parseMark(value: string): Mark {
    const normalized = value.toUpperCase();
    if (normalized === 'X') {
      return Mark.X;
    }
    if (normalized === 'O') {
      return Mark.O;
    }
    if (normalized === '.' || normalized === '') {
      return Mark.EMPTY;
    }
    throw new Error('题目包含非法棋子');
  }

  private parsePlayer(value: string): Mark {
    const mark = this.parseMark(value);
    if (mark === Mark.EMPTY) {
      throw new Error('题目缺少下一手玩家');
    }
    return mark;
  }
}
