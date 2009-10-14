require 'strscan'


class Regexp
  def sub(s, &block)
    out = ""
    offset = 0
    while m = match(s[offset..-1])
      out << s[offset...offset + m.begin(0)] if m.begin(0) > 0
      out << yield(m)
      offset += m.end(0)
    end
    out << s[offset..-1]
    out
  end
end


class String
	UNQUOTE_RE = /\\(u[\dA-Fa-f]{4}|x[\dA-Fa-f]{2}|[\/rnt\"\\])/

  # we intentionally don't unquote "\$" here, so it can be used to escape interpolation later.
  # some oddness: we're actually generating a bstring in utf8. ruby has no unicode support. :(
  def unquote_c
    UNQUOTE_RE.sub(self) do |m|
      case m[1][0]
      when ?u
        [m[1][1..-1].hex].pack("U")
      when ?x
        [m[1][1..-1].hex].pack("U")
      when ?r
        "\r"
      when ?n
        "\n"
      when ?t
        "\t"
      else
        m[1]
      end
    end
  end
end


class Lexer
	WHITESPACE = /(\s+|#[^\n]*\n)+/
	NUMBER = /-?\d+(\.\d+)?/
	STRING = /"([^\\\"]|\\[^ux]|\\\n|\\u[0-9a-fA-F]{4}|\\x[0-9a-fA-F]{2})*"/
	IDENT = /([a-zA-Z_][-\w]*)(\.[a-zA-Z_][-\w]*)*/
	ASSIGN = /=|\?=/
	OPAREN = /\(/
	CPAREN = /\)/
	OBRACKET = /\[/
	CBRACKET = /\]/
	OBRACE = /\{/
	CBRACE = /\}/
	OTAG = /</
	CTAG = />/


  attr_reader :filename, :lineno

	def initialize(str, filename=nil, lineno=1)
		@scanner = StringScanner.new(str.freeze)
		@filename = filename
		@lineno = lineno
	end

  def shift
		t = case
			when m = @scanner.scan(WHITESPACE)
			  [ :whitespace, m ]
			when m = @scanner.scan(NUMBER)
			  [ :NUMBER, m ]
			when m = @scanner.scan(STRING)
			  [ :STRING, Lexer.unquote_c(m) ]
			when m = @scanner.scan(IDENT)
			  [ :ident, m ]
			when m = @scanner.scan(ASSIGN)
			  [ :assign, m ]
		  when @scanner.eos?
		    [ false, false ]
			else
			  c = @scanner.getch
			  [ c, c ]
	  end
	  t.freeze
  end


end



