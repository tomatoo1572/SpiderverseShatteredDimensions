extends RefCounted
class_name SSDCooking

const STATION_PREP: String = "prep"
const STATION_STOVE: String = "stove"
const STATION_OVEN: String = "oven"
const STATION_FERMENTER: String = "fermenter"
const STATION_BLENDER: String = "blender"

static func get_station_type_for_block(block_id: int) -> String:
	match block_id:
		SSDVoxelDefs.BlockId.PREP_TABLE:
			return STATION_PREP
		SSDVoxelDefs.BlockId.STOVE:
			return STATION_STOVE
		SSDVoxelDefs.BlockId.OVEN:
			return STATION_OVEN
		SSDVoxelDefs.BlockId.FERMENTER:
			return STATION_FERMENTER
		SSDVoxelDefs.BlockId.BLENDER:
			return STATION_BLENDER
		_:
			return ""

static func get_station_display_name(station_type: String) -> String:
	match station_type:
		STATION_PREP:
			return "Prep Table"
		STATION_STOVE:
			return "Stove"
		STATION_OVEN:
			return "Oven"
		STATION_FERMENTER:
			return "Fermentation Jar"
		STATION_BLENDER:
			return "Blender"
		_:
			return "Cooking Station"

static func get_station_secondary_label(station_type: String) -> String:
	match station_type:
		STATION_PREP:
			return "Add-In"
		STATION_STOVE:
			return "Cookware"
		STATION_OVEN:
			return "Fuel"
		STATION_FERMENTER:
			return "Brine"
		STATION_BLENDER:
			return "Liquid"
		_:
			return "Fuel"

static func station_requires_fuel(station_type: String) -> bool:
	return station_type == STATION_OVEN

static func station_has_toggle(station_type: String) -> bool:
	return station_type == STATION_STOVE

static func get_station_toggle_label(station_type: String, active: bool) -> String:
	if station_type == STATION_STOVE:
		return "Burner: %s" % ("On" if active else "Off")
	return ""

static func station_shows_heat_meter(station_type: String) -> bool:
	return station_type == STATION_STOVE or station_type == STATION_OVEN

static func is_fuel_item(item_id: int) -> bool:
	return get_fuel_burn_time(item_id) > 0.0

static func get_fuel_burn_time(item_id: int) -> float:
	match item_id:
		SSDItemDefs.ITEM_COAL:
			return 28.0
		SSDItemDefs.ITEM_STICK:
			return 6.0
		SSDItemDefs.ITEM_OAK_PLANKS:
			return 12.0
		SSDItemDefs.ITEM_OAK_LOG:
			return 18.0
		_:
			return 0.0

static func is_stove_cookware(item_id: int) -> bool:
	return item_id == SSDItemDefs.ITEM_PAN or item_id == SSDItemDefs.ITEM_POT

static func _empty_recipe() -> Dictionary:
	return {
		"item_id": SSDItemDefs.ITEM_AIR,
		"count": 0,
		"cook_time": 0.0,
		"input_consumed": 1,
		"input_secondary_consumed": 0,
		"secondary_consumed": false,
		"secondary_return_item_id": SSDItemDefs.ITEM_AIR,
	}

static func _stove_recipe(item_id: int, count: int, cook_time: float, input_secondary_consumed: int = 0) -> Dictionary:
	return {
		"item_id": item_id,
		"count": count,
		"cook_time": cook_time,
		"input_consumed": 1,
		"input_secondary_consumed": input_secondary_consumed,
		"secondary_consumed": false,
		"secondary_return_item_id": SSDItemDefs.ITEM_AIR,
	}

static func _items_match_pair(a: int, b: int, expected_a: int, expected_b: int) -> bool:
	return (a == expected_a and b == expected_b) or (a == expected_b and b == expected_a)

