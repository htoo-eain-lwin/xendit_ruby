#!/usr/bin/env ruby

require 'bundler/setup'
require 'xendit'
require 'json'

# Configure Xendit
Xendit.configure do |config|
  config.api_key = ENV['XENDIT_API_KEY'] || 'xnd_development_...'
  # config.base_url = 'https://api.xendit.co' # Optional, defaults to production
end

# Example payment flows demonstrating different use cases

class PaymentFlowExamples
  def self.run_all
    puts 'Running Xendit Ruby SDK Payment Flow Examples'
    puts '=' * 50

    new.tap do |examples|
      examples.one_time_ewallet_payment
      examples.link_and_pay_direct_debit
      examples.tokenized_payment_flow
      examples.virtual_account_payment
      examples.refund_flow
      examples.customer_management
    end
  rescue Xendit::Errors::XenditError => e
    puts "Xendit Error: #{e.message}"
  rescue StandardError => e
    puts "Error: #{e.message}"
  end

  def one_time_ewallet_payment
    puts "\n1. One-Time E-wallet Payment (Guest Checkout)"
    puts '-' * 45

    payment_request = Xendit.payment_requests.create(
      currency: 'IDR',
      amount: 100_000,
      reference_id: "order-#{Time.now.to_i}",
      payment_method: {
        type: 'EWALLET',
        reusability: 'ONE_TIME_USE',
        ewallet: {
          channel_code: 'SHOPEEPAY',
          channel_properties: {
            success_return_url: 'https://your-site.com/success',
            failure_return_url: 'https://your-site.com/failure'
          }
        }
      },
      metadata: {
        order_id: '12345',
        customer_name: 'John Doe'
      }
    )

    puts "✓ Payment Request Created: #{payment_request.id}"
    puts "  Status: #{payment_request.status}"
    puts "  Amount: #{format_currency(payment_request.amount, payment_request.currency)}"
    puts "  Requires Action: #{payment_request.requires_action?}"

    return unless payment_request.requires_action?

    auth_action = payment_request.action_for('AUTH')
    puts "  Action URL: #{auth_action['url']}" if auth_action
  end

  def link_and_pay_direct_debit
    puts "\n2. Link and Pay (Direct Debit with Account Linking)"
    puts '-' * 52

    # First create a customer
    customer = Xendit.customers.create(
      reference_id: "customer-#{Time.now.to_i}",
      type: 'INDIVIDUAL',
      individual_detail: {
        given_names: 'Jane',
        surname: 'Smith',
        nationality: 'PH'
      },
      email: 'jane.smith@example.com',
      mobile_number: '+639171234567'
    )

    puts "✓ Customer Created: #{customer.id}"

    # Create payment request with link and pay
    payment_request = Xendit.payment_requests.create(
      currency: 'PHP',
      amount: 1500,
      customer_id: customer.id,
      reference_id: "order-#{Time.now.to_i}",
      payment_method: {
        type: 'DIRECT_DEBIT',
        reusability: 'MULTIPLE_USE', # Will be saved for future use
        direct_debit: {
          channel_code: 'BPI',
          channel_properties: {
            success_return_url: 'https://your-site.com/success',
            failure_return_url: 'https://your-site.com/failure'
          }
        }
      }
    )

    puts "✓ Payment Request Created: #{payment_request.id}"
    puts "  Status: #{payment_request.status}"
    puts "  Customer: #{customer.id}"
    puts "  Will save payment method for reuse: #{payment_request.payment_method['reusability']}"
  end

  def tokenized_payment_flow
    puts "\n3. Tokenized Payment (Using Saved Payment Method)"
    puts '-' * 50

    # Create customer first
    customer = Xendit.customers.create(
      reference_id: "customer-#{Time.now.to_i}",
      type: 'INDIVIDUAL',
      individual_detail: {
        given_names: 'Mike',
        surname: 'Johnson'
      },
      email: 'mike.johnson@example.com'
    )

    # Link payment method first
    payment_method = Xendit.payment_methods.create(
      type: 'EWALLET',
      reusability: 'MULTIPLE_USE',
      customer_id: customer.id,
      ewallet: {
        channel_code: 'OVO',
        channel_properties: {
          success_return_url: 'https://your-site.com/success',
          failure_return_url: 'https://your-site.com/failure'
        }
      }
    )

    puts "✓ Payment Method Created: #{payment_method.id}"
    puts "  Type: #{payment_method.type}"
    puts "  Status: #{payment_method.status}"
    puts "  Channel: #{payment_method.channel_code}"

    # Simulate payment method becoming active (in real scenario, customer would complete linking)
    if payment_method.requires_action?
      puts '  ⚠ Payment method requires action to activate'
      puts '  In production, customer would complete the linking process'
    end

    # Use the payment method for payment
    payment_request = Xendit.payment_requests.create(
      currency: 'IDR',
      amount: 250_000,
      payment_method_id: payment_method.id,
      reference_id: "order-#{Time.now.to_i}"
    )

    puts "✓ Tokenized Payment Created: #{payment_request.id}"
    puts "  Using Payment Method: #{payment_method.id}"
    puts "  Status: #{payment_request.status}"
  end

  def virtual_account_payment
    puts "\n4. Virtual Account Payment"
    puts '-' * 30

    payment_request = Xendit.payment_requests.create(
      currency: 'IDR',
      amount: 500_000,
      reference_id: "order-#{Time.now.to_i}",
      payment_method: {
        type: 'VIRTUAL_ACCOUNT',
        reusability: 'ONE_TIME_USE',
        virtual_account: {
          channel_code: 'BRI',
          channel_properties: {
            customer_name: 'Sarah Wilson',
            expires_at: (Time.now + (24 * 60 * 60)).strftime('%Y-%m-%dT%H:%M:%SZ') # 24 hours from now
          }
        }
      }
    )

    puts "✓ Virtual Account Created: #{payment_request.id}"
    puts "  Status: #{payment_request.status}"
    puts '  Bank: BRI'
    puts '  Customer will receive virtual account number to complete payment'
  end

  def refund_flow
    puts "\n5. Refund Flow"
    puts '-' * 15

    # Create a payment first (simulated as successful)
    payment_request = Xendit.payment_requests.create(
      currency: 'IDR',
      amount: 100_000,
      reference_id: "order-#{Time.now.to_i}",
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

    puts "✓ Payment Request Created: #{payment_request.id}"

    # Create refund (in production, you'd wait for payment to be successful)
    refund = Xendit.refunds.create(
      payment_request_id: payment_request.id,
      amount: 50_000, # Partial refund
      reason: 'REQUESTED_BY_CUSTOMER',
      reference_id: "refund-#{Time.now.to_i}",
      metadata: {
        refund_reason: 'Customer changed mind about half the items'
      }
    )

    puts "✓ Refund Created: #{refund.id}"
    puts "  Original Amount: #{format_currency(payment_request.amount, 'IDR')}"
    puts "  Refund Amount: #{format_currency(refund.amount, 'IDR')}"
    puts "  Reason: #{refund.reason}"
    puts "  Status: #{refund.status}"

    return unless refund.has_refund_fee?

    puts "  Fee: #{format_currency(refund.refund_fee_amount, 'IDR')}"
    puts "  Net Refund: #{format_currency(refund.net_refund_amount, 'IDR')}"
  end

  def customer_management
    puts "\n6. Customer Management"
    puts '-' * 22

    # Create individual customer
    individual_customer = Xendit.customers.create(
      reference_id: "individual-#{Time.now.to_i}",
      type: 'INDIVIDUAL',
      individual_detail: {
        given_names: 'Alice',
        surname: 'Brown',
        nationality: 'ID',
        gender: 'FEMALE',
        date_of_birth: '1990-01-15'
      },
      email: 'alice.brown@example.com',
      mobile_number: '+6281234567890'
    )

    puts "✓ Individual Customer: #{individual_customer.id}"
    puts "  Type: #{individual_customer.type}"
    puts "  Individual: #{individual_customer.individual?}"
    puts "  Email: #{individual_customer.email}"

    # Create business customer
    business_customer = Xendit.customers.create(
      reference_id: "business-#{Time.now.to_i}",
      type: 'BUSINESS',
      business_detail: {
        business_name: 'Tech Innovators Ltd',
        business_type: 'CORPORATION',
        nature_of_business: 'Software Development'
      },
      email: 'admin@techinnovators.com'
    )

    puts "✓ Business Customer: #{business_customer.id}"
    puts "  Type: #{business_customer.type}"
    puts "  Business: #{business_customer.business?}"
    puts "  Company: #{business_customer.business_detail['business_name']}"

    # List payment methods for individual customer
    begin
      payment_methods = Xendit.payment_methods.list(customer_id: individual_customer.id)
      puts "✓ Payment Methods for #{individual_customer.id}: #{payment_methods[:data].size}"
    rescue Xendit::Errors::XenditError
      puts '  No payment methods found (expected for new customer)'
    end
  end

  private

  def format_currency(amount, currency)
    case currency
    when 'IDR'
      "Rp #{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    when 'PHP'
      "₱#{amount}"
    when 'USD'
      "$#{format('%.2f', amount / 100.0)}"
    else
      "#{amount} #{currency}"
    end
  end
end

# Run examples if script is executed directly
PaymentFlowExamples.run_all if __FILE__ == $PROGRAM_NAME
