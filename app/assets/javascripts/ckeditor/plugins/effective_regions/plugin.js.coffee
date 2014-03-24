SaveAll = {
  replaceSnippets: (html) ->
    obj = $('<div>' + html + '</div>')
    obj.find('div[data-snippet]').each -> $(this).replaceWith("[#{$(this).data('snippet')}]")
    obj.html()

  exec: (editor) ->
    data = {}

    for name, instance of CKEDITOR.instances # All CKEditors on the whole page
      snippets_data = {}
      for name, widget of instance.widgets.instances
        console.log name
        console.log widget
        console.log widget.data
        snippets_data[widget.snippet_id()] = widget.data 

      data[name] = {
        content: @replaceSnippets(instance.getData())
        snippets: snippets_data
      }

    url = window.location.protocol + '//' + window.location.host + '/edit' + window.location.pathname

    $.ajax
      url: url
      type: 'PUT'
      dataType: 'json'
      data: { effective_regions: data }
      async: false
      success: (data) -> 
        console.log 'success!'
        console.log data
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

    snippet['snippet_id'] = -> $(this.wrapper.$).find('div.cke_widget_element').data('snippet')
    snippet['configured'] = false
    snippet['template'] = values.template
    snippet['dialog_url'] = values.dialog_url
    snippet['dialog'] = name if values.dialog_url
    snippet['requiredContent'] = "div(#{name})"
    snippet['upcast'] = (element) -> element.name == 'div' && element.hasClass(name + '_snippet')

    snippet['loadTemplate'] = (widget) ->
      $.ajax
        url: '/effective_regions/snippet'
        type: 'GET'
        data: {effective_regions: {name: widget.name, data: widget.data}}
        async: false
        complete: (data) -> $(widget.wrapper.$).find('div.cke_widget_element').html(data.responseText)

    snippet['init'] = ->
      this.on 'dialog', (evt) -> @configured = true
      this.on 'data', (evt) -> @loadTemplate(evt.sender) if @configured

    #snippet['data'] = -> 

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
    for name, values of Snippets.all()
      snippet = Snippets.build(editor, name, values) # Name might have to be Currentuserinfo

      editor.widgets.add(name, snippet)
      CKEDITOR.dialog.add(name, snippet.dialog_url) if snippet.dialog_url

      editor.config.toolbar_full[editor.config.toolbar_full.length-1].items.push(name)
      editor.config.toolbar_snippets[editor.config.toolbar_snippets.length-1].items.push(name)
      editor.ui.addButton name, {label: 'Insert ' + name, command: name}





