#include-once
#include <Array.au3>
#include 'Utils.au3'

; TO ADD :
#Region Unknown IDs
; Special - something like a ToT :
Global Const $ID_UNKNOWN_CONSUMABLE_1 = 5656
Global Const $ID_UNKNOWN_STACKABLE_1 = 1150
Global Const $ID_UNKNOWN_STACKABLE_2 = 1172
Global Const $ID_UNKNOWN_STACKABLE_3 = 1805
Global Const $ID_UNKNOWN_STACKABLE_4 = 4629
Global Const $ID_UNKNOWN_STACKABLE_5 = 4631
Global Const $ID_UNKNOWN_STACKABLE_6 = 5123
Global Const $ID_UNKNOWN_STACKABLE_7 = 7052
; It's gold, but just to be sure ...
Global Const $ID_GOLD = 2511
#EndRegion Unknown IDs


#Region Modes
Global Const $ID_NORMAL_MODE = 0
Global Const $ID_HARD_MODE = 1
#EndRegion Modes


#Region Locations
Global Const $ID_EUROPE = 2
Global Const $ID_INTERNATIONAL = -2
Global Const $ID_KOREA = 1
Global Const $ID_CHINA = 3
Global Const $ID_JAPAN = 4

Global Const $ID_ENGLISH = 0
Global Const $ID_FRENCH = 2
Global Const $ID_GERMAN = 3
Global Const $ID_ITALIAN = 4
Global Const $ID_SPANISH = 5
Global Const $ID_POLISH = 9
Global Const $ID_RUSSIAN = 10
#EndRegion Locations


#Region Game Locations
;~ Generic
Global Const $ID_Outpost = 0
Global Const $ID_Explorable = 1
Global Const $ID_Loading = 2
;~ Eden
Global Const $ID_Ashford_Abbey = 164
Global Const $ID_Lakeside_County = 146
;~ Battle Isles
Global Const $ID_Great_Temple_of_Balthazar = 248
Global Const $ID_Embark_Beach = 857
;~ Prophecies
Global Const $ID_Warriors_Isle = 4
Global Const $ID_Hunters_Isle = 5
Global Const $ID_Wizards_Isle = 6
Global Const $ID_Burning_Isle = 52
Global Const $ID_Frozen_Isle = 176
Global Const $ID_Nomads_Isle = 177
Global Const $ID_Druids_Isle = 178
Global Const $ID_Isle_Of_The_Dead = 179
;~ Factions
Global Const $ID_House_Zu_Heltzer = 77
Global Const $ID_Kaineng_City = 194
Global Const $ID_Mount_Qinkai = 200
Global Const $ID_Ferndale = 210
Global Const $ID_Bukdek_Byway = 240
Global Const $ID_Isle_Of_Weeping_Stone = 275
Global Const $ID_Isle_Of_Jade = 276
Global Const $ID_The_Marketplace = 303
Global Const $ID_Imperial_Isle = 359
Global Const $ID_Isle_Of_Meditation = 360
Global Const $ID_Saint_Anjekas_Shrine = 349
Global Const $ID_Aspenwood_Gate_Luxon = 389
Global Const $ID_Drazach_Thicket = 861
Global Const $ID_Kaineng_A_Chance_Encounter = 861

;~ Nightfall
Global Const $ID_Jokos_Domain = 437
Global Const $ID_Bone_Palace = 438
Global Const $ID_The_Shattered_Ravines = 441
Global Const $ID_The_Sulfurous_Wastes = 444
Global Const $ID_Uncharted_Isle = 529
Global Const $ID_Isle_Of_Wurms = 530
Global Const $ID_Corrupted_Isle = 537
Global Const $ID_Isle_Of_Solitude = 538
Global Const $ID_Remains_of_Sahlahja = 545
Global Const $ID_Moddok_Crevice = 427
;~ EotN
Global Const $ID_Bjora_Marches = 482
Global Const $ID_Riven_Earth = 501
Global Const $ID_Jaga_Moraine = 546
Global Const $ID_Rata_Sum = 640
Global Const $ID_Longeyes_Ledge = 650


#EndRegion Game Locations


#Region Professions
Global Const $ID_Warrior = 1
Global Const $ID_Ranger = 2
Global Const $ID_Monk = 3
Global Const $ID_Mesmer = 5
Global Const $ID_Necromancer = 4
Global Const $ID_Elementalist = 6
Global Const $ID_Ritualist = 8
Global Const $ID_Assassin = 7
Global Const $ID_Paragon = 9
Global Const $ID_Dervish = 10
#EndRegion Professions


#Region Weapon Attributes
Global Const $ID_Fast_Casting = 0
Global Const $ID_Illusion_Magic = 1
Global Const $ID_Domination_Magic = 2
Global Const $ID_Inspiration_Magic = 3
Global Const $ID_Blood_Magic = 4
Global Const $ID_Death_Magic = 5
Global Const $ID_Soul_Reaping = 6
Global Const $ID_Curses = 7
Global Const $ID_Air_Magic = 8
Global Const $ID_Earth_Magic = 9
Global Const $ID_Fire_Magic = 10
Global Const $ID_Water_Magic = 11
Global Const $ID_Energy_Storage = 12
Global Const $ID_Healing_Prayers = 13
Global Const $ID_Smiting_Prayers = 14
Global Const $ID_Protection_Prayers = 15
Global Const $ID_Divine_Favor = 16
Global Const $ID_Strength = 17
Global Const $ID_Axe_Mastery = 18
Global Const $ID_Hammer_Mastery = 19
Global Const $ID_Swordsmanship = 20
Global Const $ID_Tactics = 21
;Global Const $ID_ = 22		;BeastMastery or Survival
Global Const $ID_Expertise = 23
;Global Const $ID_ = 24		;BeastMastery or Survival
Global Const $ID_Marksmanship = 25
;Global Const $ID_ = 26
;Global Const $ID_ = 27
;Global Const $ID_ = 28
Global Const $ID_Dagger_Mastery = 29
;Global Const $ID_ = 30		;CriticalStrikes or Lethal or Shadow
;Global Const $ID_ = 31		;CriticalStrikes or Lethal or Shadow
;Global Const $ID_ = 32		;CriticalStrikes or Lethal or Shadow
Global Const $ID_Restoration_Magic = 33
Global Const $ID_Channeling_Magic = 34
Global Const $ID_Spawning_Power = 35
;Global Const $ID_ = 36
;Global Const $ID_ = 37
Global Const $ID_Command = 38
Global Const $ID_Motivation = 39
Global Const $ID_Leadership = 40
Global Const $ID_Mysticism = 44
#EndRegion Weapon Attributes


