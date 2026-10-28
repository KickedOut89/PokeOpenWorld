class_name ChunkData
extends RefCounted
## One 64x64 m chunk: 16x16 authoring cells (4x4 m each) plus placements in chunk-local metres.
## Axes: x = east, z = south. A space character is void (outside any authored area).

const CELLS := 16
const CELL_M := 4.0
const SIZE_M := 64.0
const LEVEL_M := 1.0

var id: String
var region: StringName
var coord: Vector2i
var area: StringName
var cells: PackedStringArray
var heights: PackedStringArray
var props: Array = []
var doors: Array = []
var spawn_zones: Array = []
var npc_anchors: Array = []


static func from_record(r: Dictionary) -> ChunkData:
	var d := ChunkData.new()
	d.id = r.get("id", "")
	d.region = StringName(r.get("region", "kanto"))
	var c: Array = r.get("coord", [0, 0])
	d.coord = Vector2i(int(c[0]), int(c[1]))
	d.area = StringName(r.get("area", ""))
	d.cells = PackedStringArray(r.get("cells", []))
	d.heights = PackedStringArray(r.get("heights", []))
	d.props = r.get("props", [])
	d.doors = r.get("doors", [])
	d.spawn_zones = r.get("spawn_zones", [])
	d.npc_anchors = r.get("npc_anchors", [])
	return d


func origin() -> Vector3:
	return Vector3(coord.x * SIZE_M, 0.0, coord.y * SIZE_M)


func cell(x: int, y: int) -> String:
	if y < 0 or y >= cells.size() or x < 0 or x >= cells[y].length():
		return " "
	return cells[y][x]


func level(x: int, y: int) -> int:
	if y < 0 or y >= heights.size() or x < 0 or x >= heights[y].length():
		return 0
	var ch := heights[y][x]
	return int(ch) if ch.is_valid_int() else 0


func cell_at(local: Vector2) -> String:
	return cell(int(floor(local.x / CELL_M)), int(floor(local.y / CELL_M)))


## Ground height (metres) at a chunk-local (x, z) point; terrain is stepped per cell.
func height_at(local: Vector2) -> float:
	return level(int(floor(local.x / CELL_M)), int(floor(local.y / CELL_M))) * LEVEL_M


func is_tall_grass(local: Vector2) -> bool:
	return cell_at(local) == "\""
