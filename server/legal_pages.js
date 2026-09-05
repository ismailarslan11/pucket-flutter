const SUPPORT = 'yesaworks@gmail.com';
const UPDATED = '22 Temmuz 2026';

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
    <p>PUCKET ("uygulama"), bir disk fırlatma oyunudur. Süreli mod ve kariyer modunda rakip yapay zekâdır; hesap, ilerleme ve sıralama için sunucu kullanılır. Bu politika hangi verileri topladığımızı ve nasıl kullandığımızı açıklar.</p>

    <h2>Toplanan veriler</h2>
    <ul>
      <li><strong>Hesap:</strong> Google / Apple ile giriş yaparsanız Firebase Auth kimliği; misafir modda yerel anonim kimlik.</li>
      <li><strong>Oyun:</strong> Kullanıcı adı, ELO puanı, lig, maç sonuçları, oda kodları.</li>
      <li><strong>Cihaz:</strong> FCM push token (bildirimler için), reklam tanımlayıcıları (AdMob).</li>
      <li><strong>Log:</strong> Sunucu hata ve bağlantı kayıtları (IP adresi kısa süreli).</li>
    </ul>

    <h2>Verilerin kullanımı</h2>
    <ul>
      <li>Hesap ve ilerleme kaydı</li>
      <li>İlerleme ve sıralama tablosu</li>
      <li>Push bildirimleri (izin verirseniz)</li>
      <li>Reklam gösterimi (Google AdMob)</li>
    </ul>

    <h2>Üçüncü taraflar</h2>
    <ul>
      <li>Google Firebase (kimlik doğrulama, bildirimler)</li>
      <li>Google AdMob (reklamlar)</li>
      <li>Oyun sunucusu (Türkiye'de barındırılan özel sunucu)</li>
    </ul>

    <h2>Reklamlar ve AB kullanıcıları</h2>
    <p>Avrupa Ekonomik Alanı'ndaki kullanıcılara Google UMP üzerinden rıza formu gösterilebilir. Reklam tercihlerinizi uygulama ayarlarından değiştirebilirsiniz.</p>

    <h2>Veri saklama ve hesap silme</h2>
    <p>Oyun verileri hesabınız aktif olduğu sürece sunucuda saklanır. Hesabınızı ve tüm verilerinizi
    uygulama içinden (Ayarlar → Hesabı Sil) veya <a href="/account-deletion">hesap silme sayfasından</a> silebilirsiniz.</p>

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
      <li>Süreli mod, kariyer ve bilgisayara karşı modlarında rakip yapay zekâdır; gerçek oyuncularla eşleştirme yapılmaz.</li>
      <li>Yapay zekâ maçları ELO'yu ve sıralama tablosunu etkilemez.</li>
      
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

/// Google Play "hesap silme" gereksinimi: mağaza formuna verilecek web sayfası.
function accountDeletionHtml() {
  return page('Hesap Silme', `
    <p><strong>PUCKET</strong> hesabınızı ve tüm verilerinizi kalıcı olarak silmek için iki yol vardır:</p>

    <h2>1) Uygulama içinden (önerilen, anında)</h2>
    <ul>
      <li>PUCKET'i açın</li>
      <li><strong>Ayarlar</strong> ekranına gidin</li>
      <li>En alttaki <strong>"Hesabı Sil"</strong> düğmesine basın ve onaylayın</li>
    </ul>
    <p>Bu işlem anında gerçekleşir ve geri alınamaz.</p>

    <h2>2) E-posta ile talep</h2>
    <p><a href="mailto:${SUPPORT}?subject=Hesap%20Silme%20Talebi">${SUPPORT}</a> adresine
    uygulama içindeki kullanıcı adınızla birlikte "Hesap silme talebi" yazın.
    Talebiniz en geç 7 gün içinde işleme alınır.</p>

    <h2>Silinen veriler</h2>
    <ul>
      <li>Hesap kimliği ve kullanıcı adı</li>
      <li>ELO, lig, maç geçmişi, sezon ilerlemesi</li>
      <li>Jetonlar ve kozmetikler</li>
      <li>Arkadaş listesi ve bildirim kaydı (push token)</li>
    </ul>
    <p>Sunucu yedeklerindeki kopyalar en geç 30 gün içinde temizlenir.
    Yasal zorunluluk gerektiren kayıtlar (ör. ödeme itirazları) yasal süre boyunca tutulabilir.</p>
  `);
}

module.exports = { privacyHtml, termsHtml, accountDeletionHtml };
