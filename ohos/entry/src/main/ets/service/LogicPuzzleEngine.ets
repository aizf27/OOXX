import { Board, Mark } from '../model/GameModels';

export class LogicBoard {
  readonly size: number;
  readonly cells: Mark[];
  readonly givens: Set<number>;

  constructor(size: number = 6, cells?: Mark[], givens?: Set<number>) {
    if (size < 4 || size % 2 !== 0) {
      throw new Error('棋盘尺寸必须是大于等于 4 的偶数');
    }
    const source = cells ?? new Array<Mark>(size * size).fill(Mark.EMPTY);
    if (source.length !== size * size) {
      throw new Error('棋盘格数量无效');
    }
    this.size = size;
    this.cells = source.slice();
    this.givens = givens ?? new Set<number>();
  }

  get(row: number, col: number): Mark {
    return this.cells[row * this.size + col];
  }

  cycle(move: { row: number, col: number }): LogicBoard {
    const index = move.row * this.size + move.col;
    if (this.givens.has(index)) {
      return this;
    }
    const next = this.cells.slice();
    next[index] = this.nextMark(next[index]);
    return new LogicBoard(this.size, next, this.givens);
  }

  private nextMark(mark: Mark): Mark {
    if (mark === Mark.EMPTY) {
      return Mark.X;
    }
    if (mark === Mark.X) {
      return Mark.O;
    }
    return Mark.EMPTY;
  }
}

export class LogicPuzzleEngine {
  private static readonly EMPTY = '.';

  static classic6x6(): LogicBoard {
    return LogicPuzzleEngine.parse([
      '......',
      '...O..',
      '.O....',
      '.O....',
      '..OO.X',
      '....XX'
    ]);
  }

  static parse(rows: string[]): LogicBoard {
    if (rows.length === 0 || rows.length % 2 !== 0) {
      throw new Error('逻辑棋盘行数必须是正偶数');
    }
    const size = rows.length;
    const cells: Mark[] = [];
    const givens = new Set<number>();
    for (let row = 0; row < size; row++) {
      const line = rows[row];
      if (line.length !== size) {
        throw new Error('逻辑棋盘必须是正方形');
      }
      for (let col = 0; col < size; col++) {
        const char = line[col];
        const index = row * size + col;
        if (char === 'X') {
          cells.push(Mark.X);
          givens.add(index);
        } else if (char === 'O') {
          cells.push(Mark.O);
          givens.add(index);
        } else {
          cells.push(Mark.EMPTY);
        }
      }
    }
    return new LogicBoard(size, cells, givens);
  }

  static invalidCells(board: LogicBoard): Set<number> {
    const invalid = new Set<number>();
    const half = board.size / 2;

    const checkLine = (indices: number[]): void => {
      const marks = indices.map((i) => board.cells[i]);
      const xCount = marks.filter((m) => m === Mark.X).length;
      const oCount = marks.filter((m) => m === Mark.O).length;
      if (xCount > half || oCount > half) {
        indices.filter((i) => board.cells[i] !== Mark.EMPTY).forEach((i) => invalid.add(i));
      }
      for (let start = 0; start <= board.size - 3; start++) {
        const triple = indices.slice(start, start + 3);
        const mark = board.cells[triple[0]];
        if (mark !== Mark.EMPTY && triple.every((i) => board.cells[i] === mark)) {
          triple.forEach((i) => invalid.add(i));
        }
      }
    };

    const rows: number[][] = [];
    const cols: number[][] = [];
    for (let i = 0; i < board.size; i++) {
      const row: number[] = [];
      const col: number[] = [];
      for (let j = 0; j < board.size; j++) {
        row.push(i * board.size + j);
        col.push(j * board.size + i);
      }
      rows.push(row);
      cols.push(col);
    }
    rows.forEach(checkLine);
    cols.forEach(checkLine);

    const markDuplicates = (lines: number[][]): void => {
      const fullLines = lines.filter((line) => line.every((i) => board.cells[i] !== Mark.EMPTY));
      const groups = new Map<string, number[][]>();
      fullLines.forEach((line) => {
        const key = line.map((i) => board.cells[i]).join('');
        const list = groups.get(key) ?? [];
        list.push(line);
        groups.set(key, list);
      });
      groups.forEach((list) => {
        if (list.length > 1) {
          list.forEach((line) => line.forEach((i) => invalid.add(i)));
        }
      });
    };
    markDuplicates(rows);
    markDuplicates(cols);

    return invalid;
  }

  static isSolved(board: LogicBoard): boolean {
    return board.cells.every((m) => m !== Mark.EMPTY) && LogicPuzzleEngine.invalidCells(board).size === 0;
  }

  static status(board: LogicBoard): string {
    const invalid = LogicPuzzleEngine.invalidCells(board);
    if (invalid.size > 0) {
      return '红色格违反规则，再检查一下';
    }
    if (board.cells.every((m) => m !== Mark.EMPTY)) {
      return '还有行或列未满足规则';
    }
    const filled = board.cells.filter((m) => m !== Mark.EMPTY).length;
    return `点击空格切换 X / O，已填 ${filled}/${board.cells.length}`;
  }

  static countSolutions(board: LogicBoard, limit: number = 2): number {
    const cells = board.cells.slice();
    let count = 0;

    const search = (): void => {
      if (count >= limit) {
        return;
      }
      const empty = cells.indexOf(Mark.EMPTY);
      if (empty === -1) {
        const complete = new LogicBoard(board.size, cells.slice(), board.givens);
        if (LogicPuzzleEngine.isSolved(complete)) {
          count++;
        }
        return;
      }
      for (const mark of [Mark.X, Mark.O]) {
        cells[empty] = mark;
        const partial = new LogicBoard(board.size, cells.slice(), board.givens);
        if (LogicPuzzleEngine.invalidCells(partial).size === 0) {
          search();
        }
        cells[empty] = Mark.EMPTY;
      }
    };

    search();
    return count;
  }
}
