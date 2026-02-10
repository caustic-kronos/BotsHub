#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributors: Gahais, JackLinesMatthews
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
#CE ===========================================================================

#include-once
#include <Array.au3>
#include 'Utils.au3'


#Region Item Type IDs
Global Const $ID_TYPE_ARMOR_SALVAGE			= 0
Global Const $TYPE_LEADHAND					= 1		;?
Global Const $ID_TYPE_AXE					= 2
Global Const $ID_TYPE_BAG					= 3
Global Const $ID_TYPE_FOOT_ARMOR			= 4
Global Const $ID_TYPE_BOW					= 5
Global Const $ID_TYPE_BUNDLE				= 6
Global Const $ID_TYPE_CHEST_ARMOR			= 7
Global Const $ID_TYPE_UPGRADE				= 8
Global Const $ID_TYPE_USABLE				= 9
Global Const $ID_TYPE_DYE					= 10
Global Const $ID_TYPE_MATERIAL				= 11	;Also includes Zcoins
Global Const $ID_TYPE_OFFHAND				= 12
Global Const $ID_TYPE_HAND_ARMOR			= 13
Global Const $ID_TYPE_CELESTIAL_SIGIL		= 14
Global Const $ID_TYPE_HAMMER				= 15
Global Const $ID_TYPE_HEADGEAR_ARMOR		= 16
Global Const $ID_TYPE_TROPHY_2				= 17
Global Const $ID_TYPE_KEY					= 18
Global Const $ID_TYPE_LEG_ARMOR				= 19
Global Const $ID_TYPE_MONEY					= 20
Global Const $ID_TYPE_QUEST_ITEM			= 21
Global Const $ID_TYPE_WAND					= 22
Global Const $ID_TYPE_SHIELD				= 24
Global Const $ID_TYPE_STAFF					= 26
Global Const $ID_TYPE_SWORD					= 27
Global Const $ID_TYPE_KIT					= 29	;? + Keg Ale
Global Const $ID_TYPE_TROPHY				= 30
Global Const $ID_TYPE_SCROLL				= 31
Global Const $ID_TYPE_DAGGER				= 32
Global Const $ID_TYPE_PRESENT				= 33	;?
Global Const $ID_TYPE_MINIPET				= 34
Global Const $ID_TYPE_SCYTHE				= 35
Global Const $ID_TYPE_SPEAR					= 36
Global Const $ID_TYPE_BOOK					= 43
Global Const $ID_TYPE_COSTUME_BODY			= 44
Global Const $ID_TYPE_COSTUME_HEADPIECE		= 45
Global Const $ID_TYPE_UNEQUIPPED			= 46	;?
Global Const $ITEM_TYPES_DOUBLE_ARRAY[][]	= [	[$ID_TYPE_ARMOR_SALVAGE, 'Armor salvage'], [$TYPE_LEADHAND, 'TYPE_LEADHAND ?'], [$ID_TYPE_AXE, 'Axe'], [$ID_TYPE_BAG, 'Bag'], _
													[$ID_TYPE_FOOT_ARMOR, 'Foot armor'], [$ID_TYPE_BOW, 'Bow'], [$ID_TYPE_BUNDLE, 'Bundle'], [$ID_TYPE_CHEST_ARMOR, 'Chest armor'], _
													[$ID_TYPE_UPGRADE, 'Upgrade'], [$ID_TYPE_USABLE, 'Usables'], [$ID_TYPE_DYE, 'Dye'], [$ID_TYPE_MATERIAL, 'Material'], _
													[$ID_TYPE_OFFHAND, 'Offhand'], [$ID_TYPE_HAND_ARMOR, 'Hand armor'], [$ID_TYPE_CELESTIAL_SIGIL, 'Celestial Sigil'], _
													[$ID_TYPE_HAMMER, 'Hammer'], [$ID_TYPE_HEADGEAR_ARMOR, 'Headgear armor'], [$ID_TYPE_TROPHY_2, 'Trophy2'], _
													[$ID_TYPE_KEY, 'Key'], [$ID_TYPE_LEG_ARMOR, 'Leg armor'], [$ID_TYPE_MONEY, 'Money'], [$ID_TYPE_QUEST_ITEM, 'Quest item'], _
													[$ID_TYPE_WAND, 'Wand'], [$ID_TYPE_SHIELD, 'Shield'], [$ID_TYPE_STAFF, 'Staff'], [$ID_TYPE_SWORD, 'Sword'], _
													[$ID_TYPE_KIT, 'Kit'], [$ID_TYPE_TROPHY, 'Trophy'], [$ID_TYPE_SCROLL, 'Scroll'], [$ID_TYPE_DAGGER, 'Dagger'], _
													[$ID_TYPE_PRESENT, 'PRESENT ?'], [$ID_TYPE_MINIPET, 'Minipet'], [$ID_TYPE_SCYTHE, 'Scythe'], [$ID_TYPE_SPEAR, 'Spear'], _
													[$ID_TYPE_BOOK, 'Book'], [$ID_TYPE_COSTUME_BODY, 'Costume body'], [$ID_TYPE_COSTUME_HEADPIECE, 'Costume headpiece'], _
													[$ID_TYPE_UNEQUIPPED, 'TYPE UNEQUIPED ?']]

Global Const $ARMOR_TYPES_ARRAY				= [$ID_TYPE_FOOT_ARMOR, $ID_TYPE_CHEST_ARMOR, $ID_TYPE_HAND_ARMOR, $ID_TYPE_HEADGEAR_ARMOR, $ID_TYPE_LEG_ARMOR]
Global Const $WEAPON_TYPES_ARRAY			= [$ID_TYPE_AXE, $ID_TYPE_BOW, $ID_TYPE_OFFHAND, $ID_TYPE_HAMMER, $ID_TYPE_WAND, $ID_TYPE_SHIELD, $ID_TYPE_STAFF, $ID_TYPE_SWORD, $ID_TYPE_DAGGER, $ID_TYPE_SCYTHE, $ID_TYPE_SPEAR]
Global Const $WEAPON_NAMES_ARRAY			= ['Axe', 'Bow', 'Focus', 'Hammer', 'Wand', 'Shield', 'Staff', 'Sword', 'Dagger', 'Scythe', 'Spear']
Global Const $WEAPON_NAMES_FROM_TYPES		= MapFromArrays($WEAPON_TYPES_ARRAY, $WEAPON_NAMES_ARRAY)
;Global Const $WEAPON_TYPES_FROM_NAMES		= MapFromArrays($WEAPON_NAMES_ARRAY, $WEAPON_TYPES_ARRAY)
Global Const $MAP_ARMOR_TYPES				= MapFromArray($ARMOR_TYPES_ARRAY)
Global Const $MAP_WEAPON_TYPES				= MapFromArray($WEAPON_TYPES_ARRAY)

; Damage relative to the Req							0		1		2		3		4		5		6		7		8		9		10		11		12		13
Global Const $AXE_MAX_DAMAGE_PER_LEVEL				=	[12,	12,		14,		17,		19,		22,		24,		25,		27,		28,		28,		28,		28,		28]
Global Const $BOW_MAX_DAMAGE_PER_LEVEL				=	[13,	14,		16,		18,		20,		22,		24,		25,		27,		28,		28,		28,		28,		28]
Global Const $FOCUS_MAX_DAMAGE_PER_LEVEL			=	[6,		6,		7,		8,		9,		10,		11,		11,		12,		12,		12,		12,		12,		12]
Global Const $HAMMER_MAX_DAMAGE_PER_LEVEL			=	[15,	16,		19,		22,		24,		28,		30,		32,		34,		35,		35,		35,		35,		35]
Global Const $WAND_MAX_DAMAGE_PER_LEVEL				=	[11,	11,		13,		14,		16,		18,		19,		20,		21,		22,		22,		22,		22,		22]
Global Const $SHIELD_MAX_DAMAGE_PER_LEVEL			=	[8,		9,		10,		11,		12,		13,		14,		15,		16,		16,		16,		16,		16,		16]
Global Const $STAFF_MAX_DAMAGE_PER_LEVEL			=	[11,	11,		13,		14,		16,		18,		19,		20,		21,		22,		22,		22,		22,		22]
Global Const $SWORD_MAX_DAMAGE_PER_LEVEL			=	[10,	11,		12,		14,		16,		18,		19,		20,		22,		22,		22,		22,		22,		22]
Global Const $DAGGER_MAX_DAMAGE_PER_LEVEL			=	[8,		8,		9,		11,		12,		13,		14,		15,		16,		17,		17,		17,		17,		17]
Global Const $SCYTHE_MAX_DAMAGE_PER_LEVEL			=	[17,	17,		21,		24,		27,		32,		35,		37,		40,		41,		41,		41,		41,		41]
Global Const $SPEAR_MAX_DAMAGE_PER_LEVEL			=	[12,	13,		15,		17,		19,		21,		23,		25,		26,		27,		27,		27,		27,		27]
Global Const $WEAPONS_MAX_DAMAGE_PER_LEVEL_KEYS		=	[$ID_TYPE_AXE, $ID_TYPE_BOW, $ID_TYPE_OFFHAND, $ID_TYPE_HAMMER, $ID_TYPE_WAND, $ID_TYPE_SHIELD, $ID_TYPE_STAFF, $ID_TYPE_SWORD, $ID_TYPE_DAGGER, $ID_TYPE_SCYTHE, $ID_TYPE_SPEAR]
Global Const $WEAPONS_MAX_DAMAGE_PER_LEVEL_VALUES	=	[$AXE_MAX_DAMAGE_PER_LEVEL, $BOW_MAX_DAMAGE_PER_LEVEL, $FOCUS_MAX_DAMAGE_PER_LEVEL, $HAMMER_MAX_DAMAGE_PER_LEVEL, $WAND_MAX_DAMAGE_PER_LEVEL, $SHIELD_MAX_DAMAGE_PER_LEVEL, _
															$STAFF_MAX_DAMAGE_PER_LEVEL, $SWORD_MAX_DAMAGE_PER_LEVEL, $DAGGER_MAX_DAMAGE_PER_LEVEL, $SCYTHE_MAX_DAMAGE_PER_LEVEL, $SPEAR_MAX_DAMAGE_PER_LEVEL]
Global Const $WEAPONS_MAX_DAMAGE_PER_LEVEL[]		=	MapFromArrays($WEAPONS_MAX_DAMAGE_PER_LEVEL_KEYS, $WEAPONS_MAX_DAMAGE_PER_LEVEL_VALUES)
#EndRegion Item Type IDs


#Region Items
Global Const $ID_MONEY					= 2511

Global Const $RARITY_WHITE				= 2621
Global Const $RARITY_GRAY				= 2622
Global Const $RARITY_BLUE				= 2623
Global Const $RARITY_GOLD				= 2624
Global Const $RARITY_PURPLE				= 2626
Global Const $RARITY_GREEN				= 2627
Global Const $RARITY_RED				= 33026
Global Const $RARITIES_DOUBLE_ARRAY[][]	= [[$RARITY_GRAY, 'Gray'], [$RARITY_WHITE, 'White'], [$RARITY_BLUE, 'Blue'], [$RARITY_PURPLE, 'Purple'], [$RARITY_GOLD, 'Gold'], [$RARITY_GREEN, 'Green'], [$RARITY_RED, 'Red']]
Global Const $RARITY_IDS[]				= [$RARITY_WHITE, $RARITY_GRAY, $RARITY_BLUE, $RARITY_GOLD, $RARITY_PURPLE, $RARITY_GREEN, $RARITY_GREEN, $RARITY_RED]
Global Const $RARITY_NAMES[]				= ['White', 'Gray', 'Blue', 'Gold', 'Purple', 'Green', 'Green', 'Red']
Global Const $RARITY_NAMES_FROM_IDS		= MapFromArrays($RARITY_IDS, $RARITY_NAMES)
;Global Const $RARITY_IDS_FROM_NAMES		= MapFromArrays($RARITY_NAMES, $RARITY_IDS)


#Region Merchant Items
Global Const $ID_BELT_POUCH						= 34
Global Const $ID_BAG							= 35
Global Const $ID_RUNE_OF_HOLDING				= 2988
Global Const $ID_IDENTIFICATION_KIT				= 2989		; 25 uses
Global Const $ID_SUPERIOR_IDENTIFICATION_KIT	= 5899		; 100 uses
Global Const $ID_SALVAGE_KIT					= 2992		; 25 uses
Global Const $ID_SALVAGE_KIT_2					= 2993		; 10 uses
Global Const $ID_EXPERT_SALVAGE_KIT				= 2991		; 25 uses
Global Const $ID_SUPERIOR_SALVAGE_KIT			= 5900		; 100 uses
Global Const $ID_CHARR_SALVAGE_KIT				= 18721		; 5 uses
Global Const $ID_SMALL_EQUIPMENT_PACK			= 31221
Global Const $ID_LIGHT_EQUIPMENT_PACK			= 31222
Global Const $ID_LARGE_EQUIPMENT_PACK			= 31223
Global Const $ID_HEAVY_EQUIPMENT_PACK			= 31224
#EndRegion Merchant Items


#Region Keys
Global Const $ID_ASCALONIAN_KEY			= 5966
Global Const $ID_STEEL_KEY				= 5967
Global Const $ID_KRYTAN_KEY				= 5964
Global Const $ID_MAGUUMA_KEY			= 5965
Global Const $ID_ELONIAN_KEY			= 5960
Global Const $ID_SHIVERPEAK_KEY			= 5962
Global Const $ID_DARKSTONE_KEY			= 5963
Global Const $ID_MINERS_KEY				= 5961
Global Const $ID_SHING_JEA_KEY			= 6537
Global Const $ID_CANTHAN_KEY			= 6540
Global Const $ID_KURZICK_KEY			= 6535
Global Const $ID_STONEROOT_KEY			= 6536
Global Const $ID_LUXON_KEY				= 6538
Global Const $ID_DEEP_JADE_KEY			= 6539
Global Const $ID_FORBIDDEN_KEY			= 6534
Global Const $ID_ISTANI_KEY				= 15557
Global Const $ID_KOURNAN_KEY			= 15559
Global Const $ID_VABBIAN_KEY			= 15558
Global Const $ID_ANCIENT_ELONIAN_KEY	= 15556
Global Const $ID_MARGONITE_KEY			= 15560
Global Const $ID_DEMONIC_KEY			= 19174
Global Const $ID_PHANTOM_KEY			= 5882
Global Const $ID_OBSIDIAN_KEY			= 5971
Global Const $ID_LOCKPICK				= 22751
Global Const $ID_ZAISHEN_KEY			= 28571
Global Const $ID_BOGROOTS_BOSS_KEY		= 2593
Global Const $KEYS_ARRAY[]				= [$ID_ASCALONIAN_KEY, $ID_STEEL_KEY, $ID_KRYTAN_KEY, $ID_MAGUUMA_KEY, $ID_ELONIAN_KEY, $ID_SHIVERPEAK_KEY, $ID_DARKSTONE_KEY, $ID_MINERS_KEY, $ID_SHING_JEA_KEY, _
											$ID_CANTHAN_KEY, $ID_KURZICK_KEY, $ID_STONEROOT_KEY, $ID_LUXON_KEY, $ID_DEEP_JADE_KEY, $ID_FORBIDDEN_KEY, $ID_ISTANI_KEY, $ID_KOURNAN_KEY, $ID_VABBIAN_KEY, _
											$ID_ANCIENT_ELONIAN_KEY, $ID_MARGONITE_KEY, $ID_DEMONIC_KEY, $ID_PHANTOM_KEY, $ID_OBSIDIAN_KEY, $ID_BOGROOTS_BOSS_KEY, $ID_ZAISHEN_KEY]
Global Const $MAP_KEYS					= MapFromArray($KEYS_ARRAY)
#EndRegion Keys


Global Const $GENERAL_ITEMS_ARRAY[]	= [$ID_IDENTIFICATION_KIT, $ID_EXPERT_SALVAGE_KIT, $ID_SALVAGE_KIT, $ID_SALVAGE_KIT_2, $ID_SUPERIOR_IDENTIFICATION_KIT, $ID_SUPERIOR_SALVAGE_KIT, $ID_LOCKPICK]
Global Const $MAP_GENERAL_ITEMS		= MapFromArray($GENERAL_ITEMS_ARRAY)


#Region Dyes
Global Const $ID_DYES				= 146
Global Const $ID_BLUE_DYE			= 2
Global Const $ID_GREEN_DYE			= 3
Global Const $ID_PURPLE_DYE			= 4
Global Const $ID_RED_DYE			= 5
Global Const $ID_YELLOW_DYE			= 6
Global Const $ID_BROWN_DYE			= 7
Global Const $ID_ORANGE_DYE			= 8
Global Const $ID_SILVER_DYE			= 9
Global Const $ID_BLACK_DYE			= 10
Global Const $ID_GRAY_DYE			= 11
Global Const $ID_WHITE_DYE			= 12
Global Const $ID_PINK_DYE			= 13

Global Const $DYES_ARRAY[]			= [$ID_BLUE_DYE, $ID_GREEN_DYE, $ID_PURPLE_DYE, $ID_RED_DYE, $ID_YELLOW_DYE, $ID_BROWN_DYE, $ID_ORANGE_DYE, $ID_SILVER_DYE, $ID_BLACK_DYE, $ID_GRAY_DYE, $ID_WHITE_DYE, $ID_PINK_DYE]
Global Const $DYES_NAMES_ARRAY[]	= ['Blue', 'Green', 'Purple', 'Red', 'Yellow', 'Brown', 'Orange', 'Silver', 'Black', 'Gray', 'White', 'Pink']
Global Const $DYE_NAMES_FROM_IDS	= MapFromArrays($DYES_ARRAY, $DYES_NAMES_ARRAY)
;Global Const $DYE_IDS_FROM_NAMES	= MapFromArrays($DYES_NAMES_ARRAY, $DYES_ARRAY)
Global Const $MAP_DYES				= MapFromArray($DYES_ARRAY)
#EndRegion Dyes


#Region Scrolls
Global Const $ID_URGOZ_SCROLL				= 3256
Global Const $ID_UW_SCROLL					= 3746
Global Const $ID_HEROS_INSIGHT_SCROLL		= 5594
Global Const $ID_BERSERKERS_INSIGHT_SCROLL	= 5595
Global Const $ID_SLAYERS_INSIGHT_SCROLL		= 5611
Global Const $ID_ADVENTURERS_INSIGHT_SCROLL	= 5853
Global Const $ID_RAMPAGERS_INSIGHT_SCROLL	= 5975
Global Const $ID_HUNTERS_INSIGHT_SCROLL		= 5976
Global Const $ID_SCROLL_OF_THE_LIGHTBRINGER	= 21233
Global Const $ID_DEEP_SCROLL				= 22279
Global Const $ID_FOW_SCROLL					= 22280
Global Const $BLUE_SCROLLS_ARRAY[]			= [$ID_ADVENTURERS_INSIGHT_SCROLL, $ID_RAMPAGERS_INSIGHT_SCROLL, $ID_HUNTERS_INSIGHT_SCROLL]
Global Const $GOLD_SCROLLS_ARRAY[]			= [$ID_URGOZ_SCROLL, $ID_UW_SCROLL, $ID_HEROS_INSIGHT_SCROLL, $ID_BERSERKERS_INSIGHT_SCROLL, _
												$ID_SLAYERS_INSIGHT_SCROLL, $ID_SCROLL_OF_THE_LIGHTBRINGER, $ID_DEEP_SCROLL, $ID_FOW_SCROLL]
Global Const $GOLD_SCROLLS_NAMES_ARRAY[]	= ['Passage Scroll to Urgozs Warren', 'Passage Scroll to the Underworld', 'Scroll of Heros Insight', 'Scroll of Berserkers Insight', _
												'Scroll of Slayers Insight', 'Scroll of the Lightbringer', 'Passage Scroll to the Deep', 'Passage Scroll to the Fissure of Woe']
