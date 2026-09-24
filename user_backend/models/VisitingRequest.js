const mongoose = require('mongoose');

const visitingRequestSchema = new mongoose.Schema({
    booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    mahal_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Mahal', required: true },
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    visiting_date: { type: Date, required: true },
    visiting_time: { type: String, required: true },
    visit_status: { type: String, default: 'Pending' },
    qr_token: { type: String },
    qr_status: { type: String, default: 'Unused' },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('VisitingRequest', visitingRequestSchema);
