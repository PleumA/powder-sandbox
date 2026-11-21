# Powder Sandbox — Verified Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix every verified defect from the 2026-11-21 review in `index.html` without changing the single-file, offline, zero-dependency architecture.

**Architecture:** All fixes land in `index.html`. Regression checks are added to the existing in-page `selfTest()` suite and run headlessly through a new dev-only `scripts/selftest.sh`. The world stays one struct-of-arrays simulation with the same `window.sandbox` API; the scene payload format is unchanged.

**Tech Stack:** Vanilla HTML/CSS/JS, typed arrays, Canvas 2D `ImageData`, WebAudio, `localStorage`; headless Google Chrome for the checks; no new runtime dependencies.

**Spec:** `docs/superpowers/specs/2026-11-21-powder-sandbox-review.md` — the binding list of findings, required behavior, and explicit out-of-scope items.

## Global Constraints

- The shipping artifact is exactly one file: `index.html`. No build step, no runtime dependency, no network request. `scripts/selftest.sh` is dev tooling only.
- Every automated check lives inside `selfTest()` and runs under `?selftest`. The suite must finish with `selftest: all N passed`; any `FAILED` name is a failure.
- Tests must not flake: use direct function calls with `moved.fill(0)` and explicit `hunger` values; avoid long probabilistically-gated runs. Bounded loops are allowed only where the plan states the bound.
- Do not rename or remove `window.sandbox` members. Validation may reject unknown material IDs; nothing else about the API changes.
- The scene payload stays `WxH|v:n,...` and stays locked to the exact grid size. Failures are surfaced; scaling is out of scope.
- Behavior changes are deliberate and limited to: all creatures can starve (F4); liquids/gases move at most one cell per tick (F7); the OS reduced-motion setting beats a saved `calm:false` (F19); the canvas gains a keyboard path (F10).
- Fix only the findings in the spec. Do not touch the 61 unverified candidates or the two refuted findings.
- Commit once per task, including the `Co-Authored-By` trailer shown in each commit step.

## Review Focus

- **A scene saved or linked at one window size, opened at another** — expect a visible error, never a silent no-op. Test: Task 8 `restoreScene` and Task 7 Recall.
- **Settling a nest or hive at the grid edge or with every neighbour occupied** — no out-of-bounds write, never overwrite the animal. Test: Task 2 edge case.
- **Painting, hovering, or single-stepping while paused** — the screen must update. Tests: Task 11 `needsFrame` and `dirty`.
- **Corrupt, oversized, or non-array `localStorage`/hash data** — no crash and no injected markup. Tests: Task 6 malformed chronicle; Task 8 invalid/truncated scene.
- **Global shortcuts while a toolbar button or select has focus** — the control keeps native behavior and only intended global keys fire. Tests: Task 10 Space and Shift+I.

---

### Task 1: Headless test runner and baseline

**Files:**
- Create: `scripts/selftest.sh`
- Commit (already written by this plan): `docs/superpowers/specs/2026-11-21-powder-sandbox-review.md`, `docs/superpowers/plans/2026-11-21-fix-verified-bugs.md`

**Interfaces:**
- Produces: `bash scripts/selftest.sh` — exits 0 iff the page prints `selftest: all N passed`; exits 1 on `FAILED`; exits 2 if the page produced no result. Prints the result line.

- [ ] **Step 1: Create `scripts/selftest.sh`**

```sh
#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
url="file://$(printf '%s' "$root/index.html" | sed 's/ /%20/g')?selftest"
browser=${BROWSER:-}
if [ -z "$browser" ]; then
  browser=$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)
fi
[ -n "$browser" ] || { echo "selftest: no Chrome/Chromium found" >&2; exit 2; }
out=$("$browser" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=15000 --dump-dom "$url" 2>/dev/null || true)
line=$(printf '%s' "$out" | grep -oE 'selftest: (all [0-9]+ passed|[0-9]+ FAILED[^<]*)' | tail -1)
[ -n "$line" ] || { echo "selftest: no result (page did not run)" >&2; exit 2; }
echo "$line"
case "$line" in *passed) exit 0;; *) exit 1;; esac
```

- [ ] **Step 2: Run the baseline**

Run: `bash scripts/selftest.sh`
Expected: `selftest: all 194 passed`, exit 0. (The 194 is the current count; it grows in later tasks.)

- [ ] **Step 3: Commit**

```bash
git add scripts/selftest.sh docs/superpowers/specs/2026-11-21-powder-sandbox-review.md docs/superpowers/plans/2026-11-21-fix-verified-bugs.md
git commit -m "chore: add headless selftest runner and verified bug-fix plan

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: Settlement beside the animal (birds and bees)

**Files:**
- Modify: `index.html` — add `settleBeside` after `tryMove` (ends :898); `tickBird` :1090; `tickBee` :1461-1464
- Test: `index.html` `selfTest()`, inserted after `ok('bees fill hives', sweet);` (currently :4766)

**Interfaces:**
- Produces: `settleBeside(x: number, y: number, mat: number): boolean` — scans the four orthogonal neighbours in the order up, left, right, down; sets `mat` in the first empty in-bounds cell; returns `true`; never writes `(x,y)`; returns `false` if `mat` is unknown or no neighbour is empty.
- Consumes: `MAT`, `inB`, `idx`, `grid`, `set` (all existing).

- [ ] **Step 1: Write the failing tests**

```js
// a bird settles a nest in an adjacent cell, never on itself
chamber(20,20); moved.fill(0);
set(20,20,BIRD);
const birdNest = typeof settleBeside === 'function' && settleBeside(20,20,NEST);
ok('a bird settles a nest beside itself', birdNest && grid[idx(20,20)] === BIRD && count(NEST) === 1);

