# windows-pitr-config

[![Download pitr-config.cmd](https://img.shields.io/badge/download-pitr--config.cmd-2ea44f?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/henmedia/windows-pitr-config/releases/latest/download/pitr-config.cmd)
[![Latest release](https://img.shields.io/github/v/release/henmedia/windows-pitr-config?style=for-the-badge&label=version&color=555555)](https://github.com/henmedia/windows-pitr-config/releases/latest)
[![Guide](https://img.shields.io/badge/guide-EN%20DE%20FR%20ES%20PT%20IT%20PL-1f6feb?style=for-the-badge)](https://henmedia.github.io/windows-pitr-config/guide.html)

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

The interface speaks **English, German, French, Spanish, Portuguese, Italian and Polish**. It
starts in whichever one matches your Windows display language; the buttons in the top right
switch at any time. The window also links to the project and to the
[short guide](https://henmedia.github.io/windows-pitr-config/guide.html), which opens in the
language you are currently using.

![The tool running on Windows 11 Pro: current state, existing restore points, and the four
settings](docs/screenshot.png?v=1.6.0b)
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
for everything else. The tool says the same thing in its own window.

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
ground in all seven languages. Downloading `guide.html` next to `pitr-config.cmd` makes the
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
output of `reagentc /info`, because that output is translated and this tool speaks seven
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
machine half an hour into its day is usually in use. The request goes to *Queued* and waits.

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

- Windows 11 with Point-in-time restore present (Settings → System → Recovery).
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

The interface speaks seven languages, and corrections are more welcome than new ones. German
is the only one a native speaker has gone through line by line. The other six were not, so a
clumsy phrase, or a term no Windows user in that language would recognise, is entirely
possible. A pull request fixing a single line is worth as much here as a whole new
language.

Everything lives in one table near the top of the PowerShell part, one block per language:

```powershell
$LangText = @{
    en = @{ btnApply = 'Apply' ... }
    de = @{ btnApply = 'Übernehmen' ... }
}
$LangCodes = @('en', 'de', 'fr', 'es', 'pt', 'it', 'pl')
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

## Support

The tool is free and stays that way. If it saved an afternoon of reinstalling Windows, a
coffee is welcome: [paypal.me/teslapunk](https://www.paypal.me/teslapunk). Nothing in the tool
itself ever asks for money — no notice, no link, no reminder.

## Licence

MIT — see [LICENSE](LICENSE).

This project is not affiliated with or endorsed by Microsoft. "Windows" is a trademark of
Microsoft Corporation.
