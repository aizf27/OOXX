// 此文件由 tools/sync-contract-fixtures.mjs 生成，禁止手改。
export interface ContractRuleCase {
  id: string;
  size: number;
  winLength: number;
  board: string;
  winner: string | null;
  draw: boolean;
}

export interface ContractWireCase {
  id: string;
  wire: string;
}

export const CONTRACT_VERSION: number = 1;
export const CONTRACT_SCORE_WIN: number = 30;
export const CONTRACT_SCORE_DRAW: number = 10;
export const CONTRACT_SCORE_LOSS: number = 2;

export const GAME_RULE_CASES: ContractRuleCase[] = [
    {
      "id": "classic-row-x",
      "size": 3,
      "winLength": 3,
      "board": "XXXOO....",
      "winner": "X",
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
      "id": "classic-anti-diagonal-o",
      "size": 3,
      "winLength": 3,
      "board": "XXO.O.O.X",
      "winner": "O",
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
      "id": "advanced-row-x",
      "size": 5,
      "winLength": 4,
      "board": "XXXXOOO..................",
      "winner": "X",
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
      "id": "advanced-anti-diagonal-o",
      "size": 5,
      "winLength": 4,
      "board": "X..O..XO...O...O........X",
      "winner": "O",
      "draw": false
    }
  ];

export const CLIENT_MESSAGE_CASES: ContractWireCase[] = [
    {
      "id": "hello",
      "wire": "{\"type\":\"hello\",\"playerId\":\"guest-contract\",\"name\":\"契约玩家\"}"
    },
    {
      "id": "create-classic-room",
      "wire": "{\"type\":\"room.create\",\"size\":3,\"winLength\":3}"
    },
    {
      "id": "create-advanced-room",
      "wire": "{\"type\":\"room.create\",\"size\":5,\"winLength\":4}"
    },
    {
      "id": "join-room",
      "wire": "{\"type\":\"room.join\",\"code\":\"ABC123\"}"
    },
    {
      "id": "request-room-state",
      "wire": "{\"type\":\"room.state\",\"code\":\"ABC123\"}"
    },
    {
      "id": "move",
      "wire": "{\"type\":\"move\",\"row\":1,\"col\":2}"
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
      "id": "hello-ok",
      "wire": "{\"type\":\"hello.ok\",\"playerId\":\"guest-contract\",\"name\":\"契约玩家\"}"
    },
    {
      "id": "room-created-waiting",
      "wire": "{\"type\":\"room.created\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"\",\"\",\"\"],[\"\",\"\",\"\"],[\"\",\"\",\"\"]],\"turn\":\"X\",\"status\":\"WAITING\",\"winner\":null,\"yourMark\":\"X\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"}],\"spectators\":[]}}"
    },
    {
      "id": "room-state-playing",
      "wire": "{\"type\":\"room.state\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"X\",\"O\",\"\"],[\"\",\"\",\"\"],[\"\",\"\",\"\"]],\"turn\":\"X\",\"status\":\"PLAYING\",\"winner\":null,\"yourMark\":\"X\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"},{\"id\":\"player-o\",\"name\":\"乙方\",\"mark\":\"O\"}],\"spectators\":[]}}"
    },
    {
      "id": "room-state-win",
      "wire": "{\"type\":\"room.state\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"X\",\"O\",\"\"],[\"X\",\"O\",\"\"],[\"X\",\"\",\"\"]],\"turn\":\"X\",\"status\":\"FINISHED\",\"winner\":\"X\",\"yourMark\":\"X\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"},{\"id\":\"player-o\",\"name\":\"乙方\",\"mark\":\"O\"}],\"spectators\":[]}}"
    },
    {
      "id": "room-state-draw",
      "wire": "{\"type\":\"room.state\",\"room\":{\"code\":\"ABC123\",\"size\":3,\"winLength\":3,\"board\":[[\"X\",\"O\",\"X\"],[\"X\",\"O\",\"O\"],[\"O\",\"X\",\"X\"]],\"turn\":\"X\",\"status\":\"FINISHED\",\"winner\":\"DRAW\",\"yourMark\":\"O\",\"players\":[{\"id\":\"player-x\",\"name\":\"甲方\",\"mark\":\"X\"},{\"id\":\"player-o\",\"name\":\"乙方\",\"mark\":\"O\"}],\"spectators\":[]}}"
    },
    {
      "id": "error",
      "wire": "{\"type\":\"error\",\"code\":\"NOT_YOUR_TURN\",\"message\":\"还没有轮到你\"}"
    }
  ];
