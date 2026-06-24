const { WebSocketServer } = require('ws');
const http = require('http');
const path = require('path');
const crypto = require('crypto');

const low = require('lowdb');
const FileSync = require('lowdb/adapters/FileSync');
const adapter = new FileSync(path.join(__dirname, 'db.json'));
const db = low(adapter);
db.defaults({ players: {}, matchHistory: [] }).write();

const PORT = process.env.PORT || 8080;
const RECONNECT_GRACE_MS = parseInt(process.env.RECONNECT_GRACE_MS || '60000', 10);
const GUEST_RANKED = process.env.GUEST_RANKED === 'true';

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

function getMatchHistory(uid, limit = 20) {
  const history = db.get('matchHistory').value() || [];
  return history
    .filter((m) => m.winner === uid || m.loser === uid)
    .slice(-limit)
    .reverse()
    .map((m) => {
      const won = m.winner === uid;
      const oppUid = won ? m.loser : m.winner;
      const opp = getPlayer(oppUid);
      return {
        won,
        opponent: opp?.name || 'Oyuncu',
        opponentUid: oppUid,
        eloChange: won ? m.winnerEloChange : m.loserEloChange,
        timestamp: m.timestamp,
        ranked: !!m.ranked,
      };
    });
}

function isGuestUid(uid) {
  if (!uid) return true;
  return uid.startsWith('guest_') || uid.startsWith('u_');
}

function makeCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

