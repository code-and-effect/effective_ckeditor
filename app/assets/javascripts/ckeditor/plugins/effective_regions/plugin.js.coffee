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

    # Replace the entire widget <div>...</div> with [snippet_0]
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
    # Show a checkmark on the Save button
    try
      button = $("##{this.uiItems[0]._.id}").find('.cke_button__save_icon')

      button.addClass('saving')
      setTimeout(
        -> button.removeClass('saving')
        2000
      )

    url = window.location.protocol + '//' + window.location.host + '/edit' + window.location.pathname

    # Collect all Effective::Region Data
    regionData = {}
    regionData[name] = @instanceData(instance) for name, instance of CKEDITOR.instances

    # Collect all the Effective::Menu Data
    menuData = {}
    $('.effective-menu').effectiveMenuEditor('serialize', menuData)

    $.ajax
      url: url
      type: 'PUT'
      dataType: 'json'
      data: { effective_regions: regionData, effective_menus: menuData }
      async: false
      complete: (response) ->
        data = response['responseJSON'] || {}
        $('.effective-menu').effectiveMenuEditor('saveComplete', data['effective_menus'])
        location.reload(true) if data['refresh'] == true
}

Exit = {
  exec: (editor) ->
    url = $.cookie('effective_regions_editting')
    url ||= window.location.href.replace('?edit=true', '')

    if url != undefined && url.length > 0
      window.location = url
    else
      window.history.back()
}

Regions = {
  initFullRegion: (editor) ->
    # Remove any style attributes
    editor.on 'paste', (evt) ->
      data = $('<div>' + evt.data.dataValue + '</div>')
      data.find('[style]').removeAttr('style')
      evt.data.dataValue = data.html()

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
    editor.on 'paste', (evt) -> evt.data.dataValue = evt.data.dataValue.replace(/<[^<|>]+?>/gi,'')

  initSnippetRegion: (editor) ->
    # Disable wrapping content with <p></p>.  This could break plugins.
    editor.config.autoParagraph = false

    # Disable enter button
    editor.on 'key', (event) -> event.cancel() unless (event.data.keyCode == 8)  # 8 is backspace

    # Paste as plain text, but this doesn't work all the way
    editor.config.forcePasteAsPlainText = true
    editor.on 'paste', (evt) -> evt.data.dataValue = evt.data.dataValue.replace(/<[^<|>]+?>/gi,'')
}

Snippets = {
  all: -> ((CKEDITOR.config['effective_regions'] || {})['snippets'] || {})

  build: (editor, name, values) ->
    snippet = {}

    snippet['effectiveSnippetConfigured'] = false
    snippet['dialog_url'] = values.dialog_url
    snippet['dialog'] = name if values.dialog_url
    snippet['inline'] = values.inline
    snippet['editables'] = values.editables if values.editables
    snippet['draggable'] = editor.config.effectiveRegionType != 'wrapped_snippets'
    snippet['template'] = "<#{values.tag} data-effective-snippet='#{name}'></#{values.tag}>"
    snippet['upcast'] = (element) -> element.attributes['data-effective-snippet'] == name
    snippet['loadTemplate'] = (widget) ->
      $.ajax
        url: "/effective/snippet/#{widget.name}"
        type: 'GET'
        data: {edit: true, effective_regions: {name: widget.name, data: widget.data}}
        async: false
        complete: (data) -> widget.element.setHtml(data.responseText)

    snippet['init'] = ->
      this.data[k] = v for k, v of $(this.element.$).data('snippet-data')

      this.on 'dialog', (evt) -> @effectiveSnippetConfigured = true
      this.on 'data', (evt) -> @loadTemplate(evt.sender) if @effectiveSnippetConfigured
      this.on 'ready', (evt) ->

        return true if @effectiveSnippetConfigured != true || evt.sender.editor.config.effectiveRegionType != 'wrapped_snippets'
        editor = evt.sender.editor

        # This makes sure an inserted snippet within a 'wrapped_snippets' region is inserted under <ol><li>
        try
          root = editor.getSelection().getCommonAncestor()
          root = root.getParent() while (root.hasClass('effective-region') == false && root.getName() != 'body')

          children = root.getChildren()

          node0 = children.getItem(0)
          node1 = children.getItem(1)
          node2 = children.getItem(2)

          # Find the first OL/UL, find its LI, clone it, then insert the widget into that LI
          if (node0.getName() == 'ol' || node0.getName() == 'ul') && (node1 == null || node1.hasClass('cke_widget_wrapper'))
            if (liNode = node0.getChild(0)).getName() == 'li'
              newNode = liNode.clone()
              newNode.append(this.wrapper)
              node0.append(newNode)
              node2.remove() if (node2 != null && node2.getName() == 'br')
          else if node0.hasClass('cke_widget_wrapper') && node2 != null && (node2.getName() == 'ol' || node2.getName() == 'ul')
            if (liNode = node2.getChild(0)).getName() == 'li'
              newNode = liNode.clone()
              newNode.append(this.wrapper)
              node2.append(newNode, true) # prepend it
              node1.remove() if (node1 != null && node1.getName() == 'br')

    snippet
}

BuildInsertSnippetDropdown = (editor, all_snippets) ->
  editor.ui.addRichCombo 'InsertSnippet',
    label: 'Insert Snippet',
    title: 'Insert Snippet',
    panel:
      css: [ CKEDITOR.skin.getPath( 'editor' ) ],
      multiSelect: false,
    init: ->
      for name, values of all_snippets
        if name != 'effective_asset'
          this.add(name, "#{values.label}", "#{values.description}")
    onClick: (value) -> editor.getCommand(value).exec(editor)
    onOpen: (evt) ->
      this.showAll()
      allowedSnippets = this._.panel._.editor.config.allowedSnippets

      if allowedSnippets.length > 0
        for name, _ of this._.items
          this.hideItem(name) if allowedSnippets.indexOf(name) == -1  # Hide it, if it's not in allowedSnippets array

CKEDITOR.plugins.add 'effective_regions',
  requires: 'widget',
  init: (editor) ->
    # Saving
    editor.ui.addButton 'Save', {label: 'Save', command: 'effectiveRegionsSaveAll'}
    editor.addCommand('effectiveRegionsSaveAll', SaveAll)

    # Exit Button
    editor.ui.addButton 'Exit', {label: 'Exit', command: 'effectiveRegionsExit'}
    editor.addCommand('effectiveRegionsExit', Exit)

    # Regions
    Regions.initFullRegion(editor) if editor.config.effectiveRegionType == 'full'
    Regions.initSimpleRegion(editor) if editor.config.effectiveRegionType == 'simple'
    Regions.initSnippetRegion(editor) if editor.config.effectiveRegionType == 'snippets'
    Regions.initSnippetRegion(editor) if editor.config.effectiveRegionType == 'wrapped_snippets'

    # Snippets
    BuildInsertSnippetDropdown(editor, Snippets.all()) # Insert Snippets Dropdown

    # Initialize all the Snippets as CKeditor widgets
    for name, values of Snippets.all()
      snippet = Snippets.build(editor, name, values)

      editor.widgets.add(name, snippet)
      CKEDITOR.dialog.add(name, CKEDITOR.getUrl(window.location.protocol + '//' + window.location.host + snippet.dialog_url)) if snippet.dialog_url
