const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const visitingController = require('../controllers/visitingController');
const { handleAutoCancelEndpoint } = require('../utils/autoCancelWorker');
const auth = require('../middleware/auth');

router.get('/availability', bookingController.checkAvailability);
router.post('/', auth, bookingController.createBooking);
router.get('/history', auth, bookingController.getBookingHistory);

// Status endpoint
router.get('/status', bookingController.getBookingStatus);
router.get('/visit-status', auth, visitingController.getVisitStatus);

// User Accept / Reject endpoints
router.post('/user/accept', auth, bookingController.acceptUserBooking);
router.post('/user/reject', auth, bookingController.rejectUserBooking);
router.post('/accept-booking', auth, bookingController.acceptUserBooking);
router.post('/reject-booking', auth, bookingController.rejectUserBooking);

// Auto-cancellation
router.post('/auto-cancel', handleAutoCancelEndpoint);

module.exports = router;
