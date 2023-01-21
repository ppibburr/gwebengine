#!/usr/bin/python3
import time
import os
import os.path
import signal
import sys
import gi

from PyQt5 import QtCore, QtWidgets
from PyQt5.QtCore import QUrl, QTimer
from PyQt5.QtGui import QIcon, QShowEvent
from PyQt5.QtWidgets import (QApplication, QLineEdit, QMainWindow, QPushButton, QToolBar)
from PyQt5.QtWebEngineWidgets import QWebEnginePage, QWebEngineView, QWebEngineSettings
from gi.repository import GIRepository
from gi.repository import GLib

gi.require_version("Gtk", "3.0")

from gi.repository import Gtk

def usage():
    print("GWebEngine - loader shim for QtWebEngine GObject bindings\n\nUSAGE: ./gwebengine.py SEARCHPATH PLUGIN [DATA]\n\nEx: ./gwebengine.py ./build ./samples/build/librubywebengineplugin.so ~/my_qwebengine_ruby_program.rb\n\n")

if len(sys.argv)!=4:
    usage()
    sys.exit();

if sys.argv[1]:
    GIRepository.Repository.prepend_search_path(sys.argv[1])
    GIRepository.Repository.prepend_library_path(sys.argv[1])

gi.require_version("GWebEngine", "1.0")
from gi.repository import GWebEngine

def create_gwebengine(ldr, webview):
    win = Window(webview)

    webview.win=win
    webview.ldr = ldr

    return webview;

class WebView(QWebEngineView):
    def __init__(self,par, webview):
        super(QWebEngineView,self).__init__(par)
        self.par=par
        self.webview = webview

        self.page().loadStarted.connect(self.loadStarted)
        self.page().loadFinished.connect(self.loadFinished)
        self.page().titleChanged.connect(self.titleChanged)
        self.page().urlChanged.connect(self.urlChanged)
        self.page().fullScreenRequested.connect(self.fullScreenRequested)
        self.page().printRequested.connect(lambda :self.webview.print())
        self.page().windowCloseRequested.connect(lambda :self.webview.close())
        self.page().iconUrlChanged.connect(lambda :self.webview.set_favicon(self.page().iconUrl().url()))
        self.page().profile().downloadRequested.connect(self.downloadFunction)
        #self.page().createWindow.connect(lambda :self.webview.create())

        self.settings().setAttribute(QWebEngineSettings.JavascriptEnabled, True)
        self.settings().setAttribute(QWebEngineSettings.WebGLEnabled, True)
        self.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, True)
        self.settings().setAttribute(QWebEngineSettings.PluginsEnabled, True)

        webview.get_settings().set_enable_javascript(True)
        webview.get_settings().set_enable_fullscreen(True)
        webview.get_settings().set_enable_webgl(True)
        webview.get_settings().set_enable_plugins(True)

        ## connect settings properties after init
        # ...

        webview.get_settings().connect("notify::enable-fullscreen", lambda wv,prop: self.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, webview.get_settings().get_enable_fullscreen()))
        webview.get_settings().connect("notify::enable-webgl",      lambda wv,prop: self.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, webview.get_settings().get_enable_webgl()))
        webview.get_settings().connect("notify::enable-javascript", lambda wv,prop: self.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, webview.get_settings().get_enable_javascript()))
        webview.get_settings().connect("notify::enable-plugins",    lambda wv,prop: self.settings().setAttribute(QWebEngineSettings.PluginsEnabled, webview.get_settings().get_enable_plugins()))

        # listen to methods called on the GWebEngine::WebView
        webview.connect("signal-go-back",    lambda wv: self.back())
        webview.connect("signal-go-forward", lambda wv: self.forward())
        webview.connect("signal-reload",     lambda wv: self.reload())
        webview.connect("signal-stop",       lambda wv: self.stop())
        webview.connect("signal-execute",    self.execute)
        webview.connect("signal-load",       lambda wv,uri: self.load(QUrl.fromUserInput(uri)))
        webview.connect("signal-load-html",  lambda wv, code: self.load_html(code))
        webview.connect("signal-find",       self.onFind)
        webview.connect("signal-get-zoom-level", lambda wv: self.page().zoomFactor())
        webview.connect("signal-set-zoom-level", lambda wv, l: self.page().setZoomFactor(l))

    def downloadFunction(self,item):
        req= GWebEngine.Download()
        req.set_destination(item.downloadDirectory()+"/"+item.downloadFileName())
        self.webview.emit("download-requested",req)
        req.emit("decide-destination", item.suggestedFileName())

        if not req.get_is_cancelled():
            item.setDownloadFileName(os.path.basename(req.get_destination()))
            item.setDownloadDirectory(os.path.dirname(req.get_destination()))
            item.accept()

    def createWindow(self, t):
        new_web_view = self.webview.emit("create")
        if new_web_view != None:
            window = Window(new_web_view)
            return window.webEngineView
        else:
            return None

    def loadFinished(self):
      self.onLoadChanged()

    def loadStarted(self):
      self.onLoadChanged()

    def onLoadChanged(self):
      self.webview.set_can_go_back(self.history().canGoBack());
      self.webview.set_can_go_forward(self.history().canGoForward());
      self.webview.emit("load-changed");

    def execute(self,wv,code):
        result = GWebEngine.JSResult()
        self.page().runJavaScript(code, 0, lambda r: result.emit("ready", str(r)))
        return result

    def onFind(self, wv, text):
        return self.findText(text)

    def urlChanged(self, url):
        self.webview.set_url(url.url())

    def titleChanged(self):
        self.webview.set_title(self.title())

    def fullScreenRequested(self, request):
        if request.toggleOn():
            if not self.webview.emit("enter-fullscreen"):
                request.accept();
                self.par.fullscreen()

        else:
            if not self.webview.emit("leave-fullscreen"):
                request.accept();
                self.par.unfullscreen()

