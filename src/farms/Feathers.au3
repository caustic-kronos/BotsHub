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
Global Const $DA_FEATHERS_FARMER_SKILLBAR = 'OgCjkmrMbS3ljbHY7XmXsXfbNXA'
Global Const $FEATHERS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Prayers' & @CRLF _
	& '- 10 in Scythe Mastery' & @CRLF _
	& '- 10 in Mysticism' & @CRLF _
	& '- A scythe with +5 energy and +20% enchantment duration' & @CRLF _
	& '- Windwalker or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 8m20
Global Const $FEATHERS_FARM_DURATION = (8 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($FEATHERS_SAND_SHARDS) is better than UseSkillEx(1))
Global Const $FEATHERS_DWARVEN_STABILITY	= 1
Global Const $FEATHERS_ZEALOUS_RENEWAL		= 2
Global Const $FEATHERS_PIOUS_HASTE			= 3
Global Const $FEATHERS_INTIMIDATING_AURA	= 4
Global Const $FEATHERS_SAND_SHARDS			= 5
Global Const $FEATHERS_MYSTIC_REGENERATION	= 6
Global Const $FEATHERS_VOW_OF_STRENGTH		= 7
Global Const $FEATHERS_EREMITES_ATTACK		= 8

Global Const $MODELID_SENSALI_CLAW			= 3995
Global Const $MODELID_SENSALI_DARKFEATHER	= 3997
Global Const $MODELID_SENSALI_CUTTER		= 3999

Global $feathers_farm_setup = False

;~ Main method to farm feathers
Func FeathersFarm()
	If Not $feathers_farm_setup And SetupFeathersFarm() == $FAIL Then Return $PAUSE

	GoToJayaBluffs()
	Local $result = FeathersFarmLoop()
	ResignAndReturnToOutpost($ID_SEITUNG_HARBOR)
	Return $result
EndFunc


;~ Feathers farm setup
Func SetupFeathersFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_SEITUNG_HARBOR, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFeathersFarm() == $FAIL Then Return $FAIL
	LeaveParty()

	Info('Entering Jaya Bluffs')
	UseCitySpeedBoost()
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, 17300, 17300) > 5000 Then MoveTo(17000, 12400)
	If GetDistanceToPoint($me, 17300, 17300) > 4400 Then MoveTo(19000, 13450)
	If GetDistanceToPoint($me, 17300, 17300) > 1800 Then MoveTo(18750, 16000)

	GoToJayaBluffs()
	MoveTo(10500, -13100)
	Move(10970, -13360)
	RandomSleep(1000)
	WaitMapLoading($ID_SEITUNG_HARBOR, 10000, 2000)
	$feathers_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFeathersFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_DERVISH Then
		LoadSkillTemplate($DA_FEATHERS_FARMER_SKILLBAR)
		RandomSleep(250)
	Else
		Error('Should run this farm as dervish')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Jaya Bluffs
