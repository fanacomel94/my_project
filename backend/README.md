# WA-Shield Backend

Node.js + Express backend for WA-Shield with WhatsApp Cloud API integration.

## Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Variables

Create a `.env` file in the `backend/` directory:

```env
# Server
PORT=3000
NODE_ENV=development
LOG_LEVEL=info

# WhatsApp Cloud API
WHATSAPP_API_URL=https://graph.instagram.com/v18.0
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id_here
WHATSAPP_ACCESS_TOKEN=your_access_token_here
WHATSAPP_WEBHOOK_VERIFY_TOKEN=washield_verify_token
```

**How to get WhatsApp credentials:**
1. Create a Meta Business Account at https://business.facebook.com
2. Create a WhatsApp Business App
3. Get your Phone Number ID from WhatsApp Business Settings
4. Generate a permanent access token from App Settings
5. Set up a webhook for incoming messages

### 3. Start the Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

Server will run on `http://localhost:3000`

## API Endpoints

### WhatsApp API

- **GET** `/api/whatsapp/phone-info` - Get phone number info
- **POST** `/api/whatsapp/send` - Send encrypted message via WhatsApp
  ```json
  {
    "phoneNumber": "+1234567890",
    "message": "your_encrypted_message_here",
    "messageType": "text"
  }
  ```
- **GET** `/api/whatsapp/message-status/:messageId` - Get message status
- **POST** `/api/whatsapp/mark-as-read` - Mark message as read
  ```json
  {
    "messageId": "message_id_here"
  }
  ```

### Messages API

- **POST** `/api/messages` - Store encrypted message
  ```json
  {
    "sender": "user_id",
    "recipient": "recipient_id",
    "encryptedContent": "base64_encrypted_payload",
    "timestamp": "2025-01-01T00:00:00Z"
  }
  ```
- **GET** `/api/messages` - Retrieve messages (supports `sender`, `recipient`, `limit` query params)
- **GET** `/api/messages/:messageId` - Get single message
- **PUT** `/api/messages/:messageId` - Mark message as read
- **DELETE** `/api/messages/:messageId` - Delete message

### Webhook

- **GET** `/webhook` - Webhook verification (for WhatsApp setup)
- **POST** `/webhook` - Receive incoming messages and status updates from WhatsApp

## Project Structure

```
backend/
├── src/
│   ├── index.js                 # Express app entry point
│   ├── services/
│   │   └── whatsappService.js   # WhatsApp Cloud API service
│   ├── routes/
│   │   ├── whatsapp.js          # WhatsApp API routes
│   │   ├── messages.js          # Message storage routes
│   │   └── webhook.js           # Webhook routes
│   └── utils/
│       └── logger.js            # Winston logger setup
├── package.json
├── .env                         # Environment variables (create this)
└── README.md
```

## Security Notes

- Always use HTTPS in production
- Store sensitive data (access tokens, phone numbers) in environment variables
- Implement rate limiting for production
- Use a database (MongoDB, PostgreSQL) instead of in-memory storage for production
- Validate and sanitize all incoming data
- Use JWT or API keys for client authentication

## Next Steps

1. Set up WhatsApp Cloud API credentials
2. Deploy to a platform (Heroku, AWS, Google Cloud, etc.)
3. Replace in-memory message store with a database
4. Add authentication for Flutter app to backend
5. Implement message encryption/decryption on the backend
6. Add more robust error handling and validation
