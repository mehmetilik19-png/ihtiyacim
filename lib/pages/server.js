const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("OK");
});

app.get("/create-payment", (req, res) => {
  res.send("GET OK");
});

app.post("/create-payment", (req, res) => {
  res.json({ paymentUrl: "https://www.shopier.com/s/456885619" });
});

app.listen(3000, "0.0.0.0", () => {
  console.log("LISTENING 0.0.0.0:3000");
});