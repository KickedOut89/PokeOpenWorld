# Kanto Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable HD-2D open-world slice, Pallet Town through Viridian
Forest. It covers streaming, day/night, weather, a living world of NPCs,
visible respawning wild Pokémon, real-time combat, capture, progression, saving
and one quest, delivered as a Windows build from CI.

**Architecture:**
- Godot 4 project, Forward+ renderer.
- Game rules are **pure `RefCounted` classes** (`class_name`, statically typed)
  that are unit-tested headless with GUT. Nodes and autoloads are thin adapters
  that feed those classes and apply their results.
- All content lives in `data/` as JSON, loaded by `DataDB` and checked by
  `DataValidator`.
- Systems talk through the `EventBus` autoload.

**Tech Stack:**
- Godot **4.7.2-stable**, GDScript with static typing.
- GUT **9.6.1**, vendored in `addons/gut/`.
- GitHub Actions on `ubuntu-latest` to build the Windows export.

**Spec:** `docs/superpowers/specs/2026-10-28-kanto-vertical-slice-design.md`.
Read it before any task; section numbers below (§) refer to it.

## Global Constraints

- **Engine and tools:**
  - Godot `4.7.2-stable`, pinned in `tools/godot_version.txt`.
  - All scripts statically typed (`var x: int`, typed returns).
  - No C#, no GDExtension.
- **Renderer and target:**
  - `rendering/renderer/rendering_method="forward_plus"`.
  - The export target is preset name `"Windows Desktop"`, x86_64.
- **Assets:**
  - No Nintendo/Game Freak/TPC assets in the repo.
  - `user_assets/` is git-ignored.
  - Placeholders live in `assets/placeholder/`.
- **Mechanics:**
  - Gen 5 formulas (§5.3) with the exact constants given in each task.
  - 17 types: Gen 5 has **no Fairy**, and Steel resists Ghost and Dark.
- **Scale:**
  - 1 tile = 1 m. Chunk = 64×64 m.
  - Authoring cell = 4×4 m, so 16×16 cells per chunk.
- **Time:**
  - Default speed is 1 real hour = 1 game day, so 24 game-seconds per real
    second.
  - Periods are morning [4,10), day [10,17), evening [17,20), night [20,4).
- **Commits:**
  - Conventional prefix (`feat:`, `test:`, `chore:`, `content:`).
  - Every commit ends with the session's Co-Authored-By/Claude-Session trailer
    lines.
- **Tests:**
  - One test file per pure class, `tests/unit/test_<snake_name>.gd`.
  - Integration tests in `tests/integration/`.
- **Test commands:**
  - Run one test file:
    `tools/test.sh res://tests/unit/test_x.gd`
  - Run the whole suite:
    `tools/test.sh`
  - `tools/test.sh` wraps
    `godot --headless --path . -s addons/gut/gut_cmdln.gd -ginclude_subdirs -gexit`
    with `-gdir=res://tests` (default) or `-gtest=<file>`. It exits non-zero
    on any failure.
- **Randomness:** all randomness goes through an injected
  `RandomNumberGenerator` so tests can seed it.

## Review Focus

1. **Player crosses a chunk edge mid-fight.** Chunks overlapping an active
   fight ring must stay loaded until the fight ends. Owned by Task 10
   (`test_pinned_chunks_never_unloaded`) and Task 23.
2. **Time wraps past midnight.**
   - Night covers [20,4).
   - A schedule block written `20–07` must match at 23:00 and 03:00.
   - The real-clock mode must also work across midnight.

   Owned by Task 3 (`test_night_wraps_midnight`) and Task 16
   (`test_block_wrapping_midnight`).
3. **Saving or loading in awkward states.**
   - Saving during a fight is refused.
   - Saving inside an interior must restore the player inside it.
   - Saving during a weather transition must restore the target weather.

   Owned by Task 28 (`test_save_refused_in_fight`,
   `test_interior_position_round_trip`, `test_weather_mid_transition`).
4. **Spawning finds no valid point or no valid entry.**
   - No valid point: every candidate is in view or too close.
   - No valid entry: the zone has nothing for this period and weather.
   - Both must skip quietly and retry next tick, never crash or loop forever.

   Owned by Task 14 (`test_no_valid_point_skips`,
   `test_empty_table_for_period`).
5. **Full party or a fifth move.**
   - Catching with 6 in the party sends the catch to PC box 1, and the
     player is told.
   - Learning a fifth move prompts the player to forget one; declining keeps
     the old four.

   Owned by Task 27 (`test_catch_with_full_party_goes_to_box`,
   `test_fifth_move_decline_keeps_four`).

---

## Milestone 0: Foundation

### Task 1: Project scaffold, test runner and CI

**Files:**
- Create: `project.godot`, `.gitignore`, `.gitattributes`
- Create: `export_presets.cfg`, `tools/godot_version.txt`,
  `tools/install_godot.sh`, `tools/test.sh`
- Create: `addons/gut/**` (GUT 9.6.1, vendored)
- Create: `scenes/main.tscn`, `src/main.gd`
- Create: `tests/unit/test_smoke.gd`
- Create: `.github/workflows/build.yml`, `README.md`

**Interfaces:**
- Produces:
  - `tools/test.sh [res://path]`
  - `tools/install_godot.sh` installs Godot 4.7.2 and the export templates
    to `$HOME/.local/bin/godot` and
    `~/.local/share/godot/export_templates/4.7.2.stable/`.

- [ ] **Step 1:** Write `tools/install_godot.sh`.
  - Download `Godot_v4.7.2-stable_linux.x86_64.zip` and
    `Godot_v4.7.2-stable_export_templates.tpz` from
    `github.com/godotengine/godot/releases/download/4.7.2-stable/`.
  - Version comes from `tools/godot_version.txt`.
  - Idempotent.
  - Run it, then check: `godot --version` prints `4.7.2.stable`.
- [ ] **Step 2:** Create `project.godot`.
  - Name: `"Open World Remake"`.
  - Renderer: Forward+.
  - Main scene: `res://scenes/main.tscn`.
  - Window: 1920×1080, stretch mode `canvas_items`.
  - Enable the GUT plugin.
- [ ] **Step 3:** Set up git files.
  - `.gitignore`: `.godot/`, `build/`, `user_assets/`, `*.tmp`.
  - `.gitattributes`: `* text=auto eol=lf`, `*.png binary`.
- [ ] **Step 4:** Vendor GUT 9.6.1 into `addons/gut/`.
  - Fetch it from the GUT GitHub release tag `v9.6.1`.
- [ ] **Step 5:** Write `tests/unit/test_smoke.gd`.
  - `test_engine_version` asserts `Engine.get_version_info().major == 4` and
    `minor == 7`.
- [ ] **Step 6:** Run `tools/test.sh`. Expected: `1 passed`, exit 0.
- [ ] **Step 7:** Create the export preset and check it builds.
  - `export_presets.cfg` preset `"Windows Desktop"`: x86_64, embed PCK,
    output `build/windows/OpenWorldRemake.exe`.
  - Run: `godot --headless --export-release "Windows Desktop" build/windows/OpenWorldRemake.exe`.
  - Expected: the `.exe` exists and is larger than 50 MB.
- [ ] **Step 8:** Write `.github/workflows/build.yml`, triggered on push and
  PR. Steps:
  1. Checkout.
  2. Cache `~/.local` keyed on `tools/godot_version.txt`.
  3. `tools/install_godot.sh`.
  4. `godot --headless --path . --import`.
  5. `godot --headless -s tools/validate_data.gd`, guarded by
     `if [ -f tools/validate_data.gd ]` until Task 2.
  6. `tools/test.sh`.
  7. Export.
  8. `actions/upload-artifact` with name `OpenWorldRemake-windows`.
- [ ] **Step 9:** Write `README.md`.
  - How to download the CI artifact and run it on Windows.
  - The `user_assets/` policy (§1.2).
- [ ] **Step 10:** Commit: `chore: scaffold Godot 4.7.2 project, GUT, CI Windows export`.

### Task 2: DataDB and DataValidator

**Files:**
- Create: `src/core/data_db.gd`, `src/core/data_validator.gd`,
  `tools/validate_data.gd`
- Create: `data/types.json` (17 types, empty chart filled in Task 20)
- Create: `data/schema/*.json` (one schema per content kind)
- Test: `tests/unit/test_data_db.gd`, `tests/unit/test_data_validator.gd`,
  `tests/fixtures/data_bad/`

**Interfaces:**
- Produces:
  - `class_name DataDB extends RefCounted`:
    - `static func load_dir(root: String) -> DataDB`
    - `func table(kind: StringName) -> Dictionary` (id → record)
    - `func get_record(kind: StringName, id: StringName) -> Dictionary`
      (empty dictionary if missing)
    - `var errors: PackedStringArray`
  - `class_name DataValidator extends RefCounted`:
    - `static func validate(db: DataDB) -> PackedStringArray` (empty when
      valid)
    - It checks schema field presence and types, plus every cross-reference
      listed in §9.3.
  - Autoload `Data`, holding `Data.db: DataDB` loaded from `res://data`.
- **Kinds:** `species`, `moves`, `types`, `natures`, `spawns`, `weather`,
  `npcs`, `schedules`, `dialogue`, `quests`, `doors`, `interiors`, `items`,
  `chunks`, `trainers`.
- **File layout:** one JSON file per record under `data/<kind>/<id>.json`, or
  a single `data/<kind>.json` holding an id-keyed object.

- [ ] **Step 1:** Write the failing tests:
  - `test_loads_records_by_kind`
  - `test_malformed_json_file_logged_and_skipped`: `errors.size() == 1`,
    and other records still load.
  - `test_missing_record_returns_empty`
  - `test_validator_flags_unknown_move_in_learnset`: error string contains
    the species id and the move id.
  - `test_validator_flags_door_to_missing_interior`
  - `test_validator_passes_good_fixture`
