#CS ===========================================================================
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
; ==================================================================================================
; War Supplies/Keiran Bot
; ==================================================================================================
; AutoIt Version:   3.3.18.0
; Original Author:  Danylia
; Modified Author:  RiflemanX
; Modified Author:  Zaishen Silver
; Rewrite Author for BotsHub: Gahais
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $WarSupplyKeiranInformations = 'For best results, have :' & @CRLF _
	& ' - (Weapon Slot-3) Shortbow +15/-5 vamp +5 armor is the best weapon' & @CRLF _
	& ' - (Weapon Slot-4) Keiran''s Bow' & @CRLF _ ; escaped character ' with '' here
	& ' - Ideal character is with max armor (Warrior/Paragon) with 5x Knights Insignias and the Absorption -3 superior rune and 4 runes each of restoration/recovery/clarity/purity' & @CRLF _
	& ' - When in Keiran Thackeray''s disguise then health is 600 and energy is 25' & @CRLF _
	& ' - Consumables, insignias, runes, weapon upgrade components will not change health, energy, or attributes; they will otherwise work as expected (e.g. they will increase armor rating)' & @CRLF _
	& ' - This bot doesn''t need any specific builds for main character or heroes' & @CRLF _
	& ' - Only main character enters Auspicious Beginnings mission and is assigned Keiran Thackeray''s build for the duration of the quest' & @CRLF _
	& ' ' & @CRLF _
	& 'Any character can go into Auspicious Beginnings mission if you send the right dialog ID (already in script) to Guild Wars client' & @CRLF _
	& 'You just need the Keiran''s Bow which Gwen gives when the right dialog ID is sent to Guild Wars client' & @CRLF _
	& 'You don''t need to have progress in Guild Wars Beyond campaign to be able enter this mission (even when these dialog options aren''t visible)' & @CRLF _
	& 'This bot is useful for farming War Supplies, festival items, platinum and Ebon Vanguard reputation' & @CRLF
; Average duration ~ 8 minutes
Global Const $WAR_SUPPLY_FARM_DURATION = 8 * 60 * 1000
Global Const $MAX_WAR_SUPPLY_FARM_DURATION = 16 * 60 * 1000
Global $WarSupplyFarmTimer = Null
Global $WARSUPPLY_FARM_SETUP = False

Global Const $KeiranSniperShot			= 1 ; number of Keiran's Sniper Shot skill on Keiran's skillbar
Global Const $KeiranGravestoneMarker	= 2 ; number of Gravestone Marker skill on Keiran's skillbar
Global Const $KeiranTerminalVelocity	= 3 ; number of Terminal Velocity skill on Keiran's skillbar
Global Const $KeiranRainOfArrows		= 4 ; number of Rain of Arrows skill on Keiran's skillbar
Global Const $KeiranRelentlessAssault	= 5 ; number of Relentless Assault skill on Keiran's skillbar
Global Const $KeiranNaturesBlessing		= 6 ; number of Nature's Blessing skill on Keiran's skillbar
Global Const $KeiranUnused7thSkill		= 7 ; empty skill slot on Keiran's skillbar
Global Const $KeiranUnused8thSkill		= 8 ; empty skill slot on Keiran's skillbar

Global Const $KeiranSkillsArray			= [$KeiranSniperShot,	$KeiranGravestoneMarker,	$KeiranTerminalVelocity,	$KeiranRainOfArrows,	$KeiranRelentlessAssault,	$KeiranNaturesBlessing,	$KeiranUnused7thSkill,	$KeiranUnused8thSkill]
Global Const $KeiranSkillsCostsArray	= [2,					2,							1,							1,						3,							2,						0,						0]
Global Const $KeiranSkillsCostsMap = MapFromArrays($KeiranSkillsArray, $KeiranSkillsCostsArray) ; Keiran's energy skill cost is reduced by expertise level 20

Global $WarSupplyFightOptions = CloneDictMap($Default_MoveAggroAndKill_Options)
$WarSupplyFightOptions.Item('fightFunction')	= WarSupplyFarmFight
$WarSupplyFightOptions.Item('fightRange')		= 1250
$WarSupplyFightOptions.Item('fightDuration')	= 20000 ; approximate 20 seconds max duration of initial and final fight
$WarSupplyFightOptions.Item('priorityMobs')		= True
$WarSupplyFightOptions.Item('callTarget')		= False
$WarSupplyFightOptions.Item('lootInFights')		= False ; loot only when no foes are in range
$WarSupplyFightOptions.Item('openChests')		= False ; Only Krytan chests in Auspicious Beginnings quest which may have useless loot
$WarSupplyFightOptions.Item('skillsCostMap')	= $KeiranSkillsCostsMap

