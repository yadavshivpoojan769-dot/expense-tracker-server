import dotenv from "dotenv";
import mysql from "mysql2/promise";
dotenv.config();


dotenv.config();

const isProduction = process.env.DB_HOST && process.env.DB_HOST !== "localhost";

const mysqlSetting = {
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "expense_tracker",
  port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 3306,

  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true,

  ...(isProduction && {
    ssl: { rejectUnauthorized: false },
  }),
};

const pool = mysql.createPool(mysqlSetting);

(async () => {
  try {
    const connection = await pool.getConnection();
    console.log("✅ Database connected successfully");
    connection.release();
  } catch (err) {
    console.error("❌ Database connection failed:", err.message);
  }
})();

export default pool;
