extends RefCounted
class_name SSDVoxelDefs

enum BlockId {
	AIR = 0,
	GRASS = 1,
	DIRT = 2,
	STONE = 3,
	OAK_LOG = 4,
	OAK_LEAVES = 5,
	OAK_PLANKS = 6,
	CRAFTING_TABLE = 7,
	COBBLESTONE = 8,
	FURNACE = 9,
	WATER = 10,
	COAL_ORE = 11,
	IRON_ORE = 12,
	SAND = 13,
	GLASS = 14,
	WATER_FLOW_7 = 15,
	WATER_FLOW_6 = 16,
	WATER_FLOW_5 = 17,
	WATER_FLOW_4 = 18,
	WATER_FLOW_3 = 19,
	WATER_FLOW_2 = 20,
	WATER_FLOW_1 = 21,
	PREP_TABLE = 22,
	STOVE = 23,
	OVEN = 24,
	FERMENTER = 25,
	BLENDER = 26,
	FARMLAND = 27,
	WHEAT_CROP_0 = 28,
	WHEAT_CROP_1 = 29,
	WHEAT_CROP_2 = 30,
	CARROT_CROP_0 = 31,
	CARROT_CROP_1 = 32,
	CARROT_CROP_2 = 33,
	POTATO_CROP_0 = 34,
	POTATO_CROP_1 = 35,
	POTATO_CROP_2 = 36,
	RICE_CROP_0 = 37,
	RICE_CROP_1 = 38,
	RICE_CROP_2 = 39,
	TOMATO_CROP_0 = 40,
	TOMATO_CROP_1 = 41,
	TOMATO_CROP_2 = 42,
	CUCUMBER_CROP_0 = 43,
	CUCUMBER_CROP_1 = 44,
	CUCUMBER_CROP_2 = 45,
	STRAWBERRY_BUSH_0 = 46,
	STRAWBERRY_BUSH_1 = 47,
	STRAWBERRY_BUSH_2 = 48,
	BLUEBERRY_BUSH_0 = 49,
	BLUEBERRY_BUSH_1 = 50,
	BLUEBERRY_BUSH_2 = 51,
	BLACKBERRY_BUSH_0 = 52,
	BLACKBERRY_BUSH_1 = 53,
	BLACKBERRY_BUSH_2 = 54,
	MANGO_SAPLING = 55,
	MANGO_LEAVES = 56,
	DISPLAY_CASE = 57,
}

const ATLAS_TILE_SIZE: int = 64
const ATLAS_COLUMNS: int = 8
const ATLAS_ROWS: int = 6
const TOP_CONNECTED_REPEAT_BLOCKS: int = 1
const NAMESPACE_PREFIX: String = "SSD:"

const TILE_GRASS_TOP: int = 0
const TILE_GRASS_SIDE: int = 1
const TILE_DIRT: int = 2
const TILE_STONE: int = 3
const TILE_OAK_LOG_SIDE: int = 4
const TILE_OAK_LEAVES: int = 5
const TILE_OAK_LOG_TOP: int = 6
const TILE_UNUSED: int = 7
const TILE_OAK_PLANKS: int = 8
const TILE_CRAFTING_TABLE_TOP: int = 9
const TILE_CRAFTING_TABLE_SIDE: int = 10
const TILE_CRAFTING_TABLE_BOTTOM: int = 11
const TILE_WATER: int = 12
const TILE_COAL_ORE: int = 13
const TILE_IRON_ORE: int = 14
const TILE_FURNACE_FRONT: int = 15
const TILE_SAND: int = 16
const TILE_GLASS: int = 17
const TILE_PREP_TABLE_TOP: int = 18
const TILE_PREP_TABLE_SIDE: int = 19
const TILE_STOVE: int = 20
const TILE_OVEN: int = 21
const TILE_FERMENTER: int = 22
const TILE_BLENDER: int = 23
const TILE_FARMLAND: int = 24
const TILE_WHEAT_0: int = 25
const TILE_WHEAT_1: int = 26
const TILE_WHEAT_2: int = 27
const TILE_CARROT_0: int = 28
const TILE_CARROT_1: int = 29
const TILE_CARROT_2: int = 30
const TILE_POTATO_0: int = 31
const TILE_POTATO_1: int = 32
const TILE_POTATO_2: int = 33
const TILE_RICE_0: int = 34
const TILE_RICE_1: int = 35
const TILE_RICE_2: int = 36
const TILE_TOMATO_0: int = 37
const TILE_TOMATO_1: int = 38
const TILE_TOMATO_2: int = 39
const TILE_CUCUMBER_0: int = 40
const TILE_CUCUMBER_1: int = 41
const TILE_CUCUMBER_2: int = 42
const TILE_STRAWBERRY_BUSH: int = 43
const TILE_BLUEBERRY_BUSH: int = 44
const TILE_BLACKBERRY_BUSH: int = 45
const TILE_MANGO_SAPLING: int = 46
const TILE_MANGO_LEAVES: int = 47

