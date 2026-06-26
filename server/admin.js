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

function readFormBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      resolve(Object.fromEntries(new URLSearchParams(body)));
    });
    req.on('error', reject);
  });
}

function deletePlayer(db, uid) {
  if (!uid) return { ok: false, error: 'UID gerekli' };
  const player = db.get(`players.${uid}`).value();
  if (!player) return { ok: false, error: 'Oyuncu bulunamadı' };

  let chain = db.unset(`players.${uid}`).unset(`playerMeta.${uid}`).unset(`career.${uid}`);

  const usernames = db.get('usernames').value() || {};
  for (const [key, owner] of Object.entries(usernames)) {
    if (owner === uid) chain = chain.unset(`usernames.${key}`);
  }

  const history = (db.get('matchHistory').value() || []).filter(
    (m) => m.winner !== uid && m.loser !== uid
  );
  chain = chain.set('matchHistory', history);

  const t = db.get('tournament').value() || {};
  t.entries = (t.entries || []).filter((u) => u !== uid);
  if (t.scores) delete t.scores[uid];
  chain.set('tournament', t).write();

  return { ok: true, message: `${player.name} silindi` };
}

function resetPlayerElo(db, uid) {
  if (!uid) return { ok: false, error: 'UID gerekli' };
  const player = db.get(`players.${uid}`).value();
  if (!player) return { ok: false, error: 'Oyuncu bulunamadı' };

  db.set(`players.${uid}`, {
    ...player,
    elo: 1000,
    wins: 0,
    losses: 0,
    matches: 0,
    league: 'Bronz',
  }).write();

  const meta = db.get(`playerMeta.${uid}`).value();
  if (meta) {
    meta.seasonWins = 0;
    db.set(`playerMeta.${uid}`, meta).write();
  }

  return { ok: true, message: `${player.name} ELO sıfırlandı` };
}

function releaseUsername(db, key) {
  if (!key) return { ok: false, error: 'Kullanıcı adı gerekli' };
  const owner = db.get(`usernames.${key}`).value();
  if (!owner) return { ok: false, error: 'Kayıt bulunamadı' };
  db.unset(`usernames.${key}`).write();
  return { ok: true, message: `@${key} serbest bırakıldı` };
}

function clearReports(db) {
  db.set('reports', []).write();
  return { ok: true, message: 'Tüm raporlar silindi' };
}

function deleteReport(db, timestamp) {
  const ts = parseInt(timestamp, 10);
  if (!ts) return { ok: false, error: 'Geçersiz rapor' };
  const reports = (db.get('reports').value() || []).filter((r) => r.timestamp !== ts);
  db.set('reports', reports).write();
  return { ok: true, message: 'Rapor silindi' };
}

function runAdminAction(ctx, action, params) {
  switch (action) {
    case 'delete_player':
      return deletePlayer(ctx.db, params.uid);
    case 'reset_elo':
      return resetPlayerElo(ctx.db, params.uid);
    case 'release_username':
      return releaseUsername(ctx.db, (params.key || '').toLowerCase());
    case 'clear_reports':
      return clearReports(ctx.db);
    case 'delete_report':
      return deleteReport(ctx.db, params.timestamp);
    default:
      return { ok: false, error: 'Bilinmeyen işlem' };
  }
}

function collectAdminData(ctx) {
  const players = Object.values(ctx.db.get('players').value() || {});
  const usernames = ctx.db.get('usernames').value() || {};
  const matchHistory = [...(ctx.db.get('matchHistory').value() || [])].reverse().slice(0, 30);
  const reports = [...(ctx.db.get('reports').value() || [])].reverse().slice(0, 50);
  const season = ctx.getSeasonInfo();
  const sortedPlayers = players
    .slice()
    .sort((a, b) => b.elo - a.elo || b.matches - a.matches);

  const activeRooms = ctx.rooms ? [...ctx.rooms.values()].filter((r) => !r.isEmpty).length : 0;
  const queueSize = ctx.matchmakingQueue ? ctx.matchmakingQueue.length : 0;

  return {
    stats: {
      players: players.length,
      usernames: Object.keys(usernames).length,
      rankedMatches: matchHistory.length,
      reports: reports.length,
      activeRooms,
      queueSize,
      dbMode: process.env.DATABASE_URL ? 'PostgreSQL' : 'db.json',
    },
    season,
    sortedPlayers,
    usernames,
    matchHistory,
    reports,
    getPlayer: ctx.getPlayer,
  };
}

function actionBtn(action, fields, label, className = 'btn-danger') {
  const hidden = Object.entries(fields)
    .map(([k, v]) => `<input type="hidden" name="${escapeHtml(k)}" value="${escapeHtml(v)}">`)
    .join('');
  return `<form method="POST" action="/admin/action" class="inline-form"
    onsubmit="return confirm('${escapeHtml(label)} — emin misin?')">
    <input type="hidden" name="action" value="${escapeHtml(action)}">${hidden}
    <button type="submit" class="${className}">${escapeHtml(label)}</button>
  </form>`;
}

