package com.kangsi.ooxx.match

import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.game.Mark
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class RoomProtocolTest {

    @Test
    fun `出向消息带正确的 type 与字段`() {
        assertTrue(JSONObject(RoomProtocol.hello("p1", "康思")).let { it.getString("type") == "hello" && it.getString("playerId") == "p1" })
        assertTrue(JSONObject(RoomProtocol.createRoom(size = 3)).let { it.getString("type") == "room.create" && it.getInt("size") == 3 })
        assertTrue(JSONObject(RoomProtocol.joinRoom("ab12cd")).let { it.getString("type") == "room.join" && it.getString("code") == "ab12cd" })
        assertTrue(JSONObject(RoomProtocol.move(1, 2)).let { it.getString("type") == "move" && it.getInt("row") == 1 && it.getInt("col") == 2 })
        assertEquals("game.surrender", JSONObject(RoomProtocol.surrender()).getString("type"))
    }

    @Test
    fun `解析 connected 事件`() {
        val event = RoomProtocol.decode("""{"type":"connected","playerId":"guest-1","protocol":1}""")
        assertEquals(RoomEvent.Connected("guest-1"), event)
    }

    @Test
    fun `解析对局中的房间快照`() {
        val event = RoomProtocol.decode(
            """{"type":"room.state","room":{"code":"ABC123","size":3,"winLength":3,
               "board":[["X","O",""],["","",""],["","",""]],
               "turn":"O","status":"PLAYING","winner":null,"yourMark":"X",
               "players":[{"id":"a","name":"康思","mark":"X"},{"id":"b","name":"小明","mark":"O"}],"spectators":[]}}""".trimMargin()
        )
        val room = (event as RoomEvent.RoomState).room
        assertEquals("ABC123", room.code)
        assertEquals(Mark.X, room.board[0, 0])
        assertEquals(Mark.O, room.board[0, 1])
        assertEquals(Mark.EMPTY, room.board[2, 2])
        assertEquals(Mark.O, room.turn)
        assertTrue(room.isPlaying)
        assertEquals(Mark.X, room.yourMark)
        assertEquals("小明", room.opponentName)
    }

    @Test
    fun ` finished 快照映射胜负`() {
        fun snapshot(winner: String?, yourMark: String) = RoomProtocol.decode(
            """{"type":"room.state","room":{"code":"ABC123","size":3,"winLength":3,
               "board":[["X","X","X"],["O","O",""],["","",""]],
               "turn":"X","status":"FINISHED","winner":$winner,"yourMark":"$yourMark",
               "players":[{"id":"a","name":"康思","mark":"$yourMark"}],"spectators":[]}}"""
        ).let { (it as RoomEvent.RoomState).room }

        assertEquals(MatchResult.WIN, snapshot("\"X\"", "X").toMatchResult())
        assertEquals(MatchResult.LOSS, snapshot("\"O\"", "X").toMatchResult())
        assertEquals(MatchResult.DRAW, snapshot("\"DRAW\"", "X").toMatchResult())
        assertNull(snapshot("null", "X").toMatchResult())
    }

    @Test
    fun `解析错误事件`() {
        val event = RoomProtocol.decode("""{"type":"error","code":"ROOM_NOT_FOUND","message":"房间不存在或已结束"}""")
        assertEquals(RoomEvent.Failure("ROOM_NOT_FOUND", "房间不存在或已结束"), event)
        assertFalse((event as RoomEvent.Failure).message.isEmpty())
    }
}
