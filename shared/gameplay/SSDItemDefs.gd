extends RefCounted
class_name SSDItemDefs

const NAMESPACE_PREFIX: String = "SSD:"

const ITEM_AIR: int = 0
const ITEM_GRASS: int = SSDVoxelDefs.BlockId.GRASS
const ITEM_DIRT: int = SSDVoxelDefs.BlockId.DIRT
const ITEM_STONE: int = SSDVoxelDefs.BlockId.STONE
const ITEM_OAK_LOG: int = SSDVoxelDefs.BlockId.OAK_LOG
const ITEM_OAK_LEAVES: int = SSDVoxelDefs.BlockId.OAK_LEAVES
const ITEM_OAK_PLANKS: int = SSDVoxelDefs.BlockId.OAK_PLANKS
const ITEM_CRAFTING_TABLE: int = SSDVoxelDefs.BlockId.CRAFTING_TABLE
const ITEM_COBBLESTONE: int = SSDVoxelDefs.BlockId.COBBLESTONE
const ITEM_FURNACE: int = SSDVoxelDefs.BlockId.FURNACE
const ITEM_WATER: int = SSDVoxelDefs.BlockId.WATER
const ITEM_COAL_ORE: int = SSDVoxelDefs.BlockId.COAL_ORE
const ITEM_IRON_ORE: int = SSDVoxelDefs.BlockId.IRON_ORE
const ITEM_SAND: int = SSDVoxelDefs.BlockId.SAND
const ITEM_GLASS: int = SSDVoxelDefs.BlockId.GLASS

const ITEM_WOOL: int = 1003
const ITEM_LEATHER: int = 1004
const ITEM_FEATHER: int = 1005
const ITEM_RAW_MUTTON: int = 1006
const ITEM_RAW_BEEF: int = 1007
const ITEM_RAW_CHICKEN: int = 1008
const ITEM_COOKED_MUTTON: int = 1009
const ITEM_COOKED_BEEF: int = 1010
const ITEM_COOKED_CHICKEN: int = 1011
const ITEM_STICK: int = 1012
const ITEM_COAL: int = 1013
const ITEM_IRON_CHUNK: int = 1014
const ITEM_IRON_INGOT: int = 1015
const ITEM_GLASS_BOTTLE: int = 1016
const ITEM_WATER_BOTTLE: int = 1017
const ITEM_WOODEN_PICKAXE: int = 1018
const ITEM_STONE_PICKAXE: int = 1019
const ITEM_IRON_PICKAXE: int = 1020
const ITEM_WOODEN_AXE: int = 1021
const ITEM_STONE_AXE: int = 1022
const ITEM_IRON_AXE: int = 1023
const ITEM_SHEEP_SPAWN_EGG: int = 1024
const ITEM_COW_SPAWN_EGG: int = 1025
const ITEM_CHICKEN_SPAWN_EGG: int = 1026

const ITEM_SHIRT_RED: int = 1101
const ITEM_HOODIE_RED: int = 1102

