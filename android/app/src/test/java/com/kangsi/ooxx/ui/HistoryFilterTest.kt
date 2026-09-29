package com.kangsi.ooxx.ui

import com.kangsi.ooxx.data.MatchRecord
import com.kangsi.ooxx.data.MatchResult
import org.junit.Assert.assertEquals
import org.junit.Test

class HistoryFilterTest {
    private val records = listOf(
        MatchRecord(MatchResult.WIN, "在线对战", "甲", playedAt = 3, steps = 5),
        MatchRecord(MatchResult.LOSS, "在线对战", "乙", playedAt = 2, steps = 6),
        MatchRecord(MatchResult.DRAW, "本地双人", "丙", playedAt = 1, steps = 9)
    )

    @Test
    fun allFilterReturnsEveryRecordInOriginalOrder() {
        assertEquals(records, filterMatchRecords(records, HistoryFilter.ALL))
    }

    @Test
    fun resultFiltersReturnOnlyMatchingRecords() {
        assertEquals(listOf(records[0]), filterMatchRecords(records, HistoryFilter.WIN))
        assertEquals(listOf(records[1]), filterMatchRecords(records, HistoryFilter.LOSS))
        assertEquals(listOf(records[2]), filterMatchRecords(records, HistoryFilter.DRAW))
    }
}
