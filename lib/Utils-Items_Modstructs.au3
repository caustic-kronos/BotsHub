#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Underavelvetmoon, Gahais
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

;~ Determines whether the provided item has expensive mods
Func ContainsValuableUpgrades($item)
	Local $modStruct	= GetModStruct($item)
	If Not $modStruct Then Return False

	If IsWeapon($item) Then
		Local $itemType	= DllStructGetData($item, 'type')
		If IsInscribable($item) Then
			For $struct In $ValuableModsByWeaponType[$itemType]
				If StringInStr($modStruct, $struct) > 0 Then Return True
			Next
			For $struct In $ValuableInscriptionsArray
				If StringInStr($modStruct, $struct) > 0 Then Return True
			Next
		Else
			For $struct In $ValuableModsByOSWeaponType[$itemType]
				If StringInStr($modStruct, $struct) > 0 Then Return True
			Next
		EndIf

	ElseIf IsArmorSalvageItem($item) Then
		For $struct In $ValuableRunesAndInsigniasStructsArray
			If StringInStr($modStruct, $struct) > 0 Then Return True
		Next
	EndIf
	Return False
EndFunc


;~ Determines whether the provided OS (Old School) item has perfect mods
Func HasPerfectMods($item)
	Local $itemType	= DllStructGetData($item, 'type')
	Local $modstruct	= GetModStruct($item)
	Local $typeMods	= $PerfectModsByWeaponType[$itemType]
	Switch $itemType
		; For martial weapons, only 1 inherent mod and the weapon is perfect
		Case $ID_Type_Axe, $ID_Type_Bow, $ID_Type_Hammer, $ID_Type_Sword, $ID_Type_Dagger
			For $struct In $typeMods
				If StringInStr($ModStruct, $struct) > 0 Then
					; If the mod found is vampiric or zealous strength, we need to check we are not mixing it with vampiric or zealous mod
					If $struct	== $STRUCT_INHERENT_ZEALOUS_STRENGTH Then
						If StringInStr($ModStruct, $STRUCT_MOD_ZEALOUS) Then ContinueLoop
					EndIf
					If $struct	== $STRUCT_INHERENT_VAMPIRIC_STRENGTH Then
						If StringInStr($ModStruct, $STRUCT_MOD_VAMPIRIC_3) Or StringInStr($ModStruct, $STRUCT_MOD_VAMPIRIC_5) Then ContinueLoop
					EndIf
					Return True
				EndIf
			Next
			Return False
		; For staff, only 1 inherent mod as well, but no risk of zealous/vampiric
		Case $ID_Type_Staff
			For $struct In $typeMods
				If StringInStr($ModStruct, $struct) > 0 Then Return True
			Next
			Return False
		; For wand, offhand and shield, there are 2 inherent mods, we need to check twice
		Case $ID_Type_Wand, $ID_Type_Offhand, $ID_Type_Shield
			Local $count	= 0
			For $struct In $typeMods
				If StringInStr($ModStruct, $struct) > 0 Then $count += 1
			Next
			Return $count > 1
		; For scythe and spear, if you are checking this, something is wrong, there are no OS scythe or spear. Congratulations.
		Case $ID_Type_Scythe, $ID_Type_Spear
			Return True
	EndSwitch
	Return False
EndFunc


;~ Too lazy to implement this today
Func HasAlmostPerfectMods($item)
	Return HasPerfectMods($item)
EndFunc


;~ Too lazy to implement this today
Func HasOkayMods($item)
	Return HasPerfectMods($item)
EndFunc


Global $STRUCT_MINUS_5_ENERGY	= '0500B820'
Global $STRUCT_15_ENERGY	= '0F00D822'
Global $STRUCT_ENERGY_REGENERATION	= '0100C820'


#Region Weapon Mods
Global Const $ID_Staff_Head								= 896
Global Const $ID_Staff_Wrapping							= 908
Global Const $ID_Shield_Handle							= 15554
Global Const $ID_Focus_Core								= 15551
Global Const $ID_Wand									= 15552
Global Const $ID_Bow_String								= 894
Global Const $ID_Bow_Grip								= 906
Global Const $ID_Sword_Hilt								= 897
Global Const $ID_Sword_Pommel							= 909
Global Const $ID_Axe_Haft								= 893
Global Const $ID_Axe_Grip								= 905
Global Const $ID_Dagger_Tang							= 6323
Global Const $ID_Dagger_Handle							= 6331
Global Const $ID_Hammer_Haft							= 895
Global Const $ID_Hammer_Grip							= 907
Global Const $ID_Scythe_Snathe							= 15543
Global Const $ID_Scythe_Grip							= 15553
Global Const $ID_Spearhead								= 15544
Global Const $ID_Spear_Grip								= 15555
Global Const $ID_Inscriptions_Martial					= 15540
Global Const $ID_Inscriptions_Offhand					= 15541
Global Const $ID_Inscriptions_All						= 15542
Global Const $ID_Inscriptions_General					= 17059
Global Const $ID_Inscriptions_Spellcasting				= 19122
Global Const $ID_Inscriptions_Focus						= 19123
Global Const $Weapon_Mods_Array[]						= [$ID_Axe_Haft, $ID_Bow_String, $ID_Hammer_Haft, $ID_Staff_Head, $ID_Sword_Hilt, $ID_Axe_Grip, $ID_Bow_Grip, $ID_Hammer_Grip, _
															$ID_Staff_Wrapping, $ID_Sword_Pommel, $ID_Dagger_Tang, $ID_Dagger_Handle, $ID_Inscriptions_Martial, _
															$ID_Inscriptions_Offhand, $ID_Inscriptions_All, $ID_Scythe_Snathe, $ID_Spearhead, $ID_Focus_Core, $ID_Wand, _
															$ID_Scythe_Grip, $ID_Shield_Handle, $ID_Spear_Grip, $ID_Inscriptions_General, $ID_Inscriptions_Spellcasting, _
															$ID_Inscriptions_Focus]
Global Const $Map_Weapon_Mods							= MapFromArray($Weapon_Mods_Array)
#EndRegion Weapon Mods


#Region Weapon Inscriptions
#Region Common Inscriptions
Global $STRUCT_INSCRIPTION_MEASURE_FOR_MEASURE			= '1F0208243E0432251'			;salvageable
Global $STRUCT_INSCRIPTION_SHOW_ME_THE_MONEY			= '1E0208243C043225'			;rare/money

Global $STRUCT_INSCRIPTION_STRENGTH_AND_HONOR			= '0F327822'					;+15% while health > 50%
Global $STRUCT_INSCRIPTION_GUIDED_BY_FATE				= '0F006822'					;+15% while enchanted
Global $STRUCT_INSCRIPTION_DANCE_WITH_DEATH				= '0F00A822'					;+15% while in a stance
Global $STRUCT_INSCRIPTION_TOO_MUCH_INFORMATION			= '0F005822'					;+15% against hexed foes
Global $STRUCT_INSCRIPTION_TO_THE_PAIN					= '0A001820'					;+15% damage -10 armor while attacking - -10 armor part
;Global $STRUCT_INSCRIPTION_TO_THE_PAIN_2				= '0F003822'					;+15% damage -10 armor while attacking - +15% damage part
Global $STRUCT_INSCRIPTION_BRAWN_OVER_BRAIN				= $STRUCT_MINUS_5_ENERGY		;+15% damage -5 energy - -5 energy part
;Global $STRUCT_INSCRIPTION_BRAWN_OVER_BRAIN_2			= '0F003822'					;+15% damage -5 energy - +15% damage part
Global $STRUCT_INSCRIPTION_VENGEANCE_IS_MINE			= '14328822'					;+20% while health < 50%
Global $STRUCT_INSCRIPTION_DONT_FEAR_THE_REAPER			= '14009822'					;+20% while hexed
Global $STRUCT_INSCRIPTION_DONT_THINK_TWICE				= '000A0822'					;hct 10
#EndRegion Common Inscriptions

#Region Martial Inscriptions
Global $STRUCT_INSCRIPTION_I_HAVE_THE_POWER				= '0500D822'					;+5e
Global $STRUCT_INSCRIPTION_LET_THE_MEMORY_LIVE_AGAIN	= '000AA823'					;hsr 10
#EndRegion Martial Inscriptions

#Region Caster Weapon Inscriptions
Global $STRUCT_INSCRIPTION_HALE_AND_HEARTY				= '05320823'					;+5e while health > 50%
Global $STRUCT_INSCRIPTION_HAVE_FAITH					= '0500F822'					;+5e while enchanted
Global $STRUCT_INSCRIPTION_DONT_CALL_IT_A_COME_BACK		= '07321823'					;+7e while health < 50%
Global $STRUCT_INSCRIPTION_I_AM_SORROW					= '07002823'					;+7e while hexed
Global $STRUCT_INSCRIPTION_SEIZE_THE_DAY_1				= $STRUCT_15_ENERGY				;+15e energy regeneration -1 - +15e part
Global $STRUCT_INSCRIPTION_SEIZE_THE_DAY_2				= $STRUCT_ENERGY_REGENERATION	;+15e energy regeneration -1 - energy regeneration -1 part
Global $STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE		= '00140828'					;hct 20
#EndRegion Caster Weapon Inscriptions
#EndRegion Weapon Inscriptions

#Region Offhand Inscriptions
#Region Focus Inscriptions
Global $STRUCT_INSCRIPTION_FORGET_ME_NOT				= '00142828'					;hsr 20
Global $STRUCT_INSCRIPTION_SERENITY_NOW					= '000AA823'					;hsr 10

Global $STRUCT_INSCRIPTION_HAIL_TO_THE_KING				= '0532A821'					;+5 armor while health > 50%
Global $STRUCT_INSCRIPTION_FAITH_IS_MY_SHIELD			= '05009821'					;+5 armor while enchanted
Global $STRUCT_INSCRIPTION_MIGHT_MAKES_RIGHT			= '05007821'					;+5 armor while attacking
Global $STRUCT_INSCRIPTION_KNOWING_IS_HALF_THE_BATTLE	= '05008821'					;+5 armor while casting
Global $STRUCT_INSCRIPTION_MAN_FOR_ALL_SEASONS			= '05002821'					;+5 armor vs elemental damage
Global $STRUCT_INSCRIPTION_SURVIVAL_OF_THE_FITTEST		= '05005821'					;+5 armor vs physical damage
Global $STRUCT_INSCRIPTION_IGNORANCE_IS_BLISS_1			= '05000821'					;+5 armor ^ -5 energy - +5 armor part
Global $STRUCT_INSCRIPTION_IGNORANCE_IS_BLISS_2			= $STRUCT_MINUS_5_ENERGY		;+5 armor ^ -5 energy - -5 energy part
Global $STRUCT_INSCRIPTION_LIFE_IS_PAIN					= '1400D820'					;+5 armor ^ -20 health - -20 health part
;Global $STRUCT_INSCRIPTION_LIFE_IS_PAIN_2				= '05000821'					;+5 armor ^ -20 health - +5 armor part
Global $STRUCT_INSCRIPTION_DOWN_BUT_NOT_OUT				= '0A32B821'					;+10 armor while health < 50%
Global $STRUCT_INSCRIPTION_BE_JUST_AND_FEAR_NOT			= '0A00C821'					;+10 armor while hexed
Global $STRUCT_INSCRIPTION_LIVE_FOR_TODAY_1				= $STRUCT_15_ENERGY				;+15 energy ^ -1 energy regeneration - +15 energy part
Global $STRUCT_INSCRIPTION_LIVE_FOR_TODAY_2				= $STRUCT_ENERGY_REGENERATION	;+15 energy ^ -1 energy regeneration - energy regeneration -1 part
#EndRegion Focus Inscriptions

