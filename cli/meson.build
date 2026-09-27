cli_sources = files(
  'DBusClient.vala',
  'ArgumentParser.vala',
  'TaskValidator.vala',
  'TaskCreator.vala',
  'OutputFormatter.vala',
  'Main.vala',
)

executable(
  'io.github.alainm23.planify.cli',
  cli_sources,
  config_file,
  win_resources,
  dependencies: deps,
  install: true,
)
