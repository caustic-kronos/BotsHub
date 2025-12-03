#CS ===========================================================================
==================================================
|  	 Fissure Of Woe Tower of Courage farm Bot	 |
|	  Authors: Zaishen/RiflemanX/Monk Reborn	 |
|	    Rewrite Author for BotsHub: Gahais		 |
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
Global Const $RAFoWToCFarmerSkillBar = 'OgcTc5+8ZSn5AimsBCB6uU4IuE'

Global Const $FoWToC_ShadowForm			= 1
Global Const $FoWToC_ShroudOfDistress	= 2
Global Const $FoWToC_IAmUnstoppable		= 3
Global Const $FoWToC_DarkEscape			= 4
Global Const $FoWToC_HeartOfShadow		= 5
Global Const $FoWToC_DwarvenStability	= 6
Global Const $FoWToC_WhirlingDefense	= 7
Global Const $FoWToC_MentalBlock		= 8

Global Const $FoWToC_SkillsArray 		= [$FoWToC_ShadowForm, $FoWToC_ShroudOfDistress, $FoWToC_IAmUnstoppable, $FoWToC_DarkEscape, $FoWToC_HeartOfShadow, $FoWToC_DwarvenStability, $FoWToC_WhirlingDefense, $FoWToC_MentalBlock]
Global Const $FoWToC_SkillsCostsArray 	= [5,				   10,						 5,						 5,					 5,						5,						  4,					   10]
Global Const $FoWToCSkillsCostsMap = MapFromArrays($FoWToC_SkillsArray, $FoWToC_SkillsCostsArray)
#EndRegion Configuration

; ==== Constants ====
Global Const $FoWToCFarmInformations = 'For best results, have :' & @CRLF _
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
Global $FowToCFarmTimer = Null
Global $FOW_TOC_FARM_SETUP = False

Global $FoWToCMoveOptions = CloneDictMap($Default_MoveDefend_Options)
$FoWToCMoveOptions.Item('defendFunction')		= DefendFoWToC
$FoWToCMoveOptions.Item('moveTimeOut')			= 5 * 60 * 1000
$FoWToCMoveOptions.Item('randomFactor')			= 25
$FoWToCMoveOptions.Item('hosSkillSlot')			= $FoWToC_HeartOfShadow
$FoWToCMoveOptions.Item('deathChargeSkillSlot')	= 0
$FoWToCMoveOptions.Item('openChests')			= False

Global Const $FoWToC_ModelID_ShadowMesmer		= 2804
Global Const $FoWToC_ModelID_ShadowElemental	= 2805
Global Const $FoWToC_ModelID_ShadowMonk			= 2806
Global Const $FoWToC_ModelID_ShadowWarrior		= 2807
Global Const $FoWToC_ModelID_ShadowRanger		= 2808
Global Const $FoWToC_ModelID_ShadowBeast		= 2809
Global Const $FoWToC_ModelID_Abyssal			= 2810

;~ Main method to farm Fissure of Woe - Tower of Courage
Func FoWToCFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $FOW_TOC_FARM_SETUP And SetupFoWToCFarm() == $FAIL Then Return $PAUSE
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Local $result = EnterFissureOfWoeToC()
	If $result <> $SUCCESS Then Return $result
	$result = FoWToCFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared FoW Tower of Courage mobs')
	If $result == $FAIL Then Info('Player died. Could not clear FoW Tower of Courage mobs')
	TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Fissure of Woe - Tower of Courage farm setup
Func SetupFoWToCFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Temple_of_the_Ages Then
		If TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFowToCFarm() == $FAIL Then Return $FAIL
	LeaveParty() ; solo farmer
	Sleep(500 + GetPing())
	$FOW_TOC_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func SetupPlayerFowToCFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Ranger Then
		LoadSkillTemplate($RAFoWToCFarmerSkillBar)
	Else
		Warn('You need to run this farm bot as Ranger')
		Return $FAIL
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func EnterFissureOfWoeToC()
	If GetMapID() <> $ID_Temple_of_the_Ages Then TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	If GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED Then
		Info('Using scroll to enter Fissure of Woe')
		Local $fowScroll = GetItemByModelID($ID_FoW_Scroll)
		If DllStructGetData($fowScroll, 'Slot') > 0 Then ; slots are numbered from 1, if scroll is not in any bag then Slot is 0
			UseItem($fowScroll)
			WaitMapLoading($ID_Fissure_of_Woe)
			If GetMapID() <> $ID_Fissure_of_Woe Then
				Warn('Used scroll but still could not enter Fissure of Woe. Ensure that player has correct scroll in inventory')
				Return $PAUSE
			EndIf
		Else
			Warn('Could not find scroll to enter Fissure of Woe in player''s inventory')
			Return $PAUSE
		EndIf
	Else ; not using scroll method to enter Fissure of Woe
		Info('Going to Balthazar statue to enter Fissure of Woe')
		MoveTo(-2500, 18700)
		SendChat('/kneel', '')
		RandomSleep(GetPing() + 3000)
		GoToNPC(GetNearestNPCToCoords(-2500, 18700))
		RandomSleep(GetPing() + 750)
		Dialog(0x85) ; entering FoW dialog option
		RandomSleep(GetPing() + 750)
		Dialog(0x86) ; accepting dialog option
		RandomSleep(GetPing() + 750)
		WaitMapLoading($ID_Fissure_of_Woe)
		If GetMapID() <> $ID_Fissure_of_Woe Then
			Info('Could not enter Fissure of Woe. Ensure that it''s Pantheon bonus week or that player has enough gold in inventory')
			Return $FAIL
		EndIf
	EndIf
	Return $SUCCESS
