# Research: Open Assets, Reusable Code, Design References, Sprite Tools

Project context: private, non-commercial Pokémon-style fan game, Godot 4.7 / GDScript, HD-2D (48x64 billboard sprites, 3 frames x 4 dirs, 1 m tiles, Forward+, Windows). Repo must contain **no Nintendo / Game Freak / TPC assets**.

Researched 2026-10-28. "Verified" = license read on the asset/repo page or LICENSE file during this research. "Unverified" = not confirmed in this session; check before committing.

License legend for the repo:
- **OK**: CC0, MIT, BSD, Apache-2.0, zlib, CC-BY, OGA-BY (credit required for BY).
- **OK with care**: CC-BY-SA (share-alike: derivatives of that art must stay CC-BY-SA; keep it in a separate, clearly-licensed folder).
- **FLAG**: GPL / AGPL code (copyleft: linking or porting forces your code under it); "all rights reserved"; custom "no redistribution" licenses (a public repo is redistribution).
- **NOT USABLE IN REPO**: anything ripped from or derived from Nintendo games.

---

## Top 10 recommendations

1. **Pokémon Showdown server (MIT)** for Gen 5 data and mechanics reference: port `data/` tables (species, moves, abilities, items, type chart, `data/mods/gen5`) and the damage formula into GDScript resources. Do NOT use the Showdown *client* (AGPL-3.0). https://github.com/smogon/pokemon-showdown
2. **@pkmn/ps (MIT)**: cleaner, modular split of Showdown (`@pkmn/dex`, `@pkmn/data`, `@pkmn/sim`) that is easier to script a one-time JSON export from. https://github.com/pkmn/ps
3. **Ninja Adventure Asset Pack by Pixel-boy & AAA (CC0)**: the best single all-in-one placeholder pack: 16x16 tiles, 50+ 4-direction characters, 30+ monsters, UI, 100+ SFX, 37 music tracks, plus a Godot example. https://pixel-boy.itch.io/ninja-adventure-asset-pack
4. **Kenney CC0 suite**: Tiny Town (16x16 tiles), Nature Kit (3D), UI Pack + UI Pack RPG Expansion. Zero license friction. https://kenney.nl/assets
5. **50+ Monsters Pack 2D by isaiah658 (CC0)**: 56 original monsters with front and back 64x64 sprites. A ready original "dex" for testing capture and combat without Nintendo art. https://opengameart.org/content/50-monsters-pack-2d
6. **Tuxemon Set 1 (CC-BY-SA 4.0)**: 154 original monsters with front, back and menu sprites. Many more in Tuxemon's repo under a CC0/CC-BY/CC-BY-SA mix. Keep these in a separate share-alike folder and credit each monster. Tuxemon *code* is GPL-3.0, so use it only as a design reference. https://opengameart.org/node/86155
7. **Dialogue Manager by Nathan Hoad (MIT)**, or **Dialogic 2 (MIT, Godot 4.5+)**, for NPC dialogue, plus **Questify (MIT)** for graph-based quests. https://github.com/nathanhoad/godot_dialogue_manager, https://github.com/dialogic-godot/dialogic, https://github.com/TheWalruzz/godot-questify
8. **Godot Shaders tilt-shift (CC0 minimal / depth-based)** plus **SimpleGrassTextured (MIT)** for the HD-2D look. https://godotshaders.com/shader/tilt-shift-shader-minimal/, https://godotshaders.com/shader/depth-based-tilt-shift/, https://github.com/IcterusGames/SimpleGrassTextured
9. **Juhani Junkala JRPG music packs (CC0)** plus **G&T RPG Soundtrack (CC-BY 4.0)** for town, route and battle loops. Pair them with **CC0 Freesound ambience** found through the license filter. https://opengameart.org/content/jrpg-pack-1-exploration
10. **Design priorities from Legends: Arceus and Scarlet/Violet**: alpha/size variants, mass outbreaks, research tasks, overworld-visible spawns with behavior (shy/aggressive), rideable partners, and time and weather exclusive spawns. These map directly onto the existing respawn, day/night, weather and quest systems.

Tool pick for converting the owner's own sheets: **Aseprite CLI** (paid, source-available EULA), or the free route of **ImageMagick + Pillow scripts**, with **Pixelorama (MIT)** as a free GUI. Import into Godot with **Aseprite Wizard (MIT)**.

---

## 1. Openly licensed ASSETS

All of the following are **original art** (not derived from Nintendo) unless noted.

### 1a. Top-down tilesets (2D, usable as textures on 3D tile meshes / GridMap)

