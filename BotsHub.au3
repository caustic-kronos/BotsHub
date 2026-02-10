#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
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

; TODO :
; - after salvage, get material ID and write in file salvaged material
; - add true locking mechanism to prevent trying to run several bots on the same account at the same time

; Night tips and tricks
; - Always refresh agents before getting data from them (agent = snapshot)
;		(so only use $me if you are sure nothing important changes between $me definition and $me usage)
; - AdlibRegister('NotifyHangingBot', 120000) can be used to simulate multithreading
#CE ===========================================================================

#RequireAdmin
#NoTrayIcon

#Region Includes
#include <Math.au3>
#include 'lib/GWA2_Headers.au3'
#include 'lib/GWA2_ID.au3'
#include 'lib/GWA2.au3'
#include 'lib/GWA2_Assembly.au3'
#include 'lib/Utils.au3'
#include 'lib/Utils-Agents.au3'
#include 'lib/Utils-Storage.au3'
#include 'lib/Utils-Debugger.au3'
#include 'lib/BotsHub-GUI.au3'

#include 'src/farms/CoF.au3'
#include 'src/farms/Corsairs.au3'
#include 'src/farms/DragonMoss.au3'
#include 'src/farms/EdenIris.au3'
#include 'src/farms/Feathers.au3'
#include 'src/farms/FoWTowerOfCourage.au3'
#include 'src/farms/Gemstones.au3'
#include 'src/farms/GemstoneMargonite.au3'
#include 'src/farms/GemstoneStygian.au3'
#include 'src/farms/GemstoneTorment.au3'
#include 'src/farms/JadeBrotherhood.au3'
#include 'src/farms/Lightbringer-Sunspear.au3'
#include 'src/farms/Lightbringer.au3'
#include 'src/farms/Mantids.au3'
#include 'src/farms/Kournans.au3'
#include 'src/farms/Minotaurs.au3'
#include 'src/farms/Raptors.au3'
#include 'src/farms/SpiritSlaves.au3'
#include 'src/farms/Vaettirs.au3'
#include 'src/missions/Deldrimor.au3'
#include 'src/missions/FoW.au3'
#include 'src/missions/Froggy.au3'
#include 'src/missions/GlintChallenge.au3'
#include 'src/missions/MinisterialCommendations.au3'
#include 'src/missions/NexusChallenge.au3'
#include 'src/missions/SoO.au3'
#include 'src/missions/SunspearArmor.au3'
#include 'src/missions/Underworld.au3'
#include 'src/missions/Voltaic.au3'
#include 'src/missions/WarSupplyKeiran.au3'
#include 'src/runs/Boreal.au3'
#include 'src/runs/Pongmei.au3'
#include 'src/runs/Tasca.au3'
#include 'src/titles/LDOA.au3'
#include 'src/utilities/Follower.au3'
#include 'src/utilities/OmniFarmer.au3'
#include 'src/utilities/TestSuite.au3'
#include 'src/vanquishes/Asuran.au3'
#include 'src/vanquishes/Kurzick.au3'
#include 'src/vanquishes/Kurzick2.au3'
#include 'src/vanquishes/Luxon.au3'
#include 'src/vanquishes/Norn.au3'
#include 'src/vanquishes/Vanguard.au3'
#EndRegion Includes

#Region Variables
Global Const $GW_BOT_HUB_VERSION = '2.0'

; -1 = did not start, 0 = ran fine, 1 = failed, 2 = pause
Global Const $NOT_STARTED = -1
Global Const $SUCCESS = 0
Global Const $FAIL = 1
Global Const $PAUSE = 2

Global Const $AVAILABLE_FARMS = '|Asuran|Boreal|CoF|Corsairs|Deldrimor|Dragon Moss|Eden Iris|Feathers|Follower|FoW|FoW Tower of Courage|Froggy|Gemstones|Gemstone Margonite|Gemstone Stygian|Gemstone Torment|' & _
	'Glint Challenge|Jade Brotherhood|Kournans|Kurzick|Kurzick Drazach|Lightbringer & Sunspear|Lightbringer|LDOA|Luxon|Mantids|Ministerial Commendations|Minotaurs|Nexus Challenge|Norn|OmniFarm|Pongmei|' & _
	'Raptors|SoO|SpiritSlaves|Sunspear Armor|Tasca|Underworld|Vaettirs|Vanguard|Voltaic|War Supply Keiran|Storage|Tests|TestSuite|Dynamic execution'

Global Const $AVAILABLE_DISTRICTS = '|Random|Random EU|Random US|Random Asia|America|China|English|French|German|International|Italian|Japan|Korea|Polish|Russian|Spanish'

Global Const $AVAILABLE_HEROES = '||Acolyte Jin|Acolyte Sousuke|Anton|Dunkoro|General Morgahn|Goren|Gwen|Hayda|Jora|Kahmu|Keiran Thackeray|Koss|Livia|' & _
	'Margrid the Sly|Master of Whispers|Melonni|Miku|MOX|Norgu|Ogden|Olias|Pyre Fierceshot|Razah|Tahlkora|Vekk|Xandra|ZeiRi|Zenmai|Zhed Shadowhoof|' & _
	'Mercenary Hero 1|Mercenary Hero 2|Mercenary Hero 3|Mercenary Hero 4|Mercenary Hero 5|Mercenary Hero 6|Mercenary Hero 7|Mercenary Hero 8||'

