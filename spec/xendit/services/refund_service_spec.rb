RSpec.describe Xendit::Services::RefundService do
  let(:client) { instance_double(Xendit::Client) }
  subject { described_class.new(client) }

  describe '#create' do
    let(:valid_params) do
      {
        payment_request_id: 'pr-123456789',
        amount: 50_000,
        reason: 'REQUESTED_BY_CUSTOMER'
      }
    end

    let(:expected_response) do
      {
        'id' => 'rfd-123456789',
        'payment_id' => 'payment-123',
        'amount' => 50_000,
        'status' => 'PENDING',
        'reason' => 'REQUESTED_BY_CUSTOMER',
        'created' => '2024-01-01T00:00:00Z'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'creates refund successfully' do
      result = subject.create(valid_params)

      expect(client).to have_received(:post).with('/refunds', anything, anything)
      expect(result).to be_a(Xendit::Models::Refund)
      expect(result.id).to eq('rfd-123456789')
      expect(result.amount).to eq(50_000)
      expect(result.reason).to eq('REQUESTED_BY_CUSTOMER')
    end

    it 'includes all valid parameters in request body' do
      params_with_metadata = valid_params.merge(
        reference_id: 'refund-ref-123',
        currency: 'IDR',
        metadata: { order_id: '12345' }
      )

      subject.create(params_with_metadata)

      expect(client).to have_received(:post) do |_path, body, _headers|
        expect(body).to include(
          payment_request_id: 'pr-123456789',
          amount: 50_000,
          reason: 'REQUESTED_BY_CUSTOMER',
          reference_id: 'refund-ref-123',
          currency: 'IDR',
          metadata: { order_id: '12345' }
        )
      end
    end

    context 'with invoice_id instead of payment_request_id' do
      let(:invoice_params) do
        {
          invoice_id: 'inv-123456789',
          reason: 'FRAUDULENT'
        }
      end

      it 'creates refund with invoice_id' do
        subject.create(invoice_params)

        expect(client).to have_received(:post) do |_path, body, _headers|
          expect(body).to include(
            invoice_id: 'inv-123456789',
            reason: 'FRAUDULENT'
          )
          expect(body).not_to have_key(:payment_request_id)
        end
      end
    end

    context 'with headers' do
      let(:params_with_headers) do
        valid_params.merge(
          idempotency_key: 'refund-idem-123',
          for_user_id: 'user-123'
        )
      end

      it 'includes custom headers' do
        subject.create(params_with_headers)

        expect(client).to have_received(:post) do |_path, _body, headers|
          expect(headers).to include(
            'idempotency-key' => 'refund-idem-123',
            'for-user-id' => 'user-123'
          )
        end
      end
    end

    context 'with validation errors' do
      it 'raises ValidationError when both payment_request_id and invoice_id are missing' do
        invalid_params = { reason: 'REQUESTED_BY_CUSTOMER' }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /payment_request_id.*invoice_id.*required/)
      end

      it 'raises ValidationError when reason is missing' do
        invalid_params = { payment_request_id: 'pr-123456789' }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /reason.*required/)
      end

      it 'raises ValidationError for invalid reason' do
        invalid_params = valid_params.merge(reason: 'INVALID_REASON')

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /reason must be one of/)
      end

      it 'validates allowed reasons' do
        allowed_reasons = %w[FRAUDULENT DUPLICATE REQUESTED_BY_CUSTOMER CANCELLATION OTHERS]

        allowed_reasons.each do |reason|
          valid_params_with_reason = valid_params.merge(reason: reason)
          expect { subject.create(valid_params_with_reason) }.not_to raise_error
        end
      end
    end
  end

  describe '#get' do
    let(:refund_id) { 'rfd-123456789' }
    let(:expected_response) do
      {
        'id' => refund_id,
        'status' => 'SUCCEEDED',
        'amount' => 50_000,
        'reason' => 'REQUESTED_BY_CUSTOMER'
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'retrieves refund by ID' do
      result = subject.get(refund_id)

      expect(client).to have_received(:get).with("/refunds/#{refund_id}", {}, {})
      expect(result).to be_a(Xendit::Models::Refund)
      expect(result.id).to eq(refund_id)
      expect(result.status).to eq('SUCCEEDED')
    end

    it 'includes headers when provided' do
      headers = { 'for-user-id' => 'user-123' }
      subject.get(refund_id, headers)

      expect(client).to have_received(:get)
        .with("/refunds/#{refund_id}", {}, headers)
    end
  end
end
