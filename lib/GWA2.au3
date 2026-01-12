#CS ===========================================================================
; Author: gigi, tjubutsi, Greg-76
; Modified by: MrZambix, Night, Gahais, and more
#CE ===========================================================================

#include-once

#include 'GWA2_Headers.au3'
#include 'GWA2_ID.au3'
#include 'Utils.au3'
#include 'Utils-Debugger.au3'

; Required for memory access, opening external process handles and injecting code
#RequireAdmin

; Additional directives
#Region		;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_type=a3x
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/pe /sf /tl
#EndRegion	;**** Directives created by AutoIt3Wrapper_GUI ****


#Region Declarations
; Flags
Global $disable_rendering_address
Global $rendering_enabled = True

; Game-related variables
; Game memory - queue, targets, skills
Global $queue_counter, $queue_size, $queue_base_address
Global $string_log_base_address, $skill_base_address
Global $my_ID

; Language flag
Global $force_english_language_flag

; Agent state
Global $current_target_agent_ID

; Agent structures
Global $agent_base_address, $base_address_ptr

; Regional and account info
Global $region_ID, $language_ID
Global $scan_ping_address

; Map status
Global $max_agents, $is_logged_in, $agent_copy_count, $agent_copy_base

; Trader system
Global $trader_quote_ID, $trader_cost_ID, $trader_cost_value

; Skill state
Global $skill_timer, $build_number

; Zoom levels
Global $zoom_when_still, $zoom_when_moving

; Event state
Global $current_status, $last_dialog_ID

; Optional systems
Global $use_string_logging, $use_event_system

; Character info
Global $instance_info_ptr, $area_info_ptr
Global $attribute_info_ptr
Global $map_ID, $map_loading
#EndRegion Declarations


#Region Commands
#Region Item
;~ Starts a salvaging session of an item.
Func StartSalvageWithKit($item, $salvageKit)
	Local $offset[4] = [0, 0x18, 0x2C, 0x690]
	Local $salvageSessionID = MemoryReadPtr($base_address_ptr, $offset)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	DllStructSetData($SALVAGE_STRUCT, 2, $itemID)
	DllStructSetData($SALVAGE_STRUCT, 3, DllStructGetData($salvageKit, 'ID'))
	DllStructSetData($SALVAGE_STRUCT, 4, $salvageSessionID[1])

	Enqueue($SALVAGE_STRUCT_PTR, 16)
EndFunc


;~ Doesn't work - Should validate salvage
Func ValidateSalvage()
	ControlSend(GetWindowHandle(), '', '', '{Enter}')
	Sleep(GetPing() + 1000)
EndFunc


;~ Get itemID from an item structure or pointer
Func GetItemID($item)
	If IsPtr($item) Then
		Return MemoryRead($item, 'long')
	ElseIf IsDllStruct($item) Then
		Return DllStructGetData($item, 'ID')
	Else
		Return $item
	EndIf
EndFunc


;~ Salvage the materials out of an item.
Func SalvageMaterials()
	Return SendPacket(0x4, $HEADER_SALVAGE_MATERIALS)
EndFunc


;~ Salvages a mod out of an item. Index: 0 for prefix/inscription, 1 for suffix/rune, 2 for inscription
Func SalvageMod($modIndex)
	Return SendPacket(0x8, $HEADER_SALVAGE_UPGRADE, $modIndex)
EndFunc


;~ Salvage the materials out of an item.
Func EndSalvage()
	Return SendPacket(0x4, $HEADER_SALVAGE_SESSION_DONE)
EndFunc


;~ Cancel the salvaging session
Func CancelSalvage()
	Return SendPacket(0x4, $HEADER_SALVAGE_SESSION_CANCEL)
EndFunc


;~ Identifies an item.
Func IdentifyItem($item)
	If GetIsIdentified($item) Then Return

	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	Local $identificationKit = FindIdentificationKit()
	If $identificationKit == 0 Then Return

	SendPacket(0xC, $HEADER_ITEM_IDENTIFY, DllStructGetData($identificationKit, 'ID'), $itemID)

	Local $deadlock = TimerInit()
	Do
		Sleep(20)
	Until GetIsIdentified($itemID) Or TimerDiff($deadlock) > 5000
EndFunc


;~ Identifies all items in a bag.
Func IdentifyBag($bag, $identifyWhiteItems = False, $identifyGoldItems = True)
	Local $item
	If Not IsDllStruct($bag) Then $bag = GetBag($bag)
	For $i = 1 To DllStructGetData($bag, 'Slots')
		$item = GetItemBySlot($bag, $i)
		If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
		If GetRarity($item) == $RARITY_WHITE And $identifyWhiteItems == False Then ContinueLoop
		If GetRarity($item) == $RARITY_GOLD And $identifyGoldItems == False Then ContinueLoop
		IdentifyItem($item)
	Next
EndFunc


;~ Equips an item.
Func EquipItem($item)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')
	Return SendPacket(0x8, $HEADER_ITEM_EQUIP, $itemID)
EndFunc


;~ Equips an item specified by item's model ID. No impact if item is already equipped
Func EquipItemByModelID($itemModelID)
	Local $item = GetItemByModelID($itemModelID)
	If Not IsDllStruct($item) Then Return False
	If DllStructGetData($item, 'ModelId') <> $itemModelID Then Return False
	Return SendPacket(0x8, $HEADER_ITEM_EQUIP, DllStructGetData($item, 'ID'))
EndFunc


;~ Checks if item specified by item's model ID is equipped in any weapon slot
Func IsItemEquipped($itemModelID)
	Local $item = GetItemByModelID($itemModelID)
	If Not IsDllStruct($item) Then Return False
	If DllStructGetData($item, 'ModelId') <> $itemModelID Then Return False
	; Equipped value is 0 if not equipped in any slot
	Return DllStructGetData($item, 'Equipped') > 0
EndFunc


;~ Checks if item specified by item's model ID is equipped in specified weapon slot (from 1 to 4)
Func IsItemEquippedInWeaponSlot($itemModelID, $weaponSlot)
	If $weaponSlot <> 1 And $weaponSlot <> 2 And $weaponSlot <> 3 And $weaponSlot <> 4 Then Return False
	Local $item = GetItemByModelID($itemModelID)
	If Not IsDllStruct($item) Then Return False
	If DllStructGetData($item, 'ModelId') <> $itemModelID Then Return False

	Local $equipValue = DllStructGetData($item, 'Equipped')
	; Equipped value in item struct is a bitmask of size 1 byte (from 0 to 255). Only first 4 bits are used so values are from 0 to 15
	; Bits from 1 to 4 say if item is equipped in weapon slot 1 to 4 respectively. If item is unequipped then value is 0. If the same item is equipped in all 4 slots then value is 15 = 1+2+4+8 = 2^0+2^1+2^2+2^3
	Return BitAND($equipValue, 2 ^ ($weaponSlot - 1)) > 0
EndFunc


;~ Checks if item specified by item's model ID is located in any bag or backpack or is equipped in any weapon slot
; FIXME: doesn't work
Func ItemExistsInInventory($itemModelID)
	Local $item = GetItemByModelID($itemModelID)
	If Not IsDllStruct($item) Then Return False
	If DllStructGetData($item, 'ModelId') <> $itemModelID Then Return False
	; slots are numbered from 1, if item is not in any bag then Slot is 0
	Return DllStructGetData($item, 'Equipped') > 0 Or DllStructGetData($item, 'Slot') > 0
EndFunc


;~ Uses an item.
Func UseItem($item)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')
	Return SendPacket(0x8, $HEADER_ITEM_USE, $itemID)
EndFunc


;~ Picks up an item.
Func PickUpItem($item)
	Local $agentID
	If Not IsDllStruct($item) Then
		$agentID = $item
	ElseIf DllStructGetSize($item) < 400 Then
		$agentID = DllStructGetData($item, 'AgentID')
	Else
		$agentID = DllStructGetData($item, 'ID')
	EndIf
	Return SendPacket(0xC, $HEADER_ITEM_INTERACT, $agentID, 0)
EndFunc


;~ Drops an item.
Func DropItem($item, $amount = 0)
	Local $itemID
	If IsDllStruct($item) Then
		$itemID = DllStructGetData($item, 'ID')
	Else
		$itemID = $item
		$item = GetItemByItemID($item)
	EndIf
	If $amount < 0 Then $amount = DllStructGetData($item, 'Quantity')
	Return SendPacket(0xC, $HEADER_DROP_ITEM, $itemID, $amount)
EndFunc


;~ Moves an item.
Func MoveItem($item, $bag, $slotIndex)
	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	Local $bagID
	If IsDllStruct($bag) Then
		$bagID = DllStructGetData($bag, 'ID')
	Else
		$bagID = DllStructGetData(GetBag($bag), 'ID')
	EndIf
	Return SendPacket(0x10, $HEADER_ITEM_MOVE, $itemID, $bagID, $slotIndex - 1)
EndFunc


;~ Accepts unclaimed items after a mission.
Func AcceptAllItems()
	Return SendPacket(0x8, $HEADER_ITEMS_ACCEPT_UNCLAIMED, DllStructGetData(GetBag(7), 'ID'))
EndFunc


;~ Find an item with the provided modelId in your inventory and return its itemID
Func GetItemIDFromModelID($modelID)
	For $i = 1 To $bags_count
		For $j = 1 To DllStructGetData(GetBag($i), 'slots')
			Local $item = GetItemBySlot($i, $j)
			If DllStructGetData($item, 'ModelId') == $modelID Then Return DllStructGetData($item, 'Id')
		Next
	Next
EndFunc


;~ FIXME: this function is written like trash
Func CraftItem($modelID, $amount, $gold, ByRef $materialsArray)
	Local $sourceItemPtr = GetInventoryItemPtrByModelId($materialsArray[0][0])
	If ((Not $sourceItemPtr) Or (MemoryRead($sourceItemPtr + 0x4B) < $materialsArray[0][1])) Then Return 0
	Local $destinationItemPtr = MemoryRead(GetMerchantItemPtrByModelId($modelID))
	If (Not $destinationItemPtr) Then Return 0
	Local $materialString = ''
	Local $materialCount = 0
	If IsArray($materialsArray) = 0 Then Return 0
	Local $materialsArraySize = UBound($materialsArray) - 1
	For $i = $materialsArraySize To 0 Step -1
		Local $checkQuantity = CountItemInBagsByModelID($materialsArray[$i][0])
		If $materialsArray[$i][1] * $amount > $checkQuantity Then
			; amount of missing mats in @extended
			Return SetExtended($materialsArray[$i][1] * $amount - $checkQuantity, $materialsArray[$i][0])
		EndIf
	Next
	Local $gold = GetGoldCharacter()

	For $i = 0 To $materialsArraySize
		$materialString &= GetItemIDFromModelID($materialsArray[$i][0]) & ';'
		Debug($materialString)
		$materialCount += 1
	Next

	$craftingMaterialType = 'dword'
	For $i = 1 To $materialCount - 1
		$craftingMaterialType &= ';dword'
	Next
	$craftingMaterialStruct = SafeDllStructCreate($craftingMaterialType)
	$craftingMaterialStructPtr = DllStructGetPtr($craftingMaterialStruct)
	For $i = 1 To $materialCount
		Local $size = StringInStr($materialString, ';')
		DllStructSetData($craftingMaterialStruct, $i, StringLeft($materialString, $size - 1))
		$materialString = StringTrimLeft($materialString, $size)
	Next
	Local $memorySize = $materialCount * 4
	Local $processHandle = GetProcessHandle()
	Local $memoryBuffer = SafeDllCall13($kernel_handle, 'ptr', 'VirtualAllocEx', 'handle', $processHandle, 'ptr', 0, 'ulong_ptr', $memorySize, 'dword', 0x1000, 'dword', 0x40)
	; Couldnt allocate enough memory
	If $memoryBuffer = 0 Then Return 0
	Local $buffer = SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', $processHandle, 'int', $memoryBuffer[0], 'ptr', $craftingMaterialStructPtr, 'int', $memorySize, 'int', 0)
	If $buffer = 0 Then Return
	DllStructSetData($CRAFT_ITEM_STRUCT, 1, GetValue('CommandCraftItemEx'))
	DllStructSetData($CRAFT_ITEM_STRUCT, 2, $amount)
	DllStructSetData($CRAFT_ITEM_STRUCT, 3, $destinationItemPtr)
	DllStructSetData($CRAFT_ITEM_STRUCT, 4, $memoryBuffer[0])
	Debug($memoryBuffer[0])
	DllStructSetData($CRAFT_ITEM_STRUCT, 5, $materialCount)
	Debug($materialCount)
	DllStructSetData($CRAFT_ITEM_STRUCT, 6, $amount * $gold)
	Debug($amount * $gold)
	Enqueue($CRAFT_ITEM_STRUCT_PTR, 24)
	$deadlock = TimerInit()
	Local $currentAmount
	Do
		Sleep(250)
		$currentAmount = CountItemInBagsByModelID($materialsArray[0][0])
	Until $currentAmount <> $checkQuantity Or $gold <> GetGoldCharacter() Or TimerDiff($deadlock) > 5000
	SafeDllCall11($kernel_handle, 'ptr', 'VirtualFreeEx', 'handle', $processHandle, 'ptr', $memoryBuffer[0], 'int', 0, 'dword', 0x8000)
	; should be zero if items were successfully crafted
	Return SetExtended($checkQuantity - $currentAmount - $materialsArray[0][1] * $amount, True)
