require "optparse"

module LikeAVirgin
  class Options
    attr_reader :count

    def initialize
      @count = 2
      OptionParser.new do |opts|
        opts.banner = "Usage: luv [options]"

        opts.on('-c COUNT') do |c|
          @count = c
        end
      end.parse!
    end
  end
end