class Window(QMainWindow):
    def __init__(self,webview):
        super(Window, self).__init__()
        self.webview=webview
        self.initUI()

    def on_focus(self, old,now):
        if now:
    #        ...
            self.webview.grab_focus()
    #    else:
    #        if self.ever_shown:
    #            ...

    def initUI(self):
        self.webEngineView = WebView(self, self.webview)
        self.setCentralWidget(self.webEngineView)
        self.setGeometry(0, 0, 1, 1)
        self.setWindowTitle('NoSeeMe')

        QtWidgets.qApp.focusChanged.connect(self.on_focus)

        #self.ever_shown = False
        self.took       = False
        self.show()
        self.webEngineView.page().contentsSizeChanged.connect(self.take)
        self.webEngineView.setHtml("<html/>")
        #self.webview.connect("hierarchy-changed", self.take)

    def take(self, wv):
        if  not self.took:
            print(self.took)
            self.took = True
            self.webview.take(self.winId())
            GLib.timeout_add(0,lambda :self.webview.emit("ready-to-show"))

    #def mapped(self):
    #    if self.ever_shown:
    #        ...
    #    else:
    #        ...
                
    def keyPressEvent(self, event):
        e = GWebEngine.KeyEvent(key=event.key(),text=event.text(),modifiers=event.nativeModifiers(),virtual_key=event.nativeVirtualKey(),scan_code=event.nativeScanCode())
        self.webview.key_press(e)

    def unfullscreen(self):
        if self.fs:
            self.webEngineView.setPage(self.fsv.page())
            self.fs.hide()

            self.show()
            self.showNormal();

            self.update()
            self.webEngineView.update()

    def fullscreen(self):
        w=QMainWindow(self)
        v=QWebEngineView(w)

        v.setPage(self.webEngineView.page())
        v.setGeometry(self.geometry())

        self.hide()

        w.setCentralWidget(v)
        w.show()
        w.showMaximized()
        v.update()
        w.showFullScreen()
        w.update()
        v.update()

        self.fs=w
        self.fsv=v

def start_qt_app(relay):
    relay.app = QApplication(sys.argv)
    QTimer.singleShot(0,lambda :relay.emit("qt-app"))

    return False

def main():
    # Evil ######################################
    # pango/cairo needs initialized before Qt app
    w=Gtk.Window();
    e = Gtk.Entry();
    e.set_text(" ");
    w.add(e);
    w.set_size_request(1,1)
    w.show_all();
    w.resize(width= 1,height= 1)
    #############################################

    relay  = GWebEngine.Main.get_default()
    relay.connect("signal-make-webview", create_gwebengine)

    w.connect("draw",lambda win,e:pango_init(w,relay))

    plugin = GWebEngine.load_plugin(sys.argv[2],sys.argv[3],[])

    sys.exit(0)

def pango_init(w,relay):
    w.close()
    GLib.idle_add(lambda :start_qt_app(relay))

    return False

if __name__ == '__main__':
    main()





