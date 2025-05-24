const express = require('express');
const db = require('./db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/ping', (req, res) => {
  res.send('pong!');
});

app.get('/dbcheck', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT NOW() as time');
    res.json({ db_time: rows[0].time });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
