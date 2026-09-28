import { GameSession, MatchRecord, MatchResult, RankingEntry, AppScreen, NetworkRoom, Settings } from '../model/AppModels';

export class AppState {
  screen: AppScreen = AppScreen.SPLASH;
  game: GameSession = new GameSession();
  result: MatchResult | null = null;
  records: MatchRecord[] = [];
  ranking: RankingEntry[] = [];
  networkMessage: string = '';
  isLoadingPuzzle: boolean = false;
  settings: Settings = new Settings();
  network: NetworkRoom = new NetworkRoom();
}
