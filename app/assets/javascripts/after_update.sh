#/bin/sh
for i in ./ckeditor/skins/moonocolor/*.css; do
  mv $i $i.erb

  search="url(icons.png)"
  replace="url(<%= asset_path('ckeditor/skins/moonocolor/icons.png') %>)"

  sed -i '' -e "s/${search}/${replace}/g" "${i}.erb"
done

