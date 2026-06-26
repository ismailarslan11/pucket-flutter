const ADMIN_USER = 'admin';

function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatDate(ts) {
  if (!ts) return '—';
  return new Date(ts).toLocaleString('tr-TR', { dateStyle: 'short', timeStyle: 'short' });
}

function checkAdminAuth(req) {
  const password = process.env.ADMIN_PASSWORD;
  if (!password) return { ok: false, configured: false };

  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Basic ')) return { ok: false, configured: true };

  const decoded = Buffer.from(auth.slice(6), 'base64').toString('utf8');
  const colon = decoded.indexOf(':');
  const user = colon >= 0 ? decoded.slice(0, colon) : '';
  const pass = colon >= 0 ? decoded.slice(colon + 1) : decoded;

  if (user !== ADMIN_USER || pass !== password) return { ok: false, configured: true };
  return { ok: true, configured: true };
}

function sendUnauthorized(res, configured) {
  if (!configured) {
    res.writeHead(503, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`<!DOCTYPE html><html lang="tr"><head><meta charset="utf-8"><title>Admin</title></head>
<body style="font-family:system-ui;background:#0f1419;color:#e8ecf0;padding:2rem">
<h1>Admin paneli yapılandırılmamış</h1>
<p>Render → Environment → <code>ADMIN_PASSWORD</code> değişkenini ekleyin ve servisi yeniden deploy edin.</p>
</body></html>`);
    return;
  }
  res.writeHead(401, {
    'Content-Type': 'text/plain; charset=utf-8',
    'WWW-Authenticate': 'Basic realm="PUCKET Admin"',
  });
  res.end('Giriş gerekli');
}

function collectAdminData(ctx) {
  const players = Object.values(ctx.db.get('players').value() || {});
  const usernames = ctx.db.get('usernames').value() || {};
  const matchHistory = [...(ctx.db.get('matchHistory').value() || [])].reverse().slice(0, 30);
  const reports = [...(ctx.db.get('reports').value() || [])].reverse().slice(0, 50);
  const playerMeta = ctx.db.get('playerMeta').value() || {};
  const season = ctx.getSeasonInfo();
  const tournament = ctx.db.get('tournament').value() || {};

  const sortedPlayers = players
    .slice()
    .sort((a, b) => b.elo - a.elo || b.matches - a.matches);

  const totalMatches = players.reduce((n, p) => n + (p.matches || 0), 0);
  const activeRooms = ctx.rooms ? [...ctx.rooms.values()].filter((r) => !r.isEmpty).length : 0;
  const queueSize = ctx.matchmakingQueue ? ctx.matchmakingQueue.length : 0;

  return {
    stats: {
      players: players.length,
      usernames: Object.keys(usernames).length,
      rankedMatches: matchHistory.length,
      totalPlayerMatches: totalMatches,
      reports: reports.length,
      activeRooms,
      queueSize,
      dbMode: process.env.DATABASE_URL ? 'PostgreSQL' : 'db.json',
    },
    season,
    tournament,
    sortedPlayers,
    usernames,
    matchHistory,
    reports,
    playerMeta,
    getPlayer: ctx.getPlayer,
  };
}

