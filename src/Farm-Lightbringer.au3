; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'

Local Const $LightbringerFarmInformations = 'For best results, have :' & @CRLF _
	& '- the quest A Show of Force' & @CRLF _
	& '- the quest Requiem for a Brain' & @CRLF _
	& '- rune of doom in your inventory' & @CRLF _
	& '- use low level heroes to level them up' & @CRLF _
	& '- equip holy damage weapons (monk staves/wands, Verdict (monk hammer) and Unveil (dervish staff)) and on your heroes too if possible' & @CRLF _
	& '- use weapons in this order : holy/daggers-scythes/axe-sword/spear/hammer/wand-staff/bow'

; Set to 1300 for axe, dagger and sword, 1500 for scythe and spear, 1700 for hammer, wand and staff
Local Const $weaponAttackTime = 1700

Local $LIGHTBRINGER_FARM_SETUP = False
Local $loggingFile

Local Const $Junundu_Strike = 1
Local Const $Junundu_Smash = 2
Local Const $Junundu_Bite = 3
Local Const $Junundu_Siege = 4
Local Const $Junundu_Tunnel = 5
Local Const $Junundu_Feast = 6
Local Const $Junundu_Wail = 7
Local Const $Junundu_Leave = 8

; Improvements :
; - interact with chests along the way

Func LightbringerFarm($STATUS)
	If Not $LIGHTBRINGER_FARM_SETUP Then LightbringerFarmSetup()

	If $STATUS <> 'RUNNING' Then Return 2

	ToTheSulfurousWastes()

	Local $success = FarmTheSulfurousWastes()
	ReturnToSahlahjaOutpost()
	Return $success
EndFunc

Func LightbringerFarmSetup()
	$loggingFile = FileOpen(@ScriptDir & '/logs/lightbringer_farm.log' , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	If GetMapID() <> $ID_Remains_of_Sahlahja Then
		Out('Travelling to Remains of Sahlahja')
		DistrictTravel($ID_Remains_of_Sahlahja, $DISTRICT_NAME)
	EndIf
	LeaveGroup()

	AddHero($ID_Melonni)
	;AddHero($ID_MOX)
	;AddHero($ID_Kahmu)
	;AddHero($ID_Koss)
	AddHero($ID_Goren)
	AddHero($ID_Zenmai)
	;AddHero($ID_Anton)
	AddHero($ID_Acolyte_Sousuke)
	AddHero($ID_Acolyte_Jin)
	AddHero($ID_Margrid_The_Sly)
	AddHero($ID_Tahlkora)
	;AddHero($ID_Dunkoro)
	;AddHero($ID_Ogden)

	SetDisplayedTitle($ID_Lightbringer_Title)
	SwitchMode($ID_HARD_MODE)
	$LIGHTBRINGER_FARM_SETUP = True
EndFunc

Func ToTheSulfurousWastes()
	Do
		MoveTo(1527, -4114)
		Move(1970, -4353)
		WaitMapLoading($ID_The_Sulfurous_Wastes, 10000, 4000)
	Until GetMapID() = $ID_The_Sulfurous_Wastes
EndFunc

Func CountPartyDeaths()
	Local $partyDeaths = 0
	For $i = 1 to 7
		If GetIsDead(GetHeroID($i)) = True Then $partyDeaths +=1
	Next
	Return $partyDeaths
EndFunc

Func FarmTheSulfurousWastes()
	Out('Taking Sunspear Undead Blessing')
	GoToNPC(GetNearestNPCToCoords(-660, 16000))
	Dialog(0x83)
	RndSleep(1000)
	Dialog(0x85)
	RndSleep(1000)

	Out('Entering Junundu')
	MoveTo(-615, 13450)
	RndSleep(5000)
	TargetNearestItem()
	RndSleep(1500)
	ActionInteract()
	RndSleep(1500)

	If MultipleMoveToAndAggro('First Undead Group', -800, 12000, -1700, 9800) Then Return 1
	If MultipleMoveToAndAggro('Second Undead Group', -3000, 10900, -4500, 11500) Then Return 1
	SpeedTeam()
	MoveTo(-7500, 11925)
	SpeedTeam()
	MoveTo(-9800, 12400)
	SpeedTeam()
	MoveTo(-13000, 9500)
	If MultipleMoveToAndAggro('Third Undead Group', -13250, 6750) Then Return 1

	Out('Taking Lightbringer Margonite Blessing')
	SpeedTeam()
	MoveTo(-20600, 7270)
	GoToNPC(GetNearestNPCToCoords(-20600, 7270))
	RndSleep(1000)
	Dialog(0x85)
	RndSleep(1000)

	If MultipleMoveToAndAggro('First Margonite Group', -22000, 9000, -22350, 11100) Then Return 1
	; Skipping this group because it can bring heroes on land and make them go out of Wurm
	;If MultipleMoveToAndAggro(-21200, 10750, -20250, 11000, 'Second Margonite Group') Then Return 1
	If MultipleMoveToAndAggro('Djinn Group', -19000, 5700, -20800, 600, -22000, -1200) Then Return 1	; range 2200
	If MultipleMoveToAndAggro('Undead Ritualist Boss Group', -21500, -6000, -20400, -7400, -19500, -9500) Then Return 1
	If MultipleMoveToAndAggro('Third Margonite Group', -22000, -9400, -22800, -9800) Then Return 1
	If MultipleMoveToAndAggro('Fourth Margonite Group', -23000, -10600, -23150, -12250) Then Return 1
	If MultipleMoveToAndAggro('Fifth Margonite Group', -22800, -13500, -21300, -14000) Then Return 1

	Out('Picking Up Tome')
	SpeedTeam()
	MoveTo(-21300, -14000)
	TargetNearestItem()
	RndSleep(50)
	ActionInteract()
	RndSleep(2000)
	DropBundle()
	RndSleep(1000)

	If MultipleMoveToAndAggro('Sixth Margonite Group', -22800, -13500, -23000, -10600, -21500, -9500) Then Return 1
	If MultipleMoveToAndAggro('Seventh Margonite Group', -21000, -9500, -19500, -8500) Then Return 1
	If MultipleMoveToAndAggro('Temple Monolith Groups', -22000, -9400, -23000, -10600, -22800, -13500, -19500, -13100, -18000, -13100) Then Return 1

	Out('Spawning Margonite bosses')
	SpeedTeam()
	MoveTo(-16000, -13100)
	SpeedTeam()
	MoveTo(-18180, -13540)
	RndSleep(1000)
	TargetNearestItem()
	RndSleep(250)
	ActionInteract()
	RndSleep(3000)
	DropBundle()
	RndSleep(1000)

	If MultipleMoveToAndAggro('Margonite Boss Group', -18000, -13100) Then Return 1
	Return 0
EndFunc

Func SpeedTeam()
	If (IsRecharged($Junundu_Tunnel)) Then
		UseSkillEx($Junundu_Tunnel)
		UseHeroSkill(1, $Junundu_Tunnel)
		UseHeroSkill(2, $Junundu_Tunnel)
		UseHeroSkill(3, $Junundu_Tunnel)
		UseHeroSkill(4, $Junundu_Tunnel)
		UseHeroSkill(5, $Junundu_Tunnel)
		UseHeroSkill(6, $Junundu_Tunnel)
		UseHeroSkill(7, $Junundu_Tunnel)
	EndIf
EndFunc

Func MultipleMoveToAndAggro($foesGroup, $location0x = 0, $location0y = 0, $location1x = null, $location1y = null, $location2x = null, $location2y = null, $location3x = null, $location3y = null, $location4x = null, $location4y = null)
	For $i = 0 To 4
		If (Eval('location' & $i & 'x') == null) Then ExitLoop
		SpeedTeam()
		If MoveToAndAggro($foesGroup, Eval('location' & $i & 'x'), Eval('location' & $i & 'y')) Then Return True
	Next
	Return False
EndFunc



;~ Main method for moving around and aggroing/killing mobs
;~ Return True if the group is dead, False if not
Func MoveToAndAggro($foesGroup, $x, $y)
	Out('Killing ' & $foesGroup)
	Local $range = 1650

	; Get close enough to cast spells but not Aggro
	; Use Junundu Siege (4) until it's in CD
	; While there are enemies
	;	Use Junundu Tunnel (5) unless it's on CD
	;	Use Junundu Bite (3) off CD
	;	Use Junundu Smash (2) if available
	;		Don't use Junundu Feast (6) if an enemy died (would need to check what skill we get afterward ...)
	;	Use Junundu Strike (1) in between
	;	Else just attack
	; Use Junundu Wail (7) after fight only and if life is < 2400/3000 or if a team member is dead

	Local $skillCastTimer

	Local $target = GetNearestNPCInRangeOfCoords(3, $x, $y, $range)
	If (DllStructGetData($target, 'X') == 0) Then
		MoveTo($x, $y)
		CheckForChests($RANGE_SPIRIT)
		_FileWriteLog($loggingFile, $foesGroup & ' not found around ' & $x & ';' & $y & ' with distance set to ' & $range)
		Return False
	EndIf

	GetAlmostInRangeOfAgent($target)

	$skillCastTimer = TimerInit()
	While IsRecharged($Junundu_Siege) And TimerDiff($skillCastTimer) < 3000
		UseSkillEx($Junundu_Siege, $target)
		RndSleep(20)
	WEnd

	Local $foes = 1
	Do
		$target = GetNearestEnemyToAgent(-2)
		If (IsRecharged($Junundu_Tunnel)) Then UseSkillEx($Junundu_Tunnel)
		CallTarget($target)
		Sleep(20)
		If (GetSkillbarSkillAdrenaline($Junundu_Smash) == 130) Then UseSkillEx($Junundu_Smash)
		AttackOrUseSkill($weaponAttackTime, $Junundu_Bite, $Junundu_Strike)
		$foes = CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST)
	Until $foes == 0

	If DllStructGetData(GetAgentByID(-2), 'HP') < 0.75 Or CountPartyDeaths() > 0 Then
		UseSkillEx($Junundu_Wail)
	EndIf
	RndSleep(1000)

	If CountPartyDeaths() > 5 Then Return True

	PickUpItems()
	CheckForChests($RANGE_SPIRIT)

	Return False
EndFunc

Func ReturnToSahlahjaOutpost()
	If GetMapID() <> $ID_Remains_of_Sahlahja Then
		Out('Travelling to Remains of Sahlahja')
		DistrictTravel($ID_Remains_of_Sahlahja, $DISTRICT_NAME)
	EndIf
EndFunc