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
#include 'src/farms/Lightbringer.au3'
#include 'src/farms/Lightbringer2.au3'
#include 'src/farms/Mantids.au3'
#include 'src/farms/Kournans.au3'
#include 'src/farms/Minotaurs.au3'
#include 'src/farms/Raptors.au3'
#include 'src/farms/SpiritSlaves.au3'
#include 'src/farms/Vaettirs.au3'
#include 'src/missions/FoW.au3'
#include 'src/missions/Froggy.au3'
#include 'src/missions/GlintChallenge.au3'
#include 'src/missions/Kilroy.au3'
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

Global Const $AVAILABLE_FARMS = '|Asuran|Boreal|CoF|Corsairs|Dragon Moss|Eden Iris|Feathers|Follower|FoW|FoW Tower of Courage|Froggy|Gemstones|Gemstone Margonite|Gemstone Stygian|Gemstone Torment|Glint Challenge|Jade Brotherhood|Kilroy|Kournans|Kurzick|Lightbringer|Lightbringer 2|LDOA|Luxon|Mantids|Ministerial Commendations|Minotaurs|Nexus Challenge|Norn|OmniFarm|Pongmei|Raptors|SoO|SpiritSlaves|Sunspear Armor|Tasca|Underworld|Vaettirs|Vanguard|Voltaic|War Supply Keiran|Storage|Tests|TestSuite|Dynamic execution'
Global Const $AVAILABLE_DISTRICTS = '|Random|America|China|English|French|German|International|Italian|Japan|Korea|Polish|Russian|Spanish'
Global Const $AVAILABLE_BAG_COUNTS = '|1|2|3|4|5'
Global Const $AVAILABLE_WEAPON_SLOTS = '|1|2|3|4'
Global Const $AVAILABLE_HEROES = '||Acolyte Jin|Acolyte Sousuke|Anton|Dunkoro|General Morgahn|Goren|Gwen|Hayda|Jora|Kahmu|Keiran Thackeray|Koss|Livia|Margrid the Sly|Master of Whispers|Melonni|Miku|MOX|Norgu|Ogden|Olias|Pyre Fierceshot|Razah|Tahlkora|Vekk|Xandra|ZeiRi|Zenmai|Zhed Shadowhoof|Mercenary Hero 1|Mercenary Hero 2|Mercenary Hero 3|Mercenary Hero 4|Mercenary Hero 5|Mercenary Hero 6|Mercenary Hero 7|Mercenary Hero 8||'

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
Global $district_name = 'Random'
Global $bags_count = 5
Global $default_weapon_slot = 1
; If set to 0, disables inventory management
Global $inventory_space_needed = 5
Global $run_timer = Null
Global $global_farm_setup = False
Global $inventory_management_cache[]
Global $log_level = $LVL_INFO
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
		GUICtrlDelete($GUI_Combo_CharacterChoice)
		$GUI_Combo_CharacterChoice = GUICtrlCreateCombo('Character Name Input', 10, 470, 150, 20)
	EndIf
	FillConfigurationCombo()
	LoadDefaultConfiguration()
	BotHubLoop()
EndFunc


;~ Main loop of the program
Func BotHubLoop()
	While True
		Sleep(1000)

		If ($runtime_status == 'RUNNING') Then
			DisableGUIComboboxes()

			; Skip inventory management and setups when running without authentication
			If GUICtrlRead($GUI_Combo_CharacterChoice) <> '' Then
				; Must do mid-run inventory management before normal one else we will go back to town
				If $inventory_space_needed <> 0 And GUICtrlRead($GUI_Checkbox_FarmMaterialsMidRun) = $GUI_CHECKED Then
					Local $resetRequired = InventoryManagementMidRun()
					If $resetRequired Then ResetBotsSetups()
				EndIf
				; During pickup, items will be moved to equipment bag (if used) when first 3 bags are full
				; So bag 5 will always fill before 4 - hence we can count items up to bag 4
				If (CountSlots(1, _Min($bags_count, 4)) < $inventory_space_needed) Then
					InventoryManagementBeforeRun()
					ResetBotsSetups()
				EndIf
				If (CountSlots(1, $bags_count) < $inventory_space_needed) Then
					Notice('Inventory full, pausing.')
					ResetBotsSetups()
					$runtime_status = 'WILL_PAUSE'
				EndIf
				If Not $global_farm_setup Then GeneralFarmSetup()
			EndIf

			Local $farm = GUICtrlRead($GUI_Combo_FarmChoice)
			Local $result = RunFarmLoop($farm)
			If ($result == $PAUSE Or GUICtrlRead($GUI_Checkbox_LoopRuns) == $GUI_UNCHECKED) Then
				$runtime_status = 'WILL_PAUSE'
			EndIf
		EndIf

		If ($runtime_status == 'WILL_PAUSE') Then
			Warn('Paused.')
			$runtime_status = 'PAUSED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetState($GUI_StartButton, $GUI_Enable)
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTBLUE)
			EnableGUIComboboxes()
		EndIf
	WEnd
EndFunc


;~ Setup executed for all farms - setup weapon slots, player and team builds if provided
Func GeneralFarmSetup()
	If GUICtrlRead($GUI_Checkbox_WeaponSlot) == $GUI_CHECKED Then
		Info('Setting player weapon slot to ' & $default_weapon_slot & ' according to GUI settings')
		ChangeWeaponSet($default_weapon_slot)
		RandomSleep(250)
	EndIf
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		; Need to be in an outpost to change team and builds
		If GetMapType() <> $ID_OUTPOST Then TravelToOutpost($ID_EYE_OF_THE_NORTH)
		SetupPlayerUsingGUISettings()
		SetupTeamUsingGUISettings()
	EndIf
	$global_farm_setup = True
EndFunc