function renderAdminHtml(data, flash) {
  const { stats, season, sortedPlayers, usernames, matchHistory, reports, getPlayer } = data;

  const flashHtml = flash
    ? `<div class="flash ${flash.ok ? 'flash-ok' : 'flash-err'}">${escapeHtml(flash.message)}</div>`
    : '';

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
        <td class="actions">
          ${actionBtn('reset_elo', { uid: p.uid }, 'ELO sıfırla', 'btn-warn')}
          ${actionBtn('delete_player', { uid: p.uid }, 'Sil', 'btn-danger')}
        </td>
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
        <td class="actions">
          ${actionBtn('release_username', { key }, 'Serbest bırak', 'btn-warn')}
        </td>
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
      ? '<tr><td colspan="6" class="muted">Henüz rapor yok</td></tr>'
      : reports
          .map(
            (r) => `<tr>
        <td>${escapeHtml(r.reporter)}</td>
        <td>${escapeHtml(r.reported)}</td>
        <td>${escapeHtml(r.reason)}</td>
        <td>${escapeHtml(r.room)}</td>
        <td>${formatDate(r.timestamp)}</td>
        <td class="actions">
          ${actionBtn('delete_report', { timestamp: String(r.timestamp) }, 'Sil', 'btn-danger')}
        </td>
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
    .flash { padding: .75rem 1rem; border-radius: 8px; margin-bottom: 1rem; font-size: .9rem; }
    .flash-ok { background: #14532d; color: #bbf7d0; border: 1px solid #166534; }
    .flash-err { background: #450a0a; color: #fecaca; border: 1px solid #991b1b; }
    .cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: .75rem; margin-bottom: 1.5rem; }
    .card { background: #141b24; border: 1px solid #1e2a38; border-radius: 10px; padding: 1rem; }
    .card b { display: block; font-size: 1.5rem; color: #fff; }
    .card span { font-size: .8rem; color: #8b9cb3; }
    section { margin-bottom: 2rem; }
    .section-head { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: .5rem; margin-bottom: .75rem; }
    h2 { font-size: 1rem; margin: 0; color: #94a3b8; text-transform: uppercase; letter-spacing: .05em; }
    .table-wrap { overflow-x: auto; border: 1px solid #1e2a38; border-radius: 10px; }
    table { width: 100%; border-collapse: collapse; font-size: .875rem; }
    th, td { padding: .6rem .75rem; text-align: left; border-bottom: 1px solid #1e2a38; vertical-align: middle; }
    th { background: #141b24; color: #94a3b8; font-weight: 600; white-space: nowrap; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #141b24; }
    code { font-size: .75rem; color: #7dd3fc; }
    .muted { color: #64748b; }
    .actions { white-space: nowrap; }
    .inline-form { display: inline; margin: 0 .15rem; }
    button { font: inherit; cursor: pointer; border: none; border-radius: 6px; padding: .35rem .6rem; font-size: .75rem; }
    .btn-danger { background: #7f1d1d; color: #fecaca; }
    .btn-danger:hover { background: #991b1b; }
    .btn-warn { background: #713f12; color: #fde68a; }
    .btn-warn:hover { background: #854d0e; }
    .btn-muted { background: #1e293b; color: #94a3b8; }
    .btn-muted:hover { background: #334155; }
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
    ${flashHtml}
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
          <thead><tr><th>Ad</th><th>UID</th><th>ELO</th><th>Lig</th><th>G/M</th><th>Maç</th><th>Kayıt</th><th>İşlem</th></tr></thead>
          <tbody>${playerRows || '<tr><td colspan="8" class="muted">Oyuncu yok</td></tr>'}</tbody>
        </table>
      </div>
    </section>

    <section>
      <h2>Kullanıcı adları</h2>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Username</th><th>UID</th><th>Görünen ad</th><th>İşlem</th></tr></thead>
          <tbody>${usernameRows || '<tr><td colspan="4" class="muted">Kayıt yok</td></tr>'}</tbody>
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
      <div class="section-head">
        <h2>Raporlar (${reports.length})</h2>
        ${
          reports.length
            ? actionBtn('clear_reports', {}, 'Tümünü sil', 'btn-muted')
            : ''
        }
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Raporlayan</th><th>Şikâyet edilen</th><th>Sebep</th><th>Oda</th><th>Tarih</th><th>İşlem</th></tr></thead>
          <tbody>${reportRows}</tbody>
        </table>
      </div>
    </section>
  </main>
</body>
</html>`;
}

function handleAdmin(req, res, url, ctx) {
  const isAdminPath =
    url.pathname === '/admin' ||
    url.pathname === '/admin/action' ||
    url.pathname === '/admin/api/stats';

  if (!isAdminPath) return false;

  const auth = checkAdminAuth(req);
  if (!auth.ok) {
    sendUnauthorized(res, auth.configured);
    return true;
  }

  if (url.pathname === '/admin/api/stats') {
    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(JSON.stringify(collectAdminData(ctx).stats));
    return true;
  }

  if (url.pathname === '/admin/action' && req.method === 'POST') {
    readFormBody(req)
      .then((params) => {
        const result = runAdminAction(ctx, params.action, params);
        const q = result.ok
          ? `?ok=${encodeURIComponent(result.message || 'Tamam')}`
          : `?err=${encodeURIComponent(result.error || 'Hata')}`;
        res.writeHead(303, { Location: `/admin${q}` });
        res.end();
      })
      .catch(() => {
        res.writeHead(303, { Location: '/admin?err=Geçersiz+istek' });
        res.end();
      });
    return true;
  }

  if (url.pathname === '/admin' && req.method === 'GET') {
    const flash = url.searchParams.has('ok')
      ? { ok: true, message: url.searchParams.get('ok') }
      : url.searchParams.has('err')
        ? { ok: false, message: url.searchParams.get('err') }
        : null;

    const html = renderAdminHtml(collectAdminData(ctx), flash);
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
    res.end(html);
    return true;
  }

  res.writeHead(404);
  res.end('Not found');
  return true;
}

module.exports = { handleAdmin };
