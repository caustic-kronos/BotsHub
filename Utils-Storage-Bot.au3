#include-once

#include <SQLite.au3>
#include <SQLite.dll.au3>

#include 'GWA2.au3'
#include 'GWA2_Headers.au3'
#include 'GWA2_ID.au3'
#include 'Utils.au3'

Opt('MustDeclareVars', 1)


Local $SQLITE_DB

#Region Guild Hall Globals
Local $WarriorsIsle = False
Local $HuntersIsle = False
Local $WizardsIsle = False
Local $BurningIsle = False
Local $FrozenIsle = False
Local $NomadsIsle = False
Local $DruidsIsle = False
Local $IsleOfTheDead = False
Local $IsleOfWeepingStone = False
Local $IsleOfJade = False
Local $ImperialIsle = False
Local $IsleOfMeditation = False
Local $UnchartedIsle = False
Local $IsleOfWurms = False
Local $CorruptedIsle = False
Local $IsleOfSolitude = False
#EndRegion Guild Hall Globals


#Region Tables
; Those tables are built automatically and one is completed by the user
Local $TABLE_DATA_RAW = 'DATA_RAW'
Local $SCHEMA_DATA_RAW = ['batch', 'bag', 'slot', 'model_ID', 'type_ID', 'min_stat', 'max_stat', 'requirement', 'attribute_ID', 'name_string', 'modstruct', 'quantity', 'value', 'rarity_ID', 'extra_ID', 'ID']
							;address ? interaction ? model_file_id ? name enc ? desc enc ? several modstruct (4, 8 ?) - identifier, arg1, arg2

Local $TABLE_DATA_USER = 'DATA_USER'
Local $SCHEMA_DATA_USER = ['batch', 'bag', 'slot', 'rarity', 'type', 'requirement', 'attribute', 'value', 'name', 'OS', 'prefix', 'suffix', 'inscription', 'type_ID', 'model_ID', 'name_string', 'modstruct', 'extra_ID', 'ID']

Local $TABLE_DATA_SALVAGE = 'DATA_SALVAGE'
Local $SCHEMA_DATA_SALVAGE = ['batch', 'model_ID', 'material', 'amount']

; Those 3 lookups are filled directly when database is created
Local $TABLE_LOOKUP_ATTRIBUTE = 'LOOKUP_ATTRIBUTE'
Local $SCHEMA_LOOKUP_ATTRIBUTE = ['attribute_ID', 'attribute']

Local $TABLE_LOOKUP_RARITY = 'LOOKUP_RARITY'
Local $SCHEMA_LOOKUP_RARITY = ['rarity_ID', 'rarity']

Local $TABLE_LOOKUP_TYPE = 'LOOKUP_TYPE'
Local $SCHEMA_LOOKUP_TYPE = ['type_ID', 'type']

; Those lookups are built from the data table filled by the user
Local $TABLE_LOOKUP_MODEL = 'LOOKUP_MODEL'
Local $SCHEMA_LOOKUP_MODEL = ['model_ID', 'model_name', 'OS']

Local $TABLE_LOOKUP_UPGRADES = 'LOOKUP_UPGRADES'
Local $SCHEMA_LOOKUP_UPGRADES = ['OS', 'upgrade_type', 'weapon', 'effect', 'hexa', 'name', 'propagate']
#EndRegion Tables

;~ Main method from storage bot, does all the things : identify, deal with data, store, salvage
Func ManageInventory($STATUS)
	;Out('Travel to Guild Hall')
	;TravelGH()
	;WaitMapLoading()
	;Out('Checking Guild Hall')
	;CheckGuildHall()

	PostFarmActions()

	;StoreEverythingInXunlaiStorage()
	Return 2
EndFunc


