import { MARK } from "./game-rules.js";

// Android independently solves and verifies the declared answer before accepting it.
export const dailyPuzzle = Object.freeze({
  id: "daily-001", size: 3, winLength: 3,
  board: [[MARK.X, MARK.O, MARK.EMPTY], [MARK.O, MARK.X, MARK.EMPTY], [MARK.EMPTY, MARK.EMPTY, MARK.O]],
  next: MARK.X, answer: { row: 2, col: 2 }, title: "对角线的唯一机会"
});
