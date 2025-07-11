; Author: Coaxx ?
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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :
; - Complete this bot

Opt('MustDeclareVars', 1)

; ==== Constantes ====
Global Const $LDOASkillbar = 'OgAScncGK+yM+1Z030WA'
Global Const $LDOAInformations = 'For best results, have :' & @CRLF _
	& '- Complete this list' & @CRLF _
	& ''
; Average duration ~ 10m
Global Const $LDOA_FARM_DURATION = (10 * 60) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($LDOA_Skill1) is better than UseSkillEx(1))
Global Const $LDOA_Skill1 = 1
Global Const $LDOA_Skill2 = 2
Global Const $LDOA_Skill3 = 3
Global Const $LDOA_Skill4 = 4
Global Const $LDOA_Skill5 = 5
Global Const $LDOA_Skill6 = 6
Global Const $LDOA_Skill7 = 7
Global Const $LDOA_Skill8 = 8

Global Const $ID_Quest_CharrAtTheGate = 0x2E
Global Const $ID_Quest_FarmerHamnet = 0x4A1

Global Const $ID_Luminescent_Scepter = 6508
Global Const $ID_Serrated_Shield = 6514

Global $LDOA_FARM_SETUP = False
Global $OutpostCheck = False

;~ Main method to get LDOA title
Func LDOATitleFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	If Not $LDOA_FARM_SETUP Then
		SetupLDOATitleFarm()
		$LDOA_FARM_SETUP = True
	EndIf
	; Difference between this bot and ALL the others : this bot can't go to Eye of the North for inventory management
	; This means that inventory management will have to be 'duplicated' here in this bot
	If (CountSlots(1, _Min($BAG_NUMBER, 4)) <= 5) Then
		PresearingInventoryManagement()
		; This line might not be necessary because we might deal with inventory in the same outpost we use for the farm
		$LDOA_FARM_SETUP = False
	EndIf
	If (CountSlots(1, $BAG_NUMBER) <= 5) Then
		Notice('Inventory full, pausing.')
		$LDOA_FARM_SETUP = False
		Return 2
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return LDOATitleFarmLoop($STATUS)
EndFunc


;~ LDOA Title farm setup
Func SetupLDOATitleFarm()
	Info('Setting up farm')

	LeaveGroup()
	SendChat('bonus', '/')

	If DllStructGetData(GetMyAgent(), 'Level') == 1 AND DllStructGetData(GetMyAgent(), 'Experience') == 0 Then
		Info('LDOA 1-2')
		InitialSetupLDOA()
	ElseIf DllStructGetData(GetMyAgent(), 'Level') >= 2 AND < 11 Then
		Info('LDOA 2-10')
		SetupCharrAtTheGateQuest()
	ElseIf $OutpostCheck == False Then
		Info('Checking for outposts...')
		OutpostRun()
		$OutpostCheck = True

		RndSleep(GetPing() + 750)
		Info('LDOA 11-20')
		SetupHamnetQuest()
	EndIf
	Info('Preparations complete')
EndFunc

;~ Initial setup for LDOA title farm if new char, this is done only once
Func InitialSetupLDOA()
	Local $LumS = FindInInventory($ID_Luminescent_Scepter)
	Local $SerS = FindInInventory($ID_Serrated_Shield)

	If $LumS[0] <> 0 AND $SerS[0] <> 0 Then
		EquipItem(6508)      ; Equip Luminescent Scepter
		EquipItem(6514)      ; Equip Serrated Shield
	EndIf
		
		
	;~ First Sir Tydus quest to get some skills
	;MoveTo(10399, 318)
	;MoveTo(11004, 1409)
	;MoveTo(11691, 3435)
	;GoToNPC(GetNearestNPCToCoords(11691, 3435))
	;RndSleep(GetPing() + 750)
	;Dialog(0x80DD01)
	;RndSleep(GetPing() + 750)
	
	MoveTo(7607, 5552)
	Move(7175,5229)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(6116, 3995)
	GoToNPC(GetNearestNPCToCoords(6116, 3995))
	RndSleep(GetPing() + 750)
	;Dialog(0x80DD07)
	;RndSleep(250)
	Dialog(0x805501)
	RndSleep(GetPing() + 750)
	MoveTo(4187, -948)
	MoveAggroAndKill(4207, -2892, '', 2500, Null)
	MoveTo(3771, -1729)
	MoveTo(6069, 3865)
	GoToNPC(GetNearestNPCToCoords(6069, 3865))
	RndSleep(GetPing() + 750)
	Dialog(0x805507)
	RndSleep(GetPing() + 750)
	MoveTo(2785, 7736)
	GoToNPC(GetNearestNPCToCoords(2785, 7736))
	RndSleep(GetPing() + 750)
	Dialog(0x804703)
	RndSleep(250)
	Dialog(0x804701)
