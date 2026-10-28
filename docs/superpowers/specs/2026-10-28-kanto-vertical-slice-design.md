# Open-World Pokémon Remake — Kanto Vertical Slice Design

- **Date:** 2026-10-28
- **Status:** Draft, awaiting owner review
- **Sub-project:** 1 of 5 (vertical slice). Later sub-projects get their own specs.

## 1. Purpose and context

A personal, non-commercial open-world reimagining of the mainline Pokémon games
(Red/Blue through Black 2/White 2), played by the owner and shared with at most a
handful of friends.

The owner plays and gives feedback; Claude writes all code. Builds are delivered
as a Windows desktop executable.

### 1.1 Overall program (for orientation only)

| # | Sub-project | Status |
|---|---|---|
| 1 | Kanto vertical slice: engine core, living world, spawning, real-time combat, capture, progression, save | **This spec** |
| 2 | Full Kanto: all routes, towns, Gyms, story | Later |
| 3 | Expanded quest and storyline system | Later |
| 4 | Johto, Hoenn, Sinnoh, Unova as separate open-world regions linked by travel (S.S. Aqua, Magnet Train, flights) | Later |
| 5 | Roster scale-up to Gen 1–5 (649 species) | Later |

### 1.2 Asset and IP policy

- The repository contains **no Nintendo / Game Freak / The Pokémon Company assets**
  (sprites, tiles, audio, models).
- The repository ships original placeholder art.
- The owner may place their own asset files in a local `user_assets/` folder, which
  is git-ignored and loaded at runtime through an override manifest (§9).
- Species names, types, base stats, moves and formulas are used as game data for
  this private project.

## 2. Decisions made

| Topic | Decision |
|---|---|
| Visual style | **HD-2D:** 2D billboard sprites in a 3D tile-built world, modern lighting and post-processing |
| Engine | **Godot 4** (latest stable 4.x at plan time), GDScript |
| Renderer | **Forward+** (desktop). The browser build is not a target, because the web export only supports the Compatibility renderer. |
| Platform | **Windows** desktop, x86_64 |
| Combat | Real-time and in the overworld. The player directly controls the lead Pokémon. |
| PP | **Removed**, replaced by cooldowns |
| Accuracy | **Replaced by aim and telegraphs**; no random misses |
| World structure | Each region is its own seamless streamed open world; regions are linked by travel |
| Interiors | Separate scenes with a short fade (~0.3 s) |
| Slice area | Pallet Town → Route 1 → Viridian City → Route 2 (south) → Viridian Forest |
| Spawn lists | Expanded beyond Red/Blue (Gen 2+ species allowed) |
| Mechanics baseline | Gen 5 formulas, adapted for real time |

## 3. Success criteria (definition of done)

1. The player walks from Pallet Town to Viridian Forest with no loading screens
   outdoors. Interiors fade.
2. Wild Pokémon are visible, roam, respawn, and change with location, time of day
   and weather.
3. Day/night and weather run continuously and visibly change lighting,
   post-processing, NPC behavior and spawns.
4. Towns and routes feel inhabited: NPCs follow daily schedules, react to weather,
   and have dialogue (§7).
5. The player can fight, weaken and catch a wild Pokémon in real time, gain EXP,
   level up, learn moves and evolve.
6. The player completes the Oak's Parcel quest and one rival battle.
7. Save and load work, including recovery from a corrupt save.
8. It holds a stable 60 fps at 1080p on "High" preset on a mid-range PC
   (reference: GTX 1660 / RX 5600 class, 16 GB RAM). Lower presets exist for
   weaker hardware.
9. The full automated test suite passes in CI, and CI produces a Windows build.

## 4. Architecture

Systems are decoupled. They communicate through a global `EventBus` autoload
(Godot signals) and read content from data files. Each system lives in its own
folder with its own tests.

