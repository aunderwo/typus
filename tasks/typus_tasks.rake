namespace :typus do

  desc "Install Paperclip, acts_as_list, acts_as_tree."
  task :misc do

    plugins = [ "git://github.com/thoughtbot/paperclip.git", 
                "git://github.com/rails/acts_as_list.git", 
                "git://github.com/rails/acts_as_tree.git", 
                "git://github.com/fesplugas/simplified_translation.git" ]

    system "script/plugin install #{plugins.join(' ')}"

  end

  desc "Install simplified_translation."
  task :i18n do

    plugins = [ "git://github.com/fesplugas/simplified_translation.git" ]

    system "script/plugin install #{plugins.join(' ')}"

  end

  desc "List current roles"
  task :roles => :environment do
    Typus::Configuration.roles.each do |role|
      puts "\n#{role.first.capitalize} has access to:"
      role.last.each { |key, value| puts "- #{key}: #{value}" }
    end
    puts "\n"
  end

end