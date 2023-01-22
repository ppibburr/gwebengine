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

class BrowserWindow < Gtk::Window
  type_register

  attr_reader :webview, :location
  def initialize uri="https://duckduckgo.com", main: false
    super()

    v = Gtk::Box.new :vertical

    @location               = Gtk::Entry.new
    location.can_focus      = true
    location.focus_on_click = true

    location.hide if ARGV.index "--no-location-bar"

    v.pack_start location, expand: false, fill: true, padding: 0

    location.signal_connect "activate" do
      webview.load_uri location.text
    end

    @webview               = WebView.new

    overlay = Gtk::Overlay.new

    overlay.add webview
    overlay.add_overlay view_message=Gtk::Label.new
    view_message.halign = Gtk::Align::START
    view_message.valign = Gtk::Align::END

    v.pack_start overlay, expand: true, fill: true, padding: 0

    webview.show

    resize 1300,900
    add v
    show_all

    signal_connect "delete-event" do
      Gtk.main_quit()
    end if main


    webview.signal_connect "notify::title" do
      self.title = webview.title
    end

    webview.signal_connect "enter-fullscreen" do
      hide
      false
    end

    webview.signal_connect "leave-fullscreen" do
      show
      false
    end

    webview.signal_connect "ready-to-show" do
      webview.load_uri(uri) if uri
      present

      result = webview.run_javascript "a={foo: 5};a"

      result.signal_connect "ready" do |r, json|
        puts json
      end
    end

    webview.signal_connect("notify::url") do
      location.text = webview.url
    end

    webview.signal_connect("notify::favicon") do
      self.icon = webview.icon
    end

    webview.signal_connect "mouse-target-changed" do |wv,ht|
      if ht.context.link?
        if (uri = ht.context.link_uri) != ""
          GLib::Source.remove @source if @source
          view_message.text=uri
          view_message.show
          @source = GLib::Timeout.add 1000 do
            @source = nil
            view_message.hide
            false
          end
        else
          view_message.hide
        end
      end
    end

    webview.signal_connect("on-key-press") do |eng, event|
      ctrl_shift = (0 != (event.modifiers & Gdk::ModifierType::SHIFT_MASK.to_i)) rescue nil
      ctrl       = (0 != (event.modifiers & Gdk::ModifierType::CONTROL_MASK.to_i)) rescue nil

      if (!ctrl_shift) && (ctrl)
        if (event.virtual_key == Gdk::Keyval::KEY_l)
          location.grab_focus

          next true
        end
      end
    end
  end
end

class WebView < GWebEngine::WebView
  type_register

  def initialize
    super

    self.focus_on_click = true
    self.can_focus      = true

    self.grab_focus

    settings.javascript_can_open_windows_automatically = false

    signal_connect "create" do
      make_window(main: false).webview
    end

    signal_connect("on-key-press") do |eng, event|
      ctrl_shift = (0 != (event.modifiers & Gdk::ModifierType::SHIFT_MASK.to_i)) rescue nil
      ctrl       = (0 != (event.modifiers & Gdk::ModifierType::CONTROL_MASK.to_i)) rescue nil

      if (!ctrl_shift) && (ctrl)
        if (event.virtual_key == Gdk::Keyval::KEY_f)
          if !@find_dlg
            @find_dlg = Gtk::Window.new
            @find_dlg.title = "find..."
            @find_dlg.add q=Gtk::Entry.new

            q.signal_connect "activate" do
              find(q.text);
            end

            @find_dlg.signal_connect "delete-event" do
              @find_dlg = nil
            end
          end

          @find_dlg.children[0].text=''
          @find_dlg.show_all
          @find_dlg.present

          next true
        end

        if event.virtual_key == Gdk::Keyval::KEY_Tab
          go_forward
          next true
        end

      elsif ctrl
        if event.virtual_key == Gdk::Keyval::KEY_ISO_Left_Tab.to_i
          go_back
          next true
        end
      end

      false
    end
  end
end

def make_window(uri=nil, main: true)
  BrowserWindow.new(uri, main: main)
end

begin
  GWebEngine::Context.default_context().signal_connect "download-started" do |_, item|
    item.signal_connect "decide-destination" do |_, filename|
      dlg = Gtk::FileChooserDialog.new(:title  => "Save As", :action => :save,
                                      :buttons => [[Gtk::Stock::SAVE, :accept], [Gtk::Stock::CANCEL, :cancel]])

      dlg.current_name = filename

      if dlg.run == Gtk::ResponseType::ACCEPT
        item.destination = dlg.filename
      else
        item.cancel
      end

      dlg.destroy
    end
  end

  make_window(ARGV[0]||"https://duckduckgo.com")

  Gtk.main

rescue => e
  p e
end
