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
; limitations under the License.d

#include-once

#include <array.au3>
#include <WinAPIDiag.au3>
#include 'GWA2_Headers.au3'
#include 'GWA2_ID.au3'
#include 'GWA2.au3'
#include 'Utils-Debugger.au3'

Opt('MustDeclareVars', 1)

; Mobs aggro correspond to earshot range
Global Const $RANGE_ADJACENT=156, $RANGE_NEARBY=240, $RANGE_AREA=312, $RANGE_EARSHOT=1000, $RANGE_SPELLCAST = 1085, $RANGE_SPIRIT = 2500, $RANGE_COMPASS = 5000
Global Const $RANGE_ADJACENT_2=156^2, $RANGE_NEARBY_2=240^2, $RANGE_AREA_2=312^2, $RANGE_EARSHOT_2=1000^2, $RANGE_SPELLCAST_2=1085^2, $RANGE_SPIRIT_2=2500^2, $RANGE_COMPASS_2=5000^2

Global Const $SpiritTypes_Array[3] = [278528, 311296]
Global Const $Map_SpiritTypes = MapFromArray($SpiritTypes_Array)

; Map containing the IDs of the opened chests - this map should be cleared at every loop
; Null - chest not found yet (sic)
; 0 - chest found but not flagged and not opened
; 1 - chest found and flagged
; 2 - chest found and opened
Global $chestsMap[]

;~ Main method from utils, used only to run tests
Func RunTests($STATUS)
	;SellEverythingToMerchant(DefaultShouldSellItem, True)
	;While($STATUS == 'RUNNING')
	;	GetOwnLocation()
	;	Sleep(2000)
	;WEnd

	;Local $itemPtr = GetItemPtrBySlot(1, 1)
	;Local $itemID = DllStructGetData($item, 'ID')

	;Local $target = GetNearestEnemyToAgent(GetMyAgent())
	;Local $target = GetCurrentTarget()
	;PrintNPCInformations($target)
	;_dlldisplay($target)
	;Info(GetEnergy())
	;Info(GetSkillTimer())
	;Info(DllStructGetData(GetEffect($ID_Shroud_of_Distress), 'TimeStamp'))
	;Info(GetEffectTimeRemaining(GetEffect($ID_Shroud_of_Distress)))
	;Info(_dlldisplay(GetEffect($ID_Shroud_of_Distress)))
	;RndSleep(1000)

	;Return 0
	Return 2
EndFunc


;~ Allows the user to run functions by hand
Func DynamicExecution($args)
	Local $arguments = ParseFunctionArguments($args)
	Switch $arguments[0]
		Case 0
			Error('Call to nothing ?!')
			Return
		Case 1
			Info('Call to ' & $arguments[1])
			Call($arguments[1])
		Case 2
			Info('Call to ' & $arguments[1] & ' ' & $arguments[2])
			Call($arguments[1], $arguments[2])
		Case 3
			Info('Call to ' & $arguments[1] & ' ' & $arguments[2] & ' ' & $arguments[3])
			Call($arguments[1], $arguments[2], $arguments[3])
		Case 4
			Info('Call to ' & $arguments[1] & ' ' & $arguments[2] & ' ' & $arguments[3] & ' ' & $arguments[4])
			Call($arguments[1], $arguments[2], $arguments[3], $arguments[4])
		Case Else
			MsgBox(0, 'Error', 'Too many arguments provided to that function.')
	EndSwitch
EndFunc


;~ Find out the function name and the arguments in a call fun(arg1, arg2, [...])
Func ParseFunctionArguments($functionCall)
	Local $openParenthesisPosition = StringInStr($functionCall, '(')
	Local $functionName = StringLeft($functionCall, $openParenthesisPosition - 1)

	Local $arguments[2] = [1, $functionName]
	Info($functionName)
	Local $commaPosition = $openParenthesisPosition + 1
	Local $temp = StringInStr($functionCall, ',', 0, 1, $commaPosition)
	While $temp <> 0
		_ArrayAdd($arguments, StringMid($functionCall, $commaPosition, $temp - $commaPosition))
		Info(StringMid($functionCall, $commaPosition, $temp - $commaPosition))
		$commaPosition = $temp + 1
		$temp = StringInStr($functionCall, ',', 0, 1, $commaPosition)
	WEnd
	_ArrayAdd($arguments, StringMid($functionCall, $commaPosition, StringLen($functionCall) - $commaPosition))
	Info(StringMid($functionCall, $commaPosition, StringLen($functionCall) - $commaPosition))
	$arguments[0] = Ubound($arguments) - 1
	Return $arguments
EndFunc


#Region Map and travel
;~ Get your own location
Func GetOwnLocation()
	Local $me = GetMyAgent()
	Info('(' & DllStructGetData($me, 'X') & ',' & DllStructGetData($me, 'Y') & ')')
EndFunc


;~ Travel to specified map and specified district
Func DistrictTravel($mapID, $district)
	If $district == 'Random' Then
		RandomDistrictTravel($mapID)
	Else
		Local $districtAndRegion = $RegionMap[$district]
		MoveMap($mapID, $districtAndRegion[1], 0, $districtAndRegion[0])
		WaitMapLoading($mapID, 20000)
		RndSleep(2000)
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
	RndSleep(2000)
EndFunc
#EndRegion Map and travel


#Region Loot items
;~ Loot items around character
Func PickUpItems($defendFunction = null, $ShouldPickItem = DefaultShouldPickItem, $range = $RANGE_COMPASS)
	If (GUICtrlRead($GUI_Checkbox_LootNothing) == $GUI_CHECKED) Then Return

	Local $item
	Local $agentID
	Local $deadlock
	Local $agents = GetAgentArray(0x400)
	For $i = $agents[0] To 1 Step -1
		Local $agent = $agents[$i]
		If GetIsDead() Then Return
		If Not GetCanPickUp($agent) Then ContinueLoop
		If GetDistance(GetMyAgent(), $agent) > $range Then ContinueLoop

		$agentID = DllStructGetData($agent, 'ID')
		$item = GetItemByAgentID($agentID)

		If ($ShouldPickItem($item)) Then
			If $defendFunction <> null Then $defendFunction()
			If Not GetAgentExists($agentID) Then ContinueLoop
			PickUpItem($item)
			$deadlock = TimerInit()
			While GetAgentExists($agentID) And TimerDiff($deadlock) < 10000
				RndSleep(50)
				If GetIsDead() Then Return
			WEnd
		EndIf
	Next

	If $BAG_NUMBER == 5 And CountSlots(1, 3) == 0 Then
		MoveItemsToEquipmentBag()
	EndIf
EndFunc


;~ Return True if the item should be picked up
;~ Most general implementation, pick most of the important stuff and is heavily configurable from GUI
Func DefaultShouldPickItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	; Only pick gold if character has less than 99k in inventory
	If (($itemID == $ID_Money) And (GetGoldCharacter() < 99000)) Then
		Return True
	ElseIf IsBasicMaterial($item) Then
		Return GUICtrlRead($GUI_Checkbox_LootBasicMaterials) == $GUI_CHECKED
	ElseIf IsRareMaterial($item) Then
		Return GUICtrlRead($GUI_Checkbox_LootRareMaterials) == $GUI_CHECKED
	ElseIf IsTome($itemID) Then
		Return GUICtrlRead($GUI_Checkbox_LootTomes) == $GUI_CHECKED
	ElseIf IsGoldScroll($itemID) Then
		Return GUICtrlRead($GUI_Checkbox_LootScrolls) == $GUI_CHECKED
	ElseIf IsBlueScroll($itemID) Then
		Return GUICtrlRead($GUI_Checkbox_LootScrolls) == $GUI_CHECKED
	ElseIf IsKey($itemID) Then
		Return GUICtrlRead($GUI_Checkbox_LootKeys) == $GUI_CHECKED
	ElseIf ($itemID == $ID_Dyes) Then
		Local $dyeColor = DllStructGetData($item, 'DyeColor')
		Return (($dyeColor == $ID_Black_Dye) Or ($dyeColor == $ID_White_Dye) Or (GUICtrlRead($GUI_Checkbox_LootDyes) == $GUI_CHECKED))
	ElseIf ($itemID == $ID_Glacial_Stone) Then
		Return GUICtrlRead($GUI_Checkbox_LootGlacialStones) == $GUI_CHECKED
	ElseIf ($itemID == $ID_Jade_Bracelet) Then
		Return True
	ElseIf ($itemID == $ID_Stolen_Goods) Then
		Return True
	ElseIf ($itemID == $ID_Ministerial_Commendation) Then
		Return True
	ElseIf ($itemID == $ID_Jar_of_Invigoration) Then
		Return False
	ElseIf IsMapPiece($itemID) Then
		Return GUICtrlRead($GUI_Checkbox_LootMapPieces) == $GUI_CHECKED
	ElseIf IsStackable($item) Then
		Return True
	ElseIf ($itemID == $ID_Lockpick) Then
		Return True
	ElseIf $rarity <> $RARITY_White And IsWeapon($item) And IsLowReqMaxDamage($item) Then
		Return True
	ElseIf $rarity <> $RARITY_White And isArmorSalvageItem($item) Then
		Return True
	; Temporary addition to find glacial blades
	ElseIf $itemID == $ID_Glacial_Blades_Sword Or $itemID == $ID_Glacial_Blades_Dagger Then
		Notice('Glacial Blades Sword or Dagger found')
		Return True
	ElseIf ($rarity == $RARITY_Gold) Then
		Return GUICtrlRead($GUI_Checkbox_LootGoldItems) == $GUI_CHECKED
	ElseIf ($rarity == $RARITY_Green) Then
		Return GUICtrlRead($GUI_Checkbox_LootGreenItems) == $GUI_CHECKED
	ElseIf ($rarity == $RARITY_Purple) Then
		Return GUICtrlRead($GUI_Checkbox_LootPurpleItems) == $GUI_CHECKED
	ElseIf ($rarity == $RARITY_Blue) Then
		Return GUICtrlRead($GUI_Checkbox_LootBlueItems) == $GUI_CHECKED
	ElseIf ($rarity == $RARITY_White) Then
		Return GUICtrlRead($GUI_Checkbox_LootWhiteItems) == $GUI_CHECKED
	EndIf
	Return False
EndFunc


