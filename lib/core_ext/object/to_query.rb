# If ActiveSupport is available, use the #to_query method it provides,
# otherwise, use our own. The code is taken from ActiveSupport 3.2.8.
begin
  require 'active_support/core_ext/object/to_query'
rescue LoadError
  # Copyright (c) 2005-2012 David Heinemeier Hansson
  #
  # Permission is hereby granted, free of charge, to any person obtaining
  # a copy of this software and associated documentation files (the
  # "Software"), to deal in the Software without restriction, including
  # without limitation the rights to use, copy, modify, merge, publish,
  # distribute, sublicense, and/or sell copies of the Software, and to
  # permit persons to whom the Software is furnished to do so, subject to
  # the following conditions:
  #
  # The above copyright notice and this permission notice shall be
  # included in all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  require 'core_ext/object/to_param'

  class Object
    # Converts an object into a string suitable for use as a URL query string, using the given <tt>key</tt> as the
    # param name.
    #
    # Note: This method is defined as a default implementation for all Objects for Hash#to_query to work.
    def to_query(key)
      require 'cgi' unless defined?(CGI) && defined?(CGI::escape)
      "#{CGI.escape(key.to_param)}=#{CGI.escape(to_param.to_s)}"
    end
  end

  class Array
    # Converts an array into a string suitable for use as a URL query string,
    # using the given +key+ as the param name.
    #
    #   ['Rails', 'coding'].to_query('hobbies') # => "hobbies%5B%5D=Rails&hobbies%5B%5D=coding"
    def to_query(key)
      prefix = "#{key}[]"
      collect { |value| value.to_query(prefix) }.join '&'
    end
  end

  class Hash
    alias_method :to_query, :to_param
  end
end
