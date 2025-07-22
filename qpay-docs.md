# QPay API Documentation

## Overview

QPay is Mongolia's leading payment service provider, enabling merchants to integrate QR code-based payment processing into their applications. This documentation covers both direct API integration and the official NPM package `@mnpay/qpay`.

### Key Features

- QR code payment processing
- Multiple bank integrations
- Mobile banking app deep links
- Partial payment support
- Detailed transaction tracking
- OAuth 2.0 authentication

### Environments

- **Sandbox**: `merchant-sandbox.qpay.mn`
- **Production**: `api.qpay.mn`

## Getting Started

### 1. Contact QPay

Before integration, contact QPay at `info@qpay.mn` to:

- Obtain client credentials (`client_id` and `client_secret`)
- Get access to sandbox environment
- Complete merchant onboarding

### 2. Choose Integration Method

#### Option A: Direct API Integration

Use REST API endpoints directly with HTTP requests.

#### Option B: NPM Package (@mnpay/qpay)

Use the official Node.js package for simplified integration.

```bash
npm install @mnpay/qpay
# or
yarn add @mnpay/qpay
```

## Authentication

QPay uses OAuth 2.0 with client credentials flow for API authentication.

### Generate Access Token

#### Direct API

```bash
curl -X POST https://merchant-sandbox.qpay.mn/v2/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "your_client_id",
    "client_secret": "your_client_secret"
  }'
```

#### Using NPM Package

```javascript
import { useQpay } from "@mnpay/qpay";

const qpay = useQpay({
  baseUrl: "https://merchant-sandbox.qpay.mn", // Optional, defaults to production
  version: "v2", // Optional, defaults to v2
});

// Authenticate and get access token
const authResult = await qpay.authenticate({
  client_id: "your_client_id",
  client_secret: "your_client_secret",
});
```

### Response

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### Refresh Token

#### Direct API

```bash
curl -X POST https://merchant-sandbox.qpay.mn/v2/auth/refresh \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_access_token" \
  -d '{
    "refresh_token": "your_refresh_token"
  }'
```

#### Using NPM Package

```javascript
const refreshedAuth = await qpay.refreshToken();
```

## Invoice Management

### Create Invoice

Creates a new payment invoice with QR code and deep links.

#### Direct API

```bash
curl -X POST https://merchant-sandbox.qpay.mn/v2/invoice \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_access_token" \
  -d '{
    "invoice_code": "INV_001",
    "sender_invoice_no": "MERCHANT_INV_123",
    "invoice_receiver_code": "terminal",
    "invoice_description": "Payment for services",
    "amount": 10000,
    "callback_url": "https://your-domain.com/callback"
  }'
```

#### Using NPM Package

```javascript
const invoice = await qpay.createInvoice({
  invoice_code: "INV_001",
  sender_invoice_no: "MERCHANT_INV_123",
  invoice_receiver_code: "terminal",
  invoice_description: "Payment for services",
  amount: 10000,
  callback_url: "https://your-domain.com/callback",
});
```

#### Request Parameters

| Field                   | Type   | Required | Description                           |
| ----------------------- | ------ | -------- | ------------------------------------- |
| `invoice_code`          | string | Yes      | Unique invoice identifier             |
| `sender_invoice_no`     | string | Yes      | Merchant's internal invoice number    |
| `invoice_receiver_code` | string | Yes      | Receiver code (usually "terminal")    |
| `invoice_description`   | string | Yes      | Payment description                   |
| `amount`                | number | Yes      | Payment amount in MNT                 |
| `callback_url`          | string | No       | Webhook URL for payment notifications |

#### Response

```json
{
  "invoice_id": "12345678-1234-1234-1234-123456789012",
  "qr_text": "qpay:12345678-1234-1234-1234-123456789012",
  "qr_image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "urls": [
    {
      "name": "golomtbank",
      "description": "Голомт банк",
      "logo": "https://cdn.qpay.mn/logo/golomtbank.png",
      "link": "golomt://qpay?token=12345678-1234-1234-1234-123456789012"
    },
    {
      "name": "khanbank",
      "description": "Хаан банк",
      "logo": "https://cdn.qpay.mn/logo/khanbank.png",
      "link": "khanbank://qpay?token=12345678-1234-1234-1234-123456789012"
    }
  ]
}
```

### Get Invoice Details

#### Direct API

