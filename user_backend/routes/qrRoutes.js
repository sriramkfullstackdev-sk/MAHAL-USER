const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const qrController = require('../controllers/qrController');

router.post('/generate', auth, qrController.generateQr);
router.get('/download', auth, qrController.downloadQr);
router.post('/verify', qrController.verifyQr);
router.post('/scan', qrController.scanQr);

module.exports = router;
