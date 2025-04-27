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
#include 'GWA2.au3'
#include 'GWA2_ID.au3'

Opt('MustDeclareVars', 1)

; Note: mobs aggro correspond to earshot range
Global Const $RANGE_ADJACENT=156, $RANGE_NEARBY=240, $RANGE_AREA=312, $RANGE_EARSHOT=1000, $RANGE_SPELLCAST = 1085, $RANGE_SPIRIT = 2500, $RANGE_COMPASS = 5000
Global Const $RANGE_ADJACENT_2=156^2, $RANGE_NEARBY_2=240^2, $RANGE_AREA_2=312^2, $RANGE_EARSHOT_2=1000^2, $RANGE_SPELLCAST_2=1085^2, $RANGE_SPIRIT_2=2500^2, $RANGE_COMPASS_2=5000^2

Local Const $SpiritTypes_Array[3] = [278528, 311296]
Global Const $Map_SpiritTypes = MapFromArray($SpiritTypes_Array)


;~ Main method from utils, used only to run tests
Func RunTests($STATUS)
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


Func PrintNPCState($npc)
	Info('ID: ' & DllStructGetData($npc, 'ID'))
	Info('TypeMap: ' & DllStructGetData($npc, 'TypeMap'))
	Info('ModelState: ' & DllStructGetData($npc, 'ModelState'))
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
	Info('X: ' & DllStructGetData($me, 'X') & ', Y: ' & DllStructGetData($me, 'Y'))
EndFunc


;~ Travel to specified map and specified district
Func DistrictTravel($mapID, $district)
	Local $districtAndRegion = $RegionMap[$district]
	MoveMap($mapID, $districtAndRegion[1], 0, $districtAndRegion[0])
	WaitMapLoading($mapID, 20000)
	RndSleep(2000)
EndFunc


;~ Travel to specified map to a random district
;~ 7=eu, 8=eu+int, 11=all(incl. asia)
Func RandomDistrictTravel($mapID, $district = 7)
	Local $Region[11] = [$ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_INTERNATIONAL, $ID_KOREA, $ID_CHINA, $ID_JAPAN]
	Local $Language[11] = [$ID_ENGLISH, $ID_FRENCH, $ID_GERMAN, $ID_ITALIAN, $ID_SPANISH, $ID_POLISH, $ID_RUSSIAN, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH]
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

	If ((DllStructGetData(GetBag(3), 'Slots') - DllStructGetData(GetBag(3), 'ItemsCount')) == 0) Then
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
		Local $itemExtraID = DllStructGetData($item, 'ExtraID')
		Return (($itemExtraID == $ID_Black_Dye) Or ($itemExtraID == $ID_White_Dye) Or (GUICtrlRead($GUI_Checkbox_LootDyes) == $GUI_CHECKED))
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
	ElseIf IsStackableItemButNotMaterial($itemID) Then
		Return True
	ElseIf ($itemID == $ID_Lockpick) Then
		Return True
	ElseIf $rarity <> $RARITY_White And IsWeapon($item) And IsLowReqMaxDamage($item) Then
		Return True
	ElseIf $rarity <> $RARITY_White And isArmorSalvageItem($item) Then
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
;~ Pick everything that is usually picked but also max damage purple and blue
;~ Only useful for OS items since max damage q9 blue/purple inscribable items are worthless
Func AlsoPickMaxPurpleAndBlueItems($item)

EndFunc


