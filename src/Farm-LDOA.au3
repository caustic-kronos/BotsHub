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
	SendChat('/bonus')

	Local $me = GetMyAgent()
	If DllStructGetData(GetMyAgent(), 'Level') < 10 Then
		; Examples present in the Else but feel free to have different stuff here depending on how you make the bot
	ElseIf $OutpostCheck == False Then
		Info('Checking for outposts...')
		OutpostRun()
		$OutpostCheck = True
		; LoadSkillTemplate($mapBuildsPerProfession[GetHeroProfession(0, False)])
		;LoadSkillTemplate($LDOASkillbar)
		; If you need to reload a map quickly after resign do something like that here
		;MoveTo(-22000, 12500)
		;Move(-21750, 14500)
		;RndSleep(1000)
		;WaitMapLoading($ID_Lakeside_County, 10000, 2000)
		;MoveTo(9100, -19600)
		;Move(9100, -20500)
		;RndSleep(1000)
		;WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)
	EndIf
	Info('Preparations complete')
EndFunc


;~ LDOA Title farm loop
Func LDOATitleFarmLoop($STATUS)
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	Info('Current level: ' & $level)

	If DllStructGetData(GetMyAgent(), 'Level') < 11 Then
		Info('LDOA 2-10')
		LDOATitleFarmUnder10()
	Else
		Info('LDOA 11-20')
		LDOATitleFarmAfter10()
	EndIf
	; If we level to 11, we reset the setup so that the bot starts on the 11-20 part
	Local $newLevel = DllStructGetData(GetMyAgent(), 'Level')
	If $level == 10 And $newLevel > $level Then $LDOA_FARM_SETUP = False
EndFunc


Func SetupCharrAtTheGateQuest()
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	Info('Setting up Charr at the gate quest...')

	RndSleep(GetPing() + 750)
	AbandonQuest(0x2E)
	RndSleep(GetPing() + 750)
	MoveTo(7974, 6142)
	MoveTo(5668, 10667)
	GoToNPC(GetNearestNPCToCoords(5668, 10667))
	RndSleep(GetPing() + 750)
	Dialog(0x802E01)
	RndSleep(GetPing() + 750)
EndFunc

;~ Farm to do to level to level 10
Func LDOATitleFarmUnder10()
	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_CharrAtTheGate), 'Logstate')
	Local $me = GetMyAgent()
	
	If $questStatus == 0 Then
		Info('**Quest not found**')
		SetupCharrAtTheGateQuest()
	ElseIf $questStatus == 1 Then
		Info('Good to go!')
	ElseIf $questStatus == 3 Then
		Info('Resetting the quest...')
		SetupCharrAtTheGateQuest()
	EndIf

	; If we have the quest, we can start the farm
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

	While CountFoesInRangeOfAgent($me, 2000) == 1 Then
		BackToAscalon()
		Return 0
	WEnd
	
	Return 0
EndFunc


;~ Farm to do to level to level 20
Func LDOATitleFarmAfter10()
	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_FarmerHamnet), 'Logstate')

	;~ Get quest if we dont have it
	If $questStatus == 0 Then
		Info('Quest not found, setting up...')
		SetupHamnetQuest()
	
	;~ If we have the quest, we can start the farm
	ElseIf $questStatus == 1 Then
		Info('Quest found, Good to go!')
	EndIf

	Hamnet()

	Return 0
EndFunc


;~ Run to every outpost in pre
Func OutpostRun()
	BackToAscalon()
	RndSleep(2000)
	Info('Starting outpost run...')
	Info('...peeling bananas...')
	TravelWithTimeout($ID_Ashford_Abbey, 'Ashford')
	TravelWithTimeout($ID_Foibles_Fair, 'Foible')
	TravelWithTimeout($ID_Fort_Ranik_Presearing, 'Ranik')
	TravelWithTimeout($ID_Barradin_Estate, 'Barradin')
EndFunc


;~ Setup Hamnet quest
Func SetupHamnetQuest()
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	Info('Setting up Hamnet quest...')

	RndSleep(GetPing() + 750)
	MoveTo(9516, 7668)
	MoveTo(9815, 7809)
	MoveTo(10280, 7895)
	MoveTo(10564, 7832)
	GoToNPC(GetNearestNPCToCoords(10564, 7832))
	RndSleep(GetPing() + 750)

EndFunc

;~ Farmer Hamnet farm
Func Hamnet()
	Info('Starting Hamnet farm...')
	Info('Heading to Foibles Fair!')
	RandomDistrictTravel($ID_Foibles_Fair)

	RndSleep(GetPing() + 750)

	MoveTo(-183, 9002)
	MoveTo(356, 7834)
	Info('Entering Wizards Folly!')
	Move(390, 7800)
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)

	UseConsumable($ID_Igneous_Summoning_Stone)
	Info('Using Igneous Summoning Stone')

	MoveAggroAndKill(2750, 4050, '', 1000, Null)

EndFunc


;~ Outpost checker
Func TravelWithTimeout($mapID, $onFailFunc)
	Local $startTime = TimerInit()

	RandomDistrictTravel($mapID)
	
	While TimerDiff($startTime) < 10000
		If GetMapID() == $mapID Then
			Info('Travel successful.')
			Return
		EndIf
		Sleep(1000)
	WEnd
	Info('Travel failed.')
	Call($onFailFunc)
EndFunc

;~ I like bananas
Func Ashford()
	; This function is used to run to Ashford Abbey
	Info('Starting run to Ashford Abbey..' )
	Info('Entering Lakeside County!')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(4555, 1182, 30)
	MoveTo(1894, -3264, 30)
	MoveTo(-2573, -6357, 30)
	MoveTo(-5396, -6940, 30)
	Move(-11100, -6252)
	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
	Info('Made it to Ashford Abbey')

	; If we are dead, we will try again
	If GetIsDead() Then Ashford()
EndFunc

;~ I like watermelon
Func Foible()
	; This function is used to run to Foibles Fair
	Info('Starting run to Foibles Fair..' )
	Info('Entering Lakeside County!')
	Move(-11300, -6195, 30)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(-11171, -8574, 30)
	MoveTo(-12776, -15329, 30)
	MoveTo(-12745, -16338, 30)
	MoveTo(-11832, -18630, 30)
	MoveTo(-10931, -19169, 30)
	MoveTo(-12742, -19890, 30)
	Info('Entering Wizards Folly!')
	Move(-13800, -20047)
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)
	MoveTo(8532, 17711, 30)
	MoveTo(7954, 16162, 30)
	MoveTo(4469, 12834, 30)
	MoveTo(2135, 8630, 30)
	MoveTo(1502, 6804, 30)
	MoveTo(457, 7310, 30)
	Move(400, 7700)
	WaitMapLoading($ID_Foibles_Fair, 10000, 2000)
	Info('Made it to Foibles Fair')

	; If we are dead, we will try again
	If GetIsDead() Then Foibles()
EndFunc

Func Ranik()
	; This function is used to run to Fort Ranik
	Info('Starting run to Fort Ranik..' )
	RandomDistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')
	Move(-11300, -6195, 30)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(-7084, -6604, 30)
	MoveTo(-6273, -7232, 30)
	MoveTo(-5036, -11749, 30)
	MoveTo(-4122, -12667, 30)
	MoveTo(-623, -15112, 30)
	MoveTo(1222, -16433, 30)
	MoveTo(1996, -18588, 30)
	MoveTo(4010, -19728, 30)
	Info('Entering Regent Valley!')
	Move(5000, -19782, 30)
	WaitMapLoading($ID_Regent_Valley, 10000, 2000)
	MoveTo(-14142, 15133, 30)
	MoveTo(-11645, 14192, 30)
	MoveTo(-7095, 10418, 30)
	MoveTo(-4281, 9187, 30)
	MoveTo(-1670, 7490, 30)
	MoveTo(133, 6428, 30)
	MoveTo(2964, 6071, 30)
	MoveTo(4726, 5436, 30)
	MoveTo(6471, 5315, 30)
	MoveTo(7790, 3655, 30)
	MoveTo(9429, 2774, 30)
	MoveTo(12229, 2543, 30)
	MoveTo(16141, 1263, 30)
	MoveTo(18846, 1482, 30)
	MoveTo(19132, 2047, 30)
	MoveTo(22143, 3527, 30)
	MoveTo(22613, 5474, 30)
	MoveTo(22550, 6748, 30)
	Move(22551, 7300)
	WaitMapLoading($ID_Fort_Ranik_Presearing, 10000, 2000)
	Info('Made it to Fort Ranik!')

	; If we are dead, we will try again
	If GetIsDead() Then Ranik()
EndFunc

Func Barradin()
	; This function is used to run to The Barradin Estate
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