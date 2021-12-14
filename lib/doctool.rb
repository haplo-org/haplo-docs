# Haplo Platform                                     http://haplo.org
# (c) Haplo Services Ltd 2006 - 2021    http://www.haplo-services.com
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


require 'rubygems'
require 'fileutils'

gem 'json'
require 'json/ext'

require './lib/images'
require './lib/doc_node'
require './lib/documentation'
require './lib/documentation_html'
require './lib/doc_server'

if ARGV[0] == 'publish'
  olddir = FileUtils.pwd
  FileUtils.chdir(ENV['HAPLO_ROOT'])
  haplo_revision = `git rev-parse --verify --short HEAD`.strip
  FileUtils.chdir(olddir)
  git_revision = `git rev-parse --verify --short HEAD`.strip
  git_timestamp = `git log -1 --format=%ct`.strip.to_i
  commit_time = Time.at(git_timestamp).strftime("%Y%m%d-%H%M")
  SOURCE_CONTROL_DATE = Time.at(git_timestamp).strftime("%d %b %Y")
  PACKAGING_VERSION = "#{commit_time}-#{haplo_revision}-#{git_revision}"
  UPDATED_MESSAGE = "Revision: #{git_revision} | Last Updated: #{SOURCE_CONTROL_DATE}"
  puts "Docs revision: #{git_revision}"
else
  UPDATED_MESSAGE = 'CHECKOUT'
end

DOCS_ROOT = 'root'
PUBLISH_DIR = 'docs.haplo.org'
SITE_URL_BASE = 'https://docs.haplo.org'

# Load all the documentation
puts "Loading all files..."
# Ruby files go first
Dir.glob("./#{DOCS_ROOT}/**/*.rb").each do |ruby_file|
  require ruby_file
  STDOUT.write('.'); STDOUT.flush
end
# Then all the nodes
Dir.glob("#{DOCS_ROOT}/**/*").each do |filename|
  if File.file?(filename) && filename !~ /\.rb\z/
    Documentation.read_file_auto(filename, DOCS_ROOT)
    STDOUT.write('.'); STDOUT.flush
  end
end
puts

# Template for generating web pages
Documentation.load_html_template

# Actions post-load
Documentation.call_after_loads

# Perform the requested action
case ARGV[0]
when 'server', nil
  DocServer.run

when 'check'
  puts "Checking all documentation nodes..."
  Documentation.check_all
  puts

when 'publish'
  # Check there's nothing in the queue
  if !(system "onedeploy check-queue-empty")
    puts "onedeploy queue is not empty"
    exit 1
  end
  if File.directory?(PUBLISH_DIR)
    puts "Removing old files..."
    FileUtils.rm_rf PUBLISH_DIR
  end
  FileUtils.mkdir(PUBLISH_DIR)
  puts "Copying static files..."
  Dir.glob("web/static/**/*").each do |filename|
    unless filename.include?('/.')
      target = PUBLISH_DIR + filename.sub('web/static','')
      if File.file?(filename)
        FileUtils.cp(filename, target)
      else
        FileUtils.mkdir(target, :mode => 0755)
      end
    end
  end
  FileUtils.cp_r('images', PUBLISH_DIR)
  FileUtils.chmod_R(0755, "#{PUBLISH_DIR}/images")
  puts "Writing files..."
  Documentation.publish_to(PUBLISH_DIR)
  puts "Compress files..."
  counter = 0
  Dir.glob("#{PUBLISH_DIR}/**/*.{html,css,js,txt,xml,atom,rss,ttf,woff,eot}").each do |filename|
    system "cd #{File.dirname(filename)} ; cat #{File.basename(filename)} | gzip -9 > #{File.basename(filename)}.gz"
    counter += 1
    STDOUT.write('.'); STDOUT.flush
  end
  puts; puts "#{counter} files compressed"
  puts "Queue archive..."
  queued_result = `onedeploy --archive-root=#{PUBLISH_DIR} --archive-name=webroot-docs --archive-comment="docs.haplo.org #{PACKAGING_VERSION}" queue-archive .`
  queued_archive = JSON.parse(queued_result)
  puts "Queue manifest..."
  manifest = {
    "name" => "website-docs",
    "version" => PACKAGING_VERSION,
    "description" => "Developer documentation web site",
    "install_path" => "/oneis/sites/docs.haplo.org",
    "archives" => [queued_archive["archive"]],
  }
  File.open("#{PUBLISH_DIR}/manifest.json", "w") { |f| f.write JSON.pretty_generate(manifest) }
  if !(system "onedeploy queue-manifest #{PUBLISH_DIR}/manifest.json latest")
    puts "Failed to queue manifest"
    exit 1
  end
  puts "Cleaning up..."
  FileUtils.rm_rf PUBLISH_DIR
  puts "Done."
  puts "Run 'onedeploy queue-commit' to update repository."

else
  raise "Unknown command #{ARGV[0]}"
end
