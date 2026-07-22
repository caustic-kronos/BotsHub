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
; AutoIt Version:	3.3.18.0
; Original Author:	Danylia
; Modified Author:	RiflemanX
; Modified Author:	Zaishen Silver
; Rewrite Author for BotsHub: Gahais
#CE ===========================================================================

#include-once
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $WAR_SUPPLY_KEIRAN_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- (Weapon Slot-3) Shortbow +15/-5 vamp +5 armor is the best weapon' & @CRLF _
	& '- (Weapon Slot-4) Keirans Bow' & @CRLF _
	& '- Ideal character is warrior with 5x Knights Insignias and the Absorption -3 superior rune and 4 runes each of restoration/recovery/clarity/purity' & @CRLF _
	& '- When in Keiran Thackerays disguise, armor is 70, health is 600 and energy is 25' & @CRLF _
	& '- Consumables, insignias, runes, weapon upgrade components will not change health, energy, or attributes; they will otherwise work as expected (e.g. they will increase armor rating)' & @CRLF _
	& '- This bot does not need any specific builds for main character or heroes' & @CRLF _
	& '- Only main character enters Auspicious Beginnings mission and is assigned Keiran Thackerays build for the duration of the quest' & @CRLF _
	& ' ' & @CRLF _
	& 'Any character can go into Auspicious Beginnings mission if you send the right dialog ID (already in script) to Guild Wars client' & @CRLF _
	& 'You just need the Keirans Bow which Gwen gives when the right dialog ID is sent to Guild Wars client' & @CRLF _
	& 'You do not need to have progress in Guild Wars Beyond campaign to be able enter this mission (even when these dialog options are not visible)' & @CRLF _
	& 'This bot is useful for farming War Supplies, festival items, platinum and Ebon Vanguard reputation' & @CRLF
; Average duration ~ 8 minutes
Global Const $WAR_SUPPLY_FARM_DURATION		= 8 * 60 * 1000
Global Const $MAX_WAR_SUPPLY_FARM_DURATION	= 16 * 60 * 1000

Global Const $KEIRAN_SNIPER_SHOT			= 1
Global Const $KEIRAN_GRAVESTONE_MARKER		= 2
Global Const $KEIRAN_TERMINAL_VELOCITY		= 3
Global Const $KEIRAN_RAIN_OF_ARROWS			= 4
Global Const $KEIRAN_RELENTLESS_ASSAULT		= 5
Global Const $KEIRAN_NATURES_BLESSING		= 6
Global Const $KEIRAN_UNUSED_7TH_SKILL		= 7
Global Const $KEIRAN_UNUSED_8TH_SKILL		= 8

; Keiran energy skills costs are reduced by expertise level 20
Global Const $KEIRAN_SKILLS_ARRAY			= [$KEIRAN_SNIPER_SHOT,	$KEIRAN_GRAVESTONE_MARKER,	$KEIRAN_TERMINAL_VELOCITY,	$KEIRAN_RAIN_OF_ARROWS,	$KEIRAN_RELENTLESS_ASSAULT,	$KEIRAN_NATURES_BLESSING,	$KEIRAN_UNUSED_7TH_SKILL,	$KEIRAN_UNUSED_8TH_SKILL]
Global Const $KEIRAN_SKILLS_COSTS_ARRAY		= [2,					2,							1,							1,						3,							2,						0,						0]
Global Const $KEIRAN_SKILLS_COSTS_MAP		= MapFromArrays($KEIRAN_SKILLS_ARRAY, $KEIRAN_SKILLS_COSTS_ARRAY)

Global $warsupply_fight_options					= CloneMap($default_move_aggro_kill_options)
$warsupply_fight_options['killMethod']			= WarSupplyFarmFight
$warsupply_fight_options['fightRange']			= $RANGE_LONGBOW
$warsupply_fight_options['fightTimeout']		= 3 * 60 * 1000
; approximate 20 seconds max duration of initial and final fight
$warsupply_fight_options['priorityTargeting']	= True
$warsupply_fight_options['callTarget']			= False
; Only Krytan chests in Auspicious Beginnings quest which may have useless loot
$warsupply_fight_options['openChests']			= True
$warsupply_fight_options['skillsCostMap']		= $KEIRAN_SKILLS_COSTS_MAP

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
		Info('Could not find Keirans bow in players inventory')
		GetKeiranBow()
	Else
		Info('Found Keirans bow in players inventory')
	EndIf
	SwitchToKeiranBowToEnterQuest()
	If Not IsItemEquippedInWeaponSlot($ID_KEIRANS_BOW, 4) Then
		Info('Equipping Keirans bow')
		EquipItemByModelID($ID_KEIRANS_BOW)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	$warsupply_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func GetKeiranBow()
	Info('Getting Keirans bow to be able to enter the quest')
	TravelToOutpost($ID_EYE_OF_THE_NORTH, $district_name)
	EnterHallOfMonuments()
	; hexadecimal code of dialog ID to receive keirans bow
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
		Move(-4779, 5209)
		WaitMapLoading($ID_HALL_OF_MONUMENTS)
	EndIf
	Return GetMapID() == $ID_HALL_OF_MONUMENTS ? $SUCCESS : $FAIL
