extends Node
class_name SSDBlockInteractor

signal spawn_item_drop(block_id: int, count: int, world_position: Vector3, impulse: Vector3)
signal request_open_crafting_table
signal request_open_furnace(block_pos: Vector3i)
signal request_open_cooking_station(block_pos: Vector3i, station_type: String)
signal request_spawn_mob(mob_type: String, world_position: Vector3)

const PLAYER_RADIUS: float = 0.295
const PLAYER_HEIGHT: float = 1.8
const INVALID_BLOCK: Vector3i = Vector3i(2147483647, 2147483647, 2147483647)
const SETTINGS_PATH: String = "user://ssd_settings.cfg"

@export var repeat_start_delay: float = 0.18
@export var repeat_interval: float = 0.09
@export var creative_break_repeat: float = 0.08
@export var block_break_stamina_per_second: float = 1.8
@export var block_break_finish_stamina: float = 0.75
@export var punch_stamina_cost: float = 0.65
@export var survival_break_cooldown: float = 0.18

var _world: SSDWorld
var _player: CharacterBody3D
var _camera: Camera3D
var _selector: SSDBlockSelector
var _hotbar: SSDHotbar
var _inventory: SSDInventory
var _game_mode: SSDGameMode
var _furnace_manager: SSDFurnaceManager
var _cooking_manager: SSDCookingManager
var _display_case_manager: SSDDisplayCaseManager
var _network_delegate: Node
var _break_held: bool = false
var _place_held: bool = false
var _break_repeat_timer: float = 0.0
var _place_repeat_timer: float = 0.0
var _break_target: Vector3i = INVALID_BLOCK
var _break_progress: float = 0.0
var _break_elapsed: float = 0.0
var _break_stamina_accum: float = 0.0
var _break_cooldown_remaining: float = 0.0

func set_targets(world: SSDWorld, player: CharacterBody3D, camera: Camera3D, selector: SSDBlockSelector, hotbar: SSDHotbar, inventory: SSDInventory, game_mode: SSDGameMode, furnace_manager: SSDFurnaceManager, cooking_manager: SSDCookingManager, display_case_manager: SSDDisplayCaseManager) -> void:
	_world = world
	_player = player
	_camera = camera
	_selector = selector
	_hotbar = hotbar
	_inventory = inventory
	_game_mode = game_mode
	_furnace_manager = furnace_manager
	_cooking_manager = cooking_manager
	_display_case_manager = display_case_manager
	_update_break_ui(false)

func set_network_delegate(delegate: Node) -> void:
	_network_delegate = delegate

func _process(delta: float) -> void:
	if _world == null or _player == null or _selector == null or _hotbar == null or _inventory == null:
		return
	if _break_cooldown_remaining > 0.0:
		_break_cooldown_remaining = maxf(0.0, _break_cooldown_remaining - delta)
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		cancel_held_actions()
		return

	if _break_held:
		_process_breaking(delta)

	if _place_held:
		_place_repeat_timer -= delta
		if _place_repeat_timer <= 0.0:
			_request_place_action()
			_place_repeat_timer = repeat_interval

func _input(event: InputEvent) -> void:
	if _world == null or _player == null or _selector == null or _hotbar == null or _inventory == null:
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if event.is_action_pressed("hotbar_1"):
		_hotbar.select_index(0)
	elif event.is_action_pressed("hotbar_2"):
		_hotbar.select_index(1)
	elif event.is_action_pressed("hotbar_3"):
		_hotbar.select_index(2)
	elif event.is_action_pressed("hotbar_4"):
		_hotbar.select_index(3)
	elif event.is_action_pressed("hotbar_5"):
		_hotbar.select_index(4)
	elif event.is_action_pressed("hotbar_6"):
		_hotbar.select_index(5)
	elif event.is_action_pressed("hotbar_7"):
		_hotbar.select_index(6)
	elif event.is_action_pressed("hotbar_8"):
		_hotbar.select_index(7)
	elif event.is_action_pressed("hotbar_9"):
		_hotbar.select_index(8)
	elif event.is_action_pressed("hotbar_next"):
		_hotbar.cycle(1)
	elif event.is_action_pressed("hotbar_prev"):
		_hotbar.cycle(-1)
	elif event.is_action_pressed("pick_block"):
		_pick_selected_block()
	elif event.is_action_pressed("drop_one"):
		_drop_selected_one()

	if event.is_action_pressed("break_block"):
		_break_held = true
		_begin_break_action()
	elif event.is_action_released("break_block"):
		_break_held = false
		_reset_break_state()

	if event.is_action_pressed("place_block"):
		if _should_repeat_place_action():
			_place_held = true
			_request_place_action()
			_place_repeat_timer = repeat_start_delay
		else:
			_request_place_action()
	elif event.is_action_released("place_block"):
		_place_held = false
		_place_repeat_timer = 0.0