static func is_air(block_id: int) -> bool:
	return block_id == BlockId.AIR

static func is_source_water(block_id: int) -> bool:
	return block_id == BlockId.WATER

static func is_flowing_water(block_id: int) -> bool:
	return block_id >= BlockId.WATER_FLOW_1 and block_id <= BlockId.WATER_FLOW_7

static func is_fluid(block_id: int) -> bool:
	return is_source_water(block_id) or is_flowing_water(block_id)

static func is_solid(block_id: int) -> bool:
	return block_id != BlockId.AIR and not is_fluid(block_id) and not is_plant_block(block_id) and not is_bush_block(block_id) and block_id != BlockId.MANGO_SAPLING

static func is_renderable(block_id: int) -> bool:
	return block_id != BlockId.AIR

static func is_gravity_block(block_id: int) -> bool:
	return block_id == BlockId.SAND

static func get_water_level(block_id: int) -> int:
	match block_id:
		BlockId.WATER:
			return 8
		BlockId.WATER_FLOW_7:
			return 7
		BlockId.WATER_FLOW_6:
			return 6
		BlockId.WATER_FLOW_5:
			return 5
		BlockId.WATER_FLOW_4:
			return 4
		BlockId.WATER_FLOW_3:
			return 3
		BlockId.WATER_FLOW_2:
			return 2
		BlockId.WATER_FLOW_1:
			return 1
		_:
			return 0

static func get_flow_block_from_level(level: int) -> int:
	match clampi(level, 1, 7):
		7:
			return BlockId.WATER_FLOW_7
		6:
			return BlockId.WATER_FLOW_6
		5:
			return BlockId.WATER_FLOW_5
		4:
			return BlockId.WATER_FLOW_4
		3:
			return BlockId.WATER_FLOW_3
		2:
			return BlockId.WATER_FLOW_2
		_:
			return BlockId.WATER_FLOW_1

static func get_fluid_surface_height(block_id: int) -> float:
	match get_water_level(block_id):
		8:
			return 0.90
		7:
			return 0.86
		6:
			return 0.76
		5:
			return 0.66
		4:
			return 0.56
		3:
			return 0.46
		2:
			return 0.34
		1:
			return 0.22
		_:
			return 1.0

static func get_color(block_id: int) -> Color:
	match block_id:
		BlockId.GRASS:
			return Color(0.84, 0.87, 0.84, 1.0)
		BlockId.DIRT:
			return Color(0.82, 0.78, 0.74, 1.0)
		BlockId.STONE:
			return Color(0.80, 0.80, 0.80, 1.0)
		BlockId.OAK_LOG:
			return Color(0.82, 0.79, 0.74, 1.0)
		BlockId.OAK_LEAVES:
			return Color(0.80, 0.86, 0.80, 0.88)
		BlockId.OAK_PLANKS:
			return Color(0.86, 0.80, 0.70, 1.0)
		BlockId.CRAFTING_TABLE:
			return Color(0.82, 0.77, 0.70, 1.0)
		BlockId.COBBLESTONE:
			return Color(0.78, 0.78, 0.78, 1.0)
		BlockId.FURNACE:
			return Color(0.78, 0.78, 0.78, 1.0)
		BlockId.WATER, BlockId.WATER_FLOW_7, BlockId.WATER_FLOW_6, BlockId.WATER_FLOW_5, BlockId.WATER_FLOW_4, BlockId.WATER_FLOW_3, BlockId.WATER_FLOW_2, BlockId.WATER_FLOW_1:
			return Color(0.70, 0.77, 0.88, 0.50)
		BlockId.COAL_ORE:
			return Color(0.82, 0.82, 0.82, 1.0)
		BlockId.IRON_ORE:
			return Color(0.82, 0.82, 0.82, 1.0)
		BlockId.SAND:
			return Color(0.88, 0.84, 0.72, 1.0)
		BlockId.GLASS:
			return Color(0.88, 0.92, 0.96, 0.18)
		BlockId.PREP_TABLE:
			return Color(0.78, 0.66, 0.52, 1.0)
		BlockId.STOVE:
			return Color(0.62, 0.62, 0.66, 1.0)
		BlockId.OVEN:
			return Color(0.66, 0.66, 0.70, 1.0)
		BlockId.FERMENTER:
			return Color(0.68, 0.54, 0.38, 1.0)
		BlockId.BLENDER:
			return Color(0.82, 0.92, 0.96, 1.0)
		BlockId.FARMLAND:
			return Color(0.58, 0.42, 0.24, 1.0)
		BlockId.WHEAT_CROP_0, BlockId.WHEAT_CROP_1, BlockId.WHEAT_CROP_2, BlockId.CARROT_CROP_0, BlockId.CARROT_CROP_1, BlockId.CARROT_CROP_2, BlockId.POTATO_CROP_0, BlockId.POTATO_CROP_1, BlockId.POTATO_CROP_2, BlockId.RICE_CROP_0, BlockId.RICE_CROP_1, BlockId.RICE_CROP_2, BlockId.TOMATO_CROP_0, BlockId.TOMATO_CROP_1, BlockId.TOMATO_CROP_2, BlockId.CUCUMBER_CROP_0, BlockId.CUCUMBER_CROP_1, BlockId.CUCUMBER_CROP_2:
			return Color(1.0, 1.0, 1.0, 0.95)
		BlockId.STRAWBERRY_BUSH_0, BlockId.STRAWBERRY_BUSH_1, BlockId.STRAWBERRY_BUSH_2, BlockId.BLUEBERRY_BUSH_0, BlockId.BLUEBERRY_BUSH_1, BlockId.BLUEBERRY_BUSH_2, BlockId.BLACKBERRY_BUSH_0, BlockId.BLACKBERRY_BUSH_1, BlockId.BLACKBERRY_BUSH_2:
			return Color(1.0, 1.0, 1.0, 0.92)
		BlockId.MANGO_SAPLING:
			return Color(1.0, 1.0, 1.0, 0.95)
		BlockId.MANGO_LEAVES:
			return Color(0.84, 0.92, 0.78, 0.88)
		BlockId.DISPLAY_CASE:
			return Color(0.86, 0.90, 0.96, 0.18)
		_:
			return Color(0.0, 0.0, 0.0, 0.0)

