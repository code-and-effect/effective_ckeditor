# This was modified from https://github.com/galetahub/ckeditor

namespace :ckeditor do
  desc 'Create nondigest versions of some ckeditor assets (e.g. moono skin png)'
  task :create_nondigest_assets do
    fingerprint = /\-[0-9a-f]{32}\./
    for file in Dir['public/assets/ckeditor/skins/**/*.*', 'public/assets/ckeditor/plugins/*.png', 'public/assets/effective/snippets/*.*']
      next unless file =~ fingerprint
      nondigest = file.sub fingerprint, '.' # contents-0d8ffa186a00f5063461bc0ba0d96087.css => contents.css
      FileUtils.cp file, nondigest, verbose: true
    end
  end
end

# auto run ckeditor:create_nondigest_assets after assets:precompile
Rake::Task['assets:precompile'].enhance do
  puts 'undigesting required effective_ckeditor assets'
  Rake::Task['ckeditor:create_nondigest_assets'].invoke
end

