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
	Local $Region[12] = [$ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_AMERICA, $ID_ASIA_CHINA, $ID_ASIA_JAPAN, $ID_ASIA_KOREA, $ID_INTERNATIONAL]
	Local $Language[12] = [$ID_ENGLISH, $ID_FRENCH, $ID_GERMAN, $ID_ITALIAN, $ID_SPANISH, $ID_POLISH, $ID_RUSSIAN, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH]
	Local $Random = Random(0, $district - 1, 1)
	MoveMap($mapID, $Region[$Random], 0, $Language[$Random])
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
Func ReturnBackToOutpost($outpostId)
	Local $outpostName = $MAP_NAMES_FROM_IDS[$outpostId]
	Info('Returning to ' & $outpostName & ' (outpost)')
	If GetMapID() == $outpostId Then
		Warn('Player is already in ' & $outpostName & ' (outpost)')
		Return $SUCCESS
	Endif
	ResignAndReturnToOutpost()
	WaitMapLoading($outpostId, 10000, 1000)
	Return GetMapID() == $outpostId ? $SUCCESS : $FAIL
EndFunc


Func ResignAndReturnToOutpost()
	Resign()
	Sleep(3500)
	ReturnToOutpost()
	Sleep(5000)
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
		RandomSleep(GetPing() + 3000)
		GoToNPC(GetNearestNPCToCoords(-2500, 18700))
		RandomSleep(GetPing() + 750)
		Dialog(0x85)
		RandomSleep(GetPing() + 750)
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
			WaitMapLoading($ID_UNDERWORLD)
			If GetMapID() <> $ID_UNDERWORLD Then
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
		RandomSleep(GetPing() + 3000)
		GoToNPC(GetNearestNPCToCoords(-4124, 19829))
		RandomSleep(GetPing() + 750)
		Dialog(0x85)
		RandomSleep(GetPing() + 750)
		Dialog(0x86)
		WaitMapLoading($ID_UNDERWORLD)
		If GetMapID() <> $ID_UNDERWORLD Then
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


#Region Loot items
;~ Loot items around character
Func PickUpItems($defendFunction = Null, $shouldPickItem = DefaultShouldPickItem, $range = $RANGE_COMPASS)
	If $inventory_management_cache['@pickup.nothing'] Then Return

	Local $item
	Local $agentID
	Local $deadlock
	Local $agents = GetAgentArray($ID_AGENT_TYPE_ITEM)
	For $agent In $agents
		If IsPlayerDead() Then Return
		If Not GetCanPickUp($agent) Then ContinueLoop
		If GetDistance(GetMyAgent(), $agent) > $range Then ContinueLoop

		$agentID = DllStructGetData($agent, 'ID')
		$item = GetItemByAgentID($agentID)

		If ($shouldPickItem($item)) Then
			If $defendFunction <> Null Then $defendFunction()
			If Not GetAgentExists($agentID) Then ContinueLoop
			PickUpItem($item)
			$deadlock = TimerInit()
			While IsPLayerAlive() And GetAgentExists($agentID) And TimerDiff($deadlock) < 10000
				RandomSleep(100)
			WEnd
		EndIf
	Next

	If $bags_count == 5 And CountSlots(1, 3) == 0 Then
		MoveItemsToEquipmentBag()
	EndIf
EndFunc


;~ Tests if an item is assigned to you.
Func GetAssignedToMe($agent)
	Return DllStructGetData($agent, 'Owner') == GetMyID()
EndFunc


;~ Tests if you can pick up an item.
Func GetCanPickUp($agent)
	Return GetAssignedToMe($agent) Or DllStructGetData($agent, 'Owner') = 0
EndFunc
#EndRegion Loot items


#Region Loot Chests
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
	If IsPlayerDead() Then Return Null
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
	If IsPlayerDead() Then Return
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
			If IsPlayerDead() Then Return
			RandomSleep(GetPing() + 1000)
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
	Local $X = DllStructGetData($signpost, 'X')
	Local $Y = DllStructGetData($signpost, 'Y')
	Local $blocked = 0
	While IsPlayerAlive() And GetDistance($me, $signpost) > 250 And $blocked < 15
		Move($X, $Y, 100)
		RandomSleep(GetPing() + 50)
		If $defendFunction <> Null Then $defendFunction()
		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			If $blockedFunction <> Null And $blocked > 10 Then
				$blockedFunction()
			EndIf
			$blocked += 1
			Move($X, $Y, 100)
		EndIf
		RandomSleep(GetPing() + 50)
		$me = GetMyAgent()
	WEnd
	GoSignpost($signpost)
	RandomSleep(GetPing() + 100)
EndFunc
#EndRegion Loot Chests


#Region Use Items
;~ Use morale booster on team
Func UseMoraleConsumableIfNeeded()
	While TeamHasTooMuchMalus()
		Local $usedMoraleBooster = False
		For $DPRemoval_Sweet In $DP_REMOVAL_SWEETS
			Local $ConsumableSlot = FindInInventory($DPRemoval_Sweet)
			If $ConsumableSlot[0] <> 0 Then
				UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
				$usedMoraleBooster = True
			EndIf
		Next
		If Not $usedMoraleBooster Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


