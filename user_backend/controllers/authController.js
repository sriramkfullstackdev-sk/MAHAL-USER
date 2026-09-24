const jwt = require('jsonwebtoken');
const User = require('../models/User');

// In-memory OTP store for development (mobile_number -> { otp, expiresAt })
const otpStore = {};

exports.checkMobile = async (req, res, next) => {
    try {
        const mobile = req.body.mobile || req.body.mobileNumber || req.body.phone_number || req.body.phoneNumber;

        if (!mobile) {
            return res.status(400).json({ success: false, message: 'Mobile number is required' });
        }

        const user = await User.findOne({ mbl_no: mobile });
        const exists = !!user;

        return res.status(200).json({
            success: true,
            exists,
            role: exists ? 'USER' : null,
            userId: exists ? user._id : null,
        });
    } catch (err) {
        next(err);
    }
};

exports.sendOtp = async (req, res, next) => {
    try {
        const { mobileNumber } = req.body;
        if (!mobileNumber) {
            return res.status(400).json({ success: false, message: 'Mobile number is required' });
        }

        const r = Math.random();
        const m = r * 9000;
        const s = 1000 + m;
        const f = Math.floor(s);
        const otp = f.toString();
        console.log(`[DEBUG] r=${r} | m=${m} | s=${s} | f=${f} | otp=${otp} | length=${otp.length}`);
        
        // Store OTP with 5 mins expiry
        otpStore[mobileNumber] = {
            otp,
            expiresAt: Date.now() + 5 * 60 * 1000 
        };

        // PRINT TO TERMINAL AS REQUESTED
        console.log(`\n========================================`);
        console.log(`🔑 OTP for ${mobileNumber} is: ${otp}`);
        console.log(`========================================\n`);

        return res.status(200).json({
            success: true,
            message: 'OTP sent successfully (Check terminal)'
        });
    } catch (err) {
        next(err);
    }
};

exports.verifyOtp = async (req, res, next) => {
    try {
        const { mobileNumber, otp } = req.body;
        if (!mobileNumber || !otp) {
            return res.status(400).json({ success: false, message: 'Mobile number and OTP are required' });
        }

        const storedData = otpStore[mobileNumber];
        if (!storedData) {
            return res.status(400).json({ success: false, message: 'Please request a new OTP' });
        }

        if (Date.now() > storedData.expiresAt) {
            delete otpStore[mobileNumber];
            return res.status(400).json({ success: false, message: 'OTP has expired' });
        }

        if (storedData.otp !== otp) {
            return res.status(400).json({ success: false, message: 'Invalid OTP' });
        }

        // Clear OTP after successful verification
        delete otpStore[mobileNumber];

        // Check if user exists in DB
        const user = await User.findOne({ mbl_no: mobileNumber });
        const userExists = !!user;

        let token = null;

        if (userExists) {
            token = jwt.sign(
                { id: user._id.toString(), mobile: user.mbl_no },
                process.env.JWT_SECRET || 'super_secret_key_for_mahal_spot_users_123',
                { expiresIn: '30d' }
            );
        }

        return res.status(200).json({
            success: true,
            message: 'OTP verified successfully',
            userExists,
            isExistingUser: userExists,
            role: userExists ? 'USER' : null,
            userId: user ? user._id : null,
            token,
            user: user
        });

    } catch (err) {
        next(err);
    }
};

exports.registerUser = async (req, res, next) => {
    try {
        const { mobileNumber, name, address, state } = req.body;
        
        if (!mobileNumber || !name) {
            return res.status(400).json({ success: false, message: 'Mobile number and name are required' });
        }

        const fullAddress = state ? `${address}, ${state}` : address;

        // Ensure user doesn't already exist
        let user = await User.findOne({ mbl_no: mobileNumber });
        if (user) {
            return res.status(400).json({ success: false, message: 'User already exists' });
        }

        user = new User({
            name,
            mbl_no: mobileNumber,
            address: fullAddress
        });
        await user.save();

        const token = jwt.sign(
            { id: user._id.toString(), mobile: user.mbl_no },
            process.env.JWT_SECRET || 'super_secret_key_for_mahal_spot_users_123',
            { expiresIn: '30d' }
        );

        return res.status(201).json({
            success: true,
            message: 'User registered successfully',
            token,
            user
        });
    } catch (err) {
        next(err);
    }
};

exports.getProfile = async (req, res, next) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user) {
            return res.status(404).json({ success: false, message: 'User profile not found' });
        }

        return res.status(200).json({ success: true, data: user });
    } catch (err) {
        next(err);
    }
};

exports.updateProfile = async (req, res, next) => {
    try {
        const { name, mobileNumber, address } = req.body;
        if (!name || !mobileNumber || !address) {
            return res.status(400).json({ success: false, message: 'Name, mobile number and address are required' });
        }

        const user = await User.findByIdAndUpdate(req.user.id, {
            name,
            mbl_no: mobileNumber,
            address
        }, { new: true });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User profile not found' });
        }

        return res.status(200).json({ success: true, data: user });
    } catch (err) {
        next(err);
    }
};

exports.saveFcmToken = async (req, res, next) => {
    try {
        const { fcm_token } = req.body;
        const user_id = req.user.id;

        if (!fcm_token || typeof fcm_token !== 'string') {
            return res.status(400).json({ success: false, message: 'fcm_token is required' });
        }

        await User.findByIdAndUpdate(user_id, { fcm_token });

        return res.status(200).json({ success: true, message: 'FCM token saved successfully' });
    } catch (err) {
        next(err);
    }
};
