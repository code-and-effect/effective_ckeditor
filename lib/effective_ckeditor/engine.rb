module EffectiveCkeditor
  class Engine < ::Rails::Engine
    engine_name 'effective_ckeditor'
    isolate_namespace EffectiveCkeditor

    # Include Helpers to base application
    initializer 'effective_ckeditor.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper EffectiveCkeditorHelper
      end
    end

    # Set up our default configuration options.
    initializer "effective_ckeditor.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_ckeditor.rb")
    end

  end
end