#Region Reading items data
;~ Read data from item at bagIndex and slot and print it in the console
Func ReadOneItemData($bagIndex, $slot)
	Out('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $output = GetOneItemData($bagIndex, $slot)
	If $output == '' Then Return
	Out($output)
EndFunc


;~ Read data from all items in inventory and print it in the console
Func ReadAllItemsData()
	Out('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $item, $output
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $slot = 1 To DllStructGetData($bag, 'slots')
			$output = GetOneItemData($bagIndex, $slot)
			If $output == '' Then ContinueLoop
			Out($output)
			RndSleep(50)
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
	$SQLITE_DB = _SQLite_Open('data/items_database.db3')
EndFunc


;# Disconnect from the database
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

	Local $columnsTypeIsNumber[] = [true, false]
	If TableIsEmpty($TABLE_LOOKUP_TYPE) Then FillTable($TABLE_LOOKUP_TYPE, $columnsTypeIsNumber, $Item_Types_Double_Array)
	If TableIsEmpty($TABLE_LOOKUP_ATTRIBUTE) Then FillTable($TABLE_LOOKUP_ATTRIBUTE, $columnsTypeIsNumber, $Attributes_Double_Array)
	If TableIsEmpty($TABLE_LOOKUP_RARITY) Then FillTable($TABLE_LOOKUP_RARITY, $columnsTypeIsNumber, $Rarities_Double_Array)
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
		For $j = 0 To Ubound($values,2) - 1
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
	;Out($query)
	Local $return = _SQLite_Query($SQLITE_DB, $query, $queryResult)
	If $return <> 0 Then Out('Query failed ! Failure on : ' & @CRLF & $query, $GUI_CONSOLE_RED_COLOR)
EndFunc


;~ Execute a request on the database
Func SQLExecute($query)
	;Out($query)
	Local $return = _SQLite_Exec($SQLITE_DB, $query)
	If $return <> 0 Then Out('Query failed ! Failure on : ' & @CRLF & $query, $GUI_CONSOLE_RED_COLOR)
EndFunc


#EndRegion Database Utils


;~ Store in database all data that can be found in items in inventory
Func StoreAllItemsData()
	Local $InsertQuery, $item
	Local $batchID = GetPreviousBatchID() + 1

	Out('Scanning and storing all items data')
	SQLExecute('BEGIN;')
	$InsertQuery = 'INSERT INTO ' & $TABLE_DATA_RAW & ' VALUES' & @CRLF
	For $bagIndex = 1 To 5
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
			$InsertQuery &= GetModStruct($item) & "', "
			$InsertQuery &= DllStructGetData($item, 'quantity') & ', '
			$InsertQuery &= GetOrDefault(DllStructGetData($item, 'value'), 0) & ', '
			$InsertQuery &= GetRarity($item) & ', '
			$InsertQuery &= DllStructGetData($item, 'ExtraID') & ', '
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


Local $SCHEMA_DATA_USER = ['batch', 'bag', 'slot', 'rarity', 'type', 'requirement', 'attribute', 'value', 'name', 'OS', 'prefix', 'suffix', 'inscription']

Func AddToFilledData($batchID)
	Local $InsertQuery = 'WITH raw AS (' & @CRLF _
		& '	SELECT batch, bag, slot, value, requirement, rarity_ID, type_ID, attribute_ID, model_ID, type_ID, model_ID, name_string, modstruct, extra_ID, ID FROM ' & $TABLE_DATA_RAW & ' WHERE batch = ' & $batchID & @CRLF _
		& ')' & @CRLF _
		& 'INSERT INTO ' & $TABLE_DATA_USER & @CRLF _
		& 'SELECT raw.batch, raw.bag, raw.slot, rarities.rarity, types.type, requirement, attributes.attribute, raw.value, names.model_name, names.OS, NULL, NULL, NULL, raw.type_ID, raw.model_ID, raw.name_string, raw.modstruct, raw.extra_ID, raw.ID' & @CRLF _
		& 'FROM raw' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_RARITY & ' rarities ON raw.rarity_ID = rarities.rarity_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_TYPE & ' types ON raw.type_ID = types.type_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_ATTRIBUTE & ' attributes ON raw.attribute_ID = attributes.attribute_ID' & @CRLF _
		& 'LEFT JOIN ' & $TABLE_LOOKUP_MODEL & ' names ON raw.model_ID = names.model_ID;'
	SQLExecute($InsertQuery)
EndFunc


;~ Auto fill the items mods based on the known modstructs
Func CompleteItemsMods($batchID)
	Out('Completing items mods')
	Local $upgradeTypes[3] = ['prefix', 'suffix', 'inscription']
	Local $query
	For $upgradeType In $upgradeTypes
		$query = 'UPDATE ' & $TABLE_DATA_USER & @CRLF _
			& 'SET ' & $upgradeType & ' = (' & @CRLF _
			& '	SELECT upgrades.effect' & @CRLF _
			& '	FROM ' & $TABLE_LOOKUP_UPGRADES & ' upgrades' & @CRLF _
			& '	WHERE upgrades.propagate = 1' & @CRLF _									
			& '		AND upgrades.OS = ' & $TABLE_DATA_USER & '.OS' & @CRLF _							
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
			& '			AND upgrades.OS = ' & $TABLE_DATA_USER & '.OS' & @CRLF _
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
	Out('Completing model lookup ')
	$query = 'INSERT INTO ' & $TABLE_LOOKUP_MODEL & @CRLF _
		& 'SELECT DISTINCT model_id, name, OS' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE name IS NOT NULL' & @CRLF _
		& '	AND model_ID NOT IN (SELECT model_ID FROM ' & $TABLE_LOOKUP_MODEL & ');'
	SQLExecute($query)
EndFunc


;~ Complete mods data by cross-comparing all modstructs from items that have the same mods and deduce the mod hexa from it
Func CompleteUpgradeLookupTable()
	Out('Completing upgrade lookup')
	Local $modTypes[3] = ['prefix', 'suffix', 'inscription']
	For $upgradeType In $modTypes
		InsertNewUpgrades($upgradeType)
		UpdateNewUpgrades($upgradeType)
		ValidateNewUpgrades($upgradeType)
	Next
EndFunc


Func InsertNewUpgrades($upgradeType)
	Local $query = 'INSERT INTO ' & $TABLE_LOOKUP_UPGRADES & @CRLF _
		& "SELECT DISTINCT OS, '" & $upgradeType & "', type_ID, " & $upgradeType & ', NULL, NULL, 0' & @CRLF _
		& 'FROM ' & $TABLE_DATA_USER & @CRLF _
		& 'WHERE ' & $upgradeType & ' IS NOT NULL' & @CRLF _
		& "AND (OS, '" & $upgradeType & "', type_ID, " & $upgradeType & ') NOT IN (SELECT OS, upgrade_type, weapon, effect FROM ' & $TABLE_LOOKUP_UPGRADES & ');'
	SQLExecute($query)
EndFunc


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
		& '		AND data.type_ID = weapon' & @CRLF _
		& "		AND data.modstruct LIKE ('%' || hexa || '%')" & @CRLF _
		& '		AND data.' & $upgradeType & ' <> effect' & @CRLF _
		& ');'
	SQLExecute($query)
EndFunc
#EndRegion Database


#Region Inventory
;~ Don't use : for now TraderRequestSell make the game crash
;~ Sell gold scrolls to scroll trader
Func SellGoldScrolls()
	If GetMapID() == $ID_Rata_Sum Then
		Out('Moving to Scroll Trader')
		Local $scrollTrader = GetNearestNPCToCoords(19250, 14275)
		GoToNPC($scrollTrader)
		RndSleep(500)
	EndIf
	
	Local $item, $itemID
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 And IsGoldScroll($itemID) Then
				Out('ok')
				TraderRequestSell($item)
				TraderSell()
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
		Out('No space in inventory to move the items from the equipment bag')
		Return
	EndIf
	
	For $slot = 1 To DllStructGetData($equipmentBag, 'slots')
		If $countEmptySlots <= $cursor Then 
			Out('No space in inventory to move the items from the equipment bag')
			Return
		EndIf
		Local $item = GetItemBySlot(5, $slot)
		Local $itemID = DllStructGetData($item, 'ModelID')
		If $itemID <> 0 Then
			MoveItem($item, $inventoryEmptySlots[2 * $cursor], $inventoryEmptySlots[2 * $cursor + 1])
			$cursor += 1
			RndSleep(50)
		EndIf
	Next
EndFunc
		;SalvageInscriptions()
		;UpgradeWithSalvageInscriptions()
		;SalvageItems()
		;StoreInXunlaiStorage()




;~ Sell general items to trader
Func SellEverythingToMerchant($shouldSellItem = DefaultShouldSellItem)
	If GetMapID() == $ID_Rata_Sum Then
		Out('Moving to Merchant')
		Local $merchant = GetNearestNPCToCoords(19500, 14750)
		GoToNPC($merchant)
		RndSleep(500)
	EndIf
	
	Local $item, $itemID
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 And $shouldSellItem($item) Then
				SellItem($item, DllStructGetData($item, 'Quantity'))
				RndSleep(3000)
			EndIf
		Next
	Next
EndFunc


Func StoreEverythingInXunlaiStorage($shouldStoreItem = DefaultShouldStoreItem)
	Out('Storing items')
	Local $item, $itemID
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			$itemID = DllStructGetData($item, 'ModelID')
			If $itemID <> 0 And $shouldStoreItem($item) Then
				Out('Moving ' & $bagIndex & ';' & $i)
				StoreItemInXunlaiStorage($item)
			EndIf
		Next
	Next
EndFunc


Func StoreItemInXunlaiStorage($item)
	Local $existingStacks
	Local $itemID, $storageSlot, $amount
	$itemID = DllStructGetData($item, 'ModelID')
	$amount = DllStructGetData($item, 'Quantity')
	
	If IsMaterial($item) Then
		Local $materialStorageLocation = $Map_Material_Location[$itemID]
		Local $materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $countMaterial = DllStructGetData($materialInStorage, 'Equiped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		MoveItem($item, 6, $materialStorageLocation)
		RndSleep(50 + GetPing())
		$materialInStorage = GetItemBySlot(6, $materialStorageLocation)
		Local $newCountMaterial = DllStructGetData($materialInStorage, 'Equiped') * 256 + DllStructGetData($materialInStorage, 'Quantity')
		If $newCountMaterial - $countMaterial == $amount Then Return
	EndIf
	If (IsStackableItemButNotMaterial($itemID) Or IsMaterial($item)) And $amount < 250 Then
		$existingStacks = FindAllInXunlaiStorage($itemID)
		For $bagIndex = 0 To Ubound($existingStacks) - 1 Step 2
			Local $existingStack = GetItemBySlot($existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
			Local $existingAmount = DllStructGetData($existingStack, 'Quantity')
			If $existingAmount < 250 Then
				Out('To ' & $existingStacks[$bagIndex] & ';' & $existingStacks[$bagIndex + 1])
				MoveItem($item, $existingStacks[$bagIndex], $existingStacks[$bagIndex + 1])
				RndSleep(50 + GetPing())
				$amount = $amount + $existingAmount - 250
				If $amount < 0 Then Return
			EndIf
		Next
	EndIf
	$storageSlot = FindChestFirstEmptySlot()
	If $storageSlot[0] == 0 Then
		Out('Storage is full')
		Return
	EndIf
	Out('To ' & $storageSlot[0] & ';' & $storageSlot[1])
	MoveItem($item, $storageSlot[0], $storageSlot[1])
	RndSleep(50 + GetPing())
EndFunc



;~ Return True if the item should be stored in Xunlai Storage
Func DefaultShouldStoreItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	If IsConsumable($itemID) Then
		Return True
	ElseIf IsBasicMaterial($item) Then
		Return True
	ElseIf ($itemID == $ID_Identification_Kit Or $itemID == $ID_SUP_Identification_Kit) Then
		Return True
	ElseIf IsRareMaterial($item) Then
		Return True
	ElseIf IsTome($itemID) Then
		Return True
	ElseIf IsGoldScroll($itemID) Then
		Return True
	ElseIf ($itemID == $ID_Dyes) Then
		Return True
	ElseIf ($itemID == $ID_Ministerial_Commendation) Then
		Return True
	ElseIf ($itemID == $ID_Lockpick) Then
		Return False
	ElseIf $rarity <> $RARITY_White And IsLowReqMaxDamage($item) Then
		Return True
	ElseIf ($rarity == $RARITY_Gold) Then
		Return True
	ElseIf ($rarity == $RARITY_Green) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Return True if the item should be sold to the merchant
Func DefaultShouldSellItem($item)
	Local $itemID = DllStructGetData($item, 'ModelID')
	Local $rarity = GetRarity($item)

	If $itemID == $ID_Saurian_bone Then Return True
	If IsBlueScroll($itemID) Then Return True
	If IsWeapon($item) Then
		If Not GetIsIdentified($item) Then Return False
		If $rarity <> $RARITY_White And IsLowReqMaxDamage($item) Then Return False
		If HasSalvageInscription($item) Then Return False
		If ShouldKeepWeapon($itemID) Then Return False
		Return True
	EndIf

	Return False
EndFunc

Func HasSalvageInscription($item)
	Local $salvageableInscription[] = ['1F0208243E0432251', '0008260711A8A7000000C', '0008261323A8A7000000C', '1F0208243E0432251D0008260F16A8A7', '00082600011826900098260F1CA8A7000000C', '1F0208243E0432251D0008260810B8A7000000C']
	Local $modstruct = GetModStruct($item)
	For $salvageableModStruct in $salvageableInscription
		If StringInStr($modstruct, $salvageableModStruct) Then Return True
	Next
	Return False
EndFunc

Func ShouldKeepWeapon($itemID)
	Local $ID_Model_Great_Conch = 2415
	Local $ID_Model_Elemental_Sword = 2267
	Local $shouldKeepWeaponsArray[] = [$ID_Model_Great_Conch, $ID_Model_Elemental_Sword]
	Local $Map_shouldKeepWeapons = MapFromArray($shouldKeepWeaponsArray)
	If $Map_shouldKeepWeapons[$itemID] <> null Then Return True
	Return False
EndFunc
#EndRegion Inventory


#Region Guild Hall
;~ Checks to see which Guild Hall you are in and the spawn point
Func CheckGuildHall()
	Switch GetMapID()
		Case $ID_Warriors_Isle
			$WarriorsIsle = True
		Case $ID_Hunters_Isle
			$HuntersIsle = True
		Case $ID_Wizards_Isle
			$WizardsIsle = True
		Case $ID_Burning_Isle
			$BurningIsle = True
		Case $ID_Frozen_Isle
			$FrozenIsle = True
		Case $ID_Nomads_Isle
			$NomadsIsle = True
		Case $ID_Druids_Isle
			$DruidsIsle = True
		Case $ID_Isle_Of_The_Dead
			$IsleOfTheDead = True
		Case $ID_Isle_Of_Weeping_Stone
			$IsleOfWeepingStone = True
		Case $ID_Isle_Of_Jade
			$IsleOfJade = True
		Case $ID_Imperial_Isle
			$ImperialIsle = True
		Case $ID_Isle_Of_Meditation
			$IsleOfMeditation = True
		Case $ID_Uncharted_Isle
			$UnchartedIsle = True
		Case $ID_Isle_Of_Wurms
			$IsleOfWurms = True
			CheckIsleOfWurms()
		Case $ID_Corrupted_Isle
			$CorruptedIsle = True
			CheckCorruptedIsle()
		Case $ID_Isle_Of_Solitude
			$IsleOfSolitude = True
		Case Else
			Out('Guild Hall not recognised')
	EndSwitch
EndFunc


;~ If there is a missing Guild Hall from the below listing, it is because there is only 1 spawn point in that Guild Hall
Func CheckIsleOfWurms()
	If CheckArea(8682, 2265) Then
		If MoveTo(8263, 2971) Then Return True
		Return False
	ElseIf CheckArea(6697, 3631) Then
		If MoveTo(7086, 2983) And MoveTo(8263, 2971) Then Return True
		Return False
	ElseIf CheckArea(6716, 2929) Then
		If MoveTo(8263, 2971) Then Return True
		Return False
	Else
		Return False
	EndIf
EndFunc


Func CheckCorruptedIsle()
	If CheckArea(-4830, 5985) Then
		If MoveTo(-4830, 5985) Then Return True
		Return False
	ElseIf CheckArea(-3778, 6214) Then
		If MoveTo(-3778, 6214) Then Return True
		Return False
	ElseIf CheckArea(-5209, 4468) Then
		If MoveTo(-4352, 5232) Then Return True
		Return False
	Else
		Return False
	EndIf
EndFunc


;# Go to the chest and talk to it
Func Chest()
	Local $Waypoints_by_XunlaiChest[16][3] = [ _
			[$BurningIsle, -5285, -2545], _
			[$DruidsIsle, -1792, 5444], _
			[$FrozenIsle, -115, 3775], _
			[$HuntersIsle, 4855, 7527], _
			[$IsleOfTheDead, -4562, -1525], _
			[$NomadsIsle, 4630, 4580], _
			[$WarriorsIsle, 4224, 7006], _
			[$WizardsIsle, 4858, 9446], _
			[$ImperialIsle, 2184, 13125], _
			[$IsleOfJade, 8614, 2660], _
			[$IsleOfMeditation, -726, 7630], _
			[$IsleOfWeepingStone, -1573, 7303], _
			[$CorruptedIsle, -4868, 5998], _
			[$IsleOfSolitude, 4478, 3055], _
			[$IsleOfWurms, 8586, 3603], _
			[$UnchartedIsle, 4522, -4451]]
	For $i = 0 To (UBound($Waypoints_by_XunlaiChest) - 1)
		If ($Waypoints_by_XunlaiChest[$i][0] == True) Then
			Do
				GenericRandomPath($Waypoints_by_XunlaiChest[$i][1], $Waypoints_by_XunlaiChest[$i][2], Random(60, 80, 2))
			Until CheckArea($Waypoints_by_XunlaiChest[$i][1], $Waypoints_by_XunlaiChest[$i][2])
		EndIf
	Next
	Local $chestName = 'Xunlai Chest'
	Local $chest = GetAgentByName($chestName)
	If IsDllStruct($chest) Then
		Out('Going to ' & $chestName)
		GoToNPC($chest)
		RndSleep(3500)
	EndIf
EndFunc


;~ Go to the merchant and talk to him
Func GoToMerchant()
	Local $Waypoints_by_Merchant[29][3] = [ _
			[$BurningIsle, -4439, -2088], _
			[$BurningIsle, -4772, -362], _
			[$BurningIsle, -3637, 1088], _
			[$BurningIsle, -2506, 988], _
			[$DruidsIsle, -2037, 2964], _
			[$FrozenIsle, 99, 2660], _
			[$FrozenIsle, 71, 834], _
			[$FrozenIsle, -299, 79], _
			[$HuntersIsle, 5156, 7789], _
			[$HuntersIsle, 4416, 5656], _
			[$IsleOfTheDead, -4066, -1203], _
			[$NomadsIsle, 5129, 4748], _
			[$WarriorsIsle, 4159, 8540], _
			[$WarriorsIsle, 5575, 9054], _
			[$WizardsIsle, 4288, 8263], _
			[$WizardsIsle, 3583, 9040], _
			[$ImperialIsle, 1415, 12448], _
			[$ImperialIsle, 1746, 11516], _
			[$IsleOfJade, 8825, 3384], _
			[$IsleOfJade, 10142, 3116], _
			[$IsleOfMeditation, -331, 8084], _
			[$IsleOfMeditation, -1745, 8681], _
			[$IsleOfMeditation, -2197, 8076], _
			[$IsleOfWeepingStone, -3095, 8535], _
			[$IsleOfWeepingStone, -3988, 7588], _
			[$CorruptedIsle, -4670, 5630], _
			[$IsleOfSolitude, 2970, 1532], _
			[$IsleOfWurms, 8284, 3578], _
			[$UnchartedIsle, 1503, -2830]]
	For $i = 0 To (UBound($Waypoints_by_Merchant) - 1)
		If ($Waypoints_by_Merchant[$i][0] == True) Then
			Do
				GenericRandomPath($Waypoints_by_Merchant[$i][1], $Waypoints_by_Merchant[$i][2], Random(60, 80, 2))
			Until CheckArea($Waypoints_by_Merchant[$i][1], $Waypoints_by_Merchant[$i][2])
		EndIf
	Next

	Out('Going to Merchant')
	Local $me, $guy
	Do
		RndSleep(250)
		$me = GetAgentByID(-2)
		$guy = GetNearestNPCToCoords(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'))
	Until DllStructGetData($guy, 'Id') <> 0
	ChangeTarget($guy)
	RndSleep(250)
	GoNPC($guy)
	RndSleep(250)
	Do
		MoveTo(DllStructGetData($guy, 'X'), DllStructGetData($guy, 'Y'), 40)
		RndSleep(500)
		GoNPC($guy)
		RndSleep(250)
		$me = GetAgentByID(-2)
	Until ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), DllStructGetData($guy, 'X'), DllStructGetData($guy, 'Y')) < 250
	RndSleep(1000)
EndFunc


;# Move randomly towards somewhere
Func GenericRandomPath($aPosX, $aPosY, $aRandom = 50, $STOPSMIN = 1, $STOPSMAX = 5, $NumberOfStops = -1)
	If $NumberOfStops = -1 Then $NumberOfStops = Random($STOPSMIN, $STOPSMAX, 1)
	Local $lAgent = GetAgentByID(-2)
	Local $MyPosX = DllStructGetData($lAgent, 'X')
	Local $MyPosY = DllStructGetData($lAgent, 'Y')
	Local $Distance = ComputeDistance($MyPosX, $MyPosY, $aPosX, $aPosY)
	If $NumberOfStops = 0 Or $Distance < 200 Then
		MoveTo($aPosX, $aPosY, $aRandom)
	Else
		Local $M = Random(0, 1)
		Local $N = $NumberOfStops - $M
		Local $StepX = (($M * $aPosX) + ($N * $MyPosX)) / ($M + $N)
		Local $StepY = (($M * $aPosY) + ($N * $MyPosY)) / ($M + $N)
		MoveTo($StepX, $StepY, $aRandom)
		GenericRandomPath($aPosX, $aPosY, $aRandom, $STOPSMIN, $STOPSMAX, $NumberOfStops - 1)
	EndIf
EndFunc

Func RareMaterialTrader()
	Local $Waypoints_by_RareMatTrader[36][3] = [ _
			[$BurningIsle, -3793, 1069], _
			[$BurningIsle, -2798, -74], _
			[$DruidsIsle, -989, 4493], _
			[$FrozenIsle, 71, 834], _
			[$FrozenIsle, 99, 2660], _
			[$FrozenIsle, -385, 3254], _
			[$FrozenIsle, -983, 3195], _
			[$HuntersIsle, 3267, 6557], _
			[$IsleOfTheDead, -3415, -1658], _
			[$NomadsIsle, 1930, 4129], _
			[$NomadsIsle, 462, 4094], _
			[$WarriorsIsle, 4108, 8404], _
			[$WarriorsIsle, 3403, 6583], _
			[$WarriorsIsle, 3415, 5617], _
			[$WizardsIsle, 3610, 9619], _
			[$ImperialIsle, 759, 11465], _
			[$IsleOfJade, 8919, 3459], _
			[$IsleOfJade, 6789, 2781], _
			[$IsleOfJade, 6566, 2248], _
			[$IsleOfMeditation, -2197, 8076], _
			[$IsleOfMeditation, -1745, 8681], _
			[$IsleOfMeditation, -331, 8084], _
			[$IsleOfMeditation, 422, 8769], _
			[$IsleOfMeditation, 549, 9531], _
			[$IsleOfWeepingStone, -3988, 7588], _
			[$IsleOfWeepingStone, -3095, 8535], _
			[$IsleOfWeepingStone, -2431, 7946], _
			[$IsleOfWeepingStone, -1618, 8797], _
			[$CorruptedIsle, -4424, 5645], _
			[$CorruptedIsle, -4443, 4679], _
			[$IsleOfSolitude, 3172, 3728], _
			[$IsleOfSolitude, 3221, 4789], _
			[$IsleOfSolitude, 3745, 4542], _
			[$IsleOfWurms, 8353, 2995], _
			[$IsleOfWurms, 6708, 3093], _
			[$UnchartedIsle, 2530, -2403]]
	For $i = 0 To (UBound($Waypoints_by_RareMatTrader) - 1)
		If ($Waypoints_by_RareMatTrader[$i][0] == True) Then
			Do
				GenericRandomPath($Waypoints_by_RareMatTrader[$i][1], $Waypoints_by_RareMatTrader[$i][2], Random(60, 80, 2))
			Until CheckArea($Waypoints_by_RareMatTrader[$i][1], $Waypoints_by_RareMatTrader[$i][2])
		EndIf
	Next
	Local $lRareTrader = 'Rare Material Trader'
	Local $lRare = GetAgentByName($lRareTrader)
	If IsDllStruct($lRare) Then
		Out('Going to ' & $lRareTrader)
		GoToNPC($lRare)
		RndSleep(Random(3000, 4200))
	EndIf
	;~This section does the buying
	Local $MatID
	TraderRequest($MatID)
	Sleep(500 + 3 * GetPing())
	While GetGoldCharacter() > 20*1000
		TraderRequest($MatID)
		Sleep(500 + 3 * GetPing())
		TraderBuy()
	WEnd
EndFunc
#EndRegion Guild Hall




#Region Unused
;Bolt ons from Chest Bot script i.e. Storing Golds, unids, consumables etc.
#Region Storage
Func StoreItemsEx()
	Out('Storing Items')
	Local $aItem, $m, $Q, $lbag, $Slot, $Full, $NSlot
	For $i = 1 To 4
		$lbag = GetBag($i)
		For $j = 1 To DllStructGetData($lbag, 'Slots')
			$aItem = GetItemBySlot($lbag, $j)
			If DllStructGetData($aItem, 'ID') = 0 Then ContinueLoop
			$m = DllStructGetData($aItem, 'ModelID')
			$Q = DllStructGetData($aItem, 'quantity')

			If($Map_StackableItems[$m] <> null And ($Q = 250)) Then
				Do
					For $Bag = 8 To 12
						$Slot = FindEmptySlot($Bag)
						$Slot = @extended
						If $Slot <> 0 Then
							$Full = False
							$NSlot = $Slot
							ExitLoop 2
						Else
							$Full = True
						EndIf
						Sleep(400)
					Next
				Until $Full = True
				If $Full = False Then
					MoveItem($aItem, $Bag, $NSlot)
					Sleep(GetPing() + 500)
				EndIf
			EndIf
		Next
	Next
EndFunc

#EndRegion Unused