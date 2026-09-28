package com.kangsi.ooxx.game

/** A Binary/Tic-Tac-Logic board. Givens are immutable clues supplied by the puzzle. */
data class LogicBoard(
    val size: Int = 6,
    val cells: List<Mark>,
    val givens: Set<Int>
) {
    init {
        require(size >= 4 && size % 2 == 0)
        require(cells.size == size * size)
        require(givens.all { it in cells.indices && cells[it] != Mark.EMPTY })
    }

    operator fun get(row: Int, col: Int): Mark = cells[row * size + col]

    fun cycle(move: Move): LogicBoard {
        val index = move.row * size + move.col
        if (index in givens) return this
        val next = cells.toMutableList()
        next[index] = when (next[index]) {
            Mark.EMPTY -> Mark.X
            Mark.X -> Mark.O
            Mark.O -> Mark.EMPTY
        }
        return copy(cells = next)
    }
}

object LogicPuzzleEngine {
    private const val EMPTY = '.'

    /** A compact, deterministic 6x6 puzzle with exactly one solution. */
    fun classic6x6(): LogicBoard = parse(
        listOf(
            "......",
            "...O..",
            ".O....",
            ".O....",
            "..OO.X",
            "....XX"
        )
    )

    fun parse(rows: List<String>): LogicBoard {
        require(rows.isNotEmpty() && rows.size % 2 == 0 && rows.all { it.length == rows.size })
        val cells = rows.flatMap { row ->
            row.map {
                when (it) {
                    'X' -> Mark.X
                    'O' -> Mark.O
                    EMPTY -> Mark.EMPTY
                    else -> error("Unsupported puzzle cell: $it")
                }
            }
        }
        return LogicBoard(rows.size, cells, cells.indices.filterTo(mutableSetOf()) { cells[it] != Mark.EMPTY })
    }

    fun invalidCells(board: LogicBoard): Set<Int> {
        val invalid = mutableSetOf<Int>()
        val half = board.size / 2

        fun checkLine(indices: List<Int>) {
            val marks = indices.map(board.cells::get)
            if (marks.count { it == Mark.X } > half || marks.count { it == Mark.O } > half) {
                invalid += indices.filter { board.cells[it] != Mark.EMPTY }
            }
            for (start in 0..board.size - 3) {
                val triple = indices.subList(start, start + 3)
                val mark = board.cells[triple.first()]
                if (mark != Mark.EMPTY && triple.all { board.cells[it] == mark }) invalid += triple
            }
        }

        val rows = (0 until board.size).map { row -> (0 until board.size).map { col -> row * board.size + col } }
        val columns = (0 until board.size).map { col -> (0 until board.size).map { row -> row * board.size + col } }
        (rows + columns).forEach(::checkLine)

        fun markDuplicates(lines: List<List<Int>>) {
            lines.filter { line -> line.all { board.cells[it] != Mark.EMPTY } }
                .groupBy { line -> line.map(board.cells::get) }
                .values.filter { it.size > 1 }
                .flatten().forEach { invalid += it }
        }
        markDuplicates(rows)
        markDuplicates(columns)
        return invalid
    }

    fun isSolved(board: LogicBoard): Boolean =
        Mark.EMPTY !in board.cells && invalidCells(board).isEmpty()

    fun status(board: LogicBoard): String {
        val invalid = invalidCells(board)
        return when {
            invalid.isNotEmpty() -> "红色格违反规则，再检查一下"
            Mark.EMPTY !in board.cells -> "还有行或列未满足规则"
            else -> "点击空格切换 X / O，已填 ${board.cells.count { it != Mark.EMPTY }}/${board.cells.size}"
        }
    }

    /** Used by tests and puzzle authoring to ensure a clue set has one and only one solution. */
    fun countSolutions(board: LogicBoard, limit: Int = 2): Int {
        val cells = board.cells.toMutableList()
        var count = 0

        fun search() {
            if (count >= limit) return
            val empty = cells.indexOf(Mark.EMPTY)
            if (empty == -1) {
                val complete = board.copy(cells = cells.toList())
                if (isSolved(complete)) count++
                return
            }
            for (mark in listOf(Mark.X, Mark.O)) {
                cells[empty] = mark
                val partial = board.copy(cells = cells.toList())
                if (invalidCells(partial).isEmpty()) search()
                cells[empty] = Mark.EMPTY
            }
        }

        search()
        return count
    }
}
