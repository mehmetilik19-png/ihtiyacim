const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors({ origin: true }));
app.use(express.json({ limit: "10mb" }));

const BACKEND_VERSION = "tarzim-backend-v3";

app.get("/", (req, res) => {
  return res.json({ ok: true, service: "tarzim", version: BACKEND_VERSION });
});

app.get("/version", (req, res) => {
  return res.json({ ok: true, version: BACKEND_VERSION });
});

app.post("/tarzimaicomment", async (req, res) => {
  const requestId = Math.random().toString(16).slice(2);

  try {
    const body = req.body || {};
    const prompt = (body.prompt || "").toString();
    const type = (body.type || "genel").toString();
    const imageUrl = (body.imageUrl || "").toString();
    const options = body.options || {};

    if (!prompt) {
      return res.status(400).json({ ok: false, error: "prompt zorunlu", requestId });
    }
    if (!imageUrl) {
      return res.status(400).json({ ok: false, error: "imageUrl zorunlu", requestId });
    }

    // ✅ Firebase Functions v2: secret env'den okunur
    const openaiKey = process.env.OPENAI_API_KEY;

    if (!openaiKey) {
      return res.status(500).json({
        ok: false,
        error: "OPENAI_API_KEY tanımlı değil (firebase functions:secrets:set OPENAI_API_KEY)",
        requestId,
      });
    }

    const system =
      "Gönderilen görsele gerçekten bak. Görselde ne olduğunu kısaca tarif et (1-2 cümle). " +
      "Sonra kullanıcı isteğine göre öneri ver. Uydurma yapma. Eğer görsel yoksa 'görseli göremedim' de.";

    const userText =
      `Kategori: ${type}\n` +
      `Kullanıcı notu: ${prompt}\n` +
      `Modlar: friendMode=${!!options.friendMode}, addDipNote=${!!options.addDipNote}, edit=${!!options.edit}`;

    const openaiResp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${openaiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        temperature: 0.7,
        messages: [
          { role: "system", content: system },
          {
            role: "user",
            content: [
              { type: "text", text: userText },
              { type: "image_url", image_url: { url: imageUrl } },
            ],
          },
        ],
      }),
    });

    const openaiJson = await openaiResp.json();

    if (!openaiResp.ok) {
      logger.error("OpenAI error", { requestId, status: openaiResp.status, openaiJson });
      return res.status(500).json({
        ok: false,
        error: "OpenAI çağrısı başarısız",
        detail: openaiJson,
        requestId,
      });
    }

    const text = openaiJson.choices?.[0]?.message?.content || "Yorum üretilemedi";

    return res.json({
      ok: true,
      version: BACKEND_VERSION,
      requestId,
      imageUrl,
      editedImageUrl: imageUrl,
      comment: text,
      suggestion: "Görsele göre küçük ama etkili bir düzenleme denenebilir.",
      debug: {
        model: "gpt-4o-mini",
        gotImageUrl: imageUrl.slice(0, 40) + "...",
      },
    });
  } catch (e) {
    logger.error("Server error", e);
    return res.status(500).json({ ok: false, error: e.message || "Sunucu hatası" });
  }
});

// ✅ Secret'ı burada bağlıyoruz (çok önemli)
exports.tarzimaicomment = onRequest(
  {
    region: "us-central1",
    secrets: ["OPENAI_API_KEY"],
  },
  app
);