static func get_block_name(block_id: int) -> String:
	match block_id:
		BlockId.AIR:
			return "air"
		BlockId.GRASS:
			return "grass"
		BlockId.DIRT:
			return "dirt"
		BlockId.STONE:
			return "stone"
		BlockId.OAK_LOG:
			return "oak_log"
		BlockId.OAK_LEAVES:
			return "oak_leaves"
		BlockId.OAK_PLANKS:
			return "oak_planks"
		BlockId.CRAFTING_TABLE:
			return "crafting_table"
		BlockId.COBBLESTONE:
			return "cobblestone"
		BlockId.FURNACE:
			return "furnace"
		BlockId.WATER:
			return "water"
		BlockId.COAL_ORE:
			return "coal_ore"
		BlockId.IRON_ORE:
			return "iron_ore"
		BlockId.SAND:
			return "sand"
		BlockId.GLASS:
			return "glass"
		BlockId.PREP_TABLE:
			return "prep_table"
		BlockId.STOVE:
			return "stove"
		BlockId.OVEN:
			return "oven"
		BlockId.FERMENTER:
			return "fermenter"
		BlockId.BLENDER:
			return "blender"
		BlockId.FARMLAND:
			return "farmland"
		BlockId.WHEAT_CROP_0:
			return "wheat_crop_0"
		BlockId.WHEAT_CROP_1:
			return "wheat_crop_1"
		BlockId.WHEAT_CROP_2:
			return "wheat_crop_2"
		BlockId.CARROT_CROP_0:
			return "carrot_crop_0"
		BlockId.CARROT_CROP_1:
			return "carrot_crop_1"
		BlockId.CARROT_CROP_2:
			return "carrot_crop_2"
		BlockId.POTATO_CROP_0:
			return "potato_crop_0"
		BlockId.POTATO_CROP_1:
			return "potato_crop_1"
		BlockId.POTATO_CROP_2:
			return "potato_crop_2"
		BlockId.RICE_CROP_0:
			return "rice_crop_0"
		BlockId.RICE_CROP_1:
			return "rice_crop_1"
		BlockId.RICE_CROP_2:
			return "rice_crop_2"
		BlockId.TOMATO_CROP_0:
			return "tomato_crop_0"
		BlockId.TOMATO_CROP_1:
			return "tomato_crop_1"
		BlockId.TOMATO_CROP_2:
			return "tomato_crop_2"
		BlockId.CUCUMBER_CROP_0:
			return "cucumber_crop_0"
		BlockId.CUCUMBER_CROP_1:
			return "cucumber_crop_1"
		BlockId.CUCUMBER_CROP_2:
			return "cucumber_crop_2"
		BlockId.STRAWBERRY_BUSH_0:
			return "strawberry_bush_0"
		BlockId.STRAWBERRY_BUSH_1:
			return "strawberry_bush_1"
		BlockId.STRAWBERRY_BUSH_2:
			return "strawberry_bush_2"
		BlockId.BLUEBERRY_BUSH_0:
			return "blueberry_bush_0"
		BlockId.BLUEBERRY_BUSH_1:
			return "blueberry_bush_1"
		BlockId.BLUEBERRY_BUSH_2:
			return "blueberry_bush_2"
		BlockId.BLACKBERRY_BUSH_0:
			return "blackberry_bush_0"
		BlockId.BLACKBERRY_BUSH_1:
			return "blackberry_bush_1"
		BlockId.BLACKBERRY_BUSH_2:
			return "blackberry_bush_2"
		BlockId.MANGO_SAPLING:
			return "mango_sapling"
		BlockId.MANGO_LEAVES:
			return "mango_leaves"
		BlockId.DISPLAY_CASE:
			return "display_case"
		BlockId.WATER_FLOW_7:
			return "water_flow_7"
		BlockId.WATER_FLOW_6:
			return "water_flow_6"
		BlockId.WATER_FLOW_5:
			return "water_flow_5"
		BlockId.WATER_FLOW_4:
			return "water_flow_4"
		BlockId.WATER_FLOW_3:
			return "water_flow_3"
		BlockId.WATER_FLOW_2:
			return "water_flow_2"
		BlockId.WATER_FLOW_1:
			return "water_flow_1"
		_:
			return "unknown"

