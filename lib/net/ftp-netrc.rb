# = net/ftp-netrc.rb - Net::FTP / Net::Netrc integration
#
# Copyright (c) 2005-2009 Bob Showalter
#
# This library is distributed under the terms of the Ruby license.
# You may freely distribute or modify this library.
#
# This module extends the Net::FTP#login method to use Net::Netrc
# to lookup login information if a nil username is passed.
#
# Example:
#
#   require 'net/ftp-netrc'     # (brings in net/ftp and net/netrc)
#
#   ftp = Net::FTP.new('myhost')
#   ftp.login(nil)
#   ftp.last_response
#   => 230 User myuser logged in.

require 'net/ftp'
require 'net/netrc'

module Net

  class FTP

    alias_method :orig_connect, :connect  # :nodoc:
    alias_method :orig_login, :login      # :nodoc:

    # cache host name for later use by login
    def connect(host, port = FTP_PORT) # :nodoc:
      @host = host
      orig_connect(host, port)
    end

    #
    # Logs in to the remote host. The session must have been previously
    # connected. 
    #
    # If +user+ is nil, Net::Netrc#locate is used to lookup login information
    # based on the host name supplied when the connection was established.
    #
    # If +user+ is the string "anonymous" and the +password+ is nil, a password
    # of user@host is synthesized. If the +acct+ parameter is not nil, an FTP
    # ACCT command is sent following the successful login. Raises an exception
    # on error (typically Net::FTPPermError).
    #
    # Example:
    #
    #   require 'net/ftp-netrc'     # (brings in net/ftp and net/netrc)
    #
    #   ftp = Net::FTP.new('myhost')
    #   ftp.login(nil)
    #   ftp.last_response
    #   => 230 User myuser logged in.
    #
    def login(user = "anonymous", passwd = nil, acct = nil)
      if user.nil?
        rc = Net::Netrc.locate(@host)
        if rc
          user = rc.login
          passwd = rc.password
          acct = rc.account
        else
          user = ''
          passwd = ''
        end
      end
      orig_login(user, passwd, acct)
    end

  end

end
