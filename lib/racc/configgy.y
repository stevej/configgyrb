
class ConfiggyParser

  rule
    include_file
      : 'include' STRING { puts val[1] }
end