EndFunc

;~ LDOA Title farm loop
Func LDOATitleFarmLoop($STATUS)
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	Info('Current level: ' & $level)

	If DllStructGetData(GetMyAgent(), 'Level') < 10 Then
		LDOATitleFarmUnder10()
	Else
		LDOATitleFarmAfter10()
	EndIf
	; If we level to 11, we reset the setup so that the bot starts on the 11-20 part
	Local $newLevel = DllStructGetData(GetMyAgent(), 'Level')
	If $level == 10 And $newLevel > $level Then $LDOA_FARM_SETUP = False
EndFunc

;~ Setup Charr at the gate quest
Func SetupCharrAtTheGateQuest()
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	Info('Setting up Charr at the gate quest...')

	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_CharrAtTheGate), 'Logstate')

	If $questStatus == 0 OR 3 Then
		RndSleep(GetPing() + 750)
		AbandonQuest(0x2E)
		RndSleep(GetPing() + 750)
		MoveTo(7974, 6142)
		MoveTo(5668, 10667)
		GoToNPC(GetNearestNPCToCoords(5668, 10667))
		RndSleep(GetPing() + 750)
		Dialog(0x802E01)
		RndSleep(GetPing() + 750)
	ElseIf $questStatus == 1 Then
		Info('Good to go!')
	EndIf
EndFunc

;~ Farm to do to level to level 10
Func LDOATitleFarmUnder10()
	Local $me = GetMyAgent()
	
	Info('Entering explorable')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(6220, 4470, 30)
	Info('Going to the gate')
	MoveTo(3180, 6468, 30)
	MoveTo(360, 6575, 30)
	MoveTo(-3140, 9610, 30)
	MoveTo(-3640, 10930, 30)
	MoveTo(-4165, 10655, 30)

	If GetIsDead() Then BackToAscalon()

	While 1
		If CountFoesInRangeOfAgent($me, 2000) >= 2 Then 
			Sleep(100)
		Else
			BackToAscalon()
			ExitLoop
		EndIf
	WEnd
	
	Return 0
EndFunc

;~ Setup Hamnet quest
Func SetupHamnetQuest()
	Info('I think Ill just call it There and Back Again, a Hobbits Holiday ♥')
	RandomDistrictTravel($ID_Ashford_Abbey)

	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	Info('Setting up Hamnet quest...')
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)

	Local $questStatus1 = DllStructGetData(GetQuestByID($ID_Quest_FarmerHamnet), 'Logstate')

	;~ Get quest if not already obtained
	If $questStatus1 == 0 Then
		Info('Quest not found, setting up...')
		RndSleep(GetPing() + 750)
		MoveTo(9516, 7668)
		MoveTo(9815, 7809)
		MoveTo(10280, 7895)
		MoveTo(10564, 7832)
		GoToNPC(GetNearestNPCToCoords(10564, 7832))
		RndSleep(GetPing() + 750)
	;~ If we have the quest, we can start the farm
	ElseIf $questStatus1 == 1 Then
		Info('Quest found, Good to go!')
	EndIf
EndFunc

;~ Farm to do to level to level 20
Func LDOATitleFarmAfter10()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')

	Info('Starting Hamnet farm...')

	While 1
		If $level < 20 Then
			Info('Current level: ' & $level)
			Hamnet()
		Else
			Info('Current level: ' & $level & ', stopping farm.')
			BackToAscalon()
			ExitLoop
		EndIf
	Wend

	Return 0
