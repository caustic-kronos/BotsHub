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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :
; Replacing shadow form by something to tank assassins and warriors instead might be better

Opt('MustDeclareVars', 1)

Global Const $PongmeiBotVersion = '0.1'

; ==== Constantes ====
Global Const $PongmeiChestRunnerSkillbar = 'Ogej4NfMLT3ljbHY4OIQ0k8I6MA'
Global Const $PongmeiChestRunInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Mysticism' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Deadly Arts' & @CRLF _
	& '- A shield with +30 or +45 health under enchantment or stance' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& 'Note: in HM, very frequent failures on Am Fah - I suggest cutting that part of the farm if you wish to run in HM'
; Average duration ~ 4m20s
Global Const $PONGMEI_FARM_DURATION = (4 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Pongmei_DwarvenStability) is better than UseSkillEx(1))
Global Const $Pongmei_DwarvenStability = 1
Global Const $Pongmei_Zealous_Renewal = 2
Global Const $Pongmei_Pious_Haste = 3
Global Const $Pongmei_DeathsCharge = 4
Global Const $Pongmei_HeartOfShadow = 5
Global Const $Pongmei_IAmUnstoppable = 6
Global Const $Pongmei_DeadlyParadox = 7
Global Const $Pongmei_ShadowForm = 8

Global Const $ID_paragon_mercenary_hero = $ID_Mercenary_Hero_5

Global $PONGMEI_FARM_SETUP = False

;~ Main method to chest farm Pongmei
Func PongmeiChestFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Boreas_Seabed Then DistrictTravel($ID_Boreas_Seabed, $DISTRICT_NAME)
	If Not $PONGMEI_FARM_SETUP Then
		SetupPongmeiFarm()
		$PONGMEI_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return PongmeiChestFarmLoop($STATUS)
EndFunc


;~ Pongmei chest farm setup
Func SetupPongmeiFarm()
	Info('Setting up farm')
	LeaveGroup()
	AddHero($ID_General_Morgahn)
	AddHero($ID_Hayda)
	AddHero($ID_paragon_mercenary_hero)
	AddHero($ID_Dunkoro)
	AddHero($ID_Tahlkora)
	AddHero($ID_Ogden)
	AddHero($ID_Goren)
	LoadSkillTemplate($PongmeiChestRunnerSkillbar)

	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf

	Info('Preparations complete')
EndFunc


;~ Pongmei Chest farm loop
Func PongmeiChestFarmLoop($STATUS)
	Info('Starting chest farm run')
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf

	MoveTo(-25366, 1524)
	MoveTo(-26000, 2400)
	Move(-26200, 2800)
	RndSleep(1000)
	WaitMapLoading($ID_Pongmei_Valley, 10000, 2000)

	Local $openedChests = 0

	Info('Running to Spot #1/13')
	DervishRun(22399, 1144)
	DervishRun(20126, 1983)
	DervishRun(17760, 266)
	DervishRun(15405, -2025)
	DervishRun(13314, -1374)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #2/13')
	DervishRun(12947, 2289)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #3/13')
	DervishRun(11499, 4242)
	; Am Fah Bridge
	DervishRun(11839, 5966)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #4/13')
	; Am Fah shits
	DervishRun(11703, 8854)
	DervishRun(8529, 10036)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #5/13')
	DervishRun(5485, 11048)
	DervishRun(1597, 7802)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #6/13')
	DervishRun(0, 5850)
	DervishRun(-2223, 5916)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #7/13')
	DervishRun(-7113, 4543)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #8/13')
	DervishRun(-9318, 1204)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #9/13')
	; Echovald side
	DervishRun(-12821, 2172)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #10/13')
	DervishRun(-16938, 5153)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #11/13')
	DervishRun(-17706, -1383)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #12/13')
	DervishRun(-16347, -5139)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Running to Spot #13/13')
	DervishRun(-13876, -5626)
	$openedChests += FindAndOpenChests($RANGE_COMPASS, DefendWhileOpeningChests) ? 1 : 0
	Info('Opened ' & $openedChests & ' chests.')
	Local $success = $openedChests > 0 And Not GetIsDead() ? 0 : 1
	BackToBoreasSeabed()
	Return $success
EndFunc


;~ Returning to Boreas Seabed
Func BackToBoreasSeabed()
	Info('Porting to Boreas Seabed')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Boreas_Seabed, 10000, 1000)
EndFunc


;~ Method to check to which place you are the closest to
Func SkipToPreventBackTracking($X, $Y, $nextX, $nextY)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	If ComputeDistance($myX, $myY, $X, $Y) < ComputeDistance($myX, $myY, $nextX, $nextY) Then
		Info('Skipping')
		Return True
	EndIf
	Return False
EndFunc


