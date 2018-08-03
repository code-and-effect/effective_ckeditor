$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'effective_ckeditor/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'effective_ckeditor'
  s.version     = EffectiveCkeditor::VERSION
  s.authors     = ['Code and Effect']
  s.email       = ['info@codeandeffect.com']
  s.homepage    = 'https://github.com/code-and-effect/effective_ckeditor'
  s.summary     = 'Wraps the CKEditor 4 Javscript library (http://ckeditor.com/) for use with the effective_regions gem.'
  s.description = 'Wraps the CKEditor 4 Javscript library (http://ckeditor.com/) for use with the effective_regions gem. Not intended for use as a standalone gem.'
  s.licenses    = ['MIT']

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'rails', ['>= 3.2.0']
  s.add_dependency 'sass'
end
