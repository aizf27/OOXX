export interface MatchConnection {
  send(message: string): Promise<void>;
  receive(): Promise<string | null>;
  close(): void;
}

export interface MatchTransport {
  connect(): Promise<MatchConnection>;
}
