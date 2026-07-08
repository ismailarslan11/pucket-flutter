const { WebSocketServer } = require('ws');
const http = require('http');
const crypto = require('crypto');

const { createStore } = require('./store');
const { handleAdmin } = require('./admin');
const { privacyHtml, termsHtml } = require('./legal_pages');
const {
  initFirebaseAuth,
  resolveLoginIdentity,
  canPlayRanked,
  isGuestUid,
} = require('./firebase_auth');
const push = require('./push');
const db = createStore();

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

function settleRankedMatch(room, winnerSeat) {
  if (!room.ranked || room.eloSettled) return false;
  if (winnerSeat !== 0 && winnerSeat !== 1) return false;
  const winnerUid = room.uids[winnerSeat];
  const loserUid = room.uids[1 - winnerSeat];
  if (!winnerUid || !loserUid) return false;
  const winner = getPlayer(winnerUid);
  const loser = getPlayer(loserUid);
  if (!winner || !loser) return false;

  room.eloSettled = true;
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
      seasonId: getSeasonInfo().id,
    })
    .write();

  bumpQuest(winnerUid, 'play');
  bumpQuest(loserUid, 'play');
  bumpQuest(winnerUid, 'win');
  grantAchievement(winnerUid, 'first_win');
  if (newWinner.wins >= 10) grantAchievement(winnerUid, 'ten_wins');
  const wMeta = getPlayerMeta(winnerUid);
  wMeta.seasonWins = (wMeta.seasonWins || 0) + 1;
  db.set(`playerMeta.${winnerUid}.seasonWins`, wMeta.seasonWins).write();
  const t = getTournamentState();
  if (t.entries.includes(winnerUid)) {
    t.scores[winnerUid] = (t.scores[winnerUid] || 0) + 3;
    db.set('tournament', t).write();
  }

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
  room.broadcast({ type: 'matchEnd', winner: winnerSeat, ranked: true, forfeit: true });
  return true;
}

function validateUsername(name) {
  const trimmed = (name || '').trim();
  if (trimmed.length < 2 || trimmed.length > 16) return null;
  if (!/^[a-zA-Z0-9_]+$/.test(trimmed)) return null;
  return trimmed;
}

function normalizeUsernameKey(name) {
  const v = validateUsername(name);
  return v ? v.toLowerCase() : null;
}

function checkUsernameAvailable(name, uid) {
  const key = normalizeUsernameKey(name);
  if (!key) {
    return { ok: false, available: false, error: 'Geçersiz kullanıcı adı' };
  }
  const owner = db.get(`usernames.${key}`).value();
  return { ok: true, available: !owner || owner === uid, key };
}

function claimUsername(uid, name) {
  if (!uid) return { ok: false, error: 'UID gerekli' };
  const displayName = validateUsername(name);
  if (!displayName) return { ok: false, error: 'Geçersiz kullanıcı adı (2-16 karakter, harf/rakam/_)' };

  const key = displayName.toLowerCase();
  const owner = db.get(`usernames.${key}`).value();
  if (owner && owner !== uid) {
    return { ok: false, error: 'Bu kullanıcı adı alınmış' };
  }

  const existing = getPlayer(uid);
  if (existing?.name) {
    const oldKey = normalizeUsernameKey(existing.name);
    if (oldKey && oldKey !== key && db.get(`usernames.${oldKey}`).value() === uid) {
      db.unset(`usernames.${oldKey}`).write();
    }
  }

  db.set(`usernames.${key}`, uid).write();
  const player = upsertPlayer(uid, displayName);
  return { ok: true, player };
}

function migrateUsernamesFromPlayers() {
  const players = db.get('players').value() || {};
  for (const [uid, p] of Object.entries(players)) {
    if (!p?.name || p.name === 'Oyuncu') continue;
    const key = normalizeUsernameKey(p.name);
    if (!key) continue;
    const owner = db.get(`usernames.${key}`).value();
    if (!owner) {
      db.set(`usernames.${key}`, uid).write();
    }
  }
}

function makeCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

