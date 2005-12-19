# = net/netrc.rb - ftp(1) .netrc parsing
#
# Copyright (c) 2005 Robert J. Showalter
#
# This library is distributed under the terms of the Ruby license.
# You may freely distribute or modify this library.
#
# See Net::Netrc for usage.
#
# $Id$

require 'etc'

module Net

  # Net::Netrc provides an interface to the ftp(1) .netrc file containing login
  # information for FTP (or other) servers.
  #
  # == Example Usage
  #
  #   require 'net/netrc'
  #
  #   rc = Net::Netrc.locate('ftp.example.com') or
  #     raise ".netrc missing or no entry found"
  #   puts rc.login
  #   puts rc.password
  #   puts rc.name
  #
  # == The .netrc File
  #
  # The .netrc file is a plain text file containing login information.  It is
  # typically located in the user's home directory. (See #rcname for specific
  # details on how the .netrc file is located.)
  #
  # On Unix platforms, the .netrc must be owned by the process' effective
  # user id and must not be group- or world-writable, or a SecurityError
  # will be raised.
  #
  # The .netrc file contains whitespace-separated tokens. Tokens containing
  # whitespace must be enclosed in double quotes. The following tokens are
  # recognized:
  #
  # [machine _name_]
  #   Identifies a remote machine name. #locate searches sequentially for
  #   a matching +machine+ token. Once a match is found, subsequent tokens
  #   are processed until either EOF is reached or another +machine+
  #   (or +default+) token is parsed.
  #
  # [login _name_]
  #   Identifies remote user name.
  #
  # [password _string_]
  #   Supplies remote password.
  #   
  # [account _string_]
  #   Supplies an additional account password.
  #
  # [macdef _name_]
  #   Begins a macro definition, which ends with the next blank line
  #   encountered. Ignored by Net::Netrc.
  #
  # [default]
  #   Defines default account information. The login information here
  #   will be returned if a matching +machine+ token is not found
  #   during parsing. If supplied, +default+ must appear after any
  #   +machine+ entries.
  #
  # == Sample .netrc file
  #
  # The following is an example of a .netrc file:
  #
  #   machine host1.austin.century.com 
  #     login fred 
  #     password bluebonnet
  #
  #   default login john password ranger
  #

  class Netrc

    VERSION_MAJOR = 0
    VERSION_MINOR = 1
    VERSION_PATCH = 0
    VERSION = "#{VERSION_MAJOR}.#{VERSION_MINOR}.#{VERSION_PATCH}"

    # detect whether running on MS Windows platform
    # use Matt Mower's Platform module if available
    # (//http://rubyforge.org/projects/platform/)
    begin
      require 'platform'
      IS_WIN32 = Platform::OS == :win32
    rescue LoadError
      IS_WIN32 = RUBY_PLATFORM =~ /mswin|mingw|bccwin|wince/i
    end

    # machine name, or nil if default entry
    attr_accessor :machine

    # login name (nil if none)
    attr_accessor :login

    # password (nil if none)
    attr_accessor :password

    # account name (nil if none)
    attr_accessor :account

    # Returns name of .netrc file
    #
    # If the environment variable <tt>NETRC</tt> is set, it is used
    # as the name of the .netrc file. Otherwise, a search
    # is made for <tt>.netrc</tt> (and <tt>_netrc</tt> on Windows) in the
    # following locations. The first existing file found
    # will be returned.
    #
    # - User's home directory as returned by <tt>Etc.getpwuid</tt>
    # - <tt>ENV['HOME']</tt> directory
    #
    # On Windows platforms, the following additional locations
    # are checked:
    # - <tt>ENV['USERPROFILE']</tt>
    # - <tt>ENV['HOMEPATH']</tt>
    # - <tt>ENV['HOMEDRIVE'] + ENV['HOMEDIR']</tt>
    def Netrc.rcname

      # use file indicated by NETRC environment variable if defined
      return ENV['NETRC'] if ENV['NETRC']

      dirs = []
      files = ['.netrc']

      # build candidate list of directories to check
      pw = Etc.getpwuid
      dirs << pw.dir if pw
      dirs << ENV['HOME']
      if IS_WIN32
        dirs << ENV['USERPROFILE']
        dirs << ENV['HOMESHARE']
        dirs << ENV['HOMEDRIVE'] + ENV['HOMEPATH'] || '' if ENV['HOMEDRIVE']
        files << '_netrc'
      end

      # return first found file
      dirs.flatten.each do |dir|
        files.each do |file|
          name = File.join(dir, file)
          return name if File.exist?(name)
        end
      end

      # nothing found
      nil
    end

    # opens .netrc file, returning File object if successful.
    # +name+ is the name of the .netrc file to open. If omitted,
    # #rcname is used to locate the file.
    #
    # returns nil if the file does not exist.
    #
    # On non-Windows platforms, raises SecurityError if the file
    # is not owned by the current user or if it is readable or 
    # writable by other than the current user.
    def Netrc.rcopen(name = nil)
      name ||= rcname or return nil
      return nil unless File.exist?(name)
      unless IS_WIN32
        s = File.stat(name)
        raise SecurityError, "Not owner: #{name}" unless s.owned?
        raise SecurityError, "Bad permissions: #{name}" if s.mode & 077 != 0
      end
      File.open(name, 'r')
    end

    # given a machine name, returns a Net::Netrc object containing
    # the matching entry for that name, or the default entry. If
    # no match is found and no default entry exists, nil is returned.
    #
    # The returned object's #machine, #login, #password, and #account
    # attributes will be set to the corresponding values from the .netrc file
    # entry.  #machine will be nil if the +default+ .netrc entry was used. The
    # other attributes will be nil if the corresponding token in the .netrc
    # file was not present.
    #
    # +io+ is a previously-opened IO object. If not supplied,
    # #rcopen is called to locate and open the .netrc file. +io+
    # will be closed when this method returns.
    def Netrc.locate(mach, io = nil)
      need_close = false
      if io.nil?
        io = rcopen or return nil
        need_close = true
      end
      entry = nil
      key = nil
      inmacdef = false
      begin
        while line = io.gets
          if inmacdef
            inmacdef = false if line.strip.empty?
            next
          end
          toks = line.scan(/"((?:\\.|[^"])*)"|((?:\\.|\S)+)/).flatten.compact
          toks.each { |t| t.gsub!(/\\(.)/, '\1') }
          while toks.length > 0
            tok = toks.shift
            if key
              entry = new if key == 'machine' && tok == mach
              entry.send "#{key}=", tok if entry
              key = nil
            end
            case tok
            when 'default'
              return entry if entry
              entry = new
            when 'machine'
              return entry if entry
              key = 'machine'
            when 'login', 'password', 'account'
              key = tok
            when 'macdef'
              inmacdef = true
              break
            end
          end
        end
      ensure
        io.close if need_close
      end
      entry
    end

  end

end