Global Const $GOLD_SCROLL_NAMES_FROM_IDS	= MapFromArrays($GOLD_SCROLLS_ARRAY, $GOLD_SCROLLS_NAMES_ARRAY)
;Global Const $GOLD_SCROLL_IDS_FROM_NAMES	= MapFromArrays($GOLD_SCROLLS_NAMES_ARRAY, $GOLD_SCROLLS_ARRAY)
Global Const $MAP_BLUE_SCROLLS				= MapFromArray($BLUE_SCROLLS_ARRAY)
Global Const $MAP_GOLD_SCROLLS				= MapFromArray($GOLD_SCROLLS_ARRAY)
#EndRegion Scrolls


#Region Materials
; Basic Materials
Global Const $ID_BONE							= 921
Global Const $ID_IRON_INGOT						= 948
Global Const $ID_TANNED_HIDE_SQUARE				= 940
Global Const $ID_SCALE							= 953
Global Const $ID_CHITIN_FRAGMENT				= 954
Global Const $ID_BOLT_OF_CLOTH					= 925
Global Const $ID_WOOD_PLANK						= 946
Global Const $ID_GRANITE_SLAB					= 955
Global Const $ID_PILE_OF_GLITTERING_DUST		= 929
Global Const $ID_PLANT_FIBERS					= 934
Global Const $ID_FEATHER						= 933

; Rare Marerials
Global Const $ID_FUR_SQUARE						= 941
Global Const $ID_BOLT_OF_LINEN					= 926
Global Const $ID_BOLT_OF_DAMASK					= 927
Global Const $ID_BOLT_OF_SILK					= 928
Global Const $ID_GLOB_OF_ECTOPLASM				= 930
Global Const $ID_STEEL_INGOT					= 949
Global Const $ID_DELDRIMOR_STEEL_INGOT			= 950
Global Const $ID_MONSTROUS_CLAW					= 923
Global Const $ID_MONSTROUS_EYE					= 931
Global Const $ID_MONSTROUS_FANG					= 932
Global Const $ID_RUBY							= 937
Global Const $ID_SAPPHIRE						= 938
Global Const $ID_DIAMOND						= 935
Global Const $ID_ONYX_GEMSTONE					= 936
Global Const $ID_LUMP_OF_CHARCOAL				= 922
Global Const $ID_OBSIDIAN_SHARD					= 945
Global Const $ID_TEMPERED_GLASS_VIAL			= 939
Global Const $ID_LEATHER_SQUARE					= 942
Global Const $ID_ELONIAN_LEATHER_SQUARE			= 943
Global Const $ID_VIAL_OF_INK					= 944
Global Const $ID_ROLL_OF_PARCHMENT				= 951
Global Const $ID_ROLL_OF_VELLUM					= 952
Global Const $ID_SPIRITWOOD_PLANK				= 956
Global Const $ID_AMBER_CHUNK					= 6532
Global Const $ID_JADEITE_SHARD					= 6533


Global Const $BASIC_MATERIALS_ARRAY[]			= [$ID_BONE, $ID_IRON_INGOT, $ID_TANNED_HIDE_SQUARE, $ID_SCALE, $ID_CHITIN_FRAGMENT, $ID_BOLT_OF_CLOTH, _
													$ID_WOOD_PLANK, $ID_GRANITE_SLAB, $ID_PILE_OF_GLITTERING_DUST, $ID_PLANT_FIBERS, $ID_FEATHER]
Global Const $BASIC_MATERIALS_NAMES_ARRAY[]		= ['Bone', 'Iron Ingot', 'Tanned Hide Square', 'Scale', 'Chitin Fragment', 'Bolt of Cloth', _
													'Wood Plank', 'Granite Slab', 'Pile of Glittering Dust', 'Plant Fiber', 'Feather']
Global Const $BASIC_MATERIAL_NAMES_FROM_IDS		= MapFromArrays($BASIC_MATERIALS_ARRAY, $BASIC_MATERIALS_NAMES_ARRAY)
;Global Const $BASIC_MATERIAL_IDS_FROM_NAMES	= MapFromArrays($BASIC_MATERIALS_NAMES_ARRAY, $BASIC_MATERIALS_ARRAY)

Global Const $RARE_MATERIALS_DOUBLE_ARRAY[][]	= [	[$ID_FUR_SQUARE, 'Fur Square'], [$ID_BOLT_OF_LINEN, 'Bolt of Linen'], [$ID_BOLT_OF_DAMASK, 'Bolt of Damask'], [$ID_BOLT_OF_SILK, 'Bolt of Silk'], _
													[$ID_GLOB_OF_ECTOPLASM, 'Glob of Ectoplasm'], [$ID_STEEL_INGOT, 'Steel Ingot'], [$ID_DELDRIMOR_STEEL_INGOT, 'Deldrimor Steel Ingot'], _
													[$ID_MONSTROUS_CLAW, 'Monstrous Claw'], [$ID_MONSTROUS_EYE, 'Monstrous Eye'], [$ID_MONSTROUS_FANG, 'Monstrous Fang'], _
													[$ID_RUBY, 'Ruby'], [$ID_SAPPHIRE, 'Sapphire'], [$ID_DIAMOND, 'Diamond'], [$ID_ONYX_GEMSTONE, 'Onyx Gemstones'], _
													[$ID_LUMP_OF_CHARCOAL, 'Lumps of Charcoal'], [$ID_OBSIDIAN_SHARD, 'Obsidian Shard'], [$ID_TEMPERED_GLASS_VIAL, 'Tempered Glass Vial'], _
													[$ID_LEATHER_SQUARE, 'Leather Squares'], [$ID_ELONIAN_LEATHER_SQUARE, 'Elonian Leather Square'], [$ID_VIAL_OF_INK, 'Vial of Ink'], _
													[$ID_ROLL_OF_PARCHMENT, 'Roll of Parchment'], [$ID_ROLL_OF_VELLUM, 'Roll of Vellum'], [$ID_SPIRITWOOD_PLANK, 'Spiritwood Plank'], _
													[$ID_AMBER_CHUNK, 'Amber Chunk'], [$ID_JADEITE_SHARD, 'Jadeite Shard']]
Global Const $MAP_RARE_MATERIALS				= MapFromDoubleArray($RARE_MATERIALS_DOUBLE_ARRAY)
Global Const $RARE_MATERIALS_ARRAY[]			= [$ID_FUR_SQUARE, $ID_BOLT_OF_LINEN, $ID_BOLT_OF_DAMASK, $ID_BOLT_OF_SILK, $ID_GLOB_OF_ECTOPLASM, $ID_STEEL_INGOT, _
													$ID_DELDRIMOR_STEEL_INGOT, $ID_MONSTROUS_CLAW, $ID_MONSTROUS_EYE, $ID_MONSTROUS_FANG, $ID_RUBY, $ID_SAPPHIRE, $ID_DIAMOND, _
													$ID_ONYX_GEMSTONE, $ID_LUMP_OF_CHARCOAL, $ID_OBSIDIAN_SHARD, $ID_TEMPERED_GLASS_VIAL, $ID_LEATHER_SQUARE, $ID_ELONIAN_LEATHER_SQUARE, _
													$ID_VIAL_OF_INK, $ID_ROLL_OF_PARCHMENT, $ID_ROLL_OF_VELLUM, $ID_SPIRITWOOD_PLANK, $ID_AMBER_CHUNK, $ID_JADEITE_SHARD]
Global Const $RARE_MATERIALS_NAMES_ARRAY[]		= ['Fur Square', 'Bolt of Linen', 'Bolt of Damask', 'Bolt of Silk', 'Glob of Ectoplasm', 'Steel Ingot', _
													'Deldrimor Steel Ingot', 'Monstrous Claw', 'Monstrous Eye', 'Monstrous Fang', 'Ruby', 'Sapphire', 'Diamond', _
													'Onyx Gemstone', 'Lump of Charcoal', 'Obsidian Shard', 'Tempered Glass Vial', 'Leather Square', 'Elonian Leather Square', _
													'Vial of Ink', 'Roll of Parchment', 'Roll of Vellum', 'Spiritwood Plank', 'Amber Chunk', 'Jadeite Shard']
Global Const $RARE_MATERIAL_NAMES_FROM_IDS		= MapFromArrays($RARE_MATERIALS_ARRAY, $RARE_MATERIALS_NAMES_ARRAY)
;Global Const $RARE_MATERIAL_IDS_FROM_NAMES		= MapFromArrays($RARE_MATERIALS_NAMES_ARRAY, $RARE_MATERIALS_ARRAY)

Global $all_materials_array						= $RARE_MATERIALS_ARRAY
_ArrayConcatenate($all_materials_array, $BASIC_MATERIALS_ARRAY)
Global Const $MAP_BASIC_MATERIALS				= MapFromArray($BASIC_MATERIALS_ARRAY)
Global Const $MAP_ALL_MATERIALS					= MapFromArray($all_materials_array)

Global Const $MATERIALS_DOUBLE_ARRAY[][]		= [	[$ID_BONE, 1], [$ID_IRON_INGOT, 2], [$ID_TANNED_HIDE_SQUARE, 3], [$ID_SCALE, 4], [$ID_CHITIN_FRAGMENT, 5], [$ID_BOLT_OF_CLOTH, 6], _
													[$ID_WOOD_PLANK, 7], [$ID_GRANITE_SLAB, 9], [$ID_PILE_OF_GLITTERING_DUST, 10], [$ID_PLANT_FIBERS, 11], [$ID_FEATHER, 12], _
													[$ID_FUR_SQUARE, 13], [$ID_BOLT_OF_LINEN, 14], [$ID_BOLT_OF_DAMASK, 15], [$ID_BOLT_OF_SILK, 16], [$ID_GLOB_OF_ECTOPLASM, 17], _
													[$ID_STEEL_INGOT, 18], [$ID_DELDRIMOR_STEEL_INGOT, 19], [$ID_MONSTROUS_CLAW, 20], [$ID_MONSTROUS_EYE, 21], [$ID_MONSTROUS_FANG, 22], _
													[$ID_RUBY, 23], [$ID_SAPPHIRE, 24], [$ID_DIAMOND, 25], [$ID_ONYX_GEMSTONE, 26], [$ID_LUMP_OF_CHARCOAL, 27], [$ID_OBSIDIAN_SHARD, 28], _
													[$ID_TEMPERED_GLASS_VIAL, 30], [$ID_LEATHER_SQUARE, 31], [$ID_ELONIAN_LEATHER_SQUARE, 32], [$ID_VIAL_OF_INK, 33], _
													[$ID_ROLL_OF_PARCHMENT, 34], [$ID_ROLL_OF_VELLUM, 35], [$ID_SPIRITWOOD_PLANK, 36], [$ID_AMBER_CHUNK, 37], [$ID_JADEITE_SHARD, 38]]
Global Const $MAP_MATERIAL_LOCATION				= MapFromDoubleArray($MATERIALS_DOUBLE_ARRAY)


#EndRegion Materials


#Region Endgame Rewards
Global Const $ID_AMULET_OF_THE_MISTS		= 6069
Global Const $ID_BOOK_OF_SECRETS			= 19197
Global Const $ID_DROKNARS_KEY				= 26724
Global Const $ID_IMPERIAL_DRAGONS_TEAR		= 30205		; Not tradeable
Global Const $ID_DELDRIMOR_TALISMAN			= 30693
Global Const $ID_MEDAL_OF_HONOR				= 35122		; Not tradeable
#EndRegion Endgame Rewards


#Region Alcohol
Global Const $ID_HUNTERS_ALE				= 910
Global Const $ID_FLASK_OF_FIREWATER			= 2513
Global Const $ID_DWARVEN_ALE				= 5585
Global Const $ID_WITCHS_BREW				= 6049
Global Const $ID_SPIKED_EGGNOG				= 6366
Global Const $ID_VIAL_OF_ABSINTHE			= 6367
Global Const $ID_EGGNOG						= 6375
Global Const $ID_BOTTLE_OF_RICE_WINE		= 15477
Global Const $ID_ZEHTUKAS_JUG				= 19171
Global Const $ID_BOTTLE_OF_JUNIBERRY_GIN	= 19172
Global Const $ID_BOTTLE_OF_VABBIAN_WINE		= 19173
Global Const $ID_SHAMROCK_ALE				= 22190
Global Const $ID_AGED_DWARVEN_ALE			= 24593
Global Const $ID_HARD_APPLE_CIDER			= 28435
Global Const $ID_BOTTLE_OF_GROG				= 30855
Global Const $ID_AGED_HUNTERS_ALE			= 31145
Global Const $ID_KEG_OF_AGED_HUNTERS_ALE	= 31146
Global Const $ID_KRYTAN_BRANDY				= 35124
Global Const $ID_BATTLE_ISLE_ICED_TEA		= 36682
; For pickup use
Global Const $ALCOHOLS_ARRAY[]				= [$ID_HUNTERS_ALE, $ID_FLASK_OF_FIREWATER, $ID_DWARVEN_ALE, $ID_WITCHS_BREW, $ID_SPIKED_EGGNOG, $ID_VIAL_OF_ABSINTHE, $ID_EGGNOG, _
												$ID_BOTTLE_OF_RICE_WINE, $ID_ZEHTUKAS_JUG, $ID_BOTTLE_OF_JUNIBERRY_GIN, $ID_BOTTLE_OF_VABBIAN_WINE, $ID_SHAMROCK_ALE, _
												$ID_AGED_DWARVEN_ALE, $ID_HARD_APPLE_CIDER, $ID_BOTTLE_OF_GROG, $ID_AGED_HUNTERS_ALE, $ID_KEG_OF_AGED_HUNTERS_ALE, _
												$ID_KRYTAN_BRANDY, $ID_BATTLE_ISLE_ICED_TEA]
; For using them
Global Const $ONEPOINT_ALCOHOLS_ARRAY[]		= [$ID_HUNTERS_ALE, $ID_DWARVEN_ALE, $ID_WITCHS_BREW, $ID_VIAL_OF_ABSINTHE, $ID_EGGNOG, $ID_BOTTLE_OF_RICE_WINE, $ID_ZEHTUKAS_JUG, _
												$ID_BOTTLE_OF_JUNIBERRY_GIN, $ID_BOTTLE_OF_VABBIAN_WINE, $ID_SHAMROCK_ALE, $ID_HARD_APPLE_CIDER]
Global Const $THREEPOINT_ALCOHOLS_ARRAY[]	= [$ID_FLASK_OF_FIREWATER, $ID_SPIKED_EGGNOG, $ID_AGED_DWARVEN_ALE, $ID_BOTTLE_OF_GROG, $ID_AGED_HUNTERS_ALE, $ID_KEG_OF_AGED_HUNTERS_ALE, $ID_KRYTAN_BRANDY]
Global Const $FIFTYPOINT_ALCOHOLS_ARRAY[]	= [$ID_BATTLE_ISLE_ICED_TEA]
Global Const $MAP_ALCOHOLS					= MapFromArray($ALCOHOLS_ARRAY)
Global Const $MAP_ONEPOINT_ALCOHOLS			= MapFromArray($ONEPOINT_ALCOHOLS_ARRAY)
Global Const $MAP_THREEPOINT_ALCOHOLS		= MapFromArray($THREEPOINT_ALCOHOLS_ARRAY)
Global Const $MAP_FIFTYPOINT_ALCOHOLS		= MapFromArray($FIFTYPOINT_ALCOHOLS_ARRAY)
#EndRegion Alcohol


#Region Party
Global Const $ID_GHOST_IN_THE_BOX		= 6368
Global Const $ID_SQUASH_SERUM			= 6369
Global Const $ID_SNOWMAN_SUMMONER		= 6376
Global Const $ID_BOTTLE_ROCKET			= 21809
Global Const $ID_CHAMPAGNE_POPPER		= 21810
Global Const $ID_SPARKLER				= 21813
Global Const $ID_CRATE_OF_FIREWORKS		= 29436		; Not spammable
Global Const $ID_DISCO_BALL				= 29543		; Not Spammable
Global Const $ID_PARTY_BEACON			= 36683
Global Const $SPAMMABLE_PARTY_ARRAY[]	= [$ID_GHOST_IN_THE_BOX, $ID_SQUASH_SERUM, $ID_SNOWMAN_SUMMONER, $ID_BOTTLE_ROCKET, $ID_CHAMPAGNE_POPPER, $ID_SPARKLER, $ID_PARTY_BEACON]
Global Const $ALL_FESTIVE_ARRAY[]		= [$ID_GHOST_IN_THE_BOX, $ID_SQUASH_SERUM, $ID_SNOWMAN_SUMMONER, $ID_BOTTLE_ROCKET, $ID_CHAMPAGNE_POPPER, $ID_SPARKLER, $ID_PARTY_BEACON, $ID_CRATE_OF_FIREWORKS, $ID_DISCO_BALL]
Global Const $MAP_SPAMMABLE_PARTY		= MapFromArray($SPAMMABLE_PARTY_ARRAY)
Global Const $MAP_FESTIVE				= MapFromArray($ALL_FESTIVE_ARRAY)
#EndRegion Party


#Region Sweets
Global Const $ID_CREME_BRULEE			= 15528
Global Const $ID_RED_BEAN_CAKE			= 15479
Global Const $ID_MANDRAGOR_ROOT_CAKE	= 19170
Global Const $ID_FRUITCAKE				= 21492
Global Const $ID_SUGARY_BLUE_DRINK		= 21812
Global Const $ID_CHOCOLATE_BUNNY		= 22644
Global Const $ID_MINITREATS_OF_PURITY	= 30208
Global Const $ID_JAR_OF_HONEY			= 31150
Global Const $ID_KRYTAN_LOKUM			= 35125
Global Const $ID_DELICIOUS_CAKE			= 36681
Global Const $TOWN_SWEETS_ARRAY[]		= [$ID_CREME_BRULEE, $ID_RED_BEAN_CAKE, $ID_MANDRAGOR_ROOT_CAKE, $ID_FRUITCAKE, $ID_SUGARY_BLUE_DRINK, $ID_CHOCOLATE_BUNNY, _
											$ID_MINITREATS_OF_PURITY, $ID_JAR_OF_HONEY, $ID_KRYTAN_LOKUM, $ID_DELICIOUS_CAKE]
Global Const $MAP_TOWN_SWEETS			= MapFromArray($TOWN_SWEETS_ARRAY)

#Region Sweet Pcon
Global Const $ID_DRAKE_KABOB			= 17060
Global Const $ID_BOWL_OF_SKALEFIN_SOUP	= 17061
Global Const $ID_PAHNAI_SALAD			= 17062
Global Const $ID_BIRTHDAY_CUPCAKE		= 22269
Global Const $ID_GOLDEN_EGG				= 22752
Global Const $ID_CANDY_APPLE			= 28431
Global Const $ID_CANDY_CORN				= 28432
Global Const $ID_SLICE_OF_PUMPKIN_PIE	= 28436
Global Const $ID_LUNAR_FORTUNE_PIG		= 29424		; 2007
Global Const $ID_LUNAR_FORTUNE_RAT		= 29425		; 2008
Global Const $ID_LUNAR_FORTUNE_OX		= 29426		; 2009
Global Const $ID_LUNAR_FORTUNE_TIGER	= 29427		; 2010
Global Const $ID_LUNAR_FORTUNE_RABBIT	= 29428		; 2011
Global Const $ID_LUNAR_FORTUNE_DRAGON	= 29429		; 2012
Global Const $ID_LUNAR_FORTUNE_SNAKE	= 29430		; 2013
Global Const $ID_LUNAR_FORTUNE_HORSE	= 29431		; 2014
Global Const $ID_LUNAR_FORTUNE_SHEEP	= 29432		; 2015
Global Const $ID_LUNAR_FORTUNE_MONKEY	= 29433		; 2016
Global Const $ID_LUNAR_FORTUNE_ROOSTER	= 29434		; 2017
Global Const $ID_LUNAR_FORTUNE_DOG		= 29435		; 2018

