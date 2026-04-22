extends Node3D
class_name SSDWorld

const FLUID_MAX_LEVEL: int = 7
const FLUID_HORIZONTAL_RANGE: int = 7
const FLUID_VERTICAL_RANGE: int = 8

@export var world_seed: int = 1337
@export var load_radius: int = 2
@export var collision_radius: int = 1
@export var chunks_per_frame: int = 8
@export var completed_chunks_per_frame: int = 8
@export var collisions_per_frame: int = 4
@export var update_interval: float = 0.12
@export var worker_thread_count: int = 2
@export var crop_growth_speed_multiplier: float = 1.0

@export var base_height: int = 30
@export var height_variation: int = 20
@export var primary_frequency: float = 0.012
@export var detail_frequency: float = 0.045

var _terrain_noises: Dictionary = {}

var _chunks: Dictionary = {}
var _chunk_data_cache: Dictionary = {}

var _pending_loads: Array[Vector2i] = []
var _pending_lookup: Dictionary = {}
var _active_generation_lookup: Dictionary = {}

var _pending_collision_builds: Array[Vector2i] = []
var _pending_collision_lookup: Dictionary = {}

var _target: Node3D
var _refresh_timer: float = 0.0
var _chunk_material_opaque: StandardMaterial3D
var _chunk_material_transparent: StandardMaterial3D
var _last_target_chunk: Vector2i = Vector2i(2147483647, 2147483647)
var _world_revision: int = 0
var _pending_fluid_updates: Array[Vector3i] = []
var _pending_fluid_lookup: Dictionary = {}
var _pending_gravity_updates: Array[Vector3i] = []
var _pending_gravity_lookup: Dictionary = {}
var _pending_chunk_rebuilds: Array[Vector2i] = []
var _pending_chunk_rebuild_lookup: Dictionary = {}
var _crop_growth_timer: float = 0.0

var _worker_mutex: Mutex = Mutex.new()
var _worker_semaphore: Semaphore = Semaphore.new()
var _worker_threads: Array[Thread] = []
var _worker_running: bool = false
var _worker_exit_requested: bool = false
var _worker_jobs: Array = []
var _worker_completed: Array = []

func _ready() -> void:
	_build_noises()
	_build_materials()
	worker_thread_count = clampi(OS.get_processor_count(), 4, 12)
	_start_worker()

func _exit_tree() -> void:
	_shutdown_worker()

func _process(delta: float) -> void:
	if _target == null:
		return

	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_streaming()
		_refresh_timer = update_interval

	_consume_load_queue()
	_consume_completed_results()
	_consume_chunk_rebuild_queue(max(1, min(4, int(load_radius / 3))))
	_consume_collision_queue()
	_consume_fluid_updates(4)
	_consume_gravity_updates(6)
	_crop_growth_timer += delta * maxf(0.0, crop_growth_speed_multiplier)
	if _crop_growth_timer >= 0.45:
		_crop_growth_timer = 0.0
		var attempt_bonus: int = max(1, int(round(maxf(1.0, crop_growth_speed_multiplier))))
		_consume_crop_growth_attempts(max(4, min(12, load_radius)) * attempt_bonus)


func set_crop_growth_speed_multiplier(multiplier: float) -> void:
	crop_growth_speed_multiplier = clampf(multiplier, 0.0, 64.0)

func get_crop_growth_speed_multiplier() -> float:
	return crop_growth_speed_multiplier

func accelerate_crop_growth_ticks(ticks: int) -> void:
	for _i: int in range(max(0, ticks)):
		_consume_crop_growth_attempts(max(4, min(12, load_radius)))

func set_target(target: Node3D) -> void:
	_target = target
	apply_render_distance(load_radius)

func apply_render_distance(new_distance: int) -> void:
	load_radius = clampi(new_distance, 2, 40)
	collision_radius = max(1, load_radius - 1)
	chunks_per_frame = clampi(8 + int(load_radius * 1.5), 12, 72)
	completed_chunks_per_frame = clampi(chunks_per_frame * 3, 24, 192)
	collisions_per_frame = clampi(4 + int(load_radius * 0.75), 6, 48)
	update_interval = 0.02 if load_radius >= 12 else 0.05
	_refresh_timer = 0.0
	if _target != null:
		_refresh_streaming()

func prime_spawn_area(world_position: Vector3, radius: int = 1) -> Vector3:
	var center_chunk: Vector2i = _world_position_to_chunk(world_position)
	var coords: Array[Vector2i] = _get_coords_in_radius(center_chunk, radius)

	for coord: Vector2i in coords:
		_ensure_chunk_loaded_sync(coord, true)

	return get_safe_spawn_position(world_position)

func regenerate() -> void:
	_world_revision += 1

	for chunk_variant in _chunks.values():
		var chunk: SSDChunk = chunk_variant as SSDChunk
		if is_instance_valid(chunk):
			chunk.queue_free()

	_chunks.clear()
	_chunk_data_cache.clear()
	_pending_loads.clear()
	_pending_lookup.clear()
	_active_generation_lookup.clear()
	_pending_collision_builds.clear()
	_pending_collision_lookup.clear()
	_pending_fluid_updates.clear()
	_pending_fluid_lookup.clear()
	_pending_gravity_updates.clear()
	_pending_gravity_lookup.clear()
	_pending_chunk_rebuilds.clear()
	_pending_chunk_rebuild_lookup.clear()
	_clear_worker_queues()

	_build_noises()
	_refresh_timer = 0.0

	if _target != null:
		_refresh_streaming()
		_consume_load_queue(max(4, chunks_per_frame * 2))

