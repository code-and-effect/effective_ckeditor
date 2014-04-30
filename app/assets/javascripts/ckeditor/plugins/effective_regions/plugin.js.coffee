SaveAll = {
  instanceData: (instance) ->
    instance.resetDirty()

    snippets = {} # This is the Data we're going to post to the server
    snippet_ids = [] # This keeps track html classes we need to later replace

    for id, widget of instance.widgets.instances
      if widget.effectiveSnippetConfigured != undefined # This is an effectiveSnippet type widget
        snippet_id = "snippet_#{id}"
        snippets[snippet_id] = widget.data
        snippets[snippet_id]['class_name'] = widget.name
        widget.element.addClass(snippet_id)
        snippet_ids.push(snippet_id)

    # # # Replace the entire widget <div>...</div> with [snippet_0]
    content = $('<div>' + instance.getData() + '</div>')
    content.find(".#{snippet_id}").replaceWith("[#{snippet_id}]") for snippet_id in snippet_ids

    # Slightly different values for the different region types
    if instance.config.effectiveRegionType == 'snippets'
      content = content.text()
      content = content.replace(/\s+/gi, '') if content.indexOf('[snippet_') > -1
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

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() if (event.data.keyCode == 13 || event.data.keyCode == 2228237)

    # Paste as plain text, but this doesn't work all the way
    editor.config.forcePasteAsPlainText = true
    editor.on 'afterPaste', (evt) -> editor.setData(editor.getData().replace( /<[^<|>]+?>/gi,'')) 

  initSnippetsRegion: (editor) ->
    # Disable wrapping content with <p></p>.  This could break plugins.
    editor.config.autoParagraph = false

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() unless (event.data.keyCode == 8)  # 8 is backspace

    # Paste as plain text, but this doesn't work all the way
    editor.config.forcePasteAsPlainText = true
    editor.on 'afterPaste', (evt) -> editor.setData(editor.getData().replace(/<[^<|>]+?>/gi,'')) 

  initListSnippetsRegion: (editor) ->
    # Disable wrapping content with <p></p>.  This could break plugins.
    editor.config.autoParagraph = false

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() unless (event.data.keyCode == 8)  # 8 is backspace

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

    snippet['effectiveSnippetConfigured'] = false
    snippet['dialog_url'] = values.dialog_url
    snippet['dialog'] = name if values.dialog_url
    snippet['inline'] = values.inline
    snippet['editables'] = values.editables if values.editables
    snippet['draggable'] = editor.config.effectiveRegionType != 'list_snippets'
    snippet['template'] = "<#{values.tag}></#{values.tag}>"
    snippet['upcast'] = (element) -> element.attributes['data-effective-snippet'] == name
    snippet['loadTemplate'] = (widget) ->
      $.ajax
        url: '/effective_regions/snippet'
        type: 'GET'
        data: {effective_regions: {name: widget.name, data: widget.data}}
        async: false
        complete: (data) -> 
          element = $(data.responseText)
          classes = (element.attr('class') || '').split(/\s+/)
          widget.element.setHtml(element.html())
          if classes.length > 0
            widget.element.addClass(c) for c in classes

    snippet['init'] = ->
      this.data[k] = v for k, v of $(this.element.$).data('snippet-data')

      this.on 'dialog', (evt) -> @effectiveSnippetConfigured = true
      this.on 'data', (evt) -> @loadTemplate(evt.sender) if @effectiveSnippetConfigured

    snippet
}