function makeSessionToken() {
  return crypto.randomBytes(16).toString('hex');
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function weekKey() {
  const d = new Date();
  const oneJan = new Date(d.getFullYear(), 0, 1);
  const week = Math.ceil(((d - oneJan) / 86400000 + oneJan.getDay() + 1) / 7);
  return `${d.getFullYear()}-W${week}`;
}

function getSeasonInfo() {
  const season = db.get('season').value() || { id: 1, name: 'Sezon 1', startDate: Date.now() };
  return season;
}

function defaultQuests() {
  return { date: todayKey(), play: 0, win: 0, career: 0, claimed: false };
}

const DISC_PRICES = {
  dragon: 200,
  diamond: 250,
  goldcoin: 100,
  frost: 150,
  tiger: 175,
  robot: 125,
  swan: 120,
  alien: 300,
  pirate: 225,
  nature: 160,
  emoji_fire: 15,
  emoji_basketball: 15,
  emoji_ice: 18,
  emoji_lightning: 18,
  emoji_clover: 20,
  emoji_cry: 20,
  emoji_star: 22,
  emoji_skull: 25,
  emoji_ghost: 25,
  emoji_rocket: 28,
  emoji_devil: 30,
  emoji_crown: 32,
  emoji_trophy: 35,
};
const BOARD_PRICES = { neon: 120, wood: 150 };
const FREE_DISCS = new Set(['green', 'gold', 'blue', 'red', 'purple']);
const FREE_BOARDS = new Set(['classic']);
/** Test: tüm kozmetikler ücretsiz — yayın öncesi false yap */
const COSMETICS_FREE_FOR_TESTING = false;

function winTokenAmount(elo) {
  if (elo >= 1700) return 35;
  if (elo >= 1500) return 28;
  if (elo >= 1350) return 22;
  if (elo >= 1200) return 18;
  if (elo >= 1100) return 14;
  return 10;
}

function adTokenAmount(elo) {
  if (elo >= 1700) return 40;
  if (elo >= 1500) return 32;
  if (elo >= 1350) return 26;
  if (elo >= 1200) return 22;
  if (elo >= 1100) return 18;
  return 15;
}

function ensureTokenFields(meta) {
  if (typeof meta.tokens !== 'number') meta.tokens = 0;
  if (!Array.isArray(meta.unlockedDiscs)) meta.unlockedDiscs = [];
  if (!Array.isArray(meta.unlockedBoards)) meta.unlockedBoards = [];
  if (typeof meta.lastAdReward !== 'number') meta.lastAdReward = 0;
  return meta;
}

// ── Battle Pass ──
// Her kademe kümülatif XP eşiği + ücretsiz/premium ödül.
// Ödül tipleri: {t:'tokens',n:X} | {t:'disc',id:'...'} | {t:'board',id:'...'}
const BP_XP_PER_TIER = 150;
const BP_TIERS = [
  { free: { t: 'tokens', n: 30 }, premium: { t: 'tokens', n: 60 } },
  { free: { t: 'tokens', n: 30 }, premium: { t: 'tokens', n: 60 } },
  { free: { t: 'tokens', n: 40 }, premium: { t: 'disc', id: 'goldcoin' } },
  { free: { t: 'tokens', n: 40 }, premium: { t: 'tokens', n: 80 } },
  { free: { t: 'board', id: 'neon' }, premium: { t: 'disc', id: 'frost' } },
  { free: { t: 'tokens', n: 50 }, premium: { t: 'tokens', n: 100 } },
  { free: { t: 'tokens', n: 50 }, premium: { t: 'disc', id: 'tiger' } },
  { free: { t: 'tokens', n: 60 }, premium: { t: 'tokens', n: 120 } },
  { free: { t: 'tokens', n: 60 }, premium: { t: 'disc', id: 'dragon' } },
  { free: { t: 'disc', id: 'robot' }, premium: { t: 'disc', id: 'alien' } },
];

function bpTierForXp(xp) {
  return Math.min(BP_TIERS.length, Math.floor((xp || 0) / BP_XP_PER_TIER));
}

function ensureBpFields(meta) {
  if (typeof meta.seasonXp !== 'number') meta.seasonXp = 0;
  if (!Array.isArray(meta.bpClaimedFree)) meta.bpClaimedFree = [];
  if (!Array.isArray(meta.bpClaimedPremium)) meta.bpClaimedPremium = [];
  if (typeof meta.bpPremium !== 'boolean') meta.bpPremium = false;
  return meta;
}

function grantBpReward(uid, meta, reward) {
  if (!reward) return;
  if (reward.t === 'tokens') {
    ensureTokenFields(meta);
    meta.tokens += reward.n;
    db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
  } else if (reward.t === 'disc') {
    ensureTokenFields(meta);
    if (!meta.unlockedDiscs.includes(reward.id)) {
      meta.unlockedDiscs.push(reward.id);
      db.set(`playerMeta.${uid}.unlockedDiscs`, meta.unlockedDiscs).write();
    }
  } else if (reward.t === 'board') {
    ensureTokenFields(meta);
    if (!meta.unlockedBoards.includes(reward.id)) {
      meta.unlockedBoards.push(reward.id);
      db.set(`playerMeta.${uid}.unlockedBoards`, meta.unlockedBoards).write();
    }
  }
}

function getPlayerMeta(uid) {
  if (!uid) return null;
  const meta = db.get(`playerMeta.${uid}`).value();
  if (!meta) {
    const fresh = {
      quests: defaultQuests(),
      streak: 0,
      lastLoginDate: '',
      achievements: [],
      cosmetics: { discColor: 'green', boardTheme: 'classic' },
      fcmToken: '',
      seasonWins: 0,
      tokens: 0,
      unlockedDiscs: [],
      unlockedBoards: [],
      lastAdReward: 0,
    };
    db.set(`playerMeta.${uid}`, fresh).write();
    return fresh;
  }
  if (meta.quests?.date !== todayKey()) {
    meta.quests = defaultQuests();
    db.set(`playerMeta.${uid}.quests`, meta.quests).write();
  }
  return ensureTokenFields(meta);
}

function touchLoginStreak(uid) {
  const meta = getPlayerMeta(uid);
  const today = todayKey();
  if (meta.lastLoginDate === today) return meta;
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  meta.streak = meta.lastLoginDate === yesterday ? (meta.streak || 0) + 1 : 1;
  meta.lastLoginDate = today;
  db.set(`playerMeta.${uid}`, meta).write();
  return meta;
}

function bumpQuest(uid, field) {
  const meta = getPlayerMeta(uid);
  if (meta.quests.date !== todayKey()) meta.quests = defaultQuests();
  meta.quests[field] = (meta.quests[field] || 0) + 1;
  db.set(`playerMeta.${uid}.quests`, meta.quests).write();
  return meta.quests;
}

function grantAchievement(uid, id) {
  const meta = getPlayerMeta(uid);
  if (!meta.achievements.includes(id)) {
    meta.achievements.push(id);
    db.set(`playerMeta.${uid}.achievements`, meta.achievements).write();
  }
}

function getCareerData(uid) {
  return db.get(`career.${uid}`).value() || null;
}

function saveCareerData(uid, data) {
  db.set(`career.${uid}`, data).write();
  return data;
}

// Haftalık turnuva ödülleri (ilk 3 sıra, jeton).
const TOURNAMENT_PRIZES = [300, 150, 75];

function distributeTournamentPrizes(prev) {
  if (!prev || !prev.scores) return;
  const ranked = Object.entries(prev.scores)
    .filter(([, pts]) => pts > 0)
    .sort((a, b) => b[1] - a[1])
    .slice(0, TOURNAMENT_PRIZES.length);
  ranked.forEach(([uid], i) => {
    const meta = getPlayerMeta(uid);
    if (!meta) return;
    ensureTokenFields(meta);
    meta.tokens += TOURNAMENT_PRIZES[i];
    db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
  });
}

function getTournamentState() {
  const wk = weekKey();
  let t = db.get('tournament').value() || { weekId: '', entries: [], scores: {} };
  if (t.weekId !== wk) {
    // Yeni hafta: önceki haftanın ilk 3'üne ödül dağıt, sonra sıfırla.
    if (t.weekId) distributeTournamentPrizes(t);
    t = { weekId: wk, entries: [], scores: {} };
    db.set('tournament', t).write();
  }
  return t;
}

function readJsonBody(req) {
  const MAX = 65536;
  return new Promise((resolve, reject) => {
    let body = '';
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX) {
        reject(new Error('body too large'));
        req.destroy();
        return;
      }
      body += chunk;
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(body || '{}'));
      } catch {
        reject(new Error('invalid json'));
      }
    });
    req.on('error', reject);
  });
}