- [ ] **Step 2:** Run the tests. Expected: FAIL (`DataDB` not declared).
- [ ] **Step 3:** Implement `DataDB` and `DataValidator`.
  - Use `JSON.parse_string`.
  - Bad files are pushed to `errors` and also reported with `push_warning`.
- [ ] **Step 4:** Make `tools/validate_data.gd` an `extends SceneTree` script.
  - It loads `res://data`, prints each error, and calls `quit(1)` on any
    error, `quit(0)` otherwise.
- [ ] **Step 5:** Check:
  - `tools/test.sh` passes.
  - `godot --headless -s tools/validate_data.gd` exits 0.
- [ ] **Step 6:** Commit: `feat: DataDB loader and cross-reference validator`.

### Task 3: EventBus and game clock

**Files:**
- Create: `src/core/event_bus.gd` (autoload `EventBus`)
- Create: `src/core/clock_model.gd`, `src/core/game_clock.gd`
  (autoload `Clock`)
- Test: `tests/unit/test_clock_model.gd`

**Interfaces:**
- Produces:
  - `EventBus` signals:
    - `period_changed(period: StringName)`
    - `hour_changed(hour: int)`
    - `weather_changed(area: StringName, weather: StringName)`
    - `chunk_loaded(coord: Vector2i)`
    - `chunk_unloaded(coord: Vector2i)`
    - `fight_started(fight_id: int)`
    - `fight_ended(fight_id: int, result: StringName)`
    - `flag_set(flag: StringName)`
    - `pokemon_caught(species: StringName)`
    - `area_entered(area: StringName)`
  - `class_name ClockModel extends RefCounted`:
    - Fields: `var minutes: float` (0–1440), `var day: int`,
      `var rate: float = 24.0` (game-seconds per real-second),
      `var use_real_time: bool`.
    - `func advance(real_delta: float) -> Array[StringName]`: returns the
      events crossed, in order: `&"hour:<n>"`, `&"period:<name>"`.
    - `func hour() -> int`
    - `static func period_for(hour: int) -> StringName`: returns `&"morning"`,
      `&"day"`, `&"evening"` or `&"night"`.
    - `func set_from_system(dt: Dictionary) -> void`
  - The `Clock` autoload wraps a `ClockModel` and emits on `EventBus`.

- [ ] **Step 1:** Write the failing tests:
  - `test_period_boundaries`: hours 4, 9, 10, 16, 17, 19, 20 and 3 map to
    morning, morning, day, day, evening, evening, night and night.
  - `test_night_wraps_midnight`: `period_for(23)` and `period_for(0)` are
    both night.
  - `test_default_rate_one_real_hour_is_one_day`: `advance(3600.0)` increases
    `day` by 1.
  - `test_advance_reports_crossed_hours_in_order`
  - `test_real_time_mode_tracks_system_dict`: `{hour:23, minute:59}`, then
    `{hour:0, minute:1}` increments `day`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `ClockModel`, `GameClock` and `EventBus`.
  - Register both autoloads in `project.godot`.
- [ ] **Step 4:** Run `tools/test.sh res://tests/unit/test_clock_model.gd`.
  Expected: PASS.
- [ ] **Step 5:** Commit: `feat: game clock with period events and real-time mode`.

### Task 4: Weather model

**Files:**
- Create: `src/core/weather_model.gd`, `src/core/weather_director.gd`
  (autoload `Weather`)
- Create: `data/weather/kanto_route.json`, `data/weather/kanto_town.json`,
  `data/weather/viridian_forest.json`
- Create: `data/areas.json`, which maps each area id (`pallet_town`,
  `route_1`, `viridian_city`, `route_2_south`, `viridian_forest`) to
  `{weather_table, ambience, display_name}`. It is used by Tasks 4, 6, 14
  and 18.
- Test: `tests/unit/test_weather_model.gd`

**Interfaces:**
- Consumes: `DataDB.table(&"weather")`, `EventBus.hour_changed`.
- Produces:
  - Weather ids: `&"clear"`, `&"cloudy"`, `&"rain"`, `&"thunderstorm"`,
    `&"fog"`.
  - `class_name WeatherModel extends RefCounted`:
    - `func _init(table: Dictionary, rng: RandomNumberGenerator)`
    - `func roll() -> StringName`: draws from the weighted `weights` and
      ignores ids not present in them.
    - `func transition_seconds() -> float`: uniform in [20, 40].
    - Fields: `var current: StringName`, `var target: StringName`,
      `var blend: float` (0–1).
  - Weather is re-rolled every `reroll_hours` (from data, default 3) of
    game time.
  - Only `viridian_forest.json` lists `fog`.

- [ ] **Step 1:** Write the failing tests:
  - `test_roll_respects_weights`: with weights `{clear: 3, rain: 1}` and
    10,000 seeded rolls, the rain share is within 0.25 ± 0.02.
  - `test_fog_never_rolled_when_absent`
  - `test_transition_seconds_in_range`
  - `test_blend_reaches_one_after_transition`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the model and director.
  - The director keeps one `WeatherModel` per area id.
  - It emits `EventBus.weather_changed`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: per-area weighted weather with timed transitions`.

### Task 5: Asset overrides

**Files:**
- Create: `src/core/asset_override.gd` (autoload `Assets`)
- Create: `assets/placeholder/` (generated by `tools/gen_placeholders.gd`)
- Create: `tools/gen_placeholders.gd`
- Test: `tests/unit/test_asset_override.gd`, `tests/fixtures/user_assets/`

**Interfaces:**
- Produces:
  - `class_name AssetOverride extends RefCounted`:
    - `func _init(user_dir: String, placeholder_dir: String)`
    - `func texture(key: String) -> Texture2D`
    - `func audio(key: String) -> AudioStream`
    - `var warnings: PackedStringArray`
  - Key format: `species/<id>`, `species/<id>_shiny`, `tiles/<id>`,
    `props/<id>`, `npc/<sprite_id>`, `music/<id>`, `sfx/<id>`.
  - Fallback order:
    1. `user_assets/manifest.json` entry.
    2. `assets/placeholder/<key>.png` (or `.ogg`).
    3. `assets/placeholder/missing.png`.
  - The runtime user dir is `OS.get_executable_path().get_base_dir() + "/user_assets"`.
  - Warnings go to `user://logs/assets.log`.
- Placeholder sprites are 4-direction × 3-frame sheets (48×64 px per frame)
  generated as type-colored silhouettes with the species name.

- [ ] **Step 1:** Write the failing tests:
  - `test_manifest_entry_used`
  - `test_missing_file_falls_back_and_warns`
  - `test_corrupt_png_falls_back_and_warns`
  - `test_missing_manifest_uses_placeholders_silently`
  - `test_unknown_key_returns_missing_texture`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `AssetOverride`.
  - Load images with `Image.load_from_file`.
  - Fall back whenever the result is not `OK`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Run `godot --headless -s tools/gen_placeholders.gd`.
  - Expected: `assets/placeholder/missing.png` exists.
- [ ] **Step 6:** Commit: `feat: user_assets override with placeholder fallback`.

---

## Milestone 1: World and look

### Task 6: Chunk format, region blockout and ChunkBuilder

**Files:**
- Create: `data/tileset.json`, `src/world/chunk_data.gd`,
  `src/world/chunk_builder.gd`
- Create: `src/world/mesh_library_builder.gd`, `tools/bake_chunks.gd`
- Create: `data/regions/kanto/blockout/*.txt`
- Test: `tests/unit/test_chunk_data.gd`, `tests/unit/test_chunk_builder.gd`

**Interfaces:**
- **Blockout:** an ASCII text file per area, 1 char = 4×4 m cell. The legend
  is in `tileset.json`:
  - `.` short grass
  - `"` tall grass (spawn-capable)
  - `T` tree
  - `~` water
  - `=` path
  - `#` building footprint
  - `^` ledge (south-facing one-way)
  - `f` flowers
  - `s` sand
  - `0`–`9` height level
  - Height levels go on a separate `<area>.height.txt` layer.
- **Area placement:** each blockout has a header line
  `@origin <cell_x> <cell_y>` placing it in region cell space.
- **Baking:** `tools/bake_chunks.gd` splits region cell space into
  `data/chunks/kanto_<cx>_<cy>.json`.
  - Fields: `cells` (16 strings × 16 chars), `heights`, `props[]`, `doors[]`,
    `spawn_zones[]`, `npc_anchors[]`, `area`.
  - Each prop or door has
    `{id, kind, pos:[x,y,z], rot, footprint:[w,d], ...}` in chunk-local
    metres.
  - Props/doors/zones are authored in `data/regions/kanto/placements/<area>.json`
    in region metres and are assigned to chunks by position.
- **`class_name ChunkData extends RefCounted`:**
  - `static func from_record(r: Dictionary) -> ChunkData`
  - `func cell(x: int, y: int) -> String`
  - `func height_at(local: Vector2) -> float`
  - `func is_tall_grass(local: Vector2) -> bool`
- **`class_name ChunkBuilder extends RefCounted`:**
  - `func _init(lib: MeshLibrary, seed: int)`
  - `func build(data: ChunkData) -> Node3D`
  - It returns a root holding a `GridMap` (cell size 1 m, so each blockout
    cell becomes 4×4 tiles with seeded variation), `StaticBody3D`
    collisions, prop instances, and `Area3D` doors and spawn zones.
  - It is safe to call off the main thread: it builds a detached tree only.
- **Decoration:** detail scatter (grass tufts, pebbles, tree jitter) uses
  `hash(seed, cx, cy, x, y)`, so it is identical on every load.

- [ ] **Step 1:** Write the failing tests:
  - `test_bake_splits_into_16x16_cells`: a 32×16 fixture blockout yields 2
    chunks.
  - `test_placement_assigned_to_owning_chunk`: a prop at x = 70 m lands in
    chunk 1 at local x = 6.
  - `test_tall_grass_lookup`
  - `test_height_at_interpolates_cells`
  - `test_build_is_deterministic`: two builds have identical GridMap
    `get_used_cells()` and the same item ids.
  - `test_ledge_blocks_northward_only`: the collision shape exists on the
    north edge only.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `ChunkData`, `MeshLibraryBuilder` and
  `ChunkBuilder`.
  - `MeshLibraryBuilder` builds placeholder box/plane meshes per tile id.
