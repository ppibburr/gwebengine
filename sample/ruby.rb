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
    engine.load e.text
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

  engine.signal_connect "signal-fullscreen-request" do |e,on|
    on ? w.hide : w.show_all
    true
  end

  engine.signal_connect("on-key-press") do |eng, event|
    ctrl = (event.modifiers & Gdk::ModifierType::CONTROL_MASK.to_i) rescue nil
    if ctrl && (event.virtual_key == Gdk::Keyval::KEY_l)
      e.grab_focus
      engine.can_focus = false
    end

    false
  end

  engine.signal_connect "ready" do
    engine.load(ARGV[0]||"https://duckduckgo.com")
    engine.grab_focus

    result = engine.execute "a={foo: 5};a"

    result.signal_connect "ready" do |r, json|
      puts json
    end
  end

  engine.signal_connect("notify::url") do
    e.text = engine.url
  end
end



