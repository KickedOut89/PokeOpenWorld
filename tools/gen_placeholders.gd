extends SceneTree
## Generates original placeholder art into res://assets/placeholder/.
## Sprite sheets: 3 frames x 4 directions (rows: down, left, right, up), 48x64 px per frame.
## Species sheets are tinted by primary type; re-run after adding species data.

const OUT := "res://assets/placeholder"
const FRAME := Vector2i(48, 64)
const TYPE_COLORS := {
	"normal": Color("a8a878"), "fire": Color("f08030"), "water": Color("6890f0"),
	"electric": Color("f8d030"), "grass": Color("78c850"), "ice": Color("98d8d8"),
	"fighting": Color("c03028"), "poison": Color("a040a0"), "ground": Color("e0c068"),
	"flying": Color("a890f0"), "psychic": Color("f85888"), "bug": Color("a8b820"),
	"rock": Color("b8a038"), "ghost": Color("705898"), "dragon": Color("7038f8"),
	"dark": Color("705848"), "steel": Color("b8b8d0"),
}


func _init() -> void:
	for d in ["", "species", "npc", "tiles", "props"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.path_join(d)))
	_save(_checker(Color.MAGENTA, Color.BLACK, 32), "missing")
	_save(_sheet(Color("d9b38c"), Color("3a5ba0"), false), "npc/default")
	_save(_sheet(Color("d9b38c"), Color("c0392b"), false), "npc/player")
	var db := DataDB.load_dir("res://data")
	var count := 0
	for id in db.table(&"species"):
		var rec: Dictionary = db.table(&"species")[id]
		var t: String = rec.get("types", ["normal"])[0]
		var c: Color = TYPE_COLORS.get(t, Color.GRAY)
		_save(_sheet(c, c.darkened(0.35), true), "species/%s" % id)
		_save(_sheet(c.lerp(Color.GOLD, 0.5), c.darkened(0.35), true), "species/%s_shiny" % id)
		count += 1
	print("gen_placeholders: wrote %d species sheets" % count)
	quit(0)


func _save(img: Image, key: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT.path_join(key + ".png")))


func _checker(a: Color, b: Color, size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			img.set_pixel(x, y, a if ((x / 8) + (y / 8)) % 2 == 0 else b)
	return img


## Simple silhouette: creatures are a round body with ears; people are head + body.
func _sheet(body: Color, accent: Color, creature: bool) -> Image:
	var img := Image.create(FRAME.x * 3, FRAME.y * 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for row in 4:
		for frame in 3:
			var o := Vector2i(frame * FRAME.x, row * FRAME.y)
			var bob := 1 if frame == 1 else 0
			if creature:
				_ellipse(img, o + Vector2i(24, 44 - bob), Vector2i(17, 15), body)
				_ellipse(img, o + Vector2i(12, 28 - bob), Vector2i(5, 8), accent)
				_ellipse(img, o + Vector2i(36, 28 - bob), Vector2i(5, 8), accent)
			else:
				_ellipse(img, o + Vector2i(24, 18 - bob), Vector2i(9, 10), body)
				_ellipse(img, o + Vector2i(24, 44 - bob), Vector2i(12, 17), accent)
			if row != 3:  # eyes, not on the back view
				var dx := -4 if row == 1 else (4 if row == 2 else 0)
				var ey := (40 if creature else 18) - bob
				img.set_pixel(o.x + 20 + dx, o.y + ey, Color.BLACK)
				img.set_pixel(o.x + 28 + dx, o.y + ey, Color.BLACK)
	return img


func _ellipse(img: Image, c: Vector2i, r: Vector2i, col: Color) -> void:
	for y in range(-r.y, r.y + 1):
		for x in range(-r.x, r.x + 1):
			if float(x * x) / (r.x * r.x) + float(y * y) / (r.y * r.y) <= 1.0:
				var p := c + Vector2i(x, y)
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
					img.set_pixelv(p, col)
