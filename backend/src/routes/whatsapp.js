const express = require('express');
const whatsappService = require('../services/whatsappService');
const logger = require('../utils/logger');

const router = express.Router();

// GET /api/whatsapp/phone-info
router.get('/phone-info', async (req, res) => {
  try {
    const phoneInfo = await whatsappService.getPhoneNumberInfo();
    res.status(200).json({ success: true, data: phoneInfo });
  } catch (error) {
    logger.error(`Error fetching phone info: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/whatsapp/send
router.post('/send', async (req, res) => {
  try {
    const { phoneNumber, message, messageType = 'text' } = req.body;

    if (!phoneNumber || !message) {
      return res.status(400).json({ success: false, error: 'Missing phoneNumber or message' });
    }

    const result = await whatsappService.sendMessage(phoneNumber, message, messageType);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    logger.error(`Error sending message: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/whatsapp/message-status/:messageId
router.get('/message-status/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    const status = await whatsappService.getMessageStatus(messageId);
    res.status(200).json({ success: true, data: status });
  } catch (error) {
    logger.error(`Error fetching message status: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/whatsapp/mark-as-read
router.post('/mark-as-read', async (req, res) => {
  try {
    const { messageId } = req.body;

    if (!messageId) {
      return res.status(400).json({ success: false, error: 'Missing messageId' });
    }

    const result = await whatsappService.markMessageAsRead(messageId);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    logger.error(`Error marking message as read: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