HD-2D tip: 16x16 tiles can be upscaled with nearest-neighbour onto 1 m box/slab meshes in a `MeshLibrary` for `GridMap`. Use 3D kits (1b) for props and trees, so the scene can mix flat pixel ground with low-poly or billboard foliage.

| Asset | Author | License | URL | Fit |
|---|---|---|---|---|
| Ninja Adventure Asset Pack | Pixel-boy & AAA | **CC0** (verified) | https://pixel-boy.itch.io/ninja-adventure-asset-pack | 16x16 exterior/interior autotiles, very cohesive, bright palette close to GBA-era Kanto. Best all-rounder. |
| Tiny Town | Kenney | **CC0** (verified) | https://kenney.nl/assets/tiny-town | 16x16, 130 files: houses, fences, trees. Clean and readable but simpler than Pokémon. Good for Pallet/Viridian blockouts. |
| 16x16 Puny World Tileset | Shade | **CC0** (verified) | https://opengameart.org/content/16x16-puny-world-tileset | Grass, trees, elevation, paths, rivers, sea (some animated), buildings. Closest to a classic overworld route feel. |
| 16x16 Overworld Tiles | ARoachIFoundOnMyPillow | CC0 (per search listing; unverified on page) | https://opengameart.org/content/16x16-overworld-tiles-0 | Small set; filler only. |
| Zelda-like tilesets and sprites | ArMM1998 | CC0 (unverified this session) | https://opengameart.org/content/zelda-like-tilesets-and-sprites | Classic top-down overworld, caves, interiors. Good Kanto-like vibe. |
| Overworld RPG tileset | Tayoko | GPL / CC-BY-SA (per listing) | https://opengameart.org/content/overworld-rpg-tileset | **OK with care** (choose the CC-BY-SA option; never treat it as GPL code). |
| 16x16 RPG Tileset | hilau | License field blank: **unverified** | https://opengameart.org/node/126285 | Avoid until clarified. |
| LPC terrain/tiles (Liberated Pixel Cup) | various | CC-BY-SA 3.0 / GPL 3.0 dual (typical; check per file) | https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles | 32x32, more "western RPG"; matches LPC characters. OK with care (CC-BY-SA). |

### 1b. 3D tile kits / props

| Asset | Author | License | URL | Fit |
|---|---|---|---|---|
| Nature Kit | Kenney | **CC0** (verified) | https://kenney.nl/assets/nature-kit | 330 files: low-poly trees, rocks, foliage, cliffs. Great for HD-2D props around billboards. |
| City Kit (Suburban) / Fantasy Town Kit / Retro Urban Kit | Kenney | CC0 (Kenney site-wide policy; not individually checked) | https://kenney.nl/assets | Houses and fences for towns; the suburban kit is very Pallet-like. |
| KayKit Forest Nature Pack | Kay Lousberg | **CC0** (verified; free tier 100+ models, paid tiers add more) | https://kaylousberg.itch.io/kaykit-forest | Gradient-atlas low-poly; one material, cheap to render. Fits a stylized HD-2D world. |
| Other KayKit packs (Medieval Hexagon, City Builder Bits, Resource Bits, etc.) | Kay Lousberg | Mostly CC0 (license not shown on index page: **verify per pack**) | https://kaylousberg.itch.io/ | Props for towns and resource nodes (crafting). |
| Stylized Nature MegaKit | Quaternius | **CC0** (verified on pack page) | https://quaternius.com/packs/stylizednaturemegakit.html | "Ghibli" style foliage; excellent for Viridian Forest. |
| Other Quaternius packs | Quaternius | **FLAG**: the site now has a "Quaternius Asset License v1.0" (no redistribution as standalone assets). Older packs are CC0. **Check each pack page.** | https://quaternius.com/license.html | Public repo = redistribution; only commit packs whose page says CC0. |
| Ultimate Monsters / Cute Animated Monsters (3D) | Quaternius | Per-pack (see above) | https://quaternius.com/ | Could be pre-rendered into billboard sprite sheets for placeholder creatures. |

### 1c. Original monster / creature sprites

