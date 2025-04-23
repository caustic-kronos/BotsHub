; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include-once
#include <Array.au3>
#include 'Utils.au3'

Func ContainsValuableUpgrades($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)

	Local $modstruct = GetModStruct($item)
	If Not $modstruct Then Return False

	If IsWeapon($item) Then
		If HasSalvageInscription($item) Then Return True
		Local $itemType = DllStructGetData($item, 'type')
		For $struct In $ValuableModsByType[$itemType]
			If StringInStr($ModStruct, $struct) > 0 Then Return True
		Next
	ElseIf IsArmorSalvageItem($item) Then
		For $struct In $Valuable_Rune_And_Insignia_Structs_Array
			If StringInStr($ModStruct, $struct) > 0 Then Return True
		Next
	EndIf
	Return False
EndFunc


Local $STRUCT_MINUS_5_ENERGY = '0500B820'
Local $STRUCT_15_ENERGY = '0F00D822'
Local $STRUCT_ENERGY_REGENERATION = '0100C820'


#Region Weapon Mods
Global Const $ID_Staff_Head					= 896
Global Const $ID_Staff_Wrapping				= 908
Global Const $ID_Shield_Handle				= 15554
Global Const $ID_Focus_Core					= 15551
Global Const $ID_Wand						= 15552
Global Const $ID_Bow_String					= 894
Global Const $ID_Bow_Grip					= 906
Global Const $ID_Sword_Hilt					= 897
Global Const $ID_Sword_Pommel				= 909
Global Const $ID_Axe_Haft					= 893
Global Const $ID_Axe_Grip					= 905
Global Const $ID_Dagger_Tang				= 6323
Global Const $ID_Dagger_Handle				= 6331
Global Const $ID_Hammer_Haft				= 895
Global Const $ID_Hammer_Grip				= 907
Global Const $ID_Scythe_Snathe				= 15543
Global Const $ID_Scythe_Grip				= 15553
Global Const $ID_Spearhead					= 15544
Global Const $ID_Spear_Grip					= 15555
Global Const $ID_Inscriptions_Martial		= 15540
Global Const $ID_Inscriptions_Offhand		= 15541
Global Const $ID_Inscriptions_All			= 15542
Global Const $ID_Inscriptions_General		= 17059
Global Const $ID_Inscriptions_Spellcasting	= 19122
Global Const $ID_Inscriptions_Focus			= 19123
Local Const $Weapon_Mods_Array[]			= [$ID_Axe_Haft, $ID_Bow_String, $ID_Hammer_Haft, $ID_Staff_Head, $ID_Sword_Hilt, $ID_Axe_Grip, $ID_Bow_Grip, $ID_Hammer_Grip, $ID_Staff_Wrapping, $ID_Sword_Pommel, $ID_Dagger_Tang, $ID_Dagger_Handle, _
												$ID_Inscriptions_Martial, $ID_Inscriptions_Offhand, $ID_Inscriptions_All, $ID_Scythe_Snathe, $ID_Spearhead, $ID_Focus_Core, $ID_Wand, $ID_Scythe_Grip, $ID_Shield_Handle, $ID_Spear_Grip, _
												$ID_Inscriptions_General, $ID_Inscriptions_Spellcasting, $ID_Inscriptions_Focus]
Global Const $Map_Weapon_Mods				= MapFromArray($Weapon_Mods_Array)
#EndRegion Weapon Mods


#Region Weapon Inscriptions
#Region Common Inscriptions
Local $STRUCT_INSCRIPTION_MEASURE_FOR_MEASURE = '1F0208243E0432251'		;salvageable
Local $STRUCT_INSCRIPTION_SHOW_ME_THE_MONEY = '1E0208243C043225'		;rare/money

Local $STRUCT_INSCRIPTION_STRENGTH_AND_HONOR = '0F327822'				;+15% while health > 50%
Local $STRUCT_INSCRIPTION_GUIDED_BY_FATE = '0F006822'					;+15% while enchanted
Local $STRUCT_INSCRIPTION_DANCE_WITH_DEATH = '0F00A822'					;+15% while in a stance
Local $STRUCT_INSCRIPTION_TOO_MUCH_INFORMATION = '0F005822'				;+15% against hexed foes
Local $STRUCT_INSCRIPTION_TO_THE_PAIN = '0A001820'						;+15% damage -10 armor while attacking - -10 armor part
;Local $STRUCT_INSCRIPTION_TO_THE_PAIN_2 = '0F003822'					;+15% damage -10 armor while attacking - +15% damage part
Local $STRUCT_INSCRIPTION_BRAWN_OVER_BRAIN = $STRUCT_MINUS_5_ENERGY		;+15% damage -5 energy - -5 energy part
;Local $STRUCT_INSCRIPTION_BRAWN_OVER_BRAIN_2 = '0F003822'				;+15% damage -5 energy - +15% damage part
Local $STRUCT_INSCRIPTION_VENGEANCE_IS_MINE = '14328822'				;+20% while health < 50%
Local $STRUCT_INSCRIPTION_DONT_FEAR_THE_REAPER = '14009822'				;+20% while hexed
Local $STRUCT_INSCRIPTION_DONT_THINK_TWICE = '000A0822'					;hct 10
#EndRegion Common Inscriptions

#Region Martial Inscriptions
Local $STRUCT_INSCRIPTION_I_HAVE_THE_POWER = '0500D822'					;+5e
Local $STRUCT_INSCRIPTION_LET_THE_MEMORY_LIVE_AGAIN = '000AA823'		;hsr 10
#EndRegion Martial Inscriptions

#Region Caster Weapon Inscriptions
Local $STRUCT_INSCRIPTION_HALE_AND_HEARTY = '05320823'            		;+5e while health > 50%
Local $STRUCT_INSCRIPTION_HAVE_FAITH = '0500F822'                  		;+5e while enchanted
Local $STRUCT_INSCRIPTION_DONT_CALL_IT_A_COME_BACK = '07321823'			;+7e while health < 50%
Local $STRUCT_INSCRIPTION_I_AM_SORROW = '07002823'						;+7e while hexed
Local $STRUCT_INSCRIPTION_SEIZE_THE_DAY_1 = $STRUCT_15_ENERGY			;+15e energy regeneration -1 - +15e part
Local $STRUCT_INSCRIPTION_SEIZE_THE_DAY_2 = $STRUCT_ENERGY_REGENERATION	;+15e energy regeneration -1 - energy regeneration -1 part
Local $STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE = '00140828'			;hct 20
#EndRegion Caster Weapon Inscriptions
#EndRegion Weapon Inscriptions

#Region Offhand Inscriptions
#Region Focus Inscriptions
Local $STRUCT_INSCRIPTION_FORGET_ME_NOT = '00142828'						;hsr 20
Local $STRUCT_INSCRIPTION_SERENITY_NOW = '000AA823'							;hsr 10

