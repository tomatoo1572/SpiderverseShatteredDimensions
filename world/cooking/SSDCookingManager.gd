extends Node
class_name SSDCookingManager

const SSD_COOKING_STATE_SCRIPT = preload("res://shared/gameplay/SSDCookingState.gd")

var _states: Dictionary = {}
var _appliance_visual_root: Node3D
var _stove_visuals: Dictionary = {}
var _oven_visuals: Dictionary = {}
var _world: SSDWorld
var _anim_time: float = 0.0

func _ready() -> void:
	set_process(true)
	_appliance_visual_root = Node3D.new()
	_appliance_visual_root.name = "ApplianceVisualRoot"
	add_child(_appliance_visual_root)

func set_world(world_ref: SSDWorld) -> void:
	_world = world_ref


func set_block_facing(block_pos: Vector3i, station_type: String, facing_deg: float) -> void:
	var state: SSDCookingState = get_state(block_pos, station_type)
	if state == null:
		return
	state.facing_degrees = facing_deg
	if station_type == SSDCooking.STATION_STOVE:
		_update_stove_visual(block_pos, state)
	elif station_type == SSDCooking.STATION_OVEN:
		_update_oven_visual(block_pos, state)

func _process(delta: float) -> void:
	_anim_time += delta
	var active_stove_keys: Dictionary = {}
	var active_oven_keys: Dictionary = {}
	for key: String in _states.keys():
		var state: SSDCookingState = _states[key] as SSDCookingState
		if state == null:
			continue
		state.tick(delta)
		if state.station_type == SSDCooking.STATION_STOVE:
			active_stove_keys[key] = true
			_update_stove_visual(_key_to_pos(key), state)
		elif state.station_type == SSDCooking.STATION_OVEN:
			active_oven_keys[key] = true
			_update_oven_visual(_key_to_pos(key), state)
	_cleanup_stove_visuals(active_stove_keys)
	_cleanup_oven_visuals(active_oven_keys)
	_animate_appliance_visuals()

func get_state(block_pos: Vector3i, station_type: String) -> SSDCookingState:
	var key: String = _key_for(block_pos)
	if not _states.has(key):
		var state: SSDCookingState = SSD_COOKING_STATE_SCRIPT.new() as SSDCookingState
		state.configure(station_type)
		_states[key] = state
	var existing: SSDCookingState = _states[key] as SSDCookingState
	if existing != null and existing.station_type != station_type:
		existing.configure(station_type)
	return existing

func remove_state(block_pos: Vector3i) -> void:
	var key: String = _key_for(block_pos)
	_states.erase(key)
	if _stove_visuals.has(key):
		var stove_node: Node = _stove_visuals[key] as Node
		if stove_node != null:
			stove_node.queue_free()
		_stove_visuals.erase(key)
	if _oven_visuals.has(key):
		var oven_node: Node = _oven_visuals[key] as Node
		if oven_node != null:
			oven_node.queue_free()
		_oven_visuals.erase(key)

func _key_for(block_pos: Vector3i) -> String:
	return "%d,%d,%d" % [block_pos.x, block_pos.y, block_pos.z]

func _key_to_pos(key: String) -> Vector3i:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 3:
		return Vector3i.ZERO
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))

func _cleanup_stove_visuals(active_keys: Dictionary) -> void:
	for key: String in _stove_visuals.keys().duplicate():
		var should_keep: bool = active_keys.has(key)
		if should_keep and _world != null:
			var pos: Vector3i = _key_to_pos(key)
			should_keep = _world.get_block_global(pos.x, pos.y, pos.z) == SSDVoxelDefs.BlockId.STOVE
		if should_keep:
			continue
		var node: Node = _stove_visuals[key] as Node
		if node != null:
			node.queue_free()
		_stove_visuals.erase(key)


func _cleanup_oven_visuals(active_keys: Dictionary) -> void:
	for key: String in _oven_visuals.keys().duplicate():
		var should_keep: bool = active_keys.has(key)
		if should_keep and _world != null:
			var pos: Vector3i = _key_to_pos(key)
			should_keep = _world.get_block_global(pos.x, pos.y, pos.z) == SSDVoxelDefs.BlockId.OVEN
		if should_keep:
			continue
		var node: Node = _oven_visuals[key] as Node
		if node != null:
			node.queue_free()
		_oven_visuals.erase(key)

