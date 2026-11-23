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
`TEST: SCENES` `TEST: UI & INPUT` `TEST: STATE RESTORE` `TEST: RESET & VALIDATION`

## Where to change what

| I want to change… | Start at | Search for |
|---|---|---|
| A material's name / colour / glow / density / description | its `MAT` row | `[SAND]:` |
| A material's physics | its `tick` field / handler | `tickSteam` |
| The powder or liquid fallback | `tickPowder` / `tickLiquid` | `function tickLiquid` |
| A creature's behaviour | its `MAT` row's `tick` | `tickBird` |
| Diet, predators, fear | the `diet:` field; the derived `DIET`; the per-species `sense()` calls | `diet:`, `sense(` |
| Weather, storm, seasons | the weather block in `update`, `setWeather` | `setWeather`, `raining` |
| Rendering, clouds, heat view | `draw`, `drawClouds`, the palette LUT | `function draw` |
| A UI button or panel | its DOM id and listener | `#clear`, `getElementById('clear')` |
| Painting, pointer, keyboard cursor | the pointer handlers and the canvas keydown | `pointerdown`, `ArrowRight` |
| Save / Keep / Recall / share | `pack`, `unpack`, `keepScene`, `recallScene` | `function unpack` |
| A scene (the ecosystem pond, swamp, snow) | `SCENES`, `loadScene`, `bed`, `terrain` | `SCENES.ecosystem` |
| Autopilot | `autopilot`, the `plan*` helpers, `liveCare` | `function autopilot` |
| Music / lo-fi, picker, vinyl, now-playing | `TRACKS`, `startTrack`, `beginFade`, `musicStep`, `drawVinyl` | `TRACKS`, `drawVinyl`, `#musicpick`, `#nowplaying` |
| World sound (ambience) | `ambienceTargets`, `worldStart`, `worldTick` | `#worldvol`, `worldStart` |
| Lineages (genes) | `gene`, `mutateGene`, `lineageCounts` | `gene`, `.hlineages` |
| Daily world, daily goal | `dailyPlan`, `startDaily`, `DAILY_GOALS` | `?daily`, `#daily` |
| Social amoebae / slime stalks | `tickAmoeba`, `tickStalk`, `camp` | `AMOEBA`, `STALK` |
| Locust phase switch / pods | `tickLocust`, `tickPod`, `form` | `LOCUST`, `POD` |
| Help, goals, chronicle | `buildHelp`, `GOALS`, `chronicle` | `buildHelp` |
| Tests | the matching `// § TEST:` group | `ok('` |
| Scripting API | `SANDBOX_API` | `SANDBOX_API` |
| Boot and URL flags | the bottom section | `// § BOOT` |

## Add a material

The registries are one row now (merged 2026-11-22). Append:

1. **ID constant** — in the id block, append only. Saves and links store raw IDs;
   never renumber. The census and palette size themselves from `MAT_SLOTS` and `maxId+1`.
2. **`MAT` row** — `[NAME]: {name, color:[r,g,b], glow:'#rrggbb', density:n, cat:'…', desc:'…'}`.
   Add `liquid:true`, `life:n`, `hot:1`, `diet:[…]`, `migrant:1`, and/or `tick:…` only as needed.
3. **`tick`** — a handler for custom physics. Use `tick: tickName` when it takes
   `(x,y,i,dir)`; wrap a `(x,y,dir,i)` handler as `tick:(x,y,i,dir)=>tickOld(x,y,dir,i)`.
   No tick means the `tickLiquid`/`tickPowder` fallback.
4. **One `selfTest` check** — the registry checks catch a missing `desc`/`cat`/flag and
   non-dense IDs.

Do not edit `MATS`, `DESC`, `CATS`, `LIQUID`, `HOT`, `DIET`, `FEARED`, `MIGRANTS`, or
the `step()` chain: they are all derived from the `MAT` rows.

## Add a creature

1. **ID + `MAT` row** with `migrant:1`, `diet:[…]` if it eats, and `tick:…`.
2. The **`sense()` lists** of every species that should see it — the one remaining
   cross-species edit, because predator sight is hardcoded per species.
3. A **scene / seed spawn** and the autopilot species lists if it should appear on
   its own.
4. One **`selfTest`** check.

The starvation rule runs before the tick table for every creature, so there is no
branch-order edit and no way to put a creature above it.

## Add a weather, UI, or audio mode

These are cross-cutting today, not registries: expect ~10–12 sites each (state,
`update`, `draw`, controls, prefs, tests). Read the matching `// §` anchors first.

## Invariants

- One shipping file: `index.html`; no build, dependencies, or network; it must run
  from `file://`.
- Material IDs are append-only; saves, links and number hotkeys persist raw IDs.
- `hist`/`prevHist` are `MAT_SLOTS` (256); the palette is `maxId+1`.
- The starvation rule stays before the tick table.
- The registries are derived from `MAT`; do not reintroduce parallel tables.
- `sh scripts/selftest.sh` must print `selftest: all N passed` after every change.
- `sh scripts/check-map.sh` keeps the anchors unique and this map honest.
