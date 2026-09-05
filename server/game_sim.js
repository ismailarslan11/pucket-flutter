'use strict';
// Sunucu-otoriteli fizik + oyun simülasyonu.
// lib/game/physics_engine.dart + game_constants.dart'ın BİREBİR portu.
// Amaç: fizik zaman çizgisini kararlı bir sunucuda üretmek, böylece rakip
// pulları her istemcide profesyonel seviyede akıcı görünür (host telefonun
// düzensiz kare temposu artık yok).

const C = {
  vw: 400,
  vh: 700,
  vHalf: 350,
  gapW: 72,
  gapX: (400 - 72) / 2, // 164
  wallHalfH: 8,
  gapY: 350 - 8, // 342
  gapH: 16,
  wallTop: 350 - 8, // 342
  wallBottom: 350 + 8, // 358
  discRadius: 22,
  friction: 0.983,
  restitution: 0.68,
  slingMax: 88,
  slingPower: 0.21,
  discsPerPlayer: 5,
  solverPasses: 2,
};

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

const STANDARD_RED = [
  [0.2, 0.62], [0.8, 0.62], [0.5, 0.70], [0.28, 0.82], [0.72, 0.82],
];
const STANDARD_BLUE = [
  [0.2, 0.38], [0.8, 0.38], [0.5, 0.30], [0.28, 0.18], [0.72, 0.18],
];

function buildFromPositions(red, blue) {
  const m = C.discRadius + 8;
  const discs = [];
  for (const p of red) {
    discs.push({
      vx: clamp(C.vw * p[0], m, C.vw - m),
      vy: clamp(C.vh * p[1], C.vHalf + m, C.vh - m),
      vvx: 0, vvy: 0, owner: 0,
    });
  }
  for (const p of blue) {
    discs.push({
      vx: clamp(C.vw * p[0], m, C.vw - m),
      vy: clamp(C.vh * p[1], m, C.vHalf - m),
      vvx: 0, vvy: 0, owner: 1,
    });
  }
  return discs;
}

function initDiscs() {
  return buildFromPositions(STANDARD_RED, STANDARD_BLUE);
}

function stepPhysics(discs) {
  const dr = C.discRadius;
  for (const d of discs) {
    d.vx += d.vvx;
    d.vy += d.vvy;
    d.vvx *= C.friction;
    d.vvy *= C.friction;
    if (Math.abs(d.vvx) < 0.03) d.vvx = 0;
    if (Math.abs(d.vvy) < 0.03) d.vvy = 0;
  }
  for (let pass = 0; pass < C.solverPasses; pass++) {
    for (let i = 0; i < discs.length; i++) {
      for (let j = i + 1; j < discs.length; j++) {
        resolveDiscPair(discs[i], discs[j], dr);
      }
    }
    for (const d of discs) {
      resolveMidWall(d, dr);
      resolveOuterBounds(d, dr);
    }
  }
}

function resolveOuterBounds(d, dr) {
  if (d.vx < dr) { d.vx = dr; d.vvx = Math.abs(d.vvx) * C.restitution; }
  if (d.vx > C.vw - dr) { d.vx = C.vw - dr; d.vvx = -Math.abs(d.vvx) * C.restitution; }
  if (d.vy < dr) { d.vy = dr; d.vvy = Math.abs(d.vvy) * C.restitution; }
  if (d.vy > C.vh - dr) { d.vy = C.vh - dr; d.vvy = -Math.abs(d.vvy) * C.restitution; }
}

function resolveMidWall(d, dr) {
  resolveCircleWallBar(d, dr, 0, C.wallTop, C.gapX, C.wallBottom, true);
  resolveCircleWallBar(d, dr, C.gapX + C.gapW, C.wallTop, C.vw, C.wallBottom, false);
}

