require "rb-inotify"
require "like_a_virgin/file_map"
require "like_a_virgin/options"
require "like_a_virgin/world"
require "like_a_virgin/monkey_patches"

module LikeAVirgin
  def self.start
    setup_sigtrap
    @options = Options.new
    @changing_files = []
    @notifier = setup_notifier find_specs
    World.init(@options)

    @exit = false
    while !@exit
      @notifier.process while @changing_files.empty?
      changed_files = @changing_files.flatten.uniq.sort.dup
      break if changed_files.first.nil?
      @changing_files.clear
      World.emit changed_files
      sleep 1
    end
  end

  def self.stop
    @exit = true
    @notifier.try :close
    @changing_files << nil
  end

  def self.setup_sigtrap
    # restart
    Signal.trap(:INT) do
      LikeAVirgin.stop
      exit
    end

    # quit
    Signal.trap(:TSTP) do
      LikeAVirgin.stop
      exit
    end
  end

  def self.setup_notifier(fm)
    notifier = INotify::Notifier.new

    files = fm.keys
    dirs  = files.map{ |f| File.dirname f }.uniq
    dirs.each do |dir|
      notifier.watch(dir, :all_events) do |event|
        next unless event.flags.include?(:modify) || event.flags.include?(:move_to)
        next unless files.include? event.absolute_name
        @changing_files << fm[event.absolute_name]
      end
    end

    notifier
  end

  def self.find_specs
    file_map = FileMap.new Rails.root, Dir[Rails.root + "**/*"]

    file_map.matches(%r"spec/(models|controllers|routing|views|helpers|lib)/.*\.rb") do |fm, file|
      fm[file] = file
    end

    file_map.matches(%r"spec/fixtures/.*\.yml") do |fm, file|
      model = File.basename(file, ".yml")
      fm[file] = "spec/models/#{model.singularize}_spec.rb"
      fm[file] = file_map.matches(%r"spec/views/#{model}/.*_spec\.rb")
    end

    file_map.matches(%r"app/models/.*\.rb") do |fm, file|
      model = File.basename(file, ".rb")
      fm[file] = "spec/models/#{model}_spec.rb"
    end

    file_map.matches(%r"app/views/") do |fm, file|
      fm[file] = "spec/views/#{file.sub("app/views/","")}_spec.rb"
    end

    file_map.matches(%r"app/controllers/.*\.rb") do |fm, file|
      controller = File.basename(file, ".rb")
      if controller == "application_controller"
        fm[file] = file_map.matches(%r"spec/controllers/.*_spec\.rb")
      else
        fm[file] = "spec/controllers/#{controller}_spec.rb"
      end
    end

    file_map.matches(%r"app/helpers/.*_helper\.rb") do |fm, file|
      helper = File.basename(file, ".rb")
      if helper == "application_helper"
        fm[file] = file_map.matches(%r"spec/(views|helpers)/.*_spec\.rb")
      else
        fm[file] = "spec/helpers/#{helper}_spec.rb"
        fm[file] = file_map.matches(%r"spec/views/#{helper.sub("_helper","")}/.*_spec\.rb")
      end
    end

    file_map.matches(%r"spec/shared/.*\.rb") do |fm, file|
      fm[file] = file_map.matches(%r"spec/(controllers|routing|views|helpers)/.*_spec\.rb")
    end

    file_map.matches(%r"config/(boot|environment(s/test)?).rb") do |fm, file|
      fm[file] = file_map.matches(%r"spec/(controllers|routing|views|helpers)/.*_spec\.rb")
    end

    file_map.matches(%r"lib/.*\.rb") do |fm, file|
      fm[file] = "spec/#{file}_spec.rb"
    end

    file_map["config/routes.rb"]    = file_map.matches(%r"spec/(controllers|routing|views|helpers)/.*_spec\.rb")
    file_map["spec/spec_helper.rb"] = file_map.matches(%r"spec/(controllers|routing|views|helpers)/.*_spec\.rb")
    file_map["config/database.yml"] = file_map.matches(%r"spec/models/.*_spec\.rb")

    file_map.pattern
  end
end
