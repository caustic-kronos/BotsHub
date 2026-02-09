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
; limitations under the License.
#CE ===========================================================================

#include-once

#include 'SQLite.au3'
#include 'SQLite.dll.au3'
#include 'GWA2_Headers.au3'
#include 'GWA2_ID.au3'
#include 'GWA2.au3'
#include 'Utils.au3'
#include 'Utils-Items_Modstructs.au3'
#include 'Utils-Debugger.au3'

Opt('MustDeclareVars', True)


#Region Inventory Management
;~ Function to deal with inventory before farm run
Func InventoryManagementBeforeRun($tradeTown = $ID_EYE_OF_THE_NORTH)
	; Clarity rename
	Local $cache = $inventory_management_cache
	; Operations order :
	; 1-Store unids if desired
	; 2-Sort items
	; 3-Identify items
	; 4-Collect data
	; 5-Salvage
	; 6-Sell materials
	; 7-Sell items
	; 8-Balance character's gold level
	; 9-Buy ectoplasm/obsidian with surplus
	; 10-Store items
	If $cache['Store items.Unidentified gold items'] And HasGoldUnidentifiedItems() Then
		If GetMapType() <> $ID_OUTPOST Then TravelToOutpost($tradeTown, $district_name)
		StoreItemsInXunlaiStorage(IsUnidentifiedGoldItem)
	EndIf
	If $run_options_cache['run.sort_items'] Then SortInventory()
	If $cache['@identify.something'] And HasUnidentifiedItems() Then
		TravelToOutpost($tradeTown, $district_name)
		IdentifyItems()
	EndIf
	If $run_options_cache['run.collect_data'] Then
		ConnectToDatabase()
		InitializeDatabase()
		CompleteModelLookupTable()
		CompleteUpgradeLookupTable()
		StoreAllItemsData()
		DisconnectFromDatabase()
	EndIf
	If $cache['@salvage.something'] And HasItemsToSalvage() Then
		TravelToOutpost($tradeTown, $district_name)
		SalvageItems()
		If $bags_count == 5 And MoveItemsOutOfEquipmentBag() > 0 Then SalvageItems()
		;SalvageInscriptions()
		;UpgradeWithSalvageInscriptions()
		;SalvageMaterials()
	EndIf
	If $cache['@sell.materials.something'] And (HasBasicMaterialsToTrade() Or HasRareMaterialsToTrade()) Then
		TravelToOutpost($tradeTown, $district_name)
		; If we have more than 60k, we risk running into the situation we cannot sell because we're too rich, so we store some in xunlai
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		If $cache['@sell.materials.basic.something'] And HasBasicMaterials() Then SellBasicMaterialsToMerchant()
		If $cache['@sell.materials.rare.something'] And HasRareMaterials() Then SellRareMaterialsToMerchant()
	EndIf
	If $cache['@sell.something'] And HasItemsToSell() Then
		TravelToOutpost($tradeTown, $district_name)
		; If we have more than 60k, we risk running into the situation we cannot sell because we're too rich, so we store some in xunlai
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		SellItemsToMerchant()
	EndIf
	; Max gold in Xunlai chest is 1000 platinums
	If $cache['Store items.Gold'] AND GetGoldCharacter() > 60000 And GetGoldStorage() <= (1000000 - 60000) Then
		If GetMapType() <> $ID_OUTPOST Then TravelToOutpost($tradeTown, $district_name)
		DepositGold(60000)
		Info('Deposited Gold')
	EndIf
	If $cache['Store items.Gold'] Then
		If GetMapType() <> $ID_OUTPOST Then TravelToOutpost($tradeTown, $district_name)
		BalanceCharacterGold(10000)
	EndIf
	; TODO: generalize this for all materials
	If $cache['Buy items.Rare Materials.Glob of Ectoplasm'] And GetGoldCharacter() > 10000 Then
		TravelToOutpost($tradeTown, $district_name)
		BuyRareMaterialFromMerchantUntilPoor($ID_GLOB_OF_ECTOPLASM, 10000, $ID_OBSIDIAN_SHARD)
	EndIf
	If $cache['Buy items.Rare Materials.Obsidian Shard'] And GetGoldCharacter() > 10000 Then
		TravelToOutpost($tradeTown, $district_name)
		BuyRareMaterialFromMerchantUntilPoor($ID_OBSIDIAN_SHARD, 10000, $ID_GLOB_OF_ECTOPLASM)
	EndIf
	If $cache['@store.something'] Then
		If GetMapType() <> $ID_OUTPOST Then TravelToOutpost($tradeTown, $district_name)
		StoreItemsInXunlaiStorage()
	EndIf
	ResetBotsSetups()
	Return $PAUSE
EndFunc


;~ Function to deal with inventory during farm to preserve inventory space
Func InventoryManagementMidRun($tradeTown = $ID_EYE_OF_THE_NORTH)
	; Operations order :
	; 1-Check if we have at least 1 identification kit and 1 salvage kit
	; 2-If not, buy until we have 4 identification kits and 12 salvaged kits
	; 3-Sort items
	; 4-Identify items
	; 5-Salvage
	Local Static $superiorIdentificationKits = [$ID_SUPERIOR_IDENTIFICATION_KIT]
	Local Static $salvageKits = [$ID_SALVAGE_KIT, $ID_SALVAGE_KIT_2]
	If GetInventoryKitCount($superiorIdentificationKits) < 1 Or GetInventoryKitCount($salvageKits) < 1 Then
		Info('Buying kits for passive inventory management')
		TravelToOutpost($tradeTown, $district_name)
		; Since we are in trade town, might as well clear inventory
		InventoryManagementBeforeRun()
		BuyKitsForMidRun()
		Return True
	EndIf
	If $run_options_cache['run.sort_items'] Then SortInventory()
	IdentifyItems(False)
	If $inventory_management_cache['@salvage.something'] Then
		SalvageItems(False)
		If $bags_count == 5 And MoveItemsOutOfEquipmentBag() > 0 Then SalvageItems()
	EndIf
	Return False
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
	For $bagIndex = 1 To $bags_count
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
				If ($rarity == $RARITY_GOLD) Then
					$itemsCounts[14] += 1
				ElseIf ($rarity == $RARITY_PURPLE) Then
					$itemsCounts[13] += 1
				ElseIf ($rarity == $RARITY_BLUE) Then
					$itemsCounts[12] += 1
				ElseIf ($rarity == $RARITY_GREEN) Then
					$itemsCounts[15] += 1
				ElseIf ($rarity == $RARITY_WHITE) Then
					$itemsCounts[11] += 1
				EndIf
			; ArmorSalvage
			ElseIf IsArmorSalvageItem($item) Then
				$rarity = GetRarity($item)
				If ($rarity == $RARITY_GOLD) Then
					$itemsCounts[7] += 1
				ElseIf ($rarity == $RARITY_PURPLE) Then
					$itemsCounts[8] += 1
				ElseIf ($rarity == $RARITY_BLUE) Then
					$itemsCounts[9] += 1
				ElseIf ($rarity == $RARITY_WHITE) Then
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
			ElseIf ($itemID == $ID_LOCKPICK) Then
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

		; Weapon
		If IsWeapon($item) Then
			$rarity = GetRarity($item)
			If ($rarity == $RARITY_GOLD) Then
				$category = 14
			ElseIf ($rarity == $RARITY_PURPLE) Then
				$category = 13
			ElseIf ($rarity == $RARITY_BLUE) Then
				$category = 12
			ElseIf ($rarity == $RARITY_GREEN) Then
				$category = 15
			ElseIf ($rarity == $RARITY_WHITE) Then
				$category = 11
			EndIf
		; ArmorSalvage
		ElseIf isArmorSalvageItem($item) Then
			$rarity = GetRarity($item)
			If ($rarity == $RARITY_GOLD) Then
				$category = 7
			ElseIf ($rarity == $RARITY_PURPLE) Then
				$category = 8
			ElseIf ($rarity == $RARITY_BLUE) Then
				$category = 9
			ElseIf ($rarity == $RARITY_WHITE) Then
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
		ElseIf ($itemID == $ID_LOCKPICK) Then
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
		RandomSleep(50)
	Next
EndFunc


;~ Return True if the item should be picked up
;~ Only pick rare materials, black and white dyes, lockpicks, gold items and green items
Func PickOnlyImportantItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $dyeColor = DllStructGetData($item, 'DyeColor')
	Local $rarity = GetRarity($item)
	If IsRareMaterial($item) Then
		Return True
	ElseIf ($itemID == $ID_DYES) Then
		Return (($dyeColor == $ID_BLACK_DYE) Or ($dyeColor == $ID_WHITE_DYE))
	ElseIf ($itemID == $ID_LOCKPICK) Then
		Return True
	ElseIf $rarity <> $RARITY_WHITE And IsWeapon($item) And IsLowReqMaxDamage($item) Then
		Return True
	ElseIf ($rarity == $RARITY_GOLD) Then
		Return True
	ElseIf ($rarity == $RARITY_GREEN) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Return True if the item should be picked up - default to False
