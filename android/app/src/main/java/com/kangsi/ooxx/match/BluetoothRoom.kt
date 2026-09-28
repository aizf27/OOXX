package com.kangsi.ooxx.match

import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import org.json.JSONArray
import org.json.JSONObject

/**
 * 蓝牙对战没有服务器，由主机（等待连接的那一方）承担服务端角色：
 * 校验回合与坐标、判定胜负，并下发与 server/src/game-rules.js roomSnapshot() 同构的 room.state，
 * 因此客户端的 RoomProtocol.decode / applyRoomSnapshot 可以原样复用。
 */
class RoomAuthority(private val size: Int = 3, private val hostName: String = "康思") {
    val hostId = "host"
    val code = "BLUETOOTH"

    private val winLength = if (size == 3) 3 else 4
    private var board = Board(size = size, winLength = winLength)
    private var turn: Mark = Mark.X
    private var status = "WAITING"
    private var winner: String? = null
    private var guest: Player? = null

    val guestId: String? get() = guest?.id
    val isPlaying: Boolean get() = status == "PLAYING"

    fun joinGuest(id: String, name: String) {
        if (guest != null) return
        guest = Player(id, name, Mark.O)
        status = "PLAYING"
    }

    /** 非法落子（非本人回合、越界、已占用、对局已结束）一律忽略。 */
    fun move(playerId: String, row: Int, col: Int): Boolean {
        val mark = when {
            playerId == hostId -> Mark.X
            playerId == guest?.id -> Mark.O
            else -> return false
        }
        if (status != "PLAYING" || mark != turn) return false
        if (row !in 0 until size || col !in 0 until size) return false
        if (board[row, col] != Mark.EMPTY) return false
        board = board.place(Move(row, col), mark)
        val won = board.winner()
        when {
            won != null -> { status = "FINISHED"; winner = wire(won) }
            board.isDraw() -> { status = "FINISHED"; winner = "DRAW" }
            else -> turn = turn.other()
        }
        return true
    }

    fun surrender(playerId: String) {
        val mark = when {
            playerId == hostId -> Mark.X
            playerId == guest?.id -> Mark.O
            else -> return
        }
        if (status != "PLAYING") return
        status = "FINISHED"
        winner = wire(mark.other())
    }

    /** 生成给指定一方的 room.state 消息（yourMark 与对手名按接收方视角填充）。 */
    fun snapshotFor(playerId: String): String {
        val me = if (playerId == hostId) Mark.X else Mark.O
        val players = JSONArray().apply {
            put(JSONObject().put("id", hostId).put("name", hostName).put("mark", "X"))
            guest?.let { put(JSONObject().put("id", it.id).put("name", it.name).put("mark", "O")) }
        }
        val rows = JSONArray().apply {
            for (row in 0 until size) {
                put(JSONArray().apply {
                    for (col in 0 until size) put(wire(board[row, col]))
                })
            }
        }
        val room = JSONObject()
            .put("code", code)
            .put("size", size)
            .put("winLength", winLength)
            .put("board", rows)
            .put("turn", wire(turn))
            .put("status", status)
            .put("winner", winner ?: JSONObject.NULL)
            .put("yourMark", wire(me))
            .put("players", players)
            .put("spectators", JSONArray())
        return JSONObject().put("type", "room.state").put("room", room).toString()
    }

    private fun wire(mark: Mark): String = when (mark) {
        Mark.X -> "X"
        Mark.O -> "O"
        Mark.EMPTY -> ""
    }

    private data class Player(val id: String, val name: String, val mark: Mark)
}
