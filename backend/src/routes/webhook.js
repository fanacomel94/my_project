const express = require('express');
const whatsappService = require('../services/whatsappService');
const logger = require('../utils/logger');

const router = express.Router();

// Webhook verification endpoint
router.get('/', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  logger.info(`Webhook verification request: mode=${mode}, token=${token}`);

  if (mode === 'subscribe' && whatsappService.validateWebhookToken(token)) {
    res.status(200).send(challenge);
    logger.info('Webhook verified successfully');
  } else {
    res.status(403).json({ error: 'Webhook verification failed' });
    logger.error('Webhook verification failed');
  }
});

// Webhook event handler
router.post('/', (req, res) => {
  const body = req.body;

  if (body.object === 'whatsapp_business_account') {
    if (body.entry && body.entry[0] && body.entry[0].changes && body.entry[0].changes[0]) {
      const change = body.entry[0].changes[0];

      if (change.field === 'messages') {
        const message = change.value.messages[0];
        logger.info(`Received message: ${JSON.stringify(message)}`);

        // Handle incoming message
        if (message.type === 'text') {
          logger.info(`Text message from ${message.from}: ${message.text.body}`);
        } else if (message.type === 'image') {
          logger.info(`Image message from ${message.from}`);
        } else if (message.type === 'document') {
          logger.info(`Document message from ${message.from}`);
        }
      }

      if (change.field === 'message_status') {
        const status = change.value.statuses[0];
        logger.info(`Message status update: ${status.id} - ${status.status}`);

        // Handle message status changes
        if (status.status === 'delivered') {
          logger.info(`Message ${status.id} delivered`);
        } else if (status.status === 'read') {
          logger.info(`Message ${status.id} read`);
        }
      }
    }

    res.status(200).json({ received: true });
  } else {
    res.status(404).json({ error: 'Not a WhatsApp webhook' });
  }
});

module.exports = router;
