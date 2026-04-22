extends RefCounted
class_name SSDCookingState

const MAX_STACK: int = 64

var station_type: String = SSDCooking.STATION_STOVE
var input_item_id: int = SSDItemDefs.ITEM_AIR
var input_count: int = 0
var input_secondary_item_id: int = SSDItemDefs.ITEM_AIR
var input_secondary_count: int = 0
var fuel_item_id: int = SSDItemDefs.ITEM_AIR
var fuel_count: int = 0
var output_item_id: int = SSDItemDefs.ITEM_AIR
var output_count: int = 0
var burn_time: float = 0.0
var burn_total: float = 0.0
var cook_time: float = 0.0
var cook_total: float = 8.0
var appliance_on: bool = false
var heat_ratio: float = 0.0
var facing_degrees: float = 0.0

func configure(new_station_type: String) -> void:
	station_type = new_station_type
	if station_type != SSDCooking.STATION_STOVE and station_type != SSDCooking.STATION_OVEN:
		appliance_on = false
		if station_type != SSDCooking.STATION_OVEN:
			heat_ratio = 0.0
			burn_time = 0.0
			burn_total = 0.0

func tick(delta: float) -> void:
	match station_type:
		SSDCooking.STATION_OVEN:
			_tick_oven(delta)
		SSDCooking.STATION_STOVE:
			_tick_stove(delta)
		_:
			_tick_simple(delta)

func _tick_simple(delta: float) -> void:
	var recipe: Dictionary = SSDCooking.get_recipe(station_type, input_item_id, fuel_item_id)
	var result_id: int = int(recipe.get("item_id", SSDItemDefs.ITEM_AIR))
	var result_count: int = int(recipe.get("count", 0))
	cook_total = float(recipe.get("cook_time", 0.0))
	var can_process: bool = _can_accept_output(result_id, result_count) and input_count > 0 and result_id != SSDItemDefs.ITEM_AIR
	if can_process:
		cook_time += delta
		if cook_time >= maxf(cook_total, 0.05):
			cook_time = 0.0
			_finish_recipe(recipe)
	else:
		cook_time = 0.0
	burn_total = 0.0
	burn_time = 0.0

func _tick_oven(delta: float) -> void:
	var recipe: Dictionary = SSDCooking.get_recipe(station_type, input_item_id, SSDItemDefs.ITEM_AIR)
	var result_id: int = int(recipe.get("item_id", SSDItemDefs.ITEM_AIR))
	var result_count: int = int(recipe.get("count", 0))
	cook_total = float(recipe.get("cook_time", 0.0))
	var can_process: bool = _can_accept_output(result_id, result_count) and input_count > 0 and result_id != SSDItemDefs.ITEM_AIR
	if burn_time > 0.0:
		burn_time = maxf(0.0, burn_time - delta)
	if can_process and burn_time <= 0.0 and fuel_count > 0 and SSDCooking.is_fuel_item(fuel_item_id):
		_consume_oven_fuel()
	if can_process and burn_time > 0.0:
		cook_time += delta
		if cook_time >= maxf(cook_total, 0.05):
			cook_time = 0.0
			_finish_recipe(recipe)
	else:
		if not can_process:
			cook_time = 0.0
	heat_ratio = 0.0 if burn_total <= 0.0 else clampf(burn_time / burn_total, 0.0, 1.0)

func _consume_oven_fuel() -> void:
	var total: float = SSDCooking.get_fuel_burn_time(fuel_item_id)
	if total <= 0.0 or fuel_count <= 0:
		return
	fuel_count -= 1
	if fuel_count <= 0:
		fuel_count = 0
		fuel_item_id = SSDItemDefs.ITEM_AIR
	burn_total = total
	burn_time = total

func _tick_stove(delta: float) -> void:
	if appliance_on:
		heat_ratio = minf(1.0, heat_ratio + (delta * 0.85))
	else:
		heat_ratio = maxf(0.0, heat_ratio - (delta * 0.7))
	burn_total = 1.0
	burn_time = heat_ratio
	var recipe: Dictionary = SSDCooking.get_stove_recipe(input_item_id, input_secondary_item_id, fuel_item_id)
	var result_id: int = int(recipe.get("item_id", SSDItemDefs.ITEM_AIR))
	var result_count: int = int(recipe.get("count", 0))
	cook_total = float(recipe.get("cook_time", 0.0))
	var can_process: bool = appliance_on and heat_ratio >= 0.25 and _can_accept_output(result_id, result_count) and input_count > 0 and result_id != SSDItemDefs.ITEM_AIR and SSDCooking.is_stove_cookware(fuel_item_id)
	if can_process:
		var heat_speed: float = lerpf(0.45, 1.0, heat_ratio)
		cook_time += delta * heat_speed
		if cook_time >= maxf(cook_total, 0.05):
			cook_time = 0.0
			_finish_recipe(recipe)
	else:
		cook_time = maxf(0.0, cook_time - (delta * 0.35))

