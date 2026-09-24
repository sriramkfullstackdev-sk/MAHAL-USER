require('dotenv').config();
const { sql, connectDB } = require('./config/db');
async function run() {
    await connectDB();
    const res = await sql.query("SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'BOOKINGS'");
    console.log("BOOKINGS COLUMNS:");
    console.log(JSON.stringify(res.recordset, null, 2));

    const res2 = await sql.query("SELECT TOP 5 * FROM BOOKINGS");
    console.log("SAMPLE BOOKINGS:");
    console.log(JSON.stringify(res2.recordset, null, 2));
    
    process.exit(0);
}
run();