;~ Return True if the item should be picked up
;~ Only pick rare materials, black and white dyes, lockpicks, gold items and green items
Func PickOnlyImportantItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $itemExtraID = DllStructGetData($item, 'ExtraID')
	Local $rarity = GetRarity($item)
	; Only pick gold if character has less than 99k in inventory
	If IsRareMaterial($item) Then
		Return True
	ElseIf ($itemID == $ID_Dyes) Then
		Return (($itemExtraID == $ID_Black_Dye) Or ($itemExtraID == $ID_White_Dye))
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
Func CheckForChests($range = $RANGE_EARSHOT, $DefendFunction = null)
	Local Static $openedChests[]
	Local $gadgetID
	Local $agents = GetAgentArray(0x200)	;0x200 = type: static
	For $i = 1 To $agents[0]
		$gadgetID = DllStructGetData($agents[$i], 'GadgetID')
		If $Map_Chests[$gadgetID] == null Then ContinueLoop
		If GetDistance(GetMyAgent(), $agents[$i]) > $range Then ContinueLoop

		If $openedChests[DllStructGetData($agents[$i], 'ID')] <> 1 Then
			;MoveTo(DllStructGetData($agents[$i], 'X'), DllStructGetData($agents[$i], 'Y'))		;Fail half the time
			;GoSignpost($agents[$i])															;Seems to work but serious rubberbanding
			;GoToSignpost($agents[$i])															;Much better solution BUT character doesn't defend itself while going to chest + function kind of sucks
			GoToSignpostWhileDefending($agents[$i], $DefendFunction)							;Final solution
			RndSleep(500)
			OpenChest()
			RndSleep(1000)
			$openedChests[DllStructGetData($agents[$i], 'ID')] = 1
			PickUpItems()
		EndIf
	Next
EndFunc


;~ Go to signpost and waits until you reach it.
Func GoToSignpostWhileDefending($agent, $DefendFunction = null)
	Local $me = GetMyAgent()
	Local $X = DllStructGetData($agent, 'X')
	Local $Y = DllStructGetData($agent, 'Y')
	Local $blocked = 0
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $X, $Y) > 250 And $blocked < 15
		Move($X, $Y, 100)
		RndSleep(100)
		If $DefendFunction <> null Then $DefendFunction()
		$me = GetMyAgent()
		If DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0 Then
			$blocked += 1
			Move($X, $Y, 100)
		EndIf
		GoSignpost($agent)
		RndSleep(100)
		$me = GetMyAgent()
	WEnd
	RndSleep(500)
EndFunc
#EndRegion Loot Chests


#Region Inventory or Chest
;~ Find the first empty slot in the given bag
Func FindEmptySlot($bag)
	Local $item
	For $slot = 1 To DllStructGetData(GetBag($bag), 'Slots')
		$item = GetItemBySlot($bag, $slot)
		If DllStructGetData($item, 'ID') = 0 Then Return $slot
	Next
	Return 0
EndFunc


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
	Local $bagEmptySlot[2] = [0, 0]
	For $i = 8 To 21
		$bagEmptySlot[1] = FindEmptySlot($i)
		If $bagEmptySlot[1] <> 0 Then
			$bagEmptySlot[0] = $i
			Return $bagEmptySlot
		EndIf
	Next
	Return $bagEmptySlot
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
	For $bagId = 1 To 4
		For $slot = 1 To DllStructGetData(GetBag($bagId), 'slots')
			Local $item = GetItemBySlot($bagId, $slot)
			If DllStructGetData($item, 'ID') <> 0 And (isArmorSalvageItem($item) Or IsWeapon($item)) Then
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
	;						0-Lockpicks 1-Books	2-Consumables	3-Trophies	4-Tomes	5-Materials	6-Others	7-Armor Salvageables[Gold,	8-Purple,	9-Blue	10-White]	11-Weapons [Green,	12-Gold,	13-Purple,	14-Blue,	15-White]	16-Armor (Armor salvageables, weapons and armor start from the end)
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
					$itemsCounts[12] += 1
				ElseIf ($rarity == $RARITY_Purple) Then
					$itemsCounts[13] += 1
				ElseIf ($rarity == $RARITY_Blue) Then
					$itemsCounts[14] += 1
				ElseIf ($rarity == $RARITY_Green) Then
					$itemsCounts[11] += 1
				ElseIf ($rarity == $RARITY_White) Then
					$itemsCounts[15] += 1
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
				$category = 12
			ElseIf ($rarity == $RARITY_Purple) Then
				$category = 13
			ElseIf ($rarity == $RARITY_Blue) Then
				$category = 14
			ElseIf ($rarity == $RARITY_Green) Then
				$category = 11
			ElseIf ($rarity == $RARITY_White) Then
				$category = 15
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


Func GetGeneralSlot($bagsSizes, $bag, $slot)
	Local $generalSlot = $slot
	For $i = 1 To $bag - 1
		$generalSlot += $bagsSizes[$i]
	Next
	Return $generalSlot
