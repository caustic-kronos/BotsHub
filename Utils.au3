#include-once

#include "GWA2_Headers.au3"
#include "GWA2.au3"
#include "GWA2_ID.au3"

Opt("MustDeclareVars", 1)


Global $STATS_MAP = CreateStatisticsMap()
Global Const $RANGE_ADJACENT=156, $RANGE_NEARBY=240, $RANGE_AREA=312, $RANGE_EARSHOT=1000, $RANGE_SPELLCAST = 1085, $RANGE_SPIRIT = 2500, $RANGE_COMPASS = 5000
Global Const $RANGE_ADJACENT_2=156^2, $RANGE_NEARBY_2=240^2, $RANGE_AREA_2=312^2, $RANGE_EARSHOT_2=1000^2, $RANGE_SPELLCAST_2=1085^2, $RANGE_SPIRIT_2=2500^2, $RANGE_COMPASS_2=5000^2

;~ Main method from utils, used only to run tests
Func RunTests($STATUS)
	Local $target = GetNearestEnemyToCoords(-13262, -5486)
	Local $foesBalled = GetNumberOfFoesInRangeOfAgentTest($target, $RANGE_NEARBY)
	Out("Foes balled : " & $foesBalled)

	#CS
	Local $stage = 0
	Local $target
	
	Out("s:" & $stage)
	TargetNearestEnemy()
	$stage += 1
	Sleep(3000)
	
	Out("s:" & $stage)
	$target = GetCurrentTargetID()
	Out(DllStructGetData($target, 'ID'))
	$stage += 1
	Sleep(3000)
	
	while (true)
		Out("s:" & $stage)
		TargetNextEnemy()
		$target = GetCurrentTargetID()
		Out(DllStructGetData($target, 'ID'))
		$stage += 1
		Sleep(3000)
	wend
	#CE
	
	;Out("Tests" & GetMapID())
	
	;Local $test = GetLastDialogID()
	;Out("Tests" & $test)
	;Out("Tests" & GetLastDialogIDHex($test))

	;Local $lQuestStruct = DllStructCreate('long id;long LogState;byte unknown1[12];long MapFrom;float X;float Y;byte unknown2[8];long MapTo;long Reward;long Objective')
	;Local $quest = GetQuestByID(457)
	;Out("id:" & $quest.id)
	;Out("mapFrom:" & $quest.MapFrom)
	;Out("MapTo:" & $quest.MapTo)
	;Out("Reward:" & $quest.Reward)
	;Out("Objective:" & $quest.Objective)


	;$STATS_MAP["success_code"] = 0
	$STATS_MAP["success_code"] = 2
	Return
EndFunc

