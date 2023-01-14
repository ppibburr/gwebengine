#!/usr/bin/env sh

/usr/bin/env ruby <<-EOR
rbflgs = %x[pkg-config --cflags --libs ruby].strip.split(" ").join(" -X ")

puts cmd="mkdir -p build && cd build && valac --vapidir=./ -H ./gwebengineruby.h ../lib/ext/gwebengine/ruby_loader.vala --pkg GWebEngine-1.0 --pkg gmodule-2.0 --pkg gtk+-3.0 -o libgwebengineruby.so  -X -shared  --shared-library libgwebengineruby --library GWebEngineRuby-1.0 --gir=GWebEngineRuby-1.0.gir -X -fPIC -X ../lib/ext/gwebengine/rbld.c -X #{rbflgs} -X -I./"
system cmd

puts cmd="mkdir -p build && cd build && valac --vapidir=./ -H ./gwebenginerubyplugin.h ../lib/ext/gwebengine/ruby_loader_plugin.vala --pkg GWebEngine-1.0 --pkg GWebEngineRuby-1.0 --pkg gmodule-2.0 --pkg gtk+-3.0 -o libgwebenginerubyplugin.so  -X -shared  --shared-library libgwebenginerubyplugin --library GWebEngineRubyPlugin-1.0 -X -fPIC -X ../lib/ext/gwebengine/rbld.c -X #{rbflgs} -X -I./ -X -L./libgwebengineruby -X libgwebengineruby.so"
system cmd

puts cmd="cd build && g-ir-compiler --includedir=./ --shared-library=libgwebengineruby GWebEngineRuby-1.0.gir -o GWebEngineRuby-1.0.typelib"
system cmd
EOR
