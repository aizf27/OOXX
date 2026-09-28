package com.kangsi.ooxx.game

import kotlin.math.max
import kotlin.math.min
import kotlin.random.Random

enum class Mark { EMPTY, X, O;
    fun other(): Mark = if (this == X) O else X
}

data class Move(val row: Int, val col: Int)

data class Board(
    val size: Int = 3,
    val winLength: Int = if (size == 3) 3 else 4,
    val cells: List<Mark> = List(size * size) { Mark.EMPTY }
) {
    init {
        require(size >= 3 && winLength in 3..size)
        require(cells.size == size * size)
    }

    operator fun get(row: Int, col: Int): Mark = cells[row * size + col]

    fun place(move: Move, mark: Mark): Board {
        require(mark != Mark.EMPTY && move in availableMoves())
        val next = cells.toMutableList()
        next[move.row * size + move.col] = mark
        return copy(cells = next)
    }

    fun availableMoves(): List<Move> = buildList {
        cells.forEachIndexed { index, mark ->
            if (mark == Mark.EMPTY) add(Move(index / this@Board.size, index % this@Board.size))
        }
    }

    fun winner(): Mark? {
        val directions = listOf(0 to 1, 1 to 0, 1 to 1, 1 to -1)
        for (row in 0 until size) for (col in 0 until size) {
            val mark = this[row, col]
            if (mark == Mark.EMPTY) continue
            for ((dr, dc) in directions) {
                val endRow = row + (winLength - 1) * dr
                val endCol = col + (winLength - 1) * dc
                if (endRow !in 0 until size || endCol !in 0 until size) continue
                if ((0 until winLength).all { this[row + it * dr, col + it * dc] == mark }) {
                    return mark
                }
            }
        }
        return null
    }

    fun isDraw(): Boolean = winner() == null && Mark.EMPTY !in cells
}

data class RatedMove(val move: Move, val score: Int)

object GameEngine {
    /** Returns the strongest move. 3x3 is solved exactly with alpha-beta minimax. */
    fun bestMove(board: Board, player: Mark): Move? {
        if (board.winner() != null || board.availableMoves().isEmpty()) return null
        return rateMoves(board, player).maxWithOrNull(
            compareBy<RatedMove> { it.score }
                .thenByDescending { positionalPriority(board, it.move) }
        )?.move
    }

    fun rateMoves(board: Board, player: Mark): List<RatedMove> {
        val exact = board.size == 3
        return board.availableMoves().map { move ->
            val next = board.place(move, player)
            val score = if (exact) {
                minimax(next, player.other(), player, -10_000, 10_000, 1)
            } else {
                heuristicScore(next, player) - heuristicScore(next, player.other())
            }
            RatedMove(move, score)
        }
    }

    /** A puzzle is deterministic only when exactly one move has the highest score. */
    fun uniqueBestMove(board: Board, player: Mark): Move? {
        val rated = rateMoves(board, player)
        val best = rated.maxOfOrNull { it.score } ?: return null
        return rated.singleOrNull { it.score == best }?.move
    }

    fun generateUniquePuzzle(random: Random = Random.Default): Puzzle {
        repeat(1_000) {
            var board = Board()
            var turn = Mark.X
            val plies = random.nextInt(3, 7)
            repeat(plies) {
                if (board.winner() == null && board.availableMoves().isNotEmpty()) {
                    board = board.place(board.availableMoves().random(random), turn)
                    turn = turn.other()
                }
            }
            if (board.winner() == null) {
                val answer = uniqueBestMove(board, turn)
                if (answer != null && rateMoves(board, turn).first { it.move == answer }.score > 0) {
                    return Puzzle(board, turn, answer)
                }
            }
        }
        val fallback = Board(cells = listOf(
            Mark.X, Mark.O, Mark.EMPTY,
            Mark.O, Mark.X, Mark.EMPTY,
            Mark.EMPTY, Mark.EMPTY, Mark.O
        ))
        return Puzzle(fallback, Mark.X, Move(2, 2))
    }

    private fun minimax(
        board: Board,
        turn: Mark,
        maximizer: Mark,
        alphaStart: Int,
        betaStart: Int,
        depth: Int
    ): Int {
        board.winner()?.let { return if (it == maximizer) 100 - depth else depth - 100 }
        if (board.isDraw()) return 0
        var alpha = alphaStart
        var beta = betaStart
        if (turn == maximizer) {
            var value = -10_000
            for (move in board.availableMoves()) {
                value = max(value, minimax(board.place(move, turn), turn.other(), maximizer, alpha, beta, depth + 1))
                alpha = max(alpha, value)
                if (alpha >= beta) break
            }
            return value
        }
        var value = 10_000
        for (move in board.availableMoves()) {
            value = min(value, minimax(board.place(move, turn), turn.other(), maximizer, alpha, beta, depth + 1))
            beta = min(beta, value)
            if (alpha >= beta) break
        }
        return value
    }

    private fun heuristicScore(board: Board, player: Mark): Int {
        board.winner()?.let { return if (it == player) 100_000 else -100_000 }
        var score = 0
        val directions = listOf(0 to 1, 1 to 0, 1 to 1, 1 to -1)
        for (row in 0 until board.size) for (col in 0 until board.size) for ((dr, dc) in directions) {
            val endRow = row + (board.winLength - 1) * dr
            val endCol = col + (board.winLength - 1) * dc
            if (endRow !in 0 until board.size || endCol !in 0 until board.size) continue
            var own = 0
            var enemy = 0
            repeat(board.winLength) {
                when (board[row + it * dr, col + it * dc]) {
                    player -> own++
                    player.other() -> enemy++
                    else -> Unit
                }
            }
            if (enemy == 0) score += own * own * 12 + if (own == board.winLength - 1) 600 else 0
            if (own == 0) score -= enemy * enemy * 10
        }
        return score
    }

    private fun positionalPriority(board: Board, move: Move): Int {
        val center = board.size / 2
        return board.size - (kotlin.math.abs(move.row - center) + kotlin.math.abs(move.col - center))
    }
}

data class Puzzle(val board: Board, val player: Mark, val answer: Move)
