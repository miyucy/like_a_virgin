module LikeAVirgin
  class World
    def self.init(options)
      @count  = options.count
      @worlds = {}
      @count.times{ |i| @worlds[i] = nil }
      @cycle  = @worlds.cycle
    end

    def self.emit(files)
      number, world = @cycle.next
      world.try :join

      stream = $stdout
      pid = fork do
        $stdout = stream
        $stderr = stream
        LikeAVirgin.stop
        ENV["TEST_ENV_NUMBER"] = number.to_s || ""
        ActiveRecord::Base.configurations = Rails.configuration.database_configuration
        ActiveRecord::Base.establish_connection

        ARGV.clear
        ARGV.push files.shift while !files.empty?
        ARGV.push "-O"
        ARGV.push "spec/spec.opts"

        require "spec/spec_helper"
        Spec::Runner.run
        exit
      end
      exit 1 if pid.nil?

      @worlds[number] = Thread.new { Process.waitpid pid }
    end
  end
end
