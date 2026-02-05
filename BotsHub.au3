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

; Night's tips and tricks
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

Global Const $LVL_DEBUG = 0
Global Const $LVL_INFO = 1
Global Const $LVL_NOTICE = 2
Global Const $LVL_WARNING = 3
Global Const $LVL_ERROR = 4

; UNINITIALIZED -> INITIALIZED -> RUNNING -> WILL_PAUSE -> PAUSED -> RUNNING
Global $runtime_status = 'UNINITIALIZED'
Global $run_mode = 'AUTOLOAD'
Global $process_id = ''
Global $character_name = ''
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
	If @AutoItVersion < '3.3.16.0' Then
		MsgBox(16, 'Error', 'This bot requires AutoIt version 3.3.16.0 or higher. You are using ' & @AutoItVersion & '.')
		Exit 1
	EndIf
	If @AutoItX64 Then
		MsgBox(16, 'Error!', 'Please run all bots in 32-bit (x86) mode.')
		Exit 1
	EndIf

	CreateGUI()
	GUISetState(@SW_SHOWNORMAL)
	Info('GW Bot Hub ' & $GW_BOT_HUB_VERSION)

	If $CmdLine[0] <> 0 Then
		$run_mode = 'CMD'
		If 1 > UBound($CmdLine)-1 Then
			MsgBox(0, 'Error', 'Element is out of the array bounds.')
			exit
		EndIf
		If 2 > UBound($CmdLine)-1 Then exit

		$character_name = $CmdLine[1]
		$process_id = $CmdLine[2]
		; Login with $character_name or $process_id
		$runtime_status = 'INITIALIZED'
	ElseIf $run_mode == 'AUTOLOAD' Then
		ScanAndUpdateGameClients()
		RefreshCharactersComboBox()
	Else
		ChangeCharacterNameBoxWithInput()
	EndIf
	FillConfigurationCombo()
	LoadDefaultConfiguration()
	FillFarmMap()
	BotHubLoop()
EndFunc


;~ Main loop of the program
Func BotHubLoop()
	While True
		If ($runtime_status == 'RUNNING') Then
			DisableGUIComboboxes()
			Local $result = RunFarmLoop()
			If ($result == $PAUSE Or $run_options_cache['run.loop_mode'] == False) Then $runtime_status = 'WILL_PAUSE'
		EndIf

		If ($runtime_status == 'WILL_PAUSE') Then
			Warn('Paused.')
			$runtime_status = 'PAUSED'
			EnableStartButton()
			EnableGUIComboboxes()
		EndIf
		Sleep(1000)
	WEnd
EndFunc


;~ Main loop to run farms
Func RunFarmLoop()
	Local $farmName = GUICtrlRead($gui_combo_farmchoice)
	If $farmName == Null Or $farmName == '' Then
		MsgBox(0, 'Error', 'This farm does not exist.')
		$runtime_status = 'INITIALIZED'
		EnableStartButton()
		Return $PAUSE
	EndIf

	; Farm Name;Farm function;Inventory space;Farm duration
	Local $farm = $farm_map[$farmName]
	Local $inventorySpaceNeeded = $farm[2]

	; No authentication: skip global farm setup and inventory management
	If GUICtrlRead($gui_combo_characterchoice) <> '' Then
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
		; Inventory management didn't clean up inventory - we pause
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
	Local $timePerRun = UpdateStats($NOT_STARTED)
	$run_timer = TimerInit()
	UpdateProgressBar($timePerRun == 0 ? $farm[3] : $timePerRun)
	AdlibRegister('UpdateProgressBar', 5000)
	Local $farmFunction = $farm[1]
	$result = $farmFunction()
	AdlibUnRegister('UpdateProgressBar')
	CompleteGUIFarmProgress()

	Local $elapsedTime = TimerDiff($run_timer)
	Info('Run ' & ($result == $SUCCESS ? 'successful' : 'failed') & ' after: ' & ConvertTimeToMinutesString($elapsedTime))
	UpdateStats($result, $elapsedTime)
	ClearMemory(GetProcessHandle())
	; _PurgeHook()
	Return $result
EndFunc
#EndRegion Main loops


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
	; Those don't need to be reset - party didn't change, build didn't change, and there is no need to refresh portal
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
		SetupPlayerUsingGUISettings()
		SetupTeamUsingGUISettings()
	EndIf
	$global_farm_setup = True
EndFunc


;~ Helper to add farms into map in a one-liner
Func AddFarmToFarmMap($farmName, $farmFunction, $farmInventorySpace, $farmDuration)
	Local $farmArray[4] = [$farmName, $farmFunction, $farmInventorySpace, $farmDuration]
	$farm_map[$farmName] = $farmArray
EndFunc


;~ Return if team automatic setup is enabled
Func IsTeamAutoSetup()
	Return $run_options_cache['team.automatic_team_setup']
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
Func Authentification()
	Local $characterName = GUICtrlRead($gui_combo_characterchoice)
	If ($characterName == '') Then
		Warn('Running without authentification.')
	ElseIf $process_id And $run_mode == 'CMD' Then
		Local $processID = Number($process_id, 2)
		Info('Running via PID ' & $processID)
		If InitializeGameClientForGWA2(True) = 0 Then
			MsgBox(0, 'Error', 'Could not find a ProcessID or somewhat <<' & $processID & '>> ' & VarGetType($processID) & '')
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
	EndIf
	RenameGUI('GW Bot Hub - ' & $characterName)
	Return $SUCCESS
EndFunc
#EndRegion Authentification and Login