const GRASS_ICON: Texture2D = preload("res://assets/textures/items/grass_block.png")
const DIRT_ICON: Texture2D = preload("res://assets/textures/items/dirt_block.png")
const STONE_ICON: Texture2D = preload("res://assets/textures/items/stone_block.png")
const OAK_LOG_ICON: Texture2D = preload("res://assets/textures/items/oak_log.png")
const OAK_LEAVES_ICON: Texture2D = preload("res://assets/textures/items/oak_leaves.png")
const OAK_PLANKS_ICON: Texture2D = preload("res://assets/textures/items/oak_planks.png")
const CRAFTING_TABLE_ICON: Texture2D = preload("res://assets/textures/items/crafting_table.png")
const COBBLESTONE_ICON: Texture2D = preload("res://assets/textures/items/cobblestone.png")
const FURNACE_ICON: Texture2D = preload("res://assets/textures/items/furnace.png")
const WATER_ICON: Texture2D = preload("res://assets/textures/items/water_block.png")
const COAL_ORE_ICON: Texture2D = preload("res://assets/textures/items/coal_ore.png")
const IRON_ORE_ICON: Texture2D = preload("res://assets/textures/items/iron_ore.png")
const SAND_ICON: Texture2D = preload("res://assets/textures/items/sand_block.png")
const GLASS_ICON: Texture2D = preload("res://assets/textures/items/glass_block.png")
const WOOL_ICON: Texture2D = preload("res://assets/textures/items/wool.png")
const LEATHER_ICON: Texture2D = preload("res://assets/textures/items/leather.png")
const FEATHER_ICON: Texture2D = preload("res://assets/textures/items/feather.png")
const RAW_MUTTON_ICON: Texture2D = preload("res://assets/textures/items/raw_mutton.png")
const RAW_BEEF_ICON: Texture2D = preload("res://assets/textures/items/raw_beef.png")
const RAW_CHICKEN_ICON: Texture2D = preload("res://assets/textures/items/raw_chicken.png")
const COOKED_MUTTON_ICON: Texture2D = preload("res://assets/textures/items/cooked_mutton.png")
const COOKED_BEEF_ICON: Texture2D = preload("res://assets/textures/items/cooked_beef.png")
const COOKED_CHICKEN_ICON: Texture2D = preload("res://assets/textures/items/cooked_chicken.png")
const STEAK_ICON: Texture2D = preload("res://assets/textures/items/steak.png")
const STICK_ICON: Texture2D = preload("res://assets/textures/items/stick.png")
const COAL_ICON: Texture2D = preload("res://assets/textures/items/coal.png")
const IRON_CHUNK_ICON: Texture2D = preload("res://assets/textures/items/iron_chunk.png")
const IRON_INGOT_ICON: Texture2D = preload("res://assets/textures/items/iron_ingot.png")
const GLASS_BOTTLE_ICON: Texture2D = preload("res://assets/textures/items/glass_bottle.png")
const WATER_BOTTLE_ICON: Texture2D = preload("res://assets/textures/items/water_bottle.png")
const WOODEN_PICKAXE_ICON: Texture2D = preload("res://assets/textures/items/wooden_pickaxe.png")
const STONE_PICKAXE_ICON: Texture2D = preload("res://assets/textures/items/stone_pickaxe.png")
const IRON_PICKAXE_ICON: Texture2D = preload("res://assets/textures/items/iron_pickaxe.png")
const WOODEN_AXE_ICON: Texture2D = preload("res://assets/textures/items/wooden_axe.png")
const STONE_AXE_ICON: Texture2D = preload("res://assets/textures/items/stone_axe.png")
const IRON_AXE_ICON: Texture2D = preload("res://assets/textures/items/iron_axe.png")
const SHEEP_SPAWN_EGG_ICON: Texture2D = preload("res://assets/textures/items/sheep_spawn_egg.png")
const COW_SPAWN_EGG_ICON: Texture2D = preload("res://assets/textures/items/cow_spawn_egg.png")
const CHICKEN_SPAWN_EGG_ICON: Texture2D = preload("res://assets/textures/items/chicken_spawn_egg.png")
const SHIRT_TEXTURE: Texture2D = preload("res://assets/textures/player/shirt_under.png")
const HOODIE_TEXTURE: Texture2D = preload("res://assets/textures/player/hoodie_outer.png")

const CREATIVE_CATEGORY_NAMES: PackedStringArray = [
    "All",
    "Blocks",
    "Items",
    "Tools",
    "Food",
    "Spawn Eggs",
]

const CREATIVE_CATEGORY_ALL: int = 0
const CREATIVE_CATEGORY_BLOCKS: int = 1
const CREATIVE_CATEGORY_ITEMS: int = 2
const CREATIVE_CATEGORY_TOOLS: int = 3
const CREATIVE_CATEGORY_FOOD: int = 4
const CREATIVE_CATEGORY_SPAWN_EGGS: int = 5

