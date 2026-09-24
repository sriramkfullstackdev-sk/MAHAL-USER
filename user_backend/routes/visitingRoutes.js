const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const visitingController = require('../controllers/visitingController');

router.post('/save', auth, visitingController.saveVisitingTime);
router.get('/details', auth, visitingController.getVisitingDetails);

module.exports = router;
