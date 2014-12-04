$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "effective_ckeditor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "effective_ckeditor"
  s.version     = EffectiveCkeditor::VERSION
  s.authors     = ["Code and Effect"]
  s.email       = ["info@codeandeffect.com"]
  s.homepage    = "https://github.com/code-and-effect/effective_ckeditor"
  s.summary     = "Wraps the CKEditor Javscript library (http://ckeditor.com/) for use with the effective_regions gem."
  s.description = "Wraps the CKEditor Javscript library (http://ckeditor.com/) for use with the effective_regions gem. Not intended for use as a standalone gem."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails"

  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "sqlite3"
end