#Region Type IDs
Global Const $ID_Type_Armor_Salvage = 0
Global Const $ID_Type_Axe = 2
Global Const $ID_Type_Bow = 5
Global Const $ID_Type_Rune = 8
Global Const $ID_Type_Offhand = 12
Global Const $ID_Type_Hammer = 15
Global Const $ID_Type_Wand = 22
Global Const $ID_Type_Shield = 24
Global Const $ID_Type_Staff = 26
Global Const $ID_Type_Sword = 27
Global Const $ID_Type_Dagger = 32
Global Const $ID_Type_Scythe = 35
Global Const $ID_Type_Spear = 36
Local Const $Weapon_Types_Array[26] = [$ID_Type_Axe, $ID_Type_Bow, $ID_Type_Offhand, $ID_Type_Hammer, $ID_Type_Wand, $ID_Type_Shield, $ID_Type_Staff, $ID_Type_Sword, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
Global Const $Map_Weapon_Types = MapFromArray($Weapon_Types_Array)

;~ Damage relative to the req				0		1		2		3		4		5		6		7		8		9		10		11		12		13
Local Const $Axe_Max_Damage_Per_Level = 	[12,	12,		14,		17,		19,		22,		24,		25,		27,		28,		28,		28,		28,		28]
Local Const $Bow_Max_Damage_Per_Level = 	[13,	14,		16,		18,		20,		22,		24,		25,		27,		28,		28,		28,		28,		28]
Local Const $Focus_Max_Damage_Per_Level = 	[6,		6,		7,		8,		9,		10,		11,		11,		12,		12,		12,		12,		12,		12]
Local Const $Hammer_Max_Damage_Per_Level = 	[15,	16,		19,		22,		24,		28,		30,		32,		34,		35,		35,		35,		35,		35]
Local Const $Wand_Max_Damage_Per_Level = 	[11,	11,		13,		14,		16,		18,		19,		20,		21,		22,		22,		22,		22,		22]
Local Const $Shield_Max_Damage_Per_Level = 	[8,		9,		10,		11,		12,		13,		14,		15,		16,		16,		16,		16,		16,		16]
Local Const $Staff_Max_Damage_Per_Level = 	[11,	11,		13,		14,		16,		18,		19,		20,		21,		22,		22,		22,		22,		22]
Local Const $Sword_Max_Damage_Per_Level = 	[10,	11,		12,		14,		16,		18,		19,		20,		22,		22,		22,		22,		22,		22]
Local Const $Dagger_Max_Damage_Per_Level = 	[8,		8,		9,		11,		12,		13,		14,		15,		16,		17,		17,		17,		17,		17]
Local Const $Scythe_Max_Damage_Per_Level = 	[17,	17,		21,		24,		27,		32,		35,		37,		40,		41,		41,		41,		41,		41]
Local Const $Spear_Max_Damage_Per_Level = 	[12,	13,		15,		17,		19,		21,		23,		25,		26,		27,		27,		27,		27,		27]
Local Const $Weapons_Max_Damage_Per_Level_Keys = [$ID_Type_Axe, $ID_Type_Bow, $ID_Type_Offhand, $ID_Type_Hammer, $ID_Type_Wand, $ID_Type_Shield, $ID_Type_Staff, $ID_Type_Sword, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
Local Const $Weapons_Max_Damage_Per_Level_Values = [$Axe_Max_Damage_Per_Level, $Bow_Max_Damage_Per_Level, $Focus_Max_Damage_Per_Level, $Hammer_Max_Damage_Per_Level, $Wand_Max_Damage_Per_Level, $Shield_Max_Damage_Per_Level, _
	$Staff_Max_Damage_Per_Level, $Sword_Max_Damage_Per_Level, $Dagger_Max_Damage_Per_Level, $Scythe_Max_Damage_Per_Level, $Spear_Max_Damage_Per_Level]
Global Const $Weapons_Max_Damage_Per_Level[] = MapFromArrays($Weapons_Max_Damage_Per_Level_Keys, $Weapons_Max_Damage_Per_Level_Values)
#EndRegion Type IDs


#Region MapMarkers
Global Const $ID_ExtraType_NM_Chest = 4582
Global Const $ID_ExtraType_HM_Chest = 8141
#EndRegion MapMarkers


#Region Hero IDs
Global Const $ID_Norgu = 1
Global Const $ID_Goren = 2
Global Const $ID_Tahlkora = 3
Global Const $ID_Master_Of_Whispers = 4
Global Const $ID_Acolyte_Jin = 5
Global Const $ID_Koss = 6
Global Const $ID_Dunkoro = 7
Global Const $ID_Acolyte_Sousuke = 8
Global Const $ID_Melonni = 9
Global Const $ID_Zhed_Shadowhoof = 10
Global Const $ID_General_Morgahn = 11
Global Const $ID_Margrid_The_Sly = 12
Global Const $ID_Zenmai = 13
Global Const $ID_Olias = 14
Global Const $ID_Razah = 15
Global Const $ID_MOX = 16
Global Const $ID_Keiran_Thackeray = 17
Global Const $ID_Jora = 18
Global Const $ID_Pyre_Fierceshot = 19
Global Const $ID_Anton = 20
Global Const $ID_Livia = 21
Global Const $ID_Hayda = 22
Global Const $ID_Kahmu = 23
Global Const $ID_Gwen = 24
Global Const $ID_Xandra = 25
Global Const $ID_Vekk = 26
Global Const $ID_Ogden = 27
Global Const $ID_Mercenary_Hero_1 = 28
Global Const $ID_Mercenary_Hero_2 = 29
Global Const $ID_Mercenary_Hero_3 = 30
Global Const $ID_Mercenary_Hero_4 = 31
Global Const $ID_Mercenary_Hero_5 = 32
Global Const $ID_Mercenary_Hero_6 = 33
Global Const $ID_Mercenary_Hero_7 = 34
Global Const $ID_Mercenary_Hero_8 = 35
Global Const $ID_Miku = 36
Global Const $ID_ZeiRi = 37
#EndRegion Hero IDs


#Region Titles
Global Const $ID_Sunspear_Title = 0x11
Global Const $ID_Lightbringer_Title = 0x14
Global Const $ID_Asura_Title = 0x26
Global Const $ID_Dwarf_Title = 0x27
Global Const $ID_Ebon_Vanguard_Title = 0x28
Global Const $ID_Norn_Title = 0x29
#EndRegion Titles


#Region Skill IDs
; Dervish
Global Const $ID_Mirage_Cloak = 1500
Global Const $ID_Mystic_Vigor = 1503
Global Const $ID_Vital_Boon = 1506
Global Const $ID_Sand_Shards = 1510
Global Const $ID_Mystic_Regeneration = 1516
Global Const $ID_Conviction = 1540
Global Const $ID_Heart_of_Fury = 1762
; Warrior
Global Const $ID_Healing_Signet = 1
Global Const $ID_To_The_Limit = 316
Global Const $ID_For_Great_Justice = 343
Global Const $ID_100_Blades = 381
Global Const $ID_Whirlwind_Attack = 2107
; Mesmer
Global Const $ID_Channeling = 38
Global Const $ID_Arcane_Echo = 75
Global Const $ID_Wastrels_Demise = 1335
; Assassin
Global Const $ID_Shadow_Refuge = 814
Global Const $ID_Shroud_of_Distress = 1031
;Ritualist
Global Const $ID_Union = 911
Global Const $ID_Shelter = 982
Global Const $ID_Soul_Twisting = 1240
Global Const $ID_Displacement = 1249
;Paragon
Global Const $ID_Burning_Refrain = 1576
Global Const $ID_Heroic_Refrain = 3431
; PvE
Global Const $ID_Ebon_Battle_Standard_of_Honor = 2233
Global Const $ID_Mental_Block = 2417
#EndRegion Skill IDs


#Region Items
#Region Global Items
Global Const $RARITY_White = 2621
Global Const $RARITY_Blue = 2623
Global Const $RARITY_Gold = 2624
Global Const $RARITY_Purple = 2626
Global Const $RARITY_Green = 2627
Global Const $RARITY_Red = 33026


#Region Merchant Items
Global Const $ID_Belt_Pouch = 34
Global Const $ID_Bag = 35
Global Const $ID_Rune_of_Holding = 2988
Global Const $ID_ID_Kit = 2989
Global Const $ID_SUP_ID_Kit = 5899
Global Const $ID_Salvage_Kit = 2992
Global Const $ID_EXP_Salvage_Kit = 2991
Global Const $ID_SUP_Salvage_Kit = 5900
Global Const $ID_Small_Equipment_Pack = 31221
Global Const $ID_Light_Equipment_Pack = 31222
Global Const $ID_Large_Equipment_Pack = 31223
Global Const $ID_Heavy_Equipment_Pack = 31224
#EndRegion Merchant Items


#Region Keys
Global Const $ID_Ascalonian_Key = 5966
Global Const $ID_Steel_Key = 5967
Global Const $ID_Krytan_Key = 5964
Global Const $ID_Maguuma_Key = 5965
Global Const $ID_Elonian_Key = 5960
Global Const $ID_Shiverpeak_Key = 5962
Global Const $ID_Darkstone_Key = 5963
Global Const $ID_Miners_Key = 5961
Global Const $ID_Shing_Jea_Key = 6537
Global Const $ID_Canthan_Key = 6540
Global Const $ID_Kurzick_Key = 6535
Global Const $ID_Stoneroot_Key = 6536
Global Const $ID_Luxon_Key = 6538
Global Const $ID_Deep_Jade_Key = 6539
Global Const $ID_Forbidden_Key = 6534
Global Const $ID_Istani_Key = 15557
Global Const $ID_Kournan_Key = 15559
Global Const $ID_Vabbian_Key = 15558
Global Const $ID_Ancient_Elonian_Key = 15556
Global Const $ID_Margonite_Key = 15560
Global Const $ID_Demonic_Key = 19174
Global Const $ID_Phantom_Key = 5882
Global Const $ID_Obsidian_Key = 5971
Global Const $ID_Lockpick = 22751
Global Const $ID_Zaishen_Key = 28571
Global Const $ID_Bogroots_Boss_Key = 2593
Local Const $Keys_Array[26] = [$ID_Ascalonian_Key, $ID_Steel_Key, $ID_Krytan_Key, $ID_Maguuma_Key, $ID_Elonian_Key, $ID_Shiverpeak_Key, $ID_Darkstone_Key, $ID_Miners_Key, $ID_Shing_Jea_Key, $ID_Canthan_Key, $ID_Kurzick_Key, $ID_Stoneroot_Key, $ID_Luxon_Key, _
	$ID_Deep_Jade_Key, $ID_Forbidden_Key, $ID_Istani_Key, $ID_Kournan_Key, $ID_Vabbian_Key, $ID_Ancient_Elonian_Key, $ID_Margonite_Key, $ID_Demonic_Key, $ID_Phantom_Key, $ID_Obsidian_Key, $ID_Lockpick, $ID_Bogroots_Boss_Key, $ID_Zaishen_Key]
Global Const $Map_Keys = MapFromArray($Keys_Array)
#EndRegion Keys


Local Const $General_Items_Array[6] = [$ID_ID_Kit, $ID_EXP_Salvage_Kit, $ID_Salvage_Kit, $ID_SUP_ID_Kit, $ID_SUP_Salvage_Kit, $ID_Lockpick]
Global Const $Map_General_Items = MapFromArray($General_Items_Array)


#Region Dyes
Global Const $ID_Dyes = 146
Global Const $ID_Blue_Dye = 2
Global Const $ID_Green_Dye = 3
Global Const $ID_Purple_Dye = 4
Global Const $ID_Red_Dye = 5
Global Const $ID_Yellow_Dye = 6
Global Const $ID_Brown_Dye = 7
Global Const $ID_Orange_Dye = 8
Global Const $ID_Silver_Dye = 9
Global Const $ID_Black_Dye = 10
Global Const $ID_Gray_Dye = 11
Global Const $ID_White_Dye = 12
Global Const $ID_Pink_Dye = 13
Local Const $Dyes_Array[12] = [$ID_Blue_Dye, $ID_Green_Dye, $ID_Purple_Dye, $ID_Red_Dye, $ID_Yellow_Dye, $ID_Brown_Dye, $ID_Orange_Dye, $ID_Silver_Dye, $ID_Black_Dye, $ID_Gray_Dye, $ID_White_Dye, $ID_Pink_Dye]
Global Const $Map_Dyes = MapFromArray($Dyes_Array)
#EndRegion Dyes


#Region Scrolls
Global Const $ID_Urgoz_Scroll = 3256
Global Const $ID_UW_Scroll = 3746
Global Const $ID_Heros_Insight_Scroll = 5594
Global Const $ID_Berserkers_Insight_Scroll = 5595
Global Const $ID_Slayers_Insight_Scroll = 5611
Global Const $ID_Adventurers_Insight_Scroll = 5853
Global Const $ID_Rampagers_Insight_Scroll = 5975
Global Const $ID_Hunters_Insight_Scroll = 5976
Global Const $ID_Scroll_of_the_Lightbringer = 21233
Global Const $ID_Deep_Scroll = 22279
Global Const $ID_FoW_Scroll = 22280
Local Const $Blue_Scrolls_Array[3] = [$ID_Adventurers_Insight_Scroll, $ID_Rampagers_Insight_Scroll, $ID_Hunters_Insight_Scroll]
Local Const $Gold_Scrolls_Array[8] = [$ID_Urgoz_Scroll, $ID_UW_Scroll, $ID_Heros_Insight_Scroll, $ID_Berserkers_Insight_Scroll, $ID_Slayers_Insight_Scroll, $ID_Scroll_of_the_Lightbringer, $ID_Deep_Scroll, $ID_FoW_Scroll]
Global Const $Map_Blue_Scrolls = MapFromArray($Blue_Scrolls_Array)
Global Const $Map_Gold_Scrolls = MapFromArray($Gold_Scrolls_Array)
#EndRegion Scrolls


#Region Materials
Global Const $ID_Fur_Square = 941
Global Const $ID_Bolt_of_Linen = 926
Global Const $ID_Bolt_of_Damask = 927
Global Const $ID_Bolt_of_Silk = 928
Global Const $ID_Glob_of_Ectoplasm = 930
Global Const $ID_Steel_Ingot = 949
Global Const $ID_Deldrimor_Steel_Ingot = 950
Global Const $ID_Monstrous_Claw = 923
Global Const $ID_Monstrous_Eye = 931
Global Const $ID_Monstrous_Fang = 932
Global Const $ID_Ruby = 937
Global Const $ID_Sapphire = 938
Global Const $ID_Diamond = 935
Global Const $ID_Onyx_Gemstone = 936
Global Const $ID_Lump_of_Charcoal = 922
Global Const $ID_Obsidian_Shard = 945
Global Const $ID_Tempered_Glass_Vial = 939
Global Const $ID_Leather_Square = 942
Global Const $ID_Elonian_Leather_Square = 943
Global Const $ID_Vial_of_Ink = 944
Global Const $ID_Rolls_of_Parchment = 951
Global Const $ID_Rolls_of_Vellum = 952
Global Const $ID_Spiritwood_Planks = 956
Global Const $ID_Amber_Chunk = 6532
Global Const $ID_Jadeite_Shard = 6533

Global Const $ID_Bone = 921
Global Const $ID_Iron_Ingot = 948
Global Const $ID_Tanned_Hide_Square = 940
Global Const $ID_Scale = 953
Global Const $ID_Chitin_Fragment = 954
Global Const $ID_Bolt_of_Cloth = 925
Global Const $ID_Wood_Plank = 946
Global Const $ID_Granite_Slab = 955
Global Const $ID_Pile_of_Glittering_Dust = 929
Global Const $ID_Plant_Fibers = 934
Global Const $ID_Feather = 933

Local Const $Rare_Materials_Double_Array[26][2] = [[$ID_Fur_Square, 'Fur Square'], [$ID_Bolt_of_Linen, 'Bolt of Linen'], [$ID_Bolt_of_Damask, 'Bolt of Damask'], [$ID_Bolt_of_Silk, 'Bolt of Silk'], [$ID_Glob_of_Ectoplasm, 'Glob of Ectoplasm'], _
	[$ID_Steel_Ingot, 'Steel Ingot'], [$ID_Deldrimor_Steel_Ingot, 'Deldrimor Steel Ingot'], [$ID_Monstrous_Claw, 'Monstrous Claw'], [$ID_Monstrous_Eye, 'Monstrous Eye'], [$ID_Monstrous_Fang, 'Monstrous Fang'], [$ID_Ruby, 'Ruby'], [$ID_Sapphire, 'Sapphire'], _
	[$ID_Diamond, 'Diamond'], [$ID_Onyx_Gemstone, 'Onyx Gemstones'], [$ID_Lump_of_Charcoal, 'Lumps of Charcoal'], [$ID_Obsidian_Shard, 'Obsidian Shard'], [$ID_Tempered_Glass_Vial, 'Tempered Glass Vial'], [$ID_Leather_Square, 'Leather Squares'], _
	[$ID_Elonian_Leather_Square, 'Elonian Leather Square'], [$ID_Vial_of_Ink, 'Vial of Ink'], [$ID_Rolls_of_Parchment, 'Rolls of Parchment'], [$ID_Rolls_of_Vellum, 'Rolls of Vellum'], [$ID_Spiritwood_Planks, 'Spiritwood Planks'], _
	[$ID_Amber_Chunk, 'Amber Chunk'], [$ID_Jadeite_Shard, 'Jadeite Shard']]
Global Const $Map_Rare_Materials = MapFromDoubleArray($Rare_Materials_Double_Array)

Local Const $Rare_Materials_Array[26] = [$ID_Fur_Square, $ID_Bolt_of_Linen, $ID_Bolt_of_Damask, $ID_Bolt_of_Silk, $ID_Glob_of_Ectoplasm, $ID_Steel_Ingot, $ID_Deldrimor_Steel_Ingot, $ID_Monstrous_Claw, $ID_Monstrous_Eye, $ID_Monstrous_Fang, _
	$ID_Ruby, $ID_Sapphire, $ID_Diamond, $ID_Onyx_Gemstone, $ID_Lump_of_Charcoal, $ID_Obsidian_Shard, $ID_Tempered_Glass_Vial, $ID_Leather_Square, $ID_Elonian_Leather_Square, $ID_Vial_of_Ink, $ID_Rolls_of_Parchment, $ID_Rolls_of_Vellum, _
	$ID_Spiritwood_Planks, $ID_Amber_Chunk, $ID_Jadeite_Shard]
Local Const $Basic_Materials_Array[11] = [$ID_Bone, $ID_Iron_Ingot, $ID_Tanned_Hide_Square, $ID_Scale, $ID_Chitin_Fragment, $ID_Bolt_of_Cloth, $ID_Wood_Plank, $ID_Granite_Slab, $ID_Pile_of_Glittering_Dust, $ID_Plant_Fibers, $ID_Feather]

Local $All_Materials_Array = $Rare_Materials_Array
_ArrayConcatenate($All_Materials_Array, $Basic_Materials_Array)

Global Const $Map_Basic_Materials = MapFromArray($Basic_Materials_Array)
Global Const $Map_All_Materials = MapFromArray($All_Materials_Array)
#EndRegion Materials


#Region Endgame Rewards
Global Const $ID_Amulet_of_the_Mists = 6069
Global Const $ID_Book_of_Secrets = 19197
Global Const $ID_Droknars_Key = 26724
Global Const $ID_Imperial_Dragons_Tear = 30205; Not tradeable
Global Const $ID_Deldrimor_Talisman = 30693
Global Const $ID_Medal_of_Honor = 35122 ; Not tradeable
#EndRegion Endgame Rewards


#Region Reward Trophy
Global Const $ID_Copper_Zaishen_Coin = 31202
Global Const $ID_Gold_Zaishen_Coin = 31203
Global Const $ID_Silver_Zaishen_Coin = 31204
Global Const $ID_Monastery_Credit = 5819
Global Const $ID_Imperial_Commendation = 6068
Global Const $ID_Luxon_Totem = 6048
Global Const $ID_Equipment_Requisition = 5817
Global Const $ID_Battle_Commendation = 17081
Global Const $ID_Kournan_Coin = 19195
Global Const $ID_Trade_Contract = 17082
Global Const $ID_Ancient_Artifact = 19182
Global Const $ID_Inscribed_Secret = 19196
Global Const $ID_Burol_Ironfists_Commendation = 29018
Global Const $ID_Bison_Championship_Token = 27563
Global Const $ID_Monumental_Tapestry = 27583
Global Const $ID_Royal_Gift = 35120
Global Const $ID_War_Supplies = 35121
Global Const $ID_Confessors_Orders = 35123
Global Const $ID_Paper_Wrapped_Parcel = 34212
Global Const $ID_Sack_of_Random_Junk = 34213
;Global Const $ID_Legion_Loot_Bag =
;Global Const $ID_Reverie_Gift =
Global Const $ID_Ministerial_Commendation = 36985
Global Const $ID_Imperial_Guard_Requisition_Order = 29108
Global Const $ID_Imperial_Guard_Lockbox = 30212 ; Not tradeable
;Global Const $ID_Proof_of_Flames =
;Global Const $ID_Proof_of_Mountains =
;Global Const $ID_Proof_of_Waves =
;Global Const $ID_Proof_of_Winds =
;Global Const $ID_Racing_Medal =
Global Const $ID_Glob_of_Frozen_Ectoplasm = 21509
;Global Const $ID_Celestial_Miniature_Token =
;Global Const $ID_Dragon_Festival_Grab_Bag =
Global Const $ID_Red_Gift_Bag = 21811
;Global Const $ID_Lunar_Festival_Grab_Bag =
Global Const $ID_Festival_Prize = 15478
;Global Const $ID_Imperial_Mask_Token =
;Global Const $ID_Ghoulish_Grab_Bag =
;Global Const $ID_Ghoulish_Accessory_Token =
;Global Const $ID_Frozen_Accessory_Token =
;;Global Const $ID_Wintersday_Grab_Bag =
Global Const $ID_Armbrace_of_Truth = 21127
Global Const $ID_Margonite_Gemstone = 21128
Global Const $ID_Stygian_Gemstone = 21129
Global Const $ID_Titan_Gemstone = 21130
Global Const $ID_Torment_Gemstone = 21131
Global Const $ID_Coffer_of_Whispers = 21228
Global Const $ID_Gift_of_the_Traveller = 31148
Global Const $ID_Gift_of_the_Huntsman = 31149
Global Const $ID_Champions_Zaishen_Strongbox = 36665
Global Const $ID_Heros_Zaishen_Strongbox = 36666
Global Const $ID_Gladiators_Zaishen_Strongbox = 36667
Global Const $ID_Strategists_Zaishen_Strongbox = 36668
Global Const $ID_Zhos_Journal = 25866
#EndRegion Reward Trophy


#Region Alcohol
Global Const $ID_Hunters_Ale = 910
Global Const $ID_Flask_of_Firewater = 2513
Global Const $ID_Dwarven_Ale = 5585
Global Const $ID_Witchs_Brew = 6049
Global Const $ID_Spiked_Eggnog = 6366
Global Const $ID_Vial_of_Absinthe = 6367
Global Const $ID_Eggnog = 6375
Global Const $ID_Bottle_of_Rice_Wine = 15477
Global Const $ID_Zehtukas_Jug = 19171
Global Const $ID_Bottle_of_Juniberry_Gin = 19172
Global Const $ID_Bottle_of_Vabbian_Wine = 19173
Global Const $ID_Shamrock_Ale = 22190
Global Const $ID_Aged_Dwarven_Ale = 24593
Global Const $ID_Hard_Apple_Cider = 28435
Global Const $ID_Bottle_of_Grog = 30855
Global Const $ID_Aged_Hunters_Ale = 31145
Global Const $ID_Keg_of_Aged_Hunters_Ale = 31146
Global Const $ID_Krytan_Brandy = 35124
Global Const $ID_Battle_Isle_Iced_Tea = 36682
; For pickup use
Local Const $Alcohols_Array[19] = [$ID_Hunters_Ale, $ID_Flask_of_Firewater, $ID_Dwarven_Ale, $ID_Witchs_Brew, $ID_Spiked_Eggnog, $ID_Vial_of_Absinthe, $ID_Eggnog, $ID_Bottle_of_Rice_Wine, $ID_Zehtukas_Jug, $ID_Bottle_of_Juniberry_Gin, _
	$ID_Bottle_of_Vabbian_Wine, $ID_Shamrock_Ale, $ID_Aged_Dwarven_Ale, $ID_Hard_Apple_Cider, $ID_Bottle_of_Grog, $ID_Aged_Hunters_Ale, $ID_Keg_of_Aged_Hunters_Ale, $ID_Krytan_Brandy, $ID_Battle_Isle_Iced_Tea]
; For using them
Local Const $OnePoint_Alcohols_Array[11] = [$ID_Hunters_Ale, $ID_Dwarven_Ale, $ID_Witchs_Brew, $ID_Vial_of_Absinthe, $ID_Eggnog, $ID_Bottle_of_Rice_Wine, $ID_Zehtukas_Jug, $ID_Bottle_of_Juniberry_Gin, $ID_Bottle_of_Vabbian_Wine, _
	$ID_Shamrock_Ale, $ID_Hard_Apple_Cider]
Local Const $ThreePoint_Alcohols_Array[7] = [$ID_Flask_of_Firewater, $ID_Spiked_Eggnog, $ID_Aged_Dwarven_Ale, $ID_Bottle_of_Grog, $ID_Aged_Hunters_Ale, $ID_Keg_of_Aged_Hunters_Ale, $ID_Krytan_Brandy]
Local Const $FiftyPoint_Alcohols_Array[1] = [$ID_Battle_Isle_Iced_Tea]
Global Const $Map_Alcohols = MapFromArray($Alcohols_Array)
Global Const $Map_OnePoint_Alcohols = MapFromArray($OnePoint_Alcohols_Array)
Global Const $Map_ThreePoint_Alcohols = MapFromArray($ThreePoint_Alcohols_Array)
Global Const $Map_FiftyPoint_Alcohols = MapFromArray($FiftyPoint_Alcohols_Array)
#EndRegion Alcohol


#Region Party
Global Const $ID_Ghost_in_the_Box = 6368
Global Const $ID_Squash_Serum = 6369
Global Const $ID_Snowman_Summoner = 6376
Global Const $ID_Bottle_Rocket = 21809
Global Const $ID_Champagne_Popper = 21810
Global Const $ID_Sparkler = 21813
Global Const $ID_Crate_of_Fireworks = 29436 ; Not spammable
Global Const $ID_Disco_Ball = 29543 ; Not Spammable
Global Const $ID_Party_Beacon = 36683
Local Const $Spammable_Party_Array[7] = [$ID_Ghost_in_the_Box, $ID_Squash_Serum, $ID_Snowman_Summoner, $ID_Bottle_Rocket, $ID_Champagne_Popper, $ID_Sparkler, $ID_Party_Beacon]
Local Const $All_Festive_Array[9] = [$ID_Ghost_in_the_Box, $ID_Squash_Serum, $ID_Snowman_Summoner, $ID_Bottle_Rocket, $ID_Champagne_Popper, $ID_Sparkler, $ID_Party_Beacon, $ID_Crate_of_Fireworks, $ID_Disco_Ball]
Global Const $Map_Spammable_Party = MapFromArray($Spammable_Party_Array)
Global Const $Map_Festive = MapFromArray($All_Festive_Array)
#EndRegion Party


#Region Sweets
Global Const $ID_Creme_Brulee = 15528
Global Const $ID_Red_Bean_Cake = 15479
Global Const $ID_Mandragor_Root_Cake = 19170
Global Const $ID_Fruitcake = 21492
Global Const $ID_Sugary_Blue_Drink = 21812
Global Const $ID_Chocolate_Bunny = 22644
Global Const $ID_MiniTreats_of_Purity = 30208
Global Const $ID_Jar_of_Honey = 31150
Global Const $ID_Krytan_Lokum = 35125
Global Const $ID_Delicious_Cake = 36681
Local Const $Town_Sweets_Array[10] = [$ID_Creme_Brulee, $ID_Red_Bean_Cake, $ID_Mandragor_Root_Cake, $ID_Fruitcake, $ID_Sugary_Blue_Drink, $ID_Chocolate_Bunny, $ID_MiniTreats_of_Purity, $ID_Jar_of_Honey, $ID_Krytan_Lokum, $ID_Delicious_Cake]
Global Const $Map_Town_Sweets = MapFromArray($Town_Sweets_Array)

#Region Sweet Pcon
Global Const $ID_Drake_Kabob = 17060
Global Const $ID_Bowl_of_Skalefin_Soup = 17061
Global Const $ID_Pahnai_Salad = 17062
Global Const $ID_Birthday_Cupcake = 22269
Global Const $ID_Golden_Egg = 22752
Global Const $ID_Candy_Apple = 28431
Global Const $ID_Candy_Corn = 28432
Global Const $ID_Slice_of_Pumpkin_Pie = 28436
Global Const $ID_Lunar_Fortune_2008 = 29425 ; Rat
Global Const $ID_Lunar_Fortune_2009 = 29426 ; Ox
Global Const $ID_Lunar_Fortune_2010 = 29427 ; Tiger
Global Const $ID_Lunar_Fortune_2011 = 29428 ; Rabbit
Global Const $ID_Lunar_Fortune_2012 = 29429 ; Dragon
Global Const $ID_Lunar_Fortune_2013 = 29430 ; Snake
Global Const $ID_Lunar_Fortune_2014 = 29431 ; Horse
Global Const $ID_Blue_Rock_Candy = 31151
Global Const $ID_Green_Rock_Candy = 31152
Global Const $ID_Red_Rock_Candy = 31153
Local Const $Sweet_Pcons_Array[13] = [$ID_Drake_Kabob, $ID_Bowl_of_Skalefin_Soup, $ID_Pahnai_Salad, $ID_Birthday_Cupcake, $ID_Golden_Egg, $ID_Candy_Apple, $ID_Candy_Corn, $ID_Slice_of_Pumpkin_Pie, _
	$ID_Lunar_Fortune_2014, $ID_Blue_Rock_Candy, $ID_Green_Rock_Candy, $ID_Red_Rock_Candy, $ID_War_Supplies]
Global Const $Map_Sweet_Pcons = MapFromArray($Sweet_Pcons_Array)
#EndRegion Sweet Pcon
#EndRegion Sweets


#Region DP Removal
Global Const $ID_Peppermint_CC = 6370
Global Const $ID_Refined_Jelly = 19039
Global Const $ID_Elixir_of_Valor = 21227
Global Const $ID_Wintergreen_CC = 21488
Global Const $ID_Rainbow_CC = 21489
Global Const $ID_Four_Leaf_Clover = 22191
Global Const $ID_Honeycomb = 26784
Global Const $ID_Pumpkin_Cookie = 28433
Global Const $ID_Oath_of_Purity = 30206
Global Const $ID_Seal_of_the_Dragon_Empire = 30211
Global Const $ID_Shining_Blade_Ration = 35127
Local Const $DPRemoval_Sweets[8] = [$ID_Peppermint_CC, $ID_Refined_Jelly, $ID_Wintergreen_CC, $ID_Rainbow_CC, $ID_Four_Leaf_Clover, $ID_Honeycomb, $ID_Pumpkin_Cookie, $ID_Shining_Blade_Ration]
Global Const $Map_DPRemoval_Sweets = MapFromArray($DPRemoval_Sweets)
#EndRegion DP Removal


#Region Special Drops
Global Const $ID_CC_Shard = 556
Global Const $ID_Flame_of_Balthazar = 2514 ; Not really a drop
Global Const $ID_Golden_Flame_of_Balthazar = 22188 ; Not really a drop
Global Const $ID_Celestial_Sigil = 2571 ; Not really a drop
Global Const $ID_Victory_Token = 18345
Global Const $ID_Wintersday_Gift = 21491 ; Not really a drop
Global Const $ID_Wayfarer_Mark = 37765
Global Const $ID_Lunar_Token = 21833
Global Const $ID_Lunar_Tokens = 28433
Global Const $ID_ToT = 28434
Local Const $Special_Drops[7] = [$ID_CC_Shard, $ID_Victory_Token, $ID_Wintersday_Gift, $ID_Wayfarer_Mark, $ID_Lunar_Token, $ID_Lunar_Tokens, $ID_ToT]
Global Const $Map_Special_Drops = MapFromArray($Special_Drops)
#EndRegion Special Drops


#Region Stupid Drops
Global Const $ID_Kilhn_Testibries_Cuisse = 2113
Global Const $ID_Kilhn_Testibries_Greaves = 2114
Global Const $ID_Kilhn_Testibries_Crest = 2115
Global Const $ID_Kilhn_Testibries_Pauldron = 2116
Global Const $ID_Map_Piece_TL = 24629
Global Const $ID_Map_Piece_TR = 24630
Global Const $ID_Map_Piece_BL = 24631
Global Const $ID_Map_Piece_BR = 24632
Global Const $ID_Golden_Lantern = 4195 ; Mount Qinkai Quest Item
Global Const $ID_Hunk_of_Fresh_Meat = 15583 ; NF Quest Item for Drakes on a Plain
Global Const $ID_Zehtukas_Great_Horn = 15845
Global Const $ID_Jade_Orb = 15940
Global Const $ID_Herring = 26502 ; Mini Black Moa Chick incubator item
Global Const $ID_Encrypted_Charr_Battle_Plans = 27976
Global Const $ID_Ministerial_Decree = 29109 ; WoC quest item
Global Const $ID_Keirans_Bow = 35829 ; Not really a drop
Local Const $Map_Pieces_Array[4] = [$ID_Map_Piece_TL, $ID_Map_Piece_TR, $ID_Map_Piece_BL, $ID_Map_Piece_BR]
Global Const $Map_Map_Pieces = MapFromArray($Map_Pieces_Array)
#EndRegion Stupid Drops


#Region Hero Armor Upgrades
Global Const $ID_Ancient_Armor_Remnant = 19190
Global Const $ID_Stolen_Sunspear_Armor = 19191
Global Const $ID_Mysterious_Armor_Piece = 19192
Global Const $ID_Primeval_Armor_Remnant = 19193
Global Const $ID_Deldrimor_Armor_Remnant = 27321
Global Const $ID_Cloth_of_the_Brotherhood = 27322
#EndRegion Hero Armor Upgrades


#Region Polymock
Global Const $ID_Polymock_Wind_Rider = 24356 ; Gold
Global Const $ID_Polymock_Gargoyle = 24361 ; White
Global Const $ID_Polymock_Mergoyle = 24369 ; White
Global Const $ID_Polymock_Skale = 24373 ; White
Global Const $ID_Polymock_Fire_Imp = 24359 ; White
Global Const $ID_Polymock_Kappa = 24367 ; Purple
Global Const $ID_Polymock_Ice_Imp = 24366 ; White
Global Const $ID_Polymock_Earth_Elemental = 24357 ; Purple
Global Const $ID_Polymock_Ice_Elemental = 24365 ; Purple
Global Const $ID_Polymock_Fire_Elemental = 24358 ; Purple
Global Const $ID_Polymock_Aloe_Seed = 24355 ; Purple
Global Const $ID_Polymock_Mirage_Iboga = 24363 ; Gold
Global Const $ID_Polymock_Gaki = 24360 ; Gold
;Global Const $ID_Polymock_Mantis_Dreamweaver =  ; Gold
Global Const $ID_Polymock_Mursaat_Elementalist = 24370 ; Gold
Global Const $ID_Polymock_Ruby_Djinn = 24371 ; Gold
Global Const $ID_Polymock_Naga_Shaman = 24372 ; Gold
Global Const $ID_Polymock_Stone_Rain = 24374 ; Gold
#EndRegion Polymock


#Region Stackable Trophies
Global Const $ID_Charr_Carving = 423
Global Const $ID_Icy_Lodestone = 424
Global Const $ID_Spiked_Crest = 434
Global Const $ID_Hardened_Hump = 435
Global Const $ID_Mergoyle_Skull = 436
Global Const $ID_Glowing_Heart = 439
Global Const $ID_Forest_Minotaur_Horn = 440
Global Const $ID_Shadowy_Remnant = 441
Global Const $ID_Abnormal_Seed = 442
Global Const $ID_Bog_Skale_Fin = 443
Global Const $ID_Feathered_Caromi_Scalp = 444
Global Const $ID_Shriveled_Eye = 446
Global Const $ID_Dune_Burrower_Jaw = 447
Global Const $ID_Losaru_Mane = 448
Global Const $ID_Bleached_Carapace = 449
Global Const $ID_Topaz_Crest = 450
Global Const $ID_Encrusted_Lodestone = 451
Global Const $ID_Massive_Jawbone = 452
Global Const $ID_Iridescant_Griffon_Wing = 453
Global Const $ID_Dessicated_Hydra_Claw = 454
Global Const $ID_Minotaur_Horn = 455
Global Const $ID_Jade_Mandible = 457
Global Const $ID_Forgotten_Seal = 459
Global Const $ID_White_Mantle_Emblem = 460
Global Const $ID_White_Mantle_Badge = 461
Global Const $ID_Mursaat_Token = 462
Global Const $ID_Ebon_Spider_Leg = 463
Global Const $ID_Ancient_Eye = 464
Global Const $ID_Behemoth_Jaw = 465
Global Const $ID_Maguuma_Mane = 466
Global Const $ID_Thorny_Carapace = 467
Global Const $ID_Tangled_Seed = 468
Global Const $ID_Mossy_Mandible = 469
Global Const $ID_Jungle_Skale_Fin = 70
Global Const $ID_Jungle_Troll_Tusk = 471
Global Const $ID_Obsidian_Burrower_Jaw = 472
Global Const $ID_Demonic_Fang = 473
Global Const $ID_Phantom_Residue = 474
Global Const $ID_Gruesome_Sternum = 475
Global Const $ID_Demonic_Remains = 476
Global Const $ID_Stormy_Eye = 477
Global Const $ID_Scar_Behemoth_Jaw = 478
Global Const $ID_Fetid_Carapace = 479
Global Const $ID_Singed_Gargoyle_Skull = 480
Global Const $ID_Gruesome_Ribcage = 482
Global Const $ID_Rawhide_Belt = 483
Global Const $ID_Leathery_Claw = 484
Global Const $ID_Scorched_Seed = 485
Global Const $ID_Scorched_Lodestone = 486
Global Const $ID_Ornate_Grawl_Necklace = 487
Global Const $ID_Shiverpeak_Mane = 488
Global Const $ID_Frostfire_Fang = 489
Global Const $ID_Icy_Hump = 490
Global Const $ID_Huge_Jawbone = 492
Global Const $ID_Frosted_Griffon_Wing = 493
Global Const $ID_Frigid_Heart = 494
Global Const $ID_Curved_Mintaur_Horn = 495
Global Const $ID_Azure_Remains = 496
Global Const $ID_Alpine_Seed = 497
Global Const $ID_Feathered_Avicara_Scalp = 498
Global Const $ID_Intricate_Grawl_Necklace = 499
Global Const $ID_Mountain_Troll_Tusk = 500
Global Const $ID_Stone_Summit_Badge = 502
Global Const $ID_Molten_Claw = 503
Global Const $ID_Decayed_Orr_Emblem = 504
Global Const $ID_Igneous_Spider_Leg = 505
Global Const $ID_Molten_Eye = 506
Global Const $ID_Fiery_Crest = 508
Global Const $ID_Igneous_Hump = 510
Global Const $ID_Unctuous_Remains = 511
Global Const $ID_Mahgo_Claw = 513
Global Const $ID_Molten_Heart = 514
Global Const $ID_Corrosive_Spider_Leg = 518
Global Const $ID_Umbral_Eye = 519
Global Const $ID_Shadowy_Crest = 520
Global Const $ID_Dark_Remains = 522
Global Const $ID_Gloom_Seed = 523
Global Const $ID_Umbral_Skeletal_Limb = 525
Global Const $ID_Shadowy_Husk = 526
Global Const $ID_Enslavement_Stone = 532
Global Const $ID_Kurzick_Bauble = 604
Global Const $ID_Jade_Bracelet = 809
Global Const $ID_Luxon_Pendant = 810
Global Const $ID_Bone_Charm = 811
Global Const $ID_Truffle = 813
Global Const $ID_Skull_Juju = 814
Global Const $ID_Mantid_Pincer = 815
Global Const $ID_Stone_Horn = 816
Global Const $ID_Keen_Oni_Claw = 817
Global Const $ID_Dredge_Incisor = 818
Global Const $ID_Dragon_Root = 819
Global Const $ID_Stone_Carving = 820
Global Const $ID_Warden_Horn = 822
Global Const $ID_Pulsating_Growth = 824
Global Const $ID_Forgotten_Trinket_Box = 825
Global Const $ID_Augmented_Flesh = 826
Global Const $ID_Putrid_Cyst = 827
Global Const $ID_Mantis_Pincer = 829
Global Const $ID_Naga_Pelt = 833
Global Const $ID_Feathered_Crest = 835
Global Const $ID_Feathered_Scalp = 836
Global Const $ID_Kappa_Hatchling_Shell = 838
Global Const $ID_Black_Pearl = 841
Global Const $ID_Rot_Wallow_Tusk = 842
Global Const $ID_Kraken_Eye = 843
Global Const $ID_Azure_Crest = 844
Global Const $ID_Kirin_Horn = 846
Global Const $ID_Keen_Oni_Talon = 847
Global Const $ID_Naga_Skin = 848
Global Const $ID_Guardian_Moss = 849
Global Const $ID_Archaic_Kappa_Shell = 850
Global Const $ID_Stolen_Provisions = 851
Global Const $ID_Soul_Stone = 852
Global Const $ID_Vermin_Hide = 853
Global Const $ID_Venerable_Mantid_Pincer = 854
Global Const $ID_Celestial_Essence = 855
Global Const $ID_Moon_Shell = 1009
Global Const $ID_Stolen_Goods = 1423
Global Const $ID_Copper_Shilling = 1577
Global Const $ID_Gold_Doubloon = 1578
Global Const $ID_Silver_Bullion_Coin = 1579
Global Const $ID_Demonic_Relic = 1580
Global Const $ID_Margonite_Mask = 1581
Global Const $ID_Kournan_Pendant = 1582
Global Const $ID_Mummy_Wrapping = 1583
Global Const $ID_Sandblasted_Lodestone = 1584
Global Const $ID_Inscribed_Shard = 1587
Global Const $ID_Dusty_Insect_Carapace = 1588
Global Const $ID_Giant_Tusk = 1590
Global Const $ID_Insect_Appendage = 1597
Global Const $ID_Juvenile_Termite_Leg = 1598
Global Const $ID_Sentient_Root = 1600
Global Const $ID_Sentient_Seed = 1601
Global Const $ID_Skale_Tooth = 1603
Global Const $ID_Skale_Claw = 1604
Global Const $ID_Skeleton_Bone = 1605
Global Const $ID_Cobalt_Talon = 1609
Global Const $ID_Skree_Wing = 1610
Global Const $ID_Insect_Carapace = 1617
Global Const $ID_Sentient_Lodestone = 1619
Global Const $ID_Immolated_Djinn_Essence = 1620
Global Const $ID_Roaring_Ether_Claw = 1629
Global Const $ID_Mandragor_Husk = 1668
Global Const $ID_Mandragor_Swamproot = 1671
Global Const $ID_Behemoth_Hide = 1675
Global Const $ID_Geode = 1681
Global Const $ID_Hunting_Minotaur_Horn = 1682
Global Const $ID_Mandragor_Root = 1686
Global Const $ID_Red_Iris_Flower = 2994
Global Const $ID_Iboga_Petal = 19183
Global Const $ID_Skale_Fin = 19184
Global Const $ID_Chunk_of_Drake_Flesh = 19185
Global Const $ID_Ruby_Djinn_Essence = 19187
Global Const $ID_Sapphire_Djinn_Essence = 19188
Global Const $ID_Sentient_Spore = 19198
Global Const $ID_Heket_Tongue = 19199
Global Const $ID_Diessa_Chalice = 24353
Global Const $ID_Golden_Rin_Relic = 24354
Global Const $ID_Destroyer_Core = 27033
Global Const $ID_Incubus_Wing = 27034
Global Const $ID_Saurian_Bone = 27035
Global Const $ID_Amphibian_Tongue = 27036
Global Const $ID_Weaver_Leg = 27037
Global Const $ID_Patch_of_Simian_Fur = 27038
Global Const $ID_Quetzal_Crest = 27039
Global Const $ID_Skelk_Claw = 27040
Global Const $ID_Sentient_Vine = 27041
Global Const $ID_Frigid_Mandragor_Husk = 27042
Global Const $ID_Modnir_Mane = 27043
Global Const $ID_Stone_Summit_Emblem = 27044
Global Const $ID_Jotun_Pelt = 27045
Global Const $ID_Berserker_Horn = 27046
Global Const $ID_Glacial_Stone = 27047
Global Const $ID_Frozen_Wurm_Husk = 27048
Global Const $ID_Mountain_Root = 27049
Global Const $ID_Pile_of_Elemental_Dust = 27050
Global Const $ID_Superb_Charr_Carving = 27052
Global Const $ID_Stone_Grawl_Necklace = 27053
Global Const $ID_Mantid_Ungula = 27054
Global Const $ID_Skale_Fang = 27055
Global Const $ID_Stone_Claw = 27057
Global Const $ID_Skelk_Fang = 27060
Global Const $ID_Fungal_Root = 27061
Global Const $ID_Flesh_Reaver_Morsel = 27062
Global Const $ID_Golem_Runestone = 27065
Global Const $ID_Beetle_Egg = 27066
Global Const $ID_Blob_of_Ooze = 27067
Global Const $ID_Chromatic_Scale = 27069
Global Const $ID_Dryder_Web = 27070
Global Const $ID_Vaettir_Essence = 27071
Global Const $ID_Krait_Skin = 27729
Global Const $ID_Undead_Bone = 27974
Local Const $Trophies_Array[191] = [$ID_Charr_Carving, $ID_Icy_Lodestone, $ID_Spiked_Crest, $ID_Hardened_Hump, $ID_Mergoyle_Skull, $ID_Glowing_Heart, $ID_Forest_Minotaur_Horn, $ID_Shadowy_Remnant, $ID_Abnormal_Seed, $ID_Bog_Skale_Fin, _
	$ID_Feathered_Caromi_Scalp, $ID_Shriveled_Eye, $ID_Dune_Burrower_Jaw, $ID_Losaru_Mane, $ID_Bleached_Carapace, $ID_Topaz_Crest, $ID_Encrusted_Lodestone, $ID_Massive_Jawbone, $ID_Iridescant_Griffon_Wing, $ID_Dessicated_Hydra_Claw, _
	$ID_Minotaur_Horn, $ID_Jade_Mandible, $ID_Forgotten_Seal, $ID_White_Mantle_Emblem, $ID_White_Mantle_Badge, $ID_Mursaat_Token, $ID_Ebon_Spider_Leg, $ID_Ancient_Eye, $ID_Behemoth_Jaw, $ID_Maguuma_Mane, $ID_Thorny_Carapace, $ID_Tangled_Seed, _
	$ID_Mossy_Mandible, $ID_Jungle_Skale_Fin, $ID_Jungle_Troll_Tusk, $ID_Obsidian_Burrower_Jaw, $ID_Demonic_Fang, $ID_Phantom_Residue, $ID_Gruesome_Sternum, $ID_Demonic_Remains, $ID_Stormy_Eye, $ID_Scar_Behemoth_Jaw, $ID_Fetid_Carapace, _
	$ID_Singed_Gargoyle_Skull, $ID_Gruesome_Ribcage, $ID_Rawhide_Belt, $ID_Leathery_Claw, $ID_Scorched_Seed, $ID_Scorched_Lodestone, $ID_Ornate_Grawl_Necklace, $ID_Shiverpeak_Mane, $ID_Frostfire_Fang, $ID_Icy_Hump, $ID_Huge_Jawbone, _
	$ID_Frosted_Griffon_Wing, $ID_Frigid_Heart, $ID_Curved_Mintaur_Horn, $ID_Azure_Remains, $ID_Alpine_Seed, $ID_Feathered_Avicara_Scalp, $ID_Intricate_Grawl_Necklace, $ID_Mountain_Troll_Tusk, $ID_Stone_Summit_Badge, $ID_Molten_Claw, _
	$ID_Decayed_Orr_Emblem, $ID_Igneous_Spider_Leg, $ID_Molten_Eye, $ID_Fiery_Crest, $ID_Igneous_Hump, $ID_Unctuous_Remains, $ID_Mahgo_Claw, $ID_Molten_Heart, $ID_Corrosive_Spider_Leg, $ID_Umbral_Eye, $ID_Shadowy_Crest, $ID_Dark_Remains, _
	$ID_Gloom_Seed, $ID_Umbral_Skeletal_Limb, $ID_Shadowy_Husk, $ID_Enslavement_Stone, $ID_Kurzick_Bauble, $ID_Jade_Bracelet, $ID_Luxon_Pendant, $ID_Bone_Charm, $ID_Truffle, $ID_Skull_Juju, $ID_Mantid_Pincer, $ID_Stone_Horn, $ID_Keen_Oni_Claw, _
	$ID_Dredge_Incisor, $ID_Dragon_Root, $ID_Stone_Carving, $ID_Warden_Horn, $ID_Pulsating_Growth, $ID_Forgotten_Trinket_Box, $ID_Augmented_Flesh, $ID_Putrid_Cyst, $ID_Mantis_Pincer, $ID_Naga_Pelt, $ID_Feathered_Crest, $ID_Feathered_Scalp, _
	$ID_Kappa_Hatchling_Shell, $ID_Black_Pearl, $ID_Rot_Wallow_Tusk, $ID_Kraken_Eye, $ID_Azure_Crest, $ID_Kirin_Horn, $ID_Keen_Oni_Talon, $ID_Naga_Skin, $ID_Guardian_Moss, $ID_Archaic_Kappa_Shell, $ID_Stolen_Provisions, $ID_Soul_Stone, _
	$ID_Vermin_Hide, $ID_Venerable_Mantid_Pincer, $ID_Celestial_Essence, $ID_Moon_Shell, $ID_Copper_Shilling, $ID_Gold_Doubloon, $ID_Silver_Bullion_Coin, $ID_Demonic_Relic, $ID_Margonite_Mask, $ID_Kournan_Pendant, $ID_Mummy_Wrapping, _
	$ID_Sandblasted_Lodestone, $ID_Inscribed_Shard, $ID_Dusty_Insect_Carapace, $ID_Giant_Tusk, $ID_Insect_Appendage, $ID_Juvenile_Termite_Leg, $ID_Sentient_Root, $ID_Sentient_Seed, $ID_Skale_Tooth, $ID_Skale_Claw, $ID_Skeleton_Bone, $ID_Cobalt_Talon, _
	$ID_Skree_Wing, $ID_Insect_Carapace, $ID_Sentient_Lodestone, $ID_Immolated_Djinn_Essence, $ID_Roaring_Ether_Claw, $ID_Mandragor_Husk, $ID_Mandragor_Swamproot, $ID_Behemoth_Hide, $ID_Geode, $ID_Hunting_Minotaur_Horn, $ID_Mandragor_Root, _
	$ID_Red_Iris_Flower, $ID_Iboga_Petal, $ID_Skale_Fin, $ID_Chunk_of_Drake_Flesh, $ID_Ruby_Djinn_Essence, $ID_Sapphire_Djinn_Essence, $ID_Sentient_Spore, $ID_Heket_Tongue, $ID_Diessa_Chalice, $ID_Golden_Rin_Relic, $ID_Destroyer_Core, _
	$ID_Incubus_Wing, $ID_Saurian_Bone, $ID_Amphibian_Tongue, $ID_Weaver_Leg, $ID_Patch_of_Simian_Fur, $ID_Quetzal_Crest, $ID_Skelk_Claw, $ID_Sentient_Vine, $ID_Frigid_Mandragor_Husk, $ID_Modnir_Mane, $ID_Stone_Summit_Emblem, $ID_Jotun_Pelt, _
	$ID_Berserker_Horn, $ID_Glacial_Stone, $ID_Frozen_Wurm_Husk, $ID_Mountain_Root, $ID_Pile_of_Elemental_Dust, $ID_Superb_Charr_Carving, $ID_Stone_Grawl_Necklace, $ID_Mantid_Ungula, $ID_Skale_Fang, $ID_Stone_Claw, $ID_Skelk_Fang, $ID_Fungal_Root, _
	$ID_Flesh_Reaver_Morsel, $ID_Golem_Runestone, $ID_Beetle_Egg, $ID_Blob_of_Ooze, $ID_Chromatic_Scale, $ID_Dryder_Web, $ID_Vaettir_Essence, $ID_Krait_Skin, $ID_Undead_Bone]
#EndRegion  Stackable Trophies


#Region Tomes
Global Const $ID_Assassin_EliteTome = 21786
Global Const $ID_Mesmer_EliteTome = 21787
Global Const $ID_Necromancer_EliteTome = 21788
Global Const $ID_Elementalist_EliteTome = 21789
Global Const $ID_Monk_EliteTome = 21790
Global Const $ID_Warrior_EliteTome = 21791
Global Const $ID_Ranger_EliteTome = 21792
Global Const $ID_Dervish_EliteTome = 21793
Global Const $ID_Ritualist_EliteTome = 21794
Global Const $ID_Paragon_EliteTome = 21795

Global Const $ID_Assassin_Tome = 21796
Global Const $ID_Mesmer_Tome = 21797
Global Const $ID_Necromancer_Tome = 21798
Global Const $ID_Elementalist_Tome = 21799
Global Const $ID_Monk_Tome = 21800
Global Const $ID_Warrior_Tome = 21801
Global Const $ID_Ranger_Tome = 21802
Global Const $ID_Dervish_Tome = 21803
Global Const $ID_Ritualist_Tome = 21804
Global Const $ID_Paragon_Tome = 21805
; All Tomes
Local Const $Tomes_Array[20] = [$ID_Assassin_EliteTome, $ID_Mesmer_EliteTome, $ID_Necromancer_EliteTome, $ID_Elementalist_EliteTome, $ID_Monk_EliteTome, $ID_Warrior_EliteTome, $ID_Ranger_EliteTome, $ID_Dervish_EliteTome, $ID_Ritualist_EliteTome, _
	$ID_Paragon_EliteTome, $ID_Assassin_Tome, $ID_Mesmer_Tome, $ID_Necromancer_Tome, $ID_Elementalist_Tome, $ID_Monk_Tome, $ID_Warrior_Tome, $ID_Ranger_Tome, $ID_Dervish_Tome, $ID_Ritualist_Tome, $ID_Paragon_Tome]
;~ Elite Tomes
Local Const $Elite_Tomes_Array[10] = [$ID_Assassin_EliteTome, $ID_Mesmer_EliteTome, $ID_Necromancer_EliteTome, $ID_Elementalist_EliteTome, $ID_Monk_EliteTome, $ID_Warrior_EliteTome, $ID_Ranger_EliteTome, $ID_Dervish_EliteTome, _
	$ID_Ritualist_EliteTome, $ID_Paragon_EliteTome]
;~ Normal Tomes
Local Const $Regular_Tomes_Array[10] = [$ID_Assassin_Tome, $ID_Mesmer_Tome, $ID_Necromancer_Tome, $ID_Elementalist_Tome, $ID_Monk_Tome, $ID_Warrior_Tome, $ID_Ranger_Tome, $ID_Dervish_Tome, $ID_Ritualist_Tome, $ID_Paragon_Tome]
Global Const $Map_Tomes = MapFromArray($Tomes_Array)
Global Const $Map_Elite_Tomes = MapFromArray($Elite_Tomes_Array)
Global Const $Map_Regular_Tomes = MapFromArray($Regular_Tomes_Array)
#EndRegion Tomes


#Region Consumable Crafter Items
Global Const $ID_Armor_of_Salvation = 24860
Global Const $ID_Essence_of_Celerity = 24859
Global Const $ID_Grail_of_Might = 24861
Global Const $ID_Powerstone_of_Courage = 24862
Global Const $ID_Scroll_of_Resurrection = 26501
Global Const $ID_Star_of_Transference = 25896
Global Const $ID_Perfect_Salvage_Kit = 25881
Local Const $Consets_Array[7] = [$ID_Essence_of_Celerity, $ID_Armor_of_Salvation, $ID_Grail_of_Might]
Global Const $Map_Consets = MapFromArray($Consets_Array)
#EndRegion Consumable Crafter Items


#Region Summoning Stones
Global Const $ID_Merchant_Summon = 21154
Global Const $ID_Tengu_Summon = 30209
Global Const $ID_Imperial_Guard_Summon = 30210
Global Const $ID_Automaton_Summon = 30846
Global Const $ID_Igneous_Summoning_Stone = 30847
Global Const $ID_Chitinous_Summon = 30959
Global Const $ID_Mystical_Summon = 30960
Global Const $ID_Amber_Summon = 30961
Global Const $ID_Artic_Summon = 30962
Global Const $ID_Demonic_Summon = 30963
Global Const $ID_Gelatinous_Summon = 30964
Global Const $ID_Fossilized__Summon = 30965
Global Const $ID_Jadeite_Summon = 30966
Global Const $ID_Mischievous_Summon = 31022
Global Const $ID_Frosty_Summon = 31023
Global Const $ID_Mysterious_Summon = 31155
Global Const $ID_Zaishen_Summon = 31156
Global Const $ID_Ghastly_Summon = 32557
Global Const $ID_Celestial_Summon = 34176
Global Const $ID_Shining_Blade_Summon = 35126
Global Const $ID_Legionnaire_Summoning_Crystal = 37810
Local Const $Summoning_Stones_Array[19] = [$ID_Merchant_Summon, $ID_Tengu_Summon, $ID_Imperial_Guard_Summon, $ID_Automaton_Summon, $ID_Chitinous_Summon, $ID_Mystical_Summon, $ID_Amber_Summon, $ID_Artic_Summon, $ID_Demonic_Summon, _
	$ID_Gelatinous_Summon, $ID_Fossilized__Summon, $ID_Jadeite_Summon, $ID_Mischievous_Summon, $ID_Frosty_Summon, $ID_Mysterious_Summon, $ID_Zaishen_Summon, $ID_Ghastly_Summon, $ID_Celestial_Summon, $ID_Shining_Blade_Summon]
Global Const $Map_Summoning_Stones = MapFromArray($Summoning_Stones_Array)
#EndRegion Summoning Stones


#Region Tonics
Global Const $ID_Sinister_Automatonic_Tonic = 4730
Global Const $ID_Transmogrifier_Tonic = 15837
Global Const $ID_Yuletide_Tonic = 21490
Global Const $ID_Beetle_Juice_Tonic = 22192
Global Const $ID_Abyssal_Tonic = 30624
Global Const $ID_Cerebral_Tonic = 30626
Global Const $ID_Macabre_Tonic =30628
Global Const $ID_Trapdoor_Tonic = 30630
Global Const $ID_Searing_Tonic = 30632
Global Const $ID_Automatonic_Tonic = 30634
Global Const $ID_Skeletonic_Tonic = 30636
Global Const $ID_Boreal_Tonic = 30638
Global Const $ID_Gelatinous_Tonic = 30640
Global Const $ID_Phantasmal_Tonic = 30642
Global Const $ID_Abominable_Tonic = 30646
Global Const $ID_Frosty_Tonic = 30648
Global Const $ID_Mischievious_Tonic = 31020
Global Const $ID_Mysterious_Tonic = 31141
Global Const $ID_Cottontail_Tonic = 31142
Global Const $ID_Zaishen_Tonic = 31144
Global Const $ID_Unseen_Tonic = 31172
Global Const $ID_Spooky_Tonic = 37771
Global Const $ID_Minutely_Mad_King_Tonic = 37772
Local Const $Party_Tonics_Array[23] = [$ID_Sinister_Automatonic_Tonic, $ID_Transmogrifier_Tonic, $ID_Yuletide_Tonic, $ID_Beetle_Juice_Tonic, $ID_Abyssal_Tonic, $ID_Cerebral_Tonic, $ID_Macabre_Tonic, $ID_Trapdoor_Tonic, $ID_Searing_Tonic, _
	$ID_Automatonic_Tonic, $ID_Skeletonic_Tonic, $ID_Boreal_Tonic, $ID_Gelatinous_Tonic, $ID_Phantasmal_Tonic, $ID_Abominable_Tonic, $ID_Frosty_Tonic, $ID_Mischievious_Tonic, $ID_Mysterious_Tonic, $ID_Cottontail_Tonic, $ID_Zaishen_Tonic, _
	$ID_Unseen_Tonic, $ID_Spooky_Tonic, $ID_Minutely_Mad_King_Tonic]
Global Const $Map_Party_Tonics = MapFromArray($Party_Tonics_Array)

#Region EL Tonics
;Global Const $ID_EL_Beetle_Juice_Tonic =
Global Const $ID_EL_Cottontail_Tonic = 31143
;Global Const $ID_EL_Frosty_Tonic =
Global Const $ID_EL_Mischievious_Tonic = 31021
Global Const $ID_EL_Sinister_Automatonic_Tonic = 30827
Global Const $ID_EL_Transmogrifier_Tonic = 23242
Global Const $ID_EL_Yuletide_Tonic = 29241
Global Const $ID_EL_Avatar_of_Balthazar_Tonic = 36658
Global Const $ID_EL_Balthazars_Champion_Tonic = 36661
Global Const $ID_EL_Henchman_Tonic = 32850
Global Const $ID_EL_Flame_Sentinel_Tonic = 36664
Global Const $ID_EL_Ghostly_Hero_Tonic = 36660
Global Const $ID_EL_Ghostly_Priest_Tonic = 36663
Global Const $ID_EL_Guild_Lord_Tonic = 36652
;Global Const $ID_EL_Knight_Tonic =
;Global Const $ID_EL_Legionaire_Tonic =
Global Const $ID_EL_Priest_of_Balthazar_Tonic = 36659
Global Const $ID_EL_Reindeer_Tonic = 34156
Global Const $ID_EL_Cerebral_Tonic = 30627
Global Const $ID_EL_Searing_Tonic = 30633
Global Const $ID_EL_Abyssal_Tonic = 30625
Global Const $ID_EL_Unseen_Tonic = 31173
Global Const $ID_EL_Phantasmal_Tonic = 30643
Global Const $ID_EL_Automatonic_Tonic = 30635
Global Const $ID_EL_Boreal_Tonic = 30639
Global Const $ID_EL_Trapdoor_Tonic = 30631
Global Const $ID_EL_Macabre_Tonic = 30629
Global Const $ID_EL_Skeletonic_Tonic = 30637
Global Const $ID_EL_Gelatinous_Tonic = 30641
Global Const $ID_EL_Abominable_Tonic = 30647
Global Const $ID_EL_Destroyer_Tonic = 36457
Global Const $ID_EL_Kuunavang_Tonic = 36461
Global Const $ID_EL_Margonite_Tonic = 36456
Global Const $ID_EL_Slightly_Mad_King_Tonic = 36460
Global Const $ID_EL_Gwen_Tonic = 36442
Global Const $ID_EL_Keiran_Thackeray_Tonic = 36450
Global Const $ID_EL_Miku_Tonic = 36451
Global Const $ID_EL_Shiro_Tonic = 36453
Global Const $ID_EL_Prince_Rurik_Tonic = 36455
Global Const $ID_EL_Anton_Tonic = 36447
Global Const $ID_EL_Jora_Tonic = 36455
Global Const $ID_EL_Koss_Tonic = 36425
Global Const $ID_EL_MOX_Tonic = 36452
Global Const $ID_EL_Master_of_Whispers_Tonic = 36433
Global Const $ID_EL_Ogden_Stonehealer_Tonic = 36440
Global Const $ID_EL_Queen_Salma_Tonic = 36458
Global Const $ID_EL_Pyre_Fiercehot_Tonic = 36446
Global Const $ID_EL_Razah_Tonic = 36437
Global Const $ID_EL_Zhed_Shadowhoof_Tonic = 36431
Global Const $ID_EL_Acolyte_Jin_Tonic = 36428
Global Const $ID_EL_Acolyte_Sousuke_Tonic = 36429
Global Const $ID_EL_Dunkoro_Tonic = 36426
Global Const $ID_EL_Goren_Tonic = 36434
Global Const $ID_EL_Hayda_Tonic = 36448
Global Const $ID_EL_Kahmu_Tonic = 36444
Global Const $ID_EL_Livia_Tonic = 36449
Global Const $ID_EL_Magrid_the_Sly_Tonic = 36432
Global Const $ID_EL_Melonni_Tonic = 36427
Global Const $ID_EL_Tahlkora_Tonic = 36430
Global Const $ID_EL_Norgu_Tonic = 36435
Global Const $ID_EL_Morgahn_Tonic = 36436
Global Const $ID_EL_Olias_Tonic = 36438
Global Const $ID_EL_Zenmai_Tonic = 36439
Global Const $ID_EL_Vekk_Tonic = 36441
Global Const $ID_EL_Xandra_Tonic = 36443
Global Const $ID_EL_Crate_of_Fireworks = 31147
Local Const $EL_Tonic_Array[] = []
Global Const $Map_EL_Tonics = MapFromArray($EL_Tonic_Array)
#EndRegion EL Tonics
#EndRegion Tonics


#Region Minis
; First year
Global Const $ID_Prince_Rurik_Mini = 13790
Global Const $ID_Shiro_Mini = 13791
Global Const $ID_Charr_Shaman_Mini = 13784
Global Const $ID_Fungal_Wallow_Mini = 13782
Global Const $ID_Bone_Dragon_Mini = 13783
Global Const $ID_Hydra_Mini = 13787
Global Const $ID_Jade_Armor_Mini = 13788
Global Const $ID_Kirin_Mini = 13789
Global Const $ID_Jungle_Troll_Mini = 13794
Global Const $ID_Necrid_Horseman_Mini = 13786
Global Const $ID_Temple_Guardian_Mini = 13792
Global Const $ID_Burning_Titan_Mini = 13793
Global Const $ID_Siege_Turtle_Mini = 13795
Global Const $ID_Whiptail_Devourer_Mini = 13785
; Second year
Global Const $ID_Gwen_Mini = 22753
Global Const $ID_Water_Djinn_Mini = 22754
Global Const $ID_Lich_Mini = 22755
Global Const $ID_Elf_Mini = 22756
Global Const $ID_Palawa_Joko_Mini = 22757
Global Const $ID_Koss_Mini = 22758
Global Const $ID_Aatxe_Mini = 22765
Global Const $ID_Harpy_Ranger_Mini = 22761
Global Const $ID_Heket_Warrior_Mini = 22760
Global Const $ID_Juggernaut_Mini = 22762
Global Const $ID_Mandragor_Imp_Mini = 22759
Global Const $ID_Thorn_Wolf_Mini = 22766
Global Const $ID_Wind_Rider_Mini = 22763
Global Const $ID_Fire_Imp_Mini = 22764
; Third year
Global Const $ID_Black_Beast_of_Aaaaarrrrrrggghhh_Mini = 30611
Global Const $ID_Irukandji_Mini = 30613
Global Const $ID_Mad_King_Thorn_Mini = 30614
Global Const $ID_Raptor_Mini = 30619
Global Const $ID_Cloudtouched_Simian_Mini = 30621
Global Const $ID_White_Rabbit_Mini = 30623
Global Const $ID_Freezie_Mini = 30612
Global Const $ID_Nornbear_Mini = 32519
Global Const $ID_Ooze_Mini = 30618
Global Const $ID_Abyssal_Mini = 30610
Global Const $ID_Cave_Spider_Mini = 30622
Global Const $ID_Forest_Minotaur_Mini = 30615
Global Const $ID_Mursaat_Mini = 30616
Global Const $ID_Roaring_Ether_Mini = 30620
; Fourth year
Global Const $ID_Eye_of_Janthir_Mini = 32529
Global Const $ID_Dredge_Brute_Mini = 32517
Global Const $ID_Terrorweb_Dryder_Mini = 32518
Global Const $ID_Abomination_Mini = 32519
Global Const $ID_Flame_Djinn_Mini = 32528
Global Const $ID_Flowstone_Elemental_Mini = 32525
Global Const $ID_Nian_Mini = 32526
Global Const $ID_Dagnar_Stonepate_Mini = 32527
Global Const $ID_Jora_Mini = 32524
Global Const $ID_Desert_Griffon_Mini = 32521
Global Const $ID_Krait_Neoss_Mini = 32520
Global Const $ID_Kveldulf_Mini = 32522
Global Const $ID_Quetzal_Sly_Mini = 32523
Global Const $ID_Word_of_Madness_Mini = 32516
; Fifth year
Global Const $ID_MOX_Mini = 34400
Global Const $ID_Ventari_Mini = 34395
Global Const $ID_Oola_Mini = 34396
Global Const $ID_Candysmith_Marley_Mini = 34397
Global Const $ID_Zhu_Hanuku_Mini = 34398
Global Const $ID_King_Adelbern_Mini = 34399
Global Const $ID_Cobalt_Scabara_Mini = 34393
Global Const $ID_Fire_Drake_Mini = 34390
Global Const $ID_Ophil_Nahualli_Mini = 34392
Global Const $ID_Scourge_Manta_Mini = 34394
Global Const $ID_Seer_Mini = 34386
Global Const $ID_Shard_Wolf_Mini = 34389
Global Const $ID_Siege_Devourer = 34387
Global Const $ID_Summit_Giant_Herder = 34391
; Seventh
Global Const $ID_Vizu_Mini = 22196
Global Const $ID_Shiroken_Assassin_Mini = 22195
Global Const $ID_Zhed_Shadowhoof_Mini = 22197
Global Const $ID_Naga_Raincaller_Mini = 15515
Global Const $ID_Oni_Mini = 15516
; Collector Edition
Global Const $ID_Kuunavang_Mini = 12389
Global Const $ID_Varesh_Ossa_Mini = 21069
; In-Game Reward
Global Const $ID_Mallyx_Mini = 21229
Global Const $ID_Black_Moa_Chick_Mini = 25499
Global Const $ID_Gwen_Doll_Mini = 31157
Global Const $ID_Yakkington_Mini = 32515
Global Const $ID_Brown_Rabbit_Mini = 31158
;Global Const $ID_Ghostly_Hero_Mini =
Global Const $ID_Minister_Reiko_Mini = 30224
Global Const $ID_Ecclesiate_Xun_Rao_Mini = 30225
;Global Const $ID_Peacekeeper_Enforcer_Mini =
Global Const $ID_Evennia_Mini = 35128
Global Const $ID_Livia_Mini = 35129
Global Const $ID_Princess_Salma_Mini = 35130
Global Const $ID_Confessor_Dorian_Mini = 35132
Global Const $ID_Confessor_Isaiah_Mini = 35131
Global Const $ID_Guild_Lord_Mini = 36648
Global Const $ID_Ghostly_Priest_Mini = 36650
Global Const $ID_Rift_Warden_Mini = 36651
Global Const $ID_High_Priest_Zhang_Mini = 36649
Global Const $ID_Dhuum_Mini = 32822
Global Const $ID_Smite_Crawler_Mini = 32556
; Special Event Minis
;Global Const $ID_Greased_Lightning_Mini =
Global Const $ID_Pig_Mini = 21806
Global Const $ID_Celestial_Pig_Mini = 29412
Global Const $ID_Celestial_Rat_Mini = 29413
Global Const $ID_Celestial_Ox_Mini = 29414
Global Const $ID_Celestial_Tiger_Mini = 29415
Global Const $ID_Celestial_Rabbit_Mini = 29416
Global Const $ID_Celestial_Dragon_Mini = 29417
Global Const $ID_Celestial_Snake_Mini = 29418
Global Const $ID_Celestial_Horse_Mini = 29419
Global Const $ID_Celestial_Sheep_Mini = 29420
Global Const $ID_Celestial_Monkey_Mini = 29421
Global Const $ID_Celestial_Rooster_Mini = 29422
Global Const $ID_Celestial_Dog_Mini = 29423
Global Const $ID_World_Famous_Racing_Beetle_Mini = 37792
;Global Const $ID_Legionnaire_Mini =
; Promotional
Global Const $ID_Asura_Mini = 22189
Global Const $ID_Destroyer_of_Flesh_Mini = 22250
Global Const $ID_Gray_Giant_Mini = 17053
Global Const $ID_Grawl_Mini = 22822
Global Const $ID_Ceratadon_Mini = 28416
; Miscellaneous
;Global Const $ID_Kanaxai_Mini =
Global Const $ID_Polar_Bear_Mini = 21439
Global Const $ID_Mad_Kings_Guard_Mini = 32555
Global Const $ID_Panda_Mini = 15517
;Global Const $ID_Longhair_Yeti_Mini =
#EndRegion Minis


#Region Envoy Weapons
;Envoy Skinned Greens
; Green Envoys
Global Const $ID_Demrikovs_Judgement = 36670
Global Const $ID_Vetauras_Harbinger = 36678
Global Const $ID_Torivos_Rage = 36680
Global Const $ID_Heleynes_Insight = 36676
; Gold Envoys
;Global Const $ID_Envoy_Sword =
Global Const $ID_Envoy_Scythe = 36677
;Global Const $ID_Envoy_Axe =
;Global Const $ID_Chaotic_Envoy_Staff =
;Global Const $ID_Dark_Envoy_Staff =
;Global Const $ID_Elemental_Envoy_Staff =
;Global Const $ID_Divine_Envoy_Staff =
;Global Const $ID_Spiritual_Envoy_Staff =
#EndRegion Envoy Weapons


#Region Froggy
Global Const $ID_Froggy_Domination = 1953
Global Const $ID_Froggy_Fast_Casting = 1956
Global Const $ID_Froggy_Illusion = 1957
Global Const $ID_Froggy_Inspiration = 1958
Global Const $ID_Froggy_Soul_Reaping = 1959
Global Const $ID_Froggy_Blood = 1960
Global Const $ID_Froggy_Curses = 1961
Global Const $ID_Froggy_Death = 1962
Global Const $ID_Froggy_Air = 1963
Global Const $ID_Froggy_Earth = 1964
Global Const $ID_Froggy_Energy_Storage = 1965
Global Const $ID_Froggy_Fire = 1966
Global Const $ID_Froggy_Water = 1967
Global Const $ID_Froggy_Divine = 1968
Global Const $ID_Froggy_Healing = 1969
Global Const $ID_Froggy_Protection = 1970
Global Const $ID_Froggy_Smiting = 1971
Global Const $ID_Froggy_Communing = 1972
Global Const $ID_Froggy_Spawning = 1973
Global Const $ID_Froggy_Restoration = 1974
Global Const $ID_Froggy_Channeling = 1975
#EndRegion Froggy


#Region Bone Dragon Staff
Global Const $ID_BDS_Domination = 1987
Global Const $ID_BDS_Fast_Casting = 1988
Global Const $ID_BDS_Illusion = 1989
Global Const $ID_BDS_Inspiration = 1990
Global Const $ID_BDS_Soul_Reaping = 1991
Global Const $ID_BDS_Blood = 1992
Global Const $ID_BDS_Curses = 1993
Global Const $ID_BDS_Death = 1994
Global Const $ID_BDS_Air = 1995
Global Const $ID_BDS_Earth = 1996
Global Const $ID_BDS_Energy_Storage = 1997
Global Const $ID_BDS_Fire = 1998
Global Const $ID_BDS_Water = 1999
Global Const $ID_BDS_Divine = 2000
Global Const $ID_BDS_Healing = 2001
Global Const $ID_BDS_Protection = 2002
Global Const $ID_BDS_Smiting = 2003
Global Const $ID_BDS_Communing = 2004
Global Const $ID_BDS_Spawning = 2005
Global Const $ID_BDS_Restoration = 2006
Global Const $ID_BDS_Channeling = 2007
#EndRegion Bone Dragon Staff


#Region Wintergreen Weapons
Global Const $ID_Wintergreen_Axe = 15835
Global Const $ID_Wintergreen_Bow = 15836
Global Const $ID_Wintergreen_Sword = 16130
Global Const $ID_Wintergreen_Daggers = 15838
Global Const $ID_Wintergreen_Hammer = 15839
Global Const $ID_Wintergreen_Wand = 15840
Global Const $ID_Wintergreen_Scythe = 15877
Global Const $ID_Wintergreen_Shield = 15878
Global Const $ID_Wintergreen_Spear = 15971
Global Const $ID_Wintergreen_Staff =16128
#EndRegion Wintergreen Weapons


#Region Celestial Compass
Global Const $ID_CC_Domination = 1055
Global Const $ID_CC_Fast_Casting = 1058
Global Const $ID_CC_Illusion = 1060
Global Const $ID_CC_Inspiration = 1064
Global Const $ID_CC_Soul_Reaping = 1752
Global Const $ID_CC_Blood = 1065
Global Const $ID_CC_Curses = 1066
Global Const $ID_CC_Death = 1067
Global Const $ID_CC_Air = 1768
Global Const $ID_CC_Earth = 1769
Global Const $ID_CC_Energy_Storage = 1770
Global Const $ID_CC_Fire = 1771
Global Const $ID_CC_Water = 1772
Global Const $ID_CC_Divine = 1773
Global Const $ID_CC_Healing = 1870
Global Const $ID_CC_Protection = 1879
Global Const $ID_CC_Smiting = 1880
Global Const $ID_CC_Communing = 1881
Global Const $ID_CC_Spawning = 1883
Global Const $ID_CC_Restoration = 1884
Global Const $ID_CC_Channeling = 1885
#EndRegion Celestial Compass


Local $StackableItems = $Blue_Scrolls_Array
_ArrayConcatenate($StackableItems, $Gold_Scrolls_Array)
_ArrayConcatenate($StackableItems, $Sweet_Pcons_Array)
_ArrayConcatenate($StackableItems, $Special_Drops)
_ArrayConcatenate($StackableItems, $DPRemoval_Sweets)
_ArrayConcatenate($StackableItems, $Town_Sweets_Array)
_ArrayConcatenate($StackableItems, $Party_Tonics_Array)
_ArrayConcatenate($StackableItems, $All_Festive_Array)
_ArrayConcatenate($StackableItems, $Alcohols_Array)
_ArrayConcatenate($StackableItems, $Tomes_Array)
_ArrayConcatenate($StackableItems, $Trophies_Array)
_ArrayConcatenate($StackableItems, $Map_Pieces_Array)
_ArrayAdd($StackableItems, $ID_Lockpick)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_1)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_2)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_3)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_4)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_5)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_6)
_ArrayAdd($StackableItems, $ID_UNKNOWN_STACKABLE_7)
Global Const $Map_StackableItemsExceptMaterials = MapFromArray($StackableItems)



