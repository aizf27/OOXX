import { AppScreen, GameKind, GameSession, MatchResult, NetworkRoom } from '../model/AppModels';
import { Mark, Move } from '../model/GameModels';
import { PreferenceStore } from '../service/PreferenceStore';
import { MatchConnection } from './MatchTransport';
import {
  FailureRoomEvent,
  RoomCreatedEvent,
  RoomProtocol,
  RoomSnapshot,
  RoomStateEvent,
  RoomEventUnion
} from './RoomProtocol';
import { WebSocketMatchClient } from './WebSocketMatchClient';

const WS_URL = 'ws://47.243.15.216:9527/ws';

export interface MatchStateListener {
  onNetworkChanged(network: NetworkRoom): void;
  onGameSessionChanged(session: GameSession): void;
  onScreenChanged(screen: AppScreen): void;
  onFinished(result: MatchResult): void;
}

export class MatchStore {
  network: NetworkRoom = new NetworkRoom();
  private connection: MatchConnection | null = null;
  private connecting: boolean = false;
  private awaitingRoomState: boolean = false;
  private playerId: string | null = null;
  private listener: MatchStateListener | null = null;

  private getPlayerId(): string {
    if (this.playerId === null) {
      this.playerId = PreferenceStore.getInstance().loadPlayerId();
    }
    return this.playerId;
  }

  setListener(listener: MatchStateListener | null): void {
    this.listener = listener;
  }

  createRoom(): void {
    this.matchAction((conn) => conn.send(RoomProtocol.createRoom(3, 3)));
  }

  joinRoom(code: string): void {
    this.matchAction((conn) => conn.send(RoomProtocol.joinRoom(code)));
  }

  netPlay(move: Move): void {
    if (this.awaitingRoomState) {
      return;
    }
    this.awaitingRoomState = true;
    this.matchAction((conn) => conn.send(RoomProtocol.move(move.row, move.col)));
  }

  netSurrender(): void {
    this.matchAction((conn) => conn.send(RoomProtocol.surrender()));
  }

  close(): void {
    this.connecting = false;
    this.awaitingRoomState = false;
    try {
      this.connection?.close();
    } catch {
      // ignore
    }
    this.connection = null;
  }

  private matchAction(action: (conn: MatchConnection) => Promise<void>): void {
    const run = async (): Promise<void> => {
      const conn = await this.ensureConnection();
      if (conn === null) {
        this.awaitingRoomState = false;
        return;
      }
      try {
        await action(conn);
      } catch {
        this.awaitingRoomState = false;
        this.updateNetwork({ error: '连接已断开，请重新创建或加入房间' });
        this.close();
      }
    };
    run().catch(() => {
      this.awaitingRoomState = false;
      this.updateNetwork({ error: '连接已断开，请重新创建或加入房间' });
    });
  }

  private async ensureConnection(): Promise<MatchConnection | null> {
    if (this.connection !== null) {
      return this.connection;
    }
    if (this.connecting) {
      // 等待当前连接完成
      for (let i = 0; i < 30; i++) {
        await new Promise((resolve) => setTimeout(resolve, 100));
        if (this.connection !== null) {
          return this.connection;
        }
        if (!this.connecting) {
          break;
        }
      }
      return this.connection;
    }
    this.connecting = true;
    this.updateNetwork({ connecting: true, error: null });
    try {
      const conn = await new WebSocketMatchClient(WS_URL).connect();
      this.connection = conn;
      this.connecting = false;
      this.updateNetwork({ connecting: false, statusMessage: '已连接服务器' });
      try {
        await conn.send(RoomProtocol.hello(this.getPlayerId(), '康思'));
      } catch {
        this.close();
        return null;
      }
      this.startReceiveLoop(conn);
      return this.connection;
    } catch {
      this.connecting = false;
      this.updateNetwork({ connecting: false, error: '无法连接对战服务器，请稍后再试' });
      return null;
    }
  }

