const SUPPORT = 'support@pucket.app';
const UPDATED = '30 Haziran 2026';

function page(title, body) {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${title} — PUCKET</title>
  <style>
    body{font-family:system-ui,-apple-system,sans-serif;background:#0d0d12;color:#ddd;line-height:1.65;max-width:720px;margin:0 auto;padding:24px 20px 48px}
    h1{color:#a855f7;font-size:1.5rem;margin-bottom:4px}
    h2{color:#38bdf8;font-size:1.05rem;margin-top:28px}
    p,li{color:#bbb;font-size:0.95rem}
    a{color:#38bdf8}
    .meta{color:#666;font-size:0.85rem;margin-bottom:24px}
  </style>
</head>
<body>
  <h1>${title}</h1>
  <p class="meta">PUCKET · Son güncelleme: ${UPDATED}</p>
  ${body}
  <p style="margin-top:32px;color:#666;font-size:0.85rem">İletişim: <a href="mailto:${SUPPORT}">${SUPPORT}</a></p>
</body>
</html>`;
}

function privacyHtml() {
  return page('Gizlilik Politikası', `
    <p>PUCKET ("uygulama"), çevrimiçi disk fırlatma oyunudur. Bu politika hangi verileri topladığımızı ve nasıl kullandığımızı açıklar.</p>

    <h2>Toplanan veriler</h2>
    <ul>
      <li><strong>Hesap:</strong> Google / Apple ile giriş yaparsanız Firebase Auth kimliği; misafir modda yerel anonim kimlik.</li>
      <li><strong>Oyun:</strong> Kullanıcı adı, ELO puanı, lig, maç sonuçları, oda kodları.</li>
      <li><strong>Cihaz:</strong> FCM push token (bildirimler için), reklam tanımlayıcıları (AdMob).</li>
      <li><strong>Log:</strong> Sunucu hata ve bağlantı kayıtları (IP adresi kısa süreli).</li>
    </ul>

    <h2>Verilerin kullanımı</h2>
    <ul>
      <li>Online eşleşme ve ranked maçlar</li>
      <li>İlerleme ve sıralama tablosu</li>
      <li>Push bildirimleri (izin verirseniz)</li>
      <li>Reklam gösterimi (Google AdMob)</li>
    </ul>

    <h2>Üçüncü taraflar</h2>
    <ul>
      <li>Google Firebase (kimlik doğrulama, bildirimler)</li>
      <li>Google AdMob (reklamlar)</li>
      <li>Render.com (oyun sunucusu barındırma)</li>
    </ul>

    <h2>Reklamlar ve AB kullanıcıları</h2>
    <p>Avrupa Ekonomik Alanı'ndaki kullanıcılara Google UMP üzerinden rıza formu gösterilebilir. Reklam tercihlerinizi uygulama ayarlarından değiştirebilirsiniz.</p>

    <h2>Veri saklama</h2>
    <p>Oyun verileri hesabınız aktif olduğu sürece sunucuda saklanır. Hesap silme talebi için bize yazın.</p>

    <h2>Çocuklar</h2>
    <p>Uygulama 13 yaş ve üzeri içindir. Bilerek 13 yaş altından veri toplamıyoruz.</p>

    <h2>Değişiklikler</h2>
    <p>Bu sayfa güncellenebilir. Önemli değişiklikler uygulama içinde duyurulur.</p>
  `);
}

function termsHtml() {
  return page('Kullanım Koşulları', `
    <p>PUCKET'i indirerek veya kullanarak bu koşulları kabul etmiş olursunuz.</p>

    <h2>Hizmet</h2>
    <p>Oyun "olduğu gibi" sunulur. Sunucu bakımı, gecikme veya kesinti olabilir.</p>

    <h2>Hesap ve davranış</h2>
    <ul>
      <li>Hile, ELO manipülasyonu, bot kullanımı ve taciz yasaktır.</li>
      <li>Ranked maçlar sunucu kayıtlarına dayanır.</li>
      <li>Hesabınız ihlal durumunda askıya alınabilir.</li>
    </ul>

    <h2>Yaş</h2>
    <p>13 yaş ve üzeri kullanıcılar içindir.</p>

    <h2>Fikri mülkiyet</h2>
    <p>PUCKET adı, görselleri ve oyun tasarımı geliştiriciye aittir.</p>

    <h2>Reklamlar</h2>
    <p>Uygulama ücretsizdir ve reklam içerebilir. Üçüncü taraf reklam içeriklerinden sorumlu değiliz.</p>

    <h2>Sorumluluk sınırı</h2>
    <p>Yasaların izin verdiği ölçüde dolaylı zararlardan sorumlu değiliz.</p>
  `);
}

module.exports = { privacyHtml, termsHtml };
