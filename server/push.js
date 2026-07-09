// Hedefli FCM push gönderimi. firebase_auth.js ile aynı servis hesabını kullanır.
// FIREBASE_SERVICE_ACCOUNT_JSON ayarlı değilse tüm işlemler sessizce no-op olur.

let messagingFn = null;

function initPush() {
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) return;
  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(json)),
      });
    }
    messagingFn = () => admin.messaging();
    console.log('Push (FCM) enabled');
  } catch (e) {
    console.warn('Push init skipped:', e.message);
  }
}

async function sendPush(token, title, body, data = {}) {
  if (!messagingFn || !token) return false;
  try {
    await messagingFn().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      // Android: yüksek öncelik → Doze'da bile anlık teslimat.
      android: { priority: 'high', ttl: 0 },
      // iOS: apns-priority 10 = anlık (5 = kısılır). apns-push-type alert şart.
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: { aps: { sound: 'default' } },
      },
    });
    return true;
  } catch (e) {
    // Geçersiz/expired token — çağıran tarafça temizlenebilir.
    return false;
  }
}

module.exports = { initPush, sendPush, get enabled() { return !!messagingFn; } };
