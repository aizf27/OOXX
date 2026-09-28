package com.kangsi.ooxx.match

import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.game.Mark
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** 蓝牙对战没有服务器，主机端 RoomAuthority 必须能独立判胜负并产出可被客户端解析的快照。 */
class BluetoothRoomTest {

    private fun guestState(room: RoomAuthority): RoomSnapshot {
        val event = RoomProtocol.decode(room.snapshotFor(room.guestId!!))
        assertTrue(event is RoomEvent.RoomState)
        return (event as RoomEvent.RoomState).room
    }

    @Test
    fun hostIsXAndGuestIsO() {
        val room = RoomAuthority(hostName = "康思")
        room.joinGuest("guest-1", "小明")
        val state = guestState(room)
        assertEquals(Mark.O, state.yourMark)
        assertEquals("康思", state.opponentName)
        assertEquals("PLAYING", state.status)
        assertEquals(Mark.X, state.turn)
    }

    @Test
    fun illegalMovesAreRejected() {
        val room = RoomAuthority()
        room.joinGuest("guest-1", "小明")
        assertFalse("客机不能抢先手", room.move("guest-1", 0, 0))
        assertTrue(room.move("host", 0, 0))
        assertFalse("同一格不能重复落子", room.move("guest-1", 0, 0))
        assertFalse("越界坐标", room.move("guest-1", 3, 0))
        assertFalse("未加入的第三方", room.move("stranger", 1, 1))
    }

    @Test
    fun hostWinsByColumnAndSnapshotCarriesResult() {
        val room = RoomAuthority()
        room.joinGuest("guest-1", "小明")
        room.move("host", 0, 0)
        room.move("guest-1", 0, 1)
        room.move("host", 1, 0)
        room.move("guest-1", 1, 1)
        room.move("host", 2, 0)

        val hostState = (RoomProtocol.decode(room.snapshotFor(room.hostId)) as RoomEvent.RoomState).room
        assertEquals("FINISHED", hostState.status)
        assertEquals("X", hostState.winner)
        assertEquals(MatchResult.WIN, hostState.toMatchResult())

        val guest = guestState(room)
        assertEquals(MatchResult.LOSS, guest.toMatchResult())
        assertEquals(Mark.X, guest.board[2, 0])
    }

    @Test
    fun surrenderGivesWinToOpponent() {
        val room = RoomAuthority()
        room.joinGuest("guest-1", "小明")
        room.surrender("guest-1")
        val host = (RoomProtocol.decode(room.snapshotFor(room.hostId)) as RoomEvent.RoomState).room
        assertEquals(MatchResult.WIN, host.toMatchResult())
    }

    @Test
    fun drawIsDetected() {
        val room = RoomAuthority()
        room.joinGuest("guest-1", "小明")
        // X: (0,0)(0,1)(1,2)(2,0)(2,2)  O: (0,2)(1,0)(1,1)(2,1)
        val script = listOf(
            "host" to (0 to 0), "guest-1" to (0 to 2),
            "host" to (0 to 1), "guest-1" to (1 to 0),
            "host" to (1 to 2), "guest-1" to (1 to 1),
            "host" to (2 to 0), "guest-1" to (2 to 1),
            "host" to (2 to 2)
        )
        script.forEach { (player, cell) -> assertTrue(room.move(player, cell.first, cell.second)) }
        val host = (RoomProtocol.decode(room.snapshotFor(room.hostId)) as RoomEvent.RoomState).room
        assertEquals("DRAW", host.winner)
        assertEquals(MatchResult.DRAW, host.toMatchResult())
    }

    @Test
    fun clientMessagesAreDecoded() {
        assertEquals(
            ClientEvent.Hello("guest-9", "小明"),
            RoomProtocol.decodeClient("""{"type":"hello","playerId":"guest-9","name":"小明"}""")
        )
        assertEquals(ClientEvent.Move(1, 2), RoomProtocol.decodeClient("""{"type":"move","row":1,"col":2}"""))
        assertEquals(ClientEvent.Surrender, RoomProtocol.decodeClient("""{"type":"game.surrender"}"""))
        assertNull(RoomProtocol.decodeClient("""{"type":"room.state"}"""))
        assertNull(RoomProtocol.decodeClient("not json"))
    }
}
