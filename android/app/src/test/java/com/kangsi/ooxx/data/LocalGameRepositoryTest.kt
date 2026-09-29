package com.kangsi.ooxx.data

import android.app.Application
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class LocalGameRepositoryTest {
    private lateinit var application: Application
    private lateinit var repository: LocalGameRepository

    @Before
    fun setUp() {
        application = ApplicationProvider.getApplicationContext()
        application.getSharedPreferences("ooxx_records", Context.MODE_PRIVATE).edit().clear().commit()
        repository = LocalGameRepository(application)
    }

    @Test
    fun `保存后按时间倒序读取并清理分隔符`() {
        repository.save(MatchRecord(MatchResult.LOSS, "本地|双人", "小|明", playedAt = 10, steps = 7))
        repository.save(MatchRecord(MatchResult.WIN, "经典 3×3", "AI", playedAt = 20, steps = 5))

        val records = repository.records()

        assertEquals(listOf(20L, 10L), records.map { it.playedAt })
        assertEquals("本地双人", records[1].mode)
        assertEquals("小明", records[1].opponent)
    }

    @Test
    fun `损坏记录被忽略且最多保留五十条`() {
        application.getSharedPreferences("ooxx_records", Context.MODE_PRIVATE)
            .edit().putString("records", "损坏数据\nWIN|经典|AI|不是时间|3").commit()
        repository = LocalGameRepository(application)

        repeat(55) { index ->
            repository.save(MatchRecord(MatchResult.DRAW, "模式", "对手", playedAt = index.toLong(), steps = index))
        }

        val records = repository.records()
        assertEquals(50, records.size)
        assertEquals(54L, records.first().playedAt)
        assertEquals(5L, records.last().playedAt)
    }

    @Test
    fun `排行榜累计本机积分并重新计算名次`() {
        repository.save(MatchRecord(MatchResult.WIN, "模式", "甲", steps = 1))
        repository.save(MatchRecord(MatchResult.DRAW, "模式", "乙", steps = 1))
        repository.save(MatchRecord(MatchResult.LOSS, "模式", "丙", steps = 1))

        val ranking = repository.ranking()
        val me = ranking.single { it.isMe }

        assertEquals(662, me.score)
        assertEquals(ranking.indexOf(me) + 1, me.rank)
        assertTrue(ranking.zipWithNext().all { (first, second) -> first.score >= second.score })
        assertFalse(ranking.first().isMe)
    }
}