func get_loaded_chunk_count() -> int:
	return _chunks.size()

func get_cached_chunk_count() -> int:
	return _chunk_data_cache.size()

func get_pending_load_count() -> int:
	return _pending_loads.size() + _active_generation_lookup.size()

func get_pending_collision_count() -> int:
	return _pending_collision_builds.size()

func get_surface_height_at(block_x: int, block_z: int) -> int:
	for block_y: int in range(SSDChunkConfig.SIZE_Y - 1, -1, -1):
		if SSDVoxelDefs.is_solid(get_block_global(block_x, block_y, block_z)):
			return block_y
	return 0

func get_safe_spawn_position(approx_world_position: Vector3) -> Vector3:
	var block_x: int = floori(approx_world_position.x / SSDChunkConfig.VOXEL_SIZE)
	var block_z: int = floori(approx_world_position.z / SSDChunkConfig.VOXEL_SIZE)
	var surface_height: int = get_surface_height_at(block_x, block_z)
	return Vector3(
		(float(block_x) + 0.5) * SSDChunkConfig.VOXEL_SIZE,
		(float(surface_height) + 1.02) * SSDChunkConfig.VOXEL_SIZE,
		(float(block_z) + 0.5) * SSDChunkConfig.VOXEL_SIZE
	)

func get_block_global(block_x: int, block_y: int, block_z: int) -> int:
	if block_y < 0 or block_y >= SSDChunkConfig.SIZE_Y:
		return SSDVoxelDefs.BlockId.AIR

	var chunk_coords: Vector2i = _block_to_chunk_coords(block_x, block_z)
	if _chunk_data_cache.has(chunk_coords):
		var chunk_data: SSDChunkData = _chunk_data_cache[chunk_coords] as SSDChunkData
		var local_x: int = posmod(block_x, SSDChunkConfig.SIZE_X)
		var local_z: int = posmod(block_z, SSDChunkConfig.SIZE_Z)
		return chunk_data.get_block(local_x, block_y, local_z)

	var terrain_height: int = SSDTerrainGenerator.get_terrain_height(
		_terrain_noises,
		block_x,
		block_z,
		base_height,
		height_variation
	)
	return SSDTerrainGenerator.get_generated_block(_terrain_noises, block_x, block_y, block_z, terrain_height)

func request_set_block_global(block_x: int, block_y: int, block_z: int, block_id: int, queue_fluid_update: bool = true) -> bool:
	if block_y < 0 or block_y >= SSDChunkConfig.SIZE_Y:
		return false

	var chunk_coords: Vector2i = _block_to_chunk_coords(block_x, block_z)
	var chunk_data: SSDChunkData = _ensure_chunk_data_cached(chunk_coords)
	var local_x: int = posmod(block_x, SSDChunkConfig.SIZE_X)
	var local_z: int = posmod(block_z, SSDChunkConfig.SIZE_Z)
	var old_block: int = chunk_data.get_block(local_x, block_y, local_z)

	if old_block == block_id:
		return false

	chunk_data.set_block(local_x, block_y, local_z, block_id)
	_chunk_data_cache[chunk_coords] = chunk_data

	var dirty_chunks: Dictionary = {}
	dirty_chunks[chunk_coords] = true

	if local_x == 0:
		dirty_chunks[Vector2i(chunk_coords.x - 1, chunk_coords.y)] = true
	elif local_x == SSDChunkConfig.SIZE_X - 1:
		dirty_chunks[Vector2i(chunk_coords.x + 1, chunk_coords.y)] = true

	if local_z == 0:
		dirty_chunks[Vector2i(chunk_coords.x, chunk_coords.y - 1)] = true
	elif local_z == SSDChunkConfig.SIZE_Z - 1:
		dirty_chunks[Vector2i(chunk_coords.x, chunk_coords.y + 1)] = true

	for dirty_coord_variant in dirty_chunks.keys():
		var dirty_coord: Vector2i = dirty_coord_variant
		_queue_chunk_rebuild(dirty_coord)

	if queue_fluid_update and _should_queue_fluid_update(old_block, block_id, block_x, block_y, block_z):
		_queue_fluid_rebuild_around(Vector3i(block_x, block_y, block_z))
	_queue_gravity_rebuild_around(Vector3i(block_x, block_y, block_z))

	return true


