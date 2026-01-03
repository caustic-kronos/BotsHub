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

; GUI built with GuiBuilderPlus

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

#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <ComboConstants.au3>
#include <GuiTab.au3>
#include <GuiRichEdit.au3>
#include <GuiTreeView.au3>
#include <Math.au3>

#include 'lib/GWA2_Headers.au3'
#include 'lib/GWA2_ID.au3'
#include 'lib/GWA2.au3'
#include 'lib/Utils.au3'
#include 'lib/Utils-Debugger.au3'
#include 'lib/Utils-OmniFarmer.au3'
#include 'lib/Utils-Storage-Bot.au3'
#include 'src/Farm-Asuran.au3'
#include 'src/Farm-Boreal.au3'
#include 'src/Farm-Corsairs.au3'
#include 'src/Farm-DragonMoss.au3'
#include 'src/Farm-EdenIris.au3'
#include 'src/Farm-Feathers.au3'
#include 'src/Farm-Follower.au3'
#include 'src/Farm-FoW.au3'
#include 'src/Farm-FoWTowerOfCourage.au3'
#include 'src/Farm-Froggy.au3'
#include 'src/Farm-Gemstones.au3'
#include 'src/Farm-GemstoneMargonite.au3'
#include 'src/Farm-GemstoneStygian.au3'
#include 'src/Farm-GemstoneTorment.au3'
#include 'src/Farm-GlintChallenge.au3'
#include 'src/Farm-JadeBrotherhood.au3'
#include 'src/Farm-Kournans.au3'
#include 'src/Farm-Kurzick.au3'
#include 'src/Farm-Lightbringer.au3'
#include 'src/Farm-Lightbringer2.au3'
#include 'src/Farm-Luxon.au3'
#include 'src/Farm-Mantids.au3'
#include 'src/Farm-MinisterialCommendations.au3'
#include 'src/Farm-Minotaurs.au3'
#include 'src/Farm-NexusChallenge.au3'
#include 'src/Farm-Norn.au3'
#include 'src/Farm-Pongmei.au3'
#include 'src/Farm-Raptors.au3'
#include 'src/Farm-SoO.au3'
#include 'src/Farm-SpiritSlaves.au3'
#include 'src/Farm-SunspearArmor.au3'
#include 'src/Farm-Tasca.au3'
#include 'src/Farm-TestSuite.au3'
#include 'src/Farm-Underworld.au3'
#include 'src/Farm-Vaettirs.au3'
#include 'src/Farm-Vanguard.au3'
#include 'src/Farm-Voltaic.au3'
#include 'src/Farm-WarSupplyKeiran.au3'

#include 'lib/JSON.au3'
#EndRegion Includes

#Region Variables
Global Const $GW_BOT_HUB_VERSION = '2.0'

Global Const $LVL_DEBUG = 0
Global Const $LVL_INFO = 1
Global Const $LVL_NOTICE = 2
Global Const $LVL_WARNING = 3
Global Const $LVL_ERROR = 4

Global Const $GUI_WM_COMMAND = 0x0111
Global Const $GUI_COMBOBOX_DROPDOWN_OPENED = 7

; -1 = did not start, 0 = ran fine, 1 = failed, 2 = pause
Global Const $NOT_STARTED = -1
Global Const $SUCCESS = 0
Global Const $FAIL = 1
Global Const $PAUSE = 2
Global Const $STUCK = 3

; UNINITIALIZED -> INITIALIZED -> RUNNING -> WILL_PAUSE -> PAUSED -> RUNNING
Global $STATUS = 'UNINITIALIZED'
Global $RUN_MODE = 'AUTOLOAD'
Global $PROCESS_ID = ''
Global $LOG_LEVEL = $LVL_INFO
Global $CHARACTER_NAME = ''
Global $DISTRICT_NAME = 'Random'
Global $BAGS_COUNT = 5
Global $WEAPON_SLOT = 1
Global $INVENTORY_SPACE_NEEDED = 5
Global $RUN_TIMER = Null ; global variable to measure elapsed time of farm run

Global $AVAILABLE_FARMS = '|Asuran|Boreal|Corsairs|Dragon Moss|Eden Iris|Feathers|Follower|FoW|FoW Tower of Courage|Froggy|Gemstones|Gemstone Margonite|Gemstone Stygian|Gemstone Torment|Glint Challenge|Jade Brotherhood|Kournans|Kurzick|Lightbringer|Lightbringer 2|Luxon|Mantids|Ministerial Commendations|Minotaurs|Nexus Challenge|Norn|OmniFarm|Pongmei|Raptors|SoO|SpiritSlaves|Sunspear Armor|Tasca|Underworld|Vaettirs|Vanguard|Voltaic|War Supply Keiran|Storage|Tests|TestSuite|Dynamic execution'
Global $AVAILABLE_DISTRICTS = '|Random|America|China|English|French|German|International|Italian|Japan|Korea|Polish|Russian|Spanish'
Global $AVAILABLE_BAG_COUNTS = '|1|2|3|4|5'
Global $AVAILABLE_WEAPON_SLOTS = '|1|2|3|4'
Global $AVAILABLE_HEROES = '|Norgu|Goren|Tahlkora|Master of Whispers|Acolyte Jin|Koss|Dunkoro|Acolyte Sousuke|Melonni|Zhed Shadowhoof|General Morgahn|Margrid the Sly|Zenmai|Olias|Razah|MOX|Keiran Thackeray|Jora|Pyre Fierceshot|Anton|Livia|Hayda|Kahmu|Gwen|Xandra|Vekk|Ogden|Miku|ZeiRi|Mercenary Hero 1|Mercenary Hero 2|Mercenary Hero 3|Mercenary Hero 4|Mercenary Hero 5|Mercenary Hero 6|Mercenary Hero 7|Mercenary Hero 8'
#EndRegion Variables


#Region GUI
Opt('GUIOnEventMode', True)
Opt('GUICloseOnESC', False)
Opt('MustDeclareVars', True)

Global $GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_Tab_Main, $GUI_Tab_RunOptions, $GUI_Tab_LootOptions, $GUI_Tab_FarmInfos, $GUI_Tab_LootOptions, $GUI_Tab_TeamOptions
Global $GUI_Console, $GUI_Combo_CharacterChoice, $GUI_Combo_FarmChoice, $GUI_StartButton, $GUI_FarmProgress
Global $GUI_Label_DynamicExecution, $GUI_Input_DynamicExecution, $GUI_Button_DynamicExecution, $GUI_RenderButton, $GUI_RenderLabel, _
		$GUI_Label_BagsCount, $GUI_Combo_BagsCount, $GUI_Label_TravelDistrict, $GUI_Combo_DistrictChoice, _
		$GUI_Checkbox_WeaponSlot, $GUI_Combo_WeaponSlot, $GUI_Icon_SaveConfig, $GUI_Combo_ConfigChoice

Global $GUI_Group_RunInfos, _
		$GUI_Label_Runs_Text, $GUI_Label_Runs_Value, $GUI_Label_Successes_Text, $GUI_Label_Successes_Value, $GUI_Label_Failures_Text, $GUI_Label_Failures_Value, $GUI_Label_SuccessRatio_Text, $GUI_Label_SuccessRatio_Value, _
		$GUI_Label_Time_Text, $GUI_Label_Time_Value, $GUI_Label_TimePerRun_Text, $GUI_Label_TimePerRun_Value, $GUI_Label_Experience_Text, $GUI_Label_Experience_Value, $GUI_Label_Chests_Text, $GUI_Label_Chests_Value, _
		$GUI_Label_Gold_Text, $GUI_Label_Gold_Value, $GUI_Label_GoldItems_Text, $GUI_Label_GoldItems_Value, $GUI_Label_Ectos_Text, $GUI_Label_Ectos_Value, $GUI_Label_ObsidianShards_Text, $GUI_Label_ObsidianShards_Value
Global $GUI_Group_ItemsLooted, _
		$GUI_Label_Lockpicks_Text, $GUI_Label_Lockpicks_Value, $GUI_Label_JadeBracelets_Text, $GUI_Label_JadeBracelets_Value, _
		$GUI_Label_GlacialStones_Text, $GUI_Label_GlacialStones_Value, $GUI_Label_DestroyerCores_Text, $GUI_Label_DestroyerCores_Value, _
		$GUI_Label_DiessaChalices_Text, $GUI_Label_DiessaChalices_Value, $GUI_Label_RinRelics_Text, $GUI_Label_RinRelics_Value, _
		$GUI_Label_WarSupplies_Text, $GUI_Label_WarSupplies_Value, $GUI_Label_MinisterialCommendations_Text, $GUI_Label_MinisterialCommendations_Value, _
		$GUI_Label_ChunksOfDrakeFlesh_Text, $GUI_Label_ChunksOfDrakeFlesh_Value, $GUI_Label_SkaleFins_Text, $GUI_Label_SkaleFins_Value, _
		$GUI_Label_WintersdayGifts_Text, $GUI_Label_WintersdayGifts_Value, $GUI_Label_DeliciousCakes_Text, $GUI_Label_DeliciousCakes_Value, _
		$GUI_Label_MargoniteGemstone_Text, $GUI_Label_MargoniteGemstone_Value, $GUI_Label_StygianGemstone_Text, $GUI_Label_StygianGemstone_Value, _
		$GUI_Label_TitanGemstone_Text, $GUI_Label_TitanGemstone_Value, $GUI_Label_TormentGemstone_Text, $GUI_Label_TormentGemstone_Value, _
		$GUI_Label_TrickOrTreats_Text, $GUI_Label_TrickOrTreats_Value, $GUI_Label_BirthdayCupcakes_Text, $GUI_Label_BirthdayCupcakes_Value, _
		$GUI_Label_GoldenEggs_Text, $GUI_Label_GoldenEggs_Value, $GUI_Label_PumpkinPieSlices_Text, $GUI_Label_PumpkinPieSlices_Value, _
		$GUI_Label_HoneyCombs_Text, $GUI_Label_HoneyCombs_Value, $GUI_Label_FruitCakes_Text, $GUI_Label_FruitCakes_Value, _
		$GUI_Label_SugaryBlueDrinks_Text, $GUI_Label_SugaryBlueDrinks_Value, $GUI_Label_ChocolateBunnies_Text, $GUI_Label_ChocolateBunnies_Value, _
		$GUI_Label_AmberChunks_Text, $GUI_Label_AmberChunks_Value, $GUI_Label_JadeiteShards_Text, $GUI_Label_JadeiteShards_Value
Global $GUI_Group_Titles, _
		$GUI_Label_AsuraTitle_Text, $GUI_Label_AsuraTitle_Value, $GUI_Label_DeldrimorTitle_Text, $GUI_Label_DeldrimorTitle_Value, $GUI_Label_NornTitle_Text, $GUI_Label_NornTitle_Value, _
		$GUI_Label_VanguardTitle_Text, $GUI_Label_VanguardTitle_Value, $GUI_Label_KurzickTitle_Text, $GUI_Label_KurzickTitle_Value, $GUI_Label_LuxonTitle_Text, $GUI_Label_LuxonTitle_Value, _
		$GUI_Label_LightbringerTitle_Text, $GUI_Label_LightbringerTitle_Value, $GUI_Label_SunspearTitle_Text, $GUI_Label_SunspearTitle_Value
Global $GUI_Group_RunOptions, _
		$GUI_Checkbox_LoopRuns, $GUI_Checkbox_HardMode, $GUI_Checkbox_AutomaticTeamSetup, $GUI_Checkbox_UseConsumables, $GUI_Checkbox_UseScrolls
Global $GUI_Group_ItemOptions, _
		$GUI_Checkbox_StoreUnidentifiedGoldItems, $GUI_Checkbox_SortItems, $GUI_Checkbox_StoreTheRest, $GUI_Checkbox_StoreGold, _
		$GUI_Checkbox_BuyEctoplasm, $GUI_Checkbox_BuyObsidian, $GUI_Checkbox_CollectData, $GUI_Checkbox_FarmMaterialsMidRun
Global $GUI_Group_FactionOptions, $GUI_Label_Faction, $GUI_RadioButton_DonatePoints, $GUI_RadioButton_BuyFactionResources, $GUI_RadioButton_BuyFactionScrolls
Global $GUI_Group_TeamOptions, $GUI_TeamLabel, $GUI_TeamMemberLabel, $GUI_TeamMemberBuildLabel, _
		$GUI_Label_Hero_1, $GUI_Label_Hero_2, $GUI_Label_Hero_3, $GUI_Label_Hero_4, $GUI_Label_Hero_5, $GUI_Label_Hero_6, $GUI_Label_Hero_7, _
		$GUI_Label_Player, $GUI_Combo_Hero_1, $GUI_Combo_Hero_2, $GUI_Combo_Hero_3, $GUI_Combo_Hero_4, $GUI_Combo_Hero_5, $GUI_Combo_Hero_6, $GUI_Combo_Hero_7, _
		$GUI_Label_Build_Hero_1, $GUI_Label_Build_Hero_2, $GUI_Label_Build_Hero_3, $GUI_Label_Build_Hero_4, $GUI_Label_Build_Hero_5, $GUI_Label_Build_Hero_6, $GUI_Label_Build_Hero_7, _
		$GUI_Input_Build_Player, $GUI_Input_Build_Hero_1, $GUI_Input_Build_Hero_2, $GUI_Input_Build_Hero_3, $GUI_Input_Build_Hero_4, $GUI_Input_Build_Hero_5, $GUI_Input_Build_Hero_6, $GUI_Input_Build_Hero_7
Global $GUI_Group_OtherOptions
Global $GUI_Label_CharacterBuilds, $GUI_Label_HeroesBuilds, $GUI_Edit_CharacterBuilds, $GUI_Edit_HeroesBuilds, $GUI_Label_FarmInformations
Global $GUI_TreeView_LootOptions, $GUI_JSON_LootOptions, $GUI_ExpandLootOptionsButton, $GUI_ReduceLootOptionsButton, $GUI_LoadLootOptionsButton, $GUI_SaveLootOptionsButton, $GUI_ApplyLootOptionsButton
Global $GUI_Label_ToDoList