Global Const $AgentID_Player = 2 ; in Auspicious Beginnings location, the agent ID of Player is always assigned to 2 (can be accessed in GWToolbox)
Global Const $AgentID_Miku = 3 ; in Auspicious Beginnings location, the agent ID of Miku is always assigned to 3 (can be accessed in GWToolbox)
Global Const $ModelID_Miku = 8382 ; unique Model ID of Miku NPC, that can be accessed in GWToolbox


;~ Main loop function for farming war supplies
Func WarSupplyKeiranFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $WARSUPPLY_FARM_SETUP Then SetupWarSupplyFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Local $result = WarSupplyFarmLoop()
	Return $result
EndFunc


;~ farm setup preparation
Func SetupWarSupplyFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Eye_of_the_North Then TravelToOutpost($ID_Eye_of_the_North, $DISTRICT_NAME)
	If Not ItemExistsInInventory($ID_Keirans_Bow) Then
		Info('Could not find Keiran''s bow in player''s inventory')
		GetKeiranBow()
	Else
		Info('Found Keiran''s bow in player''s inventory')
	EndIf
	Info('Changing Weapons: Slot-4 Keiran Bow')
	ChangeWeaponSet(4)
	If Not IsItemEquippedInWeaponSlot($ID_Keirans_Bow, 4) Then
		Info('Equipping Keiran''s bow')
		EquipItemByModelID($ID_Keirans_Bow)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	$WARSUPPLY_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func GetKeiranBow()
	Info('Getting Keiran''s bow to be able to enter the quest')
	If GetMapID() <> $ID_Eye_of_the_North Then TravelToOutpost($ID_Eye_of_the_North, $DISTRICT_NAME)
	EnterHallOfMonuments()
	Local $bowDialogID = 0x8A ; hexadecimal code of dialog id to receive keiran's bow
	Local $Gwen = GetNearestNPCToCoords(-6583, 6672) ; coordinates of Gwen inside Hall of Monuments location
	GoToNPC($Gwen)
	RandomSleep(500)
	dialog($bowDialogID) ; start a dialog with Gwen and send a packet for receiving Keiran Bow
	RandomSleep(500)
EndFunc


;~ Farm loop
Func WarSupplyFarmLoop()
	If EnterHallOfMonuments() == $FAIL Then Return $FAIL
	If EnterAuspiciousBeginningsQuest() == $FAIL Then Return $FAIL
	Local $result = RunQuest()
	Sleep(1000)
	If $result == $FAIL Then
		If IsPlayerDead() Then Warn('Player died')
		ReturnBackToOutpost($ID_Hall_of_Monuments)
		Sleep(3000)
	EndIf
	return $result
EndFunc


Func EnterHallOfMonuments()
	If GetMapID() <> $ID_Hall_of_Monuments Then
		If GetMapID() <> $ID_Eye_of_the_North Then TravelToOutpost($ID_Eye_of_the_North, $DISTRICT_NAME)
		Info('Going into Hall of Monuments')
		MoveTo(-3477, 4245)
		MoveTo(-4060, 4675)
		MoveTo(-4448, 4952)
		move(-4779, 5209)
		WaitMapLoading($ID_Hall_of_Monuments)
	EndIf
	Return GetMapID() == $ID_Hall_of_Monuments ? $SUCCESS : $FAIL
EndFunc


Func EnterAuspiciousBeginningsQuest()
	If GetMapID() <> $ID_Hall_of_Monuments Then Return $FAIL
	Local $questDialogID = 0x63E ; hexadecimal code of dialog id to start Auspicious Beginnings quest
	Info('Entering Auspicious Beginnings quest')
	Info('Changing Weapons: Slot-4 Keiran Bow')
	ChangeWeaponSet(4)
	MoveTo(-6445, 6415)
	Local $scryingPool = GetNearestNpcToCoords(-6662, 6584)
	ChangeTarget($scryingPool)
	GoToNPC($scryingPool)
	RandomSleep(1000)
	Dialog($questDialogID)
	WaitMapLoading($ID_Auspicious_Beginnings, 15000, 7000)
	Return GetMapID() == $ID_Auspicious_Beginnings ? $SUCCESS : $FAIL
EndFunc