Global Const $ID_BLUE_ROCK_CANDY		= 31151
Global Const $ID_GREEN_ROCK_CANDY		= 31152
Global Const $ID_RED_ROCK_CANDY			= 31153
Global Const $ID_WAR_SUPPLIES			= 35121
Global Const $SWEET_PCONS_ARRAY			= [$ID_DRAKE_KABOB, $ID_BOWL_OF_SKALEFIN_SOUP, $ID_PAHNAI_SALAD, $ID_BIRTHDAY_CUPCAKE, $ID_GOLDEN_EGG, $ID_CANDY_APPLE, $ID_CANDY_CORN, _
											$ID_SLICE_OF_PUMPKIN_PIE, $ID_LUNAR_FORTUNE_HORSE, $ID_BLUE_ROCK_CANDY, $ID_GREEN_ROCK_CANDY, $ID_RED_ROCK_CANDY, $ID_WAR_SUPPLIES]
Global Const $MAP_SWEET_PCONS			= MapFromArray($SWEET_PCONS_ARRAY)
#EndRegion Sweet Pcon
#EndRegion Sweets


#Region DP Removal
Global Const $ID_PEPPERMINT_CC				= 6370
Global Const $ID_REFINED_JELLY				= 19039
Global Const $ID_ELIXIR_OF_VALOR			= 21227
Global Const $ID_WINTERGREEN_CC				= 21488
Global Const $ID_RAINBOW_CC					= 21489
Global Const $ID_FOUR_LEAF_CLOVER			= 22191
Global Const $ID_HONEYCOMB					= 26784
Global Const $ID_PUMPKIN_COOKIE				= 28433
Global Const $ID_OATH_OF_PURITY				= 30206
Global Const $ID_SEAL_OF_THE_DRAGON_EMPIRE	= 30211
Global Const $ID_SHINING_BLADE_RATION		= 35127
Global Const $DP_REMOVAL_SWEETS[]			= [$ID_PEPPERMINT_CC, $ID_REFINED_JELLY, $ID_WINTERGREEN_CC, $ID_RAINBOW_CC, $ID_FOUR_LEAF_CLOVER, $ID_HONEYCOMB, $ID_PUMPKIN_COOKIE, $ID_SHINING_BLADE_RATION]
Global Const $MAP_DP_REMOVAL_SWEETS			= MapFromArray($DP_REMOVAL_SWEETS)
#EndRegion DP Removal


#Region Special Drops
Global Const $ID_CC_SHARD					= 556
Global Const $ID_FLAME_OF_BALTHAZAR			= 2514		; Not really a drop
Global Const $ID_GOLDEN_FLAME_OF_BALTHAZAR	= 22188		; Not really a drop
Global Const $ID_CELESTIAL_SIGIL			= 2571		; Not really a drop
Global Const $ID_VICTORY_TOKEN				= 18345
Global Const $ID_WINTERSDAY_GIFT			= 21491		; Not really a drop
Global Const $ID_WAYFARER_MARK				= 37765
Global Const $ID_LUNAR_TOKEN				= 21833
Global Const $ID_LUNAR_TOKENS				= 28433
Global Const $ID_TOT						= 28434
Global Const $SPECIAL_DROPS[]				= [$ID_CC_SHARD, $ID_VICTORY_TOKEN, $ID_WINTERSDAY_GIFT, $ID_WAYFARER_MARK, $ID_LUNAR_TOKEN, $ID_LUNAR_TOKENS, $ID_TOT]
Global Const $SPECIAL_DROPS_NAMES[]			= ['Candy Cane Shard', 'Victory Token', 'Wintersday Gift', 'Wayfarer Mark', 'Lunar Token', 'Lunar Tokens', 'Trick-or-Treat Bag']
Global Const $SPECIAL_DROP_NAMES_FROM_IDS		= MapFromArrays($SPECIAL_DROPS, $SPECIAL_DROPS_NAMES)
;Global Const $SPECIAL_DROP_IDS_FROM_NAMES	= MapFromArrays($SPECIAL_DROPS_NAMES, $SPECIAL_DROPS)
Global Const $MAP_SPECIAL_DROPS				= MapFromArray($SPECIAL_DROPS)
#EndRegion Special Drops


#Region Stupid Drops
Global Const $ID_KILHN_TESTIBRIES_CUISSE		= 2113
Global Const $ID_KILHN_TESTIBRIES_GREAVES		= 2114
Global Const $ID_KILHN_TESTIBRIES_CREST			= 2115
Global Const $ID_KILHN_TESTIBRIES_PAULDRON		= 2116
Global Const $ID_MAP_PIECE_TL					= 24629
Global Const $ID_MAP_PIECE_TR					= 24630
Global Const $ID_MAP_PIECE_BL					= 24631
Global Const $ID_MAP_PIECE_BR					= 24632
Global Const $ID_GOLDEN_LANTERN					= 4195		; Mount Qinkai Quest Item
Global Const $ID_HUNK_OF_FRESH_MEAT				= 15583		; NF Quest Item for Drakes on a Plain
Global Const $ID_ZEHTUKAS_GREAT_HORN			= 15845
Global Const $ID_JADE_ORB						= 15940
Global Const $ID_HERRING						= 26502		; Mini Black Moa Chick incubator item
Global Const $ID_ENCRYPTED_CHARR_BATTLE_PLANS	= 27976
Global Const $ID_MINISTERIAL_DECREE				= 29109		; WoC quest item
Global Const $ID_KEIRANS_BOW					= 35829		; Not really a drop
Global Const $ID_JAR_OF_INVIGORATION			= 27133
Global Const $MAP_PIECES_ARRAY[]				= [$ID_MAP_PIECE_TL, $ID_MAP_PIECE_TR, $ID_MAP_PIECE_BL, $ID_MAP_PIECE_BR]
Global Const $MAP_MAP_PIECES					= MapFromArray($MAP_PIECES_ARRAY)
#EndRegion Stupid Drops


#Region Hero Armor Upgrades
Global Const $ID_ANCIENT_ARMOR_REMNANT		= 19190
Global Const $ID_STOLEN_SUNSPEAR_ARMOR		= 19191
Global Const $ID_MYSTERIOUS_ARMOR_PIECE		= 19192
Global Const $ID_PRIMEVAL_ARMOR_REMNANT		= 19193
Global Const $ID_DELDRIMOR_ARMOR_REMNANT	= 27321
Global Const $ID_CLOTH_OF_THE_BROTHERHOOD	= 27322
#EndRegion Hero Armor Upgrades


#Region Polymock
Global Const $ID_POLYMOCK_WIND_RIDER			= 24356		; Gold
Global Const $ID_POLYMOCK_GARGOYLE				= 24361		; White
Global Const $ID_POLYMOCK_MERGOYLE				= 24369		; White
Global Const $ID_POLYMOCK_SKALE					= 24373		; White
Global Const $ID_POLYMOCK_FIRE_IMP				= 24359		; White
Global Const $ID_POLYMOCK_KAPPA					= 24367		; Purple
Global Const $ID_POLYMOCK_ICE_IMP				= 24366		; White
Global Const $ID_POLYMOCK_EARTH_ELEMENTAL		= 24357		; Purple
Global Const $ID_POLYMOCK_ICE_ELEMENTAL			= 24365		; Purple
Global Const $ID_POLYMOCK_FIRE_ELEMENTAL		= 24358		; Purple
Global Const $ID_POLYMOCK_ALOE_SEED				= 24355		; Purple
Global Const $ID_POLYMOCK_MIRAGE_IBOGA			= 24363		; Gold
Global Const $ID_POLYMOCK_GAKI					= 24360		; Gold
;Global Const $ID_POLYMOCK_MANTIS_DREAMWEAVER	=			; Gold
Global Const $ID_POLYMOCK_MURSAAT_ELEMENTALIST	= 24370		; Gold
Global Const $ID_POLYMOCK_RUBY_DJINN			= 24371		; Gold
Global Const $ID_POLYMOCK_NAGA_SHAMAN			= 24372		; Gold
Global Const $ID_POLYMOCK_STONE_RAIN			= 24374		; Gold
#EndRegion Polymock


#Region Reward Trophy
Global Const $ID_COPPER_ZAISHEN_COIN				= 31202
Global Const $ID_GOLD_ZAISHEN_COIN					= 31203
Global Const $ID_SILVER_ZAISHEN_COIN				= 31204
Global Const $ID_MONASTERY_CREDIT					= 5819
Global Const $ID_IMPERIAL_COMMENDATION				= 6068
Global Const $ID_LUXON_TOTEM						= 6048
Global Const $ID_EQUIPMENT_REQUISITION				= 5817
Global Const $ID_BATTLE_COMMENDATION				= 17081
Global Const $ID_KOURNAN_COIN						= 19195
Global Const $ID_TRADE_CONTRACT						= 17082
Global Const $ID_ANCIENT_ARTIFACT					= 19182
Global Const $ID_INSCRIBED_SECRET					= 19196
Global Const $ID_BUROL_IRONFISTS_COMMENDATION		= 29018
Global Const $ID_BISON_CHAMPIONSHIP_TOKEN			= 27563
Global Const $ID_MONUMENTAL_TAPESTRY				= 27583
Global Const $ID_ROYAL_GIFT							= 35120
Global Const $ID_CONFESSORS_ORDERS					= 35123
Global Const $ID_PAPER_WRAPPED_PARCEL				= 34212
Global Const $ID_SACK_OF_RANDOM_JUNK				= 34213
;Global Const $ID_LEGION_LOOT_BAG					=
;Global Const $ID_REVERIE_GIFT						=
Global Const $ID_MINISTERIAL_COMMENDATION			= 36985
Global Const $ID_IMPERIAL_GUARD_REQUISITION_ORDER	= 29108
Global Const $ID_IMPERIAL_GUARD_LOCKBOX				= 30212		; Not tradeable
;Global Const $ID_PROOF_OF_FLAMES					=
;Global Const $ID_PROOF_OF_MOUNTAINS				=
;Global Const $ID_PROOF_OF_WAVES					=
;Global Const $ID_PROOF_OF_WINDS					=
;Global Const $ID_RACING_MEDAL						=
Global Const $ID_GLOB_OF_FROZEN_ECTOPLASM			= 21509
;Global Const $ID_CELESTIAL_MINIATURE_TOKEN			=
;Global Const $ID_DRAGON_FESTIVAL_GRAB_BAG			=
Global Const $ID_RED_GIFT_BAG						= 21811
;Global Const $ID_LUNAR_FESTIVAL_GRAB_BAG			=
Global Const $ID_FESTIVAL_PRIZE						= 15478
;Global Const $ID_IMPERIAL_MASK_TOKEN				=
;Global Const $ID_GHOULISH_GRAB_BAG					=
;Global Const $ID_GHOULISH_ACCESSORY_TOKEN			=
;Global Const $ID_FROZEN_ACCESSORY_TOKEN			=
;Global Const $ID_WINTERSDAY_GRAB_BAG				=
Global Const $ID_ARMBRACE_OF_TRUTH					= 21127
Global Const $ID_MARGONITE_GEMSTONE					= 21128
Global Const $ID_STYGIAN_GEMSTONE					= 21129
Global Const $ID_TITAN_GEMSTONE						= 21130
Global Const $ID_TORMENT_GEMSTONE					= 21131
Global Const $ID_COFFER_OF_WHISPERS					= 21228
Global Const $ID_GIFT_OF_THE_TRAVELLER				= 31148
Global Const $ID_GIFT_OF_THE_HUNTSMAN				= 31149
Global Const $ID_CHAMPIONS_ZAISHEN_STRONGBOX		= 36665
Global Const $ID_HEROS_ZAISHEN_STRONGBOX			= 36666
Global Const $ID_GLADIATORS_ZAISHEN_STRONGBOX		= 36667
Global Const $ID_STRATEGISTS_ZAISHEN_STRONGBOX		= 36668
Global Const $ID_ZHOS_JOURNAL						= 25866
Global Const $REWARD_TROPHIES_ARRAY	= [ _
	$ID_COPPER_ZAISHEN_COIN, $ID_GOLD_ZAISHEN_COIN, $ID_SILVER_ZAISHEN_COIN, $ID_MONASTERY_CREDIT, $ID_IMPERIAL_COMMENDATION, $ID_LUXON_TOTEM, $ID_EQUIPMENT_REQUISITION, _
	$ID_BATTLE_COMMENDATION, $ID_KOURNAN_COIN, $ID_TRADE_CONTRACT, $ID_ANCIENT_ARTIFACT, $ID_INSCRIBED_SECRET, $ID_BUROL_IRONFISTS_COMMENDATION, $ID_BISON_CHAMPIONSHIP_TOKEN, _
	$ID_MONUMENTAL_TAPESTRY, $ID_ROYAL_GIFT, $ID_WAR_SUPPLIES, $ID_CONFESSORS_ORDERS, $ID_PAPER_WRAPPED_PARCEL, $ID_SACK_OF_RANDOM_JUNK, $ID_MINISTERIAL_COMMENDATION, _
	$ID_IMPERIAL_GUARD_REQUISITION_ORDER, $ID_IMPERIAL_GUARD_LOCKBOX, $ID_GLOB_OF_FROZEN_ECTOPLASM, $ID_RED_GIFT_BAG, $ID_FESTIVAL_PRIZE, $ID_ARMBRACE_OF_TRUTH, _
	$ID_MARGONITE_GEMSTONE, $ID_STYGIAN_GEMSTONE, $ID_TITAN_GEMSTONE, $ID_TORMENT_GEMSTONE, $ID_COFFER_OF_WHISPERS, $ID_GIFT_OF_THE_TRAVELLER, $ID_GIFT_OF_THE_HUNTSMAN, _
	$ID_CHAMPIONS_ZAISHEN_STRONGBOX, $ID_HEROS_ZAISHEN_STRONGBOX, $ID_GLADIATORS_ZAISHEN_STRONGBOX, $ID_STRATEGISTS_ZAISHEN_STRONGBOX, $ID_ZHOS_JOURNAL _
]
Global Const $MAP_REWARD_TROPHIES					= MapFromArray($REWARD_TROPHIES_ARRAY)
#EndRegion Reward Trophy


#Region Stackable Trophies
; Still needed for Nick
;Global Const $ID_ANCIENT_KAPPA_SHELL		= XXX
;Global Const $ID_MAGUUMA_SPIDER_WEB		= XXX
;Global Const $ID_SHADOWY_REMNANTS			= XXX
;Global Const $ID_WATER_DJINN_ESSENCE		= XXX

; Needed for rare materials salvage
;Global Const $ID_STOLEN_SHIPMENT			= XXX
;Global Const $ID_ANCIENT_LODESTONE			= XXX
;Global Const $ID_DECAYING_MASS				= XXX
;Global Const $ID_PUNGENT_MASS				= XXX
;Global Const $ID_REGURGITATED_MASS			= XXX

; Needed for feathers
;Global Const $ID_FLEDGLING_SKREE_WING		= XXXX

; Needed for dust
;Global Const $ID_GHOSTLY_REMAINS			= XXX
;Global Const $ID_SPIDER_WEB				= XXX
;Global Const $ID_SPIDER_WEB_2				= XXX
;Global Const $ID_FROZEN_REMNANT			= XXX
;Global Const $ID_SMOKING_REMAINS			= XXX
;Global Const $ID_ETHEREAL_GARMENT			= XXX

; Needed for bones
;Global Const $ID_GARGOYLE_SKULL			= XXX
;Global Const $ID_SEARED_RIBCAGE			= XXX
;Global Const $ID_GRAWL_NECKLACE			= XXX
;Global Const $ID_DARK_FLAME_FANG			= XXX
;Global Const $ID_GARGANTUAN_JAWBONE		= XXX
;Global Const $ID_DARK_CLAW					= XXX
;Global Const $ID_SPINY_SEED				= XXX
;Global Const $ID_UNNATURAL_SEED			= XXX
;Global Const $ID_SKELETAL_LIMB				= XXX
;Global Const $ID_ONI_TALON					= XXX
;Global Const $ID_ONI_CLAW					= XXX
;Global Const $ID_DREDGE_CHARM				= XXX
;Global Const $ID_RINKHAL_TALON				= XXX
;Global Const $ID_BULL_TRAINER_GIANT_JAWBONE = XXXX
;Global Const $ID_MANDRAGOR_CARAPACE		= XXX
;Global Const $ID_VAMPIRIC_FANG				= XXX

