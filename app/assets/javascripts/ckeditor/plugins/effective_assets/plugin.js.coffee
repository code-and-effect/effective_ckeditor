# This plugin just opens the Snippet dialog

CKEDITOR.plugins.add 'effective_assets',
  init: (editor) ->
      editor.ui.addButton 'EffectiveAssets', {label: 'Insert File', command: 'openEffectiveAssetsSnippetDialog'}
      editor.addCommand('openEffectiveAssetsSnippetDialog', OpenEffectiveAssetsSnippetDialog)

OpenEffectiveAssetsSnippetDialog = {
  exec: (editor) ->
    if (command = editor.getCommand('effective_assets'))
      command.exec(editor)
    else if (command = editor.getCommand('ck_asset'))
      command.exec(editor)
    else
      alert('This function is currently disabled.')
}

