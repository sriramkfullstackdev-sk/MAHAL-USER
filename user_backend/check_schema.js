require('dotenv').config();
const {sql} = require('./config/db');
async function run() {
    await sql.connect();
    const res = await sql.query("SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MAHAL'");
    console.log(JSON.stringify(res.recordset, null, 2));
    
    // Also check if there's any other table for photos
    const res2 = await sql.query("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%PHOTO%' OR TABLE_NAME LIKE '%IMAGE%'");
    console.log(JSON.stringify(res2.recordset, null, 2));

    process.exit(0);
}
run();
