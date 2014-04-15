SaveAll = {
  instanceData: (instance) ->
    instance.resetDirty()

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
    content.find(".#{snippet_id}").replaceWith("[#{snippet_id}]") for snippet_id in snippet_ids

    # Slightly different values for the different region types
    if instance.config.toolbar == 'snippets'
      content = content.text()
      content = content.replace(/\]\s+\[/gi, '') if content.indexOf('[snippet_') > -1
    else if instance.config.toolbar == 'simple'
      content = content.text()
    else
      content = content.html()

    {content: content, snippets: snippets}

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

Exit = {
  exec: (editor) -> 
    url = $.cookie('effective_regions_editting')

    if url != undefined && url.length > 0
      window.location = url
    else
      window.history.back()
}

Regions = {
  initFullRegion: (editor) -> true

  initSimpleRegion: (editor) ->
    # Disable all tags
    filter = new CKEDITOR.filter('no_tags_allowed')
    editor.setActiveFilter(filter)

    # Disable wrapping content with <p></p>.  This could break plugins.
    editor.config.autoParagraph = false
    editor.setActiveEnterMode(CKEDITOR.ENTER_BR, CKEDITOR.ENTER_BR)

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() if (event.data.keyCode == 13 || event.data.keyCode == 2228237)

    # Paste as plain text, but this doesn't work all the way
    editor.config.forcePasteAsPlainText = true
    editor.on 'afterPaste', (evt) -> editor.setData(editor.getData().replace( /<[^<|>]+?>/gi,'')) 

  initSnippetsRegion: (editor) ->
    # Disable wrapping content with <p></p>.  This could break plugins.
    editor.config.autoParagraph = false
    editor.setActiveEnterMode(CKEDITOR.ENTER_BR, CKEDITOR.ENTER_BR)

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() if (event.data.keyCode == 13 || event.data.keyCode == 2228237)

    # Paste as plain text, but this doesn't work all the way
    editor.config.forcePasteAsPlainText = true
    editor.on 'afterPaste', (evt) -> editor.setData(editor.getData().replace(/<[^<|>]+?>/gi,'')) 
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
    snippet['dialog_url'] = values.dialog_url
    snippet['dialog'] = name if values.dialog_url
    snippet['inline'] = values.inline

    snippet['template'] = "<#{values.wrapper_tag} class='#{name}_snippet' data-effective-snippet='{}'></#{values.wrapper_tag}>"
    snippet['requiredContent'] = "#{values.wrapper_tag}(#{name}_snippet)"
    snippet['upcast'] = (element) -> element.name == "#{values.wrapper_tag}" && element.hasClass(name + '_snippet')

    snippet['loadTemplate'] = (widget) ->
      $.ajax
        url: '/effective_regions/snippet'
        type: 'GET'
        data: {effective_regions: {name: widget.name, data: widget.data}}
        async: false
        complete: (data) -> $(widget.wrapper.$).find('.cke_widget_element').html(data.responseText)

    snippet['init'] = ->
      for k, v of $(this.wrapper.$).find('.cke_widget_element').data('effective-snippet')
        this.data[k] = v

      this.on 'dialog', (evt) -> @configured = true
      this.on 'data', (evt) -> @loadTemplate(evt.sender) if @configured

    snippet
}

CKEDITOR.plugins.add 'effective_regions',
  requires: 'widget',
  icons: 'save,exit',
  hidpi: true,
  init: (editor) ->
    # Saving
    editor.ui.addButton 'Save', {label: 'Save', command: 'effectiveRegionsSaveAll'}
    editor.addCommand('effectiveRegionsSaveAll', SaveAll)

    # Exit Button
    editor.ui.addButton 'Exit', {label: 'Exit', command: 'effectiveRegionsExit'}
    editor.addCommand('effectiveRegionsExit', Exit)

    # Regions
    Regions.initSimpleRegion(editor) if editor.config.toolbar == 'simple'
    Regions.initSnippetsRegion(editor) if editor.config.toolbar == 'snippets'
    Regions.initFullRegion(editor) if editor.config.toolbar == 'full'

    # Snippets
    all_snippets = Snippets.all()

    # Build the Insert Snippets Dropdown
    editor.ui.addRichCombo 'InsertSnippet',
      label: 'Insert Snippet',
      title: 'Insert Snippet',
      panel: 
        css: [ CKEDITOR.skin.getPath( 'editor' ) ],
        multiSelect: false,
      init: ->
        for name, values of all_snippets
          this.add name, "#{values.label}", "#{values.description}" # Command, Label, Tooltip
      onClick: (value) -> editor.getCommand(value).exec(editor)

    # Initialize all the Snippets as CKeditor widgets
    for name, values of all_snippets
      snippet = Snippets.build(editor, name, values)

      editor.widgets.add(name, snippet)
      CKEDITOR.dialog.add(name, snippet.dialog_url) if snippet.dialog_url


