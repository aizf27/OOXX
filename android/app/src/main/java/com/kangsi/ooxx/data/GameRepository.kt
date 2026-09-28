package com.kangsi.ooxx.data

import android.content.Context
import com.kangsi.ooxx.BuildConfig
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.GameEngine
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.game.Puzzle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.time.Instant
import java.util.concurrent.TimeUnit

enum class MatchResult { WIN, LOSS, DRAW }

data class MatchRecord(
    val result: MatchResult,
    val mode: String,
    val opponent: String,
    val playedAt: Long = System.currentTimeMillis(),
    val steps: Int
)

data class RankingEntry(val rank: Int, val name: String, val score: Int, val isMe: Boolean = false)

class LocalGameRepository(context: Context) {
    private val preferences = context.getSharedPreferences("ooxx_records", Context.MODE_PRIVATE)

    fun save(record: MatchRecord) {
        val encoded = listOf(
            record.result.name,
            record.mode.replace("|", ""),
            record.opponent.replace("|", ""),
            record.playedAt,
            record.steps
        ).joinToString("|")
        val records = (loadEncoded() + encoded).takeLast(50)
        preferences.edit().putString("records", records.joinToString("\n")).apply()
    }

    fun records(): List<MatchRecord> = loadEncoded().mapNotNull { line ->
        val item = line.split('|')
        if (item.size != 5) return@mapNotNull null
        runCatching {
            MatchRecord(MatchResult.valueOf(item[0]), item[1], item[2], item[3].toLong(), item[4].toInt())
        }.getOrNull()
    }.sortedByDescending { it.playedAt }

    fun ranking(): List<RankingEntry> {
        val score = records().fold(0) { total, record ->
            total + when (record.result) {
                MatchResult.WIN -> 30
                MatchResult.DRAW -> 10
                MatchResult.LOSS -> 2
            }
        }
        val players = listOf(
            RankingEntry(1, "棋妙高手", 1280),
            RankingEntry(2, "圈圈达人", 1160),
            RankingEntry(3, "叉叉队长", 1030),
            RankingEntry(4, "康思", 620 + score, true),
            RankingEntry(5, "小明", 590)
        ).sortedByDescending { it.score }
        return players.mapIndexed { index, item -> item.copy(rank = index + 1) }
    }

    private fun loadEncoded(): List<String> = preferences.getString("records", "")
        .orEmpty().lineSequence().filter { it.isNotBlank() }.toList()
}

class NetworkGameRepository(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(3, TimeUnit.SECONDS)
        .readTimeout(3, TimeUnit.SECONDS)
        .build()
) {
    /**
     * Expected payload:
     * {"size":3,"winLength":3,"board":"XO..X.O..","next":"X","answer":{"row":2,"col":2}}
     */
    suspend fun fetchDailyPuzzle(): Result<Puzzle> = withContext(Dispatchers.IO) {
        runCatching {
            val request = Request.Builder()
                .url(BuildConfig.GAME_API_BASE_URL + "games/daily")
                .header("Accept", "application/json")
                .build()
            client.newCall(request).execute().use { response ->
                check(response.isSuccessful) { "服务器返回 ${response.code}" }
                val json = JSONObject(response.body?.string().orEmpty())
                val size = json.optInt("size", 3)
                val encoded = json.getString("board")
                check(encoded.length == size * size)
                val board = Board(
                    size = size,
                    winLength = json.optInt("winLength", if (size == 3) 3 else 4),
                    cells = encoded.map {
                        when (it.uppercaseChar()) {
                            'X' -> Mark.X
                            'O' -> Mark.O
                            else -> Mark.EMPTY
                        }
                    }
                )
                val player = if (json.optString("next", "X") == "O") Mark.O else Mark.X
                val calculated = GameEngine.uniqueBestMove(board, player)
                    ?: error("题目不存在唯一最优解")
                val serverAnswer = json.optJSONObject("answer")?.let {
                    Move(it.getInt("row"), it.getInt("col"))
                }
                check(serverAnswer == null || serverAnswer == calculated) { "服务端答案校验失败" }
                Puzzle(board, player, calculated)
            }
        }
    }

    fun fallbackPuzzle(): Puzzle = GameEngine.generateUniquePuzzle()
}
