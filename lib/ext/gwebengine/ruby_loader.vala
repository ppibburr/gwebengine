// Embeds Ruby -
// Provides GObject based bindings for QtWebEngine for Ruby

extern void load_rb(string pth, string data);


namespace GWebEngineRuby {
  public class RubyLoader : GWebEngine.Main {
	private static RubyLoader _default_loader;

	public static RubyLoader default_loader() {
		return _default_loader;
	}

	public string path {construct set;get;}

    construct {
      print(this.data+"\n");
	  _default_loader=this;
      this.path = this.data;
      load_rb(this.path, "{}");
    }
  }
}
