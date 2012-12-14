# If ActiveSupport is available, use the #to_param method it provides,
# otherwise, use our own. The code is taken from ActiveSupport 3.2.8.
begin
  require 'active_support/core_ext/object/to_param'
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
  class Object
    # Alias of <tt>to_s</tt>.
    def to_param
      to_s
    end
  end

  class NilClass
    def to_param
      self
    end
  end

  class TrueClass
    def to_param
      self
    end
  end

  class FalseClass
    def to_param
      self
    end
  end

  class Array
    # Calls <tt>to_param</tt> on all its elements and joins the result with
    # slashes. This is used by <tt>url_for</tt> in Action Pack.
    def to_param
      collect { |e| e.to_param }.join '/'
    end
  end

  class Hash
    # Returns a string representation of the receiver suitable for use as a URL
    # query string:
    #
    #   {:name => 'David', :nationality => 'Danish'}.to_param
    #   # => "name=David&nationality=Danish"
    #
    # An optional namespace can be passed to enclose the param names:
    #
    #   {:name => 'David', :nationality => 'Danish'}.to_param('user')
    #   # => "user[name]=David&user[nationality]=Danish"
    #
    # The string pairs "key=value" that conform the query string
    # are sorted lexicographically in ascending order.
    #
    # This method is also aliased as +to_query+.
    def to_param(namespace = nil)
      collect do |key, value|
        value.to_query(namespace ? "#{namespace}[#{key}]" : key)
      end.sort * '&'
    end
  end
end