func _animate_appliance_visuals() -> void:
	for visual_dict: Dictionary in [_stove_visuals, _oven_visuals]:
		for key: String in visual_dict.keys():
			var root: Node3D = visual_dict[key] as Node3D
			if root == null:
				continue
			for child: Node in root.get_children():
				if child is Node3D and bool(child.get_meta("is_flame", false)):
					var flame_node: Node3D = child as Node3D
					var base_y: float = float(flame_node.get_meta("base_y", flame_node.position.y))
					var phase: float = float(flame_node.get_meta("phase", 0.0))
					var amp: float = float(flame_node.get_meta("amp", 0.018))
					var speed: float = float(flame_node.get_meta("speed", 14.0))
					var wobble: float = sin((_anim_time * speed) + phase) * amp
					wobble += sin((_anim_time * (speed * 1.73)) + (phase * 0.91)) * (amp * 0.65)
					wobble += sin((_anim_time * (speed * 2.41)) + (phase * 1.63)) * (amp * 0.28)
					flame_node.position.y = base_y + wobble
					var intensity: float = clampf(1.0 + (wobble / maxf(amp, 0.001)) * 0.8, 0.72, 1.65)
					var width_jitter: float = clampf(1.0 + sin((_anim_time * (speed * 0.85)) + (phase * 1.11)) * 0.08, 0.88, 1.12)
					flame_node.scale = Vector3(width_jitter, intensity, width_jitter)

func _update_stove_visual(block_pos: Vector3i, state: SSDCookingState) -> void:
	if _world != null and _world.get_block_global(block_pos.x, block_pos.y, block_pos.z) != SSDVoxelDefs.BlockId.STOVE:
		remove_state(block_pos)
		return
	var key: String = _key_for(block_pos)
	var root: Node3D = _stove_visuals.get(key) as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "StoveVisual_%s" % key.replace(",", "_")
		_appliance_visual_root.add_child(root)
		_stove_visuals[key] = root
	root.position = Vector3(block_pos.x + 0.5, block_pos.y + 1.01, block_pos.z + 0.5)
	root.rotation_degrees = Vector3(0.0, state.facing_degrees, 0.0)

	var cookware_id: int = state.get_cookware_item_id()
	var display_item_id: int = state.output_item_id if state.output_count > 0 else state.input_item_id
	var heat_ratio: float = state.heat_ratio
	var burner_on: bool = state.appliance_on
	var signature: String = "%d|%d|%d|%s|%0.2f|%d|%d|%d" % [cookware_id, display_item_id, state.input_secondary_item_id, str(burner_on), heat_ratio, state.input_count, state.input_secondary_count, state.output_count]
	if str(root.get_meta("signature", "")) == signature:
		return
	root.set_meta("signature", signature)
	for child: Node in root.get_children():
		child.queue_free()

	_build_stove_controls(root, heat_ratio, burner_on)

	if cookware_id == SSDItemDefs.ITEM_AIR:
		return

	if cookware_id == SSDItemDefs.ITEM_PAN:
		_build_pan_visual(root, display_item_id, heat_ratio, burner_on)
	elif cookware_id == SSDItemDefs.ITEM_POT:
		_build_pot_visual(root, display_item_id, heat_ratio, burner_on)
	if state.input_secondary_item_id != SSDItemDefs.ITEM_AIR and state.output_count <= 0:
		_build_food_visual(root, state.input_secondary_item_id, Vector3(0.11, 0.11, 0.0), Vector3(-PI * 0.5, 0.0, 0.0), 0.09)


func _update_oven_visual(block_pos: Vector3i, state: SSDCookingState) -> void:
	if _world != null and _world.get_block_global(block_pos.x, block_pos.y, block_pos.z) != SSDVoxelDefs.BlockId.OVEN:
		remove_state(block_pos)
		return
	var key: String = _key_for(block_pos)
	var root: Node3D = _oven_visuals.get(key) as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "OvenVisual_%s" % key.replace(",", "_")
		_appliance_visual_root.add_child(root)
		_oven_visuals[key] = root
	root.position = Vector3(block_pos.x + 0.5, block_pos.y + 0.5, block_pos.z + 0.5)
	root.rotation_degrees = Vector3(0.0, state.facing_degrees, 0.0)

	var heat_ratio: float = state.heat_ratio
	var signature: String = "%d|%d|%0.2f|%d|%d|%d|%s" % [state.input_item_id, state.output_item_id, heat_ratio, state.input_count, state.output_count, state.fuel_count, str(state.appliance_on)]
	if str(root.get_meta("signature", "")) == signature:
		return
	root.set_meta("signature", signature)
	for child: Node in root.get_children():
		child.queue_free()

	_build_oven_visual(root, state)

