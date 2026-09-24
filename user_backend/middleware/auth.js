const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
    const token = req.header('Authorization');
    if (!token) return res.status(401).json({ success: false, message: 'Access Denied. No token provided.' });

    try {
        const decoded = jwt.verify(token.replace('Bearer ', ''), process.env.JWT_SECRET || 'super_secret_key_for_mahal_spot_users_123');
        req.user = decoded;
        next();
    } catch (ex) {
        res.status(400).json({ success: false, message: 'Invalid token.' });
    }
};

module.exports = authMiddleware;