;------------------------------------------------------
; Title...........:	_guiCreate
; Description.....:	Create the main GUI
;------------------------------------------------------
Func createGUI()
	$GUI_GWBotHub = GUICreate('GW Bot Hub', 650, 500, -1, -1) ; -1, -1 automatically positions GUI in the middle of the screen, alternatively can do calculations with inbuilt @DesktopWidth and @DesktopHeight
	GUISetBkColor($COLOR_SILVER, $GUI_GWBotHub)

	$GUI_Combo_CharacterChoice = GUICtrlCreateCombo('No character selected', 10, 470, 150, 20)
	$GUI_Combo_FarmChoice = GUICtrlCreateCombo('Choose a farm', 170, 470, 150, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_FarmChoice, $AVAILABLE_FARMS, 'Choose a farm')
	GUICtrlSetOnEvent($GUI_Combo_FarmChoice, 'GuiButtonHandler')
	$GUI_StartButton = GUICtrlCreateButton('Start', 330, 470, 150, 21)
	GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTBLUE)
	GUICtrlSetOnEvent($GUI_StartButton, 'GuiButtonHandler')
	GUISetOnEvent($GUI_EVENT_CLOSE, 'GuiButtonHandler')
	$GUI_FarmProgress = GUICtrlCreateProgress(490, 470, 150, 21)

	$GUI_Tabs_Parent = GUICtrlCreateTab(10, 10, 630, 450)
	$GUI_Tab_Main = GUICtrlCreateTabItem('Main')
	GUICtrlSetOnEvent($GUI_Tabs_Parent, 'GuiButtonHandler')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $COLOR_SILVER)

	$GUI_Console = _GUICtrlRichEdit_Create($GUI_GWBotHub, '', 20, 190, 300, 255, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	_GUICtrlRichEdit_SetCharColor($GUI_Console, $COLOR_WHITE)
	_GUICtrlRichEdit_SetBkColor($GUI_Console, $COLOR_BLACK)

	; === Run Infos ===
	$GUI_Group_RunInfos = GUICtrlCreateGroup('Informations', 21, 39, 300, 145)
	$GUI_Label_Runs_Text = GUICtrlCreateLabel('Runs:', 31, 64, 65, 16)
	$GUI_Label_Runs_Value = GUICtrlCreateLabel('0', 110, 64, 50, 16, $SS_RIGHT)
	$GUI_Label_Successes_Text = GUICtrlCreateLabel('Successes:', 31, 84, 65, 16)
	$GUI_Label_Successes_Value = GUICtrlCreateLabel('0', 110, 84, 50, 16, $SS_RIGHT)
	$GUI_Label_Failures_Text = GUICtrlCreateLabel('Failures:', 31, 104, 65, 16)
	$GUI_Label_Failures_Value = GUICtrlCreateLabel('0', 110, 104, 50, 16, $SS_RIGHT)
	$GUI_Label_SuccessRatio_Text = GUICtrlCreateLabel('Success Ratio:', 31, 124, 85, 16)
	$GUI_Label_SuccessRatio_Value = GUICtrlCreateLabel('0', 110, 124, 50, 16, $SS_RIGHT)
	$GUI_Label_Time_Text = GUICtrlCreateLabel('Time:', 31, 144, 45, 16)
	$GUI_Label_Time_Value = GUICtrlCreateLabel('0', 90, 144, 70, 16, $SS_RIGHT)
	$GUI_Label_TimePerRun_Text = GUICtrlCreateLabel('Time per run:', 31, 164, 65, 16)
	$GUI_Label_TimePerRun_Value = GUICtrlCreateLabel('0', 110, 164, 50, 16, $SS_RIGHT)

	$GUI_Label_Experience_Text = GUICtrlCreateLabel('Experience:', 180, 64, 65, 16)
	$GUI_Label_Experience_Value = GUICtrlCreateLabel('0', 260, 64, 50, 16, $SS_RIGHT)
	$GUI_Label_Chests_Text = GUICtrlCreateLabel('Chests:', 180, 84, 65, 16)
	$GUI_Label_Chests_Value = GUICtrlCreateLabel('0', 260, 84, 50, 16, $SS_RIGHT)
	$GUI_Label_Gold_Text = GUICtrlCreateLabel('Gold:', 180, 104, 65, 16)
	$GUI_Label_Gold_Value = GUICtrlCreateLabel('0', 260, 104, 50, 16, $SS_RIGHT)
	$GUI_Label_GoldItems_Text = GUICtrlCreateLabel('Gold Items:', 180, 124, 65, 16)
	$GUI_Label_GoldItems_Value = GUICtrlCreateLabel('0', 260, 124, 50, 16, $SS_RIGHT)
	$GUI_Label_Ectos_Text = GUICtrlCreateLabel('Ectos:', 180, 144, 65, 16)
	$GUI_Label_Ectos_Value = GUICtrlCreateLabel('0', 260, 144, 50, 16, $SS_RIGHT)
	$GUI_Label_ObsidianShards_Text = GUICtrlCreateLabel('Obsidian Shards:', 180, 164, 85, 16)
	$GUI_Label_ObsidianShards_Value = GUICtrlCreateLabel('0', 260, 164, 50, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	; === Items Looted ===
	$GUI_Group_ItemsLooted = GUICtrlCreateGroup('Items collected', 330, 39, 295, 290)
	$GUI_Label_Lockpicks_Text = GUICtrlCreateLabel('Lockpicks:', 341, 64, 140, 16)
	$GUI_Label_Lockpicks_Value = GUICtrlCreateLabel('0', 425, 64, 60, 16, $SS_RIGHT)
	$GUI_Label_MargoniteGemstone_Text = GUICtrlCreateLabel('Margonite Gemstones:', 341, 84, 140, 16)
	$GUI_Label_MargoniteGemstone_Value = GUICtrlCreateLabel('0', 425, 84, 60, 16, $SS_RIGHT)
	$GUI_Label_StygianGemstone_Text = GUICtrlCreateLabel('Stygian Gemstones:', 341, 104, 140, 16)
	$GUI_Label_StygianGemstone_Value = GUICtrlCreateLabel('0', 425, 104, 60, 16, $SS_RIGHT)
	$GUI_Label_TitanGemstone_Text = GUICtrlCreateLabel('Titan Gemstones:', 341, 124, 140, 16)
	$GUI_Label_TitanGemstone_Value = GUICtrlCreateLabel('0', 425, 124, 60, 16, $SS_RIGHT)
	$GUI_Label_TormentGemstone_Text = GUICtrlCreateLabel('Torment Gemstones:', 341, 144, 140, 16)
	$GUI_Label_TormentGemstone_Value = GUICtrlCreateLabel('0', 425, 144, 60, 16, $SS_RIGHT)
	$GUI_Label_GlacialStones_Text = GUICtrlCreateLabel('Glacial Stones:', 341, 164, 140, 16)
	$GUI_Label_GlacialStones_Value = GUICtrlCreateLabel('0', 425, 164, 60, 16, $SS_RIGHT)
	$GUI_Label_DestroyerCores_Text = GUICtrlCreateLabel('Destroyer Cores:', 341, 184, 140, 16)
	$GUI_Label_DestroyerCores_Value = GUICtrlCreateLabel('0', 425, 184, 60, 16, $SS_RIGHT)
	$GUI_Label_DiessaChalices_Text = GUICtrlCreateLabel('Diessa Chalices:', 341, 204, 140, 16)
	$GUI_Label_DiessaChalices_Value = GUICtrlCreateLabel('0', 425, 204, 60, 16, $SS_RIGHT)
	$GUI_Label_RinRelics_Text = GUICtrlCreateLabel('Rin Relics:', 341, 224, 140, 16)
	$GUI_Label_RinRelics_Value = GUICtrlCreateLabel('0', 425, 224, 60, 16, $SS_RIGHT)
	$GUI_Label_WarSupplies_Text = GUICtrlCreateLabel('War Supplies:', 341, 244, 140, 16)
	$GUI_Label_WarSupplies_Value = GUICtrlCreateLabel('0', 425, 244, 60, 16, $SS_RIGHT)
	$GUI_Label_MinisterialCommendations_Text = GUICtrlCreateLabel('Ministerial Commendations:', 341, 264, 140, 16)
	$GUI_Label_MinisterialCommendations_Value = GUICtrlCreateLabel('0', 425, 264, 60, 16, $SS_RIGHT)
	$GUI_Label_JadeBracelets_Text = GUICtrlCreateLabel('Jade Bracelets:', 341, 284, 140, 16)
	$GUI_Label_JadeBracelets_Value = GUICtrlCreateLabel('0', 425, 284, 60, 16, $SS_RIGHT)
	$GUI_Label_JadeiteShards_Text = GUICtrlCreateLabel('Jadeite Shards:', 341, 304, 140, 16)
	$GUI_Label_JadeiteShards_Value = GUICtrlCreateLabel('0', 425, 304, 60, 16, $SS_RIGHT)

	$GUI_Label_ChunksOfDrakeFlesh_Text = GUICtrlCreateLabel('Drake Flesh Chunks:', 495, 64, 140, 16)
	$GUI_Label_ChunksOfDrakeFlesh_Value = GUICtrlCreateLabel('0', 558, 64, 60, 16, $SS_RIGHT)
	$GUI_Label_SkaleFins_Text = GUICtrlCreateLabel('Skale Fins:', 495, 84, 140, 16)
	$GUI_Label_SkaleFins_Value = GUICtrlCreateLabel('0', 558, 84, 60, 16, $SS_RIGHT)
	$GUI_Label_WintersdayGifts_Text = GUICtrlCreateLabel('Wintersday Gifts:', 495, 104, 140, 16)
	$GUI_Label_WintersdayGifts_Value = GUICtrlCreateLabel('0', 558, 104, 60, 16, $SS_RIGHT)
	$GUI_Label_BirthdayCupcakes_Text = GUICtrlCreateLabel('Birthday Cupcakes:', 495, 124, 140, 16)
	$GUI_Label_BirthdayCupcakes_Value = GUICtrlCreateLabel('0', 558, 124, 60, 16, $SS_RIGHT)
	$GUI_Label_TrickOrTreats_Text = GUICtrlCreateLabel('Trick or Treat Bags:', 495, 144, 140, 16)
	$GUI_Label_TrickOrTreats_Value = GUICtrlCreateLabel('0', 558, 144, 60, 16, $SS_RIGHT)
	$GUI_Label_PumpkinPieSlices_Text = GUICtrlCreateLabel('Slices of Pumpkin Pie:', 495, 164, 140, 16)
	$GUI_Label_PumpkinPieSlices_Value = GUICtrlCreateLabel('0', 558, 164, 60, 16, $SS_RIGHT)
	$GUI_Label_GoldenEggs_Text = GUICtrlCreateLabel('Golden Eggs:', 495, 184, 140, 16)
	$GUI_Label_GoldenEggs_Value = GUICtrlCreateLabel('0', 558, 184, 60, 16, $SS_RIGHT)
	$GUI_Label_HoneyCombs_Text = GUICtrlCreateLabel('Honey Combs:', 495, 204, 140, 16)
	$GUI_Label_HoneyCombs_Value = GUICtrlCreateLabel('0', 558, 204, 60, 16, $SS_RIGHT)
	$GUI_Label_FruitCakes_Text = GUICtrlCreateLabel('Fruit Cakes:', 495, 224, 140, 16)
	$GUI_Label_FruitCakes_Value = GUICtrlCreateLabel('0', 558, 224, 60, 16, $SS_RIGHT)
	$GUI_Label_SugaryBlueDrinks_Text = GUICtrlCreateLabel('Sugary Blue Drinks:', 495, 244, 140, 16)
	$GUI_Label_SugaryBlueDrinks_Value = GUICtrlCreateLabel('0', 558, 244, 60, 16, $SS_RIGHT)
	$GUI_Label_ChocolateBunnies_Text = GUICtrlCreateLabel('Chocolate Bunnies:', 495, 264, 140, 16)
	$GUI_Label_ChocolateBunnies_Value = GUICtrlCreateLabel('0', 558, 264, 60, 16, $SS_RIGHT)
	$GUI_Label_DeliciousCakes_Text = GUICtrlCreateLabel('Delicious Cakes:', 495, 284, 140, 16)
	$GUI_Label_DeliciousCakes_Value = GUICtrlCreateLabel('0', 558, 284, 60, 16, $SS_RIGHT)
	$GUI_Label_AmberChunks_Text = GUICtrlCreateLabel('Amber Chunks:', 495, 304, 140, 16)
	$GUI_Label_AmberChunks_Value = GUICtrlCreateLabel('0', 558, 304, 60, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	; === Titles ===
	$GUI_Group_Titles = GUICtrlCreateGroup('Titles', 330, 335, 295, 111)
	$GUI_Label_AsuraTitle_Text = GUICtrlCreateLabel('Asura:', 341, 360, 60, 16)
	$GUI_Label_AsuraTitle_Value = GUICtrlCreateLabel('0', 425, 360, 60, 16, $SS_RIGHT)
	$GUI_Label_DeldrimorTitle_Text = GUICtrlCreateLabel('Deldrimor:', 341, 380, 60, 16)
	$GUI_Label_DeldrimorTitle_Value = GUICtrlCreateLabel('0', 425, 380, 60, 16, $SS_RIGHT)
	$GUI_Label_NornTitle_Text = GUICtrlCreateLabel('Norn:', 341, 400, 60, 16)
	$GUI_Label_NornTitle_Value = GUICtrlCreateLabel('0', 425, 400, 60, 16, $SS_RIGHT)
	$GUI_Label_VanguardTitle_Text = GUICtrlCreateLabel('Vanguard:', 341, 420, 60, 16)
	$GUI_Label_VanguardTitle_Value = GUICtrlCreateLabel('0', 425, 420, 60, 16, $SS_RIGHT)

	$GUI_Label_KurzickTitle_Text = GUICtrlCreateLabel('Kurzick:', 495, 360, 60, 16)
	$GUI_Label_KurzickTitle_Value = GUICtrlCreateLabel('0', 558, 360, 60, 16, $SS_RIGHT)
	$GUI_Label_LuxonTitle_Text = GUICtrlCreateLabel('Luxon:', 495, 380, 60, 16)
	$GUI_Label_LuxonTitle_Value = GUICtrlCreateLabel('0', 558, 380, 60, 16, $SS_RIGHT)
	$GUI_Label_LightbringerTitle_Text = GUICtrlCreateLabel('Lightbringer:', 495, 400, 60, 16)
	$GUI_Label_LightbringerTitle_Value = GUICtrlCreateLabel('0', 558, 400, 60, 16, $SS_RIGHT)
	$GUI_Label_SunspearTitle_Text = GUICtrlCreateLabel('Sunspear:', 495, 420, 60, 16)
	$GUI_Label_SunspearTitle_Value = GUICtrlCreateLabel('0', 558, 420, 60, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	$GUI_Tab_RunOptions = GUICtrlCreateTabItem('Run options')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $COLOR_SILVER)

	$GUI_Group_RunOptions = GUICtrlCreateGroup('Run options', 21, 39, 295, 155)
	$GUI_Checkbox_LoopRuns = GUICtrlCreateCheckbox('Loop Runs', 31, 60)
	$GUI_Checkbox_HardMode = GUICtrlCreateCheckbox('Hard Mode', 31, 85)
	$GUI_Checkbox_FarmMaterialsMidRun = GUICtrlCreateCheckbox('Farm materials during runs to save inventory space', 31, 110)
	$GUI_Checkbox_UseConsumables = GUICtrlCreateCheckbox('Use consumables required by farm', 31, 135)
	$GUI_Checkbox_UseScrolls = GUICtrlCreateCheckbox('Use scrolls to enter elite zones (UW, FoW, etc.)', 31, 160)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_ItemOptions = GUICtrlCreateGroup('Items management options', 21, 205, 295, 235)
	$GUI_Checkbox_StoreUnidentifiedGoldItems = GUICtrlCreateCheckbox('Store unidentified gold items in chest', 31, 225)
	$GUI_Checkbox_SortItems = GUICtrlCreateCheckbox('Sort items before items management', 31, 255)
	$GUI_Checkbox_CollectData = GUICtrlCreateCheckbox('Collect data of obtained items into database', 31, 285)
	$GUI_Checkbox_StoreTheRest = GUICtrlCreateCheckbox('Store the rest of items in chest after items management', 31, 315)
	$GUI_Checkbox_StoreGold = GUICtrlCreateCheckbox('Store gold after items management', 31, 345)
	$GUI_Checkbox_BuyEctoplasm = GUICtrlCreateCheckbox('Buy globs of ectoplasm when having gold surplus', 31, 375)
	$GUI_Checkbox_BuyObsidian = GUICtrlCreateCheckbox('Buy obsidian shards when having gold surplus', 31, 405)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_FactionOptions = GUICtrlCreateGroup('Faction options', 330, 39, 295, 155)
	$GUI_Label_Faction = GUICtrlCreateLabel('Option on how to spend faction points earned in Kurzick/Luxon farms', 350, 60, 252, 40)
	$GUI_RadioButton_DonatePoints = GUICtrlCreateRadio('Donate Kurzick/Luxon faction points to alliance', 350, 100)
	$GUI_RadioButton_BuyFactionResources = GUICtrlCreateRadio('Buy Amber Chunks/Jadeite Shards resources', 350, 130)
	$GUI_RadioButton_BuyFactionScrolls = GUICtrlCreateRadio('Buy Urgoz''s Warren/The Deep Passage scrolls', 350, 160)
	GUICtrlSetState($GUI_RadioButton_DonatePoints, $GUI_CHECKED)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_OtherOptions = GUICtrlCreateGroup('Other options', 330, 205, 295, 235)
	$GUI_Checkbox_WeaponSlot = GUICtrlCreateCheckbox('Save weapon slot for farm:', 355, 225)
	GUICtrlSetOnEvent($GUI_Checkbox_WeaponSlot, 'GuiButtonHandler')
	$GUI_Combo_WeaponSlot = GUICtrlCreateCombo('1', 505, 225, 30, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_WeaponSlot, $AVAILABLE_WEAPON_SLOTS, '1')
	GUICtrlSetOnEvent($GUI_Combo_WeaponSlot, 'GuiButtonHandler')

	$GUI_Label_BagsCount = GUICtrlCreateLabel('Number of bags:', 355, 253)
	$GUI_Combo_BagsCount = GUICtrlCreateCombo('5', 440, 250, 30, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_BagsCount, $AVAILABLE_BAG_COUNTS, '5')
	GUICtrlSetOnEvent($GUI_Combo_BagsCount, 'GuiButtonHandler')
	$GUI_Label_TravelDistrict = GUICtrlCreateLabel('Travel district:', 355, 278)
	$GUI_Combo_DistrictChoice = GUICtrlCreateCombo('Random', 430, 275, 81, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_DistrictChoice, $AVAILABLE_DISTRICTS, 'Random')
	GUICtrlSetOnEvent($GUI_Combo_DistrictChoice, 'GuiButtonHandler')

	$GUI_RenderLabel = GUICtrlCreateLabel('Disabling rendering can reduce power consumption', 355, 305, 252, 20)
	$GUI_RenderButton = GUICtrlCreateButton('Rendering enabled', 351, 325, 252, 25)
	GUICtrlSetBkColor($GUI_RenderButton, $COLOR_YELLOW)
	GUICtrlSetOnEvent($GUI_RenderButton, 'GuiButtonHandler')
	Local $DynamicLabelString = 'Dynamic execution. It allows to run a command with' & @CRLF _
							& 'any arguments on the fly by writing it in below field.' & @CRLF _
							& 'Syntax: fun(arg1, arg2, arg3, [...])'
	$GUI_Label_DynamicExecution = GUICtrlCreateLabel($DynamicLabelString, 355, 355, 252, 40)
	$GUI_Input_DynamicExecution = GUICtrlCreateInput('', 355, 405, 156, 20)
	$GUI_Button_DynamicExecution = GUICtrlCreateButton('Run', 530, 405, 75, 20)
	GUICtrlSetBkColor($GUI_Button_DynamicExecution, $COLOR_LIGHTBLUE)
	GUICtrlSetOnEvent($GUI_Button_DynamicExecution, 'GuiButtonHandler')
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	$GUI_Tab_TeamOptions = GUICtrlCreateTabItem('Team options')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $COLOR_SILVER)
	$GUI_Group_TeamOptions = GUICtrlCreateGroup('Team options', 21, 39, 604, 401)
	$GUI_Checkbox_AutomaticTeamSetup = GUICtrlCreateCheckbox('Setup team automatically using team options section', 31, 65)
	GUICtrlSetOnEvent($GUI_Checkbox_AutomaticTeamSetup, 'GuiButtonHandler')
	$GUI_TeamLabel = GUICtrlCreateLabel('Below settings can be applied to some farms like vanquish that don''t have restrictions on used build templates' & @CRLF _
		& 'If party size is 4 or 6 then last heroes just won''t be added to party', 31, 100)
	$GUI_TeamMemberLabel = GUICtrlCreateLabel('Team member', 147, 140, 100, 20)
	$GUI_TeamMemberBuildLabel = GUICtrlCreateLabel('Team member build', 445, 140, 100, 20)

	$GUI_Label_Player = GUICtrlCreateLabel('Player', 125, 167, 114, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	$GUI_Input_Build_Player = GUICtrlCreateInput('', 375, 167, 236, 20)
	GUICtrlSetBkColor($GUI_Label_Player, 0xFFFFFF)
	$GUI_Label_Hero_1 = GUICtrlCreateLabel('Selected Hero 1:', 31, 200, 100, 20)
	$GUI_Combo_Hero_1 = GUICtrlCreateCombo('Master of Whispers', 125, 197, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_1, $AVAILABLE_HEROES, 'Master of Whispers')
	$GUI_Label_Build_Hero_1 = GUICtrlCreateLabel('Hero 1 Build Template:', 254, 200, 120, 20)
	$GUI_Input_Build_Hero_1 = GUICtrlCreateInput('OAljUwGopSUBHVyBoBVVbh4B1YA', 375, 197, 236, 20)
	$GUI_Label_Hero_2 = GUICtrlCreateLabel('Selected Hero 2:', 31, 230, 100, 20)
	$GUI_Combo_Hero_2 = GUICtrlCreateCombo('Livia', 125, 227, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_2, $AVAILABLE_HEROES, 'Livia')
	$GUI_Label_Build_Hero_2 = GUICtrlCreateLabel('Hero 2 Build Template:', 254, 230, 120, 20)
	$GUI_Input_Build_Hero_2 = GUICtrlCreateInput('OAhjQoGYIP3hhWVVaO5EeDzxJ', 375, 227, 236, 20)
	$GUI_Label_Hero_3 = GUICtrlCreateLabel('Selected Hero 3:', 31, 260, 100, 20)
	$GUI_Combo_Hero_3 = GUICtrlCreateCombo('Gwen', 125, 257, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_3, $AVAILABLE_HEROES, 'Gwen')
	$GUI_Label_Build_Hero_3 = GUICtrlCreateLabel('Hero 3 Build Template:', 254, 260, 120, 20)
	$GUI_Input_Build_Hero_3 = GUICtrlCreateInput('OQNEAqwD2ycC0AmupXOIDQEQj', 375, 257, 236, 20)
	$GUI_Label_Hero_4 = GUICtrlCreateLabel('Selected Hero 4:', 31, 290, 100, 20)
	$GUI_Combo_Hero_4 = GUICtrlCreateCombo('Olias', 125, 287, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_4, $AVAILABLE_HEROES, 'Olias')
	$GUI_Label_Build_Hero_4 = GUICtrlCreateLabel('Hero 4 Build Template:', 254, 290, 120, 20)
	$GUI_Input_Build_Hero_4 = GUICtrlCreateInput('OAhjUwGYoSUBHVoBbhVVWbTODTA', 375, 287, 236, 20)
	$GUI_Label_Hero_5 = GUICtrlCreateLabel('Selected Hero 5:', 31, 320, 100, 20)
	$GUI_Combo_Hero_5 = GUICtrlCreateCombo('Norgu', 125, 317, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_5, $AVAILABLE_HEROES, 'Norgu')
	$GUI_Label_Build_Hero_5 = GUICtrlCreateLabel('Hero 5 Build Template:', 254, 320, 120, 20)
	$GUI_Input_Build_Hero_5 = GUICtrlCreateInput('OQNEAqwD2ycCwpmupXOIDcBQj', 375, 317, 236, 20)
	$GUI_Label_Hero_6 = GUICtrlCreateLabel('Selected Hero 6:', 31, 350, 100, 20)
	$GUI_Combo_Hero_6 = GUICtrlCreateCombo('Xandra', 125, 347, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_6, $AVAILABLE_HEROES, 'Xandra')
	$GUI_Label_Build_Hero_6 = GUICtrlCreateLabel('Hero 6 Build Template:', 254, 350, 120, 20)
	$GUI_Input_Build_Hero_6 = GUICtrlCreateInput('OACiAyk8gNtePuwJ00ZOPLYA', 375, 347, 236, 20)
	$GUI_Label_Hero_7 = GUICtrlCreateLabel('Selected Hero 7:', 31, 380, 100, 20)
	$GUI_Combo_Hero_7 = GUICtrlCreateCombo('Razah', 125, 377, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($GUI_Combo_Hero_7, $AVAILABLE_HEROES, 'Razah')
	$GUI_Label_Build_Hero_7 = GUICtrlCreateLabel('Hero 7 Build Template:', 254, 380, 120, 20)
	$GUI_Input_Build_Hero_7 = GUICtrlCreateInput('OQNEAqwD2ycCaCmupXOIDMEQj', 375, 377, 236, 20)
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	$GUI_Tab_LootOptions = GUICtrlCreateTabItem('Loot options')
	$GUI_TreeView_LootOptions = GUICtrlCreateTreeView(80, 45, 545, 400, BitOR($TVS_HASLINES, $TVS_LINESATROOT, $TVS_HASBUTTONS, $TVS_CHECKBOXES, $TVS_FULLROWSELECT))
	$GUI_JSON_LootOptions = LoadLootOptions(@ScriptDir & '/conf/loot/Default Loot Configuration.json')
	BuildTreeViewFromJSON($GUI_TreeView_LootOptions, $GUI_JSON_LootOptions)
	$GUI_ExpandLootOptionsButton = GUICtrlCreateButton('Expand all', 21, 154, 55, 21)
	GUICtrlSetOnEvent($GUI_ExpandLootOptionsButton, 'GuiButtonHandler')
	$GUI_ReduceLootOptionsButton = GUICtrlCreateButton('Reduce all', 21, 184, 55, 21)
	GUICtrlSetOnEvent($GUI_ReduceLootOptionsButton, 'GuiButtonHandler')
	$GUI_LoadLootOptionsButton = GUICtrlCreateButton('Load', 21, 214, 55, 21)
	GUICtrlSetOnEvent($GUI_LoadLootOptionsButton, 'GuiButtonHandler')
	$GUI_SaveLootOptionsButton = GUICtrlCreateButton('Save', 21, 244, 55, 21)
	GUICtrlSetOnEvent($GUI_SaveLootOptionsButton, 'GuiButtonHandler')
	$GUI_ApplyLootOptionsButton = GUICtrlCreateButton('Apply', 21, 274, 55, 21)
	GUICtrlSetOnEvent($GUI_ApplyLootOptionsButton, 'GuiButtonHandler')
	GUICtrlCreateTabItem('')

	$GUI_Tab_FarmInfos = GUICtrlCreateTabItem('Farm informations')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $COLOR_SILVER)
	$GUI_Label_CharacterBuilds = GUICtrlCreateLabel('Recommended character builds:', 90, 40)
	$GUI_Edit_CharacterBuilds = GUICtrlCreateEdit('', 45, 60, 250, 105, BitOR($ES_MULTILINE, $ES_READONLY), $WS_EX_TOOLWINDOW)
	$GUI_Label_HeroesBuilds = GUICtrlCreateLabel('Recommended Heroes builds:', 400, 40)
	$GUI_Edit_HeroesBuilds = GUICtrlCreateEdit('', 350, 60, 250, 105, BitOR($ES_MULTILINE, $ES_READONLY), $WS_EX_TOOLWINDOW)
	$GUI_Label_FarmInformations = GUICtrlCreateLabel('Farm informations:', 30, 170, 575, 450)
	GUICtrlCreateTabItem('')

	$GUI_Combo_ConfigChoice = GUICtrlCreateCombo('Default Farm Configuration', 400, 10, 210, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent($GUI_Combo_ConfigChoice, 'GuiButtonHandler')

	$GUI_Icon_SaveConfig = GUICtrlCreatePic(@ScriptDir & '/doc/save.jpg', 615, 12, 20, 20)
	GUICtrlSetOnEvent($GUI_Icon_SaveConfig, 'GuiButtonHandler')

	GUIRegisterMsg($WM_COMMAND, 'WM_COMMAND_Handler')
	GUIRegisterMsg($WM_NOTIFY, 'WM_NOTIFY_Handler')
EndFunc


;~ Change the color of a tab
Func _GUICtrlTab_SetBkColor($gui, $parentTab, $color)
	Local $tabPosition = ControlGetPos($gui, '', $parentTab)
	Local $tabRectangle = _GUICtrlTab_GetItemRect($parentTab, -1)

	GUICtrlCreateLabel('', $tabPosition[0]+2, $tabPosition[1]+$tabRectangle[3]+4, $tabPosition[2]-6, $tabPosition[3]-$tabRectangle[3]-7)
	GUICtrlSetBkColor(-1, $color)
	GUICtrlSetState(-1, $GUI_DISABLE)
EndFunc


#Region Handlers
;~ Handles WM_COMMAND elements, like combobox arrow clicks
Func WM_COMMAND_Handler($windowHandle, $messageCode, $packedParameters, $controlHandle)
	Local $notificationCode = BitShift($packedParameters, 16)
	Local $controlID = BitAND($packedParameters, 0xFFFF)

	If $notificationCode = $GUI_COMBOBOX_DROPDOWN_OPENED Then
		Switch $controlID
			Case $GUI_Combo_CharacterChoice
				ScanAndUpdateGameClients()
				RefreshCharactersComboBox()
		EndSwitch
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc


;~ Handles WM_NOTIFY elements, like treeview clicks
Func WM_NOTIFY_Handler($windowHandle, $messageCode, $unusedParam, $paramNotifyStruct)
	Local $notificationHeader = DllStructCreate('hwnd sourceHandle;int controlId;int notificationCode', $paramNotifyStruct)
	Local $sourceHandle = DllStructGetData($notificationHeader, 'sourceHandle')
	Local $notificationCode = DllStructGetData($notificationHeader, 'notificationCode')

	If $sourceHandle = GUICtrlGetHandle($GUI_TreeView_LootOptions) Then
		Switch $notificationCode
			Case $NM_CLICK
				Local $mousePos = _WinAPI_GetMousePos(True, $sourceHandle)
				Local $hitTestResult = _GUICtrlTreeView_HitTestEx($sourceHandle, DllStructGetData($mousePos, 1), DllStructGetData($mousePos, 2))
				Local $clickedItem = DllStructGetData($hitTestResult, 'Item')
				Local $hitFlags = DllStructGetData($hitTestResult, 'Flags')

				If $clickedItem <> 0 And BitAND($hitFlags, $TVHT_ONITEMSTATEICON) Then
					ToggleCheckboxCascade($sourceHandle, $clickedItem, True)
					VerifyParentCheckbox($sourceHandle, $clickedItem, True)
				EndIf

			Case $TVN_KEYDOWN
				Local $keyInfo = DllStructCreate('hwnd;int;int;short key;uint', $paramNotifyStruct)
				Local $selectedItem = _GUICtrlTreeView_GetSelection($sourceHandle)
				; Spacebar pressed
				If DllStructGetData($keyInfo, 'key') = 0x20 And $selectedItem Then
					ToggleCheckboxCascade($sourceHandle, $selectedItem, True)
					VerifyParentCheckbox($sourceHandle, $selectedItem, True)
				EndIf
		EndSwitch
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc


;~ Toggles checkbox state on a TreeView item and cascades it to children
Func ToggleCheckboxCascade($treeViewHandle, $itemHandle, $toggleFromRoot = False)
	Local $isChecked = _GUICtrlTreeView_GetChecked($treeViewHandle, $itemHandle)
	If $toggleFromRoot Then $isChecked = Not $isChecked

	If _GUICtrlTreeView_GetChildren($treeViewHandle, $itemHandle) Then
		Local $childHandle = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $itemHandle)
		While $childHandle <> 0
			_GUICtrlTreeView_SetChecked($treeViewHandle, $childHandle, $isChecked)
			If _GUICtrlTreeView_GetChildren($treeViewHandle, $childHandle) Then
				ToggleCheckboxCascade($treeViewHandle, $childHandle)
			EndIf
			$childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
		WEnd
	EndIf
EndFunc


;~ Verifies parent checkbox state of provided TreeView item. Checks parent if all parent's children checkboxes (including item) are checked and unchecks it when at least one child is unchecked (can be item)
;~ $willToggle parameter is needed because AutoIT truly checks/unchecks clicked item only after WM_NOTIFY is handled, after this function finishes
;~ And when propagating parents to root, these parents of clicked item won't be toggled after WM_NOTIFY, because they weren't clicked. Need to make difference between clicked item and its parents
Func VerifyParentCheckbox($treeViewHandle, $itemHandle, $willToggle = False)
	Local $parentHandle = _GUICtrlTreeView_GetParentHandle($treeViewHandle, $itemHandle)
	If $parentHandle <> 0 Then
		If _GUICtrlTreeView_GetChildren($treeViewHandle, $parentHandle) Then
			Local $allChildsChecked = True
			Local $childHandle = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $parentHandle)
			While $childHandle <> 0
				Local $isChildChecked = _GUICtrlTreeView_GetChecked($treeViewHandle, $childHandle)
				; for currently clicked child item its check status need to be inversed because its status will truly be changed only after this function finishes (after WM_NOTIFY is handled)
				If $childHandle == $itemHandle And $willToggle Then $isChildChecked = Not $isChildChecked
				If Not $isChildChecked Then
					$allChildsChecked = False
					ExitLoop
				EndIf
				$childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
			WEnd
			_GUICtrlTreeView_SetChecked($treeViewHandle, $parentHandle, $allChildsChecked)
			; also verify parent's parent to cascade to root, no need to take $willToggle into account for parent, which got updated in previous instruction
			VerifyParentCheckbox($treeViewHandle, $parentHandle, False)
		EndIf
	EndIf
EndFunc


;~ Cascading checks in the treeview - unused for now
Func CascadeSetChecked($nodeHandle, $checked)
	If Not IsInt($nodeHandle) Then Return
	_GUICtrlTreeView_SetChecked($GUI_TreeView_LootOptions, $nodeHandle, $checked)
	If MapExists($GUI_HandleTree, $nodeHandle) Then
		For $child In $GUI_HandleTree[$nodeHandle]
			CascadeSetChecked($child, $checked)
		Next
	EndIf
EndFunc


;~ Handle GUI buttons usage
Func GuiButtonHandler()
	Switch @GUI_CtrlId
		Case $GUI_Tabs_Parent
			TabHandler()
		Case $GUI_Combo_FarmChoice
			UpdateFarmDescription(GUICtrlRead($GUI_Combo_FarmChoice))
		Case $GUI_Combo_BagsCount
			$BAGS_COUNT = Number(GUICtrlRead($GUI_Combo_BagsCount))
			$BAGS_COUNT = _Max($BAGS_COUNT, 1)
			$BAGS_COUNT = _Min($BAGS_COUNT, 5)
		Case $GUI_Combo_ConfigChoice
			LoadConfiguration(GUICtrlRead($GUI_Combo_ConfigChoice))
		Case $GUI_Combo_DistrictChoice
			$DISTRICT_NAME = GUICtrlRead($GUI_Combo_DistrictChoice)
		Case $GUI_Checkbox_WeaponSlot
			UpdateWeaponSlotCombobox()
		Case $GUI_Combo_WeaponSlot
			$WEAPON_SLOT = Number(GUICtrlRead($GUI_Combo_WeaponSlot))
			$WEAPON_SLOT = _Max($WEAPON_SLOT, 1)
			$WEAPON_SLOT = _Min($WEAPON_SLOT, 4)
		Case $GUI_Checkbox_AutomaticTeamSetup
			UpdateTeamComboboxes()
		Case $GUI_Icon_SaveConfig
			GUICtrlSetState($GUI_Icon_SaveConfig, $GUI_DISABLE)
			Local $filePath = FileSaveDialog('', @ScriptDir & '\conf\farm', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to write JSON configuration.')
			Else
				SaveConfiguration($filePath)
			EndIf
			GUICtrlSetState($GUI_Icon_SaveConfig, $GUI_ENABLE)
		Case $GUI_ExpandLootOptionsButton
			_GUICtrlTreeView_Expand(GUICtrlGetHandle($GUI_TreeView_LootOptions), 0, True)
		Case $GUI_ReduceLootOptionsButton
			_GUICtrlTreeView_Expand(GUICtrlGetHandle($GUI_TreeView_LootOptions), 0, False)
		Case $GUI_LoadLootOptionsButton
			Local $filePath = FileOpenDialog('Please select a valid loot options file', @ScriptDir & '\conf\loot', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to read JSON loot options configuration.')
			Else
				$GUI_JSON_LootOptions = LoadLootOptions($filePath)
				_GUICtrlTreeView_DeleteAll($GUI_TreeView_LootOptions)
				BuildTreeViewFromJSON($GUI_TreeView_LootOptions, $GUI_JSON_LootOptions)
			EndIf
		Case $GUI_SaveLootOptionsButton
			Local $jsonObject = BuildJSONFromTreeView($GUI_TreeView_LootOptions)
			Local $jsonString = _JSON_Generate($jsonObject)
			Local $filePath = FileSaveDialog('', @ScriptDir & '\conf\loot', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to write JSON loot options configuration.')
			Else
				Local $configFile = FileOpen($filePath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
				FileWrite($configFile, $jsonString)
				FileClose($configFile)
				Info('Saved loot options configuration ' & $configFile)
			EndIf
		Case $GUI_ApplyLootOptionsButton
			UpdateLootOptionsFromInterface()
		Case $GUI_RenderButton
			ToggleRenderingState()
		Case $GUI_Button_DynamicExecution
			DynamicExecution(GUICtrlRead($GUI_Input_DynamicExecution))
		Case $GUI_StartButton
			StartButtonHandler()
		Case $GUI_EVENT_CLOSE
			EnableRendering() ; restore rendering in case it was disabled
			Exit
		Case Else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc


;~ Function handling tab changes
Func TabHandler()
	Switch GUICtrlRead($GUI_Tabs_Parent)
		Case 0
			ControlEnable($GUI_GWBotHub, '', $GUI_Console)
			ControlShow($GUI_GWBotHub, '', $GUI_Console)
		Case Else
			ControlDisable($GUI_GWBotHub, '', $GUI_Console)
			ControlHide($GUI_GWBotHub, '', $GUI_Console)
	EndSwitch
EndFunc


;~ Function handling start button
Func StartButtonHandler()
	Switch $STATUS
		Case 'UNINITIALIZED'
			Info('Initializing...')
			If (Authentification() <> $SUCCESS) Then Return
			$STATUS = 'INITIALIZED'
			Info('Starting...')
			$STATUS = 'RUNNING'
			GUICtrlSetData($GUI_StartButton, 'Pause')
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTCORAL)
		Case 'INITIALIZED'
			Info('Starting...')
			$STATUS = 'RUNNING'
		Case 'RUNNING'
			Info('Pausing...')
			GUICtrlSetData($GUI_StartButton, 'Will pause after this run')
			GUICtrlSetState($GUI_StartButton, $GUI_Disable)
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTYELLOW)
			$STATUS = 'WILL_PAUSE'
		Case 'WILL_PAUSE'
			MsgBox(0, 'Error', 'You should not be able to press Pause when bot is already pausing.')
		Case 'PAUSED'
			Info('Restarting...')
			GUICtrlSetData($GUI_StartButton, 'Pause')
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTCORAL)
			$STATUS = 'RUNNING'
		Case Else
			MsgBox(0, 'Error', 'Unknown status <' & $STATUS & '>')
	EndSwitch
EndFunc


Func ToggleRenderingState()
	If(GUICtrlRead($GUI_RenderButton) == 'Rendering enabled') Then
		UpdateRenderingState(False)
	ElseIf(GUICtrlRead($GUI_RenderButton) == 'Rendering disabled') Then
		UpdateRenderingState(True)
	EndIf
EndFunc


Func SetRenderingState()
	If(GUICtrlRead($GUI_RenderButton) == 'Rendering enabled') Then
		UpdateRenderingState(True)
	ElseIf(GUICtrlRead($GUI_RenderButton) == 'Rendering disabled') Then
		UpdateRenderingState(False)
	EndIf
EndFunc


Func UpdateRenderingState($enableRendering = True)
	If $enableRendering Then
		GUICtrlSetBkColor($GUI_RenderButton, $COLOR_YELLOW)
		GUICtrlSetData($GUI_RenderButton, 'Rendering enabled')
		EnableRendering()
	Else
		GUICtrlSetBkColor($GUI_RenderButton, $COLOR_LIGHTGREEN)
		GUICtrlSetData($GUI_RenderButton, 'Rendering disabled')
		DisableRendering()
	Endif
EndFunc


Func UpdateWeaponSlotCombobox()
	If(GUICtrlRead($GUI_Checkbox_WeaponSLot) == $GUI_CHECKED) Then
		If $STATUS == 'RUNNING' Then Return ; don't enable combobox when bot is running, only enable it when bot is paused, to avoid accidental mouse scroll on combobox
		GUICtrlSetState($GUI_Combo_WeaponSLot, $GUI_ENABLE)
	ElseIf(GUICtrlRead($GUI_Checkbox_WeaponSLot) == $GUI_UNCHECKED) Then
		GUICtrlSetState($GUI_Combo_WeaponSLot, $GUI_DISABLE)
	EndIf
EndFunc


Func UpdateTeamComboboxes()
	If(GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED) Then
		EnableTeamComboboxes()
	ElseIf(GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_UNCHECKED) Then
		DisableTeamComboboxes()
	EndIf
EndFunc


Func EnableTeamComboboxes()
	If $STATUS == 'RUNNING' Then Return ; don't enable comboboxes when bot is running, only enable them when bot is paused, to avoid accidental mouse scroll on comboboxes
	GUICtrlSetState($GUI_Label_Player, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_1, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_2, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_3, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_4, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_5, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_6, $GUI_ENABLE)
	GUICtrlSetState($GUI_Combo_Hero_7, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Player, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_1, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_2, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_3, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_4, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_5, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_6, $GUI_ENABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_7, $GUI_ENABLE)
EndFunc


Func DisableTeamComboboxes()
	GUICtrlSetState($GUI_Label_Player, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_1, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_2, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_3, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_4, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_5, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_6, $GUI_DISABLE)
	GUICtrlSetState($GUI_Combo_Hero_7, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Player, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_1, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_2, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_3, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_4, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_5, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_6, $GUI_DISABLE)
	GUICtrlSetState($GUI_Input_Build_Hero_7, $GUI_DISABLE)
EndFunc
#EndRegion Handlers


#Region Console
;~ Print debug to console with timestamp
Func Debug($TEXT)
	Out($TEXT, $LVL_DEBUG)
EndFunc


;~ Print info to console with timestamp
Func Info($TEXT)
	Out($TEXT, $LVL_INFO)
EndFunc


;~ Print notice to console with timestamp
Func Notice($TEXT)
	Out($TEXT, $LVL_NOTICE)
EndFunc


;~ Print warning to console with timestamp
Func Warn($TEXT)
	Out($TEXT, $LVL_WARNING)
EndFunc


;~ Print warning to console with timestamp, only once
Func WarnOnce($TEXT)
	Static Local $warningMessages[]
	If $warningMessages[$TEXT] <> 1 Then
		Out($TEXT, $LVL_WARNING)
		$warningMessages[$TEXT] = 1
	EndIf
EndFunc


;~ Print error to console with timestamp
Func Error($TEXT)
	Out($TEXT, $LVL_ERROR)
EndFunc


;~ Print to console with timestamp
;~ LOGLEVEL= 0-Debug, 1-Info, 2-Notice, 3-Warning, 4-Error
Func Out($TEXT, $LOGLEVEL = 1)
	If $LOGLEVEL >= $LOG_LEVEL Then
		Local $logColor
		Switch $LOGLEVEL
			Case $LVL_DEBUG
				$logColor = $CLR_LIGHTGREEN ; CLR is reversed BGR color
			Case $LVL_INFO
				$logColor = $CLR_WHITE ; CLR is reversed BGR color
			Case $LVL_NOTICE
				$logColor = $CLR_TEAL ; CLR is reversed BGR color
			Case $LVL_WARNING
				$logColor = $CLR_YELLOW ; CLR is reversed BGR color
			Case $LVL_ERROR
				$logColor = $CLR_RED ; CLR is reversed BGR color
		EndSwitch
		_GUICtrlRichEdit_SetCharColor($GUI_Console, $logColor)
		_GUICtrlRichEdit_AppendText($GUI_Console, @HOUR & ':' & @MIN & ':' & @SEC & ' - ' & $TEXT & @CRLF)
	EndIf
EndFunc
#EndRegion Console
#EndRegion GUI


#Region Main loops
main()

;------------------------------------------------------
; Title...........:	_main
; Description.....:	run the main program
;------------------------------------------------------
Func main()
	If @AutoItVersion < '3.3.16.0' Then
		MsgBox(16, 'Error', 'This bot requires AutoIt version 3.3.16.0 or higher. You are using ' & @AutoItVersion & '.')
		Exit 1
	EndIf
	If @AutoItX64 Then
		MsgBox(16, 'Error!', 'Please run all bots in 32-bit (x86) mode.')
		Exit 1
	EndIf

	createGUI()
	GUISetState(@SW_SHOWNORMAL)
	Info('GW Bot Hub ' & $GW_BOT_HUB_VERSION)


	If $CmdLine[0] <> 0 Then
		$RUN_MODE = 'CMD'
		If 1 > UBound($CmdLine)-1 Then
			MsgBox(0, 'Error', 'Element is out of the array bounds.')
			exit
		EndIf
		If 2 > UBound($CmdLine)-1 Then exit

		$CHARACTER_NAME = $CmdLine[1]
		$PROCESS_ID = $CmdLine[2]
		; Login with $CHARACTER_NAME or $PROCESS_ID
		$STATUS = 'INITIALIZED'
	ElseIf $RUN_MODE == 'AUTOLOAD' Then
		ScanAndUpdateGameClients()
		RefreshCharactersComboBox()
	Else
		GUICtrlDelete($GUI_Combo_CharacterChoice)
		$GUI_Combo_CharacterChoice = GUICtrlCreateCombo('Character Name Input', 10, 470, 150, 20)
	EndIf
	FillConfigurationCombo()
	LoadDefaultConfiguration()
	UpdateLootOptionsFromInterface()
	BotHubLoop()
EndFunc


;~ Main loop of the program
Func BotHubLoop()
	While True
		Sleep(1000)

		If ($STATUS == 'RUNNING') Then
			SetRenderingState()
			DisableGUIComboboxes()
			; During pickup, items will be moved to equipment bag (if used) when first 3 bags are full
			; So bag 5 will always fill before 4 - hence we can count items up to bag 4
			If (CountSlots(1, _Min($BAGS_COUNT, 4)) < $INVENTORY_SPACE_NEEDED) Then
				InventoryManagementBeforeRun()
				ResetBotsSetups()
			EndIf
			If (CountSlots(1, $BAGS_COUNT) < $INVENTORY_SPACE_NEEDED) Then
				Notice('Inventory full, pausing.')
				ResetBotsSetups()
				$STATUS = 'WILL_PAUSE'
			EndIf
			If GUICtrlRead($GUI_Checkbox_FarmMaterialsMidRun) = $GUI_CHECKED Then
				Local $resetRequired = InventoryManagementMidRun()
				If $resetRequired Then ResetBotsSetups()
			EndIf
			Local $Farm = GUICtrlRead($GUI_Combo_FarmChoice)
			Local $result = RunFarmLoop($Farm)
			If ($result == $PAUSE Or GUICtrlRead($GUI_Checkbox_LoopRuns) == $GUI_UNCHECKED) Then
				$STATUS = 'WILL_PAUSE'
			EndIf
		EndIf

		If ($STATUS == 'WILL_PAUSE') Then
			Warn('Paused.')
			$STATUS = 'PAUSED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetState($GUI_StartButton, $GUI_Enable)
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTBLUE)
			EnableGUIComboboxes()
		EndIf
	WEnd
EndFunc


Func EnableGUIComboboxes()
	; Enabling changing account is non trivial
	;GUICtrlSetState($GUI_Combo_CharacterChoice, $GUI_Enable)
	GUICtrlSetState($GUI_Combo_FarmChoice, $GUI_Enable)
	GUICtrlSetState($GUI_Combo_ConfigChoice, $GUI_Enable)
	GUICtrlSetState($GUI_Combo_WeaponSlot, $GUI_Enable)
	GUICtrlSetState($GUI_Combo_DistrictChoice, $GUI_Enable)
	GUICtrlSetState($GUI_Combo_BagsCount, $GUI_Enable)
	EnableTeamComboboxes()
EndFunc


Func DisableGUIComboboxes()
	GUICtrlSetState($GUI_Combo_CharacterChoice, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_FarmChoice, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_ConfigChoice, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_WeaponSlot, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_DistrictChoice, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_BagsCount, $GUI_Disable)
	DisableTeamComboboxes()
EndFunc


;~ Main loop to run farms
Func RunFarmLoop($Farm)
	Local $result = $NOT_STARTED
	Local $timePerRun = UpdateStats($NOT_STARTED)
	$RUN_TIMER = TimerInit()
	UpdateProgressBar($timePerRun == 0 ? SelectFarmDuration($Farm) : $timePerRun)
	AdlibRegister('UpdateProgressBar', 5000)
	Switch $Farm
		Case 'Choose a farm'
			MsgBox(0, 'Error', 'No farm chosen.')
			$STATUS = 'INITIALIZED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetBkColor($GUI_StartButton, $COLOR_LIGHTBLUE)
		Case 'Asuran'
			$INVENTORY_SPACE_NEEDED = 5
			$result = AsuranTitleFarm($STATUS)
		Case 'Boreal'
			$INVENTORY_SPACE_NEEDED = 5
			$result = BorealChestFarm($STATUS)
		Case 'Corsairs'
			$INVENTORY_SPACE_NEEDED = 5
			$result = CorsairsFarm($STATUS)
		Case 'Dragon Moss'
			$INVENTORY_SPACE_NEEDED = 5
			$result = DragonMossFarm($STATUS)
		Case 'Eden Iris'
			$INVENTORY_SPACE_NEEDED = 2
			$result = EdenIrisFarm($STATUS)
		Case 'Feathers'
			$INVENTORY_SPACE_NEEDED = 10
			$result = FeathersFarm($STATUS)
		Case 'Follower'
			$INVENTORY_SPACE_NEEDED = 15
			$result = FollowerFarm()
		Case 'FoW'
			$INVENTORY_SPACE_NEEDED = 15
			$result = FoWFarm($STATUS)
		Case 'FoW Tower of Courage'
			$INVENTORY_SPACE_NEEDED = 10
			$result = FoWToCFarm($STATUS)
		Case 'Froggy'
			$INVENTORY_SPACE_NEEDED = 10
			$result = FroggyFarm($STATUS)
		Case 'Gemstones'
			$INVENTORY_SPACE_NEEDED = 10
			$result = GemstonesFarm($STATUS)
		Case 'Gemstone Margonite'
			$INVENTORY_SPACE_NEEDED = 10
			$result = GemstoneMargoniteFarm($STATUS)
		Case 'Gemstone Stygian'
			$INVENTORY_SPACE_NEEDED = 10
			$result = GemstoneStygianFarm($STATUS)
		Case 'Gemstone Torment'
			$INVENTORY_SPACE_NEEDED = 10
			$result = GemstoneTormentFarm($STATUS)
		Case 'Glint Challenge'
			$INVENTORY_SPACE_NEEDED = 5
			$result = GlintChallengeFarm($STATUS)
		Case 'Jade Brotherhood'
			$INVENTORY_SPACE_NEEDED = 5
			$result = JadeBrotherhoodFarm($STATUS)
		Case 'Kournans'
			$INVENTORY_SPACE_NEEDED = 5
			$result = KournansFarm($STATUS)
		Case 'Kurzick'
			$INVENTORY_SPACE_NEEDED = 15
			$result = KurzickFactionFarm($STATUS)
		Case 'Lightbringer'
			$INVENTORY_SPACE_NEEDED = 10
			$result = LightbringerFarm($STATUS)
		Case 'Lightbringer 2'
			$INVENTORY_SPACE_NEEDED = 5
			$result = LightbringerFarm2($STATUS)
		Case 'Luxon'
			$INVENTORY_SPACE_NEEDED = 10
			$result = LuxonFactionFarm($STATUS)
		Case 'Mantids'
			$INVENTORY_SPACE_NEEDED = 5
			$result = MantidsFarm($STATUS)
		Case 'Ministerial Commendations'
			$INVENTORY_SPACE_NEEDED = 5
			$result = MinisterialCommendationsFarm($STATUS)
		Case 'Minotaurs'
			$INVENTORY_SPACE_NEEDED = 5
			$result = MinotaursFarm($STATUS)
		Case 'Nexus Challenge'
			$INVENTORY_SPACE_NEEDED = 5
			$result = NexusChallengeFarm($STATUS)
		Case 'Norn'
			$INVENTORY_SPACE_NEEDED = 5
			$result = NornTitleFarm($STATUS)
		Case 'OmniFarm'
			$INVENTORY_SPACE_NEEDED = 5
			$result = OmniFarm($STATUS)
		Case 'Pongmei'
			$INVENTORY_SPACE_NEEDED = 5
			$result = PongmeiChestFarm($STATUS)
		Case 'Raptors'
			$INVENTORY_SPACE_NEEDED = 5
			$result = RaptorsFarm($STATUS)
		Case 'SoO'
			$INVENTORY_SPACE_NEEDED = 15
			$result = SoOFarm($STATUS)
		Case 'SpiritSlaves'
			$INVENTORY_SPACE_NEEDED = 5
			$result = SpiritSlavesFarm($STATUS)
		Case 'Sunspear Armor'
			$INVENTORY_SPACE_NEEDED = 5
			$result = SunspearArmorFarm($STATUS)
		Case 'Tasca'
			$INVENTORY_SPACE_NEEDED = 5
			$result = TascaChestFarm($STATUS)
		Case 'Underworld'
			$INVENTORY_SPACE_NEEDED = 5
			$result = UnderworldFarm($STATUS)
		Case 'Vaettirs'
			$INVENTORY_SPACE_NEEDED = 5
			$result = VaettirsFarm($STATUS)
		Case 'Vanguard'
			$INVENTORY_SPACE_NEEDED = 5
			$result = VanguardTitleFarm($STATUS)
		Case 'Voltaic'
			$INVENTORY_SPACE_NEEDED = 10
			$result = VoltaicFarm($STATUS)
		Case 'War Supply Keiran'
			$INVENTORY_SPACE_NEEDED = 10
			$result = WarSupplyKeiranFarm($STATUS)
		Case 'Storage'
			$INVENTORY_SPACE_NEEDED = 5
			ResetBotsSetups()
			$result = ManageInventory($STATUS)
		Case 'Dynamic execution'
			Info('Dynamic execution')
		Case 'Tests'
			$result = RunTests($STATUS)
		Case 'TestSuite'
			$result = RunTestSuite($STATUS)
		Case Else
			MsgBox(0, 'Error', 'This farm does not exist.')
	EndSwitch
	AdlibUnRegister('UpdateProgressBar')
	GUICtrlSetData($GUI_FarmProgress, 100)
	Local $elapsedTime = TimerDiff($RUN_TIMER)
	If $result == $SUCCESS Then
		Info('Run Successful after: ' & ConvertTimeToMinutesString($elapsedTime))
	ElseIf $result == $FAIL Then
		Info('Run failed after: ' & ConvertTimeToMinutesString($elapsedTime))
	EndIf
	UpdateStats($result, $elapsedTime)
	ClearMemory()
	; _PurgeHook()
	Return $result
EndFunc
#EndRegion Main loops


#Region Setup
;~ Reset the setups of the bots when porting to a city for instance
Func ResetBotsSetups()
	$BOREAL_FARM_SETUP						= False
	$DM_FARM_SETUP							= False
	$FEATHERS_FARM_SETUP					= False
	$FOW_FARM_SETUP							= False
	$FROGGY_FARM_SETUP						= False
	$IRIS_FARM_SETUP						= False
	$JADE_BROTHERHOOD_FARM_SETUP			= False
	$KOURNANS_FARM_SETUP					= False
	$LIGHTBRINGER_FARM2_SETUP				= False
	$MANTIDS_FARM_SETUP						= False
	$RAPTORS_FARM_SETUP						= False
	$SOO_FARM_SETUP							= False
	$SPIRIT_SLAVES_FARM_SETUP				= False
	$TASCA_FARM_SETUP						= False
	$UW_FARM_SETUP							= False
	$VAETTIRS_FARM_SETUP					= False
	; Those don't need to be reset - party didn't change, build didn't change, and there is no need to refresh portal
	; BUT those bots MUST tp to the correct map on every loop
	;$CORSAIRS_FARM_SETUP					= False
	;$FOLLOWER_SETUP						= False
	;$GEMSTONES_FARM_SETUP					= False
	;$GEMSTONE_MARGONITE_FARM_SETUP			= False
	;$GEMSTONE_STYGIAN_FARM_SETUP			= False
	;$GEMSTONE_TORMENT_FARM_SETUP			= False
	;$GLINT_CHALLENGE_SETUP					= False
	;$LIGHTBRINGER_FARM_SETUP				= False
	;$MINISTERIAL_COMMENDATIONS_FARM_SETUP	= False
	;$PONGMEI_FARM_SETUP					= False
	;$VOLTAIC_FARM_SETUP					= False
	;$WARSUPPLY_FARM_SETUP					= False
EndFunc


;~ Update the farm description written on the rightmost tab
Func UpdateFarmDescription($Farm)
	GUICtrlSetData($GUI_Edit_CharacterBuilds, '')
	GUICtrlSetData($GUI_Edit_HeroesBuilds, '')
	GUICtrlSetData($GUI_Label_FarmInformations, '')
	Switch $Farm
		Case 'Asuran'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $AsuranFarmInformations)
		Case 'Boreal'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $BorealRangerChestRunnerSkillbar & @CRLF & _
				$BorealMonkChestRunnerSkillbar & @CRLF & $BorealNecromancerChestRunnerSkillbar & @CRLF & _
				$BorealMesmerChestRunnerSkillbar & @CRLF & $BorealElementalistChestRunnerSkillbar & @CRLF & _
				$BorealAssassinChestRunnerSkillbar & @CRLF & $BorealRitualistChestRunnerSkillbar & @CRLF & _
				$BorealDervishChestRunnerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $BorealChestRunInformations)
		Case 'Corsairs'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RACorsairsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $MoPCorsairsHeroSkillbar & @CRLF & $DRCorsairsHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $CorsairsFarmInformations)
		Case 'Dragon Moss'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RADragonMossFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $DragonMossFarmInformations)
		Case 'Eden Iris'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, 'No build necessary')
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $EdenIrisFarmInformations)
		Case 'Feathers'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $DAFeathersFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $FeathersFarmInformations)
		Case 'Follower'
			GUICtrlSetData($GUI_Label_FarmInformations, $FollowerInformations)
		Case 'FoW'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $FoWFarmInformations)
		Case 'FoW Tower of Courage'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RAFoWToCFarmerSkillBar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $FoWToCFarmInformations)
		Case 'Froggy'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $FroggyFarmInformations)
		Case 'Gemstones'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $GemstonesMesmerSkillBar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $GemstonesHero1Skillbar & @CRLF & _
				$GemstonesHero2Skillbar & @CRLF & $GemstonesHero3Skillbar & @CRLF & _
				$GemstonesHero4Skillbar & @CRLF & $GemstonesHero5Skillbar & @CRLF & _
				$GemstonesHero6Skillbar & @CRLF & $GemstonesHero7Skillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $GemstonesFarmInformations)
		Case 'Gemstone Margonite'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $AMeMargoniteSkillBar & @CRLF & _
				$MeAMargoniteSkillBar & @CRLF & $EMeMargoniteSkillBar & @CRLF & $RAMargoniteSkillBar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $MargoniteMonkHeroSkillBar)
			GUICtrlSetData($GUI_Label_FarmInformations, $GemstoneMargoniteFarmInformations)
		Case 'Gemstone Stygian'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $AMeStygianSkillBar _
				& @CRLF & $MeAStygianSkillBar & @CRLF & $RNStygianSkillBar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $StygianRangerHeroSkillBar)
			GUICtrlSetData($GUI_Label_FarmInformations, $GemstoneStygianFarmInformations)
		Case 'Gemstone Torment'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $EATormentSkillBar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $GemstoneTormentFarmInformations)
		Case 'Glint Challenge'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $GlintMesmerSkillBarOptional)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $GlintRituSoulTwisterHeroSkillBar & @CRLF & _
				$GlintNecroFleshGolemHeroSkillBar & @CRLF & $GlintNecroHexerHeroSkillBar & @CRLF & _
				$GlintNecroBiPHeroSkillBar & @CRLF & $GlintMesmerPanicHeroSkillBar & @CRLF & _
				$GlintMesmerIneptitudeHeroSkillBar & @CRLF & $GlintMesmerIneptitudeHeroSkillBar)
			GUICtrlSetData($GUI_Label_FarmInformations, $GlintChallengeInformations)
		Case 'Jade Brotherhood'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $JB_Skillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $JB_Hero_Skillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $JB_FarmInformations)
		Case 'Kournans'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $ElAKournansFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $RKournansHeroSkillbar & @CRLF & _
				$RtKournansHeroSkillbar & @CRLF & $PKournansHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $KournansFarmInformations)
		Case 'Kurzick'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $KurzickFactionInformations)
		Case 'Lightbringer'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $LightbringerFarmInformations)
		Case 'Lightbringer 2'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $LightbringerFarm2Informations)
		Case 'Luxon'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $LuxonFactionInformations)
		Case 'Mantids'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $RAMantidsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $MantidsHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $MantidsFarmInformations)
		Case 'Ministerial Commendations'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $DWCommendationsFarmerSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $CommendationsFarmInformations)
		Case 'Minotaurs'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $MinotaursFarmInformations)
		Case 'Nexus Challenge'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $NexusChallengeinformations)
		Case 'Norn'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $NornFarmInformations)
		Case 'Pongmei'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $PongmeiChestRunnerSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $PongmeiChestRunInformations)
		Case 'Raptors'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $WNRaptorsFarmerSkillbar & @CRLF & $DNRaptorsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, $PRunnerHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $RaptorsFarmInformations)
		Case 'SoO'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $SoOFarmInformations)
		Case 'SpiritSlaves'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $SpiritSlaves_Skillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $SpiritSlavesFarmInformations)
		Case 'Sunspear Armor'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $SunspearArmorFarmInformations)
		Case 'Tasca'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $TascaDervishChestRunnerSkillbar & @CRLF & _
				$TascaAssassinChestRunnerSkillbar & @CRLF & $TascaMesmerChestRunnerSkillbar & @CRLF & _
				$TascaElementalistChestRunnerSkillbar & @CRLF & $TascaMonkChestRunnerSkillbar & @CRLF & _
				$TascaNecromancerChestRunnerSkillbar & @CRLF & $TascaRitualistChestRunnerSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $TascaChestRunInformations)
		Case 'Underworld'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $UnderworldFarmInformations)
		Case 'Vaettirs'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, $AMeVaettirsFarmerSkillbar & @CRLF & _
				$MeAVaettirsFarmerSkillbar & @CRLF & $MoAVaettirsFarmerSkillbar & @CRLF & $EMeVaettirsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $VaettirsFarmInformations)
		Case 'Vanguard'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $VanguardTitleFarmInformations)
		Case 'Voltaic'
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solid heroes setup')
			GUICtrlSetData($GUI_Label_FarmInformations, $VoltaicFarmInformations)
		Case 'War Supply Keiran'
			GUICtrlSetData($GUI_Edit_CharacterBuilds, 'No build necessary')
			GUICtrlSetData($GUI_Edit_HeroesBuilds, 'Solo farm')
			GUICtrlSetData($GUI_Label_FarmInformations, $WarSupplyKeiranInformations)
		Case 'OmniFarm'
			Return
		Case 'Storage'
			Return
		Case Else
			Return
	EndSwitch