;~ Use Armor of Salvation, Essence of Celerity and Grail of Might
Func UseConset()
	UseConsumable($ID_ARMOR_OF_SALVATION)
	UseConsumable($ID_ESSENCE_OF_CELERITY)
	UseConsumable($ID_GRAIL_OF_MIGHT)
EndFunc


;~ Uses a consumable from inventory, if present
Func UseCitySpeedBoost($forceUse = False)
	If (Not $forceUse And GUICtrlRead($GUI_Checkbox_UseConsumables) == $GUI_UNCHECKED) Then Return $FAIL
	If GetMapType() <> $ID_OUTPOST Then Return $FAIL
	If GetEffectTimeRemaining(GetEffect($ID_SUGAR_JOLT_SHORT)) > 0 Or GetEffectTimeRemaining(GetEffect($ID_SUGAR_JOLT_LONG)) > 0 Then Return
	Local $ConsumableSlot = FindInInventory($ID_SUGARY_BLUE_DRINK)
	If $ConsumableSlot[0] <> 0 Then
		UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
	Else
		$ConsumableSlot = FindInInventory($ID_CHOCOLATE_BUNNY)
		If $ConsumableSlot[0] <> 0 Then UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
	EndIf
	Return $SUCCESS
EndFunc


;~ Uses an item from inventory or chest, if present
Func UseItemFromInventory($itemID, $forceUse = False, $checkXunlaiChest = True)
	Local $ConsumableItemBagAndSlot
	If $checkXunlaiChest == True And GetMapType() == $ID_OUTPOST Then
		$ConsumableItemBagAndSlot = FindInStorages(1, 21, $itemID)
	Else
		$ConsumableItemBagAndSlot = FindInStorages(1, $bags_count, $itemID)
	EndIf

	Local $ConsumableBag = $ConsumableItemBagAndSlot[0]
	Local $ConsumableSlot = $ConsumableItemBagAndSlot[1]
	If $ConsumableBag <> 0 And $ConsumableSlot <> 0 Then
		UseItemBySlot($ConsumableBag, $ConsumableSlot)
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


;~ Uses a consumable from inventory or chest, if present
Func UseConsumable($consumableID, $forceUse = False, $checkXunlaiChest = True)
	If (Not $forceUse And GUICtrlRead($GUI_Checkbox_UseConsumables) == $GUI_UNCHECKED) Then Return
	If Not IsConsumable($consumableID) Then
		Warn('Provided item model ID might not correspond to consumable')
		Return $FAIL
	EndIf
	Local $result = UseItemFromInventory($consumableID, $forceUse, $checkXunlaiChest)
	If $result == $SUCCESS Then Info('Consumable used successfully')
	If $result == $FAIL Then Warn('Could not find specified consumable in inventory')
	Return $result
EndFunc


;~ Uses a scroll from inventory or chest, if present
Func UseScroll($scrollID, $forceUse = False, $checkXunlaiChest = True)
	If (Not $forceUse And GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_UNCHECKED) Then Return
	If Not IsBlueScroll($scrollID) And Not IsGoldScroll($scrollID) Then
		Warn('Provided item model ID might not correspond to scroll')
		Return $FAIL
	EndIf
	Local $result = UseItemFromInventory($scrollID, $forceUse, $checkXunlaiChest)
	If $result == $SUCCESS Then Info('Scroll used successfully')
	If $result == $FAIL Then Warn('Could not find specified scroll in inventory')
	Return $result
EndFunc


;~ Uses the Item from $bag at position $slot (positions start at 1)
Func UseItemBySlot($bag, $slot)
	If $bag > 0 And $slot > 0 Then
		If IsPlayerAlive() And GetMapType() <> $ID_Loading Then
			Local $item = GetItemBySlot($bag, $slot)
			SendPacket(8, $HEADER_Item_USE, DllStructGetData($item, 'ID'))
		EndIf
	EndIf
EndFunc
#EndRegion Use Items


#Region Utils
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


;~ Do an operation on selected rows of 2D array. Available number of columns for array are 2, 3, 4, 5
;~ $firstIndex and $lastIndex specify start and end of range of rows of 2D array on which $function should be performed
;~ Return $FAIL if operation failed on any row, $SUCCESS if operation succeded for all rows od 2D array
Func DoForArrayRows($array, $firstIndex, $lastIndex, $function)
	If Not IsArray($array) Or UBound($array, $UBOUND_DIMENSIONS) <> 2 Then Return $FAIL
	If UBound($array, $UBOUND_COLUMNS) <> 2 And UBound($array, $UBOUND_COLUMNS) <> 3 And UBound($array, $UBOUND_COLUMNS) <> 4 And UBound($array, $UBOUND_COLUMNS) <> 5 Then Return $FAIL
	If $firstIndex < 1 Or UBound($array) < $lastIndex Then Return $FAIL
	If $firstIndex > $lastIndex Then Return $FAIL
	Local $result = $SUCCESS
	; Caution, array rows are indexed from 1, but $array is indexed from 0
	For $i = $firstIndex - 1 To $lastIndex - 1
		If UBound($array, $UBOUND_COLUMNS) == 2 Then
			$result = $function($array[$i][0], $array[$i][1])
		ElseIf UBound($array, $UBOUND_COLUMNS) == 3 Then
			$result = $function($array[$i][0], $array[$i][1], $array[$i][2])
		ElseIf UBound($array, $UBOUND_COLUMNS) == 4 Then
			$result = $function($array[$i][0], $array[$i][1], $array[$i][2], $array[$i][3])
		ElseIf UBound($array, $UBOUND_COLUMNS) == 5 Then
			$result = $function($array[$i][0], $array[$i][1], $array[$i][2], $array[$i][3], $array[$i][4])
		EndIf
		If $result <> $SUCCESS Then Return $result
	Next
	Return $SUCCESS
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
	Local $LongestCommonSubstringSize = 0
	Local $array[UBound($string1characters) + 1][UBound($string2characters) + 1]
	FillArray($array, 0)

	For $i = 1 To UBound($string1characters)
		For $j = 1 To UBound($string2characters)
			If ($string1characters[$i-1] == $string2characters[$j-1]) Then
				$array[$i][$j] = $array[$i-1][$j-1] + 1
				If $array[$i][$j] > $LongestCommonSubstringSize Then
					$LongestCommonSubstringSize = $array[$i][$j]
					; resetting to empty array
					Local $longestCommonSubstrings[0]
					_ArrayAdd($longestCommonSubstrings, StringMid($string1, $i - $LongestCommonSubstringSize + 1, $LongestCommonSubstringSize))
				ElseIf $array[$i][$j] = $LongestCommonSubstringSize Then
					_ArrayAdd($longestCommonSubstrings, StringMid($string1, $i - $LongestCommonSubstringSize + 1, $LongestCommonSubstringSize))
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


