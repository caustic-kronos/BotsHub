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

Global $sqlite_db

#Region Tables
; Those tables are built automatically and one is completed by the user
Global Const $TABLE_DATA_RAW = 'DATA_RAW'
Global Const $SCHEMA_DATA_RAW = ['batch', 'bag', 'slot', 'model_ID', 'type_ID', 'min_stat', 'max_stat', 'requirement', 'attribute_ID', 'name_string', 'OS', 'modstruct', 'quantity', 'value', 'rarity_ID', 'dye_color', 'ID']
							;address ? interaction ? model_file_id ? name enc ? desc enc ? several modstruct (4, 8 ?) - identifier, arg1, arg2

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


#Region Loot Options Flags
; Those options are not renamed because they will be present inside cache once created
Global $PICKUP_NOTHING = False
Global $PICKUP_WEAPONS = True
Global $PICKUP_EVERYTHING = False
Global $IDENTIFY_ITEMS = True
Global $SALVAGE_ANY_ITEM = False
Global $SALVAGE_NOTHING = True
Global $SALVAGE_WEAPONS = False
Global $SALVAGE_GEARS = False
Global $SALVAGE_ALL_TROPHIES = False
Global $SALVAGE_TROPHIES = False
Global $SALVAGE_MATERIALS = False
Global $SELL_NOTHING = False
Global $SELL_WEAPONS = True
Global $SELL_BASIC_MATERIALS = False
Global $SELL_RARE_MATERIALS = False
Global $STORE_WEAPONS = True
#EndRegion Loot Options Flags


;~ Main method from storage bot, does all the things : identify, deal with data, store, salvage
Func ManageInventory()
	;SellItemsToMerchant(DefaultShouldSellItem, True)
	InventoryManagementBeforeRun()
	Return $PAUSE
EndFunc


;~ Function to deal with inventory before farm run
Func InventoryManagementBeforeRun($tradeTown = $ID_EYE_OF_THE_NORTH)
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
	If GUICtrlRead($GUI_Checkbox_StoreUnidentifiedGoldItems) == $GUI_CHECKED Then
		TravelToOutpost($tradeTown, $district_name)
		StoreItemsInXunlaiStorage(IsUnidentifiedGoldItem)
	EndIf
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	If $inventory_management_cache['@identify.something'] And HasUnidentifiedItems() Then
		TravelToOutpost($tradeTown, $district_name)
		IdentifyItems()
	EndIf
	If GUICtrlRead($GUI_Checkbox_CollectData) == $GUI_CHECKED Then
		ConnectToDatabase()
		InitializeDatabase()
		CompleteModelLookupTable()
		CompleteUpgradeLookupTable()
		StoreAllItemsData()
		DisconnectFromDatabase()
	EndIf
	If $inventory_management_cache['@salvage.something'] Then
		TravelToOutpost($tradeTown, $district_name)
		SalvageItems()
		If $bags_count == 5 And MoveItemsOutOfEquipmentBag() > 0 Then SalvageItems()
		;SalvageInscriptions()
		;UpgradeWithSalvageInscriptions()
		;SalvageMaterials()
	EndIf
	If $inventory_management_cache['@sell.materials.something'] And HasMaterials() Then
		TravelToOutpost($tradeTown, $district_name)
		; If we have more than 60k, we risk running into the situation we can't sell because we're too rich, so we store some in xunlai
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		If $inventory_management_cache['@sell.materials.basic.something'] And HasBasicMaterials() Then SellBasicMaterialsToMerchant()
		If $inventory_management_cache['@sell.materials.rare.something'] And HasRareMaterials() Then SellRareMaterialsToMerchant()
	EndIf
	If $inventory_management_cache['@sell.something'] Then
		TravelToOutpost($tradeTown, $district_name)
		; If we have more than 60k, we risk running into the situation we can't sell because we're too rich, so we store some in xunlai
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		SellItemsToMerchant()
	EndIf
	; Max gold in Xunlai chest is 1000 platinums
	If GUICtrlRead($GUI_CheckBox_StoreGold) == $GUI_CHECKED AND GetGoldCharacter() > 60000 And GetGoldStorage() <= (1000000 - 60000) Then
		DepositGold(60000)
		Info('Deposited Gold')
	EndIf
	If GUICtrlRead($GUI_CheckBox_StoreGold) == $GUI_UNCHECKED Then
		Info('Balancing character''s gold level')
		BalanceCharacterGold(10000)
	EndIf
	If GUICtrlRead($GUI_Checkbox_BuyEctoplasm) == $GUI_CHECKED And GetGoldCharacter() > 10000 Then BuyRareMaterialFromMerchantUntilPoor($ID_GLOB_OF_ECTOPLASM, 10000, $ID_OBSIDIAN_SHARD)
	If GUICtrlRead($GUI_Checkbox_BuyObsidian) == $GUI_CHECKED And GetGoldCharacter() > 10000 Then BuyRareMaterialFromMerchantUntilPoor($ID_OBSIDIAN_SHARD, 10000, $ID_GLOB_OF_ECTOPLASM)
	If GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED Then StoreItemsInXunlaiStorage()
EndFunc


;~ Function to deal with inventory during farm to preserve inventory space
Func InventoryManagementMidRun()
	If GUICtrlRead($GUI_Checkbox_FarmMaterialsMidRun) <> $GUI_CHECKED Then Return False
	; Operations order :
	; 1-Check if we have at least 1 identification kit and 1 salvage kit
	; 2-If not, buy until we have 4 identification kits and 12 salvaged kits
	; 3-Sort items
	; 4-Identify items
	; 5-Salvage
	If GetInventoryKitCount($superiorIdentificationKits) < 1 Or GetInventoryKitCount($salvageKits) < 1 Then
		Info('Buying kits for passive inventory management')
		TravelToOutpost($tradeTown, $district_name)
		; Since we are in trade town, might as well clear inventory
		InventoryManagementBeforeRun()
		BuyKitsForMidRun()
		Return True
	EndIf
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	IdentifyItems(False)
	If $inventory_management_cache['@salvage.something'] Then
		SalvageItems(False)
		If $bags_count == 5 And MoveItemsOutOfEquipmentBag() > 0 Then SalvageItems()
	EndIf
	Return False
EndFunc


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
	Local $InsertQuery, $item
	Local $batchID = GetPreviousBatchID() + 1

	Info('Scanning and storing all items data')
	SQLExecute('BEGIN;')
	$InsertQuery = 'INSERT INTO ' & $TABLE_DATA_RAW & ' VALUES' & @CRLF
	For $bagIndex = 1 To $bags_count
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			GetItemReq($item)
			$InsertQuery &= '	('
			$InsertQuery &= $batchID & ', '
			$InsertQuery &= $bagIndex & ', '
			$InsertQuery &= $i & ', '
			$InsertQuery &= DllStructGetData($item, 'modelID') & ', '
			$InsertQuery &= DllStructGetData($item, 'type') & ', '
			$InsertQuery &= 'NULL, '
			$InsertQuery &= (IsWeapon($item) ? GetItemMaxDmg($item) : 'NULL') & ', '
			$InsertQuery &= (IsWeapon($item) ? GetItemReq($item) : 'NULL') & ', '
			$InsertQuery &= (IsWeapon($item) ? GetItemAttribute($item) : 'NULL') & ", '"
			$InsertQuery &= DllStructGetData($item, 'nameString') & "', '"
			$InsertQuery &= (IsInscribable($item) ? 0 : 1) & "', '"
			$InsertQuery &= GetModStruct($item) & "', "
			$InsertQuery &= DllStructGetData($item, 'quantity') & ', '
			$InsertQuery &= GetOrDefault(DllStructGetData($item, 'value'), 0) & ', '
			$InsertQuery &= GetRarity($item) & ', '
			$InsertQuery &= DllStructGetData($item, 'DyeColor') & ', '
			$InsertQuery &= DllStructGetData($item, 'ID')
			$InsertQuery &= '),' & @CRLF
			Sleep(20)
		Next
	Next

	$InsertQuery = StringLeft($InsertQuery, StringLen($InsertQuery) - 3) & @CRLF & ';'
	SQLExecute($InsertQuery)
	SQLExecute('COMMIT;')

	AddToFilledData($batchID)
	CompleteItemsMods($batchID)
EndFunc


;~ Insert data into the RAW data table
Func AddToFilledData($batchID)
	Local $InsertQuery = 'WITH raw AS (' & @CRLF _
		& '	SELECT batch, bag, slot, value, requirement, rarity_ID, type_ID, attribute_ID, model_ID, type_ID, model_ID, name_string, OS, modstruct, dye_color, ID FROM ' & $TABLE_DATA_RAW & ' WHERE batch = ' & $batchID & @CRLF _
		& ')' & @CRLF _
		& 'INSERT INTO ' & $TABLE_DATA_USER & @CRLF _
		& 'SELECT raw.batch, raw.bag, raw.slot, rarities.rarity, types.type, requirement, attributes.attribute, raw.value, names.model_name, raw.OS, NULL, NULL, NULL, raw.type_ID, raw.model_ID, raw.name_string, raw.modstruct, raw.dye_color, raw.ID' & @CRLF _
		& 'FROM raw' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_RARITY & ' rarities ON raw.rarity_ID = rarities.rarity_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_TYPE & ' types ON raw.type_ID = types.type_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_ATTRIBUTE & ' attributes ON raw.attribute_ID = attributes.attribute_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_MODEL & ' names ON raw.type_ID = names.type_ID AND raw.model_ID = names.model_ID;'
	SQLExecute($InsertQuery)
EndFunc


;~ Auto fill the items mods based on the known modstructs
Func CompleteItemsMods($batchID)
	Info('Completing items mods')
	Local $upgradeTypes[3] = ['prefix', 'suffix', 'inscription']
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
		& 'SELECT DISTINCT type_id, model_id, name, OS' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE name IS NOT NULL' & @CRLF _
		& '	AND (type_ID, model_ID) NOT IN (SELECT type_ID, model_ID FROM ' & $TABLE_LOOKUP_MODEL & ');'
	SQLExecute($query)
EndFunc


;~ Complete mods data by cross-comparing all modstructs from items that have the same mods and deduce the mod hexa from it
Func CompleteUpgradeLookupTable()
	Info('Completing upgrade lookup')
	Local $modTypes[3] = ['prefix', 'suffix', 'inscription']
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

	Local $OSWeaponUpgradeTypes = MapKeys($mapItemStruct)
	For $OSWeaponUpgradeType In $OSWeaponUpgradeTypes
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


#Region Inventory
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


