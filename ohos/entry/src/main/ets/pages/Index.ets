import { HomePage } from './HomePage';
import { ModePage } from './ModePage';
import { GamePage } from './GamePage';
import { HistoryPage } from './HistoryPage';
import { ProfilePage } from './ProfilePage';
import { OnboardingPage } from './OnboardingPage';
import { ResultPage } from './ResultPage';
import { RoomPage } from './RoomPage';
import { SplashPage } from './SplashPage';
import { AppScreen, GameKind, GameSession, MatchResult, NetworkRoom, Settings } from '../model/AppModels';
import { Mark, Move } from '../model/GameModels';
import { LocalGameRepository } from '../repository/LocalGameRepository';
import { GameStore, MoveHandling } from '../store/GameStore';
import { PreferenceStore } from '../service/PreferenceStore';
import { MatchStore, MatchStateListener } from '../match/MatchStore';
import { DailyClient } from '../network/DailyClient';
import { SoundPlayer } from '../service/SoundPlayer';
import { vibrator } from '@kit.SensorServiceKit';
import { promptAction } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';

@Entry
@Component
struct Index implements MatchStateListener {
  @State screen: AppScreen = AppScreen.SPLASH;
  @State board: string[] = ['', '', '', '', '', '', '', '', ''];
  @State turnText: string = '轮到你了';
  @State result: MatchResult | null = null;
  @State boardSize: number = 3;
  @State currentKind: GameKind = GameKind.AI_3X3;
  @State settings: Settings = new Settings();
  @State network: NetworkRoom = new NetworkRoom();
  private readonly gameStore: GameStore = new GameStore(new LocalGameRepository());
  private readonly matchStore: MatchStore = new MatchStore();
  private readonly dailyClient: DailyClient = new DailyClient();
  private readonly soundPlayer: SoundPlayer = new SoundPlayer();
  private context: Context | null = null;

  aboutToAppear(): void {
    this.matchStore.setListener(this);
    const ctx = getContext(this);
    this.context = ctx;
    PreferenceStore.getInstance().init(ctx).then(() => {
      const loaded = PreferenceStore.getInstance().loadSettings();
      this.settings = loaded;
      this.gameStore.setSettings(loaded);
      this.soundPlayer.setEnabled(loaded.sound);
      AppStorage.setOrCreate('isDarkMode', loaded.darkMode);
    }).catch(() => {
      // ignore
    });
    setTimeout(() => {
      if (this.screen === AppScreen.SPLASH) {
        this.screen = AppScreen.ONBOARDING;
      }
    }, 900);
  }

  aboutToDisappear(): void {
    this.matchStore.close();
    this.matchStore.setListener(null);
    this.soundPlayer.release();
  }

  showHome(): void {
    this.refreshRecords();
    this.screen = AppScreen.HOME;
  }

  refreshRecords(): void {
    this.gameStore.session = new GameSession();
  }

  async startGame(kind: GameKind): Promise<void> {
    this.currentKind = kind;
    this.matchStore.close();
    if (kind === GameKind.DAILY) {
      const remote = await this.dailyClient.fetchDailyPuzzle();
      const puzzle = remote ?? this.gameStore.fallbackPuzzle();
      this.gameStore.start(kind, puzzle);
    } else {
      this.gameStore.start(kind);
    }
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
    const move = new Move(row, col);

    if (this.currentKind === GameKind.NETWORK) {
      this.matchStore.netPlay(move);
      return;
    }

    const decision = await this.gameStore.play(move);
    if (decision.handling === MoveHandling.REJECTED) {
      this.showToast(decision.message);
      return;
    }
    this.tapFeedback();
    this.syncGameState();
    if (this.gameStore.session.isAiThinking) {
      await this.gameStore.playAiTurn();
      this.tapFeedback();
      this.syncGameState();
    }
    if (this.gameStore.result !== null) {
      this.result = this.gameStore.result;
      this.screen = AppScreen.RESULT;
    }
  }

  undo(): void {
    if (this.gameStore.undo()) {
      this.tapFeedback();
      this.syncGameState();
    }
  }

  async surrender(): Promise<void> {
    if (this.currentKind === GameKind.NETWORK) {
      this.matchStore.netSurrender();
      return;
    }
    await this.gameStore.surrender();
    this.syncGameState();
    this.result = this.gameStore.result;
    if (this.result !== null) {
      this.screen = AppScreen.RESULT;
    }
  }

  onCreateRoom(): void {
    this.currentKind = GameKind.NETWORK;
    this.gameStore.start(GameKind.NETWORK);
    this.syncGameState();
    this.matchStore.createRoom();
  }

