# Windows-only Vala bindings

MSYS2 builds libical without GObject introspection, so it ships no Vala
bindings. `libical-glib.vapi` is the file vapigen generates for libical-glib
3.0.x (taken unmodified from Ubuntu's `libical-dev` 3.0.17 package). It is
only added to the search path for Windows builds, so Linux builds keep using
the bindings installed with libical.