- [ ] **Step 4:** Implement `tools/bake_chunks.gd`.
- [ ] **Step 5:** Run the tests. Expected: PASS.
- [ ] **Step 6:** Commit: `feat: ASCII blockout baking and deterministic chunk builder`.

### Task 7: Player controller and HD-2D camera

**Files:**
- Create: `src/world/player.gd`, `scenes/player.tscn`
- Create: `src/world/billboard_sprite.gd`, `src/world/hd2d_camera.gd`
- Create: `src/core/input_setup.gd`
- Test: `tests/unit/test_hd2d_camera.gd`, `tests/unit/test_billboard_sprite.gd`

**Interfaces:**
- **Input actions,** each with keyboard/mouse and gamepad bindings:
  - `move_up`, `move_down`, `move_left`, `move_right`
  - `dodge`, `move_1`, `move_2`, `move_3`, `move_4`
  - `switch`, `aim`, `throw`, `interact`, `menu`, `run`
- **`class_name BillboardSprite extends Sprite3D`:**
  - `func set_sheet(tex: Texture2D, frames: int = 3) -> void`
  - `func face(dir: Vector2) -> void`: picks a row from 4 directions.
  - `billboard = BaseMaterial3D.BILLBOARD_FIXED_Y`, `texture_filter = NEAREST`,
    `shaded = true`, `alpha_cut = ALPHA_CUT_DISCARD`.
  - Casts shadows.
- **`class_name HD2DCamera extends Camera3D`:**
  - Exports: `pitch_deg = 35.0`, `fov = 30.0`, `distance = 22.0`,
    `combat_distance = 16.0`, `follow_lerp = 8.0`.
  - `func target_transform(focus: Vector3, in_combat: bool) -> Transform3D`
    is a pure helper.
- **Player:** `CharacterBody3D`.
  - Walk 5 m/s, run 8 m/s.
  - Gravity on; can drop down ledges but not climb back.
  - `signal interacted(target: Node)`.

