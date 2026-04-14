extends RefCounted
class_name SSDTerrainGenerator

const SEA_LEVEL: int = 24

static func generate_chunk_payload(
    chunk_coords: Vector2i,
    world_seed: int,
    base_height: int,
    height_variation: int,
    primary_frequency: float,
    detail_frequency: float
) -> Dictionary:
    var noises: Dictionary = _create_noises(world_seed, primary_frequency, detail_frequency)
    var chunk_data: SSDChunkData = SSDChunkData.new()
    var cache_width: int = SSDChunkConfig.SIZE_X + 2
    var cache_depth: int = SSDChunkConfig.SIZE_Z + 2
    var height_cache: PackedInt32Array = PackedInt32Array()
    height_cache.resize(cache_width * cache_depth)

    for sample_z: int in range(cache_depth):
        for sample_x: int in range(cache_width):
            var world_x: int = (chunk_coords.x * SSDChunkConfig.SIZE_X) + (sample_x - 1)
            var world_z: int = (chunk_coords.y * SSDChunkConfig.SIZE_Z) + (sample_z - 1)
            var terrain_height: int = get_terrain_height(noises, world_x, world_z, base_height, height_variation)
            height_cache[sample_x + (sample_z * cache_width)] = terrain_height

            if sample_x == 0 or sample_x == cache_width - 1 or sample_z == 0 or sample_z == cache_depth - 1:
                continue

            var local_x: int = sample_x - 1
            var local_z: int = sample_z - 1
            var fill_top: int = max(terrain_height, SEA_LEVEL)
            for local_y: int in range(fill_top + 1):
                var block_id: int = get_generated_block(noises, world_x, local_y, world_z, terrain_height)
                if block_id != SSDVoxelDefs.BlockId.AIR:
                    chunk_data.set_block(local_x, local_y, local_z, block_id)

    _apply_tree_pass(chunk_data, noises, chunk_coords, base_height, height_variation)

    return {
        "chunk_data": chunk_data,
        "height_cache": height_cache,
    }

static func generate_chunk_data(
    chunk_coords: Vector2i,
    world_seed: int,
    base_height: int,
    height_variation: int,
    primary_frequency: float,
    detail_frequency: float
) -> SSDChunkData:
    var payload: Dictionary = generate_chunk_payload(chunk_coords, world_seed, base_height, height_variation, primary_frequency, detail_frequency)
    return payload.get("chunk_data", SSDChunkData.new()) as SSDChunkData

static func build_height_cache(
    chunk_coords: Vector2i,
    world_seed: int,
    base_height: int,
    height_variation: int,
    primary_frequency: float,
    detail_frequency: float
) -> PackedInt32Array:
    var noises: Dictionary = _create_noises(world_seed, primary_frequency, detail_frequency)

    var cache_width: int = SSDChunkConfig.SIZE_X + 2
    var cache_depth: int = SSDChunkConfig.SIZE_Z + 2
    var cache: PackedInt32Array = PackedInt32Array()
    cache.resize(cache_width * cache_depth)

    for sample_z: int in range(cache_depth):
        for sample_x: int in range(cache_width):
            var world_x: int = (chunk_coords.x * SSDChunkConfig.SIZE_X) + (sample_x - 1)
            var world_z: int = (chunk_coords.y * SSDChunkConfig.SIZE_Z) + (sample_z - 1)
            cache[sample_x + (sample_z * cache_width)] = get_terrain_height(
                noises,
                world_x,
                world_z,
                base_height,
                height_variation
            )

    return cache

static func get_terrain_height(
    noises: Dictionary,
    world_x: int,
    world_z: int,
    base_height: int,
    height_variation: int
) -> int:
    var broad_noise: FastNoiseLite = noises["broad"] as FastNoiseLite
    var hill_noise: FastNoiseLite = noises["hill"] as FastNoiseLite
    var feature_noise: FastNoiseLite = noises["feature"] as FastNoiseLite
    var detail_noise: FastNoiseLite = noises["detail"] as FastNoiseLite

    var broad_value: float = broad_noise.get_noise_2d(float(world_x), float(world_z))
    var hill_value: float = hill_noise.get_noise_2d(float(world_x), float(world_z))
    var feature_value: float = feature_noise.get_noise_2d(float(world_x), float(world_z))
    var detail_value: float = detail_noise.get_noise_2d(float(world_x), float(world_z))

    var broad_factor: float = _smooth01((broad_value + 1.0) * 0.5)
    var terrain_relief: float = _smooth01(clampf(((feature_value + 1.0) * 0.5 - 0.26) / 0.54, 0.0, 1.0))
    var wide_hills: float = hill_value * lerpf(0.40, 1.05, broad_factor)
    var terrace_softener: float = sin(float(world_x) * 0.016) * 0.04 + cos(float(world_z) * 0.014) * 0.04
    var detail_term: float = detail_value * 0.12

    var combined_relief: float = (wide_hills + detail_term + terrace_softener) * lerpf(0.14, 1.0, terrain_relief)
    var broad_bias: float = lerpf(-0.28, 0.34, broad_factor)
    var signed_height: float = (broad_bias + combined_relief) * float(height_variation)

    return clampi(base_height + int(round(signed_height)), 3, SSDChunkConfig.SIZE_Y - 6)

