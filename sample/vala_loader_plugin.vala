public class Plugin : GWebEngine.Main, GWebEngine.Plugin {
  public void registered (GWebEngine.PluginLoader loader) {
    print ("Loaded\n");
  }

  public GWebEngine.Main activated(string? data) {
    ready.connect(main);
    return this;
  }

  public bool key_event(GWebEngine.KeyEvent e) {
    var ctrl = (e.modifiers & Gdk.ModifierType.CONTROL_MASK);
    print("Key: "+e.key.to_string()+":"+Gdk.Key.l.to_string()+":"+e.virtual_key.to_string()+"\n");

    if (ctrl != 0) {
      if ((e.virtual_key) == Gdk.Key.l) {
        print("Ctrl-l\n");
        show_location();

        return true;
      }
      if ((e.virtual_key) == Gdk.Key.f) {
        show_find();
        return true;
      }
    }

    return false;
  }

  public bool show_location() {
    var l = new Gtk.Dialog();
    var e = new Gtk.Entry();

    e.text = engine.url
    ;
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
      engine.find(e.text);
    });

    h.pack_start(e, true,true,0);
    h.pack_start(b, false, false, 0);

    l.get_content_area().add(h);
    l.show_all();

    return false;
  }

  public void deactivated () {
    print ("Deactivate");
  }

  private GWebEngine.WebView engine;

  public void main() {
    var w      = new Gtk.Window();
    engine     = make_webview();

    w.add(engine);
    w.resize(1300,900);
    w.show_all();

    w.delete_event.connect(() => {
      main_quit();
      return false;
    });

    string[]? argv;
    GLib.Shell.parse_argv(Environment.get_variable("GWEBENGINE_ARGV"), out argv);

    var url = "https://duckduckgo.com";
    if (argv[0]!=null) {
	  url = argv[0];
	}

    print("load: "+url+"\n");

    engine.settings.fullscreen_enabled = true;
    engine.settings.javascript_enabled = true;
    engine.settings.webgl_enabled      = true;
    engine.settings.plugins_enabled    = true;

    engine.on_key_press.connect(key_event);

    engine.ready.connect(() => {
      engine.load(url);

      engine.notify["url"].connect(()=>{
        print(engine.find("ee").to_string());
      });

      var res = engine.execute("a={foo: 5};a");
        res.ready.connect((r, json) => {
        print(json+"\n");
      });
    });

    engine.signal_fullscreen_request.connect((e,on)=>{
      if (on) {
        w.hide();
      } else {
        w.show_all();
      }

      return true;
    });

    engine.notify["title"].connect(()=>{
      w.title = engine.title;
    });
  }
}

public Type register_plugin (Module module) {
  return typeof (Plugin);
}