BuildInsertSnippetDropdown = (editor, all_snippets) ->
  editor.ui.addRichCombo 'InsertSnippet',
    label: 'Insert Snippet',
    title: 'Insert Snippet',
    panel: 
      css: [ CKEDITOR.skin.getPath( 'editor' ) ],
      multiSelect: false,
    init: -> this.add(name, "#{values.label}", "#{values.description}") for name, values of all_snippets
    onClick: (value) -> editor.getCommand(value).exec(editor)
    onOpen: (evt) ->
      this.showAll()
      allowedSnippets = this._.panel._.editor.config.allowedSnippets

      if allowedSnippets.length > 0
        for name, _ of this._.items
          this.hideItem(name) if allowedSnippets.indexOf(name) == -1  # Hide it, if it's not in allowedSnippets array

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
    Regions.initSimpleRegion(editor) if editor.config.effectiveRegionType == 'simple'
    Regions.initSnippetsRegion(editor) if editor.config.effectiveRegionType == 'snippets'
    Regions.initListSnippetsRegion(editor) if editor.config.effectiveRegionType == 'list_snippets'
    Regions.initFullRegion(editor) if editor.config.effectiveRegionType == 'full'

    # Snippets
    all_snippets = Snippets.all()

    # Insert Snippets Dropdown
    BuildInsertSnippetDropdown(editor, all_snippets)

    # Initialize all the Snippets as CKeditor widgets
    for name, values of all_snippets

      snippet = Snippets.build(editor, name, values)

      editor.widgets.add(name, snippet)
      CKEDITOR.dialog.add(name, snippet.dialog_url) if snippet.dialog_url




    #snippet['requiredContent'] = "#{values.wrapper_tag}(#{name}_snippet)"
    # snippet['init'] = ->
    #   console.log "INIT"
    #   for k, v of $(this.wrapper.$).find('.cke_widget_element').data('effective-snippet')
    #     this.data[k] = v

    #   for editables_name, editables_values of values.editables
    #     console.log editables_values.selector
    #     console.log this.element.find(editables_values.selector)
    #     console.log this.element.find(editables_values.selector).getItem(0).getHtml()
    #     this.data[editables_name] = this.element.find(editables_values.selector).getItem(0).getHtml()


      # console.log "INIT"
      # console.log this.element
      # console.log values.editables

    # snippet['loadTemplate'] = (widget) ->
    #   $.ajax
    #     url: '/effective_regions/snippet'
    #     type: 'GET'
    #     data: {effective_regions: {name: widget.name, data: widget.data}}
    #     async: false
    #     complete: (data) -> $(widget.wrapper.$).find('.cke_widget_element').html(data.responseText)

    # snippet['init'] = ->
    #   for k, v of $(this.wrapper.$).find('.cke_widget_element').data('effective-snippet')
    #     this.data[k] = v

    #   this.on 'dialog', (evt) -> @configured = true
    #   this.on 'data', (evt) -> @loadTemplate(evt.sender) if @configured
    #   this.on 'ready', (evt) ->
    #     return true if @configured != true || evt.sender.editor.config.effectiveRegionType != 'list_snippets'
    #     editor = evt.sender.editor

    #     # This makes sure an inserted snippet within a 'list_snippets' region is inserted under <ol><li>
    #     try
    #       root = editor.getSelection().getCommonAncestor()
    #       root = root.getParent() while (root.hasClass('effective-region') == false && root.getName() != 'body')

    #       children = root.getChildren()

    #       node0 = children.getItem(0)
    #       node1 = children.getItem(1)
    #       node2 = children.getItem(2)

    #       # Find the first OL/UL, find its LI, clone it, then insert the widget into that LI
    #       if (node0.getName() == 'ol' || node0.getName() == 'ul') && (node1 == null || node1.hasClass('cke_widget_wrapper'))
    #         if (liNode = node0.getChild(0)).getName() == 'li'
    #           newNode = liNode.clone()
    #           newNode.append(this.wrapper)
    #           node0.append(newNode)
    #           node2.remove() if (node2 != null && node2.getName() == 'br')
    #       else if node0.hasClass('cke_widget_wrapper') && node2 != null && (node2.getName() == 'ol' || node2.getName() == 'ul')
    #         if (liNode = node2.getChild(0)).getName() == 'li'
    #           newNode = liNode.clone()
    #           newNode.append(this.wrapper)
    #           node2.append(newNode, true) # prepend it
    #           node1.remove() if (node1 != null && node1.getName() == 'br')