| System | Responsibility | Depends on |
|---|---|---|
| `Clock` | Game time; default 1 real hour = 1 game day; adjustable, or follows the PC's real clock. Emits `period_changed` (morning/day/evening/night) and `hour_changed`. | — |
| `Weather` | Rolls weather per area from weighted tables; transitions over 20–40 s; emits `weather_changed`. | Clock |
| `Lighting` | Drives sun/moon angle, sky, exposure, fog, color grading and post-processing from Clock and Weather. | Clock, Weather |
| `WorldStreaming` | Loads and unloads 64×64 m chunks around the player (3×3 ring loaded, 5×5 preloaded on a background thread). | — |
| `Spawning` | Per-zone spawn tables; population cap; respawn timers; despawn by distance. | Clock, Weather, WorldStreaming, Creatures |
| `Creatures` | Species, stats, IV/EV, natures, learnsets, evolution, EXP. Pure logic. | Data |
| `Combat` | Fight ring, hitboxes, cooldowns, damage, status, stat stages, AI. | Creatures |
| `Capture` | Aim/throw, Gen 5 catch formula, critical capture. | Creatures, Combat |
| `NPCs` | Schedules, pathing, dialogue, barks, reactions (§7). | Clock, Weather, WorldStreaming |
| `Party` / `Inventory` | Party of 6, PC boxes, items, money. | Creatures |
| `Quests` | Flags and a minimal quest state machine (slice: Oak's Parcel). | EventBus |
| `Save` | Versioned JSON save with migration and backup. | All stateful systems |
| `AssetOverride` | Resolves art from `user_assets/` with fallback to placeholders. | — |

### 4.1 Repository layout

```
project.godot
addons/gut/                 # test framework
data/                       # all content (JSON)
  species/  moves/  types.json  natures.json
  spawns/   weather/  npcs/  dialogue/  quests/
src/
  core/  (EventBus, Clock, Weather, Save, AssetOverride)
  world/ (streaming, chunks, lighting, interiors)
  creatures/  combat/  capture/  npcs/  quests/  ui/
scenes/
  regions/kanto/chunks/  interiors/
assets/placeholder/
tests/unit/  tests/integration/
tools/                      # data validator, chunk authoring scripts
user_assets/                # git-ignored
.github/workflows/build.yml
```

## 5. Combat and capture

### 5.1 Flow

- **Starting a fight:** one side attacks, or an aggressive wild Pokémon charges
  and connects. A ~12 m fight ring forms around the fight. The lead party
  Pokémon is released and the player now controls it. The camera tightens
  slightly.
- **Wild fights:** the player escapes by staying outside the ring for 3 s.
- **Trainer fights:** no escape. The ring is fixed.
- **Switching:** a 1.5 s swap during which the incoming Pokémon is vulnerable,
  then a 5 s cooldown before the next switch.
- **Defeat:** if the whole party faints, the player blacks out to the last
  Pokémon Center and loses money (Gen 5 rule: based on badges and level).

### 5.2 Controls

Controller and keyboard/mouse:

- Move
- Dodge-roll: 0.25 s of invulnerability, costs stamina
- Four move slots
- Switch Pokémon
- Aim and throw ball
- Interact
- Menu

### 5.3 Mechanics adaptation

| Main games | Real-time rule |
|---|---|
| Damage | Gen 5 formula: `((((2·L/5+2)·Power·A/D)/50)+2) × STAB(1.5) × type × random(0.85–1.00) × crit(2.0) × burn(0.5, physical) × weather` |
| Critical hits | Gen 5 stage-0 rate of 1/16, with Gen 5 stage table |
| PP | Removed. `cooldown = clamp(28 / PP, 0.6, 8.0)` seconds. Tackle (35 PP) ≈ 0.8 s, Hydro Pump (5 PP) ≈ 5.6 s. Tunable per move. |
| Accuracy | No RNG misses. Lower accuracy means a longer wind-up or a narrower hitbox (data-driven per move). |
| Speed stat | Scales movement speed and wind-up time |
| Priority | Priority +1 or higher means near-instant wind-up |
| Paralysis | Speed × 0.25 (Gen 5). 25% chance per 2 s to be stunned for 0.75 s. |
| Sleep | Cannot act for 3–6 s; taking damage ends it early |
| Poison / Burn | 1/8 max HP damage every 4 s (scaled from per-turn) |
| Freeze | Immobile; ends after 2–5 s or immediately on a Fire hit |
| Stat stages | ±6, Gen 5 multipliers; reset when the fight ends |
| Weather (rain / sun) | Water ×1.5 / Fire ×0.5 in rain, and the reverse in harsh sun |

Each move's data includes a **shape**: melee arc, projectile, beam, area at
target, or self-buff. Each move also has a wind-up time, active frames, range
and an optional status chance.

### 5.4 Wild AI temperaments

Defined per species:

- **Timid:** flees on sight (Pidgey)
- **Aggressive:** charges when the player is close (Rattata, Weedle)
- **Territorial:** defends a radius around its spawn point
- **Passive:** ignores the player until attacked (Metapod, Kakuna)

### 5.5 Capture

The catch chance uses the Gen 5 formula:

`a = ((3·HPmax − 2·HPcur) · catchRate · ballBonus / (3·HPmax)) · statusBonus`

- `statusBonus` is 2.5 for sleep or freeze and 1.5 for paralysis, poison or burn.
- Gen 5 shake checks and critical capture are implemented.
- **Sneak throw** (non-canon addition): a ball thrown before a fight starts gets
  a ×1.5 bonus.

### 5.6 Slice content

- About 15 species: the three Kanto starters and the slice's spawns.
- About 30 moves.

## 6. World, time, weather, spawning, lighting

### 6.1 Scale and layout

- 1 tile = 1 m.
- Areas are scaled ~4–6× from Red/Blue.
- Layouts stay recognizable: Route 1 runs north from Pallet to Viridian; the
  ledges return; Viridian Forest is still a maze. Side paths, ponds, groves and
  landmarks are added to fill the space.

### 6.2 Time periods

| Period | Hours | Look |
|---|---|---|
| Morning | 04–10 | Low warm sun, forest mist |
| Day | 10–17 | Bright neutral |
| Evening | 17–20 | Orange sky; lamps and windows switch on |
| Night | 20–04 | Moonlight; cool tones; local light from lamps, windows and glowing Pokémon |

### 6.3 Weather

- **Types:** clear, cloudy, rain, thunderstorm, fog (forest only).
- **Effects:** particles, wet surface shading, puddle reflections, lightning,
  fog density, NPC behavior (§7), spawn modifiers and combat modifiers.

### 6.4 Spawning

- Each zone has a table; each entry has species, level range, weight, allowed
  periods and weather multipliers.
- Population is 8–12 active within 60 m of the player. Pokémon are despawned
  beyond 80 m.
- Spawn points are only chosen outside the camera view, at least 25 m from the
  player.
- A defeated or caught Pokémon's slot respawns after 1–3 game minutes.
- Shiny rate is **1/8192**. Shinies sparkle in the overworld.

**Slice spawn plan (draft, final values tuned in the plan):**

| Zone | All day | Morning / Day | Night | Weather notes |
|---|---|---|---|---|
| Route 1 | Pidgey, Rattata | Sentret | Hoothoot | — |
| Route 2 (south) | Pidgey, Rattata, Caterpie, Weedle | Sentret | Hoothoot | — |
| Viridian Forest | Caterpie, Metapod, Weedle, Kakuna, Pikachu (rare) | — | Hoothoot, Oddish | Pikachu ×3 weight in thunderstorms; Bug weights ×0.5 in rain |

### 6.5 Lighting and post-processing

- A sun and moon on an arc, casting shadows.
- SDFGI (Godot's dynamic global illumination), with VoxelGI or baked lighting
  in interiors.
- SSAO and SSIL.
- Volumetric fog.
- Glow (bloom).
- Tilt-shift depth of field.
- ACES/AgX tonemap.
- Per-period color grading LUTs.
- Graphics presets: Low, Medium, High, Ultra, plus individual toggles.

## 7. Living world

Scaling maps up 4–6× would leave them empty if nothing else were added. This
section exists to make towns and routes feel inhabited and lived-in.

### 7.1 Expanded towns

Original landmarks are preserved and placed first. New buildings fill out the
town around them.

| Town | Red/Blue | Slice target | Additions |
|---|---|---|---|
| Pallet Town | 3 buildings (player's house, rival's house, Oak's Lab) | ~10–12 | Houses, a small farm and orchard, Oak's research greenhouse and outdoor Pokémon pen, a dock/pier on the southern water, a small café/general store |
| Viridian City | ~8 (Pokémon Center, Mart, Gym (closed), Trainer School, houses) | ~25–30 | Residential streets, a market square with stalls, a park, a café, a police box, a bus stop, an apartment block, a flower shop, a workshop, the old man's house |

Routes also gain inhabited spots:

- **Route 1:** a roadside rest stop with a vendor, and a berry farmer's cottage.
- **Route 2:** a gatehouse before the forest, and a campsite.
- **Viridian Forest:** a ranger outpost, and a bug-catcher hideout.

**Enterable interiors:**

- Required: every story building, every shop and the Pokémon Center.
- Plus about 40–50% of homes.

Building every home's interior is the largest content cost in this section, so
the rest are locked with a reason ("No one's home", "Do not disturb"). The
enterable ratio is a tunable content decision.

### 7.2 NPCs

**Population targets for the slice:**

- Pallet Town: 12–15
- Route 1: 6–10
- Viridian City: 35–45
- Route 2 and Viridian Forest: 10–15, including trainers

**NPC types:**

- **Residents:** have a home, a workplace or hangout, and a schedule.
- **Travelers:** walk between towns along routes.
- **Trainers:** stationary, or patrol a set path. They challenge on line of
  sight, as in the main games, and use real-time AI.
- **Workers:** shopkeepers, Nurse Joy and similar. They keep fixed hours.

**Daily schedules:** data-driven blocks per period. Example: "home 20–07,
walk to market 07–08, work at stall 08–17, park 17–19, home".

- NPCs path with Godot's navigation system.
- NPCs in unloaded chunks advance their schedule abstractly (no simulation),
  so they are in the right place when the chunk loads.
- Shops close at night. Streets thin out after 21:00. A few night-owl NPCs
  appear only at night.

**Weather reactions:**

- Rain: umbrellas, NPCs heading indoors or under awnings, market stalls covered.
- Thunderstorms: streets mostly empty.
- Fog: fewer travelers.

**Dialogue:**

- Each NPC has **barks**: short lines when the player passes, which vary by
  time, weather and story progress.
- Main dialogue on interact.
- At least 3 lines per NPC that vary with context. Key NPCs have branching
  dialogue.
- All dialogue lives in `data/dialogue/` so it can grow without code changes.

**Companion Pokémon:**

- About 30% of residents walk with a Pokémon of a species fitting the area
  (Pidgey, Rattata, Meowth, Growlithe, and so on).
- These Pokémon idle, follow their owner and react to the player.
- They cannot be caught or fought.

### 7.3 Ambient life

- Non-combat ambient creatures for atmosphere: Pidgey flocks lifting off when
  approached, Butterfree drifting over the flowers in daytime, glowing
  Volbeat/Illumise near the forest edge at night.
- These are separate from the spawn system's catchable Pokémon.
- Lit windows at night with occasional silhouettes.
- Chimney smoke.
- Laundry lines that move in the wind.
- Audio ambience that varies by period and weather. Placeholder sounds are
  overridable via `user_assets/`.

### 7.4 Performance guardrails

- NPCs farther than 40 m update their logic at reduced rate (4 Hz).
- NPCs farther than 80 m are not simulated (handled by the abstract schedule).
- Sprites use multi-mesh/instancing where possible.
- At most 60 animated NPCs/creatures on screen on "High"; the cap is lower on
  lower presets.

## 8. Progression, party, quests

- **EXP:** Gen 5 level-scaled formula.
- **Growth rates:** six standard curves.
- **Level-up:** learn moves at main-game levels, maximum four known; choose one
  to forget.
- **Evolution:** by level for the slice (cancellable).
- **IV / EV / nature:** IVs 0–31, EVs per Gen 5 rules, 25 natures.
- **Starters:** Bulbasaur, Charmander or Squirtle from Oak. The rival takes the
  type-advantaged one.
- **Slice quest: Oak's Parcel.**
  1. The Viridian Mart clerk gives the parcel.
  2. The player delivers it to Oak.
  3. Oak gives the Pokédex and 5 Poké Balls.
  4. Viridian Mart sells Poké Balls from then on.
- **Rival battle:** one battle at Oak's Lab, using real-time trainer AI.

## 9. Saves, assets, errors

### 9.1 Saves

- Location: `%APPDATA%\Godot\app_userdata\<project>\saves\`.
- JSON format with a `version` field and sequential migration functions.
- Atomic write: write to a temp file, then rename.
- Autosave on area change and when the player saves manually.
- The previous save is kept as `.bak`. On a parse or validation failure, the
  game loads `.bak` and shows a notice.

### 9.2 Asset overrides

- On startup the game reads `user_assets/manifest.json`, which maps keys like
  `species/pidgey`, `tiles/grass_a` or `music/route1` to files.
- If a file is missing or invalid, the game uses the placeholder and writes a
  warning to `user://logs/assets.log`. It never crashes.
- `user_assets/` is listed in `.gitignore`.

### 9.3 Data errors

- `tools/validate_data.gd` runs in CI. It checks schema conformance and
  cross-references (moves, species, spawn zones, dialogue keys, NPC homes).
  A failure blocks the build.
- If a malformed entry reaches runtime anyway, the game logs it and skips that
  entry instead of crashing.

## 10. Testing

**Unit tests (GUT, headless):**

- Damage formula against known Gen 5 calculations.
- Type chart, including dual types.
- Catch formula and shake probability.
- Cooldown mapping.
- Stat and EXP calculations.
- Evolution triggers.
- Spawn table selection by period and weather.
- Weather rolls.
- NPC schedule resolution, including abstract advancement.
- Save round-trip, migration, and corrupt-file fallback.
- Asset override fallback.

**Integration tests (headless):**

- A scripted player walks Pallet → Forest. Asserts: chunks load and unload,
  there are no loading stalls over 100 ms, the spawn count stays within the cap,
  and NPC counts are correct per period.
- A scripted fight and catch.
- The Oak's Parcel quest flow.

**CI:** GitHub Actions on every push. It runs the data validator, then the tests,
then the Windows export, and uploads the build as an artifact.

**Visual quality** (lighting, color, feel) cannot be verified by Claude in the
cloud container, which has no GPU. It is verified by the owner playing each
milestone build.

## 11. Milestones

Each milestone produces a playable Windows build.

1. **World and look:** Pallet Town and Route 1 chunks, the HD-2D camera, Clock,
   Lighting and post-processing.
2. **Streaming and life:** streaming through Viridian Forest, weather,
   spawning, and NPCs with schedules, dialogue and companions.
3. **Combat:** real-time fights, moves, status, wild AI.
4. **Capture and progression:** capture, party, EXP, evolution, Pokémon Center.
5. **Completion:** Save, Oak's Parcel quest, rival battle, settings and
   graphics presets, ambient life polish.

## 12. Out of scope for this slice

- Gyms and badges.
- Story beyond Oak's Parcel.
- Regions other than Kanto.
- Breeding and abilities beyond a stub. Abilities are listed in data but only a
  few are implemented.
- Held items.
- Multiplayer.
- Voice acting.
- Seasons (Gen 5 has them; candidate for a later sub-project).
- A browser build.
- Fully seamless interiors.

## 13. Risks

| Risk | Mitigation |
|---|---|
| Visual tuning without a GPU in the dev environment | Owner feedback per milestone; tunables exposed in a debug menu |
| Content volume: houses, interiors, NPC dialogue | Data-driven authoring; enterable-interior ratio is tunable; reuse interior templates |
| Streaming hitches on Windows | Threaded loading; preload ring; integration test for stall time |
| Godot export in CI | Pin the Godot version and export templates in the workflow |
| Scope creep from later sub-projects | Section 12 is binding for this slice |
