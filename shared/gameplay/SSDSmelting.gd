extends RefCounted
class_name SSDSmelting

static func get_smelt_result(item_id: int) -> Dictionary:
    match item_id:
        SSDItemDefs.ITEM_RAW_MUTTON:
            return {"item_id": SSDItemDefs.ITEM_COOKED_MUTTON, "count": 1, "cook_time": 10.0}
        SSDItemDefs.ITEM_RAW_BEEF:
            return {"item_id": SSDItemDefs.ITEM_COOKED_BEEF, "count": 1, "cook_time": 10.0}
        SSDItemDefs.ITEM_RAW_CHICKEN:
            return {"item_id": SSDItemDefs.ITEM_COOKED_CHICKEN, "count": 1, "cook_time": 10.0}
        SSDItemDefs.ITEM_IRON_CHUNK:
            return {"item_id": SSDItemDefs.ITEM_IRON_INGOT, "count": 1, "cook_time": 10.0}
        SSDItemDefs.ITEM_SAND:
            return {"item_id": SSDItemDefs.ITEM_GLASS, "count": 1, "cook_time": 8.0}
        SSDItemDefs.ITEM_RICE:
            return {"item_id": SSDItemDefs.ITEM_COOKED_RICE, "count": 1, "cook_time": 7.0}
        SSDItemDefs.ITEM_RAW_CHEESE_PIZZA:
            return {"item_id": SSDItemDefs.ITEM_CHEESE_PIZZA, "count": 1, "cook_time": 12.0}
        SSDItemDefs.ITEM_COOKIE_DOUGH:
            return {"item_id": SSDItemDefs.ITEM_CHOCOLATE_CHIP_COOKIE, "count": 1, "cook_time": 9.0}
        _:
            return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0, "cook_time": 0.0}

static func get_fuel_burn_time(item_id: int) -> float:
    match item_id:
        SSDItemDefs.ITEM_OAK_LOG:
            return 15.0
        SSDItemDefs.ITEM_OAK_PLANKS:
            return 7.5
        SSDItemDefs.ITEM_STICK:
            return 2.5
        SSDItemDefs.ITEM_COAL:
            return 80.0
        _:
            return 0.0