;~ Returns the distance between two coordinate pairs.
Func ComputeDistance($X1, $Y1, $X2, $Y2)
	Return Sqrt(($X1 - $X2) ^ 2 + ($Y1 - $Y2) ^ 2)
EndFunc


;~ Returns the distance between two agents.
Func GetDistance($agent1, $agent2)
	Return Sqrt((DllStructGetData($agent1, 'X') - DllStructGetData($agent2, 'X')) ^ 2 + (DllStructGetData($agent1, 'Y') - DllStructGetData($agent2, 'Y')) ^ 2)
EndFunc


;~ Returns the distance between agent and point specified by a coordinate pair.
Func GetDistanceToPoint($agent, $X, $Y)
	Return Sqrt(($X - DllStructGetData($agent, 'X')) ^ 2 + ($Y - DllStructGetData($agent, 'Y')) ^ 2)
EndFunc


;~ Returns the square of the distance between two agents.
Func GetPseudoDistance($agent1, $agent2)
	Return (DllStructGetData($agent1, 'X') - DllStructGetData($agent2, 'X')) ^ 2 + (DllStructGetData($agent1, 'Y') - DllStructGetData($agent2, 'Y')) ^ 2
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


;~ Sleep a period of time, plus or minus a tolerance
Func TolSleep($amount = 150, $randomAmount = 50)
	Sleep(Random($amount - $randomAmount, $amount + $randomAmount))
EndFunc


;~ Alias function for DllStructCreate. Can be used optionally. It can improve readability at the cost of performance, 1 additional layer in function call stack
Func CreateStruct($structDefinition)
	Return DllStructCreate($structDefinition)
EndFunc


;~ Alias function for DllStructSetData. Can be used optionally. It can improve readability at the cost of performance, 1 additional layer in function call stack
Func SetStructData($object, $dataString, $value)
	DllStructSetData($object, $dataString, $value)
EndFunc


;~ Alias function for DllStructGetData. Can be used optionally. It can improve readability at the cost of performance, 1 additional layer in function call stack
Func GetStructData($object, $dataString)
	Return DllStructGetData($object, $dataString)
EndFunc


;~ Alias function for DllStructGetSize. Can be used optionally. It can improve readability at the cost of performance, 1 additional layer in function call stack
Func GetStructSize($object)
	Return DllStructGetSize($object)
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
#EndRegion Utils


#Region Quests status
;~ Take a quest or a reward - for reward, expectedState should be 0 once reward taken
Func TakeQuestOrReward($npc, $questID, $dialogID, $expectedState = 0)
	Local $questState = 999
	While $questState <> $expectedState
		Info('Current quest state : ' & $questState)
		GoToNPC($npc)
		RandomSleep(GetPing() + 750)
		Dialog($dialogID)
		RandomSleep(GetPing() + 750)
		$questState = DllStructGetData(GetQuestByID($questID), 'LogState')
	WEnd
EndFunc
#EndRegion Quests status


#Region Actions
;~ Move to specified position while defending and trying to avoid body block and trying to avoid getting stuck
Func MoveAvoidingBodyBlock($destinationX, $destinationY, $options = $Default_MoveDefend_Options)
	If IsPlayerDead() Then Return $FAIL
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
		Sleep(GetPing())
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Detect if player is rubberbanding
Func IsPlayerRubberBanding()
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
		RandomSleep(500 + GetPing())
		Return True
	EndIf
	Return False
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


;~ Aggro a foe
Func AggroAgent($targetAgent)
	While IsPlayerAlive() And GetDistance(GetMyAgent(), $targetAgent) > $RANGE_EARSHOT - 100
		Move(DllStructGetData($targetAgent, 'X'), DllStructGetData($targetAgent, 'Y'))
		RandomSleep(200)
	WEnd
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


