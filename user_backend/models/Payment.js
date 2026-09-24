const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    amount: { type: Number, required: true },
    pay_method: { type: String, required: true },
    pay_statement: { type: String, default: 'Advance Paid' },
    mahal_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Mahal', required: true },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Payment', paymentSchema);