;~ Return True if the item should be picked up
;~ Only pick rare materials, black and white dyes, lockpicks, gold items and green items
Func PickOnlyImportantItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $dyeColor = DllStructGetData($item, 'DyeColor')
	Local $rarity = GetRarity($item)
	; Only pick gold if character has less than 99k in inventory
	If IsRareMaterial($item) Then
		Return True
	ElseIf ($itemID == $ID_Dyes) Then
		Return (($dyeColor == $ID_Black_Dye) Or ($dyeColor == $ID_White_Dye))
	ElseIf ($itemID == $ID_Lockpick) Then
		Return True
	ElseIf $rarity <> $RARITY_White And IsWeapon($item) And IsLowReqMaxDamage($item) Then
		Return True
	ElseIf ($rarity == $RARITY_Gold) Then
		Return True
	ElseIf ($rarity == $RARITY_Green) Then
		Return True
	EndIf
	Return False
EndFunc
#EndRegion Loot items


#Region Loot Chests
;~ Find and open chests in the given range (earshot by default)
Func CheckForChests($range = $RANGE_EARSHOT, $DefendFunction = null, $BlockedFunction = null)
	If GetIsDead() Then Return

	Local $gadgetID
	Local $agents = GetAgentArray(0x200)	;0x200 = type: static
	Local $openedChest = False
	For $i = 1 To $agents[0]
		$gadgetID = DllStructGetData($agents[$i], 'GadgetID')
		If $Map_Chests_IDs[$gadgetID] == null Then ContinueLoop
		If GetDistance(GetMyAgent(), $agents[$i]) > $range Then ContinueLoop

		If $chestsMap[DllStructGetData($agents[$i], 'ID')] <> 2 Then
			;MoveTo(DllStructGetData($agents[$i], 'X'), DllStructGetData($agents[$i], 'Y'))		;Fail half the time
			;GoSignpost($agents[$i])															;Seems to work but serious rubberbanding
			;GoToSignpost($agents[$i])															;Much better solution BUT character doesn't defend itself while going to chest + function kind of sucks
			GoToSignpostWhileDefending($agents[$i], $DefendFunction, $BlockedFunction)			;Final solution
			If GetIsDead() Then Return
			RndSleep(200)
			OpenChest()
			If GetIsDead() Then Return
			RndSleep(GetPing() + 1000)
			If GetIsDead() Then Return
			$chestsMap[DllStructGetData($agents[$i], 'ID')] = 2
			PickUpItems()
			$openedChest = True
		EndIf
	Next
	Return $openedChest
EndFunc


;~ Count amount of chests opened
Func CountOpenedChests()
	Local $chestsOpened = 0
	Local $keys = MapKeys($chestsMap)
	For $key In $keys
		$chestsOpened += $chestsMap[$key] == 2 ? 1 : 0
	Next
	Return $chestsOpened
EndFunc

;~ Clearing map of chests
Func ClearChestsMap()
	; Redefining the variable clears it for maps
	Global $chestsMap[]
EndFunc


;~ Go to signpost and waits until you reach it.
Func GoToSignpostWhileDefending($agent, $DefendFunction = Null, $BlockedFunction = Null)
	Local $me = GetMyAgent()
	Local $X = DllStructGetData($agent, 'X')
	Local $Y = DllStructGetData($agent, 'Y')
	Local $blocked = 0
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $X, $Y) > 250 And $blocked < 15
		Move($X, $Y, 100)
		RndSleep(100)
		If $DefendFunction <> Null Then $DefendFunction()
		$me = GetMyAgent()
		If DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0 Then
			If $BlockedFunction <> Null And $blocked > 10 Then
				$BlockedFunction()
			EndIf
			$blocked += 1
			Move($X, $Y, 100)
		EndIf
		GoSignpost($agent)
		RndSleep(100)
		$me = GetMyAgent()
	WEnd
EndFunc
#EndRegion Loot Chests


#Region Inventory or Chest
;~ Find all empty slots in the given bag
Func FindEmptySlots($bagId)
	Local $bag = GetBag($bagId)
	Local $emptySlots[0] = []
	Local $item
	For $slot = 1 To DllStructGetData($bag, 'Slots')
		$item = GetItemBySlot($bagId, $slot)
		If DllStructGetData($item, 'ID') == 0 Then
			_ArrayAdd($emptySlots, $bagId)
			_ArrayAdd($emptySlots, $slot)
		EndIf
	Next
	Return $emptySlots
EndFunc


;~ Find first empty slot in chest
Func FindChestFirstEmptySlot()
	Return FindFirstEmptySlot(8, 21)
EndFunc


;~ Find first empty slot in bags from firstBag to lastBag
Func FindFirstEmptySlot($firstBag, $lastBag)
	Local $bagEmptySlot[2] = [0, 0]
	For $i = $firstBag To $lastBag
		$bagEmptySlot[1] = FindEmptySlot($i)
		If $bagEmptySlot[1] <> 0 Then
			$bagEmptySlot[0] = $i
			Return $bagEmptySlot
		EndIf
	Next
	Return $bagEmptySlot
EndFunc


;~ Find the first empty slot in the given bag
Func FindEmptySlot($bag)
	Local $item
	For $slot = 1 To DllStructGetData(GetBag($bag), 'Slots')
		$item = GetItemBySlot($bag, $slot)
		If DllStructGetData($item, 'ID') = 0 Then Return $slot
	Next
	Return 0
EndFunc


;~ Find all empty slots in inventory
Func FindInventoryEmptySlots()
	Return FindAllEmptySlots(1, $BAG_NUMBER)
EndFunc


;~ Find all empty slots in chest
Func FindChestEmptySlots()
	Return FindAllEmptySlots(8, 21)
EndFunc


;~ Find all empty slots in the given bags
Func FindAllEmptySlots($firstBag, $lastBag)
	Local $emptySlots[0] = []
	For $i = $firstBag To $lastBag
		Local $bagEmptySlots[] = FindEmptySlots($i)
		If UBound($bagEmptySlots) > 0 Then _ArrayAdd($emptySlots, $bagEmptySlots)
	Next
	Return $emptySlots
EndFunc


;~ Count available slots in the inventory
Func CountSlots($fromBag = 1, $toBag = $BAG_NUMBER)
	Local $bag
	Local $availableSlots = 0
	; If bag is missing it just won't count
	For $i = $fromBag To $toBag
		$bag = GetBag($i)
		$availableSlots += DllStructGetData($bag, 'Slots') - DllStructGetData($bag, 'ItemsCount')
	Next
	Return $availableSlots
EndFunc


;~ Counts open slots in the Xunlai storage chest
Func CountSlotsChest()
	Local $chestTab
	Local $availableSlots = 0
	For $i = 8 To 21
		$chestTab = GetBag($i)
		$availableSlots += 25 - DllStructGetData($chestTab, 'ItemsCount')
	Next
	Return $availableSlots
EndFunc


;~ Move items to the equipment bag
Func MoveItemsToEquipmentBag()
	If $BAG_NUMBER < 5 Then Return
	Local $equipmentBagEmptySlots = FindEmptySlots(5)
	Local $countEmptySlots = UBound($equipmentBagEmptySlots) / 2
	If $countEmptySlots < 1 Then
		Debug('No space in equipment bag to move the items to')
		Return
	EndIf

	Local $cursor = 1
	For $bagId = 4 To 1 Step -1
		For $slot = 1 To DllStructGetData(GetBag($bagId), 'slots')
			Local $item = GetItemBySlot($bagId, $slot)
			If DllStructGetData($item, 'ID') <> 0 And (isArmor($item) Or IsWeapon($item)) Then
				If $countEmptySlots < 1 Then
					Debug('No space in equipment bag to move the items to')
					Return
				EndIf
				MoveItem($item, 5, $equipmentBagEmptySlots[$cursor])
				$cursor += 2
				$countEmptySlots -= 1
				RndSleep(50)
			EndIf
		Next
	Next
EndFunc


