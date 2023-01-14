#!/usr/bin/env sh
/usr/bin/env ruby <<-EOR
puts c="sudo cp librubyplugin.so /usr/lib/*/xfce4/panel/plugins/"
%x[#{c}]
puts c="bin/rxpp.rb -I"
system c
EOR
