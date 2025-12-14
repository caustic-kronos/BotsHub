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

; Possible improvements :
; Replacing shadow form by something to tank assassins and warriors instead might be better

Opt('MustDeclareVars', True)

; ==== Constants ====
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
Global Const $Pongmei_DwarvenStability	= 1
Global Const $Pongmei_Zealous_Renewal	= 2
Global Const $Pongmei_Pious_Haste		= 3
Global Const $Pongmei_DeathsCharge		= 4
Global Const $Pongmei_HeartOfShadow		= 5
Global Const $Pongmei_IAmUnstoppable	= 6
Global Const $Pongmei_DeadlyParadox		= 7
Global Const $Pongmei_ShadowForm		= 8

Global Const $ID_paragon_mercenary_hero = $ID_Mercenary_Hero_5

Global $PONGMEI_FARM_SETUP = False

;~ Main method to chest farm Pongmei
Func PongmeiChestFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $PONGMEI_FARM_SETUP Then SetupPongmeiChestFarm()

	GoToPongmeiValley()
	Local $result = PongmeiChestFarmLoop($STATUS)
	ReturnBackToOutpost($ID_Boreas_Seabed)
	Return $result
EndFunc


;~ Pongmei chest farm setup
Func SetupPongmeiChestFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Boreas_Seabed, $DISTRICT_NAME)

	SetupPlayerPongmeiChestFarm()
	SetupTeamPongmeiChestFarm()

	SwitchToHardModeIfEnabled()
	$PONGMEI_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerPongmeiChestFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Dervish Then
		LoadSkillTemplate($PongmeiChestRunnerSkillbar)
	Else
		Warn('Should run this farm as dervish')
	EndIf
	Sleep(250 + GetPing())
	If GUICtrlRead($GUI_Checkbox_WeaponSlot) == $GUI_CHECKED Then
		Info('Setting player weapon slot to ' & $WEAPON_SLOT & ' according to GUI settings')
		ChangeWeaponSet($WEAPON_SLOT)
	Else
		Info('Automatic player weapon slot setting is disabled. Assuming that player sets weapon slot manually')
	EndIf
	Sleep(250 + GetPing())
EndFunc


Func SetupTeamPongmeiChestFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Setting up team according to default settings')
		LeaveParty()
		Sleep(500 + GetPing())
		AddHero($ID_General_Morgahn)
		AddHero($ID_Hayda)
		AddHero($ID_paragon_mercenary_hero)
		AddHero($ID_Dunkoro)
		AddHero($ID_Tahlkora)
		AddHero($ID_Ogden)
		AddHero($ID_Goren)
	EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


;~ Move out of outpost into Pongmei Valley
Func GoToPongmeiValley()
	TravelToOutpost($ID_Boreas_Seabed, $DISTRICT_NAME)
	While GetMapID() <> $ID_Pongmei_Valley
		Info('Moving to Pongmei Valley')
		MoveTo(-25366, 1524)
		MoveTo(-26000, 2400)
		Move(-26200, 2800)
		RandomSleep(1000)
		WaitMapLoading($ID_Pongmei_Valley, 10000, 2000)
	WEnd
EndFunc


;~ Pongmei Chest farm loop
Func PongmeiChestFarmLoop($STATUS)
	If FindInInventory($ID_Lockpick)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	If GetMapID() <> $ID_Pongmei_Valley Then Return $FAIL
	Info('Starting chest farm run')

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
	Return $openedChests > 0 And IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Method to check to which place you are the closest to
Func SkipToPreventBackTracking($X, $Y, $nextX, $nextY)
	Local $me = GetMyAgent()
	If GetDistanceToPoint($me, $X, $Y) < GetDistanceToPoint($me, $nextX, $nextY) Then
		Info('Skipping')
		Return True
	EndIf
	Return False
EndFunc


;~ Main function to run as a Dervish
Func DervishRun($X, $Y)
	; We could potentially improve bot by avoiding using run stance right before Shadow Form, but that's a very tiny improvement
	;Local Static $shadowFormLastUse = Null
	Move($X, $Y, 0)
	Local $blockedCounter = 0
	Local $me = GetMyAgent()
	Local $energy
	While IsPlayerAlive() And GetDistanceToPoint($me, $X, $Y) > 100 And $blockedCounter < 15
		If GetEnergy() >= 5 And IsRecharged($Pongmei_IAmUnstoppable) And GetEffect($ID_Crippled) <> Null Then UseSkillEx($Pongmei_IAmUnstoppable)

		If GetEnergy() >= 5 And IsRecharged($Pongmei_DeathsCharge) Then
			Local $target = GetTargetForDeathsCharge($X, $Y, 700)
			If $target <> Null Then UseSkillEx($Pongmei_DeathsCharge, $target)
		EndIf

		If GetEnergy() >= 20 And IsRecharged($Pongmei_ShadowForm) And AreFoesInFront($X, $Y) Then
			If IsRecharged($Pongmei_IAmUnstoppable) Then UseSkillEx($Pongmei_IAmUnstoppable)
			UseSkillEx($Pongmei_DeadlyParadox)
			RandomSleep(20)
			UseSkillEx($Pongmei_ShadowForm)
			;$shadowFormLastUse = TimerInit()
		EndIf

		$energy = GetEnergy()
		If $energy >= 7 And IsRecharged($Pongmei_Pious_Haste) And (Not IsRecharged($Pongmei_DwarvenStability) Or ($energy >= 12 And IsRecharged($Pongmei_DwarvenStability))) Then
			If IsRecharged($Pongmei_DwarvenStability) Then UseSkillEx($Pongmei_DwarvenStability)
			UseSkillEx($Pongmei_Zealous_Renewal)
			RandomSleep(20)
			UseSkillEx($Pongmei_Pious_Haste)
		EndIf

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
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
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


;~ Check if there are foes near point (X, Y) in front of player so we can use Shadow Form preemptively
Func AreFoesInFront($X, $Y)
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 350)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return False
	For $foe In $foes
		If (getDistanceToPoint($me, $X, $Y) - getDistanceToPoint($foe, $X, $Y)) > 0 Then Return True
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

	For $npc In $npcs
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


;~ Get a foe that in front of player and close enough to point (X, Y) to use Death Charge on
Func GetTargetForDeathsCharge($X, $Y, $distance = 700)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	If Not IsArray($foes) Or UBound($foes) <= 0 Then Return Null
	For $foe In $foes
		If (getDistanceToPoint($me, $X, $Y) - getDistanceToPoint($foe, $X, $Y)) > $distance Then Return $foe
	Next
	Return Null
EndFunc


;~ Use defensive skills while opening chests
Func DefendWhileOpeningChests()
	Local $nearestFoe = GetNearestEnemyToAgent(GetMyAgent())

	If GetEnergy() >= 5 And IsRecharged($Pongmei_IAmUnstoppable) And GetDistance(GetMyAgent(), $nearestFoe) < $RANGE_AREA Then UseSkillEx($Pongmei_IAmUnstoppable)
	If GetEnergy() >= 20 And IsRecharged($Pongmei_ShadowForm) And GetDistance(GetMyAgent(), $nearestFoe) < ($RANGE_SPELLCAST + 200) Then
		UseSkillEx($Pongmei_DeadlyParadox)
		RandomSleep(20)
		UseSkillEx($Pongmei_ShadowForm)
	EndIf
EndFunc