func request_set_blocks_batch(changes: Array[Dictionary], include_air: bool = false, queue_fluid_update: bool = true) -> int:
	if changes.is_empty():
		return 0

	var dirty_chunks: Dictionary = {}
	var changed: int = 0

	for change_variant: Dictionary in changes:
		var block_x: int = int(change_variant.get("x", 0))
		var block_y: int = int(change_variant.get("y", 0))
		var block_z: int = int(change_variant.get("z", 0))
		var block_id: int = int(change_variant.get("id", SSDVoxelDefs.BlockId.AIR))
		if block_y < 0 or block_y >= SSDChunkConfig.SIZE_Y:
			continue
		if block_id == SSDVoxelDefs.BlockId.AIR and not include_air:
			continue

		var chunk_coords: Vector2i = _block_to_chunk_coords(block_x, block_z)
		var chunk_data: SSDChunkData = _ensure_chunk_data_cached(chunk_coords)
		var local_x: int = posmod(block_x, SSDChunkConfig.SIZE_X)
		var local_z: int = posmod(block_z, SSDChunkConfig.SIZE_Z)
		var old_block: int = chunk_data.get_block(local_x, block_y, local_z)
		if old_block == block_id:
			continue

		chunk_data.set_block(local_x, block_y, local_z, block_id)
		_chunk_data_cache[chunk_coords] = chunk_data
		dirty_chunks[chunk_coords] = true

		if local_x == 0:
			dirty_chunks[Vector2i(chunk_coords.x - 1, chunk_coords.y)] = true
		elif local_x == SSDChunkConfig.SIZE_X - 1:
			dirty_chunks[Vector2i(chunk_coords.x + 1, chunk_coords.y)] = true
		if local_z == 0:
			dirty_chunks[Vector2i(chunk_coords.x, chunk_coords.y - 1)] = true
		elif local_z == SSDChunkConfig.SIZE_Z - 1:
			dirty_chunks[Vector2i(chunk_coords.x, chunk_coords.y + 1)] = true
		changed += 1

	for dirty_coord_variant in dirty_chunks.keys():
		_queue_chunk_rebuild(dirty_coord_variant as Vector2i)

	if queue_fluid_update:
		for change_variant: Dictionary in changes:
			var cx: int = int(change_variant.get("x", 0))
			var cy: int = int(change_variant.get("y", 0))
			var cz: int = int(change_variant.get("z", 0))
			var new_block_id: int = int(change_variant.get("id", SSDVoxelDefs.BlockId.AIR))
			if _should_queue_fluid_update(get_block_global(cx, cy, cz), new_block_id, cx, cy, cz):
				_queue_fluid_rebuild_around(Vector3i(cx, cy, cz))
	for change_variant: Dictionary in changes:
		_queue_gravity_rebuild_around(Vector3i(int(change_variant.get("x", 0)), int(change_variant.get("y", 0)), int(change_variant.get("z", 0))))

	return changed


func _queue_chunk_rebuild(chunk_coords: Vector2i) -> void:
	if not _chunks.has(chunk_coords):
		return
	if _pending_chunk_rebuild_lookup.has(chunk_coords):
		return
	_pending_chunk_rebuild_lookup[chunk_coords] = true
	_pending_chunk_rebuilds.append(chunk_coords)

func _consume_chunk_rebuild_queue(max_count: int) -> void:
	var budget: int = max_count
	while budget > 0 and not _pending_chunk_rebuilds.is_empty():
		var coord: Vector2i = _pending_chunk_rebuilds[0]
		_pending_chunk_rebuilds.remove_at(0)
		_pending_chunk_rebuild_lookup.erase(coord)
		_rebuild_loaded_chunk(coord)
		budget -= 1


func _queue_gravity_rebuild_around(center: Vector3i) -> void:
	for dy: int in range(-1, 3):
		for dz: int in range(-1, 2):
			for dx: int in range(-1, 2):
				_queue_gravity_update(center + Vector3i(dx, dy, dz))

func _queue_gravity_update(block_pos: Vector3i) -> void:
	if block_pos.y <= 0 or block_pos.y >= SSDChunkConfig.SIZE_Y:
		return
	var key: String = _fluid_key(block_pos)
	if _pending_gravity_lookup.has(key):
		return
	_pending_gravity_lookup[key] = true
	_pending_gravity_updates.append(block_pos)

func _consume_gravity_updates(max_count: int) -> void:
	var budget: int = max_count
	while budget > 0 and not _pending_gravity_updates.is_empty():
		var gravity_pos: Vector3i = _pending_gravity_updates[0]
		_pending_gravity_updates.remove_at(0)
		_pending_gravity_lookup.erase(_fluid_key(gravity_pos))
		_simulate_gravity_at(gravity_pos)
		budget -= 1

func _simulate_gravity_at(block_pos: Vector3i) -> void:
	if block_pos.y <= 0 or block_pos.y >= SSDChunkConfig.SIZE_Y:
		return
	var block_id: int = get_block_global(block_pos.x, block_pos.y, block_pos.z)
	if not SSDVoxelDefs.is_gravity_block(block_id):
		return
	var below: Vector3i = block_pos + Vector3i.DOWN
	var below_id: int = get_block_global(below.x, below.y, below.z)
	if below_id != SSDVoxelDefs.BlockId.AIR and not SSDVoxelDefs.is_fluid(below_id):
		return
	request_set_blocks_batch([
		{"x": block_pos.x, "y": block_pos.y, "z": block_pos.z, "id": SSDVoxelDefs.BlockId.AIR},
		{"x": below.x, "y": below.y, "z": below.z, "id": block_id},
	], true, true)
	_queue_gravity_update(block_pos)
	_queue_gravity_update(below)
	_queue_gravity_update(block_pos + Vector3i.UP)

