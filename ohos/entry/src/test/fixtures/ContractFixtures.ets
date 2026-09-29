// 此文件由 tools/sync-contract-fixtures.mjs 生成，禁止手改。
export interface ContractRuleCase {
  id: string;
  size: number;
  winLength: number;
  board: string;
  winner: string | null;
  draw: boolean;
}

export interface ContractInvalidRuleCase {
  id: string;
  size: number;
  winLength: number;
  board: string;
  reason: string;
}

export interface ContractMove {
  row: number;
  col: number;
}

export interface ContractPuzzlePayload {
  id: string;
  title: string;
  size: number;
  winLength: number;
  board: string;
  next: string;
  answer: ContractMove;
}

export interface ContractPuzzleExpected {
  answer: ContractMove;
  winnerAfterMove: string;
}

export interface ContractPuzzleCase {
  id: string;
  payload: ContractPuzzlePayload;
  expected: ContractPuzzleExpected;
}

export interface ContractInvalidPuzzleCase {
  id: string;
  payload: ContractPuzzlePayload;
  reason: string;
}

export interface ContractWireCase {
  id: string;
  wire: string;
}

export interface ContractInvalidWireCase {
  id: string;
  wire: string;
  expected: string;
}

export const CONTRACT_VERSION: number = 1;
export const CONTRACT_SCORE_WIN: number = 30;
export const CONTRACT_SCORE_DRAW: number = 10;
export const CONTRACT_SCORE_LOSS: number = 2;

export const GAME_RULE_CASES: ContractRuleCase[] = [
    {
      "id": "advanced-anti-diagonal-o",
      "size": 5,
      "winLength": 4,
      "board": "X..O..XO...O...O........X",
      "winner": "O",
      "draw": false
    },
    {
      "id": "advanced-column-o",
      "size": 5,
      "winLength": 4,
      "board": "X...O.X..O..X.O....O.....",
      "winner": "O",
      "draw": false
    },
    {
      "id": "advanced-diagonal-x",
      "size": 5,
      "winLength": 4,
      "board": "X.....X.....X.....X.....O",
      "winner": "X",
      "draw": false
    },
    {
      "id": "advanced-row-x",
      "size": 5,
      "winLength": 4,
      "board": "XXXXOOO..................",
      "winner": "X",
      "draw": false
    },
    {
      "id": "classic-anti-diagonal-o",
      "size": 3,
      "winLength": 3,
      "board": "XXO.O.O.X",
      "winner": "O",
      "draw": false
    },
    {
      "id": "classic-column-o",
      "size": 3,
      "winLength": 3,
      "board": "XO.XO..OX",
      "winner": "O",
      "draw": false
    },
    {
      "id": "classic-diagonal-x",
      "size": 3,
      "winLength": 3,
      "board": "XOO.X...X",
      "winner": "X",
      "draw": false
    },
    {
      "id": "classic-draw",
      "size": 3,
      "winLength": 3,
      "board": "XOXXOOOXX",
      "winner": null,
      "draw": true
    },
    {
      "id": "classic-ongoing",
      "size": 3,
      "winLength": 3,
      "board": "XO..X.O..",
      "winner": null,
      "draw": false
    },
    {
      "id": "classic-row-x",
      "size": 3,
      "winLength": 3,
      "board": "XXXOO....",
      "winner": "X",
      "draw": false
    }
  ];

export const INVALID_GAME_RULE_CASES: ContractInvalidRuleCase[] = [
    {
      "id": "invalid-board-character",
      "size": 3,
      "winLength": 3,
      "board": "XQ.......",
      "reason": "INVALID_BOARD_CHARACTER"
    },
    {
      "id": "invalid-board-length",
      "size": 3,
      "winLength": 3,
      "board": "XO",
      "reason": "INVALID_BOARD_LENGTH"
    },
    {
      "id": "invalid-size",
      "size": 4,
      "winLength": 3,
      "board": "................",
      "reason": "INVALID_SIZE"
    },
    {
      "id": "invalid-win-length",
      "size": 5,
      "winLength": 3,
      "board": ".........................",
      "reason": "INVALID_WIN_LENGTH"
    }
  ];

export const VALID_PUZZLE_CASES: ContractPuzzleCase[] = [
    {
      "id": "daily-diagonal-finish",
      "payload": {
        "id": "daily-001",
        "title": "对角线的唯一机会",
        "size": 3,
        "winLength": 3,
        "board": "XO..X.O..",
        "next": "X",
        "answer": {
          "row": 2,
          "col": 2
        }
      },
      "expected": {
        "answer": {
          "row": 2,
          "col": 2
        },
        "winnerAfterMove": "X"
      }
    },
    {
      "id": "daily-top-row-finish",
      "payload": {
        "id": "daily-002",
        "title": "补全顶行",
        "size": 3,
        "winLength": 3,
        "board": "XX.OO....",
        "next": "X",
        "answer": {
          "row": 0,
          "col": 2
        }
      },
      "expected": {
        "answer": {
          "row": 0,
          "col": 2
        },
        "winnerAfterMove": "X"
      }
    }
  ];