;~ Attack and use one of the skill provided if available, else wait for specified duration
;~ Credits to Shiva for auto-attack improvement
Func AttackOrUseSkill($attackSleep, $skill1 = Null, $skill2 = Null, $skill3 = Null, $skill4 = Null, $skill5 = Null, $skill6 = Null, $skill7 = Null, $skill8 = Null)
	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	Local $skillUsed = False

	; Start auto-attack first
	Attack($target)
	; Small delay to ensure attack starts
	RandomSleep(20)

	For $i = 1 To 8
		Local $skillSlot = Eval('skill' & $i)
		If ($skillSlot <> Null And IsRecharged($skillSlot)) Then
			UseSkillEx($skillSlot, $target)
			RandomSleep(20)
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


#Region Map Clearing Utilities
Global $Default_MoveAggroAndKill_Options = ObjCreate('Scripting.Dictionary')
$Default_MoveAggroAndKill_Options.Add('fightFunction', KillFoesInArea)
$Default_MoveAggroAndKill_Options.Add('fightRange', $RANGE_EARSHOT * 1.5)
$Default_MoveAggroAndKill_Options.Add('flagHeroesOnFight', False)
$Default_MoveAggroAndKill_Options.Add('callTarget', True)
$Default_MoveAggroAndKill_Options.Add('priorityMobs', False)
$Default_MoveAggroAndKill_Options.Add('skillsMask', Null)
$Default_MoveAggroAndKill_Options.Add('skillsCostMap', Null)
$Default_MoveAggroAndKill_Options.Add('skillsCastTimeMap', Null)
$Default_MoveAggroAndKill_Options.Add('lootInFights', False)
$Default_MoveAggroAndKill_Options.Add('openChests', True)
$Default_MoveAggroAndKill_Options.Add('chestOpenRange', $RANGE_SPIRIT)
; default 60 seconds fight duration
$Default_MoveAggroAndKill_Options.Add('fightDuration', 60000)

Global $Default_FlagMoveAggroAndKill_Options = CloneDictMap($Default_MoveAggroAndKill_Options)
$Default_FlagMoveAggroAndKill_Options.Item('flagHeroesOnFight') = True

Global $Default_MoveDefend_Options = ObjCreate('Scripting.Dictionary')
$Default_MoveDefend_Options.Add('defendFunction', Null)
$Default_MoveDefend_Options.Add('moveTimeOut', 5 * 60 * 1000)
; random factor for movement
$Default_MoveDefend_Options.Add('randomFactor', 100)
$Default_MoveDefend_Options.Add('hosSkillSlot', 0)
$Default_MoveDefend_Options.Add('deathChargeSkillSlot', 0)
$Default_MoveDefend_Options.Add('openChests', False)
$Default_MoveDefend_Options.Add('chestOpenRange', $RANGE_SPIRIT)


;~ Stand and fight any enemies that come within specified range within specified time interval (default 60 seconds) in options parameter
Func WaitAndFightEnemiesInArea($options = $Default_MoveAggroAndKill_Options)
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


;~ Move, aggro and vanquish groups of mobs specified in 2D $foes array
;~ 2D $foes array should have 3 elements/columns in each row: x coordinate, y coordinate and group name.
;~ Optionally 2D $foes array can have 4th element/column for each row: range in which group should be aggroed
;~ $firstGroup and $lastGroup specify start and end of range of groups within provided array to vanquish
;~ Return $FAIL if the party is dead, $SUCCESS if not
Func MoveAggroAndKillGroups($foes, $firstGroup, $lastGroup)
	If IsPlayerAndPartyWiped() Then Return $FAIL
	If UBound($foes, $UBOUND_COLUMNS) <> 3 And UBound($foes, $UBOUND_COLUMNS) <> 4 Then Return $FAIL
	Return DoForArrayRows($foes, $firstGroup, $lastGroup, MoveAggroAndKillInRange)
EndFunc


;~ Version to flag heroes before fights
;~ Better against heavy AoE - dangerous when flags can end up in a non accessible spot
Func FlagMoveAggroAndKill($x, $y, $log = '', $options = $Default_FlagMoveAggroAndKill_Options)
	Return MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ Version to specify fight range as parameter instead of in options map
Func MoveAggroAndKillInRange($x, $y, $log = '', $range = $RANGE_EARSHOT * 1.5, $options = Null)
	If $options = Null Then $options = CloneDictMap($Default_MoveAggroAndKill_Options)
	$options.Item('fightRange') = $range
	Return MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ Version to specify fight range as parameter instead of in options map and also flag heroes before fights
Func FlagMoveAggroAndKillInRange($x, $y, $log = '', $range = $RANGE_EARSHOT * 1.5, $options = Null)
	If $options = Null Then $options = CloneDictMap($Default_FlagMoveAggroAndKill_Options)
	$options.Item('fightRange') = $range
	Return MoveAggroAndKill($x, $y, $log, $options)
EndFunc