Func RunQuest()
	If GetMapID() <> $ID_Auspicious_Beginnings Then Return $FAIL
	Info('Running Auspicious Beginnings quest ')
	RandomSleep(1000)
	$WarSupplyFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run

	Info('Moving to start location to wait out initial dialogs')
	MoveTo(11500, -5050)
	Sleep(20000) ; waiting out initial dialogs for 20 seconds

	Info('Changing weapons to 3th slot with custom modded bow')
	ChangeWeaponSet(3)
	MoveTo(12000, -4600) ; move to initial location to fight first group of foes
	If WaitAndFightEnemiesInArea($WarSupplyFightOptions) == $FAIL Then Return $FAIL
	; proceeding with the quest, second dialogs can be safely skipped to speed up farm runs
	If RunWayPoints() == $FAIL Then Return $FAIL
	; clearing final area
	If WaitAndFightEnemiesInArea($WarSupplyFightOptions) == $FAIL Then Return $FAIL

	; loop to wait out in-game countdown to exit quest automatically
	Local $deadlock = TimerInit()
	While GetMapID() <> $ID_Hall_of_Monuments And IsPlayerAlive()
		Sleep(1000)
		If TimerDiff($deadlock) > 120000 Then Return $FAIL ; if 2 minutes elapsed after a final fight and still not left the then some stuck occurred, therefore exiting
	WEnd
	Sleep(3000)
	Return $SUCCESS
EndFunc


Func RunWayPoints()
	Local $wayPoints[26][3] = [ _
		[11125, -5226, 'Main Path 1'], _
		[11000, -5200, 'Main Path 2'], _
		[10750, -5500, 'Main Path 3'], _
		[10500, -5800, 'Main Path 4'], _
		[10338, -5966, 'Main Path 5'], _
		[9871, -6464, 'Main Path 6'], _
		[9500, -7000, 'Main Path 7'], _
		[8740, -7978, 'Main Path 8'], _
		[7498, -8517, 'Main Path 9'], _
		[6000, -8000, 'Main Path 10'], _
		[5000, -7500, 'Fighting pre forest group'], _
		[5193, -8514, 'Trying to skip forest'], _
		[3082, -11112, 'Trying to skip forest'], _
		[1743, -12859, 'Trying to skip forest group'], _
		[-181, -12791, 'Leaving Forest'], _
		[-2728, -11695, 'Detour 16'], _
		[-2858, -11942, 'Detour 17'], _
		[-4212, -12641, 'Detour 18'], _
		[-4276, -12771, 'Detour 19'], _
		[-6884, -11357, 'Detour 20'], _
		[-9085, -8631, 'Detour 21'], _
		[-13156, -7883, 'Detour 22'], _
		[-13768, -8158, 'Final Area 23'], _
		[-14205, -8373, 'Final Area 24'], _
		[-15876, -8903, 'Final Area 25'], _
		[-17109, -8978, 'Final Area 26'] _
	]

	Info('Running through way points')
	Local $x, $y, $log, $range
	For $i = 0 To UBound($wayPoints) - 1
		;If GetMapLoading() == 2 Or (GetMapID() <> $ID_Auspicious_Beginnings And GetMapID() <> $ID_Hall_of_Monuments) Then Disconnected()
		$x = $wayPoints[$i][0]
		$y = $wayPoints[$i][1]
		$log = $wayPoints[$i][2]
		If MoveAggroAndKill($x, $y, $log, $WarSupplyFightOptions) == $FAIL Then Return $FAIL
		If $i == 2 Or $i == 3 Then Sleep(3000) ; wait for initial group to appear in front of player, because they appear suddenly and can't be detected in advance
		If $i == 9 Or $i == 10 Then Sleep(3000) ; wait for pre forest group to clear it because not clearing it can result in fail by Miku pulling this group into forest (2-3 groups at once)
		While IsPlayerAlive() ; Between waypoints ensure that everything is fine with player and Miku
			If TimerDiff($WarSupplyFarmTimer) > $MAX_WAR_SUPPLY_FARM_DURATION Then Return $FAIL
			If GetMapID() <> $ID_Auspicious_Beginnings Then ExitLoop
			Local $me = GetMyAgent()
			Local $Miku = GetAgentByID($AgentID_Miku)
			If DllStructGetData($Miku, 'X') == 0 And DllStructGetData($Miku, 'Y') == 0 Then Return $FAIL ; check against some impossible scenarios
			; Using 6th healing skill on the way between waypoints to recover until health is full
			If IsRecharged($KeiranNaturesBlessing) And (DllStructGetData($me, 'HP') < 0.9 Or DllStructGetData($Miku, 'HP') < 0.9) And IsPlayerAlive() Then UseSkillEx($KeiranNaturesBlessing)
			If CountFoesInRangeOfAgent($me, $WarSupplyFightOptions.Item('fightRange')) > 0 Then WarSupplyFarmFight($WarSupplyFightOptions)
			If GetDistance($me, $Miku) > 1650 Then ; Ensuring that Miku is not too far
				Info('Miku is too far. Trying to move to her location')
				MoveTo(DllStructGetData($Miku, 'X'), DllStructGetData($Miku, 'Y'), 250)
			EndIf
			If GetDistance($me, $Miku) < 1650 And Not GetIsDead($Miku) And DllStructGetData($me, 'HP') > 0.9 And DllStructGetData($Miku, 'HP') > 0.9 Then ExitLoop ; continue running through waypoints
			Sleep(1000)
		WEnd
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($WarSupplyFarmTimer) > $MAX_WAR_SUPPLY_FARM_DURATION Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