function renderAdminHtml(data) {
  const { stats, season, sortedPlayers, usernames, matchHistory, reports, getPlayer } = data;

  const playerRows = sortedPlayers
    .map(
      (p) => `<tr>
        <td>${escapeHtml(p.name)}</td>
        <td><code>${escapeHtml(p.uid)}</code></td>
        <td>${p.elo}</td>
        <td>${escapeHtml(p.league)}</td>
        <td>${p.wins}/${p.losses}</td>
        <td>${p.matches}</td>
        <td>${formatDate(p.createdAt)}</td>
      </tr>`
    )
    .join('');

  const usernameRows = Object.entries(usernames)
    .sort(([a], [b]) => a.localeCompare(b, 'tr'))
    .map(
      ([key, uid]) => `<tr>
        <td>${escapeHtml(key)}</td>
        <td><code>${escapeHtml(uid)}</code></td>
        <td>${escapeHtml(getPlayer(uid)?.name || '—')}</td>
      </tr>`
    )
    .join('');

  const matchRows = matchHistory
    .map((m) => {
      const winner = getPlayer(m.winner);
      const loser = getPlayer(m.loser);
      return `<tr>
        <td>${escapeHtml(winner?.name || m.winner)}</td>
        <td>${escapeHtml(loser?.name || m.loser)}</td>
        <td>${m.winnerEloChange > 0 ? '+' : ''}${m.winnerEloChange}</td>
        <td>${m.loserEloChange}</td>
        <td>${formatDate(m.timestamp)}</td>
      </tr>`;
    })
    .join('');

  const reportRows =
    reports.length === 0
      ? '<tr><td colspan="5" class="muted">Henüz rapor yok</td></tr>'
      : reports
          .map(
            (r) => `<tr>
        <td>${escapeHtml(r.reporter)}</td>
        <td>${escapeHtml(r.reported)}</td>
        <td>${escapeHtml(r.reason)}</td>
        <td>${escapeHtml(r.room)}</td>
        <td>${formatDate(r.timestamp)}</td>
      </tr>`
          )
          .join('');

  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PUCKET Admin</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; font-family: system-ui, -apple-system, sans-serif; background: #0b0f14; color: #e8ecf0; }
    header { padding: 1.25rem 1.5rem; border-bottom: 1px solid #1e2a38; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: .75rem; }
    h1 { margin: 0; font-size: 1.25rem; color: #4ade80; }
    .meta { color: #8b9cb3; font-size: .85rem; }
    main { padding: 1.5rem; max-width: 1200px; margin: 0 auto; }
    .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: .75rem; margin-bottom: 1.5rem; }
    .card { background: #141b24; border: 1px solid #1e2a38; border-radius: 10px; padding: 1rem; }
    .card b { display: block; font-size: 1.5rem; color: #fff; }
    .card span { font-size: .8rem; color: #8b9cb3; }
    section { margin-bottom: 2rem; }
    h2 { font-size: 1rem; margin: 0 0 .75rem; color: #94a3b8; text-transform: uppercase; letter-spacing: .05em; }
    .table-wrap { overflow-x: auto; border: 1px solid #1e2a38; border-radius: 10px; }
    table { width: 100%; border-collapse: collapse; font-size: .875rem; }
    th, td { padding: .6rem .75rem; text-align: left; border-bottom: 1px solid #1e2a38; }
    th { background: #141b24; color: #94a3b8; font-weight: 600; white-space: nowrap; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #141b24; }
    code { font-size: .75rem; color: #7dd3fc; }
    .muted { color: #64748b; }
    a { color: #4ade80; }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>PUCKET Admin</h1>
      <div class="meta">${escapeHtml(season.name)} · DB: ${escapeHtml(stats.dbMode)} · ${new Date().toLocaleString('tr-TR')}</div>
    </div>
    <div class="meta">Canlı: ${stats.activeRooms} oda · ${stats.queueSize} kuyruk</div>
  </header>
  <main>
    <div class="cards">
      <div class="card"><b>${stats.players}</b><span>Oyuncu</span></div>
      <div class="card"><b>${stats.usernames}</b><span>Kullanıcı adı</span></div>
      <div class="card"><b>${stats.rankedMatches}</b><span>Ranked maç kaydı</span></div>
      <div class="card"><b>${stats.reports}</b><span>Rapor</span></div>
      <div class="card"><b>${stats.activeRooms}</b><span>Aktif oda</span></div>
      <div class="card"><b>${stats.queueSize}</b><span>Eşleşme kuyruğu</span></div>
    </div>

    <section>
      <h2>Oyuncular (${sortedPlayers.length})</h2>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Ad</th><th>UID</th><th>ELO</th><th>Lig</th><th>G/M</th><th>Maç</th><th>Kayıt</th></tr></thead>
          <tbody>${playerRows || '<tr><td colspan="7" class="muted">Oyuncu yok</td></tr>'}</tbody>
        </table>
      </div>
    </section>

    <section>
      <h2>Kullanıcı adları</h2>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Username</th><th>UID</th><th>Görünen ad</th></tr></thead>
          <tbody>${usernameRows || '<tr><td colspan="3" class="muted">Kayıt yok</td></tr>'}</tbody>
        </table>
      </div>
    </section>

    <section>
      <h2>Son maçlar</h2>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Kazanan</th><th>Kaybeden</th><th>+ELO</th><th>-ELO</th><th>Tarih</th></tr></thead>
          <tbody>${matchRows || '<tr><td colspan="5" class="muted">Maç yok</td></tr>'}</tbody>
        </table>
      </div>
    </section>

    <section>
      <h2>Raporlar</h2>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Raporlayan</th><th>Şikâyet edilen</th><th>Sebep</th><th>Oda</th><th>Tarih</th></tr></thead>
          <tbody>${reportRows}</tbody>
        </table>
      </div>
    </section>
  </main>
</body>
</html>`;
}

function handleAdmin(req, res, url, ctx) {
  if (url.pathname === '/admin/api/stats') {
    const auth = checkAdminAuth(req);
    if (!auth.ok) {
      sendUnauthorized(res, auth.configured);
      return true;
    }
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(JSON.stringify(collectAdminData(ctx).stats));
    return true;
  }

  if (url.pathname !== '/admin') return false;

  const auth = checkAdminAuth(req);
  if (!auth.ok) {
    sendUnauthorized(res, auth.configured);
    return true;
  }

  const html = renderAdminHtml(collectAdminData(ctx));
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(html);
  return true;
}

module.exports = { handleAdmin };