func _begin_break_action() -> void:
	if _is_creative():
		if _try_hit_mob():
			return
		_request_break_selected_block()
		_break_repeat_timer = creative_break_repeat
		return

	if not _is_block_breaking_enabled():
		return
	if _break_cooldown_remaining > 0.0:
		return

	if _try_hit_mob():
		_spend_stamina(punch_stamina_cost)
		return

	if not _selector.has_selection():
		_spend_stamina(punch_stamina_cost * 0.35)
		_reset_break_state()
		return

	_sync_break_target(true)

func _process_breaking(delta: float) -> void:
	if _is_creative():
		_break_repeat_timer -= delta
		if _break_repeat_timer <= 0.0:
			if _try_hit_mob():
				_break_repeat_timer = creative_break_repeat
				return
			_request_break_selected_block()
			_break_repeat_timer = creative_break_repeat
		return

	if not _is_block_breaking_enabled():
		_break_held = false
		_reset_break_state()
		return

	if not _selector.has_selection():
		_reset_break_state()
		return

	var selected: Vector3i = _selector.get_selected_block()
	if selected != _break_target:
		_sync_break_target(false)

	var block_id: int = _world.get_block_global(selected.x, selected.y, selected.z)
	if block_id == SSDVoxelDefs.BlockId.AIR:
		_reset_break_state()
		return

	var break_duration: float = _get_break_duration(block_id)
	_break_elapsed += delta
	_break_progress = clampf(_break_elapsed / maxf(0.05, break_duration), 0.0, 1.0)

	_break_stamina_accum += delta
	while _break_stamina_accum >= 0.25:
		_break_stamina_accum -= 0.25
		if not _spend_stamina(block_break_stamina_per_second * 0.25):
			_break_held = false
			_reset_break_state()
			return

	_update_break_ui(true)

	if _break_progress >= 1.0:
		if _request_break_selected_block():
			_spend_stamina(block_break_finish_stamina)
			_break_cooldown_remaining = survival_break_cooldown
		_reset_break_state()

func _sync_break_target(force_reset: bool) -> void:
	if not _selector.has_selection():
		_reset_break_state()
		return
	var selected: Vector3i = _selector.get_selected_block()
	if force_reset or selected != _break_target:
		_break_target = selected
		_break_progress = 0.0
		_break_elapsed = 0.0
		_break_stamina_accum = 0.0
		_update_break_ui(true)

func _reset_break_state() -> void:
	_break_target = INVALID_BLOCK
	_break_progress = 0.0
	_break_elapsed = 0.0
	_break_stamina_accum = 0.0
	_update_break_ui(false)

func _update_break_ui(show: bool) -> void:
	if _hotbar == null:
		return
	if not show or _break_progress <= 0.0 or _break_target == INVALID_BLOCK:
		_hotbar.set_break_progress(0.0, "", false)
		return
	var percent_text: String = "%d%%" % int(round(_break_progress * 100.0))
	_hotbar.set_break_progress(_break_progress, percent_text, true)

