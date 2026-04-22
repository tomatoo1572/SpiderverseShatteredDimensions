extends Node
class_name SSDDisplayCaseManager

const DISPLAY_CASE_SCENE: PackedScene = preload("res://assets/models/display_case/display_case.glb")
const PLAYER_MODEL_SCRIPT = preload("res://client/player/SSDPlayerModel.gd")
const DISPLAY_CASE_TEXTURE: Texture2D = preload("res://assets/textures/display/display_case_texture.png")

var _states: Dictionary = {}
var _visual_root: Node3D
var _visuals: Dictionary = {}
var _world: SSDWorld

func _ready() -> void:
	set_process(true)
	_visual_root = Node3D.new()
	_visual_root.name = "DisplayCaseVisualRoot"
	add_child(_visual_root)

func set_world(world_ref: SSDWorld) -> void:
	_world = world_ref

func _process(_delta: float) -> void:
	var active_keys: Dictionary = {}
	for key: String in _states.keys():
		var pos: Vector3i = _key_to_pos(key)
		if _world != null and _world.get_block_global(pos.x, pos.y, pos.z) == SSDVoxelDefs.BlockId.DISPLAY_CASE:
			active_keys[key] = true
			_update_visual(pos, _states[key])
	for key: String in _visuals.keys().duplicate():
		if active_keys.has(key):
			continue
		var node: Node = _visuals[key] as Node
		if node != null:
			node.queue_free()
		_visuals.erase(key)

func ensure_visual(block_pos: Vector3i) -> void:
	ensure_state(block_pos)
	_update_visual(block_pos, _states.get(_key_for(block_pos), {}))

func ensure_state(block_pos: Vector3i) -> Dictionary:
	var key: String = _key_for(block_pos)
	if not _states.has(key):
		_states[key] = {
			"open": false,
			"shirt_item_id": SSDItemDefs.ITEM_AIR,
			"jacket_item_id": SSDItemDefs.ITEM_AIR,
			"facing_degrees": 0.0,
		}
	return _states[key]


func set_block_facing(block_pos: Vector3i, facing_deg: float) -> void:
	var state: Dictionary = ensure_state(block_pos)
	state["facing_degrees"] = facing_deg
	_update_visual(block_pos, state)

func remove_state(block_pos: Vector3i) -> void:
	var key: String = _key_for(block_pos)
	_states.erase(key)
	if _visuals.has(key):
		var node: Node = _visuals[key] as Node
		if node != null:
			node.queue_free()
		_visuals.erase(key)

func toggle_open(block_pos: Vector3i) -> bool:
	var state: Dictionary = ensure_state(block_pos)
	state["open"] = not bool(state.get("open", false))
	_update_visual(block_pos, state)
	return true

func try_insert_clothing(block_pos: Vector3i, item_id: int) -> bool:
	var slot_name: String = SSDItemDefs.get_equipment_slot_name(item_id)
	if slot_name.is_empty():
		return false
	var state: Dictionary = ensure_state(block_pos)
	if not bool(state.get("open", false)):
		return false
	if slot_name == "Shirt":
		state["shirt_item_id"] = item_id
	elif slot_name == "Jacket":
		state["jacket_item_id"] = item_id
	else:
		return false
	_update_visual(block_pos, state)
	return true

func take_last_clothing(block_pos: Vector3i) -> Dictionary:
	var state: Dictionary = ensure_state(block_pos)
	var item_id: int = int(state.get("jacket_item_id", SSDItemDefs.ITEM_AIR))
	if item_id != SSDItemDefs.ITEM_AIR:
		state["jacket_item_id"] = SSDItemDefs.ITEM_AIR
		_update_visual(block_pos, state)
		return {"item_id": item_id, "count": 1}
	item_id = int(state.get("shirt_item_id", SSDItemDefs.ITEM_AIR))
	if item_id != SSDItemDefs.ITEM_AIR:
		state["shirt_item_id"] = SSDItemDefs.ITEM_AIR
		_update_visual(block_pos, state)
		return {"item_id": item_id, "count": 1}
	return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0}

