require_relative 'lib/xendit/version'

Gem::Specification.new do |spec|
  spec.name          = 'xendit-ruby'
  spec.version       = Xendit::VERSION
  spec.authors       = ['Htoo']
  spec.email         = ['htooeainlwin12@gmail.com']

  spec.summary       = 'Ruby SDK for Xendit Payment Gateway API'
  spec.description   = 'A comprehensive Ruby gem for integrating with Xendit payment gateway services including payments, refunds, and payment methods.'
  spec.homepage      = 'https://github.com/htoo-eain-lwin/xendit-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/htoo-eain-lwin/xendit-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/htoo-eain-lwin/xendit-ruby/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'faraday-multipart', '~> 1.0'
  spec.add_dependency 'multi_json', '~> 1.15'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
