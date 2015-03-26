#/bin/sh
for i in ./ckeditor/skins/moonocolor/*.css; do
  mv $i $i.erb

  ### Regular DPI

  # Icons
  search="url(icons.png)"
  replace="url(<%= asset_path('ckeditor\\/skins\\/moonocolor\\/icons.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # Arrow.png
  search="url(images\\/arrow.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/arrow.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # Close.png
  search="url(images\\/close.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/close.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # Lock-open.png
  search="url(images\\/lock-open.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/lock-open.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"


  # Lock.png
  search="url(images\\/lock.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/lock.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # Refresh.png
  search="url(images\\/refresh.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/refresh.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  ### Hi DPI

  # Icons
  search="url(icons_hidpi.png)"
  replace="url(<%= asset_path('ckeditor\\/skins\\/moonocolor\\/icons_hidpi.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # Close.png
  search="url(images\\/hidpi\\/close.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/hidpi\\/close.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # Lock-open.png
  search="url(images\\/hidpi\\/lock-open.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/hidpi\\/lock-open.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # lock.png
  search="url(images\\/hidpi\\/lock.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/hidpi\\/lock.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"

  # refresh.png
  search="url(images\\/hidpi\\/refresh.png)"
  replace="url(<%= asset_data_uri('ckeditor\\/skins\\/moonocolor\\/images\\/hidpi\\/refresh.png') %>)"
  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"
done

echo 'Done rewriting asset paths.  Thanks and have a seriously lovely day.'