; UNINITIALIZED -> INITIALIZED -> RUNNING -> WILL_PAUSE -> PAUSED -> RUNNING
Global $runtime_status = 'UNINITIALIZED'
Global $run_mode = 'GUI'
Global $process_id = ''
Global $character_name = ''
Global $farm_name = ''
Global $run_configuration = 'Default Farm Configuration'
Global $loot_configuration = 'Default Loot Configuration'
; If set to 0, disables inventory management
Global $inventory_space_needed = 5
Global $run_timer = Null
Global $global_farm_setup = False
Global $log_level = $LVL_INFO

; Farm Name;Farm function;Inventory space;Farm duration
Global $farm_map[]

Global $inventory_management_cache[]
Global $run_options_cache[]
$run_options_cache['run.district'] = 'Random EU'
$run_options_cache['run.consume_consumables'] = True
$run_options_cache['run.use_scrolls'] = False
$run_options_cache['run.sort_items'] = False
$run_options_cache['run.farm_materials_mid_run'] = False
$run_options_cache['run.bags_count'] = 5
$run_options_cache['run.donate_faction_points'] = True
$run_options_cache['run.buy_faction_scrolls'] = False
$run_options_cache['run.buy_faction_resources'] = False
$run_options_cache['run.collect_data'] = False
$run_options_cache['team.automatic_team_setup'] = False
; Overrides on $run_options_cache for frequent usage
Global $district_name = 'Random EU'
Global $bags_count = 5
#EndRegion Variables


#Region Main loops
Main()

;------------------------------------------------------
; Title...........:	Main
; Description.....:	run the main program
;------------------------------------------------------
Func Main()
	; Verify validity
	If @AutoItVersion < '3.3.16.0' Then
		MsgBox(16, 'Error', 'This bot requires AutoIt version 3.3.16.0 or higher. You are using ' & @AutoItVersion & '.')
		Exit 1
	EndIf
	If @AutoItX64 Then
		MsgBox(16, 'Error!', 'Please run all bots in 32-bit (x86) mode.')
		Exit 1
	EndIf

	If $CmdLine[0] <> 0 Then $run_mode = 'HEADLESS'

	; GUI free steps
	FillFarmMap()
	LoadDefaultRunConfiguration()
	LoadDefaultLootConfiguration()

	If $run_mode == 'GUI' Then
		CreateGUI()
		ApplyConfigToGUI()
		FillConfigurationCombo()
		GUISetState(@SW_SHOWNORMAL)
		Info('GW Bot Hub ' & $GW_BOT_HUB_VERSION)
		; Authentication
		ScanAndUpdateGameClients()
		RefreshCharactersComboBox()
	ElseIf $run_mode == 'HEADLESS' Then
		; Need minimum 3 things to run a bot: process ID, character name and farm name
		If $CmdLine[0] < 3 Then
			MsgBox(0, 'Error', 'The Hub needs 0 or at least 3 arguments.')
			Exit
		EndIf
		$process_id = $CmdLine[1]
		$character_name = $CmdLine[2]
		$farm_name = $CmdLine[3]

		Info('Running in CMD mode with process ID: ' & $process_id & ' character name: ' & $character_name & ' farm name: ' & $farm_name)

		Local $openProcess = SafeDllCall9($kernel_handle, 'int', 'OpenProcess', 'int', 0x1F0FFF, 'int', 1, 'int', $process_id)
		Local $processHandle = IsArray($openProcess) ? $openProcess[0] : 0
		If $processHandle <> 0 Then
			Local $windowHandle = GetWindowHandleForProcess($process_id)
			AddClient($process_id, $processHandle, $windowHandle, $character_name)
			SelectClient(1)
		Else
			MsgBox(0, 'Error', 'GW Process with incorrect handle.')
			Exit
		EndIf
		; Authentication
		Authentification($character_name)
		$runtime_status = 'RUNNING'
	Else
		MsgBox(0, 'Error', 'Unknown run mode: ' & $run_mode)
		Exit
	EndIf

	; Infinite loop
	BotHubLoop()
EndFunc


;~ Main loop of the program
Func BotHubLoop()
	While True
		If ($runtime_status == 'RUNNING') Then
			If $run_mode == 'GUI' Then
				DisableGUIComboboxes()
				$farm_name = GUICtrlRead($gui_combo_farmchoice)
				If $farm_name == Null Or $farm_name == '' Then
					Error('This farm does not exist.')
					$runtime_status = 'INITIALIZED'
					EnableStartButton()
					Return $PAUSE
				EndIf
			EndIf
			Local $result = RunFarmLoop()
			If ($result == $PAUSE Or $run_options_cache['run.loop_mode'] == False) Then $runtime_status = 'WILL_PAUSE'
		EndIf

		If ($runtime_status == 'WILL_PAUSE') Then
			Warn('Paused.')
			$runtime_status = 'PAUSED'
			If $run_mode == 'GUI' Then
				EnableStartButton()
				EnableGUIComboboxes()
			EndIf
		EndIf
		Sleep(1000)
	WEnd
EndFunc


