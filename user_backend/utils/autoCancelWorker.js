const { sql } = require('../config/db');

async function autoCancelExpiredVisits() {
    try {
        // Find all scheduled visiting requests whose expiry time has passed
        const expiredRes = await sql.query`
            SELECT v.visit_id, v.booking_id, v.user_id, v.mahal_id, b.user_name, m.mahal_name 
            FROM VISITING_REQUESTS v
            JOIN BOOKINGS b ON v.booking_id = b.booking_id
            JOIN MAHAL m ON v.mahal_id = m.mahal_id
            WHERE v.visit_status = 'Scheduled' AND v.expiry_time <= SYSDATETIME()
        `;

        if (expiredRes.recordset.length === 0) return;

        console.log(`[Auto-Cancel Worker] Found ${expiredRes.recordset.length} expired visiting request(s). Cancelling...`);

        for (const item of expiredRes.recordset) {
            await sql.query`
                UPDATE VISITING_REQUESTS 
                SET visit_status = 'Expired', booking_status = 'Cancelled' 
                WHERE visit_id = ${item.visit_id};

                UPDATE BOOKINGS 
                SET booking_status = 'Cancelled' 
                WHERE booking_id = ${item.booking_id};
            `;

            console.log(`[Auto-Cancel Worker] Booking ID ${item.booking_id} cancelled automatically due to QR expiry.`);
        }
    } catch (err) {
        console.error('[Auto-Cancel Worker Error]:', err.message);
    }
}

// Controller endpoint handler for POST /api/booking/auto-cancel
async function handleAutoCancelEndpoint(req, res, next) {
    try {
        await autoCancelExpiredVisits();
        return res.status(200).json({
            success: true,
            message: 'Auto-cancellation check executed successfully'
        });
    } catch (err) {
        next(err);
    }
}

module.exports = {
    autoCancelExpiredVisits,
    handleAutoCancelEndpoint
};
