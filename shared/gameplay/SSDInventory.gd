extends Node
class_name SSDInventory

signal inventory_changed
signal selected_hotbar_changed(index: int)

const HOTBAR_COUNT: int = 9
const MAIN_SLOT_COUNT: int = 27
const EQUIPMENT_SLOT_COUNT: int = 7
const MAIN_SLOT_START: int = HOTBAR_COUNT
const EQUIPMENT_START_INDEX: int = HOTBAR_COUNT + MAIN_SLOT_COUNT
const SLOT_COUNT: int = HOTBAR_COUNT + MAIN_SLOT_COUNT + EQUIPMENT_SLOT_COUNT
const MAX_STACK: int = 64

const EQUIPMENT_NAMES: PackedStringArray = [
    "Head",
    "Gloves",
    "Shirt",
    "Jacket",
    "Pants",
    "Belt",
    "Boots",
]

var _slot_block_ids: PackedInt32Array = PackedInt32Array()
var _slot_counts: PackedInt32Array = PackedInt32Array()
var _selected_hotbar_index: int = 0
var _initialized: bool = false

func _init() -> void:
    _initialize_slots()

func _ready() -> void:
    if not _initialized:
        _initialize_slots()
    inventory_changed.emit()
    selected_hotbar_changed.emit(_selected_hotbar_index)

func _initialize_slots() -> void:
    _slot_block_ids.resize(SLOT_COUNT)
    _slot_counts.resize(SLOT_COUNT)
    for i: int in range(SLOT_COUNT):
        _slot_block_ids[i] = SSDVoxelDefs.BlockId.AIR
        _slot_counts[i] = 0
    _initialized = true

func clear_all() -> void:
    for i: int in range(SLOT_COUNT):
        _slot_block_ids[i] = SSDItemDefs.ITEM_AIR
        _slot_counts[i] = 0
    inventory_changed.emit()

func get_slot_count() -> int:
    return SLOT_COUNT

func get_hotbar_count() -> int:
    return HOTBAR_COUNT

func get_selected_hotbar_index() -> int:
    return _selected_hotbar_index

func set_selected_hotbar_index(index: int) -> void:
    if index < 0 or index >= HOTBAR_COUNT:
        return
    _selected_hotbar_index = index
    selected_hotbar_changed.emit(_selected_hotbar_index)
    inventory_changed.emit()

func cycle_hotbar(direction: int) -> void:
    _selected_hotbar_index = posmod(_selected_hotbar_index + direction, HOTBAR_COUNT)
    selected_hotbar_changed.emit(_selected_hotbar_index)
    inventory_changed.emit()

func get_slot_block_id(index: int) -> int:
    if index < 0 or index >= SLOT_COUNT or index >= _slot_block_ids.size():
        return SSDVoxelDefs.BlockId.AIR
    return _slot_block_ids[index]

func get_slot_count_value(index: int) -> int:
    if index < 0 or index >= SLOT_COUNT or index >= _slot_counts.size():
        return 0
    return _slot_counts[index]

func set_slot(index: int, block_id: int, count: int) -> void:
    if index < 0 or index >= SLOT_COUNT:
        return
    _set_slot(index, block_id, count)
    inventory_changed.emit()

func clear_slot(index: int) -> void:
    set_slot(index, SSDVoxelDefs.BlockId.AIR, 0)

func get_selected_block_id() -> int:
    return get_slot_block_id(_selected_hotbar_index)

func get_selected_block_count() -> int:
    return get_slot_count_value(_selected_hotbar_index)

func get_selected_block_name() -> String:
    return SSDItemDefs.get_display_id(get_selected_block_id())

func try_consume_selected_one() -> int:
    var block_id: int = get_selected_block_id()
    if block_id == SSDVoxelDefs.BlockId.AIR:
        return SSDVoxelDefs.BlockId.AIR

    var count: int = get_selected_block_count()
    if count <= 0:
        clear_slot(_selected_hotbar_index)
        return SSDVoxelDefs.BlockId.AIR

    _slot_counts[_selected_hotbar_index] = count - 1
    if _slot_counts[_selected_hotbar_index] <= 0:
        _slot_block_ids[_selected_hotbar_index] = SSDVoxelDefs.BlockId.AIR
        _slot_counts[_selected_hotbar_index] = 0

    inventory_changed.emit()
    return block_id

func add_items(block_id: int, count: int) -> int:
    if block_id == SSDItemDefs.ITEM_AIR or count <= 0:
        return count

    var remaining: int = count
    remaining = _merge_into_range(block_id, remaining, 0, HOTBAR_COUNT + MAIN_SLOT_COUNT - 1)
    if remaining > 0:
        remaining = _fill_empty_in_range(block_id, remaining, 0, HOTBAR_COUNT + MAIN_SLOT_COUNT - 1)

    inventory_changed.emit()
    return remaining

func try_drop_one_selected() -> int:
    return try_consume_selected_one()

