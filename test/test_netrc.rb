# $Id$

$:.unshift File.join(File.dirname(__FILE__), "../lib")

require 'net/netrc'
require 'test/unit'

class TestNetrc < Test::Unit::TestCase

  SAMPLE_NETRC = 'dot.netrc.test'

  def setup
    @path = File.join(File.dirname(__FILE__), SAMPLE_NETRC)
    File.open(@path, 'w') do |f|
      f << <<EOT
machine example.com
  login example_login
  password example_password
  account example_account

machine twowords.com
  login "twowords login"
  password "twowords password"
  account "twowords account"

macdef foo
  this is a macro definition.
  it starts with the line following 'macdef',
  and ends with a null line (consecutive newline characters)

default
  login default_login
  password default_password

machine unreached.com
  login unreached_login
  password unreached_password

EOT
    end
    File.chmod(0600, @path)
    ENV['NETRC'] = @path
  end

  def teardown
    File.unlink @path
  end

  def test_path
    assert_not_nil(ENV['NETRC'])
    assert(File.exists?(ENV['NETRC']), '#{SAMPLE_NETRC} not found')
    assert_equal(Net::Netrc.rcname, @path)
  end

  unless Net::Netrc::IS_WIN32
    def test_security
      File.chmod(0666, @path)
      assert_raise(SecurityError) { Net::Netrc.rcopen }
      File.chmod(0600, @path)
      assert_nothing_raised { Net::Netrc.rcopen }
    end
  end

  def test_entries

    entry = Net::Netrc.locate('example.com')
    assert_not_nil(entry)
    assert_equal('example.com', entry.machine)
    assert_equal('example_login', entry.login)
    assert_equal('example_password', entry.password)
    assert_equal('example_account', entry.account)

    entry = Net::Netrc.locate('twowords.com')
    assert_not_nil(entry)
    assert_equal('twowords.com', entry.machine)
    assert_equal('twowords login', entry.login)
    assert_equal('twowords password', entry.password)
    assert_equal('twowords account', entry.account)

    default = Net::Netrc.locate('')
    assert_not_nil(default)
    assert_nil(default.machine)
    assert_equal('default_login', default.login)
    assert_equal('default_password', default.password)
    assert_nil(default.account)

    entry = Net::Netrc.locate('unreached.com')
    assert_not_nil(entry)
    assert_equal(default.machine, entry.machine)
    assert_equal(default.login, entry.login)
    assert_equal(default.password, entry.password)
    assert_equal(default.account, entry.account)

  end

end