EndFunc


;~ Drop gold on the ground.
Func DropGold($amount = 0)
	If $amount <= 0 Then
		$amount = GetGoldCharacter()
	EndIf

	Return SendPacket(0x8, $HEADER_DROP_GOLD, $amount)
EndFunc


;~ Deposit gold into storage.
Func DepositGold($amount = 0)
	Local $storageGold = GetGoldStorage()
	Local $characterGold = GetGoldCharacter()

	If $amount > 0 And $characterGold >= $amount Then
		$amount = $amount
	Else
		$amount = $characterGold
	EndIf

	If $storageGold + $amount > 1000000 Then $amount = 1000000 - $storageGold

	ChangeGold($characterGold - $amount, $storageGold + $amount)
EndFunc


;~ Withdraw gold from storage.
Func WithdrawGold($amount = 0)
	Local $storageGold = GetGoldStorage()
	Local $characterGold = GetGoldCharacter()

	If $amount <= 0 Or $storageGold < $amount Then
		$amount = $storageGold
	EndIf

	If $characterGold + $amount > 100000 Then $amount = 100000 - $characterGold

	ChangeGold($characterGold + $amount, $storageGold - $amount)
EndFunc


;~ Internal use for moving gold.
Func ChangeGold($character, $storage)
	Return SendPacket(0xC, $HEADER_CHANGE_GOLD, $character, $storage)
EndFunc
#EndRegion Item


#Region Trade
#Region NPC Trade
;~ Sells an item.
Func SellItem($item, $amount = 0)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	If $amount = 0 Or $amount > DllStructGetData($item, 'Quantity') Then $amount = DllStructGetData($item, 'Quantity')

	DllStructSetData($SELL_ITEM_STRUCT, 2, $amount * DllStructGetData($item, 'Value'))
	DllStructSetData($SELL_ITEM_STRUCT, 3, DllStructGetData($item, 'ID'))
	DllStructSetData($SELL_ITEM_STRUCT, 4, MemoryRead(GetScannedAddress('ScanBuyItemBase', 15)))
	Enqueue($SELL_ITEM_STRUCT_PTR, 16)
EndFunc


;~ Buys an item. ItemPosition is the position of the item in the list of items offered by merchant
Func BuyItem($itemPosition, $amount, $value)
	Local $merchantItemsBase = GetMerchantItemsBase()

	If Not $merchantItemsBase Then Return
	If $itemPosition < 1 Or GetMerchantItemsSize() < $itemPosition Then Return

	DllStructSetData($BUY_ITEM_STRUCT, 2, $amount)
	DllStructSetData($BUY_ITEM_STRUCT, 3, MemoryRead($merchantItemsBase + 4 * ($itemPosition - 1)))
	DllStructSetData($BUY_ITEM_STRUCT, 4, $amount * $value)
	DllStructSetData($BUY_ITEM_STRUCT, 5, MemoryRead(GetScannedAddress('ScanBuyItemBase', 15)))
	Enqueue($BUY_ITEM_STRUCT_PTR, 20)
EndFunc


;~ Buys an identification kit.
Func BuyIdentificationKit($amount = 1)
	BuyItem(5, $amount, 100)
EndFunc


;~ Buys a superior identification kit.
Func BuySuperiorIdentificationKit($amount = 1)
	BuyItem(6, $amount, 500)
	RandomSleep(1000)
EndFunc


;~ Buys a basic salvage kit.
Func BuySalvageKit($amount = 1)
	BuyItem(2, $amount, 100)
	RandomSleep(1000)
EndFunc


;~ Buys an expert salvage kit.
Func BuyExpertSalvageKit($amount = 1)
	BuyItem(3, $amount, 400)
	RandomSleep(1000)
EndFunc


;~ Buys an expert salvage kit.
Func BuySuperiorSalvageKit($amount = 1)
	BuyItem(4, $amount, 2000)
	RandomSleep(1000)
EndFunc


;~ Get item from merchant corresponding to given modelID
Func GetMerchantItemPtrByModelId($modelID)
	Local $offsets[5] = [0, 0x18, 0x40, 0xB8]
	Local $merchantBaseAddress = GetMerchantItemsBase()
	Local $itemID = 0
	Local $itemPtr = 0
	For $i = 0 To GetMerchantItemsSize() -1
		$itemID = MemoryRead($merchantBaseAddress + 4 * $i)
		If ($itemID) Then
			$offsets[4] = 4 * $itemID
			$itemPtr = MemoryReadPtr($base_address_ptr, $offsets)[1]
			If (MemoryRead($itemPtr + 0x2C) = $modelID) Then
				Return Ptr($itemPtr)
			EndIf
		EndIf
	Next
EndFunc


;~ Request a quote to buy an item from a trader. Returns True if successful.
Func TraderRequest($modelID, $dyeColor = -1)
	Local $offset[4] = [0, 0x18, 0x40, 0xC0]
	Local $itemArraySize = MemoryReadPtr($base_address_ptr, $offset)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0]
	Local $itemPtr, $itemID
	Local $found = False
	Local $quoteID = MemoryRead($trader_quote_ID)
	Local $itemStruct = SafeDllStructCreate($ITEM_STRUCT_TEMPLATE)
	Local $processHandle = GetProcessHandle()
	For $itemID = 1 To $itemArraySize[1]
		$offset[4] = 0x4 * $itemID
		$itemPtr = MemoryReadPtr($base_address_ptr, $offset)
		If $itemPtr[1] = 0 Then ContinueLoop

		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', 0)
		If DllStructGetData($itemStruct, 'ModelID') = $modelID And DllStructGetData($itemStruct, 'bag') = 0 And DllStructGetData($itemStruct, 'AgentID') == 0 Then
			If $dyeColor = -1 Or DllStructGetData($itemStruct, 'DyeColor') = $dyeColor Then
				$found = True
				ExitLoop
			EndIf
		EndIf
	Next
	If Not $found Then Return False

	DllStructSetData($REQUEST_QUOTE_STRUCT, 2, DllStructGetData($itemStruct, 'ID'))
	Enqueue($REQUEST_QUOTE_STRUCT_PTR, 8)

	Local $deadlock = TimerInit()
	$found = False
	Do
		Sleep(20)
		$found = MemoryRead($trader_quote_ID) <> $quoteID
	Until $found Or TimerDiff($deadlock) > GetPing() + 5000
	Return $found
EndFunc


;~ Buy the requested item.
Func TraderBuy()
	If Not GetTraderCostID() Or Not GetTraderCostValue() Then Return False
	Enqueue($TRADER_BUY_STRUCT_PTR, 4)
	Return True
EndFunc


;~ Request to buy an item to a trader, returns the quote value
Func TraderRequestBuy($item)
	Local $found = False
	Local $quoteID = MemoryRead($trader_quote_ID)
	Local $itemID = $item

	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')

	DllStructSetData($REQUEST_QUOTE_STRUCT, 1, $HEADER_REQUEST_QUOTE)
	DllStructSetData($REQUEST_QUOTE_STRUCT, 2, $itemID)
	Enqueue($REQUEST_QUOTE_STRUCT_PTR, 8)

	Local $deadlock = TimerInit()
	$found = False
	Do
		Sleep(20)
		$found = MemoryRead($trader_quote_ID) <> $quoteID
	Until $found Or TimerDiff($deadlock) > GetPing() + 5000

	Return $found
EndFunc


;~ Request a quote to sell an item to the trader.
Func TraderRequestSell($item)
	Local $found = False
	Local $quoteID = MemoryRead($trader_quote_ID)

	Local $itemID = $item
	If IsDllStruct($item) Then $itemID = DllStructGetData($item, 'ID')
	;DllStructSetData($REQUEST_QUOTE_STRUCT_SELL, 1, $HEADER_REQUEST_QUOTE)
	DllStructSetData($REQUEST_QUOTE_STRUCT_SELL, 2, $itemID)
	Enqueue($REQUEST_QUOTE_STRUCT_SELL_PTR, 8)

	Local $deadlock = TimerInit()
	Do
		Sleep(20)
		$found = MemoryRead($trader_quote_ID) <> $quoteID
	Until $found Or TimerDiff($deadlock) > GetPing() + 5000
	Return $found
EndFunc


;~ ID of the item item being sold.
Func TraderSell()
	If Not GetTraderCostID() Or Not GetTraderCostValue() Then Return False
	Enqueue($TRADER_SELL_STRUCT_PTR, 4)
	Return True
EndFunc
#Region NPC Trade


#Region Player Trade
;~ Initiate a trade with the given player agent
Func TradePlayer($agent)
	SendPacket(0x08, $HEADER_TRADE_PLAYER, DllStructGetData($agent, 'ID'))
EndFunc


;~ Like pressing the 'Accept' button in a trade.
Func AcceptTrade()
	Return SendPacket(0x4, $HEADER_TRADE_ACCEPT)
EndFunc


;~ Like pressing the 'Accept' button in a trade. Can only be used after both players have submitted their offer.
Func SubmitOffer($gold = 0)
	Return SendPacket(0x8, $HEADER_TRADE_SUBMIT_OFFER, $gold)
EndFunc


;~ Like pressing the 'Cancel' button in a trade.
Func CancelTrade()
	Return SendPacket(0x4, $HEADER_TRADE_CANCEL)
EndFunc


;~ Like pressing the 'Change Offer' button.
Func ChangeOffer()
	Return SendPacket(0x4, $HEADER_TRADE_CHANGE_OFFER)
EndFunc


;~ $itemID = ID of the item or item agent, $amount = Quantity
Func OfferItem($itemID, $amount = 1)
	Return SendPacket(0xC, $HEADER_TRADE_OFFER_ITEM, $itemID, $amount)
EndFunc


;~ Returns: 1 - Trade windows exist 3 - Offer 7 - Accepted Trade
Func TradeWinExist()
	Local $offset = [0, 0x18, 0x58, 0]
	Return MemoryReadPtr($base_address_ptr, $offset)[1]
EndFunc


Func TradeOfferItemExist()
	Local $offset = [0, 0x18, 0x58, 0x28, 0]
	Return MemoryReadPtr($base_address_ptr, $offset)[1]
EndFunc


Func TradeOfferMoneyExist()
	Local $offset = [0, 0x18, 0x58, 0x24]
	Return MemoryReadPtr($base_address_ptr, $offset)[1]
EndFunc


Func ToggleTradePatch($enableTradePatch = True)
	MemoryWrite($trade_hack_address, $enableTradePatch ? 0xC3 : 0x55, 'BYTE')
EndFunc
#EndRegion Player Trade
#EndRegion Trade


#Region H&H
;~ Adds a hero to the party.
Func AddHero($heroID)
	SendPacket(0x8, $HEADER_HERO_ADD, $heroID)
	Sleep(100)
EndFunc


;~ Kicks a hero from the party.
Func KickHero($heroID)
	Return SendPacket(0x8, $HEADER_HERO_KICK, $heroID)
EndFunc


;~ Kicks all heroes from the party.
Func KickAllHeroes()
	Return SendPacket(0x8, $HEADER_HERO_KICK, 0x26)
EndFunc


;~ Add a henchman to the party.
Func AddNpc($npcID)
	Return SendPacket(0x8, $HEADER_PARTY_INVITE_NPC, $npcID)
EndFunc


;~ Kick a henchman from the party.
Func KickNpc($npcID)
	Return SendPacket(0x8, $HEADER_PARTY_KICK_NPC, $npcID)
EndFunc


;~ Clear the position flag from a hero.
Func CancelHero($heroIndex)
	Local $agentID = GetHeroID($heroIndex)
	Return SendPacket(0x14, $HEADER_HERO_FLAG_SINGLE, $agentID, 0x7F800000, 0x7F800000, 0)
EndFunc


;~ Clear the full-party position flag.
Func CancelAll()
	Return SendPacket(0x10, $HEADER_HERO_FLAG_ALL, 0x7F800000, 0x7F800000, 0)
EndFunc


;~ Clear the position flag from all heroes.
Func CancelAllHeroes()
	For $heroIndex = 1 To GetHeroCount()
		CancelHero($heroIndex)
	Next
EndFunc


;~ Place a hero's position flag.
Func CommandHero($heroIndex, $X, $Y)
	Return SendPacket(0x14, $HEADER_HERO_FLAG_SINGLE, GetHeroID($heroIndex), FloatToInt($X), FloatToInt($Y), 0)