func _queue_fluid_rebuild_around(center: Vector3i) -> void:
	for dy: int in range(-1, 2):
		for dz: int in range(-1, 2):
			for dx: int in range(-1, 2):
				_queue_fluid_update(center + Vector3i(dx, dy, dz))

func _queue_fluid_update(block_pos: Vector3i) -> void:
	var key: String = _fluid_key(block_pos)
	if _pending_fluid_lookup.has(key):
		return
	_pending_fluid_lookup[key] = true
	_pending_fluid_updates.append(block_pos)

func _consume_fluid_updates(max_count: int) -> void:
	var budget: int = max_count
	while budget > 0 and not _pending_fluid_updates.is_empty():
		var fluid_pos: Vector3i = _pending_fluid_updates[0]
		_pending_fluid_updates.remove_at(0)
		_pending_fluid_lookup.erase(_fluid_key(fluid_pos))
		_recompute_fluid_region(fluid_pos)
		budget -= 1

func _recompute_fluid_region(center: Vector3i) -> void:
	var min_x: int = center.x - (FLUID_HORIZONTAL_RANGE + 1)
	var max_x: int = center.x + (FLUID_HORIZONTAL_RANGE + 1)
	var min_y: int = max(0, center.y - FLUID_VERTICAL_RANGE)
	var max_y: int = min(SSDChunkConfig.SIZE_Y - 1, center.y + FLUID_VERTICAL_RANGE)
	var min_z: int = center.z - (FLUID_HORIZONTAL_RANGE + 1)
	var max_z: int = center.z + (FLUID_HORIZONTAL_RANGE + 1)

	var sources: Array[Vector3i] = []
	var existing_flows: Array[Vector3i] = []
	for y: int in range(min_y, max_y + 1):
		for z: int in range(min_z, max_z + 1):
			for x: int in range(min_x, max_x + 1):
				var block_id: int = get_block_global(x, y, z)
				if SSDVoxelDefs.is_source_water(block_id):
					sources.append(Vector3i(x, y, z))
				elif SSDVoxelDefs.is_flowing_water(block_id):
					existing_flows.append(Vector3i(x, y, z))

	if sources.is_empty() and existing_flows.is_empty():
		return

	var desired: Dictionary = {}
	var queue: Array[Dictionary] = []
	for source: Vector3i in sources:
		queue.append({"pos": source, "level": FLUID_MAX_LEVEL})

	while not queue.is_empty():
		var state: Dictionary = queue[0]
		queue.remove_at(0)
		var pos: Vector3i = state.get("pos", Vector3i.ZERO)
		var level: int = int(state.get("level", 0))
		if pos.x < min_x or pos.x > max_x or pos.y < min_y or pos.y > max_y or pos.z < min_z or pos.z > max_z:
			continue
		var key: String = _fluid_key(pos)
		if int(desired.get(key, -1)) >= level:
			continue
		desired[key] = level
		if level <= 0:
			continue

		var below: Vector3i = pos + Vector3i.DOWN
		if _can_fluid_fill_at(below):
			queue.append({"pos": below, "level": FLUID_MAX_LEVEL})

		if level > 1:
			var horizontal_dirs: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]
			for dir: Vector3i in horizontal_dirs:
				var next_pos: Vector3i = pos + dir
				if not _can_fluid_fill_at(next_pos):
					continue
				queue.append({"pos": next_pos, "level": level - 1})

	var changes: Array[Dictionary] = []
	for flow_pos: Vector3i in existing_flows:
		var block_id: int = get_block_global(flow_pos.x, flow_pos.y, flow_pos.z)
		if not SSDVoxelDefs.is_flowing_water(block_id):
			continue
		var flow_key: String = _fluid_key(flow_pos)
		if not desired.has(flow_key):
			changes.append({"x": flow_pos.x, "y": flow_pos.y, "z": flow_pos.z, "id": SSDVoxelDefs.BlockId.AIR})

	for key_variant in desired.keys():
		var key_str: String = str(key_variant)
		var level: int = int(desired[key_variant])
		var pos: Vector3i = _fluid_pos_from_key(key_str)
		var existing_id: int = get_block_global(pos.x, pos.y, pos.z)
		if SSDVoxelDefs.is_source_water(existing_id):
			continue
		if not _can_fluid_fill_at(pos) and not SSDVoxelDefs.is_flowing_water(existing_id):
			continue
		var desired_id: int = SSDVoxelDefs.get_flow_block_from_level(level)
		if existing_id != desired_id:
			changes.append({"x": pos.x, "y": pos.y, "z": pos.z, "id": desired_id})

	if not changes.is_empty():
		request_set_blocks_batch(changes, true, false)

func _can_fluid_fill_at(pos: Vector3i) -> bool:
	if pos.y < 0 or pos.y >= SSDChunkConfig.SIZE_Y:
		return false
	var block_id: int = get_block_global(pos.x, pos.y, pos.z)
	return block_id == SSDVoxelDefs.BlockId.AIR or SSDVoxelDefs.is_fluid(block_id)

func _should_queue_fluid_update(old_block: int, new_block: int, block_x: int, block_y: int, block_z: int) -> bool:
	if SSDVoxelDefs.is_fluid(old_block) or SSDVoxelDefs.is_fluid(new_block):
		return true
	for dz: int in range(-1, 2):
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				if dx == 0 and dy == 0 and dz == 0:
					continue
				if SSDVoxelDefs.is_fluid(get_block_global(block_x + dx, block_y + dy, block_z + dz)):
					return true
	return false

