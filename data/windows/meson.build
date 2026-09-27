windows = import('windows')

icon = profile == 'development' ? 'planify-devel.ico' : 'planify.ico'
version_parts = meson.project_version().split('.')

rc_conf = configuration_data()
rc_conf.set('ICON', icon)
rc_conf.set('VERSION', meson.project_version())
rc_conf.set('VERSION_NUMBERS', ','.join(version_parts + ['0']))

rc_file = configure_file(
  input: 'planify.rc.in',
  output: 'planify.rc',
  configuration: rc_conf,
)

# The icon must have resource ID 1: GLib uses it for Windows notifications.
win_resources = windows.compile_resources(
  rc_file,
  include_directories: include_directories('.'),
  depend_files: files(icon),
)
