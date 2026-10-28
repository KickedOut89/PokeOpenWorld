class_name StreamingMath
extends RefCounted
## Shared world <-> chunk coordinate helpers.


static func chunk_of(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / ChunkData.SIZE_M), floori(pos.z / ChunkData.SIZE_M))
