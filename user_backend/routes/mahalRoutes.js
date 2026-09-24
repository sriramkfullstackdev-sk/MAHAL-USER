const express = require('express');
const router = express.Router();
const mahalController = require('../controllers/mahalController');

router.get('/', mahalController.getAllMahals);
router.get('/:id/default-timings', mahalController.getDefaultTimings);
router.get('/:id/timing-by-type', mahalController.getTimingByBookingType);
router.get('/:id', mahalController.getMahalById);

module.exports = router;
