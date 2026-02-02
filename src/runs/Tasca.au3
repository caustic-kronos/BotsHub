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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils.au3'
#include '../utilities/OmniFarmer.au3'

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $TASCA_DERVISH_CHESTRUNNER_SKILLBAR = 'OgejwyezHT8I6MHQ3l0kNQ4OIQ'
Global Const $TASCA_ASSASSIN_CHESTRUNNER_SKILLBAR = 'OwBj4xf84Q8I6MHQ3l0kNQ4OIQ'
Global Const $TASCA_MESMER_CHESTRUNNER_SKILLBAR = 'OQdTAmP7ZiHRn5A6ukmsBC3BBC'
Global Const $TASCA_ELEMENTALIST_CHESTRUNNER_SKILLBAR = 'OgdTw4P7HiHRn5A6ukmsBC3BBC'
Global Const $TASCA_MONK_CHESTRUNNER_SKILLBAR = 'OwcTAnP7ZiHRn5A6ukmsBC3BBC'
Global Const $TASCA_NECROMANCER_CHESTRUNNER_SKILLBAR = 'OAdT8Z/YYiHRn5A6ukmsBC3BBC'
Global Const $TASCA_RITUALIST_CHESTRUNNER_SKILLBAR = 'OAej8xeM5Q8I6MHQ3l0kNQ4OIQ'

Global Const $TASCA_CHESTRUN_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 16 in Mysticism if playing Dervish' & @CRLF _
	& '- 3 in Deadly Arts' & @CRLF _
	& '- A staff +20e and +20% enchantment duration' & @CRLF _
	& '- caster weapons on all heroes' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 3m
Global Const $TASCA_FARM_DURATION = (3 * 60) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($TASCA_DWARVEN_STABILITY) is better than UseSkillEx(1))
Global Const $TASCA_DEADLY_PARADOX		= 1
Global Const $TASCA_SHADOWFORM			= 2
Global Const $TASCA_SHROUD_OF_DISTRESS	= 3
Global Const $TASCA_DWARVEN_STABILITY	= 4
Global Const $TASCA_I_AM_UNSTOPPABLE	= 5
Global Const $TASCA_DARK_ESCAPE			= 6
Global Const $TASCA_DEATHS_CHARGE		= 7
Global Const $TASCA_HEART_OF_SHADOW		= 8

Global Const $TASCA_CHEST_RANGE = 1.5 * $RANGE_SPELLCAST

Global $tasca_farm_setup = False
Global $tasca_player_profession = $ID_DERVISH

;~ Main method to chest farm Tasca
Func TascaChestFarm()
	If Not $tasca_farm_setup And SetupTascaChestFarm() == $FAIL Then Return $PAUSE

	GoToTascasDemise()
	Local $result = TascaChestFarmLoop()
	ResignAndReturnToOutpost($ID_THE_GRANITE_CITADEL)
	Return $result
EndFunc


;~ Tasca chest farm setup
Func SetupTascaChestFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_THE_GRANITE_CITADEL, $district_name) == $FAIL Then Return $FAIL
	UseCitySpeedBoost()
	If SetupPlayerTascaChestFarm() == $FAIL Then Return $FAIL
	If SetupTeamTascaChestFarm() == $FAIL Then Return $FAIL
	SwitchToHardModeIfEnabled()

	GoToTascasDemise()
	MoveTo(-9250, 19850)
	Move(-10000, 18875)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_GRANITE_CITADEL, 10000, 1000)
	$tasca_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerTascaChestFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_DERVISH
			$tasca_player_profession = $ID_DERVISH
			LoadSkillTemplate($TASCA_DERVISH_CHESTRUNNER_SKILLBAR)
		Case $ID_ASSASSIN
			$tasca_player_profession = $ID_ASSASSIN
			LoadSkillTemplate($TASCA_ASSASSIN_CHESTRUNNER_SKILLBAR)
		Case $ID_MESMER
			$tasca_player_profession = $ID_MESMER
			LoadSkillTemplate($TASCA_MESMER_CHESTRUNNER_SKILLBAR)
		Case $ID_MONK
			$tasca_player_profession = $ID_MONK
			LoadSkillTemplate($TASCA_MONK_CHESTRUNNER_SKILLBAR)
		Case $ID_ELEMENTALIST
			$tasca_player_profession = $ID_ELEMENTALIST
			LoadSkillTemplate($TASCA_ELEMENTALIST_CHESTRUNNER_SKILLBAR)
		Case $ID_NECROMANCER
			$tasca_player_profession = $ID_NECROMANCER
			LoadSkillTemplate($TASCA_NECROMANCER_CHESTRUNNER_SKILLBAR)
		Case $ID_RITUALIST
			$tasca_player_profession = $ID_RITUALIST
			LoadSkillTemplate($TASCA_RITUALIST_CHESTRUNNER_SKILLBAR)
		Case Else
			; other characters have too few energy
			Warn('Should run this farm as Dervish, Assassin, Mesmer, Monk, Elementalist, Necromancer or Ritualist')
			Return $FAIL
	EndSwitch
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamTascaChestFarm()
	If IsTeamAutoSetup() Then Return True

	Info('Setting up team according to default settings')
	OmniFarmFullSetup()
	RandomSleep(500)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Tasca's Demise