;~ Sort the inventory in this order :
Func SortInventory()
	Info('Sorting inventory')
	;						0-Lockpicks 1-Books	2-Consumables	3-Trophies	4-Tomes	5-Materials	6-Others	7-Armor Salvageables[Gold,	8-Purple,	9-Blue	10-White]	11-Weapons [White,	12-Blue,	13-Purple,	14-Gold,	15-Green]	16-Armor (Armor salvageables, weapons and armor start from the end)
	Local $itemsCounts = [	0,			0,		0,				0,			0,		0,			0,			0,							0,			0,		0,			0,					0,			0,			0,			0,			0]
	Local $bagsSizes[6]
	Local $bagsSize = 0
	Local $bag, $item, $itemID, $rarity
	Local $items[80]
	Local $k = 0
	For $bagIndex = 1 To $BAG_NUMBER
		$bag = GetBag($bagIndex)
		$bagsSizes[$bagIndex] = DllStructGetData($bag, 'slots')
		$bagsSize += $bagsSizes[$bagIndex]
		For $slot = 1 To $bagsSizes[$bagIndex]
			$item = GetItemBySlot($bagIndex, $slot)
			$itemID = DllStructGetData(($item), 'ModelID')

			If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
			$items[$k] = $item
			$k += 1
			; Weapon
			If IsWeapon($item) Then
				$rarity = GetRarity($item)
				If ($rarity == $RARITY_Gold) Then
					$itemsCounts[14] += 1
				ElseIf ($rarity == $RARITY_Purple) Then
					$itemsCounts[13] += 1
				ElseIf ($rarity == $RARITY_Blue) Then
					$itemsCounts[12] += 1
				ElseIf ($rarity == $RARITY_Green) Then
					$itemsCounts[15] += 1
				ElseIf ($rarity == $RARITY_White) Then
					$itemsCounts[11] += 1
				EndIf
			; ArmorSalvage
			ElseIf IsArmorSalvageItem($item) Then
				$rarity = GetRarity($item)
				If ($rarity == $RARITY_Gold) Then
					$itemsCounts[7] += 1
				ElseIf ($rarity == $RARITY_Purple) Then
					$itemsCounts[8] += 1
				ElseIf ($rarity == $RARITY_Blue) Then
					$itemsCounts[9] += 1
				ElseIf ($rarity == $RARITY_White) Then
					$itemsCounts[10] += 1
				EndIf
			; Trophies
			ElseIf IsTrophy($itemID) Then
				$itemsCounts[3] += 1
			; Consumables
			ElseIf IsConsumable($itemID) Then
				$itemsCounts[2] += 1
			; Materials
			ElseIf IsMaterial($item) Then
				$itemsCounts[5] += 1
			; Lockpick
			ElseIf ($itemID == $ID_Lockpick) Then
				$itemsCounts[0] += 1
			; Tomes
			ElseIf IsTome($itemID) Then
				$itemsCounts[4] += 1
			; Armor
			ElseIf IsArmor($item) Then
				$itemsCounts[16] += 1
			; Books
			ElseIf IsBook($item) Then
				$itemsCounts[1] += 1
			; Others
			Else
				$itemsCounts[6] += 1
			EndIf
		Next
	Next


	Local $itemsPositions[17]
	$itemsPositions[0] = 1
	$itemsPositions[16] = $bagsSize + 1 - $itemsCounts[16]
	For $i = 1 To 6
		$itemsPositions[$i] = $itemsPositions[$i - 1] + $itemsCounts[$i - 1]
	Next
	For $i = 15 To 7 Step -1
		$itemsPositions[$i] = $itemsPositions[$i + 1] - $itemsCounts[$i]
	Next


	Local $bagAndSlot
	Local $category
	For $item In $items
		$itemID = DllStructGetData($item, 'ModelID')
		If $itemID == 0 Then ExitLoop
		RndSleep(10)

		; Weapon
		If IsWeapon($item) Then
			$rarity = GetRarity($item)
			If ($rarity == $RARITY_Gold) Then
				$category = 14
			ElseIf ($rarity == $RARITY_Purple) Then
				$category = 13
			ElseIf ($rarity == $RARITY_Blue) Then
				$category = 12
			ElseIf ($rarity == $RARITY_Green) Then
				$category = 15
			ElseIf ($rarity == $RARITY_White) Then
				$category = 11
			EndIf
		; ArmorSalvage
		ElseIf isArmorSalvageItem($item) Then
			$rarity = GetRarity($item)
			If ($rarity == $RARITY_Gold) Then
				$category = 7
			ElseIf ($rarity == $RARITY_Purple) Then
				$category = 8
			ElseIf ($rarity == $RARITY_Blue) Then
				$category = 9
			ElseIf ($rarity == $RARITY_White) Then
				$category = 10
			EndIf
		; Trophies
		ElseIf IsTrophy($itemID) Then
			$category = 3
		; Consumables
		ElseIf IsConsumable($itemID) Then
			$category = 2
		; Materials
		ElseIf IsMaterial($item) Then
			$category = 5
		; Lockpick
		ElseIf ($itemID == $ID_Lockpick) Then
			$category = 0
		; Tomes
		ElseIf IsTome($itemID) Then
			$category = 4
		; Armor
		ElseIf IsArmor($item) Then
			$category = 16
		; Books
		ElseIf IsBook($item) Then
			$category = 1
		; Others
		Else
			$category = 6
		EndIf

		$bagAndSlot = GetBagAndSlotFromGeneralSlot($bagsSizes, $itemsPositions[$category])
		Debug('Moving item ' & DllStructGetData($item, 'ModelID') & ' to bag ' & $bagAndSlot[0] & ', position ' & $bagAndSlot[1])
		MoveItem($item, $bagAndSlot[0], $bagAndSlot[1])
		$itemsPositions[$category] += 1
		RndSleep(50)
	Next
EndFunc


;~ Turns the bag index and the slot index into a general index
Func GetGeneralSlot($bagsSizes, $bag, $slot)
	Local $generalSlot = $slot
	For $i = 1 To $bag - 1
		$generalSlot += $bagsSizes[$i]
	Next
	Return $generalSlot
EndFunc


;~ Turns a general index into the bag index and the slot index
Func GetBagAndSlotFromGeneralSlot($bagsSizes, $generalSlot)
	Local $bagAndSlot[2]
	Local $i = 1
	For $i = 1 To 4
		If $generalSlot <= $bagsSizes[$i] Then
			$bagAndSlot[0] = $i
			$bagAndSlot[1] = $generalSlot
			Return $bagAndSlot
		Else
			$generalSlot -= $bagsSizes[$i]
		EndIf
	Next
	$bagAndSlot[0] = $i
	$bagAndSlot[1] = $generalSlot
	Return $bagAndSlot
EndFunc


;~ Helper function for sorting function - allows moving an item via a generic position instead of with both bag and position
Func GenericMoveItem($bagsSizes, $item, $genericSlot)
	Local $i = 1
	For $i = 1 To 4
		If $genericSlot <= $bagsSizes[$i] Then
			Debug('to bag ' & $i & ' position ' & $genericSlot)
			;MoveItem($item, $i, $genericSlot)
			Return
		Else
			$genericSlot -= $bagsSizes[$i]
		EndIf
	Next
	Debug('to bag ' & $i & ' position ' & $genericSlot)
	;MoveItem($item, $i, $genericSlot)
EndFunc


;~ Balance character gold to the amount given
Func BalanceCharacterGold($goldAmount)
	Info('Balancing characters gold')
	Local $GCharacter = GetGoldCharacter()
	Local $GStorage = GetGoldStorage()
	If $GStorage > 950000 Then
		Warn('Too much gold in chest, use some.')
	ElseIf $GStorage < 50000 Then
		Warn('Not enough gold in chest, get some.')
	ElseIf $GCharacter > $goldAmount Then
		DepositGold($GCharacter - $goldAmount)
	ElseIf $GCharacter < $goldAmount Then
		WithdrawGold($goldAmount - $GCharacter)
	EndIf
	Return True
EndFunc
#EndRegion Inventory or Chest


#Region Count and find items
;~ Counts black dyes in inventory
Func GetBlackDyeCount()
	Return GetInventoryItemCount($ID_Black_Dye)
EndFunc


;~ Counts birthday cupcakes in inventory
Func GetBirthdayCupcakeCount()
	Return GetInventoryItemCount($ID_Birthday_Cupcake)
EndFunc


;~ Counts gold items in inventory
Func CountGoldItems()
	Local $goldItemsCount = 0
	Local $item
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			If ((IsWeapon($item) Or IsArmorSalvageItem($item)) And GetRarity($item) == $RARITY_Gold) Then $goldItemsCount += 1
		Next
	Next
	Return $goldItemsCount
EndFunc


;~ Look for any of the given items in bags and return bag and slot of an item, [0, 0] if none are present (positions start at 1)
Func FindAnyInInventory(ByRef $itemIDs)
	Local $item
	Local $itemBagAndSlot[2]
	$itemBagAndSlot[0] = $itemBagAndSlot[1] = 0

	For $bag = 1 To $BAG_NUMBER
		Local $bagSize = GetMaxSlots($bag)
		For $slot = 1 To $bagSize
			$item = GetItemBySlot($bag, $slot)
			For $itemId in $itemIDs
				If(DllStructGetData($item, 'ModelID') == $itemID) Then
					$itemBagAndSlot[0] = $bag
					$itemBagAndSlot[1] = $slot
				EndIf
			Next
		Next
	Next
	Return $itemBagAndSlot
EndFunc


;~ Look for an item in inventory
Func FindInInventory($itemID)
	Return FindInStorages(1, $BAG_NUMBER, $itemID)
EndFunc


;~ Look for an item in xunlai storage
Func FindInXunlaiStorage($itemID)
	Return FindInStorages(8, 21, $itemID)
EndFunc


;~ Look for an item in storages from firstBag to lastBag and return bag and slot of the item, [0, 0] else
Func FindInStorages($firstBag, $lastBag, $itemID)
	Local $item
	Local $itemBagAndSlot[2] = [0, 0]

	For $bag = $firstBag To $lastBag
		Local $bagSize = GetMaxSlots($bag)
		For $slot = 1 To $bagSize
			$item = GetItemBySlot($bag, $slot)
			If(DllStructGetData($item, 'ModelID') == $itemID) Then
				$itemBagAndSlot[0] = $bag
				$itemBagAndSlot[1] = $slot
			EndIf
		Next
	Next
	Return $itemBagAndSlot
EndFunc


;~ Look for an item in storages from firstBag to lastBag and return bag and slot of the item, [0, 0] else
Func FindAllInStorages($firstBag, $lastBag, $item)
	Local $itemBagsAndSlots[0] = []
	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $dyeColor = ($itemID == $ID_Dyes) ? DllStructGetData($item, 'DyeColor') : -1
	Local $storageItem

	For $bag = $firstBag To $lastBag
		Local $bagSize = GetMaxSlots($bag)
		For $slot = 1 To $bagSize
			$storageItem = GetItemBySlot($bag, $slot)
			If (DllStructGetData($storageItem, 'ModelID') == $itemID) And ($dyeColor == -1 Or DllStructGetData($storageItem, 'DyeColor') == $dyeColor) Then
				_ArrayAdd($itemBagsAndSlots, $bag)
				_ArrayAdd($itemBagsAndSlots, $slot)
			EndIf
		Next
	Next
	Return $itemBagsAndSlots
EndFunc


;~ Look for an item in inventory
Func FindAllInInventory($item)
	Return FindAllInStorages(1, $BAG_NUMBER, $item)
EndFunc


;~ Look for an item in xunlai storage
Func FindAllInXunlaiStorage($item)
	Return FindAllInStorages(8, 21, $item)
EndFunc


;~ Counts anything in inventory
Func GetInventoryItemCount($itemID)
	Local $amountItem
	Local $bag
	Local $item
	For $i = 1 To $BAG_NUMBER
		$bag = GetBag($i)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $j = 1 To $bagSize
			$item = GetItemBySlot($bag, $j)

			If $Map_Dyes[$itemID] <> null Then
				If (DllStructGetData($item, 'ModelID') == $ID_Dyes) And (DllStructGetData($item, 'DyeColor') == $itemID) Then $amountItem += DllStructGetData($item, 'Quantity')
			Else
				If DllStructGetData($item, 'ModelID') == $itemID Then $amountItem += DllStructGetData($item, 'Quantity')
			EndIf
		Next
	Next
	Return $amountItem
EndFunc


;~ Update the gemstone counters
Func CountTheseItems($itemArray)
	Local $arraySize = UBound($itemArray)
	Local $counts[$arraySize]
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)	
		Local $slots = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $slots
			Local $item = GetItemBySlot($bag, $slot)
			Local $itemID = DllStructGetData($item, 'ModelID')
			For $i = 0 To $arraySize - 1
				If $itemID == $itemArray[$i] Then
					$counts[$i] += DllStructGetData($item, 'Quantity')
					ExitLoop
				EndIf
			Next
		Next
	Next
	Return $counts
EndFunc
#EndRegion Count and find items


