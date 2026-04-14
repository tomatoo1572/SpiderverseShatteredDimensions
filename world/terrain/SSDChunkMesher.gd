extends RefCounted
class_name SSDChunkMesher

const FACE_DIRECTIONS: Array[Vector3i] = [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1),
]

const FACE_NORMALS: Array[Vector3] = [
	Vector3.RIGHT,
	Vector3.LEFT,
	Vector3.UP,
	Vector3.DOWN,
	Vector3.FORWARD,
	Vector3.BACK,
]

const FACE_VERTICES: Array = [
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	[Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0)],
]

static func build_surface_arrays(chunk_coords: Vector2i, chunk_data: SSDChunkData, height_cache: PackedInt32Array, sea_level: int = 24) -> Dictionary:
	return _build_surface_arrays_impl(chunk_coords, chunk_data, func(world_x: int, world_y: int, world_z: int, local_x: int, local_z: int) -> int:
		var neighbor_local_x: int = local_x + world_x - (chunk_coords.x * SSDChunkConfig.SIZE_X)
		var neighbor_local_z: int = local_z + world_z - (chunk_coords.y * SSDChunkConfig.SIZE_Z)
		return _get_generated_neighbor_block(chunk_data, height_cache, neighbor_local_x, world_y, neighbor_local_z, sea_level)
	)

static func build_surface_arrays_runtime(world: SSDWorld, chunk_coords: Vector2i, chunk_data: SSDChunkData) -> Dictionary:
	return _build_surface_arrays_impl(chunk_coords, chunk_data, func(world_x: int, world_y: int, world_z: int, _local_x: int, _local_z: int) -> int:
		return world.get_block_global(world_x, world_y, world_z)
	)

static func _build_surface_arrays_impl(chunk_coords: Vector2i, chunk_data: SSDChunkData, neighbor_callable: Callable) -> Dictionary:
	var opaque: Dictionary = _make_mesh_arrays_dict()
	var transparent: Dictionary = _make_mesh_arrays_dict()
	var collision_vertices: PackedVector3Array = PackedVector3Array()
	var collision_indices: PackedInt32Array = PackedInt32Array()

	var base_block_x: int = chunk_coords.x * SSDChunkConfig.SIZE_X
	var base_block_z: int = chunk_coords.y * SSDChunkConfig.SIZE_Z

	for local_y: int in range(SSDChunkConfig.SIZE_Y):
		for local_z: int in range(SSDChunkConfig.SIZE_Z):
			for local_x: int in range(SSDChunkConfig.SIZE_X):
				var block_id: int = chunk_data.get_block(local_x, local_y, local_z)
				if not SSDVoxelDefs.is_renderable(block_id):
					continue

				var world_x: int = base_block_x + local_x
				var world_z: int = base_block_z + local_z
				var base_position: Vector3 = Vector3(float(local_x), float(local_y), float(local_z)) * SSDChunkConfig.VOXEL_SIZE
				var mesh_target: Dictionary = transparent if _is_transparent_block(block_id) else opaque

				for face_index: int in range(6):
					var direction: Vector3i = FACE_DIRECTIONS[face_index]
					var neighbor_world_x: int = world_x + direction.x
					var neighbor_world_y: int = local_y + direction.y
					var neighbor_world_z: int = world_z + direction.z
					var neighbor_block: int = int(neighbor_callable.call(neighbor_world_x, neighbor_world_y, neighbor_world_z, local_x, local_z))
					if _should_hide_face(block_id, neighbor_block, face_index):
						continue
					_append_face(mesh_target, collision_vertices, collision_indices, base_position, face_index, block_id, world_x, local_y, world_z)

	return {
		"opaque": opaque,
		"transparent": transparent,
		"collision_vertices": collision_vertices,
		"collision_indices": collision_indices,
	}

static func create_mesh_from_arrays(surface_arrays: Dictionary) -> ArrayMesh:
	var vertices: PackedVector3Array = surface_arrays.get("vertices", PackedVector3Array())
	var mesh: ArrayMesh = ArrayMesh.new()
	if vertices.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = surface_arrays.get("normals", PackedVector3Array())
	arrays[Mesh.ARRAY_COLOR] = surface_arrays.get("colors", PackedColorArray())
	arrays[Mesh.ARRAY_TEX_UV] = surface_arrays.get("uvs", PackedVector2Array())
	arrays[Mesh.ARRAY_INDEX] = surface_arrays.get("indices", PackedInt32Array())
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func create_collision_shape_from_arrays(surface_arrays: Dictionary) -> ConcavePolygonShape3D:
	var vertices: PackedVector3Array = surface_arrays.get("collision_vertices", PackedVector3Array())
	if vertices.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = surface_arrays.get("collision_indices", PackedInt32Array())
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh.create_trimesh_shape() as ConcavePolygonShape3D

static func _make_mesh_arrays_dict() -> Dictionary:
	return {
		"vertices": PackedVector3Array(),
		"normals": PackedVector3Array(),
		"colors": PackedColorArray(),
		"uvs": PackedVector2Array(),
		"indices": PackedInt32Array(),
	}

