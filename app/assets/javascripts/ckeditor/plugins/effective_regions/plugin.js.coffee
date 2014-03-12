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

CKEDITOR.plugins.add 'effective_regions',
  icons: 'save',
  hidpi: true,
  init: (editor) ->
    editor.ui.addButton 'Save',
      label: 'Save'
      command: 'effectiveRegionsSave'
      toolbar: 'document'

    editor.addCommand('effectiveRegionsSave', effectiveRegionsSave)
