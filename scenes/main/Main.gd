extends Node3D
class_name SSDMain

const SSD_BLOCK_INTERACTOR_SCRIPT = preload("res://client/interact/SSDBlockInteractor.gd")
const SSD_HOTBAR_SCRIPT = preload("res://ui/SSDHotbar.gd")
const SSD_VITALS_SCRIPT = preload("res://shared/gameplay/SSDVitals.gd")
const SSD_CROSSHAIR_SCRIPT = preload("res://ui/SSDCrosshair.gd")
const SSD_DAY_NIGHT_SCRIPT = preload("res://shared/time/SSDDayNightCycle.gd")
const SSD_INVENTORY_SCRIPT = preload("res://shared/gameplay/SSDInventory.gd")
const SSD_INVENTORY_UI_SCRIPT = preload("res://ui/SSDInventoryUI.gd")
const SSD_SETTINGS_MENU_SCRIPT = preload("res://ui/SSDSettingsMenu.gd")
const SSD_ITEM_DROP_SCRIPT = preload("res://world/items/SSDItemDrop.gd")
const SSD_GAME_MODE_SCRIPT = preload("res://shared/gameplay/SSDGameMode.gd")
const SSD_CHAT_SCRIPT = preload("res://ui/SSDProximityChat.gd")
const SSD_FURNACE_MANAGER_SCRIPT = preload("res://world/furnace/SSDFurnaceManager.gd")
const SSD_COOKING_MANAGER_SCRIPT = preload("res://world/cooking/SSDCookingManager.gd")
const SSD_DISPLAY_CASE_MANAGER_SCRIPT = preload("res://world/display/SSDDisplayCaseManager.gd")
const SSD_MOB_SPAWNER_SCRIPT = preload("res://world/mobs/SSDPassiveMobSpawner.gd")
const SSD_SCHEMATIC_MANAGER_SCRIPT = preload("res://shared/schematics/SSDSchematicManager.gd")
const SSD_SCHEMATIC_PREVIEW_SCRIPT = preload("res://world/schematics/SSDSchematicPreview.gd")
const SSD_REMOTE_PLAYER_SCRIPT = preload("res://shared/network/SSDRemotePlayer.gd")
const NETWORK_STATE_SEND_INTERVAL: float = 0.05

@onready var world: SSDWorld = $World as SSDWorld
@onready var player: SSDFlyPlayer = $Player as SSDFlyPlayer
@onready var player_camera: Camera3D = $Player/Pivot/Camera3D as Camera3D
@onready var selector: SSDBlockSelector = $BlockSelector as SSDBlockSelector
@onready var hud: SSDDebugHUD = $HUD as SSDDebugHUD
@onready var sun: DirectionalLight3D = $Sun as DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment as WorldEnvironment

var _interactor: SSDBlockInteractor
var _hotbar: SSDHotbar
var _vitals: SSDVitals
var _crosshair: SSDCrosshair
var _day_night: SSDDayNightCycle
var _inventory: SSDInventory
var _inventory_ui: SSDInventoryUI
var _settings_menu: SSDSettingsMenu
var _item_drop_root: Node3D
var _game_mode: SSDGameMode
var _chat_ui: SSDProximityChat
var _furnace_manager: SSDFurnaceManager
var _cooking_manager: SSDCookingManager
var _display_case_manager: SSDDisplayCaseManager
var _mob_spawner: SSDPassiveMobSpawner
var _schematic_manager: SSDSchematicManager
var _schematic_preview: SSDSchematicPreview
var _schematic_preview_origin: Vector3i = Vector3i.ZERO
var _schematic_preview_active: bool = false
var _network_mode: int = SSDCore.NetworkMode.OFFLINE
var _network_player_name: String = SSDCore.DEFAULT_PLAYER_NAME
var _network_port: int = SSDCore.DEFAULT_SERVER_PORT
var _network_address: String = SSDNetworkConfig.DEFAULT_LOCAL_IP
var _remote_players: Dictionary = {}
var _peer_names: Dictionary = {}
var _peer_profiles: Dictionary = {}
var _peer_states: Dictionary = {}
var _state_send_accumulator: float = 0.0
var _multiplayer_signals_connected: bool = false

