RSpec.describe Xendit::Services::PaymentRequestService do
  let(:client) { instance_double(Xendit::Client) }
  subject { described_class.new(client) }

  describe '#create' do
    let(:valid_params) do
      {
        currency: 'IDR',
        amount: 100_000,
        payment_method: {
          type: 'EWALLET',
          reusability: 'ONE_TIME_USE',
          ewallet: {
            channel_code: 'OVO',
            channel_properties: {
              success_return_url: 'https://example.com/success'
            }
          }
        }
      }
    end

    let(:expected_response) do
      {
        'id' => 'pr-123456789',
        'business_id' => 'business-123',
        'amount' => 100_000,
        'currency' => 'IDR',
        'status' => 'PENDING',
        'created' => '2024-01-01T00:00:00Z',
        'updated' => '2024-01-01T00:00:00Z'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'creates payment request successfully' do
      result = subject.create(valid_params)

      expect(client).to have_received(:post).with('/payment_requests', anything, anything)
      expect(result).to be_a(Xendit::Models::PaymentRequest)
      expect(result.id).to eq('pr-123456789')
      expect(result.amount).to eq(100_000)
      expect(result.currency).to eq('IDR')
    end

    it 'includes payment method in request body' do
      subject.create(valid_params)

      expect(client).to have_received(:post) do |_path, body, _headers|
        expect(body[:payment_method]).to include(
          type: 'EWALLET',
          reusability: 'ONE_TIME_USE'
        )
        expect(body[:payment_method][:ewallet]).to include(
          channel_code: 'OVO'
        )
      end
    end

    context 'with payment_method_id' do
      let(:params_with_pm_id) do
        {
          currency: 'IDR',
          amount: 100_000,
          payment_method_id: 'pm-123456789'
        }
      end

      it 'creates payment request with payment method ID' do
        subject.create(params_with_pm_id)

        expect(client).to have_received(:post) do |_path, body, _headers|
          expect(body[:payment_method_id]).to eq('pm-123456789')
          expect(body[:payment_method]).to be_nil
        end
      end
    end

    context 'with customer_id for direct debit' do
      let(:direct_debit_params) do
        {
          currency: 'PHP',
          amount: 100_000,
          customer_id: 'cust-123',
          payment_method: {
            type: 'DIRECT_DEBIT',
            reusability: 'MULTIPLE_USE',
            direct_debit: {
              channel_code: 'BPI'
            }
          }
        }
      end

      it 'includes customer_id in request' do
        subject.create(direct_debit_params)

        expect(client).to have_received(:post) do |_path, body, _headers|
          expect(body[:customer_id]).to eq('cust-123')
        end
      end
    end

    context 'with headers' do
      let(:params_with_headers) do
        valid_params.merge(
          idempotency_key: 'idempotency-123',
          for_user_id: 'user-123'
        )
      end

      it 'includes custom headers' do
        subject.create(params_with_headers)

        expect(client).to have_received(:post) do |_path, _body, headers|
          expect(headers).to include(
            'idempotency-key' => 'idempotency-123',
            'for-user-id' => 'user-123'
          )
        end
      end
    end

    context 'with invalid parameters' do
      it 'raises ValidationError when payment method is missing' do
        invalid_params = valid_params.except(:payment_method)

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /payment_method.*required/)
      end

      it 'raises ValidationError when direct debit lacks customer_id' do
        invalid_params = {
          currency: 'PHP',
          amount: 100_000,
          payment_method: {
            type: 'DIRECT_DEBIT',
            reusability: 'MULTIPLE_USE',
            direct_debit: { channel_code: 'BPI' }
          }
        }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /customer_id.*required/)
      end
    end
  end

  describe '#get' do
    let(:payment_request_id) { 'pr-123456789' }
    let(:expected_response) do
      {
        'id' => payment_request_id,
        'status' => 'SUCCEEDED',
        'amount' => 100_000,
        'currency' => 'IDR'
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'retrieves payment request by ID' do
      result = subject.get(payment_request_id)

      expect(client).to have_received(:get).with("/payment_requests/#{payment_request_id}", {}, {})
      expect(result).to be_a(Xendit::Models::PaymentRequest)
      expect(result.id).to eq(payment_request_id)
      expect(result.status).to eq('SUCCEEDED')
    end

    it 'includes headers when provided' do
      headers = { 'for-user-id' => 'user-123' }
      subject.get(payment_request_id, headers)

      expect(client).to have_received(:get)
        .with("/payment_requests/#{payment_request_id}", {}, headers)
    end
  end

  describe '#list' do
    let(:expected_response) do
      {
        'data' => [
          {
            'id' => 'pr-123456789',
            'status' => 'SUCCEEDED',
            'amount' => 100_000
          },
          {
            'id' => 'pr-987654321',
            'status' => 'PENDING',
            'amount' => 50_000
          }
        ],
        'has_more' => false
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'lists payment requests' do
      result = subject.list

      expect(client).to have_received(:get).with('/payment_requests', {})
      expect(result[:data]).to be_an(Array)
      expect(result[:data].size).to eq(2)
      expect(result[:data].first).to be_a(Xendit::Models::PaymentRequest)
      expect(result[:has_more]).to be false
    end

    it 'includes query parameters' do
      params = { limit: 10, reference_id: 'order-123' }
      subject.list(params)

      expect(client).to have_received(:get) do |_path, query_params|
        expect(query_params).to include(limit: 10, reference_id: 'order-123')
      end
    end
  end

  describe '#authorize' do
    let(:payment_request_id) { 'pr-123456789' }
    let(:auth_code) { '123456' }
    let(:expected_response) do
      {
        'id' => payment_request_id,
        'status' => 'SUCCEEDED',
        'amount' => 100_000
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'authorizes payment request with auth code' do
      result = subject.authorize(payment_request_id, auth_code: auth_code)

      expect(client).to have_received(:post) do |path, body, _headers|
        expect(path).to eq("/payment_requests/#{payment_request_id}/auth")
        expect(body).to eq({ auth_code: auth_code })
      end
      expect(result).to be_a(Xendit::Models::PaymentRequest)
      expect(result.id).to eq(payment_request_id)
    end

    it 'raises ValidationError when auth_code is missing' do
      expect { subject.authorize(payment_request_id, {}) }
        .to raise_error(Xendit::Errors::ValidationError, 'Missing required parameters: auth_code')
    end
  end

  describe '#resend_auth' do
    let(:payment_request_id) { 'pr-123456789' }
    let(:expected_response) do
      {
        'id' => payment_request_id,
        'status' => 'REQUIRES_ACTION'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'resends auth for payment request' do
      result = subject.resend_auth(payment_request_id)

      expect(client).to have_received(:post)
        .with("/payment_requests/#{payment_request_id}/auth/resend", {}, {})
      expect(result).to be_a(Xendit::Models::PaymentRequest)
      expect(result.id).to eq(payment_request_id)
    end
  end
end
