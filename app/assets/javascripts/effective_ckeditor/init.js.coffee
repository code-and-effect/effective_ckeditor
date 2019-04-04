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

    initTemplates()

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

  ckeditor = CKEDITOR.inline(editor_div.id,
    toolbar: toolbar
    allowedSnippets: $(editor_div).data('allowed-snippets')
    effectiveRegionType: region
    customConfig: ''
    enterMode: enterMode
    shiftEnterMode: shiftEnterMode
    startupOutlineBlocks: startupOutlineBlocks
    disableNativeTableHandles: true
    disableNativeSpellChecker: false
    sharedSpaces:
      top: 'effective-ckeditor-top'
    startupShowBorders: true
    extraPlugins: 'base64image,effective_regions,effective_assets,effective_menus,effective_references'
    format_tags: 'p;h1;h2;h3;h4;h5;h6;pre;div'
    templates: 'effective_regions'
    templates_files: []
    templates_replaceContent: false
    filebrowserWindowHeight: 600
    filebrowserWindowWidth: 800
    filebrowserBrowseUrl: '/effective/assets'
    filebrowserImageBrowseUrl: '/effective/assets?only=images'
    referencesEditorSelector:"'#' + editor.name"
    toolbar_full: [
      { name: 'save', items: ['Save', '-', 'NewPage'] },
      { name: 'html', items: ['Sourcedialog', '-', 'ShowBlocks'] },
      { name: 'editing', items: ['Undo', 'Redo'] },
      { name: 'clipboard', items: ['Cut', 'Copy', 'Paste', 'PasteText', 'PasteFromWord'] },
      { name: 'justify', items: ['JustifyLeft', 'JustifyCenter', 'JustifyRight']}
      { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat'] },
      ['Exit']
      '/',
      { name: 'definedstyles', items: ['Format'] },
      { name: 'links', items: ['Link', 'Unlink', '-', 'Anchor'] },
      { name: 'insert', items: ['Image', 'base64image', 'oembed'] },
      { name: 'lists', items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent'] },
      { name: 'insert2', items: ['Table', 'EffectiveReferences', 'Blockquote', 'HorizontalRule', 'PageBreak'] },
      { name: 'colors', items: ['TextColor', 'BGColor'] },
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

  ckeditor.on 'insertElement', (event) ->
    element = $(event.data.$)
    if element.is('table')
      element.removeAttr('style').addClass('table')

initTemplates = ->
  templates = ((CKEDITOR.config['effective_regions'] || {})['templates'] || {})

  CKEDITOR.addTemplates 'effective_regions',
    imagesPath: CKEDITOR.getUrl( window.location.protocol + '//' + window.location.host + '/assets/effective/templates/' ),
    templates: template for template in templates

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


# # This removes the width and height attributes from being set on an image
# # The attributes will come back if you drag & drop resize the image
# CKEDITOR.on 'dialogDefinition', (ev) ->
#   dialogName = ev.data.name
#   dialogDefinition = ev.data.definition

#   if (dialogName == 'image2')
#     try
#       dialogDefinition.contents['0'].elements['2'].style = 'display: none;'  # Hide width/height fields entirely

#       widthDefinition = dialogDefinition.contents['0'].elements['2'].children['0']
#       heightDefinition = dialogDefinition.contents['0'].elements['2'].children['1']

#       if widthDefinition['label'] == 'Width'
#         widthDefinition.commit = (widget) -> widget.setData('width', null)

#       if heightDefinition['label'] == 'Height'
#         heightDefinition.commit = (widget) -> widget.setData('height', null)