// a bee founds a hive in an adjacent cell, never on itself
chamber(20,20);
set(20,20,BEE);
const beeHive = typeof settleBeside === 'function' && settleBeside(20,20,HIVE);
ok('a bee settles a hive beside itself', beeHive && grid[idx(20,20)] === BEE && count(HIVE) === 1);

// the same call at the grid edge stays in bounds
chamber(2,2); set(1,1,BIRD);
ok('settling respects the grid edge', typeof settleBeside === 'function' && settleBeside(1,1,HIVE) && grid[idx(1,1)] === BIRD && count(HIVE) === 1);
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `a bird settles a nest beside itself`, `a bee settles a hive beside itself`, `settling respects the grid edge`.

- [ ] **Step 3: Implement**

Add after `tryMove`:

```js
// place mat in the first empty neighbour; never overwrite the caller
function settleBeside(x,y,mat){
  if (!MAT[mat]) return false;
  for (const [nx,ny] of [[x,y-1],[x-1,y],[x+1,y],[x,y+1]]){
    if (inB(nx,ny) && grid[idx(nx,ny)] === EMPTY){ set(nx,ny, mat); return true; }
  }
  return false;
}
```

In `tickBird`, replace `if (perched && Math.random() < 0.02 && get(x,y) === EMPTY) set(x,y, NEST);` with:

```js
if (perched && Math.random() < 0.02) settleBeside(x,y,NEST);
```

In `tickBee`, replace the inner `if (inB(nx,ny) && grid[idx(nx,ny)] === WOOD && get(x,y) === EMPTY){ set(x,y, HIVE); return true; }` with:

```js
if (inB(nx,ny) && grid[idx(nx,ny)] === WOOD && settleBeside(x,y,HIVE)) return true;
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the three new names are absent from any FAILED list.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(ecology): let birds and bees settle nests and hives beside themselves

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: One hunger rule and frogs that stop starving when fed

**Files:**
- Modify: `index.html` — `step` :731-755; `tickFrog` :1347-1351; remove per-species increments at :1628, :1778, :1836
- Test: `index.html` `selfTest()`, inserted after `ok('frog eats bug', count(LIFE) === 0);` (:4672) and after `ok('creatures starve', count(LIFE) === 0);` (:4742)

**Interfaces:**
- Produces: `step(x,y,dir)` applies the single starvation rule to every creature before dispatch. No new names.
- Behavior change: all creatures can starve; human/deer/heron no longer increment hunger in their own handlers. Task 4's `moved` guard completes the once-per-tick guarantee.

- [ ] **Step 1: Write the failing tests**

After the frog test:

```js
// a frog that eats resets its hunger and survives
chamber(20,20); moved.fill(0);
set(20,20,FROG); set(21,20,LIFE);
hunger[idx(20,20)] = 899;
tickFrog(20,20,idx(20,20));                       // it eats now, deterministically
let frogAt = -1;
for (let i=0;i<grid.length;i++) if (grid[i] === FROG) frogAt = i;
ok('a feeding frog resets its hunger', frogAt >= 0 && hunger[frogAt] < 200);
run(2);
ok('a fed frog does not starve', count(FROG) > 0);
```

After the existing starvation test:

```js
// the rule applies to species that used to return before it
chamber(20,20); set(20,20,CRAB); hunger[idx(20,20)] = 899; run(2);
ok('a crab starves when it cannot feed', count(CRAB) === 0);
chamber(20,20); set(20,20,HUMAN); hunger[idx(20,20)] = 899; run(2);
ok('a person starves when they cannot feed', count(HUMAN) === 0);
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `a feeding frog resets its hunger`, `a fed frog does not starve`, `a crab starves when it cannot feed`, `a person starves when they cannot feed`.

- [ ] **Step 3: Implement**

In `step`, delete these eight lines from their current positions (:734-736, :746-749, :752):

```js
if (v === ANT) return tickAnt(x,y,i);
if (v === CRAB) return tickCrab(x,y,i);
if (v === OCTOPUS) return tickOctopus(x,y,i);
if (v === HERON) return tickHeron(x,y,i);
if (v === GULL) return tickGull(x,y,i);
if (v === HUMAN) return tickHuman(x,y,i);
if (v === DEER) return tickDeer(x,y,i);
if (v === TERMITE) return tickTermite(x,y,i);
```

Keep the existing rule at :755 where it is, and re-insert the eight lines immediately after it, before `if (v === FIRE)`. Change the rule to skip cells that already moved this tick:

```js
if (!moved[i] && IS_CREATURE.has(v) && ++hunger[i] > STARVE){ set(x,y, Math.random() < 0.5 ? COMPOST : EMPTY); tally.starved++; return true; }
```