static func get_display_name(block_id: int) -> String:
	match block_id:
		BlockId.GRASS:
			return "Grass"
		BlockId.DIRT:
			return "Dirt"
		BlockId.STONE:
			return "Stone"
		BlockId.OAK_LOG:
			return "Oak Log"
		BlockId.OAK_LEAVES:
			return "Oak Leaves"
		BlockId.OAK_PLANKS:
			return "Oak Planks"
		BlockId.CRAFTING_TABLE:
			return "Crafting Table"
		BlockId.COBBLESTONE:
			return "Cobblestone"
		BlockId.FURNACE:
			return "Furnace"
		BlockId.WATER:
			return "Water"
		BlockId.COAL_ORE:
			return "Coal Ore"
		BlockId.IRON_ORE:
			return "Iron Ore"
		BlockId.SAND:
			return "Sand"
		BlockId.GLASS:
			return "Glass"
		BlockId.PREP_TABLE:
			return "Prep Table"
		BlockId.STOVE:
			return "Stove"
		BlockId.OVEN:
			return "Oven"
		BlockId.FERMENTER:
			return "Fermentation Jar"
		BlockId.BLENDER:
			return "Blender"
		BlockId.FARMLAND:
			return "Farmland"
		BlockId.WHEAT_CROP_0, BlockId.WHEAT_CROP_1, BlockId.WHEAT_CROP_2:
			return "Wheat Crop"
		BlockId.CARROT_CROP_0, BlockId.CARROT_CROP_1, BlockId.CARROT_CROP_2:
			return "Carrot Crop"
		BlockId.POTATO_CROP_0, BlockId.POTATO_CROP_1, BlockId.POTATO_CROP_2:
			return "Potato Crop"
		BlockId.RICE_CROP_0, BlockId.RICE_CROP_1, BlockId.RICE_CROP_2:
			return "Rice Crop"
		BlockId.TOMATO_CROP_0, BlockId.TOMATO_CROP_1, BlockId.TOMATO_CROP_2:
			return "Tomato Plant"
		BlockId.CUCUMBER_CROP_0, BlockId.CUCUMBER_CROP_1, BlockId.CUCUMBER_CROP_2:
			return "Cucumber Plant"
		BlockId.STRAWBERRY_BUSH_0, BlockId.STRAWBERRY_BUSH_1, BlockId.STRAWBERRY_BUSH_2:
			return "Strawberry Bush"
		BlockId.BLUEBERRY_BUSH_0, BlockId.BLUEBERRY_BUSH_1, BlockId.BLUEBERRY_BUSH_2:
			return "Blueberry Bush"
		BlockId.BLACKBERRY_BUSH_0, BlockId.BLACKBERRY_BUSH_1, BlockId.BLACKBERRY_BUSH_2:
			return "Blackberry Bush"
		BlockId.MANGO_SAPLING:
			return "Mango Sapling"
		BlockId.MANGO_LEAVES:
			return "Mango Leaves"
		BlockId.DISPLAY_CASE:
			return "Display Case"
		BlockId.AIR:
			return "Empty"
		_:
			return "Water"

static func get_namespaced_id(block_id: int) -> String:
	return NAMESPACE_PREFIX + get_block_name(block_id)

static func get_display_id(block_id: int) -> String:
	if block_id == BlockId.AIR:
		return "EMPTY"
	return "%s [%d]" % [get_namespaced_id(block_id), block_id]

static func get_tooltip_lines(block_id: int) -> PackedStringArray:
	if block_id == BlockId.AIR:
		return PackedStringArray([])
	return PackedStringArray([
		get_display_name(block_id),
		"%s [%d]" % [get_namespaced_id(block_id), block_id],
	])