func _build_oven_visual(root: Node3D, state: SSDCookingState) -> void:
	var door_open: bool = state.appliance_on
	var door_y: float = 0.0 if not door_open else -0.22
	var door_z: float = 0.47 if not door_open else 0.31
	var door_pitch: float = 0.0 if not door_open else -82.0

	var door_frame: MeshInstance3D = MeshInstance3D.new()
	var frame_mesh: BoxMesh = BoxMesh.new()
	frame_mesh.size = Vector3(0.66, 0.5, 0.08)
	door_frame.mesh = frame_mesh
	door_frame.material_override = _make_colored_material(Color(0.15, 0.15, 0.16), 0.7, 0.1)
	door_frame.position = Vector3(0.0, door_y, door_z)
	door_frame.rotation_degrees = Vector3(door_pitch, 0.0, 0.0)
	root.add_child(door_frame)

	var window: MeshInstance3D = MeshInstance3D.new()
	var window_mesh: BoxMesh = BoxMesh.new()
	window_mesh.size = Vector3(0.42, 0.22, 0.02)
	window.mesh = window_mesh
	var glass_mat: StandardMaterial3D = _make_colored_material(Color(0.1, 0.12, 0.14, 0.65), 0.15, 0.0)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	window.material_override = glass_mat
	window.position = Vector3(0.0, door_y + 0.02, door_z + 0.045)
	window.rotation_degrees = Vector3(door_pitch, 0.0, 0.0)
	root.add_child(window)

	var handle: MeshInstance3D = MeshInstance3D.new()
	var handle_mesh: BoxMesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.22, 0.028, 0.028)
	handle.mesh = handle_mesh
	handle.material_override = _make_colored_material(Color(0.78, 0.78, 0.8), 0.22, 0.15)
	handle.position = Vector3(0.0, door_y - 0.18, door_z + 0.065)
	handle.rotation_degrees = Vector3(door_pitch, 0.0, 0.0)
	root.add_child(handle)

	var cavity: MeshInstance3D = MeshInstance3D.new()
	var cavity_mesh: BoxMesh = BoxMesh.new()
	cavity_mesh.size = Vector3(0.5, 0.28, 0.42)
	cavity.mesh = cavity_mesh
	var cavity_color: Color = Color(0.06, 0.05, 0.05)
	if state.burn_time > 0.0:
		cavity_color = cavity_color.lerp(Color(0.45, 0.18, 0.07), clampf(state.heat_ratio, 0.0, 1.0) * 0.7)
	var cavity_mat: StandardMaterial3D = _make_colored_material(cavity_color, 0.9, 0.0)
	if state.burn_time > 0.0:
		cavity_mat.emission_enabled = true
		cavity_mat.emission = Color(1.0, 0.45, 0.1) * (0.5 + state.heat_ratio)
	cavity.material_override = cavity_mat
	cavity.position = Vector3(0.0, -0.02, 0.26)
	root.add_child(cavity)

	var rack: MeshInstance3D = MeshInstance3D.new()
	var rack_mesh: BoxMesh = BoxMesh.new()
	rack_mesh.size = Vector3(0.44, 0.01, 0.28)
	rack.mesh = rack_mesh
	rack.material_override = _make_colored_material(Color(0.35, 0.35, 0.36), 0.4, 0.12)
	rack.position = Vector3(0.0, -0.02, 0.26)
	root.add_child(rack)

	if state.fuel_count > 0 and state.fuel_item_id != SSDItemDefs.ITEM_AIR:
		_build_food_visual(root, state.fuel_item_id, Vector3(-0.13, -0.14, 0.24), Vector3(-PI * 0.5, 0.0, 0.0), 0.12)

	var visible_food_id: int = state.output_item_id if state.output_count > 0 else state.input_item_id
	if visible_food_id != SSDItemDefs.ITEM_AIR:
		_build_food_visual(root, visible_food_id, Vector3(0.0, -0.01, 0.24), Vector3(-PI * 0.5, 0.0, 0.0), 0.2)

	if state.burn_time > 0.0:
		_add_appliance_light(root, Vector3(0.0, 0.02, 0.24), Color(1.0, 0.48, 0.12), 0.9 + (state.heat_ratio * 0.7), 2.2)
		for i: int in range(3):
			var flame: MeshInstance3D = MeshInstance3D.new()
			var flame_mesh: CylinderMesh = CylinderMesh.new()
			flame_mesh.top_radius = 0.012
			flame_mesh.bottom_radius = 0.028
			flame_mesh.height = 0.08
			flame_mesh.radial_segments = 8
			flame.mesh = flame_mesh
			var flame_material: StandardMaterial3D = _make_colored_material(Color(1.0, 0.55, 0.12), 0.1, 0.0)
			flame_material.emission_enabled = true
			flame_material.emission = Color(1.0, 0.45, 0.1) * (0.9 + state.heat_ratio)
			flame.material_override = flame_material
			flame.position = Vector3((float(i) - 1.0) * 0.08, -0.12, 0.26)
			flame.set_meta("is_flame", true)
			flame.set_meta("base_y", -0.12)
			flame.set_meta("phase", float(i) * 0.91)
			flame.set_meta("amp", 0.01 + (float(i) * 0.002))
			flame.set_meta("speed", 6.5 + float(i))
			root.add_child(flame)


