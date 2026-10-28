extends Node
## Autoload `Weather`: one WeatherModel per weather table, re-rolled every N game hours.

var models: Dictionary = {}  # table id -> WeatherModel
var _rng := RandomNumberGenerator.new()
var _hours_since: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	var tables := Data.db.table(&"weather")
	for id in tables:
		var m := WeatherModel.new(tables[id], _rng)
		m.current = m.roll()
		m.target = m.current
		models[id] = m
		_hours_since[id] = 0
	EventBus.hour_changed.connect(_on_hour)


func model_for_area(area: StringName) -> WeatherModel:
	var table: StringName = StringName(Data.db.get_record(&"areas", area).get("weather_table", ""))
	return models.get(table, null)


func weather_for_area(area: StringName) -> StringName:
	var m := model_for_area(area)
	return m.current if m != null else &"clear"


func _process(delta: float) -> void:
	for id in models:
		var m: WeatherModel = models[id]
		var was := m.current
		m.tick(delta)
		if m.current != was:
			EventBus.weather_changed.emit(id, m.current)


func _on_hour(_hour: int) -> void:
	for id in models:
		_hours_since[id] += 1
		var m: WeatherModel = models[id]
		if _hours_since[id] >= m.reroll_hours:
			_hours_since[id] = 0
			var next := m.roll()
			if next != m.current:
				m.start_transition(next)