static func resolve_block_token(token: String) -> int:
	var cleaned: String = token.strip_edges()
	if cleaned.is_empty():
		return BlockId.AIR

	if cleaned.is_valid_int():
		var numeric_id: int = cleaned.to_int()
		match numeric_id:
			BlockId.GRASS, BlockId.DIRT, BlockId.STONE, BlockId.OAK_LOG, BlockId.OAK_LEAVES, BlockId.OAK_PLANKS, BlockId.CRAFTING_TABLE, BlockId.COBBLESTONE, BlockId.FURNACE, BlockId.WATER, BlockId.COAL_ORE, BlockId.IRON_ORE, BlockId.SAND, BlockId.GLASS, BlockId.PREP_TABLE, BlockId.STOVE, BlockId.OVEN, BlockId.FERMENTER, BlockId.BLENDER:
				return numeric_id
			_:
				return BlockId.AIR

	var lowered: String = cleaned.to_lower()
	if lowered.begins_with(NAMESPACE_PREFIX.to_lower()):
		lowered = lowered.substr(NAMESPACE_PREFIX.length())

	match lowered:
		"grass":
			return BlockId.GRASS
		"dirt":
			return BlockId.DIRT
		"stone":
			return BlockId.STONE
		"oak_log", "log":
			return BlockId.OAK_LOG
		"oak_leaves", "leaves":
			return BlockId.OAK_LEAVES
		"oak_planks", "planks", "plank":
			return BlockId.OAK_PLANKS
		"crafting_table", "table":
			return BlockId.CRAFTING_TABLE
		"cobblestone", "cobble":
			return BlockId.COBBLESTONE
		"furnace":
			return BlockId.FURNACE
		"water":
			return BlockId.WATER
		"coal_ore", "coalore":
			return BlockId.COAL_ORE
		"iron_ore", "ironore":
			return BlockId.IRON_ORE
		"sand":
			return BlockId.SAND
		"glass":
			return BlockId.GLASS
		"prep_table", "preptable":
			return BlockId.PREP_TABLE
		"stove":
			return BlockId.STOVE
		"oven":
			return BlockId.OVEN
		"fermenter", "fermentation_jar":
			return BlockId.FERMENTER
		"blender":
			return BlockId.BLENDER
		"display_case", "displaycase", "wardrobe":
			return BlockId.DISPLAY_CASE
		_:
			return BlockId.AIR

static func get_face_tile_index(block_id: int, face_index: int) -> int:
	match block_id:
		BlockId.GRASS:
			if face_index == 2:
				return TILE_GRASS_TOP
			if face_index == 3:
				return TILE_DIRT
			return TILE_GRASS_SIDE
		BlockId.DIRT:
			return TILE_DIRT
		BlockId.STONE:
			return TILE_STONE
		BlockId.OAK_LOG:
			if face_index == 2 or face_index == 3:
				return TILE_OAK_LOG_TOP
			return TILE_OAK_LOG_SIDE
		BlockId.OAK_LEAVES:
			return TILE_OAK_LEAVES
		BlockId.OAK_PLANKS:
			return TILE_OAK_PLANKS
		BlockId.CRAFTING_TABLE:
			if face_index == 2:
				return TILE_CRAFTING_TABLE_TOP
			if face_index == 3:
				return TILE_CRAFTING_TABLE_BOTTOM
			return TILE_CRAFTING_TABLE_SIDE
		BlockId.COBBLESTONE:
			return TILE_STONE
		BlockId.FURNACE:
			if face_index == 4:
				return TILE_FURNACE_FRONT
			return TILE_STONE
		BlockId.WATER, BlockId.WATER_FLOW_7, BlockId.WATER_FLOW_6, BlockId.WATER_FLOW_5, BlockId.WATER_FLOW_4, BlockId.WATER_FLOW_3, BlockId.WATER_FLOW_2, BlockId.WATER_FLOW_1:
			return TILE_WATER
		BlockId.COAL_ORE:
			return TILE_COAL_ORE
		BlockId.IRON_ORE:
			return TILE_IRON_ORE
		BlockId.SAND:
			return TILE_SAND
		BlockId.GLASS:
			return TILE_GLASS
		BlockId.PREP_TABLE:
			if face_index == 2:
				return TILE_PREP_TABLE_TOP
			return TILE_PREP_TABLE_SIDE
		BlockId.STOVE:
			return TILE_STOVE
		BlockId.OVEN:
			return TILE_OVEN
		BlockId.FERMENTER:
			return TILE_FERMENTER
		BlockId.BLENDER:
			return TILE_BLENDER
		BlockId.FARMLAND:
			return TILE_FARMLAND
		BlockId.WHEAT_CROP_0:
			return TILE_WHEAT_0
		BlockId.WHEAT_CROP_1:
			return TILE_WHEAT_1
		BlockId.WHEAT_CROP_2:
			return TILE_WHEAT_2
		BlockId.CARROT_CROP_0:
			return TILE_CARROT_0
		BlockId.CARROT_CROP_1:
			return TILE_CARROT_1
		BlockId.CARROT_CROP_2:
			return TILE_CARROT_2
		BlockId.POTATO_CROP_0:
			return TILE_POTATO_0
		BlockId.POTATO_CROP_1:
			return TILE_POTATO_1
		BlockId.POTATO_CROP_2:
			return TILE_POTATO_2
		BlockId.RICE_CROP_0:
			return TILE_RICE_0
		BlockId.RICE_CROP_1:
			return TILE_RICE_1
		BlockId.RICE_CROP_2:
			return TILE_RICE_2
		BlockId.TOMATO_CROP_0:
			return TILE_TOMATO_0
		BlockId.TOMATO_CROP_1:
			return TILE_TOMATO_1
		BlockId.TOMATO_CROP_2:
			return TILE_TOMATO_2
		BlockId.CUCUMBER_CROP_0:
			return TILE_CUCUMBER_0
		BlockId.CUCUMBER_CROP_1:
			return TILE_CUCUMBER_1
		BlockId.CUCUMBER_CROP_2:
			return TILE_CUCUMBER_2
		BlockId.STRAWBERRY_BUSH_0, BlockId.STRAWBERRY_BUSH_1, BlockId.STRAWBERRY_BUSH_2:
			return TILE_STRAWBERRY_BUSH
		BlockId.BLUEBERRY_BUSH_0, BlockId.BLUEBERRY_BUSH_1, BlockId.BLUEBERRY_BUSH_2:
			return TILE_BLUEBERRY_BUSH
		BlockId.BLACKBERRY_BUSH_0, BlockId.BLACKBERRY_BUSH_1, BlockId.BLACKBERRY_BUSH_2:
			return TILE_BLACKBERRY_BUSH
		BlockId.MANGO_SAPLING:
			return TILE_MANGO_SAPLING
		BlockId.MANGO_LEAVES:
			return TILE_MANGO_LEAVES
		BlockId.DISPLAY_CASE:
			return TILE_GLASS
		_:
			return -1

