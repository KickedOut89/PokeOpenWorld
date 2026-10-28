#!/usr/bin/env python3
"""Assigns real-time combat fields (shape/range/arc/radius/speed) to imported moves.

Usage: python3 -I tools/tune_moves.py
Only fills fields that are missing, so hand edits in data/moves/*.json win.
"""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOVES = os.path.join(ROOT, "data/moves")

RANGED_PHYSICAL = {"poison_sting", "twineedle", "pin_missile", "rock_throw", "bullet_seed", "seed_bomb", "sand_tomb",
                   "rock_tomb", "bone_club", "razor_leaf", "magical_leaf"}
BEAMS = {"psybeam", "aurora_beam", "bubble_beam", "solar_beam", "hyper_beam", "signal_beam", "flamethrower", "hydro_pump", "water_pulse"}
POWDERS = {"sleep_powder", "stun_spore", "poison_powder", "sweet_scent", "spore", "cotton_spore"}
SOUNDS = {"growl", "supersonic", "uproar", "sing", "screech", "roar", "hyper_voice", "echoed_voice", "round"}
AREA_SELF = {"twister", "discharge", "earthquake", "surf", "petal_dance", "whirlwind", "magnitude"}


def tune(m):
    mid = m["id"]
    cat = m["category"]
    target_self = m.get("stat_change", {}).get("target") == "self"
    if mid in POWDERS:
        d = {"shape": "area", "range": 3.5, "radius": 2.5}
    elif mid in SOUNDS or mid in AREA_SELF:
        d = {"shape": "area", "range": 0.0, "radius": 5.5 if mid in SOUNDS else 4.0}
    elif cat == "status" and (target_self or "status" not in m and "stat_change" not in m):
        d = {"shape": "self", "range": 0.0}
    elif cat == "status":
        d = {"shape": "projectile", "range": 8.0, "speed": 14.0, "radius": 0.8}
    elif mid in BEAMS:
        d = {"shape": "beam", "range": 11.0, "radius": 0.6}
    elif cat == "physical" and mid not in RANGED_PHYSICAL:
        d = {"shape": "melee_arc", "range": 2.5, "arc_deg": 100.0}
    else:
        d = {"shape": "projectile", "range": 12.0, "speed": 18.0 if m["type"] == "electric" else 15.0, "radius": 0.7}
    if m.get("priority", 0) >= 1 and d["shape"] == "melee_arc":
        d["range"] = 4.5  # dash attacks like Quick Attack lunge further
    for k, v in d.items():
        m[k] = v
    m.setdefault("active_s", 0.15)
    return m


for f in sorted(os.listdir(MOVES)):
    if not f.endswith(".json"):
        continue
    p = os.path.join(MOVES, f)
    m = json.load(open(p))
    if m.get("tuned"):
        continue
    m = tune(m)
    m["tuned"] = True
    json.dump(m, open(p, "w"), indent=1)
print("tuned")