static func get_block_for_height(local_y: int, terrain_height: int) -> int:
    return get_generated_block({}, 0, local_y, 0, terrain_height)

static func get_generated_block(_noises: Dictionary, world_x: int, world_y: int, world_z: int, terrain_height: int) -> int:
    if world_y > terrain_height or world_y < 0 or world_y >= SSDChunkConfig.SIZE_Y:
        if world_y <= SEA_LEVEL and world_y >= 0 and world_y < SSDChunkConfig.SIZE_Y and world_y > terrain_height:
            return SSDVoxelDefs.BlockId.WATER
        return SSDVoxelDefs.BlockId.AIR

    if terrain_height <= SEA_LEVEL + 2:
        if world_y == terrain_height:
            return SSDVoxelDefs.BlockId.SAND
        if world_y >= terrain_height - 3:
            return SSDVoxelDefs.BlockId.SAND
    if world_y == terrain_height:
        return SSDVoxelDefs.BlockId.GRASS
    if world_y >= terrain_height - 3:
        return SSDVoxelDefs.BlockId.DIRT

    var ore_block: int = _get_ore_block(world_x, world_y, world_z)
    if ore_block != SSDVoxelDefs.BlockId.STONE:
        return ore_block
    return SSDVoxelDefs.BlockId.STONE

static func _get_ore_block(world_x: int, world_y: int, world_z: int) -> int:
    var coal_hash: int = abs(int((world_x * 73856093) ^ (world_y * 19349663) ^ (world_z * 83492791))) % 1000
    if world_y <= 52 and world_y >= 6 and coal_hash < 18:
        return SSDVoxelDefs.BlockId.COAL_ORE

    var iron_hash: int = abs(int((world_x * 198491317) ^ (world_y * 6542989) ^ (world_z * 357239))) % 1000
    if world_y <= 40 and world_y >= 4 and iron_hash < 12:
        return SSDVoxelDefs.BlockId.IRON_ORE

    return SSDVoxelDefs.BlockId.STONE

static func _create_noises(world_seed: int, primary_frequency: float, detail_frequency: float) -> Dictionary:
    var broad_noise: FastNoiseLite = FastNoiseLite.new()
    broad_noise.seed = world_seed
    broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH as FastNoiseLite.NoiseType
    broad_noise.frequency = maxf(primary_frequency * 0.45, 0.0015)
    broad_noise.fractal_type = FastNoiseLite.FRACTAL_FBM as FastNoiseLite.FractalType
    broad_noise.fractal_octaves = 3
    broad_noise.fractal_gain = 0.5
    broad_noise.fractal_lacunarity = 1.95

    var hill_noise: FastNoiseLite = FastNoiseLite.new()
    hill_noise.seed = world_seed + 41
    hill_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH as FastNoiseLite.NoiseType
    hill_noise.frequency = primary_frequency
    hill_noise.fractal_type = FastNoiseLite.FRACTAL_FBM as FastNoiseLite.FractalType
    hill_noise.fractal_octaves = 4
    hill_noise.fractal_gain = 0.52
    hill_noise.fractal_lacunarity = 2.0

    var feature_noise: FastNoiseLite = FastNoiseLite.new()
    feature_noise.seed = world_seed + 97
    feature_noise.noise_type = FastNoiseLite.TYPE_PERLIN as FastNoiseLite.NoiseType
    feature_noise.frequency = maxf(primary_frequency * 0.55, 0.0020)
    feature_noise.fractal_type = FastNoiseLite.FRACTAL_FBM as FastNoiseLite.FractalType
    feature_noise.fractal_octaves = 2
    feature_noise.fractal_gain = 0.5
    feature_noise.fractal_lacunarity = 2.0

    var detail_noise: FastNoiseLite = FastNoiseLite.new()
    detail_noise.seed = world_seed + 101
    detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN as FastNoiseLite.NoiseType
    detail_noise.frequency = maxf(detail_frequency * 0.55, 0.008)
    detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM as FastNoiseLite.FractalType
    detail_noise.fractal_octaves = 2
    detail_noise.fractal_gain = 0.48
    detail_noise.fractal_lacunarity = 2.0

    return {
        "broad": broad_noise,
        "hill": hill_noise,
        "feature": feature_noise,
        "detail": detail_noise,
    }

static func _smooth01(value: float) -> float:
    var clamped: float = clampf(value, 0.0, 1.0)
    return clamped * clamped * (3.0 - (2.0 * clamped))