Local $STRUCT_INSCRIPTION_HAIL_TO_THE_KING = '0532A821'						;+5 armor while health > 50%
Local $STRUCT_INSCRIPTION_FAITH_IS_MY_SHIELD = '05009821'					;+5 armor while enchanted
Local $STRUCT_INSCRIPTION_MIGHT_MAKES_RIGHT = '05007821'           			;+5 armor while attacking
Local $STRUCT_INSCRIPTION_KNOWING_IS_HALF_THE_BATTLE = '05008821'  			;+5 armor while casting
Local $STRUCT_INSCRIPTION_MAN_FOR_ALL_SEASONS = '05002821'         			;+5 armor vs elemental damage
Local $STRUCT_INSCRIPTION_SURVIVAL_OF_THE_FITTEST = '05005821'     			;+5 armor vs physical damage
Local $STRUCT_INSCRIPTION_IGNORANCE_IS_BLISS_1 = '05000821'        			;+5 armor ^ -5 energy - +5 armor part
Local $STRUCT_INSCRIPTION_IGNORANCE_IS_BLISS_2 = $STRUCT_MINUS_5_ENERGY		;+5 armor ^ -5 energy - -5 energy part
Local $STRUCT_INSCRIPTION_LIFE_IS_PAIN = '1400D820'              			;+5 armor ^ -20 health - -20 health part
;Local $STRUCT_INSCRIPTION_LIFE_IS_PAIN_2 = '05000821'              		;+5 armor ^ -20 health - +5 armor part
Local $STRUCT_INSCRIPTION_DOWN_BUT_NOT_OUT = '0A32B821'            			;+10 armor while health < 50%
Local $STRUCT_INSCRIPTION_BE_JUST_AND_FEAR_NOT = '0A00C821'        			;+10 armor while hexed
Local $STRUCT_INSCRIPTION_LIVE_FOR_TODAY_1 = $STRUCT_15_ENERGY        		;+15 energy ^ -1 energy regeneration - +15 energy part
Local $STRUCT_INSCRIPTION_LIVE_FOR_TODAY_2 = $STRUCT_ENERGY_REGENERATION	;+15 energy ^ -1 energy regeneration - energy regeneration -1 part
#EndRegion Focus Inscriptions

#Region Focus and Shield Inscriptions
Local $STRUCT_INSCRIPTION_MASTER_OF_MY_DOMAIN = '00143828'			;+1^20% item attribute

Local $STRUCT_INSCRIPTION_NOT_THE_FACE = '0A0018A1'            		;+10 armor vs blunt
Local $STRUCT_INSCRIPTION_LEAF_ON_THE_WIND = '0A0318A1'        		;+10 armor vs cold
Local $STRUCT_INSCRIPTION_LIKE_A_ROLLING_STONE = '0A0B18A1'    		;+10 armor vs earth
Local $STRUCT_INSCRIPTION_SLEEP_NOW_IN_THE_FIRE = '0A0518A1'   		;+10 armor vs fire
Local $STRUCT_INSCRIPTION_RIDERS_ON_THE_STORM = '0A0418A1'     		;+10 armor vs lightning
Local $STRUCT_INSCRIPTION_THROUGH_THICK_AND_THIN = '0A0118A1'		;+10 armor vs piercing
Local $STRUCT_INSCRIPTION_THE_RIDDLE_OF_STEEL = '0A0218A1'			;+10 armor vs slashing

Local $STRUCT_INSCRIPTION_SHELTERED_BY_FAITH = '02008820'			;-2 physical damage while enchanted
Local $STRUCT_INSCRIPTION_RUN_FOR_YOUR_LIFE = '0200A820'			;-2 physical damage while in a stance
Local $STRUCT_INSCRIPTION_NOTHING_TO_FEAR = '03009820'				;-3 physical damage while hexed
Local $STRUCT_INSCRIPTION_LUCK_OF_THE_DRAW = '05147820'				;-5 physical damage ^ 20%

Local $STRUCT_INSCRIPTION_FEAR_CUTS_DEEPER = '00005828'				;-20 bleeding duration
Local $STRUCT_INSCRIPTION_I_CAN_SEE_CLEARLY_NOW = '00015828'		;-20 blind duration
Local $STRUCT_INSCRIPTION_SWIFT_AS_THE_WIND = '00035828'			;-20 crippled duration
Local $STRUCT_INSCRIPTION_SOUNDNESS_OF_MIND = '00075828'			;-20 dazed duration
Local $STRUCT_INSCRIPTION_STRENGTH_OF_BODY = '00045828'				;-20 deep wound duration
Local $STRUCT_INSCRIPTION_CAST_OUT_THE_UNCLEAN = '00055828'			;-20 disease duration
Local $STRUCT_INSCRIPTION_CAST_OUT_THE_UNCLEAN_OS = 'E3017824'		;-20 disease duration
Local $STRUCT_INSCRIPTION_PURE_OF_HEART = '00065828'				;-20 poison duration
Local $STRUCT_INSCRIPTION_ONLY_THE_STRONG_SURVIVE = '00085828'		;-20 weakness duration								; incorrect
#EndRegion Focus and Shield Inscriptions
#EndRegion Offhand Inscriptions



#Region Mods
#Region common mods
Local $STRUCT_MOD_30_HEALTH = '001E4823'						;+30 health
Local $STRUCT_MOD_5_ARMOR = '05000821'							;+5 armor
Local $STRUCT_MOD_OF_SHELTER = '07005821'						;+7 armor vs physical
Local $STRUCT_MOD_OF_WARDING = '07002821'						;+7 armor vs elemental
Local $STRUCT_MOD_OF_ENCHANTING = '1400B822'					;+20% enchantment duration

Local $STRUCT_MOD_OF_THE_WARRIOR = '0511A828'
Local $STRUCT_MOD_OF_THE_RANGER = '0517A828'
Local $STRUCT_MOD_OF_THE_NECROMANCER = '0506A828'
Local $STRUCT_MOD_OF_THE_MESMER = '0500A828'
Local $STRUCT_MOD_OF_THE_ELEMENTALIST = '050CA828'
Local $STRUCT_MOD_OF_THE_MONK = '0510A828'
Local $STRUCT_MOD_OF_THE_RITUALIST = '0524A828'
Local $STRUCT_MOD_OF_THE_ASSASSIN = '0523A828'
Local $STRUCT_MOD_OF_THE_PARAGON = '0528A828'
Local $STRUCT_MOD_OF_THE_DERVISH = '052CA828'

Local $STRUCT_MOD_OF_DEATHBANE = '00008080'
Local $STRUCT_MOD_OF_CHARRSLAYING = '00018080'
Local $STRUCT_MOD_OF_TROLLSLAYING = '00028080'
Local $STRUCT_MOD_OF_PRUNING = '00038080'
Local $STRUCT_MOD_OF_SKELETON_SLAYING = '00048080'
Local $STRUCT_MOD_OF_GIANT_SLAYING = '00058080'
Local $STRUCT_MOD_OF_DWARF_SLAYING = '00068080'
Local $STRUCT_MOD_OF_TENGU_SLAYING = '00078080'
Local $STRUCT_MOD_OF_DEMON_SLAYING = '00088080'
Local $STRUCT_MOD_OF_OGRE_SLAYING = '000A8080'
Local $STRUCT_MOD_OF_DRAGON_SLAYING = '00098080'
#EndRegion common mods

#Region martial mods
Local $STRUCT_MOD_BARBED_PREFIX = 'DE016824'					;+33% bleeding
Local $STRUCT_MOD_CRUEL_PREFIX = 'E2016824'						;+33% deep wound
Local $STRUCT_MOD_CRIPPLING_PREFIX = 'E1016824'					;+33% crippled							;Doesn't match all crippling prefixes
Local $STRUCT_MOD_HEAVY_PREFIX = 'E601824'						;+33% weakness
Local $STRUCT_MOD_POISONOUS_PREFIX = 'E4016824'					;+33% poison
Local $STRUCT_MOD_SILENCING_PREFIX = 'E5016824'           		;+33% dazed

Local $STRUCT_MOD_EBON_PREFIX = '000BB824'
Local $STRUCT_MOD_FIERY_PREFIX = '0005B824'
Local $STRUCT_MOD_ICY_PREFIX = '0003B824'
Local $STRUCT_MOD_SHOCKING_PREFIX = '0004B824'

