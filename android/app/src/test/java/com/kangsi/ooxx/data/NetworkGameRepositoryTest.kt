package com.kangsi.ooxx.data

import com.kangsi.ooxx.game.Mark
import com.kangsi.ooxx.game.Move
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.SocketPolicy
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NetworkGameRepositoryTest {
    private lateinit var server: MockWebServer

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun `合法响应解析并校验唯一最优解`() = runTest {
        server.enqueue(MockResponse().setBody(VALID_PUZZLE).setHeader("Content-Type", "application/json"))
        val repository = repository()

        val result = repository.fetchDailyPuzzle()

        assertTrue(result.isSuccess)
        assertEquals(Mark.X, result.getOrThrow().player)
        assertEquals(Move(2, 2), result.getOrThrow().answer)
        assertEquals("/games/daily", server.takeRequest().path)
    }

    @Test
    fun `服务端错误转为失败结果而不是抛出异常`() = runTest {
        server.enqueue(MockResponse().setResponseCode(503).setBody("维护中"))

        val result = repository().fetchDailyPuzzle()

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull()?.message.orEmpty().contains("503"))
    }

    @Test
    fun `非法棋盘与错误答案均被拒绝`() = runTest {
        server.enqueue(MockResponse().setBody("""{"size":3,"board":"XO","next":"X"}"""))
        server.enqueue(MockResponse().setBody(VALID_PUZZLE.replace("\"row\":2,\"col\":2", "\"row\":0,\"col\":2")))
        val repository = repository()

        val invalidBoard = repository.fetchDailyPuzzle()
        val invalidAnswer = repository.fetchDailyPuzzle()

        assertTrue(invalidBoard.isFailure)
        assertTrue(invalidBoard.exceptionOrNull()?.message.orEmpty().contains("长度"))
        assertTrue(invalidAnswer.isFailure)
        assertTrue(invalidAnswer.exceptionOrNull()?.message.orEmpty().contains("答案校验失败"))
    }

    @Test
    fun `连接中断转为失败结果`() = runTest {
        server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.DISCONNECT_AT_START))

        val result = repository().fetchDailyPuzzle()

        assertTrue(result.isFailure)
    }

    private fun repository(): NetworkGameRepository = NetworkGameRepository(
        client = OkHttpClient.Builder()
            .connectTimeout(1, TimeUnit.SECONDS)
            .readTimeout(1, TimeUnit.SECONDS)
            .build(),
        baseUrl = server.url("/").toString()
    )

    private companion object {
        const val VALID_PUZZLE = """{"size":3,"winLength":3,"board":"XO..X.O..","next":"X","answer":{"row":2,"col":2}}"""
    }
}
