# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Powder Sandbox: a falling-sand world simulation shipped as a single self-contained `index.html` (~250 KB, ~5,500 lines). No build step, no dependencies, no network requests — it must keep working from `file://`. `README.md` documents the user-facing controls, scenes, autoplay and the `window.sandbox` scripting API; read it before changing behaviour.

## Run / verify

- Run: open `index.html` directly, or serve the repo (`python3 -m http.server`) and visit `/`.
- Test: `index.html?selftest` runs the entire in-page suite (physics, ecology, weather, people, conservation rules, music) and prints pass/fail to the console and HUD. There is no CLI test runner, linter or build — this is the verification path.
- Perf: in the browser console, `sandbox.bench(80)` returns `{ms, ticks, drawMs}`; README baseline is ~0.56 ms/tick and ~0.4 ms/draw on the ecosystem scene.
- Deploy: the repo root is already `index.html`, so GitHub Pages serves it from `main` with no extra setup.

## Architecture

Everything lives in global scope in one `<script>`, split by `/* ---------- section ---------- */` banners.

**World data.** `W × H` simulation cells at 4 CSS px each, sized from the viewport. `grid` is a `Uint8Array` of material ids; parallel typed arrays carry per-cell state: `life`, `heat` (temperature field), `moved` (per-tick move guard), `facing`, `hunger`, `alarmT`/`alarmDir` (panic spread), `scent` (ant trails), `home`, `rowLive` (occupied cells per row), `stars`. `resize()` reallocates and resamples the existing world.

**Materials.** `MAT` maps id → `{name, color, glow, density, liquid?, flammable?, life?}`; `MATS`, `LIQUID`, `HOT` derive from it. Ids 0–22 are consts; 23–60 are literal numeric keys because `MAT` is built before those consts are declared — keep that pattern when adding materials. `DIET` / `FEARED` (who eats whom) drive predation, fear and breeding. `density` lets lighter cells displace heavier ones.

**Simulation.** `update()` runs the ambient layer first (rain/snow, acid rain, strikes, volcano, fireflies, wind/gusts, day-night `sun`, seasons `season`, migration of extinct species, milestones), then `spreadHeat()` (heat diffuses hot→cold; moonlight cools), then scans rows bottom-up alternating left/right each tick to kill directional bias. Empty rows are skipped via `rowLive`. `step(x, y, dir)` dispatches per material to a `tickX()` function; `moved` stops a cell moving twice per tick. `update.t` is the tick counter used for periodic events.

**Render.** `draw()` writes one `ImageData` frame: material colour, night/season/heat-view tint, sun/moon/stars on empty sky, glow flicker, brush ring; it also rebuilds `hist` and the population counters the HUD reads. The canvas is W×H and CSS-upscaled (`image-rendering: pixelated`).

**Loop.** `frame()` (requestAnimationFrame): fixed ~30 Hz accumulator scaled by speed (0.5–3×), at most ~3+speed updates per frame, one draw; then autopilot and goal checks; HUD text refreshes twice a second.

**Persistence.** `pack()` / `unpack()` use an RLE string `WxH|id:count,...`. `unpack` rejects a different grid size, so saved scenes, undo and URL-hash links only load at the same W×H. Used by: undo (last 12 snapshots), `localStorage` keys `powder-scene` (Keep/Recall, plus `beforeunload`), `powder-prefs`, `powder-goals`, `powder-chronicle`, and the `Link` button (URL hash). Destructive actions call `snapshot()` first.

**Scenes, autopilot, UI.** `SCENES` is a registry of world builders (`loadScene` snapshots, then runs 24 settling ticks); `?scene=<name>` selects one. `autopilot()` drives the palette like a player (never disasters, pauses between strokes); `?autoplay` enables it and arms the music. Panels: HUD/census/sparkline, palette built from `MATS`, tools, help dialog, event log + chronicle, goals. `h` toggles the `clean` class that hides all panels.

**Audio.** Web Audio only — every note is synthesised. `ac()` exists after the first user gesture; `armMusic()` registers one-time gesture listeners. 15 tracks in 4 mood groups (`cafe`, `cozy`, `study`, `focus`) using `CHORD` / `noteHz`, pad/pluck/drum voices and a tape echo; tracks last 3–5 minutes and cross-fade to a random other track. Music responds to the sky and storms.

## Invariants / gotchas

- Write cells through `set()`, not `grid[i] = v`, in normal code — `set()` maintains `rowLive`. Bulk builders may fill `grid` directly but must call `reindexRows()` afterwards.
- Keep the `moved.fill(0)` contract: exactly one move per cell per tick.
- Stay one file with zero network requests; inline data URIs only (the favicon is embedded this way).
- New behaviour usually needs an `ok(...)` case in `selfTest()`; it swaps in a 40×40 world with weather frozen and restores the real world afterwards.
- Audio cannot start without a gesture (browser autoplay policy) — route start attempts through `armMusic()`.
- `window.sandbox` is the supported scripting surface; update it when adding a user-visible capability.

## Conventions

- Section banners mark the file layout; put new code in the matching section.
- No framework, no dependencies: typed arrays and hand-rolled loops. There are mobile/narrow layouts and a `clean` photo mode — check both when touching UI.
- README, the help panel and `window.sandbox` are user-facing docs; update them when controls or the API change.
