CKEDITOR.plugins.add 'effective_snippets',
  requires: 'widget',
  icons: 'snippet',
  hidpi: true,
  init: (editor) ->
    console.log 'INIT EFFECTIVE SNIPPETS'

    CKEDITOR.dialog.add('effective_snippets', this.path + 'dialogs/effective_snippets.js')

    editor.widgets.add 'effective_snippets',
      button: 'effective_snippets',
      dialog: 'effective_snippets',
      template:
        '<div class="simplebox">' +
            '<h2 class="simplebox-title">Title</h2>' +
            '<div class="simplebox-content"><p>Content...</p></div>' +
        '</div>'
      # editables:
      #     title:
      #       selector: '.simplebox-title'
      #     content:
      #       selector: '.simplebox-content'
