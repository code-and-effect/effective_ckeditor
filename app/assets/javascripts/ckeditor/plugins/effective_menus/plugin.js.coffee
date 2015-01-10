# OKAY THE TOP OF THIS IS A JQUERY PLUGIN
# When the CKEditor plugin below is initialized via an /edit/ route
# it initialized this jquery on any $(.effective-menu) objects present on the page

(($, window) ->
  class EffectiveMenuEditor
    defaults:
      menuClass: 'effective-menu'
      expandThreshold: 600  # Seconds before a leaf li item will be auto-expanded into a dropdown

    menu: null
    draggable: null
    droppable: null

    constructor: (el, options) ->
      @options = $.extend({}, @defaults, options)
      @menu = $(el)

      @initCkEditorEvents()
      @initAddButtonEvents()
      @initDestroyButtonEvents()
      @initDragDropEvents()
      @initAdditionalEvents()
      true

    # All 3 of these events are basically the same:
    # Remove the open class and

    initCkEditorEvents: ->
      # Oh yea, you like that selector.  The comma means or, so there are actually 3 selectors being created here
      # They need to be in this order for the stopPropagation to work properly.
      @menu.on 'click', 'li.dropdown.open,.dropdown-menu > li.dropdown,li:not(.dropdown)', (event) =>
        event.stopPropagation()
        @menu.find('.open').removeClass('open')
        # Open the CKEDITOR dialog and pass the source effective_menu_item $('li') to the dialog
        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = $(event.currentTarget)

    initAddButtonEvents: ->
      @menu.on 'mouseenter', (event) => @menu.children('.actions').children('.add-item').show()
      @menu.on 'mouseleave', (event) => @menu.children('.actions').children('.add-item').hide()
      @menu.on 'mouseenter', '.add-item', (event) -> $(event.currentTarget).addClass('large') ; event.stopPropagation()
      @menu.on 'mouseleave', '.add-item', (event) -> $(event.currentTarget).removeClass('large'); event.stopPropagation()

      @menu.on 'click', '.add-item', (event) =>
        event.preventDefault()
        unique_id = new Date().getTime()
        item = $(@menu.data('effective-menu-new-html').replace(':new', "#{unique_id}", 'g'))

        @menu.children('.actions').before(item)

        CKEDITOR.instances[Object.keys(CKEDITOR.instances)[0]].openDialog 'effectiveMenusDialog', (dialog) ->
          dialog.effective_menu_item = item

    initDestroyButtonEvents: ->
      @menu.on 'dragenter', '.remove-item', (event) => $(event.currentTarget).addClass('large')
      @menu.on 'dragleave', '.remove-item', (event) => $(event.currentTarget).removeClass('large')

      @menu.on 'dragover', '.remove-item', (event) =>
        return false unless @draggable
        glyphicon = $(event.currentTarget).addClass('large') # Garbage can

        event.preventDefault() # Enable drag and drop
        event.stopPropagation()

      @menu.on 'drop', '.remove-item', (event) =>
        return false unless @draggable
        glyphicon = $(event.currentTarget).removeClass('large')

        @markDestroyed(@draggable)

        @cleanupAfterDrop()
        event.stopPropagation()
        event.preventDefault()

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
        @draggable = item = $(event.currentTarget)
        @menu.children('.actions').children('.add-item').hide()
        item.find('.open').removeClass('open')

        event.originalEvent.dataTransfer.setData('text/html', item[0].outerHTML)

        item.css('opacity', '0.4') # Show it slightly removed from the DOM
        @menu.addClass('dragging')
        event.stopPropagation()

      @menu.on 'dragover', 'li', (event) =>
        item = $(event.currentTarget)

        return false unless @draggable
        return false if @draggable.find(item).length > 0 # Don't drag a parent into a child

        if item.hasClass('dropdown') && !item.hasClass('open') # This is a menu, expand it
          @menu.find('.open').removeClass('open')
          item.parentsUntil(@menu, 'li').andSelf().addClass('open')
        else
          event.preventDefault() # Enable drag and drop
          @expandToDropdown(item) if @droppable.time? && ((new Date().getTime()) - @droppable.time) > @options.expandThreshold

        # If I don't have the placeholder class already
        if item.hasClass('placeholder') == false
          @menu.find('.placeholder').removeClass('placeholder')
          item.addClass('placeholder')

        event.stopPropagation()

      @menu.on 'dragend', 'li', (event) =>
        return false unless @draggable
        item = $(event.currentTarget)

        @cleanupAfterDrop()
        item.css('opacity', '1.0')

      @menu.on 'drop', 'li', (event) =>
        return false unless @draggable
        item = $(event.currentTarget)

        item.before(event.originalEvent.dataTransfer.getData('text/html'))
        @draggable.remove()

        @cleanupAfterDrop()
        item.parentsUntil(@menu, 'li.dropdown').addClass('open')

        event.stopPropagation()
        event.preventDefault()

    # If it hasn't already been expanded...
    # Append some html to make it into a faux dropdown
    # which is just a ul.dropdown-menu > li
    expandToDropdown: (item) ->
      return false if item.hasClass('dropdown') || item.hasClass('effective-menu-expand')

      item.append(@menu.data('effective-menu-expand-html'))
      item.addClass('dropdown')
      item.children('a').attr('data-toggle', 'dropdown')

      # # If I'm a top level dropdown
      # if item.parent().hasClass('effective-menu')
      #   item.childre('a').append("<span class='caret'>")


      @menu.find('.open').removeClass('open')
      item.parentsUntil(@menu, 'li.dropdown').addClass('open')

    cleanupAfterDrop: ->
      # chrome puts in a weird meta tag that firefox doesnt
      # so we delete it here
      @menu.find('meta,li.effective-menu-expand').remove()

      # Convert any empty dropdowns back we converted back to leafs
      @menu.find('.dropdown-menu:empty').each (index, item) ->
        item = $(item).closest('.dropdown')
        item.removeClass('dropdown').removeClass('open')
        item.children('a').removeAttr('data-toggle')
        item.children('.dropdown-menu').remove()

      @menu.removeClass('dragging')
      @menu.find('.placeholder,.open').removeClass('placeholder').removeClass('open')
      @menu.children('.actions').children('.add-item').show()

      @draggable = null
      @droppable = null

    # Just pass _destroyed = 1 back to rails to delete this item
    # Rails seems to disregard new items set to the new Date.now() values anyhow
    # Put all deleted items after the .actions div just to be tidy
    markDestroyed: (item) ->
      item.hide().addClass('destroyed').find("input[name$='[_destroy]']").val(1)
      @menu.children('.actions').after(item.remove())


    # This method is called with a Hash value
    # that is called by reference from the parent function
    #
    # This serialize method is called from the effective_ckeditor gem plugins/effective_regions plugin
    # by the SaveAll method to actually persist the menus when it also saves the regions
    # This way the saves happen all at once

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

      # This next bit just massages some of the form serialization
      # and translates the jquery serializeArray into the formnat needed by Rails accepts_nested_attributes

      $.each @menu.find('input').serializeArray(), ->
        @name = @name.replace("effective_menu[menu_items_attributes]", "menu_items_attributes")

        if items[@name]?
          items[@name] = [items[@name]] unless items[@name].push
          items[@name].push (@value || '')
        else
          items[@name] = (@value || '')

      # This retVal has to account for multiple effective-menus on one page
      retval[@menu.data('effective-menu-id')] = items

    assignLftRgt: (parent, lft) ->
      rgt = lft + 1

      parent.children('.dropdown-menu').children('li:not(.destroyed)').each (_, child) =>
        rgt = @assignLftRgt($(child), rgt)

      parent.children('li:not(.destroyed)').each (_, child) =>
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

# This plugin is registered with CkEditor and a dialog to edit menu item is created
# See the initCkEditorEvents() function in the jquery plugin that calls this dialog
# When the dialog is called, it sets dialog.effective_menu_item to
# to the event.currentTarget, i.e. the jquery element $(li)

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
                id: 'add_or_edit',
                type: 'html',
                html: '',
                setup: (element) ->
                  # This just doesnt work and Im not sure why
                  if this.getDialog().effective_menu_item.hasClass('new-item')
                    this.setValue('<p>Create a new menu item</p>')
                  else
                    this.setValue('<p>Editing an existing menu item</p>')
              },
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
                      url = element.children('.menu-item').children("input[name$='[url]']").val() || ''
                      if (url.length > 0 && url != '#') then this.setValue('URL') else this.setValue('Page')
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

        onShow: -> this.setupContent(this.effective_menu_item) if this.effective_menu_item

        onOk: ->
          this.commitContent(this.effective_menu_item)
          this.effective_menu_item.removeClass('new-item') if this.effective_menu_item.hasClass('new-item')
          this.effective_menu_item = undefined

        onCancel: ->
          this.effective_menu_item.remove() if this.effective_menu_item.hasClass('new-item')
          this.effective_menu_item = undefined
      }
