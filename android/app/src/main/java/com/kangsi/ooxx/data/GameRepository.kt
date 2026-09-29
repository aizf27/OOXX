package com.kangsi.ooxx.data

import android.content.Context
import android.util.Log
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
import java.util.concurrent.TimeUnit

enum class MatchResult { WIN, LOSS, DRAW }

object MatchScore {
    fun points(result: MatchResult): Int = when (result) {
        MatchResult.WIN -> 30
        MatchResult.DRAW -> 10
        MatchResult.LOSS -> 2
    }
}

data class MatchRecord(
    val result: MatchResult,
    val mode: String,
    val opponent: String,
    val playedAt: Long = System.currentTimeMillis(),
    val steps: Int
)

data class RankingEntry(val rank: Int, val name: String, val score: Int, val isMe: Boolean = false)

interface GameRecordRepository {
    fun save(record: MatchRecord)
    fun records(): List<MatchRecord>
    fun ranking(): List<RankingEntry>
}

class LocalGameRepository(context: Context) : GameRecordRepository {
    private val preferences = context.getSharedPreferences("ooxx_records", Context.MODE_PRIVATE)

    override fun save(record: MatchRecord) {
        val encoded = listOf(
            record.result.name,
            record.mode.replace("|", ""),
            record.opponent.replace("|", ""),
            record.playedAt,
            record.steps
        ).joinToString("|")
        val records = (loadEncoded() + encoded).takeLast(MAX_RECORDS)
        preferences.edit().putString(RECORDS_KEY, records.joinToString("\n")).apply()
    }

    override fun records(): List<MatchRecord> = loadEncoded().mapNotNull { line ->
        val item = line.split('|')
        if (item.size != 5) return@mapNotNull null
        runCatching {
            MatchRecord(MatchResult.valueOf(item[0]), item[1], item[2], item[3].toLong(), item[4].toInt())
        }.getOrNull()
    }.sortedByDescending { it.playedAt }

    override fun ranking(): List<RankingEntry> {
        val score = records().sumOf { MatchScore.points(it.result) }
        val players = listOf(
            RankingEntry(1, "棋妙高手", 1280),
            RankingEntry(2, "圈圈达人", 1160),
            RankingEntry(3, "叉叉队长", 1030),
            RankingEntry(4, "康思", 620 + score, true),
            RankingEntry(5, "小明", 590)
        ).sortedByDescending { it.score }
        return players.mapIndexed { index, item -> item.copy(rank = index + 1) }
    }

    private fun loadEncoded(): List<String> = preferences.getString(RECORDS_KEY, "")
        .orEmpty().lineSequence().filter { it.isNotBlank() }.toList()

    private companion object {
        const val RECORDS_KEY = "records"
        const val MAX_RECORDS = 50
    }
}

interface DailyPuzzleRepository {
    suspend fun fetchDailyPuzzle(): Result<Puzzle>
    fun fallbackPuzzle(): Puzzle
}

internal object DailyPuzzleParser {
    fun parse(json: JSONObject): Puzzle {
        val size = json.getInt("size")
        val encoded = json.getString("board")
        check(encoded.length == size * size) { "棋盘数据长度错误" }

        val winLength = json.getInt("winLength")
        check((size == 3 && winLength == 3) || (size == 5 && winLength == 4)) {
            "棋盘模式非法"
        }
        val cells = encoded.map { value ->
            when (value.uppercaseChar()) {
                'X' -> Mark.X
                'O' -> Mark.O
                '.' -> Mark.EMPTY
                else -> error("棋盘包含非法棋子")
            }
        }
        val player = when (json.getString("next")) {
            "X" -> Mark.X
            "O" -> Mark.O
            else -> error("下一手玩家非法")
        }
        val answerJson = json.getJSONObject("answer")
        val answer = Move(answerJson.getInt("row"), answerJson.getInt("col"))
        check(answer.row in 0 until size && answer.col in 0 until size) { "题目答案越界" }

        val board = Board(size = size, winLength = winLength, cells = cells)
        check(board.cells[answer.row * size + answer.col] == Mark.EMPTY) { "题目答案位置无效" }
        val calculated = GameEngine.uniqueBestMove(board, player)
            ?: error("题目不存在唯一最优解")
        check(answer == calculated) { "服务端答案校验失败" }
        return Puzzle(board, player, answer)
    }
}

class NetworkGameRepository(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(3, TimeUnit.SECONDS)
        .readTimeout(3, TimeUnit.SECONDS)
        .build(),
    private val baseUrl: String = BuildConfig.GAME_API_BASE_URL
) : DailyPuzzleRepository {
    /**
     * Expected payload:
     * {"size":3,"winLength":3,"board":"XO..X.O..","next":"X","answer":{"row":2,"col":2}}
     */
    override suspend fun fetchDailyPuzzle(): Result<Puzzle> = withContext(Dispatchers.IO) {
        val requestUrl = baseUrl.trimEnd('/') + "/games/daily"
        Log.i(TAG, "请求每日挑战: $requestUrl")
        runCatching {
            val request = Request.Builder()
                .url(requestUrl)
                .header("Accept", "application/json")
                .build()
            client.newCall(request).execute().use { response ->
                check(response.isSuccessful) { "服务器返回 ${response.code}" }
                DailyPuzzleParser.parse(JSONObject(response.body?.string().orEmpty()))
            }
        }.onSuccess {
            Log.i(TAG, "每日挑战获取成功")
        }.onFailure {
            Log.e(TAG, "每日挑战获取失败", it)
        }
    }

    override fun fallbackPuzzle(): Puzzle = GameEngine.generateUniquePuzzle()

    private companion object {
        const val TAG = "NetworkGameRepository"
    }
}
