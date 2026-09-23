import { MatchRecord, MatchResult, RankingEntry } from '../model/AppModels';
import { Puzzle } from '../model/GameModels';
import { GameEngine } from '../service/GameEngine';
import { PuzzleRepository, RecordRepository } from './GameRepository';

export interface RecordDataSource {
  load(): Promise<MatchRecord[]>;
  replace(records: MatchRecord[]): Promise<void>;
}

export class MemoryRecordDataSource implements RecordDataSource {
  private records: MatchRecord[] = [];

  async load(): Promise<MatchRecord[]> {
    return this.records.slice();
  }

  async replace(records: MatchRecord[]): Promise<void> {
    this.records = records.slice();
  }
}

export class LocalGameRepository implements PuzzleRepository, RecordRepository {
  private readonly source: RecordDataSource;
  private readonly engine: GameEngine;

  constructor(source: RecordDataSource = new MemoryRecordDataSource(), engine: GameEngine = new GameEngine()) {
    this.source = source;
    this.engine = engine;
  }

  async fetchDailyPuzzle(): Promise<Puzzle> {
    return this.engine.generateUniquePuzzle();
  }

  fallbackPuzzle(): Puzzle {
    return this.engine.fallbackPuzzle();
  }

  async save(record: MatchRecord): Promise<void> {
    const stored = await this.source.load();
    const next = stored.concat([record]).sort((left: MatchRecord, right: MatchRecord) => left.playedAt - right.playedAt);
    await this.source.replace(next.slice(Math.max(0, next.length - 50)));
  }

  async records(): Promise<MatchRecord[]> {
    const stored = await this.source.load();
    return stored.sort((left: MatchRecord, right: MatchRecord) => right.playedAt - left.playedAt);
  }

  async ranking(): Promise<RankingEntry[]> {
    const records = await this.records();
    let score = 0;
    let wins = 0;
    let losses = 0;
    let draws = 0;
    for (let index = 0; index < records.length; index++) {
      const result = records[index].result;
      if (result === MatchResult.WIN) {
        score += 30;
        wins++;
      } else if (result === MatchResult.DRAW) {
        score += 10;
        draws++;
      } else {
        score += 2;
        losses++;
      }
    }
    const players: RankingEntry[] = [
      new RankingEntry(0, 'bot-master', '棋妙高手', 1280, 36, 4, 2),
      new RankingEntry(0, 'bot-circle', '圈圈达人', 1160, 32, 6, 4),
      new RankingEntry(0, 'bot-cross', '叉叉队长', 1030, 27, 8, 5),
      new RankingEntry(0, 'guest-local', '康思', 620 + score, wins, losses, draws, true),
      new RankingEntry(0, 'bot-ming', '小明', 590, 14, 12, 7)
    ];
    players.sort((left: RankingEntry, right: RankingEntry) => right.score - left.score);
    const ranked: RankingEntry[] = [];
    for (let index = 0; index < players.length; index++) {
      const item = players[index];
      ranked.push(new RankingEntry(index + 1, item.playerId, item.name, item.score,
        item.wins, item.losses, item.draws, item.isMe));
    }
    return ranked;
  }
}
