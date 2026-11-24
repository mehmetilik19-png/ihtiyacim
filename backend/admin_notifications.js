const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function sendPendingAdminNotifications() {
  console.log("Admin bildirim kontrolü başladı...");

  const snap = await db
    .collection("admin_ads")
    .where("active", "==", true)
    .where("sendNotification", "==", true)
    .where("notificationSent", "==", false)
    .get();

  if (snap.empty) {
    console.log("Gönderilecek bildirim yok.");
    return;
  }

  const usersSnap = await db.collection("users").get();

  const tokens = [];

  usersSnap.forEach((doc) => {
    const data = doc.data();

    if (
      data.fcmToken &&
      data.notificationsEnabled !== false
    ) {
      tokens.push(data.fcmToken);
    }
  });

  if (tokens.length === 0) {
    console.log("Kayıtlı FCM token yok.");
    return;
  }

  for (const adDoc of snap.docs) {
    const ad = adDoc.data();

    const title = ad.title || "İhtiyacım";
    const body = ad.desc || "Yeni duyuru var";

    console.log(`Bildirim gönderiliyor: ${title}`);

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: String(ad.type || "duyuru"),
        adId: adDoc.id,
        display: String(ad.display || ""),
        actionType: String(ad.actionType || "none"),
        pageTarget: String(ad.pageTarget || ""),
        targetValue: String(ad.targetValue || ""),
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    console.log("Başarılı:", response.successCount);
    console.log("Başarısız:", response.failureCount);

    await adDoc.ref.update({
      notificationSent: true,
      notificationSentAt: Date.now(),
      notificationSuccessCount: response.successCount,
      notificationFailureCount: response.failureCount,
    });
  }

  console.log("Admin bildirim kontrolü bitti.");
}

sendPendingAdminNotifications()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("HATA:", error);
    process.exit(1);
  });