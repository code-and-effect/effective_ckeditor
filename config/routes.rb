Rails.application.routes.draw do
  scope :module => 'effective' do
    # scope '/effective/mercury' do
    #   match ':type/:resource' => 'mercury#resource', :via => [:get], :as => :effective_ckeditor_resource
    #   match 'snippets/:name/options' => 'mercury#snippet_options', :via => [:get, :post], :as => :effective_ckeditor_snippet_option
    #   match 'snippets/:name/preview' => 'mercury#snippet_preview', :via => [:get, :post], :as => :effective_ckeditor_snippet_preview
    # end
  end
end
