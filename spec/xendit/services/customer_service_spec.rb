RSpec.describe Xendit::Services::CustomerService do
  let(:client) { instance_double(Xendit::Client) }
  subject { described_class.new(client) }

  describe '#create' do
    let(:valid_individual_params) do
      {
        reference_id: 'customer-123',
        type: 'INDIVIDUAL',
        individual_detail: {
          given_names: 'John',
          surname: 'Doe',
          nationality: 'ID'
        },
        email: 'john.doe@example.com',
        mobile_number: '+6281234567890'
      }
    end

    let(:expected_response) do
      {
        'id' => 'cust-123456789',
        'reference_id' => 'customer-123',
        'type' => 'INDIVIDUAL',
        'email' => 'john.doe@example.com',
        'created' => '2024-01-01T00:00:00Z'
      }
    end

    before do
      allow(client).to receive(:post).and_return(expected_response)
    end

    it 'creates individual customer successfully' do
      result = subject.create(valid_individual_params)

      expect(client).to have_received(:post).with('/customers', anything, anything)
      expect(result).to be_a(Xendit::Models::Customer)
      expect(result.id).to eq('cust-123456789')
      expect(result.type).to eq('INDIVIDUAL')
      expect(result.reference_id).to eq('customer-123')
    end

    it 'includes individual detail in request body' do
      subject.create(valid_individual_params)

      expect(client).to have_received(:post) do |_path, body, _headers|
        expect(body[:individual_detail]).to include(
          given_names: 'John',
          surname: 'Doe',
          nationality: 'ID'
        )
      end
    end

    context 'with business customer' do
      let(:business_params) do
        {
          reference_id: 'business-123',
          type: 'BUSINESS',
          business_detail: {
            business_name: 'Acme Corp',
            business_type: 'CORPORATION',
            nature_of_business: 'Technology'
          },
          email: 'admin@acme.com'
        }
      end

      it 'creates business customer successfully' do
        subject.create(business_params)

        expect(client).to have_received(:post) do |_path, body, _headers|
          expect(body[:type]).to eq('BUSINESS')
          expect(body[:business_detail]).to include(
            business_name: 'Acme Corp',
            business_type: 'CORPORATION'
          )
        end
      end
    end

    context 'with headers' do
      let(:params_with_headers) do
        valid_individual_params.merge(idempotency_key: 'customer-idem-123')
      end

      it 'includes custom headers' do
        subject.create(params_with_headers)

        expect(client).to have_received(:post) do |_path, _body, headers|
          expect(headers).to include('idempotency-key' => 'customer-idem-123')
        end
      end
    end

    context 'with validation errors' do
      it 'raises ValidationError when reference_id is missing' do
        invalid_params = valid_individual_params.except(:reference_id)

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /reference_id.*required/)
      end

      it 'raises ValidationError when type is missing' do
        invalid_params = valid_individual_params.except(:type)

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /type.*required/)
      end

      it 'raises ValidationError for invalid customer type' do
        invalid_params = valid_individual_params.merge(type: 'INVALID_TYPE')

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /customer type must be one of/)
      end

      it 'raises ValidationError when individual_detail is missing for INDIVIDUAL type' do
        invalid_params = valid_individual_params.except(:individual_detail)

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /individual_detail is required/)
      end

      it 'raises ValidationError when given_names is missing in individual_detail' do
        invalid_params = valid_individual_params.dup
        invalid_params[:individual_detail] = invalid_params[:individual_detail].except(:given_names)

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /given_names is required/)
      end

      it 'raises ValidationError when business_detail is missing for BUSINESS type' do
        invalid_params = {
          reference_id: 'business-123',
          type: 'BUSINESS'
        }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /business_detail is required/)
      end

      it 'raises ValidationError when business_name is missing in business_detail' do
        invalid_params = {
          reference_id: 'business-123',
          type: 'BUSINESS',
          business_detail: {
            business_type: 'CORPORATION'
          }
        }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /business_name.*required/)
      end

      it 'validates gender in individual_detail' do
        invalid_params = valid_individual_params.dup
        invalid_params[:individual_detail][:gender] = 'INVALID_GENDER'

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /gender must be one of/)
      end

      it 'validates business_type in business_detail' do
        invalid_params = {
          reference_id: 'business-123',
          type: 'BUSINESS',
          business_detail: {
            business_name: 'Acme Corp',
            business_type: 'INVALID_TYPE'
          }
        }

        expect { subject.create(invalid_params) }
          .to raise_error(Xendit::Errors::ValidationError, /business_type must be one of/)
      end
    end
  end

  describe '#get' do
    let(:customer_id) { 'cust-123456789' }
    let(:expected_response) do
      {
        'id' => customer_id,
        'type' => 'INDIVIDUAL',
        'reference_id' => 'customer-123',
        'email' => 'john.doe@example.com'
      }
    end

    before do
      allow(client).to receive(:get).and_return(expected_response)
    end

    it 'retrieves customer by ID' do
      result = subject.get(customer_id)

      expect(client).to have_received(:get).with("/customers/#{customer_id}")
      expect(result).to be_a(Xendit::Models::Customer)
      expect(result.id).to eq(customer_id)
      expect(result.type).to eq('INDIVIDUAL')
    end
  end
end