Func DefaultShouldPickItem($item)
	; Clarity rename
	Local $cache = $inventory_management_cache
	If $cache['@pickup.nothing'] Then Return False
	If $cache['@pickup.everything'] Then Return True

	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)

	; ---------------------------------------- Money ----------------------------------------
	If (($itemID == $ID_MONEY) And (GetGoldCharacter() < 99000)) Then
		Return $cache['Pick up items.Gold']
	; --------------------------------------- Weapons ---------------------------------------
	ElseIf IsWeapon($item) Then
		If $rarity <> $RARITY_WHITE And IsLowReqMaxDamage($item) Then Return True
		Return CheckPickupWeapon($item)
	; --------------------------------- Armor salvageables ---------------------------------
	ElseIf isArmorSalvageItem($item) Then
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		Return $cache['Pick up items.Armor salvageables.' & $rarityName]
	; --------------------------- Consumables, Alcohols & Festives ---------------------------
	ElseIf IsConsumable($itemID) Then
		Return $cache['Pick up items.Consumables']
	ElseIf IsAlcohol($itemID) Then
		Return $cache['Pick up items.Alcohols']
	ElseIf IsSpecialDrop($itemID) Then
		Local $festivalDropName = $SPECIAL_DROP_NAMES_FROM_IDS[$itemID]
		Return $cache['Pick up items.Festival Items.' & $festivalDropName]
	; --------------------------------------- Trophies ---------------------------------------
	ElseIf IsTrophy($itemID) Then
		; TODO: replace this by a map from ID to trophy name
		Switch $itemID
			Case $ID_MINISTERIAL_COMMENDATION
				Return True
			Case $ID_GLACIAL_STONE
				Return $cache['Pick up items.Trophies.Glacial Stone']
			Case $ID_DESTROYER_CORE
				Return $cache['Pick up items.Trophies.Destroyer Core']
			Case $ID_JADE_BRACELET
				Return $cache['Pick up items.Trophies.Jade Bracelet']
			Case $ID_STOLEN_GOODS
				Return $cache['Pick up items.Trophies.Stolen Goods']
			Case $ID_DARK_REMAINS
				Return $cache['Pick up items.Trophies.Dark Remains']
			Case $ID_DEMONIC_REMAINS
				Return $cache['Pick up items.Trophies.Demonic Remains']
		EndSwitch
		Return $cache['Pick up items.Trophies']
	; -------------------------------------- Materials --------------------------------------
	ElseIf IsBasicMaterial($item) Then
		Local $materialName = $BASIC_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $cache['Pick up items.Basic Materials.' & $materialName]
	ElseIf IsRareMaterial($item) Then
		Local $materialName = $RARE_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $cache['Pick up items.Rare Materials.' & $materialName]
	; ---------------------------------------- Tomes ----------------------------------------
	ElseIf IsRegularTome($itemID) Then
		Local $tomeName = $REGULAR_TOME_NAMES_FROM_IDS[$itemID]
		Return $cache['Pick up items.Tomes.Normal.' & $tomeName]
	ElseIf IsEliteTome($itemID) Then
		Local $tomeName = $ELITE_TOME_NAMES_FROM_IDS[$itemID]
		Return $cache['Pick up items.Tomes.Elite.' & $tomeName]
	; --------------------------------------- Scrolls ---------------------------------------
	ElseIf IsGoldScroll($itemID) Then
		Local $scrollName = $GOLD_SCROLL_NAMES_FROM_IDS[$itemID]
		Local $pickup = $cache['Pick up items.Scrolls.Gold.' & $scrollName]
		If $pickup <> Null Then Return $pickup
		Return $cache['Pick up items.Scrolls.Gold.Other gold scrolls']
	ElseIf IsBlueScroll($itemID) Then
		Return $cache['Pick up items.Scrolls.Blue']
	; ----------------------------------------- Keys -----------------------------------------
	ElseIf IsKey($itemID) Then
		Return $cache['Pick up items.Keys']
	ElseIf ($itemID == $ID_LOCKPICK) Then
		Return True
	; ----------------------------------------- Dyes -----------------------------------------
	ElseIf ($itemID == $ID_DYES) Then
		Local $dyeColorID = DllStructGetData($item, 'DyeColor')
		Local $dyeColorName = $DYE_NAMES_FROM_IDS[$dyeColorID]
		Return $cache['Pick up items.Dyes.' & $dyeColorName]
	; --------------------------------- Gizmos & Quest items ---------------------------------
	ElseIf ($itemID == $ID_JAR_OF_INVIGORATION) Then
		Return False
	ElseIf IsMapPiece($itemID) Then
		Return $cache['Pick up items.Quest items.Map pieces']
	; ----------------------------------- Other stackables -----------------------------------
	ElseIf IsStackable($item) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Return True if the item should be salvaged - default to false
Func DefaultShouldSalvageItem($item)
	; Clarity rename
	Local $cache = $inventory_management_cache
	If $cache['@salvage.nothing'] Then Return False

	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $rarity = GetRarity($item)

	If $rarity == $RARITY_GREEN Then
		Return False
	; --------------------------------------- Weapons ---------------------------------------
	ElseIf IsWeapon($item) Then
		If Not DllStructGetData($item, 'IsMaterialSalvageable') Then Return False
		If $cache['@salvage.weapons.nothing'] Then Return False
		If Not CheckSalvageWeapon($item) Then Return False
		Return Not ShouldKeepWeapon($item)
	; --------------------------------- Armor salvageables ---------------------------------
	ElseIf IsArmorSalvageItem($item) Then
		If $cache['@salvage.salvageables.nothing'] Then Return False
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		If Not $cache['Salvage items.Armor salvageables.' & $rarityName] Then Return False
		Return IsIdentified($item) And Not ContainsValuableUpgrades($item)
	; --------------------------------------- Trophies ---------------------------------------
	ElseIf IsTrophy($itemID) Then
		If $cache['Salvage items.Trophies'] Then Return True
		If $cache['@salvage.trophies.nothing'] Then Return False
		; TODO: replace this by a map from ID to trophy name
		Switch $itemID
			Case $ID_GLACIAL_STONE
				Return $cache['Salvage items.Trophies.Glacial Stone']
			Case $ID_DESTROYER_CORE
				Return $cache['Salvage items.Trophies.Destroyer Core']
			Case $ID_JADE_BRACELET
				Return $cache['Salvage items.Trophies.Jade Bracelet']
			Case $ID_STOLEN_GOODS
				Return $cache['Salvage items.Trophies.Stolen Goods']
			Case $ID_DARK_REMAINS
				Return $cache['Salvage items.Trophies.Dark Remains']
			Case $ID_DEMONIC_REMAINS
				Return $cache['Salvage items.Trophies.Demonic Remains']
		EndSwitch
		;Return $cache['Salvage items.Trophies.Other trophies']

		If $MAP_FEATHER_TROPHIES[$itemID] <> Null Then Return True
		If $MAP_DUST_TROPHIES[$itemID] <> Null Then Return True
		If $MAP_BONES_TROPHIES[$itemID] <> Null Then Return True
		If $MAP_FIBER_TROPHIES[$itemID] <> Null Then Return True
		Return False
	; -------------------------------------- Materials --------------------------------------
	ElseIf IsRareMaterial($item) Then
		Local $materialName = $RARE_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $cache['Salvage items.Rare Materials.' & $materialName]
	EndIf
	Return False
EndFunc


;~ Return True if the item should be sold to the merchant - default to false
Func DefaultShouldSellItem($item)
	; Clarity rename
	Local $cache = $inventory_management_cache
	If $cache['@sell.nothing'] Then Return False

	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)

	If $rarity == $RARITY_GREEN Then
		Return False
	; --------------------------------------- Weapons ---------------------------------------
	ElseIf IsWeapon($item) Then
		If $cache['@sell.weapons.nothing'] Then Return False
		If Not CheckSellWeapon($item) Then Return False
		Return Not ShouldKeepWeapon($item)
	; --------------------------------- Armor salvageables ---------------------------------
	ElseIf isArmorSalvageItem($item) Then
		If $cache['@sell.salvageables.nothing'] Then Return False
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		If Not $cache['Sell items.Armor salvageables.' & $rarityName] Then Return False
		Return IsIdentified($item) And Not ContainsValuableUpgrades($item)
	; --------------------------------------- Scrolls ---------------------------------------
	ElseIf IsBlueScroll($itemID) Then
		Return $cache['Sell items.Scrolls.Blue']
	ElseIf IsGoldScroll($itemID) Then
		Local $scrollName = $GOLD_SCROLL_NAMES_FROM_IDS[$itemID]
		Local $shouldSell = $cache['Sell items.Scrolls.Gold.' & $scrollName]
		If $shouldSell <> Null Then Return $shouldSell
		Return $cache['Sell items.Scrolls.Gold.Other gold scrolls']
	; ----------------------------------------- Keys -----------------------------------------
	ElseIf IsKey($itemID) Then
		Return $cache['Sell items.Keys']
	EndIf
	Return False
EndFunc


;~ Return True if the item should be stored in Xunlai Storage - default to false
Func DefaultShouldStoreItem($item)
	; Clarity rename
	Local $cache = $inventory_management_cache
	If $cache['@store.nothing'] Then Return False

	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	Local $quantity = DllStructGetData($item, 'Quantity')

	; --------------------------------------- Weapons ---------------------------------------
	If IsWeapon($item) Then
		;Return ShouldKeepWeapon($item)
		Return CheckStoreWeapon($item)
	; --------------------------------- Armor salvageables ---------------------------------
	ElseIf isArmorSalvageItem($item) Then
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		;Return ContainsValuableUpgrades($item)
		Return $cache['Store items.Armor salvageables.' & $rarityName]
	; ------------------------------------- Consumables -------------------------------------
	ElseIf IsConsumable($itemID) Then
		If $quantity <> 250 Then Return False
		Return $cache['Store items.Consumables']
	ElseIf IsSpecialDrop($itemID) Then
		Local $festivalDropName = $SPECIAL_DROP_NAMES_FROM_IDS[$itemID]
		Return $cache['Store items.Festival Items.' & $festivalDropName]
	; --------------------------------------- Trophies ---------------------------------------
	ElseIf IsTrophy($itemID) Then
		If $quantity <> 250 Then Return False
		Return True
	; -------------------------------------- Materials --------------------------------------
	ElseIf IsBasicMaterial($item) Then
		If $quantity <> 250 Then Return False
		Local $materialName = $BASIC_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $cache['Store items.Basic Materials.' & $materialName]
	ElseIf IsRareMaterial($item) Then
		If $quantity <> 250 Then Return False
		Local $materialName = $RARE_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $cache['Store items.Rare Materials.' & $materialName]
	; ----------------------------------------- Tomes -----------------------------------------
	ElseIf IsRegularTome($itemID) Then
		Local $tomeName = $REGULAR_TOME_NAMES_FROM_IDS[$itemID]
		Return $cache['Store items.Tomes.Normal.' & $tomeName]
	ElseIf IsEliteTome($itemID) Then
		Local $tomeName = $ELITE_TOME_NAMES_FROM_IDS[$itemID]
		Return $cache['Store items.Tomes.Elite.' & $tomeName]
	; --------------------------------------- Scrolls ---------------------------------------
	ElseIf IsGoldScroll($itemID) Then
		Local $scrollName = $GOLD_SCROLL_NAMES_FROM_IDS[$itemID]
		Local $shouldStore = $cache['Store items.Scrolls.Gold.' & $scrollName]
		If $shouldStore <> Null Then Return $shouldStore
		Return $cache['Store items.Scrolls.Gold.Other gold scrolls']
	ElseIf IsBlueScroll($itemID) Then
		Return $cache['Store items.Scrolls.Blue']
	; ----------------------------------------- Keys -----------------------------------------
	ElseIf IsKey($itemID) Then
		Return $cache['Store items.Keys']
	; ----------------------------------------- Dyes -----------------------------------------
	ElseIf ($itemID == $ID_DYES) Then
		Local $dyeColorID = DllStructGetData($item, 'DyeColor')
		Local $dyeColorName = $DYE_NAMES_FROM_IDS[$dyeColorID]
		Return $cache['Store items.Dyes.' & $dyeColorName]
	EndIf
	Return False
EndFunc


