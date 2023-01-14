/* gwebenginerubyplugin.h generated by valac 0.56.3, the Vala compiler, do not modify */

#ifndef ____GWEBENGINERUBYPLUGIN_H__
#define ____GWEBENGINERUBYPLUGIN_H__

#include <glib-object.h>
#include <gwebengine.h>
#include <gmodule.h>
#include <glib.h>

G_BEGIN_DECLS

#if !defined(VALA_EXTERN)
#if defined(_MSC_VER)
#define VALA_EXTERN __declspec(dllexport) extern
#elif __GNUC__ >= 4
#define VALA_EXTERN __attribute__((visibility("default"))) extern
#else
#define VALA_EXTERN extern
#endif
#endif

#define TYPE_PLUGIN (plugin_get_type ())
#define PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_PLUGIN, Plugin))
#define PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_PLUGIN, PluginClass))
#define IS_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_PLUGIN))
#define IS_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_PLUGIN))
#define PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_PLUGIN, PluginClass))

typedef struct _Plugin Plugin;
typedef struct _PluginClass PluginClass;
typedef struct _PluginPrivate PluginPrivate;

struct _Plugin {
	GObject parent_instance;
	PluginPrivate * priv;
};

struct _PluginClass {
	GObjectClass parent_class;
};

VALA_EXTERN GType plugin_get_type (void) G_GNUC_CONST ;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (Plugin, g_object_unref)
VALA_EXTERN Plugin* plugin_new (void);
VALA_EXTERN Plugin* plugin_construct (GType object_type);
VALA_EXTERN GType register_plugin (GModule* module);

G_END_DECLS

#endif