const matchmakingQueue = [];
const casualMatchmakingQueue = [];
// Çevrimiçi oyuncular: uid -> aktif bağlantı sayısı (arkadaş durumu için).
const onlineUids = new Map();
function markOnline(uid) {
  if (!uid) return;
  onlineUids.set(uid, (onlineUids.get(uid) || 0) + 1);
}
function markOffline(uid) {
  if (!uid || !onlineUids.has(uid)) return;
  const n = onlineUids.get(uid) - 1;
  if (n <= 0) onlineUids.delete(uid);
  else onlineUids.set(uid, n);
}

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
    this.eloSettled = false;
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
      const oppSeat = this.opponentSeat(seat);
      this.broadcast({ type: 'opponent_left', seat });
      if (this.ranked && this.uids[oppSeat]) {
        settleRankedMatch(this, oppSeat);
      }
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
    if (ws && ws.readyState === 1) {
      ws.send(JSON.stringify({ ...msg, yourSeat: seat }));
    }
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

// Bir oyuncunun seçili pul kozmetiği (rakibe göstermek için).
function discOf(uid) {
  const meta = db.get(`playerMeta.${uid}`).value();
  return (meta && meta.cosmetics && meta.cosmetics.discColor) || 'green';
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
    oppUid: seat1Uid,
    oppDisc: discOf(seat1Uid),
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
    oppUid: seat0Uid,
    oppDisc: discOf(seat0Uid),
  });
}

function sendStart(room) {
  for (let seat = 0; seat < 2; seat++) {
    const oppSeat = room.opponentSeat(seat);
    room.send(seat, {
      type: 'start',
      room: room.id,
      seat,
      sessionToken: room.sessionTokens[seat],
      oppName: room.names[oppSeat],
      oppElo: getPlayer(room.uids[oppSeat])?.elo ?? 1000,
      oppLeague: getLeague(getPlayer(room.uids[oppSeat])?.elo ?? 1000).name,
      oppUid: room.uids[oppSeat],
      oppDisc: discOf(room.uids[oppSeat]),
    });
  }
}

