// Embeds Ruby -
// Provides GObject based bindings for QtWebEngine for Ruby

extern void load_rb(string pth, string data);

public class Plugin : Object, GWebEngine.Plugin {
  public void registered (GWebEngine.PluginLoader loader) {
      print("Ruby Plugin Loaded...\n");
  }

  public void activated(string? data) {
      load_rb(data,"{}");
  }

  public void deactivated() {
	  
  }
}

public Type register_plugin (Module module) {
  return typeof (Plugin);
}
