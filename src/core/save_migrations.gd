class_name SaveMigrations
extends RefCounted
## Upgrades old save dictionaries step by step to SaveService.CURRENT_VERSION.
## Add `_v1_to_v2` etc. here when the format changes. Unknown future versions are rejected.


static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 0))
	if v < 1 or v > SaveService.CURRENT_VERSION:
		return {}
	while v < SaveService.CURRENT_VERSION:
		match v:
			_:
				return {}
		v += 1
	return d