EndFunc
#EndRegion Setup


#Region Configuration
;~ Fill the choice of configuration
Func FillConfigurationCombo($configuration = 'Default Farm Configuration')
	Local $files = _FileListToArray(@ScriptDir & '/conf/farm/', '*.json', $FLTA_FILES)
	Local $comboList = ''
	If @error == 0 Then
		For $file In $files
			Local $fileNameTrimmed = StringTrimRight($file, 5)
			If $fileNameTrimmed <> '' Then
				$comboList &= '|'
				$comboList &= $fileNameTrimmed
			EndIf
		Next
	EndIf
	GUICtrlSetData($GUI_Combo_ConfigChoice, $comboList, $configuration)
EndFunc


;~ Load default farm configuration if it exists
Func LoadDefaultConfiguration()
	If FileExists(@ScriptDir & '/conf/farm/Default Farm Configuration.json') Then
		Local $configFile = FileOpen(@ScriptDir & '/conf/farm/Default Farm Configuration.json' , $FO_READ + $FO_UTF8)
		Local $jsonString = FileRead($configFile)
		ReadConfigFromJson($jsonString)
		FileClose($configFile)
		Info('Loaded default farm configuration')
	EndIf
EndFunc


;~ Change to a different configuration
Func LoadConfiguration($configuration)
	Local $configFile = FileOpen(@ScriptDir & '/conf/farm/' & $configuration & '.json' , $FO_READ + $FO_UTF8)
	Local $jsonString = FileRead($configFile)
	ReadConfigFromJson($jsonString)
	FileClose($configFile)
	Info('Loaded configuration <' & $configuration & '>')
