public class Plugin : Object, GWebEngine.Plugin {
  private GWebEngine.WebView engine;
  
  public void deactivated () {
    print ("Deactivate");
  }
  
  public void registered (GWebEngine.PluginLoader loader) {
    print ("Loaded\n");
  }

  public void activated(string? data) {
    var w      = new Gtk.Window();
    engine     = new GWebEngine.WebView();

    w.add(engine);
    w.resize(1300,900);
    w.show_all();
    w.present();

    w.delete_event.connect(() => {
      Gtk.main_quit();
      return false;
    });

    string[]? argv;
    GLib.Shell.parse_argv(Environment.get_variable("GWEBENGINE_ARGV"), out argv);

    var url = "https://duckduckgo.com";
    if (argv[0]!=null) {
	  url = argv[0];
	}

    print("load: "+url+"\n");

    engine.settings.enable_fullscreen = true;
    engine.settings.enable_javascript = true;
    engine.settings.enable_webgl      = true;
    engine.settings.enable_plugins    = true;

    engine.on_key_press.connect(key_event);

    engine.ready_to_show.connect(() => {
      engine.load_uri(url);

      var res = engine.run_javascript("a={foo: 5};a");
        res.ready.connect((r, json) => {
        print(json+"\n");
      });
    });

    engine.leave_fullscreen.connect(()=>{
      w.show();
      return false;
    });

    engine.enter_fullscreen.connect(()=>{
      w.hide();
      return false;
    });

    engine.notify["title"].connect(()=>{
      w.title = engine.title;
    });

    engine.notify["favicon"].connect(()=>{
      w.icon = engine.icon();
    });

    Gtk.main();
  }

  public bool key_event(GWebEngine.KeyEvent e) {
    var ctrl       = (e.modifiers & Gdk.ModifierType.CONTROL_MASK);
    var ctrl_shift = (e.modifiers & Gdk.ModifierType.SHIFT_MASK);

    if ((ctrl !=0) && (ctrl_shift != 0)) {
      // Ctrl+Shift+Tab -> go back
      if (e.virtual_key == Gdk.Key.ISO_Left_Tab) {
        engine.go_back();
        return true;
      }
    }

    if (ctrl != 0) {
      // Ctrl+l -> focus location
      if (e.virtual_key == Gdk.Key.l) {
        print("Ctrl-l\n");
        show_location();

        return true;
      }

      // Ctrl+f -> find
      if (e.virtual_key == Gdk.Key.f) {
        show_find();
        return true;
      }

      // Ctrl+Tab -> go forward
      if (e.virtual_key == Gdk.Key.Tab) {
        engine.go_forward();
      }
    }

    return false;
  }

  public bool show_location() {
    var l = new Gtk.Dialog();
    var e = new Gtk.Entry();

    e.text = engine.url;
    
    e.activate.connect(()=>{
	  engine.load_uri(e.text);
	});
    
    l.get_content_area().add(e);
    l.show_all();

    return false;
  }

  public bool show_find() {
    var l = new Gtk.Dialog();
    var h = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
    var e = new Gtk.Entry();
    var b = new Gtk.Button.with_label("Find");

    e.activate.connect(()=>{
	  bool found;
      engine.find(e.text, out found);
    });

    h.pack_start(e, true,true,0);
    h.pack_start(b, false, false, 0);

    l.get_content_area().add(h);
    l.show_all();

    return false;
  }
}

public Type register_plugin (Module module) {
  return typeof (Plugin);
}