EndFunc


Func EnterAuspiciousBeginningsQuest()
	If GetMapID() <> $ID_HALL_OF_MONUMENTS Then Return $FAIL
	; hexadecimal code of dialog id to start Auspicious Beginnings quest
	Local $questDialogID = 0x64B
	Info('Entering Auspicious Beginnings quest')
	SwitchToKeiranBowToEnterQuest()
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

	SwitchToDamageBow()
	; proceeding with the quest, second dialogs can be safely skipped to speed up farm runs
	If RunWayPoints() == $FAIL Then Return $FAIL

	; loop to wait out in-game countdown to exit quest automatically
	Local $exitTimer = TimerInit()
	While GetMapID() <> $ID_HALL_OF_MONUMENTS And IsPlayerAlive()
		Sleep(1000)
		; if 2 minutes elapsed after a final fight and still not left the then some stuck occurred, therefore exiting
		If TimerDiff($exitTimer) > 120000 Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


Func RunWayPoints()
	; Tiny waits everywhere to let time for Miku to join us
	Local $wayPoints[][] = [ _
		[11900,		-4800,	'Group 1',			20	], _
		[10700,		-5700,	'Group 2',			5	], _
		[9600,		-6700,	'Moving',			1	], _
		[8700,		-8000,	'Group 3',			1	], _
		[8000,		-8600,	'Moving',			1	], _
		[6900,		-8400,	'Moving',			1	], _
		[5700,		-8000,	'Group 4',			15	], _
		[4600,		-9230,	'Moving',			0	], _
		[3750,		-10000, 'Moving',			0	], _
		[3070,		-11300,	'Avoiding Group 5',	0	], _
		[2250,		-12300,	'Moving',			0	], _
		[1100,		-13200,	'Avoiding Group 6',	0	], _
		[-200,		-12800,	'Moving',			0	], _
		[-1000,		-12250,	'Moving',			0	], _
		_ ;-1400,	-11500
		[-2000,		-11600,	'Group 7',			2	], _
		[-4250,		-12400,	'Moving',			2	], _
		[-5150,		-12800,	'Moving',			0	], _
		[-6900,		-12100,	'Moving',			2	], _
		[-6900,		-10500,	'Group 8',			2	], _
		[-8200,		-9850,	'Moving',			2	], _
		[-8700,		-9100,	'Moving',			2	], _
		[-10100,	-8400,	'Group 9',			2	], _
		[-13400,	-8000,	'Moving',			2	], _
		[-16775,	-9000,	'Last group wait',	20	], _
		[-16000,	-8500,	'Last group kill',	0	] _
	]

	Info('Running through way points')
	Local $me = GetMyAgent()
	Local $miku = GetAgentByID($AGENTID_MIKU)
	For $i = 0 To UBound($wayPoints) - 1
		If CheckStuck('Waypoint ' & $wayPoints[$i][2], $MAX_WAR_SUPPLY_FARM_DURATION) == $FAIL Then Return $FAIL
		If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then Return $FAIL

		If MoveAggroAndKill($wayPoints[$i][0], $wayPoints[$i][1], $wayPoints[$i][2], $warsupply_fight_options) == $FAIL Then Return $FAIL

		; We have to wait for those places (first, second, preforest and last groups)
		If $wayPoints[$i][3] <> 0 Then
			Local $foe = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
			Local $wait = 0
			While $foe == Null And $wait < $wayPoints[$i][3]
				Sleep(1000)
				$me = GetMyAgent()
				$foe = GetNearestEnemyToAgent($me, $RANGE_EARSHOT)
				$wait += 1
			WEnd
		EndIf
		If IsPlayerDead() Then Return $FAIL

		$me = GetMyAgent()
		$miku = GetAgentByID($AGENTID_MIKU)
		; Between waypoints ensure that everything is fine with player and Miku
		While GetDistance($me, $miku) > 1650 Or KeiranOrMikuNeedsHealing($me, $miku) Or GetIsDead($miku)
			If CheckStuck('Waypoint ' & $wayPoints[$i][2], $MAX_WAR_SUPPLY_FARM_DURATION) == $FAIL Then Return $FAIL
			If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then Return $FAIL
			; Using healing skill on the way between waypoints to recover until health is full
			If KeiranOrMikuNeedsHealing($me, $miku) And IsRecharged($KEIRAN_NATURES_BLESSING) Then UseSkillEx($KEIRAN_NATURES_BLESSING)
			; Moving to Miku
			If GetDistance($me, $miku) > 1650 And MoveAggroAndKill(DllStructGetData($miku, 'X'), DllStructGetData($miku, 'Y'), 'Moving to Miku', $warsupply_fight_options) == $FAIL Then Return $FAIL
			Sleep(1000)
			$me = GetMyAgent()
			$miku = GetAgentByID($AGENTID_MIKU)
			If IsPlayerDead() Then Return $FAIL
		WEnd
	Next
	Return $SUCCESS
