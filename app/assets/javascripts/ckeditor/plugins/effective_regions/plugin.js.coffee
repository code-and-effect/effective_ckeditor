effectiveRegionsSave = {
  exec: (editor) ->
    data = {}

    for name, instance of CKEDITOR.instances # All CKEditors on the whole page
      data[name] = 
        content: instance.getData()

    url = window.location.protocol + '//' + window.location.host + '/edit' + window.location.pathname

    $.ajax
      url: url
      type: 'PUT'
      dataType: 'json'
      data: 
        effective_regions: data
      async: false
      success: (data) -> 
        console.log 'success!'
        console.log data
}

effectiveRegionsRegionTypes = {
  initSimpleRegion: (editor) ->
    # Disable all tags
    filter = new CKEDITOR.filter('effective_region')
    editor.setActiveFilter(filter)

    # Disable wrapping content with <p></p>.  This could break plugins.
    editor.config.autoParagraph = false
    editor.setActiveEnterMode(CKEDITOR.ENTER_BR, CKEDITOR.ENTER_BR)

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() if event.data.keyCode == 13

    # Paste as plain text, but this doesn't work all the way
    editor.config.forcePasteAsPlainText = true
    editor.on 'afterPaste', (evt) -> editor.setData(editor.getData().replace( /<[^<|>]+?>/gi,'')) 
}

CKEDITOR.plugins.add 'effective_regions',
  icons: 'save',
  hidpi: true,
  init: (editor) ->
    # Saving Stuff
    editor.ui.addButton 'Save',
      label: 'Save'
      command: 'effectiveRegionsSave'
      toolbar: 'document'

    editor.addCommand('effectiveRegionsSave', effectiveRegionsSave)

    # Region Types
    if editor.config.toolbar == 'simple'
      effectiveRegionsRegionTypes.initSimpleRegion(editor)




