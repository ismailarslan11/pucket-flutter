const GUEST_RANKED = process.env.GUEST_RANKED === 'true';

let verifyIdTokenFn = null;

async function initFirebaseAuth() {
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) return;
  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(json)),
      });
    }
    verifyIdTokenFn = (token) => admin.auth().verifyIdToken(token);
    console.log('Firebase ID token verification enabled');
  } catch (e) {
    console.warn('Firebase Auth init skipped:', e.message);
  }
}

function isGuestUid(uid) {
  if (!uid) return true;
  return uid.startsWith('guest_') || uid.startsWith('u_');
}

async function resolveLoginIdentity(msg) {
  let uid = msg.uid || null;
  let isAnonymous = msg.isAnonymous === true;

  if (verifyIdTokenFn && msg.idToken) {
    try {
      const decoded = await verifyIdTokenFn(msg.idToken);
      uid = decoded.uid;
      isAnonymous = decoded.firebase?.sign_in_provider === 'anonymous';
      return { uid, isAnonymous, verified: true };
    } catch (e) {
      console.warn('ID token verify failed:', e.message);
    }
  }

  return { uid, isAnonymous, verified: false };
}

function canPlayRanked(ws, uid) {
  if (GUEST_RANKED) return true;
  if (isGuestUid(uid)) return false;
  if (ws.isAnonymous) return false;
  return true;
}

module.exports = {
  initFirebaseAuth,
  resolveLoginIdentity,
  canPlayRanked,
  isGuestUid,
};
