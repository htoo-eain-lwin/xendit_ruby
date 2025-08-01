require 'bundler/setup'
require 'xendit'
require 'webmock/rspec'
require 'vcr'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri headers body]
  }
  config.filter_sensitive_data('<API_KEY>') { |interaction| interaction.request.headers['Authorization']&.first }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.order = :random
  Kernel.srand config.seed

  # Reset Xendit configuration before each test
  config.before(:each) do
    Xendit.reset!
  end

  # Shared contexts and helpers
  config.include(Module.new do
    def configure_xendit(api_key: 'test_api_key')
      Xendit.configure do |config|
        config.api_key = api_key
        config.base_url = 'https://api.xendit.co'
      end
    end

    def stub_xendit_request(method, path, response_body: {}, status: 200, headers: {})
      stub_request(method, "https://api.xendit.co#{path}")
        .to_return(
          status: status,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }.merge(headers)
        )
    end
  end)
end
