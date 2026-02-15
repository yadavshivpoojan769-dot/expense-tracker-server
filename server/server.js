import express from "express";
import http from "http";
import pool from "./config/db.js";
import app from "./route.js";

// Static folder
app.use('/uploads', express.static('uploads'));

// 🔥 Auto create tables on startup
async function createTables() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS userdata (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        email VARCHAR(150) UNIQUE,
        phone VARCHAR(100),
        password VARCHAR(300),
        image VARCHAR(250),
        TIMEDATE DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await pool.query(`
      CREATE TABLE IF NOT EXISTS userdetails (
        id INT AUTO_INCREMENT PRIMARY KEY,
        userId INT,
        income INT DEFAULT 0,
        expence INT DEFAULT 0,
        from_user VARCHAR(255),
        to_user VARCHAR(255),
        letest_income INT,
        letest_expence INT,
        TIMEDATE DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log("✅ Tables checked/created successfully");
  } catch (err) {
    console.error("❌ Table creation error:", err);
  }
}


// Create tables before server starts
await createTables();

const server = http.createServer(app);

const PORT = process.env.PORT || 55000;

server.listen(PORT, () => {
  console.log("🚀 Server is listening on", PORT);
});
