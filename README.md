# windows-pitr-config

[![Download pitr-config.cmd](https://img.shields.io/badge/download-pitr--config.cmd-2ea44f?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/henmedia/windows-pitr-config/releases/latest/download/pitr-config.cmd)
[![Latest release](https://img.shields.io/github/v/release/henmedia/windows-pitr-config?style=for-the-badge&label=version&color=555555)](https://github.com/henmedia/windows-pitr-config/releases/latest)
[![Guide](https://img.shields.io/badge/guide-EN%20DE%20NL%20FR%20ES%20PT%20IT%20PL%20UK%20CS-1f6feb?style=for-the-badge)](https://henmedia.github.io/windows-pitr-config/guide.html)

Configure **Point-in-time restore** (PITR) on Windows 11 — including the frequency and
retention settings that Microsoft exposes on the Enterprise edition only.

A single, self-contained `.cmd` file with a graphical interface. No installation, no
dependencies, no PowerShell modules. Copy it to a USB stick and run it anywhere.

> ### 📸 A restore point on demand
>
> Beyond the schedule, the tool creates a **restore point at any moment**. The green
> **Create snapshot now** button sits at the top of the window and needs nothing else — no
> setting is changed, no value written. One click before a driver installation, a registry
> edit, or the first run of unfamiliar software.
>
> This works even while the machine is in use, which a manual start of the task does not:
> `PITRTask` runs only when the system is idle, so the button lifts that condition for
> exactly one run and restores it afterwards.

> ### 🔄 And the way back
>
> A restore point is applied from the Windows Recovery Environment, not from inside a running
> Windows. **Restart to recovery** reboots straight into it — from the same window that created
> the point. Windows does offer that route, under Settings → System → Recovery → Advanced
> startup, but several clicks away from anything to do with restore points.
>
> The line next to the button shows whether that environment exists at all, along with the size
> and free space of the recovery partition. If it is switched off, no restore point can be
> applied by anyone, and the tool says so in red instead of leaving it to be discovered on the
> day it matters.

> ### 📁 Or just one file, not the whole system
>
> Restore points aren’t only for rolling the whole drive back. Right-click any file or
> folder, open **Properties**, and the **Previous Versions** tab lists every restore point that
> captured it — **Open** shows the old content without touching anything, **Restore** brings
> back only that one item. No recovery environment, no restart: this runs from inside a working
> Windows, reading the same shadow copies the tool already creates.
>
> Windows has offered this for years, on every edition; what changes with more frequent restore
> points is how far back the list reaches.

> ### 🔍 And when no point appears at all
>
> A run that falls due while the machine is in use is dropped silently — Windows writes
> nothing to any log, which is why a schedule that has quietly stopped working looks exactly
> like one that is merely waiting. **Check idle** tells the two apart: it reads every other
> scheduled task on the machine that waits for idle and compares them with the last boot. Has
> none of them run in hours, the idle state is blocked system-wide and the missing restore
> points are a symptom rather than the fault — `powercfg /requests` then names what holds the
> system awake. Also available as `pitr-config.cmd idle`, which runs without administrator
> rights — elevated it simply sees more of the scheduled tasks, and says so when it does not.

The interface speaks **English, German, Dutch, French, Spanish, Portuguese, Italian, Polish,
Ukrainian and Czech**. It starts in whichever one matches your Windows display language; the buttons in the top right
switch at any time. The window also links to the project and to the
[short guide](https://henmedia.github.io/windows-pitr-config/guide.html), which opens in the
language you are currently using.

![The tool running on Windows 11 Pro: current state, existing restore points, and the four
settings](docs/screenshot.png?v=1.8.1)
<!-- The ?v= is a cache buster. GitHub proxies README images and caches them by URL,
     so replacing the file alone keeps serving the old picture for a long time.
     Bump this whenever the screenshot is regenerated. -->

> **This is an unofficial approach.** The configuration values it writes are undocumented by
> Microsoft; they were recovered by analysing the Windows binaries. A future Windows release
> may change them, at which point the Windows default behaviour simply applies again. The
> tool states this in its own interface as well, and *Reset everything* undoes all of it.

---

## The problem

Point-in-time restore is the newer full-system rollback feature in Windows 11. It captures
complete system snapshots through the Volume Shadow Copy Service and lets you roll the
machine back from the Windows Recovery Environment.

Under **Settings → System → Recovery → Point-in-time restore**, Windows offers only two
controls on Home and Pro: on/off and the storage limit. According to
[Microsoft's own documentation](https://learn.microsoft.com/en-us/windows/configuration/point-in-time-restore),
**restore point frequency and retention are configurable on the Enterprise edition only** —
everywhere else those dropdowns are greyed out.

## What this tool does

It turns out the edition gate lives in the Settings user interface, not in the engine. The
PITR engine reads its configuration from a single registry key, and it does not check the
Windows edition when doing so.

This tool writes that configuration directly, which makes frequency and retention available
on any edition.

| Setting | Range offered here | Microsoft's documented range |
|---|---|---|
| Feature on/off | on / off | on / off (all editions) |
| Frequency | 1, 2, 4, 6, 8, 12, 16, 24 hours | 4, 6, 12, 16, 24 hours (Enterprise only) |
| Retention | 1–7 days (values above 72 h verified in practice) | up to 72 hours (Enterprise only) |
| Maximum storage | 2–50 GB | 2–50 GB (all editions) |

Every setting also offers **"Windows default"**, which removes the override again.

> **Frequency is an earliest possible interval, not a guarantee.** Restore points are only
> created while the system is idle: `PITRTask` runs with `RunOnlyIfIdle = True`. If the
> machine is in use — or switched off — the run is postponed, and a scheduled slot can be
> skipped entirely. Setting one hour on a machine that is used all day and shut down at
> night will not produce twenty-four points.
>
> The tool makes this visible rather than leaving you guessing: it shows the task status
> (*waiting for the system to go idle* when a run is pending) and marks an overdue next run.
> **Create snapshot now**, at the top of the window, forces a point immediately whenever
> one is wanted.

## Scope: the OS volume only

Point-in-time restore covers the Windows volume — `C:` on a normal installation — and
nothing else. Other partitions and other disks are not included, **not even when they sit on
the same physical disk**.

That is not a setting anywhere; it is how the engine is built — see
[Evidence](#evidence).

Two consequences worth knowing:

- Data on other volumes is **not protected**. No restore point will bring it back after a
  deletion or an encryption attack — those volumes still need a backup of their own.
- Data on other volumes is also **not rolled back**. Rolling the system back to yesterday
  leaves today's work on `D:` exactly where it is.

The storage limit this tool sets likewise applies to the OS volume alone. The tool states
this in its own interface and labels the storage figures with the drive they refer to.

## Not a backup

Point-in-time restore answers a change that went wrong — a bad update, a driver that broke
something, software that left the machine in a worse state than before. It does not answer
losing the disk.

The restore points live on the very volume they protect, in the shadow storage area of the
Windows drive. A failed drive takes them along, and so does a stolen laptop, a wiped or
re-partitioned volume, or ransomware that gets far enough. There is no copy anywhere else, and
that is by design: this is a rollback mechanism, not a backup mechanism. The two look similar
from a distance and fail in completely different ways.

Treat it as the fast way back from a bad afternoon, and keep a real backup on separate media
for everything else. That includes recovering a single file through Previous Versions: quick
and convenient, but still the same shadow storage on the same drive. The tool says the same
thing in its own window.

## How it works

The engine reads its configuration from:

```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Recovery\PITR\Settings
```

Values follow the scheme `<name>_<level>`, all of type `REG_DWORD`:

| Value name | Unit | Meaning |
|---|---|---|
| `Active` | 0 / 1 | Feature enabled |
| `SnapshotInterval` | minutes | Interval between restore points |
| `MaxTimespan` | minutes | Lifetime of a restore point |
| `MaxGlobalSize` | MB | Ceiling for all restore points combined |
| `MaxCount` | count | Maximum number of restore points |

The level suffix determines precedence: **`GPO` > `CSP` > `UX` > `Default`**, where `UX` is
the Settings app and `CSP` is management through Intune. This tool writes at the `GPO`
level, so its values take precedence over the Settings app.

> **`GPO` here is only a name.** It is a plain registry value with that suffix — the Group
> Policy service is not involved and `gpedit.msc` is never used. Windows Home not shipping a
> Group Policy editor is therefore irrelevant.

These value names are **not documented by Microsoft**. They were recovered from
`C:\Windows\System32\OOBE\PITR.dll` and `RemoteRemediationCSP.dll`.

## Evidence

### The frequency really does change

Restore points are created by the scheduled task `\Microsoft\Windows\Setup\PITRTask`, which
recalculates its next run time on every execution. The gap between last and next run is
therefore a directly measurable indicator of the effective frequency.

Setting `SnapshotInterval_GPO = 240` and running the task once:

| | Before | After |
|---|---|---|
| Interval | 1440 min (24 h) | **240 min (4 h)** |

Task exit code `0`, and an additional restore point was created. Afterwards the Settings app
displayed *"Some of these settings are managed by your organization"* and showed the values
greyed out — on a machine under no management at all.

### Only the OS volume is ever covered

`PITR.dll` carries an explicit rejection for anything else, and a snapshot's registry entry
has no volume field at all, because there is only ever one volume:

```
OS volume      : %s
Snapshot is not on the OS volume
```

Confirmed on a machine whose `C:` and `D:` are two partitions of the same SSD: `C:` holds the
shadow copy and its difference area, while `D:` has no shadow copy and no shadow storage
configured at all.

## Usage

[**Download `pitr-config.cmd`**](https://github.com/henmedia/windows-pitr-config/releases/latest/download/pitr-config.cmd)
— that one file is the whole download, and the link always points at the newest release. The
version shown under the headline in the window tells you which release you are running.

Double-click `pitr-config.cmd`. It requests administrator rights itself (UAC).

Running it straight from a network share works as well. `cmd.exe` used to print a warning of
its own in that case — *UNC paths are not supported*, falling back to `C:\Windows` — which
looks like a failure but is none: the tool works from its own full path and never touches the
current directory. Since 1.4.1 that message is cleared from the console on start.

A [short guide](https://henmedia.github.io/windows-pitr-config/guide.html) covers the same
ground in all ten languages. Downloading `guide.html` next to `pitr-config.cmd` makes the
tool open that local copy instead, which keeps it fully usable on a stick without a network.

Browsers treat `.cmd` files as executable content, so the download may need one confirmation
before it is kept. Every release lists the SHA-256 of its file, which is worth comparing
before running anything that writes to `HKLM`:

```
Get-FileHash pitr-config.cmd -Algorithm SHA256
```

| Button | Effect |
|---|---|
| **Create snapshot now** | Creates a restore point immediately, without changing a single setting. Highlighted at the top of the window. |
| **Apply** | Writes the values. A new frequency takes effect on the next task run. |
| **Apply and run now** | Writes the values and runs the task immediately, so the schedule is recalculated at once. |
| **Refresh** | Re-reads the current state. |
| **Reset everything** | Removes every value this tool has set, after confirmation. |
| **Restart to recovery** | Restarts Windows into the recovery environment, where a restore point can actually be applied. Asks first; unsaved work in other programs is lost. |
| **Copy state** | Puts the whole state into the clipboard as plain text — made for a forum post or a bug report. |

For a read-only look at your system — no window, no administrator rights, nothing written:

```
pitr-config.cmd selftest
```

### Update check

On start the tool asks GitHub whether a newer release exists and, if so, shows a line in the
window with a link to it. It never downloads or installs anything by itself — the link opens
the release page in your browser and you decide from there. That is deliberate: a tool that
writes to `HKLM` has no business replacing its own code over the network, and doing so would
make the published checksums pointless.

The check runs in the background, so the window stays usable, and it fails silently. No
network, a firewall, or GitHub's rate limit simply means no notice appears. To skip it
entirely, start the tool as:

```
pitr-config.cmd noupdate
```

This is the only network connection the tool makes. The request reveals nothing about your
system beyond what any web request does — an IP address and a `pitr-config` user agent.

### Whether this Windows has the feature at all

Point-in-time restore is not on every Windows 11, and a new Windows version is not what
decides it: the feature also reached existing builds through a cumulative update. On the
machine this was built on, the component carries version `10.0.26100.8875` inside a system
reporting build `26200` — two machines on the same build can genuinely differ, so a build
number settles nothing.

The tool therefore asks after the component itself rather than after a number, and puts the
answer on the first line of *Current state*:

```
Point-in-time restore:  supported by this Windows  ·  component 10.0.26100.8875
```

Two things have to be there, and both are read from the system rather than assumed:

- the **COM class** through which the scheduled task calls the snapshot component,
  `{093CB270-C282-4C22-B2EA-7D2BF1C30BBF}`. Its registration also names the file, so that
  path is never guessed; a registration pointing at a file that is gone does not count.
- the scheduled task **`\Microsoft\Windows\Setup\PITRTask`**, which calls it on a schedule.

Neither present means this Windows does not have the feature. A red box says so, and
everything that writes is switched off — those values would sit in the registry with nothing
to read them. Reading, the language buttons and **Copy state** stay available.

Only one of the two present is a different finding and is named differently: the feature is
there but incomplete. The box says which half is missing and points at an elevated
`sfc /scannow`. The controls stay usable in that case on purpose — a misreading must not
disable the tool on a system where the feature works.

### The recovery environment

A restore point is applied from the Windows Recovery Environment, not from inside a running
Windows. If that environment is missing or switched off — which happens more often than one
would think, most visibly during the WinRE servicing failures of early 2024 — then restore
points are collected that nobody can reach when it matters.

The window therefore shows its state in the *Current state* box, together with the size and
free space of the recovery partition:

```
Recovery environment:  available  ·  1151 MB, 106 MB free
```

If it is switched off, the line turns red and a note appears: an elevated `reagentc /enable`
usually puts it back. **Restart to recovery** next to that line reboots straight into the
environment, which is where a point gets applied after something has gone wrong.

The state is read from `%SystemRoot%\System32\Recovery\ReAgent.xml` rather than from the
output of `reagentc /info`, because that output is translated and this tool speaks ten
languages. The partition behind it is found through the disk number and byte offset recorded
in that same file. If any of it fails, the line says *not determinable* — no guess.

### How long a snapshot takes

The log reports the runtime of every snapshot the tool triggers, and the restore point list has
a **Duration** column for all of them — including the runs Windows starts on its own.

That column needs a source, and Windows offers exactly one. The duration of a shadow copy is
recorded nowhere: `Win32_ShadowCopy` knows only a timestamp, and the paired events in
`Microsoft-Windows-VolumeSnapshot-Driver/Operational` describe volumes going online and
offline, not a snapshot being made. What does work is the Task Scheduler history — events 100
and 102 share an instance id, and the difference between them is the runtime of `PITRTask`. A
restore point is matched to the run whose window contains its timestamp; the runs lie hours
apart, so there is nothing to confuse.

Windows keeps that history switched off by default. While it is off the column shows a dash,
and a line under the list offers to enable it:

```
wevtutil sl Microsoft-Windows-TaskScheduler/Operational /e:true
```

The tool never does this on its own, and the button asks first — it is a system-wide setting
that from then on logs every scheduled task on the machine into a 10 MB ring buffer. It also
does not work backwards: points that already exist keep no duration, however long they took.

### A point at every system start

The checkbox under the green button, **At every system start**, has the tool create a restore
point a few minutes after every boot.

Windows already wants one. `PITRTask` carries a boot trigger of its own, with a thirty minute
delay:

```
Trigger:  MSFT_TaskBootTrigger   Delay = PT30M
          MSFT_TaskTimeTrigger   Repetition = PT1H
```

That trigger rarely produces anything, because the task also has `RunOnlyIfIdle = True` and a
machine half an hour into its day is usually in use. The run is then discarded rather than held
back: it counts as a skipped run and leaves no entry in the Task Scheduler history at all.

The checkbox does not add a second trigger and does not touch the Windows task. It registers a
small task of its own, `\pitr-config\Startup snapshot`, which after the chosen delay does
exactly what the button does: lift the idle condition for one run, start the task, put the
condition back. Permanently disabling `RunOnlyIfIdle` would be the lazier route and a worse
one — shadow copies would then start in the middle of someone's work, and the next feature
update resets the value anyway.

**Why a delay at all.** A machine that has just booted is busy with services, drivers, the
antivirus and often Windows Update. A shadow copy competes with all of it, and the VSS writers
are not necessarily responsive yet. Microsoft's own answer to this is thirty minutes; the tool
offers 1 to 30 and defaults to five, which is late enough to be out of the boot storm and early
enough to still mean "shortly after the start".

**At startup, not at logon.** The task runs as `SYSTEM` with a boot trigger, so it fires
without anyone signing in — on a machine that boots to the lock screen and stays there, the
point is still created.

> **One caveat worth knowing: Fast Startup.** With Fast Startup enabled — the Windows default
> on most machines — shutting down and switching on again is a resume from hibernation, not a
> boot, and boot triggers do not fire. A *restart* is a real boot and does trigger it. If the
> point matters to you on every power-on, either turn Fast Startup off, or rely on the hourly
> schedule instead. The tool cannot work around this; nothing can, short of changing how the
> machine shuts down.

From the command line:

```
pitr-config.cmd autostart on delay=5m
pitr-config.cmd autostart off
pitr-config.cmd autostart status
```

And the same thing once, without the task:

```
pitr-config.cmd snapshot
```

Both need an elevated prompt, like `apply`. **It cannot work from a network share**, and the reason is worth knowing: the task runs as
`SYSTEM`, and `SYSTEM` reaches the network as the *computer account*, not as the person signed
in. A share that opens without a murmur in Explorer is therefore usually out of reach for the
task. Switching the checkbox on from such a path offers to copy the file to
`%ProgramData%\pitr-config\` and to register the task against that copy; on the command line,
add `copy` to do the same. To tell this apart from a boot-timing problem, run the task by hand
while signed in — if it fails then too, it is access and not timing.

That copy then has a life of its own: the task keeps the path it was given, so a newer version
started from the share leaves the old copy running at every boot, quietly. The window compares
the two whenever it refreshes and says so, with a button that refreshes the copy and keeps the
delay. The version is read out of the file; if two files carry the same version but differ,
the checksums settle it. On the command line, `autostart status` prints the path the task uses
and warns when it is behind.

### How the snapshot on demand works

`PITRTask` has `RunOnlyIfIdle = True`. While the machine is actively in use the task stays in
the *Queued* state, and a manual start — from the Task Scheduler, or via `Start-ScheduledTask`
— appears to do nothing at all. That is the reason a snapshot on demand needs a tool rather
than a one-line command.

**Create snapshot now** lifts the idle condition for exactly one run and restores it
afterwards, including when an error occurs in between. It writes nothing else: the settings in
the window are left where they are. **Apply and run now**, at the bottom, does the same thing
but saves the settings first — the right button when a new frequency should take effect at
once instead of at the next scheduled run.

### When no restore point appears at all

Every restore point waits on one condition: the system has to be idle. `PITRTask` carries
`RunOnlyIfIdle`, and a run that falls due while the machine is in use is not deferred — it is
discarded there and then. Nothing is written to any log when that happens. The only trace is a
counter, `NumberOfMissedRuns`, which the window shows beside the task status as *runs skipped*.

That it is really discarded rather than held is measurable. With the idle wait left at its
default of thirty minutes, the counter had already risen seven minutes after the trigger — long
before that window could expire — and the task had still not run, although the machine had gone
idle two minutes after the trigger and stayed that way. The Task Scheduler history stayed empty
throughout. That silence is the reason a schedule which has quietly stopped working leaves
nothing behind to find, and it is what the check below is for.

A manual start behaves differently: an explicit `Start-ScheduledTask` on a task waiting for idle
does land in the *Queued* state, which is why **Create snapshot now** lifts the condition for
one run instead of merely starting the task.

Skipped runs on their own mean nothing — they are the normal case while somebody is working.
They turn into a symptom only when Windows stops reporting an idle state altogether, because a
program or a driver holds a power request, say. From then on nothing that waits for idle runs
at all; the restore points are merely the part somebody notices.

The window tells those two apart. Once runs have been skipped, a box appears with a **Check
idle** button. It reads every other task on this machine that carries `RunOnlyIfIdle` — disk
cleanup, storage sense, memory diagnostics and two dozen more — and compares their last run
with the last boot:

- **at least one of them has run** — idle detection works, the machine was simply in use when
  the run fell due;
- **not one of them has run**, and the system has been up for more than two hours — the idle
  state is blocked system-wide, and the missing restore points are a symptom, not the fault.

The tool's own task stays out of that count on purpose: the green button can force it, and a
forced run would carry a fresh timestamp that reverses the whole verdict.

What holds a system awake is named by

```
powercfg /requests
```

in an elevated prompt. A stuck lock screen process, a media player, an open audio stream, a
background app that never lets go — those are the usual candidates. Ending the process that
holds the request releases it, and so does a restart.

The same check runs without a window, and it only reads, so administrator rights are not
required:

```
pitr-config.cmd idle
```

It returns **2** when the idle state is blocked and **0** otherwise, which makes it usable from
a monitoring script.

Rights do change the answer, though. An unelevated prompt sees only the scheduled tasks visible
to that account — on the machine this was written on, 22 of 33. A positive verdict survives
that: if something has run, idle detection works, whoever is counting. A verdict of *blocked*
does not, because the tasks that did run may be among the ones that were not visible. Both the
command and the window therefore state when they counted without rights, and the command adds a
warning before returning 2.

### Command line

For startup scripts, remote administration, or setting up several machines the same way, the
tool also writes without opening a window:

```
pitr-config.cmd apply freq=4h reten=5d size=20g active=on
```

| Word | Range | Meaning |
|---|---|---|
| `freq` | `60m` to `24h` | interval between restore points |
| `reten` | `1d` to `7d` | lifetime of a restore point |
| `size` | `2g` to `50g` | storage limit for all points together |
| `active` | `on` / `off` | the feature itself |
| `reset` | — | removes every value this tool has written |
| `status` | — | prints the values in effect and writes nothing |

Every setting also accepts `default`, which removes that single override again. Hours, minutes
and days can be written as `90m`, `4h` or `2d`; the size takes `20g` or a plain number of
megabytes.

Three further words do not write any setting and have a shape of their own:

```
pitr-config.cmd snapshot
pitr-config.cmd autostart on delay=5m
pitr-config.cmd idle
```

`snapshot` creates a restore point straight away and `autostart` also takes `off` and `status`;
both need the same elevated prompt as `apply`. `idle` is the exception — it only reads, runs
without administrator rights, and returns **2** instead of **0** when the idle state is blocked
system-wide. Unelevated it counts fewer scheduled tasks and says so.

It needs an elevated prompt and deliberately does **not** elevate itself: elevation would
start a new process with its own console, and neither its output nor its exit code would reach
the calling script. Without administrator rights it says so and returns **5**. A wrong or
unreadable argument returns **1** and prints the usage; success returns **0**.

Started from a network share, `cmd.exe` prints its UNC warning ahead of the tool, the one the
window mode clears away. The command line deliberately leaves it: clearing the console there
would wipe the calling script's own output. It goes to stderr, so `2>nul` in a batch file or
`2>$null` in PowerShell silences it.

The output of this mode is always English, whatever the display language is. It gets read by
scripts and pasted into bug reports, and there a stable wording is worth more than a polite
one. `status` prints the raw level — `GPO`, `CSP`, `UX` — for the same reason.

## Requirements

- Windows 11 with Point-in-time restore present (Settings → System → Recovery). The tool
  checks this itself and says plainly when the feature is missing — see
  [below](#whether-this-windows-has-the-feature-at-all).
  Home and Pro are both confirmed working; Enterprise offers these settings natively anyway.
- Administrator rights (the tool requests them itself)
- Windows PowerShell 5.1, which ships with Windows

## Risks and reversal

- The value names are undocumented. A larger Windows update may change the scheme; the
  Windows default behaviour then simply applies again.
- A short frequency produces more shadow copies. VSS storage is shared with other tools —
  keep an eye on the storage limit if you also run something like Macrium Reflect.
- Nothing here is permanent. *Reset everything* removes the values, or delete every value
  with the `_GPO` suffix from the registry key above by hand.
- The tool never deletes restore points. It only changes configuration.

## About restore point storage

The tool shows three figures, all for the OS volume:

- **In use** — data actually written by the shadow copies.
- **Reserved** — space VSS has already claimed on disk. It is unavailable to other files but
  not yet fully filled; VSS grabs it ahead of time so writes never stall.
- **Limit** — the configured ceiling.

Windows reports these per volume only. There is deliberately **no per-point size**: all
restore points share one common difference area, so an individual size would not be a
meaningful figure.

## Editing the file

The tool is a hybrid file: a short batch section on top, and the complete PowerShell code
with the WPF interface below the `#___PSCODE___` marker. The batch part secures
administrator rights, reads its own file through `%~f0` (so renaming it is harmless), and
executes the lower part as a script block.

> **Keep the encoding.** The file must stay **UTF-8 without BOM** with CRLF line endings — a
> BOM makes `cmd.exe` trip over the first line. Non-ASCII characters survive regardless,
> because the loader reads the file as UTF-8 explicitly rather than relying on the console
> code page.

## Translations

The interface speaks ten languages, and corrections are more welcome than new ones. German
is the only one a native speaker has gone through line by line. The other nine were not, so a
clumsy phrase, or a term no Windows user in that language would recognise, is entirely
possible. A pull request fixing a single line is worth as much here as a whole new
language.

Everything lives in one table near the top of the PowerShell part, one block per language:

```powershell
$LangText = @{
    en = @{ btnApply = 'Apply' ... }
    de = @{ btnApply = 'Übernehmen' ... }
}
$LangCodes = @('en', 'de', 'nl', 'fr', 'es', 'pt', 'it', 'pl', 'uk', 'cs')
```

A new language needs four things: a block copied from `en` and translated, its code appended
to `$LangCodes`, a button in the XAML next to the others, and one line wiring that button to
`Set-Lang`. Missing keys fall back to English, so an unfinished block degrades to a mixed
window rather than to empty labels — a partial translation is a perfectly good pull request.

Four things are worth knowing before starting:

- **Apostrophes are doubled and plain ASCII**: `l''edizione`, not `l'edizione` and never the
  typographic `’`. Windows PowerShell 5.1 treats the curly quote as a string delimiter just
  like the straight one, so a single one silently ends the string and the file stops parsing.
  Accented letters and diacritics are fine as they are — the loader reads the file as UTF-8.
- **Terminology should follow the Windows interface of that language**, not the dictionary.
  Where someone recognises the term from their own Windows, a clumsy sentence is forgiven; the
  other way round it is not.
- **The text addresses nobody.** No *du/Sie*, no *tu/vous*, no *tú/usted*. In the Romance
  languages the imperative carries that distinction too, so instructions are phrased as nouns
  — *Doppio clic su…* rather than *fare clic*.
- **Plural forms vary.** Polish hours are abbreviated to `godz.` because the full word changes
  with the number (2 godziny, 5 godzin) and the window shows both cases. Any language with the
  same problem can do the same.

`pitr-config.cmd selftest` walks through every language and prints the interface of each one
to the console — headline, notices, buttons, group headers and the filled dropdown lists —
without opening a window, writing anything, or needing administrator rights. That is the
fastest way to read a translation in context, and it catches a broken quote immediately,
because the file then does not parse at all.

The same applies to [docs/guide.html](docs/guide.html), which carries one `<section>` per
language plus its button and an entry in the `CODES` array of the small script at the bottom.

## Versioning

Releases follow `MAJOR.MINOR.PATCH` and are tagged `vX.Y.Z`. The running version is shown in
the window below the headline and printed by `pitr-config.cmd selftest`, so a bug report can
always name the exact build. What changed between releases is in [CHANGELOG.md](CHANGELOG.md).

The minor version tracks what the tool can newly **do** on a system where it already worked.
Two kinds of release stay on the patch tier even though something in the window visibly
changed:

- **Only a language added**, with no other change to the interface or its behaviour. The set of
  available languages is not a feature in the sense the minor version tracks; it is content,
  and treating it as such keeps a translation-only release from reading as bigger than it is.
- **A state the tool previously handled badly, now named.** 1.8.1 is the example: on a Windows
  without point-in-time restore the window used to fill with blank fields and no explanation.
  New wording, a new line and a new box — but nothing a working system can do afterwards that
  it could not do before. That is a repair, not a feature.

Everything that widens what the tool can do gets a minor version.

## Support

The tool is free and stays that way. If it saved an afternoon of reinstalling Windows, a
coffee is welcome: [paypal.me/teslapunk](https://www.paypal.me/teslapunk). Nothing in the tool
itself ever asks for money — no notice, no link, no reminder.

## Licence

MIT — see [LICENSE](LICENSE).

This project is not affiliated with or endorsed by Microsoft. "Windows" is a trademark of
Microsoft Corporation.
