const { sql, connectDB } = require('./config/db');

async function migrateVisiting() {
  try {
    await connectDB();
    console.log("Running Visiting Requests migration...");
    
    await sql.query`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VISITING_REQUESTS')
      BEGIN
          CREATE TABLE VISITING_REQUESTS (
              visit_id INT IDENTITY(1,1) PRIMARY KEY,
              booking_id INT NOT NULL,
              user_id INT NOT NULL,
              mahal_id INT NOT NULL,
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
      END
    `;
    
    console.log("Migration completed successfully. VISITING_REQUESTS table is ready.");
    process.exit(0);
  } catch (err) {
    console.error("Migration failed:", err);
    process.exit(1);
  }
}

migrateVisiting();