EndFunc


;~ Save a new configuration
Func SaveConfiguration($configurationPath)
	Local $configFile = FileOpen($configurationPath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	Local $jsonString = WriteConfigToJson()
	FileWrite($configFile, $jsonString)
	FileClose($configFile)
	Local $configurationName = StringTrimRight(StringMid($configurationPath, StringInStr($configurationPath, '\', 0, -1) + 1), 5)
	FillConfigurationCombo($configurationName)
	Info('Saved configuration ' & $configurationPath)
EndFunc


;~ Writes current config to a json string
Func WriteConfigToJson()
	Local $jsonObject
	_JSON_addChangeDelete($jsonObject, 'main.character', GUICtrlRead($GUI_Combo_CharacterChoice))
	_JSON_addChangeDelete($jsonObject, 'main.farm', GUICtrlRead($GUI_Combo_FarmChoice))
	_JSON_addChangeDelete($jsonObject, 'run.loop_mode', GUICtrlRead($GUI_Checkbox_LoopRuns) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.hard_mode', GUICtrlRead($GUI_Checkbox_HardMode) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.farm_materials_mid_run', GUICtrlRead($GUI_Checkbox_FarmMaterialsMidRun) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.consume_consumables', GUICtrlRead($GUI_Checkbox_UseConsumables) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.use_scrolls', GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.store_unids', GUICtrlRead($GUI_Checkbox_StoreUnidentifiedGoldItems) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.sort_items', GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.collect_data', GUICtrlRead($GUI_Checkbox_CollectData) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.store_leftovers', GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.store_gold', GUICtrlRead($GUI_Checkbox_StoreGold) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.buy_ectoplasm', GUICtrlRead($GUI_Checkbox_BuyEctoplasm) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.buy_obsidian', GUICtrlRead($GUI_Checkbox_BuyObsidian) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.donate_faction_points', GUICtrlRead($GUI_RadioButton_DonatePoints) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.buy_faction_resources', GUICtrlRead($GUI_RadioButton_BuyFactionResources) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.buy_faction_scrolls', GUICtrlRead($GUI_RadioButton_BuyFactionScrolls) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.save_weapon_slot', GUICtrlRead($GUI_Checkbox_WeaponSlot) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'run.weapon_slot', Number(GUICtrlRead($GUI_Combo_WeaponSlot)))
	_JSON_addChangeDelete($jsonObject, 'run.bags_count', Number(GUICtrlRead($GUI_Combo_BagsCount)))
	_JSON_addChangeDelete($jsonObject, 'run.district', GUICtrlRead($GUI_Combo_DistrictChoice))
	_JSON_addChangeDelete($jsonObject, 'run.disable_rendering', GUICtrlRead($GUI_RenderButton) == 'Rendering disabled')

	_JSON_addChangeDelete($jsonObject, 'team.automatic_team_setup', GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED)
	_JSON_addChangeDelete($jsonObject, 'team.player_build', GUICtrlRead($GUI_Input_Build_Player))
	_JSON_addChangeDelete($jsonObject, 'team.hero_1', GUICtrlRead($GUI_Combo_Hero_1))
	_JSON_addChangeDelete($jsonObject, 'team.hero_1_build', GUICtrlRead($GUI_Input_Build_Hero_1))
	_JSON_addChangeDelete($jsonObject, 'team.hero_2', GUICtrlRead($GUI_Combo_Hero_2))
	_JSON_addChangeDelete($jsonObject, 'team.hero_2_build', GUICtrlRead($GUI_Input_Build_Hero_2))
	_JSON_addChangeDelete($jsonObject, 'team.hero_3', GUICtrlRead($GUI_Combo_Hero_3))
	_JSON_addChangeDelete($jsonObject, 'team.hero_3_build', GUICtrlRead($GUI_Input_Build_Hero_3))
	_JSON_addChangeDelete($jsonObject, 'team.hero_4', GUICtrlRead($GUI_Combo_Hero_4))
	_JSON_addChangeDelete($jsonObject, 'team.hero_4_build', GUICtrlRead($GUI_Input_Build_Hero_4))
	_JSON_addChangeDelete($jsonObject, 'team.hero_5', GUICtrlRead($GUI_Combo_Hero_5))
	_JSON_addChangeDelete($jsonObject, 'team.hero_5_build', GUICtrlRead($GUI_Input_Build_Hero_5))
	_JSON_addChangeDelete($jsonObject, 'team.hero_6', GUICtrlRead($GUI_Combo_Hero_6))
	_JSON_addChangeDelete($jsonObject, 'team.hero_6_build', GUICtrlRead($GUI_Input_Build_Hero_6))
	_JSON_addChangeDelete($jsonObject, 'team.hero_7', GUICtrlRead($GUI_Combo_Hero_7))
	_JSON_addChangeDelete($jsonObject, 'team.hero_7_build', GUICtrlRead($GUI_Input_Build_Hero_7))

	Return _JSON_Generate($jsonObject)
EndFunc


;~ Read given config from JSON
Func ReadConfigFromJson($jsonString)
	Local $jsonObject = _JSON_Parse($jsonString)
	GUICtrlSetData($GUI_Combo_CharacterChoice, _JSON_Get($jsonObject, 'main.character'))
	; below line is a fix for a very weird bug that character combobox truly updates during loading farm configuration only after being set second time. _JSON_Get() function seems to be fine, maybe this is AutoIT bug
	GUICtrlSetData($GUI_Combo_CharacterChoice, _JSON_Get($jsonObject, 'main.character'))
	GUICtrlSetData($GUI_Combo_FarmChoice, _JSON_Get($jsonObject, 'main.farm'))
	; below line is a fix for a very weird bug that farm combobox sometimes updates during loading farm configuration only after being set second time. _JSON_Get() function seems to be fine, maybe this is AutoIT bug
	GUICtrlSetData($GUI_Combo_FarmChoice, _JSON_Get($jsonObject, 'main.farm'))
	UpdateFarmDescription(_JSON_Get($jsonObject, 'main.farm'))
	Local $weaponSlot = _JSON_Get($jsonObject, 'run.weapon_slot')
	$weaponSlot = _Max($weaponSlot, 1)
	$weaponSlot = _Min($weaponSlot, 4)
	$WEAPON_SLOT = $weaponSlot
	GUICtrlSetData($GUI_Combo_WeaponSlot, $weaponSlot)
	Local $bagsCount = _JSON_Get($jsonObject, 'run.bags_count')
	$bagsCount = _Max($bagsCount, 1)
	$bagsCount = _Min($bagsCount, 5)
	$BAGS_COUNT = $bagsCount
	GUICtrlSetData($GUI_Combo_BagsCount, $bagsCount)
	Local $district = _JSON_Get($jsonObject, 'run.district')
	GUICtrlSetData($GUI_Combo_DistrictChoice, $district)
	$DISTRICT_NAME = $district
	Local $renderingDisabled = _JSON_Get($jsonObject, 'run.disable_rendering')
	Local $renderingEnabled = Not $renderingDisabled
	UpdateRenderingState($renderingEnabled)
	GUICtrlSetState($GUI_Checkbox_LoopRuns, _JSON_Get($jsonObject, 'run.loop_mode') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_HardMode, _JSON_Get($jsonObject, 'run.hard_mode') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_FarmMaterialsMidRun, _JSON_Get($jsonObject, 'run.farm_materials_mid_run') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_UseConsumables, _JSON_Get($jsonObject, 'run.consume_consumables') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_UseScrolls, _JSON_Get($jsonObject, 'run.use_scrolls') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_StoreUnidentifiedGoldItems, _JSON_Get($jsonObject, 'run.store_unids') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_SortItems, _JSON_Get($jsonObject, 'run.sort_items') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_CollectData, _JSON_Get($jsonObject, 'run.collect_data') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_StoreTheRest, _JSON_Get($jsonObject, 'run.store_leftovers') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_StoreGold, _JSON_Get($jsonObject, 'run.store_gold') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_BuyEctoplasm, _JSON_Get($jsonObject, 'run.buy_ectoplasm') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_BuyObsidian, _JSON_Get($jsonObject, 'run.buy_obsidian') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_RadioButton_DonatePoints, _JSON_Get($jsonObject, 'run.donate_faction_points') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_RadioButton_BuyFactionResources, _JSON_Get($jsonObject, 'run.buy_faction_resources') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_RadioButton_BuyFactionScrolls, _JSON_Get($jsonObject, 'run.buy_faction_scrolls') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_WeaponSlot, _JSON_Get($jsonObject, 'run.save_weapon_slot') ? $GUI_CHECKED : $GUI_UNCHECKED)
	UpdateWeaponSlotCombobox()

	GUICtrlSetState($GUI_Checkbox_AutomaticTeamSetup, _JSON_Get($jsonObject, 'team.automatic_team_setup') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($GUI_Input_Build_Player, _JSON_Get($jsonObject, 'team.player_build'))
	GUICtrlSetData($GUI_Combo_Hero_1, _JSON_Get($jsonObject, 'team.hero_1'))
	GUICtrlSetData($GUI_Input_Build_Hero_1, _JSON_Get($jsonObject, 'team.hero_1_build'))
	GUICtrlSetData($GUI_Combo_Hero_2, _JSON_Get($jsonObject, 'team.hero_2'))
	GUICtrlSetData($GUI_Input_Build_Hero_2, _JSON_Get($jsonObject, 'team.hero_2_build'))
	GUICtrlSetData($GUI_Combo_Hero_3, _JSON_Get($jsonObject, 'team.hero_3'))
	GUICtrlSetData($GUI_Input_Build_Hero_3, _JSON_Get($jsonObject, 'team.hero_3_build'))
	GUICtrlSetData($GUI_Combo_Hero_4, _JSON_Get($jsonObject, 'team.hero_4'))
	GUICtrlSetData($GUI_Input_Build_Hero_4, _JSON_Get($jsonObject, 'team.hero_4_build'))
	GUICtrlSetData($GUI_Combo_Hero_5, _JSON_Get($jsonObject, 'team.hero_5'))
	GUICtrlSetData($GUI_Input_Build_Hero_5, _JSON_Get($jsonObject, 'team.hero_5_build'))
	GUICtrlSetData($GUI_Combo_Hero_6, _JSON_Get($jsonObject, 'team.hero_6'))
	GUICtrlSetData($GUI_Input_Build_Hero_6, _JSON_Get($jsonObject, 'team.hero_6_build'))
	GUICtrlSetData($GUI_Combo_Hero_7, _JSON_Get($jsonObject, 'team.hero_7'))
	GUICtrlSetData($GUI_Input_Build_Hero_7, _JSON_Get($jsonObject, 'team.hero_7_build'))
	UpdateTeamComboboxes()
EndFunc


Func UpdateLootOptionsFromInterface()
	RefreshValuableListsFromInterface()
	Opt('GUIDataSeparatorChar', '.')
	$PICKUP_EVERYTHING = IsLootOptionChecked('Pick up items')
	$PICKUP_NOTHING = Not IsAnyLootOptionInBranchChecked('Pick up items')
	$PICKUP_WEAPONS = IsAnyLootOptionInBranchChecked('Pick up items.Weapons and offhands')
	$IDENTIFY_ITEMS = IsAnyLootOptionInBranchChecked('Identify items')
	$SALVAGE_NOTHING = Not IsAnyLootOptionInBranchChecked('Salvage items')
	$SALVAGE_ANY_ITEM = IsAnyLootOptionInBranchChecked('Salvage items')
	$SALVAGE_WEAPONS = IsAnyLootOptionInBranchChecked('Salvage items.Weapons and offhands')
	$SALVAGE_GEARS = IsAnyLootOptionInBranchChecked('Salvage items.Armor salvageables')
	$SALVAGE_ALL_TROPHIES = IsLootOptionChecked('Salvage items.Trophies')
	$SALVAGE_TROPHIES = IsAnyLootOptionInBranchChecked('Salvage items.Trophies')
	$SELL_NOTHING = Not IsAnyLootOptionInBranchChecked('Sell items')
	$SELL_WEAPONS = IsAnyLootOptionInBranchChecked('Sell items.Weapons and offhands')
	$SELL_BASIC_MATERIALS = IsAnyLootOptionInBranchChecked('Sell items.Basic Materials')
	$SELL_RARE_MATERIALS = IsAnyLootOptionInBranchChecked('Sell items.Rare Materials')
	$STORE_WEAPONS = IsAnyLootOptionInBranchChecked('Store items.Weapons and offhands')
EndFunc


;~ Creating a treeview from a JSON node
Func BuildTreeViewFromJSON($parentItem, $jsonNode)
	; Unused for now, but might become useful
	Local $GUI_HandleTree[]
	Local $keyHandle
	Local $valueHandle
	If IsMap($jsonNode) Then
		Local $keys = MapKeys($jsonNode)
		For $key In $keys
			$keyHandle = GUICtrlCreateTreeViewItem($key, $parentItem)
			$valueHandle = BuildTreeViewFromJSON($keyHandle, $jsonNode[$key])
			If $valueHandle == True Then
				_GUICtrlTreeView_SetChecked($GUI_TreeView_LootOptions, $keyHandle, True)
			Else
				$GUI_HandleTree[$keyHandle] = $valueHandle
			EndIf
		Next
		; after adding all children checkboxes to tree element(checkbox), verify if it should also be checked if all its children are checked
		VerifyParentCheckbox($GUI_TreeView_LootOptions, $keyHandle)
	ElseIf IsArray($jsonNode) Then
		Local $handles[UBound($jsonNode)]
		For $i = 0 To UBound($jsonNode) - 1
			$handles[$i] = BuildTreeViewFromJSON($parentItem, $jsonNode[$i])
		Next
		Return $handles
	Else
		Return $jsonNode
	EndIf
EndFunc


;~ Getting ticked loot options from checkboxes as array
Func GetLootOptionsTickedCheckboxes($startingPoint)
	; checking if $startingPoint contains extended path separated with . characters or is single tree element
	If StringInStr($startingPoint, '.') > 0 Then ; $startingPoint contains extended path, not single tree element
		Opt('GUIDataSeparatorChar', '.')
		Return BuildArrayFromTreeView($GUI_TreeView_LootOptions, _GUICtrlTreeView_FindItemEx($GUI_TreeView_LootOptions, $startingPoint))
	Else ; $startingPoint doesn't contain extended path, single tree element
		Return BuildArrayFromTreeView($GUI_TreeView_LootOptions, _GUICtrlTreeView_FindItem($GUI_TreeView_LootOptions, $startingPoint))
	EndIf
EndFunc


;~ Creating a JSON node from a treeview
Func BuildJSONFromTreeView($treeViewHandle, $treeViewItem = Null, $currentPath = '')
	Local $jsonObject
	IterateOverTreeView($jsonObject, $treeViewHandle, $treeViewItem, $currentPath, AddLeavesToJSONObject)
	Return $jsonObject
EndFunc


;~ Utility function to add treeview elements to a JSON object
Func AddLeavesToJSONObject(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath)
	Debug($currentPath)
	_JSON_addChangeDelete($context, $currentPath, _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem))
EndFunc


;~ Creating an array from a treeview
Func BuildArrayFromTreeView($treeViewHandle, $treeViewItem = Null, $currentPath = '')
	Local $array[0]
	IterateOverTreeView($array, $treeViewHandle, $treeViewItem, $currentPath, AddLeafToArray)
	Return $array
EndFunc


;~ Utility function to add treeview elements to an array
Func AddLeafToArray(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath)
	If _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem) Then _ArrayAdd($context, $currentPath)
EndFunc


;~ Iterate over a treeview and make an operation on leaves
Func IterateOverTreeView(ByRef $context, $treeViewHandle, $treeViewItem = Null, $currentPath = '', $functionToApply = Null)
	; If no item was passed in, then traverse whole tree recursively from root, otherwise traverse from passed item
	If $treeViewItem == Null Then
		$treeViewItem = _GUICtrlTreeView_GetFirstItem($treeViewHandle)
		While $treeViewItem <> 0
			IterateOverTreeView($context, $treeViewHandle, $treeViewItem, '', $functionToApply)
			$treeViewItem = _GUICtrlTreeView_GetNextSibling($treeViewHandle, $treeViewItem)
		WEnd
		Return
	EndIf

	$currentPath &= ($currentPath == '') ? _GUICtrlTreeView_GetText($treeViewHandle, $treeViewItem) : '.' & _GUICtrlTreeView_GetText($treeViewHandle, $treeViewItem)

	Local $childrenCount = _GUICtrlTreeView_GetChildCount($treeViewHandle, $treeViewItem)
	If $childrenCount <= 0 Then ; We are on a leaf
		If $functionToApply <> Null Then $functionToApply($context, $treeViewHandle, $treeViewItem, $currentPath)
	ElseIf $childrenCount == 1 Then ; We are on a branch with one leaf
		IterateOverTreeView($context, $treeViewHandle, _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem), $currentPath, $functionToApply)
	Else ; We are on a branch with many leaves
		Local $currentChild = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem)
		IterateOverTreeView($context, $treeViewHandle, $currentChild, $currentPath, $functionToApply)
		For $i = 1 To $childrenCount - 1
			$currentChild = _GUICtrlTreeView_GetNextChild($treeViewHandle, $currentChild)
			IterateOverTreeView($context, $treeViewHandle, $currentChild, $currentPath, $functionToApply)
		Next
	EndIf
EndFunc


Func IsLootOptionChecked($startingPoint, $treeViewHandle = $GUI_TreeView_LootOptions)
	; skipped check if $startingPoint contains path separated with . characters for optimization, generally only full path is used for this function
	Return _GUICtrlTreeView_GetChecked($treeViewHandle, _GUICtrlTreeView_FindItemEx($treeViewHandle, $startingPoint))
EndFunc


; Function to check if any checkbox is checked in a branch provided as path string
Func IsAnyLootOptionInBranchChecked($startingPoint, $treeViewHandle = $GUI_TreeView_LootOptions)
	Local $treeViewItem
	; checking if $startingPoint contains extended path separated with . characters or is single tree element
	If StringInStr($startingPoint, '.') > 0 Then ; $startingPoint contains extended path, not single tree element
		Opt('GUIDataSeparatorChar', '.')
		$treeViewItem = _GUICtrlTreeView_FindItemEx($treeViewHandle, $startingPoint)
	Else ; $startingPoint doesn't contain extended path, single tree element
		$treeViewItem = _GUICtrlTreeView_FindItem($treeViewHandle, $startingPoint)
	EndIf
	Return IsAnyChildInBranchChecked($treeViewHandle, $treeViewItem)
EndFunc


; Function to recursively traverse a branch in a tree view to check if any child in that branch is checked
Func IsAnyChildInBranchChecked($treeViewHandle, $treeViewItem)
	; Check if current item is checked
	If _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem) Then Return True

	Local $anyChildChecked = False
	; Recursively check all child items of provided $treeViewItem
	If _GUICtrlTreeView_GetChildren($treeViewHandle, $treeViewItem) Then
		Local $childHandle = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem)
		While $childHandle <> 0
			If IsAnyChildInBranchChecked($treeViewHandle, $childHandle) == True Then
				$anyChildChecked = True
				ExitLoop
			EndIf
			$childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
		WEnd
	EndIf

	Return $anyChildChecked
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
#EndRegion Configuration