EndFunc


;~ Place the full-party position flag.
Func CommandAll($X, $Y)
	Return SendPacket(0x10, $HEADER_HERO_FLAG_ALL, FloatToInt($X), FloatToInt($Y), 0)
EndFunc


;~ Lock a hero onto a target.
Func LockHeroTarget($heroIndex, $agentID = 0)
	Local $heroID = GetHeroID($heroIndex)
	Return SendPacket(0xC, $HEADER_HERO_LOCK_TARGET, $heroID, $agentID)
EndFunc


;~ Change a hero's aggression level.
;~ 0=Fight, 1=Guard, 2=Avoid
Func SetHeroBehaviour($heroIndex, $aggressionLevel)
	Local $heroID = GetHeroID($heroIndex)
	Return SendPacket(0xC, $HEADER_HERO_BEHAVIOR, $heroID, $aggressionLevel)
EndFunc


;~ Disable all skills on a hero's skill bar.
Func DisableAllHeroSkills($heroIndex)
	For $i = 1 to 8
		DisableHeroSkillSlot($heroIndex, $i)
		Sleep(GetPing() + 20)
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


;~ Internal use for enabling or disabling hero skills
Func ToggleHeroSkillSlot($heroIndex, $skillSlot)
	Return SendPacket(0xC, $HEADER_HERO_SKILL_TOGGLE, GetHeroID($heroIndex), $skillSlot - 1)
EndFunc
#EndRegion H&H


#Region Movement
;~ Move to a location. Returns True if successful
Func Move($X, $Y, $random = 50)
	If GetAgentExists(GetMyID()) Then
		DllStructSetData($MOVE_STRUCT, 2, $X + Random(-$random, $random))
		DllStructSetData($MOVE_STRUCT, 3, $Y + Random(-$random, $random))
		Enqueue($MOVE_STRUCT_PTR, 16)
		Return True
	Else
		Return False
	EndIf
EndFunc


;~ Move to a location and wait until you reach it.
Func MoveTo($X, $Y, $random = 50, $doWhileRunning = Null)
	Local $blockedCount = 0
	Local $me
	Local $mapID = GetMapID(), $oldMapID
	Local $destinationX = $X + Random(-$random, $random)
	Local $destinationY = $Y + Random(-$random, $random)

	Move($destinationX, $destinationY, 0)

	Do
		Sleep(100)
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
	Until GetDistanceToPoint($me, $destinationX, $destinationY) < 25 Or $blockedCount > 14
EndFunc


;~ Run to or follow a player.
Func GoPlayer($agent)
	Return SendPacket(0x8, $HEADER_INTERACT_PLAYER , DllStructGetData($agent, 'ID'))
EndFunc


;~ Talk to an NPC
Func GoNPC($agent)
	Return SendPacket(0xC, $HEADER_INTERACT_NPC, DllStructGetData($agent, 'ID'))
EndFunc


;~ Run to a signpost.
Func GoSignpost($agent)
	Return SendPacket(0xC, $HEADER_SIGNPOST_RUN, DllStructGetData($agent, 'ID'), 0)
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
	Sleep(100)
	If $GoFunction <> Null Then $GoFunction($agent)
	Do
		Sleep(100)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') <= 0 Then ExitLoop
		$mapLoadingOld = $mapLoading
		$mapLoading = GetMapType()
		If $mapLoading <> $mapLoadingOld Then ExitLoop
		If Not IsPlayerMoving() Then
			$blockedCount += 1
			Move(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), 100)
			Sleep(100)
			If $GoFunction <> Null Then $GoFunction($agent)
		EndIf
	Until GetDistance($me, $agent) < 250 Or $blockedCount > 14
	Sleep(GetPing() + 1000)
EndFunc


;~ Attack an agent.
Func Attack($agent, $callTarget = False)
	Return SendPacket(0xC, $HEADER_ACTION_ATTACK, DllStructGetData($agent, 'ID'), $callTarget)
EndFunc