;~ Main loop to run farms
Func RunFarmLoop($Farm)
	Local $result = $NOT_STARTED
	Local $timePerRun = UpdateStats($NOT_STARTED)
	$run_timer = TimerInit()
	UpdateProgressBar($timePerRun == 0 ? SelectFarmDuration($Farm) : $timePerRun)
	AdlibRegister('UpdateProgressBar', 5000)
	Switch $Farm
		Case 'Choose a farm'
			MsgBox(0, 'Error', 'No farm chosen.')
			$runtime_status = 'INITIALIZED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTBLUE)
		Case 'Asuran'
			$inventory_space_needed = 5
			$result = AsuranTitleFarm()
		Case 'Boreal'
			$inventory_space_needed = 5
			$result = BorealChestFarm()
		Case 'CoF'
			$inventory_space_needed = 5
			$result = CoFFarm()
		Case 'Corsairs'
			$inventory_space_needed = 5
			$result = CorsairsFarm()
		Case 'Dragon Moss'
			$inventory_space_needed = 5
			$result = DragonMossFarm()
		Case 'Eden Iris'
			$inventory_space_needed = 2
			$result = EdenIrisFarm()
		Case 'Feathers'
			$inventory_space_needed = 10
			$result = FeathersFarm()
		Case 'Follower'
			$inventory_space_needed = 5
			$result = FollowerFarm()
		Case 'FoW'
			$inventory_space_needed = 15
			$result = FoWFarm()
		Case 'FoW Tower of Courage'
			$inventory_space_needed = 10
			$result = FoWToCFarm()
		Case 'Froggy'
			$inventory_space_needed = 10
			$result = FroggyFarm()
		Case 'Gemstones'
			$inventory_space_needed = 10
			$result = GemstonesFarm()
		Case 'Gemstone Margonite'
			$inventory_space_needed = 10
			$result = GemstoneMargoniteFarm()
		Case 'Gemstone Stygian'
			$inventory_space_needed = 10
			$result = GemstoneStygianFarm()
		Case 'Gemstone Torment'
			$inventory_space_needed = 10
			$result = GemstoneTormentFarm()
		Case 'Glint Challenge'
			$inventory_space_needed = 5
			$result = GlintChallengeFarm()
		Case 'Jade Brotherhood'
			$inventory_space_needed = 5
			$result = JadeBrotherhoodFarm()
		Case 'Kilroy'
			$inventory_space_needed = 5
			$result = KilroyFarm()
		Case 'Kournans'
			$inventory_space_needed = 5
			$result = KournansFarm()
		Case 'Kurzick'
			$inventory_space_needed = 15
			$result = KurzickFactionFarm()
		Case 'LDOA'
			$inventory_space_needed = 0
			$result = LDOATitleFarm()
		Case 'Lightbringer'
			$inventory_space_needed = 10
			$result = LightbringerFarm()
		Case 'Lightbringer 2'
			$inventory_space_needed = 5
			$result = LightbringerFarm2()
		Case 'Luxon'
			$inventory_space_needed = 10
			$result = LuxonFactionFarm()
		Case 'Mantids'
			$inventory_space_needed = 5
			$result = MantidsFarm()
		Case 'Ministerial Commendations'
			$inventory_space_needed = 5
			$result = MinisterialCommendationsFarm()
		Case 'Minotaurs'
			$inventory_space_needed = 5
			$result = MinotaursFarm()
		Case 'Nexus Challenge'
			$inventory_space_needed = 5
			$result = NexusChallengeFarm()
		Case 'Norn'
			$inventory_space_needed = 5
			$result = NornTitleFarm()
		Case 'OmniFarm'
			$inventory_space_needed = 5
			$result = OmniFarm()
		Case 'Pongmei'
			$inventory_space_needed = 5
			$result = PongmeiChestFarm()
		Case 'Raptors'
			$inventory_space_needed = 5
			$result = RaptorsFarm()
		Case 'SoO'
			$inventory_space_needed = 15
			$result = SoOFarm()
		Case 'SpiritSlaves'
			$inventory_space_needed = 5
			$result = SpiritSlavesFarm()
		Case 'Sunspear Armor'
			$inventory_space_needed = 5
			$result = SunspearArmorFarm()
		Case 'Tasca'
			$inventory_space_needed = 5
			$result = TascaChestFarm()
		Case 'Underworld'
			$inventory_space_needed = 5
			$result = UnderworldFarm()
		Case 'Vaettirs'
			$inventory_space_needed = 5
			$result = VaettirsFarm()
		Case 'Vanguard'
			$inventory_space_needed = 5
			$result = VanguardTitleFarm()
		Case 'Voltaic'
			$inventory_space_needed = 10
			$result = VoltaicFarm()
		Case 'War Supply Keiran'
			$inventory_space_needed = 10
			$result = WarSupplyKeiranFarm()
		Case 'Storage'
			$inventory_space_needed = 5
			ResetBotsSetups()
			InventoryManagementBeforeRun()
			$result = $PAUSE
		Case 'Dynamic execution'
			Info('Dynamic execution')
		Case 'Tests'
			$result = RunTests()
		Case 'TestSuite'
			$result = RunTestSuite()
		Case Else
			MsgBox(0, 'Error', 'This farm does not exist.')
	EndSwitch
	AdlibUnRegister('UpdateProgressBar')
	GUICtrlSetData($GUI_FarmProgress, 100)
	Local $elapsedTime = TimerDiff($run_timer)
	If $result == $SUCCESS Then
		Info('Run Successful after: ' & ConvertTimeToMinutesString($elapsedTime))
	ElseIf $result == $FAIL Then
		Info('Run failed after: ' & ConvertTimeToMinutesString($elapsedTime))
	EndIf
	UpdateStats($result, $elapsedTime)
	ClearMemory(GetProcessHandle())
	; _PurgeHook()
	Return $result
