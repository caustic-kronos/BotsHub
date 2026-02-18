#CS ===========================================================================
; Author: Coaxx
; Contributor: caustic-kronos, n1kn4x, Gahais
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
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Storage.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $LDOA_INFORMATIONS = 'This bot:' & @CRLF _
	& '- gets weapons and summoning stone' & @CRLF _
	& '- do a few quests and kill worms outside Ashford until level 2' & @CRLF _
	& '- between level 2 and 9, does the quest Charr at the Gate repeatedly' & @CRLF _
	& '- between level 10 and 19 does the quest Farmer Hamnet which is only available one day of the week' & @CRLF _
	& '- stops once Legendary Defender of Ascalon.'
; Average duration ~ 1m
Global Const $LDOA_FARM_DURATION = 1 * 60 * 1000

; Accepting an finishing 'War Preparation' dialog IDs depend on the profession and are determined dynamically
Global $TEMPLATE_ID_DIALOG_ACCEPT_QUEST = 0x800001
Global $TEMPLATE_ID_DIALOG_FINISH_QUEST = 0x800007
Global Const $ID_DIALOG_SELECT_QUEST_A_MESMERS_BURDEN = 0x804703
Global Const $ID_DIALOG_ACCEPT_QUEST_A_MESMERS_BURDEN = 0x804701
Global Const $ID_DIALOG_ACCEPT_QUEST_CHARR_AT_THE_GATE = 0x802E01
Global Const $ID_DIALOG_ACCEPT_QUEST_FARMER_HAMNET = 0x84A101
Global Const $ID_DIALOG_ACCEPT_QUEST_BANDIT_RAID = 0x802901
Global Const $ID_DIALOG_ACCEPT_QUEST_POOR_TENANT = 0x804601

; Variables used for Survivor async checking (Low Health Monitor)
Global Const $LOW_HEALTH_THRESHOLD = 0.33
Global Const $LOW_HEALTH_CHECK_INTERVAL = 100

Global $ldoa_farm_setup = False

Global $ldoa_fight_options = CloneDictMap($default_moveaggroandkill_options)
$ldoa_fight_options.Item('openChests')			= False
$ldoa_fight_options.Item('callTarget')			= False
$ldoa_fight_options.Item('priorityMobs')		= True
$ldoa_fight_options.Item('lootInFights')		= False

;~ Main method to get LDOA title
Func LDOATitleFarm()
	If Not $ldoa_farm_setup And SetupLDOATitleFarm() == $FAIL Then
		Info('LDOA farm setup failed, stopping farm.')
		Return $PAUSE
	EndIf
	; Difference between this bot and ALL the others : this bot cannot go to Eye of the North or other towns for inventory management
	PresearingInventoryManagement()

	AdlibRegister('LowHealthMonitor', $LOW_HEALTH_CHECK_INTERVAL)
	Local $result = LDOATitleFarmLoop()
	AdlibUnRegister('LowHealthMonitor')
	Return $result
EndFunc


;~ LDOA Title farm setup
Func SetupLDOATitleFarm()
	Info('Setting up farm')
	LeaveParty()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	If $level == 1 Then
		Info('LDOA 1-2')
		InitialSetupLDOA()
	ElseIf $level >= 2 And $level < 10 Then
		Info('LDOA 2-10')
		SetupCharrAtTheGateQuest()
	Else
		Info('LDOA 10-20')
		If SetupHamnetQuest() == $FAIL Then Return $FAIL
		Info('Checking if Foibles Fair is available...')
		If TryTravel($ID_FOIBLES_FAIR) == $FAIL Then RunToFoible()
	EndIf
	Info('Preparations complete')
	$ldoa_farm_setup = True
EndFunc