#Region Mods
#Region Weapon Mods
Global Const $ID_Staff_Head = 896
Global Const $ID_Staff_Wrapping = 908
Global Const $ID_Shield_Handle = 15554
Global Const $ID_Focus_Core = 15551
Global Const $ID_Wand = 15552
Global Const $ID_Bow_String = 894
Global Const $ID_Bow_Grip = 906
Global Const $ID_Sword_Hilt = 897
Global Const $ID_Sword_Pommel = 909
Global Const $ID_Axe_Haft = 893
Global Const $ID_Axe_Grip = 905
Global Const $ID_Dagger_Tang = 6323
Global Const $ID_Dagger_Handle = 6331
Global Const $ID_Hammer_Haft = 895
Global Const $ID_Hammer_Grip = 907
Global Const $ID_Scythe_Snathe = 15543
Global Const $ID_Scythe_Grip = 15553
Global Const $ID_Spearhead = 15544
Global Const $ID_Spear_Grip = 15555
Global Const $ID_Inscriptions_Martial = 15540
Global Const $ID_Inscriptions_Offhand = 15541
Global Const $ID_Inscriptions_All = 15542
Global Const $ID_Inscriptions_General = 17059
Global Const $ID_Inscriptions_Spellcasting = 19122
Global Const $ID_Inscriptions_Focus = 19123
Local Const $Weapon_Mods_Array[25] = [$ID_Axe_Haft, $ID_Bow_String, $ID_Hammer_Haft, $ID_Staff_Head, $ID_Sword_Hilt, $ID_Axe_Grip, $ID_Bow_Grip, $ID_Hammer_Grip, $ID_Staff_Wrapping, $ID_Sword_Pommel, $ID_Dagger_Tang, $ID_Dagger_Handle, _
	$ID_Inscriptions_Martial, $ID_Inscriptions_Offhand, $ID_Inscriptions_All, $ID_Scythe_Snathe, $ID_Spearhead, $ID_Focus_Core, $ID_Wand, $ID_Scythe_Grip, $ID_Shield_Handle, $ID_Spear_Grip, $ID_Inscriptions_General, _
	$ID_Inscriptions_Spellcasting, $ID_Inscriptions_Focus]