static func is_block(item_id: int) -> bool:
    return item_id > 0 and item_id < 1000 and item_id != ITEM_WATER

static func is_placeable_block(item_id: int) -> bool:
    return item_id > 0 and item_id < 1000

static func is_equipment_item(item_id: int) -> bool:
    return not get_equipment_slot_name(item_id).is_empty()

static func get_equipment_slot_name(item_id: int) -> String:
    match item_id:
        ITEM_SHIRT_RED:
            return "Shirt"
        ITEM_HOODIE_RED:
            return "Jacket"
        _:
            return ""

static func can_equip_in_slot(item_id: int, slot_name: String) -> bool:
    if slot_name.is_empty():
        return true
    return get_equipment_slot_name(item_id) == slot_name

static func get_display_name(item_id: int) -> String:
    if item_id > 0 and item_id < 1000:
        return SSDVoxelDefs.get_display_name(item_id)
    match item_id:
        ITEM_WOOL:
            return "Wool"
        ITEM_LEATHER:
            return "Leather"
        ITEM_FEATHER:
            return "Feather"
        ITEM_RAW_MUTTON:
            return "Raw Mutton"
        ITEM_RAW_BEEF:
            return "Raw Beef"
        ITEM_RAW_CHICKEN:
            return "Raw Chicken"
        ITEM_COOKED_MUTTON:
            return "Cooked Mutton"
        ITEM_COOKED_BEEF:
            return "Cooked Beef"
        ITEM_COOKED_CHICKEN:
            return "Cooked Chicken"
        ITEM_STICK:
            return "Stick"
        ITEM_COAL:
            return "Coal"
        ITEM_IRON_CHUNK:
            return "Iron Chunk"
        ITEM_IRON_INGOT:
            return "Iron Ingot"
        ITEM_GLASS_BOTTLE:
            return "Glass Bottle"
        ITEM_WATER_BOTTLE:
            return "Bottle of Water"
        ITEM_WOODEN_PICKAXE:
            return "Wooden Pickaxe"
        ITEM_STONE_PICKAXE:
            return "Stone Pickaxe"
        ITEM_IRON_PICKAXE:
            return "Iron Pickaxe"
        ITEM_WOODEN_AXE:
            return "Wooden Axe"
        ITEM_STONE_AXE:
            return "Stone Axe"
        ITEM_IRON_AXE:
            return "Iron Axe"
        ITEM_SHEEP_SPAWN_EGG:
            return "Sheep Spawn Egg"
        ITEM_COW_SPAWN_EGG:
            return "Cow Spawn Egg"
        ITEM_CHICKEN_SPAWN_EGG:
            return "Chicken Spawn Egg"
        ITEM_SHIRT_RED:
            return "Red Shirt"
        ITEM_HOODIE_RED:
            return "Red Hoodie"
        ITEM_AIR:
            return "Empty"
        _:
            return "Unknown"

static func get_item_name(item_id: int) -> String:
    if item_id > 0 and item_id < 1000:
        return SSDVoxelDefs.get_block_name(item_id)
    match item_id:
        ITEM_WOOL:
            return "wool"
        ITEM_LEATHER:
            return "leather"
        ITEM_FEATHER:
            return "feather"
        ITEM_RAW_MUTTON:
            return "raw_mutton"
        ITEM_RAW_BEEF:
            return "raw_beef"
        ITEM_RAW_CHICKEN:
            return "raw_chicken"
        ITEM_COOKED_MUTTON:
            return "cooked_mutton"
        ITEM_COOKED_BEEF:
            return "cooked_beef"
        ITEM_COOKED_CHICKEN:
            return "cooked_chicken"
        ITEM_STICK:
            return "stick"
        ITEM_COAL:
            return "coal"
        ITEM_IRON_CHUNK:
            return "iron_chunk"
        ITEM_IRON_INGOT:
            return "iron_ingot"
        ITEM_GLASS_BOTTLE:
            return "glass_bottle"
        ITEM_WATER_BOTTLE:
            return "water_bottle"
        ITEM_WOODEN_PICKAXE:
            return "wooden_pickaxe"
        ITEM_STONE_PICKAXE:
            return "stone_pickaxe"
        ITEM_IRON_PICKAXE:
            return "iron_pickaxe"
        ITEM_WOODEN_AXE:
            return "wooden_axe"
        ITEM_STONE_AXE:
            return "stone_axe"
        ITEM_IRON_AXE:
            return "iron_axe"
        ITEM_SHEEP_SPAWN_EGG:
            return "sheep_spawn_egg"
        ITEM_COW_SPAWN_EGG:
            return "cow_spawn_egg"
        ITEM_CHICKEN_SPAWN_EGG:
            return "chicken_spawn_egg"
        ITEM_SHIRT_RED:
            return "red_shirt"
        ITEM_HOODIE_RED:
            return "red_hoodie"
        ITEM_AIR:
            return "air"
        _:
            return "unknown"

