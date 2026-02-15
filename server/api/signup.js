import bcrypt from 'bcrypt';
import express from 'express';
import multer from 'multer';
import exeCommand from '../config/cmdExecution.js';
import db from '../config/db.js';

const router = express.Router(); 

// Set up multer storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/'); // Don't use leading slash ('/uploads/') unless it's absolute
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({ storage: storage });

// Route: Sign Up User
router.post('/signupuser/insert', upload.single('file'), async (req, res) => {
    console.log("hit from Flutter"); 

    const { name, email, phone, password } = req.body;  
    const imagePath = req.file ? req.file.path : null;

    console.log("name:", name, "email:", email, "phone:", phone, "password:", password, "image:", imagePath);

    try {
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        const TIMEDATE = new Date();

        const query = `
            INSERT INTO userdata (name, email, phone, password, image, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        exeCommand({
            sql: query,
            values: [name, email, phone, hashedPassword, imagePath, TIMEDATE]
        })
            .then(() => res.json('success'))
            .catch(err => {
                console.error('Insert error:', err);
                res.status(500).json({ error: 'Insert failed' });
            });

    } catch (error) {
        console.error('Hashing error:', error);
        res.status(500).json({ error: 'Password hashing failed' });
    }
});

// Route: Check if email exists
router.post('/signupuser', (req, res) => {
    const email = req.body.email;
    const query = 'SELECT COUNT(*) as email_count FROM userdata WHERE email = ?';

    db.query(query, [email], (err, results) => {
        if (err) {  
            console.error('Error executing query:', err);
            return res.status(500).json({ error: 'Database query failed' });
        }

        const emailExists = results[0].email_count > 0;
        res.json({ email_exists: emailExists });
    });
});

//Add shopkeeper account

router.post('/shopkeeper/insert', upload.single('file'), async (req, res) => {
    console.log("get from Flutter"); 

    const { shopname, email, phone, shoptype, uid, address} = req.body;  
    const imagePath = req.file ? req.file.path : null;

    console.log("shopname:", shopname, "email:", email, "phone:", phone, "shoptype:", shoptype, "uid:", uid, "address:", address, "image:", imagePath);

    try {
        
        const TIMEDATE = new Date();

        const query = `
            INSERT INTO shopkeeper (shopname, email, phone, shoptype, uid, address, image, TIMEDATE)
            VALUES (?, ?, ?, ?, ?, ?, ?, now())
        `;

        exeCommand({
            sql: query,
            values: [shopname, email, phone, shoptype, uid, address, imagePath, TIMEDATE]
        })
            .then(() => res.json('success'))
            .catch(err => {
                console.error('Insert error:', err);
                res.status(500).json({ error: 'Insert failed' });
            });

    } catch (error) {
        console.error('Hashing error:', error);
        res.status(500).json({ error: 'Password hashing failed' });
    }
});

export default router;
