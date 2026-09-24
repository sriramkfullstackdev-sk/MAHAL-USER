const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function initializeFirebase() {
    if (admin.apps.length > 0) return;

    const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
        path.join(__dirname, 'serviceAccountKey.json');

    if (fs.existsSync(serviceAccountPath)) {
        const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id
        });
        return;
    }

    admin.initializeApp({ credential: admin.credential.applicationDefault() });
}

async function notifyOwnerOfBookingRequest({ ownerToken, ownerId, bookingId, userName, eventName, eventDate, eventTime, eventEndDate, eventEndTime, visitingDate, visitingTime }) {
    return notifyOwner({
        ownerToken,
        ownerId,
        bookingId,
        title: 'New Booking Request',
        body: `${userName} requested a booking for ${eventName}.`,
        type: 'booking_request',
        data: {
            user_name: userName,
            event_name: eventName,
            event_date: eventDate,
            event_time: eventTime,
            event_end_date: eventEndDate || eventDate,
            event_end_time: eventEndTime,
            visiting_date: visitingDate,
            visiting_time: visitingTime
        }
    });
}

async function notifyOwner({ ownerToken, ownerId, bookingId, title, body, type = 'booking', data = {} }) {
    if (!ownerToken) return { sent: false, reason: 'Owner FCM token is missing' };

    initializeFirebase();
    const messageId = await admin.messaging().send({
        token: ownerToken,
        notification: { title, body },
        data: {
            type,
            owner_id: String(ownerId || ''),
            booking_id: String(bookingId || ''),
            title,
            body,
            ...Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value || '')]))
        }
    });

    return { sent: true, messageId };
}

module.exports = { notifyOwnerOfBookingRequest, notifyOwner };