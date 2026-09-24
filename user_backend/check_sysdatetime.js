const { sql, connectDB } = require('./config/db');

async function checkSysDateTime() {
  try {
    await connectDB();
    const res = await sql.query`SELECT SYSDATETIME() as sys_dt, GETDATE() as get_dt, GETUTCDATE() as utc_dt`;
    console.log("SQL SERVER TIMES:");
    console.log("SYSDATETIME():", res.recordset[0].sys_dt);
    console.log("GETDATE():", res.recordset[0].get_dt);
    console.log("GETUTCDATE():", res.recordset[0].utc_dt);
    console.log("NODE LOCAL TIME:", new Date().toString());
    console.log("NODE ISO TIME:", new Date().toISOString());

    const visits = await sql.query`SELECT TOP 5 visit_id, booking_id, visiting_date, visiting_time, payment_time, expiry_time, visit_status, booking_status FROM VISITING_REQUESTS ORDER BY visit_id DESC`;
    console.log("\nRECENT VISITING REQUESTS IN DB:");
    console.log(JSON.stringify(visits.recordset, null, 2));

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

checkSysDateTime();
