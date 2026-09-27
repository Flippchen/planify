/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

/*
 * Operating system specific behaviour. On Linux these are thin pass-throughs;
 * on Windows they replace the freedesktop services that are not available
 * there.
 */
namespace Platform {
#if WINDOWS
    [CCode (cheader_filename = "Platform/Win32.h", cname = "planify_win32_prefers_dark_theme")]
    private extern bool win32_prefers_dark_theme ();

    [CCode (cheader_filename = "Platform/Win32.h", cname = "planify_win32_set_autostart")]
    private extern bool win32_set_autostart (string name, bool enabled, bool background);

    [CCode (cheader_filename = "Platform/Win32.h", cname = "planify_win32_register_uri_scheme")]
    private extern bool win32_register_uri_scheme (string scheme, string description);
#endif

    public bool is_windows () {
#if WINDOWS
        return true;
#else
        return false;
#endif
    }

    /*
     * The installation prefix. Windows builds are relocatable, so the prefix
     * is derived from the location of the running executable instead of the
     * one configured at build time.
     */
    public string get_install_prefix (string build_prefix) {
#if WINDOWS
        string? prefix = GLib.Win32.get_package_installation_directory_of_module (null);
        if (prefix != null) {
            return prefix;
        }
#endif
        return build_prefix;
    }

    public string get_locale_dir (string build_locale_dir) {
#if WINDOWS
        string? prefix = GLib.Win32.get_package_installation_directory_of_module (null);
        if (prefix != null) {
            return Path.build_filename (prefix, "share", "locale");
        }
#endif
        return build_locale_dir;
    }

    /*
     * Whether the desktop asks applications to use a dark style. Returns
     * false when the platform has no way to tell.
     */
    public bool system_prefers_dark () {
#if WINDOWS
        return win32_prefers_dark_theme ();
#else
        return false;
#endif
    }

    /*
     * Registers (or removes) Planify to start with the user session. Only
     * implemented on Windows; Linux goes through the background portal.
     */
    public bool set_autostart (string app_id, bool enabled, bool background) {
#if WINDOWS
        return win32_set_autostart (app_id, enabled, background);
#else
        return false;
#endif
    }

    /*
     * Pango's fallback fonts for the Windows UI font don't include an emoji
     * font, so emoji (project icons, task names…) would be drawn as
     * missing-glyph boxes. List the Windows emoji fonts after the UI font so
     * they are used for the characters it lacks.
     */
    public void install_emoji_font_fallback () {
#if WINDOWS
        string family = "Segoe UI";
        string? font_name = Gtk.Settings.get_default ().gtk_font_name;
        if (font_name != null) {
            string? system_family = Pango.FontDescription.from_string (font_name).get_family ();
            if (system_family != null && system_family != "") {
                family = system_family;
            }
        }

        var provider = new Gtk.CssProvider ();
        provider.load_from_string (
            "window, popover { font-family: \"%s\", \"Segoe UI Emoji\", \"Segoe UI Symbol\"; }".printf (family)
        );

        Gtk.StyleContext.add_provider_for_display ( // vala-lint=deprecated
            Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
#endif
    }

    /*
     * Makes the running executable the handler for planify:// links, which
     * the Todoist login redirects to. On Linux this is done by the .desktop
     * file.
     */
    public void register_uri_scheme () {
#if WINDOWS
        if (!win32_register_uri_scheme ("planify", "Planify")) {
            warning ("Could not register the planify:// URI scheme");
        }
#endif
    }
}
