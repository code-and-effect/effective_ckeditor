CKEDITOR.disableAutoInline = true

# Disable drag & dropping into regions (fixes issues with simple regions)
$(document).on 'drop', '.effective-region', (event) -> event.preventDefault()

# Don't propogate click events up
$(document).on 'click', '.effective-region', (event) -> event.stopPropagation()

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
      startupOutlineBlocks = true
    when 'snippets'
      enterMode = CKEDITOR.ENTER_BR
      startupOutlineBlocks = false
    when 'simple'
      enterMode = CKEDITOR.ENTER_BR
      startupOutlineBlocks = false

  CKEDITOR.inline(editor_div.id,
    toolbar: region
    allowedSnippets: $(editor_div).data('allowed-snippets')
    customConfig: '/assets/effective_ckeditor/config.js'
    enterMode: enterMode
    startupOutlineBlocks: startupOutlineBlocks
    disableNativeTableHandles: true
    sharedSpaces:
      top: 'effective-ckeditor-top'
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