#Region Authentification and Login
;~ Initialize connection to GW with the character name or process id given
Func Authentification()
	Local $characterName = GUICtrlRead($GUI_Combo_CharacterChoice)
	If ($characterName == '') Then
		Warn('Running without authentification.')
	ElseIf $PROCESS_ID And $RUN_MODE == 'CMD' Then
		Local $proc_id_int = Number($PROCESS_ID, 2)
		Info('Running via pid ' & $proc_id_int)
		If InitializeGameClientData(True, True, False) = 0 Then
			MsgBox(0, 'Error', 'Could not find a ProcessID or somewhat <<' & $proc_id_int & '>> ' & VarGetType($proc_id_int) & '')
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
			If InitializeGameClientData(True, True, False) = 0 Then
				MsgBox(0, 'Error', 'Failed game initialisation')
				Return $FAIL
			EndIf
		EndIf
	EndIf
	EnsureEnglish(True)
	WinSetTitle($GUI_GWBotHub, '', 'GW Bot Hub - ' & $characterName)
	Return $SUCCESS
EndFunc


;~ Fill characters combobox
Func RefreshCharactersComboBox()
	Local $comboList = ''
	For $i = 1 To $gameClients[0][0]
		If $gameClients[$i][0] <> -1 Then $comboList &= '|' & $gameClients[$i][3]
	Next
	Opt('GUIDataSeparatorChar', '|') ;'|' is the default, but caution is advised that it can be overriden by '.' which is used for tree view
	GUICtrlSetData($GUI_Combo_CharacterChoice, $comboList, $gameClients[0][0] > 0 ? $gameClients[1][3] : '')
	If ($gameClients[0][0] > 0) Then SelectClient(1)
