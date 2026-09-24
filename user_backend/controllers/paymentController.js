const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const { notifyOwner } = require('../services/notificationService');

exports.processPayment = async (req, res, next) => {
    try {
        const { booking_id, amount, pay_method, pay_statement, mahal_id } = req.body;
        const user_id = req.user.id;

        if (!booking_id || !amount || !pay_method) {
            return res.status(400).json({ success: false, message: 'Booking ID, Amount, and Payment Method are required' });
        }

        const payment = new Payment({
            user_id,
            booking_id,
            amount,
            pay_method,
            pay_statement: pay_statement || 'Advance Paid',
            mahal_id
        });
        await payment.save();

        const booking = await Booking.findOne({ _id: booking_id, user_id }).populate({
            path: 'mahal_id',
            populate: { path: 'mahalowner_id' }
        });
        if (booking) {
            booking.payment_status = 'Paid';
            booking.payment_method = pay_method;
            booking.payment_id = payment._id.toString();
            booking.payment_date = new Date();

            if (booking.owner_decision === 'Accepted' || booking.booking_status === 'Waiting For User Confirmation') {
                booking.user_decision = 'Accepted';
                booking.booking_status = 'Confirmed';
            } else {
                booking.booking_status = 'Payment Completed';
            }

            await booking.save();

            const owner = booking.mahal_id?.mahalowner_id;
            if (owner) {
                await notifyOwner({
                    ownerToken: owner.fcm_token,
                    ownerId: owner._id,
                    bookingId: booking._id,
                    title: 'Booking Completed',
                    body: `${booking.user_name} completed payment. The booking is confirmed on your calendar.`,
                    type: 'booking_completed',
                    data: { booking_status: booking.booking_status }
                });
            }
        }

        return res.status(201).json({
            success: true,
            message: 'Payment processed successfully',
            data: {
                payment_id: payment._id,
                booking_id,
                booking_status: booking ? booking.booking_status : 'Payment Completed'
            }
        });
    } catch (err) {
        next(err);
    }
};

exports.getPaymentHistory = async (req, res, next) => {
    try {
        const user_id = req.user.id;
        
        const payments = await Payment.find({ user_id })
            .populate('booking_id', 'event_name')
            .populate('mahal_id', 'mahal_name')
            .sort({ _id: -1 });

        const mapped = payments.map(p => ({
            ...p.toObject(),
            payment_id: p._id,
            event_name: p.booking_id ? p.booking_id.event_name : null,
            mahal_name: p.mahal_id ? p.mahal_id.mahal_name : null
        }));

        return res.status(200).json({
            success: true,
            data: mapped
        });
    } catch (err) {
        next(err);
    }
};
