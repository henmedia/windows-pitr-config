# Changelog

Notable changes are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.2] — 2026-08-31

### Changed

- The four settings sit in two columns instead of four rows, which takes about 135 pixels off
  the window — a tenth of its full height. The window grew 110 pixels wider in exchange, which
  is the cheaper of the two: height is what runs out on a laptop screen, width is not.

  Six grid rows rather than two panels side by side, so both columns share the same rows and
  the drop-downs stay level even when a caption wraps. The column width follows the longest
  caption across all ten languages — "Aufbewahrung — Lebensdauer eines
  Wiederherstellungspunkts" at 375 px — which is what sets the window at 900: it leaves 393 px
  per column, 18 to spare. Checked in every language by measuring the captions' rendered
  height, so a wrap would show up as a number rather than something to spot by eye.

- *Status* is the last column of the restore point list now, after *Build*. It is by far the
  widest, and as the last one it carries the leftover width instead of pushing the narrow
  columns to the right. It also fails better: pulled to its minimum width the window can no
  longer show every column, and what gets cut off is now the status text rather than the build
  number or the duration.

- Space that comes free below the content now goes to the log box instead of standing there
  empty. When a box at the top collapses — the notice about an outdated startup copy, once the
  copy has been refreshed — the content gets shorter while the window stays put, and what was
  left over was an empty strip at the bottom. Shrinking the window would be the obvious answer,
  but a window that shrinks by itself after a click reads as a fault. The log is the one field
  here that genuinely benefits from more height, so it takes the space, and gives it back when
  the content needs room again — never dropping below the height it starts at. Dragging the
  window taller does the same thing, rather than leaving a gap.

  This needed `VerticalAlignment="Top"` on the content panel, and that is not cosmetic. Inside
  a scroll viewer a panel is stretched to the full height of the viewport as soon as the
  content is smaller, so its `ActualHeight` reports the window's height rather than the
  content's — empty space below is then indistinguishable from filled space. Two other
  measurements were wrong for related reasons: `ExtentHeight` is not updated while the content
  fits (measured at 1248 px while the panel had already grown to 1277), and `SizeChanged` fires
  in the middle of the layout pass, where those numbers are still the old ones. The event to
  listen to is `ScrollChanged`, which is precisely the report that viewport or extent has
  changed, and it arrives afterwards.

### Fixed

- The window sized itself too short and kept a scroll bar it did not need. The height was
  computed from the content panel's own height, but the panel carries a 14 px margin on every
  side and those 28 vertical pixels sit outside that number. The window therefore always
  stopped 28 px short of its content: a scroll bar for a remainder that had room to spare, and
  a strip below the last group that looked like wasted space.

  It now takes the panel's height plus its margins — the scroll viewer's own `ExtentHeight`
  looks like the authority but is not, see above — and measures twice: once the window is
  tall enough for the scroll bar to disappear, roughly 17 px of width come
  free, a wrapping paragraph can lose a line, and the content ends up shorter than what was
  just measured — so the second pass is allowed to shrink as well as grow. Three passes cap
  it, two pixels is the threshold below which another correction is not worth making.

Arithmetic alone was not enough either, because a strip can also appear long after
  startup — when a box at the top collapses, which is what the log box above now absorbs. The
  last step of the fit therefore measures rather than computes: whatever room is left in the
  viewport below the content *is* the empty strip, whatever produced it, and it is subtracted,
  keeping one pixel so a rounding error cannot bring the scroll bar back. Verified by forcing
  the window 60 px too tall: the step puts it back exactly, to within a pixel.

  The content's bottom margin went from 14 px to 6. Fourteen matches the top and the sides,
  but there is no next group under the last one — down there the margin carries nothing but
  emptiness.

  On a 1392 px work area the window now ends at 1288 px with no scroll bar and 0.9 px unused,
  against 1254 px with a scroll bar and 25 px of content cut off before. Taken together with
  the two-column settings the content went from 1375 px — which did not fit this screen at
  all — to 1248 px, which fits with room left over.

