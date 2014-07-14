$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'csvql'

def capture
  begin
    $stdout = StringIO.new
    yield
    result = $stdout.string
  ensure
    $stdout = STDOUT
  end
  result
end
