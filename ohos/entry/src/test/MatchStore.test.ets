import { describe, it, expect } from '@ohos/hypium';
import { AppScreen, GameSession, MatchResult, NetworkRoom } from '../main/ets/model/AppModels';
import { Mark, Move } from '../main/ets/model/GameModels';
import { MatchStateListener, MatchStore } from '../main/ets/match/MatchStore';
import { MatchConnection, MatchTransport } from '../main/ets/match/MatchTransport';
import { RoomSnapshotPayload } from '../main/ets/match/RoomProtocol';

class FakeMatchConnection implements MatchConnection {
  readonly sent: string[] = [];
  private readonly queued: string[] = [];
  private pendingResolve: ((value: string | null) => void) | null = null;
  private closed: boolean = false;

  async send(message: string): Promise<void> {
    if (this.closed) {
      throw new Error('连接已关闭');
    }
    this.sent.push(message);
  }

  async receive(): Promise<string | null> {
    if (this.queued.length > 0) {
      return this.queued.shift()!;
    }
    if (this.closed) {
      return null;
    }
    return new Promise((resolve) => {
      this.pendingResolve = resolve;
    });
  }

  push(message: string): void {
    if (this.pendingResolve !== null) {
      const resolve = this.pendingResolve;
      this.pendingResolve = null;
      resolve(message);
      return;
    }
    this.queued.push(message);
  }

  close(): void {
    this.closed = true;
    if (this.pendingResolve !== null) {
      const resolve = this.pendingResolve;
      this.pendingResolve = null;
      resolve(null);
    }
  }
}

class FakeMatchTransport implements MatchTransport {
  readonly connection: FakeMatchConnection;
  readonly failure: Error | null;
  connectCount: number = 0;

  constructor(connection: FakeMatchConnection = new FakeMatchConnection(), failure: Error | null = null) {
    this.connection = connection;
    this.failure = failure;
  }

  async connect(): Promise<MatchConnection> {
    this.connectCount++;
    if (this.failure !== null) {
      throw this.failure;
    }
    return this.connection;
  }
}

class RecordingMatchListener implements MatchStateListener {
  networks: NetworkRoom[] = [];
  sessions: GameSession[] = [];
  screens: AppScreen[] = [];
  results: MatchResult[] = [];

  onNetworkChanged(network: NetworkRoom): void {
    this.networks.push(network);
  }

  onGameSessionChanged(session: GameSession): void {
    this.sessions.push(session);
  }

  onScreenChanged(screen: AppScreen): void {
    this.screens.push(screen);
  }

  onFinished(result: MatchResult): void {
    this.results.push(result);
  }
}

function roomPayload(status: string = 'PLAYING', turn: string = 'X', winner: string | null = null): RoomSnapshotPayload {
  return {
    code: 'ABC123',
    size: 3,
    winLength: 3,
    board: [['X', '', ''], ['', 'O', ''], ['', '', '']],
    turn,
    status,
    winner,
    yourMark: 'X',
    players: [
      { id: 'mine', name: '康思', mark: 'X' },
      { id: 'other', name: '小明', mark: 'O' }
    ],
    spectators: []
  };
}

function roomEvent(type: string, payload: RoomSnapshotPayload): string {
  return JSON.stringify({ type, room: payload });
}

async function flushAsync(): Promise<void> {
  await new Promise<void>((resolve) => setTimeout(resolve, 20));
}

export default function matchStoreTest() {
  describe('MatchStore', () => {
    it('connectsOnceAndSendsHelloBeforeRoomAction', 0, async () => {
      const transport = new FakeMatchTransport();
      const store = new MatchStore(transport, () => 'guest-test');

      store.createRoom();
      await flushAsync();

      expect(transport.connectCount).assertEqual(1);
      expect(transport.connection.sent.length).assertEqual(2);
      expect(transport.connection.sent[0]).assertEqual(RoomProtocolHello);
      expect(transport.connection.sent[1]).assertEqual('{"type":"room.create","size":3,"winLength":3}');
      store.close();
    });

    it('appliesAuthoritativePlayingRoomAndTurnPrompt', 0, async () => {
      const transport = new FakeMatchTransport();
      const listener = new RecordingMatchListener();
      const store = new MatchStore(transport, () => 'guest-test');
      store.setListener(listener);
      store.joinRoom('ABC123');
      await flushAsync();

      transport.connection.push(roomEvent('room.state', roomPayload('PLAYING', 'O')));
      await flushAsync();

      expect(listener.sessions.length).assertEqual(1);
      expect(listener.sessions[0].board.get(0, 0)).assertEqual(Mark.X);
      expect(listener.sessions[0].turn).assertEqual(Mark.O);
      expect(listener.sessions[0].message).assertEqual('轮到 O 落子 · 等待对方');
      expect(listener.screens[0]).assertEqual(AppScreen.GAME);
      expect(store.network.roomCode).assertEqual('ABC123');
      expect(store.network.statusMessage).assertEqual('对局中 · 你执X');
      store.close();
    });

    it('blocksDuplicateMovesUntilNextRoomSnapshot', 0, async () => {
      const transport = new FakeMatchTransport();
      const store = new MatchStore(transport, () => 'guest-test');
      store.createRoom();
      await flushAsync();

      store.netPlay(new Move(0, 1));
      store.netPlay(new Move(0, 2));
      await flushAsync();
      expect(transport.connection.sent.length).assertEqual(3);
      expect(transport.connection.sent[2]).assertEqual('{"type":"move","row":0,"col":1}');

      transport.connection.push(roomEvent('room.state', roomPayload('PLAYING', 'X')));
      await flushAsync();
      store.netPlay(new Move(0, 2));
      await flushAsync();
      expect(transport.connection.sent.length).assertEqual(4);
      expect(transport.connection.sent[3]).assertEqual('{"type":"move","row":0,"col":2}');
      store.close();
    });

    it('notifiesFinishedResultFromServerSnapshot', 0, async () => {
      const transport = new FakeMatchTransport();
      const listener = new RecordingMatchListener();
      const store = new MatchStore(transport, () => 'guest-test');
      store.setListener(listener);
      store.createRoom();
      await flushAsync();

      transport.connection.push(roomEvent('room.state', roomPayload('FINISHED', 'X', 'X')));
      await flushAsync();

      expect(listener.sessions[0].message).assertEqual('对局已结束');
      expect(listener.results[0]).assertEqual(MatchResult.WIN);
      store.close();
    });

    it('mapsServerFailureAndConnectionFailureToRecoverableState', 0, async () => {
      const transport = new FakeMatchTransport();
      const store = new MatchStore(transport, () => 'guest-test');
      store.createRoom();
      await flushAsync();
      transport.connection.push('{"type":"error","code":"NOT_YOUR_TURN","message":"server text"}');
      await flushAsync();
      expect(store.network.error).assertEqual('还没有轮到你');
      store.close();

      const failed = new MatchStore(new FakeMatchTransport(new FakeMatchConnection(), new Error('网络不可达')),
        () => 'guest-test');
      failed.createRoom();
      await flushAsync();
      expect(failed.network.connecting).assertFalse();
      expect(failed.network.error).assertEqual('无法连接对战服务器，请稍后再试');
    });
  });
}

const RoomProtocolHello: string = '{"type":"hello","playerId":"guest-test","name":"康思"}';
