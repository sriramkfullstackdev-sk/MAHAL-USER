require('dotenv').config();
const { sql, connectDB } = require('./config/db');

async function updateSchema() {
    try {
        await connectDB();
        
        const queries = [
            `IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'USERS' AND COLUMN_NAME = 'fcm_token')
             ALTER TABLE USERS ADD fcm_token VARCHAR(500) NULL`,
            `IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MAHALOWNER' AND COLUMN_NAME = 'fcm_token')
             ALTER TABLE MAHALOWNER ADD fcm_token VARCHAR(500) NULL`,
            "ALTER TABLE MAHAL ADD mahal_images_2 VARBINARY(MAX)",
            "ALTER TABLE MAHAL ADD mahal_images_3 VARBINARY(MAX)",
            "ALTER TABLE MAHAL ADD mahal_images_4 VARBINARY(MAX)",
            "ALTER TABLE MAHAL ADD mahal_images_5 VARBINARY(MAX)",
            "ALTER TABLE MAHAL ADD mahal_images_6 VARBINARY(MAX)"
        ];
        
        for (const query of queries) {
            try {
                await sql.query(query);
                console.log("Executed: " + query);
            } catch (err) {
                if (err.message.includes('already exists')) {
                    console.log("Column already exists, skipping: " + query);
                } else {
                    console.error("Error executing query: " + query, err);
                }
            }
        }
        console.log("Schema update complete.");
        process.exit(0);
    } catch (e) {
        console.error("DB connection error:", e);
        process.exit(1);
    }
}

updateSchema();
