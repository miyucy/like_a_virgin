module LikeAVirgin
  class FileMap
    def initialize(root, files)
      @root    = root
      @files   = files
      @mapping = {}
    end

    def clear
      @mapping = {}
      @pattern = nil
    end

    def pattern
      @pattern ||= @mapping.inject({}) do |result, (source, depends)|
        depend = depends.flatten.select{ |f| file? f }
        result[source] = depend unless depend.empty?
        result
      end
    end

    def matches(pattern)
      if block_given?
        @files.grep(pattern) do |file|
          yield self, file
        end
      else
        @files.grep(pattern)
      end
    end

    def []=(source, depends)
      @mapping[source] ||= []
      @mapping[source]  << depends
    end

    def file?(file)
      FileTest.exist?(file) and FileTest.file?(file)
    end
  end
end
