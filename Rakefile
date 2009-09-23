# Net::Netrc Rakefile
# major inspiration from Jamis Buck's Net::SSH Rakefile (thanks!)

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/contrib/sshpublisher'

require './lib/net/netrc'

PACKAGE_NAME = "net-netrc"
PACKAGE_VERSION = Net::Netrc::VERSION

SOURCE_FILES = FileList.new do |fl|
  [ "lib", "test" ].each do |dir|
    fl.include "#{dir}/**/*"
  end
  fl.include "Rakefile"
  fl.exclude( /\b.svn\b/ )
end

PACKAGE_FILES = FileList.new do |fl|
  fl.include "ChangeLog", "NEWS", "LICENSE", "TODO", "#{PACKAGE_NAME}.gemspec"
  fl.include "README", "setup.rb"
  fl.include SOURCE_FILES
  fl.exclude( /\b.svn\b/ )
end

def can_require( file )
  begin
    require file
    return true
  rescue LoadError
    return false
  end
end

desc "Default task"
task :default => [ :test ]

task :rdoc => SOURCE_FILES

desc "Clean generated files"
task :clean do
  rm_rf "pkg"
  rm_rf "doc"
  rm_f  "ChangeLog"
end

desc "Generate the changelog using git2cl"
task :changelog => "ChangeLog"

file "ChangeLog" do
  unless system "./git2cl >ChangeLog"
    warn "could not generate ChangeLog (git2cl missing?)"
  end
end

Rake::TestTask.new do |t|
  t.test_files = [ "test/test_netrc.rb" ]
  t.verbose = true
end

desc "Prepackage warnings and reminders"
task :prepackage do
  unless ENV["OK"] == "yes"
    vers = "#{Net::Netrc::VERSION_MAJOR}.#{Net::Netrc::VERSION_MINOR}.#{Net::Netrc::VERSION_PATCH}"
    puts "========================================================="
    puts "Please check that the following files have been updated"
    puts "in preparation for this release:"
    puts
    puts "  NEWS (with latest release notes)"
    puts "  lib/net/netrc.rb (with current version number)"
    puts "  rake pubrdoc"
    puts
    puts "  git tag -a #{vers} -m 'Version #{vers}'"
    puts
    puts "If you are sure these have all been taken care of, re-run"
    puts "rake with 'OK=yes'."
    puts "========================================================="
    puts
    abort
  end
end

package_name = "#{PACKAGE_NAME}-#{PACKAGE_VERSION}"
package_dir = "pkg"
package_dir_path = "#{package_dir}/#{package_name}"

gz_file = "#{package_name}.tar.gz"
bz2_file = "#{package_name}.tar.bz2"
zip_file = "#{package_name}.zip"
gem_file = "#{package_name}.gem"

task :gzip => SOURCE_FILES + [ :changelog, :rdoc, "#{package_dir}/#{gz_file}" ]
task :bzip => SOURCE_FILES + [ :changelog, :rdoc, "#{package_dir}/#{bz2_file}" ]
task :zip  => SOURCE_FILES + [ :changelog, :rdoc, "#{package_dir}/#{zip_file}" ]
task :gem  => SOURCE_FILES + [ :changelog, "#{package_dir}/#{gem_file}" ]

desc "Build all packages"
task :package => [ :test, :prepackage, :gzip, :bzip, :zip, :gem ]

directory package_dir

file package_dir_path do
  mkdir_p package_dir_path rescue nil
  PACKAGE_FILES.each do |fn|
    f = File.join( package_dir_path, fn )
    if File.directory?( fn )
      mkdir_p f unless File.exist?( f )
    else
      dir = File.dirname( f )
      mkdir_p dir unless File.exist?( dir )
      rm_f f
      safe_ln fn, f
    end
  end
end

file "#{package_dir}/#{zip_file}" => package_dir_path do
  rm_f "#{package_dir}/#{zip_file}"
  chdir package_dir do
    sh %{zip -r #{zip_file} #{package_name}}
  end
end

file "#{package_dir}/#{gz_file}" => package_dir_path do
  rm_f "#{package_dir}/#{gz_file}"
  chdir package_dir do
    sh %{tar czvf #{gz_file} #{package_name}}
  end
end

file "#{package_dir}/#{bz2_file}" => package_dir_path do
  rm_f "#{package_dir}/#{bz2_file}"
  chdir package_dir do
    sh %{tar cjvf #{bz2_file} #{package_name}}
  end
end

file "#{package_dir}/#{gem_file}" => package_dir do
  spec = eval(File.read(PACKAGE_NAME+".gemspec"))
  Gem::Builder.new(spec).build
  mv gem_file, "#{package_dir}/#{gem_file}"
end

rdoc_dir = "doc"

desc "Build the RDoc documentation"
Rake::RDocTask.new( :rdoc ) do |rdoc|
  rdoc.rdoc_dir = rdoc_dir
  rdoc.title    = "Net::Netrc -- ftp(1)-style .netrc parsing"
  rdoc.options << '--inline-source'
  rdoc.options << '--main'
  rdoc.options << 'README'
  rdoc.rdoc_files.include 'README'
  rdoc.rdoc_files.include 'lib/**/*.rb'
end

desc "Publish the RDoc documentation"
task :pubrdoc => [ :rdoc ] do
  Rake::SshDirPublisher.new(
    "bshow@rubyforge.org",
    "/var/www/gforge-projects/net-netrc",
    "doc" ).upload
end
