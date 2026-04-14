extends RefCounted
class_name SSDCrafting

static func compute_result(grid_ids: PackedInt32Array, grid_width: int, grid_height: int) -> Dictionary:
    var normalized: Dictionary = _normalize_grid(grid_ids, grid_width, grid_height)
    var cells: PackedInt32Array = normalized.get("cells", PackedInt32Array())
    var width: int = int(normalized.get("width", 0))
    var height: int = int(normalized.get("height", 0))
    var non_air: int = int(normalized.get("non_air", 0))
    if non_air <= 0:
        return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0}

    if _matches_exact(cells, width, height, PackedInt32Array([SSDItemDefs.ITEM_OAK_LOG]), 1, 1):
        return {"item_id": SSDItemDefs.ITEM_OAK_PLANKS, "count": 4}

    if _matches_exact(cells, width, height, PackedInt32Array([
        SSDItemDefs.ITEM_OAK_PLANKS,
        SSDItemDefs.ITEM_OAK_PLANKS,
    ]), 1, 2):
        return {"item_id": SSDItemDefs.ITEM_STICK, "count": 4}

    if _matches_uniform(cells, width, height, 2, 2, SSDItemDefs.ITEM_OAK_PLANKS):
        return {"item_id": SSDItemDefs.ITEM_CRAFTING_TABLE, "count": 1}

    if _matches_exact(cells, width, height, PackedInt32Array([
        SSDItemDefs.ITEM_COBBLESTONE, SSDItemDefs.ITEM_COBBLESTONE, SSDItemDefs.ITEM_COBBLESTONE,
        SSDItemDefs.ITEM_COBBLESTONE, SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_COBBLESTONE,
        SSDItemDefs.ITEM_COBBLESTONE, SSDItemDefs.ITEM_COBBLESTONE, SSDItemDefs.ITEM_COBBLESTONE,
    ]), 3, 3):
        return {"item_id": SSDItemDefs.ITEM_FURNACE, "count": 1}

    var pickaxe_recipe: Dictionary = _match_pickaxe_recipe(cells, width, height)
    if int(pickaxe_recipe.get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
        return pickaxe_recipe

    var axe_recipe: Dictionary = _match_axe_recipe(cells, width, height)
    if int(axe_recipe.get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
        return axe_recipe

    if _matches_exact(cells, width, height, PackedInt32Array([
        SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_GLASS, SSDItemDefs.ITEM_AIR,
        SSDItemDefs.ITEM_GLASS, SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_GLASS,
    ]), 3, 2):
        return {"item_id": SSDItemDefs.ITEM_GLASS_BOTTLE, "count": 3}

    return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0}

static func consume_ingredients(grid_ids: PackedInt32Array, grid_counts: PackedInt32Array, grid_width: int, grid_height: int) -> void:
    var result: Dictionary = compute_result(grid_ids, grid_width, grid_height)
    if int(result.get("item_id", SSDItemDefs.ITEM_AIR)) == SSDItemDefs.ITEM_AIR:
        return
    for i: int in range(grid_ids.size()):
        if grid_ids[i] == SSDItemDefs.ITEM_AIR or grid_counts[i] <= 0:
            continue
        grid_counts[i] -= 1
        if grid_counts[i] <= 0:
            grid_ids[i] = SSDItemDefs.ITEM_AIR
            grid_counts[i] = 0

static func _match_pickaxe_recipe(cells: PackedInt32Array, width: int, height: int) -> Dictionary:
    var materials: Array = [
        {"input": SSDItemDefs.ITEM_OAK_PLANKS, "output": SSDItemDefs.ITEM_WOODEN_PICKAXE},
        {"input": SSDItemDefs.ITEM_COBBLESTONE, "output": SSDItemDefs.ITEM_STONE_PICKAXE},
        {"input": SSDItemDefs.ITEM_IRON_INGOT, "output": SSDItemDefs.ITEM_IRON_PICKAXE},
    ]
    for entry_variant in materials:
        var entry: Dictionary = entry_variant
        var material_id: int = int(entry.get("input", SSDItemDefs.ITEM_AIR))
        if _matches_exact(cells, width, height, PackedInt32Array([
            material_id, material_id, material_id,
            SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_STICK, SSDItemDefs.ITEM_AIR,
            SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_STICK, SSDItemDefs.ITEM_AIR,
        ]), 3, 3):
            return {"item_id": int(entry.get("output", SSDItemDefs.ITEM_AIR)), "count": 1}
    return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0}

static func _match_axe_recipe(cells: PackedInt32Array, width: int, height: int) -> Dictionary:
    var materials: Array = [
        {"input": SSDItemDefs.ITEM_OAK_PLANKS, "output": SSDItemDefs.ITEM_WOODEN_AXE},
        {"input": SSDItemDefs.ITEM_COBBLESTONE, "output": SSDItemDefs.ITEM_STONE_AXE},
        {"input": SSDItemDefs.ITEM_IRON_INGOT, "output": SSDItemDefs.ITEM_IRON_AXE},
    ]
    for entry_variant in materials:
        var entry: Dictionary = entry_variant
        var material_id: int = int(entry.get("input", SSDItemDefs.ITEM_AIR))
        var left_pattern: PackedInt32Array = PackedInt32Array([
            material_id, material_id,
            material_id, SSDItemDefs.ITEM_STICK,
            SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_STICK,
        ])
        var right_pattern: PackedInt32Array = PackedInt32Array([
            material_id, material_id,
            SSDItemDefs.ITEM_STICK, material_id,
            SSDItemDefs.ITEM_STICK, SSDItemDefs.ITEM_AIR,
        ])
        if _matches_exact(cells, width, height, left_pattern, 2, 3) or _matches_exact(cells, width, height, right_pattern, 2, 3):
            return {"item_id": int(entry.get("output", SSDItemDefs.ITEM_AIR)), "count": 1}
    return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0}

static func _matches_uniform(cells: PackedInt32Array, width: int, height: int, expected_width: int, expected_height: int, item_id: int) -> bool:
    if width != expected_width or height != expected_height or cells.size() != expected_width * expected_height:
        return false
    for value: int in cells:
        if value != item_id:
            return false
    return true

static func _matches_exact(cells: PackedInt32Array, width: int, height: int, expected: PackedInt32Array, expected_width: int, expected_height: int) -> bool:
    if width != expected_width or height != expected_height or cells.size() != expected.size():
        return false
    for i: int in range(expected.size()):
        if cells[i] != expected[i]:
            return false
    return true

static func _normalize_grid(grid_ids: PackedInt32Array, grid_width: int, grid_height: int) -> Dictionary:
    var min_x: int = 999
    var min_y: int = 999
    var max_x: int = -1
    var max_y: int = -1
    var non_air: int = 0

    for y: int in range(grid_height):
        for x: int in range(grid_width):
            var index: int = y * grid_width + x
            var item_id: int = grid_ids[index]
            if item_id == SSDItemDefs.ITEM_AIR:
                continue
            non_air += 1
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)

    if non_air == 0:
        return {"cells": PackedInt32Array(), "width": 0, "height": 0, "non_air": 0}

    var width: int = max_x - min_x + 1
    var height: int = max_y - min_y + 1
    var cells: PackedInt32Array = PackedInt32Array()
    cells.resize(width * height)
    for y: int in range(height):
        for x: int in range(width):
            var src_index: int = (min_y + y) * grid_width + (min_x + x)
            cells[y * width + x] = grid_ids[src_index]
    return {"cells": cells, "width": width, "height": height, "non_air": non_air}
