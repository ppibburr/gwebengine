begin
  require 'gwebengine'
rescue LoadError
  $: << File.join(File.expand_path(File.dirname(__FILE__)), "..", "lib")
  begin
    require 'gwebengine'
  rescue =>  e
    raise e
  end
end

require 'gtk3'

ldr = GWebEngineRuby::RubyLoader.default_loader

ldr.signal_connect "ready" do
  w       = Gtk::Window.new
  w.title = "gtk webengine"

  q = Gtk::Box.new(:vertical)
  q.pack_start e      = Gtk::Entry.new() ,expand: false,fill: true,padding: 0
  q.pack_start engine = ldr.make_webview(), expand: true, fill: true, padding: 0

  e.signal_connect "activate" do
    engine.load_uri e.text
  end

  w.resize 1300,900
  w.add q
  w.show_all

  w.signal_connect "delete-event" do
    ldr.main_quit()
  end

  engine.settings.fullscreen_enabled = true
  engine.settings.javascript_enabled = true
  engine.settings.webgl_enabled      = true
  engine.settings.plugins_enabled    = true

  engine.signal_connect "notify::title" do
    w.title = engine.title
  end

  engine.signal_connect "enter-fullscreen" do
    w.hide
    false
  end

  engine.signal_connect "leave-fullscreen" do
    w.show
    false
  end

  engine.signal_connect("on-key-press") do |eng, event|
    ctrl = (event.modifiers & Gdk::ModifierType::CONTROL_MASK.to_i) rescue nil
    if ctrl && (event.virtual_key == Gdk::Keyval::KEY_l)
      e.grab_focus
      engine.can_focus = false
      next true
    end
    
    if ctrl && (event.virtual_key == Gdk::Keyval::KEY_f)
      if !@find
        @find = Gtk::Window.new
        @find.title = "find..."
        @find.add q=Gtk::Entry.new
        q.signal_connect "activate" do
          p engine.find(q.text);
        end
        
        @find.signal_connect "delete-event" do
          @find = nil
        end
      end
      
      @find.children[0].text=''
      @find.show_all
      @find.present
      
      next true
    end

    false
  end

  engine.signal_connect "ready-to-show" do
    engine.load_uri(ARGV[0]||"https://duckduckgo.com")
    engine.grab_focus

    result = engine.run_javascript "a={foo: 5};a"

    result.signal_connect "ready" do |r, json|
      puts json
    end
  end

  engine.signal_connect("notify::url") do
    e.text = engine.url
  end
end