static func get_namespaced_id(item_id: int) -> String:
    if item_id == ITEM_AIR:
        return "EMPTY"
    return "%s%s" % [NAMESPACE_PREFIX, get_item_name(item_id)]

static func get_display_id(item_id: int) -> String:
    if item_id == ITEM_AIR:
        return "EMPTY"
    return "%s [%d]" % [get_namespaced_id(item_id), item_id]

static func get_tooltip_lines(item_id: int) -> PackedStringArray:
    if item_id == ITEM_AIR:
        return PackedStringArray([])
    return PackedStringArray([get_display_name(item_id), get_display_id(item_id)])

static func get_inventory_icon_texture(item_id: int) -> Texture2D:
    match item_id:
        ITEM_GRASS:
            return GRASS_ICON
        ITEM_DIRT:
            return DIRT_ICON
        ITEM_STONE:
            return STONE_ICON
        ITEM_OAK_LOG:
            return OAK_LOG_ICON
        ITEM_OAK_LEAVES:
            return OAK_LEAVES_ICON
        ITEM_OAK_PLANKS:
            return OAK_PLANKS_ICON
        ITEM_CRAFTING_TABLE:
            return CRAFTING_TABLE_ICON
        ITEM_COBBLESTONE:
            return COBBLESTONE_ICON
        ITEM_FURNACE:
            return FURNACE_ICON
        ITEM_WATER:
            return WATER_ICON
        ITEM_COAL_ORE:
            return COAL_ORE_ICON
        ITEM_IRON_ORE:
            return IRON_ORE_ICON
        ITEM_SAND:
            return SAND_ICON
        ITEM_GLASS:
            return GLASS_ICON
        ITEM_WOOL:
            return WOOL_ICON
        ITEM_LEATHER:
            return LEATHER_ICON
        ITEM_FEATHER:
            return FEATHER_ICON
        ITEM_RAW_MUTTON:
            return RAW_MUTTON_ICON
        ITEM_RAW_BEEF:
            return RAW_BEEF_ICON
        ITEM_RAW_CHICKEN:
            return RAW_CHICKEN_ICON
        ITEM_COOKED_MUTTON:
            return COOKED_MUTTON_ICON
        ITEM_COOKED_BEEF:
            return COOKED_BEEF_ICON
        ITEM_COOKED_CHICKEN:
            return COOKED_CHICKEN_ICON
        ITEM_STICK:
            return STICK_ICON
        ITEM_COAL:
            return COAL_ICON
        ITEM_IRON_CHUNK:
            return IRON_CHUNK_ICON
        ITEM_IRON_INGOT:
            return IRON_INGOT_ICON
        ITEM_GLASS_BOTTLE:
            return GLASS_BOTTLE_ICON
        ITEM_WATER_BOTTLE:
            return WATER_BOTTLE_ICON
        ITEM_WOODEN_PICKAXE:
            return WOODEN_PICKAXE_ICON
        ITEM_STONE_PICKAXE:
            return STONE_PICKAXE_ICON
        ITEM_IRON_PICKAXE:
            return IRON_PICKAXE_ICON
        ITEM_WOODEN_AXE:
            return WOODEN_AXE_ICON
        ITEM_STONE_AXE:
            return STONE_AXE_ICON
        ITEM_IRON_AXE:
            return IRON_AXE_ICON
        ITEM_SHEEP_SPAWN_EGG:
            return SHEEP_SPAWN_EGG_ICON
        ITEM_COW_SPAWN_EGG:
            return COW_SPAWN_EGG_ICON
        ITEM_CHICKEN_SPAWN_EGG:
            return CHICKEN_SPAWN_EGG_ICON
        ITEM_SHIRT_RED:
            return SHIRT_TEXTURE
        ITEM_HOODIE_RED:
            return HOODIE_TEXTURE
        _:
            return null

