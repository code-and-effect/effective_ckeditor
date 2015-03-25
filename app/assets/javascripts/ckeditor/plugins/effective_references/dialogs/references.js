/**
 * The effective references dialog definition.
 *
 * Based on https://github.com/andykirk/CKEditorFootnotes Version 1.0.9
 *
 */

// Dialog definition.
CKEDITOR.dialog.add( 'referencesDialog', function( editor ) {

    return {
        editor_name: false,
        // Basic properties of the dialog window: title, minimum size.
        title: 'Manage References',
        minWidth: 400,
        minHeight: 200,
        references_el: false,

        // Dialog window contents definition.
        contents: [
            {
                // Definition of the Basic Settings dialog tab (page).
                id: 'tab-basic',
                label: 'Basic Settings',

                // The tab contents.
                elements: [
                    {
                        // Text input field for the references text.
                        type: 'textarea',
                        id: 'new_reference',
                        'class': 'reference_text',
                        label: 'New reference:',
                        inputStyle: 'height: 100px',
                    },
                    {
                        // Text input field for the references title (explanation).
                        type: 'text',
                        id: 'reference_id',
                        name: 'reference_id',
                        label: 'No existing references',


                        // Called by the main setupContent call on dialog initialization.
                        setup: function( element ) {
                            var dialog = this.getDialog();
                            $el = jQuery('#' + this.domId);

                            dialog.references_el = $el;

                            editor = dialog.getParentEditor();
                            // Dynamically add existing references:
                            $references = editor.plugins.effective_references.editorContents(editor).find('.references ol');
                            $this = this;

                            if ($references.length > 0) {
                                if ($el.find('p').length == 0) {
                                    $el.append('<p style="margin-bottom: 10px;"><strong>OR:</strong> Choose reference:</p><ol class="references_list"></ol>');
                                } else {
                                    $el.find('ol').empty();
                                }

                                var radios = '';
                                $references.find('li').each(function(){
                                    $item = jQuery(this);
                                    var reference_id = $item.attr('data-reference-id');
                                    radios += '<li style="margin-left: 15px;"><input type="radio" name="reference_id" value="' + reference_id + '" id="fn_' + reference_id + '" /> <label for="fn_' + reference_id + '" style="white-space: normal; display: inline-block; padding: 0 25px 0 5px; vertical-align: top; margin-bottom: 10px;">' + $item.find('cite').text() + '</label></li>';
                                });

                                $el.children('label,div').css('display', 'none');
                                $el.find('ol').html(radios);
                                $el.find(':radio').change(function(){;
                                    $el.find(':text').val(jQuery(this).val());
                                });

                            } else {
                                $el.children('div').css('display', 'none');
                            }
                        }
                    }
                ]
            },
        ],

        // Invoked when the dialog is loaded.
        onShow: function() {
            this.setupContent();

            var dialog = this;
            CKEDITOR.on( 'instanceLoaded', function( evt ) {
                dialog.editor_name = evt.editor.name;
            } );

            var current_editor_id = dialog.getParentEditor().id;

            CKEDITOR.replaceAll( function( textarea, config ) {
                // Make sure the textarea has the correct class:
                if (!textarea.className.match(/reference_text/)) {
                    return false;
                }

                // Make sure we only instantiate the relevant editor:
                var el = textarea;
                while ((el = el.parentElement) && !el.classList.contains(current_editor_id));
                if (!el) {
                    return false;
                }
                //console.log(el);
                config.toolbarGroups = [
                    { name: 'editing',     groups: [ 'undo', 'find', 'selection', 'spellchecker' ] },
                    { name: 'clipboard',   groups: [ 'clipboard' ] },
                    { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
                ]
                config.allowedContent = 'br em strong; a[!href]';
                config.enterMode = CKEDITOR.ENTER_BR;
                config.autoParagraph = false;
                config.height = 80;
                config.resize_enabled = false;
                config.autoGrow_minHeight = 80;
                config.removePlugins = 'references';
                config.customConfig = '';

                config.on = {
                    focus: function( evt ){
                        var $editor_el = jQuery('#' + evt.editor.id + '_contents');
                        $editor_el.parents('tr').next().find(':checked').attr('checked', false);
                        $editor_el.parents('tr').next().find(':text').val('');
                    }
                };
                return true;
            });

        },

        // This method is invoked once a user clicks the OK button, confirming the dialog.
        onOk: function() {
            var dialog = this;
            var reference_editor = CKEDITOR.instances[dialog.editor_name];
            var reference_id     = dialog.getValueOf('tab-basic', 'reference_id');
            var reference_data   = reference_editor.getData();
            reference_editor.destroy();

            if (reference_id == '') {
                // No existing id selected, check for new reference:
                if (reference_data == '') {
                    // Nothing entered, so quit:
                    return;
                } else {
                    // Insert new reference:
                    editor.plugins.effective_references.build(reference_data, true, editor);
                }
            } else {
                // Insert existing reference:
                editor.plugins.effective_references.build(reference_id, false, editor);
            }
            // Destroy the editor so it's rebuilt properly next time:
            return;
        },

        onCancel: function() {
            var dialog = this;
            var reference_editor = CKEDITOR.instances[dialog.editor_name];
            reference_editor.destroy();
        }
    };
});
