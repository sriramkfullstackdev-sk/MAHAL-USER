const { sql, connectDB } = require('./config/db');

async function fixVisitingSchema() {
  try {
    await connectDB();
    console.log("Fixing VISITING_REQUESTS table column types...");
    
    // Drop table if exists and recreate with VARCHAR for booking_id, user_id, mahal_id
    await sql.query`
      IF EXISTS (SELECT * FROM sys.tables WHERE name = 'VISITING_REQUESTS')
      BEGIN
          DROP TABLE VISITING_REQUESTS;
      END

      CREATE TABLE VISITING_REQUESTS (
          visit_id INT IDENTITY(1,1) PRIMARY KEY,
          booking_id VARCHAR(255) NOT NULL,
          user_id VARCHAR(255) NOT NULL,
          mahal_id VARCHAR(255) NOT NULL,
          visiting_date DATE NOT NULL,
          visiting_time VARCHAR(50) NOT NULL,
          payment_time DATETIME2 NOT NULL,
          expiry_time DATETIME2 NOT NULL,
          visit_status VARCHAR(50) DEFAULT 'Scheduled',
          booking_status VARCHAR(50) DEFAULT 'Confirmed',
          qr_token VARCHAR(255) UNIQUE NOT NULL,
          qr_expiry DATETIME2 NOT NULL,
          qr_scan_time DATETIME2 NULL,
          user_notified_30m BIT DEFAULT 0,
          created_at DATETIME2 DEFAULT SYSDATETIME()
      );
    `;
    
    console.log("VISITING_REQUESTS table recreated with VARCHAR(255) for IDs successfully.");
    process.exit(0);
  } catch (err) {
    console.error("Schema fix failed:", err);
    process.exit(1);
  }
}

fixVisitingSchema();