EndFunc

;~ Farmer Hamnet farm
Func Hamnet()
	Info('Heading to Foibles Fair!')
	RandomDistrictTravel($ID_Foibles_Fair)

	RndSleep(GetPing() + 750)

	MoveTo(-183, 9002)
	MoveTo(356, 7834)
	Info('Entering Wizards Folly!')
	Move(390, 7800)
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)

	While 1
		If GetMapID() == $ID_Wizards_Folly Then
			UseConsumable($ID_Igneous_Summoning_Stone)
			Info('Using Igneous Summoning Stone')
			ExitLoop
		Else
			Sleep(100)
		EndIf
	WEnd

	MoveAggroAndKill(2418, 5437, '', 2000, Null)

	If GetIsDead() Then Hamnet()

	ReturnToOutpost()
	Info('Returning to Foibles Fair')
	WaitMapLoading($ID_Foibles_Fair, 10000, 2000)
EndFunc

;~ Run to every outpost in pre
Func OutpostRun()
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)
	
	RndSleep(2000)
	Info('Starting outpost run...')
	TravelWithTimeout($ID_Ashford_Abbey, 'Ashford')
	Sleep(500)
	TravelWithTimeout($ID_Foibles_Fair, 'Foible')
	Sleep(500)
	TravelWithTimeout($ID_Fort_Ranik_Presearing, 'Ranik')
	Sleep(500)
	;TravelWithTimeout($ID_Barradin_Estate, 'Barradin')
EndFunc

;~ Outpost checker
Func TravelWithTimeout($mapID, $onFailFunc)
	Local $startTime = TimerInit()

	RandomDistrictTravel($mapID)
	
	While TimerDiff($startTime) < 15000
		If GetMapID() == $mapID Then
			Info('Travel successful.')
			Return
		EndIf
		Sleep(1000)
	WEnd
	Info('Travel failed.')
	Call($onFailFunc)
EndFunc

;~ Run to Ashford Abbey
Func Ashford()
	; This function is used to run to Ashford Abbey
	Info('Starting run to Ashford Abbey..' )
	Info('Entering Lakeside County!')
	
	RndSleep(GetPing() + 750)
	
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(4555, 1182)
	MoveTo(1894, -3264)
	MoveTo(-2573, -6357)
	MoveTo(-5396, -6940)
	Move(-11100, -6252)

	; If we are dead, we will try again
	If GetIsDead() Then Ashford()

	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
	Info('Made it to Ashford Abbey')
EndFunc

;~ Run to Foibles Fair
Func Foible()
	Info('Starting run to Foibles Fair..' )
	RandomDistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')
		
	RndSleep(GetPing() + 750)
	
	Move(-11300, -6195)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(-11171, -8574)
	MoveTo(-12776, -15329)
	MoveTo(-12745, -16338)
	MoveTo(-11832, -18630)
	MoveTo(-10931, -19169)
	MoveTo(-12742, -19890)
	Info('Entering Wizards Folly!')
	Move(-13880, -20100)
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)
	UseSS($ID_Wizards_Folly)
	MoveTo(8532, 17711)
	MoveTo(7954, 16162)
	MoveTo(4469, 12834)
	MoveTo(2135, 8630)
	MoveTo(1502, 6804)
	MoveTo(457, 7310)
	Move(400, 7700)

	; If we are dead, we will try again
	If GetIsDead() Then Foibles()
	
	WaitMapLoading($ID_Foibles_Fair, 10000, 2000)
	Info('Made it to Foibles Fair')
EndFunc

