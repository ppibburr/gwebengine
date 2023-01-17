#!/usr/bin/python3

import sys
from PyQt5 import QtCore, QtWidgets
from PyQt5.QtCore import QUrl, QTimer
from PyQt5.QtGui import QIcon, QShowEvent
from PyQt5.QtWidgets import (QApplication, QLineEdit, QMainWindow,
    QPushButton, QToolBar)
from PyQt5.QtWebEngineWidgets import QWebEnginePage, QWebEngineView, QWebEngineSettings



def usage():
    print("GWebEngine - loader shim for QtWebEngine GObject bindings\n\nUSAGE: ./gwebengine.py SEARCHPATH PLUGIN [DATA]\n\nEx: ./gwebengine.py ./build ./samples/build/librubywebengineplugin.so ~/my_qwebengine_ruby_program.rb\n\n")

if len(sys.argv)!=4:
    usage()
    sys.exit();


import gi
from gi.repository import GIRepository


if sys.argv[1]:
    GIRepository.Repository.prepend_search_path(sys.argv[1])
    GIRepository.Repository.prepend_library_path(sys.argv[1])

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
gi.require_version("GWebEngine", "1.0")
from gi.repository import GWebEngine
from gi.repository import GLib

def create_gwebengine(ldr):
    win = Example()
    webview = GWebEngine.WebView(winid=win.winId())
    webview.win=win
    webview.ldr = ldr
    win.init_webview(webview)

    return webview;

class Example(QMainWindow):

    def __init__(self):
        super(Example, self).__init__()

        self.initUI()


    def on_focus(self, old,now):
        if self.ever_shown and now:
            ...
            #self.webview.grab_focus()
        else:
            if self.ever_shown:
                ...

    def initUI(self):
        self.webEngineView = QWebEngineView(self)
        self.setCentralWidget(self.webEngineView)

        self.webEngineView.page().loadStarted.connect(self.loadStarted)
        self.webEngineView.page().loadFinished.connect(self.loadFinished)
        self.webEngineView.page().titleChanged.connect(self.titleChanged)
        self.webEngineView.page().urlChanged.connect(self.urlChanged)
        self.webEngineView.page().fullScreenRequested.connect(self.fullScreenRequested)
        self.webEngineView.page().printRequested.connect(lambda :self.webview.print())
        self.webEngineView.page().windowCloseRequested.connect(lambda :self.webview.close())
        self.webEngineView.page().iconUrlChanged.connect(lambda :self.webview.set_favicon(self.webEngineView.page().iconUrl().url()))
        #self.webEngineView.page().createWindow.connect(lambda :self.webview.create())
        self.setGeometry(0, 0, 1, 1)
        self.setWindowTitle('NoSeeMe')

    def init_webview(self, webview):
        self.webview=webview

        QtWidgets.qApp.focusChanged.connect(self.on_focus)

        self.webEngineView.settings().setAttribute(QWebEngineSettings.JavascriptEnabled, True)
        self.webEngineView.settings().setAttribute(QWebEngineSettings.WebGLEnabled, True)
        self.webEngineView.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, True)
        self.webEngineView.settings().setAttribute(QWebEngineSettings.PluginsEnabled, True)

        webview.get_settings().set_enable_javascript(True)
        webview.get_settings().set_enable_fullscreen(True)
        webview.get_settings().set_enable_webgl(True)
        webview.get_settings().set_enable_plugins(True)

        ## connect settings properties after init
        # ...

        webview.get_settings().connect("notify::enable-fullscreen", lambda wv,prop: self.webEngineView.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, webview.get_settings().get_enable_fullscreen()))
        webview.get_settings().connect("notify::enable-webgl", lambda wv,prop: self.webEngineView.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, webview.get_settings().get_enable_webgl()))
        webview.get_settings().connect("notify::enable-javascript", lambda wv,prop: self.webEngineView.settings().setAttribute(QWebEngineSettings.FullScreenSupportEnabled, webview.get_settings().get_enable_javascript()))
        webview.get_settings().connect("notify::enable-plugins", lambda wv,prop: self.webEngineView.settings().setAttribute(QWebEngineSettings.PluginsEnabled, webview.get_settings().get_enable_plugins()))

        # listen to methods called on the GWebEngine::WebView
        webview.connect("signal-go-back", self.back)
        webview.connect("signal-go-forward", self.forward)
        webview.connect("signal-reload", self.reload)
        webview.connect("signal-stop", self.stop)
        webview.connect("signal-execute", self.execute)
        webview.connect("signal-load", self.load)
        webview.connect("signal-load-html", lambda wv, code: self.webEngineView.load_html(code))
        webview.connect("signal-find", self.onFind)
        webview.connect("signal-get-zoom-level", lambda wv: self.webEngineView.page().zoomFactor())
        webview.connect("signal-set-zoom-level", lambda wv, l: self.webEngineView.page().setZoomFactor(l))

        self.ever_shown = False

        self.webEngineView.page().contentsSizeChanged.connect(self.mapped)
        self.webEngineView.setHtml("<html/>")
        self.show()

    def mapped(self):
        if not self.ever_shown:
            self.ever_shown=True
            self.webview.take()
            self.webview.emit("ready-to-show")

    def keyPressEvent(self, event):
        e = GWebEngine.KeyEvent(key=event.key(),text=event.text(),modifiers=event.nativeModifiers(),virtual_key=event.nativeVirtualKey(),scan_code=event.nativeScanCode())
        self.webview.key_press(e)

    def loadFinished(self):
      self.onLoadChanged()

    def loadStarted(self):
      self.onLoadChanged()

    def onLoadChanged(self):
      self.webview.set_can_go_back(self.webEngineView.history().canGoBack());
      self.webview.set_can_go_forward(self.webEngineView.history().canGoForward());      
      self.webview.emit("load-changed");

    def load(self, wv, url):

        url = QUrl.fromUserInput(url)

        if url.isValid():
            self.webEngineView.load(url)

    def back(self, wv):
        self.webEngineView.back()

    def forward(self, wv):
        self.webEngineView.forward()

    def reload(self, wv):
        self.webEngineView.page().triggerAction(QWebEnginePage.Reload)

    def stop(self):
        ...

    def execute(self,wv,code):
        result = GWebEngine.JSResult()
        self.webEngineView.page().runJavaScript(code, 0, lambda r: result.emit("ready", str(r)))
        return result

    def onFind(self, wv, text):
        return self.webEngineView.findText(text)

    def urlChanged(self, url):
        self.webview.set_url(url.url())

    def titleChanged(self):
        self.webview.set_title(self.webEngineView.title())

    def fullScreenRequested(self, request):
        if request.toggleOn():
            if not self.webview.emit("enter-fullscreen"):
                request.accept();
                self.fullscreen()

        else:
            if not self.webview.emit("leave-fullscreen"):
                request.accept();
                self.unfullscreen()

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

import time

def start(plugin):
    plugin.app = QApplication(sys.argv)

    plugin.init()

    return False

import os
import signal

def main_quit(plugin):
    Gtk.main_quit()
    plugin.app.exit()



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

    w.connect("draw",lambda win,e:runner(w))

    Gtk.main()

    sys.exit(0)

def runner(w):
    w.close()

    plugin = GWebEngine.load_plugin(sys.argv[2],sys.argv[3],[])
    plugin.connect("signal-make-webview", create_gwebengine)
    plugin.connect("signal-main-quit",  lambda ldr: main_quit(ldr))
    plugin.connect("signal-main", start)

    return False



if __name__ == '__main__':
    main()