function resolveCircleWallBar(d, r, left, top, right, bottom, pushRight) {
  if (d.vy + r <= top || d.vy - r >= bottom) return;
  const closestX = clamp(d.vx, left, right);
  const closestY = clamp(d.vy, top, bottom);
  const dx = d.vx - closestX;
  const dy = d.vy - closestY;
  const distSq = dx * dx + dy * dy;
  const rSq = r * r;
  if (distSq >= rSq) return;

  let nx, ny, penetration;
  if (distSq < 1e-8) {
    nx = pushRight ? 1 : -1;
    ny = 0;
    penetration = pushRight ? (left + (right - left) + r - d.vx) : (d.vx - left + r);
    if (penetration < 0) penetration = r;
  } else {
    const dist = Math.sqrt(distSq);
    nx = dx / dist;
    ny = dy / dist;
    penetration = r - dist;
    if (pushRight && nx < 0) { nx = 1; ny = 0; }
    else if (!pushRight && nx > 0) { nx = -1; ny = 0; }
  }

  d.vx += nx * penetration;
  d.vy += ny * penetration;

  const vDot = d.vvx * nx + d.vvy * ny;
  if (vDot < 0) {
    const bounce = (1 + C.restitution) * vDot;
    d.vvx -= bounce * nx;
    d.vvy -= bounce * ny;
  }
}

function resolveDiscPair(a, b, dr) {
  let dx = b.vx - a.vx;
  let dy = b.vy - a.vy;
  const minDist = dr * 2;
  const distSq = dx * dx + dy * dy;
  if (distSq >= minDist * minDist) return;
  let dist = Math.sqrt(distSq);
  if (dist < 1e-6) { dx = 0; dy = 1; dist = 1; }
  const nx = dx / dist;
  const ny = dy / dist;
  const overlap = dr * 2 - dist;
  a.vx -= nx * overlap / 2;
  a.vy -= ny * overlap / 2;
  b.vx += nx * overlap / 2;
  b.vy += ny * overlap / 2;
  const dot = (b.vvx - a.vvx) * nx + (b.vvy - a.vvy) * ny;
  if (dot < 0) {
    a.vvx += dot * C.restitution * nx;
    a.vvy += dot * C.restitution * ny;
    b.vvx -= dot * C.restitution * nx;
    b.vvy -= dot * C.restitution * ny;
  }
}

function inGateZone(d) {
  const dr = C.discRadius;
  const inGapX = d.vx > C.gapX && d.vx < C.gapX + C.gapW;
  const inGapY = d.vy + dr > C.gapY && d.vy - dr < C.gapY + C.gapH;
  return inGapX && inGapY;
}

const isStopped = (d) => Math.abs(d.vvx) < 0.12 && Math.abs(d.vvy) < 0.12;
const allStopped = (discs) => discs.every(isStopped);

function occupiesTop(d) {
  const dr = C.discRadius;
  if (inGateZone(d)) return d.vy <= C.vHalf;
  return d.vy - dr < C.vHalf;
}
function occupiesBottom(d) {
  const dr = C.discRadius;
  if (inGateZone(d)) return d.vy > C.vHalf;
  return d.vy + dr > C.vHalf;
}

function countMoving(discs, threshold = 0.05) {
  let n = 0;
  for (const d of discs) {
    if (Math.abs(d.vvx) > threshold || Math.abs(d.vvy) > threshold) n++;
  }
  return n;
}

function settleGateDiscs(discs) {
  if (!allStopped(discs)) return;
  const dr = C.discRadius;
  const minSep = dr * 2 + 1;
  for (let pass = 0; pass < 4; pass++) {
    for (let i = 0; i < discs.length; i++) {
      for (let j = i + 1; j < discs.length; j++) {
        resolveDiscPair(discs[i], discs[j], dr);
      }
    }
    for (const d of discs) resolveMidWall(d, dr);
  }
  const gateDiscs = discs.filter(inGateZone).sort((a, b) => a.vy - b.vy);
  for (let i = 1; i < gateDiscs.length; i++) {
    const prev = gateDiscs[i - 1];
    const cur = gateDiscs[i];
    if (cur.vy - prev.vy < minSep) cur.vy = prev.vy + minSep;
  }
  for (const d of gateDiscs) {
    const target = d.vy < C.vHalf ? C.vHalf - dr - 2 : C.vHalf + dr + 2;
    d.vy += clamp(target - d.vy, -4.0, 4.0);
    d.vvx = 0;
    d.vvy = 0;
    resolveMidWall(d, dr);
  }
}

function checkWinner(discs) {
  if (discs.length < C.discsPerPlayer * 2) return null;
  const topEmpty = !discs.some(occupiesTop);
  const bottomEmpty = !discs.some(occupiesBottom);
  if (bottomEmpty) return 0;
  if (topEmpty) return 1;
  return null;
}

module.exports = {
  C, clamp, initDiscs, stepPhysics, settleGateDiscs, checkWinner,
  countMoving, allStopped, occupiesTop, occupiesBottom,
};
