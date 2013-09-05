# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "monga"
  spec.version       = "0.0.11"
  spec.authors       = ["Petr Yanovich"]
  spec.email         = ["fl00r@yandex.ru"]
  spec.description   = %q{Yet another MongoDB Ruby Client}
  spec.summary       = %q{Yet another MongoDB Ruby Client}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "kgio"
  spec.add_development_dependency "em-synchrony"

  spec.add_dependency "bson", ["2.0.0.rc1"]
  # spec.add_dependency "bson"
  # spec.add_dependency "bson_ext"
  spec.add_dependency "bin_utils"
end
