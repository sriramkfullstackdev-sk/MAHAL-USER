const crypto = require('crypto');
const VisitingRequest = require('../models/VisitingRequest');
const Booking = require('../models/Booking');
const Mahal = require('../models/Mahal');
const User = require('../models/User');
const { notifyOwnerOfBookingRequest } = require('../services/notificationService');

// Helper to parse date string (YYYY-MM-DD) and time string ("07:30 PM") into DateTime
function parseVisitingDateTime(dateStr, timeStr) {
    if (!dateStr || !timeStr) return null;
    try {
        let [year, month, day] = dateStr.split('-').map(Number);
        
        let match = timeStr.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
        if (!match) return null;

        let hours = parseInt(match[1], 10);
        let minutes = parseInt(match[2], 10);
        let period = match[3].toUpperCase();

        if (period === 'PM' && hours < 12) hours += 12;
        if (period === 'AM' && hours === 12) hours = 0;

        return new Date(year, month - 1, day, hours, minutes, 0);
    } catch (e) {
        return null;
    }
}

// 1. Save Visiting Time
exports.saveVisitingTime = async (req, res, next) => {
    try {
        const { booking_id, visiting_date, visiting_time, payment_time } = req.body;
        const user_id = req.user.id;

        if (!booking_id || !visiting_date || !visiting_time) {
            return res.status(400).json({ 
                success: false, 
                message: 'booking_id, visiting_date, and visiting_time are required' 
            });
        }

        const booking = await Booking.findOne({ _id: booking_id, user_id }).populate({
            path: 'mahal_id',
            populate: { path: 'mahalowner_id' }
        });

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        const mahal = booking.mahal_id;
        const owner = mahal ? mahal.mahalowner_id : null;
        
        const user = await User.findById(user_id);
        const userName = booking.user_name || (user ? user.name : 'A user');

        const payTimeObj = payment_time ? new Date(payment_time) : new Date();
        const visitingDateTime = parseVisitingDateTime(visiting_date, visiting_time);

        if (!visitingDateTime || isNaN(visitingDateTime.getTime())) {
            return res.status(400).json({ success: false, message: 'Invalid visiting date or time format' });
        }

        const maxAllowedTime = new Date(payTimeObj.getTime() + 180 * 60 * 1000);

        if (visitingDateTime > maxAllowedTime) {
            return res.status(400).json({
                success: false,
                message: 'Selected visiting time exceeds the allowed limit (Max 3 hours from payment).'
            });
        }

        if (visitingDateTime < new Date(payTimeObj.getTime() - 5 * 60 * 1000)) {
            return res.status(400).json({
                success: false,
                message: 'Visiting time must be in the future.'
            });
        }

        let existingVisit = await VisitingRequest.findOne({ booking_id });

        const qr_token = `QR-${booking_id}-${crypto.randomBytes(6).toString('hex').toUpperCase()}`;

        if (existingVisit) {
            existingVisit.visiting_date = visiting_date;
            existingVisit.visiting_time = visiting_time;
            existingVisit.expiry_time = visitingDateTime;
            existingVisit.visit_status = 'Scheduled';
            existingVisit.qr_status = 'Generated';
            existingVisit.qr_token = qr_token;
            await existingVisit.save();
        } else {
            existingVisit = new VisitingRequest({
                booking_id,
                user_id,
                mahal_id: mahal ? mahal._id : null,
                visiting_date,
                visiting_time,
                expiry_time: visitingDateTime,
                visit_status: 'Scheduled',
                qr_token,
                qr_status: 'Generated'
            });
            await existingVisit.save();
        }

        booking.booking_status = 'Visit Pending';
        await booking.save();

        const nowServer = new Date();

        if (owner && owner.fcm_token) {
            try {
                await notifyOwnerOfBookingRequest({
                    ownerToken: owner.fcm_token,
                    ownerId: owner._id,
                    bookingId: booking._id,
                    userName,
                    eventName: booking.event_name,
                    eventDate: booking.booking_date,
                    eventTime: booking.event_time,
                    eventEndDate: booking.end_date,
                    eventEndTime: booking.end_time,
                    visitingDate: visiting_date,
                    visitingTime: visiting_time
                });
            } catch (err) {
                console.error('QR generated, but owner notification failed:', err.message);
            }
        }

        return res.status(200).json({
            success: true,
            message: 'Visiting time scheduled and QR pass generated successfully',
            data: {
                booking_id,
                mahal_id: mahal ? mahal._id : null,
                visiting_date,
                visiting_time,
                payment_time: payTimeObj.toISOString(),
                expiry_time: visitingDateTime.toISOString(),
                server_time: nowServer.toISOString(),
                qr_token,
                visit_status: 'Scheduled',
                qr_status: 'Generated',
                booking_status: 'Visit Pending'
            }
        });
    } catch (err) {
        next(err);
    }
};

