package com.kangsi.ooxx.match

import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import org.json.JSONArray
import org.json.JSONObject

/** 服务器下发的房间快照，字段与 server/src/game-rules.js 的 roomSnapshot() 一一对应。 */
data class RoomSnapshot(
    val code: String,
    val board: Board,
    val turn: Mark,
    val status: String,
    val winner: String?,
    val yourMark: Mark?,
    val opponentName: String?
) {
    val isPlaying: Boolean get() = status == "PLAYING"
    val isWaiting: Boolean get() = status == "WAITING"
    val isFinished: Boolean get() = status == "FINISHED"

    /** 结合自己的执子把服务器胜负映射成本地结算。观战（yourMark 为空）按平局外的失败处理不了，返回 null。 */
    fun toMatchResult(): MatchResult? {
        if (!isFinished || winner == null) return null
        if (winner == "DRAW") return MatchResult.DRAW
        val mine = yourMark ?: return null
        return if (winner == mine.wire()) MatchResult.WIN else MatchResult.LOSS
    }
}

sealed interface RoomEvent {    data class Connected(val playerId: String) : RoomEvent
    data class HelloOk(val playerId: String, val name: String) : RoomEvent
    data class RoomCreated(val room: RoomSnapshot) : RoomEvent
    data class RoomState(val room: RoomSnapshot) : RoomEvent
    data class Failure(val code: String, val message: String) : RoomEvent
}

/** 客户端发给服务端的消息。网络模式下由服务器解析，蓝牙模式下由主机端（RoomAuthority）解析。 */
sealed interface ClientEvent {
    data class Hello(val playerId: String, val name: String) : ClientEvent
    data class Move(val row: Int, val col: Int) : ClientEvent
    data object Surrender : ClientEvent
}

object RoomProtocol {
    fun hello(playerId: String, name: String): String = JSONObject(
        mapOf("type" to "hello", "playerId" to playerId, "name" to name)
    ).toString()

    fun createRoom(size: Int = 3, winLength: Int = if (size == 3) 3 else 4): String = JSONObject(
        mapOf("type" to "room.create", "size" to size, "winLength" to winLength)
    ).toString()

    fun joinRoom(code: String): String = JSONObject(
        mapOf("type" to "room.join", "code" to code)
    ).toString()

    fun requestRoomState(code: String): String = JSONObject(
        mapOf("type" to "room.state", "code" to code)
    ).toString()

    fun move(row: Int, col: Int): String = JSONObject(
        mapOf("type" to "move", "row" to row, "col" to col)
    ).toString()

    fun surrender(): String = JSONObject(mapOf("type" to "game.surrender")).toString()

    fun decode(text: String): RoomEvent {
        val json = JSONObject(text)
        return when (json.optString("type")) {
            "connected" -> RoomEvent.Connected(json.getString("playerId"))
            "hello.ok" -> RoomEvent.HelloOk(json.getString("playerId"), json.optString("name"))
            "room.created" -> RoomEvent.RoomCreated(snapshot(json.getJSONObject("room")))
            "room.state" -> RoomEvent.RoomState(snapshot(json.getJSONObject("room")))
            "error" -> RoomEvent.Failure(json.optString("code", "UNKNOWN"), json.optString("message", "未知错误"))
            else -> RoomEvent.Failure("UNKNOWN_TYPE", "未知的服务器消息")
        }
    }

    /** 解析对端（客户端）发来的消息，蓝牙主机端使用。 */
    fun decodeClient(text: String): ClientEvent? {
        val json = runCatching { JSONObject(text) }.getOrNull() ?: return null
        return when (json.optString("type")) {
            "hello" -> ClientEvent.Hello(json.optString("playerId"), json.optString("name").ifBlank { "好友" })
            "move" -> runCatching { ClientEvent.Move(json.getInt("row"), json.getInt("col")) }.getOrNull()
            "game.surrender" -> ClientEvent.Surrender
            else -> null
        }
    }

    private fun snapshot(json: JSONObject): RoomSnapshot {
        val size = json.getInt("size")
        val rows = json.getJSONArray("board")
        val cells = buildList {
            for (row in 0 until size) {
                val line = rows.getJSONArray(row)
                for (col in 0 until size) add(parseMark(line.getString(col)))
            }
        }
        return RoomSnapshot(
            code = json.getString("code"),
            board = Board(size = size, winLength = json.getInt("winLength"), cells = cells),
            turn = parseMark(json.getString("turn")),
            status = json.getString("status"),
            winner = json.optString("winner").takeIf { it.isNotEmpty() && it != "null" },
            yourMark = json.optString("yourMark").takeUnless { it.isNullOrEmpty() || it == "null" }?.let(::parseMark),
            opponentName = opponentName(json)
        )
    }

    private fun opponentName(json: JSONObject): String? {
        val mine = json.optString("yourMark")
        val players = json.getJSONArray("players")
        for (index in 0 until players.length()) {
            val player = players.getJSONObject(index)
            if (player.optString("mark") != mine) return player.optString("name")
        }
        return null
    }

    private fun parseMark(raw: String): Mark = when (raw) {
        "X" -> Mark.X
        "O" -> Mark.O
        else -> Mark.EMPTY
    }
}

private fun Mark.wire(): String = if (this == Mark.X) "X" else "O"
