const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json({ limit: '1mb' }));

let db = {
    all_users_table: {}
};

app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

app.get('/', (req, res) => {
    res.status(200).send('Onion Evade Hub Backend is Running!');
});

app.get('/get/:key', (req, res) => {
    const key = req.params.key;
    if (db[key]) {
        return res.status(200).json(db[key]);
    }
    return res.status(200).json({});
});

app.post('/set/:key', (req, res) => {
    const key = req.params.key;
    if (req.body) {
        db[key] = req.body;
        return res.status(200).json({ success: true });
    }
    return res.status(400).json({ error: 'Invalid or empty body' });
});

app.listen(PORT, () => {
    console.log(`Server successfully started on port ${PORT}`);
});
