# OKAY THE TOP OF THIS IS A JQUERY PLUGIN
(($, window) ->
  class EffectiveMenuEditor
    defaults:
      menuClass: 'effective-menu'
      expandThreshold: 600

    menu: null
    draggable: null
    droppable: null

    constructor: (el, options) ->
      @options = $.extend({}, @defaults, options)
      @menu = $(el)

      @initCkEditorEvents()
      @initAddRemoveEvents()
      @initDragDropEvents()
      @initAdditionalEvents()
      true

    initCkEditorEvents: ->
      @menu.on 'click', 'li.dropdown.open', (event) =>
        event.stopPropagation()
        @menu.find('.open').removeClass('open')
        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = $(event.currentTarget)

      @menu.on 'click', '.dropdown-menu > li.dropdown', (event) =>
        event.stopPropagation()
        @menu.find('.open').removeClass('open')
        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = $(event.currentTarget)

      @menu.on 'click', 'li:not(.dropdown)', (event) =>
        event.stopPropagation()
        @menu.find('.open').removeClass('open')
        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = $(event.currentTarget)

    initAddRemoveEvents: ->
      @menu.on 'mouseover', (event) => @menu.children('.actions').children('.add-node').show()
      @menu.on 'mouseout', (event) => @menu.children('.actions').children('.add-node').hide()

      @menu.on 'click', '.add-node', (event) =>
        event.preventDefault()
        unique_id = new Date().getTime()
        node = $(@menu.data('effective-menu-new-html').replace(':new', "#{unique_id}", 'g'))

        @menu.children('.actions').before(node)

        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = node

    initAdditionalEvents: ->
      @menu.on 'click', 'a', (event) -> event.preventDefault()


    initDragDropEvents: ->
      @menu.on 'dragenter', 'li', (event) =>
        @droppable = null
        @droppable = {item: $(event.currentTarget), time: new Date().getTime()}
        event.preventDefault() if @draggable  # enable drag and drop

      @menu.on 'dragleave', 'li', (event) =>
        event.preventDefault() if @draggable # enable drag and drop

      @menu.on 'dragstart', 'li', (event) =>
        @draggable = node = $(event.currentTarget)
        @menu.children('.actions').children('.add-node').hide()
        node.find('.open').removeClass('open')

        event.originalEvent.dataTransfer.setData('text/html', node[0].outerHTML)

        node.css('opacity', '0.4') # Show it slightly removed from the DOM
        @menu.addClass('dragging')
        event.stopPropagation()

      @menu.on 'dragover', 'li', (event) =>
        node = $(event.currentTarget)

        return false unless @draggable
        return false if @draggable.find(node).length > 0 # Don't drag a parent into a child

        if node.hasClass('dropdown') && !node.hasClass('open') # This is a menu, expand it
          @menu.find('.open').removeClass('open')
          node.parentsUntil(@menu, 'li').andSelf().addClass('open')
        else
          event.preventDefault() # Enable drag and drop
          @convertToDropdown(node) if @droppable.time? && ((new Date().getTime()) - @droppable.time) > @options.expandThreshold

        # If I don't have the placeholder class already
        if node.hasClass('placeholder') == false
          @menu.find('.placeholder').removeClass('placeholder')
          node.addClass('placeholder')

        event.stopPropagation()

      @menu.on 'dragend', 'li', (event) =>
        return false unless @draggable
        node = $(event.currentTarget)

        @cleanupAfterDrop()
        node.css('opacity', '1.0')

      @menu.on 'drop', 'li', (event) =>
        return false unless @draggable
        node = $(event.currentTarget)

        node.before(event.originalEvent.dataTransfer.getData('text/html'))
        @draggable.remove()

        @cleanupAfterDrop()
        node.parentsUntil(@menu, 'li.dropdown').addClass('open')

        event.stopPropagation()
        event.preventDefault()

    convertToDropdown: (node) ->
      return false if node.hasClass('dropdown') || node.hasClass('effective-menu-expand')

      node.append(@menu.data('effective-menu-expand-html'))
      node.addClass('dropdown')
      node.children('a').attr('data-toggle', 'dropdown')

      @menu.find('.open').removeClass('open')
      node.parentsUntil(@menu, 'li.dropdown').addClass('open')

    cleanupAfterDrop: ->
      @menu.find('li.effective-menu-expand').remove()

      # Convert empty dropdowns back to leafs
      @menu.find('.dropdown-menu:empty').each (index, item) ->
        node = $(item).closest('.dropdown')
        node.removeClass('dropdown').removeClass('open')
        node.children('a').removeAttr('data-toggle')
        node.children('.dropdown-menu').remove()

      @menu.removeClass('dragging')
      @menu.find('.placeholder,.open').removeClass('placeholder').removeClass('open')
      @menu.children('.actions').children('.add-node').show()

      @draggable = null
      @droppable = null

    serialize: (retval) ->

      # console.log "============ BEFORE =============="
      # @menu.find('li').each (index, item) =>
      #   item = $(item)
      #   label = item.children('a').first().text()
      #   left = item.children('.menu-item').children("input[name$='[lft]']").val()
      #   right = item.children('.menu-item').children("input[name$='[rgt]']").val()
      #   console.log "[#{label}] #{left}, #{right}"
      # console.log "=================================="

      @assignLftRgt(@menu, 1)

      # console.log "============ AFTER =============="
      # @menu.find('li').each (index, item) =>
      #   item = $(item)
      #   label = item.children('a').first().text()
      #   left = item.children('.menu-item').children("input[name$='[lft]']").val()
      #   right = item.children('.menu-item').children("input[name$='[rgt]']").val()
      #   console.log "[#{label}] #{left}, #{right}"
      # console.log "=================================="

      items = {}

      $.each @menu.find('input').serializeArray(), ->
        @name = @name.replace("effective_menu[menu_items_attributes]", "menu_items_attributes")

        if items[@name]?
          items[@name] = [items[@name]] unless items[@name].push
          items[@name].push (@value || '')
        else
          items[@name] = (@value || '')

      retval[@menu.data('effective-menu-id')] = items

    assignLftRgt: (parent, lft) ->
      rgt = lft + 1

      parent.children('.dropdown-menu').children('li').each (_, child) =>
        rgt = @assignLftRgt($(child), rgt)

      parent.children('li').each (_, child) =>
        rgt = @assignLftRgt($(child), rgt)

      parent.children('.menu-item').children("input[name$='[lft]']").val(lft)
      parent.children('.menu-item').children("input[name$='[rgt]']").val(rgt)

      rgt + 1


  $.fn.extend effectiveMenuEditor: (option, args...) ->
    @each ->
      $this = $(this)
      data = $this.data('effectiveMenuEditor')

      $this.data('effectiveMenuEditor', (data = new EffectiveMenuEditor(this, option))) if !data
      data[option].apply(data, args) if typeof option == 'string'
      $this

) window.jQuery, window