static func get_hotbar_tile_index(block_id: int) -> int:
	match block_id:
		BlockId.GRASS:
			return TILE_GRASS_TOP
		BlockId.DIRT:
			return TILE_DIRT
		BlockId.STONE:
			return TILE_STONE
		BlockId.OAK_LOG:
			return TILE_OAK_LOG_SIDE
		BlockId.OAK_LEAVES:
			return TILE_OAK_LEAVES
		BlockId.OAK_PLANKS:
			return TILE_OAK_PLANKS
		BlockId.CRAFTING_TABLE:
			return TILE_CRAFTING_TABLE_TOP
		BlockId.COBBLESTONE:
			return TILE_STONE
		BlockId.FURNACE:
			return TILE_FURNACE_FRONT
		BlockId.WATER, BlockId.WATER_FLOW_7, BlockId.WATER_FLOW_6, BlockId.WATER_FLOW_5, BlockId.WATER_FLOW_4, BlockId.WATER_FLOW_3, BlockId.WATER_FLOW_2, BlockId.WATER_FLOW_1:
			return TILE_WATER
		BlockId.COAL_ORE:
			return TILE_COAL_ORE
		BlockId.IRON_ORE:
			return TILE_IRON_ORE
		BlockId.SAND:
			return TILE_SAND
		BlockId.GLASS:
			return TILE_GLASS
		BlockId.PREP_TABLE:
			return TILE_PREP_TABLE_TOP
		BlockId.STOVE:
			return TILE_STOVE
		BlockId.OVEN:
			return TILE_OVEN
		BlockId.FERMENTER:
			return TILE_FERMENTER
		BlockId.BLENDER:
			return TILE_BLENDER
		BlockId.FARMLAND:
			return TILE_FARMLAND
		BlockId.WHEAT_CROP_0:
			return TILE_WHEAT_0
		BlockId.WHEAT_CROP_1:
			return TILE_WHEAT_1
		BlockId.WHEAT_CROP_2:
			return TILE_WHEAT_2
		BlockId.CARROT_CROP_0:
			return TILE_CARROT_0
		BlockId.CARROT_CROP_1:
			return TILE_CARROT_1
		BlockId.CARROT_CROP_2:
			return TILE_CARROT_2
		BlockId.POTATO_CROP_0:
			return TILE_POTATO_0
		BlockId.POTATO_CROP_1:
			return TILE_POTATO_1
		BlockId.POTATO_CROP_2:
			return TILE_POTATO_2
		BlockId.RICE_CROP_0:
			return TILE_RICE_0
		BlockId.RICE_CROP_1:
			return TILE_RICE_1
		BlockId.RICE_CROP_2:
			return TILE_RICE_2
		BlockId.TOMATO_CROP_0:
			return TILE_TOMATO_0
		BlockId.TOMATO_CROP_1:
			return TILE_TOMATO_1
		BlockId.TOMATO_CROP_2:
			return TILE_TOMATO_2
		BlockId.CUCUMBER_CROP_0:
			return TILE_CUCUMBER_0
		BlockId.CUCUMBER_CROP_1:
			return TILE_CUCUMBER_1
		BlockId.CUCUMBER_CROP_2:
			return TILE_CUCUMBER_2
		BlockId.STRAWBERRY_BUSH_0, BlockId.STRAWBERRY_BUSH_1, BlockId.STRAWBERRY_BUSH_2:
			return TILE_STRAWBERRY_BUSH
		BlockId.BLUEBERRY_BUSH_0, BlockId.BLUEBERRY_BUSH_1, BlockId.BLUEBERRY_BUSH_2:
			return TILE_BLUEBERRY_BUSH
		BlockId.BLACKBERRY_BUSH_0, BlockId.BLACKBERRY_BUSH_1, BlockId.BLACKBERRY_BUSH_2:
			return TILE_BLACKBERRY_BUSH
		BlockId.MANGO_SAPLING:
			return TILE_MANGO_SAPLING
		BlockId.MANGO_LEAVES:
			return TILE_MANGO_LEAVES
		BlockId.DISPLAY_CASE:
			return TILE_GLASS
		_:
			return -1