EndFunc
#EndRegion Main loops


#Region Authentification and Login
;~ Initialize connection to GW with the character name or process id given
Func Authentification()
	Local $characterName = GUICtrlRead($GUI_Combo_CharacterChoice)
	If ($characterName == '') Then
		Warn('Running without authentification.')
	ElseIf $process_id And $run_mode == 'CMD' Then
		Local $processID = Number($process_id, 2)
		Info('Running via pid ' & $processID)
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
	WinSetTitle($GUI_GWBotHub, '', 'GW Bot Hub - ' & $characterName)
	Return $SUCCESS
EndFunc
#EndRegion Authentification and Login


#Region Setup
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
	$lightbringer_farm2_setup				= False
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


;~ Update the farm description written on the rightmost tab
Func UpdateFarmDescription($Farm)
	GUICtrlSetData($GUI_Edit_CharacterBuilds, '')
	GUICtrlSetData($GUI_Edit_HeroesBuilds, '')
	GUICtrlSetData($GUI_Label_FarmInformations, '')

	Local $generalCharacterSetup = 'Simple build to play from skill 1 to skill 8, such as:' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:N/A_Assassin%27s_Promise_Death_Magic' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:E/A_Assassin%27s_Promise' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:Me/A_Assassin%27s_Promise'
	Local $generalHeroesSetup = 'Solid heroes setup, such as:' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_Mercenary_Mesmerway' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:Team_-_5_Hero_Mesmerway' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:Team_-_3_Hero_Dual_Mesmer' & @CRLF & _
		'https://gwpvx.fandom.com/wiki/Build:Team_-_3_Hero_Balanced'
	Switch $Farm
		Case 'Asuran'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $ASURAN_FARM_INFORMATIONS)
		Case 'Boreal'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $BOREAL_RANGER_CHESTRUNNER_SKILLBAR & @CRLF & _
				$BOREAL_MONK_CHESTRUNNER_SKILLBAR & @CRLF & $BOREAL_NECROMANCER_CHESTRUNNER_SKILLBAR & @CRLF & _
				$BOREAL_MESMER_CHESTRUNNER_SKILLBAR & @CRLF & $BOREAL_ELEMENTALIST_CHESTRUNNER_SKILLBAR & @CRLF & _
				$BOREAL_ASSASSIN_CHESTRUNNER_SKILLBAR & @CRLF & $BOREAL_RITUALIST_CHESTRUNNER_SKILLBAR & @CRLF & _
				$BOREAL_DERVISH_CHEST_RUNNER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $BOREAL_CHESTRUN_INFORMATIONS)
		Case 'CoF'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $D_COF_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $COF_FARM_INFORMATIONS)
		Case 'Corsairs'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RA_CORSAIRS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $MOP_CORSAIRS_HERO_SKILLBAR & @CRLF & $DR_CORSAIRS_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $CORSAIRS_FARM_INFORMATIONS)
		Case 'Dragon Moss'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RA_DRAGON_MOSS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $DRAGON_MOSS_FARM_INFORMATIONS)
		Case 'Eden Iris'
			GUICtrlSetData($GUI_Label_FarmInformations, $EDEN_IRIS_FARM_INFORMATIONS)
		Case 'Feathers'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $DA_FEATHERS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $FEATHERS_FARM_INFORMATIONS)
		Case 'Follower'
			GUICtrlSetData($GUI_Label_FarmInformations, $FOLLOWER_INFORMATIONS)
		Case 'FoW'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $FOW_FARM_INFORMATIONS)
		Case 'FoW Tower of Courage'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RA_FOW_TOC_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $FOW_TOC_FARM_INFORMATIONS)
		Case 'Froggy'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $FROGGY_FARM_INFORMATIONS)
		Case 'Gemstones'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $GEMSTONES_MESMER_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $GEMSTONES_HERO_1_SKILLBAR & @CRLF & _
				$GEMSTONES_HERO_2_SKILLBAR & @CRLF & $GEMSTONES_HERO_3_SKILLBAR & @CRLF & _
				$GEMSTONES_HERO_4_SKILLBAR & @CRLF & $GEMSTONES_HERO_5_SKILLBAR & @CRLF & _
				$GEMSTONES_HERO_6_SKILLBAR & @CRLF & $GEMSTONES_HERO_7_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $GEMSTONES_FARM_INFORMATIONS)
		Case 'Gemstone Margonite'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $AME_MARGONITE_SKILLBAR & @CRLF & _
				$MEA_MARGONITE_SKILLBAR & @CRLF & $EME_MARGONITE_SKILLBAR & @CRLF & $RA_MARGONITE_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $MARGONITE_MONK_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $GEMSTONE_MARGONITE_FARM_INFORMATIONS)
		Case 'Gemstone Stygian'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $AME_STYGIAN_SKILLBAR _
				& @CRLF & $MEA_STYGIAN_SKILLBAR & @CRLF & $RN_STYGIAN_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $STYGIAN_RANGER_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $GEMSTONE_STYGIAN_FARM_INFORMATIONS)
		Case 'Gemstone Torment'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $EA_TORMENT_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $GEMSTONE_TORMENT_FARM_INFORMATIONS)
		Case 'Glint Challenge'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $GLINT_MESMER_SKILLBAR_OPTIONAL)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $GLINT_RITU_SOUL_TWISTER_HERO_SKILLBAR & @CRLF & _
				$GLINT_NECRO_FLESH_GOLEM_HERO_SKILLBAR & @CRLF & $GLINT_NECRO_HEXER_HERO_SKILLBAR & @CRLF & _
				$GLINT_NECRO_BIP_HERO_SKILLBAR & @CRLF & $GLINT_MESMER_PANIC_HERO_SKILLBAR & @CRLF & _
				$GLINT_MESMER_INEPTITUDE_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $GLINT_CHALLENGE_INFORMATIONS)
		Case 'Jade Brotherhood'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $JB_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $JB_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $JB_FARM_INFORMATIONS)
		Case 'Kilroy'
			GUICtrlSetData($GUI_Label_FarmInformations, $KILROY_FARM_INFORMATIONS)
		Case 'Kournans'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $ELA_KOURNANS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $R_KOURNANS_HERO_SKILLBAR & @CRLF & _
				$RT_KOURNANS_HERO_SKILLBAR & @CRLF & $P_KOURNANS_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $KOURNANS_FARM_INFORMATIONS)
		Case 'Kurzick'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $KURZICK_FACTION_INFORMATIONS)
		Case 'LDOA'
			GUICtrlSetData($GUI_Label_FarmInformations, $LDOA_INFORMATIONS)
		Case 'Lightbringer'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $LIGHTBRINGER_FARM_INFORMATIONS)
		Case 'Lightbringer 2'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $LIGHTBRINGER_FARM2_INFORMATIONS)
		Case 'Luxon'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $LUXON_FACTION_INFORMATIONS)
		Case 'Mantids'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RA_MANTIDS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $MANTIDS_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $MANTIDS_FARM_INFORMATIONS)
		Case 'Ministerial Commendations'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $DW_COMMENDATIONS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $COMMENDATIONS_FARM_INFORMATIONS)
		Case 'Minotaurs'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $MINOTAURS_FARM_INFORMATIONS)
		Case 'Nexus Challenge'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $NEXUS_CHALLENGE_INFORMATIONS)
		Case 'Norn'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $NORN_FARM_INFORMATIONS)
		Case 'Pongmei'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $PONGMEI_CHESTRUNNER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $PONGMEI_CHESTRUN_INFORMATIONS)
		Case 'Raptors'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $WN_RAPTORS_FARMER_SKILLBAR & @CRLF & $DN_RAPTORS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $P_RUNNER_HERO_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $RAPTORS_FARM_INFORMATIONS)
		Case 'SoO'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $SOO_FARM_INFORMATIONS)
		Case 'SpiritSlaves'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $SPIRIT_SLAVES_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $SPIRIT_SLAVES_FARM_INFORMATIONS)
		Case 'Sunspear Armor'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $SUNSPEAR_ARMOR_FARM_INFORMATIONS)
		Case 'Tasca'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $TASCA_DERVISH_CHESTRUNNER_SKILLBAR & @CRLF & _
				$TASCA_ASSASSIN_CHESTRUNNER_SKILLBAR & @CRLF & $TASCA_MESMER_CHESTRUNNER_SKILLBAR & @CRLF & _
				$TASCA_ELEMENTALIST_CHESTRUNNER_SKILLBAR & @CRLF & $TASCA_MONK_CHESTRUNNER_SKILLBAR & @CRLF & _
				$TASCA_NECROMANCER_CHESTRUNNER_SKILLBAR & @CRLF & $TASCA_RITUALIST_CHESTRUNNER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $TASCA_CHESTRUN_INFORMATIONS)
		Case 'Underworld'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $UNDERWORLD_FARM_INFORMATIONS)
		Case 'Vaettirs'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $AME_VAETTIRS_FARMER_SKILLBAR & @CRLF & _
				$MEA_VAETTIRS_FARMER_SKILLBAR & @CRLF & $MOA_VAETTIRS_FARMER_SKILLBAR & @CRLF & $EME_VAETTIRS_FARMER_SKILLBAR)
			GUICtrlSetData($GUI_Label_FarmInformations, $VAETTIRS_FARM_INFORMATIONS)
		Case 'Vanguard'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $VANGUARD_TITLE_FARM_INFORMATIONS)
		Case 'Voltaic'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $generalCharacterSetup)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $generalHeroesSetup)
			GUICtrlSetData($GUI_Label_FarmInformations, $VOLTAIC_FARM_INFORMATIONS)
		Case 'War Supply Keiran'
			GUICtrlSetData($GUI_Label_FarmInformations, $WAR_SUPPLY_KEIRAN_INFORMATIONS)
		Case 'OmniFarm'
			Return
		Case 'Storage'
			Return
		Case Else
			Return
	EndSwitch
