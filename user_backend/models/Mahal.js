const mongoose = require('mongoose');

const mahalSchema = new mongoose.Schema({
    mahal_name: { type: String, required: true },
    mahalowner_id: { type: mongoose.Schema.Types.ObjectId, ref: 'MahalOwner', required: true },
    contact_no: { type: String },
    contact_no_2: { type: String },
    whatsapp_no: { type: String },
    street_address: { type: String },
    locality: { type: String },
    city: { type: String },
    state: { type: String },
    pincode: { type: String },
    latitude: { type: String },
    longitude: { type: String },
    full_day_price: { type: Number },
    half_day_price: { type: Number },
    advance_amount: { type: Number },
    seat_capacity: { type: Number },
    dining_capacity: { type: Number },
    parking_car_capacity: { type: Number },
    parking_bike_capacity: { type: Number },
    rooms_available: { type: Number },
    ac_available: { type: Boolean, default: false },
    veg_nonveg: { type: String },
    features: { type: [String] },
    mahal_image: { type: Buffer },
    mahal_images_2: { type: Buffer },
    mahal_images_3: { type: Buffer },
    mahal_images_4: { type: Buffer },
    mahal_images_5: { type: Buffer },
    mahal_images_6: { type: Buffer },
    bank_acc_name: { type: String },
    bank_acc_no: { type: String },
    bank_ifsc: { type: String },
    bank_branch: { type: String },
    bank_bank_name: { type: String },
    default_timings: [{
        booking_type: String,
        start_time: String,
        end_time: String
    }],
    verification_status: { type: String, default: 'Pending' },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Mahal', mahalSchema);
