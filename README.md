# Xendit Ruby SDK

A comprehensive Ruby SDK for integrating with the Xendit payment gateway API.

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
end
```

## Usage

### Payment Requests

#### Create a Payment Request

```ruby
# E-wallet one-time payment
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

# Direct debit with existing payment method
payment_request = Xendit.payment_requests.create(
  currency: 'PHP',
  amount: 1500,
  payment_method_id: 'pm-04152d03-0f56-433c-994c-251f79b6074a'
)

# Virtual account
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

#### Get Payment Request

```ruby
payment_request = Xendit.payment_requests.get('pr-123456789')
puts payment_request.status # 'SUCCEEDED', 'FAILED', etc.
```

#### List Payment Requests

```ruby
result = Xendit.payment_requests.list(
  limit: 10,
  reference_id: 'order-123'
)
puts result[:data].first.amount
```

#### Authorize Payment Request (OTP Validation)

```ruby
payment_request = Xendit.payment_requests.authorize(
  'pr-123456789',
  auth_code: '123456'
)
```

### Payment Methods

#### Create Payment Method (Account Linking)

```ruby
# E-wallet account linking
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

# Direct debit account linking
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

#### Get Payment Method

```ruby
payment_method = Xendit.payment_methods.get('pm-123456789')
puts payment_method.active? # true/false
```

#### List Payment Methods

```ruby
result = Xendit.payment_methods.list(
  customer_id: 'cust-123456789',
  type: 'EWALLET'
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
```

#### Authorize Payment Method (Account Linking OTP)

```ruby
payment_method = Xendit.payment_methods.authorize(
  'pm-123456789',
  auth_code: '123456'
)
```

### Payments

#### List Payments by Payment Method

```ruby
result = Xendit.payments.list_by_payment_method(
  'pm-123456789',
  limit: 10,
  status: 'SUCCEEDED'
)
```

#### Simulate Payment (Test Mode)

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

```ruby
begin
  payment_request = Xendit.payment_requests.create(invalid_params)
rescue Xendit::Errors::ValidationError => e
  puts "Validation error: #{e.message}"
rescue Xendit::Errors::AuthenticationError => e
  puts "Authentication error: #{e.message}"
rescue Xendit::Errors::XenditError => e
  puts "General Xendit error: #{e.message}"
end
```

### Custom Headers

```ruby
payment_request = Xendit.payment_requests.create(
  params,
  idempotency_key: 'unique-key-123',
  for_user_id: 'user-123',
  with_split_rule: 'split-rule-123'
)
```

### Webhooks Integration

The SDK provides model classes that can be used to parse webhook payloads:

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
  end
end
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/xendit-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).