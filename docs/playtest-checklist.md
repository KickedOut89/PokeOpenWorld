# Kanto Slice — Playtest Checklist (Windows)

Download the latest **OpenWorldRemake-windows** artifact from the GitHub Actions tab,
unzip it, and run `OpenWorldRemake.exe`. Tick each box and note anything that feels off.

## Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move / run | WASD or arrows / Shift | Left stick / L3 |
| Talk, enter doors | E or Enter; walk up into a door | A (talking takes priority over Move 1) |
| Moves 1-4 (in a fight) | 1 2 3 4 | A X Y RB |
| Dodge-roll | Space | B |
| Switch Pokémon | Tab | LB |
| Aim / throw Poké Ball | Hold right mouse / left click or F | LT / RT |
| Party, bag, money | Esc | Start |
| Answer a question | Up/Down + Enter, or number keys; Esc = last option (no / leave) | D-pad + A; B = last option |
| Settings | F2 | — |
| Save | F5 (also autosaves on area change and doors) | — |
| Debug tuning (debug builds) | F3 | — |

## Spec §3 success criteria

- [ ] 1. Walk from Pallet Town to Viridian Forest with no outdoor loading screens; interiors fade briefly.
- [ ] 2. Wild Pokémon are visible in tall grass, roam, respawn, and change with place, time and weather
      (Hoothoot at night, Sentret by day, more Pikachu in storms in the forest).
- [ ] 3. Day/night and weather run continuously and change lighting, NPC behaviour and spawns.
- [ ] 4. Towns feel inhabited: residents follow daily routines, carry umbrellas or go indoors in rain,
      walk with their Pokémon, and say context lines as you pass.
- [ ] 5. Fight, weaken and catch a wild Pokémon in real time; gain EXP, level up, learn a move, evolve.
- [ ] 6. Pick a starter from Oak, battle the rival, fetch Oak's Parcel from the Viridian Mart, get the Pokédex.
- [ ] 7. Save, quit, Continue — you return to the same place (even inside a building).
- [ ] 8. Performance: run `OpenWorldRemake.exe -- --perf` (from a terminal in the unzipped folder).
      After 120 s it writes `%APPDATA%\Godot\app_userdata\Open World Remake\logs\perf.json`.
      Target: **avg_fps ≥ 60** and **p99_ms ≤ 25** at 1080p on the High preset.
      Paste the file contents back to Claude.
- [ ] 9. CI is green on the latest commit (Actions tab).

## Look and feel (please comment freely)

- [ ] Camera distance and angle (currently 42 m, 35° pitch, FOV 30)
- [ ] Brightness/contrast at morning, noon, evening, night
- [ ] Fog thickness in the forest and during rain
- [ ] Tilt-shift depth of field: try it via F2 → 2 (off by default — it could not be tuned without a GPU)
- [ ] Combat feel: move wind-ups, cooldown lengths, dodge timing, enemy aggression
- [ ] Catch difficulty
- [ ] Anything that looks broken (NPCs stuck on walls, Pokémon floating, lighting pops)

Use F3 → PgUp/PgDn (time), W (weather), X/Z (exposure), F/V (fog) and report the values it prints
for any time of day that looks wrong.
