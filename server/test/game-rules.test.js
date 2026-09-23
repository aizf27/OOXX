import test from "node:test";
import assert from "node:assert/strict";
import { createBoard, isDraw, winner } from "../src/game-rules.js";

test("detects a winning diagonal", () => {
  const board = createBoard();
  board[0][0] = "X"; board[1][1] = "X"; board[2][2] = "X";
  assert.equal(winner(board), "X");
});

test("recognises draw board", () => {
  const board = [["X", "O", "X"], ["X", "O", "O"], ["O", "X", "X"]];
  assert.equal(winner(board), null);
  assert.equal(isDraw(board), true);
});