static func _get_generated_neighbor_block(chunk_data: SSDChunkData, height_cache: PackedInt32Array, local_x: int, local_y: int, local_z: int, sea_level: int) -> int:
	if local_y < 0 or local_y >= SSDChunkConfig.SIZE_Y:
		return SSDVoxelDefs.BlockId.AIR
	if local_x >= 0 and local_x < SSDChunkConfig.SIZE_X and local_z >= 0 and local_z < SSDChunkConfig.SIZE_Z:
		return chunk_data.get_block(local_x, local_y, local_z)
	var cache_width: int = SSDChunkConfig.SIZE_X + 2
	var sample_x: int = clampi(local_x + 1, 0, SSDChunkConfig.SIZE_X + 1)
	var sample_z: int = clampi(local_z + 1, 0, SSDChunkConfig.SIZE_Z + 1)
	var terrain_height: int = height_cache[sample_x + (sample_z * cache_width)]
	if local_y > terrain_height and local_y <= sea_level:
		return SSDVoxelDefs.BlockId.WATER
	if local_y <= terrain_height:
		return SSDVoxelDefs.BlockId.STONE
	return SSDVoxelDefs.BlockId.AIR

static func _is_transparent_block(block_id: int) -> bool:
	return SSDVoxelDefs.is_fluid(block_id) or block_id == SSDVoxelDefs.BlockId.GLASS

static func _should_hide_face(current_block: int, neighbor_block: int, face_index: int) -> bool:
	if not SSDVoxelDefs.is_renderable(neighbor_block):
		return false
	if SSDVoxelDefs.is_fluid(current_block) and SSDVoxelDefs.is_fluid(neighbor_block):
		return face_index != 2
	if SSDVoxelDefs.is_solid(current_block) and SSDVoxelDefs.is_solid(neighbor_block):
		return true
	if current_block == SSDVoxelDefs.BlockId.GLASS and neighbor_block == SSDVoxelDefs.BlockId.GLASS:
		return true
	return false

static func _append_face(mesh_target: Dictionary, collision_vertices: PackedVector3Array, collision_indices: PackedInt32Array, base_position: Vector3, face_index: int, block_id: int, world_x: int, world_y: int, world_z: int) -> void:
	var face_vertices: Array = FACE_VERTICES[face_index]
	var normal: Vector3 = FACE_NORMALS[face_index]
	var shaded_color: Color = _get_shaded_color(block_id, face_index)
	var face_uvs: Array[Vector2] = _build_face_uvs(block_id, face_index, world_x, world_y, world_z)
	var fluid_height: float = SSDVoxelDefs.get_fluid_surface_height(block_id)

	var vertices: PackedVector3Array = mesh_target["vertices"] as PackedVector3Array
	var normals: PackedVector3Array = mesh_target["normals"] as PackedVector3Array
	var colors: PackedColorArray = mesh_target["colors"] as PackedColorArray
	var uvs: PackedVector2Array = mesh_target["uvs"] as PackedVector2Array
	var indices: PackedInt32Array = mesh_target["indices"] as PackedInt32Array

	var vertex_start: int = vertices.size()
	for vertex_index: int in range(face_vertices.size()):
		var vertex: Vector3 = face_vertices[vertex_index] as Vector3
		var adjusted: Vector3 = vertex
		if SSDVoxelDefs.is_fluid(block_id) and vertex.y > 0.5:
			adjusted.y = fluid_height
		var world_vertex: Vector3 = base_position + (adjusted * SSDChunkConfig.VOXEL_SIZE)
		vertices.push_back(world_vertex)
		normals.push_back(normal)
		colors.push_back(shaded_color)
		uvs.push_back(face_uvs[vertex_index])

	mesh_target["vertices"] = vertices
	mesh_target["normals"] = normals
	mesh_target["colors"] = colors
	mesh_target["uvs"] = uvs
	mesh_target["indices"] = indices

	if SSDVoxelDefs.is_solid(block_id):
		var collision_start: int = collision_vertices.size()
		for collision_vertex_index: int in range(face_vertices.size()):
			var collision_vertex: Vector3 = face_vertices[collision_vertex_index] as Vector3
			collision_vertices.push_back(base_position + (collision_vertex * SSDChunkConfig.VOXEL_SIZE))
		collision_indices.push_back(collision_start + 0)
		collision_indices.push_back(collision_start + 1)
		collision_indices.push_back(collision_start + 2)
		collision_indices.push_back(collision_start + 0)
		collision_indices.push_back(collision_start + 2)
		collision_indices.push_back(collision_start + 3)

	indices.push_back(vertex_start + 0)
	indices.push_back(vertex_start + 1)
	indices.push_back(vertex_start + 2)
	indices.push_back(vertex_start + 0)
	indices.push_back(vertex_start + 2)
	indices.push_back(vertex_start + 3)
	mesh_target["indices"] = indices

static func _build_face_uvs(block_id: int, face_index: int, world_x: int, _world_y: int, world_z: int) -> Array[Vector2]:
	var uv_rect: Rect2 = SSDVoxelDefs.get_face_uv_rect(block_id, face_index)
	if uv_rect.size.x <= 0.0 or uv_rect.size.y <= 0.0:
		return [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var uv_left: float = uv_rect.position.x
	var uv_top: float = uv_rect.position.y
	var uv_right: float = uv_rect.position.x + uv_rect.size.x
	var uv_bottom: float = uv_rect.position.y + uv_rect.size.y
	return [
		Vector2(uv_right, uv_bottom),
		Vector2(uv_right, uv_top),
		Vector2(uv_left, uv_top),
		Vector2(uv_left, uv_bottom),
	]

static func _get_shaded_color(block_id: int, face_index: int) -> Color:
	var multiplier: float = 1.0
	match face_index:
		2:
			multiplier = 0.82
		3:
			multiplier = 0.50
		0, 1:
			multiplier = 0.70
		4, 5:
			multiplier = 0.64
		_:
			multiplier = 1.0
	var alpha_value: float = 1.0
	if block_id == SSDVoxelDefs.BlockId.GLASS:
		alpha_value = 0.38
	elif SSDVoxelDefs.is_fluid(block_id):
		alpha_value = 0.72
	return Color(multiplier, multiplier, multiplier, alpha_value)
