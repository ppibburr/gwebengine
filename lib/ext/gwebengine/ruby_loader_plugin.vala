public class Plugin : Object, GWebEngine.Plugin {
  public void registered (GWebEngine.PluginLoader loader) {
      print ("Loaded\n");
  }

  public GWebEngine.Main activated(string? data) {
      print ("Activate\n");
      var loader =(GWebEngine.Main) Object.new(typeof(GWebEngineRuby.RubyLoader), data: data);
      return loader;
  }

  public void deactivated () {
      print ("Deactivate");
  }
}

public Type register_plugin (Module module) {
  return typeof (Plugin);
}