;~ Return True if weapon item should not be sold or salvaged
Func ShouldKeepWeapon($item)
	Local Static $lowReqValuableWeaponTypes = [$ID_TYPE_SWORD, $ID_TYPE_OFFHAND, $ID_TYPE_SHIELD, $ID_TYPE_DAGGER, $ID_TYPE_SCYTHE, $ID_TYPE_SPEAR]
	Local Static $lowReqValuableWeaponTypesMap = MapFromArray($lowReqValuableWeaponTypes)
	Local Static $valuableOSWeaponTypes = [$ID_TYPE_SHIELD, $ID_TYPE_OFFHAND, $ID_TYPE_WAND]
	Local Static $valuableOSWeaponTypesMap = MapFromArray($valuableOSWeaponTypes)

	Local $rarity = GetRarity($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $type = DllStructGetData($item, 'Type')
	; Keeping equipped items
	If DllStructGetData($item, 'Equipped') Then Return True
	; Keeping customized items
	If DllStructGetData($item, 'Customized') <> 0 Then Return True
	; Throwing white items
	If $rarity == $RARITY_WHITE Then Return False
	; Keeping green items
	If $rarity == $RARITY_GREEN Then Return True
	; Keeping unidentified items
	If Not IsIdentified($item) Then Return True
	; Keeping super-rare items, good in all cases, items (BDS, voltaic, etc)
	If $MAP_ULTRA_RARE_WEAPONS[$itemID] <> Null Then Return True
	; Keeping items that contain good upgrades
	If ContainsValuableUpgrades($item) Then Return True
	; Throwing items without good damage/energy/armor
	If Not IsMaxDamageForReq($item) Then Return False
	; Inscribable are kept only if : 1) rare skin and q9 2) low Req of a good type
	If IsInscribable($item) Then
		If IsLowReqMaxDamage($item) And $lowReqValuableWeaponTypesMap[DllStructGetData($item, 'type')] <> Null Then Return True
		If GetItemReq($item) == 9 And $MAP_RARE_WEAPONS[$itemID] <> Null Then Return True
		Return False
	; OS - Old School weapon without inscription ... it is more complicated
	Else
		If GetItemReq($item) >= 9 Then
			; OS (Old School) high Req are kept only if : 1) rare skin and perfect/almost perfect mods 2) good type and perfect mods (shield, offhand, wand)
			If $MAP_RARE_WEAPONS[$itemID] <> Null Then
				Return HasPerfectMods($item) Or HasAlmostPerfectMods($item)
			ElseIf $valuableOSWeaponTypesMap[DllStructGetData($item, 'type')] <> Null Then
				Return HasPerfectMods($item)
			EndIf
			Return False
		Else
			; Low Req are kept if they have perfect mods, almost perfect mods, or a rare skin with somewhat okay mods
			If HasPerfectMods($item) Then Return True
			If HasAlmostPerfectMods($item) Then Return True
			If $MAP_RARE_WEAPONS[$itemID] <> Null And HasOkayMods($item) Then Return True
			Return False
		EndIf
	EndIf
	Return False
EndFunc


;~ Return true if basic material should be sold to the material merchant
Func DefaultShouldSellBasicMaterial($item)
	If Not IsBasicMaterial($item) Then Return False
	Local $materialID = DllStructGetData($item, 'ModelID')
	Local $materialName = $BASIC_MATERIAL_NAMES_FROM_IDS[$materialID]
	Return $inventory_management_cache['Sell items.Basic Materials.' & $materialName]
EndFunc


;~ Return true if rare material should be sold to the rare material merchant
Func DefaultShouldSellRareMaterial($item)
	If Not IsRareMaterial($item) Then Return False
	Local $materialID = DllStructGetData($item, 'ModelID')
	Local $materialName = $RARE_MATERIAL_NAMES_FROM_IDS[$materialID]
	Return $inventory_management_cache['Sell items.Rare Materials.' & $materialName]
EndFunc


Func CheckPickupWeapon($weaponItem)
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_RED Then Return True
	If $weaponRarity == $RARITY_GRAY Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Pick up items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc


Func CheckSalvageWeapon($weaponItem)
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GREEN Or $weaponRarity == $RARITY_GRAY Or $weaponRarity == $RARITY_RED Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Salvage items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc


Func CheckSellWeapon($weaponItem)
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GREEN Or $weaponRarity == $RARITY_GRAY Or $weaponRarity == $RARITY_RED Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Sell items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc


Func CheckStoreWeapon($weaponItem)
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GRAY Or $weaponRarity == $RARITY_RED Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Store items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc
#EndRegion Inventory Management


#Region Buying/selling items from/to merchant
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


;~ Buy salvage kits in town
Func BuySalvageKitInTown($amount = 1)
	While $amount > 10
		BuyInTown($ID_SALVAGE_KIT, 2, 100, 10, False)
		$amount -= 10
	WEnd
	If $amount > 0 Then BuyInTown($ID_SALVAGE_KIT, 2, 100, $amount, False)
EndFunc


;~ Buy expert salvage kits in town
Func BuyExpertSalvageKitInTown($amount = 1)
	While $amount > 10
		BuyInTown($ID_EXPERT_SALVAGE_KIT, 3, 400, 10, False)
		$amount -= 10
	WEnd
	If $amount > 0 Then BuyInTown($ID_EXPERT_SALVAGE_KIT, 3, 400, $amount, False)
EndFunc


;~ Buy superior salvage kits in town
Func BuySuperiorSalvageKitInTown($amount = 1)
	While $amount > 10
		BuyInTown($ID_SUPERIOR_SALVAGE_KIT, 4, 2000, 10, False)
		$amount -= 10
	WEnd
	If $amount > 0 Then BuyInTown($ID_SUPERIOR_SALVAGE_KIT, 4, 2000, $amount, False)
EndFunc


;~ Buy superior identification kits in town
Func BuySuperiorIdentificationKitInTown($amount = 1)
	While $amount > 10
		BuyInTown($ID_SUPERIOR_IDENTIFICATION_KIT, 6, 500, 10, False)
		$amount -= 10
	WEnd
	If $amount > 0 Then BuyInTown($ID_SUPERIOR_IDENTIFICATION_KIT, 6, 500, $amount, False)
EndFunc