;~ Turn character to the left.
Func TurnLeft($turn)
	Return PerformAction(0xA2, $turn ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Turn character to the right.
Func TurnRight($turn)
	Return PerformAction(0xA3, $turn ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Move backwards.
Func MoveBackward($move)
	Return PerformAction(0xAC, $move ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Run forwards.
Func MoveForward($move)
	Return PerformAction(0xAD, $move ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Strafe to the left.
Func StrafeLeft($strafe)
	Return PerformAction(0x91, $strafe ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Strafe to the right.
Func StrafeRight($strafe)
	Return PerformAction(0x92, $strafe ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Auto-run.
Func ToggleAutoRun()
	Return PerformAction(0xB7)
EndFunc


;~ Turn around.
Func ReverseDirection()
	Return PerformAction(0xB1)
EndFunc
#EndRegion Movement


#Region Travel
;~ Internal use for map travel.
Func ZoneMap($mapID, $district = 0)
	MoveMap($mapID, GetRegion(), $district, GetLanguage())
EndFunc


;~ Internal use for map travel.
Func MoveMap($mapID, $region, $district, $language)
	Return SendPacket(0x18, $HEADER_MAP_TRAVEL, $mapID, $region, $district, $language, False)
EndFunc


;~ Returns to outpost after resigning/failure.
Func ReturnToOutpost()
	Return SendPacket(0x4, $HEADER_PARTY_RETURN_TO_OUTPOST)
EndFunc


;~ Enter a challenge mission/pvp.
Func EnterChallenge()
	Enqueue($ENTER_MISSION_STRUCT_PTR, 4)
EndFunc


;~ Enter a foreign challenge mission/pvp.
Func EnterChallengeForeign()
	Return SendPacket(0x8, $HEADER_PARTY_ENTER_FOREIGN_MISSION, 0)
EndFunc


;~ Travel to your guild hall.
Func TravelGuildHall()
	Local $offset[3] = [0, 0x18, 0x3C]
	Local $guildHall = MemoryReadPtr($base_address_ptr, $offset)
	SendPacket(0x18, $HEADER_GUILDHALL_TRAVEL, MemoryRead($guildHall[1] + 0x64), MemoryRead($guildHall[1] + 0x68), MemoryRead($guildHall[1] + 0x6C), MemoryRead($guildHall[1] + 0x70), 1)
	Return WaitMapLoading()
EndFunc


;~ Leave your guild hall.
Func LeaveGuildHall()
	SendPacket(0x8, $HEADER_GUILDHALL_LEAVE, 1)
	Return WaitMapLoading()
EndFunc


;~ Wait for map to be loaded, True if map loaded correctly, False otherwise
Func WaitMapLoading($mapID = -1, $deadlockTime = 10000, $waitingTime = 2500)
	Local $offset[5] = [0, 0x18, 0x2C, 0x6F0, 0xBC]
	Local $deadlock = TimerInit()
	Local $skillbarStruct
	Do
		Sleep(200)
		$skillbarStruct = MemoryReadPtr($base_address_ptr, $offset, 'ptr')
		If $skillbarStruct[0] = 0 Then $deadlock = TimerInit()
		If TimerDiff($deadlock) > $deadlockTime And $deadlockTime > 0 Then Return False
	Until GetMyID() <> 0 And $skillbarStruct[0] <> 0 And (GetMapID() = $mapID Or $mapID = -1)
	RandomSleep($waitingTime)
	Return True
EndFunc
#EndRegion Travel


#Region Quest
;~ Accept a quest from an NPC.
Func AcceptQuest($questID)
	Return SendPacket(0x8, $HEADER_DIALOG_SEND, '0x008' & Hex($questID, 3) & '01')
EndFunc


;~ Accept the reward for a quest.
Func QuestReward($questID)
	Return SendPacket(0x8, $HEADER_DIALOG_SEND, '0x008' & Hex($questID, 3) & '07')
EndFunc


;~ Abandon a quest.
Func AbandonQuest($questID)
	Return SendPacket(0x8, $HEADER_QUEST_ABANDON, $questID)
EndFunc
#EndRegion Quest


#Region Windows
;~ Close all in-game windows.
Func CloseAllPanels()
	Return PerformAction(0x85)
EndFunc


;~ Toggle hero window.
Func ToggleHeroWindow()
	Return PerformAction(0x8A)
EndFunc


;~ Toggle inventory window.
Func ToggleInventory()
	Return PerformAction(0x8B)
EndFunc


;~ Toggle all bags window.
Func ToggleAllBags()
	Return PerformAction(0xB8)
EndFunc


;~ Toggle world map.
Func ToggleWorldMap()
	Return PerformAction(0x8C)
EndFunc


;~ Toggle options window.
Func ToggleOptions()
	Return PerformAction(0x8D)
EndFunc


;~ Toggle quest window.
Func ToggleQuestWindow()
	Return PerformAction(0x8E)
EndFunc


;~ Toggle skills window.
Func ToggleSkillWindow()
	Return PerformAction(0x8F)
EndFunc


;~ Toggle mission map.
Func ToggleMissionMap()
	Return PerformAction(0xB6)
EndFunc


;~ Toggle friends list window.
Func ToggleFriendList()
	Return PerformAction(0xB9)
EndFunc


;~ Toggle guild window.
Func ToggleGuildWindow()
	Return PerformAction(0xBA)
EndFunc


;~ Toggle party window.
Func TogglePartyWindow()
	Return PerformAction(0xBF)
EndFunc


;~ Toggle score chart.
Func ToggleScoreChart()
	Return PerformAction(0xBD)
EndFunc


;~ Toggle layout window.
Func ToggleLayoutWindow()
	Return PerformAction(0xC1)
EndFunc


;~ Toggle minions window.
Func ToggleMinionList()
	Return PerformAction(0xC2)
EndFunc


;~ Toggle a hero panel.
Func ToggleHeroPanel($hero)
	Return PerformAction(($hero < 4 ? 0xDB : 0xFE) + $hero)
EndFunc


;~ Toggle hero's pet panel.
Func ToggleHeroPetPanel($hero)
	Return PerformAction(($hero < 4 ? 0xDF : 0xFA) + $hero)
EndFunc


;~ Toggle pet panel.
Func TogglePetPanel()
	Return PerformAction(0xDF)
EndFunc


;~ Toggle help window.
Func ToggleHelpWindow()
	Return PerformAction(0xE4)
EndFunc
#EndRegion Windows


#Region Targeting
;~ Target an agent.
Func ChangeTarget($agent)
	DllStructSetData($CHANGE_TARGET_STRUCT, 2, DllStructGetData($agent, 'ID'))
	Enqueue($CHANGE_TARGET_STRUCT_PTR, 8)
EndFunc


;~ Call target.
Func CallTarget($target)
	Return SendPacket(0xC, $HEADER_CALL_TARGET, 0xA, DllStructGetData($target, 'ID'))
EndFunc


;~ Clear current target.
Func ClearTarget()
	Return PerformAction(0xE3)
EndFunc


;~ Target the nearest enemy.
Func TargetNearestEnemy()
	Return PerformAction(0x93)
EndFunc


;~ Target the next enemy.
Func TargetNextEnemy()
	Return PerformAction(0x95)
EndFunc


;~ Target the next party member.
Func TargetPartyMember($partyMemberIndex)
	If $partyMemberIndex > 0 And $partyMemberIndex < 13 Then Return PerformAction(0x95 + $partyMemberIndex)
EndFunc


;~ Target the previous enemy.
Func TargetPreviousEnemy()
	Return PerformAction(0x9E)
EndFunc


;~ Target the called target.
Func TargetCalledTarget()
	Return PerformAction(0x9F)
EndFunc


;~ Target yourself.
Func TargetSelf()
	Return PerformAction(0xA0)
EndFunc


;~ Target the nearest ally.
Func TargetNearestAlly()
	Return PerformAction(0xBC)
EndFunc


;~ Target the nearest item.
Func TargetNearestItem()
	Return PerformAction(0xC3)
EndFunc


;~ Target the next item.
Func TargetNextItem()
	Return PerformAction(0xC4)
EndFunc


;~ Target the previous item.
Func TargetPreviousItem()
	Return PerformAction(0xC5)
EndFunc


;~ Target the next party member.
Func TargetNextPartyMember()
	Return PerformAction(0xCA)
EndFunc


;~ Target the previous party member.
Func TargetPreviousPartyMember()
	Return PerformAction(0xCB)
EndFunc
#EndRegion Targeting


#Region Display
;~ Enable graphics rendering.
Func EnableRendering($showWindow = True)
	Local $windowHandle = GetWindowHandle(), $prevGwState = WinGetState($windowHandle), $previousWindow = WinGetHandle('[ACTIVE]', ''), $previousWindowState = WinGetState($previousWindow)
	If $showWindow And $prevGwState Then
		If BitAND($prevGwState, 0x10) Then
			WinSetState($windowHandle, '', @SW_RESTORE)
		ElseIf Not BitAND($prevGwState, 0x02) Then
			WinSetState($windowHandle, '', @SW_SHOW)
		EndIf
		If $windowHandle <> $previousWindow And $previousWindow Then RestoreWindowState($previousWindow, $previousWindowState)
	EndIf
	If Not GetIsRendering() Then
		If Not MemoryWrite($disable_rendering_address, 0) Then Return SetError(@error, False)
		Sleep(250)
	EndIf
	Return 1
EndFunc


;~ Disable graphics rendering.
Func DisableRendering($hideWindow = True)
	Local $windowHandle = GetWindowHandle()
	If $hideWindow And WinGetState($windowHandle) Then WinSetState($windowHandle, '', @SW_HIDE)
	If GetIsRendering() Then
		If Not MemoryWrite($disable_rendering_address, 1) Then Return SetError(@error, False)
		Sleep(250)
	EndIf
	Return 1
EndFunc


;~ Toggles graphics rendering
Func ToggleRendering()
	Return $rendering_enabled ? EnableRendering() : DisableRendering()
EndFunc


;~ Returns True if the game is being rendered
Func GetIsRendering()
	Return MemoryRead($disable_rendering_address) <> 1
EndFunc


;~ Internally used - restores a window to previous state.
Func RestoreWindowState($windowHandle, $previousWindowState)
	If Not $windowHandle Or Not $previousWindowState Then Return 0

	Local $currentWindowState = WinGetState($windowHandle)
	; SW_HIDE, SW_SHOWNORMAL, SW_SHOWMINIMIZED, SW_SHOWMAXIMIZED, SW_MINIMIZE, SW_RESTORE
	Local $states = [1, 2, 4, 8, 16, 32]
	For $state In $states
		If BitAND($previousWindowState, $state) And Not BitAND($currentWindowState, $state) Then WinSetState($windowHandle, '', $state)
	Next
EndFunc

;~ Display all names.
Func DisplayAll($display)
	DisplayAllies($display)
	DisplayEnemies($display)
EndFunc


;~ Display the names of allies.
Func DisplayAllies($display)
	Return PerformAction(0x89, $display ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Display the names of enemies.
Func DisplayEnemies($display)
	Return PerformAction(0x94, $display ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc
#EndRegion Display


#Region Chat
;~ Write a message in chat (can only be seen by user).
Func WriteChat($message, $sender = 'GWA2')
	Local $address = 256 * $queue_counter + $queue_base_address
	; FIXME: rewrite with modulo
	$queue_counter = $queue_counter = $queue_size ? 0 : $queue_counter + 1
	If StringLen($sender) > 19 Then $sender = StringLeft($sender, 19)

	MemoryWrite($address + 4, $sender, 'wchar[20]')

	If StringLen($message) > 100 Then $message = StringLeft($message, 100)

	MemoryWrite($address + 44, $message, 'wchar[101]')
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', GetProcessHandle(), 'int', $address, 'ptr', $WRITE_CHAT_STRUCT_PTR, 'int', 4, 'int', 0)

	If StringLen($message) > 100 Then WriteChat(StringTrimLeft($message, 100), $sender)
EndFunc


;~ Send a whisper to another player.
Func SendWhisper($receiver, $message)
	Local $total = 'whisper ' & $receiver & ',' & $message
	If StringLen($total) > 120 Then
		$message = StringLeft($total, 120)
	Else
		$message = $total
	EndIf
	SendChat($message, '/')
	If StringLen($total) > 120 Then SendWhisper($receiver, StringTrimLeft($total, 120))
EndFunc


;~ Send a message to chat.
Func SendChat($message, $channel = '!')
	Local $address = 256 * $queue_counter + $queue_base_address
	; FIXME: rewrite with modulo
	$queue_counter = $queue_counter = $queue_size ? 0 : $queue_counter + 1
	If StringLen($message) > 120 Then $message = StringLeft($message, 120)

	MemoryWrite($address + 12, $channel & $message, 'wchar[122]')
	SafeDllCall13($kernel_handle, 'int', 'WriteProcessMemory', 'int', GetProcessHandle(), 'int', $address, 'ptr', $SEND_CHAT_STRUCT_PTR, 'int', 8, 'int', 0)

	If StringLen($message) > 120 Then SendChat(StringTrimLeft($message, 120), $channel)
EndFunc


;~ Internal use only.
Func ProcessChatMessage($chatLogStruct)
	Local $messageType = DllStructGetData($chatLogStruct, 1)
	Local $message = DllStructGetData($chatLogStruct, 'message[512]')
	Local $channel = 'Unknown'
	Local $sender = 'Unknown'

	Switch $messageType
		Case 0
			$channel = 'Alliance'
		Case 3
			$channel = 'All'
		Case 9
			$channel = 'Guild'
		Case 11
			$channel = 'Team'
		Case 12
			$channel = 'Trade'
		Case 10
			If StringLeft($message, 3) == '-> ' Then
				$channel = 'Sent'
			Else
				$channel = 'Global'
				$sender = 'Guild Wars'
			EndIf
		Case 13
			$channel = 'Advisory'
			$sender = 'Guild Wars'
		Case 14
			$channel = 'Whisper'
		Case Else
			$channel = 'Other'
			$sender = 'Other'
	EndSwitch

	If $channel <> 'Global' And $channel <> 'Advisory' And $channel <> 'Other' Then
		$sender = StringMid($message, 6, StringInStr($message, '</a>') - 6)
		$message = StringTrimLeft($message, StringInStr($message, '<quote>') + 6)
	EndIf

	If $channel == 'Sent' Then
		$sender = StringMid($message, 10, StringInStr($message, '</a>') - 10)
		$message = StringTrimLeft($message, StringInStr($message, '<quote>') + 6)
	EndIf
EndFunc
#EndRegion Chat


#Region Misc
;~ Change weapon sets.
Func ChangeWeaponSet($weaponSet)
	Return PerformAction(0x80 + $weaponSet)
EndFunc


Func GetCastTimeModifier($effects, $usedSkill)
	Local $skillID = DllStructGetData($usedSkill, 'ID')
	Local $effectID = 0
	Local $castTime = 1
	For $effect in $effects
		$effectID = DllStructGetData($effect, 'EffectId')
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


;~ Use a skill, doesn't wait for the skill to be done
;~ If no target is provided then skill is used on self
Func UseSkill($skillSlot, $target = Null, $callTarget = False)
	Local $targetId = ($target == Null) ? GetMyID() : DllStructGetData($target, 'ID')
	DllStructSetData($USE_SKILL_STRUCT, 2, $skillSlot)
	DllStructSetData($USE_SKILL_STRUCT, 3, $targetId)
	DllStructSetData($USE_SKILL_STRUCT, 4, $callTarget)
	Enqueue($USE_SKILL_STRUCT_PTR, 16)
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
	Until Not IsRecharged($skillSlot) Or ($approximateCastTime > 0 And TimerDiff($castTimer) > $approximateCastTime)
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
	Local $fullCastTime = $castTimeModifier * $castTime + $aftercast + GetPing()

	; when player casts a skill on target that is beyond cast range then trying to get close to target first to not count time on the run
	If $target <> Null And GetDistance(GetMyAgent(), $target) > ($RANGE_SPELLCAST + 100) Then GetAlmostInRangeOfAgent($target)
	UseSkill($skillSlot, $target)
	Local $castTimer = TimerInit()
	; wait until skill starts recharging or time for skill to be fully activated has elapsed
	Do
		Sleep(50 + GetPing())
	Until (Not IsRecharged($skillSlot)) Or ($fullCastTime < TimerDiff($castTimer))
	Return True
EndFunc


;~ Order a hero to use a skill, doesn't wait for the skill to be done
;~ If no target is provided then skill is used on hero who uses the skill
Func UseHeroSkill($heroIndex, $skillSlot, $target = Null)
	Local $targetId = ($target == Null) ? GetHeroID($heroIndex) : DllStructGetData($target, 'ID')
	DllStructSetData($USE_HERO_SKILL_STRUCT, 2, GetHeroID($heroIndex))
	DllStructSetData($USE_HERO_SKILL_STRUCT, 3, $targetId)
	DllStructSetData($USE_HERO_SKILL_STRUCT, 4, $skillSlot - 1)
	Enqueue($USE_HERO_SKILL_STRUCT_PTR, 16)
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
	Local $approximateCastTime = $castTime + $aftercast + GetPing()

	UseHeroSkill($heroIndex, $skillSlot, $target)
	Local $castTimer = TimerInit()
	; Wait until skill starts recharging or time for skill to be activated has elapsed
	Do
		Sleep(50 + GetPing())
	Until (Not IsRecharged($skillSlot)) Or ($approximateCastTime < TimerDiff($castTimer))
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
	Local $fullCastTime = $castTimeModifier * $castTime + $aftercast + GetPing()

	UseHeroSkill($heroIndex, $skillSlot, $target)
	Local $castTimer = TimerInit()
	; wait until skill starts recharging or time for skill to be fully activated has elapsed
	Do
		Sleep(50 + GetPing())
	Until (Not IsRecharged($skillSlot)) Or ($fullCastTime < TimerDiff($castTimer))
	Return True
EndFunc


;~ Returns True if the skill at the skillslot given is recharged
Func IsRecharged($skillSlot, $heroIndex = 0)
	Return GetSkillbarSkillRecharge($skillSlot, $heroIndex) == 0
EndFunc


;~ Cancel current action.
Func CancelAction()
	Return SendPacket(0x4, $HEADER_ACTION_CANCEL)
EndFunc


;~ Same as hitting spacebar.
Func ActionInteract()
	Return PerformAction(0x80)
EndFunc


;~ Follow a player.
Func ActionFollow()
	Return PerformAction(0xCC)
EndFunc


;~ Drop environment object.
Func DropBundle()
	Return PerformAction(0xCD)
EndFunc


;~ Clear all hero flags.
Func ClearPartyCommands()
	Return PerformAction(0xDB)
EndFunc


;~ Suppress action.
Func SuppressAction($suppressAction)
	Return PerformAction(0xD0, $suppressAction ? $CONTROL_TYPE_ACTIVATE : $CONTROL_TYPE_DEACTIVATE)
EndFunc


;~ Open a chest.
Func OpenChest()
	Return SendPacket(0x8, $HEADER_OPEN_CHEST, 2)
EndFunc


;~ Stop maintaining enchantment on target.
Func DropBuff($skillID, $agent, $heroIndex = 0)
	Local $buffCount = GetBuffCount($heroIndex)
	Local $buffStructAddress
	Local $offset1[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($base_address_ptr, $offset1)

	Local $buffer
	Local $offset2[5] = [0, 0x18, 0x2C, 0x508, 0]
	Local $buffStruct = SafeDllStructCreate($BUFF_STRUCT_TEMPLATE)
	Local $processHandle = GetProcessHandle()
	For $i = 0 To $count[1] - 1
		$offset2[4] = 0x24 * $i
		$buffer = MemoryReadPtr($base_address_ptr, $offset2)
		If $buffer[1] == GetHeroID($heroIndex) Then
			Local $offset3[6] = [0, 0x18, 0x2C, 0x508, 0x4 + 0x24 * $i, 0]
			For $j = 0 To $buffCount - 1
				$offset3[5] = 0 + 0x10 * $j
				$buffStructAddress = MemoryReadPtr($base_address_ptr, $offset3)
				SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $buffStructAddress[0], 'ptr', DllStructGetPtr($buffStruct), 'int', DllStructGetSize($buffStruct), 'int', 0)
				If (DllStructGetData($buffStruct, 'SkillID') == $skillID) And (DllStructGetData($buffStruct, 'TargetId') == DllStructGetData($agent, 'ID')) Then
					Return SendPacket(0x8, $HEADER_BUFF_DROP, DllStructGetData($buffStruct, 'BuffId'))
					ExitLoop 2
				EndIf
			Next
		EndIf
	Next
EndFunc


;~ Take a screenshot.
Func MakeScreenshot()
	Return PerformAction(0xAE)
EndFunc


;~ Invite a player to the party.
Func InvitePlayer($playerName)
	SendChat('invite ' & $playerName, '/')
EndFunc


;~ Leave your party.
Func LeaveParty($kickHeroes = True)
	If $kickHeroes Then KickAllHeroes()
	SendPacket(0x4, $HEADER_PARTY_LEAVE)
	Sleep(100)
EndFunc


;~ Switches to/from Hard Mode.
Func SwitchMode($mode)
	Return SendPacket(0x8, $HEADER_SET_DIFFICULTY, $mode)
EndFunc


;~ Resign.
Func Resign()
	SendChat('resign', '/')
EndFunc


;~ Donate Kurzick or Luxon faction.
Func DonateFaction($faction)
	Return SendPacket(0x10, $HEADER_FACTION_DEPOSIT, 0, StringLeft($faction, 1) = 'k' ? 0 : 1, 5000)
EndFunc


;~ Open a dialog.
Func Dialog($dialogID)
	Return SendPacket(0x8, $HEADER_DIALOG_SEND, $dialogID)
EndFunc


;~ Skip a cinematic.
Func SkipCinematic()
	Return SendPacket(0x4, $HEADER_CINEMATIC_SKIP)
EndFunc


;~ Change a skill on the skillbar.
Func SetSkillbarSkill($slot, $skillID, $heroIndex = 0)
	Return SendPacket(0x14, $HEADER_SET_SKILLBAR_SKILL, GetHeroID($heroIndex), $slot - 1, $skillID, 0)
EndFunc


;~ Load all skills onto a skillbar simultaneously.
Func LoadSkillBar($skill1 = 0, $skill2 = 0, $skill3 = 0, $skill4 = 0, $skill5 = 0, $skill6 = 0, $skill7 = 0, $skill8 = 0, $heroIndex = 0)
	SendPacket(0x2C, $HEADER_LOAD_SKILLBAR, GetHeroID($heroIndex), 8, $skill1, $skill2, $skill3, $skill4, $skill5, $skill6, $skill7, $skill8)
EndFunc


;~ Increase attribute by 1
Func IncreaseAttribute($attributeID, $heroIndex = 0)
	DllStructSetData($INCREASE_ATTRIBUTE_STRUCT, 2, $attributeID)
	DllStructSetData($INCREASE_ATTRIBUTE_STRUCT, 3, GetHeroID($heroIndex))
	Enqueue($INCREASE_ATTRIBUTE_STRUCT_PTR, 12)
EndFunc


;~ Decrease attribute by 1
Func DecreaseAttribute($attributeID, $heroIndex = 0)
	DllStructSetData($DECREASE_ATTRIBUTE_STRUCT, 2, $attributeID)
	DllStructSetData($DECREASE_ATTRIBUTE_STRUCT, 3, GetHeroID($heroIndex))
	Enqueue($DECREASE_ATTRIBUTE_STRUCT_PTR, 12)
EndFunc


;~ Set all attributes to 0
Func ClearAttributes($heroIndex = 0)
	Local $level
	If GetMapType() <> $ID_OUTPOST Then Return False
	For $i = 0 To UBound($ATTRIBUTES_ARRAY) - 1
		Local $attributeID = $ATTRIBUTES_ARRAY[$i]
		If GetAttributeByID($attributeID, False, $heroIndex) > 0 Then
			Do
				$level = GetAttributeByID($attributeID, False, $heroIndex)
				$deadlock = TimerInit()
				DecreaseAttribute($attributeID, $heroIndex)
				Do
					Sleep(20)
				Until $level > GetAttributeByID($attributeID, False, $heroIndex) Or TimerDiff($deadlock) > 5000
				Sleep(100)
			Until GetAttributeByID($attributeID, False, $heroIndex) == 0
		EndIf
	Next
	Return True
EndFunc


;~ Change your secondary profession.
Func ChangeSecondProfession($profession, $heroIndex = 0)
	Return SendPacket(0xC, $HEADER_PROFESSION_CHANGE, GetHeroID($heroIndex), $profession)
EndFunc


;~ Changes game language to english.
Func EnsureEnglish($ensureEnglish)
	MemoryWrite($force_english_language_flag, $ensureEnglish ? 1 : 0)
EndFunc


;~ Change game language.
Func ToggleLanguage()
	DllStructSetData($TOGGLE_LANGUAGE_STRUCT, 2, 0x18)
	Enqueue($TOGGLE_LANGUAGE_STRUCT_PTR, 8)
EndFunc


;~ Changes the maximum distance you can zoom out.
Func ChangeMaxZoom($zoom = 750)
	MemoryWrite($zoom_when_still, $zoom, 'float')
	MemoryWrite($zoom_when_moving, $zoom, 'float')
EndFunc
#EndRegion Misc


;~ Converts float to integer.
Func FloatToInt($float)
	Local $floatStruct = SafeDllStructCreate('float')
	Local $int = SafeDllStructCreate('int', DllStructGetPtr($floatStruct))
	DllStructSetData($floatStruct, 1, $float)
	Return DllStructGetData($int, 1)
EndFunc
#EndRegion Commands


#Region Queries
#Region Titles
;~ Set a title on
Func SetDisplayedTitle($title = 0)
	If $title Then
		Return SendPacket(0x8, $HEADER_TITLE_DISPLAY, $title)
	Else
		Return SendPacket(0x4, $HEADER_TITLE_HIDE)
	EndIf
EndFunc


;~ Set the title to Spearmarshall
Func SetTitleSpearmarshall()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_SUNSPEAR_TITLE)
EndFunc


;~ Set the title to Lightbringer
Func SetTitleLightbringer()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_LIGHTBRINGER_TITLE)
EndFunc


;~ Set the title to Asuran
Func SetTitleAsuran()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_ASURA_TITLE)
EndFunc


;~ Set the title to Dwarven
Func SetTitleDwarven()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_DWARF_TITLE)
EndFunc


;~ Set the title to Ebon Vanguard
Func SetTitleEbonVanguard()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_EBON_VANGUARD_TITLE)
EndFunc


;~ Set the title to Norn
Func SetTitleNorn()
	SendPacket(0x8, $HEADER_TITLE_DISPLAY, $ID_NORN_TITLE)
EndFunc


;~ Returns title progress by title index.
Func GetTitleByIndex($titleIndex)
	Static $TITLE_BASE_OFFSET = 0x04
	Static $TITLE_STRUCT_SIZE = 0x2C
	Return GetTitleProgress($TITLE_BASE_OFFSET + ($titleIndex * $TITLE_STRUCT_SIZE))
EndFunc


;~ Return title progression - common part for most titles
Func GetTitleProgress($finalOffset)
	Local $offset[5] = [0, 0x18, 0x2C, 0x81C, $finalOffset]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns Hero title progress.
Func GetHeroTitle()
	Return GetTitleByIndex(0)
EndFunc


;~ Returns Gladiator title progress.
Func GetGladiatorTitle()
	Return GetTitleByIndex(3)
EndFunc


;~ Returns Kurzick title progress.
Func GetKurzickTitle()
	Return GetTitleByIndex(5)
EndFunc


;~ Returns Luxon title progress.
Func GetLuxonTitle()
	Return GetTitleByIndex(6)
EndFunc


;~ Returns drunkard title progress.
Func GetDrunkardTitle()
	Return GetTitleByIndex(7)
EndFunc


;~ Returns survivor title progress.
Func GetSurvivorTitle()
	Return GetTitleByIndex(9)
EndFunc


;~ Returns max titles
Func GetMaxTitles()
	Return GetTitleByIndex(10)
EndFunc


;~ Returns lucky title progress.
Func GetLuckyTitle()
	Return GetTitleByIndex(15)
EndFunc


;~ Returns unlucky title progress.
Func GetUnluckyTitle()
	Return GetTitleByIndex(16)
EndFunc


;~ Returns Sunspear title progress.
Func GetSunspearTitle()
	Return GetTitleByIndex(17)
EndFunc


;~ Returns Lightbringer title progress.
Func GetLightbringerTitle()
	Return GetTitleByIndex(20)
EndFunc


;~ Returns Commander title progress.
Func GetCommanderTitle()
	Return GetTitleByIndex(22)
EndFunc


;~ Returns Gamer title progress.
Func GetGamerTitle()
	Return GetTitleByIndex(23)
EndFunc


;~ Returns Legendary Guardian title progress.
Func GetLegendaryGuardianTitle()
	Return GetTitleByIndex(31)
EndFunc


;~ Returns sweets title progress.
Func GetSweetTitle()
	Return GetTitleByIndex(34)
EndFunc


;~ Returns Asura title progress.
Func GetAsuraTitle()
	Return GetTitleByIndex(38)
EndFunc


;~ Returns Deldrimor title progress.
Func GetDeldrimorTitle()
	Return GetTitleByIndex(39)
EndFunc


;~ Returns Vanguard title progress.
Func GetVanguardTitle()
	Return GetTitleByIndex(40)
EndFunc


;~ Returns Norn title progress.
Func GetNornTitle()
	Return GetTitleByIndex(41)
EndFunc


;~ Returns mastery of the north title progress.
Func GetNorthMasteryTitle()
	Return GetTitleByIndex(42)
EndFunc


;~ Returns party title progress.
Func GetPartyTitle()
	Return GetTitleByIndex(43)
EndFunc


;~ Returns Zaishen title progress.
Func GetZaishenTitle()
	Return GetTitleByIndex(44)
EndFunc


;~ Returns treasure hunter title progress.
Func GetTreasureTitle()
	Return GetTitleByIndex(45)
EndFunc


;~ Returns wisdom title progress.
Func GetWisdomTitle()
	Return GetTitleByIndex(46)
EndFunc


;~ Returns Codex title progress.
Func GetCodexTitle()
	Return GetTitleByIndex(47)
EndFunc


;~ Returns current Tournament points.
Func GetTournamentPoints()
	Local $offset[5] = [0, 0x18, 0x2C, 0, 0x18]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc
#EndRegion Titles

#Region Faction
;~ Returns current Kurzick faction.
Func GetKurzickFaction()
	Return GetFaction(0x748)
EndFunc


;~ Returns max Kurzick faction.
Func GetMaxKurzickFaction()
	Return GetFaction(0x7B8)
EndFunc


;~ Returns current Luxon faction.
Func GetLuxonFaction()
	Return GetFaction(0x758)
EndFunc


;~ Returns max Luxon faction.
Func GetMaxLuxonFaction()
	Return GetFaction(0x7BC)
EndFunc


;~ Returns current Balthazar faction.
Func GetBalthazarFaction()
	Return GetFaction(0x798)
EndFunc


;~ Returns max Balthazar faction.
Func GetMaxBalthazarFaction()
	Return GetFaction(0x7C0)
EndFunc


;~ Returns current Imperial faction.
Func GetImperialFaction()
	Return GetFaction(0x76C)
EndFunc


;~ Returns max Imperial faction.
Func GetMaxImperialFaction()
	Return GetFaction(0x7C4)
EndFunc


;~ Returns the faction points depending on the offset provided
Func GetFaction($finalOffset)
	Local $offset[4] = [0, 0x18, 0x2C, $finalOffset]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc
#EndRegion Faction


#Region Item
;~ Returns rarity (name color) of an item.
Func GetRarity($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $ptr = DllStructGetData($item, 'NameString')
	If $ptr == 0 Then Return
	Return MemoryRead($ptr, 'ushort')
EndFunc


;~ Tests if an item is identified.
Func GetIsIdentified($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Return BitAND(DllStructGetData($item, 'Interaction'), 0x1) > 0
EndFunc


;~ Tests if an item is unidentified.
Func GetIsUnidentified($item)
	Return Not GetIsIdentified($item)
EndFunc


;~ Returns if material is rare.
Func GetIsRareMaterial($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	If DllStructGetData($item, 'Type') <> 11 Then Return False
	Return Not GetIsCommonMaterial($item)
EndFunc


;~ Returns if material is Common.
Func GetIsCommonMaterial($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Return BitAND(DllStructGetData($item, 'Interaction'), 0x20) <> 0
EndFunc


;~ Returns a weapon or shield's minimum required attribute.
Func GetItemReq($item)
	Local $mod = GetModByIdentifier($item, '9827')
	Return $mod[0]
EndFunc


;~ Returns a weapon or shield's required attribute.
Func GetItemAttribute($item)
	Local $mod = GetModByIdentifier($item, '9827')
	Return $mod[1]
EndFunc


;~ Returns an array of a the requested mod.
Func GetModByIdentifier($item, $identifier)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $result[2]
	Local $string = StringTrimLeft(GetModStruct($item), 2)
	For $i = 0 To StringLen($string) / 8 - 2
		If StringMid($string, 8 * $i + 5, 4) == $identifier Then
			$result[0] = Int('0x' & StringMid($string, 8 * $i + 1, 2))
			$result[1] = Int('0x' & StringMid($string, 8 * $i + 3, 2))
			ExitLoop
		EndIf
	Next
	Return $result
EndFunc


;~ Returns modstruct of an item.
Func GetModStruct($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $modstruct = DllStructGetData($item, 'modstruct')
	If $modstruct = 0 Then Return
	Return MemoryRead($modstruct, 'Byte[' & DllStructGetData($item, 'modstructsize') * 4 & ']')
EndFunc


;~ Returns struct of an inventory bag.
Func GetBag($bag)
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x4 * $bag]
	Local $bagPtr = MemoryReadPtr($base_address_ptr, $offset)
	If $bagPtr[1] = 0 Then Return
	Local $bagStruct = SafeDllStructCreate($BAG_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $bagPtr[1], 'ptr', DllStructGetPtr($bagStruct), 'int', DllStructGetSize($bagStruct), 'int', 0)
	Return $bagStruct
EndFunc


;~ Returns item by slot.
Func GetItemBySlot($bag, $slot)
	If Not IsDllStruct($bag) Then $bag = GetBag($bag)

	Local $itemPtr = DllStructGetData($bag, 'ItemArray')
	Local $buffer = SafeDllStructCreate('ptr')
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $itemPtr + 4 * ($slot - 1), 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)

	Local $memoryInfo = DllStructCreate($MEMORY_INFO_STRUCT_TEMPLATE)
	SafeDllCall11($kernel_handle, 'int', 'VirtualQueryEx', 'int', GetProcessHandle(), 'int', DllStructGetData($buffer, 1), 'ptr', DllStructGetPtr($memoryInfo), 'int', DllStructGetSize($memoryInfo))
	If DllStructGetData($memoryInfo, 'State') <> 0x1000 Then Return 0

	Local $itemStruct = SafeDllStructCreate($ITEM_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', DllStructGetData($buffer, 1), 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', 0)
	Return $itemStruct
EndFunc


;~ Returns item struct.
Func GetItemByItemID($itemID)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0x4 * $itemID]
	Local $itemPtr = MemoryReadPtr($base_address_ptr, $offset)
	Local $itemStruct = SafeDllStructCreate($ITEM_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', 0)
	Return $itemStruct
EndFunc


;~ Returns item by agent ID.
Func GetItemByAgentID($agentID)
	Local $offset[4] = [0, 0x18, 0x40, 0xC0]
	Local $itemArraySize = MemoryReadPtr($base_address_ptr, $offset)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0]
	Local $itemPtr, $itemID
	Local $processHandle = GetProcessHandle()

	For $itemID = 1 To $itemArraySize[1]
		$offset[4] = 0x4 * $itemID
		$itemPtr = MemoryReadPtr($base_address_ptr, $offset)
		If $itemPtr[1] = 0 Then ContinueLoop
		Local $itemStruct = SafeDllStructCreate($ITEM_STRUCT_TEMPLATE)
		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', $processHandle, 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', 0)
		If DllStructGetData($itemStruct, 'AgentID') = $agentID Then
			Return $itemStruct
		EndIf
	Next
EndFunc


;~ Returns item by model ID.
Func GetItemByModelID($modelID)
	Local $offset[4] = [0, 0x18, 0x40, 0xC0]
	Local $itemArraySize = MemoryReadPtr($base_address_ptr, $offset)
	Local $offset[5] = [0, 0x18, 0x40, 0xB8, 0]
	Local $itemPtr, $itemID

	For $itemID = 1 To $itemArraySize[1]
		$offset[4] = 0x4 * $itemID
		$itemPtr = MemoryReadPtr($base_address_ptr, $offset)
		If $itemPtr[1] = 0 Then ContinueLoop
		Local $itemStruct = SafeDllStructCreate($ITEM_STRUCT_TEMPLATE)
		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $itemPtr[1], 'ptr', DllStructGetPtr($itemStruct), 'int', DllStructGetSize($itemStruct), 'int', 0)
		If DllStructGetData($itemStruct, 'ModelID') == $modelID Then Return $itemStruct
	Next
	Return Null
EndFunc


;~ Returns the nearest item by model ID to an agent.
Func GetNearestItemByModelIDToAgent($modelID, $agent)
	Local $nearestItemAgent, $nearestDistance = 100000000
	Local $distance
	If GetMaxAgents() > 0 Then
		For $i = 1 To GetMaxAgents()
			Local $itemAgent = GetAgentByID($i)
			If Not IsItemAgentType($itemAgent) Then ContinueLoop
			Local $agentModelID = DllStructGetData(GetItemByAgentID($i), 'ModelID')
			If $agentModelID = $modelID Then
				$distance = GetDistance($itemAgent, $agent)
				If $distance < $nearestDistance Then
					$nearestItemAgent = $itemAgent
					$nearestDistance = $distance
				EndIf
			EndIf
		Next
		Return $nearestItemAgent
	EndIf
EndFunc

;~ Returns amount of gold in storage.
Func GetGoldStorage()
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x94]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns amount of gold being carried.
Func GetGoldCharacter()
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x90]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns the item ID of the quoted item.
Func GetTraderCostID()
	Return MemoryRead($trader_cost_ID)
EndFunc


;~ Returns the cost of the requested item.
Func GetTraderCostValue()
	Return MemoryRead($trader_cost_value)
EndFunc


;~ Internal use for BuyItem()
Func GetMerchantItemsBase()
	Local $offset[4] = [0, 0x18, 0x2C, 0x24]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Internal use for BuyItem()
Func GetMerchantItemsSize()
	Local $offset[4] = [0, 0x18, 0x2C, 0x28]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns pointer to the bag at the bag index provided
Func GetBagPtr($bagIndex)
	Local $offset[5] = [0, 0x18, 0x40, 0xF8, 0x4 * $bagIndex]
	Local $itemStructAddress = MemoryReadPtr($base_address_ptr, $offset, 'ptr')
	Return $itemStructAddress[1]
EndFunc


;~ Returns pointer to the item at the slot provided
Func GetItemPtrBySlot($bag, $slot)
	Local $bagPtr = Null
	If IsPtr($bag) Then
		$bagPtr = $bag
	Else
		If $bag < 1 Or $bag > 17 Then Return 0
		If $slot < 1 Or $slot > GetMaxSlots($bag) Then Return 0
		$bagPtr = GetBagPtr($bag)
	EndIf
	Local $itemArrayPtr = MemoryRead($bagPtr + 24, 'ptr')
	Return MemoryRead($itemArrayPtr + 4 * ($slot - 1), 'ptr')
EndFunc


;~ Returns amount of slots of bag.
Func GetMaxSlots($bag)
	If IsPtr($bag) Then
		Return MemoryRead($bag + 32, 'long')
	ElseIf IsDllStruct($bag) Then
		Return DllStructGetData($bag, 'Slots')
	Else
		Return MemoryRead(GetBagPtr($bag) + 32, 'long')
	EndIf
EndFunc
#EndRegion Item


#Region H&H
;~ Returns number of heroes you control.
Func GetHeroCount()
	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x2C]
	Local $heroCount = MemoryReadPtr($base_address_ptr, $offset)
	Return $heroCount[1]
