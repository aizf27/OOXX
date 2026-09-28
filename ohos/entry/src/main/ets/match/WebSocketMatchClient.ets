import { webSocket } from '@kit.NetworkKit';
import { MatchConnection } from './MatchTransport';

const DEFAULT_WS_URL = 'ws://47.243.15.216:9527/ws';

export class WebSocketMatchConnection implements MatchConnection {
  private socket: webSocket.WebSocket;
  private queue: string[] = [];
  private pendingResolve: ((value: string | null) => void) | null = null;
  private closed: boolean = false;

  constructor(socket: webSocket.WebSocket) {
    this.socket = socket;
    this.socket.on('message', (err: Error, data: string | ArrayBuffer) => {
      if (err !== undefined && err !== null) {
        return;
      }
      const text = typeof data === 'string' ? data : this.bufferToString(data);
      if (this.pendingResolve !== null) {
        const resolve = this.pendingResolve;
        this.pendingResolve = null;
        resolve(text);
      } else {
        this.queue.push(text);
      }
    });
    this.socket.on('close', () => {
      this.closed = true;
      this.resolvePending(null);
    });
    this.socket.on('error', () => {
      this.closed = true;
      this.resolvePending(null);
    });
  }

  async send(message: string): Promise<void> {
    if (this.closed) {
      throw new Error('WebSocket 已关闭');
    }
    this.socket.send(message);
  }

  async receive(): Promise<string | null> {
    if (this.queue.length > 0) {
      return this.queue.shift()!;
    }
    if (this.closed) {
      return null;
    }
    return new Promise((resolve) => {
      this.pendingResolve = resolve;
    });
  }

  close(): void {
    this.closed = true;
    this.resolvePending(null);
    try {
      this.socket.close();
    } catch {
      // ignore
    }
  }

  private resolvePending(value: string | null): void {
    if (this.pendingResolve !== null) {
      const resolve = this.pendingResolve;
      this.pendingResolve = null;
      resolve(value);
    }
  }

  private bufferToString(buffer: ArrayBuffer): string {
    const view = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < view.length; i++) {
      result += String.fromCharCode(view[i]);
    }
    return result;
  }
}

export class WebSocketMatchClient {
  private readonly url: string;

  constructor(url: string = DEFAULT_WS_URL) {
    this.url = url;
  }

  async connect(): Promise<MatchConnection> {
    return new Promise((resolve, reject) => {
      const socket = webSocket.createWebSocket();
      let settled = false;

      const cleanup = (): void => {
        try {
          socket.off('open');
          socket.off('error');
        } catch {
          // ignore
        }
      };

      socket.on('open', () => {
        if (settled) {
          return;
        }
        settled = true;
        cleanup();
        resolve(new WebSocketMatchConnection(socket));
      });

      socket.on('error', (err: Error) => {
        if (settled) {
          return;
        }
        settled = true;
        cleanup();
        reject(new Error(err?.message ?? 'WebSocket 连接失败'));
      });

      try {
        socket.connect(this.url);
      } catch (err) {
        if (!settled) {
          settled = true;
          cleanup();
          reject(new Error('WebSocket 连接失败'));
        }
      }
    });
  }
}