;~ Main function to run as a Dervish
Func DervishRun($X, $Y)
	; We could potentially improve bot by avoiding using run stance right before Shadow Form, but that's a very tiny improvement
	;Local Static $shadowFormLastUse = Null
	If FindInInventory($ID_Lockpick)[0] == 0 Then
		Error('Out of lockpicks')
		Return 2
	EndIf

	Move($X, $Y, 0)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $X, $Y) > 100 And $blockedCounter < 15
		If GetEnergy() >= 5 And IsRecharged($Pongmei_IAmUnstoppable) And DllStructGetData(GetEffect($ID_Crippled), 'SkillID') <> 0 Then UseSkillEx($Pongmei_IAmUnstoppable)

		If GetEnergy() >= 5 And IsRecharged($Pongmei_DeathsCharge) Then
			Local $target = GetTargetForDeathsCharge($X, $Y, 700)
			If $target <> 0 Then UseSkillEx($Pongmei_DeathsCharge, $target)
		EndIf

		If GetEnergy() >= 20 And IsRecharged($Pongmei_ShadowForm) And AreFoesInFront($X, $Y) Then
			If IsRecharged($Pongmei_IAmUnstoppable) Then UseSkillEx($Pongmei_IAmUnstoppable)
			UseSkillEx($Pongmei_DeadlyParadox)
			RndSleep(20)
			UseSkillEx($Pongmei_ShadowForm)
			;$shadowFormLastUse = TimerInit()
		EndIf

		$energy = GetEnergy()
		If $energy >= 7 And IsRecharged($Pongmei_Pious_Haste) And (Not IsRecharged($Pongmei_DwarvenStability) Or ($energy >= 12 And IsRecharged($Pongmei_DwarvenStability))) Then
			If IsRecharged($Pongmei_DwarvenStability) Then UseSkillEx($Pongmei_DwarvenStability)
			UseSkillEx($Pongmei_Zealous_Renewal)
			RndSleep(20)
			UseSkillEx($Pongmei_Pious_Haste)
		EndIf

		$me = GetMyAgent()
		If DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0 Then
			$blockedCounter += 1
			Move($X, $Y, 0)
		EndIf

		If $blockedCounter > 5 And GetEnergy() >= 5 And IsRecharged($Pongmei_HeartOfShadow) Then
			$blockedCounter = 0
			Local $npc = GetNPCInTheBack($X, $Y)
			If $npc == Null Then $npc = $me
			UseSkillEx($Pongmei_HeartOfShadow, $npc)
		EndIf

		Sleep(250)
		$me = GetMyAgent()
	WEnd
EndFunc


;~ Check if there are foes in front so we can use Shadow Form preemptively
Func AreFoesInFront($X, $Y)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 350)
	Local $foe
	For $i = 1 To $foes[0]
		$foe = $foes[$i]
		If ((ComputeDistance($X, $Y, $myX, $myY) - ComputeDistance($X, $Y, DllStructGetData($foe, 'X'), DllStructGetData($foe, 'Y'))) > 0) Then Return True
	Next
	Return False
EndFunc


;~ Get an NPC in the back to use Heart of Shadow on - can be a foe or a party member
Func GetNPCInTheBack($X, $Y)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $npcs = GetNPCsInRangeOfAgent($me, $RANGE_SPELLCAST)
	Local $bestNpc = Null
	; dot product ranges from -1 (directly behind) to 1 (directly ahead)
	Local $minDot = 1

	Local $moveX = $X - $myX
	Local $moveY = $Y - $myY
	; Same computation as in ComputeDistance
	Local $myMovementVector = Sqrt($moveX ^ 2 + $moveY ^ 2)
	If $myMovementVector = 0 Then Return Null
	; Normalizing movement vector
	$moveX /= $myMovementVector
	$moveY /= $myMovementVector

	For $i = 1 To $npcs[0]
		Local $npc = $npcs[$i]
		Local $npcMoveX = DllStructGetData($npc, 'X') - $myX
		Local $npcMoveY = DllStructGetData($npc, 'Y') - $myY
		Local $npcMovementVector = Sqrt($npcMoveX ^ 2 + $npcMoveY ^ 2)
		If $npcMovementVector = 0 Then ContinueLoop
		$npcMoveX /= $npcMovementVector
		$npcMoveY /= $npcMovementVector

		; Dot product
		Local $dot = $npcMoveX * $moveX + $npcMoveY * $moveY
		If $dot < $minDot Then
			$minDot = $dot
			$bestNpc = $npc
		EndIf
	Next
	Return $bestNpc
EndFunc


;~ Get a foe that is in front of you and close enough to use Death Charge on
Func GetTargetForDeathsCharge($X, $Y, $distance = 700)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	Local $foe
	For $i = 1 To $foes[0]
		$foe = $foes[$i]
		If ((ComputeDistance($X, $Y, $myX, $myY) - ComputeDistance($X, $Y, DllStructGetData($foe, 'X'), DllStructGetData($foe, 'Y'))) > $distance) Then Return $foe
	Next
	Return 0
EndFunc


;~ Use defensive skills while opening chests
Func DefendWhileOpeningChests()
	Local $nearestFoe = GetNearestEnemyToAgent(GetMyAgent())

	If GetEnergy() >= 5 And IsRecharged($Pongmei_IAmUnstoppable) And GetDistance(GetMyAgent(), $nearestFoe) < $RANGE_AREA Then UseSkillEx($Pongmei_IAmUnstoppable)

	If GetEnergy() >= 20 And IsRecharged($Pongmei_ShadowForm) And GetDistance(GetMyAgent(), $nearestFoe) < ($RANGE_SPELLCAST + 200) Then
		UseSkillEx($Pongmei_DeadlyParadox)
		RndSleep(20)
		UseSkillEx($Pongmei_ShadowForm)
	EndIf
EndFunc