require 'yarjuf'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

class String
  def unindent
    gsub /^#{self[/\A\s*/]}/, ''
  end
end