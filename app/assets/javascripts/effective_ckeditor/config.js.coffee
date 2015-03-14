CKEDITOR.editorConfig = (config) ->
  config.startupShowBorders = true

  config.extraPlugins = 'effective_regions,effective_assets,effective_menus,footnotes'
  config.format_tags = 'p;h1;h2;h3;h4;h5;h6;pre;div'

  config.templates = 'effective_regions'
  config.templates_files = []
  config.templates_replaceContent = false

  config.filebrowserWindowHeight = 600
  config.filebrowserWindowWidth = 800
  config.filebrowserBrowseUrl = '/effective/assets?only=images'

  config.footnotesEditorSelector = "'#' + editor.name"

  CKEDITOR.dtd.$removeEmpty['i'] = false

  config.toolbar_full = [
    { name: 'save', items: ['Save', '-', 'NewPage'] },
    { name: 'html', items: ['Sourcedialog', '-', 'ShowBlocks'] },
    { name: 'editing', items: ['Undo', 'Redo'] },
    { name: 'clipboard', items: ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'] },
    { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat'] },
    ['Exit']
    '/',
    { name: 'definedstyles', items: ['Format'] },
    { name: 'links', items: ['Link', 'Unlink'] },
    { name: 'insert', items: ['Image', 'oembed', 'EffectiveAssets'] },
    { name: 'lists', items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent'] },
    { name: 'insert2', items: ['Table', 'Footnotes', 'Blockquote', 'HorizontalRule', 'PageBreak'] },
    { name: 'snippets', items: ['Templates', 'InsertSnippet'] }
  ]

  config.toolbar_snippets = [
    ['Save', '-', 'NewPage'],
    ['Sourcedialog', '-', 'ShowBlocks'],
    ['Undo', 'Redo'],
    { name: 'snippets', items: ['InsertSnippet'] },
    ['Exit']
  ]

  config.toolbar_simple = [
    ['Save', '-', 'NewPage'],
    ['Undo', 'Redo'],
    ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'],
    ['Exit']
  ]