func _ready() -> void:
	var selected_world: Dictionary = SSDCore.get_current_world()
	world.world_seed = int(selected_world.get("seed", world.world_seed))
	world.regenerate()
	_item_drop_root = Node3D.new()
	_item_drop_root.name = "ItemDrops"
	add_child(_item_drop_root)

	_day_night = SSD_DAY_NIGHT_SCRIPT.new() as SSDDayNightCycle
	_day_night.name = "DayNightCycle"
	add_child(_day_night)
	_day_night.set_targets(sun, world_environment, player)

	_game_mode = SSD_GAME_MODE_SCRIPT.new() as SSDGameMode
	_game_mode.name = "GameMode"
	add_child(_game_mode)
	_game_mode.mode_changed.connect(_on_game_mode_changed)

	var safe_spawn: Vector3 = world.prime_spawn_area(player.global_position, 2)
	player.global_position = safe_spawn
	player.reset_motion()

	world.set_target(player)
	player.set_world(world)
	selector.set_targets(world, player_camera)

	_inventory = SSD_INVENTORY_SCRIPT.new() as SSDInventory
	_inventory.name = "Inventory"
	add_child(_inventory)
	player.set_inventory(_inventory)

	_hotbar = SSD_HOTBAR_SCRIPT.new() as SSDHotbar
	_hotbar.name = "Hotbar"
	add_child(_hotbar)
	_hotbar.set_inventory(_inventory)

	_inventory_ui = SSD_INVENTORY_UI_SCRIPT.new() as SSDInventoryUI
	_inventory_ui.name = "InventoryUI"
	add_child(_inventory_ui)
	_inventory_ui.set_inventory(_inventory)
	_inventory_ui.set_game_mode(_game_mode)
	_inventory_ui.request_drop_stack.connect(_drop_stack_from_cursor)
	_inventory_ui.set_world(world)

	_settings_menu = SSD_SETTINGS_MENU_SCRIPT.new() as SSDSettingsMenu
	_settings_menu.name = "SettingsMenu"
	add_child(_settings_menu)
	_settings_menu.set_targets(player, player_camera, world, _game_mode, _day_night)
	_settings_menu.menu_closed.connect(func() -> void:
		if not _is_any_ui_open():
			_apply_ui_mode(false)
	)

	_crosshair = SSD_CROSSHAIR_SCRIPT.new() as SSDCrosshair
	_crosshair.name = "Crosshair"
	add_child(_crosshair)

	_vitals = SSD_VITALS_SCRIPT.new() as SSDVitals
	_vitals.name = "Vitals"
	add_child(_vitals)
	_vitals.apply_profile(SSDCore.get_current_world_profile())
	player.set_vitals(_vitals)
	_hotbar.set_vitals(_vitals)
	_inventory_ui.set_vitals(_vitals)

	_chat_ui = SSD_CHAT_SCRIPT.new() as SSDProximityChat
	_chat_ui.name = "ProximityChat"
	add_child(_chat_ui)
	_chat_ui.set_player(player)
	_chat_ui.chat_submitted.connect(_on_chat_submitted)
	_chat_ui.add_system_message("Loaded world: %s (seed %d)" % [SSDCore.get_current_world_name(), SSDCore.get_current_world_seed()])

	_furnace_manager = SSD_FURNACE_MANAGER_SCRIPT.new() as SSDFurnaceManager
	_furnace_manager.name = "FurnaceManager"
	add_child(_furnace_manager)
	_inventory_ui.set_furnace_manager(_furnace_manager)

	_cooking_manager = SSD_COOKING_MANAGER_SCRIPT.new() as SSDCookingManager
	_cooking_manager.name = "CookingManager"
	add_child(_cooking_manager)
	_cooking_manager.set_world(world)
	_inventory_ui.set_cooking_manager(_cooking_manager)

	_display_case_manager = SSD_DISPLAY_CASE_MANAGER_SCRIPT.new() as SSDDisplayCaseManager
	_display_case_manager.name = "DisplayCaseManager"
	add_child(_display_case_manager)
	_display_case_manager.set_world(world)

	_mob_spawner = SSD_MOB_SPAWNER_SCRIPT.new() as SSDPassiveMobSpawner
	_mob_spawner.name = "PassiveMobSpawner"
	add_child(_mob_spawner)
	_mob_spawner.set_targets(world, player)
	_mob_spawner.mob_spawned.connect(_on_mob_spawned)

	_schematic_manager = SSD_SCHEMATIC_MANAGER_SCRIPT.new() as SSDSchematicManager
	_schematic_manager.name = "SchematicManager"
	add_child(_schematic_manager)
	_schematic_manager.set_world(world)

	_schematic_preview = SSD_SCHEMATIC_PREVIEW_SCRIPT.new() as SSDSchematicPreview
	_schematic_preview.name = "SchematicPreview"
	add_child(_schematic_preview)

	_interactor = SSD_BLOCK_INTERACTOR_SCRIPT.new() as SSDBlockInteractor
	_interactor.name = "BlockInteractor"
	add_child(_interactor)
	_interactor.set_targets(world, player, player_camera, selector, _hotbar, _inventory, _game_mode, _furnace_manager, _cooking_manager, _display_case_manager)
	_interactor.spawn_item_drop.connect(_spawn_item_drop)
	_interactor.request_spawn_mob.connect(_spawn_mob_at)
	_interactor.request_open_crafting_table.connect(func() -> void:
		if _inventory_ui != null:
			_inventory_ui.open_crafting_table()
			_apply_ui_mode(true)
	)
	_interactor.request_open_furnace.connect(func(block_pos: Vector3i) -> void:
		if _inventory_ui != null:
			_inventory_ui.open_furnace(block_pos)
			_apply_ui_mode(true)
	)
	_interactor.request_open_cooking_station.connect(func(block_pos: Vector3i, station_type: String) -> void:
		if _inventory_ui != null:
			_inventory_ui.open_cooking_station(block_pos, station_type)
			_apply_ui_mode(true)
	)

	_interactor.set_network_delegate(self)

	hud.set_targets(world, player, selector, _hotbar, _vitals, _day_night)
	hud.set_inventory(_inventory)
	_apply_ui_mode(false)
	_on_game_mode_changed(_game_mode.get_mode(), _game_mode.get_mode_name())
	_setup_network_session()

func _exit_tree() -> void:
	if multiplayer != null:
		multiplayer.multiplayer_peer = null

func _input(event: InputEvent) -> void:
	if _chat_ui != null and _chat_ui.is_open():
		if event.is_action_pressed("toggle_menu"):
			_chat_ui.close_chat()
			_apply_ui_mode(false)
			get_viewport().set_input_as_handled()
		return

	if _inventory_ui != null and _inventory_ui.is_open():
		if event.is_action_pressed("toggle_menu"):
			_inventory_ui.close()
			_apply_ui_mode(false)
			get_viewport().set_input_as_handled()
		return

	if _settings_menu != null and _settings_menu.is_open():
		if event.is_action_pressed("toggle_menu"):
			_settings_menu.close()
			_apply_ui_mode(false)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_menu"):
		_settings_menu.toggle_open()
		_apply_ui_mode(_settings_menu.is_open())
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_inventory"):
		if _inventory_ui != null and not _inventory_ui.is_open():
			_inventory_ui.toggle_open()
			_apply_ui_mode(_inventory_ui.is_open())
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_chat"):
		if _chat_ui != null and not _chat_ui.is_open():
			_chat_ui.open_chat()
			_apply_ui_mode(true)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_gamemode"):
		if _is_multiplayer_client():
			if _chat_ui != null:
				_chat_ui.add_system_message("Only the host can change gamemode in multiplayer.")
		elif _game_mode != null:
			_game_mode.toggle_mode()
		get_viewport().set_input_as_handled()
		return

