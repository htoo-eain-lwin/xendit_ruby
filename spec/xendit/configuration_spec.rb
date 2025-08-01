RSpec.describe Xendit::Configuration do
  subject { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(subject.base_url).to eq('https://api.xendit.co')
      expect(subject.timeout).to eq(30)
      expect(subject.open_timeout).to eq(10)
      expect(subject.faraday_adapter).to eq(Faraday.default_adapter)
      expect(subject.api_key).to be_nil
    end
  end

  describe '#valid?' do
    context 'when api_key is nil' do
      it 'returns false' do
        subject.api_key = nil
        expect(subject.valid?).to be false
      end
    end

    context 'when api_key is empty string' do
      it 'returns false' do
        subject.api_key = ''
        expect(subject.valid?).to be false
      end
    end

    context 'when api_key is present' do
      it 'returns true' do
        subject.api_key = 'test_key'
        expect(subject.valid?).to be true
      end
    end
  end

  describe 'attribute accessors' do
    it 'allows setting and getting api_key' do
      subject.api_key = 'test_api_key'
      expect(subject.api_key).to eq('test_api_key')
    end

    it 'allows setting and getting base_url' do
      subject.base_url = 'https://custom.xendit.co'
      expect(subject.base_url).to eq('https://custom.xendit.co')
    end

    it 'allows setting and getting timeout' do
      subject.timeout = 60
      expect(subject.timeout).to eq(60)
    end

    it 'allows setting and getting open_timeout' do
      subject.open_timeout = 20
      expect(subject.open_timeout).to eq(20)
    end

    it 'allows setting and getting faraday_adapter' do
      subject.faraday_adapter = :test
      expect(subject.faraday_adapter).to eq(:test)
    end
  end
end
