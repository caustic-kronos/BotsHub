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

#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $LightbringerFarmInformations = 'For best results, have :' & @CRLF _
	& '- the quest A Show of Force' & @CRLF _
	& '- the quest Requiem for a Brain' & @CRLF _
	& '- rune of doom in your inventory' & @CRLF _
	& '- use low level heroes to level them up' & @CRLF _
	& '- equip holy damage weapons (monk staves/wands, Verdict (monk hammer) and Unveil (dervish staff)) and on your heroes too if possible' & @CRLF _
	& '- use weapons in this order : holy/daggers-scythes/axe-sword/spear/hammer/wand-staff/bow'
Global Const $LIGHTBRINGER_FARM_DURATION = 25 * 60 * 1000

; Set to 1300 for axe, dagger and sword, 1500 for scythe and spear, 1700 for hammer, wand and staff
Global Const $weaponAttackTime = 1700

Global $LIGHTBRINGER_FARM_SETUP = False
Global $loggingFile

Global Const $Junundu_Strike	= 1
Global Const $Junundu_Smash		= 2
Global Const $Junundu_Bite		= 3
Global Const $Junundu_Siege		= 4
Global Const $Junundu_Tunnel	= 5
Global Const $Junundu_Feast		= 6
Global Const $Junundu_Wail		= 7
Global Const $Junundu_Leave		= 8


;~ Main entry point to the farm - calls the setup if needed, the loop else, and the going in and out of the map
Func LightbringerFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $LIGHTBRINGER_FARM_SETUP Then LightbringerFarmSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToTheSulfurousWastes()
	Local $result = FarmTheSulfurousWastes()
	TravelToOutpost($ID_Remains_of_Sahlahja, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Setup for the Lightbringer farm
Func LightbringerFarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Remains_of_Sahlahja, $DISTRICT_NAME)
	If $LOG_LEVEL == 0 Then $loggingFile = FileOpen(@ScriptDir & '/logs/lightbringer_farm-' & GetCharacterName() & '.log', $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	SetupPlayerLightbringerFarm()
	SetupTeamLightbringerFarm()
	SetDisplayedTitle($ID_Lightbringer_Title)
	SwitchMode($ID_HARD_MODE)
	$LIGHTBRINGER_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func SetupPlayerLightbringerFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		Sleep(500 + GetPing())
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
    Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamLightbringerFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Automatic team builds setup is disabled. Assuming that team builds are set up manually')
    EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


;~ Move out of outpost into the Sulfurous Wastes
Func GoToTheSulfurousWastes()
	If GetMapID() <> $ID_Remains_of_Sahlahja Then TravelToOutpost($ID_Remains_of_Sahlahja, $DISTRICT_NAME)
	While GetMapID() <> $ID_The_Sulfurous_Wastes
		Info('Moving to the Sulfurous Wastes')
		MoveTo(1527, -4114)
		Move(1970, -4353)
		RandomSleep(1000)
		WaitMapLoading($ID_The_Sulfurous_Wastes, 10000, 4000)
	WEnd
EndFunc


;~ Farm the Sulfurous Wastes - main function
Func FarmTheSulfurousWastes()
	If GetMapID() <> $ID_The_Sulfurous_Wastes Then Return $FAIL
	Info('Taking Sunspear Undead Blessing')
	GoToNPC(GetNearestNPCToCoords(-660, 16000))
	Dialog(0x83)
	RandomSleep(1000)
	Dialog(0x85)
	RandomSleep(1000)

	Info('Entering Junundu')
	MoveTo(-615, 13450)
	RandomSleep(5000)
	TargetNearestItem()
	RandomSleep(1500)
	ActionInteract()
	RandomSleep(1500)

	Local Static $foes[30][3] = [ _ ; 30 groups to vanquish
		[-800, 12000, 'First Undead Group 1'], _
		[-1700, 9800, 'First Undead Group 2'], _
		[-3000, 10900, 'Second Undead Group 1'], _
		[-4500, 11500, 'Second Undead Group 2'], _
		[-13250, 6750, 'Third Undead Group'], _
		[-22000, 9000, 'First Margonite Group 1'], _
		[-22350, 11100, 'First Margonite Group 2'], _
		_ ; Skipping this group because it can bring heroes on land and make them go out of Wurm
		_ ;[-21200, 10750, 'Second Margonite Group 1'], _
		_ ;[-20250, 11000, 'Second Margonite Group 2'], _
		[-19000, 5700, 'Djinn Group Group 1'], _ ; range 2200
		[-20800, 600, 'Djinn Group Group 2'], _ ; range 2200
		[-22000, -1200, 'Djinn Group Group 3'], _ ; range 2200
		[-21500, -6000, 'Undead Ritualist Boss Group 1'], _
		[-20400, -7400, 'Undead Ritualist Boss Group 2'], _
		[-19500, -9500, 'Undead Ritualist Boss Group 3'], _
		[-22000, -9400, 'Third Margonite Group 1'], _
		[-22800, -9800, 'Third Margonite Group 2'], _
		[-23000, -10600, 'Fourth Margonite Group 1'], _
		[-23150, -12250, 'Fourth Margonite Group 2'], _
		[-22800, -13500, 'Fifth Margonite Group 1'], _
		[-21300, -14000, 'Fifth Margonite Group 2'], _
		[-22800, -13500, 'Sixth Margonite Group 1'], _
		[-23000, -10600, 'Sixth Margonite Group 2'], _
		[-21500, -9500, 'Sixth Margonite Group 3'], _
		[-21000, -9500, 'Seventh Margonite Group 1'], _
		[-19500, -8500, 'Seventh Margonite Group 2'], _
		[-22000, -9400, 'Temple Monolith Group 1'], _
		[-23000, -10600, 'Temple Monolith Group 2'], _
		[-22800, -13500, 'Temple Monolith Group 3'], _
		[-19500, -13100, 'Temple Monolith Group 4'], _
		[-18000, -13100, 'Temple Monolith Group 5'], _
		[-18000, -13100, 'Margonite Boss Group'] _
	]

	If DoForArrayRows($foes, 1, 4, MoveToAndAggroWithJunundu) == $FAIL Then Return $FAIL
	SpeedTeam()
	MoveTo(-7500, 11925)
	SpeedTeam()
	MoveTo(-9800, 12400)
	SpeedTeam()
	MoveTo(-13000, 9500)
	If DoForArrayRows($foes, 5, 5, MoveToAndAggroWithJunundu) == $FAIL Then Return $FAIL

	Info('Taking Lightbringer Margonite Blessing')
	SpeedTeam()
	MoveTo(-20600, 7270)
	GoToNPC(GetNearestNPCToCoords(-20600, 7270))
	RandomSleep(1000)
	Dialog(0x85)
	RandomSleep(1000)

	If DoForArrayRows($foes, 6, 19, MoveToAndAggroWithJunundu) == $FAIL Then Return $FAIL

	Info('Picking Up Tome')
	SpeedTeam()
	MoveTo(-21300, -14000)
	TargetNearestItem()
	RandomSleep(50)
	ActionInteract()
	RandomSleep(2000)
	DropBundle()
	RandomSleep(1000)

	If DoForArrayRows($foes, 20, 29, MoveToAndAggroWithJunundu) == $FAIL Then Return $FAIL

	Info('Spawning Margonite bosses')
	SpeedTeam()
	MoveTo(-16000, -13100)
	SpeedTeam()
	MoveTo(-18180, -13540)
	RandomSleep(1000)
	TargetNearestItem()
	RandomSleep(250)
	ActionInteract()
	RandomSleep(3000)
	DropBundle()
	RandomSleep(1000)

	If DoForArrayRows($foes, 30, 30, MoveToAndAggroWithJunundu) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ All team uses Junundu_Tunnel to speed party up
Func SpeedTeam()
	If (IsRecharged($Junundu_Tunnel)) Then
		UseSkillEx($Junundu_Tunnel)
		AllHeroesUseSkill($Junundu_Tunnel)
	EndIf
EndFunc


;~ Optional function to move and aggro a group of mob at maximally 5 locations
;~ Return $FAIL if the party is dead, $SUCCESS if not
Func MultipleMoveToAndAggro($foesGroup, $location0x = 0, $location0y = 0, $location1x = Null, $location1y = Null, $location2x = Null, $location2y = Null, $location3x = Null, $location3y = Null, $location4x = Null, $location4y = Null)
	For $i = 0 To 4
		If (Eval('location' & $i & 'x') == Null) Then ExitLoop
		If MoveToAndAggroWithJunundu(Eval('location' & $i & 'x'), Eval('location' & $i & 'y'), $foesGroup) == $FAIL Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


;~ Main method for moving around and aggroing/killing mobs
;~ Return $FAIL if the party is dead, $SUCCESS if not
Func MoveToAndAggroWithJunundu($x, $y, $foesGroup)
	Info('Killing ' & $foesGroup)
	Local $range = 1650

	; Speed up team using Junundu Tunnel
	; Get close enough to cast spells but not Aggro
	; Use Junundu Siege (4) until it's in countdown
	; While there are enemies
	;	Use Junundu Tunnel (5) unless it's on countdown
	;	Use Junundu Bite (3) off countdown
	;	Use Junundu Smash (2) if available
	;		Don't use Junundu Feast (6) if an enemy died (would need to check what skill we get afterward ...)
	;	Use Junundu Strike (1) in between
	;	Else just attack
	; Use Junundu Wail (7) after fight only and if life is < 2400/3000 or if a team member is dead

	Local $skillCastTimer
	SpeedTeam()

	Local $target = GetNearestNPCInRangeOfCoords($x, $y, 3, $range)
	If (DllStructGetData($target, 'X') == 0) Then
		MoveTo($x, $y)
		FindAndOpenChests($RANGE_SPIRIT)
		Return $SUCCESS
	EndIf

	GetAlmostInRangeOfAgent($target)

	$skillCastTimer = TimerInit()
	While IsRecharged($Junundu_Siege) And TimerDiff($skillCastTimer) < 3000
		UseSkillEx($Junundu_Siege, $target)
		RandomSleep(20)
	WEnd

	Local $me = GetMyAgent()
	Local $foes = 1
	While $foes <> 0
		$target = GetNearestEnemyToAgent($me)
		If (IsRecharged($Junundu_Tunnel)) Then UseSkillEx($Junundu_Tunnel)
		CallTarget($target)
		Sleep(20)
		If (GetSkillbarSkillAdrenaline($Junundu_Smash) == 130) Then UseSkillEx($Junundu_Smash)
		AttackOrUseSkill($weaponAttackTime, $Junundu_Bite, $Junundu_Strike)
		$me = GetMyAgent()
		$foes = CountFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	WEnd

	If DllStructGetData($me, 'HealthPercent') < 0.75 Or CountAliveHeroes() > 0 Then
		UseSkillEx($Junundu_Wail)
	EndIf
	RandomSleep(1000)

	If CountAliveHeroes() < 2 Then Return $FAIL ; situation when most of the team is wiped
	PickUpItems()
	FindAndOpenChests($RANGE_SPIRIT)

	Return $SUCCESS
EndFunc