func _update_visual(block_pos: Vector3i, state: Dictionary) -> void:
	if _world != null and _world.get_block_global(block_pos.x, block_pos.y, block_pos.z) != SSDVoxelDefs.BlockId.DISPLAY_CASE:
		remove_state(block_pos)
		return
	var key: String = _key_for(block_pos)
	var root: Node3D = _visuals.get(key) as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "DisplayCase_%s" % key.replace(",", "_")
		_visual_root.add_child(root)
		_visuals[key] = root
	root.position = Vector3(block_pos.x + 0.5, block_pos.y, block_pos.z + 0.5)
	root.rotation_degrees = Vector3(0.0, float(state.get("facing_degrees", 0.0)) + 180.0, 0.0)
	root.scale = Vector3.ONE

	var collider: StaticBody3D = root.get_node_or_null("CaseCollider") as StaticBody3D
	if collider == null:
		collider = StaticBody3D.new()
		collider.name = "CaseCollider"
		root.add_child(collider)
		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(0.92, 1.98, 0.92)
		collision_shape.shape = box
		collision_shape.position = Vector3(0.0, 0.99, 0.0)
		collider.add_child(collision_shape)

	var signature: String = "%s|%d|%d" % [str(state.get("open", false)), int(state.get("shirt_item_id", SSDItemDefs.ITEM_AIR)), int(state.get("jacket_item_id", SSDItemDefs.ITEM_AIR))]
	if str(root.get_meta("signature", "")) == signature:
		return
	root.set_meta("signature", signature)

	var case_scene_root: Node3D = root.get_node_or_null("Case") as Node3D
	if case_scene_root == null:
		case_scene_root = DISPLAY_CASE_SCENE.instantiate() as Node3D
		if case_scene_root == null:
			return
		case_scene_root.name = "Case"
		case_scene_root.position = Vector3.ZERO
		root.add_child(case_scene_root)
		_hide_imported_mannequin(case_scene_root)
		_polish_case_meshes(case_scene_root)
	var mannequin: SSDPlayerModel = root.get_node_or_null("Mannequin") as SSDPlayerModel
	if mannequin == null:
		mannequin = PLAYER_MODEL_SCRIPT.new() as SSDPlayerModel
		mannequin.name = "Mannequin"
		mannequin.render_layer_mask = 1
		mannequin.model_scale = 0.82
		root.add_child(mannequin)
		mannequin.position = Vector3(0.0, 0.02, -0.02)
		mannequin.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		var fill_light: OmniLight3D = OmniLight3D.new()
		fill_light.name = "FillLight"
		fill_light.light_color = Color(1.0, 0.97, 0.93)
		fill_light.light_energy = 4.4
		fill_light.omni_range = 4.8
		fill_light.shadow_enabled = false
		fill_light.position = Vector3(0.0, 1.30, 0.08)
		root.add_child(fill_light)
		var front_light: SpotLight3D = SpotLight3D.new()
		front_light.name = "FrontLight"
		front_light.light_color = Color(1.0, 0.96, 0.92)
		front_light.light_energy = 3.6
		front_light.spot_range = 4.6
		front_light.spot_angle = 58.0
		front_light.shadow_enabled = false
		front_light.position = Vector3(0.0, 1.55, 0.52)
		front_light.rotation_degrees = Vector3(-82.0, 180.0, 0.0)
		root.add_child(front_light)
	mannequin.set_shirt_item(int(state.get("shirt_item_id", SSDItemDefs.ITEM_AIR)))
	mannequin.set_jacket_item(int(state.get("jacket_item_id", SSDItemDefs.ITEM_AIR)))
	var animation_player: AnimationPlayer = _find_animation_player(case_scene_root)
	if animation_player != null:
		var should_open: bool = bool(state.get("open", false))
		var animation_name: StringName = &"Open" if should_open else &"Close"
		if animation_player.has_animation(animation_name):
			animation_player.play(animation_name)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null

func _key_for(block_pos: Vector3i) -> String:
	return "%d,%d,%d" % [block_pos.x, block_pos.y, block_pos.z]

func _key_to_pos(key: String) -> Vector3i:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 3:
		return Vector3i.ZERO
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))


func _hide_imported_mannequin(node: Node) -> void:
	var lowered_name: String = node.name.to_lower()
	if node is Node3D and (lowered_name.contains("head") or lowered_name.contains("body") or lowered_name.contains("arm") or lowered_name.contains("leg")):
		(node as Node3D).visible = false
	for child: Node in node.get_children():
		_hide_imported_mannequin(child)

func _polish_case_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.extra_cull_margin = 4.0
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var lowered_name: String = mesh_instance.name.to_lower()
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		material.roughness = 0.18
		material.metallic = 0.0
		material.vertex_color_use_as_albedo = false
		if lowered_name.contains("glass") or lowered_name.contains("window") or lowered_name.contains("door"):
			material.albedo_color = Color(0.90, 0.94, 0.98, 0.12)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.refraction_enabled = false
			material.emission_enabled = true
			material.emission = Color(0.34, 0.30, 0.30) * 0.32
			material.roughness = 0.05
		else:
			material.albedo_texture = DISPLAY_CASE_TEXTURE
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
			material.metallic = 0.02
			material.roughness = 0.78
			material.emission_enabled = true
			material.emission = Color(0.38, 0.34, 0.34) * 0.22
		mesh_instance.material_override = material
	for child: Node in node.get_children():
		_polish_case_meshes(child)

