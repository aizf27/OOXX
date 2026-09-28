package com.kangsi.ooxx.game

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class GameEngineTest {
    @Test fun detectsRowsColumnsAndDiagonals() {
        val row = Board(cells = listOf(
            Mark.X, Mark.X, Mark.X,
            Mark.O, Mark.O, Mark.EMPTY,
            Mark.EMPTY, Mark.EMPTY, Mark.EMPTY
        ))
        assertEquals(Mark.X, row.winner())

        val diagonal = Board(cells = listOf(
            Mark.O, Mark.X, Mark.X,
            Mark.EMPTY, Mark.O, Mark.EMPTY,
            Mark.X, Mark.EMPTY, Mark.O
        ))
        assertEquals(Mark.O, diagonal.winner())
    }

    @Test fun minimaxNeverMissesImmediateWin() {
        val board = Board(cells = listOf(
            Mark.X, Mark.X, Mark.EMPTY,
            Mark.O, Mark.O, Mark.EMPTY,
            Mark.EMPTY, Mark.EMPTY, Mark.EMPTY
        ))
        assertEquals(Move(0, 2), GameEngine.bestMove(board, Mark.X))
    }

    @Test fun uniqueSolutionIsRejectedWhenBestMovesTie() {
        assertNull(GameEngine.uniqueBestMove(Board(), Mark.X))
    }

    @Test fun generatedPuzzleAlwaysHasDeclaredUniqueSolution() {
        repeat(25) {
            val puzzle = GameEngine.generateUniquePuzzle(kotlin.random.Random(it))
            assertEquals(puzzle.answer, GameEngine.uniqueBestMove(puzzle.board, puzzle.player))
        }
    }

    @Test fun classicLogicPuzzleHasExactlyOneSolution() {
        assertEquals(1, LogicPuzzleEngine.countSolutions(LogicPuzzleEngine.classic6x6()))
    }

    @Test fun logicRulesDetectTriplesBalanceAndDuplicateLines() {
        val triple = LogicPuzzleEngine.parse(listOf("XXXO..", "......", "......", "......", "......", "......"))
        assertEquals(setOf(0, 1, 2), LogicPuzzleEngine.invalidCells(triple))

        val duplicateRows = LogicPuzzleEngine.parse(listOf("XXOXOO", "XXOXOO", "......", "......", "......", "......"))
        val invalid = LogicPuzzleEngine.invalidCells(duplicateRows)
        assertEquals(true, (0 until 12).all { it in invalid })
    }
}
