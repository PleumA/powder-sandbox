# Powder Sandbox — Verified Review Findings (2026-11-21)

**Purpose:** the defect list the implementation plan implements. Only findings that
passed the two-lens adversarial verification in the 2026-11-21 review are in scope.
The review ran six slice readers, an architecture mapper, a whole-file cross-cutting
scan, and two independent verifiers per selected finding (correctness + practical
impact). Several verifiers executed the page in headless Chrome and observed the
behavior, not just the source.

Baseline at review time: `git` clean at `9cc81df`, `index.html` 6,030 lines /
277,840 bytes, `?selftest` prints `selftest: all 194 passed`.

Severity is from the review. "Required" is the behavior the fix must produce; it is
binding on the plan.

## In-scope findings

### F1. Birds can never build a nest (high)
- **Where:** `tickBird`, index.html:1090.
- **Symptom:** while `tickBird` runs, its own cell holds `BIRD`, so
  `get(x,y) === EMPTY` is always false. `NEST` is only ever placed by scenes and
  tests. The dusk roost branch (:1084-1087) is inert for wild birds, and wild-laid
  eggs hatch as `LIFE` (or `FISH` near water) because no adjacent `NEST` exists
  (:2243).
- **Required:** on the existing 2% perch roll, place a `NEST` in an adjacent empty
  cell and leave the bird in its own cell.

### F2. Bees can never found a hive (medium)
- **Where:** `tickBee`, index.html:1461-1464.
- **Symptom:** same own-cell test (`get(x,y) === EMPTY`) plus `set(x,y,HIVE)` would
  overwrite the bee even if the test passed. The honey economy never bootstraps.
- **Required:** with adjacent wood, place a `HIVE` in an adjacent empty cell and
  leave the bee in place.

### F3. Frogs starve while eating (high)
- **Where:** `tickFrog`, index.html:1347-1351; generic rule at :755;
  `eatAround` resets hunger at :1492.
- **Symptom:** eating clears the prey cell but never resets `hunger[i]`. Every frog
  dies ~700 ticks after birth regardless of food.
- **Required:** eating resets the frog's hunger to 0.

### F4. Starvation depends on dispatch order (medium)
- **Where:** `step`, index.html:731-755.
- **Symptom:** ant, crab, octopus, heron, gull, human, deer and termite return
  before the generic starvation rule at :755. Ant/crab/octopus/gull/termite never
  increment hunger at all; human/deer/heron increment it themselves but cap at
  900/600/600 so they never cross `STARVE = 900`. Adding or moving a branch silently
  changes the ecology.
- **Required:** one starvation rule applies to every creature. Per-species hunger
  increments at :1628, :1778, :1836 are removed so hunger ages once per tick.
  **Behavior change:** all creatures can now starve.

### F5. Keep is overwritten on unload; Recall destroys the live world (high)
- **Where:** unload autosave :3374-3376; Keep :3415-3417; Recall :3418-3420;
  size lock :3361.
- **Symptom:** `beforeunload` writes `powder-scene`, the same key Keep writes, and
  Recall is the only reader. Click Keep, keep playing, close the tab — Recall
  restores the close-time world, possibly empty. Recall does not snapshot, so the
  live world is destroyed; a size-mismatched save silently does nothing.
- **Required:** manual Keep survives an unload; Recall is undoable and reports a
  wrong-size save. Remove the unload autosave (there is no boot-time restore; the
  README promises Keep/Recall only).

### F6. Ecosystem pond is one cell deep (high)
- **Where:** scene `ecosystem`, index.html:3442, :3452, :3459, :3481, :3494.
- **Symptom:** `bed(STONE, 0.3, true)` fills every row from the surface to the
  floor with stone; only the top stone row becomes sand; the pond loop skips every
  `STONE` cell. The 9-cell basin is never carved. The spring at `H-2` and the fish
  at `H-1..H-3` are buried under stone.
- **Required:** carve water through the stone profile; place the spring in the pond
  bottom and the fish in pond water.

### F7. Non-creature cells are stepped repeatedly in one tick (medium)
- **Where:** sweep :683-691; `tryMove` :887-898; `hop`/`swap` :960-967, :583-593.
- **Symptom:** the sweep mutates the grid in place bottom-up. Only `hop()` sets
  `moved`; a gas that rises into a row the sweep has not reached is stepped again
  and can cross many rows in one `update()`. Liquid speed likewise depends on scan
  order; per-tick effects such as `life` run once per row traversed.
- **Required:** `swap()` marks the destination moved; `step()` returns early for
  moved cells. **Behavior change:** liquids and gases move at most one cell per
  tick. (A deliberate multi-cell gas rise, if wanted, is a later feature.)

### F8. Kin alarm never decays (medium)
- **Where:** `raiseAlarm` :1539; `fleeFrom` :1556; `tickFish` :1049-1051.
- **Symptom:** `raiseAlarm` includes the caller's own cell, and both callers
  re-raise while their own deadline is live. Every re-raise extends the deadline,
  so a scared shoal stays panic-locked and stops schooling.
- **Required:** an alarm that is still live is not extended.

