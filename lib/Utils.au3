#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributors: Gahais, JackLinesMatthews
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
; limitations under the License.d
#CE ===========================================================================

#include-once

#include <array.au3>
#include <WinAPIDiag.au3>
#include 'GWA2_Headers.au3'
#include 'GWA2_ID.au3'
#include 'GWA2.au3'
#include 'Utils-Debugger.au3'

Opt('MustDeclareVars', True)

Global Const $RANGE_ADJACENT=156, $RANGE_NEARBY=240, $RANGE_AREA=312, $RANGE_EARSHOT=1000, $RANGE_SPELLCAST=1085, $RANGE_LONGBOW=1250, $RANGE_SPIRIT=2500, $RANGE_COMPASS=5000
Global Const $RANGE_ADJACENT_2=156^2, $RANGE_NEARBY_2=240^2, $RANGE_AREA_2=312^2, $RANGE_EARSHOT_2=1000^2, $RANGE_SPELLCAST_2=1085^2, $RANGE_LONGBOW_2=1250^2, $RANGE_SPIRIT_2=2500^2, $RANGE_COMPASS_2=5000^2
; Mobs aggro correspond to earshot range
Global Const $AGGRO_RANGE=$RANGE_EARSHOT * 1.5

Global Const $SPIRIT_TYPES_ARRAY[2] = [0x44000, 0x4C000]
Global Const $MAP_SPIRIT_TYPES = MapFromArray($SPIRIT_TYPES_ARRAY)

; Map containing the IDs of the opened chests - this map should be cleared at every loop
; Null - chest not found yet (sic)
; 0 - chest found but not flagged and not opened
; 1 - chest found and flagged
; 2 - chest found and opened
Global $chests_map[]


#Region Map and travel
;~ Get your own position on map
Func GetOwnPosition()
	Local $me = GetMyAgent()
	Info('(' & DllStructGetData($me, 'X') & ',' & DllStructGetData($me, 'Y') & ')')
EndFunc


;~ Move to a location and wait until you reach it.
Func MoveTo($X, $Y, $random = 50, $doWhileRunning = Null)
	Local $blockedCount = 0
	Local $me
	Local $mapID = GetMapID(), $oldMapID
	Local $destinationX = $X + Random(-$random, $random)
	Local $destinationY = $Y + Random(-$random, $random)

	Move($destinationX, $destinationY, 0)

	While GetDistanceToPoint($me, $destinationX, $destinationY) > 25 And $blockedCount < 14
		RandomSleep(100)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') <= 0 Then ExitLoop
		$oldMapID = $mapID
		$mapID = GetMapID()
		If $mapID <> $oldMapID Then ExitLoop
		If $doWhileRunning <> Null Then $doWhileRunning()
		If Not IsPlayerMoving() Then
			$blockedCount += 1
			$destinationX = $X + Random(-$random, $random)
			$destinationY = $Y + Random(-$random, $random)
			Move($destinationX, $destinationY, 0)
		EndIf
	WEnd
EndFunc


;~ Talks to NPC and waits until you reach them.
Func GoToNPC($agent)
	GoToAgent($agent, GoNPC)
EndFunc


;~ Go to signpost and waits until you reach it.
Func GoToSignpost($agent)
	GoToAgent($agent, GoSignpost)
EndFunc


;~ Talks to an agent and waits until you reach it.
Func GoToAgent($agent, $GoFunction = Null)
	Local $me
	Local $blockedCount = 0
	Local $mapLoading = GetMapType(), $mapLoadingOld
	Move(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), 100)
	RandomSleep(100)
	If $GoFunction <> Null Then $GoFunction($agent)
	While GetDistance($me, $agent) > 250 And $blockedCount < 14
		RandomSleep(100)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') <= 0 Then ExitLoop
		$mapLoadingOld = $mapLoading
		$mapLoading = GetMapType()
		If $mapLoading <> $mapLoadingOld Then ExitLoop
		If Not IsPlayerMoving() Then
			$blockedCount += 1
			Move(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), 100)
			RandomSleep(100)
			If $GoFunction <> Null Then $GoFunction($agent)
		EndIf
	WEnd
	RandomSleep(1000)
EndFunc


;~ Travel to specified map and specified district
Func DistrictTravel($mapID, $district = 'Random')
	If GetMapID() == $mapID Then Return
	If $district == 'Random' Then
		RandomDistrictTravel($mapID)
	Else
		Local $districtAndRegion = $REGION_MAP[$district]
		MoveMap($mapID, $districtAndRegion[1], 0, $districtAndRegion[0])
		WaitMapLoading($mapID, 20000)
		RandomSleep(2000)
	EndIf
EndFunc


;~ Travel to specified map to a random district
;~ 7=eu, 8=eu+int, 11=all(incl. asia)
Func RandomDistrictTravel($mapID, $district = 12)
	Local $region[12] = [$ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_AMERICA, $ID_ASIA_CHINA, $ID_ASIA_JAPAN, $ID_ASIA_KOREA, $ID_INTERNATIONAL]
	Local $language[12] = [$ID_ENGLISH, $ID_FRENCH, $ID_GERMAN, $ID_ITALIAN, $ID_SPANISH, $ID_POLISH, $ID_RUSSIAN, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH]
	Local $random = Random(0, $district - 1, 1)
	MoveMap($mapID, $region[$random], 0, $language[$random])
	WaitMapLoading($mapID, 20000)
	RandomSleep(2000)
EndFunc


Func TravelToOutpost($outpostId, $district = 'Random')
	Local $outpostName = $MAP_NAMES_FROM_IDS[$outpostId]
	If GetMapID() == $outpostId Then Return $SUCCESS
	Info('Travelling to ' & $outpostName & ' (Outpost)')
	DistrictTravel($outpostId, $district)
	RandomSleep(1000)
	If GetMapID() <> $outpostId Then
		Warn('Player may not have access to ' & $outpostName & ' (outpost)')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Return back to outpost from exploration/mission map using resign functionality. This can put player closer to exit portal in outpost
;~ Don't use for maps that share the same ID as the outpost
Func ResignAndReturnToOutpost($outpostId, $ignoreMapId = False)
	Local $outpostName = $MAP_NAMES_FROM_IDS[$outpostId]
	Info('Returning to ' & $outpostName & ' (outpost)')
	If Not $ignoreMapId And GetMapID() == $outpostId Then
		Warn('Player is already in ' & $outpostName & ' (outpost)')
		Return $SUCCESS
	Endif
	Resign()
	Sleep(3500)
	ReturnToOutpost()
	If $ignoreMapId Then Sleep(5000)
	WaitMapLoading($outpostId, 10000, 1000)
	Return GetMapID() == $outpostId ? $SUCCESS : $FAIL
EndFunc


Func EnterFissureOfWoe()
	TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name)
	If GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED Then
		Info('Using scroll to enter Fissure of Woe')
		If UseScroll($ID_FOW_SCROLL) == $SUCCESS Then
			WaitMapLoading($ID_THE_FISSURE_OF_WOE)
			If GetMapID() <> $ID_THE_FISSURE_OF_WOE Then
				Warn('Used scroll but still could not enter Fissure of Woe. Ensure that player has correct scroll in inventory')
				Return $PAUSE
			EndIf
		EndIf
	Else
		Info('Balancing character''s gold level to have enough to enter the Fissure of Woe')
		BalanceCharacterGold(10000)
		Info('Going to Balthazar statue to enter Fissure of Woe')
		MoveTo(-2500, 18700)
		SendChat('/kneel', '')
		Local $ping = GetPing()
		Sleep(3000 + $ping)
		GoToNPC(GetNearestNPCToCoords(-2500, 18700))
		Sleep(750 + $ping)
		Dialog(0x85)
		Sleep(750 + $ping)
		Dialog(0x86)
		WaitMapLoading($ID_THE_FISSURE_OF_WOE)
		If GetMapID() <> $ID_THE_FISSURE_OF_WOE Then
			Info('Could not enter Fissure of Woe. Ensure that it''s Pantheon bonus week or that player has enough gold in inventory')
			Return $FAIL
		EndIf
	EndIf
	Return $SUCCESS
EndFunc


Func EnterUnderworld()
	TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name)
	If GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED Then
		Info('Using scroll to enter Underworld')
		If UseScroll($ID_UW_SCROLL) == $SUCCESS Then
			WaitMapLoading($ID_THE_UNDERWORLD)
			If GetMapID() <> $ID_THE_UNDERWORLD Then
				Warn('Used scroll but still could not enter Underworld. Ensure that player has correct scroll in inventory')
				Return $PAUSE
			EndIf
		EndIf
	Else
		Info('Balancing character''s gold level to have enough to enter the Underworld')
		BalanceCharacterGold(10000)
		Info('Moving to Grenth statue to enter Underworld')
		MoveTo(-4170, 19759)
		MoveTo(-4124, 19829)
		SendChat('/kneel', '')
		Local $ping = GetPing()
		Sleep(3000 + $ping)
		GoToNPC(GetNearestNPCToCoords(-4124, 19829))
		Sleep(750 + $ping)
		Dialog(0x85)
		Sleep(750 + $ping)
		Dialog(0x86)
		WaitMapLoading($ID_THE_UNDERWORLD)
		If GetMapID() <> $ID_THE_UNDERWORLD Then
			Info('Could not enter Underworld. Ensure that it''s Pantheon bonus week or that player has enough gold in inventory')
			Return $FAIL
		EndIf
	EndIf
	Return $SUCCESS
EndFunc


