export enum Mark {
  EMPTY = '',
  X = 'X',
  O = 'O'
}

export class Move {
  readonly row: number;
  readonly col: number;

  constructor(row: number, col: number) {
    this.row = row;
    this.col = col;
  }

  equals(other: Move | null): boolean {
    return other !== null && this.row === other.row && this.col === other.col;
  }
}

export class Board {
  readonly size: number;
  readonly winLength: number;
  readonly cells: Mark[];

  constructor(size: number = 3, winLength: number = 3, cells?: Mark[]) {
    if (size < 3 || winLength < 3 || winLength > size) {
      throw new Error('棋盘尺寸或连线长度无效');
    }
    const source = cells ?? new Array<Mark>(size * size).fill(Mark.EMPTY);
    if (source.length !== size * size) {
      throw new Error('棋盘格数量无效');
    }
    this.size = size;
    this.winLength = winLength;
    this.cells = source.slice();
  }

  get(row: number, col: number): Mark {
    return this.cells[row * this.size + col];
  }

  isInside(row: number, col: number): boolean {
    return row >= 0 && row < this.size && col >= 0 && col < this.size;
  }

  isEmpty(move: Move): boolean {
    return this.isInside(move.row, move.col) && this.get(move.row, move.col) === Mark.EMPTY;
  }

  place(move: Move, mark: Mark): Board {
    if (mark === Mark.EMPTY || !this.isEmpty(move)) {
      throw new Error('当前落子无效');
    }
    const next = this.cells.slice();
    next[move.row * this.size + move.col] = mark;
    return new Board(this.size, this.winLength, next);
  }

  availableMoves(): Move[] {
    const moves: Move[] = [];
    for (let index = 0; index < this.cells.length; index++) {
      if (this.cells[index] === Mark.EMPTY) {
        moves.push(new Move(Math.floor(index / this.size), index % this.size));
      }
    }
    return moves;
  }
}

export class Puzzle {
  readonly id: string;
  readonly title: string;
  readonly board: Board;
  readonly next: Mark;
  readonly answer: Move;

  constructor(id: string, title: string, board: Board, next: Mark, answer: Move) {
    this.id = id;
    this.title = title;
    this.board = board;
    this.next = next;
    this.answer = answer;
  }
}

export function oppositeMark(mark: Mark): Mark {
  if (mark === Mark.X) {
    return Mark.O;
  }
  if (mark === Mark.O) {
    return Mark.X;
  }
  return Mark.EMPTY;
}
