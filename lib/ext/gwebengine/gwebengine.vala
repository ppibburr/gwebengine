namespace GWebEngine {
  public errordomain PluginError {
	  NOT_SUPPORTED,
	  UNEXPECTED_TYPE,
	  NO_REGISTRATION_FUNCTION,
	  FAILED
  }

  public interface Plugin : Object {
	  public abstract void registered (PluginLoader loader);
	  public abstract Main activated(string? data);
	  public abstract void deactivated ();
  }

  private class PluginInfo : Object {
	  public Module module;
	  public Type gtype;

	  public PluginInfo (Type type, owned Module module) {
		  this.module = (owned) module;
		  this.gtype = type;
	  }
  }

  public class PluginLoader : Object {
	  [CCode (has_target = false)]
	  private delegate Type RegisterPluginFunction (Module module);

	  private Plugin[] plugins = new Plugin[0];
	  private PluginInfo[] infos = new PluginInfo[0];

	  public Plugin load (string path) throws PluginError {
		  if (Module.supported () == false) {
			  throw new PluginError.NOT_SUPPORTED ("Plugins are not supported");
		  }

		  Module module = Module.open (path, ModuleFlags.BIND_LAZY);
		  if (module == null) {
			  throw new PluginError.FAILED (Module.error ());
		  }

		  void* function;
		  module.symbol ("register_plugin", out function);
		  if (function == null) {
			  throw new PluginError.NO_REGISTRATION_FUNCTION ("register_plugin () not found");
		  }

		  RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
		  Type type = register_plugin (module);
		  if (type.is_a (typeof (Plugin)) == false) {
			  throw new PluginError.UNEXPECTED_TYPE ("Unexpected type");
		  }

		  PluginInfo info = new PluginInfo (type, (owned) module);
		  infos += info;

		  Plugin plugin = (Plugin) Object.new (type);
		  plugins += plugin;
		  plugin.registered (this);

		  return plugin;
	  }
  }

  public Main? load_plugin(string path, string? data, string[] a={}) {
	try {
	  PluginLoader loader = new PluginLoader();
	  Plugin plugin = loader.load(path);

	  plugin.ref();
	  loader.ref();

	  var ldr=plugin.activated(data);

	  GLib.Timeout.add(300,()=>{
		ldr.signal_main();
		return false;
	  });

	  return ldr;

	} catch (PluginError e) {
	  print("Error: %s\n", e.message);
	  return null;

	}
  }

  public class Main : Object {
    public string? data {construct set; get;}

	public WebView make_webview() {
		return signal_make_webview();
	}

	public void main_quit() {
		signal_main_quit();
	}

	public void iterate() {
		Gtk.main_iteration_do(false);
	}

	// @private
	// invokes the `ready` signal
	public void init() {
      ready();
	}


    public signal WebView signal_make_webview();
    public signal void signal_main_quit();
    public signal void signal_main();

	//
	public signal void ready();
  }

  public class Event : Object {

  }

  public class KeyEvent : Event {
	public string? text {get; construct set;}
	public int modifiers {get; construct set;}
	public int key {get; construct set;}
	public int scan_code {get; construct set;}
	public int virtual_key {get; construct set;}
  }

  public class WebSettings : Object {
    public bool javascript_enabled {get;set;}
    public bool fullscreen_enabled {get;set;}
    public bool plugins_enabled {get;set;}
    public bool webgl_enabled {get;set;}
  }

  public class WebView : Gtk.Socket {
    public string? title {get; set;}
    public bool    can_go_back {get; set;}
    public bool    can_go_forward {get; set;}
    public string? url {get; set;}
    public int     winid {construct set; get;}
    public WebSettings? settings { get; construct set;}

    construct {
	  this.settings  = new WebSettings();

	}

    public WebView(int id, WebSettings _settings=new WebSettings()) {
		this.winid=id;
		this.settings = _settings;
	}

	// private
	// Embeds the PyQT::Window into a Gtk::Socket
	public void take() {
		add_id( this.winid);
		this.can_focus = true;
	}

	public void back() {
		signal_go_back();
	}

	public void forward() {
		signal_go_forward();
	}

	public void reload() {
		signal_reload();
	}

	public JSResult execute(string code) {
		return signal_execute(code);
	}

	public void load(string url) {
		signal_load(url);
	}

	public bool fullscreen_request(bool toggle_on) {
		return signal_fullscreen_request(toggle_on);
	}

    public void fullscreen() {
		if (fullscreen_request(true)) {
		  signal_fullscreen();
	    }
	}

    public void unfullscreen() {
		if (fullscreen_request(false)) {
		  signal_unfullscreen();
	    }
	}

	public void key_press(KeyEvent e) {
	  on_key_press(e);
	}

	public bool find(string text) {
	  return signal_find(text);
	}

	// Outgoing events
	public signal void signal_go_back();
	public signal void signal_go_forward();
	public signal void signal_reload();
	public signal void signal_load(string url);
	public signal JSResult signal_execute(string code);
	public signal bool signal_fullscreen_request(bool toggle_on);
	public signal void signal_fullscreen();
	public signal void signal_unfullscreen();
	public signal bool signal_find(string text);

	// Incoming events
	public signal bool on_key_press(KeyEvent e);
	public signal void ready();
  }

  public class JSResult : Object {
    public signal void ready(string json);
  }
}
