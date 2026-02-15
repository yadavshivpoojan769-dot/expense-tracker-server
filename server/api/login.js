import bcrypt from 'bcrypt';
import express from 'express';
import exeCommand from '../config/cmdExecution.js';

const router = express.Router();

router.post('/loginUser', async (req, res) => {
    const { email, password } = req.body;

    try {
        const result = await exeCommand({
            sql: 'SELECT * FROM userdata WHERE email = ?',
            values: [email]
        });

        if (result.length === 0) {
            return res.json({ msg: "error", error: "User not found" });
        }

        const user = result[0];

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.json({ msg: "error", error: "Incorrect password" });
        }

        res.json({ msg: "success", data: user });

    } catch (err) {
        console.error("Login error:", err);
        res.status(500).json({ msg: "error", error: "Server error" });
    }
});

export default router;
