class_name CatchCalc
extends RefCounted
## Gen 5 capture (Black/White), written on the 0-255 scale:
##   a = ((3*HPmax - 2*HPcur) * rate * ball / (3*HPmax)) * status   (capped at 255)
##   status: sleep/freeze x2.5, paralysis/poison/burn x1.5
##   b = floor(65536 / (255/a)^(1/4)); THREE shake checks, each passes if rand(0..65535) < b
##   critical capture: c = floor(min(255,a) * dex_mult / 6); triggers if rand(0..255) < c,
##   then a single shake check decides the catch.
##   dex_mult by species caught: <=30 x0, 31-150 x0.5, 151-300 x1, 301-450 x1.5, 451-600 x2, >600 x2.5
## Sources: Bulbapedia "Catch rate" (Gen V section) as summarised in search results; Gen VI's
## 3/16 exponent and four checks are deliberately not used. The dark-grass modifier is not
## applied (no dark grass in the slice). "sneak" (x1.5) is this game's addition.

const SHAKE_CHECKS := 3


static func modified_rate(max_hp: int, cur_hp: int, catch_rate: int, ball: float, status: StringName, sneak: bool) -> float:
	var a := (3.0 * max_hp - 2.0 * cur_hp) * catch_rate * ball / (3.0 * max_hp)
	match status:
		&"slp", &"frz":
			a *= 2.5
		&"par", &"psn", &"brn":
			a *= 1.5
	if sneak:
		a *= 1.5
	return clampf(a, 0.0, 255.0)


static func dex_multiplier(caught: int) -> float:
	if caught > 600:
		return 2.5
	if caught > 450:
		return 2.0
	if caught > 300:
		return 1.5
	if caught > 150:
		return 1.0
	if caught > 30:
		return 0.5
	return 0.0


static func shake_threshold(a: float) -> int:
	if a >= 255.0:
		return 65536
	if a <= 0.0:
		return 0
	return int(floor(65536.0 / pow(255.0 / a, 0.25)))


static func attempt(a: float, dex_caught: int, rng: RandomNumberGenerator) -> Dictionary:
	var b := shake_threshold(a)
	var c := int(floor(minf(255.0, a) * dex_multiplier(dex_caught) / 6.0))
	if c > 0 and rng.randi_range(0, 255) < c:
		var ok := rng.randi_range(0, 65535) < b
		return {"caught": ok, "shakes": 1 if ok else 0, "critical": true}
	var shakes := 0
	for i in SHAKE_CHECKS:
		if rng.randi_range(0, 65535) < b:
			shakes += 1
		else:
			break
	return {"caught": shakes == SHAKE_CHECKS, "shakes": shakes, "critical": false}
