CKEDITOR.dialog.add "effective_snippets", (editor) ->
  title: "Edit Effective Snippets"
  minWidth: 200
  minHeight: 100
  contents: [
    id: "info"
    elements: [
      {
        id: "align"
        type: "select"
        label: "Align"
        items: [
          [editor.lang.common.notSet, ""]
          [editor.lang.common.alignLeft, "left"]
          [editor.lang.common.alignRight, "right"]
          [editor.lang.common.alignCenter, "center"]
        ]
        
        # When setting up this field, set its value to the "align" value from widget data.
        # Note: Align values used in the widget need to be the same as those defined in the "items" array above.
        setup: (widget) -> @setValue widget.data.align
        
        # When committing (saving) this field, set its value to the widget data.
        commit: (widget) -> widget.setData "align", @getValue()
      },
      {
        id: "width"
        type: "text"
        label: "Width"
        width: "50px"
        setup: (widget) -> @setValue widget.data.width
        commit: (widget) -> widget.setData "width", @getValue()
      }
    ]
  ]