#Region Focus and Shield Inscriptions
Global $STRUCT_INSCRIPTION_MASTER_OF_MY_DOMAIN			= '00143828'					;+1^20% item attribute

Global $STRUCT_INSCRIPTION_NOT_THE_FACE					= '0A0018A1'					;+10 armor vs blunt
Global $STRUCT_INSCRIPTION_LEAF_ON_THE_WIND				= '0A0318A1'					;+10 armor vs cold
Global $STRUCT_INSCRIPTION_LIKE_A_ROLLING_STONE			= '0A0B18A1'					;+10 armor vs earth
Global $STRUCT_INSCRIPTION_SLEEP_NOW_IN_THE_FIRE		= '0A0518A1'					;+10 armor vs fire
Global $STRUCT_INSCRIPTION_RIDERS_ON_THE_STORM			= '0A0418A1'					;+10 armor vs lightning
Global $STRUCT_INSCRIPTION_THROUGH_THICK_AND_THIN		= '0A0118A1'					;+10 armor vs piercing
Global $STRUCT_INSCRIPTION_THE_RIDDLE_OF_STEEL			= '0A0218A1'					;+10 armor vs slashing

Global $STRUCT_INSCRIPTION_SHELTERED_BY_FAITH			= '02008820'					;-2 physical damage while enchanted
Global $STRUCT_INSCRIPTION_RUN_FOR_YOUR_LIFE			= '0200A820'					;-2 physical damage while in a stance
Global $STRUCT_INSCRIPTION_NOTHING_TO_FEAR				= '03009820'					;-3 physical damage while hexed
Global $STRUCT_INSCRIPTION_LUCK_OF_THE_DRAW				= '05147820'					;-5 physical damage ^ 20%

Global $STRUCT_INSCRIPTION_FEAR_CUTS_DEEPER				= '00005828'					;-20 bleeding duration
Global $STRUCT_INSCRIPTION_I_CAN_SEE_CLEARLY_NOW		= '00015828'					;-20 blind duration
Global $STRUCT_INSCRIPTION_SWIFT_AS_THE_WIND			= '00035828'					;-20 crippled duration
Global $STRUCT_INSCRIPTION_SOUNDNESS_OF_MIND			= '00075828'					;-20 dazed duration
Global $STRUCT_INSCRIPTION_STRENGTH_OF_BODY				= '00045828'					;-20 deep wound duration
Global $STRUCT_INSCRIPTION_CAST_OUT_THE_UNCLEAN			= '00055828'					;-20 disease duration
Global $STRUCT_INSCRIPTION_CAST_OUT_THE_UNCLEAN_OS		= 'E3017824'					;-20 disease duration
Global $STRUCT_INSCRIPTION_PURE_OF_HEART				= '00065828'					;-20 poison duration
Global $STRUCT_INSCRIPTION_ONLY_THE_STRONG_SURVIVE		= '00085828'					;-20 weakness duration								; incorrect
#EndRegion Focus and Shield Inscriptions
#EndRegion Offhand Inscriptions



#Region Mods
#Region common mods
Global $STRUCT_MOD_30_HEALTH							= '001E4823'					;+30 health
Global $STRUCT_MOD_5_ARMOR								= '05000821'					;+5 armor
Global $STRUCT_MOD_OF_SHELTER							= '07005821'					;+7 armor vs physical
Global $STRUCT_MOD_OF_WARDING							= '07002821'					;+7 armor vs elemental
Global $STRUCT_MOD_OF_ENCHANTING						= '1400B822'					;+20% enchantment duration

Global $STRUCT_MOD_OF_THE_WARRIOR						= '0511A828'
Global $STRUCT_MOD_OF_THE_RANGER						= '0517A828'
Global $STRUCT_MOD_OF_THE_NECROMANCER					= '0506A828'
Global $STRUCT_MOD_OF_THE_MESMER						= '0500A828'
Global $STRUCT_MOD_OF_THE_ELEMENTALIST					= '050CA828'
Global $STRUCT_MOD_OF_THE_MONK							= '0510A828'
Global $STRUCT_MOD_OF_THE_RITUALIST						= '0524A828'
Global $STRUCT_MOD_OF_THE_ASSASSIN						= '0523A828'
Global $STRUCT_MOD_OF_THE_PARAGON						= '0528A828'
Global $STRUCT_MOD_OF_THE_DERVISH						= '052CA828'

Global $STRUCT_MOD_OF_DEATHBANE							= '00008080'
Global $STRUCT_MOD_OF_CHARRSLAYING						= '00018080'
Global $STRUCT_MOD_OF_TROLLSLAYING						= '00028080'
Global $STRUCT_MOD_OF_PRUNING							= '00038080'
Global $STRUCT_MOD_OF_SKELETON_SLAYING					= '00048080'
Global $STRUCT_MOD_OF_GIANT_SLAYING						= '00058080'
Global $STRUCT_MOD_OF_DWARF_SLAYING						= '00068080'
Global $STRUCT_MOD_OF_TENGU_SLAYING						= '00078080'
Global $STRUCT_MOD_OF_DEMON_SLAYING						= '00088080'
Global $STRUCT_MOD_OF_OGRE_SLAYING						= '000A8080'
Global $STRUCT_MOD_OF_DRAGON_SLAYING					= '00098080'
#EndRegion common mods

#Region martial mods
Global $STRUCT_MOD_BARBED								= 'DE016824'					;+33% bleeding
Global $STRUCT_MOD_CRUEL								= 'E2016824'					;+33% deep wound
Global $STRUCT_MOD_CRIPPLING							= 'E1016824'					;+33% crippled							;Doesn't match all crippling prefixes
Global $STRUCT_MOD_HEAVY								= 'E601824'						;+33% weakness
Global $STRUCT_MOD_POISONOUS							= 'E4016824'					;+33% poison
Global $STRUCT_MOD_SILENCING							= 'E5016824'					;+33% dazed

Global $STRUCT_MOD_EBON									= '000BB824'
Global $STRUCT_MOD_FIERY								= '0005B824'
Global $STRUCT_MOD_ICY									= '0003B824'
Global $STRUCT_MOD_SHOCKING								= '0004B824'

Global $STRUCT_MOD_FURIOUS								= '0A00B823'					;adrenaline * 2 ^ 20%
Global $STRUCT_MOD_SUNDERING							= '1414F823'					;armor penetration 20^20

Global $STRUCT_MOD_VAMPIRIC_3							= '00032825'
Global $STRUCT_MOD_VAMPIRIC_5							= '00052825'
Global $STRUCT_MOD_ZEALOUS								= '01001825'
; +1^20%
Global $STRUCT_MOD_OF_AXE_MASTERY						= '14121824'
Global $STRUCT_MOD_OF_MARKSMANSHIP						= '14191824'
Global $STRUCT_MOD_OF_DAGGER_MASTERY					= '141D1824'
Global $STRUCT_MOD_OF_HAMMER_MASTERY					= '14131824'
Global $STRUCT_MOD_OF_SCYTHE_MASTERY					= '14291824'
Global $STRUCT_MOD_OF_SPEAR_MASTERY						= '14251824'
Global $STRUCT_MOD_OF_SWORDMANSHIP						= '14141824'
#EndRegion of Mastery

#Region caster weapons mods
Global $STRUCT_MOD_HCT_20								= '00140828'
Global $STRUCT_MOD_HCT_10								= '000A0822'
Global $STRUCT_MOD_HSR_20								= '00142828'
Global $STRUCT_MOD_HSR_10								= '000AA823'
#EndRegion caster weapons mods

#Region staff mods
Global $STRUCT_MOD_OF_DEVOTION							= '002D6823'					;+45 health while enchanted
Global $STRUCT_MOD_OF_ENDURANCE							= '002D8823'					;+45 health while in a stance
Global $STRUCT_MOD_OF_VALOR								= '003C7823'					;+60 health while hexed

Global $STRUCT_MOD_STAFF_MASTERY						= '00143828'					;+1^20%
#EndRegion staff mods
#EndRegion Mods


#Region inherent bonus
#Region martial weapons
Global $STRUCT_INHERENT_ZEALOUS_STRENGTH				= $STRUCT_ENERGY_REGENERATION	;+15% damage energy regeneration -1 - energy regeneration -1 part
;Global $STRUCT_INHERENT_ZEALOUS_STRENGTH_2				= '0F003822'					;+15% damage -1 energy regeneration - +15% damage part

Global $STRUCT_INHERENT_VAMPIRIC_STRENGTH				= '0100E820'					;+15% damage health regeneration -1 - health regeneration -1 part
;Global $STRUCT_INHERENT_VAMPIRIC_STRENGTH_2			= '0F003822'					;+15% damage -1 health regeneration - +15% damage part
#EndRegion martial weapons