  onJoinRoom(code: string): void {
    this.currentKind = GameKind.NETWORK;
    this.gameStore.start(GameKind.NETWORK);
    this.syncGameState();
    this.matchStore.joinRoom(code);
  }

  onRoomBack(): void {
    this.matchStore.close();
    this.showHome();
  }

  setSound(enabled: boolean): void {
    this.settings = this.settings.copy({ sound: enabled });
    this.gameStore.setSettings(this.settings);
    this.soundPlayer.setEnabled(enabled);
    this.saveSettings();
  }

  setVibration(enabled: boolean): void {
    this.settings = this.settings.copy({ vibration: enabled });
    this.gameStore.setSettings(this.settings);
    this.saveSettings();
  }

  setDarkMode(enabled: boolean): void {
    this.settings = this.settings.copy({ darkMode: enabled });
    this.gameStore.setSettings(this.settings);
    AppStorage.setOrCreate('isDarkMode', enabled);
    this.saveSettings();
  }

  private saveSettings(): void {
    PreferenceStore.getInstance().saveSettings(this.settings).catch(() => {
      // ignore
    });
  }

  gameModeText(): string {
    if (this.currentKind === GameKind.AI_5X5) {
      return '进阶 5×5';
    }
    if (this.currentKind === GameKind.LOGIC_6X6) {
      return '逻辑 OOXX 6×6';
    }
    if (this.currentKind === GameKind.LOCAL) {
      return '双人同屏';
    }
    if (this.currentKind === GameKind.DAILY) {
      return '每日挑战';
    }
    if (this.currentKind === GameKind.NETWORK) {
      return '网络对战';
    }
    if (this.currentKind === GameKind.BLUETOOTH) {
      return '蓝牙对战';
    }
    return '经典 3×3';
  }

  syncGameState(): void {
    const session = this.gameStore.session;
    if (session.kind === GameKind.LOGIC_6X6 && session.logicBoard !== null) {
      this.boardSize = session.logicBoard.size;
      const cells: string[] = [];
      for (let index = 0; index < session.logicBoard.cells.length; index++) {
        cells.push(session.logicBoard.cells[index] === Mark.EMPTY ? '' : session.logicBoard.cells[index]);
      }
      this.board = cells;
      this.turnText = session.message;
      return;
    }
    this.boardSize = session.board.size;
    const cells: string[] = [];
    for (let index = 0; index < session.board.cells.length; index++) {
      cells.push(session.board.cells[index] === Mark.EMPTY ? '' : session.board.cells[index]);
    }
    this.board = cells;
    this.turnText = session.message;
  }

  // MatchStateListener
  onNetworkChanged(network: NetworkRoom): void {
    this.network = network;
  }

  onGameSessionChanged(session: GameSession): void {
    this.gameStore.applyAuthoritativeState(session, null);
    this.syncGameState();
  }

  onScreenChanged(screen: AppScreen): void {
    this.screen = screen;
  }

  onFinished(result: MatchResult): void {
    this.gameStore.applyAuthoritativeState(this.gameStore.session, result);
    this.result = result;
    this.screen = AppScreen.RESULT;
  }

  private tapFeedback(): void {
    if (this.settings.sound) {
      this.soundPlayer.beep();
    }
    if (this.settings.vibration) {
      try {
        vibrator.startVibration({ type: 'time', duration: 30 }, { usage: 'touch' });
      } catch {
        // ignore
      }
    }
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({ message, duration: 2000 });
    } catch {
      // ignore
    }
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
          onStartDaily: () => this.startGame(GameKind.DAILY),
          onStartLogic: () => this.startGame(GameKind.LOGIC_6X6)
        })
      } else if (this.screen === AppScreen.ROOM) {
        RoomPage({
          network: this.network,
          onBack: () => this.onRoomBack(),
          onCreate: () => this.onCreateRoom(),
          onJoin: (code: string) => this.onJoinRoom(code)
        })
      } else if (this.screen === AppScreen.GAME) {
        GamePage({
          board: this.board,
          playerTurn: this.turnText,
          isLocal: this.currentKind === GameKind.LOCAL,
          isNetwork: this.currentKind === GameKind.NETWORK,
          isLogic: this.currentKind === GameKind.LOGIC_6X6,
          kind: this.currentKind,
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
          settings: this.settings,
          onBack: () => this.showHome(),
          onOpenHistory: () => this.screen = AppScreen.HISTORY,
          onSoundChanged: (enabled: boolean) => this.setSound(enabled),
          onVibrationChanged: (enabled: boolean) => this.setVibration(enabled),
          onDarkModeChanged: (enabled: boolean) => this.setDarkMode(enabled)
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