Func EnterUrgozsWarren()
	TravelToOutpost($ID_EMBARK_BEACH, $district_name)
	If GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED Then
		Info('Using scroll to enter Urgoz''s Warren')
		If UseScroll($ID_URGOZ_SCROLL) == $SUCCESS Then
			WaitMapLoading($ID_URGOZS_WARREN)
			If GetMapID() <> $ID_URGOZS_WARREN Then
				Warn('Used scroll but still could not enter Urgoz''s Warren. Ensure that player has correct scroll in inventory')
				Return $PAUSE
			EndIf
		EndIf
	Else
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func EnterTheDeep()
	TravelToOutpost($ID_EMBARK_BEACH, $district_name)
	If GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED Then
		Info('Using scroll to enter the Deep')
		If UseScroll($ID_DEEP_SCROLL) == $SUCCESS Then
			WaitMapLoading($ID_THE_DEEP)
			If GetMapID() <> $ID_THE_DEEP Then
				Warn('Used scroll but still could not enter the Deep. Ensure that player has correct scroll in inventory')
				Return $PAUSE
			EndIf
		EndIf
	Else
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func NPCCoordinatesInTown($town = $ID_EYE_OF_THE_NORTH, $type = 'Merchant')
	Local $coordinates[2] = [-1, -1]
	Switch $type
		Case 'Merchant'
			Switch $town
				Case $ID_EMBARK_BEACH
					$coordinates[0] = 2158
					$coordinates[1] = -2006
				Case $ID_EYE_OF_THE_NORTH
					$coordinates[0] = -2700
					$coordinates[1] = 1075
				Case Else
					Warn('For provided town coordinates of that NPC aren''t mapped yet')
			EndSwitch
		Case 'Basic material trader'
			Switch $town
				Case $ID_EMBARK_BEACH
					$coordinates[0] = 2997
					$coordinates[1] = -2271
				Case $ID_EYE_OF_THE_NORTH
					$coordinates[0] = -1850
					$coordinates[1] = 875
				Case Else
					Warn('For provided town coordinates of that NPC aren''t mapped yet')
			EndSwitch
		Case 'Rare material trader'
			Switch $town
				Case $ID_EMBARK_BEACH
					$coordinates[0] = 2928
					$coordinates[1] = -2452
				Case $ID_EYE_OF_THE_NORTH
					$coordinates[0] = -2100
					$coordinates[1] = 1125
				Case Else
					Warn('For provided town coordinates of that NPC aren''t mapped yet')
			EndSwitch
		;Case 'Dye trader'
		;Case 'Scroll trader'
		;Case 'Consumables trader'
		;Case 'Armorer'
		;Case 'Weaponsmith'
		;Case 'Xunlai chest'
		;Case 'Skill trainer'
		Case Else
			Warn('Wrong NPC type provided')
	EndSwitch
	Return $coordinates
EndFunc
#EndRegion Map and travel


#Region Find and open Chests
;~ Scans for chests and return the first one found around the player or the given coordinates
;~ If flagged is set to true, it will return previously found chests
;~ If $Chest_Gadget_ID parameter is provided then functions will scan only for chests with the same GadgetID as provided
Func ScanForChests($range, $flagged = False, $X = Null, $Y = Null, $Chest_Gadget_ID = Null)
	If $X == Null Or $Y == Null Then
		Local $me = GetMyAgent()
		$X = DllStructGetData($me, 'X')
		$Y = DllStructGetData($me, 'Y')
	EndIf
	Local $gadgetID
	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	For $agent In $agents
		$gadgetID = DllStructGetData($agent, 'GadgetID')
		If $Chest_Gadget_ID <> Null And $Chest_Gadget_ID <> $gadgetID Then ContinueLoop
		If $Chest_Gadget_ID == Null And $MAP_CHESTS_IDS[$gadgetID] == Null Then ContinueLoop
		If GetDistanceToPoint($agent, $X, $Y) > $range Then ContinueLoop
		Local $chestID = DllStructGetData($agent, 'ID')
		If $chests_map[$chestID] == Null Or $chests_map[$chestID] == 0 Or ($flagged And $chests_map[$chestID] == 1) Then
			$chests_map[$chestID] = 1
			Return $agent
		EndIf
	Next
	Return Null
EndFunc


;~ Find chests in the given range (earshot by default)
Func FindChest($range = $RANGE_EARSHOT)
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		WarnOnce('No lockpicks available to open chests')
		Return Null
	EndIf

	Local $gadgetID
	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	Local $chest
	Local $chestCount = 0
	For $agent In $agents
		$gadgetID = DllStructGetData($agent, 'GadgetID')
		If $MAP_CHESTS_IDS[$gadgetID] == Null Then ContinueLoop
		If GetDistance(GetMyAgent(), $agent) > $range Then ContinueLoop

		If $chests_map[DllStructGetData($agent, 'ID')] <> 2 Then
			Return $agent
		EndIf
	Next
	Return Null
EndFunc


;~ Find and open chests in the given range (earshot by default)
Func FindAndOpenChests($range = $RANGE_EARSHOT, $defendFunction = Null, $blockedFunction = Null)
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		WarnOnce('No lockpicks available to open chests')
		Return
	EndIf
	Local $gadgetID
	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	Local $openedChest = False
	For $agent In $agents
		$gadgetID = DllStructGetData($agent, 'GadgetID')
		If $MAP_CHESTS_IDS[$gadgetID] == Null Then ContinueLoop
		If GetDistance(GetMyAgent(), $agent) > $range Then ContinueLoop

		If $chests_map[DllStructGetData($agent, 'ID')] <> 2 Then
			;Fail half the time
			;MoveTo(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
			;Seems to work but serious rubberbanding
			;GoSignpost($agent)
			;Much better solution BUT character doesn't defend itself while going to chest + function kind of sucks
			;GoToSignpost($agent)
			;Final solution, caution, chest is considered as signpost by game client
			GoToSignpostWhileDefending($agent, $defendFunction, $blockedFunction)
			If IsPlayerDead() Then Return
			RandomSleep(200)
			OpenChest()
			RandomSleep(1000)
			If IsPlayerDead() Then Return
			$chests_map[DllStructGetData($agent, 'ID')] = 2
			PickUpItems()
			$openedChest = True
		EndIf
	Next
	Return $openedChest
EndFunc


;~ Count amount of chests opened
Func CountOpenedChests()
	Local $chestsOpened = 0
	Local $keys = MapKeys($chests_map)
	For $key In $keys
		$chestsOpened += $chests_map[$key] == 2 ? 1 : 0
	Next
	Return $chestsOpened
EndFunc

;~ Clearing map of chests
Func ClearChestsMap()
	; Redefining the variable clears it for maps
	Global $chests_map[]
EndFunc


;~ Go to signpost and wait until you reach it.
Func GoToSignpostWhileDefending($signpost, $defendFunction = Null, $blockedFunction = Null)
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($signpost, 'X')
	Local $y = DllStructGetData($signpost, 'Y')
	Local $blocked = 0
	While IsPlayerAlive() And GetDistance($me, $signpost) > 250 And $blocked < 15
		Move($x, $y, 100)
		RandomSleep(100)
		If $defendFunction <> Null Then $defendFunction()
		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			If $blockedFunction <> Null And $blocked > 10 Then
				$blockedFunction()
			EndIf
			$blocked += 1
			Move($x, $y, 100)
		EndIf
		RandomSleep(100)
		$me = GetMyAgent()
	WEnd
	GoSignpost($signpost)
	RandomSleep(100)
EndFunc
#EndRegion Find and open Chests


#Region Advanced actions
;~ Detect if player is rubberbanding
Func IsPlayerRubberBanding()
EndFunc


;~ Check if bot got stuck by checking if max duration for bot has elapsed. Default max duration is 60 minutes = 3600000 milliseconds
;~ If run lasts longer than max duration time then bot must have gotten stuck and fail is returned to restart run
Func CheckStuck($stuckLocation, $maxFarmDuration = 3600000)
	If TimerDiff($run_timer) > $maxFarmDuration Then
		Error('Bot appears to be stuck at: ' & $stuckLocation & '. Restarting run.')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Send /stuck - don't overuse, otherwise there can be a BAN !
Func CheckAndSendStuckCommand()
	; static variable is initialized only once when CheckAndSendStuckCommand is called first time
	Local Static $chatStuckTimer = TimerInit()
	; 10 seconds interval between stuck commands
	Local $stuckInterval = 10000

	; Use a timer to avoid spamming /stuck, because spamming stuck can result in being flagged, which can result in a ban
	; Checking if no foes are in range to use /stuck only when rubberbanding or on some obstacles, there shouldn't be any enemies around the character then
	If Not IsPlayerMoving() And CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY) == 0 And TimerDiff($chatStuckTimer) > $stuckInterval Then
		Warn('Sending /stuck')
		SendChat('stuck', '/')
		$chatStuckTimer = TimerInit()
		RandomSleep(500)
		Return True
	EndIf
	Return False
EndFunc


;~ Aggro a foe
Func AggroAgent($targetAgent)
	While IsPlayerAlive() And GetDistance(GetMyAgent(), $targetAgent) > $RANGE_EARSHOT - 100
		Move(DllStructGetData($targetAgent, 'X'), DllStructGetData($targetAgent, 'Y'))
		RandomSleep(200)
	WEnd
EndFunc


;~ Go to the NPC closest to the given coordinates
Func GoNearestNPCToCoords($x, $y)
	Local $npc = GetNearestNPCToCoords($x, $y)
	Local $me = GetMyAgent()
	While DllStructGetData($npc, 'ID') == 0
		RandomSleep(100)
		$npc = GetNearestNPCToCoords($x, $y)
	WEnd
	ChangeTarget($npc)
	RandomSleep(250)
	GoNPC($npc)
	RandomSleep(250)
	$me = GetMyAgent()
	While GetDistance($me, $npc) > 250
		RandomSleep(250)
		Move(DllStructGetData($npc, 'X'), DllStructGetData($npc, 'Y'), 40)
		RandomSleep(250)
		GoNPC($npc)
		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	RandomSleep(250)
EndFunc


;~ Get close to a mob without aggroing it
Func GetAlmostInRangeOfAgent($targetAgent, $proximity = ($RANGE_SPELLCAST + 100))
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $targetX = DllStructGetData($targetAgent, 'X')
	Local $targetY = DllStructGetData($targetAgent, 'Y')
	Local $distance = GetDistance($me, $targetAgent)

	If ($distance <= $proximity) Then Return

	Local $ratio = $proximity / $distance

	Local $goX = $myX + ($targetX - $myX) * (1 - $ratio)
	Local $goY = $myY + ($targetY - $myY) * (1 - $ratio)
	MoveTo($goX, $goY, 0)
EndFunc


