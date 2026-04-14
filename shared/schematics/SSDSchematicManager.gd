extends Node
class_name SSDSchematicManager

const SCHEM_DIR: String = "user://ssd_schematics"

var _world: SSDWorld
var _pos1_set: bool = false
var _pos2_set: bool = false
var _pos1: Vector3i = Vector3i.ZERO
var _pos2: Vector3i = Vector3i.ZERO
var _loaded_name: String = ""
var _loaded_data: Dictionary = {}

func set_world(world: SSDWorld) -> void:
    _world = world

func set_pos1(pos: Vector3i) -> void:
    _pos1 = pos
    _pos1_set = true

func set_pos2(pos: Vector3i) -> void:
    _pos2 = pos
    _pos2_set = true

func clear_selection() -> void:
    _pos1_set = false
    _pos2_set = false
    _pos1 = Vector3i.ZERO
    _pos2 = Vector3i.ZERO

func has_complete_selection() -> bool:
    return _pos1_set and _pos2_set

func get_selection_bounds() -> Dictionary:
    if not has_complete_selection():
        return {}
    var min_pos := Vector3i(mini(_pos1.x, _pos2.x), mini(_pos1.y, _pos2.y), mini(_pos1.z, _pos2.z))
    var max_pos := Vector3i(maxi(_pos1.x, _pos2.x), maxi(_pos1.y, _pos2.y), maxi(_pos1.z, _pos2.z))
    var size := (max_pos - min_pos) + Vector3i.ONE
    return {"min": min_pos, "max": max_pos, "size": size}

func capture_selection(schem_name: String, include_air: bool = false) -> Dictionary:
    if _world == null or not has_complete_selection():
        return {}
    var bounds := get_selection_bounds()
    if bounds.is_empty():
        return {}
    var min_pos: Vector3i = bounds["min"]
    var max_pos: Vector3i = bounds["max"]
    var palette_ids: Array[int] = []
    var palette_map: Dictionary = {}
    var blocks: Array[Dictionary] = []

    for y: int in range(min_pos.y, max_pos.y + 1):
        for z: int in range(min_pos.z, max_pos.z + 1):
            for x: int in range(min_pos.x, max_pos.x + 1):
                var block_id: int = _world.get_block_global(x, y, z)
                if block_id == 0 and not include_air:
                    continue
                if not palette_map.has(block_id):
                    palette_map[block_id] = palette_ids.size()
                    palette_ids.append(block_id)
                blocks.append({
                    "x": x - min_pos.x,
                    "y": y - min_pos.y,
                    "z": z - min_pos.z,
                    "p": int(palette_map[block_id]),
                })

    var size: Vector3i = bounds["size"]
    return {
        "name": schem_name,
        "size": {"x": size.x, "y": size.y, "z": size.z},
        "palette": palette_ids,
        "blocks": blocks,
        "origin": {"x": _pos1.x, "y": _pos1.y, "z": _pos1.z},
        "include_air": include_air,
        "version": 1,
    }

func save_selection(schem_name: String, include_air: bool = false) -> bool:
    var data := capture_selection(schem_name, include_air)
    if data.is_empty():
        return false
    _ensure_dir()
    var path := "%s/%s.json" % [SCHEM_DIR, _sanitize_name(schem_name)]
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data, "  "))
    _loaded_name = schem_name
    _loaded_data = data.duplicate(true)
    return true

func load_schematic(schem_name: String) -> bool:
    _ensure_dir()
    var path := "%s/%s.json" % [SCHEM_DIR, _sanitize_name(schem_name)]
    if not FileAccess.file_exists(path):
        return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    _loaded_name = schem_name
    _loaded_data = (parsed as Dictionary).duplicate(true)
    return true

func has_loaded_schematic() -> bool:
    return not _loaded_data.is_empty()

func get_loaded_name() -> String:
    return _loaded_name

func get_loaded_size() -> Vector3i:
    if _loaded_data.is_empty():
        return Vector3i.ZERO
    var size_data: Dictionary = _loaded_data.get("size", {})
    return Vector3i(int(size_data.get("x", 0)), int(size_data.get("y", 0)), int(size_data.get("z", 0)))

func list_schematics() -> PackedStringArray:
    _ensure_dir()
    var names := PackedStringArray()
    var dir := DirAccess.open(SCHEM_DIR)
    if dir == null:
        return names
    dir.list_dir_begin()
    while true:
        var file_name := dir.get_next()
        if file_name == "":
            break
        if dir.current_is_dir():
            continue
        if file_name.get_extension().to_lower() == "json":
            names.append(file_name.get_basename())
    dir.list_dir_end()
    names.sort()
    return names

func rotate_loaded_y(clockwise_steps: int) -> bool:
    if _loaded_data.is_empty():
        return false
    var steps: int = ((clockwise_steps % 4) + 4) % 4
    if steps == 0:
        return true

    var size: Vector3i = get_loaded_size()
    var src_blocks: Array = _loaded_data.get("blocks", [])
    var rotated_blocks: Array[Dictionary] = []
    var new_size: Vector3i = size

    for _i: int in range(steps):
        new_size = Vector3i(new_size.z, new_size.y, new_size.x)

    for entry_variant: Variant in src_blocks:
        if typeof(entry_variant) != TYPE_DICTIONARY:
            continue
        var entry: Dictionary = entry_variant
        var pos := Vector3i(int(entry.get("x", 0)), int(entry.get("y", 0)), int(entry.get("z", 0)))
        var current_size := size
        for _step: int in range(steps):
            pos = Vector3i(current_size.z - 1 - pos.z, pos.y, pos.x)
            current_size = Vector3i(current_size.z, current_size.y, current_size.x)
        rotated_blocks.append({"x": pos.x, "y": pos.y, "z": pos.z, "p": int(entry.get("p", 0))})
    _loaded_data["blocks"] = rotated_blocks
    _loaded_data["size"] = {"x": new_size.x, "y": new_size.y, "z": new_size.z}
    return true

func paste_loaded(origin: Vector3i, include_air: bool = false) -> int:
    if _world == null or _loaded_data.is_empty():
        return 0
    var palette: Array = _loaded_data.get("palette", [])
    var blocks: Array = _loaded_data.get("blocks", [])
    var changes: Array[Dictionary] = []
    for entry_variant: Variant in blocks:
        if typeof(entry_variant) != TYPE_DICTIONARY:
            continue
        var entry: Dictionary = entry_variant
        var palette_index: int = int(entry.get("p", 0))
        if palette_index < 0 or palette_index >= palette.size():
            continue
        var block_id: int = int(palette[palette_index])
        if block_id == SSDVoxelDefs.BlockId.AIR and not include_air:
            continue
        var target := origin + Vector3i(int(entry.get("x", 0)), int(entry.get("y", 0)), int(entry.get("z", 0)))
        changes.append({"x": target.x, "y": target.y, "z": target.z, "id": block_id})
    return _world.request_set_blocks_batch(changes, include_air)

func get_loaded_data() -> Dictionary:
    return _loaded_data.duplicate(true)

func _ensure_dir() -> void:
    if not DirAccess.dir_exists_absolute(SCHEM_DIR):
        DirAccess.make_dir_recursive_absolute(SCHEM_DIR)

func _sanitize_name(schem_name: String) -> String:
    var out := schem_name.strip_edges().to_lower()
    out = out.replace(" ", "_")
    for bad: String in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
        out = out.replace(bad, "_")
    return out