func _can_accept_output(result_id: int, result_count: int) -> bool:
	if result_id == SSDItemDefs.ITEM_AIR or result_count <= 0:
		return false
	if output_count <= 0 or output_item_id == SSDItemDefs.ITEM_AIR:
		return true
	return output_item_id == result_id and output_count + result_count <= MAX_STACK

func _finish_recipe(recipe: Dictionary) -> void:
	var result_id: int = int(recipe.get("item_id", SSDItemDefs.ITEM_AIR))
	var result_count: int = int(recipe.get("count", 0))
	var input_consumed: int = max(0, int(recipe.get("input_consumed", 1)))
	var input_secondary_consumed: int = max(0, int(recipe.get("input_secondary_consumed", 0)))
	if input_consumed > 0:
		input_count -= input_consumed
		if input_count <= 0:
			input_count = 0
			input_item_id = SSDItemDefs.ITEM_AIR
	if input_secondary_consumed > 0:
		input_secondary_count -= input_secondary_consumed
		if input_secondary_count <= 0:
			input_secondary_count = 0
			input_secondary_item_id = SSDItemDefs.ITEM_AIR
	var consume_secondary: bool = bool(recipe.get("secondary_consumed", false))
	var secondary_return_item_id: int = int(recipe.get("secondary_return_item_id", SSDItemDefs.ITEM_AIR))
	if consume_secondary and fuel_count > 0:
		fuel_count -= 1
		if fuel_count <= 0:
			fuel_count = 0
			fuel_item_id = secondary_return_item_id
			if fuel_item_id != SSDItemDefs.ITEM_AIR:
				fuel_count = 1
	if output_count <= 0 or output_item_id == SSDItemDefs.ITEM_AIR:
		output_item_id = result_id
		output_count = result_count
	else:
		output_count += result_count

func has_cookware() -> bool:
	return station_type == SSDCooking.STATION_STOVE and SSDCooking.is_stove_cookware(fuel_item_id) and fuel_count > 0

func get_cookware_item_id() -> int:
	return fuel_item_id if has_cookware() else SSDItemDefs.ITEM_AIR

func can_place_stove_cookware(item_id: int) -> bool:
	return station_type == SSDCooking.STATION_STOVE and not has_cookware() and SSDCooking.is_stove_cookware(item_id) and input_item_id == SSDItemDefs.ITEM_AIR and input_secondary_item_id == SSDItemDefs.ITEM_AIR and output_item_id == SSDItemDefs.ITEM_AIR

func place_stove_cookware(item_id: int) -> bool:
	if not can_place_stove_cookware(item_id):
		return false
	fuel_item_id = item_id
	fuel_count = 1
	return true

