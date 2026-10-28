class_name AmbiencePlayer
extends Node
## Plays ambient loops for the current area/period/weather, crossfading over 3 s.

const FADE := 3.0
const SILENT_DB := -60.0

var mixer: AmbienceMixer
var area: StringName = &""
var indoors: bool = false
var _players: Dictionary = {}  # layer -> AudioStreamPlayer


func _ready() -> void:
	mixer = AmbienceMixer.new(Data.db.get_record(&"ambience", &"ambience"))
	EventBus.area_entered.connect(func(a: StringName) -> void: area = a)


func _process(delta: float) -> void:
	var w := Weather.weather_for_area(area)
	var amb := StringName(Data.db.get_record(&"areas", area).get("ambience", ""))
	var want := {} if indoors else mixer.layers(amb, Clock.model.period(), w)
	for layer in want:
		if not _players.has(layer):
			var p := AudioStreamPlayer.new()
			p.stream = Assets.audio("sfx/amb_%s" % layer)
			p.volume_db = SILENT_DB
			p.bus = &"Master"
			add_child(p)
			p.play()
			_players[layer] = p
	var step := (SILENT_DB * -1.0) / FADE * delta
	for layer in _players:
		var p: AudioStreamPlayer = _players[layer]
		var target: float = want.get(layer, SILENT_DB)
		if target > SILENT_DB:
			target += linear_to_db(maxf(0.001, float(Settings.get_value("audio/ambience"))))
		p.volume_db = move_toward(p.volume_db, target, step)
