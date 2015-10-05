#
# Based on Redmine plugin system by Jean-Philippe Lang
#

class PluginNotFound < StandardError
end
class PluginRequirementError < StandardError
end

# Base class for Redmine plugins.
# Plugins are registered using the <tt>register</tt> class method that acts as the public constructor.
#
#   Redmine::Plugin.register :example do
#     name 'Example plugin'
#     author 'John Smith'
#     description 'This is an example plugin for Redmine'
#     version '0.0.1'
#
class Plugin
  cattr_accessor :directory
  self.directory = File.join(Rails.root, 'plugins')

  cattr_accessor :public_directory
  self.public_directory = File.join(Rails.root, 'public', 'plugin_assets')

  @registered_plugins = {}

  class << self
    attr_reader :registered_plugins
    private :new

    def def_field(*names)
      class_eval do
        names.each do |name|
          define_method(name) do |*args|
            args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
          end
        end
      end
    end
  end
  def_field :name, :description, :url, :author, :author_url, :version, :directory
  attr_reader :id

  # Plugin constructor
  def self.register(id, &block)
    p = new(id)
    p.instance_eval(&block)

    # Set a default name if it was not provided during registration
    p.name(id.to_s.humanize) if p.name.nil?
    # Set a default directory if it was not provided during registration
    p.directory(File.join(self.directory, id.to_s)) if p.directory.nil?

    # Adds plugin locales if any
    # YAML translation files should be found under <plugin>/config/locales/
    Rails.application.config.i18n.load_path += Dir.glob(File.join(p.directory, 'config', 'locales', '*.yml'))

    # Prepends the app/views directory of the plugin to the view path
    view_path = File.join(p.directory, 'app', 'views')
    if File.directory?(view_path)
      ActionController::Base.prepend_view_path(view_path)
      ActionMailer::Base.prepend_view_path(view_path)
    end

    # Adds the app/{controllers,helpers,models} directories of the plugin to the autoload path
    Dir.glob File.expand_path(File.join(p.directory, 'app', '{controllers,helpers,models}')) do |dir|
      ActiveSupport::Dependencies.autoload_paths += [dir]
    end

    registered_plugins[id] = p
  end

  # Returns an array of all registered plugins
  def self.all
    registered_plugins.values.sort
  end

  # Finds a plugin by its id
  # Returns a PluginNotFound exception if the plugin doesn't exist
  def self.find(id)
    registered_plugins[id.to_sym] || raise(PluginNotFound)
  end

  # Clears the registered plugins hash
  # It doesn't unload installed plugins
  def self.clear
    @registered_plugins = {}
  end

  # Removes a plugin from the registered plugins
  # It doesn't unload the plugin
  def self.unregister(id)
    @registered_plugins.delete(id)
  end

  # Checks if a plugin is installed
  #
  # @param [String] id name of the plugin
  def self.installed?(id)
    registered_plugins[id.to_sym].present?
  end

  def self.load
    Dir.glob(File.join(self.directory, '*')).sort.each do |directory|
      if File.directory?(directory)
        lib = File.join(directory, "lib")
        if File.directory?(lib)
          $:.unshift lib
          ActiveSupport::Dependencies.autoload_paths += [lib]
        end
        initializer = File.join(directory, "init.rb")
        if File.file?(initializer)
          require initializer
        end
      end
    end
  end

  def initialize(id)
    @id = id.to_sym
  end

  def public_directory
    File.join(self.class.public_directory, id.to_s)
  end

  def to_param
    id
  end

  def assets_directory
    File.join(directory, 'assets')
  end

  def <=>(plugin)
    self.id.to_s <=> plugin.id.to_s
  end

  def mirror_assets
    source = assets_directory
    destination = public_directory
    return unless File.directory?(source)

    source_files = Dir[source + "/**/*"]
    source_dirs = source_files.select { |d| File.directory?(d) }
    source_files -= source_dirs

    unless source_files.empty?
      base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ''))
      begin
        FileUtils.mkdir_p(base_target_dir)
      rescue Exception => e
        raise "Could not create directory #{base_target_dir}: " + e.message
      end
    end

    source_dirs.each do |dir|
      # strip down these paths so we have simple, relative paths we can
      # add to the destination
      target_dir = File.join(destination, dir.gsub(source, ''))
      begin
        FileUtils.mkdir_p(target_dir)
      rescue Exception => e
        raise "Could not create directory #{target_dir}: " + e.message
      end
    end

    source_files.each do |file|
      begin
        target = File.join(destination, file.gsub(source, ''))
        unless File.exist?(target) && FileUtils.identical?(file, target)
          FileUtils.cp(file, target)
        end
      rescue Exception => e
        raise "Could not copy #{file} to #{target}: " + e.message
      end
    end
  end

  # Mirrors assets from one or all plugins to public/plugin_assets
  def self.mirror_assets(name=nil)
    if name.present?
      find(name).mirror_assets
    else
      all.each do |plugin|
        plugin.mirror_assets
      end
    end
  end

  # The directory containing this plugin's migrations (<tt>plugin/db/migrate</tt>)
  def migration_directory
    File.join(directory, 'db', 'migrate')
  end

  # Returns the version number of the latest migration for this plugin. Returns
  # nil if this plugin has no migrations.
  def latest_migration
    migrations.last
  end

  # Returns the version numbers of all migrations for this plugin.
  def migrations
    migrations = Dir[migration_directory+"/*.rb"]
    migrations.map { |p| File.basename(p).match(/0*(\d+)\_/)[1].to_i }.sort
  end

  # Migrate this plugin to the given version
  def migrate(version = nil)
    puts "Migrating #{id} (#{name})..."
    Plugin::Migrator.migrate_plugin(self, version)
  end

  # Migrates all plugins or a single plugin to a given version
  # Exemples:
  #   Plugin.migrate
  #   Plugin.migrate('sample_plugin')
  #   Plugin.migrate('sample_plugin', 1)
  #
  def self.migrate(name=nil, version=nil)
    if name.present?
      find(name).migrate(version)
    else
      all.each do |plugin|
        plugin.migrate
      end
    end
  end

  class Migrator < ActiveRecord::Migrator
    # We need to be able to set the 'current' plugin being migrated.
    cattr_accessor :current_plugin

    class << self
      # Runs the migrations from a plugin, up (or down) to the version given
      def migrate_plugin(plugin, version)
        self.current_plugin = plugin
        return if current_version(plugin) == version
        migrate(plugin.migration_directory, version)
      end

      def current_version(plugin=current_plugin)
        # Delete migrations that don't match .. to_i will work because the number comes first
        ::ActiveRecord::Base.connection.select_values(
          "SELECT version FROM #{schema_migrations_table_name}"
        ).delete_if{ |v| v.match(/-#{plugin.id}$/) == nil }.map(&:to_i).max || 0
      end
    end

    def migrated
      sm_table = self.class.schema_migrations_table_name
      ::ActiveRecord::Base.connection.select_values(
        "SELECT version FROM #{sm_table}"
      ).delete_if{ |v| v.match(/-#{current_plugin.id}$/) == nil }.map(&:to_i).sort
    end

    def record_version_state_after_migrating(version)
      super(version.to_s + "-" + current_plugin.id.to_s)
    end
  end
end