EndFunc


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
		Info('Too much gold in chest, use some.')
	ElseIf $GStorage < 50000 Then
		Info('Not enough gold in chest, get some.')
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
	Local $extraID = ($itemID == $ID_Dyes) ? DllStructGetData($item, 'ExtraID') : -1
	Local $storageItem

	For $bag = $firstBag To $lastBag
		Local $bagSize = GetMaxSlots($bag)
		For $slot = 1 To $bagSize
			$storageItem = GetItemBySlot($bag, $slot)
			If (DllStructGetData($storageItem, 'ModelID') == $itemID) And ($extraId == -1 Or DllStructGetData($storageItem, 'ExtraID') == $extraID) Then
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
	For $i = 1 To 4
		$bag = GetBag($i)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $j = 1 To $bagSize
			$item = GetItemBySlot($bag, $j)

			If $Map_Dyes[$itemID] <> null Then
				If ((DllStructGetData($item, 'ModelID') == $ID_Dyes) And (DllStructGetData($item, 'ExtraID') == $itemID) Then $amountItem += DllStructGetData($item, 'Quantity')
			Else
				If DllStructGetData($item, 'ModelID') == $itemID Then $amountItem += DllStructGetData($item, 'Quantity')
			EndIf
		Next
	Next
	Return $amountItem
EndFunc
#EndRegion Count and find items


#Region Use Items
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
	UseItemBySlot($ConsumableSlot[0], $ConsumableSlot[1])
EndFunc


;~ Uses the Item from $bag at position $slot (positions start at 1)
Func UseItemBySlot($bag, $slot)
	If $bag > 0 And $slot > 0 Then
		If Not GetIsDead() And GetMapLoading() <> 2 Then
			Local $item = GetItemBySlot($bag, $slot)
			SendPacket(8, $HEADER_Item_USE, DllStructGetData($item, 'ID'))
		EndIf
	EndIf
EndFunc
#EndRegion Use Items


#Region Identification and Salvage
;~ Return True if the item should be salvaged
; TODO : refine which items should be salvaged and which should not
Func ShouldSalvageItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	If IsWeapon($item) And GetRarity($item) <> $RARITY_Green Then
		Return False
	ElseIf $itemID == $ID_Glacial_Stone Then
		Return True
	ElseIf $itemID == $ID_Saurian_Bone Then
		Return True
	ElseIf IsTrophy($item) Then
		Return False
	ElseIf IsTrophy($item) Then
		Return False
	EndIf
	Return False
EndFunc


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

			FindIdentificationKitOrBuySome()
			If Not GetIsIdentified($item) Then
				IdentifyItem($item)
				RndSleep(100)
			EndIf
		Next
	Next
EndFunc


;~ Salvage all items from inventory
Func SalvageAllItems()
	Info('Salvaging all items')
	For $bagIndex = 1 To 4
		Debug('Salvaging bag' & $bagIndex)
		Local $bagSize = DllStructGetData(GetBag($bagIndex), 'slots')
		For $i = 1 To $bagSize
			SalvageItemAt($bagIndex, $i)
		Next
	Next
EndFunc


;~ Salvage an item based on its position in the inventory
Func SalvageItemAt($bag, $slot)
	Local $item = GetItemBySlot($bag, $slot)
	If DllStructGetData($item, 'ID') = 0 Then Return

	If (ShouldSalvageItem($item) And CountSlots() > 0) Then
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
		Sleep(100 + GetPing())			
		If $rarity == $RARITY_gold Or $rarity == $RARITY_purple Then 
			ValidateSalvage()
			Sleep(100 + GetPing())			
		EndIf
	Next
EndFunc


#CS
10:45 - Starting...
10:45 - Salvaging bag 1, slot 6
10:45 - ItemID 2251
10:45 - Salvage kit 1274
10:45 - Starting salvage
10:45 - Salvage session
10:45 - Enqueueing
10:45 - Sending enter
10:45 - Salvage done
10:45 - Paused.
#CE


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
	
	Local $j = 0
	While $IdentificationKit == 0
		If $j = 3 Then Return 0
		BuySuperiorIdentificationKit()
		$j = $j + 1
		$IdentificationKit = FindIdentificationKit()
	WEnd
	RndSleep(500)
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


Func IsArmorSalvageItem($item)
	Return DllStructGetData($item, 'type') == $ID_Type_Armor_Salvage
EndFunc


Func IsBook($item)
	Return DllStructGetData($item, 'type') == $ID_Type_Book
EndFunc


Func IsStackableItemButNotMaterial($itemID)
	Return $Map_StackableItemsExceptMaterials[$itemID] <> null
EndFunc


Func IsMaterial($item)
	Return DllStructGetData($item, 'Type') == 11 And $Map_All_Materials[DllStructGetData($item, 'ModelID')] <> null
EndFunc


Func IsBasicMaterial($item)
	Return DllStructGetData($item, 'Type') == 11 And $Map_Basic_Materials[DllStructGetData($item, 'ModelID')] <> null
EndFunc


Func IsRareMaterial($item)
	Return DllStructGetData($item, 'Type') == 11 And $Map_Rare_Materials[DllStructGetData($item, 'ModelID')] <> null
EndFunc

Func IsConsumable($itemID)
	Return IsAlcohol($itemID) Or IsFestive($itemID) Or IsTownSweet($itemID) Or IsPCon($itemID) Or IsDPRemovalSweet($itemID) Or IsSpecialDrop($itemID) Or IsSummoningStone($itemID) Or IsPartyTonic($itemID) Or IsEverlastingTonic($itemID)
EndFunc

Func IsAlcohol($itemID)
	Return $Map_Alcohols[$itemID] <> null
EndFunc


Func IsFestive($itemID)
	Return $Map_Festive[$itemID] <> null
EndFunc


Func IsTownSweet($itemID)
	Return $Map_Town_Sweets[$itemID] <> null
EndFunc


Func IsPCon($itemID)
	Return $Map_Sweet_Pcons[$itemID] <> null
EndFunc


Func IsDPRemovalSweet($itemID)
	Return $Map_DPRemoval_Sweets[$itemID] <> null
EndFunc


Func IsSpecialDrop($itemID)
	Return $Map_Special_Drops[$itemID] <> null
EndFunc


Func IsSummoningStone($itemID)
	Return $Map_Summoning_Stones[$itemID] <> null
EndFunc


Func IsPartyTonic($itemID)
	Return $Map_Party_Tonics[$itemID] <> null
EndFunc


Func IsEverlastingTonic($itemID)
	Return $Map_EL_Tonics[$itemID] <> null
EndFunc


Func IsTrophy($itemID)
	Return $Map_Trophies[$itemID] <> null Or $Map_Reward_Trophies[$itemID] <> null
EndFunc


Func IsArmor($item)
	Return $Map_Armor_Types[DllStructGetData($item, 'type')] <> null
EndFunc


Func IsWeapon($item)
	Return $Map_Weapon_Types[DllStructGetData($item, 'type')] <> null
EndFunc


Func IsWeaponMod($itemID)
	Return $Map_Weapon_Mods[$itemID] <> null
EndFunc


Func IsTome($itemID)
	Return $Map_Tomes[$itemID] <> null
EndFunc


Func IsGoldScroll($itemID)
	Return $Map_Gold_Scrolls[$itemID] <> null
EndFunc


Func IsBlueScroll($itemID)
	Return $Map_Blue_Scrolls[$itemID] <> null
EndFunc


Func IsKey($itemID)
	Return $Map_Keys[$itemID] <> null
EndFunc


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
;~ Return the value if it's not null else the defaultValue
Func GetOrDefault($value, $defaultValue)
	If ($value == null) Then Return $defaultValue
	Return $value
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
	ElseIf $position < 0 Then
		Return False
	Else
		Return False
	EndIf
EndFunc
#EndRegion Utils


#Region NPCs
;~ Print NPC informations
Func PrintNPCInformations($npc)
	Info('ID: ' & DllStructGetData($npc, 'ID'))
	Info('X: ' & DllStructGetData($npc, 'X'))
	Info('Y: ' & DllStructGetData($npc, 'Y'))
	Info('TypeMap: ' & DllStructGetData($npc, 'TypeMap'))
	Info('Allegiance: ' & DllStructGetData($npc, 'Allegiance'))
	Info('Effects: ' & DllStructGetData($npc, 'Effects'))
	Info('ModelState: ' & DllStructGetData($npc, 'ModelState'))
	Info('NameProperties: ' & DllStructGetData($npc, 'NameProperties'))
	Info('Type: ' & DllStructGetData($npc, 'Type'))
	Info('ExtraType: ' & DllStructGetData($npc, 'ExtraType'))
	Info('GadgetID: ' & DllStructGetData($npc, 'GadgetID'))
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

;~ Small helper to filter party members - TODO: remove this
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
		Local $curDistance = GetDistance($me, $curAgent)
		If $range > 0 And ComputeDistance($coordX, $coordY, DllStructGetData($curAgent, 'X'), DllStructGetData($curAgent, 'Y')) > $range Then ContinueLoop
		If $curDistance > $furthestDistance Then
			$returnAgent = $curAgent
			$furthestDistance = $curDistance
		EndIf
	Next

	Return $returnAgent
EndFunc


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
Func AttackOrUseSkill($attackSleep, $skill = null, $skill2 = null, $skill3 = null, $skill4 = null, $skill5 = null, $skill6 = null, $skill7 = null, $skill8 = null)
	Local $me = GetMyAgent()
	If ($skill <> null And IsRecharged($skill)) Then
		UseSkillEx($skill, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill2 <> null And IsRecharged($skill2)) Then
		UseSkillEx($skill2, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill3 <> null And IsRecharged($skill3)) Then
		UseSkillEx($skill3, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill4 <> null And IsRecharged($skill4)) Then
		UseSkillEx($skill4, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill5 <> null And IsRecharged($skill5)) Then
		UseSkillEx($skill5, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill6 <> null And IsRecharged($skill6)) Then
		UseSkillEx($skill6, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill7 <> null And IsRecharged($skill7)) Then
		UseSkillEx($skill7, GetNearestEnemyToAgent($me))
		RndSleep(50)
	ElseIf ($skill8 <> null And IsRecharged($skill8)) Then
		UseSkillEx($skill8, GetNearestEnemyToAgent($me))
		RndSleep(50)
	Else
		Attack(GetNearestEnemyToAgent($me))
		RndSleep($attackSleep)
	EndIf
EndFunc


#Region Map Clearing Utilities
Func MapClearMoveAndAggro($x, $y, $s = '', $range = 1450)
	Info('Hunting ' & $s)
	Local $blocked = 0
	Local $me = GetMyAgent()
	Local $coordsX = DllStructGetData($me, 'X')
	Local $coordsY = DllStructGetData($me, 'Y')

	Move($x, $y)

	Local $oldCoordsX
	Local $oldCoordsY
	Local $nearestEnemy
	While $groupIsAlive And ComputeDistance($coordsX, $coordsY, $x, $y) > $RANGE_NEARBY And $blocked < 10
		$oldCoordsX = $coordsX
		$oldCoordsY = $coordsY
		$me = GetMyAgent()
		$nearestEnemy = GetNearestEnemyToAgent($me)
		If GetDistance($me, $nearestEnemy) < $range And DllStructGetData($nearestEnemy, 'ID') <> 0 Then MapClearKillFoes()
		$coordsX = DllStructGetData($me, 'X')
		$coordsY = DllStructGetData($me, 'Y')
		If $oldCoordsX = $coordsX And $oldCoordsY = $coordsY Then
			$blocked += 1
			Move($coordsX, $coordsY, 500)
			RndSleep(500)
			Move($x, $y)
		EndIf
		RndSleep(500)
		CheckForChests($RANGE_SPIRIT)
	WEnd
	If Not $groupIsAlive Then Return True
EndFunc


Func MapClearKillFoes()
	Local $me = GetMyAgent()
	Local $skillNumber = 1, $foesCount = 999, $target = GetNearestEnemyToAgent($me), $targetId = -1
	GetAlmostInRangeOfAgent($target)

	While $groupIsAlive And $foesCount > 0
		$target = GetNearestEnemyToAgent($me)
		If DllStructGetData($target, 'ID') <> $targetId Then
			$targetId = DllStructGetData($target, 'ID')
			CallTarget($target)
		EndIf
		RndSleep(50)
		While Not IsRecharged($skillNumber) And $skillNumber < 9
			$skillNumber += 1
		WEnd
		If $skillNumber < 9 Then
			UseSkillEx($skillNumber, $target)
			RndSleep(50)
		Else
			Attack($target)
			RndSleep(1000)
		EndIf
		$skillNumber = 1
		PickUpItems(null, DefaultShouldPickItem, $RANGE_SPELLCAST)
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	WEnd
	RndSleep(1000)
	PickUpItems()
EndFunc


Func IsGroupAlive()
	Local $deadMembers = 0
	For $i = 1 to GetHeroCount()
		If GetIsDead(GetHeroID($i)) = True Then
			$deadMembers += 1
		EndIf
		If $deadMembers >= 5 Then
			Notice('Group wiped, back to oupost to save time.')
			Return False
		EndIf
	Next
	Return True
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
	Local $attributes[1][2]		; A Bits + 4 Bits (for each Attribute)
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

	$attributes[0][0] = $attributesCount
	For $i = 1 To $attributesCount
		If Bin64ToDec(StringLeft($buildTemplate, $attributesBits)) == GetProfPrimaryAttribute($primaryProfession) Then
			$buildTemplate = StringTrimLeft($buildTemplate, $attributesBits)
			$attributes[0][1] = Bin64ToDec(StringLeft($buildTemplate, 4))
			$buildTemplate = StringTrimLeft($buildTemplate, 4)
			ContinueLoop
		EndIf
		$attributes[0][0] += 1
		ReDim $attributes[$attributes[0][0] + 1][2]
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

	$attributes[0][0] = $secondaryProfession
	
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
	For $i = 1 To UBound($attributesArray) - 1
		If $attributesArray[$i][1] > 12 Then $attributesArray[$i][1] = 12
		If $attributesArray[$i][1] < 0 Then $attributesArray[$i][1] = 0
	Next

	; Only way to do this is to set all attributes to 0 and then increasing them as many times as needed
	EmptyAttributes($secondaryProfession, $heroIndex)
	
	; Now that all attributes are at 0, we increase them by the times needed
	; Using GetAttributeByID during the increase is a bad idea because it counts points from runes too
	For $i = 1 To UBound($attributesArray) - 1
		For $j = 1 To $attributesArray[$i][1]
			IncreaseAttribute($attributesArray[$i][0], $heroIndex)
			Sleep(100 + GetPing())
		Next
	Next
	Sleep(250)

	; If there are any points left, we put them in the primary attribute (it's often not tracked by the $attributesArray)
	For $i = 0 To 11
		IncreaseAttribute($primaryAttribute, $heroIndex)
		Sleep(100 + GetPing())
	Next
EndFunc


;~ Set all attributes of the character/hero to 0
Func EmptyAttributes($secondaryProfession, $heroIndex = 0)
	For $attribute In $AttributesByProfessionMap[GetHeroProfession($heroIndex)]
		For $i = 0 To 11
			DecreaseAttribute($attribute, $heroIndex)
			Sleep(20 + GetPing())
		Next
	Next
	
	For $attribute In $AttributesByProfessionMap[$secondaryProfession]
		For $i = 0 To 11
			DecreaseAttribute($attribute, $heroIndex)
			Sleep(20 + GetPing())
		Next
	Next
EndFunc
#EndRegion Skill and Templates



Func _dlldisplay($tStruct)
	Local $pNextPtr, $pCurrentPtr = DllStructGetPtr($tStruct, 1)
	Local $iOffset = 0, $iDllSize = DllStructGetSize($tStruct)
	Local $vElVal, $sType, $iTypeSize, $iElSize, $iArrCount, $iAlign

	Local $aStruct[1][5] = [['-', $pCurrentPtr, '<struct>', 0, '-']]	; #|Offset|Type|Size|Value'

	; loop through elements
	For $iE = 1 To 2 ^ 63

		; backup first index value, establish type and typesize of element, restore first index value
		$vElVal = DllStructGetData($tStruct, $iE, 1)
		Switch VarGetType($vElVal)
			Case 'Int32', 'Int64'
				DllStructSetData($tStruct, $iE, 0x7777666655554433, 1)
				Switch DllStructGetData($tStruct, $iE, 1)
					Case 0x7777666655554433
						$sType = 'int64'
						$iTypeSize = 8
					Case 0x55554433
						DllStructSetData($tStruct, $iE, 0x88887777, 1)
						$sType = (DllStructGetData($tStruct, $iE, 1) > 0 ? 'uint' : 'int')
						$iTypeSize = 4
					Case 0x4433
						DllStructSetData($tStruct, $iE, 0x8888, 1)
						$sType = (DllStructGetData($tStruct, $iE, 1) > 0 ? 'ushort' : 'short')
						$iTypeSize = 2
					Case 0x33
						$sType = 'byte'
						$iTypeSize = 1
				EndSwitch
			Case 'Ptr'
				$sType = 'ptr'
				$iTypeSize = @AutoItX64 ? 8 : 4
			Case 'String'
				DllStructSetData($tStruct, $iE, ChrW(0x2573), 1)
				$sType = (DllStructGetData($tStruct, $iE, 1) = ChrW(0x2573) ? 'wchar' : 'char')
				$iTypeSize = ($sType = 'wchar') ? 2 : 1
			Case 'Double'
				DllStructSetData($tStruct, $iE, 10 ^ - 15, 1)
				$sType = (DllStructGetData($tStruct, $iE, 1) = 10 ^ - 15 ? 'double' : 'float')
				$iTypeSize = ($sType = 'double') ? 8 : 4
		EndSwitch
		DllStructSetData($tStruct, $iE, $vElVal, 1)

		; calculate element total size based on distance to next element
		$pNextPtr = DllStructGetPtr($tStruct, $iE + 1)
		$iElSize = $pNextPtr ? Int($pNextPtr - $pCurrentPtr) : $iDllSize

		; calculate true array count. Walk index backwards till there is NOT an error
		$iArrCount = Int($iElSize / $iTypeSize)
		While $iArrCount > 1
			DllStructGetData($tStruct, $iE, $iArrCount)
			If Not @error Then ExitLoop
			$iArrCount -= 1
		WEnd

		; alignment is whatever space is left
		$iAlign = $iElSize - ($iArrCount * $iTypeSize)
		$iElSize -= $iAlign

		; Add/print values and alignment
		Switch $sType
			Case 'wchar', 'char', 'byte'
				_ArrayAdd($aStruct, $iE & '|' & $iOffset & '|' & $sType & '[' & $iArrCount & ']|' & $iElSize & '|' & DllStructGetData($tStruct, $iE))
			; 'uint', 'int', 'ushort', 'short', 'double', 'float', 'ptr'
			Case Else
				If $iArrCount > 1 Then
					_ArrayAdd($aStruct, $iE & '|' & $iOffset & '|' & $sType & '[' & $iArrCount & ']' & '|' & $iElSize & ' (' & $iTypeSize & ')|' & (DllStructGetData($tStruct, $iE) ? '[1] ' & $vElVal : '-'))
					; skip empty arrays
					If DllStructGetData($tStruct, $iE) Then
						For $j = 2 To $iArrCount
							_ArrayAdd($aStruct, '-|' & $iOffset + ($iTypeSize * ($j - 1)) & '|-|-|[' & $j & '] ' & DllStructGetData($tStruct, $iE, $j))
						Next
					EndIf
				Else
					_ArrayAdd($aStruct, $iE & '|' & $iOffset & '|' & $sType & '|' & $iElSize & '|' & $vElVal)
				EndIf
		EndSwitch
		If $iAlign Then _ArrayAdd($aStruct, '-|-|<alignment>|' & ($iAlign) & '|-')

		; if no next ptr then this was the last/only element
		If Not $pNextPtr Then ExitLoop

		; update offset, size and next ptr
		$iOffset += $iElSize + $iAlign
		$iDllSize -= $iElSize + $iAlign
		$pCurrentPtr = $pNextPtr

	Next

	_ArrayAdd($aStruct, '-|' & DllStructGetPtr($tStruct) + DllStructGetSize($tStruct) & '|<endstruct>|' & DllStructGetSize($tStruct) & '|-')

	_ArrayDisplay($aStruct, '', '', 64, Default, '#|Offset|Type|Size|Value')

	Return $aStruct
EndFunc