Local $STRUCT_MOD_FURIOUS_PREFIX = '0A00B823'					;adrenaline * 2 ^ 20%
Local $STRUCT_MOD_SUNDERING_PREFIX = '1414F823'					;armor penetration 20^20

Local $STRUCT_MOD_VAMPIRIC_3_PREFIX = '00032825'
Local $STRUCT_MOD_VAMPIRIC_5_PREFIX = '00052825'
Local $STRUCT_MOD_ZEALOUS_PREFIX = '01001825'
; +1^20%
Local $STRUCT_MOD_OF_AXE_MASTERY = '14121824'
Local $STRUCT_MOD_OF_MARKSMANSHIP = '14191824'
Local $STRUCT_MOD_OF_DAGGER_MASTERY = '141D1824'
Local $STRUCT_MOD_OF_HAMMER_MASTERY = '14131824'
Local $STRUCT_MOD_OF_SCYTHE_MASTERY = '14291824'
Local $STRUCT_MOD_OF_SPEAR_MASTERY = '14251824'
Local $STRUCT_MOD_OF_SWORDMANSHIP = '14141824'
#EndRegion of Mastery

#Region caster weapons mods
Local $STRUCT_MOD_HCT_20 = '00140828'
Local $STRUCT_MOD_HCT_10 = '000A0822'
Local $STRUCT_MOD_HSR_20 = '00142828'
Local $STRUCT_MOD_HSR_10 = '000AA823'
#EndRegion caster weapons mods

#Region staff mods
Local $STRUCT_MOD_OF_DEVOTION = '002D6823'								;+45 health while enchanted
Local $STRUCT_MOD_OF_ENDURANCE = '002D8823'								;+45 health while in a stance
Local $STRUCT_MOD_OF_VALOR = '003C7823'                					;+60 health while hexed

Local $STRUCT_MOD_STAFF_MASTERY  = '00143828'							;+1^20%
#EndRegion staff mods
#EndRegion Mods


#Region inherent bonus
#Region martial weapons
Local $STRUCT_INHERENT_ZEALOUS_STRENGTH = $STRUCT_ENERGY_REGENERATION	;+15% damage energy regeneration -1 - energy regeneration -1 part
;Local $STRUCT_INHERENT_ZEALOUS_STRENGTH_2 = '0F003822'					;+15% damage -1 energy regeneration - +15% damage part

Local $STRUCT_INHERENT_VAMPIRIC_STRENGTH = '0100E820'					;+15% damage health regeneration -1 - health regeneration -1 part
;Local $STRUCT_INHERENT_VAMPIRIC_STRENGTH_2 = '0F003822'				;+15% damage -1 health regeneration - +15% damage part
#EndRegion martial weapons

; Missing the inherent hsr^20 and hct^20 for specific attributes

#Region focus and shield OS
; 10 armor VS ...
Local $STRUCT_INHERENT_ARMOR_VS_UNDEAD = '0A004821'		;'A0048210'
Local $STRUCT_INHERENT_ARMOR_VS_CHARR = '0A014821'
Local $STRUCT_INHERENT_ARMOR_VS_TROLLS = '0A024821'
Local $STRUCT_INHERENT_ARMOR_VS_PLANTS = '0A034821'		;'A0348210'
Local $STRUCT_INHERENT_ARMOR_VS_SKELETONS = '0A044821'
Local $STRUCT_INHERENT_ARMOR_VS_GIANTS = '0A054821'
Local $STRUCT_INHERENT_ARMOR_VS_DWARVES = '0A064821'
Local $STRUCT_INHERENT_ARMOR_VS_TENGU = '0A074821'		;'A0748210'
Local $STRUCT_INHERENT_ARMOR_VS_DEMONS = '0A084821'		;'A0848210'
Local $STRUCT_INHERENT_ARMOR_VS_DRAGONS = '0A094821'	;'A0948210'
Local $STRUCT_INHERENT_ARMOR_VS_OGRES = '0A0A4821'

; +1^20%
Local $STRUCT_INHERENT_OF_ILLUSION_MAGIC = '14011824'
Local $STRUCT_INHERENT_OF_DOMINATION_MAGIC = '14021824'
Local $STRUCT_INHERENT_OF_INSPIRATION = '14031824'
Local $STRUCT_INHERENT_OF_BLOOD_MAGIC = '14041824'
Local $STRUCT_INHERENT_OF_DEATH_MAGIC = '14051824'
Local $STRUCT_INHERENT_OF_SOUL_REAPING = '14061824'
Local $STRUCT_INHERENT_OF_CURSE_MAGIC = '14071824'
Local $STRUCT_INHERENT_OF_AIR_MAGIC = '14081824'
Local $STRUCT_INHERENT_OF_EARTH_MAGIC = '14091824'
Local $STRUCT_INHERENT_OF_FIRE_MAGIC = '140A1824'
Local $STRUCT_INHERENT_OF_WATER_MAGIC = '140B1824'
Local $STRUCT_INHERENT_OF_HEALING_PRAYERS = '140D1824'
Local $STRUCT_INHERENT_OF_SMITING_PRAYERS = '140E1824'
Local $STRUCT_INHERENT_OF_PROTECTION_PRAYERS = '140F1824'
Local $STRUCT_INHERENT_OF_DIVINE_FAVOR = '14101824'
Local $STRUCT_INHERENT_OF_COMMUNING_MAGIC = '14201824'
Local $STRUCT_INHERENT_OF_RESTORATION_MAGIC = '14211824'
Local $STRUCT_INHERENT_OF_CHANNELING_MAGIC = '14221824'
Local $STRUCT_INHERENT_OF_SPAWNING_MAGIC = '14241824'
#EndRegion focus and shield OS
#EndRegion inherent bonus


