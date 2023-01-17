# gwebengine
QtWebEngine for GObject.

Python with Qt5 loads GIR of GObject binding library
Program loads GModule plugin libraries

Provides Out of the Box support for Ruby.

Wrote in Vala, Ruby, C, and Python

# Build GObject bindings and plugin loader
`bash build.sh`

# Build Ruby loader
`bash build_ruby.sh`

# Build sample vala plugin
`cd sample && bash build_vala.sh`

# Usage (The ruby wrapper)
```
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
```

# Usage (The Python program)
`./bin/gwebengine.py PATH_TO_LIB PATH_TO_PLUGIN [DATA]`
