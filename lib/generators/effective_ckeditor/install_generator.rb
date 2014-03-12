module EffectiveCkeditor
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Creates an EffectiveCkeditor initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def copy_initializer
        template "effective_ckeditor.rb", "config/initializers/effective_ckeditor.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
