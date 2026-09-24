const mongoose = require('mongoose');

const mahalOwnerSchema = new mongoose.Schema({
    mbl_no: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    owner_name: {
        type: String,
        trim: true
    },
    city: {
        type: String,
        trim: true
    },
    address: {
        type: String,
        trim: true
    },
    mahal_landline_num: {
        type: String,
        trim: true
    },
    owner_of_mahal: {
        type: String,
        trim: true
    },
    bank_account_holder_name: { type: String, trim: true },
    bank_account_number: { type: String, trim: true },
    bank_name: { type: String, trim: true },
    bank_ifsc_code: { type: String, trim: true },
    bank_branch_name: { type: String, trim: true },
    fcm_token: {
        type: String,
        default: null
    },
    created_at: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('MahalOwner', mahalOwnerSchema);