#Region caster weapons and focus
Global $STRUCT_INHERENT_FIRE_MAGIC_HCT					= '0A141822'
Global $STRUCT_INHERENT_FIRE_MAGIC_HSR					= '0A149823'
Global $STRUCT_INHERENT_WATER_MAGIC_HCT					= '0B141822'
Global $STRUCT_INHERENT_WATER_MAGIC_HSR					= '0B149823'
Global $STRUCT_INHERENT_AIR_MAGIC_HCT					= '08141822'
Global $STRUCT_INHERENT_AIR_MAGIC_HSR					= '08149823'
Global $STRUCT_INHERENT_EARTH_MAGIC_HCT					= '09141822'
Global $STRUCT_INHERENT_EARTH_MAGIC_HSR					= '09149823'
Global $STRUCT_INHERENT_ENERGY_STORAGE_HCT				= '0C141822'
Global $STRUCT_INHERENT_ENERGY_STORAGE_HSR				= '0C149823'
Global $STRUCT_INHERENT_SMITING_PRAYERS_HCT				= '0E141822'
Global $STRUCT_INHERENT_SMITING_PRAYERS_HSR				= '0E149823'
Global $STRUCT_INHERENT_DIVINE_FAVOR_HCT				= '10141822'
Global $STRUCT_INHERENT_DIVINE_FAVOR_HSR				= '10149823'
Global $STRUCT_INHERENT_HEALING_PRAYERS_HCT				= '0D141822'
Global $STRUCT_INHERENT_HEALING_PRAYERS_HSR				= '0D149823'
Global $STRUCT_INHERENT_PROTECTION_PRAYERS_HCT			= '0F141822'
Global $STRUCT_INHERENT_PROTECTION_PRAYERS_HSR			= '0F149823'
Global $STRUCT_INHERENT_CHANNELING_MAGIC_HCT			= '22141822'
Global $STRUCT_INHERENT_CHANNELING_MAGIC_HSR			= '22149823'
Global $STRUCT_INHERENT_RESTORATION_MAGIC_HCT			= '21141822'
Global $STRUCT_INHERENT_RESTORATION_MAGIC_HSR			= '21149823'
Global $STRUCT_INHERENT_COMMUNING_HCT					= '20141822'
Global $STRUCT_INHERENT_COMMUNING_HSR					= '20149823'
Global $STRUCT_INHERENT_SPAWNING_POWER_HCT				= '24141822'
Global $STRUCT_INHERENT_SPAWNING_POWER_HSR				= '24149823'
Global $STRUCT_INHERENT_ILLUSION_MAGIC_HCT				= '01149823'
Global $STRUCT_INHERENT_ILLUSION_MAGIC_HSR				= '01141822'
Global $STRUCT_INHERENT_DOMINATION_MAGIC_HCT			= '02141822'
Global $STRUCT_INHERENT_DOMINATION_MAGIC_HSR			= '02149823'
Global $STRUCT_INHERENT_INSPIRATION_MAGIC_HCT			= '03149823'
Global $STRUCT_INHERENT_INSPIRATION_MAGIC_HSR			= '03141822'
Global $STRUCT_INHERENT_DEATH_MAGIC_HCT					= '05141822'
Global $STRUCT_INHERENT_DEATH_MAGIC_HSR					= '05149823'
Global $STRUCT_INHERENT_BLOOD_MAGIC_HCT					= '04149823'
Global $STRUCT_INHERENT_BLOOD_MAGIC_HSR					= '04141822'
Global $STRUCT_INHERENT_SOUL_REAPING_HCT				= '06149823'
Global $STRUCT_INHERENT_SOUL_REAPING_HSR				= '06141822'
Global $STRUCT_INHERENT_CURSES_HCT						= '07149823'
Global $STRUCT_INHERENT_CURSES_HSR						= '07141822'
#EndRegion caster weapons and focus

#Region focus and shield OS (Old School)
; 10 armor VS ...
Global $STRUCT_INHERENT_ARMOR_VS_UNDEAD					= '0A004821'		;'A0048210'
Global $STRUCT_INHERENT_ARMOR_VS_CHARR					= '0A014821'
Global $STRUCT_INHERENT_ARMOR_VS_TROLLS					= '0A024821'
Global $STRUCT_INHERENT_ARMOR_VS_PLANTS					= '0A034821'		;'A0348210'
Global $STRUCT_INHERENT_ARMOR_VS_SKELETONS				= '0A044821'
Global $STRUCT_INHERENT_ARMOR_VS_GIANTS					= '0A054821'
Global $STRUCT_INHERENT_ARMOR_VS_DWARVES				= '0A064821'
Global $STRUCT_INHERENT_ARMOR_VS_TENGU					= '0A074821'		;'A0748210'
Global $STRUCT_INHERENT_ARMOR_VS_DEMONS					= '0A084821'		;'A0848210'
Global $STRUCT_INHERENT_ARMOR_VS_DRAGONS				= '0A094821'		;'A0948210'
Global $STRUCT_INHERENT_ARMOR_VS_OGRES					= '0A0A4821'

; +1^19% and +1^20%
; Adding 14 to the modstruct as a prefix gives you only +1^20%
Global $STRUCT_INHERENT_OF_ILLUSION_MAGIC				= '0118240'
Global $STRUCT_INHERENT_OF_DOMINATION_MAGIC				= '0218240'
Global $STRUCT_INHERENT_OF_INSPIRATION					= '0318240'
Global $STRUCT_INHERENT_OF_BLOOD_MAGIC					= '0418240'
Global $STRUCT_INHERENT_OF_DEATH_MAGIC					= '0518240'
Global $STRUCT_INHERENT_OF_SOUL_REAPING					= '0618240'
Global $STRUCT_INHERENT_OF_CURSE_MAGIC					= '0718240'
Global $STRUCT_INHERENT_OF_AIR_MAGIC					= '0818240'
Global $STRUCT_INHERENT_OF_EARTH_MAGIC					= '0918240'
Global $STRUCT_INHERENT_OF_FIRE_MAGIC					= '0A18240'
Global $STRUCT_INHERENT_OF_WATER_MAGIC					= '0B18240'
Global $STRUCT_INHERENT_OF_HEALING_PRAYERS				= '0D18240'
Global $STRUCT_INHERENT_OF_SMITING_PRAYERS				= '0E18240'
Global $STRUCT_INHERENT_OF_PROTECTION_PRAYERS			= '0F18240'
Global $STRUCT_INHERENT_OF_DIVINE_FAVOR					= '1018240'
Global $STRUCT_INHERENT_OF_COMMUNING_MAGIC				= '2018240'
Global $STRUCT_INHERENT_OF_RESTORATION_MAGIC			= '2118240'
Global $STRUCT_INHERENT_OF_CHANNELING_MAGIC				= '2218240'
Global $STRUCT_INHERENT_OF_SPAWNING_MAGIC				= '2418240'
#EndRegion focus and shield OS (Old School)
#EndRegion inherent bonus


