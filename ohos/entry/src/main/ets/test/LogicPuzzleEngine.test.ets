import { describe, it, expect } from '@ohos/hypium';
import { LogicPuzzleEngine } from '../main/ets/service/LogicPuzzleEngine';

export default function logicPuzzleEngineTest() {
  describe('LogicPuzzleEngine', () => {
    it('classicPuzzleHasExactlyOneSolution', 0, () => {
      expect(LogicPuzzleEngine.countSolutions(LogicPuzzleEngine.classic6x6())).assertEqual(1);
    });

    it('detectsTriplesBalanceAndDuplicateLines', 0, () => {
      const triple = LogicPuzzleEngine.parse(['XXXO..', '......', '......', '......', '......', '......']);
      expect(LogicPuzzleEngine.invalidCells(triple).size).assertEqual(3);

      const duplicateRows = LogicPuzzleEngine.parse(['XXOXOO', 'XXOXOO', '......', '......', '......', '......']);
      const invalid = LogicPuzzleEngine.invalidCells(duplicateRows);
      expect(invalid.size).assertEqual(12);
    });
  });
}