Delete the three per-species increments (and their trailing comments):

- :1628 `hunger[i] = Math.min(900, hunger[i] + 1);  // a person gets hungry too`
- :1778 `hunger[i] = Math.min(600, hunger[i] + 1);  // a deer gets hungry too`
- :1836 `hunger[i] = Math.min(600, hunger[i] + 1);  // how long since the last catch`

In `tickFrog`, make the eat branch reset hunger:

```js
if (t === LIFE || t === FISH){ set(nx,ny, EMPTY); hunger[i] = 0; break; }
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0. The existing `creatures starve` check still passes; all four new names are absent.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(ecology): one starvation rule and frogs reset hunger when they eat

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: One move per tick

**Files:**
- Modify: `index.html` — `swap` :583-593; `step` :727-730
- Test: `index.html` `selfTest()`, inserted after `ok('water sinks through oil', grid[idx(20,8)] === WATER);` (:4531)

**Interfaces:**
- Produces: `swap(a,b)` marks the destination `moved[b] = 1`; `step(x,y,dir)` returns `false` immediately for a moved cell. No new names.
- Behavior change: liquids and gases move at most one cell per update.

- [ ] **Step 1: Write the failing test**

```js
// a gas rises one cell per tick, not one cell per row of the sweep
shaft(20,6);
set(20,8,STEAM);
run(1);
ok('steam rises one cell per tick', grid[idx(20,7)] === STEAM && grid[idx(20,6)] === EMPTY);
```

- [ ] **Step 2: Run to see it fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `steam rises one cell per tick` (the steam climbs to row 6).

- [ ] **Step 3: Implement**

At the end of `swap(a,b)`, mark the destination:

```js
moved[b] = 1;
```

At the top of `step`, after `const i = idx(x,y);`, add:

```js
if (moved[i]) return false;
```

Leave the existing `moved[j] = 1` in `hop` and `swim`; it is now redundant but harmless.

- [ ] **Step 4: Run to see it pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; `steam rises one cell per tick` absent from FAILED; no existing physics check regressed.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(physics): move each cell at most once per tick

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: An alarm stops when it is already live

**Files:**
- Modify: `index.html` — `raiseAlarm` :1528-1540
- Test: `index.html` `selfTest()`, inserted after `ok('prey flees hunters', ...);` (:4838)

**Interfaces:**
- Produces: `raiseAlarm(x,y,who,esc)` does not extend a cell whose `alarmT` is still in the future. No new names.

- [ ] **Step 1: Write the failing test**

```js
// re-raising does not push the caller's own deadline forward
chamber(20,20); moved.fill(0);
alarmT.fill(0); alarmDir.fill(0);
set(20,20,LIFE);
update.t = (update.t|0) + 1;
raiseAlarm(20,20,LIFE,1);
const alarm0 = alarmT[idx(20,20)];
update.t = (update.t|0) + 1;
raiseAlarm(20,20,LIFE,1);
ok('an alarm does not refresh itself', alarmT[idx(20,20)] === alarm0);
alarmT.fill(0); alarmDir.fill(0);
```

- [ ] **Step 2: Run to see it fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `an alarm does not refresh itself` (the second call extends the deadline by one tick).

- [ ] **Step 3: Implement**

In the inner loop of `raiseAlarm`, immediately after `const j = yy*W + xx;` and the `if (grid[j] !== who) continue;` check, add:

```js
if (alarmT[j] > update.t) continue;     // a live alarm is not extended
```

- [ ] **Step 4: Run to see it pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the new check is absent from FAILED; the existing `prey flees hunters` check still passes.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(ecology): stop alarms refreshing themselves forever

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: The chronicle is text, not HTML

**Files:**
- Modify: `index.html` — chronicle load :4360; `buildHelp` story block :4298-4301
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;` (:5940)

**Interfaces:**
- Produces: `parseChronicle(raw: string): {d: number, t: string}[]` — returns `[]` for malformed JSON, non-arrays, and invalid entries. `chronicleLog` is initialised through it. The Help story is built with DOM nodes and `textContent`.

- [ ] **Step 1: Write the failing tests**

```js
// persisted chronicle text cannot become markup
const storyWas = chronicleLog;
chronicleLog = [{ d: 1, t: '</span><b id="pwn">x</b><span>' }];
buildHelp();
ok('the chronicle cannot inject markup',
  helpEl.querySelector('#pwn') === null &&
  helpEl.querySelector('.hstory').textContent.includes('<b id="pwn">'));
chronicleLog = storyWas;
buildHelp();
ok('a malformed chronicle is ignored',
  typeof parseChronicle === 'function' &&
  parseChronicle('{"x":1}').length === 0 &&
  parseChronicle('[{"d":1,"t":"ok"},{"d":"x","t":2}]').length === 1);
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `the chronicle cannot inject markup` and `a malformed chronicle is ignored`.

- [ ] **Step 3: Implement**

Add before the `let chronicleLog = []` declaration:

```js
function parseChronicle(raw){
  try {
    const v = JSON.parse(raw || '[]');
    return Array.isArray(v) ? v.filter(e => e && typeof e.d === 'number' && typeof e.t === 'string') : [];
  } catch (e) { return []; }
}
```

Initialise:

```js
let chronicleLog = [];
try { chronicleLog = parseChronicle(localStorage.getItem('powder-chronicle')); } catch (e) { chronicleLog = []; }
```

Replace the `.hstory` innerHTML block with DOM construction:

```js
const storyEl = helpEl.querySelector('.hstory');
storyEl.textContent = '';
const story = chronicleLog.slice(-12).reverse();
if (!story.length){
  const s = document.createElement('span'); s.className = 'hl';
  const i = document.createElement('i'); i.textContent = 'nothing yet — light a fire, plant a seed';
  s.appendChild(i); storyEl.appendChild(s);
} else {
  for (const e of story){
    const s = document.createElement('span'); s.className = 'hl';
    const b = document.createElement('b'); b.textContent = 'day ' + e.d;
    s.appendChild(b);
    s.appendChild(document.createTextNode(' · ' + e.t));
    storyEl.appendChild(s);
  }
}
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; both new names absent from FAILED.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(security): render the chronicle as text, not HTML

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 7: Manual saves survive; Recall is undoable and reports failure

