extends Node3D
class_name SSDPassiveMobSpawner

signal mob_spawned(mob: SSDPassiveMob)

const SSD_PASSIVE_MOB_SCRIPT = preload("res://world/mobs/SSDPassiveMob.gd")

var _world: SSDWorld
var _player: Node3D
var _tick_timer: float = 0.0

func set_targets(world: SSDWorld, player: Node3D) -> void:
    _world = world
    _player = player

func _process(delta: float) -> void:
    if _world == null or _player == null:
        return
    _tick_timer -= delta
    if _tick_timer > 0.0:
        return
    _tick_timer = 4.0
    _maintain_population()

func _maintain_population() -> void:
    var counts: Dictionary = {"sheep": 0, "cow": 0, "chicken": 0}
    for child in get_children():
        var mob: SSDPassiveMob = child as SSDPassiveMob
        if mob != null and counts.has(mob.mob_type):
            counts[mob.mob_type] += 1
    for mob_type: String in counts.keys():
        while int(counts[mob_type]) < 3:
            _spawn_mob(mob_type)
            counts[mob_type] += 1

func spawn_mob_at(mob_type: String, world_position: Vector3) -> SSDPassiveMob:
    if mob_type != "sheep" and mob_type != "cow" and mob_type != "chicken":
        return null
    var mob: SSDPassiveMob = SSD_PASSIVE_MOB_SCRIPT.new() as SSDPassiveMob
    mob.mob_type = mob_type
    mob.name = "%s_%d" % [mob_type.capitalize(), Time.get_ticks_msec()]
    add_child(mob)
    mob.global_position = world_position
    mob_spawned.emit(mob)
    return mob

func _spawn_mob(mob_type: String) -> void:
    var offset: Vector3 = Vector3(randf_range(-20.0, 20.0), 0.0, randf_range(-20.0, 20.0))
    var spawn: Vector3 = _world.get_safe_spawn_position(_player.global_position + offset)
    spawn_mob_at(mob_type, spawn)
