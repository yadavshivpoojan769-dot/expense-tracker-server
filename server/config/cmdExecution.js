import pool from './db.js';

const exeCommand = async ({ sql, values = [] }) => {
  try {
    const [result] = await pool.query(sql, values);
    return result;
  } catch (err) {
    throw err;
  }
};

export default exeCommand;