#Region Runes
Global Const $ID_Warrior_Knights_Insignia =				'19152'
Global Const $ID_Warrior_Lieutenants_Insignia =			'19153'
Global Const $ID_Warrior_Stonefist_Insignia =			'19154'
Global Const $ID_Warrior_Dreadnought_Insignia =			'19155'
Global Const $ID_Warrior_Sentinels_Insignia =			'19156'
Global Const $ID_Warrior_Minor_Absorption =				'903'
Global Const $ID_Warrior_Minor_Axe_Mastery =			'903'
Global Const $ID_Warrior_Minor_Hammer_Mastery =			'903'
Global Const $ID_Warrior_Minor_Strength =				'903'
Global Const $ID_Warrior_Minor_Swordsmanship =			'903'
Global Const $ID_Warrior_Minor_Tactics =				'903'
Global Const $ID_Warrior_Major_Absorption =				'5558'
Global Const $ID_Warrior_Major_Axe_Mastery =			'5558'
Global Const $ID_Warrior_Major_Hammer_Mastery =			'5558'
Global Const $ID_Warrior_Major_Strength =				'5558'
Global Const $ID_Warrior_Major_Swordsmanship =			'5558'
Global Const $ID_Warrior_Major_Tactics =				'5558'
Global Const $ID_Warrior_Superior_Axe_Mastery =			'5559'
Global Const $ID_Warrior_Superior_Hammer_Mastery =		'5559'
Global Const $ID_Warrior_Superior_Strength =			'5559'
Global Const $ID_Warrior_Superior_Swordsmanship =		'5559'
Global Const $ID_Warrior_Superior_Tactics =				'5559'
Global Const $ID_Warrior_Superior_Absorption =			'5559'
Global Const $ID_Ranger_Frostbound_Insignia =			'19157'
Global Const $ID_Ranger_Pyrebound_Insignia =			'19159'
Global Const $ID_Ranger_Stormbound_Insignia =			'19160'
Global Const $ID_Ranger_Scouts_Insignia =				'19162'
Global Const $ID_Ranger_Earthbound_Insignia =			'19158'
Global Const $ID_Ranger_Beastmasters_Insignia =			'19161'
Global Const $ID_Ranger_Minor_Beast_Mastery =			'904'
Global Const $ID_Ranger_Minor_Expertise =				'904'
Global Const $ID_Ranger_Minor_Marksmanship =			'904'
Global Const $ID_Ranger_Minor_Wilderness_Survival =		'904'
Global Const $ID_Ranger_Major_Beast_Mastery =			'5560'
Global Const $ID_Ranger_Major_Expertise =				'5560'
Global Const $ID_Ranger_Major_Marksmanship =			'5560'
Global Const $ID_Ranger_Major_Wilderness_Survival =		'5560'
Global Const $ID_Ranger_Superior_Beast_Mastery =		'5561'
Global Const $ID_Ranger_Superior_Expertise =			'5561'
Global Const $ID_Ranger_Superior_Marksmanship =			'5561'
Global Const $ID_Ranger_Superior_Wilderness_Survival =	'5561'
Global Const $ID_Monk_Wanderers_Insignia =				'19149'
Global Const $ID_Monk_Disciples_Insignia =				'19150'
Global Const $ID_Monk_Anchorites_Insignia =				'19151'
Global Const $ID_Monk_Minor_Divine_Favor =				'902'
Global Const $ID_Monk_Minor_Healing_Prayers =			'902'
Global Const $ID_Monk_Minor_Protection_Prayers =		'902'
Global Const $ID_Monk_Minor_Smiting_Prayers =			'902'
Global Const $ID_Monk_Major_Healing_Prayers =			'5556'
Global Const $ID_Monk_Major_Protection_Prayers =		'5556'
Global Const $ID_Monk_Major_Smiting_Prayers =			'5556'
Global Const $ID_Monk_Major_Divine_Favor =				'5556'
Global Const $ID_Monk_Superior_Divine_Favor =			'5557'
Global Const $ID_Monk_Superior_Healing_Prayers =		'5557'
Global Const $ID_Monk_Superior_Protection_Prayers =		'5557'
Global Const $ID_Monk_Superior_Smiting_Prayers =		'5557'
Global Const $ID_Necromancer_Bloodstained_Insignia =	'19138'
Global Const $ID_Necromancer_Tormentors_Insignia =		'19139'
Global Const $ID_Necromancer_Bonelace_Insignia =		'19141'
Global Const $ID_Necromancer_Minion_Masters_Insignia =	'19142'
Global Const $ID_Necromancer_Blighters_Insignia =		'19143'
Global Const $ID_Necromancer_Undertakers_Insignia =		'19140'
Global Const $ID_Necromancer_Minor_Blood_Magic =		'900'
Global Const $ID_Necromancer_Minor_Curses =				'900'
Global Const $ID_Necromancer_Minor_Death_Magic =		'900'
Global Const $ID_Necromancer_Minor_Soul_Reaping =		'900'
Global Const $ID_Necromancer_Major_Blood_Magic =		'5552'
Global Const $ID_Necromancer_Major_Curses =				'5552'
Global Const $ID_Necromancer_Major_Death_Magic =		'5552'
Global Const $ID_Necromancer_Major_Soul_Reaping =		'5552'
Global Const $ID_Necromancer_Superior_Blood_Magic =		'5553'
Global Const $ID_Necromancer_Superior_Curses =			'5553'
Global Const $ID_Necromancer_Superior_Death_Magic =		'5553'
Global Const $ID_Necromancer_Superior_Soul_Reaping =	'5553'
Global Const $ID_Mesmer_Virtuosos_Insignia =			'19130'
Global Const $ID_Mesmer_Artificers_Insignia =			'19128'
Global Const $ID_Mesmer_Prodigys_Insignia =				'19129'
Global Const $ID_Mesmer_Minor_Domination_Magic =		'899'
Global Const $ID_Mesmer_Minor_Fast_Casting =			'899'
Global Const $ID_Mesmer_Minor_Illusion_Magic =			'899'
Global Const $ID_Mesmer_Minor_Inspiration_Magic =		'899'
Global Const $ID_Mesmer_Major_Domination_Magic =		'3612'
Global Const $ID_Mesmer_Major_Fast_Casting =			'3612'
Global Const $ID_Mesmer_Major_Illusion_Magic =			'3612'
Global Const $ID_Mesmer_Major_Inspiration_Magic =		'3612'
Global Const $ID_Mesmer_Superior_Domination_Magic =		'5549'
Global Const $ID_Mesmer_Superior_Fast_Casting =			'5549'
Global Const $ID_Mesmer_Superior_Illusion_Magic =		'5549'
Global Const $ID_Mesmer_Superior_Inspiration_Magic =	'5549'
Global Const $ID_Elementalist_Hydromancer_Insignia =	'19145'
Global Const $ID_Elementalist_Geomancer_Insignia =		'19146'
Global Const $ID_Elementalist_Pyromancer_Insignia =		'19147'
Global Const $ID_Elementalist_Aeromancer_Insignia =		'19148'
Global Const $ID_Elementalist_Prismatic_Insignia =		'19144'
Global Const $ID_Elementalist_Minor_Air_Magic =			'901'
Global Const $ID_Elementalist_Minor_Earth_Magic =		'901'
Global Const $ID_Elementalist_Minor_Energy_Storage =	'901'
Global Const $ID_Elementalist_Minor_Water_Magic =		'901'
Global Const $ID_Elementalist_Minor_Fire_Magic =		'901'
Global Const $ID_Elementalist_Major_Air_Magic =			'5554'
Global Const $ID_Elementalist_Major_Earth_Magic =		'5554'
Global Const $ID_Elementalist_Major_Energy_Storage =	'5554'
Global Const $ID_Elementalist_Major_Fire_Magic =		'5554'
Global Const $ID_Elementalist_Major_Water_Magic =		'5554'
Global Const $ID_Elementalist_Superior_Air_Magic =		'5555'
Global Const $ID_Elementalist_Superior_Earth_Magic =	'5555'
Global Const $ID_Elementalist_Superior_Energy_Storage =	'5555'
Global Const $ID_Elementalist_Superior_Fire_Magic =		'5555'
Global Const $ID_Elementalist_Superior_Water_Magic =	'5555'
Global Const $ID_Assassin_Vanguards_Insignia =			'19124'
Global Const $ID_Assassin_Infiltrators_Insignia =		'19125'
Global Const $ID_Assassin_Saboteurs_Insignia =			'19126'
Global Const $ID_Assassin_Nightstalkers_Insignia =		'19127'
Global Const $ID_Assassin_Minor_Critical_Strikes =		'6324'
Global Const $ID_Assassin_Minor_Dagger_Mastery =		'6324'
Global Const $ID_Assassin_Minor_Deadly_Arts =			'6324'
Global Const $ID_Assassin_Minor_Shadow_Arts =			'6324'
Global Const $ID_Assassin_Major_Critical_Strikes =		'6325'
Global Const $ID_Assassin_Major_Dagger_Mastery =		'6325'
Global Const $ID_Assassin_Major_Deadly_Arts =			'6325'
Global Const $ID_Assassin_Major_Shadow_Arts =			'6325'
Global Const $ID_Assassin_Superior_Critical_Strikes =	'6326'
Global Const $ID_Assassin_Superior_Dagger_Mastery =		'6326'
Global Const $ID_Assassin_Superior_Deadly_Arts =		'6326'
Global Const $ID_Assassin_Superior_Shadow_Arts =		'6326'
Global Const $ID_Ritualist_Shamans_Insignia =			'19165'
Global Const $ID_Ritualist_Ghost_Forge_Insignia =		'19166'
Global Const $ID_Ritualist_Mystics_Insignia =			'19167'
Global Const $ID_Ritualist_Minor_Channeling_Magic =		'6327'
Global Const $ID_Ritualist_Minor_Communing =			'6327'
Global Const $ID_Ritualist_Minor_Restoration_Magic =	'6327'
Global Const $ID_Ritualist_Minor_Spawning_Power =		'6327'
Global Const $ID_Ritualist_Major_Channeling_Magic =		'6328'
Global Const $ID_Ritualist_Major_Communing =			'6328'
Global Const $ID_Ritualist_Major_Restoration_Magic =	'6328'
Global Const $ID_Ritualist_Major_Spawning_Power =		'6328'
Global Const $ID_Ritualist_Superior_Channeling_Magic =	'6329'
Global Const $ID_Ritualist_Superior_Communing =			'6329'
Global Const $ID_Ritualist_Superior_Restoration_Magic =	'6329'
Global Const $ID_Ritualist_Superior_Spawning_Power =	'6329'
Global Const $ID_Dervish_Windwalker_Insignia =			'19163'
Global Const $ID_Dervish_Forsaken_Insignia =			'19164'
Global Const $ID_Dervish_Minor_Earth_Prayers =			'15545'
Global Const $ID_Dervish_Minor_Mysticism =				'15545'
Global Const $ID_Dervish_Minor_Scythe_Mastery =			'15545'
Global Const $ID_Dervish_Minor_Wind_Prayers =			'15545'
Global Const $ID_Dervish_Major_Earth_Prayers =			'15546'
Global Const $ID_Dervish_Major_Mysticism =				'15546'
Global Const $ID_Dervish_Major_Scythe_Mastery =			'15546'
Global Const $ID_Dervish_Major_Wind_Prayers =			'15546'
Global Const $ID_Dervish_Superior_Earth_Prayers =		'15547'
Global Const $ID_Dervish_Superior_Mysticism =			'15547'
Global Const $ID_Dervish_Superior_Scythe_Mastery =		'15547'
Global Const $ID_Dervish_Superior_Wind_Prayers =		'15547'
Global Const $ID_Paragon_Centurions_Insignia =			'19168'
Global Const $ID_Paragon_Minor_Command =				'15548'
Global Const $ID_Paragon_Minor_Leadership =				'15548'
Global Const $ID_Paragon_Minor_Motivation =				'15548'
Global Const $ID_Paragon_Minor_Spear_Mastery =			'15548'
Global Const $ID_Paragon_Major_Command =				'15549'
Global Const $ID_Paragon_Major_Leadership =				'15549'
Global Const $ID_Paragon_Major_Motivation =				'15549'
Global Const $ID_Paragon_Major_Spear_Mastery =			'15549'
Global Const $ID_Paragon_Superior_Command =				'15550'
Global Const $ID_Paragon_Superior_Leadership =			'15550'
Global Const $ID_Paragon_Superior_Motivation =			'15550'
Global Const $ID_Paragon_Superior_Spear_Mastery =		'15550'
Global Const $ID_Survivor_Insignia =					'19132'
Global Const $ID_Radiant_Insignia =						'19131'
Global Const $ID_Stalwart_Insignia =					'19133'
Global Const $ID_Brawlers_Insignia =					'19134'
Global Const $ID_Blessed_Insignia =						'19135'
Global Const $ID_Heralds_Insignia =						'19136'
Global Const $ID_Sentrys_Insignia =						'19137'
Global Const $ID_Rune_of_Minor_Vigor =					'898'
Global Const $ID_Rune_of_Vitae =						'898'
Global Const $ID_Rune_of_Attunement =					'898'
Global Const $ID_Rune_of_Major_Vigor =					'5550'
Global Const $ID_Rune_of_Recovery =						'5550'
Global Const $ID_Rune_of_Restoration =					'5550'
Global Const $ID_Rune_of_Clarity =						'5550'
Global Const $ID_Rune_of_Purity =						'5550'
Global Const $ID_Rune_of_Superior_Vigor =				'5551'