- The column headers of the restore point list looked clickable and were not. *Time*, *Status*
  and *Build* used WPF's stock header, which is a button: it highlights under the pointer and
  depresses on click, promising a sort that has never existed. *Age* and *Duration* had looked
  different since 1.7.1, where they were given their own template for the right alignment — the
  inconsistency was the visible half of the problem, the false promise the other half. All five
  now share one flat template, and none of them is a tab stop any more.

  The empty column at the right edge was the filler header WPF always draws behind the last
  column. It carried a vertical divider, which read as a further, empty column; now only the
  bottom rule of the header row runs on to the edge.

  One thing goes with it: columns can no longer be dragged wider, because the resize grip lives
  in the stock header template. *Age* and *Duration* had already lost it in 1.7.1 for the same
  reason. The widths are fixed and now fit their content — which is why *Status* was widened in
  the same release.

- The *Status* column of the restore point list cut its own text off. Measured across all ten
  languages it needs 326 px — Spanish "desconocido (se requieren permisos de administrador)" is
  the longest — and it had 250. All five column widths are now derived from a measurement
  rather than an estimate: per column, the widest value that can appear in any language against
  the widest heading, plus the padding. *Time* follows the US format with AM/PM, because dates
  follow the user's region rather than the interface language, so the longest region has to fit.
  The table ends up 744 px wide instead of 712, which the window carries without growing.

- The *Duration* column used a fixed `s` and `min` while the *Age* column right beside it used
  the translated abbreviations. Two spellings of the same unit ended up next to each other: in
  German "37 Min." against "1:35 min", and in Ukrainian two different scripts, "37 хв" against
  "1:35 min". Both columns now take their abbreviation from the same place, and every language
  gained one for seconds — `s` in most, `Sek.` in German, `sec.` in Dutch, `с` in Ukrainian.

  The comment in the code had justified the fixed units by claiming `s` and `min` are the same
  abbreviation in every language. That was already untrue for German, long before Ukrainian was
  added.

- Three comments still counted seven languages. The batch header was corrected in 1.8.1; the
  same stale count sat twice more in the PowerShell part — in the docstring's language list and
  in the note explaining why the recovery environment's state is read from `ReAgent.xml` rather
  than from translated `reagentc` output.

## [1.8.1] — 2026-08-31

A patch rather than a minor version. On a Windows without point-in-time restore the window
used to fill with blank fields and a bare *PITRTask not found*, leaving the reason to
guesswork — naming that state is closer to repairing a defect than to adding a feature.

### Added

- The window now answers, before anything else, whether this Windows has point-in-time
  restore at all. It is not on every Windows 11, and the build number does not settle it: the
  feature also reached existing builds through a cumulative update, so two machines reporting
  the same build can differ. On the machine this was built on the component carries version
  `10.0.26100.8875` inside a system reporting build `26200`.

  The check therefore asks after the component and not after a number. Two things have to be
  present: the COM class the scheduled task calls the snapshot component through
  (`{093CB270-C282-4C22-B2EA-7D2BF1C30BBF}`, whose registration also names the file, so that
  path is read rather than guessed — a registration pointing at a file that is gone does not
  count), and the scheduled task `\Microsoft\Windows\Setup\PITRTask` that calls it on a
  schedule. The answer is the first line of *Current state*, with the component version beside
  it, and it is part of **Copy state** so a forum post carries it too.

  With neither present, a red box says the feature is absent and everything that writes is
  switched off — those values would sit in the registry with nothing to read them. Reading,
  the language buttons and *Copy state* stay available. With only one of the two present, the feature is there
  but incomplete; that is a different finding and is worded differently, the box names the
  missing half and points at an elevated `sfc /scannow`. The controls stay usable in that
  case on purpose — a misreading must not disable the tool on a system where the feature
  works.

  The check costs about 16 ms and reuses the scheduled task the view reads anyway.

- `pitr-config.cmd apply` and `apply status` print the same finding as a warning line when
  the feature does not look present. A warning, not a refusal: a startup script that already
  contains the call should not begin failing because a check misread something.

### Fixed

- The header comment in the file still announced seven languages. There have been ten since
  1.7.1.

## [1.8.0] — 2026-08-31