# AND THE REST IS A CKEDITOR PLUGIN

CKEDITOR.plugins.add 'effective_menus',


  init: (editor) ->
    $('.effective-menu').effectiveMenuEditor() # Initialize the EffectiveMenus

    CKEDITOR.dialog.add 'effectiveMenusDialog', (editor) ->
      {
        title: 'Effective Menu Item'
        minWidth: 350,
        minHeight: 200,
        contents: [
          {
            id: 'item',
            label: 'Menu Item'
            elements: [
              {
                id: 'title',
                type: 'text',
                label: 'Title',
                validate: CKEDITOR.dialog.validate.notEmpty('please enter a title')
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[title]']").val())
                commit: (element) ->
                  element.children('.menu-item').children("input[name$='[title]']").val(this.getValue())
                  element.children('a').text(this.getValue())
              },
              {type: 'html', html: '<br>'},
              {
                type: 'hbox',
                children: [
                  {
                    id: 'source',
                    type: 'radio',
                    label: 'Link Source',
                    items: [['Page', 'Page'], ['URL', 'URL']]
                    setup: (element) ->
                      menuable_id = element.children('.menu-item').children("input[name$='[menuable_id]']").val() || ''
                      if menuable_id.length > 0 then this.setValue('Page') else this.setValue('URL')
                    onChange: (event) ->
                      if this.getValue() == 'Page'
                        this.getDialog().getContentElement('item', 'menuable_id').getElement().show()
                        this.getDialog().getContentElement('item', 'url').getElement().hide()

                      if this.getValue() == 'URL'
                        this.getDialog().getContentElement('item', 'menuable_id').getElement().hide()
                        this.getDialog().getContentElement('item', 'url').getElement().show()
                  },
                  {type: 'html', html: ''}
                ]
              },
              {
                id: 'menuable_id',
                type: 'select',
                label: 'Page',
                items: (
                  pages = []
                  $.ajax
                    url: '/admin/pages'
                    dataType: 'json'
                    async: false
                    complete: (data) -> pages = data.responseJSON
                  pages
                ),
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[menuable_id]']").val())
                commit: (element) ->
                  if this.getElement().isVisible()
                    element.children('.menu-item').children("input[name$='[menuable_id]']").val(this.getValue())
                    element.children('.menu-item').children("input[name$='[menuable_type]']").val('Effective::Page')
                  else
                    element.children('.menu-item').children("input[name$='[menuable_id]']").val('')
                    element.children('.menu-item').children("input[name$='[menuable_type]']").val('')
                validate: ->
                  if this.getElement().isVisible() && (this.getValue() || '').length == 0
                    CKEDITOR.dialog.validate.notEmpty('please select a page').apply(this)
              },
              {
                id: 'url',
                type: 'text',
                label: 'URL',
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[url]']").val())
                commit: (element) ->
                  if this.getElement().isVisible() then value = this.getValue() else value = ''

                  element.children('.menu-item').children("input[name$='[url]']").val(value)
                  element.children('a').attr('href', value || '#')
                validate: ->
                  if this.getElement().isVisible() && (this.getValue() || '').length == 0
                    CKEDITOR.dialog.validate.notEmpty('please enter a URL').apply(this)
              }
            ] # /tab1 elements
          },
          {
            id: 'advanced',
            label: 'Advanced'
            elements: [
              {
                id: 'new_window',
                type: 'checkbox',
                label: 'Open in new window',
                setup: (element) ->
                  value = element.children('.menu-item').children("input[name$='[new_window]']").val()
                  if value == 'true' then this.setValue(true) else this.setValue(false)
                commit: (element) ->
                  element.children('.menu-item').children("input[name$='[new_window]']").val(this.getValue())
              },
              {
                id: 'classes',
                type: 'text',
                label: 'HTML Classes',
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[classes]']").val())
                commit: (element) ->
                  element.children('.menu-item').children("input[name$='[classes]']").val(this.getValue())
              }
            ]
          }
        ], # /contents

        onShow: ->
          if this.effective_menu_item
            this.setupContent(this.effective_menu_item)
          else
            this.getContentElement('item', 'source').setValue('Page')

        onOk: ->
          this.commitContent(this.effective_menu_item)
          this.effective_menu_item.removeClass('new-item') if this.effective_menu_item.hasClass('new-item')
          this.effective_menu_item = undefined

        onCancel: ->
          this.effective_menu_item.remove() if this.effective_menu_item.hasClass('new-item')
          this.effective_menu_item = undefined
      }