Global Const $Struct_Warrior_Knights_Insignia =				'F9010824'
Global Const $Struct_Warrior_Lieutenants_Insignia =			'08020824'
Global Const $Struct_Warrior_Stonefist_Insignia =			'09020824'
Global Const $Struct_Warrior_Dreadnought_Insignia =			'FA010824'
Global Const $Struct_Warrior_Sentinels_Insignia =			'FB010824'
Global Const $Struct_Warrior_Minor_Absorption =				'EA02E827'
Global Const $Struct_Warrior_Minor_Axe_Mastery =			'0112E821'
Global Const $Struct_Warrior_Minor_Hammer_Mastery =			'0113E821'
Global Const $Struct_Warrior_Minor_Strength =				'0111E821'
Global Const $Struct_Warrior_Minor_Swordsmanship =			'0114E821'
Global Const $Struct_Warrior_Minor_Tactics =				'0115E821'
Global Const $Struct_Warrior_Major_Absorption =				'EA02E927'
Global Const $Struct_Warrior_Major_Axe_Mastery =			'0212E8217301'
Global Const $Struct_Warrior_Major_Hammer_Mastery =			'0213E8217301'
Global Const $Struct_Warrior_Major_Strength =				'0211E8217301'
Global Const $Struct_Warrior_Major_Swordsmanship =			'0214E8217301'
Global Const $Struct_Warrior_Major_Tactics =				'0215E8217301'
Global Const $Struct_Warrior_Superior_Axe_Mastery =			'0312E8217F01'
Global Const $Struct_Warrior_Superior_Hammer_Mastery =		'0313E8217F01'
Global Const $Struct_Warrior_Superior_Strength =			'0311E8217F01'
Global Const $Struct_Warrior_Superior_Swordsmanship =		'0314E8217F01'
Global Const $Struct_Warrior_Superior_Tactics =				'0315E8217F01'
Global Const $Struct_Warrior_Superior_Absorption =			'EA02EA27'
Global Const $Struct_Ranger_Frostbound_Insignia =			'FC010824'
Global Const $Struct_Ranger_Pyrebound_Insignia =			'FE010824'
Global Const $Struct_Ranger_Stormbound_Insignia =			'FF010824'
Global Const $Struct_Ranger_Scouts_Insignia =				'01020824'
Global Const $Struct_Ranger_Earthbound_Insignia =			'FD010824'
Global Const $Struct_Ranger_Beastmasters_Insignia =			'00020824'
Global Const $Struct_Ranger_Minor_Beast_Mastery =			'0116E821'
Global Const $Struct_Ranger_Minor_Expertise =				'0117E821'
Global Const $Struct_Ranger_Minor_Marksmanship =			'0119E821'
Global Const $Struct_Ranger_Minor_Wilderness_Survival =		'0118E821'
Global Const $Struct_Ranger_Major_Beast_Mastery =			'0216E8217501'
Global Const $Struct_Ranger_Major_Expertise =				'0217E8217501'
Global Const $Struct_Ranger_Major_Marksmanship =			'0219E8217501'
Global Const $Struct_Ranger_Major_Wilderness_Survival =		'0218E8217501'
Global Const $Struct_Ranger_Superior_Beast_Mastery =		'0316E8218101'
Global Const $Struct_Ranger_Superior_Expertise =			'0317E8218101'
Global Const $Struct_Ranger_Superior_Marksmanship =			'0319E8218101'
Global Const $Struct_Ranger_Superior_Wilderness_Survival =	'0318E8218101'
Global Const $Struct_Monk_Wanderers_Insignia =				'F6010824'
Global Const $Struct_Monk_Disciples_Insignia =				'F7010824'
Global Const $Struct_Monk_Anchorites_Insignia =				'F8010824'
Global Const $Struct_Monk_Minor_Divine_Favor =				'0110E821'
Global Const $Struct_Monk_Minor_Healing_Prayers =			'010DE821'
Global Const $Struct_Monk_Minor_Protection_Prayers =		'010FE821'
Global Const $Struct_Monk_Minor_Smiting_Prayers =			'010EE821'
Global Const $Struct_Monk_Major_Healing_Prayers =			'020DE8217101'
Global Const $Struct_Monk_Major_Protection_Prayers =		'020FE8217101'
Global Const $Struct_Monk_Major_Smiting_Prayers =			'020EE8217101'
Global Const $Struct_Monk_Major_Divine_Favor =				'0210E8217101'
Global Const $Struct_Monk_Superior_Divine_Favor =			'0310E8217D01'
Global Const $Struct_Monk_Superior_Healing_Prayers =		'030DE8217D01'
Global Const $Struct_Monk_Superior_Protection_Prayers =		'030FE8217D01'
Global Const $Struct_Monk_Superior_Smiting_Prayers =		'030EE8217D01'
Global Const $Struct_Necromancer_Bloodstained_Insignia =	'0A020824'
Global Const $Struct_Necromancer_Tormentors_Insignia =		'EC010824'
Global Const $Struct_Necromancer_Bonelace_Insignia =		'EE010824'
Global Const $Struct_Necromancer_Minion_Masters_Insignia =	'EF010824'
Global Const $Struct_Necromancer_Blighters_Insignia =		'F0010824'
Global Const $Struct_Necromancer_Undertakers_Insignia =		'ED010824'
Global Const $Struct_Necromancer_Minor_Blood_Magic =		'0104E821'
Global Const $Struct_Necromancer_Minor_Curses =				'0107E821'
Global Const $Struct_Necromancer_Minor_Death_Magic =		'0105E821'
Global Const $Struct_Necromancer_Minor_Soul_Reaping =		'0106E821'
Global Const $Struct_Necromancer_Major_Blood_Magic =		'0204E8216D01'
Global Const $Struct_Necromancer_Major_Curses =				'0207E8216D01'
Global Const $Struct_Necromancer_Major_Death_Magic =		'0205E8216D01'
Global Const $Struct_Necromancer_Major_Soul_Reaping =		'0206E8216D01'
Global Const $Struct_Necromancer_Superior_Blood_Magic =		'0304E8217901'
Global Const $Struct_Necromancer_Superior_Curses =			'0307E8217901'
Global Const $Struct_Necromancer_Superior_Death_Magic =		'0305E8217901'
Global Const $Struct_Necromancer_Superior_Soul_Reaping =	'0306E8217901'
Global Const $Struct_Mesmer_Virtuosos_Insignia =			'E4010824'
Global Const $Struct_Mesmer_Artificers_Insignia =			'E2010824'
Global Const $Struct_Mesmer_Prodigys_Insignia =				'E3010824'
Global Const $Struct_Mesmer_Minor_Domination_Magic =		'0102E821'
Global Const $Struct_Mesmer_Minor_Fast_Casting =			'0100E821'
Global Const $Struct_Mesmer_Minor_Illusion_Magic =			'0101E821'
Global Const $Struct_Mesmer_Minor_Inspiration_Magic =		'0103E821'
Global Const $Struct_Mesmer_Major_Domination_Magic =		'0202E8216B01'
Global Const $Struct_Mesmer_Major_Fast_Casting =			'0200E8216B01'
Global Const $Struct_Mesmer_Major_Illusion_Magic =			'0201E8216B01'
Global Const $Struct_Mesmer_Major_Inspiration_Magic =		'0203E8216B01'
Global Const $Struct_Mesmer_Superior_Domination_Magic =		'0302E8217701'
Global Const $Struct_Mesmer_Superior_Fast_Casting =			'0300E8217701'
Global Const $Struct_Mesmer_Superior_Illusion_Magic =		'0301E8217701'
Global Const $Struct_Mesmer_Superior_Inspiration_Magic =	'0303E8217701'
Global Const $Struct_Elementalist_Hydromancer_Insignia =	'F2010824'
Global Const $Struct_Elementalist_Geomancer_Insignia =		'F3010824'
Global Const $Struct_Elementalist_Pyromancer_Insignia =		'F4010824'
Global Const $Struct_Elementalist_Aeromancer_Insignia =		'F5010824'
Global Const $Struct_Elementalist_Prismatic_Insignia =		'F1010824'
Global Const $Struct_Elementalist_Minor_Air_Magic =			'0108E821'
Global Const $Struct_Elementalist_Minor_Earth_Magic =		'0109E821'
Global Const $Struct_Elementalist_Minor_Energy_Storage =	'010CE821'
Global Const $Struct_Elementalist_Minor_Water_Magic =		'010BE821'
Global Const $Struct_Elementalist_Minor_Fire_Magic =		'010AE821'
Global Const $Struct_Elementalist_Major_Air_Magic =			'0208E8216F01'
Global Const $Struct_Elementalist_Major_Earth_Magic =		'0209E8216F01'
Global Const $Struct_Elementalist_Major_Energy_Storage =	'020CE8216F01'
Global Const $Struct_Elementalist_Major_Fire_Magic =		'020AE8216F01'
Global Const $Struct_Elementalist_Major_Water_Magic =		'020BE8216F01'
Global Const $Struct_Elementalist_Superior_Air_Magic =		'0308E8217B01'
Global Const $Struct_Elementalist_Superior_Earth_Magic =	'0309E8217B01'
Global Const $Struct_Elementalist_Superior_Energy_Storage =	'030CE8217B01'
Global Const $Struct_Elementalist_Superior_Fire_Magic =		'030AE8217B01'
Global Const $Struct_Elementalist_Superior_Water_Magic =	'030BE8217B01'
Global Const $Struct_Assassin_Vanguards_Insignia =			'DE010824'
Global Const $Struct_Assassin_Infiltrators_Insignia =		'DF010824'
Global Const $Struct_Assassin_Saboteurs_Insignia =			'E0010824'
Global Const $Struct_Assassin_Nightstalkers_Insignia =		'E1010824'
Global Const $Struct_Assassin_Minor_Critical_Strikes =		'0123E821'
Global Const $Struct_Assassin_Minor_Dagger_Mastery =		'011DE821'
Global Const $Struct_Assassin_Minor_Deadly_Arts =			'011EE821'
Global Const $Struct_Assassin_Minor_Shadow_Arts =			'011FE821'
Global Const $Struct_Assassin_Major_Critical_Strikes =		'0223E8217902'
Global Const $Struct_Assassin_Major_Dagger_Mastery =		'021DE8217902'
Global Const $Struct_Assassin_Major_Deadly_Arts =			'021EE8217902'
Global Const $Struct_Assassin_Major_Shadow_Arts =			'021FE8217902'
Global Const $Struct_Assassin_Superior_Critical_Strikes =	'0323E8217B02'
Global Const $Struct_Assassin_Superior_Dagger_Mastery =		'031DE8217B02'
Global Const $Struct_Assassin_Superior_Deadly_Arts =		'031EE8217B02'
Global Const $Struct_Assassin_Superior_Shadow_Arts =		'031FE8217B02'
Global Const $Struct_Ritualist_Shamans_Insignia =			'04020824'
Global Const $Struct_Ritualist_Ghost_Forge_Insignia =		'05020824'
Global Const $Struct_Ritualist_Mystics_Insignia =			'06020824'
Global Const $Struct_Ritualist_Minor_Channeling_Magic =		'0122E821'
Global Const $Struct_Ritualist_Minor_Communing =			'0120E821'
Global Const $Struct_Ritualist_Minor_Restoration_Magic =	'0121E821'
Global Const $Struct_Ritualist_Minor_Spawning_Power =		'0124E821'
Global Const $Struct_Ritualist_Major_Channeling_Magic =		'0222E8217F02'
Global Const $Struct_Ritualist_Major_Communing =			'0220E8217F02'
Global Const $Struct_Ritualist_Major_Restoration_Magic =	'0221E8217F02'
Global Const $Struct_Ritualist_Major_Spawning_Power =		'0224E8217F02'
Global Const $Struct_Ritualist_Superior_Channeling_Magic =	'0322E8218102'
Global Const $Struct_Ritualist_Superior_Communing =			'0320E8218102'
Global Const $Struct_Ritualist_Superior_Restoration_Magic =	'0321E8218102'
Global Const $Struct_Ritualist_Superior_Spawning_Power =	'0324E8218102'
Global Const $Struct_Dervish_Windwalker_Insignia =			'02020824'
Global Const $Struct_Dervish_Forsaken_Insignia =			'03020824'
Global Const $Struct_Dervish_Minor_Earth_Prayers =			'012BE821'
Global Const $Struct_Dervish_Minor_Mysticism =				'012CE821'
Global Const $Struct_Dervish_Minor_Scythe_Mastery =			'0129E821'
Global Const $Struct_Dervish_Minor_Wind_Prayers =			'012AE821'
Global Const $Struct_Dervish_Major_Earth_Prayers =			'022BE8210703'
Global Const $Struct_Dervish_Major_Mysticism =				'022CE8210703'
Global Const $Struct_Dervish_Major_Scythe_Mastery =			'0229E8210703'
Global Const $Struct_Dervish_Major_Wind_Prayers =			'022AE8210703'
Global Const $Struct_Dervish_Superior_Earth_Prayers =		'032BE8210903'
Global Const $Struct_Dervish_Superior_Mysticism =			'032CE8210903'
Global Const $Struct_Dervish_Superior_Scythe_Mastery =		'0329E8210903'
Global Const $Struct_Dervish_Superior_Wind_Prayers =		'032AE8210903'
Global Const $Struct_Paragon_Centurions_Insignia =			'07020824'
Global Const $Struct_Paragon_Minor_Command =				'0126E821'
Global Const $Struct_Paragon_Minor_Leadership =				'0128E821'
Global Const $Struct_Paragon_Minor_Motivation =				'0127E821'
Global Const $Struct_Paragon_Minor_Spear_Mastery =			'0125E821'
Global Const $Struct_Paragon_Major_Command =				'0226E8210D03'
Global Const $Struct_Paragon_Major_Leadership =				'0228E8210D03'
Global Const $Struct_Paragon_Major_Motivation =				'0227E8210D03'
Global Const $Struct_Paragon_Major_Spear_Mastery =			'0225E8210D03'
Global Const $Struct_Paragon_Superior_Command =				'0326E8210F03'
Global Const $Struct_Paragon_Superior_Leadership =			'0328E8210F03'
Global Const $Struct_Paragon_Superior_Motivation =			'0327E8210F03'
Global Const $Struct_Paragon_Superior_Spear_Mastery =		'0325E8210F03'
Global Const $Struct_Survivor_Insignia =					'E6010824'
Global Const $Struct_Radiant_Insignia =						'E5010824'
Global Const $Struct_Stalwart_Insignia =					'E7010824'
Global Const $Struct_Brawlers_Insignia =					'E8010824'
Global Const $Struct_Blessed_Insignia =						'E9010824'
Global Const $Struct_Heralds_Insignia =						'EA010824'
Global Const $Struct_Sentrys_Insignia =						'EB010824'
Global Const $Struct_Rune_of_Minor_Vigor =					'C202E827'
Global Const $Struct_Rune_of_Vitae =						'000A4823'
Global Const $Struct_Rune_of_Attunement =					'0200D822'
Global Const $Struct_Rune_of_Major_Vigor =					'C202E927'
Global Const $Struct_Rune_of_Recovery =						'07047827'
Global Const $Struct_Rune_of_Restoration =					'00037827'
Global Const $Struct_Rune_of_Clarity =						'01087827'
Global Const $Struct_Rune_of_Purity =						'05067827'
Global Const $Struct_Rune_of_Superior_Vigor =				'C202EA27'
#EndRegion Runes


