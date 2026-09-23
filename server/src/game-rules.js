export const MARK = Object.freeze({ EMPTY: "", X: "X", O: "O" });

export function createBoard(size = 3) {
  return Array.from({ length: size }, () => Array(size).fill(MARK.EMPTY));
}

export function winner(board, winLength = board.length === 3 ? 3 : 4) {
  const size = board.length;
  const directions = [[0, 1], [1, 0], [1, 1], [1, -1]];
  for (let row = 0; row < size; row += 1) {
    for (let col = 0; col < size; col += 1) {
      const mark = board[row][col];
      if (!mark) continue;
      for (const [dr, dc] of directions) {
        const endRow = row + (winLength - 1) * dr;
        const endCol = col + (winLength - 1) * dc;
        if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) continue;
        if (Array.from({ length: winLength }, (_, i) => board[row + i * dr][col + i * dc]).every((cell) => cell === mark)) return mark;
      }
    }
  }
  return null;
}

export function isDraw(board) {
  return !winner(board) && board.every((row) => row.every(Boolean));
}

export function roomSnapshot(room, playerId) {
  const player = room.players.find((item) => item.id === playerId);
  return {
    code: room.code, size: room.size, winLength: room.winLength, board: room.board,
    turn: room.turn, status: room.status, winner: room.winner, yourMark: player?.mark ?? null,
    players: room.players.map(({ id, name, mark }) => ({ id, name, mark })),
    spectators: room.spectators.map(({ id, name }) => ({ id, name }))
  };
}
