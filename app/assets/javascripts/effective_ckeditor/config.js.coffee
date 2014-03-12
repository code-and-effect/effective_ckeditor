CKEDITOR.editorConfig = (config) ->
  config.startupShowBorders = true

  config.extraPlugins = 'effective_regions'

  config.toolbar_full = [
    ['Save','-', 'NewPage'], 
    ['Undo', 'Redo'],
    ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'],
    ['Find', 'Replace', '-', 'SelectAll'],
    ['Link', 'Unlink', 'Anchor'],
    ['Image', 'tliyoutube', 'Table', 'HorizontalRule', 'Smiley', 'SpecialChar', 'PageBreak'],
    ['Sourcedialog', '-', 'ShowBlocks'],
    '/',
    ['Styles', 'Format'],
    ['Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat'],
    ['TextColor', 'BGColor']
    ['JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock'],
    ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'Blockquote', 'CreateDiv']
  ]

  config.toolbar_simple = [
    ['Save', '-', 'NewPage'], 
    ['Undo', 'Redo'],
    ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'],
    ['Find', 'Replace', '-', 'SelectAll']
  ]

  config.toolbar_snippets = [
    ['Source', '-', 'Bold', 'Italic']
  ]

