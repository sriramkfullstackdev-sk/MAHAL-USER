const crypto = require('crypto');
const VisitingRequest = require('../models/VisitingRequest');
const Booking = require('../models/Booking');
const Mahal = require('../models/Mahal');
const { notifyOwnerOfBookingRequest } = require('../services/notificationService');

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

// 1. Generate QR Pass Metadata
exports.generateQr = async (req, res, next) => {
    try {
        const { booking_id } = req.body;
        if (!booking_id) return res.status(400).json({ success: false, message: 'booking_id is required' });

        const visit = await VisitingRequest.findOne({ booking_id }).populate({
            path: 'booking_id',
            populate: { path: 'mahal_id' }
        });

        if (!visit) {
            return res.status(404).json({ success: false, message: 'Visiting request not found for this booking' });
        }

        const booking = visit.booking_id;
        if (!booking) return res.status(404).json({ success: false, message: 'Associated booking not found' });

        const mahal = booking.mahal_id;
        let shouldNotifyOwner = false;

        if (!visit.qr_token || visit.qr_status !== 'Generated') {
            visit.qr_token = `QR-${booking._id}-${crypto.randomBytes(6).toString('hex').toUpperCase()}`;
            visit.qr_status = 'Generated';
            visit.visit_status = 'Scheduled';
            await visit.save();
            shouldNotifyOwner = true;
        }

        const expiryIso = getExactExpiryIso(visit.visiting_date, visit.visiting_time) || (visit.expiry_time ? new Date(visit.expiry_time).toISOString() : new Date().toISOString());
        const now = new Date();
        const expiry = new Date(expiryIso);

        if (now > expiry && visit.visit_status === 'Scheduled') {
            visit.visit_status = 'Expired';
            await visit.save();
            
            booking.booking_status = 'Cancelled';
            await booking.save();
        }

        if (shouldNotifyOwner && mahal && mahal.mahalowner_id) {
            try {
                await notifyOwnerOfBookingRequest({
                    ownerToken: mahal.mahalowner_id.fcm_token,
                    ownerId: mahal.mahalowner_id._id,
                    bookingId: booking._id,
                    userName: booking.user_name,
                    eventName: booking.event_name,
                    eventDate: booking.booking_date,
                    eventTime: booking.event_time,
                    eventEndDate: booking.end_date,
                    eventEndTime: booking.end_time,
                    visitingDate: visit.visiting_date,
                    visitingTime: visit.visiting_time,
                });
            } catch (err) {
                console.error('QR generated, but owner notification failed:', err.message);
            }
        }

        return res.status(200).json({
            success: true,
            data: {
                qr_token: visit.qr_token,
                booking_id: booking._id,
                mahal_name: mahal ? mahal.mahal_name : null,
                event_name: booking.event_name,
                user_name: booking.user_name,
                mbl_no: booking.mbl_no,
                booking_date: booking.booking_date,
                visiting_date: visit.visiting_date,
                visiting_time: visit.visiting_time,
                expiry_time: expiryIso,
                qr_valid_until: visit.visiting_time,
                server_time: now.toISOString(),
                visit_status: visit.visit_status,
                booking_status: booking.booking_status
            }
        });
    } catch (err) {
        next(err);
    }
};

// 2. Download Ticket Payload
exports.downloadQr = async (req, res, next) => {
    try {
        const { booking_id } = req.query;
        if (!booking_id) return res.status(400).json({ success: false, message: 'booking_id is required' });

        const visit = await VisitingRequest.findOne({ booking_id }).populate({
            path: 'booking_id',
            populate: { path: 'mahal_id' }
        });

        if (!visit) return res.status(404).json({ success: false, message: 'Ticket not found' });
        const booking = visit.booking_id;
        const mahal = booking ? booking.mahal_id : null;

        return res.status(200).json({
            success: true,
            ticketPayload: {
                title: "MAHAL VISITING PASS",
                mahal_name: mahal ? mahal.mahal_name : null,
                event_name: booking ? booking.event_name : null,
                booking_id: booking ? booking._id : null,
                user_name: booking ? booking.user_name : null,
                mbl_no: booking ? booking.mbl_no : null,
                event_date: booking ? booking.booking_date : null,
                visiting_date: visit.visiting_date,
                visiting_time: visit.visiting_time,
                qr_valid_until: visit.expiry_time,
                qr_token: visit.qr_token
            }
        });
    } catch (err) {
        next(err);
    }
};

