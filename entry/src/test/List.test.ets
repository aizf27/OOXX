import localUnitTest from './LocalUnit.test';
import gameEngineTest from './GameEngine.test';

export default function testsuite() {
  localUnitTest();
  gameEngineTest();
}