func _fluid_key(pos: Vector3i) -> String:
	return "%d,%d,%d" % [pos.x, pos.y, pos.z]

func _fluid_pos_from_key(key: String) -> Vector3i:
	var split: PackedStringArray = key.split(",")
	if split.size() != 3:
		return Vector3i.ZERO
	return Vector3i(int(split[0].to_int()), int(split[1].to_int()), int(split[2].to_int()))

func _refresh_streaming() -> void:
	if _target == null:
		return

	var center_chunk: Vector2i = _world_position_to_chunk(_target.global_position)
	var moved_to_new_chunk: bool = center_chunk != _last_target_chunk
	_last_target_chunk = center_chunk
	var wanted_lookup: Dictionary = {}
	var wanted_collision_lookup: Dictionary = {}
	var ordered_coords: Array[Vector2i] = _get_coords_in_radius(center_chunk, load_radius)
	var ordered_collision_coords: Array[Vector2i] = _get_coords_in_radius(center_chunk, collision_radius)

	var sync_ring: int = 1 if moved_to_new_chunk else 0
	if sync_ring > 0:
		for near_coord: Vector2i in ordered_coords:
			if maxi(abs(near_coord.x - center_chunk.x), abs(near_coord.y - center_chunk.y)) > sync_ring:
				continue
			if not _chunks.has(near_coord):
				_ensure_chunk_loaded_sync(near_coord, true)

	for coord: Vector2i in ordered_coords:
		wanted_lookup[coord] = true

		if not _chunks.has(coord) and not _pending_lookup.has(coord) and not _active_generation_lookup.has(coord):
			_pending_loads.append(coord)
			_pending_lookup[coord] = true

	for coord: Vector2i in ordered_collision_coords:
		wanted_collision_lookup[coord] = true
		if _chunks.has(coord) and not _pending_collision_lookup.has(coord):
			var loaded_chunk: SSDChunk = _chunks[coord] as SSDChunk
			if loaded_chunk != null and not loaded_chunk.has_collision_enabled():
				_pending_collision_builds.append(coord)
				_pending_collision_lookup[coord] = true

	var loaded_to_remove: Array[Vector2i] = []
	for loaded_coord_variant in _chunks.keys():
		var loaded_coord: Vector2i = loaded_coord_variant
		if not wanted_lookup.has(loaded_coord):
			loaded_to_remove.append(loaded_coord)
		elif not wanted_collision_lookup.has(loaded_coord):
			var chunk_without_collision: SSDChunk = _chunks[loaded_coord] as SSDChunk
			if chunk_without_collision != null:
				chunk_without_collision.set_collision_enabled(false)

	for loaded_coord: Vector2i in loaded_to_remove:
		var chunk: SSDChunk = _chunks[loaded_coord] as SSDChunk
		_chunks.erase(loaded_coord)
		_pending_chunk_rebuild_lookup.erase(loaded_coord)
		if is_instance_valid(chunk):
			chunk.queue_free()

	var filtered_pending: Array[Vector2i] = []
	var filtered_lookup: Dictionary = {}
	for pending_coord: Vector2i in _pending_loads:
		if wanted_lookup.has(pending_coord):
			filtered_pending.append(pending_coord)
			filtered_lookup[pending_coord] = true

	_pending_loads = _sort_coords_by_distance(filtered_pending, center_chunk)
	_pending_lookup = filtered_lookup

	var filtered_collision_pending: Array[Vector2i] = []
	var filtered_collision_lookup: Dictionary = {}
	for pending_collision_coord: Vector2i in _pending_collision_builds:
		if wanted_collision_lookup.has(pending_collision_coord) and _chunks.has(pending_collision_coord):
			filtered_collision_pending.append(pending_collision_coord)
			filtered_collision_lookup[pending_collision_coord] = true

	_pending_collision_builds = filtered_collision_pending
	_pending_collision_lookup = filtered_collision_lookup

func _consume_load_queue(count: int = -1) -> void:
	var budget: int = chunks_per_frame if count < 0 else count
	var dispatched_count: int = 0

	while dispatched_count < budget and _pending_loads.size() > 0:
		var coord: Vector2i = _pending_loads[0]
		_pending_loads.remove_at(0)
		_pending_lookup.erase(coord)

		if _chunks.has(coord) or _active_generation_lookup.has(coord):
			continue

		_active_generation_lookup[coord] = true
		_enqueue_worker_job(coord, _world_revision)
		dispatched_count += 1

