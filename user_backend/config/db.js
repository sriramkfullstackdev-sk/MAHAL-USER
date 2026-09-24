const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
    try {
        const mongoURI = process.env.MONGODB_URI;
        await mongoose.connect(mongoURI);
        console.log("MongoDB Connected");
    } catch (err) {
        console.error("MongoDB Connection Error: ", err);
        process.exit(1);
    }
};

module.exports = { connectDB };