func pick_block_creative(block_id: int) -> void:
    if not SSDItemDefs.is_placeable_block(block_id):
        return

    for i: int in range(HOTBAR_COUNT):
        if _slot_block_ids[i] == block_id and _slot_counts[i] > 0:
            _slot_counts[i] = MAX_STACK
            set_selected_hotbar_index(i)
            inventory_changed.emit()
            return

    for i: int in range(HOTBAR_COUNT):
        if _slot_counts[i] <= 0:
            _set_slot(i, block_id, MAX_STACK)
            set_selected_hotbar_index(i)
            inventory_changed.emit()
            return

    _set_slot(_selected_hotbar_index, block_id, MAX_STACK)
    inventory_changed.emit()

func ensure_creative_loadout() -> void:
    _set_slot(0, SSDVoxelDefs.BlockId.GRASS, MAX_STACK)
    _set_slot(1, SSDVoxelDefs.BlockId.DIRT, MAX_STACK)
    _set_slot(2, SSDVoxelDefs.BlockId.STONE, MAX_STACK)
    _set_slot(3, SSDVoxelDefs.BlockId.WATER, MAX_STACK)
    _set_slot(4, SSDVoxelDefs.BlockId.COAL_ORE, MAX_STACK)
    _set_slot(5, SSDVoxelDefs.BlockId.IRON_ORE, MAX_STACK)
    _set_slot(6, SSDVoxelDefs.BlockId.CRAFTING_TABLE, MAX_STACK)
    _set_slot(7, SSDVoxelDefs.BlockId.COBBLESTONE, MAX_STACK)
    _set_slot(8, SSDVoxelDefs.BlockId.FURNACE, MAX_STACK)
    _set_slot(MAIN_SLOT_START, SSDItemDefs.ITEM_SHIRT_RED, 1)
    _set_slot(MAIN_SLOT_START + 1, SSDItemDefs.ITEM_HOODIE_RED, 1)
    _set_slot(MAIN_SLOT_START + 2, SSDItemDefs.ITEM_COAL, 64)
    _set_slot(MAIN_SLOT_START + 3, SSDItemDefs.ITEM_IRON_CHUNK, 32)
    _set_slot(MAIN_SLOT_START + 4, SSDItemDefs.ITEM_IRON_INGOT, 16)
    inventory_changed.emit()

func move_or_merge(left_index: int, right_index: int) -> void:
    if left_index == right_index:
        return
    if left_index < 0 or right_index < 0 or left_index >= SLOT_COUNT or right_index >= SLOT_COUNT:
        return

    var left_id: int = _slot_block_ids[left_index]
    var left_count: int = _slot_counts[left_index]
    var right_id: int = _slot_block_ids[right_index]
    var right_count: int = _slot_counts[right_index]

    if left_count <= 0:
        _set_slot(left_index, right_id, right_count)
        _set_slot(right_index, SSDVoxelDefs.BlockId.AIR, 0)
        inventory_changed.emit()
        return

    if right_count > 0 and left_id == right_id and right_count < MAX_STACK:
        var transferable: int = min(MAX_STACK - right_count, left_count)
        _slot_counts[right_index] += transferable
        _slot_counts[left_index] -= transferable
        if _slot_counts[left_index] <= 0:
            _slot_block_ids[left_index] = SSDVoxelDefs.BlockId.AIR
            _slot_counts[left_index] = 0
        inventory_changed.emit()
        return

    _set_slot(left_index, right_id, right_count)
    _set_slot(right_index, left_id, left_count)
    inventory_changed.emit()

func take_half(index: int) -> Dictionary:
    if index < 0 or index >= SLOT_COUNT:
        return {"block_id": SSDVoxelDefs.BlockId.AIR, "count": 0}
    var slot_count: int = _slot_counts[index]
    if slot_count <= 0:
        return {"block_id": SSDVoxelDefs.BlockId.AIR, "count": 0}

    var taken: int = int(ceil(float(slot_count) * 0.5))
    _slot_counts[index] = slot_count - taken
    var block_id: int = _slot_block_ids[index]
    if _slot_counts[index] <= 0:
        _slot_block_ids[index] = SSDVoxelDefs.BlockId.AIR
        _slot_counts[index] = 0
    inventory_changed.emit()
    return {"block_id": block_id, "count": taken}

