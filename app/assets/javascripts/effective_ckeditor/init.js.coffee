CKEDITOR.disableAutoInline = true

$ -> init()
$(document).on 'page:change', -> init()

init = ->
  console.log "RUNNING INIT"
  ckeditors = $('div[data-effective-ckeditor]')

  if ckeditors.length
    $('body').prepend("<div id='effective-ckeditor-top'></div>")
    $('body').append("<div id='effective-ckeditor-bottom'></div>")
    $('body').addClass('effective-ckeditor-editting')

    ckeditors.each -> 
      # instance = CKEDITOR.instances[this.id]
      # if instance
      #   console.log "WELL THIS IS ALREADY HERE #{this.id}"
      #   instance.destroy(true)

      CKEDITOR.inline(this.id,
        toolbar: $(this).data('effective-ckeditor')
        customConfig: '/assets/effective_ckeditor/config.js'
        sharedSpaces:
          top: 'effective-ckeditor-top'
          bottom: 'effective-ckeditor-bottom'
      )

#       function loadEditors() {
#     var $editors = $("textarea.ckeditor");
#     if ($editors.length) {
#         $editors.each(function() {
#             var editorID = $(this).attr("id");
#             var instance = CKEDITOR.instances[editorID];
#             if (instance) { instance.destroy(true); }
#             CKEDITOR.replace(editorID);
#         });
#     }
# }

# init = ->
#   ckeditors = $('[data-ckeditor]')

#   if ckeditors.length
#     $('body').prepend("<div id='effective-ckeditor-top'></div>")
#     $('body').append("<div id='effective-ckeditor-bottom'></div>")
#     $('body').addClass('effective-ckeditor-editting')

#     ckeditors.each -> 
#       $this = $(this)

#       CKEDITOR.inline(this.id,
#         toolbar: $this.data('ckeditor')
#         customConfig: '/assets/effective_ckeditor/config.js'
#         sharedSpaces:
#           top: 'effective-ckeditor-top'
#           bottom: 'effective-ckeditor-bottom'
#       )