static func resolve_item_token(token: String) -> int:
    var cleaned: String = token.strip_edges()
    if cleaned.is_empty():
        return ITEM_AIR
    if cleaned.is_valid_int():
        var numeric_id: int = cleaned.to_int()
        if numeric_id == ITEM_AIR:
            return ITEM_AIR
        if numeric_id > 0 and numeric_id < 2000:
            return numeric_id
    var lowered: String = cleaned.to_lower()
    if lowered.begins_with(NAMESPACE_PREFIX.to_lower()):
        lowered = lowered.substr(NAMESPACE_PREFIX.length())
    match lowered:
        "grass":
            return ITEM_GRASS
        "dirt":
            return ITEM_DIRT
        "stone":
            return ITEM_STONE
        "oak_log", "log":
            return ITEM_OAK_LOG
        "oak_leaves", "leaves":
            return ITEM_OAK_LEAVES
        "oak_planks", "planks", "plank":
            return ITEM_OAK_PLANKS
        "crafting_table", "table":
            return ITEM_CRAFTING_TABLE
        "cobblestone", "cobble":
            return ITEM_COBBLESTONE
        "furnace":
            return ITEM_FURNACE
        "water":
            return ITEM_WATER
        "coal_ore":
            return ITEM_COAL_ORE
        "iron_ore":
            return ITEM_IRON_ORE
        "sand":
            return ITEM_SAND
        "glass":
            return ITEM_GLASS
        "coal":
            return ITEM_COAL
        "iron_chunk", "raw_iron":
            return ITEM_IRON_CHUNK
        "iron_ingot", "iron":
            return ITEM_IRON_INGOT
        "wool":
            return ITEM_WOOL
        "leather":
            return ITEM_LEATHER
        "feather", "feathers":
            return ITEM_FEATHER
        "raw_mutton":
            return ITEM_RAW_MUTTON
        "raw_beef":
            return ITEM_RAW_BEEF
        "raw_chicken":
            return ITEM_RAW_CHICKEN
        "cooked_mutton", "mutton":
            return ITEM_COOKED_MUTTON
        "cooked_beef", "beef", "steak":
            return ITEM_COOKED_BEEF
        "cooked_chicken", "chicken":
            return ITEM_COOKED_CHICKEN
        "stick", "sticks":
            return ITEM_STICK
        "glass_bottle", "bottle":
            return ITEM_GLASS_BOTTLE
        "water_bottle", "bottle_of_water":
            return ITEM_WATER_BOTTLE
        "wooden_pickaxe", "wood_pickaxe":
            return ITEM_WOODEN_PICKAXE
        "stone_pickaxe":
            return ITEM_STONE_PICKAXE
        "iron_pickaxe":
            return ITEM_IRON_PICKAXE
        "wooden_axe", "wood_axe":
            return ITEM_WOODEN_AXE
        "stone_axe":
            return ITEM_STONE_AXE
        "iron_axe":
            return ITEM_IRON_AXE
        "sheep_spawn_egg":
            return ITEM_SHEEP_SPAWN_EGG
        "cow_spawn_egg":
            return ITEM_COW_SPAWN_EGG
        "chicken_spawn_egg":
            return ITEM_CHICKEN_SPAWN_EGG
        "red_shirt", "shirt":
            return ITEM_SHIRT_RED
        "red_hoodie", "hoodie", "jacket":
            return ITEM_HOODIE_RED
        _:
            return ITEM_AIR

