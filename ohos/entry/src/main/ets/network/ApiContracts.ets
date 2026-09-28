export interface MovePayload {
  row: number;
  col: number;
}

export interface DailyPuzzlePayload {
  id: string;
  title: string;
  size: number;
  winLength: number;
  board: string;
  next: string;
  answer: MovePayload;
}

export interface RankingPayload {
  playerId: string;
  name: string;
  result: string;
}

export interface RankingEntryPayload {
  rank: number;
  id: string;
  name: string;
  score: number;
  wins: number;
  losses: number;
  draws: number;
}