function makeSessionToken() {
  return crypto.randomBytes(16).toString('hex');
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

class Room {
  constructor(id) {
    this.id = id;
    this.players = [null, null];
    this.uids = ['', ''];
    this.names = ['', ''];
    this.sessionTokens = ['', ''];
    this.created = Date.now();
    this.ranked = false;
    this.gameSnapshot = null;
    this.rematchVotes = [false, false];
    this.disconnectTimers = [null, null];
  }

  get isFull() {
    return !!(this.uids[0] && this.uids[1]);
  }

  get isEmpty() {
    return !this.uids[0] && !this.uids[1];
  }

  get connectedCount() {
    return this.players.filter(Boolean).length;
  }

  issueToken(seat) {
    const token = makeSessionToken();
    this.sessionTokens[seat] = token;
    return token;
  }

  join(ws, uid, name) {
    for (let i = 0; i < 2; i++) {
      if (!this.uids[i]) {
        this.players[i] = ws;
        this.uids[i] = uid;
        this.names[i] = name || 'Oyuncu';
        const token = this.issueToken(i);
        ws.seat = i;
        ws.roomId = this.id;
        ws.uid = uid;
        ws.sessionToken = token;
        return i;
      }
    }
    return -1;
  }

  reconnect(ws, seat) {
    if (this.disconnectTimers[seat]) {
      clearTimeout(this.disconnectTimers[seat]);
      this.disconnectTimers[seat] = null;
    }
    this.players[seat] = ws;
    ws.seat = seat;
    ws.roomId = this.id;
    ws.uid = this.uids[seat];
    ws.sessionToken = this.sessionTokens[seat];
    return true;
  }

  handleDisconnect(ws) {
    const seat = ws.seat;
    if (seat < 0 || seat > 1) return;
    this.players[seat] = null;
    this.broadcast(
      {
        type: 'opponent_disconnected',
        seat,
        graceSeconds: Math.floor(RECONNECT_GRACE_MS / 1000),
      },
      ws,
    );
    this.disconnectTimers[seat] = setTimeout(() => {
      this.broadcast({ type: 'opponent_left', seat });
      this.players[seat] = null;
      this.uids[seat] = '';
      this.names[seat] = '';
      this.sessionTokens[seat] = '';
      if (this.isEmpty) rooms.delete(this.id);
    }, RECONNECT_GRACE_MS);
  }

  leave(ws) {
    for (let i = 0; i < 2; i++) {
      if (this.players[i] === ws) {
        this.players[i] = null;
      }
    }
  }

  opponentSeat(seat) {
    return 1 - seat;
  }

  send(seat, msg) {
    const ws = this.players[seat];
    if (ws && ws.readyState === 1) ws.send(JSON.stringify(msg));
  }

  broadcast(msg, exceptWs) {
    for (const ws of this.players) {
      if (ws && ws !== exceptWs && ws.readyState === 1) {
        ws.send(JSON.stringify(msg));
      }
    }
  }

  resetRematch() {
    this.rematchVotes = [false, false];
  }
}

const rooms = new Map();

function getOrCreateRoom(code) {
  if (code && rooms.has(code)) return rooms.get(code);
  const id = code || makeCode();
  const room = new Room(id);
  rooms.set(id, room);
  return room;
}

function sendMatchInfo(room, seat0Uid, seat1Uid) {
  const p0 = getPlayer(seat0Uid);
  const p1 = getPlayer(seat1Uid);
  room.send(0, {
    type: 'matched',
    seat: 0,
    room: room.id,
    ranked: room.ranked,
    sessionToken: room.sessionTokens[0],
    myElo: p0.elo,
    myLeague: getLeague(p0.elo).name,
    oppElo: p1.elo,
    oppLeague: getLeague(p1.elo).name,
    oppName: p1.name,
  });
  room.send(1, {
    type: 'matched',
    seat: 1,
    room: room.id,
    ranked: room.ranked,
    sessionToken: room.sessionTokens[1],
    myElo: p1.elo,
    myLeague: getLeague(p1.elo).name,
    oppElo: p0.elo,
    oppLeague: getLeague(p0.elo).name,
    oppName: p0.name,
  });
}

function sendStart(room) {
  const p0 = getPlayer(room.uids[0]);
  const p1 = getPlayer(room.uids[1]);
  for (let seat = 0; seat < 2; seat++) {
    const oppSeat = room.opponentSeat(seat);
    room.send(seat, {
      type: 'start',
      sessionToken: room.sessionTokens[seat],
      oppName: room.names[oppSeat],
      oppElo: getPlayer(room.uids[oppSeat])?.elo ?? 1000,
      oppLeague: getLeague(getPlayer(room.uids[oppSeat])?.elo ?? 1000).name,
      oppUid: room.uids[oppSeat],
    });
  }
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const cors = { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'application/json' };

  if (url.pathname === '/' || url.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Pucket server OK');
    return;
  }

  if (url.pathname === '/leaderboard') {
    res.writeHead(200, cors);
    res.end(JSON.stringify(getLeaderboard()));
    return;
  }

  if (url.pathname.startsWith('/player/')) {
    const uid = decodeURIComponent(url.pathname.split('/player/')[1]);
    const p = getPlayer(uid);
    res.writeHead(p ? 200 : 404, cors);
    res.end(JSON.stringify(p || { error: 'not found' }));
    return;
  }

  if (url.pathname.startsWith('/match-history/')) {
    const uid = decodeURIComponent(url.pathname.split('/match-history/')[1]);
    res.writeHead(200, cors);
    res.end(JSON.stringify(getMatchHistory(uid)));
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
  ws.sessionToken = null;

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

      case 'reconnect': {
        const code = (msg.room || '').trim().toUpperCase();
        const uid = msg.uid;
        const token = msg.sessionToken;
        const room = rooms.get(code);
        if (!room || !uid || !token) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Yeniden bağlanılamadı' }));
          return;
        }
        let seat = -1;
        for (let i = 0; i < 2; i++) {
          if (room.uids[i] === uid && room.sessionTokens[i] === token) seat = i;
        }
        if (seat === -1) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Oturum süresi doldu' }));
          return;
        }
        room.reconnect(ws, seat);
        ws.send(
          JSON.stringify({
            type: 'reconnected',
            seat,
            room: code,
            ranked: room.ranked,
            snapshot: room.gameSnapshot,
            oppName: room.names[room.opponentSeat(seat)],
            oppElo: getPlayer(room.uids[room.opponentSeat(seat)])?.elo ?? 1000,
          }),
        );
        room.broadcast({ type: 'opponent_reconnected', seat }, ws);
        break;
      }

      case 'queue': {
        const uid = ws.uid || msg.uid || `guest_${makeCode()}`;
        ws.uid = uid;

        if (!GUEST_RANKED && isGuestUid(uid)) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Ranked için Google ile giriş yapın' }));
          return;
        }

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
          room.join(ws, uid, msg.name);
          const oppPlayer = getPlayer(opponent.uid);
          room.join(opponent.ws, opponent.uid, oppPlayer.name);
          sendMatchInfo(room, uid, opponent.uid);
          console.log(`Ranked: ${room.names[0]} vs ${room.names[1]}`);
        } else {
          matchmakingQueue.push(entry);
          ws.send(JSON.stringify({ type: 'waiting', queuePos: matchmakingQueue.length }));
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
        const room = getOrCreateRoom(code);
        if (room.isFull && !room.uids.includes(ws.uid || msg.uid)) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Oda dolu' }));
          return;
        }

        const uid = ws.uid || msg.uid || `guest_${makeCode()}`;
        ws.uid = uid;
        upsertPlayer(uid, msg.name);
        const seat = room.join(ws, uid, msg.name);

        ws.send(
          JSON.stringify({
            type: 'joined',
            room: room.id,
            seat,
            waiting: !room.isFull,
            sessionToken: room.sessionTokens[seat],
          }),
        );

        if (room.isFull) {
          sendStart(room);
        }
        break;
      }

      case 'state': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (room && ws.seat === 0) {
          room.gameSnapshot = {
            discs: msg.discs,
            roundWins: msg.roundWins,
            currentRound: msg.currentRound,
            phase: msg.phase,
            seconds: msg.seconds,
          };
        }
        if (ws.roomId) rooms.get(ws.roomId)?.broadcast(msg, ws);
        break;
      }

      case 'roundEnd': {
        if (ws.seat !== 0) break;
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (room) {
          room.gameSnapshot = {
            ...(room.gameSnapshot || {}),
            roundWins: msg.roundWins,
            currentRound: msg.currentRound,
            phase: 'gameover',
            lastWinner: msg.winner,
          };
        }
        if (ws.roomId) rooms.get(ws.roomId)?.broadcast(msg, ws);
        break;
      }

      case 'matchEnd': {
        if (ws.seat !== 0) break;
        const room = rooms.get(ws.roomId);
        if (!room || !room.ranked) {
          room?.broadcast(msg, ws);
          break;
        }
        const winnerSeat = msg.winner;
        if (winnerSeat !== 0 && winnerSeat !== 1) break;
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
            ranked: true,
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

      case 'rematch_request': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (!room || ws.seat < 0) break;
        room.rematchVotes[ws.seat] = true;
        room.broadcast({ type: 'rematch_request', seat: ws.seat }, ws);
        if (room.rematchVotes[0] && room.rematchVotes[1]) {
          room.resetRematch();
          room.gameSnapshot = null;
          room.broadcast({ type: 'rematch_accepted' });
        }
        break;
      }

      case 'rematch_decline': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (!room) break;
        room.resetRematch();
        room.broadcast({ type: 'rematch_declined', seat: ws.seat });
        break;
      }

      case 'shot':
      case 'pause':
      case 'resume':
      case 'nextRound':
      case 'newMatch':
      case 'rematch':
      case 'gameover':
        if (ws.roomId) rooms.get(ws.roomId)?.broadcast(msg, ws);
        break;

      case 'ping':
        ws.send(JSON.stringify({ type: 'pong', t: Date.now() }));
        break;
    }
  });

  ws.on('close', () => {
    const qi = matchmakingQueue.findIndex((e) => e.ws === ws);
    if (qi !== -1) matchmakingQueue.splice(qi, 1);

    if (!ws.roomId) return;
    const room = rooms.get(ws.roomId);
    if (!room) return;

    if (ws.seat >= 0 && room.uids[ws.seat]) {
      room.handleDisconnect(ws);
    } else {
      room.leave(ws);
      if (room.isEmpty) rooms.delete(ws.roomId);
    }
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
