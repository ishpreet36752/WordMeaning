; WordMeaning.iss — Inno Setup script. Builds dist\WordMeaning-Setup.exe.
; Per-user install (no admin): installs the standalone WordMeaning.exe, adds a
; Start-menu shortcut, an optional desktop shortcut, and an optional
; "Start with Windows" auto-start (HKCU Run key). Ships an uninstaller.
;
; Compile:  "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" installer\WordMeaning.iss
; (build.ps1 does this automatically when Inno Setup is present, after the exe.)

#define MyAppName "WordMeaning"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "WordMeaning contributors"
#define MyAppURL "https://github.com/ishpreet36752/WordMeaning"
#define MyAppExeName "WordMeaning.exe"

[Setup]
; Stable per-app id (do not change across versions).
AppId={{EF28F94C-729D-4348-A5E1-4FAAD44DDE2E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
; Per-user, no administrator rights required.
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=WordMeaning-Setup
SetupIconFile=..\assets\wordmeaning.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "startupicon"; Description: "Start {#MyAppName} automatically when Windows starts"; GroupDescription: "Startup:"

[Files]
Source: "..\dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Auto-start on login (only if the user ticked the task). Uses the same HKCU Run
; value name the app's own "Start with Windows" tray toggle manages, so they stay
; consistent. Removed automatically on uninstall.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

[Code]
// Close a running instance so its .exe can be overwritten / removed.
procedure KillRunning;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/IM {#MyAppExeName} /F', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  KillRunning;
  Result := '';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    KillRunning;
end;
