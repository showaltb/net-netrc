# $Id$

require './lib/net/netrc'

Gem::Specification.new do |s|
  s.name = 'net-netrc'
  s.version = Net::Netrc::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Net::Netrc provides ftp(1)-style .netrc parsing"
  s.files = Dir.glob("{lib,test}/**/*").delete_if { |item|
    item.include?( "CVS" ) }
  s.files << "README"
  s.files << "LICENSE"
  s.files << "NEWS"
  s.files << "ChangeLog"
  s.require_path = 'lib'
  s.autorequire = 'net/netrc'
  s.add_dependency 'Platform', '>= 0.3.0'
  s.has_rdoc=true
  s.test_file = 'test/test_netrc.rb'
  s.author = "Bob Showalter"
  s.email = "bshow@rubyforge.org"
  s.homepage = "http://net-netrc.rubyforge.org"
end
