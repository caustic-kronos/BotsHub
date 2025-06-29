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

Global $LDOA_FARM_SETUP = False

;~ Main method to get LDOA title
Func LDOATitleFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	If Not $LDOA_FARM_SETUP Then
		SetupLDOATitleFarm()
		$LDOA_FARM_SETUP = True
	EndIf
	; Difference between this bot and ALL the others : this bot can't go to Eye of the North for inventory management
	; This means that inventory management will have to be "duplicated" here in this bot
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

	Local $me = GetMyAgent()
	If DllStructGetData(GetMyAgent(), 'Level') < 10 Then
		; Examples present in the Else but feel free to have different stuff here depending on how you make the bot
	Else
		; LoadSkillTemplate($mapBuildsPerProfession[GetHeroProfession(0, False)])
		LoadSkillTemplate($LDOASkillbar)
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

	If DllStructGetData(GetMyAgent(), 'Level') < 10 Then
		LDOATitleFarmUnder10()
	Else
		LDOATitleFarmAfter10()
	EndIf
	Local $newLevel = DllStructGetData(GetMyAgent(), 'Level')
	; If we level to 10, we reset the setup so that the bot starts on the 10-20 part
	If $level == 9 And $newLevel > $level Then $LDOA_FARM_SETUP = False
EndFunc


;~ Farm to do to level to level 10
Func LDOATitleFarmUnder10()
	Info('Entering explorable')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)

	;TODO

	If GetIsDead() Then
		BackToAscalon()
		Return 1
	EndIf

	Info('Looting')
	PickUpItems()

	BackToAscalon()
	Return 0
EndFunc


;~ Farm to do to level to level 20
Func LDOATitleFarmAfter10()
	Info('Entering explorable')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RndSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)

	;TODO

	If GetIsDead() Then
		BackToAscalon()
		Return 1
	EndIf

	Info('Looting')
	PickUpItems()

	BackToAscalon()
	Return 0
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