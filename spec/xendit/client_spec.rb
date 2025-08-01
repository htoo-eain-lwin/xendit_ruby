RSpec.describe Xendit::Client do
  let(:config) do
    Xendit::Configuration.new.tap do |c|
      c.api_key = 'test_api_key'
      c.base_url = 'https://api.xendit.co'
    end
  end

  subject { described_class.new(config) }

  describe '#initialize' do
    context 'with valid configuration' do
      it 'initializes successfully' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with invalid configuration' do
      let(:invalid_config) { Xendit::Configuration.new }

      it 'raises ConfigurationError' do
        expect { described_class.new(invalid_config) }
          .to raise_error(Xendit::Errors::ConfigurationError, 'API key is required')
      end
    end
  end

  describe '#connection' do
    it 'returns a Faraday connection' do
      expect(subject.connection).to be_a(Faraday::Connection)
    end

    it 'configures the connection with correct base URL' do
      expect(subject.connection.url_prefix.to_s).to eq('https://api.xendit.co/')
    end

    it 'configures Basic Auth with API key' do
      connection = subject.connection
      # Check that the connection has basic auth configured
      # We can't directly access the auth header since it's set by Faraday middleware
      expect(connection.builder.handlers).to include(Faraday::Request::Authorization)
    end

    it 'returns the same connection on subsequent calls' do
      expect(subject.connection).to be(subject.connection)
    end
  end

  describe 'HTTP methods' do
    describe '#get' do
      it 'makes GET request successfully' do
        stub_xendit_request(:get, '/test', response_body: { success: true })

        response = subject.get('/test')
        expect(response).to eq({ 'success' => true })
      end

      it 'includes query parameters' do
        stub_xendit_request(:get, '/test')
          .with(query: { param: 'value' })

        subject.get('/test', { param: 'value' })
      end

      it 'includes headers' do
        stub_xendit_request(:get, '/test')
          .with(headers: { 'Custom-Header' => 'value' })

        subject.get('/test', {}, { 'Custom-Header' => 'value' })
      end
    end

    describe '#post' do
      it 'makes POST request successfully' do
        stub_xendit_request(:post, '/test', response_body: { success: true })

        response = subject.post('/test', { data: 'value' })
        expect(response).to eq({ 'success' => true })
      end

      it 'includes request body' do
        stub_xendit_request(:post, '/test')
          .with(body: { data: 'value' }.to_json)

        subject.post('/test', { data: 'value' })
      end
    end

    describe '#patch' do
      it 'makes PATCH request successfully' do
        stub_xendit_request(:patch, '/test', response_body: { success: true })

        response = subject.patch('/test', { data: 'value' })
        expect(response).to eq({ 'success' => true })
      end
    end

    describe '#put' do
      it 'makes PUT request successfully' do
        stub_xendit_request(:put, '/test', response_body: { success: true })

        response = subject.put('/test', { data: 'value' })
        expect(response).to eq({ 'success' => true })
      end
    end

    describe '#delete' do
      it 'makes DELETE request successfully' do
        stub_xendit_request(:delete, '/test', response_body: { success: true })

        response = subject.delete('/test')
        expect(response).to eq({ 'success' => true })
      end
    end
  end

  describe 'error handling' do
    context 'with 400 status' do
      it 'raises ValidationError for API_VALIDATION_ERROR' do
        stub_xendit_request(:get, '/test',
                            status: 400,
                            response_body: { error_code: 'API_VALIDATION_ERROR', message: 'Invalid request' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::ValidationError, 'Invalid request')
      end

      it 'raises DuplicateError for DUPLICATE_ERROR' do
        stub_xendit_request(:get, '/test',
                            status: 400,
                            response_body: { error_code: 'DUPLICATE_ERROR', message: 'Resource already exists' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::DuplicateError, 'Resource already exists')
      end

      it 'raises InsufficientBalanceError for INSUFFICIENT_BALANCE' do
        stub_xendit_request(:get, '/test',
                            status: 400,
                            response_body: { error_code: 'INSUFFICIENT_BALANCE', message: 'Not enough balance' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::InsufficientBalanceError, 'Not enough balance')
      end

      it 'raises BadRequestError for unknown error codes' do
        stub_xendit_request(:get, '/test',
                            status: 400,
                            response_body: { error_code: 'UNKNOWN_ERROR', message: 'Unknown error' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::BadRequestError, 'Unknown error')
      end
    end

    context 'with 401 status' do
      it 'raises AuthenticationError' do
        stub_xendit_request(:get, '/test', status: 401, response_body: { message: 'Unauthorized' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::AuthenticationError, 'Unauthorized')
      end
    end

    context 'with 403 status' do
      it 'raises ForbiddenError' do
        stub_xendit_request(:get, '/test', status: 403, response_body: { message: 'Forbidden' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::ForbiddenError, 'Forbidden')
      end
    end

    context 'with 404 status' do
      it 'raises NotFoundError' do
        stub_xendit_request(:get, '/test', status: 404, response_body: { message: 'Not found' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::NotFoundError, 'Not found')
      end
    end

    context 'with 409 status' do
      it 'raises ConflictError' do
        stub_xendit_request(:get, '/test', status: 409, response_body: { message: 'Conflict' })

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::ConflictError, 'Conflict')
      end
    end

    context 'with 429 status' do
      it 'raises RateLimitError' do
        stub_xendit_request(:get, '/test', status: 429)

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::RateLimitError, 'Rate limit exceeded')
      end
    end

    context 'with 500 status' do
      it 'raises ServerError' do
        stub_xendit_request(:get, '/test', status: 500)

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::ServerError, 'Internal server error')
      end
    end

    context 'with timeout' do
      it 'raises TimeoutError' do
        allow(subject.connection).to receive(:get).and_raise(Faraday::TimeoutError)

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::TimeoutError, 'Request timeout')
      end
    end

    context 'with connection failure' do
      it 'raises ConnectionError' do
        allow(subject.connection).to receive(:get).and_raise(Faraday::ConnectionFailed)

        expect { subject.get('/test') }
          .to raise_error(Xendit::Errors::ConnectionError, 'Connection failed')
      end
    end
  end
end