Func GoToJayaBluffs()
	TravelToOutpost($ID_SEITUNG_HARBOR, $district_name)
	While GetMapID() <> $ID_JAYA_BLUFFS
		Info('Moving to Jaya Bluffs')
		MoveTo(17300, 17300)
		Move(16800, 17550)
		RandomSleep(1000)
		WaitMapLoading($ID_JAYA_BLUFFS, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func FeathersFarmLoop()
	If GetMapID() <> $ID_JAYA_BLUFFS Then Return $FAIL

	Info('Running to Sensali.')
	MoveTo(9000, -12400, 0, 0, FeathersRun)
	MoveTo(7950, -10800, 0, 0, FeathersRun)
	MoveTo(3300, -8950, 0, 0, FeathersRun)
	MoveTo(1550, -6650, 0, 0, FeathersRun)
	;ToggleMapping(4)

	; 15 groups to kill
	;~ Local Static $sensalis[][] = [ _
	;~	[-472,		-4342,	'First sensali group'	], _
	;~	[-1536,		-1686,	'Second sensali group'		], _
	;~	[586,		-76,	'Third sensali group'		], _
	;~	[-1556,		2786,	'Fourth sensali group'		], _
	;~	[-2229,		-815,	'Fifth sensali group'		], _
	;~	[-5247,		-3290,	'Sixth sensali group'		], _
	;~	[-6994,		-2273,	'Seventh sensali group'		], _
	;~	[-5042,		-6638,	'Eighth sensali group'		], _
	;~	[-11040,	-8577,	'Ninth sensali group'		], _
	;~	[-10860,	-2840,	'Tenth sensali group'		], _
	;~	[-14900,	-3000,	'Eleventh sensali group'	], _
	;~	[-12200,	150,	'Twelfth sensali group'		], _
	;~	[-12500,	4000,	'Thirteenth sensali group'	], _
	;~	[-12111,	1690,	'Fourteenth sensali group'	], _
	;~	[-10303,	4110,	'Fifteenth sensali group'	], _
	;~	[-10500,	5500,	'Sixteenth sensali group'	], _
	;~	[-9700,		2400,	'Seventeenth sensali group'	] _
	;~ ]
	Local Static $sensalis[][] = [ _
		[0,			-5000,	'Sensali group 1'			], _
		[-1000,		-3500,	'Spot 1 - Plain'			], _
		[-1000,		-2500,	'Sensali group 2'			], _
		[1000,		-500,	'Sensali group 3'			], _
		[-500,		1500,	'Spot 2 - Shrine'			], _
		[-1000,		2500,	'Sensali group 4'			], _
		[-2400,		-1000,	'Sensali group 2 bis'		], _
		[-3000,		-3000,	'Spot 3 - Promontory'		], _
		[-4500,		-3000,	'Sensali group 5'			], _
		[-6000,		-3500,	'Spot 4 - Downhill'			], _
		[-7000,		-2500,	'Sensali group 6'			], _
		[-5000,		-3500,	'Spot 5 - Bridge'			], _
		[-5000,		-7000,	'Sensali group 7'			], _
		[-8500,		-8500,	'Sensali group 8'			], _
		[-10000,	-9000,	'Sensali group 9'			], _
		[-8500,		-6500,	'Spot 3 - Over the lake'	], _
		[-9750,		-5000,	'Spot 4 - Slightly further'	], _
		[-10500,	-3000,	'Sensali group 10'			], _
		[-10000,	-500,	'Spot 5 - Under mountain'	], _
		[-9500,		2500,	'Sensali group 11'			], _
		[-10000,	4000,	'Spot 6 - The Island'		], _
		[-10500,	5500,	'Sensali group 12'			], _
		[-11000,	2500,	'Spot 7 - On the ledge'		], _
		[-12500,	5000,	'Sensali group 13'			], _
		[-12500,	500,	'Yeti warrior boss'			], _
		[-14500,	-2500,	'Sensali group 14'			] _
	]
	For $i = 0 To UBound($sensalis) - 1
		If MoveAndKillSensali($sensalis[$i][0], $sensalis[$i][1], $sensalis[$i][2]) == $FAIL And $i <> UBound($sensalis) - 1 Then Return $FAIL
	Next
	;ToggleMapping(4)
	Return $SUCCESS
EndFunc


Func MoveAndKillSensali($x, $y, $message)
	Info($message)
	; Move until we are at position or until we aggroed a sensali
	Local $me = GetMyAgent()
	Local $sensali = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $MOB_AGGRO_RANGE, IsSensali)
	While GetDistanceToPoint($me, $x, $y) > $RANGE_AREA And $sensali == Null
		FeathersRun()
		Move($x, $y)
		RandomSleep(1000)
		If IsPlayerDead() Then Return $FAIL
		$me = GetMyAgent()
		$sensali = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $MOB_AGGRO_RANGE, IsSensali)
	WEnd
	; No sensali around, we can consider this group as cleared and move on to the next one
	If $sensali == Null Then Return $SUCCESS

	; Once we have aggroed at least one sensali, we cast our long lasting buffs
	If IsRecharged($FEATHERS_INTIMIDATING_AURA) Then UseSkillEx($FEATHERS_INTIMIDATING_AURA)
	If IsRecharged($FEATHERS_SAND_SHARDS) Then UseSkillEx($FEATHERS_SAND_SHARDS)
	CastMysticRegeneration()

	; Move to furthest sensali - either a caster or they aggroed on a yeti and we want to go on them
	$me = GetMyAgent()
	$sensali = GetFurthestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_EARSHOT, IsSensali)
	Local $counter = 0
	While $counter < 10
		CastMysticRegeneration()
		If $counter > 6 Then CheckAndSendStuckCommand()
		Move(DllStructGetData($sensali, 'X'), DllStructGetData($sensali, 'Y'))
		RandomSleep(1000)
		$counter += 1
		If IsPlayerDead() Then Return $FAIL
		$me = GetMyAgent()
		$sensali = GetAgentByID(DllStructGetData($sensali, 'ID'))
		If GetDistance($me, $sensali) < $RANGE_AREA Then
			$sensali = GetFurthestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_EARSHOT, IsSensali)
		EndIf
		If GetDistance($me, $sensali) < $RANGE_AREA Then ExitLoop
	WEnd

	; Now we wait until foes are all around, maximum 10s
	Local $counter = 0
	$sensali = GetFurthestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_EARSHOT, IsSensali)
	While Not IsRecharged($FEATHERS_ZEALOUS_RENEWAL) Or (GetDistance($me, $sensali) > $RANGE_AREA And $counter < 10)
		CastMysticRegeneration()
		RandomSleep(1000)
		$counter += 1
		If $counter > 5 Then CheckAndSendStuckCommand()
		If IsPlayerDead() Then Return $FAIL
		$me = GetMyAgent()
		$sensali = GetFurthestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_EARSHOT, IsSensali)
	WEnd

	; Those do not last that long, we cast them last moment
	UseSkillEx($FEATHERS_VOW_OF_STRENGTH)
	RandomSleep(250)
	UseSkillEx($FEATHERS_ZEALOUS_RENEWAL)
	RandomSleep(250)
	$me = GetMyAgent()
	Local $attempts = 0
	While IsRecharged($FEATHERS_EREMITES_ATTACK)
		$sensali = GetNearestEnemyToAgent($me, $RANGE_ADJACENT)
		If $sensali == Null Then CheckAndSendStuckCommand()
		UseSkillEx($FEATHERS_EREMITES_ATTACK, $sensali)
		$attempts += 1
		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Or $attempts > 7 Then Return
	WEnd

	$sensali = GetNearestEnemyToAgent($me, $RANGE_AREA)
	While $sensali <> Null And IsSensali($sensali) And Not GetIsDead($sensali)
		CastMysticRegeneration()
		If IsRecharged($FEATHERS_VOW_OF_STRENGTH) Then UseSkillEx($FEATHERS_VOW_OF_STRENGTH)
		Attack($sensali)
		RandomSleep(750)
		If IsPlayerDead() Then Return $FAIL
		$me = GetMyAgent()
		$sensali = GetNearestEnemyToAgent($me, $RANGE_AREA)
	WEnd
	RandomSleep(250)
	PickUpItems()
	FindAndOpenChests()
	Return $SUCCESS
