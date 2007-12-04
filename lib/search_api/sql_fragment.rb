module SearchApi
  
  # Utility class that implements logic for sql fragments (such as ["escaped_sql = ?", dirty_string])
  
  class SqlFragment < Array
    # A class that makes it more easy to manipulate SQL fragments : 'a=1' or ['a=?', 1]
    #
    # c = SqlFragment()             => []
    # c = SqlFragment('')           => []
    # c = SqlFragment('a=1')        => ["a=1"]
    # c = SqlFragment(['a=?', 1])   => ["a=?", 1]
    # c.or(SqlFragment())           => ["a=?", 1]
    # c.or(SqlFragment('b=2'))      => ["(a=?) OR (b=2)", 1]
    # c.or!(['b=?', 2])             => ["(a=?) OR (b=?)", 1, 2]
    # c.and('c=3')                  => ["((a=?) OR (b=?)) AND (c=3)", 1, 2]
    # c << ['c=?', 3]               => ["((a=?) OR (b=?)) AND (c=?)", 1, 2, 3]
    # c                             => ["((a=?) OR (b=?)) AND (c=?)", 1, 2, 3]
  
    class << self
      def sanitize(*args)
        self.new(*args).sanitize
      end
    end
  
    attr_reader :logical_operator
  
    def initialize(*args)
      if args.length > 1
      else
        args = args.first
      end
    
      # default operator is AND
      self.logical_operator = :and
    
      return if args.nil? or args.empty?
    
      if args.is_a? Array
        replace(args)
      else
        self.push(args)
      end
    end
  
    def logical_operator=(logical_operator)
      @logical_operator = (logical_operator || :and)
    end
  
    def and(inSqlFragment)
      inSqlFragment = SqlFragment.new(inSqlFragment) unless inSqlFragment.is_a?(SqlFragment)
      return self if inSqlFragment.empty?
      return inSqlFragment if empty?
      SqlFragment(["(#{sqlString}) AND (#{inSqlFragment[0]})"] + sqlParameters + inSqlFragment[1..-1])
    end
    def and!(inSqlFragment) replace(self.and(inSqlFragment)) end

    def or(inSqlFragment)
      inSqlFragment = SqlFragment.new(inSqlFragment) unless inSqlFragment.is_a?(SqlFragment)
      return self if inSqlFragment.empty?
      return inSqlFragment if empty?
      SqlFragment(["(#{sqlString}) OR (#{inSqlFragment[0]})"] + sqlParameters + inSqlFragment[1..-1])
    end
    def or!(inSqlFragment) replace(self.or(inSqlFragment)) end
  
    def <<(inSqlFragment)
      case logical_operator
      when :and!, :and
        and!(inSqlFragment)
      when :or!, :or
        or!(inSqlFragment)
      else
        raise "Unsupported logical_operator #{logical_operator.inspect}"
      end
    end
  
    def not
      return self if empty?
      SqlFragment(["NOT(#{sqlString})"]+sqlParameters)
    end
  
    def sqlString
      self[0]
    end
    def sqlParameters
      self[1..-1]
    end
  
    def sanitize
      fragment = self
      ActiveRecord::Base.instance_eval do sanitize_sql(fragment) end
    end
  end
end


def SqlFragment(*args)
  SearchApi::SqlFragment.new(*args)
end
