import localUnitTest from './LocalUnit.test';
import gameEngineTest from './GameEngine.test';
import puzzleValidatorTest from './PuzzleValidator.test';
import localGameRepositoryTest from './LocalGameRepository.test';
import gameStoreTest from './GameStore.test';
import crossPlatformContractTest from './CrossPlatformContract.test';
import historyFilterTest from './HistoryFilter.test';
import turnPromptTest from './TurnPrompt.test';
import roomProtocolTest from './RoomProtocol.test';
import dailyClientTest from './DailyClient.test';
import matchStoreTest from './MatchStore.test';

export default function testsuite() {
  localUnitTest();
  gameEngineTest();
  puzzleValidatorTest();
  localGameRepositoryTest();
  gameStoreTest();
  crossPlatformContractTest();
  historyFilterTest();
  turnPromptTest();
  roomProtocolTest();
  dailyClientTest();
  matchStoreTest();
}