EndFunc


;~ Returns agent ID of a hero.
Func GetHeroID($heroIndex)
	If $heroIndex == 0 Then Return GetMyID()
	Local $offset[6] = [0, 0x18, 0x4C, 0x54, 0x24, 0x18 * ($heroIndex - 1)]
	Local $agentID = MemoryReadPtr($base_address_ptr, $offset)
	Return $agentID[1]
EndFunc


;~ Returns hero number by agent ID. If no heroes found with provided agent ID then function returns Null
Func GetHeroNumberByAgentID($agentID)
	Local $heroID
	Local $offset[6] = [0, 0x18, 0x4C, 0x54, 0x24, 0]
	For $i = 1 To GetHeroCount()
		$offset[5] = 0x18 * ($i - 1)
		$heroID = MemoryReadPtr($base_address_ptr, $offset)
		If $heroID[1] == $agentID Then Return $i
	Next
	Return Null
EndFunc


;~ Returns hero number by hero ID.
Func GetHeroNumberByHeroID($heroID)
	Local $agentID
	Local $offset[6] = [0, 0x18, 0x4C, 0x54, 0x24, 0]
	For $i = 1 To GetHeroCount()
		$offset[5] = 8 + 0x18 * ($i - 1)
		$agentID = MemoryReadPtr($base_address_ptr, $offset)
		If $agentID[1] == $heroID Then Return $i
	Next
	Return 0
