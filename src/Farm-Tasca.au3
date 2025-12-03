#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
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
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils-OmniFarmer.au3'

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $TascaDervishChestRunnerSkillbar = 'OgejwyezHT8I6MHQ3l0kNQ4OIQ'
Global Const $TascaAssassinChestRunnerSkillbar = 'OwBj4xf84Q8I6MHQ3l0kNQ4OIQ'
Global Const $TascaMesmerChestRunnerSkillbar = 'OQdTAmP7ZiHRn5A6ukmsBC3BBC'
Global Const $TascaElementalistChestRunnerSkillbar = 'OgdTw4P7HiHRn5A6ukmsBC3BBC'
Global Const $TascaMonkChestRunnerSkillbar = 'OwcTAnP7ZiHRn5A6ukmsBC3BBC'
Global Const $TascaNecromancerChestRunnerSkillbar = 'OAdT8Z/YYiHRn5A6ukmsBC3BBC'
Global Const $TascaRitualistChestRunnerSkillbar = 'OAej8xeM5Q8I6MHQ3l0kNQ4OIQ'
Global $TascaPlayerProfession = $ID_Dervish ; global variable to remember player's profession in setup

Global Const $TascaChestRunInformations = 'For best results, have :' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 16 in Mysticism if playing Dervish' & @CRLF _
	& '- 3 in Deadly Arts' & @CRLF _
	& '- A staff +20e and +20% enchantment duration' & @CRLF _
	& '- caster weapons on all heroes' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 3m
Global Const $TASCA_FARM_DURATION = (3 * 60) * 1000
Global $TASCA_FARM_SETUP = False

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Tasca_DwarvenStability) is better than UseSkillEx(1))
Global Const $Tasca_DeadlyParadox		= 1
Global Const $Tasca_ShadowForm			= 2
Global Const $Tasca_ShroudOfDistress	= 3
Global Const $Tasca_DwarvenStability	= 4
Global Const $Tasca_IAmUnstoppable		= 5
Global Const $Tasca_DarkEscape			= 6
Global Const $Tasca_DeathsCharge		= 7
Global Const $Tasca_HeartOfShadow		= 8

Global Const $TASCA_CHEST_RANGE = 1.5 * $RANGE_SPELLCAST


;~ Main method to chest farm Tasca
Func TascaChestFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $TASCA_FARM_SETUP And SetupTascaChestFarm() == $FAIL THen Return $PAUSE
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToTascasDemise()
	Local $result = TascaChestFarmLoop($STATUS)
	ReturnBackToOutpost($ID_The_Granite_Citadel)
	Return $result
EndFunc