EndFunc


;~ Farm loop
Func FoWToCFarmLoop()
	Local $me = Null, $target = Null
	Sleep(500 + GetPing())
	If GetMapID() <> $ID_Fissure_of_Woe Then Return $FAIL
	If IsPlayerDead() Then Return $FAIL
	Info('Starting Farm')
	$FowToCFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run
	Info('Moving to initial spot')

	UseSkillEx($FoWToC_ShadowForm)
	UseSkillEx($FoWToC_DwarvenStability)
	Sleep(500 + GetPing())
	UseSkillEx($FoWToC_DarkEscape) ; dark escape can be replaced with other skill like great dwarf armor to increase survivability at the cost of farm speed
	If MoveDefendingFoWToC(-21131, -2390) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-16494, -3113) == $STUCK Then Return $FAIL

	If IsPlayerDead() Then Return $FAIL
	Info('Balling abyssals')
	Sleep(500 + GetPing())
	If MoveDefendingFoWToC(-14453, -3536) == $STUCK Then Return $FAIL
	Info('Recharging skills and energy')
	While Not IsRecharged($FoWToC_DwarvenStability) Or Not IsRecharged($FoWToC_WhirlingDefense) Or GetEnergy() < 20
		If IsPlayerDead() Or TimerDiff($FowToCFarmTimer) > $MAX_FOW_TOC_FARM_DURATION Then Return $FAIL
		DefendFoWToC()
	WEnd
	If IsRecharged($FoWToC_IAmUnstoppable) And GetEffectTimeRemaining(GetEffect($FoWToC_IAmUnstoppable)) == 0 Then UseSkillEx($FoWToC_IAmUnstoppable)
	While GetEnergy() < 9 ; recharging energy to cast Dwarven Stability and Whirling Defense
		If IsPlayerDead() Or TimerDiff($FowToCFarmTimer) > $MAX_FOW_TOC_FARM_DURATION Then Return $FAIL
		Sleep(500)
	WEnd
	Info('Fighting abyssals')
	UseSkillEx($FoWToC_DwarvenStability)
	Sleep(1000 + GetPing())
	UseSkillEx($FoWToC_WhirlingDefense)
	If MoveDefendingFoWToC(-13684, -2077) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14113, -418) == $STUCK Then Return $FAIL
	If IsRecharged($FoWToC_MentalBlock) And GetEffectTimeRemaining(GetEffect($ID_Mental_Block)) == 0 And GetEnergy() > 10 Then UseSkillEx($FoWToC_MentalBlock)
	Sleep(1000 + GetPing())
	While GetEffectTimeRemaining(GetEffect($ID_Whirling_Defense)) > 0
		If IsPlayerDead() Or TimerDiff($FowToCFarmTimer) > $MAX_FOW_TOC_FARM_DURATION Then Return $FAIL
		DefendFoWToC()
	WEnd
	Info('Abyssals cleared. Picking up loot')
	If IsPlayerAlive() Then PickUpItems(CastBuffsFowToC, DefaultShouldPickItem, $RANGE_SPIRIT)
	Sleep(500)
	If MoveDefendingFoWToC(-13684, -2077) == $STUCK Then Return $FAIL

	If IsPlayerDead() Then Return $FAIL
	Info('Balling rangers')
	If MoveDefendingFoWToC(-15826, -3046) == $STUCK Then Return $FAIL
	RandomSleep(1500)
	If MoveDefendingFoWToC(-16002, -3031) == $STUCK Then Return $FAIL
	Info('Recharging skills and energy')
	While Not IsRecharged($FoWToC_DwarvenStability) Or Not IsRecharged($FoWToC_WhirlingDefense) Or GetEnergy() < 20
		If IsPlayerDead() Or TimerDiff($FowToCFarmTimer) > $MAX_FOW_TOC_FARM_DURATION Then Return $FAIL
		DefendFoWToC()
	WEnd
	If MoveDefendingFoWToC(-16004, -3202) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-15272, -3004) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14453, -3536) == $STUCK Then Return $FAIL
	If MoveDefendingFoWToC(-14209, -2935) == $STUCK Then Return $FAIL
	;If MoveDefendingFoWToC(-14535, -2615) == $STUCK Then Return $FAIL ; this spot is supposed to have all shadow rangers in it
	If MoveDefendingFoWToC(-14454, -2601) == $STUCK Then Return $FAIL ; this spot is supposed to have all shadow rangers in it
	; if shadow rangers somehow are not in the spot then try to get closer to them
	$me = GetMyAgent()
	$target = GetNearestAgentToAgent($me, 0xDB, IsShadowRangerFoWToC) ; getting closer to nearest shadow ranger, not nearest abyssal
	Attack($target) ; assuming that player is wearing sword or axe of enchanting
	While GetEnergy() < 9 ; recharging energy to cast Dwarven Stability and Whirling Defense
		If IsPlayerDead() Or TimerDiff($FowToCFarmTimer) > $MAX_FOW_TOC_FARM_DURATION Then Return $FAIL
		Sleep(500)
	WEnd
	Info('Fighting rangers')
	UseSkillEx($FoWToC_DwarvenStability)
	Sleep(1000 + GetPing())
	UseSkillEx($FoWToC_WhirlingDefense)
	If IsRecharged($FoWToC_MentalBlock) And GetEffectTimeRemaining(GetEffect($ID_Mental_Block)) == 0 And GetEnergy() > 10 Then UseSkillEx($FoWToC_MentalBlock)
	If IsRecharged($FoWToC_IAmUnstoppable) And GetEffectTimeRemaining(GetEffect($FoWToC_IAmUnstoppable)) == 0 Then UseSkillEx($FoWToC_IAmUnstoppable)
	Sleep(1000 + GetPing())
	While GetEffectTimeRemaining(GetEffect($ID_Whirling_Defense)) > 0
		If IsPlayerDead() Or TimerDiff($FowToCFarmTimer) > $MAX_FOW_TOC_FARM_DURATION Then Return $FAIL
		DefendFoWToC(False)
	WEnd
	Info('Rangers cleared. Picking up loot')
	If IsPlayerAlive() Then PickUpItems(CastBuffsFowToC, DefaultShouldPickItem, $RANGE_SPIRIT)
	Sleep(500 + GetPing())

	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func IsShadowRangerFoWToC($agent)
	Return EnemyAgentFilter($agent) And (DllStructGetData($agent, 'ModelID') == $FoWToC_ModelID_ShadowRanger)