EndFunc
#EndRegion Authentification and Login


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
	Local Static $itemsToCount[28] = [$ID_Glob_Of_Ectoplasm, $ID_Obsidian_Shard, $ID_Lockpick, _
		$ID_Margonite_Gemstone, $ID_Stygian_Gemstone, $ID_Titan_Gemstone, $ID_Torment_Gemstone, _
		$ID_Diessa_Chalice, $ID_Golden_Rin_Relic, $ID_Destroyer_Core, $ID_Glacial_Stone, _
		$ID_War_Supplies, $ID_Ministerial_Commendation, $ID_Jade_Bracelet, _
		$ID_Chunk_of_Drake_Flesh, $ID_Skale_Fin, _
		$ID_Wintersday_Gift, $ID_ToT, $ID_Birthday_Cupcake, $ID_Golden_Egg, $ID_Slice_of_Pumpkin_Pie, _
		$ID_Honeycomb, $ID_Fruitcake, $ID_Sugary_Blue_Drink, $ID_Chocolate_Bunny, $ID_Delicious_Cake, _
		$ID_Amber_Chunk, $ID_Jadeite_Shard]
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
	Local $RunIncomeGold = GetGoldCharacter() - $PreRunGold
	Local $RunIncomeGoldItems = $goldItemsCount - $PreRunGoldItems
	Local $RunIncomeEctos = $itemCounts[0] - $PreRunEctos
	Local $RunIncomeObsidianShards = $itemCounts[1] - $PreRunObsidianShards
	Local $RunIncomeLockpicks = $itemCounts[2] - $PreRunLockpicks
	Local $RunIncomeMargoniteGemstones = $itemCounts[3] - $PreRunMargoniteGemstones
	Local $RunIncomeStygianGemstones = $itemCounts[4] - $PreRunStygianGemstones
	Local $RunIncomeTitanGemstones = $itemCounts[5] - $PreRunTitanGemstones
	Local $RunIncomeTormentGemstones = $itemCounts[6] - $PreRunTormentGemstones
	Local $RunIncomeDiessaChalices = $itemCounts[7] - $PreRunDiessaChalices
	Local $RunIncomeRinRelics = $itemCounts[8] - $PreRunRinRelics
	Local $RunIncomeDestroyerCores = $itemCounts[9] - $PreRunDestroyerCores
	Local $RunIncomeGlacialStones = $itemCounts[10] - $PreRunGlacialStones
	Local $RunIncomeWarSupplies = $itemCounts[11] - $PreRunWarSupplies
	Local $RunIncomeMinisterialCommendations = $itemCounts[12] - $PreRunMinisterialCommendations
	Local $RunIncomeJadeBracelets = $itemCounts[13] - $PreRunJadeBracelets
	Local $RunIncomeChunksOfDrakeFlesh = $itemCounts[14] - $PreRunChunksOfDrakeFlesh
	Local $RunIncomeSkaleFins = $itemCounts[15] - $PreRunSkaleFins
	Local $RunIncomeWintersdayGifts = $itemCounts[16] - $PreRunWintersdayGifts
	Local $RunIncomeTrickOrTreats = $itemCounts[17] - $PreRunTrickOrTreats
	Local $RunIncomeBirthdayCupcakes = $itemCounts[18] - $PreRunBirthdayCupcakes
	Local $RunIncomeGoldenEggs = $itemCounts[19] - $PreRunGoldenEggs
	Local $RunIncomePumpkinPieSlices = $itemCounts[20] - $PreRunPumpkinPieSlices
	Local $RunIncomeHoneyCombs = $itemCounts[21] - $PreRunHoneyCombs
	Local $RunIncomeFruitCakes = $itemCounts[22] - $PreRunFruitCakes
	Local $RunIncomeSugaryBlueDrinks = $itemCounts[23] - $PreRunSugaryBlueDrinks
	Local $RunIncomeChocolateBunnies = $itemCounts[24] - $PreRunChocolateBunnies
	Local $RunIncomeDeliciousCakes = $itemCounts[25] - $PreRunDeliciousCakes
	Local $RunIncomeAmberChunks = $itemCounts[26] - $PreRunAmberChunks
	Local $RunIncomeJadeiteShards = $itemCounts[27] - $PreRunJadeiteShards

	; If income is positive then updating cumulative item stats. Income is negative when selling or storing items in chest
	If $RunIncomeGold > 0 Then $TotalGold += $RunIncomeGold
	If $RunIncomeGoldItems > 0 Then $TotalGoldItems += $RunIncomeGoldItems
	If $RunIncomeEctos > 0 Then $TotalEctos += $RunIncomeEctos
	If $RunIncomeObsidianShards > 0 Then $TotalObsidianShards += $RunIncomeObsidianShards
	If $RunIncomeLockpicks > 0 Then $TotalLockpicks += $RunIncomeLockpicks
	If $RunIncomeMargoniteGemstones > 0 Then $TotalMargoniteGemstones += $RunIncomeMargoniteGemstones
	If $RunIncomeStygianGemstones > 0 Then $TotalStygianGemstones += $RunIncomeStygianGemstones
	If $RunIncomeTitanGemstones > 0 Then $TotalTitanGemstones += $RunIncomeTitanGemstones
	If $RunIncomeTormentGemstones > 0 Then $TotalTormentGemstones += $RunIncomeTormentGemstones
	If $RunIncomeDiessaChalices > 0 Then $TotalDiessaChalices += $RunIncomeDiessaChalices
	If $RunIncomeRinRelics > 0 Then $TotalRinRelics += $RunIncomeRinRelics
	If $RunIncomeDestroyerCores > 0 Then $TotalDestroyerCores += $RunIncomeDestroyerCores
	If $RunIncomeGlacialStones > 0 Then $TotalGlacialStones += $RunIncomeGlacialStones
	If $RunIncomeWarSupplies > 0 Then $TotalWarSupplies += $RunIncomeWarSupplies
	If $RunIncomeMinisterialCommendations > 0 Then $TotalMinisterialCommendations += $RunIncomeMinisterialCommendations
	If $RunIncomeJadeBracelets > 0 Then $TotalJadeBracelets += $RunIncomeJadeBracelets
	If $RunIncomeChunksOfDrakeFlesh > 0 Then $TotalChunksOfDrakeFlesh += $RunIncomeChunksOfDrakeFlesh
	If $RunIncomeSkaleFins > 0 Then $TotalSkaleFins += $RunIncomeSkaleFins
	If $RunIncomeWintersdayGifts > 0 Then $TotalWintersdayGifts += $RunIncomeWintersdayGifts
	If $RunIncomeTrickOrTreats > 0 Then $TotalTrickOrTreats += $RunIncomeTrickOrTreats
	If $RunIncomeBirthdayCupcakes > 0 Then $TotalBirthdayCupcakes += $RunIncomeBirthdayCupcakes
	If $RunIncomeGoldenEggs > 0 Then $TotalGoldenEggs += $RunIncomeGoldenEggs
	If $RunIncomePumpkinPieSlices > 0 Then $TotalPumpkinPieSlices += $RunIncomePumpkinPieSlices
	If $RunIncomeHoneyCombs > 0 Then $TotalHoneyCombs += $RunIncomeHoneyCombs
	If $RunIncomeFruitCakes > 0 Then $TotalFruitCakes += $RunIncomeFruitCakes
	If $RunIncomeSugaryBlueDrinks > 0 Then $TotalSugaryBlueDrinks += $RunIncomeSugaryBlueDrinks
	If $RunIncomeChocolateBunnies > 0 Then $TotalChocolateBunnies += $RunIncomeChocolateBunnies
	If $RunIncomeDeliciousCakes > 0 Then $TotalDeliciousCakes += $RunIncomeDeliciousCakes
	If $RunIncomeAmberChunks > 0 Then $TotalAmberChunks += $RunIncomeAmberChunks
	If $RunIncomeJadeiteShards > 0 Then $TotalJadeiteShards += $RunIncomeJadeiteShards

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