;~ Tasca chest farm setup
Func SetupTascaChestFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_The_Granite_Citadel Then TravelToOutpost($ID_The_Granite_Citadel, $DISTRICT_NAME)
	UseCitySpeedBoost()
	If SetupPlayerTascaChestFarm() == $FAIL Then Return $FAIL
	SetupTeamTascaChestFarm()
	SwitchToHardModeIfEnabled()

	GoToTascasDemise()
	MoveTo(-9250, 19850)
	Move(-10000, 18875)
	RandomSleep(1000)
	WaitMapLoading($ID_The_Granite_Citadel, 10000, 1000)
	$TASCA_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerTascaChestFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_Dervish
			$TascaPlayerProfession = $ID_Dervish
			LoadSkillTemplate($TascaDervishChestRunnerSkillbar)
		Case $ID_Assassin
			$TascaPlayerProfession = $ID_Assassin
			LoadSkillTemplate($TascaAssassinChestRunnerSkillbar)
		Case $ID_Mesmer
			$TascaPlayerProfession = $ID_Mesmer
			LoadSkillTemplate($TascaMesmerChestRunnerSkillbar)
		Case $ID_Monk
			$TascaPlayerProfession = $ID_Monk
			LoadSkillTemplate($TascaMonkChestRunnerSkillbar)
		Case $ID_Elementalist
			$TascaPlayerProfession = $ID_Elementalist
			LoadSkillTemplate($TascaElementalistChestRunnerSkillbar)
		Case $ID_Necromancer
			$TascaPlayerProfession = $ID_Necromancer
			LoadSkillTemplate($TascaNecromancerChestRunnerSkillbar)
		Case $ID_Ritualist
			$TascaPlayerProfession = $ID_Ritualist
			LoadSkillTemplate($TascaRitualistChestRunnerSkillbar)
		Case Else
    		Warn('Should run this farm as Dervish, Assassin, Mesmer, Monk, Elementalist, Necromancer or Ritualist'
			Return $FAIL
	EndSwitch
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamTascaChestFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Setting up team according to default settings')
		OmniFarmFullSetup()
	EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
    	Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


;~ Move out of outpost into Tasca's Demise
Func GoToTascasDemise()
	If GetMapID() <> $ID_The_Granite_Citadel Then TravelToOutpost($ID_The_Granite_Citadel, $DISTRICT_NAME)
	While GetMapID() <> $ID_Tascas_Demise
		Info('Moving to Tasca''s Demise')
		MoveTo(-10000, 18875)
		Move(-9250, 19850)
		RandomSleep(1000)
		WaitMapLoading($ID_Tascas_Demise, 10000, 2000)
	WEnd
EndFunc


;~ Tasca Chest farm loop
Func TascaChestFarmLoop($STATUS)
	If FindInInventory($ID_Lockpick)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $ID_Tascas_Demise Then Return $FAIL

	Info('Starting chest run')
	UseConsumable($ID_Birthday_Cupcake, True)
	; Calling it here to already use shroud of distress and dwarven stability and have enough mana later on
	CommandAll(-11300, 21389)
	TascaDefendFunction(0, 0)
	Move(-4000, 19000)
	Sleep(10000)
	PrepareZephyrSpirit()
	RegisterBurstHealingUnit()

	Local $openedChests = 0
	;ToggleMapping(2)
	TascaChestRun(-2000, 17500)
	TascaChestRun(1000, 16500)
	Info('#1/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(3000, 15000)
	TascaChestRun(5900, 14500)
	Local $annoyingChest = ScanForChests(2000, True, 5500, 18000)
	Notice('Bonus chest ? ' & ($annoyingChest <> Null))
	TascaChestRun(6750, 14500)
	Info('#2/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(8000, 15000)
	TascaChestRun(9500, 16000)
	TascaChestRun(10500, 18000)
	Info('#3/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(11500, 19500)
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(12500, 21000)
	; Very far chests here, spirit range is needed
	Info('#4/13')
	$openedChests += FindAndOpenChests($RANGE_SPIRIT, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(13000, 23500)
	Info('#5/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(12000, 25000)
	Info('#6/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(11500, 26000)
	Info('#7/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(9750, 26750)
	Info('#8/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(7750, 26125)
	Info('#9/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(6500, 27500)
	Info('#10/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(5000, 28000)
	; Chest can be all the way north of the map - need extreme range here
	$openedChests += FindAndOpenChests($RANGE_SPIRIT + 500, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(4000, 27000)
	; Chest can be all the way west of the map - need extreme range here
	Info('#11/13')
	$openedChests += FindAndOpenChests($RANGE_SPIRIT + 500, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(4000, 26000)
	$openedChests += FindAndOpenChests($RANGE_SPIRIT, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(5000, 25000)
	TascaChestRun(6000, 22000)
	Info('#12/13')
	$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
	TascaChestRun(4500, 21500)
	If ($annoyingChest == Null) Then $annoyingChest = ScanForChests(2000, True, 5500, 18000)
	Notice('Bonus chest ? ' & ($annoyingChest <> Null))
	TascaChestRun(3000, 21500)
	Info('#13/13')
	$openedChests += FindAndOpenChests($RANGE_SPIRIT, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0

	If ($annoyingChest <> Null) Then
		TascaChestRun(6000, 21500)
		TascaChestRun(7000, 20500)
		Info('#Bonus chest')
		$annoyingChest = ScanForChests(2000, True, 5500, 18000)
		Local $target = GetTargetToEscapeWithDeathsCharge(DllStructGetData($annoyingChest, 'X'), DllStructGetData($annoyingChest, 'Y'))
		If $target <> Null Then UseSkillEx($Tasca_DeathsCharge, $target)
		$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
		RandomSleep(1000)
	EndIf

	;ToggleMapping()
	UnregisterBurstHealingUnit()
	Info('Opened ' & $openedChests & ' chests.')
	Return (($openedChests > 0) Or IsPlayerAlive()) ? $SUCCESS : $FAIL
EndFunc


;~ Main function for chest run
Func TascaChestRun($X, $Y)
	If IsPlayerDead() Then Return $FAIL

	Move($X, $Y, 0)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	While IsPlayerAlive() And GetDistanceToPoint($me, $X, $Y) > 150 And $blockedCounter < 20
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($X, $Y, 0)
		EndIf

		TascaDefendFunction($X, $Y)
		; Energy usage becomes too heavy if we start using Death's Charge as a speedup
		;If GetEnergy() >= 5 And IsRecharged($Tasca_DeathsCharge) Then
		;	Local $target = GetTargetForDeathsCharge($X, $Y, 700)
		;	If $target <> Null Then UseSkillEx($Tasca_DeathsCharge, $target)
		;EndIf

		; We only start unblocking after 10 times 250 ms which is 2.5 s -> that's because knockdown lasts 2s
		If $blockedCounter > 10 And GetEnergy() >= 10 Then
			Local $target = GetTargetToEscapeWithDeathsCharge($X, $Y)
			If $target <> Null And IsRecharged($Tasca_DeathsCharge) Then
				UseSkillEx($Tasca_DeathsCharge, $target)
				$blockedCounter = 0
			ElseIf IsRecharged($Tasca_HeartOfShadow) Then
				Local $npc = GetNPCInTheBack($X, $Y)
				If $npc == Null Then $npc = $me
				UseSkillEx($Tasca_HeartOfShadow, $npc)
				$blockedCounter = 0
			EndIf
		EndIf

		Sleep(250)
		$me = GetMyAgent()
	WEnd
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


;~ Get a foe close enough to use Death's Charge on and as close as possible to coordinates
Func GetTargetToEscapeWithDeathsCharge($X, $Y)
	Local $targetDistance = 999999
	Local $target = Null
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	For $foe In $foes
		Local $distance = GetDistanceToPoint($foe, $X, $Y)
		If $distance < $targetDistance Then
			$target = $foe
			$targetDistance = $distance
		EndIf
	Next
	Return $target
EndFunc


;~ Function to unblocked when opening chests
Func UnblockWhenOpeningChests()
	If IsRecharged($Tasca_HeartOfShadow) Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then $target = GetMyAgent()
		UseSkillEx($Tasca_HeartOfShadow, $target)
	ElseIf IsRecharged($Tasca_DeathsCharge) Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_Allegiance_Foe, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($Tasca_DeathsCharge, $target)
	EndIf
EndFunc


;~ Wrapper for TascaDefendFunction to be used in FindAndOpenChests
Func TascaDefendFunctionForChests()
	Return TascaDefendFunction(0, 0)
EndFunc


;~ Use defensive skills while opening chests
Func TascaDefendFunction($X, $Y)
	; Using timers here reduce DllCalls and make bot more reactive
	Local Static $Timer_ShroudOfDistress = Null
	Local Static $Timer_Shadowform = Null
	Local Static $Timer_DwarvenStability = Null

	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	If ($Timer_Shadowform == Null Or TimerDiff($Timer_Shadowform) > 19500) Then
		Local $enemiesAreNear = GetDistance($me, $target) < $RANGE_SPELLCAST
		If $enemiesAreNear Or ($X <> 0 And AreFoesInFront($X, $Y)) Then
			If $enemiesAreNear And IsRecharged($Tasca_IAmUnstoppable) Then UseSkillEx($Tasca_IAmUnstoppable)
			While IsPlayerAlive() And GetEnergy() < 20 And $enemiesAreNear
				Sleep(250)
				$target = GetNearestEnemyToAgent($me)
				$enemiesAreNear = GetDistance($me, $target) < $RANGE_SPELLCAST
			WEnd
			AdlibRegister('UseDeadlyParadox', 750)
			While IsPlayerAlive() And IsRecharged($Tasca_ShadowForm)
				UseSkillEx($Tasca_ShadowForm, $me)
				Sleep(GetPing() + 20)
			WEnd
			$Timer_Shadowform = TimerInit()
			Sleep(GetPing() + 20)
			If ($Timer_DwarvenStability == Null Or TimerDiff($Timer_DwarvenStability) > 34000) And GetEnergy() >= 5 Then
				UseSkillEx($Tasca_DwarvenStability)
				$Timer_DwarvenStability = TimerInit()
				Sleep(GetPing() + 20)
			EndIf
			If (GetEnergy() >= 5) Then UseSkillEx($Tasca_DarkEscape)
		EndIf
	EndIf
	If ($Timer_ShroudOfDistress == Null Or TimerDiff($Timer_ShroudOfDistress) > 62000) And GetEnergy() >= 10 Then
		If (GetEnergy() >= 10) Then
			UseSkillEx($Tasca_ShroudOfDistress)
			$Timer_ShroudOfDistress = TimerInit()
		EndIf
	EndIf
EndFunc


;~ Use Whirling Defense skill
Func UseDeadlyParadox()
	While IsPlayerAlive() And IsRecharged($Tasca_DeadlyParadox)
		UseSkillEx($Tasca_DeadlyParadox)
		Sleep(GetPing() + 20)
	WEnd
	AdlibUnRegister('UseDeadlyParadox')
EndFunc