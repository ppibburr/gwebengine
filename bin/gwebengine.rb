#!/usr/bin/env ruby

lib_dir = File.expand_path(File.join(File.dirname(__FILE__),"..","build"))
loader  = File.join(lib_dir,"libgwebenginerubyplugin.so")

ENV["QTWEBENGINE_CHROMIUM_FLAGS"] = "--force-dark-mode --enable-force-dark --blink-settings='darkMode=4,darkModeImagePolicy=2,darkModeEnabled=true'"

def help
  puts """
./gwebengine.rb - QtWebEngine GObject bindings loader shim

SYNOPSIS:
  Loads Ruby scripts or C/Vala plugins.

EXAMPLES:
  ruby: ARGV is available
    ./gwebengine.rb PATH [arg, ...]

  other: ARGV will be in GWEBENGINE_ARGV environment variable (`g_shell_parse_argv` can parse this)
    ./gwebengine.rb -c PLUGIN_PATH [arg, ..]

OPTIONS:
  -c PLUGIN_PATH     the plugin to load non ruby programs
  """

  exit()
end

if (ARGV.length == 0) || ARGV.index("-h") || ARGV.index("--help")
  help
end


if !ARGV.delete("-c")
  case ARGV.length
  when 1
    ENV["GWEBENGINE_ARGV"]=""
  else
    path  = ARGV.shift
    ENV["GWEBENGINE_ARGV"] = ARGV.map do |a| "\"#{a}\"" end.join(" ")
    ARGV.clear
    ARGV << path
  end
else
  loader = File.expand_path(ARGV.shift)

  if !File.exist?(loader)
    q = File.join(File.dirname(__FILE__),"..",'sample', 'build',File.basename(loader))
    loader = File.exist?(q) ? q : loader
  end

  loader = "lib"+File.basename(loader)+".so" unless (loader =~ /lib|\.so/)

  if !File.exist?(loader)
    q = File.join("./",loader)
    loader = File.exist?(q) ? q : loader

    if !File.exist?(loader)
      q = File.join(File.dirname(__FILE__),"..",'sample', 'build',loader)
      loader = File.exist?(q) ? q : loader
    end
  end

  ENV["GWEBENGINE_ARGV"] = ARGV.map do |a| "\"#{a}\"" end.join(" ")
  ARGV.clear
  ARGV << ""
end

ARGV.unshift loader
ARGV.unshift lib_dir

ld=ENV['LD_LIBRARY_PATH']
ENV["GWEB_LIB_DIR"] = lib_dir
ENV["LD_LIBRARY_PATH"]="#{ld}:#{lib_dir}"

Process.spawn File.join(File.dirname(__FILE__),"/gwebengine.py"), *ARGV