Func GetNumberOfFoesInRangeOfAgentTest($aAgent, $aRange)
	Local $lAgent, $lDistance
	Local $lCount = 0

	If Not IsDllStruct($aAgent) Then $aAgent = GetAgentByID($aAgent)

	For $i = 1 To GetMaxAgents()
		$lAgent = GetAgentByID($i)
		If BitAND(DllStructGetData($lAgent, 'typemap'), 262144) Then ContinueLoop
		If DllStructGetData($lAgent, 'Type') <> 0xDB Then ContinueLoop
		If DllStructGetData($lAgent, 'Allegiance') <> 3 Then ContinueLoop
		If DllStructGetData($lAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($lAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		$lDistance = GetDistance($aAgent, $lAgent)
		If $lDistance > $aRange Then ContinueLoop
		$lCount += 1
	Next

	Return $lCount
EndFunc



Func DynamicExecution($args)
	Local $arguments = ParseFunctionArguments($args)
	Switch $arguments[0]
		Case 0
			Out("Call to nothing ?!")
			Return
		Case 1
			Out("Call to " & $arguments[1])
			Call($arguments[1])
		Case 2
			Out("Call to " & $arguments[1] & " " & $arguments[2])
			Call($arguments[1], $arguments[2])
		Case 3
			Out("Call to " & $arguments[1] & " " & $arguments[2] & " " & $arguments[3])
			Call($arguments[1], $arguments[2], $arguments[3])
		Case 4
			Out("Call to " & $arguments[1] & " " & $arguments[2] & " " & $arguments[3] & " " & $arguments[4])
			Call($arguments[1], $arguments[2], $arguments[3], $arguments[4])
	EndSwitch
EndFunc


Func ParseFunctionArguments($functionCall)
	Local $openParenthesisPosition = StringInStr($functionCall, "(")
	Local $functionName = StringLeft($functionCall, $openParenthesisPosition - 1)

	Local $arguments[2] = [1, $functionName]
	Out($functionName)
	Local $commaPosition = $openParenthesisPosition + 1
	Local $temp = StringInStr($functionCall, ",", 0, 1, $commaPosition)
	While $temp <> 0
		_ArrayAdd($arguments, StringMid($functionCall, $commaPosition, $temp - $commaPosition))
		Out(StringMid($functionCall, $commaPosition, $temp - $commaPosition))
		$commaPosition = $temp + 1
		$temp = StringInStr($functionCall, ",", 0, 1, $commaPosition)
	WEnd
	_ArrayAdd($arguments, StringMid($functionCall, $commaPosition, StringLen($functionCall) - $commaPosition))
	Out(StringMid($functionCall, $commaPosition, StringLen($functionCall) - $commaPosition))
	$arguments[0] = Ubound($arguments) - 1
	Return $arguments
EndFunc


#Region Statistics management


;~ Create a map for information/statistics sharing between programs
Func CreateStatisticsMap()
	Local Const $Array_Statistics[16][2] = [["success_code", -1], ["runs", 0], ["failures", 0], ["run_time", 0], ["gold_earned", 0], ["gold_items_obtained", 0], ["experience_earned", 0], _
		["asura_title_points_earned", 0], ["deldrimor_title_points_earned", 0], ["norn_title_points_earned", 0], ["vanguard_title_points_earned", 0], _
		["kurzick_title_points_earned", 0], ["luxon_title_points_earned", 0], ["lightbringer_title_points_earned", 0], ["sunspear_title_points_earned", 0]]
	Local $STATS_MAP = MapFromDoubleArray($Array_Statistics)
	Return $STATS_MAP
EndFunc


Func AppendArrayMap($map, $key, $element)
	If ($map[$key] == null) Then
		Local $newArray[1] = [$element]
		$map[$key] = $newArray
	Else 
		_ArrayAdd($map[$key], $element)
	EndIf
	Return $map
EndFunc


;~ Fill statistics
Func FillStats($time = 0)
	Local Static $FirstGoldCount = GetGoldCharacter()
	Local Static $FirstExperienceCount = GetExperience()
	Local Static $FirstAsuraTitlePoints = GetAsuraTitle()
	Local Static $FirstNornTitlePoints = GetNornTitle()
	
	;Local Static $ChunkOfDrakeFleshCount = 0
	;Local Static $SkaleFinsCount = 0
	;Local Static $GlacialStonesCount = 0
	;Local Static $DiessaChalicesCount = 0
	;Local Static $RinRelicsCount = 0
	;Local Static $WintersdayGiftsCount = 0
	;Local Static $MargoniteGemstoneCount = 0
	;Local Static $TitanGemstoneCount = 0
	;Local Static $TormentGemstoneCount = 0
	
	Local $successCode = $STATS_MAP["success_code"]
	;Either bot did not run yet or ran but was paused
	If $successCode == -1 Then Return

	$STATS_MAP["runs"] += 1
	if ($successCode == 1) Then $STATS_MAP["failures"] += 1
	$STATS_MAP["run_time"] += $time
	$STATS_MAP["gold_earned"] = GetGoldCharacter() - $FirstGoldCount
	$STATS_MAP["experience_earned"] = GetExperience() - $FirstExperienceCount
	$STATS_MAP["norn_title_points_earned"] = GetNornTitle() - $FirstNornTitlePoints
	$STATS_MAP["asura_title_points_earned"] = GetAsuraTitle() - $FirstAsuraTitlePoints
EndFunc


;~ Update statistics
Func UpdateStats()
	;Global stats
	GUICtrlSetData($RunsLabel, "Runs: " & $STATS_MAP["runs"])
	GUICtrlSetData($FailuresLabel, "Failures: " & $STATS_MAP["failures"])
	GUICtrlSetData($TimeLabel, "Time: " & Round($STATS_MAP["run_time"]/60000) & "min" & Round(Mod($STATS_MAP["run_time"], 60000)/1000) & "s")
	Local $timePerRun = $STATS_MAP["run_time"] / $STATS_MAP["runs"]
	GUICtrlSetData($TimePerRunLabel, "Time per run: " & Round($timePerRun/60000) & "min" & Round(Mod($timePerRun, 60000)/1000) & "s")
	GUICtrlSetData($GoldLabel, "Gold: " & Round($STATS_MAP["gold_earned"]/1000) & "k" & Mod($STATS_MAP["gold_earned"], 1000) & "g")
	GUICtrlSetData($GoldItemsLabel, "Gold Items: "  & $STATS_MAP["gold_items_obtained"])
	GUICtrlSetData($ExperienceLabel, "Experience: " & $STATS_MAP["experience_earned"])
	
	;Item stats
	;GUICtrlSetData($ChunkOfDrakeFleshLabel, "Chunks Of Drake Flesh: " & $STATS_MAP["ChunkOfDrakeFleshCount"])
	;GUICtrlSetData($SkaleFinsLabel, "Skale Fins: " & $SkaleFinsCount)
	;GUICtrlSetData($GlacialStonesLabel, "Glacial Stones: " & $GlacialStonesCount)
	;GUICtrlSetData($DiessaChalicesLabel, "Diessa Chalices: " & $DiessaChalicesCount)
	;GUICtrlSetData($RinRelicsLabel, "Rin Relics: " & $RinRelicsCount)
	;GUICtrlSetData($WintersdayGiftsLabel, "Wintersday Gifts: " & $WintersdayGiftsCount)
	;GUICtrlSetData($MargoniteGemstoneLabel, "Margonite Gemstones: " & $MargoniteGemstoneCount)
	;GUICtrlSetData($TitanGemstoneLabel, "Titan Gemstones: " & $TitanGemstoneCount)
	;GUICtrlSetData($TormentGemstoneLabel, "Torment Gemstones: " & $TormentGemstoneCount)
	
	;Title stats
	GUICtrlSetData($AsuraTitleLabel, "Asura: " & $STATS_MAP["asura_title_points_earned"])
	GUICtrlSetData($DeldrimorTitleLabel, "Deldrimor: " & $STATS_MAP["deldrimor_title_points_earned"])
	GUICtrlSetData($NornTitleLabel, "Norn: " & $STATS_MAP["norn_title_points_earned"])
	GUICtrlSetData($VanguardTitleLabel, "Vanguard: " & $STATS_MAP["vanguard_title_points_earned"])
	GUICtrlSetData($KurzickTitleLabel, "Kurzick: " & $STATS_MAP["kurzick_title_points_earned"])
	GUICtrlSetData($LuxonTitleLabel, "Luxon: " & $STATS_MAP["luxon_title_points_earned"])
	GUICtrlSetData($LightbringerTitleLabel, "Lightbringer: " & $STATS_MAP["lightbringer_title_points_earned"])
	GUICtrlSetData($SunspearTitleLabel, "Sunspear: " & $STATS_MAP["sunspear_title_points_earned"])		
EndFunc
#EndRegion Statistics management


#Region GW Utils
#Region Titles
;=================================================================================================
; Function:			SetDisplayedTitle($aTitle = 0)
; Description:		Set the currently displayed title.
; Parameter(s):		Parameter = $aTitle
;								No Title		= 0x00
;								Spearmarshall 	= 0x11
;								Lightbringer 	= 0x14
;								Asuran 			= 0x26
;								Dwarven 		= 0x27
;								Ebon Vanguard 	= 0x28
;								Norn 			= 0x29
;; Requirement(s):	GW must be running and Memory must have been scanned for pointers (see Initialize())
; Return Value(s):	Returns displayed Title
; Author(s):		Skaldish
;=================================================================================================
; Func SetDisplayedTitle($aTitle = 0)
; 	If $aTitle Then
; 		Return SendPacket(0x8, $HEADER_TITLE_DISPLAY, $aTitle)
; 	Else
; 		Return SendPacket(0x4, $HEADER_TITLE_CLEAR)
; 	EndIf
; EndFunc
#Region Titles


#Region Map and travel
;~ Get your own location
Func GetOwnLocation()
	Local $lMe = GetAgentByID(-2)
	Out("X: " & DllStructGetData($lMe, 'X') & ", Y: " & DllStructGetData($lMe, 'Y'))
EndFunc


;~ Travel to specified map and specified district/language
Func DistrictTravel($mapID, $district, $language)
	MoveMap($mapID, $district, 0, $language)
	WaitMapLoading($mapID, 30000)
	Sleep(GetPing()+3000)
EndFunc


;~ Travel to specified map to a random district
;~ 7=eu, 8=eu+int, 11=all(incl. asia)
Func RandomDistrictTravel($mapID, $district = 7)
	Local $Region[11]   = [$ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_EUROPE, $ID_INTERNATIONAL, $ID_KOREA, $ID_CHINA, $ID_JAPAN]
	Local $Language[11] = [$ID_ENGLISH, $ID_FRENCH, $ID_GERMAN, $ID_ITALIAN, $ID_SPANISH, $ID_POLISH, $ID_RUSSIAN, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH, $ID_ENGLISH]
	Local $Random = Random(0, $district - 1, 1)
	MoveMap($mapID, $Region[$Random], 0, $Language[$Random])
	WaitMapLoading($mapID, 30000)
	Sleep(GetPing()+3000)
EndFunc
#EndRegion Map and travel


#Region Inventory


#Region Count and find items
;~ Count available slots in the inventory
Func CountSlots()
	Local $bag
	Local $availableSlots = 0
	; If bag is missing it just won't count
	For $i = 1 To 5
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


;~ Counts black dyes in inventory
Func GetBlackDyeCount()
	Return GetInventoryItemCount($ID_Black_Dye)
EndFunc


;~ Counts birthday cupcakes in inventory
Func GetBirthdayCupcakeCount()
	Return GetInventoryItemCount($ID_Birthday_Cupcake)
EndFunc


;~ Look for an item in bags and return bag and slot of the item, [0, 0] else (positions start at 1)
Func findInInventory($itemID)
	Local $item
	Local $itemBagAndSlot[2]
	$itemBagAndSlot[0] = $itemBagAndSlot[1] = 0

	For $bag = 1 To 5
		Local $bagSize = GetMaxSlots($bag)
		For $slot = 1 To $bagSize
			$item = GetItemBySlot($bag, $slot)
			If(DllStructGetData($item, "ModelID") == $itemID) Then
				$itemBagAndSlot[0] = $bag
				$itemBagAndSlot[1] = $slot
			EndIf
		Next
	Next
	Return $itemBagAndSlot
EndFunc


;~ Counts anything in inventory
Func GetInventoryItemCount($itemID)
	Local $amountItem
	Local $bag
	Local $item
	For $i = 1 To 4
		$bag = GetBag($i)
		Local $bagSize = DllStructGetData($bag, "Slots")
		For $j = 1 To $bagSize
			$item = GetItemBySlot($bag, $j)
			
			If $Map_Dyes[$itemID] <> null Then
				If ((DllStructGetData($item, "ModelID") == $ID_Dyes) And (DllStructGetData($item, "ExtraID") == $itemID) Then $amountItem += DllStructGetData($item, "Quantity")
			Else
				If DllStructGetData($item, "ModelID") == $itemID Then $amountItem += DllStructGetData($item, "Quantity")
			EndIf
		Next
	Next
	Return $amountItem
EndFunc
#EndRegion Count and find items


#Region Loot and use items
;~ Loot items around character
Func PickUpItems($defendFunction = null)
	Local $lAgent
	Local $lItem
	Local $lDeadlock
	For $i = 1 To GetMaxAgents()
		If GetIsDead(-2) Then Return
		$lAgent = GetAgentByID($i)
		If DllStructGetData($lAgent, 'Type') <> 0x400 Then ContinueLoop
		$lItem = GetItemByAgentID($i)
		If ShouldPickItem($lItem) Then
			If $defendFunction <> null Then $defendFunction()
			PickUpItem($lItem)
			$lDeadlock = TimerInit()
			While GetAgentExists($i)
				Sleep(100)
				If GetIsDead(-2) Then Return
				If TimerDiff($lDeadlock) > 10000 Then ExitLoop
			WEnd
		EndIf
	Next
EndFunc


;~ Uses a cupcake from inventory, if present
Func UseCupcake()
	Local $Birthday_Cupcake_Slot = findInInventory($ID_Birthday_Cupcake)
	UseItemBySlot($Birthday_Cupcake_Slot[0], $Birthday_Cupcake_Slot[1])
EndFunc

Func UseEgg()
	Local $GoldenEggSlot = findInInventory($ID_Golden_Egg)
	UseItemBySlot($GoldenEggSlot[0], $GoldenEggSlot[1])
EndFunc


;~ Uses the Item from $bag at position $slot (positions start at 1)
Func UseItemBySlot($bag, $slot)
	If $bag > 0 And $slot > 0 Then
		If (GetMapLoading() == 1) And (GetIsDead(-2) == False) Then
			Local $item = GetItemBySlot($bag, $slot)
			SendPacket(8, $HEADER_Item_USE, DllStructGetData($item, "ID"))
		EndIf
	EndIf
EndFunc
#EndRegion Loot and use items


#Region Items tests

Func GetItemMaxDmg($item)
	If Not IsDllStruct($item) Then $item = GetItemByItemID($item)
	Local $modString = GetModStruct($item)
	Local $position = StringInStr($modString, "A8A7"); Weapon Damage
	If $position = 0 Then $position = StringInStr($modString, "C867"); Energy (focus)
	If $position = 0 Then $position = StringInStr($modString, "B8A7"); Armor (shield)
	If $position = 0 Then Return 0
	Return Int("0x" & StringMid($modString, $position - 2, 2))
EndFunc


;~ Return true if the item should be picked up
Func ShouldPickItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $itemExtraID = DllStructGetData($item, "ExtraID")
	Local $rarity = GetRarity($item)
	Local $characterGold = GetGoldCharacter()
	;Only pick gold if character has less than 99k in inventory
	If (($itemID == $ID_GOLD) And (GetGoldCharacter() < 99000)) Then
		Return True
	ElseIf IsBasicMaterial($itemID) Then
		Return GUICtrlRead($LootBasicMaterialsCheckbox) == $GUI_CHECKED
	ElseIf IsRareMaterial($itemID) Then
		Return GUICtrlRead($LootRareMaterialsCheckbox) == $GUI_CHECKED
	ElseIf IsTome($itemID) Then
		Return GUICtrlRead($LootTomesCheckbox) == $GUI_CHECKED
	ElseIf IsGoldScroll($itemID) Then
		Return GUICtrlRead($LootScrollsCheckbox) == $GUI_CHECKED
	ElseIf IsBlueScroll($itemID) Then
		Return GUICtrlRead($LootScrollsCheckbox) == $GUI_CHECKED
	ElseIf IsKey($itemID) Then
		Return GUICtrlRead($LootKeysCheckbox) == $GUI_CHECKED
	ElseIf ($itemID == $ID_Dyes) Then
		Return (($itemExtraID == $ID_Black_Dye) Or ($itemExtraID == $ID_White_Dye) Or (GUICtrlRead($LootDyesCheckbox) == $GUI_CHECKED))
	ElseIf ($itemID == $ID_Glacial_Stone) Then
		Return GUICtrlRead($LootGlacialStonesCheckbox) == $GUI_CHECKED
	ElseIf ($itemID == $ID_Jade_Bracelet) Then
		Return True
	ElseIf IsMapPiece($itemID) Then
		Return GUICtrlRead($LootMapPiecesCheckbox) == $GUI_CHECKED
	ElseIf IsStackableItem($itemID) Then
		Return True
	ElseIf ($itemID == $ID_Lockpick)Then
		Return True
	ElseIf ($rarity == $RARITY_Gold) Then
		Return True
	ElseIf ($rarity == $RARITY_Green) Then
		Return True
	ElseIf ($rarity == $RARITY_Purple) Then
		Return GUICtrlRead($LootPurpleItemsCheckbox) == $GUI_CHECKED
	ElseIf ($rarity == $RARITY_Blue) Then
		Return GUICtrlRead($LootBlueItemsCheckbox) == $GUI_CHECKED
	ElseIf ($rarity == $RARITY_White) Then
		Return GUICtrlRead($LootWhiteItemsCheckbox) == $GUI_CHECKED
	EndIf
	Return False
EndFunc


;~ Return true if the item should be salvaged
; TODO : refine which items should be salvaged and which should not
Func ShouldSalvageItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $rarity = GetRarity($item)
	;Local $requirement = GetItemReq($item)
	If IsBasicMaterial($itemID) Then
		Return False
	ElseIf IsRareMaterial($itemID) Then
		Return False
	ElseIf IsTome($itemID) Then
		Return False
	ElseIf IsGoldScroll($itemID) Then
		Return False
	ElseIf IsBlueScroll($itemID) Then
		Return False
	ElseIf IsKey($itemID) Then
		Return False
	ElseIf ($itemID == $ID_Dyes) Then
		Return False
	ElseIf ($itemID == $ID_Glacial_Stone) Then
		Return False
	ElseIf IsMapPiece($itemID) Then
		Return False
	ElseIf IsStackableItem($itemID) Then
		Return False
	ElseIf ($itemID == $ID_Lockpick)Then
		Return False
	ElseIf ($rarity == $RARITY_Gold) Then
		Return False
	ElseIf ($rarity == $RARITY_Green) Then
		Return False
	ElseIf ($rarity == $RARITY_Purple) Then
		Return False
	ElseIf ($rarity == $RARITY_Blue) Then
		Return False
	ElseIf ($rarity == $RARITY_White) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Return true if the item should be sold to the merchant
; TODO : refine which items should be sold and which should not
Func ShouldSellItem($item)
	Local $itemID = DllStructGetData(($item), 'ModelID')
	Local $itemExtraID = DllStructGetData($item, "ExtraID")
	Local $rarity = GetRarity($item)
	;Local $requirement = GetItemReq($item)
	If IsBasicMaterial($itemID) Then
		Return False
	ElseIf IsRareMaterial($itemID) Then
		Return False
	ElseIf IsTome($itemID) Then
		Return False
	ElseIf IsGoldScroll($itemID) Then
		Return True
	ElseIf IsBlueScroll($itemID) Then
		Return True
	ElseIf ($itemID == $ID_Lockpick)Then
		Return False
	ElseIf IsKey($itemID) Then
		Return True
	ElseIf ($itemID == $ID_Dyes) Then
		Return False
	ElseIf ($itemID == $ID_Glacial_Stone) Then
		Return False
	ElseIf IsMapPiece($itemID) Then
		Return False
	ElseIf IsStackableItem($itemID) Then
		Return False
	ElseIf ($rarity == $RARITY_Gold) Then
		Return False
	ElseIf ($rarity == $RARITY_Green) Then
		Return False
	ElseIf ($rarity == $RARITY_Purple) Then
		Return False
	ElseIf ($rarity == $RARITY_Blue) Then
		Return False
	ElseIf ($rarity == $RARITY_White) Then
		Return False
	EndIf
	Return False
EndFunc


;~ Return true if the item is a kit or a lockpick - used in Storage Bot to not sell those
Func IsGeneralItem($itemID)
	Return $Map_General_Items[$itemID] <> null
EndFunc


Func IsArmorSalvageItem($itemID)
	Return DllStructGetData($item, "type") == $ID_Type_Armor_Salvage
EndFunc


Func IsStackableItem($itemID)
	Return $Map_StackableItems[$itemID] <> null
EndFunc


Func IsMaterial($itemID)
	Return $Map_All_Materials[$itemID] <> null
EndFunc


Func IsBasicMaterial($itemID)
	Return $Map_Basic_Materials[$itemID] <> null
EndFunc


Func IsRareMaterial($itemID)
	Return $Map_Rare_Materials[$itemID] <> null
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


Func IsTrophy($itemID)
	Return $Trophies_Array[$itemID] <> null
EndFunc


Func IsSummoningStone($itemID)
	Return $Map_Summoning_Stones[$itemID] <> null
EndFunc


Func IsWeapon($item)
	Return $Map_Weapon_Types[DllStructGetData($item, "type")] <> null
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
#EndRegion Items tests


; Find the first empty slot in the given bag
Func FindEmptySlot($bag)
	Local $item
	For $slot = 1 To DllStructGetData(GetBag($bag), "Slots")
		Sleep(40)
		$item = GetItemBySlot($bag, $slot)
		If DllStructGetData($item, "ID") = 0 Then Return $slot
	Next
	Return 0
EndFunc


; Find all empty slots in the given bag
Func FindEmptySlots($bag)
	Local $emptySlots[] = []
	Local $item
	For $slot = 1 To DllStructGetData(GetBag($bag), "Slots")
		Sleep(40)
		$item = GetItemBySlot($bag, $slot)
		If DllStructGetData($item, "ID") = 0 Then _ArrayAdd($emptySlots, $slot)
	Next
	Return $emptySlots
EndFunc


; Find first empty slot in chest
Func FindChestEmptySlot()
	Local $emptySlot
	For $i = 8 To 21
		$emptySlot = FindEmptySlot($i)
		If $emptySlot <> 0 Then Return $emptySlot
		Sleep(400)
	Next
	Return 0
EndFunc


; Find all empty slots in chest
Func FindChestEmptySlots()
	Local $emptySlots[]
	For $i = 8 To 21
		Local $chestTabEmptySlots[] = FindEmptySlots($i)
		If UBound($chestTabEmptySlots) <> 0 Then $emptySlots[$i] = $chestTabEmptySlots
		Sleep(400)
	Next
	Return $emptySlots
EndFunc


;~ Balance character gold to the amount given
Func BalanceCharacterGold($goldAmount)
	Out("Balancing character's gold")
	Local $GCharacter = GetGoldCharacter()
	Local $GStorage = GetGoldStorage()
	If $GStorage > 950000 Then
		Out("Too much gold in chest, use some.")
	ElseIf $GStorage < 50000 Then
		Out("Not enough gold in chest, get some.")
	ElseIf $GCharacter > $goldAmount Then
		DepositGold($GCharacter - $goldAmount)
	ElseIf $GCharacter < $goldAmount Then
		WithdrawGold($goldAmount - $GCharacter)
	EndIf
	Return True
EndFunc

#EndRegion Inventory and consumables

#Region Identification and Salvage

;~ Get the number of uses of a kit
Func GetKitUsesLeft($kitID)
	Local $kitStruct = GetModStruct($kitID)
	Return Int("0x" & StringMid($kitStruct, 11, 2))
EndFunc


;~ Identify all items from inventory
Func IdentifyAllItems()
	Out("Identifying all items")
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		Local $item
		For $i = 1 To DllStructGetData($bag, "slots")
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, "ID") = 0 Then ContinueLoop
			
			Local $identificationKit = FindIDKitOrBuySome()
			IdentifyItem($item)
			Sleep(GetPing()+500)
		Next
	Next
EndFunc


;~ Salvage all items from inventory (non functional)
Func SalvageAllItems()
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		Local $item
		For $i = 1 To DllStructGetData($bag, "slots")
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, "ID") = 0 Then ContinueLoop
			
			Local $salvageKit = FindSalvageKitOrBuySome()
			SalvageItem($item)
			Sleep(GetPing()+500)
		Next
	Next
EndFunc


;~ Find an identification Kit in inventory or buy one. Return the ID of the kit or 0 if no kit was bought
Func FindIDKitOrBuySome()
	Local $IdentificationKitID = FindIDKit()
	If $IdentificationKitID <> 0 Then Return $IdentificationKitID
	
	If GetGoldCharacter() < 500 And GetGoldStorage() > 499 Then
		WithdrawGold(500)
		Sleep(GetPing() + 500)
	EndIf
	Local $j = 0
	Do
		BuyItem(6, 1, 500)
		Sleep(GetPing() + 500)
		$j = $j + 1
	Until FindIDKit() <> 0 Or $j = 3
	If $j = 3 Then Return 0
	Sleep(GetPing() + 500)
	Return FindIDKit()
EndFunc


;~ Find a salvage Kit in inventory or buy one. Return the ID of the kit or 0 if no kit was bought
Func FindSalvageKitOrBuySome()
	Local $SalvageKitID = FindSalvageKit()
	If $SalvageKitID <> 0 Then Return $SalvageKitID
	
	If GetGoldCharacter() < 400 And GetGoldStorage() > 399 Then
		WithdrawGold(400)
		Sleep(GetPing() + 400)
	EndIf
	Local $j = 0
	Do
		BuyItem(3, 1, 400)
		Sleep(GetPing() + 400)
		$j = $j + 1
	Until FindSalvageKit() <> 0 Or $j = 3
	If $j = 3 Then Return 0
	Sleep(GetPing() + 400)
	Return FindSalvageKit()
EndFunc

#EndRegion Identification and Salvage

;~ Go to the NPC the closest to given coordinates
Func GoNearestNPCToCoords($x, $y)
	Local $guy, $Me
	Do
		RndSleep(100)
		$guy = GetNearestNPCToCoords($x, $y)
	Until DllStructGetData($guy, 'Id') <> 0
	ChangeTarget($guy)
	RndSleep(250)
	GoNPC($guy)
	RndSleep(250)
	Do
		RndSleep(250)
		Move(DllStructGetData($guy, 'X'), DllStructGetData($guy, 'Y'), 40)
		RndSleep(250)
		GoNPC($guy)
		RndSleep(250)
		$Me = GetAgentByID(-2)
	Until ComputeDistance(DllStructGetData($Me, 'X'), DllStructGetData($Me, 'Y'), DllStructGetData($guy, 'X'), DllStructGetData($guy, 'Y')) < 250
	RndSleep(250)
EndFunc

#EndRegion GW Utils




#Region Utils
;~ Return the value if it's not null else the defaultValue
Func GetOrDefault($value, $defaultValue)
	If ($value == null) Then Return $defaultValue
	Return $value
EndFunc


;~ Create a map from an array to have a one liner map instanciation
Func MapFromArray(Const ByRef $array)
	Local $map[]
	For $i = 0 To UBound($array) - 1
		$map[$array[$i]] = 1
	Next
	Return $map
EndFunc


;~ Create a map from a double array to have a one liner map instanciation with values
Func MapFromDoubleArray(Const ByRef $array)
	Local $map[]
	For $i = 0 To UBound($array) - 1
		$map[$array[$i][0]] = $array[$i][1]
	Next
	Return $map
EndFunc


;~ Return True if item is present in array, else False
Func ArrayContains($array, $item)
	For $i = 0 To UBound($array) - 1
		If $array[$i] == $item Then Return True
	Next
	Return False
EndFunc


; Find common longest substring in two strings
Func LongestCommonSubstringOfTwo($string1, $string2)
	Local $longestCommonSubstrings[0]
	Local $string1characters = StringSplit($string1, "")
	Local $string2characters = StringSplit($string2, "")
	
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



; Find common longest substring in array of strings
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


; Return true if find is into every string in the array of strings
Func IsSubstring($find, $strings)
	If UBound($strings) < 1 And StringLen($find) < 1 Then
		Return False
	EndIf
	For $string In $strings
		If Not StringInStr($string, $find) Then
			Return False
		EndIf
	Next
	Return true
EndFunc


#EndRegion Utils



















;~ Store weapons, badly written
;~ TODO: unused, keep until storage function is written
Func Weapons($BagIndex, $SlotCount)
	Local $aItem
	Local $Bag
	Local $Slot
	Local $Full
	Local $NSlot
	For $I = 1 To $SlotCount
		Local $aItem = GetItemBySlot($BagIndex, $I)
		If DllStructGetData($aItem, "ID") = 0 Then ContinueLoop
		Local $ModStruct = GetModStruct($aItem)
		Local $Energy = StringInStr($ModStruct, "0500D822", 0, 1) ;~String for +5e mod
		Switch DllStructGetData($aItem, "Type")
			Case 2, 5, 15, 27, 32, 35, 36
				If $Energy > 0 Then
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
						Sleep(Random(450, 550))
					EndIf
				EndIf
		EndSwitch
	Next
EndFunc


;~ Waits until all foes are in Range
; TODO: unused, keep
Func WaitUntilAllFoesAreInRange($lRange)
	Local $lAgentArray = GetAgentArray(0xDB)
	Local $lMe = GetAgentByID(-2)
	Local $lDistance
	While True
		Sleep(100)
		If GetIsDead($lMe) Then Return
		StayAlive($lAgentArray)
		For $i = 1 To $lAgentArray[0]
			$lDistance = GetPseudoDistance($lMe, $lAgentArray[$i])
			If $lDistance < $RANGE_SPELLCAST_2 And $lDistance > $lRange^2 Then Return
		Next
	WEnd
EndFunc