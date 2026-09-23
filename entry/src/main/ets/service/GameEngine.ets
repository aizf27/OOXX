import { Board, Mark, Move, oppositeMark, Puzzle } from '../model/GameModels';

export class RatedMove {
  readonly move: Move;
  readonly score: number;

  constructor(move: Move, score: number) {
    this.move = move;
    this.score = score;
  }
}

export class GameEngine {
  winner(board: Board): Mark | null {
    const directions: number[][] = [[0, 1], [1, 0], [1, 1], [1, -1]];
    for (let row = 0; row < board.size; row++) {
      for (let col = 0; col < board.size; col++) {
        const mark = board.get(row, col);
        if (mark === Mark.EMPTY) {
          continue;
        }
        for (let index = 0; index < directions.length; index++) {
          const rowStep = directions[index][0];
          const colStep = directions[index][1];
          const endRow = row + (board.winLength - 1) * rowStep;
          const endCol = col + (board.winLength - 1) * colStep;
          if (!board.isInside(endRow, endCol)) {
            continue;
          }
          let matched = true;
          for (let offset = 1; offset < board.winLength; offset++) {
            if (board.get(row + offset * rowStep, col + offset * colStep) !== mark) {
              matched = false;
              break;
            }
          }
          if (matched) {
            return mark;
          }
        }
      }
    }
    return null;
  }

  isDraw(board: Board): boolean {
    return this.winner(board) === null && board.availableMoves().length === 0;
  }

  rateMoves(board: Board, player: Mark): RatedMove[] {
    if (player === Mark.EMPTY || this.winner(board) !== null) {
      return [];
    }
    const exact = board.size === 3 && board.winLength === 3;
    const moves = board.availableMoves();
    const rated: RatedMove[] = [];
    for (let index = 0; index < moves.length; index++) {
      const move = moves[index];
      const next = board.place(move, player);
      const score = exact
        ? this.minimax(next, oppositeMark(player), player, -10000, 10000, 1)
        : this.heuristicScore(next, player) - this.heuristicScore(next, oppositeMark(player));
      rated.push(new RatedMove(move, score));
    }
    return rated;
  }

  bestMove(board: Board, player: Mark): Move | null {
    const rated = this.rateMoves(board, player);
    if (rated.length === 0) {
      return null;
    }
    let best = rated[0];
    for (let index = 1; index < rated.length; index++) {
      const candidate = rated[index];
      if (candidate.score > best.score ||
        (candidate.score === best.score && this.positionPriority(board, candidate.move) > this.positionPriority(board, best.move))) {
        best = candidate;
      }
    }
    return best.move;
  }

  uniqueBestMove(board: Board, player: Mark): Move | null {
    const rated = this.rateMoves(board, player);
    if (rated.length === 0) {
      return null;
    }
    let bestScore = rated[0].score;
    for (let index = 1; index < rated.length; index++) {
      bestScore = Math.max(bestScore, rated[index].score);
    }
    let answer: Move | null = null;
    for (let index = 0; index < rated.length; index++) {
      if (rated[index].score === bestScore) {
        if (answer !== null) {
          return null;
        }
        answer = rated[index].move;
      }
    }
    return answer;
  }

  generateUniquePuzzle(): Puzzle {
    for (let attempt = 0; attempt < 1000; attempt++) {
      let board = new Board();
      let turn = Mark.X;
      const plies = 3 + Math.floor(Math.random() * 4);
      for (let step = 0; step < plies; step++) {
        const moves = board.availableMoves();
        if (moves.length === 0 || this.winner(board) !== null) {
          break;
        }
        const move = moves[Math.floor(Math.random() * moves.length)];
        board = board.place(move, turn);
        turn = oppositeMark(turn);
      }
      if (this.winner(board) !== null) {
        continue;
      }
      const answer = this.uniqueBestMove(board, turn);
      if (answer !== null && this.scoreForMove(board, turn, answer) > 0) {
        return new Puzzle(`local-${Date.now()}`, '本地唯一解挑战', board, turn, answer);
      }
    }
    return this.fallbackPuzzle();
  }

  fallbackPuzzle(): Puzzle {
    const board = new Board(3, 3, [
      Mark.X, Mark.X, Mark.EMPTY,
      Mark.O, Mark.O, Mark.EMPTY,
      Mark.EMPTY, Mark.EMPTY, Mark.EMPTY
    ]);
    return new Puzzle('fallback-001', '唯一制胜落点', board, Mark.X, new Move(0, 2));
  }

  private scoreForMove(board: Board, player: Mark, move: Move): number {
    const rated = this.rateMoves(board, player);
    for (let index = 0; index < rated.length; index++) {
      if (rated[index].move.equals(move)) {
        return rated[index].score;
      }
    }
    return -10000;
  }

  private minimax(board: Board, turn: Mark, maximizer: Mark,
    alphaStart: number, betaStart: number, depth: number): number {
    const won = this.winner(board);
    if (won !== null) {
      return won === maximizer ? 100 - depth : depth - 100;
    }
    if (board.availableMoves().length === 0) {
      return 0;
    }
    let alpha = alphaStart;
    let beta = betaStart;
    const moves = board.availableMoves();
    if (turn === maximizer) {
      let value = -10000;
      for (let index = 0; index < moves.length; index++) {
        const score = this.minimax(board.place(moves[index], turn), oppositeMark(turn), maximizer,
          alpha, beta, depth + 1);
        value = Math.max(value, score);
        alpha = Math.max(alpha, value);
        if (alpha >= beta) {
          break;
        }
      }
      return value;
    }
    let value = 10000;
    for (let index = 0; index < moves.length; index++) {
      const score = this.minimax(board.place(moves[index], turn), oppositeMark(turn), maximizer,
        alpha, beta, depth + 1);
      value = Math.min(value, score);
      beta = Math.min(beta, value);
      if (alpha >= beta) {
        break;
      }
    }
    return value;
  }

  private heuristicScore(board: Board, player: Mark): number {
    const won = this.winner(board);
    if (won !== null) {
      return won === player ? 100000 : -100000;
    }
    const enemy = oppositeMark(player);
    const directions: number[][] = [[0, 1], [1, 0], [1, 1], [1, -1]];
    let score = 0;
    for (let row = 0; row < board.size; row++) {
      for (let col = 0; col < board.size; col++) {
        for (let direction = 0; direction < directions.length; direction++) {
          const rowStep = directions[direction][0];
          const colStep = directions[direction][1];
          const endRow = row + (board.winLength - 1) * rowStep;
          const endCol = col + (board.winLength - 1) * colStep;
          if (!board.isInside(endRow, endCol)) {
            continue;
          }
          let ownCount = 0;
          let enemyCount = 0;
          for (let offset = 0; offset < board.winLength; offset++) {
            const mark = board.get(row + offset * rowStep, col + offset * colStep);
            if (mark === player) {
              ownCount++;
            } else if (mark === enemy) {
              enemyCount++;
            }
          }
          if (enemyCount === 0) {
            score += ownCount * ownCount * 12;
            if (ownCount === board.winLength - 1) {
              score += 600;
            }
          }
          if (ownCount === 0) {
            score -= enemyCount * enemyCount * 10;
          }
        }
      }
    }
    return score;
  }

  private positionPriority(board: Board, move: Move): number {
    const center = Math.floor(board.size / 2);
    return board.size - (Math.abs(move.row - center) + Math.abs(move.col - center));
  }
}
