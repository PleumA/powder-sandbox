# Powder Sandbox — feature map

How to find things:

- `grep -n '^// §' index.html` — every section and test-group anchor, in file order.
- `sh scripts/where.sh <word>` — this map, the anchors, symbols, DOM ids and test names in one pass.
- Anchors are names, not line numbers, so they do not rot.

## Section anchors

`CONFIG` `STATE` `GRID` `PHYSICS` `RENDER` `INPUT` `PALETTE` `PALETTE: DRAWER`
`CONTROLS` `PRESENTATION` `AUTOPILOT` `PERSISTENCE` `SCENES` `WEATHER`
`AUDIO` `MUSIC` `HELP` `CHRONICLE` `GOALS` `LOOP` `SELFTEST` `API` `BOOT`

Test groups inside `SELFTEST`: `TEST: MATERIAL REGISTRY` `TEST: PHYSICS` `TEST: ECOLOGY` `TEST: WEATHER`
`TEST: PEOPLE & HERDS` `TEST: AUDIO` `TEST: PERSISTENCE & SECURITY`
`TEST: SCENES` `TEST: UI & INPUT` `TEST: STATE RESTORE`

## Where to change what

| I want to change… | Start at | Search for |
|---|---|---|
| A material's name / colour / glow / density | its `MAT` row | `[SAND]:` |
| A material's physics | its tick handler | `tickSteam` |
| The powder or liquid fallback | `tickPowder` / `tickLiquid` | `function tickLiquid` |
| A creature's behaviour | its tick handler | `tickBird` |
| Diet, predators, fear | `DIET`, `FEARED`, the per-species `sense()` calls | `const DIET`, `sense(` |
| Weather, storm, seasons | the weather block in `update`, `setWeather` | `setWeather`, `raining` |
| Rendering, clouds, heat view | `draw`, `drawClouds`, the palette LUT | `function draw` |
| A UI button or panel | its DOM id and listener | `#clear`, `getElementById('clear')` |
| Painting, pointer, keyboard cursor | the pointer handlers and the canvas keydown | `pointerdown`, `ArrowRight` |
| Save / Keep / Recall / share | `pack`, `unpack`, `keepScene`, `recallScene` | `function unpack` |
| A scene (the ecosystem pond, swamp, snow) | `SCENES`, `loadScene`, `bed`, `terrain` | `SCENES.ecosystem` |
| Autopilot | `autopilot`, the `plan*` helpers, `liveCare` | `function autopilot` |
| Music / lo-fi | `TRACKS`, `musicStep`, `ac` | `TRACKS`, `function ac` |
| Help, goals, chronicle | `buildHelp`, `GOALS`, `chronicle` | `buildHelp` |
| Tests | the matching `// § TEST:` group | `ok('` |
| Scripting API | `SANDBOX_API` | `SANDBOX_API` |
| Boot and URL flags | the bottom section | `// § BOOT` |

## Add a material (before the registry refactor)

1. **ID constant** — append only. The census is `MAT_SLOTS` (256) and the palette is
   sized by `maxId+1`, so new IDs have room. Never renumber: saves and links store raw IDs.
2. **`MAT` row** — name, `color`, `glow`, `density`; `liquid:true` for a liquid;
   `life:n` only for an age-limited material.
3. **`LIQUID` / `HOT`** — only if liquid / ignitable, and they must agree with the
   `MAT` flags.
4. **`step()` branch + `tick<Name>`** for custom physics; otherwise the
   `tickPowder` / `tickLiquid` fallback.
5. **`DESC`** text and a **`CATS`** palette category.
6. **`DIET`** if edible; the hardcoded fire / acid / lightning / egg lists only for
   the interactions you want.
7. One **`selfTest`** check and the README material list.

Silent failures to watch: a missing `DESC` is a blank tooltip; a missing `CATS`
entry becomes "other"; a missing `LIQUID` entry falls through to powder.

## Add a creature

1. **ID + `MAT` row**; do not set `life` unless it is age-limited.
2. **`MIGRANTS` + `IS_CREATURE`**; **`DIET` / `FEARED`** if it eats or is hunted.
3. **`tick<Name>` + a `step()` branch after the generic starvation rule.**
4. The **`sense()` lists** of every species that should see it — those lists are
   hardcoded per species, not derived from `DIET`.
5. A **scene / seed spawn** and the autopilot species lists if it should appear on
   its own.
6. **`DESC`**, **`CATS`**, and one **`selfTest`** check.

## Add a weather, UI, or audio mode

These are cross-cutting today, not registries: expect ~10–12 sites each (state,
`update`, `draw`, controls, prefs, tests). Read the matching `// §` anchors first.

## Invariants

- One shipping file: `index.html`; no build, dependencies, or network; it must run
  from `file://`.
- Material IDs are append-only; saves, links and number hotkeys persist raw IDs.
- `hist`/`prevHist` are `MAT_SLOTS` (256); the palette is `maxId+1`; IDs are append-only.
- The starvation rule stays before every creature branch.
- `sh scripts/selftest.sh` must print `selftest: all N passed` after every change.
- `sh scripts/check-map.sh` keeps the anchors unique and this map honest.

After the registry refactor, the "add a material" checklist shrinks to one `MAT` row
plus one test; update this file then.