| Asset | Author | License | URL | Fit |
|---|---|---|---|---|
| 50+ Monsters Pack 2D | isaiah658 | **CC0** (verified) | https://opengameart.org/content/50-monsters-pack-2d | 56 monsters, 64x64 front and back. Ideal test dex. Needs overworld (walking) frames drawn or faked with squash/bob. |
| Tuxemon Set 1 (154 monsters) | Tuxemon contributors | **CC-BY-SA 4.0** (verified), per-monster attribution required | https://opengameart.org/node/86155 | 64x64 front/back + 24x24 menu icons. Most "monster-tamer" in style. OK with care. |
| Tuxemon repo assets (393 monsters, 208 NPC sprites) | many | Mixed per file (ATTRIBUTIONS.md: about 165 CC-BY-SA, about 100 CC0, about 80 CC-BY 3.0/4.0, a few GPLv3) (verified) | https://github.com/Tuxemon/Tuxemon/blob/development/ATTRIBUTIONS.md | Pick files individually from ATTRIBUTIONS.md. **Tuxemon code is GPL-3.0: do not copy code.** |
| RPG Monster Sprites from Guardian Monsters | Gem (Georg Eckert) | **CC-BY 4.0** (verified); the author's full packages are CC-BY-SA, with some GPL3/OGA parts | https://opengameart.org/content/rpg-monster-sprites-from-guardian-monsters | Small set; condition: keep the provided monster names. |
| Ninja Adventure monsters (30+) and bosses (9) | Pixel-boy & AAA | **CC0** | (pack above) | Top-down animated, so they work directly as overworld wild-spawn sprites. |
| Shibu Front Sprites (Openmon) | screensmith | **Unverified** | https://screensmith.itch.io/shibu-front-sprites-openmon-monster | Check the itch license field. |
| LPC in-battle RPG sprites | Redshrike | CC-BY-SA 3.0 / GPL 3.0 | https://opengameart.org (search "LPC in battle RPG sprites") | OK with care. |

Not usable (reference only): PokeAPI/sprites, Smogon sprites, Spriters Resource rips, Infinite Fusion custom fusions (derived from official designs).

### 1d. Overworld character sheets (4-direction walk)

Target is 48x64, 3 frames x 4 directions (RPG Maker VX layout). Most open sets are 16x16, 32x32 or 64x64 and need rescaling or re-layout (see section 4).

| Asset | Author | License | URL | Fit |
|---|---|---|---|---|
| Universal LPC Spritesheet Generator | LPC contributors | Art: per-asset CC0 / CC-BY / CC-BY-SA / OGA-BY / GPL listed in `CREDITS.csv`; generator code **GPL-3.0** (verified) | https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator (web: https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/) | 64x64 frames, 4-direction walk (9 frames). Huge variety of trainers and NPCs. Export only CC0/CC-BY/OGA-BY layers to avoid share-alike; credits screen required. Using the generator does not put your game under GPL. |
| Ninja Adventure characters | Pixel-boy & AAA | **CC0** | (pack above) | 50+ characters, 4-way, with facesets for dialogue. Small (16x16), so upscale. |
| Puny Characters | Shade | **CC0** (verified) | https://opengameart.org/content/puny-characters | 8-direction; idle/walk/attack/throw/hurt/death; 32x32 canvas. "Throw" suits ball throwing. |
| Antifarea's RPG sprite set 1 | Antifarea | **CC-BY 3.0** (credit must link to OGA) | https://opengameart.org/content/antifareas-rpg-sprite-set-1-enlarged-w-transparent-background | Classic 3-frame, 4-direction, closest to the GBA trainer layout. |
| Twelve 16x18 RPG character sprites | Antifarea | CC-BY 3.0 | https://opengameart.org/node/3393 | NPCs, same style. |
| Simple 32x48 base sprite | BlazingMagpie | CC0 (per listing) | https://opengameart.org (in "3 Frame Walk Cycles" collection) | 3-frame layout at 32x48, the right aspect for 48x64 if scaled 1.5x or redrawn. |
| Human RPG Character | Shepardskin | CC0 (per listing) | https://opengameart.org/content/human-rpg-character | 4-direction walk plus blinking faceset. |

### 1e. UI kits / fonts

| Asset | Author | License | URL | Fit |
|---|---|---|---|---|
| UI Pack | Kenney | CC0 | https://kenney.nl/assets/ui-pack | Buttons, panels, sliders. |
| UI Pack RPG Expansion | Kenney | **CC0** (verified, 85 files) | https://kenney.nl/assets/ui-pack-rpg-expansion | Parchment/metal frames and bars. Good for HP and cooldown bars. |
| Ninja Adventure UI + 2 fonts | Pixel-boy & AAA | CC0 | (pack above) | Pixel dialogue boxes that match the tiles. |
| Kenney Fonts | Kenney | CC0 | https://kenney.nl/assets/kenney-fonts | Pixel fonts. |
| m5x7 / m6x11 fonts | Daniel Linssen | "free to use, credit appreciated": **unverified formal license** | https://managore.itch.io/m5x7 | Popular, readable pixel fonts. |

### 1f. Ambient SFX

Freesound search URLs with the CC0 filter applied (results checked 2026-10-28; still open each sound page to confirm the license before committing):