EndFunc


;~ Returns hero's profession ID (when it can't be found by other means)
Func GetHeroProfession($heroIndex, $secondary = False)
	Local $offset[5] = [0, 0x18, 0x2C, 0x6BC, 0]
	Local $buffer
	$heroIndex = GetHeroID($heroIndex)
	For $i = 0 To GetHeroCount()
		$buffer = MemoryReadPtr($base_address_ptr, $offset)
		If $buffer[1] = $heroIndex Then
			$offset[4] += 4
			If $secondary Then $offset[4] += 4
			$buffer = MemoryReadPtr($base_address_ptr, $offset)
			Return $buffer[1]
		EndIf
		$offset[4] += 0x14
	Next
EndFunc


;~ Tests if a hero's skill slot is disabled.
Func GetIsHeroSkillSlotDisabled($heroIndex, $skillSlot)
	Return BitAND(BitShift(1, -($skillSlot - 1)), DllStructGetData(GetSkillbar($heroIndex), 'Disabled')) > 0
EndFunc
#EndRegion H&H


#Region Agent
;~ Return agent of the player
Func GetMyAgent()
	Return GetAgentByID(GetMyID())
EndFunc


;~ Returns an agent struct.
Func GetAgentByID($agentID)
	If $agentID = -2 Then $agentID = GetMyID()
	Local $agentPtr = GetAgentPtr($agentID)
	Local $agentStruct = SafeDllStructCreate($AGENT_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $agentPtr, 'ptr', DllStructGetPtr($agentStruct), 'int', DllStructGetSize($agentStruct), 'int', 0)
	Return $agentStruct
EndFunc


;~ Internal use for GetAgentByID()
Func GetAgentPtr($agentID)
	Local $offset[3] = [0, 4 * $agentID, 0]
	Local $agentStructAddress = MemoryReadPtr($agent_base_address, $offset)
	Return $agentStructAddress[0]
EndFunc


;~ Test if an agent exists.
Func GetAgentExists($agentID)
	Return GetAgentPtr($agentID) <> 0
EndFunc


;~ FIXME: this function might not be working correctly
;~ Returns the target of an agent.
Func GetTarget($agent)
	Return MemoryRead(GetValue('TargetLogBase') + 4 * DllStructGetData($agent, 'ID'))
EndFunc


;~ Returns agent by player name or Null if player with provided name not found.
Func GetAgentByPlayerName($playerName)
	For $i = 1 To GetMaxAgents()
		If Not GetAgentExists($i) Then ContinueLoop
		Local $agent = GetAgentByID($i)
		If GetPlayerName($agent) == $playerName Then Return $agent
	Next
	Return Null
EndFunc


;~ Returns agent by name.
Func GetAgentByName($agentName)
	If $use_string_logging = False Then Return

	Local $name, $address

	For $i = 1 To GetMaxAgents()
		$address = $string_log_base_address + 256 * $i
		$name = MemoryRead($address, 'wchar [128]')
		$name = StringRegExpReplace($name, '[<]{1}([^>]+)[>]{1}', '')
		If StringInStr($name, $agentName) > 0 Then Return GetAgentByID($i)
	Next

	DisplayAll(True)
	Sleep(100)
	DisplayAll(False)
	DisplayAll(True)
	Sleep(100)
	DisplayAll(False)

	For $i = 1 To GetMaxAgents()
		$address = $string_log_base_address + 256 * $i
		$name = MemoryRead($address, 'wchar [128]')
		$name = StringRegExpReplace($name, '[<]{1}([^>]+)[>]{1}', '')
		If StringInStr($name, $agentName) > 0 Then Return GetAgentByID($i)
	Next
EndFunc


;~ Quickly creates an array of agents of a given type
Func GetAgentArray($type = 0)
	Local $struct
	Local $count
	Local $buffer = ''
	DllStructSetData($MAKE_AGENT_ARRAY_STRUCT, 2, $type)
	MemoryWrite($agent_copy_count, -1, 'long')
	Enqueue($MAKE_AGENT_ARRAY_STRUCT_PTR, 8)
	Local $deadlock = TimerInit()
	Do
		Sleep(1)
		$count = MemoryRead($agent_copy_count, 'long')
	Until $count >= 0 Or TimerDiff($deadlock) > 5000
	If $count < 0 Then $count = 0

	Local $returnArray[$count]
	If $count > 0 Then
		For $i = 0 To $count - 1
			; 448 = size of $AGENT_STRUCT_TEMPLATE in bytes
			$buffer &= 'Byte[448];'
		Next
		$buffer = SafeDllStructCreate($buffer)
		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $agent_copy_base, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
		For $i = 0 To $count - 1
			$returnArray[$i] = SafeDllStructCreate($AGENT_STRUCT_TEMPLATE)
			$struct = SafeDllStructCreate('byte[448]', DllStructGetPtr($returnArray[$i]))
			DllStructSetData($struct, 1, DllStructGetData($buffer, $i + 1))
		Next
	EndIf
	Return $returnArray
EndFunc


#Region Party
;~	Description: Returns different States about Party. Check with BitAND.
;~	0x8 = Leader starts Mission / Leader is travelling with Party
;~	0x10 = Hardmode enabled
;~	0x20 = Party defeated
;~	0x40 = Guild Battle
;~	0x80 = Party Leader
;~	0x100 = Observe-Mode
Func GetPartyState($flag)
	Local $offset[4] = [0, 0x18, 0x4C, 0x14]
	Local $bitMask = MemoryReadPtr($base_address_ptr, $offset)
	Return BitAND($bitMask[1], $flag) > 0
EndFunc