### F9. Chronicle text is injected into the Help dialog (medium)
- **Where:** `buildHelp` :4298-4301; chronicle load :4360.
- **Symptom:** `powder-chronicle` is parsed without checking it is an array of
  `{d:number, t:string}`, and `e.d`/`e.t` are concatenated into `innerHTML`.
  A same-origin writer can plant markup that executes when Help opens; a non-array
  value also makes `buildHelp` throw. (Precondition: same-origin storage; on GitHub
  Pages project sites share an origin, and Chrome shares `file://` storage.)
- **Required:** validate the parsed chronicle and build the story with
  `textContent`.

### F10. Canvas is pointer-only and unnamed (medium)
- **Where:** markup :200; pointer handlers :2519-2547.
- **Symptom:** `<canvas id="c">` has no name, role or `tabindex`; painting,
  erasing and picking are pointer-only, so keyboard and screen-reader users cannot
  play.
- **Required:** accessible name and focusable canvas plus a keyboard cursor:
  arrows move, Enter pours, Delete/Backspace erases, `X` picks.

### F11. Paused world redraws every frame (medium)
- **Where:** `frame` :4437-4450.
- **Symptom:** `draw()` runs unconditionally after the paused branch; a static
  world still rasterises every cell at display refresh.
- **Required:** draw when unpaused, when a paint/step marked the world dirty, or
  while the cursor ring is visible.

### F12. Scene size mismatch fails silently (medium)
- **Where:** `unpack` :3361; Recall :3419; boot hash :6023-6025.
- **Symptom:** `unpack` returns false for any other grid size and every caller
  ignores it. A shared link or Recall after a window resize does nothing, with no
  message.
- **Required:** report the failure to the user. The payload format stays
  size-locked; scaling is out of scope.

### F13. URL-hash/scene material IDs are unvalidated (medium/low)
- **Where:** `unpack` :3367-3368; `tryMove` :892; API `matId` :5952.
- **Symptom:** `unpack` writes any number 0-255 into the grid; `set()` stores it;
  `tryMove` then evaluates `MAT[v].density` on `undefined` and throws inside the
  animation loop. The scripting API forwards numeric IDs unvalidated.
- **Required:** `unpack` rejects unknown IDs and malformed payloads before
  mutating the world; `set()` ignores unknown IDs.

### F14. Link reports success unconditionally (low)
- **Where:** link handler :3405-3413.
- **Symptom:** the toast says the link was copied even when `replaceState` throws
  and the clipboard is unavailable or rejects; on `file://` the copied value is a
  relative pathname.
- **Required:** build an absolute URL and report the actual outcome.

### F15. Space hijacks focused buttons (low)
- **Where:** global keydown :4236-4238.
- **Symptom:** the handler exempts INPUT/SELECT/TEXTAREA but not BUTTON, then
  `preventDefault()`s Space and toggles pause. A keyboard user cannot activate a
  focused toolbar button with Space.
- **Required:** Space on a focused button or link performs native activation.

### F16. `i` / Ice shortcut collision (low)
- **Where:** keydown :4251-4255 and :4266; README controls.
- **Symptom:** the census branch checks both `i` and `I` and returns, so the later
  Ice branch is unreachable; the README lists `i` for both.
- **Required:** plain `i` toggles the census, `Shift+I` selects Ice; README updated.

### F17. Brush slider has no accessible name (low)
- **Where:** markup :214-215.
- **Symptom:** the visible "Brush 6" label is not associated with the input.
- **Required:** `<label for="brush">`.

### F18. Scene picker blurs itself (low)
- **Where:** change handler :3730-3733.
- **Symptom:** `sceneEl.blur()` after every change loses keyboard focus.
- **Required:** the picker keeps focus.

### F19. Saved `calm:false` overrides OS reduced motion (low)
- **Where:** `calmOn` init :2886; `loadPrefs` :4220-4228.
- **Symptom:** the OS reduced-motion setting initialises `calmOn`, then a stored
  `calm:false` explicitly turns it off.
- **Required:** when the OS asks for reduced motion, calm stays on regardless of
  the saved preference. Extract `applyPrefs` so this is testable.

### F20. Recorder assumes `video/webm` (low)
- **Where:** Rec handler :3381-3390.
- **Symptom:** it checks only that `MediaRecorder` exists, then constructs it with
  a hard-coded `video/webm`. Browsers that record only MP4 throw.
- **Required:** pick a supported MIME type or show the existing "cannot record"
  toast.

### F21. README drift (docs)
- **Where:** README.md:28, :80, :86, :91.
- **Symptom:** says 189 checks (194 at review time, more after this plan), ~247 KB
  (277,840 bytes), lists `i` for Ice, and lists `flash` in the scripting API
  although no such API member exists (only a module-level variable).
- **Required:** accurate count and size after the fixes, `Shift+I` for Ice, no
  `flash` API claim, keyboard-cursor row in the controls table.

## Out of scope

- **Refuted by verification:** fish not seeing frogs through water (deliberate
  ambush behavior, pinned by a passing self-test); the 121-cell alarm scan is
  ~0.34 µs/call and not a performance problem.
- **Unverified:** the 61 lower-priority candidates from the review were never
  verified. Do not "fix" them in this plan.
- **Scene scaling on window resize:** the payload stays size-locked; only the
  error is surfaced.
- **Splitting `index.html` into HTML/CSS/JS files:** declined; the one-file,
  offline, no-build property is the product.
- **README's "headless Playwright pass" claim:** no scripts are shipped. The new
  `scripts/selftest.sh` becomes the shipped check; the README wording is adjusted
  only as described in F21.
