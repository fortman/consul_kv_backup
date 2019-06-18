# frozen_string_literal: true

lib = File.expand_path('lib', '..')
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'consul_kv_backup'
  spec.version       = IO.read('VERSION').chomp
  spec.authors       = ['Ryan Fortman']
  spec.email         = ['r.fortman.dev@gmail.com']

  spec.summary       = 'Send consul watch events to an amqp.'
  spec.homepage      = 'https://github.com/fortman/consul_kv_backup'
  spec.metadata = {
    'docker_image_name' => 'rfortman/consul_kv_backup'
  } 

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  # spec.add_runtime_dependency 'bundler', '~> 2.0'
  spec.add_runtime_dependency 'diplomat', '~> 2.2.4'
  spec.add_dependency 'bunny', '~> 1.7.0'
  spec.add_dependency 'slop', '~> 4.6'
  spec.add_dependency 'flazm_ruby_helpers', '~> 0.0.3'
end