#Region Runes
Global Const $ID_Warrior_Insignias_Knights					= '19152'
Global Const $ID_Warrior_Insignias_Lieutenants				= '19153'
Global Const $ID_Warrior_Insignias_Stonefist				= '19154'
Global Const $ID_Warrior_Insignias_Dreadnought				= '19155'
Global Const $ID_Warrior_Insignias_Sentinels				= '19156'
Global Const $ID_Warrior_Runes_Minor_Absorption				= '903'
Global Const $ID_Warrior_Runes_Minor_Axe_Mastery			= '903'
Global Const $ID_Warrior_Runes_Minor_Hammer_Mastery			= '903'
Global Const $ID_Warrior_Runes_Minor_Strength				= '903'
Global Const $ID_Warrior_Runes_Minor_Swordsmanship			= '903'
Global Const $ID_Warrior_Runes_Minor_Tactics				= '903'
Global Const $ID_Warrior_Runes_Major_Absorption				= '5558'
Global Const $ID_Warrior_Runes_Major_Axe_Mastery			= '5558'
Global Const $ID_Warrior_Runes_Major_Hammer_Mastery			= '5558'
Global Const $ID_Warrior_Runes_Major_Strength				= '5558'
Global Const $ID_Warrior_Runes_Major_Swordsmanship			= '5558'
Global Const $ID_Warrior_Runes_Major_Tactics				= '5558'
Global Const $ID_Warrior_Runes_Superior_Axe_Mastery			= '5559'
Global Const $ID_Warrior_Runes_Superior_Hammer_Mastery		= '5559'
Global Const $ID_Warrior_Runes_Superior_Strength			= '5559'
Global Const $ID_Warrior_Runes_Superior_Swordsmanship		= '5559'
Global Const $ID_Warrior_Runes_Superior_Tactics				= '5559'
Global Const $ID_Warrior_Runes_Superior_Absorption			= '5559'
Global Const $ID_Ranger_Insignias_Frostbound				= '19157'
Global Const $ID_Ranger_Insignias_Pyrebound					= '19159'
Global Const $ID_Ranger_Insignias_Stormbound				= '19160'
Global Const $ID_Ranger_Insignias_Scouts					= '19162'
Global Const $ID_Ranger_Insignias_Earthbound				= '19158'
Global Const $ID_Ranger_Insignias_Beastmasters				= '19161'
Global Const $ID_Ranger_Runes_Minor_Beast_Mastery			= '904'
Global Const $ID_Ranger_Runes_Minor_Expertise				= '904'
Global Const $ID_Ranger_Runes_Minor_Marksmanship			= '904'
Global Const $ID_Ranger_Runes_Minor_Wilderness_Survival		= '904'
Global Const $ID_Ranger_Runes_Major_Beast_Mastery			= '5560'
Global Const $ID_Ranger_Runes_Major_Expertise				= '5560'
Global Const $ID_Ranger_Runes_Major_Marksmanship			= '5560'
Global Const $ID_Ranger_Runes_Major_Wilderness_Survival		= '5560'
Global Const $ID_Ranger_Runes_Superior_Beast_Mastery		= '5561'
Global Const $ID_Ranger_Runes_Superior_Expertise			= '5561'
Global Const $ID_Ranger_Runes_Superior_Marksmanship			= '5561'
Global Const $ID_Ranger_Runes_Superior_Wilderness_Survival	= '5561'
Global Const $ID_Monk_Insignias_Wanderers					= '19149'
Global Const $ID_Monk_Insignias_Disciples					= '19150'
Global Const $ID_Monk_Insignias_Anchorites					= '19151'
Global Const $ID_Monk_Runes_Minor_Divine_Favor				= '902'
Global Const $ID_Monk_Runes_Minor_Healing_Prayers			= '902'
Global Const $ID_Monk_Runes_Minor_Protection_Prayers		= '902'
Global Const $ID_Monk_Runes_Minor_Smiting_Prayers			= '902'
Global Const $ID_Monk_Runes_Major_Healing_Prayers			= '5556'
Global Const $ID_Monk_Runes_Major_Protection_Prayers		= '5556'
Global Const $ID_Monk_Runes_Major_Smiting_Prayers			= '5556'
Global Const $ID_Monk_Runes_Major_Divine_Favor				= '5556'
Global Const $ID_Monk_Runes_Superior_Divine_Favor			= '5557'
Global Const $ID_Monk_Runes_Superior_Healing_Prayers		= '5557'
Global Const $ID_Monk_Runes_Superior_Protection_Prayers		= '5557'
Global Const $ID_Monk_Runes_Superior_Smiting_Prayers		= '5557'
Global Const $ID_Necromancer_Insignias_Bloodstained			= '19138'
Global Const $ID_Necromancer_Insignias_Tormentors			= '19139'
Global Const $ID_Necromancer_Insignias_Bonelace				= '19141'
Global Const $ID_Necromancer_Insignias_Minion_Masters		= '19142'
Global Const $ID_Necromancer_Insignias_Blighters			= '19143'
Global Const $ID_Necromancer_Insignias_Undertakers			= '19140'
Global Const $ID_Necromancer_Runes_Minor_Blood_Magic		= '900'
Global Const $ID_Necromancer_Runes_Minor_Curses				= '900'
Global Const $ID_Necromancer_Runes_Minor_Death_Magic		= '900'
Global Const $ID_Necromancer_Runes_Minor_Soul_Reaping		= '900'
Global Const $ID_Necromancer_Runes_Major_Blood_Magic		= '5552'
Global Const $ID_Necromancer_Runes_Major_Curses				= '5552'
Global Const $ID_Necromancer_Runes_Major_Death_Magic		= '5552'
Global Const $ID_Necromancer_Runes_Major_Soul_Reaping		= '5552'
Global Const $ID_Necromancer_Runes_Superior_Blood_Magic		= '5553'
Global Const $ID_Necromancer_Runes_Superior_Curses			= '5553'
Global Const $ID_Necromancer_Runes_Superior_Death_Magic		= '5553'
Global Const $ID_Necromancer_Runes_Superior_Soul_Reaping	= '5553'
Global Const $ID_Mesmer_Insignias_Virtuosos					= '19130'
Global Const $ID_Mesmer_Insignias_Artificers				= '19128'
Global Const $ID_Mesmer_Insignias_Prodigys					= '19129'
Global Const $ID_Mesmer_Runes_Minor_Domination_Magic		= '899'
Global Const $ID_Mesmer_Runes_Minor_Fast_Casting			= '899'
Global Const $ID_Mesmer_Runes_Minor_Illusion_Magic			= '899'
Global Const $ID_Mesmer_Runes_Minor_Inspiration_Magic		= '899'
Global Const $ID_Mesmer_Runes_Major_Domination_Magic		= '3612'
Global Const $ID_Mesmer_Runes_Major_Fast_Casting			= '3612'
Global Const $ID_Mesmer_Runes_Major_Illusion_Magic			= '3612'
Global Const $ID_Mesmer_Runes_Major_Inspiration_Magic		= '3612'
Global Const $ID_Mesmer_Runes_Superior_Domination_Magic		= '5549'
Global Const $ID_Mesmer_Runes_Superior_Fast_Casting			= '5549'
Global Const $ID_Mesmer_Runes_Superior_Illusion_Magic		= '5549'
Global Const $ID_Mesmer_Runes_Superior_Inspiration_Magic	= '5549'
Global Const $ID_Elementalist_Insignias_Hydromancer			= '19145'
Global Const $ID_Elementalist_Insignias_Geomancer			= '19146'
Global Const $ID_Elementalist_Insignias_Pyromancer			= '19147'
Global Const $ID_Elementalist_Insignias_Aeromancer			= '19148'
Global Const $ID_Elementalist_Insignias_Prismatic			= '19144'
Global Const $ID_Elementalist_Runes_Minor_Air_Magic			= '901'
Global Const $ID_Elementalist_Runes_Minor_Earth_Magic		= '901'
Global Const $ID_Elementalist_Runes_Minor_Energy_Storage	= '901'
Global Const $ID_Elementalist_Runes_Minor_Water_Magic		= '901'
Global Const $ID_Elementalist_Runes_Minor_Fire_Magic		= '901'
Global Const $ID_Elementalist_Runes_Major_Air_Magic			= '5554'
Global Const $ID_Elementalist_Runes_Major_Earth_Magic		= '5554'
Global Const $ID_Elementalist_Runes_Major_Energy_Storage	= '5554'
Global Const $ID_Elementalist_Runes_Major_Fire_Magic		= '5554'
Global Const $ID_Elementalist_Runes_Major_Water_Magic		= '5554'
Global Const $ID_Elementalist_Runes_Superior_Air_Magic		= '5555'
Global Const $ID_Elementalist_Runes_Superior_Earth_Magic	= '5555'
Global Const $ID_Elementalist_Runes_Superior_Energy_Storage	= '5555'
Global Const $ID_Elementalist_Runes_Superior_Fire_Magic		= '5555'
Global Const $ID_Elementalist_Runes_Superior_Water_Magic	= '5555'
Global Const $ID_Assassin_Insignias_Vanguards				= '19124'
Global Const $ID_Assassin_Insignias_Infiltrators			= '19125'
Global Const $ID_Assassin_Insignias_Saboteurs				= '19126'
Global Const $ID_Assassin_Insignias_Nightstalkers			= '19127'
Global Const $ID_Assassin_Runes_Minor_Critical_Strikes		= '6324'
Global Const $ID_Assassin_Runes_Minor_Dagger_Mastery		= '6324'
Global Const $ID_Assassin_Runes_Minor_Deadly_Arts			= '6324'
Global Const $ID_Assassin_Runes_Minor_Shadow_Arts			= '6324'
Global Const $ID_Assassin_Runes_Major_Critical_Strikes		= '6325'
Global Const $ID_Assassin_Runes_Major_Dagger_Mastery		= '6325'
Global Const $ID_Assassin_Runes_Major_Deadly_Arts			= '6325'
Global Const $ID_Assassin_Runes_Major_Shadow_Arts			= '6325'
Global Const $ID_Assassin_Runes_Superior_Critical_Strikes	= '6326'
Global Const $ID_Assassin_Runes_Superior_Dagger_Mastery		= '6326'
Global Const $ID_Assassin_Runes_Superior_Deadly_Arts		= '6326'
Global Const $ID_Assassin_Runes_Superior_Shadow_Arts		= '6326'
Global Const $ID_Ritualist_Insignias_Shamans				= '19165'
Global Const $ID_Ritualist_Insignias_Ghost_Forge			= '19166'
Global Const $ID_Ritualist_Insignias_Mystics				= '19167'
Global Const $ID_Ritualist_Runes_Minor_Channeling_Magic		= '6327'
Global Const $ID_Ritualist_Runes_Minor_Communing			= '6327'
Global Const $ID_Ritualist_Runes_Minor_Restoration_Magic	= '6327'
Global Const $ID_Ritualist_Runes_Minor_Spawning_Power		= '6327'
Global Const $ID_Ritualist_Runes_Major_Channeling_Magic		= '6328'
Global Const $ID_Ritualist_Runes_Major_Communing			= '6328'
Global Const $ID_Ritualist_Runes_Major_Restoration_Magic	= '6328'
Global Const $ID_Ritualist_Runes_Major_Spawning_Power		= '6328'
Global Const $ID_Ritualist_Runes_Superior_Channeling_Magic	= '6329'
Global Const $ID_Ritualist_Runes_Superior_Communing			= '6329'
Global Const $ID_Ritualist_Runes_Superior_Restoration_Magic	= '6329'
Global Const $ID_Ritualist_Runes_Superior_Spawning_Power	= '6329'
Global Const $ID_Dervish_Insignias_Windwalker				= '19163'
Global Const $ID_Dervish_Insignias_Forsaken					= '19164'
Global Const $ID_Dervish_Runes_Minor_Earth_Prayers			= '15545'
Global Const $ID_Dervish_Runes_Minor_Mysticism				= '15545'
Global Const $ID_Dervish_Runes_Minor_Scythe_Mastery			= '15545'
Global Const $ID_Dervish_Runes_Minor_Wind_Prayers			= '15545'
Global Const $ID_Dervish_Runes_Major_Earth_Prayers			= '15546'
Global Const $ID_Dervish_Runes_Major_Mysticism				= '15546'
Global Const $ID_Dervish_Runes_Major_Scythe_Mastery			= '15546'
Global Const $ID_Dervish_Runes_Major_Wind_Prayers			= '15546'
Global Const $ID_Dervish_Runes_Superior_Earth_Prayers		= '15547'
Global Const $ID_Dervish_Runes_Superior_Mysticism			= '15547'
Global Const $ID_Dervish_Runes_Superior_Scythe_Mastery		= '15547'
Global Const $ID_Dervish_Runes_Superior_Wind_Prayers		= '15547'
Global Const $ID_Paragon_Insignias_Centurions				= '19168'
Global Const $ID_Paragon_Runes_Minor_Command				= '15548'
Global Const $ID_Paragon_Runes_Minor_Leadership				= '15548'
Global Const $ID_Paragon_Runes_Minor_Motivation				= '15548'
Global Const $ID_Paragon_Runes_Minor_Spear_Mastery			= '15548'
Global Const $ID_Paragon_Runes_Major_Command				= '15549'
Global Const $ID_Paragon_Runes_Major_Leadership				= '15549'
Global Const $ID_Paragon_Runes_Major_Motivation				= '15549'
Global Const $ID_Paragon_Runes_Major_Spear_Mastery			= '15549'
Global Const $ID_Paragon_Runes_Superior_Command				= '15550'
Global Const $ID_Paragon_Runes_Superior_Leadership			= '15550'
Global Const $ID_Paragon_Runes_Superior_Motivation			= '15550'
Global Const $ID_Paragon_Runes_Superior_Spear_Mastery		= '15550'
Global Const $ID_Insignias_Survivor							= '19132'
Global Const $ID_Insignias_Radiant							= '19131'
Global Const $ID_Insignias_Stalwart							= '19133'
Global Const $ID_Insignias_Brawlers							= '19134'
Global Const $ID_Insignias_Blessed							= '19135'
Global Const $ID_Insignias_Heralds							= '19136'
Global Const $ID_Insignias_Sentrys							= '19137'
Global Const $ID_Runes_Minor_Vigor							= '898'
Global Const $ID_Runes_Vitae								= '898'
Global Const $ID_Runes_Attunement							= '898'
Global Const $ID_Runes_Major_Vigor							= '5550'
Global Const $ID_Runes_Recovery								= '5550'
Global Const $ID_Runes_Restoration							= '5550'
Global Const $ID_Runes_Clarity								= '5550'
Global Const $ID_Runes_Purity								= '5550'
Global Const $ID_Runes_Superior_Vigor						= '5551'