Global Const $ID_CHARR_HIDE					= 225
Global Const $ID_CHARR_CARVING				= 423
Global Const $ID_ICY_LODESTONE				= 424
Global Const $ID_SPIKED_CREST				= 434
Global Const $ID_HARDENED_HUMP				= 435
Global Const $ID_MERGOYLE_SKULL				= 436
Global Const $ID_GLOWING_HEART				= 439
Global Const $ID_FOREST_MINOTAUR_HORN		= 440
Global Const $ID_SHADOWY_REMNANT			= 441
Global Const $ID_ABNORMAL_SEED				= 442
Global Const $ID_BOG_SKALE_FIN				= 443
Global Const $ID_FEATHERED_CAROMI_SCALP		= 444
Global Const $ID_SHRIVELED_EYE				= 446
Global Const $ID_DUNE_BURROWER_JAW			= 447
Global Const $ID_LOSARU_MANE				= 448
Global Const $ID_BLEACHED_CARAPACE			= 449
Global Const $ID_TOPAZ_CREST				= 450
Global Const $ID_ENCRUSTED_LODESTONE		= 451
Global Const $ID_MASSIVE_JAWBONE			= 452
Global Const $ID_IRIDESCENT_GRIFFON_WING	= 453
Global Const $ID_DESSICATED_HYDRA_CLAW		= 454
Global Const $ID_MINOTAUR_HORN				= 455
Global Const $ID_JADE_MANDIBLE				= 457
Global Const $ID_FORGOTTEN_SEAL				= 459
Global Const $ID_WHITE_MANTLE_EMBLEM		= 460
Global Const $ID_WHITE_MANTLE_BADGE			= 461
Global Const $ID_MURSAAT_TOKEN				= 462
Global Const $ID_EBON_SPIDER_LEG			= 463
Global Const $ID_ANCIENT_EYE				= 464
Global Const $ID_BEHEMOTH_JAW				= 465
Global Const $ID_MAGUUMA_MANE				= 466
Global Const $ID_THORNY_CARAPACE			= 467
Global Const $ID_TANGLED_SEED				= 468
Global Const $ID_MOSSY_MANDIBLE				= 469
Global Const $ID_JUNGLE_SKALE_FIN			= 70
Global Const $ID_JUNGLE_TROLL_TUSK			= 471
Global Const $ID_OBSIDIAN_BURROWER_JAW		= 472
Global Const $ID_DEMONIC_FANG				= 473
Global Const $ID_PHANTOM_RESIDUE			= 474
Global Const $ID_GRUESOME_STERNUM			= 475
Global Const $ID_DEMONIC_REMAINS			= 476
Global Const $ID_STORMY_EYE					= 477
Global Const $ID_SCAR_BEHEMOTH_JAW			= 478
Global Const $ID_FETID_CARAPACE				= 479
Global Const $ID_SINGED_GARGOYLE_SKULL		= 480
Global Const $ID_GRUESOME_RIBCAGE			= 482
Global Const $ID_RAWHIDE_BELT				= 483
Global Const $ID_LEATHERY_CLAW				= 484
Global Const $ID_SCORCHED_SEED				= 485
Global Const $ID_SCORCHED_LODESTONE			= 486
Global Const $ID_ORNATE_GRAWL_NECKLACE		= 487
Global Const $ID_SHIVERPEAK_MANE			= 488
Global Const $ID_FROSTFIRE_FANG				= 489
Global Const $ID_ICY_HUMP					= 490
Global Const $ID_HUGE_JAWBONE				= 492
Global Const $ID_FROSTED_GRIFFON_WING		= 493
Global Const $ID_FRIGID_HEART				= 494
Global Const $ID_CURVED_MINTAUR_HORN		= 495
Global Const $ID_AZURE_REMAINS				= 496
Global Const $ID_ALPINE_SEED				= 497
Global Const $ID_FEATHERED_AVICARA_SCALP	= 498
Global Const $ID_INTRICATE_GRAWL_NECKLACE	= 499
Global Const $ID_MOUNTAIN_TROLL_TUSK		= 500
Global Const $ID_STONE_SUMMIT_BADGE			= 502
Global Const $ID_MOLTEN_CLAW				= 503
Global Const $ID_DECAYED_ORR_EMBLEM			= 504
Global Const $ID_IGNEOUS_SPIDER_LEG			= 505
Global Const $ID_MOLTEN_EYE					= 506
Global Const $ID_FIERY_CREST				= 508
Global Const $ID_IGNEOUS_HUMP				= 510
Global Const $ID_UNCTUOUS_REMAINS			= 511
Global Const $ID_MAHGO_CLAW					= 513
Global Const $ID_MOLTEN_HEART				= 514
Global Const $ID_CORROSIVE_SPIDER_LEG		= 518
Global Const $ID_UMBRAL_EYE					= 519
Global Const $ID_SHADOWY_CREST				= 520
Global Const $ID_DARK_REMAINS				= 522
Global Const $ID_GLOOM_SEED					= 523
Global Const $ID_UMBRAL_SKELETAL_LIMB		= 525
Global Const $ID_SHADOWY_HUSK				= 526
Global Const $ID_ENSLAVEMENT_STONE			= 532
Global Const $ID_KURZICK_BAUBLE				= 604
Global Const $ID_PLAGUE_IDOL				= 805
Global Const $ID_COPPER_CRIMSON_SKULL_COIN	= 806
Global Const $ID_GOLD_CRIMSON_SKULL_COIN	= 807
Global Const $ID_JADE_BRACELET				= 809
Global Const $ID_LUXON_PENDANT				= 810
Global Const $ID_BONE_CHARM					= 811
Global Const $ID_TRUFFLE					= 813
Global Const $ID_SKULL_JUJU					= 814
Global Const $ID_MANTIS_PINCER				= 815
Global Const $ID_STONE_HORN					= 816
Global Const $ID_KEEN_ONI_CLAW				= 817
Global Const $ID_DREDGE_INCISOR				= 818
Global Const $ID_DRAGON_ROOT				= 819
Global Const $ID_STONE_CARVING				= 820
Global Const $ID_WARDEN_HORN				= 822
Global Const $ID_PULSATING_GROWTH			= 824
Global Const $ID_FORGOTTEN_TRINKET_BOX		= 825
Global Const $ID_AUGMENTED_FLESH			= 826
Global Const $ID_PUTRID_CYST				= 827
Global Const $ID_MANTID_PINCER				= 829
Global Const $ID_NAGA_HIDE					= 832
Global Const $ID_NAGA_PELT					= 833
Global Const $ID_FEATHERED_CREST			= 835
Global Const $ID_FEATHERED_SCALP			= 836
Global Const $ID_KAPPA_HATCHLING_SHELL		= 838
Global Const $ID_STOLEN_SUPPLIES			= 840
Global Const $ID_BLACK_PEARL				= 841
Global Const $ID_ROT_WALLOW_TUSK			= 842
Global Const $ID_KRAKEN_EYE					= 843
Global Const $ID_AZURE_CREST				= 844
Global Const $ID_KIRIN_HORN					= 846
Global Const $ID_KEEN_ONI_TALON				= 847
Global Const $ID_NAGA_SKIN					= 848
Global Const $ID_GUARDIAN_MOSS				= 849
Global Const $ID_ARCHAIC_KAPPA_SHELL		= 850
Global Const $ID_STOLEN_PROVISIONS			= 851
Global Const $ID_SOUL_STONE					= 852
Global Const $ID_VERMIN_HIDE				= 853
Global Const $ID_VENERABLE_MANTID_PINCER	= 854
Global Const $ID_CELESTIAL_ESSENCE			= 855
Global Const $ID_MOON_SHELL					= 1009
Global Const $ID_STOLEN_GOODS				= 1423
Global Const $ID_COPPER_SHILLING			= 1577
Global Const $ID_GOLD_DOUBLOON				= 1578
Global Const $ID_SILVER_BULLION_COIN		= 1579
Global Const $ID_DEMONIC_RELIC				= 1580
Global Const $ID_MARGONITE_MASK				= 1581
Global Const $ID_KOURNAN_PENDANT			= 1582
Global Const $ID_MUMMY_WRAPPING				= 1583
Global Const $ID_SANDBLASTED_LODESTONE		= 1584
Global Const $ID_INSCRIBED_SHARD			= 1587
Global Const $ID_DUSTY_INSECT_CARAPACE		= 1588
Global Const $ID_GIANT_TUSK					= 1590
Global Const $ID_INSECT_APPENDAGE			= 1597
Global Const $ID_JUVENILE_TERMITE_LEG		= 1598
Global Const $ID_SENTIENT_ROOT				= 1600
Global Const $ID_SENTIENT_SEED				= 1601
Global Const $ID_SKALE_TOOTH				= 1603
Global Const $ID_SKALE_CLAW					= 1604
Global Const $ID_SKELETON_BONE				= 1605
Global Const $ID_COBALT_TALON				= 1609
Global Const $ID_SKREE_WING					= 1610
Global Const $ID_INSECT_CARAPACE			= 1617
Global Const $ID_SENTIENT_LODESTONE			= 1619
Global Const $ID_IMMOLATED_DJINN_ESSENCE	= 1620
Global Const $ID_ROARING_ETHER_CLAW			= 1629
Global Const $ID_LUMINOUS_STONE				= 1660
Global Const $ID_ROARING_ETHER_HEART		= 1662
Global Const $ID_PILLAGED_GOODS				= 1663
Global Const $ID_MANDRAGOR_HUSK				= 1668
Global Const $ID_MANDRAGOR_SWAMPROOT		= 1671
Global Const $ID_BEHEMOTH_HIDE				= 1675
Global Const $ID_GEODE						= 1681
Global Const $ID_HUNTING_MINOTAUR_HORN		= 1682
Global Const $ID_MANDRAGOR_ROOT				= 1686
Global Const $ID_RED_IRIS_FLOWER			= 2994
Global Const $ID_IBOGA_PETAL				= 19183
Global Const $ID_SKALE_FIN					= 19184
Global Const $ID_CHUNK_OF_DRAKE_FLESH		= 19185
Global Const $ID_DIAMOND_DJINN_ESSENCE		= 19186
Global Const $ID_RUBY_DJINN_ESSENCE			= 19187
Global Const $ID_SAPPHIRE_DJINN_ESSENCE		= 19188
Global Const $ID_BRANCH_OF_JUNI_BERRIES		= 19194
Global Const $ID_SENTIENT_SPORE				= 19198
Global Const $ID_HEKET_TONGUE				= 19199
Global Const $ID_DIESSA_CHALICE				= 24353
Global Const $ID_GOLDEN_RIN_RELIC			= 24354
Global Const $ID_DESTROYER_CORE				= 27033
Global Const $ID_INCUBUS_WING				= 27034
Global Const $ID_SAURIAN_BONE				= 27035
Global Const $ID_AMPHIBIAN_TONGUE			= 27036
Global Const $ID_WEAVER_LEG					= 27037
Global Const $ID_PATCH_OF_SIMIAN_FUR		= 27038
Global Const $ID_QUETZAL_CREST				= 27039
Global Const $ID_SKELK_CLAW					= 27040
Global Const $ID_SENTIENT_VINE				= 27041
Global Const $ID_FRIGID_MANDRAGOR_HUSK		= 27042
Global Const $ID_MODNIIR_MANE				= 27043
Global Const $ID_STONE_SUMMIT_EMBLEM		= 27044
Global Const $ID_JOTUN_PELT					= 27045
Global Const $ID_BERSERKER_HORN				= 27046
Global Const $ID_GLACIAL_STONE				= 27047
Global Const $ID_FROZEN_WURM_HUSK			= 27048
Global Const $ID_MOUNTAIN_ROOT				= 27049
Global Const $ID_PILE_OF_ELEMENTAL_DUST		= 27050
Global Const $ID_FIBROUS_MANDRAGOR_ROOT		= 27051
Global Const $ID_SUPERB_CHARR_CARVING		= 27052
Global Const $ID_STONE_GRAWL_NECKLACE		= 27053
Global Const $ID_MANTID_UNGULA				= 27054
Global Const $ID_SKALE_FANG					= 27055
Global Const $ID_STONE_CLAW					= 27057
Global Const $ID_SKELK_FANG					= 27060
Global Const $ID_FUNGAL_ROOT				= 27061
Global Const $ID_FLESH_REAVER_MORSEL		= 27062
Global Const $ID_GOLEM_RUNESTONE			= 27065
Global Const $ID_BEETLE_EGG					= 27066
Global Const $ID_BLOB_OF_OOZE				= 27067
Global Const $ID_CHROMATIC_SCALE			= 27069
Global Const $ID_DRYDER_WEB					= 27070
Global Const $ID_VAETTIR_ESSENCE			= 27071
Global Const $ID_KRAIT_SKIN					= 27729
Global Const $ID_UNDEAD_BONE				= 27974
Global Const $TROPHIES_ARRAY[]	= [ _
	$ID_CHARR_CARVING, $ID_ICY_LODESTONE, $ID_SPIKED_CREST, $ID_HARDENED_HUMP, $ID_MERGOYLE_SKULL, $ID_GLOWING_HEART, $ID_FOREST_MINOTAUR_HORN, $ID_SHADOWY_REMNANT, _
	$ID_ABNORMAL_SEED, $ID_BOG_SKALE_FIN, $ID_FEATHERED_CAROMI_SCALP, $ID_SHRIVELED_EYE, $ID_DUNE_BURROWER_JAW, $ID_LOSARU_MANE, $ID_BLEACHED_CARAPACE, $ID_TOPAZ_CREST, _
	$ID_ENCRUSTED_LODESTONE, $ID_MASSIVE_JAWBONE, $ID_IRIDESCENT_GRIFFON_WING, $ID_DESSICATED_HYDRA_CLAW, $ID_MINOTAUR_HORN, $ID_JADE_MANDIBLE, $ID_FORGOTTEN_SEAL, _
	$ID_WHITE_MANTLE_EMBLEM, $ID_WHITE_MANTLE_BADGE, $ID_MURSAAT_TOKEN, $ID_EBON_SPIDER_LEG, $ID_ANCIENT_EYE, $ID_BEHEMOTH_JAW, $ID_MAGUUMA_MANE, $ID_THORNY_CARAPACE, _
	$ID_TANGLED_SEED, $ID_MOSSY_MANDIBLE, $ID_JUNGLE_SKALE_FIN, $ID_JUNGLE_TROLL_TUSK, $ID_OBSIDIAN_BURROWER_JAW, $ID_DEMONIC_FANG, $ID_PHANTOM_RESIDUE, $ID_GRUESOME_STERNUM, _
	$ID_DEMONIC_REMAINS, $ID_STORMY_EYE, $ID_SCAR_BEHEMOTH_JAW, $ID_FETID_CARAPACE, $ID_SINGED_GARGOYLE_SKULL, $ID_GRUESOME_RIBCAGE, $ID_RAWHIDE_BELT, $ID_LEATHERY_CLAW, _
	$ID_SCORCHED_SEED, $ID_SCORCHED_LODESTONE, $ID_ORNATE_GRAWL_NECKLACE, $ID_SHIVERPEAK_MANE, $ID_FROSTFIRE_FANG, $ID_ICY_HUMP, $ID_HUGE_JAWBONE, $ID_FROSTED_GRIFFON_WING, _
	$ID_FRIGID_HEART, $ID_CURVED_MINTAUR_HORN, $ID_AZURE_REMAINS, $ID_ALPINE_SEED, $ID_FEATHERED_AVICARA_SCALP, $ID_INTRICATE_GRAWL_NECKLACE, $ID_MOUNTAIN_TROLL_TUSK, _
	$ID_STONE_SUMMIT_BADGE, $ID_MOLTEN_CLAW, $ID_DECAYED_ORR_EMBLEM, $ID_IGNEOUS_SPIDER_LEG, $ID_MOLTEN_EYE, $ID_FIERY_CREST, $ID_IGNEOUS_HUMP, $ID_UNCTUOUS_REMAINS, _
	$ID_MAHGO_CLAW, $ID_MOLTEN_HEART, $ID_CORROSIVE_SPIDER_LEG, $ID_UMBRAL_EYE, $ID_SHADOWY_CREST, $ID_DARK_REMAINS, $ID_GLOOM_SEED, $ID_UMBRAL_SKELETAL_LIMB, $ID_SHADOWY_HUSK, _
	$ID_ENSLAVEMENT_STONE, $ID_KURZICK_BAUBLE, $ID_JADE_BRACELET, $ID_LUXON_PENDANT, $ID_BONE_CHARM, $ID_TRUFFLE, $ID_SKULL_JUJU, $ID_MANTID_PINCER, $ID_STONE_HORN, _
	$ID_KEEN_ONI_CLAW, $ID_DREDGE_INCISOR, $ID_DRAGON_ROOT, $ID_STONE_CARVING, $ID_WARDEN_HORN, $ID_PULSATING_GROWTH, $ID_FORGOTTEN_TRINKET_BOX, $ID_AUGMENTED_FLESH, _
	$ID_PUTRID_CYST, $ID_MANTIS_PINCER, $ID_NAGA_PELT, $ID_FEATHERED_CREST, $ID_FEATHERED_SCALP, $ID_KAPPA_HATCHLING_SHELL, $ID_STOLEN_SUPPLIES, $ID_BLACK_PEARL, _
	$ID_ROT_WALLOW_TUSK, $ID_KRAKEN_EYE, $ID_AZURE_CREST, $ID_KIRIN_HORN, $ID_KEEN_ONI_TALON, $ID_NAGA_SKIN, $ID_GUARDIAN_MOSS, $ID_ARCHAIC_KAPPA_SHELL, $ID_STOLEN_PROVISIONS, _
	$ID_SOUL_STONE, $ID_VERMIN_HIDE, $ID_VENERABLE_MANTID_PINCER, $ID_CELESTIAL_ESSENCE, $ID_MOON_SHELL, $ID_COPPER_SHILLING, $ID_GOLD_DOUBLOON, $ID_SILVER_BULLION_COIN, _
	$ID_DEMONIC_RELIC, $ID_MARGONITE_MASK, $ID_KOURNAN_PENDANT, $ID_MUMMY_WRAPPING, $ID_SANDBLASTED_LODESTONE, $ID_INSCRIBED_SHARD, $ID_DUSTY_INSECT_CARAPACE, $ID_GIANT_TUSK, _
	$ID_INSECT_APPENDAGE, $ID_JUVENILE_TERMITE_LEG, $ID_SENTIENT_ROOT, $ID_SENTIENT_SEED, $ID_SKALE_TOOTH, $ID_SKALE_CLAW, $ID_SKELETON_BONE, $ID_COBALT_TALON, $ID_SKREE_WING, _
	$ID_INSECT_CARAPACE, $ID_SENTIENT_LODESTONE, $ID_IMMOLATED_DJINN_ESSENCE, $ID_ROARING_ETHER_CLAW, $ID_MANDRAGOR_HUSK, $ID_MANDRAGOR_SWAMPROOT, $ID_BEHEMOTH_HIDE, $ID_GEODE, _
	$ID_HUNTING_MINOTAUR_HORN, $ID_MANDRAGOR_ROOT, $ID_RED_IRIS_FLOWER, $ID_IBOGA_PETAL, $ID_SKALE_FIN, $ID_CHUNK_OF_DRAKE_FLESH, $ID_RUBY_DJINN_ESSENCE, $ID_SAPPHIRE_DJINN_ESSENCE, _
	$ID_SENTIENT_SPORE, $ID_HEKET_TONGUE, $ID_DIESSA_CHALICE, $ID_GOLDEN_RIN_RELIC, $ID_DESTROYER_CORE, $ID_INCUBUS_WING, $ID_SAURIAN_BONE, $ID_AMPHIBIAN_TONGUE, $ID_WEAVER_LEG, _
	$ID_PATCH_OF_SIMIAN_FUR, $ID_QUETZAL_CREST, $ID_SKELK_CLAW, $ID_SENTIENT_VINE, $ID_FRIGID_MANDRAGOR_HUSK, $ID_MODNIIR_MANE, $ID_STONE_SUMMIT_EMBLEM, $ID_JOTUN_PELT, _
	$ID_BERSERKER_HORN, $ID_GLACIAL_STONE, $ID_FROZEN_WURM_HUSK, $ID_MOUNTAIN_ROOT, $ID_PILE_OF_ELEMENTAL_DUST, $ID_FIBROUS_MANDRAGOR_ROOT, $ID_SUPERB_CHARR_CARVING, _
	$ID_STONE_GRAWL_NECKLACE, $ID_MANTID_UNGULA, $ID_SKALE_FANG, $ID_STONE_CLAW, $ID_SKELK_FANG, $ID_FUNGAL_ROOT, $ID_FLESH_REAVER_MORSEL, $ID_GOLEM_RUNESTONE, $ID_BEETLE_EGG, _
	$ID_BLOB_OF_OOZE, $ID_CHROMATIC_SCALE, $ID_DRYDER_WEB, $ID_VAETTIR_ESSENCE, $ID_KRAIT_SKIN, $ID_UNDEAD_BONE _
]
Global Const $MAP_TROPHIES	= MapFromArray($TROPHIES_ARRAY)

Global Const $FEATHER_TROPHIES_ARRAY[]			= [$ID_FEATHERED_CAROMI_SCALP, $ID_FEATHERED_AVICARA_SCALP, $ID_FEATHERED_CREST, $ID_FEATHERED_SCALP, _ ;$ID_FLEDGLING_SKREE_WING, _
													$ID_SKREE_WING, $ID_FROSTED_GRIFFON_WING, $ID_IRIDESCENT_GRIFFON_WING, $ID_QUETZAL_CREST]
Global Const $MAP_FEATHER_TROPHIES				= MapFromArray($FEATHER_TROPHIES_ARRAY)

Global Const $DUST_TROPHIES_ARRAY[]				= [$ID_AMPHIBIAN_TONGUE, $ID_ANCIENT_EYE, $ID_AUGMENTED_FLESH, $ID_AZURE_REMAINS, $ID_BEETLE_EGG, $ID_BLACK_PEARL, _
													$ID_BLOB_OF_OOZE, $ID_DARK_REMAINS, $ID_DEMONIC_FANG, $ID_DEMONIC_REMAINS, $ID_DRYDER_WEB, $ID_ENSLAVEMENT_STONE, _ ;$ID_ETHEREAL_GARMENT, $ID_FROZEN_REMNANT, _
													$ID_FROSTFIRE_FANG, $ID_FROZEN_WURM_HUSK, $ID_GLACIAL_STONE, $ID_HEKET_TONGUE, _ ;$ID_GHOSTLY_REMAINS, _
													$ID_IMMOLATED_DJINN_ESSENCE, $ID_JADE_BRACELET, $ID_KIRIN_HORN, $ID_LOSARU_MANE, $ID_MAGUUMA_MANE, $ID_MOLTEN_EYE, _
													$ID_MOON_SHELL, $ID_MURSAAT_TOKEN, $ID_PHANTOM_RESIDUE, $ID_PILE_OF_ELEMENTAL_DUST, $ID_PULSATING_GROWTH, _
													$ID_PUTRID_CYST, $ID_SENTIENT_ROOT, $ID_SENTIENT_SEED, $ID_SENTIENT_SPORE, $ID_SHADOWY_REMNANT, $ID_SHIVERPEAK_MANE, _
													$ID_SHRIVELED_EYE, $ID_STORMY_EYE, _ ;$ID_SMOKING_REMAINS, $ID_SPIDER_WEB, $ID_SPIDER_WEB_2, _
													$ID_UMBRAL_EYE, $ID_UNCTUOUS_REMAINS, $ID_VAETTIR_ESSENCE]