A minor version rather than a patch: it removes something the window used to show, and the
startup path was rewritten underneath.

### Added

- A "Collecting data..." line under the version, next to the same wait cursor and disabled
  buttons every other longer action already gets. Reading the task scheduler, VSS and the
  registry on startup used to take a second or two, and the only sign of it was quiet
  "reading..." placeholder text in a few fields - easy to miss, and easy to mistake for the
  window having hung. It sits right under the headline rather than in the log at the bottom,
  on purpose: the window opens capped in height and only grows to fit its content once that
  first read completes, so anything in the log would spend the entire wait scrolled out of
  view. "Ready." now prints only once the fields it refers to are actually filled, instead of
  a moment before the window has even drawn them. There is deliberately no minimum display
  time: a floor like that only takes effect when the read was quick, which is exactly when
  nobody needs reassuring, and it would have padded every launch to advertise a wait that did
  not happen. Now that the same read finishes in about a third of a second (see below), the
  line often passes in a blink - which is the honest outcome, not a problem to paper over.

### Removed

- The note that appeared next to the oldest restore point once it passed 72 hours ("the
  extended retention demonstrably works"). The point was proven the day retention beyond 72
  hours was first confirmed to hold; a standing reminder of that in the interface stopped
  earning its place. The oldest point's field no longer changes colour or grows a footnote —
  it just states the point, plainly, same as every other one.

### Changed

- The window's controls are now found with a single walk over the logical tree instead of a
  hand-typed list of `x:Name` values. That list needed a matching edit here whenever the XAML
  gained or lost a name, and nothing caught it when someone forgot - the control would just be
  `$null` until the first thing that touched it threw. Verified against the list it replaces:
  same 80 names, same objects, same types.
- The restore point list matches each point against its Task Scheduler run with a plain loop
  instead of `Where-Object | Select-Object -First 1`, avoiding pipeline overhead on every
  point on every refresh.
- The task history is read through `EventLogReader` instead of `Get-WinEvent`. Same log, same
  filter, same events - but `Get-WinEvent` spends about a second building what it returns, and
  in a freshly started process, which this tool always is, that cost lands on every launch.
  Measured on the same machine and the same 4374-record log: 1050 ms before, 22 ms after, with
  all 38 events and all 19 runs identical down to the millisecond. Two things that looked like
  plausible causes turned out not to be, and are recorded here so nobody re-tries them:
  narrowing the XPath to a time window changes nothing, and neither does the size of the log.
- The startup snapshot's state is read once per refresh instead of twice. `Get-AutoStartState`
  re-fetched the scheduled task its caller had just fetched, and `Get-ScheduledTask` costs
  roughly 400 ms a call whether or not the task exists. It now takes the task it should work
  on.
- Scheduled tasks are **read** through the Task Scheduler's COM interface rather than the
  `ScheduledTasks` cmdlets: the same values arrive in about 20 ms instead of about 400 ms per
  call, and the task's last run, next run and missed-run count now come from the object
  already in hand instead of a second query. Every field was compared against the cmdlets
  before the switch - state, both run times, missed runs, the trigger interval, the idle
  setting, the action's arguments, and the whole idle-health count - and all of them matched.
  Everything that *changes* a task deliberately stays on the cmdlets: lifting and restoring
  `RunOnlyIfIdle` around a forced run, and registering or removing the startup task. Speed is
  worth little there, and a mistake would leave the idle condition switched off, which is not
  a slow failure but a silent one.

Together these took a refresh from about 2.8 s to about 0.3 s.
- The outdated-startup-copy notice is red now, not the same amber as the standing
  "unofficial approach" note. The two read the same at a glance before, but they are not the
  same kind of thing: one is a permanent fact about the tool, the other means the next
  automatic snapshot silently runs an old build. Reuses the red already used for the missing
  recovery-environment warning, for the same reason - the rest of the window matters less
  while either is showing.

## [1.7.1] — 2026-08-30

### Added

- Dutch, Ukrainian and Czech interface translations, alongside the existing seven. The window
  now carries ten language buttons (EN DE NL FR ES PT IT PL UK CS), and
  [docs/guide.html](docs/guide.html) gained a section in each of the three. None of the three
  has had a native-speaker pass yet, same as five of the seven before them.
- A note in the README's *Versioning* section: a release that only adds a language is a patch,
  not a minor version — the interface and its behaviour do not change, only what it can be read
  in.

### Fixed

- Switching languages while "At every system start" was already on could reopen the startup
  snapshot's copy-to-local prompt on every single switch. The delay dropdown is rebuilt on each
  language change to relabel it, and `Items.Clear()` on a populated `ComboBox` fires
  `SelectionChanged` by itself, before anything is reselected — that handler starts the same
  routine a real click does. The rebuild is now silenced the same way the rest of the autostart
  row already was.
- The Age and Duration columns in the restore point list are right-aligned, header included —
  they hold numbers, and a ragged left edge read worse than the ordinary case did.

## [1.7.0] — 2026-08-30

### Added

- **An answer to "why is there no restore point?"** A run that falls due while the machine is in
  use is dropped without a word: `PITRTask` carries `RunOnlyIfIdle`, and Windows writes nothing
  to any log when that condition fails. The only trace is `NumberOfMissedRuns`, which the window
  has always shown — but skipped runs on their own mean nothing, because they are the normal case
  while somebody is working. So when the counter is above zero the window now offers a **Check
  idle** button. It reads every *other* task on the machine that carries `RunOnlyIfIdle` — disk
  cleanup, storage sense, memory diagnostics, two dozen more — and compares their last run
  against the last boot. If at least one of them has run, idle detection works and the machine
  was simply in use. If not one of them has run and the system has been up for more than two
  hours, the idle state is blocked system-wide, and the missing restore points are a symptom
  rather than the fault. The tool's own task is deliberately left out of that count: the green
  button can force it, and a forced run would carry a fresh timestamp that reverses the verdict.
- `pitr-config.cmd idle` — the same check without a window. It only reads, so unlike `apply`,
  `snapshot` and `autostart` it runs without administrator rights, and it returns **2** when the
  idle state is blocked, which makes it usable from monitoring. Rights do change the answer
  though: an unelevated prompt sees only the scheduled tasks visible to that account, so both
  the command and the window say when a verdict was drawn from a partial list.

### Changed

- Timestamps in the window now carry seconds. `Format-Stamp` and the restore point list both
  moved from the region's short date-and-time pattern to the long one — the seconds are what
  makes a point or a run matchable against an entry in the Task Scheduler, and without them a
  next run at 20:47:22 simply read 20:47. The time column grew from 150 to 172 pixels to fit
  the widest case, which is the English 12-hour form.

### Fixed

- The warning about an outdated startup copy printed the same version number twice when the copy
  differed from the running file in content only — "runs version 1.6.0 … this one is 1.6.0". The
  detection was right, the sentence was not: a different version and a different build of the
  same version now read differently.

## [1.6.0] — 2026-08-29

### Added

- **A restore point at every system start.** A checkbox under the green button registers a
  scheduled task that creates a point the chosen number of minutes after each boot, 1 to 30,
  five by default. Windows already asks for one — `PITRTask` has a boot trigger with a thirty
  minute delay — but that request waits for the system to go idle, which a machine that just
  started is not. The task forces the run the same way the button does, and the Windows task
  itself is left alone.
- **A warning when the startup task runs an older copy.** The task remembers one fixed path,
  so a copy in `ProgramData` keeps running while a newer version is started from elsewhere —
  silently, and for as long as nobody looks. The window now compares the two on every refresh
  and offers to refresh the copy in place, keeping the delay that was set. Versions are read
  from the file itself; when they match but the contents do not, the checksums decide.
  `autostart status` reports the same thing on the command line.
- `pitr-config.cmd snapshot` — creates a restore point without a window, for scripts and for
  the startup task itself.
- `pitr-config.cmd autostart on delay=5m` / `off` / `status`.
- **A duration column in the restore point list.** Windows records the length of a snapshot
  nowhere — neither `Win32_ShadowCopy` nor the volume snapshot log knows a timespan; the pairs
  in that log describe volumes going online and offline. The one source is the Task Scheduler
  history: events 100 and 102 carry the same instance id, and their difference is the runtime
  of `PITRTask`. A point belongs to the run whose window contains its timestamp.
  That history is off by default in Windows. While it is, the column stays empty and a line
  under the list offers to switch it on, saying what that changes — a system-wide logging
  setting, and only for runs from then on. The tool never switches it on by itself.
- **How long a snapshot took**, in the log: the runtime of the task from start until it is
  back to *Ready*, which is the time Windows spends on the shadow copy. Resolution is the
  1.5 seconds of the polling loop. If the wait runs out before the task finishes, the log says
  so instead of reporting a duration — that number would be the waiting time, not the
  snapshot's.

### Fixed

- **The window now appears before the data does.** Reading the scheduled task, VSS and the
  registry takes one to two seconds, and until now all of it happened before anything was on
  screen — which looks exactly like nothing happening. The fields start with a *reading…*
  placeholder and fill as soon as the window has been drawn: visible after roughly 0.4 s,
  filled about 1.9 s later.
- **The recovery partition figures cost 1.7 seconds of that.** `Get-Partition` and `Get-Volume`
  load the Storage module on first use; the same information straight from the
  `root/Microsoft/Windows/Storage` CIM namespace needs 200 ms and no module at all.
- The window took noticeably longer to open once the task history was on. The duration lookup
  fetched 600 events and picked out the PITRTask ones in PowerShell — and parsing an event
  costs about a millisecond, so that was 600 ms of startup for six useful events. The filter
  now runs inside the event log (`-FilterXPath` on the task name), which brings it to 15 ms and
  keeps it there however full the log gets.

### Notes

- The task runs as `SYSTEM` with a boot trigger, so it fires without anyone signing in.
- **A startup snapshot cannot work from a network share.** `SYSTEM` reaches the network as the
  computer account, not as the signed-in person, so a share that opens fine in Explorer is
  usually out of reach for the task. Switching the checkbox on from such a path now offers to
  copy the file to `%ProgramData%\pitr-config\` and register the task against that copy;
  `autostart on copy` does the same from the command line.
- With Fast Startup enabled, shutting down and switching on again is a resume, not a boot, and
  boot triggers do not fire. A restart does trigger it. This cannot be worked around from a
  tool.
- Nothing comparable is offered for shutdown, deliberately: Task Scheduler has no shutdown
  trigger, an event-triggered task gets killed halfway through the snapshot, and a Group Policy
  shutdown script would hold up the shutdown for as long as VSS needs. A point taken at
  shutdown would also differ very little from one taken twenty minutes earlier.

## [1.5.0] — 2026-08-28

### Added

- **The state of the recovery environment** in the *Current state* box, with the size and free
  space of the recovery partition. A restore point is applied from that environment, not from
  inside Windows — if it is switched off, the tool would otherwise collect points that nobody
  can reach when it matters. The line turns red and explains itself in that case. The state is
  read from `ReAgent.xml`, not from the translated output of `reagentc /info`, and the
  partition is found through the disk number and byte offset recorded there.
- **Restart to recovery** next to that line — reboots straight into the recovery environment,
  where a point gets applied. Asks first, because it is the only button that restarts the
  machine. Windows does offer that route, under Settings → System → Recovery → Advanced
  startup, but several clicks away from anything to do with restore points. README and guide
  put it right behind *Create snapshot now*: creating a point and reaching the place where it
  gets applied are two halves of the same thing.
- **Copy state**, below the log: puts the whole state into the clipboard as plain text, in the
  language currently selected. Made for a forum post or a bug report.
- **A command line for scripts**: `pitr-config.cmd apply freq=4h reten=5d size=20g active=on`,
  plus `reset` and `status`. It writes without opening a window, needs an elevated prompt and
  deliberately does not elevate itself — elevation would start a new process whose output and
  exit code never reach the caller. Exit codes: 0 done, 1 bad argument, 5 not elevated. Its
  output stays English whatever the display language is, and `status` prints the raw level, so
  scripts have something stable to read.
- **A plain statement that this is not a backup**, in the window, the README and the guide. The
  restore points live on the very volume they protect, so a failed disk, a stolen machine or a
  wiped volume takes them along. Point-in-time restore answers a bad update or a bad driver;
  hardware failure, theft and ransomware need a backup on separate media. Easy to assume
  otherwise from a feature that promises to roll the whole system back.
- Italian and Polish interface translations, alongside English, German, French, Spanish and
  Portuguese. The guide covers both in full, including the section on creating a snapshot on
  demand.
- A discreet support note at the end of the guide, in every language, matching the one in the
  README. Nothing about it appears in the tool itself.
- A *Translations* section in the README: how the language table is built, what a new language
  needs, and the traps worth knowing — doubled ASCII apostrophes, terminology taken from the
  Windows interface of that language, no forms of address, and plural forms that vary with the
  number. Corrections to the existing six are wanted more than new languages; German is the
  only one a native speaker has reviewed.

### Changed

- The language buttons wrap to a second row instead of taking width from the headline. The row
  keeps the width it had with five buttons; the sixth and later ones move down.
- Terminology follows the Windows interface of each language rather than a literal translation
  — *punto di ripristino* and *copia shadow* in Italian, *punkt przywracania* and *kopia w
  tle* in Polish. Polish hours are abbreviated as `godz.`, because the full word takes a
  different form depending on the number (2 godziny, 5 godzin) and the interface shows both.

## [1.4.1] — 2026-08-27

### Changed

- The guide mentions that the file runs just as well from a USB stick or a network share.
- The Spanish guide still addressed the reader in one place (*hasta que pulse un botón*),
  missed when the address forms were removed in 1.3.1.

### Fixed

- Started from a network share, `cmd.exe` printed a warning of its own before the tool ran:
  *UNC paths are not supported*, falling back to `C:\Windows` as the current directory. It
  reads like a failure but has none — the loader only ever uses its own full path and never
  the current directory. `@echo off` cannot suppress the message, because `cmd.exe` writes it
  itself, to stderr, before the first line of the file runs. The loader now recognises a start
  from a UNC path and clears the message from the console, leaving a short line in its place.
  The selftest is deliberately left alone: it writes into a console whose contents nobody
  wants cleared.

## [1.4.0] — 2026-08-27

### Added

- **Create snapshot now** — a highlighted button at the top of the window that creates a
  restore point immediately, without writing any setting. The tool could already force a
  point, but only through *Apply and run now* at the bottom, which saves the settings along
  with it; creating a snapshot on demand is the more common reason to open the tool at all
  and now has its own button.
- The guide covers it in all five languages, with its own section and a row in the button
  table.

### Changed

- The note about idle time now points at the new button as the way to force a point.
- The German interface used a mixed pair of quotation marks in the unofficial-approach
  notice.

## [1.3.1] — 2026-08-27

### Changed

- Guide and interface no longer address the reader. German had to choose between "du" and
  "Sie", and Spanish, French and Portuguese between their familiar and polite forms; that
  choice is now avoided altogether by phrasing everything impersonally. English follows the
  same register for consistency.

### Fixed

- Last run and next run were shown in US notation on every system, `08/27/2026` instead of
  `27.08.2026`. PowerShell formats a date inside a double-quoted string with the invariant
  culture rather than the user's, so `"$date"` silently produced US order. All timestamps now
  go through one helper that uses the short date and time format of the user's region, the
  same as the restore point list.

## [1.3.0] — 2026-08-27

### Fixed

- The scheduled interval was computed as *next run minus last run*, which is only the
  configured interval when no run is ever skipped. Since the task runs only while the system
  is idle, skipped runs are the normal case — an hourly schedule then showed up as two hours,
  with a misleading note claiming the value stemmed from a previous setting. The interval is
  now read from the repetition of the task's time trigger, where it actually lives.

### Added

- Skipped runs are shown next to the task status. They are what explains a gap between two
  restore points that is longer than the configured interval.

### Changed

- The window is no longer a fixed 880 pixels tall. It opens at 800 at most, and never taller
  than the work area minus a margin — the work area excludes the taskbar, so the window can
  no longer end up behind it. On a tall screen it grows beyond 800 if that lets the content
  fit without scrolling, and it is re-centred on the work area afterwards.
- The introduction and the "unofficial approach" notice now run the full width of the window.
  They used to sit in the left column next to the language buttons, where they wrapped early
  and left the area beneath the buttons empty.
- The scheduled interval and the task status swapped places, and the restore point count now
  shares a line with the oldest point.
- Paddings, margins, the restore point list and the log box were tightened throughout. The
  same content now needs roughly 200 pixels less height.

## [1.2.1] — 2026-08-27

### Fixed

- The Windows edition was shown as *Windows 10 Pro* on Windows 11. The tool read
  `ProductName` from the registry, and Microsoft never updated that value for Windows 11 —
  it still reads "Windows 10" there, for application compatibility. The build number is used
  as the discriminator instead: 22000 and above is Windows 11.

- Restore point timestamps were formatted as `dd.MM.yyyy`, a German convention, in every
  language. They now follow the date format of the user's region, like every other date
  in the window.

### Changed

- The state line now also shows the feature update and the full build, for example
  `Windows 11 Pro (EditionID: Professional) — 25H2, Build 26200.9168`.

## [1.2.0] — 2026-08-27

### Added

- A check for a newer release on start. When one exists, the window shows a line with a link
  to the release page, in whichever language is selected. The check runs in a background
  runspace so the window stays responsive, and it fails silently — no network, a firewall or
  GitHub's rate limit simply means no notice appears.
- `pitr-config.cmd noupdate` skips that check. The argument is passed on across the elevation
  prompt, which starts a new process that would otherwise lose it.

### Notes

- Nothing is downloaded or installed automatically, by design. A tool that writes to `HKLM`
  should not replace its own code over the network, and doing so would make the published
  checksums pointless. The notice is a link; the decision stays with the user.
- The update check is the only network connection the tool makes. The request reveals nothing
  about the system beyond what any web request does — an IP address and a `pitr-config` user
  agent.

## [1.1.0] — 2026-08-27

### Added

- French, Spanish and Portuguese interface translations, alongside the existing English and
  German. The language is still detected from the Windows display language; the top right now
  carries one button per language (EN DE FR ES PT) with the active one marked.
- A link to the project page and to a short guide in the window header. The guide opens in
  the language currently selected.
- `docs/guide.html` — a short guide in all five languages in one page, published at
  <https://henmedia.github.io/windows-pitr-config/guide.html> and attached to the release. A
  copy placed next to `pitr-config.cmd` takes precedence over the online version, so the tool
  stays fully usable without a network.

### Changed

- The text table is now organised as one block per language instead of one entry per string,
  which keeps a translation readable as a whole. Missing entries fall back to English, so an
  incomplete translation degrades to a mixed interface rather than to empty labels.

## [1.0.0] — 2026-08-26

First public release.

### Added

- Configuration of Point-in-time restore frequency, retention and storage limit on any
  Windows 11 edition, by writing the undocumented `_GPO` level values directly.
- Single self-contained `.cmd` file with a WPF interface. Self-elevating, portable, no
  installation and no PowerShell modules.
- Bilingual interface (English / German) with automatic detection of the Windows display
  language and a switch button in the top right.
- Current-state display: Windows edition, last and next task run, scheduled interval, and
  the state of `PITRTask` — including *waiting for the system to go idle* and a marker for
  an overdue run.
- List of existing restore points with age, build and whether a shadow copy still backs the
  registry entry.
- Shadow storage figures for the OS volume (in use, reserved, limit).
- **Apply and run now**, which lifts the task's idle condition for exactly one run and
  restores it afterwards, including on error.
- **Reset everything**, which removes every value the tool has written.
- `pitr-config.cmd selftest` — a read-only check of the interface with no window, no
  administrator rights and nothing written.

### Notes

- Frequency is an earliest possible interval, not a guarantee: restore points are only
  created while the system is idle.
- Only the OS volume is covered. Other partitions and disks are neither captured nor rolled
  back.
- Retention beyond the documented 72 hours was verified in practice.