;~ Initial setup for LDOA title farm if new char, this is done only once
Func InitialSetupLDOA()
	DistrictTravel($ID_ASCALON_CITY_PRESEARING, $district_name)
	If Not IsItemEquippedInWeaponSlot($ID_LUMINESCENT_SCEPTER, 1) Or FindInInventory($ID_IGNEOUS_SUMMONING_STONE)[0] == 0 Then GetBonusWeapons()
	; First Sir Tydus quest to get some skills
	MoveTo(10399, 318)
	MoveTo(11004, 1409)
	Local $questNPC = GetNearestNPCToCoords(11683, 3447)
	; Determine War Preparation and Profession Test quest IDs and dialog IDs depending on the primary profession
	Local $warPreparationsQuestID
	Local $professionTestQuestID
	Local $primaryProfession = DllStructGetData(GetMyAgent(), 'Primary')
	Switch $primaryProfession
		Case $ID_MESMER
			$warPreparationsQuestID = $ID_QUEST_WAR_PREPARATIONS_MESMER
			$professionTestQuestID = $ID_QUEST_MESMER_TEST
		Case $ID_NECROMANCER
			$warPreparationsQuestID = $ID_QUEST_WAR_PREPARATIONS_NECROMANCER
			$professionTestQuestID = $ID_QUEST_NECROMANCER_TEST
		Case $ID_ELEMENTALIST
			$warPreparationsQuestID = $ID_QUEST_WAR_PREPARATIONS_ELEMENTALIST
			$professionTestQuestID = $ID_QUEST_ELEMENTALIST_TEST
		Case $ID_MONK
			$warPreparationsQuestID = $ID_QUEST_WAR_PREPARATIONS_MONK
			$professionTestQuestID = $ID_QUEST_MONK_TEST
		Case $ID_WARRIOR
			$warPreparationsQuestID = $ID_QUEST_WAR_PREPARATIONS_WARRIOR
			$professionTestQuestID = $ID_QUEST_WARRIOR_TEST
		Case $ID_RANGER
			$warPreparationsQuestID = $ID_QUEST_WAR_PREPARATIONS_RANGER
			$professionTestQuestID = $ID_QUEST_RANGER_TEST
	EndSwitch
	Local $warPreparationsAcceptQuestDialogID = BitOR($TEMPLATE_ID_DIALOG_ACCEPT_QUEST, BitShift($warPreparationsQuestID, -8))
	Local $warPreparationsFinishQuestDialogID = BitOR($TEMPLATE_ID_DIALOG_FINISH_QUEST, BitShift($warPreparationsQuestID, -8))
	Local $professionTestAcceptQuestDialogID = BitOR($TEMPLATE_ID_DIALOG_ACCEPT_QUEST, BitShift($professionTestQuestID, -8))
	Local $professionTestFinishQuestDialogID = BitOR($TEMPLATE_ID_DIALOG_FINISH_QUEST, BitShift($professionTestQuestID, -8))
	TakeQuest($questNPC, $warPreparationsQuestID, $warPreparationsAcceptQuestDialogID)

	; Could talk to Baron Egan to get Bandit Raid Quest
	;MoveTo(11000, 10400)
	;$questNPC = GetNearestNPCToCoords(11060, 10775)
	;TakeQuest($questNPC, $ID_QUEST_BANDIT_RAID, $ID_DIALOG_ACCEPT_QUEST_BANDIT_RAID)

	; Could also get Namar quest
	;MoveTo(7607, 5552)
	;MoveTo(6800, 9500)
	;$questNPC = GetNearestNPCToCoords(6760, 9720)
	;TakeQuest($questNPC, $ID_QUEST_POOR_TENANT, $ID_DIALOG_ACCEPT_QUEST_POOR_TENANT)

	MoveTo(7607, 5552)
	Move(7175, 5229)
	WaitMapLoading($ID_LAKESIDE_COUNTY, 10000, 2000)
	MoveTo(6116, 3995)
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	$questNPC = GetNearestNPCToCoords(6187, 4085)

	; This quest never appears as completed because taking the reward is the completion
	; So we send the dialog here manually
	Info('Finishing War Preparations')
	GoToNPC($questNPC)
	Sleep(1000 + GetPing())
	Dialog($warPreparationsFinishQuestDialogID)
	Sleep(1000 + GetPing())
	Info('Done: Finishing War Preparations')

	TakeQuest($questNPC, $professionTestQuestID, $professionTestAcceptQuestDialogID)
	MoveTo(4187, -948)
	MoveAggroAndKillInRange(4207, -2892, '', 3000)
	If $primaryProfession == $ID_MONK Then
		MoveTo(3868, -4330)
		Local $npcGwen = GetNearestNPCToCoords(3868, -4330)
		GoToNPC($npcGwen)
		Sleep(1000 + GetPing())
	EndIf
	MoveTo(3771, -1729)
	MoveTo(6069, 3865)

	; This quest never appears as completed either - last dialog to get reward is the completion
	Info('Finishing Profession Test')
	GoToNPC($questNPC)
	Sleep(1000 + GetPing())
	Dialog($professionTestFinishQuestDialogID)
	Sleep(1000 + GetPing())
	Info('Done: Finishing Profession Test')

	MoveTo(2885, 7638)
	$questNPC = GetNearestNPCToCoords(2885, 7638)
	TakeQuest($questNPC, $ID_QUEST_A_MESMER_S_BURDEN, $ID_DIALOG_ACCEPT_QUEST_A_MESMERS_BURDEN, $ID_DIALOG_SELECT_QUEST_A_MESMERS_BURDEN)

	DistrictTravel($ID_ASCALON_CITY_PRESEARING, $district_name)
	If TryTravel($ID_ASHFORD_ABBEY) == $FAIL Then RunToAshford()