func _try_hit_mob() -> bool:
	if _camera == null:
		return false
	var origin: Vector3 = _camera.global_position
	var target: Vector3 = origin + (-_camera.global_basis.z * 6.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [_player]
	var hit: Dictionary = _world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_method("interact_kill"):
		collider.call("interact_kill")
		return true
	return false

func _pick_selected_block() -> void:
	if not _selector.has_selection():
		return
	var selected: Vector3i = _selector.get_selected_block()
	var block_id: int = _world.get_block_global(selected.x, selected.y, selected.z)
	if SSDItemDefs.is_placeable_block(block_id):
		_inventory.pick_block_creative(block_id)

func _request_break_selected_block() -> bool:
	if not _selector.has_selection():
		return false

	var selected: Vector3i = _selector.get_selected_block()
	var old_block: int = _world.get_block_global(selected.x, selected.y, selected.z)
	if old_block == SSDVoxelDefs.BlockId.AIR:
		return false

	if _network_delegate != null and _network_delegate.has_method("request_break_block_from_interactor"):
		return bool(_network_delegate.call("request_break_block_from_interactor", selected, old_block, _is_survival()))

	if _world.request_set_block_global(selected.x, selected.y, selected.z, SSDVoxelDefs.BlockId.AIR):
		if old_block == SSDVoxelDefs.BlockId.FURNACE and _furnace_manager != null:
			_furnace_manager.remove_state(selected)
		var cooking_station_type: String = SSDCooking.get_station_type_for_block(old_block)
		if not cooking_station_type.is_empty() and _cooking_manager != null:
			_cooking_manager.remove_state(selected)
		if old_block == SSDVoxelDefs.BlockId.DISPLAY_CASE and _display_case_manager != null:
			_display_case_manager.remove_state(selected)
		if _is_survival():
			var dropped_item_id: int = _get_drop_for_block(old_block)
			if dropped_item_id != SSDItemDefs.ITEM_AIR:
				var drop_position: Vector3 = Vector3(selected.x + 0.5, selected.y + 0.55, selected.z + 0.5)
				var impulse: Vector3 = Vector3(randf_range(-1.2, 1.2), randf_range(1.8, 2.6), randf_range(-1.2, 1.2))
				spawn_item_drop.emit(dropped_item_id, 1, drop_position, impulse)
		return true
	return false

func _get_drop_for_block(block_id: int) -> int:
	if SSDVoxelDefs.is_fluid(block_id):
		return SSDItemDefs.ITEM_AIR
	if SSDVoxelDefs.requires_correct_tool_for_drop(block_id) and not _can_harvest_block(block_id):
		return SSDItemDefs.ITEM_AIR
	if block_id == SSDVoxelDefs.BlockId.STONE:
		return SSDItemDefs.ITEM_COBBLESTONE
	if block_id == SSDVoxelDefs.BlockId.COAL_ORE:
		return SSDItemDefs.ITEM_COAL
	if block_id == SSDVoxelDefs.BlockId.IRON_ORE:
		return SSDItemDefs.ITEM_IRON_CHUNK
	var crop_drop: int = SSDCrops.get_break_drop_item_id(block_id)
	if SSDVoxelDefs.is_plant_block(block_id) or SSDVoxelDefs.is_bush_block(block_id) or block_id == SSDVoxelDefs.BlockId.MANGO_SAPLING or block_id == SSDVoxelDefs.BlockId.MANGO_LEAVES or block_id == SSDVoxelDefs.BlockId.FARMLAND:
		return crop_drop
	if crop_drop != SSDItemDefs.ITEM_AIR:
		return crop_drop
	return block_id

func _request_place_action() -> void:
	if _selector.has_selection():
		var selected_block: Vector3i = _selector.get_selected_block()
		var selected_id: int = _world.get_block_global(selected_block.x, selected_block.y, selected_block.z)
		if _try_harvest_crop(selected_block, selected_id):
			return
		if selected_id == SSDVoxelDefs.BlockId.CRAFTING_TABLE:
			request_open_crafting_table.emit()
			return
		if selected_id == SSDVoxelDefs.BlockId.FURNACE:
			request_open_furnace.emit(selected_block)
			return
		if selected_id == SSDVoxelDefs.BlockId.STOVE:
			if _try_interact_stove(selected_block):
				return
			return
		if selected_id == SSDVoxelDefs.BlockId.OVEN:
			if _try_interact_oven(selected_block):
				return
			return
		if selected_id == SSDVoxelDefs.BlockId.DISPLAY_CASE:
			if _try_interact_display_case(selected_block):
				return
			return
		if selected_id == SSDVoxelDefs.BlockId.PREP_TABLE:
			request_open_cooking_station.emit(selected_block, SSDCooking.STATION_PREP)
			return
		var cooking_station_type: String = SSDCooking.get_station_type_for_block(selected_id)
		if not cooking_station_type.is_empty():
			request_open_cooking_station.emit(selected_block, cooking_station_type)
			return

	var item_id: int = _inventory.get_selected_block_id()
	if item_id == SSDItemDefs.ITEM_AIR:
		return

	if item_id == SSDItemDefs.ITEM_GLASS_BOTTLE:
		if _try_fill_bottle():
			return

	if SSDCrops.can_item_be_planted(item_id):
		if _try_place_crop_or_bush(item_id):
			return

	if SSDItemDefs.is_consumable(item_id) and not SSDItemDefs.is_placeable_block(item_id):
		if _consume_selected_item():
			return

	if SSDItemDefs.is_spawn_egg(item_id):
		if _try_use_spawn_egg(item_id):
			return

	if not SSDItemDefs.is_placeable_block(item_id):
		return
	if _is_survival() and _inventory.get_selected_block_count() <= 0:
		return

	var place_block: Vector3i = _resolve_place_block()
	if place_block == INVALID_BLOCK:
		return
	var existing_block: int = _world.get_block_global(place_block.x, place_block.y, place_block.z)
	if existing_block != SSDVoxelDefs.BlockId.AIR and not SSDVoxelDefs.is_fluid(existing_block):
		return
	if item_id == SSDVoxelDefs.BlockId.DISPLAY_CASE:
		var upper_block: int = _world.get_block_global(place_block.x, place_block.y + 1, place_block.z)
		if upper_block != SSDVoxelDefs.BlockId.AIR and not SSDVoxelDefs.is_fluid(upper_block):
			return

	var allow_under_jump: bool = Input.is_action_pressed("jump") and not _player.is_on_floor()
	if _would_place_inside_player(place_block, allow_under_jump):
		return

	var placement_facing_degrees: float = _compute_placement_facing_degrees(place_block)
	var placed: bool = false
	if _network_delegate != null and _network_delegate.has_method("request_place_block_from_interactor"):
		placed = bool(_network_delegate.call("request_place_block_from_interactor", place_block, item_id, _is_survival(), placement_facing_degrees))
	else:
		placed = _world.request_set_block_global(place_block.x, place_block.y, place_block.z, item_id)
		if placed:
			_apply_oriented_block_placement(place_block, item_id, placement_facing_degrees)

	if placed:
		if item_id == SSDVoxelDefs.BlockId.DISPLAY_CASE and _display_case_manager != null:
			_display_case_manager.ensure_visual(place_block)
		if _is_survival():
			_inventory.try_consume_selected_one()



func _try_interact_display_case(block_pos: Vector3i) -> bool:
	if _display_case_manager == null:
		return false
	var held_item_id: int = _inventory.get_selected_block_id()
	var crouching: bool = Input.is_action_pressed("crouch")
	if crouching and held_item_id == SSDItemDefs.ITEM_AIR:
		var stack: Dictionary = _display_case_manager.take_last_clothing(block_pos)
		return _return_stack_to_inventory(int(stack.get("item_id", SSDItemDefs.ITEM_AIR)), int(stack.get("count", 0)))
	if held_item_id == SSDItemDefs.ITEM_AIR:
		return _display_case_manager.toggle_open(block_pos)
	if SSDItemDefs.is_equipment_item(held_item_id):
		if _display_case_manager.try_insert_clothing(block_pos, held_item_id):
			if _is_survival():
				_inventory.try_consume_selected_one()
			return true
	return false

func _try_interact_oven(block_pos: Vector3i) -> bool:
	if _cooking_manager == null:
		return false
	var state: SSDCookingState = _cooking_manager.get_state(block_pos, SSDCooking.STATION_OVEN)
	if state == null:
		return false

	var held_item_id: int = _inventory.get_selected_block_id()
	var crouching: bool = Input.is_action_pressed("crouch")

	if crouching and held_item_id == SSDItemDefs.ITEM_AIR:
		state.toggle_active()
		return true

	if held_item_id == SSDItemDefs.ITEM_AIR:
		if state.output_count > 0:
			return _try_take_stove_output(state)
		if state.appliance_on and state.input_count > 0:
			var input_stack: Dictionary = state.take_input_stack()
			return _return_stack_to_inventory(int(input_stack.get("item_id", SSDItemDefs.ITEM_AIR)), int(input_stack.get("count", 0)))
		if state.appliance_on and state.fuel_count > 0:
			var fuel_stack: Dictionary = state.take_fuel_stack()
			return _return_stack_to_inventory(int(fuel_stack.get("item_id", SSDItemDefs.ITEM_AIR)), int(fuel_stack.get("count", 0)))
		return false

	if state.can_insert_oven_fuel(held_item_id):
		if state.insert_oven_fuel(held_item_id):
			if _is_survival():
				_inventory.try_consume_selected_one()
			return true

	if state.can_insert_oven_input(held_item_id):
		if state.insert_oven_input(held_item_id):
			if _is_survival():
				_inventory.try_consume_selected_one()
			return true

	if state.output_count > 0:
		return _try_take_stove_output(state)
	return false

func _try_interact_stove(block_pos: Vector3i) -> bool:
	if _cooking_manager == null:
		return false
	var state: SSDCookingState = _cooking_manager.get_state(block_pos, SSDCooking.STATION_STOVE)
	if state == null:
		return false

	var held_item_id: int = _inventory.get_selected_block_id()
	var crouching: bool = Input.is_action_pressed("crouch")

	if crouching:
		if state.output_count > 0:
			return _try_take_stove_output(state)
		if held_item_id == SSDItemDefs.ITEM_AIR:
			if state.input_secondary_count > 0:
				var second_stack: Dictionary = state.take_secondary_input_stack()
				return _return_stack_to_inventory(int(second_stack.get("item_id", SSDItemDefs.ITEM_AIR)), int(second_stack.get("count", 0)))
			if state.input_count > 0:
				var input_stack: Dictionary = state.take_input_stack()
				return _return_stack_to_inventory(int(input_stack.get("item_id", SSDItemDefs.ITEM_AIR)), int(input_stack.get("count", 0)))
			return false
		if state.has_cookware() and not state.appliance_on and state.input_count <= 0 and state.output_count <= 0 and held_item_id == state.get_cookware_item_id():
			var cookware_id: int = state.take_stove_cookware()
			return _return_stack_to_inventory(cookware_id, 1)
		return false

	if held_item_id == SSDItemDefs.ITEM_AIR:
		if state.output_count > 0:
			return _try_take_stove_output(state)
		state.toggle_active()
		return true

	if state.can_place_stove_cookware(held_item_id):
		if state.place_stove_cookware(held_item_id):
			if _is_survival():
				_inventory.try_consume_selected_one()
			return true

	if state.can_insert_stove_input(held_item_id):
		if state.insert_stove_input(held_item_id):
			if _is_survival():
				_inventory.try_consume_selected_one()
			return true

	if state.output_count > 0:
		return _try_take_stove_output(state)
	return false

func _try_take_stove_output(state: SSDCookingState) -> bool:
	if state == null or state.output_count <= 0 or state.output_item_id == SSDItemDefs.ITEM_AIR:
		return false
	var item_id: int = state.output_item_id
	var count: int = state.output_count
	var remaining: int = _inventory.add_items(item_id, count)
	var moved: int = count - remaining
	if moved <= 0:
		return false
	state.output_count = remaining
	if state.output_count <= 0:
		state.output_count = 0
		state.output_item_id = SSDItemDefs.ITEM_AIR
	return true

func _return_stack_to_inventory(item_id: int, count: int) -> bool:
	if item_id == SSDItemDefs.ITEM_AIR or count <= 0:
		return false
	var remaining: int = _inventory.add_items(item_id, count)
	return remaining < count

func _consume_selected_item() -> bool:
	var item_id: int = _inventory.get_selected_block_id()
	if not SSDItemDefs.is_consumable(item_id):
		return false
	var vitals: SSDVitals = _get_vitals()
	if vitals == null:
		return false

	vitals.restore_hunger(SSDItemDefs.get_hunger_restore(item_id))
	vitals.restore_thirst(SSDItemDefs.get_thirst_restore(item_id))
	vitals.restore_stamina(SSDItemDefs.get_stamina_restore(item_id))

	var return_item_id: int = SSDItemDefs.get_consumed_return_item_id(item_id)
	if _is_survival():
		_inventory.try_consume_selected_one()
		if return_item_id != SSDItemDefs.ITEM_AIR:
			_inventory.add_items(return_item_id, 1)
	elif return_item_id != SSDItemDefs.ITEM_AIR:
		_inventory.add_items(return_item_id, 1)
	return true

func _try_fill_bottle() -> bool:
	if not _selector.has_selection():
		return false
	var selected: Vector3i = _selector.get_selected_block()
	var block_id: int = _world.get_block_global(selected.x, selected.y, selected.z)
	if not SSDVoxelDefs.is_fluid(block_id):
		return false
	if _is_survival():
		if _inventory.get_selected_block_count() <= 0:
			return false
		_inventory.try_consume_selected_one()
	_inventory.add_items(SSDItemDefs.ITEM_WATER_BOTTLE, 1)
	return true

func _try_use_spawn_egg(item_id: int) -> bool:
	var mob_type: String = SSDItemDefs.get_spawn_egg_mob_type(item_id)
	if mob_type.is_empty():
		return false
	var place_block: Vector3i = _resolve_place_block()
	if place_block == INVALID_BLOCK and _selector.has_selection():
		place_block = _selector.get_selected_block() + Vector3i.UP
	if place_block == INVALID_BLOCK:
		return false
	var existing_block: int = _world.get_block_global(place_block.x, place_block.y, place_block.z)
	if existing_block != SSDVoxelDefs.BlockId.AIR and not SSDVoxelDefs.is_fluid(existing_block):
		return false
	var spawn_pos: Vector3 = Vector3(place_block.x + 0.5, place_block.y, place_block.z + 0.5)
	request_spawn_mob.emit(mob_type, spawn_pos)
	if _is_survival():
		_inventory.try_consume_selected_one()
	return true

func _resolve_place_block() -> Vector3i:
	if Input.is_action_pressed("jump") and not _player.is_on_floor():
		var under_player: Vector3i = _get_under_player_place_block()
		if under_player != INVALID_BLOCK and not SSDVoxelDefs.is_solid(_world.get_block_global(under_player.x, under_player.y, under_player.z)):
			return under_player
	if _selector.has_place_target():
		return _selector.get_place_block()
	return INVALID_BLOCK

func _get_under_player_place_block() -> Vector3i:
	var samples: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(PLAYER_RADIUS * 0.55, 0.0),
		Vector2(-PLAYER_RADIUS * 0.55, 0.0),
		Vector2(0.0, PLAYER_RADIUS * 0.55),
		Vector2(0.0, -PLAYER_RADIUS * 0.55),
	]
	var feet_y: float = (_player.global_position.y / SSDChunkConfig.VOXEL_SIZE) - 0.18
	var start_y: int = floori(feet_y) - 1
	var best_target: Vector3i = INVALID_BLOCK
	var best_y: int = -999999
	for sample: Vector2 in samples:
		var x: int = floori((_player.global_position.x + sample.x) / SSDChunkConfig.VOXEL_SIZE)
		var z: int = floori((_player.global_position.z + sample.y) / SSDChunkConfig.VOXEL_SIZE)
		for y: int in range(start_y, start_y - 5, -1):
			if SSDVoxelDefs.is_solid(_world.get_block_global(x, y, z)):
				if y + 1 > best_y:
					best_y = y + 1
					best_target = Vector3i(x, y + 1, z)
				break
	if best_target != INVALID_BLOCK:
		return best_target
	return Vector3i(floori(_player.global_position.x), start_y, floori(_player.global_position.z))

