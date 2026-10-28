class_name ChunkBuilder
extends RefCounted
## Builds a detached Node3D for one chunk: terrain GridMap (1 m tiles, 4x4 per cell),
## terrain/obstacle collision, trees, ledges, props, door and spawn-zone areas, anchors.
## Safe to call off the main thread (never touches the scene tree).

const CELL := ChunkData.CELL_M

var _lib: MeshLibrary
var _seed: int
var _items: Dictionary
var _tileset: Dictionary


func _init(lib: MeshLibrary, seed_value: int) -> void:
	_lib = lib
	_seed = seed_value
	_items = lib.get_meta(&"char_items", {})
	_tileset = lib.get_meta(&"tileset", {})


func build(data: ChunkData) -> Node3D:
	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [data.coord.x, data.coord.y]
	root.position = data.origin()
	root.set_meta(&"chunk", data)
	var grid := GridMap.new()
	grid.name = "Ground"
	grid.mesh_library = _lib
	grid.cell_size = Vector3.ONE
	grid.position.y = -1.0  # cell y=level spans [level-1, level]: tile tops sit at `level` metres
	grid.collision_layer = 0
	grid.collision_mask = 0
	root.add_child(grid)
	var terrain := StaticBody3D.new()
	terrain.name = "Terrain"
	root.add_child(terrain)
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	for y in ChunkData.CELLS:
		for x in ChunkData.CELLS:
			_build_cell(data, x, y, grid, terrain, props)
	for p in data.props:
		props.add_child(PropFactory.make(p))
	for d in data.doors:
		root.add_child(_door(d))
	for z in data.spawn_zones:
		root.add_child(_zone(z))
	for a in data.npc_anchors:
		var m := Marker3D.new()
		m.name = "Anchor_%s" % a.id
		m.position = Vector3(float(a.pos[0]), float(a.pos[1]), float(a.pos[2]))
		m.set_meta(&"anchor", a)
		root.add_child(m)
	return root


func _build_cell(data: ChunkData, x: int, y: int, grid: GridMap, terrain: StaticBody3D, props: Node3D) -> void:
	var ch := data.cell(x, y)
	if ch == " " or not _items.has(ch):
		return
	var def: Dictionary = _tileset.get(ch, {})
	var lvl := data.level(x, y)
	var ids: PackedInt32Array = _items[ch]
	for ty in 4:
		for tx in 4:
			var h := hash([_seed, data.coord.x, data.coord.y, x * 4 + tx, y * 4 + ty])
			grid.set_cell_item(Vector3i(x * 4 + tx, lvl, y * 4 + ty), ids[absi(h) % ids.size()])
	var top := float(lvl)
	# Ground collision slab for the cell.
	_add_box(terrain, Vector3(x * CELL + 2, top - 0.5, y * CELL + 2), Vector3(CELL, 1.0, CELL))
	if def.get("solid", false) and not def.get("tree", false):
		_add_box(terrain, Vector3(x * CELL + 2, top + 1.0, y * CELL + 2), Vector3(CELL, 2.0, CELL))
	if def.get("tree", false):
		var h := hash([_seed, "tree", data.coord.x, data.coord.y, x, y])
		var jitter := Vector3((h % 7 - 3) * 0.15, 0, ((h >> 4) % 7 - 3) * 0.15)
		var t := PropFactory.tree(Vector3(x * CELL + 2, top, y * CELL + 2) + jitter, 0.9 + (absi(h >> 8) % 5) * 0.05)
		t.name = "Tree_%d_%d" % [x, y]
		props.add_child(t)
	if def.get("ledge", false):
		var ledge := StaticBody3D.new()
		ledge.name = "Ledge_%d_%d" % [x, y]
		ledge.position = Vector3(x * CELL, top, y * CELL)
		ledge.add_to_group(&"ledge")
		var col := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = Vector3(CELL, 1.0, 0.3)
		col.shape = s
		col.position = Vector3(CELL * 0.5, 0.5, 0.15)
		ledge.add_child(col)
		props.add_child(ledge)


func _add_box(body: StaticBody3D, center: Vector3, size: Vector3) -> void:
	var col := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	col.shape = s
	col.position = center
	body.add_child(col)


func _door(d: Dictionary) -> Area3D:
	var a := Area3D.new()
	a.name = "Door_%s" % d.id
	a.position = Vector3(float(d.pos[0]), float(d.pos[1]), float(d.pos[2]))
	a.set_meta(&"door_id", StringName(d.id))
	a.set_meta(&"door", d)
	a.add_to_group(&"door")
	var col := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1.6, 2.2, 1.2)
	col.shape = s
	col.position.y = 1.1
	a.add_child(col)
	return a


func _zone(z: Dictionary) -> Area3D:
	var a := Area3D.new()
	a.name = "Zone_%s" % z.id
	var r: Array = z.rect
	a.position = Vector3(float(r[0]) + float(r[2]) * 0.5, 0, float(r[1]) + float(r[3]) * 0.5)
	a.set_meta(&"zone", z)
	a.add_to_group(&"spawn_zone")
	a.monitoring = false
	a.monitorable = false
	var col := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(float(r[2]), 4.0, float(r[3]))
	col.shape = s
	a.add_child(col)
	return a
