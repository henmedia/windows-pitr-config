@echo off
rem ===========================================================================
rem  pitr-config.cmd
rem  Configures Point-in-time restore / Zeitpunktwiederherstellung (Windows 11).
rem  Seven languages: English, German, French, Spanish, Portuguese, Italian and
rem  Polish. The one matching the Windows display language is picked automatically.
rem
rem  Single file: the complete PowerShell code sits below the #___PSCODE___
rem  marker and is loaded from here. Just double-click it; the file requests
rem  administrator rights itself (UAC) and can be copied anywhere, e.g. onto
rem  a USB stick.
rem
rem  Running it with the argument "selftest" only checks the interface - no
rem  window, no administrator rights, and nothing is written.
rem
rem  The argument "noupdate" skips the check for a newer version on start.
rem
rem  "snapshot" creates a restore point without a window; "autostart on delay=5m"
rem  registers a task that does exactly that a few minutes after every system start.
rem
rem  "idle" reports whether Windows still reaches an idle state at all - the one
rem  condition every restore point depends on. It only reads and runs without rights,
rem  though an unelevated prompt sees fewer scheduled tasks and says so. It returns 2
rem  when the idle state is blocked system-wide.
rem
rem  Running it as "apply" writes settings without a window, for startup scripts:
rem      pitr-config.cmd apply freq=4h reten=5d size=20g active=on
rem  It needs an elevated prompt and does not elevate itself - see the note further down.
rem
rem  IMPORTANT: this file must stay UTF-8 WITHOUT BOM. A BOM makes cmd.exe
rem  trip over the very first line. Non-ASCII characters in the PowerShell
rem  part survive regardless, because the loader reads the file as UTF-8
rem  explicitly instead of relying on the console code page.
rem ===========================================================================
setlocal

if /i "%~1"=="selftest" goto :selftest
if /i "%~1"=="apply"    goto :apply
if /i "%~1"=="snapshot"  goto :snapshot
if /i "%~1"=="autostart" goto :autostart
if /i "%~1"=="idle"      goto :idle

rem  Started from a network share, cmd.exe prints a warning of its own before the first
rem  line here runs: UNC paths are not supported as the current directory, and it falls
rem  back to C:\Windows. "@echo off" cannot suppress it - cmd.exe writes it itself, to
rem  stderr. It reads like a failure but has no consequence: the loader works with %~f0,
rem  its own full path, and never needs the current directory. So wipe it and put a calm
rem  line in its place. Only in window mode - the selftest writes into a console whose
rem  contents nobody wants cleared.
set "P0=%~f0"
if "%P0:~0,2%"=="\\" (
  cls
  echo.
  echo   pitr-config - starting, please wait ...
  echo.
)

rem  The argument has to survive the elevation, because the elevated instance is a new
rem  process that does not inherit it. It is therefore passed on explicitly.
set "PITR_NOUPDATE="
if /i "%~1"=="noupdate" set "PITR_NOUPDATE=1"

net session >nul 2>&1
if "%errorlevel%"=="0" goto :admin
if defined PITR_NOUPDATE (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden -ArgumentList 'noupdate'"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WindowStyle Hidden"
)
exit /b

:admin
set "PITR_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb"
exit /b

:selftest
set "PITR_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb -SelfTest"
exit /b

rem  Der Kommandozeilenbetrieb hebt sich bewusst NICHT selbst auf Administratorrechte:
rem  Die Erhoehung startet einen neuen Prozess mit eigener Konsole, dessen Ausgabe und
rem  Rueckgabewert im aufrufenden Skript nicht mehr ankommen. Ein Startskript laeuft
rem  ohnehin erhoeht; alles andere bekommt eine klare Ansage und den Rueckgabewert 5.
rem
rem  The command line deliberately does NOT self-elevate: elevation starts a new process
rem  with its own console, and neither its output nor its exit code would reach the
rem  caller. A startup script runs elevated anyway; anything else gets a clear message
rem  and exit code 5.
:apply
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo pitr-config: administrator rights are required for "apply".
  exit /b 5
)
set "PITR_SELF=%~f0"
set "PITR_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb -Apply -Options $env:PITR_ARGS"
exit /b %errorlevel%

rem  Legt sofort einen Wiederherstellungspunkt an, ohne Fenster. Das ist der Aufruf,
rem  den die Startaufgabe verwendet - und der sich in jedem eigenen Skript benutzen
rem  laesst. Braucht wie "apply" eine erhoehte Eingabeaufforderung.
:snapshot
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo pitr-config: administrator rights are required for "snapshot".
  exit /b 5
)
set "PITR_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb -Snapshot"
exit /b %errorlevel%

:autostart
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo pitr-config: administrator rights are required for "autostart".
  exit /b 5
)
set "PITR_SELF=%~f0"
set "PITR_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb -AutoStart -Options $env:PITR_ARGS"
exit /b %errorlevel%

rem  Reine Auskunft: liest nur Aufgaben und Systemstartzeit, schreibt nichts und
rem  braucht deshalb - anders als die drei Zweige darueber - keine erhoehte
rem  Eingabeaufforderung.
:idle
set "PITR_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$m='#___PSCODE___'; $t=[IO.File]::ReadAllText($env:PITR_SELF,[Text.UTF8Encoding]::new($false)); $sb=[scriptblock]::Create($t.Substring($t.LastIndexOf($m)+$m.Length)); & $sb -Idle"
exit /b %errorlevel%

#___PSCODE___
<#
    Point-in-time restore (PITR) / Zeitpunktwiederherstellung
    Graphical configuration tool in EN, DE, FR, ES, PT, IT and PL.
    Also drivable from the command line:  pitr-config.cmd apply freq=4h reten=5d

    The PITR engine reads its configuration from
        HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings
    using the scheme <name>_<level> (DWORD).
        Names  : Active, SnapshotInterval (min), MaxTimespan (min),
                 MaxGlobalSize (MB), MaxCount
        Levels : GPO > CSP > UX (Settings app) > Default

    This tool writes at the GPO level and therefore takes precedence over the
    Settings app. That makes frequency and retention configurable on Windows 11
    Home and Pro as well, where the interface does not offer them.

    Scope: PITR only ever covers the OS volume. PITR.dll rejects anything else
    ("Snapshot is not on the OS volume"), there is no per-volume configuration,
    and a snapshot registry entry carries no volume at all. Other partitions and
    other disks are neither captured nor rolled back.

    The value names are undocumented by Microsoft; they were recovered from
    PITR.dll and RemoteRemediationCSP.dll and verified in practice.
#>

param([switch]$SelfTest, [switch]$Apply, [switch]$Snapshot, [switch]$AutoStart,
      [switch]$Idle, [string]$Options = '')

# Wird von den kopflosen Zweigen gesetzt und von Write-Log/Update-Ui abgefragt.
$script:Headless = $false

$ErrorActionPreference = 'Stop'

# The one place the version is defined. It appears under the headline in the window
# and in the selftest; a release is tagged with "v" followed by this value. Keeping
# it out of the batch header above avoids having two numbers that can drift apart.
$Version  = '1.7.0'

# Asked on start unless PITR_NOUPDATE is set. Returns the newest release of the project.
$UpdateApi = 'https://api.github.com/repos/henmedia/windows-pitr-config/releases/latest'
$script:UpdateVersion = $null
$script:UpdateUrl     = $null

# Linked from the window. The guide carries all seven languages in one page and picks
# one from the fragment. A copy of it sitting next to the .cmd wins over the online
# version, so the tool stays fully usable on a stick without a network.
$ProjectUrl = 'https://github.com/henmedia/windows-pitr-config'
$GuideUrl   = 'https://henmedia.github.io/windows-pitr-config/guide.html'
if ($env:PITR_SELF) {
    $localGuide = Join-Path (Split-Path -Parent $env:PITR_SELF) 'guide.html'
    if (Test-Path -LiteralPath $localGuide) { $GuideUrl = ([Uri]$localGuide).AbsoluteUri }
}
function Get-GuideUri { return "$GuideUrl#$($script:Lang)" }

$KeyPath  = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings'
$SnapPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Snapshots'
$TaskPath = '\Microsoft\Windows\Setup\'
$TaskName = 'PITRTask'
$Level    = 'GPO'

