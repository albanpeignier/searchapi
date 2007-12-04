module SearchApi
  
  # Utility class that implements fulltext search.
  #
  # Includes some Google-like features.
  
  class TextCriterion
    # t = TextCriterion.new('bonjour +les +amis -toto  -"allons bon" define:"salut poulette"')
    # t.meta_keywords      => {"define"=>["salut poulette"]}
    # t.mandatory_keywords => ["les", "amis"]
    # t.optional_keywords  => ["bonjour"],
    # t.negative_keywords  => ["toto", "allons bon"],
    # t.positive_keywords  = t.mandatory_keywords+t.optional_keywords
  
    # 
    attr_accessor :meta_keywords
    attr_accessor :mandatory_keywords
    attr_accessor :negative_keywords
    attr_accessor :optional_keywords
  
    def initialize(inSearchString='', inOptions= {})
      # inOptions may contain :
      # :exclude => string, Regexp, or list of Strings and Regexp to exclude (strings are case insensitive)
    
      @options = inOptions
      @options[:exclude] = [@options[:exclude]] unless @options[:exclude].nil? || (@options[:exclude].is_a?(Enumerable) && !@options[:exclude].is_a?(String))
      @options[:parse_meta?] = true if @options[:parse_meta?].nil?
    
      @meta_keywords = {}
      @mandatory_keywords = []
      @negative_keywords = []
      @optional_keywords = []
    
      unless inSearchString.blank?
    
        currentMeta = nil
      
        splitter = /
              (
                  [-+]?\b[^ ":]+\b:?
              )
              |
              (
                  [-+]?"[^"]*"
              )
            /x
    
        inSearchString.gsub(/\s+/, ' ').scan(splitter).each { |keyword|
          keyword=(keyword[0]||keyword[1]).gsub(/"/, '')
      
          if currentMeta
            @meta_keywords[currentMeta] ||= []
            @meta_keywords[currentMeta] << keyword
            currentMeta = nil
          else
            case keyword
            when /^-/
              @negative_keywords << keyword[1..-1] unless exclude_keyword?(keyword[1..-1])
            when /^\+/
              @mandatory_keywords << keyword[1..-1] unless exclude_keyword?(keyword[1..-1])
            when /:$/
              if @options[:parse_meta?]
                currentMeta = keyword[0..-2]
              else
                @optional_keywords << keyword unless exclude_keyword?(keyword)
              end
            else
              @optional_keywords << keyword unless exclude_keyword?(keyword)
            end
          end
        }
    
        # if everything is excluded, look for the whole search string
        @optional_keywords << inSearchString if @meta_keywords.empty? && @mandatory_keywords.empty? && @negative_keywords.empty? && @optional_keywords.empty?
      end
    end
  
    def to_s
      chunks = []
      chunks += @mandatory_keywords.map { |x| (x =~ / /) ? "+\"#{x}\"" : "+#{x}" } unless @mandatory_keywords.blank?
      chunks += @negative_keywords.map { |x| (x =~ / /) ? "-\"#{x}\"" : "-#{x}" } unless @negative_keywords.blank?
      chunks += @optional_keywords.map { |x| (x =~ / /) ? "\"#{x}\"" : x.to_s } unless @optional_keywords.blank?
      chunks += @meta_keywords.inject([]) { |s, key_value|
        key, value = key_value
        if value.is_a?(Array)
          s += value.map { |x| (x =~ / /) ? "#{key}:\"#{x}\"" : "#{key}:#{x}" }
        else
          s << ((value =~ / /) ? "#{key}:\"#{value}\"" : "#{key}:#{value}")
        end
        s
      } if @meta_keywords
      chunks.join(' ')
    end
  
    def positive_keywords
      @mandatory_keywords + @optional_keywords
    end
  
    def condition(inFields)
      conditions = SqlFragment.new
    
      conditions << (@mandatory_keywords.inject(SqlFragment.new) { |cv, value|
        value = "%#{value}%"
        cv.and(inFields.inject(SqlFragment.new) { |cf, field|
          cf.or(["#{field} like ?", value])
        })
      })
  
      conditions << (@negative_keywords.inject(SqlFragment.new) { |cv, value|
        value = "%#{value}%"
        cv.and(inFields.inject(SqlFragment.new) { |cf, field|
          cf.or(["#{field} is not null AND #{field} like ?", value])
        })
      }.not)
  
      conditions << (@optional_keywords.inject(SqlFragment.new) { |cv, value|
        value = "%#{value}%"
        cv.or(inFields.inject(SqlFragment.new) { |cf, field|
          cf.or(["#{field} like ?", value])
        })
      })
    
      conditions
    end

    protected
      def exclude_keyword?(inKeyword)
        return false unless @options[:exclude]
        return @options[:exclude].any? { |exclude| inKeyword =~ (exclude.is_a?(Regexp) ? exclude : Regexp.new(Regexp.escape(exclude), 'i')) }
      end
  end
end
