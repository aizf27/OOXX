import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Puzzle } from '../model/GameModels';
import { Board, Mark, Move } from '../model/GameModels';
import { DailyPuzzlePayload } from './ApiContracts';

const BASE_URL = 'http://47.243.15.216:9527';

export class DailyClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string = BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async fetchDailyPuzzle(): Promise<Puzzle | null> {
    try {
      const httpClient = http.createHttp();
      const response = await new Promise<http.HttpResponse>((resolve, reject) => {
        httpClient.request(`${this.baseUrl}/games/daily`, {
          method: http.RequestMethod.GET,
          header: { 'Content-Type': 'application/json' },
          connectTimeout: 8000,
          readTimeout: 8000
        }, (err: BusinessError, data: http.HttpResponse) => {
          if (err) {
            reject(err);
          } else {
            resolve(data);
          }
        });
      });
      httpClient.destroy();
      if (response.responseCode !== 200) {
        return null;
      }
      let payload: DailyPuzzlePayload;
      if (typeof response.result === 'string') {
        payload = JSON.parse(response.result) as DailyPuzzlePayload;
      } else if (typeof response.result === 'object' && response.result !== null) {
        payload = response.result as DailyPuzzlePayload;
      } else {
        return null;
      }
      return this.parsePayload(payload);
    } catch {
      return null;
    }
  }

  private parsePayload(payload: DailyPuzzlePayload): Puzzle | null {
    if (!payload.board || payload.board.length !== payload.size * payload.size) {
      return null;
    }
    const cells: Mark[] = [];
    for (let i = 0; i < payload.board.length; i++) {
      const char = payload.board[i];
      if (char === 'X') {
        cells.push(Mark.X);
      } else if (char === 'O') {
        cells.push(Mark.O);
      } else {
        cells.push(Mark.EMPTY);
      }
    }
    const board = new Board(payload.size, payload.winLength, cells);
    const next = payload.next === 'O' ? Mark.O : Mark.X;
    const answer = new Move(payload.answer.row, payload.answer.col);
    return new Puzzle(payload.id, payload.title, board, next, answer);
  }
}