EndFunc


Func WarSupplyFarmFight($target, $options = $warsupply_fight_options)
	If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then Return $FAIL

	GetAlmostInRangeOfAgent($target)
	Attack($target)
	PingSleep(100)

	Local $fightRange	= $options['fightRange'] <> Null ?		$options['fightRange'] : $RANGE_LONGBOW
	Local $me = GetMyAgent()
	Local $miku = GetAgentByID($AGENTID_MIKU)
	; this loop ends when there are no more foes in range
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		If CheckStuck('War Supply fight', $MAX_WAR_SUPPLY_FARM_DURATION) == $FAIL Then Return $FAIL
		If GetMapID() <> $ID_AUSPICIOUS_BEGINNINGS Then Return $FAIL
		If IsPlayerDead() Then Return $FAIL
		; check to prevent data races when exited quest after doing above map check
		If $miku == Null Then Return $FAIL

		; Skill 6 : only use when player or Miku HP are below 90%
		If KeiranOrMikuNeedsHealing($me, $miku) And IsRecharged($KEIRAN_NATURES_BLESSING) Then UseSkillEx($KEIRAN_NATURES_BLESSING)

		; Always ensure auto-attack is active before using skills
		Attack($target)
		PingSleep(50)

		Local $foes = GetFoesInRangeOfAgent($me, $fightRange)
		Local $hexFoe = Null
		Local $interruptFoe = Null
		Local $evade = False
		For $foe In $foes
			If GetHasHex($foe) Then
				$hexFoe = $foe
				ExitLoop
			ElseIf GetIsCasting($foe) Then
				Switch DllStructGetData($foe, 'Skill')
					; if foe is casting dangerous AoE skill on player then try to interrupt it and evade AoE location
					Case $ID_METEOR_SHOWER, $ID_FIRE_STORM, $ID_RAY_OF_JUDGMENT, $ID_UNSTEADY_GROUND, $ID_SANDSTORM, $ID_SAVANNAH_HEAT
						$interruptFoe = $foe
						$evade = True
						ExitLoop
					; other important skills casted by foes in Auspicious Beginnings quest that are easy to interrupt
					Case $ID_HEALING_SIGNET, $ID_RESURRECTION_SIGNET, $ID_EMPATHY, $ID_ANIMATE_BONE_MINIONS, $ID_VENGEANCE, $ID_TROLL_UNGUENT, _
							$ID_FLESH_OF_MY_FLESH, $ID_ANIMATE_FLESH_GOLEM, $ID_RESURRECTION_CHANT, $ID_RENEW_LIFE, $ID_SIGNET_OF_RETURN
						$interruptFoe = $foe
						ExitLoop
				EndSwitch
			EndIf
		Next

		; If knocked the others skills cannot be used
		If GetIsKnocked($me) Then
			Sleep(500)
		; Situation when Miku stays behind player and does not attack, because mobs are too far beyond her range but they can attack the player from sufficient distance (rangers and spellcasters)
		ElseIf ShouldEnsureMikuAttacks($me, $miku, $foes) Then
			; We compute a spot right behind Miku and we move there
			Local $dx = DllStructGetData($miku, 'X') - DllStructGetData($me, 'X')
			Local $dy = DllStructGetData($miku, 'Y') - DllStructGetData($me, 'Y')
			Local $length = Sqrt($dx * $dx + $dy * $dy)
			Local $targetX = DllStructGetData($miku, 'X') + $dx / $length * $RANGE_NEARBY
			Local $targetY = DllStructGetData($miku, 'Y') + $dy / $length * $RANGE_NEARBY
			MoveTo($targetX, $targetY)
		; Skill 1 : use on any foe with a hex
		ElseIf IsRecharged($KEIRAN_SNIPER_SHOT) And $hexFoe <> Null Then
			UseSkillEx($KEIRAN_SNIPER_SHOT, $hexFoe)
			RandomSleep(100)
		; Skill 3 : use to interrupt foes
		ElseIf IsRecharged($KEIRAN_TERMINAL_VELOCITY) And $interruptFoe <> Null Then
			; attempt to interrupt dangerous AoE skill
			; or another important skills casted by foes in Auspicious Beginnings quest that are easy to interrupt
			UseSkillEx($KEIRAN_TERMINAL_VELOCITY, $interruptFoe)
			; attempt to evade dangerous AoE skill effect just in case interrupt was too late or unsuccessful
			If $evade Then EvadeAoESkillArea()
		; Other skills can be used all the time
		ElseIf IsRecharged($KEIRAN_RELENTLESS_ASSAULT) And GetHasCondition($me) Then
			UseSkillEx($KEIRAN_RELENTLESS_ASSAULT, $target)
			RandomSleep(100)
		ElseIf IsRecharged($KEIRAN_RAIN_OF_ARROWS) Then
			UseSkillEx($KEIRAN_RAIN_OF_ARROWS, $target)
		ElseIf IsRecharged($KEIRAN_GRAVESTONE_MARKER) Then
			UseSkillEx($KEIRAN_GRAVESTONE_MARKER, $target)
			RandomSleep(100)
		; Terminal velocity will still be used if all other skills are on CD - prioritized earlier for interrupt
		ElseIf IsRecharged($KEIRAN_TERMINAL_VELOCITY) Then
			UseSkillEx($KEIRAN_TERMINAL_VELOCITY, $target)
		EndIf
		; Slow move in order to reduce cases where view of the target is obstructed
		If GetDistance($me, $target) > $RANGE_AREA Then Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
		Sleep(500)
		$me = GetMyAgent()
		$miku = GetAgentByID($AGENTID_MIKU)
		$target = GetCurrentTarget()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