;~ Sell general items to trader
Func SellItemsToMerchant($shouldSellItem = DefaultShouldSellItem, $dryRun = False, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to merchant to sell items')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $NPCCoordinates = NPCCoordinatesInTown($tradeTown, 'Merchant')
	MoveTo($NPCCoordinates[0], $NPCCoordinates[1])
	Local $merchant = GetNearestNPCToCoords($NPCCoordinates[0], $NPCCoordinates[1])
	GoToNPC($merchant)
	RandomSleep(500)

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
						RandomSleep(GetPing() + 200)
					EndIf
				Else
					If $dryRun Then Info('Will not sell item at ' & $bagIndex & ':' & $i)
				EndIf
			EndIf
		Next
	Next
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


;~ Sell basic materials to materials merchant in town
Func SellBasicMaterialsToMerchant($shouldSellMaterial = DefaultShouldSellBasicMaterial, $tradeTown = $ID_EYE_OF_THE_NORTH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $NPCCoordinates = NPCCoordinatesInTown($tradeTown, 'Basic material trader')
	MoveTo($NPCCoordinates[0], $NPCCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($NPCCoordinates[0], $NPCCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(500)

	Local $item, $itemID
	For $bagIndex = 1 To _Min(4, $bags_count)
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $shouldSellMaterial($item) Then
				$itemID = DllStructGetData($item, 'ID')
				Local $totalAmount = DllStructGetData($item, 'Quantity')
				Debug('Selling ' & $totalAmount & ' material ' & $bagIndex & '-' & $i)
				While $totalAmount > 9
					TraderRequestSell($itemID)
					Sleep(GetPing() + 200)
					TraderSell()
					Sleep(GetPing() + 200)
					$totalAmount -= 10
					; Safety net incase some sell orders didn't go through
					If ($totalAmount < 10) Then
						$item = GetItemBySlot($bagIndex, $i)
						$totalAmount = DllStructGetData($item, 'Quantity')
					EndIf
				WEnd
			EndIf
		Next
	Next
EndFunc


;~ Sell rare materials to rare materials merchant in town
Func SellRareMaterialsToMerchant($shouldSellMaterial = DefaultShouldSellRareMaterial, $tradeTown = $ID_EMBARK_BEACH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to rare materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $NPCCoordinates = NPCCoordinatesInTown($tradeTown, 'Rare material trader')
	MoveTo($NPCCoordinates[0], $NPCCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($NPCCoordinates[0], $NPCCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	Local $item, $itemID
	For $bagIndex = 1 To _Min(4, $bags_count)
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If $shouldSellMaterial($item) Then
				$itemID = DllStructGetData($item, 'ID')
				Local $totalAmount = DllStructGetData($item, 'Quantity')
				Debug('Selling ' & $totalAmount & ' material ' & $bagIndex & '-' & $i)
				While $totalAmount > 0
					TraderRequestSell($itemID)
					Sleep(GetPing() + 200)
					TraderSell()
					Sleep(GetPing() + 200)
					$totalAmount -= 1
					; Safety net incase some sell orders didn't go through
					If ($totalAmount < 1) Then
						$item = GetItemBySlot($bagIndex, $i)
						$totalAmount = DllStructGetData($item, 'Quantity')
					EndIf
				WEnd
			EndIf
		Next
	Next
EndFunc


;~ Buy rare material from rare materials merchant in town
Func BuyRareMaterialFromMerchant($materialModelID, $amount, $tradeTown = $ID_EMBARK_BEACH)
	TravelToOutpost($tradeTown, $district_name)
	Info('Moving to rare materials merchant')
	UseCitySpeedBoost()
	; in Embark Beach, move to spot to avoid getting stuck on obstacles
	If $tradeTown == $ID_EMBARK_BEACH Then MoveTo(1950, 0)
	Local $NPCCoordinates = NPCCoordinatesInTown($tradeTown, 'Rare material trader')
	MoveTo($NPCCoordinates[0], $NPCCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($NPCCoordinates[0], $NPCCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	For $i = 1 To $amount
		TraderRequest($materialModelID)
		Sleep(GetPing() + 200)
		Local $traderPrice = GetTraderCostValue()
		Debug('Buying for ' & $traderPrice)
		TraderBuy()
		Sleep(GetPing() + 200)
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
	Local $NPCCoordinates = NPCCoordinatesInTown($tradeTown, 'Rare material trader')
	MoveTo($NPCCoordinates[0], $NPCCoordinates[1])
	Local $materialTrader = GetNearestNPCToCoords($NPCCoordinates[0], $NPCCoordinates[1])
	GoToNPC($materialTrader)
	RandomSleep(250)

	Local $IDMaterialToBuy = $materialModelID
	TraderRequest($IDMaterialToBuy)
	Sleep(GetPing() + 200)
	Local $traderPrice = GetTraderCostValue()
	If $traderPrice <= 0 Then
		Error('Couldn''t get trader price for the original material')
		If ($backupMaterialModelID <> Null) Then
			TraderRequest($backupMaterialModelID)
			Sleep(GetPing() + 200)
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
		Sleep(GetPing() + 200)
		TraderRequest($IDMaterialToBuy)
		Sleep(GetPing() + 200)
		$traderPrice = GetTraderCostValue()
		$amount -= 1
	WEnd
EndFunc


;~ Tests if an item is an identified gold item
Func IsIdentifiedGoldItem($item)
	Return GetIsIdentified($item) And (GetRarity($item) == $RARITY_GOLD)
EndFunc


;~ Tests if an item is an identified blue item
Func IsIdentifiedBlueItem($item)
	Return GetIsIdentified($item) And (GetRarity($item) == $RARITY_BLUE)
EndFunc


;~ Tests if an item is an identified purple item
Func IsIdentifiedPurpleItem($item)
	Return GetIsIdentified($item) And (GetRarity($item) == $RARITY_PURPLE)
EndFunc


;~ Tests if an item is an unidentified gold item
Func IsUnidentifiedGoldItem($item)
	Return Not GetIsIdentified($item) And (GetRarity($item) == $RARITY_GOLD)
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
		RandomSleep(GetPing() + 20)
		$materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $newCountMaterial = DllStructGetData($materialInStorage, 'Equipped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		If $newCountMaterial - $countMaterial == $amount Then Return True
		$amount = DllStructGetData($item, 'Quantity')
	EndIf
	If (IsStackable($item) Or IsMaterial($item)) And $amount < 250 Then
		$existingStacks = FindAllInXunlaiStorage($item)
		For $bagIndex = 0 To UBound($existingStacks) - 1 Step 2
			Local $existingStack = GetItemBySlot($existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
			Local $existingAmount = DllStructGetData($existingStack, 'Quantity')
			If $existingAmount < 250 Then
				Debug('To ' & $existingStacks[$bagIndex] & ':' & $existingStacks[$bagIndex + 1])
				MoveItem($item, $existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
				RandomSleep(GetPing() + 20)
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
	RandomSleep(GetPing() + 20)
	Return True
EndFunc


;~ Return True if the item should be stored in Xunlai Storage
Func DefaultShouldStoreItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	Local $quantity = DllStructGetData($item, 'Quantity')
	; Only store full stacks of consumables and materials
	If IsConsumable($itemID) Then
		Return $quantity == 250 And $inventory_management_cache['Store items.Consumables']
	ElseIf IsBasicMaterial($item) Then
		Local $materialName = $BASIC_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $quantity == 250 And $inventory_management_cache['Store items.Basic Materials.' & $materialName]
	ElseIf IsRareMaterial($item) Then
		Local $materialName = $RARE_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return $inventory_management_cache['Store items.Rare Materials.' & $materialName]
	ElseIf ($itemID == $ID_IDENTIFICATION_KIT Or $itemID == $ID_SUPERIOR_IDENTIFICATION_KIT) Then
		Return False
	ElseIf ($itemID == $ID_SALVAGE_KIT Or $itemID == $ID_SALVAGE_KIT_2 Or $itemID == $ID_EXPERT_SALVAGE_KIT Or $itemID == $ID_SUPERIOR_SALVAGE_KIT) Then
		Return False
	ElseIf IsRegularTome($itemID) Then
		Local $tomeName = $REGULAR_TOME_NAMES_FROM_IDS[$itemID]
		Return $inventory_management_cache['Store items.Tomes.Normal.' & $tomeName]
	ElseIf IsEliteTome($itemID) Then
		Local $tomeName = $ELITE_TOME_NAMES_FROM_IDS[$itemID]
		Return $inventory_management_cache['Store items.Tomes.Elite.' & $tomeName]
	ElseIf IsGoldScroll($itemID) Then
		Local $scrollName = $GOLD_SCROLL_NAMES_FROM_IDS[$itemID]
		Return $inventory_management_cache['Store items.Scrolls.Gold.' & $scrollName]
	ElseIf IsBlueScroll($itemID) Then
		Return $inventory_management_cache['Store items.Scrolls.Blue']
	ElseIf IsKey($itemID) Then
		Return $inventory_management_cache['Store items.Keys']
	ElseIf ($itemID == $ID_DYES) Then
		Local $dyeColorID = DllStructGetData($item, 'DyeColor')
		Local $dyeColorName = $DYE_NAMES_FROM_IDS[$dyeColorID]
		Return $inventory_management_cache['Store items.Dyes.' & $dyeColorName]
	ElseIf ($itemID == $ID_MINISTERIAL_COMMENDATION) Then
		Return True
	ElseIf ($itemID == $ID_LOCKPICK) Then
		Return False
	ElseIf IsWeapon($item) Then
		Return CheckStoreWeapon($item)		;ShouldKeepWeapon($item)
	ElseIf isArmorSalvageItem($item) Then
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		Return $inventory_management_cache['Store items.Armor salvageables.' & $rarityName]		;ContainsValuableUpgrades($item)
	; Storing trophies only when we have a full stack of 250
	ElseIf (IsTrophy($itemID) And $quantity == 250) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Return True if the item should be sold to the merchant
Func DefaultShouldSellItem($item)
	If $inventory_management_cache['@sell.nothing'] Then Return False

	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	If $rarity == $RARITY_GREEN Then Return False
	If IsKey($itemID) Then
		Return $inventory_management_cache['Sell items.Keys']
	ElseIf IsBlueScroll($itemID) Then
		Return $inventory_management_cache['Sell items.Scrolls.Blue']
	ElseIf IsGoldScroll($itemID) Then
		Local $scrollName = $GOLD_SCROLL_NAMES_FROM_IDS[$itemID]
		Return $inventory_management_cache['Sell items.Scrolls.Gold.' & $scrollName]
	ElseIf isArmorSalvageItem($item) Then
		If $inventory_management_cache['@sell.salvageables.nothing'] Then Return False
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		If Not $inventory_management_cache['Sell items.Armor salvageables.' & $rarityName] Then Return False
		Return GetIsIdentified($item) And Not ContainsValuableUpgrades($item)
	ElseIf IsWeapon($item) And CheckSellWeapon($item) Then
		Return Not ShouldKeepWeapon($item)
	EndIf
	Return False
EndFunc


;~ Return True if the item should be salvaged
Func DefaultShouldSalvageItem($item)
	If $inventory_management_cache['@salvage.nothing'] Then Return False

	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $rarity = GetRarity($item)

	If $rarity == $RARITY_GREEN Then Return False
	If IsTrophy($itemID) Then
		If $inventory_management_cache['Salvage items.Trophies'] Then Return True
		If $inventory_management_cache['@salvage.trophies.nothing'] Then Return False
		If $itemID == $ID_GLACIAL_STONE Then Return $inventory_management_cache['Salvage items.Trophies.Glacial Stone']
		If $itemID == $ID_DESTROYER_CORE Then Return $inventory_management_cache['Salvage items.Trophies.Destroyer Core']
		If $itemID == $ID_STOLEN_GOODS Then Return $inventory_management_cache['Salvage items.Trophies.Stolen Goods']
		;Return $inventory_management_cache['Salvage items.Trophies.Other trophies']

		If $MAP_FEATHER_TROPHIES[$itemID] <> Null Then Return True
		If $MAP_DUST_TROPHIES[$itemID] <> Null Then Return True
		If $MAP_BONES_TROPHIES[$itemID] <> Null Then Return True
		If $MAP_FIBER_TROPHIES[$itemID] <> Null Then Return True
		Return False
	ElseIf IsRareMaterial($item) Then
		Local $materialName = $RARE_MATERIAL_NAMES_FROM_IDS[$itemID]
		Return IsLootOptionChecked('Salvage items.Rare Materials.' & $materialName)
	ElseIf IsArmorSalvageItem($item) Then
		If $inventory_management_cache['@salvage.salvageables.nothing'] Then Return False
		Local $rarityName = $RARITY_NAMES_FROM_IDS[$rarity]
		If Not $inventory_management_cache['Salvage items.Armor salvageables.' & $rarityName] Then Return False
		Return GetIsIdentified($item) And Not ContainsValuableUpgrades($item)
	ElseIf IsWeapon($item) Then
		If Not DllStructGetData($item, 'IsMaterialSalvageable') Then Return False
		If $inventory_management_cache['@salvage.weapons.nothing'] Then Return False
		If Not CheckSalvageWeapon($item) Then Return False
		Return Not ShouldKeepWeapon($item)
	EndIf
	Return False
EndFunc


;~ Return True if weapon item should not be sold or salvaged
Func ShouldKeepWeapon($item)
	Local Static $lowReqValuableWeaponTypes = [$ID_TYPE_SHIELD, $ID_TYPE_DAGGER, $ID_TYPE_SCYTHE, $ID_TYPE_SPEAR]
	Local Static $lowReqValuableWeaponTypesMap = MapFromArray($lowReqValuableWeaponTypes)
	Local Static $valuableOSWeaponTypes = [$ID_TYPE_SHIELD, $ID_TYPE_OFFHAND, $ID_TYPE_WAND, $ID_TYPE_STAFF]
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
	If Not GetIsIdentified($item) Then Return True
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
	; OS - Old School weapon without inscription ... it's more complicated
	Else
		If GetItemReq($item) >= 9 Then
			; OS (Old School) high Req are kept only if : 1) perfect mods and good type or good skin 2) rare skin and almost perfect mods
			If HasPerfectMods($item) And ($MAP_RARE_WEAPONS[$itemID] <> Null Or $valuableOSWeaponTypesMap[DllStructGetData($item, 'type')] <> Null) Then Return True
			If $MAP_RARE_WEAPONS[$itemID] == Null Then Return False
			If HasAlmostPerfectMods($item) Then Return True
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


;~ Returns true if an item has a 'Salvageable' inscription
Func HasSalvageInscription($item)
	Local $salvageableInscription[] = ['1F0208243E0432251', '0008260711A8A7000000C', '0008261323A8A7000000C', '00082600011826900098260F1CA8A7000000C']
	Local $modstruct = GetModStruct($item)
	For $salvageableModStruct in $salvageableInscription
		If StringInStr($modstruct, $salvageableModStruct) Then Return True
	Next
	Return False
EndFunc


Func CheckPickupWeapon($weaponItem)
	If Not $PICKUP_WEAPONS Then Return False

	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GREEN Or $weaponRarity == $RARITY_RED Then Return True
	If $weaponRarity == $RARITY_GRAY Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Pick up items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc


Func CheckSalvageWeapon($weaponItem)
	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GREEN Or $weaponRarity == $RARITY_GRAY Or $weaponRarity == $RARITY_RED Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Salvage items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc


Func CheckSellWeapon($weaponItem)
	If Not $SELL_WEAPONS Then Return False

	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GREEN Or $weaponRarity == $RARITY_GRAY Or $weaponRarity == $RARITY_RED Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Sell items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc


Func CheckStoreWeapon($weaponItem)
	If Not $STORE_WEAPONS Then Return False

	Local $weaponType = DllStructGetData($weaponItem, 'Type')
	Local $weaponTypeName = $WEAPON_NAMES_FROM_TYPES[$weaponType]
	Local $weaponRarity = GetRarity($weaponItem)
	If $weaponRarity == $RARITY_GREEN Then Return True
	If $weaponRarity == $RARITY_GRAY Or $weaponRarity == $RARITY_RED Then Return False
	Local $weaponRarityName = $RARITY_NAMES_FROM_IDS[$weaponRarity]
	Local $weaponReq = GetItemReq($weaponItem)
	Return $inventory_management_cache['Store items.Weapons and offhands.' & $weaponRarityName & '.' & $weaponTypeName & '.Req ' & $weaponReq]
EndFunc
#EndRegion Inventory