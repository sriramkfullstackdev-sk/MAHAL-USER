const Booking = require('../models/Booking');
const Mahal = require('../models/Mahal');
const User = require('../models/User');
const VisitingRequest = require('../models/VisitingRequest');
const Notification = require('../models/Notification');
const { notifyOwner } = require('../services/notificationService');

function normalizeDate(dateVal) {
    if (!dateVal) return null;
    if (dateVal instanceof Date) return dateVal.toISOString().substring(0, 10);
    let dateStr = String(dateVal).trim();
    if (/^\d{4}-\d{2}-\d{2}/.test(dateStr)) return dateStr.substring(0, 10);
    if (/^\d{2}\.\d{2}\.\d{4}/.test(dateStr)) {
        const parts = dateStr.split('.');
        return `${parts[2]}-${parts[1]}-${parts[0]}`;
    }
    if (/^\d{1,2}\/\d{1,2}\/\d{4}/.test(dateStr)) {
        const parts = dateStr.split('/');
        return `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
    }
    try {
        const d = new Date(dateStr);
        if (!isNaN(d.getTime())) return d.toISOString().substring(0, 10);
    } catch (e) { }
    return dateStr;
}

function parseTimeToMinutes(timeStr) {
    if (!timeStr) return null;
    timeStr = String(timeStr).trim().toUpperCase().replace('.', ':');
    let isPM = timeStr.includes('PM');
    let isAM = timeStr.includes('AM');
    timeStr = timeStr.replace('PM', '').replace('AM', '').trim();
    const parts = timeStr.split(':');
    let hours = parseInt(parts[0], 10);
    let minutes = parts[1] ? parseInt(parts[1], 10) : 0;
    if (isNaN(hours)) return null;
    if (isNaN(minutes)) minutes = 0;
    if (isPM && hours < 12) hours += 12;
    else if (isAM && hours === 12) hours = 0;
    return hours * 60 + minutes;
}

function getRemainingAvailableTime(morningBooked, afternoonBooked, eveningBooked, parsedBookings) {
    if (morningBooked && afternoonBooked && eveningBooked) return "None";
    if (morningBooked && afternoonBooked) {
        let latestEndMin = 0;
        let latestEndTimeStr = "02:00 PM";
        for (const b of parsedBookings) {
            if (b.endMin > latestEndMin && b.endMin < 1440) {
                latestEndMin = b.endMin;
                latestEndTimeStr = b.end_time || b.orig_end_time || "02:00 PM";
            }
        }
        return `Available After ${latestEndTimeStr}`;
    }
    if (eveningBooked && !morningBooked) {
        let earliestStartMin = 1440;
        let earliestStartTimeStr = "06:00 PM";
        for (const b of parsedBookings) {
            if (b.startMin < earliestStartMin && b.startMin > 0) {
                earliestStartMin = b.startMin;
                earliestStartTimeStr = b.event_time || b.orig_event_time || "06:00 PM";
            }
        }
        return `Available Before ${earliestStartTimeStr}`;
    }
    if (morningBooked && !eveningBooked) {
        let latestEndMin = 0;
        let latestEndTimeStr = "12:00 PM";
        for (const b of parsedBookings) {
            if (b.endMin > latestEndMin) {
                latestEndMin = b.endMin;
                latestEndTimeStr = b.end_time || b.orig_end_time || "12:00 PM";
            }
        }
        return `Available After ${latestEndTimeStr}`;
    }
    return "Available Full Day";
}

function formatDateReadable(dateStr) {
    if (!dateStr) return '';
    try {
        const parts = dateStr.split('-');
        if (parts.length === 3) return `${parts[2]}-${parts[1]}-${parts[0]}`;
    } catch (_) {}
    return dateStr;
}

function calculateAvailabilityForDate(dateStr, bookings = [], defaultTimings = [], allBookingsByDate = {}) {
    const pendingStatuses = ['Pending', 'Payment Completed', 'Waiting For User Confirmation', 'Visit Pending'];

    const confirmedBookings = bookings.filter(b => !pendingStatuses.includes(b.booking_status));
    const pendingBookings = bookings.filter(b => pendingStatuses.includes(b.booking_status));

    let morningBooked = false, afternoonBooked = false, eveningBooked = false;

    const parsedBookings = confirmedBookings.map(b => ({
        ...b,
        startMin: parseTimeToMinutes(b.event_time) ?? 0,
        endMin: parseTimeToMinutes(b.end_time) ?? 1439
    })).sort((a, b) => {
        const dateA = normalizeDate(a.booking_date || a.orig_booking_date);
        const dateB = normalizeDate(b.booking_date || b.orig_booking_date);
        if (dateA && dateB && dateA !== dateB) return dateA.localeCompare(dateB);
        return (parseTimeToMinutes(a.orig_event_time || a.event_time) ?? 0) - (parseTimeToMinutes(b.orig_event_time || b.event_time) ?? 0);
    });

    const pendingParsedBookings = pendingBookings.map(b => ({
        ...b,
        startMin: parseTimeToMinutes(b.event_time) ?? 0,
        endMin: parseTimeToMinutes(b.end_time) ?? 1439
    })).sort((a, b) => (parseTimeToMinutes(a.orig_event_time || a.event_time) ?? 0) - (parseTimeToMinutes(b.orig_event_time || b.event_time) ?? 0));

    const occupiedBookings = [...parsedBookings, ...pendingParsedBookings].sort(
        (a, b) => (parseTimeToMinutes(a.orig_event_time || a.event_time) ?? 0) -
            (parseTimeToMinutes(b.orig_event_time || b.event_time) ?? 0),
    );

    for (const b of occupiedBookings) {
        const bType = (b.booking_type || b.event_name || '').toLowerCase();
        if (bType === 'full day' || (b.startMin <= 360 && b.endMin >= 1320)) {
            morningBooked = true; afternoonBooked = true; eveningBooked = true;
        }
        if (b.startMin < 720 && b.endMin > 0) morningBooked = true;
        if (b.startMin < 1080 && b.endMin > 720) afternoonBooked = true;
        if (b.startMin < 1440 && b.endMin > 1080) eveningBooked = true;
    }

    const fullDayBooked = morningBooked && afternoonBooked && eveningBooked;
    const remainingTime = getRemainingAvailableTime(morningBooked, afternoonBooked, eveningBooked, occupiedBookings);

    let nextDateStr = null;
    try {
        const d = new Date(dateStr);
        d.setDate(d.getDate() + 1);
        nextDateStr = d.toISOString().substring(0, 10);
    } catch (_) {}

    const nextDayBookings = (nextDateStr && allBookingsByDate[nextDateStr]) ? allBookingsByDate[nextDateStr] : [];

    const ownerDefaultSlots = defaultTimings.map(t => {
        const tStartMin = parseTimeToMinutes(t.start_time) ?? 0;
        const tEndMin = parseTimeToMinutes(t.end_time) ?? 1439;
        let isAvailable = !fullDayBooked;
        
        if (isAvailable) {
            if (tStartMin < tEndMin) {
                for (const b of occupiedBookings) {
                    if (tStartMin < b.endMin && tEndMin > b.startMin) {
                        isAvailable = false; break;
                    }
                }
            } else {
                for (const b of occupiedBookings) {
                    if (tStartMin < b.endMin && 1439 > b.startMin) {
                        isAvailable = false; break;
                    }
                }
                if (isAvailable && nextDayBookings.length > 0) {
                    for (const bNext of nextDayBookings) {
                        const bStartMin = parseTimeToMinutes(bNext.event_time) ?? 0;
                        const bEndMin = parseTimeToMinutes(bNext.end_time) ?? 1439;
                        if (0 < bEndMin && tEndMin > bStartMin) {
                            isAvailable = false; break;
                        }
                    }
                }
            }
        }
        return { booking_type: t.booking_type, start_time: t.start_time, end_time: t.end_time, is_available: isAvailable };
    });
    const availableSlots = ownerDefaultSlots.filter(slot => slot.is_available);

    let occupiedSlotsTextList = [];
    let availableSlotsTextList = [];

    if (fullDayBooked) {
        occupiedSlotsTextList.push("Full Day Occupied");
        availableSlotsTextList.push("None");
    } else {
        if (morningBooked && afternoonBooked && !eveningBooked) {
            const lastEnd = occupiedBookings.length > 0 ? (occupiedBookings[occupiedBookings.length - 1].orig_end_time || occupiedBookings[occupiedBookings.length - 1].end_time || '02:00 PM') : '02:00 PM';
            occupiedSlotsTextList.push(`Morning & Afternoon (Until ${lastEnd})`);
            availableSlotsTextList.push(`${lastEnd} onwards`);
        } else if (!morningBooked && !afternoonBooked && eveningBooked) {
            const firstStart = occupiedBookings.length > 0 ? (occupiedBookings[0].orig_event_time || occupiedBookings[0].event_time || '06:00 PM') : '06:00 PM';
            occupiedSlotsTextList.push(`Evening (After ${firstStart})`);
            availableSlotsTextList.push(`Before ${firstStart}`);
        } else {
            if (morningBooked) occupiedSlotsTextList.push("Morning"); else availableSlotsTextList.push("Morning");
            if (afternoonBooked) occupiedSlotsTextList.push("Afternoon"); else availableSlotsTextList.push("Afternoon");
            if (eveningBooked) occupiedSlotsTextList.push("Evening"); else availableSlotsTextList.push("Evening");
        }
    }

    const availableSlotsText = fullDayBooked ? "None" : availableSlotsTextList.join(', ');

    const allVisibleBookings = [
        ...parsedBookings.map(pb => {
            const sDate = pb.orig_booking_date || dateStr;
            const eDate = pb.orig_end_date || dateStr;
            const sTime = pb.orig_event_time || pb.event_time;
            const eTime = pb.orig_end_time || pb.end_time;
            return {
                booking_id: pb.booking_id || pb._id,
                user_id: pb.user_id,
                user_name: pb.user_name,
                mbl_no: pb.mbl_no,
                event_name: pb.event_name,
                event_time: sTime,
                end_time: eTime,
                booking_date: sDate,
                end_date: eDate,
                booking_status: pb.booking_status || 'Confirmed',
                booking_type: pb.booking_type,
                booked_duration_text: `${formatDateReadable(sDate)} ${sTime} ↓ ${formatDateReadable(eDate)} ${eTime}`,
                occupied_slots_text: 'Confirmed',
                available_slots_text: 'None'
            };
        }),
        ...pendingParsedBookings.map(pb => {
            const sDate = pb.orig_booking_date || dateStr;
            const eDate = pb.orig_end_date || dateStr;
            const sTime = pb.orig_event_time || pb.event_time;
            const eTime = pb.orig_end_time || pb.end_time;
            return {
                booking_id: pb.booking_id || pb._id,
                user_id: pb.user_id,
                user_name: pb.user_name,
                mbl_no: pb.mbl_no,
                event_name: pb.event_name,
                event_time: sTime,
                end_time: eTime,
                booking_date: sDate,
                end_date: eDate,
                booking_status: pb.booking_status || 'Pending',
                booking_type: pb.booking_type,
                booked_duration_text: `${formatDateReadable(sDate)} ${sTime} ↓ ${formatDateReadable(eDate)} ${eTime}`,
                occupied_slots_text: 'Pending approval',
                available_slots_text: 'Pending approval'
            };
        })
    ];

    return {
        booking_date: dateStr,
        morning_booked: morningBooked ? 1 : 0,
        afternoon_booked: afternoonBooked ? 1 : 0,
        evening_booked: eveningBooked ? 1 : 0,
        full_day_booked: fullDayBooked ? 1 : 0,
        pending_count: pendingParsedBookings.length,
        booked_start_time: occupiedBookings.length > 0 ? (occupiedBookings[0].orig_event_time || occupiedBookings[0].event_time) : "",
        booked_end_time: occupiedBookings.length > 0 ? (occupiedBookings[0].orig_end_time || occupiedBookings[0].end_time) : "",
        booking_status: parsedBookings.length > 0 ? parsedBookings[0].booking_status : (pendingParsedBookings.length > 0 ? 'Pending' : 'Available'),
        next_available_time: remainingTime.startsWith("Available ") ? remainingTime.replace("Available After ", "").replace("Available Before ", "") : remainingTime,
        remaining_available_time: remainingTime,
        occupied_slots_text: occupiedSlotsTextList.join(', '),
        available_slots_text: availableSlots.length > 0
            ? availableSlots.map(slot => slot.booking_type).join(', ')
            : 'None',
        available_slots: availableSlots,
        owner_default_slots: ownerDefaultSlots,
        multiple_bookings: allVisibleBookings.length > 1,
        bookings: allVisibleBookings
    };
}

exports.calculateAvailabilityForDate = calculateAvailabilityForDate;

exports.checkAvailability = async (req, res, next) => {
    try {
        const { mahal_id, booking_date } = req.query;
        if (!mahal_id) return res.status(400).json({ success: false, message: 'mahal_id is required' });

        const mahal = await Mahal.findById(mahal_id);
        if (!mahal) return res.status(404).json({ success: false, message: 'Mahal not found' });
        const defaultTimings = mahal.default_timings || [];

        const bookings = await Booking.find({
            mahal_id,
            booking_status: { $in: ['Confirmed', 'Pending', 'Payment Completed', 'Waiting For User Confirmation', 'Visit Pending'] }
        });

        const bookingsByDate = {};
        for (const row of bookings) {
            const startDateStr = normalizeDate(row.booking_date);
            let endDateStr = row.end_date ? normalizeDate(row.end_date) : startDateStr;
            if (!startDateStr) continue;

            const startMin = parseTimeToMinutes(row.event_time) ?? 0;
            const endMin = parseTimeToMinutes(row.end_time) ?? 1439;

            if (startMin >= endMin && endDateStr === startDateStr) {
                let nextDay = new Date(startDateStr);
                nextDay.setDate(nextDay.getDate() + 1);
                endDateStr = nextDay.toISOString().substring(0, 10);
            }

            let start = new Date(startDateStr);
            let end = new Date(endDateStr);

            if (isNaN(start.getTime()) || isNaN(end.getTime()) || start > end) {
                const list = bookingsByDate[startDateStr] || [];
                list.push({ ...row.toObject(), orig_booking_date: startDateStr, orig_end_date: endDateStr, orig_event_time: row.event_time, orig_end_time: row.end_time });
                bookingsByDate[startDateStr] = list;
                continue;
            }

            for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
                const curDateStr = d.toISOString().substring(0, 10);
                const list = bookingsByDate[curDateStr] || [];
                const isStartDay = curDateStr === startDateStr;
                const isEndDay = curDateStr === endDateStr;

                list.push({
                    booking_id: row._id,
                    user_id: row.user_id,
                    user_name: row.user_name,
                    mbl_no: row.mbl_no,
                    event_name: row.event_name,
                    booking_type: row.booking_type,
                    booking_status: row.booking_status,
                    orig_booking_date: startDateStr,
                    orig_end_date: endDateStr,
                    orig_event_time: row.event_time,
                    orig_end_time: row.end_time,
                    event_time: isStartDay ? row.event_time : "12:00 AM",
                    end_time: isEndDay ? row.end_time : "11:59 PM"
                });
                bookingsByDate[curDateStr] = list;
            }
        }

        const data = [];
        const sortedDates = Object.keys(bookingsByDate).sort();
        for (const dateStr of sortedDates) {
            data.push(calculateAvailabilityForDate(dateStr, bookingsByDate[dateStr], defaultTimings, bookingsByDate));
        }

        if (booking_date) {
            const normReqDate = normalizeDate(booking_date);
            let filtered = data.filter(d => d.booking_date === normReqDate);
            if (filtered.length === 0) {
                filtered = [calculateAvailabilityForDate(normReqDate, [], defaultTimings, bookingsByDate)];
            }
            return res.status(200).json({ success: true, data: filtered });
        }

        return res.status(200).json({ success: true, data });
    } catch (err) {
        next(err);
    }
};

exports.createBooking = async (req, res, next) => {
    try {
        const { mahal_id, booking_date, end_date, event_name, booking_type, total_amt, initial_amt } = req.body;
        let { event_time, end_time } = req.body;
        const user_id = req.user.id;

        if (!mahal_id) return res.status(400).json({ success: false, message: 'mahal_id is required' });

        const mahal = await Mahal.findById(mahal_id).populate('mahalowner_id');
        if (!mahal) return res.status(404).json({ success: false, message: 'Mahal not found' });

        const defaultTimings = mahal.default_timings || [];
        if (defaultTimings.length === 0) {
            return res.status(400).json({ success: false, message: 'Default booking timings for this Mahal have not been configured by the owner.' });
        }

        let selectedType = booking_type || 'Full Day';
        const matchedTiming = defaultTimings.find(t => t.booking_type.toLowerCase() === selectedType.toLowerCase());

        if (!matchedTiming) {
            return res.status(400).json({ success: false, message: `Default timings for '${selectedType}' have not been configured for this Mahal.` });
        }

        event_time = matchedTiming.start_time;
        end_time = matchedTiming.end_time;
        selectedType = matchedTiming.booking_type;

        const requestedDate = normalizeDate(booking_date);
        const requestedStart = parseTimeToMinutes(event_time) ?? 0;
        const requestedEnd = parseTimeToMinutes(end_time) ?? 1439;
        const activeBookings = await Booking.find({
            mahal_id,
            booking_status: { $in: ['Confirmed', 'Pending', 'Payment Completed', 'Waiting For User Confirmation', 'Visit Pending'] }
        });
        const hasOverlap = activeBookings.some(existing => {
            const existingDate = normalizeDate(existing.booking_date);
            if (existingDate !== requestedDate) return false;

            const existingStart = parseTimeToMinutes(existing.event_time) ?? 0;
            const existingEnd = parseTimeToMinutes(existing.end_time) ?? 1439;
            return requestedStart < existingEnd && requestedEnd > existingStart;
        });

        if (hasOverlap) {
            return res.status(409).json({
                success: false,
                message: 'This booking slot is already pending or confirmed. Please choose another available slot.'
            });
        }

        const user = await User.findById(user_id);
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        const newBooking = new Booking({
            mahal_id,
            user_id,
            user_name: user.name,
            mbl_no: user.mbl_no,
            booking_date: new Date(booking_date),
            end_date: end_date ? new Date(end_date) : new Date(booking_date),
            event_name,
            booking_type: selectedType,
            event_time,
            end_time,
            total_amt,
            initial_amt,
            booking_status: 'Pending'
        });

        await newBooking.save();

        if (mahal.mahalowner_id) {
            try {
                await notifyOwner({
                    ownerToken: mahal.mahalowner_id.fcm_token,
                    ownerId: mahal.mahalowner_id._id,
                    bookingId: newBooking._id,
                    title: 'New Booking Request',
                    body: `${user.name} requested a booking for ${event_name}.`,
                    type: 'booking_request',
                    data: {
                        user_name: user.name,
                        event_name,
                        event_date: booking_date,
                        event_time,
                        event_end_date: end_date || booking_date,
                        event_end_time: end_time
                    }
                });
            } catch (err) {
                console.error('Owner notification failed:', err);
            }
        }

        const bookingDoc = newBooking.toObject();
        return res.status(201).json({
            success: true,
            message: 'Booking created successfully',
            data: {
                ...bookingDoc,
                booking_id: newBooking._id,
                _id: newBooking._id
            }
        });
    } catch (err) {
        next(err);
    }
};

exports.getBookingHistory = async (req, res, next) => {
    try {
        const user_id = req.user.id;
        const bookings = await Booking.find({ user_id }).populate('mahal_id').sort({ _id: -1 });

        const mapped = bookings.map(b => ({
            ...b.toObject(),
            booking_id: b._id,
            mahal_name: b.mahal_id ? b.mahal_id.mahal_name : null,
            mahal_address: b.mahal_id ? b.mahal_id.street_address : null,
            city: b.mahal_id ? b.mahal_id.city : null
        }));

        return res.status(200).json({ success: true, data: mapped });
    } catch (err) {
        next(err);
    }
};

exports.acceptUserBooking = async (req, res, next) => {
    try {
        const user_id = req.user.id;
        const booking_id = req.body.booking_id || req.body.bookingId;
        if (!booking_id) return res.status(400).json({ success: false, message: 'booking_id is required' });

        const booking = await Booking.findOne({ _id: booking_id, user_id });
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (booking.booking_status === 'Confirmed') {
            return res.status(200).json({ success: true, message: 'Booking is already fully Confirmed.', data: { booking_id, booking_status: 'Confirmed' } });
        }

        if (booking.booking_status !== 'Waiting For User Confirmation' && booking.owner_decision !== 'Accepted') {
            return res.status(400).json({ success: false, message: `Cannot confirm booking with current status '${booking.booking_status}'. Waiting for Owner Approval.` });
        }

        booking.user_decision = 'Accepted';
        booking.booking_status = 'Confirmed';
        await booking.save();

        const notif = new Notification({
            user_id: booking.user_id,
            title: 'Booking Completed Successfully',
            body: 'User has confirmed the booking. Your Mahal calendar is now locked for this event.',
            type: 'booking_confirmed'
        });
        await notif.save();

        return res.status(200).json({
            success: true,
            message: 'User confirmed booking successfully. Booking is now fully Confirmed and calendar slot is locked.',
            data: { booking_id, booking_status: 'Confirmed', user_decision: 'Accepted' }
        });
    } catch (err) {
        next(err);
    }
};

exports.rejectUserBooking = async (req, res, next) => {
    try {
        const user_id = req.user.id;
        const booking_id = req.body.booking_id || req.body.bookingId;
        if (!booking_id) return res.status(400).json({ success: false, message: 'booking_id is required' });

        const booking = await Booking.findOne({ _id: booking_id, user_id });
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (booking.booking_status === 'Cancelled') {
            return res.status(200).json({ success: true, message: 'Booking is already Cancelled.', data: { booking_id, booking_status: 'Cancelled' } });
        }

        booking.user_decision = 'Rejected';
        booking.booking_status = 'Cancelled';
        await booking.save();

        const visit = await VisitingRequest.findOne({ booking_id });
        if (visit) {
            visit.visit_status = 'Expired';
            visit.qr_status = 'Expired';
            await visit.save();
        }

        const notif = new Notification({
            user_id: booking.user_id,
            title: 'Booking Cancelled',
            body: 'The customer has declined the booking. Booking cancelled. Slot released in calendar.',
            type: 'booking_cancelled'
        });
        await notif.save();

        return res.status(200).json({
            success: true,
            message: 'Booking declined by customer. Booking cancelled and slot released in calendar.',
            data: { booking_id, booking_status: 'Cancelled', user_decision: 'Rejected' }
        });
    } catch (err) {
        next(err);
    }
};

exports.getBookingStatus = async (req, res, next) => {
    try {
        const booking_id = req.query.booking_id || req.query.bookingId || req.params.booking_id;
        if (!booking_id) return res.status(400).json({ success: false, message: 'booking_id is required' });

        const booking = await Booking.findById(booking_id);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking status not found' });

        const v = await VisitingRequest.findOne({ booking_id });

        const data = {
            booking_id: booking._id,
            booking_status: booking.booking_status,
            owner_decision: booking.owner_decision,
            user_decision: booking.user_decision,
            updated_at: booking.updated_at,
            visiting_date: v ? v.visiting_date : null,
            visiting_time: v ? v.visiting_time : null,
            visit_status: v ? v.visit_status : null,
            qr_token: v ? v.qr_token : null,
            qr_status: v ? v.qr_status : null
        };

        return res.status(200).json({ success: true, data });
    } catch (err) {
        next(err);
    }
};