**Files:**
- Modify: `index.html` — remove the unload autosave :3374-3376; add `keepScene`/`recallScene` beside the buttons; rewire :3415-3420; add `toastMsg` after `let goalsDone = 0, toastTimer = 0;` (:4399)
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;`

**Interfaces:**
- Produces:
  - `toastMsg(text: string, ms?: number): void` (default 2500 ms)
  - `keepScene(): boolean` — writes `powder-scene`; shows a toast on storage failure
  - `recallScene(): boolean` — reads `powder-scene`; snapshots first; shows a toast and returns `false` on a size-mismatched save
- Consumes: `pack`, `unpack`, `snapshot`, `toastEl`, `toastTimer`.

- [ ] **Step 1: Write the failing tests**

```js
// a manual Keep is not overwritten by a later tab close
let keepWas = null;
try { keepWas = localStorage.getItem('powder-scene'); } catch (e) {}
try { localStorage.setItem('powder-scene', 'MARKER'); } catch (e) {}
dispatchEvent(new Event('beforeunload'));
let keepNow = null;
try { keepNow = localStorage.getItem('powder-scene'); } catch (e) {}
ok('Keep is not overwritten on unload', keepNow === 'MARKER');
try { keepWas === null ? localStorage.removeItem('powder-scene') : localStorage.setItem('powder-scene', keepWas); } catch (e) {}

// Recall restores the kept world and leaves an undo step
chamber(20,20); set(20,20,SAND); undoStack.length = 0;
const kept = typeof keepScene === 'function' && keepScene();
grid.fill(0); life.fill(0); rowLive.fill(0);
const recalled = typeof recallScene === 'function' && recallScene();
ok('Recall is undoable and restores the kept world', kept && recalled && count(SAND) === 1 && undoStack.length > 0);

// a save from another window size is reported, not silently ignored
let sizeWas = null;
try { sizeWas = localStorage.getItem('powder-scene'); } catch (e) {}
try { localStorage.setItem('powder-scene', '999x999|0:1'); } catch (e) {}
const toastBefore = toastEl.textContent;
const sizeFailed = typeof recallScene === 'function' ? recallScene() : true;
ok('a wrong-size save reports an error', sizeFailed === false && toastEl.textContent !== toastBefore && /window/.test(toastEl.textContent));
try { sizeWas === null ? localStorage.removeItem('powder-scene') : localStorage.setItem('powder-scene', sizeWas); } catch (e) {}
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `Keep is not overwritten on unload`, `Recall is undoable and restores the kept world`, `a wrong-size save reports an error`.

- [ ] **Step 3: Implement**

Delete the `beforeunload` listener at :3374-3376 entirely.

Add after `let goalsDone = 0, toastTimer = 0;`:

```js
function toastMsg(text, ms = 2500){
  toastEl.textContent = text;
  toastEl.classList.add('on');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toastEl.classList.remove('on'), ms);
}
```

Add beside the save buttons (before the `psave` listener):

```js
function keepScene(){
  try { localStorage.setItem('powder-scene', pack()); return true; }
  catch (e) { toastMsg('could not save: storage is blocked'); return false; }
}
function recallScene(){
  let s = null;
  try { s = localStorage.getItem('powder-scene'); } catch (e) {}
  if (!s) return false;
  snapshot();
  if (!unpack(s)){ toastMsg('that scene was kept at a different window size'); return false; }
  return true;
}
```

Replace the button bodies with:

```js
document.getElementById('psave').addEventListener('click', () => keepScene());
document.getElementById('pload').addEventListener('click', () => recallScene());
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; all three new names absent from FAILED.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(persistence): keep manual saves safe and make recall undoable

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 8: Validate scenes and links; report failed loads

**Files:**
- Modify: `index.html` — `set` :573-582; `unpack` :3359-3373; `recallScene` (from Task 7); link handler :3405-3413; boot hash :6023-6025
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;`