;~ Return True if hard mode is on
Func GetIsHardMode()
	Return GetPartyState(0x10)
EndFunc


Func GetPartySize()
	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0xC]
	Local $playersPtr = MemoryReadPtr($base_address_ptr, $offset)

	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x1C]
	Local $henchmenPtr = MemoryReadPtr($base_address_ptr, $offset)

	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x2C]
	Local $heroesPtr = MemoryReadPtr($base_address_ptr, $offset)

	Local $players = MemoryRead($playersPtr[0], 'long')
	Local $henchmen = MemoryRead($henchmenPtr[0], 'long')
	Local $heroes = MemoryRead($heroesPtr[0], 'long')

	Return $players + $henchmen + $heroes
EndFunc


Func GetPartyAlliesSize()
	Local $offset[5] = [0, 0x18, 0x4C, 0x54, 0x3C]
	Local $alliesPtr = MemoryReadPtr($base_address_ptr, $offset)
	Return MemoryRead($alliesPtr[0], 'long')
EndFunc


Func GetPartyWaitingForMission()
	Return GetPartyState(0x8)
EndFunc
#EndRegion Party


#Region AgentInfo
;~ Returns a player's name.
Func GetPlayerName($agent)
	Local $loginNumber = DllStructGetData($agent, 'LoginNumber')
	Local $offset[6] = [0, 0x18, 0x2C, 0x80C, 76 * $loginNumber + 0x28, 0]
	Local $result = MemoryReadPtr($base_address_ptr, $offset, 'wchar[30]')
	Return $result[1]
EndFunc


;~ Returns the name of an agent.
Func GetAgentName($agent)
	Local $address = $string_log_base_address + 256 * DllStructGetData($agent, 'ID')
	Local $agentName = MemoryRead($address, 'wchar [128]')

	If $agentName = '' Then
		DisplayAll(True)
		Sleep(100)
		DisplayAll(False)
	EndIf

	Local $agentName = MemoryRead($address, 'wchar [128]')
	Return StringRegExpReplace($agentName, '[<]{1}([^>]+)[>]{1}', '')
EndFunc
#EndRegion AgentInfo
#EndRegion Agent


#Region Buff
;~ Returns current number of buffs being maintained.
Func GetBuffCount($heroIndex = 0)
	Local $offset1[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($base_address_ptr, $offset1)
	Local $buffer
	Local $offset2[5] = [0, 0x18, 0x2C, 0x508, 0]
	For $i = 0 To $count[1] - 1
		$offset2[4] = 0x24 * $i
		$buffer = MemoryReadPtr($base_address_ptr, $offset2)
		If $buffer[1] == GetHeroID($heroIndex) Then
			Return MemoryRead($buffer[0] + 0xC)
		EndIf
	Next
	Return 0
EndFunc


;~ Tests if you are currently maintaining buff on target.
Func GetIsTargetBuffed($skillID, $agent, $heroIndex = 0)
	Local $buffCount = GetBuffCount($heroIndex)
	Local $buffStructAddress
	Local $offset1[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($base_address_ptr, $offset1)
	Local $buffer
	Local $offset2[5] = [0, 0x18, 0x2C, 0x508, 0]
	For $i = 0 To $count[1] - 1
		$offset2[4] = 0x24 * $i
		$buffer = MemoryReadPtr($base_address_ptr, $offset2)
		If $buffer[1] == GetHeroID($heroIndex) Then
			Local $offset3[6] = [0, 0x18, 0x2C, 0x508, 0x4 + 0x24 * $i, 0]
			For $j = 0 To $buffCount - 1
				$offset3[5] = 0 + 0x10 * $j
				$buffStructAddress = MemoryReadPtr($base_address_ptr, $offset3)
				Local $buffStruct = SafeDllStructCreate($BUFF_STRUCT_TEMPLATE)
				SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $buffStructAddress[0], 'ptr', DllStructGetPtr($buffStruct), 'int', DllStructGetSize($buffStruct), 'int', 0)
				If (DllStructGetData($buffStruct, 'SkillID') == $skillID) And DllStructGetData($buffStruct, 'TargetId') == DllStructGetData($agent, 'ID') Then
					Return $j + 1
				EndIf
			Next
		EndIf
	Next
	Return 0
EndFunc


;~ Returns buff struct.
Func GetBuffByIndex($buffIndex, $heroIndex = 0)
	Local $offset1[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($base_address_ptr, $offset1)
	Local $offset2[5] = [0, 0x18, 0x2C, 0x508, 0]
	Local $buffer
	For $i = 0 To $count[1] - 1
		$offset2[4] = 0x24 * $i
		$buffer = MemoryReadPtr($base_address_ptr, $offset2)
		If $buffer[1] == GetHeroID($heroIndex) Then
			Local $offset3[6] = [0, 0x18, 0x2C, 0x508, 0x4 + 0x24 * $i, 0x10 * ($buffIndex - 1)]
			$buffStructAddress = MemoryReadPtr($base_address_ptr, $offset3)
			Local $buffStruct = SafeDllStructCreate($BUFF_STRUCT_TEMPLATE)
			SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $buffStructAddress[0], 'ptr', DllStructGetPtr($buffStruct), 'int', DllStructGetSize($buffStruct), 'int', 0)
			Return $buffStruct
		EndIf
	Next
	Return 0
EndFunc
#EndRegion Buff


#Region Misc
;~ Returns skillbar struct.
Func GetSkillbar($heroIndex = 0)
	Local $offset[5] = [0, 0x18, 0x2C, 0x6F0, 0]
	For $i = 0 To GetHeroCount()
		$offset[4] = $i * 0xBC
		Local $skillbarStructAddress = MemoryReadPtr($base_address_ptr, $offset)
		Local $skillbarStruct = SafeDllStructCreate($SKILLBAR_STRUCT_TEMPLATE)
		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $skillbarStructAddress[0], 'ptr', DllStructGetPtr($skillbarStruct), 'int', DllStructGetSize($skillbarStruct), 'int', 0)
		If DllStructGetData($skillbarStruct, 'AgentId') == GetHeroID($heroIndex) Then
			Return $skillbarStruct
		EndIf
	Next
EndFunc


;~ Returns the skill ID of an equipped skill.
Func GetSkillbarSkillID($skillSlot, $heroIndex = 0)
	Return DllStructGetData(GetSkillbar($heroIndex), 'SkillId' & $skillSlot)
EndFunc


;~ Returns the adrenaline charge of an equipped skill.
Func GetSkillbarSkillAdrenaline($skillSlot, $heroIndex = 0)
	Return DllStructGetData(GetSkillbar($heroIndex), 'AdrenalineA' & $skillSlot)
EndFunc


;~ Returns the recharge time remaining of an equipped skill in milliseconds.
Func GetSkillbarSkillRecharge($skillSlot, $heroIndex = 0)
	Local $skillbar = GetSkillbar($heroIndex)
	; Recharge in $SKILLBAR_STRUCT_TEMPLATE is 0 when skill is already recharged or is the timestamp in the future when the skill will be recharged if it is recharging
	Local $rechargeFutureTimestamp = DllStructGetData($skillbar, 'Recharge' & $skillSlot)
	Local $skill = GetSkillByID(DllStructGetData($skillbar, 'SkillId' & $skillSlot))
	Local $castTime = DllStructGetData($skill, 'Activation') * 1000
	Local $aftercast = DllStructGetData($skill, 'Aftercast') * 1000

	; Caution, noticed some	discrepancy between GetInstanceUpTime() and recharge timestamps, difference can be negative surprisingly
	; Therefore capping recharge time to be always bigger or equal to 1 with _Max() if Recharge is non-zero
	Return $rechargeFutureTimestamp == 0 ? 0 : _Max(1, ($rechargeFutureTimestamp + $castTime + $aftercast + GetPing()) - GetInstanceUpTime())
EndFunc


;~ Returns skill struct.
Func GetSkillByID($skillID)
	Local $skillstructAddress = $skill_base_address + (0xA4 * $skillID)
	Local $skillStruct = SafeDllStructCreate($SKILL_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $skillstructAddress, 'ptr', DllStructGetPtr($skillStruct), 'int', DllStructGetSize($skillStruct), 'int', 0)
	Return $skillStruct
EndFunc


;~ Returns current morale.
Func GetMorale($heroIndex = 0)
	Local $agentID = GetHeroID($heroIndex)
	Local $offset1[4] = [0, 0x18, 0x2C, 0x638]
	Local $index = MemoryReadPtr($base_address_ptr, $offset1)
	Local $offset2[6] = [0, 0x18, 0x2C, 0x62C, 8 + 0xC * BitAND($agentID, $index[1]), 0x18]
	Local $result = MemoryReadPtr($base_address_ptr, $offset2)
	Return $result[1] - 100
EndFunc


;~ Returns attribute struct.
Func GetAttributeInfoByID($attributeID)
	Local $attributeStructAddress = $attribute_info_ptr + (0x14 * $attributeID)
	Local $attributeStruct = SafeDllStructCreate($ATTRIBUTE_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $attributeStructAddress, 'ptr', DllStructGetPtr($attributeStruct), 'int', DllStructGetSize($attributeStruct), 'int', 0)
	Return $attributeStruct
EndFunc


;~ Returns profession associated with an attribute
Func GetAttributeProfession($attributeID)
	Local $attributeInfo = GetAttributeInfoByID($attributeID)
	Return DllStructGetData($attributeInfo, 'profession_id')
EndFunc


;~ TODO: try this
Func GetAttributeNameID($attributeID)
	Local $attributeInfo = GetAttributeInfoByID($attributeID)
	Return DllStructGetData($attributeInfo, 'name_id')
EndFunc


;~ TODO: try this
Func GetAttributeIsPvE($attributeID)
	Local $attributeInfo = GetAttributeInfoByID($attributeID)
	Return DllStructGetData($attributeInfo, 'is_pve')
EndFunc


;~ Returns effect struct or array of effects.
Func GetEffect($skillID = 0, $heroIndex = 0)
	Local $effectCount, $effectStructAddress
	; Offsets have to be kept separate - else we risk cross-call contamination - Avoid ReDim !
	Local $offset1[4] = [0, 0x18, 0x2C, 0x510]
	Local $count = MemoryReadPtr($base_address_ptr, $offset1)
	Local $buffer
	For $i = 0 To $count[1] - 1
		Local $offset2[5] = [0, 0x18, 0x2C, 0x508, 0x24 * $i]
		$buffer = MemoryReadPtr($base_address_ptr, $offset2)
		If $buffer[1] == GetHeroID($heroIndex) Then
			Local $offset3[5] = [0, 0x18, 0x2C, 0x508, 0x1C + 0x24 * $i]
			$effectCount = MemoryReadPtr($base_address_ptr, $offset3)

			Local $offset4[6] = [0, 0x18, 0x2C, 0x508, 0x14 + 0x24 * $i, 0]
			$effectStructAddress = MemoryReadPtr($base_address_ptr, $offset4)

			If $skillID = 0 Then
				Local $resultArray[$effectCount[1]]
				For $j = 0 To $effectCount[1] - 1
					$resultArray[$j] = SafeDllStructCreate($EFFECT_STRUCT_TEMPLATE)
					$effectStructAddress[1] = $effectStructAddress[0] + 24 * $j
					SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $effectStructAddress[1], 'ptr', DllStructGetPtr($resultArray[$j]), 'int', 24, 'int', 0)
				Next
				Return $resultArray
			Else
				For $j = 0 To $effectCount[1] - 1
					Local $effectStruct = SafeDllStructCreate($EFFECT_STRUCT_TEMPLATE)
					SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $effectStructAddress[0] + 24 * $j, 'ptr', DllStructGetPtr($effectStruct), 'int', 24, 'int', 0)

					If DllStructGetData($effectStruct, 'SkillID') == $skillID Then
						Return $effectStruct
					EndIf
				Next
			EndIf
		EndIf
	Next
	Return Null
EndFunc


;~ Returns time remaining before an effect expires, in milliseconds.
Func GetEffectTimeRemaining($effect, $heroIndex = 0)
	If Not IsDllStruct($effect) Then $effect = GetEffect($effect, $heroIndex)
	; if hero or player (0) is not under specified effect then 0 will be returned here
	If $effect == Null Then Return 0
	If IsArray($effect) Then Return 0

	Local $effectSkill = GetSkillByID(DllStructGetData($effect, 'SkillId'))
	Local $castTime = DllStructGetData($effectSkill, 'Activation') * 1000
	Local $aftercast = DllStructGetData($effectSkill, 'Aftercast') * 1000
	; full duration of effect in seconds, not remaining time
	Local $duration = DllStructGetData($effect, 'Duration') * 1000
	; timestamp when the effect was started
	Local $castTimeStamp = DllStructGetData($effect, 'TimeStamp')

	; Caution, noticed some	discrepancy between GetInstanceUpTime() and cast timestamps, difference can be negative surprisingly
	; Furthermore, other problem is that reapplying the effect doesn't always refresh its start timestamp until previous effect elapses
	; Therefore capping remaining effect time to be always bigger or equal to 1 with _Max() if there is still effect on hero/player
	Return _Max(1, $duration - (GetInstanceUpTime() - ($castTimeStamp + $castTime + $aftercast + GetPing())))