func _add_appliance_light(root: Node3D, local_position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.position = local_position
	light.shadow_enabled = false
	root.add_child(light)

func _build_vapor_plume(root: Node3D, origin: Vector3, height_scale: float) -> void:
	for vapor_index: int in range(4):
		var puff: MeshInstance3D = MeshInstance3D.new()
		var puff_mesh: SphereMesh = SphereMesh.new()
		puff_mesh.radius = 0.018 + (float(vapor_index) * 0.005)
		puff_mesh.height = puff_mesh.radius * 2.0
		puff.mesh = puff_mesh
		var puff_material: StandardMaterial3D = _make_colored_material(Color(0.88, 0.90, 0.94, 0.18), 1.0, 0.0)
		puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		puff.material_override = puff_material
		var y_offset: float = float(vapor_index) * 0.045
		puff.position = origin + Vector3(randf_range(-0.025, 0.025), y_offset, randf_range(-0.025, 0.025))
		puff.scale = Vector3.ONE * (1.0 + float(vapor_index) * 0.15) * height_scale
		root.add_child(puff)

func _build_stove_controls(root: Node3D, heat_ratio: float, burner_on: bool) -> void:
	var top_panel: MeshInstance3D = MeshInstance3D.new()
	var top_panel_mesh: BoxMesh = BoxMesh.new()
	top_panel_mesh.size = Vector3(0.92, 0.03, 0.92)
	top_panel.mesh = top_panel_mesh
	top_panel.material_override = _make_colored_material(Color(0.16, 0.16, 0.17), 0.72, 0.08)
	top_panel.position = Vector3(0.0, -0.035, 0.0)
	root.add_child(top_panel)

	var burner_bed: MeshInstance3D = MeshInstance3D.new()
	var burner_bed_mesh: CylinderMesh = CylinderMesh.new()
	burner_bed_mesh.top_radius = 0.17
	burner_bed_mesh.bottom_radius = 0.17
	burner_bed_mesh.height = 0.014
	burner_bed_mesh.radial_segments = 24
	burner_bed.mesh = burner_bed_mesh
	burner_bed.material_override = _make_colored_material(Color(0.05, 0.05, 0.055), 0.95, 0.0)
	burner_bed.position = Vector3(0.0, -0.023, 0.0)
	root.add_child(burner_bed)

	var burner_cap: MeshInstance3D = MeshInstance3D.new()
	var burner_cap_mesh: CylinderMesh = CylinderMesh.new()
	burner_cap_mesh.top_radius = 0.065
	burner_cap_mesh.bottom_radius = 0.075
	burner_cap_mesh.height = 0.018
	burner_cap_mesh.radial_segments = 24
	burner_cap.mesh = burner_cap_mesh
	burner_cap.material_override = _make_colored_material(Color(0.12, 0.12, 0.125), 0.82, 0.02)
	burner_cap.position = Vector3(0.0, -0.005, 0.0)
	root.add_child(burner_cap)

	var grate_material: StandardMaterial3D = _make_colored_material(Color(0.07, 0.07, 0.075), 0.88, 0.02)
	for offset: float in [-0.13, 0.13]:
		var bar_x: MeshInstance3D = MeshInstance3D.new()
		var bar_x_mesh: BoxMesh = BoxMesh.new()
		bar_x_mesh.size = Vector3(0.04, 0.028, 0.56)
		bar_x.mesh = bar_x_mesh
		bar_x.material_override = grate_material
		bar_x.position = Vector3(offset, 0.006, 0.0)
		root.add_child(bar_x)

		var bar_z: MeshInstance3D = MeshInstance3D.new()
		var bar_z_mesh: BoxMesh = BoxMesh.new()
		bar_z_mesh.size = Vector3(0.56, 0.028, 0.04)
		bar_z.mesh = bar_z_mesh
		bar_z.material_override = grate_material
		bar_z.position = Vector3(0.0, 0.006, offset)
		root.add_child(bar_z)

	for spoke_index: int in range(4):
		var spoke: MeshInstance3D = MeshInstance3D.new()
		var spoke_mesh: BoxMesh = BoxMesh.new()
		spoke_mesh.size = Vector3(0.03, 0.02, 0.20)
		spoke.mesh = spoke_mesh
		spoke.material_override = grate_material
		spoke.position = Vector3(0.0, 0.004, 0.0)
		spoke.rotation_degrees = Vector3(0.0, spoke_index * 45.0, 0.0)
		root.add_child(spoke)

	var ring_material: StandardMaterial3D = _make_colored_material(Color(0.08, 0.08, 0.09), 0.8, 0.0)
	for i: int in range(8):
		var head: MeshInstance3D = MeshInstance3D.new()
		var head_mesh: BoxMesh = BoxMesh.new()
		head_mesh.size = Vector3(0.018, 0.008, 0.035)
		head.mesh = head_mesh
		head.material_override = ring_material
		var a: float = TAU * float(i) / 12.0
		head.position = Vector3(cos(a) * 0.105, -0.006, sin(a) * 0.105)
		head.rotation_degrees = Vector3(0.0, -rad_to_deg(a), 0.0)
		root.add_child(head)

	if burner_on:
		for i: int in range(12):
			var flame: MeshInstance3D = MeshInstance3D.new()
			var flame_mesh: CylinderMesh = CylinderMesh.new()
			flame_mesh.top_radius = 0.008
			flame_mesh.bottom_radius = 0.018
			flame_mesh.height = 0.055 + (heat_ratio * 0.025)
			flame_mesh.radial_segments = 8
			flame.mesh = flame_mesh
			var flame_material: StandardMaterial3D = _make_colored_material(Color(0.35, 0.7, 1.0).lerp(Color(0.7, 0.88, 1.0), heat_ratio), 0.15, 0.0)
			flame_material.emission_enabled = true
			flame_material.emission = Color(0.25, 0.55, 1.0) * (1.4 + heat_ratio)
			flame.material_override = flame_material
			var a: float = TAU * float(i) / 12.0
			flame.position = Vector3(cos(a) * 0.105, 0.018, sin(a) * 0.105)
			flame.set_meta("is_flame", true)
			flame.set_meta("base_y", 0.018)
			flame.set_meta("phase", (float(i) * 0.81) + randf_range(0.0, 0.6))
			flame.set_meta("amp", 0.016 + randf_range(0.0, 0.014))
			flame.set_meta("speed", 13.0 + randf_range(0.0, 7.0))
			root.add_child(flame)

	var front_panel: MeshInstance3D = MeshInstance3D.new()
	var front_panel_mesh: BoxMesh = BoxMesh.new()
	front_panel_mesh.size = Vector3(0.34, 0.05, 0.12)
	front_panel.mesh = front_panel_mesh
	front_panel.material_override = _make_colored_material(Color(0.14, 0.14, 0.145), 0.78, 0.06)
	front_panel.position = Vector3(0.0, -0.005, 0.32)
	root.add_child(front_panel)

	var knob: MeshInstance3D = MeshInstance3D.new()
	var knob_mesh: CylinderMesh = CylinderMesh.new()
	knob_mesh.top_radius = 0.042
	knob_mesh.bottom_radius = 0.044
	knob_mesh.height = 0.045
	knob_mesh.radial_segments = 20
	knob.mesh = knob_mesh
	knob.material_override = _make_colored_material(Color(0.18, 0.18, 0.19), 0.52, 0.1)
	knob.position = Vector3(-0.03, 0.004, 0.33)
	knob.rotation_degrees = Vector3(90.0, 0.0, -45.0 if burner_on else 35.0)
	root.add_child(knob)

	var knob_pointer: MeshInstance3D = MeshInstance3D.new()
	var knob_pointer_mesh: BoxMesh = BoxMesh.new()
	knob_pointer_mesh.size = Vector3(0.008, 0.02, 0.032)
	knob_pointer.mesh = knob_pointer_mesh
	knob_pointer.material_override = _make_colored_material(Color(0.85, 0.85, 0.88), 0.35, 0.0)
	knob_pointer.position = Vector3(-0.03, 0.028, 0.344)
	knob_pointer.rotation_degrees = Vector3(0.0, 0.0, -45.0 if burner_on else 35.0)
	root.add_child(knob_pointer)

	var pilot_housing: MeshInstance3D = MeshInstance3D.new()
	var pilot_housing_mesh: BoxMesh = BoxMesh.new()
	pilot_housing_mesh.size = Vector3(0.1, 0.028, 0.06)
	pilot_housing.mesh = pilot_housing_mesh
	pilot_housing.material_override = _make_colored_material(Color(0.12, 0.12, 0.125), 0.8, 0.04)
	pilot_housing.position = Vector3(0.11, 0.0, 0.32)
	root.add_child(pilot_housing)

	var pilot_light: MeshInstance3D = MeshInstance3D.new()
	var pilot_light_mesh: SphereMesh = SphereMesh.new()
	pilot_light_mesh.radius = 0.018
	pilot_light_mesh.height = 0.036
	pilot_light.mesh = pilot_light_mesh
	var pilot_color: Color = Color(0.35, 0.05, 0.05)
	var pilot_emission: float = 0.04
	if burner_on:
		pilot_color = Color(0.2, 0.55, 1.0)
		pilot_emission = 1.2 + heat_ratio
	var pilot_material: StandardMaterial3D = _make_colored_material(pilot_color, 0.18, 0.0)
	pilot_material.emission_enabled = true
	pilot_material.emission = pilot_color * pilot_emission
	pilot_light.material_override = pilot_material
	pilot_light.position = Vector3(0.11, 0.01, 0.335)
	root.add_child(pilot_light)

	if burner_on:
		_add_appliance_light(root, Vector3(0.0, 0.18, 0.0), Color(0.30, 0.55, 1.0), 0.55 + (heat_ratio * 0.35), 1.9)

func _build_pan_visual(root: Node3D, display_item_id: int, heat_ratio: float, burner_on: bool) -> void:
	var pan_base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 0.215
	base_mesh.bottom_radius = 0.22
	base_mesh.height = 0.022
	base_mesh.radial_segments = 24
	pan_base.mesh = base_mesh
	pan_base.material_override = _make_colored_material(Color(0.14, 0.14, 0.16), 0.46, 0.16)
	pan_base.position = Vector3(0.0, 0.018, 0.0)
	root.add_child(pan_base)

	var pan_wall: MeshInstance3D = MeshInstance3D.new()
	var wall_mesh: CylinderMesh = CylinderMesh.new()
	wall_mesh.top_radius = 0.24
	wall_mesh.bottom_radius = 0.225
	wall_mesh.height = 0.09
	wall_mesh.radial_segments = 24
	wall_mesh.cap_top = false
	wall_mesh.cap_bottom = false
	pan_wall.mesh = wall_mesh
	pan_wall.material_override = _make_colored_material(Color(0.17, 0.17, 0.19), 0.38, 0.22)
	pan_wall.position = Vector3(0.0, 0.062, 0.0)
	root.add_child(pan_wall)

	var pan_inner_floor: MeshInstance3D = MeshInstance3D.new()
	var floor_mesh: CylinderMesh = CylinderMesh.new()
	floor_mesh.top_radius = 0.19
	floor_mesh.bottom_radius = 0.19
	floor_mesh.height = 0.012
	floor_mesh.radial_segments = 24
	pan_inner_floor.mesh = floor_mesh
	pan_inner_floor.material_override = _make_colored_material(Color(0.045, 0.045, 0.05), 0.18, 0.02)
	pan_inner_floor.position = Vector3(0.0, 0.022, 0.0)
	root.add_child(pan_inner_floor)

	var pan_inner_wall: MeshInstance3D = MeshInstance3D.new()
	var inner_wall_mesh: CylinderMesh = CylinderMesh.new()
	inner_wall_mesh.top_radius = 0.2
	inner_wall_mesh.bottom_radius = 0.195
	inner_wall_mesh.height = 0.055
	inner_wall_mesh.radial_segments = 24
	inner_wall_mesh.cap_top = false
	inner_wall_mesh.cap_bottom = false
	pan_inner_wall.mesh = inner_wall_mesh
	pan_inner_wall.material_override = _make_colored_material(Color(0.06, 0.06, 0.07), 0.18, 0.02)
	pan_inner_wall.position = Vector3(0.0, 0.06, 0.0)
	root.add_child(pan_inner_wall)

	var pan_rim_material: StandardMaterial3D = _make_colored_material(Color(0.25, 0.25, 0.27), 0.3, 0.22)
	for rim_part: Array in [
		[Vector3(0.0, 0.105, 0.205), Vector3(0.38, 0.012, 0.02)],
		[Vector3(0.0, 0.105, -0.205), Vector3(0.38, 0.012, 0.02)],
		[Vector3(0.205, 0.105, 0.0), Vector3(0.02, 0.012, 0.38)],
		[Vector3(-0.205, 0.105, 0.0), Vector3(0.02, 0.012, 0.38)],
	]:
		var pan_rim: MeshInstance3D = MeshInstance3D.new()
		var rim_mesh: BoxMesh = BoxMesh.new()
		rim_mesh.size = rim_part[1]
		pan_rim.mesh = rim_mesh
		pan_rim.material_override = pan_rim_material
		pan_rim.position = rim_part[0]
		root.add_child(pan_rim)

	var pan_handle: MeshInstance3D = MeshInstance3D.new()
	var handle_mesh: BoxMesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.06, 0.028, 0.24)
	pan_handle.mesh = handle_mesh
	pan_handle.material_override = _make_colored_material(Color(0.12, 0.12, 0.13), 0.35, 0.08)
	pan_handle.position = Vector3(0.0, 0.055, 0.295)
	root.add_child(pan_handle)

	var handle_grip: MeshInstance3D = MeshInstance3D.new()
	var grip_mesh: BoxMesh = BoxMesh.new()
	grip_mesh.size = Vector3(0.075, 0.032, 0.13)
	handle_grip.mesh = grip_mesh
	handle_grip.material_override = _make_colored_material(Color(0.08, 0.08, 0.09), 0.85, 0.0)
	handle_grip.position = Vector3(0.0, 0.055, 0.385)
	root.add_child(handle_grip)

	if display_item_id != SSDItemDefs.ITEM_AIR:
		_build_food_visual(root, display_item_id, Vector3(0.0, 0.055, -0.005), Vector3(-PI * 0.5, 0.0, 0.0), 0.21)
	if burner_on and heat_ratio > 0.2 and display_item_id != SSDItemDefs.ITEM_AIR:
		_build_vapor_plume(root, Vector3(0.0, 0.11, -0.005), 0.8 + (heat_ratio * 0.2))

