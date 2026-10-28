# Implementation decisions log

Every judgement call made while building the Kanto slice, in order, with what it costs if wrong.
Source: the execution ledger. "Deferred minors" are known small issues left for later.

## Rulings

- **Pre-flight:** add `areas` kind to DataDB kinds — spec silent, plan T4 creates data/areas.json — cost: none
- **Task 1:** GUT fetched via git clone of tag v9.6.1 (GitHub archive zips 403 through proxy) — same content — cost: none
- **Task 1:** smoke test is environment check, not watched RED — scaffold/config exception — cost: none
- **Task 1:** export include_filter=data/* so JSON content ships in PCK — required for DataDB at runtime — cost: none
- **Task 2:** added kinds areas, lighting, ambience, schema to DataDB.KINDS — later tasks create those data files — cost: none
- **Task 2:** test.sh re-imports when sources are newer than the class cache — new class_name scripts otherwise unresolved headless — cost: ~8s per changed run
- **Task 3:** ClockModel.set_from_system returns crossed events (plan said void) — GameClock needs the same events in real-clock mode — cost: none. Added ClockModel.period() helper
- **Task 4:** weather state is per weather table (areas map to tables via areas.json); weather_changed emits table id — adjacent areas sharing a table share weather, which reads naturally — cost if wrong: per-area models later, small. Added start_transition/tick/to_dict/from_dict to WeatherModel (needed by director and Task 28)
- **Task 5:** placeholder sheets are colored silhouettes without the species name text — drawing text into Image needs a font rasterizer; names show in UI instead — cost: placeholders less identifiable, cosmetic
- **Task 5:** reject files without PNG/JPG/WebP signature before decoding — avoids engine error spam for corrupt files — cost: none. In editor runs, user_assets is res://user_assets
- **Task 6:** added pure ChunkBaker class (bake tool is a thin wrapper) and PropFactory — makes baking testable — cost: none
- **Task 6:** terrain is stepped per cell; test renamed test_height_at_returns_cell_level (plan said interpolates) — Kanto ledges/cliffs are steps; smooth hills can come later as slope tiles — cost: no smooth slopes in slice
- **Task 6:** tileset is data kind 'tileset' keyed by char; added tiles d(dirt) w(fence) r(rock)
- **Task 6:** ledge = solid strip on the cell's north edge in group 'ledge'; the player hops south over it (Task 7) — cost: none
- **Task 7:** input_setup.gd is class InputSetup with static register(); camera follow done in HD2DCamera._physics_process with snap() — cost: none
- **Task 8:** color grades are data-defined 3-stop gradients (GradientTexture1D) in data/lighting.json instead of LUT PNGs — editable as text — cost: less precise grading than 3D LUTs
- **Task 8:** screenshot step moved to Task 9 (no world yet); lavapipe (mesa-vulkan-drivers) installed in container so screenshots are possible. GraphicsPresets also carries dof_enabled()/npc_cap()
- **Task 9:** added 'S' stairs ramp tile — stepped terrain otherwise makes ledged Route 1 impassable northbound — cost: none
- **Task 9:** camera distance 22→42 m, combat 16→32 m (tests updated) — screenshots at 22 m showed ~12 m of world, far too zoomed for open world — cost: owner may want closer; it's an export var
- **Task 9:** DOF off by default on Low/Medium/High (Ultra keeps it), near blur removed, far blur 70 m — under lavapipe DOF blurred the whole frame and I cannot verify on a real GPU — cost: no tilt-shift look unless owner enables Ultra; flagged for owner review
- **Task 9:** Pallet has 11 buildings incl. fishing shack; Pallet/Route1 doors are 'pending' except player/rival/lab ('always', interiors in Task 11). Screenshots possible via xvfb + lavapipe (~25-120 s per frame)
- **Task 10:** no WorkerThreadPool — building collision/GridMap nodes off-thread crashed (exit 134) and raised GridMap errors; preload ring is built on main thread one chunk/frame (~10 ms here after caching shared meshes/shapes) — cost: a ~3-5 ms hitch per chunk on a PC; revisit with data-only threading if profiling shows stutter. M1 world test now asserts ≥6 streamed chunks (3x3 around spawn) instead of all chunks. Area tracking moved from KantoWorld to WorldStreamer
- **Task 11:** GameState autoload is named 'State' — Godot forbids an autoload sharing its class_name — cost: none
- **Task 11:** DoorUnlock.evaluate takes 4th param has_interior (default true) — needed for 'missing interior = pending' — cost: none
- **Task 11:** interior templates live in data/interior_templates/ (own kind) — data/interiors/ subdirs are not scanned — cost: none
- **Task 11:** interiors are built at y=1000 while the overworld is hidden and its chunks pinned; doors trigger on walking north into them (exits on walking south) via DoorController; locked text via new EventBus.message + MessageToast. Pallet: 7 enterable (player, rival, lab, house_2, house_4 always; café 8-20; greenhouse after got_pokedex), 4 pending. Player gains last_input/forced_input
- **Task 12:** wetness test values — plan's '30 s rain then 60 s dry ≈ 0.25' contradicts its own 60 s wet / 120 s dry rates (gives 0); test uses 60 s rain → 1.0, 60 s dry → 0.5 — cost: none
- **Task 12:** wetness darkens/smooths the shared tile StandardMaterials directly instead of a shader include/global uniform — all terrain uses StandardMaterial3D — cost: props/buildings don't get wet. Lightning = LightingDirector.flash(). Bug fixed with regression test: WeatherFx missed the initial area_entered
- **Task 13:** species/move facts imported from PokeAPI (tools/import_species.py) instead of hand-typed — fewer transcription errors; Gen 6/7 stat buffs reverted for Butterfree, Beedrill, Pikachu, Volbeat, Illumise; move values rolled back via past_values — cost if wrong: a stat off by a Gen; source recorded per record
- **Task 13:** learnsets capped at Lv 30 and every referenced move (98) imported now with default real-time fields, since the validator requires learnset moves to exist — Task 21 tunes shapes — cost: none
- **Task 13:** Creature.from_dict(d, db) takes the DataDB — stats need species data — cost: none. Evolutions beyond the slice roster omitted. Added Creature.pending_evolution for cancel/retry (Task 27)
- **Task 14:** between ACTIVE_MIN and ACTIVE_MAX the director tops up with 25% chance per tick (spec gives 8-12 but no fill rule) — cost: tunable const
- **Task 14:** a zone with a pending respawn timer is blocked until it expires; distance despawns also start a timer; game_minutes is monotonic (day*1440+min) so midnight needs no special case. SpawnTable takes a nocturnal set (enforced regardless of data); validator now rejects unknown/ambient-only spawn species and zones pointing at missing tables
- **Task 15:** aggressive/territorial also charge when attacked (spec only names passive) — reads naturally — cost: none. Wild move speed = 2 + Spe/40 m/s. Overworld spawner/NPC/ambient nodes pause while indoors
- **Task 16:** no navmesh baking — per-chunk bake would add tens of ms to every chunk build; NPCs steer directly with slide and snap to goal when stuck off-camera; anchors are authored on open ground — cost: NPCs may visibly hug walls; revisit with NavigationRegion3D if it looks bad in playtest
- **Task 16:** an NPC 'home' is a door id (indexed with anchors at 1.2 m in front of the door) — cost: none. Default weather behaviour: rain=umbrella, thunderstorm=indoors. NPCManager.setup takes a factory Callable for testability
- **Task 17:** '≥3 lines with distinct when contexts' validated as ≥3 distinct when-signatures across barks+talk — cost: authors must write context variants (intended). Validator also checks NPC schedule/home/companion and schedule anchors (only when chunk data exists). Branch choices may carry set_flag, next (node) or reply. Added EventBus.npc_talked for quests
- **Task 18:** flocks resettle within 20 s (8 s flight + return) rather than starting the return at 20 s — matches 'resettle after 20 s' as completion — cost: none
- **Task 18:** window silhouettes are static (1 in 3 buildings, shown when lamps are on), not animated — cost: less life at night. Ambient effects are props (flock/drifters/laundry) so they stream with chunks; chimney smoke on houses/barn. Companion share validated per town area (ambience 'town')
- **Task 19:** forest entrance is an open path beside an enterable gatehouse (not a pass-through building) — avoids a two-door interior hop — cost: less canon-faithful
- **Task 19:** content is generated by tools/content/*.py (committed) and their output JSON/TXT committed; NPC bark lines for time/weather/flag contexts come from shared pools, talk lines are per-NPC — cost: some repeated barks across NPCs
- **Task 19:** bug-catcher hideout gated by reward pokedex_caught>=10; Gym gated by flag viridian_gym_open (never set in slice). Viridian has 25 buildings (11/22 Pallet+Viridian homes enterable). Interior NPCs (Oak, clerk, Joy) are listed on interiors; spawning them indoors comes with Task 29. Added --at=<anchor> dev flag
- **Task 20:** thunderstorm counts as rain for Water/Fire boosts; 'sun' supported but no slice weather produces it — cost: none
- **Task 20:** modifiers floored per step (plan) rather than Gen 5's 4096-scale pokeRound — results match for the pinned cases; can differ by 1 HP elsewhere — cost: off-by-one vs cartridge in rare cases
- **Task 21:** MoveExecutor is a pure timeline (wind-up/active/recovery events); spawning projectile visuals and applying Damage moves to the fight controller (Task 23) — keeps it unit-testable — cost: none
- **Task 21:** shapes assigned by tools/tune_moves.py heuristics (powders=area at 3.5 m, sounds=area around user, self-targeting status=self, contact physical=melee arc, priority melee lunges 4.5 m) — cost: some moves feel off until hand-tuned; files are editable. Accuracy scales arcs/radii to 50-100%; windup_s override is not speed-scaled
- **Task 22:** dodging requires being able to act (not asleep/frozen/stunned); a status already present is never overwritten (main-series rule) — cost: none. Sleep/freeze timers re-roll when a fight starts with a carried-over status (timer INF until apply)
- **Task 23:** when the active Pokémon faints the next able one is sent out automatically (normal 1.5 s switch) — no menu in the slice — cost: player can't pick the replacement
- **Task 23:** escape uses the controlled Pokémon's distance from the ring centre — you steer the Pokémon, not the trainer
- **Task 23:** melee/beam aim gets a 30° soft aim-assist toward the foe — keyboard aiming is coarse — cost: slightly easier hits
- **Task 23:** Party lives on State.party (saved separately by Task 28). Fight flow integration tests were written after FightController (model tests were RED-first) — cost: weaker proof those 5 can fail. A wild still in a fight is never despawned by distance
- **Task 24:** CombatAI takes chart/db/rng in its constructor; decide(me, my_pos, foe, foe_pos, ready, skill) — cost: none
- **Task 24:** trainer prize money = 16 x highest level (Bug Catcher Gen 5 base payout) — cost: approximate. Bug Catcher parties follow Red/Blue/Yellow Viridian Forest trainers. Trainer facing comes from npc.facing (default down)
- **Task 25:** Bulbapedia blocked direct fetch (403); Gen 5 formula taken from search-result summaries of Bulbapedia's Catch rate/Talk pages: b = floor(65536/(255/a)^(1/4)), 3 shake checks, critical c = floor(min(255,a)*dex_mult/6)/256 with one check; sources conflicted on 3/16 vs 1/4 — 3/16 attributed to Gen 6 — cost if wrong: catch odds a few % off; formula is isolated in catch_calc.gd. Worked on the 0-255 scale rather than Gen 5's 4096-scaled integers — cost: rounding differences
- **Task 26:** balls are thrown by the trainer avatar at the wild nearest the aim direction (35° cone) with an arc preview — keyboard aiming of a free target is impractical — cost: less skill expression
- **Task 26:** throwing at a Trainer's Pokémon is refused without using the ball. Breakouts make the wild hostile and start a fight. State.give_pokemon added (party only; PC overflow in Task 27). FightController guards against the foe being freed mid-frame
- **Task 27:** evolution can be cancelled via a Continue/Stop prompt (no hold-to-cancel animation scene) — cost: less ceremony
- **Task 27:** interior residents (Joy, clerk, Oak, Mom…) spawn at template npc_spots when an interior is built; NPCs carry a 'service' (heal/mart) handled in KantoWorld.talk_to; Mom heals at home (last_center pallet_home) as in the main games. Party/bag/money share one 'menu' panel; 1-6 moves a Pokémon to the lead. Added viridian_center_front anchor (blackout return point)
- **Task 28:** SaveService.save(slot, data) takes a snapshot built by KantoWorld.snapshot_world() (plan: save(slot) gathered state itself) — keeps the service testable without a world — cost: none
- **Task 28:** load is load_slot() (load is a GDScript builtin)
- **Task 28:** title menu is a Continue/New Game prompt over the world, Settings comes in Task 30; F5 = manual save into the autosave slot. Spawn respawn timers are saved/restored
- **Task 29:** rival is 'Blue' (Red/Blue default) and battles inside Oak's Lab right after the starter pick; losing heals, costs nothing and still sets rival_lab_done (no_blackout trainers set their flag either way) — matches the main games — cost: none
- **Task 29:** Oak's north-exit block is a z threshold at Pallet's north edge (pushes back 5 m with Oak's line) rather than an Oak walk-up cutscene — cost: less cinematic. Quests: starter (2 stages) and oaks_parcel (requires got_starter). QuestRunner saved via KantoWorld.quest_state()
- **Task 30:** settings class is GameSettings (autoload Settings) — autoload/class name clash — cost: none
- **Task 30:** menus are keyboard panels (F2 settings, F3 debug) rather than slider widgets; input rebinding not exposed in the slice — cost: no remapping UI. Tilt-shift DOF is a settings toggle (off by default per Task 9 ruling)
- **Task 31:** the walkthrough teleports between anchors instead of walking every metre (streaming is covered by test_streaming_walk) — cost: none. Perf probe verified headless (≈7 ms/frame CPU in container); under lavapipe the first rainy Viridian frame takes minutes, so the 60 fps target can only be measured on the owner's PC. Export --selftest confirms data/ ships in the PCK (24 species, 98 moves, 40 chunks, 74 NPCs, 0 validator errors)
- **Final:** Gen 5 shake exponent (reviewer declined) — kept fourth root per sources, isolated in catch_calc.gd — cost: catch odds a few % off if wrong
- **Final:** controller A stays shared by Talk and Move 1, with talking taking priority — no free face button — cost: pad players start fights with X/Y/RB or by being charged

## Deferred minors

- duplicate evolution prompts when gaining 2+ levels past evolution level in one fight
- catch message says "sent to the PC" even when the PC is full (240 slots)
- real-clock mode treats a backward clock change (DST) as +1 day
- debug-menu teleport while inside a building errors
- EXP split/trainer bonus applied after +1 (off by ≤1 EXP vs Gen 5)
- weather reroll hour counter not saved
- save validation only checks shape/version, not content