static func get_stove_recipe(primary_item_id: int, secondary_input_item_id: int, cookware_item_id: int) -> Dictionary:
	if cookware_item_id == SSDItemDefs.ITEM_PAN:
		if primary_item_id == SSDItemDefs.ITEM_RAW_BEEF and secondary_input_item_id == SSDItemDefs.ITEM_AIR:
			return _stove_recipe(SSDItemDefs.ITEM_STEAK, 1, 7.5)
		if primary_item_id == SSDItemDefs.ITEM_RAW_CHICKEN and secondary_input_item_id == SSDItemDefs.ITEM_AIR:
			return _stove_recipe(SSDItemDefs.ITEM_COOKED_CHICKEN, 1, 7.0)
	elif cookware_item_id == SSDItemDefs.ITEM_POT:
		if primary_item_id == SSDItemDefs.ITEM_RICE and secondary_input_item_id == SSDItemDefs.ITEM_AIR:
			return _stove_recipe(SSDItemDefs.ITEM_COOKED_RICE, 1, 6.5)
		if primary_item_id == SSDItemDefs.ITEM_POTATO and secondary_input_item_id == SSDItemDefs.ITEM_AIR:
			return _stove_recipe(SSDItemDefs.ITEM_MASHED_POTATOES, 1, 8.0)
		if secondary_input_item_id != SSDItemDefs.ITEM_AIR:
			if _items_match_pair(primary_item_id, secondary_input_item_id, SSDItemDefs.ITEM_NOODLES, SSDItemDefs.ITEM_SHREDDED_CHEESE):
				return _stove_recipe(SSDItemDefs.ITEM_MAC_AND_CHEESE, 1, 9.5, 1)
			if _items_match_pair(primary_item_id, secondary_input_item_id, SSDItemDefs.ITEM_BROTH, SSDItemDefs.ITEM_NOODLES):
				return _stove_recipe(SSDItemDefs.ITEM_CHICKEN_NOODLE_SOUP, 1, 10.5, 1)
			if _items_match_pair(primary_item_id, secondary_input_item_id, SSDItemDefs.ITEM_BROTH, SSDItemDefs.ITEM_COOKED_BEEF):
				return _stove_recipe(SSDItemDefs.ITEM_PHO, 1, 11.0, 1)
			if _items_match_pair(primary_item_id, secondary_input_item_id, SSDItemDefs.ITEM_NOODLES, SSDItemDefs.ITEM_GROUND_BEEF):
				return _stove_recipe(SSDItemDefs.ITEM_DADS_SPAGHETTI, 1, 10.0, 1)
			if _items_match_pair(primary_item_id, secondary_input_item_id, SSDItemDefs.ITEM_NOODLES, SSDItemDefs.ITEM_COOKED_CHICKEN):
				return _stove_recipe(SSDItemDefs.ITEM_CHICKEN_ALFREDO, 1, 10.0, 1)
	return _empty_recipe()