;~ Sell general items to trader
Func SellItemsToMerchant($shouldSellItem = DefaultShouldSellItem, $dryRun = False, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to merchant to sell items')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $npcCoordinates = NPCCoordinatesInTown($tradeTown, 'Merchant')
	MoveTo($npcCoordinates[0], $npcCoordinates[1])
	Local $merchant = GetNearestNPCToCoords($npcCoordinates[0], $npcCoordinates[1])
	GoToNPC($merchant)
	RandomSleep(250)

	Info('Selling items')
	Local $item, $itemID
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 Then
				If $shouldSellItem($item) Then
					If Not $dryRun Then
						SellItem($item, DllStructGetData($item, 'Quantity'))
						RandomSleep(250)
					EndIf
				Else
					If $dryRun Then Info('Will not sell item at ' & $bagIndex & ':' & $i)
				EndIf
			EndIf
		Next
	Next
EndFunc


;~ Sell basic materials to materials merchant in town
Func SellBasicMaterialsToMerchant($shouldSellMaterial = DefaultShouldSellBasicMaterial, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $npcCoordinates = NPCCoordinatesInTown($tradeTown, 'Basic material trader')
	MoveTo($npcCoordinates[0], $npcCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($npcCoordinates[0], $npcCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	Local $item
	For $bagIndex = 1 To _Min(4, $bags_count)
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $shouldSellMaterial($item) Then
				SellItemToTrader($item)
			EndIf
		Next
	Next
EndFunc


;~ Sell rare materials to rare materials merchant in town
Func SellRareMaterialsToMerchant($shouldSellMaterial = DefaultShouldSellRareMaterial, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to rare materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $npcCoordinates = NPCCoordinatesInTown($tradeTown, 'Rare material trader')
	MoveTo($npcCoordinates[0], $npcCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($npcCoordinates[0], $npcCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	Local $item
	For $bagIndex = 1 To _Min(4, $bags_count)
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $shouldSellMaterial($item) Then
				SellItemToTrader($item)
			EndIf
		Next
	Next
EndFunc


;~ Buy rare material from rare materials merchant in town
Func BuyRareMaterialFromMerchant($materialModelID, $amount, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to rare materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $npcCoordinates = NPCCoordinatesInTown($tradeTown, 'Rare material trader')
	MoveTo($npcCoordinates[0], $npcCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($npcCoordinates[0], $npcCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	For $i = 1 To $amount
		TraderRequest($materialModelID)
		RandomSleep(250)
		Local $traderPrice = GetTraderCostValue()
		Debug('Buying for ' & $traderPrice)
		TraderBuy()
		RandomSleep(250)
	Next
	; TODO: add safety net to check amount of items bought and buy some more if needed
EndFunc


;~ Buy rare material from rare materials merchant in town until you have little or no money left
;~ Possible issue if you provide a very low poorThreshold and the price of an item hike up enough to reduce your money to less than 0
;~ So please only use with $poorThreshold > 5k
Func BuyRareMaterialFromMerchantUntilPoor($materialModelID, $poorThreshold = 20000, $backupMaterialModelID = Null, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	If CountSlots(1, 4) == 0 Then
		Warn('No room in inventory to buy rare materials, tick some checkboxes to clear inventory')
		Return
	EndIf
	Info('Moving to rare materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $npcCoordinates = NPCCoordinatesInTown($tradeTown, 'Rare material trader')
	MoveTo($npcCoordinates[0], $npcCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($npcCoordinates[0], $npcCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	Local $IDMaterialToBuy = $materialModelID
	TraderRequest($IDMaterialToBuy)
	RandomSleep(250)
	Local $traderPrice = GetTraderCostValue()
	If $traderPrice <= 0 Then
		Error('Could not get trader price for the original material')
		If ($backupMaterialModelID <> Null) Then
			TraderRequest($backupMaterialModelID)
			RandomSleep(250)
			Local $traderPrice = GetTraderCostValue()
			If $traderPrice <= 0 Then Return
			$IDMaterialToBuy = $backupMaterialModelID
			Notice('Falling back to backup material')
		Else
			Return
		EndIf
	EndIf
	Local $amount = Floor((GetGoldCharacter() - $poorThreshold) / $traderPrice)
	Info('Buying ' & $amount & ' items for ' & $traderPrice)
	While $amount > 0
		TraderBuy()
		RandomSleep(250)
		TraderRequest($IDMaterialToBuy)
		RandomSleep(250)
		$traderPrice = GetTraderCostValue()
		$amount -= 1
	WEnd
EndFunc


;~ Buy merchant items in town
;~ FIXME: error if total price is superior to 100k, add a loop for that
;~ FIXME: error if amount is superior to 250, add another loop for that
Func BuyInTown($itemID, $itemPosition, $itemPrice, $amount = 1, $stackable = False, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	If GetGoldCharacter() < $amount * $itemPrice And GetGoldStorage() > $amount * $itemPrice - 1 Then
		WithdrawGold($amount * $itemPrice)
		RandomSleep(500)
	EndIf

	Info('Moving to merchant to buy items')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $npcCoordinates = NPCCoordinatesInTown($tradeTown, 'Merchant')
	MoveTo($npcCoordinates[0], $npcCoordinates[1])
	Local $merchant = GetNearestNPCToCoords($npcCoordinates[0], $npcCoordinates[1])
	GoToNPC($merchant)
	RandomSleep(500)

	Local $xunlaiTemporarySlot = Null
	Local $spaceNeeded = $stackable ? 1 : $amount
	; There is no space in inventory, we need to store things in Xunlai to buy items
	If (CountSlots(1, 4) < $spaceNeeded) Then
		$xunlaiTemporarySlot = FindChestEmptySlots()
		If UBound($xunlaiTemporarySlot) < $spaceNeeded Then
			Error('Not enough space in inventory and storage to buy anything')
			Return False
		EndIf

		For $i = 0 To $spaceNeeded - 1
			MoveItem(GetItemBySlot(1, $i + 1), $xunlaiTemporarySlot[2 * $i], $xunlaiTemporarySlot[2 * $i + 1])
		Next
	EndIf

	Local $itemCount = GetInventoryItemCount($itemID)
	Local $targetItemCount = $itemCount + $amount
	Local $tryCount = 0
	While $itemCount < $targetItemCount
		If $tryCount == 10 Then Return False
		BuyItem($itemPosition, $amount, $itemPrice)
		RandomSleep(1000)
		$tryCount += 1
		$itemCount = GetInventoryItemCount($itemID)
	WEnd

	RandomSleep(500)
	If $xunlaiTemporarySlot <> Null Then
		Local $freeSpace = $stackable ? 1 : $amount
		For $i = 0 To $freeSpace - 1
			MoveItem(GetItemByModelID($itemID), $xunlaiTemporarySlot[2 * $i], $xunlaiTemporarySlot[2 * $i + 1])
		Next
	EndIf
EndFunc


;~ Buy kits for mid run salvage to preserve inventory space during run
Func BuyKitsForMidRun()
	; constants to determine how many kits should be in player's inventory
	Local Static $requiredSalvageKitUses = 300				; = 12 salvage kits with 25 uses,
	Local Static $requiredIdentificationKitUses = 400		; = 4 superior identification kits with 100 uses

	Local $salvageUses = CountRemainingKitUses($ID_SALVAGE_KIT)
	Local $salvageKitsRequired = KitsRequired($requiredSalvageKitUses - $salvageUses, $ID_SALVAGE_KIT)
	Local $identificationUses = CountRemainingKitUses($ID_SUPERIOR_IDENTIFICATION_KIT)
	Local $identificationKitsRequired = KitsRequired($requiredIdentificationKitUses - $identificationUses, $ID_SUPERIOR_IDENTIFICATION_KIT)

	If $salvageKitsRequired > 0 Then BuySalvageKitInTown($salvageKitsRequired)
	If $identificationKitsRequired > 0 Then BuySuperiorIdentificationKitInTown($identificationKitsRequired)
EndFunc
#EndRegion Buying/selling items from/to merchant


#Region Identification and salvage
;~ Get the number of uses of a kit
Func GetKitUsesLeft($kitID)
	Local $kitStruct = GetModStruct($kitID)
	Return Int('0x' & StringMid($kitStruct, 11, 2))
EndFunc


;~ Returns item ID of basic salvage kit in inventory.
Func FindBasicSalvageKit()
	Local $kits = [$ID_SALVAGE_KIT, $ID_SALVAGE_KIT_2]
	Return FindKit($kits)
EndFunc


;~ Returns item ID of salvage kit in inventory (except basic)
Func FindSalvageKit()
	Local $kits = [$ID_EXPERT_SALVAGE_KIT, $ID_SUPERIOR_SALVAGE_KIT]
	Return FindKit($kits)
EndFunc


;~ Returns item ID of identification kit in inventory.
Func FindIdentificationKit()
	Local $kits = [$ID_IDENTIFICATION_KIT, $ID_SUPERIOR_IDENTIFICATION_KIT]
	Return FindKit($kits)
EndFunc


;~ Returns kits
Func GetInventoryKitCount($enabledModelIDs)
	Local $kitCount = 0
	Local $item, $modelID

	For $i = 1 To 4
		For $j = 1 To DllStructGetData(GetBag($i), 'Slots')
			$item = GetItemBySlot($i, $j)
			$modelID = DllStructGetData($item, 'ModelID')

			; Skip this item if model is not in our list
			If Not FindKitArrayContainsHelper($enabledModelIDs, $modelID) Then ContinueLoop
			$kitCount += 1
		Next
	Next
	Return $kitCount
EndFunc


;~ Returns kit
Func FindKit($enabledModelIDs)
	Local $kit = Null
	Local $uses = 101
	Local $item, $modelID, $value

	For $i = 1 To 16
		For $j = 1 To DllStructGetData(GetBag($i), 'Slots')
			$item = GetItemBySlot($i, $j)
			$modelID = DllStructGetData($item, 'ModelID')

			; Skip this item if model is not in our list
			If Not FindKitArrayContainsHelper($enabledModelIDs, $modelID) Then ContinueLoop
			$value = DllStructGetData($item, 'Value')
			Switch $modelID
				Case $ID_SALVAGE_KIT, $ID_SALVAGE_KIT_2
					If $value / 2 < $uses Then
						$uses = $value / 2
						$kit = $item
					EndIf
				Case $ID_EXPERT_SALVAGE_KIT
					If $value / 8 < $uses Then
						$uses = $value / 8
						$kit = $item
					EndIf
				Case $ID_SUPERIOR_SALVAGE_KIT
					If $value / 10 < $uses Then
						$uses = $value / 10
						$kit = $item
					EndIf
				Case $ID_IDENTIFICATION_KIT
					If $value / 2 < $uses Then
						$uses = $value / 2
						$kit = $item
					EndIf
				Case $ID_SUPERIOR_IDENTIFICATION_KIT
					If $value / 2.5 < $uses Then
						$uses = $value / 2.5
						$kit = $item
					EndIf
			EndSwitch
		Next
	Next
	Return $kit
EndFunc


;~ Return True if item is present in array of items, else False - duplicate in Utils
Func FindKitArrayContainsHelper($itemsArray, $itemModelID)
	For $itemArrayModelID In $itemsArray
		If $itemArrayModelID == $itemModelID Then Return True
	Next
	Return False
EndFunc


;~ Function to calculate remaining count of uses of kits present in inventory, of modelID provided as parameter
Func CountRemainingKitUses($kitModelID)
	Local $allKitUses = 0
	Local $item, $itemModelID, $kitUses

	For $i = 1 To 4
		For $j = 1 To DllStructGetData(GetBag($i), 'Slots')
			$item = GetItemBySlot($i, $j)
			$itemModelID = DllStructGetData($item, 'ModelID')
			If $itemModelID <> $kitModelID Then ContinueLoop
			$kitUses = DllStructGetData($item, 'Value') / 2
			$allKitUses = $allKitUses + $kitUses
		Next
	Next
	Return $allKitUses
EndFunc


;~ Function to calculate required number of kits to perform required number of kit actions
Func KitsRequired($requiredkitUses, $kitModelID)
	Local $usesPerKit
	Switch $kitModelID
		Case $ID_PERFECT_SALVAGE_KIT, $ID_CHARR_SALVAGE_KIT
			$usesPerKit = 5
		Case $ID_SALVAGE_KIT_2
			$usesPerKit = 10
		Case $ID_IDENTIFICATION_KIT, $ID_SALVAGE_KIT, $ID_EXPERT_SALVAGE_KIT
			$usesPerKit = 25
		Case $ID_SUPERIOR_IDENTIFICATION_KIT, $ID_SUPERIOR_SALVAGE_KIT
			$usesPerKit = 100
	EndSwitch
	Return Ceiling($requiredkitUses / $usesPerKit)
EndFunc


#Region Identification
;~ Identify items from inventory
Func IdentifyItems($buyKit = True)
	Info('Identifying items')
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		Local $item
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
			If Not IsIdentified($item) Then
				Local $rarity = GetRarity($item)
				Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
				If Not $inventory_management_cache['Identify items.' & $rarityName] Then ContinueLoop

				Local $identificationKit = FindIdentificationKit()
				If $identificationKit == Null Then
					If $buyKit Then
						BuySuperiorIdentificationKitInTown()
					Else
						Return False
					EndIf
				EndIf
				IdentifyItem($item)
				RandomSleep(100)
			EndIf
		Next
	Next
	Return True
EndFunc


;~ Identifies all items in a bag.
Func IdentifyBag($bag, $identifyWhiteItems = False, $identifyGoldItems = True)
	Local $item
	For $i = 1 To DllStructGetData($bag, 'Slots')
		$item = GetItemBySlot(DllStructGetData($bag, 'index'), $i)
		If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
		If GetRarity($item) == $RARITY_WHITE And Not $identifyWhiteItems Then ContinueLoop
		If GetRarity($item) == $RARITY_GOLD And Not $identifyGoldItems Then ContinueLoop
		IdentifyItem($item)
	Next
EndFunc
#Region Identification


#Region Salvage
;~ Salvage items from inventory, only items specified by configuration in GUI interface
Func SalvageItems($buyKit = True)
	Local $kit = GetSalvageKit($buyKit)
	If $kit == 0 Then Return False
	Local $uses = DllStructGetData($kit, 'Value') / 2

	Local $movedItem = Null
	If (CountSlots(1, 4) < 1) Then
		; There is no space in inventory, we need to store something in Xunlai chest to start the salvage
		Local $xunlaiTemporarySlot = FindChestFirstEmptySlot()
		$movedItem = GetItemBySlot(_Min(4, $bags_count), 1)
		MoveItem($movedItem, $xunlaiTemporarySlot[0], $xunlaiTemporarySlot[1])
	EndIf

	Info('Salvaging items')
	Local $trophiesAndMaterialItems[60]
	Local $trophyAndMaterialIndex = 0
	For $bagIndex = 1 To _Min(4, $bags_count)
		Local $bagSize = DllStructGetData(GetBag($bagIndex), 'slots')
		For $slot = 1 To $bagSize
			Local $item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop

			Local $itemID = DllStructGetData($item, 'ModelID')
			If IsTrophy($itemID) Then
				If $inventory_management_cache['@salvage.trophies.nothing'] Then ContinueLoop
				; Trophies should be salvaged at the end, because they create a lot of materials
				$trophiesAndMaterialItems[$trophyAndMaterialIndex] = $item
				$trophyAndMaterialIndex += 1
			ElseIf IsRareMaterial($item) Then
				If $inventory_management_cache['@salvage.materials.nothing'] Then ContinueLoop
				; Rare materials should be salvaged at the end, because they create a lot of materials
				$trophiesAndMaterialItems[$trophyAndMaterialIndex] = $item
				$trophyAndMaterialIndex += 1
			Else
				If DefaultShouldSalvageItem($item) Then
					SalvageItem($item, $kit)
					$uses -= 1
					If $uses < 1 Then
						$kit = GetSalvageKit($buyKit)
						If $kit == Null Then Return False
						$uses = DllStructGetData($kit, 'Value') / 2
					EndIf
				EndIf
			EndIf
		Next
	Next

	; Moving removed item back from Xunlai chest to empty slot in inventory to check it to salvage it too
	If $movedItem <> Null Then
		Local $bagEmptySlot = FindFirstEmptySlot(1, _Min(4, $bags_count))
		MoveItem($movedItem, $bagEmptySlot[0], $bagEmptySlot[1])
		If DefaultShouldSalvageItem($movedItem) Then
			SalvageItem($movedItem, $kit)
			$uses -= 1
			If $uses < 1 Then
				$kit = GetSalvageKit($buyKit)
				If $kit == Null Then Return False
				$uses = DllStructGetData($kit, 'Value') / 2
			EndIf
		EndIf
	EndIf

	For $i = 0 To $trophyAndMaterialIndex - 1
		If DefaultShouldSalvageItem($trophiesAndMaterialItems[$i]) Then
			For $k = 0 To DllStructGetData($trophiesAndMaterialItems[$i], 'Quantity') - 1
				SalvageItem($trophiesAndMaterialItems[$i], $kit)
				$uses -= 1
				If $uses < 1 Then
					$kit = GetSalvageKit($buyKit)
					If $kit == Null Then Return False
					$uses = DllStructGetData($kit, 'Value') / 2
				EndIf
			Next
		EndIf
	Next
EndFunc


;~ Get a salvage kit from inventory, or buy one if not present
;~ Returns the kit or 0 if it was not found and not bought
Func GetSalvageKit($buyKit = True)
	Local $kit = FindBasicSalvageKit()
	If $kit == Null And $buyKit Then
		BuySalvageKitInTown()
		$kit = FindBasicSalvageKit()
	EndIf
	Return $kit
EndFunc


;~ Salvage an item based on its position in the inventory
Func SalvageItemAt($bagIndex, $slot)
	Local $item = GetItemBySlot($bagIndex, $slot)
	If DllStructGetData($item, 'ID') = 0 Then Return
	If DefaultShouldSalvageItem($item) Then
		SalvageItem($item, $salvageKit)
	EndIf
EndFunc


;~ Salvage the given item - FIXME: fails for weapons/armorsalvageable when using expert kits and better because they open a window
Func SalvageItem($item, $salvageKit)
	Local $rarity = GetRarity($item)
	While Not StartSalvageWithKit($item, $salvageKit)
		Sleep(GetPing())
	WEnd
	Sleep(600 + GetPing())
	If $rarity == $RARITY_gold Or $rarity == $RARITY_purple Then
		ValidateSalvage()
		Sleep(600 + GetPing())
	EndIf
	SendPacket(0x4, $HEADER_SALVAGE_MATERIALS)
	Sleep(40 + GetPing())
	Return True
EndFunc
#EndRegion Salvage
#EndRegion Identification and salvage


#Region Inventory and Chest Storage
;~ Move items to the equipment bag
Func MoveItemsToEquipmentBag()
	If $bags_count < 5 Then Return
	Local $equipmentBagEmptySlots = FindEmptySlots(5)
	Local $countEmptySlots = UBound($equipmentBagEmptySlots) / 2
	If $countEmptySlots < 1 Then
		Debug('No space in equipment bag to move the items to')
		Return
	EndIf

	Local $cursor = 1
	For $bagIndex = 4 To 1 Step -1
		For $slot = 1 To DllStructGetData(GetBag($bagIndex), 'slots')
			Local $item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ID') <> 0 And (isArmor($item) Or IsWeapon($item)) Then
				If $countEmptySlots < 1 Then
					Debug('No space in equipment bag to move the items to')
					Return
				EndIf
				MoveItem($item, 5, $equipmentBagEmptySlots[$cursor])
				$cursor += 2
				$countEmptySlots -= 1
				RandomSleep(50)
			EndIf
		Next
	Next
EndFunc


;~ Move all items out of the equipment bag so they can be salvaged
Func MoveItemsOutOfEquipmentBag()
	Local $equipmentBag = GetBag(5)
	Local $inventoryEmptySlots = FindAllEmptySlots(1, 4)
	Local $countEmptySlots = UBound($inventoryEmptySlots) / 2
	Local $cursor = 0
	If $countEmptySlots <= $cursor Then
		Warn('No space in inventory to move the items out of the equipment bag')
		Return 0
	EndIf

	For $slot = 1 To DllStructGetData($equipmentBag, 'slots')
		If $countEmptySlots <= $cursor Then
			Warn('No space in inventory to move the items out of the equipment bag')
			Return 0
		EndIf
		Local $item = GetItemBySlot(5, $slot)
		If DllStructGetData($item, 'ModelID') <> 0 Then
			If IsArmor($item) Then ContinueLoop
			If Not DefaultShouldSalvageItem($item) Then ContinueLoop
			MoveItem($item, $inventoryEmptySlots[2 * $cursor], $inventoryEmptySlots[2 * $cursor + 1])
			$cursor += 1
			RandomSleep(50)
		EndIf
	Next
	Return $cursor
EndFunc


;~ helper function for StoreEverythingInXunlaiStorage function
Func StoreAllItems($item = Null)
	Return True
EndFunc


;~ Store all items in the Xunlai Storage
Func StoreEverythingInXunlaiStorage()
	StoreItemsInXunlaiStorage(StoreAllItems)
EndFunc


;~ Store selected items in the Xunlai Storage
Func StoreItemsInXunlaiStorage($shouldStoreItem = DefaultShouldStoreItem)
	Info('Storing items')
	Local $item, $itemID
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 And $shouldStoreItem($item) Then
				Debug('Moving ' & $bagIndex & ':' & $i)
				If Not StoreItemInXunlaiStorage($item) Then Return False
				RandomSleep(50)
			EndIf
		Next
	Next
EndFunc


;~ Store an item in the Xunlai Storage
Func StoreItemInXunlaiStorage($item)
	Local $existingStacks
	Local $itemID, $storageSlot, $amount
	$itemID = DllStructGetData($item, 'ModelID')
	$amount = DllStructGetData($item, 'Quantity')

	If IsMaterial($item) Then
		Local $materialStorageLocation = $MAP_MATERIAL_LOCATION[$itemID]
		Local $materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $countMaterial = DllStructGetData($materialInStorage, 'Equipped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		MoveItem($item, 6, $materialStorageLocation)
		Sleep(20 + GetPing())
		$materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $newCountMaterial = DllStructGetData($materialInStorage, 'Equipped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		If $newCountMaterial - $countMaterial == $amount Then Return True
		$amount = DllStructGetData($item, 'Quantity')
	EndIf
	If (IsStackable($item) Or IsMaterial($item)) And $amount < 250 Then
		$existingStacks = FindAllInXunlaiStorage($item)
		Local $ping = GetPing()
		For $bagIndex = 0 To UBound($existingStacks) - 1 Step 2
			Local $existingStack = GetItemBySlot($existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
			Local $existingAmount = DllStructGetData($existingStack, 'Quantity')
			If $existingAmount < 250 Then
				Debug('To ' & $existingStacks[$bagIndex] & ':' & $existingStacks[$bagIndex + 1])
				MoveItem($item, $existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
				Sleep(20 + $ping)
				$amount = $amount + $existingAmount - 250
				If $amount <= 0 Then Return True
			EndIf
		Next
	EndIf
	$storageSlot = FindChestFirstEmptySlot()
	If $storageSlot[0] == 0 Then
		Warn('Storage is full')
		Return False
	EndIf
	Debug('To ' & $storageSlot[0] & ':' & $storageSlot[1])
	MoveItem($item, $storageSlot[0], $storageSlot[1])
	Sleep(20)
	Return True
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


;~ Balance character gold to the amount given - mode 0 = full balance, mode 1 = only withdraw, mode 2 = only deposit
Func BalanceCharacterGold($goldAmount, $mode = 0)
	Info('Balancing characters gold')
	Local $goldCharacter = GetGoldCharacter()
	Local $goldStorage = GetGoldStorage()
	If $goldStorage > 950000 Then
		Warn('Too much gold in chest, use some.')
	ElseIf $goldStorage < 50000 Then
		Warn('Not enough gold in chest, get some.')
	ElseIf $goldCharacter > $goldAmount And $mode <> 1 Then
		DepositGold($goldCharacter - $goldAmount)
	ElseIf $goldCharacter < $goldAmount And $mode <> 2 Then
		WithdrawGold($goldAmount - $goldCharacter)
	EndIf
	Return True
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
#EndRegion Inventory and Chest storage


#Region Loot items
;~ Loot items around character
Func PickUpItems($defendFunction = Null, $shouldPickItem = DefaultShouldPickItem, $range = $RANGE_COMPASS)
	If $inventory_management_cache['@pickup.nothing'] Then Return

	Local $item
	Local $agentID
	Local $deadlock
	Local $agents = GetAgentArray($ID_AGENT_TYPE_ITEM)
	Local $me = GetMyAgent()
	For $agent In $agents
		If IsPlayerDead() Then Return
		If Not GetCanPickUp($agent) Then ContinueLoop
		If GetDistance($me, $agent) > $range Then ContinueLoop

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


#Region Count and find items
;~ Find all empty slots in the given bag
Func FindEmptySlots($bagIndex)
	Local $bag = GetBag($bagIndex)
	Local $emptySlots[0] = []
	Local $item
	For $slot = 1 To DllStructGetData($bag, 'Slots')
		$item = GetItemBySlot($bagIndex, $slot)
		If DllStructGetData($item, 'ID') == 0 Then
			_ArrayAdd($emptySlots, $bagIndex)
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
	Local $bagEmptySlot[] = [0, 0]
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
Func FindEmptySlot($bagIndex)
	Local $item
	For $slot = 1 To DllStructGetData(GetBag($bagIndex), 'Slots')
		$item = GetItemBySlot($bagIndex, $slot)
		If DllStructGetData($item, 'ID') = 0 Then Return $slot
	Next
	; slots are indexed from 1, 0 if no empty slot found
	Return 0
EndFunc


;~ Find all empty slots in inventory
Func FindInventoryEmptySlots()
	Return FindAllEmptySlots(1, $bags_count)
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
Func CountSlots($fromBag = 1, $toBag = $bags_count)
	Local $bag
	Local $availableSlots = 0
	; If bag is missing it just will not count (Slots = 0, ItemsCount = 0)
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


;~ Returns true if there are materials in inventory
Func HasMaterials()
	Return HasInInventory(IsMaterial)
EndFunc


;~ Returns true if there are basic materials in inventory
Func HasBasicMaterials()
	Return HasInInventory(IsBasicMaterial)
EndFunc


;~ Returns true if there are rare materials in inventory
Func HasRareMaterials()
	Return HasInInventory(IsRareMaterial)
EndFunc


;~ Returns true if there are unidentified items in inventory
Func HasUnidentifiedItems()
	Return HasInInventory(IsUnidentified)
EndFunc


;~ Returns true if there are unidentified items in inventory
Func HasGoldUnidentifiedItems()
	Return HasInInventory(IsUnidentifiedGoldItem)
EndFunc


;~ Returns true if there are items in inventory that user selected to salvage in the GUI interface
Func HasItemsToSalvage($shouldSalvageItem = DefaultShouldSalvageItem)
	Return HasInInventory($shouldSalvageItem)
EndFunc


;~ Returns true if there are items in inventory that user selected to sell (merchant)
Func HasItemsToSell($shouldSellItem = DefaultShouldSellItem)
	Return HasInInventory($shouldSellItem)
EndFunc


;~ Returns true if there are basic materials in inventory that user selected to sell (trader)
Func HasBasicMaterialsToTrade($shouldSellMaterial = DefaultShouldSellBasicMaterial)
	Return HasInInventory($shouldSellMaterial)
EndFunc


;~ Returns true if there are basic materials in inventory that user selected to sell (trader)
Func HasRareMaterialsToTrade($shouldSellMaterial = DefaultShouldSellRareMaterial)
	Return HasInInventory($shouldSellMaterial)
EndFunc


;~ Returns true if there are items in inventory satisfying condition
Func HasInInventory($condition)
	Local $item, $itemID
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $condition($item) Then Return True
		Next
	Next
	Return False
EndFunc


;~ Counts black dyes in inventory
Func GetBlackDyeCount()
	Return GetInventoryItemCount($ID_BLACK_DYE)
EndFunc


;~ Counts birthday cupcakes in inventory
Func GetBirthdayCupcakeCount()
	Return GetInventoryItemCount($ID_BIRTHDAY_CUPCAKE)
EndFunc


;~ Counts gold items in inventory
Func CountGoldItems()
	Local $goldItemsCount = 0
	Local $item
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			If ((IsWeapon($item) Or IsArmorSalvageItem($item)) And GetRarity($item) == $RARITY_GOLD) Then $goldItemsCount += 1
		Next
	Next
	Return $goldItemsCount
EndFunc


;~ Destroy all items that fit the provided modelIDs
Func DestroyFromInventory($mapItemIDs)
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $bagSize
			Local $item = GetItemBySlot($bagIndex, $slot)
			If $mapItemIDs[DllStructGetData($item, 'ModelID')] <> Null Then
				DestroyItem($item)
				RandomSleep(1000)
			EndIf
		Next
	Next
EndFunc


;~ Look for any of the given items in bags and return bag and slot of an item, [0, 0] if none are present (positions start at 1)
Func FindAnyInInventory(ByRef $itemIDs)
	Local $itemBagAndSlot[2]
	$itemBagAndSlot[0] = $itemBagAndSlot[1] = 0

	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $bagSize
			Local $item = GetItemBySlot($bagIndex, $slot)
			For $itemID in $itemIDs
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
	Return FindInStorages(1, $bags_count, $itemID)
EndFunc


;~ Look for an item in xunlai storage
Func FindInXunlaiStorage($itemID)
	Return FindInStorages(8, 21, $itemID)
EndFunc


;~ Look for an item in storages from firstBag to lastBag and return bag and slot of the item, [0, 0] else (bags and slots are indexed from 1 as in GWToolbox)
Func FindInStorages($firstBag, $lastBag, $itemID)
	Local $item
	Local $itemBagAndSlot[] = [0, 0]

	For $bagIndex = $firstBag To $lastBag
		Local $bag = GetBag($bagIndex)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $bagSize
			$item = GetItemBySlot($bagIndex, $slot)
			If(DllStructGetData($item, 'ModelID') == $itemID) Then
				$itemBagAndSlot[0] = $bagIndex
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
	Local $dyeColor = ($itemID == $ID_DYES) ? DllStructGetData($item, 'DyeColor') : -1
	Local $storageItem

	For $bagIndex = $firstBag To $lastBag
		Local $bag = GetBag($bagIndex)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $bagSize
			$storageItem = GetItemBySlot($bagIndex, $slot)
			If (DllStructGetData($storageItem, 'ModelID') == $itemID) And ($dyeColor == -1 Or DllStructGetData($storageItem, 'DyeColor') == $dyeColor) Then
				_ArrayAdd($itemBagsAndSlots, $bagIndex)
				_ArrayAdd($itemBagsAndSlots, $slot)
			EndIf
		Next
	Next
	Return $itemBagsAndSlots
EndFunc


;~ Look for an item in inventory
Func FindAllInInventory($item)
	Return FindAllInStorages(1, $bags_count, $item)
EndFunc


;~ Look for an item in xunlai storage
Func FindAllInXunlaiStorage($item)
	Return FindAllInStorages(8, 21, $item)
EndFunc


;~ Counts anything in inventory
Func GetInventoryItemCount($itemID)
	Local $amountItem = 0
	Local $bag
	Local $item
	For $i = 1 To $bags_count
		$bag = GetBag($i)
		Local $bagSize = DllStructGetData($bag, 'Slots')
		For $j = 1 To $bagSize
			$item = GetItemBySlot($i, $j)

			If $MAP_DYES[$itemID] <> Null Then
				If (DllStructGetData($item, 'ModelID') == $ID_DYES) And (DllStructGetData($item, 'DyeColor') == $itemID) Then $amountItem += DllStructGetData($item, 'Quantity')
			Else
				If DllStructGetData($item, 'ModelID') == $itemID Then $amountItem += DllStructGetData($item, 'Quantity')
			EndIf
		Next
	Next
	Return $amountItem
EndFunc


;~ Count quantity of each item in inventory, specified in provided array of items
;~ Returns a corresponding array of counters, of the same size as provided array
Func CountTheseItems($itemArray)
	Local $arraySize = UBound($itemArray)
	Local $counts[$arraySize]
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		Local $slots = DllStructGetData($bag, 'Slots')
		For $slot = 1 To $slots
			Local $item = GetItemBySlot($bagIndex, $slot)
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
;~ Use morale booster on team
Func UseMoraleConsumableIfNeeded()
	While TeamHasTooMuchMalus()
		Local $usedMoraleBooster = False
		For $DPRemoval_Sweet In $DP_REMOVAL_SWEETS
			Local $consumableSlot = FindInInventory($DPRemoval_Sweet)
			If $consumableSlot[0] <> 0 Then
				UseItemBySlot($consumableSlot[0], $consumableSlot[1])
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
	If (Not $forceUse And Not $run_options_cache['run.consume_consumables']) Then Return $FAIL
	If GetMapType() <> $ID_OUTPOST Then Return $FAIL
	If GetEffectTimeRemaining(GetEffect($ID_SUGAR_JOLT_SHORT)) > 0 Or GetEffectTimeRemaining(GetEffect($ID_SUGAR_JOLT_LONG)) > 0 Then Return $SUCCESS
	Local $consumableSlot = FindInInventory($ID_SUGARY_BLUE_DRINK)
	If $consumableSlot[0] <> 0 Then
		UseItemBySlot($consumableSlot[0], $consumableSlot[1])
	Else
		$consumableSlot = FindInInventory($ID_CHOCOLATE_BUNNY)
		If $consumableSlot[0] <> 0 Then UseItemBySlot($consumableSlot[0], $consumableSlot[1])
	EndIf
	Return $SUCCESS
EndFunc


;~ Uses an item from inventory or chest, if present
Func UseItemFromInventory($itemID, $forceUse = False, $checkXunlaiChest = True)
	Local $consumableItemBagAndSlot
	If $checkXunlaiChest == True And GetMapType() == $ID_OUTPOST Then
		$consumableItemBagAndSlot = FindInStorages(1, 21, $itemID)
	Else
		$consumableItemBagAndSlot = FindInStorages(1, $bags_count, $itemID)
	EndIf

	Local $consumableBag = $consumableItemBagAndSlot[0]
	Local $consumableSlot = $consumableItemBagAndSlot[1]
	If $consumableBag <> 0 And $consumableSlot <> 0 Then
		UseItemBySlot($consumableBag, $consumableSlot)
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


;~ Uses a consumable from inventory or chest, if present
Func UseConsumable($consumableID, $forceUse = False, $checkXunlaiChest = True)
	If (Not $forceUse And Not $run_options_cache['run.consume_consumables']) Then Return
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
Func UseItemBySlot($bagIndex, $slot)
	If $bagIndex > 0 And $slot > 0 Then
		If IsPlayerAlive() And GetMapType() <> $ID_LOADING Then
			Local $item = GetItemBySlot($bagIndex, $slot)
			SendPacket(8, $HEADER_Item_USE, DllStructGetData($item, 'ID'))
		EndIf
	EndIf
EndFunc
#EndRegion Use Items


#Region Items tests
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
	Info('ModelID: ' & DllStructGetData($item, 'ModelID'))
	Info('ItemFormula: ' & DllStructGetData($item, 'ItemFormula'))
	Info('IsMaterialSalvageable: ' & DllStructGetData($item, 'IsMaterialSalvageable'))
	Info('Quantity: ' & DllStructGetData($item, 'Quantity'))
	Info('Equipped: ' & DllStructGetData($item, 'Equipped'))
	Info('Profession: ' & DllStructGetData($item, 'Profession'))
	Info('Type2: ' & DllStructGetData($item, 'Type2'))
	Info('Slot: ' & DllStructGetData($item, 'Slot'))
EndFunc


;~ Get the item damage (maximum, not minimum)
Func GetItemMaxDmg($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $modString = GetModStruct($item)
	Local $position = StringInStr($modString, 'A8A7')						; Weapon Damage
	If $position = 0 Then $position = StringInStr($modString, 'C867')		; Energy (focus)
	If $position = 0 Then $position = StringInStr($modString, 'B8A7')		; Armor (shield)
	If $position = 0 Then Return 0
	Return Int('0x' & StringMid($modString, $position - 2, 2))
EndFunc


;~ Return True if the item is a kit or a lockpick - used in Storage Bot to not sell those
Func IsGeneralItem($itemID)
	Return $MAP_GENERAL_ITEMS[$itemID] <> Null
EndFunc


;~ Returns true if the item is an armor salvage
Func IsArmorSalvageItem($item)
	Return DllStructGetData($item, 'type') == $ID_TYPE_ARMOR_SALVAGE
EndFunc


;~ Returns true if the item is a book
Func IsBook($item)
	Return DllStructGetData($item, 'type') == $ID_TYPE_BOOK
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
	Return DllStructGetData($item, 'Type') == 11 And $MAP_ALL_MATERIALS[DllStructGetData($item, 'ModelID')] <> Null
EndFunc


;~ Returns true if the item is a basic material
Func IsBasicMaterial($item)
	;Return DllStructGetData($item, 'Type') == 11 And $MAP_BASIC_MATERIALS[DllStructGetData($item, 'ModelID')] <> Null
	Return DllStructGetData($item, 'Type') == 11 And BitAND(DllStructGetData($item, 'Interaction'), 0x20) <> 0
EndFunc


;~ Returns true if the item is a rare material
Func IsRareMaterial($item)
	;Return DllStructGetData($item, 'Type') == 11 And $MAP_RARE_MATERIALS[DllStructGetData($item, 'ModelID')] <> Null
	Return DllStructGetData($item, 'Type') == 11 And Not IsBasicMaterial($item)
EndFunc


;~ Returns true if the item is a consumable
Func IsConsumable($itemID)
	Return IsAlcohol($itemID) Or IsFestive($itemID) Or IsTownSweet($itemID) Or IsPCon($itemID) Or IsDPRemovalSweet($itemID) Or _
		IsSummoningStone($itemID) Or IsPartyTonic($itemID) Or IsEverlastingTonic($itemID) Or IsConset($itemID)
EndFunc


;~ Returns true if the item is 1 of 3 conset items: Essence of Celerity, Armor of Salvation, Grail of Might
Func IsConset($itemID)
	Return $MAP_CONSETS[$itemID] <> Null
EndFunc


;~ Returns true if the item is an alcohol
Func IsAlcohol($itemID)
	Return $MAP_ALCOHOLS[$itemID] <> Null
EndFunc


;~ Returns true if the item is a festive item
Func IsFestive($itemID)
	Return $MAP_FESTIVE[$itemID] <> Null
EndFunc


;~ Returns true if the item is a sweet
Func IsTownSweet($itemID)
	Return $MAP_TOWN_SWEETS[$itemID] <> Null
EndFunc


;~ Returns true if the item is a PCon
Func IsPCon($itemID)
	Return $MAP_SWEET_PCONS[$itemID] <> Null
EndFunc


;~ Return true if the item is a sweet removing doubl... death penalty
Func IsDPRemovalSweet($itemID)
	Return $MAP_DP_REMOVAL_SWEETS[$itemID] <> Null
EndFunc


;~ Return true if the item is a special drop
Func IsSpecialDrop($itemID)
	Return $MAP_SPECIAL_DROPS[$itemID] <> Null
EndFunc


;~ Return true if the item is a summoning stone
Func IsSummoningStone($itemID)
	Return $MAP_SUMMONING_STONES[$itemID] <> Null
EndFunc


;~ Return true if the item is a party tonic
Func IsPartyTonic($itemID)
	Return $MAP_PARTY_TONICS[$itemID] <> Null
EndFunc


;~ Return true if the item is an everlasting tonic
Func IsEverlastingTonic($itemID)
	Return $MAP_EL_TONICS[$itemID] <> Null
EndFunc


;~ Return true if the item is a trophy
Func IsTrophy($itemID)
	Return $MAP_TROPHIES[$itemID] <> Null Or $MAP_REWARD_TROPHIES[$itemID] <> Null
EndFunc


;~ Return true if the item is an armor
Func IsArmor($item)
	Return $MAP_ARMOR_TYPES[DllStructGetData($item, 'type')] <> Null
EndFunc


;~ Return true if the item is a weapon
Func IsWeapon($item)
	Return $MAP_WEAPON_TYPES[DllStructGetData($item, 'type')] <> Null
EndFunc


;~ Return true if the item is a weapon mod
Func IsWeaponMod($itemID)
	Return $MAP_WEAPON_MODS[$itemID] <> Null
EndFunc


;~ Return true if the item is a tome
Func IsTome($itemID)
	Return $MAP_TOMES[$itemID] <> Null
EndFunc


;~ Return true if the item is a regular tome
Func IsRegularTome($itemID)
	Return $MAP_REGULAR_TOMES[$itemID] <> Null
EndFunc


;~ Return true if the item is an elite tome
Func IsEliteTome($itemID)
	Return $MAP_ELITE_TOMES[$itemID] <> Null
EndFunc


;~ Return true if the item is a gold scroll
Func IsGoldScroll($itemID)
	Return $MAP_GOLD_SCROLLS[$itemID] <> Null
EndFunc


;~ Return true if the item is a blue scroll
Func IsBlueScroll($itemID)
	Return $MAP_BLUE_SCROLLS[$itemID] <> Null
EndFunc


;~ Return true if the item is a key
Func IsKey($itemID)
	Return $MAP_KEYS[$itemID] <> Null
EndFunc


;~ Return true if the item is a map piece
Func IsMapPiece($itemID)
	Return $MAP_MAP_PIECES[$itemID] <> Null
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
	Local $weaponMaxDamages = $WEAPONS_MAX_DAMAGE_PER_LEVEL[$type]
	Local $maxDamage = $weaponMaxDamages[$requirement]
	If $damage == $maxDamage Then Return True
	Return False
EndFunc


;~ Returns true if an item has a 'Salvageable' inscription
Func HasSalvageInscription($item)
	Local $salvageableInscription[] = ['1F0208243E0432251', '0008260711A8A7000000C', '0008261323A8A7000000C', '00082600011826900098260F1CA8A7000000C']
	Local $modstruct = GetModStruct($item)
	For $salvageableModStruct in $salvageableInscription
		If StringInStr($modstruct, $salvageableModStruct) Then Return True
	Next
	Return False
EndFunc
#EndRegion Items tests


#Region Reading items data
;~ Read data from item at bagIndex and slot and print it in the console
Func ReadOneItemData($bagIndex, $slot)
	Info('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $output = GetOneItemData($bagIndex, $slot)
	If $output == '' Then Return
	Info($output)
EndFunc


;~ Read data from all items in inventory and print it in the console
Func ReadAllItemsData()
	Info('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $item, $output
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $slot = 1 To DllStructGetData($bag, 'slots')
			$output = GetOneItemData($bagIndex, $slot)
			If $output == '' Then ContinueLoop
			Info($output)
			RandomSleep(50)
		Next
	Next
EndFunc


;~ Get data from an item into a string
Func GetOneItemData($bagIndex, $slot)
	Local $item = GetItemBySlot($bagIndex, $slot)
	Local $output = ''
	If DllStructGetData($item, 'ID') <> 0 Then
		$output &= $bagIndex & ';'
		$output &= $slot & ';'
		$output &= DllStructGetData($item, 'rarity') & ';'
		$output &= DllStructGetData($item, 'ModelID') & ';'
		$output &= DllStructGetData($item, 'ID') & ';'
		$output &= DllStructGetData($item, 'Type') & ';'
		$output &= GetOrDefault(GetItemAttribute($item) & ';', '')
		$output &= GetOrDefault(GetItemReq($item) & ';', '')
		$output &= GetOrDefault(GetItemMaxDmg($item) & ';', '')
		$output &= DllStructGetData($item, 'NameString') & ';'
		$output &= GetModStruct($item) & ';'
		$output &= DllStructGetData($item, 'quantity') & ';'
		$output &= GetOrDefault(DllStructGetData($item, 'Value') & ';', 0)
	EndIf
	Return $output
EndFunc
#EndRegion Reading items data


#Region Database
Global $sqlite_db

#Region Tables
; Those tables are built automatically and one is completed by the user
Global Const $TABLE_DATA_RAW = 'DATA_RAW'
Global Const $SCHEMA_DATA_RAW = ['batch', 'bag', 'slot', 'model_ID', 'type_ID', 'min_stat', 'max_stat', 'requirement', 'attribute_ID', 'name_string', 'OS', 'modstruct', 'quantity', 'value', 'rarity_ID', 'dye_color', 'ID']
							;address ? interaction ? model_file_ID ? name enc ? desc enc ? several modstruct (4, 8 ?) - identifier, arg1, arg2

Global Const $TABLE_DATA_USER = 'DATA_USER'
Global Const $SCHEMA_DATA_USER = ['batch', 'bag', 'slot', 'rarity', 'type', 'requirement', 'attribute', 'value', 'name', 'OS', 'prefix', 'suffix', 'inscription', 'type_ID', 'model_ID', 'name_string', 'modstruct', 'dye_color', 'ID']

Global Const $TABLE_DATA_SALVAGE = 'DATA_SALVAGE'
Global Const $SCHEMA_DATA_SALVAGE = ['batch', 'model_ID', 'material', 'amount']

; Those 3 lookups are filled directly when database is created
Global Const $TABLE_LOOKUP_ATTRIBUTE = 'LOOKUP_ATTRIBUTE'
Global Const $SCHEMA_LOOKUP_ATTRIBUTE = ['attribute_ID', 'attribute']

Global Const $TABLE_LOOKUP_RARITY = 'LOOKUP_RARITY'
Global Const $SCHEMA_LOOKUP_RARITY = ['rarity_ID', 'rarity']

Global Const $TABLE_LOOKUP_TYPE = 'LOOKUP_TYPE'
Global Const $SCHEMA_LOOKUP_TYPE = ['type_ID', 'type']

; Those lookups are built from the data table filled by the user
Global Const $TABLE_LOOKUP_MODEL = 'LOOKUP_MODEL'
Global Const $SCHEMA_LOOKUP_MODEL = ['type_ID', 'model_ID', 'model_name', 'OS']

Global Const $TABLE_LOOKUP_UPGRADES = 'LOOKUP_UPGRADES'
Global Const $SCHEMA_LOOKUP_UPGRADES = ['OS', 'upgrade_type', 'weapon', 'effect', 'hexa', 'name', 'propagate']
#EndRegion Tables


;~ Connect to the database storing information about items
Func ConnectToDatabase()
	_SQLite_Startup()
	If @error Then Exit MsgBox(16, 'SQLite Error', 'Failed to start SQLite')
	FileChangeDir(@ScriptDir)
	$sqlite_db = _SQLite_Open('data\items_database.db3')
	If @error Then Exit MsgBox(16, 'SQLite Error', 'Failed to open database: ' & _SQLite_ErrMsg())
	;_SQLite_SetSafeMode(False)
	Info('Opened database at ' & @ScriptDir & '\data\items_database.db3')
EndFunc


;~ Disconnect from the database
Func DisconnectFromDatabase()
	_SQLite_Close()
	_SQLite_Shutdown()
EndFunc


;~ Create tables and views and fill the ones that need it
Func InitializeDatabase()
	CreateTable($TABLE_LOOKUP_ATTRIBUTE, $SCHEMA_LOOKUP_ATTRIBUTE)
	CreateTable($TABLE_LOOKUP_RARITY, $SCHEMA_LOOKUP_RARITY)
	CreateTable($TABLE_LOOKUP_TYPE, $SCHEMA_LOOKUP_TYPE)

	CreateTable($TABLE_LOOKUP_MODEL, $SCHEMA_LOOKUP_MODEL)
	CreateTable($TABLE_LOOKUP_UPGRADES, $SCHEMA_LOOKUP_UPGRADES)

	CreateTable($TABLE_DATA_RAW, $SCHEMA_DATA_RAW)
	CreateTable($TABLE_DATA_USER, $SCHEMA_DATA_USER)

	Local $columnsTypeIsNumber[] = [True, False]
	If TableIsEmpty($TABLE_LOOKUP_TYPE) Then FillTable($TABLE_LOOKUP_TYPE, $columnsTypeIsNumber, $ITEM_TYPES_DOUBLE_ARRAY)
	If TableIsEmpty($TABLE_LOOKUP_ATTRIBUTE) Then FillTable($TABLE_LOOKUP_ATTRIBUTE, $columnsTypeIsNumber, $ATTRIBUTES_DOUBLE_ARRAY)
	If TableIsEmpty($TABLE_LOOKUP_RARITY) Then FillTable($TABLE_LOOKUP_RARITY, $columnsTypeIsNumber, $RARITIES_DOUBLE_ARRAY)
EndFunc


;~ Create a table
Func CreateTable($tableName, $tableColumns, $ifNotExists = True)
	Local $query = 'CREATE TABLE '
	If $ifNotExists Then $query &= 'IF NOT EXISTS '
	$query &= $tableName & ' ('
	For $column in $tableColumns
		$query &= $column & ', '
	Next
	$query = StringLeft($query, StringLen($query) - 2)
	$query &= ');'
	SQLExecute($query)
EndFunc


;~ Drop a table
Func DropTable($tableName)
	Local $query = 'DROP TABLE IF EXISTS ' & $tableName & ';'
	SQLExecute($query)
EndFunc


;~ Fill a table with the given values (bidimensional array)
Func FillTable($table, Const ByRef $isNumber, Const ByRef $values)
	Local $query = 'INSERT INTO ' & $table & ' VALUES '
	For $i = 0 To UBound($values) - 1
		$query &= '('
		For $j = 0 To UBound($values,2) - 1
			If $isNumber[$j] Then
				$query &= $values[$i][$j] & ', '
			Else
				$query &= "'" & $values[$i][$j] & "', "
			EndIf
		Next
		$query = StringLeft($query, StringLen($query) - 2)
		$query &= '), '
	Next

	$query = StringLeft($query, StringLen($query) - 2)
	$query &= ';'
	SQLExecute($query)
EndFunc


#Region Database Utils
;~ Returns true if a table exists
Func TableExists($table)
	Local $query, $queryResult, $row
	SQLQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='" & $table & "';", $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$lastBatchID = $row[0]
	WEnd
	Return $lastBatchID
EndFunc


;~ Returns true if a table is empty
Func TableIsEmpty($table)
	Local $query, $queryResult, $row, $rowCount
	SQLQuery('SELECT COUNT(*) FROM ' & $table & ';', $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$rowCount = $row[0]
	WEnd
	Return $rowCount == 0
EndFunc


;~ Query database
Func SQLQuery($query, ByRef $queryResult)
	Debug($query)
	Local $result = _SQLite_Query($sqlite_db, $query, $queryResult)
	If $result <> 0 Then Error('Query failed ! Failure on : ' & @CRLF & $query)
EndFunc


;~ Execute a request on the database
Func SQLExecute($query)
	Debug($query)
	Local $result = _SQLite_Exec($sqlite_db, $query)
	If $result <> 0 Then Error('Query failed ! Failure on : ' & @CRLF & $query & @CRLF & @error)
EndFunc
#EndRegion Database Utils


;~ Store in database all data that can be found in items in inventory
Func StoreAllItemsData()
	Local $insertQuery, $item
	Local $batchID = GetPreviousBatchID() + 1

	Info('Scanning and storing all items data')
	SQLExecute('BEGIN;')
	$insertQuery = 'INSERT INTO ' & $TABLE_DATA_RAW & ' VALUES' & @CRLF
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			GetItemReq($item)
			$insertQuery &= '	('
			$insertQuery &= $batchID & ', '
			$insertQuery &= $bagIndex & ', '
			$insertQuery &= $i & ', '
			$insertQuery &= DllStructGetData($item, 'modelID') & ', '
			$insertQuery &= DllStructGetData($item, 'type') & ', '
			$insertQuery &= 'NULL, '
			$insertQuery &= (IsWeapon($item) ? GetItemMaxDmg($item) : 'NULL') & ', '
			$insertQuery &= (IsWeapon($item) ? GetItemReq($item) : 'NULL') & ', '
			$insertQuery &= (IsWeapon($item) ? GetItemAttribute($item) : 'NULL') & ", '"
			$insertQuery &= DllStructGetData($item, 'nameString') & "', '"
			$insertQuery &= (IsInscribable($item) ? 0 : 1) & "', '"
			$insertQuery &= GetModStruct($item) & "', "
			$insertQuery &= DllStructGetData($item, 'quantity') & ', '
			$insertQuery &= GetOrDefault(DllStructGetData($item, 'value'), 0) & ', '
			$insertQuery &= GetRarity($item) & ', '
			$insertQuery &= DllStructGetData($item, 'DyeColor') & ', '
			$insertQuery &= DllStructGetData($item, 'ID')
			$insertQuery &= '),' & @CRLF
			Sleep(20)
		Next
	Next

	$insertQuery = StringLeft($insertQuery, StringLen($insertQuery) - 3) & @CRLF & ';'
	SQLExecute($insertQuery)
	SQLExecute('COMMIT;')

	AddToFilledData($batchID)
	CompleteItemsMods($batchID)
EndFunc


;~ Insert data into the RAW data table
Func AddToFilledData($batchID)
	Local $insertQuery = 'WITH raw AS (' & @CRLF _
		& '	SELECT batch, bag, slot, value, requirement, rarity_ID, type_ID, attribute_ID, model_ID, type_ID, model_ID, name_string, OS, modstruct, dye_color, ID FROM ' & $TABLE_DATA_RAW & ' WHERE batch = ' & $batchID & @CRLF _
		& ')' & @CRLF _
		& 'INSERT INTO ' & $TABLE_DATA_USER & @CRLF _
		& 'SELECT raw.batch, raw.bag, raw.slot, rarities.rarity, types.type, requirement, attributes.attribute, raw.value, names.model_name, raw.OS, NULL, NULL, NULL, raw.type_ID, raw.model_ID, raw.name_string, raw.modstruct, raw.dye_color, raw.ID' & @CRLF _
		& 'FROM raw' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_RARITY & ' rarities ON raw.rarity_ID = rarities.rarity_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_TYPE & ' types ON raw.type_ID = types.type_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_ATTRIBUTE & ' attributes ON raw.attribute_ID = attributes.attribute_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_MODEL & ' names ON raw.type_ID = names.type_ID AND raw.model_ID = names.model_ID;'
	SQLExecute($insertQuery)
EndFunc


;~ Auto fill the items mods based on the known modstructs
Func CompleteItemsMods($batchID)
	Info('Completing items mods')
	Local $upgradeTypes[] = ['prefix', 'suffix', 'inscription']
	Local $query
	For $upgradeType In $upgradeTypes
		$query = 'UPDATE ' & $TABLE_DATA_USER & @CRLF _
			& 'SET ' & $upgradeType & ' = (' & @CRLF _
			& '	SELECT upgrades.effect' & @CRLF _
			& '	FROM ' & $TABLE_LOOKUP_UPGRADES & ' upgrades' & @CRLF _
			& '	WHERE upgrades.propagate = 1' & @CRLF _
			& '		AND upgrades.weapon = type_ID' & @CRLF _
			& '		AND upgrades.hexa IS NOT NULL' & @CRLF _
			& "		AND upgrades.upgrade_type = '" & $upgradeType & "'" & @CRLF _
			& "		AND modstruct LIKE ('%' || upgrades.hexa || '%')" & @CRLF _
			& ')' & @CRLF _
			& 'WHERE ' & $upgradeType & ' IS NULL' & @CRLF _
			& '	AND batch = ' & $batchID & @CRLF _
			& '	AND EXISTS (' & @CRLF _
			& '		SELECT upgrades.effect' & @CRLF _
			& '		FROM ' & $TABLE_LOOKUP_UPGRADES & ' upgrades' & @CRLF _
			& '		WHERE upgrades.propagate = 1' & @CRLF _
			& '			AND upgrades.weapon = type_ID' & @CRLF _
			& '			AND upgrades.hexa IS NOT NULL' & @CRLF _
			& "			AND upgrades.upgrade_type = '" & $upgradeType & "'" & @CRLF _
			& "			AND modstruct LIKE ('%' || upgrades.hexa || '%')" & @CRLF _
			& ');'
		SQLExecute($query)
	Next
EndFunc


;~ Get the previous batchID or -1 if no batch has been added into database
Func GetPreviousBatchID()
	Local $queryResult, $row, $lastBatchID, $query
	$query = 'SELECT COALESCE(MAX(batch), -1) FROM ' & $TABLE_DATA_RAW & ';'
	SQLQuery($query, $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$lastBatchID = $row[0]
	WEnd
	Return $lastBatchID
EndFunc


;~ Complete model name lookup table
Func CompleteModelLookupTable()
	Local $query
	Info('Completing model lookup ')
	$query = 'INSERT INTO ' & $TABLE_LOOKUP_MODEL & @CRLF _
		& 'SELECT DISTINCT type_ID, model_ID, name, OS' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE name IS NOT NULL' & @CRLF _
		& '	AND (type_ID, model_ID) NOT IN (SELECT type_ID, model_ID FROM ' & $TABLE_LOOKUP_MODEL & ');'
	SQLExecute($query)
EndFunc


;~ Complete mods data by cross-comparing all modstructs from items that have the same mods and deduce the mod hexa from it
Func CompleteUpgradeLookupTable()
	Info('Completing upgrade lookup')
	Local $modTypes[] = ['prefix', 'suffix', 'inscription']
	For $upgradeType In $modTypes
		InsertNewUpgrades($upgradeType)
		UpdateNewUpgrades($upgradeType)
		ValidateNewUpgrades($upgradeType)
	Next
EndFunc


;~ Insert upgrades not already present in database
Func InsertNewUpgrades($upgradeType)
	Local $query = 'INSERT INTO ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
		& "SELECT DISTINCT OS, '" & $upgradeType & "', type_ID, " & $upgradeType & ', NULL, NULL, 0' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE ' & $upgradeType & ' IS NOT NULL' & @CRLF _
		& "AND (OS, '" & $upgradeType & "', type_ID, " & $upgradeType & ') NOT IN (SELECT OS, upgrade_type, weapon, effect FROM ' & $TABLE_LOOKUP_UPGRADES & ');'
	SQLExecute($query)
EndFunc


;~ Update upgrades with their hexa struct if we manage to find enough similarities
Func UpdateNewUpgrades($upgradeType)
	Local $queryResult, $row
	Local $mapItemStruct[]
	Local $query = 'WITH valid_groups AS (' & @CRLF _
		& '	SELECT OS, type_ID AS weapon, ' & $upgradeType & ' FROM ' & $TABLE_DATA_USER & ' WHERE ' & $upgradeType & ' IS NOT NULL GROUP BY OS, weapon, ' & $upgradeType & ' HAVING COUNT(*) > 3' & @CRLF _
		& ')' & @CRLF _
		& 'SELECT valid_groups.OS, weapon, valid_groups.' & $upgradeType & ', data.modstruct' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & ' data' & @CRLF _
		& 'INNER JOIN valid_groups' & @CRLF _
		& '	ON valid_groups.OS = data.OS AND valid_groups.weapon = data.type_ID AND valid_groups.' & $upgradeType & ' = data.' & $upgradeType & @CRLF _
		& 'ORDER BY valid_groups.' & $upgradeType & ';'
	SQLQuery($query, $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$mapItemStruct = AppendArrayMap($mapItemStruct, $row[0] & '|' & $row[1] & '|' & $row[2], $row[3])
	WEnd

	Local $osWeaponUpgradeTypes = MapKeys($mapItemStruct)
	For $OSWeaponUpgradeType In $osWeaponUpgradeTypes
		Local $modStruct = LongestCommonSubstring($mapItemStruct[$OSWeaponUpgradeType])
		Local $bananaSplit = StringSplit($OSWeaponUpgradeType, '|')

		$query = 'UPDATE ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
			& "	SET hexa = '" & $modStruct & "' WHERE OS = " & $bananaSplit[1] & " AND upgrade_type = '" & $upgradeType & "' AND weapon = " & $bananaSplit[2] & " AND effect = '" & $bananaSplit[3] & "';"
		SQLExecute($query)
	Next
EndFunc


;~ Validate that the upgrades hexa structs we found are correct
Func ValidateNewUpgrades($upgradeType)
	Local $query
	$query = 'UPDATE ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
		& 'SET propagate = 2' & @CRLF _
		& 'WHERE hexa IS NOT NULL' & @CRLF _
		& 'AND EXISTS (' & @CRLF _
		& "	SELECT data.OS, type_ID, '" & $upgradeType & "', " & $upgradeType & @CRLF _
		& '	FROM ' & $TABLE_DATA_USER & ' data' & @CRLF _
		& '	WHERE data.OS = ' & $TABLE_LOOKUP_UPGRADES & '.OS' & @CRLF _
		& "		AND upgrade_type = '" & $upgradeType & "'" & @CRLF _
		& "		AND data.rarity = 'Gold'" & @CRLF _
		& '		AND data.type_ID = weapon' & @CRLF _
		& "		AND data.modstruct LIKE ('%' || hexa || '%')" & @CRLF _
		& '		AND data.' & $upgradeType & ' <> effect' & @CRLF _
		& ');'
	SQLExecute($query)
EndFunc
#EndRegion Database
