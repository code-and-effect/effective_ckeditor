# OKAY THE TOP OF THIS IS A JQUERY PLUGIN
# When the CKEditor plugin below is initialized via an /edit/ route
# it initialized this jquery on any $(.effective-menu) objects present on the page

(($, window) ->
  class EffectiveMenuEditor
    defaults:
      menuClass: 'effective-menu'
      expandThreshold: 250  # Seconds before a leaf li item will be auto-expanded into a dropdown
      maxDepth: 9999

    menu: null
    draggable: null
    droppable: null

    constructor: (el, options) ->
      @menu = $(el)

      @options = $.extend({}, @defaults, options)
      @options.maxDepth = @menu.data('effective-menu-maxdepth') if @menu.data('effective-menu-maxdepth')

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
        @menu.data('dirty', true)
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
        item = $(@menu.data('effective-menu-new-html').replace(/:new/g, "#{unique_id}"))

        @menu.children('.actions').before(item)
        @menu.data('dirty', true)

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

        @cleanupMenuAfterDrop()
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
        item.removeClass('open').find('.open').removeClass('open')

        event.originalEvent.dataTransfer.setData('Text', item[0].outerHTML)

        item.css('opacity', '0.4') # Show it slightly removed from the DOM
        @menu.addClass('dragging')
        event.stopPropagation()

      @menu.on 'dragover', 'li', (event) =>
        return false unless @draggable

        item = $(event.currentTarget)

        if item.hasClass('dropdown') && !item.hasClass('open') # This is a menu, expand it
          @menu.find('.open').removeClass('open')
          item.parentsUntil(@menu, 'li').andSelf().addClass('open')
        else
          event.preventDefault() # Enable drag and drop
          @expandToDropdown(item) if (new Date().getTime()) > @options.expandThreshold + (@droppable.time || 0)

        # If I don't have the placeholder class already
        if item.hasClass('placeholder') == false
          @menu.find('.placeholder').removeClass('placeholder')
          item.addClass('placeholder')

        event.stopPropagation()

      @menu.on 'dragend', 'li', (event) =>
        return false unless @draggable
        item = $(event.currentTarget)

        @cleanupMenuAfterDrop()
        item.css('opacity', '1.0')

      @menu.on 'drop', 'li', (event) =>
        item = $(event.currentTarget)

        # Don't allow to drop into myself or my own children
        return false if !@draggable? || @draggable.is(item) || @draggable.find(item).length > 0

        new_item = $(event.originalEvent.dataTransfer.getData('Text'))

        item.before(new_item)
        @draggable.remove()

        @cleanupMenuAfterDrop()
        @cleanupItemAfterDrop(new_item)

        event.stopPropagation()
        event.preventDefault()

    # If it hasn't already been expanded...
    # Append some html to make it into a faux dropdown
    # which is just a ul.dropdown-menu > li
    expandToDropdown: (item) ->
      return false if item.hasClass('dropdown') || item.hasClass('effective-menu-expand')
      return false if @depthOf(item) >= @options.maxDepth

      item.append(@menu.data('effective-menu-expand-html'))
      item.addClass('dropdown')
      item.children('a').attr('data-toggle', 'dropdown')

      # If I'm a top level dropdown
      if item.parent().hasClass('effective-menu')
        item.children('a').append("<span class='caret'></span>")

      @menu.find('.open').removeClass('open')
      item.parentsUntil(@menu, 'li.dropdown').addClass('open')

    cleanupMenuAfterDrop: ->
      # chrome puts in a weird meta tag that firefox doesnt
      # so we delete it here
      @menu.find('meta,li.effective-menu-expand').remove()

      @menu.data('dirty', true)

      # Collapse any empty dropdowns we may have expanded back to leafs
      @menu.find('.dropdown-menu:empty').each (index, item) ->
        item = $(item).closest('.dropdown')
        item.removeClass('dropdown').removeClass('open')
        item.children('a').removeAttr('data-toggle').find('span.caret').remove()
        item.children('.dropdown-menu').remove()

      @menu.removeClass('dragging')
      @menu.children('.actions').children('.add-item').show()
      @menu.find('.placeholder,.open').removeClass('placeholder').removeClass('open')

      @draggable = null
      @droppable = null

    cleanupItemAfterDrop: (item) ->
      item.children('a').find('span.caret').remove() # Just always remove the caret if present

      # And add it back if we're a top level node
      if item.parent().hasClass('effective-menu') && item.children('.dropdown-menu').length
        item.children('a').append("<span class='caret'></span>")

      item.parentsUntil(@menu, 'li.dropdown').addClass('open')

    # Very top level items are assigned Depth of 0
    # The first dropdowns all have Depth of 1
    depthOf: (item) -> item.parentsUntil(@menu, 'li').length

    markDestroyed: (item) -> item.remove()

    # This method is called with a Hash value
    # that is called by reference from the parent function
    #
    # This serialize method is called from the effective_ckeditor gem plugins/effective_regions plugin
    # by the SaveAll method to actually persist the menus when it also saves the regions
    # This way the saves happen all at once

    serialize: (retval) ->
      return if @menu.data('dirty') != true

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

    saveComplete: (data) -> @menu.data('dirty', false)

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

                  if element.children('a').find('span.caret').length > 0
                    element.children('a').text(this.getValue())
                    element.children('a').append("<span class='caret'></span>")
                  else
                    element.children('a').text(this.getValue())
                validate: ->
                  if this.getDialog().getValueOf('item', 'source') != 'Divider' && (this.getValue() || '').length == 0
                    CKEDITOR.dialog.validate.notEmpty('please enter a title').apply(this)
              },
              {type: 'html', html: '<br>'},
              {
                id: 'source',
                type: 'radio',
                label: 'Link Type',
                items: [['Page', 'Page'], ['URL', 'URL'], ['Route', 'Route'], ['Divider', 'Divider'], ['Dropdown', 'Dropdown']]
                setup: (element) ->
                  menuable_id = element.children('.menu-item').children("input[name$='[menuable_id]']").val() || ''
                  special = element.children('.menu-item').children("input[name$='[special]']").val() || ''
                  url = element.children('.menu-item').children("input[name$='[url]']").val() || ''

                  if this.getDialog().effective_menu_item.hasClass('dropdown')
                    this.setValue('Dropdown')
                  else if menuable_id.length > 0
                    this.setValue('Page')
                  else if special == 'divider'
                    this.setValue('Divider')
                  else if special.length > 0
                    this.setValue('Route')
                  else if url.length > 0 && url != '#'
                    this.setValue('URL')
                  else
                    this.setValue('Page')

                onChange: (event) ->
                  if this.getValue() != 'Dropdown'
                    radios = $('#' + this.getDialog().getContentElement('item', 'source').getElement().getId())
                    radios.find('input').prop('disabled', false)
                    radios.find("input[value='Dropdown']").prop('disabled', true)

                  if this.getValue() == 'Page'
                    this.getDialog().getContentElement('item', 'title').getElement().show()
                    this.getDialog().getContentElement('item', 'menuable_id').getElement().show()

                    this.getDialog().getContentElement('item', 'url').getElement().hide()
                    this.getDialog().getContentElement('item', 'special').getElement().hide()
                    this.getDialog().getContentElement('item', 'dropdown').getElement().hide()

                  if this.getValue() == 'URL'
                    this.getDialog().getContentElement('item', 'title').getElement().show()
                    this.getDialog().getContentElement('item', 'url').getElement().show()

                    this.getDialog().getContentElement('item', 'menuable_id').getElement().hide()
                    this.getDialog().getContentElement('item', 'special').getElement().hide()
                    this.getDialog().getContentElement('item', 'dropdown').getElement().hide()

                  if this.getValue() == 'Divider'
                    this.getDialog().getContentElement('item', 'url').getElement().hide()
                    this.getDialog().getContentElement('item', 'title').getElement().hide()
                    this.getDialog().getContentElement('item', 'menuable_id').getElement().hide()
                    this.getDialog().getContentElement('item', 'special').getElement().hide()
                    this.getDialog().getContentElement('item', 'dropdown').getElement().hide()

                  if this.getValue() == 'Dropdown'
                    this.getDialog().getContentElement('item', 'title').getElement().show()
                    this.getDialog().getContentElement('item', 'dropdown').getElement().show()
                    $('#' + this.getDialog().getContentElement('item', 'source').getElement().getId()).find('input').prop('disabled', true)

                    this.getDialog().getContentElement('item', 'special').getElement().hide()
                    this.getDialog().getContentElement('item', 'url').getElement().hide()
                    this.getDialog().getContentElement('item', 'menuable_id').getElement().hide()

                  if this.getValue() == 'Route'
                    this.getDialog().getContentElement('item', 'title').getElement().show()
                    this.getDialog().getContentElement('item', 'special').getElement().show()

                    this.getDialog().getContentElement('item', 'menuable_id').getElement().hide()
                    this.getDialog().getContentElement('item', 'url').getElement().hide()
                    this.getDialog().getContentElement('item', 'dropdown').getElement().hide()
              },
              {
                id: 'menuable_id',
                type: 'select',
                label: 'Page',
                items: ((CKEDITOR.config['effective_regions'] || {})['pages'] || [['', '']]),
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[menuable_id]']").val())
                commit: (element) ->
                  if this.getDialog().getValueOf('item', 'source') == 'Page'
                    element.children('.menu-item').children("input[name$='[menuable_id]']").val(this.getValue())
                    element.children('.menu-item').children("input[name$='[menuable_type]']").val('Effective::Page')
                  else if this.getDialog().getValueOf('item', 'source') == 'Dropdown'
                    # Nothing
                  else
                    element.children('.menu-item').children("input[name$='[menuable_id]']").val('')
                    element.children('.menu-item').children("input[name$='[menuable_type]']").val('')
                validate: ->
                  if this.getDialog().getValueOf('item', 'source') == 'Page' && (this.getValue() || '').length == 0
                    if this.getDialog().effective_menu_item.hasClass('dropdown') == false
                      CKEDITOR.dialog.validate.notEmpty('please select a page').apply(this)
              },
              {
                id: 'url',
                type: 'text',
                label: 'URL',
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[url]']").val())
                commit: (element) ->
                  if this.getDialog().getValueOf('item', 'source') == 'URL' then value = this.getValue() else value = ''

                  if this.getDialog().getValueOf('item', 'source') != 'Dropdown'
                    element.children('.menu-item').children("input[name$='[url]']").val(value)
                    element.children('a').attr('href', value || '#')
                validate: ->
                  if this.getDialog().getValueOf('item', 'source') == 'URL' && (this.getValue() || '').length == 0
                    CKEDITOR.dialog.validate.notEmpty('please enter a URL').apply(this)
              },
              {
                id: 'special',
                type: 'text',
                label: 'Route',
                setup: (element) ->
                  this.setValue(element.children('.menu-item').children("input[name$='[special]']").val())
                commit: (element) ->
                  if this.getDialog().getValueOf('item', 'source') == 'Divider'
                    element.children('.menu-item').children("input[name$='[special]']").val('divider')
                    element.children('a').html('')
                  else if this.getDialog().getValueOf('item', 'source') == 'Route'
                    element.children('.menu-item').children("input[name$='[special]']").val(this.getValue())
                  else if this.getDialog().getValueOf('item', 'source') == 'Dropdown'
                    # Nothing
                  else
                    element.children('.menu-item').children("input[name$='[special]']").val('')
                  # There is more stuff in the classes commit
                validate: ->
                  if this.getDialog().getValueOf('item', 'source') == 'Divider'
                    if this.getDialog().effective_menu_item.hasClass('dropdown')
                      CKEDITOR.dialog.validate.notEmpty('cannot convert existing dropdown menu to a Divider').apply(this)
                  else if this.getDialog().getValueOf('item', 'source') == 'Route'
                    if (this.getValue() || '').length == 0
                      CKEDITOR.dialog.validate.notEmpty('please enter a route').apply(this)
              },
              {
                id: 'dropdown',
                type: 'html',
                html: 'Dropdown menu items cannot also be links.<br><br>To change this dropdown back to a regular menu item,<br>please click Cancel and then use the drag & drop<br>functionality to remove all its child menu items.'
              }
            ] # /tab1 elements
          },
          {
            id: 'permissions',
            label: 'Permissions',
            elements: [
              {
                id: 'signed_out',
                type: 'checkbox',
                label: 'Only visible when signed out',
                setup: (element) ->
                  value = element.children('.menu-item').children("input[name$='[roles_mask]']").val()
                  this.setValue(value == '-1')
                onChange: (event) ->
                  if this.getValue() == true
                    this.getDialog().setValueOf('permissions', 'signed_in', false)

                    for role, index in ((CKEDITOR.config['effective_regions'] || {})['roles'] || [])
                      this.getDialog().setValueOf('permissions', "role_#{role[1]}", false)
              },
              {
                id: 'signed_in',
                type: 'checkbox',
                label: 'Only visible when signed in',
                setup: (element) ->
                  value = element.children('.menu-item').children("input[name$='[roles_mask]']").val()
                  this.setValue(value.length > 0 && parseInt(value, 10) >= 0)
                onChange: (event) ->
                  if this.getValue() == true
                    this.getDialog().setValueOf('permissions', 'signed_out', false)
              }
              {
                id: 'roles',
                type: 'vbox',
                width: '100%',
                children:
                  [{type: 'html', html: '<p>Only visible when signed in as a user with one or more<br>of the following website roles:</p>'}].concat(
                    for role, index in ((CKEDITOR.config['effective_regions'] || {})['roles'] || [])
                      bit_mask = Math.pow(2, index)
                      # role == [description, title, 'disabled' or null]   We're not using description
                      {
                        id: "role_#{role[1]}",
                        type: 'checkbox',
                        label: "#{role[1]}",
                        className: "role_#{bit_mask}_#{role[2]}_box"
                        setup: (element) ->
                          this.disable() if (this.className.split('_')[2] == 'disabled')

                          roles_mask = parseInt(element.children('.menu-item').children("input[name$='[roles_mask]']").val(), 10) || 0
                          roles_mask = 0 if roles_mask == -1
                          bit_mask = parseInt(this.className.split('_')[1], 10) || 0

                          this.setValue((bit_mask & roles_mask) != 0)
                        onClick: (event) ->
                          if this.getValue() == true # Ensure Only visible when signed in is checked too if we have roles
                            this.getDialog().setValueOf('permissions', 'signed_in', true)
                            this.getDialog().setValueOf('permissions', 'signed_out', false)
                      }
                  )
                commit: (element) ->
                  roles_mask = 0

                  for role, index in ((CKEDITOR.config['effective_regions'] || {})['roles'] || [])
                    if this.getDialog().getValueOf('permissions', "role_#{role[1]}") == true
                      roles_mask += Math.pow(2, index)

                  if roles_mask > 0
                    element.children('.menu-item').children("input[name$='[roles_mask]']").val(roles_mask)
                  else if this.getDialog().getValueOf('permissions', 'signed_in') == true
                    element.children('.menu-item').children("input[name$='[roles_mask]']").val(0)
                  else if this.getDialog().getValueOf('permissions', 'signed_out') == true
                    element.children('.menu-item').children("input[name$='[roles_mask]']").val(-1)
                  else
                    element.children('.menu-item').children("input[name$='[roles_mask]']").val('')
              }
            ]
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
                  value = this.getValue()
                  element.children('.menu-item').children("input[name$='[classes]']").val(value)

                  dropdown = element.hasClass('dropdown')

                  element.prop('class', value)

                  # Put back classes we need
                  element.addClass('dropdown') if dropdown

                  if this.getDialog().getValueOf('item', 'source') == 'Divider'
                    element.addClass('divider')
                  else
                    element.removeClass('divider')
              }
            ]
          }
        ], # /contents

        onShow: -> this.setupContent(this.effective_menu_item) if this.effective_menu_item

        onOk: ->
          if this.effective_menu_item
            this.commitContent(this.effective_menu_item)
            this.effective_menu_item.removeClass('new-item') if this.effective_menu_item.hasClass('new-item')

        onCancel: ->
          if this.effective_menu_item && this.effective_menu_item.hasClass('new-item')
            this.effective_menu_item.remove()
      }