;~ Move to specified position while defending and trying to avoid body block and trying to avoid getting stuck
Func MoveAvoidingBodyBlock($destinationX, $destinationY, $options = $default_movedefend_options)
	Local $me = Null, $target = Null, $chest = Null
	Local $blocked = 0, $distance = 0
	Local $myX, $myY, $randomAngle, $offsetX, $offsetY
	Local Const $PI = 3.141592653589793

	Local $openChests = ($options.Item('openChests') <> Null) ? $options.Item('openChests') : False
	Local $chestOpenRange = ($options.Item('chestOpenRange') <> Null) ? $options.Item('chestOpenRange') : $RANGE_SPIRIT
	Local $defendFunction = ($options.Item('defendFunction') <> Null) ? $options.Item('defendFunction') : Null
	Local $moveTimeOut = ($options.Item('moveTimeOut') <> Null) ? $options.Item('moveTimeOut') : 2 * 60 * 1000
	Local $randomFactor = ($options.Item('randomFactor') <> Null) ? $options.Item('randomFactor') : 100
	Local $hosSkillSlot = ($options.Item('hosSkillSlot') <> Null) ? $options.Item('hosSkillSlot') : 0
	Local $deathChargeSkillSlot = ($options.Item('$deathChargeSkillSlot') <> Null) ? $options.Item('$deathChargeSkillSlot') : 0
	$randomFactor = _Min(_Max($randomFactor, 0), $RANGE_NEARBY) ; $randomFactor in range [0;$RANGE_NEARBY]
	If $hosSkillSlot <> 1 And $hosSkillSlot <> 2 And $hosSkillSlot <> 3 And $hosSkillSlot <> 4 And $hosSkillSlot <> 5 And $hosSkillSlot <> 6 And $hosSkillSlot <> 7 And $hosSkillSlot <> 8 Then $hosSkillSlot = 0
	If $deathChargeSkillSlot <> 1 And $deathChargeSkillSlot <> 2 And $deathChargeSkillSlot <> 3 And $deathChargeSkillSlot <> 4 And $deathChargeSkillSlot <> 5 And $deathChargeSkillSlot <> 6 And $deathChargeSkillSlot <> 7 And $deathChargeSkillSlot <> 8 Then $deathChargeSkillSlot = 0

	Local $moveTimer = TimerInit()
	Local $chatStuckTimer = TimerInit()
	Move($destinationX, $destinationY, $randomFactor)

	While IsPlayerAlive() And GetDistanceToPoint(GetMyAgent(), $destinationX, $destinationY) > $RANGE_NEARBY
		If $defendFunction <> Null Then $defendFunction()
		Sleep(GetPing())
		If TimerDiff($moveTimer) > $moveTimeOut Then Return $STUCK

		If IsPlayerAlive() And Not IsPlayerMoving() Then
			$blocked += 1
			$me = GetMyAgent()
			If $blocked > 8 Then CheckAndSendStuckCommand()
			If $blocked > 10 Then
				; If Heart of Shadow skill is available then use it to avoid becoming stuck
				If $hosSkillSlot > 0 Then
					If IsRecharged($hosSkillSlot) And GetEnergy() > 5 Then
						UseSkillEx($hosSkillSlot)
						Sleep(GetPing())
						Move($destinationX, $destinationY, $randomFactor)
					EndIf
				EndIf
				; If Death's Charge skill is available then use it to avoid becoming stuck
				If $deathChargeSkillSlot > 0 Then
					If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then
						If IsRecharged($deathChargeSkillSlot) And GetEnergy() > 5 Then
							$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
							ChangeTarget($target)
							UseSkillEx($deathChargeSkillSlot, $target)
							Sleep(GetPing())
							Move($destinationX, $destinationY, $randomFactor)
						EndIf
					EndIf
				EndIf
			EndIf
			If $blocked < 6 Then
				Move($destinationX, $destinationY, $randomFactor)
				Sleep(GetPing())
			ElseIf $blocked > 5 Then
				$myX = DllStructGetData($me, 'X')
				$myY = DllStructGetData($me, 'Y')
				; range [0, 2*$PI] - full circle in radian degrees
				$randomAngle = Random(0, 2 * $PI)
				$offsetX = 300 * cos($randomAngle)
				$offsetY = 300 * sin($randomAngle)
				; 0 = no random, because random offset is already calculated
				Move($myX + $offsetX , $myY + $offsetY, 0)
				Sleep(GetPing())
			EndIf
		Else
			Move($destinationX, $destinationY, $randomFactor)
			If $blocked > 0 Then
				$blocked = 0
				; player started moving, after being stuck but maybe player is rubberbanding? Therefore checking it
				CheckAndSendStuckCommand()
			EndIf
		EndIf
		If $openChests Then
			$chest = FindChest($chestOpenRange)
			If $chest <> Null Then
				$options.Item('openChests') = False
				MoveAvoidingBodyBlock(DllStructGetData($chest, 'X'), DllStructGetData($chest, 'Y'), $options)
				$options.Item('openChests') = True
				FindAndOpenChests($chestOpenRange)
			EndIf
		EndIf
		Sleep(50 + GetPing())
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Attack and use one of the skill provided if available, else wait for specified duration
;~ Credits to Shiva for auto-attack improvement
Func AttackOrUseSkill($attackSleep, $skill1 = Null, $skill2 = Null, $skill3 = Null, $skill4 = Null, $skill5 = Null, $skill6 = Null, $skill7 = Null, $skill8 = Null)
	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	Local $skillUsed = False

	; Start auto-attack first
	Attack($target)
	; Small delay to ensure attack starts
	RandomSleep(50)

	For $i = 1 To 8
		Local $skillSlot = Eval('skill' & $i)
		If ($skillSlot <> Null And IsRecharged($skillSlot)) Then
			UseSkillEx($skillSlot, $target)
			RandomSleep(50)
			$skillUsed = True
			ExitLoop
		EndIf
	Next
	If Not $skillUsed Then RandomSleep($attackSleep)
EndFunc


Func AllHeroesUseSkill($skillSlot, $target = 0)
	For $i = 1 to 7
		Local $heroID = GetHeroID($i)
		If GetAgentExists($heroID) And Not GetIsDead(GetAgentById($heroID)) Then UseHeroSkill($i, $skillSlot, $target)
	Next
EndFunc


;~ Returns the cast time modifier based on current effects and used skill
Func GetCastTimeModifier($effects, $usedSkill)
	Local $skillID = DllStructGetData($usedSkill, 'ID')
	Local $effectID = 0
	Local $castTime = 1
	For $effect in $effects
		$effectID = DllStructGetData($effect, 'EffectID')
		Switch $effectID
			; consumables effects
			Case $ID_ESSENCE_OF_CELERITY_EFFECT
				$castTime = 0.80 * $castTime
			Case $ID_PIE_INDUCED_ECSTASY
				$castTime = 0.85 * $castTime
			Case $ID_RED_ROCK_CANDY_RUSH
				$castTime = 0.75 * $castTime
			Case $ID_BLUE_ROCK_CANDY_RUSH
				$castTime = 0.80 * $castTime
			Case $ID_GREEN_ROCK_CANDY_RUSH
				$castTime = 0.85 * $castTime
			; skills shortening cast time
			Case $ID_DEADLY_PARADOX
				If $skillID == $ID_SHADOW_FORM Then $castTime = 0.667 * $castTime
			Case $ID_GLYPH_OF_SACRIFICE, $ID_GLYPH_OF_ESSENCE, $ID_SIGNET_OF_MYSTIC_SPEED
				$castTime = 0
			Case $ID_MINDBENDER
				$castTime = 0.80 * $castTime
			Case $ID_TIME_WARD, $ID_OVER_THE_LIMIT
				Local $attributeLevel = DllStructGetData($effect, 'AttributeLevel')
				; Below equation converts attribute level of Time Ward or Over the Limit effect into shorter cast time, e.g. 80% for attribute levels 14,15,16
				Local $castTimeReduction = 1 - ((15 + Floor(($attributeLevel + 1) / 3)) / 100)
				$castTime = $castTimeReduction * $castTime
			; hexes lengthening cast time
			Case $ID_ARCANE_CONUNDRUM, $ID_MIGRAINE, $ID_STOLEN_SPEED, $ID_SHARED_BURDEN, $ID_FRUSTRATION, $ID_CONFUSING_IMAGES
				$castTime = 2 * $castTime
			Case $ID_SUM_OF_ALL_FEARS
				$castTime = 1.5 * $castTime
			; other effects
			Case $ID_DAZED
				$castTime = 2 * $castTime
		EndSwitch
	Next
	Return $castTime
EndFunc


;~ Use a skill and wait for it to be done, but skipping calculation of precise cast time, without effects modifiers for optimization
;~ If no target is provided then skill is used on self
;~ Returns True if skill usage was successful, False otherwise
Func UseSkillEx($skillSlot, $target = Null)
	If IsPlayerDead() Or Not IsRecharged($skillSlot) Then Return False

	Local $skill = GetSkillByID(GetSkillbarSkillID($skillSlot))
	Local $energy = StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10')
	If GetEnergy() < $energy Then Return False
	Local $castTime = DllStructGetData($skill, 'Activation') * 1000
	Local $aftercast = DllStructGetData($skill, 'Aftercast') * 1000
	; Random delay make us wait at least 2 loops before checking for recharge, to avoid issues with very low cast times
	Local $approximateCastTime = $castTime + $aftercast + Random(75, 125)
	UseSkill($skillSlot, $target)
	Local $castTimer = TimerInit()
	; wait until skill starts recharging or time for skill to be activated has elapsed
	Do
		Sleep(50)
	Until ($approximateCastTime > 0 And TimerDiff($castTimer) > $approximateCastTime) Or Not IsRecharged($skillSlot)
	Return True
EndFunc


;~ Use a skill and wait for it to be done, with calculation of all effects modifiers to wait exact cast time
;~ If no target is provided then skill is used on self
;~ Returns True if skill usage was successful, False otherwise
Func UseSkillTimed($skillSlot, $target = Null)
	If IsPlayerDead() Or Not IsRecharged($skillSlot) Then Return False

	Local $skill = GetSkillByID(GetSkillbarSkillID($skillSlot))
	Local $energy = StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10')
	If GetEnergy() < $energy Then Return False
	Local $castTime = DllStructGetData($skill, 'Activation') * 1000
	Local $aftercast = DllStructGetData($skill, 'Aftercast') * 1000
	; taking into account skill activation time modifiers
	Local $effects = GetEffect(0)
	; get cast time modifier, default is 1, but effects can influence it
	Local $castTimeModifier = GetCastTimeModifier($effects, $skill)
	Local $ping = GetPing()
	Local $fullCastTime = $castTimeModifier * $castTime + $aftercast + $ping

	; when player casts a skill on target that is beyond cast range then trying to get close to target first to not count time on the run
	If $target <> Null And GetDistance(GetMyAgent(), $target) > ($RANGE_SPELLCAST + 100) Then GetAlmostInRangeOfAgent($target)
	UseSkill($skillSlot, $target)
	Local $castTimer = TimerInit()
	; wait until skill starts recharging or time for skill to be fully activated has elapsed
	Do
		Sleep(50 + $ping)
	Until ($fullCastTime < TimerDiff($castTimer)) Or (Not IsRecharged($skillSlot))
	Return True
EndFunc


;~ Order a hero to use a skill and wait for it to be done, but skipping calculation of precise cast time, without effects modifiers for optimization
;~ If no target is provided then skill is used on hero who uses the skill
;~ Returns True if skill usage was successful, False otherwise
Func UseHeroSkillEx($heroIndex, $skillSlot, $target = Null)
	If IsHeroDead($heroIndex) Or Not IsRecharged($skillSlot, $heroIndex) Then Return False

	Local $skill = GetSkillByID(GetSkillbarSkillID($skillSlot, $heroIndex))
	Local $energy = StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10')
	If GetEnergy(GetAgentById(GetHeroID($heroIndex))) < $energy Then Return False
	Local $castTime = DllStructGetData($skill, 'Activation') * 1000
	Local $aftercast = DllStructGetData($skill, 'Aftercast') * 1000
	Local $ping = GetPing()
	Local $approximateCastTime = $castTime + $aftercast + $ping

	UseHeroSkill($heroIndex, $skillSlot, $target)
	Local $castTimer = TimerInit()
	; Wait until skill starts recharging or time for skill to be activated has elapsed
	Do
		Sleep(50 + $ping)
	Until ($approximateCastTime < TimerDiff($castTimer)) Or (Not IsRecharged($skillSlot))
	Return True