;~ Main loop to run farms
Func RunFarmLoop()
	; Farm Name;Farm function;Inventory space;Farm duration
	Local $farm = $farm_map[$farm_name]
	Local $inventorySpaceNeeded = $farm[2]

	; No authentication: skip global farm setup and inventory management
	If $character_name <> '' Then
		; Must do mid-run inventory management before normal one else we will go back to town
		If $inventorySpaceNeeded <> 0 And $run_options_cache['run.farm_materials_mid_run'] Then
			Local $resetRequired = InventoryManagementMidRun()
			If $resetRequired Then ResetBotsSetups()
		EndIf

		; During pickup, items will be moved to equipment bag (if used) when first 3 bags are full
		; So bag 5 will always fill before 4 - hence we can count items up to bag 4
		If (CountSlots(1, _Min($bags_count, 4)) < $inventorySpaceNeeded) Then
			InventoryManagementBeforeRun()
		EndIf
		; Inventory management did not clean up inventory - we pause
		If (CountSlots(1, $bags_count) < $inventorySpaceNeeded) Then
			Notice('Inventory full, pausing.')
			ResetBotsSetups()
			$runtime_status = 'WILL_PAUSE'
		EndIf

		; Global farm setup
		If Not $global_farm_setup Then GeneralFarmSetup()
	EndIf

	; Dealing with unexisting farms
	If $farm == Null Or $farm[1] == Null Then
		MsgBox(0, 'Error', 'This farm does not exist.')
		$runtime_status = 'INITIALIZED'
		EnableStartButton()
		Return $PAUSE
	EndIf

	; Running chosen farm
	Local $result = $NOT_STARTED
	$run_timer = TimerInit()
	Local $farmFunction = $farm[1]
	If $run_mode == 'HEADLESS' Then
		$result = $farmFunction()
	ElseIf $run_mode == 'GUI' Then
		Local $timePerRun = UpdateStats($NOT_STARTED)
		UpdateProgressBar($timePerRun == 0 ? $farm[3] : $timePerRun)
		AdlibRegister('UpdateProgressBar', 5000)
		$result = $farmFunction()
		AdlibUnRegister('UpdateProgressBar')
		CompleteGUIFarmProgress()
		Local $elapsedTime = TimerDiff($run_timer)
		Info('Run ' & ($result == $SUCCESS ? 'successful' : 'failed') & ' after: ' & ConvertTimeToMinutesString($elapsedTime))
		UpdateStats($result, $elapsedTime)
	EndIf
	ClearMemory(GetProcessHandle())
	; _PurgeHook()
	Return $result
EndFunc
#EndRegion Main loops


#Region Load/Save configuration
;~ Load default farm configuration if it exists
Func LoadDefaultRunConfiguration()
	Local $filePath = @ScriptDir & '/conf/farm/' & $run_configuration & '.json'
	If FileExists($filePath) Then
		LoadRunConfiguration($filePath)
	Else
		Error('No default run configuration at ' & $filePath)
	EndIf
EndFunc


;~ Change to a different configuration
Func LoadRunConfiguration($filePath)
	Local $configFile = FileOpen($filePath , $FO_READ + $FO_UTF8)
	Local $jsonString = FileRead($configFile)
	ReadConfigFromJson($jsonString)
	FileClose($configFile)
	Info('Loaded run configuration at ' & $filePath)
EndFunc