EndFunc


Func MoveDefendingFoWToC($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $FoWToCMoveOptions)
EndFunc


Func CastBuffsFowToC()
	If IsPlayerDead() Then Return $FAIL

	If IsRecharged($FoWToC_ShadowForm) Then UseSkillEx($FoWToC_ShadowForm)
	; start using 'I Am Unstoppable', 'Shroud of Distress' and 'Mental Block' skill only after 20 seconds of farm when starting aggroing abyssals which can knock down the player
	If TimerDiff($FowToCFarmTimer) > 20000 Then
		If IsRecharged($FoWToC_IAmUnstoppable) Then UseSkillEx($FoWToC_IAmUnstoppable)
		If IsRecharged($FoWToC_ShroudOfDistress) Then UseSkillEx($FoWToC_ShroudOfDistress)
		If IsRecharged($FoWToC_MentalBlock) And GetEffectTimeRemaining(GetEffect($ID_Mental_Block)) == 0 And (GetEnergy() > 20) Then
			UseSkillEx($FoWToC_MentalBlock)
		EndIf
	EndIf

	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func DefendFoWToC($useHoSSkill = True) ; $useHoSSkill == False to not use heart of shadow on rangers, because they don't follow player to adjacent range
	If IsPlayerDead() Then Return $FAIL

	CastBuffsFowToC()

	If $useHoSSkill Then ; can use heart of shadow skill
		Local $me = GetMyAgent()

		If DllStructGetData($me, 'HealthPercent') < 0.3 Or _
				(DllStructGetData($me, 'HealthPercent') < 0.4 And GetHasCondition($me)) Then
			UseSkillEx($FoWToC_HeartOfShadow)
			Sleep(500 + GetPing())
		EndIf
	EndIf

	RandomSleep(250)
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc