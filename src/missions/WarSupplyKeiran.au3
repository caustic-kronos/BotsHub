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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $WAR_SUPPLY_KEIRAN_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- (Weapon Slot-3) Shortbow +15/-5 vamp +5 armor is the best weapon' & @CRLF _
	& '- (Weapon Slot-4) Keiran''s Bow' & @CRLF _
	& '- Ideal character is with max armor (Warrior/Paragon) with 5x Knights Insignias and the Absorption -3 superior rune and 4 runes each of restoration/recovery/clarity/purity' & @CRLF _
	& '- When in Keiran Thackeray''s disguise then health is 600 and energy is 25' & @CRLF _
	& '- Consumables, insignias, runes, weapon upgrade components will not change health, energy, or attributes; they will otherwise work as expected (e.g. they will increase armor rating)' & @CRLF _
	& '- This bot does not need any specific builds for main character or heroes' & @CRLF _
	& '- Only main character enters Auspicious Beginnings mission and is assigned Keiran Thackeray''s build for the duration of the quest' & @CRLF _
	& ' ' & @CRLF _
	& 'Any character can go into Auspicious Beginnings mission if you send the right dialog ID (already in script) to Guild Wars client' & @CRLF _
	& 'You just need the Keiran''s Bow which Gwen gives when the right dialog ID is sent to Guild Wars client' & @CRLF _
	& 'You do not need to have progress in Guild Wars Beyond campaign to be able enter this mission (even when these dialog options are not visible)' & @CRLF _
	& 'This bot is useful for farming War Supplies, festival items, platinum and Ebon Vanguard reputation' & @CRLF
; Average duration ~ 8 minutes
Global Const $WAR_SUPPLY_FARM_DURATION		= 8 * 60 * 1000
Global Const $MAX_WAR_SUPPLY_FARM_DURATION	= 16 * 60 * 1000

Global Const $KEIRAN_SNIPER_SHOT			= 1		; number of Keiran's Sniper Shot skill on Keiran's skillbar
Global Const $KEIRAN_GRAVESTONE_MARKER		= 2		; number of Gravestone Marker skill on Keiran's skillbar
Global Const $KEIRAN_TERMINAL_VELOCITY		= 3		; number of Terminal Velocity skill on Keiran's skillbar
Global Const $KEIRAN_RAIN_OF_ARROWS			= 4		; number of Rain of Arrows skill on Keiran's skillbar
Global Const $KEIRAN_RELENTLESS_ASSAULT		= 5		; number of Relentless Assault skill on Keiran's skillbar
Global Const $KEIRAN_NATURES_BLESSING		= 6		; number of Nature's Blessing skill on Keiran's skillbar
Global Const $KEIRAN_UNUSED_7TH_SKILL		= 7		; empty skill slot on Keiran's skillbar
Global Const $KEIRAN_UNUSED_8TH_SKILL		= 8		; empty skill slot on Keiran's skillbar

; Keiran's energy skill cost is reduced by expertise level 20
Global Const $KEIRAN_SKILLS_ARRAY			= [$KEIRAN_SNIPER_SHOT,	$KEIRAN_GRAVESTONE_MARKER,	$KEIRAN_TERMINAL_VELOCITY,	$KEIRAN_RAIN_OF_ARROWS,	$KEIRAN_RELENTLESS_ASSAULT,	$KEIRAN_NATURES_BLESSING,	$KEIRAN_UNUSED_7TH_SKILL,	$KEIRAN_UNUSED_8TH_SKILL]
Global Const $KEIRAN_SKILLS_COSTS_ARRAY		= [2,					2,							1,							1,						3,							2,						0,						0]
Global Const $KEIRAN_SKILLS_COSTS_MAP		= MapFromArrays($KEIRAN_SKILLS_ARRAY, $KEIRAN_SKILLS_COSTS_ARRAY)

Global $warsupply_fight_options = CloneDictMap($default_moveaggroandkill_options)
$warsupply_fight_options.Item('fightFunction')	= WarSupplyFarmFight
$warsupply_fight_options.Item('fightRange')		= 1250
; approximate 20 seconds max duration of initial and final fight
$warsupply_fight_options.Item('fightDuration')	= 20000
$warsupply_fight_options.Item('priorityMobs')		= True
$warsupply_fight_options.Item('callTarget')		= False
$warsupply_fight_options.Item('lootInFights')		= False
; Only Krytan chests in Auspicious Beginnings quest which may have useless loot
$warsupply_fight_options.Item('openChests')		= False
$warsupply_fight_options.Item('skillsCostMap')	= $KEIRAN_SKILLS_COSTS_MAP

; in Auspicious Beginnings location, the agent ID of Player is always assigned to 2 (can be accessed in GWToolbox)
Global Const $AGENTID_PLAYER = 2
; in Auspicious Beginnings location, the agent ID of Miku is always assigned to 3 (can be accessed in GWToolbox)
Global Const $AGENTID_MIKU = 3
Global Const $MODELID_MIKU = 8433

Global $warsupply_farm_setup = False

;~ Main loop function for farming war supplies
Func WarSupplyKeiranFarm()
	If Not $warsupply_farm_setup Then SetupWarSupplyFarm()

	Local $result = WarSupplyFarmLoop()
	Return $result
EndFunc


;~ farm setup preparation
Func SetupWarSupplyFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	If Not IsItemEquippedInWeaponSlot($ID_KEIRANS_BOW, 4) And FindInInventory($ID_KEIRANS_BOW)[0] == 0 Then
		Info('Could not find Keiran''s bow in player''s inventory')
		GetKeiranBow()
	Else
		Info('Found Keiran''s bow in player''s inventory')
	EndIf
	Info('Changing Weapons: Slot-4 Keiran Bow')
	ChangeWeaponSet(4)
	If Not IsItemEquippedInWeaponSlot($ID_KEIRANS_BOW, 4) Then
		Info('Equipping Keiran''s bow')
		EquipItemByModelID($ID_KEIRANS_BOW)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	$warsupply_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func GetKeiranBow()
	Info('Getting Keiran''s bow to be able to enter the quest')
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	EnterHallOfMonuments()
	; hexadecimal code of dialog id to receive keiran's bow
	Local $bowDialogID = 0x8A
	; coordinates of Gwen inside Hall of Monuments location
	Local $gwen = GetNearestNPCToCoords(-6583, 6672)
	GoToNPC($gwen)
	RandomSleep(500)
	; start a dialog with Gwen and send a packet for receiving Keiran Bow
	dialog($bowDialogID)
	RandomSleep(500)
EndFunc


;~ Farm loop
Func WarSupplyFarmLoop()
	If EnterHallOfMonuments() == $FAIL Then Return $FAIL
	RandomSleep(1000)
	If EnterAuspiciousBeginningsQuest() == $FAIL Then Return $FAIL
	RandomSleep(1000)
	Local $result = RunQuest()
	RandomSleep(1000)
	If $result == $FAIL Then
		If IsPlayerDead() Then Warn('Player died')
		ResignAndReturnToOutpost($ID_HALL_OF_MONUMENTS)
		Sleep(3000)
	EndIf
	Return $result
EndFunc


Func EnterHallOfMonuments()
	If GetMapID() <> $ID_HALL_OF_MONUMENTS Then
		TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
		Info('Going into Hall of Monuments')
		MoveTo(-3477, 4245)
		MoveTo(-4060, 4675)
		MoveTo(-4448, 4952)
		move(-4779, 5209)
		WaitMapLoading($ID_HALL_OF_MONUMENTS)
	EndIf
	Return GetMapID() == $ID_HALL_OF_MONUMENTS ? $SUCCESS : $FAIL
EndFunc


Func EnterAuspiciousBeginningsQuest()
	If GetMapID() <> $ID_HALL_OF_MONUMENTS Then Return $FAIL
	; hexadecimal code of dialog id to start Auspicious Beginnings quest
	;Local $questDialogID = 0x63E ;Apparently dialog changed
	Local $questDialogID = 0x63F
	Info('Entering Auspicious Beginnings quest')
	Info('Changing Weapons: Slot-4 Keiran Bow')
	ChangeWeaponSet(4)
	MoveTo(-6445, 6415)
	Local $scryingPool = GetNearestNpcToCoords(-6662, 6584)
	ChangeTarget($scryingPool)
	GoToNPC($scryingPool)
	RandomSleep(1000)
	Dialog($questDialogID)
	WaitMapLoading($ID_AUSPICIOUS_BEGINNINGS, 15000, 7000)
	Return GetMapID() == $ID_AUSPICIOUS_BEGINNINGS ? $SUCCESS : $FAIL
EndFunc


Func RunQuest()
	If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then Return $FAIL
	Info('Running Auspicious Beginnings quest ')

	Info('Moving to start location to wait out initial dialogs')
	MoveTo(11500, -5050)
	; waiting out initial dialogs for 20 seconds
	Sleep(20000)

	Info('Changing weapons to 3th slot with custom modded bow')
	ChangeWeaponSet(3)
	; move to initial location to fight first group of foes
	MoveTo(12000, -4600)
	If WaitAndFightEnemiesInArea($warsupply_fight_options) == $FAIL Then Return $FAIL
	; proceeding with the quest, second dialogs can be safely skipped to speed up farm runs
	If RunWayPoints() == $FAIL Then Return $FAIL
	; clearing final area
	If WaitAndFightEnemiesInArea($warsupply_fight_options) == $FAIL Then Return $FAIL

	; loop to wait out in-game countdown to exit quest automatically
	Local $exitTimer = TimerInit()
	While GetMapID() <> $ID_HALL_OF_MONUMENTS And IsPlayerAlive()
		Sleep(1000)
		; if 2 minutes elapsed after a final fight and still not left the then some stuck occurred, therefore exiting
		If TimerDiff($exitTimer) > 120000 Then Return $FAIL
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
	Local $x, $y, $log, $range, $me, $Miku
	For $i = 0 To UBound($wayPoints) - 1
		;If GetMapLoading() == 2 Or (GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS And GetMapID() <> $ID_HALL_OF_MONUMENTS) Then Disconnected()
		$x = $wayPoints[$i][0]
		$y = $wayPoints[$i][1]
		$log = $wayPoints[$i][2]
		If MoveAggroAndKill($x, $y, $log, $warsupply_fight_options) == $FAIL Then Return $FAIL
		; wait for initial group to appear in front of player, because they appear suddenly and can't be detected in advance
		If $i == 2 Or $i == 3 Then Sleep(3000)
		; wait for pre forest group to clear it because not clearing it can result in fail by Miku pulling this group into forest (2-3 groups at once)
		If $i == 9 Or $i == 10 Then Sleep(3000)
		; Between waypoints ensure that everything is fine with player and Miku
		While IsPlayerAlive()
			If CheckStuck('Waypoint ' & $log, $MAX_WAR_SUPPLY_FARM_DURATION) == $FAIL Then Return $FAIL
			If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then ExitLoop
			$me = GetMyAgent()
			$Miku = GetAgentByID($AGENTID_MIKU)
			; check against some impossible scenarios
			If DllStructGetData($Miku, 'X') == 0 And DllStructGetData($Miku, 'Y') == 0 Then Return $FAIL
			; Using 6th healing skill on the way between waypoints to recover until health is full
			If IsRecharged($KEIRAN_NATURES_BLESSING) And (DllStructGetData($me, 'HealthPercent') < 0.9 Or DllStructGetData($Miku, 'HealthPercent') < 0.9) Then UseSkillEx($KEIRAN_NATURES_BLESSING)
			If CountFoesInRangeOfAgent($me, $warsupply_fight_options.Item('fightRange')) > 0 Then WarSupplyFarmFight($warsupply_fight_options)
			; Ensuring that Miku is not too far
			If GetDistance($me, $Miku) > 1650 Then
				Info('Miku is too far. Trying to move to her location')
				MoveTo(DllStructGetData($Miku, 'X'), DllStructGetData($Miku, 'Y'), 250)
			EndIf
			; continue running through waypoints
			If GetDistance($me, $Miku) < 1650 And Not GetIsDead($Miku) And DllStructGetData($me, 'HealthPercent') > 0.9 And DllStructGetData($Miku, 'HealthPercent') > 0.9 Then ExitLoop
			Sleep(1000)
		WEnd
		If IsPlayerDead() Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


Func WarSupplyFarmFight($options = $warsupply_fight_options)
	If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then Return $FAIL
	Info('Fighting')

	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : 1200
	Local $priorityMobs = ($options.Item('priorityMobs') <> Null) ? $options.Item('priorityMobs') : True

	Local $me = Null
	Local $miku = Null
	Local $foes = Null
	Local $target = Null

	; this loop ends when there are no more foes in range
	While IsPlayerAlive()
		If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then ExitLoop
		If CheckStuck('War Supply fight', $MAX_WAR_SUPPLY_FARM_DURATION) == $FAIL Then Return $FAIL
		; refreshing/sampling all agents state at the start of every loop iteration to not operate on some old, inadequate data
		$me = GetMyAgent()
		$miku = GetAgentByID($AGENTID_MIKU)
		$foes = GetFoesInRangeOfAgent($me, $fightRange)
		If Not IsArray($foes) Or UBound($foes) < 0 Then ExitLoop
		; check to prevent data races when exited quest after doing above map check
		If $miku == Null Then Return $FAIL
		If GetIsDead($miku) Then Warn('Miku dead')
		; no more foes detected in range
		If UBound($foes) == 0 Then ExitLoop

		; use skills 1, 3, 6 in special circumstances, not specifically on current target
		; only use Nature's Blessing skill when it is recharged and player's or Miku's HP is below 90%
		If IsRecharged($KEIRAN_NATURES_BLESSING) And (DllStructGetData($me, 'HealthPercent') < 0.9 Or DllStructGetData($miku, 'HealthPercent') < 0.9) And IsPlayerAlive() Then
			UseSkillEx($KEIRAN_NATURES_BLESSING)
		EndIf

		If IsPlayerDead() Then Return $FAIL
		If GetIsKnocked($me) Then ContinueLoop

		If IsRecharged($KEIRAN_SNIPER_SHOT) And IsPlayerAlive() Then
			For $foe In $foes
				If GetHasHex($foe) And Not GetIsDead($foe) And DllStructGetData($foe, 'ID') <> 0 Then
					UseSkillEx($KEIRAN_SNIPER_SHOT, $foe)
					RandomSleep(100)
					; exit loop iteration to not use any skills on potentially deceased target
					ContinueLoop
				EndIf
			Next
		EndIf

		If IsRecharged($KEIRAN_TERMINAL_VELOCITY) And IsPlayerAlive() Then
			For $foe In $foes
				If GetIsCasting($foe) And Not GetIsDead($foe) And DllStructGetData($foe, 'ID') <> 0 Then
					Switch DllStructGetData($foe, 'Skill')
						; if foe is casting dangerous AoE skill on player then try to interrupt it and evade AoE location
						Case $ID_METEOR_SHOWER, $ID_FIRE_STORM, $ID_RAY_OF_JUDGMENT, $ID_UNSTEADY_GROUND, $ID_SANDSTORM, $ID_SAVANNAH_HEAT
							; attempt to interrupt dangerous AoE skill
							UseSkillEx($KEIRAN_TERMINAL_VELOCITY, $foe)
							; attempt to evade dangerous AoE skill effect just in case interrupt was too late or unsuccessful
							EvadeAoESkillArea()
							ContinueLoop
						; other important skills casted by foes in Auspicious Beginnings quest that are easy to interrupt
						Case $ID_HEALING_SIGNET, $ID_RESURRECTION_SIGNET, $ID_EMPATHY, $ID_ANIMATE_BONE_MINIONS, $ID_VENGEANCE, $ID_TROLL_UNGUENT, _
								$ID_FLESH_OF_MY_FLESH, $ID_ANIMATE_FLESH_GOLEM, $ID_RESURRECTION_CHANT, $ID_RENEW_LIFE, $ID_SIGNET_OF_RETURN
							; attempt to interrupt skill
							UseSkillEx($KEIRAN_TERMINAL_VELOCITY, $foe)
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
			If BitAND(DllStructGetData($foe, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE Then $isFoeAttacking = True
			If GetDistance($miku, $foe) < $RANGE_EARSHOT Then $isFoeInRangeOfMiku = True
			; unfortunately GetTarget() always returns 0, so can't be used here
			;If GetTarget($foe) == $AGENTID_PLAYER Then $isFoeAttackingPlayer = True
			;If GetTarget($foe) == $AGENTID_MIKU Then $isFoeAttackingMiku = True
		Next
		If BitAND(DllStructGetData($me, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE Then $isPlayerAttacking = True
		If BitAND(DllStructGetData($miku, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE Then $isMikuAttacking = True
		If ($isPlayerAttacking And $isFoeAttacking And Not $isFoeInRangeOfMiku And Not $isMikuAttacking And IsPlayerAlive() And Not GetIsDead($miku)) Then
			; move to Miku's position to trigger fight between Miku and mobs
			Move(DllStructGetData($miku, 'X'), DllStructGetData($miku, 'Y'), 300)
			ContinueLoop
		EndIf

		; if target is Null then select a new target for ordinary bow attack skills 2, 4, 5 or exit the loop when there are no more targets in range
		If $target == Null Or GetIsDead($target) Or GetIsDead(GetCurrentTarget()) Or DllStructGetData($target, 'ID') == 0 Then
			$me = GetMyAgent()
			If $priorityMobs Then $target = GetHighestPriorityFoe($me, $fightRange)
			If $target == Null Or GetIsDead($target) Or DllStructGetData($target, 'ID') == 0 Then
				$target = GetNearestEnemyToAgent($me)
				; no more enemy agents found anywhere
				If $target == Null Or GetIsDead($target) Or DllStructGetData($target, 'ID') == 0 Then ExitLoop
				; no more enemy agents found within fight range
				If GetDistance($me, $target) > $fightRange Then ExitLoop
			Endif
			ChangeTarget($target)
			Sleep(100)
			; Start auto-attack on new target
			Attack($target)
			Sleep(100)
		EndIf


		If IsRecharged($KEIRAN_RELENTLESS_ASSAULT) And GetHasCondition($me) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KEIRAN_RELENTLESS_ASSAULT, $target)
			RandomSleep(100)
			ContinueLoop
		EndIf

		If IsRecharged($KEIRAN_RAIN_OF_ARROWS) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KEIRAN_RAIN_OF_ARROWS, $target)
			RandomSleep(100)
			ContinueLoop
		EndIf

		If IsRecharged($KEIRAN_GRAVESTONE_MARKER) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KEIRAN_GRAVESTONE_MARKER, $target)
			RandomSleep(100)
			ContinueLoop
		EndIf

		; only use interrupting 3th skill on current target when all other skills are recharging (interrupting skill is prioritized on more important skills above)
		If IsRecharged($KEIRAN_TERMINAL_VELOCITY) And Not GetIsDead($target) And Not GetIsDead(GetCurrentTarget()) And DllStructGetData($target, 'ID') <> 0 And IsPlayerAlive() Then
			UseSkillEx($KEIRAN_TERMINAL_VELOCITY, $target)
			ContinueLoop
		EndIf
	WEnd
	If IsPlayerDead() Then Return $FAIL
	PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
	Return $SUCCESS
EndFunc


;~ Evade circular area affected with AoE skill into outer circular area using 2 random coordinates in polar system
;~ New random position with absolute offset at least 300, up to 500, which is further than $RANGE_NEARBY=240
Func EvadeAoESkillArea()
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local Const $PI = 3.14
	; range [0, 2*$PI] - full circle in radian degrees
	Local $randomAngle = Random(0, 2 * $PI)
	; range [300, 500] - outside of AoE area
	Local $randomRadius = Random(300, 500)
	Local $offsetX = $randomRadius * cos($randomAngle)
	Local $offsetY = $randomRadius * sin($randomAngle)
	; 0 = no random, because random offset is already calculated
	MoveTo($myX + $offsetX , $myY + $offsetY, 0)
EndFunc