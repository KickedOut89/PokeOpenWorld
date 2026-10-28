#!/usr/bin/env python3
"""Imports Gen 5 (Black/White) species and move facts from PokeAPI into data/.

Usage: python3 -I tools/import_species.py
Writes data/species/<id>.json and data/moves/<id>.json. Hand-tuned real-time move
fields (shape, range, windup...) in existing move files are preserved.
"""
import json, os, sys, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://pokeapi.co/api/v2/"
MAX_LEARN_LEVEL = 30

# Slice species: id -> (temperament, nocturnal, ambient_only, in-slice evolution targets only)
SPECIES = {
    "bulbasaur": ("territorial", False, False), "ivysaur": ("territorial", False, False),
    "charmander": ("aggressive", False, False), "charmeleon": ("aggressive", False, False),
    "squirtle": ("territorial", False, False), "wartortle": ("territorial", False, False),
    "pidgey": ("timid", False, False), "pidgeotto": ("territorial", False, False),
    "rattata": ("aggressive", False, False), "raticate": ("aggressive", False, False),
    "sentret": ("timid", False, False), "hoothoot": ("passive", True, False),
    "caterpie": ("passive", False, False), "metapod": ("passive", False, False),
    "butterfree": ("timid", False, False), "weedle": ("aggressive", False, False),
    "kakuna": ("passive", False, False), "beedrill": ("aggressive", False, False),
    "pikachu": ("timid", False, False), "oddish": ("passive", True, False),
    "volbeat": ("passive", True, True), "illumise": ("passive", True, True),
    "meowth": ("timid", False, True), "growlithe": ("territorial", False, True),
}
# Gen 6 raised these base stats; restore Gen 5 values.
GEN5_STAT_OVERRIDES = {
    "butterfree": {"spa": 80}, "beedrill": {"atk": 80},
    "pikachu": {"def": 30, "spd": 40},
    # Gen 7 raised these two by +20 Def and +10 SpD.
    "volbeat": {"def": 55, "spd": 75}, "illumise": {"def": 55, "spd": 75},
}
EXTRA_MOVES = ["thunder-shock", "quick-attack", "ember", "water-gun", "vine-whip"]
GEN5_OR_EARLIER = {"red-blue", "yellow", "gold-silver", "crystal", "ruby-sapphire", "emerald",
    "firered-leafgreen", "colosseum", "xd", "diamond-pearl", "platinum", "heartgold-soulsilver",
    "black-white", "black-2-white-2"}
GROWTH = {"slow": "slow", "medium": "medium_fast", "fast": "fast", "medium-slow": "medium_slow",
    "slow-then-very-fast": "erratic", "fast-then-very-slow": "fluctuating"}
STAT = {"hp": "hp", "attack": "atk", "defense": "def", "special-attack": "spa", "special-defense": "spd", "speed": "spe"}
CACHE = {}