// 3. Verify QR Token
exports.verifyQr = async (req, res, next) => {
    try {
        const { qr_token } = req.body;
        if (!qr_token) return res.status(400).json({ success: false, message: 'qr_token is required' });

        const visit = await VisitingRequest.findOne({ qr_token }).populate({
            path: 'booking_id',
            populate: { path: 'mahal_id' }
        });

        if (!visit) return res.status(404).json({ success: false, message: 'Invalid QR Pass' });

        const booking = visit.booking_id;
        const now = new Date();
        const expiry = new Date(visit.expiry_time || now);

        if (now > expiry || visit.visit_status === 'Expired' || (booking && booking.booking_status === 'Cancelled')) {
            visit.visit_status = 'Expired';
            await visit.save();
            if (booking) {
                booking.booking_status = 'Cancelled';
                await booking.save();
            }
            return res.status(400).json({
                success: false,
                status: 'EXPIRED',
                message: 'QR Expired. Booking Cancelled. Access Denied.'
            });
        }

        if (visit.visit_status === 'Completed') {
            return res.status(400).json({
                success: false,
                status: 'USED',
                message: 'QR Pass has already been used.'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'QR Pass is Valid',
            data: {
                ...visit.toObject(),
                booking_id: booking ? booking._id : null,
                event_name: booking ? booking.event_name : null,
                booking_date: booking ? booking.booking_date : null,
                mbl_no: booking ? booking.mbl_no : null,
                user_name: booking ? booking.user_name : null,
                current_b_status: booking ? booking.booking_status : null,
                mahal_name: (booking && booking.mahal_id) ? booking.mahal_id.mahal_name : null
            }
        });
    } catch (err) {
        next(err);
    }
};

// 4. Scan QR Code by Owner
exports.scanQr = async (req, res, next) => {
    try {
        const { qr_token } = req.body;
        if (!qr_token) return res.status(400).json({ success: false, message: 'qr_token is required' });

        const visit = await VisitingRequest.findOne({ qr_token }).populate({
            path: 'booking_id',
            populate: { path: 'mahal_id' }
        });

        if (!visit) return res.status(404).json({ success: false, message: 'Invalid QR Code' });
        
        const booking = visit.booking_id;
        const now = new Date();
        const expiry = new Date(visit.expiry_time || now);

        if (now > expiry || visit.visit_status === 'Expired' || (booking && booking.booking_status === 'Cancelled')) {
            visit.visit_status = 'Expired';
            await visit.save();
            if (booking) {
                booking.booking_status = 'Cancelled';
                await booking.save();
            }
            return res.status(400).json({
                success: false,
                status: 'EXPIRED',
                message: 'QR Expired. Booking Cancelled. Access Denied.'
            });
        }

        if (visit.visit_status === 'Completed') {
            return res.status(400).json({
                success: false,
                status: 'USED',
                message: 'QR Pass already scanned and completed.'
            });
        }

        visit.visit_status = 'Completed';
        visit.qr_status = 'Scanned';
        await visit.save();

        if (booking) {
            booking.booking_status = 'Confirmed';
            await booking.save();
        }

        return res.status(200).json({
            success: true,
            status: 'VERIFIED',
            message: 'Visit Verified Successfully',
            data: {
                booking_id: booking ? booking._id : null,
                user_name: booking ? booking.user_name : null,
                mbl_no: booking ? booking.mbl_no : null,
                event_name: booking ? booking.event_name : null,
                mahal_name: (booking && booking.mahal_id) ? booking.mahal_id.mahal_name : null,
                visit_status: 'Completed',
                booking_status: 'Confirmed'
            }
        });
    } catch (err) {
        next(err);
    }
};