#Region Struct Utils
; Insignias are present at index 0 of their armor salvageable item
; Runes are present at index 1 of their armor salvageable item
Local Const $Valuable_Rune_And_Insignia_Structs_Array[] = [ _
	$Struct_Warrior_Sentinels_Insignia, _
	$Struct_Ranger_Beastmasters_Insignia, _
	$Struct_Monk_Anchorites_Insignia, _				;Not that valuable, but I need those
	$Struct_Monk_Minor_Divine_Favor, _
	$Struct_Necromancer_Bloodstained_Insignia, _
	$Struct_Necromancer_Tormentors_Insignia, _
	$Struct_Necromancer_Minor_Soul_Reaping, _
	$Struct_Necromancer_Major_Soul_Reaping, _
	$Struct_Necromancer_Superior_Death_Magic, _
	$Struct_Mesmer_Prodigys_Insignia, _
	$Struct_Mesmer_Minor_Fast_Casting, _
	$Struct_Mesmer_Minor_Inspiration_Magic, _
	$Struct_Mesmer_Major_Fast_Casting, _
	$Struct_Mesmer_Major_Domination_Magic, _
	$Struct_Mesmer_Superior_Domination_Magic, _
	$Struct_Mesmer_Superior_Illusion_Magic, _
	$Struct_Elementalist_Minor_Energy_Storage, _
	$Struct_Assassin_Nightstalkers_Insignia, _
	$Struct_Assassin_Minor_Critical_Strikes, _
	$Struct_Ritualist_Shamans_Insignia, _
	$Struct_Ritualist_Minor_Spawning_Power, _
	$Struct_Ritualist_Superior_Communing, _
	$Struct_Ritualist_Superior_Spawning_Power, _
	$Struct_Dervish_Windwalker_Insignia, _
	$Struct_Dervish_Minor_Mysticism, _
	$Struct_Dervish_Minor_Scythe_Mastery, _
	$Struct_Dervish_Superior_Earth_Prayers, _
	$Struct_Paragon_Centurions_Insignia, _
	$Struct_Survivor_Insignia, _
	$Struct_Brawlers_Insignia, _
	$Struct_Blessed_Insignia, _
	$Struct_Rune_of_Vitae, _
	$Struct_Rune_of_Clarity, _
	$Struct_Rune_of_Minor_Vigor, _
	$Struct_Rune_of_Major_Vigor, _
	$Struct_Rune_of_Superior_Vigor _
]