func _would_place_inside_player(block: Vector3i, allow_under_jump: bool) -> bool:
	var block_min: Vector3 = Vector3(float(block.x), float(block.y), float(block.z)) * SSDChunkConfig.VOXEL_SIZE
	var block_max: Vector3 = block_min + (Vector3.ONE * SSDChunkConfig.VOXEL_SIZE)
	if allow_under_jump and block_max.y <= (_player.global_position.y + 0.02):
		return false
	var feet_y: float = _player.global_position.y
	var player_min: Vector3 = Vector3(_player.global_position.x - PLAYER_RADIUS + 0.02, feet_y + 0.03, _player.global_position.z - PLAYER_RADIUS + 0.02)
	var player_max: Vector3 = Vector3(_player.global_position.x + PLAYER_RADIUS - 0.02, feet_y + PLAYER_HEIGHT - 0.08, _player.global_position.z + PLAYER_RADIUS - 0.02)
	if block_max.y <= player_min.y + 0.02:
		return false
	return _aabb_intersects(block_min, block_max, player_min, player_max)

func _aabb_intersects(a_min: Vector3, a_max: Vector3, b_min: Vector3, b_max: Vector3) -> bool:
	return a_min.x < b_max.x and a_max.x > b_min.x and a_min.y < b_max.y and a_max.y > b_min.y and a_min.z < b_max.z and a_max.z > b_min.z