Func ShouldEnsureMikuAttacks($me, $miku, $foes)
	Local $isPlayerAttacking = False
	Local $isMikuAttacking = False
	If BitAND(DllStructGetData($me, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE Then $isPlayerAttacking = True
	If BitAND(DllStructGetData($miku, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE Then $isMikuAttacking = True
	If $isPlayerAttacking And Not $isMikuAttacking And Not GetIsDead($miku) Then
		Local $isFoeAttacking = False
		Local $isFoeInRangeOfMiku = False
		For $foe In $foes
			If BitAND(DllStructGetData($foe, 'TypeMap'), 0x1) == $ID_TYPEMAP_ATTACK_STANCE Then $isFoeAttacking = True
			If GetDistance($miku, $foe) < $RANGE_EARSHOT Then $isFoeInRangeOfMiku = True
			If $isFoeAttacking And $isFoeInRangeOfMiku Then ExitLoop
		Next
		If $isFoeAttacking And Not $isFoeInRangeOfMiku Then Return True
	EndIf
	Return False
EndFunc


;~ Evade circular area affected with AoE skill into outer circular area using 2 random coordinates in polar system
;~ New random position with absolute offset at least 300, up to 500, which is further than $RANGE_NEARBY = 240
Func EvadeAoESkillArea()
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	MoveToRadial($myX, $myY, 400)
EndFunc


;~ Return true if Miku or Keiran have low life
Func KeiranOrMikuNeedsHealing($me, $miku)
	Return DllStructGetData($me, 'HealthPercent') < 0.75 Or DllStructGetData($miku, 'HealthPercent') < 0.75
EndFunc


Func SwitchToKeiranBowToEnterQuest()
	Info('Changing Weapons: Slot-4 Keiran Bow')
	PingSleep(200)
	ChangeWeaponSet(4)
	PingSleep(200)
EndFunc

Func SwitchToDamageBow()
	Info('Changing weapons to 3th slot with custom modded bow')
	PingSleep(200)
	ChangeWeaponSet(3)
	PingSleep(200)
EndFunc