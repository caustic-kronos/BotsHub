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


;~ Main method from storage bot, does all the things : identify, deal with data, store, salvage
Func ManageInventory($STATUS)
	; TODO :
	
	; - deposit in chest mesmer tomes, white and black dyes, ToT bags and other consumables, RARE weapons
	; - recycle all mods that need to be recycled (measure for measure, Forget Me Not, Strength and Honor, rare mods, insignias and runes)
	; - recycle all items that need to be recycled for materials (glacial stones, specific weapons)
	; - sell worthless items like bows and axes

	;Out('Travel to Guild Hall')
	;TravelGH()
	;WaitMapLoading()
	;Out('Checking Guild Hall')
	;CheckGuildHall()
	;RndSleep(500)
	;If $STATUS <> 'RUNNING' Then Return 2
	;GoToMerchant()
	;If $STATUS <> 'RUNNING' Then Return 2
	;BalanceCharacterGold(20000)
	;If $STATUS <> 'RUNNING' Then Return 2
	IdentifyAllItems()
	;If $STATUS <> 'RUNNING' Then Return 2

	;ConnectToDatabase()
	;StoreAllItemsData()
	;CompleteItemsNames()
	;CompleteItemsMods()
	;CompleteModsHexa()
	;SalvageAndStoreData()
	DisconnectFromDatabase()
	Return 0
EndFunc




#Region Database


;# Connect to the database storing information about items
Func ConnectToDatabase()
	_SQLite_Startup()
	$SQLITE_DB = _SQLite_Open('items_database.db3')
	_SQLite_Exec($SQLITE_DB, 'CREATE TABLE IF NOT EXISTS items_data (batch_ID, bag, bag_slot, model_ID, name, prefix, suffix, inscription, salvage, damage, attribute, requirement, item_ID, item_type, name_string, modstruct, quantity, value);')
EndFunc


;# Disconnect from the database
Func DisconnectFromDatabase()
	_SQLite_Close()
	_SQLite_Shutdown()
EndFunc


;~ Read data from item at bagIndex and slot and print it in the console
Func ReadOneItemData($bagIndex, $slot)
	Local $bag = GetBag($bagIndex)
	Local $item = GetItemBySlot($bagIndex, $slot)
	If DllStructGetData($item, 'ID') = 0 Then Return
	Out('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	Local $output = $bagIndex & ';'
	$output &= $slot & ';'
	$output &= DllStructGetData($item, 'rarity') & ';'
	$output &= DllStructGetData($item, 'ModelID') & ';'
	$output &= DllStructGetData($item, 'ID') & ';'
	$output &= DllStructGetData($item, 'Type') & ';'
	$output &= GetItemAttribute($item) & ';'
	$output &= GetItemReq($item) & ';'
	$output &= GetItemMaxDmg($item) & ';'
	$output &= DllStructGetData($item, 'NameString') & ';'
	$output &= GetModStruct($item) & ';'
	$output &= DllStructGetData($item, 'quantity') & ';'
	$output &= DllStructGetData($item, 'Value') & ';'
	Out($output)
	
	For $i = 0 To 20
		Out(DllStructGetData($item, $i))
	Next
EndFunc


;~ Read data from all items in inventory and print it in the console
Func ReadAllItemsData()
	Local $item, $output
	Out('bag;slot;rarity;modelID;ID;type;attribute;requirement;stats;nameString;mods;quantity;value')
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $slot = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $slot)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			
			$output = $bagIndex & ';'
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
			Out($output)
			RndSleep(500)
		Next
	Next
EndFunc


;~ Store in database all data that can be found in items in inventory
Func StoreAllItemsData()
	Local $InsertQuery, $item
	Local $batchID = GetPreviousBatchID() + 1
	
	Out('Scanning and storing all items data')
	_SQLite_Exec($SQLITE_DB, 'BEGIN;')
	$InsertQuery = 'INSERT INTO items_data VALUES' & @CRLF
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			GetItemReq($item)
			$InsertQuery &= '	('
			$InsertQuery &= $batchID & ', '
			$InsertQuery &= $bagIndex & ', '
			$InsertQuery &= $i & ', "'
			$InsertQuery &= DllStructGetData($item, 'modelID') & '", NULL, NULL, NULL, NULL, NULL, '
			$InsertQuery &= (IsWeapon($item) ? GetItemMaxDmg($item) : 'NULL') & ', '
			$InsertQuery &= (IsWeapon($item) ? GetItemAttribute($item) : 'NULL') & ', '
			$InsertQuery &= (IsWeapon($item) ? GetItemReq($item) : 'NULL') & ', "'
			$InsertQuery &= DllStructGetData($item, 'ID') & '", "'
			$InsertQuery &= DllStructGetData($item, 'type') & '", "'
			$InsertQuery &= DllStructGetData($item, 'nameString') & '", "'
			$InsertQuery &= GetModStruct($item) & '", '
			$InsertQuery &= DllStructGetData($item, 'quantity') & ', '
			$InsertQuery &= GetOrDefault(DllStructGetData($item, 'value'), 0) & ', '
			$InsertQuery &= GetRarity($item)
			$InsertQuery &= '),' & @CRLF
			Sleep(GetPing()+100)
		Next
	Next
	$InsertQuery = StringLeft($InsertQuery, StringLen($InsertQuery) - 3) & @CRLF & ';'
	Out($InsertQuery)
	_SQLite_Exec($SQLITE_DB, $InsertQuery)
	_SQLite_Exec($SQLITE_DB, 'COMMIT;')