Func WarSupplyFarmFight($options = $WarSupplyFightOptions)
	Info('Fighting')
	If(IsPLayerDead()) Then Return $FAIL
	If GetMapID() <> $ID_Auspicious_Beginnings Then Return $FAIL
	If TimerDiff($WarSupplyFarmTimer) > $MAX_WAR_SUPPLY_FARM_DURATION Then Return $FAIL

	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : 1200
	Local $priorityMobs = ($options.Item('priorityMobs') <> Null) ? $options.Item('priorityMobs') : True

	Local $me = Null
	Local $Miku = Null
	Local $foes = Null
	Local $target = Null

	While IsPlayerAlive()
		If GetMapID() <> $ID_Auspicious_Beginnings Then ExitLoop
		If TimerDiff($WarSupplyFarmTimer) > $MAX_WAR_SUPPLY_FARM_DURATION Then Return $FAIL
		; refreshing/sampling all agents state at the start of every loop iteration to not operate on some old, inadequate data
		$me = GetMyAgent()
		$Miku = GetAgentByID($AgentID_Miku)
		$foes = GetFoesInRangeOfAgent($me, $fightRange)
		If Not IsArray($foes) Or UBound($foes) < 0 Then ExitLoop
		If $Miku == Null Then Return $FAIL ; check to prevent data races when exited quest after doing above map check
		If GetIsDead($Miku) Then Warn('Miku dead')
		If UBound($foes) == 0 Then ExitLoop ; no more foes detected in range

		; use skills 1, 3, 6 in special circumstances, not specifically on current target
		; only use Nature's Blessing skill when it is recharged and player's or Miku's HP is below 90%
		If IsRecharged($KeiranNaturesBlessing) And (DllStructGetData($me, 'HP') < 0.9 Or DllStructGetData($Miku, 'HP') < 0.9) And IsPlayerAlive() Then
			UseSkillEx($KeiranNaturesBlessing)
		EndIf

		If IsPlayerDead() Then Return $FAIL
		If GetIsKnocked($me) Then ContinueLoop

		If IsRecharged($KeiranSniperShot) And IsPlayerAlive() Then
			For $foe In $foes
				If GetHasHex($foe) And Not GetIsDead($foe) And DllStructGetData($foe, 'ID') <> 0 Then
					UseSkillEx($KeiranSniperShot, $foe)
					Sleep(800)
					ContinueLoop ; exit loop iteration to not use any skills on potentially deceased target
				EndIf
			Next
		EndIf

		If IsRecharged($KeiranTerminalVelocity) And IsPlayerAlive() Then
			For $foe In $foes
				If GetIsCasting($foe) And Not GetIsDead($foe) And DllStructGetData($foe, 'ID') <> 0 Then
					Switch DllStructGetData($foe, 'Skill')
						; if foe is casting dangerous AoE skill on player then try to interrupt it and evade AoE location
						Case $ID_Meteor_Shower, $ID_Fire_Storm, $ID_Ray_of_Judgement, $ID_Unsteady_Ground, $ID_Sand_Storm, $ID_Savannah_Heat
							UseSkillEx($KeiranTerminalVelocity, $foe) ; attempt to interrupt dangerous AoE skill
							; attempt to evade dangerous AoE skill effect just in case interrupt was too late or unsuccessful
							EvadeAoESkillArea()
							ContinueLoop
						; other important skills casted by foes in Auspicious Beginnings quest that are easy to interrupt
						Case $ID_Healing_Signet, $ID_Resurrection_Signet, $ID_Empathy, $ID_Animate_Bone_Minions, $ID_Vengeance, $ID_Troll_Unguent, _
								$ID_Flesh_of_My_Flesh, $ID_Animate_Flesh_Golem, $ID_Resurrection_Chant, $ID_Renew_Life, $ID_Signet_of_Return
							UseSkillEx($KeiranTerminalVelocity, $foe) ; attempt to interrupt skill
							ContinueLoop
					EndSwitch
				EndIf
			Next
		EndIf

		; fix for the pathological situation when Miku stays behind player and doesn't attack mobs, because mobs are standing a bit too far beyond Miku's range but still can attack the player from sufficient distance (rangers and spellcasters)
		;Local $isFoeAttackingPlayer = False
		;Local $isFoeAttackingMiku = False
		Local $isPlayerAttacking = False
		Local $isFoeAttacking = False
		Local $isMikuAttacking = False
		Local $isFoeInRangeOfMiku = False
		For $foe In $foes
			If BitAND(DllStructGetData($foe, 'TypeMap'), 0x1) == 1 Then $isFoeAttacking = True ; first bit in TypeMap corresponds to attack stance
			If GetDistance($Miku, $foe) < $RANGE_EARSHOT Then $isFoeInRangeOfMiku = True
			;If GetTarget($foe) == $AgentID_Player Then $isFoeAttackingPlayer = True ; unfortunately GetTarget() always returns 0, so can't be used here
			;If GetTarget($foe) == $AgentID_Miku Then $isFoeAttackingMiku = True ; unfortunately GetTarget() always returns 0, so can't be used here
		Next
		If BitAND(DllStructGetData($me, 'TypeMap'), 0x1) == 1 Then $isPlayerAttacking = True ; first bit in TypeMap corresponds to attack stance
		If BitAND(DllStructGetData($Miku, 'TypeMap'), 0x1) == 1 Then $isMikuAttacking = True ; first bit in TypeMap corresponds to attack stance
		If ($isPlayerAttacking And $isFoeAttacking And Not $isFoeInRangeOfMiku And Not $isMikuAttacking And IsPlayerAlive() And Not GetIsDead($Miku)) Then
			Move(DllStructGetData($Miku, 'X'), DllStructGetData($Miku, 'Y'), 300) ; move to Miku's position to trigger fight between Miku and mobs
			ContinueLoop
		EndIf

		; if target is Null then select a new target for ordinary bow attack skills 2, 4, 5 or exit the loop when there are no more targets in range
		If $target == Null Or GetIsDead($target) Or GetIsDead(GetCurrentTarget()) Or DllStructGetData($target, 'ID') == 0 Then
			$me = GetMyAgent()
			If $priorityMobs Then $target = GetHighestPriorityFoe($me, $fightRange)
			If $target == Null Or GetIsDead($target) Or DllStructGetData($target, 'ID') == 0 Then
				$target = GetNearestEnemyToAgent($me)
				If $target == Null Or GetIsDead($target) Or DllStructGetData($target, 'ID') == 0 Then ExitLoop ; no more enemy agents found anywhere
				If GetDistance($me, $target) > $fightRange Then ExitLoop ; no more enemy agents found within fight range
			Endif
			ChangeTarget($target)
			Sleep(100)
			Attack($target) ; Start auto-attack on new target
			Sleep(100)
		EndIf


		If IsRecharged($KeiranRelentlessAssault) And GetHasCondition($me) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KeiranRelentlessAssault, $target)
			Sleep(200)
			ContinueLoop
		EndIf

		If IsRecharged($KeiranRainOfArrows) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KeiranRainOfArrows, $target)
			Sleep(200)
			ContinueLoop
		EndIf

		If IsRecharged($KeiranGravestoneMarker) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KeiranGravestoneMarker, $target)
			Sleep(200)
			ContinueLoop
		EndIf

		; only use interrupting 3th skill on current target when all other skills are recharging (interrupting skill is prioritized on more important skills above)
		If IsRecharged($KeiranTerminalVelocity) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KeiranTerminalVelocity, $target)
			ContinueLoop
		EndIf
	WEnd
	If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $fightRange)
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


;~ Evade circular area affected with AoE skill into outer circular area using 2 random coordinates in polar system
;~ New random position with absolute offset at least 300, up to 500, which is further than $RANGE_NEARBY=240
Func EvadeAoESkillArea()
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local Const $PI = 3.14
	Local $randomAngle = Random(0, 2*$PI) ; range [0, 2*$PI] - full circle in radian degrees
	Local $randomRadius = Random(300, 500) ; range [300, 500] - outside of AoE area
	Local $offsetX = $randomRadius * cos($randomAngle)
	Local $offsetY = $randomRadius * sin($randomAngle)
	MoveTo($myX + $offsetX , $myY + $offsetY, 0) ; 0 = no random, because random offset is already calculated
EndFunc