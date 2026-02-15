import express from 'express';
import exeCommand from '../config/cmdExecution.js';
const router = express.Router();


//Insert User Details
router.post('/insert', async (req, res) => {
    const {income, from_user, userId, expence, to_user, letest_income, letest_expence } = req.body;

    console.log("Received data:", {income, from_user, userId, expence, to_user, letest_income, letest_expence});

    try {
        const query = `
            INSERT INTO user_details (income, from_user, userId, expence, to_user, letest_income, letest_expence, TIMEDATE) VALUES (?, ?, ?, ?, ?, ?, ?, now())
        `;
        exeCommand({
            sql: query,
            values: [income, from_user, userId, expence, to_user, letest_income, letest_expence]
        })  
            .then(() => res.json('success'))
            .catch(err => {
                console.error('Insert error:', err);
                res.status(500).json({ error: 'Insert failed' });
            });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Server error' });

    }
});

//Insert Budget
router.post('/budget/insert', async (req, res) => {
    const { title, amount, date, uid, transactionDetails } = req.body;

    const transactionJSON = JSON.stringify(transactionDetails || []);

    console.log("Received data:", { title, amount, date, uid, transactionDetails });

    try {
        const query = `
            INSERT INTO budget (title, amount, date, uid, transactionDetails, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, now())
        `;
        exeCommand({
            sql: query,
            values: [title, amount, date, uid, transactionJSON]
        })
        .then(() => res.json('success'))
        .catch(err => {
            console.error('Insert error:', err);
            res.status(500).json({ error: 'Insert failed' });
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});


//Insert Products
router.post('/products/insert', async (req, res) => {
    const { title, uid, productName } = req.body;

    const productJSON = JSON.stringify(productName || []);

    try {
        const query = `
            INSERT INTO products (title, uid, productName, TIMEDATE)
            VALUES (?, ?, ?, now())
        `;
        await exeCommand({
            sql: query,
            values: [title, uid, productJSON]
        });
        res.json('success');
    } catch (error) {
        console.error('Insert error:', error);
        res.status(500).json({ error: 'Insert failed' });
    }
});

router.post('/products/add', async (req, res) => {
    const { id, newProducts } = req.body;

    if (!id || !newProducts || !Array.isArray(newProducts) || newProducts.length === 0) {
        return res.status(400).json({ error: 'Invalid input: id and newProducts array are required.' });
    }

    try {
       //Fetch the existing products JSON from the database
        const selectQuery = 'SELECT productName FROM products WHERE id = ?';
        const [existingProductData] = await exeCommand({
            sql: selectQuery,
            values: [id]
        });

        if (!existingProductData) {
            return res.status(404).json({ error: 'Product list not found' });
        }

        //  Check if the data is a string before parsing. If not, use it directly.
        let existingProductsArray;
        if (typeof existingProductData.productName === 'string') {
            // If it's a string, parse it
            existingProductsArray = JSON.parse(existingProductData.productName || '[]');
        } else {
            // If it's already an object/array, just use it
            existingProductsArray = existingProductData.productName || [];
        }
        const formattedNewProducts = newProducts.map(name => ({ productName: name }));
        const updatedProductsArray = [...existingProductsArray, ...formattedNewProducts];

        const updatedProductJSON = JSON.stringify(updatedProductsArray);
        const updateQuery = 'UPDATE products SET productName = ? WHERE id = ?';
        await exeCommand({
            sql: updateQuery,
            values: [updatedProductJSON, id]
        });

        res.json({ message: 'Products added successfully' });

    } catch (error) {   
        console.error('Error adding products:', error);
        res.status(500).json({ error: 'Failed to add products' });
    }
}); 


//Update productName
router.post('/products/update', async (req, res) => {
    const { id, updatedProducts } = req.body;

    if (!id || !Array.isArray(updatedProducts)) {
        return res.status(400).json({ error: 'Invalid input: id and updatedProducts array are required.' });
    }

    try {
        // Convert product array to JSON string
        const updatedProductJSON = JSON.stringify(updatedProducts);

        // Update database
        const updateQuery = 'UPDATE products SET productName = ? WHERE id = ?';
        const result = await exeCommand({
            sql: updateQuery,
            values: [updatedProductJSON, id]
        });

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'No products found for given ID.' });
        }

        res.json({ message: 'Products updated successfully' });
    } catch (error) {
        console.error('Error updating products:', error);
        res.status(500).json({ error: 'Failed to update products' });
    }
});


// DELETE PRODUCTS API
router.post('/products/delete', async (req, res) => {
    const { id, remainingProducts } = req.body;

    // Validate inputs
    if (!id || !Array.isArray(remainingProducts)) {
        return res.status(400).json({
            error: 'Invalid input: id and remainingProducts array are required.'
        });
    }

    try {
        // Convert remaining products array to JSON string
        const remainingProductsJSON = JSON.stringify(remainingProducts);

        // Update the database with the new product list
        const deleteQuery = 'UPDATE products SET productName = ? WHERE id = ?';
        const result = await exeCommand({
            sql: deleteQuery,
            values: [remainingProductsJSON, id]
        });

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'No products found for given ID.' });
        }

        res.json({ message: 'Products deleted successfully' });
    } catch (error) {
        console.error('Error deleting products:', error);
        res.status(500).json({ error: 'Failed to delete products' });
    }
});

// //Delete user Transaction
// router.post('/deleteUserTransaction', (req, res) => {
//   const id = req.body.id;
//   const query = `DELETE FROM products WHERE id = '${id}'`;

//   exeCommand(query)
//     .then((result) => {
//       res.json({ success: true, message: 'Deleted successfully', result });
//       console.log('Delete successfully');
//     })
//     .catch((err) => {
//     //   logWriter(query, err);
//       res.status(500).json({ success: false, message: 'Error deleting transaction' });
//       console.log('Error deleting transaction');
//     });
// });



        export default router;