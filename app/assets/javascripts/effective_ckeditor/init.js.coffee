CKEDITOR.disableAutoInline = true

$ -> init()

init = ->
  instance.destroy(true) for instance in CKEDITOR.instances
  
  ckeditors = $('div[data-effective-ckeditor]')

  if ckeditors.length
    $('body').prepend("<div id='effective-ckeditor-top'></div>")
    $('body').append("<div id='effective-ckeditor-bottom'></div>")
    $('body').addClass('effective-ckeditor-editting')

    ckeditors.each -> 
      if $(this).is(':visible')
        initEditor(this)
      else
        $(this).on 'click', -> try initEditor(this)

initEditor = (div) ->
  CKEDITOR.inline(div.id,
    toolbar: $(div).data('effective-ckeditor')
    customConfig: '/assets/effective_ckeditor/config.js'
    disableNativeTableHandles: true
    sharedSpaces:
      top: 'effective-ckeditor-top'
      bottom: 'effective-ckeditor-bottom'
  )
