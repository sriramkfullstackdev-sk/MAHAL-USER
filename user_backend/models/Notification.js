const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    user_id: { type: mongoose.Schema.Types.ObjectId, required: true },
    title: { type: String, required: true },
    body: { type: String, required: true },
    type: { type: String, default: 'booking' },
    is_read: { type: Boolean, default: false },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Notification', notificationSchema);