EndFunc


;~ Order a hero to use a skill and wait for it to be done, with calculation of all effects modifiers to wait exact cast time
;~ If no target is provided then skill is used on hero who uses the skill
;~ Returns True if skill usage was successful, False otherwise
Func UseHeroSkillTimed($heroIndex, $skillSlot, $target = Null)
	If IsHeroDead($heroIndex) Or Not IsRecharged($skillSlot, $heroIndex) Then Return False

	Local $skill = GetSkillByID(GetSkillbarSkillID($skillSlot, $heroIndex))
	Local $energy = StringReplace(StringReplace(StringReplace(StringMid(DllStructGetData($skill, 'Unknown4'), 6, 1), 'C', '25'), 'B', '15'), 'A', '10')
	If GetEnergy(GetAgentById(GetHeroID($heroIndex))) < $energy Then Return False
	Local $castTime = DllStructGetData($skill, 'Activation') * 1000
	Local $aftercast = DllStructGetData($skill, 'Aftercast') * 1000
	; taking into account skill activation time modifiers
	Local $effects = GetEffect(0, $heroIndex)
	; get cast time modifier, default is 1, but effects can influence it
	Local $castTimeModifier = GetCastTimeModifier($effects, $skill)
	Local $ping = GetPing()
	Local $fullCastTime = $castTimeModifier * $castTime + $aftercast + $ping

	UseHeroSkill($heroIndex, $skillSlot, $target)
	Local $castTimer = TimerInit()
	; wait until skill starts recharging or time for skill to be fully activated has elapsed
	Do
		Sleep(50 + $ping)
	Until ($fullCastTime < TimerDiff($castTimer)) Or (Not IsRecharged($skillSlot))
	Return True
EndFunc


#Region Map Clearing Utilities
Global $default_moveaggroandkill_options = ObjCreate('Scripting.Dictionary')
$default_moveaggroandkill_options.Add('fightFunction', KillFoesInArea)
$default_moveaggroandkill_options.Add('fightRange', $RANGE_EARSHOT * 1.5)
$default_moveaggroandkill_options.Add('flagHeroesOnFight', False)
$default_moveaggroandkill_options.Add('callTarget', True)
$default_moveaggroandkill_options.Add('priorityMobs', False)
$default_moveaggroandkill_options.Add('skillsMask', Null)
$default_moveaggroandkill_options.Add('skillsCostMap', Null)
$default_moveaggroandkill_options.Add('skillsCastTimeMap', Null)
$default_moveaggroandkill_options.Add('lootInFights', False)
$default_moveaggroandkill_options.Add('openChests', True)
$default_moveaggroandkill_options.Add('chestOpenRange', $RANGE_SPIRIT)
$Default_MoveAggroAndKill_Options.Add('defendAgainstTraps', False)
$Default_MoveAggroAndKill_Options.Add('doNotLoot', False)
; default 60 seconds fight duration
$default_moveaggroandkill_options.Add('fightDuration', 60000)

Global $default_flagmoveaggroandkill_options = CloneDictMap($default_moveaggroandkill_options)
$default_flagmoveaggroandkill_options.Item('flagHeroesOnFight') = True

Global $default_movedefend_options = ObjCreate('Scripting.Dictionary')
$default_movedefend_options.Add('defendFunction', Null)
$default_movedefend_options.Add('moveTimeOut', 5 * 60 * 1000)
; random factor for movement
$default_movedefend_options.Add('randomFactor', 100)
$default_movedefend_options.Add('hosSkillSlot', 0)
$default_movedefend_options.Add('deathChargeSkillSlot', 0)
$default_movedefend_options.Add('openChests', False)
$default_movedefend_options.Add('chestOpenRange', $RANGE_SPIRIT)


;~ Stand and fight any enemies that come within specified range within specified time interval (default 60 seconds) in options parameter
Func WaitAndFightEnemiesInArea($options = $default_moveaggroandkill_options)
	If IsPlayerAndPartyWiped() Then Return $FAIL

	Local $fightFunction = ($options.Item('fightFunction') <> Null) ? $options.Item('fightFunction') : KillFoesInArea
	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : $RANGE_EARSHOT * 1.5
	Local $fightDuration = ($options.Item('fightDuration') <> Null) ? $options.Item('fightDuration') : 60000

	Local $me = GetMyAgent()
	Local $target = Null
	Local $distance = 99999
	Local $foesCount = CountFoesInRangeOfAgent($me, $fightRange)
	Local $timer = TimerInit()

	While $foesCount > 0 Or TimerDiff($timer) < $fightDuration
		If IsPlayerAndPartyWiped() Then Return $FAIL
		RandomSleep(250)
		$target = GetNearestEnemyToAgent($me)
		If $target == Null Or (DllStructGetData($target, 'ID') == 0) Then ContinueLoop
		$distance = GetDistance($me, $target)
		If $distance < $fightRange And $fightFunction <> Null Then
			If $fightFunction($options) == $FAIL Then ExitLoop
		EndIf
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $fightRange)
		RandomSleep(250)
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $fightRange)
	WEnd
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Version to flag heroes before fights
;~ Better against heavy AoE - dangerous when flags can end up in a non accessible spot
Func FlagMoveAggroAndKill($x, $y, $log = '', $options = $default_flagmoveaggroandkill_options)
	Return MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ Version to specify fight range as parameter instead of in options map
Func MoveAggroAndKillInRange($x, $y, $log = '', $range = $RANGE_EARSHOT * 1.5, $options = Null)
	If $options = Null Then $options = CloneDictMap($default_moveaggroandkill_options)
	$options.Item('fightRange') = $range
	Return MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ Version to specify fight range as parameter instead of in options map and also flag heroes before fights
Func FlagMoveAggroAndKillInRange($x, $y, $log = '', $range = $RANGE_EARSHOT * 1.5, $options = Null)
	If $options = Null Then $options = CloneDictMap($default_flagmoveaggroandkill_options)
	$options.Item('fightRange') = $range
	Return MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ Trap Safe Wrapper for MoveAggroAndKill
Func MoveAggroAndKillSafeTraps($x, $y, $log = '', $options = Null)
	If $options = Null Then $options = CloneDictMap($Default_MoveAggroAndKill_Options)
	$options.Item('defendAgainstTraps') = True
	$options.Item('fightRange') = $RANGE_EARSHOT
    MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ defendAgainstTrapsLoot function for PickupItems()
Func defendAgainstTrapsLoot($x,$y, $fightRange)
	CommandAll($x, $y)
	;Add your prot spells in here if you want to
	PickUpItems(Null, DefaultShouldPickItem, $fightRange)
	RandomSleep(5000)
	CancelAll()
EndFunc