static func get_face_uv_rect(block_id: int, face_index: int) -> Rect2:
	return _get_uv_rect_from_tile(get_face_tile_index(block_id, face_index))

static func get_hotbar_region_pixels(block_id: int) -> Rect2:
	var tile_index: int = get_hotbar_tile_index(block_id)
	if tile_index < 0:
		return Rect2()
	var column: int = posmod(tile_index, ATLAS_COLUMNS)
	var row: int = _get_tile_row(tile_index)
	return Rect2(float(column * ATLAS_TILE_SIZE), float(row * ATLAS_TILE_SIZE), float(ATLAS_TILE_SIZE), float(ATLAS_TILE_SIZE))

static func get_face_region_pixels(block_id: int, face_index: int) -> Rect2:
	var tile_index: int = get_face_tile_index(block_id, face_index)
	if tile_index < 0:
		return Rect2()
	var column: int = posmod(tile_index, ATLAS_COLUMNS)
	var row: int = _get_tile_row(tile_index)
	return Rect2(float(column * ATLAS_TILE_SIZE), float(row * ATLAS_TILE_SIZE), float(ATLAS_TILE_SIZE), float(ATLAS_TILE_SIZE))

static func _get_uv_rect_from_tile(tile_index: int) -> Rect2:
	if tile_index < 0:
		return Rect2()
	var uv_tile_width: float = 1.0 / float(ATLAS_COLUMNS)
	var uv_tile_height: float = 1.0 / float(ATLAS_ROWS)
	var column: int = posmod(tile_index, ATLAS_COLUMNS)
	var row: int = _get_tile_row(tile_index)
	var atlas_width_px: float = float(ATLAS_TILE_SIZE * ATLAS_COLUMNS)
	var atlas_height_px: float = float(ATLAS_TILE_SIZE * ATLAS_ROWS)
	var padding_u: float = 1.0 / atlas_width_px
	var padding_v: float = 1.0 / atlas_height_px
	return Rect2(
		(float(column) * uv_tile_width) + padding_u,
		(float(row) * uv_tile_height) + padding_v,
		uv_tile_width - (padding_u * 2.0),
		uv_tile_height - (padding_v * 2.0)
	)

static func _get_tile_row(tile_index: int) -> int:
	return int(floor(float(tile_index) / float(ATLAS_COLUMNS)))

