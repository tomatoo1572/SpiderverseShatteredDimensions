extends Node

const WORLDS_PATH: String = "user://ssd_worlds.json"
const DEFAULT_WORLD_NAME: String = "New World"

enum NetworkMode {
	OFFLINE,
	HOST,
	CLIENT,
}

const DEFAULT_PLAYER_NAME: String = "Player"
const DEFAULT_SERVER_PORT: int = 24500

var _worlds: Array[Dictionary] = []
var _current_world: Dictionary = {
	"id": "default",
	"name": DEFAULT_WORLD_NAME,
	"seed": 1337,
}
const DEFAULT_PROFILE: Dictionary = {
	"skin_tone": "d3af92",
	"body_type_index": 0,
	"health_bonus": 0.0,
	"stamina_bonus": 0.0,
	"stamina_training_drains": 0,
	"stamina_training_goal": 3,
}

var _player_profile: Dictionary = DEFAULT_PROFILE.duplicate(true)

var _network_session: Dictionary = {
	"mode": NetworkMode.OFFLINE,
	"address": "127.0.0.1",
	"port": DEFAULT_SERVER_PORT,
	"player_name": DEFAULT_PLAYER_NAME,
}

func _ready() -> void:
	randomize()
	_register_default_actions()
	_load_worlds()

func _register_default_actions() -> void:
	_ensure_exact_key_action("move_forward", KEY_W)
	_ensure_exact_key_action("move_backward", KEY_S)
	_ensure_exact_key_action("move_left", KEY_A)
	_ensure_exact_key_action("move_right", KEY_D)
	_ensure_exact_key_action("jump", KEY_SPACE)
	_ensure_exact_key_action("crouch", KEY_CTRL)
	_ensure_exact_key_action("sprint", KEY_SHIFT)
	_ensure_exact_key_action("toggle_menu", KEY_ESCAPE)
	_ensure_exact_key_action("toggle_flight", KEY_F)
	_clear_action_events("regenerate_world")
	_ensure_exact_key_action("toggle_inventory", KEY_E)
	_ensure_exact_key_action("drop_one", KEY_Q)
	_ensure_exact_key_action("toggle_chat", KEY_T)
	_ensure_exact_key_action("toggle_gamemode", KEY_G)
	_ensure_exact_key_action("toggle_camera_mode", KEY_F3)
	_ensure_exact_key_action("camera_freelook", KEY_ALT)

	_ensure_mouse_button_action("break_block", MOUSE_BUTTON_LEFT)
	_ensure_mouse_button_action("place_block", MOUSE_BUTTON_RIGHT)
	_ensure_mouse_button_action("pick_block", MOUSE_BUTTON_MIDDLE)
	_ensure_mouse_button_action("hotbar_prev", MOUSE_BUTTON_WHEEL_UP)
	_ensure_mouse_button_action("hotbar_next", MOUSE_BUTTON_WHEEL_DOWN)

	_ensure_exact_key_action("hotbar_1", KEY_1)
	_ensure_exact_key_action("hotbar_2", KEY_2)
	_ensure_exact_key_action("hotbar_3", KEY_3)
	_ensure_exact_key_action("hotbar_4", KEY_4)
	_ensure_exact_key_action("hotbar_5", KEY_5)
	_ensure_exact_key_action("hotbar_6", KEY_6)
	_ensure_exact_key_action("hotbar_7", KEY_7)
	_ensure_exact_key_action("hotbar_8", KEY_8)
	_ensure_exact_key_action("hotbar_9", KEY_9)

func _ensure_action(action_name: String, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, deadzone)

func _ensure_exact_key_action(action_name: String, keycode: int) -> void:
	_ensure_action(action_name)

	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			InputMap.action_erase_event(action_name, event)

	var input_event: InputEventKey = InputEventKey.new()
	input_event.physical_keycode = keycode as Key
	input_event.keycode = keycode as Key
	InputMap.action_add_event(action_name, input_event)

func _ensure_mouse_button_action(action_name: String, button_index: MouseButton) -> void:
	_ensure_action(action_name)

	if _action_has_mouse_button(action_name, button_index):
		return

	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

func _action_has_mouse_button(action_name: String, button_index: MouseButton) -> bool:
	var events: Array[InputEvent] = InputMap.action_get_events(action_name)
	for event: InputEvent in events:
		if event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_event.button_index == button_index:
				return true
	return false


func _clear_action_events(action_name: String) -> void:
	_ensure_action(action_name)
	for event: InputEvent in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, event)

func rebind_action_to_key(action_name: String, keycode: int) -> void:
	_ensure_exact_key_action(action_name, keycode)