;~ Clear a zone around the coordinates provided
;~ Credits to Shiva for auto-attack improvement
Func MoveAggroAndKill($x, $y, $log = '', $options = $Default_MoveAggroAndKill_Options)
	If IsPlayerAndPartyWiped() Then Return $FAIL

	Local $openChests = ($options.Item('openChests') <> Null) ? $options.Item('openChests') : True
	Local $chestOpenRange = ($options.Item('chestOpenRange') <> Null) ? $options.Item('chestOpenRange') : $RANGE_SPIRIT
	Local $fightFunction = ($options.Item('fightFunction') <> Null) ? $options.Item('fightFunction') : KillFoesInArea
	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : $RANGE_EARSHOT * 1.5

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
			If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $fightRange)
			; If one member of party is dead, go to rez him before proceeding
		EndIf
		RandomSleep(250)
		If IsPlayerDead() Then Return $FAIL
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
Func KillFoesInArea($options = $Default_MoveAggroAndKill_Options)
	If IsPlayerAndPartyWiped() Then Return $FAIL

	Local $fightRange = ($options.Item('fightRange') <> Null) ? $options.Item('fightRange') : $RANGE_EARSHOT * 1.5
	Local $flagHeroes = ($options.Item('flagHeroesOnFight') <> Null) ? $options.Item('flagHeroesOnFight') : False
	Local $callTarget = ($options.Item('callTarget') <> Null) ? $options.Item('callTarget') : True
	Local $priorityMobs = ($options.Item('priorityMobs') <> Null) ? $options.Item('priorityMobs') : False
	Local $lootInFights = ($options.Item('lootInFights') <> Null) ? $options.Item('lootInFights') : False
	Local $skillsMask = ($options.Item('skillsMask') <> Null And IsArray($options.Item('skillsMask')) And UBound($options.Item('skillsMask')) == 8) ? $options.Item('skillsMask') : Null
	Local $skillsCostMap = ($options.Item('skillsCostMap') <> Null And UBound($options.Item('skillsCostMap')) == 8) ? $options.Item('skillsCostMap') : Null

	Local $me = GetMyAgent()
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
	If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $fightRange)
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Create a map containing foes and their priority level
Func CreateMobsPriorityMap()
	; Voltaic farm foes model IDs
	Local $PN_SS_Dominator		= 6544
	Local $PN_SS_Dreamer		= 6545
	Local $PN_SS_Contaminator	= 6546
	Local $PN_SS_Blasphemer		= 6547
	Local $PN_SS_Warder			= 6548
	Local $PN_SS_Priest			= 6549
	Local $PN_SS_Defender		= 6550
	Local $PN_SS_Zealot			= 6557
	Local $PN_SS_Summoner		= 6558
	Local $PN_Modniir_Priest	= 6563

	; Gemstone farm foes model IDs
	Local $Gem_AnurKaya			= 5217
	;Local $Gem_AnurDabi		= 5218
	Local $Gem_AnurSu			= 5219
	Local $Gem_AnurKi			= 5220
	;Local $Gem_AnurTuk			= 5222
	;Local $Gem_AnurRund		= 5224
	;Local $Gem_MiseryTitan		= 5246
	Local $Gem_RageTitan		= 5247
	;Local $Gem_DementiaTitan	= 5248
	;Local $Gem_AnguishTitan	= 5249
	Local $Gem_FuryTitan		= 5251
	;Local $Gem_MindTormentor	= 5255
	;Local $Gem_SoulTormentor	= 5256
	Local $Gem_WaterTormentor	= 5257
	Local $Gem_HeartTormentor	= 5258
	;Local $Gem_FleshTormentor	= 5259
	Local $Gem_TortureWebDryder	= 5266
	Local $Gem_GreatDreamRider	= 5267

	; War Supply farm foes model IDs, why so many? (o_O)
	;Local $WarSupply_Peacekeeper_1	= 8146
	;Local $WarSupply_Peacekeeper_2	= 8147
	;Local $WarSupply_Peacekeeper_3	= 8148
	;Local $WarSupply_Peacekeeper_4	= 8170
	;Local $WarSupply_Peacekeeper_5	= 8171
	;Local $WarSupply_Marksman_1	= 8187
	;Local $WarSupply_Marksman_2	= 8188
	;Local $WarSupply_Marksman_3	= 8189
	;Local $WarSupply_Enforcer_1	= 8232
	;Local $WarSupply_Enforcer_2	= 8233
	;Local $WarSupply_Enforcer_3	= 8234
	;Local $WarSupply_Enforcer_4	= 8235
	;Local $WarSupply_Enforcer_5	= 8236
	Local $WarSupply_Sycophant_1	= 8237
	Local $WarSupply_Sycophant_2	= 8238
	Local $WarSupply_Sycophant_3	= 8239
	Local $WarSupply_Sycophant_4	= 8240
	Local $WarSupply_Sycophant_5	= 8241
	Local $WarSupply_Sycophant_6	= 8242
	Local $WarSupply_Ritualist_1	= 8243
	Local $WarSupply_Ritualist_2	= 8244
	Local $WarSupply_Ritualist_3	= 8245
	Local $WarSupply_Ritualist_4	= 8246
	Local $WarSupply_Fanatic_1		= 8247
	Local $WarSupply_Fanatic_2		= 8248
	Local $WarSupply_Fanatic_3		= 8249
	Local $WarSupply_Fanatic_4		= 8250
	Local $WarSupply_Savant_1		= 8251
	Local $WarSupply_Savant_2		= 8252
	Local $WarSupply_Savant_3		= 8253
	Local $WarSupply_Adherent_1		= 8254
	Local $WarSupply_Adherent_2		= 8255
	Local $WarSupply_Adherent_3		= 8256
	Local $WarSupply_Adherent_4		= 8257
	Local $WarSupply_Adherent_5		= 8258
	Local $WarSupply_Priest_1		= 8259
	Local $WarSupply_Priest_2		= 8260
	Local $WarSupply_Priest_3		= 8261
	Local $WarSupply_Priest_4		= 8262
	Local $WarSupply_Abbot_1		= 8263
	Local $WarSupply_Abbot_2		= 8264
	Local $WarSupply_Abbot_3		= 8265
	;Local $WarSupply_Zealot_1		= 8267
	;Local $WarSupply_Zealot_2		= 8268
	;Local $WarSupply_Zealot_3		= 8269
	;Local $WarSupply_Zealot_4		= 8270
	;Local $WarSupply_Knight_1		= 8273
	;Local $WarSupply_Knight_2		= 8274
	;Local $WarSupply_Scout_1		= 8275
	;Local $WarSupply_Scout_2		= 8276
	;Local $WarSupply_Scout_3		= 8277
	;Local $WarSupply_Scout_4		= 8278
	;Local $WarSupply_Seeker_1		= 8279
	;Local $WarSupply_Seeker_2		= 8280
	;Local $WarSupply_Seeker_3		= 8281
	;Local $WarSupply_Seeker_4		= 8282
	;Local $WarSupply_Seeker_5		= 8283
	;Local $WarSupply_Seeker_6		= 8284
	;Local $WarSupply_Seeker_7		= 8285
	;Local $WarSupply_Seeker_8		= 8286
	Local $WarSupply_Ritualist_5	= 8287
	Local $WarSupply_Ritualist_6	= 8288
	Local $WarSupply_Ritualist_7	= 8289
	Local $WarSupply_Ritualist_8	= 8290
	Local $WarSupply_Ritualist_9	= 8291
	Local $WarSupply_Ritualist_10	= 8292
	Local $WarSupply_Ritualist_11	= 8293
	;Local $WarSupply_Champion_1	= 8295
	;Local $WarSupply_Champion_2	= 8296
	;Local $WarSupply_Champion_3	= 8297
	;Local $WarSupply_Zealot_5		= 8392

	; Priority map : 0 highest kill priority, bigger numbers mean lesser priority
	Local $map[]
	$map[$PN_SS_Defender]		= 0
	$map[$PN_SS_Priest]			= 0
	$map[$PN_Modniir_Priest]	= 0
	$map[$PN_SS_Summoner]		= 1
	$map[$PN_SS_Warder]			= 2
	$map[$PN_SS_Dominator]		= 2
	$map[$PN_SS_Blasphemer]		= 2
	$map[$PN_SS_Dreamer]		= 2
	$map[$PN_SS_Contaminator]	= 2
	$map[$PN_SS_Zealot]			= 2

	$map[$Gem_TortureWebDryder]	= 0
	$map[$Gem_RageTitan]		= 1
	$map[$Gem_AnurKi]			= 2
	$map[$Gem_AnurSu]			= 3
	$map[$Gem_AnurKaya]			= 4
	$map[$Gem_GreatDreamRider]	= 5
	$map[$Gem_HeartTormentor]	= 6
	$map[$Gem_WaterTormentor]	= 7

	$map[$WarSupply_Savant_1]		= 0
	$map[$WarSupply_Savant_2]		= 0
	$map[$WarSupply_Savant_3]		= 0
	$map[$WarSupply_Adherent_1]		= 0
	$map[$WarSupply_Adherent_2]		= 0
	$map[$WarSupply_Adherent_3]		= 0
	$map[$WarSupply_Adherent_4]		= 0
	$map[$WarSupply_Adherent_5]		= 0
	$map[$WarSupply_Priest_1]		= 1
	$map[$WarSupply_Priest_2]		= 1
	$map[$WarSupply_Priest_3]		= 1
	$map[$WarSupply_Priest_4]		= 1
	$map[$WarSupply_Ritualist_1]	= 2
	$map[$WarSupply_Ritualist_2]	= 2
	$map[$WarSupply_Ritualist_3]	= 2
	$map[$WarSupply_Ritualist_4]	= 2
	$map[$WarSupply_Ritualist_5]	= 2
	$map[$WarSupply_Ritualist_6]	= 2
	$map[$WarSupply_Ritualist_7]	= 2
	$map[$WarSupply_Ritualist_8]	= 2
	$map[$WarSupply_Ritualist_9]	= 2
	$map[$WarSupply_Ritualist_10]	= 2
	$map[$WarSupply_Ritualist_11]	= 2
	$map[$WarSupply_Abbot_1]		= 3
	$map[$WarSupply_Abbot_2]		= 3
	$map[$WarSupply_Abbot_3]		= 3
	$map[$WarSupply_Sycophant_1]	= 4
	$map[$WarSupply_Sycophant_2]	= 4
	$map[$WarSupply_Sycophant_3]	= 4
	$map[$WarSupply_Sycophant_4]	= 4
	$map[$WarSupply_Sycophant_5]	= 4
	$map[$WarSupply_Sycophant_6]	= 4
	$map[$WarSupply_Fanatic_1]		= 5
	$map[$WarSupply_Fanatic_2]		= 5
	$map[$WarSupply_Fanatic_3]		= 5
	$map[$WarSupply_Fanatic_4]		= 5

	Return $map
