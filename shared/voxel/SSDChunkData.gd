extends RefCounted
class_name SSDChunkData

var blocks: PackedInt32Array = PackedInt32Array()

func _init() -> void:
    var total_size: int = SSDChunkConfig.SIZE_X * SSDChunkConfig.SIZE_Y * SSDChunkConfig.SIZE_Z
    blocks.resize(total_size)
    blocks.fill(SSDVoxelDefs.BlockId.AIR)

func get_block(local_x: int, local_y: int, local_z: int) -> int:
    if not is_in_bounds(local_x, local_y, local_z):
        return SSDVoxelDefs.BlockId.AIR

    return blocks[_index(local_x, local_y, local_z)]

func set_block(local_x: int, local_y: int, local_z: int, block_id: int) -> void:
    if not is_in_bounds(local_x, local_y, local_z):
        return

    blocks[_index(local_x, local_y, local_z)] = block_id

func is_in_bounds(local_x: int, local_y: int, local_z: int) -> bool:
    return local_x >= 0         and local_x < SSDChunkConfig.SIZE_X         and local_y >= 0         and local_y < SSDChunkConfig.SIZE_Y         and local_z >= 0         and local_z < SSDChunkConfig.SIZE_Z

func _index(local_x: int, local_y: int, local_z: int) -> int:
    return local_x + (local_z * SSDChunkConfig.SIZE_X) + (local_y * SSDChunkConfig.SIZE_X * SSDChunkConfig.SIZE_Z)