func quick_move(index: int) -> void:
    if index < 0 or index >= SLOT_COUNT:
        return

    var block_id: int = _slot_block_ids[index]
    var count: int = _slot_counts[index]
    if count <= 0 or block_id == SSDItemDefs.ITEM_AIR:
        return

    var remaining: int = count
    if is_hotbar_slot(index):
        if SSDItemDefs.is_equipment_item(block_id):
            var target_name: String = SSDItemDefs.get_equipment_slot_name(block_id)
            for equip_i: int in range(EQUIPMENT_SLOT_COUNT):
                var equip_index: int = EQUIPMENT_START_INDEX + equip_i
                if EQUIPMENT_NAMES[equip_i] == target_name and _slot_counts[equip_index] <= 0:
                    _set_slot(equip_index, block_id, 1)
                    remaining -= 1
                    break
        remaining = _merge_into_range(block_id, remaining, MAIN_SLOT_START, MAIN_SLOT_START + MAIN_SLOT_COUNT - 1, index)
        remaining = _fill_empty_in_range(block_id, remaining, MAIN_SLOT_START, MAIN_SLOT_START + MAIN_SLOT_COUNT - 1, index)
    elif is_main_inventory_slot(index):
        if SSDItemDefs.is_equipment_item(block_id):
            var target_name: String = SSDItemDefs.get_equipment_slot_name(block_id)
            for equip_i: int in range(EQUIPMENT_SLOT_COUNT):
                var equip_index: int = EQUIPMENT_START_INDEX + equip_i
                if EQUIPMENT_NAMES[equip_i] == target_name and _slot_counts[equip_index] <= 0:
                    _set_slot(equip_index, block_id, 1)
                    remaining -= 1
                    break
        remaining = _merge_into_range(block_id, remaining, 0, HOTBAR_COUNT - 1, index)
        remaining = _fill_empty_in_range(block_id, remaining, 0, HOTBAR_COUNT - 1, index)
    elif is_equipment_slot(index):
        remaining = _merge_into_range(block_id, remaining, 0, HOTBAR_COUNT + MAIN_SLOT_COUNT - 1, index)
        remaining = _fill_empty_in_range(block_id, remaining, 0, HOTBAR_COUNT + MAIN_SLOT_COUNT - 1, index)

    _set_slot(index, block_id, remaining)
    inventory_changed.emit()

func try_return_cursor_stack(block_id: int, count: int) -> int:
    if count <= 0 or block_id == SSDItemDefs.ITEM_AIR:
        return 0

    var remaining: int = count
    remaining = _merge_into_range(block_id, remaining, 0, HOTBAR_COUNT + MAIN_SLOT_COUNT - 1)
    remaining = _fill_empty_in_range(block_id, remaining, 0, HOTBAR_COUNT + MAIN_SLOT_COUNT - 1)
    inventory_changed.emit()
    return remaining

func is_hotbar_slot(index: int) -> bool:
    return index >= 0 and index < HOTBAR_COUNT

func is_main_inventory_slot(index: int) -> bool:
    return index >= MAIN_SLOT_START and index < (MAIN_SLOT_START + MAIN_SLOT_COUNT)

func is_equipment_slot(index: int) -> bool:
    return index >= EQUIPMENT_START_INDEX and index < SLOT_COUNT

func get_equipment_slot_label(index: int) -> String:
    return get_equipment_slot_name_by_index(index)

func get_equipment_slot_name_by_index(index: int) -> String:
    if not is_equipment_slot(index):
        return ""
    return EQUIPMENT_NAMES[index - EQUIPMENT_START_INDEX]

func can_place_item_in_slot(item_id: int, slot_index: int) -> bool:
    if item_id == SSDItemDefs.ITEM_AIR:
        return true
    if is_equipment_slot(slot_index):
        return SSDItemDefs.can_equip_in_slot(item_id, get_equipment_slot_name_by_index(slot_index))
    return true

func get_equipped_item_id(slot_name: String) -> int:
    for i: int in range(EQUIPMENT_SLOT_COUNT):
        var index: int = EQUIPMENT_START_INDEX + i
        if EQUIPMENT_NAMES[i] == slot_name:
            return _slot_block_ids[index]
    return SSDItemDefs.ITEM_AIR

func _merge_into_range(block_id: int, count: int, start_index: int, end_index: int, skip_index: int = -1) -> int:
    var remaining: int = count
    for i: int in range(start_index, end_index + 1):
        if i == skip_index:
            continue
        if _slot_block_ids[i] != block_id:
            continue
        if _slot_counts[i] >= MAX_STACK:
            continue
        var addable: int = min(MAX_STACK - _slot_counts[i], remaining)
        _slot_counts[i] += addable
        remaining -= addable
        if remaining <= 0:
            return 0
    return remaining

func _fill_empty_in_range(block_id: int, count: int, start_index: int, end_index: int, skip_index: int = -1) -> int:
    var remaining: int = count
    for i: int in range(start_index, end_index + 1):
        if i == skip_index:
            continue
        if _slot_counts[i] > 0:
            continue
        var add_count: int = min(MAX_STACK, remaining)
        _slot_block_ids[i] = block_id
        _slot_counts[i] = add_count
        remaining -= add_count
        if remaining <= 0:
            return 0
    return remaining

func _set_slot(index: int, block_id: int, count: int) -> void:
    _slot_block_ids[index] = block_id if count > 0 else SSDItemDefs.ITEM_AIR
    _slot_counts[index] = max(0, count)