static func _apply_tree_pass(chunk_data: SSDChunkData, noises: Dictionary, chunk_coords: Vector2i, base_height: int, height_variation: int) -> void:
    var chunk_origin_x: int = chunk_coords.x * SSDChunkConfig.SIZE_X
    var chunk_origin_z: int = chunk_coords.y * SSDChunkConfig.SIZE_Z
    for world_z: int in range(chunk_origin_z - 3, chunk_origin_z + SSDChunkConfig.SIZE_Z + 4):
        for world_x: int in range(chunk_origin_x - 3, chunk_origin_x + SSDChunkConfig.SIZE_X + 4):
            if not _should_place_tree(noises, world_x, world_z):
                continue
            var terrain_height: int = get_terrain_height(noises, world_x, world_z, base_height, height_variation)
            if terrain_height < SEA_LEVEL - 1:
                continue
            _stamp_tree_into_chunk(chunk_data, chunk_origin_x, chunk_origin_z, world_x, terrain_height + 1, world_z, _tree_variant_seed(world_x, world_z))

static func _should_place_tree(noises: Dictionary, world_x: int, world_z: int) -> bool:
    var broad_noise: FastNoiseLite = noises["broad"] as FastNoiseLite
    var feature_noise: FastNoiseLite = noises["feature"] as FastNoiseLite
    var density_noise: FastNoiseLite = noises["detail"] as FastNoiseLite
    var broad_value: float = (broad_noise.get_noise_2d(float(world_x), float(world_z)) + 1.0) * 0.5
    var feature_value: float = (feature_noise.get_noise_2d(float(world_x), float(world_z)) + 1.0) * 0.5
    var density_value: float = (density_noise.get_noise_2d(float(world_x) * 0.72, float(world_z) * 0.72) + 1.0) * 0.5
    if broad_value < 0.34 or feature_value < 0.42 or density_value < 0.63:
        return false
    var hash_value: int = abs(int((world_x * 734287) ^ (world_z * 912931))) % 23
    return hash_value == 0 or hash_value == 1

static func _tree_variant_seed(world_x: int, world_z: int) -> int:
    return abs(int((world_x * 92821) ^ (world_z * 68917)))

static func _stamp_tree_into_chunk(chunk_data: SSDChunkData, chunk_origin_x: int, chunk_origin_z: int, tree_x: int, tree_y: int, tree_z: int, variant_seed: int) -> void:
    var tree_type: int = variant_seed % 3
    var trunk_height: int = 4 + (variant_seed % 3)
    if tree_type == 1:
        trunk_height += 1
    elif tree_type == 2:
        trunk_height += 2

    for y: int in range(trunk_height):
        _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x, tree_y + y, tree_z, SSDVoxelDefs.BlockId.OAK_LOG)

    var top_y: int = tree_y + trunk_height - 1
    match tree_type:
        0:
            for dy: int in range(-2, 2):
                var radius: int = 2 if dy < 1 else 1
                for dz: int in range(-radius, radius + 1):
                    for dx: int in range(-radius, radius + 1):
                        if abs(dx) + abs(dz) <= radius + 1:
                            _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x + dx, top_y + dy, tree_z + dz, SSDVoxelDefs.BlockId.OAK_LEAVES)
        1:
            for dy: int in range(-1, 3):
                var radius: int = maxi(1, 3 - dy)
                for dz: int in range(-radius, radius + 1):
                    for dx: int in range(-radius, radius + 1):
                        if abs(dx) <= radius and abs(dz) <= radius:
                            _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x + dx, top_y + dy, tree_z + dz, SSDVoxelDefs.BlockId.OAK_LEAVES)
        _:
            for dy: int in range(-2, 2):
                for dz: int in range(-2, 3):
                    for dx: int in range(-2, 3):
                        if dx * dx + dz * dz <= 5:
                            _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x + dx, top_y + dy, tree_z + dz, SSDVoxelDefs.BlockId.OAK_LEAVES)
            for branch_dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x + branch_dir.x, top_y, tree_z + branch_dir.y, SSDVoxelDefs.BlockId.OAK_LOG)
                _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x + (branch_dir.x * 2), top_y, tree_z + (branch_dir.y * 2), SSDVoxelDefs.BlockId.OAK_LEAVES)

    _set_chunk_world_block(chunk_data, chunk_origin_x, chunk_origin_z, tree_x, top_y + 2, tree_z, SSDVoxelDefs.BlockId.OAK_LEAVES)

static func _set_chunk_world_block(chunk_data: SSDChunkData, chunk_origin_x: int, chunk_origin_z: int, world_x: int, world_y: int, world_z: int, block_id: int) -> void:
    if world_y < 0 or world_y >= SSDChunkConfig.SIZE_Y:
        return
    var local_x: int = world_x - chunk_origin_x
    var local_z: int = world_z - chunk_origin_z
    if local_x < 0 or local_x >= SSDChunkConfig.SIZE_X or local_z < 0 or local_z >= SSDChunkConfig.SIZE_Z:
        return
    chunk_data.set_block(local_x, world_y, local_z, block_id)