;~ Clear a zone around the coordinates provided
;~ Credits to Shiva for auto-attack improvement
Func MoveAggroAndKill($x, $y, $log = '', $options = $default_moveaggroandkill_options)
	If IsPlayerAndPartyWiped() Then Return $FAIL

	Local $openChests = ($options.Item('openChests') <> Null) ? $options.Item('openChests') : True
	Local $chestOpenRange = ($options.Item('chestOpenRange') <> Null) ? $options.Item('chestOpenRange') : $RANGE_SPIRIT
	Local $fightFunction = ($options.Item('fightFunction') <> Null) ? $options.Item('fightFunction') : KillFoesInArea
	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : $RANGE_EARSHOT * 1.5
	Local $doNotLoot = ($options.Item('doNotLoot') <> Null) ? $options.Item('doNotLoot') : False

	If $log <> '' Then Info($log)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $blocked = 0

	Move($x, $y)

	Local $oldMyX
	Local $oldMyY
	Local $target
	Local $chest
	While IsPlayerOrPartyAlive() And GetDistanceToPoint(GetMyAgent(), $x, $y) > $RANGE_NEARBY And $blocked < 10
		$oldMyX = $myX
		$oldMyY = $myY
		$me = GetMyAgent()
		$target = GetNearestEnemyToAgent($me)
		If GetDistance($me, $target) < $fightRange And DllStructGetData($target, 'ID') <> 0 Then
			If $fightFunction($options) == $FAIL Then ExitLoop
			RandomSleep(500)
			If IsPlayerAlive() And Not $doNotLoot Then PickUpItems(Null, DefaultShouldPickItem, $fightRange)
			; If one member of party is dead, go to rez him before proceeding
		EndIf
		RandomSleep(250)
		$me = GetMyAgent()
		$myX = DllStructGetData($me, 'X')
		$myY = DllStructGetData($me, 'Y')
		If $oldMyX = $myX And $oldMyY = $myY Then
			$blocked += 1
			If $blocked > 6 Then
				Move($myX, $myY, 500)
				RandomSleep(500)
				Move($x, $y)
			EndIf
		Else
			; reset of block count if player got unstuck
			$blocked = 0
		EndIf
		If $openChests Then
			$chest = FindChest($chestOpenRange)
			If $chest <> Null Then
				$options.Item('openChests') = False
				MoveAggroAndKill(DllStructGetData($chest, 'X'), DllStructGetData($chest, 'Y'), 'Found a chest', $options)
				$options.Item('openChests') = True
				FindAndOpenChests($chestOpenRange)
			EndIf
		EndIf
	WEnd
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Kill foes by casting skills from 1 to 8
Func KillFoesInArea($options = $default_moveaggroandkill_options)
	If IsPlayerAndPartyWiped() Then Return $FAIL

	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : $RANGE_EARSHOT * 1.5
	Local $flagHeroes = ($options.Item('flagHeroesOnFight') <> Null) ? $options.Item('flagHeroesOnFight') : False
	Local $callTarget = ($options.Item('callTarget') <> Null) ? $options.Item('callTarget') : True
	Local $priorityMobs = ($options.Item('priorityMobs') <> Null) ? $options.Item('priorityMobs') : False
	Local $lootInFights = ($options.Item('lootInFights') <> Null) ? $options.Item('lootInFights') : False
	Local $skillsMask = ($options.Item('skillsMask') <> Null And IsArray($options.Item('skillsMask')) And UBound($options.Item('skillsMask')) == 8) ? $options.Item('skillsMask') : Null
	Local $skillsCostMap = ($options.Item('skillsCostMap') <> Null And UBound($options.Item('skillsCostMap')) == 8) ? $options.Item('skillsCostMap') : Null
	Local $defendTraps = ($options.Item('defendAgainstTraps') <> Null) ? $options.Item('defendAgainstTraps') : False
	Local $doNotLoot = ($options.Item('doNotLoot') <> Null) ? $options.Item('doNotLoot') : False

	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $foesCount = CountFoesInRangeOfAgent($me, $fightRange)
	Local $target = Null
	; 260 distance larger than nearby distance = 240 to avoid AoE damage and still quite compact formation
	If $flagHeroes Then FanFlagHeroes(260)

	While IsPlayerOrPartyAlive() And $foesCount > 0
		If $priorityMobs Then $target = GetHighestPriorityFoe($me, $fightRange)
		If Not $priorityMobs Or $target == Null Then $target = GetNearestEnemyToAgent($me)
		If IsPlayerAlive() And $target <> Null And DllStructGetData($target, 'ID') <> 0 And Not GetIsDead($target) And GetDistance($me, $target) < $fightRange Then
			ChangeTarget($target)
			Sleep(100)
			If $callTarget Then
				CallTarget($target)
				Sleep(100)
			EndIf
			; get as close as possible to target foe to have a surprise effect when attacking
			GetAlmostInRangeOfAgent($target)
			Attack($target)
			Sleep(100)

			Local $i = 0
			; casting skills from 1 to 8 in inner loop and leaving it only after target or player is dead
			While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
				If IsPlayerDead() Then ExitLoop
				; incrementation of skill index and capping it by number of skills, range <1..8>
				$i = Mod($i, 8) + 1
				; optional skillsMask indexed from 0, tells which skills to use or skip
				If $skillsMask <> Null And $skillsMask[$i-1] == False Then ContinueLoop
				; Always ensure auto-attack is active before using skills
				Attack($target)
				Sleep(100)

				; if no skill energy cost map is provided then attempt to use skills anyway
				Local $sufficientEnergy = ($skillsCostMap <> Null) ? (GetEnergy() >= $skillsCostMap[$i]) : True
				If IsRecharged($i) And $sufficientEnergy Then
					UseSkillEx($i, $target)
					RandomSleep(100)
				EndIf
				$target = GetCurrentTarget()
			WEnd
		EndIf

		If $lootInFights And IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $fightRange)
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $fightRange)
	WEnd
	If $flagHeroes Then CancelAllHeroes()
	If $doNotLoot <> True Then
		If IsPlayerAlive() and $defendTraps Then
			PickUpItems(defendAgainstTrapsLoot($myX, $myY, $fightRange), DefaultShouldPickItem, $fightRange)
		Else
			PickUpItems(Null, DefaultShouldPickItem, $fightRange)
		EndIf
	EndIf
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Take current character's position (AND orientation) to flag heroes in a fan position
Func FanFlagHeroes($range = $RANGE_AREA)
	Local $heroCount = GetHeroCount()
	; Change your hero locations here
	Switch $heroCount
		Case 3
			; right, left, behind
			Local $heroFlagPositions[3] = [1, 2, 3]
		Case 5
			; right, left, behind, behind right, behind left
			Local $heroFlagPositions[5] = [1, 2, 3, 4, 5]
		Case 7
			; right, left, behind, behind right, behind left, way behind right, way behind left
			Local $heroFlagPositions[7] = [1, 2, 6, 3, 4, 5, 7]
		Case Else
			Local $heroFlagPositions[0] = []
	EndSwitch

	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	Local $rotationX = DllStructGetData($me, 'RotationCos')
	Local $rotationY = DllStructGetData($me, 'RotationSin')
	Local $distance = $range + 10

	Local $agent = GetNearestEnemyToAgent($me)
	If $agent <> Null Then
		$rotationX = DllStructGetData($agent, 'X') - $x
		$rotationY = DllStructGetData($agent, 'Y') - $y
		Local $distanceToFoe = Sqrt($rotationX ^ 2 + $rotationY ^ 2)
		$rotationX = $rotationX / $distanceToFoe
		$rotationY = $rotationY / $distanceToFoe
	EndIf

	; To the right
	If $heroCount > 0 Then CommandHero($heroFlagPositions[0], $x + $rotationY * $distance, $y - $rotationX * $distance)
	; To the left
	If $heroCount > 1 Then CommandHero($heroFlagPositions[1], $x - $rotationY * $distance, $y + $rotationX * $distance)
	; Straight behind
	If $heroCount > 2 Then CommandHero($heroFlagPositions[2], $x - $rotationX * $distance, $y - $rotationY * $distance)
	; To the right, behind
	If $heroCount > 3 Then CommandHero($heroFlagPositions[3], $x + ($rotationY - $rotationX) * $distance, $y - ($rotationX + $rotationY) * $distance)
	; To the left, behind
	If $heroCount > 4 Then CommandHero($heroFlagPositions[4], $x - ($rotationY + $rotationX) * $distance, $y + ($rotationX - $rotationY) * $distance)
	; To the right, way behind
	If $heroCount > 5 Then CommandHero($heroFlagPositions[5], $x + ($rotationY / 2 - 2 * $rotationX) * $distance, $y - (2 * $rotationY + $rotationX / 2) * $distance)
	; To the left, way behind
	If $heroCount > 6 Then CommandHero($heroFlagPositions[6], $x - ($rotationY / 2 + 2 * $rotationX) * $distance, $y + ($rotationX / 2 - 2 * $rotationY) * $distance)

EndFunc
#EndRegion Map Clearing Utilities
#EndRegion Advanced actions


#Region DateTime
Func ConvertTimeToHourString($time)
	Return Floor($time/3600000) & 'h ' & Floor(Mod($time, 3600000)/60000) & 'min ' & Floor(Mod($time, 60000)/1000) & 's'
EndFunc


Func ConvertTimeToMinutesString($time)
	Return Floor($time/60000) & 'min ' & Floor(Mod($time, 60000)/1000) & 's'
EndFunc


; During below festival these are the decorated towns: Kamadan, Jewel of Istan, Lion's Arch, Shing Jea Monastery
; Map IDs for these cities may change so can check them before travelling
; Caution: Each character in account needs to visit city decorated during events first before being able to travel automatically to that city decorated during events using bots
; Otherwise that city is considered an unknown outpost to which bot can't travel even when that city was visited before festival event by that character
Func IsCanthanNewYearFestival()
	Local $currentMonth = @MON
	Local $currentDay = @MDAY
	; Check if current day is between 31-01 and 07-02
	Return ($currentMonth == 1 And $currentDay >= 31) Or ($currentMonth == 2 And $currentDay <= 7)
EndFunc


; During below festival Kaineng Center and Shing Jea Monastery are decorated
; Map IDs for these cities may change so can check them before travelling
; Caution: Each character in account needs to visit city decorated during events first before being able to travel automatically to that city decorated during events using bots
; Otherwise that city is considered an unknown outpost to which bot can't travel even when that city was visited before festival event by that character
Func IsAnniversaryCelebration()
	Local $currentMonth = @MON
	Local $currentDay = @MDAY
	; Check if current day is between 22-04 and 06-05 (Anniversary Celebration)
	Return ($currentMonth == 4 And $currentDay >= 22) Or ($currentMonth == 5 And $currentDay <= 6)
EndFunc


; During below festival decorations are applied to Kaineng Center and Shing Jea Monastery
; Map IDs for these cities may change so can check them before travelling
; Caution: Each character in account needs to visit city decorated during events first before being able to travel automatically to that city decorated during events using bots
; Otherwise that city is considered an unknown outpost to which bot can't travel even when that city was visited before festival event by that character
Func IsDragonFestival()
	Local $currentMonth = @MON
	Local $currentDay = @MDAY
	; Check if current day is between 27-06 and 04-07
	Return ($currentMonth == 6 And $currentDay >= 27) Or ($currentMonth == 7 And $currentDay <= 4)
EndFunc


; During below festival Lion's Arch, Droknar's Forge, Kamadan, Jewel of Istan and Tomb of the Primeval Kings are all redecorated in a suitably festive (dark) style
; Map IDs for these cities may change so can check them before travelling
; Caution: Each character in account needs to visit city decorated during events first before being able to travel automatically to that city decorated during events using bots
; Otherwise that city is considered an unknown outpost to which bot can't travel even when that city was visited before festival event by that character
Func IsHalloweenFestival()
	Local $currentMonth = @MON
	Local $currentDay = @MDAY
	; Check if current day is between 18-10 and 02-11 (Halloween)
	Return ($currentMonth == 10 And $currentDay >= 18) Or ($currentMonth == 11 And $currentDay <= 2)
EndFunc


