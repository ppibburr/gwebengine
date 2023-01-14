#!/usr/bin/env sh

/usr/bin/env ruby <<-EOR
puts cmd="mkdir -p build && cd build && valac --vapidir=../../build --vapidir=./ -H ./gwebenginevalaplugin.h ../vala_loader_plugin.vala --pkg GWebEngine-1.0 --pkg gmodule-2.0 --pkg gtk+-3.0 -o libgwebenginevalaplugin.so  -X -shared  --shared-library libgwebenginevalaplugin --library GWebEngineValaPlugin-1.0 -X -fPIC -X -I../../build -X -I./"
system cmd

EOR