static func stove_accepts_second_ingredient(primary_item_id: int, cookware_item_id: int) -> bool:
	if primary_item_id == SSDItemDefs.ITEM_AIR or not is_stove_cookware(cookware_item_id):
		return false
	for candidate: int in PackedInt32Array([SSDItemDefs.ITEM_NOODLES, SSDItemDefs.ITEM_SHREDDED_CHEESE, SSDItemDefs.ITEM_BROTH, SSDItemDefs.ITEM_COOKED_BEEF, SSDItemDefs.ITEM_GROUND_BEEF, SSDItemDefs.ITEM_COOKED_CHICKEN]):
		if int(get_stove_recipe(primary_item_id, candidate, cookware_item_id).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
			return true
	return false

static func has_any_stove_recipe_for_primary(primary_item_id: int, cookware_item_id: int) -> bool:
	if int(get_stove_recipe(primary_item_id, SSDItemDefs.ITEM_AIR, cookware_item_id).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
		return true
	return stove_accepts_second_ingredient(primary_item_id, cookware_item_id)

static func get_recipe(station_type: String, input_item_id: int, secondary_item_id: int = SSDItemDefs.ITEM_AIR) -> Dictionary:
	match station_type:
		STATION_PREP:
			if input_item_id == SSDItemDefs.ITEM_WHEAT and secondary_item_id == SSDItemDefs.ITEM_AIR:
				return {"item_id": SSDItemDefs.ITEM_FLOUR, "count": 1, "cook_time": 0.9, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_FLOUR and secondary_item_id == SSDItemDefs.ITEM_WATER_BOTTLE:
				return {"item_id": SSDItemDefs.ITEM_DOUGH, "count": 1, "cook_time": 1.2, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_GLASS_BOTTLE}
			if input_item_id == SSDItemDefs.ITEM_DOUGH and secondary_item_id == SSDItemDefs.ITEM_AIR:
				return {"item_id": SSDItemDefs.ITEM_NOODLES, "count": 1, "cook_time": 1.0, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_TOMATO and secondary_item_id == SSDItemDefs.ITEM_AIR:
				return {"item_id": SSDItemDefs.ITEM_SLICED_TOMATO, "count": 1, "cook_time": 0.9, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_CHEESE and secondary_item_id == SSDItemDefs.ITEM_AIR:
				return {"item_id": SSDItemDefs.ITEM_SHREDDED_CHEESE, "count": 1, "cook_time": 0.9, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_RAW_BEEF and secondary_item_id == SSDItemDefs.ITEM_AIR:
				return {"item_id": SSDItemDefs.ITEM_GROUND_BEEF, "count": 1, "cook_time": 1.1, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_DOUGH and secondary_item_id == SSDItemDefs.ITEM_SLICED_TOMATO:
				return {"item_id": SSDItemDefs.ITEM_PIZZA_BASE, "count": 1, "cook_time": 1.1, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_PIZZA_BASE and secondary_item_id == SSDItemDefs.ITEM_SHREDDED_CHEESE:
				return {"item_id": SSDItemDefs.ITEM_RAW_CHEESE_PIZZA, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_FLOUR and secondary_item_id == SSDItemDefs.ITEM_SHREDDED_CHEESE:
				return {"item_id": SSDItemDefs.ITEM_COOKIE_DOUGH, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_COOKED_RICE and secondary_item_id == SSDItemDefs.ITEM_COOKED_CHICKEN:
				return {"item_id": SSDItemDefs.ITEM_RICE_AND_CHICKEN, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_COOKED_CHICKEN and secondary_item_id == SSDItemDefs.ITEM_WATER_BOTTLE:
				return {"item_id": SSDItemDefs.ITEM_BROTH, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_GLASS_BOTTLE}
			if input_item_id == SSDItemDefs.ITEM_GROUND_BEEF and secondary_item_id == SSDItemDefs.ITEM_SLICED_TOMATO:
				return {"item_id": SSDItemDefs.ITEM_MEATLOAF_MIX, "count": 1, "cook_time": 1.2, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_RAW_CHEESE_PIZZA and secondary_item_id == SSDItemDefs.ITEM_GROUND_BEEF:
				return {"item_id": SSDItemDefs.ITEM_RAW_MEAT_LOVERS_PIZZA, "count": 1, "cook_time": 1.1, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_DOUGH and secondary_item_id == SSDItemDefs.ITEM_SHREDDED_CHEESE:
				return {"item_id": SSDItemDefs.ITEM_ITALIAN_CHEESE_BREAD_DOUGH, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_BREADSTICKS and secondary_item_id == SSDItemDefs.ITEM_COOKED_CHICKEN:
				return {"item_id": SSDItemDefs.ITEM_FOOTLONG_SANDWICH, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_CUCUMBER and secondary_item_id == SSDItemDefs.ITEM_CARROT:
				return {"item_id": SSDItemDefs.ITEM_SPRING_ROLLS, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_COOKIE_DOUGH and secondary_item_id == SSDItemDefs.ITEM_STRAWBERRY:
				return {"item_id": SSDItemDefs.ITEM_RED_VELVET_COOKIE_DOUGH, "count": 1, "cook_time": 1.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
		STATION_STOVE:
			return get_stove_recipe(input_item_id, SSDItemDefs.ITEM_AIR, secondary_item_id)
		STATION_OVEN:
			if input_item_id == SSDItemDefs.ITEM_POTATO:
				return {"item_id": SSDItemDefs.ITEM_BAKED_POTATO, "count": 1, "cook_time": 10.0, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_RAW_CHEESE_PIZZA:
				return {"item_id": SSDItemDefs.ITEM_CHEESE_PIZZA, "count": 1, "cook_time": 11.0, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_COOKIE_DOUGH:
				return {"item_id": SSDItemDefs.ITEM_CHOCOLATE_CHIP_COOKIE, "count": 1, "cook_time": 8.0, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_MEATLOAF_MIX:
				return {"item_id": SSDItemDefs.ITEM_MEATLOAF, "count": 1, "cook_time": 12.0, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_RAW_MEAT_LOVERS_PIZZA:
				return {"item_id": SSDItemDefs.ITEM_MEAT_LOVERS_PIZZA, "count": 1, "cook_time": 12.0, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_DOUGH:
				return {"item_id": SSDItemDefs.ITEM_BREADSTICKS, "count": 1, "cook_time": 8.5, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_ITALIAN_CHEESE_BREAD_DOUGH:
				return {"item_id": SSDItemDefs.ITEM_ITALIAN_CHEESE_BREAD, "count": 1, "cook_time": 9.5, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if input_item_id == SSDItemDefs.ITEM_RED_VELVET_COOKIE_DOUGH:
				return {"item_id": SSDItemDefs.ITEM_RED_VELVET_COOKIE, "count": 1, "cook_time": 8.5, "secondary_consumed": false, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
		STATION_FERMENTER:
			if input_item_id == SSDItemDefs.ITEM_CUCUMBER and secondary_item_id == SSDItemDefs.ITEM_WATER_BOTTLE:
				return {"item_id": SSDItemDefs.ITEM_PICKLES, "count": 1, "cook_time": 16.0, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_GLASS_BOTTLE}
		STATION_BLENDER:
			if secondary_item_id == SSDItemDefs.ITEM_WATER_BOTTLE and input_item_id in [SSDItemDefs.ITEM_STRAWBERRY, SSDItemDefs.ITEM_BLUEBERRY, SSDItemDefs.ITEM_BLACKBERRY, SSDItemDefs.ITEM_MANGO]:
				return {"item_id": SSDItemDefs.ITEM_SMOOTHIE, "count": 1, "cook_time": 4.5, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
			if secondary_item_id == SSDItemDefs.ITEM_WATER_BOTTLE and input_item_id == SSDItemDefs.ITEM_CHOCOLATE_CHIP_COOKIE:
				return {"item_id": SSDItemDefs.ITEM_CARAMEL_FRAPPE, "count": 1, "cook_time": 5.2, "secondary_consumed": true, "secondary_return_item_id": SSDItemDefs.ITEM_AIR}
	return _empty_recipe()

static func _valid_secondary_items(station_type: String) -> PackedInt32Array:
	match station_type:
		STATION_PREP:
			return PackedInt32Array([SSDItemDefs.ITEM_AIR, SSDItemDefs.ITEM_WATER_BOTTLE, SSDItemDefs.ITEM_SLICED_TOMATO, SSDItemDefs.ITEM_SHREDDED_CHEESE, SSDItemDefs.ITEM_COOKED_CHICKEN, SSDItemDefs.ITEM_GROUND_BEEF, SSDItemDefs.ITEM_CARROT, SSDItemDefs.ITEM_STRAWBERRY])
		STATION_STOVE:
			return PackedInt32Array([SSDItemDefs.ITEM_PAN, SSDItemDefs.ITEM_POT])
		STATION_OVEN:
			return PackedInt32Array([SSDItemDefs.ITEM_COAL, SSDItemDefs.ITEM_STICK, SSDItemDefs.ITEM_OAK_PLANKS, SSDItemDefs.ITEM_OAK_LOG])
		STATION_FERMENTER, STATION_BLENDER:
			return PackedInt32Array([SSDItemDefs.ITEM_WATER_BOTTLE])
		_:
			return PackedInt32Array([])

static func has_any_recipe_for_input(station_type: String, input_item_id: int) -> bool:
	if station_type == STATION_OVEN:
		return int(get_recipe(station_type, input_item_id, SSDItemDefs.ITEM_AIR).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR
	if station_type == STATION_STOVE:
		for cookware_item_id: int in PackedInt32Array([SSDItemDefs.ITEM_PAN, SSDItemDefs.ITEM_POT]):
			if has_any_stove_recipe_for_primary(input_item_id, cookware_item_id):
				return true
		return false
	if int(get_recipe(station_type, input_item_id, SSDItemDefs.ITEM_AIR).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
		return true
	for secondary_item_id: int in _valid_secondary_items(station_type):
		if secondary_item_id == SSDItemDefs.ITEM_AIR:
			continue
		if int(get_recipe(station_type, input_item_id, secondary_item_id).get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR:
			return true
	return false

static func is_valid_secondary_for_station(station_type: String, secondary_item_id: int) -> bool:
	if station_type == STATION_OVEN:
		return is_fuel_item(secondary_item_id)
	return secondary_item_id in _valid_secondary_items(station_type)
