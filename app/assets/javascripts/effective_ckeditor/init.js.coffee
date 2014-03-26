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
      CKEDITOR.inline(this.id,
        toolbar: $(this).data('effective-ckeditor')
        customConfig: '/assets/effective_ckeditor/config.js'
        disableNativeTableHandles: true
        sharedSpaces:
          top: 'effective-ckeditor-top'
          bottom: 'effective-ckeditor-bottom'
      )
