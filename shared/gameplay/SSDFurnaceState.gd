extends RefCounted
class_name SSDFurnaceState

const MAX_STACK: int = 64

var input_item_id: int = SSDItemDefs.ITEM_AIR
var input_count: int = 0
var fuel_item_id: int = SSDItemDefs.ITEM_AIR
var fuel_count: int = 0
var output_item_id: int = SSDItemDefs.ITEM_AIR
var output_count: int = 0
var burn_time: float = 0.0
var burn_total: float = 0.0
var cook_time: float = 0.0
var cook_total: float = 10.0

func tick(delta: float) -> void:
    if burn_time > 0.0:
        burn_time = maxf(0.0, burn_time - delta)

    var recipe: Dictionary = SSDSmelting.get_smelt_result(input_item_id)
    var result_id: int = int(recipe.get("item_id", SSDItemDefs.ITEM_AIR))
    var result_count: int = int(recipe.get("count", 0))
    cook_total = float(recipe.get("cook_time", 10.0))

    var can_smelt_now: bool = _can_accept_output(result_id, result_count) and input_count > 0 and result_id != SSDItemDefs.ITEM_AIR

    if can_smelt_now and burn_time <= 0.0 and fuel_count > 0:
        var fuel_burn: float = SSDSmelting.get_fuel_burn_time(fuel_item_id)
        if fuel_burn > 0.0:
            burn_time = fuel_burn
            burn_total = fuel_burn
            fuel_count -= 1
            if fuel_count <= 0:
                fuel_count = 0
                fuel_item_id = SSDItemDefs.ITEM_AIR

    if can_smelt_now and burn_time > 0.0:
        cook_time += delta
        if cook_time >= cook_total:
            cook_time = 0.0
            _finish_smelt(result_id, result_count)
    else:
        cook_time = 0.0

func _can_accept_output(result_id: int, result_count: int) -> bool:
    if result_id == SSDItemDefs.ITEM_AIR or result_count <= 0:
        return false
    if output_count <= 0 or output_item_id == SSDItemDefs.ITEM_AIR:
        return true
    return output_item_id == result_id and output_count + result_count <= MAX_STACK

func _finish_smelt(result_id: int, result_count: int) -> void:
    input_count -= 1
    if input_count <= 0:
        input_count = 0
        input_item_id = SSDItemDefs.ITEM_AIR
    if output_count <= 0 or output_item_id == SSDItemDefs.ITEM_AIR:
        output_item_id = result_id
        output_count = result_count
    else:
        output_count += result_count

func can_place_input(item_id: int) -> bool:
    var recipe: Dictionary = SSDSmelting.get_smelt_result(item_id)
    return int(recipe.get("item_id", SSDItemDefs.ITEM_AIR)) != SSDItemDefs.ITEM_AIR

func can_place_fuel(item_id: int) -> bool:
    return SSDSmelting.get_fuel_burn_time(item_id) > 0.0
