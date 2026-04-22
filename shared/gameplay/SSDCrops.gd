extends RefCounted
class_name SSDCrops

static func can_item_be_planted(item_id: int) -> bool:
	return get_planted_block_for_item(item_id) != SSDVoxelDefs.BlockId.AIR

static func get_planted_block_for_item(item_id: int) -> int:
	match item_id:
		SSDItemDefs.ITEM_WHEAT:
			return SSDVoxelDefs.BlockId.WHEAT_CROP_0
		SSDItemDefs.ITEM_CARROT:
			return SSDVoxelDefs.BlockId.CARROT_CROP_0
		SSDItemDefs.ITEM_POTATO:
			return SSDVoxelDefs.BlockId.POTATO_CROP_0
		SSDItemDefs.ITEM_RICE:
			return SSDVoxelDefs.BlockId.RICE_CROP_0
		SSDItemDefs.ITEM_TOMATO:
			return SSDVoxelDefs.BlockId.TOMATO_CROP_0
		SSDItemDefs.ITEM_CUCUMBER:
			return SSDVoxelDefs.BlockId.CUCUMBER_CROP_0
		SSDItemDefs.ITEM_STRAWBERRY:
			return SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_0
		SSDItemDefs.ITEM_BLUEBERRY:
			return SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_0
		SSDItemDefs.ITEM_BLACKBERRY:
			return SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_0
		SSDItemDefs.ITEM_MANGO:
			return SSDVoxelDefs.BlockId.MANGO_SAPLING
		_:
			return SSDVoxelDefs.BlockId.AIR

static func requires_farmland(block_id: int) -> bool:
	return block_id >= SSDVoxelDefs.BlockId.WHEAT_CROP_0 and block_id <= SSDVoxelDefs.BlockId.CUCUMBER_CROP_2

static func can_plant_on_ground(plant_block_id: int, ground_block_id: int) -> bool:
	if requires_farmland(plant_block_id):
		return ground_block_id == SSDVoxelDefs.BlockId.FARMLAND or ground_block_id == SSDVoxelDefs.BlockId.GRASS or ground_block_id == SSDVoxelDefs.BlockId.DIRT
	return ground_block_id == SSDVoxelDefs.BlockId.GRASS or ground_block_id == SSDVoxelDefs.BlockId.DIRT or ground_block_id == SSDVoxelDefs.BlockId.FARMLAND

static func is_mature(block_id: int) -> bool:
	match block_id:
		SSDVoxelDefs.BlockId.WHEAT_CROP_2, SSDVoxelDefs.BlockId.CARROT_CROP_2, SSDVoxelDefs.BlockId.POTATO_CROP_2, SSDVoxelDefs.BlockId.RICE_CROP_2, SSDVoxelDefs.BlockId.TOMATO_CROP_2, SSDVoxelDefs.BlockId.CUCUMBER_CROP_2, SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_2, SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_2, SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_2:
			return true
		_:
			return false

static func can_grow(block_id: int) -> bool:
	match block_id:
		SSDVoxelDefs.BlockId.WHEAT_CROP_0, SSDVoxelDefs.BlockId.WHEAT_CROP_1, SSDVoxelDefs.BlockId.CARROT_CROP_0, SSDVoxelDefs.BlockId.CARROT_CROP_1, SSDVoxelDefs.BlockId.POTATO_CROP_0, SSDVoxelDefs.BlockId.POTATO_CROP_1, SSDVoxelDefs.BlockId.RICE_CROP_0, SSDVoxelDefs.BlockId.RICE_CROP_1, SSDVoxelDefs.BlockId.TOMATO_CROP_0, SSDVoxelDefs.BlockId.TOMATO_CROP_1, SSDVoxelDefs.BlockId.CUCUMBER_CROP_0, SSDVoxelDefs.BlockId.CUCUMBER_CROP_1, SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_0, SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_1, SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_0, SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_1, SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_0, SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_1, SSDVoxelDefs.BlockId.MANGO_SAPLING:
			return true
		_:
			return false

static func get_next_stage(block_id: int) -> int:
	match block_id:
		SSDVoxelDefs.BlockId.WHEAT_CROP_0:
			return SSDVoxelDefs.BlockId.WHEAT_CROP_1
		SSDVoxelDefs.BlockId.WHEAT_CROP_1:
			return SSDVoxelDefs.BlockId.WHEAT_CROP_2
		SSDVoxelDefs.BlockId.CARROT_CROP_0:
			return SSDVoxelDefs.BlockId.CARROT_CROP_1
		SSDVoxelDefs.BlockId.CARROT_CROP_1:
			return SSDVoxelDefs.BlockId.CARROT_CROP_2
		SSDVoxelDefs.BlockId.POTATO_CROP_0:
			return SSDVoxelDefs.BlockId.POTATO_CROP_1
		SSDVoxelDefs.BlockId.POTATO_CROP_1:
			return SSDVoxelDefs.BlockId.POTATO_CROP_2
		SSDVoxelDefs.BlockId.RICE_CROP_0:
			return SSDVoxelDefs.BlockId.RICE_CROP_1
		SSDVoxelDefs.BlockId.RICE_CROP_1:
			return SSDVoxelDefs.BlockId.RICE_CROP_2
		SSDVoxelDefs.BlockId.TOMATO_CROP_0:
			return SSDVoxelDefs.BlockId.TOMATO_CROP_1
		SSDVoxelDefs.BlockId.TOMATO_CROP_1:
			return SSDVoxelDefs.BlockId.TOMATO_CROP_2
		SSDVoxelDefs.BlockId.CUCUMBER_CROP_0:
			return SSDVoxelDefs.BlockId.CUCUMBER_CROP_1
		SSDVoxelDefs.BlockId.CUCUMBER_CROP_1:
			return SSDVoxelDefs.BlockId.CUCUMBER_CROP_2
		SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_0:
			return SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_1
		SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_1:
			return SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_2
		SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_0:
			return SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_1
		SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_1:
			return SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_2
		SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_0:
			return SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_1
		SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_1:
			return SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_2
		_:
			return block_id

