import localUnitTest from './LocalUnit.test';
import gameEngineTest from './GameEngine.test';
import puzzleValidatorTest from './PuzzleValidator.test';

export default function testsuite() {
  localUnitTest();
  gameEngineTest();
  puzzleValidatorTest();
}