```bash
curl -X GET https://merchant-sandbox.qpay.mn/v2/invoice/12345678-1234-1234-1234-123456789012 \
  -H "Authorization: Bearer your_access_token"
```

#### Using NPM Package

```javascript
const invoiceDetails = await qpay.getInvoice(
  "12345678-1234-1234-1234-123456789012"
);
```

### Cancel Invoice

#### Direct API

```bash
curl -X DELETE https://merchant-sandbox.qpay.mn/v2/invoice/12345678-1234-1234-1234-123456789012 \
  -H "Authorization: Bearer your_access_token"
```

#### Using NPM Package

```javascript
const cancelResult = await qpay.cancelInvoice(
  "12345678-1234-1234-1234-123456789012"
);
```

## Payment Operations

### Check Payment Status

#### Direct API

```bash
curl -X GET https://merchant-sandbox.qpay.mn/v2/payment/check/12345678-1234-1234-1234-123456789012 \
  -H "Authorization: Bearer your_access_token"
```

#### Using NPM Package

```javascript
const paymentStatus = await qpay.checkPayment(
  "12345678-1234-1234-1234-123456789012"
);
```

### Get Payment Details

#### Using NPM Package

```javascript
const paymentDetails = await qpay.getPayment("payment_id");
```

### Get Payment List

#### Using NPM Package

```javascript
const paymentList = await qpay.getPaymentList({
  page: 1,
  per_page: 20,
  start_date: "2024-01-01",
  end_date: "2024-01-31",
});
```

### Cancel Payment

#### Using NPM Package

```javascript
const cancelPayment = await qpay.cancelPayment("payment_id");
```

## Advanced Invoice Creation

### Detailed Invoice with Line Items

```javascript
const detailedInvoice = await qpay.createInvoice({
  invoice_code: "INV_002",
  sender_invoice_no: "MERCHANT_INV_456",
  invoice_receiver_code: "terminal",
  invoice_description: "Product purchase",
  amount: 25000,
  callback_url: "https://your-domain.com/webhook",
  sender_staff_name: "John Doe",
  sender_terminal_code: "POS_001",
  lines: [
    {
      line_description: "Product A",
      line_quantity: 2,
      line_unit_price: 10000,
      line_total_amount: 20000,
    },
    {
      line_description: "Product B",
      line_quantity: 1,
      line_unit_price: 5000,
      line_total_amount: 5000,
    },
  ],
  taxes: [
    {
      tax_name: "VAT",
      tax_percentage: 10,
      tax_amount: 2273,
    },
  ],
  discounts: [
    {
      discount_name: "Loyalty discount",
      discount_percentage: 5,
      discount_amount: 1136,
    },
  ],
});
```

## NPM Package Configuration

### Initialize with Configuration

```javascript
import { useQpay } from "@mnpay/qpay";

const qpay = useQpay({
  baseUrl: "https://merchant-sandbox.qpay.mn", // Optional
  version: "v2", // Optional
  accessToken: "your_existing_access_token", // Optional
  refreshToken: "your_existing_refresh_token", // Optional
  expiresIn: new Date(), // Optional
});
```

### Available Methods

| Method                       | Description            |
| ---------------------------- | ---------------------- |
| `authenticate(credentials)`  | Generate access token  |
| `refreshToken()`             | Refresh existing token |
| `createInvoice(invoiceData)` | Create payment invoice |
| `getInvoice(invoiceId)`      | Get invoice details    |
| `cancelInvoice(invoiceId)`   | Cancel invoice         |
| `getPayment(paymentId)`      | Get payment details    |
| `checkPayment(objectId)`     | Check payment status   |
| `cancelPayment(paymentId)`   | Cancel payment         |
| `getPaymentList(filters)`    | Get payment history    |

## Webhooks & Callbacks

When creating invoices, you can specify a `callback_url` to receive payment notifications.

### Webhook Payload Example

```json
{
  "object_type": "INVOICE",
  "object_id": "12345678-1234-1234-1234-123456789012",
  "payment_id": "87654321-4321-4321-4321-210987654321",
  "payment_status": "PAID",
  "payment_amount": 10000,
  "payment_date": "2024-01-15T10:30:00Z",
  "currency": "MNT"
}
```

### Webhook Security

Always verify webhook signatures to ensure requests are from QPay. Contact QPay support for webhook signature verification details.

## Error Handling

