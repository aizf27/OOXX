package com.kangsi.ooxx.ui

import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.kangsi.ooxx.data.DailyPuzzleRepository
import com.kangsi.ooxx.data.GameRecordRepository
import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.RankingEntry
import com.kangsi.ooxx.game.Board
import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import com.kangsi.ooxx.game.Puzzle
import com.kangsi.ooxx.ui.theme.OoxxTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class OoxxAppTest {
    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun 首页进入双人对局并完成一次落子() {
        val viewModel = createViewModel()
        viewModel.navigate(Screen.HOME)
        setContent(viewModel)

        composeRule.onNodeWithTag("home_screen").assertIsDisplayed()
        composeRule.onNodeWithText("双人同屏").performClick()
        composeRule.onNodeWithTag("game_screen").assertIsDisplayed()
        composeRule.onNodeWithText("双人同屏 · 轮流落子").assertIsDisplayed()

        composeRule.onNodeWithTag("board_0_0").performClick()
        composeRule.onNodeWithText("X").assertIsDisplayed()
        composeRule.onNodeWithText("轮到你了 · O").assertIsDisplayed()
    }

    @Test
    fun 战绩空页面可通过底栏进入我的页面() {
        val viewModel = createViewModel()
        viewModel.navigate(Screen.HISTORY)
        setContent(viewModel)

        composeRule.onNodeWithTag("history_screen").assertIsDisplayed()
        composeRule.onNodeWithText("还没有记录，先去完成一局吧").assertIsDisplayed()
        composeRule.onNodeWithText("我的").performClick()
        composeRule.onNodeWithTag("profile_screen").assertIsDisplayed()
        composeRule.onNodeWithText("关于我们").assertIsDisplayed()
    }

    private fun setContent(viewModel: OoxxViewModel) {
        composeRule.setContent {
            OoxxTheme {
                OoxxApp(viewModel)
            }
        }
    }

    private fun createViewModel(): OoxxViewModel {
        val puzzle = Puzzle(
            board = Board(cells = listOf(
                Mark.X, Mark.O, Mark.EMPTY,
                Mark.EMPTY, Mark.X, Mark.EMPTY,
                Mark.O, Mark.EMPTY, Mark.EMPTY
            )),
            player = Mark.X,
            answer = Move(2, 2)
        )
        return OoxxViewModel(
            application = composeRule.activity.application,
            local = EmptyGameRecordRepository,
            network = FixedDailyPuzzleRepository(puzzle),
            matchConnector = { error("UI 测试不连接网络") },
            startupDelayMillis = 60_000L
        )
    }
}

private object EmptyGameRecordRepository : GameRecordRepository {
    override fun save(record: MatchRecord) = Unit
    override fun records(): List<MatchRecord> = emptyList()
    override fun ranking(): List<RankingEntry> = emptyList()
}

private class FixedDailyPuzzleRepository(private val puzzle: Puzzle) : DailyPuzzleRepository {
    override suspend fun fetchDailyPuzzle(): Result<Puzzle> = Result.success(puzzle)
    override fun fallbackPuzzle(): Puzzle = puzzle
}