function pairCasualMatch(entry) {
  const opp = casualMatchmakingQueue.shift();
  if (!opp) return false;

  const code = makeCode();
  const room = new Room(code);
  rooms.set(code, room);

  const p0 = getPlayer(opp.uid);
  const p1 = getPlayer(entry.uid);
  room.join(opp.ws, opp.uid, p0?.name || opp.name || 'Oyuncu');
  room.join(entry.ws, entry.uid, p1?.name || entry.name || 'Oyuncu');

  for (let seat = 0; seat < 2; seat++) {
    const oppSeat = room.opponentSeat(seat);
    room.send(seat, {
      type: 'joined',
      room: code,
      seat,
      waiting: false,
      sessionToken: room.sessionTokens[seat],
      oppName: room.names[oppSeat],
      oppElo: getPlayer(room.uids[oppSeat])?.elo ?? 1000,
      oppLeague: getLeague(getPlayer(room.uids[oppSeat])?.elo ?? 1000).name,
      oppUid: room.uids[oppSeat],
      oppDisc: discOf(room.uids[oppSeat]),
    });
  }
  sendStart(room);
  console.log(`Quick: ${room.names[0]} vs ${room.names[1]} (${code})`);
  return true;
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'application/json',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  if (req.method === 'OPTIONS') {
    res.writeHead(204, cors);
    res.end();
    return;
  }

  if (url.pathname === '/' || url.pathname === '/health') {
    const playerCount = Object.keys(db.get('players').value() || {}).length;
    const dbMode = process.env.DATABASE_URL ? 'postgres' : 'file';
    const pkg = require('./package.json');
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, db: dbMode, players: playerCount, version: pkg.version }));
    return;
  }

  if (url.pathname === '/privacy') {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    });
    res.end(privacyHtml());
    return;
  }

  if (url.pathname === '/terms') {
    res.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    });
    res.end(termsHtml());
    return;
  }

  if (url.pathname === '/register' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = data.uid;
        const name = data.name || 'Oyuncu';
        if (!uid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'UID gerekli' }));
          return;
        }
        const player = upsertPlayer(uid, name);
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, player }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
      });
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

  if (url.pathname === '/username/check') {
    const name = url.searchParams.get('name') || '';
    const uid = url.searchParams.get('uid') || '';
    const result = checkUsernameAvailable(name, uid);
    res.writeHead(200, cors);
    res.end(JSON.stringify(result));
    return;
  }

  if (url.pathname === '/username/claim' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const result = claimUsername(data.uid, data.username);
        res.writeHead(result.ok ? 200 : 409, cors);
        res.end(JSON.stringify(result));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
      });
    return;
  }

  if (url.pathname === '/season') {
    res.writeHead(200, cors);
    res.end(JSON.stringify(getSeasonInfo()));
    return;
  }

  if (url.pathname === '/season/leaderboard') {
    const season = getSeasonInfo();
    const all = Object.entries(db.get('playerMeta').value() || {})
      .map(([uid, meta]) => {
        const p = getPlayer(uid);
        if (!p) return null;
        return { uid, name: p.name, seasonWins: meta.seasonWins || 0, elo: p.elo };
      })
      .filter(Boolean)
      .sort((a, b) => b.seasonWins - a.seasonWins || b.elo - a.elo)
      .slice(0, 50);
    res.writeHead(200, cors);
    res.end(JSON.stringify({ season, leaderboard: all }));
    return;
  }

  if (url.pathname.startsWith('/meta/')) {
    const uid = decodeURIComponent(url.pathname.split('/meta/')[1]);
    if (req.method === 'GET') {
      const name = url.searchParams.get('name') || '';
      upsertPlayer(uid, name || undefined);
      touchLoginStreak(uid);
      res.writeHead(200, cors);
      res.end(JSON.stringify(getPlayerMeta(uid)));
      return;
    }
    if (req.method === 'POST') {
      readJsonBody(req)
        .then((data) => {
          const meta = getPlayerMeta(uid);
          if (data.action === 'claim_quests') {
            const q = meta.quests;
            if (q.claimed) {
              res.writeHead(409, cors);
              res.end(JSON.stringify({ ok: false, error: 'Zaten alındı' }));
              return;
            }
            if (q.play < 3 || q.win < 1 || q.career < 1) {
              res.writeHead(409, cors);
              res.end(JSON.stringify({ ok: false, error: 'Görevler tamamlanmadı' }));
              return;
            }
            q.claimed = true;
            db.set(`playerMeta.${uid}.quests`, q).write();
            res.writeHead(200, cors);
            res.end(JSON.stringify({ ok: true, meta: getPlayerMeta(uid), reward: 50 }));
            return;
          }
          if (data.cosmetics) {
            const next = { ...meta.cosmetics, ...data.cosmetics };
            const disc = next.discColor;
            const board = next.boardTheme;
            if (disc && !COSMETICS_FREE_FOR_TESTING && !FREE_DISCS.has(disc) && !(meta.unlockedDiscs || []).includes(disc)) {
              res.writeHead(403, cors);
              res.end(JSON.stringify({ ok: false, error: 'Kilitli kozmetik' }));
              return;
            }
            if (board && !COSMETICS_FREE_FOR_TESTING && !FREE_BOARDS.has(board) && !(meta.unlockedBoards || []).includes(board)) {
              res.writeHead(403, cors);
              res.end(JSON.stringify({ ok: false, error: 'Kilitli kozmetik' }));
              return;
            }
            db.set(`playerMeta.${uid}.cosmetics`, next).write();
          }
          if (data.action === 'earn_win') {
            ensureTokenFields(meta);
            const p = upsertPlayer(uid);
            let gain = winTokenAmount(p.elo || 1000);
            // Günün ilk galibiyeti 2x jeton (geri dönüş teşviki).
            const today = new Date().toISOString().slice(0, 10);
            let doubled = false;
            if (meta.lastWinTokenDate !== today) {
              gain *= 2;
              doubled = true;
              meta.lastWinTokenDate = today;
              db.set(`playerMeta.${uid}.lastWinTokenDate`, today).write();
            }
            meta.tokens += gain;
            db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
            res.writeHead(200, cors);
            res.end(JSON.stringify({ ok: true, meta: getPlayerMeta(uid), tokenGain: gain, doubled }));
            return;
          }
          if (data.action === 'reward_ad') {
            ensureTokenFields(meta);
            const now = Date.now();
            if (now - (meta.lastAdReward || 0) < 30000) {
              res.writeHead(429, cors);
              res.end(JSON.stringify({ ok: false, error: '30 saniye bekle' }));
              return;
            }
            const p = upsertPlayer(uid);
            const gain = adTokenAmount(p.elo || 1000);
            meta.tokens += gain;
            meta.lastAdReward = now;
            db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
            db.set(`playerMeta.${uid}.lastAdReward`, now).write();
            res.writeHead(200, cors);
            res.end(JSON.stringify({ ok: true, meta: getPlayerMeta(uid), tokenGain: gain }));
            return;
          }
          if (data.action === 'purchase') {
            ensureTokenFields(meta);
            const type = data.itemType;
            const itemId = data.itemId;
            let price = 0;
            if (type === 'disc') {
              if (FREE_DISCS.has(itemId)) {
                res.writeHead(400, cors);
                res.end(JSON.stringify({ ok: false, error: 'Ücretsiz' }));
                return;
              }
              price = DISC_PRICES[itemId];
              if (!price) {
                res.writeHead(400, cors);
                res.end(JSON.stringify({ ok: false, error: 'Geçersiz pul' }));
                return;
              }
              if (meta.unlockedDiscs.includes(itemId)) {
                res.writeHead(409, cors);
                res.end(JSON.stringify({ ok: false, error: 'Zaten açık' }));
                return;
              }
              if (meta.tokens < price) {
                res.writeHead(402, cors);
                res.end(JSON.stringify({ ok: false, error: 'Yetersiz jeton' }));
                return;
              }
              meta.tokens -= price;
              meta.unlockedDiscs.push(itemId);
              const cosmetics = { ...(meta.cosmetics || {}), discColor: itemId };
              db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
              db.set(`playerMeta.${uid}.unlockedDiscs`, meta.unlockedDiscs).write();
              db.set(`playerMeta.${uid}.cosmetics`, cosmetics).write();
            } else if (type === 'board') {
              if (FREE_BOARDS.has(itemId)) {
                res.writeHead(400, cors);
                res.end(JSON.stringify({ ok: false, error: 'Ücretsiz' }));
                return;
              }
              price = BOARD_PRICES[itemId];
              if (!price) {
                res.writeHead(400, cors);
                res.end(JSON.stringify({ ok: false, error: 'Geçersiz tema' }));
                return;
              }
              if (meta.unlockedBoards.includes(itemId)) {
                res.writeHead(409, cors);
                res.end(JSON.stringify({ ok: false, error: 'Zaten açık' }));
                return;
              }
              if (meta.tokens < price) {
                res.writeHead(402, cors);
                res.end(JSON.stringify({ ok: false, error: 'Yetersiz jeton' }));
                return;
              }
              meta.tokens -= price;
              meta.unlockedBoards.push(itemId);
              const cosmetics = { ...(meta.cosmetics || {}), boardTheme: itemId };
              db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
              db.set(`playerMeta.${uid}.unlockedBoards`, meta.unlockedBoards).write();
              db.set(`playerMeta.${uid}.cosmetics`, cosmetics).write();
            } else {
              res.writeHead(400, cors);
              res.end(JSON.stringify({ ok: false, error: 'Geçersiz tip' }));
              return;
            }
            res.writeHead(200, cors);
            res.end(JSON.stringify({ ok: true, meta: getPlayerMeta(uid), spent: price }));
            return;
          }
          if (data.fcmToken) {
            db.set(`playerMeta.${uid}.fcmToken`, data.fcmToken).write();
          }
          // questBump yalnızca sunucu tarafından (matchEnd, career) — istemciden kabul edilmez
          res.writeHead(200, cors);
          res.end(JSON.stringify({ ok: true, meta: getPlayerMeta(uid) }));
        })
        .catch(() => {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
        });
      return;
    }
  }

  if (url.pathname.startsWith('/career/')) {
    const uid = decodeURIComponent(url.pathname.split('/career/')[1]);
    if (req.method === 'GET') {
      res.writeHead(200, cors);
      res.end(JSON.stringify(getCareerData(uid) || {}));
      return;
    }
    if (req.method === 'POST') {
      readJsonBody(req)
        .then((data) => {
          saveCareerData(uid, data);
          bumpQuest(uid, 'career');
          res.writeHead(200, cors);
          res.end(JSON.stringify({ ok: true }));
        })
        .catch(() => {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false }));
        });
      return;
    }
  }

  if (url.pathname === '/tournament') {
    const t = getTournamentState();
    const leaderboard = Object.entries(t.scores || {})
      .map(([uid, pts]) => {
        const p = getPlayer(uid);
        return p ? { uid, name: p.name, points: pts } : null;
      })
      .filter(Boolean)
      .sort((a, b) => b.points - a.points)
      .slice(0, 20);
    res.writeHead(200, cors);
    res.end(JSON.stringify({ weekId: t.weekId, entries: t.entries, leaderboard, prizes: TOURNAMENT_PRIZES }));
    return;
  }

  if (url.pathname === '/tournament/join' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = data.uid;
        if (!uid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false }));
          return;
        }
        upsertPlayer(uid, data.name);
        const t = getTournamentState();
        if (!t.entries.includes(uid)) {
          t.entries.push(uid);
          t.scores[uid] = t.scores[uid] || 0;
          db.set('tournament', t).write();
        }
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, tournament: t }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false }));
      });
    return;
  }

  // ── Battle Pass ──
  if (url.pathname.startsWith('/battlepass/') && req.method === 'GET') {
    const uid = decodeURIComponent(url.pathname.split('/battlepass/')[1]);
    const meta = ensureBpFields(getPlayerMeta(uid) || {});
    res.writeHead(200, cors);
    res.end(
      JSON.stringify({
        xp: meta.seasonXp || 0,
        xpPerTier: BP_XP_PER_TIER,
        tier: bpTierForXp(meta.seasonXp),
        premium: !!meta.bpPremium,
        claimedFree: meta.bpClaimedFree || [],
        claimedPremium: meta.bpClaimedPremium || [],
        tiers: BP_TIERS,
      }),
    );
    return;
  }

  if (url.pathname === '/battlepass/xp' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        const amount = Math.max(0, Math.min(200, (data.amount | 0)));
        if (!uid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false }));
          return;
        }
        const meta = ensureBpFields(getPlayerMeta(uid) || {});
        meta.seasonXp = (meta.seasonXp || 0) + amount;
        db.set(`playerMeta.${uid}.seasonXp`, meta.seasonXp).write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, xp: meta.seasonXp, tier: bpTierForXp(meta.seasonXp) }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false }));
      });
    return;
  }

  if (url.pathname === '/battlepass/claim' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        const tier = data.tier | 0;
        const premium = data.track === 'premium';
        if (!uid || tier < 0 || tier >= BP_TIERS.length) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'Geçersiz kademe' }));
          return;
        }
        const meta = ensureBpFields(getPlayerMeta(uid));
        const reached = bpTierForXp(meta.seasonXp) > tier;
        if (!reached) {
          res.writeHead(409, cors);
          res.end(JSON.stringify({ ok: false, error: 'Kademe açık değil' }));
          return;
        }
        if (premium && !meta.bpPremium) {
          res.writeHead(403, cors);
          res.end(JSON.stringify({ ok: false, error: 'Premium kilitli' }));
          return;
        }
        const claimed = premium ? meta.bpClaimedPremium : meta.bpClaimedFree;
        if (claimed.includes(tier)) {
          res.writeHead(409, cors);
          res.end(JSON.stringify({ ok: false, error: 'Zaten alındı' }));
          return;
        }
        const reward = premium ? BP_TIERS[tier].premium : BP_TIERS[tier].free;
        grantBpReward(uid, meta, reward);
        claimed.push(tier);
        db.set(`playerMeta.${uid}.${premium ? 'bpClaimedPremium' : 'bpClaimedFree'}`, claimed).write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, reward, meta: getPlayerMeta(uid) }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
      });
    return;
  }

  if (url.pathname === '/battlepass/unlock' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        // NOT: Gerçek satın alma doğrulaması IAP entegrasyonuyla eklenecek.
        // Şimdilik receipt olmadan premium açılmaz (güvenlik).
        if (!uid || !data.receipt) {
          res.writeHead(403, cors);
          res.end(JSON.stringify({ ok: false, error: 'Satın alma doğrulanamadı' }));
          return;
        }
        const meta = ensureBpFields(getPlayerMeta(uid));
        meta.bpPremium = true;
        db.set(`playerMeta.${uid}.bpPremium`, true).write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false }));
      });
    return;
  }

  // ── Arkadaş sistemi ──
  if (url.pathname.startsWith('/friends/') && req.method === 'GET') {
    const uid = decodeURIComponent(url.pathname.split('/friends/')[1]);
    const list = db.get(`friends.${uid}`).value() || [];
    const out = list
      .map((fid) => {
        const p = getPlayer(fid);
        if (!p) return null;
        return {
          uid: fid,
          name: p.name,
          elo: p.elo,
          league: getLeague(p.elo).name,
          online: onlineUids.has(fid),
        };
      })
      .filter(Boolean)
      .sort((a, b) => (b.online ? 1 : 0) - (a.online ? 1 : 0) || b.elo - a.elo);
    res.writeHead(200, cors);
    res.end(JSON.stringify(out));
    return;
  }

  if (url.pathname === '/friend/add' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        const uname = (data.username || '').trim().toLowerCase();
        const directUid = (data.friendUid || '').trim();
        if (!uid || (!uname && !directUid)) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'Eksik bilgi' }));
          return;
        }
        // uid ile (maç sonu) veya kullanıcı adı ile (elle ekleme) ekle.
        const friendUid = directUid || db.get(`usernames.${uname}`).value();
        if (!friendUid || !getPlayer(friendUid)) {
          res.writeHead(404, cors);
          res.end(JSON.stringify({ ok: false, error: 'Kullanıcı bulunamadı' }));
          return;
        }
        if (friendUid === uid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'Kendini ekleyemezsin' }));
          return;
        }
        const mine = db.get(`friends.${uid}`).value() || [];
        if (mine.includes(friendUid)) {
          res.writeHead(409, cors);
          res.end(JSON.stringify({ ok: false, error: 'Zaten arkadaş' }));
          return;
        }
        mine.push(friendUid);
        const theirs = db.get(`friends.${friendUid}`).value() || [];
        if (!theirs.includes(uid)) theirs.push(uid);
        db.set(`friends.${uid}`, mine).set(`friends.${friendUid}`, theirs).write();
        const p = getPlayer(friendUid);
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, friend: { uid: friendUid, name: p ? p.name : uname } }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
      });
    return;
  }

  if (url.pathname === '/friend/challenge' && req.method === 'POST') {
    readJsonBody(req)
      .then(async (data) => {
        const uid = (data.uid || '').trim();
        const friendUid = (data.friendUid || '').trim();
        const room = (data.room || '').trim();
        const name = (data.name || 'Bir arkadaşın').trim();
        if (!uid || !friendUid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false }));
          return;
        }
        const fmeta = getPlayerMeta(friendUid);
        let sent = false;
        if (fmeta && fmeta.fcmToken) {
          sent = await push.sendPush(
            fmeta.fcmToken,
            'Pucket meydan okuması!',
            `${name} seni maça çağırıyor`,
            { type: 'challenge', room },
          );
        }
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, delivered: sent }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false }));
      });
    return;
  }

  if (url.pathname === '/friend/remove' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        const friendUid = (data.friendUid || '').trim();
        if (!uid || !friendUid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'Eksik bilgi' }));
          return;
        }
        const mine = (db.get(`friends.${uid}`).value() || []).filter((f) => f !== friendUid);
        const theirs = (db.get(`friends.${friendUid}`).value() || []).filter((f) => f !== uid);
        db.set(`friends.${uid}`, mine).set(`friends.${friendUid}`, theirs).write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
      });
    return;
  }

  // IAP jeton paketi. NOT: Üretimde satın alma makbuzu (receipt) sunucuda
  // doğrulanmalı. Şimdilik istemci-bildirimli (mağaza satın almayı doğrular).
  if (url.pathname === '/iap/grant' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        const amount = Math.max(0, Math.min(1000, data.amount | 0));
        if (!uid || !amount) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false }));
          return;
        }
        const meta = ensureTokenFields(getPlayerMeta(uid));
        meta.tokens += amount;
        db.set(`playerMeta.${uid}.tokens`, meta.tokens).write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true, tokens: meta.tokens }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false }));
      });
    return;
  }

  if (url.pathname === '/account/delete' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        const uid = (data.uid || '').trim();
        if (!uid) {
          res.writeHead(400, cors);
          res.end(JSON.stringify({ ok: false, error: 'UID gerekli' }));
          return;
        }
        // Oyuncunun tüm verilerini kaldır (Play/App Store hesap silme gereksinimi).
        db.unset(`players.${uid}`);
        db.unset(`playerMeta.${uid}`);
        db.unset(`career.${uid}`);
        // Arkadaş listelerinden de çıkar
        const myFriends = db.get(`friends.${uid}`).value() || [];
        for (const fid of myFriends) {
          const theirs = (db.get(`friends.${fid}`).value() || []).filter((f) => f !== uid);
          db.set(`friends.${fid}`, theirs);
        }
        db.unset(`friends.${uid}`);
        const usernames = db.get('usernames').value() || {};
        for (const [key, owner] of Object.entries(usernames)) {
          if (owner === uid) db.unset(`usernames.${key}`);
        }
        const history = db.get('matchHistory').value() || [];
        const filtered = history.filter((m) => m.winner !== uid && m.loser !== uid);
        // Kalıcılaştır: db facade'ında standalone write yok, zincir üzerinden yaz.
        db.set('matchHistory', filtered).write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false, error: 'Geçersiz istek' }));
      });
    return;
  }

  if (url.pathname === '/report' && req.method === 'POST') {
    readJsonBody(req)
      .then((data) => {
        db.get('reports')
          .push({
            reporter: data.reporter || '',
            reported: data.reported || '',
            reason: data.reason || '',
            room: data.room || '',
            timestamp: Date.now(),
          })
          .write();
        res.writeHead(200, cors);
        res.end(JSON.stringify({ ok: true }));
      })
      .catch(() => {
        res.writeHead(400, cors);
        res.end(JSON.stringify({ ok: false }));
      });
    return;
  }

  if (
    handleAdmin(req, res, url, {
      db,
      getPlayer,
      getLeaderboard,
      getSeasonInfo,
      rooms,
      matchmakingQueue,
    })
  ) {
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
        (async () => {
          try {
            const identity = await resolveLoginIdentity(msg);
            let uid = identity.uid || msg.uid || `guest_${makeCode()}`;
            const name = msg.name || 'Oyuncu';
            ws.uid = uid;
            markOnline(uid);
            // Son aktiflik (geri-kazan push'u için).
            db.set(`playerMeta.${uid}.lastActiveDate`, new Date().toISOString().slice(0, 10)).write();
            ws.isAnonymous = identity.isAnonymous;
            ws.rankedEligible = canPlayRanked(ws, uid);
            const player = upsertPlayer(uid, name);
            ws.send(
              JSON.stringify({
                type: 'profile',
                player: { ...player, isAnonymous: ws.isAnonymous },
                leagues: LEAGUES,
                league: getLeague(player.elo),
              }),
            );
          } catch (e) {
            console.error('login error', e);
            ws.send(JSON.stringify({ type: 'error', msg: 'Giriş hatası' }));
          }
        })();
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
            oppDisc: discOf(room.uids[room.opponentSeat(seat)]),
          }),
        );
        room.broadcast({ type: 'opponent_reconnected', seat }, ws);
        break;
      }

      case 'queue': {
        const uid = ws.uid || msg.uid || `guest_${makeCode()}`;
        ws.uid = uid;

        if (!canPlayRanked(ws, uid)) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Ranked için Google veya Apple ile giriş yapın' }));
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
        let code = (msg.room || '').trim().toUpperCase();
        const uid = ws.uid || msg.uid || `guest_${makeCode()}`;
        ws.uid = uid;
        upsertPlayer(uid, msg.name);

        // Hızlı eşleştir: boş kod → casual kuyruk
        if (!code) {
          const existingIdx = casualMatchmakingQueue.findIndex((e) => e.ws === ws);
          if (existingIdx !== -1) casualMatchmakingQueue.splice(existingIdx, 1);

          const entry = { ws, uid, name: msg.name || 'Oyuncu', joinedAt: Date.now() };
          if (casualMatchmakingQueue.length > 0) {
            pairCasualMatch(entry);
          } else {
            casualMatchmakingQueue.push(entry);
            ws.send(
              JSON.stringify({
                type: 'waiting',
                queuePos: casualMatchmakingQueue.length,
              }),
            );
          }
          break;
        }

        const room = getOrCreateRoom(code);
        if (room.isFull && !room.uids.includes(uid)) {
          ws.send(JSON.stringify({ type: 'error', msg: 'Oda dolu' }));
          return;
        }

        const seat = room.join(ws, uid, msg.name);

        ws.send(
          JSON.stringify({
            type: 'joined',
            room: room.id,
            seat,
            yourSeat: seat,
            waiting: !room.isFull,
            sessionToken: room.sessionTokens[seat],
            oppName: room.isFull ? room.names[room.opponentSeat(seat)] : undefined,
            oppElo: room.isFull ? getPlayer(room.uids[room.opponentSeat(seat)])?.elo ?? 1000 : undefined,
            oppLeague: room.isFull
              ? getLeague(getPlayer(room.uids[room.opponentSeat(seat)])?.elo ?? 1000).name
              : undefined,
            oppUid: room.isFull ? room.uids[room.opponentSeat(seat)] : undefined,
            oppDisc: room.isFull ? discOf(room.uids[room.opponentSeat(seat)]) : undefined,
          }),
        );

        if (room.isFull) {
          sendStart(room);
        }
        break;
      }

      case 'state': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (!room || ws.seat !== 0) break;
        room.gameSnapshot = {
          discs: msg.discs,
          roundWins: msg.roundWins,
          currentRound: msg.currentRound,
          phase: msg.phase,
          seconds: msg.seconds,
          lastWinner: msg.lastWinner,
        };
        room.send(1, msg);
        break;
      }

      case 'roundEnd': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (!room) break;
        room.gameSnapshot = {
          ...(room.gameSnapshot || {}),
          roundWins: msg.roundWins,
          currentRound: msg.currentRound,
          phase: 'gameover',
          lastWinner: msg.winner,
        };
        for (let i = 0; i < 2; i++) {
          room.send(i, msg);
        }
        break;
      }

      case 'matchEnd': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (!room) break;
        if (!room.ranked) {
          room.broadcast(msg, ws);
          break;
        }
        if (ws.seat !== 0) break;
        const winnerSeat = msg.winner;
        if (settleRankedMatch(room, winnerSeat)) {
          room.broadcast(msg, ws);
        }
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
          room.eloSettled = false;
          room.ranked = false;
          room.broadcast({ type: 'rematch_accepted', ranked: false });
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
      case 'emote':
      case 'gameover': {
        const room = ws.roomId ? rooms.get(ws.roomId) : null;
        if (!room) break;
        if (msg.type === 'shot') {
          if (ws.seat === 1) room.send(0, msg);
          break;
        }
        if (msg.type === 'emote') {
          // Sadece emoji id'sini geçir (kötüye kullanımı önle).
          room.broadcast({ type: 'emote', e: String(msg.e || '').slice(0, 8) }, ws);
          break;
        }
        room.broadcast(msg, ws);
        break;
      }

      case 'ping':
        ws.send(JSON.stringify({ type: 'pong', t: msg.t || Date.now(), serverT: Date.now() }));
        break;
    }
  });

  ws.on('close', () => {
    markOffline(ws.uid);
    const qi = matchmakingQueue.findIndex((e) => e.ws === ws);
    if (qi !== -1) matchmakingQueue.splice(qi, 1);

    const ci = casualMatchmakingQueue.findIndex((e) => e.ws === ws);
    if (ci !== -1) casualMatchmakingQueue.splice(ci, 1);

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
    if (r.isEmpty) {
      rooms.delete(id);
    } else if (now - r.created > 7200000) {
      // 2 saatten eski boş olmayan odalar — muhtemelen terk edilmiş
      if (r.connectedCount === 0) rooms.delete(id);
    }
  }
  for (let i = matchmakingQueue.length - 1; i >= 0; i--) {
    if (now - matchmakingQueue[i].joinedAt > 30000) matchmakingQueue.splice(i, 1);
  }
  for (let i = casualMatchmakingQueue.length - 1; i >= 0; i--) {
    if (now - casualMatchmakingQueue[i].joinedAt > 30000) casualMatchmakingQueue.splice(i, 1);
  }
}, 30000);

