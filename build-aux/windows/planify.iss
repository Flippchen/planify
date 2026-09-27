; Inno Setup script for the Windows installer.
;
; Build the bundle with build-aux/windows/bundle.sh first, then run:
;
;   iscc /DAppVersion=4.20.0 /DBundleDir=..\..\dist\planify build-aux\windows\planify.iss
;
; The installer is written to dist\.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef BundleDir
  #define BundleDir "..\..\dist\planify"
#endif

#define AppId "io.github.alainm23.planify"
#define AppExe AppId + ".exe"

[Setup]
AppId={{9F6C3B1E-4E0A-4C8B-9A57-6A2D1C7E5B40}
AppName=Planify
AppVersion={#AppVersion}
AppVerName=Planify {#AppVersion}
AppPublisher=Alain M.
AppPublisherURL=https://github.com/alainm23/planify
AppSupportURL=https://github.com/alainm23/planify/issues
AppUpdatesURL=https://github.com/alainm23/planify/releases
DefaultDirName={autopf}\Planify
DefaultGroupName=Planify
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
OutputDir=..\..\dist
OutputBaseFilename=planify-{#AppVersion}-setup
SetupIconFile=..\..\data\windows\planify.ico
UninstallDisplayIcon={app}\bin\{#AppExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Planify keeps its settings, autostart entry and planify:// handler per
; user, so a per-user install needs no elevation.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Planify"; Filename: "{app}\bin\{#AppExe}"; WorkingDir: "{app}\bin"
Name: "{autoprograms}\Planify Quick Add"; Filename: "{app}\bin\{#AppId}.quick-add.exe"; WorkingDir: "{app}\bin"
Name: "{autodesktop}\Planify"; Filename: "{app}\bin\{#AppExe}"; WorkingDir: "{app}\bin"; Tasks: desktopicon

[Registry]
; Planify registers this itself on start-up as well; declaring it here makes
; the Todoist login work right after installing and removes it on uninstall.
Root: HKCU; Subkey: "Software\Classes\planify"; ValueType: string; ValueName: ""; ValueData: "URL:Planify"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\planify"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\planify\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\{#AppExe}"",0"
Root: HKCU; Subkey: "Software\Classes\planify\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\{#AppExe}"" ""%1"""

[Run]
; Index the installed fonts now rather than on Planify's first launch.
Filename: "{app}\bin\fc-cache.exe"; StatusMsg: "Building the font cache..."; Flags: runhidden
Filename: "{app}\bin\{#AppExe}"; Description: "{cm:LaunchProgram,Planify}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Stop the session bus GLib started from this installation so its files can
; be removed. Other gdbus.exe processes are left alone.
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -Command ""Get-Process gdbus -ErrorAction SilentlyContinue | Where-Object {{ $_.Path -like '{app}\*' } | Stop-Process -Force"""; Flags: runhidden; RunOnceId: "StopGDBus"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', '{#AppId}');
end;
