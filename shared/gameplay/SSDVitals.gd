extends Node
class_name SSDVitals

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal hunger_changed(current: float, maximum: float)
signal thirst_changed(current: float, maximum: float)
signal died()

@export var base_max_health: float = 100.0
@export var base_max_stamina: float = 100.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var sprint_drain_per_second: float = 18.0
@export var stamina_regen_per_second: float = 20.0
@export var stamina_regen_delay: float = 0.9
@export var base_hunger_drain_per_second: float = 0.10
@export var base_thirst_drain_per_second: float = 0.14
@export var sprint_hunger_bonus_per_second: float = 0.12
@export var sprint_thirst_bonus_per_second: float = 0.28
@export var jump_hunger_cost: float = 0.15
@export var jump_thirst_cost: float = 0.30
@export var min_sprint_start_stamina: float = 6.0
@export var min_jump_stamina: float = 4.0
@export var training_full_drains_per_upgrade: int = 3
@export var training_bonus_per_upgrade: float = 4.0

var max_health: float = 100.0
var max_stamina: float = 100.0
var health: float = 100.0
var current_stamina: float = 100.0
var current_hunger: float = 100.0
var current_thirst: float = 100.0
var _regen_delay_remaining: float = 0.0
var _health_bonus: float = 0.0
var _stamina_bonus: float = 0.0
var _stamina_training_drains: int = 0
var _drained_this_cycle: bool = false

func _ready() -> void:
    max_health = base_max_health
    max_stamina = base_max_stamina
    health = max_health
    current_stamina = max_stamina
    current_hunger = max_hunger
    current_thirst = max_thirst
    _emit_all()

func apply_profile(profile: Dictionary) -> void:
    _health_bonus = maxf(0.0, float(profile.get("health_bonus", 0.0)))
    _stamina_bonus = maxf(0.0, float(profile.get("stamina_bonus", 0.0)))
    _stamina_training_drains = max(0, int(profile.get("stamina_training_drains", 0)))
    training_full_drains_per_upgrade = max(1, int(profile.get("stamina_training_goal", training_full_drains_per_upgrade)))
    var previous_max_health: float = max_health
    var previous_max_stamina: float = max_stamina
    max_health = base_max_health + _health_bonus
    max_stamina = base_max_stamina + _stamina_bonus
    if previous_max_health <= 0.0:
        health = max_health
    else:
        health = clampf(health + (max_health - previous_max_health), 0.0, max_health)
    if previous_max_stamina <= 0.0:
        current_stamina = max_stamina
    else:
        current_stamina = clampf(current_stamina + (max_stamina - previous_max_stamina), 0.0, max_stamina)
    if current_stamina > maxf(max_stamina * 0.35, min_jump_stamina):
        _drained_this_cycle = false
    _emit_all()

func build_profile_patch() -> Dictionary:
    return {
        "health_bonus": _health_bonus,
        "stamina_bonus": _stamina_bonus,
        "stamina_training_drains": _stamina_training_drains,
        "stamina_training_goal": training_full_drains_per_upgrade,
    }

func get_health_bonus() -> float:
    return _health_bonus

func get_stamina_bonus() -> float:
    return _stamina_bonus

func increase_health_bonus(amount: float) -> void:
    if amount <= 0.0:
        return
    _health_bonus += amount
    apply_profile(build_profile_patch())
    _persist_profile()

func increase_stamina_bonus(amount: float) -> void:
    if amount <= 0.0:
        return
    _stamina_bonus += amount
    apply_profile(build_profile_patch())
    _persist_profile()

func tick(delta: float, drain_sprint: bool) -> void:
    _apply_survival_drain(delta, drain_sprint)
    if drain_sprint and can_sprint():
        var previous_stamina: float = current_stamina
        current_stamina = maxf(0.0, current_stamina - (sprint_drain_per_second * delta))
        _regen_delay_remaining = stamina_regen_delay
        _check_training_state(previous_stamina)
        emit_signal("stamina_changed", current_stamina, max_stamina)
        return
    if _regen_delay_remaining > 0.0:
        _regen_delay_remaining = maxf(0.0, _regen_delay_remaining - delta)
        if current_stamina > maxf(max_stamina * 0.35, min_jump_stamina):
            _drained_this_cycle = false
        return
    if current_stamina < max_stamina:
        var regen_scale: float = 1.0
        if current_hunger <= 0.0 or current_thirst <= 0.0:
            regen_scale = 0.35
        current_stamina = minf(max_stamina, current_stamina + (stamina_regen_per_second * regen_scale * delta))
        if current_stamina > maxf(max_stamina * 0.35, min_jump_stamina):
            _drained_this_cycle = false
        emit_signal("stamina_changed", current_stamina, max_stamina)