export const INVALID_PUZZLE_CASES: ContractInvalidPuzzleCase[] = [
    {
      "id": "invalid-puzzle-answer-occupied",
      "payload": {
        "id": "invalid-003",
        "title": "答案位置已占用",
        "size": 3,
        "winLength": 3,
        "board": "XX.OO....",
        "next": "X",
        "answer": {
          "row": 0,
          "col": 0
        }
      },
      "reason": "ANSWER_OCCUPIED"
    },
    {
      "id": "invalid-puzzle-answer-out-of-bounds",
      "payload": {
        "id": "invalid-002",
        "title": "答案越界",
        "size": 3,
        "winLength": 3,
        "board": "XO..X.O..",
        "next": "X",
        "answer": {
          "row": 3,
          "col": 0
        }
      },
      "reason": "ANSWER_OUT_OF_BOUNDS"
    },
    {
      "id": "invalid-puzzle-board-length",
      "payload": {
        "id": "invalid-001",
        "title": "棋盘长度错误",
        "size": 3,
        "winLength": 3,
        "board": "XO",
        "next": "X",
        "answer": {
          "row": 0,
          "col": 0
        }
      },
      "reason": "INVALID_BOARD_LENGTH"
    },
    {
      "id": "invalid-puzzle-no-unique-answer",
      "payload": {
        "id": "invalid-005",
        "title": "无唯一解",
        "size": 3,
        "winLength": 3,
        "board": ".........",
        "next": "X",
        "answer": {
          "row": 1,
          "col": 1
        }
      },
      "reason": "NO_UNIQUE_SOLUTION"
    },
    {
      "id": "invalid-puzzle-wrong-answer",
      "payload": {
        "id": "invalid-004",
        "title": "答案错误",
        "size": 3,
        "winLength": 3,
        "board": "XX.OO....",
        "next": "X",
        "answer": {
          "row": 2,
          "col": 2
        }
      },
      "reason": "WRONG_ANSWER"
    }
  ];

export const CLIENT_MESSAGE_CASES: ContractWireCase[] = [
    {
      "id": "create-advanced-room",
      "wire": "{\"type\":\"room.create\",\"size\":5,\"winLength\":4}"
    },
    {
      "id": "create-classic-room",
      "wire": "{\"type\":\"room.create\",\"size\":3,\"winLength\":3}"
    },
    {
      "id": "hello",
      "wire": "{\"type\":\"hello\",\"playerId\":\"guest-contract\",\"name\":\"契约玩家\"}"
    },
    {
      "id": "join-room",
      "wire": "{\"type\":\"room.join\",\"code\":\"ABC123\"}"
    },
    {
      "id": "move",
      "wire": "{\"type\":\"move\",\"row\":1,\"col\":2}"
    },
    {
      "id": "request-room-state",
      "wire": "{\"type\":\"room.state\",\"code\":\"ABC123\"}"
    },
    {
      "id": "surrender",
      "wire": "{\"type\":\"game.surrender\"}"
    }
  ];

export const SERVER_MESSAGE_CASES: ContractWireCase[] = [
    {
      "id": "connected",
      "wire": "{\"type\":\"connected\",\"playerId\":\"guest-server\",\"protocol\":1}"
    },
    {
      "id": "error",
      "wire": "{\"type\":\"error\",\"code\":\"NOT_YOUR_TURN\",\"message\":\"还没有轮到你\"}"
    },
    {
      "id": "hello-ok",
      "wire": "{\"type\":\"hello.ok\",\"playerId\":\"guest-contract\",\"name\":\"契约玩家\"}"
    },
    {
      "id": "room-created-waiting",
      "wire": "{\"type\":\"room.created\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"\",\"\",\"\"],[\"\",\"\",\"\"],[\"\",\"\",\"\"]],\"turn\":\"X\",\"status\":\"WAITING\",\"winner\":null,\"yourMark\":\"X\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"}],\"spectators\":[]}}"
    },
    {
      "id": "room-state-draw",
      "wire": "{\"type\":\"room.state\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"X\",\"O\",\"X\"],[\"X\",\"O\",\"O\"],[\"O\",\"X\",\"X\"]],\"turn\":\"X\",\"status\":\"FINISHED\",\"winner\":\"DRAW\",\"yourMark\":\"O\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"},{\"id\":\"player-o\",\"name\":\"乙方\",\"mark\":\"O\"}],\"spectators\":[]}}"
    },
    {
      "id": "room-state-playing",
      "wire": "{\"type\":\"room.state\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"X\",\"O\",\"\"],[\"\",\"\",\"\"],[\"\",\"\",\"\"]],\"turn\":\"X\",\"status\":\"PLAYING\",\"winner\":null,\"yourMark\":\"X\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"},{\"id\":\"player-o\",\"name\":\"乙方\",\"mark\":\"O\"}],\"spectators\":[]}}"
    },
    {
      "id": "room-state-win",
      "wire": "{\"type\":\"room.state\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"X\",\"O\",\"\"],[\"X\",\"O\",\"\"],[\"X\",\"\",\"\"]],\"turn\":\"X\",\"status\":\"FINISHED\",\"winner\":\"X\",\"yourMark\":\"X\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"},{\"id\":\"player-o\",\"name\":\"乙方\",\"mark\":\"O\"}],\"spectators\":[]}}"
    }
  ];

export const INVALID_SERVER_MESSAGE_CASES: ContractInvalidWireCase[] = [
    {
      "id": "invalid-room-payload",
      "wire": "{\"type\":\"room.state\",\"room\":null}",
      "expected": "REJECT"
    },
    {
      "id": "malformed-json",
      "wire": "{bad json",
      "expected": "REJECT"
    },
    {
      "id": "missing-type",
      "wire": "{\"playerId\":\"guest-server\"}",
      "expected": "REJECT"
    },
    {
      "id": "unknown-type",
      "wire": "{\"type\":\"contract.unknown\"}",
      "expected": "REJECT"
    }
  ];