def get(path):
    url = path if path.startswith("http") else API + path
    if url not in CACHE:
        req = urllib.request.Request(url, headers={"User-Agent": "OpenWorldRemake-importer/1.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            CACHE[url] = json.loads(r.read().decode("utf-8"))
    return CACHE[url]


def sid(name):
    return name.replace("-", "_")


def vg_id(url):
    return int(url.rstrip("/").split("/")[-1])


def species_record(name):
    temperament, nocturnal, ambient = SPECIES[name]
    p = get("pokemon/" + name)
    s = get("pokemon-species/" + name)
    base = {STAT[x["stat"]["name"]]: x["base_stat"] for x in p["stats"]}
    base.update(GEN5_STAT_OVERRIDES.get(name, {}))
    ev = {STAT[x["stat"]["name"]]: x["effort"] for x in p["stats"] if x["effort"] > 0}
    types = [t["type"]["name"] for t in sorted(p["types"], key=lambda t: t["slot"])]
    if "fairy" in types:
        raise SystemExit(name + ": fairy type has no Gen 5 equivalent; handle manually")
    learn = []
    for m in p["moves"]:
        for d in m["version_group_details"]:
            if d["version_group"]["name"] == "black-white" and d["move_learn_method"]["name"] == "level-up":
                lvl = max(1, d["level_learned_at"])
                if lvl <= MAX_LEARN_LEVEL:
                    learn.append([lvl, sid(m["move"]["name"])])
    learn.sort(key=lambda e: (e[0], e[1]))
    evolves = []
    chain = get(s["evolution_chain"]["url"])["chain"]
    def walk(node):
        if node["species"]["name"] == name:
            for nxt in node["evolves_to"]:
                to = nxt["species"]["name"]
                det = nxt["evolution_details"][0] if nxt["evolution_details"] else {}
                if to in SPECIES and det.get("trigger", {}).get("name") == "level-up" and det.get("min_level"):
                    evolves.append({"to": to, "level": det["min_level"]})
        for nxt in node["evolves_to"]:
            walk(nxt)
    walk(chain)
    rec = {"id": name, "name": s["names"] and next(n["name"] for n in s["names"] if n["language"]["name"] == "en"),
        "dex": s["id"], "types": types, "base": base, "catch_rate": s["capture_rate"],
        "base_exp": p["base_experience"], "growth": GROWTH[s["growth_rate"]["name"]], "ev_yield": ev,
        "learnset": learn, "evolves": evolves, "temperament": temperament,
        "gender_ratio": s["gender_rate"], "source": "PokeAPI (Gen 5 Black/White learnset)"}
    if nocturnal: rec["nocturnal"] = True
    if ambient: rec["ambient_only"] = True
    return rec


def move_record(name):
    m = get("move/" + name)
    vals = {"power": m["power"], "pp": m["pp"], "accuracy": m["accuracy"], "type": m["type"]["name"]}
    later = [pv for pv in m.get("past_values", []) if pv["version_group"]["name"] not in GEN5_OR_EARLIER]
    for pv in sorted(later, key=lambda pv: vg_id(pv["version_group"]["url"]), reverse=True):
        for k in ("power", "pp", "accuracy"):
            if pv.get(k) is not None: vals[k] = pv[k]
        if pv.get("type"): vals["type"] = pv["type"]["name"]
    if vals["type"] == "fairy":
        vals["type"] = "normal"
    cat = m["damage_class"]["name"]
    meta = m.get("meta") or {}
    rec = {"id": sid(name), "name": next(n["name"] for n in m["names"] if n["language"]["name"] == "en"),
        "type": vals["type"], "category": cat, "power": vals["power"] or 0, "pp": vals["pp"] or 10,
        "accuracy": vals["accuracy"] or 100, "priority": m["priority"],
        "shape": {"physical": "melee_arc", "special": "projectile", "status": "self"}[cat],
        "range": {"physical": 2.5, "special": 12.0, "status": 0.0}[cat], "active_s": 0.15,
        "source": "PokeAPI (Gen 5 values)"}
    ail = (meta.get("ailment") or {}).get("name", "none")
    if ail in ("paralysis", "sleep", "poison", "burn", "freeze") and meta.get("ailment_chance", 0) >= 0:
        rec["status"] = {"id": {"paralysis": "par", "sleep": "slp", "poison": "psn", "burn": "brn", "freeze": "frz"}[ail],
            "chance": (meta.get("ailment_chance") or 100) / 100.0}
    changes = m.get("stat_changes") or []
    if changes:
        c = changes[0]
        target = "self" if m["target"]["name"] in ("user", "users-field", "user-and-allies") else "foe"
        rec["stat_change"] = {"target": target, "stat": STAT.get(c["stat"]["name"], c["stat"]["name"]), "stages": c["change"]}
    return rec


def main():
    os.makedirs(os.path.join(ROOT, "data/species"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "data/moves"), exist_ok=True)
    moves = set(sid(x) for x in EXTRA_MOVES)
    for name in SPECIES:
        rec = species_record(name)
        moves.update(e[1] for e in rec["learnset"])
        json.dump(rec, open(os.path.join(ROOT, "data/species", name + ".json"), "w"), indent=1)
        print("species", name, rec["base"], "learn", len(rec["learnset"]))
    keep = ("shape", "range", "arc_deg", "radius", "speed", "windup_s", "active_s", "recovery_s", "cooldown_override", "tuned")
    for mid in sorted(moves):
        path = os.path.join(ROOT, "data/moves", mid + ".json")
        rec = move_record(mid.replace("_", "-"))
        if os.path.exists(path):
            old = json.load(open(path))
            for k in keep:
                if k in old: rec[k] = old[k]
        json.dump(rec, open(path, "w"), indent=1)
    print("moves", len(moves))


if __name__ == "__main__":
    main()
