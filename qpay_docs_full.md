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

Obtain access token using client_id and client_secret provided by QPay.

#### Endpoint

```
POST https://merchant-sandbox.qpay.mn/v2/auth/token
```

#### Direct API

```bash
curl --location --request POST 'https://merchant-sandbox.qpay.mn/v2/auth/token' \
--header 'Authorization: Basic' \
--data ''
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

Refresh access token using refresh_token.

#### Endpoint

```
POST https://merchant-sandbox.qpay.mn/v2/auth/refresh
```

#### Direct API

```bash
curl --location --request POST 'https://merchant-sandbox.qpay.mn/v2/auth/refresh' \
--header 'Authorization: Bearer'
```

#### Using NPM Package

```javascript
const refreshedAuth = await qpay.refreshToken();
```

## Invoice Management

### Create Invoice

Creates a new payment invoice with QR code and deep links. The `invoice_code` is provided by QPay.

#### Endpoint

```
POST https://merchant-sandbox.qpay.mn/v2/invoice
```

#### Request Parameters (Full)

| Field                   | Required | Type   | Max Length | Description                         | Example                      |
| ----------------------- | -------- | ------ | ---------- | ----------------------------------- | ---------------------------- |
| `invoice_code`          | Yes      | string | 45         | Invoice code provided by QPay       | TEST_INVOICE                 |
| `sender_invoice_no`     | Yes      | string | 45         | Unique invoice number from merchant | 123                          |
| `sender_branch_code`    | No       | string | 45         | Merchant branch code                | branch_01                    |
| `sender_branch_data`    | No       | object | -          | Merchant branch information         | -                            |
| `sender_staff_code`     | No       | string | 100        | Unique staff code                   | staff_01                     |
| `sender_staff_data`     | No       | object | -          | Staff information                   | -                            |
| `sender_terminal_code`  | No       | string | 45         | Terminal code                       | terminal_01                  |
| `sender_terminal_data`  | No       | object | -          | Terminal information                | -                            |
| `invoice_receiver_code` | Yes      | string | 45         | Unique customer code                | ТБ82045421                   |
| `invoice_receiver_data` | No       | object | -          | Customer information                | -                            |
| `invoice_description`   | Yes      | string | 255        | Invoice description                 | Чихэр 5ш                     |
| `invoice_due_date`      | No       | date   | -          | Invoice due date                    | -                            |
| `enable_expiry`         | No       | bool   | -          | Allow payment after expiry          | FALSE                        |
| `expiry_date`           | No       | date   | -          | Invoice expiry date                 | -                            |
| `calculate_vat`         | No       | bool   | -          | VAT calculation                     | FALSE                        |
| `tax_customer_code`     | No       | string | -          | Tax customer code                   | -                            |
| `line_tax_code`         | No       | string | -          | Product tax code                    | 83051                        |
| `allow_partial`         | No       | bool   | -          | Allow partial payments              | FALSE                        |
| `minimum_amount`        | No       | number | -          | Minimum payment amount              | -                            |
| `allow_exceed`          | No       | bool   | -          | Allow overpayment                   | FALSE                        |
| `maximum_amount`        | No       | number | -          | Maximum payment amount              | -                            |
| `amount`                | No       | number | -          | Total amount                        | 100                          |
| `callback_url`          | No       | string | 255        | Payment notification URL            | https://example.com/callback |
| `note`                  | No       | string | 1000       | Note                                | -                            |
| `lines`                 | No       | array  | -          | Invoice line items                  | -                            |
| `transactions`          | No       | array  | -          | Transactions                        | -                            |

#### Sender Branch Data (`sender_branch_data`)

| Field      | Required | Type   | Max Length | Description            | Example         |
| ---------- | -------- | ------ | ---------- | ---------------------- | --------------- |
| `register` | No       | string | 20         | Branch register number | 121232          |
| `name`     | No       | string | 100        | Branch name            | Баянзүрх салбар |
| `email`    | No       | string | 255        | Branch email           | sample@info.mn  |
| `phone`    | No       | string | 20         | Branch phone           | 99119911        |
| `address`  | No       | object | -          | Address                | -               |

#### Address Object

| Field       | Required | Type   | Max Length | Description | Example      |
| ----------- | -------- | ------ | ---------- | ----------- | ------------ |
| `city`      | No       | string | 100        | City        | Ulaanbaatar  |
| `district`  | No       | string | 100        | District    | Sukhbaatar   |
| `street`    | No       | string | 100        | Street      | Olimp street |
| `building`  | No       | string | 100        | Building    | Ayud         |
| `address`   | No       | string | 100        | Address     | 1505         |
| `zipcode`   | No       | string | 20         | Zip code    | 14240        |
| `longitude` | No       | string | 20         | Longitude   | 47.91503215  |
| `latitude`  | No       | string | 20         | Latitude    | 106.9182065  |

#### Sender Terminal Data (`sender_terminal_data`)

| Field  | Required | Type   | Max Length | Description   | Example        |
| ------ | -------- | ------ | ---------- | ------------- | -------------- |
| `name` | No       | string | 100        | Terminal name | Терминалын нэр |

#### Invoice Receiver Data (`invoice_receiver_data`)

| Field      | Required | Type   | Max Length | Description              | Example      |
| ---------- | -------- | ------ | ---------- | ------------------------ | ------------ |
| `register` | No       | string | 20         | Customer register number | TA89102712   |
| `name`     | No       | string | 100        | Customer name            | Бат          |
| `email`    | No       | string | 255        | Customer email           | info@info.mn |
| `phone`    | No       | string | 20         | Customer phone           | 99887766     |
| `address`  | No       | object | -          | Customer address         | -            |

#### Line Items (`lines[]`)

| Field                 | Required | Type   | Max Length | Description           | Example             |
| --------------------- | -------- | ------ | ---------- | --------------------- | ------------------- |
| `sender_product_code` | No       | string | 45         | Internal product code | Product_01          |
| `tax_product_code`    | No       | string | 45         | Tax product code      | 83051               |
| `line_description`    | Yes      | string | 255        | Line description      | Invoice description |
| `line_quantity`       | Yes      | number | -          | Quantity              | 1                   |
| `line_unit_price`     | Yes      | number | -          | Unit price            | 10000               |
| `note`                | No       | string | -          | Note                  | -                   |
| `discounts`           | No       | array  | -          | Discounts             | -                   |
| `surcharges`          | No       | array  | -          | Surcharges            | -                   |
| `taxes`               | No       | array  | -          | Taxes                 | -                   |

#### Discounts (`discounts[]`)

| Field           | Required | Type   | Max Length | Description   | Example        |
| --------------- | -------- | ------ | ---------- | ------------- | -------------- |
| `discount_code` | No       | string | 45         | Discount code | Discount_01    |
| `description`   | Yes      | string | 100        | Description   | uPoint хямдрал |
| `amount`        | Yes      | number | -          | Amount        | 100            |
| `note`          | No       | string | -          | Note          | тэмдэглэл      |

#### Surcharges (`surcharges[]`)

| Field            | Required | Type   | Max Length | Description    | Example           |
| ---------------- | -------- | ------ | ---------- | -------------- | ----------------- |
| `surcharge_code` | No       | string | 45         | Surcharge code | Surcharge_01      |
| `description`    | Yes      | string | 100        | Description    | Хүргэлтийн зардал |
| `amount`         | Yes      | number | -          | Amount         | 100               |
| `note`           | No       | string | -          | Note           | тэмдэглэл         |

#### Taxes (`taxes[]`)

| Field         | Required | Type   | Max Length | Description              | Example   |
| ------------- | -------- | ------ | ---------- | ------------------------ | --------- |
| `tax_code`    | No       | string | -          | Tax code (CITY_TAX, VAT) | VAT       |
| `description` | Yes      | string | 100        | Description              | НӨАТ      |
| `amount`      | Yes      | number | -          | Amount                   | 100       |
| `city_tax`    | No       | number | -          | City tax                 | -         |
| `note`        | No       | string | -          | Note                     | тэмдэглэл |

#### Transactions (`transactions[]`)

| Field         | Required | Type   | Max Length | Description             | Example     |
| ------------- | -------- | ------ | ---------- | ----------------------- | ----------- |
| `description` | Yes      | string | 100        | Transaction description | Тест төлбөр |
| `amount`      | Yes      | number | -          | Amount                  | 100         |
| `accounts`    | No       | array  | -          | Bank accounts           | -           |

#### Accounts (`accounts[]`)

| Field               | Required | Type   | Max Length | Description    | Example            |
| ------------------- | -------- | ------ | ---------- | -------------- | ------------------ |
| `account_bank_code` | Yes      | string | -          | Bank code      | -                  |
| `account_number`    | Yes      | string | 100        | Account number | 50****\*\*\*\***** |
| `account_name`      | Yes      | string | 100        | Account name   | ККТТ               |
| `account_currency`  | Yes      | string | -          | Currency       | MNT                |

#### Direct API (Detailed Example)

```bash
curl --location 'https://merchant-sandbox.qpay.mn/v2/invoice' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer your_access_token' \
--data-raw '{
    "invoice_code": "TEST_INVOICE",
    "sender_invoice_no": "9329873948",
    "sender_branch_code": "branch",
    "invoice_receiver_code": "terminal",
    "invoice_receiver_data":{
        "register":"TA89102712",
        "name":"Бат",
        "email":"info@info.mn",
        "phone":"99887766"
    },
    "invoice_description": "Invoice description",
    "invoice_due_date": null,
    "allow_partial": false,
    "minimum_amount": null,
    "allow_exceed": false,
    "maximum_amount": null,
    "note": null,
    "lines": [
        {
            "tax_product_code": null,
            "line_description": "Invoice description",
            "line_quantity": "1.00",
            "line_unit_price": "10000.00",
            "note": "",
            "discounts": [{
                "discount_code":"NONE",
                "description":"uPoint хямдрал",
                "amount":100,
                "note":"тэмдэглэл"
            }],
            "surcharges": [{
                "surcharge_code":"NONE",
                "description":"Хүргэлтийн зардал",
                "amount":100,
                "note":"тэмдэглэл"
            }],
            "taxes": [{
                "tax_code":"VAT",
                "description":"НӨАТ",
                "amount":100,
                "note":"тэмдэглэл"
            }]
        }
    ]
}'
```

#### Using NPM Package

```javascript
const invoice = await qpay.createInvoice({
  invoice_code: "TEST_INVOICE",
  sender_invoice_no: "MERCHANT_INV_123",
  invoice_receiver_code: "terminal",
  invoice_description: "Payment for services",
  amount: 10000,
  callback_url: "https://your-domain.com/callback",
});
```

#### Response

| Field        | Required | Type   | Description                                | Example                              |
| ------------ | -------- | ------ | ------------------------------------------ | ------------------------------------ |
| `invoice_id` | Yes      | string | Object ID                                  | 00f94137-66fd-4d90-b2b2-8225c1b4ed2d |
| `qr_text`    | Yes      | string | QR code text for card/account transactions | 0002010102...                        |
| `qr_image`   | Yes      | string | Base64 QR code image with QPay logo        | iVBORw0KGgo...                       |
| `urls`       | Yes      | array  | Bank app deep links                        | -                                    |

#### URLs Array (`urls[]`)

| Field         | Required | Type   | Description   | Example                      |
| ------------- | -------- | ------ | ------------- | ---------------------------- |
| `name`        | No       | string | Bank name     | Khan bank                    |
| `description` | No       | string | Display name  | Хаан банк                    |
| `link`        | No       | string | Deep link URL | khanbank://q?qPay_QRcode=... |

```json
{
  "invoice_id": "00f94137-66fd-4d90-b2b2-8225c1b4ed2d",
  "qr_text": "0002010102121531279404962794049600000000KKTQPAY52046010530349654031005802MN5913TEST_MERCHANT6011Ulaanbaatar6244010712345670504test0721G7ZEWdbzkppBhJ1nouBhZ6304879D",
  "qr_image": "iVBORw0KGgoAAAANSUhEUgAAASwAAAEsCAYAAAB5fY51AAAABmJLR0QA...",
  "urls": [
    {
      "name": "Khan bank",
      "description": "Хаан банк",
      "link": "khanbank://q?qPay_QRcode=0002010102121531279404962794049600000000KKTQPAY52046010530349654031005802MN5913TEST_MERCHANT6011Ulaanbaatar6244010712345670504test0721G7ZEWdbzkppBhJ1nouBhZ6304879D"
    },
    {
      "name": "State bank",
      "description": "Төрийн банк",
      "link": "statebank://q?qPay_QRcode=0002010102121531279404962794049600000000KKTQPAY52046010530349654031005802MN5913TEST_MERCHANT6011Ulaanbaatar6244010712345670504test0721G7ZEWdbzkppBhJ1nouBhZ6304879D"
    }
  ]
}
```

### Create Simple Test Invoice

For simple test invoice creation with minimal parameters.

#### Request Parameters (Simple)

| Field                   | Required | Type   | Max Length | Description              | Example                      |
| ----------------------- | -------- | ------ | ---------- | ------------------------ | ---------------------------- |
| `invoice_code`          | Yes      | string | 45         | Invoice code from QPay   | TEST_INVOICE                 |
| `sender_invoice_no`     | Yes      | string | 45         | Unique invoice number    | 123                          |
| `invoice_receiver_code` | Yes      | string | 45         | Customer code            | ТБ82045123                   |
| `invoice_description`   | Yes      | string | 255        | Invoice description      | Invoice description          |
| `amount`                | Yes      | number | -          | Amount                   | 100                          |
| `callback_url`          | Yes      | string | 255        | Payment notification URL | https://example.com/callback |

#### Direct API (Simple)

```bash
curl --location 'https://merchant-sandbox.qpay.mn/v2/invoice' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer your_access_token' \
--data '{
    "invoice_code": "TEST_INVOICE",
    "sender_invoice_no": "1234567",
    "invoice_receiver_code": "terminal",
    "invoice_description":"test",
    "amount":100,
    "callback_url":"https://bd5492c3ee85.ngrok.io/payments?payment_id=1234567"
}'
```

### Get Invoice Details

Retrieve information about a created invoice using invoice_id as query parameter.

#### Endpoint

```
GET https://merchant-sandbox.qpay.mn/v2/invoice/:invoice_id
```

#### Direct API

```bash
curl --location 'https://merchant-sandbox.qpay.mn/v2/invoice/12345678-1234-1234-1234-123456789012' \
--header 'Authorization: Bearer your_access_token'
```

#### Using NPM Package

```javascript
const invoiceDetails = await qpay.getInvoice(
  "12345678-1234-1234-1234-123456789012"
);
```

### Cancel Invoice

Cancel a payment invoice using invoice_id as query parameter.

#### Endpoint

```
DELETE https://merchant-sandbox.qpay.mn/v2/invoice/:invoice_id
```

#### Direct API

```bash
curl --location --request DELETE 'https://merchant-sandbox.qpay.mn/v2/invoice/12345678-1234-1234-1234-123456789012' \
--header 'Authorization: Bearer your_access_token'
```

#### Using NPM Package

```javascript
const cancelResult = await qpay.cancelInvoice(
  "12345678-1234-1234-1234-123456789012"
);
```

## Payment Operations

### Get Payment Details

Get payment information using payment_id as query parameter.

#### Endpoint

```
GET https://merchant-sandbox.qpay.mn/v2/payment/:payment_id
```

#### Direct API

```bash
curl --location 'https://merchant-sandbox.qpay.mn/v2/payment/payment_id' \
--header 'Authorization: Bearer your_access_token'
```

#### Using NPM Package

```javascript
const paymentDetails = await qpay.getPayment("payment_id");
```

### Check Payment Status

Check if payment has been made. Use `object_type=INVOICE` to check invoice payment.

#### Endpoint

```
POST https://merchant-sandbox.qpay.mn/v2/payment/check
```

#### Request Parameters

| Field         | Required | Type   | Description                         | Example                              |
| ------------- | -------- | ------ | ----------------------------------- | ------------------------------------ |
| `object_type` | Yes      | string | Object type (INVOICE, QR, ITEM)     | INVOICE                              |
| `object_id`   | Yes      | string | Object ID (use QR code for QR type) | 00f94137-66fd-4d90-b2b2-8225c1b4ed2d |
| `offset`      | No       | object | Pagination                          | -                                    |

#### Offset Object

| Field         | Required | Type   | Description        | Example |
| ------------- | -------- | ------ | ------------------ | ------- |
| `page_number` | Yes      | number | Page number        | 1       |
| `page_limit`  | Yes      | number | Page limit (1-100) | 100     |

#### Direct API

```bash
curl --location 'https://merchant-sandbox.qpay.mn/v2/payment/check' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer your_access_token' \
--data '{
    "object_type": "INVOICE",
    "object_id"  : "071f45e6-b6e6-4562-a470-8457269d251a",
    "offset"     : {
        "page_number": 1,
        "page_limit" : 100
    }
}'
```

#### Using NPM Package

```javascript
const paymentStatus = await qpay.checkPayment(
  "071f45e6-b6e6-4562-a470-8457269d251a"
);
```

#### Response

| Field         | Required | Type   | Description             | Example |
| ------------- | -------- | ------ | ----------------------- | ------- |
| `count`       | Yes      | number | Total transaction count | 1       |
| `paid_amount` | Yes      | number | Transaction amount      | 100     |
| `rows`        | Yes      | array  | Payment records         | -       |

#### Payment Rows (`rows[]`)

| Field              | Required | Type   | Description                                  | Example                              |
| ------------------ | -------- | ------ | -------------------------------------------- | ------------------------------------ |
| `payment_id`       | Yes      | number | QPay payment ID                              | 593744473409193                      |
| `payment_status`   | Yes      | string | Payment status (NEW, FAILED, PAID, REFUNDED) | PAID                                 |
| `payment_date`     | Yes      | date   | Payment date                                 | 2020-10-19T08:58:46.641Z             |
| `payment_fee`      | Yes      | number | Transaction fee                              | 1                                    |
| `payment_amount`   | Yes      | number | Payment amount                               | 100                                  |
| `payment_currency` | Yes      | string | Payment currency                             | MNT                                  |
| `payment_wallet`   | Yes      | string | Payment wallet ID                            | 0fc9b71c-cd87-4ffd-9cac-2279ebd9deb0 |
| `transaction_type` | Yes      | string | Transaction type (P2P, CARD)                 | P2P                                  |

```json
{
  "count": 1,
  "paid_amount": 100,
  "rows": [
    {
      "payment_id": "593744473409193",
      "payment_status": "PAID",
      "payment_date": "2020-10-19T08:58:46.641Z",
      "payment_fee": "1.00",
      "payment_amount": "100.00",
      "payment_currency": "MNT",
      "payment_wallet": "0fc9b71c-cd87-4ffd-9cac-2279ebd9deb0",
      "transaction_type": "P2P"
    }
  ]
}
```

### Cancel Payment

Cancel a paid payment using payment_id as query parameter.

#### Endpoint

```
DELETE https://merchant-sandbox.qpay.mn/v2/payment/cancel/:payment_id
```

#### Request Parameters

| Field          | Required | Type   | Description  | Example                                                                        |
| -------------- | -------- | ------ | ------------ | ------------------------------------------------------------------------------ |
| `callback_url` | No       | string | Callback URL | https://qpay.mn/payment/result?payment_id=a2ab7ab0-80b0-4045-b79a-3052eda1ca89 |
| `note`         | No       | string | Note         | butsaalt                                                                       |

#### Direct API

```bash
curl --location --request DELETE 'https://merchant-sandbox.qpay.mn/v2/payment/cancel/payment_id' \
--header 'Authorization: Bearer your_access_token' \
--data '{
    "callback_url":"https://qpay.mn/payment/result?payment_id=ccb8e022-0187-4184-bd3f-a6d9ce231e6f",
    "note":"butsaalt"
}'
```

#### Using NPM Package

```javascript
const cancelPayment = await qpay.cancelPayment("payment_id");
```

#### Error Response

```json
{
  "error": "PAYMENT_SETTLED",
  "message": "PAYMENT_SETTLED"
}
```

### Refund Payment

Refund a paid payment using payment_id as query parameter.

#### Endpoint

```
DELETE https://merchant-sandbox.qpay.mn/v2/payment/refund/:payment_id
```

#### Request Parameters

| Field          | Required | Type   | Description  | Example                                                                        |
| -------------- | -------- | ------ | ------------ | ------------------------------------------------------------------------------ |
| `callback_url` | No       | string | Callback URL | https://qpay.mn/payment/result?payment_id=a2ab7ab0-80b0-4045-b79a-3052eda1ca89 |
| `note`         | No       | string | Note         | butsaalt                                                                       |

#### Direct API

```bash
curl --location --request DELETE 'https://merchant-sandbox.qpay.mn/v2/payment/refund/payment_id' \
--header 'Authorization: Bearer your_access_token'
```

### Payment List

Get list of payments. The `customer_id`, `card_terminal_id`, `p2p_terminal_id` information can be obtained from QPay merchant web admin or QPay.

#### Endpoint

```
POST https://merchant-sandbox.qpay.mn/v2/payment/list
```

#### Request Parameters

| Field                    | Required | Type   | Max Length | Description                         | Example                              |
| ------------------------ | -------- | ------ | ---------- | ----------------------------------- | ------------------------------------ |
| `object_type`            | Yes      | string | 45         | Object type (MERCHANT, INVOICE, QR) | MERCHANT                             |
| `object_id`              | Yes      | string | 45         | Object ID                           | 00f94137-66fd-4d90-b2b2-8225c1b4ed2d |
| `merchant_branch_code`   | No       | string | -          | Merchant branch code                | branch_01                            |
| `merchant_terminal_code` | No       | string | -          | Merchant terminal code              | terminal_01                          |
| `merchant_staff_code`    | No       | string | -          | Staff code                          | staff_01                             |
| `offset`                 | No       | object | -          | Pagination                          | -                                    |

#### Response

| Field                 | Type    | Description                                  | Example                              |
| --------------------- | ------- | -------------------------------------------- | ------------------------------------ |
| `payment_id`          | string  | QPay payment ID                              | 12f94137-66fd-4d90-b2b2-8225c1b4ed2d |
| `payment_date`        | date    | Payment date                                 | 2020-10-19T08:58:46.641Z             |
| `payment_status`      | string  | Payment status (NEW, FAILED, PAID, REFUNDED) | PAID                                 |
| `payment_fee`         | decimal | Fee amount                                   | 10                                   |
| `payment_amount`      | decimal | Payment amount                               | 1000                                 |
| `payment_currency`    | string  | Payment currency                             | MNT                                  |
| `payment_wallet`      | string  | Payment wallet ID                            | 0fc9b71c-cd87-4ffd-9cac-2279ebd9deb0 |
| `payment_name`        | string  | Payment name                                 | Юнивишн                              |
| `payment_description` | string  | Payment description                          | Юнивишн төлбөр                       |
| `qr_code`             | string  | QR code used in transaction                  | 000201010211...                      |
| `paid_by`             | string  | Transaction type (P2P, CARD)                 | CARD                                 |
| `object_type`         | string  | Object type (MERCHANT, INVOICE, QR)          | INVOICE                              |
| `object_id`           | string  | Object ID                                    | 00f94137-66fd-4d90-b2b2-8225c1b4ed2d |

#### Using NPM Package

```javascript
const paymentList = await qpay.getPaymentList({
  page: 1,
  per_page: 20,
  start_date: "2024-01-01",
  end_date: "2024-01-31",
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
  "error": "INVALID_REQUEST",
  "message": "Invoice amount must be greater than 0",
  "details": {}
}
```

### Payment Status Codes

| Status   | Description          |
| -------- | -------------------- |
| NEW      | Transaction created  |
| FAILED   | Transaction failed   |
| PAID     | Payment completed    |
| REFUNDED | Transaction refunded |

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
