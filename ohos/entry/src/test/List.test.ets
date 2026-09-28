import localUnitTest from './LocalUnit.test';
import gameEngineTest from './GameEngine.test';
import puzzleValidatorTest from './PuzzleValidator.test';
import localGameRepositoryTest from './LocalGameRepository.test';
import gameStoreTest from './GameStore.test';

export default function testsuite() {
  localUnitTest();
  gameEngineTest();
  puzzleValidatorTest();
  localGameRepositoryTest();
  gameStoreTest();
}