- Rain loops (CC0 filter): https://freesound.org/search/?q=rain+loop&f=license%3A%22Creative+Commons+0%22&s=num_downloads+desc
  - "Slowly Raining Loop", unfa: https://freesound.org/people/unfa/sounds/177479/
  - "Rain from Indoors - Perfect loop", samesamesame: https://freesound.org/people/samesamesame/sounds/242889/
  - "Rain Slowly Passing TREATED LOOP", speakwithanimals: https://freesound.org/people/speakwithanimals/sounds/525046/
  - "rain_thunder_loop.flac", Nimlos: https://freesound.org/people/Nimlos/sounds/423610/
- Thunder (CC0 filter): https://freesound.org/search/?q=thunder&f=license%3A%22Creative+Commons+0%22
  - "Rolling_Distant_Thunder_In_Heavy_Rain_06", BlondPanda: https://freesound.org/people/BlondPanda/sounds/778374/
  - "Short_Thunder_Mid.wav", SholeColtis: https://freesound.org/people/SholeColtis/sounds/683421/
  - "high thunder suburb 08.wav", klankbeeld: https://freesound.org/people/klankbeeld/sounds/169534/ (klankbeeld often uses CC-BY; confirm)
- Crickets / night (CC0 filter):
  - "Crickets At Night - Raw sound", Defelozedd94: https://freesound.org/people/Defelozedd94/sounds/522299/
  - "Crickets during the night, close to the beach in Mexico", felix.blume: https://freesound.org/people/felix.blume/sounds/479041/
- Birds / forest day (CC0 filter):
  - "Forest Day - Bird Chirps, Insects", RealSquink: https://freesound.org/people/RealSquink/sounds/788118/
  - "crickets and birds country morning rural farm field2", kyles: https://freesound.org/people/kyles/sounds/452188/ (kyles publishes many CC0 field recordings, a good source for dawn and dusk transitions)
- Wind (CC0 filter):
  - "Wind through trees (loop)", NomadApe: https://freesound.org/people/NomadApe/sounds/444921/
  - "loop smooth muffled rushing air tone ... wind trees forest", kyles: https://freesound.org/people/kyles/sounds/454072/
- Game SFX: Kenney audio packs (RPG Audio, Interface Sounds, Impact Sounds): **CC0**: https://kenney.nl/assets?q=audio. Ninja Adventure includes 100+ CC0 SFX.
- Avoid or flag: Mixkit (custom Mixkit License, not CC); Sonniss GDC bundles (royalty-free, but raw-file redistribution in a public repo is not allowed: keep them local if used); Freesound CC-BY-NC (non-commercial is fine for you, but it is not on your allowed list and complicates forks).

### 1g. Music loops

| Asset | Author | License | URL | Fit |
|---|---|---|---|---|
| JRPG Pack 1: Exploration | Juhani Junkala (SubspaceAudio) | **CC0** (verified) | https://opengameart.org/content/jrpg-pack-1-exploration | Grasslands, Prairie Nights and more: route and forest themes. Prairie Nights suits a night variant. |
| JRPG Pack 2: Towns | Juhani Junkala | **CC0** (verified) | https://opengameart.org/content/jrpg-pack-2-towns | Home Town, Where Time Stands Still, Sunshine Coast, Bazaar. "Home Town" is a natural fit for Pallet. |
| JRPG Pack 4: Calm (mentioned in comments) | Juhani Junkala | CC0 likely: **unverified** | search OGA "JRPG Pack 4" | Pokémon Center / rest music. |
| 5 Chiptunes (Action) | Juhani Junkala | CC0 (per listing) | https://opengameart.org/content/5-chiptunes-action | Wild-battle loops. |
| G&T RPG Soundtrack (37 tracks) | Juhani Junkala | **CC-BY 4.0 / OGA-BY 3.0** (verified) | https://opengameart.org/content/gt-rpg-soundtrack | Hymn Overworld, battles, victory fanfare, caves, towns. A full soundtrack; credit required. |
| Ninja Adventure music (37 tracks) | Pixel-boy & AAA | CC0 | (pack above) | Chiptune-ish; coherent with the tileset. |
| Chiptune inspired music pack | Technodono | CC-BY-SA 4.0 | https://opengameart.org/content/chiptune-inspired-music-pack | "Super overworld" track. OK with care. |
| Fantasy RPG Orchestra (11 loops) | Aleksis Tristan Shaw | CC-BY 4.0 (paid, $5 min) | https://aleksis-tristan-shaw.itch.io/fantasy-rpg-orchestra | Orchestral HD-2D feel ("Provincial Village"). |
| Adventure RPG Essentials Music Pack | Chris Kohler | "no credit needed", **no formal license: unverified** | https://chriskohler.itch.io/adventure-rpg-essentials-music-pack | Ask the author for CC0 before committing. |
| Fight & Town RPG Soundtrack Pack 2 | nickr02 | Free, credit required, **no formal license: unverified** | https://nickr02.itch.io/fight-town-rpg-soundtrack-pack-2 | Same caveat. |
| Kevin MacLeod / incompetech | Kevin MacLeod | CC-BY 4.0 (well known; not rechecked) | https://incompetech.com/music/ | Large orchestral and ambient library. |

