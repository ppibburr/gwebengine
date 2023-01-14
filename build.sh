#!/usr/bin/env sh

cmd="mkdir -p build && cd build && valac -H ./gwebengine.h ../lib/ext/gwebengine/gwebengine.vala --pkg gmodule-2.0 --pkg gtk+-3.0 -o libgwebengine.so  -X -shared  --shared-library libgwebengine --library GWebEngine-1.0 --gir=GWebEngine-1.0.gir -X -fPIC -X -I./"
echo $cmd
bash -c "$cmd"

cmd="cd build && g-ir-compiler --shared-library=libgwebengine GWebEngine-1.0.gir -o GWebEngine-1.0.typelib"
echo $cmd
bash -c "$cmd"