Global Const $Map_Weapon_Mods = MapFromArray($Weapon_Mods_Array)
#EndRegion Weapon Mods

; Valid for shields/focus but also staff and probably others
Global Const $ID_Plus_30_Health = '1E4823'

; Shield/Focus Mods health and minus damage
Global Const $ID_Minus_3_Hex = '3009820'
Global Const $ID_Minus_2_Stance = '200A820'
Global Const $ID_Minus_2_Enchantment = '2008820'
Global Const $ID_Plus_45_Stance = '02D8823'
Global Const $ID_Plus_45_Enchantment = '02D6823'
Global Const $ID_Plus_44_Enchantment_Demons = '02C6823'
Global Const $ID_Minus_5_20 = '5147820'
; Shield/Focus Mods +10 vs X
Global Const $ID_Plus_10_vs_Demons = 'A0848210'
Global Const $ID_Plus_10_vs_Dragons = 'A0948210'
Global Const $ID_Plus_10_vs_Plants = 'A0348210'
Global Const $ID_Plus_10_vs_Tengu = 'A0748210'
Global Const $ID_Plus_10_vs_Undead = 'A0048210'

Global Const $ID_Plus_10_vs_Blunt = '0A0018A1'
Global Const $ID_Plus_10_vs_Piercing = 'A0118210'
Global Const $ID_Plus_10_vs_Slashing = 'A0218210'

