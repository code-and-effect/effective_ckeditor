CKEDITOR.disableAutoInline = true

# Disable drag & dropping into regions (fixes issues with simple regions)
$(document).on 'drop', 'div.effective-region', (event) -> event.preventDefault()

# Don't propogate click events up
$(document).on 'click', 'div.effective-region', (event) -> event.stopPropagation()

$ -> init()

init = ->
  instance.destroy(true) for instance in CKEDITOR.instances
  
  ckeditors = $('[data-effective-ckeditor]')

  if ckeditors.length
    $('body').prepend("<div id='effective-ckeditor-top'></div>")
    $('body').append("<div id='effective-ckeditor-bottom'></div>")
    $('body').addClass('effective-ckeditor-editting')

    ckeditors.each -> 
      editor_div = $(this)

      if editor_div.is(':visible')
        initEditor(this)
      else
        editor_div.on 'click', -> try initEditor(this)

      # This tweaks the bootstrap menu behaviour to be click-on, click-off, rather than close on blur
      dropdown_menu = editor_div.closest('.dropdown-menu')
      if dropdown_menu.length > 0 
        dropdown_menu.on 'click', (event) -> event.stopPropagation()

        dropdown = editor_div.closest('.dropdown')
        dropdown.on 'hide.bs.dropdown', (event) -> event.preventDefault()
        dropdown.on 'click.bs.dropdown', (event) -> event.preventDefault()
        dropdown.on 'click', (event) ->
          $(this).removeClass('open') and event.stopPropagation() if $(this).hasClass('open')


initEditor = (editor_div) ->
  CKEDITOR.inline(editor_div.id,
    toolbar: $(editor_div).data('effective-ckeditor')
    customConfig: '/assets/effective_ckeditor/config.js'
    disableNativeTableHandles: true
    sharedSpaces:
      top: 'effective-ckeditor-top'
      bottom: 'effective-ckeditor-bottom'
  )
