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
 * Small Win32 helpers used in place of the freedesktop services (settings
 * portal, background portal, .desktop files) Planify relies on under Linux.
 * Everything is stored per user under HKEY_CURRENT_USER, so no elevation is
 * needed.
 */

#include "Win32.h"

#include <windows.h>

#define PERSONALIZE_KEY L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"
#define RUN_KEY L"Software\\Microsoft\\Windows\\CurrentVersion\\Run"

static gchar *
get_executable_path (void)
{
  DWORD capacity = MAX_PATH;

  for (;;)
    {
      gunichar2 *buffer = g_new (gunichar2, capacity);
      DWORD len = GetModuleFileNameW (NULL, (LPWSTR) buffer, capacity);

      if (len == 0)
        {
          g_free (buffer);
          return NULL;
        }

      if (len < capacity)
        {
          gchar *path = g_utf16_to_utf8 (buffer, len, NULL, NULL, NULL);
          g_free (buffer);
          return path;
        }

      g_free (buffer);

      if (capacity >= 32768)
        return NULL;

      capacity *= 2;
    }
}

/* Writes a REG_SZ value. A NULL @subkey writes to @key itself and a NULL
 * @name writes the key's default value. */
static gboolean
set_string_value (HKEY         key,
                  const gchar *subkey,
                  const gchar *name,
                  const gchar *data)
{
  gunichar2 *wsubkey = NULL;
  gunichar2 *wname = NULL;
  gunichar2 *wdata = NULL;
  glong data_len = 0;
  gboolean ok = FALSE;

  if (subkey != NULL)
    wsubkey = g_utf8_to_utf16 (subkey, -1, NULL, NULL, NULL);
  if (name != NULL)
    wname = g_utf8_to_utf16 (name, -1, NULL, NULL, NULL);
  wdata = g_utf8_to_utf16 (data, -1, NULL, &data_len, NULL);

  if (wdata != NULL)
    ok = RegSetKeyValueW (key, (LPCWSTR) wsubkey, (LPCWSTR) wname, REG_SZ,
                          (const BYTE *) wdata,
                          (DWORD) ((data_len + 1) * sizeof (gunichar2))) == ERROR_SUCCESS;

  g_free (wsubkey);
  g_free (wname);
  g_free (wdata);

  return ok;
}

gboolean
planify_win32_prefers_dark_theme (void)
{
  DWORD value = 1;
  DWORD size = sizeof (value);

  if (RegGetValueW (HKEY_CURRENT_USER, PERSONALIZE_KEY, L"AppsUseLightTheme",
                    RRF_RT_REG_DWORD, NULL, &value, &size) != ERROR_SUCCESS)
    return FALSE;

  return value == 0;
}

gboolean
planify_win32_set_autostart (const gchar *name,
                             gboolean     enabled,
                             gboolean     background)
{
  HKEY key;
  gboolean ok = FALSE;

  if (RegCreateKeyExW (HKEY_CURRENT_USER, RUN_KEY, 0, NULL, 0, KEY_SET_VALUE,
                       NULL, &key, NULL) != ERROR_SUCCESS)
    return FALSE;

  if (enabled)
    {
      gchar *exe = get_executable_path ();

      if (exe != NULL)
        {
          gchar *command = g_strdup_printf ("\"%s\"%s", exe,
                                            background ? " --background" : "");
          ok = set_string_value (key, NULL, name, command);
          g_free (command);
          g_free (exe);
        }
    }
  else
    {
      gunichar2 *wname = g_utf8_to_utf16 (name, -1, NULL, NULL, NULL);
      LSTATUS status = RegDeleteValueW (key, (LPCWSTR) wname);

      ok = status == ERROR_SUCCESS || status == ERROR_FILE_NOT_FOUND;
      g_free (wname);
    }

  RegCloseKey (key);

  return ok;
}

gboolean
planify_win32_register_uri_scheme (const gchar *scheme,
                                   const gchar *description)
{
  HKEY key;
  gchar *exe;
  gchar *key_path;
  gunichar2 *wkey_path;
  gboolean ok = FALSE;

  exe = get_executable_path ();
  if (exe == NULL)
    return FALSE;

  key_path = g_strdup_printf ("Software\\Classes\\%s", scheme);
  wkey_path = g_utf8_to_utf16 (key_path, -1, NULL, NULL, NULL);

  if (RegCreateKeyExW (HKEY_CURRENT_USER, (LPCWSTR) wkey_path, 0, NULL, 0,
                       KEY_SET_VALUE | KEY_CREATE_SUB_KEY, NULL, &key, NULL) == ERROR_SUCCESS)
    {
      gchar *default_value = g_strdup_printf ("URL:%s", description);
      gchar *icon = g_strdup_printf ("\"%s\",0", exe);
      gchar *command = g_strdup_printf ("\"%s\" \"%%1\"", exe);

      ok = set_string_value (key, NULL, NULL, default_value) &&
           set_string_value (key, NULL, "URL Protocol", "") &&
           set_string_value (key, "DefaultIcon", NULL, icon) &&
           set_string_value (key, "shell\\open\\command", NULL, command);

      g_free (default_value);
      g_free (icon);
      g_free (command);
      RegCloseKey (key);
    }

  g_free (wkey_path);
  g_free (key_path);
  g_free (exe);

  return ok;
}
