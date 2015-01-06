# OKAY THE TOP OF THIS IS A JQUERY PLUGIN
(($, window) ->
  class EffectiveMenuEditor
    defaults:
      menuClass: 'effective-menu'

    menu: null
    draggable: null

    constructor: (el, options) ->
      console.log 'constructed'
      @options = $.extend({}, @defaults, options)
      @menu = $(el)

      @initDragDropEvents()
      @initCkEditorEvents()
      @initAdditionalEvents()
      true

    initDragDropEvents: ->
      @menu.on 'dragenter', 'li', (event) => event.preventDefault() if @draggable  # enable drag and drop
      @menu.on 'dragleave', 'li', (event) => event.preventDefault() if @draggable # enable drag and drop

      @menu.on 'dragstart', 'li', (event) =>
        @draggable = node = $(event.currentTarget)
        event.originalEvent.dataTransfer.setData('text/html', node[0].outerHTML)

        node.css('opacity', '0.4') # Show it slightly removed from the DOM
        @menu.addClass('dragging')
        event.stopPropagation()

      @menu.on 'dragover', 'li', (event) =>
        return false unless @draggable

        node = $(event.currentTarget)

        if (node.hasClass('dropdown') || node.hasClass('dropdown-submenu')) && !node.hasClass('open') # This is a menu, expand it
          @menu.find('.open').removeClass('open')
          node.parentsUntil(@menu, 'li').andSelf().addClass('open')
        else
          event.preventDefault()

        # If I don't have the placeholder class already
        if node.hasClass('placeholder') == false
          @menu.find('.placeholder').removeClass('placeholder')
          node.addClass('placeholder')

        event.stopPropagation()

      @menu.on 'dragend', 'li', (event) =>
        return false unless @draggable

        node = $(event.currentTarget)
        node.css('opacity', '1.0')
        @menu.removeClass('dragging').find('.placeholder').removeClass('placeholder')
        @draggable = null

      @menu.on 'drop', 'li', (event) =>
        return false unless @draggable

        node = $(event.currentTarget)

        node.before(event.originalEvent.dataTransfer.getData('text/html'))

        @menu.removeClass('dragging').find('.placeholder').removeClass('placeholder')

        @draggable.remove() if @draggable
        @draggable = null

        event.stopPropagation()
        event.preventDefault()

    initCkEditorEvents: ->
      @menu.on 'dblclick', 'li.dropdown', (event) ->
        event.stopPropagation()
        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = $(event.currentTarget)

      @menu.on 'click', 'li:not(.dropdown)', (event) ->
        event.stopPropagation()
        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = $(event.currentTarget)

    initAdditionalEvents: ->
      @menu.on 'click', 'a', (event) -> event.preventDefault()

    serialize: (retval) ->
      items = {}

      $.each @menu.find('input').serializeArray(), ->
        @name = @name.replace("effective_menu[menu_items_attributes]", "menu_items_attributes")

        if items[@name]?
          items[@name] = [items[@name]] unless items[@name].push
          items[@name].push (@value || '')
        else
          items[@name] = (@value || '')

      retval[@menu.data('effective-menu-id')] = items

    assignLftRgt: ->
      stack = []
      console.log @menu.find('li')

      @menu.find('li').each (item) ->
        console.log 'item'


  $.fn.extend effectiveMenuEditor: (option, args...) ->
    @each ->
      $this = $(this)
      data = $this.data('effectiveMenuEditor')

      $this.data('effectiveMenuEditor', (data = new EffectiveMenuEditor(this, option))) if !data
      data[option].apply(data, args) if typeof option == 'string'
      $this

) window.jQuery, window


# AND THE REST IS A CKEDITOR PLUGIn

CKEDITOR.plugins.add 'effective_menus',
  icons: 'effectivemenus',
  hidpi: true,
  init: (editor) ->
    $('.effective-menu').effectiveMenuEditor() # Initialize the EffectiveMenus

    CKEDITOR.dialog.add 'effectiveMenusDialog', (editor) ->
      {
        title: 'Effective Menu Item'
        minWidth: 650,
        minHeight: 500,
        contents: [
          {
            id: 'tab1',
            label: 'Menu Item'
            elements: [
              {
                type: 'html',
                html: "<p>This is some text</p>"
              },
              {
                id: 'effective_menu_item_title',
                type: 'text',
                label: 'Title',
                validate: CKEDITOR.dialog.validate.notEmpty('Must have a title')
                setup: (element) ->
                  console.log 'setup title'
                  console.log element
                  this.setValue('title from matt')
                #commit: (element) -> widget.setData('html_class', this.getValue()) if widget
              },
              {
                id: 'effective_menu_item_url',
                type: 'text',
                label: 'URL',
                validate: CKEDITOR.dialog.validate.notEmpty('Must have a url')
              }
            ] # /tab1 elements
          }
        ], # /contents

        onShow: (thing) ->
          console.log 'on show'
          console.log this
          console.log this.effective_menu_item.text()

          # console.log 'on show'
          # console.log this
          # console.log thing
          # console.log editor
          # console.log 'calling setup Content'
          this.setupContent()
      }
