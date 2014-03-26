SaveAll = {
  instanceData: (instance) ->
    snippets = {} # This is the Data we're going to post to the server
    snippet_ids = [] # This keeps track html classes we need to later replace

    for id, widget of instance.widgets.instances
      if widget.element.data('effective-snippet')
        snippet_id = "snippet_#{id}"
        snippets[snippet_id] = widget.data
        snippets[snippet_id]['class_name'] = widget.name
        widget.element.addClass(snippet_id)
        snippet_ids.push(snippet_id)

    # Replace the entire widget <div>...</div> with [snippet_0]
    content = $('<div>' + instance.getData() + '</div>')
    content.find("div.#{snippet_id}").replaceWith("[#{snippet_id}]") for snippet_id in snippet_ids

    {content: content.html(), snippets: snippets}

  exec: (editor) ->
    data = {}
    data[name] = @instanceData(instance) for name, instance of CKEDITOR.instances

    url = window.location.protocol + '//' + window.location.host + '/edit' + window.location.pathname

    $.ajax
      url: url
      type: 'PUT'
      dataType: 'json'
      data: { effective_regions: data }
      async: false
}

Regions = {
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

  initSnippetsRegion: (editor) ->
}

Snippets = {
  snippets: undefined

  all: ->
    if @snippets == undefined
      $.ajax
        url: '/effective_regions/snippets'
        type: 'GET'
        dataType: 'json'
        async: false
        complete: (data) -> Snippets.snippets = data.responseJSON
    @snippets

  build: (editor, name, values) ->
    snippet = {}

    snippet['configured'] = false
    snippet['template'] = "<div class='#{name}_snippet' data-effective-snippet='{}'></div>"
    snippet['dialog_url'] = values.dialog_url
    snippet['dialog'] = name if values.dialog_url
    snippet['requiredContent'] = "div(#{name}_snippet)"
    snippet['upcast'] = (element) -> element.name == 'div' && element.hasClass(name + '_snippet')

    snippet['loadTemplate'] = (widget) ->
      $.ajax
        url: '/effective_regions/snippet'
        type: 'GET'
        data: {effective_regions: {name: widget.name, data: widget.data}}
        async: false
        complete: (data) -> $(widget.wrapper.$).find('div.cke_widget_element').html(data.responseText)

    snippet['init'] = ->
      for k, v of $(this.wrapper.$).find('div.cke_widget_element').data('effective-snippet')
        this.data[k] = v

      this.on 'dialog', (evt) -> @configured = true
      this.on 'data', (evt) -> @loadTemplate(evt.sender) if @configured

    snippet
}

CKEDITOR.plugins.add 'effective_regions',
  requires: 'widget',
  icons: 'save,snippet',
  hidpi: true,
  init: (editor) ->
    # Saving
    editor.ui.addButton 'Save', {label: 'Save', command: 'effectiveRegionsSaveAll'}
    editor.addCommand('effectiveRegionsSaveAll', SaveAll)

    # Regions
    Regions.initSimpleRegion(editor) if editor.config.toolbar == 'simple'
    Regions.initSnippetsRegion(editor) if editor.config.toolbar == 'snippets'

    # Snippets
    all_snippets = Snippets.all()

    # Build the Insert Snippets Dropdown
    editor.ui.addRichCombo('InsertSnippet',
      label: 'Insert Snippet',
      title: 'Insert Snippet',
      panel: 
        css: [ CKEDITOR.skin.getPath( 'editor' ) ].concat('width: 250px !important'),
        multiSelect: false,
      init: ->
        for name, values of all_snippets
          this.add name, "Insert #{name}", "Insert Snippet #{name}" # Command, Label, Tooltip
      onClick: (value) -> editor.getCommand(value).exec(editor)
    )

    # Initialize all the Snippets as CKeditor widgets
    for name, values of all_snippets
      snippet = Snippets.build(editor, name, values)

      editor.widgets.add(name, snippet)
      CKEDITOR.dialog.add(name, snippet.dialog_url) if snippet.dialog_url