func can_insert_stove_input(item_id: int) -> bool:
	if station_type != SSDCooking.STATION_STOVE:
		return false
	if not has_cookware() or item_id == SSDItemDefs.ITEM_AIR:
		return false
	if input_item_id == SSDItemDefs.ITEM_AIR:
		return SSDCooking.has_any_stove_recipe_for_primary(item_id, fuel_item_id)
	if input_secondary_item_id != SSDItemDefs.ITEM_AIR:
		return false
	var recipe: Dictionary = SSDCooking.get_stove_recipe(input_item_id, item_id, fuel_item_id)
	return int(recipe.get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR

func insert_stove_input(item_id: int) -> bool:
	if not can_insert_stove_input(item_id):
		return false
	if input_item_id == SSDItemDefs.ITEM_AIR:
		input_item_id = item_id
		input_count = 1
	else:
		input_secondary_item_id = item_id
		input_secondary_count = 1
	cook_time = 0.0
	return true


func can_insert_oven_input(item_id: int) -> bool:
	if station_type != SSDCooking.STATION_OVEN:
		return false
	if item_id == SSDItemDefs.ITEM_AIR or input_item_id != SSDItemDefs.ITEM_AIR:
		return false
	return int(SSDCooking.get_recipe(station_type, item_id, SSDItemDefs.ITEM_AIR).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR

func insert_oven_input(item_id: int) -> bool:
	if not can_insert_oven_input(item_id):
		return false
	input_item_id = item_id
	input_count = 1
	cook_time = 0.0
	return true

func can_insert_oven_fuel(item_id: int) -> bool:
	if station_type != SSDCooking.STATION_OVEN:
		return false
	if not SSDCooking.is_fuel_item(item_id):
		return false
	return fuel_item_id == SSDItemDefs.ITEM_AIR or fuel_item_id == item_id

func insert_oven_fuel(item_id: int) -> bool:
	if not can_insert_oven_fuel(item_id):
		return false
	if fuel_item_id == SSDItemDefs.ITEM_AIR:
		fuel_item_id = item_id
	fuel_count += 1
	return true

func take_fuel_stack() -> Dictionary:
	var result: Dictionary = {"item_id": fuel_item_id, "count": fuel_count}
	fuel_item_id = SSDItemDefs.ITEM_AIR
	fuel_count = 0
	burn_time = 0.0
	burn_total = 0.0
	return result

func take_output_stack() -> Dictionary:
	var result: Dictionary = {"item_id": output_item_id, "count": output_count}
	output_item_id = SSDItemDefs.ITEM_AIR
	output_count = 0
	return result

func take_input_stack() -> Dictionary:
	var result: Dictionary = {"item_id": input_item_id, "count": input_count}
	input_item_id = SSDItemDefs.ITEM_AIR
	input_count = 0
	cook_time = 0.0
	return result

func take_secondary_input_stack() -> Dictionary:
	var result: Dictionary = {"item_id": input_secondary_item_id, "count": input_secondary_count}
	input_secondary_item_id = SSDItemDefs.ITEM_AIR
	input_secondary_count = 0
	cook_time = 0.0
	return result

func take_stove_cookware() -> int:
	if station_type != SSDCooking.STATION_STOVE or not has_cookware() or input_item_id != SSDItemDefs.ITEM_AIR or input_secondary_item_id != SSDItemDefs.ITEM_AIR or output_item_id != SSDItemDefs.ITEM_AIR:
		return SSDItemDefs.ITEM_AIR
	var cookware_id: int = fuel_item_id
	fuel_item_id = SSDItemDefs.ITEM_AIR
	fuel_count = 0
	appliance_on = false
	return cookware_id

func can_place_input(item_id: int) -> bool:
	if station_type == SSDCooking.STATION_OVEN:
		return int(SSDCooking.get_recipe(station_type, item_id, SSDItemDefs.ITEM_AIR).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR
	if fuel_item_id != SSDItemDefs.ITEM_AIR:
		var recipe_with_secondary: Dictionary = SSDCooking.get_recipe(station_type, item_id, fuel_item_id)
		if int(recipe_with_secondary.get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
			return true
	return SSDCooking.has_any_recipe_for_input(station_type, item_id)

func can_place_fuel(item_id: int) -> bool:
	return can_place_secondary(item_id)

func can_place_secondary(item_id: int) -> bool:
	if station_type == SSDCooking.STATION_OVEN:
		return SSDCooking.is_fuel_item(item_id)
	if not SSDCooking.is_valid_secondary_for_station(station_type, item_id):
		return false
	if input_item_id == SSDItemDefs.ITEM_AIR:
		return true
	var recipe: Dictionary = SSDCooking.get_recipe(station_type, input_item_id, item_id)
	return int(recipe.get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR

func can_toggle_active() -> bool:
	return SSDCooking.station_has_toggle(station_type) or station_type == SSDCooking.STATION_OVEN

func toggle_active() -> void:
	if can_toggle_active():
		appliance_on = not appliance_on

func get_status_text() -> String:
	match station_type:
		SSDCooking.STATION_OVEN:
			if appliance_on:
				return "Oven door open"
			if input_item_id == SSDItemDefs.ITEM_AIR:
				return "Add food to the oven"
			if burn_time > 0.0:
				return "Oven hot"
			if fuel_count > 0 and SSDCooking.is_fuel_item(fuel_item_id):
				return "Ready to heat"
			return "Add coal or wood fuel"
		SSDCooking.STATION_STOVE:
			if fuel_item_id == SSDItemDefs.ITEM_AIR:
				return "Place a pan or pot on the stove"
			if output_count > 0:
				return "Dish ready to plate"
			if input_item_id == SSDItemDefs.ITEM_AIR:
				return "Add ingredient to the cookware"
			if input_secondary_item_id == SSDItemDefs.ITEM_AIR and SSDCooking.stove_accepts_second_ingredient(input_item_id, fuel_item_id):
				return "Add a second ingredient"
			if not appliance_on:
				return "Burner off"
			if heat_ratio < 0.25:
				return "Heating burner"
			return "Cooking on stove"
		SSDCooking.STATION_PREP:
			return "Prep ingredients by hand"
		SSDCooking.STATION_FERMENTER:
			return "Ferment slowly over time"
		SSDCooking.STATION_BLENDER:
			return "Blend fruit with liquid"
		_:
			return ""