EndFunc


;~ Returns the highest priority foe around a target agent
Func GetHighestPriorityFoe($targetAgent, $range = $RANGE_SPELLCAST)
	Local Static $mobsPriorityMap = CreateMobsPriorityMap()
	Local $agents = GetFoesInRangeOfAgent(GetMyAgent(), $range)
	Local $highestPriorityTarget = Null
	Local $priorityLevel = 99999
	Local $agentID = DllStructGetData($targetAgent, 'ID')

	For $agent In $agents
		If Not EnemyAgentFilter($agent) Then ContinueLoop
		; This gets all mobs in fight, but also mobs that just used a skill, it's not completely perfect
		; TypeMap == 0 is only when foe is idle, not casting and not fighting, also prioritized for surprise attack
		; If DllStructGetData($agent, 'TypeMap') == 0 Then ContinueLoop
		If DllStructGetData($agent, 'ID') == $agentID Then ContinueLoop
		Local $distance = GetDistance($targetAgent, $agent)
		If $distance < $range Then
			Local $priority = $mobsPriorityMap[DllStructGetData($agent, 'ModelID')]
			; map returns Null for all other mobs that don't exist in map
			If ($priority == Null) Then
				If $highestPriorityTarget == Null Then $highestPriorityTarget = $agent
				ContinueLoop
			EndIf
			If ($priority == 0) Then Return $agent
			If ($priority < $priorityLevel) Then
				$highestPriorityTarget = $agent
				$priorityLevel = $priority
			EndIf
		EndIf
	Next
	Return $highestPriorityTarget
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
	Local $X = DllStructGetData($me, 'X')
	Local $Y = DllStructGetData($me, 'Y')
	Local $rotationX = DllStructGetData($me, 'RotationCos')
	Local $rotationY = DllStructGetData($me, 'RotationSin')
	Local $distance = $range + 10

	Local $agent = GetNearestEnemyToAgent($me)
	If $agent <> Null Then
		$rotationX = DllStructGetData($agent, 'X') - $X
		$rotationY = DllStructGetData($agent, 'Y') - $Y
		Local $distanceToFoe = Sqrt($rotationX ^ 2 + $rotationY ^ 2)
		$rotationX = $rotationX / $distanceToFoe
		$rotationY = $rotationY / $distanceToFoe
	EndIf

	; To the right
	If $heroCount > 0 Then CommandHero($heroFlagPositions[0], $X + $rotationY * $distance, $Y - $rotationX * $distance)
	; To the left
	If $heroCount > 1 Then CommandHero($heroFlagPositions[1], $X - $rotationY * $distance, $Y + $rotationX * $distance)
	; Straight behind
	If $heroCount > 2 Then CommandHero($heroFlagPositions[2], $X - $rotationX * $distance, $Y - $rotationY * $distance)
	; To the right, behind
	If $heroCount > 3 Then CommandHero($heroFlagPositions[3], $X + ($rotationY - $rotationX) * $distance, $Y - ($rotationX + $rotationY) * $distance)
	; To the left, behind
	If $heroCount > 4 Then CommandHero($heroFlagPositions[4], $X - ($rotationY + $rotationX) * $distance, $Y + ($rotationX - $rotationY) * $distance)
	; To the right, way behind
	If $heroCount > 5 Then CommandHero($heroFlagPositions[5], $X + ($rotationY / 2 - 2 * $rotationX) * $distance, $Y - (2 * $rotationY + $rotationX / 2) * $distance)
	; To the left, way behind
	If $heroCount > 6 Then CommandHero($heroFlagPositions[6], $X - ($rotationY / 2 + 2 * $rotationX) * $distance, $Y + ($rotationX / 2 - 2 * $rotationY) * $distance)

