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

  e.can_focus = true

  w.resize 1300,900
  w.add q
  w.show_all

  e.hide if ARGV.index "--no-location-bar"

  w.signal_connect "delete-event" do
    ldr.main_quit()
  end

  engine.settings.enable_fullscreen = true
  engine.settings.enable_javascript = true
  engine.settings.enable_webgl      = true
  engine.settings.enable_plugins    = true

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
    ctrl_shift = (0 != (event.modifiers & Gdk::ModifierType::SHIFT_MASK.to_i)) rescue nil
    ctrl       = (0 != (event.modifiers & Gdk::ModifierType::CONTROL_MASK.to_i)) rescue nil

    if (!ctrl_shift) && (ctrl)
      if (event.virtual_key == Gdk::Keyval::KEY_l)
        e.grab_focus

        next true
      end

      if (event.virtual_key == Gdk::Keyval::KEY_f)
        if !@find
          @find = Gtk::Window.new
          @find.title = "find..."
          @find.add q=Gtk::Entry.new

          q.signal_connect "activate" do
            engine.find(q.text);
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

      if event.virtual_key == Gdk::Keyval::KEY_Tab
        engine.go_forward
        next true
      end

    elsif ctrl
      if event.virtual_key == Gdk::Keyval::KEY_ISO_Left_Tab.to_i
        engine.go_back
        next true
      end
    end

    false
  end

  engine.signal_connect "ready-to-show" do
    engine.load_uri(ARGV[0]||"https://duckduckgo.com")

    result = engine.run_javascript "a={foo: 5};a"

    result.signal_connect "ready" do |r, json|
      puts json
    end
  end

  engine.signal_connect("notify::url") do
    e.text = engine.url
  end

  engine.signal_connect("notify::favicon") do
    w.icon = engine.icon
  end
end