EndFunc


;~ FIXME: this function might not be working correctly
;~ Returns the timestamp used for effects and skills (milliseconds).
Func GetSkillTimer()
	Return MemoryRead($skill_timer, 'long')
EndFunc


;~ Returns level of an attribute - takes runes into account
Func GetAttributeByID($attributeID, $withRunes = False, $heroIndex = 0)
	Local $agentID = GetHeroID($heroIndex)
	Local $buffer
	Local $offset[5]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x2C
	$offset[3] = 0xAC
	For $i = 0 To GetHeroCount()
		$offset[4] = 0x3D8 * $i
		$buffer = MemoryReadPtr($base_address_ptr, $offset)
		If $buffer[1] == $agentID Then
			$offset[4] = 0x3D8 * $i + 0x14 * $attributeID + $withRunes ? 0xC : 0x8
			$buffer = MemoryReadPtr($base_address_ptr, $offset)
			Return $buffer[1]
		EndIf
	Next
EndFunc


;~ Returns amount of experience.
Func GetExperience()
	Local $offset[4] = [0, 0x18, 0x2C, 0x740]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Tests if an area has been vanquished.
Func GetAreaVanquished()
	Return GetFoesToKill() = 0
EndFunc


;~ Returns number of foes that have been killed so far.
Func GetFoesKilled()
	Local $offset[4] = [0, 0x18, 0x2C, 0x84C]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns number of enemies left to kill for vanquish.
Func GetFoesToKill()
	Local $offset[4] = [0, 0x18, 0x2C, 0x850]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns number of agents currently loaded.
Func GetMaxAgents()
	Return MemoryRead($max_agents)
EndFunc


;~ Returns your agent ID.
Func GetMyID()
	Return MemoryRead($my_ID)
EndFunc


;~ Returns current target.
Func GetCurrentTarget()
	Local $currentTargetId = GetCurrentTargetID()
	Return $currentTargetId == 0 ? Null : GetAgentByID(GetCurrentTargetID())
EndFunc


;~ Returns current target ID.
Func GetCurrentTargetID()
	Return MemoryRead($current_target_agent_ID)
EndFunc


;~ Returns current ping.
Func GetPing()
	Local $ping = MemoryRead($scan_ping_address)
	Return $ping < 10 ? 10 : $ping
EndFunc


;~ Alternate way to get anything, reads directly from game memory without call to Scan something - but is not robust and will break anytime the game changes
Func GetDataFromRelativeAddress($relativeCheatEngineAddress, $size)
	Local $base_address = ScanForProcess()
	Local $fullAddress = $base_address + $relativeCheatEngineAddress - 0x1000
	Local $buffer = DllStructCreate('byte[' & $size & ']')
	Local $result = SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'ptr', $fullAddress, 'ptr', DllStructGetPtr($buffer), 'int', DllStructGetSize($buffer), 'int', 0)
	Return $buffer
EndFunc


;~ Returns current map ID
Func GetMapID()
	Return MemoryRead($map_ID)
EndFunc


;~ Returns the instance type (city, explorable, mission, etc ...)
Func GetMapType()
	Local $offset[1] = [0x00]
	Local $result = MemoryReadPtr($instance_info_ptr, $offset, 'dword')
	Return $result[1]
EndFunc


;~ Returns the area infos corresponding to the given map
Func GetAreaInfoByID($mapID = 0)
	If $mapID = 0 Then $mapID = GetMapID()

	Local $areaInfoAddress = $area_info_ptr + (0x7C * $mapID)
	Local $areaInfoStruct = SafeDllStructCreate($AREA_INFO_STRUCT_TEMPLATE)
	SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $areaInfoAddress, 'ptr', DllStructGetPtr($areaInfoStruct), 'int', DllStructGetSize($areaInfoStruct), 'int', 0)

	Return $areaInfoStruct
EndFunc


;~ Returns the campaign of a given map
Func GetMapCampaign($mapID = 0)
	Local $mapStruct = GetAreaInfoByID($mapID)
	Return DllStructGetData($mapStruct, 'campaign')
EndFunc


;~ Returns the region of a given map
Func GetMapRegion($mapID = 0)
	Local $mapStruct = GetAreaInfoByID($mapID)
	Return DllStructGetData($mapStruct, 'region')
EndFunc


;~ TODO: what does this do ?
Func GetMapRegionType($mapID = 0)
	Local $mapStruct = GetAreaInfoByID($mapID)
	Return DllStructGetData($mapStruct, 'regiontype')
EndFunc


;~ FIXME: this function might not be working correctly
;~ Returns current load-state.
Func GetMapLoading()
	Return MemoryRead($map_loading)
EndFunc


;~ Returns if map has been loaded.
Func GetMapIsLoaded()
	Return GetAgentExists(GetMyID())
EndFunc


;~ Returns current district
Func GetDistrict()
	Local $offset[4] = [0, 0x18, 0x44, 0x220]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Internal use for travel functions.
Func GetRegion()
	Return MemoryRead($region_ID)
EndFunc


;~ Internal use for travel functions.
Func GetLanguage()
	Return MemoryRead($language_ID)
EndFunc


;~ Returns quest
;~ LogState = 0(no such quest) - 1(quest in progress) - 2(quest over and out) - 3(quest over, still in map)
Func GetQuestByID($questID = 0)
	Local $questPtr, $questLogSize, $quest
	Local $offset[4] = [0, 0x18, 0x2C, 0x534]

	$questLogSize = MemoryReadPtr($base_address_ptr, $offset)

	If $questID = 0 Then
		$offset[1] = 0x18
		$offset[2] = 0x2C
		$offset[3] = 0x528
		$quest = MemoryReadPtr($base_address_ptr, $offset)
		$questID = $quest[1]
	EndIf

	Local $offset[5] = [0, 0x18, 0x2C, 0x52C, 0]
	For $i = 0 To $questLogSize[1]
		$offset[4] = 0x34 * $i
		$questPtr = MemoryReadPtr($base_address_ptr, $offset)
		$quest = SafeDllStructCreate($QUEST_STRUCT_TEMPLATE)
		SafeDllCall13($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $questPtr[0], 'ptr', DllStructGetPtr($quest), 'int', DllStructGetSize($quest), 'int', 0)
		If DllStructGetData($quest, 'ID') = $questID Then Return $quest
	Next
	Return Null
EndFunc


;~ Returns if you're logged in.
Func GetLoggedIn()
	Return MemoryRead($is_logged_in)
EndFunc


;~ Returns language currently being used.
Func GetDisplayLanguage()
	Local $offset[6] = [0, 0x18, 0x18, 0x194, 0x4C, 0x40]
	Local $result = MemoryReadPtr($base_address_ptr, $offset)
	Return $result[1]
EndFunc


;~ Returns how long the current instance has been active, in milliseconds.
Func GetInstanceUpTime()
	Local $offset[4]
	$offset[0] = 0
	$offset[1] = 0x18
	$offset[2] = 0x8
	$offset[3] = 0x1AC
	Local $timer = MemoryReadPtr($base_address_ptr, $offset)
	Return $timer[1]
EndFunc


;~ Returns the game client's build number
Func GetBuildNumber()
	Return $build_number
EndFunc


;~ Returns primary attribute from the provided profession
Func GetProfPrimaryAttribute($profession)
	Switch $profession
		Case $ID_WARRIOR
			Return $ID_STRENGTH
		Case $ID_RANGER
			Return $ID_EXPERTISE
		Case $ID_MONK
			Return $ID_DIVINE_FAVOR
		Case $ID_NECROMANCER
			Return $ID_SOUL_REAPING
		Case $ID_MESMER
			Return $ID_FAST_CASTING
		Case $ID_ELEMENTALIST
			Return $ID_ENERGY_STORAGE
		Case $ID_ASSASSIN
			Return $ID_CRITICAL_STRIKES
		Case $ID_RITUALIST
			Return $ID_SPAWNING_POWER
		Case $ID_PARAGON
			Return $ID_LEADERSHIP
		Case $ID_DERVISH
			Return $ID_MYSTICISM
	EndSwitch
EndFunc
#EndRegion Misc
#EndRegion Queries


#Region Other Functions
#Region Misc
;~ Invites a player into the guild using his character name
Func InviteGuild($characterName)
	If GetAgentExists(GetMyID()) Then
		DllStructSetData($INVITE_GUILD_STRUCT, 1, GetValue('CommandPacketSend'))
		DllStructSetData($INVITE_GUILD_STRUCT, 2, 0x4C)
		DllStructSetData($INVITE_GUILD_STRUCT, 3, 0xB5)
		DllStructSetData($INVITE_GUILD_STRUCT, 4, 0x01)
		DllStructSetData($INVITE_GUILD_STRUCT, 5, $characterName)
		DllStructSetData($INVITE_GUILD_STRUCT, 6, 0x02)
		Enqueue(DllStructGetPtr($INVITE_GUILD_STRUCT), DllStructGetSize($INVITE_GUILD_STRUCT))
		Return True
	EndIf
	Return False
EndFunc


;~ Invites a player as a guest into the guild using his character name
Func InviteGuest($characterName)
	If GetAgentExists(GetMyID()) Then
		DllStructSetData($INVITE_GUILD_STRUCT, 1, GetValue('CommandPacketSend'))
		DllStructSetData($INVITE_GUILD_STRUCT, 2, 0x4C)
		DllStructSetData($INVITE_GUILD_STRUCT, 3, 0xB5)
		DllStructSetData($INVITE_GUILD_STRUCT, 4, 0x01)
		DllStructSetData($INVITE_GUILD_STRUCT, 5, $characterName)
		DllStructSetData($INVITE_GUILD_STRUCT, 6, 0x01)
		Enqueue(DllStructGetPtr($INVITE_GUILD_STRUCT), DllStructGetSize($INVITE_GUILD_STRUCT))
		Return True
	EndIf
	Return False
EndFunc
#EndRegion Misc


#Region Online Status
;~ Change online status. 0 = Offline, 1 = Online, 2 = Do not disturb, 3 = Away
Func SetPlayerStatus($status)
	If $status < 0 Or $status > 3 Or GetPlayerStatus() == $status Then
		Warn('Provided an incorrect status - or the player is already in the provided status.')
		Return False
	EndIf

	DllStructSetData($CHANGE_STATUS_STRUCT, 2, $status)
	Enqueue($CHANGE_STATUS_STRUCT_PTR, 8)
	Return True
EndFunc


;~ Returns player status : 0 = Offline, 1 = Online, 2 = Do not disturb, 3 = Away
Func GetPlayerStatus()
	Return MemoryRead($current_status)
EndFunc


Func Disconnected()
	Local $check = False
	Local $deadlock = TimerInit()
	Do
		Sleep(20)
		$check = GetMapType() <> $ID_Loading And GetAgentExists(GetMyID())
	Until $check Or TimerDiff($deadlock) > 5000
	If $check = False Then
		Error('Disconnected!')
		Error('Attempting to reconnect.')
		Local $windowHandle = GetWindowHandle()
		ControlSend($windowHandle, '', '', '{Enter}')
		$deadlock = TimerInit()
		Do
			Sleep(20)
			$check = GetMapType() <> $ID_Loading And GetAgentExists(GetMyID())
		Until $check Or TimerDiff($deadlock) > 60000
		If $check = False Then
			Error('Failed to Reconnect 1!')
			Error('Retrying.')
			ControlSend($windowHandle, '', '', '{Enter}')
			$deadlock = TimerInit()
			Do
				Sleep(20)
				$check = GetMapType() <> $ID_Loading And GetAgentExists(GetMyID())
			Until $check Or TimerDiff($deadlock) > 60000
			If $check = False Then
				Error('Failed to Reconnect 2!')
				Error('Retrying.')
				ControlSend($windowHandle, '', '', '{Enter}')
				$deadlock = TimerInit()
				Do
					Sleep(20)
					$check = GetMapType() <> $ID_Loading And GetAgentExists(GetMyID())
				Until $check Or TimerDiff($deadlock) > 60000
				If $check = False Then
					Error('Could not reconnect!')
					Error('Exiting.')
					EnableRendering()
					Exit 1
				EndIf
			EndIf
		EndIf
	EndIf
	Notice('Reconnected!')
	Sleep(5000)
EndFunc
#EndRegion Online Status


Func GetLastDialogID()
	Return MemoryRead($last_dialog_ID)
EndFunc


Func GetLastDialogIDHex(Const ByRef $ID)
	If $ID Then Return '0x' & StringReplace(Hex($ID, 8), StringRegExpReplace(Hex($ID, 8), '[^0].*', ''), '')
EndFunc
#EndRegion Other Functions