func _apply_survival_drain(delta: float, drain_sprint: bool) -> void:
    var hunger_drain: float = base_hunger_drain_per_second
    var thirst_drain: float = base_thirst_drain_per_second
    if drain_sprint:
        hunger_drain += sprint_hunger_bonus_per_second
        thirst_drain += sprint_thirst_bonus_per_second
    current_hunger = maxf(0.0, current_hunger - (hunger_drain * delta))
    current_thirst = maxf(0.0, current_thirst - (thirst_drain * delta))
    emit_signal("hunger_changed", current_hunger, max_hunger)
    emit_signal("thirst_changed", current_thirst, max_thirst)

func spend_stamina(amount: float) -> bool:
    if amount <= 0.0:
        return true
    if current_stamina + 0.001 < amount:
        return false
    var previous_stamina: float = current_stamina
    current_stamina = maxf(0.0, current_stamina - amount)
    _regen_delay_remaining = stamina_regen_delay
    _apply_exertion_needs(amount)
    _check_training_state(previous_stamina)
    emit_signal("stamina_changed", current_stamina, max_stamina)
    return true

func _apply_exertion_needs(stamina_amount: float) -> void:
    var hunger_cost: float = (stamina_amount / 4.0) * jump_hunger_cost
    var thirst_cost: float = (stamina_amount / 4.0) * jump_thirst_cost
    current_hunger = maxf(0.0, current_hunger - hunger_cost)
    current_thirst = maxf(0.0, current_thirst - thirst_cost)
    emit_signal("hunger_changed", current_hunger, max_hunger)
    emit_signal("thirst_changed", current_thirst, max_thirst)

func _check_training_state(previous_stamina: float) -> void:
    if previous_stamina > 0.001 and current_stamina <= 0.001 and not _drained_this_cycle:
        _register_full_drain()
    elif current_stamina > maxf(max_stamina * 0.35, min_jump_stamina):
        _drained_this_cycle = false

func _register_full_drain() -> void:
    _drained_this_cycle = true
    _stamina_training_drains += 1
    if _stamina_training_drains >= max(1, training_full_drains_per_upgrade):
        _stamina_training_drains = 0
        _stamina_bonus += training_bonus_per_upgrade
        var previous_max_stamina: float = max_stamina
        max_stamina = base_max_stamina + _stamina_bonus
        current_stamina = clampf(current_stamina + (max_stamina - previous_max_stamina), 0.0, max_stamina)
        emit_signal("stamina_changed", current_stamina, max_stamina)
    _persist_profile()

func _persist_profile() -> void:
    SSDCore.set_current_world_profile(build_profile_patch())

func can_sprint() -> bool:
    return current_stamina >= min_sprint_start_stamina and current_hunger > 0.0 and current_thirst > 0.0

func can_jump(required_cost: float = 0.0) -> bool:
    return current_stamina >= maxf(min_jump_stamina, required_cost)

func restore_hunger(amount: float) -> void:
    if amount <= 0.0:
        return
    current_hunger = minf(max_hunger, current_hunger + amount)
    emit_signal("hunger_changed", current_hunger, max_hunger)

func restore_thirst(amount: float) -> void:
    if amount <= 0.0:
        return
    current_thirst = minf(max_thirst, current_thirst + amount)
    emit_signal("thirst_changed", current_thirst, max_thirst)

func restore_stamina(amount: float) -> void:
    if amount <= 0.0:
        return
    current_stamina = minf(max_stamina, current_stamina + amount)
    if current_stamina > maxf(max_stamina * 0.35, min_jump_stamina):
        _drained_this_cycle = false
    emit_signal("stamina_changed", current_stamina, max_stamina)

func take_damage(amount: float) -> void:
    if amount <= 0.0:
        return
    health = maxf(0.0, health - amount)
    emit_signal("health_changed", health, max_health)
    if health <= 0.0:
        emit_signal("died")

func heal(amount: float) -> void:
    if amount <= 0.0:
        return
    health = minf(max_health, health + amount)
    emit_signal("health_changed", health, max_health)

func restore_full() -> void:
    health = max_health
    current_stamina = max_stamina
    current_hunger = max_hunger
    current_thirst = max_thirst
    _regen_delay_remaining = 0.0
    _drained_this_cycle = false
    _emit_all()

func _emit_all() -> void:
    emit_signal("health_changed", health, max_health)
    emit_signal("stamina_changed", current_stamina, max_stamina)
    emit_signal("hunger_changed", current_hunger, max_hunger)
    emit_signal("thirst_changed", current_thirst, max_thirst)