**Interfaces:**
- Produces:
  - `set(x, y, v): void` — ignores an unknown material ID (`!MAT[v]`); `life` reads `MAT[v].life || 0`
  - `unpack(str: string): boolean` — validates dimensions, every `v:n` token, `1 <= v < MATS.length`, `n >= 1`, and total length `=== W*H`; mutates nothing unless all checks pass
  - `restoreScene(str: string, what?: string): boolean` — `unpack`, else `toastMsg(what + ' was made at a different window size')`
  - `sceneUrl(): string` — absolute document URL plus `#` plus `encodeURIComponent(pack())`
- Consumes: `keepScene`, `recallScene`, `toastMsg` from Task 7; `MAT`, `MATS`, `pack`.

- [ ] **Step 1: Write the failing tests**

```js
// an unknown id never enters the grid
chamber(20,20); set(20,20,STONE);
set(20,20,999);
ok('unknown material ids are ignored', grid[idx(20,20)] === STONE);

// a scene with an unknown id is rejected before it mutates anything
chamber(20,20); set(20,20,STONE);
const badId = unpack(W + 'x' + H + '|999:9');
ok('a scene with unknown ids is rejected', badId === false && grid[idx(20,20)] === STONE && count(999) === 0);

// a truncated scene is rejected
ok('a truncated scene is rejected', unpack(W + 'x' + H + '|1:1') === false);

// a load failure is reported
toastEl.textContent = '';
const toastBefore2 = '';
ok('restoreScene reports a wrong-size scene',
  typeof restoreScene === 'function' && restoreScene('999x999|0:1') === false && toastEl.textContent !== toastBefore2);

// links are absolute even from file://
ok('scene links are absolute',
  typeof sceneUrl === 'function' && sceneUrl().startsWith(location.href.split('#')[0] + '#'));
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `unknown material ids are ignored`, `a scene with unknown ids is rejected`, `a truncated scene is rejected`, `restoreScene reports a wrong-size scene`, `scene links are absolute`.

- [ ] **Step 3: Implement**

Change the top of `set` to:

```js
function set(x,y,v){
  if (!inB(x,y) || !MAT[v]) return;
  const i = idx(x,y);
  const was = grid[i] !== EMPTY, now = v !== EMPTY;
  if (was !== now) rowLive[y] += now ? 1 : -1;
  hunger[i] = 200;
  if (home) home[i] = 0;
  grid[i] = v;
  life[i] = MAT[v].life || 0;
}
```

Replace `unpack` with a validate-first version:

```js
function unpack(str){
  const m = /^(\d+)x(\d+)\|(.*)$/.exec(String(str));
  if (!m || +m[1] !== W || +m[2] !== H) return false;     // a different window size cannot take it
  const cells = [];
  let total = 0;
  for (const part of m[3].split(',')){
    const pm = /^(\d+):(\d+)$/.exec(part);
    if (!pm) return false;
    const v = +pm[1], n = +pm[2];
    if (!MAT[v] || n < 1) return false;
    total += n;
    if (total > grid.length) return false;
    cells.push([v, n]);
  }
  if (total !== grid.length) return false;
  grid.fill(0); life.fill(0); rowLive.fill(0);
  let i = 0;
  for (const [v, n] of cells) for (let k=0;k<n;k++) grid[i++] = v;
  reindexRows();
  draw();
  return true;
}
```

Add `restoreScene` and `sceneUrl` beside `pack`/`unpack`:

```js
function restoreScene(str, what = 'scene'){
  if (unpack(str)) return true;
  toastMsg(what + ' was made at a different window size');
  return false;
}
function sceneUrl(){ return location.href.split('#')[0] + '#' + encodeURIComponent(pack()); }
```

In `recallScene`, replace the `unpack`/toast pair with `if (!restoreScene(s, 'that scene')) return false;`.

Replace the link handler body with:

```js
const url = sceneUrl();
let inBar = false;
try { history.replaceState(null, '', url); inBar = true; } catch (e) { /* file:// may refuse */ }
if (navigator.clipboard){
  navigator.clipboard.writeText(url)
    .then(() => toastMsg('✓ scene link copied'))
    .catch(() => toastMsg(inBar ? '✓ scene link is in the address bar' : 'could not copy the link — copy the URL manually'));
} else {
  toastMsg(inBar ? '✓ scene link is in the address bar' : 'could not copy the link — copy the URL manually');
}
```

At boot, replace the bare hash `unpack` with:

```js
try { restoreScene(decodeURIComponent(location.hash.slice(1)), 'scene link'); } catch (e) { /* not our scene */ }
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the five new names absent from FAILED. The existing `sandbox.load(save())` path still returns true for same-size scenes.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(persistence): validate scenes and report failed loads

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 9: Carve the ecosystem pond and stock it

**Files:**
- Modify: `index.html` — `SCENES.ecosystem`: pond loop :3454-3460, spring :3481, fish :3494
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;`

**Interfaces:**
- No new names. The scene keeps its key `ecosystem` and its shape; water occupies the depth profile, the spring sits at the pond bottom, and the fish are placed in water.

- [ ] **Step 1: Write the failing tests**

```js
// the ecosystem scene carves its pond and puts the fauna in it
SCENES.ecosystem();
ok('the ecosystem pond is deeper than one cell', count(WATER) > 40);
let wetFish = 0, wetSpring = 0;
for (let i=0;i<grid.length;i++){
  if (grid[i] !== FISH && grid[i] !== SPRING) continue;
  const x = i % W, y = (i / W) | 0;
  let wet = false;
  for (const [nx,ny] of [[x,y-1],[x-1,y],[x+1,y],[x,y+1]]) if (inB(nx,ny) && grid[idx(nx,ny)] === WATER) wet = true;
  if (wet && grid[i] === FISH) wetFish++;
  if (wet && grid[i] === SPRING) wetSpring++;
}
ok('ecosystem fish live in the pond', wetFish > 0);
ok('the ecosystem spring feeds the pond', wetSpring > 0);
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `the ecosystem pond is deeper than one cell`, `ecosystem fish live in the pond`, `the ecosystem spring feeds the pond`.