function getExactExpiryIso(dateStr, timeStr) {
    if (!dateStr || !timeStr) return null;
    try {
        let dStr = dateStr;
        if (typeof dStr === 'object' && dStr instanceof Date) {
            const y = dStr.getFullYear();
            const m = String(dStr.getMonth() + 1).padStart(2, '0');
            const d = String(dStr.getDate()).padStart(2, '0');
            dStr = `${y}-${m}-${d}`;
        } else if (typeof dStr === 'string') {
            dStr = dStr.split('T')[0].split(' ')[0];
        }

        let match = timeStr.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
        if (!match) return null;

        let hours = parseInt(match[1], 10);
        let minutes = parseInt(match[2], 10);
        let period = match[3].toUpperCase();

        if (period === 'PM' && hours < 12) hours += 12;
        if (period === 'AM' && hours === 12) hours = 0;

        let [year, month, day] = dStr.split('-').map(Number);
        const localDate = new Date(year, month - 1, day, hours, minutes, 0);
        return localDate.toISOString();
    } catch (e) {
        return null;
    }
}

// 2. Get Visiting Details
exports.getVisitingDetails = async (req, res, next) => {
    try {
        const { booking_id } = req.query;
        if (!booking_id) {
            return res.status(400).json({ success: false, message: 'booking_id is required' });
        }

        const visit = await VisitingRequest.findOne({ booking_id }).populate({
            path: 'booking_id',
            populate: { path: 'mahal_id' }
        });

        if (!visit) {
            return res.status(404).json({ success: false, message: 'Visiting details not found' });
        }

        const booking = visit.booking_id;
        const mahal = booking ? booking.mahal_id : null;

        const now = new Date();
        const expiry = new Date(visit.expiry_time || now);
        const remainingMs = Math.max(0, expiry.getTime() - now.getTime());

        return res.status(200).json({
            success: true,
            data: {
                ...visit.toObject(),
                booking_id: booking ? booking._id : null,
                event_name: booking ? booking.event_name : null,
                booking_date: booking ? booking.booking_date : null,
                event_time: booking ? booking.event_time : null,
                mbl_no: booking ? booking.mbl_no : null,
                user_name: booking ? booking.user_name : null,
                current_b_status: booking ? booking.booking_status : null,
                owner_decision: booking ? booking.owner_decision : null,
                user_decision: booking ? booking.user_decision : null,
                mahal_name: mahal ? mahal.mahal_name : null,
                city: mahal ? mahal.city : null,
                remaining_seconds: Math.floor(remainingMs / 1000),
                is_expired: now > expiry && visit.visit_status !== 'Verified' && visit.visit_status !== 'Completed'
            }
        });
    } catch (err) {
        next(err);
    }
};

// 3. Get Realtime Visit & Booking Status & Expiry Check
exports.getVisitStatus = async (req, res, next) => {
    try {
        const { booking_id } = req.query;
        if (!booking_id) {
            return res.status(400).json({ success: false, message: 'booking_id is required' });
        }

        const visit = await VisitingRequest.findOne({ booking_id }).populate('booking_id');

        if (!visit) {
            return res.status(404).json({ success: false, message: 'Visiting request not found' });
        }

        const booking = visit.booking_id;
        const expiryIso = getExactExpiryIso(visit.visiting_date, visit.visiting_time) || (visit.expiry_time ? new Date(visit.expiry_time).toISOString() : new Date().toISOString());
        const now = new Date();
        const expiry = new Date(expiryIso);

        const isExpired = now > expiry && visit.visit_status === 'Scheduled' && booking && booking.booking_status !== 'QR Verified' && booking.booking_status !== 'Waiting For User Confirmation' && booking.booking_status !== 'Confirmed';

        if (isExpired) {
            visit.visit_status = 'Expired';
            visit.qr_status = 'Expired';
            await visit.save();

            if (booking) {
                booking.booking_status = 'Cancelled';
                await booking.save();
            }
        }

        const remainingMs = Math.max(0, expiry.getTime() - now.getTime());

        return res.status(200).json({
            success: true,
            data: {
                visit_status: visit.visit_status,
                qr_status: visit.qr_status,
                booking_status: booking ? booking.booking_status : null,
                owner_decision: booking ? booking.owner_decision : null,
                user_decision: booking ? booking.user_decision : null,
                rejection_reason: booking ? booking.rejection_reason : null,
                expiry_time: expiryIso,
                server_time: now.toISOString(),
                remaining_seconds: Math.floor(remainingMs / 1000),
                is_expired: isExpired || visit.visit_status === 'Expired'
            }
        });
    } catch (err) {
        next(err);
    }
};
