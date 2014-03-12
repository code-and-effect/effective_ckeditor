effectiveRegionsSave = {
  exec: (editor) ->
    data = {}

    console.log CKEDITOR.instances.length

    for instance, value of CKEDITOR.instances # All CKEditors on the whole page
      console.log "instance"
      console.log instance
      console.log value
      data[instance] = instance.getData()

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


 # var $editors = $("textarea.ckeditor");
 #    if ($editors.length) {
 #        $editors.each(function() {
 #            var instance = CKEDITOR.instances[$(this).attr("id")];
 #            if (instance) { $(this).val(instance.getData()); }
 #        });
 #    }
