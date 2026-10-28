class_name BillboardSprite
extends Sprite3D
## Camera-facing 2D sprite using a 3-frame x 4-direction sheet (rows: down, left, right, up).

const ROW_DOWN := 0
const ROW_LEFT := 1
const ROW_RIGHT := 2
const ROW_UP := 3

var row: int = ROW_DOWN
var anim_fps: float = 6.0
var walking: bool = false
var _t: float = 0.0


func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	pixel_size = 0.04  # 48x64 frame -> ~1.9 x 2.6 m
	centered = true
	offset = Vector2(0, 32)  # feet at node origin
	hframes = 3
	vframes = 4


func set_sheet(tex: Texture2D, frames: int = 3) -> void:
	texture = tex
	hframes = frames
	vframes = 4
	frame = row * hframes


func face(dir: Vector2) -> void:
	if dir.length_squared() < 0.0001:
		return
	if absf(dir.x) >= absf(dir.y):
		row = ROW_RIGHT if dir.x > 0 else ROW_LEFT
	else:
		row = ROW_DOWN if dir.y > 0 else ROW_UP
	frame = row * hframes + (frame % hframes)


func _process(delta: float) -> void:
	if not walking:
		frame = row * hframes + (1 if hframes > 1 else 0)
		return
	_t += delta * anim_fps
	frame = row * hframes + int(_t) % hframes