;~ Save a new configuration
Func SaveRunConfiguration($filePath)
	Local $configFile = FileOpen($filePath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	Local $jsonString = WriteConfigToJson()
	FileWrite($configFile, $jsonString)
	FileClose($configFile)
	Local $configurationName = StringTrimRight(StringMid($filePath, StringInStr($filePath, '\', 0, -1) + 1), 5)
	Info('Saved run configuration at ' & $filePath)
	Return $configurationName
EndFunc


;~ Load default loot configuration if it exists
Func LoadDefaultLootConfiguration()
	Local $filePath = @ScriptDir & '/conf/loot/' & $loot_configuration & '.json'
	If FileExists($filePath) Then
		LoadLootConfiguration($filePath)
	Else
		Error('No default loot configuration at ' & $filePath)
	EndIf
EndFunc


;~ Load loot configuration file if it exists
Func LoadLootConfiguration($filePath)
	$loot_configuration = $filePath
	$loot_configuration = StringTrimRight($loot_configuration, StringLen(@ScriptDir & '/conf/loot/'))
	; Removing .json
	$loot_configuration = StringTrimLeft($loot_configuration, 5)
	Local $jsonLootOptions = LoadLootOptions($filePath)
	FillInventoryCacheFromJSON($jsonLootOptions, '')
	BuildInventoryDerivedFlags()
	RefreshValuableListsFromCache()
	Info('Loaded loot configuration at ' & $filePath)
EndFunc


;~ Load loot configuration file if it exists
Func LoadLootOptions($filePath)
	If FileExists($filePath) Then
		Local $lootOptionsFile = FileOpen($filePath, $FO_READ + $FO_UTF8)
		Local $jsonString = FileRead($lootOptionsFile)
		FileClose($lootOptionsFile)
		Return _JSON_Parse($jsonString)
	EndIf
	Return Null
EndFunc


;~ Read given config from JSON
Func ReadConfigFromJson($jsonString)
	Local $jsonObject = _JSON_Parse($jsonString)

	$character_name = _JSON_Get($jsonObject, 'main.character')
	$farm_name = _JSON_Get($jsonObject, 'main.farm')
	Local $lootConfig = _JSON_Get($jsonObject, 'main.loot_configuration')
	If $lootConfig <> Null And $lootConfig <> '' Then $loot_configuration = $lootConfig

	Local $weaponSlot = _JSON_Get($jsonObject, 'run.weapon_slot')
	$weaponSlot = _Max($weaponSlot, 0)
	$weaponSlot = _Min($weaponSlot, 4)
	$run_options_cache['run.weapon_slot'] = $weaponSlot

	$bags_count = _JSON_Get($jsonObject, 'run.bags_count')
	$bags_count = _Max($bags_count, 1)
	$bags_count = _Min($bags_count, 5)
	$run_options_cache['run.bags_count'] = $bags_count

	$district_name = _JSON_Get($jsonObject, 'run.district')
	$run_options_cache['run.district'] = $district_name

	Local $renderingDisabled = _JSON_Get($jsonObject, 'run.disable_rendering')
	$rendering_enabled = Not $renderingDisabled

	; TODO/FIXME: simplify by iterating over JSON leaves
	$run_options_cache['run.loop_mode'] = _JSON_Get($jsonObject, 'run.loop_mode')
	$run_options_cache['run.hard_mode'] = _JSON_Get($jsonObject, 'run.hard_mode')
	$run_options_cache['run.farm_materials_mid_run'] = _JSON_Get($jsonObject, 'run.farm_materials_mid_run')
	$run_options_cache['run.consume_consumables'] = _JSON_Get($jsonObject, 'run.consume_consumables')
	$run_options_cache['run.use_scrolls'] = _JSON_Get($jsonObject, 'run.use_scrolls')
	$run_options_cache['run.sort_items'] = _JSON_Get($jsonObject, 'run.sort_items')
	$run_options_cache['run.sort_items'] = _JSON_Get($jsonObject, 'run.sort_items')
	$run_options_cache['run.collect_data'] = _JSON_Get($jsonObject, 'run.collect_data')
	$run_options_cache['run.donate_faction_points'] = _JSON_Get($jsonObject, 'run.donate_faction_points')
	$run_options_cache['run.buy_faction_resources'] = _JSON_Get($jsonObject, 'run.buy_faction_resources')
	$run_options_cache['run.buy_faction_scrolls'] = _JSON_Get($jsonObject, 'run.buy_faction_scrolls')

	$run_options_cache['team.automatic_team_setup'] = _JSON_Get($jsonObject, 'team.automatic_team_setup')
	$run_options_cache['team.hero_1'] = _JSON_Get($jsonObject, 'team.hero_1')
	$run_options_cache['team.hero_2'] = _JSON_Get($jsonObject, 'team.hero_2')
	$run_options_cache['team.hero_3'] = _JSON_Get($jsonObject, 'team.hero_3')
	$run_options_cache['team.hero_4'] = _JSON_Get($jsonObject, 'team.hero_4')
	$run_options_cache['team.hero_5'] = _JSON_Get($jsonObject, 'team.hero_5')
	$run_options_cache['team.hero_6'] = _JSON_Get($jsonObject, 'team.hero_6')
	$run_options_cache['team.hero_7'] = _JSON_Get($jsonObject, 'team.hero_7')
	$run_options_cache['team.load_all_builds'] = _JSON_Get($jsonObject, 'team.load_all_builds')
	$run_options_cache['team.load_player_build'] = _JSON_Get($jsonObject, 'team.load_player_build')
	$run_options_cache['team.load_hero_1_build'] = _JSON_Get($jsonObject, 'team.load_hero_1_build')
	$run_options_cache['team.load_hero_2_build'] = _JSON_Get($jsonObject, 'team.load_hero_2_build')
	$run_options_cache['team.load_hero_3_build'] = _JSON_Get($jsonObject, 'team.load_hero_3_build')
	$run_options_cache['team.load_hero_4_build'] = _JSON_Get($jsonObject, 'team.load_hero_4_build')
	$run_options_cache['team.load_hero_5_build'] = _JSON_Get($jsonObject, 'team.load_hero_5_build')
	$run_options_cache['team.load_hero_6_build'] = _JSON_Get($jsonObject, 'team.load_hero_6_build')
	$run_options_cache['team.load_hero_7_build'] = _JSON_Get($jsonObject, 'team.load_hero_7_build')
	$run_options_cache['team.player_build'] = _JSON_Get($jsonObject, 'team.player_build')
	$run_options_cache['team.hero_1_build'] = _JSON_Get($jsonObject, 'team.hero_1_build')
	$run_options_cache['team.hero_2_build'] = _JSON_Get($jsonObject, 'team.hero_2_build')
	$run_options_cache['team.hero_3_build'] = _JSON_Get($jsonObject, 'team.hero_3_build')
	$run_options_cache['team.hero_4_build'] = _JSON_Get($jsonObject, 'team.hero_4_build')
	$run_options_cache['team.hero_5_build'] = _JSON_Get($jsonObject, 'team.hero_5_build')
	$run_options_cache['team.hero_6_build'] = _JSON_Get($jsonObject, 'team.hero_6_build')
	$run_options_cache['team.hero_7_build'] = _JSON_Get($jsonObject, 'team.hero_7_build')
EndFunc


;~ Writes current config to a json string
Func WriteConfigToJson()
	Local $jsonObject
	; TODO/FIXME: simplify by iterating over map keys
	_JSON_addChangeDelete($jsonObject, 'main.character', $character_name)
	_JSON_addChangeDelete($jsonObject, 'main.farm', $farm_name)
	_JSON_addChangeDelete($jsonObject, 'run.loop_mode', $run_options_cache['run.loop_mode'])
	_JSON_addChangeDelete($jsonObject, 'run.hard_mode', $run_options_cache['run.hard_mode'])
	_JSON_addChangeDelete($jsonObject, 'run.farm_materials_mid_run', $run_options_cache['run.farm_materials_mid_run'])
	_JSON_addChangeDelete($jsonObject, 'run.consume_consumables', $run_options_cache['run.consume_consumables'])
	_JSON_addChangeDelete($jsonObject, 'run.use_scrolls', $run_options_cache['run.use_scrolls'])
	_JSON_addChangeDelete($jsonObject, 'run.sort_items', $run_options_cache['run.sort_items'])
	_JSON_addChangeDelete($jsonObject, 'run.collect_data', $run_options_cache['run.collect_data'])
	_JSON_addChangeDelete($jsonObject, 'run.donate_faction_points', $run_options_cache['run.donate_faction_points'])
	_JSON_addChangeDelete($jsonObject, 'run.buy_faction_resources', $run_options_cache['run.buy_faction_resources'])
	_JSON_addChangeDelete($jsonObject, 'run.buy_faction_scrolls', $run_options_cache['run.buy_faction_scrolls'])
	_JSON_addChangeDelete($jsonObject, 'run.weapon_slot', $run_options_cache['run.weapon_slot'])
	_JSON_addChangeDelete($jsonObject, 'run.bags_count', $run_options_cache['run.bags_count'])
	_JSON_addChangeDelete($jsonObject, 'run.district', $run_options_cache['run.district'])
	_JSON_addChangeDelete($jsonObject, 'run.disable_rendering', Not $rendering_enabled)

	_JSON_addChangeDelete($jsonObject, 'team.automatic_team_setup', $run_options_cache['team.automatic_team_setup'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_1', $run_options_cache['team.hero_1'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_2', $run_options_cache['team.hero_2'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_3', $run_options_cache['team.hero_3'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_4', $run_options_cache['team.hero_4'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_5', $run_options_cache['team.hero_5'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_6', $run_options_cache['team.hero_6'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_7', $run_options_cache['team.hero_7'])
	_JSON_addChangeDelete($jsonObject, 'team.load_all_builds', $run_options_cache['team.load_all_builds'])
	_JSON_addChangeDelete($jsonObject, 'team.load_player_build', $run_options_cache['team.load_player_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_1_build', $run_options_cache['team.load_hero_1_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_2_build', $run_options_cache['team.load_hero_2_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_3_build', $run_options_cache['team.load_hero_3_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_4_build', $run_options_cache['team.load_hero_4_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_5_build', $run_options_cache['team.load_hero_5_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_6_build', $run_options_cache['team.load_hero_6_build'])
	_JSON_addChangeDelete($jsonObject, 'team.load_hero_7_build', $run_options_cache['team.load_hero_7_build'])
	_JSON_addChangeDelete($jsonObject, 'team.player_build', $run_options_cache['team.player_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_1_build', $run_options_cache['team.hero_1_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_2_build', $run_options_cache['team.hero_2_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_3_build', $run_options_cache['team.hero_3_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_4_build', $run_options_cache['team.hero_4_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_5_build', $run_options_cache['team.hero_5_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_6_build', $run_options_cache['team.hero_6_build'])
	_JSON_addChangeDelete($jsonObject, 'team.hero_7_build', $run_options_cache['team.hero_7_build'])

	Return _JSON_Generate($jsonObject)
EndFunc
#EndRegion Load/Save configuration


#Region Setup
;~ Fill the map of farms with the farms and their details
Func FillFarmMap()
	;					Farm Name						Farm function					Inventory space		Farm duration
	AddFarmToFarmMap(	'Asuran',						AsuranTitleFarm,				5,					$ASURAN_FARM_DURATION)
	AddFarmToFarmMap(	'Boreal',						BorealChestFarm,				5,					$BOREAL_FARM_DURATION)
	AddFarmToFarmMap(	'CoF',							CoFFarm,						5,					$COF_FARM_DURATION)
	AddFarmToFarmMap(	'Corsairs',						CorsairsFarm,					5,					$CORSAIRS_FARM_DURATION)
	AddFarmToFarmMap(	'Deldrimor',					DeldrimorFarm,					10,					$DELDRIMOR_FARM_DURATION)
	AddFarmToFarmMap(	'Dragon Moss',					DragonMossFarm,					5,					$DRAGONMOSS_FARM_DURATION)
	AddFarmToFarmMap(	'Eden Iris',					EdenIrisFarm,					2,					$IRIS_FARM_DURATION)
	AddFarmToFarmMap(	'Feathers',						FeathersFarm,					10,					$FEATHERS_FARM_DURATION)
	AddFarmToFarmMap(	'Follower',						FollowerFarm,					5,					30 * 60 * 1000)
	AddFarmToFarmMap(	'FoW',							FoWFarm,						15,					$FOW_FARM_DURATION)
	AddFarmToFarmMap(	'FoW Tower of Courage',			FoWToCFarm,						10,					$FOW_TOC_FARM_DURATION)
	AddFarmToFarmMap(	'Froggy',						FroggyFarm,						10,					$FROGGY_FARM_DURATION)
	AddFarmToFarmMap(	'Gemstones',					GemstonesFarm,					10,					$GEMSTONES_FARM_DURATION)
	AddFarmToFarmMap(	'Gemstone Margonite',			GemstoneMargoniteFarm,			10,					$GEMSTONE_MARGONITE_FARM_DURATION)
	AddFarmToFarmMap(	'Gemstone Stygian',				GemstoneStygianFarm,			10,					$GEMSTONE_STYGIAN_FARM_DURATION)
	AddFarmToFarmMap(	'Gemstone Torment',				GemstoneTormentFarm,			10,					$GEMSTONE_TORMENT_FARM_DURATION)
	AddFarmToFarmMap(	'Glint Challenge',				GlintChallengeFarm,				5,					$GLINT_CHALLENGE_DURATION)
	AddFarmToFarmMap(	'Jade Brotherhood',				JadeBrotherhoodFarm,			5,					$JADEBROTHERHOOD_FARM_DURATION)
	AddFarmToFarmMap(	'Kournans',						KournansFarm,					5,					$KOURNANS_FARM_DURATION)
	AddFarmToFarmMap(	'Kurzick',						KurzickFactionFarm,				15,					$KURZICKS_FARM_DURATION)
	AddFarmToFarmMap(	'Kurzick Drazach',				KurzickFactionFarmDrazach,		10,					$KURZICKS_FARM_DRAZACH_DURATION)
	AddFarmToFarmMap(	'LDOA',							LDOATitleFarm,					0,					$LDOA_FARM_DURATION)
	AddFarmToFarmMap(	'Lightbringer',					LightbringerFarm,				5,					$LIGHTBRINGER_FARM_DURATION)
	AddFarmToFarmMap(	'Lightbringer & Sunspear',		LightbringerSunspearFarm,		10,					$LIGHTBRINGER_SUNSPEAR_FARM_DURATION)
	AddFarmToFarmMap(	'Luxon',						LuxonFactionFarm,				10,					$LUXONS_FARM_DURATION)
	AddFarmToFarmMap(	'Mantids',						MantidsFarm,					5,					$MANTIDS_FARM_DURATION)
	AddFarmToFarmMap(	'Ministerial Commendations',	MinisterialCommendationsFarm,	5,					$COMMENDATIONS_FARM_DURATION)
	AddFarmToFarmMap(	'Minotaurs',					MinotaursFarm,					5,					$MINOTAURS_FARM_DURATION)
	AddFarmToFarmMap(	'Nexus Challenge',				NexusChallengeFarm,				5,					$NEXUS_CHALLENGE_FARM_DURATION)
	AddFarmToFarmMap(	'Norn',							NornTitleFarm,					5,					$NORN_FARM_DURATION)
	AddFarmToFarmMap(	'OmniFarm',						OmniFarm,						5,					5 * 60 * 1000)
	AddFarmToFarmMap(	'Pongmei',						PongmeiChestFarm,				5,					$PONGMEI_FARM_DURATION)
	AddFarmToFarmMap(	'Raptors',						RaptorsFarm,					5,					$RAPTORS_FARM_DURATION)
	AddFarmToFarmMap(	'SoO',							SoOFarm,						15,					$SOO_FARM_DURATION)
	AddFarmToFarmMap(	'SpiritSlaves',					SpiritSlavesFarm,				5,					$SPIRIT_SLAVES_FARM_DURATION)
	AddFarmToFarmMap(	'Sunspear Armor',				SunspearArmorFarm,				5,					$SUNSPEAR_ARMOR_FARM_DURATION)
	AddFarmToFarmMap(	'Tasca',						TascaChestFarm,					5,					$TASCA_FARM_DURATION)
	AddFarmToFarmMap(	'Underworld',					UnderworldFarm,					5,					$UW_FARM_DURATION)
	AddFarmToFarmMap(	'Vaettirs',						VaettirsFarm,					5,					$VAETTIRS_FARM_DURATION)
	AddFarmToFarmMap(	'Vanguard',						VanguardTitleFarm,				5,					$VANGUARD_TITLE_FARM_DURATION)
	AddFarmToFarmMap(	'Voltaic',						VoltaicFarm,					10,					$VOLTAIC_FARM_DURATION)
	AddFarmToFarmMap(	'War Supply Keiran',			WarSupplyKeiranFarm,			10,					$WAR_SUPPLY_FARM_DURATION)
	AddFarmToFarmMap(	'Execution',					RunTests,						5,					2 * 60 * 1000)
	AddFarmToFarmMap(	'Storage',						InventoryManagementBeforeRun,	5,					2 * 60 * 1000)
	AddFarmToFarmMap(	'Tests',						RunTests,						0,					2 * 60 * 1000)
	AddFarmToFarmMap(	'TestSuite',					RunTestSuite,					0,					5 * 60 * 1000)
	AddFarmToFarmMap(	'',								Null,							0,					2 * 60 * 1000)
EndFunc


;~ Reset the setups of the bots when porting to a city for instance
Func ResetBotsSetups()
	$global_farm_setup						= False
	$boreal_farm_setup						= False
	$dm_farm_setup							= False
	$feathers_farm_setup					= False
	$froggy_farm_setup						= False
	$iris_farm_setup						= False
	$jade_brotherhood_farm_setup			= False
	$kournans_farm_setup					= False
	$ldoa_farm_setup						= False
	$lightbringer_farm_setup				= False
	$mantids_farm_setup						= False
	$pongmei_farm_setup						= False
	$raptors_farm_setup						= False
	$soo_farm_setup							= False
	$spirit_slaves_farm_setup				= False
	$tasca_farm_setup						= False
	$vaettirs_farm_setup					= False
	; Those do not need to be reset - party did not change, build did not change, and there is no need to refresh portal
	; BUT those bots MUST tp to the correct map on every loop
	;$cof_farm_setup						= False
	;$corsairs_farm_setup					= False
	;$follower_setup						= False
	;$fow_farm_setup						= False
	;$gemstones_farm_setup					= False
	;$gemstone_margonite_farm_setup			= False
	;$gemstone_stygian_farm_setup			= False
	;$gemstone_torment_farm_setup			= False
	;$glint_challenge_setup					= False
	;$lightbringer_farm_setup				= False
	;$ministerial_commendations_farm_setup	= False
	;$uw_farm_setup							= False
	;$voltaic_farm_setup					= False
	;$warsupply_farm_setup					= False
EndFunc


;~ Setup executed for all farms - setup weapon slots, player and team builds if provided
Func GeneralFarmSetup()
	Local $weaponSlot = $run_options_cache['run.weapon_slot']
	If $weaponSlot <> 0 Then
		Info('Setting player weapon slot to ' & $weaponSlot & ' according to GUI settings')
		ChangeWeaponSet($weaponSlot)
		RandomSleep(250)
	EndIf
	If $run_options_cache['team.automatic_team_setup'] Then
		; Need to be in an outpost to change team and builds
		If GetMapType() <> $ID_OUTPOST Then TravelToOutpost($ID_EYE_OF_THE_NORTH)
		SetupPlayerUsingGlobalSettings()
		SetupTeamUsingGlobalSettings()
	EndIf
	$global_farm_setup = True
EndFunc


;~ Helper to add farms into map in a one-liner
Func AddFarmToFarmMap($farmName, $farmFunction, $farmInventorySpace, $farmDuration)
	Local $farmArray[] = [$farmName, $farmFunction, $farmInventorySpace, $farmDuration]
	$farm_map[$farmName] = $farmArray
EndFunc


;~ Return if team automatic setup is enabled
Func IsTeamAutoSetup()
	Return $run_options_cache['team.automatic_team_setup']
EndFunc


;~ Setup player build from global settings (from GUI or JSON)
Func SetupPlayerUsingGlobalSettings()
	If $run_options_cache['team.load_player_build'] Then
		Info('Loading player build from GUI')
		LoadSkillTemplate($run_options_cache['team.player_build'])
		RandomSleep(250)
	EndIf
EndFunc


;~ Setup team build from global settings (from GUI or JSON)
Func SetupTeamUsingGlobalSettings($teamSize = $ID_TEAM_SIZE_LARGE)
	Info('Setting up team according to GUI settings')
	LeaveParty()
	RandomSleep(500)
	; Could use Eval(), it is shorter but also kind of dirty
	For $i = 1 To $ID_TEAM_SIZE_LARGE - 1
		Local $hero = $run_options_cache['team.hero_' & $i]
		If $hero <> '' Then
			AddHero($HERO_IDS_FROM_NAMES[$hero])
			If $run_options_cache['team.load_hero_' & $i & '_build'] Then
				RandomSleep(500 + GetPing())
				Info('Loading hero ' & $i & ' build from GUI')
				LoadSkillTemplate($run_options_cache['team.hero_' & $i & '_build'], $i)
			EndIf
		EndIf
	Next
EndFunc


Func IsHardmodeEnabled()
	Return $run_options_cache['run.hard_mode']
EndFunc


Func SwitchToHardModeIfEnabled()
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
EndFunc


;~ Fill the inventory cache with additional derived data
Func BuildInventoryDerivedFlags()
	; -------- Pickup --------
	Local $pickupSomething = IsAnyChecked('Pick up items')
	$inventory_management_cache['@pickup.something'] = $pickupSomething
	$inventory_management_cache['@pickup.nothing'] = Not $pickupSomething
	Local $pickupSomeWeapons = IsAnyChecked('Pick up items.Weapons and offhands')
	$inventory_management_cache['@pickup.weapons.something'] = $pickupSomeWeapons
	$inventory_management_cache['@pickup.weapons.nothing'] = Not $pickupSomeWeapons

	; -------- Identify --------
	Local $identifySomething = IsAnyChecked('Identify items')
	$inventory_management_cache['@identify.something'] = $identifySomething
	$inventory_management_cache['@identify.nothing'] = Not $identifySomething

	; -------- Salvage --------
	Local $salvageSomething = IsAnyChecked('Salvage items')
	$inventory_management_cache['@salvage.something'] = $salvageSomething
	$inventory_management_cache['@salvage.nothing'] = Not $salvageSomething
	Local $salvageSomeWeapons = IsAnyChecked('Salvage items.Weapons and offhands')
	$inventory_management_cache['@salvage.weapons.something'] = $salvageSomeWeapons
	$inventory_management_cache['@salvage.weapons.nothing'] = Not $salvageSomeWeapons
	Local $salvageSomeSalvageables = IsAnyChecked('Salvage items.Armor salvageables')
	$inventory_management_cache['@salvage.salvageables.something'] = $salvageSomeSalvageables
	$inventory_management_cache['@salvage.salvageables.nothing'] = Not $salvageSomeSalvageables
	Local $salvageSomeTrophies = IsAnyChecked('Salvage items.Trophies')
	$inventory_management_cache['@salvage.trophies.something'] = $salvageSomeTrophies
	$inventory_management_cache['@salvage.trophies.nothing'] = Not $salvageSomeTrophies
	Local $salvageSomeMaterials = IsAnyChecked('Salvage items.Rare Materials')
	$inventory_management_cache['@salvage.materials.something'] = $salvageSomeMaterials
	$inventory_management_cache['@salvage.materials.nothing'] = Not $salvageSomeMaterials

	; -------- Sell --------
	Local $sellSomething = IsAnyChecked('Sell items')
	$inventory_management_cache['@sell.something'] = $sellSomething
	$inventory_management_cache['@sell.nothing'] = Not $sellSomething
	Local $sellSomeWeapons = IsAnyChecked('Sell items.Weapons and offhands')
	$inventory_management_cache['@sell.weapons.something'] = $sellSomeWeapons
	$inventory_management_cache['@sell.weapons.nothing'] = Not $sellSomeWeapons

	Local $sellSomeBasicMaterials = IsAnyChecked('Sell items.Basic Materials')
	$inventory_management_cache['@sell.materials.basic.something'] = $sellSomeBasicMaterials
	$inventory_management_cache['@sell.materials.basic.nothing'] = Not $sellSomeBasicMaterials
	Local $sellSomeRareMaterials = IsAnyChecked('Sell items.Rare Materials')
	$inventory_management_cache['@sell.materials.rare.something'] = $sellSomeRareMaterials
	$inventory_management_cache['@sell.materials.rare.nothing'] = Not $sellSomeRareMaterials
	Local $sellSomeMaterials = $sellSomeBasicMaterials Or $sellSomeRareMaterials
	$inventory_management_cache['@sell.materials.something'] = $sellSomeMaterials
	$inventory_management_cache['@sell.materials.nothing'] = Not $sellSomeMaterials

	; -------- Buy --------
	Local $buySomething = IsAnyChecked('Buy items')
	$inventory_management_cache['@buy.something'] = $buySomething
	$inventory_management_cache['@buy.nothing'] = Not $buySomething

	Local $buySomeBasicMaterials = IsAnyChecked('Buy items.Basic Materials')
	$inventory_management_cache['@buy.materials.basic.something'] = $buySomeBasicMaterials
	$inventory_management_cache['@buy.materials.basic.nothing'] = Not $buySomeBasicMaterials
	Local $buySomeRareMaterials = IsAnyChecked('Buy items.Rare Materials')
	$inventory_management_cache['@buy.materials.rare.something'] = $buySomeRareMaterials
	$inventory_management_cache['@buy.materials.rare.nothing'] = Not $buySomeRareMaterials
	Local $buySomeMaterials = $buySomeBasicMaterials Or $buySomeRareMaterials
	$inventory_management_cache['@buy.materials.something'] = $buySomeMaterials
	$inventory_management_cache['@buy.materials.nothing'] = Not $buySomeMaterials

	; -------- Store --------
	Local $storeSomething = IsAnyChecked('Store items')
	$inventory_management_cache['@store.something'] = $storeSomething
	$inventory_management_cache['@store.nothing'] = Not $storeSomething
	Local $storeSomeWeapons = IsAnyChecked('Store items.Weapons and offhands')
	$inventory_management_cache['@store.weapons.something'] = $storeSomeWeapons
	$inventory_management_cache['@store.weapons.nothing'] = Not $storeSomeWeapons
EndFunc


;~ Return if any option at provided path or lower in the tree is checked
Func IsAnyChecked($path)
	Local $pathLength = StringLen($path) + 1
	For $key In MapKeys($inventory_management_cache)
		If Not $inventory_management_cache[$key] Then ContinueLoop
		If $key == $path Then Return True
		If StringLen($key) <= $pathLength Then ContinueLoop
		If StringLeft($key, $pathLength) == ($path & '.') Then Return True
	Next
	Return False
EndFunc


;~ Return checked leaf options under provided path
Func GetAllChecked($map, $path, $minDepth = -1, $maxDepth = -1)
	Local $checkedElements[0]
	Local $pathLength = StringLen($path) + 1

	; Step 1: collect all checked descendants
	For $key In MapKeys($map)
		If Not $map[$key] Then ContinueLoop
		If $key == $path Then ContinueLoop
		If StringLen($key) <= $pathLength Then ContinueLoop
		If StringLeft($key, $pathLength) == ($path & '.') Then
			_ArrayAdd($checkedElements, $key)
		EndIf
	Next

	; Step 2: remove checked parents (keep leaves only)
	Local $size = UBound($checkedElements)
	Local $remove[$size]

	For $i = 0 To $size - 1
		For $j = 0 To $size - 1
			If $i = $j Then ContinueLoop
			If StringLeft($checkedElements[$j], StringLen($checkedElements[$i]) + 1) == $checkedElements[$i] & '.' Then
				$remove[$i] = True
				ExitLoop
			EndIf
		Next
	Next

	Local $leaves[0]
	For $i = 0 To $size - 1
		If Not $remove[$i] Then _ArrayAdd($leaves, $checkedElements[$i])
	Next

	; Step 3: depth filtering
	If $minDepth > 0 Or $maxDepth > 0 Then
		Local $filtered[0]

		For $element In $leaves
			Local $relative = StringTrimLeft($element, $pathLength)
			; Careful - this is AutoIt, size is present in first slot
			Local $depth = UBound(StringSplit($relative, '.')) - 1
			If $minDepth > 0 And $depth < $minDepth Then ContinueLoop
			If $maxDepth > 0 And $depth > $maxDepth Then ContinueLoop

			_ArrayAdd($filtered, $element)
		Next

		Return $filtered
	EndIf

	Return $leaves
EndFunc
#EndRegion Setup


#Region Authentification and Login
;~ Initialize connection to GW with the character name or process ID given
Func Authentification($characterName)
	If ($characterName == '') Then
		Warn('Running without authentification.')
	ElseIf $run_mode == 'HEADLESS' Then
		Info('Running via PID ' & $process_id)
		If InitializeGameClientForGWA2(True) = 0 Then
			MsgBox(0, 'Error', 'Could not find a ProcessID or somewhat <<' & $process_id & '>> ' & VarGetType($process_id) & '')
			Return $FAIL
		EndIf
	Else
		Local $clientIndex = FindClientIndexByCharacterName($characterName)
		If $clientIndex == -1 Then
			MsgBox(0, 'Error', 'Could not find a GW client with a character named <<' & $characterName & '>>')
			Return $FAIL
		Else
			SelectClient($clientIndex)
			OpenDebugLogFile()
			If InitializeGameClientForGWA2(True) = 0 Then
				MsgBox(0, 'Error', 'Failed game initialisation')
				Return $FAIL
			EndIf
		EndIf
		RenameGUI('GW Bot Hub - ' & $characterName)
	EndIf
	Return $SUCCESS
EndFunc
#EndRegion Authentification and Login