;~ Run to Fort Ranik
Func Ranik()
	Info('Starting run to Fort Ranik..' )
	RandomDistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')
		
	RndSleep(GetPing() + 750)
	
	Move(-11300, -6195)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(-7084, -6604)
	MoveTo(-6273, -7232)
	MoveTo(-5036, -11749)
	MoveTo(-4122, -12667)
	MoveTo(-623, -15112)
	MoveTo(1222, -16433)
	MoveTo(1996, -18588)
	MoveTo(4010, -19728)
	Info('Entering Regent Valley!')
	Move(5000, -19782)
	WaitMapLoading($ID_Regent_Valley, 10000, 2000)
	UseSS($ID_Regent_Valley)
	MoveTo(-14142, 15133)
	MoveTo(-11645, 14192)
	MoveTo(-7095, 10418)
	MoveTo(-4281, 9187)
	MoveTo(-1670, 7490)
	MoveTo(133, 6428)
	MoveTo(2964, 6071)
	MoveTo(4726, 5436)
	MoveTo(6471, 5315)
	MoveTo(7790, 3655)
	MoveTo(9429, 2774)
	MoveTo(12229, 2543)
	MoveTo(16141, 1263)
	MoveTo(18846, 1482)
	MoveTo(19132, 2047)
	MoveTo(22143, 3527)
	MoveTo(22613, 5474)
	MoveTo(22550, 6748)
	Move(22551, 7300)

	; If we are dead, we will try again
	If GetIsDead() Then Ranik()
	
	WaitMapLoading($ID_Fort_Ranik_Presearing, 10000, 2000)
	Info('Made it to Fort Ranik!')
EndFunc

;~ Run to Barradin Estate
Func Barradin()
	Info('Starting run to The Barradin Estate..' )
	; If we are dead, we will try again
	If GetIsDead() Then Barradin()
EndFunc

;~ Resign and return to Ascalon
Func BackToAscalon()
	Info('Porting to Ascalon')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)
EndFunc

;~ Function to deal with inventory after farm, in presearing
Func PresearingInventoryManagement()
	; Operations order :
	; 1-Sort items
	; 2-Identify items
	; 3-Collect data
	; 4-Salvage
	; 5-Sell materials
	; 6-Sell items
	; 7-Store items
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	If GUICtrlRead($GUI_Checkbox_IdentifyGoldItems) == $GUI_CHECKED And HasUnidentifiedItems() Then
		If GetMapID() <> $ID_Eye_of_the_North Then DistrictTravel($ID_Eye_of_the_North, $DISTRICT_NAME)
		; This function operates in Eye of the North - create one working in presearing
		IdentifyAllItems()
	EndIf
	If GUICtrlRead($GUI_Checkbox_CollectData) == $GUI_CHECKED Then
		ConnectToDatabase()
		InitializeDatabase()
		CompleteModelLookupTable()
		CompleteUpgradeLookupTable()
		StoreAllItemsData()
		DisconnectFromDatabase()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SalvageItems) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
		; This function operates in Eye of the North - create one working in presearing
		; Also, salvage in presearing obeys different rules than salvaging outside presearing, so some things will need to be changed
		SalvageAllItems()
		If $BAG_NUMBER == 5 Then
			If MoveItemsOutOfEquipmentBag() > 0 Then SalvageAllItems()
		EndIf
	EndIf
	If GUICtrlRead($GUI_Checkbox_SellMaterials) == $GUI_CHECKED And HasMaterials() Then
		If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		If HasBasicMaterials() Then SellMaterialsToMerchant()
		If HasRareMaterials() Then SellRareMaterialsToMerchant()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SellItems) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
		If GetGoldCharacter() > 60000 Then BalanceCharacterGold(10000)
		SellEverythingToMerchant()
	EndIf
	If GUICtrlRead($GUI_CheckBox_StoreGold) == $GUI_CHECKED AND GetGoldCharacter() > 60000 And GetGoldStorage() < 100000 Then
		DepositGold(60000)
		Info('Deposited Gold')
		$TIMESDEPOSITED += 1
	EndIf
	If GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED Then StoreEverythingInXunlaiStorage()
EndFunc

;~ Use Igneous Summoning Stone
Func UseSS($m)
	Local $InvSS = FindInInventory($ID_Igneous_Summoning_Stone)
	
	While 1
		If GetMapID() == $m Then
			If $InvSS[0] <> 0 Then
				UseConsumable($ID_Igneous_Summoning_Stone)
				Info('Using Igneous Summoning Stone')
				ExitLoop
			Else
				Info('Igneous Summoning Stone not found in inventory.')
				ExitLoop
			EndIf
		Else
			Sleep(100)
		EndIf
	WEnd
EndFunc