Global Const $MAP_DUST_TROPHIES					= MapFromArray($DUST_TROPHIES_ARRAY)
Global Const $BONES_TROPHIES_ARRAY[]			= [$ID_AUGMENTED_FLESH, $ID_BERSERKER_HORN, $ID_BONE_CHARM, $ID_CURVED_MINTAUR_HORN, _
													$ID_FLESH_REAVER_MORSEL, $ID_GIANT_TUSK, $ID_GRUESOME_RIBCAGE, $ID_GRUESOME_STERNUM, $ID_HUGE_JAWBONE, _
													$ID_HUNTING_MINOTAUR_HORN, $ID_JUNGLE_TROLL_TUSK, $ID_KEEN_ONI_CLAW, $ID_MASSIVE_JAWBONE, $ID_MERGOYLE_SKULL, _
													$ID_MINOTAUR_HORN, $ID_MOUNTAIN_TROLL_TUSK, $ID_PULSATING_GROWTH, $ID_PUTRID_CYST, $ID_SAURIAN_BONE, _
													$ID_SINGED_GARGOYLE_SKULL, $ID_SKALE_CLAW, $ID_SKALE_FANG, $ID_SKALE_TOOTH, $ID_SKELETON_BONE, $ID_SKELK_CLAW, _
													$ID_SKELK_FANG, $ID_SKREE_WING, $ID_UMBRAL_SKELETAL_LIMB, $ID_UNDEAD_BONE, $ID_WARDEN_HORN]
Global Const $MAP_BONES_TROPHIES				= MapFromArray($BONES_TROPHIES_ARRAY)
Global Const $FIBER_TROPHIES_ARRAY[]			= [$ID_ABNORMAL_SEED, $ID_TANGLED_SEED, $ID_SCORCHED_SEED, $ID_ORNATE_GRAWL_NECKLACE, $ID_ALPINE_SEED, _
													$ID_INTRICATE_GRAWL_NECKLACE, $ID_GLOOM_SEED, $ID_DRAGON_ROOT, $ID_GUARDIAN_MOSS, $ID_SENTIENT_ROOT, _
													$ID_SENTIENT_SEED, $ID_MANDRAGOR_ROOT, $ID_IBOGA_PETAL, $ID_SENTIENT_SPORE, $ID_SENTIENT_VINE, $ID_MOUNTAIN_ROOT, _
													$ID_FIBROUS_MANDRAGOR_ROOT, $ID_FUNGAL_ROOT]
Global Const $MAP_FIBER_TROPHIES				= MapFromArray($FIBER_TROPHIES_ARRAY)
Global Const $RARE_MATERIALS_TROPHIES_ARRAY[]	= [ _
	_ ; Ink and others
	$ID_STOLEN_GOODS, $ID_STOLEN_PROVISIONS, _;$ID_STOLEN_SHIPMENT, 
	$ID_STOLEN_SUPPLIES, $ID_PILLAGED_GOODS, _
	_ ; Sapphire and Ruby
	_ ;$ID_ANCIENT_LODESTONE, 
	$ID_GEODE, $ID_SAPPHIRE_DJINN_ESSENCE, _;$ID_WATER_DJINN_ESSENCE, 
	$ID_ROARING_ETHER_HEART, $ID_RUBY_DJINN_ESSENCE, _
	_ ; Monstrous Fang and Monstrous Claw
	$ID_COBALT_TALON, $ID_KEEN_ONI_TALON, $ID_ROARING_ETHER_CLAW, _;$ID_DECAYING_MASS, 
	$ID_DEMONIC_RELIC, $ID_DREDGE_INCISOR, $ID_NAGA_SKIN, _;$ID_PUNGENT_MASS, $ID_REGURGITATED_MASS, 
	$ID_ROT_WALLOW_TUSK _
]
Global Const $MAP_RARE_MATERIALS_TROPHIES		= MapFromArray($RARE_MATERIALS_TROPHIES_ARRAY)

; All Nicholas items minus materials: Amber chunk, Elonian Leather Square, Jadeite Shard, Roll of Parchment, Spiritwood Plank, Vial of Ink
Global Const $NICHOLAS_ITEMS_ARRAY[] 		= [ _
	$ID_ABNORMAL_SEED, $ID_ALPINE_SEED, $ID_AMPHIBIAN_TONGUE, $ID_ANCIENT_EYE, _ ;$ID_ANCIENT_KAPPA_SHELL, 
	$ID_AZURE_CREST, $ID_AZURE_REMAINS, _
	$ID_BEHEMOTH_HIDE, $ID_BEHEMOTH_JAW, $ID_BERSERKER_HORN, $ID_BLACK_PEARL, $ID_BOG_SKALE_FIN, $ID_BOLT_OF_LINEN, $ID_BONE_CHARM, $ID_BOTTLE_OF_VABBIAN_WINE, $ID_BOWL_OF_SKALEFIN_SOUP, $ID_BRANCH_OF_JUNI_BERRIES, _
	$ID_CELESTIAL_ESSENCE, $ID_CHARR_CARVING, $ID_CHARR_HIDE, $ID_CHROMATIC_SCALE, $ID_COBALT_TALON, $ID_COPPER_CRIMSON_SKULL_COIN, $ID_COPPER_SHILLING, _
	$ID_DECAYED_ORR_EMBLEM, $ID_DEMONIC_RELIC, $ID_DESSICATED_HYDRA_CLAW, $ID_DIAMOND_DJINN_ESSENCE, $ID_DRAGON_ROOT, $ID_DRAKE_KABOB, $ID_DREDGE_INCISOR, $ID_DWARVEN_ALE, _
	$ID_ENSLAVEMENT_STONE, _
	$ID_FEATHERED_AVICARA_SCALP, $ID_FEATHERED_CAROMI_SCALP, $ID_FEATHERED_SCALP, $ID_FETID_CARAPACE, $ID_FIBROUS_MANDRAGOR_ROOT, $ID_FOREST_MINOTAUR_HORN, _
		$ID_FORGOTTEN_SEAL, $ID_FORGOTTEN_TRINKET_BOX, $ID_FRIGID_HEART, $ID_FRIGID_MANDRAGOR_HUSK, $ID_FROSTED_GRIFFON_WING, $ID_FROSTFIRE_FANG, _
	$ID_GEODE, $ID_GLOOM_SEED, $ID_GLOWING_HEART, $ID_GOLD_CRIMSON_SKULL_COIN, $ID_GOLD_DOUBLOON, $ID_GRUESOME_RIBCAGE, $ID_GUARDIAN_MOSS, _
	$ID_HARDENED_HUMP, $ID_HEKET_TONGUE, $ID_HERRING, _
	$ID_ICY_HUMP, $ID_ICY_LODESTONE, $ID_INSCRIBED_SHARD, $ID_INSECT_CARAPACE, $ID_INTRICATE_GRAWL_NECKLACE, _
	$ID_JADE_BRACELET, $ID_JADE_MANDIBLE, $ID_JOTUN_PELT, $ID_JUNGLE_TROLL_TUSK, _
	$ID_KEEN_ONI_TALON, $ID_KOURNAN_PENDANT, $ID_KRAIT_SKIN, $ID_KRAKEN_EYE, _
	$ID_LEATHERY_CLAW, $ID_LUMINOUS_STONE, _
	$ID_MAGUUMA_MANE, _;$ID_MAGUUMA_SPIDER_WEB, 
	$ID_MAHGO_CLAW, $ID_MANDRAGOR_ROOT_CAKE, $ID_MANDRAGOR_SWAMPROOT, $ID_MANTID_PINCER, $ID_MARGONITE_MASK, $ID_MASSIVE_JAWBONE, _
		$ID_MERGOYLE_SKULL, $ID_MINOTAUR_HORN, $ID_MODNIIR_MANE, $ID_MOON_SHELL, $ID_MOSSY_MANDIBLE, $ID_MOUNTAIN_TROLL_TUSK, $ID_MUMMY_WRAPPING, $ID_MURSAAT_TOKEN, _
	$ID_NAGA_HIDE, $ID_NAGA_SKIN, _
	$ID_PAHNAI_SALAD, $ID_PHANTOM_RESIDUE, $ID_PILE_OF_ELEMENTAL_DUST, $ID_PILLAGED_GOODS, $ID_PLAGUE_IDOL, $ID_PUTRID_CYST, _
	$ID_QUETZAL_CREST, _
	$ID_RED_IRIS_FLOWER, $ID_ROARING_ETHER_CLAW, $ID_ROARING_ETHER_HEART, $ID_ROT_WALLOW_TUSK, $ID_RUBY_DJINN_ESSENCE, _
	$ID_SANDBLASTED_LODESTONE, $ID_SAPPHIRE_DJINN_ESSENCE, $ID_SAURIAN_BONE, $ID_SCORCHED_LODESTONE, $ID_SENTIENT_LODESTONE, $ID_SENTIENT_SEED, $ID_SENTIENT_SPORE, _;$ID_SHADOWY_REMNANTS, _
		$ID_SHIVERPEAK_MANE, $ID_SHRIVELED_EYE, $ID_SILVER_BULLION_COIN, $ID_SINGED_GARGOYLE_SKULL, $ID_SKELK_CLAW, $ID_SKREE_WING, $ID_SKULL_JUJU, $ID_SOUL_STONE, $ID_SPIKED_CREST, _
		$ID_STOLEN_SUPPLIES, $ID_STONE_CARVING, $ID_STONE_GRAWL_NECKLACE, $ID_STONE_SUMMIT_BADGE, $ID_STORMY_EYE, $ID_SUPERB_CHARR_CARVING, _
	$ID_TANGLED_SEED, $ID_TEMPERED_GLASS_VIAL, $ID_THORNY_CARAPACE, $ID_TOPAZ_CREST, $ID_TRUFFLE, _
	$ID_VERMIN_HIDE, _
	_;$ID_WATER_DJINN_ESSENCE, 
	$ID_WEAVER_LEG _
]
Global Const $MAP_NICHOLAS_ITEMS			= MapFromArray($NICHOLAS_ITEMS_ARRAY)

; Items farmed specifically to obtain them or just very frequently obtained
Global Const $FARMED_TROPHIES[] 			= [ _
	$ID_MARGONITE_GEMSTONE, $ID_STYGIAN_GEMSTONE, $ID_TITAN_GEMSTONE, $ID_TORMENT_GEMSTONE, _
	$ID_DIESSA_CHALICE, $ID_GOLDEN_RIN_RELIC, $ID_CHUNK_OF_DRAKE_FLESH, $ID_SKALE_FIN, $ID_IBOGA_PETAL, _
	$ID_DESTROYER_CORE, $ID_GLACIAL_STONE, $ID_SAURIAN_BONE, _
	$ID_JADE_BRACELET, $ID_DARK_REMAINS, $ID_DEMONIC_REMAINS _
]
Global Const $FARMED_TROPHIES_NAMES[]		= [ _
	'Margonite Gemstone', 'Stygian Gemstone', 'Titan Gemstone', 'Torment Gemstone', _
	'Diessa Chalice', 'Golden Rin Relic', 'Chunk of Drake Flesh', 'Skale Fin', 'Iboga Petal', _
	'Destroyer Core', 'Glacial Stone', 'Saurian Bone', _
	'Jade Bracelet', 'Dark Remains', 'Demonic Remains' _
]
Global Const $FARMED_TROPHIES_NAMES_FROM_ID	= MapFromArrays($FARMED_TROPHIES, $FARMED_TROPHIES_NAMES)

Global Const $MAP_FARMED_TROPHIES			= MapFromArray($FARMED_TROPHIES)
#EndRegion Stackable Trophies


#Region Tomes
Global Const $ID_ASSASSIN_ELITETOME		= 21786
Global Const $ID_MESMER_ELITETOME		= 21787
Global Const $ID_NECROMANCER_ELITETOME	= 21788
Global Const $ID_ELEMENTALIST_ELITETOME	= 21789
Global Const $ID_MONK_ELITETOME			= 21790
Global Const $ID_WARRIOR_ELITETOME		= 21791
Global Const $ID_RANGER_ELITETOME		= 21792
Global Const $ID_DERVISH_ELITETOME		= 21793
Global Const $ID_RITUALIST_ELITETOME	= 21794
Global Const $ID_PARAGON_ELITETOME		= 21795

Global Const $ID_ASSASSIN_TOME			= 21796
Global Const $ID_MESMER_TOME			= 21797
Global Const $ID_NECROMANCER_TOME		= 21798
Global Const $ID_ELEMENTALIST_TOME		= 21799
Global Const $ID_MONK_TOME				= 21800
Global Const $ID_WARRIOR_TOME			= 21801
Global Const $ID_RANGER_TOME			= 21802
Global Const $ID_DERVISH_TOME			= 21803
Global Const $ID_RITUALIST_TOME			= 21804
Global Const $ID_PARAGON_TOME			= 21805
; All Tomes
Global Const $TOMES_ARRAY[]					= [$ID_ASSASSIN_ELITETOME, $ID_MESMER_ELITETOME, $ID_NECROMANCER_ELITETOME, $ID_ELEMENTALIST_ELITETOME, $ID_MONK_ELITETOME, $ID_WARRIOR_ELITETOME, _
												$ID_RANGER_ELITETOME, $ID_DERVISH_ELITETOME, $ID_RITUALIST_ELITETOME, $ID_PARAGON_ELITETOME, $ID_ASSASSIN_TOME, $ID_MESMER_TOME, _
												$ID_NECROMANCER_TOME, $ID_ELEMENTALIST_TOME, $ID_MONK_TOME, $ID_WARRIOR_TOME, $ID_RANGER_TOME, $ID_DERVISH_TOME, $ID_RITUALIST_TOME, $ID_PARAGON_TOME]
; Elite Tomes
Global Const $ELITE_TOMES_ARRAY[]			= [$ID_ASSASSIN_ELITETOME, $ID_MESMER_ELITETOME, $ID_NECROMANCER_ELITETOME, $ID_ELEMENTALIST_ELITETOME, $ID_MONK_ELITETOME, _
												$ID_WARRIOR_ELITETOME, $ID_RANGER_ELITETOME, $ID_DERVISH_ELITETOME, $ID_RITUALIST_ELITETOME, $ID_PARAGON_ELITETOME]
Global Const $ELITE_TOMES_NAMES_ARRAY[]		= ['Elite Assassin Tome', 'Elite Mesmer Tome', 'Elite Necromancer Tome', 'Elite Elementalist Tome', 'Elite Monk Tome', _
												'Elite Warrior Tome', 'Elite Ranger Tome', 'Elite Dervish Tome', 'Elite Ritualist Tome', 'Elite Paragon Tome']
Global Const $ELITE_TOME_NAMES_FROM_IDS		= MapFromArrays($ELITE_TOMES_ARRAY, $ELITE_TOMES_NAMES_ARRAY)
;Global Const $ELITE_TOME_IDS_FROM_NAMES	= MapFromArrays($ELITE_TOMES_NAMES_ARRAY, $ELITE_TOMES_ARRAY)
; Normal Tomes
Global Const $REGULAR_TOMES_ARRAY[]			= [$ID_ASSASSIN_TOME, $ID_MESMER_TOME, $ID_NECROMANCER_TOME, $ID_ELEMENTALIST_TOME, $ID_MONK_TOME, _
												$ID_WARRIOR_TOME, $ID_RANGER_TOME, $ID_DERVISH_TOME, $ID_RITUALIST_TOME, $ID_PARAGON_TOME]
Global Const $REGULAR_TOMES_NAMES_ARRAY[]	= ['Assassin Tome', 'Mesmer Tome', 'Necromancer Tome', 'Elementalist Tome', 'Monk Tome', _
												'Warrior Tome', 'Ranger Tome', 'Dervish Tome', 'Ritualist Tome', 'Paragon Tome']
Global Const $REGULAR_TOME_NAMES_FROM_IDS	= MapFromArrays($REGULAR_TOMES_ARRAY, $REGULAR_TOMES_NAMES_ARRAY)
;Global Const $REGULAR_TOME_IDS_FROM_NAMES	= MapFromArrays($REGULAR_TOMES_NAMES_ARRAY, $REGULAR_TOMES_ARRAY)
Global Const $MAP_TOMES						= MapFromArray($TOMES_ARRAY)
Global Const $MAP_ELITE_TOMES				= MapFromArray($ELITE_TOMES_ARRAY)
Global Const $MAP_REGULAR_TOMES				= MapFromArray($REGULAR_TOMES_ARRAY)
#EndRegion Tomes


#Region Consumable Crafter Items
Global Const $ID_ARMOR_OF_SALVATION		= 24860
Global Const $ID_ESSENCE_OF_CELERITY	= 24859
Global Const $ID_GRAIL_OF_MIGHT			= 24861
Global Const $ID_POWERSTONE_OF_COURAGE	= 24862
Global Const $ID_SCROLL_OF_RESURRECTION	= 26501
Global Const $ID_STAR_OF_TRANSFERENCE	= 25896
Global Const $ID_PERFECT_SALVAGE_KIT	= 25881
Global Const $CONSETS_ARRAY[]			= [$ID_ESSENCE_OF_CELERITY, $ID_ARMOR_OF_SALVATION, $ID_GRAIL_OF_MIGHT]
Global Const $MAP_CONSETS				= MapFromArray($CONSETS_ARRAY)
#EndRegion Consumable Crafter Items


#Region Summoning Stones
Global Const $ID_MERCHANT_SUMMON				= 21154
Global Const $ID_TENGU_SUMMON					= 30209
Global Const $ID_IMPERIAL_GUARD_SUMMON			= 30210
Global Const $ID_AUTOMATON_SUMMON				= 30846
Global Const $ID_IGNEOUS_SUMMONING_STONE		= 30847
Global Const $ID_CHITINOUS_SUMMON				= 30959
Global Const $ID_MYSTICAL_SUMMON				= 30960
Global Const $ID_AMBER_SUMMON					= 30961
Global Const $ID_ARTIC_SUMMON					= 30962
Global Const $ID_DEMONIC_SUMMON					= 30963
Global Const $ID_GELATINOUS_SUMMON				= 30964
Global Const $ID_FOSSILIZED__SUMMON				= 30965
Global Const $ID_JADEITE_SUMMON					= 30966
Global Const $ID_MISCHIEVOUS_SUMMON				= 31022
Global Const $ID_FROSTY_SUMMON					= 31023
Global Const $ID_MYSTERIOUS_SUMMON				= 31155
Global Const $ID_ZAISHEN_SUMMON					= 31156
Global Const $ID_GHASTLY_SUMMON					= 32557
Global Const $ID_CELESTIAL_SUMMON				= 34176
Global Const $ID_SHINING_BLADE_SUMMON			= 35126
Global Const $ID_LEGIONNAIRE_SUMMONING_CRYSTAL	= 37810
Global Const $SUMMONING_STONES_ARRAY[]			= [$ID_MERCHANT_SUMMON, $ID_TENGU_SUMMON, $ID_IMPERIAL_GUARD_SUMMON, $ID_AUTOMATON_SUMMON, $ID_IGNEOUS_SUMMONING_STONE, _
													$ID_CHITINOUS_SUMMON, $ID_MYSTICAL_SUMMON, $ID_AMBER_SUMMON, $ID_ARTIC_SUMMON, $ID_DEMONIC_SUMMON, $ID_GELATINOUS_SUMMON, _
													$ID_FOSSILIZED__SUMMON, $ID_JADEITE_SUMMON, $ID_MISCHIEVOUS_SUMMON, $ID_FROSTY_SUMMON, $ID_MYSTERIOUS_SUMMON, _
													$ID_ZAISHEN_SUMMON, $ID_GHASTLY_SUMMON, $ID_CELESTIAL_SUMMON, $ID_SHINING_BLADE_SUMMON]
