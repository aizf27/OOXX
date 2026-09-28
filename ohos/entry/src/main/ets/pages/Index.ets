import { HomePage } from './HomePage';
import { ModePage } from './ModePage';
import { GamePage } from './GamePage';
import { HistoryPage } from './HistoryPage';
import { ProfilePage } from './ProfilePage';
import { OnboardingPage } from './OnboardingPage';
import { ResultPage } from './ResultPage';
import { RoomPage } from './RoomPage';
import { SplashPage } from './SplashPage';
import { AppScreen, GameKind, MatchResult } from '../model/AppModels';
import { Mark, Move } from '../model/GameModels';
import { LocalGameRepository } from '../repository/LocalGameRepository';
import { GameStore } from '../store/GameStore';

@Entry
@Component
struct Index {
  @State screen: AppScreen = AppScreen.SPLASH;
  @State board: string[] = ['', '', '', '', '', '', '', '', ''];
  @State turnText: string = '轮到你了';
  @State result: MatchResult | null = null;
  @State boardSize: number = 3;
  @State currentKind: GameKind = GameKind.AI_3X3;
  private readonly gameStore: GameStore = new GameStore(new LocalGameRepository());

  showHome(): void {
    this.screen = AppScreen.HOME;
  }

  startGame(kind: GameKind): void {
    this.currentKind = kind;
    this.gameStore.start(kind);
    this.result = null;
    this.syncGameState();
    this.screen = AppScreen.GAME;
  }

  async tapCell(index: number): Promise<void> {
    if (index < 0 || index >= this.board.length || this.board[index] !== '') {
      return;
    }
    const row = Math.floor(index / this.boardSize);
    const col = index % this.boardSize;
    await this.gameStore.play(new Move(row, col));
    this.syncGameState();
    if (this.gameStore.session.isAiThinking) {
      await this.gameStore.playAiTurn();
      this.syncGameState();
    }
    if (this.gameStore.result !== null) {
      this.result = this.gameStore.result;
      this.screen = AppScreen.RESULT;
    }
  }

  undo(): void {
    if (this.gameStore.undo()) {
      this.syncGameState();
    }
  }

  async surrender(): Promise<void> {
    await this.gameStore.surrender();
    this.syncGameState();
    this.result = this.gameStore.result;
    if (this.result !== null) {
      this.screen = AppScreen.RESULT;
    }
  }

  gameModeText(): string {
    if (this.currentKind === GameKind.AI_5X5) {
      return '进阶 5×5';
    }
    if (this.currentKind === GameKind.LOCAL) {
      return '双人同屏';
    }
    if (this.currentKind === GameKind.DAILY) {
      return '每日挑战';
    }
    return '经典 3×3';
  }

  syncGameState(): void {
    const session = this.gameStore.session;
    this.boardSize = session.board.size;
    const cells: string[] = [];
    for (let index = 0; index < session.board.cells.length; index++) {
      cells.push(session.board.cells[index] === Mark.EMPTY ? '' : session.board.cells[index]);
    }
    this.board = cells;
    this.turnText = session.message;
  }

  build() {
    Column() {
      if (this.screen === AppScreen.SPLASH) {
        SplashPage({ onContinue: () => this.screen = AppScreen.ONBOARDING })
      } else if (this.screen === AppScreen.ONBOARDING) {
        OnboardingPage({ onStart: () => this.showHome() })
      } else if (this.screen === AppScreen.HOME) {
        HomePage({
          onOpenMode: () => this.screen = AppScreen.MODE,
          onStartLocal: () => this.startGame(GameKind.LOCAL),
          onOpenRoom: () => this.screen = AppScreen.ROOM,
          onOpenDaily: () => this.startGame(GameKind.DAILY),
          onOpenHistory: () => this.screen = AppScreen.HISTORY,
          onOpenProfile: () => this.screen = AppScreen.PROFILE
        })
      } else if (this.screen === AppScreen.MODE) {
        ModePage({
          onBack: () => this.showHome(),
          onStartClassic: () => this.startGame(GameKind.AI_3X3),
          onStartAdvanced: () => this.startGame(GameKind.AI_5X5),
          onStartDaily: () => this.startGame(GameKind.DAILY)
        })
      } else if (this.screen === AppScreen.ROOM) {
        RoomPage({
          onBack: () => this.showHome(),
          onCreate: () => {},
          onJoin: () => {}
        })
      } else if (this.screen === AppScreen.GAME) {
        GamePage({
          board: this.board,
          playerTurn: this.turnText,
          isLocal: this.currentKind === GameKind.LOCAL,
          onBack: () => this.showHome(),
          onTapCell: (index: number) => this.tapCell(index),
          onUndo: () => this.undo(),
          onSurrender: () => this.surrender()
        })
      } else if (this.screen === AppScreen.HISTORY) {
        HistoryPage({
          onBack: () => this.showHome(),
          onOpenProfile: () => this.screen = AppScreen.PROFILE
        })
      } else if (this.screen === AppScreen.PROFILE) {
        ProfilePage({
          onBack: () => this.showHome(),
          onOpenHistory: () => this.screen = AppScreen.HISTORY
        })
      } else if (this.screen === AppScreen.RESULT) {
        ResultPage({
          result: this.result,
          moves: this.gameStore.session.moves,
          mode: this.gameModeText(),
          onReplay: () => this.startGame(this.currentKind),
          onHome: () => this.showHome()
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