### Common Error Codes

| Code | Description      | Solution                     |
| ---- | ---------------- | ---------------------------- |
| 401  | Unauthorized     | Check access token validity  |
| 403  | Forbidden        | Verify client permissions    |
| 404  | Not Found        | Check invoice/payment ID     |
| 422  | Validation Error | Review request parameters    |
| 429  | Rate Limited     | Implement retry with backoff |
| 500  | Server Error     | Contact QPay support         |

### Error Response Format

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Invoice amount must be greater than 0",
    "details": {}
  }
}
```

### NPM Package Error Handling

```javascript
try {
  const invoice = await qpay.createInvoice(invoiceData);
} catch (error) {
  console.error("QPay Error:", error.message);
  // Handle specific error codes
  if (error.code === "INVALID_REQUEST") {
    // Handle validation error
  }
}
```

## Complete Integration Example

### Node.js Express Server

```javascript
import express from "express";
import { useQpay } from "@mnpay/qpay";

const app = express();
app.use(express.json());

// Initialize QPay
const qpay = useQpay({
  baseUrl: process.env.QPAY_BASE_URL || "https://merchant-sandbox.qpay.mn",
});

// Authenticate on startup
let isAuthenticated = false;

async function authenticate() {
  try {
    await qpay.authenticate({
      client_id: process.env.QPAY_CLIENT_ID,
      client_secret: process.env.QPAY_CLIENT_SECRET,
    });
    isAuthenticated = true;
    console.log("QPay authenticated successfully");
  } catch (error) {
    console.error("Authentication failed:", error);
  }
}

// Create payment endpoint
app.post("/create-payment", async (req, res) => {
  try {
    if (!isAuthenticated) {
      await authenticate();
    }

    const { amount, description, orderId } = req.body;

    const invoice = await qpay.createInvoice({
      invoice_code: `INV_${Date.now()}`,
      sender_invoice_no: orderId,
      invoice_receiver_code: "terminal",
      invoice_description: description,
      amount: amount,
      callback_url: `${process.env.BASE_URL}/webhook/qpay`,
    });

    res.json({
      success: true,
      invoice_id: invoice.invoice_id,
      qr_text: invoice.qr_text,
      qr_image: invoice.qr_image,
      bank_urls: invoice.urls,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message,
    });
  }
});

// Check payment status
app.get("/payment-status/:invoiceId", async (req, res) => {
  try {
    const status = await qpay.checkPayment(req.params.invoiceId);
    res.json(status);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Webhook endpoint
app.post("/webhook/qpay", (req, res) => {
  const { object_id, payment_status, payment_amount } = req.body;

  // Process payment notification
  console.log(
    `Payment ${object_id}: ${payment_status} - ${payment_amount} MNT`
  );

  // Update your database here
  // updatePaymentStatus(object_id, payment_status);

  res.status(200).send("OK");
});

// Initialize
authenticate();

app.listen(3000, () => {
  console.log("Server running on port 3000");
});
```

## Testing

### Sandbox Testing

1. Use sandbox environment: `merchant-sandbox.qpay.mn`
2. Test with sandbox client credentials
3. Use test bank accounts for payment simulation

### Mobile App Testing

- Install bank mobile apps on test devices
- Test deep link functionality with generated URLs
- Verify QR code scanning works correctly

## Production Deployment

### Environment Variables

```bash
QPAY_CLIENT_ID=your_production_client_id
QPAY_CLIENT_SECRET=your_production_client_secret
QPAY_BASE_URL=https://api.qpay.mn
BASE_URL=https://your-domain.com
```

### Security Considerations

- Store credentials securely (use environment variables)
- Implement webhook signature verification
- Use HTTPS for all communications
- Log transactions for audit purposes
- Implement rate limiting
- Set up monitoring and alerting

## Support & Resources

- **Official Documentation**: https://developer.qpay.mn/
- **NPM Package**: https://www.npmjs.com/package/@mnpay/qpay
- **Contact**: info@qpay.mn
- **Environment**: Sandbox and Production available

## Package Information

- **Package Name**: @mnpay/qpay
- **Version**: 0.1.9
- **License**: MIT
- **Dependencies**: axios, zod
- **TypeScript**: Supported

---

_This documentation covers QPay API integration for developers building payment solutions in Mongolia. For the most up-to-date information, always refer to the official QPay developer documentation._