Global Const $Struct_Warrior_Insignias_Knights					= 'F9010824'
Global Const $Struct_Warrior_Insignias_Lieutenants				= '08020824'
Global Const $Struct_Warrior_Insignias_Stonefist				= '09020824'
Global Const $Struct_Warrior_Insignias_Dreadnought				= 'FA010824'
Global Const $Struct_Warrior_Insignias_Sentinels				= 'FB010824'
Global Const $Struct_Warrior_Runes_Minor_Absorption				= 'EA02E827'
Global Const $Struct_Warrior_Runes_Minor_Axe_Mastery			= '0112E821'
Global Const $Struct_Warrior_Runes_Minor_Hammer_Mastery			= '0113E821'
Global Const $Struct_Warrior_Runes_Minor_Strength				= '0111E821'
Global Const $Struct_Warrior_Runes_Minor_Swordsmanship			= '0114E821'
Global Const $Struct_Warrior_Runes_Minor_Tactics				= '0115E821'
Global Const $Struct_Warrior_Runes_Major_Absorption				= 'EA02E927'
Global Const $Struct_Warrior_Runes_Major_Axe_Mastery			= '0212E8217301'
Global Const $Struct_Warrior_Runes_Major_Hammer_Mastery			= '0213E8217301'
Global Const $Struct_Warrior_Runes_Major_Strength				= '0211E8217301'
Global Const $Struct_Warrior_Runes_Major_Swordsmanship			= '0214E8217301'
Global Const $Struct_Warrior_Runes_Major_Tactics				= '0215E8217301'
Global Const $Struct_Warrior_Runes_Superior_Axe_Mastery			= '0312E8217F01'
Global Const $Struct_Warrior_Runes_Superior_Hammer_Mastery		= '0313E8217F01'
Global Const $Struct_Warrior_Runes_Superior_Strength			= '0311E8217F01'
Global Const $Struct_Warrior_Runes_Superior_Swordsmanship		= '0314E8217F01'
Global Const $Struct_Warrior_Runes_Superior_Tactics				= '0315E8217F01'
Global Const $Struct_Warrior_Runes_Superior_Absorption			= 'EA02EA27'
Global Const $Struct_Ranger_Insignias_Frostbound				= 'FC010824'
Global Const $Struct_Ranger_Insignias_Pyrebound					= 'FE010824'
Global Const $Struct_Ranger_Insignias_Stormbound				= 'FF010824'
Global Const $Struct_Ranger_Insignias_Scouts					= '01020824'
Global Const $Struct_Ranger_Insignias_Earthbound				= 'FD010824'
Global Const $Struct_Ranger_Insignias_Beastmasters				= '00020824'
Global Const $Struct_Ranger_Runes_Minor_Beast_Mastery			= '0116E821'
Global Const $Struct_Ranger_Runes_Minor_Expertise				= '0117E821'
Global Const $Struct_Ranger_Runes_Minor_Marksmanship			= '0119E821'
Global Const $Struct_Ranger_Runes_Minor_Wilderness_Survival		= '0118E821'
Global Const $Struct_Ranger_Runes_Major_Beast_Mastery			= '0216E8217501'
Global Const $Struct_Ranger_Runes_Major_Expertise				= '0217E8217501'
Global Const $Struct_Ranger_Runes_Major_Marksmanship			= '0219E8217501'
Global Const $Struct_Ranger_Runes_Major_Wilderness_Survival		= '0218E8217501'
Global Const $Struct_Ranger_Runes_Superior_Beast_Mastery		= '0316E8218101'
Global Const $Struct_Ranger_Runes_Superior_Expertise			= '0317E8218101'
Global Const $Struct_Ranger_Runes_Superior_Marksmanship			= '0319E8218101'
Global Const $Struct_Ranger_Runes_Superior_Wilderness_Survival	= '0318E8218101'
Global Const $Struct_Monk_Insignias_Wanderers					= 'F6010824'
Global Const $Struct_Monk_Insignias_Disciples					= 'F7010824'
Global Const $Struct_Monk_Insignias_Anchorites					= 'F8010824'
Global Const $Struct_Monk_Runes_Minor_Divine_Favor				= '0110E821'
Global Const $Struct_Monk_Runes_Minor_Healing_Prayers			= '010DE821'
Global Const $Struct_Monk_Runes_Minor_Protection_Prayers		= '010FE821'
Global Const $Struct_Monk_Runes_Minor_Smiting_Prayers			= '010EE821'
Global Const $Struct_Monk_Runes_Major_Healing_Prayers			= '020DE8217101'
Global Const $Struct_Monk_Runes_Major_Protection_Prayers		= '020FE8217101'
Global Const $Struct_Monk_Runes_Major_Smiting_Prayers			= '020EE8217101'
Global Const $Struct_Monk_Runes_Major_Divine_Favor				= '0210E8217101'
Global Const $Struct_Monk_Runes_Superior_Divine_Favor			= '0310E8217D01'
Global Const $Struct_Monk_Runes_Superior_Healing_Prayers		= '030DE8217D01'
Global Const $Struct_Monk_Runes_Superior_Protection_Prayers		= '030FE8217D01'
Global Const $Struct_Monk_Runes_Superior_Smiting_Prayers		= '030EE8217D01'
Global Const $Struct_Necromancer_Insignias_Bloodstained			= '0A020824'
Global Const $Struct_Necromancer_Insignias_Tormentors			= 'EC010824'
Global Const $Struct_Necromancer_Insignias_Bonelace				= 'EE010824'
Global Const $Struct_Necromancer_Minion_Masters_Insignia		= 'EF010824'
Global Const $Struct_Necromancer_Insignias_Blighters			= 'F0010824'
Global Const $Struct_Necromancer_Insignias_Undertakers			= 'ED010824'
Global Const $Struct_Necromancer_Runes_Minor_Blood_Magic		= '0104E821'
Global Const $Struct_Necromancer_Runes_Minor_Curses				= '0107E821'
Global Const $Struct_Necromancer_Runes_Minor_Death_Magic		= '0105E821'
Global Const $Struct_Necromancer_Runes_Minor_Soul_Reaping		= '0106E821'
Global Const $Struct_Necromancer_Runes_Major_Blood_Magic		= '0204E8216D01'
Global Const $Struct_Necromancer_Runes_Major_Curses				= '0207E8216D01'
Global Const $Struct_Necromancer_Runes_Major_Death_Magic		= '0205E8216D01'
Global Const $Struct_Necromancer_Runes_Major_Soul_Reaping		= '0206E8216D01'
Global Const $Struct_Necromancer_Runes_Superior_Blood_Magic		= '0304E8217901'
Global Const $Struct_Necromancer_Runes_Superior_Curses			= '0307E8217901'
Global Const $Struct_Necromancer_Runes_Superior_Death_Magic		= '0305E8217901'
Global Const $Struct_Necromancer_Runes_Superior_Soul_Reaping	= '0306E8217901'
Global Const $Struct_Mesmer_Insignias_Virtuosos					= 'E4010824'
Global Const $Struct_Mesmer_Insignias_Artificers				= 'E2010824'
Global Const $Struct_Mesmer_Insignias_Prodigys					= 'E3010824'
Global Const $Struct_Mesmer_Runes_Minor_Domination_Magic		= '0102E821'
Global Const $Struct_Mesmer_Runes_Minor_Fast_Casting			= '0100E821'
Global Const $Struct_Mesmer_Runes_Minor_Illusion_Magic			= '0101E821'
Global Const $Struct_Mesmer_Runes_Minor_Inspiration_Magic		= '0103E821'
Global Const $Struct_Mesmer_Runes_Major_Domination_Magic		= '0202E8216B01'
Global Const $Struct_Mesmer_Runes_Major_Fast_Casting			= '0200E8216B01'
Global Const $Struct_Mesmer_Runes_Major_Illusion_Magic			= '0201E8216B01'
Global Const $Struct_Mesmer_Runes_Major_Inspiration_Magic		= '0203E8216B01'
Global Const $Struct_Mesmer_Runes_Superior_Domination_Magic		= '0302E8217701'
Global Const $Struct_Mesmer_Runes_Superior_Fast_Casting			= '0300E8217701'
Global Const $Struct_Mesmer_Runes_Superior_Illusion_Magic		= '0301E8217701'
Global Const $Struct_Mesmer_Runes_Superior_Inspiration_Magic	= '0303E8217701'
Global Const $Struct_Elementalist_Insignias_Hydromancer			= 'F2010824'
Global Const $Struct_Elementalist_Insignias_Geomancer			= 'F3010824'
Global Const $Struct_Elementalist_Insignias_Pyromancer			= 'F4010824'
Global Const $Struct_Elementalist_Insignias_Aeromancer			= 'F5010824'
Global Const $Struct_Elementalist_Insignias_Prismatic			= 'F1010824'
Global Const $Struct_Elementalist_Runes_Minor_Air_Magic			= '0108E821'
Global Const $Struct_Elementalist_Runes_Minor_Earth_Magic		= '0109E821'
Global Const $Struct_Elementalist_Runes_Minor_Energy_Storage	= '010CE821'
Global Const $Struct_Elementalist_Runes_Minor_Water_Magic		= '010BE821'
Global Const $Struct_Elementalist_Runes_Minor_Fire_Magic		= '010AE821'
Global Const $Struct_Elementalist_Runes_Major_Air_Magic			= '0208E8216F01'
Global Const $Struct_Elementalist_Runes_Major_Earth_Magic		= '0209E8216F01'
Global Const $Struct_Elementalist_Runes_Major_Energy_Storage	= '020CE8216F01'
Global Const $Struct_Elementalist_Runes_Major_Fire_Magic		= '020AE8216F01'
Global Const $Struct_Elementalist_Runes_Major_Water_Magic		= '020BE8216F01'
Global Const $Struct_Elementalist_Runes_Superior_Air_Magic		= '0308E8217B01'
Global Const $Struct_Elementalist_Runes_Superior_Earth_Magic	= '0309E8217B01'
Global Const $Struct_Elementalist_Runes_Superior_Energy_Storage	= '030CE8217B01'
Global Const $Struct_Elementalist_Runes_Superior_Fire_Magic		= '030AE8217B01'
Global Const $Struct_Elementalist_Runes_Superior_Water_Magic	= '030BE8217B01'
Global Const $Struct_Assassin_Insignias_Vanguards				= 'DE010824'
Global Const $Struct_Assassin_Insignias_Infiltrators			= 'DF010824'
Global Const $Struct_Assassin_Insignias_Saboteurs				= 'E0010824'
Global Const $Struct_Assassin_Insignias_Nightstalkers			= 'E1010824'
Global Const $Struct_Assassin_Runes_Minor_Critical_Strikes		= '0123E821'
Global Const $Struct_Assassin_Runes_Minor_Dagger_Mastery		= '011DE821'
Global Const $Struct_Assassin_Runes_Minor_Deadly_Arts			= '011EE821'
Global Const $Struct_Assassin_Runes_Minor_Shadow_Arts			= '011FE821'
Global Const $Struct_Assassin_Runes_Major_Critical_Strikes		= '0223E8217902'
Global Const $Struct_Assassin_Runes_Major_Dagger_Mastery		= '021DE8217902'
Global Const $Struct_Assassin_Runes_Major_Deadly_Arts			= '021EE8217902'
Global Const $Struct_Assassin_Runes_Major_Shadow_Arts			= '021FE8217902'
Global Const $Struct_Assassin_Runes_Superior_Critical_Strikes	= '0323E8217B02'
Global Const $Struct_Assassin_Runes_Superior_Dagger_Mastery		= '031DE8217B02'
Global Const $Struct_Assassin_Runes_Superior_Deadly_Arts		= '031EE8217B02'
Global Const $Struct_Assassin_Runes_Superior_Shadow_Arts		= '031FE8217B02'
Global Const $Struct_Ritualist_Insignias_Shamans				= '04020824'
Global Const $Struct_Ritualist_Ghost_Forge_Insignia				= '05020824'
Global Const $Struct_Ritualist_Insignias_Mystics				= '06020824'
Global Const $Struct_Ritualist_Runes_Minor_Channeling_Magic		= '0122E821'
Global Const $Struct_Ritualist_Runes_Minor_Communing			= '0120E821'
Global Const $Struct_Ritualist_Runes_Minor_Restoration_Magic	= '0121E821'
Global Const $Struct_Ritualist_Runes_Minor_Spawning_Power		= '0124E821'
Global Const $Struct_Ritualist_Runes_Major_Channeling_Magic		= '0222E8217F02'
Global Const $Struct_Ritualist_Runes_Major_Communing			= '0220E8217F02'
Global Const $Struct_Ritualist_Runes_Major_Restoration_Magic	= '0221E8217F02'
Global Const $Struct_Ritualist_Runes_Major_Spawning_Power		= '0224E8217F02'
Global Const $Struct_Ritualist_Runes_Superior_Channeling_Magic	= '0322E8218102'
Global Const $Struct_Ritualist_Runes_Superior_Communing			= '0320E8218102'
Global Const $Struct_Ritualist_Runes_Superior_Restoration_Magic	= '0321E8218102'
Global Const $Struct_Ritualist_Runes_Superior_Spawning_Power	= '0324E8218102'
Global Const $Struct_Dervish_Insignias_Windwalker				= '02020824'
Global Const $Struct_Dervish_Insignias_Forsaken					= '03020824'
Global Const $Struct_Dervish_Runes_Minor_Earth_Prayers			= '012BE821'
Global Const $Struct_Dervish_Runes_Minor_Mysticism				= '012CE821'
Global Const $Struct_Dervish_Runes_Minor_Scythe_Mastery			= '0129E821'
Global Const $Struct_Dervish_Runes_Minor_Wind_Prayers			= '012AE821'
Global Const $Struct_Dervish_Runes_Major_Earth_Prayers			= '022BE8210703'
Global Const $Struct_Dervish_Runes_Major_Mysticism				= '022CE8210703'
Global Const $Struct_Dervish_Runes_Major_Scythe_Mastery			= '0229E8210703'
Global Const $Struct_Dervish_Runes_Major_Wind_Prayers			= '022AE8210703'
Global Const $Struct_Dervish_Runes_Superior_Earth_Prayers		= '032BE8210903'
Global Const $Struct_Dervish_Runes_Superior_Mysticism			= '032CE8210903'
Global Const $Struct_Dervish_Runes_Superior_Scythe_Mastery		= '0329E8210903'
Global Const $Struct_Dervish_Runes_Superior_Wind_Prayers		= '032AE8210903'
Global Const $Struct_Paragon_Insignias_Centurions				= '07020824'
Global Const $Struct_Paragon_Runes_Minor_Command				= '0126E821'
Global Const $Struct_Paragon_Runes_Minor_Leadership				= '0128E821'
Global Const $Struct_Paragon_Runes_Minor_Motivation				= '0127E821'
Global Const $Struct_Paragon_Runes_Minor_Spear_Mastery			= '0125E821'
Global Const $Struct_Paragon_Runes_Major_Command				= '0226E8210D03'
Global Const $Struct_Paragon_Runes_Major_Leadership				= '0228E8210D03'
Global Const $Struct_Paragon_Runes_Major_Motivation				= '0227E8210D03'
Global Const $Struct_Paragon_Runes_Major_Spear_Mastery			= '0225E8210D03'
Global Const $Struct_Paragon_Runes_Superior_Command				= '0326E8210F03'
Global Const $Struct_Paragon_Runes_Superior_Leadership			= '0328E8210F03'
Global Const $Struct_Paragon_Runes_Superior_Motivation			= '0327E8210F03'
Global Const $Struct_Paragon_Runes_Superior_Spear_Mastery		= '0325E8210F03'
Global Const $Struct_All_Insignias_Survivor						= 'E6010824'
Global Const $Struct_All_Insignias_Radiant						= 'E5010824'
Global Const $Struct_All_Insignias_Stalwart						= 'E7010824'
Global Const $Struct_All_Insignias_Brawlers						= 'E8010824'
Global Const $Struct_All_Insignias_Blessed						= 'E9010824'
Global Const $Struct_All_Insignias_Heralds						= 'EA010824'
Global Const $Struct_All_Insignias_Sentrys						= 'EB010824'
Global Const $Struct_All_Runes_Minor_Vigor						= 'C202E827'
Global Const $Struct_All_Runes_Vitae							= '000A4823'
Global Const $Struct_All_Runes_Attunement						= '0200D822'
Global Const $Struct_All_Runes_Major_Vigor						= 'C202E927'
Global Const $Struct_All_Runes_Recovery							= '07047827'
Global Const $Struct_All_Runes_Restoration						= '00037827'
Global Const $Struct_All_Runes_Clarity							= '01087827'
Global Const $Struct_All_Runes_Purity							= '05067827'
Global Const $Struct_All_Runes_Superior_Vigor					= 'C202EA27'
#EndRegion Runes