EndFunc


;~ Get weapons for LDOA title farm
Func GetBonusWeapons()
	; Get Igneous summoning stone for low level characters
	SendChat('bonus', '/')
	RandomSleep(750)

	Local $bonusItemsArray = [$ID_BONUS_DRAGON_FANGS, $ID_SPIRIT_BINDER, $ID_NEVERMORE, $ID_TIGER_ROAR, $ID_WOLF_FAVOR, $ID_RHINOS_CHARGE, _
		$ID_SOUL_SHRIEKER, $ID_BONUS_DARKSTEEL_LONGBOW, $ID_BONUS_HOURGLASS_STAFF, $ID_BONUS_GLACIAL_BLADE]
	Local $bonusItemsMap = MapFromArray($bonusItemsArray)
	DestroyFromInventory($bonusItemsMap)
	Local $luminescentScepter = FindInInventory($ID_LUMINESCENT_SCEPTER)
	Local $serratedShield = FindInInventory($ID_SERRATED_SHIELD)
	If $luminescentScepter[0] <> 0 And $serratedShield[0] <> 0 Then
		Info('Equipping Luminescent Scepter and Serrated Shield')
		Local $item = GetItemBySlot($luminescentScepter[0], $luminescentScepter[1])
		EquipItem($item)
		Sleep(250)
		$item = GetItemBySlot($serratedShield[0], $serratedShield[1])
		EquipItem($item)
		Sleep(250)
	Else
		Error('Weapons not found in inventory')
	EndIf
EndFunc


;~ Setup Charr at the gate quest
Func SetupCharrAtTheGateQuest()
	If IsQuestNotFound($ID_QUEST_CHARR_AT_THE_GATE) Or IsQuestReward($ID_QUEST_CHARR_AT_THE_GATE) Then
		Info('Setting up Charr at the gate quest...')
		DistrictTravel($ID_ASCALON_CITY_PRESEARING, $district_name)
		RandomSleep(750)
		AbandonQuest($ID_QUEST_CHARR_AT_THE_GATE)
		RandomSleep(750)
		MoveTo(7974, 6142)
		MoveTo(5668, 10667)
		Local $questNPC = GetNearestNPCToCoords(5668, 10667)
		TakeQuest($questNPC, $ID_QUEST_CHARR_AT_THE_GATE, $ID_DIALOG_ACCEPT_QUEST_CHARR_AT_THE_GATE)
	EndIf
	If IsQuestActive($ID_QUEST_CHARR_AT_THE_GATE) Then
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


;~ Setup Hamnet quest
Func SetupHamnetQuest()
	Info('Setting up Hamnet quest...')

	If IsQuestNotFound($ID_QUEST_VANGUARD_RESCUE_FARMER_HAMNET) Then
		Info('Quest not found, setting up...')
		DistrictTravel($ID_ASCALON_CITY_PRESEARING, $district_name)
		RandomSleep(750)
		MoveTo(9516, 7668)
		MoveTo(9815, 7809)
		MoveTo(10280, 7895)
		MoveTo(10564, 7832)
		Local $questNPC = GetNearestNPCToCoords(10564, 7832)
		TakeQuest($questNPC, $ID_QUEST_VANGUARD_RESCUE_FARMER_HAMNET, $ID_DIALOG_ACCEPT_QUEST_FARMER_HAMNET)
	EndIf
	If IsQuestActive($ID_QUEST_VANGUARD_RESCUE_FARMER_HAMNET) Then
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


;~ LDOA Title farm loop
Func LDOATitleFarmLoop()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	Local $result
	Info('Current level: ' & $level)
	If $level < 1 Then
		Error('Level 0, something went wrong. Waiting a bit and repeating.')
		RandomSleep(3000)
		Return $FAIL
	EndIf
	If $level < 2 Then
		$result = LDOATitleFarmUnder2()
	ElseIf $level < 10 Then
		$result = LDOATitleFarmUnder10()
	ElseIf $level < 20 Then
		$result = LDOATitleFarmAfter10()
	Else
		Info('Reached level 20, LDOA title farm complete.')
		Return $PAUSE
	EndIf
	; If we leveled to 2 or 10, we reset the setup so that the bot starts on the 2-10 or the 10-20 part
	Local $newLevel = DllStructGetData(GetMyAgent(), 'Level')
	If ($level == 1 Or $level == 9) And $newLevel > $level Then $ldoa_farm_setup = False
	Return $result
EndFunc


;~ Kill some worms, level 2 needed for CharrAtGate
Func LDOATitleFarmUnder2()
	Info('Here wormy, wormy!')
	DistrictTravel($ID_ASHFORD_ABBEY, $district_name)
	MoveTo(-11455, -6238)
	Move(-11037, -6240)
	WaitMapLoading($ID_LAKESIDE_COUNTY, 10000, 2000)
	MoveTo(-10433, -6021)
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	Local $wurmies[][] = [ _
		[-9551,	-5499], _
		[-9545, -4205], _
		[-9551, -2929], _
		[-9559, -1324], _
		[-9451, -301] _
	]
	For $i = 0 To UBound($wurmies) - 1
		MoveAggroAndKill($wurmies[$i][0], $wurmies[$i][1])
		If DllStructGetData(GetMyAgent(), 'Level') == 2 Then Return $SUCCESS
		; If not in Lakeside County, we ported because of low life
		If GetMapID() <> $ID_LAKESIDE_COUNTY Then Return $FAIL
		If IsPlayerDead() Then Return $FAIL
	Next
	Return $SUCCESS
EndFunc


;~ Farm to do to level to level 10
Func LDOATitleFarmUnder10()
	SetupCharrAtTheGateQuest()
	DistrictTravel($ID_ASCALON_CITY_PRESEARING, $district_name)
	Info('Entering explorable')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RandomSleep(1000)
	WaitMapLoading($ID_LAKESIDE_COUNTY, 10000, 2000)
	MoveTo(6220, 4470)
	Sleep(3000)
	Info('Going to the gate')
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	MoveTo(3180, 6468)
	MoveTo(360, 6575)
	MoveTo(-3140, 9610)
	Sleep(6000)
	MoveTo(-3640, 10930)
	Sleep(2000)
	MoveTo(-3440, 10010)
	MoveAggroAndKillInRange(-3753, 11131, '', 3000)
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Farm to do to level to level 20
Func LDOATitleFarmAfter10()
	Info('Starting Hamnet farm...')
	Info('Heading to Foibles Fair!')
	DistrictTravel($ID_FOIBLES_FAIR, $district_name)
	MoveTo(356, 7834)
	Info('Entering Wizards Folly!')
	Move(500, 7300)
	WaitMapLoading($ID_WIZARDS_FOLLY, 10000, 2000)
	MoveTo(2200, 6000)
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	MoveTo(2550, 4500)
	KillFoesInArea($ldoa_fight_options)
	If IsPlayerDead() Then Return $FAIL
	Info('Returning to Foibles Fair')
	ResignAndReturnToOutpost($ID_FOIBLES_FAIR)
	Return $SUCCESS
EndFunc


;~ Outpost checker
Func TryTravel($mapID)
	Local $startTime = TimerInit()
	DistrictTravel($mapID, $district_name)
	While TimerDiff($startTime) < 10000
		If GetMapID() == $mapID Then
			Info('Travel successful.')
			Return $SUCCESS
		EndIf
		Sleep(200)
	WEnd
	Info('Travel failed.')
	Return $FAIL
EndFunc


;~ Run to Ashford Abbey
Func RunToAshford()
	; This function is used to run to Ashford Abbey
	Info('Starting run to Ashford Abbey from Ascalon..')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RandomSleep(1000)
	WaitMapLoading($ID_LAKESIDE_COUNTY, 10000, 2000)
	MoveTo(2560, -2331)
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	MoveTo(-1247, -6084)
	MoveTo(-5310, -6951)
	MoveTo(-11026, -6238)
	If IsPlayerDead() Then Return $FAIL
	Move(-11444, -6237)
	WaitMapLoading($ID_ASHFORD_ABBEY, 10000, 2000)
	Info('Made it to Ashford Abbey')
	Return $SUCCESS
EndFunc


;~ Run to Foibles Fair
Func RunToFoible()
	Info('Starting run to Foibles Fair from Ashford Abbey..')
	DistrictTravel($ID_ASHFORD_ABBEY, $district_name)
	Info('Entering Lakeside County!')
	MoveTo(-11455, -6238)
	Move(-11037, -6240)
	WaitMapLoading($ID_LAKESIDE_COUNTY, 10000, 2000)
	MoveTo(-11809, -12198)
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	MoveTo(-12893, -16093)
	MoveTo(-11566, -18712)
	MoveTo(-11246, -19376)
	MoveTo(-13738, -20079)
	If IsPlayerDead() Then Return $FAIL
	Info('Entering Wizards Folly!')
	Move(-14000, -19900)
	WaitMapLoading($ID_WIZARDS_FOLLY, 10000, 2000)
	MoveTo(8648, 17730)
	UseConsumable($ID_IGNEOUS_SUMMONING_STONE, True)
	MoveTo(7497, 15763)
	MoveTo(2840, 10383)
	MoveTo(1648, 7527)
	MoveTo(536, 7315)
	If IsPlayerDead() Then Return $FAIL
	Move(320, 7950)
	WaitMapLoading($ID_FOIBLES_FAIR, 10000, 2000)
	Info('Made it to Foibles Fair')
	Return $SUCCESS
EndFunc


;~ Resign and return to Ascalon
Func BackToAscalon()
	Info('Porting to Ascalon')
	ResignAndReturnToOutpost($ID_FOIBLES_FAIR)
	WaitMapLoading($ID_ASCALON_CITY_PRESEARING, 10000, 1000)
EndFunc


;~ Start/stop background low-health monitor
;~ Return to Ascalon/Foibles if health is dangerously low
Func LowHealthMonitor()
	If IsLowHealth() Then
		Local $level = DllStructGetData(GetMyAgent(), 'Level')
		If $level < 10 Then
			Notice('Health below threshold, returning to Ascalon and restarting the run.')
			DistrictTravel($ID_ASCALON_CITY_PRESEARING, $district_name)
		ElseIf $level < 20 Then
			Notice('Health below threshold, returning to Foibles and restarting the run.')
			DistrictTravel($ID_FOIBLES_FAIR, $district_name)
		EndIf
	EndIf
EndFunc


Func IsLowHealth()
	Local $me = GetMyAgent()
	Local $healthRatio = DllStructGetData($me, 'HealthPercent')
	If $healthRatio > 0 And $healthRatio < $LOW_HEALTH_THRESHOLD Then Return True
	Return False
EndFunc


;~ Function to deal with inventory after farm, in presearing
Func PresearingInventoryManagement()
	If (CountSlots(1, $bags_count) < 0) Then
		; Operations order :
		; 1-Sort items
		; 2-Identify items
		; 3-Salvage -> skipped, charr salvage kits are kind of rare
		; 4-Sell items
		If $run_options_cache['run.sort_items'] Then SortInventory()
		If $inventory_management_cache['@identify.something'] And HasUnidentifiedItems() Then IdentifyItems(False)
		;~ If $inventory_management_cache['@salvage.something'] Then
		;~	SalvageItems(False)
		;~	If $bags_count == 5 And MoveItemsOutOfEquipmentBag() > 0 Then SalvageItems(False)
		;~ EndIf

		; FIXME: add selling
	EndIf
EndFunc