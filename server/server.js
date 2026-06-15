const { WebSocketServer } = require('ws');
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const low = require('lowdb');
const FileSync = require('lowdb/adapters/FileSync');
const adapter = new FileSync(path.join(__dirname, 'db.json'));
const db = low(adapter);
db.defaults({ players: {}, matchHistory: [] }).write();

const PORT = process.env.PORT || 8080;

const LEAGUES = [
  { name: 'Bronz', emoji: '🥉', min: 0, max: 1099, color: '#cd7f32' },
  { name: 'Gümüş', emoji: '🥈', min: 1100, max: 1199, color: '#aaaaaa' },
  { name: 'Altın', emoji: '🥇', min: 1200, max: 1349, color: '#f0c040' },
  { name: 'Elmas', emoji: '💎', min: 1350, max: 1499, color: '#60d0ff' },
  { name: 'Usta', emoji: '🏆', min: 1500, max: 1699, color: '#9b59b6' },
  { name: 'Efsane', emoji: '👑', min: 1700, max: 9999, color: '#e83030' },
];

function getLeague(elo) {
  return LEAGUES.find((l) => elo >= l.min && elo <= l.max) || LEAGUES[0];
}

function calcElo(myElo, oppElo, won) {
  const K = 32;
  const expected = 1 / (1 + Math.pow(10, (oppElo - myElo) / 400));
  return Math.round(K * ((won ? 1 : 0) - expected));
}

function getPlayer(uid) {
  return db.get(`players.${uid}`).value();
}

function upsertPlayer(uid, name) {
  if (!getPlayer(uid)) {
    db.set(`players.${uid}`, {
      uid,
      name: name || 'Oyuncu',
      elo: 1000,
      wins: 0,
      losses: 0,
      matches: 0,
      league: 'Bronz',
      createdAt: Date.now(),
    }).write();
  } else if (name) {
    db.set(`players.${uid}.name`, name).write();
  }
  return getPlayer(uid);
}

function updateElo(uid, eloChange, won) {
  const p = getPlayer(uid);
  if (!p) return;
  const newElo = Math.max(0, p.elo + eloChange);
  db.set(`players.${uid}.elo`, newElo)
    .set(`players.${uid}.league`, getLeague(newElo).name)
    .set(`players.${uid}.wins`, p.wins + (won ? 1 : 0))
    .set(`players.${uid}.losses`, p.losses + (won ? 0 : 1))
    .set(`players.${uid}.matches`, p.matches + 1)
    .write();
  return getPlayer(uid);
}

function getLeaderboard() {
  const all = Object.values(db.get('players').value() || {});
  return all.sort((a, b) => b.elo - a.elo).slice(0, 50);
}

const matchmakingQueue = [];

function findMatch(newEntry) {
  const ELO_RANGE = 200;
  const now = Date.now();

  let best = null;
  let bestIdx = -1;
  for (let i = 0; i < matchmakingQueue.length; i++) {
    const candidate = matchmakingQueue[i];
    if (candidate.uid === newEntry.uid) continue;
    const waited = now - candidate.joinedAt;
    const range = ELO_RANGE + Math.floor(waited / 5000) * 100;
    if (Math.abs(candidate.elo - newEntry.elo) <= range) {
      if (!best || candidate.joinedAt < best.joinedAt) {
        best = candidate;
        bestIdx = i;
      }
    }
  }
  if (best) matchmakingQueue.splice(bestIdx, 1);
  return best;
}

const rooms = new Map();

class Room {
  constructor(id) {
    this.id = id;
    this.players = [null, null];
    this.uids = ['', ''];
    this.created = Date.now();
    this.ranked = false;
  }
  get isFull() {
    return !!(this.players[0] && this.players[1]);
  }
  get isEmpty() {
    return !this.players[0] && !this.players[1];
  }

  join(ws, uid) {
    for (let i = 0; i < 2; i++) {
      if (!this.players[i]) {
        this.players[i] = ws;
        this.uids[i] = uid;
        ws.seat = i;
        ws.roomId = this.id;
        ws.uid = uid;
        return i;
      }
    }
    return -1;
  }
  leave(ws) {
    for (let i = 0; i < 2; i++) {
      if (this.players[i] === ws) {
        this.players[i] = null;
        this.uids[i] = '';
      }
    }
  }
  send(seat, msg) {
    const ws = this.players[seat];
    if (ws && ws.readyState === 1) ws.send(JSON.stringify(msg));
  }
  broadcast(msg, exceptWs) {
    for (const ws of this.players) {
      if (ws && ws !== exceptWs && ws.readyState === 1) ws.send(JSON.stringify(msg));
    }
  }
}

function makeCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/leaderboard') {
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(JSON.stringify(getLeaderboard()));
    return;
  }

  if (url.pathname.startsWith('/player/')) {
    const uid = url.pathname.split('/player/')[1];
    const p = getPlayer(uid);
    res.writeHead(p ? 200 : 404, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(JSON.stringify(p || { error: 'not found' }));
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  ws.seat = -1;
  ws.roomId = null;
  ws.uid = null;

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }

    switch (msg.type) {
      case 'login': {
        const uid = msg.uid || `guest_${makeCode()}`;
        const name = msg.name || 'Oyuncu';
        ws.uid = uid;
        const player = upsertPlayer(uid, name);
        ws.send(
          JSON.stringify({
            type: 'profile',
            player,
            leagues: LEAGUES,
            league: getLeague(player.elo),
          }),
        );
        break;
      }

      case 'queue': {
        const uid = ws.uid || msg.uid || `guest_${makeCode()}`;
        ws.uid = uid;
        const player = upsertPlayer(uid, msg.name);
        ws.send(
          JSON.stringify({
            type: 'queued',
            elo: player.elo,
            league: getLeague(player.elo),
          }),
        );

        const entry = { ws, uid, elo: player.elo, joinedAt: Date.now() };
        const opponent = findMatch(entry);

        if (opponent) {
          const code = makeCode();
          const room = new Room(code);
          room.ranked = true;
          rooms.set(code, room);

          room.join(ws, uid);
          room.join(opponent.ws, opponent.uid);

          const myPlayer = getPlayer(uid);
          const oppPlayer = getPlayer(opponent.uid);

          room.send(0, {
            type: 'matched',
            seat: 0,
            room: code,
            ranked: true,
            myElo: myPlayer.elo,
            myLeague: getLeague(myPlayer.elo),
            oppElo: oppPlayer.elo,
            oppLeague: getLeague(oppPlayer.elo),
            oppName: oppPlayer.name,
          });
          room.send(1, {
            type: 'matched',
            seat: 1,
            room: code,
            ranked: true,
            myElo: oppPlayer.elo,
            myLeague: getLeague(oppPlayer.elo),
            oppElo: myPlayer.elo,
            oppLeague: getLeague(myPlayer.elo),
            oppName: myPlayer.name,
          });

          console.log(
            `Ranked match: ${myPlayer.name}(${myPlayer.elo}) vs ${oppPlayer.name}(${oppPlayer.elo})`,
          );
        } else {
          matchmakingQueue.push(entry);
          ws.send(
            JSON.stringify({
              type: 'waiting',
              queuePos: matchmakingQueue.length,
            }),
          );
        }
        break;
      }

      case 'dequeue': {
        const idx = matchmakingQueue.findIndex((e) => e.ws === ws);
        if (idx !== -1) matchmakingQueue.splice(idx, 1);
        break;
      }

      case 'join': {
        const code = (msg.room || '').trim().toUpperCase();
        let room = code
          ? rooms.get(code) ||
            (() => {
              const r = new Room(code);
              rooms.set(code, r);
              return r;
            })()
          : (() => {
              const r = new Room(makeCode());
              rooms.set(r.id, r);
              return r;
            })();

        if (room.isFull) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Oda dolu' }));
          return;
        }

        const uid = ws.uid || msg.uid || `guest_${makeCode()}`;
        ws.uid = uid;
        upsertPlayer(uid, msg.name);
        const seat = room.join(ws, uid);

        ws.send(
          JSON.stringify({
            type: 'joined',
            room: room.id,
            seat,
            waiting: !room.isFull,
          }),
        );
        if (room.isFull) {
          room.send(0, { type: 'start' });
          room.send(1, { type: 'start' });
        }
        break;
      }

      case 'matchEnd': {
        const room = rooms.get(ws.roomId);
        if (!room || !room.ranked) {
          room?.broadcast(msg, ws);
          break;
        }
        const winnerSeat = msg.winner;
        const winnerUid = room.uids[winnerSeat];
        const loserUid = room.uids[1 - winnerSeat];

        const winner = getPlayer(winnerUid);
        const loser = getPlayer(loserUid);
        if (!winner || !loser) break;

        const winnerGain = calcElo(winner.elo, loser.elo, true);
        const loserLoss = calcElo(loser.elo, winner.elo, false);

        const newWinner = updateElo(winnerUid, winnerGain, true);
        const newLoser = updateElo(loserUid, loserLoss, false);

        db.get('matchHistory')
          .push({
            winner: winnerUid,
            loser: loserUid,
            winnerEloChange: winnerGain,
            loserEloChange: loserLoss,
            timestamp: Date.now(),
          })
          .write();

        room.send(winnerSeat, {
          type: 'eloResult',
          won: true,
          eloChange: +winnerGain,
          newElo: newWinner.elo,
          newLeague: getLeague(newWinner.elo).name,
        });
        room.send(1 - winnerSeat, {
          type: 'eloResult',
          won: false,
          eloChange: loserLoss,
          newElo: newLoser.elo,
          newLeague: getLeague(newLoser.elo).name,
        });

        room.broadcast(msg, ws);
        break;
      }

      case 'shot':
      case 'state':
      case 'roundEnd':
      case 'nextRound':
      case 'newMatch':
      case 'rematch':
      case 'gameover':
        if (ws.roomId) rooms.get(ws.roomId)?.broadcast(msg, ws);
        break;

      case 'ping':
        ws.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  });

  ws.on('close', () => {
    const qi = matchmakingQueue.findIndex((e) => e.ws === ws);
    if (qi !== -1) matchmakingQueue.splice(qi, 1);

    if (!ws.roomId) return;
    const room = rooms.get(ws.roomId);
    if (!room) return;
    room.broadcast({ type: 'opponent_left' }, ws);
    room.leave(ws);
    if (room.isEmpty) rooms.delete(ws.roomId);
  });

  ws.on('error', () => {});
});

setInterval(() => {
  const now = Date.now();
  for (const [id, r] of rooms) {
    if (r.isEmpty || now - r.created > 3600000) rooms.delete(id);
  }
  for (let i = matchmakingQueue.length - 1; i >= 0; i--) {
    if (now - matchmakingQueue[i].joinedAt > 30000) matchmakingQueue.splice(i, 1);
  }
}, 30000);

server.listen(PORT, () => console.log(`Pucket server → http://localhost:${PORT}`));