EndFunc
#EndRegion Map Clearing Utilities
#EndRegion Actions


#Region Skill and Templates
;~ Loads skill template code.
Func LoadSkillTemplate($buildTemplate, $heroIndex = 0)
	Local $heroID = GetHeroID($heroIndex)
	Local $BuildTemplateChars = StringSplit($buildTemplate, '')
	; deleting first element of string array (which has the count of characters in AutoIT) to have string array indexed from 0
	_ArrayDelete($BuildTemplateChars, 0)

	Local $tempValuelateType	; 4 Bits
	Local $versionNumber		; 4 Bits
	Local $professionBits		; 2 Bits -> P
	Local $primaryProfession	; P Bits
	Local $secondaryProfession	; P Bits
	Local $attributesCount		; 4 Bits
	Local $attributesBits		; 4 Bits -> A
	Local $attributes[10][2]	; A Bits + 4 Bits (for each Attribute)
	Local $skillsBits			; 4 Bits -> S
	Local $skills[8]			; S Bits * 8
	Local $opTail				; 1 Bit

	$buildTemplate = ''
	For $character in $BuildTemplateChars
		$buildTemplate &= Base64ToBin64($character)
	Next

	$tempValuelateType = Bin64ToDec(StringLeft($buildTemplate, 4))
	$buildTemplate = StringTrimLeft($buildTemplate, 4)
	If $tempValuelateType <> 14 Then Return False

	$versionNumber = Bin64ToDec(StringLeft($buildTemplate, 4))
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	$professionBits = Bin64ToDec(StringLeft($buildTemplate, 2)) * 2 + 4
	$buildTemplate = StringTrimLeft($buildTemplate, 2)

	$primaryProfession = Bin64ToDec(StringLeft($buildTemplate, $professionBits))
	$buildTemplate = StringTrimLeft($buildTemplate, $professionBits)
	If $primaryProfession <> GetHeroProfession($heroIndex) Then Return False

	$secondaryProfession = Bin64ToDec(StringLeft($buildTemplate, $professionBits))
	$buildTemplate = StringTrimLeft($buildTemplate, $professionBits)

	$attributesCount = Bin64ToDec(StringLeft($buildTemplate, 4))
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	$attributesBits = Bin64ToDec(StringLeft($buildTemplate, 4)) + 4
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	$attributes[0][0] = $secondaryProfession
	$attributes[0][1] = $attributesCount
	For $i = 1 To $attributesCount
		$attributes[$i][0] = Bin64ToDec(StringLeft($buildTemplate, $attributesBits))
		$buildTemplate = StringTrimLeft($buildTemplate, $attributesBits)
		$attributes[$i][1] = Bin64ToDec(StringLeft($buildTemplate, 4))
		$buildTemplate = StringTrimLeft($buildTemplate, 4)
	Next

	$skillsBits = Bin64ToDec(StringLeft($buildTemplate, 4)) + 8
	$buildTemplate = StringTrimLeft($buildTemplate, 4)

	For $i = 0 To 7
		$skills[$i] = Bin64ToDec(StringLeft($buildTemplate, $skillsBits))
		$buildTemplate = StringTrimLeft($buildTemplate, $skillsBits)
	Next

	$opTail = Bin64ToDec($buildTemplate)


	LoadAttributes($attributes, $secondaryProfession, $heroIndex)

	LoadSkillBar($skills[0], $skills[1], $skills[2], $skills[3], $skills[4], $skills[5], $skills[6], $skills[7], $heroIndex)