#Region Struct Utils
; Insignias are present at index 0 of their armor salvageable item
; Runes are present at index 1 of their armor salvageable item
Global $ValuableRunesAndInsigniasStructsArray[] = DefaultCreateValuableRunesAndInsigniasArray()
Global $ValuableModsByOSWeaponType = DefaultCreateValuableModsByOSWeaponTypeMap()
Global $ValuableModsByWeaponType = DefaultCreateValuableModsByWeaponTypeMap()
Global $PerfectModsByWeaponType = CreatePerfectModsByOSWeaponTypeMap()
Global $ValuableInscriptionsArray[]


;~ Creates an array of all valuable runes and insignias
Func DefaultCreateValuableRunesAndInsigniasArray()
	Local $ValuableRunesAndInsigniasStructsArray[]	= [ _
		$Struct_Warrior_Insignias_Sentinels, _
		_ ;$Struct_Ranger_Insignias_Beastmasters, _
		_ ;$Struct_Monk_Insignias_Anchorites, _
		_ ;$Struct_Monk_Runes_Minor_Divine_Favor, _
		_ ;$Struct_Necromancer_Insignias_Bloodstained, _
		$Struct_Necromancer_Insignias_Tormentors, _
		_ ;$Struct_Necromancer_Runes_Minor_Soul_Reaping, _
		$Struct_Necromancer_Runes_Major_Soul_Reaping, _
		$Struct_Necromancer_Runes_Superior_Soul_Reaping, _
		$Struct_Necromancer_Runes_Minor_Curses, _
		_ ;$Struct_Necromancer_Runes_Superior_Death_Magic, _
		$Struct_Mesmer_Insignias_Prodigys, _
		$Struct_Mesmer_Runes_Minor_Fast_Casting, _
		$Struct_Mesmer_Runes_Minor_Inspiration_Magic, _
		$Struct_Mesmer_Runes_Major_Fast_Casting, _
		$Struct_Mesmer_Runes_Major_Domination_Magic, _
		$Struct_Mesmer_Runes_Superior_Domination_Magic, _
		_ ;$Struct_Mesmer_Runes_Superior_Illusion_Magic, _
		_ ;$Struct_Elementalist_Runes_Minor_Energy_Storage, _
		$Struct_Assassin_Insignias_Nightstalkers, _
		_ ;$Struct_Assassin_Runes_Minor_Critical_Strikes, _
		$Struct_Ritualist_Insignias_Shamans, _
		$Struct_Ritualist_Runes_Minor_Communing, _
		_ ;$Struct_Ritualist_Runes_Minor_Spawning_Power, _
		$Struct_Ritualist_Runes_Minor_Restoration_Magic, _
		$Struct_Ritualist_Runes_Superior_Communing, _
		$Struct_Ritualist_Runes_Superior_Spawning_Power, _
		$Struct_Dervish_Insignias_Windwalker, _
		$Struct_Dervish_Runes_Minor_Mysticism, _
		$Struct_Dervish_Runes_Minor_Scythe_Mastery, _
		_ ;$Struct_Dervish_Runes_Superior_Earth_Prayers, _
		$Struct_Paragon_Insignias_Centurions, _
		$Struct_Paragon_Runes_Minor_Spear_Mastery, _
		_ ;$Struct_All_Insignias_Survivor, _
		_ ;$Struct_All_Insignias_Radiant, _
		_ ;$Struct_All_Insignias_Brawlers, _
		$Struct_All_Insignias_Blessed, _
		_ ;$Struct_All_Runes_Vitae, _
		_ ;$Struct_All_Runes_Clarity, _
		$Struct_All_Runes_Minor_Vigor, _
		$Struct_All_Runes_Major_Vigor, _
		$Struct_All_Runes_Superior_Vigor _
	]
	Return $ValuableRunesAndInsigniasStructsArray
EndFunc


