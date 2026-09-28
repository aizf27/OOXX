import test from "node:test";
import assert from "node:assert/strict";
import { winner } from "../src/game-rules.js";
import { dailyPuzzle } from "../src/puzzles.js";

test("daily puzzle uses the shared flat board contract", () => {
  assert.equal(typeof dailyPuzzle.board, "string");
  assert.equal(dailyPuzzle.board.length, dailyPuzzle.size * dailyPuzzle.size);
  assert.match(dailyPuzzle.board, /^[XO.]+$/);

  const answerIndex = dailyPuzzle.answer.row * dailyPuzzle.size + dailyPuzzle.answer.col;
  assert.equal(dailyPuzzle.board[answerIndex], ".");
});

test("daily puzzle answer completes the declared winning line", () => {
  const board = Array.from({ length: dailyPuzzle.size }, (_, row) =>
    Array.from({ length: dailyPuzzle.size }, (_, col) => {
      const value = dailyPuzzle.board[row * dailyPuzzle.size + col];
      return value === "." ? "" : value;
    })
  );

  board[dailyPuzzle.answer.row][dailyPuzzle.answer.col] = dailyPuzzle.next;
  assert.equal(winner(board, dailyPuzzle.winLength), dailyPuzzle.next);
});
