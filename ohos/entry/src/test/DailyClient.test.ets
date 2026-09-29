import { describe, it, expect } from '@ohos/hypium';
import { Mark } from '../main/ets/model/GameModels';
import { DailyPuzzlePayload } from '../main/ets/network/ApiContracts';
import { DailyClient, DailyHttpRequester, DailyHttpResponse } from '../main/ets/network/DailyClient';

class StubDailyRequester implements DailyHttpRequester {
  requestedUrl: string = '';
  response: DailyHttpResponse | null;
  failure: Error | null;

  constructor(response: DailyHttpResponse | null = null, failure: Error | null = null) {
    this.response = response;
    this.failure = failure;
  }

  async request(url: string): Promise<DailyHttpResponse> {
    this.requestedUrl = url;
    if (this.failure !== null) {
      throw this.failure;
    }
    if (this.response === null) {
      throw new Error('缺少测试响应');
    }
    return this.response;
  }
}

function validPayload(): DailyPuzzlePayload {
  return {
    id: 'daily-1',
    title: '找出唯一胜着',
    size: 3,
    winLength: 3,
    board: 'XO..X.O..',
    next: 'X',
    answer: { row: 2, col: 2 }
  };
}

export default function dailyClientTest() {
  describe('DailyClient', () => {
    it('parsesStringResponseAndUsesConfiguredBaseUrl', 0, async () => {
      const requester = new StubDailyRequester({ responseCode: 200, result: JSON.stringify(validPayload()) });
      const client = new DailyClient('http://127.0.0.1:9527', requester);

      const puzzle = await client.fetchDailyPuzzle();

      expect(requester.requestedUrl).assertEqual('http://127.0.0.1:9527/games/daily');
      expect(puzzle).not().assertNull();
      if (puzzle !== null) {
        expect(puzzle.id).assertEqual('daily-1');
        expect(puzzle.board.get(0, 0)).assertEqual(Mark.X);
        expect(puzzle.board.get(0, 1)).assertEqual(Mark.O);
        expect(puzzle.next).assertEqual(Mark.X);
        expect(puzzle.answer.row).assertEqual(2);
        expect(puzzle.answer.col).assertEqual(2);
      }
    });

    it('parsesObjectResponseAndOPlayer', 0, async () => {
      const payload = validPayload();
      payload.next = 'O';
      const client = new DailyClient('http://test', new StubDailyRequester({ responseCode: 200, result: payload }));

      const puzzle = await client.fetchDailyPuzzle();

      expect(puzzle).not().assertNull();
      if (puzzle !== null) {
        expect(puzzle.next).assertEqual(Mark.O);
      }
    });

    it('returnsNullForHttpAndTransportFailures', 0, async () => {
      const badStatus = new DailyClient('http://test',
        new StubDailyRequester({ responseCode: 503, result: '{}' }));
      expect(await badStatus.fetchDailyPuzzle()).assertNull();

      const disconnected = new DailyClient('http://test',
        new StubDailyRequester(null, new Error('网络中断')));
      expect(await disconnected.fetchDailyPuzzle()).assertNull();
    });

    it('returnsNullForMalformedJsonAndInvalidBoard', 0, async () => {
      const malformed = new DailyClient('http://test',
        new StubDailyRequester({ responseCode: 200, result: '{bad json' }));
      expect(await malformed.fetchDailyPuzzle()).assertNull();

      const payload = validPayload();
      payload.board = 'XO.';
      const invalidBoard = new DailyClient('http://test',
        new StubDailyRequester({ responseCode: 200, result: payload }));
      expect(await invalidBoard.fetchDailyPuzzle()).assertNull();
    });
  });
}
