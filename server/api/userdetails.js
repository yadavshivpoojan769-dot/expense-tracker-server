import express from 'express';
import exeCommand from '../config/cmdExecution.js';

const router = express.Router();

/* ===============================
   INSERT USER TRANSACTION DETAILS
================================ */
router.post('/insert', async (req, res) => {
    try {
        let {
            income,
            from_user,
            userId,
            expence,
            to_user,
            letest_income,
            letest_expence
        } = req.body;

        console.log("Received data:", req.body);

        // 🔥 Numeric sanitization (critical fix)
        income = Number(income) || 0;
        expence = Number(expence) || 0;
        letest_income = Number(letest_income) || 0;
        letest_expence = Number(letest_expence) || 0;
        userId = Number(userId);

        if (!userId) {
            return res.status(400).json({ error: "Invalid userId" });
        }

        const query = `
            INSERT INTO user_details
            (income, from_user, userId, expence, to_user, letest_income, letest_expence, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        `;

        await exeCommand({
            sql: query,
            values: [
                income,
                from_user || '',
                userId,
                expence,
                to_user || '',
                letest_income,
                letest_expence
            ]
        });

        res.json({ success: true });

    } catch (error) {
        console.error("Insert error:", error);
        res.status(500).json({ error: "Insert failed" });
    }
});


/* ===============================
   INSERT BUDGET
================================ */
router.post('/budget/insert', async (req, res) => {
    try {
        let { title, amount, date, uid, transactionDetails } = req.body;

        amount = Number(amount) || 0;
        uid = Number(uid);

        if (!uid) {
            return res.status(400).json({ error: "Invalid uid" });
        }

        const query = `
            INSERT INTO budget
            (title, amount, date, uid, transactionDetails, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, NOW())
        `;

        await exeCommand({
            sql: query,
            values: [
                title || '',
                amount,
                date || null,
                uid,
                JSON.stringify(transactionDetails || [])
            ]
        });

        res.json({ success: true });

    } catch (error) {
        console.error("Budget insert error:", error);
        res.status(500).json({ error: "Insert failed" });
    }
});


/* ===============================
   INSERT PRODUCTS
================================ */
router.post('/products/insert', async (req, res) => {
    try {
        let { title, uid, productName } = req.body;

        uid = Number(uid);

        if (!uid) {
            return res.status(400).json({ error: "Invalid uid" });
        }

        const query = `
            INSERT INTO products
            (title, uid, productName, TIMEDATE)
            VALUES (?, ?, ?, NOW())
        `;

        await exeCommand({
            sql: query,
            values: [
                title || '',
                uid,
                JSON.stringify(productName || [])
            ]
        });

        res.json({ success: true });

    } catch (error) {
        console.error("Product insert error:", error);
        res.status(500).json({ error: "Insert failed" });
    }
});


/* ===============================
   ADD PRODUCTS
================================ */
router.post('/products/add', async (req, res) => {
    try {
        const { id, newProducts } = req.body;

        if (!id || !Array.isArray(newProducts)) {
            return res.status(400).json({ error: "Invalid input" });
        }

        const result = await exeCommand({
            sql: `SELECT productName FROM products WHERE id = ?`,
            values: [id]
        });

        if (result.length === 0) {
            return res.status(404).json({ error: "Product list not found" });
        }

        let existingProducts =
            typeof result[0].productName === "string"
                ? JSON.parse(result[0].productName || "[]")
                : result[0].productName || [];

        const updatedProducts = [
            ...existingProducts,
            ...newProducts.map(p => ({ productName: p }))
        ];

        await exeCommand({
            sql: `UPDATE products SET productName = ? WHERE id = ?`,
            values: [JSON.stringify(updatedProducts), id]
        });

        res.json({ success: true });

    } catch (error) {
        console.error("Add product error:", error);
        res.status(500).json({ error: "Failed to add products" });
    }
});


/* ===============================
   UPDATE PRODUCTS
================================ */
router.post('/products/update', async (req, res) => {
    try {
        const { id, updatedProducts } = req.body;

        if (!id || !Array.isArray(updatedProducts)) {
            return res.status(400).json({ error: "Invalid input" });
        }

        const result = await exeCommand({
            sql: `UPDATE products SET productName = ? WHERE id = ?`,
            values: [JSON.stringify(updatedProducts), id]
        });

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "No products found" });
        }

        res.json({ success: true });

    } catch (error) {
        console.error("Update error:", error);
        res.status(500).json({ error: "Failed to update" });
    }
});


/* ===============================
   DELETE PRODUCTS
================================ */
router.post('/products/delete', async (req, res) => {
    try {
        const { id, remainingProducts } = req.body;

        if (!id || !Array.isArray(remainingProducts)) {
            return res.status(400).json({ error: "Invalid input" });
        }

        const result = await exeCommand({
            sql: `UPDATE products SET productName = ? WHERE id = ?`,
            values: [JSON.stringify(remainingProducts), id]
        });

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "No products found" });
        }

        res.json({ success: true });

    } catch (error) {
        console.error("Delete error:", error);
        res.status(500).json({ error: "Failed to delete" });
    }
});

export default router;