EndFunc
#EndRegion Setup


#Region Statistics management
;~ Fill statistics
Func UpdateStats($result, $elapsedTime = 0)
	; All static variables are initialized only once when UpdateStats() function is called first time
	Local Static $runs = 0
	Local Static $successes = 0
	Local Static $failures = 0
	Local Static $successRatio = 0
	Local Static $totalTime = 0
	Local Static $TotalChests = 0
	Local Static $InitialExperience = GetExperience()

	Local Static $AsuraTitlePoints = GetAsuraTitle()
	Local Static $DeldrimorTitlePoints = GetDeldrimorTitle()
	Local Static $NornTitlePoints = GetNornTitle()
	Local Static $VanguardTitlePoints = GetVanguardTitle()
	Local Static $LightbringerTitlePoints = GetLightbringerTitle()
	Local Static $SunspearTitlePoints = GetSunspearTitle()
	Local Static $KurzickTitlePoints = GetKurzickTitle()
	Local Static $LuxonTitlePoints = GetLuxonTitle()

	; $NOT_STARTED = -1 : Before every farm loop
	If $result == $NOT_STARTED Then
		Info('Starting run ' & ($runs + 1))
	; $SUCCESS = 0 : Successful farm run
	ElseIf $result == $SUCCESS Then
		$successes += 1
		$runs += 1
		$successRatio = Round(($successes / $runs) * 100, 2)
		$totalTime += $elapsedTime
	; $FAIL = 1 : Failed farm run
	ElseIf $result == $FAIL Then
		$failures += 1
		$runs += 1
		$successRatio = Round(($successes / $runs) * 100, 2)
		$totalTime += $elapsedTime
	EndIf
	; $PAUSE = 2 : Paused run or will pause

	; Global stats
	GUICtrlSetData($GUI_Label_Runs_Value, $runs)
	GUICtrlSetData($GUI_Label_Successes_Value, $successes)
	GUICtrlSetData($GUI_Label_Failures_Value, $failures)
	GUICtrlSetData($GUI_Label_SuccessRatio_Value, $successRatio & ' %')
	GUICtrlSetData($GUI_Label_Time_Value, ConvertTimeToHourString($totalTime))
	Local $timePerRun = $runs == 0 ? 0 : $totalTime / $runs
	GUICtrlSetData($GUI_Label_TimePerRun_Value, ConvertTimeToMinutesString($timePerRun))
	$TotalChests += CountOpenedChests()
	ClearChestsMap()
	GUICtrlSetData($GUI_Label_Chests_Value, $TotalChests)
	GUICtrlSetData($GUI_Label_Experience_Value, (GetExperience() - $InitialExperience))

	; Title stats
	GUICtrlSetData($GUI_Label_AsuraTitle_Value, GetAsuraTitle() - $AsuraTitlePoints)
	GUICtrlSetData($GUI_Label_DeldrimorTitle_Value, GetDeldrimorTitle() - $DeldrimorTitlePoints)
	GUICtrlSetData($GUI_Label_NornTitle_Value, GetNornTitle() - $NornTitlePoints)
	GUICtrlSetData($GUI_Label_VanguardTitle_Value, GetVanguardTitle() - $VanguardTitlePoints)
	GUICtrlSetData($GUI_Label_KurzickTitle_Value, GetKurzickTitle() - $KurzickTitlePoints)
	GUICtrlSetData($GUI_Label_LuxonTitle_Value, GetLuxonTitle() - $LuxonTitlePoints)
	GUICtrlSetData($GUI_Label_LightbringerTitle_Value, GetLightbringerTitle() - $LightbringerTitlePoints)
	GUICtrlSetData($GUI_Label_SunspearTitle_Value, GetSunspearTitle() - $SunspearTitlePoints)

	UpdateItemStats()
	Return $timePerRun
