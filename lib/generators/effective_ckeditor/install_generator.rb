module EffectiveCkeditor
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Creates an EffectiveCKeditor initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