Func GoToTascasDemise()
	TravelToOutpost($ID_THE_GRANITE_CITADEL, $district_name)
	While GetMapID() <> $ID_TASCAS_DEMISE
		Info('Moving to Tasca''s Demise')
		MoveTo(-10000, 18875)
		Move(-9250, 19850)
		RandomSleep(1000)
		WaitMapLoading($ID_TASCAS_DEMISE, 10000, 2000)
	WEnd
EndFunc


;~ Tasca Chest farm loop
Func TascaChestFarmLoop()
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $ID_TASCAS_DEMISE Then Return $FAIL

	Info('Starting chest run')
	UseConsumable($ID_BIRTHDAY_CUPCAKE, True)
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
		If $target <> Null Then UseSkillEx($TASCA_DEATHS_CHARGE, $target)
		$openedChests += FindAndOpenChests($TASCA_CHEST_RANGE, TascaDefendFunctionForChests, UnblockWhenOpeningChests) ? 1 : 0
		RandomSleep(1000)
	EndIf

	;ToggleMapping()
	UnregisterBurstHealingUnit()
	Info('Opened ' & $openedChests & ' chests.')
	Return ($openedChests > 0) Or IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Main function for chest run
Func TascaChestRun($X, $Y)
	If IsPlayerDead() Then Return $FAIL

	Move($X, $Y, 0)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	While GetDistanceToPoint($me, $X, $Y) > 150 And $blockedCounter < 20
		If Not IsPlayerMoving() Then
			$blockedCounter += 1
			Move($X, $Y, 0)
		EndIf

		TascaDefendFunction($X, $Y)
		; Energy usage becomes too heavy if we start using Death's Charge as a speedup
		;If GetEnergy() >= 5 And IsRecharged($TASCA_DEATHS_CHARGE) Then
		;	Local $target = GetTargetForDeathsCharge($X, $Y, 700)
		;	If $target <> Null Then UseSkillEx($TASCA_DEATHS_CHARGE, $target)
		;EndIf

		; We only start unblocking after 10 times 250 ms which is 2.5 s -> that's because knockdown lasts 2s
		If $blockedCounter > 10 And GetEnergy() >= 10 Then
			Local $target = GetTargetToEscapeWithDeathsCharge($X, $Y)
			If $target <> Null And IsRecharged($TASCA_DEATHS_CHARGE) Then
				UseSkillEx($TASCA_DEATHS_CHARGE, $target)
				$blockedCounter = 0
			ElseIf IsRecharged($TASCA_HEART_OF_SHADOW) Then
				Local $npc = GetNPCInTheBack($X, $Y)
				If $npc == Null Then $npc = $me
				UseSkillEx($TASCA_HEART_OF_SHADOW, $npc)
				$blockedCounter = 0
			EndIf
		EndIf

		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
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
	If IsRecharged($TASCA_HEART_OF_SHADOW) Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then $target = GetMyAgent()
		UseSkillEx($TASCA_HEART_OF_SHADOW, $target)
	ElseIf IsRecharged($TASCA_DEATHS_CHARGE) Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($TASCA_DEATHS_CHARGE, $target)
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
	Local $ping = GetPing()
	If ($Timer_Shadowform == Null Or TimerDiff($Timer_Shadowform) > 19500) Then
		Local $enemiesAreNear = GetDistance($me, $target) < $RANGE_SPELLCAST
		If $enemiesAreNear Or ($X <> 0 And AreFoesInFront($X, $Y)) Then
			If $enemiesAreNear And IsRecharged($TASCA_I_AM_UNSTOPPABLE) Then UseSkillEx($TASCA_I_AM_UNSTOPPABLE)
			While IsPlayerAlive() And GetEnergy() < 20 And $enemiesAreNear
				Sleep(250)
				$target = GetNearestEnemyToAgent($me)
				$enemiesAreNear = GetDistance($me, $target) < $RANGE_SPELLCAST
			WEnd
			AdlibRegister('UseDeadlyParadox', 750)
			While IsPlayerAlive() And IsRecharged($TASCA_SHADOWFORM)
				UseSkillEx($TASCA_SHADOWFORM, $me)
				Sleep(20 + $ping)
			WEnd
			$Timer_Shadowform = TimerInit()
			Sleep(20 + $ping)
			If ($Timer_DwarvenStability == Null Or TimerDiff($Timer_DwarvenStability) > 34000) And GetEnergy() >= 5 Then
				UseSkillEx($TASCA_DWARVEN_STABILITY)
				$Timer_DwarvenStability = TimerInit()
				Sleep(20 + $ping)
			EndIf
			If (GetEnergy() >= 5) Then UseSkillEx($TASCA_DARK_ESCAPE)
		EndIf
	EndIf
	If ($Timer_ShroudOfDistress == Null Or TimerDiff($Timer_ShroudOfDistress) > 62000) And GetEnergy() >= 10 Then
		If (GetEnergy() >= 10) Then
			UseSkillEx($TASCA_SHROUD_OF_DISTRESS)
			$Timer_ShroudOfDistress = TimerInit()
		EndIf
	EndIf
EndFunc


;~ Use Whirling Defense skill
Func UseDeadlyParadox()
	While IsPlayerAlive() And IsRecharged($TASCA_DEADLY_PARADOX)
		UseSkillEx($TASCA_DEADLY_PARADOX)
		Sleep(50)
	WEnd
	AdlibUnRegister('UseDeadlyParadox')
EndFunc