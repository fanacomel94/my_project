require('dotenv').config();
const axios = require('axios');
const logger = require('../utils/logger');

const WHATSAPP_API_URL = process.env.WHATSAPP_API_URL || 'https://graph.instagram.com/v18.0';
const PHONE_NUMBER_ID = process.env.PHONE_NUMBER_ID;
const ACCESS_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;

class WhatsAppService {
  constructor() {
    if (!PHONE_NUMBER_ID || !ACCESS_TOKEN) {
      logger.error('Missing WHATSAPP_PHONE_NUMBER_ID or WHATSAPP_ACCESS_TOKEN environment variables');
    }
  }

  async sendMessage(recipientPhoneNumber, message, messageType = 'text') {
    try {
      const url = `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`;
      
      const payload = {
        messaging_product: 'whatsapp',
        to: recipientPhoneNumber,
        type: messageType,
      };

      if (messageType === 'text') {
        payload.text = { body: message };
      } else if (messageType === 'image') {
        payload.image = { link: message };
      } else if (messageType === 'document') {
        payload.document = { link: message };
      }

      const config = {
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
          'Content-Type': 'application/json',
        },
      };

      const response = await axios.post(url, payload, config);
      logger.info(`Message sent to ${recipientPhoneNumber}: ${response.data.messages[0].id}`);
      return response.data;
    } catch (error) {
      logger.error(`Failed to send message: ${error.message}`);
      throw error;
    }
  }

  async getMessageStatus(messageId) {
    try {
      const url = `${WHATSAPP_API_URL}/${messageId}`;
      const config = {
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
        },
        params: {
          fields: 'status,timestamp',
        },
      };

      const response = await axios.get(url, config);
      return response.data;
    } catch (error) {
      logger.error(`Failed to get message status: ${error.message}`);
      throw error;
    }
  }

  async markMessageAsRead(messageId) {
    try {
      const url = `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`;
      const payload = {
        messaging_product: 'whatsapp',
        status: 'read',
        message_id: messageId,
      };

      const config = {
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
          'Content-Type': 'application/json',
        },
      };

      const response = await axios.post(url, payload, config);
      return response.data;
    } catch (error) {
      logger.error(`Failed to mark message as read: ${error.message}`);
      throw error;
    }
  }

  async getPhoneNumberInfo() {
    try {
      const url = `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}`;
      const config = {
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
        },
      };

      const response = await axios.get(url, config);
      return response.data;
    } catch (error) {
      logger.error(`Failed to get phone number info: ${error.message}`);
      throw error;
    }
  }

  validateWebhookToken(providedToken) {
    const verifyToken = process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN || 'washield_verify_token';
    return providedToken === verifyToken;
  }
}

module.exports = new WhatsAppService();
