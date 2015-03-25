CKEDITOR.disableAutoInline = true
CKEDITOR.dtd.$removeEmpty['i'] = false

# Disable drag & dropping into regions (fixes issues with simple regions)
$(document).on 'drop', '.effective-region', (event) -> event.preventDefault()

# Don't propogate click events up
$(document).on 'click', '.effective-region', (event) ->
  event.stopPropagation()
  event.preventDefault()

$ -> init()

init = ->
  instance.destroy(true) for instance in CKEDITOR.instances

  ckeditors = $('[data-effective-ckeditor]')

  if ckeditors.length
    $('body').prepend("<div id='effective-ckeditor-top'></div>").addClass('effective-ckeditor-editting')

    $(window).on 'beforeunload', (event) -> promptToSaveIfDirty(event)
    $(window).on 'unload', (event) -> $.cookie('effective_regions_editting', '', {path: '/', expires: -1})

    ckeditors.each ->
      editor_div = $(this)

      if editor_div.is(':visible')
        initEditor(this)
      else
        affixBootstrapMenu(editor_div)
        editor_div.on 'click', -> try initEditor(this)

initEditor = (editor_div) ->
  region = $(editor_div).data('effective-ckeditor')

  switch region
    when 'full'
      enterMode = CKEDITOR.ENTER_P
      shiftEnterMode = CKEDITOR.ENTER_BR
      startupOutlineBlocks = true
      toolbar = 'full'
    when 'snippets'
      enterMode = CKEDITOR.ENTER_BR
      shiftEnterMode = CKEDITOR.ENTER_BR
      startupOutlineBlocks = false
      toolbar = 'snippets'
    when 'simple'
      enterMode = CKEDITOR.ENTER_BR
      shiftEnterMode = CKEDITOR.ENTER_BR
      startupOutlineBlocks = false
      toolbar = 'simple'

  CKEDITOR.inline(editor_div.id,
    toolbar: toolbar
    allowedSnippets: $(editor_div).data('allowed-snippets')
    effectiveRegionType: region
    customConfig: ''
    enterMode: enterMode
    shiftEnterMode: shiftEnterMode
    startupOutlineBlocks: startupOutlineBlocks
    disableNativeTableHandles: true
    sharedSpaces:
      top: 'effective-ckeditor-top'
    startupShowBorders: true
    extraPlugins: 'effective_regions,effective_assets,effective_menus,effective_references'
    format_tags: 'p;h1;h2;h3;h4;h5;h6;pre;div'
    templates: 'effective_regions'
    templates_files: []
    templates_replaceContent: false
    filebrowserWindowHeight: 600
    filebrowserWindowWidth: 800
    filebrowserBrowseUrl: '/effective/assets?only=images'
    referencesEditorSelector:"'#' + editor.name"
    toolbar_full: [
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
      { name: 'insert2', items: ['Table', 'EffectiveReferences', 'Blockquote', 'HorizontalRule', 'PageBreak'] },
      { name: 'snippets', items: ['Templates', 'InsertSnippet'] }
    ]
    toolbar_snippets: [
      ['Save', '-', 'NewPage'],
      ['Sourcedialog', '-', 'ShowBlocks'],
      ['Undo', 'Redo'],
      { name: 'snippets', items: ['InsertSnippet'] },
      ['Exit']
    ]
    toolbar_simple: [
      ['Save', '-', 'NewPage'],
      ['Undo', 'Redo'],
      ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'],
      ['Exit']
    ]
  )

promptToSaveIfDirty = (event) ->
  dirty = false

  for name, instance of CKEDITOR.instances
    if instance.checkDirty()
      dirty = true
      break

  if dirty
    'You have unsaved changes'
  else
    event.stopPropagation()

affixBootstrapMenu = (editor_div) ->
  dropdown_menu = editor_div.closest('.dropdown-menu')

  if dropdown_menu.length > 0
    dropdown_menu.on 'click', (event) -> event.stopPropagation()

    dropdown = editor_div.closest('.dropdown')
    dropdown.on 'hide.bs.dropdown', (event) -> event.preventDefault()
    dropdown.on 'click.bs.dropdown', (event) -> event.preventDefault()
    dropdown.on 'click', (event) ->
      $(this).removeClass('open') and event.stopPropagation() if $(this).hasClass('open')