# Windows default retention (minutes). Longer values demonstrably work, even
# though Microsoft documents 72 hours as the maximum.
$RetentionDefault = 4320   # 72 Stunden = 3 Tage

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ------------------------------------------------------------------- Text --
# One block per language, so each translation can be read and maintained as a whole.
# English is the fallback for anything a block is missing, which means a new language
# can be added incrementally without breaking the interface.
#
# The feature name stays "Point-in-time restore" everywhere: that is the term Microsoft's
# documentation uses and the one a user has to search for. Where a block adds a rendering
# in its own language, it is a plain description in brackets - not a claim about what the
# Windows interface itself is called in that language.
#
# "pt" is Brazilian Portuguese. Windows reports both variants as "pt", so one block has to
# serve both; pt-BR has by far the larger share of users.
#
# The name $LangText is deliberately long and distinct: PowerShell variables are not
# case-sensitive and are resolved dynamically. A short $S would be shadowed by the local
# $s in Update-View as soon as T() is called from there.
$LangText = @{

# ----------------------------------------------------------------- English --
en = @{
    winTitle   = 'Point-in-time restore'
    headline   = 'Point-in-time restore'
    subtitle   = 'PITR'
    intro      = 'Windows offers frequency and retention on the Enterprise edition only. This tool writes them straight into the PITR engine configuration, which performs no edition check.'
    lnkGuide   = 'Guide'
    tipProject = 'Open the project page on GitHub'
    tipGuide   = 'Open the short guide in the browser'
    updAvail   = 'Version {0} is available - open the release page'
    tipUpdate  = 'Opens the download page in the browser. Nothing is downloaded or installed automatically.'

    grpState   = 'Current state'
    capEdition = 'Windows edition:'
    capLast    = 'Last run:'
    capNext    = 'Next run:'
    capDelta   = 'Scheduled interval:'
    capTaskSt  = 'Task status:'
    tsReady    = 'ready'
    tsQueued   = 'waiting for the system to go idle'
    tsRunning  = 'running right now'
    tsDisabled = 'disabled'
    tsOverdue  = 'overdue by'
    missedRuns = 'runs skipped: {0}'
    btnIdleChk = 'Check idle'
    idlePartial = ' Counted without administrator rights, so only the tasks visible to this account were included.'
    idleBanner = '{0} runs were skipped. That is normal while the machine is in use - but it can also mean Windows is no longer reporting an idle state at all.'
    idleBlocked = 'Windows has not reported an idle state since {0}. Not one of {1} other idle-bound tasks has run since then, so this reaches well beyond snapshots. Usually a program or a driver is holding the system awake - "powercfg /requests" in an elevated command prompt names it.'
    idleFine   = 'Idle detection is working: {0} of {1} other idle-bound tasks have run since the system started, the last one at {2}. The machine was simply in use when a run fell due.'
    idleEarly  = 'None of the {0} other idle-bound tasks has run yet, but the system has only been up for {1} - too short to mean anything. Worth checking again later.'
    idleChecking = 'reading the other idle-bound tasks ...'
    logIdleChk = 'Idle check: {0}'
    staleSame  = 'The startup task runs a different build of this same version {0} from {1}.'
    noteIdle   = 'Restore points are only created while the system is idle. If the machine is in use or switched off, the run is postponed - and a scheduled slot may be skipped entirely. The configured frequency is therefore an earliest possible interval, not a guarantee. "Create snapshot now" at the top forces a point whenever one is wanted.'

    grpPoints  = 'Restore points'
    lblCount   = 'Count'
    lblOldest  = 'Oldest point'
    lblStorage = 'Storage on drive'
    stUsed     = 'in use'
    stAlloc    = 'reserved'
    stMax      = 'limit'
    stNoAdmin  = 'unavailable (administrator rights required)'
    noteStore  = 'Windows reports storage per drive only, never per point - all points share one common difference area.'
    tipStore   = 'In use = data actually written by shadow copies.' + [Environment]::NewLine +
                 'Reserved = space VSS has already claimed on disk. It is no longer available to other files but is not yet fully filled.' + [Environment]::NewLine +
                 'Limit = configured ceiling; the area never grows beyond it.'
    noteVolume = 'Only the Windows drive {0} is covered. Other partitions and other disks are left out - even when they sit on the same physical disk. They are neither captured nor rolled back during a restore, so data there still needs a backup of its own. The storage limit below likewise applies to {0} alone. The points also sit on the very drive they protect: a failed disk takes them with it. Point-in-time restore answers a bad update or a bad driver, not hardware failure, theft or ransomware - it is no substitute for a backup.'

    colTime    = 'Time'
    colAge     = 'Age'
    colStatus  = 'Status'
    colBuild   = 'Build'
    colDur     = 'Duration'
    histHint   = 'Windows does not record how long a snapshot took unless the Task Scheduler history is switched on. It logs every scheduled task on this machine, and it only covers runs from then on.'
    btnHist    = 'Enable task history'
    askHist    = 'Switch the Task Scheduler history on? This is a Windows-wide setting: from then on every scheduled task on this machine is logged into a 10 MB ring buffer. Existing restore points still get no duration - only runs from now on.'
    askHistT   = 'Task history'
    logHistOn  = 'Task history switched on. Durations appear from the next run onwards.'
    logHistErr = 'Could not switch the task history on.'
    askCopy    = 'This file is on a network share or a removable drive. The task runs as SYSTEM, which reaches the network as the computer account and not as you - that is why a startup snapshot from a share usually fails even when the share opens fine for you.{0}{0}Copy the file to {1} and register the task from there?{0}{0}Yes: copy and use the local file. No: register it with the current path anyway. Cancel: do not register.'
    askCopyT   = 'Startup snapshot'
    logCopyOk  = 'Copied to {0} - the task uses that file.'
    loading    = 'reading...'
    staleOld   = 'The startup task still runs version {0} from {1}. This one is {2}.'
    staleGone  = 'The startup task points at {0}, and that file is no longer there.'
    btnAutoUpd = 'Refresh the copy'
    logAutoUpd = 'Copy refreshed: {0} now holds version {1}.'
    stShadowOk = 'shadow copy present'
    stRegOnly  = 'registry entry only'
    stUnknown  = 'unknown (needs admin rights)'

    grpSet     = 'Settings'
    capActive  = 'Feature enabled'
    capFreq    = 'Frequency - interval between restore points'
    capReten   = 'Retention - lifetime of a restore point'
    capSize    = 'Maximum storage for all restore points'

    optNoOver  = 'Windows default (do not override)'
    optOn      = 'On'
    optOff     = 'Off'
    optStdFreq = 'Windows default (24 hours)'
    optStdRet  = 'Windows default (3 days / 72 hours)'
    unitHour   = 'hour'
    unitHours  = 'hours'
    unitDay    = 'day'
    unitDays   = 'days'
    unitMin    = 'minutes'
    unitMin1   = 'minute'
    unitMinShort = 'min'
    unitHourShort = 'h'

    btnReset   = 'Reset everything'
    btnRefresh = 'Refresh'
    btnApply   = 'Apply'
    btnApplyNow= 'Apply and run now'
    btnSnapNow = 'Create snapshot now'
    snapHint   = 'Creates a restore point right away, whatever the schedule says. The settings below stay untouched.'
    tipSnapNow = 'Runs PITRTask once, even while the machine is in use. Nothing is written to the configuration.'
    chkAuto    = 'At every system start'
    autoHint   = 'Windows asks for a point at startup by itself, but that request waits for the system to go idle - and a machine that just booted is anything but. This forces it.'
    tipAuto    = 'Registers a scheduled task that creates a restore point the chosen number of minutes after every system start. Runs as SYSTEM, no logon needed.'
    logAutoOn  = 'Startup snapshot registered: {0} minutes after boot.'
    logAutoOff = 'Startup snapshot removed.'
    warnPath   = 'This file is not on a fixed local drive. The task stores its path and may not reach it at boot time.'
    grpLog     = 'Log'

    effective  = 'Currently effective'
    source     = 'source'
    winDefault = 'Windows default'
    srcGPO     = 'policy (this tool)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'Settings app'
    sizeStd    = 'Windows default (2% of the disk)'

    carryOver  = 'still stems from the previous setting; will be adjusted on the next run to'
    proven72   = 'older than 72 hours: the extended retention demonstrably works'
    unofficial = 'Unofficial approach: the configuration values written here are undocumented by Microsoft and may change with future Windows releases. "Reset everything" restores the Windows default at any time.'
    taskMissing= 'PITRTask not found'
    unknownTxt = 'unknown'

    logReady   = 'Ready. Values are written at policy level and take precedence over the Settings app.'
    logNoAdmin = 'WARNING: without administrator rights no values can be saved.'
    logRefresh = 'View refreshed.'
    logSaved   = 'Saved. Takes effect on the next PITRTask run (it only runs when the system is idle).'
    logCleared = 'override removed -> Windows default'
    logIdleOff = 'Idle condition temporarily lifted.'
    logStarted = 'PITRTask started, waiting for completion...'
    logIdleOn  = 'Idle condition restored.'
    logIdleErr = 'Idle condition restored after an error.'
    logIdleBad = 'WARNING: could not restore the idle condition!'
    logDone    = 'Done. Result'
    logNextRun = 'next run'
    logTook    = 'took {0}'
    logNoFinish= 'still busy after {0} - the point is being finished in the background.'
    logRemoved = 'removed'
    logNothing = 'No values were set.'
    logError   = 'Error'
    askReset   = 'Remove every value set by this tool and return to the Windows default?'
    askResetT  = 'Reset'
    capWinRE   = 'Recovery environment:'
    winreOn    = 'available'
    winreOff   = 'switched off'
    winreUnk   = 'not determinable'
    winreFree  = 'free'
    noteWinRE  = 'Without the recovery environment no restore point can be applied - the rollback runs from there, not from inside Windows. An elevated "reagentc /enable" usually puts it back.'
    btnWinRE   = 'Restart to recovery'
    tipWinRE   = 'Restarts Windows into the recovery environment, where a restore point can be applied. Unsaved work in other programs is lost.'
    askWinRE   = 'Restart into the recovery environment now? Unsaved work in other programs will be lost.'
    askWinRET  = 'Restart'
    logWinRE   = 'Restarting into the recovery environment...'
    btnCopy    = 'Copy state'
    copyHint   = 'Copies edition, settings with their source, task status and restore points as text - for a forum post or a bug report.'
    tipCopy    = 'Copies the current state to the clipboard as plain text - edition, settings with their source, task status, restore points and storage. Made for a forum post or a bug report.'
    logCopied  = 'State copied to the clipboard.'
}

# ------------------------------------------------------------------ German --
# The German subtitle deliberately names the English original - that is what Microsoft's
# documentation is filed under.
de = @{
    winTitle   = 'Zeitpunktwiederherstellung (Point-in-time restore)'
    headline   = 'Zeitpunktwiederherstellung'
    subtitle   = 'Point-in-time restore (PITR)'
    intro      = 'Windows bietet Häufigkeit und Aufbewahrung nur auf der Enterprise-Edition an. Dieses Werkzeug schreibt sie direkt in die Konfiguration der PITR-Engine, die keine Editionsprüfung vornimmt.'
    lnkGuide   = 'Anleitung'
    tipProject = 'Projektseite auf GitHub öffnen'
    tipGuide   = 'Kurzanleitung im Browser öffnen'
    updAvail   = 'Version {0} ist verfügbar - Release-Seite öffnen'
    tipUpdate  = 'Öffnet die Download-Seite im Browser. Es wird nichts automatisch heruntergeladen oder installiert.'

    grpState   = 'Aktueller Zustand'
    capEdition = 'Windows-Edition:'
    capLast    = 'Letzter Lauf:'
    capNext    = 'Nächster Lauf:'
    capDelta   = 'Eingeplanter Abstand:'
    capTaskSt  = 'Status der Aufgabe:'
    tsReady    = 'bereit'
    tsQueued   = 'wartet auf Leerlauf des Systems'
    tsRunning  = 'läuft gerade'
    tsDisabled = 'deaktiviert'
    tsOverdue  = 'überfällig seit'
    missedRuns = 'ausgefallene Läufe: {0}'
    btnIdleChk = 'Leerlauf prüfen'
    idlePartial = ' Ohne Administratorrechte gezählt, es sind also nur die für dieses Konto sichtbaren Aufgaben enthalten.'
    idleBanner = '{0} Läufe sind ausgefallen. Das ist normal, solange der Rechner benutzt wird - es kann aber auch heißen, dass Windows überhaupt keinen Leerlauf mehr meldet.'
    idleBlocked = 'Windows meldet seit {0} keinen Leerlauf. Seitdem ist keine von {1} weiteren leerlaufgebundenen Aufgaben gelaufen, das reicht also weit über Schnappschüsse hinaus. Meist hält ein Programm oder ein Treiber das System wach - "powercfg /requests" in einer Eingabeaufforderung mit Rechten nennt es.'
    idleFine   = 'Die Leerlauferkennung arbeitet: {0} von {1} weiteren leerlaufgebundenen Aufgaben liefen seit dem Systemstart, die letzte um {2}. Der Rechner war zu den fälligen Zeiten nur in Benutzung.'
    idleEarly  = 'Von {0} weiteren leerlaufgebundenen Aufgaben lief noch keine, der Rechner läuft aber erst seit {1} - zu kurz für einen Befund. Später noch einmal prüfen.'
    idleChecking = 'die anderen leerlaufgebundenen Aufgaben werden gelesen ...'
    logIdleChk = 'Leerlaufprüfung: {0}'
    staleSame  = 'Die Startaufgabe führt eine andere Fassung derselben Version {0} aus {1} aus.'
    noteIdle   = 'Wiederherstellungspunkte entstehen nur, wenn das System im Leerlauf ist. Wird der Rechner gerade benutzt oder ist er ausgeschaltet, verschiebt sich der Lauf — ein Termin kann dadurch auch ganz ausfallen. Die eingestellte Häufigkeit ist deshalb ein frühestmöglicher Abstand, keine Garantie. Mit „Schnappschuss jetzt erstellen“ ganz oben lässt sich jederzeit ein Punkt erzwingen.'

    grpPoints  = 'Wiederherstellungspunkte'
    lblCount   = 'Anzahl'
    lblOldest  = 'Ältester Punkt'
    lblStorage = 'Speicher auf Laufwerk'
    stUsed     = 'belegt'
    stAlloc    = 'reserviert'
    stMax      = 'Grenze'
    stNoAdmin  = 'nicht abrufbar (Administratorrechte erforderlich)'
    noteStore  = 'Windows weist den belegten Speicher nur für das gesamte Laufwerk aus, nicht je einzelnem Punkt — die Punkte teilen sich einen gemeinsamen Differenzbereich.'
    tipStore   = 'Belegt = tatsächlich von Schattenkopien beschriebene Daten.' + [Environment]::NewLine +
                 'Reserviert = Platz, den VSS bereits auf der Platte abgesteckt hat. Er steht anderen Dateien nicht mehr zur Verfügung, ist aber noch nicht vollständig gefüllt.' + [Environment]::NewLine +
                 'Grenze = konfigurierte Obergrenze; darüber hinaus wächst der Bereich nicht.'
    noteVolume = 'Erfasst wird ausschließlich das Windows-Laufwerk {0}. Weitere Partitionen und weitere Festplatten bleiben außen vor — auch wenn sie auf derselben physischen Platte liegen. Sie werden weder gesichert noch bei einer Wiederherstellung zurückgesetzt; für Daten dort ist weiterhin eine eigene Sicherung nötig. Auch die Speichergrenze weiter unten gilt allein für {0}. Die Punkte liegen zudem auf genau dem Laufwerk, das sie schützen: Eine defekte Platte nimmt sie mit. Die Zeitpunktwiederherstellung ist die Antwort auf ein missglücktes Update oder einen fehlerhaften Treiber, nicht auf Hardwaredefekt, Diebstahl oder Verschlüsselungstrojaner - eine Sicherung ersetzt sie nicht.'

    colTime    = 'Zeitpunkt'
    colAge     = 'Alter'
    colStatus  = 'Status'
    colBuild   = 'Build'
    colDur     = 'Dauer'
    histHint   = 'Windows hält nicht fest, wie lange ein Schnappschuss gedauert hat, solange der Aufgabenverlauf abgeschaltet ist. Er protokolliert jede geplante Aufgabe dieses Rechners und erfasst nur Läufe ab dem Einschalten.'
    btnHist    = 'Aufgabenverlauf einschalten'
    askHist    = 'Den Aufgabenverlauf einschalten? Das ist eine systemweite Windows-Einstellung: Ab dann wird jede geplante Aufgabe dieses Rechners in einen 10-MB-Ringpuffer protokolliert. Vorhandene Wiederherstellungspunkte bekommen weiterhin keine Dauer, nur die Läufe ab jetzt.'
    askHistT   = 'Aufgabenverlauf'
    logHistOn  = 'Aufgabenverlauf eingeschaltet. Die Dauer erscheint ab dem nächsten Lauf.'
    logHistErr = 'Der Aufgabenverlauf ließ sich nicht einschalten.'
    askCopy    = 'Diese Datei liegt auf einer Netzwerkfreigabe oder einem Wechseldatenträger. Die Aufgabe läuft als SYSTEM und erreicht das Netzwerk als Computerkonto, nicht als du selbst - deshalb scheitert ein Startschnappschuss von einer Freigabe meist, obwohl sie sich für dich problemlos öffnen lässt.{0}{0}Die Datei nach {1} kopieren und die Aufgabe von dort aus einrichten?{0}{0}Ja: kopieren und die lokale Datei verwenden. Nein: trotzdem mit dem jetzigen Pfad einrichten. Abbrechen: nicht einrichten.'
    askCopyT   = 'Startschnappschuss'
    logCopyOk  = 'Nach {0} kopiert - die Aufgabe verwendet diese Datei.'
    loading    = 'wird gelesen...'
    staleOld   = 'Die Startaufgabe führt weiterhin Version {0} aus {1} aus. Diese hier ist {2}.'
    staleGone  = 'Die Startaufgabe zeigt auf {0}, und diese Datei gibt es nicht mehr.'
    btnAutoUpd = 'Kopie aktualisieren'
    logAutoUpd = 'Kopie aktualisiert: In {0} liegt jetzt Version {1}.'
    stShadowOk = 'Schattenkopie vorhanden'
    stRegOnly  = 'nur Registry-Eintrag'
    stUnknown  = 'unbekannt (Adminrechte nötig)'

    grpSet     = 'Einstellungen'
    capActive  = 'Feature aktiv'
    capFreq    = 'Häufigkeit — Abstand zwischen Wiederherstellungspunkten'
    capReten   = 'Aufbewahrung — Lebensdauer eines Wiederherstellungspunkts'
    capSize    = 'Maximaler Speicherplatz für alle Wiederherstellungspunkte'

    optNoOver  = 'Windows-Standard (nicht überschreiben)'
    optOn      = 'Ein'
    optOff     = 'Aus'
    optStdFreq = 'Windows-Standard (24 Stunden)'
    optStdRet  = 'Windows-Standard (3 Tage / 72 Stunden)'
    unitHour   = 'Stunde'
    unitHours  = 'Stunden'
    unitDay    = 'Tag'
    unitDays   = 'Tage'
    unitMin    = 'Minuten'
    unitMin1   = 'Minute'
    unitMinShort = 'Min.'
    unitHourShort = 'Std.'

    btnReset   = 'Alles zurücksetzen'
    btnRefresh = 'Aktualisieren'
    btnApply   = 'Übernehmen'
    btnApplyNow= 'Übernehmen und sofort ausführen'
    btnSnapNow = 'Schnappschuss jetzt erstellen'
    snapHint   = 'Erzeugt sofort einen Wiederherstellungspunkt, unabhängig vom Zeitplan. Die Einstellungen unten bleiben unberührt.'
    tipSnapNow = 'Führt PITRTask einmal aus, auch während der Rechner benutzt wird. An der Konfiguration ändert sich nichts.'
    chkAuto    = 'Bei jedem Systemstart'
    autoHint   = 'Windows fordert beim Start von sich aus einen Punkt an, doch die Anforderung wartet auf den Leerlauf - und ein frisch gestarteter Rechner ist alles andere als das. Dies erzwingt sie.'
    tipAuto    = 'Richtet eine geplante Aufgabe ein, die die gewählte Anzahl Minuten nach jedem Systemstart einen Wiederherstellungspunkt anlegt. Läuft als SYSTEM, eine Anmeldung ist nicht nötig.'
    logAutoOn  = 'Startschnappschuss eingerichtet: {0} Minuten nach dem Start.'
    logAutoOff = 'Startschnappschuss entfernt.'
    warnPath   = 'Diese Datei liegt nicht auf einem festen lokalen Laufwerk. Die Aufgabe merkt sich den Pfad und erreicht ihn beim Start womöglich nicht.'
    grpLog     = 'Protokoll'

    effective  = 'Aktuell wirksam'
    source     = 'Quelle'
    winDefault = 'Windows-Standard'
    srcGPO     = 'Richtlinie (dieses Werkzeug)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'Einstellungen-App'
    sizeStd    = 'Windows-Standard (2% der Platte)'

    carryOver  = 'stammt noch aus der vorherigen Einstellung; wird beim nächsten Lauf angepasst auf'
    proven72   = 'älter als 72 Stunden: die erweiterte Aufbewahrung wirkt nachweislich'
    unofficial = 'Inoffizielle Lösung: Die hier gesetzten Konfigurationswerte sind von Microsoft nicht dokumentiert und können sich mit künftigen Windows-Versionen ändern. „Alles zurücksetzen“ stellt jederzeit den Windows-Standard wieder her.'
    taskMissing= 'PITRTask nicht gefunden'
    unknownTxt = 'unbekannt'

    logReady   = 'Bereit. Werte werden auf Level "Richtlinie" gesetzt und haben Vorrang vor der Einstellungen-App.'
    logNoAdmin = 'WARNUNG: Ohne Administratorrechte lassen sich keine Werte speichern.'
    logRefresh = 'Ansicht aktualisiert.'
    logSaved   = 'Gespeichert. Wirksam beim nächsten Lauf von PITRTask (der läuft nur im Leerlauf).'
    logCleared = 'Überschreibung entfernt -> Windows-Standard'
    logIdleOff = 'Leerlauf-Bedingung vorübergehend aufgehoben.'
    logStarted = 'PITRTask gestartet, warte auf Abschluss...'
    logIdleOn  = 'Leerlauf-Bedingung wiederhergestellt.'
    logIdleErr = 'Leerlauf-Bedingung nach Fehler wiederhergestellt.'
    logIdleBad = 'WARNUNG: Leerlauf-Bedingung konnte nicht wiederhergestellt werden!'
    logDone    = 'Fertig. Ergebnis'
    logNextRun = 'nächster Lauf'
    logTook    = 'Dauer {0}'
    logNoFinish= 'läuft nach {0} noch - der Punkt wird im Hintergrund fertiggestellt.'
    logRemoved = 'entfernt'
    logNothing = 'Es waren keine Werte gesetzt.'
    logError   = 'Fehler'
    askReset   = 'Alle von diesem Werkzeug gesetzten Werte entfernen und zum Windows-Standard zurückkehren?'
    askResetT  = 'Zurücksetzen'
    capWinRE   = 'Wiederherstellungsumgebung:'
    winreOn    = 'vorhanden'
    winreOff   = 'abgeschaltet'
    winreUnk   = 'nicht ermittelbar'
    winreFree  = 'frei'
    noteWinRE  = 'Ohne Wiederherstellungsumgebung lässt sich kein Wiederherstellungspunkt anwenden - das Zurückrollen läuft von dort und nicht aus Windows heraus. Ein „reagentc /enable“ mit Administratorrechten stellt sie meist wieder her.'
    btnWinRE   = 'Neustart zur Wiederherstellung'
    tipWinRE   = 'Startet Windows in die Wiederherstellungsumgebung, in der sich ein Wiederherstellungspunkt anwenden lässt. Nicht Gespeichertes in anderen Programmen geht verloren.'
    askWinRE   = 'Jetzt in die Wiederherstellungsumgebung neu starten? Nicht gespeicherte Arbeit in anderen Programmen geht verloren.'
    askWinRET  = 'Neustart'
    logWinRE   = 'Neustart in die Wiederherstellungsumgebung...'
    btnCopy    = 'Zustand kopieren'
    copyHint   = 'Kopiert Edition, Einstellungen samt Quelle, Aufgabenstatus und Wiederherstellungspunkte als Text - für einen Forenbeitrag oder eine Fehlermeldung.'
    tipCopy    = 'Kopiert den aktuellen Zustand als Klartext in die Zwischenablage - Edition, Einstellungen samt Quelle, Aufgabenstatus, Wiederherstellungspunkte und Speicher. Gemacht für einen Forenbeitrag oder eine Fehlermeldung.'
    logCopied  = 'Zustand in die Zwischenablage kopiert.'
}

# ------------------------------------------------------------------ French --
# Apostrophes here are plain ASCII and doubled, because that is how a single-quoted
# PowerShell string escapes one. Do NOT "fix" them to the typographic U+2019: Windows
# PowerShell 5.1 treats the curly quote as a string delimiter just like the straight one,
# so a single U+2019 silently ends the string and the whole file stops parsing.
fr = @{
    winTitle   = 'Point-in-time restore'
    headline   = 'Point-in-time restore'
    subtitle   = 'Restauration à un instant donné (PITR)'
    intro      = 'Windows ne propose la fréquence et la conservation que sur l''édition Enterprise. Cet outil les écrit directement dans la configuration du moteur PITR, qui ne vérifie pas l''édition.'
    lnkGuide   = 'Guide'
    tipProject = 'Ouvrir la page du projet sur GitHub'
    tipGuide   = 'Ouvrir le guide rapide dans le navigateur'
    updAvail   = 'La version {0} est disponible - ouvrir la page de la version'
    tipUpdate  = 'Ouvre la page de téléchargement dans le navigateur. Rien n''est téléchargé ni installé automatiquement.'

    grpState   = 'État actuel'
    capEdition = 'Édition de Windows :'
    capLast    = 'Dernière exécution :'
    capNext    = 'Prochaine exécution :'
    capDelta   = 'Intervalle planifié :'
    capTaskSt  = 'État de la tâche :'
    tsReady    = 'prête'
    tsQueued   = 'en attente d''une période d''inactivité du système'
    tsRunning  = 'en cours d''exécution'
    tsDisabled = 'désactivée'
    tsOverdue  = 'en retard de'
    missedRuns = 'exécutions manquées : {0}'
    btnIdleChk = 'Vérifier l''inactivité'
    idlePartial = ' Compté sans droits d''administrateur : seules les tâches visibles pour ce compte sont incluses.'
    idleBanner = '{0} exécutions ont été manquées. C''est normal tant que la machine est utilisée - mais cela peut aussi signifier que Windows ne signale plus aucune inactivité.'
    idleBlocked = 'Windows ne signale plus aucune inactivité depuis {0}. Depuis, aucune des {1} autres tâches liées à l''inactivité ne s''est exécutée : cela dépasse donc largement les instantanés. En général, un programme ou un pilote maintient le système éveillé - "powercfg /requests" dans une invite de commandes avec droits d''administrateur le nomme.'
    idleFine   = 'La détection d''inactivité fonctionne : {0} des {1} autres tâches liées à l''inactivité se sont exécutées depuis le démarrage, la dernière à {2}. La machine était simplement utilisée aux heures prévues.'
    idleEarly  = 'Aucune des {0} autres tâches liées à l''inactivité ne s''est encore exécutée, mais le système ne fonctionne que depuis {1} - trop peu pour conclure. À revérifier plus tard.'
    idleChecking = 'lecture des autres tâches liées à l''inactivité ...'
    logIdleChk = 'Vérification de l''inactivité : {0}'
    staleSame  = 'La tâche de démarrage exécute une autre build de cette même version {0} depuis {1}.'
    noteIdle   = 'Les points de restauration ne sont créés que lorsque le système est inactif. Si la machine est utilisée ou éteinte, l''exécution est reportée — et un créneau planifié peut être ignoré entièrement. La fréquence configurée est donc un intervalle minimal, pas une garantie. « Créer un instantané maintenant », tout en haut, force un point à tout moment.'

    grpPoints  = 'Points de restauration'
    lblCount   = 'Nombre'
    lblOldest  = 'Point le plus ancien'
    lblStorage = 'Stockage sur le lecteur'
    stUsed     = 'utilisé'
    stAlloc    = 'réservé'
    stMax      = 'limite'
    stNoAdmin  = 'indisponible (droits d''administrateur requis)'
    noteStore  = 'Windows ne rapporte le stockage que par lecteur, jamais par point — tous les points partagent une même zone de différences.'
    tipStore   = 'Utilisé = données réellement écrites par les clichés instantanés.' + [Environment]::NewLine +
                 'Réservé = espace que VSS a déjà réservé sur le disque. Il n''est plus disponible pour d''autres fichiers, mais il n''est pas encore rempli.' + [Environment]::NewLine +
                 'Limite = plafond configuré ; la zone ne dépasse jamais cette valeur.'
    noteVolume = 'Seul le lecteur Windows {0} est pris en compte. Les autres partitions et les autres disques sont exclus — même s''ils se trouvent sur le même disque physique. Ils ne sont ni capturés ni restaurés, les données qui s''y trouvent ont donc toujours besoin de leur propre sauvegarde. La limite de stockage ci-dessous s''applique elle aussi uniquement à {0}. Les points se trouvent de plus sur le disque même qu''ils protègent : un disque défaillant les emporte. La restauration à un instant donné répond à une mise à jour ratée ou à un pilote défectueux, pas à une panne matérielle, un vol ou un rançongiciel - elle ne remplace pas une sauvegarde.'

    colTime    = 'Date et heure'
    colAge     = 'Âge'
    colStatus  = 'État'
    colBuild   = 'Build'
    colDur     = 'Durée'
    histHint   = 'Windows n''enregistre pas la durée d''un instantané tant que l''historique du planificateur de tâches est désactivé. Celui-ci journalise toutes les tâches planifiées de la machine et ne couvre que les exécutions à partir de son activation.'
    btnHist    = 'Activer l''historique'
    askHist    = 'Activer l''historique du planificateur de tâches ? Il s''agit d''un réglage global de Windows : toutes les tâches planifiées de cette machine seront journalisées dans un tampon circulaire de 10 Mo. Les points de restauration existants n''auront toujours pas de durée.'
    askHistT   = 'Historique des tâches'
    logHistOn  = 'Historique activé. La durée apparaîtra à partir de la prochaine exécution.'
    logHistErr = 'Impossible d''activer l''historique des tâches.'
    askCopy    = 'Ce fichier se trouve sur un partage réseau ou un support amovible. La tâche s''exécute en tant que SYSTEM et atteint le réseau via le compte d''ordinateur, pas via votre compte - c''est pourquoi un instantané au démarrage depuis un partage échoue le plus souvent, même si le partage s''ouvre sans problème.{0}{0}Copier le fichier vers {1} et enregistrer la tâche à partir de là ?{0}{0}Oui : copier et utiliser le fichier local. Non : enregistrer malgré tout avec le chemin actuel. Annuler : ne pas enregistrer.'
    askCopyT   = 'Instantané au démarrage'
    logCopyOk  = 'Copié vers {0} - la tâche utilise ce fichier.'
    loading    = 'lecture...'
    staleOld   = 'La tâche de démarrage exécute encore la version {0} depuis {1}. Celle-ci est la {2}.'
    staleGone  = 'La tâche de démarrage pointe vers {0}, et ce fichier n''existe plus.'
    btnAutoUpd = 'Actualiser la copie'
    logAutoUpd = 'Copie actualisée : {0} contient désormais la version {1}.'
    stShadowOk = 'cliché instantané présent'
    stRegOnly  = 'entrée de registre uniquement'
    stUnknown  = 'inconnu (droits d''administrateur requis)'

    grpSet     = 'Paramètres'
    capActive  = 'Fonctionnalité activée'
    capFreq    = 'Fréquence — intervalle entre les points de restauration'
    capReten   = 'Conservation — durée de vie d''un point de restauration'
    capSize    = 'Espace maximal pour tous les points de restauration'

    optNoOver  = 'Valeur par défaut de Windows (ne pas remplacer)'
    optOn      = 'Activé'
    optOff     = 'Désactivé'
    optStdFreq = 'Valeur par défaut de Windows (24 heures)'
    optStdRet  = 'Valeur par défaut de Windows (3 jours / 72 heures)'
    unitHour   = 'heure'
    unitHours  = 'heures'
    unitDay    = 'jour'
    unitDays   = 'jours'
    unitMin    = 'minutes'
    unitMin1   = 'minute'
    unitMinShort = 'min'
    unitHourShort = 'h'

    btnReset   = 'Tout réinitialiser'
    btnRefresh = 'Actualiser'
    btnApply   = 'Appliquer'
    btnApplyNow= 'Appliquer et exécuter maintenant'
    btnSnapNow = 'Créer un instantané maintenant'
    snapHint   = 'Crée immédiatement un point de restauration, indépendamment de la planification. Les réglages ci-dessous restent inchangés.'
    tipSnapNow = 'Exécute PITRTask une fois, même pendant l''utilisation de la machine. Rien n''est écrit dans la configuration.'
    chkAuto    = 'À chaque démarrage du système'
    autoHint   = 'Windows demande de lui-même un point au démarrage, mais cette demande attend l''inactivité - et une machine qui vient de démarrer est tout sauf inactive. Ceci la force.'
    tipAuto    = 'Enregistre une tâche planifiée qui crée un point de restauration le nombre de minutes choisi après chaque démarrage. S''exécute en tant que SYSTEM, sans ouverture de session.'
    logAutoOn  = 'Instantané de démarrage enregistré : {0} minutes après le démarrage.'
    logAutoOff = 'Instantané de démarrage supprimé.'
    warnPath   = 'Ce fichier ne se trouve pas sur un disque local fixe. La tâche mémorise son chemin et pourrait ne pas l''atteindre au démarrage.'
    grpLog     = 'Journal'

    effective  = 'Actuellement appliqué'
    source     = 'source'
    winDefault = 'Valeur par défaut de Windows'
    srcGPO     = 'stratégie (cet outil)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'application Paramètres'
    sizeStd    = 'Valeur par défaut de Windows (2% du disque)'

    carryOver  = 'provient encore du réglage précédent ; sera ajusté à la prochaine exécution sur'
    proven72   = 'plus de 72 heures : la conservation étendue fonctionne de manière démontrable'
    unofficial = 'Solution non officielle : les valeurs de configuration écrites ici ne sont pas documentées par Microsoft et peuvent changer avec de futures versions de Windows. « Tout réinitialiser » rétablit à tout moment la valeur par défaut de Windows.'
    taskMissing= 'PITRTask introuvable'
    unknownTxt = 'inconnu'

    logReady   = 'Prêt. Les valeurs sont écrites au niveau stratégie et priment sur l''application Paramètres.'
    logNoAdmin = 'AVERTISSEMENT : sans droits d''administrateur, aucune valeur ne peut être enregistrée.'
    logRefresh = 'Vue actualisée.'
    logSaved   = 'Enregistré. Prend effet à la prochaine exécution de PITRTask (qui ne s''exécute qu''au repos).'
    logCleared = 'remplacement supprimé -> valeur par défaut de Windows'
    logIdleOff = 'Condition d''inactivité temporairement levée.'
    logStarted = 'PITRTask démarrée, en attente de la fin...'
    logIdleOn  = 'Condition d''inactivité rétablie.'
    logIdleErr = 'Condition d''inactivité rétablie après une erreur.'
    logIdleBad = 'AVERTISSEMENT : impossible de rétablir la condition d''inactivité !'
    logDone    = 'Terminé. Résultat'
    logNextRun = 'prochaine exécution'
    logTook    = 'durée {0}'
    logNoFinish= 'toujours en cours après {0} - le point se termine en arrière-plan.'
    logRemoved = 'supprimé'
    logNothing = 'Aucune valeur n''était définie.'
    logError   = 'Erreur'
    askReset   = 'Supprimer toutes les valeurs définies par cet outil et revenir à la valeur par défaut de Windows ?'
    askResetT  = 'Réinitialiser'
    capWinRE   = 'Environnement de récupération :'
    winreOn    = 'présent'
    winreOff   = 'désactivé'
    winreUnk   = 'indéterminable'
    winreFree  = 'libres'
    noteWinRE  = 'Sans environnement de récupération, aucun point de restauration ne peut être appliqué : la restauration s''exécute depuis cet environnement, pas depuis Windows. Un « reagentc /enable » avec des droits d''administrateur le rétablit en général.'
    btnWinRE   = 'Redémarrer vers la récupération'
    tipWinRE   = 'Redémarre Windows dans l''environnement de récupération, où un point de restauration peut être appliqué. Le travail non enregistré dans les autres programmes est perdu.'
    askWinRE   = 'Redémarrer maintenant dans l''environnement de récupération ? Le travail non enregistré dans les autres programmes sera perdu.'
    askWinRET  = 'Redémarrage'
    logWinRE   = 'Redémarrage dans l''environnement de récupération...'
    btnCopy    = 'Copier l''état'
    copyHint   = 'Copie l''édition, les réglages avec leur source, l''état de la tâche et les points de restauration en texte - pour un message de forum ou un rapport d''erreur.'
    tipCopy    = 'Copie l''état actuel en texte brut dans le presse-papiers : édition, réglages avec leur source, état de la tâche, points de restauration et stockage. Prévu pour un message de forum ou un rapport d''erreur.'
    logCopied  = 'État copié dans le presse-papiers.'
}

# ----------------------------------------------------------------- Spanish --
es = @{
    winTitle   = 'Point-in-time restore'
    headline   = 'Point-in-time restore'
    subtitle   = 'Restauración a un momento anterior (PITR)'
    intro      = 'Windows solo ofrece la frecuencia y la conservación en la edición Enterprise. Esta herramienta las escribe directamente en la configuración del motor PITR, que no comprueba la edición.'
    lnkGuide   = 'Guía'
    tipProject = 'Abrir la página del proyecto en GitHub'
    tipGuide   = 'Abrir la guía breve en el navegador'
    updAvail   = 'La versión {0} está disponible - abrir la página de la versión'
    tipUpdate  = 'Abre la página de descarga en el navegador. No se descarga ni se instala nada automáticamente.'

    grpState   = 'Estado actual'
    capEdition = 'Edición de Windows:'
    capLast    = 'Última ejecución:'
    capNext    = 'Próxima ejecución:'
    capDelta   = 'Intervalo programado:'
    capTaskSt  = 'Estado de la tarea:'
    tsReady    = 'lista'
    tsQueued   = 'esperando a que el sistema esté inactivo'
    tsRunning  = 'en ejecución'
    tsDisabled = 'desactivada'
    tsOverdue  = 'retrasada'
    missedRuns = 'ejecuciones omitidas: {0}'
    btnIdleChk = 'Comprobar inactividad'
    idlePartial = ' Contado sin permisos de administrador: solo se incluyen las tareas visibles para esta cuenta.'
    idleBanner = 'Se omitieron {0} ejecuciones. Es normal mientras se usa el equipo, pero también puede significar que Windows ya no informa de ninguna inactividad.'
    idleBlocked = 'Windows no informa de inactividad desde {0}. Desde entonces no se ha ejecutado ninguna de las otras {1} tareas ligadas a la inactividad, así que esto va mucho más allá de las instantáneas. Normalmente un programa o un controlador mantiene el sistema despierto: "powercfg /requests" en un símbolo del sistema con permisos lo indica.'
    idleFine   = 'La detección de inactividad funciona: {0} de las otras {1} tareas ligadas a la inactividad se han ejecutado desde el arranque, la última a las {2}. El equipo simplemente estaba en uso a las horas previstas.'
    idleEarly  = 'Todavía no se ha ejecutado ninguna de las otras {0} tareas ligadas a la inactividad, pero el sistema solo lleva {1} encendido: demasiado poco para concluir nada. Conviene volver a comprobarlo más tarde.'
    idleChecking = 'leyendo las otras tareas ligadas a la inactividad ...'
    logIdleChk = 'Comprobación de inactividad: {0}'
    staleSame  = 'La tarea de inicio ejecuta otra compilación de esta misma versión {0} desde {1}.'
    noteIdle   = 'Los puntos de restauración solo se crean cuando el sistema está inactivo. Si el equipo se está usando o está apagado, la ejecución se aplaza — y una cita programada puede omitirse por completo. Por eso la frecuencia configurada es el intervalo mínimo posible, no una garantía. Con «Crear instantánea ahora», arriba del todo, se puede forzar un punto en cualquier momento.'

    grpPoints  = 'Puntos de restauración'
    lblCount   = 'Cantidad'
    lblOldest  = 'Punto más antiguo'
    lblStorage = 'Almacenamiento en la unidad'
    stUsed     = 'en uso'
    stAlloc    = 'reservado'
    stMax      = 'límite'
    stNoAdmin  = 'no disponible (se requieren permisos de administrador)'
    noteStore  = 'Windows informa del almacenamiento por unidad, nunca por punto — todos los puntos comparten una misma área de diferencias.'
    tipStore   = 'En uso = datos realmente escritos por las instantáneas.' + [Environment]::NewLine +
                 'Reservado = espacio que VSS ya ha reclamado en el disco. Deja de estar disponible para otros archivos, pero todavía no está lleno.' + [Environment]::NewLine +
                 'Límite = tope configurado; el área no crece más allá.'
    noteVolume = 'Solo se incluye la unidad de Windows {0}. Otras particiones y otros discos quedan fuera — incluso si están en el mismo disco físico. No se capturan ni se revierten en una restauración, así que los datos que haya allí siguen necesitando su propia copia de seguridad. El límite de almacenamiento de abajo también se aplica únicamente a {0}. Además, los puntos están en la misma unidad que protegen: un disco averiado se los lleva. La restauración a un momento anterior responde a una actualización fallida o a un controlador defectuoso, no a una avería de hardware, un robo o un ransomware: no sustituye a una copia de seguridad.'

    colTime    = 'Fecha y hora'
    colAge     = 'Antigüedad'
    colStatus  = 'Estado'
    colBuild   = 'Compilación'
    colDur     = 'Duración'
    histHint   = 'Windows no registra cuánto tardó una instantánea mientras el historial del Programador de tareas esté desactivado. Este registra todas las tareas programadas del equipo y solo cubre las ejecuciones a partir de su activación.'
    btnHist    = 'Activar el historial'
    askHist    = '¿Activar el historial del Programador de tareas? Es un ajuste de todo el sistema: a partir de entonces se registrará cada tarea programada de este equipo en un búfer circular de 10 MB. Los puntos de restauración existentes seguirán sin duración.'
    askHistT   = 'Historial de tareas'
    logHistOn  = 'Historial activado. La duración aparecerá a partir de la siguiente ejecución.'
    logHistErr = 'No se pudo activar el historial de tareas.'
    askCopy    = 'Este archivo está en un recurso compartido de red o en una unidad extraíble. La tarea se ejecuta como SYSTEM y accede a la red con la cuenta de equipo, no con la suya, por eso una instantánea de inicio desde un recurso compartido suele fallar aunque este se abra sin problemas.{0}{0}¿Copiar el archivo a {1} y registrar la tarea desde ahí?{0}{0}Sí: copiar y usar el archivo local. No: registrar de todos modos con la ruta actual. Cancelar: no registrar.'
    askCopyT   = 'Instantánea de inicio'
    logCopyOk  = 'Copiado a {0}: la tarea usa ese archivo.'
    loading    = 'leyendo...'
    staleOld   = 'La tarea de inicio sigue ejecutando la versión {0} desde {1}. Esta es la {2}.'
    staleGone  = 'La tarea de inicio apunta a {0}, y ese archivo ya no existe.'
    btnAutoUpd = 'Actualizar la copia'
    logAutoUpd = 'Copia actualizada: en {0} está ahora la versión {1}.'
    stShadowOk = 'instantánea presente'
    stRegOnly  = 'solo entrada del registro'
    stUnknown  = 'desconocido (se requieren permisos de administrador)'

    grpSet     = 'Configuración'
    capActive  = 'Función activada'
    capFreq    = 'Frecuencia — intervalo entre puntos de restauración'
    capReten   = 'Conservación — vida útil de un punto de restauración'
    capSize    = 'Espacio máximo para todos los puntos de restauración'

    optNoOver  = 'Valor predeterminado de Windows (no sobrescribir)'
    optOn      = 'Activado'
    optOff     = 'Desactivado'
    optStdFreq = 'Valor predeterminado de Windows (24 horas)'
    optStdRet  = 'Valor predeterminado de Windows (3 días / 72 horas)'
    unitHour   = 'hora'
    unitHours  = 'horas'
    unitDay    = 'día'
    unitDays   = 'días'
    unitMin    = 'minutos'
    unitMin1   = 'minuto'
    unitMinShort = 'min'
    unitHourShort = 'h'

    btnReset   = 'Restablecer todo'
    btnRefresh = 'Actualizar'
    btnApply   = 'Aplicar'
    btnApplyNow= 'Aplicar y ejecutar ahora'
    btnSnapNow = 'Crear instantánea ahora'
    snapHint   = 'Crea de inmediato un punto de restauración, al margen de la programación. Los ajustes de abajo quedan intactos.'
    tipSnapNow = 'Ejecuta PITRTask una vez, incluso mientras el equipo está en uso. No se escribe nada en la configuración.'
    chkAuto    = 'En cada inicio del sistema'
    autoHint   = 'Windows pide por sí mismo un punto al arrancar, pero esa petición espera a que el sistema esté inactivo, y un equipo recién arrancado no lo está. Esto la fuerza.'
    tipAuto    = 'Registra una tarea programada que crea un punto de restauración los minutos elegidos después de cada inicio. Se ejecuta como SYSTEM, sin necesidad de iniciar sesión.'
    logAutoOn  = 'Instantánea de inicio registrada: {0} minutos después del arranque.'
    logAutoOff = 'Instantánea de inicio eliminada.'
    warnPath   = 'Este archivo no está en una unidad local fija. La tarea guarda su ruta y puede no alcanzarla al arrancar.'
    grpLog     = 'Registro'

    effective  = 'Actualmente en vigor'
    source     = 'origen'
    winDefault = 'Valor predeterminado de Windows'
    srcGPO     = 'directiva (esta herramienta)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'app Configuración'
    sizeStd    = 'Valor predeterminado de Windows (2% del disco)'

    carryOver  = 'procede todavía del ajuste anterior; se corregirá en la próxima ejecución a'
    proven72   = 'más de 72 horas: la conservación ampliada funciona de forma demostrable'
    unofficial = 'Solución no oficial: los valores de configuración que se escriben aquí no están documentados por Microsoft y pueden cambiar en futuras versiones de Windows. «Restablecer todo» devuelve el valor predeterminado de Windows en cualquier momento.'
    taskMissing= 'PITRTask no encontrada'
    unknownTxt = 'desconocido'

    logReady   = 'Listo. Los valores se escriben en el nivel de directiva y tienen prioridad sobre la app Configuración.'
    logNoAdmin = 'ADVERTENCIA: sin permisos de administrador no se puede guardar ningún valor.'
    logRefresh = 'Vista actualizada.'
    logSaved   = 'Guardado. Surtirá efecto en la próxima ejecución de PITRTask (que solo se ejecuta con el sistema inactivo).'
    logCleared = 'sobrescritura eliminada -> valor predeterminado de Windows'
    logIdleOff = 'Condición de inactividad suspendida temporalmente.'
    logStarted = 'PITRTask iniciada, esperando a que termine...'
    logIdleOn  = 'Condición de inactividad restaurada.'
    logIdleErr = 'Condición de inactividad restaurada tras un error.'
    logIdleBad = 'ADVERTENCIA: no se pudo restaurar la condición de inactividad.'
    logDone    = 'Terminado. Resultado'
    logNextRun = 'próxima ejecución'
    logTook    = 'duración {0}'
    logNoFinish= 'sigue en marcha tras {0} - el punto se completa en segundo plano.'
    logRemoved = 'eliminado'
    logNothing = 'No había ningún valor establecido.'
    logError   = 'Error'
    askReset   = '¿Eliminar todos los valores establecidos por esta herramienta y volver al valor predeterminado de Windows?'
    askResetT  = 'Restablecer'
    capWinRE   = 'Entorno de recuperación:'
    winreOn    = 'presente'
    winreOff   = 'desactivado'
    winreUnk   = 'no determinable'
    winreFree  = 'libres'
    noteWinRE  = 'Sin el entorno de recuperación no se puede aplicar ningún punto de restauración: la reversión se ejecuta desde ahí, no desde dentro de Windows. Un «reagentc /enable» con derechos de administrador suele restablecerlo.'
    btnWinRE   = 'Reiniciar a recuperación'
    tipWinRE   = 'Reinicia Windows en el entorno de recuperación, donde se puede aplicar un punto de restauración. El trabajo sin guardar en otros programas se pierde.'
    askWinRE   = '¿Reiniciar ahora en el entorno de recuperación? El trabajo sin guardar en otros programas se perderá.'
    askWinRET  = 'Reinicio'
    logWinRE   = 'Reiniciando en el entorno de recuperación...'
    btnCopy    = 'Copiar el estado'
    copyHint   = 'Copia la edición, los ajustes con su origen, el estado de la tarea y los puntos de restauración como texto: para un mensaje de foro o un informe de error.'
    tipCopy    = 'Copia el estado actual como texto sin formato al portapapeles: edición, ajustes con su origen, estado de la tarea, puntos de restauración y almacenamiento. Pensado para un mensaje de foro o un informe de error.'
    logCopied  = 'Estado copiado al portapapeles.'
}

# -------------------------------------------------------------- Portuguese --
pt = @{
    winTitle   = 'Point-in-time restore'
    headline   = 'Point-in-time restore'
    subtitle   = 'Restauração para um ponto no tempo (PITR)'
    intro      = 'O Windows oferece frequência e retenção somente na edição Enterprise. Esta ferramenta grava esses valores diretamente na configuração do mecanismo PITR, que não verifica a edição.'
    lnkGuide   = 'Guia'
    tipProject = 'Abrir a página do projeto no GitHub'
    tipGuide   = 'Abrir o guia rápido no navegador'
    updAvail   = 'A versão {0} está disponível - abrir a página da versão'
    tipUpdate  = 'Abre a página de download no navegador. Nada é baixado nem instalado automaticamente.'

    grpState   = 'Estado atual'
    capEdition = 'Edição do Windows:'
    capLast    = 'Última execução:'
    capNext    = 'Próxima execução:'
    capDelta   = 'Intervalo agendado:'
    capTaskSt  = 'Status da tarefa:'
    tsReady    = 'pronta'
    tsQueued   = 'aguardando o sistema ficar ocioso'
    tsRunning  = 'em execução'
    tsDisabled = 'desativada'
    tsOverdue  = 'atrasada em'
    missedRuns = 'execuções perdidas: {0}'
    btnIdleChk = 'Verificar ociosidade'
    idlePartial = ' Contado sem direitos de administrador: só entram as tarefas visíveis para esta conta.'
    idleBanner = '{0} execuções foram perdidas. Isso é normal enquanto o computador está em uso - mas também pode significar que o Windows não informa mais nenhuma ociosidade.'
    idleBlocked = 'O Windows não informa ociosidade desde {0}. Desde então nenhuma das outras {1} tarefas ligadas à ociosidade foi executada, portanto isso vai muito além dos instantâneos. Normalmente um programa ou um driver mantém o sistema acordado: "powercfg /requests" em um prompt de comando com permissões o indica.'
    idleFine   = 'A detecção de ociosidade funciona: {0} das outras {1} tarefas ligadas à ociosidade foram executadas desde a inicialização, a última às {2}. O computador apenas estava em uso nos horários previstos.'
    idleEarly  = 'Nenhuma das outras {0} tarefas ligadas à ociosidade foi executada ainda, mas o sistema está ligado há apenas {1} - pouco demais para concluir algo. Vale verificar mais tarde.'
    idleChecking = 'lendo as outras tarefas ligadas à ociosidade ...'
    logIdleChk = 'Verificação de ociosidade: {0}'
    staleSame  = 'A tarefa de inicialização executa outra compilação desta mesma versão {0} de {1}.'
    noteIdle   = 'Os pontos de restauração só são criados quando o sistema está ocioso. Se o computador estiver em uso ou desligado, a execução é adiada — e um horário agendado pode ser pulado por completo. Por isso a frequência configurada é um intervalo mínimo, não uma garantia. "Criar instantâneo agora", no topo, força um ponto a qualquer momento.'

    grpPoints  = 'Pontos de restauração'
    lblCount   = 'Quantidade'
    lblOldest  = 'Ponto mais antigo'
    lblStorage = 'Armazenamento na unidade'
    stUsed     = 'em uso'
    stAlloc    = 'reservado'
    stMax      = 'limite'
    stNoAdmin  = 'indisponível (requer direitos de administrador)'
    noteStore  = 'O Windows informa o armazenamento apenas por unidade, nunca por ponto — todos os pontos compartilham uma mesma área de diferenças.'
    tipStore   = 'Em uso = dados realmente gravados pelas cópias de sombra.' + [Environment]::NewLine +
                 'Reservado = espaço que o VSS já reservou no disco. Ele deixa de estar disponível para outros arquivos, mas ainda não está preenchido.' + [Environment]::NewLine +
                 'Limite = teto configurado; a área nunca cresce além dele.'
    noteVolume = 'Apenas a unidade do Windows {0} é incluída. Outras partições e outros discos ficam de fora — mesmo quando estão no mesmo disco físico. Eles não são capturados nem revertidos em uma restauração, então os dados ali continuam precisando do próprio backup. O limite de armazenamento abaixo também vale somente para {0}. Além disso, os pontos ficam na mesma unidade que protegem: um disco com defeito os leva junto. A restauração a um ponto no tempo responde a uma atualização malsucedida ou a um driver defeituoso, não a uma falha de hardware, roubo ou ransomware - ela não substitui um backup.'

    colTime    = 'Data e hora'
    colAge     = 'Idade'
    colStatus  = 'Status'
    colBuild   = 'Build'
    colDur     = 'Duração'
    histHint   = 'O Windows não registra quanto tempo um instantâneo levou enquanto o histórico do Agendador de Tarefas estiver desativado. Ele registra todas as tarefas agendadas do computador e cobre apenas as execuções a partir da ativação.'
    btnHist    = 'Ativar o histórico'
    askHist    = 'Ativar o histórico do Agendador de Tarefas? É uma configuração de todo o sistema: a partir daí cada tarefa agendada deste computador é registrada em um buffer circular de 10 MB. Os pontos de restauração existentes continuam sem duração.'
    askHistT   = 'Histórico de tarefas'
    logHistOn  = 'Histórico ativado. A duração aparece a partir da próxima execução.'
    logHistErr = 'Não foi possível ativar o histórico de tarefas.'
    askCopy    = 'Este arquivo está em um compartilhamento de rede ou em uma unidade removível. A tarefa é executada como SYSTEM e acessa a rede com a conta de computador, não com a sua, por isso um instantâneo de inicialização a partir de um compartilhamento costuma falhar mesmo que ele abra normalmente.{0}{0}Copiar o arquivo para {1} e registrar a tarefa a partir de lá?{0}{0}Sim: copiar e usar o arquivo local. Não: registrar mesmo assim com o caminho atual. Cancelar: não registrar.'
    askCopyT   = 'Instantâneo de inicialização'
    logCopyOk  = 'Copiado para {0} - a tarefa usa esse arquivo.'
    loading    = 'lendo...'
    staleOld   = 'A tarefa de inicialização ainda executa a versão {0} de {1}. Esta aqui é a {2}.'
    staleGone  = 'A tarefa de inicialização aponta para {0}, e esse arquivo não existe mais.'
    btnAutoUpd = 'Atualizar a cópia'
    logAutoUpd = 'Cópia atualizada: em {0} está agora a versão {1}.'
    stShadowOk = 'cópia de sombra presente'
    stRegOnly  = 'apenas entrada no registro'
    stUnknown  = 'desconhecido (requer direitos de administrador)'

    grpSet     = 'Configurações'
    capActive  = 'Recurso ativado'
    capFreq    = 'Frequência — intervalo entre pontos de restauração'
    capReten   = 'Retenção — tempo de vida de um ponto de restauração'
    capSize    = 'Espaço máximo para todos os pontos de restauração'

    optNoOver  = 'Padrão do Windows (não substituir)'
    optOn      = 'Ativado'
    optOff     = 'Desativado'
    optStdFreq = 'Padrão do Windows (24 horas)'
    optStdRet  = 'Padrão do Windows (3 dias / 72 horas)'
    unitHour   = 'hora'
    unitHours  = 'horas'
    unitDay    = 'dia'
    unitDays   = 'dias'
    unitMin    = 'minutos'
    unitMin1   = 'minuto'
    unitMinShort = 'min'
    unitHourShort = 'h'

    btnReset   = 'Redefinir tudo'
    btnRefresh = 'Atualizar'
    btnApply   = 'Aplicar'
    btnApplyNow= 'Aplicar e executar agora'
    btnSnapNow = 'Criar instantâneo agora'
    snapHint   = 'Cria imediatamente um ponto de restauração, independentemente do agendamento. As configurações abaixo permanecem intactas.'
    tipSnapNow = 'Executa a PITRTask uma vez, mesmo com o computador em uso. Nada é gravado na configuração.'
    chkAuto    = 'A cada inicialização do sistema'
    autoHint   = 'O Windows pede um ponto na inicialização por conta própria, mas esse pedido espera o sistema ficar ocioso - e um computador recém-iniciado não está. Isto o força.'
    tipAuto    = 'Registra uma tarefa agendada que cria um ponto de restauração os minutos escolhidos após cada inicialização. É executada como SYSTEM, sem necessidade de logon.'
    logAutoOn  = 'Instantâneo de inicialização registrado: {0} minutos após a inicialização.'
    logAutoOff = 'Instantâneo de inicialização removido.'
    warnPath   = 'Este arquivo não está em uma unidade local fixa. A tarefa guarda o caminho dele e pode não alcançá-lo na inicialização.'
    grpLog     = 'Registro'

    effective  = 'Atualmente em vigor'
    source     = 'origem'
    winDefault = 'Padrão do Windows'
    srcGPO     = 'política (esta ferramenta)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'app Configurações'
    sizeStd    = 'Padrão do Windows (2% do disco)'

    carryOver  = 'ainda vem da configuração anterior; será ajustado na próxima execução para'
    proven72   = 'mais de 72 horas: a retenção estendida funciona comprovadamente'
    unofficial = 'Solução não oficial: os valores de configuração gravados aqui não são documentados pela Microsoft e podem mudar em versões futuras do Windows. "Redefinir tudo" restaura o padrão do Windows a qualquer momento.'
    taskMissing= 'PITRTask não encontrada'
    unknownTxt = 'desconhecido'

    logReady   = 'Pronto. Os valores são gravados no nível de política e têm prioridade sobre o app Configurações.'
    logNoAdmin = 'AVISO: sem direitos de administrador nenhum valor pode ser salvo.'
    logRefresh = 'Exibição atualizada.'
    logSaved   = 'Salvo. Terá efeito na próxima execução do PITRTask (que só roda com o sistema ocioso).'
    logCleared = 'substituição removida -> padrão do Windows'
    logIdleOff = 'Condição de ociosidade suspensa temporariamente.'
    logStarted = 'PITRTask iniciada, aguardando a conclusão...'
    logIdleOn  = 'Condição de ociosidade restaurada.'
    logIdleErr = 'Condição de ociosidade restaurada após um erro.'
    logIdleBad = 'AVISO: não foi possível restaurar a condição de ociosidade!'
    logDone    = 'Concluído. Resultado'
    logNextRun = 'próxima execução'
    logTook    = 'duração {0}'
    logNoFinish= 'ainda em execução após {0} - o ponto é concluído em segundo plano.'
    logRemoved = 'removido'
    logNothing = 'Nenhum valor estava definido.'
    logError   = 'Erro'
    askReset   = 'Remover todos os valores definidos por esta ferramenta e voltar ao padrão do Windows?'
    askResetT  = 'Redefinir'
    capWinRE   = 'Ambiente de recuperação:'
    winreOn    = 'presente'
    winreOff   = 'desativado'
    winreUnk   = 'não determinável'
    winreFree  = 'livres'
    noteWinRE  = 'Sem o ambiente de recuperação nenhum ponto de restauração pode ser aplicado: a reversão é executada a partir dele, não de dentro do Windows. Um "reagentc /enable" com direitos de administrador costuma restabelecê-lo.'
    btnWinRE   = 'Reiniciar para a recuperação'
    tipWinRE   = 'Reinicia o Windows no ambiente de recuperação, onde um ponto de restauração pode ser aplicado. O trabalho não salvo em outros programas é perdido.'
    askWinRE   = 'Reiniciar agora no ambiente de recuperação? O trabalho não salvo em outros programas será perdido.'
    askWinRET  = 'Reinício'
    logWinRE   = 'Reiniciando no ambiente de recuperação...'
    btnCopy    = 'Copiar o estado'
    copyHint   = 'Copia a edição, as configurações com a origem, o status da tarefa e os pontos de restauração como texto - para uma mensagem de fórum ou um relato de erro.'
    tipCopy    = 'Copia o estado atual como texto simples para a área de transferência: edição, configurações com a origem, status da tarefa, pontos de restauração e armazenamento. Feito para uma mensagem de fórum ou um relato de erro.'
    logCopied  = 'Estado copiado para a área de transferência.'
}

# ----------------------------------------------------------------- Italian --
# Apostrophes here are plain ASCII and doubled - see the note on the French block.
it = @{
    winTitle   = 'Point-in-time restore'
    headline   = 'Point-in-time restore'
    subtitle   = 'Ripristino a un punto nel tempo (PITR)'
    intro      = 'Windows offre frequenza e conservazione solo nell''edizione Enterprise. Questo strumento le scrive direttamente nella configurazione del motore PITR, che non verifica l''edizione.'
    lnkGuide   = 'Guida'
    tipProject = 'Apre la pagina del progetto su GitHub'
    tipGuide   = 'Apre la guida rapida nel browser'
    updAvail   = 'La versione {0} è disponibile - aprire la pagina della versione'
    tipUpdate  = 'Apre la pagina di download nel browser. Nulla viene scaricato o installato automaticamente.'

    grpState   = 'Stato attuale'
    capEdition = 'Edizione di Windows:'
    capLast    = 'Ultima esecuzione:'
    capNext    = 'Prossima esecuzione:'
    capDelta   = 'Intervallo pianificato:'
    capTaskSt  = 'Stato dell''attività:'
    tsReady    = 'pronta'
    tsQueued   = 'in attesa che il sistema sia inattivo'
    tsRunning  = 'in esecuzione'
    tsDisabled = 'disattivata'
    tsOverdue  = 'in ritardo di'
    missedRuns = 'esecuzioni saltate: {0}'
    btnIdleChk = 'Verifica inattività'
    idlePartial = ' Conteggiato senza privilegi di amministratore: sono incluse solo le attività visibili a questo account.'
    idleBanner = '{0} esecuzioni sono state saltate. È normale finché il computer è in uso, ma può anche significare che Windows non segnala più alcuna inattività.'
    idleBlocked = 'Windows non segnala inattività dal {0}. Da allora non è stata eseguita nessuna delle altre {1} attività legate all''inattività, quindi la cosa va ben oltre gli snapshot. Di solito un programma o un driver tiene sveglio il sistema: "powercfg /requests" in un prompt dei comandi con privilegi lo indica.'
    idleFine   = 'Il rilevamento dell''inattività funziona: {0} delle altre {1} attività legate all''inattività sono state eseguite dall''avvio, l''ultima alle {2}. Il computer era semplicemente in uso agli orari previsti.'
    idleEarly  = 'Nessuna delle altre {0} attività legate all''inattività è ancora stata eseguita, ma il sistema è acceso solo da {1}: troppo poco per trarre conclusioni. Meglio ricontrollare più tardi.'
    idleChecking = 'lettura delle altre attività legate all''inattività ...'
    logIdleChk = 'Verifica dell''inattività: {0}'
    staleSame  = 'L''attività di avvio esegue un''altra build di questa stessa versione {0} da {1}.'
    noteIdle   = 'I punti di ripristino vengono creati solo quando il sistema è inattivo. Se il computer è in uso o spento, l''esecuzione viene rinviata - e un appuntamento pianificato può saltare del tutto. La frequenza impostata è quindi un intervallo minimo, non una garanzia. Con «Crea subito un''istantanea», in alto, si può forzare un punto in qualsiasi momento.'

    grpPoints  = 'Punti di ripristino'
    lblCount   = 'Numero'
    lblOldest  = 'Punto più vecchio'
    lblStorage = 'Spazio sull''unità'
    stUsed     = 'in uso'
    stAlloc    = 'riservato'
    stMax      = 'limite'
    stNoAdmin  = 'non disponibile (sono necessari i diritti di amministratore)'
    noteStore  = 'Windows indica lo spazio solo per unità, mai per singolo punto - tutti i punti condividono una sola area comune di differenze.'
    tipStore   = 'In uso = dati effettivamente scritti dalle copie shadow.' + [Environment]::NewLine +
                 'Riservato = spazio che il servizio VSS ha già occupato sul disco. Non è più disponibile per altri file, ma non è ancora del tutto riempito.' + [Environment]::NewLine +
                 'Limite = tetto massimo configurato; l''area non cresce mai oltre.'
    noteVolume = 'Viene protetta solo l''unità di Windows {0}. Le altre partizioni e gli altri dischi restano esclusi - anche quando si trovano sullo stesso disco fisico. Non vengono né acquisiti né ripristinati, quindi i dati che vi si trovano hanno bisogno di un backup proprio. Anche il limite di spazio qui sotto vale solo per {0}. I punti si trovano inoltre sull''unità stessa che proteggono: un disco guasto se li porta via. Il ripristino a un punto nel tempo risponde a un aggiornamento mal riuscito o a un driver difettoso, non a un guasto hardware, a un furto o a un ransomware: non sostituisce un backup.'

    colTime    = 'Data e ora'
    colAge     = 'Età'
    colStatus  = 'Stato'
    colBuild   = 'Build'
    colDur     = 'Durata'
    histHint   = 'Windows non registra quanto è durata un''istantanea finché la cronologia dell''Utilità di pianificazione è disattivata. Questa registra ogni attività pianificata del computer e copre solo le esecuzioni successive all''attivazione.'
    btnHist    = 'Attivare la cronologia'
    askHist    = 'Attivare la cronologia dell''Utilità di pianificazione? È un''impostazione valida per tutto il sistema: da quel momento ogni attività pianificata di questo computer viene registrata in un buffer circolare da 10 MB. I punti di ripristino esistenti restano senza durata.'
    askHistT   = 'Cronologia delle attività'
    logHistOn  = 'Cronologia attivata. La durata compare dalla prossima esecuzione.'
    logHistErr = 'Non è stato possibile attivare la cronologia.'
    askCopy    = 'Questo file si trova su una condivisione di rete o su un''unità rimovibile. L''attività viene eseguita come SYSTEM e raggiunge la rete con l''account del computer, non con il tuo, perciò un''istantanea all''avvio da una condivisione di solito non riesce anche se la condivisione si apre senza problemi.{0}{0}Copiare il file in {1} e registrare l''attività da lì?{0}{0}Sì: copiare e usare il file locale. No: registrare comunque con il percorso attuale. Annulla: non registrare.'
    askCopyT   = 'Istantanea all''avvio'
    logCopyOk  = 'Copiato in {0} - l''attività usa quel file.'
    loading    = 'lettura...'
    staleOld   = 'L''attività di avvio esegue ancora la versione {0} da {1}. Questa è la {2}.'
    staleGone  = 'L''attività di avvio punta a {0}, e quel file non c''è più.'
    btnAutoUpd = 'Aggiorna la copia'
    logAutoUpd = 'Copia aggiornata: in {0} ora c''è la versione {1}.'
    stShadowOk = 'copia shadow presente'
    stRegOnly  = 'solo voce di registro'
    stUnknown  = 'sconosciuto (servono diritti di amministratore)'

    grpSet     = 'Impostazioni'
    capActive  = 'Funzione attivata'
    capFreq    = 'Frequenza - intervallo tra i punti di ripristino'
    capReten   = 'Conservazione - durata di un punto di ripristino'
    capSize    = 'Spazio massimo per tutti i punti di ripristino'

    optNoOver  = 'Impostazione predefinita di Windows (non modificare)'
    optOn      = 'Attivata'
    optOff     = 'Disattivata'
    optStdFreq = 'Impostazione predefinita di Windows (24 ore)'
    optStdRet  = 'Impostazione predefinita di Windows (3 giorni / 72 ore)'
    unitHour   = 'ora'
    unitHours  = 'ore'
    unitDay    = 'giorno'
    unitDays   = 'giorni'
    unitMin    = 'minuti'
    unitMin1   = 'minuto'
    unitMinShort = 'min'
    unitHourShort = 'h'

    btnReset   = 'Reimposta tutto'
    btnRefresh = 'Aggiorna'
    btnApply   = 'Applica'
    btnApplyNow= 'Applica ed esegui subito'
    btnSnapNow = 'Crea subito un''istantanea'
    snapHint   = 'Crea subito un punto di ripristino, indipendentemente dalla pianificazione. Le impostazioni qui sotto restano invariate.'
    tipSnapNow = 'Esegue PITRTask una volta, anche mentre il computer è in uso. Nella configurazione non viene scritto nulla.'
    chkAuto    = 'A ogni avvio del sistema'
    autoHint   = 'Windows chiede da solo un punto all''avvio, ma quella richiesta aspetta che il sistema sia inattivo - e un computer appena avviato non lo è. Questo la forza.'
    tipAuto    = 'Registra un''attività pianificata che crea un punto di ripristino dopo i minuti scelti a ogni avvio. Viene eseguita come SYSTEM, senza bisogno di accedere.'
    logAutoOn  = 'Istantanea all''avvio registrata: {0} minuti dopo l''avvio.'
    logAutoOff = 'Istantanea all''avvio rimossa.'
    warnPath   = 'Questo file non si trova su un''unità locale fissa. L''attività memorizza il suo percorso e potrebbe non raggiungerlo all''avvio.'
    grpLog     = 'Registro'

    effective  = 'Attualmente in vigore'
    source     = 'origine'
    winDefault = 'impostazione predefinita di Windows'
    srcGPO     = 'criterio (questo strumento)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'app Impostazioni'
    sizeStd    = 'impostazione predefinita di Windows (2% del disco)'

    carryOver  = 'deriva ancora dall''impostazione precedente; alla prossima esecuzione verrà portato a'
    proven72   = 'più vecchio di 72 ore: la conservazione estesa funziona in modo dimostrabile'
    unofficial = 'Soluzione non ufficiale: i valori di configurazione scritti qui non sono documentati da Microsoft e possono cambiare con le future versioni di Windows. «Reimposta tutto» ripristina in qualsiasi momento l''impostazione predefinita di Windows.'
    taskMissing= 'PITRTask non trovata'
    unknownTxt = 'sconosciuto'

    logReady   = 'Pronto. I valori vengono scritti a livello di criterio e hanno la precedenza sull''app Impostazioni.'
    logNoAdmin = 'ATTENZIONE: senza diritti di amministratore non è possibile salvare alcun valore.'
    logRefresh = 'Vista aggiornata.'
    logSaved   = 'Salvato. Ha effetto alla prossima esecuzione di PITRTask (che avviene solo a sistema inattivo).'
    logCleared = 'modifica rimossa -> impostazione predefinita di Windows'
    logIdleOff = 'Condizione di inattività temporaneamente sospesa.'
    logStarted = 'PITRTask avviata, in attesa del completamento...'
    logIdleOn  = 'Condizione di inattività ripristinata.'
    logIdleErr = 'Condizione di inattività ripristinata dopo un errore.'
    logIdleBad = 'ATTENZIONE: non è stato possibile ripristinare la condizione di inattività!'
    logDone    = 'Fatto. Risultato'
    logNextRun = 'prossima esecuzione'
    logTook    = 'durata {0}'
    logNoFinish= 'ancora in corso dopo {0} - il punto viene completato in background.'
    logRemoved = 'rimosso'
    logNothing = 'Nessun valore era impostato.'
    logError   = 'Errore'
    askReset   = 'Rimuovere tutti i valori impostati da questo strumento e tornare all''impostazione predefinita di Windows?'
    askResetT  = 'Reimposta'
    capWinRE   = 'Ambiente di ripristino:'
    winreOn    = 'presente'
    winreOff   = 'disattivato'
    winreUnk   = 'non determinabile'
    winreFree  = 'liberi'
    noteWinRE  = 'Senza l''ambiente di ripristino nessun punto di ripristino può essere applicato: il ripristino viene eseguito da lì, non da dentro Windows. Un «reagentc /enable» con diritti di amministratore di solito lo ristabilisce.'
    btnWinRE   = 'Riavvia al ripristino'
    tipWinRE   = 'Riavvia Windows nell''ambiente di ripristino, dove è possibile applicare un punto di ripristino. Il lavoro non salvato negli altri programmi va perso.'
    askWinRE   = 'Riavviare ora nell''ambiente di ripristino? Il lavoro non salvato negli altri programmi andrà perso.'
    askWinRET  = 'Riavvio'
    logWinRE   = 'Riavvio nell''ambiente di ripristino...'
    btnCopy    = 'Copia lo stato'
    copyHint   = 'Copia edizione, impostazioni con la loro origine, stato dell''attività e punti di ripristino come testo - per un messaggio in un forum o una segnalazione.'
    tipCopy    = 'Copia lo stato attuale negli appunti come testo semplice: edizione, impostazioni con la loro origine, stato dell''attività, punti di ripristino e spazio. Pensato per un messaggio in un forum o una segnalazione.'
    logCopied  = 'Stato copiato negli appunti.'
}
# ------------------------------------------------------------------ Polish --
# "godz." statt "godziny"/"godzin": Polnisch verlangt je nach Zahl eine andere Form
# (2 godziny, aber 5 godzin), und die Oberflaeche kennt beide Faelle. Die Abkuerzung
# ist unveraenderlich und in Windows selbst ueblich, damit stimmt jede Zahl. Bei
# Tagen genuegen zwei Formen, dzien und dni, die decken alles ab.
pl = @{
    winTitle   = 'Point-in-time restore'
    headline   = 'Point-in-time restore'
    subtitle   = 'Przywracanie do punktu w czasie (PITR)'
    intro      = 'Windows udostępnia częstotliwość i czas przechowywania tylko w edycji Enterprise. To narzędzie zapisuje je bezpośrednio w konfiguracji mechanizmu PITR, który nie sprawdza edycji.'
    lnkGuide   = 'Przewodnik'
    tipProject = 'Otwiera stronę projektu w serwisie GitHub'
    tipGuide   = 'Otwiera krótki przewodnik w przeglądarce'
    updAvail   = 'Dostępna jest wersja {0} - strona wydania'
    tipUpdate  = 'Otwiera stronę pobierania w przeglądarce. Nic nie jest pobierane ani instalowane automatycznie.'

    grpState   = 'Stan bieżący'
    capEdition = 'Edycja systemu Windows:'
    capLast    = 'Ostatnie uruchomienie:'
    capNext    = 'Następne uruchomienie:'
    capDelta   = 'Zaplanowany odstęp:'
    capTaskSt  = 'Stan zadania:'
    tsReady    = 'gotowe'
    tsQueued   = 'oczekiwanie na bezczynność systemu'
    tsRunning  = 'trwa wykonywanie'
    tsDisabled = 'wyłączone'
    tsOverdue  = 'opóźnione o'
    missedRuns = 'pominięte uruchomienia: {0}'
    btnIdleChk = 'Sprawdź bezczynność'
    idlePartial = ' Policzono bez uprawnień administratora, więc uwzględniono tylko zadania widoczne dla tego konta.'
    idleBanner = 'Pominięto {0} uruchomień. To normalne, dopóki komputer jest używany - ale może też oznaczać, że Windows w ogóle nie zgłasza już bezczynności.'
    idleBlocked = 'Windows nie zgłasza bezczynności od {0}. Od tego czasu nie uruchomiło się żadne z pozostałych {1} zadań zależnych od bezczynności, więc sprawa sięga daleko poza migawki. Zwykle jakiś program lub sterownik utrzymuje system w stanie czuwania - "powercfg /requests" w wierszu polecenia z uprawnieniami wskaże, który.'
    idleFine   = 'Wykrywanie bezczynności działa: {0} z pozostałych {1} zadań zależnych od bezczynności uruchomiło się od startu systemu, ostatnie o {2}. Komputer był po prostu używany w wyznaczonych porach.'
    idleEarly  = 'Żadne z pozostałych {0} zadań zależnych od bezczynności jeszcze się nie uruchomiło, ale system działa dopiero od {1} - za krótko, by cokolwiek stwierdzić. Warto sprawdzić później.'
    idleChecking = 'odczyt pozostałych zadań zależnych od bezczynności ...'
    logIdleChk = 'Sprawdzenie bezczynności: {0}'
    staleSame  = 'Zadanie startowe uruchamia inną kompilację tej samej wersji {0} z {1}.'
    noteIdle   = 'Punkty przywracania powstają tylko wtedy, gdy system jest bezczynny. Gdy komputer jest używany lub wyłączony, uruchomienie zostaje przesunięte - a zaplanowany termin może zostać pominięty w całości. Ustawiona częstotliwość jest więc najmniejszym możliwym odstępem, a nie gwarancją. Przycisk „Utwórz migawkę teraz” u góry pozwala wymusić punkt w dowolnej chwili.'

    grpPoints  = 'Punkty przywracania'
    lblCount   = 'Liczba'
    lblOldest  = 'Najstarszy punkt'
    lblStorage = 'Miejsce na dysku'
    stUsed     = 'w użyciu'
    stAlloc    = 'zarezerwowane'
    stMax      = 'limit'
    stNoAdmin  = 'niedostępne (wymagane uprawnienia administratora)'
    noteStore  = 'Windows podaje zajętość tylko dla całego dysku, nigdy dla pojedynczego punktu - wszystkie punkty korzystają ze wspólnego obszaru różnicowego.'
    tipStore   = 'W użyciu = dane rzeczywiście zapisane przez kopie w tle.' + [Environment]::NewLine +
                 'Zarezerwowane = miejsce już zajęte na dysku przez usługę VSS. Nie jest dostępne dla innych plików, ale nie jest jeszcze w pełni wypełnione.' + [Environment]::NewLine +
                 'Limit = skonfigurowany pułap; obszar nigdy nie rośnie ponad niego.'
    noteVolume = 'Obejmowany jest wyłącznie dysk systemu Windows {0}. Pozostałe partycje i inne dyski pozostają poza zakresem - również wtedy, gdy znajdują się na tym samym dysku fizycznym. Nie są ani zapisywane, ani przywracane, więc dane na nich nadal wymagają własnej kopii zapasowej. Limit miejsca poniżej również dotyczy wyłącznie {0}. Punkty znajdują się przy tym na tym samym dysku, który chronią: uszkodzony dysk zabiera je ze sobą. Przywracanie do punktu w czasie jest odpowiedzią na nieudaną aktualizację lub wadliwy sterownik, a nie na awarię sprzętu, kradzież czy ransomware - nie zastępuje kopii zapasowej.'

    colTime    = 'Data i godzina'
    colAge     = 'Wiek'
    colStatus  = 'Stan'
    colBuild   = 'Kompilacja'
    colDur     = 'Czas'
    histHint   = 'Windows nie zapisuje, jak długo trwała migawka, dopóki historia Harmonogramu zadań jest wyłączona. Rejestruje ona każde zaplanowane zadanie na tym komputerze i obejmuje tylko uruchomienia od momentu włączenia.'
    btnHist    = 'Włącz historię zadań'
    askHist    = 'Włączyć historię Harmonogramu zadań? To ustawienie obejmuje cały system: od tej chwili każde zaplanowane zadanie na tym komputerze jest zapisywane w buforze cyklicznym o wielkości 10 MB. Istniejące punkty przywracania nadal pozostaną bez czasu trwania.'
    askHistT   = 'Historia zadań'
    logHistOn  = 'Historia zadań włączona. Czas pojawi się od następnego uruchomienia.'
    logHistErr = 'Nie udało się włączyć historii zadań.'
    askCopy    = 'Ten plik znajduje się w udziale sieciowym lub na nośniku wymiennym. Zadanie działa jako SYSTEM i sięga do sieci jako konto komputera, a nie jako Ty - dlatego migawka startowa z udziału zwykle się nie udaje, choć udział otwiera się bez problemu.{0}{0}Skopiować plik do {1} i zarejestrować zadanie stamtąd?{0}{0}Tak: skopiować i użyć pliku lokalnego. Nie: zarejestrować mimo to z bieżącą ścieżką. Anuluj: nie rejestrować.'
    askCopyT   = 'Migawka startowa'
    logCopyOk  = 'Skopiowano do {0} - zadanie używa tego pliku.'
    loading    = 'odczyt...'
    staleOld   = 'Zadanie startowe nadal uruchamia wersję {0} z {1}. Ta tutaj to {2}.'
    staleGone  = 'Zadanie startowe wskazuje na {0}, a tego pliku już nie ma.'
    btnAutoUpd = 'Odśwież kopię'
    logAutoUpd = 'Kopia odświeżona: w {0} jest teraz wersja {1}.'
    stShadowOk = 'kopia w tle istnieje'
    stRegOnly  = 'tylko wpis w rejestrze'
    stUnknown  = 'nieznany (wymagane uprawnienia administratora)'

    grpSet     = 'Ustawienia'
    capActive  = 'Funkcja włączona'
    capFreq    = 'Częstotliwość - odstęp między punktami przywracania'
    capReten   = 'Czas przechowywania - okres życia punktu przywracania'
    capSize    = 'Maksymalne miejsce dla wszystkich punktów przywracania'

    optNoOver  = 'Ustawienie domyślne systemu Windows (bez zmiany)'
    optOn      = 'Włączona'
    optOff     = 'Wyłączona'
    optStdFreq = 'Ustawienie domyślne systemu Windows (24 godz.)'
    optStdRet  = 'Ustawienie domyślne systemu Windows (3 dni / 72 godz.)'
    unitHour   = 'godz.'
    unitHours  = 'godz.'
    unitDay    = 'dzień'
    unitDays   = 'dni'
    unitMin    = 'min'
    unitMin1   = 'min'
    unitMinShort = 'min'
    unitHourShort = 'godz.'

    btnReset   = 'Resetuj wszystko'
    btnRefresh = 'Odśwież'
    btnApply   = 'Zastosuj'
    btnApplyNow= 'Zastosuj i uruchom teraz'
    btnSnapNow = 'Utwórz migawkę teraz'
    snapHint   = 'Tworzy punkt przywracania od razu, niezależnie od harmonogramu. Ustawienia poniżej pozostają bez zmian.'
    tipSnapNow = 'Uruchamia PITRTask jeden raz, także wtedy, gdy komputer jest używany. W konfiguracji nic nie zostaje zapisane.'
    chkAuto    = 'Przy każdym uruchomieniu systemu'
    autoHint   = 'Windows sam prosi o punkt przy starcie, ale to żądanie czeka na bezczynność systemu - a dopiero co uruchomiony komputer bezczynny nie jest. To go wymusza.'
    tipAuto    = 'Rejestruje zaplanowane zadanie, które tworzy punkt przywracania po wybranej liczbie minut od każdego uruchomienia. Działa jako SYSTEM, bez potrzeby logowania.'
    logAutoOn  = 'Migawka startowa zarejestrowana: {0} minut po uruchomieniu.'
    logAutoOff = 'Migawka startowa usunięta.'
    warnPath   = 'Ten plik nie znajduje się na stałym dysku lokalnym. Zadanie zapamiętuje jego ścieżkę i może jej nie osiągnąć przy starcie.'
    grpLog     = 'Dziennik'

    effective  = 'Obecnie obowiązuje'
    source     = 'źródło'
    winDefault = 'ustawienie domyślne systemu Windows'
    srcGPO     = 'zasada (to narzędzie)'
    srcCSP     = 'Intune/MDM'
    srcUX      = 'aplikacja Ustawienia'
    sizeStd    = 'ustawienie domyślne systemu Windows (2% dysku)'

    carryOver  = 'nadal pochodzi z poprzedniego ustawienia; przy następnym uruchomieniu zostanie zmieniony na'
    proven72   = 'starszy niż 72 godziny: wydłużony czas przechowywania działa w praktyce'
    unofficial = 'Rozwiązanie nieoficjalne: zapisywane tutaj wartości konfiguracyjne nie są udokumentowane przez firmę Microsoft i mogą ulec zmianie w przyszłych wersjach systemu Windows. „Resetuj wszystko” w każdej chwili przywraca ustawienie domyślne systemu Windows.'
    taskMissing= 'Nie znaleziono zadania PITRTask'
    unknownTxt = 'nieznany'

    logReady   = 'Gotowe. Wartości są zapisywane na poziomie zasad i mają pierwszeństwo przed aplikacją Ustawienia.'
    logNoAdmin = 'UWAGA: bez uprawnień administratora nie można zapisać żadnych wartości.'
    logRefresh = 'Widok odświeżony.'
    logSaved   = 'Zapisano. Zaczyna obowiązywać przy następnym uruchomieniu PITRTask (następuje ono tylko przy bezczynnym systemie).'
    logCleared = 'zmiana usunięta -> ustawienie domyślne systemu Windows'
    logIdleOff = 'Warunek bezczynności tymczasowo zniesiony.'
    logStarted = 'Uruchomiono PITRTask, oczekiwanie na zakończenie...'
    logIdleOn  = 'Warunek bezczynności przywrócony.'
    logIdleErr = 'Warunek bezczynności przywrócony po błędzie.'
    logIdleBad = 'UWAGA: nie udało się przywrócić warunku bezczynności!'
    logDone    = 'Gotowe. Wynik'
    logNextRun = 'następne uruchomienie'
    logTook    = 'czas {0}'
    logNoFinish= 'nadal trwa po {0} - punkt jest kończony w tle.'
    logRemoved = 'usunięto'
    logNothing = 'Żadne wartości nie były ustawione.'
    logError   = 'Błąd'
    askReset   = 'Usunąć wszystkie wartości ustawione przez to narzędzie i wrócić do ustawienia domyślnego systemu Windows?'
    askResetT  = 'Resetowanie'
    capWinRE   = 'Środowisko odzyskiwania:'
    winreOn    = 'dostępne'
    winreOff   = 'wyłączone'
    winreUnk   = 'nie do ustalenia'
    winreFree  = 'wolne'
    noteWinRE  = 'Bez środowiska odzyskiwania nie da się zastosować żadnego punktu przywracania - cofnięcie odbywa się właśnie stamtąd, a nie z poziomu systemu Windows. Polecenie „reagentc /enable” z uprawnieniami administratora zwykle je przywraca.'
    btnWinRE   = 'Uruchom ponownie do odzyskiwania'
    tipWinRE   = 'Uruchamia system Windows ponownie w środowisku odzyskiwania, gdzie można zastosować punkt przywracania. Niezapisana praca w innych programach zostanie utracona.'
    askWinRE   = 'Uruchomić ponownie w środowisku odzyskiwania? Niezapisana praca w innych programach zostanie utracona.'
    askWinRET  = 'Ponowne uruchomienie'
    logWinRE   = 'Ponowne uruchamianie w środowisku odzyskiwania...'
    btnCopy    = 'Kopiuj stan'
    copyHint   = 'Kopiuje edycję, ustawienia wraz ze źródłem, stan zadania i punkty przywracania jako tekst - do wpisu na forum lub zgłoszenia błędu.'
    tipCopy    = 'Kopiuje bieżący stan do schowka jako zwykły tekst: edycja, ustawienia wraz ze źródłem, stan zadania, punkty przywracania i miejsce. Pomyślane o wpisie na forum lub zgłoszeniu błędu.'
    logCopied  = 'Stan skopiowany do schowka.'
}

}