static func get_creative_category_name(index: int) -> String:
    if index < 0 or index >= CREATIVE_CATEGORY_NAMES.size():
        return CREATIVE_CATEGORY_NAMES[CREATIVE_CATEGORY_ALL]
    return CREATIVE_CATEGORY_NAMES[index]

static func get_all_creative_item_ids() -> PackedInt32Array:
    return PackedInt32Array([
        ITEM_GRASS,
        ITEM_DIRT,
        ITEM_STONE,
        ITEM_SAND,
        ITEM_GLASS,
        ITEM_WATER,
        ITEM_COAL_ORE,
        ITEM_IRON_ORE,
        ITEM_OAK_LOG,
        ITEM_OAK_LEAVES,
        ITEM_OAK_PLANKS,
        ITEM_CRAFTING_TABLE,
        ITEM_COBBLESTONE,
        ITEM_FURNACE,
        ITEM_SHIRT_RED,
        ITEM_HOODIE_RED,
        ITEM_WOOL,
        ITEM_LEATHER,
        ITEM_FEATHER,
        ITEM_STICK,
        ITEM_COAL,
        ITEM_IRON_CHUNK,
        ITEM_IRON_INGOT,
        ITEM_GLASS_BOTTLE,
        ITEM_WATER_BOTTLE,
        ITEM_WOODEN_PICKAXE,
        ITEM_STONE_PICKAXE,
        ITEM_IRON_PICKAXE,
        ITEM_WOODEN_AXE,
        ITEM_STONE_AXE,
        ITEM_IRON_AXE,
        ITEM_RAW_MUTTON,
        ITEM_RAW_BEEF,
        ITEM_RAW_CHICKEN,
        ITEM_COOKED_MUTTON,
        ITEM_COOKED_BEEF,
        ITEM_COOKED_CHICKEN,
        ITEM_SHEEP_SPAWN_EGG,
        ITEM_COW_SPAWN_EGG,
        ITEM_CHICKEN_SPAWN_EGG,
    ])

static func get_creative_item_ids(category_index: int) -> PackedInt32Array:
    match category_index:
        CREATIVE_CATEGORY_ALL:
            return get_all_creative_item_ids()
        CREATIVE_CATEGORY_BLOCKS:
            return PackedInt32Array([
                ITEM_GRASS,
                ITEM_DIRT,
                ITEM_STONE,
                ITEM_SAND,
                ITEM_GLASS,
                ITEM_WATER,
                ITEM_COAL_ORE,
                ITEM_IRON_ORE,
                ITEM_OAK_LOG,
                ITEM_OAK_LEAVES,
                ITEM_OAK_PLANKS,
                ITEM_CRAFTING_TABLE,
                ITEM_COBBLESTONE,
                ITEM_FURNACE,
            ])
        CREATIVE_CATEGORY_ITEMS:
            return PackedInt32Array([
                ITEM_SHIRT_RED,
                ITEM_HOODIE_RED,
                ITEM_WOOL,
                ITEM_LEATHER,
                ITEM_FEATHER,
                ITEM_STICK,
                ITEM_COAL,
                ITEM_IRON_CHUNK,
                ITEM_IRON_INGOT,
                ITEM_GLASS_BOTTLE,
                ITEM_WATER_BOTTLE,
            ])
        CREATIVE_CATEGORY_TOOLS:
            return PackedInt32Array([
                ITEM_WOODEN_PICKAXE,
                ITEM_STONE_PICKAXE,
                ITEM_IRON_PICKAXE,
                ITEM_WOODEN_AXE,
                ITEM_STONE_AXE,
                ITEM_IRON_AXE,
            ])
        CREATIVE_CATEGORY_FOOD:
            return PackedInt32Array([
                ITEM_RAW_MUTTON,
                ITEM_RAW_BEEF,
                ITEM_RAW_CHICKEN,
                ITEM_COOKED_MUTTON,
                ITEM_COOKED_BEEF,
                ITEM_COOKED_CHICKEN,
                ITEM_WATER_BOTTLE,
            ])
        CREATIVE_CATEGORY_SPAWN_EGGS:
            return PackedInt32Array([
                ITEM_SHEEP_SPAWN_EGG,
                ITEM_COW_SPAWN_EGG,
                ITEM_CHICKEN_SPAWN_EGG,
            ])
        _:
            return PackedInt32Array([])

