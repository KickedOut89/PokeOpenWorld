class_name TypeChart
extends RefCounted
## Gen 2-5 type effectiveness (17 types, no Fairy). Data: data/types.json chart = {defender: mult}.

var _chart: Dictionary = {}


static func from_db(db: DataDB) -> TypeChart:
	var t := TypeChart.new()
	for id in db.table(&"types"):
		var row := {}
		var chart: Dictionary = db.table(&"types")[id].get("chart", {})
		for d in chart:
			row[StringName(d)] = float(chart[d])
		t._chart[StringName(id)] = row
	return t


func types() -> Array:
	return _chart.keys()


func mult(atk_type: StringName, def_types: Array) -> float:
	var row: Dictionary = _chart.get(atk_type, {})
	var m := 1.0
	for d in def_types:
		m *= float(row.get(StringName(d), 1.0))
	return m
