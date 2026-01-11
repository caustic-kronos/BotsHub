#CS ===========================================================================
==================================================
|	Fissure Of Woe Tower of Courage farm Bot	|
|	Authors: Zaishen/RiflemanX/Monk Reborn		|
|	Rewrite Author for BotsHub: Gahais			|
==================================================
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
;
; Fissure of Woe farm of Obsidian Shards in Tower of Courage location based on below article:
https://gwpvx.fandom.com/wiki/Build:R/A_Whirling_Defense_Farmer
; Run this farm bot as Ranger
;
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)


#Region Configuration
; === Build ===
Global Const $RA_FOW_TOC_FARMER_SKILLBAR = 'OgcTc5+8ZSn5AimsBCB6uU4IuE'

Global Const $FOW_TOC_SHADOWFORM			= 1
Global Const $FOW_TOC_SHROUD_OF_DISTRESS	= 2
Global Const $FOW_TOC_I_AM_UNSTOPPABLE		= 3
Global Const $FOW_TOC_DARK_ESCAPE			= 4
Global Const $FOW_TOC_HEART_OF_SHADOW		= 5
Global Const $FOW_TOC_DWARVEN_STABILITY		= 6
Global Const $FOW_TOC_WHIRLING_DEFENSE		= 7
Global Const $FOW_TOC_MENTAL_BLOCK			= 8

Global Const $FOW_TOC_SKILLS_ARRAY			= [$FOW_TOC_SHADOWFORM, $FOW_TOC_SHROUD_OF_DISTRESS, $FOW_TOC_I_AM_UNSTOPPABLE, $FOW_TOC_DARK_ESCAPE, $FOW_TOC_HEART_OF_SHADOW, $FOW_TOC_DWARVEN_STABILITY, $FOW_TOC_WHIRLING_DEFENSE, $FOW_TOC_MENTAL_BLOCK]
Global Const $FOW_TOC_SKILLS_COSTS_ARRAY	= [5,					10,							5,						5,					5,						5,						4,						10]
Global Const $FOW_TOC_SKILLS_COSTS_MAP		= MapFromArrays($FOW_TOC_SKILLS_ARRAY, $FOW_TOC_SKILLS_COSTS_ARRAY)
#EndRegion Configuration

; ==== Constants ====
Global Const $FOW_TOC_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- Armor with HP/Energy runes and 5 blessed insignias (+50 armor when enchanted)' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- A shield with the inscription ''Through Thick and Thin'' (+10 armor against piercing damage) and +45 health while enchanted or in stance' & @CRLF _
	& '- At least 5th level in Deldrimor, Asura and Norn reputation ranks' & @CRLF _
	& ' ' & @CRLF _
	& 'This bot farms obsidian shards in Tower of Courage in Fissure of Woe location in normal mode. Hard mode might be too hard for this bot' & @CRLF _
	& 'Solo farm using Ranger based on below article' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:R/A_Whirling_Defense_Farmer' & @CRLF _
	& 'If you have FoW scrolls then can set in GUI to enter FoW only through FoW scrolls and stop the bot when FoW scrolls run out' & @CRLF _
	& 'It is recommended to run this farm mostly during weeks with Pantheon bonus active which gives free entry to FoW and UW' & @CRLF _
	& 'Because otherwise this farm bot can flush gold storage to 0. However income from obsidian shards, dark remains, etc. can outweigh platinum cost' & @CRLF
Global Const $FOW_TOC_FARM_DURATION = 3 * 60 * 1000
Global Const $MAX_FOW_TOC_FARM_DURATION = 6 * 60 * 1000

Global $fow_toc_move_options = CloneDictMap($Default_MoveDefend_Options)
$fow_toc_move_options.Item('defendFunction')		= DefendFoWToC
$fow_toc_move_options.Item('moveTimeOut')			= 5 * 60 * 1000
$fow_toc_move_options.Item('randomFactor')			= 25
$fow_toc_move_options.Item('hosSkillSlot')			= $FOW_TOC_HEART_OF_SHADOW
$fow_toc_move_options.Item('deathChargeSkillSlot')	= 0
$fow_toc_move_options.Item('openChests')			= False

