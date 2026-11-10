# Powder Sandbox

A living falling-sand world in **one HTML file** — no build step, no dependencies, no network, works offline.

Sand, water, fire, lava, ice, ash, reeds and coal. Deer, herons, gulls, crabs, ants, termites and people who hunt, farm, build, haul and keep a fire. Weather that turns to snow at night, seasons that dry the ponds and brown the reeds, lightning that starts wildfires in a drought and puts itself out in the wet season. Procedural lo-fi that follows the sky, and a chronicle in which the world writes down what happened in it.

**Live demo:** the repo root is already `index.html` — enable GitHub Pages (Settings → Pages → Deploy from branch → `main` / root). Nothing else is needed.

---

## Run it

1. Download `index.html`.
2. Double-click it.

That's it. It runs from `file://`, from a static host, from a USB stick. Everything — graphics, audio, music — is generated at runtime.

## Controls

| Input | Action |
|---|---|
| drag | pour the selected material |
| right-click | erase |
| middle-click | pick a material under the cursor |
| `space` | pause / resume |
| `[` `]` | brush size |
| `0`–`9` | pick a material by number |
| `f` `w` `b` `l` `i` `g` `t` `s` `m` `o` | Fish, Wood, Birds, Bugs, Ice, Glass, TNT, Smoke, Mercury, Worms |
| `y` | mirror painting |
| `h` | hide all panels (press again to bring them back) |
| `/` | focus the material filter |
| `i` | census overlay + population sparkline |
| `k` | lo-fi on / off |
| `n` | weather on / off |
| `j` | broadcast captions on / off |
| `v` | camera drift on / off |
| `p` | scene loop on / off |
| `Ctrl`+`Z` | undo |
| `?` | help panel — goals, creatures, food web, **the story so far** |

Buttons: Pause, Step, Clear, Fill, Rain, Quake, Weather, Volcano, Terrain, Wrath, Storm, Gust, Heat (thermal view: cold blue, black neutral, red hot), Garden, Shot (PNG), Link (share a scene by URL hash), Rec (WebM), Keep / Recall (localStorage), Speed, Sound, Lo-fi, Autoplay, Cast, Cine, Loop, Calm, and a scene picker. The Sound and Music volume sliders appear only while that channel is on.

**Cast** swaps the panels for a stream overlay: the latest chronicle line as a caption, and the current day and track in the corner. **Cine** adds a slow camera drift, **Loop** rotates scenes every 20 minutes through a fade, and **Calm** removes flashes, screen shake and flicker (it starts on when the OS asks for reduced motion). The same are available as `?broadcast`, `?cine`, `?playlist` and `?calm`.

Lo-fi is twenty procedural tracks in five mood groups — cafe, cozy, study, focus and jazz — each 3–5 minutes with different chords, tempos, drum patterns, synth voices and hooks. The jazz set uses ii–V–I changes, walking bass and a brushed kit. When a track ends it fades out, the vinyl keeps playing, and a random track from a random mood group fades in. The music follows the sky (darker at night, faster in a storm).

## Autoplay

- **Autoplay button** turns the world's autopilot on mid-session and starts the music with the click.
- **`?autoplay`** does the same at load (music is armed — the first tap starts it), and accepts a scene: `?autoplay&scene=forest`.

Autoplay never presses a disaster button, but it will use any **element** in small doses. It settles camps (hearth, household, fence, deer), drives herds through them, plants reed beds at the waterline (with fish, herons, fishers and crabs), and drops materials to work with. Camps grow, gain households, spill over into daughter camps, and the herds return to quiet ground.

It also plays the way a person does: it picks from the whole palette — every element and every creature — changes the brush (scaled to the window size), drags a short stream, ground line, fence, creature trail or one small dab with the brush ring visible, then stops for a few seconds to watch what it made. It avoids repeating the last few materials, uses smaller doses for fire, lava, acid, TNT, oil and mercury, and never erases. Now and then it presses Rain or Garden. After 15 minutes on a full, messy world it picks a new random scene. Pauses, strokes and choices are deliberate rather than a spawn every second.

For long live runs it also does housekeeping every 90 seconds: it tops up the bestiary when too little is alive, replants reed beds, settles a household if none is left, sends rain when the world has gone dry, and refreshes a world that has filled up. It never triggers a disaster.

It also runs small projects instead of isolated dabs: a pond with reeds and fish, a grove, a bestiary suited to the scene (water, land or cold), a camp, or a lava-and-water glassworks. Each project is chosen by what the world is missing, staged over several deliberate strokes, and left to settle before the next one. While an experiment scene is active it holds still and lets the experiment play out.

## Scripting

Open the console — `window.sandbox` is the whole API.

```js
sandbox.scene('ecosystem')
sandbox.paint(60, 40, 20, 'lava')
sandbox.put(10, 10, 'heron')
sandbox.step(120)
sandbox.stats()           // { cells, alive, species, born, eaten, starved, day, wet }
sandbox.sun(Math.PI / 2)  // noon
sandbox.season(-2)        // drought
sandbox.weather(false)    // freeze the weather
sandbox.camp()            // settle a household
sandbox.herd()            // drive a herd through the camps
sandbox.reedbed()         // plant reeds, fish, heron, fishers
sandbox.chronicle()      // what happened, as [{ d, t }]
sandbox.bench(80)         // { ms, drawMs, ticks } — simulation and draw cost
```

Also: `get`, `fill`, `clear`, `pause`, `resume`, `speed`, `save`, `load`, `size`, `music`, `lofi`, `auto`, `audio`, `zap`, `heading`, `flash`, `star`.

## Verification

The world carries its own test suite:

- `index.html?selftest` runs **189 in-page checks** (physics, ecology, weather, people, conservation rules) and prints the result in the HUD.
- A headless Chromium/Playwright pass is used during development (scripts are not shipped); the current build measures about **0.56 ms per simulation tick and 0.4 ms per draw** on the ecosystem scene.

## Notes

- One file, ~247 KB, zero dependencies, zero network requests.
- Saves: scenes in `localStorage` (`Keep` / `Recall`), preferences (music, weather), and the chronicle.
- Licence: Apache License 2.0 — see `LICENSE`.