Global Const $MAP_SUMMONING_STONES				= MapFromArray($SUMMONING_STONES_ARRAY)
#EndRegion Summoning Stones


#Region Tonics
Global Const $ID_SINISTER_AUTOMATONIC_TONIC	= 4730
Global Const $ID_TRANSMOGRIFIER_TONIC		= 15837
Global Const $ID_YULETIDE_TONIC				= 21490
Global Const $ID_BEETLE_JUICE_TONIC			= 22192
Global Const $ID_ABYSSAL_TONIC				= 30624
Global Const $ID_CEREBRAL_TONIC				= 30626
Global Const $ID_MACABRE_TONIC				= 30628
Global Const $ID_TRAPDOOR_TONIC				= 30630
Global Const $ID_SEARING_TONIC				= 30632
Global Const $ID_AUTOMATONIC_TONIC			= 30634
Global Const $ID_SKELETONIC_TONIC			= 30636
Global Const $ID_BOREAL_TONIC				= 30638
Global Const $ID_GELATINOUS_TONIC			= 30640
Global Const $ID_PHANTASMAL_TONIC			= 30642
Global Const $ID_ABOMINABLE_TONIC			= 30646
Global Const $ID_FROSTY_TONIC				= 30648
Global Const $ID_MISCHIEVIOUS_TONIC			= 31020
Global Const $ID_MYSTERIOUS_TONIC			= 31141
Global Const $ID_COTTONTAIL_TONIC			= 31142
Global Const $ID_ZAISHEN_TONIC				= 31144
Global Const $ID_UNSEEN_TONIC				= 31172
Global Const $ID_SPOOKY_TONIC				= 37771
Global Const $ID_MINUTELY_MAD_KING_TONIC	= 37772
Global Const $PARTY_TONICS_ARRAY[]			= [$ID_SINISTER_AUTOMATONIC_TONIC, $ID_TRANSMOGRIFIER_TONIC, $ID_YULETIDE_TONIC, $ID_BEETLE_JUICE_TONIC, $ID_ABYSSAL_TONIC, _
												$ID_CEREBRAL_TONIC, $ID_MACABRE_TONIC, $ID_TRAPDOOR_TONIC, $ID_SEARING_TONIC, $ID_AUTOMATONIC_TONIC, $ID_SKELETONIC_TONIC, _
												$ID_BOREAL_TONIC, $ID_GELATINOUS_TONIC, $ID_PHANTASMAL_TONIC, $ID_ABOMINABLE_TONIC, $ID_FROSTY_TONIC, $ID_MISCHIEVIOUS_TONIC, _
												$ID_MYSTERIOUS_TONIC, $ID_COTTONTAIL_TONIC, $ID_ZAISHEN_TONIC, $ID_UNSEEN_TONIC, $ID_SPOOKY_TONIC, $ID_MINUTELY_MAD_KING_TONIC]
Global Const $MAP_PARTY_TONICS				= MapFromArray($PARTY_TONICS_ARRAY)

#Region EL Tonics
;Global Const $ID_EL_BEETLE_JUICE_TONIC	=
Global Const $ID_EL_COTTONTAIL_TONIC			= 31143
;Global Const $ID_EL_FROSTY_TONIC	=
Global Const $ID_EL_MISCHIEVIOUS_TONIC			= 31021
Global Const $ID_EL_SINISTER_AUTOMATONIC_TONIC	= 30827
Global Const $ID_EL_TRANSMOGRIFIER_TONIC		= 23242
Global Const $ID_EL_YULETIDE_TONIC				= 29241
Global Const $ID_EL_AVATAR_OF_BALTHAZAR_TONIC	= 36658
Global Const $ID_EL_BALTHAZARS_CHAMPION_TONIC	= 36661
Global Const $ID_EL_HENCHMAN_TONIC				= 32850
Global Const $ID_EL_FLAME_SENTINEL_TONIC		= 36664
Global Const $ID_EL_GHOSTLY_HERO_TONIC			= 36660
Global Const $ID_EL_GHOSTLY_PRIEST_TONIC		= 36663
Global Const $ID_EL_GUILD_LORD_TONIC			= 36652
;Global Const $ID_EL_KNIGHT_TONIC	=
;Global Const $ID_EL_LEGIONAIRE_TONIC	=
Global Const $ID_EL_PRIEST_OF_BALTHAZAR_TONIC	= 36659
Global Const $ID_EL_REINDEER_TONIC				= 34156
Global Const $ID_EL_CEREBRAL_TONIC				= 30627
Global Const $ID_EL_SEARING_TONIC				= 30633
Global Const $ID_EL_ABYSSAL_TONIC				= 30625
Global Const $ID_EL_UNSEEN_TONIC				= 31173
Global Const $ID_EL_PHANTASMAL_TONIC			= 30643
Global Const $ID_EL_AUTOMATONIC_TONIC			= 30635
Global Const $ID_EL_BOREAL_TONIC				= 30639
Global Const $ID_EL_TRAPDOOR_TONIC				= 30631
Global Const $ID_EL_MACABRE_TONIC				= 30629
Global Const $ID_EL_SKELETONIC_TONIC			= 30637
Global Const $ID_EL_GELATINOUS_TONIC			= 30641
Global Const $ID_EL_ABOMINABLE_TONIC			= 30647
Global Const $ID_EL_DESTROYER_TONIC				= 36457
Global Const $ID_EL_KUUNAVANG_TONIC				= 36461
Global Const $ID_EL_MARGONITE_TONIC				= 36456
Global Const $ID_EL_SLIGHTLY_MAD_KING_TONIC		= 36460
Global Const $ID_EL_GWEN_TONIC					= 36442
Global Const $ID_EL_KEIRAN_THACKERAY_TONIC		= 36450
Global Const $ID_EL_MIKU_TONIC					= 36451
Global Const $ID_EL_SHIRO_TONIC					= 36453
Global Const $ID_EL_PRINCE_RURIK_TONIC			= 36455
Global Const $ID_EL_ANTON_TONIC					= 36447
Global Const $ID_EL_JORA_TONIC					= 36455
Global Const $ID_EL_KOSS_TONIC					= 36425
Global Const $ID_EL_MOX_TONIC					= 36452
Global Const $ID_EL_MASTER_OF_WHISPERS_TONIC	= 36433
Global Const $ID_EL_OGDEN_STONEHEALER_TONIC		= 36440
Global Const $ID_EL_QUEEN_SALMA_TONIC			= 36458
Global Const $ID_EL_PYRE_FIERCEHOT_TONIC		= 36446
Global Const $ID_EL_RAZAH_TONIC					= 36437
Global Const $ID_EL_ZHED_SHADOWHOOF_TONIC		= 36431
Global Const $ID_EL_ACOLYTE_JIN_TONIC			= 36428
Global Const $ID_EL_ACOLYTE_SOUSUKE_TONIC		= 36429
Global Const $ID_EL_DUNKORO_TONIC				= 36426
Global Const $ID_EL_GOREN_TONIC					= 36434
Global Const $ID_EL_HAYDA_TONIC					= 36448
Global Const $ID_EL_KAHMU_TONIC					= 36444
Global Const $ID_EL_LIVIA_TONIC					= 36449
Global Const $ID_EL_MAGRID_THE_SLY_TONIC		= 36432
Global Const $ID_EL_MELONNI_TONIC				= 36427
Global Const $ID_EL_TAHLKORA_TONIC				= 36430
Global Const $ID_EL_NORGU_TONIC					= 36435
Global Const $ID_EL_MORGAHN_TONIC				= 36436
Global Const $ID_EL_OLIAS_TONIC					= 36438
Global Const $ID_EL_ZENMAI_TONIC				= 36439
Global Const $ID_EL_VEKK_TONIC					= 36441
Global Const $ID_EL_XANDRA_TONIC				= 36443
Global Const $ID_EL_CRATE_OF_FIREWORKS			= 31147
Global Const $EL_TONIC_ARRAY[]					= []
Global Const $MAP_EL_TONICS						= MapFromArray($EL_TONIC_ARRAY)
#EndRegion EL Tonics
#EndRegion Tonics


#Region Minis
; First year
Global Const $ID_PRINCE_RURIK_MINI						= 13790
Global Const $ID_SHIRO_MINI								= 13791
Global Const $ID_CHARR_SHAMAN_MINI						= 13784
Global Const $ID_FUNGAL_WALLOW_MINI						= 13782
Global Const $ID_BONE_DRAGON_MINI						= 13783
Global Const $ID_HYDRA_MINI								= 13787
Global Const $ID_JADE_ARMOR_MINI						= 13788
Global Const $ID_KIRIN_MINI								= 13789
Global Const $ID_JUNGLE_TROLL_MINI						= 13794
Global Const $ID_NECRID_HORSEMAN_MINI					= 13786
Global Const $ID_TEMPLE_GUARDIAN_MINI					= 13792
Global Const $ID_BURNING_TITAN_MINI						= 13793
Global Const $ID_SIEGE_TURTLE_MINI						= 13795
Global Const $ID_WHIPTAIL_DEVOURER_MINI					= 13785
; Second year
Global Const $ID_GWEN_MINI								= 22753
Global Const $ID_WATER_DJINN_MINI						= 22754
Global Const $ID_LICH_MINI								= 22755
Global Const $ID_ELF_MINI								= 22756
Global Const $ID_PALAWA_JOKO_MINI						= 22757
Global Const $ID_KOSS_MINI								= 22758
Global Const $ID_AATXE_MINI								= 22765
Global Const $ID_HARPY_RANGER_MINI						= 22761
Global Const $ID_HEKET_WARRIOR_MINI						= 22760
Global Const $ID_JUGGERNAUT_MINI						= 22762
Global Const $ID_MANDRAGOR_IMP_MINI						= 22759
Global Const $ID_THORN_WOLF_MINI						= 22766
Global Const $ID_WIND_RIDER_MINI						= 22763
Global Const $ID_FIRE_IMP_MINI							= 22764
; Third year
Global Const $ID_BLACK_BEAST_OF_AAAAARRRRRRGGGHHH_MINI	= 30611
Global Const $ID_IRUKANDJI_MINI							= 30613
Global Const $ID_MAD_KING_THORN_MINI					= 30614
Global Const $ID_RAPTOR_MINI							= 30619
Global Const $ID_CLOUDTOUCHED_SIMIAN_MINI				= 30621
Global Const $ID_WHITE_RABBIT_MINI						= 30623
Global Const $ID_FREEZIE_MINI							= 30612
Global Const $ID_NORNBEAR_MINI							= 32519
Global Const $ID_OOZE_MINI								= 30618
Global Const $ID_ABYSSAL_MINI							= 30610
Global Const $ID_CAVE_SPIDER_MINI						= 30622
Global Const $ID_FOREST_MINOTAUR_MINI					= 30615
Global Const $ID_MURSAAT_MINI							= 30616
Global Const $ID_ROARING_ETHER_MINI						= 30620
; Fourth year
Global Const $ID_EYE_OF_JANTHIR_MINI					= 32529
Global Const $ID_DREDGE_BRUTE_MINI						= 32517
Global Const $ID_TERRORWEB_DRYDER_MINI					= 32518
Global Const $ID_ABOMINATION_MINI						= 32519
Global Const $ID_FLAME_DJINN_MINI						= 32528
Global Const $ID_FLOWSTONE_ELEMENTAL_MINI				= 32525
Global Const $ID_NIAN_MINI								= 32526
Global Const $ID_DAGNAR_STONEPATE_MINI					= 32527
Global Const $ID_JORA_MINI								= 32524
Global Const $ID_DESERT_GRIFFON_MINI					= 32521
Global Const $ID_KRAIT_NEOSS_MINI						= 32520
Global Const $ID_KVELDULF_MINI							= 32522
Global Const $ID_QUETZAL_SLY_MINI						= 32523
Global Const $ID_WORD_OF_MADNESS_MINI					= 32516
; Fifth year
Global Const $ID_MOX_MINI								= 34400
Global Const $ID_VENTARI_MINI							= 34395
Global Const $ID_OOLA_MINI								= 34396
Global Const $ID_CANDYSMITH_MARLEY_MINI					= 34397
Global Const $ID_ZHU_HANUKU_MINI						= 34398
Global Const $ID_KING_ADELBERN_MINI						= 34399
Global Const $ID_COBALT_SCABARA_MINI					= 34393
Global Const $ID_FIRE_DRAKE_MINI						= 34390
Global Const $ID_OPHIL_NAHUALLI_MINI					= 34392
Global Const $ID_SCOURGE_MANTA_MINI						= 34394
Global Const $ID_SEER_MINI								= 34386
Global Const $ID_SHARD_WOLF_MINI						= 34389
Global Const $ID_SIEGE_DEVOURER							= 34387
Global Const $ID_SUMMIT_GIANT_HERDER					= 34391
; Seventh
Global Const $ID_VIZU_MINI								= 22196
Global Const $ID_SHIROKEN_ASSASSIN_MINI					= 22195
Global Const $ID_ZHED_SHADOWHOOF_MINI					= 22197
Global Const $ID_NAGA_RAINCALLER_MINI					= 15515
Global Const $ID_ONI_MINI								= 15516
; Collector Edition
Global Const $ID_KUUNAVANG_MINI							= 12389
Global Const $ID_VARESH_OSSA_MINI						= 21069
; In-Game Reward
Global Const $ID_MALLYX_MINI							= 21229
Global Const $ID_BLACK_MOA_CHICK_MINI					= 25499
Global Const $ID_GWEN_DOLL_MINI							= 31157
Global Const $ID_YAKKINGTON_MINI						= 32515
Global Const $ID_BROWN_RABBIT_MINI						= 31158
;Global Const $ID_GHOSTLY_HERO_MINI	=
Global Const $ID_MINISTER_REIKO_MINI					= 30224
Global Const $ID_ECCLESIATE_XUN_RAO_MINI				= 30225
;Global Const $ID_PEACEKEEPER_ENFORCER_MINI	=
Global Const $ID_EVENNIA_MINI							= 35128
Global Const $ID_LIVIA_MINI								= 35129
Global Const $ID_PRINCESS_SALMA_MINI					= 35130
Global Const $ID_CONFESSOR_DORIAN_MINI					= 35132
Global Const $ID_CONFESSOR_ISAIAH_MINI					= 35131
Global Const $ID_GUILD_LORD_MINI						= 36648
Global Const $ID_GHOSTLY_PRIEST_MINI					= 36650
Global Const $ID_RIFT_WARDEN_MINI						= 36651
Global Const $ID_HIGH_PRIEST_ZHANG_MINI					= 36649
Global Const $ID_DHUUM_MINI								= 32822
Global Const $ID_SMITE_CRAWLER_MINI						= 32556
; Special Event Minis
;Global Const $ID_GREASED_LIGHTNING_MINI	=
Global Const $ID_PIG_MINI								= 21806
Global Const $ID_CELESTIAL_PIG_MINI						= 29412
Global Const $ID_CELESTIAL_RAT_MINI						= 29413
Global Const $ID_CELESTIAL_OX_MINI						= 29414
Global Const $ID_CELESTIAL_TIGER_MINI					= 29415
Global Const $ID_CELESTIAL_RABBIT_MINI					= 29416
Global Const $ID_CELESTIAL_DRAGON_MINI					= 29417
Global Const $ID_CELESTIAL_SNAKE_MINI					= 29418
Global Const $ID_CELESTIAL_HORSE_MINI					= 29419
Global Const $ID_CELESTIAL_SHEEP_MINI					= 29420
Global Const $ID_CELESTIAL_MONKEY_MINI					= 29421
Global Const $ID_CELESTIAL_ROOSTER_MINI					= 29422
Global Const $ID_CELESTIAL_DOG_MINI						= 29423
Global Const $ID_WORLD_FAMOUS_RACING_BEETLE_MINI		= 37792
;Global Const $ID_LEGIONNAIRE_MINI						=
; Promotional
Global Const $ID_ASURA_MINI								= 22189
Global Const $ID_DESTROYER_OF_FLESH_MINI				= 22250
Global Const $ID_GRAY_GIANT_MINI						= 17053
Global Const $ID_GRAWL_MINI								= 22822
Global Const $ID_CERATADON_MINI							= 28416
; Miscellaneous
;Global Const $ID_KANAXAI_MINI							=
Global Const $ID_POLAR_BEAR_MINI						= 21439
Global Const $ID_MAD_KINGS_GUARD_MINI					= 32555
Global Const $ID_PANDA_MINI								= 15517
;Global Const $ID_LONGHAIR_YETI_MINI					=
#EndRegion Minis


#Region Ultra rare skins
; Missing IDs
;Global Const $ID_ASTRAL_STAFF
;Global Const $ID_DRYAD_BOW
;Global Const $ID_GOLDHORN_STAFF
;Global Const $ID_NOTCHED_BLADE
;Global Const $ID_CERULEAN_EDGE
;Global Const $ID_CHRYSOCOLA_STAFF
;Global Const $ID_COBALT_STAFF
;Global Const $ID_VIOLET_EDGE
;Global Const $ID_BONECAGE_SCYTHE
;Global Const $ID_DEMON_FANGS
;Global Const $ID_ICICLE_STAFF
;Global Const $ID_TURQUOISE_STAFF
;Global Const $ID_EMERALD_EDGE
;Global Const $ID_TOPAZ_SCEPTER
;Global Const $ID_GOLDEN_HAMMER
;Global Const $ID_CLOCKWORK_SCYTHE
;Global Const $ID_SIGNET_SHIELD
;Global Const $ID_STEELHEAD_SCYTHE
;Global Const $ID_INSECTOID_SCYTHE
;Global Const $ID_INSECTOID_STAFF
;Global Const $ID_EMBERCREST_STAFF
;Global Const $ID_SINGING_BLADE

;Global Const $ID_CHAOTIC_ENVOY_STAFF				=
;Global Const $ID_DARK_ENVOY_STAFF					=
;Global Const $ID_ELEMENTAL_ENVOY_STAFF				=
;Global Const $ID_SPIRITUAL_ENVOY_STAFF				=

Global Const $ID_ETERNAL_BLADE						= 1045
Global Const $ID_OBSIDIAN_EDGE						= 1900
Global Const $ID_EMERALD_BLADE						= 1976
Global Const $ID_STORM_DAGGERS						= 1986
Global Const $ID_VOLTAIC_SPEAR						= 2071
Global Const $ID_DHUUMS_SOUL_REAPER					= 32823
Global Const $ID_AUREATE_BLADE						= 2124
Global Const $ID_EAGLECREST_AXE						= 1985
Global Const $ID_WINGCREST_MAUL						= 2048
Global Const $ID_DEMONCREST_SPEAR					= 2079
Global Const $ID_SILVERWING_RECURVE_BOW				= 2039
Global Const $ID_ONYX_SCEPTER						= 2394
Global Const $ID_TENTACLE_SCYTHE					= 2063
Global Const $ID_MOLDAVITE_STAFF					= 2328
Global Const $ID_ANCIENT_MOSS_STAFF					= 2376
Global Const $ID_SUNTOUCHED_STAFF					= 2381
Global Const $ID_CRYSTAL_FLAME_STAFF				= 2366