Local Const $Common_Valuable_Mods[] = [$STRUCT_INSCRIPTION_MEASURE_FOR_MEASURE]
Local $ValuableModsByType = CreateValuableModsByTypeMap()

;~ Dirty way to do it because AutoIt sucks with maps and arrays
Func CreateValuableModsByTypeMap()
	Local $map[]
	; Redefined here so that no include to GWA2_ID is required
	Local $ID_Type_Axe				= 2
	Local $ID_Type_Bow				= 5
	Local $ID_Type_Offhand			= 12
	Local $ID_Type_Hammer			= 15
	Local $ID_Type_Wand				= 22
	Local $ID_Type_Shield			= 24
	Local $ID_Type_Staff			= 26
	Local $ID_Type_Sword			= 27
	Local $ID_Type_Dagger			= 32
	Local $ID_Type_Scythe			= 35
	Local $ID_Type_Spear			= 36

	; Shield
	Local $Shield_Mods_Array = [ _
		$STRUCT_INHERENT_ARMOR_VS_UNDEAD, $STRUCT_INHERENT_ARMOR_VS_CHARR, $STRUCT_INHERENT_ARMOR_VS_TROLLS, $STRUCT_INHERENT_ARMOR_VS_PLANTS, _
		$STRUCT_INHERENT_ARMOR_VS_SKELETONS, $STRUCT_INHERENT_ARMOR_VS_GIANTS, $STRUCT_INHERENT_ARMOR_VS_DWARVES, $STRUCT_INHERENT_ARMOR_VS_TENGU, _
		$STRUCT_INHERENT_ARMOR_VS_DEMONS, $STRUCT_INHERENT_ARMOR_VS_DRAGONS, $STRUCT_INHERENT_ARMOR_VS_OGRES, _
		$STRUCT_INHERENT_OF_ILLUSION_MAGIC, $STRUCT_INHERENT_OF_DOMINATION_MAGIC, $STRUCT_INHERENT_OF_INSPIRATION, $STRUCT_INHERENT_OF_BLOOD_MAGIC, _
		$STRUCT_INHERENT_OF_DEATH_MAGIC, $STRUCT_INHERENT_OF_SOUL_REAPING, $STRUCT_INHERENT_OF_CURSE_MAGIC, $STRUCT_INHERENT_OF_AIR_MAGIC, _
		$STRUCT_INHERENT_OF_EARTH_MAGIC, $STRUCT_INHERENT_OF_FIRE_MAGIC, $STRUCT_INHERENT_OF_WATER_MAGIC, $STRUCT_INHERENT_OF_HEALING_PRAYERS, _
		$STRUCT_INHERENT_OF_SMITING_PRAYERS, $STRUCT_INHERENT_OF_PROTECTION_PRAYERS, $STRUCT_INHERENT_OF_DIVINE_FAVOR, $STRUCT_INHERENT_OF_COMMUNING_MAGIC, _
		$STRUCT_INHERENT_OF_RESTORATION_MAGIC, $STRUCT_INHERENT_OF_CHANNELING_MAGIC, $STRUCT_INHERENT_OF_SPAWNING_MAGIC _
	]
	$map[$ID_Type_Shield] = $Shield_Mods_Array
	; Caster
	Local $Offhand_Mods_Array = [ _
		$STRUCT_INHERENT_ARMOR_VS_UNDEAD, $STRUCT_INHERENT_ARMOR_VS_CHARR, $STRUCT_INHERENT_ARMOR_VS_TROLLS, $STRUCT_INHERENT_ARMOR_VS_PLANTS, $STRUCT_INHERENT_ARMOR_VS_SKELETONS, $STRUCT_INHERENT_ARMOR_VS_GIANTS, _
		$STRUCT_INHERENT_ARMOR_VS_DWARVES, $STRUCT_INHERENT_ARMOR_VS_TENGU, $STRUCT_INHERENT_ARMOR_VS_DEMONS, $STRUCT_INHERENT_ARMOR_VS_DRAGONS, $STRUCT_INHERENT_ARMOR_VS_OGRES, _
		$STRUCT_INHERENT_OF_ILLUSION_MAGIC, $STRUCT_INHERENT_OF_DOMINATION_MAGIC, $STRUCT_INHERENT_OF_INSPIRATION, $STRUCT_INHERENT_OF_BLOOD_MAGIC, $STRUCT_INHERENT_OF_DEATH_MAGIC, $STRUCT_INHERENT_OF_SOUL_REAPING, $STRUCT_INHERENT_OF_CURSE_MAGIC, _
		$STRUCT_INHERENT_OF_AIR_MAGIC, $STRUCT_INHERENT_OF_EARTH_MAGIC, $STRUCT_INHERENT_OF_FIRE_MAGIC, $STRUCT_INHERENT_OF_WATER_MAGIC, $STRUCT_INHERENT_OF_HEALING_PRAYERS, $STRUCT_INHERENT_OF_SMITING_PRAYERS, $STRUCT_INHERENT_OF_PROTECTION_PRAYERS, _
		$STRUCT_INHERENT_OF_DIVINE_FAVOR, $STRUCT_INHERENT_OF_COMMUNING_MAGIC, $STRUCT_INHERENT_OF_RESTORATION_MAGIC, $STRUCT_INHERENT_OF_CHANNELING_MAGIC, $STRUCT_INHERENT_OF_SPAWNING_MAGIC, _
		$STRUCT_INSCRIPTION_FORGET_ME_NOT, $STRUCT_MOD_HCT_20, $STRUCT_MOD_HSR_20 _
	]
	$map[$ID_Type_Offhand] = $Offhand_Mods_Array
	Local $Wand_Mods_Array = [ _
		$STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE, $STRUCT_MOD_HCT_20, $STRUCT_MOD_HSR_20, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_MESMER, $STRUCT_MOD_OF_THE_MONK, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Wand] = $Wand_Mods_Array
	Local $Staff_Mods_Array = [ _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING, _
		$STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE, $STRUCT_MOD_OF_ENCHANTING, $STRUCT_MOD_HCT_20, $STRUCT_MOD_HSR_20, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_MESMER, $STRUCT_MOD_OF_THE_MONK, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Staff] = $Staff_Mods_Array
	; Ranged
	Local $Bow_Mods_Array = [ _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Bow] = $Bow_Mods_Array
	; Melee
	Local $Axe_Mods_Array = [ _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Axe] = $Axe_Mods_Array
	Local $Hammer_Mods_Array = [ _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Hammer] = $Hammer_Mods_Array
	Local $Sword_Mods_Array = [ _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Sword] = $Sword_Mods_Array
	Local $Dagger_Mods_Array = [ _
		$STRUCT_MOD_ZEALOUS_PREFIX, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Dagger] = $Dagger_Mods_Array
	Local $Scythe_Mods_Array = [ _
		$STRUCT_MOD_ZEALOUS_PREFIX, $STRUCT_MOD_OF_ENCHANTING, $STRUCT_MOD_SUNDERING_PREFIX, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Scythe] = $Scythe_Mods_Array
	Local $Spear_Mods_Array = [ _
		$STRUCT_MOD_OF_ENCHANTING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_ELEMENTALIST, $STRUCT_MOD_OF_THE_WARRIOR, $STRUCT_MOD_OF_THE_RANGER, $STRUCT_MOD_OF_THE_RITUALIST, $STRUCT_MOD_OF_THE_ASSASSIN, $STRUCT_MOD_OF_THE_DERVISH _
	]
	$map[$ID_Type_Spear] = $Spear_Mods_Array
	Return $map
EndFunc

#EndRegion Struct Utils