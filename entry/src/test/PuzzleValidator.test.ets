import { describe, it, expect } from '@ohos/hypium';
import { DailyPuzzlePayload } from '../main/ets/network/ApiContracts';
import { PuzzleValidator } from '../main/ets/service/PuzzleValidator';

export default function puzzleValidatorTest() {
  describe('PuzzleValidator', () => {
    const validator = new PuzzleValidator();

    it('acceptsDeclaredUniqueAnswer', 0, () => {
      const payload: DailyPuzzlePayload = {
        id: 'daily-001',
        title: '唯一制胜落点',
        size: 3,
        winLength: 3,
        board: 'XX.OO....',
        next: 'X',
        answer: { row: 0, col: 2 }
      };
      const puzzle = validator.validate(payload);
      expect(puzzle.answer.row).assertEqual(0);
      expect(puzzle.answer.col).assertEqual(2);
    });

    it('rejectsBoardWithoutUniqueAnswer', 0, () => {
      const payload: DailyPuzzlePayload = {
        id: 'invalid-001',
        title: '无唯一解',
        size: 3,
        winLength: 3,
        board: '.........',
        next: 'X',
        answer: { row: 1, col: 1 }
      };
      let rejected = false;
      try {
        validator.validate(payload);
      } catch (_) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
