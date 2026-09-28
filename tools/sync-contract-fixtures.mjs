import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const rulesPath = join(root, 'contracts', 'game-rules.v1.json');
const protocolPath = join(root, 'contracts', 'websocket-protocol.v1.json');
const outputPath = join(root, 'ohos', 'entry', 'src', 'test', 'fixtures', 'ContractFixtures.ets');

function renderValue(value) {
  return JSON.stringify(value, null, 2)
    .replace(/^/gm, '  ')
    .trimStart();
}

export async function renderContractFixtures() {
  const rules = JSON.parse(await readFile(rulesPath, 'utf8'));
  const protocol = JSON.parse(await readFile(protocolPath, 'utf8'));
  return `// 此文件由 tools/sync-contract-fixtures.mjs 生成，禁止手改。\n` +
`export interface ContractRuleCase {\n` +
`  id: string;\n  size: number;\n  winLength: number;\n  board: string;\n  winner: string | null;\n  draw: boolean;\n}\n\n` +
`export interface ContractWireCase {\n  id: string;\n  wire: string;\n}\n\n` +
`export const CONTRACT_VERSION: number = ${rules.version};\n` +
`export const CONTRACT_SCORE_WIN: number = ${rules.scoring.WIN};\n` +
`export const CONTRACT_SCORE_DRAW: number = ${rules.scoring.DRAW};\n` +
`export const CONTRACT_SCORE_LOSS: number = ${rules.scoring.LOSS};\n\n` +
`export const GAME_RULE_CASES: ContractRuleCase[] = ${renderValue(rules.cases)};\n\n` +
`export const CLIENT_MESSAGE_CASES: ContractWireCase[] = ${renderValue(protocol.clientMessages)};\n\n` +
`export const SERVER_MESSAGE_CASES: ContractWireCase[] = ${renderValue(protocol.serverMessages)};\n`;
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
