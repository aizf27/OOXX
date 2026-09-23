import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

export class RankingStore {
  constructor(filePath) { this.filePath = filePath; this.entries = new Map(); }
  async load() {
    try { for (const entry of JSON.parse(await readFile(this.filePath, "utf8")).entries ?? []) this.entries.set(entry.id, entry); }
    catch (error) { if (error.code !== "ENOENT") throw error; }
  }
  list(limit = 20) {
    return [...this.entries.values()]
      .sort((a, b) => b.score - a.score || b.wins - a.wins || a.name.localeCompare(b.name))
      .slice(0, Math.min(Math.max(Number(limit) || 20, 1), 100))
      .map((entry, index) => ({ rank: index + 1, ...entry }));
  }
  async applyMatch({ id, name, result }) {
    const entry = this.entries.get(id) ?? { id, name: "匿名玩家", score: 0, wins: 0, losses: 0, draws: 0, updatedAt: 0 };
    entry.name = sanitizeName(name || entry.name);
    if (result === "WIN") { entry.score += 30; entry.wins += 1; }
    if (result === "DRAW") { entry.score += 10; entry.draws += 1; }
    if (result === "LOSS") { entry.score += 2; entry.losses += 1; }
    entry.updatedAt = Date.now(); this.entries.set(id, entry); await this.persist(); return entry;
  }
  async persist() {
    await mkdir(dirname(this.filePath), { recursive: true });
    const temporary = `${this.filePath}.tmp`;
    await writeFile(temporary, JSON.stringify({ entries: [...this.entries.values()] }, null, 2), "utf8");
    await rename(temporary, this.filePath);
  }
}
function sanitizeName(value) { return String(value).replace(/[\r\n|]/g, "").trim().slice(0, 20) || "匿名玩家"; }
