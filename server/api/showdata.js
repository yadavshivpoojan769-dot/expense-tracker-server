import express from 'express';
import multer from 'multer';
import path from 'path';
import exeCommand from '../config/cmdExecution.js';

const router = express.Router();

/* ===============================
   GET USER INFO
================================ */
router.post('/userInfo', async (req, res) => {
    try {
        const { email } = req.body;

        const result = await exeCommand({
            sql: `SELECT * FROM userdata WHERE email = ? LIMIT 1`,
            values: [email]
        });

        res.json(result);

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch user info" });
    }
});


/* ===============================
   ALL USER DETAILS
================================ */
router.post('/userDetails', async (req, res) => {
    try {
        const { userId } = req.body;

        const result = await exeCommand({
            sql: `SELECT * FROM user_details WHERE userId = ? ORDER BY TIMEDATE DESC`,
            values: [userId]
        });

        res.json(result);

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch details" });
    }
});


/* ===============================
   LIMITED USER DETAILS
================================ */
router.post('/limiteduserDetails', async (req, res) => {
    try {
        const { userId } = req.body;

        const result = await exeCommand({
            sql: `SELECT * FROM user_details WHERE userId = ? ORDER BY TIMEDATE DESC LIMIT 3`,
            values: [userId]
        });

        res.json(result);

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch limited details" });
    }
});


/* ===============================
   UPDATE PROFILE
================================ */

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const upload = multer({ storage });

router.post('/profile/update', upload.single('file'), async (req, res) => {
    try {
        const { name, phone, email } = req.body;
        const imagePath = req.file
            ? path.posix.join('uploads', req.file.filename)
            : null;

        let sql = `UPDATE userdata SET name = ?, phone = ?`;
        const values = [name, phone];

        if (imagePath) {
            sql += `, image = ?`;
            values.push(imagePath);
        }

        sql += ` WHERE email = ?`;
        values.push(email);

        await exeCommand({ sql, values });

        res.json({
            status: 'success',
            image: imagePath
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ status: 'error' });
    }
});


/* ===============================
   BUDGET TRANSACTION
================================ */
router.post('/budgetTransaction', async (req, res) => {
    try {
        const { uid } = req.body;

        const result = await exeCommand({
            sql: `SELECT * FROM budget WHERE uid = ? ORDER BY TIMEDATE DESC`,
            values: [uid]
        });

        res.json(result);

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch budget transactions" });
    }
});


/* ===============================
   DELETE BUDGET
================================ */
router.post('/deletebudgetTransaction', async (req, res) => {
    try {
        const { id } = req.body;

        const result = await exeCommand({
            sql: `DELETE FROM budget WHERE id = ?`,
            values: [id]
        });

        res.json({ success: true, result });

    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false });
    }
});


/* ===============================
   DELETE MULTIPLE USER TRANSACTIONS
================================ */
router.post('/deleteUserTransaction', async (req, res) => {
    try {
        const { transactionIds } = req.body;

        if (!Array.isArray(transactionIds) || transactionIds.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'transactionIds must be non-empty array'
            });
        }

        const placeholders = transactionIds.map(() => '?').join(',');

        const result = await exeCommand({
            sql: `DELETE FROM user_details WHERE id IN (${placeholders})`,
            values: transactionIds
        });

        res.json({
            success: true,
            deletedCount: result.affectedRows
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false });
    }
});


export default router;