#Region Envoy Weapons
; Green Envoys
Global Const $ID_DEMRIKOVS_JUDGEMENT				= 36670
Global Const $ID_VETAURAS_HARBINGER					= 36678
Global Const $ID_TORIVOS_RAGE						= 36680
Global Const $ID_HELEYNES_INSIGHT					= 36676
; Gold Envoys
Global Const $ID_ENVOY_SWORD						= 36669
Global Const $ID_ENVOY_AXE							= 36679
Global Const $ID_DIVINE_ENVOY_STAFF					= 36674
Global Const $ID_ENVOY_SCYTHE						= 36677
#EndRegion Envoy Weapons

#Region Froggy
Global Const $ID_FROGGY_DOMINATION					= 1953
Global Const $ID_FROGGY_FAST_CASTING				= 1956
Global Const $ID_FROGGY_ILLUSION					= 1957
Global Const $ID_FROGGY_INSPIRATION					= 1958
Global Const $ID_FROGGY_SOUL_REAPING				= 1959
Global Const $ID_FROGGY_BLOOD						= 1960
Global Const $ID_FROGGY_CURSES						= 1961
Global Const $ID_FROGGY_DEATH						= 1962
Global Const $ID_FROGGY_AIR							= 1963
Global Const $ID_FROGGY_EARTH						= 1964
Global Const $ID_FROGGY_ENERGY_STORAGE				= 1965
Global Const $ID_FROGGY_FIRE						= 1966
Global Const $ID_FROGGY_WATER						= 1967
Global Const $ID_FROGGY_DIVINE						= 1968
Global Const $ID_FROGGY_HEALING						= 1969
Global Const $ID_FROGGY_PROTECTION					= 1970
Global Const $ID_FROGGY_SMITING						= 1971
Global Const $ID_FROGGY_COMMUNING					= 1972
Global Const $ID_FROGGY_SPAWNING					= 1973
Global Const $ID_FROGGY_RESTORATION					= 1974
Global Const $ID_FROGGY_CHANNELING					= 1975
#EndRegion Froggy

#Region Bone Dragon Staff
Global Const $ID_BONE_DRAGON_STAFF_DOMINATION		= 1987
Global Const $ID_BONE_DRAGON_STAFF_FAST_CASTING		= 1988
Global Const $ID_BONE_DRAGON_STAFF_ILLUSION			= 1989
Global Const $ID_BONE_DRAGON_STAFF_INSPIRATION		= 1990
Global Const $ID_BONE_DRAGON_STAFF_SOUL_REAPING		= 1991
Global Const $ID_BONE_DRAGON_STAFF_BLOOD			= 1992
Global Const $ID_BONE_DRAGON_STAFF_CURSES			= 1993
Global Const $ID_BONE_DRAGON_STAFF_DEATH			= 1994
Global Const $ID_BONE_DRAGON_STAFF_AIR				= 1995
Global Const $ID_BONE_DRAGON_STAFF_EARTH			= 1996
Global Const $ID_BONE_DRAGON_STAFF_ENERGY_STORAGE	= 1997
Global Const $ID_BONE_DRAGON_STAFF_FIRE				= 1998
Global Const $ID_BONE_DRAGON_STAFF_WATER			= 1999
Global Const $ID_BONE_DRAGON_STAFF_DIVINE			= 2000
Global Const $ID_BONE_DRAGON_STAFF_HEALING			= 2001
Global Const $ID_BONE_DRAGON_STAFF_PROTECTION		= 2002
Global Const $ID_BONE_DRAGON_STAFF_SMITING			= 2003
Global Const $ID_BONE_DRAGON_STAFF_COMMUNING		= 2004
Global Const $ID_BONE_DRAGON_STAFF_SPAWNING			= 2005
Global Const $ID_BONE_DRAGON_STAFF_RESTORATION		= 2006
Global Const $ID_BONE_DRAGON_STAFF_CHANNELING		= 2007
#EndRegion Bone Dragon Staff

#Region Wintergreen Weapons
Global Const $ID_WINTERGREEN_AXE					= 15835
Global Const $ID_WINTERGREEN_BOW					= 15836
Global Const $ID_WINTERGREEN_SWORD					= 16130
Global Const $ID_WINTERGREEN_DAGGERS				= 15838
Global Const $ID_WINTERGREEN_HAMMER					= 15839
Global Const $ID_WINTERGREEN_WAND					= 15840
Global Const $ID_WINTERGREEN_SCYTHE					= 15877
Global Const $ID_WINTERGREEN_SHIELD					= 15878
Global Const $ID_WINTERGREEN_SPEAR					= 15971
Global Const $ID_WINTERGREEN_STAFF					= 16128
#EndRegion Wintergreen Weapons

#Region Celestial Compass
Global Const $ID_CELESTIAL_COMPASS_DOMINATION		= 1055
Global Const $ID_CELESTIAL_COMPASS_FAST_CASTING		= 1058
Global Const $ID_CELESTIAL_COMPASS_ILLUSION			= 1060
Global Const $ID_CELESTIAL_COMPASS_INSPIRATION		= 1064
Global Const $ID_CELESTIAL_COMPASS_SOUL_REAPING		= 1752
Global Const $ID_CELESTIAL_COMPASS_BLOOD			= 1065
Global Const $ID_CELESTIAL_COMPASS_CURSES			= 1066
Global Const $ID_CELESTIAL_COMPASS_DEATH			= 1067
Global Const $ID_CELESTIAL_COMPASS_AIR				= 1768
Global Const $ID_CELESTIAL_COMPASS_EARTH			= 1769
Global Const $ID_CELESTIAL_COMPASS_ENERGY_STORAGE	= 1770
Global Const $ID_CELESTIAL_COMPASS_FIRE				= 1771
Global Const $ID_CELESTIAL_COMPASS_WATER			= 1772
Global Const $ID_CELESTIAL_COMPASS_DIVINE			= 1773
Global Const $ID_CELESTIAL_COMPASS_HEALING			= 1870
Global Const $ID_CELESTIAL_COMPASS_PROTECTION		= 1879
Global Const $ID_CELESTIAL_COMPASS_SMITING			= 1880
Global Const $ID_CELESTIAL_COMPASS_COMMUNING		= 1881
Global Const $ID_CELESTIAL_COMPASS_SPAWNING			= 1883
Global Const $ID_CELESTIAL_COMPASS_RESTORATION		= 1884
Global Const $ID_CELESTIAL_COMPASS_CHANNELING		= 1885
#EndRegion Celestial Compass
#EndRegion Ultra rare skins


#Region Rare skins
; Which skin is that ID ? Only obsidian one is worth it
; Called orr staff but there are no orr staves
Global Const $ID_EARTH_STAFF						= 603
; Are those two the 'good' versions ?
Global Const $ID_SEPHIS_AXE							= 120
Global Const $ID_SERPENT_AXE						= 118

; Missing IDs
;Global Const $ID_NAGA_SHORTBOW						=
;Global Const $ID_NAGA_LONGBOW						=
;Global Const $ID_AMETHYST_AEGIS					=
;Global Const $ID_STRAW_EFFIGY						=
;Global Const $ID_COLOSSAL_PICK						=
;Global Const $ID_DESOLATION_MAUL					=
;Global Const $ID_COCKATRICE_STAFF					=
;Global Const $ID_DEAD_STAFF						=
;Global Const $ID_FORBIDDEN_STAFF					=
;Global Const $ID_GHOSTLY_STAFF						=
;Global Const $ID_OUTCAST_STAFF						=
;Global Const $ID_SHADOW_STAFF						=
;Global Const $ID_DRAGONS_BREATH_WAND				=
;Global Const $ID_GOLDEN_PILLAR						=
;Global Const $ID_JELLYFISH_WAND					=
;Global Const $ID_KOI_SCEPTER						=
;Global Const $ID_WATER_SPIRIT_ROD					=

;Global Const $ID_ZODIAC_STAFF						=
;Global Const $ID_ALL_ZODIAC_WEAPONS				=

; This one needs to be the eye version
;Global Const $ID_FLAME_ARTIFACT					=

; Unknown IDs
;3270, 869, 946, 949		; Echovald Shield, Gothic Defender ???
;3270						; magma shield/summit shield ???
;870, 869, 1101				; more canthan rare skins
;1439, 1557					; Elonian Swords (Colossal, Tattooed, Dead, etc)

Global Const $ID_CHAOS_AXE							= 111

; Bow
Global Const $ID_ETERNAL_BOW						= 133
Global Const $ID_STORM_BOW							= 145

; Focii
Global Const $ID_PAPER_FAN							= 775
Global Const $ID_PAPER_FAN_2						= 776
Global Const $ID_PAPER_FAN_3						= 789
Global Const $ID_PAPER_FAN_4						= 858
Global Const $ID_PAPER_FAN_5						= 866
Global Const $ID_PAPER_LANTERN						= 896
Global Const $ID_JUG								= 874
Global Const $ID_JUG_2								= 875
Global Const $ID_JUG_3								= 1022
;Global Const $ID_JUG_?								=
Global Const $ID_PLAGUEBORN_FOCUS					= 1026
Global Const $ID_PLAGUEBORN_FOCUS_2					= 1027
;Global Const $ID_PLAGUEBORN_FOCUS_?				=
Global Const $ID_PRONGED_FAN						= 1728
;Global Const $ID_PRONGED_FAN_?						=

; Scythe
Global Const $ID_DRACONIC_SCYTHE					= 1978

; Shield
Global Const $ID_DEMONIC_AEGIS						= 1893
Global Const $ID_DRACONIC_AEGIS						= 1896
Global Const $ID_ETERNAL_SHIELD						= 332
Global Const $ID_AMBER_SHIELD						= 940
Global Const $ID_AMBER_SHIELD_2						= 941
Global Const $ID_BLADED_SHIELD						= 777
Global Const $ID_BLADED_SHIELD_2					= 778
Global Const $ID_ECHOVALD_SHIELD					= 944
Global Const $ID_ECHOVALD_SHIELD_2					= 945
Global Const $ID_EMBLAZONED_DEFENDER				= 947
Global Const $ID_EXALTED_AEGIS						= 1037
Global Const $ID_GOTHIC_DEFENDER					= 950
Global Const $ID_GOTHIC_DEFENDER_2					= 951
Global Const $ID_GUARDIAN_OF_THE_HUNT				= 1320
Global Const $ID_GUARDIAN_OF_THE_HUNT_2				= 1321
Global Const $ID_KAPPA_SHIELD						= 952
Global Const $ID_KAPPA_SHIELD_2						= 953
Global Const $ID_MAGMA_SHIELD						= 344
Global Const $ID_ORNATE_SHIELD						= 955
Global Const $ID_PLAGUEBORN_SHIELD					= 959
Global Const $ID_PLAGUEBORN_SHIELD_2				= 960
Global Const $ID_OUTCAST_SHIELD						= 956
Global Const $ID_OUTCAST_SHIELD_2					= 958
Global Const $ID_SEA_PURSE_SHIELD					= 1589
Global Const $ID_STONE_SUMMIT_SHIELD				= 341
Global Const $ID_SUMMIT_WARLORD_SHIELD				= 342
Global Const $ID_AMETHYST_AEGIS_1					= 2422
Global Const $ID_AMETHYST_AEGIS_2					= 2423

; Staff
Global Const $ID_BO_STAFF							= 735
Global Const $ID_PLATINUM_STAFF						= 873
Global Const $ID_DRAGON_STAFF						= 736
Global Const $ID_RAVEN_STAFF						= 391
Global Const $ID_JEWELED_STAFF						= 352
;Global Const $ID_JEWELED_STAFF_?					=

; Sword
Global Const $ID_CRYSTALLINE_SWORD					= 399
Global Const $ID_BROADSWORD							= 737
Global Const $ID_DADAO_SWORD						= 739
Global Const $ID_JITTE								= 741
Global Const $ID_KATANA								= 742
Global Const $ID_SHINOBI_BLADE						= 744
Global Const $ID_ONI_BLADE							= 794
Global Const $ID_GOLDEN_PHOENIX_BLADE				= 795
Global Const $ID_COLOSSAL_SCIMITAR					= 1556
Global Const $ID_TATOOED_SCIMITAR					= 1197
Global Const $ID_ADAMANTINE_FALCHION				= 1563
Global Const $ID_ORNATE_SCIMITAR					= 1569

; Wand
Global Const $ID_PLATINUM_WAND						= 1011
Global Const $ID_VOLTAIC_WAND						= 1018
Global Const $ID_WAYWARD_WAND						= 977

#Region Celestial
Global Const $ID_CELESTIAL_SHIELD					= 942
Global Const $ID_CELESTIAL_SHIELD_2					= 943
Global Const $ID_CELESTIAL_SCEPTER					= 926
Global Const $ID_CELESTIAL_SWORD					= 790
Global Const $ID_CELESTIAL_DAGGERS					= 761
Global Const $ID_CELESTIAL_HAMMER					= 769
Global Const $ID_CELESTIAL_AXE						= 747
Global Const $ID_CELESTIAL_STAFF					= 785
Global Const $ID_CELESTIAL_LONGBOW					= 1068
#EndRegion Celestial

#Region Zodiac
Global Const $ID_ZODIAC_SHIELD						= 1039
Global Const $ID_ZODIAC_LONGBOW						= 966
#EndRegion Zodiac
#EndRegion Rare skins


#Region Anniversary Weapon skins
#Region Tyria
Global Const $ID_ITHAS_BOW								= 2011
Global Const $ID_CHIMERIC_PRISM_FAST_CASTING			= 2012
Global Const $ID_CHIMERIC_PRISM_SOUL_REAPING			= 2013
Global Const $ID_CHIMERIC_PRISM_ENERGY_STORAGE			= 2014
Global Const $ID_CHIMERIC_PRISM_DIVINE_FAVOR			= 2015
Global Const $ID_CHIMERIC_PRISM_SPAWNING_POWER			= 2016
Global Const $ID_BONE_IDOL_SOUL_REAPING					= 2017
Global Const $ID_BONE_IDOL_BLOOD_MAGIC					= 2018
Global Const $ID_BONE_IDOL_CURSES						= 2019
Global Const $ID_BONE_IDOL_DEATH_MAGIC					= 2020
Global Const $ID_CANTHAN_TARGE_TACTIC					= 2444
Global Const $ID_CANTHAN_TARGE_STRENGTH					= 2445
Global Const $ID_CANTHAN_TARGE_LEADERSHIP				= 2446
Global Const $ID_CENSORS_ICON_DIVINE_FAVOR				= 2100
Global Const $ID_CENSORS_ICON_HEALING_PRAYERS			= 2101
Global Const $ID_CENSORS_ICON_PROTECTION_PRAYERS		= 999999
Global Const $ID_CENSORS_ICON_SMITING_PRAYERS			= 999999

Global Const $ID_WAR_PICK								= 999999
#EndRegion Tyria

#Region Cantha
Global Const $ID_DRAGON_FANGS							= 2460
Global Const $ID_SPIRITBINDER_COMMUNING					= 2464
Global Const $ID_SPIRITBINDER_SPAWNING_POWER			= 2465
Global Const $ID_SPIRITBINDER_RESTORATION				= 2466
Global Const $ID_SPIRITBINDER_CHANNELING				= 2467
Global Const $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_STRENGTH	= 2469
Global Const $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_TACTIC	= 2470
Global Const $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_LEADERSHIP= 2470
#EndRegion Cantha

#Region Elona
Global Const $ID_SOULBREAKER							= 2468
Global Const $ID_SUNSPEAR								= 2471
#EndRegion Elona

#Region EotN
Global Const $ID_DARKSTEEL_LONGBOW						= 2472
Global Const $ID_GLACIAL_BLADE							= 2473
Global Const $ID_GLACIAL_BLADES							= 2474
Global Const $ID_HOURGLASS_STAFF_DOMINATION_MAGIC		= 2475
Global Const $ID_HOURGLASS_STAFF_FAST_CASTING			= 2476
Global Const $ID_HOURGLASS_STAFF_ILLUSION_MAGIC			= 2477
Global Const $ID_HOURGLASS_STAFF_INSPIRATION_MAGIC		= 2478
Global Const $ID_HOURGLASS_STAFF_SOUL_REAPING			= 2479
Global Const $ID_HOURGLASS_STAFF_BLOOD_MAGIC			= 2480
Global Const $ID_HOURGLASS_STAFF_CURSES					= 2481
Global Const $ID_HOURGLASS_STAFF_DEATH_MAGIC			= 2482
Global Const $ID_HOURGLASS_STAFF_AIR_MAGIC				= 2483
Global Const $ID_HOURGLASS_STAFF_EARTH_MAGIC			= 2484
Global Const $ID_HOURGLASS_STAFF_ENERGY_STORAGE			= 2485
Global Const $ID_HOURGLASS_STAFF_FIRE_MAGIC				= 2486
Global Const $ID_HOURGLASS_STAFF_WATER_MAGIC			= 2487
Global Const $ID_HOURGLASS_STAFF_DIVINE_FAVOR			= 2488
Global Const $ID_HOURGLASS_STAFF_HEALING_PRAYERS		= 2489
Global Const $ID_HOURGLASS_STAFF_PROTECTION_PRAYERS		= 2490
Global Const $ID_HOURGLASS_STAFF_SMITING_PRAYERS		= 2491
Global Const $ID_HOURGLASS_STAFF_COMMUNING				= 2492
Global Const $ID_HOURGLASS_STAFF_SPAWNING_POWER			= 2493
Global Const $ID_HOURGLASS_STAFF_RESTORATION			= 2494
Global Const $ID_HOURGLASS_STAFF_CHANNELING				= 2495
Global Const $ID_LESSER_ETCHED_SWORD					= 2102
Global Const $ID_ETCHED_SWORD							= 2134
Global Const $ID_GREATER_ETCHED_SWORD					= 2103
Global Const $ID_ARCED_BLADE							= 999999
Global Const $ID_GREATER_ARCED_BLADE					= 999999
Global Const $ID_LESSER_GRANITE_EDGE					= 2116
Global Const $ID_GRANITE_EDGE							= 999999
Global Const $ID_GREATER_GRANITE_EDGE					= 2117
Global Const $ID_LESSER_STONEBLADE						= 1955
Global Const $ID_STONEBLADE								= 2125
Global Const $ID_GREATER_STONEBLADE						= 1956
#EndRegion EotN

#Region Any
Global Const $ID_SCORPION_BOW							= 2008
Global Const $ID_SCORPIONS_LUST							= 2009
Global Const $ID_BLACK_HAWKS_LUST						= 2010
Global Const $ID_STORM_EMBER_AIR_MAGIC					= 2021
Global Const $ID_STORM_EMBER_EARTH_MAGIC				= 2022
Global Const $ID_STORM_EMBER_ENERGY_STORAGE				= 2023
Global Const $ID_STORM_EMBER_FIRE_MAGIC					= 2024
Global Const $ID_STORM_EMBER_WATER_MAGIC				= 2025
Global Const $ID_LIONS_PRIDE_AIR_MAGIC					= 2026
Global Const $ID_LIONS_PRIDE_EARTH_MAGIC				= 2027
Global Const $ID_LIONS_PRIDE_ENERGY_STORAGE				= 2028
Global Const $ID_LIONS_PRIDE_FIRE_MAGIC					= 2029
Global Const $ID_LIONS_PRIDE_WATER_MAGIC				= 2030

Global Const $ID_TIGERS_PRIDE_FAST_CASTING				= 2031
Global Const $ID_TIGERS_PRIDE_SOUL_REAPING				= 2045
Global Const $ID_TIGERS_PRIDE_ENERGY_STORAGE			= 2047
Global Const $ID_TIGERS_PRIDE_DIVINE_FAVOR				= 2054
Global Const $ID_TIGERS_PRIDE_COMMUNING					= 2055

