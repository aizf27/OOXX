import { describe, it, expect } from '@ohos/hypium';
import { MatchResult } from '../main/ets/model/AppModels';
import { Mark } from '../main/ets/model/GameModels';
import {
  ConnectedRoomEvent,
  FailureRoomEvent,
  HelloOkRoomEvent,
  RoomCreatedEvent,
  RoomProtocol,
  RoomSnapshot,
  RoomSnapshotPayload,
  RoomStateEvent
} from '../main/ets/match/RoomProtocol';

function snapshotPayload(status: string = 'PLAYING', winner: string | null = null,
  yourMark: string | null = 'X'): RoomSnapshotPayload {
  return {
    code: 'ABC123',
    size: 3,
    winLength: 3,
    board: [['X', 'O', ''], ['', 'X', ''], ['', '', '']],
    turn: 'O',
    status,
    winner,
    yourMark,
    players: [
      { id: 'mine', name: '康思', mark: 'X' },
      { id: 'other', name: '小明', mark: 'O' }
    ],
    spectators: []
  };
}

export default function roomProtocolTest() {
  describe('RoomProtocol', () => {
    it('serializesEveryClientMessage', 0, () => {
      expect(RoomProtocol.hello('p1', '康思')).assertEqual('{"type":"hello","playerId":"p1","name":"康思"}');
      expect(RoomProtocol.createRoom(3)).assertEqual('{"type":"room.create","size":3,"winLength":3}');
      expect(RoomProtocol.createRoom(5)).assertEqual('{"type":"room.create","size":5,"winLength":4}');
      expect(RoomProtocol.joinRoom('ABC123')).assertEqual('{"type":"room.join","code":"ABC123"}');
      expect(RoomProtocol.requestRoomState('ABC123')).assertEqual('{"type":"room.state","code":"ABC123"}');
      expect(RoomProtocol.move(1, 2)).assertEqual('{"type":"move","row":1,"col":2}');
      expect(RoomProtocol.surrender()).assertEqual('{"type":"game.surrender"}');
    });

    it('decodesConnectionAndFailureEvents', 0, () => {
      const connected = RoomProtocol.decode('{"type":"connected","playerId":"guest-1"}');
      expect(connected instanceof ConnectedRoomEvent).assertTrue();
      if (connected instanceof ConnectedRoomEvent) {
        expect(connected.playerId).assertEqual('guest-1');
      }

      const hello = RoomProtocol.decode('{"type":"hello.ok","playerId":"guest-1","name":"康思"}');
      expect(hello instanceof HelloOkRoomEvent).assertTrue();
      if (hello instanceof HelloOkRoomEvent) {
        expect(hello.name).assertEqual('康思');
      }

      const failure = RoomProtocol.decode('{"type":"error","code":"ROOM_NOT_FOUND","message":"不存在"}');
      expect(failure instanceof FailureRoomEvent).assertTrue();
      if (failure instanceof FailureRoomEvent) {
        expect(failure.code).assertEqual('ROOM_NOT_FOUND');
        expect(failure.message).assertEqual('不存在');
      }
    });

    it('decodesRoomCreatedAndPlayingSnapshot', 0, () => {
      const payload = snapshotPayload();
      const created = RoomProtocol.decode(JSON.stringify({ type: 'room.created', room: payload }));
      expect(created instanceof RoomCreatedEvent).assertTrue();

      const state = RoomProtocol.decode(JSON.stringify({ type: 'room.state', room: payload }));
      expect(state instanceof RoomStateEvent).assertTrue();
      if (state instanceof RoomStateEvent) {
        expect(state.room.code).assertEqual('ABC123');
        expect(state.room.board.get(0, 0)).assertEqual(Mark.X);
        expect(state.room.board.get(0, 1)).assertEqual(Mark.O);
        expect(state.room.board.get(2, 2)).assertEqual(Mark.EMPTY);
        expect(state.room.turn).assertEqual(Mark.O);
        expect(state.room.yourMark).assertEqual(Mark.X);
        expect(state.room.opponentName).assertEqual('小明');
        expect(state.room.isPlaying).assertTrue();
      }
    });

    it('mapsFinishedSnapshotToWinLossAndDraw', 0, () => {
      expect(new RoomSnapshot(snapshotPayload('FINISHED', 'X')).toMatchResult()).assertEqual(MatchResult.WIN);
      expect(new RoomSnapshot(snapshotPayload('FINISHED', 'O')).toMatchResult()).assertEqual(MatchResult.LOSS);
      expect(new RoomSnapshot(snapshotPayload('FINISHED', 'DRAW')).toMatchResult()).assertEqual(MatchResult.DRAW);
      expect(new RoomSnapshot(snapshotPayload('PLAYING', null)).toMatchResult()).assertNull();
    });

    it('doesNotAssignPersonalResultToSpectator', 0, () => {
      const payload = snapshotPayload('FINISHED', 'X', null);
      expect(new RoomSnapshot(payload).yourMark).assertNull();
      expect(new RoomSnapshot(payload).toMatchResult()).assertNull();
    });

    it('returnsNullForUnknownOrMalformedMessages', 0, () => {
      expect(RoomProtocol.decode('{"type":"unknown"}')).assertNull();
      expect(RoomProtocol.decode('{bad json')).assertNull();
      expect(RoomProtocol.decode('{"type":"room.state","room":null}')).assertNull();
    });
  });
}
