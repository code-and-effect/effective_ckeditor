/**
 * Basic sample plugin inserting references elements into CKEditor editing area.
 *
 * Based on https://github.com/andykirk/CKEditorFootnotes Version 1.0.9
 *
 */
// Register the plugin within the editor.
CKEDITOR.plugins.add( 'effective_references', {
    reference_ids: [],
    requires: 'widget',

    // The plugin initialization logic goes inside this method.
    init: function(editor) {
        // Allow `cite` to be editable:
        CKEDITOR.dtd.$editable['cite'] = 1;

        // Add some CSS tweaks:
        var css = '.references{background:#eee; padding:1px 15px;} .references cite{font-style: normal;}';
        CKEDITOR.addCss(css);

        var $this = this;

        // Force a reorder on startup to make sure all vars are set: (e.g. references store):
        editor.on('instanceReady', function(evt) {
            $this.reorderMarkers(editor);
        });

        // Add the reorder change event:
        editor.on('change', function(evt) {
            // Copy the references_store as we may be doing a cut:
            if(!evt.editor.references_tmp) {
                evt.editor.references_tmp = evt.editor.references_store;
            }

            // Prevent no selection errors:
            if (!evt.editor.getSelection().getStartElement()) {
                return;
            }
            // Don't reorder the markers if editing a cite:
            var reference_section = evt.editor.getSelection().getStartElement().getAscendant('section');
            if (reference_section && reference_section.$.className.indexOf('references') != -1) {
                return;
            }
            // SetTimeout seems to be necessary (it's used in the core but can't be 100% sure why)
            setTimeout(function(){
                    $this.reorderMarkers(editor);
                },
                0
            );
        });

        // Build the initial references widget editables definition:
        var prefix = editor.config.referencesPrefix ? '-' + editor.config.referencesPrefix : '';
        var def = {
            header: {
                selector: 'header > *',
                //allowedContent: ''
                allowedContent: 'strong em span sub sup;'
            }
        };
        var contents = jQuery('<div>' + editor.element.$.textContent + '</div>')
                 , l = contents.find('.references li').length
                 , i = 1;
        for (i; i <= l; i++) {
            def['reference_' + i] = {selector: '#reference' + prefix + '-' + i + ' cite', allowedContent: 'a[href]; cite[*](*); strong em span br'};
        }

        // Register the references widget.
        editor.widgets.add('references', {

            // Minimum HTML which is required by this widget to work.
            requiredContent: 'section(references)',

            // Check the elements that need to be converted to widgets.
            upcast: function(element) {
                return element.name == 'section' && element.hasClass('references');
            },

            editables: def
        });

        // Register the referencemarker widget.
        editor.widgets.add('referencemarker', {

            // Minimum HTML which is required by this widget to work.
            requiredContent: 'sup[data-reference-id]',

            // Check the elements that need to be converted to widgets.
            upcast: function(element) {
                return element.name == 'sup' && element.attributes['data-reference-id'] != 'undefined';
            }
        });

        // Define an editor command that opens our dialog.
        editor.addCommand('references', new CKEDITOR.dialogCommand('referencesDialog', {
            // @TODO: This needs work:
            allowedContent: 'section[*](*);header[*](*);li[*];a[*];cite(*)[*];sup[*]',
            requiredContent: 'section[*](*);header[*](*);li[*];a[*];cite(*)[*];sup[*]'
        }));

        // Create a toolbar button that executes the above command.
        editor.ui.addButton('EffectiveReferences', {

            // The text part of the button (if available) and tooptip.
            label: 'Insert References',

            // The command to execute on click.
            command: 'references',

            // The button placement in the toolbar (toolbar group name).
            toolbar: 'insert'
        });

        // Register our dialog file. this.path is the plugin folder path.
        CKEDITOR.dialog.add('referencesDialog', this.path + 'dialogs/references.js');
    },

    editorContents: function(editor) {
        if (editor.config.referencesEditorSelector) {
            return jQuery(eval(editor.config.referencesEditorSelector)).contents()
        } else {
            return jQuery('#' + editor.id + '_contents iframe').contents().find('body');
        }
    },

    build: function(reference, is_new, editor) {

        if (is_new) {
            // Generate new id:
            reference_id = this.generateReferenceId();
        } else {
            // Existing reference id passed:
            reference_id = reference;
        }

        // Insert the marker:
        var reference_marker = '<sup data-reference-id="' + reference_id + '">X</sup>';

        editor.insertHtml(reference_marker);

        if (is_new) {
            editor.fire('lockSnapshot');
            this.addReference(this.buildReference(reference_id, reference, false, editor), editor);
            editor.fire('unlockSnapshot');
        }
        this.reorderMarkers(editor);
    },

    buildReference: function(reference_id, reference_text, data, editor) {
        data ? data : false;
        var links   = '';
        var letters = 'abcdefghijklmnopqrstuvwxyz';
        var order   = data ? data.order.indexOf(reference_id) + 1
                           : 1;
        var prefix  = editor.config.referencesPrefix ? '-' + editor.config.referencesPrefix : '';
        if (data && data.occurrences[reference_id] == 1) {
            links = '<a href="#reference-marker' + prefix + '-' + order + '-1">^</a> ';
        } else if (data && data.occurrences[reference_id] > 1) {
            var i = 0
              , l = data.occurrences[reference_id]
              , n = l;
            for (i; i < l; i++) {
                links += '<a href="#reference-marker' + prefix + '-' + order + '-' + (i + 1) + '">' + letters.charAt(i) + '</a>';
                if (i < l-1) {
                    links += ', ';
                } else {
                    links += ' ';
                }
            }
        }
        reference = '<li id="reference' + prefix + '-' + order + '" data-reference-id="' + reference_id + '">' + links + '<cite>' + reference_text + '</cite></li>';
        return reference;
    },

    addReference: function(reference, editor) {
        $contents  = this.editorContents(editor);
        $references = $contents.find('.references');

        if ($references.length == 0) {
            var container = '<section class="references"><header><h2>References</h2></header><ol>' + reference + '</ol></section>';
            // Move cursor to end of content:
            var range = editor.createRange();
            range.moveToElementEditEnd(range.root);
            editor.getSelection().selectRanges([range]);
            // Insert the container:
            editor.insertHtml(container);
        } else {
            $references.find('ol').append(reference);
        }
        return;
    },

    generateReferenceId: function() {
        var id = Math.random().toString(36).substr(2, 5);
        while (jQuery.inArray(id, this.reference_ids) != -1) {
            id = String(this.generateReferenceId());
        }
        this.reference_ids.push(id);
        return id;
    },

    reorderMarkers: function(editor) {
        editor.fire('lockSnapshot');
        var prefix  = editor.config.referencesPrefix ? '-' + editor.config.referencesPrefix : '';
        $contents = this.editorContents(editor);
        var data = {
            order: [],
            occurrences: {}
        };

        // Check that there's a references section. If it's been deleted the markers are useless:
        if ($contents.find('.references').length == 0) {
            $contents.find('sup[data-reference-id]').remove();
            editor.fire('unlockSnapshot');
            return;
        }

        // Find all the markers in the document:
        var $markers = $contents.find('sup[data-reference-id]');
        // If there aren't any, remove the References container:
        if ($markers.length == 0) {
            $contents.find('.references').parent().remove();
            editor.fire('unlockSnapshot');
            return;
        }

        // Otherwise reorder the markers:
        $markers.each(function(){
            var reference_id = jQuery(this).attr('data-reference-id')
              , marker_ref
              , n = data.order.indexOf(reference_id);

            // If this is the markers first occurrence:
            if (n == -1) {
                // Store the id:
                data.order.push(reference_id);
                n = data.order.length;
                data.occurrences[reference_id] = 1;
                marker_ref = n + '-1';
            } else {
                // Otherwise increment the number of occurrences:
                // (increment n due to zero-index array)
                n++;
                data.occurrences[reference_id]++;
                marker_ref = n + '-' + data.occurrences[reference_id];
            }
            // Replace the marker contents:
            var marker = '<a href="#reference' + prefix + '-' + n + '" id="reference-marker' + prefix + '-' + marker_ref + '" rel="reference">[' + n + ']</a>';
            jQuery(this).html(marker);
        });

        // Prepare the references_store object:
        editor.references_store = {};

        // Then rebuild the References content to match marker order:
        var references     = '';
        var reference_text = '';
        var i = 0
          , l = data.order.length;
        for (i; i < l; i++) {
            reference_id   = data.order[i];
            reference_text = $contents.find('.references [data-reference-id=' + reference_id + '] cite').html();
            // If the references text can't be found in the editor, it may be in the tmp store
            // following a cut:
            if (!reference_text) {
                reference_text = editor.references_tmp[reference_id];
            }
            references += this.buildReference(reference_id, reference_text, data, editor);
            // Store the references for later use (post cut/paste):
            editor.references_store[reference_id] = reference_text;
        }

        // Insert the references into the list:
        $contents.find('.references ol').html(references);

        // Next we need to reinstate the 'editable' properties of the references.
        // (we have to do this individually due to Widgets 'fireOnce' for editable selectors)
        var el = $contents.find('.references')
          , reference_widget;
        // So first we need to find the right Widget instance:
        // (I hope there's a better way of doing this but I can't find one)
        for (i in editor.widgets.instances) {
            if (editor.widgets.instances[i].name == 'references') {
                reference_widget = editor.widgets.instances[i];
                break;
            }
        }
        // Then we `initEditable` each reference, giving it a unique selector:
        for (i in data.order) {
            n = parseInt(i) + 1;
            reference_widget.initEditable('reference_' + n, {selector: '#reference' + prefix + '-' + n +' cite', allowedContent: 'a[href]; cite[*](*); em strong span'});
        }

        editor.fire('unlockSnapshot');
        return;
    }
});