func cancel_held_actions() -> void:
	_break_held = false
	_place_held = false
	_break_repeat_timer = 0.0
	_place_repeat_timer = 0.0
	_reset_break_state()

func _drop_selected_one() -> void:
	var block_id: int = SSDItemDefs.ITEM_AIR
	if _is_creative():
		block_id = _inventory.get_selected_block_id()
		if block_id == SSDItemDefs.ITEM_AIR:
			return
	else:
		block_id = _inventory.try_drop_one_selected()
		if block_id == SSDItemDefs.ITEM_AIR:
			return
	var drop_position: Vector3 = _player.global_position + (-_player.global_basis.z * 0.90) + Vector3(0.0, 1.30, 0.0)
	var impulse: Vector3 = (-_player.global_basis.z.normalized() * 5.0) + Vector3(0.0, 1.9, 0.0)
	spawn_item_drop.emit(block_id, 1, drop_position, impulse)

func _get_break_duration(block_id: int) -> float:
	if _is_creative():
		return 0.0

	var selected_item: int = _inventory.get_selected_block_id()
	var preferred_tool: String = SSDVoxelDefs.get_preferred_tool(block_id)
	var required_tier: int = SSDVoxelDefs.get_required_tool_tier(block_id)
	var hardness: float = maxf(0.25, SSDVoxelDefs.get_break_hardness(block_id))

	var base_duration: float = 1.5
	match block_id:
		SSDVoxelDefs.BlockId.OAK_LOG:
			base_duration = 3.0
		SSDVoxelDefs.BlockId.OAK_PLANKS:
			base_duration = 1.0
		SSDVoxelDefs.BlockId.OAK_LEAVES:
			base_duration = 0.6
		SSDVoxelDefs.BlockId.STONE, SSDVoxelDefs.BlockId.COBBLESTONE:
			base_duration = 3.0
		SSDVoxelDefs.BlockId.COAL_ORE, SSDVoxelDefs.BlockId.IRON_ORE:
			base_duration = 3.4
		SSDVoxelDefs.BlockId.CRAFTING_TABLE:
			base_duration = 2.4
		SSDVoxelDefs.BlockId.FURNACE:
			base_duration = 3.8
		SSDVoxelDefs.BlockId.GLASS:
			base_duration = 0.8
		_:
			base_duration = maxf(1.5, hardness * 1.65)

	var using_tool: bool = SSDItemDefs.is_tool_item(selected_item)
	var matching_tool: bool = false
	var tool_tier: int = 0
	var speed_multiplier: float = 1.0
	if using_tool:
		var tool_type: String = SSDItemDefs.get_tool_type(selected_item)
		tool_tier = SSDItemDefs.get_tool_tier(selected_item)
		if preferred_tool.is_empty() or tool_type == preferred_tool:
			matching_tool = true
			speed_multiplier = maxf(1.0, SSDItemDefs.get_tool_break_speed(selected_item))
		else:
			speed_multiplier = 0.9

	var duration: float = base_duration
	if matching_tool:
		duration /= speed_multiplier
		if required_tier > 0 and tool_tier < required_tier:
			duration *= 2.0
	elif required_tier > 0:
		duration *= 1.75
	elif not preferred_tool.is_empty():
		duration *= 1.20

	if preferred_tool.is_empty():
		duration = maxf(1.5, duration)
	elif block_id == SSDVoxelDefs.BlockId.OAK_PLANKS and not matching_tool:
		duration = maxf(1.0, duration)
	elif block_id == SSDVoxelDefs.BlockId.OAK_LOG and not matching_tool:
		duration = maxf(3.0, duration)

	return clampf(duration, 0.15, 8.0)

func _can_harvest_block(block_id: int) -> bool:
	if not SSDVoxelDefs.requires_correct_tool_for_drop(block_id):
		return true
	var selected_item: int = _inventory.get_selected_block_id()
	if not SSDItemDefs.is_tool_item(selected_item):
		return false
	if SSDItemDefs.get_tool_type(selected_item) != SSDVoxelDefs.get_preferred_tool(block_id):
		return false
	return SSDItemDefs.get_tool_tier(selected_item) >= SSDVoxelDefs.get_required_tool_tier(block_id)

func _spend_stamina(amount: float) -> bool:
	if _is_creative():
		return true
	var vitals: SSDVitals = _get_vitals()
	if vitals == null:
		return true
	return vitals.spend_stamina(amount)

func _get_vitals() -> SSDVitals:
	if _player != null and _player.has_method("get_vitals"):
		return _player.call("get_vitals") as SSDVitals
	return null

func _is_block_breaking_enabled() -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return true
	return bool(cfg.get_value("gameplay", "block_breaking_enabled", true))

func _should_repeat_place_action() -> bool:
	var item_id: int = _inventory.get_selected_block_id()
	return SSDItemDefs.is_placeable_block(item_id)

func _is_creative() -> bool:
	return _game_mode != null and _game_mode.is_creative()

