extends Node
class_name SSDDayNightCycle

const SSD_SKY_DOME_SCRIPT = preload("res://shared/time/SSDSkyDome.gd")

@export var day_length_seconds: float = 1440.0
@export var sunrise_start_hour: float = 5.0
@export var sunrise_end_hour: float = 7.0
@export var sunset_start_hour: float = 19.0
@export var sunset_end_hour: float = 21.0
@export var initial_hour: float = 12.0
@export var sun_yaw_degrees: float = 35.0

var _sun: DirectionalLight3D
var _world_environment: WorldEnvironment
var _sky_anchor: Node3D
var _elapsed_seconds: float = 0.0
var _day_count: int = 1
var _brightness_percent: float = 50.0

var _sky_dome: SSDSkyDome

func set_targets(sun: DirectionalLight3D, world_environment: WorldEnvironment, sky_anchor: Node3D = null) -> void:
    _sun = sun
    _world_environment = world_environment
    _sky_anchor = sky_anchor
    _ensure_sky_nodes()
    call_deferred("_apply_lighting")

func _process(delta: float) -> void:
    _elapsed_seconds += delta
    if _elapsed_seconds >= day_length_seconds:
        _elapsed_seconds = fmod(_elapsed_seconds, day_length_seconds)
        _day_count += 1
    _apply_lighting()

func get_time_hours() -> float:
    return fmod(initial_hour + ((_elapsed_seconds / day_length_seconds) * 24.0), 24.0)

func set_time_hours(hours: float) -> void:
    var normalized_hour: float = fposmod(hours, 24.0)
    var delta_hours: float = fposmod(normalized_hour - initial_hour, 24.0)
    _elapsed_seconds = (delta_hours / 24.0) * day_length_seconds
    _apply_lighting()

func get_formatted_time() -> String:
    var current_hour: float = get_time_hours()
    var hour_int: int = int(floor(current_hour))
    var minute_int: int = int(round((current_hour - float(hour_int)) * 60.0))
    if minute_int >= 60:
        minute_int = 0
        hour_int = (hour_int + 1) % 24
    return "%02d:%02d" % [hour_int, minute_int]

func get_day_count() -> int:
    return _day_count

func set_brightness_percent(value: float) -> void:
    _brightness_percent = clampf(value, 0.0, 100.0)
    _apply_lighting()

func get_brightness_percent() -> float:
    return _brightness_percent

func _get_brightness_scale() -> float:
    return lerpf(0.82, 1.18, _brightness_percent / 100.0)

func _ensure_sky_nodes() -> void:
    var parent_node: Node = get_parent()
    if parent_node == null:
        return

    if _sky_dome == null:
        _sky_dome = SSD_SKY_DOME_SCRIPT.new() as SSDSkyDome
        _sky_dome.name = "SkyDome"
        parent_node.add_child(_sky_dome)
        parent_node.move_child(_sky_dome, 0)

func _apply_lighting() -> void:
    if _sun == null or _world_environment == null or _world_environment.environment == null:
        return

    var environment: Environment = _world_environment.environment
    var current_hour: float = get_time_hours()
    var daylight: float = _get_daylight_factor(current_hour)
    var brightness_scale: float = _get_brightness_scale()

    var sky_day: Color = Color(0.72, 0.74, 0.82, 1.0)
    var sky_night: Color = Color(0.14, 0.15, 0.24, 1.0)
    var ground_fill_day: Color = Color(0.78, 0.78, 0.80, 1.0)
    var ground_fill_night: Color = Color(0.20, 0.20, 0.26, 1.0)
    var fog_color: Color = sky_night.lerp(sky_day, daylight)
    var ambient_color: Color = ground_fill_night.lerp(ground_fill_day, daylight)

    environment.background_mode = Environment.BG_CLEAR_COLOR
    environment.background_color = fog_color
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = ambient_color
    environment.ambient_light_energy = lerpf(0.38, 0.95, daylight) * brightness_scale
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
    environment.fog_enabled = true
    environment.fog_density = lerpf(0.0018, 0.0007, daylight)
    environment.fog_aerial_perspective = lerpf(0.03, 0.06, daylight)
    environment.fog_light_color = fog_color
    environment.fog_light_energy = lerpf(0.08, 0.18, daylight) * brightness_scale

    _sun.shadow_enabled = false
    _sun.light_energy = 0.0
    _sun.light_indirect_energy = 0.0
    _sun.light_volumetric_fog_energy = 0.0
    _sun.light_color = Color(1.0, 1.0, 1.0, 1.0)

    var sun_progress: float = fposmod((current_hour - 6.0) / 24.0, 1.0)
    var sun_pitch: float = -90.0 + (sun_progress * 360.0)
    _sun.rotation_degrees = Vector3(sun_pitch, sun_yaw_degrees, 0.0)

    if _sky_anchor == null or not _sky_anchor.is_inside_tree():
        return

    var anchor_position: Vector3 = _sky_anchor.global_position
    var sun_direction: Vector3 = _sun.global_basis.z.normalized()
    if _sky_dome != null and _sky_dome.is_inside_tree():
        _sky_dome.global_position = Vector3(anchor_position.x, 0.0, anchor_position.z)
        _sky_dome.set_sky_values(daylight, 0.0, sun_direction, current_hour, clampf(brightness_scale * 0.78, 0.55, 1.0))

func _get_daylight_factor(hour: float) -> float:
    if hour < sunrise_start_hour:
        return 0.0
    if hour < sunrise_end_hour:
        return _smooth01((hour - sunrise_start_hour) / maxf(0.001, sunrise_end_hour - sunrise_start_hour))
    if hour < sunset_start_hour:
        return 1.0
    if hour < sunset_end_hour:
        return 1.0 - _smooth01((hour - sunset_start_hour) / maxf(0.001, sunset_end_hour - sunset_start_hour))
    return 0.0

func _get_horizon_tint_factor(hour: float) -> float:
    var sunrise_mid: float = (sunrise_start_hour + sunrise_end_hour) * 0.5
    var sunset_mid: float = (sunset_start_hour + sunset_end_hour) * 0.5
    var sunrise_factor: float = clampf(1.0 - absf(hour - sunrise_mid) / maxf(0.001, sunrise_end_hour - sunrise_start_hour), 0.0, 1.0)
    var sunset_factor: float = clampf(1.0 - absf(hour - sunset_mid) / maxf(0.001, sunset_end_hour - sunset_start_hour), 0.0, 1.0)
    return maxf(sunrise_factor, sunset_factor)

func _smooth01(value: float) -> float:
    var clamped: float = clampf(value, 0.0, 1.0)
    return clamped * clamped * (3.0 - (2.0 * clamped))