- [ ] **Step 3: Implement**

In the pond loop, replace `if (get(x,y) !== STONE) set(x,y, WATER);` with:

```js
set(x,y, WATER);
```

Replace the spring line with a pond-bottom placement:

```js
const bot = Math.min(H-2, (topsHint[cx] || H-5) + 8);
if (cx > 1 && cx < W-2 && H > 3) set(cx, bot, SPRING);
```

Replace the absolute fish placement loop with a water-scan:

```js
for (let k=0;k<14;k++){
  const x = cx - r + 1 + ((Math.random()*(2*r - 1))|0);   // skip the depth-1 edge columns
  const top = topsHint[x] || H-5;
  for (let y=top; y<Math.min(H, top+12); y++){
    if (grid[idx(x,y)] === WATER){ set(x,y,FISH); break; }
  }
}
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the three new names absent from FAILED.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(scenes): carve the ecosystem pond and stock it

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 10: Input and focus correctness

**Files:**
- Modify: `index.html` — keydown Space :4236-4238; shift/census/Ice :4251-4255, :4266; brush label :214-215; scene change :3730-3733; README controls row
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;`

**Interfaces:**
- No new names. Plain `i` toggles the census; `Shift+I` selects Ice; Space on a focused button or link is left to the browser; the brush slider has `label[for="brush"]`; the scene picker keeps focus.

- [ ] **Step 1: Write the failing tests**

