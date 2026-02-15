import mysql from "mysql2/promise";

const mysqlSetting = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: Number(process.env.DB_PORT),

  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true,

  // 🔥 Railway public MySQL के लिए जरूरी
  ssl: {
    rejectUnauthorized: false,
  },
};

const pool = mysql.createPool(mysqlSetting);

// Test connection on startup
(async () => {
  try {
    const connection = await pool.getConnection();
    console.log("✅ Database connected successfully");
    connection.release();
  } catch (err) {
    console.error("❌ Database connection failed:", err);
  }
})();

export default pool;