---

## 2. Permissively licensed CODE / DATA

| Project | License | URL | Reusable | Godot 4.x |
|---|---|---|---|---|
| Pokémon Showdown (server/sim) | **MIT** (verified) | https://github.com/smogon/pokemon-showdown | `data/pokedex.ts`, `moves.ts`, `abilities.ts`, `items.ts`, `typechart.ts`, `learnsets.ts`, `data/mods/gen5/*` (Gen 5 overrides); `sim/battle-actions.ts` (damage calc, modifiers, chain order); condition/ability event hooks as a model for a GDScript signal/event bus. Its AI is random/simple; no strong AI to port. | TypeScript: write a one-time Node export script to JSON, then load as Godot `Resource`s. |
| Pokémon Showdown client | **AGPL-3.0: FLAG** (verified) | https://github.com/smogon/pokemon-showdown-client | Nothing. Do not copy UI code or sprite-index logic. Its sprite CDN is Nintendo-derived. | n/a |
| @pkmn/ps (dex, data, sim, sets) | **MIT** (verified) | https://github.com/pkmn/ps | Same data as Showdown, packaged as npm modules; `@pkmn/data` has per-generation views (`gens.get(5)`), the easiest way to export clean Gen 5 JSON. | Export to JSON. |
| @pkmn/engine | **MIT** (verified) | https://github.com/pkmn/engine | Zig, Gen 1-2 focus; reference for RNG-exact mechanics. Low relevance for Gen 5. | Reference only. |
| Smogon damage-calc | **MIT** (verified) | https://github.com/smogon/damage-calc | Clean Gen 5 damage formula (`calc/src/mechanics/gen56.ts`) with modifier order. Easier to port than the sim. Adapt for aim/crit-zone and real-time multipliers. | Port to GDScript. |
| PokeAPI (code) | **BSD-3-Clause** (verified) | https://github.com/PokeAPI/pokeapi | `data/v2/csv/*`: species, stats, moves, encounter tables (Kanto routes per version), evolution chains, flavor text. Encounter CSVs are useful to seed Kanto spawn tables. | CSV import. Note: the repo has *sprites* and *cries* submodules that are Nintendo assets: **do not vendor them.** |
| PokeAPI/sprites | Nintendo-derived: **NOT USABLE** | https://github.com/PokeAPI/sprites | Owner's local loader could point at it; never commit. | |
| veekun/pokedex | **MIT** (verified) | https://github.com/veekun/pokedex | Older CSV dex data (same lineage as PokeAPI); good for Gen 5 encounter slots and version-exclusive data. | CSV. |
| poke-env | **MIT** (verified) | https://github.com/hsahovic/poke-env | Python RL/heuristic battle agents against Showdown; ideas for AI heuristics (switch scoring, move scoring). | Ideas only. |
| Pokémon Essentials | Repo LICENSE says MIT (verified), **but the kit ships Nintendo graphics/audio: FLAG** | https://github.com/pokemon-essentials/pokemon-essentials | Ruby (RPG Maker XP) logic for encounters, daycare, roaming, PBS data formats. Read as reference; do not copy assets. | Reference. |
| Tuxemon (code) | **GPL-3.0: FLAG** (verified) | https://github.com/Tuxemon/Tuxemon | Design reference only (Python/pygame). | n/a |
| Monstercollector 2.5D demo | MIT (verified LICENSE) | https://github.com/whomera/Monstercollector2.5D.demoGodot2 | Godot 4.3, 2.5D monster-collector demo. **Assets inside not audited: check for ripped sprites before copying anything.** | 4.3 to 4.7 should be fine. |
| Godot Open RPG (GDQuest) | **MIT** (verified) | https://github.com/gdquest-demos/godot-open-rpg | Turn-based JRPG framework: field/combat split, cutscene and dialogue patterns, inventory. | Godot 4 version exists. |
| Dialogic 2 | **MIT** (verified); requires **Godot 4.5+** | https://github.com/dialogic-godot/dialogic | Visual timeline editor, characters, portraits, variables, text effects. Heavier. | Yes (4.5+). |
| Dialogue Manager | **MIT** (verified) | https://github.com/nathanhoad/godot_dialogue_manager | Script-like `.dialogue` files, conditions, mutations calling GDScript. Lightweight, good for many NPCs and schedules. Recommended. | Yes. |
| Questify | **MIT** (verified) | https://github.com/TheWalruzz/godot-questify | Graph-based quest editor (objectives, conditions, branches) and manager with serialization. | Listed 4.1+, v1.6.x. Verify on 4.7. |
| Quest System (shomy) | MIT (per Asset Library) | https://godotengine.org/asset-library/asset/2516 | Minimal code-first quest framework. | 4.0+. |
| Beehave (behavior trees) | **MIT** (verified) | https://github.com/bitbrain/beehave | Wild Pokémon AI (flee, wander, aggro, alpha behaviors). | Yes. |
| LimboAI (BT + HSM) | **MIT** (verified) | https://github.com/limbonaut/limboai | Faster C++ GDExtension BT/state machine for many concurrent wild spawns. | Yes (check 4.7 build). |
| Godot State Charts | **MIT** (verified) | https://github.com/derkork/godot-statecharts | Statecharts for combat states and player/partner control modes. | Yes. |
| Phantom Camera | **MIT** (verified) | https://github.com/ramokz/phantom-camera | HD-2D camera follow, framing, smooth zone transitions, lock-on during action combat. | Yes. |
| Open World Database | **MIT** (verified) | https://github.com/DigitallyTailored/Godot-Open-World-Database | Chunk streaming and persistence; under active development (warns about node deletion on load/unload). Compare with your existing streamer. | 4.4+. |
| Terrain3D | **MIT** (verified) | https://github.com/TokisanGames/Terrain3D | Only if you move from tiles to sculpted terrain for later regions. Mostly not needed. | Yes (GDExtension). |
| Zylann HeightMap plugin | **MIT** (verified) | https://github.com/Zylann/godot_heightmap_plugin | Alternative terrain; reference for chunked LOD. | Yes. |
| SimpleGrassTextured | **MIT** (verified) | https://github.com/IcterusGames/SimpleGrassTextured | MultiMesh grass with wind and player interaction. Perfect for tall-grass encounter patches (visible rustle). | Yes. |
| Spatial Gardener | **Unverified** (believed MIT) | https://github.com/HungryProton/spatial_gardener | Paint foliage instances on surfaces. | Yes. |
| Waterways | **MIT** (verified) | https://github.com/Arnklit/Waterways | River mesh and flow-map shader. Built for Godot 3; **Godot 4 compatibility unverified**. | Check. |
| Godot Shaders: Tilt-Shift (minimal) | **CC0** (per listing) | https://godotshaders.com/shader/tilt-shift-shader-minimal/ | Screen-space top/bottom blur: the classic HD-2D miniature look. | Godot 4. |
| Godot Shaders: Depth-based Tilt-shift | per-post (site allows CC0 / MIT / GPL-3: **check the post's badge**) | https://godotshaders.com/shader/depth-based-tilt-shift/ | Depth-aware focus band; better for an angled camera. | 4.3+. |
| Godot Shaders: billboard tag | per-post (CC0 / MIT / **GPL-3**: check each) | https://godotshaders.com/shader-tag/billboard | Multi-directional billboard, Sprite3D sway, hit flash, normal-mapped Sprite3D (lets sprites take dynamic day/night light). | Godot 4. |
| Godot-AdvancedBillboard | **MIT** (verified) | https://github.com/NovaDC/Godot-AdvancedBillboard | Y-axis billboarding helpers. | 4.2+. |
| Godot demo projects | **MIT** (verified) | https://github.com/godotengine/godot-demo-projects | 3D platformer/navigation, threads, loading demos (background scene loading for chunks). | Yes. |
| Maaack Godot Game Template | **MIT** (verified) | https://github.com/Maaack/Godot-Game-Template | Menus, options, save slots, loading screens. | Yes. |
| Aseprite Wizard (import) | **MIT** (verified) | https://github.com/viniciusgerevini/godot-aseprite-wizard | Imports .aseprite/.json into SpriteFrames/AnimationPlayer automatically. | Godot 4 branch. |

Notes:
- Only **mechanics data** (numbers, formulas) is extracted from Showdown/PokeAPI. Species names, move names and dex text are TPC trademarks or copyright regardless of the code license. Fine in a private, non-commercial fan repo in practice, but keep any *flavor text* (copyrighted prose) out of the repo and load it locally like the sprites.
- Real-time adaptation: map Showdown's `basePower x STAB x type x random(85-100)` pipeline as is, replace accuracy rolls with hitbox tests, and turn PP into cooldown = f(PP), for example `cooldown_s = clamp(40 / PP, 0.6, 8)`.

---

## 3. Design references (features to adopt)

| Feature | Best example | How it fits this project |
|---|---|---|
| Alpha / oversized Pokémon | Legends: Arceus (alphas); S/V (size variants, mark titles) | Spawner rolls a rare "alpha" flag: scale billboard 1.5-2x, red eyes/glow shader, boosted stats, guaranteed egg move. Aggressive BT branch. |
| Mass outbreaks | Legends: Arceus (massive/mass outbreaks), S/V (map-marked outbreaks with shiny boost) | Daily seeded event per region chunk: one species replaces the spawn table for N kills/captures; show on the town map. |
| Visible, behavior-driven overworld spawns | Legends: Arceus, S/V, Let's Go | Already have visible spawns; add per-species temperament (skittish/curious/aggressive/territorial) through Beehave. Sneak (crouch, tall grass) for back-strike bonuses. |
| Research tasks / dex levels | Legends: Arceus | Per-species task list (catch X, see move Y, defeat with type Z, feed) feeding dex completion. Fits the existing quest system. |
| Back-strike / stealth capture | Legends: Arceus | Ball throw from behind an unaware Pokémon gives a capture bonus. Pairs with aim-based capture. |
| Feeding / lures / baits | Legends: Arceus (berries, smoke balls), Palworld | Throwable items that pull or distract spawns; consumes crafting materials. |
| Crafting | Legends: Arceus (kit crafting), Palworld (base crafting), Temtem | Gather nodes (Apricorns, berries, ore) to craft balls and potions at camp/bench. Add resource props from KayKit/Quaternius. |
| Camps / picnics | Sword/Shield camps, S/V picnics | Place a camp anywhere: save, heal, cook stat-buff meals, bond with team. Good save-point design for open world. |
| Ride Pokémon / mounts | Legends: Arceus (ride Wyrdeer/Basculegion/Braviary), S/V (Koraidon/Miraidon), Palworld | Mount = swap player controller to a partner's speed/jump/swim profile. Gate traversal (surf, climb, glide) in place of HMs. |
| Partner overworld abilities (field moves) | Palworld (pals do work), Cassette Beasts (overworld abilities: glide, climb, magnetism), Coromon (gauntlet modules) | Lead Pokémon gives a contextual field action (Cut a tree, Rock Smash, Flash in caves) without HM slots. |
| Followers | HGSS, Pokémon Clover/Prism (fan), Let's Go, S/V (let's go auto-battle) | Lead Pokémon follows as a 48x64 billboard; S/V "Let's Go" auto-battle of weak wilds fits real-time combat. |
| Day/night and weather exclusive encounters | HGSS, Legends: Arceus, S/V, Temtem (time/weather spawns) | Spawn tables keyed by time band x weather; already have both systems. Show "habitat hints" in the dex. |
| Dynamic events / space-time distortions | Legends: Arceus (distortions), Palworld (raids on base) | Random timed zone event (storm, meteor, legendary sighting) with rare spawns and loot, driven by the weather system. |
| Raids / co-op dens | S/V Tera Raids, SwSh Max Raids, Temtem dojo battles | Single-player variant: boss Pokémon with shields/phases and NPC allies; real-time combat suits this well. |
| Dungeons | Monster Sanctuary (metroidvania areas), Cassette Beasts, Mystery Dungeon | Procedural or handmade caves (Mt. Moon, Rock Tunnel) with puzzles that need partner field moves. |
| Fusions | Infinite Fusion; Cassette Beasts (fusion of any two forms) | Scope creep: skip, or limit to a cosmetic fusion shader. Infinite Fusion art is derived from official designs. |
| Difficulty / level caps / nuzlocke options | Reborn, Insurgence, Clover, Radical Red | Optional level cap per badge, randomizer, nuzlocke toggle in settings. Cheap to add. |
| Delta / regional variants | Insurgence (Delta species), Uranium (Nuclear type), S/V/Legends regional forms | Lets you add *original* regional forms with your own CC0 art without touching Nintendo designs. |
| Post-game across regions | HGSS (Kanto+Johto), Prism, Reborn | Region-as-chunkset architecture already supports cross-region travel by boat/train. |
| Tamer combat with skill trees / synergy | Temtem (synergy), Monster Sanctuary (skill trees, shift), Cassette Beasts (chemistry) | Optional depth: type-pair combo bonuses during real-time tag-team switching. |
| Overworld puzzles and secrets | Coromon, Cassette Beasts | Collectible hidden items, light puzzles in each route, Viridian Forest bug-catcher hide and seek. |
| Base building / jobs for monsters | Palworld | Lightweight: a ranch where boxed Pokémon passively gather crafting mats. Ties to daycare. |
| Online / trade | Temtem MMO | Out of scope; leave save format versioned for later. |

