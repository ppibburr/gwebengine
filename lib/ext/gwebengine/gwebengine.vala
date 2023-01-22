namespace GWebEngine {
  public errordomain PluginError {
	  NOT_SUPPORTED,
	  UNEXPECTED_TYPE,
	  NO_REGISTRATION_FUNCTION,
	  FAILED
  }

  public interface Plugin : Object {
	  public abstract void registered (PluginLoader loader);
	  public abstract void activated(string? data);
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

  public Plugin? load_plugin(string path, string? data, string[] a={}) {
	try {
	  PluginLoader loader = new PluginLoader();
	  Plugin plugin = loader.load(path);

	  plugin.ref();
	  loader.ref();

	  plugin.activated(data);

	  GLib.Timeout.add(0,()=>{
		//ldr.signal_main();
		return false;
	  });

	  return plugin;

	} catch (PluginError e) {
	  print("Error: %s\n", e.message);
	  return null;

	}
  }

  public class Main : Object {
	private bool _qt; // true if QApplication initialized
	public bool qt {  // true if QApplication initialized
	  get {
	    return _qt;
  	  }
	}

	public static Main? _default = null;       // Default instance of the relay
    public static unowned Main get_default() { // Default instance of the relay
		if (_default != null) {
		  return _default;
	    }

	    _default = new Main();
	    _default.ref();
	    return _default;
	}

	public void make_webview(WebView view) {  // Signals python to make a QWebEngineView
		signal_make_webview(view);
	}

	public signal void signal_make_context(Context ctx);
    public signal void signal_make_webview(WebView view); // "signal-" prefix signals are listened by python
    public signal void qt_app() {                         // emitted when QApplication is started
	  this._qt = true;
	  Context.get_default_context();
	}
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
    public bool enable_javascript {get;set; default=true;}
    public bool enable_fullscreen {get;set; default=true;}
    public bool enable_plugins {get;set; default=true;}
    public bool enable_webgl {get;set; default=true;}
    public bool auto_load_images {get;set; default=true;}
    public bool javascript_can_access_clipboard {get;set; default=true;}
    public bool javascript_can_open_windows_automatically {get; set; default=false;}
  }

  public class WebView : Gtk.Socket {
    public string? title {get; set;}
    public bool    can_go_back {get; set;}
    public bool    can_go_forward {get; set;}
    public string? url {get; set;}
    public double  zoom_level {
	  get {
		return signal_get_zoom_level();
	  }
	  set{
		signal_set_zoom_level(value);
	  }
	}

    public double  load_progess {get; set;}
    public bool    is_loading {
	  get {
		return signal_get_is_loading();
	  }
	}

    public string?  favicon {get;set;}

    public WebSettings? settings { get; construct set;}
    public int     winid {construct set; get;}

    construct {
	  this.settings  = new WebSettings();

	  if (Main.get_default().qt) {
		Context.get_default_context();
		Main._default.make_webview(this);
	  } else {
		Main.get_default().qt_app.connect(()=>{
		  Context.get_default_context();
		  GLib.Idle.add(()=>{
		    Main._default.make_webview(this);
		   return false;
		  });
		});
	  }
	}

    public WebView(WebSettings? _settings=new WebSettings()) {
		this.settings = _settings ?? new WebSettings();
	}

	// private
	// Embeds the PyQT::Window into a Gtk::Socket
	public void take(int id) {
		add_id(id);
		this.can_focus = true;
	}

	public void go_back() {
		signal_go_back();
	}

	public void go_forward() {
		signal_go_forward();
	}

	public void reload() {
		signal_reload();
	}

    public void stop() {
		signal_stop();
	}

	public void load_uri(string url) {
		signal_load(url);
	}

	public JSResult run_javascript(string code) {
		return signal_execute(code);
	}

    public void load_html() {
		signal_load_html(url);
	}
	
    //

    public void fullscreen() {
		if (!enter_fullscreen()) {
		  signal_fullscreen();
	    }
	}

    public void unfullscreen() {
		if (!leave_fullscreen()) {
		  signal_unfullscreen();
	    }
	}

	public void key_press(KeyEvent e) {
	  on_key_press(e);
	}

	public void find(string text, out bool foo) {
	  foo = signal_find(text);
	}

	public Gdk.Pixbuf? icon() {
	  return new Gdk.Pixbuf.from_stream(File.new_for_uri(this.favicon).read());
	}

	// Outgoing events
	public signal void signal_go_back();
	public signal void signal_go_forward();
	public signal void signal_reload();
	public signal void signal_stop();	
	public signal void signal_load(string url);
	public signal void signal_load_html(string code);
	public signal JSResult signal_execute(string code);
	public signal void signal_fullscreen();
	public signal void signal_unfullscreen();
	public signal bool signal_find(string text);
	public signal bool signal_get_is_loading();
	public signal double signal_get_zoom_level();
	public signal void   signal_set_zoom_level(double zoom);

	// Incoming events
	public signal void load_changed();
	public signal void ready_to_show();
	public signal void print();	
	public signal bool enter_fullscreen();
	public signal bool leave_fullscreen();
	public signal void close();
	public signal void download_requested(Download item);
	public signal void mouse_target_changed(HitTestResult result);
	// // not implemented yet
	public signal WebView? create();
	public signal void authenticate();		
	public signal void context_menu();
	public signal void resource_load_started();
	public signal void permission_request();
    public signal void run_color_chooser();	  
    public signal void run_file_chooser();	 
	public signal void script_dialog();
	
	// custom
	public signal bool on_key_press(KeyEvent e);
  }

  public class JSResult : Object {
    public signal void ready(string json);
  }

  public class Download : Object {
	public string destination {get; set;}
	private bool _is_cancelled=false;
	public bool is_cancelled {get {
	  return _is_cancelled;
	}}

	public void cancel() {
	  _is_cancelled = true;
	}

	public signal void decide_destination(string suggested_filename);
  }

  public class Context : Object {
	private static Context? _default;
	public static Context? get_default_context() {
		if (_default == null) {
		  _default = new Context();
		}

		return _default;
	}

	public Context() {
	  if (Main.get_default().qt) {
	    Main.get_default().signal_make_context(this);
	  } else {
		Main.get_default().qt_app.connect(()=>{
		  Main.get_default().signal_make_context(this);
		});
	  }
	}

	public signal void download_started(Download item);
  }

  public class HitTestResult : Object {
	public HitTestResultContext context {get; construct set;}
  }

  public class HitTestResultContext : Object {
	public bool is_link {get; construct set;}
	public string? link_uri {get; construct set;}
  }
}