```js
// Space on a focused button is not a global pause
const testBtn = document.createElement('button');
document.body.appendChild(testBtn); testBtn.focus();
const pausedWas2 = paused;
testBtn.dispatchEvent(new KeyboardEvent('keydown', { code: 'Space', key: ' ', bubbles: true }));
const stayedPaused = paused === pausedWas2;
if (!stayedPaused) togglePause();
ok('space on a focused button does not pause', stayedPaused);
testBtn.remove();

// Shift+I selects Ice; plain i still toggles the census
const matWas = current, censusWas = censusOn;
dispatchEvent(new KeyboardEvent('keydown', { key: 'I', shiftKey: true }));
ok('shift+I selects ice', current === ICE);
current = matWas;
censusOn = censusWas;
document.getElementById('census').classList.toggle('on', censusOn);

// the brush slider has an accessible label
ok('the brush slider has a label', !!document.querySelector('label[for="brush"]'));

// choosing a scene does not drop keyboard focus
const scenePick = document.getElementById('scene');
scenePick.focus();
scenePick.value = Object.keys(SCENES)[0];
scenePick.dispatchEvent(new Event('change'));
ok('the scene picker keeps focus', document.activeElement === scenePick);
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `space on a focused button does not pause`, `shift+I selects ice`, `the brush slider has a label`, `the scene picker keeps focus`.

- [ ] **Step 3: Implement**

Immediately before `if (e.code === 'Space'){` add:

```js
if (e.code === 'Space' && e.target && /^(BUTTON|A)$/.test(e.target.tagName)) return;   // let the control activate
```

Before the census branch, add the Ice branch:

```js
if (e.shiftKey && (e.key === 'i' || e.key === 'I')){ select(ICE); return; }
```

Change the census branch to plain `i` only:

```js
if (!e.shiftKey && (e.key === 'i' || e.key === 'I')){ ... }
```

Delete the now-unreachable `if (e.key === 'i' || e.key === 'I'){ select(ICE); return; }` at :4266.

Change the markup to `<label for="brush">Brush <b id="brushval">6</b></label>`.

Delete `sceneEl.blur();` from the change handler.

In README's controls table, change the material row's `i` to `Shift`+`I` and leave the census row as plain `i`.

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the four new names absent from FAILED.

- [ ] **Step 5: Commit**

```bash
git add index.html README.md
git commit -m "fix(input): space on buttons, shift+I for ice, labels and focus

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 11: Reduced-motion precedence, recorder MIME, paused redraw

**Files:**
- Modify: `index.html` — `calmOn` init :2886; `loadPrefs` :4220-4230; Rec handler :3377-3403; `set` (Task 8 version); state :461; `frame` :4437-4450
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;`

**Interfaces:**
- Produces:
  - `prefersReducedMotion(): boolean`
  - `applyPrefs(p: object): void` — SFX/music/weather, then calm with reduced motion winning, then music arming
  - `recMime(): string` — `''` when unsupported, else a MIME type `MediaRecorder.isTypeSupported` accepts
  - `let dirty = true` — set by `set()` and by Task 12's painting
  - `needsFrame(): boolean` — `!paused || dirty || cursor.on`
- `setCalm` still saves the preference; the test restores the stored value.

- [ ] **Step 1: Write the failing tests**

```js
// the OS setting wins over a stored calm:false
const mmWas = window.matchMedia, calmWas = calmOn;
let prefsWas = null;
try { prefsWas = localStorage.getItem('powder-prefs'); } catch (e) {}
if (typeof applyPrefs === 'function'){
  window.matchMedia = () => ({ matches: true });
  applyPrefs({ calm: false });
}
ok('reduced motion beats a saved calm:false', typeof applyPrefs === 'function' && calmOn === true);
window.matchMedia = mmWas;
calmOn = calmWas; reflect(calmEl, calmOn);
try { prefsWas === null ? localStorage.removeItem('powder-prefs') : localStorage.setItem('powder-prefs', prefsWas); } catch (e) {}

// the recorder picks a MIME type the browser supports
const rm = typeof recMime === 'function' ? recMime() : undefined;
ok('recording picks a supported mime', typeof rm === 'string' &&
  (rm === '' || (typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported(rm))));

// paused frames redraw only when something changed
const pausedWas3 = paused, cursorWas = cursor.on;
let dirtyWas = null;
try { dirtyWas = dirty; } catch (e) {}
paused = true; cursor.on = false;
if (typeof dirty === 'boolean') dirty = false;
ok('a clean paused world needs no frame', typeof needsFrame === 'function' && needsFrame() === false);
if (typeof dirty === 'boolean') dirty = true;
ok('a dirty paused world needs a frame', typeof needsFrame === 'function' && needsFrame() === true);
if (typeof dirty === 'boolean') dirty = false;
cursor.on = true;
ok('a visible cursor needs a frame', typeof needsFrame === 'function' && needsFrame() === true);
paused = pausedWas3; cursor.on = cursorWas;
if (dirtyWas !== null) dirty = dirtyWas;
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `reduced motion beats a saved calm:false`, `recording picks a supported mime`, `a clean paused world needs no frame`, `a dirty paused world needs a frame`, `a visible cursor needs a frame`.

- [ ] **Step 3: Implement**

Replace the `calmOn` initialiser with:

```js
function prefersReducedMotion(){
  return typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
}
let calmOn = prefersReducedMotion();
```

Add `applyPrefs` and make `loadPrefs` delegate:

```js
function applyPrefs(p){
  if (typeof p.sfx === 'number') setSfxLevel(p.sfx);
  if (typeof p.musicVol === 'number') setMusicLevel(p.musicVol);
  if (p.weather === false) setWeather(false);
  if (prefersReducedMotion()){ calmOn = true; reflect(calmEl, true); }   // do not overwrite the stored pref
  else if (p.calm === true) setCalm(true);
  else if (p.calm === false) setCalm(false);
  if (p.music) armMusic();
}
```

Add near the Rec handler:

```js
function recMime(){
  if (typeof MediaRecorder === 'undefined' || !MediaRecorder.isTypeSupported) return '';
  for (const m of ['video/webm;codecs=vp9', 'video/webm', 'video/mp4']) if (MediaRecorder.isTypeSupported(m)) return m;
  return '';
}
```

In the Rec click handler, replace the capability check and constructor:

```js
const mime = recMime();
if (!cvs.captureStream || !mime){ toastMsg('this browser cannot record the canvas'); return; }
const stream = cvs.captureStream(30);
recChunks = [];
recorder = new MediaRecorder(stream, { mimeType: mime });
```

Use `mime.split(';')[0]` for the Blob type and `mime.includes('mp4') ? 'mp4' : 'webm'` for the download extension.

Add the dirty state beside the world state (:461):

```js
let dirty = true;
```

In `set()`, after the guard, add `dirty = true;`.

Add `needsFrame` beside `cursor`:

```js
function needsFrame(){ return !paused || dirty || cursor.on; }
```

In `frame`, replace the unconditional `draw();` with:

```js
if (needsFrame()){ draw(); dirty = false; }
```

In the paused branch, mark a single step dirty:

```js
if (stepOnce){ stepOnce = false; update(); dirty = true; }
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the five new names absent from FAILED; the existing audio/prefs checks still pass.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "fix(ui): reduced-motion precedence, recorder MIME, paused redraw

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 12: Keyboard access to the world canvas

**Files:**
- Modify: `index.html` — canvas markup :200; input section :2478-2551
- Test: `index.html` `selfTest()`, inserted immediately before `testing = false;`

**Interfaces:**
- Produces: `kb: {x: number, y: number}` (cell coordinates) and `kbShow()`; the canvas is focusable and carries an `aria-label` that documents the keys. Arrows move, Enter pours, Delete/Backspace erases, `X` picks.

- [ ] **Step 1: Write the failing tests**

```js
// the world canvas is focusable, named, and has a keyboard path
const cvsEl = document.getElementById('c');
cvsEl.focus();
const hasKb = typeof kb === 'object' && kb !== null;
if (hasKb){ kb.x = 20; kb.y = 20; }
ok('the canvas is focusable and named', cvsEl.tabIndex === 0 && !!cvsEl.getAttribute('aria-label'));
cvsEl.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }));
ok('arrow keys move the keyboard cursor', hasKb && kb.x === 21);