---

## 4. Tools for converting the owner's own extracted sheets

(No rippers. These only slice, re-layout, recolor or batch-convert images the owner already has.)

| Tool | License | Platform | Use |
|---|---|---|---|
| Aseprite | Source-available EULA, paid (~$20) (not OSI open source; build-from-source allowed for personal use) | Win/Mac/Linux | Best pixel workflow. CLI: `aseprite -b in.png --sheet-type rows --sheet out.png --data out.json`, `--split-layers`, scale `--scale 3`. Import sheets by grid. |
| LibreSprite | **GPL-2.0** (verified; tool use is fine, it does not touch your code license) | Win/Mac/Linux | Free fork of old Aseprite; slicing and re-export. |
| Pixelorama | **MIT** (verified) | Win/Mac/Linux/Web (made in Godot) | Free GUI: import spritesheet by grid, palette tools, export sheets/frames. |
| ImageMagick | ImageMagick License (Apache-2.0-style) | All | Batch: `magick sheet.png -crop 48x64 +repage frame_%02d.png`; re-tile `magick montage frame_*.png -tile 3x4 -geometry +0+0 -background none out.png`; nearest-neighbor scale `-filter point -resize 300%`; palette remap `-remap palette.png +dither`. |
| Python + Pillow | MIT-CMU (HPND) | All | Scripted slicer: detect grid, center-pad each frame to 48x64 with feet on a baseline, write a 144x256 sheet (3x4). Best for batch-normalizing hundreds of species. |
| Free Texture Packer | **MIT** (verified) | Win/Mac/Linux/Web | Pack frames into atlases with JSON. Godot atlas import. |
| TexturePacker | Commercial | All | Same, more polish; not required. |
| GIMP | GPL-3.0 | All | Manual edits; "Guillotine" slicing; indexed palette mode. |
| Lospec Palette List | Free palettes (each palette's own terms) | Web | Pick one master palette for consistent HD-2D color grading: https://lospec.com/palette-list |
| Godot built-in | MIT | Editor | SpriteFrames "Add frames from sprite sheet" (grid 3x4); `Image` API in an `@tool` script to batch-convert locally loaded owner assets at import time (keeps the repo clean: the script ships, the assets do not). |
| Aseprite Wizard | **MIT** (verified) | Godot plugin | Auto-import .aseprite to SpriteFrames/AnimationPlayer with tags. |
| Tiled | GPL-2.0 app (maps you author are yours) | All | Re-layout owner tilesets, export TSX/TMX/JSON. |
| LDtk | **MIT** (verified) | Win/Mac/Linux | Level and tileset editor with auto-layers; Godot importers exist (check each importer's license). |

Suggested normalizer pipeline (all local, nothing committed): `owner_assets/` (gitignored) to a Python/Pillow script (open source in repo) that writes 48x64 frames, 3x4 layout, palette-quantized, with feet on y=60, then to `user://` or a gitignored `res://local_assets/`. The game loads through a path resolver that falls back to CC0 placeholder art (e.g. isaiah658 monsters, Ninja Adventure trainers) when local assets are absent.

---

## Licensing summary / red flags

- **AGPL-3.0**: Pokémon Showdown *client*. Avoid.
- **GPL-3.0**: Tuxemon code, LPC generator code, some LPC/Tuxemon art (pick the CC alternative where dual-licensed), some godotshaders.com posts (check each badge).
- **Custom / no-redistribution**: newer Quaternius packs (Quaternius Asset License), Sonniss GDC bundles, Mixkit. Keep local or skip.
- **No formal license**: Chris Kohler and nickr02 music packs, m5x7 fonts, hilau tileset. Unverified; ask the author or avoid.
- **Nintendo-derived (never commit)**: PokeAPI/sprites and cries, Showdown/Smogon sprite sets, Spriters Resource rips, Pokémon Essentials bundled graphics, Infinite Fusion sprites, fan "gen 3 style" tilesets that trace official tiles.
- **Share-alike (CC-BY-SA)**: Tuxemon Set 1, LPC art, Technodono music. Allowed, but keep in `assets/cc-by-sa/` with a CREDITS file; modified versions must stay CC-BY-SA.
- Keep a `CREDITS.md` / in-game credits screen listing every CC-BY / OGA-BY / CC-BY-SA asset with author, URL and license.