func _process(delta: float) -> void:
	if player.global_position.y < -32.0:
		var rescue_position: Vector3 = world.prime_spawn_area(player.global_position, 2)
		player.global_position = rescue_position
		player.reset_motion()
		return

	_soft_unstuck_player()
	_update_schematic_preview()
	if _crosshair != null:
		_crosshair.visible = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	_network_process(delta)

func _apply_ui_mode(ui_open: bool) -> void:
	player.set_controls_enabled(not ui_open)
	if ui_open and _interactor != null:
		_interactor.cancel_held_actions()
	if ui_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _spawn_mob_at(mob_type: String, world_position: Vector3) -> void:
	if _mob_spawner == null:
		return
	var mob: SSDPassiveMob = _mob_spawner.spawn_mob_at(mob_type, world_position)
	_on_mob_spawned(mob)

func _spawn_item_drop(block_id: int, count: int, world_position: Vector3, impulse: Vector3) -> void:
	call_deferred("_spawn_item_drop_deferred", block_id, count, world_position, impulse)

func _spawn_item_drop_deferred(block_id: int, count: int, world_position: Vector3, impulse: Vector3) -> void:
	if _item_drop_root == null:
		return
	var drop: SSDItemDrop = SSD_ITEM_DROP_SCRIPT.new() as SSDItemDrop
	drop.name = "Drop_%d" % Time.get_ticks_msec()
	_item_drop_root.add_child(drop)
	drop.global_position = world_position
	drop.setup(block_id, count, player, _inventory, impulse)

func _drop_stack_from_cursor(block_id: int, count: int) -> void:
	if count <= 0:
		return
	var drop_position: Vector3 = player.global_position + (-player.global_basis.z * 0.90) + Vector3(0.0, 1.25, 0.0)
	var impulse: Vector3 = (-player.global_basis.z.normalized() * 5.0) + Vector3(0.0, 1.8, 0.0)
	_spawn_item_drop(block_id, count, drop_position, impulse)

func _on_chat_submitted(message: String, sender_position: Vector3) -> void:
	var trimmed: String = message.strip_edges()
	if trimmed.is_empty():
		_apply_ui_mode(false)
		return
	if trimmed.begins_with("/"):
		if _is_multiplayer_client():
			if _chat_ui != null:
				_chat_ui.add_system_message("Commands run on the host in this build.")
		else:
			_handle_chat_command(trimmed)
		_apply_ui_mode(false)
		return
	_send_chat_message(trimmed, sender_position)
	_apply_ui_mode(false)

func _setup_network_session() -> void:
	var session: Dictionary = SSDCore.get_network_session()
	_network_mode = int(session.get("mode", SSDCore.NetworkMode.OFFLINE))
	_network_player_name = str(session.get("player_name", SSDCore.DEFAULT_PLAYER_NAME))
	_network_port = int(session.get("port", SSDCore.DEFAULT_SERVER_PORT))
	_network_address = str(session.get("address", SSDNetworkConfig.DEFAULT_LOCAL_IP))
	_peer_names.clear()
	_peer_profiles.clear()
	_peer_states.clear()
	_remote_players.clear()
	_connect_multiplayer_signals()

	match _network_mode:
		SSDCore.NetworkMode.HOST:
			_start_host_session()
		SSDCore.NetworkMode.CLIENT:
			_start_client_session()
		_:
			if _chat_ui != null:
				_chat_ui.add_system_message("Singleplayer session ready.")

func _connect_multiplayer_signals() -> void:
	if _multiplayer_signals_connected:
		return
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_multiplayer_signals_connected = true

func _start_host_session() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(_network_port, SSDNetworkConfig.MAX_PLAYERS)
	if err != OK:
		_network_mode = SSDCore.NetworkMode.OFFLINE
		if _chat_ui != null:
			_chat_ui.add_system_message("Failed to host on port %d (error %d)." % [_network_port, int(err)])
		return
	multiplayer.multiplayer_peer = peer
	_peer_names[1] = _network_player_name
	_peer_profiles[1] = SSDCore.get_current_world_profile()
	if _chat_ui != null:
		_chat_ui.add_system_message("Hosting %s on port %d." % [SSDCore.get_current_world_name(), _network_port])

func _start_client_session() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(_network_address, _network_port)
	if err != OK:
		_network_mode = SSDCore.NetworkMode.OFFLINE
		if _chat_ui != null:
			_chat_ui.add_system_message("Failed to connect to %s:%d (error %d)." % [_network_address, _network_port, int(err)])
		return
	multiplayer.multiplayer_peer = peer
	player.set_controls_enabled(false)
	if _chat_ui != null:
		_chat_ui.add_system_message("Connecting to %s:%d..." % [_network_address, _network_port])

func _is_multiplayer_client() -> bool:
	return _network_mode == SSDCore.NetworkMode.CLIENT and multiplayer.multiplayer_peer != null and not multiplayer.is_server()

func _is_multiplayer_host() -> bool:
	return _network_mode == SSDCore.NetworkMode.HOST and multiplayer.multiplayer_peer != null and multiplayer.is_server()

func _on_network_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	rpc_id(peer_id, "_rpc_receive_world_sync", world.world_seed, _day_night.get_time_hours(), _game_mode.get_mode_name())

func _on_network_peer_disconnected(peer_id: int) -> void:
	var left_name: String = str(_peer_names.get(peer_id, "Player"))
	_remove_remote_player(peer_id)
	_peer_names.erase(peer_id)
	_peer_profiles.erase(peer_id)
	_peer_states.erase(peer_id)
	if _chat_ui != null and not left_name.is_empty():
		_chat_ui.add_system_message("%s left the game." % left_name)

func _on_connected_to_server() -> void:
	_peer_names[multiplayer.get_unique_id()] = _network_player_name
	_peer_profiles[multiplayer.get_unique_id()] = SSDCore.get_current_world_profile()
	rpc_id(1, "_rpc_register_player", _network_player_name, SSDCore.get_current_world_profile())
	_send_local_player_state(true)