func _build_pot_visual(root: Node3D, display_item_id: int, heat_ratio: float, burner_on: bool) -> void:
	var pot_base: MeshInstance3D = MeshInstance3D.new()
	var base_mesh: CylinderMesh = CylinderMesh.new()
	base_mesh.top_radius = 0.185
	base_mesh.bottom_radius = 0.195
	base_mesh.height = 0.03
	base_mesh.radial_segments = 24
	pot_base.mesh = base_mesh
	pot_base.material_override = _make_colored_material(Color(0.16, 0.16, 0.18), 0.44, 0.14)
	pot_base.position = Vector3(0.0, 0.03, 0.0)
	root.add_child(pot_base)

	var pot_outer: MeshInstance3D = MeshInstance3D.new()
	var outer_mesh: CylinderMesh = CylinderMesh.new()
	outer_mesh.top_radius = 0.205
	outer_mesh.bottom_radius = 0.195
	outer_mesh.height = 0.24
	outer_mesh.radial_segments = 24
	outer_mesh.cap_top = false
	outer_mesh.cap_bottom = false
	pot_outer.mesh = outer_mesh
	pot_outer.material_override = _make_colored_material(Color(0.19, 0.19, 0.21), 0.46, 0.18)
	pot_outer.position = Vector3(0.0, 0.145, 0.0)
	root.add_child(pot_outer)

	var pot_inner_floor: MeshInstance3D = MeshInstance3D.new()
	var inner_floor_mesh: CylinderMesh = CylinderMesh.new()
	inner_floor_mesh.top_radius = 0.155
	inner_floor_mesh.bottom_radius = 0.155
	inner_floor_mesh.height = 0.016
	inner_floor_mesh.radial_segments = 24
	pot_inner_floor.mesh = inner_floor_mesh
	pot_inner_floor.material_override = _make_colored_material(Color(0.05, 0.05, 0.055), 0.18, 0.02)
	pot_inner_floor.position = Vector3(0.0, 0.03, 0.0)
	root.add_child(pot_inner_floor)

	var pot_inner_wall: MeshInstance3D = MeshInstance3D.new()
	var inner_wall_mesh: CylinderMesh = CylinderMesh.new()
	inner_wall_mesh.top_radius = 0.168
	inner_wall_mesh.bottom_radius = 0.16
	inner_wall_mesh.height = 0.18
	inner_wall_mesh.radial_segments = 24
	inner_wall_mesh.cap_top = false
	inner_wall_mesh.cap_bottom = false
	pot_inner_wall.mesh = inner_wall_mesh
	pot_inner_wall.material_override = _make_colored_material(Color(0.065, 0.065, 0.075), 0.18, 0.02)
	pot_inner_wall.position = Vector3(0.0, 0.135, 0.0)
	root.add_child(pot_inner_wall)

	var pot_rim_material: StandardMaterial3D = _make_colored_material(Color(0.25, 0.25, 0.27), 0.3, 0.22)
	for rim_part: Array in [
		[Vector3(0.0, 0.265, 0.17), Vector3(0.30, 0.014, 0.02)],
		[Vector3(0.0, 0.265, -0.17), Vector3(0.30, 0.014, 0.02)],
		[Vector3(0.17, 0.265, 0.0), Vector3(0.02, 0.014, 0.30)],
		[Vector3(-0.17, 0.265, 0.0), Vector3(0.02, 0.014, 0.30)],
	]:
		var pot_rim: MeshInstance3D = MeshInstance3D.new()
		var rim_mesh: BoxMesh = BoxMesh.new()
		rim_mesh.size = rim_part[1]
		pot_rim.mesh = rim_mesh
		pot_rim.material_override = pot_rim_material
		pot_rim.position = rim_part[0]
		root.add_child(pot_rim)

	var handle_mesh: BoxMesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.07, 0.03, 0.12)
	var handle_material: StandardMaterial3D = _make_colored_material(Color(0.14, 0.14, 0.15), 0.38, 0.08)
	for x: float in [-0.22, 0.22]:
		var handle: MeshInstance3D = MeshInstance3D.new()
		handle.mesh = handle_mesh
		handle.material_override = handle_material
		handle.position = Vector3(x, 0.15, 0.0)
		root.add_child(handle)

	if display_item_id != SSDItemDefs.ITEM_AIR:
		_build_food_visual(root, display_item_id, Vector3(0.0, 0.12, 0.0), Vector3(-PI * 0.5, 0.0, 0.0), 0.16)
	if burner_on and heat_ratio > 0.2 and display_item_id != SSDItemDefs.ITEM_AIR:
		_build_vapor_plume(root, Vector3(0.0, 0.22, 0.0), 1.0 + (heat_ratio * 0.25))

func _build_food_visual(root: Node3D, item_id: int, local_position: Vector3, local_rotation: Vector3, size: float) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	mesh_instance.mesh = quad
	mesh_instance.position = local_position
	mesh_instance.rotation = local_rotation
	mesh_instance.material_override = _make_item_material(item_id)
	root.add_child(mesh_instance)

func _make_item_material(item_id: int) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = SSDItemDefs.get_inventory_icon_texture(item_id)
	return material

func _make_colored_material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material
