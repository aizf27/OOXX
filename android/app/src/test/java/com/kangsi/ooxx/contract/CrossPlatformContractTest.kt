package com.kangsi.ooxx.contract

import com.kangsi.ooxx.data.DailyPuzzleParser
import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.data.MatchScore
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.match.RoomEvent
import com.kangsi.ooxx.match.RoomProtocol
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CrossPlatformContractTest {

    @Test
    fun `公共棋盘规则与积分符合契约`() {
        val contract = contract("game-rules.v1.json")
        assertEquals(1, contract.getInt("version"))

        val cases = contract.getJSONArray("cases")
        for (index in 0 until cases.length()) {
            val case = cases.getJSONObject(index)
            val board = boardFrom(case)
            val expectedWinner = case.optString("winner").takeIf { it.isNotEmpty() && it != "null" }?.toMark()
            assertEquals(case.getString("id"), expectedWinner, board.winner())
            assertEquals(case.getString("id"), case.getBoolean("draw"), board.isDraw())
        }

        val invalidCases = contract.getJSONArray("invalidCases")
        for (index in 0 until invalidCases.length()) {
            val case = invalidCases.getJSONObject(index)
            assertTrue(case.getString("id"), runCatching { boardFrom(case) }.isFailure)
        }

        val scoring = contract.getJSONObject("scoring")
        assertEquals(scoring.getInt("WIN"), MatchScore.points(MatchResult.WIN))
        assertEquals(scoring.getInt("DRAW"), MatchScore.points(MatchResult.DRAW))
        assertEquals(scoring.getInt("LOSS"), MatchScore.points(MatchResult.LOSS))
    }

    @Test
    fun `公共题目符合唯一解契约`() {
        val contract = contract("puzzles.v1.json")
        val validCases = contract.getJSONArray("validCases")
        for (index in 0 until validCases.length()) {
            val case = validCases.getJSONObject(index)
            val payload = case.getJSONObject("payload")
            val puzzle = DailyPuzzleParser.parse(payload)
            val expected = case.getJSONObject("expected")
            val answer = expected.getJSONObject("answer")
            assertEquals(case.getString("id"), answer.getInt("row"), puzzle.answer.row)
            assertEquals(case.getString("id"), answer.getInt("col"), puzzle.answer.col)
            assertEquals(
                case.getString("id"),
                expected.getString("winnerAfterMove").toMark(),
                puzzle.board.place(puzzle.answer, puzzle.player).winner()
            )
        }

        val invalidCases = contract.getJSONArray("invalidCases")
        for (index in 0 until invalidCases.length()) {
            val case = invalidCases.getJSONObject(index)
            assertTrue(
                case.getString("id"),
                runCatching { DailyPuzzleParser.parse(case.getJSONObject("payload")) }.isFailure
            )
        }
    }

    @Test
    fun `客户端消息字段符合 WebSocket 契约`() {
        val messages = messagesById(contract("websocket-protocol.v1.json"), "clientMessages")
        assertJsonEquals(messages.getValue("hello"), RoomProtocol.hello("guest-contract", "契约玩家"))
        assertJsonEquals(messages.getValue("create-classic-room"), RoomProtocol.createRoom(3))
        assertJsonEquals(messages.getValue("create-advanced-room"), RoomProtocol.createRoom(5))
        assertJsonEquals(messages.getValue("join-room"), RoomProtocol.joinRoom("ABC123"))
        assertJsonEquals(messages.getValue("request-room-state"), RoomProtocol.requestRoomState("ABC123"))
        assertJsonEquals(messages.getValue("move"), RoomProtocol.move(1, 2))
        assertJsonEquals(messages.getValue("surrender"), RoomProtocol.surrender())
    }

    @Test
    fun `服务端消息可以按契约解析`() {
        val contract = contract("websocket-protocol.v1.json")
        val messages = messagesById(contract, "serverMessages")

        assertEquals(RoomEvent.Connected("guest-server"), RoomProtocol.decode(messages.getValue("connected")))
        assertEquals(RoomEvent.HelloOk("guest-contract", "契约玩家"), RoomProtocol.decode(messages.getValue("hello-ok")))

        val created = RoomProtocol.decode(messages.getValue("room-created-waiting")) as RoomEvent.RoomCreated
        assertEquals("ABC123", created.room.code)
        assertTrue(created.room.isWaiting)
        assertEquals(Mark.X, created.room.yourMark)

        val playing = RoomProtocol.decode(messages.getValue("room-state-playing")) as RoomEvent.RoomState
        assertTrue(playing.room.isPlaying)
        assertEquals(Mark.X, playing.room.turn)
        assertEquals("乙方", playing.room.opponentName)

        val win = RoomProtocol.decode(messages.getValue("room-state-win")) as RoomEvent.RoomState
        assertEquals(MatchResult.WIN, win.room.toMatchResult())
        assertEquals(Mark.X, win.room.board.winner())

        val draw = RoomProtocol.decode(messages.getValue("room-state-draw")) as RoomEvent.RoomState
        assertEquals(MatchResult.DRAW, draw.room.toMatchResult())
        assertTrue(draw.room.board.isDraw())

        assertEquals(
            RoomEvent.Failure("NOT_YOUR_TURN", "还没有轮到你"),
            RoomProtocol.decode(messages.getValue("error"))
        )

        val invalidMessages = contract.getJSONArray("invalidServerMessages")
        for (index in 0 until invalidMessages.length()) {
            val case = invalidMessages.getJSONObject(index)
            val result = runCatching { RoomProtocol.decode(case.getString("wire")) }
            val rejected = result.isFailure ||
                (result.getOrNull() as? RoomEvent.Failure)?.code == "UNKNOWN_TYPE"
            assertTrue(case.getString("id"), rejected)
        }
    }

    private fun contract(name: String): JSONObject {
        val stream = checkNotNull(javaClass.classLoader?.getResourceAsStream(name)) { "找不到契约文件：$name" }
        return stream.bufferedReader().use { JSONObject(it.readText()) }
    }

    private fun boardFrom(case: JSONObject): Board {
        val size = case.getInt("size")
        val winLength = case.getInt("winLength")
        check((size == 3 && winLength == 3) || (size == 5 && winLength == 4)) { "不支持的棋盘模式" }
        val encoded = case.getString("board")
        check(encoded.length == size * size) { "棋盘长度无效" }
        return Board(
            size = size,
            winLength = winLength,
            cells = encoded.map { value ->
                when (value) {
                    'X' -> Mark.X
                    'O' -> Mark.O
                    '.' -> Mark.EMPTY
                    else -> error("棋盘包含非法棋子")
                }
            }
        )
    }

    private fun messagesById(contract: JSONObject, key: String): Map<String, String> {
        val messages = contract.getJSONArray(key)
        return buildMap {
            for (index in 0 until messages.length()) {
                val item = messages.getJSONObject(index)
                put(item.getString("id"), item.getString("wire"))
            }
        }
    }

    private fun assertJsonEquals(expected: String, actual: String) {
        assertEquals(normalize(JSONObject(expected)), normalize(JSONObject(actual)))
    }

    private fun normalize(value: Any?): Any? = when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> value.keys().asSequence().associateWith { normalize(value.get(it)) }
        is JSONArray -> (0 until value.length()).map { normalize(value.get(it)) }
        else -> value
    }

    private fun String.toMark(): Mark = when (this) {
        "X" -> Mark.X
        "O" -> Mark.O
        else -> Mark.EMPTY
    }
}