func get_action_binding_text(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return "Unbound"
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			if key_event.physical_keycode != KEY_NONE:
				return OS.get_keycode_string(key_event.physical_keycode)
			if key_event.keycode != KEY_NONE:
				return OS.get_keycode_string(key_event.keycode)
	return "Unbound"

func get_worlds() -> Array[Dictionary]:
	return _worlds.duplicate(true)

func get_current_world() -> Dictionary:
	return _current_world.duplicate(true)

func get_current_world_seed() -> int:
	return int(_current_world.get("seed", 1337))

func get_current_world_name() -> String:
	return str(_current_world.get("name", DEFAULT_WORLD_NAME))


func generate_random_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(0, 2147483647)

func create_world(world_name: String, seed_text: String) -> Dictionary:
	var clean_name: String = world_name.strip_edges()
	if clean_name.is_empty():
		clean_name = DEFAULT_WORLD_NAME

	var world_seed: int = 0
	if seed_text.strip_edges().is_empty():
		world_seed = generate_random_seed()
	elif seed_text.is_valid_int():
		world_seed = int(seed_text.to_int())
	else:
		world_seed = int(hash(seed_text))

	var world_id: String = _slugify(clean_name)
	var suffix: int = 2
	while _world_index_by_id(world_id) >= 0:
		world_id = "%s_%d" % [_slugify(clean_name), suffix]
		suffix += 1

	var world_entry: Dictionary = {
		"id": world_id,
		"name": clean_name,
		"seed": world_seed,
		"profile": DEFAULT_PROFILE.duplicate(true),
	}
	_worlds.append(world_entry)
	_save_worlds()
	return world_entry.duplicate(true)

func delete_world_by_id(world_id: String) -> void:
	var index: int = _world_index_by_id(world_id)
	if index < 0:
		return
	_worlds.remove_at(index)
	if str(_current_world.get("id", "")) == world_id:
		if _worlds.is_empty():
			_current_world = {"id": "default", "name": DEFAULT_WORLD_NAME, "seed": 1337}
		else:
			_current_world = _worlds[0].duplicate(true)
	_save_worlds()

func set_current_world_by_id(world_id: String) -> void:
	var index: int = _world_index_by_id(world_id)
	if index < 0:
		return
	_current_world = _worlds[index].duplicate(true)
	_player_profile = _get_world_profile(_current_world)
	_save_worlds()

func set_current_world(world_data: Dictionary) -> void:
	_current_world = world_data.duplicate(true)
	_player_profile = _get_world_profile(_current_world)
	_save_worlds()

func get_player_profile() -> Dictionary:
	return _player_profile.duplicate(true)

func get_current_world_profile() -> Dictionary:
	return _get_world_profile(_current_world)

func set_player_profile(profile: Dictionary) -> void:
	set_current_world_profile(profile)

func set_current_world_profile(profile: Dictionary) -> void:
	var merged: Dictionary = DEFAULT_PROFILE.duplicate(true)
	merged["skin_tone"] = str(profile.get("skin_tone", merged["skin_tone"]))
	merged["body_type_index"] = clampi(int(profile.get("body_type_index", merged["body_type_index"])), 0, 3)
	merged["health_bonus"] = maxf(0.0, float(profile.get("health_bonus", merged["health_bonus"])))
	merged["stamina_bonus"] = maxf(0.0, float(profile.get("stamina_bonus", merged["stamina_bonus"])))
	merged["stamina_training_drains"] = max(0, int(profile.get("stamina_training_drains", merged["stamina_training_drains"])))
	merged["stamina_training_goal"] = max(1, int(profile.get("stamina_training_goal", merged["stamina_training_goal"])))
	_player_profile = merged.duplicate(true)
	_current_world["profile"] = merged.duplicate(true)
	var index: int = _world_index_by_id(str(_current_world.get("id", "")))
	if index >= 0:
		_worlds[index]["profile"] = merged.duplicate(true)
	_save_worlds()


func adjust_current_world_attribute(attribute_name: String, amount: float) -> void:
	var profile: Dictionary = get_current_world_profile()
	match attribute_name:
		"health":
			profile["health_bonus"] = maxf(0.0, float(profile.get("health_bonus", 0.0)) + amount)
		"stamina":
			profile["stamina_bonus"] = maxf(0.0, float(profile.get("stamina_bonus", 0.0)) + amount)
		_:
			return
	set_current_world_profile(profile)

func get_player_skin_tone_color() -> Color:
	var profile: Dictionary = get_current_world_profile()
	var color_text: String = str(profile.get("skin_tone", "d3af92"))
	if color_text.begins_with("#"):
		color_text = color_text.substr(1)
	if color_text.length() != 6:
		color_text = "d3af92"
	return Color("#" + color_text)

func configure_offline_session(player_name: String = "") -> void:
	_network_session = {
		"mode": NetworkMode.OFFLINE,
		"address": "127.0.0.1",
		"port": DEFAULT_SERVER_PORT,
		"player_name": _sanitize_player_name(player_name),
	}

func configure_host_session(player_name: String = "", port: int = DEFAULT_SERVER_PORT) -> void:
	_network_session = {
		"mode": NetworkMode.HOST,
		"address": "0.0.0.0",
		"port": clampi(port, 1024, 65535),
		"player_name": _sanitize_player_name(player_name),
	}

func configure_join_session(address: String, player_name: String = "", port: int = DEFAULT_SERVER_PORT) -> void:
	var clean_address: String = address.strip_edges()
	if clean_address.is_empty():
		clean_address = "127.0.0.1"
	_network_session = {
		"mode": NetworkMode.CLIENT,
		"address": clean_address,
		"port": clampi(port, 1024, 65535),
		"player_name": _sanitize_player_name(player_name),
	}

func get_network_session() -> Dictionary:
	var result: Dictionary = _network_session.duplicate(true)
	result["player_name"] = _sanitize_player_name(str(result.get("player_name", DEFAULT_PLAYER_NAME)))
	result["port"] = clampi(int(result.get("port", DEFAULT_SERVER_PORT)), 1024, 65535)
	return result

func get_network_mode() -> int:
	return int(_network_session.get("mode", NetworkMode.OFFLINE))

func get_network_player_name() -> String:
	return _sanitize_player_name(str(_network_session.get("player_name", DEFAULT_PLAYER_NAME)))

func get_network_port() -> int:
	return clampi(int(_network_session.get("port", DEFAULT_SERVER_PORT)), 1024, 65535)

func get_network_address() -> String:
	return str(_network_session.get("address", "127.0.0.1"))

func _sanitize_player_name(value: String) -> String:
	var clean: String = value.strip_edges()
	if clean.is_empty():
		clean = DEFAULT_PLAYER_NAME
	if clean.length() > 20:
		clean = clean.substr(0, 20)
	return clean

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _load_worlds() -> void:
	if not FileAccess.file_exists(WORLDS_PATH):
		_worlds = [{"id": "default", "name": DEFAULT_WORLD_NAME, "seed": 1337, "profile": DEFAULT_PROFILE.duplicate(true)}]
		_current_world = _worlds[0].duplicate(true)
		_player_profile = _get_world_profile(_current_world)
		_save_worlds()
		return

	var file: FileAccess = FileAccess.open(WORLDS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		_worlds.clear()
		for entry_variant: Variant in parsed:
			if entry_variant is Dictionary:
				var entry: Dictionary = entry_variant
				if entry.has("id") and entry.has("name") and entry.has("seed"):
					_worlds.append({
						"id": str(entry["id"]),
						"name": str(entry["name"]),
						"seed": int(entry["seed"]),
						"profile": _sanitize_profile(entry.get("profile", DEFAULT_PROFILE.duplicate(true))),
					})
	if _worlds.is_empty():
		_worlds = [{"id": "default", "name": DEFAULT_WORLD_NAME, "seed": 1337, "profile": DEFAULT_PROFILE.duplicate(true)}]
	_current_world = _worlds[0].duplicate(true)
	_player_profile = _get_world_profile(_current_world)

func _save_worlds() -> void:
	var file: FileAccess = FileAccess.open(WORLDS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_worlds, "  "))

func _sanitize_profile(value: Variant) -> Dictionary:
	if value is Dictionary:
		var incoming: Dictionary = value
		var result: Dictionary = DEFAULT_PROFILE.duplicate(true)
		result["skin_tone"] = str(incoming.get("skin_tone", result["skin_tone"]))
		result["body_type_index"] = clampi(int(incoming.get("body_type_index", result["body_type_index"])), 0, 3)
		result["health_bonus"] = maxf(0.0, float(incoming.get("health_bonus", result["health_bonus"])))
		result["stamina_bonus"] = maxf(0.0, float(incoming.get("stamina_bonus", result["stamina_bonus"])))
		result["stamina_training_drains"] = max(0, int(incoming.get("stamina_training_drains", result["stamina_training_drains"])))
		result["stamina_training_goal"] = max(1, int(incoming.get("stamina_training_goal", result["stamina_training_goal"])))
		return result
	return DEFAULT_PROFILE.duplicate(true)

func _get_world_profile(world_data: Dictionary) -> Dictionary:
	return _sanitize_profile(world_data.get("profile", DEFAULT_PROFILE.duplicate(true)))

func _world_index_by_id(world_id: String) -> int:
	for i: int in range(_worlds.size()):
		if str(_worlds[i].get("id", "")) == world_id:
			return i
	return -1

func _slugify(value: String) -> String:
	var lowered: String = value.to_lower().strip_edges()
	lowered = lowered.replace(" ", "_")
	var output: String = ""
	for i: int in range(lowered.length()):
		var ch: String = lowered.substr(i, 1)
		var code: int = ch.unicode_at(0)
		if (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or ch == "_":
			output += ch
	if output.is_empty():
		output = "world"
	return output
