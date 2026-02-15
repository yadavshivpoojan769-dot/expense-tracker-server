import bcrypt from 'bcrypt';
import express from 'express';
import multer from 'multer';
import exeCommand from '../config/cmdExecution.js';

const router = express.Router();

// Multer storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({ storage });

// 🔹 INSERT USER
router.post('/signupuser/insert', upload.single('file'), async (req, res) => {
    console.log("hit from Flutter");

    const { name, email, phone, password } = req.body;
    const imagePath = req.file ? req.file.path : null;

    try {
        const hashedPassword = await bcrypt.hash(password, 10);

        const query = `
            INSERT INTO userdata (name, email, phone, password, image, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, NOW())
        `;

        await exeCommand({
            sql: query,
            values: [name, email, phone, hashedPassword, imagePath]
        });

        res.json("success");

    } catch (err) {
        console.error("Insert error:", err);
        res.status(500).json({ error: "Insert failed" });
    }
});


// 🔹 CHECK EMAIL EXISTS
router.post('/signupuser', async (req, res) => {
    const { email } = req.body;

    try {
        const result = await exeCommand({
            sql: 'SELECT COUNT(*) as email_count FROM userdata WHERE email = ?',
            values: [email]
        });

        const emailExists = result[0].email_count > 0;

        res.json({ email_exists: emailExists });

    } catch (err) {
        console.error("Email check error:", err);
        res.status(500).json({ error: "Database query failed" });
    }
});


// 🔹 INSERT SHOPKEEPER
router.post('/shopkeeper/insert', upload.single('file'), async (req, res) => {
    console.log("get from Flutter");

    const { shopname, email, phone, shoptype, uid, address } = req.body;
    const imagePath = req.file ? req.file.path : null;

    try {
        const query = `
            INSERT INTO shopkeeper (shopname, email, phone, shoptype, uid, address, image, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        `;

        await exeCommand({
            sql: query,
            values: [shopname, email, phone, shoptype, uid, address, imagePath]
        });

        res.json("success");

    } catch (err) {
        console.error("Shopkeeper insert error:", err);
        res.status(500).json({ error: "Insert failed" });
    }
});

export default router;