#Region Use Items
;~ Team member has too much malus
Func TeamHasTooMuchMalus()
	Local $party = GetParty()
	For $i = 0 To $party[0]
		If GetMorale($i) < 0 Then Return True
	Next
	Return False
EndFunc


;~ Use morale booster on team
Func UseMoraleConsumableIfNeeded()
	While TeamHasTooMuchMalus()
		Local $usedMoraleBooster = False
		For $DPRemoval_Sweet In $DPRemoval_Sweets
			Local $ConsumableSlot = findInInventory($DPRemoval_Sweet)
			If $ConsumableSlot[0] <> 0 Then
				UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
				$usedMoraleBooster = True
			EndIf
		Next
		If Not $usedMoraleBooster Then Return False
	WEnd
	Return True
EndFunc


;~ Use Armor of Salvation, Essence of Celerity and Grail of Might
Func UseConset()
	UseConsumable($ID_Armor_of_Salvation)
	UseConsumable($ID_Essence_of_Celerity)
	UseConsumable($ID_Grail_of_Might)
EndFunc


;~ Uses a consumable from inventory, if present
Func UseCitySpeedBoost($forceUse = False)
	If (Not $forceUse And GUICtrlRead($GUI_Checkbox_UseConsumables) == $GUI_UNCHECKED) Then Return

	If GetEffectTimeRemaining(GetEffect($ID_Sugar_Jolt_2)) > 0 Or GetEffectTimeRemaining(GetEffect($ID_Sugar_Jolt_5)) > 0 Then Return

	Local $ConsumableSlot = findInInventory($ID_Sugary_Blue_Drink)
	If $ConsumableSlot[0] <> 0 Then
		UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
	Else
		$ConsumableSlot = findInInventory($ID_Chocolate_Bunny)
		If $ConsumableSlot[0] <> 0 Then UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
	EndIf
EndFunc


;~ Uses a consumable from inventory, if present
Func UseConsumable($ID_consumable, $forceUse = False)
	If (Not $forceUse And GUICtrlRead($GUI_Checkbox_UseConsumables) == $GUI_UNCHECKED) Then Return
	Local $ConsumableSlot = findInInventory($ID_consumable)
	If $ConsumableSlot[0] <> 0 Then UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
EndFunc


;~ Uses the Item from $bag at position $slot (positions start at 1)
Func UseItemBySlot($bag, $slot)
	If $bag > 0 And $slot > 0 Then
		If Not GetIsDead() And GetInstanceType() <> 2 Then
			Local $item = GetItemBySlot($bag, $slot)
			SendPacket(8, $HEADER_Item_USE, DllStructGetData($item, 'ID'))
		EndIf
	EndIf
EndFunc
#EndRegion Use Items


#Region Identification and Salvage
;~ Get the number of uses of a kit
Func GetKitUsesLeft($kitID)
	Local $kitStruct = GetModStruct($kitID)
	Return Int('0x' & StringMid($kitStruct, 11, 2))
EndFunc


;~ Returns true if there are unidentified items in inventory
Func HasUnidentifiedItems()
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		Local $item
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			If Not GetIsIdentified($item) Then Return True
		Next
	Next
	Return False
EndFunc


;~ Identify all items from inventory
Func IdentifyAllItems()
	Info('Identifying all items')
	For $bagIndex = 1 To $BAG_NUMBER
		Local $bag = GetBag($bagIndex)
		Local $item
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			If Not GetIsIdentified($item) Then
				FindIdentificationKitOrBuySome()
				IdentifyItem($item)
				RndSleep(100)
			EndIf
		Next
	Next
EndFunc


;~ Salvage all items from inventory
Func SalvageAllItems()
	Local $movedItem = Null
	If (CountSlots(1, 4) < 1) Then
		; There is no space in inventory, we need to store something in Xunlai to start the salvage
		Local $xunlaiTemporarySlot = FindChestFirstEmptySlot()
		$movedItem = GetItemBySlot(_Min(4, $BAG_NUMBER), 1)
		MoveItem($movedItem, $xunlaiTemporarySlot[0], $xunlaiTemporarySlot[1])
	EndIf

	Info('Salvaging all items')
	Local $trophiesItems[120]
	Local $trophyIndex = 0
	For $bagIndex = 1 To _Min(4, $BAG_NUMBER)
		Debug('Salvaging bag' & $bagIndex)
		Local $bagSize = DllStructGetData(GetBag($bagIndex), 'slots')
		For $slot = 1 To $bagSize
			Local $item = GetItemBySlot($bagIndex, $slot)
			If IsTrophy(DllStructGetData($item, 'ModelID')) Then
				; Trophies should be salvaged at the end, because they create a lot of materials
				$trophiesItems[$trophyIndex] = $bagIndex
				$trophiesItems[$trophyIndex + 1] = $slot
				$trophyIndex += 2
			Else
				SalvageItemAt($bagIndex, $slot)
			EndIf
		Next
	Next

	If $movedItem <> Null Then
		Local $bagEmptySlot = FindFirstEmptySlot(1, _Min(4, $BAG_NUMBER))
		MoveItem($movedItem, $bagEmptySlot[0], $bagEmptySlot[1])
		SalvageItemAt($bagEmptySlot[0], $bagEmptySlot[1])
	EndIf

	For $i = 0 To $trophyIndex - 2
		SalvageItemAt($trophiesItems[$i], $trophiesItems[$i + 1])
	Next
EndFunc


;~ Salvage an item based on its position in the inventory
Func SalvageItemAt($bag, $slot)
	Local $item = GetItemBySlot($bag, $slot)
	If DllStructGetData($item, 'ID') = 0 Then Return
	If DefaultShouldSalvageItem($item) Then
		SalvageItem($item)
	EndIf
EndFunc


;~ Salvage the given item - FIXME: fails for weapons/armorsalvageable when using expert kits and better because they open a window
Func SalvageItem($item)
	Local $rarity = GetRarity($item)
	Local $salvageKit
	For $i = 1 To DllStructGetData($item, 'Quantity')
		$salvageKit = FindSalvageKitOrBuySome()
		StartSalvageWithKit($item, $salvageKit)
		Sleep(GetPing() + 150)
		If $rarity == $RARITY_gold Or $rarity == $RARITY_purple Then
			ValidateSalvage()
			Sleep(GetPing() + 150)
		EndIf
	Next
EndFunc


;~ Find an identification Kit in inventory or buy one. Return the kit or 0 if no kit was bought
Func FindIdentificationKitOrBuySome()
	Local $IdentificationKit = FindIdentificationKit()
	If $IdentificationKit <> 0 Then Return $IdentificationKit
	If GetGoldCharacter() < 500 And GetGoldStorage() > 499 Then
		WithdrawGold(500)
		RndSleep(500)
	EndIf

	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	Info('Moving to merchant')
	Local $merchant = GetNearestNPCToCoords(-2700, 1075)
	UseCitySpeedBoost()
	GoToNPC($merchant)
	RndSleep(500)

	Local $xunlaiTemporarySlot = 0
	; There is no space in inventory, we need to store something in Xunlai to buy identification kit
	If CountSlots(1, 4) == 0 Then
		Local $xunlaiTemporarySlot = FindChestFirstEmptySlot()
		MoveItem(GetItemBySlot(1, 1), $xunlaiTemporarySlot[0], $xunlaiTemporarySlot[1])
	EndIf

	Local $j = 0
	While $IdentificationKit == 0
		If $j = 3 Then Return 0
		BuySuperiorIdentificationKit()
		$j = $j + 1
		$IdentificationKit = FindIdentificationKit()
	WEnd
	RndSleep(500)
	If $IdentificationKit <> 0 And $xunlaiTemporarySlot <> 0 Then MoveItem($IdentificationKit, $xunlaiTemporarySlot[0], $xunlaiTemporarySlot[1])
	Return $IdentificationKit
EndFunc


;~ Find a salvage Kit in inventory or buy one. Return the ID of the kit or 0 if no kit was bought
Func FindSalvageKitOrBuySome($basicSalvageKit = True)
	Local $SalvageKit
	If $basicSalvageKit Then
		$SalvageKit = FindBasicSalvageKit()
	Else
		$SalvageKit = FindSalvageKit()
	EndIf
	If $SalvageKit <> 0 Then Return $SalvageKit

	If GetGoldCharacter() < 400 And GetGoldStorage() > 399 Then
		WithdrawGold(400)
		RndSleep(400)
	EndIf

	If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
	Info('Moving to merchant')
	Local $merchant = GetNearestNPCToCoords(-2700, 1075)
	UseCitySpeedBoost()
	GoToNPC($merchant)
	RndSleep(500)

	Local $xunlaiTemporarySlot = 0
	; There is no space in inventory, we need to store something in Xunlai to buy salvage kit
	If CountSlots(1, 4) == 0 Then
		$xunlaiTemporarySlot = FindChestFirstEmptySlot()
		MoveItem(GetItemBySlot(1, 1), $xunlaiTemporarySlot[0], $xunlaiTemporarySlot[1])
	EndIf

	Local $j = 0
	While $SalvageKit == 0
		If $j = 3 Then Return 0
		If $basicSalvageKit Then
			BuySalvageKit()
			$SalvageKit = FindBasicSalvageKit()
		Else
			BuyExpertSalvageKit()
			$SalvageKit = FindSalvageKit()
		EndIf
		$j = $j + 1
	WEnd
	If $SalvageKit <> 0 And $xunlaiTemporarySlot <> 0 Then MoveItem($SalvageKit, $xunlaiTemporarySlot[0], $xunlaiTemporarySlot[1])
	Return $SalvageKit
EndFunc
#EndRegion Identification and Salvage


