RSpec.describe Xendit::Services::PaymentMethodService do
  let(:client) { instance_double(Xendit::Client) }
  subject { described_class.new(client) }

  describe '#create' do
    let(:valid_params) do
      {
        type: 'EWALLET',
        reusability: 'MULTIPLE_USE',
        customer_id: 'cust-123',
        ewallet: {
          channel_code: 'OVO',
          channel_properties: {
            success_return_url: 'https://example.com/success'
          }
        }
      }
    end

    let(:expected_response) do
      {
        'id' => 'pm-123456789',
        'type' => 'EWALLET',
        'status' => 'PENDING',
        'reusability' => 'MULTIPLE_USE',
        'customer_id' => 'cust-123',
        'created' => '2024-01-01T00:00:00Z'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'creates payment method successfully' do
      result = subject.create(valid_params)

      expect(client).to have_received(:post).with('/v2/payment_methods', anything, anything)
      expect(result).to be_a(Xendit::Models::PaymentMethod)
      expect(result.id).to eq('pm-123456789')
      expect(result.type).to eq('EWALLET')
      expect(result.customer_id).to eq('cust-123')
    end

    context 'with direct debit' do
      let(:direct_debit_params) do
        {
          type: 'DIRECT_DEBIT',
          reusability: 'MULTIPLE_USE',
          customer_id: 'cust-123',
          direct_debit: {
            channel_code: 'BPI',
            channel_properties: {
              success_return_url: 'https://example.com/success'
            }
          }
        }
      end

      it 'creates direct debit payment method' do
        subject.create(direct_debit_params)

        expect(client).to have_received(:post) do |_path, body, _headers|
          expect(body[:type]).to eq('DIRECT_DEBIT')
          expect(body[:direct_debit]).to include(channel_code: 'BPI')
        end
      end
    end

    context 'with validation errors' do
      it 'raises ValidationError when type is missing' do
        invalid_params = valid_params.except(:type)

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /type.*required/)
      end

      it 'raises ValidationError when customer_id is missing for direct debit' do
        invalid_params = {
          type: 'DIRECT_DEBIT',
          reusability: 'MULTIPLE_USE',
          direct_debit: { channel_code: 'BPI' }
        }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /customer_id.*required/)
      end
    end
  end

  describe '#get' do
    let(:payment_method_id) { 'pm-123456789' }
    let(:expected_response) do
      {
        'id' => payment_method_id,
        'type' => 'EWALLET',
        'status' => 'ACTIVE'
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'retrieves payment method by ID' do
      result = subject.get(payment_method_id)

      expect(client).to have_received(:get).with("/v2/payment_methods/#{payment_method_id}", {}, {})
      expect(result).to be_a(Xendit::Models::PaymentMethod)
      expect(result.id).to eq(payment_method_id)
    end
  end

  describe '#list' do
    let(:expected_response) do
      {
        'data' => [
          {
            'id' => 'pm-123456789',
            'type' => 'EWALLET',
            'status' => 'ACTIVE'
          }
        ],
        'has_more' => false
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'lists payment methods' do
      result = subject.list

      expect(client).to have_received(:get).with('/v2/payment_methods', {})
      expect(result[:data]).to be_an(Array)
      expect(result[:data].first).to be_a(Xendit::Models::PaymentMethod)
    end

    it 'includes query parameters' do
      params = { customer_id: 'cust-123', type: 'EWALLET' }
      subject.list(params)

      expect(client).to have_received(:get) do |_path, query_params|
        expect(query_params).to include(customer_id: 'cust-123', type: 'EWALLET')
      end
    end
  end

  describe '#update' do
    let(:payment_method_id) { 'pm-123456789' }
    let(:update_params) { { status: 'INACTIVE' } }
    let(:expected_response) do
      {
        'id' => payment_method_id,
        'status' => 'INACTIVE'
      }
    end

    before do
      allow(client).to receive(:patch).and_return(expected_response)
    end

    it 'updates payment method' do
      result = subject.update(payment_method_id, update_params)

      expect(client).to have_received(:patch)
        .with("/v2/payment_methods/#{payment_method_id}", update_params, {})
      expect(result).to be_a(Xendit::Models::PaymentMethod)
      expect(result.status).to eq('INACTIVE')
    end
  end

  describe '#expire' do
    let(:payment_method_id) { 'pm-123456789' }
    let(:expected_response) do
      {
        'id' => payment_method_id,
        'status' => 'EXPIRED'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'expires payment method' do
      result = subject.expire(payment_method_id)

      expect(client).to have_received(:post)
        .with("/v2/payment_methods/#{payment_method_id}/expire", {}, {})
      expect(result).to be_a(Xendit::Models::PaymentMethod)
      expect(result.status).to eq('EXPIRED')
    end

    context 'with KTB direct debit parameters' do
      let(:ktb_params) do
        {
          success_return_url: 'https://example.com/success',
          failure_return_url: 'https://example.com/failure'
        }
      end

      it 'includes query parameters for KTB' do
        subject.expire(payment_method_id, ktb_params)

        expect(client).to have_received(:post) do |path, _body, _headers|
          expect(path).to include('success_return_url=https%3A%2F%2Fexample.com%2Fsuccess')
          expect(path).to include('failure_return_url=https%3A%2F%2Fexample.com%2Ffailure')
        end
      end
    end
  end

  describe '#authorize' do
    let(:payment_method_id) { 'pm-123456789' }
    let(:auth_code) { '123456' }
    let(:expected_response) do
      {
        'id' => payment_method_id,
        'status' => 'ACTIVE'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'authorizes payment method with auth code' do
      result = subject.authorize(payment_method_id, auth_code: auth_code)

      expect(client).to have_received(:post) do |path, body, _headers|
        expect(path).to eq("/v2/payment_methods/#{payment_method_id}/auth")
        expect(body).to eq({ auth_code: auth_code })
      end
      expect(result).to be_a(Xendit::Models::PaymentMethod)
      expect(result.status).to eq('ACTIVE')
    end

    it 'raises ValidationError when auth_code is missing' do
      expect { subject.authorize(payment_method_id, auth_code: nil) }
        .to raise_error(Xendit::Errors::ValidationError, /auth_code.*required/)
    end
  end
end
