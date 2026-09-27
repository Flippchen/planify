quick_find_sources = files(
  'Services/DBusClient.vala',
  'App.vala',
  'MainWindow.vala',
)

executable(
  'io.github.alainm23.planify.quick-add',
  quick_find_sources,
  asresources,
  config_file,
  win_resources,
  dependencies: deps,
  win_subsystem: 'windows',
  install: true,
)
