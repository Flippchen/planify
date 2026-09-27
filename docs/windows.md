# Planify on Windows

Planify builds natively on Windows with [MSYS2](https://www.msys2.org/),
which provides GTK 4, libadwaita and the rest of the GNOME stack as Windows
libraries.

## Download

Every push and pull request is built by the
[Windows workflow](../.github/workflows/windows.yml). Each run uploads a
`planify-windows-x64` artifact containing:

- `planify-<version>-setup.exe`: an installer. It installs for the current
  user by default and needs no administrator rights.
- `planify-<version>-windows-x64.zip`: a portable build. Extract it anywhere
  and run `bin\io.github.alainm23.planify.exe`.

## Building from source

1. Install [MSYS2](https://www.msys2.org/) and open the **MSYS2 UCRT64**
   shell.

2. Install the build dependencies:

   ```bash
   pacman -S --needed git grep zip \
       mingw-w64-ucrt-x86_64-{cc,meson,ninja,pkgconf,vala,gettext-tools} \
       mingw-w64-ucrt-x86_64-{glib2,glib-networking,gtk4,libadwaita,adwaita-icon-theme} \
       mingw-w64-ucrt-x86_64-{gtksourceview5,libspelling,hunspell-en} \
       mingw-w64-ucrt-x86_64-{libgee,json-glib,libsoup3,sqlite3} \
       mingw-w64-ucrt-x86_64-{libical,libxml2,icu}
   ```

3. Clone the repository with its submodules and build a bundle:

   ```bash
   git clone --recursive https://github.com/alainm23/planify.git
   cd planify
   build-aux/windows/bundle.sh
   ```

   `dist/planify` now holds a self-contained copy of Planify: the
   executables, every DLL they load, and the schemas, icons and translations
   they need. It can be copied to any Windows 10 or 11 machine.

4. Optionally, build the installer with [Inno Setup 6](https://jrsoftware.org/isinfo.php)
   from a regular command prompt:

   ```bat
   iscc /DAppVersion=4.20.0 build-aux\windows\planify.iss
   ```

For development you can also run the usual meson commands from the UCRT64
shell (`meson setup build && meson compile -C build`) and start
`build/src/io.github.alainm23.planify.exe` directly, since the MSYS2 libraries
are already on `PATH` there. The `portal`, `evolution` and `goa` options are
switched off automatically on Windows.

## What's different from Linux

The following features depend on Linux desktop services and are not
available on Windows:

- **Calendar events** from Evolution Data Server (GNOME Calendar accounts).
- **GNOME Online Accounts** detection when adding Nextcloud or CalDAV
  accounts. Adding them by hand works as usual.
- **GNOME Shell search** integration.

Everything else, including local projects and syncing with Todoist,
Nextcloud and CalDAV servers, works as on Linux. Some things work
differently:

| Feature | Linux | Windows |
| --- | --- | --- |
| Data, backups and log | `~/.local/share/io.github.alainm23.planify` | `%LOCALAPPDATA%\io.github.alainm23.planify` |
| Settings | GSettings (dconf) | GSettings (registry, `HKCU\Software\GSettings`) |
| Light/dark style | Settings portal | Windows "app mode" setting |
| Run on Startup | Background portal | `HKCU\...\CurrentVersion\Run` entry |
| `planify://` links (Todoist login) | `.desktop` file | Registered under `HKCU\Software\Classes\planify` |
| Reminders | Desktop notifications | Windows notifications |
| Spell checking | Enchant (usually Hunspell) | The Windows spell checker, for every language installed in Windows; bundled English Hunspell dictionaries as a fallback |

Quick Add (`io.github.alainm23.planify.quick-add.exe`) and the command-line
tool (`io.github.alainm23.planify.cli.exe`) talk to the running app over
D-Bus, like on Linux. GLib starts a private session bus for them
(`gdbus.exe`, included in the bundle) the first time one is needed. To open
Quick Add with a keyboard shortcut, give its Start menu shortcut a shortcut
key in its **Properties** dialog.
