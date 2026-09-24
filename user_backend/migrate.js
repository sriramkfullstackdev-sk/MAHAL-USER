const { sql, connectDB } = require('./config/db');

async function migrate() {
  try {
    await connectDB();
    console.log("Running migration...");
    
    // Add columns if they do not exist
    await sql.query`
      IF COL_LENGTH('BOOKINGS', 'end_date') IS NULL
      BEGIN
          ALTER TABLE BOOKINGS
          ADD end_date DATE, end_time VARCHAR(255)
      END
    `;
    
    console.log("Migration completed.");
    process.exit(0);
  } catch (err) {
    console.error("Migration failed:", err);
    process.exit(1);
  }
}

migrate();
