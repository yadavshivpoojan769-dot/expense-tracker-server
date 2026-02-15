import express from 'express';
import multer from 'multer';
import path from 'path';
import exeCommand from '../config/cmdExecution.js';
const router = express.Router();

router.post('/userInfo', (req, res) => {
    const email = req.body.email;
    const query = `SELECT * FROM userdata WHERE email = '${email}' LIMIT 1`;
    console.log("Query for get userinfo", query);

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});

//All user Details
router.post('/userDetails', (req, res) => {
    const userId = req.body.userId;

    const query = `SELECT * FROM user_details WHERE userId = '${userId}' ORDER BY TIMEDATE DESC`;

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});

//Top 3 user details
router.post('/limiteduserDetails', (req, res) => {
    const userId = req.body.userId;

    const query = `SELECT * FROM user_details WHERE userId = '${userId}' ORDER BY TIMEDATE DESC`;

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});


//multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/'); // Don't use leading slash ('/uploads/') unless it's absolute
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const upload = multer({ storage: storage });

router.post('/profile/update', upload.single('file'), async (req, res) => {
    const name = req.body.name;
    const phone = req.body.phone;
    const email = req.body.email;
    const imagePath = req.file ? path.posix.join('uploads', req.file.filename) : null;

    let query = `UPDATE userdata SET name='${name}', phone='${phone}'`;

    if (imagePath) {
        query += `, image='${imagePath}'`;
    }

    query += ` WHERE email='${email}'`;

    console.log("Update Query:", query);

    try {
        await exeCommand(query);
        res.json({
            status: 'success',
            image: imagePath // Could be null, handle on Flutter
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ status: 'error', error: err });
    }
});


//Fetch LIMITED Budget Transaction
router.post('/budgetTransaction', (req, res) => {
    const uid = req.body.uid;

    const query = `SELECT * FROM budget WHERE uid = '${uid}' ORDER BY TIMEDATE DESC`;

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});

//Delete Budget Transaction
router.post('/deletebudgetTransaction', (req, res) => {
    const id = req.body.id;
    const query = `DELETE FROM budget WHERE id = '${id}'`;

    exeCommand(query)
        .then((result) => {
            res.json({ success: true, message: 'Deleted successfully', result });
            console.log('Delete successfully');
        })
        .catch((err) => {
            //   logWriter(query, err);
            res.status(500).json({ success: false, message: 'Error deleting transaction' });
            console.log('Error deleting transaction');
        });
});

//UserTransaction Details
router.post('/userTransaction', (req, res) => {
    const userId = req.body.userId;

    const query = `SELECT * FROM user_details WHERE userId = '${userId}' ORDER BY TIMEDATE DESC`;

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});


//Fetch Products
router.post('/allProducts', (req, res) => {
    const uid = req.body.uid;

    const query = `SELECT * FROM products WHERE uid = '${uid}' ORDER BY TIMEDATE DESC`;

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});


//Delete Products 
router.post('/deleteProducts', (req, res) => {
    const id = req.body.id;
    const query = `DELETE FROM products WHERE id = '${id}'`;

    exeCommand(query)
        .then((result) => {
            res.json({ success: true, message: 'Deleted successfully', result });
            console.log('Delete successfully');
        })
        .catch((err) => {
            //   logWriter(query, err);
            res.status(500).json({ success: false, message: 'Error deleting transaction' });
            console.log('Error deleting transaction');
        });
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

// Delete multiple user transactions
router.post('/deleteUserTransaction', async (req, res) => {
    console.log("upcoming data:", req.body);
    const upcomingIds = req.body.transactionIds;

    if (!Array.isArray(upcomingIds) || upcomingIds.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'transactionIds must be a non-empty array'
        });
    }

    try {
        const idsStr = upcomingIds.map(id => parseInt(id, 10)).join(",");
        const cmd = `DELETE FROM user_details WHERE id IN (${idsStr})`;
        const result = await exeCommand(cmd);

        return res.status(200).json({
            success: true,
            message: 'Transactions deleted successfully',
            deletedCount: result?.affectedRows || 0
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error?.message || 'Server error'
        });
    }
});


//Fetch Shopkeeper Info
router.post('/shopkeeperInfo', (req, res) => {
    const uid = req.body.uid;

    const query = `SELECT * FROM Shopkeeper WHERE uid = '${uid}' LIMIT 1`;

    exeCommand(query).then((result) => {
        // console.log(result);
        exeCommand(query)
            .then((result) => res.json(result))
            .catch((err) => logWriter(query, err))

    }).catch((err) => {
        console.log(err);
    });
});

//Delete Shopkeeper Account

router.post('/deleteShopkeeper', (req, res) => {
    const id = req.body.id;
    const query = `DELETE FROM Shopkeeper WHERE id = '${id}'`;

    exeCommand(query)
        .then((result) => {
            res.json({ success: true, message: 'Deleted successfully', result });
            console.log('Delete successfully');
        })
        .catch((err) => {
            //   logWriter(query, err);
            res.status(500).json({ success: false, message: 'Error deleting transaction' });
            console.log('Error deleting transaction');
        });
});






export default router;
