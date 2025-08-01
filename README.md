# Xendit Ruby SDK

A comprehensive Ruby SDK for integrating with the Xendit payment gateway API. This SDK provides a clean, Ruby-idiomatic interface to Xendit's Payments API, supporting all major payment methods across Southeast Asia.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xendit-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install xendit-ruby

## Configuration

Configure the gem with your Xendit API key:

```ruby
Xendit.configure do |config|
  config.api_key = 'your_xendit_api_key'
  config.base_url = 'https://api.xendit.co' # optional, defaults to production
  config.timeout = 30 # optional, request timeout in seconds
  config.open_timeout = 10 # optional, connection timeout in seconds
end
```

## Authentication

The SDK uses HTTP Basic Authentication with your Xendit API key as the username and an empty password. Get your API keys from the [Xendit Dashboard](https://dashboard.xendit.co/settings/developers#api-keys).

## Usage

### Payment Requests

Payment requests represent the intent to collect payment from a customer using various payment methods.

#### Create a Payment Request

**E-wallet one-time payment:**
```ruby
payment_request = Xendit.payment_requests.create(
  currency: 'IDR',
  amount: 100000,
  payment_method: {
    type: 'EWALLET',
    reusability: 'ONE_TIME_USE',
    ewallet: {
      channel_code: 'SHOPEEPAY',
      channel_properties: {
        success_return_url: 'https://your-site.com/success'
      }
    }
  },
  metadata: { order_id: '12345' }
)
```

**Direct debit with existing payment method:**
```ruby
payment_request = Xendit.payment_requests.create(
  currency: 'PHP',
  amount: 1500,
  payment_method_id: 'pm-04152d03-0f56-433c-994c-251f79b6074a'
)
```

**Virtual account:**
```ruby
payment_request = Xendit.payment_requests.create(
  currency: 'IDR',
  amount: 100000,
  payment_method: {
    type: 'VIRTUAL_ACCOUNT',
    reusability: 'ONE_TIME_USE',
    virtual_account: {
      channel_code: 'BRI',
      channel_properties: {
        customer_name: 'John Doe',
        expires_at: '2024-12-31T23:59:59Z'
      }
    }
  }
)
```

**Credit card payment:**
```ruby
payment_request = Xendit.payment_requests.create(
  currency: 'IDR',
  amount: 100000,
  payment_method_id: 'pm-tokenized-card-id', # From tokenization
  capture_method: 'AUTOMATIC', # or 'MANUAL'
  channel_properties: {
    skip_three_d_secure: false
  }
)
```

#### Get Payment Request

```ruby
payment_request = Xendit.payment_requests.get('pr-123456789')
puts payment_request.status # 'SUCCEEDED', 'FAILED', etc.
puts payment_request.successful? # true/false
```

#### List Payment Requests

```ruby
result = Xendit.payment_requests.list(
  limit: 10,
  reference_id: 'order-123'
)
puts result[:data].first.amount
puts result[:has_more]
```

#### Authorize Payment Request (OTP Validation)

For direct debit payments that require OTP:

```ruby
payment_request = Xendit.payment_requests.authorize(
  'pr-123456789',
  auth_code: '123456'
)
```

#### Resend Authorization

For certain direct debit channels:

```ruby
payment_request = Xendit.payment_requests.resend_auth('pr-123456789')
```

### Payment Methods

Payment methods represent tokenized payment instruments that can be reused for multiple transactions.

#### Create Payment Method (Account Linking)

**E-wallet account linking:**
```ruby
payment_method = Xendit.payment_methods.create(
  type: 'EWALLET',
  reusability: 'MULTIPLE_USE',
  customer_id: 'cust-123456789',
  ewallet: {
    channel_code: 'OVO',
    channel_properties: {
      success_return_url: 'https://your-site.com/success',
      failure_return_url: 'https://your-site.com/failure'
    }
  }
)
```

**Direct debit account linking:**
```ruby
payment_method = Xendit.payment_methods.create(
  type: 'DIRECT_DEBIT',
  reusability: 'MULTIPLE_USE',
  customer_id: 'cust-123456789',
  direct_debit: {
    channel_code: 'BPI',
    channel_properties: {
      success_return_url: 'https://your-site.com/success',
      failure_return_url: 'https://your-site.com/failure'
    }
  }
)
```

**Virtual account (reusable):**
```ruby
payment_method = Xendit.payment_methods.create(
  type: 'VIRTUAL_ACCOUNT',
  reusability: 'MULTIPLE_USE',
  virtual_account: {
    channel_code: 'BRI',
    channel_properties: {
      customer_name: 'John Doe'
    }
  }
)
```

#### Get Payment Method

```ruby
payment_method = Xendit.payment_methods.get('pm-123456789')
puts payment_method.active? # true/false
puts payment_method.channel_code # 'OVO', 'BPI', etc.
```

#### List Payment Methods

```ruby
result = Xendit.payment_methods.list(
  customer_id: 'cust-123456789',
  type: 'EWALLET',
  status: 'ACTIVE'
)
```

#### Update Payment Method

```ruby
payment_method = Xendit.payment_methods.update(
  'pm-123456789',
  status: 'INACTIVE'
)
```

#### Expire Payment Method

```ruby
payment_method = Xendit.payment_methods.expire('pm-123456789')

# For KTB direct debit (requires confirmation URLs)
payment_method = Xendit.payment_methods.expire(
  'pm-123456789',
  success_return_url: 'https://your-site.com/success',
  failure_return_url: 'https://your-site.com/failure'
)
```

#### Authorize Payment Method (Account Linking OTP)

```ruby
payment_method = Xendit.payment_methods.authorize(
  'pm-123456789',
  auth_code: '123456'
)
```

### Payments

The Payment object represents completed or attempted payment transactions.

#### List Payments by Payment Method

```ruby
result = Xendit.payments.list_by_payment_method(
  'pm-123456789',
  limit: 10,
  status: 'SUCCEEDED'
)
```

#### Simulate Payment (Test Mode Only)

```ruby
result = Xendit.payments.simulate('pm-123456789', amount: 100000)
puts result[:status] # 'PENDING'
```

### Refunds

#### Create Refund

```ruby
refund = Xendit.refunds.create(
  payment_request_id: 'pr-123456789',
  amount: 50000,
  reason: 'REQUESTED_BY_CUSTOMER'
)
```

#### Get Refund

```ruby
refund = Xendit.refunds.get('rfd-123456789')
puts refund.successful? # true/false
puts refund.net_refund_amount # amount after fees
```

### Customers

#### Create Customer

```ruby
customer = Xendit.customers.create(
  reference_id: 'customer-123',
  type: 'INDIVIDUAL',
  individual_detail: {
    given_names: 'John',
    surname: 'Doe'
  },
  email: 'john.doe@example.com',
  mobile_number: '+6281234567890'
)
```

#### Get Customer

```ruby
customer = Xendit.customers.get('cust-123456789')
puts customer.individual? # true/false
```

## Advanced Usage

### Error Handling

The SDK provides specific error classes for different scenarios:

```ruby
begin
  payment_request = Xendit.payment_requests.create(params)
rescue Xendit::Errors::ChannelNotActivatedError => e
  puts "Payment channel not activated: #{e.message}"
rescue Xendit::Errors::CustomerNotFoundError => e
  puts "Customer not found: #{e.message}"
rescue Xendit::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue Xendit::Errors::InsufficientBalanceError => e
  puts "Insufficient balance: #{e.message}"
rescue Xendit::Errors::MaxAmountLimitError => e
  puts "Amount exceeds limit: #{e.message}"
rescue Xendit::Errors::AuthenticationError => e
  puts "Authentication error: #{e.message}"
rescue Xendit::Errors::XenditError => e
  puts "General Xendit error: #{e.message}"
end
```

### Custom Headers

```ruby
payment_request = Xendit.payment_requests.create(
  payment_params,
  idempotency_key: 'unique-key-123',
  for_user_id: 'user-123', # For xenPlatform
  with_split_rule: 'split-rule-123' # For fee splitting
)
```

### Webhook Payload Parsing

The SDK provides model classes that can parse webhook payloads:

```ruby
# In your webhook controller
def handle_payment_webhook
  payload = JSON.parse(request.body.read)

  case payload['event']
  when 'payment.succeeded'
    payment = Xendit::Models::Payment.new(payload['data'])
    handle_successful_payment(payment)
  when 'payment.failed'
    payment = Xendit::Models::Payment.new(payload['data'])
    handle_failed_payment(payment)
  when 'payment_method.activated'
    payment_method = Xendit::Models::PaymentMethod.new(payload['data'])
    handle_payment_method_activated(payment_method)
  end
end
```

### Model Helper Methods

**Payment Request:**
```ruby
payment_request = Xendit.payment_requests.get('pr-123')
payment_request.successful?          # true/false
payment_request.requires_action?     # true/false
payment_request.automatic_capture?   # true/false
payment_request.customer_initiated?  # true/false
payment_request.action_for('AUTH')   # Get specific action
```

**Payment Method:**
```ruby
payment_method = Xendit.payment_methods.get('pm-123')
payment_method.active?        # true/false
payment_method.ewallet?       # true/false
payment_method.multiple_use?  # true/false
payment_method.channel_code   # 'OVO', 'BPI', etc.
```

**Payment:**
```ruby
payment = Xendit::Models::Payment.new(webhook_data)
payment.successful?           # true/false
payment.channel_code         # Payment channel
payment.has_payment_detail?  # Has additional details
payment.items_count          # Number of items
```

## Supported Payment Methods

### E-wallets
- **Indonesia**: DANA, LinkAja, OVO, ShopeePay, AstraPay, JeniusPay, NexCash
- **Philippines**: GrabPay, GCash, Maya (PayMaya), ShopeePay
- **Vietnam**: Appota, MOMO, ZaloPay, VNPTWALLET, ShopeePay, ViettelPay
- **Thailand**: WechatPay, LINE Pay, ShopeePay, TrueMoney
- **Malaysia**: Touch n Go, ShopeePay, GrabPay, WechatPay

### Direct Debit
- **Indonesia**: BRI, Mandiri
- **Philippines**: BPI, RCBC, Unionbank, Chinabank, BDO EPAY
- **Thailand**: SCB, KTB, BBL, BAY, K-Bank
- **Malaysia**: Various FPX banks

### Virtual Accounts
- **Indonesia**: BCA, BJB, BNI, BRI, BSI, CIMB, Mandiri, Permata
- **Vietnam**: PV, Viet Capital, Woori, MSB, VPB, BIDV
- **Thailand**: Standard Chartered
- **Philippines**: InstaPay/PESONet
- **Malaysia**: UOB, AmBank

### Over-the-Counter
- **Indonesia**: Alfamart, Indomaret
- **Philippines**: 7-Eleven, Cebuana Lhuillier, ECPay, Palawan Express, MLhuillier, LBC

### Cards
- **Indonesia**: IDR transactions
- **Philippines**: PHP and USD transactions

### QR Codes
- **Indonesia**: DANA (QRIS), LinkAja (QRIS)
- **Thailand**: PromptPay
- **Philippines**: QRPH

## Payment Flows

### One-Time Payment
For guest checkout or single-use payments:

```ruby
payment_request = Xendit.payment_requests.create(
  currency: 'IDR',
  amount: 100000,
  payment_method: {
    type: 'EWALLET',
    reusability: 'ONE_TIME_USE',
    ewallet: {
      channel_code: 'DANA',
      channel_properties: {
        success_return_url: 'https://your-site.com/success'
      }
    }
  }
)
```

### Link and Pay
Save payment method for future use during payment:

```ruby
payment_request = Xendit.payment_requests.create(
  currency: 'PHP',
  amount: 1500,
  customer_id: 'cust-123',
  payment_method: {
    type: 'DIRECT_DEBIT',
    reusability: 'MULTIPLE_USE', # Will be saved for reuse
    direct_debit: {
      channel_code: 'BPI',
      channel_properties: {
        success_return_url: 'https://your-site.com/success',
        failure_return_url: 'https://your-site.com/failure'
      }
    }
  }
)
```

### Tokenized Payment
Use previously saved payment method:

```ruby
# First, link the payment method
payment_method = Xendit.payment_methods.create(...)

# Then use it for payments
payment_request = Xendit.payment_requests.create(
  currency: 'PHP',
  amount: 1500,
  payment_method_id: payment_method.id
)
```

## Testing

For testing, use Xendit's test API keys and the simulation endpoints:

```ruby
# Configure with test API key
Xendit.configure do |config|
  config.api_key = 'xnd_development_...'
end

# Simulate payment (test mode only)
Xendit.payments.simulate('pm-test-id', amount: 100000)
```

## Configuration Options

```ruby
Xendit.configure do |config|
  config.api_key = 'your_api_key'           # Required
  config.base_url = 'https://api.xendit.co' # Optional
  config.timeout = 30                       # Request timeout (seconds)
  config.open_timeout = 10                  # Connection timeout (seconds)
  config.faraday_adapter = :net_http        # HTTP adapter
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/htoo-eain-lwin/xendit-ruby.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

## Support

For SDK-related issues, please open an issue on GitHub.
For Xendit API support, visit the [Xendit Help Center](https://help.xendit.co/).
