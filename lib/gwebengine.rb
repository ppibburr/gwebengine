#
require 'gio2'

$: << File.expand_path(File.dirname(__FILE__))

require 'gwebengine/loader'

ARGV.clear

begin
  if (argv=ENV["GWEBENGINE_ARGV"]) && argv!=''
    ARGV.clear
    GLib::Shell.parse(argv).each do |a|
      ARGV << a
    end
  end
rescue
end

GWebEngine::Loader.new(GWebEngine,[]).load

STDERR.puts "ruby loader loaded."
