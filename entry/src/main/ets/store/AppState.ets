import { GameSession, MatchRecord, MatchResult, RankingEntry, Screen } from '../model/AppModels';

export class AppState {
  screen: Screen = Screen.SPLASH;
  game: GameSession = new GameSession();
  result: MatchResult | null = null;
  records: MatchRecord[] = [];
  ranking: RankingEntry[] = [];
  networkMessage: string = '';
  isLoadingPuzzle: boolean = false;
}