Global Const $FOW_TOC_MODELID_SHADOW_MESMER		= 2855
Global Const $FOW_TOC_MODELID_SHADOW_ELEMENTAL	= 2856
Global Const $FOW_TOC_MODELID_SHADOW_MONK			= 2857
Global Const $FOW_TOC_MODELID_SHADOW_WARRIOR		= 2858
Global Const $FOW_TOC_MODELID_SHADOW_RANGER		= 2859
Global Const $FOW_TOC_MODELID_SHADOW_BEAST		= 2860
Global Const $FOW_TOC_MODELID_ABYSSAL			= 2861

Global $fow_toc_farm_setup = False

;~ Main method to farm Fissure of Woe - Tower of Courage
Func FoWToCFarm()
	If Not $fow_toc_farm_setup And SetupFoWToCFarm() == $FAIL Then Return $PAUSE

	Local $result = EnterFissureOfWoe()
	If $result <> $SUCCESS Then Return $result
	$result = FoWToCFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared FoW Tower of Courage mobs')
	If $result == $FAIL Then Info('Player died. Could not clear FoW Tower of Courage mobs')
	TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name)
	Return $result
EndFunc


;~ Fissure of Woe - Tower of Courage farm setup
Func SetupFoWToCFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFowToCFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	Sleep(500 + GetPing())
	$fow_toc_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFowToCFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($RA_FOW_TOC_FARMER_SKILLBAR)
	Else
		Warn('You need to run this farm bot as Ranger')
		Return $FAIL
	EndIf
	Sleep(250 + GetPing())
	Return $SUCCESS
EndFunc