EndFunc


;~ Load attributes from a two dimensional array.
Func LoadAttributes($attributesArray, $secondaryProfession, $heroIndex = 0)
	Local $heroID = GetHeroID($heroIndex)
	Local $primaryAttribute
	Local $deadlock
	Local $level

	$primaryAttribute = GetProfPrimaryAttribute(GetHeroProfession($heroIndex))

	; fix for problem when build template doesn't have second profession, but attribute points of current player/hero profession still need to be cleared
	; in case of player it's possible to extract secondary profession property from agent struct because player exists in outposts contrary to heroes
	; in case of heroes it isn't possible to extract secondary profession from agent struct of hero in outpost because hero agents don't exist in outposts, only in explorables
	; therefore doing a workaround for heroes that when build template doesn't have second profession then hero second profession is changed to Monk, which clears attribute points of second profession, regardless if it was Monk or not
	If $secondaryProfession == 0 Or $secondaryProfession == Null Then
		If $heroIndex == 0 Then
			$secondaryProfession = DllStructGetData(GetMyAgent(), 'Secondary')
		Else
			ChangeSecondProfession($ID_MONK, $heroIndex)
			$secondaryProfession = $ID_MONK
		EndIf
	EndIf

	$deadlock = TimerInit()
	; Setting up secondary profession
	If GetHeroProfession($heroIndex) <> $secondaryProfession Then
		While GetHeroProfession($heroIndex, True) <> $secondaryProfession And TimerDiff($deadlock) < 8000
			ChangeSecondProfession($attributesArray[0][0], $heroIndex)
			Sleep(GetPing() + 20)
		WEnd
	EndIf

	; Cleaning the attributes array to have only values between 0 and 12
	For $i = 1 To $attributesArray[0][1]
		If $attributesArray[$i][1] > 12 Then $attributesArray[$i][1] = 12
		If $attributesArray[$i][1] < 0 Then $attributesArray[$i][1] = 0
	Next

	; Only way to do this is to set all attributes to 0 and then increasing them as many times as needed
	EmptyAttributes($secondaryProfession, $heroIndex)

	; Now that all attributes are at 0, we increase them by the times needed
	; Using GetAttributeByID during the increase is a bad idea because it counts points from runes too
	For $i = 1 To $attributesArray[0][1]
		For $j = 1 To $attributesArray[$i][1]
			IncreaseAttribute($attributesArray[$i][0], $heroIndex)
			Sleep(GetPing() + 50)
		Next
	Next
	Sleep(GetPing() + 50)

	; If there are any points left, we put them in the primary attribute
	For $i = 0 To 11
		IncreaseAttribute($primaryAttribute, $heroIndex)
		Sleep(GetPing() + 50)
	Next
EndFunc


;~ Set all attributes of the character/hero to 0
Func EmptyAttributes($secondaryProfession, $heroIndex = 0)
	For $attribute In $ATTRIBUTES_BY_PROFESSION_MAP[GetHeroProfession($heroIndex)]
		For $i = 0 To 11
			DecreaseAttribute($attribute, $heroIndex)
			Sleep(GetPing() + 10)
		Next
	Next

	For $attribute In $ATTRIBUTES_BY_PROFESSION_MAP[$secondaryProfession]
		For $i = 0 To 11
			DecreaseAttribute($attribute, $heroIndex)
			Sleep(GetPing() + 10)
		Next
	Next
EndFunc
#EndRegion Skill and Templates


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