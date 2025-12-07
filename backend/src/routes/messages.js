const express = require('express');
const logger = require('../utils/logger');

const router = express.Router();

// In-memory message store (replace with database in production)
const messageStore = [];

// POST /api/messages - Store encrypted message
router.post('/', (req, res) => {
  try {
    const { sender, recipient, encryptedContent, timestamp, messageId } = req.body;

    if (!sender || !recipient || !encryptedContent) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const message = {
      id: messageId || `msg_${Date.now()}`,
      sender,
      recipient,
      encryptedContent,
      timestamp: timestamp || new Date().toISOString(),
      read: false,
    };

    messageStore.push(message);
    logger.info(`Message stored: ${message.id}`);

    res.status(201).json({ success: true, data: message });
  } catch (error) {
    logger.error(`Error storing message: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/messages - Retrieve messages (with optional filters)
router.get('/', (req, res) => {
  try {
    const { sender, recipient, limit = 50 } = req.query;

    let filtered = messageStore;

    if (sender) {
      filtered = filtered.filter(m => m.sender === sender);
    }
    if (recipient) {
      filtered = filtered.filter(m => m.recipient === recipient);
    }

    const results = filtered.slice(-limit);
    res.status(200).json({ success: true, data: results });
  } catch (error) {
    logger.error(`Error retrieving messages: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/messages/:messageId - Get single message
router.get('/:messageId', (req, res) => {
  try {
    const { messageId } = req.params;
    const message = messageStore.find(m => m.id === messageId);

    if (!message) {
      return res.status(404).json({ success: false, error: 'Message not found' });
    }

    res.status(200).json({ success: true, data: message });
  } catch (error) {
    logger.error(`Error fetching message: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// PUT /api/messages/:messageId - Mark message as read
router.put('/:messageId', (req, res) => {
  try {
    const { messageId } = req.params;
    const message = messageStore.find(m => m.id === messageId);

    if (!message) {
      return res.status(404).json({ success: false, error: 'Message not found' });
    }

    message.read = true;
    res.status(200).json({ success: true, data: message });
  } catch (error) {
    logger.error(`Error updating message: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

// DELETE /api/messages/:messageId - Delete message
router.delete('/:messageId', (req, res) => {
  try {
    const { messageId } = req.params;
    const index = messageStore.findIndex(m => m.id === messageId);

    if (index === -1) {
      return res.status(404).json({ success: false, error: 'Message not found' });
    }

    messageStore.splice(index, 1);
    res.status(200).json({ success: true, message: 'Message deleted' });
  } catch (error) {
    logger.error(`Error deleting message: ${error.message}`);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