;~ Update the progress bar
Func UpdateProgressBar($totalDuration = 0)
	Local Static $duration
	If IsDeclared('totalDuration') And $totalDuration <> 0 Then
		$duration = $totalDuration
	EndIf
	Local $progress = Floor((TimerDiff($RUN_TIMER) / $duration) * 100)
	If $progress > 98 Then $progress = 98 ; capping run progess at 98%
	GUICtrlSetData($GUI_FarmProgress, $progress)
EndFunc


;~ Select correct farm duration
Func SelectFarmDuration($Farm)
	Switch $Farm
		Case 'Asuran'
			Return $ASURAN_FARM_DURATION
		Case 'Boreal'
			Return $BOREAL_FARM_DURATION
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
		Case 'Kournans'
			Return $KOURNANS_FARM_DURATION
		Case 'Kurzick'
			Return $KURZICKS_FARM_DURATION
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


#Region Utils
Func IsHardmodeEnabled()
	Return GUICtrlRead($GUI_Checkbox_HardMode) == $GUI_CHECKED
EndFunc


Func ConvertTimeToHourString($time)
	Return Floor($time/3600000) & 'h ' & Floor(Mod($time, 3600000)/60000) & 'min ' & Floor(Mod($time, 60000)/1000) & 's'
EndFunc


Func ConvertTimeToMinutesString($time)
	Return Floor($time/60000) & 'min ' & Floor(Mod($time, 60000)/1000) & 's'
EndFunc
#EndRegion Utils