;~ Farm loop
Func FoWToCFarmLoop()
	Local $me = Null, $target = Null
	If GetMapID() <> $ID_FISSURE_OF_WOE Then Return $FAIL
	Info('Starting Farm')
	$run_timer = TimerInit()
	Info('Moving to initial spot')

	UseSkillEx($FOW_TOC_SHADOWFORM)
	UseSkillEx($FOW_TOC_DWARVEN_STABILITY)
	Sleep(500 + GetPing())
	; dark escape can be replaced with other skill like great dwarf armor to increase survivability at the cost of farm speed
	UseSkillEx($FOW_TOC_DARK_ESCAPE)
	If MoveDefendingFoWToC(-21131, -2390) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-16494, -3113) == $STUCK Then Return $FAIL

	If IsPlayerDead() Then Return $FAIL
	Info('Balling abyssals')
	Sleep(500 + GetPing())
	If MoveDefendingFoWToC(-14453, -3536) == $STUCK Then Return $FAIL
	Info('Recharging skills and energy')
	While Not IsRecharged($FOW_TOC_DWARVEN_STABILITY) Or Not IsRecharged($FOW_TOC_WHIRLING_DEFENSE) Or GetEnergy() < 20
		If CheckStuck('Recharging skills', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
		DefendFoWToC()
	WEnd
	If IsRecharged($FOW_TOC_I_AM_UNSTOPPABLE) And GetEffectTimeRemaining(GetEffect($FOW_TOC_I_AM_UNSTOPPABLE)) == 0 Then UseSkillEx($FOW_TOC_I_AM_UNSTOPPABLE)
	; recharging energy to cast Dwarven Stability and Whirling Defense
	While GetEnergy() < 9
		If CheckStuck('Recharging energy', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
		Sleep(500)
	WEnd
	Info('Fighting abyssals')
	UseSkillEx($FOW_TOC_DWARVEN_STABILITY)
	Sleep(1000 + GetPing())
	UseSkillEx($FOW_TOC_WHIRLING_DEFENSE)
	If MoveDefendingFoWToC(-13684, -2077) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14113, -418) == $STUCK Then Return $FAIL
	If IsRecharged($FOW_TOC_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() > 10 Then UseSkillEx($FOW_TOC_MENTAL_BLOCK)
	Sleep(1000 + GetPing())
	While GetEffectTimeRemaining(GetEffect($ID_WHIRLING_DEFENSE)) > 0
		If CheckStuck('Fighting Abyssals', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
		DefendFoWToC()
	WEnd
	Info('Abyssals cleared. Picking up loot')
	If IsPlayerAlive() Then PickUpItems(CastBuffsFowToC)
	Sleep(500)
	If MoveDefendingFoWToC(-13684, -2077) == $STUCK Then Return $FAIL

	If IsPlayerDead() Then Return $FAIL
	Info('Balling rangers')
	If MoveDefendingFoWToC(-15826, -3046) == $STUCK Then Return $FAIL
	RandomSleep(1500)
	If MoveDefendingFoWToC(-16002, -3031) == $STUCK Then Return $FAIL
	Info('Recharging skills and energy')
	While Not IsRecharged($FOW_TOC_DWARVEN_STABILITY) Or Not IsRecharged($FOW_TOC_WHIRLING_DEFENSE) Or GetEnergy() < 20
		If CheckStuck('Recharging skills', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
		DefendFoWToC()
	WEnd
	If MoveDefendingFoWToC(-16004, -3202) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-15272, -3004) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14453, -3536) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14209, -2935) == $STUCK Then Return $FAIL
	; this spot is supposed to have all shadow rangers in it
	;If MoveDefendingFoWToC(-14535, -2615) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14454, -2601) == $STUCK Then Return $FAIL
	; if shadow rangers somehow are not in the spot then try to get closer to them
	$me = GetMyAgent()
	; getting closer to nearest shadow ranger, not nearest abyssal
	$target = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, IsShadowRangerFoWToC)
	; assuming that player is wearing sword or axe of enchanting
	Attack($target)
	; recharging energy to cast Dwarven Stability and Whirling Defense
	While GetEnergy() < 9
		If CheckStuck('Recharging energy', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
		Sleep(500)
	WEnd
	Info('Fighting rangers')
	UseSkillEx($FOW_TOC_DWARVEN_STABILITY)
	Sleep(1000 + GetPing())
	UseSkillEx($FOW_TOC_WHIRLING_DEFENSE)
	If IsRecharged($FOW_TOC_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And GetEnergy() > 10 Then UseSkillEx($FOW_TOC_MENTAL_BLOCK)
	If IsRecharged($FOW_TOC_I_AM_UNSTOPPABLE) And GetEffectTimeRemaining(GetEffect($FOW_TOC_I_AM_UNSTOPPABLE)) == 0 Then UseSkillEx($FOW_TOC_I_AM_UNSTOPPABLE)
	Sleep(1000 + GetPing())
	While GetEffectTimeRemaining(GetEffect($ID_WHIRLING_DEFENSE)) > 0
		If CheckStuck('Fighting Rangers', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
		DefendFoWToC(False)
	WEnd
	If IsPlayerAlive() Then
		Info('Rangers cleared. Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(CastBuffsFowToC)
			Sleep(GetPing())
		Next
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


Func IsShadowRangerFoWToC($agent)
	Return EnemyAgentFilter($agent) And (DllStructGetData($agent, 'ModelID') == $FOW_TOC_MODELID_SHADOW_RANGER)
EndFunc


Func MoveDefendingFoWToC($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $fow_toc_move_options)
EndFunc


Func CastBuffsFowToC()
	If IsPlayerDead() Then Return $FAIL

	If IsRecharged($FOW_TOC_SHADOWFORM) Then UseSkillEx($FOW_TOC_SHADOWFORM)
	; start using 'I Am Unstoppable', 'Shroud of Distress' and 'Mental Block' skill only after 20 seconds of farm when starting aggroing abyssals which can knock down the player
	If TimerDiff($run_timer) > 20000 Then
		If IsRecharged($FOW_TOC_I_AM_UNSTOPPABLE) Then UseSkillEx($FOW_TOC_I_AM_UNSTOPPABLE)
		If IsRecharged($FOW_TOC_SHROUD_OF_DISTRESS) Then UseSkillEx($FOW_TOC_SHROUD_OF_DISTRESS)
		If IsRecharged($FOW_TOC_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 And (GetEnergy() > 20) Then
			UseSkillEx($FOW_TOC_MENTAL_BLOCK)
		EndIf
	EndIf

	Return $SUCCESS
EndFunc


; $useHoSSkill == False to not use heart of shadow on rangers, because they don't follow player to adjacent range
Func DefendFoWToC($useHoSSkill = True)
	If CastBuffsFowToC() == $FAIL Then Return $FAIL

	If $useHoSSkill Then
		Local $me = GetMyAgent()

		If DllStructGetData($me, 'HealthPercent') < 0.3 Or _
				(DllStructGetData($me, 'HealthPercent') < 0.4 And GetHasCondition($me)) Then
			UseSkillEx($FOW_TOC_HEART_OF_SHADOW)
			Sleep(500 + GetPing())
		EndIf
	EndIf

	RandomSleep(250)
	Return $SUCCESS
EndFunc