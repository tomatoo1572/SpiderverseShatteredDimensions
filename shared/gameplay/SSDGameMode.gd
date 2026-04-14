extends Node
class_name SSDGameMode

signal mode_changed(mode: int, mode_name: String)

enum Mode {
    SURVIVAL,
    CREATIVE,
}

var _mode: int = Mode.SURVIVAL

func get_mode() -> int:
    return _mode

func get_mode_name() -> String:
    return "creative" if _mode == Mode.CREATIVE else "survival"

func is_survival() -> bool:
    return _mode == Mode.SURVIVAL

func is_creative() -> bool:
    return _mode == Mode.CREATIVE

func set_mode(new_mode: int) -> void:
    var clamped_mode: int = clampi(new_mode, Mode.SURVIVAL, Mode.CREATIVE)
    if _mode == clamped_mode:
        return
    _mode = clamped_mode
    mode_changed.emit(_mode, get_mode_name())

func set_mode_by_name(mode_name: String) -> void:
    var normalized: String = mode_name.strip_edges().to_lower()
    if normalized == "creative":
        set_mode(Mode.CREATIVE)
    else:
        set_mode(Mode.SURVIVAL)

func toggle_mode() -> void:
    set_mode(Mode.CREATIVE if _mode == Mode.SURVIVAL else Mode.SURVIVAL)