# Order of the language buttons, and at the same time the list of supported codes.
$LangCodes = @('en', 'de', 'fr', 'es', 'pt', 'it', 'pl')

# English steps in for anything a translation is missing, so a half-finished language
# block degrades to a mixed interface instead of empty labels.
function T {
    param([string]$Key)
    $v = $LangText[$script:Lang][$Key]
    if ($null -eq $v) { $v = $LangText['en'][$Key] }
    return $v
}

# Derive the language from the Windows display language; English if it is not one of ours.
$uiLang = (Get-UICulture).TwoLetterISOLanguageName
$script:Lang = if ($LangCodes -contains $uiLang) { $uiLang } else { 'en' }

function Test-Admin {
    ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ------------------------------------------------------------ Registry-Layer --
$LevelOrder = @('GPO', 'CSP', 'UX')

function Get-LevelLabel {
    param([string]$Lvl)
    switch ($Lvl) { 'GPO' { T 'srcGPO' } 'CSP' { T 'srcCSP' } default { T 'srcUX' } }
}

function Get-PitrValue {
    param([string]$Name)
    foreach ($lvl in $LevelOrder) {
        $vn = "${Name}_$lvl"
        $v = (Get-ItemProperty -Path $KeyPath -Name $vn -ErrorAction SilentlyContinue).$vn
        if ($null -ne $v) { return [pscustomobject]@{ Value = [int]$v; Level = $lvl } }
    }
    return $null
}

function Set-PitrValue {
    param([string]$Name, [int]$Value)
    if (-not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }
    New-ItemProperty -Path $KeyPath -Name "${Name}_$Level" -Value $Value -PropertyType DWord -Force | Out-Null
}

function Remove-PitrValue {
    param([string]$Name)
    $vn = "${Name}_$Level"
    if ($null -ne (Get-ItemProperty -Path $KeyPath -Name $vn -ErrorAction SilentlyContinue).$vn) {
        Remove-ItemProperty -Path $KeyPath -Name $vn -Force
        return $true
    }
    return $false
}

function Format-Duration {
    param([int]$Minutes)
    $h = $Minutes / 60
    if ($Minutes % 1440 -eq 0 -and $Minutes -ge 1440) {
        $d = $Minutes / 1440
        $du = if ($d -eq 1) { T 'unitDay' } else { T 'unitDays' }
        return "$d $du ($h $(T 'unitHours'))"
    }
    $hr = [math]::Round($h, 1)
    $hu = if ($hr -eq 1) { T 'unitHour' } else { T 'unitHours' }
    return "$hr $hu"
}

# PowerShell formatiert ein Datum in Anfuehrungszeichen mit der INVARIANTEN Kultur, nicht
# mit der des Nutzers: "$datum" ergibt 08/27/2026 auch auf einem deutschen System. Jede
# Zeitangabe geht deshalb ausdruecklich ueber ToString('G') - kurzes Datum, lange Uhrzeit
# der Region, dasselbe wie in der Punkteliste. 'G' und nicht 'g': Das kurze Format laesst
# die Sekunden weg, und die werden gebraucht, sobald jemand einen Punkt oder einen Lauf
# einem Eintrag im Aufgabenplaner zuordnen will.
# Sekunden mit einer Nachkommastelle, ab einer Minute als m:ss. Die Einheiten bleiben
# als "s" und "min" stehen: Beides ist in allen sieben Sprachen dieselbe Abkuerzung,
# die Zahl selbst folgt ueber ToString der Region des Nutzers.
function Format-Elapsed {
    param([double]$Seconds)
    if ($Seconds -lt 60) { return $Seconds.ToString('0.0') + ' s' }
    # Floor und nicht [int]: Die Umwandlung nach [int] RUNDET in PowerShell, aus 95,4
    # Sekunden wuerden damit 2:35 statt 1:35 - und aus 119,7 sogar 1:60.
    return ('{0}:{1:00} min' -f [math]::Floor($Seconds / 60), [math]::Floor($Seconds % 60))
}

function Format-Stamp {
    param($Value)
    if ($null -eq $Value) { return '-' }
    try { return ([datetime]$Value).ToString('G') } catch { return "$Value" }
}

function Format-Age {
    param([double]$Hours)
    # Unter einer Stunde in Minuten: "0,1 h" sagt niemandem etwas, "8 min" schon.
    # Ganzzahlig gerundet, weil Sekundenbruchteile beim Alter keine Rolle spielen.
    if ($Hours -lt 1) { return ('{0:N0} {1}' -f ($Hours * 60), (T 'unitMinShort')) }
    if ($Hours -lt 48) { return ('{0:N1} {1}' -f $Hours, (T 'unitHourShort')) }
    return ('{0:N1} {1}' -f ($Hours / 24), (T 'unitDays'))
}

# Restore points: timestamps from the registry (TimeUTC = 8-byte FILETIME),
# reconciled against the VSS shadow copies that actually exist. A registry entry
# without a matching shadow copy is a leftover and cannot be restored from.
# Windows haelt die Dauer einer Schattenkopie nirgends fest - weder Win32_ShadowCopy
# noch das Momentaufnahme-Protokoll kennen eine Zeitspanne, dessen Ereignispaare
# beschreiben das Online- und Offlineschalten von Volumes. Die einzige Quelle ist der
# Aufgabenverlauf: Ereignis 100 (gestartet) und 102 (abgeschlossen) tragen dieselbe
# Instanz-Kennung, die Differenz ist die Laufzeit von PITRTask.
#
# Der Verlauf ist bei Windows ab Werk abgeschaltet. Dann gibt es hier $null, die Spalte
# bleibt leer und die Oberflaeche bietet das Einschalten an - heimlich wird an einer
# systemweiten Protokolleinstellung nichts gedreht.
function Get-TaskRuns {
    $log = 'Microsoft-Windows-TaskScheduler/Operational'
    # $TaskPath endet bereits auf einen Backslash - schlichtes Aneinanderhaengen ist
    # hier eindeutiger als jede Trimmerei mit maskierten Zeichen.
    $full = $TaskPath + $TaskName
    try {
        $l = Get-WinEvent -ListLog $log -ErrorAction Stop
        if (-not $l.IsEnabled) { return $null }
    } catch { return $null }

    # Gefiltert wird im Protokoll und nicht hinterher in PowerShell. Das Zerlegen der
    # Ereignisse nach XML kostet rund eine Millisekunde pro Stueck: Bei 600 Ereignissen
    # aus allen Aufgaben des Rechners waren das 600 ms Startverzoegerung, bei den sechs,
    # die PITRTask betreffen, sind es 7 ms. Der Aufwand bleibt damit konstant, egal wie
    # voll das Protokoll ist - und es fuellt sich mit jeder Aufgabe des Systems.
    $xp = "*[System[(EventID=100 or EventID=102)]] and *[EventData[Data[@Name='TaskName']='$full']]"
    try {
        $ev = Get-WinEvent -LogName $log -FilterXPath $xp -MaxEvents 200 -ErrorAction Stop
    } catch { return @() }          # eingeschaltet, aber noch nichts drin

    # In einfachen Anfuehrungszeichen ist '\' buchstaeblich ZWEI Backslashes - der
    # Aufgabenname haette damit nie gepasst. Join-Path waere hier falsch (kein Dateipfad).
    $runs = @{}
    foreach ($e in $ev) {
        try {
            # Ueber die benannten Felder und nicht ueber Properties[0..n]: Die
            # Reihenfolge unterscheidet sich zwischen den beiden Ereignissen.
            $d = @{}
            foreach ($n in ([xml]$e.ToXml()).Event.EventData.Data) { $d[$n.Name] = $n.'#text' }
            $id = [string]$d['InstanceId']
            if ([string]::IsNullOrEmpty($id)) { continue }
            if (-not $runs.ContainsKey($id)) { $runs[$id] = @{ Start = $null; End = $null } }
            if ($e.Id -eq 100) { $runs[$id].Start = $e.TimeCreated } else { $runs[$id].End = $e.TimeCreated }
        } catch { }
    }

    $out = New-Object System.Collections.Generic.List[object]
    foreach ($r in $runs.Values) {
        if ($r.Start -and $r.End -and $r.End -ge $r.Start) {
            $out.Add([pscustomobject]@{
                Start   = $r.Start
                End     = $r.End
                Seconds = ($r.End - $r.Start).TotalSeconds
            })
        }
    }
    # ToArray() und nicht @($out): Windows PowerShell 5.1 wirft beim Umwandeln einer
    # generischen Liste in ein Array mit @(...) eine ArgumentException, sobald ein
    # PSCustomObject darin liegt ("Die Argumenttypen stimmen nicht ueberein"). An der
    # anderen Liste in dieser Datei faellt es nicht auf, weil sie durch Sort-Object
    # laeuft - eine Pipeline umgeht die Umwandlung.
    return $out.ToArray()
}

function Get-RestorePoints {
    # Without administrator rights the VSS query fails. The status must then stay
    # open instead of falsely claiming "registry entry only".
    $vss = @{}
    $vssOk = $false
    try {
        foreach ($c in (Get-CimInstance Win32_ShadowCopy -ErrorAction Stop)) { $vss["$($c.ID)"] = $true }
        $vssOk = $true
    } catch { }

    # Ein Punkt gehoert zu dem Lauf, in dessen Zeitfenster sein Zeitstempel faellt.
    # Eine halbe Minute Spielraum nach beiden Seiten, weil der Eintrag in der Registry
    # und das Ereignis nicht auf die Sekunde zusammenfallen. Die Laeufe liegen Stunden
    # auseinander, eine Verwechslung ist damit ausgeschlossen.
    $runs = Get-TaskRuns
    $script:HistoryOff = ($null -eq $runs)

    $now = Get-Date
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($k in (Get-ChildItem -Path $SnapPath -ErrorAction SilentlyContinue)) {
        $p = Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue
        if (-not $p) { continue }
        $b = $p.TimeUTC
        $dt = $null
        if ($b -is [byte[]] -and $b.Length -eq 8) {
            try { $dt = [DateTime]::FromFileTimeUtc([BitConverter]::ToInt64($b, 0)).ToLocalTime() } catch { }
        }
        $ageH = if ($dt) { ($now - $dt).TotalHours } else { $null }
        $list.Add([pscustomobject]@{
            Sortier   = if ($dt) { $dt } else { [DateTime]::MinValue }
            AlterStd  = $ageH
            # 'G' is the short date with the long time of the user's region - the seconds are
            # what makes a point matchable against a Task Scheduler entry. A fixed dd.MM.yyyy
            # would be wrong everywhere outside the German-speaking world.
            Zeitpunkt = if ($dt) { $dt.ToString('G') } else { T 'unknownTxt' }
            Alter     = if ($null -ne $ageH) { Format-Age $ageH } else { '-' }
            Status    = if (-not $vssOk) { T 'stUnknown' }
                        elseif ($vss.ContainsKey("$($p.Id)")) { T 'stShadowOk' }
                        else { T 'stRegOnly' }
            Version   = "$($p.Build).$($p.Revision)"
            Dauer     = if ($dt -and $runs) {
                            $hit = $runs | Where-Object {
                                $dt -ge $_.Start.AddSeconds(-30) -and $dt -le $_.End.AddSeconds(30)
                            } | Select-Object -First 1
                            if ($hit) { Format-Elapsed $hit.Seconds } else { '-' }
                        } else { '-' }
        })
    }
    return @($list | Sort-Object Sortier -Descending)
}

# VSS reports storage per drive only, never per individual point. The query is
# pinned to the OS volume rather than taking whatever comes first, because that is
# the only volume PITR ever touches - other volumes may well carry shadow copies
# from unrelated tools, and those figures would be misleading here.
#   UsedSpace      = data actually written by the shadow copies
#   AllocatedSpace = difference area already claimed on disk (>= Used)
#   MaxSpace       = configured ceiling
function Get-ShadowStorage {
    try {
        $osVol = (Get-CimInstance Win32_Volume -Filter "DriveLetter='$env:SystemDrive'" -ErrorAction Stop).DeviceID
        $s = Get-CimInstance Win32_ShadowStorage -ErrorAction Stop |
             Where-Object { $_.Volume.DeviceID -eq $osVol } | Select-Object -First 1
        if ($s) {
            return [pscustomobject]@{
                Drive = $env:SystemDrive
                Used  = [double]$s.UsedSpace
                Alloc = [double]$s.AllocatedSpace
                Max   = [double]$s.MaxSpace
            }
        }
    } catch { }
    return $null
}

# Ein PITR-Punkt wird aus der Wiederherstellungsumgebung heraus angewendet, nicht aus
# Windows. Ist die abgeschaltet - nach missglueckten Updates keine Seltenheit, siehe
# KB5034441 -, sammelt das Werkzeug Punkte, an die im Ernstfall niemand herankommt.
# Gelesen wird ReAgent.xml und nicht die Ausgabe von "reagentc /info": die ist
# uebersetzt und damit in sieben Sprachen verschieden, die Datei ist es nicht.
# InstallState 1 = eingerichtet. Faellt irgendetwas davon aus, gibt es $null und die
# Oberflaeche schreibt "nicht ermittelbar" - lieber keine Aussage als eine falsche.
function Get-WinReState {
    $file = Join-Path $env:SystemRoot 'System32\Recovery\ReAgent.xml'
    try {
        if (-not (Test-Path -LiteralPath $file)) { return $null }
        $cfg = ([xml](Get-Content -LiteralPath $file -Raw -ErrorAction Stop)).WindowsRE
        if ($null -eq $cfg) { return $null }

        $state = $null
        if ($null -ne $cfg.InstallState) { $state = [string]$cfg.InstallState.state }
        $path = ''
        if ($null -ne $cfg.WinreLocation) { $path = [string]$cfg.WinreLocation.path }

        # Ohne InstallState hilft der Ablageort weiter: er ist leer, solange die
        # Umgebung nicht eingerichtet ist.
        $on = if ($null -ne $state) { $state -eq '1' } else { -not [string]::IsNullOrWhiteSpace($path) }

        # Groesse und freier Platz sind Beiwerk, aber aufschlussreich: zu wenig Platz ist
        # der Grund, aus dem WinRE-Updates reihenweise scheiterten. Der Ablageort in der
        # Datei ist relativ, die Partition steckt in id (Datentraeger) und offset (Versatz
        # in Byte) - danach wird gesucht, nicht im Pfad. Klappt es nicht, bleiben die
        # Zahlen einfach weg.
        # Direkt ueber CIM und nicht ueber Get-Partition/Get-Volume: Der erste Aufruf
        # dieser Cmdlets laedt das Storage-Modul, und das kostete beim Programmstart
        # allein 1,7 Sekunden. Dieselbe Auskunft ueber denselben CIM-Namensraum
        # braucht 200 Millisekunden, weil kein Modul dafuer geladen werden muss.
        $size = $null
        $free = $null
        try {
            $disk = [int]$cfg.WinreLocation.id
            $off  = [long]$cfg.WinreLocation.offset
            $part = Get-CimInstance -Namespace root/Microsoft/Windows/Storage `
                                    -ClassName MSFT_Partition -ErrorAction Stop |
                    Where-Object { $_.DiskNumber -eq $disk -and $_.Offset -eq $off } |
                    Select-Object -First 1
            if ($part) {
                $size = $part.Size
                try {
                    $vol = $part | Get-CimAssociatedInstance -ResultClassName MSFT_Volume -ErrorAction Stop
                    if ($vol) { $free = $vol.SizeRemaining }
                } catch { }
            }
        } catch { }
        return [pscustomobject]@{ Enabled = [bool]$on; Path = $path; Size = $size; Free = $free }
    } catch { }
    return $null
}

# --------------------------------------------------------------- User interface --
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="790" Height="800" MinWidth="720" MinHeight="440"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize" Background="#F5F5F5"
        FontFamily="Segoe UI" FontSize="13">
  <Window.Resources>
    <!-- Ein normaler WPF-Knopf nimmt zwar ein Background an, malt beim Ueberfahren aber
         wieder den Systemverlauf darueber. Fuer den einen hervorgehobenen Knopf deshalb
         eine eigene Vorlage; drei Zustaende genuegen ihm. -->
    <Style x:Key="Primary" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="Background" Value="#2C7A4B"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Chrome" Background="{TemplateBinding Background}"
                    CornerRadius="3" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Chrome" Property="Background" Value="#35935A"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Chrome" Property="Background" Value="#215C39"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Chrome" Property="Background" Value="#A9C4B4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
    <StackPanel Margin="14">

    <Grid Margin="0,0,0,8">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock x:Name="TxtHead" FontSize="20" FontWeight="SemiBold"/>
        <TextBlock x:Name="TxtSub" FontSize="13" Foreground="#777" Margin="0,1,0,0"/>
        <TextBlock FontSize="12" Margin="0,3,0,0">
          <Hyperlink x:Name="LnkProject"><Run Text="github.com/henmedia/windows-pitr-config"/></Hyperlink>
          <Run Text="   ·   " Foreground="#AAAAAA"/>
          <Hyperlink x:Name="LnkGuide"><Run x:Name="RunGuide" Text="Guide"/></Hyperlink>
        </TextBlock>
        <TextBlock x:Name="TxtUpdate" FontSize="12" Margin="0,4,0,0" Visibility="Collapsed">
          <Hyperlink x:Name="LnkUpdate" Foreground="#1A7F37" FontWeight="SemiBold"><Run x:Name="RunUpdate" Text=""/></Hyperlink>
        </TextBlock>
      </StackPanel>
      <!-- WrapPanel mit fester Hoechstbreite: Ab der sechsten Sprache bricht die Reihe
           in eine zweite Zeile um, statt der Ueberschrift daneben Platz wegzunehmen.
           205 = fuenf Knoepfe a 41 Pixel, also genau die Breite, die sie schon immer
           hatte. Einheitlicher Rand rechts und unten, weil beim Umbruch jeder Knopf
           der letzte einer Zeile sein kann. -->
      <WrapPanel Grid.Column="1" Orientation="Horizontal" MaxWidth="205"
                 VerticalAlignment="Top" Margin="12,2,0,0">
        <Button x:Name="BtnLangEN" Tag="en" Content="EN" Width="38" Height="26" Margin="0,0,3,3"/>
        <Button x:Name="BtnLangDE" Tag="de" Content="DE" Width="38" Height="26" Margin="0,0,3,3"/>
        <Button x:Name="BtnLangFR" Tag="fr" Content="FR" Width="38" Height="26" Margin="0,0,3,3"/>
        <Button x:Name="BtnLangES" Tag="es" Content="ES" Width="38" Height="26" Margin="0,0,3,3"/>
        <Button x:Name="BtnLangPT" Tag="pt" Content="PT" Width="38" Height="26" Margin="0,0,3,3"/>
        <Button x:Name="BtnLangIT" Tag="it" Content="IT" Width="38" Height="26" Margin="0,0,3,3"/>
        <Button x:Name="BtnLangPL" Tag="pl" Content="PL" Width="38" Height="26" Margin="0,0,3,3"/>
      </WrapPanel>
    </Grid>

    <!-- Der Schnappschuss steht bewusst oben und nicht bei den uebrigen Knoepfen am
         Fuss: Er ist die einzige Aktion, die ohne jede Einstellung auskommt, und fuer
         viele der einzige Grund, das Werkzeug ueberhaupt zu oeffnen. Die Erklaerung
         daneben statt darunter, damit die Zeile keine zusaetzliche Hoehe kostet. -->
    <Border Background="#EDF6F0" BorderBrush="#BFDCC9" BorderThickness="1"
            Padding="9,7" Margin="0,0,0,10">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Button x:Name="BtnSnapNow" Grid.Column="0" Style="{StaticResource Primary}"
                Height="34" MinWidth="240" Padding="14,0" FontSize="14" FontWeight="SemiBold"/>
        <TextBlock x:Name="TxtSnapHint" Grid.Column="1" Margin="12,0,0,0"
                   VerticalAlignment="Center" TextWrapping="Wrap"
                   Foreground="#2F5744" FontSize="12"/>
      </Grid>
    </Border>

    <!-- Der Startschnappschuss gehoert direkt unter den Knopf: Es ist dieselbe Aktion,
         nur zeitversetzt. Erklaerung rechts daneben, damit die Zeile flach bleibt. -->
    <Grid Margin="2,0,0,10">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="Auto"/>
        <ColumnDefinition Width="Auto"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <CheckBox x:Name="ChkAuto" Grid.Column="0" VerticalAlignment="Center" FontSize="12"/>
      <ComboBox x:Name="CmbAutoDelay" Grid.Column="1" Width="112" Height="22"
                Margin="10,0,0,0" FontSize="12" VerticalAlignment="Center"/>
      <TextBlock x:Name="TxtAutoHint" Grid.Column="2" Margin="12,0,0,0" VerticalAlignment="Center"
                 TextWrapping="Wrap" Foreground="#777" FontSize="11"/>
    </Grid>

    <!-- Nur sichtbar, wenn die Startaufgabe auf eine andere Fassung zeigt als die
         gerade laufende. Gelb wie der Unoffiziell-Hinweis: eine Warnung, kein Fehler. -->
    <Border x:Name="BoxStale" BorderBrush="#D9B36A" BorderThickness="1" Background="#FFF8E7"
            Padding="8,6" Margin="0,0,0,10" Visibility="Collapsed">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="TxtStale" Grid.Column="0" TextWrapping="Wrap" VerticalAlignment="Center"
                   Foreground="#6B5210" FontSize="12"/>
        <Button x:Name="BtnAutoUpd" Grid.Column="1" Height="24" Padding="12,0" Margin="12,0,0,0"
                FontSize="12"/>
      </Grid>
    </Border>

    <!-- Einleitung und Hinweis stehen bewusst ausserhalb des Rasters: in der linken Spalte
         brachen sie neben den Sprachknoepfen frueh um und liessen die Flaeche darunter leer.
         Ueber die volle Breite brauchen sie zugleich weniger Zeilen. -->
    <TextBlock x:Name="TxtIntro" Foreground="#555" TextWrapping="Wrap" Margin="0,0,0,8"/>
    <Border BorderBrush="#D9B36A" BorderThickness="1" Background="#FFF8E7"
            Padding="8,6" Margin="0,0,0,10">
      <TextBlock x:Name="TxtUnofficial" TextWrapping="Wrap" Foreground="#6B5210" FontSize="12"/>
    </Border>

    <GroupBox x:Name="GrpState" Padding="9" Margin="0,0,0,10">
      <StackPanel>
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <TextBlock x:Name="CapEdition" Grid.Row="0" Grid.Column="0" Margin="0,0,10,2"/>
          <TextBlock x:Name="TxtEdition" Grid.Row="0" Grid.Column="1" Text="-" Margin="0,0,0,2" TextWrapping="Wrap"/>
          <TextBlock x:Name="CapLast" Grid.Row="1" Grid.Column="0" Margin="0,0,10,2"/>
          <TextBlock x:Name="TxtLast" Grid.Row="1" Grid.Column="1" Text="-" Margin="0,0,0,2"/>
          <TextBlock x:Name="CapNext" Grid.Row="2" Grid.Column="0" Margin="0,0,10,2"/>
          <TextBlock x:Name="TxtNext" Grid.Row="2" Grid.Column="1" Text="-" Margin="0,0,0,2" TextWrapping="Wrap"/>
          <TextBlock x:Name="CapDelta" Grid.Row="3" Grid.Column="0" Margin="0,0,10,2"/>
          <TextBlock x:Name="TxtDelta" Grid.Row="3" Grid.Column="1" Text="-" Margin="0,0,0,2" TextWrapping="Wrap"/>
          <TextBlock x:Name="CapTaskState" Grid.Row="4" Grid.Column="0" Margin="0,0,10,2"/>
          <TextBlock x:Name="TxtTaskState" Grid.Row="4" Grid.Column="1" Text="-" Margin="0,0,0,2" TextWrapping="Wrap"/>
          <!-- Der Knopf steht in der Zeile, zu der er gehoert, und nicht unten bei den
               uebrigen: Er handelt von der Umgebung, deren Zustand daneben steht. -->
          <!-- Der Knopf macht diese Zeile hoeher als die vier darueber. Damit das nicht
               schief aussieht, wird die Beschriftung mittig gesetzt statt oben, und der
               Knopf bleibt flach: 21 Pixel sind gerade genug fuer die Schrift und lassen
               die Zeile nur wenig wachsen. -->
          <TextBlock x:Name="CapWinRE" Grid.Row="5" Grid.Column="0" Margin="0,0,10,0"
                     VerticalAlignment="Center"/>
          <StackPanel Grid.Row="5" Grid.Column="1" Orientation="Horizontal">
            <TextBlock x:Name="TxtWinRE" Text="-" VerticalAlignment="Center" TextWrapping="Wrap"/>
            <Button x:Name="BtnWinRE" Height="21" Padding="9,0" Margin="12,0,0,0" FontSize="11"
                    VerticalAlignment="Center"/>
          </StackPanel>
        </Grid>
        <Border BorderBrush="#C9D6E4" BorderThickness="1" Background="#EEF4FA"
                Padding="8,5" Margin="0,8,0,0">
          <TextBlock x:Name="TxtIdleNote" TextWrapping="Wrap" Foreground="#2C4A66" FontSize="12"/>
        </Border>
        <!-- Erscheint erst, wenn Laeufe ausgefallen sind, und beantwortet die Frage, die
             dann unweigerlich kommt: normal, oder meldet Windows gar keinen Leerlauf mehr?
             Gelb wie der Veraltet-Hinweis - eine Frage, kein Fehler. -->
        <Border x:Name="BoxIdle" BorderBrush="#D9B36A" BorderThickness="1" Background="#FFF8E7"
                Padding="8,6" Margin="0,8,0,0" Visibility="Collapsed">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock x:Name="TxtIdleDiag" Grid.Column="0" TextWrapping="Wrap"
                       VerticalAlignment="Center" Foreground="#6B5210" FontSize="12"/>
            <Button x:Name="BtnIdleChk" Grid.Column="1" Height="24" Padding="12,0" Margin="12,0,0,0"
                    FontSize="12" VerticalAlignment="Center"/>
          </Grid>
        </Border>
        <!-- Nur sichtbar, wenn die Umgebung fehlt. Rot, weil in dem Fall alles andere
             in diesem Fenster folgenlos bleibt. -->
        <Border x:Name="BoxWinRE" BorderBrush="#E3B4B4" BorderThickness="1" Background="#FDF0F0"
                Padding="8,5" Margin="0,8,0,0" Visibility="Collapsed">
          <TextBlock x:Name="TxtWinReNote" TextWrapping="Wrap" Foreground="#8A2C2C" FontSize="12"/>
        </Border>
      </StackPanel>
    </GroupBox>

    <GroupBox x:Name="GrpPoints" Padding="9" Margin="0,0,0,10">
      <StackPanel>
        <!-- WrapPanel statt einer festen Zeile: Anzahl und aeltester Punkt stehen
             nebeneinander, rutschen aber um, wenn der 72-Stunden-Hinweis die Zeile
             sprengt. Zwei Textblocks bleiben es, damit sich nur der hintere gruen
             faerben kann. -->
        <WrapPanel Orientation="Horizontal" Margin="0,0,0,4">
          <TextBlock x:Name="TxtPoints" Text="-"/>
          <TextBlock Text="  ·  " Foreground="#AAAAAA"/>
          <TextBlock x:Name="TxtOldest" Text="-"/>
        </WrapPanel>
        <TextBlock x:Name="TxtStorage" Text="-" Margin="0,0,0,2" TextWrapping="Wrap"/>
        <TextBlock x:Name="TxtStoreNote" Foreground="#666" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,6"/>
        <ListView x:Name="LstPoints" Height="118" BorderThickness="1" BorderBrush="#DDD"
                  ScrollViewer.HorizontalScrollBarVisibility="Disabled">
          <ListView.View>
            <GridView>
              <GridViewColumn Width="172" DisplayMemberBinding="{Binding Zeitpunkt}"/>
              <GridViewColumn Width="90"  DisplayMemberBinding="{Binding Alter}"/>
              <GridViewColumn Width="90"  DisplayMemberBinding="{Binding Dauer}"/>
              <GridViewColumn Width="190" DisplayMemberBinding="{Binding Status}"/>
              <GridViewColumn Width="110" DisplayMemberBinding="{Binding Version}"/>
            </GridView>
          </ListView.View>
        </ListView>
        <!-- Nur sichtbar, solange der Aufgabenverlauf aus ist: Ohne ihn bleibt die
             Spalte "Dauer" leer, und der Knopf ist der einzige Weg dorthin. -->
        <Grid x:Name="RowHist" Margin="0,6,0,0" Visibility="Collapsed">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBlock x:Name="TxtHistHint" Grid.Column="0" Foreground="#777" FontSize="11"
                     TextWrapping="Wrap" VerticalAlignment="Center" Margin="2,0,10,0"/>
          <Button x:Name="BtnHist" Grid.Column="1" Height="22" Padding="10,0" FontSize="11"/>
        </Grid>
        <Border BorderBrush="#C9D6E4" BorderThickness="1" Background="#EEF4FA"
                Padding="8,5" Margin="0,8,0,0">
          <TextBlock x:Name="TxtVolumeNote" TextWrapping="Wrap" Foreground="#2C4A66" FontSize="12"/>
        </Border>
      </StackPanel>
    </GroupBox>

    <GroupBox x:Name="GrpSet" Padding="9" Margin="0,0,0,10">
      <StackPanel>
        <TextBlock x:Name="CapActive" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbActive" Margin="0,3,0,2"/>
        <TextBlock x:Name="LblActive" Foreground="#666" FontSize="11" Margin="0,0,0,8" TextWrapping="Wrap"/>

        <TextBlock x:Name="CapFreq" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbFreq" Margin="0,3,0,2"/>
        <TextBlock x:Name="LblFreq" Foreground="#666" FontSize="11" Margin="0,0,0,8" TextWrapping="Wrap"/>

        <TextBlock x:Name="CapReten" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbReten" Margin="0,3,0,2"/>
        <TextBlock x:Name="LblReten" Foreground="#666" FontSize="11" Margin="0,0,0,8" TextWrapping="Wrap"/>

        <TextBlock x:Name="CapSize" FontWeight="SemiBold"/>
        <ComboBox x:Name="CmbSize" Margin="0,3,0,2"/>
        <TextBlock x:Name="LblSize" Foreground="#666" FontSize="11" TextWrapping="Wrap"/>
      </StackPanel>
    </GroupBox>

    <Grid Margin="0,0,0,10">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="Auto"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <Button x:Name="BtnReset" Grid.Column="0" Width="170" Height="30" HorizontalAlignment="Left"/>
      <StackPanel Grid.Column="2" Orientation="Horizontal">
        <Button x:Name="BtnRefresh"  Width="120" Height="30" Margin="0,0,8,0"/>
        <Button x:Name="BtnApply"    Width="130" Height="30" Margin="0,0,8,0"/>
        <Button x:Name="BtnApplyNow" Width="230" Height="30"/>
      </StackPanel>
    </Grid>

    <GroupBox x:Name="GrpLog" Padding="6">
      <StackPanel>
        <TextBox x:Name="TxtLog" IsReadOnly="True" TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto" Height="76"
                 BorderThickness="1" BorderBrush="#DDD" Background="White"
                 Padding="6" FontFamily="Consolas" FontSize="12"/>
        <!-- Beim Protokoll und nicht bei den Knoepfen unten: Was hier herauskommt, ist
             ein Textbericht, und genau darum geht es bei dem Knopf. Die Erklaerung steht
             daneben und nicht darunter, damit die Zeile keine zusaetzliche Hoehe kostet. -->
        <Grid Margin="0,6,0,0">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBlock x:Name="TxtCopyHint" Grid.Column="0" Foreground="#777" FontSize="11"
                     TextWrapping="Wrap" VerticalAlignment="Center" Margin="2,0,12,0"/>
          <Button x:Name="BtnCopy" Grid.Column="1" Height="24" Padding="12,0" FontSize="12"/>
        </Grid>
      </StackPanel>
    </GroupBox>

    </StackPanel>
  </ScrollViewer>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$ctl = @{}
foreach ($n in 'TxtHead','TxtSub','TxtIntro','TxtUnofficial',
               'LnkProject','LnkGuide','RunGuide',
               'TxtUpdate','LnkUpdate','RunUpdate',
               'BtnLangEN','BtnLangDE','BtnLangFR','BtnLangES','BtnLangPT',
               'BtnLangIT','BtnLangPL',
               'BtnSnapNow','TxtSnapHint','ChkAuto','CmbAutoDelay','TxtAutoHint',
               'BoxStale','TxtStale','BtnAutoUpd',
               'GrpState','CapEdition','TxtEdition','CapLast','TxtLast','CapNext','TxtNext',
               'CapWinRE','TxtWinRE','BtnWinRE','BoxWinRE','TxtWinReNote','BtnCopy','TxtCopyHint',
               'CapTaskState','TxtTaskState','CapDelta','TxtDelta','TxtIdleNote',
               'BoxIdle','TxtIdleDiag','BtnIdleChk',
               'GrpPoints','TxtPoints','TxtOldest','TxtStorage','TxtStoreNote','LstPoints',
               'RowHist','TxtHistHint','BtnHist',
               'TxtVolumeNote',
               'GrpSet','CapActive','CmbActive','LblActive','CapFreq','CmbFreq','LblFreq',
               'CapReten','CmbReten','LblReten','CapSize','CmbSize','LblSize',
               'BtnReset','BtnRefresh','BtnApply','BtnApplyNow','GrpLog','TxtLog') {
    $ctl[$n] = $window.FindName($n)
}

# Marks the active language button. Built once - a brush per repaint would be wasteful.
$BrushActiveLang = New-Object System.Windows.Media.SolidColorBrush (
    [System.Windows.Media.ColorConverter]::ConvertFromString('#CFE3F7'))

# The check runs in its own runspace, because a hanging proxy on the UI thread would
# freeze the window for the length of the timeout. Every failure stays silent - no network,
# a firewall, GitHub down, the rate limit reached: the tool then behaves exactly as it did
# before. An update notice is never worth an error message.
#
# Deliberately no automatic download and no self-replacement. This tool writes to HKLM;
# something in that position quietly replacing its own code from the internet is precisely
# the shape people are warned about, and it would make the published checksums pointless.
function Start-UpdateCheck {
    if ($env:PITR_NOUPDATE) { return $null }
    try {
        $ps = [PowerShell]::Create()
        $ps.AddScript({
            param($Url)
            try {
                [Net.ServicePointManager]::SecurityProtocol =
                    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                $r = Invoke-RestMethod -Uri $Url -Headers @{ 'User-Agent' = 'pitr-config' } -TimeoutSec 3
                [pscustomobject]@{ Tag = [string]$r.tag_name; Url = [string]$r.html_url }
            } catch { $null }
        }).AddArgument($UpdateApi) | Out-Null
        return [pscustomobject]@{ Shell = $ps; Handle = $ps.BeginInvoke() }
    } catch { return $null }
}

function Show-UpdateNotice {
    param($Info)
    if (-not $Info -or -not $Info.Tag) { return }
    $new = ([string]$Info.Tag).TrimStart('vV')
    $newer = $false
    try { $newer = [version]$new -gt [version]$Version } catch { }
    if (-not $newer) { return }
    $script:UpdateVersion = $new
    $script:UpdateUrl     = [string]$Info.Url
    $ctl.RunUpdate.Text   = (T 'updAvail') -f $new
    $ctl.LnkUpdate.ToolTip = T 'tipUpdate'
    $ctl.TxtUpdate.Visibility = 'Visible'
}

# ---------------------------------------------------------------- Helpers --
function Write-Log {
    param([string]$Text)
    $stamp = (Get-Date).ToString('HH:mm:ss')
    # Im kopflosen Betrieb gibt es kein Fenster, an das man schreiben koennte - dann
    # in die Konsole. Dieselbe Funktion, damit Invoke-TaskNow nichts davon wissen muss.
    if ($script:Headless) { Write-Host "[$stamp] $Text"; return }
    $ctl.TxtLog.AppendText("[$stamp] $Text`r`n")
    $ctl.TxtLog.ScrollToEnd()
}

# Keeps the window repainting while work is in progress.
function Update-Ui {
    if ($script:Headless) { return }
    $window.Dispatcher.Invoke([action] {}, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
}

function Add-Choice {
    param($Combo, [string]$Text, $TagValue)
    $i = New-Object System.Windows.Controls.ComboBoxItem
    $i.Content = $Text
    $i.Tag = if ($null -eq $TagValue) { '' } else { [string]$TagValue }
    $Combo.Items.Add($i) | Out-Null
}

function Select-ByTag {
    param($Combo, $TagValue)
    $target = if ($null -eq $TagValue) { '' } else { [string]$TagValue }
    foreach ($item in $Combo.Items) {
        if ([string]$item.Tag -eq $target) { $Combo.SelectedItem = $item; return }
    }
    $Combo.SelectedIndex = 0
}

function Get-SelectedTag {
    param($Combo)
    if (-not $Combo.SelectedItem) { return $null }
    $t = [string]$Combo.SelectedItem.Tag
    if ([string]::IsNullOrEmpty($t)) { return $null }
    return [int]$t
}

# The drop-down lists are built from code so that a language switch can relabel
# them without losing the current selection.
function Build-Choices {
    $keep = @{}
    foreach ($n in 'CmbActive', 'CmbFreq', 'CmbReten', 'CmbSize') {
        $keep[$n] = if ($ctl[$n].SelectedItem) { [string]$ctl[$n].SelectedItem.Tag } else { '' }
        $ctl[$n].Items.Clear()
    }

    Add-Choice $ctl.CmbActive (T 'optNoOver') $null
    Add-Choice $ctl.CmbActive (T 'optOn')  1
    Add-Choice $ctl.CmbActive (T 'optOff') 0

    Add-Choice $ctl.CmbFreq (T 'optStdFreq') $null
    foreach ($h in 1, 2, 4, 6, 8, 12, 16, 24) {
        $u = if ($h -eq 1) { T 'unitHour' } else { T 'unitHours' }
        Add-Choice $ctl.CmbFreq "$h $u" ($h * 60)
    }

    Add-Choice $ctl.CmbReten (T 'optStdRet') $null
    foreach ($d in 1, 2, 3, 4, 5, 6, 7) {
        $du = if ($d -eq 1) { T 'unitDay' } else { T 'unitDays' }
        Add-Choice $ctl.CmbReten "$d $du ($($d * 24) $(T 'unitHours'))" ($d * 1440)
    }

    Add-Choice $ctl.CmbSize (T 'optNoOver') $null
    foreach ($g in 2, 4, 6, 8, 10, 12, 16, 20, 25, 30, 40, 50) {
        Add-Choice $ctl.CmbSize "$g GB" ($g * 1024)
    }

    foreach ($n in 'CmbActive', 'CmbFreq', 'CmbReten', 'CmbSize') {
        Select-ByTag $ctl[$n] $keep[$n]
    }
}

function Apply-Language {
    $window.Title        = T 'winTitle'
    $ctl.TxtHead.Text    = T 'headline'
    $ctl.TxtSub.Text     = "$(T 'subtitle')  ·  Version $Version"
    $ctl.TxtIntro.Text       = T 'intro'
    $ctl.TxtUnofficial.Text  = T 'unofficial'
    $ctl.RunGuide.Text       = T 'lnkGuide'
    $ctl.LnkProject.ToolTip  = T 'tipProject'
    $ctl.LnkGuide.ToolTip    = T 'tipGuide'
    $ctl.BtnSnapNow.Content  = T 'btnSnapNow'
    $ctl.BtnSnapNow.ToolTip  = T 'tipSnapNow'
    $ctl.BtnWinRE.Content    = T 'btnWinRE'
    $ctl.BtnWinRE.ToolTip    = T 'tipWinRE'
    $ctl.BtnCopy.Content     = T 'btnCopy'
    $ctl.BtnCopy.ToolTip     = T 'tipCopy'
    $ctl.TxtCopyHint.Text    = T 'copyHint'
    $ctl.CapWinRE.Text       = T 'capWinRE'
    $ctl.TxtWinReNote.Text   = T 'noteWinRE'
    $ctl.TxtSnapHint.Text    = T 'snapHint'
    $ctl.ChkAuto.Content     = T 'chkAuto'
    $ctl.ChkAuto.ToolTip     = T 'tipAuto'
    $ctl.TxtAutoHint.Text    = T 'autoHint'
    $ctl.CmbAutoDelay.ToolTip = T 'tipAuto'
    $ctl.BtnAutoUpd.Content   = T 'btnAutoUpd'
    Build-DelayChoices

    # The notice may already be on screen when the language is switched.
    if ($script:UpdateVersion) {
        $ctl.RunUpdate.Text    = (T 'updAvail') -f $script:UpdateVersion
        $ctl.LnkUpdate.ToolTip = T 'tipUpdate'
    }

    # The active language is marked, not disabled: IsEnabled belongs to Set-Busy, which
    # would otherwise switch it back on and lose the marking.
    foreach ($code in $LangCodes) {
        $b = $ctl['BtnLang' + $code.ToUpper()]
        if ($code -eq $script:Lang) {
            $b.FontWeight = [System.Windows.FontWeights]::Bold
            $b.Background = $BrushActiveLang
        } else {
            $b.FontWeight = [System.Windows.FontWeights]::Normal
            $b.ClearValue([System.Windows.Controls.Control]::BackgroundProperty)
        }
    }

    $ctl.GrpState.Header  = T 'grpState'
    $ctl.CapEdition.Text  = T 'capEdition'
    $ctl.CapLast.Text     = T 'capLast'
    $ctl.CapNext.Text      = T 'capNext'
    $ctl.CapTaskState.Text = T 'capTaskSt'
    $ctl.CapDelta.Text     = T 'capDelta'
    $ctl.TxtIdleNote.Text  = T 'noteIdle'
    $ctl.BtnIdleChk.Content = T 'btnIdleChk'

    $ctl.GrpPoints.Header   = T 'grpPoints'
    $ctl.TxtStoreNote.Text  = T 'noteStore'
    $ctl.TxtStorage.ToolTip = T 'tipStore'
    $ctl.TxtVolumeNote.Text = (T 'noteVolume') -f $env:SystemDrive

    $cols = $ctl.LstPoints.View.Columns
    $cols[0].Header = T 'colTime'
    $cols[1].Header = T 'colAge'
    $cols[2].Header = T 'colDur'
    $cols[3].Header = T 'colStatus'
    $cols[4].Header = T 'colBuild'
    $ctl.TxtHistHint.Text = T 'histHint'
    $ctl.BtnHist.Content  = T 'btnHist'

    $ctl.GrpSet.Header  = T 'grpSet'
    $ctl.CapActive.Text = T 'capActive'
    $ctl.CapFreq.Text   = T 'capFreq'
    $ctl.CapReten.Text  = T 'capReten'
    $ctl.CapSize.Text   = T 'capSize'

    $ctl.BtnReset.Content    = T 'btnReset'
    $ctl.BtnRefresh.Content  = T 'btnRefresh'
    $ctl.BtnApply.Content    = T 'btnApply'
    $ctl.BtnApplyNow.Content = T 'btnApplyNow'
    $ctl.GrpLog.Header       = T 'grpLog'

    Build-Choices
}

# Ausgefallene Laeufe sagen fuer sich genommen nichts: Sie sind der Normalfall,
# solange jemand am Rechner sitzt. Verdaechtig wird es erst, wenn ueberhaupt keine
# der anderen leerlaufgebundenen Aufgaben mehr laeuft - dann meldet Windows systemweit
# keinen Leerlauf, etwa weil ein Programm oder ein Treiber eine Energieanforderung
# haelt, und die Schnappschuesse sind nur das, was zuerst auffaellt.
#
# Die eigene Aufgabe bleibt bei der Zaehlung aussen vor: Sie laesst sich ueber den
# gruenen Knopf erzwingen und truege dann einen frischen Zeitstempel, der den ganzen
# Befund umkehren wuerde.
function Get-IdleHealth {
    $boot   = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    $mine   = $TaskPath + $TaskName
    $total  = 0
    $since  = 0
    $newest = $null
    foreach ($t in (Get-ScheduledTask -ErrorAction Stop)) {
        if (-not $t.Settings.RunOnlyIfIdle) { continue }
        if (($t.TaskPath + $t.TaskName) -eq $mine) { continue }
        $total++
        $i = Get-ScheduledTaskInfo -InputObject $t -ErrorAction SilentlyContinue
        if ($null -eq $i -or $null -eq $i.LastRunTime) { continue }
        # Noch nie gelaufene Aufgaben tragen den 30.11.1999 und wuerden das
        # "zuletzt im Leerlauf" verfaelschen.
        if ($i.LastRunTime.Year -lt 2000) { continue }
        if ($i.LastRunTime -gt $boot) { $since++ }
        if ($null -eq $newest -or $i.LastRunTime -gt $newest) { $newest = $i.LastRunTime }
    }
    # Kurz nach dem Systemstart ist "noch keine gelaufen" kein Befund, sondern zu frueh:
    # Leerlauf setzt Minuten ohne Eingabe voraus, und die Aufgaben verteilen sich ueber
    # Stunden. Zwei Stunden Laufzeit sind die Schwelle, ab der Schweigen etwas bedeutet.
    $upH = ((Get-Date) - $boot).TotalHours
    return [pscustomobject]@{
        Boot    = $boot
        UpHours = $upH
        Total   = $total
        Since   = $since
        Newest  = $newest
        Blocked = ($total -gt 0 -and $since -eq 0 -and $upH -ge 2)
    }
}

function Update-View {
    # Read the values first so the task state can be interpreted against them.
    $a = Get-PitrValue 'Active'
    $f = Get-PitrValue 'SnapshotInterval'
    $r = Get-PitrValue 'MaxTimespan'
    $s = Get-PitrValue 'MaxGlobalSize'
    $effFreq = if ($null -eq $f) { 1440 } else { $f.Value }

    # ProductName still reads "Windows 10 ..." on Windows 11 - Microsoft never updated the
    # value, for application compatibility, so it cannot be shown as it stands. The build
    # number is the reliable discriminator: 22000 and above is Windows 11.
    $nt = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $osName = [string]$nt.ProductName
    $osBuild = 0
    [void][int]::TryParse([string]$nt.CurrentBuild, [ref]$osBuild)
    if ($osBuild -ge 22000) { $osName = $osName -replace '^Windows 10\b', 'Windows 11' }
    $osParts = @()
    if ($nt.DisplayVersion) { $osParts += [string]$nt.DisplayVersion }
    if ($nt.CurrentBuild)   { $osParts += "Build $($nt.CurrentBuild).$($nt.UBR)" }
    $edTxt = "$osName (EditionID: $($nt.EditionID))"
    if ($osParts.Count) { $edTxt += '  —  ' + ($osParts -join ', ') }
    $ctl.TxtEdition.Text = $edTxt

    # --- Restore points ---
    $punkte = @(Get-RestorePoints)
    $ctl.LstPoints.ItemsSource = $punkte
    $ctl.RowHist.Visibility = if ($script:HistoryOff) { 'Visible' } else { 'Collapsed' }
    $ctl.TxtPoints.Text = "$(T 'lblCount'): $($punkte.Count)"

    # The oldest point shows directly whether the configured retention takes effect.
    $mitZeit = @($punkte | Where-Object { $null -ne $_.AlterStd })
    if ($mitZeit.Count -gt 0) {
        $aeltest = ($mitZeit | Sort-Object AlterStd -Descending)[0]
        $ot = "$(T 'lblOldest'): $($aeltest.Zeitpunkt) ($($aeltest.Alter))"
        if ($aeltest.AlterStd -gt 72.5) {
            $ot += '  —  ' + (T 'proven72')
            $ctl.TxtOldest.Foreground = [System.Windows.Media.Brushes]::DarkGreen
        } else {
            $ctl.TxtOldest.Foreground = [System.Windows.Media.Brushes]::Black
        }
        $ctl.TxtOldest.Text = $ot
    } else {
        $ctl.TxtOldest.Text = "$(T 'lblOldest'): -"
    }

    $st = Get-ShadowStorage
    if ($st) {
        $ctl.TxtStorage.Text = ('{0} {1} — {2} {3:N2} GB · {4} {5:N2} GB · {6} {7:N2} GB' -f
            (T 'lblStorage'), $st.Drive, (T 'stUsed'), ($st.Used / 1GB), (T 'stAlloc'), ($st.Alloc / 1GB),
            (T 'stMax'), ($st.Max / 1GB))
    } else {
        $ctl.TxtStorage.Text = ('{0} {1} — {2}' -f (T 'lblStorage'), $env:SystemDrive, (T 'stNoAdmin'))
    }

    # --- Scheduled task ---
    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        $info = Get-ScheduledTaskInfo -TaskPath $TaskPath -TaskName $TaskName
        $ctl.TxtLast.Text = Format-Stamp $info.LastRunTime

        # Der Lauf findet nur im Leerlauf statt - ein ueberfaelliger Termin ist daher
        # kein Fehler, sondern der Normalfall an einem benutzten Rechner.
        $nextTxt = Format-Stamp $info.NextRunTime
        if ($info.NextRunTime -and $info.NextRunTime -lt (Get-Date)) {
            $due = [math]::Round(((Get-Date) - $info.NextRunTime).TotalMinutes)
            $nextTxt += "  —  $(T 'tsOverdue') $due $(T 'unitMin')"
            $ctl.TxtNext.Foreground = [System.Windows.Media.Brushes]::DarkOrange
        } else {
            $ctl.TxtNext.Foreground = [System.Windows.Media.Brushes]::Black
        }
        $ctl.TxtNext.Text = $nextTxt

        # "Queued" heisst wortwoertlich: Der Lauf ist faellig, wartet aber auf Leerlauf.
        $stateName = "$($task.State)"
        $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::Black
        switch ($stateName) {
            'Ready'    { $ctl.TxtTaskState.Text = T 'tsReady' }
            'Queued'   { $ctl.TxtTaskState.Text = T 'tsQueued'
                         $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::DarkOrange }
            'Running'  { $ctl.TxtTaskState.Text = T 'tsRunning'
                         $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::DarkGreen }
            'Disabled' { $ctl.TxtTaskState.Text = T 'tsDisabled'
                         $ctl.TxtTaskState.Foreground = [System.Windows.Media.Brushes]::DarkOrange }
            default    { $ctl.TxtTaskState.Text = $stateName }
        }

        # Ausgefallene Laeufe gehoeren neben den Status: Sie sind die Erklaerung dafuer,
        # dass zwischen zwei Punkten mehr Zeit liegt als der eingeplante Abstand.
        if ($info.NumberOfMissedRuns -gt 0) {
            $ctl.TxtTaskState.Text += '  ·  ' + ((T 'missedRuns') -f $info.NumberOfMissedRuns)
            # Der Kasten stellt nur die Frage - beantwortet wird sie auf Knopfdruck,
            # weil die Antwort jede leerlaufgebundene Aufgabe einzeln abfragt und das
            # ein bis zwei Sekunden dauert. Ein geholter Befund bleibt danach stehen.
            if ($null -eq $script:IdleDiag) {
                $ctl.TxtIdleDiag.Text = (T 'idleBanner') -f $info.NumberOfMissedRuns
            } else {
                $ctl.TxtIdleDiag.Text = $script:IdleDiag
            }
            $ctl.BoxIdle.Visibility = 'Visible'
        } else {
            $ctl.BoxIdle.Visibility = 'Collapsed'
        }

        Update-WinReRow
        Update-AutoRow

        # The scheduled interval is the repetition of the time trigger. Deriving it from
        # "next run minus last run" was wrong: when a run is skipped because the machine is
        # not idle - the normal case, and the very thing the note below explains - that gap
        # grows to a multiple of the interval while the schedule itself is unchanged.
        $planned = $null
        foreach ($tr in $task.Triggers) {
            if ($tr.Repetition -and $tr.Repetition.Interval) {
                try {
                    $planned = [System.Xml.XmlConvert]::ToTimeSpan([string]$tr.Repetition.Interval).TotalMinutes
                    break
                } catch { }
            }
        }

        if ($null -ne $planned) {
            $d = [math]::Round($planned)
            # Format-Duration statt fester Pluralform: sonst steht dort "1 hours".
            $txt = "$d $(T 'unitMin') = $(Format-Duration $d)"
            # PITRTask rewrites its own trigger only while running, so right after a change
            # the trigger can still carry the previous value - not a contradiction, just a
            # carry-over. One minute of tolerance absorbs rounding of seconds.
            if ([math]::Abs($d - $effFreq) -gt 1) {
                $txt += '  —  ' + (T 'carryOver') + ' ' + (Format-Duration $effFreq)
                $ctl.TxtDelta.Foreground = [System.Windows.Media.Brushes]::DarkOrange
            } else {
                $ctl.TxtDelta.Foreground = [System.Windows.Media.Brushes]::Black
            }
            $ctl.TxtDelta.Text = $txt
        } else {
            $ctl.TxtDelta.Text = T 'unknownTxt'
        }
    } catch {
        $ctl.TxtLast.Text       = T 'taskMissing'
        $ctl.TxtNext.Text       = '-'
        $ctl.TxtTaskState.Text  = '-'
        $ctl.TxtDelta.Text      = '-'
        $ctl.BoxIdle.Visibility = 'Collapsed'
    }

    # The drop-downs show our own (policy) values only; other levels stay on "default".
    Select-ByTag $ctl.CmbActive $(if ($a -and $a.Level -eq $Level) { $a.Value } else { $null })
    Select-ByTag $ctl.CmbFreq   $(if ($f -and $f.Level -eq $Level) { $f.Value } else { $null })
    Select-ByTag $ctl.CmbReten  $(if ($r -and $r.Level -eq $Level) { $r.Value } else { $null })
    Select-ByTag $ctl.CmbSize   $(if ($s -and $s.Level -eq $Level) { $s.Value } else { $null })

    $eff = T 'effective'
    $src = T 'source'

    $ctl.LblActive.Text = if ($null -eq $a) { "${eff}: $(T 'winDefault')" }
                          else { "${eff}: $(if ($a.Value -eq 1) { T 'optOn' } else { T 'optOff' }) — ${src}: $(Get-LevelLabel $a.Level)" }

    $ctl.LblFreq.Text   = if ($null -eq $f) { "${eff}: 24 $(T 'unitHours') ($(T 'winDefault'))" }
                          else { "${eff}: $(Format-Duration $f.Value) — ${src}: $(Get-LevelLabel $f.Level)" }

    # Retention beyond 72 hours was confirmed in practice (a point aged 3.7 days
    # survived), so no special warning is shown here any more.
    $ctl.LblReten.Text = if ($null -eq $r) { "${eff}: $(Format-Duration $RetentionDefault) ($(T 'winDefault'))" }
                         else { "${eff}: $(Format-Duration $r.Value) — ${src}: $(Get-LevelLabel $r.Level)" }
    $ctl.LblReten.Foreground = [System.Windows.Media.Brushes]::Gray

    $ctl.LblSize.Text   = if ($null -eq $s) { "${eff}: $(T 'sizeStd')" }
                          else { "${eff}: $([math]::Round($s.Value/1024,1)) GB — ${src}: $(Get-LevelLabel $s.Level)" }
}

# Die Auswahl wird bei jedem Sprachwechsel neu aufgebaut, deshalb merkt sie sich den
# eingestellten Wert und setzt ihn danach wieder.
function Build-DelayChoices {
    $keep = Get-SelectedTag $ctl.CmbAutoDelay
    if ($null -eq $keep) { $keep = 5 }
    $ctl.CmbAutoDelay.Items.Clear()
    foreach ($m in 1, 2, 5, 10, 15, 30) {
        $u = if ($m -eq 1) { T 'unitMin1' } else { T 'unitMin' }
        Add-Choice $ctl.CmbAutoDelay "$m $u" $m
    }
    Select-ByTag $ctl.CmbAutoDelay $keep
}

# Setzt Haken und Auswahl auf den tatsaechlichen Zustand der Aufgabe, ohne dabei das
# Ereignis auszuloesen - sonst wuerde jedes Aktualisieren die Aufgabe neu schreiben.
function Update-AutoRow {
    $a = Get-AutoStart
    $script:AutoQuiet = $true
    try {
        $ctl.ChkAuto.IsChecked = ($null -ne $a)
        if ($null -ne $a) { Select-ByTag $ctl.CmbAutoDelay $a.Delay }
    } finally { $script:AutoQuiet = $false }

    $s = Get-AutoStartState
    if ($null -ne $s -and $s.Stale) {
        $ctl.TxtStale.Text = switch ($s.Reason) {
            'gone'    { (T 'staleGone') -f $s.Path }
            'content' { (T 'staleSame') -f $Version, $s.Path }
            default   { (T 'staleOld')  -f $s.Version, $s.Path, $Version }
        }
        $ctl.BoxStale.Visibility = 'Visible'
    } else {
        $ctl.BoxStale.Visibility = 'Collapsed'
    }
}

function Update-WinReRow {
    $re = Get-WinReState
    if ($null -eq $re) {
        $ctl.TxtWinRE.Text = T 'winreUnk'
        $ctl.TxtWinRE.Foreground = [System.Windows.Media.Brushes]::Gray
        $ctl.BoxWinRE.Visibility = 'Collapsed'
        return
    }
    if ($re.Enabled) {
        $txt = T 'winreOn'
        if ($re.Size) {
            $txt += '  ·  ' + [string][math]::Round($re.Size / 1MB) + ' MB'
            if ($re.Free) { $txt += ', ' + [string][math]::Round($re.Free / 1MB) + ' MB ' + (T 'winreFree') }
        }
        $ctl.TxtWinRE.Text = $txt
        $ctl.TxtWinRE.Foreground = [System.Windows.Media.Brushes]::Black
        $ctl.BoxWinRE.Visibility = 'Collapsed'
    } else {
        $ctl.TxtWinRE.Text = T 'winreOff'
        $ctl.TxtWinRE.Foreground = New-Object System.Windows.Media.SolidColorBrush (
            [System.Windows.Media.ColorConverter]::ConvertFromString('#B02A2A'))
        $ctl.BoxWinRE.Visibility = 'Visible'
    }
}

# Der Bericht ist bewusst genau das, was in einem Forenthread als Erstes erfragt wird.
# Er benutzt die eingestellte Sprache: Wer auf Deutsch fragt, postet ihn auf Deutsch.
function Get-StateReport {
    $nl = [Environment]::NewLine
    $out = New-Object System.Text.StringBuilder
    [void]$out.AppendLine("pitr-config $Version - $(T 'grpState')")
    [void]$out.AppendLine((Get-Date).ToString('u'))
    [void]$out.AppendLine('')
    foreach ($row in @(
        @{ C = $ctl.CapEdition.Text;  V = $ctl.TxtEdition.Text }
        @{ C = $ctl.CapLast.Text;     V = $ctl.TxtLast.Text }
        @{ C = $ctl.CapNext.Text;     V = $ctl.TxtNext.Text }
        @{ C = $ctl.CapDelta.Text;    V = $ctl.TxtDelta.Text }
        @{ C = $ctl.CapTaskState.Text;V = $ctl.TxtTaskState.Text }
        @{ C = $ctl.CapWinRE.Text;    V = $ctl.TxtWinRE.Text })) {
        [void]$out.AppendLine(('{0,-28} {1}' -f $row.C, $row.V))
    }
    [void]$out.AppendLine('')
    [void]$out.AppendLine("$(T 'grpPoints'): $($ctl.TxtPoints.Text)  ·  $($ctl.TxtOldest.Text)")
    [void]$out.AppendLine($ctl.TxtStorage.Text)
    [void]$out.AppendLine('')
    [void]$out.AppendLine("$(T 'grpSet'):")
    foreach ($row in @(
        @{ C = $ctl.CapActive.Text; V = $ctl.LblActive.Text }
        @{ C = $ctl.CapFreq.Text;   V = $ctl.LblFreq.Text }
        @{ C = $ctl.CapReten.Text;  V = $ctl.LblReten.Text }
        @{ C = $ctl.CapSize.Text;   V = $ctl.LblSize.Text })) {
        [void]$out.AppendLine(('  {0}{1}    {2}' -f $row.C, $nl, $row.V))
    }
    return $out.ToString()
}

# Windows legt beim Start von sich aus einen Punkt an - PITRTask hat einen
# Boot-Trigger mit 30 Minuten Verzoegerung. Er verpufft nur, weil RunOnlyIfIdle gilt
# und ein frisch gestarteter Rechner nicht im Leerlauf ist. Diese Aufgabe hier setzt
# nicht noch einen Trigger obendrauf, sondern erzwingt den Lauf so, wie es der Knopf
# im Fenster tut: Bedingung kurz aufheben, starten, zuruecksetzen.
#
# Die Windows-Aufgabe selbst bleibt unangetastet. Wer dort RunOnlyIfIdle dauerhaft
# abschaltet, laesst Schattenkopien mitten in der Arbeit anlaufen - und beim naechsten
# Funktionsupdate steht der Wert ohnehin wieder auf Vorgabe.
$AutoTaskPath = '\pitr-config\'
$AutoTaskName = 'Startup snapshot'

function Get-AutoStart {
    try {
        $t = Get-ScheduledTask -TaskPath $AutoTaskPath -TaskName $AutoTaskName -ErrorAction Stop
        $d = 5
        foreach ($tr in $t.Triggers) {
            if ($tr.Delay) {
                try { $d = [int][System.Xml.XmlConvert]::ToTimeSpan([string]$tr.Delay).TotalMinutes } catch { }
            }
        }
        return [pscustomobject]@{ Enabled = $true; Delay = $d; Action = $t.Actions[0].Arguments }
    } catch { }
    return $null
}

function Set-AutoStart {
    param([int]$DelayMinutes = 5, [string]$SelfPath)
    $self = if ($SelfPath) { $SelfPath } else { $env:PITR_SELF }
    if (-not $self) { throw 'PITR_SELF is not set' }
    $act = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument ('/c "' + $self + '" snapshot')
    $trg = New-ScheduledTaskTrigger -AtStartup
    $trg.Delay = 'PT{0}M' -f $DelayMinutes
    $prn = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    # StartWhenAvailable holt einen verpassten Start nach; ExecutionTimeLimit verhindert,
    # dass eine haengende Schattenkopie die Aufgabe dauerhaft blockiert.
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                                        -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
    Register-ScheduledTask -TaskPath $AutoTaskPath -TaskName $AutoTaskName -Action $act `
                           -Trigger $trg -Principal $prn -Settings $set -Force | Out-Null
}

# Die Aufgabe laeuft als SYSTEM. SYSTEM erreicht eine Netzwerkfreigabe als Computerkonto
# und nicht als der angemeldete Mensch - deshalb scheitert ein Startschnappschuss von
# einer Freigabe auch dann, wenn sie sich im Explorer anstandslos oeffnet. Eine lokale
# Kopie loest das; ProgramData, weil SYSTEM dort schreiben und lesen darf.
$LocalCopyDir = Join-Path $env:ProgramData 'pitr-config'

# Die Versionszeile steht im Kopf des PowerShell-Teils, also weit innerhalb der ersten
# 200 Zeilen. Mehr zu lesen waere Verschwendung - die Datei ist 160 KB gross.
function Get-FileVersion {
    param([string]$Path)
    try {
        foreach ($l in (Get-Content -LiteralPath $Path -TotalCount 200 -ErrorAction Stop)) {
            if ($l -match "^\`$Version\s*=\s*'([^']+)'") { return $Matches[1] }
        }
    } catch { }
    return $null
}

# Die Aufgabe merkt sich einen festen Pfad. Wird spaeter eine neuere Fassung von der
# Freigabe gestartet, laeuft beim Systemstart weiterhin die alte Kopie - ohne dass es
# jemandem auffiele. Deshalb wird beides verglichen.
function Get-AutoStartState {
    $a = Get-AutoStart
    if ($null -eq $a) { return $null }

    $path = $null
    if ($a.Action -match '"([^"]+)"') { $path = $Matches[1] }
    if (-not $path) { return $null }

    $same = $false
    try { $same = ([IO.Path]::GetFullPath($path) -ieq [IO.Path]::GetFullPath($env:PITR_SELF)) } catch { }
    if ($same) { return [pscustomobject]@{ Path = $path; Stale = $false; Gone = $false; Version = $Version; Reason = 'same' } }

    if (-not (Test-Path -LiteralPath $path)) {
        return [pscustomobject]@{ Path = $path; Stale = $true; Gone = $true; Version = $null; Reason = 'gone' }
    }

    $v = Get-FileVersion $path
    # Gleiche Nummer, anderer Inhalt: kommt bei Zwischenstaenden vor, die noch keine
    # eigene Version tragen. Dann entscheidet der Vergleich der Pruefsummen. Welcher
    # der beiden Faelle vorliegt, muss mit heraus - sonst nennt der Hinweis zweimal
    # dieselbe Nummer und liest sich wie ein Fehler des Werkzeugs.
    $stale  = $false
    $reason = 'ok'
    if ($v -ne $Version) { $stale = $true; $reason = 'version' }
    else {
        try {
            $h1 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            $h2 = (Get-FileHash -LiteralPath $env:PITR_SELF -Algorithm SHA256).Hash
            if ($h1 -ne $h2) { $stale = $true; $reason = 'content' }
        } catch { }
    }
    return [pscustomobject]@{ Path = $path; Stale = $stale; Gone = $false; Version = $v; Reason = $reason }
}

function Copy-SelfLocal {
    if (-not (Test-Path -LiteralPath $LocalCopyDir)) {
        New-Item -ItemType Directory -Path $LocalCopyDir -Force | Out-Null
    }
    $dest = Join-Path $LocalCopyDir 'pitr-config.cmd'
    Copy-Item -LiteralPath $env:PITR_SELF -Destination $dest -Force
    return $dest
}

function Remove-AutoStart {
    try {
        Unregister-ScheduledTask -TaskPath $AutoTaskPath -TaskName $AutoTaskName -Confirm:$false -ErrorAction Stop
        return $true
    } catch { }
    return $false
}

# Eine Aufgabe merkt sich den Pfad der Datei. Liegt sie auf einer Freigabe oder einem
# Wechseldatentraeger, ist der zum Startzeitpunkt womoeglich noch nicht da.
function Test-SelfPathLocal {
    $self = $env:PITR_SELF
    if (-not $self) { return $false }
    if ($self.StartsWith('\\')) { return $false }
    try {
        $d = [IO.DriveInfo]::new(([IO.Path]::GetPathRoot($self)))
        return ($d.DriveType -eq 'Fixed')
    } catch { }
    return $false
}

function Save-Settings {
    $map = @(
        @{ Name = 'Active';           Combo = $ctl.CmbActive; Text = (T 'capActive') }
        @{ Name = 'SnapshotInterval'; Combo = $ctl.CmbFreq;   Text = 'SnapshotInterval' }
        @{ Name = 'MaxTimespan';      Combo = $ctl.CmbReten;  Text = 'MaxTimespan' }
        @{ Name = 'MaxGlobalSize';    Combo = $ctl.CmbSize;   Text = 'MaxGlobalSize' }
    )
    foreach ($m in $map) {
        $val = Get-SelectedTag $m.Combo
        if ($null -eq $val) {
            if (Remove-PitrValue $m.Name) { Write-Log "$($m.Name): $(T 'logCleared')" }
        } else {
            Set-PitrValue $m.Name $val
            Write-Log "$($m.Name)_$Level = $val"
        }
    }
}

function Invoke-TaskNow {
    # PITRTask has RunOnlyIfIdle=True and stays "Queued" while the machine is in use.
    # Lift that condition for exactly one run and restore it reliably afterwards.
    $restored = $false
    try {
        $t = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        $orig = $t.Settings.RunOnlyIfIdle
        $t.Settings.RunOnlyIfIdle = $false
        Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Settings $t.Settings | Out-Null
        Write-Log (T 'logIdleOff')
        Update-Ui

        # Gemessen wird die Laufzeit der Aufgabe: vom Start bis sie wieder auf "Ready"
        # steht. Das ist die Zeit, die Windows fuer die Schattenkopie braucht - die
        # Aufloesung betraegt die 1,5 Sekunden der Warteschleife, mehr braucht es nicht.
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Start-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        Write-Log (T 'logStarted')
        Update-Ui

        $finished = $false
        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Milliseconds 1500
            Update-Ui
            if ((Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName).State -eq 'Ready') {
                $finished = $true
                break
            }
        }
        $sw.Stop()
        $took = Format-Elapsed $sw.Elapsed.TotalSeconds

        $t2 = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
        $t2.Settings.RunOnlyIfIdle = $orig
        Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Settings $t2.Settings | Out-Null
        $restored = $true
        Write-Log (T 'logIdleOn')

        $info = Get-ScheduledTaskInfo -TaskPath $TaskPath -TaskName $TaskName
        if ($finished) {
            Write-Log "$(T 'logDone'): $($info.LastTaskResult), $((T 'logTook') -f $took), $(T 'logNextRun'): $(Format-Stamp $info.NextRunTime)"
        } else {
            # Die Schleife ist ausgelaufen, nicht die Aufgabe. Eine Dauer zu melden waere
            # hier falsch - sie waere die Wartezeit und nicht die des Schnappschusses.
            Write-Log ((T 'logNoFinish') -f $took)
        }
    } finally {
        if (-not $restored) {
            try {
                $t3 = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName
                $t3.Settings.RunOnlyIfIdle = $true
                Set-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Settings $t3.Settings | Out-Null
                Write-Log (T 'logIdleErr')
            } catch {
                Write-Log (T 'logIdleBad')
            }
        }
    }
}

function Set-Busy {
    param([bool]$On)
    $buttons = @('BtnSnapNow','BtnReset','BtnRefresh','BtnApply','BtnApplyNow','BtnWinRE','BtnCopy','BtnHist',
                 'ChkAuto','CmbAutoDelay','BtnAutoUpd','BtnIdleChk') +
               @($LangCodes | ForEach-Object { 'BtnLang' + $_.ToUpper() })
    foreach ($b in $buttons) { $ctl[$b].IsEnabled = -not $On }
    $window.Cursor = if ($On) { [System.Windows.Input.Cursors]::Wait } else { $null }
    Update-Ui
}

# --------------------------------------------------------------------- Events --
function Set-Lang {
    param([string]$Code)
    $script:Lang = $Code
    try { Apply-Language; Update-View }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
}

# Written out one by one on purpose: a handler built in a loop would either need a
# closure (which gets its own session state, breaking $script:Lang) or $this, and both
# are more fragile than five plain lines.
$ctl.BtnLangEN.Add_Click({ Set-Lang 'en' })
$ctl.BtnLangDE.Add_Click({ Set-Lang 'de' })
$ctl.BtnLangFR.Add_Click({ Set-Lang 'fr' })
$ctl.BtnLangES.Add_Click({ Set-Lang 'es' })
$ctl.BtnLangPT.Add_Click({ Set-Lang 'pt' })
$ctl.BtnLangIT.Add_Click({ Set-Lang 'it' })
$ctl.BtnLangPL.Add_Click({ Set-Lang 'pl' })

$ctl.LnkProject.Add_Click({
    try { Start-Process $ProjectUrl }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

$ctl.LnkGuide.Add_Click({
    try { Start-Process (Get-GuideUri) }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

$ctl.LnkUpdate.Add_Click({
    try { if ($script:UpdateUrl) { Start-Process $script:UpdateUrl } }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

# Bewusst ohne Save-Settings: Der Knopf soll einen Punkt erzeugen und sonst nichts.
# Wer die Einstellungen mit uebernehmen will, hat dafuer unten "Uebernehmen und sofort
# ausfuehren"; die Trennung macht den Schnappschuss zur folgenlosen Aktion.
$ctl.BtnSnapNow.Add_Click({
    Set-Busy $true
    try { Invoke-TaskNow; Update-View }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

$ctl.BtnRefresh.Add_Click({
    try { Update-View; Write-Log (T 'logRefresh') }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

$ctl.BtnApply.Add_Click({
    Set-Busy $true
    try { Save-Settings; Update-View; Write-Log (T 'logSaved') }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

$ctl.BtnApplyNow.Add_Click({
    Set-Busy $true
    try { Save-Settings; Invoke-TaskNow; Update-View }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

function Apply-AutoStart {
    if ($script:AutoQuiet) { return }
    Set-Busy $true
    try {
        if ($ctl.ChkAuto.IsChecked) {
            $d = Get-SelectedTag $ctl.CmbAutoDelay
            if ($null -eq $d) { $d = 5 }
            $path = $env:PITR_SELF
            if (-not (Test-SelfPathLocal)) {
                $nl = [Environment]::NewLine
                $answer = [System.Windows.MessageBox]::Show(
                    ((T 'askCopy') -f $nl, $LocalCopyDir), (T 'askCopyT'),
                    [System.Windows.MessageBoxButton]::YesNoCancel,
                    [System.Windows.MessageBoxImage]::Warning)
                if ($answer -eq [System.Windows.MessageBoxResult]::Cancel) {
                    $script:AutoQuiet = $true
                    try { $ctl.ChkAuto.IsChecked = $false } finally { $script:AutoQuiet = $false }
                    return
                }
                if ($answer -eq [System.Windows.MessageBoxResult]::Yes) {
                    $path = Copy-SelfLocal
                    Write-Log ((T 'logCopyOk') -f $path)
                } else {
                    Write-Log (T 'warnPath')
                }
            }
            Set-AutoStart -DelayMinutes $d -SelfPath $path
            Write-Log ((T 'logAutoOn') -f $d)
        } else {
            if (Remove-AutoStart) { Write-Log (T 'logAutoOff') }
        }
    }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
}

$ctl.ChkAuto.Add_Click({ Apply-AutoStart })

# Kopie erneuern und die Aufgabe darauf neu ausrichten - mit derselben Verzoegerung,
# die dort schon eingestellt war.
$ctl.BtnAutoUpd.Add_Click({
    Set-Busy $true
    try {
        $a = Get-AutoStart
        $d = if ($a) { $a.Delay } else { 5 }
        $path = Copy-SelfLocal
        Set-AutoStart -DelayMinutes $d -SelfPath $path
        Write-Log ((T 'logAutoUpd') -f $path, $Version)
        Update-View
    }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

# Der Befund wird gemerkt, damit ihn die naechste Aktualisierung der Ansicht nicht
# wieder durch die blosse Frage ersetzt.
$ctl.BtnIdleChk.Add_Click({
    Set-Busy $true
    $ctl.TxtIdleDiag.Text = T 'idleChecking'
    Update-Ui
    try {
        $h = Get-IdleHealth
        if ($h.Blocked) {
            $script:IdleDiag = (T 'idleBlocked') -f (Format-Stamp $h.Boot), $h.Total
        } elseif ($h.Since -eq 0) {
            $script:IdleDiag = (T 'idleEarly') -f $h.Total, (Format-Age $h.UpHours)
        } else {
            $script:IdleDiag = (T 'idleFine') -f $h.Since, $h.Total, (Format-Stamp $h.Newest)
        }
        # Ohne Rechte sind Teile der Aufgabenplanung unsichtbar. Bei einem positiven
        # Befund ist das harmlos, bei "blockiert" waere es ein Fehlalarm aus einer
        # Teilmenge - also gehoert der Vorbehalt an jeden der drei Befunde.
        if (-not (Test-Admin)) { $script:IdleDiag += T 'idlePartial' }
        $ctl.TxtIdleDiag.Text = $script:IdleDiag
        Write-Log ((T 'logIdleChk') -f $script:IdleDiag)
    }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})
$ctl.CmbAutoDelay.Add_SelectionChanged({ if ($ctl.ChkAuto.IsChecked) { Apply-AutoStart } })

$ctl.BtnHist.Add_Click({
    $answer = [System.Windows.MessageBox]::Show((T 'askHist'), (T 'askHistT'),
        [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    Set-Busy $true
    try {
        # wevtutil statt einer Registry-Aenderung: Der Aufgabenplaner liest den Zustand
        # ueber die Protokollkonfiguration, ein direkter Registry-Eingriff wirkt erst
        # nach einem Neustart des Dienstes.
        $p = Start-Process -FilePath 'wevtutil.exe' `
                           -ArgumentList 'sl', 'Microsoft-Windows-TaskScheduler/Operational', '/e:true' `
                           -Wait -PassThru -WindowStyle Hidden
        if ($p.ExitCode -eq 0) { Write-Log (T 'logHistOn') } else { Write-Log (T 'logHistErr') }
        Update-View
    }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

$ctl.BtnCopy.Add_Click({
    try {
        Set-Clipboard -Value (Get-StateReport)
        Write-Log (T 'logCopied')
    } catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

# Der einzige Knopf, der den Rechner neu startet - deshalb die Rueckfrage, und deshalb
# steht in ihrem Text, was dabei verloren geht.
$ctl.BtnWinRE.Add_Click({
    $answer = [System.Windows.MessageBox]::Show((T 'askWinRE'), (T 'askWinRET'),
        [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        Write-Log (T 'logWinRE')
        Update-Ui
        Start-Process -FilePath 'shutdown.exe' -ArgumentList '/r', '/o', '/t', '3' -WindowStyle Hidden
    } catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
})

$ctl.BtnReset.Add_Click({
    $answer = [System.Windows.MessageBox]::Show((T 'askReset'), (T 'askResetT'),
        [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
    Set-Busy $true
    try {
        $n = 0
        foreach ($name in 'Active','SnapshotInterval','MaxTimespan','MaxGlobalSize','MaxCount') {
            if (Remove-PitrValue $name) { Write-Log "$(T 'logRemoved'): ${name}_$Level"; $n++ }
        }
        if ($n -eq 0) { Write-Log (T 'logNothing') }
        Update-View
    }
    catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
    finally { Set-Busy $false }
})

# ---------------------------------------------------------------------- Start --
Apply-Language

# Die Felder tragen bis zur ersten Abfrage einen Platzhalter. "-" waere hier falsch:
# Das sieht nach einer Auskunft aus, obwohl noch gar nichts gelesen wurde.
foreach ($n in 'TxtEdition','TxtLast','TxtNext','TxtDelta','TxtTaskState','TxtWinRE',
               'TxtPoints','TxtOldest','TxtStorage') {
    $ctl[$n].Text = T 'loading'
}

# Die Arbeitsflaeche ist der Bildschirm ohne Taskleiste - was hineinpasst, kann von ihr
# nicht verdeckt werden. Davon geht noch eine Reserve ab, damit das Fenster nicht bündig an
# den Kanten klebt. 800 Pixel sind die Obergrenze fuer den Normalfall; auf einem hohen
# Bildschirm darf das Fenster darueber hinaus wachsen, aber nie ueber die Arbeitsflaeche.
$workArea = [System.Windows.SystemParameters]::WorkArea
$reserve  = 56
$window.MaxHeight = [math]::Max(440, [math]::Floor($workArea.Height - $reserve))
$window.Height    = [math]::Min($window.MaxHeight, 800)

# Erst nach dem ersten Zeichnen steht fest, wie hoch der Inhalt tatsaechlich ist. Passt er
# ohne Rollbalken und laesst der Bildschirm es zu, waechst das Fenster darauf.
# Update-View fragt Aufgabenplaner, VSS und Registry ab; zusammen sind das je nach
# Rechner ein bis zwei Sekunden, in denen frueher nichts zu sehen war - man haelt das
# fuer "es passiert nichts". Deshalb laeuft die Abfrage erst, nachdem das Fenster
# gezeichnet wurde: Es steht sofort da, mit Platzhaltern, und fuellt sich gleich darauf.
$script:FirstFill = $false
$window.Add_ContentRendered({
    if (-not $script:FirstFill) {
        $script:FirstFill = $true
        try { Update-View } catch { Write-Log "$(T 'logError'): $($_.Exception.Message)" }
        try { $window.UpdateLayout() } catch { }
    }
    try {
        $sv     = $window.Content
        $panel  = $sv.Content
        $chrome = $window.ActualHeight - $sv.ActualHeight
        $need   = [math]::Ceiling($panel.ActualHeight + $chrome + 2)
        $target = [math]::Min($window.MaxHeight, $need)
        if ($target -gt $window.ActualHeight) { $window.Height = $target }

        # Neu mittig setzen: CenterScreen zentriert auf dem Bildschirm, nicht auf der
        # Arbeitsflaeche, und die Hoehe hat sich seitdem geaendert.
        $wa = [System.Windows.SystemParameters]::WorkArea
        $window.Top  = $wa.Top  + [math]::Max(0, ($wa.Height - $window.ActualHeight) / 2)
        $window.Left = $wa.Left + [math]::Max(0, ($wa.Width  - $window.ActualWidth)  / 2)
    } catch { }
})

# --------------------------------------------------------------- Command line --
# Bewusst englisch, egal welche Anzeigesprache eingestellt ist: Diese Ausgabe wird von
# Skripten gelesen und in Fehlerberichte kopiert, da ist eine stabile Sprache mehr wert
# als eine hoefliche. Rueckgabewerte: 0 in Ordnung, 1 Eingabefehler.
# "snapshot" und "autostart" brauchen kein Fenster. Der Zweig sitzt vor dem von
# "apply", damit beide dieselbe Vorpruefung teilen.
# "idle" liest nur und braucht deshalb keine Rechte. Rueckgabewert 2 heisst "Leerlauf
# systemweit blockiert" und laesst sich damit in einer Ueberwachung auswerten.
if ($Idle) {
    $script:Headless = $true
    try {
        $i = Get-ScheduledTaskInfo -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($i) {
            Write-Host "PITRTask: last run $($i.LastRunTime), next $($i.NextRunTime), missed $($i.NumberOfMissedRuns)"
        }
        $h = Get-IdleHealth
        Write-Host "booted: $($h.Boot)"
        Write-Host "other idle-bound tasks: $($h.Since) of $($h.Total) have run since boot"
        if ($h.Newest) { Write-Host "  most recent idle run: $($h.Newest)" }
        $full = Test-Admin
        if (-not $full) {
            Write-Host '  note: not elevated - only the tasks visible to this account were counted.'
        }
        if ($h.Blocked) {
            Write-Host 'RESULT - blocked: Windows has not reported an idle state since boot.'
            Write-Host '  Nothing that waits for idle runs while this lasts, snapshots included.'
            Write-Host '  Run "powercfg /requests" in an elevated prompt to see what holds the system awake.'
            if (-not $full) {
                Write-Host '  WARNING - this verdict was drawn from a partial list. Repeat it from an'
                Write-Host '  elevated prompt before acting on it.'
            }
            exit 2
        }
        if ($h.Since -eq 0) {
            Write-Host ('RESULT - too early: up for {0:N1} hours only, no verdict yet.' -f $h.UpHours)
            exit 0
        }
        Write-Host 'RESULT - idle detection works.'
        exit 0
    } catch {
        Write-Host "pitr-config: $($_.Exception.Message)"
        exit 1
    }
}

if ($Snapshot -or $AutoStart) {
    $script:Headless = $true

    if ($Snapshot) {
        try {
            Invoke-TaskNow
            exit 0
        } catch {
            Write-Host "pitr-config: $($_.Exception.Message)"
            exit 1
        }
    }

    $words = @($Options -split '\s+' | Where-Object { $_ -ne '' })
    if ($words.Count -gt 0 -and $words[0] -ieq 'autostart') { $words = @($words[1..($words.Count - 1)]) }

    $mode = if ($words.Count -gt 0) { $words[0].ToLower() } else { 'status' }
    $delay = 5
    foreach ($w in $words) {
        if ($w -match '^delay=(\d+)m?$') { $delay = [int]$Matches[1] }
    }

    switch ($mode) {
        'on' {
            if ($delay -lt 1 -or $delay -gt 60) {
                Write-Host 'pitr-config: delay must be between 1 and 60 minutes'
                exit 1
            }
            # "copy" nimmt dem Skriptbetrieb die Rueckfrage ab, die das Fenster stellt.
            $path = $env:PITR_SELF
            if (-not (Test-SelfPathLocal)) {
                if ($words -contains 'copy') {
                    $path = Copy-SelfLocal
                    Write-Host "copied to $path"
                } else {
                    Write-Host 'pitr-config: WARNING - this file is not on a fixed local drive.'
                    Write-Host '  The task runs as SYSTEM, which reaches the network as the computer'
                    Write-Host '  account, so a share that opens for you may still be out of reach.'
                    Write-Host '  Add "copy" to place a copy in ProgramData and use that instead.'
                }
            }
            try {
                Set-AutoStart -DelayMinutes $delay -SelfPath $path
                Write-Host "startup snapshot registered, $delay minutes after boot"
                exit 0
            } catch {
                Write-Host "pitr-config: $($_.Exception.Message)"
                exit 1
            }
        }
        'off' {
            if (Remove-AutoStart) { Write-Host 'startup snapshot removed' }
            else { Write-Host 'startup snapshot was not registered' }
            exit 0
        }
        default {
            $a = Get-AutoStart
            if ($null -eq $a) { Write-Host 'startup snapshot: off'; exit 0 }
            Write-Host "startup snapshot: on, $($a.Delay) minutes after boot"
            $s = Get-AutoStartState
            if ($null -ne $s) {
                Write-Host "  runs: $($s.Path)"
                if ($s.Gone) { Write-Host '  WARNING - that file is gone; run "autostart on copy" again' }
                elseif ($s.Stale) { Write-Host "  WARNING - that copy is version $($s.Version), this one is $Version" }
            }
            exit 0
        }
    }
}

if ($Apply) {
    $spec = @{
        freq   = @{ Name = 'SnapshotInterval'; Min = 60;   Max = 1440;  Unit = 'min' }
        reten  = @{ Name = 'MaxTimespan';      Min = 1440; Max = 10080; Unit = 'min' }
        size   = @{ Name = 'MaxGlobalSize';    Min = 2048; Max = 51200; Unit = 'mb'  }
        active = @{ Name = 'Active';           Min = 0;    Max = 1;     Unit = 'flag' }
    }

    function Convert-Amount {
        param([string]$Key, [string]$Raw)
        $u = $spec[$Key].Unit
        if ($u -eq 'flag') {
            switch ($Raw) {
                'on'  { return 1 }
                '1'   { return 1 }
                'off' { return 0 }
                '0'   { return 0 }
            }
            return $null
        }
        if ($Raw -notmatch '^(\d+)([a-z]*)$') { return $null }
        $n = [int]$Matches[1]
        $s = $Matches[2]
        if ($u -eq 'min') {
            switch ($s) {
                ''  { return $n }
                'm' { return $n }
                'h' { return $n * 60 }
                'd' { return $n * 1440 }
            }
            return $null
        }
        switch ($s) {
            ''   { return $n }
            'm'  { return $n }
            'mb' { return $n }
            'g'  { return $n * 1024 }
            'gb' { return $n * 1024 }
        }
        return $null
    }

    $usage = @(
        "pitr-config $Version",
        '',
        'Usage: pitr-config.cmd apply [freq=<n>h] [reten=<n>d] [size=<n>g] [active=on|off]',
        '                            [reset] [status]',
        '',
        '  freq    60m to 24h    interval between restore points',
        '  reten   1d to 7d      lifetime of a restore point',
        '  size    2g to 50g     storage limit for all points together',
        '  active  on | off      the feature itself',
        '  reset                 removes every value this tool has written',
        '  status                prints the values in effect and writes nothing',
        '',
        'Startup snapshot: pitr-config.cmd autostart on [delay=<n>m] [copy] | off | status',
        '  copy    put a copy in ProgramData first - a task runs as SYSTEM and may not',
        '          reach the network share this file sits on',
        '',
        '  Any setting also takes "default", which removes that single override.',
        '  Values are written at policy level and outrank the Settings app.',
        '  Requires an elevated prompt; exit code 5 says it was not.'
    ) -join [Environment]::NewLine

    # Der erste Wortteil ist "apply" selbst, der faellt weg.
    $words = @($Options -split '\s+' | Where-Object { $_ -ne '' })
    if ($words.Count -gt 0 -and $words[0] -ieq 'apply') { $words = @($words[1..($words.Count - 1)]) }

    if ($words.Count -eq 0 -or $words[0] -in @('/?', '-?', 'help', '--help')) {
        Write-Host $usage
        exit 1
    }

    $wanted = @{}
    $doReset  = $false
    $doStatus = $false
    foreach ($w in $words) {
        if ($w -ieq 'reset')  { $doReset  = $true; continue }
        if ($w -ieq 'status') { $doStatus = $true; continue }
        $kv = $w -split '=', 2
        if ($kv.Count -ne 2 -or -not $spec.ContainsKey($kv[0].ToLower())) {
            Write-Host "pitr-config: cannot read '$w'"
            Write-Host ''
            Write-Host $usage
            exit 1
        }
        $key = $kv[0].ToLower()
        $raw = $kv[1].ToLower()
        if ($raw -eq 'default') { $wanted[$key] = $null; continue }
        $val = Convert-Amount $key $raw
        if ($null -eq $val) {
            Write-Host "pitr-config: cannot read the value in '$w'"
            exit 1
        }
        if ($val -lt $spec[$key].Min -or $val -gt $spec[$key].Max) {
            Write-Host ("pitr-config: {0}={1} is outside the allowed range ({2} to {3} {4})" -f
                        $key, $raw, $spec[$key].Min, $spec[$key].Max, $spec[$key].Unit)
            exit 1
        }
        $wanted[$key] = $val
    }

    if ($doStatus) {
        Write-Host "pitr-config $Version"
        foreach ($k in @('active', 'freq', 'reten', 'size')) {
            $cur = Get-PitrValue $spec[$k].Name
            if ($null -eq $cur) { Write-Host ("  {0,-7} Windows default" -f $k) }
            # Die rohe Stufe und nicht das uebersetzte Etikett: Diese Zeile wird von
            # Skripten gelesen, da waere eine mitwandernde Sprache nur im Weg.
            else { Write-Host ("  {0,-7} {1} ({2})" -f $k, $cur.Value, $cur.Level) }
        }
        exit 0
    }

    if ($doReset) {
        $n = 0
        foreach ($name in 'Active', 'SnapshotInterval', 'MaxTimespan', 'MaxGlobalSize', 'MaxCount') {
            if (Remove-PitrValue $name) { Write-Host "removed ${name}_$Level"; $n++ }
        }
        if ($n -eq 0) { Write-Host 'nothing was set' }
    }

    foreach ($k in @('active', 'freq', 'reten', 'size')) {
        if (-not $wanted.ContainsKey($k)) { continue }
        $name = $spec[$k].Name
        if ($null -eq $wanted[$k]) {
            if (Remove-PitrValue $name) { Write-Host "removed ${name}_$Level" }
            else { Write-Host "${name}_$Level was not set" }
        } else {
            Set-PitrValue $name $wanted[$k]
            Write-Host "${name}_$Level = $($wanted[$k])"
        }
    }
    Write-Host 'Takes effect on the next PITRTask run (it only runs when the system is idle).'
    exit 0
}

if ($SelfTest) {
    foreach ($l in $LangCodes) {
        $script:Lang = $l
        Apply-Language
        Update-View
        Write-Host "===== Sprache: $l ====="
        Write-Host "  Titel        : $($window.Title)"
        Write-Host "  Untertitel   : $($ctl.TxtSub.Text)"
        Write-Host "  Hoehe/Max    : $($window.Height) / $($window.MaxHeight)  (Arbeitsflaeche $([int]([System.Windows.SystemParameters]::WorkArea.Height)))"
        $lb = foreach ($c in $LangCodes) {
            $n = 'BtnLang' + $c.ToUpper()
            if ($ctl[$n].FontWeight -eq [System.Windows.FontWeights]::Bold) { "[$($ctl[$n].Content)]" }
            else { [string]$ctl[$n].Content }
        }
        Write-Host "  Sprachknoepfe: $($lb -join ' ')"
        Write-Host "  Anleitung    : $($ctl.RunGuide.Text) -> $(Get-GuideUri)"
        Write-Host "  Update-Text  : $((T 'updAvail') -f '9.9.9')"
        Write-Host "  Hinweisbox   : $($ctl.TxtUnofficial.Text)"
        Write-Host "  Leerlauf-Box : $($ctl.TxtIdleNote.Text)"
        Write-Host "  Laufwerk-Box : $($ctl.TxtVolumeNote.Text)"
        Write-Host "  Aufgabe      : $($ctl.CapTaskState.Text) $($ctl.TxtTaskState.Text)"
        Write-Host "  Naechster    : $($ctl.TxtNext.Text)"
        Write-Host "  Gruppen      : $($ctl.GrpState.Header) | $($ctl.GrpPoints.Header) | $($ctl.GrpSet.Header) | $($ctl.GrpLog.Header)"
        Write-Host "  Spalten      : $(($ctl.LstPoints.View.Columns | ForEach-Object { $_.Header }) -join ' | ')"
        Write-Host "  Schnappschuss: $($ctl.BtnSnapNow.Content) - $($ctl.TxtSnapHint.Text)"
        Write-Host "  Beim Start   : [$(if ($ctl.ChkAuto.IsChecked) { 'x' } else { ' ' })] $($ctl.ChkAuto.Content) ($(($ctl.CmbAutoDelay.Items | ForEach-Object { $_.Content }) -join ' | '))"
        Write-Host "  Start-Hinweis: $($ctl.TxtAutoHint.Text)"
        Write-Host "  Veraltet-Text: $((T 'staleOld') -f '1.5.0', 'C:\ProgramData\pitr-config\pitr-config.cmd', $Version)"
        Write-Host "  Gleiche Vers.: $((T 'staleSame') -f $Version, 'C:\ProgramData\pitr-config\pitr-config.cmd')"
        Write-Host "  Leerlauf-Frage: $((T 'idleBanner') -f 5) [$($ctl.BtnIdleChk.Content)]"
        Write-Host "  Leerlauf-Stopp: $((T 'idleBlocked') -f '29.08.2026 09:25', 33)"
        Write-Host "  Leerlauf-Gut : $((T 'idleFine') -f 6, 33, '29.08.2026 18:06')"
        Write-Host "  Leerlauf-Frueh: $((T 'idleEarly') -f 33, '25 min')"
        Write-Host "  Leerlauf-Teil : $(T 'idlePartial')"
        Write-Host "  WinRE        : $($ctl.CapWinRE.Text) $($ctl.TxtWinRE.Text) [$($ctl.BtnWinRE.Content)]"
        Write-Host "  WinRE-Warnung: $($ctl.TxtWinReNote.Text)"
        Write-Host "  Kopierknopf  : $($ctl.BtnCopy.Content) - $($ctl.TxtCopyHint.Text)"
        Write-Host "  Knoepfe      : $($ctl.BtnReset.Content) | $($ctl.BtnRefresh.Content) | $($ctl.BtnApply.Content) | $($ctl.BtnApplyNow.Content)"
        Write-Host "  $($ctl.TxtPoints.Text)"
        Write-Host "  $($ctl.TxtOldest.Text)"
        Write-Host "  $($ctl.TxtStorage.Text)"
        Write-Host "  $($ctl.LblFreq.Text)"
        Write-Host "  $($ctl.LblReten.Text)"
        Write-Host "  Haeufigkeit  : $(($ctl.CmbFreq.Items  | ForEach-Object { $_.Content }) -join ' | ')"
        Write-Host "  Aufbewahrung : $(($ctl.CmbReten.Items | ForEach-Object { $_.Content }) -join ' | ')"
        Write-Host "  Auswahl haelt: Freq=$([string]$ctl.CmbFreq.SelectedItem.Tag) Reten=$([string]$ctl.CmbReten.SelectedItem.Tag) Size=$([string]$ctl.CmbSize.SelectedItem.Tag)"
        Write-Host ""
    }
    Write-Host "Erkannte Systemsprache: $((Get-UICulture).Name)"
    Write-Host "Administrator         : $(Test-Admin)"
    Write-Host "Version               : $Version"
    return
}

if (-not (Test-Admin)) { Write-Log (T 'logNoAdmin') }
Write-Log (T 'logReady')

# Polled from the UI thread instead of using a completion callback, because a callback
# fires on the worker thread and may not touch WPF controls from there.
$script:UpdateJob = Start-UpdateCheck
if ($script:UpdateJob) {
    $script:UpdateTries = 0
    $script:UpdateTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:UpdateTimer.Interval = [TimeSpan]::FromMilliseconds(400)
    $script:UpdateTimer.Add_Tick({
        $script:UpdateTries++
        $j = $script:UpdateJob
        if ($j.Handle.IsCompleted) {
            $script:UpdateTimer.Stop()
            try { Show-UpdateNotice (@($j.Shell.EndInvoke($j.Handle)))[0] } catch { }
            try { $j.Shell.Dispose() } catch { }
        } elseif ($script:UpdateTries -ge 20) {
            # Roughly eight seconds - after that nobody is waiting for the answer any more.
            $script:UpdateTimer.Stop()
            try { $j.Shell.Stop(); $j.Shell.Dispose() } catch { }
        }
    })
    $script:UpdateTimer.Start()
}

$window.ShowDialog() | Out-Null