Global Const $ID_Plus_10_vs_Air = 'A0418210'
Global Const $ID_Plus_10_vs_Cold = 'A0318210'
Global Const $ID_Plus_10_vs_Earth = 'A0B18210'
Global Const $ID_Plus_10_vs_Fire = 'A0518210'

; +1 20% Mods
Global Const $ID_Plus_1_Domination = '0218240'
Global Const $ID_Plus_1_Divine = '1018240'
Global Const $ID_Plus_1_Smite = '0E18240'
Global Const $ID_Plus_1_Healing = '0D18240'
Global Const $ID_Plus_1_Prot = '0F18240'
Global Const $ID_Plus_1_Fire = '0A18240'
Global Const $ID_Plus_1_Water = '0B18240'
Global Const $ID_Plus_1_Air = '0818240'
Global Const $ID_Plus_1_Earth = '0918240'
Global Const $ID_Plus_1_Death = '0518240'
Global Const $ID_Plus_1_Blood = '0418240'

; Universal mods
Global Const $ID_Plus_5_50 = '5320823'
Global Const $ID_Plus_5_Enchantment = '500F822'
Global Const $ID_Casting_10 = 'A0822'
Global Const $ID_Recharge_10 = 'AA823'

; Ele mods
Global Const $ID_Casting_20_Fire = '0A141822'
Global Const $ID_Casting_20_Water = '0B141822'
Global Const $ID_Casting_20_Air = '08141822'
Global Const $ID_Casting_20_Earth = '09141822'
Global Const $ID_Casting_20_Energy = '0C141822'
Global Const $ID_Recharge_20_Fire = '0A149823'
Global Const $ID_Recharge_20_Water = '0B149823'
Global Const $ID_Recharge_20_Air = '08149823'
Global Const $ID_Recharge_20_Earth = '09149823'
Global Const $ID_Recharge_20_Energy = '0C149823'
; Monk mods
Global Const $ID_Casting_20_Smite = '0E141822'
Global Const $ID_Casting_20_Divine = '10141822'
Global Const $ID_Casting_20_Healing = '0D141822'
Global Const $ID_Casting_20_Protection = '0F141822'
Global Const $ID_Recharge_20_Smiting = '0E149823'
Global Const $ID_Recharge_20_Divine = '10149823'
Global Const $ID_Recharge_20_Healing = '0D149823'
Global Const $ID_Recharge_20_Protection = '0F149823'
; Rit mods
Global Const $ID_Casting_20_Channeling = '22141822'
Global Const $ID_Casting_20_Restoration = '21141822'
Global Const $ID_Recharge_20_Channeling = '22149823'
Global Const $ID_Recharge_20_Restoration = '21149823'
; Mes mods
Global Const $ID_Casting_20_Domination = '02141822'
Global Const $ID_Recharge_20_Domination = '02149823'
; Necro mods
Global Const $ID_Casting_20_Death = '05141822'
Global Const $ID_Casting_20_Blood = '04141822'
Global Const $ID_Recharge_20_Death = '05149823'
Global Const $ID_Recharge_20_Blood = '04149823'

; Runes and insignias
Global Const $ID_Rune_Superior_Vigor = 'C202EA27'
Global Const $ID_Insignia_Windwalker = '040430A5060518A7'
Global Const $ID_Rune_Minor_Mysticism = '05033025012CE821'
Global Const $ID_Rune_Superior_Earth_Prayers = '32BE82109033025'
Global Const $ID_Insignia_Prodigy = 'C60330A5000528A7'
Global Const $ID_Rune_Superior_Domination = '30250302E821770'
Global Const $ID_Insignia_Shaman = '080430A50005F8A'

; Weapon damage
Global $ID_Weapon_stats = 'A8A7'
; Focus energy
Global $ID_Focus_energy = 'C867'
; Shield armor
Global $ID_Focus_energy = 'B8A7'

; Staff mods
Global $ID_Plus_5_Armor = '05000821'

; Furious mod (Axe haft, Dagger Tang, Hammer Haft, Scythe Snathe, Spearhead, Sword Hilt)
Global Const $ID_Furious_Mod = '0A00B823'

Global Const $ID_Enchanting_Mod = '1400B822'

Global Const $ID_Casting_20 = '00140828'
Global Const $ID_Recharge_20 = '00142828'

#EndRegion Mods

#EndRegion Items