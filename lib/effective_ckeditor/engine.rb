module EffectiveCkeditor
  class Engine < ::Rails::Engine
    engine_name 'effective_ckeditor'
    isolate_namespace EffectiveCkeditor

    # Append some precompiled assets we need access to
    # This works in conjunction with the effective_ckeditor rake task that enhances assets:precompile
    initializer "effective_ckeditor.append_precompiled_assets" do |app|
      precompile = [
        'effective_ckeditor.js',
        'effective_ckeditor.css',
        'ckeditor/contents.css',
        'ckeditor/plugins/*',
        'ckeditor/skins/*',
        'effective/snippets/*',
      ]

      Rails.application.config.assets.precompile += precompile
    end

  end
end
