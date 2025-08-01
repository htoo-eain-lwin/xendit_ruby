RSpec.describe Xendit::Services::PaymentService do
  let(:client) { instance_double(Xendit::Client) }
  subject { described_class.new(client) }

  describe '#list_by_payment_method' do
    let(:payment_method_id) { 'pm-123456789' }
    let(:expected_response) do
      {
        'data' => [
          {
            'id' => 'payment-123',
            'status' => 'SUCCEEDED',
            'amount' => 100_000,
            'currency' => 'IDR'
          },
          {
            'id' => 'payment-456',
            'status' => 'PENDING',
            'amount' => 50_000,
            'currency' => 'IDR'
          }
        ],
        'has_more' => false,
        'links' => []
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'lists payments by payment method ID' do
      result = subject.list_by_payment_method(payment_method_id)

      expect(client).to have_received(:get)
        .with("/v2/payment_methods/#{payment_method_id}/payments", {})
      expect(result[:data]).to be_an(Array)
      expect(result[:data].size).to eq(2)
      expect(result[:data].first).to be_a(Xendit::Models::Payment)
      expect(result[:data].first.id).to eq('payment-123')
      expect(result[:has_more]).to be false
      expect(result[:links]).to eq([])
    end

    it 'includes query parameters' do
      params = {
        status: 'SUCCEEDED',
        limit: 10,
        payment_request_id: 'pr-123'
      }

      subject.list_by_payment_method(payment_method_id, params)

      expect(client).to have_received(:get) do |_path, query_params|
        expect(query_params).to include(
          status: 'SUCCEEDED',
          limit: 10,
          payment_request_id: 'pr-123'
        )
      end
    end

    it 'handles date range parameters with bracketed format' do
      params = {
        created_gte: '2024-01-01T00:00:00Z',
        created_lte: '2024-01-31T23:59:59Z',
        updated_gte: '2024-01-01T00:00:00Z',
        updated_lte: '2024-01-31T23:59:59Z'
      }

      subject.list_by_payment_method(payment_method_id, params)

      expect(client).to have_received(:get) do |_path, query_params|
        expect(query_params).to include(
          'created[gte]' => '2024-01-01T00:00:00Z',
          'created[lte]' => '2024-01-31T23:59:59Z',
          'updated[gte]' => '2024-01-01T00:00:00Z',
          'updated[lte]' => '2024-01-31T23:59:59Z'
        )
        expect(query_params).not_to have_key(:created_gte)
        expect(query_params).not_to have_key(:created_lte)
        expect(query_params).not_to have_key(:updated_gte)
        expect(query_params).not_to have_key(:updated_lte)
      end
    end
  end

  describe '#simulate' do
    let(:payment_method_id) { 'pm-123456789' }
    let(:amount) { 100_000 }
    let(:expected_response) do
      {
        'status' => 'PENDING',
        'message' => 'Payment simulation initiated'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'simulates payment successfully' do
      result = subject.simulate(payment_method_id, amount: amount)

      expect(client).to have_received(:post) do |path, body|
        expect(path).to eq("/v2/payment_methods/#{payment_method_id}/payments/simulate")
        expect(body).to eq({ amount: amount })
      end
      expect(result[:status]).to eq('PENDING')
      expect(result[:message]).to eq('Payment simulation initiated')
    end

    it 'raises ValidationError when amount is missing' do
      expect { subject.simulate(payment_method_id, amount: nil) }
        .to raise_error(Xendit::Errors::ValidationError, /Missing required parameters: amount/)
    end
  end
end