EndFunc


Func UpdateItemStats()
	; All static variables are initialized only once when UpdateItemStats() function is called first time
	Local Static $itemsToCount[28] = [$ID_GLOB_OF_ECTOPLASM, $ID_OBSIDIAN_SHARD, $ID_LOCKPICK, _
		$ID_MARGONITE_GEMSTONE, $ID_STYGIAN_GEMSTONE, $ID_TITAN_GEMSTONE, $ID_TORMENT_GEMSTONE, _
		$ID_DIESSA_CHALICE, $ID_GOLDEN_RIN_RELIC, $ID_DESTROYER_CORE, $ID_GLACIAL_STONE, _
		$ID_WAR_SUPPLIES, $ID_MINISTERIAL_COMMENDATION, $ID_JADE_BRACELET, _
		$ID_CHUNK_OF_DRAKE_FLESH, $ID_SKALE_FIN, _
		$ID_WINTERSDAY_GIFT, $ID_TOT, $ID_BIRTHDAY_CUPCAKE, $ID_GOLDEN_EGG, $ID_SLICE_OF_PUMPKIN_PIE, _
		$ID_HONEYCOMB, $ID_FRUITCAKE, $ID_SUGARY_BLUE_DRINK, $ID_CHOCOLATE_BUNNY, $ID_DELICIOUS_CAKE, _
		$ID_AMBER_CHUNK, $ID_JADEITE_SHARD]
	Local $itemCounts = CountTheseItems($itemsToCount)
	Local $goldItemsCount = CountGoldItems()

	Local Static $PreRunGold = GetGoldCharacter()
	Local Static $PreRunGoldItems = $goldItemsCount
	Local Static $TotalGold = 0
	Local Static $TotalGoldItems = 0

	Local Static $PreRunEctos = $itemCounts[0]
	Local Static $PreRunObsidianShards = $itemCounts[1]
	Local Static $PreRunLockpicks = $itemCounts[2]
	Local Static $PreRunMargoniteGemstones = $itemCounts[3]
	Local Static $PreRunStygianGemstones = $itemCounts[4]
	Local Static $PreRunTitanGemstones = $itemCounts[5]
	Local Static $PreRunTormentGemstones = $itemCounts[6]
	Local Static $PreRunDiessaChalices = $itemCounts[7]
	Local Static $PreRunRinRelics = $itemCounts[8]
	Local Static $PreRunDestroyerCores = $itemCounts[9]
	Local Static $PreRunGlacialStones = $itemCounts[10]
	Local Static $PreRunWarSupplies = $itemCounts[11]
	Local Static $PreRunMinisterialCommendations = $itemCounts[12]
	Local Static $PreRunJadeBracelets = $itemCounts[13]
	Local Static $PreRunChunksOfDrakeFlesh = $itemCounts[14]
	Local Static $PreRunSkaleFins = $itemCounts[15]
	Local Static $PreRunWintersdayGifts = $itemCounts[16]
	Local Static $PreRunTrickOrTreats = $itemCounts[17]
	Local Static $PreRunBirthdayCupcakes = $itemCounts[18]
	Local Static $PreRunGoldenEggs = $itemCounts[19]
	Local Static $PreRunPumpkinPieSlices = $itemCounts[20]
	Local Static $PreRunHoneyCombs = $itemCounts[21]
	Local Static $PreRunFruitCakes = $itemCounts[22]
	Local Static $PreRunSugaryBlueDrinks = $itemCounts[23]
	Local Static $PreRunChocolateBunnies = $itemCounts[24]
	Local Static $PreRunDeliciousCakes = $itemCounts[25]
	Local Static $PreRunAmberChunks = $itemCounts[26]
	Local Static $PreRunJadeiteShards = $itemCounts[27]

	Local Static $TotalEctos = 0
	Local Static $TotalObsidianShards = 0
	Local Static $TotalLockpicks = 0
	Local Static $TotalMargoniteGemstones = 0
	Local Static $TotalStygianGemstones = 0
	Local Static $TotalTitanGemstones = 0
	Local Static $TotalTormentGemstones = 0
	Local Static $TotalDiessaChalices = 0
	Local Static $TotalRinRelics = 0
	Local Static $TotalDestroyerCores = 0
	Local Static $TotalGlacialStones = 0
	Local Static $TotalWarSupplies = 0
	Local Static $TotalMinisterialCommendations = 0
	Local Static $TotalJadeBracelets = 0
	Local Static $TotalChunksOfDrakeFlesh = 0
	Local Static $TotalSkaleFins = 0
	Local Static $TotalWintersdayGifts = 0
	Local Static $TotalTrickOrTreats = 0
	Local Static $TotalBirthdayCupcakes = 0
	Local Static $TotalGoldenEggs = 0
	Local Static $TotalPumpkinPieSlices = 0
	Local Static $TotalHoneyCombs = 0
	Local Static $TotalFruitCakes = 0
	Local Static $TotalSugaryBlueDrinks = 0
	Local Static $TotalChocolateBunnies = 0
	Local Static $TotalDeliciousCakes = 0
	Local Static $TotalAmberChunks = 0
	Local Static $TotalJadeiteShards = 0

	; Items stats, including inventory management situations when some items got sold or stored in chest, to update counters accordingly
	; Counting income surplus of every item group after each finished run
	Local $runIncomeGold = GetGoldCharacter() - $PreRunGold
	Local $runIncomeGoldItems = $goldItemsCount - $PreRunGoldItems
	Local $runIncomeEctos = $itemCounts[0] - $PreRunEctos
	Local $runIncomeObsidianShards = $itemCounts[1] - $PreRunObsidianShards
	Local $runIncomeLockpicks = $itemCounts[2] - $PreRunLockpicks
	Local $runIncomeMargoniteGemstones = $itemCounts[3] - $PreRunMargoniteGemstones
	Local $runIncomeStygianGemstones = $itemCounts[4] - $PreRunStygianGemstones
	Local $runIncomeTitanGemstones = $itemCounts[5] - $PreRunTitanGemstones
	Local $runIncomeTormentGemstones = $itemCounts[6] - $PreRunTormentGemstones
	Local $runIncomeDiessaChalices = $itemCounts[7] - $PreRunDiessaChalices
	Local $runIncomeRinRelics = $itemCounts[8] - $PreRunRinRelics
	Local $runIncomeDestroyerCores = $itemCounts[9] - $PreRunDestroyerCores
	Local $runIncomeGlacialStones = $itemCounts[10] - $PreRunGlacialStones
	Local $runIncomeWarSupplies = $itemCounts[11] - $PreRunWarSupplies
	Local $runIncomeMinisterialCommendations = $itemCounts[12] - $PreRunMinisterialCommendations
	Local $runIncomeJadeBracelets = $itemCounts[13] - $PreRunJadeBracelets
	Local $runIncomeChunksOfDrakeFlesh = $itemCounts[14] - $PreRunChunksOfDrakeFlesh
	Local $runIncomeSkaleFins = $itemCounts[15] - $PreRunSkaleFins
	Local $runIncomeWintersdayGifts = $itemCounts[16] - $PreRunWintersdayGifts
	Local $runIncomeTrickOrTreats = $itemCounts[17] - $PreRunTrickOrTreats
	Local $runIncomeBirthdayCupcakes = $itemCounts[18] - $PreRunBirthdayCupcakes
	Local $runIncomeGoldenEggs = $itemCounts[19] - $PreRunGoldenEggs
	Local $runIncomePumpkinPieSlices = $itemCounts[20] - $PreRunPumpkinPieSlices
	Local $runIncomeHoneyCombs = $itemCounts[21] - $PreRunHoneyCombs
	Local $runIncomeFruitCakes = $itemCounts[22] - $PreRunFruitCakes
	Local $runIncomeSugaryBlueDrinks = $itemCounts[23] - $PreRunSugaryBlueDrinks
	Local $runIncomeChocolateBunnies = $itemCounts[24] - $PreRunChocolateBunnies
	Local $runIncomeDeliciousCakes = $itemCounts[25] - $PreRunDeliciousCakes
	Local $runIncomeAmberChunks = $itemCounts[26] - $PreRunAmberChunks
	Local $runIncomeJadeiteShards = $itemCounts[27] - $PreRunJadeiteShards

	; If income is positive then updating cumulative item stats. Income is negative when selling or storing items in chest
	If $runIncomeGold > 0 Then $TotalGold += $runIncomeGold
	If $runIncomeGoldItems > 0 Then $TotalGoldItems += $runIncomeGoldItems
	If $runIncomeEctos > 0 Then $TotalEctos += $runIncomeEctos
	If $runIncomeObsidianShards > 0 Then $TotalObsidianShards += $runIncomeObsidianShards
	If $runIncomeLockpicks > 0 Then $TotalLockpicks += $runIncomeLockpicks
	If $runIncomeMargoniteGemstones > 0 Then $TotalMargoniteGemstones += $runIncomeMargoniteGemstones
	If $runIncomeStygianGemstones > 0 Then $TotalStygianGemstones += $runIncomeStygianGemstones
	If $runIncomeTitanGemstones > 0 Then $TotalTitanGemstones += $runIncomeTitanGemstones
	If $runIncomeTormentGemstones > 0 Then $TotalTormentGemstones += $runIncomeTormentGemstones
	If $runIncomeDiessaChalices > 0 Then $TotalDiessaChalices += $runIncomeDiessaChalices
	If $runIncomeRinRelics > 0 Then $TotalRinRelics += $runIncomeRinRelics
	If $runIncomeDestroyerCores > 0 Then $TotalDestroyerCores += $runIncomeDestroyerCores
	If $runIncomeGlacialStones > 0 Then $TotalGlacialStones += $runIncomeGlacialStones
	If $runIncomeWarSupplies > 0 Then $TotalWarSupplies += $runIncomeWarSupplies
	If $runIncomeMinisterialCommendations > 0 Then $TotalMinisterialCommendations += $runIncomeMinisterialCommendations
	If $runIncomeJadeBracelets > 0 Then $TotalJadeBracelets += $runIncomeJadeBracelets
	If $runIncomeChunksOfDrakeFlesh > 0 Then $TotalChunksOfDrakeFlesh += $runIncomeChunksOfDrakeFlesh
	If $runIncomeSkaleFins > 0 Then $TotalSkaleFins += $runIncomeSkaleFins
	If $runIncomeWintersdayGifts > 0 Then $TotalWintersdayGifts += $runIncomeWintersdayGifts
	If $runIncomeTrickOrTreats > 0 Then $TotalTrickOrTreats += $runIncomeTrickOrTreats
	If $runIncomeBirthdayCupcakes > 0 Then $TotalBirthdayCupcakes += $runIncomeBirthdayCupcakes
	If $runIncomeGoldenEggs > 0 Then $TotalGoldenEggs += $runIncomeGoldenEggs
	If $runIncomePumpkinPieSlices > 0 Then $TotalPumpkinPieSlices += $runIncomePumpkinPieSlices
	If $runIncomeHoneyCombs > 0 Then $TotalHoneyCombs += $runIncomeHoneyCombs
	If $runIncomeFruitCakes > 0 Then $TotalFruitCakes += $runIncomeFruitCakes
	If $runIncomeSugaryBlueDrinks > 0 Then $TotalSugaryBlueDrinks += $runIncomeSugaryBlueDrinks
	If $runIncomeChocolateBunnies > 0 Then $TotalChocolateBunnies += $runIncomeChocolateBunnies
	If $runIncomeDeliciousCakes > 0 Then $TotalDeliciousCakes += $runIncomeDeliciousCakes
	If $runIncomeAmberChunks > 0 Then $TotalAmberChunks += $runIncomeAmberChunks
	If $runIncomeJadeiteShards > 0 Then $TotalJadeiteShards += $runIncomeJadeiteShards

	; updating GUI labels with cumulative items counters
	GUICtrlSetData($GUI_Label_Gold_Value, Floor($TotalGold/1000) & 'k' & Mod($TotalGold, 1000) & 'g')
	GUICtrlSetData($GUI_Label_GoldItems_Value, $TotalGoldItems)
	GUICtrlSetData($GUI_Label_Ectos_Value, $TotalEctos)
	GUICtrlSetData($GUI_Label_ObsidianShards_Value, $TotalObsidianShards)
	GUICtrlSetData($GUI_Label_Lockpicks_Value, $TotalLockpicks)
	GUICtrlSetData($GUI_Label_MargoniteGemstone_Value, $TotalMargoniteGemstones)
	GUICtrlSetData($GUI_Label_StygianGemstone_Value, $TotalStygianGemstones)
	GUICtrlSetData($GUI_Label_TitanGemstone_Value, $TotalTitanGemstones)
	GUICtrlSetData($GUI_Label_TormentGemstone_Value, $TotalTormentGemstones)
	GUICtrlSetData($GUI_Label_DiessaChalices_Value, $TotalDiessaChalices)
	GUICtrlSetData($GUI_Label_RinRelics_Value, $TotalRinRelics)
	GUICtrlSetData($GUI_Label_DestroyerCores_Value, $TotalDestroyerCores)
	GUICtrlSetData($GUI_Label_GlacialStones_Value, $TotalGlacialStones)
	GUICtrlSetData($GUI_Label_WarSupplies_Value, $TotalWarSupplies)
	GUICtrlSetData($GUI_Label_MinisterialCommendations_Value, $TotalMinisterialCommendations)
	GUICtrlSetData($GUI_Label_JadeBracelets_Value, $TotalJadeBracelets)
	GUICtrlSetData($GUI_Label_ChunksOfDrakeFlesh_Value, $TotalChunksOfDrakeFlesh)
	GUICtrlSetData($GUI_Label_SkaleFins_Value, $TotalSkaleFins)
	GUICtrlSetData($GUI_Label_WintersdayGifts_Value, $TotalWintersdayGifts)
	GUICtrlSetData($GUI_Label_TrickOrTreats_Value, $TotalTrickOrTreats)
	GUICtrlSetData($GUI_Label_BirthdayCupcakes_Value, $TotalBirthdayCupcakes)
	GUICtrlSetData($GUI_Label_GoldenEggs_Value, $TotalGoldenEggs)
	GUICtrlSetData($GUI_Label_PumpkinPieSlices_Value, $TotalPumpkinPieSlices)
	GUICtrlSetData($GUI_Label_HoneyCombs_Value, $TotalHoneyCombs)
	GUICtrlSetData($GUI_Label_FruitCakes_Value, $TotalFruitCakes)
	GUICtrlSetData($GUI_Label_SugaryBlueDrinks_Value, $TotalSugaryBlueDrinks)
	GUICtrlSetData($GUI_Label_ChocolateBunnies_Value, $TotalChocolateBunnies)
	GUICtrlSetData($GUI_Label_DeliciousCakes_Value, $TotalDeliciousCakes)
	GUICtrlSetData($GUI_Label_AmberChunks_Value, $TotalAmberChunks)
	GUICtrlSetData($GUI_Label_JadeiteShards_Value, $TotalJadeiteShards)

	; resetting items counters to count income surplus for the next run
	$PreRunGold = GetGoldCharacter()
	$PreRunGoldItems = $goldItemsCount
	$PreRunEctos = $itemCounts[0]
	$PreRunObsidianShards = $itemCounts[1]
	$PreRunLockpicks = $itemCounts[2]
	$PreRunMargoniteGemstones = $itemCounts[3]
	$PreRunStygianGemstones = $itemCounts[4]
	$PreRunTitanGemstones = $itemCounts[5]
	$PreRunTormentGemstones = $itemCounts[6]
	$PreRunDiessaChalices = $itemCounts[7]
	$PreRunRinRelics = $itemCounts[8]
	$PreRunDestroyerCores = $itemCounts[9]
	$PreRunGlacialStones = $itemCounts[10]
	$PreRunWarSupplies = $itemCounts[11]
	$PreRunMinisterialCommendations = $itemCounts[12]
	$PreRunJadeBracelets = $itemCounts[13]
	$PreRunChunksOfDrakeFlesh = $itemCounts[14]
	$PreRunSkaleFins = $itemCounts[15]
	$PreRunWintersdayGifts = $itemCounts[16]
	$PreRunTrickOrTreats = $itemCounts[17]
	$PreRunBirthdayCupcakes = $itemCounts[18]
	$PreRunGoldenEggs = $itemCounts[19]
	$PreRunPumpkinPieSlices = $itemCounts[20]
	$PreRunHoneyCombs = $itemCounts[21]
	$PreRunFruitCakes = $itemCounts[22]
	$PreRunSugaryBlueDrinks = $itemCounts[23]
	$PreRunChocolateBunnies = $itemCounts[24]
	$PreRunDeliciousCakes = $itemCounts[25]
	$PreRunAmberChunks = $itemCounts[26]
	$PreRunJadeiteShards = $itemCounts[27]
