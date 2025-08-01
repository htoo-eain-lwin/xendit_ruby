RSpec.describe 'Xendit Models' do
  describe Xendit::Models::Base do
    let(:attributes) do
      {
        'id' => 'test-123',
        'name' => 'Test Model',
        'amount' => 100_000
      }
    end

    subject { described_class.new(attributes) }

    describe '#initialize' do
      it 'transforms keys to strings' do
        model = described_class.new(id: 'test', amount: 1000)
        expect(model['id']).to eq('test')
        expect(model['amount']).to eq(1000)
      end
    end

    describe '#to_h' do
      it 'returns a copy of attributes hash' do
        hash = subject.to_h
        expect(hash).to eq(attributes)
        expect(hash).not_to be(subject.instance_variable_get(:@attributes))
      end
    end

    describe '#to_json' do
      it 'returns JSON representation' do
        json = subject.to_json
        expect(json).to be_a(String)
        expect(MultiJson.load(json)).to eq(attributes)
      end
    end

    describe '#==' do
      it 'returns true for same class with same attributes' do
        other = described_class.new(attributes)
        expect(subject).to eq(other)
      end

      it 'returns false for different attributes' do
        other = described_class.new(attributes.merge('name' => 'Different'))
        expect(subject).not_to eq(other)
      end

      it 'returns false for different class' do
        other = Class.new(Xendit::Models::Base).new(attributes)
        expect(subject).not_to eq(other)
      end
    end

    describe '[] and []=' do
      it 'allows accessing attributes with string keys' do
        expect(subject['id']).to eq('test-123')
      end

      it 'allows accessing attributes with symbol keys' do
        expect(subject[:id]).to eq('test-123')
      end

      it 'allows setting attributes' do
        subject['new_field'] = 'new_value'
        expect(subject['new_field']).to eq('new_value')
      end
    end
  end

  describe Xendit::Models::PaymentRequest do
    let(:attributes) do
      {
        'id' => 'pr-123456789',
        'status' => 'SUCCEEDED',
        'amount' => 100_000,
        'currency' => 'IDR',
        'capture_method' => 'AUTOMATIC',
        'initiator' => 'CUSTOMER',
        'actions' => [
          {
            'action' => 'AUTH',
            'url' => 'https://example.com/auth'
          },
          {
            'action' => 'CAPTURE',
            'url' => 'https://example.com/capture'
          }
        ]
      }
    end

    subject { described_class.new(attributes) }

    describe 'status methods' do
      it '#successful? returns true for SUCCEEDED status' do
        expect(subject.successful?).to be true
      end

      it '#failed? returns true for FAILED status' do
        failed_payment = described_class.new(attributes.merge('status' => 'FAILED'))
        expect(failed_payment.failed?).to be true
      end

      it '#pending? returns true for PENDING status' do
        pending_payment = described_class.new(attributes.merge('status' => 'PENDING'))
        expect(pending_payment.pending?).to be true
      end

      it '#requires_action? returns true for REQUIRES_ACTION status' do
        action_payment = described_class.new(attributes.merge('status' => 'REQUIRES_ACTION'))
        expect(action_payment.requires_action?).to be true
      end

      it '#awaiting_capture? returns true for AWAITING_CAPTURE status' do
        capture_payment = described_class.new(attributes.merge('status' => 'AWAITING_CAPTURE'))
        expect(capture_payment.awaiting_capture?).to be true
      end
    end

    describe 'capture method helpers' do
      it '#automatic_capture? returns true for AUTOMATIC capture method' do
        expect(subject.automatic_capture?).to be true
      end

      it '#manual_capture? returns true for MANUAL capture method' do
        manual_payment = described_class.new(attributes.merge('capture_method' => 'MANUAL'))
        expect(manual_payment.manual_capture?).to be true
      end
    end

    describe 'initiator helpers' do
      it '#customer_initiated? returns true for CUSTOMER initiator' do
        expect(subject.customer_initiated?).to be true
      end

      it '#merchant_initiated? returns true for MERCHANT initiator' do
        merchant_payment = described_class.new(attributes.merge('initiator' => 'MERCHANT'))
        expect(merchant_payment.merchant_initiated?).to be true
      end
    end

    describe '#action_for' do
      it 'returns specific action by type' do
        auth_action = subject.action_for('AUTH')
        expect(auth_action).to eq({
                                    'action' => 'AUTH',
                                    'url' => 'https://example.com/auth'
                                  })
      end

      it 'returns nil for non-existent action' do
        expect(subject.action_for('NONEXISTENT')).to be_nil
      end

      it 'handles symbol input' do
        capture_action = subject.action_for(:CAPTURE)
        expect(capture_action['action']).to eq('CAPTURE')
      end
    end

    describe '#auth_actions' do
      it 'returns all auth actions' do
        auth_actions = subject.auth_actions
        expect(auth_actions.size).to eq(1)
        expect(auth_actions.first['action']).to eq('AUTH')
      end
    end
  end

  describe Xendit::Models::PaymentMethod do
    let(:attributes) do
      {
        'id' => 'pm-123456789',
        'type' => 'EWALLET',
        'status' => 'ACTIVE',
        'reusability' => 'MULTIPLE_USE',
        'ewallet' => {
          'channel_code' => 'OVO'
        },
        'actions' => [
          {
            'action' => 'AUTH',
            'url' => 'https://example.com/auth'
          }
        ]
      }
    end

    subject { described_class.new(attributes) }

    describe 'status methods' do
      it '#active? returns true for ACTIVE status' do
        expect(subject.active?).to be true
      end

      it '#inactive? returns true for INACTIVE status' do
        inactive_pm = described_class.new(attributes.merge('status' => 'INACTIVE'))
        expect(inactive_pm.inactive?).to be true
      end

      it '#expired? returns true for EXPIRED status' do
        expired_pm = described_class.new(attributes.merge('status' => 'EXPIRED'))
        expect(expired_pm.expired?).to be true
      end

      it '#failed? returns true for FAILED status' do
        failed_pm = described_class.new(attributes.merge('status' => 'FAILED'))
        expect(failed_pm.failed?).to be true
      end
    end

    describe 'reusability methods' do
      it '#multiple_use? returns true for MULTIPLE_USE' do
        expect(subject.multiple_use?).to be true
      end

      it '#one_time_use? returns true for ONE_TIME_USE' do
        one_time_pm = described_class.new(attributes.merge('reusability' => 'ONE_TIME_USE'))
        expect(one_time_pm.one_time_use?).to be true
      end
    end

    describe 'type methods' do
      it '#ewallet? returns true for EWALLET type' do
        expect(subject.ewallet?).to be true
      end

      it '#direct_debit? returns true for DIRECT_DEBIT type' do
        dd_pm = described_class.new(attributes.merge('type' => 'DIRECT_DEBIT'))
        expect(dd_pm.direct_debit?).to be true
      end

      it '#card? returns true for CARD type' do
        card_pm = described_class.new(attributes.merge('type' => 'CARD'))
        expect(card_pm.card?).to be true
      end
    end

    describe '#channel_code' do
      it 'returns channel code for ewallet' do
        expect(subject.channel_code).to eq('OVO')
      end

      it 'returns channel code for direct debit' do
        dd_pm = described_class.new(attributes.merge(
                                      'type' => 'DIRECT_DEBIT',
                                      'direct_debit' => { 'channel_code' => 'BPI' }
                                    ))
        expect(dd_pm.channel_code).to eq('BPI')
      end

      it 'returns CARD for card type' do
        card_pm = described_class.new(attributes.merge('type' => 'CARD'))
        expect(card_pm.channel_code).to eq('CARD')
      end
    end
  end

  describe Xendit::Models::Payment do
    let(:attributes) do
      {
        'id' => 'payment-123',
        'status' => 'SUCCEEDED',
        'amount' => 100_000,
        'currency' => 'IDR',
        'payment_method' => {
          'type' => 'EWALLET',
          'ewallet' => {
            'channel_code' => 'OVO'
          }
        },
        'payment_detail' => {
          'receipt_id' => 'receipt-123'
        },
        'items' => [
          { 'name' => 'Item 1', 'price' => 50_000 },
          { 'name' => 'Item 2', 'price' => 50_000 }
        ]
      }
    end

    subject { described_class.new(attributes) }

    describe 'status methods' do
      it '#successful? returns true for SUCCEEDED status' do
        expect(subject.successful?).to be true
      end

      it '#failed? returns true for FAILED status' do
        failed_payment = described_class.new(attributes.merge('status' => 'FAILED'))
        expect(failed_payment.failed?).to be true
      end

      it '#pending? returns true for PENDING status' do
        pending_payment = described_class.new(attributes.merge('status' => 'PENDING'))
        expect(pending_payment.pending?).to be true
      end
    end

    describe '#channel_code' do
      it 'returns channel code for ewallet' do
        expect(subject.channel_code).to eq('OVO')
      end

      it 'returns channel code for direct debit' do
        dd_payment = described_class.new(attributes.merge(
                                           'payment_method' => {
                                             'type' => 'DIRECT_DEBIT',
                                             'direct_debit' => { 'channel_code' => 'BPI' }
                                           }
                                         ))
        expect(dd_payment.channel_code).to eq('BPI')
      end

      it 'returns CARD for card payments' do
        card_payment = described_class.new(attributes.merge(
                                             'payment_method' => { 'type' => 'CARD' }
                                           ))
        expect(card_payment.channel_code).to eq('CARD')
      end
    end

    describe 'payment detail methods' do
      it '#has_payment_detail? returns true when payment detail exists' do
        expect(subject.has_payment_detail?).to be true
      end

      it '#payment_detail_field returns specific field' do
        expect(subject.payment_detail_field('receipt_id')).to eq('receipt-123')
      end

      it '#payment_detail_field returns nil for non-existent field' do
        expect(subject.payment_detail_field('nonexistent')).to be_nil
      end
    end

    describe 'items methods' do
      it '#has_items? returns true when items exist' do
        expect(subject.has_items?).to be true
      end

      it '#items_count returns correct count' do
        expect(subject.items_count).to eq(2)
      end

      it '#has_items? returns false when no items' do
        no_items_payment = described_class.new(attributes.merge('items' => []))
        expect(no_items_payment.has_items?).to be false
      end
    end
  end

  describe Xendit::Models::Refund do
    let(:attributes) do
      {
        'id' => 'rfd-123456789',
        'status' => 'SUCCEEDED',
        'amount' => 50_000,
        'currency' => 'IDR',
        'reason' => 'REQUESTED_BY_CUSTOMER',
        'refund_fee_amount' => 1000
      }
    end

    subject { described_class.new(attributes) }

    describe 'status methods' do
      it '#successful? returns true for SUCCEEDED status' do
        expect(subject.successful?).to be true
      end

      it '#failed? returns true for FAILED status' do
        failed_refund = described_class.new(attributes.merge('status' => 'FAILED'))
        expect(failed_refund.failed?).to be true
      end

      it '#pending? returns true for PENDING status' do
        pending_refund = described_class.new(attributes.merge('status' => 'PENDING'))
        expect(pending_refund.pending?).to be true
      end
    end

    describe 'reason methods' do
      it '#customer_requested? returns true for REQUESTED_BY_CUSTOMER' do
        expect(subject.customer_requested?).to be true
      end

      it '#fraudulent? returns true for FRAUDULENT' do
        fraud_refund = described_class.new(attributes.merge('reason' => 'FRAUDULENT'))
        expect(fraud_refund.fraudulent?).to be true
      end

      it '#duplicate? returns true for DUPLICATE' do
        dup_refund = described_class.new(attributes.merge('reason' => 'DUPLICATE'))
        expect(dup_refund.duplicate?).to be true
      end

      it '#cancellation? returns true for CANCELLATION' do
        cancel_refund = described_class.new(attributes.merge('reason' => 'CANCELLATION'))
        expect(cancel_refund.cancellation?).to be true
      end
    end

    describe 'fee methods' do
      it '#has_refund_fee? returns true when fee exists' do
        expect(subject.has_refund_fee?).to be true
      end

      it '#net_refund_amount returns amount minus fee' do
        expect(subject.net_refund_amount).to eq(49_000)
      end

      it '#net_refund_amount returns full amount when no fee' do
        no_fee_refund = described_class.new(attributes.merge('refund_fee_amount' => nil))
        expect(no_fee_refund.net_refund_amount).to eq(50_000)
      end
    end
  end

  describe Xendit::Models::Customer do
    let(:individual_attributes) do
      {
        'id' => 'cust-123456789',
        'type' => 'INDIVIDUAL',
        'reference_id' => 'customer-123',
        'email' => 'john.doe@example.com',
        'individual_detail' => {
          'given_names' => 'John',
          'surname' => 'Doe'
        }
      }
    end

    let(:business_attributes) do
      {
        'id' => 'cust-987654321',
        'type' => 'BUSINESS',
        'reference_id' => 'business-123',
        'email' => 'admin@acme.com',
        'business_detail' => {
          'business_name' => 'Acme Corp',
          'business_type' => 'CORPORATION'
        }
      }
    end

    describe 'type methods' do
      it '#individual? returns true for INDIVIDUAL type' do
        individual_customer = described_class.new(individual_attributes)
        expect(individual_customer.individual?).to be true
      end

      it '#business? returns true for BUSINESS type' do
        business_customer = described_class.new(business_attributes)
        expect(business_customer.business?).to be true
      end

      it '#individual? returns false for BUSINESS type' do
        business_customer = described_class.new(business_attributes)
        expect(business_customer.individual?).to be false
      end

      it '#business? returns false for INDIVIDUAL type' do
        individual_customer = described_class.new(individual_attributes)
        expect(individual_customer.business?).to be false
      end
    end
  end
end