func _is_survival() -> bool:
	return not _is_creative()


func _try_place_crop_or_bush(item_id: int) -> bool:
	var plant_block_id: int = SSDCrops.get_planted_block_for_item(item_id)
	if plant_block_id == SSDVoxelDefs.BlockId.AIR:
		return false
	var place_block: Vector3i = _resolve_place_block()
	if place_block == INVALID_BLOCK:
		return false
	var existing_block: int = _world.get_block_global(place_block.x, place_block.y, place_block.z)
	if existing_block != SSDVoxelDefs.BlockId.AIR and not SSDVoxelDefs.is_fluid(existing_block):
		return false
	var ground_pos: Vector3i = place_block + Vector3i.DOWN
	var ground_block: int = _world.get_block_global(ground_pos.x, ground_pos.y, ground_pos.z)
	if not SSDCrops.can_plant_on_ground(plant_block_id, ground_block):
		return false
	if _would_place_inside_player(place_block, false):
		return false
	var changes: Array[Dictionary] = []
	if SSDCrops.requires_farmland(plant_block_id) and ground_block != SSDVoxelDefs.BlockId.FARMLAND:
		changes.append({"x": ground_pos.x, "y": ground_pos.y, "z": ground_pos.z, "id": SSDVoxelDefs.BlockId.FARMLAND})
	changes.append({"x": place_block.x, "y": place_block.y, "z": place_block.z, "id": plant_block_id})
	var changed: int = _world.request_set_blocks_batch(changes, true, false)
	if changed > 0:
		if _is_survival():
			_inventory.try_consume_selected_one()
		return true
	return false