EndFunc


;~ Get the previous batchID or -1 if no batch has been added into database
Func GetPreviousBatchID()
	Local $queryResult, $row, $lastBatchID, $query
	$query = 'SELECT COALESCE(MAX(batch_ID), -1) FROM items_data;'
	Out($query)
	_SQLite_Query($SQLITE_DB, $query, $queryResult)
	While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
		$lastBatchID = $row[0]
	WEnd
	Return $lastBatchID
EndFunc


;~ Complete items data with their name if those items have been recognised before
Func CompleteItemsNames()
	Local $query, $queryResult
	Out('Completing items names')
	$query = 'WITH data AS (' & @CRLF _
		& '	SELECT DISTINCT model_ID, name FROM items_data WHERE name IS NOT NULL' & @CRLF _
		& ')' & @CRLF _
		& 'UPDATE items_data' & @CRLF _
		& 'SET name = (SELECT name FROM data WHERE data.model_ID = items_data.model_ID)' & @CRLF _
		& 'WHERE name IS NULL'
	Out($query)
	_SQLite_Exec($SQLITE_DB, $query)
EndFunc


;~ Complete mods data by cross-comparing all modstructs from items that have the same mods and deduce the mod hexa from it
Func CompleteModsHexa()
	Out('Completing mods structure')
	Local $modTypes[3] = ['prefix', 'suffix', 'inscription']
	Local $modType, $query, $queryResult, $row, $modName
	For $modType In $modTypes
		Local $mapItemStruct[]
		$query = 'WITH valid_groups AS (' & @CRLF _
			& '	SELECT ' & $modType & ' FROM items_data WHERE ' & $modType & ' IS NOT NULL GROUP BY ' & $modType & ' HAVING COUNT(*) > 3' & @CRLF _
			& ')' & @CRLF _
			& 'SELECT items_data.' & $modType & ', items_data.modstruct' & @CRLF _
			& 'FROM items_data' & @CRLF _
			& 'INNER JOIN valid_groups ON valid_groups.' & $modType & ' = items_data.' & $modType & @CRLF _
			& 'ORDER BY items_data.' & $modType & ';'
		Out($query)
		_SQLite_Query($SQLITE_DB, $query, $queryResult)
		While _SQLite_FetchData($queryResult, $row) = $SQLITE_OK
			$mapItemStruct = AppendArrayMap($mapItemStruct, $row[0], $row[1])
		WEnd
		
		_SQLite_Exec($SQLITE_DB, 'BEGIN;')
		Local $modNames = MapKeys($mapItemStruct)
		For $modName In $modNames
			Local $modStruct = LongestCommonSubstring($mapItemStruct[$modName])
			$query = 'UPDATE mods_data' & @CRLF _
				& '	SET hexa = "' & $modStruct & '" WHERE name = "' & $modName & '" AND mod_type = "' & $modType & '";'
			Out($query)
			_SQLite_Exec($SQLITE_DB, $query)
		Next
		_SQLite_Exec($SQLITE_DB, 'COMMIT;')
	Next
EndFunc


;~ Auto fill the items mods based on the known modstructs
Func CompleteItemsMods()
	Out('Completing items mods')
	Local $batchID = GetPreviousBatchID()
	Local $modTypes[3] = ['prefix', 'suffix', 'inscription']
	Local $query
	For $modType In $modTypes
		$query = 'UPDATE items_data' & @CRLF _
			& 'SET ' & $modType & ' = (SELECT name FROM mods_data WHERE propagate = 1 AND hexa IS NOT NULL AND mod_type = "' & $modType & '" AND modstruct LIKE ("%" || hexa || "%"))' & @CRLF _
			& 'WHERE ' & $modType & ' IS NULL' & @CRLF _
			& 'AND batch_ID = ' & $batchID & @CRLF _
			& 'AND EXISTS (SELECT name FROM mods_data WHERE propagate = 1 AND hexa IS NOT NULL AND mod_type = "' & $modType & '" AND modstruct LIKE ("%" || hexa || "%"));'
		Out($query)
		_SQLite_Exec($SQLITE_DB, $query)
	Next