#Region Items tests
;~ Get the item damage (maximum, not minimum)
Func GetItemMaxDmg($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $modString = GetModStruct($item)
	Local $position = StringInStr($modString, 'A8A7')					; Weapon Damage
	If $position = 0 Then $position = StringInStr($modString, 'C867')	; Energy (focus)
	If $position = 0 Then $position = StringInStr($modString, 'B8A7')	; Armor (shield)
	If $position = 0 Then Return 0
	Return Int('0x' & StringMid($modString, $position - 2, 2))
EndFunc


;~ Return True if the item is a kit or a lockpick - used in Storage Bot to not sell those
Func IsGeneralItem($itemID)
	Return $Map_General_Items[$itemID] <> null
EndFunc


;~ Returns true if the item is an armor salvage
Func IsArmorSalvageItem($item)
	Return DllStructGetData($item, 'type') == $ID_Type_Armor_Salvage
EndFunc


;~ Returns true if the item is a book
Func IsBook($item)
	Return DllStructGetData($item, 'type') == $ID_Type_Book
EndFunc


;~ Returns true if the item is stackable
Func IsStackable($item)
	Return BitAND(DllStructGetData($item, 'Interaction'), 0x80000) <> 0
EndFunc


;~ Returns true if the item is inscribable
Func IsInscribable($item)
	Return BitAND(DllStructGetData($item, 'Interaction'), 0x08000000) <> 0
EndFunc


;~ Returns true if the item is a material, basic or rare
Func IsMaterial($item)
	Return DllStructGetData($item, 'Type') == 11 And $Map_All_Materials[DllStructGetData($item, 'ModelID')] <> null
EndFunc


;~ Returns true if the item is a basic material
Func IsBasicMaterial($item)
	Return DllStructGetData($item, 'Type') == 11 And $Map_Basic_Materials[DllStructGetData($item, 'ModelID')] <> null
EndFunc


;~ Returns true if the item is a rare material
Func IsRareMaterial($item)
	Return DllStructGetData($item, 'Type') == 11 And $Map_Rare_Materials[DllStructGetData($item, 'ModelID')] <> null
EndFunc


;~ Returns true if the item is a consumable
Func IsConsumable($itemID)
	Return IsAlcohol($itemID) Or IsFestive($itemID) Or IsTownSweet($itemID) Or IsPCon($itemID) Or IsDPRemovalSweet($itemID) Or IsSpecialDrop($itemID) Or IsSummoningStone($itemID) Or IsPartyTonic($itemID) Or IsEverlastingTonic($itemID)
EndFunc


;~ Returns true if the item is an alcohol
Func IsAlcohol($itemID)
	Return $Map_Alcohols[$itemID] <> null
EndFunc


;~ Returns true if the item is a festive item
Func IsFestive($itemID)
	Return $Map_Festive[$itemID] <> null
EndFunc


;~ Returns true if the item is a sweet
Func IsTownSweet($itemID)
	Return $Map_Town_Sweets[$itemID] <> null
EndFunc


;~ Returns true if the item is a PCon
Func IsPCon($itemID)
	Return $Map_Sweet_Pcons[$itemID] <> null
EndFunc


;~ Return true if the item is a sweet removing doubl... death penalty
Func IsDPRemovalSweet($itemID)
	Return $Map_DPRemoval_Sweets[$itemID] <> null
EndFunc


;~ Return true if the item is a special drop
Func IsSpecialDrop($itemID)
	Return $Map_Special_Drops[$itemID] <> null
EndFunc


;~ Return true if the item is a summoning stone
Func IsSummoningStone($itemID)
	Return $Map_Summoning_Stones[$itemID] <> null
EndFunc


;~ Return true if the item is a party tonic
Func IsPartyTonic($itemID)
	Return $Map_Party_Tonics[$itemID] <> null
EndFunc


;~ Return true if the item is an everlasting tonic
Func IsEverlastingTonic($itemID)
	Return $Map_EL_Tonics[$itemID] <> null
EndFunc


;~ Return true if the item is a trophy
Func IsTrophy($itemID)
	Return $Map_Trophies[$itemID] <> null Or $Map_Reward_Trophies[$itemID] <> null
EndFunc


;~ Return true if the item is an armor
Func IsArmor($item)
	Return $Map_Armor_Types[DllStructGetData($item, 'type')] <> null
EndFunc


;~ Return true if the item is a weapon
Func IsWeapon($item)
	Return $Map_Weapon_Types[DllStructGetData($item, 'type')] <> null
EndFunc


;~ Return true if the item is a weapon mod
Func IsWeaponMod($itemID)
	Return $Map_Weapon_Mods[$itemID] <> null
EndFunc


;~ Return true if the item is a tome
Func IsTome($itemID)
	Return $Map_Tomes[$itemID] <> null
EndFunc


;~ Return true if the item is a gold scroll
Func IsGoldScroll($itemID)
	Return $Map_Gold_Scrolls[$itemID] <> null
EndFunc


;~ Return true if the item is a blue scroll
Func IsBlueScroll($itemID)
	Return $Map_Blue_Scrolls[$itemID] <> null
EndFunc


;~ Return true if the item is a key
Func IsKey($itemID)
	Return $Map_Keys[$itemID] <> null
EndFunc


;~ Return true if the item is a map piece
Func IsMapPiece($itemID)
	Return $Map_Map_Pieces[$itemID] <> null
EndFunc


;~ Identify is an item is q7-q8 with max damage
Func IsLowReqMaxDamage($item)
	If Not IsWeapon($item) Then Return False
	Local $requirement = GetItemReq($item)
	Return $requirement < 9 And IsMaxDamageForReq($item)
EndFunc


;~ Identify if an item is q0 with max damage
Func IsNoReqMaxDamage($item)
	If Not IsWeapon($item) Then Return False
	Local $requirement = GetItemReq($item)
	Return $requirement == 0 And IsMaxDamageForReq($item)
EndFunc


;~ Identify if an item has max damage for its requirement
Func IsMaxDamageForReq($item)
	If Not IsWeapon($item) Then Return False
	Local $type = DllStructGetData($item, 'Type')
	Local $requirement = GetItemReq($item)
	Local $damage = GetItemMaxDmg($item)
	Local $weaponMaxDamages = $Weapons_Max_Damage_Per_Level[$type]
	Local $maxDamage = $weaponMaxDamages[$requirement]
	If $damage == $maxDamage Then Return True
	Return False
EndFunc
#EndRegion Items tests


#Region Utils
;~ Mapping function
;~ Mapping mode corresponds to : 0 - everything, 1 - only location, 2 - only chests
Func ToggleMapping($mappingMode = 0)
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
		$mappingFile = FileOpen(@ScriptDir & '/logs/mapping.log', $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
		$chestFile = FileOpen(@ScriptDir & '/logs/chests.log', $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
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


;~ Scans for chests and return the first one found around the player or the given coordinates
;~ If flagged is set to true, it will return previously found chests
Func ScanForChests($range, $flagged = False, $X = Null, $Y = Null)
	If $X == Null Then
		Local $me = GetMyAgent()
		$X = DllStructGetData($me, 'X')
		$Y = DllStructGetData($me, 'Y')
	EndIf
	Local $gadgetID
	;0x200 = type: static
	Local $agents = GetAgentArray(0x200)
	For $i = 1 To $agents[0]
		$gadgetID = DllStructGetData($agents[$i], 'GadgetID')
		If $Map_Chests_IDs[$gadgetID] == null Then ContinueLoop
		If ComputeDistance($X, $Y, DllStructGetData($agents[$i], 'X'), DllStructGetData($agents[$i], 'Y')) > $range Then ContinueLoop
		Local $chestID = DllStructGetData($agents[$i], 'ID')
		If $chestsMap[$chestID] == Null Or $chestsMap[$chestID] == 0 Or ($flagged And $chestsMap[$chestID] == 1) Then
			$chestsMap[$chestID] = 1
			Return $agents[$i]
		EndIf
	Next
	Return Null
EndFunc


;~ Return the value if it's not null else the defaultValue
Func GetOrDefault($value, $defaultValue)
	Return ($value == null) ? $defaultValue : $value
EndFunc


;~ Return True if item is present in array, else False
Func ArrayContains($array, $item)
	For $i = 0 To UBound($array) - 1
		If $array[$i] == $item Then Return True
	Next
	Return False
EndFunc


;~ Add to a Map of arrays (create key and new array if unexisting, add to existant array if existing)
Func AppendArrayMap($map, $key, $element)
	If ($map[$key] == null) Then
		Local $newArray[1] = [$element]
		$map[$key] = $newArray
	Else
		_ArrayAdd($map[$key], $element)
	EndIf
	Return $map
EndFunc


;~ Create a map from an array to have a one liner map instanciation
Func MapFromArray($keys)
	Local $map[]
	For $i = 0 To UBound($keys) - 1
		$map[$keys[$i]] = 1
	Next
	Return $map
EndFunc


;~ Create a map from a double array to have a one liner map instanciation with values
Func MapFromDoubleArray($keysAndValues)
	Local $map[]
	For $i = 0 To UBound($keysAndValues) - 1
		$map[$keysAndValues[$i][0]] = $keysAndValues[$i][1]
	Next
	Return $map
EndFunc


;~ Create a map from two arrays to have a one liner map instanciation with values
Func MapFromArrays($keys, $values)
	Local $map[]
	For $i = 0 To UBound($keys) - 1
		Local $val = $values[$i]
		$map[$keys[$i]] = $val
	Next
	Return $map
EndFunc


;~ Find common longest substring in two strings
Func LongestCommonSubstringOfTwo($string1, $string2)
	Local $longestCommonSubstrings[0]
	Local $string1characters = StringSplit($string1, '')
	Local $string2characters = StringSplit($string2, '')

	Local $array[$string1characters[0] + 1][$string2characters[0] + 1]
	Local $LongestCommonSubstringSize = 0

	For $i = 1 To $string1characters[0]
		For $j = 1 To $string2characters[0]
			If ($string1characters[$i] == $string2characters[$j]) Then
				If ($i = 1 OR $j = 1) Then
					$array[$i][$j] = 1
				Else
					$array[$i][$j] = $array[$i-1][$j-1] + 1
				EndIf
				If $array[$i][$j] > $LongestCommonSubstringSize Then
					$LongestCommonSubstringSize = $array[$i][$j]
					Local $longestCommonSubstrings[0]
					_ArrayAdd($longestCommonSubstrings, StringMid($string1, $i - $LongestCommonSubstringSize + 1, $LongestCommonSubstringSize - 1))
				ElseIf $array[$i][$j] = $LongestCommonSubstringSize Then
					_ArrayAdd($longestCommonSubstrings, StringMid($string1, $i - $LongestCommonSubstringSize + 1, $LongestCommonSubstringSize - 1))
				EndIf
			Else
				$array[$i][$j] = 0
			EndIf
		Next
	Next

	Return $longestCommonSubstrings[0]
EndFunc


;~ Find common longest substring in array of strings
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


;~ Return True if find is into every string in the array of strings
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


;~ Return True if the point X, Y is over the line defined by aX + bY + c = 0
Func IsOverLine($coefficientX, $coefficientY, $fixedCoefficient, $posX, $posY)
	Local $position = $posX * $coefficientX + $posY * $coefficientY + $fixedCoefficient
	If $position > 0 Then
		Return True
	EndIf
	Return False
EndFunc


;~ Is agent in range of coordinates
Func IsAgentInRange($agent, $X, $Y, $range)
	If ComputeDistance(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), $X, $Y) < $range Then Return True
	Return False
EndFunc
#EndRegion Utils


#Region NPCs
;~ Print NPC informations
Func PrintNPCInformations($npc)
	Info('ID: ' & DllStructGetData($npc, 'ID'))
	Info('X: ' & DllStructGetData($npc, 'X'))
	Info('Y: ' & DllStructGetData($npc, 'Y'))
	Info('TypeMap: ' & DllStructGetData($npc, 'TypeMap'))
	Info('PlayerNumber: ' & DllStructGetData($npc, 'PlayerNumber'))
	Info('Allegiance: ' & DllStructGetData($npc, 'Allegiance'))
	Info('Effects: ' & DllStructGetData($npc, 'Effects'))
	Info('ModelState: ' & DllStructGetData($npc, 'ModelState'))
	Info('NameProperties: ' & DllStructGetData($npc, 'NameProperties'))
	Info('Type: ' & DllStructGetData($npc, 'Type'))
	Info('ExtraType: ' & DllStructGetData($npc, 'ExtraType'))
	Info('GadgetID: ' & DllStructGetData($npc, 'GadgetID'))
EndFunc


;~ Print Item informations
Func PrintItemInformations($item)
	Info('ID: ' & DllStructGetData($item, 'ID'))
	Info('ModStruct: ' & GetModStruct($item))
	Info('ModStructSize: ' & DllStructGetData($item, 'ModStructSize'))
	Info('ModelFileID: ' & DllStructGetData($item, 'ModelFileID'))
	Info('Type: ' & DllStructGetData($item, 'Type'))
	Info('DyeColor: ' & DllStructGetData($item, 'DyeColor'))
	Info('Value: ' & DllStructGetData($item, 'Value'))
	Info('Interaction: ' & DllStructGetData($item, 'Interaction'))
	Info('ModelId: ' & DllStructGetData($item, 'ModelId'))
	Info('ItemFormula: ' & DllStructGetData($item, 'ItemFormula'))
	Info('IsMaterialSalvageable: ' & DllStructGetData($item, 'IsMaterialSalvageable'))
	Info('Quantity: ' & DllStructGetData($item, 'Quantity'))
	Info('Equipped: ' & DllStructGetData($item, 'Equipped'))
	Info('Profession: ' & DllStructGetData($item, 'Profession'))
	Info('Type2: ' & DllStructGetData($item, 'Type2'))
	Info('Slot: ' & DllStructGetData($item, 'Slot'))
EndFunc


#Region Counting NPCs
;~ Count foes in range of the given agent
Func CountFoesInRangeOfAgent($agent, $range = 0, $condition = null)
	Return CountNPCsInRangeOfAgent($agent, 3, $range, $condition)
EndFunc


;~ Count foes in range of the given coordinates
Func CountFoesInRangeOfCoords($xCoord = null, $yCoord = null, $range = 0, $condition = null)
	Return CountNPCsInRangeOfCoords($xCoord, $yCoord, 3, $range, $condition)
EndFunc


;~ Count allies in range of the given coordinates
Func CountAlliesInRangeOfCoords($xCoord = null, $yCoord = null, $range = 0, $condition = null)
	Return CountNPCsInRangeOfCoords($xCoord, $yCoord, 6, $range, $condition)
EndFunc


;~ Count NPCs in range of the given agent
Func CountNPCsInRangeOfAgent($agent, $npcAllegiance = null, $range = 0, $condition = null)
	Return CountNPCsInRangeOfCoords(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), $npcAllegiance, $range, $condition)
EndFunc
#EndRegion Counting NPCs


#Region Getting NPCs
;~ Returns the coordinates in the middle of a group of foes
Func FindMiddleOfFoes($posX, $posY, $range)
	Local $position[2] = [0, 0]
	Local $nearestFoe = GetNearestEnemyToCoords($posX, $posY)
	Local $foes = GetFoesInRangeOfAgent($nearestFoe, $RANGE_AREA)
	Local $foe
	For $i = 1 To $foes[0]
		$foe = $foes[$i]
		$position[0] += DllStructGetData($foe, 'X')
		$position[1] += DllStructGetData($foe, 'Y')
	Next
	$position[0] = $position[0] / $foes[0]
	$position[1] = $position[1] / $foes[0]
	Return $position
EndFunc


;~ Get foes in range of the given agent
Func GetFoesInRangeOfAgent($agent, $range = 0, $condition = null)
	Return GetNPCsInRangeOfAgent($agent, 3, $range, $condition)
EndFunc


;~ Get foes in range of the given coordinates
Func GetFoesInRangeOfCoords($xCoord = null, $yCoord = null, $range = 0, $condition = null)
	Return GetNPCsInRangeOfCoords($xCoord, $yCoord, 3, $range, $condition)
EndFunc


;~ Get NPCs in range of the given agent
Func GetNPCsInRangeOfAgent($agent, $npcAllegiance = null, $range = 0, $condition = null)
	Return GetNPCsInRangeOfCoords(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), $npcAllegiance, $range, $condition)
