import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const rulesPath = join(root, 'contracts', 'game-rules.v1.json');
const puzzlesPath = join(root, 'contracts', 'puzzles.v1.json');
const protocolPath = join(root, 'contracts', 'websocket-protocol.v1.json');
const outputPath = join(root, 'ohos', 'entry', 'src', 'test', 'fixtures', 'ContractFixtures.ets');
const supportedModes = new Set(['3/3', '5/4']);

function renderValue(value) {
  return JSON.stringify(value, null, 2)
    .replace(/^/gm, '  ')
    .trimStart();
}

function sortedById(items) {
  return [...items].sort((left, right) => left.id.localeCompare(right.id, 'en'));
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertUniqueIds(label, items) {
  const ids = new Set();
  for (const item of items) {
    assert(typeof item.id === 'string' && item.id.length > 0, `${label} 存在空用例 ID`);
    assert(!ids.has(item.id), `${label} 存在重复用例 ID：${item.id}`);
    ids.add(item.id);
  }
}

function modeError(item) {
  if (item.size !== 3 && item.size !== 5) return 'INVALID_SIZE';
  if (!supportedModes.has(`${item.size}/${item.winLength}`)) return 'INVALID_WIN_LENGTH';
  return null;
}

function boardError(item) {
  const invalidMode = modeError(item);
  if (invalidMode) return invalidMode;
  if (typeof item.board !== 'string' || item.board.length !== item.size * item.size) {
    return 'INVALID_BOARD_LENGTH';
  }
  if (!/^[XO.]+$/.test(item.board)) return 'INVALID_BOARD_CHARACTER';
  return null;
}

function validateRuleContract(rules) {
  assert(rules.schema === 'ooxx.game-rules', '棋盘规则 schema 无效');
  assertUniqueIds('棋盘合法用例', rules.cases);
  assertUniqueIds('棋盘非法用例', rules.invalidCases);
  for (const item of rules.cases) {
    assert(boardError(item) === null, `棋盘合法用例无效：${item.id}`);
  }
  for (const item of rules.invalidCases) {
    assert(boardError(item) === item.reason, `棋盘非法用例原因不匹配：${item.id}`);
  }
}

function validatePuzzlePayload(item, allowInvalidBoard = false) {
  const payload = item.payload;
  assert(payload && typeof payload === 'object', `题目缺少 payload：${item.id}`);
  assert(typeof payload.id === 'string' && payload.id.length > 0, `题目缺少业务 ID：${item.id}`);
  assert(typeof payload.title === 'string', `题目缺少标题：${item.id}`);
  assert(payload.next === 'X' || payload.next === 'O', `题目下一手无效：${item.id}`);
  if (!allowInvalidBoard) assert(boardError(payload) === null, `题目棋盘无效：${item.id}`);
  const answer = payload.answer;
  assert(answer && Number.isInteger(answer.row) && Number.isInteger(answer.col), `题目答案坐标无效：${item.id}`);
}

function validatePuzzleContract(puzzles) {
  assert(puzzles.schema === 'ooxx.puzzles', '题目契约 schema 无效');
  assertUniqueIds('合法题目', puzzles.validCases);
  assertUniqueIds('非法题目', puzzles.invalidCases);
  for (const item of puzzles.validCases) {
    validatePuzzlePayload(item);
    const { payload } = item;
    const { row, col } = payload.answer;
    assert(row >= 0 && row < payload.size && col >= 0 && col < payload.size, `题目答案越界：${item.id}`);
    assert(payload.board[row * payload.size + col] === '.', `题目答案位置非空：${item.id}`);
    assert(item.expected?.answer?.row === row && item.expected?.answer?.col === col, `题目预期答案不一致：${item.id}`);
    assert(item.expected?.winnerAfterMove === payload.next, `题目预期胜者不一致：${item.id}`);
  }

  const knownReasons = new Set([
    'INVALID_BOARD_LENGTH',
    'ANSWER_OUT_OF_BOUNDS',
    'ANSWER_OCCUPIED',
    'WRONG_ANSWER',
    'NO_UNIQUE_SOLUTION'
  ]);
  for (const item of puzzles.invalidCases) {
    validatePuzzlePayload(item, item.reason === 'INVALID_BOARD_LENGTH');
    assert(knownReasons.has(item.reason), `未知题目失败原因：${item.id}`);
    const { payload } = item;
    const { row, col } = payload.answer;
    const inBounds = row >= 0 && row < payload.size && col >= 0 && col < payload.size;
    if (item.reason === 'INVALID_BOARD_LENGTH') {
      assert(boardError(payload) === 'INVALID_BOARD_LENGTH', `题目应包含错误棋盘长度：${item.id}`);
    } else if (item.reason === 'ANSWER_OUT_OF_BOUNDS') {
      assert(!inBounds, `题目答案应越界：${item.id}`);
    } else if (item.reason === 'ANSWER_OCCUPIED') {
      assert(inBounds && payload.board[row * payload.size + col] !== '.', `题目答案位置应已占用：${item.id}`);
    } else {
      assert(boardError(payload) === null && inBounds && payload.board[row * payload.size + col] === '.', `题目语义失败用例格式无效：${item.id}`);
    }
  }
}

function validateProtocolContract(protocol) {
  assert(protocol.schema === 'ooxx.websocket-protocol', '协议 schema 无效');
  assertUniqueIds('客户端协议消息', protocol.clientMessages);
  assertUniqueIds('服务端协议消息', protocol.serverMessages);
  assertUniqueIds('非法服务端协议消息', protocol.invalidServerMessages);
  for (const item of [...protocol.clientMessages, ...protocol.serverMessages]) {
    try {
      JSON.parse(item.wire);
    } catch {
      throw new Error(`协议消息不是合法 JSON：${item.id}`);
    }
  }
  for (const item of protocol.invalidServerMessages) {
    assert(item.expected === 'REJECT', `非法协议消息预期结果无效：${item.id}`);
  }
}

export async function renderContractFixtures() {
  const rules = JSON.parse(await readFile(rulesPath, 'utf8'));
  const puzzles = JSON.parse(await readFile(puzzlesPath, 'utf8'));
  const protocol = JSON.parse(await readFile(protocolPath, 'utf8'));
  validateRuleContract(rules);
  validatePuzzleContract(puzzles);
  validateProtocolContract(protocol);

  return `// 此文件由 tools/sync-contract-fixtures.mjs 生成，禁止手改。\n` +
`export interface ContractRuleCase {\n` +
`  id: string;\n  size: number;\n  winLength: number;\n  board: string;\n  winner: string | null;\n  draw: boolean;\n}\n\n` +
`export interface ContractInvalidRuleCase {\n` +
`  id: string;\n  size: number;\n  winLength: number;\n  board: string;\n  reason: string;\n}\n\n` +
`export interface ContractMove {\n  row: number;\n  col: number;\n}\n\n` +
`export interface ContractPuzzlePayload {\n` +
`  id: string;\n  title: string;\n  size: number;\n  winLength: number;\n  board: string;\n  next: string;\n  answer: ContractMove;\n}\n\n` +
`export interface ContractPuzzleExpected {\n` +
`  answer: ContractMove;\n  winnerAfterMove: string;\n}\n\n` +
`export interface ContractPuzzleCase {\n` +
`  id: string;\n  payload: ContractPuzzlePayload;\n  expected: ContractPuzzleExpected;\n}\n\n` +
`export interface ContractInvalidPuzzleCase {\n` +
`  id: string;\n  payload: ContractPuzzlePayload;\n  reason: string;\n}\n\n` +
`export interface ContractWireCase {\n  id: string;\n  wire: string;\n}\n\n` +
`export interface ContractInvalidWireCase {\n` +
`  id: string;\n  wire: string;\n  expected: string;\n}\n\n` +
`export const CONTRACT_VERSION: number = ${rules.version};\n` +
`export const CONTRACT_SCORE_WIN: number = ${rules.scoring.WIN};\n` +
`export const CONTRACT_SCORE_DRAW: number = ${rules.scoring.DRAW};\n` +
`export const CONTRACT_SCORE_LOSS: number = ${rules.scoring.LOSS};\n\n` +
`export const GAME_RULE_CASES: ContractRuleCase[] = ${renderValue(sortedById(rules.cases))};\n\n` +
`export const INVALID_GAME_RULE_CASES: ContractInvalidRuleCase[] = ${renderValue(sortedById(rules.invalidCases))};\n\n` +
`export const VALID_PUZZLE_CASES: ContractPuzzleCase[] = ${renderValue(sortedById(puzzles.validCases))};\n\n` +
`export const INVALID_PUZZLE_CASES: ContractInvalidPuzzleCase[] = ${renderValue(sortedById(puzzles.invalidCases))};\n\n` +
`export const CLIENT_MESSAGE_CASES: ContractWireCase[] = ${renderValue(sortedById(protocol.clientMessages))};\n\n` +
`export const SERVER_MESSAGE_CASES: ContractWireCase[] = ${renderValue(sortedById(protocol.serverMessages))};\n\n` +
`export const INVALID_SERVER_MESSAGE_CASES: ContractInvalidWireCase[] = ${renderValue(sortedById(protocol.invalidServerMessages))};\n`;
}

export async function syncContractFixtures(checkOnly = false) {
  const expected = await renderContractFixtures();
  if (checkOnly) {
    const actual = await readFile(outputPath, 'utf8').catch(() => '');
    if (actual !== expected) {
      throw new Error('鸿蒙契约夹具未同步，请执行 node tools/sync-contract-fixtures.mjs');
    }
    return;
  }
  await writeFile(outputPath, expected, 'utf8');
}

const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  await syncContractFixtures(process.argv.includes('--check'));
  console.log(process.argv.includes('--check') ? '契约夹具已同步' : `已生成 ${outputPath}`);
}