EndFunc


;~ Cast Mystic Regeneration only when needed
Func CastMysticRegeneration()
	Local Static $mysticTimer = Null
	If ($mysticTimer == Null Or TimerDiff($mysticTimer) > 24000) And IsRecharged($FEATHERS_MYSTIC_REGENERATION) Then
		UseSkillEx($FEATHERS_MYSTIC_REGENERATION)
		$mysticTimer = TimerInit()
	EndIf
EndFunc


;~ Running help
Func FeathersRun()
	;~ If pious haste is available, use it
	If IsRecharged($FEATHERS_PIOUS_HASTE) Then
		If IsRecharged($FEATHERS_DWARVEN_STABILITY) Then UseSkillEx($FEATHERS_DWARVEN_STABILITY)
		UseSkillEx($FEATHERS_ZEALOUS_RENEWAL)
		RandomSleep(250)
		UseSkillEx($FEATHERS_PIOUS_HASTE)
	EndIf

	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.7 Then CastMysticRegeneration()
EndFunc


;~ Return True if agent is a Sensali
Func IsSensali($agent)
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If IsNearlyEqual(DllStructGetData($agent, 'HealthPercent'), 0) Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then Return False
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return $modelID == $MODELID_SENSALI_CLAW _
		Or $modelID == $MODELID_SENSALI_DARKFEATHER _
		Or $modelID == $MODELID_SENSALI_CUTTER
EndFunc