const matWas2 = current;
if (hasKb){ current = SAND; kb.x = 20; kb.y = 20; }
cvsEl.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
ok('enter pours at the keyboard cursor', hasKb && grid[idx(20,20)] === SAND);

cvsEl.dispatchEvent(new KeyboardEvent('keydown', { key: 'Delete', bubbles: true }));
ok('delete erases at the keyboard cursor', hasKb && grid[idx(20,20)] === EMPTY);

if (hasKb){ current = WOOD; set(21,20,WOOD); kb.x = 21; kb.y = 20; }
cvsEl.dispatchEvent(new KeyboardEvent('keydown', { key: 'x', bubbles: true }));
ok('x picks the material under the keyboard cursor', hasKb && current === WOOD);

current = matWas2; cursor.on = false; chamber(20,20);
```

- [ ] **Step 2: Run to see them fail**

Run: `bash scripts/selftest.sh`
Expected: exit 1; FAILED includes `the canvas is focusable and named`, `arrow keys move the keyboard cursor`, `enter pours at the keyboard cursor`, `delete erases at the keyboard cursor`, `x picks the material under the keyboard cursor`.

- [ ] **Step 3: Implement**

Replace the whole stage line with:

```html
<div id="stage"><canvas id="c" tabindex="0" aria-label="World canvas. Arrow keys move the cursor; Enter pours the selected material; Delete erases; X picks the material under the cursor."></canvas></div>
```

Beside the pointer handlers, add:

```js
const kb = { x: 0, y: 0 };
let kbCentered = false;
function kbShow(){
  if (!kbCentered){ kb.x = W >> 1; kb.y = H >> 1; kbCentered = true; }
  kb.x = Math.max(0, Math.min(W-1, kb.x));
  kb.y = Math.max(0, Math.min(H-1, kb.y));
  cursor.x = kb.x + 0.5; cursor.y = kb.y + 0.5; cursor.on = true; dirty = true;
}
cvs.addEventListener('focus', kbShow);
cvs.addEventListener('blur', () => { cursor.on = false; dirty = true; });
cvs.addEventListener('keydown', e => {
  const k = e.key;
  const d = k === 'ArrowLeft' ? [-1,0] : k === 'ArrowRight' ? [1,0] : k === 'ArrowUp' ? [0,-1] : k === 'ArrowDown' ? [0,1] : null;
  if (d){ e.preventDefault(); e.stopPropagation(); kb.x += d[0]; kb.y += d[1]; kbShow(); return; }
  if (k === 'Enter'){ e.preventDefault(); e.stopPropagation(); snapshot(); paintCircle(kb.x, kb.y, current); dirty = true; return; }
  if (k === 'Delete' || k === 'Backspace'){ e.preventDefault(); e.stopPropagation(); snapshot(); paintCircle(kb.x, kb.y, EMPTY); dirty = true; return; }
  if (k === 'x' || k === 'X'){ e.preventDefault(); e.stopPropagation(); if (inB(kb.x, kb.y)) select(grid[idx(kb.x, kb.y)]); return; }
});
```

- [ ] **Step 4: Run to see them pass**

Run: `bash scripts/selftest.sh`
Expected: exit 0; the four new names absent from FAILED.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat(a11y): keyboard cursor for the world canvas

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 13: Make the README match the shipped build

**Files:**
- Modify: `README.md` — controls table :28; API list :80; verification :86; notes :91
- Test: `docs/superpowers/specs/2026-11-21-powder-sandbox-review.md` F21; final runner output

**Interfaces:**
- No code. The README quotes the count printed by the final runner and the size printed by `wc -c index.html`.

- [ ] **Step 1: Get the final numbers**

Run: `bash scripts/selftest.sh`
Expected: `selftest: all N passed` — record N.

Run: `wc -c index.html`
Expected: a byte count; round it to the nearest whole KB for the README.

- [ ] **Step 2: Edit the README**

- Replace `**189 in-page checks**` with `**N in-page checks**` (the number from Step 1).
- Replace `One file, ~247 KB` with `One file, ~M KB` (the rounded byte count).
- Change the Ice key in the material row from `i` to `Shift`+`I`.
- Add a controls row: `| arrows, `Enter`, `Delete`, `X` (canvas focused) | move the keyboard cursor, pour, erase, pick |`.
- Remove `flash` from the `Also:` API list (there is no such API member; `flash` is a module-level variable).

- [ ] **Step 3: Verify the drift is gone**

Run: `grep -nE '189|247 KB|`flash`' README.md`
Expected: no output.

Run: `grep -nF '`f` `w` `b` `l` `i`' README.md`
Expected: no output. (The material row now uses `Shift`+`I`.)

Run: `bash scripts/selftest.sh`
Expected: exit 0, `selftest: all N passed` with the same N.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: make the README match the shipped behavior

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## Final verification (after Task 13)

- `bash scripts/selftest.sh` → `selftest: all N passed`, exit 0.
- `git status --short` → only the files this plan touched.
- `git log --oneline -13` → one commit per task.
- Manually open `index.html` from `file://` and check: the ecosystem scene shows a real pond; Keep survives a reload; a wrong-size Link shows the toast; the canvas is reachable by Tab and paints with Enter; pausing and painting still shows the stroke.
