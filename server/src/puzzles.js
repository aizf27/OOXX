// 两端按扁平字符串解析棋盘，空格统一使用“.”。
export const dailyPuzzle = Object.freeze({
  id: "daily-001",
  size: 3,
  winLength: 3,
  board: "XO..X.O..",
  next: "X",
  answer: Object.freeze({ row: 2, col: 2 }),
  title: "对角线的唯一机会"
});