func _consume_completed_results(count: int = -1) -> void:
	var results: Array = []
	var budget: int = completed_chunks_per_frame if count < 0 else count

	_worker_mutex.lock()
	var taken: int = 0
	while taken < budget and _worker_completed.size() > 0:
		results.append(_worker_completed[0])
		_worker_completed.remove_at(0)
		taken += 1
	_worker_mutex.unlock()

	for result_variant in results:
		var result: Dictionary = result_variant
		var coord: Vector2i = result.get("coord", Vector2i.ZERO)
		var result_revision: int = result.get("revision", -1)

		_active_generation_lookup.erase(coord)

		if result_revision != _world_revision:
			continue

		var chunk_data: SSDChunkData = result.get("data", null) as SSDChunkData
		if chunk_data == null:
			continue

		_chunk_data_cache[coord] = chunk_data

		if _chunks.has(coord):
			continue

		if _target != null:
			var center_chunk: Vector2i = _world_position_to_chunk(_target.global_position)
			if not _is_within_radius(coord, center_chunk, load_radius):
				continue

		_spawn_chunk_from_result(coord, chunk_data, result.get("surface_arrays", {}), false)

func _consume_collision_queue(count: int = -1) -> void:
	var budget: int = collisions_per_frame if count < 0 else count
	var built_count: int = 0

	while built_count < budget and _pending_collision_builds.size() > 0:
		var coord: Vector2i = _pending_collision_builds[0]
		_pending_collision_builds.remove_at(0)
		_pending_collision_lookup.erase(coord)

		if not _chunks.has(coord):
			continue

		var chunk: SSDChunk = _chunks[coord] as SSDChunk
		if chunk == null:
			continue

		chunk.set_collision_enabled(true)
		built_count += 1

func _spawn_chunk_from_result(chunk_coords: Vector2i, chunk_data: SSDChunkData, surface_arrays: Dictionary, enable_collision_now: bool) -> void:
	var chunk: SSDChunk = _chunks.get(chunk_coords, null) as SSDChunk
	if chunk == null:
		chunk = SSDChunk.new()
		add_child(chunk)
		_chunks[chunk_coords] = chunk

	_pending_chunk_rebuild_lookup.erase(chunk_coords)
	chunk.setup(chunk_coords, chunk_data, _chunk_material_opaque, _chunk_material_transparent)
	chunk.apply_surface_arrays(surface_arrays)
	chunk.set_collision_enabled(enable_collision_now)
	_queue_chunk_gravity(chunk_coords, chunk_data)

	if not enable_collision_now and _target != null:
		var center_chunk: Vector2i = _world_position_to_chunk(_target.global_position)
		if _is_within_radius(chunk_coords, center_chunk, collision_radius) and not _pending_collision_lookup.has(chunk_coords):
			_pending_collision_builds.append(chunk_coords)
			_pending_collision_lookup[chunk_coords] = true

func _queue_chunk_gravity(chunk_coords: Vector2i, chunk_data: SSDChunkData) -> void:
	if chunk_data == null:
		return
	var base_x: int = chunk_coords.x * SSDChunkConfig.SIZE_X
	var base_z: int = chunk_coords.y * SSDChunkConfig.SIZE_Z
	for local_y: int in range(1, SSDChunkConfig.SIZE_Y):
		for local_z: int in range(SSDChunkConfig.SIZE_Z):
			for local_x: int in range(SSDChunkConfig.SIZE_X):
				if chunk_data.get_block(local_x, local_y, local_z) != SSDVoxelDefs.BlockId.SAND:
					continue
				var below_id: int = chunk_data.get_block(local_x, local_y - 1, local_z)
				if below_id == SSDVoxelDefs.BlockId.AIR or SSDVoxelDefs.is_fluid(below_id):
					_queue_gravity_update(Vector3i(base_x + local_x, local_y, base_z + local_z))

func _ensure_chunk_loaded_sync(chunk_coords: Vector2i, enable_collision_now: bool) -> void:
	var chunk_data: SSDChunkData = _ensure_chunk_data_cached(chunk_coords)
	var surface_arrays: Dictionary = SSDChunkMesher.build_surface_arrays_runtime(self, chunk_coords, chunk_data)
	_spawn_chunk_from_result(chunk_coords, chunk_data, surface_arrays, enable_collision_now)

func _ensure_chunk_data_cached(chunk_coords: Vector2i) -> SSDChunkData:
	if _chunk_data_cache.has(chunk_coords):
		return _chunk_data_cache[chunk_coords] as SSDChunkData

	var payload: Dictionary = SSDTerrainGenerator.generate_chunk_payload(
		chunk_coords,
		world_seed,
		base_height,
		height_variation,
		primary_frequency,
		detail_frequency
	)
	var chunk_data: SSDChunkData = payload.get("chunk_data", null) as SSDChunkData
	_chunk_data_cache[chunk_coords] = chunk_data
	return chunk_data

func _rebuild_loaded_chunk(chunk_coords: Vector2i) -> void:
	if not _chunks.has(chunk_coords):
		return

	var chunk: SSDChunk = _chunks[chunk_coords] as SSDChunk
	if chunk == null:
		return

	var chunk_data: SSDChunkData = _ensure_chunk_data_cached(chunk_coords)
	var had_collision: bool = chunk.has_collision_enabled()
	var surface_arrays: Dictionary = SSDChunkMesher.build_surface_arrays_runtime(self, chunk_coords, chunk_data)
	chunk.apply_surface_arrays(surface_arrays)
	chunk.set_collision_enabled(false)
	if had_collision and not _pending_collision_lookup.has(chunk_coords):
		_pending_collision_builds.append(chunk_coords)
		_pending_collision_lookup[chunk_coords] = true