;~ Creates a map to use to find whether an OS (Old School) weapon has a valuable mod - this doesn't mean the weapon itself is valuable
Func DefaultCreateValuableModsByOSWeaponTypeMap()
	; Nothing worth it on OS shields and focii, and there are no OS scythes and spears
	Local $Shield_Mods_Array		= []
	Local $Offhand_Mods_Array		= []
	Local $Scythe_Mods_Array		= []
	Local $Spear_Mods_Array			= []
	Local $Wand_Mods_Array			= [$STRUCT_MOD_OF_THE_NECROMANCER]
	Local $Dagger_Mods_Array		= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER]
	Local $Staff_Mods_Array			= [$STRUCT_MOD_OF_THE_NECROMANCER, _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING] ; Personal collection
	Local $Bow_Mods_Array			= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER, _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING] ; Personal collection
	Local $Axe_Mods_Array			= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER, _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING] ; Personal collection
	Local $Hammer_Mods_Array		= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER, _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING] ; Personal collection
	Local $Sword_Mods_Array			= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER, _
		$STRUCT_MOD_OF_CHARRSLAYING, $STRUCT_MOD_OF_TROLLSLAYING, $STRUCT_MOD_OF_GIANT_SLAYING, $STRUCT_MOD_OF_DWARF_SLAYING, $STRUCT_MOD_OF_TENGU_SLAYING] ; Personal collection
	; Redefining types here remove dependency on GWA2_ID - and we only execute this function once
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
	Local Const $All_Weapons_Array			= [$ID_Type_Shield, $ID_Type_Offhand, $ID_Type_Wand, $ID_Type_Staff, $ID_Type_Bow, $ID_Type_Axe, $ID_Type_Hammer, $ID_Type_Sword, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
	Local Const $All_Weapons_Mods_Array		= [$Shield_Mods_Array, $Offhand_Mods_Array, $Wand_Mods_Array, $Staff_Mods_Array, $Bow_Mods_Array, $Axe_Mods_Array, $Hammer_Mods_Array, _
													$Sword_Mods_Array, $Dagger_Mods_Array, $Scythe_Mods_Array, $Spear_Mods_Array]
	Local $ValuableModsByOSWeaponType[]		= MapFromArrays($All_Weapons_Array, $All_Weapons_Mods_Array)
	Return $ValuableModsByOSWeaponType
EndFunc


;~ Creates a map to use to find whether a weapon (not Old School) has a valuable mod - this doesn't mean the weapon itself is valuable
Func DefaultCreateValuableModsByWeaponTypeMap()
	; Nothing worth on shields - maybe could keep +45^enchanted handles ....
	Local $Shield_Mods_Array	= []
	Local $Offhand_Mods_Array	= [$STRUCT_INSCRIPTION_FORGET_ME_NOT, $STRUCT_MOD_HCT_20, $STRUCT_MOD_HSR_20]
	Local $Wand_Mods_Array		= [ _
		$STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE, _
		$STRUCT_MOD_OF_THE_NECROMANCER _
	]
	Local $Staff_Mods_Array		= [ _
		$STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE, _
		$STRUCT_MOD_OF_THE_NECROMANCER _
	]
	Local $Bow_Mods_Array		= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER]
	Local $Axe_Mods_Array		= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER]
	Local $Hammer_Mods_Array	= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER]
	Local $Sword_Mods_Array		= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER]
	Local $Dagger_Mods_Array	= [$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER]
	Local $Scythe_Mods_Array	= [ _
		$STRUCT_MOD_ZEALOUS, $STRUCT_MOD_OF_ENCHANTING, $STRUCT_MOD_SUNDERING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER _
	]
	Local $Spear_Mods_Array		= [ _
		$STRUCT_MOD_OF_ENCHANTING, _
		$STRUCT_MOD_OF_THE_NECROMANCER, $STRUCT_MOD_OF_THE_RANGER _
	]
	; Redefining types here remove dependency on GWA2_ID - and we only execute this function once
	Local $ID_Type_Axe							= 2
	Local $ID_Type_Bow							= 5
	Local $ID_Type_Offhand						= 12
	Local $ID_Type_Hammer						= 15
	Local $ID_Type_Wand							= 22
	Local $ID_Type_Shield						= 24
	Local $ID_Type_Staff						= 26
	Local $ID_Type_Sword						= 27
	Local $ID_Type_Dagger						= 32
	Local $ID_Type_Scythe						= 35
	Local $ID_Type_Spear						= 36
	Local Const $All_Weapons_Array				= [$ID_Type_Shield, $ID_Type_Offhand, $ID_Type_Wand, $ID_Type_Staff, $ID_Type_Bow, $ID_Type_Axe, $ID_Type_Hammer, $ID_Type_Sword, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
	Local Const $All_Weapons_Mods_Array			= [$Shield_Mods_Array, $Offhand_Mods_Array, $Wand_Mods_Array, $Staff_Mods_Array, $Bow_Mods_Array, $Axe_Mods_Array, $Hammer_Mods_Array, _
													$Sword_Mods_Array, $Dagger_Mods_Array, $Scythe_Mods_Array, $Spear_Mods_Array]
	Local Const $Weapon_Mods_By_Type[]			= MapFromArrays($All_Weapons_Array, $All_Weapons_Mods_Array)
	Return $Weapon_Mods_By_Type
EndFunc


;~ Creates a map to use to find whether an OS (Old School) weapon ITSELF has perfect mods or not
Func CreatePerfectModsByOSWeaponTypeMap()
	; For martial weapons, only one of those mods is enough to say the weapon is perfect
	; But for zealous strength and vampiric strength, we need to check that it's not the zealous/vampiric mod
	Local $martialWeapons	= [ _
		$STRUCT_INSCRIPTION_STRENGTH_AND_HONOR, _
		$STRUCT_INSCRIPTION_GUIDED_BY_FATE, _
		$STRUCT_INSCRIPTION_DANCE_WITH_DEATH, _
		$STRUCT_INSCRIPTION_I_HAVE_THE_POWER, _
		$STRUCT_INHERENT_ZEALOUS_STRENGTH, _
		$STRUCT_INHERENT_VAMPIRIC_STRENGTH _
	]

	; Those are common to caster weapons and focii
	Local $casterAndFocus	= [ _
		$STRUCT_INHERENT_FIRE_MAGIC_HCT, _
		$STRUCT_INHERENT_FIRE_MAGIC_HSR, _
		$STRUCT_INHERENT_WATER_MAGIC_HCT, _
		$STRUCT_INHERENT_WATER_MAGIC_HSR, _
		$STRUCT_INHERENT_AIR_MAGIC_HCT, _
		$STRUCT_INHERENT_AIR_MAGIC_HSR, _
		$STRUCT_INHERENT_EARTH_MAGIC_HCT, _
		$STRUCT_INHERENT_EARTH_MAGIC_HSR, _
		$STRUCT_INHERENT_ENERGY_STORAGE_HCT, _
		$STRUCT_INHERENT_ENERGY_STORAGE_HSR, _
		$STRUCT_INHERENT_SMITING_PRAYERS_HCT, _
		$STRUCT_INHERENT_SMITING_PRAYERS_HSR, _
		$STRUCT_INHERENT_DIVINE_FAVOR_HCT, _
		$STRUCT_INHERENT_DIVINE_FAVOR_HSR, _
		$STRUCT_INHERENT_HEALING_PRAYERS_HCT, _
		$STRUCT_INHERENT_HEALING_PRAYERS_HSR, _
		$STRUCT_INHERENT_PROTECTION_PRAYERS_HCT, _
		$STRUCT_INHERENT_PROTECTION_PRAYERS_HSR, _
		$STRUCT_INHERENT_CHANNELING_MAGIC_HCT, _
		$STRUCT_INHERENT_CHANNELING_MAGIC_HSR, _
		$STRUCT_INHERENT_RESTORATION_MAGIC_HCT, _
		$STRUCT_INHERENT_RESTORATION_MAGIC_HSR, _
		$STRUCT_INHERENT_COMMUNING_HCT, _
		$STRUCT_INHERENT_COMMUNING_HSR, _
		$STRUCT_INHERENT_SPAWNING_POWER_HCT, _
		$STRUCT_INHERENT_SPAWNING_POWER_HSR, _
		$STRUCT_INHERENT_ILLUSION_MAGIC_HCT, _
		$STRUCT_INHERENT_ILLUSION_MAGIC_HSR, _
		$STRUCT_INHERENT_DOMINATION_MAGIC_HCT, _
		$STRUCT_INHERENT_DOMINATION_MAGIC_HSR, _
		$STRUCT_INHERENT_INSPIRATION_MAGIC_HCT, _
		$STRUCT_INHERENT_INSPIRATION_MAGIC_HSR, _
		$STRUCT_INHERENT_DEATH_MAGIC_HCT, _
		$STRUCT_INHERENT_DEATH_MAGIC_HSR, _
		$STRUCT_INHERENT_BLOOD_MAGIC_HCT, _
		$STRUCT_INHERENT_BLOOD_MAGIC_HSR, _
		$STRUCT_INHERENT_SOUL_REAPING_HCT, _
		$STRUCT_INHERENT_SOUL_REAPING_HSR, _
		$STRUCT_INHERENT_CURSES_HCT, _
		$STRUCT_INHERENT_CURSES_HSR _
	]

	; Those are common to shield and focus - They might be less interesting on one or the other so maybe it will need to be splitted further
	Local $shieldAndFocus	= [ _
		$STRUCT_INSCRIPTION_NOT_THE_FACE, _
		$STRUCT_INSCRIPTION_LEAF_ON_THE_WIND, _
		$STRUCT_INSCRIPTION_LIKE_A_ROLLING_STONE, _
		$STRUCT_INSCRIPTION_SLEEP_NOW_IN_THE_FIRE, _
		$STRUCT_INSCRIPTION_RIDERS_ON_THE_STORM, _
		$STRUCT_INSCRIPTION_THROUGH_THICK_AND_THIN, _
		$STRUCT_INSCRIPTION_THE_RIDDLE_OF_STEEL, _
		$STRUCT_INSCRIPTION_SHELTERED_BY_FAITH, _
		$STRUCT_INSCRIPTION_RUN_FOR_YOUR_LIFE, _
		$STRUCT_INSCRIPTION_LUCK_OF_THE_DRAW, _
		$STRUCT_INHERENT_OF_ILLUSION_MAGIC, _
		$STRUCT_INHERENT_OF_DOMINATION_MAGIC, _
		$STRUCT_INHERENT_OF_INSPIRATION, _
		$STRUCT_INHERENT_OF_BLOOD_MAGIC, _
		$STRUCT_INHERENT_OF_DEATH_MAGIC, _
		$STRUCT_INHERENT_OF_SOUL_REAPING, _
		$STRUCT_INHERENT_OF_CURSE_MAGIC, _
		$STRUCT_INHERENT_OF_AIR_MAGIC, _
		$STRUCT_INHERENT_OF_EARTH_MAGIC, _
		$STRUCT_INHERENT_OF_FIRE_MAGIC, _
		$STRUCT_INHERENT_OF_WATER_MAGIC, _
		$STRUCT_INHERENT_OF_HEALING_PRAYERS, _
		$STRUCT_INHERENT_OF_SMITING_PRAYERS, _
		$STRUCT_INHERENT_OF_PROTECTION_PRAYERS, _
		$STRUCT_INHERENT_OF_DIVINE_FAVOR, _
		$STRUCT_INHERENT_OF_COMMUNING_MAGIC, _
		$STRUCT_INHERENT_OF_RESTORATION_MAGIC, _
		$STRUCT_INHERENT_OF_CHANNELING_MAGIC, _
		$STRUCT_INHERENT_OF_SPAWNING_MAGIC, _
		$STRUCT_INHERENT_ARMOR_VS_UNDEAD, _
		$STRUCT_INHERENT_ARMOR_VS_CHARR, _
		$STRUCT_INHERENT_ARMOR_VS_TROLLS, _
		$STRUCT_INHERENT_ARMOR_VS_PLANTS, _
		$STRUCT_INHERENT_ARMOR_VS_SKELETONS, _
		$STRUCT_INHERENT_ARMOR_VS_GIANTS, _
		$STRUCT_INHERENT_ARMOR_VS_DWARVES, _
		$STRUCT_INHERENT_ARMOR_VS_TENGU, _
		$STRUCT_INHERENT_ARMOR_VS_DEMONS, _
		$STRUCT_INHERENT_ARMOR_VS_DRAGONS, _
		$STRUCT_INHERENT_ARMOR_VS_OGRES, _
		$STRUCT_MOD_OF_DEVOTION, _
		$STRUCT_MOD_OF_ENDURANCE, _
		$STRUCT_MOD_30_HEALTH _
	]

	Local $casterWeapons	= [ _
		$STRUCT_INSCRIPTION_HALE_AND_HEARTY, _
		$STRUCT_INSCRIPTION_HAVE_FAITH, _
		$STRUCT_INSCRIPTION_SEIZE_THE_DAY_1, _
		$STRUCT_INSCRIPTION_SEIZE_THE_DAY_2, _
		$STRUCT_INSCRIPTION_APTITUDE_NOT_ATTITUDE _
	]
	_ArrayAdd($casterWeapons, $casterAndFocus)

	Local $focus	= [ _
		$STRUCT_INSCRIPTION_FORGET_ME_NOT, _
		$STRUCT_INSCRIPTION_HAIL_TO_THE_KING, _
		$STRUCT_INSCRIPTION_FAITH_IS_MY_SHIELD, _
		$STRUCT_INSCRIPTION_LIFE_IS_PAIN, _
		$STRUCT_INSCRIPTION_LIVE_FOR_TODAY_1, _
		$STRUCT_INSCRIPTION_LIVE_FOR_TODAY_2 _
	]
	_ArrayAdd($focus, $casterAndFocus)
	_ArrayAdd($focus, $shieldAndFocus)

	Local $shield	= [ _
		$STRUCT_INSCRIPTION_I_CAN_SEE_CLEARLY_NOW, _
		$STRUCT_INSCRIPTION_SWIFT_AS_THE_WIND, _
		$STRUCT_INSCRIPTION_ONLY_THE_STRONG_SURVIVE _
	]
	_ArrayAdd($shield, $shieldAndFocus)

	; Empty because there are no OS (Old School) scythes and spears
	Local $scytheAndSpear			= []

	; Redefining types here remove dependency on GWA2_ID - and we only execute this function once
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
	Local Const $All_Weapons_Array				= [$ID_Type_Shield, $ID_Type_Offhand, $ID_Type_Wand, $ID_Type_Staff, $ID_Type_Bow, $ID_Type_Axe, $ID_Type_Hammer, $ID_Type_Sword, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
	Local Const $All_Weapons_Mods_Array			= [$shield, $focus, $casterWeapons, $casterWeapons, $martialWeapons, $martialWeapons, $martialWeapons, _
													$martialWeapons, $martialWeapons, $scytheAndSpear, $scytheAndSpear]
	Local Const $Weapon_Mods_By_Type[]			= MapFromArrays($All_Weapons_Array, $All_Weapons_Mods_Array)
	Return $Weapon_Mods_By_Type
EndFunc


;~ Replace valuable runes/insignias/inscriptions/mods default list by the list of elements present in interface
Func RefreshValuableListsFromInterface()
	$ValuableRunesAndInsigniasStructsArray = CreateValuableRunesAndInsigniasArray()
	;$ValuableModsByOSWeaponType = CreateValuableModsByOSWeaponTypeMap()
	$ValuableModsByWeaponType = CreateValuableModsByWeaponTypeMap()
	$ValuableInscriptionsArray = CreateValuableInscriptionsArray()
EndFunc


;~ Creates an array of all valuable runes and insignias based on selected elements in treeview
Func CreateValuableRunesAndInsigniasArray()
	Local $tickedRunesAndInsignias = GetLootOptionsTickedCheckboxes('Keep components.Armor upgrades')
	Local $ValuableRunesAndInsigniasStructsArray[UBound($tickedRunesAndInsignias)]
	For $i = 0 To UBound($tickedRunesAndInsignias) - 1
		Local $varName = StringTrimLeft($tickedRunesAndInsignias[$i], 15) ; removing unnecessary leftmost string with dot "Armor upgrades."
		$varName = 'Struct_' & StringReplace(StringReplace($varName, '.', '_'), ' ', '_') ; conversion of . into _ and spaces into _ and concatenation with prefix 'Struct_'
		$ValuableRunesAndInsigniasStructsArray[$i] = Eval($varName) ; conversion of rune/insignia struct name into its ID
	Next
	Return $ValuableRunesAndInsigniasStructsArray
EndFunc


;~ TODO: finish this function
;~ Creates an array of all valuable OS (Old School without inscription) weapon mods based on selected elements in treeview
Func CreateValuableModsByOSWeaponTypeMap()
	Local $tickedMods = GetLootOptionsTickedCheckboxes('Keep components.Mods')
	Local $ValuableModsByOSWeaponType[UBound($tickedMods)]
	For $tickedMod In $tickedMods
		Info($tickedMods)
	Next
	Return Null
EndFunc


;~ Creates an array of all valuable not OS (Old School) weapon mods based on selected elements in treeview
Func CreateValuableModsByWeaponTypeMap()
	Local $tickedMods = GetLootOptionsTickedCheckboxes('Keep components.Mods')

	Local $Shield_Mods_Array[0], $Offhand_Mods_Array[0], $Wand_Mods_Array[0], $Staff_Mods_Array[0], $Bow_Mods_Array[0], $Axe_Mods_Array[0], _
			$Hammer_Mods_Array[0], $Sword_Mods_Array[0], $Dagger_Mods_Array[0], $Scythe_Mods_Array[0], $Spear_Mods_Array[0]

	; Redefining types here remove dependency on GWA2_ID - and we execute this function rarely
	Local $ID_Type_Axe							= 2
	Local $ID_Type_Bow							= 5
	Local $ID_Type_Offhand						= 12
	Local $ID_Type_Hammer						= 15
	Local $ID_Type_Wand							= 22
	Local $ID_Type_Shield						= 24
	Local $ID_Type_Staff						= 26
	Local $ID_Type_Sword						= 27
	Local $ID_Type_Dagger						= 32
	Local $ID_Type_Scythe						= 35
	Local $ID_Type_Spear						= 36

	For $i = 0 To UBound($tickedMods) - 1
		Local $varName = StringTrimLeft($tickedMods[$i], 5) ; removing unnecessary leftmost string with dot "Mods."
		Local $weaponType = StringLeft($varName, StringInStr($varName, '.') - 1) ; extracting string before first dot
		Switch $weaponType
			Case 'Axe'
				$varName = StringReplace($varName, 'Axe.Prefix - Haft.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Axe.Suffix - Grip.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Axe_Mods_Array, Eval($varName))
			Case 'Bow'
				$varName = StringReplace($varName, 'Bow.Prefix - String.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Bow.Suffix - Grip.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Bow_Mods_Array, Eval($varName))
			Case 'Dagger'
				$varName = StringReplace($varName, 'Dagger.Prefix - Tang.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Dagger.Suffix - Handle.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Dagger_Mods_Array, Eval($varName))
			Case 'Focus'
				$varName = StringReplace($varName, 'Focus.Suffix - Core.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Offhand_Mods_Array, Eval($varName))
			Case 'Hammer'
				$varName = StringReplace($varName, 'Hammer.Prefix - Haft.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Hammer.Suffix - Grip.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Hammer_Mods_Array, Eval($varName))
			Case 'Scythe'
				$varName = StringReplace($varName, 'Scythe.Prefix - Snathe.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Scythe.Suffix - Grip.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Scythe_Mods_Array, Eval($varName))
			Case 'Shield'
				$varName = StringReplace($varName, 'Shield.Suffix - Handle.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Shield_Mods_Array, Eval($varName))
			Case 'Spear'
				$varName = StringReplace($varName, 'Spear.Prefix - Head.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Spear.Suffix - Grip.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Spear_Mods_Array, Eval($varName))
			Case 'Staff'
				$varName = StringReplace($varName, 'Staff.Prefix - Head.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Staff.Suffix - Wrapping.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Staff_Mods_Array, Eval($varName))
			Case 'Sword'
				$varName = StringReplace($varName, 'Sword.Prefix - Hilt.', 'STRUCT_MOD_')
				$varName = StringReplace($varName, 'Sword.Suffix - Pommel.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Sword_Mods_Array, Eval($varName))
			Case 'Wand'
				$varName = StringReplace($varName, 'Wand.Suffix - Wrapping.', 'STRUCT_MOD_')
				$varName = ModNameCleanupHelper($varName)
				_ArrayAdd($Wand_Mods_Array, Eval($varName))
		EndSwitch
	Next

	Local Const $All_Weapons_Array				= [$ID_Type_Shield, $ID_Type_Offhand, $ID_Type_Wand, $ID_Type_Staff, $ID_Type_Bow, $ID_Type_Axe, $ID_Type_Hammer, $ID_Type_Sword, $ID_Type_Dagger, $ID_Type_Scythe, $ID_Type_Spear]
	Local Const $All_Weapons_Mods_Array			= [$Shield_Mods_Array, $Offhand_Mods_Array, $Wand_Mods_Array, $Staff_Mods_Array, $Bow_Mods_Array, $Axe_Mods_Array, $Hammer_Mods_Array, _
													$Sword_Mods_Array, $Dagger_Mods_Array, $Scythe_Mods_Array, $Spear_Mods_Array]
	Local Const $Weapon_Mods_By_Type[]			= MapFromArrays($All_Weapons_Array, $All_Weapons_Mods_Array)
	Return $Weapon_Mods_By_Type
EndFunc


Func ModNameCleanupHelper($modName)
	$modName = StringRegExpReplace($modName, "\s*\(.*?\)", "") ; cleanup of all parentheses and contents in them
	$modName = StringReplace($modName, ' ', '_') ; conversion of spaces into _
	$modName = StringUpper($modName) ; conversion of all letters into uppercase to better match mod struct names constants
	Return $modName
EndFunc


;~ Creates an array of all valuable inscriptions based on selected elements in treeview
Func CreateValuableInscriptionsArray()
	Local $tickedInscriptions = GetLootOptionsTickedCheckboxes('Keep components.Inscriptions')
	Local $ValuableInscriptionsArray[UBound($tickedInscriptions)]
	For $i = 0 To UBound($tickedInscriptions) - 1
		Local $varName = $tickedInscriptions[$i]
		$varName = StringReplace($varName, 'Inscriptions.Common.', 'STRUCT_INSCRIPTION_')
		$varName = StringReplace($varName, 'Inscriptions.Weapon.Common.', 'STRUCT_INSCRIPTION_')
		$varName = StringReplace($varName, 'Inscriptions.Weapon.Martial.', 'STRUCT_INSCRIPTION_')
		$varName = StringReplace($varName, 'Inscriptions.Weapon.Spellcasting.', 'STRUCT_INSCRIPTION_')
		$varName = StringReplace($varName, 'Inscriptions.Offhand.Focus.', 'STRUCT_INSCRIPTION_')
		$varName = StringReplace($varName, 'Inscriptions.Offhand.Focus and shield.', 'STRUCT_INSCRIPTION_')
		$varName = ModNameCleanupHelper($varName)
		$ValuableInscriptionsArray[$i] = Eval($varName) ; conversion of inscription struct name into its ID
	Next
	Return $ValuableInscriptionsArray
EndFunc
#EndRegion Struct Utils