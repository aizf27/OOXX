import { describe, it, expect } from '@ohos/hypium';
import { Board, Mark, Move } from '../main/ets/model/GameModels';
import { GameEngine } from '../main/ets/service/GameEngine';

export default function gameEngineTest() {
  describe('GameEngine', () => {
    const engine = new GameEngine();

    it('detectsRowAndDiagonalWinner', 0, () => {
      const row = new Board(3, 3, [
        Mark.X, Mark.X, Mark.X,
        Mark.O, Mark.O, Mark.EMPTY,
        Mark.EMPTY, Mark.EMPTY, Mark.EMPTY
      ]);
      const diagonal = new Board(3, 3, [
        Mark.O, Mark.X, Mark.X,
        Mark.EMPTY, Mark.O, Mark.EMPTY,
        Mark.X, Mark.EMPTY, Mark.O
      ]);
      expect(engine.winner(row)).assertEqual(Mark.X);
      expect(engine.winner(diagonal)).assertEqual(Mark.O);
    });

    it('minimaxFindsImmediateWin', 0, () => {
      const board = new Board(3, 3, [
        Mark.X, Mark.X, Mark.EMPTY,
        Mark.O, Mark.O, Mark.EMPTY,
        Mark.EMPTY, Mark.EMPTY, Mark.EMPTY
      ]);
      const move = engine.bestMove(board, Mark.X);
      expect(move?.row).assertEqual(0);
      expect(move?.col).assertEqual(2);
    });

    it('emptyBoardHasNoUniqueBestMove', 0, () => {
      expect(engine.uniqueBestMove(new Board(), Mark.X)).assertNull();
    });

    it('fallbackPuzzleHasDeclaredUniqueAnswer', 0, () => {
      const puzzle = engine.fallbackPuzzle();
      const calculated = engine.uniqueBestMove(puzzle.board, puzzle.next);
      expect(calculated?.equals(puzzle.answer)).assertTrue();
      expect(puzzle.board.isEmpty(new Move(puzzle.answer.row, puzzle.answer.col))).assertTrue();
    });
  });
}