static func is_tool(item_id: int) -> bool:
    return get_tool_type(item_id) != ""

static func get_tool_type(item_id: int) -> String:
    match item_id:
        ITEM_WOODEN_PICKAXE, ITEM_STONE_PICKAXE, ITEM_IRON_PICKAXE:
            return "pickaxe"
        ITEM_WOODEN_AXE, ITEM_STONE_AXE, ITEM_IRON_AXE:
            return "axe"
        _:
            return ""

static func get_tool_tier(item_id: int) -> int:
    match item_id:
        ITEM_WOODEN_PICKAXE, ITEM_WOODEN_AXE:
            return 1
        ITEM_STONE_PICKAXE, ITEM_STONE_AXE:
            return 2
        ITEM_IRON_PICKAXE, ITEM_IRON_AXE:
            return 3
        _:
            return 0

static func get_tool_break_speed(item_id: int) -> float:
    match item_id:
        ITEM_WOODEN_PICKAXE, ITEM_WOODEN_AXE:
            return 2.2
        ITEM_STONE_PICKAXE, ITEM_STONE_AXE:
            return 3.6
        ITEM_IRON_PICKAXE, ITEM_IRON_AXE:
            return 5.2
        _:
            return 1.0

static func is_consumable(item_id: int) -> bool:
    return get_hunger_restore(item_id) > 0.0 or get_thirst_restore(item_id) > 0.0

static func get_hunger_restore(item_id: int) -> float:
    match item_id:
        ITEM_RAW_MUTTON:
            return 10.0
        ITEM_RAW_BEEF:
            return 9.0
        ITEM_RAW_CHICKEN:
            return 8.0
        ITEM_COOKED_MUTTON:
            return 22.0
        ITEM_COOKED_BEEF:
            return 26.0
        ITEM_COOKED_CHICKEN:
            return 18.0
        _:
            return 0.0

static func get_thirst_restore(item_id: int) -> float:
    match item_id:
        ITEM_WATER_BOTTLE:
            return 34.0
        ITEM_RAW_CHICKEN:
            return 2.0
        ITEM_RAW_BEEF:
            return 1.0
        ITEM_RAW_MUTTON:
            return 1.0
        ITEM_COOKED_CHICKEN:
            return 3.0
        ITEM_COOKED_BEEF:
            return 2.0
        ITEM_COOKED_MUTTON:
            return 2.0
        _:
            return 0.0

static func get_stamina_restore(item_id: int) -> float:
    match item_id:
        ITEM_WATER_BOTTLE:
            return 10.0
        ITEM_COOKED_BEEF:
            return 7.0
        ITEM_COOKED_MUTTON:
            return 6.0
        ITEM_COOKED_CHICKEN:
            return 5.0
        _:
            return 0.0

static func get_consumed_return_item_id(item_id: int) -> int:
    if item_id == ITEM_WATER_BOTTLE:
        return ITEM_GLASS_BOTTLE
    return ITEM_AIR

static func is_spawn_egg(item_id: int) -> bool:
    return get_spawn_egg_mob_type(item_id) != ""

static func get_spawn_egg_mob_type(item_id: int) -> String:
    match item_id:
        ITEM_SHEEP_SPAWN_EGG:
            return "sheep"
        ITEM_COW_SPAWN_EGG:
            return "cow"
        ITEM_CHICKEN_SPAWN_EGG:
            return "chicken"
        _:
            return ""
