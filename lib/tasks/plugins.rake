namespace :plugins do
  desc 'Migrates installed plugins.'
  task :migrate => :environment do
    name = ENV['NAME']
    version = nil
    version_string = ENV['VERSION']
    if version_string
      if version_string =~ /^\d+$/
        version = version_string.to_i
        if name.nil?
          abort "The VERSION argument requires a plugin NAME."
        end
      else
        abort "Invalid VERSION #{version_string} given."
      end
    end

    begin
      Plugin.migrate(name, version)
    rescue PluginNotFound
      abort "Plugin #{name} was not found."
    end

    Rake::Task["db:schema:dump"].invoke
  end

  desc 'Copies plugins assets into the public directory.'
  task :assets => :environment do
    name = ENV['NAME']

    begin
      Plugin.mirror_assets(name)
    rescue PluginNotFound
      abort "Plugin #{name} was not found."
    end
  end
end

# Load plugins' rake tasks
Dir[File.join(Rails.root, "plugins/*/lib/tasks/**/*.rake")].sort.each { |ext| load ext }