EndFunc


;~ Select correct farm duration
Func SelectFarmDuration($Farm)
	Switch $Farm
		Case 'Asuran'
			Return $ASURAN_FARM_DURATION
		Case 'Boreal'
			Return $BOREAL_FARM_DURATION
		Case 'CoF'
			Return $COF_FARM_DURATION
		Case 'Corsairs'
			Return $CORSAIRS_FARM_DURATION
		Case 'Dragon Moss'
			Return $DRAGONMOSS_FARM_DURATION
		Case 'Eden Iris'
			Return $IRIS_FARM_DURATION
		Case 'Feathers'
			Return $FEATHERS_FARM_DURATION
		Case 'Follower'
			Return 30 * 60 * 1000
		Case 'FoW'
			Return $FOW_FARM_DURATION
		Case 'FoW Tower of Courage'
			Return $FOW_TOC_FARM_DURATION
		Case 'Gemstones'
			Return $GEMSTONES_FARM_DURATION
		Case 'Gemstone Margonite'
			Return $GEMSTONE_MARGONITE_FARM_DURATION
		Case 'Gemstone Stygian'
			Return $GEMSTONE_STYGIAN_FARM_DURATION
		Case 'Gemstone Torment'
			Return $GEMSTONE_TORMENT_FARM_DURATION
		Case 'Glint Challenge'
			Return $GLINT_CHALLENGE_DURATION
		Case 'Jade Brotherhood'
			Return $JADEBROTHERHOOD_FARM_DURATION
		Case 'Kilroy'
			Return $KILROY_FARM_DURATION
		Case 'Kournans'
			Return $KOURNANS_FARM_DURATION
		Case 'Kurzick'
			Return $KURZICKS_FARM_DURATION
		Case 'LDOA'
			Return $LDOA_FARM_DURATION
		Case 'Lightbringer'
			Return $LIGHTBRINGER_FARM_DURATION
		Case 'Lightbringer 2'
			Return $LIGHTBRINGER_FARM2_DURATION
		Case 'Luxon'
			Return $LUXONS_FARM_DURATION
		Case 'Mantids'
			Return $MANTIDS_FARM_DURATION
		Case 'Ministerial Commendations'
			Return $COMMENDATIONS_FARM_DURATION
		Case 'Minotaurs'
			Return $MINOTAURS_FARM_DURATION
		Case 'Nexus Challenge'
			Return $NEXUS_CHALLENGE_FARM_DURATION
		Case 'Norn'
			Return $NORN_FARM_DURATION
		Case 'OmniFarm'
			Return 5 * 60 * 1000
		Case 'Pongmei'
			Return $PONGMEI_FARM_DURATION
		Case 'Raptors'
			Return $RAPTORS_FARM_DURATION
		Case 'SpiritSlaves'
			Return $SPIRIT_SLAVES_FARM_DURATION
		Case 'Sunspear Armor'
			Return $SUNSPEAR_ARMOR_FARM_DURATION
		Case 'Tasca'
			Return $TASCA_FARM_DURATION
		Case 'Underworld'
			Return $UW_FARM_DURATION
		Case 'Vaettirs'
			Return $VAETTIRS_FARM_DURATION
		Case 'Vanguard'
			Return $VANGUARD_TITLE_FARM_DURATION
		Case 'Voltaic'
			Return $VOLTAIC_FARM_DURATION
		Case 'War Supply Keiran'
			Return $WAR_SUPPLY_FARM_DURATION
		Case 'Storage'
			Return 2 * 60 * 1000
		Case Else
			Return 2 * 60 * 1000
	EndSwitch

EndFunc
#EndRegion Statistics management