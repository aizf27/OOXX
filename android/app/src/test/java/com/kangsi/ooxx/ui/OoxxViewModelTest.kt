package com.kangsi.ooxx.ui

import android.app.Application
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.kangsi.ooxx.data.DailyPuzzleRepository
import com.kangsi.ooxx.data.GameRecordRepository
import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.MatchResult
import com.kangsi.ooxx.data.RankingEntry
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.game.Puzzle
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class OoxxViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var application: Application
    private lateinit var records: FakeGameRecordRepository

    @Before
    fun setUp() {
        application = ApplicationProvider.getApplicationContext()
        application.getSharedPreferences("ooxx_settings", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .putBoolean("sound", false)
            .putBoolean("vibration", false)
            .commit()
        records = FakeGameRecordRepository()
    }

    @Test
    fun `启动延时结束后进入引导页`() = runTest {
        val viewModel = viewModel(startupDelayMillis = 900L)

        assertEquals(Screen.SPLASH, viewModel.state.value.screen)
        mainDispatcherRule.dispatcher.scheduler.advanceTimeBy(900L)
        mainDispatcherRule.dispatcher.scheduler.runCurrent()

        assertEquals(Screen.ONBOARDING, viewModel.state.value.screen)
    }

    @Test
    fun `本地对局支持落子悔棋与认输结算`() {
        val viewModel = viewModel()

        viewModel.startGame(GameKind.LOCAL)
        viewModel.play(Move(0, 0))
        assertEquals(Mark.X, viewModel.state.value.game.board[0, 0])
        assertEquals(Mark.O, viewModel.state.value.game.turn)

        viewModel.undo()
        assertEquals(Mark.EMPTY, viewModel.state.value.game.board[0, 0])
        assertEquals(0, viewModel.state.value.game.moves)

        viewModel.surrender()
        assertEquals(Screen.RESULT, viewModel.state.value.screen)
        assertEquals(MatchResult.LOSS, viewModel.state.value.result)
        assertEquals(1, records.saved.size)
        assertEquals("双人同屏", records.saved.single().mode)
    }

    @Test
    fun `每日挑战网络失败时加载本地题目并清除加载态`() {
        val fallback = puzzle()
        val viewModel = viewModel(
            network = FakeDailyPuzzleRepository(Result.failure(IllegalStateException("离线")), fallback)
        )

        viewModel.startGame(GameKind.DAILY)

        val state = viewModel.state.value
        assertEquals(Screen.GAME, state.screen)
        assertEquals(GameKind.DAILY, state.game.kind)
        assertEquals(fallback.answer, state.game.puzzleAnswer)
        assertFalse(state.isLoadingPuzzle)
        assertTrue(state.networkMessage.contains("本地唯一解"))
    }

    @Test
    fun `对战服务器连接失败时写入可恢复错误状态`() {
        val viewModel = OoxxViewModel(
            application = application,
            local = records,
            network = FakeDailyPuzzleRepository(Result.success(puzzle()), puzzle()),
            matchConnector = { error("网络不可达") },
            startupDelayMillis = 60_000L
        )

        viewModel.createRoom()

        assertFalse(viewModel.state.value.network.connecting)
        assertEquals("无法连接对战服务器，请稍后再试", viewModel.state.value.network.error)
    }

    private fun viewModel(
        network: DailyPuzzleRepository = FakeDailyPuzzleRepository(Result.success(puzzle()), puzzle()),
        startupDelayMillis: Long = 60_000L
    ): OoxxViewModel = OoxxViewModel(
        application = application,
        local = records,
        network = network,
        matchConnector = { error("测试不应连接真实服务器") },
        startupDelayMillis = startupDelayMillis
    )

    private fun puzzle(): Puzzle = Puzzle(
        board = Board(cells = listOf(
            Mark.X, Mark.O, Mark.EMPTY,
            Mark.EMPTY, Mark.X, Mark.EMPTY,
            Mark.O, Mark.EMPTY, Mark.EMPTY
        )),
        player = Mark.X,
        answer = Move(2, 2)
    )
}

private class FakeGameRecordRepository : GameRecordRepository {
    val saved = mutableListOf<MatchRecord>()

    override fun save(record: MatchRecord) {
        saved += record
    }

    override fun records(): List<MatchRecord> = saved.sortedByDescending { it.playedAt }

    override fun ranking(): List<RankingEntry> = listOf(RankingEntry(1, "康思", 620, true))
}

private class FakeDailyPuzzleRepository(
    private val remote: Result<Puzzle>,
    private val fallback: Puzzle
) : DailyPuzzleRepository {
    override suspend fun fetchDailyPuzzle(): Result<Puzzle> = remote
    override fun fallbackPuzzle(): Puzzle = fallback
}