EndFunc


;~ Get party in range of the given agent
Func GetPartyInRangeOfAgent($agent, $range = 0)
	Return GetNPCsInRangeOfCoords(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), 1, $range, PartyMemberFilter)
EndFunc


;~ Small helper to filter party members
Func PartyMemberFilter($agent)
	Return BitAND(DllStructGetData($agent, 'TypeMap'), 131072)
EndFunc
#EndRegion Getting NPCs


;~ Count NPCs in range of the given coordinates
Func CountNPCsInRangeOfCoords($coordX = null, $coordY = null, $npcAllegiance = null, $range = 0, $condition = null)
	;Return GetNPCsInRangeOfCoords($coordX, $coordY, $npcAllegiance, $range, $condition)[0]
	Local $agents = GetAgentArray(0xDB)
	Local $curAgent
	Local $count = 0

	For $i = 1 To $agents[0]
		$curAgent = $agents[$i]
		If $npcAllegiance <> null And DllStructGetData($curAgent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($curAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($curAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		If $Map_SpiritTypes[DllStructGetData($curAgent, 'TypeMap')] <> null Then ContinueLoop	;It's a spirit
		If $range > 0 Then
			If $coordX == null Or $coordY == null Then
				Local $me = GetMyAgent()
				$coordX = DllStructGetData($me, 'X')
				$coordY = DllStructGetData($me, 'Y')
			EndIf
			If ComputeDistance($coordX, $coordY, DllStructGetData($curAgent, 'X'), DllStructGetData($curAgent, 'Y')) > $range Then ContinueLoop
		EndIf
		If $condition <> null And $condition($curAgent) == False Then ContinueLoop
		$count += 1
	Next

	Return $count
EndFunc


;~ Get NPCs in range of the given coordinates
Func GetNPCsInRangeOfCoords($coordX = null, $coordY = null, $npcAllegiance = null, $range = 0, $condition = null)
	Local $agents = GetAgentArray(0xDB)
	Local $curAgent
	Local $returnAgents[1] = [0]

	For $i = 1 To $agents[0]
		$curAgent = $agents[$i]
		If $npcAllegiance <> null And DllStructGetData($curAgent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($curAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($curAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		If $Map_SpiritTypes[DllStructGetData($curAgent, 'TypeMap')] <> null Then ContinueLoop	;It's a spirit
		If $range > 0 Then
			If $coordX == null Or $coordY == null Then
				Local $me = GetMyAgent()
				$coordX = DllStructGetData($me, 'X')
				$coordY = DllStructGetData($me, 'Y')
			EndIf
			If ComputeDistance($coordX, $coordY, DllStructGetData($curAgent, 'X'), DllStructGetData($curAgent, 'Y')) > $range Then ContinueLoop
		EndIf
		If $condition <> null And $condition($curAgent) == False Then ContinueLoop

		_ArrayAdd($returnAgents, $curAgent)
		$returnAgents[0] += 1
	Next
	Return $returnAgents
EndFunc


;~ Get NPCs in range of the given coordinates
Func GetNearestNPCInRangeOfCoords($coordX = null, $coordY = null, $npcAllegiance = null, $range = 0, $condition = null)
	Local $me = GetMyAgent()
	Local $agents = GetAgentArray(0xDB)
	Local $smallestDistance = 99999
	Local $returnAgent
	Local $curAgent

	If $coordX == null Or $coordY == null Then
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $i = 1 To $agents[0]
		$curAgent = $agents[$i]
		If $npcAllegiance <> null And DllStructGetData($curAgent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($curAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($curAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		If $Map_SpiritTypes[DllStructGetData($curAgent, 'TypeMap')] <> null Then ContinueLoop	;It's a spirit
		If $condition <> null And $condition($curAgent) == False Then ContinueLoop
		If $range > 0 And ComputeDistance($coordX, $coordY, DllStructGetData($curAgent, 'X'), DllStructGetData($curAgent, 'Y')) > $range Then ContinueLoop
		Local $curDistance = GetDistance($me, $curAgent)
		If $curDistance < $smallestDistance Then
			$returnAgent = $curAgent
			$smallestDistance = $curDistance
		EndIf
	Next

	Return $returnAgent
EndFunc


;~ Get NPCs in range of the given coordinates
Func GetFurthestNPCInRangeOfCoords($npcAllegiance = null, $coordX = null, $coordY = null, $range = 0, $condition = null)
	Local $me = GetMyAgent()
	Local $agents = GetAgentArray(0xDB)
	Local $furthestDistance = 0
	Local $returnAgent
	Local $curAgent

	If $coordX == null Or $coordY == null Then
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $i = 1 To $agents[0]
		$curAgent = $agents[$i]
		If $npcAllegiance <> null And DllStructGetData($curAgent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($curAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($curAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		If $Map_SpiritTypes[DllStructGetData($curAgent, 'TypeMap')] <> null Then ContinueLoop	;It's a spirit
		If $condition <> null And $condition($curAgent) == False Then ContinueLoop
		If $range > 0 And ComputeDistance($coordX, $coordY, DllStructGetData($curAgent, 'X'), DllStructGetData($curAgent, 'Y')) > $range Then ContinueLoop
		Local $curDistance = GetDistance($me, $curAgent)
		If $curDistance > $furthestDistance Then
			$returnAgent = $curAgent
			$furthestDistance = $curDistance
		EndIf
	Next

	Return $returnAgent
EndFunc


;~ TODO: check that this method is still better, I improved the original
;~ Get NPCs in range of the given coordinates
Func BetterGetNearestNPCToCoords($npcAllegiance = null, $coordX = null, $coordY = null, $range = 0, $condition = null)
	Local $me = GetMyAgent()
	Local $agents = GetAgentArray(0xDB)
	Local $smallestDistance = 99999
	Local $returnAgent
	Local $curAgent

	If $coordX == null Or $coordY == null Then
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $i = 1 To $agents[0]
		$curAgent = $agents[$i]
		If $npcAllegiance <> null And DllStructGetData($curAgent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($curAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($curAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		If $Map_SpiritTypes[DllStructGetData($curAgent, 'TypeMap')] <> null Then ContinueLoop	;It's a spirit
		If $condition <> null And $condition($curAgent) == False Then ContinueLoop
		Local $curDistance = ComputeDistance(DllStructGetData($curAgent, 'X'), DllStructGetData($curAgent, 'Y'), $coordX, $coordY)
		If $range > 0 And $curDistance > $range Then ContinueLoop
		If $curDistance < $smallestDistance Then
			$returnAgent = $curAgent
			$smallestDistance = $curDistance
		EndIf
	Next

	Return $returnAgent
EndFunc
#EndRegion NPCs


#Region Actions
;~ Move while trying to avoid body block
Func MoveAvoidingBodyBlock($coordX, $coordY, $timeOut)
	Local $timer = TimerInit()
	Local Const $PI = 3.141592653589793
	Local $me = GetMyAgent()
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $coordX, $coordY) > $RANGE_ADJACENT And TimerDiff($timer) < $timeOut
		Move($coordX, $coordY)
		RndSleep(100)
		;Local $blocked = -1
		;Local $angle = 0
		;While Not GetIsDead() And DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0
		;	$blocked += 1
		;	If $blocked > 0 Then
		;		$angle = -1 ^ $blocked * Round($blocked/2) * $PI / 4
		;	EndIf
		;	If $blocked > 5 Then
		;		Return False
		;	EndIf
		;	Move(DllStructGetData($me, 'X') + 150 * sin($angle), DllStructGetData($me, 'Y') + 150 * cos($angle))
		;	RndSleep(50)
		;WEnd
		$me = GetMyAgent()
	WEnd
	Return True
EndFunc

;~ Go to the NPC the closest to given coordinates
Func GoNearestNPCToCoords($x, $y)
	Local $guy = GetNearestNPCToCoords($x, $y)
	Local $me = GetMyAgent()
	While DllStructGetData($guy, 'ID') == 0
		RndSleep(100)
		$guy = GetNearestNPCToCoords($x, $y)
	WEnd
	ChangeTarget($guy)
	RndSleep(250)
	GoNPC($guy)
	RndSleep(250)
	$me = GetMyAgent()
	While ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), DllStructGetData($guy, 'X'), DllStructGetData($guy, 'Y')) > 250
		RndSleep(250)
		Move(DllStructGetData($guy, 'X'), DllStructGetData($guy, 'Y'), 40)
		RndSleep(250)
		GoNPC($guy)
		RndSleep(250)
		$me = GetMyAgent()
	WEnd
	RndSleep(250)
EndFunc


;~ Aggro a foe
Func AggroAgent($tgtAgent)
	While Not GetIsDead() And GetDistance(GetMyAgent(), $tgtAgent) > $RANGE_EARSHOT - 100
		Move(DllStructGetData($tgtAgent, 'X'), DllStructGetData($tgtAgent, 'Y'))
		RndSleep(200)
	WEnd
EndFunc


;~ Get close to a mob without aggroing it
Func GetAlmostInRangeOfAgent($tgtAgent, $proximity = ($RANGE_SPELLCAST + 100))
	Local $me = GetMyAgent()
	Local $xMe = DllStructGetData($me, 'X')
	Local $yMe = DllStructGetData($me, 'Y')
	Local $xTgt = DllStructGetData($tgtAgent, 'X')
	Local $yTgt = DllStructGetData($tgtAgent, 'Y')

	Local $distance = ComputeDistance($xTgt, $yTgt, $xMe, $yMe)
	If ($distance < $RANGE_SPELLCAST) Then Return

	Local $ratio = $proximity / $distance

	Local $xGo = $xMe + ($xTgt - $xMe) * (1 - $ratio)
	Local $yGo = $yMe + ($yTgt - $yMe) * (1 - $ratio)
	MoveTo($xGo, $yGo, 0)
EndFunc


;~ Use one of the skill mentionned if available, else attack
;~ Credits to Shiva for auto-attack improvement
Func AttackOrUseSkill($attackSleep, $skill = null, $skill2 = null, $skill3 = null, $skill4 = null, $skill5 = null, $skill6 = null, $skill7 = null, $skill8 = null)
	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)

	; Start auto-attack first
	Attack($target)
	; Small delay to ensure attack starts
	RndSleep(20)

	If ($skill <> null And IsRecharged($skill)) Then
		UseSkillEx($skill, $target)
		RndSleep(20)
	ElseIf ($skill2 <> null And IsRecharged($skill2)) Then
		UseSkillEx($skill2, $target)
		RndSleep(20)
	ElseIf ($skill3 <> null And IsRecharged($skill3)) Then
		UseSkillEx($skill3, $target)
		RndSleep(20)
	ElseIf ($skill4 <> null And IsRecharged($skill4)) Then
		UseSkillEx($skill4, $target)
		RndSleep(20)
	ElseIf ($skill5 <> null And IsRecharged($skill5)) Then
		UseSkillEx($skill5, $target)
		RndSleep(20)
	ElseIf ($skill6 <> null And IsRecharged($skill6)) Then
		UseSkillEx($skill6, $target)
		RndSleep(20)
	ElseIf ($skill7 <> null And IsRecharged($skill7)) Then
		UseSkillEx($skill7, $target)
		RndSleep(20)
	ElseIf ($skill8 <> null And IsRecharged($skill8)) Then
		UseSkillEx($skill8, $target)
		RndSleep(20)
	Else
		RndSleep($attackSleep)
	EndIf
EndFunc


#Region Map Clearing Utilities
;~ Safer version to not pick items while fighting and not open chests from too far
;~ Usually better in dungeons
Func SafeMoveAggroAndKill($x, $y, $s = '', $range = 1450)
	Return MoveAggroAndKill($x, $y, $s, $range, $range - 100, False)
EndFunc


;~ Clear a zone around the coordinates provided
;~ Credits to Shiva for auto-attack improvement
Func MoveAggroAndKill($x, $y, $s = '', $range = 1450, $chestOpenRange = $RANGE_SPIRIT, $lootInFights = True)
	If Not IsGroupAlive() Then Return True
	If $s <> '' Then Info($s)
	Local $blocked = 0
	Local $me = GetMyAgent()
	Local $coordsX = DllStructGetData($me, 'X')
	Local $coordsY = DllStructGetData($me, 'Y')

	Move($x, $y)

	Local $oldCoordsX
	Local $oldCoordsY
	Local $nearestEnemy
	; GroupIsAlive is caller's responsibility to fill
	While $groupIsAlive And ComputeDistance($coordsX, $coordsY, $x, $y) > $RANGE_NEARBY And $blocked < 10
		$oldCoordsX = $coordsX
		$oldCoordsY = $coordsY
		$me = GetMyAgent()
		$nearestEnemy = GetNearestEnemyToAgent($me)
		If GetDistance($me, $nearestEnemy) < $range And DllStructGetData($nearestEnemy, 'ID') <> 0 Then DefaultKillFoes($lootInFights)
		$coordsX = DllStructGetData($me, 'X')
		$coordsY = DllStructGetData($me, 'Y')
		If $oldCoordsX = $coordsX And $oldCoordsY = $coordsY Then
			$blocked += 1
			Move($coordsX, $coordsY, 500)
			RndSleep(500)
			Move($x, $y)
		EndIf
		RndSleep(500)
		CheckForChests($chestOpenRange)
	WEnd
	Return Not $groupIsAlive
EndFunc


;~ Kill foes by casting skills from 1 to 8
Func DefaultKillFoes($lootInFights = True)
	Local $me = GetMyAgent()
	Local $skillNumber = 1, $foesCount = 999, $target = GetNearestEnemyToAgent($me), $targetId = -1
	GetAlmostInRangeOfAgent($target)
	FanFlagHeroes()

	While $groupIsAlive And $foesCount > 0
		$target = GetNearestEnemyToAgent($me)
		If DllStructGetData($target, 'ID') <> $targetId Then
			$targetId = DllStructGetData($target, 'ID')
			CallTarget($target)
			; Start auto-attack on new target
			Attack($target)
			RndSleep(20)
		EndIf
		; Always ensure auto-attack is active before using skills
		Attack($target)
		RndSleep(20)

		RndSleep(20)
		While Not IsRecharged($skillNumber) And $skillNumber < 9
			$skillNumber += 1
		WEnd
		If $skillNumber < 9 Then
			UseSkillEx($skillNumber, $target)
			RndSleep(20)
		Else
			; Just wait for auto-attack to continue
			RndSleep(1000)
		EndIf
		$skillNumber = 1
		If $lootInFights Then PickUpItems(null, DefaultShouldPickItem, $RANGE_SPELLCAST)
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	WEnd
	CancelAll()
	RndSleep(1000)
	PickUpItems()
EndFunc


;~ Kill foes by casting skills from 1 to 8
Func PriorityKillFoes($lootInFights = True)
	Local $skillNumber = 1, $foesCount = 999, $target = GetNearestEnemyToAgent(GetMyAgent())
	GetAlmostInRangeOfAgent($target)
	ChangeTarget($target)
	; At first we target the closest mob to have the surprise effect
	While $groupIsAlive And $target <> Null
		If GetCurrentTarget() == Null Then
			$target = GetHighestPriorityFoe(GetMyAgent(), $RANGE_SPIRIT)
			ChangeTarget($target)
			Sleep(GetPing() + 20)
			CallTarget($target)
			; Start auto-attack on new target
			Attack($target)
			Sleep(GetPing() + 20)
		EndIf
		If $target <> Null Then
			While Not IsRecharged($skillNumber) And $skillNumber < 9
				$skillNumber += 1
			WEnd
			If $skillNumber < 9 Then
				UseSkillEx($skillNumber, $target)
				RndSleep(20)
			Else
				; Just wait for auto-attack to continue
				RndSleep(1000)
			EndIf
			$skillNumber = 1
		EndIf
		If $lootInFights Then PickUpItems(null, DefaultShouldPickItem, $RANGE_SPELLCAST + 250)
		RndSleep(20)
	WEnd
	RndSleep(1000)
	PickUpItems()
EndFunc


;~ Create a map containing foes and their priority level
Func CreateMobsPriorityMap()
	;Voltaic farm foes
	Local $PN_SS_Defender		= 6499
	Local $PN_SS_Priest			= 6498
	Local $PN_Modniir_Priest	= 6512
	Local $PN_SS_Summoner		= 6507
	Local $PN_SS_Warder			= 6497
	Local $PN_SS_Dominator		= 6493
	Local $PN_SS_Blasphemer		= 6496
	Local $PN_SS_Dreamer		= 6494
	Local $PN_SS_Contaminator	= 6495

	; Priority map : 0 biggest kill priority, and then it's decreasing
	Local $map[]
	$map[$PN_SS_Defender] = 0
	$map[$PN_SS_Priest] = 0
	$map[$PN_Modniir_Priest] = 0
	$map[$PN_SS_Summoner] = 1
	$map[$PN_SS_Warder] = 2
	$map[$PN_SS_Dominator] = 2
	$map[$PN_SS_Blasphemer] = 2
	$map[$PN_SS_Dreamer] = 2
	Return $map
EndFunc


;~ Returns the highest priority foe around an agent
Func GetHighestPriorityFoe($agent, $range = $RANGE_SPELLCAST)
	Local Static $mobsPriorityMap = CreateMobsPriorityMap()
	Local $agentArray = GetAgentArray(0xDB)
	Local $X = DllStructGetData($agent, 'X')
	Local $Y = DllStructGetData($agent, 'Y')
	Local $highestPriorityTarget = Null
	Local $priorityLevel = 99999

	For $i = 1 To $agentArray[0]
		If Not EnemyAgentFilter($agentArray[$i]) Then ContinueLoop
		; This gets all mobs in fight, but also mobs that just used a skill, it's not completely perfect
		If DllStructGetData($agentArray[$i], 'TypeMap') == 0 Then ContinueLoop
		;If DllStructGetData($agentArray[$i], 'ID') == $agentID Then ContinueLoop
		Local $distance = ComputeDistance($X, $y, DllStructGetData($agentArray[$i], 'X'), DllStructGetData($agentArray[$i], 'Y'))
		If $distance < $range Then
			Local $priority = $mobsPriorityMap[DllStructGetData($agentArray[$i], 'PlayerNumber')]
			If ($priority == Null) Then
				If $highestPriorityTarget == Null Then $highestPriorityTarget = $agentArray[$i]
				ContinueLoop
			EndIf
			If ($priority == 0) Then Return $agentArray[$i]
			If ($priority < $priorityLevel) Then
				$highestPriorityTarget = $agentArray[$i]
				$priorityLevel = $priority
			EndIf
		EndIf
	Next
	Return $highestPriorityTarget
EndFunc


;~ Returns True if the group is alive
Func IsGroupAlive()
	Local Static $heroesWithRez = FindHeroesWithRez()
	For $i In $heroesWithRez
		Local $heroID = GetHeroID($i)
		If GetAgentExists($heroID) And Not GetIsDead(GetAgentById($heroID)) Then Return True
	Next
	Return False
EndFunc


;~ Return an array of the player and the members of the group with a rez
Func FindHeroesWithRez()
	Local $heroes[7]
	Local $count = 0
    For $heroNumber = 1 To GetHeroCount()
        Local $heroID = GetHeroID($heroNumber)
        For $skillSlot = 1 To 8
            Local $skill = GetSkillbarSkillID($skillSlot, $heroNumber)
            If IsRezSkill($skill) Then
				$heroes[$count] = $heroNumber
				$count += 1
            EndIf
        Next
    Next
	Local $result[$count + 1]
	$result[0] = 0
	For $i = 1 To $count
		$result[$i] = $heroes[$i - 1]
	Next
	Return $result
EndFunc


;~ Return true if the provided skill is a rez skill - signets excluded
Func IsRezSkill($skill)
	Local $By_Urals_Hammer			= 2217
	Local $Junundu_Wail				= 1865
	;Local $Resurrection_Signet		= 2
	;Local $Sunspear_Rebirth_Signet	= 1816
	Local $Eternal_Aura				= 2109
	Local $We_Shall_Return			= 1592
	Local $Signet_of_Return			= 1778
	Local $Death_Pact_Signet		= 1481
	Local $Flesh_of_My_Flesh		= 791
	Local $Lively_Was_Naomei		= 1222
	Local $Restoration				= 963
	Local $Light_of_Dwayna			= 304
	Local $Rebirth					= 306
	Local $Renew_Life				= 1263
	Local $Restore_Life				= 314
	Local $Resurrect				= 305
	Local $Resurrection_Chant		= 1128
	Local $Unyielding_Aura			= 268
	Local $Vengeance				= 315
    Switch $skill
        Case $By_Urals_Hammer, $Junundu_Wail, _ ;$Resurrection_Signet, $Sunspear_Rebirth_Signet _
			$Eternal_Aura, _
			$We_Shall_Return, $Signet_of_Return, _
			$Death_Pact_Signet, $Flesh_of_My_Flesh, $Lively_Was_Naomei, $Restoration, _
			$Light_of_Dwayna, $Rebirth, $Renew_Life, $Restore_Life, $Resurrect, $Resurrection_Chant, $Unyielding_Aura, $Vengeance
            Return True
    EndSwitch
	Return False
EndFunc


;~ Take current character's position (AND orientation) to flag heroes in a fan position
Func FanFlagHeroes()
	Local $heroCount = GetHeroCount()
	; Change your hero locations here
	Switch $heroCount
		Case 3
			Local $heroFlagPositions[3] = [1, 2, 3]				; right, left, behind
		Case 5
			Local $heroFlagPositions[5] = [1, 2, 3, 4, 5]		; right, left, behind, behind right, behind left
		Case 7
			Local $heroFlagPositions[7] = [1, 2, 6, 3, 4, 5, 7]	; right, left, behind, behind right, behind left, way behind right, way behind left
		Case Else
			Local $heroFlagPositions[0] = []
	EndSwitch

	Local $me = GetMyAgent()
	Local $X = DllStructGetData($me, 'X')
	Local $Y = DllStructGetData($me, 'Y')
	Local $rotationX = DllStructGetData($me, 'RotationCos')
	Local $rotationY = DllStructGetData($me, 'RotationSin')
	Local $distance = $RANGE_AREA + 50
	
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
	Local $splitBuildTemplate = StringSplit($buildTemplate, '')

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
	For $i = 1 To $splitBuildTemplate[0]
		$buildTemplate &= Base64ToBin64($splitBuildTemplate[$i])
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

	$deadlock = TimerInit()
	; Setting up secondary profession
	If GetHeroProfession($heroIndex) <> $secondaryProfession Then
		While GetHeroProfession($heroIndex, True) <> $secondaryProfession And TimerDiff($deadlock) < 8000
			ChangeSecondProfession($attributesArray[0][0], $heroIndex)
			Sleep(50)
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
			Sleep(GetPing() + 100)
		Next
	Next
	Sleep(250)

	; If there are any points left, we put them in the primary attribute
	For $i = 0 To 11
		IncreaseAttribute($primaryAttribute, $heroIndex)
		Sleep(GetPing() + 100)
	Next
EndFunc


;~ Set all attributes of the character/hero to 0
Func EmptyAttributes($secondaryProfession, $heroIndex = 0)
	For $attribute In $AttributesByProfessionMap[GetHeroProfession($heroIndex)]
		For $i = 0 To 11
			DecreaseAttribute($attribute, $heroIndex)
			Sleep(GetPing() + 20)
		Next
	Next

	For $attribute In $AttributesByProfessionMap[$secondaryProfession]
		For $i = 0 To 11
			DecreaseAttribute($attribute, $heroIndex)
			Sleep(GetPing() + 20)
		Next
	Next
EndFunc
#EndRegion Skill and Templates


;~ Function to print a structure in a table - pretty brutal tbh
Func _dlldisplay($struct)
	Local $nextPtr, $currentPtr = DllStructGetPtr($struct, 1)
	Local $offset = 0, $dllSize = DllStructGetSize($struct)
	Local $elementValue, $type, $typeSize, $elementSize, $arrayCount, $aligns

	Local $structArray[1][5] = [['-', $currentPtr, '<struct>', 0, '-']]	; #|Offset|Type|Size|Value'

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
				_ArrayAdd($structArray, $i & '|' & $offset & '|' & $type & '[' & $arrayCount & ']|' & $elementSize & '|' & DllStructGetData($struct, $i))
			; 'uint', 'int', 'ushort', 'short', 'double', 'float', 'ptr'
			Case Else
				If $arrayCount > 1 Then
					_ArrayAdd($structArray, $i & '|' & $offset & '|' & $type & '[' & $arrayCount & ']' & '|' & $elementSize & ' (' & $typeSize & ')|' & (DllStructGetData($struct, $i) ? '[1] ' & $elementValue : '-'))
					; skip empty arrays
					If DllStructGetData($struct, $i) Then
						For $j = 2 To $arrayCount
							_ArrayAdd($structArray, '-|' & $offset + ($typeSize * ($j - 1)) & '|-|-|[' & $j & '] ' & DllStructGetData($struct, $i, $j))
						Next
					EndIf
				Else
					_ArrayAdd($structArray, $i & '|' & $offset & '|' & $type & '|' & $elementSize & '|' & $elementValue)
				EndIf
		EndSwitch
		If $aligns Then _ArrayAdd($structArray, '-|-|<alignment>|' & ($aligns) & '|-')

		; if no next ptr then this was the last/only element
		If Not $nextPtr Then ExitLoop

		; update offset, size and next ptr
		$offset += $elementSize + $aligns
		$dllSize -= $elementSize + $aligns
		$currentPtr = $nextPtr

	Next

	_ArrayAdd($structArray, '-|' & DllStructGetPtr($struct) + DllStructGetSize($struct) & '|<endstruct>|' & DllStructGetSize($struct) & '|-')
	_ArrayToClip($structArray)
	_ArrayDisplay($structArray, '', '', 64, Default, '#|Offset|Type|Size|Value')

	Return $structArray
EndFunc