func _on_connection_failed() -> void:
	player.set_controls_enabled(true)
	if _chat_ui != null:
		_chat_ui.add_system_message("Connection failed.")

func _on_server_disconnected() -> void:
	player.set_controls_enabled(true)
	if _chat_ui != null:
		_chat_ui.add_system_message("Disconnected from host.")

func _network_process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	_state_send_accumulator += delta
	if _state_send_accumulator < NETWORK_STATE_SEND_INTERVAL:
		return
	_state_send_accumulator = 0.0
	_send_local_player_state(false)

func _send_local_player_state(force_send: bool) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if not force_send and not is_inside_tree():
		return
	var held_item_id: int = _inventory.get_selected_block_id() if _inventory != null else SSDItemDefs.ITEM_AIR
	var yaw: float = player.get_body_yaw_radians()
	var pitch: float = player.get_pitch_radians()
	var player_position: Vector3 = player.global_position
	if multiplayer.is_server():
		rpc("_rpc_receive_player_state", 1, player_position, yaw, pitch, held_item_id)
	else:
		rpc_id(1, "_rpc_submit_player_state", player_position, yaw, pitch, held_item_id)

func _spawn_or_update_remote_player(peer_id: int, profile: Dictionary, world_position: Vector3, yaw: float, pitch: float, held_item_id: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	var remote: SSDRemotePlayer = _remote_players.get(peer_id, null) as SSDRemotePlayer
	if remote == null:
		remote = SSD_REMOTE_PLAYER_SCRIPT.new() as SSDRemotePlayer
		remote.name = "RemotePlayer_%d" % peer_id
		add_child(remote)
		_remote_players[peer_id] = remote
	if not profile.is_empty():
		remote.apply_profile(profile)
	remote.apply_state(world_position, yaw, pitch, held_item_id)

func _remove_remote_player(peer_id: int) -> void:
	if not _remote_players.has(peer_id):
		return
	var remote: SSDRemotePlayer = _remote_players.get(peer_id, null) as SSDRemotePlayer
	if remote != null and is_instance_valid(remote):
		remote.queue_free()
	_remote_players.erase(peer_id)

func _send_chat_message(message: String, sender_position: Vector3) -> void:
	if multiplayer.multiplayer_peer == null:
		_broadcast_chat_message(_network_player_name, message, sender_position)
		return
	if multiplayer.is_server():
		_broadcast_chat_message(_network_player_name, message, sender_position)
		rpc("_rpc_receive_chat", _network_player_name, message, sender_position)
	else:
		rpc_id(1, "_rpc_submit_chat", message, sender_position)

func request_break_block_from_interactor(block_pos: Vector3i, old_block: int, survival: bool) -> bool:
	if _is_multiplayer_client():
		rpc_id(1, "_rpc_request_break_block", block_pos.x, block_pos.y, block_pos.z, old_block, survival)
		return true
	return _apply_block_break_authoritative(block_pos, old_block, survival, _is_multiplayer_host())

func request_place_block_from_interactor(block_pos: Vector3i, item_id: int, _survival: bool, facing_deg: float = 0.0) -> bool:
	if _is_multiplayer_client():
		rpc_id(1, "_rpc_request_place_block", block_pos.x, block_pos.y, block_pos.z, item_id, facing_deg)
		return true
	return _apply_block_place_authoritative(block_pos, item_id, _is_multiplayer_host(), facing_deg)

func _apply_block_break_authoritative(block_pos: Vector3i, old_block: int, survival: bool, broadcast_change: bool) -> bool:
	if old_block == SSDVoxelDefs.BlockId.AIR:
		return false
	if not world.request_set_block_global(block_pos.x, block_pos.y, block_pos.z, SSDVoxelDefs.BlockId.AIR):
		return false
	if old_block == SSDVoxelDefs.BlockId.FURNACE and _furnace_manager != null:
		_furnace_manager.remove_state(block_pos)
	var cooking_station_type: String = SSDCooking.get_station_type_for_block(old_block)
	if not cooking_station_type.is_empty() and _cooking_manager != null:
		_cooking_manager.remove_state(block_pos)
	if survival:
		var dropped_item_id: int = _resolve_drop_for_network_break(old_block)
		if dropped_item_id != SSDItemDefs.ITEM_AIR:
			var drop_position: Vector3 = Vector3(block_pos.x + 0.5, block_pos.y + 0.55, block_pos.z + 0.5)
			var impulse: Vector3 = Vector3(randf_range(-1.2, 1.2), randf_range(1.8, 2.6), randf_range(-1.2, 1.2))
			_spawn_item_drop(dropped_item_id, 1, drop_position, impulse)
	if broadcast_change and multiplayer.multiplayer_peer != null:
		rpc("_rpc_apply_block_update", block_pos.x, block_pos.y, block_pos.z, SSDVoxelDefs.BlockId.AIR)
	return true

func _apply_block_place_authoritative(block_pos: Vector3i, item_id: int, broadcast_change: bool, facing_deg: float = 0.0) -> bool:
	if item_id == SSDVoxelDefs.BlockId.DISPLAY_CASE:
		var upper_block: int = world.get_block_global(block_pos.x, block_pos.y + 1, block_pos.z)
		if upper_block != SSDVoxelDefs.BlockId.AIR and not SSDVoxelDefs.is_fluid(upper_block):
			return false
	if not world.request_set_block_global(block_pos.x, block_pos.y, block_pos.z, item_id):
		return false
	_apply_oriented_block_state(block_pos, item_id, facing_deg)
	if broadcast_change and multiplayer.multiplayer_peer != null:
		rpc("_rpc_apply_block_update", block_pos.x, block_pos.y, block_pos.z, item_id)
		rpc("_rpc_apply_block_facing", block_pos.x, block_pos.y, block_pos.z, item_id, facing_deg)
	return true

func _resolve_drop_for_network_break(block_id: int) -> int:
	if SSDVoxelDefs.is_fluid(block_id):
		return SSDItemDefs.ITEM_AIR
	if block_id == SSDVoxelDefs.BlockId.STONE:
		return SSDItemDefs.ITEM_COBBLESTONE
	if block_id == SSDVoxelDefs.BlockId.COAL_ORE:
		return SSDItemDefs.ITEM_COAL
	if block_id == SSDVoxelDefs.BlockId.IRON_ORE:
		return SSDItemDefs.ITEM_IRON_CHUNK
	return block_id

@rpc("authority", "call_remote", "reliable")
func _rpc_receive_world_sync(world_seed_value: int, time_hours: float, mode_name: String) -> void:
	world.world_seed = world_seed_value
	world.regenerate()
	var safe_spawn: Vector3 = world.prime_spawn_area(player.global_position, 2)
	player.global_position = safe_spawn
	player.reset_motion()
	world.set_target(player)
	player.set_world(world)
	if _day_night != null:
		_day_night.set_time_hours(time_hours)
	if _game_mode != null:
		_game_mode.set_mode_by_name(mode_name)
	player.set_controls_enabled(true)
	if _chat_ui != null:
		_chat_ui.add_system_message("Connected to host world '%s'." % SSDCore.get_current_world_name())

@rpc("any_peer", "call_remote", "reliable")
func _rpc_register_player(player_name_value: String, profile: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_peer_names[sender_id] = player_name_value
	_peer_profiles[sender_id] = profile.duplicate(true)
	_spawn_or_update_remote_player(sender_id, profile, player.global_position + Vector3(1.5, 0.0, 1.5), 0.0, 0.0, SSDItemDefs.ITEM_AIR)
	rpc_id(sender_id, "_rpc_spawn_remote_peer", 1, str(_peer_names.get(1, _network_player_name)), _peer_profiles.get(1, SSDCore.get_current_world_profile()))
	rpc_id(sender_id, "_rpc_receive_player_state", 1, player.global_position, player.get_body_yaw_radians(), player.get_pitch_radians(), _inventory.get_selected_block_id())
	for peer_variant in _peer_names.keys():
		var peer_id: int = int(peer_variant)
		if peer_id == 1 or peer_id == sender_id:
			continue
		rpc_id(sender_id, "_rpc_spawn_remote_peer", peer_id, str(_peer_names.get(peer_id, "Player")), _peer_profiles.get(peer_id, {}))
		if _peer_states.has(peer_id):
			var state: Dictionary = _peer_states.get(peer_id, {})
			rpc_id(sender_id, "_rpc_receive_player_state", peer_id, state.get("position", Vector3.ZERO), float(state.get("yaw", 0.0)), float(state.get("pitch", 0.0)), int(state.get("held_item_id", SSDItemDefs.ITEM_AIR)))
	rpc("_rpc_spawn_remote_peer", sender_id, player_name_value, profile)
	if _chat_ui != null:
		_chat_ui.add_system_message("%s joined the game." % player_name_value)

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_remote_peer(peer_id: int, player_name_value: String, profile: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	_peer_names[peer_id] = player_name_value
	_peer_profiles[peer_id] = profile.duplicate(true)
	_spawn_or_update_remote_player(peer_id, profile, player.global_position + Vector3(1.5, 0.0, 1.5), 0.0, 0.0, SSDItemDefs.ITEM_AIR)
	if _chat_ui != null:
		_chat_ui.add_system_message("%s joined the game." % player_name_value)

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_submit_player_state(world_position: Vector3, yaw: float, pitch: float, held_item_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_peer_states[sender_id] = {
		"position": world_position,
		"yaw": yaw,
		"pitch": pitch,
		"held_item_id": held_item_id,
	}
	_spawn_or_update_remote_player(sender_id, _peer_profiles.get(sender_id, {}), world_position, yaw, pitch, held_item_id)
	rpc("_rpc_receive_player_state", sender_id, world_position, yaw, pitch, held_item_id)

@rpc("authority", "call_remote", "unreliable")
func _rpc_receive_player_state(peer_id: int, world_position: Vector3, yaw: float, pitch: float, held_item_id: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	_spawn_or_update_remote_player(peer_id, _peer_profiles.get(peer_id, {}), world_position, yaw, pitch, held_item_id)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_chat(message: String, sender_position: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var sender_name: String = str(_peer_names.get(sender_id, "Player"))
	_broadcast_chat_message(sender_name, message, sender_position)
	rpc("_rpc_receive_chat", sender_name, message, sender_position)

@rpc("authority", "call_remote", "reliable")
func _rpc_receive_chat(sender_name: String, message: String, sender_position: Vector3) -> void:
	_broadcast_chat_message(sender_name, message, sender_position)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_break_block(block_x: int, block_y: int, block_z: int, old_block: int, survival: bool) -> void:
	if not multiplayer.is_server():
		return
	var current_block: int = world.get_block_global(block_x, block_y, block_z)
	if current_block == SSDVoxelDefs.BlockId.AIR:
		return
	_apply_block_break_authoritative(Vector3i(block_x, block_y, block_z), current_block if current_block != SSDVoxelDefs.BlockId.AIR else old_block, survival, true)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_place_block(block_x: int, block_y: int, block_z: int, item_id: int, facing_deg: float = 0.0) -> void:
	if not multiplayer.is_server():
		return
	_apply_block_place_authoritative(Vector3i(block_x, block_y, block_z), item_id, true, facing_deg)

@rpc("authority", "call_remote", "reliable")
func _rpc_apply_block_update(block_x: int, block_y: int, block_z: int, block_id: int) -> void:
	world.request_set_block_global(block_x, block_y, block_z, block_id)


@rpc("authority", "call_remote", "reliable")
func _rpc_apply_block_facing(block_x: int, block_y: int, block_z: int, item_id: int, facing_deg: float) -> void:
	_apply_oriented_block_state(Vector3i(block_x, block_y, block_z), item_id, facing_deg)

func _apply_oriented_block_state(block_pos: Vector3i, item_id: int, facing_deg: float) -> void:
	if item_id == SSDVoxelDefs.BlockId.DISPLAY_CASE and _display_case_manager != null:
		_display_case_manager.ensure_visual(block_pos)
		_display_case_manager.set_block_facing(block_pos, facing_deg)
		return
	var station_type: String = SSDCooking.get_station_type_for_block(item_id)
	if _cooking_manager != null and (station_type == SSDCooking.STATION_STOVE or station_type == SSDCooking.STATION_OVEN):
		_cooking_manager.set_block_facing(block_pos, station_type, facing_deg)


@rpc("authority", "call_remote", "reliable")
func _rpc_apply_time_sync(hours: float) -> void:
	if _day_night != null:
		_day_night.set_time_hours(hours)

func _broadcast_chat_message(sender_name: String, message: String, sender_position: Vector3) -> void:
	if _chat_ui == null:
		return
	_chat_ui.receive_message(sender_name, message, sender_position, player.global_position)

func _handle_chat_command(command_text: String) -> void:
	var parts: PackedStringArray = command_text.substr(1).split(" ", false)
	if parts.is_empty():
		return

	var root: String = parts[0].to_lower()
	match root:
		"gm", "gamemode":
			if parts.size() < 2:
				_chat_ui.add_system_message("Usage: /gm survival or /gm creative")
			else:
				_game_mode.set_mode_by_name(parts[1])
		"help":
			_chat_ui.add_system_message("/gm survival|creative | /time set day|noon|night|midnight|HH:MM")
			_chat_ui.add_system_message("/tp x y z | /give SSD:grass 64 | /give SSD:furnace 1 | /give SSD:raw_beef 4 | /summon sheep")
			_chat_ui.add_system_message("/schem pos1|pos2|save name|load name|preview|commit|rotate 90|list|info|clear | /clear | /rd value | /cropgrow value [ticks]")
		"time":
			_handle_time_command(parts)
		"tp":
			_handle_tp_command(parts)
		"give":
			_handle_give_command(parts)
		"summon":
			_handle_summon_command(parts)
		"clear":
			_clear_inventory_contents()
			_chat_ui.add_system_message("Inventory cleared.")
		"rd", "renderdistance":
			if parts.size() < 2:
				_chat_ui.add_system_message("Usage: /rd 2-20")
			else:
				var new_distance: int = clampi(int(parts[1].to_int()), 2, 32)
				if world.has_method("apply_render_distance"):
					world.apply_render_distance(new_distance)
				else:
					world.load_radius = new_distance
					world.collision_radius = max(1, new_distance - 1)
				world.set_target(player)
				player.set_world(world)
				_chat_ui.add_system_message("Render distance set to %d." % new_distance)
		"schem", "schematic":
			_handle_schematic_command(parts)
		"cropgrow", "cropgrowth":
			_handle_crop_grow_command(parts)
		_:
			_chat_ui.add_system_message("Unknown command: %s" % root)

func _handle_time_command(parts: PackedStringArray) -> void:
	if _day_night == null:
		return
	if parts.size() < 3 or parts[1].to_lower() != "set":
		_chat_ui.add_system_message("Usage: /time set day|noon|night|midnight|HH:MM")
		return
	var value: String = parts[2].to_lower()
	var hour: float = 12.0
	match value:
		"day":
			hour = 9.0
		"noon":
			hour = 12.0
		"sunrise", "morning":
			hour = 5.0
		"sunset", "evening":
			hour = 19.0
		"night":
			hour = 21.0
		"midnight":
			hour = 0.0
		_:
			if value.contains(":"):
				var split: PackedStringArray = value.split(":")
				if split.size() == 2:
					hour = clampf(float(split[0].to_int()) + (float(split[1].to_int()) / 60.0), 0.0, 23.99)
				else:
					_chat_ui.add_system_message("Invalid time. Try 06:30 or 18:45.")
					return
			else:
				_chat_ui.add_system_message("Usage: /time set day|noon|night|midnight|HH:MM")
				return
	_day_night.set_time_hours(hour)
	if _is_multiplayer_host():
		rpc("_rpc_apply_time_sync", hour)
	_chat_ui.add_system_message("Time set to %s." % _day_night.get_formatted_time())

func _handle_tp_command(parts: PackedStringArray) -> void:
	if parts.size() < 4:
		_chat_ui.add_system_message("Usage: /tp x y z")
		return
	var x: float = float(parts[1].to_float())
	var y: float = float(parts[2].to_float())
	var z: float = float(parts[3].to_float())
	player.global_position = Vector3(x, y, z)
	player.reset_motion()
	world.set_target(player)
	player.set_world(world)
	_chat_ui.add_system_message("Teleported to %.1f %.1f %.1f." % [x, y, z])

func _handle_give_command(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_chat_ui.add_system_message("Usage: /give item_id [count]")
		return
	var item_id: int = _resolve_item_name(parts[1])
	if item_id == SSDItemDefs.ITEM_AIR:
		_chat_ui.add_system_message("Unknown item: %s" % parts[1])
		return
	var count: int = 64 if parts.size() < 3 else clampi(int(parts[2].to_int()), 1, 999)
	var remaining: int = _inventory.add_items(item_id, count)
	_chat_ui.add_system_message("Given %d %s%s." % [count - remaining, SSDItemDefs.get_display_id(item_id), "" if remaining <= 0 else " (inventory full)"])

func _resolve_item_name(token: String) -> int:
	return SSDItemDefs.resolve_item_token(token)

func _handle_summon_command(parts: PackedStringArray) -> void:
	if _mob_spawner == null:
		_chat_ui.add_system_message("Mob spawner unavailable.")
		return
	if parts.size() < 2:
		_chat_ui.add_system_message("Usage: /summon sheep|cow|chicken [x y z]")
		return
	var mob_type: String = parts[1].to_lower()
	if mob_type != "sheep" and mob_type != "cow" and mob_type != "chicken":
		_chat_ui.add_system_message("Unknown mob: %s" % parts[1])
		return
	var spawn_position: Vector3 = player.global_position + (-player.global_basis.z * 2.0)
	spawn_position.y = player.global_position.y
	if parts.size() >= 5:
		spawn_position = Vector3(float(parts[2].to_float()), float(parts[3].to_float()), float(parts[4].to_float()))
	_spawn_mob_at(mob_type, spawn_position)
	_chat_ui.add_system_message("Summoned %s." % mob_type)


func _handle_crop_grow_command(parts: PackedStringArray) -> void:
	if world == null:
		return
	if parts.size() < 2:
		_chat_ui.add_system_message("Usage: /cropgrow multiplier [bonus_ticks]")
		return
	var multiplier: float = clampf(float(parts[1].to_float()), 0.0, 64.0)
	if world.has_method("set_crop_growth_speed_multiplier"):
		world.set_crop_growth_speed_multiplier(multiplier)
	var bonus_ticks: int = 0
	if parts.size() >= 3:
		bonus_ticks = max(0, int(parts[2].to_int()))
		if world.has_method("accelerate_crop_growth_ticks"):
			world.accelerate_crop_growth_ticks(bonus_ticks)
	_chat_ui.add_system_message("Crop growth speed set to x%.2f%s" % [multiplier, "" if bonus_ticks <= 0 else " with %d instant growth ticks." % bonus_ticks])

func _clear_inventory_contents() -> void:
	if _inventory == null:
		return
	for i: int in range(_inventory.get_slot_count()):
		_inventory.set_slot(i, SSDItemDefs.ITEM_AIR, 0)

func _on_game_mode_changed(_mode: int, mode_name: String) -> void:
	var creative_enabled: bool = mode_name == "creative"
	if player != null:
		player.set_flight_allowed(creative_enabled)
	if _vitals != null:
		_vitals.set_survival_enabled(not creative_enabled)
		if creative_enabled:
			_vitals.restore_full()
	if _chat_ui != null:
		_chat_ui.add_system_message("Gamemode set to %s" % mode_name.capitalize())
	if _inventory_ui != null:
		_inventory_ui.set_game_mode(_game_mode)
	if _hotbar != null:
		_hotbar.set_vitals(_vitals)


func _on_mob_spawned(mob: SSDPassiveMob) -> void:
	if mob == null:
		return
	if not mob.drop_requested.is_connected(_spawn_item_drop):
		mob.drop_requested.connect(_spawn_item_drop)

func _is_any_ui_open() -> bool:
	return (
		(_inventory_ui != null and _inventory_ui.is_open())
		or (_settings_menu != null and _settings_menu.is_open())
		or (_chat_ui != null and _chat_ui.is_open())
	)

func _soft_unstuck_player() -> void:
	if world == null or player == null:
		return

	var body_x: int = floori(player.global_position.x / SSDChunkConfig.VOXEL_SIZE)
	var body_z: int = floori(player.global_position.z / SSDChunkConfig.VOXEL_SIZE)
	var feet_y: int = floori((player.global_position.y + 0.05) / SSDChunkConfig.VOXEL_SIZE)
	var chest_y: int = floori((player.global_position.y + 0.90) / SSDChunkConfig.VOXEL_SIZE)
	var head_y: int = floori((player.global_position.y + 1.55) / SSDChunkConfig.VOXEL_SIZE)

	var feet_inside: bool = SSDVoxelDefs.is_solid(world.get_block_global(body_x, feet_y, body_z))
	var chest_inside: bool = SSDVoxelDefs.is_solid(world.get_block_global(body_x, chest_y, body_z))
	var head_inside: bool = SSDVoxelDefs.is_solid(world.get_block_global(body_x, head_y, body_z))

	if not chest_inside and not head_inside:
		return

	var inside_body: bool = feet_inside or chest_inside or head_inside
	for _i: int in range(10):
		player.global_position.y += 0.12
		feet_y = floori((player.global_position.y + 0.05) / SSDChunkConfig.VOXEL_SIZE)
		chest_y = floori((player.global_position.y + 0.90) / SSDChunkConfig.VOXEL_SIZE)
		head_y = floori((player.global_position.y + 1.55) / SSDChunkConfig.VOXEL_SIZE)
		feet_inside = SSDVoxelDefs.is_solid(world.get_block_global(body_x, feet_y, body_z))
		chest_inside = SSDVoxelDefs.is_solid(world.get_block_global(body_x, chest_y, body_z))
		head_inside = SSDVoxelDefs.is_solid(world.get_block_global(body_x, head_y, body_z))
		inside_body = feet_inside or chest_inside or head_inside
		if not inside_body:
			player.reset_motion()
			return


func _resolve_schematic_origin() -> Vector3i:
	if selector != null and selector.has_place_target():
		return selector.get_place_block()
	elif selector != null and selector.has_selection():
		return selector.get_selected_block() + Vector3i.UP
	return Vector3i(floori(player.global_position.x), floori(player.global_position.y), floori(player.global_position.z))

func _update_schematic_preview() -> void:
	if not _schematic_preview_active or _schematic_preview == null or _schematic_manager == null or not _schematic_manager.has_loaded_schematic():
		if _schematic_preview != null:
			_schematic_preview.clear_preview()
		return
	var origin: Vector3i = _resolve_schematic_origin()
	if origin != _schematic_preview_origin or not _schematic_preview.visible:
		_schematic_preview_origin = origin
		_schematic_preview.build_from_schematic(_schematic_manager.get_loaded_data(), origin)

func _set_schematic_preview_active(active: bool) -> void:
	_schematic_preview_active = active
	if not active and _schematic_preview != null:
		_schematic_preview.clear_preview()



func _handle_schematic_command(parts: PackedStringArray) -> void:
	if _schematic_manager == null:
		_chat_ui.add_system_message("Schematic manager unavailable.")
		return
	if parts.size() < 2:
		_chat_ui.add_system_message("Usage: /schem pos1|pos2|save name|load name|preview|commit|rotate 90|list|info|clear")
		return
	var sub: String = parts[1].to_lower()
	match sub:
		"pos1":
			if selector == null or not selector.has_selection():
				_chat_ui.add_system_message("Look at a block first, then run /schem pos1.")
				return
			var pos1: Vector3i = selector.get_selected_block()
			_schematic_manager.set_pos1(pos1)
			_chat_ui.add_system_message("Schematic pos1 set to %d %d %d." % [pos1.x, pos1.y, pos1.z])
		"pos2":
			if selector == null or not selector.has_selection():
				_chat_ui.add_system_message("Look at a block first, then run /schem pos2.")
				return
			var pos2: Vector3i = selector.get_selected_block()
			_schematic_manager.set_pos2(pos2)
			_chat_ui.add_system_message("Schematic pos2 set to %d %d %d." % [pos2.x, pos2.y, pos2.z])
		"save":
			if parts.size() < 3:
				_chat_ui.add_system_message("Usage: /schem save name")
				return
			var schem_name: String = parts[2]
			if not _schematic_manager.has_complete_selection():
				_chat_ui.add_system_message("Set /schem pos1 and /schem pos2 first.")
				return
			if _schematic_manager.save_selection(schem_name, false):
				var size: Vector3i = _schematic_manager.get_selection_bounds().get("size", Vector3i.ZERO)
				_chat_ui.add_system_message("Saved schematic '%s' (%dx%dx%d)." % [schem_name, size.x, size.y, size.z])
			else:
				_chat_ui.add_system_message("Failed to save schematic '%s'." % schem_name)
		"load":
			if parts.size() < 3:
				_chat_ui.add_system_message("Usage: /schem load name")
				return
			var load_name: String = parts[2]
			if _schematic_manager.load_schematic(load_name):
				var load_size: Vector3i = _schematic_manager.get_loaded_size()
				_set_schematic_preview_active(false)
				_chat_ui.add_system_message("Loaded schematic '%s' (%dx%dx%d)." % [load_name, load_size.x, load_size.y, load_size.z])
			else:
				_chat_ui.add_system_message("Could not load schematic '%s'." % load_name)
		"preview":
			if not _schematic_manager.has_loaded_schematic():
				_chat_ui.add_system_message("Load a schematic first with /schem load name.")
				return
			_schematic_preview_origin = _resolve_schematic_origin()
			_set_schematic_preview_active(true)
			_schematic_preview.build_from_schematic(_schematic_manager.get_loaded_data(), _schematic_preview_origin)
			_chat_ui.add_system_message("Previewing '%s'. Use /schem commit to finalize." % _schematic_manager.get_loaded_name())
		"commit", "paste":
			if not _schematic_manager.has_loaded_schematic():
				_chat_ui.add_system_message("Load a schematic first with /schem load name.")
				return
			var origin: Vector3i = _schematic_preview_origin if _schematic_preview_active else _resolve_schematic_origin()
			var placed: int = _schematic_manager.paste_loaded(origin, false)
			_set_schematic_preview_active(false)
			_chat_ui.add_system_message("Placed '%s' (%d blocks)." % [_schematic_manager.get_loaded_name(), placed])
		"rotate":
			if parts.size() < 3:
				_chat_ui.add_system_message("Usage: /schem rotate 90|180|270")
				return
			if not _schematic_manager.has_loaded_schematic():
				_chat_ui.add_system_message("Load a schematic first with /schem load name.")
				return
			var degrees: int = int(parts[2].to_int())
			var steps: int = 0
			match degrees:
				90:
					steps = 1
				180:
					steps = 2
				270:
					steps = 3
				_:
					_chat_ui.add_system_message("Rotation must be 90, 180, or 270.")
					return
			_schematic_manager.rotate_loaded_y(steps)
			var rot_size: Vector3i = _schematic_manager.get_loaded_size()
			if _schematic_preview_active:
				_schematic_preview.build_from_schematic(_schematic_manager.get_loaded_data(), _schematic_preview_origin)
			_chat_ui.add_system_message("Rotated '%s' to %d° (%dx%dx%d)." % [_schematic_manager.get_loaded_name(), degrees, rot_size.x, rot_size.y, rot_size.z])
		"list":
			var names: PackedStringArray = _schematic_manager.list_schematics()
			if names.is_empty():
				_chat_ui.add_system_message("No schematics saved yet.")
			else:
				_chat_ui.add_system_message("Schematics: %s" % ", ".join(names))
		"info":
			if _schematic_manager.has_loaded_schematic():
				var info_size: Vector3i = _schematic_manager.get_loaded_size()
				_chat_ui.add_system_message("Loaded: %s (%dx%dx%d)." % [_schematic_manager.get_loaded_name(), info_size.x, info_size.y, info_size.z])
			else:
				_chat_ui.add_system_message("No schematic loaded.")
			if _schematic_manager.has_complete_selection():
				var bounds: Dictionary = _schematic_manager.get_selection_bounds()
				var min_pos: Vector3i = bounds.get("min", Vector3i.ZERO)
				var max_pos: Vector3i = bounds.get("max", Vector3i.ZERO)
				var sel_size: Vector3i = bounds.get("size", Vector3i.ZERO)
				_chat_ui.add_system_message("Selection: %d %d %d -> %d %d %d (%dx%dx%d)." % [min_pos.x, min_pos.y, min_pos.z, max_pos.x, max_pos.y, max_pos.z, sel_size.x, sel_size.y, sel_size.z])
		"clear":
			_schematic_manager.clear_selection()
			_set_schematic_preview_active(false)
			_chat_ui.add_system_message("Schematic selection cleared.")
		_:
			_chat_ui.add_system_message("Usage: /schem pos1|pos2|save name|load name|preview|commit|rotate 90|list|info|clear")