Global Const $ID_HEAVENS_ARCH_DIVINE_FAVOR				= 2056
Global Const $ID_HEAVENS_ARCH_HEALING_PRAYERS			= 2057
Global Const $ID_HEAVENS_ARCH_PROTECTION_PRAYERS		= 2066
Global Const $ID_HEAVENS_ARCH_SMITING_PRAYERS			= 2067

Global Const $ID_FOXS_GREED_DIVINE_FAVOR				= 2068
Global Const $ID_FOXS_GREED_HEALING_PRAYERS				= 2069
Global Const $ID_FOXS_GREED_PROTECTION_PRAYERS			= 2070
Global Const $ID_FOXS_GREED_SMITING_PRAYERS				= 2080
Global Const $ID_FOXS_GREED_COMMUNING					= 2081
Global Const $ID_FOXS_GREED_SPAWNING_POWER				= 2082
Global Const $ID_FOXS_GREED_RESTORATION					= 2083
Global Const $ID_FOXS_GREED_CHANNELING					= 2084

Global Const $ID_WOLFS_GREED_DIVINE_FAVOR				= 2085
Global Const $ID_WOLFS_GREED_HEALING_PRAYERS			= 2087
Global Const $ID_WOLFS_GREED_PROTECTION_PRAYERS			= 2088
Global Const $ID_WOLFS_GREED_SMITING_PRAYERS			= 2090
Global Const $ID_WOLFS_GREED_COMMUNING					= 2091
Global Const $ID_WOLFS_GREED_SPAWNING_POWER				= 2092
Global Const $ID_WOLFS_GREED_RESTORATION				= 2094
Global Const $ID_WOLFS_GREED_CHANNELING					= 2095

Global Const $ID_BEARS_SLOTH							= 2239

Global Const $ID_HOGS_GLUTTONY_TACTICS					= 2438
Global Const $ID_HOGS_GLUTTONY_STRENGTH					= 2339
Global Const $ID_HOGS_GLUTTONY_LEADERSHIP				= 2440

Global Const $ID_SNAKES_ENVY_SOUL_REAPING				= 2451
Global Const $ID_SNAKES_ENVY_BLOOD_MAGIC				= 2452
Global Const $ID_SNAKES_ENVY_CURSES						= 2453
Global Const $ID_SNAKES_ENVY_DEATH_MAGIC				= 2454
Global Const $ID_UNICORNS_WRATH_DOMINATION_MAGIC		= 2246
Global Const $ID_UNICORNS_WRATH_FAST_CASTING			= 2424
Global Const $ID_UNICORNS_WRATH_ILLUSION_MAGIC			= 2425
Global Const $ID_UNICORNS_WRATH_INSPIRATION_MAGIC		= 2426
Global Const $ID_UNICORNS_WRATH_SOUL_REAPING			= 2427
Global Const $ID_UNICORNS_WRATH_ENERGY_STORAGE			= 2428
Global Const $ID_UNICORNS_WRATH_DIVINE_FAVOR			= 2429
Global Const $ID_UNICORNS_WRATH_COMMUNING				= 2430
Global Const $ID_DRAGONS_ENVY_FAST_CASTING				= 2455
Global Const $ID_DRAGONS_ENVY_SOUL_REAPING				= 2456
Global Const $ID_DRAGONS_ENVY_ENERGY_STORAGE			= 2457
Global Const $ID_DRAGONS_ENVY_DIVINE_FAVOR				= 2458
Global Const $ID_DRAGONS_ENVY_COMMUNING					= 2459
Global Const $ID_PEACOCKS_WRATH_DOMINATION_MAGIC		= 2431
Global Const $ID_PEACOCKS_WRATH_FAST_CASTING			= 2432
Global Const $ID_PEACOCKS_WRATH_ILLUSION_MAGIC			= 2433
Global Const $ID_PEACOCKS_WRATH_INSPIRATION_MAGIC		= 2434
Global Const $ID_RHINOS_SLOTH							= 2240
Global Const $ID_SPIDERS_GLUTTONY_TACTICS				= 2441
Global Const $ID_SPIDERS_GLUTTONY_STRENGTH				= 2442
Global Const $ID_SPIDERS_GLUTTONY_LEADERSHIP			= 2443

Global Const $ID_FURIOUS_BONECRUSHER					= 2133
Global Const $ID_BRONZE_GUARDIAN_TACTICS				= 2435
Global Const $ID_BRONZE_GUARDIAN_STRENGTH				= 2436
Global Const $ID_BRONZE_GUARDIAN_LEADERSHIP				= 2437
Global Const $ID_DEATHS_HEAD_SOUL_REAPING				= 2447
Global Const $ID_DEATHS_HEAD_BLOOD_MAGIC				= 2448
Global Const $ID_DEATHS_HEAD_CURSES						= 2449
Global Const $ID_DEATHS_HEAD_DEATH_MAGIC				= 2450
Global Const $ID_QUICKSILVER_DOMINATION_MAGIC			= 2242
Global Const $ID_QUICKSILVER_FAST_CASTING				= 2243
Global Const $ID_QUICKSILVER_ILLUSION_MAGIC				= 2244
Global Const $ID_QUICKSILVER_INSPIRATION_MAGIC			= 2445
Global Const $ID_OMINOUS_AEGIS_TACTICS					= 2461
Global Const $ID_OMINOUS_AEGIS_STRENGTH					= 2462
Global Const $ID_OMINOUS_AEGIS_LEADERSHIP				= 2463

; No Command shields :(
Global Const $ID_HOGS_GLUTTONY_COMMAND					= 999999
Global Const $ID_BRONZE_GUARDIAN_COMMAND				= 999999
Global Const $ID_SPIDERS_GLUTTONY_COMMAND				= 999999
Global Const $ID_OMINOUS_AEGIS_COMMAND					= 999999

#EndRegion Any
#EndRegion Anniversary Weapon skins


#Region Other skins
; Missing IDs
;Global Const $ID_JEWELED_DAGGERS					=
;Global Const $ID_RUBY_DAGGERS						=

Global Const $ID_GREAT_CONCH						= 2415
Global Const $ID_RUBY_MAUL							= 2274
Global Const $ID_ELEMENTAL_SWORD					= 2267
Global Const $ID_ILLUSORY_STAFF						= 1916
Global Const $ID_QUICKSILVER						= 2242
Global Const $ID_FIRE_STAFF							= 887		; Canthan version
Global Const $ID_DIVINE_SCROLL						= 905		; Canthan version
Global Const $ID_EARTH_SCROLL						= 177
Global Const $ID_EARTH_SCROLL_2						= 178
Global Const $ID_EARTH_SCROLL_3						= 568
Global Const $ID_FELLBLADE							= 400
Global Const $ID_FIERY_DRAGON_SWORD					= 1612
Global Const $ID_BUTTERFLY_SWORD					= 397
Global Const $ID_CRENELLATED_SCIMITAR				= 791
Global Const $ID_FALCHION							= 405
Global Const $ID_FLAMBERGE							= 2250
Global Const $ID_GEMSTONE_AXE						= 701
Global Const $ID_IRIDESCENT_AEGIS					= 2299
Global Const $ID_PEACOCKS_WRATH						= 2433
Global Const $ID_ORNATE_BUCKLER						= 326
Global Const $ID_REINFORCED_BUCKLER					= 327
Global Const $ID_SHIELD_OF_THE_WING					= 334
Global Const $ID_SKELETON_SHIELD					= 337
Global Const $ID_SKULL_SHIELD						= 338
Global Const $ID_SPIKED_TARGE						= 871
Global Const $ID_SPIKED_TARGE_2						= 872
Global Const $ID_TALL_SHIELD						= 343

Global Const $ID_ADAMANTINE_SHIELD					= 1892
Global Const $ID_AEGIS								= 323
Global Const $ID_DARKWING_DEFENDER					= 1052
Global Const $ID_DEFENDER							= 331
Global Const $ID_DIAMOND_AEGIS						= 783
Global Const $ID_DIAMOND_AEGIS_2					= 1469
Global Const $ID_DIAMOND_AEGIS_3					= 2294
Global Const $ID_ENAMELED_SHIELD					= 2236
Global Const $ID_GLOOM_SHIELD						= 1315
Global Const $ID_SHADOW_SHIELD						= 336
Global Const $ID_TOWER_SHIELD						= 345
Global Const $ID_DWARVEN_AXE						= 114
Global Const $ID_ONI_DAGGERS						= 766
#EndRegion Other skins

Local $ultraRareWeaponsArray = [ _
	$ID_GLACIAL_BLADE, $ID_GLACIAL_BLADES, $ID_CRYSTALLINE_SWORD, _
	$ID_ETERNAL_BLADE, $ID_OBSIDIAN_EDGE, $ID_EMERALD_BLADE, $ID_STORM_DAGGERS, $ID_VOLTAIC_SPEAR, $ID_DHUUMS_SOUL_REAPER, _
	$ID_AUREATE_BLADE, $ID_EAGLECREST_AXE, $ID_WINGCREST_MAUL, $ID_DEMONCREST_SPEAR, $ID_SILVERWING_RECURVE_BOW, $ID_ONYX_SCEPTER, _
	$ID_TENTACLE_SCYTHE, $ID_MOLDAVITE_STAFF, $ID_ANCIENT_MOSS_STAFF, $ID_SUNTOUCHED_STAFF, $ID_CRYSTAL_FLAME_STAFF, _
	_
	$ID_DEMRIKOVS_JUDGEMENT, $ID_VETAURAS_HARBINGER, $ID_TORIVOS_RAGE, $ID_HELEYNES_INSIGHT, _
	$ID_ENVOY_SWORD, $ID_ENVOY_AXE, $ID_DIVINE_ENVOY_STAFF, $ID_ENVOY_SCYTHE, _
	_
	$ID_FROGGY_DOMINATION, $ID_FROGGY_FAST_CASTING, $ID_FROGGY_ILLUSION, $ID_FROGGY_INSPIRATION, _
	$ID_FROGGY_SOUL_REAPING, $ID_FROGGY_BLOOD, $ID_FROGGY_CURSES, $ID_FROGGY_DEATH, _
	$ID_FROGGY_AIR, $ID_FROGGY_EARTH, $ID_FROGGY_ENERGY_STORAGE, $ID_FROGGY_FIRE, $ID_FROGGY_WATER, _
	$ID_FROGGY_DIVINE, $ID_FROGGY_HEALING, $ID_FROGGY_PROTECTION, $ID_FROGGY_SMITING, _
	$ID_FROGGY_COMMUNING, $ID_FROGGY_SPAWNING, $ID_FROGGY_RESTORATION, $ID_FROGGY_CHANNELING, _
	_
	$ID_BONE_DRAGON_STAFF_DOMINATION, $ID_BONE_DRAGON_STAFF_FAST_CASTING, $ID_BONE_DRAGON_STAFF_ILLUSION, $ID_BONE_DRAGON_STAFF_INSPIRATION, _
	$ID_BONE_DRAGON_STAFF_SOUL_REAPING, $ID_BONE_DRAGON_STAFF_BLOOD, $ID_BONE_DRAGON_STAFF_CURSES, $ID_BONE_DRAGON_STAFF_DEATH, _
	$ID_BONE_DRAGON_STAFF_AIR, $ID_BONE_DRAGON_STAFF_EARTH, $ID_BONE_DRAGON_STAFF_ENERGY_STORAGE, $ID_BONE_DRAGON_STAFF_FIRE, $ID_BONE_DRAGON_STAFF_WATER, _
	$ID_BONE_DRAGON_STAFF_DIVINE, $ID_BONE_DRAGON_STAFF_HEALING, $ID_BONE_DRAGON_STAFF_PROTECTION, $ID_BONE_DRAGON_STAFF_SMITING, _
	$ID_BONE_DRAGON_STAFF_COMMUNING, $ID_BONE_DRAGON_STAFF_SPAWNING, $ID_BONE_DRAGON_STAFF_RESTORATION, $ID_BONE_DRAGON_STAFF_CHANNELING, _
	_
	$ID_CELESTIAL_COMPASS_DOMINATION, $ID_CELESTIAL_COMPASS_FAST_CASTING, $ID_CELESTIAL_COMPASS_ILLUSION, $ID_CELESTIAL_COMPASS_INSPIRATION, _
	$ID_CELESTIAL_COMPASS_SOUL_REAPING, $ID_CELESTIAL_COMPASS_BLOOD, $ID_CELESTIAL_COMPASS_CURSES, $ID_CELESTIAL_COMPASS_DEATH, _
	$ID_CELESTIAL_COMPASS_AIR, $ID_CELESTIAL_COMPASS_EARTH, $ID_CELESTIAL_COMPASS_ENERGY_STORAGE, $ID_CELESTIAL_COMPASS_FIRE, $ID_CELESTIAL_COMPASS_WATER, _
	$ID_CELESTIAL_COMPASS_DIVINE, $ID_CELESTIAL_COMPASS_HEALING, $ID_CELESTIAL_COMPASS_PROTECTION, $ID_CELESTIAL_COMPASS_SMITING, _
	$ID_CELESTIAL_COMPASS_COMMUNING, $ID_CELESTIAL_COMPASS_SPAWNING, $ID_CELESTIAL_COMPASS_RESTORATION, $ID_CELESTIAL_COMPASS_CHANNELING _
]
Global Const $MAP_ULTRA_RARE_WEAPONS = MapFromArray($ultraRareWeaponsArray)

Local $rareWeaponsArray = [ _
	$ID_EARTH_STAFF, _
	_ ; Axes
	$ID_SEPHIS_AXE, $ID_SERPENT_AXE, $ID_CHAOS_AXE, _
	_ ; Bows
	$ID_ETERNAL_BOW, $ID_STORM_BOW, _
	_ ; Focii
	$ID_PAPER_FAN, $ID_PAPER_FAN_2, $ID_PAPER_FAN_3, $ID_PAPER_FAN_4, $ID_PAPER_FAN_5, $ID_PAPER_LANTERN, _
	$ID_JUG, $ID_JUG_2, $ID_JUG_3, $ID_PLAGUEBORN_FOCUS, $ID_PLAGUEBORN_FOCUS_2, $ID_PRONGED_FAN, _
	_ ; Scythes
	$ID_DRACONIC_SCYTHE, _
	_ ; Shields
	$ID_DEMONIC_AEGIS, $ID_DRACONIC_AEGIS, $ID_ETERNAL_SHIELD, $ID_EMBLAZONED_DEFENDER, $ID_EXALTED_AEGIS, _
	$ID_AMBER_SHIELD, $ID_AMBER_SHIELD_2, $ID_BLADED_SHIELD, $ID_BLADED_SHIELD_2, _
	$ID_ECHOVALD_SHIELD, $ID_ECHOVALD_SHIELD_2, $ID_GOTHIC_DEFENDER, $ID_GOTHIC_DEFENDER_2, $ID_GUARDIAN_OF_THE_HUNT, $ID_GUARDIAN_OF_THE_HUNT_2, _
	$ID_KAPPA_SHIELD, $ID_KAPPA_SHIELD_2, $ID_ORNATE_SHIELD, $ID_PLAGUEBORN_SHIELD, $ID_PLAGUEBORN_SHIELD_2, _
	$ID_OUTCAST_SHIELD, $ID_OUTCAST_SHIELD_2, $ID_SEA_PURSE_SHIELD, _
	$ID_MAGMA_SHIELD, $ID_STONE_SUMMIT_SHIELD, $ID_SUMMIT_WARLORD_SHIELD, $ID_AMETHYST_AEGIS_1, $ID_AMETHYST_AEGIS_2, _
	_ ; Staves
	$ID_BO_STAFF, $ID_PLATINUM_STAFF, $ID_DRAGON_STAFF, $ID_RAVEN_STAFF, $ID_JEWELED_STAFF, _
	_ ; Swords
	$ID_JITTE, $ID_KATANA, $ID_ONI_BLADE, $ID_SHINOBI_BLADE, $ID_DADAO_SWORD, $ID_GOLDEN_PHOENIX_BLADE, _
	$ID_BROADSWORD, $ID_COLOSSAL_SCIMITAR, $ID_TATOOED_SCIMITAR, $ID_ADAMANTINE_FALCHION, $ID_ORNATE_SCIMITAR, _
	_ ; Wands
	$ID_PLATINUM_WAND, $ID_VOLTAIC_WAND, $ID_WAYWARD_WAND, _
	_ ; Celestial weapons
	$ID_CELESTIAL_SHIELD, $ID_CELESTIAL_SHIELD_2, $ID_CELESTIAL_SCEPTER, $ID_CELESTIAL_SWORD, $ID_CELESTIAL_DAGGERS, _
	$ID_CELESTIAL_HAMMER, $ID_CELESTIAL_AXE, $ID_CELESTIAL_STAFF, $ID_CELESTIAL_LONGBOW, _
	_ ; Zodiac weapons
	$ID_ZODIAC_SHIELD, _
	_ ; Anniversary weapons
	$ID_DRAGON_FANGS, $ID_CANTHAN_TARGE_STRENGTH, $ID_CANTHAN_TARGE_TACTIC, $ID_CANTHAN_TARGE_LEADERSHIP, _
	$ID_SPIRITBINDER_COMMUNING, $ID_SPIRITBINDER_SPAWNING_POWER, $ID_SPIRITBINDER_RESTORATION, $ID_SPIRITBINDER_CHANNELING, _
	$ID_JAPAN_1ST_ANNIVERSARY_SHIELD_STRENGTH, $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_TACTIC, $ID_JAPAN_1ST_ANNIVERSARY_SHIELD_LEADERSHIP, _
	_ ; Nightfall
	$ID_SOULBREAKER, $ID_SUNSPEAR, _
	_ ; EotN
	$ID_SPIDERS_GLUTTONY_COMMAND, $ID_SPIDERS_GLUTTONY_LEADERSHIP, $ID_SPIDERS_GLUTTONY_STRENGTH, $ID_SPIDERS_GLUTTONY_TACTICS, _
	$ID_OMINOUS_AEGIS_COMMAND, $ID_OMINOUS_AEGIS_LEADERSHIP, $ID_OMINOUS_AEGIS_STRENGTH, $ID_OMINOUS_AEGIS_TACTICS _
]
Global Const $MAP_RARE_WEAPONS = MapFromArray($rareWeaponsArray)


Global Const $ID_BONUS_DARKSTEEL_LONGBOW = 25406
Global Const $ID_BONUS_HOURGLASS_STAFF = 25407
Global Const $ID_BONUS_GLACIAL_BLADE = 25408
Global Const $ID_LUMINESCENT_SCEPTER = 6508
Global Const $ID_SERRATED_SHIELD = 6514
Global Const $ID_BONUS_DRAGON_FANGS = 6377
Global Const $ID_SPIRIT_BINDER = 6507
Global Const $ID_NEVERMORE = 5831
Global Const $ID_TIGER_ROAR = 6036
Global Const $ID_WOLF_FAVOR = 6058
Global Const $ID_RHINOS_CHARGE = 6060
Global Const $ID_SOUL_SHRIEKER = 6515
Local $bonusWeaponsArray = [ _
	$ID_BONUS_DRAGON_FANGS, $ID_NEVERMORE, $ID_TIGER_ROAR, $ID_WOLF_FAVOR, $ID_RHINOS_CHARGE, $ID_LUMINESCENT_SCEPTER, $ID_SERRATED_SHIELD, $ID_SPIRIT_BINDER, $ID_SOUL_SHRIEKER _
]
Global Const $MAP_BONUS_WEAPONS = MapFromArray($bonusWeaponsArray)
#EndRegion Items