func _try_harvest_crop(block_pos: Vector3i, block_id: int) -> bool:
	if _inventory.get_selected_block_id() != SSDItemDefs.ITEM_AIR:
		return false
	if not SSDCrops.is_use_harvestable(block_id):
		return false
	var harvest: Dictionary = SSDCrops.get_use_harvest_result(block_id)
	var item_id: int = int(harvest.get("item_id", SSDItemDefs.ITEM_AIR))
	var count: int = int(harvest.get("count", 0))
	var reset_block_id: int = int(harvest.get("reset_block_id", block_id))
	if item_id == SSDItemDefs.ITEM_AIR or count <= 0:
		return false
	if not _world.request_set_block_global(block_pos.x, block_pos.y, block_pos.z, reset_block_id, false):
		return false
	var remaining: int = _inventory.add_items(item_id, count)
	var moved: int = count - remaining
	if remaining > 0:
		var drop_position: Vector3 = Vector3(block_pos.x + 0.5, block_pos.y + 0.55, block_pos.z + 0.5)
		var impulse: Vector3 = Vector3(randf_range(-0.4, 0.4), randf_range(1.4, 2.0), randf_range(-0.4, 0.4))
		spawn_item_drop.emit(item_id, remaining, drop_position, impulse)
	return moved > 0 or remaining > 0


func _apply_oriented_block_placement(block_pos: Vector3i, item_id: int, facing_deg: float) -> void:
	if item_id == SSDVoxelDefs.BlockId.DISPLAY_CASE and _display_case_manager != null:
		_display_case_manager.set_block_facing(block_pos, facing_deg)
		return
	var station_type: String = SSDCooking.get_station_type_for_block(item_id)
	if _cooking_manager != null and (station_type == SSDCooking.STATION_STOVE or station_type == SSDCooking.STATION_OVEN):
		_cooking_manager.set_block_facing(block_pos, station_type, facing_deg)

func _compute_placement_facing_degrees(block_pos: Vector3i) -> float:
	var block_center: Vector3 = Vector3(block_pos.x + 0.5, _player.global_position.y, block_pos.z + 0.5)
	var to_player: Vector3 = _player.global_position - block_center
	to_player.y = 0.0
	if to_player.length_squared() <= 0.0001:
		var camera_forward: Vector3 = -_camera.global_basis.z
		camera_forward.y = 0.0
		if camera_forward.length_squared() > 0.0001:
			to_player = -camera_forward.normalized()
		else:
			to_player = Vector3(0.0, 0.0, 1.0)
	else:
		to_player = to_player.normalized()
	return snappedf(rad_to_deg(atan2(to_player.x, to_player.z)), 90.0)