static func get_break_hardness(block_id: int) -> float:
	match block_id:
		BlockId.GRASS, BlockId.DIRT, BlockId.SAND:
			return 0.65
		BlockId.OAK_LEAVES:
			return 0.25
		BlockId.OAK_LOG:
			return 2.0
		BlockId.OAK_PLANKS:
			return 2.0
		BlockId.CRAFTING_TABLE:
			return 2.5
		BlockId.PREP_TABLE:
			return 2.4
		BlockId.STOVE:
			return 3.0
		BlockId.OVEN:
			return 3.2
		BlockId.FERMENTER:
			return 2.1
		BlockId.BLENDER:
			return 1.8
		BlockId.DISPLAY_CASE:
			return 1.2
		BlockId.STONE:
			return 2.2
		BlockId.COBBLESTONE:
			return 2.4
		BlockId.FURNACE:
			return 3.2
		BlockId.COAL_ORE:
			return 3.0
		BlockId.IRON_ORE:
			return 3.2
		BlockId.GLASS:
			return 0.5
		BlockId.FARMLAND:
			return 0.7
		BlockId.WHEAT_CROP_0, BlockId.WHEAT_CROP_1, BlockId.WHEAT_CROP_2, BlockId.CARROT_CROP_0, BlockId.CARROT_CROP_1, BlockId.CARROT_CROP_2, BlockId.POTATO_CROP_0, BlockId.POTATO_CROP_1, BlockId.POTATO_CROP_2, BlockId.RICE_CROP_0, BlockId.RICE_CROP_1, BlockId.RICE_CROP_2, BlockId.TOMATO_CROP_0, BlockId.TOMATO_CROP_1, BlockId.TOMATO_CROP_2, BlockId.CUCUMBER_CROP_0, BlockId.CUCUMBER_CROP_1, BlockId.CUCUMBER_CROP_2, BlockId.STRAWBERRY_BUSH_0, BlockId.STRAWBERRY_BUSH_1, BlockId.STRAWBERRY_BUSH_2, BlockId.BLUEBERRY_BUSH_0, BlockId.BLUEBERRY_BUSH_1, BlockId.BLUEBERRY_BUSH_2, BlockId.BLACKBERRY_BUSH_0, BlockId.BLACKBERRY_BUSH_1, BlockId.BLACKBERRY_BUSH_2, BlockId.MANGO_SAPLING:
			return 0.1
		BlockId.MANGO_LEAVES:
			return 0.2
		BlockId.WATER, BlockId.WATER_FLOW_7, BlockId.WATER_FLOW_6, BlockId.WATER_FLOW_5, BlockId.WATER_FLOW_4, BlockId.WATER_FLOW_3, BlockId.WATER_FLOW_2, BlockId.WATER_FLOW_1:
			return 0.0
		_:
			return 1.0

static func get_preferred_tool(block_id: int) -> String:
	match block_id:
		BlockId.STONE, BlockId.COBBLESTONE, BlockId.FURNACE, BlockId.COAL_ORE, BlockId.IRON_ORE:
			return "pickaxe"
		BlockId.OAK_LOG, BlockId.OAK_PLANKS, BlockId.CRAFTING_TABLE, BlockId.PREP_TABLE, BlockId.FERMENTER:
			return "axe"
		BlockId.STOVE, BlockId.OVEN, BlockId.BLENDER:
			return "pickaxe"
		BlockId.DISPLAY_CASE:
			return "axe"
		_:
			return ""

static func get_required_tool_tier(block_id: int) -> int:
	match block_id:
		BlockId.STONE, BlockId.COBBLESTONE, BlockId.COAL_ORE, BlockId.IRON_ORE, BlockId.FURNACE, BlockId.STOVE, BlockId.OVEN, BlockId.BLENDER:
			return 1
		BlockId.DISPLAY_CASE:
			return 0
		_:
			return 0

static func requires_correct_tool_for_drop(block_id: int) -> bool:
	return get_required_tool_tier(block_id) > 0


static func is_plant_block(block_id: int) -> bool:
	return block_id >= BlockId.WHEAT_CROP_0 and block_id <= BlockId.CUCUMBER_CROP_2

static func is_bush_block(block_id: int) -> bool:
	return block_id >= BlockId.STRAWBERRY_BUSH_0 and block_id <= BlockId.BLACKBERRY_BUSH_2

static func get_custom_mesh_kind(block_id: int) -> String:
	if is_plant_block(block_id) or block_id == BlockId.MANGO_SAPLING:
		return "cross"
	if is_bush_block(block_id):
		return "bush"
	return "cube"

static func get_visual_height(block_id: int) -> float:
	match block_id:
		BlockId.WHEAT_CROP_0, BlockId.CARROT_CROP_0, BlockId.POTATO_CROP_0, BlockId.RICE_CROP_0, BlockId.TOMATO_CROP_0, BlockId.CUCUMBER_CROP_0:
			return 0.36
		BlockId.WHEAT_CROP_1, BlockId.CARROT_CROP_1, BlockId.POTATO_CROP_1, BlockId.RICE_CROP_1, BlockId.TOMATO_CROP_1, BlockId.CUCUMBER_CROP_1:
			return 0.64
		BlockId.WHEAT_CROP_2, BlockId.CARROT_CROP_2, BlockId.POTATO_CROP_2, BlockId.RICE_CROP_2, BlockId.TOMATO_CROP_2, BlockId.CUCUMBER_CROP_2, BlockId.MANGO_SAPLING:
			return 0.96
		BlockId.STRAWBERRY_BUSH_0, BlockId.BLUEBERRY_BUSH_0, BlockId.BLACKBERRY_BUSH_0:
			return 0.42
		BlockId.STRAWBERRY_BUSH_1, BlockId.BLUEBERRY_BUSH_1, BlockId.BLACKBERRY_BUSH_1:
			return 0.62
		BlockId.STRAWBERRY_BUSH_2, BlockId.BLUEBERRY_BUSH_2, BlockId.BLACKBERRY_BUSH_2:
			return 0.82
		_:
			return 1.0