func _enqueue_worker_job(coord: Vector2i, revision: int) -> void:
	_worker_mutex.lock()
	_worker_jobs.append({
		"coord": coord,
		"revision": revision,
	})
	_worker_mutex.unlock()
	_worker_semaphore.post()

func _clear_worker_queues() -> void:
	_worker_mutex.lock()
	_worker_jobs.clear()
	_worker_completed.clear()
	_worker_mutex.unlock()

func _worker_loop() -> void:
	while true:
		_worker_semaphore.wait()

		var job: Dictionary = {}
		var should_exit: bool = false

		_worker_mutex.lock()
		should_exit = _worker_exit_requested
		if _worker_jobs.size() > 0:
			job = _worker_jobs[0]
			_worker_jobs.remove_at(0)
		_worker_mutex.unlock()

		if should_exit and job.is_empty():
			break

		if job.is_empty():
			continue

		var result: Dictionary = _build_chunk_result(job)

		_worker_mutex.lock()
		_worker_completed.append(result)
		_worker_mutex.unlock()

func _build_chunk_result(job: Dictionary) -> Dictionary:
	var coord: Vector2i = job.get("coord", Vector2i.ZERO)
	var revision: int = job.get("revision", 0)
	var payload: Dictionary = SSDTerrainGenerator.generate_chunk_payload(
		coord,
		world_seed,
		base_height,
		height_variation,
		primary_frequency,
		detail_frequency
	)
	var chunk_data: SSDChunkData = payload.get("chunk_data", null) as SSDChunkData
	var height_cache: PackedInt32Array = payload.get("height_cache", PackedInt32Array())
	var surface_arrays: Dictionary = SSDChunkMesher.build_surface_arrays(coord, chunk_data, height_cache, SSDTerrainGenerator.SEA_LEVEL)

	return {
		"coord": coord,
		"revision": revision,
		"data": chunk_data,
		"surface_arrays": surface_arrays,
	}

func _start_worker() -> void:
	if _worker_running:
		return

	_worker_exit_requested = false
	_worker_threads.clear()

	var started_any: bool = false
	for i: int in range(max(1, worker_thread_count)):
		var worker: Thread = Thread.new()
		var err: Error = worker.start(Callable(self, "_worker_loop"))
		if err == OK:
			_worker_threads.append(worker)
			started_any = true
		else:
			push_error("SSDWorld: Failed to start terrain worker thread %d." % i)

	_worker_running = started_any

func _shutdown_worker() -> void:
	if not _worker_running:
		return

	_worker_mutex.lock()
	_worker_exit_requested = true
	_worker_mutex.unlock()

	for _i: int in range(_worker_threads.size()):
		_worker_semaphore.post()

	for worker: Thread in _worker_threads:
		worker.wait_to_finish()

	_worker_threads.clear()
	_worker_running = false

func _build_noises() -> void:
	_terrain_noises = SSDTerrainGenerator._create_noises(world_seed, primary_frequency, detail_frequency)

func _build_materials() -> void:
	var atlas: Texture2D = load("res://assets/textures/blocks/terrain_atlas.png") as Texture2D

	_chunk_material_opaque = StandardMaterial3D.new()
	_chunk_material_opaque.vertex_color_use_as_albedo = true
	_chunk_material_opaque.roughness = 1.0
	_chunk_material_opaque.metallic = 0.0
	_chunk_material_opaque.cull_mode = BaseMaterial3D.CULL_BACK
	_chunk_material_opaque.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_chunk_material_opaque.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_chunk_material_opaque.alpha_scissor_threshold = 0.5
	_chunk_material_opaque.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_chunk_material_opaque.albedo_texture = atlas
	_chunk_material_opaque.albedo_color = Color(0.56, 0.56, 0.56, 1.0)

	_chunk_material_transparent = StandardMaterial3D.new()
	_chunk_material_transparent.vertex_color_use_as_albedo = true
	_chunk_material_transparent.roughness = 1.0
	_chunk_material_transparent.metallic = 0.0
	_chunk_material_transparent.cull_mode = BaseMaterial3D.CULL_BACK
	_chunk_material_transparent.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_chunk_material_transparent.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_chunk_material_transparent.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_chunk_material_transparent.albedo_texture = atlas
	_chunk_material_transparent.albedo_color = Color(0.56, 0.56, 0.56, 0.82)

func _world_position_to_chunk(world_position: Vector3) -> Vector2i:
	var block_x: int = floori(world_position.x / SSDChunkConfig.VOXEL_SIZE)
	var block_z: int = floori(world_position.z / SSDChunkConfig.VOXEL_SIZE)
	return _block_to_chunk_coords(block_x, block_z)

func _block_to_chunk_coords(block_x: int, block_z: int) -> Vector2i:
	var chunk_x: int = floori(float(block_x) / float(SSDChunkConfig.SIZE_X))
	var chunk_z: int = floori(float(block_z) / float(SSDChunkConfig.SIZE_Z))
	return Vector2i(chunk_x, chunk_z)