; During below festival Ascalon City, Lion's Arch, Droknar's Forge, Kamadan, Jewel of Istan and Eye of the North are all redecorated in a suitably festive (and snowy) style
; Map IDs for these cities may change so can check them before travelling
; Caution: Each character in account needs to visit city decorated during events first before being able to travel automatically to that city decorated during events using bots
; Otherwise that city is considered an unknown outpost to which bot can't travel even when that city was visited before festival event by that character
Func IsChristmasFestival()
	Local $currentMonth = @MON
	Local $currentDay = @MDAY
	; Check if current day is between 19-12 and 02-01 (from Christmas To New Year's Eve)
	Return ($currentMonth == 12 And 19 <= $currentDay) Or ($currentMonth == 1 And $currentDay <= 2)
EndFunc
#EndRegion DateTime


#Region GW Utils
;~ Disable all skills on a hero's skill bar.
Func DisableAllHeroSkills($heroIndex)
	Local $ping = GetPing()
	For $i = 1 to 8
		DisableHeroSkillSlot($heroIndex, $i)
		Sleep(20 + $ping)
	Next
EndFunc


;~ Disable a skill on a hero's skill bar.
Func DisableHeroSkillSlot($heroIndex, $skillSlot)
	If Not GetIsHeroSkillSlotDisabled($heroIndex, $skillSlot) Then ToggleHeroSkillSlot($heroIndex, $skillSlot)
EndFunc


;~ Enable a skill on a hero's skill bar.
Func EnableHeroSkillSlot($heroIndex, $skillSlot)
	If GetIsHeroSkillSlotDisabled($heroIndex, $skillSlot) Then ToggleHeroSkillSlot($heroIndex, $skillSlot)
EndFunc


;~ Returns the nearest item by model ID to an agent.
Func GetNearestItemByModelIDToAgent($modelID, $agent)
	Local $nearestItemAgent = Null
	Local $nearestDistance = 100000000
	Local $distance

	For $itemAgent In GetAgentArray($ID_AGENT_TYPE_ITEM)
		Local $itemAgentID = DllStructGetData($itemAgent, 'ID')
		Local $item = GetItemByAgentID($itemAgentID)
		Local $agentModelID = DllStructGetData($item, 'ModelID')
		If $agentModelID = $modelID Then
			$distance = GetDistance($itemAgent, $agent)
			If $distance < $nearestDistance Then
				$nearestItemAgent = $itemAgent
				$nearestDistance = $distance
			EndIf
		EndIf
	Next
	Return $nearestItemAgent
EndFunc


;~ Take a quest or a reward - for reward, expectedState should be 0 once reward taken
Func TakeQuestOrReward($npc, $questID, $dialogID, $expectedState = 0)
	Local $questState = 999
	While $questState <> $expectedState
		Info('Current quest state : ' & $questState)
		GoToNPC($npc)
		RandomSleep(750)
		Dialog($dialogID)
		RandomSleep(750)
		$questState = DllStructGetData(GetQuestByID($questID), 'LogState')
	WEnd
EndFunc


;~ Mapping function
;~ Mapping mode corresponds to : 0 - everything, 1 - only location, 2 - only chests
Func ToggleMapping($mappingMode = 0, $mappingPath = @ScriptDir & '/logs/mapping.log', $chestPath = @ScriptDir & '/logs/chests.log')
	; Toggle variable
	Local Static $isMapping = False
	Local Static $mappingFile
	Local Static $chestFile
	If $isMapping Then
		AdlibUnregister('MappingWrite')
		FileClose($mappingFile)
		FileClose($chestFile)
		$isMapping = False
	Else
		Info('Logging mapping to : ' & $mappingPath)
		Info('Logging chests to : ' & $chestPath)
		$mappingFile = FileOpen($mappingPath, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
		$chestFile = FileOpen($chestPath, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
		MappingWrite($mappingFile, $chestFile, $mappingMode)
		AdlibRegister('MappingWrite', 1000)
		$isMapping = True
	EndIf
EndFunc


;~ Write mapping log in file
Func MappingWrite($mapfile = Null, $chestingFile = Null, $mode = Null)
	Local Static $mappingFile = 0
	Local Static $chestFile = 0
	Local Static $mappingMode = 0
	Local $mustReturn = False
	; Initialisation the first time when called outside of AdlibRegister
	If (IsDeclared('mapfile') And $mapfile <> Null) Then
		$mappingFile = $mapfile
		$mustReturn = True
	EndIf
	If (IsDeclared('chestingFile') And $chestingFile <> Null) Then
		$chestFile = $chestingFile
		$mustReturn = True
	EndIf
	If (IsDeclared('mode') And $mode <> Null) Then
		$mappingMode = $mode
		$mustReturn = True
	EndIf
	If $mustReturn Then Return
	If $mappingMode <> 2 Then
		Local $me = GetMyAgent()
		_FileWriteLog($mappingFile, '(' & DllStructGetData($me, 'X') & ',' & DllStructGetData($me, 'Y') & ')')
	EndIf
	If $mappingMode <> 1 Then
		Local $chest = ScanForChests($RANGE_COMPASS)
		If $chest <> Null Then
			Local $chestString = 'Chest ' & DllStructGetData($chest, 'ID') & ' - (' & DllStructGetData($chest, 'X') & ',' & DllStructGetData($chest, 'Y') & ')'
			_FileWriteLog($chestFile, $chestString)
		EndIf
	EndIf
EndFunc


;~ Invite a player to the party.
Func InvitePlayer($playerName)
	SendChat('invite ' & $playerName, '/')
EndFunc


;~ Resign.
Func Resign()
	SendChat('resign', '/')
EndFunc
#EndRegion GW Utils


#Region Memory Utils
Global Const $MEMORY_INFO_STRUCT_TEMPLATE = 'dword BaseAddress;dword AllocationBase;dword AllocationProtect;dword RegionSize;dword State;dword Protect;dword Type'


#Region Memory GWA2
;~ Writes a binary string to a specified memory address in the process.
Func WriteBinary($processHandle, $binaryString, $address)
	Local $data = SafeDllStructCreate('byte[' & 0.5 * StringLen($binaryString) & ']')
	For $i = 1 To DllStructGetSize($data)
		DllStructSetData($data, 1, Dec(StringMid($binaryString, 2 * $i - 1, 2)), $i)
	Next
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'ptr', $address, 'ptr', DllStructGetPtr($data), 'int', DllStructGetSize($data), 'int', 0)
EndFunc


;~ Writes the specified data to a memory address of a given type (default is 'dword').
Func MemoryWrite($processHandle, $address, $data, $type = 'dword')
	Local $buffer = SafeDllStructCreate($type)
	DllStructSetData($buffer, 1, $data)
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
EndFunc


;~ Reads data from a memory address, returning it as the specified type (defaults to dword).
Func MemoryRead($processHandle, $address, $type = 'dword')
	Local $buffer = SafeDllStructCreate($type)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
	Return DllStructGetData($buffer, 1)
EndFunc


;~ Reads data from a memory address, following pointer chains based on the provided offsets.
Func MemoryReadPtr($processHandle, $address, $offset, $type = 'dword')
	Local $ptrCount = UBound($offset) - 2
	Local $buffer = SafeDllStructCreate('dword')
	Local $memoryInfo = DllStructCreate($MEMORY_INFO_STRUCT_TEMPLATE)
	Local $data[2] = [0, 0]

	; This loops serves as a control - if ExitLoop is reached in the inner loop, we can skip the rest of the outer loop
	For $j = 0 To 0
		For $i = 0 To $ptrCount
			$address += $offset[$i]

			SafeDllCall11($kernel_handle, 'int', 'VirtualQueryEx', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($memoryInfo), 'int', DllStructGetSize($memoryInfo))
			If DllStructGetData($memoryInfo, 'State') <> 0x1000 Then ExitLoop 2

			SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
			$address = DllStructGetData($buffer, 1)
			If $address == 0 Then ExitLoop 2
		Next
		$address += $offset[$ptrCount + 1]
		SafeDllCall11($kernel_handle, 'int', 'VirtualQueryEx', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($memoryInfo), 'int', DllStructGetSize($memoryInfo))
		If DllStructGetData($memoryInfo, 'State') <> 0x1000 Then ExitLoop

		$buffer = SafeDllStructCreate($type)
		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
		$data[0] = $address
		$data[1] = DllStructGetData($buffer, 1)
		Return $data
	Next
	; This can be valid when trying to access an agent out of range for instance
	DebuggerLog('Tried to access an invalid address')
	Return $data
EndFunc


;~ Swaps the byte order (endianness) of a given hexadecimal string.
Func SwapEndian($hex)
	Return StringMid($hex, 7, 2) & StringMid($hex, 5, 2) & StringMid($hex, 3, 2) & StringMid($hex, 1, 2)
EndFunc


;~ Empties Guild Wars client memory
Func ClearMemory($processHandle)
	SafeDllCall9($kernel_handle, 'int', 'SetProcessWorkingSetSize', 'int', $processHandle, 'int', -1, 'int', -1)
EndFunc


;~ Changes the maximum memory Guild Wars can use.
Func SetMaxMemory($processHandle)
	SafeDllCall11($kernel_handle, 'int', 'SetProcessWorkingSetSizeEx', 'int', $processHandle, 'int', 1024 * 1024, 'int', 256 * 1024 * 1024, 'dword', 0)
EndFunc


;~ Scan memory for a pattern - used to find process and to find character names
Func ScanMemoryForPattern($processHandle, $patternBinary)
	Local $currentSearchAddress = 0x00000000
	Local $memoryInfos = SafeDllStructCreate($MEMORY_INFO_STRUCT_TEMPLATE)

	; Iterating over regions
	While $currentSearchAddress < 0x01F00000
		SafeDllCall11($kernel_handle, 'int', 'VirtualQueryEx', 'int', $processHandle, 'int', $currentSearchAddress, 'ptr', DllStructGetPtr($memoryInfos), 'int', DllStructGetSize($memoryInfos))
		Local $memoryBaseAddress = DllStructGetData($memoryInfos, 'BaseAddress')
		Local $regionSize = DllStructGetData($memoryInfos, 'RegionSize')
		Local $state = DllStructGetData($memoryInfos, 'State')
		Local $protect = DllStructGetData($memoryInfos, 'Protect')

		; If memory is committed and not guarded
		If $state = 0x1000 And BitAND($protect, 0x100) = 0 Then
			$protect = BitAND($protect, 0xFF)
			; If memory is allowed to be read
			Switch $protect
				Case 0x02, 0x04, 0x08, 0x20, 0x40, 0x80
					Local $buffer = SafeDllStructCreate('byte[' & $regionSize & ']')
					SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $currentSearchAddress, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
					Local $tmpMemoryData = DllStructGetData($buffer, 1)
					$tmpMemoryData = BinaryToString($tmpMemoryData)
					Local $matchOffset = StringInStr($tmpMemoryData, $patternBinary, 2)
					If $matchOffset > 0 Then
						Local $match[3] = [$memoryBaseAddress, $currentSearchAddress, $matchOffset]
						Return $match
					EndIf
			EndSwitch
		EndIf
		$currentSearchAddress += $regionSize
	WEnd
	Return Null
EndFunc


;~ Retrieves the window handle for the specified game process
Func GetWindowHandleForProcess($process)
	Local $wins = WinList()
	For $i = 1 To UBound($wins) - 1
		If (WinGetProcess($wins[$i][1]) == $process) And (BitAND(WinGetState($wins[$i][1]), 2)) Then Return $wins[$i][1]
	Next
EndFunc


;~ Get the address provided to a call (ie: strips the E8 instruction, and sums current call address with the obtained offset)
Func GetCallTargetAddress($processHandle, $address)
	Local $offset = MemoryRead($processHandle, $address + 0x01, 'dword')
	If $offset > 0x7FFFFFFF Then
		Warn('Offset is larger than 0x7FFFFFFF, adjusting for 64-bit address space.')
		$offset -= 0x100000000
	EndIf
	Local $targetAddress = $address + 5 + $offset
	Return $targetAddress
EndFunc


;~ Internal use only.
Func Bin64ToDec($binary)
	Local $result = 0
	For $i = 1 To StringLen($binary)
		If StringMid($binary, $i, 1) == 1 Then $result += BitShift(1, -($i - 1))
	Next
	Return $result
EndFunc


;~ Converts float to integer.
Func FloatToInt($float)
	Local $floatStruct = SafeDllStructCreate('float')
	Local $int = SafeDllStructCreate('int', DllStructGetPtr($floatStruct))
	DllStructSetData($floatStruct, 1, $float)
	Return DllStructGetData($int, 1)
EndFunc


;~ Internal use only.
Func Base64ToBin64($character)
	Select
		Case $character == 'A'
			Return '000000'
		Case $character == 'B'
			Return '100000'
		Case $character == 'C'
			Return '010000'
		Case $character == 'D'
			Return '110000'
		Case $character == 'E'
			Return '001000'
		Case $character == 'F'
			Return '101000'
		Case $character == 'G'
			Return '011000'
		Case $character == 'H'
			Return '111000'
		Case $character == 'I'
			Return '000100'
		Case $character == 'J'
			Return '100100'
		Case $character == 'K'
			Return '010100'
		Case $character == 'L'
			Return '110100'
		Case $character == 'M'
			Return '001100'
		Case $character == 'N'
			Return '101100'
		Case $character == 'O'
			Return '011100'
		Case $character == 'P'
			Return '111100'
		Case $character == 'Q'
			Return '000010'
		Case $character == 'R'
			Return '100010'
		Case $character == 'S'
			Return '010010'
		Case $character == 'T'
			Return '110010'
		Case $character == 'U'
			Return '001010'
		Case $character == 'V'
			Return '101010'
		Case $character == 'W'
			Return '011010'
		Case $character == 'X'
			Return '111010'
		Case $character == 'Y'
			Return '000110'
		Case $character == 'Z'
			Return '100110'
		Case $character == 'a'
			Return '010110'
		Case $character == 'b'
			Return '110110'
		Case $character == 'c'
			Return '001110'
		Case $character == 'd'
			Return '101110'
		Case $character == 'e'
			Return '011110'
		Case $character == 'f'
			Return '111110'
		Case $character == 'g'
			Return '000001'
		Case $character == 'h'
			Return '100001'
		Case $character == 'i'
			Return '010001'
		Case $character == 'j'
			Return '110001'
		Case $character == 'k'
			Return '001001'
		Case $character == 'l'
			Return '101001'
		Case $character == 'm'
			Return '011001'
		Case $character == 'n'
			Return '111001'
		Case $character == 'o'
			Return '000101'
		Case $character == 'p'
			Return '100101'
		Case $character == 'q'
			Return '010101'
		Case $character == 'r'
			Return '110101'
		Case $character == 's'
			Return '001101'
		Case $character == 't'
			Return '101101'
		Case $character == 'u'
			Return '011101'
		Case $character == 'v'
			Return '111101'
		Case $character == 'w'
			Return '000011'
		Case $character == 'x'
			Return '100011'
		Case $character == 'y'
			Return '010011'
		Case $character == 'z'
			Return '110011'
		Case $character == '0'
			Return '001011'
		Case $character == '1'
			Return '101011'
		Case $character == '2'
			Return '011011'
		Case $character == '3'
			Return '111011'
		Case $character == '4'
			Return '000111'
		Case $character == '5'
			Return '100111'
		Case $character == '6'
			Return '010111'
		Case $character == '7'
			Return '110111'
		Case $character == '8'
			Return '001111'
		Case $character == '9'
			Return '101111'
		Case $character == '+'
			Return '011111'
		Case $character == '/'
			Return '111111'
	EndSelect
EndFunc


;~ Internal use only.
Func ASMNumber($number, $small = False)
	If $number >= 0 Then
		$number = Dec($number)
	EndIf
	If $small And $number <= 127 And $number >= -128 Then
		Return SetExtended(1, Hex($number, 2))
	Else
		Return SetExtended(0, SwapEndian(Hex($number, 8)))
	EndIf
EndFunc
#EndRegion Memory GWA2


#Region Memory unused / debugging functions
;~ Alternate way to get anything, reads directly from game memory without call to Scan something - but is not robust and will break anytime the game changes
Func GetDataFromRelativeAddress($processHandle, $relativeCheatEngineAddress, $size)
	Local $baseAddress = ScanForProcess()
	Local $fullAddress = $baseAddress + $relativeCheatEngineAddress - 0x1000
	Local $buffer = DllStructCreate('byte[' & $size & ']')
	Local $result = SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'ptr', $fullAddress, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
	Return $buffer
EndFunc


;~ Compute and print structure offsets and total size based on structure definition string
Func ComputeStructureOffsets($structureDefinition)
	Local $offset = 0
	Local $fields = StringSplit($structureDefinition, ';', 2)

	For $field In $fields
		$field = StringStripWS($field, 3)
		If $field = '' Then ContinueLoop

		Local $parts = StringSplit($field, ' ', 2)
		Local $type = $parts[0]
		Local $name = $parts[1]

		; Handle arrays (for example wchar name[32])
		Local $count = 1
		Local $countPosition = StringInStr($name, '[')
		If $countPosition > 0 Then
			Local $countSize = StringInStr($name, ']') - $countPosition - 1
			$count = Number(StringMid($name, $countPosition + 1, $countSize))
			$name = StringLeft($name, $countPosition - 1)
		EndIf

		Local $size = TypeSize($type) * $count
		Out(StringFormat('%-30s offset=%3d size=%3d', $name, $offset, $size))
		$offset += $size
	Next

	Out('Total size = ' & $offset & ' bytes')
EndFunc


;~ Returns the size in bytes of the given type
Func TypeSize($type)
	Switch StringLower($type)
		Case 'byte'
			Return 1
		Case 'char'
			Return 1
		Case 'short'
			Return 2
		Case 'word'
			Return 2
		Case 'wchar'
			Return 2
		Case 'dword'
			Return 4
		Case 'int'
			Return 4
		Case 'float'
			Return 4
		Case 'long'
			Return 4
		Case 'double'
			Return 8
		Case 'ptr'
			Return @AutoItX64 ? 8 : 4
		Case Else
			Return -1
	EndSwitch
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........:	_ProcessGetName
; Description ...:	Returns a string containing the process name that belongs to a given PID.
; Syntax.........:	_ProcessGetName( $pid )
; Parameters ....:	$pid - The PID of a currently running process
; Return values .:	Success		- The name of the process
;					Failure		- Blank string and sets @error
;						1 - Process doesn't exist
;						2 - Error getting process list
;						3 - No processes found
; Author ........: Erifash <erifash [at] gmail [dot] com>, Wouter van Kesteren.
; Remarks .......: Supplementary to ProcessExists().
; ===============================================================================================================================
Func __ProcessGetName($pid)
	If Not ProcessExists($pid) Then Return SetError(1, 0, '')
	If Not @error Then
		Local $processes = ProcessList()
		For $i = 1 To $processes[0][0]
			If $processes[$i][1] = $pid Then Return $processes[$i][0]
		Next
	EndIf
	Return SetError(1, 0, '')
EndFunc
#EndRegion Memory unused / debugging functions
#EndRegion Memory Utils


#Region AutoIt Utils
;~ Return the value if it's not Null else the defaultValue
Func GetOrDefault($value, $defaultValue)
	Return ($value == Null) ? $defaultValue : $value
EndFunc


;~ Returns True if item is present in array, else False, assuming that array is indexed from 0
Func ArrayContains($array, $item)
	For $arrayItem In $array
		If $arrayItem == $item Then Return True
	Next
	Return False
EndFunc


;~ Fill 1D or 2D array by reference with a specified value, assuming that array is indexed from 0
Func FillArray(ByRef $array, $value)
	If UBound($array, $UBOUND_DIMENSIONS) == 1 Then
		For $i = 0 To UBound($array) - 1
			$array[$i] = $value
		Next
	ElseIf UBound($array, $UBOUND_DIMENSIONS) == 2 Then
		For $i = 0 To UBound($array, $UBOUND_ROWS) - 1
			For $j = 0 To UBound($array, $UBOUND_COLUMNS) - 1
				$array[$i][$j] = $value
			Next
		Next
	EndIf
EndFunc


;~ Add to a Map of arrays (create key and new array if unexisting, add to existent array if existing)
Func AppendArrayMap($map, $key, $element)
	If ($map[$key] == Null) Then
		Local $newArray[1] = [$element]
		$map[$key] = $newArray
	Else
		_ArrayAdd($map[$key], $element)
	EndIf
	Return $map
EndFunc


;~ Create a map from an array to have a one liner map instantiation
Func MapFromArray($keys)
	Local $map[]
	For $key In $keys
		$map[$key] = 1
	Next
	Return $map
EndFunc


;~ Create a map from a double array of dimensions [N, 2] to have a one liner map instantiation with values
Func MapFromDoubleArray($keysAndValues)
	Local $map[]
	For $i = 0 To UBound($keysAndValues) - 1
		$map[$keysAndValues[$i][0]] = $keysAndValues[$i][1]
	Next
	Return $map
EndFunc


;~ Create a map from two arrays to have a one liner map instantiation with values
Func MapFromArrays($keys, $values)
	Local $map[]
	For $i = 0 To UBound($keys) - 1
		$map[$keys[$i]] = $values[$i]
	Next
	Return $map
EndFunc


;~ Clone a map
Func CloneMap($original)
	Local $clone[]
	For $key In MapKeys($original)
		$clone[$key] = $original[$key]
	Next
	Return $clone
EndFunc


;~ Clone a dictiomary map. Dictionary map has an advantage that it is inherently passed by reference to functions as the same object without the need of copying
Func CloneDictMap($original)
	Local $clone = ObjCreate('Scripting.Dictionary')
	For $key In $original.Keys
		$clone.Add($key, $original.Item($key))
	Next
	Return $clone
EndFunc


;~ Find common longest substring in two strings
Func LongestCommonSubstringOfTwoStrings($string1, $string2)
	Local $longestCommonSubstrings[0]
	Local $string1characters = StringSplit($string1, '')
	Local $string2characters = StringSplit($string2, '')
	; deleting first element of string arrays (which has the count of characters in AutoIT) to have string arrays indexed from 0
	_ArrayDelete($string1characters, 0)
	_ArrayDelete($string2characters, 0)
	Local $longestCommonSubstringSize = 0
	Local $array[UBound($string1characters) + 1][UBound($string2characters) + 1]
	FillArray($array, 0)

	For $i = 1 To UBound($string1characters)
		For $j = 1 To UBound($string2characters)
			If ($string1characters[$i-1] == $string2characters[$j-1]) Then
				$array[$i][$j] = $array[$i-1][$j-1] + 1
				If $array[$i][$j] > $longestCommonSubstringSize Then
					$longestCommonSubstringSize = $array[$i][$j]
					; resetting to empty array
					Local $longestCommonSubstrings[0]
					_ArrayAdd($longestCommonSubstrings, StringMid($string1, $i - $longestCommonSubstringSize + 1, $longestCommonSubstringSize))
				ElseIf $array[$i][$j] = $longestCommonSubstringSize Then
					_ArrayAdd($longestCommonSubstrings, StringMid($string1, $i - $longestCommonSubstringSize + 1, $longestCommonSubstringSize))
				EndIf
			Else
				$array[$i][$j] = 0
			EndIf
		Next
	Next

	; return first string from the array of longest substrings (there might be more than 1 with the same maximal size)
	Return $longestCommonSubstrings[0]
EndFunc


;~ Find common longest substring in array of strings, indexed from 0
Func LongestCommonSubstring($strings)
	Local $longestCommonSubstring = ''
	If UBound($strings) = 0 Then Return ''
	If UBound($strings) = 1 Then Return $strings[0]
	Local $firstStringLength = StringLen($strings[0])
	If $firstStringLength = 0 Then
		Return ''
	Else
		For $i = 0 To $firstStringLength - 1
			For $j = 0 To $firstStringLength - $i
				If $j > StringLen($longestCommonSubstring) And IsSubstring(StringMid($strings[0], $i, $j), $strings) Then
					$longestCommonSubstring = StringMid($strings[0], $i, $j)
				EndIf
			Next
		Next
	EndIf
	Return $LongestCommonSubstring
EndFunc


;~ Returns True if find substring is in every string in the array of strings
Func IsSubstring($find, $strings)
	If UBound($strings) < 1 And StringLen($find) < 1 Then
		Return False
	EndIf
	For $string In $strings
		If Not StringInStr($string, $find) Then
			Return False
		EndIf
	Next
	Return True
EndFunc


;~ Wrapper around Eval to add validation and error handling
Func SafeEval($variableName, $logging = True)
	Local $value = Eval($variableName)
	If @error Then
		If $logging Then Error('Couldnt evaluate ' & $variableName)
		Return Null
	EndIf
	Return $value
EndFunc


;~ Returns the distance between two coordinate pairs.
Func ComputeDistance($X1, $Y1, $X2, $Y2)
	Return Sqrt(($X1 - $X2) ^ 2 + ($Y1 - $Y2) ^ 2)
EndFunc


;~ Return True if the point X, Y is over the line defined by aX + bY + c = 0
Func IsOverLine($coefficientX, $coefficientY, $fixedCoefficient, $posX, $posY)
	Local $position = $posX * $coefficientX + $posY * $coefficientY + $fixedCoefficient
	If $position > 0 Then
		Return True
	EndIf
	Return False
EndFunc


;~ Checks if a point is within a polygon defined by an array
;~ Point-in-Polygon algorithm — Ray Casting Method - pretty cool stuff !
Func GetIsPointInPolygon($areaCoordinates, $X = 0, $Y = 0)
	Local $edges = UBound($areaCoordinates)
	Local $oddNodes = False
	If $edges < 3 Then Return False
	If $X = 0 Then
		Local $me = GetMyAgent()
		$X = DllStructGetData($me, 'X')
		$Y = DllStructGetData($me, 'Y')
	EndIf
	Local $j = $edges - 1
	For $i = 0 To $edges - 1
		If (($areaCoordinates[$i][1] < $Y And $areaCoordinates[$j][1] >= $Y) _
				Or ($areaCoordinates[$j][1] < $Y And $areaCoordinates[$i][1] >= $Y)) _
				And ($areaCoordinates[$i][0] <= $X Or $areaCoordinates[$j][0] <= $X) Then
			If ($areaCoordinates[$i][0] + ($Y - $areaCoordinates[$i][1]) / ($areaCoordinates[$j][1] - $areaCoordinates[$i][1]) * ($areaCoordinates[$j][0] - $areaCoordinates[$i][0]) < $X) Then
				$oddNodes = Not $oddNodes
			EndIf
		EndIf
		$j = $i
	Next
	Return $oddNodes
EndFunc


;~ Sleep a random amount of time.
Func RandomSleep($baseAmount, $randomFactor = Null)
	Local $randomAmount
	Select
		Case $randomFactor <> Null
			$randomAmount = $baseAmount * $randomFactor
		Case $baseAmount >= 15000
			$randomAmount = $baseAmount * 0.025
		Case $baseAmount >= 6000
			$randomAmount = $baseAmount * 0.05
		Case $baseAmount >= 3000
			$randomAmount = $baseAmount * 0.1
		Case $baseAmount >= 10
			$randomAmount = $baseAmount * 0.2
		Case Else
			$randomAmount = 1
	EndSelect
	Sleep(Random($baseAmount - $randomAmount, $baseAmount + $randomAmount))
EndFunc


;~ Allows the user to run a function by hand in a call fun(arg1, arg2, [...])
Func DynamicExecution($functionCall)
	Local $openParenthesisPosition = StringInStr($functionCall, '(')
	Local $functionName = StringLeft($functionCall, $openParenthesisPosition - 1)
	If $functionName == '' Then
		Info('Call to nothing ?!')
		Return
	EndIf
	Info('Call to ' & $functionName)
	Local $argumentsString = StringMid($functionCall, $openParenthesisPosition + 1, StringLen($functionCall) - $openParenthesisPosition)
	Local $functionArguments = ParseFunctionArguments($argumentsString)
	; flag to be able to pass unlimited array of arguments into Call() function
	Local $arguments[1] = ['CallArgArray']
	_ArrayConcatenate($arguments, $functionArguments)
	Call($functionName, $arguments)
EndFunc


;~ Return the array of arguments from input string in a syntax arg1, arg2, [...]
Func ParseFunctionArguments($args)
	Local $arguments[0]
	Local $temp = 0, $commaPosition = 1
	While $commaPosition < StringLen($args)
		$temp = StringInStr($args, ',', 0, 1, $commaPosition)
		If $temp == 0 Then $temp = StringLen($args)
		Info(StringMid($args, $commaPosition, $temp - $commaPosition))
		_ArrayAdd($arguments, StringMid($args, $commaPosition, $temp - $commaPosition))
		$commaPosition = $temp + 1
	WEnd
	Return $arguments
EndFunc


;~ Function to print a structure in a table - pretty brutal tbh
Func _dlldisplay($struct, $fieldNames = Null)
	Local $nextPtr, $currentPtr = DllStructGetPtr($struct, 1)
	Local $offset = 0, $dllSize = DllStructGetSize($struct)
	Local $elementValue, $type, $typeSize, $elementSize, $arrayCount, $aligns

	; #|Offset|Type|Size|Value'
	Local $structArray[1][6] = [['-', '-', $currentPtr, '<struct>', 0, '-']]

	; loop through elements
	For $i = 1 To 2 ^ 63
		; backup first index value, establish type and typesize of element, restore first index value
		$elementValue = DllStructGetData($struct, $i, 1)
		Switch VarGetType($elementValue)
			Case 'Int32', 'Int64'
				DllStructSetData($struct, $i, 0x7777666655554433, 1)
				Switch DllStructGetData($struct, $i, 1)
					Case 0x7777666655554433
						$type = 'int64'
						$typeSize = 8
					Case 0x55554433
						DllStructSetData($struct, $i, 0x88887777, 1)
						$type = (DllStructGetData($struct, $i, 1) > 0 ? 'uint' : 'int')
						$typeSize = 4
					Case 0x4433
						DllStructSetData($struct, $i, 0x8888, 1)
						$type = (DllStructGetData($struct, $i, 1) > 0 ? 'ushort' : 'short')
						$typeSize = 2
					Case 0x33
						$type = 'byte'
						$typeSize = 1
				EndSwitch
			Case 'Ptr'
				$type = 'ptr'
				$typeSize = @AutoItX64 ? 8 : 4
			Case 'String'
				DllStructSetData($struct, $i, ChrW(0x2573), 1)
				$type = (DllStructGetData($struct, $i, 1) = ChrW(0x2573) ? 'wchar' : 'char')
				$typeSize = ($type = 'wchar') ? 2 : 1
			Case 'Double'
				DllStructSetData($struct, $i, 10 ^ - 15, 1)
				$type = (DllStructGetData($struct, $i, 1) = 10 ^ - 15 ? 'double' : 'float')
				$typeSize = ($type = 'double') ? 8 : 4
		EndSwitch
		DllStructSetData($struct, $i, $elementValue, 1)

		; calculate element total size based on distance to next element
		$nextPtr = DllStructGetPtr($struct, $i + 1)
		$elementSize = $nextPtr ? Int($nextPtr - $currentPtr) : $dllSize

		; calculate true array count. Walk index backwards till there is NOT an error
		$arrayCount = Int($elementSize / $typeSize)
		While $arrayCount > 1
			DllStructGetData($struct, $i, $arrayCount)
			If Not @error Then ExitLoop
			$arrayCount -= 1
		WEnd

		; alignment is whatever space is left
		$aligns = $elementSize - ($arrayCount * $typeSize)
		$elementSize -= $aligns

		; Add/print values and alignment
		Switch $type
			Case 'wchar', 'char', 'byte'
				_ArrayAdd($structArray, $i & '|' & ($fieldNames <> Null ? $fieldNames[$i] : '-') & '|' & $offset & '|' & $type & '[' & $arrayCount & ']|' & $elementSize & '|' & DllStructGetData($struct, $i))
			; 'uint', 'int', 'ushort', 'short', 'double', 'float', 'ptr'
			Case Else
				If $arrayCount > 1 Then
					_ArrayAdd($structArray, $i & '|' & ($fieldNames <> Null ? $fieldNames[$i] : '-') & '|' & $offset & '|' & $type & '[' & $arrayCount & ']' & '|' & $elementSize & ' (' & $typeSize & ')|' & (DllStructGetData($struct, $i) ? '[1] ' & $elementValue : '-'))
					; skip empty arrays
					If DllStructGetData($struct, $i) Then
						For $j = 2 To $arrayCount
							_ArrayAdd($structArray, '-|' & '-' & '|' & $offset + ($typeSize * ($j - 1)) & '|-|-|[' & $j & '] ' & DllStructGetData($struct, $i, $j))
						Next
					EndIf
				Else
					_ArrayAdd($structArray, $i & '|' & ($fieldNames <> Null ? $fieldNames[$i] : '-') & '|' & $offset & '|' & $type & '|' & $elementSize & '|' & $elementValue)
				EndIf
		EndSwitch
		If $aligns Then _ArrayAdd($structArray, '-|-|-|<alignment>|' & ($aligns) & '|-')

		; if no next ptr then this was the last/only element
		If Not $nextPtr Then ExitLoop

		; update offset, size and next ptr
		$offset += $elementSize + $aligns
		$dllSize -= $elementSize + $aligns
		$currentPtr = $nextPtr
	Next

	_ArrayAdd($structArray, '-|-|' & DllStructGetPtr($struct) + DllStructGetSize($struct) & '|<endstruct>|' & DllStructGetSize($struct) & '|-')
	_ArrayToClip($structArray)
	_ArrayDisplay($structArray, '', '', 64, Default, '#|Name|Offset|Type|Size|Value')

	Return $structArray
EndFunc
#EndRegion AutoIt Utils
