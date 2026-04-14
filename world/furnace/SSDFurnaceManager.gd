extends Node
class_name SSDFurnaceManager

const SSD_FURNACE_STATE_SCRIPT = preload("res://shared/gameplay/SSDFurnaceState.gd")

var _states: Dictionary = {}

func _ready() -> void:
    set_process(true)


func _process(delta: float) -> void:
    for state_variant in _states.values():
        var state: SSDFurnaceState = state_variant as SSDFurnaceState
        if state != null:
            state.tick(delta)

func get_state(block_pos: Vector3i) -> SSDFurnaceState:
    var key: String = _key_for(block_pos)
    if not _states.has(key):
        _states[key] = SSD_FURNACE_STATE_SCRIPT.new()
    return _states[key] as SSDFurnaceState

func remove_state(block_pos: Vector3i) -> void:
    _states.erase(_key_for(block_pos))

func _key_for(block_pos: Vector3i) -> String:
    return "%d,%d,%d" % [block_pos.x, block_pos.y, block_pos.z]