func _sort_coords_by_distance(coords: Array[Vector2i], center_chunk: Vector2i) -> Array[Vector2i]:
	var sorted_coords: Array[Vector2i] = coords.duplicate()
	sorted_coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da: int = maxi(abs(a.x - center_chunk.x), abs(a.y - center_chunk.y))
		var db: int = maxi(abs(b.x - center_chunk.x), abs(b.y - center_chunk.y))
		if da == db:
			var ax: int = abs(a.x - center_chunk.x) + abs(a.y - center_chunk.y)
			var bx: int = abs(b.x - center_chunk.x) + abs(b.y - center_chunk.y)
			return ax < bx
		return da < db
	)
	return sorted_coords

func _get_coords_in_radius(center_chunk: Vector2i, radius: int) -> Array[Vector2i]:
	var ordered: Array[Vector2i] = []

	for ring: int in range(radius + 1):
		for dz: int in range(-ring, ring + 1):
			for dx: int in range(-ring, ring + 1):
				if max(abs(dx), abs(dz)) != ring:
					continue

				ordered.append(Vector2i(center_chunk.x + dx, center_chunk.y + dz))

	return ordered

func _is_within_radius(coord: Vector2i, center_coord: Vector2i, radius: int) -> bool:
	return abs(coord.x - center_coord.x) <= radius and abs(coord.y - center_coord.y) <= radius


func _consume_crop_growth_attempts(attempt_count: int) -> void:
	if _chunks.is_empty():
		return
	var chunk_coords_list: Array = _chunks.keys()
	for _attempt_index: int in range(attempt_count):
		var chunk_coords: Vector2i = chunk_coords_list[randi() % chunk_coords_list.size()]
		_attempt_crop_growth_in_chunk(chunk_coords)

func _attempt_crop_growth_in_chunk(chunk_coords: Vector2i) -> void:
	var chunk_data: SSDChunkData = _ensure_chunk_data_cached(chunk_coords)
	if chunk_data == null:
		return
	var local_x: int = randi() % SSDChunkConfig.SIZE_X
	var local_z: int = randi() % SSDChunkConfig.SIZE_Z
	for local_y: int in range(SSDChunkConfig.SIZE_Y - 1, -1, -1):
		var block_id: int = chunk_data.get_block(local_x, local_y, local_z)
		if block_id == SSDVoxelDefs.BlockId.AIR:
			continue
		var world_x: int = chunk_coords.x * SSDChunkConfig.SIZE_X + local_x
		var world_z: int = chunk_coords.y * SSDChunkConfig.SIZE_Z + local_z
		var block_pos: Vector3i = Vector3i(world_x, local_y, world_z)
		if block_id == SSDVoxelDefs.BlockId.MANGO_SAPLING:
			if randf() <= SSDCrops.get_growth_chance(block_id, _has_nearby_water(block_pos)):
				_try_grow_mango_tree(block_pos)
			return
		if not SSDCrops.can_grow(block_id):
			return
		if not _can_crop_grow_at(block_pos, block_id):
			return
		if randf() <= SSDCrops.get_growth_chance(block_id, _has_nearby_water(block_pos)):
			request_set_block_global(block_pos.x, block_pos.y, block_pos.z, SSDCrops.get_next_stage(block_id), false)
		return

func _can_crop_grow_at(block_pos: Vector3i, block_id: int) -> bool:
	var below_id: int = get_block_global(block_pos.x, block_pos.y - 1, block_pos.z)
	if SSDCrops.requires_farmland(block_id):
		return below_id == SSDVoxelDefs.BlockId.FARMLAND
	if SSDVoxelDefs.is_bush_block(block_id) or block_id == SSDVoxelDefs.BlockId.MANGO_SAPLING:
		return below_id == SSDVoxelDefs.BlockId.GRASS or below_id == SSDVoxelDefs.BlockId.DIRT or below_id == SSDVoxelDefs.BlockId.FARMLAND
	return true

func _has_nearby_water(block_pos: Vector3i) -> bool:
	for dz: int in range(-2, 3):
		for dx: int in range(-2, 3):
			for dy: int in range(-1, 2):
				var neighbor_id: int = get_block_global(block_pos.x + dx, block_pos.y + dy, block_pos.z + dz)
				if SSDVoxelDefs.is_fluid(neighbor_id):
					return true
	return false

func _try_grow_mango_tree(sapling_pos: Vector3i) -> void:
	var changes: Array[Dictionary] = []
	for trunk_y: int in range(0, 3):
		changes.append({"x": sapling_pos.x, "y": sapling_pos.y + trunk_y, "z": sapling_pos.z, "id": SSDVoxelDefs.BlockId.OAK_LOG})
	for leaf_y: int in range(2, 5):
		for leaf_z: int in range(-1, 2):
			for leaf_x: int in range(-1, 2):
				var ax: int = sapling_pos.x + leaf_x
				var ay: int = sapling_pos.y + leaf_y
				var az: int = sapling_pos.z + leaf_z
				if leaf_x == 0 and leaf_z == 0 and leaf_y <= 3:
					continue
				var current_id: int = get_block_global(ax, ay, az)
				if current_id == SSDVoxelDefs.BlockId.AIR or current_id == SSDVoxelDefs.BlockId.MANGO_SAPLING or current_id == SSDVoxelDefs.BlockId.OAK_LEAVES:
					changes.append({"x": ax, "y": ay, "z": az, "id": SSDVoxelDefs.BlockId.MANGO_LEAVES})
	request_set_blocks_batch(changes, true, false)
