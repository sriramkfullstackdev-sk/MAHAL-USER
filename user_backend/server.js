const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
require("dotenv").config();

const { connectDB } = require("./config/db");
const errorHandler = require("./middleware/errorHandler");
const { autoCancelExpiredVisits } = require("./utils/autoCancelWorker");

// Register Mongoose models before populating refs like MahalOwner / Booking / User
require("./models/User");
require("./models/MahalOwner");
require("./models/Mahal");
require("./models/Booking");
require("./models/VisitingRequest");
require("./models/Notification");
require("./models/Payment");

// Import Routes
const authRoutes = require("./routes/authRoutes");
const mahalRoutes = require("./routes/mahalRoutes");
const bookingRoutes = require("./routes/bookingRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const visitingRoutes = require("./routes/visitingRoutes");
const qrRoutes = require("./routes/qrRoutes");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev')); // Logging

// Connect to Database
connectDB();

// Mount Routes
app.use("/api/auth", authRoutes);
app.use("/api/mahals", mahalRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/booking", bookingRoutes); // Prompt endpoint GET /booking/status
app.use("/user", bookingRoutes); // Prompt endpoints POST /user/accept-booking, POST /user/reject-booking
app.use("/api/user", bookingRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/visiting", visitingRoutes);
app.use("/api/qr", qrRoutes);

// Global Error Handler
app.use(errorHandler);

// Prevent process exit on uncaught errors
process.on("uncaughtException", (err) => {
    console.error("Uncaught Exception in user_backend:", err);
});

process.on("unhandledRejection", (reason, promise) => {
    console.error("Unhandled Rejection in user_backend at:", promise, "reason:", reason);
});

// Start Background Auto-Cancellation Worker (runs every 30 seconds)
setInterval(() => {
    try {
        autoCancelExpiredVisits();
    } catch (e) {
        console.error("Error in autoCancelExpiredVisits worker:", e);
    }
}, 30000);

const PORT = process.env.PORT || 3001;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server Running on Port ${PORT} and accepting connections from any IP`);
});