EndFunc


#EndRegion Database




#Region Guild Hall Specifics
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
	If IsDllStruct($chest)Then
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


#EndRegion Guild Hall Specifics




























Func SellBagItems($bagIndex)
	Local $item
	Local $bag = GetBag($bagIndex)
	Local $SlotCount = DllStructGetData($bag, 'slots')
	For $i = 1 To $SlotCount
		$item = GetItemBySlot($bagIndex, $i)
		If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
		If CanSell($item) Then
			Out('Selling Item: ' & $bagIndex & ', ' & $i)
			SellItem($item)
		EndIf
		Sleep(GetPing()+250)
	Next
EndFunc

Func CanSell($item)
	; Local $Requirement = GetItemReq($item)
	Local $itemID = DllStructGetData($item, 'ModelID')

	; Lockpicks, Kits
	If IsGeneralItem($itemID) Then Return False
	If $itemID == $ID_Glacial_Stone Then Return False
	If IsTome($itemID) Then Return False
	If IsMaterial($itemID) Then Return False
	If IsWeaponMod($itemID) Then Return False
	If IsStackableItem($itemID) Then Return False

	If $itemID == $ID_Dyes Then
		Switch DllStructGetData($item, 'ExtraID')
			Case $ID_Black_Dye, $ID_White_Dye
				Return False
			Case Else
				Return True
		EndSwitch
	EndIf
	
	Local $rarity = GetRarity($item)
	If $rarity == $RARITY_Gold Then Return True
	If $rarity == $RARITY_Purple Then Return True
	If $rarity == $RARITY_Blue Then Return True
	If $rarity == $RARITY_White Then Return True
	Return True
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
	If IsDllStruct($lRare)Then
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

#EndRegion Inventory




Func _salvage()
	Local $lquantityold, $loldvalue
	salvagekit()
	Local $lsalvagekitid = findsalvagekit()
	Local $lsalvagekitptr = getitemptr($lsalvagekitid)
	For $bag = 1 To 4
		$lbagptr = getbagptr($bag)
		$lbagp = getbag($bag)
		If $lbagptr = 0 Then ContinueLoop
		For $slot = 1 To memoryread($lbagptr + 32, 'long')
			$litem = getitemptrbyslot($lbagptr, $slot)
			$aitem = getitembyslot($bag, $slot)
			out('getcansalvage($litem)')
			If NOT getcansalvage($litem) Then ContinueLoop
			out('Salvaging : ' & $bag & ',' & $slot)
			$lquantity = memoryread($litem + 76, 'byte')
			$itemmid = memoryread($litem + 44, 'long')
			$itemrarity = getrarity($aitem)
			If $itemrarity = $rarity_white OR $itemrarity = $rarity_blue Then
				For $i = 1 To $lquantity
					If memoryread($lsalvagekitptr + 12, 'ptr') = 0 Then
						salvagekit()
						$lsalvagekitid = findsalvagekit()
						$lsalvagekitptr = getitemptr($lsalvagekitid)
					EndIf
					$lquantityold = $lquantity
					$loldvalue = memoryread($lsalvagekitptr + 36, 'short')
					startsalvage($aitem)
					Local $ldeadlock = TimerInit()
					Do
						Sleep(200)
					Until memoryread($lsalvagekitptr + 36, 'short') <> $loldvalue OR TimerDiff($ldeadlock) > 5000
				Next
			ElseIf $itemrarity = $rarity_purple OR $itemrarity = $rarity_gold Then
				$itemtype = memoryread($litem + 32, 'byte')
				If $itemtype = 0 Then
					ContinueLoop
				EndIf
				If memoryread($litem + 12, 'ptr') <> 0 Then
					If memoryread($lsalvagekitptr + 12, 'ptr') = 0 Then
						salvagekit()
						$lsalvagekitid = findsalvagekit()
						$lsalvagekitptr = getitemptr($lsalvagekitid)
					EndIf
					$loldvalue = memoryread($lsalvagekitptr + 36, 'short')
					startsalvage($aitem)
					Sleep(500 + getping())
					salvagematerials()
					Local $ldeadlock = TimerInit()
					Do
						Sleep(200)
					Until memoryread($lsalvagekitptr + 36, 'short') <> $loldvalue OR TimerDiff($ldeadlock) > 5000
				EndIf
			EndIf
		Next
	Next
	salvagekit()
EndFunc







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