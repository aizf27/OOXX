import { MatchRecord, RankingEntry } from '../model/AppModels';
import { Puzzle } from '../model/GameModels';

export interface PuzzleRepository {
  fetchDailyPuzzle(): Promise<Puzzle>;
  fallbackPuzzle(): Puzzle;
}

export interface RecordRepository {
  save(record: MatchRecord): Promise<void>;
  records(): Promise<MatchRecord[]>;
  ranking(): Promise<RankingEntry[]>;
}