  private startReceiveLoop(conn: MatchConnection): void {
    const loop = async (): Promise<void> => {
      while (this.connection === conn) {
        try {
          const text = await conn.receive();
          if (text === null) {
            break;
          }
          const event = RoomProtocol.decode(text);
          if (event !== null) {
            this.handleRoomEvent(event);
          }
        } catch {
          break;
        }
      }
      this.onDisconnected(conn);
    };
    loop().catch(() => {
      this.onDisconnected(conn);
    });
  }

  private handleRoomEvent(event: RoomEventUnion): void {
    if (event instanceof ConnectedRoomEvent || event instanceof HelloOkRoomEvent) {
      return;
    }
    if (event instanceof RoomCreatedEvent) {
      this.awaitingRoomState = false;
      this.updateNetwork({
        roomCode: event.room.code,
        waiting: !event.room.isPlaying,
        statusMessage: event.room.isPlaying ? '对手已加入，开始对局' : '房间已创建，等待好友加入…',
        error: null
      });
      this.applyRoomSnapshot(event.room);
      return;
    }
    if (event instanceof RoomStateEvent) {
      this.applyRoomSnapshot(event.room);
      return;
    }
    if (event instanceof FailureRoomEvent) {
      this.awaitingRoomState = false;
      this.updateNetwork({ error: this.errorText(event.code) });
    }
  }

  private applyRoomSnapshot(room: RoomSnapshot): void {
    this.awaitingRoomState = false;
    if (room.isFinished) {
      const result = room.toMatchResult();
      if (result !== null) {
        const session = new GameSession(
          room.board,
          room.turn,
          room.yourMark ?? Mark.X,
          GameKind.NETWORK,
          0,
          '对局已结束',
          null,
          null,
          false,
          room.opponentName
        );
        this.notifyGameSession(session);
        this.notifyFinished(result);
        return;
      }
    }
    const session = new GameSession(
      room.board,
      room.turn,
      room.yourMark ?? Mark.X,
      GameKind.NETWORK,
      0,
      this.messageFor(room),
      null,
      null,
      false,
      room.opponentName
    );
    this.updateNetwork({
      roomCode: room.code,
      waiting: room.isWaiting,
      statusMessage: room.isPlaying
        ? `对局中 · 你执${room.yourMark === Mark.X ? 'X' : 'O'}`
        : room.isWaiting ? '等待对手加入…' : this.network.statusMessage,
      error: null
    });
    this.notifyGameSession(session);
    if (room.isPlaying) {
      this.notifyScreen(AppScreen.GAME);
    }
  }

  private messageFor(room: RoomSnapshot): string {
    if (room.isWaiting) {
      return '等待对手加入…';
    }
    if (room.yourMark === null) {
      return '观战中';
    }
    if (room.turn === room.yourMark) {
      return '轮到你了';
    }
    return '等待对方落子…';
  }

  private errorText(code: string): string {
    const map: Record<string, string> = {
      'ROOM_NOT_FOUND': '房间不存在或已结束',
      'ROOM_FULL': '房间已满员',
      'NOT_YOUR_TURN': '还没有轮到你',
      'CELL_OCCUPIED': '该位置已有棋子',
      'GAME_NOT_READY': '等待另一位玩家加入'
    };
    return map[code] ?? '未知错误';
  }

  private onDisconnected(conn: MatchConnection): void {
    if (this.connection !== conn) {
      return;
    }
    this.connection = null;
    this.connecting = false;
    this.updateNetwork({ statusMessage: '与服务器断开连接' });
  }

  private updateNetwork(params: Partial<NetworkRoom>): void {
    this.network = this.network.copy(params);
    this.listener?.onNetworkChanged(this.network);
  }

  private notifyGameSession(session: GameSession): void {
    this.listener?.onGameSessionChanged(session);
  }

  private notifyScreen(screen: AppScreen): void {
    this.listener?.onScreenChanged(screen);
  }

  private notifyFinished(result: MatchResult): void {
    this.listener?.onFinished(result);
  }
}
