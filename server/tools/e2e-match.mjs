// 端到端联调脚本：两个 WebSocket 客户端在同一服务器上建房间、对下、分胜负
import WebSocket from "ws";

const URL = process.env.WS_URL ?? "ws://127.0.0.1:9527/ws";

function connect(name) {
  const socket = new WebSocket(URL);
  const queue = [];
  socket.on("message", (raw) => queue.push(JSON.parse(raw.toString())));
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  return {
    socket,
    async open() { await new Promise((resolve, reject) => { socket.once("open", resolve); socket.once("error", reject); }); },
    send(payload) { socket.send(JSON.stringify(payload)); },
    // 每次落子双方各收到一条 room.state 广播，等待片刻后取最新一条，避免读到旧状态
    async drain(type, ms = 300) {
      await sleep(ms);
      const error = queue.find((message) => message.type === "error");
      if (error) { queue.length = 0; throw new Error(`服务端错误 ${error.code}: ${error.message}`); }
      const matched = queue.filter((message) => message.type === type);
      queue.length = 0;
      if (!matched.length) throw new Error(`等待 ${type} 超时`);
      return matched[matched.length - 1];
    },
    close() { socket.close(); },
  };
}

const a = connect("A");
const b = connect("B");
await Promise.all([a.open(), b.open()]);

for (const [client, playerId, name] of [[a, "player-a", "甲方"], [b, "player-b", "乙方"]]) {
  client.send({ type: "hello", playerId, name });
  const ok = await client.drain("hello.ok");
  console.log(`hello.ok -> ${ok.name}`);
}

a.send({ type: "room.create", size: 3 });
const created = await a.drain("room.created");
const code = created.room.code;
console.log(`房间创建 -> ${code}`);

b.send({ type: "room.join", code });
const joined = await b.drain("room.state");
console.log(`乙方加入 -> players=${joined.room.players.length} turn=${joined.room.turn}`);

// 甲方走 0,0 / 1,0 / 2,0 竖线取胜；乙方走 0,1 / 1,1 拦截失败
const script = [
  [a, 0, 0], [b, 0, 1], [a, 1, 0], [b, 1, 1], [a, 2, 0],
];
let last = null;
for (const [client, row, col] of script) {
  client.send({ type: "move", row, col });
  last = await a.drain("room.state");
  const board = last.room.board.map((line) => line.join("")).join(" | ");
  console.log(`落子 ${row},${col} -> winner=${last.room.winner ?? "-"} ${board}`);
}

console.log(last.room.winner ? `结果：胜者 ${last.room.winner}` : "结果：未产出胜者（异常）");
a.close();
b.close();
process.exit(last.room.winner ? 0 : 1);
