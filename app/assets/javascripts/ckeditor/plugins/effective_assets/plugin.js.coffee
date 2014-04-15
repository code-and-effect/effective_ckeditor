# This plugin just opens the Snippet dialog

CKEDITOR.plugins.add 'effective_assets',
  icons: 'effectiveassets',
  hidpi: true,
  init: (editor) ->
      editor.ui.addButton 'EffectiveAssets', {label: 'Insert/Upload File', command: 'openEffectiveAssetsSnippetDialog'}
      editor.addCommand('openEffectiveAssetsSnippetDialog', OpenEffectiveAssetsSnippetDialog)

OpenEffectiveAssetsSnippetDialog = {
  exec: (editor) -> 
    if (command = editor.getCommand('effective_asset'))
      command.exec(editor)
    else
      alert('This function is currently disabled.  Please install EffectiveAssets gem.')
}