static func get_growth_chance(block_id: int, near_water: bool) -> float:
	var bonus: float = 1.35 if near_water else 1.0
	match block_id:
		SSDVoxelDefs.BlockId.WHEAT_CROP_0, SSDVoxelDefs.BlockId.WHEAT_CROP_1:
			return 0.30 * bonus
		SSDVoxelDefs.BlockId.CARROT_CROP_0, SSDVoxelDefs.BlockId.CARROT_CROP_1, SSDVoxelDefs.BlockId.POTATO_CROP_0, SSDVoxelDefs.BlockId.POTATO_CROP_1:
			return 0.26 * bonus
		SSDVoxelDefs.BlockId.RICE_CROP_0, SSDVoxelDefs.BlockId.RICE_CROP_1:
			return 0.33 * bonus
		SSDVoxelDefs.BlockId.TOMATO_CROP_0, SSDVoxelDefs.BlockId.TOMATO_CROP_1, SSDVoxelDefs.BlockId.CUCUMBER_CROP_0, SSDVoxelDefs.BlockId.CUCUMBER_CROP_1:
			return 0.24 * bonus
		SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_0, SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_1, SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_0, SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_1, SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_0, SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_1:
			return 0.16 * bonus
		SSDVoxelDefs.BlockId.MANGO_SAPLING:
			return 0.10 * bonus
		_:
			return 0.0

static func is_use_harvestable(block_id: int) -> bool:
	return is_mature(block_id)

static func get_use_harvest_result(block_id: int) -> Dictionary:
	match block_id:
		SSDVoxelDefs.BlockId.WHEAT_CROP_2:
			return {"item_id": SSDItemDefs.ITEM_WHEAT, "count": 3, "reset_block_id": SSDVoxelDefs.BlockId.AIR}
		SSDVoxelDefs.BlockId.CARROT_CROP_2:
			return {"item_id": SSDItemDefs.ITEM_CARROT, "count": 2, "reset_block_id": SSDVoxelDefs.BlockId.AIR}
		SSDVoxelDefs.BlockId.POTATO_CROP_2:
			return {"item_id": SSDItemDefs.ITEM_POTATO, "count": 2, "reset_block_id": SSDVoxelDefs.BlockId.AIR}
		SSDVoxelDefs.BlockId.RICE_CROP_2:
			return {"item_id": SSDItemDefs.ITEM_RICE, "count": 3, "reset_block_id": SSDVoxelDefs.BlockId.AIR}
		SSDVoxelDefs.BlockId.TOMATO_CROP_2:
			return {"item_id": SSDItemDefs.ITEM_TOMATO, "count": 3, "reset_block_id": SSDVoxelDefs.BlockId.TOMATO_CROP_1}
		SSDVoxelDefs.BlockId.CUCUMBER_CROP_2:
			return {"item_id": SSDItemDefs.ITEM_CUCUMBER, "count": 2, "reset_block_id": SSDVoxelDefs.BlockId.CUCUMBER_CROP_1}
		SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_2:
			return {"item_id": SSDItemDefs.ITEM_STRAWBERRY, "count": 3, "reset_block_id": SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_1}
		SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_2:
			return {"item_id": SSDItemDefs.ITEM_BLUEBERRY, "count": 3, "reset_block_id": SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_1}
		SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_2:
			return {"item_id": SSDItemDefs.ITEM_BLACKBERRY, "count": 3, "reset_block_id": SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_1}
		_:
			return {"item_id": SSDItemDefs.ITEM_AIR, "count": 0, "reset_block_id": block_id}

static func get_break_drop_item_id(block_id: int) -> int:
	match block_id:
		SSDVoxelDefs.BlockId.WHEAT_CROP_2:
			return SSDItemDefs.ITEM_WHEAT
		SSDVoxelDefs.BlockId.CARROT_CROP_2:
			return SSDItemDefs.ITEM_CARROT
		SSDVoxelDefs.BlockId.POTATO_CROP_2:
			return SSDItemDefs.ITEM_POTATO
		SSDVoxelDefs.BlockId.RICE_CROP_2:
			return SSDItemDefs.ITEM_RICE
		SSDVoxelDefs.BlockId.TOMATO_CROP_2:
			return SSDItemDefs.ITEM_TOMATO
		SSDVoxelDefs.BlockId.CUCUMBER_CROP_2:
			return SSDItemDefs.ITEM_CUCUMBER
		SSDVoxelDefs.BlockId.STRAWBERRY_BUSH_2:
			return SSDItemDefs.ITEM_STRAWBERRY
		SSDVoxelDefs.BlockId.BLUEBERRY_BUSH_2:
			return SSDItemDefs.ITEM_BLUEBERRY
		SSDVoxelDefs.BlockId.BLACKBERRY_BUSH_2:
			return SSDItemDefs.ITEM_BLACKBERRY
		SSDVoxelDefs.BlockId.MANGO_LEAVES:
			return SSDItemDefs.ITEM_MANGO
		_:
			return SSDItemDefs.ITEM_AIR