// Günlük geri-kazan push'u: 3-14 gün önce aktif olup dönmemiş oyunculara,
// günde en fazla bir kez. Saatte bir kontrol eder.
function startEngagementScheduler() {
  if (!push.enabled) return;
  const HOUR = 3600000;
  setInterval(async () => {
    const today = new Date().toISOString().slice(0, 10);
    const players = db.get('playerMeta').value() || {};
    for (const [uid, meta] of Object.entries(players)) {
      if (!meta || !meta.fcmToken) continue;
      if (meta.lastActiveDate === today) continue;
      if (meta.lastPushDate === today) continue;
      const last = meta.lastActiveDate ? Date.parse(meta.lastActiveDate) : 0;
      if (!last) continue;
      const days = (Date.now() - last) / 86400000;
      if (days < 3 || days > 14) continue;
      const ok = await push.sendPush(
        meta.fcmToken,
        'Seni özledik! 🏒',
        'Günlük ödülün ve yeni rakipler seni bekliyor.',
        { type: 'winback' },
      );
      if (ok) db.set(`playerMeta.${uid}.lastPushDate`, today).write();
    }
  }, HOUR);
}

async function startServer() {
  await initFirebaseAuth();
  push.initPush();
  await db.init();
  db.defaults({
    players: {},
    matchHistory: [],
    usernames: {},
    playerMeta: {},
    career: {},
    reports: [],
    friends: {},
    tournament: { weekId: '', entries: [], scores: {} },
    season: { id: 1, name: 'Sezon 1', startDate: Date.now() },
  }).write();
  migrateUsernamesFromPlayers();

  server.listen(PORT, () => {
    console.log(`Pucket server → http://localhost:${PORT}`);
  });
  startEngagementScheduler();
}

const shutdown = async (signal) => {
  console.log(`${signal} — kapanıyor…`);
  await db.flush();
  await db.close();
  process.exit(0);
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

startServer().catch((err) => {
  console.error('Sunucu başlatılamadı:', err);
  process.exit(1);
});
