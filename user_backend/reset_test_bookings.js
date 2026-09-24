const { sql, connectDB } = require('./config/db');

async function resetTestBookings() {
  try {
    await connectDB();
    console.log("Resetting test bookings...");
    
    // Set non-cancelled visiting requests back to Scheduled & Confirmed for testing
    await sql.query`
      UPDATE BOOKINGS 
      SET booking_status = 'Confirmed' 
      WHERE booking_id IN (SELECT booking_id FROM PAYMENTS);

      UPDATE VISITING_REQUESTS 
      SET visit_status = 'Scheduled', booking_status = 'Confirmed'
      WHERE expiry_time > SYSDATETIME();
    `;
    
    console.log("Test bookings reset successfully.");
    process.exit(0);
  } catch (err) {
    console.error("Reset failed:", err);
    process.exit(1);
  }
}

resetTestBookings();
