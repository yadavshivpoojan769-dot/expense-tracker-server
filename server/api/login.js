import bcrypt from 'bcrypt';
import express from 'express';
import exeCommand from '../config/cmdExecution.js';
const router = express.Router();

router.post('/loginUser', async (req, res) => {
    const email = req.body.email;
    const password = req.body.password;

const query = `SELECT * FROM userdata WHERE email = ?`;

try {
  const result = await exeCommand({ sql: query, values: [email] });

  if (result.length === 0) {
    return res.json({ error: "User not found" });
  }

  const user = result[0];

console.log('Entered password:', password);
console.log('Stored hash:', user.password);


  const isMatch = await bcrypt.compare(password, user.password);

  if (isMatch) {
    res.json({ msg: "success", data: user });
  } else {
    res.json({ msg: "error", error: "Incorrect password" });
  }

} catch (err) {
  console.error('Login error:', err);
  res.status(500).json({ msg: "error", error: "Server error" });
}

});

export default router;
