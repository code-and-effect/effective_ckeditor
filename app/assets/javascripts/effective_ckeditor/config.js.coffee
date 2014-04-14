CKEDITOR.editorConfig = (config) ->
  config.startupShowBorders = true

  config.extraPlugins = 'effective_regions'

  config.format_tags = 'p;h1;h2;h3;h4;pre'

  config.toolbar_full = [
    { name: 'save', items: ['Save', '-', 'NewPage'] },
    { name: 'editing', items: ['Undo', 'Redo'] },
    { name: 'clipboard', items: ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'] },
    { name: 'find', items: ['Find', 'Replace', '-', 'SelectAll'] },
    { name: 'links', items: ['Link', 'Unlink', 'Anchor'] },
    { name: 'insert', items: ['Image', 'tliyoutube', 'Table', 'HorizontalRule', 'PageBreak'] },
    { name: 'html', items: ['Sourcedialog', '-', 'ShowBlocks'] },
    ['Exit']
    '/',
    { name: 'definedstyleszzz', items: ['Styles', 'Format'] },
    { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat'] },
    { name: 'colors', items: ['TextColor', 'BGColor'] },
    { name: 'lists', items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', 'CreateDiv'] },
    { name: 'snippets', items: ['InsertSnippet'] }
  ]

  config.toolbar_simple = [
    ['Save', '-', 'NewPage'], 
    ['Undo', 'Redo'],
    ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'],
    ['Find', 'Replace', '-', 'SelectAll'],
    ['Exit']
  ]

  config.toolbar_snippets = [
    ['Save', '-', 'NewPage'], 
    ['Undo', 'Redo'],
    ['Sourcedialog', '-', 'ShowBlocks'],
    { name: 'snippets', items: ['InsertSnippet'] },
    ['Exit']
  ]