- [ ] **Step 1:** Write the failing tests:
  - `test_camera_pitch_and_distance`: camera position equals focus +
    `Vector3(0, sin35°·22, cos35°·22)` within 0.01.
  - `test_camera_combat_distance`
  - `test_billboard_face_picks_row`: (0,1) → row 0, (-1,0) → row 1,
    (1,0) → row 2, (0,-1) → row 3.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the three scripts and `input_setup.gd`.
  - `input_setup.gd` registers the actions at startup if they are missing.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: player controller, billboard sprites, HD-2D camera`.

### Task 8: Lighting director and post-processing

**Files:**
- Create: `src/world/lighting_model.gd`, `src/world/lighting_director.gd`
- Create: `scenes/world_environment.tscn`
- Create: `data/lighting/periods.json`, `assets/placeholder/lut/*.png`
- Create: `src/core/graphics_presets.gd`
- Test: `tests/unit/test_lighting_model.gd`, `tests/unit/test_graphics_presets.gd`

**Interfaces:**
- Consumes: `ClockModel.minutes`, `WeatherModel.current/target/blend`.
- Produces:
  - `class_name LightingModel extends RefCounted`:
    - `func sample(minutes: float, weather: StringName, weather_to: StringName, blend: float) -> LightingState`
  - `class_name LightingState extends RefCounted`, with fields:
    - `sun_dir: Vector3`, `sun_color: Color`, `sun_energy: float`
    - `moon_energy: float`, `sky_top: Color`, `sky_horizon: Color`
    - `ambient_energy: float`, `fog_density: float`
    - `volumetric_density: float`, `exposure: float`
    - `lut: StringName`, `lamps_on: bool`
  - Keyframes are in `periods.json`, one per game hour, and are linearly
    interpolated. Weather applies multiplicative overrides from the same file.
  - `lamps_on` is true from 17:30 to 06:00.
  - The sun arc rises at 05:00, peaks at 12:00 and sets at 19:30. The moon
    is opposite.
  - `GraphicsPresets.apply(preset: StringName, env: Environment, vp: Viewport) -> void`
    applies Low, Medium, High or Ultra, toggling SDFGI, SSAO, SSIL,
    volumetric fog, glow, DOF, shadow size and MSAA.
  - The tilt-shift look is `CameraAttributesPractical` DOF: far blur from
    30 m, near blur up to 8 m.

- [ ] **Step 1:** Write the failing tests:
  - `test_noon_sun_highest`
  - `test_midnight_sun_below_horizon_moon_up`
  - `test_interpolates_between_keyframes`
  - `test_rain_darkens_and_raises_fog`
  - `test_blend_half_between_weathers`
  - `test_lamps_on_window`
  - `test_low_preset_disables_sdfgi_and_volumetrics`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the model.
  - The director applies `LightingState` each frame to `DirectionalLight3D`
    (sun and moon), `WorldEnvironment` and the LUT (`Environment.adjustment_color_correction`).
  - It emits `lamps_on` changes via a new `EventBus.lamps_changed(on: bool)`
    signal.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5 (best-effort visual check):** Try
  `xvfb-run godot --rendering-driver vulkan --path . --quit-after 120 -- --screenshot=build/shots/noon.png`
  using `src/main.gd` handling `--screenshot`.
  - If no Vulkan device is available (lavapipe missing), record
    "screenshots unavailable in container" in the commit body and skip.
  - Do not fail the task.
- [ ] **Step 6:** Commit: `feat: time/weather-driven lighting, LUT grading, graphics presets`.

### Task 9: Pallet Town and Route 1 content (Milestone 1 build)

**Files:**
- Create: `data/regions/kanto/blockout/pallet_town.txt` (+ `.height.txt`)
- Create: `data/regions/kanto/blockout/route_1.txt` (+ `.height.txt`)
- Create: `data/regions/kanto/placements/pallet_town.json`,
  `data/regions/kanto/placements/route_1.json`
- Create: `scenes/regions/kanto/kanto_world.tscn`
- Modify: `scenes/main.tscn`
- Test: `tests/integration/test_m1_world.gd`

**Interfaces:**
- **Sizes:**
  - Pallet Town: about 2×2 chunks.
  - Route 1: about 2×3 chunks, running north from Pallet.
  - Keep Red/Blue landmarks: the player's house, the rival's house and Oak's
    Lab; the southern water; Route 1's ledges and twin tall-grass belts.
- **Pallet Town placements:** 10–12 buildings, per §7.1:
  - houses
  - farm and orchard
  - Oak's greenhouse and outdoor pen
  - pier on the south water
  - café/general store
- **Route 1 placements,** per §7.1:
  - rest stop with a vendor stall
  - berry farmer's cottage
- **Doors:** every building gets a door record. See Task 11 for the door
  schema. Until Task 11 lands, doors use `unlock: {type: "pending"}`.

- [ ] **Step 1:** Write the failing test `test_m1_world`:
  - Load `kanto_world.tscn` headless and build the Pallet and Route 1 chunks.
  - Assert the building count in Pallet chunks is between 10 and 12.
  - Assert Oak's Lab, the player's house and the rival's house exist by id.
  - Assert Route 1 has at least 2 tall-grass zones and at least 3 ledges.
- [ ] **Step 2:** Run the test. Expected: FAIL.
- [ ] **Step 3:** Author the blockouts and placements, then bake them with
  `tools/bake_chunks.gd`.
- [ ] **Step 4:** Wire up `kanto_world.tscn`.
  - It holds the player spawned in front of the player's house, the camera,
    the lighting director and the environment.
  - All chunks load directly for now; streaming arrives in Task 10.
- [ ] **Step 5:** Run `tools/test.sh` and the validator. Expected: both pass.
- [ ] **Step 6:** Commit: `content: Pallet Town and Route 1 blockout`.
- [ ] **Step 7:** Push.
  - Confirm the CI artifact builds.
  - Tell the owner Milestone 1 is ready for a look-and-feel review on
    Windows.

---

## Milestone 2: Streaming and the living world

### Task 10: World streaming

**Files:**
- Create: `src/world/streaming_planner.gd`, `src/world/world_streamer.gd`
- Modify: `scenes/regions/kanto/kanto_world.tscn`
- Test: `tests/unit/test_streaming_planner.gd`,
  `tests/integration/test_streaming_walk.gd`

**Interfaces:**
- Produces:
  - `class_name StreamingPlanner extends RefCounted`:
    - `static func chunk_of(pos: Vector3) -> Vector2i`: `floor(x/64), floor(z/64)`.
    - `func plan(center: Vector2i, loaded: Array[Vector2i], pinned: Array[Vector2i]) -> Dictionary`
      returns `{load: Array[Vector2i], preload: Array[Vector2i], unload: Array[Vector2i]}`.
    - Rings: 3×3 must be loaded, 5×5 is preloaded, and anything outside 5×5
      is unloaded unless pinned.
  - `WorldStreamer` node:
    - `func pin(coords: Array[Vector2i], owner_id: int) -> void`
    - `func unpin(owner_id: int) -> void`
    - Emits `EventBus.chunk_loaded` / `chunk_unloaded`.
    - Builds chunks with `WorkerThreadPool.add_task(ChunkBuilder.build)` and
      adds them on the main thread at most 1 per frame.
    - Only coords whose chunk record exists are planned.
    - When the player's chunk `area` changes, it emits
      `EventBus.area_entered(area)`.

- [ ] **Step 1:** Write the failing tests:
  - `test_chunk_of_negative_coords`: (-1, -1) maps to (-1, -1).
  - `test_plan_initial_loads_3x3_preloads_ring`
  - `test_plan_unloads_beyond_5x5`
  - `test_pinned_chunks_never_unloaded`
  - `test_missing_chunk_records_ignored`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the planner and streamer.
- [ ] **Step 4:** Write `test_streaming_walk`.
  - Move a stub player along a path across 6 chunk boundaries over 600 frames.
  - Assert the 3×3 around the player is always loaded at frame end.
  - Assert no single frame spends more than 100 ms in the streamer (measured
    with `Time.get_ticks_usec`).
- [ ] **Step 5:** Run the tests. Expected: PASS.
- [ ] **Step 6:** Commit: `feat: threaded chunk streaming with pin support`.

### Task 11: Doors, unlock conditions and interiors

**Files:**
- Create: `src/world/door_unlock.gd`, `src/world/door.gd`,
  `src/world/interior_manager.gd`
- Create: `src/core/game_state.gd` (autoload `GameState`)
- Create: `data/interiors/templates/*.json`, `data/interiors/*.json`
- Create: `scenes/interiors/interior_root.tscn`
- Test: `tests/unit/test_door_unlock.gd`, `tests/unit/test_game_state.gd`,
  `tests/unit/test_interior_manager.gd`

**Interfaces:**
- **Door record** (in chunk placements):
  `{id, interior, pos, unlock: {type, flag?, item?, reward?: {kind, count}}, hours?: [open, close], locked_text}`.
  - `type` is one of `always`, `flag`, `item`, `reward`, `time` or `pending`
    (§7.1).
  - `hours` may be combined with any type.
  - `reward.kind` is one of `pokedex_caught`, `badges` or `friendship:<npc_id>`.
- **`class_name GameState extends Node`** (autoload):
  - `var flags: Dictionary` (StringName → true)
  - `var items: Dictionary` (id → count)
  - `var pokedex_caught: Dictionary`, `var badges: int`
  - `var friendship: Dictionary`, `var money: int`
  - `var last_center: StringName` (anchor id, default `&"pallet_home"`)
  - `func set_flag(f: StringName) -> void`: emits `EventBus.flag_set`.
  - `func has_flag(f: StringName) -> bool`
  - `func to_dict() -> Dictionary`
  - `func from_dict(d: Dictionary) -> void`
- **`class_name DoorUnlock extends RefCounted`:**
  - `static func evaluate(door: Dictionary, state: GameState, hour: int) -> Dictionary`
    returns `{open: bool, text: String}`.
  - A `pending` door, or a door whose interior has no record, is always
    closed, showing `locked_text`, or `"It's locked."` by default.
  - `hours` wraps past midnight the same way as Task 3.
- **Interior record:**
  `{id, template, furnishing: [...], spawn: [x,y,z], npcs: [...], lighting: "interior_warm"}`.
  - `InteriorManager.enter(door_id)` and `exit()` fade over 0.3 s.
  - On entering, the outdoor player position and the active chunk set are
    saved, and the streamer keeps the outdoor chunks pinned.
  - Exiting restores the position, offset 1.5 m from the door's outward
    normal.

- [ ] **Step 1:** Write the failing tests:
  - `test_always_open`
  - `test_flag_gate`
  - `test_item_gate`
  - `test_reward_pokedex_count`: closed at 9 caught, open at 10.
  - `test_time_hours_wrap_midnight`: `[18, 2]` is open at 01:00 and closed
    at 03:00.
  - `test_pending_always_closed_with_text`
  - `test_missing_interior_record_treated_as_pending`
  - `test_game_state_round_trip`
  - `test_exit_restores_outdoor_position`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the classes.
  - Add the `doors` → `interiors` check to `DataValidator`: a door is only
    allowed a missing interior when its type is `pending`.
- [ ] **Step 4:** Author interiors for Oak's Lab, the player's house and the
  rival's house, from templates `house_small`, `house_large` and `lab`.
  - Set those doors to `always`.
  - Pallet's other doors: about half get built interiors, the rest stay
    `pending`.
- [ ] **Step 5:** Run the tests and the validator. Expected: PASS.
- [ ] **Step 6:** Commit: `feat: data-driven doors with unlock conditions and interiors`.

### Task 12: Weather visuals

**Files:**
- Create: `src/world/weather_fx.gd`, `scenes/fx/rain.tscn`, `scenes/fx/fog_volume.tscn`
- Create: `src/world/wetness.gd`
- Create: `assets/placeholder/shaders/wet_surface.gdshaderinc`
- Test: `tests/unit/test_weather_fx.gd`

**Interfaces:**
- Consumes: `EventBus.weather_changed`, `WeatherModel.blend`.
- Produces:
  - `class_name WeatherFx extends Node3D`.
  - `func targets_for(weather: StringName) -> Dictionary` is pure and returns
    `{rain_rate: float, wetness: float, lightning_interval: Vector2, fog_volume: float}`.
  - Wetness ramps up over 60 s of rain and dries over 120 s, and is fed to
    the global shader uniform `wetness`.
  - Lightning flashes the sun energy and plays `sfx/thunder` 0.5–3 s later.
  - Rain particles follow the camera, in a 40 m box.

- [ ] **Step 1:** Write the failing tests:
  - `test_clear_has_no_rain`
  - `test_thunderstorm_has_lightning_interval`
  - `test_wetness_ramps_and_dries`: after 30 s it is about 0.5, and after
    rain stops for 60 s it is about 0.25.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the effects and add `wetness` to the tile and prop
  materials (roughness down, albedo darkened).
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: rain, storm, fog and wet-surface visuals`.

### Task 13: Creature core (species, stats, natures, growth, EXP)

**Files:**
- Create: `src/creatures/species.gd`, `src/creatures/creature.gd`,
  `src/creatures/stats.gd`, `src/creatures/growth.gd`
- Create: `data/species/*.json`, `data/natures.json`
- Test: `tests/unit/test_stats.gd`, `tests/unit/test_growth.gd`,
  `tests/unit/test_creature.gd`

**Interfaces:**
- **Slice species:** about 15 spawnable or starter species, 20 records
  including evolutions:
  - Bulbasaur, Ivysaur, Charmander, Charmeleon, Squirtle, Wartortle
  - Pidgey, Pidgeotto, Rattata, Raticate
  - Sentret, Hoothoot
  - Caterpie, Metapod, Butterfree
  - Weedle, Kakuna, Beedrill
  - Pikachu, Oddish

  Ambient-only species are tagged
  `"ambient_only": true`: Volbeat, Illumise, Meowth, Growlithe.
- **Species record:**
  `{id, name, types, base: {hp, atk, def, spa, spd, spe}, catch_rate, base_exp, growth, ev_yield, learnset: [[lvl, move]], evolves: [{to, level}], temperament, nocturnal?: bool, ambient_only?: bool}`.
  - Values come from Bulbapedia's Gen 5 data for each species.
- **`class_name Stats`:**
  - `static func hp(base: int, iv: int, ev: int, lvl: int) -> int` returns
    `floor((2B+IV+floor(EV/4))·L/100) + L + 10`.
  - `static func other(base, iv, ev, lvl, nature_mult: float) -> int`
    returns `floor((floor((2B+IV+floor(EV/4))·L/100) + 5) · nature)`.
- **`class_name Growth`:**
  - `static func exp_for_level(curve: StringName, lvl: int) -> int` covers
    `erratic`, `fast`, `medium_fast`, `medium_slow`, `slow` and
    `fluctuating`, using the standard piecewise formulas.
  - `static func gen5_exp_gain(base_exp: int, foe_lvl: int, my_lvl: int, trainer: bool) -> int`
    returns `floor( floor(b·Lf/5) · trainer(1.5) · ((2Lf+10)^2.5 / (Lf+Lp+10)^2.5) ) + 1`.
    (Gen 5 scaled formula; ignore Lucky Egg/traded for the slice.)
- **`class_name Creature extends RefCounted`:**
  - Fields: `species: StringName`, `level: int`, `exp: int`,
    `ivs: Dictionary`, `evs: Dictionary`, `nature: StringName`,
    `moves: Array[StringName]` (≤ 4), `hp: int`, `status: StringName`,
    `shiny: bool`, `nickname: String`.
  - `static func create(species: StringName, level: int, rng: RandomNumberGenerator, db: DataDB) -> Creature`:
    IVs 0–31 random, random nature, last 4 learnset moves at or below the
    level.
  - `func stat(name: StringName) -> int`
  - `func max_hp() -> int`
  - `func add_exp(amount: int) -> Array[Dictionary]` returns events
    `{type: "level", level}`, `{type: "learn", move}` and
    `{type: "evolve", to}`.
  - `func to_dict() -> Dictionary`
  - `static func from_dict(d: Dictionary) -> Creature`

- [ ] **Step 1:** Write the failing tests:
  - `test_hp_formula`: Pikachu (base 35), IV 31, EV 0, Lv 50 → 110.
  - `test_other_formula_with_nature`: base 55 atk, IV 31, EV 0, Lv 50,
    Adamant 1.1 → 82.
  - `test_medium_slow_level_5`: 135.
  - `test_medium_fast_level_100`: 1,000,000.
  - `test_fluctuating_level_100`: 1,640,000.
  - `test_erratic_level_100`: 600,000.
  - `test_exp_gain_scales_with_level_gap`: gain vs. a Lv 10 foe at Lv 5 is
    greater than at Lv 15.
  - `test_create_picks_last_four_moves`
  - `test_add_exp_emits_level_learn_evolve_in_order`
  - `test_creature_round_trip`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the classes. Author the species JSON and
  `natures.json` (25 natures, ±10%).
- [ ] **Step 4:** Run the tests and the validator. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: creature stats, growth curves, Gen 5 EXP`.

### Task 14: Spawning

**Files:**
- Create: `src/spawning/spawn_table.gd`, `src/spawning/spawn_director.gd`
- Create: `data/spawns/route_1.json`, `data/spawns/route_2.json`,
  `data/spawns/viridian_forest.json`
- Test: `tests/unit/test_spawn_table.gd`, `tests/unit/test_spawn_director.gd`

**Interfaces:**
- **Spawn entry:**
  `{species, min_lvl, max_lvl, weight, periods: [..] | "all", weather_mult: {weather: float}}`.
  - Use the §6.4 table, with levels: Route 1 2–5, Route 2 3–6, forest 3–7,
    and rare Pikachu (weight 5, ×3 in thunderstorm).
- **`class_name SpawnTable extends RefCounted`:**
  - `func _init(record: Dictionary)`
  - `func pick(period: StringName, weather: StringName, rng: RandomNumberGenerator) -> Dictionary`
    returns `{species, level}`, or `{}` if nothing is eligible.
- **`class_name SpawnDirector extends RefCounted`:** pure, driven by the
  `SpawnNode` adapter.
  - Constants: `ACTIVE_MIN = 8`, `ACTIVE_MAX = 12`, `ACTIVE_RADIUS = 60.0`,
    `DESPAWN_RADIUS = 80.0`, `MIN_SPAWN_DIST = 25.0`,
    `RESPAWN_GAME_MIN = Vector2(1, 3)`, `SHINY_ODDS = 8192`,
    `MAX_POINT_TRIES = 8`.
  - `func tick(player_pos: Vector3, active: Array[Dictionary], zones: Array[Dictionary], period: StringName, weather: StringName, is_visible: Callable, game_minutes: float) -> Dictionary`
    returns `{spawn: Array[Dictionary], despawn: Array[int]}`.
    - Each spawn is `{species, level, shiny, pos, zone_id}`.
    - At most one spawn per tick.
    - The adapter ticks it every 0.5 s.
  - `func on_removed(zone_id: StringName, game_minutes: float) -> void`
    starts a respawn timer for that slot.
- Nocturnal species never spawn outside `night`, even if the data says
  otherwise. The validator also warns about that mismatch.

- [ ] **Step 1:** Write the failing tests:
  - `test_pick_filters_by_period`: Hoothoot only at night.
  - `test_weather_multiplier_applied`: Pikachu's share in a thunderstorm is
    about 3× its share in clear weather (10,000 rolls, ±15%).
  - `test_empty_table_for_period`: returns `{}`.
  - `test_fills_to_min_then_caps_at_max`
  - `test_despawns_beyond_80m`
  - `test_never_spawns_within_25m_or_visible`
  - `test_no_valid_point_skips`: an `is_visible` that is always true gives an
    empty spawn, no loop, and at most 8 calls.
  - `test_respawn_waits_1_to_3_game_minutes`
  - `test_shiny_rate_seeded`: 819,200 rolls give 100 ± 30 shinies.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the spawn table and director.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: time/weather spawn tables with population caps and respawn`.

### Task 15: Wild overworld actors and temperaments

**Files:**
- Create: `src/creatures/wild_pokemon.gd`, `scenes/wild_pokemon.tscn`
- Create: `src/creatures/temperament.gd`
- Test: `tests/unit/test_temperament.gd`

**Interfaces:**
- Consumes: `Creature`, `BillboardSprite`, `Assets.texture("species/<id>[_shiny]")`.
- Produces:
  - `class_name Temperament extends RefCounted`:
    - `static func decide(kind: StringName, self_pos: Vector3, home: Vector3, player_pos: Vector3, attacked: bool) -> Dictionary`
      returns `{action, target}`.
    - `action` is one of `&"wander"`, `&"flee"`, `&"charge"`, `&"return"`
      or `&"idle"`.
  - Rules by `kind`:
    - `timid`: flee if the player is within 10 m.
    - `aggressive`: charge if within 8 m.
    - `territorial`: charge if the player is within 6 m of `home`; return if
      more than 15 m from home.
    - `passive`: idle unless attacked.
  - `WildPokemon` (CharacterBody3D):
    - `var creature: Creature`, `var zone_id: StringName`
    - `signal engaged(wild: WildPokemon)`, emitted when its charge connects
      or when the player hits it.
    - Shinies get a looping sparkle `GPUParticles3D`.

- [ ] **Step 1:** Write the failing tests: one per rule in the Interfaces list
  (`test_timid_flees_inside_10m`, ...), plus `test_attacked_passive_charges`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `Temperament` and `WildPokemon`.
  - Wander uses random points within 6 m of home, with a 2–5 s pause.
- [ ] **Step 3b:** Implement the spawn adapter `SpawnNode`
  (`src/spawning/spawn_node.gd`).
  - It ticks `SpawnDirector` every 0.5 s.
  - It reads zones from loaded chunks (tall-grass zones only).
  - `is_visible` uses `Camera3D.is_position_in_frustum`.
  - It instances `WildPokemon` and calls `on_removed` when one is freed.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: visible wild Pokémon with temperament AI`.

### Task 16: NPC schedules and actors

**Files:**
- Create: `src/npcs/schedule.gd`, `src/npcs/npc.gd`, `src/npcs/npc_manager.gd`
- Create: `scenes/npc.tscn`
- Test: `tests/unit/test_schedule.gd`, `tests/unit/test_npc_manager.gd`

**Interfaces:**
- **NPC record:**
  `{id, name, sprite, role: resident|traveler|trainer|worker, home: anchor_id, schedule: schedule_id, dialogue: dialogue_id, companion?: species, weather_behavior?: {rain: "indoors"|"umbrella"|"awning", thunderstorm: "indoors"}}`.
- **Schedule record:**
  `{id, blocks: [{from: h, to: h, at: anchor_id, activity: StringName}]}`.
  - Blocks may wrap midnight.
  - Gaps fall back to `home`.
- **Anchors:** `npc_anchors` in chunk data are `{id, pos, kind}`; door
  anchors refer to a door id.
- **`class_name Schedule extends RefCounted`:**
  - `func resolve(hour: float, weather: StringName, behavior: Dictionary) -> Dictionary`
    returns `{anchor, activity, indoors: bool, umbrella: bool}`.
- **`class_name NPCManager extends Node`:**
  - It tracks all NPCs abstractly as `{id, anchor, indoors}`.
  - It instances an actor only when the NPC's resolved anchor lies in a
    loaded chunk and the NPC is not indoors.
  - It places the actor at the anchor (abstract advancement).
  - LOD: actors farther than 40 m think at 4 Hz; farther than 80 m they are
    freed.
  - Animated actor cap: `GraphicsPresets.npc_cap()` (60 on High).
- **NPC actor:**
  - Uses `NavigationAgent3D`. A navmesh is baked per chunk at build time;
    add a `NavigationRegion3D` in `ChunkBuilder`.
  - The umbrella is a child billboard toggled on.
  - Workers stand at their stall or counter.

- [ ] **Step 1:** Write the failing tests:
  - `test_block_lookup`
  - `test_block_wrapping_midnight`: `{20→7 home}` matches at 23:00 and 03:00.
  - `test_gap_falls_back_home`
  - `test_rain_indoors_override`
  - `test_umbrella_flag`
  - `test_manager_instances_only_in_loaded_chunks`
  - `test_manager_respects_cap`
  - `test_far_npcs_freed`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `Schedule`, `NPCManager` and the `NPC` actor.
  - Add navmesh baking to `ChunkBuilder`, using
    `NavigationServer3D.bake_from_source_geometry_data`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: NPC daily schedules, weather reactions, LOD`.

### Task 17: Dialogue and barks

**Files:**
- Create: `src/npcs/dialogue_selector.gd`, `src/ui/dialogue_box.gd`,
  `scenes/ui/dialogue_box.tscn`, `src/ui/bark_label.gd`
- Create: `data/dialogue/*.json`
- Test: `tests/unit/test_dialogue_selector.gd`

**Interfaces:**
- **Dialogue record:**
  `{id, barks: [Line], talk: [Line], branches?: {...}}`.
  - Each `Line` is `{text, when?: {periods?, weather?, flag?, not_flag?}, weight?: int}`.
- **`class_name DialogueSelector extends RefCounted`:**
  - `func pick(lines: Array, ctx: Dictionary, rng: RandomNumberGenerator) -> String`.
  - `ctx` is `{period, weather, flags: Dictionary}`.
  - The most specific match wins: lines with more `when` keys are preferred,
    then lines are weighted at random among equals.
  - Returns `""` if nothing matches.
- **Barks** trigger when the player passes within 4 m, with a per-NPC
  cooldown of 30 s. They show as a floating `Label3D` for 3 s.
- **Talk** is triggered by `interact`. The bottom dialogue box advances on
  `interact`.
- **Branches** use `{choices: [{text, next, set_flag?}]}` (used by Oak and
  the Mart clerk).

- [ ] **Step 1:** Write the failing tests:
  - `test_specific_line_beats_generic`
  - `test_flag_and_not_flag`
  - `test_no_match_returns_empty`
  - `test_weighted_among_equals`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the selector and UI.
  - The validator checks that every NPC's dialogue id exists and that every
    NPC has at least 3 lines across barks and talk with distinct `when`
    contexts (§7.2).
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: context-aware dialogue and barks`.

### Task 18: Companions and ambient life

**Files:**
- Create: `src/npcs/companion.gd`, `src/world/ambient/flock.gd`,
  `src/world/ambient/drifters.gd`
- Create: `src/world/ambient/window_lights.gd`,
  `src/world/ambient/chimney_smoke.gd`, `src/world/ambient/cloth_sway.gd`
- Create: `src/world/ambient/ambience_mixer.gd`, `data/ambience.json`
- Test: `tests/unit/test_flock.gd`, `tests/unit/test_ambience_mixer.gd`,
  `tests/unit/test_companion.gd`

**Interfaces:**
- **Companions:**
  - A `Companion` follows its owner NPC at 1.5–2.5 m and idles near them.
  - It has no collision with combat, and the spawner and fight ring ignore
    it (group `ambient`).
  - The validator checks that at least 30% of `resident` NPCs per town have
    a `companion`.
- **`class_name Flock extends RefCounted`:**
  - `func step(birds: PackedVector3Array, player_pos: Vector3, delta: float) -> PackedVector3Array`.
  - Birds scatter upward when the player comes within 6 m, and resettle after
    20 s.
- **Drifters:** Butterfree in the day, Volbeat and Illumise at night, at the
  forest edge.
- **Window lights:** toggle on `EventBus.lamps_changed`. A random 30% of lit
  windows show a silhouette quad that animates occasionally.
- **`class_name AmbienceMixer extends RefCounted`:**
  - `func layers(area: StringName, period: StringName, weather: StringName) -> Dictionary`
    returns layer id → volume_db.
  - It crossfades over 3 s.
  - Sounds use `Assets.audio("sfx/amb_*")`.

- [ ] **Step 1:** Write the failing tests:
  - `test_flock_scatters_inside_6m`
  - `test_flock_resettles`
  - `test_night_forest_layers_include_crickets`
  - `test_rain_layer_added`
  - `test_companion_excluded_from_spawner`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the ambient systems.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: companions, flocks, window lights, ambience`.

### Task 19: Viridian City, Route 2, Viridian Forest content (Milestone 2 build)

**Files:**
- Create: blockouts and placements for `viridian_city`, `route_2_south`,
  `viridian_forest`
- Create: NPC, schedule and dialogue data for Pallet, Route 1, Viridian,
  Route 2 and the forest
- Create: interiors for the Viridian Pokémon Center, Mart and the built
  homes
- Test: `tests/integration/test_m2_population.gd`

**Interfaces:**
- **Sizes:**
  - Viridian City: about 4×3 chunks.
  - Route 2 south: about 2×3 chunks.
  - Viridian Forest: about 3×4 chunks, keeping its maze character.
  - The Route 2 gatehouse is the forest entrance.
- **Buildings:** Viridian gets 25–30, using the §7.1 list.
  - The Gym door uses `{type: "flag", flag: "viridian_gym_open"}`, which is
    never set in the slice.
  - The Pokémon Center and Mart are `always`.
  - The Mart closes 21–8 via `hours`.
  - About 40–50% of homes get built interiors; the rest stay `pending`.
- **NPC counts:** per §7.2 (Pallet 12–15, Route 1 6–10, Viridian 35–45,
  Route 2 and forest 10–15 including 3–4 Bug Catcher trainers).
  - At least 3 night-owl NPCs in Viridian who appear only 21–3.

- [ ] **Step 1:** Write the failing test `test_m2_population`. Simulate the
  clock at 12:00 and 23:00. Assert:
  - NPC record counts per area are within the §7.2 ranges.
  - Viridian active NPCs at 23:00 are below 50% of those at 12:00.
  - Night-owls are present only at night.
  - The building count in Viridian is between 25 and 30.
  - Every door resolves through `DoorUnlock` without error.
- [ ] **Step 2:** Run the test. Expected: FAIL.
- [ ] **Step 3:** Author the content and bake the chunks.
- [ ] **Step 4:** Run `tools/test.sh` and the validator. Expected: both pass.
- [ ] **Step 5:** Commit: `content: Viridian City, Route 2, Viridian Forest, NPC population`.
- [ ] **Step 6:** Push, confirm the CI artifact, and tell the owner
  Milestone 2 is ready for review.

---

## Milestone 3: Combat

### Task 20: Type chart and damage

**Files:**
- Modify: `data/types.json` (full Gen 2–5 chart)
- Create: `src/combat/type_chart.gd`, `src/combat/damage.gd`
- Test: `tests/unit/test_type_chart.gd`, `tests/unit/test_damage.gd`

**Interfaces:**
- **`class_name TypeChart extends RefCounted`:**
  - `func mult(atk_type: StringName, def_types: Array[StringName]) -> float`.
- **`class_name Damage extends RefCounted`:**
  - `static func calc(p: Dictionary) -> int`.
  - Keys of `p`: `level`, `power`, `atk`, `def`, `stab: bool`,
    `type_mult: float`, `crit: bool`, `burn_physical: bool`,
    `weather_mult: float`, `roll: int` (85–100).
  - Gen 5 order with `floor` at each step:
    1. base = `floor(floor(floor(2L/5+2)·P·A/D)/50)+2`
    2. × weather
    3. × crit (2.0)
    4. × roll/100
    5. × STAB (1.5)
    6. × type
    7. × burn (0.5)
  - The result is at least 1 unless `type_mult == 0`.
  - `static func crit_chance(stage: int) -> float` returns, for stages 0–4,
    1/16, 1/8, 1/4, 1/3 and 1/2.
  - `static func stage_mult(stage: int) -> float` returns `(2+s)/2` for
    s ≥ 0 and `2/(2-s)` for s < 0, clamped to ±6.

- [ ] **Step 1:** Write the failing tests:
  - `test_gen5_has_no_fairy`
  - `test_steel_resists_ghost_and_dark`: 0.5 each.
  - `test_dual_type_multiplies`: Electric vs Water/Flying → 4.
  - `test_ground_immune_to_electric`: 0.
  - `test_damage_known_values`: L50, P80, A=D=100, STAB, ×2. Roll 100 → 110;
    roll 85 → 92.
  - `test_immune_deals_zero`
  - `test_min_damage_one`
  - `test_burn_halves`
  - `test_crit_doubles`
  - `test_stage_mults`: +6 → 4.0, −6 → 0.25, +1 → 1.5.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the chart and damage. Fill `types.json` from the
  Gen 2–5 chart.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: Gen 5 type chart and damage formula`.

### Task 21: Moves, cooldowns and hitboxes

**Files:**
- Create: `data/moves/*.json` (about 30 moves)
- Create: `src/combat/move_def.gd`, `src/combat/cooldowns.gd`
- Create: `src/combat/move_executor.gd`, `src/combat/hitbox_shapes.gd`
- Test: `tests/unit/test_cooldowns.gd`, `tests/unit/test_move_executor.gd`,
  `tests/unit/test_hitbox_shapes.gd`

**Interfaces:**
- **Move record:**
  `{id, name, type, category: physical|special|status, power, pp, priority, accuracy, shape: melee_arc|projectile|beam|area|self, range, arc_deg?, radius?, speed?, windup_s?, active_s, status?: {id, chance}, stat_change?: {target, stat, stages}, cooldown_override?}`.
  - `pp` is kept only to derive cooldowns.
  - Moves: every learnset move up to Lv 20 for the slice species, plus
    Thunder Shock and Quick Attack.
- **`class_name Cooldowns`:**
  - `static func for_move(m: Dictionary) -> float` returns
    `cooldown_override` if present, else `clamp(28.0 / pp, 0.6, 8.0)`.
- **`class_name MoveDef`:**
  - `func windup(user_speed: int) -> float`.
  - Base wind-up: `windup_s` if set; otherwise `0.35 + (100 - accuracy) · 0.02`.
  - Scaled by `clamp(1.25 - user_speed / 400.0, 0.6, 1.25)`.
  - Priority of 1 or more sets wind-up to 0.05.
- **`class_name HitboxShapes`:**
  - `static func hits(shape: Dictionary, origin: Vector3, facing: Vector3, target: Vector3, target_radius: float) -> bool`.
  - Lower accuracy narrows the arc and radius per the data.
- **`MoveExecutor` node:**
  - Runs wind-up, then active, then recovery.
  - Spawns projectile/beam/area nodes.
  - On hit, calls `Damage.calc` with `roll = rng.randi_range(85, 100)`.
  - No random misses.

- [ ] **Step 1:** Write the failing tests:
  - `test_tackle_cooldown_0_8`
  - `test_hydro_pump_cooldown_5_6`
  - `test_cooldown_clamped`: PP 40 → 0.7; PP 1 → 8.0.
  - `test_override_wins`
  - `test_priority_windup`
  - `test_low_accuracy_longer_windup`
  - `test_melee_arc_hits_inside_only`
  - `test_projectile_travel_time`
  - `test_no_rng_miss`: 1,000 executions against a stationary target in
    range give 1,000 hits.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the move system and author the moves.
- [ ] **Step 4:** Run the tests and the validator. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: real-time moves with PP-derived cooldowns and aim-based hit shapes`.

### Task 22: Status conditions and stat stages in real time

**Files:**
- Create: `src/combat/status_effects.gd`, `src/combat/combatant.gd`
- Test: `tests/unit/test_status_effects.gd`, `tests/unit/test_combatant.gd`

**Interfaces:**
- **`class_name Combatant extends RefCounted`:** wraps a `Creature` during a
  fight.
  - `var stages: Dictionary` (atk, def, spa, spd, spe, crit; ±6)
  - `var status: StringName`, `var status_timer: float`
  - `var stunned: float`, `var invuln: float`, `var stamina: float = 100.0`
  - `func effective(stat: StringName) -> int` applies stages, plus ×0.25 Spe
    when paralyzed.
  - `func can_act() -> bool`
  - `func tick(delta: float, rng: RandomNumberGenerator) -> Array[Dictionary]`
    returns DoT events and status-end events.
  - `func take_hit(dmg: int, move_type: StringName) -> void`: wakes from
    sleep, thaws on a Fire hit.
  - `func end_fight() -> void`: resets stages.
- **Rules (§5.3):**
  - Paralysis: Spe ×0.25. Every 2 s there is a 25% chance of a 0.75 s stun.
  - Sleep: 3–6 s.
  - Poison/burn: `floor(max_hp/8)` every 4 s.
  - Freeze: 2–5 s.
  - Burn halves physical damage (passed to `Damage`).
  - Status persists after the fight; the Creature keeps it.
- **Dodge:** costs 25 stamina and grants 0.25 s invulnerability. Stamina
  regenerates 20/s after 1 s without dodging.

- [ ] **Step 1:** Write the failing tests:
  - `test_paralysis_quarter_speed`
  - `test_paralysis_stun_rate`: over 10,000 simulated seconds, about 25%
    of 2 s windows stun, ±3%.
  - `test_sleep_duration_bounds`
  - `test_damage_wakes`
  - `test_poison_tick_eighth`
  - `test_fire_thaws`
  - `test_stages_reset_on_end`
  - `test_dodge_stamina_and_iframes`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `Combatant` and `StatusEffects`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: real-time status conditions, stat stages, dodge`.

### Task 23: Fight controller (ring, flow, switching, blackout)

**Files:**
- Create: `src/combat/fight_model.gd`, `src/combat/fight_controller.gd`
- Create: `scenes/fight_ring.tscn`, `src/ui/combat_hud.gd`,
  `scenes/ui/combat_hud.tscn`
- Create: `src/core/party.gd` (minimal; Task 27 extends it)
- Test: `tests/unit/test_fight_model.gd`

**Interfaces:**
- **`class_name FightModel extends RefCounted`:**
  - `func _init(kind: StringName, center: Vector3, party: Party, foes: Array[Combatant])`,
    with kind `&"wild"` or `&"trainer"`.
  - Constants: `RING_RADIUS = 12.0`, `ESCAPE_SECONDS = 3.0`,
    `SWITCH_SECONDS = 1.5`, `SWITCH_COOLDOWN = 5.0`.
  - `func update(delta: float, player_pos: Vector3) -> StringName` returns
    `&"ongoing"`, `&"escaped"`, `&"won"`, `&"lost"` or `&"caught"`.
  - `func request_switch(index: int) -> bool`
  - `func pinned_chunks() -> Array[Vector2i]` returns every chunk overlapping
    the ring.
  - Escape is impossible when kind is `trainer`.
  - `static func blackout_money_loss(badges: int, highest_level: int) -> int`
    returns `[8,16,24,36,48,64,80,100,120][badges] × highest_level`.
- **`class_name Party extends RefCounted`:**
  - `var members: Array[Creature]` (≤ 6)
  - `func lead() -> Creature`
  - `func first_able() -> int`
  - `func all_fainted() -> bool`
- **FightController** (node):
  - Starts on `WildPokemon.engaged` or on trainer line of sight.
  - Spawns the lead as a controllable `PlayerPokemon`: the player avatar
    stays at the ring edge and the input targets the Pokémon.
  - Calls `WorldStreamer.pin(fight.pinned_chunks(), fight_id)`.
  - Switches the camera to combat distance.
  - Emits `fight_started` and `fight_ended`.
  - On `lost`: deducts money, warps to the last Pokémon Center anchor
    (`GameState.last_center`), and heals.

- [ ] **Step 1:** Write the failing tests:
  - `test_wild_escape_after_3s_outside`
  - `test_reentering_resets_escape_timer`
  - `test_trainer_cannot_escape`
  - `test_switch_timing_and_cooldown`
  - `test_lost_when_all_fainted`
  - `test_won_when_foes_fainted`
  - `test_pinned_chunks_cover_ring_at_chunk_corner`
  - `test_blackout_loss`: 0 badges at Lv 10 → 80.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the model, controller and HUD.
  - The HUD shows HP bars, move slots with radial cooldowns, stamina, the
    switch cooldown and the escape timer.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: overworld fight ring with escape, switching, blackout`.

### Task 24: Combat AI and trainers (Milestone 3 build)

**Files:**
- Create: `src/combat/combat_ai.gd`, `data/trainers/*.json`
- Create: `src/npcs/trainer_sight.gd`
- Test: `tests/unit/test_combat_ai.gd`, `tests/integration/test_scripted_fight.gd`

**Interfaces:**
- **`class_name CombatAI extends RefCounted`:**
  - `func decide(me: Combatant, my_pos: Vector3, foe: Combatant, foe_pos: Vector3, ready_moves: Array[StringName], db: DataDB, skill: float) -> Dictionary`
    returns `{action: &"move"|&"approach"|&"retreat"|&"strafe", move?, target_pos?}`.
  - Moves are scored as `power × type_mult × stab`, plus status-move value
    when the foe has no status.
  - `skill` ranges 0–1: wild 0.3, Bug Catcher 0.5, rival 0.7. Below 1.0 the
    AI picks randomly among the top-k moves.
  - The AI keeps the move's ideal range: ranged moves strafe, melee
    approaches.
- **Trainer record:**
  `{id, npc, party: [{species, level, moves?}], skill, sight_range: 6, reward_money, defeated_flag}`.
  - Trainer sight is a 6 m forward ray cone. It triggers an "!" bark and the
    trainer walks to the player.
  - Defeated trainers set their flag and won't re-challenge.

- [ ] **Step 1:** Write the failing tests:
  - `test_prefers_super_effective`
  - `test_uses_status_when_foe_clean`
  - `test_keeps_range_for_projectiles`
  - `test_low_skill_still_legal_moves`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the AI, trainer sight and Bug Catcher data.
- [ ] **Step 4:** Write `test_scripted_fight`.
  - Lv 10 Charmander vs. a Lv 3 Caterpie, with the player inputs scripted to
    Ember on cooldown.
  - The fight must end `won` within 30 simulated seconds.
- [ ] **Step 5:** Run the tests. Expected: PASS.
- [ ] **Step 6:** Commit: `feat: combat AI and line-of-sight trainers`.
- [ ] **Step 7:** Push, confirm the CI artifact, and tell the owner
  Milestone 3 is ready for review.

---

## Milestone 4: Capture and progression

### Task 25: Catch formula

**Files:**
- Create: `src/capture/catch_calc.gd`, `data/items.json` (Poké Ball,
  Potion, Antidote, Parlyz Heal, Awakening, Oak's Parcel, Town Map)
- Test: `tests/unit/test_catch_calc.gd`

**Interfaces:**
- **`class_name CatchCalc extends RefCounted`:**
  - `static func modified_rate(max_hp: int, cur_hp: int, catch_rate: int, ball: float, status: StringName, sneak: bool) -> float`
    returns `a` per §5.5. `status` multiplies by 2.5 for sleep/freeze and
    1.5 for paralysis, poison or burn. `sneak` multiplies by 1.5. Capped
    at 255.
  - `static func attempt(a: float, dex_caught: int, rng: RandomNumberGenerator) -> Dictionary`
    returns `{caught: bool, shakes: int, critical: bool}`.
- **Before coding:** read the Bulbapedia "Catch rate" article, Generation V
  section. Transcribe the shake-check formula for `b`, the critical-capture
  multiplier table by Pokédex count, and the critical capture's single shake
  check.
  - Record the source formula as a comment at the top of `catch_calc.gd`.
  - The tests below must match it.
  - Do not substitute the Gen III/IV or Gen VI formula.
- Gen 5's grass-darkness modifier is **not** applied (no dark grass in the
  slice).

- [ ] **Step 1:** Write the failing tests:
  - `test_full_hp_no_status_formula`: max 20, cur 20, rate 255, ball 1 →
    a = 85.
  - `test_one_hp_status_sleep`: max 20, cur 1, rate 45 → a = 45·58/60·2.5,
    within 0.5.
  - `test_cap_255_always_catches`: `caught` and `shakes == 3`.
  - `test_no_critical_under_31_caught`
  - `test_catch_rate_distribution`: for a = 45, the seeded 20,000-trial
    success rate is within ±1.5% of the closed-form probability computed from
    the transcribed `b`.
  - `test_sneak_multiplier`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `CatchCalc`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: Gen 5 catch formula with critical capture`.

### Task 26: Aim, throw and capture sequence

**Files:**
- Create: `src/capture/ball_projectile.gd`, `src/capture/throw_aim.gd`,
  `src/capture/capture_sequence.gd`
- Create: `scenes/capture/ball.tscn`
- Test: `tests/unit/test_throw_aim.gd`, `tests/unit/test_capture_sequence.gd`

**Interfaces:**
- **`class_name ThrowAim extends RefCounted`:**
  - `static func arc(origin: Vector3, target: Vector3, apex: float = 2.0) -> Dictionary`
    returns `{velocity: Vector3, time: float}`, a ballistic solve under
    gravity 9.8.
  - Maximum range is 20 m.
- **Throwing:**
  - Holding `aim` shows the arc preview; `throw` throws and consumes 1 ball
    from `GameState.items`.
  - Throwing is allowed in or out of a fight. Out of a fight at an
    unengaged wild it counts as a sneak throw.
  - It can't be thrown at a trainer's Pokémon, which bounces off with "You
    can't catch a trainer's Pokémon!"
- **`class_name CaptureSequence extends RefCounted`:** a state machine
  `absorb → shake×n → result`, 0.6 s per shake.
  - On success: emits `EventBus.pokemon_caught`, adds to `Party` (or box,
    per Task 27), records the Pokédex entry, ends the fight `caught`, and
    calls `SpawnDirector.on_removed`.
  - On failure: the Pokémon breaks out, and a fight starts if one isn't
    already running.

- [ ] **Step 1:** Write the failing tests:
  - `test_arc_lands_on_target`: simulated landing within 0.1 m.
  - `test_out_of_range_rejected`
  - `test_sequence_shake_count_matches_attempt`
  - `test_breakout_starts_fight`
  - `test_trainer_pokemon_blocked`
  - `test_no_balls_cannot_throw`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement aiming, throwing and the capture sequence.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: aimed ball throws and capture sequence`.

### Task 27: Party, boxes, inventory, level-ups, evolution, Pokémon Center (Milestone 4 build)

**Files:**
- Modify: `src/core/party.gd`
- Create: `src/core/pc_storage.gd`, `src/core/inventory.gd`
- Create: `src/ui/party_menu.gd`, `src/ui/learn_move_prompt.gd`,
  `src/ui/evolution_scene.gd`, `src/ui/bag_menu.gd`
- Create: `src/world/pokemon_center.gd`, `src/world/mart.gd`
- Test: `tests/unit/test_party.gd`, `tests/unit/test_pc_storage.gd`,
  `tests/unit/test_inventory.gd`, `tests/unit/test_progression_flow.gd`

**Interfaces:**
- **`Party`** gains:
  - `func add(c: Creature, pc: PCStorage) -> StringName`, returning
    `&"party"` or `&"box"`.
  - `func swap(i: int, j: int) -> void`
  - `func heal_all() -> void`: full HP, status cleared.
- **`class_name PCStorage extends RefCounted`:**
  - 8 boxes × 30.
  - `func deposit(c: Creature) -> Vector2i` returns (box, slot), or (-1, -1)
    if full.
- **`class_name Inventory extends RefCounted`:**
  - `func add(id, n)`, `func remove(id, n) -> bool`, `func count(id) -> int`.
  - It backs `GameState.items`.
- **Progression flow:**
  - EXP is awarded on `won` to participants (Gen 5: split among
    participants).
  - `Creature.add_exp` events are processed in order:
    - `learn` with 4 moves known opens `LearnMovePrompt` (forget one, or
      decline).
    - `evolve` opens `EvolutionScene`, which can be cancelled by holding
      `menu`.
    - A cancelled evolution re-triggers at the next level-up.
- **Pokémon Center:** Nurse Joy's interaction calls `heal_all()` and sets
  `GameState.last_center`.
- **Mart:** a buy list from data. Poké Balls are gated on the flag
  `got_pokedex`.

- [ ] **Step 1:** Write the failing tests:
  - `test_catch_with_full_party_goes_to_box`
  - `test_box_full_returns_minus_one`
  - `test_fifth_move_decline_keeps_four`
  - `test_fifth_move_replace`
  - `test_evolution_cancel_retriggers_next_level`
  - `test_exp_split_between_participants`
  - `test_center_heals_and_sets_last_center`
  - `test_inventory_remove_insufficient_false`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement storage, inventory, the progression flow and the
  UI.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: party, PC boxes, bag, level-up moves, evolution, Pokémon Center`.
- [ ] **Step 6:** Push, confirm the CI artifact, and tell the owner
  Milestone 4 is ready for review.

---

## Milestone 5: Completion

### Task 28: Save system

**Files:**
- Create: `src/core/save_service.gd` (autoload `Saves`),
  `src/core/save_migrations.gd`
- Test: `tests/unit/test_save_service.gd`

**Interfaces:**
- **Save dictionary:**
  `{version: 1, saved_at, clock: {minutes, day}, weather: {area: {current, target, blend}}, player: {pos, area, interior?: {id, outdoor_pos}}, game_state: GameState.to_dict(), party: [...], pc: [...], quests: {...}, spawns_respawn_timers: {...}}`.
- **`class_name SaveService extends Node`:**
  - `const CURRENT_VERSION := 1`
  - `func save(slot: int) -> Error`: returns `ERR_BUSY` when a fight is
    active. It writes `slot_N.json.tmp`, renames the existing `slot_N.json`
    to `slot_N.json.bak`, then renames the tmp file to `slot_N.json`.
  - `func load(slot: int) -> Dictionary` returns `{ok: bool, data, used_backup: bool}`.
    - It tries the main file, then `.bak`.
    - Each file must parse, have a `version`, and pass
      `SaveMigrations.migrate`.
  - `func autosave() -> void`: slot 0, on `EventBus.area_entered` and
    interior enter/exit, skipped during fights.
  - Saves go in `user://saves/`. On Windows that is under `%APPDATA%\Godot\app_userdata\Open World Remake\saves\`.
- **`class_name SaveMigrations`:**
  - `static func migrate(d: Dictionary) -> Dictionary` runs `_v1_to_v2` and
    so on in sequence.
  - It is empty at v1, but the loop and an unknown-future-version rejection
    are implemented.
- When `used_backup` is true, the HUD shows "Your last save was damaged; the
  previous save was loaded."

- [ ] **Step 1:** Write the failing tests:
  - `test_round_trip_full_state`
  - `test_interior_position_round_trip`
  - `test_weather_mid_transition`: restores current, target and blend.
  - `test_save_refused_in_fight`
  - `test_corrupt_main_loads_backup`
  - `test_both_corrupt_returns_not_ok`
  - `test_future_version_rejected`
  - `test_atomic_write_leaves_no_tmp`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement `SaveService` and `SaveMigrations`. Add a title
  menu with Continue, New Game and Settings.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: versioned atomic saves with backup recovery`.

### Task 29: Quests, starter, Oak's Parcel, rival battle

**Files:**
- Create: `src/quests/quest_model.gd`, `src/quests/quest_runner.gd`
- Create: `data/quests/oaks_parcel.json`, `data/quests/starter.json`
- Create: `data/trainers/rival_lab.json`, `src/ui/starter_select.gd`
- Test: `tests/unit/test_quest_model.gd`, `tests/integration/test_oaks_parcel_flow.gd`

**Interfaces:**
- **Quest record:**
  `{id, stages: [{id, objective_text, complete_when: {flag|item|talk_to|caught_count}, on_complete: {set_flags?, give_items?, take_items?, money?}}]}`.
- **`class_name QuestModel extends RefCounted`:**
  - `func _init(record: Dictionary)`
  - `func current_stage() -> Dictionary`
  - `func check(state: GameState, event: Dictionary) -> Array[Dictionary]`
    returns the `on_complete` payloads applied, and advances the stage.
  - `func to_dict() -> Dictionary`, `func from_dict(d: Dictionary) -> void`
- **Starter quest:**
  1. Leaving Pallet north without a Pokémon is blocked: Oak stops the player.
  2. Oak's Lab starter select (Bulbasaur, Charmander or Squirtle at Lv 5)
     sets `got_starter`.
  3. The rival picks the type-advantaged starter: player Bulbasaur → rival
     Charmander, Charmander → Squirtle, Squirtle → Bulbasaur.
  4. The rival battle (`skill` 0.7) follows. Losing does not black out,
     matching the main games.
- **Oak's Parcel quest** (§8):
  1. Talking to the Viridian Mart clerk gives `oaks_parcel`.
  2. Talking to Oak takes it, gives the Pokédex and 5 `poke_ball`, and sets
     `got_pokedex`.

- [ ] **Step 1:** Write the failing tests:
  - `test_stage_advances_on_flag`
  - `test_on_complete_gives_and_takes_items`
  - `test_quest_round_trip`
  - `test_rival_counterpick`: all three cases.
- [ ] **Step 2:** Write `test_oaks_parcel_flow`.
  - Script the events: starter pick, rival battle end, talk to the clerk,
    talk to Oak.
  - Assert `got_pokedex`, 5 Poké Balls, and that the Mart now lists Poké
    Balls.
- [ ] **Step 3:** Run the tests. Expected: FAIL.
- [ ] **Step 4:** Implement the quest system and authored content.
- [ ] **Step 5:** Run the tests. Expected: PASS.
- [ ] **Step 6:** Commit: `feat: quest system, starter selection, rival battle, Oak's Parcel`.

### Task 30: Settings, graphics presets UI, debug tuning

**Files:**
- Create: `src/ui/settings_menu.gd`, `scenes/ui/settings_menu.tscn`,
  `src/core/settings.gd` (autoload `Settings`)
- Create: `src/ui/debug_menu.gd`
- Test: `tests/unit/test_settings.gd`

**Interfaces:**
- **`class_name Settings extends Node`:**
  - Persists to `user://settings.cfg` (`ConfigFile`).
  - Keys: `graphics/preset` (default `&"high"`), `graphics/*` individual
    toggles, `time/rate` (12, 24, 48, 96), `time/use_real_clock: bool`,
    `audio/master|music|sfx|ambience`, `input/*`.
  - `func apply() -> void` calls `GraphicsPresets.apply`, sets `Clock.rate`,
    and sets audio bus volumes.
- **Debug menu** (F3, only when `OS.is_debug_build()` or `--debug-menu`):
  - Sliders for the live `LightingState` overrides and fog.
  - Set time, set weather, spawn species, teleport to an area.
  - It exists so the owner can tune the look on Windows and report the
    values.

- [ ] **Step 1:** Write the failing tests:
  - `test_defaults`
  - `test_persist_round_trip`
  - `test_missing_file_uses_defaults`
  - `test_invalid_value_falls_back`
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the settings and debug menus.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: settings, graphics presets UI, debug tuning menu`.

### Task 31: Slice integration and performance pass (Milestone 5 build)

**Files:**
- Create: `tests/integration/test_slice_walkthrough.gd`,
  `tools/perf_probe.gd`, `docs/playtest-checklist.md`

**Interfaces:**
- Consumes everything above.

- [ ] **Step 1:** Write `test_slice_walkthrough`. A scripted run:
  1. New game.
  2. Pick a starter.
  3. Beat the rival.
  4. Walk Pallet → Route 1 → Viridian, entering and exiting the Center.
  5. Get the parcel, return to Oak, walk back to the forest.
  6. Catch one wild Pokémon by forcing `CatchCalc` with a seeded RNG.
  7. Save, reload, and assert the state is equal.
  8. Advance the clock to 23:00 and assert the night spawn table and night
     NPC counts.
- [ ] **Step 2:** Run the test, then fix integration defects until it passes.
  Each fix goes in the task file that owns the code, with a regression test.
- [ ] **Step 3:** Add `tools/perf_probe.gd`.
  - The `--perf` flag runs a 120 s camera fly-through over Viridian at noon
    in rain.
  - It writes min/avg/p99 frame times to `user://logs/perf.json`.
  - Document in `docs/playtest-checklist.md` how the owner runs it on
    Windows. The 60 fps target cannot be measured in the container.
- [ ] **Step 4:** Write `docs/playtest-checklist.md` with every item of spec
  §3 as a checkbox for the owner.
- [ ] **Step 5:** Run `tools/test.sh` and the validator. Expected: all pass.
- [ ] **Step 6:** Commit: `test: end-to-end slice walkthrough, perf probe, playtest checklist`.
- [ ] **Step 7:** Push, confirm the CI artifact, and give the owner the
  Milestone 5 build along with the playtest checklist.
