; Author: caustic-kronos (aka Kronos, Night, Svarog)
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
; - change bots to have cleaner return system
; - add true locking mechanism to prevent trying to run several bots on the same account at the same time

; Night's tips and tricks
; - Always refresh agents before getting data from them (agent = snapshot)
;		(so only use $me if you are sure nothing important changes between $me definition and $me usage)
; - AdlibRegister('NotifyHangingBot', 120000) can be used to simulate multithreading

#RequireAdmin
#NoTrayIcon

#Region Includes
; TODO: cleanup needed here, remove any of those if there are no issues showing up
;#include <ButtonConstants.au3>
;#include <EditConstants.au3>
;#include <ComboConstants.au3>
;#include <FileConstants.au3>
;#include <Date.au3>
;#include <GuiEdit.au3>

#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
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
#include 'src/Farm-Corsairs.au3'
#include 'src/Farm-DragonMoss.au3'
#include 'src/Farm-EdenIris.au3'
#include 'src/Farm-Feathers.au3'
#include 'src/Farm-Follower.au3'
#include 'src/Farm-FoW.au3'
#include 'src/Farm-Froggy.au3'
#include 'src/Farm-JadeBrotherhood.au3'
#include 'src/Farm-Kournans.au3'
#include 'src/Farm-Kurzick.au3'
#include 'src/Farm-Lightbringer.au3'
#include 'src/Farm-Luxon.au3'
#include 'src/Farm-Mantids.au3'
#include 'src/Farm-MinisterialCommendations.au3'
#include 'src/Farm-Pongmei.au3'
#include 'src/Farm-Raptors.au3'
#include 'src/Farm-SpiritSlaves.au3'
#include 'src/Farm-SoO.au3'
#include 'src/Farm-Tasca.au3'
#include 'src/Farm-Vaettirs.au3'
#include 'src/Farm-Voltaic.au3'
#include 'src/Farm-Gemstone.au3'
#include 'lib/JSON.au3'
#EndRegion Includes

#Region Variables
Global Const $GW_BOT_HUB_VERSION = '1.0'

Global Const $LVL_DEBUG = 0
Global Const $LVL_INFO = 1
Global Const $LVL_NOTICE = 2
Global Const $LVL_WARNING = 3
Global Const $LVL_ERROR = 4

Global Const $GUI_GREY_COLOR = 13158600
Global Const $GUI_BLUE_COLOR = 11192062
Global Const $GUI_YELLOW_COLOR = 16777192
Global Const $GUI_RED_COLOR = 16751781

Global Const $GUI_CONSOLE_GREY_COLOR = 16777215
Global Const $GUI_CONSOLE_BLUE_COLOR = 0xFF7000
Global Const $GUI_CONSOLE_GREEN_COLOR = 13434828
Global Const $GUI_CONSOLE_YELLOW_COLOR = 0x00FFFF
Global Const $GUI_CONSOLE_RED_COLOR = 0x0000FF

Global Const $GUI_WM_COMMAND = 0x0111
Global Const $GUI_COMBOBOX_DROPDOWN_OPENED = 7


; STOPPED -> INITIALIZED -> RUNNING -> WILL_PAUSE -> PAUSED -> RUNNING
Global $STATUS = 'STOPPED'
; -1 = did not start, 0 = ran fine, 1 = failed, 2 = pause
Global $RUN_MODE = 'AUTOLOAD'
Global $PROCESS_ID = ''
Global $LOG_LEVEL = 1
Global $CHARACTER_NAME = ''
Global $DISTRICT_NAME = 'Random'
Global $BAG_NUMBER = 5
Global $INVENTORY_SPACE_NEEDED = 5
Global $TIMESDEPOSITED = 0

Global $AVAILABLE_FARMS = 'Corsairs|Dragon Moss|Eden Iris|Feathers|Follow|FoW|Froggy|Gemstone|Jade Brotherhood|Kournans|Kurzick|Lightbringer|Luxon|Mantids|Ministerial Commendations|OmniFarm|Pongmei|Raptors|SoO|SpiritSlaves|Tasca|Vaettirs|Voltaic|Storage|Tests|Dynamic'
Global $AVAILABLE_DISTRICTS = '|Random|America|China|English|French|German|International|Italian|Japan|Korea|Polish|Russian|Spanish'
#EndRegion Variables


#Region GUI
Opt('GUIOnEventMode', 1)
Opt('GUICloseOnESC', 0)
Opt('MustDeclareVars', 1)

Global $GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_Tab_Main, $GUI_Tab_RunOptions, $GUI_Tab_LootOptions, $GUI_Tab_FarmInfos, $GUI_Tab_LootComponents
Global $GUI_Console, $GUI_Combo_CharacterChoice, $GUI_Combo_FarmChoice, $GUI_StartButton, $GUI_FarmProgress
Global $GUI_Input_DynamicExecution, $GUI_Button_DynamicExecution, $GUI_Label_BagNumber, $GUI_Input_BagNumber, $GUI_Label_TravelDistrict, $GUI_Combo_DistrictChoice, $GUI_Icon_SaveConfig, $GUI_Combo_ConfigChoice

Global $GUI_Group_RunInfos, _
		$GUI_Label_Runs_Text, $GUI_Label_Runs_Value, $GUI_Label_Failures_Text, $GUI_Label_Failures_Value, $GUI_Label_Time_Text, $GUI_Label_Time_Value, _
		$GUI_Label_TimePerRun_Text, $GUI_Label_TimePerRun_Value, $GUI_Label_Gold_Text, $GUI_Label_Gold_Value, $GUI_Label_Ectos_Text, $GUI_Label_Ectos_Value, _
		$GUI_Label_GoldItems_Text, $GUI_Label_GoldItems_Value, $GUI_Label_Chests_Text, $GUI_Label_Chests_Value, $GUI_Label_Experience_Text, $GUI_Label_Experience_Value
Global $GUI_Group_ItemsLooted, _
		$GUI_Label_ChunkOfDrakeFlesh_Text, $GUI_Label_ChunkOfDrakeFlesh_Value, $GUI_Label_SkaleFins_Text, $GUI_Label_SkaleFins_Value, _
		$GUI_Label_GlacialStones_Text, $GUI_Label_GlacialStones_Value, $GUI_Label_DiessaChalices_Text, $GUI_Label_DiessaChalices_Value, _
		$GUI_Label_RinRelics_Text, $GUI_Label_RinRelics_Value, $GUI_Label_WintersdayGifts_Text, $GUI_Label_WintersdayGifts_Value, _
		$GUI_Label_MargoniteGemstone_Text, $GUI_Label_MargoniteGemstone_Value, $GUI_Label_StygianGemstone_Text, $GUI_Label_StygianGemstone_Value, _
		$GUI_Label_TitanGemstone_Text, $GUI_Label_TitanGemstone_Value, $GUI_Label_TormentGemstone_Text, $GUI_Label_TormentGemstone_Value
Global $GUI_Group_Titles, _
		$GUI_Label_AsuraTitle_Text, $GUI_Label_AsuraTitle_Value, $GUI_Label_DeldrimorTitle_Text, $GUI_Label_DeldrimorTitle_Value, $GUI_Label_NornTitle_Text, $GUI_Label_NornTitle_Value, _
		$GUI_Label_VanguardTitle_Text, $GUI_Label_VanguardTitle_Value, $GUI_Label_KurzickTitle_Text, $GUI_Label_KurzickTitle_Value, $GUI_Label_LuxonTitle_Text, $GUI_Label_LuxonTitle_Value, _
		$GUI_Label_LightbringerTitle_Text, $GUI_Label_LightbringerTitle_Value, $GUI_Label_SunspearTitle_Text, $GUI_Label_SunspearTitle_Value
Global $GUI_Group_GlobalOptions, _
		$GUI_Checkbox_LoopRuns, $GUI_Checkbox_HM, $GUI_Checkbox_StoreUnidentifiedGoldItems, $GUI_Checkbox_SortItems, $GUI_Checkbox_CollectData, $GUI_Checkbox_IdentifyGoldItems, _
		$GUI_Checkbox_SalvageItems, $GUI_Checkbox_SellItems, $GUI_Checkbox_SellMaterials, $GUI_Checkbox_StoreTheRest, $GUI_Checkbox_StoreGold, $GUI_Checkbox_BuyEctoplasm
Global $GUI_Group_ConsumableOptions, $GUI_Checkbox_UseConsumables, $GUI_Checkbox_FarmMaterials
Global $GUI_Group_BaseLootOptions, _
		$GUI_Checkbox_LootEverything, $GUI_Checkbox_LootNothing, $GUI_Checkbox_LootRareMaterials, $GUI_Checkbox_LootBasicMaterials, $GUI_Checkbox_LootKeys, $GUI_Checkbox_LootSalvageItems, _
		$GUI_Checkbox_LootTomes, $GUI_Checkbox_LootDyes, $GUI_Checkbox_LootScrolls
Global $GUI_Group_RarityLootOptions, _
		$GUI_Checkbox_LootGoldItems, $GUI_Checkbox_LootPurpleItems, $GUI_Checkbox_LootBlueItems, $GUI_Checkbox_LootWhiteItems, $GUI_Checkbox_LootGreenItems
Global $GUI_Group_FarmSpecificLootOptions, _
		$GUI_Checkbox_LootGlacialStones, $GUI_Checkbox_LootMapPieces, $GUI_Checkbox_LootTrophies
Global $GUI_Group_ConsumablesLootOption, _
		$GUI_Checkbox_LootCandyCaneShards, $GUI_Checkbox_LootLunarTokens, $GUI_Checkbox_LootToTBags, $GUI_Checkbox_LootFestiveItems, $GUI_Checkbox_LootAlcohols, $GUI_Checkbox_LootSweets
Global $GUI_Label_CharacterBuild, $GUI_Label_HeroBuild, $GUI_Edit_CharacterBuild, $GUI_Edit_HeroBuild, $GUI_Label_FarmInformations
Global $GUI_TreeView_Components, $GUI_JSON_Components, $GUI_ExpandComponentsButton, $GUI_ReduceComponentsButton, $GUI_LoadComponentsButton, $GUI_SaveComponentsButton, $GUI_ApplyComponentsButton
Global $GUI_Label_ToDoList


;------------------------------------------------------
; Title...........:	_guiCreate
; Description.....:	Create the main GUI
;------------------------------------------------------
Func createGUI()
	$GUI_GWBotHub = GUICreate('GW Bot Hub', 600, 450, 851, 263)
	GUISetBkColor($GUI_GREY_COLOR, $GUI_GWBotHub)

	$GUI_Combo_CharacterChoice = GUICtrlCreateCombo('No character selected', 10, 420, 136, 20)
	$GUI_Combo_FarmChoice = GUICtrlCreateCombo('Choose a farm', 155, 420, 136, 20)
	GUICtrlSetData($GUI_Combo_FarmChoice, $AVAILABLE_FARMS, 'Choose a farm')
	GUICtrlSetOnEvent($GUI_Combo_FarmChoice, 'GuiButtonHandler')
	$GUI_StartButton = GUICtrlCreateButton('Start', 300, 420, 136, 21)
	GUICtrlSetBkColor($GUI_StartButton, $GUI_BLUE_COLOR)
	GUICtrlSetOnEvent($GUI_StartButton, 'GuiButtonHandler')
	GUISetOnEvent($GUI_EVENT_CLOSE, 'GuiButtonHandler')
	$GUI_FarmProgress = GUICtrlCreateProgress(445, 420, 141, 21)

	$GUI_Tabs_Parent = GUICtrlCreateTab(10, 10, 581, 401)
	$GUI_Tab_Main = GUICtrlCreateTabItem('Main')
	GUICtrlSetOnEvent($GUI_Tabs_Parent, 'GuiButtonHandler')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)

	$GUI_Console = _GUICtrlRichEdit_Create($GUI_GWBotHub, '', 20, 175, 271, 226, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	_GUICtrlRichEdit_SetCharColor($GUI_Console, $GUI_CONSOLE_GREY_COLOR)
	_GUICtrlRichEdit_SetBkColor($GUI_Console, 0)

	; === Run Infos ===
	$GUI_Group_RunInfos = GUICtrlCreateGroup('Infos', 21, 39, 271, 126)
	$GUI_Label_Runs_Text = GUICtrlCreateLabel('Runs:', 31, 64, 65, 16)
	$GUI_Label_Runs_Value = GUICtrlCreateLabel('0', 91, 64, 50, 16, $SS_RIGHT)
	$GUI_Label_Time_Text = GUICtrlCreateLabel('Time:', 31, 84, 45, 16)
	$GUI_Label_Time_Value = GUICtrlCreateLabel('0', 71, 84, 70, 16, $SS_RIGHT)
	$GUI_Label_Gold_Text = GUICtrlCreateLabel('Gold:', 31, 104, 65, 16)
	$GUI_Label_Gold_Value = GUICtrlCreateLabel('0', 91, 104, 50, 16, $SS_RIGHT)
	$GUI_Label_GoldItems_Text = GUICtrlCreateLabel('Gold Items:', 31, 124, 65, 16)
	$GUI_Label_GoldItems_Value = GUICtrlCreateLabel('0', 91, 124, 50, 16, $SS_RIGHT)
	$GUI_Label_Experience_Text = GUICtrlCreateLabel('Experience:', 31, 144, 65, 16)
	$GUI_Label_Experience_Value = GUICtrlCreateLabel('0', 91, 144, 50, 16, $SS_RIGHT)
	$GUI_Label_Failures_Text = GUICtrlCreateLabel('Failures:', 161, 64, 65, 16)
	$GUI_Label_Failures_Value = GUICtrlCreateLabel('0', 231, 64, 50, 16, $SS_RIGHT)
	$GUI_Label_TimePerRun_Text = GUICtrlCreateLabel('Time per run:', 161, 84, 65, 16)
	$GUI_Label_TimePerRun_Value = GUICtrlCreateLabel('0', 231, 84, 50, 16, $SS_RIGHT)
	$GUI_Label_Ectos_Text = GUICtrlCreateLabel('Ectos:', 161, 104, 65, 16)
	$GUI_Label_Ectos_Value = GUICtrlCreateLabel('0', 231, 104, 50, 16, $SS_RIGHT)
	$GUI_Label_Chests_Text = GUICtrlCreateLabel('Chests:', 161, 124, 65, 16)
	$GUI_Label_Chests_Value = GUICtrlCreateLabel('0', 231, 124, 50, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	; === Items Looted ===
	$GUI_Group_ItemsLooted = GUICtrlCreateGroup('Items', 306, 39, 271, 241)
	$GUI_Label_GlacialStones_Text = GUICtrlCreateLabel('Glacial Stones:', 316, 64, 140, 16)
	$GUI_Label_GlacialStones_Value = GUICtrlCreateLabel('0', 502, 64, 60, 16, $SS_RIGHT)
	$GUI_Label_ChunkOfDrakeFlesh_Text = GUICtrlCreateLabel('Chunk Of Drake Flesh:', 316, 84, 140, 16)
	$GUI_Label_ChunkOfDrakeFlesh_Value = GUICtrlCreateLabel('0', 502, 84, 60, 16, $SS_RIGHT)
	$GUI_Label_SkaleFins_Text = GUICtrlCreateLabel('Skale Fins:', 316, 104, 140, 16)
	$GUI_Label_SkaleFins_Value = GUICtrlCreateLabel('0', 502, 104, 60, 16, $SS_RIGHT)
	$GUI_Label_WintersdayGifts_Text = GUICtrlCreateLabel('Wintersday Gifts:', 316, 124, 140, 16)
	$GUI_Label_WintersdayGifts_Value = GUICtrlCreateLabel('0', 502, 124, 60, 16, $SS_RIGHT)
	$GUI_Label_DiessaChalices_Text = GUICtrlCreateLabel('Diessa Chalices:', 316, 144, 140, 16)
	$GUI_Label_DiessaChalices_Value = GUICtrlCreateLabel('0', 502, 144, 60, 16, $SS_RIGHT)
	$GUI_Label_RinRelics_Text = GUICtrlCreateLabel('Rin Relics:', 316, 164, 140, 16)
	$GUI_Label_RinRelics_Value = GUICtrlCreateLabel('0', 502, 164, 60, 16, $SS_RIGHT)
	$GUI_Label_MargoniteGemstone_Text = GUICtrlCreateLabel('Margonite Gemstone:', 316, 184, 140, 16)
	$GUI_Label_MargoniteGemstone_Value = GUICtrlCreateLabel('0', 502, 184, 60, 16, $SS_RIGHT)
	$GUI_Label_StygianGemstone_Text = GUICtrlCreateLabel('Stygian Gemstone:', 316, 205, 140, 16)
	$GUI_Label_StygianGemstone_Value = GUICtrlCreateLabel('0', 502, 205, 60, 16, $SS_RIGHT)
	$GUI_Label_TitanGemstone_Text = GUICtrlCreateLabel('Titan Gemstone:', 316, 229, 140, 16)
	$GUI_Label_TitanGemstone_Value = GUICtrlCreateLabel('0', 502, 229, 60, 16, $SS_RIGHT)
	$GUI_Label_TormentGemstone_Text = GUICtrlCreateLabel('Torment Gemstone:', 316, 250, 140, 16)
	$GUI_Label_TormentGemstone_Value = GUICtrlCreateLabel('0', 502, 250, 60, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	; === Titles ===
	$GUI_Group_Titles = GUICtrlCreateGroup('Titles', 306, 289, 271, 111)
	$GUI_Label_AsuraTitle_Text = GUICtrlCreateLabel('Asura:', 316, 314, 60, 16)
	$GUI_Label_AsuraTitle_Value = GUICtrlCreateLabel('0', 372, 314, 60, 16, $SS_RIGHT)
	$GUI_Label_DeldrimorTitle_Text = GUICtrlCreateLabel('Deldrimor:', 316, 334, 60, 16)
	$GUI_Label_DeldrimorTitle_Value = GUICtrlCreateLabel('0', 372, 334, 60, 16, $SS_RIGHT)
	$GUI_Label_NornTitle_Text = GUICtrlCreateLabel('Norn:', 316, 354, 60, 16)
	$GUI_Label_NornTitle_Value = GUICtrlCreateLabel('0', 372, 354, 60, 16, $SS_RIGHT)
	$GUI_Label_VanguardTitle_Text = GUICtrlCreateLabel('Vanguard:', 316, 374, 60, 16)
	$GUI_Label_VanguardTitle_Value = GUICtrlCreateLabel('0', 372, 374, 60, 16, $SS_RIGHT)
	$GUI_Label_KurzickTitle_Text = GUICtrlCreateLabel('Kurzick:', 446, 314, 60, 16)
	$GUI_Label_KurzickTitle_Value = GUICtrlCreateLabel('0', 502, 314, 60, 16, $SS_RIGHT)
	$GUI_Label_LuxonTitle_Text = GUICtrlCreateLabel('Luxon:', 446, 334, 60, 16)
	$GUI_Label_LuxonTitle_Value = GUICtrlCreateLabel('0', 502, 334, 60, 16, $SS_RIGHT)
	$GUI_Label_LightbringerTitle_Text = GUICtrlCreateLabel('Lightbringer:', 446, 354, 60, 16)
	$GUI_Label_LightbringerTitle_Value = GUICtrlCreateLabel('0', 502, 354, 60, 16, $SS_RIGHT)
	$GUI_Label_SunspearTitle_Text = GUICtrlCreateLabel('Sunspear:', 446, 374, 60, 16)
	$GUI_Label_SunspearTitle_Value = GUICtrlCreateLabel('0', 502, 374, 60, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	$GUI_Tab_RunOptions = GUICtrlCreateTabItem('Run options')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)

	$GUI_Group_GlobalOptions = GUICtrlCreateGroup('Options', 21, 39, 271, 361)
	$GUI_Checkbox_LoopRuns = GUICtrlCreateCheckbox('Loop Runs', 31, 64, 156, 20)
	$GUI_Checkbox_HM = GUICtrlCreateCheckbox('HM', 31, 94, 156, 20)
	$GUI_Checkbox_StoreUnidentifiedGoldItems = GUICtrlCreateCheckbox('Store Unidentified Gold Items', 31, 124, 156, 20)
	$GUI_Checkbox_SortItems = GUICtrlCreateCheckbox('Sort Items', 31, 154, 156, 20)
	$GUI_Checkbox_IdentifyGoldItems = GUICtrlCreateCheckbox('Identify all items', 31, 184, 156, 20)
	$GUI_Checkbox_CollectData = GUICtrlCreateCheckbox('Collect data', 31, 214, 156, 20)
	$GUI_Checkbox_SalvageItems = GUICtrlCreateCheckbox('Salvage items', 31, 244, 156, 20)
	$GUI_Checkbox_SellMaterials = GUICtrlCreateCheckbox('Sell Materials', 31, 274, 156, 20)
	$GUI_Checkbox_SellItems = GUICtrlCreateCheckbox('Sell Items', 31, 304, 156, 20)
	$GUI_Checkbox_BuyEctoplasm = GUICtrlCreateCheckbox('Buy ectoplasm', 31, 334, 156, 20)
	$GUI_Checkbox_StoreTheRest = GUICtrlCreateCheckbox('Store the rest', 31, 364, 100, 20)
	$GUI_Checkbox_StoreGold = GUICtrlCreateCheckbox('Store Gold', 168, 364, 100, 20)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_ConsumableOptions = GUICtrlCreateGroup('More options', 305, 40, 271, 361)
	$GUI_Checkbox_UseConsumables = GUICtrlCreateCheckbox('Any consumable required by farm', 315, 65, 256, 20)
	$GUI_Label_BagNumber = GUICtrlCreateLabel('Number of bags:', 315, 95, 80, 20)
	$GUI_Input_BagNumber = GUICtrlCreateInput('5', 400, 95, 20, 20, $ES_NUMBER)
	GUICtrlSetOnEvent($GUI_Input_BagNumber, 'GuiButtonHandler')
	$GUI_Label_TravelDistrict = GUICtrlCreateLabel('Travel district:', 315, 125, 70, 20)
	$GUI_Combo_DistrictChoice = GUICtrlCreateCombo('Random', 400, 122, 100, 20)
	GUICtrlSetData($GUI_Combo_DistrictChoice, $AVAILABLE_DISTRICTS, 'Random')
	GUICtrlSetOnEvent($GUI_Combo_DistrictChoice, 'GuiButtonHandler')
	$GUI_Checkbox_FarmMaterials = GUICtrlCreateCheckbox('Farm materials', 315, 154, 256, 20)
	$GUI_Input_DynamicExecution = GUICtrlCreateInput('', 315, 364, 156, 20)
	$GUI_Button_DynamicExecution = GUICtrlCreateButton('Run', 490, 364, 75, 20)
	GUICtrlSetBkColor($GUI_Button_DynamicExecution, $GUI_BLUE_COLOR)
	GUICtrlSetOnEvent($GUI_Button_DynamicExecution, 'GuiButtonHandler')
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	$GUI_Tab_LootOptions = GUICtrlCreateTabItem('Loot options')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)

	$GUI_Group_BaseLootOptions = GUICtrlCreateGroup('Base Loot', 21, 39, 271, 176)
	$GUI_Checkbox_LootEverything = GUICtrlCreateCheckbox('Loot everything', 31, 64, 96, 20)
	$GUI_Checkbox_LootNothing = GUICtrlCreateCheckbox('Loot nothing', 31, 94, 96, 20)
	$GUI_Checkbox_LootRareMaterials = GUICtrlCreateCheckbox('Rare materials', 31, 124, 96, 20)
	$GUI_Checkbox_LootBasicMaterials = GUICtrlCreateCheckbox('Basic materials', 30, 155, 96, 20)
	$GUI_Checkbox_LootSalvageItems = GUICtrlCreateCheckbox('Salvage items', 151, 64, 111, 20)
	$GUI_Checkbox_LootTomes = GUICtrlCreateCheckbox('Tomes', 151, 94, 111, 20)
	$GUI_Checkbox_LootKeys = GUICtrlCreateCheckbox('Keys', 151, 154, 96, 20)
	$GUI_Checkbox_LootDyes = GUICtrlCreateCheckbox('Dyes (all)', 31, 184, 96, 20)
	$GUI_Checkbox_LootScrolls = GUICtrlCreateCheckbox('Scrolls', 151, 124, 111, 20)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_RarityLootOptions = GUICtrlCreateGroup('Rarity Loot', 166, 224, 126, 176)
	$GUI_Checkbox_LootWhiteItems = GUICtrlCreateCheckbox('White items', 176, 249, 106, 20)
	$GUI_Checkbox_LootBlueItems = GUICtrlCreateCheckbox('Blue items', 176, 279, 106, 20)
	$GUI_Checkbox_LootPurpleItems = GUICtrlCreateCheckbox('Purple items', 176, 309, 106, 20)
	$GUI_Checkbox_LootGoldItems = GUICtrlCreateCheckbox('Gold items', 176, 339, 106, 20)
	$GUI_Checkbox_LootGreenItems = GUICtrlCreateCheckbox('Green items', 176, 369, 106, 20)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_FarmSpecificLootOptions = GUICtrlCreateGroup('Farm Specific', 23, 224, 136, 176)
	$GUI_Checkbox_LootGlacialStones = GUICtrlCreateCheckbox('Glacial Stones', 31, 249, 81, 20)
	$GUI_Checkbox_LootMapPieces = GUICtrlCreateCheckbox('Map pieces', 31, 279, 81, 20)
	$GUI_Checkbox_LootTrophies = GUICtrlCreateCheckbox('Trophies', 30, 310, 81, 20)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_ConsumablesLootOption = GUICtrlCreateGroup('Consumables loot', 306, 39, 271, 361)
	$GUI_Checkbox_LootSweets = GUICtrlCreateCheckbox('Sweets', 316, 64, 121, 20)
	$GUI_Checkbox_LootAlcohols = GUICtrlCreateCheckbox('Alcohols', 446, 64, 121, 20)
	$GUI_Checkbox_LootFestiveItems = GUICtrlCreateCheckbox('Festive Items', 316, 94, 121, 20)
	$GUI_Checkbox_LootToTBags = GUICtrlCreateCheckbox('ToT Bags', 316, 124, 121, 20)
	$GUI_Checkbox_LootLunarTokens = GUICtrlCreateCheckbox('Lunar Tokens', 446, 124, 121, 20)
	$GUI_Checkbox_LootCandyCaneShards = GUICtrlCreateCheckbox('Candy Cane Shards', 446, 94, 121, 20)
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	$GUI_Tab_FarmInfos = GUICtrlCreateTabItem('Farm infos')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)
	$GUI_Label_CharacterBuild = GUICtrlCreateLabel('Character build:', 30, 55, 80, 21)
	$GUI_Edit_CharacterBuild = GUICtrlCreateEdit('', 115, 55, 446, 21, $ES_READONLY, $WS_EX_TOOLWINDOW)
	$GUI_Label_HeroBuild = GUICtrlCreateLabel('Hero build:', 30, 95, 80, 21)
	$GUI_Edit_HeroBuild = GUICtrlCreateEdit('', 115, 95, 446, 21, $ES_READONLY, $WS_EX_TOOLWINDOW)
	$GUI_Label_FarmInformations = GUICtrlCreateLabel('Farm informations:', 30, 135, 531, 156)
	GUICtrlCreateTabItem('')

	$GUI_Tab_LootComponents = GUICtrlCreateTabItem('Loot components')
	$GUI_TreeView_Components = GUICtrlCreateTreeView(80, 45, 500, 355, BitOR($TVS_HASLINES, $TVS_LINESATROOT, $TVS_HASBUTTONS, $TVS_CHECKBOXES, $TVS_FULLROWSELECT))
	$GUI_JSON_Components = LoadUpgradeComponents(@ScriptDir & '/conf/loot/upgrade_components.json')
	BuildTreeViewFromJSON($GUI_TreeView_Components, $GUI_JSON_Components)
	$GUI_ExpandComponentsButton = GUICtrlCreateButton('Expand all', 21, 154, 55, 21)
	GUICtrlSetOnEvent($GUI_ExpandComponentsButton, 'GuiButtonHandler')
	$GUI_ReduceComponentsButton = GUICtrlCreateButton('Reduce all', 21, 184, 55, 21)
	GUICtrlSetOnEvent($GUI_ReduceComponentsButton, 'GuiButtonHandler')
	$GUI_LoadComponentsButton = GUICtrlCreateButton('Load', 21, 214, 55, 21)
	GUICtrlSetOnEvent($GUI_LoadComponentsButton, 'GuiButtonHandler')
	$GUI_SaveComponentsButton = GUICtrlCreateButton('Save', 21, 244, 55, 21)
	GUICtrlSetOnEvent($GUI_SaveComponentsButton, 'GuiButtonHandler')
	$GUI_ApplyComponentsButton = GUICtrlCreateButton('Apply', 21, 274, 55, 21)
	GUICtrlSetOnEvent($GUI_ApplyComponentsButton, 'GuiButtonHandler')
	GUICtrlCreateTabItem('')

	$GUI_Combo_ConfigChoice = GUICtrlCreateCombo('Default Configuration', 425, 12, 136, 20)
	GUICtrlSetOnEvent($GUI_Combo_ConfigChoice, 'GuiButtonHandler')

	$GUI_Icon_SaveConfig = GUICtrlCreatePic(@ScriptDir & '/doc/save.jpg', 565, 12, 20, 20)
	GUICtrlSetOnEvent($GUI_Icon_SaveConfig, 'GuiButtonHandler')

	GUICtrlSetState($GUI_Checkbox_HM, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LoopRuns, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_UseConsumables, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootRareMaterials, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootBasicMaterials, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootKeys, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootSalvageItems, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootTomes, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootScrolls, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootGoldItems, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootGreenItems, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootGlacialStones, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootSweets, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootAlcohols, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootFestiveItems, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootToTBags, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootLunarTokens, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootCandyCaneShards, $GUI_CHECKED)
	GUICtrlSetState($GUI_Checkbox_LootTrophies, $GUI_CHECKED)

	GUIRegisterMsg($WM_COMMAND, 'WM_COMMAND_Handler')
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY_Handler")
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
    Local $notificationHeader = DllStructCreate("hwnd sourceHandle;int controlId;int notificationCode", $paramNotifyStruct)
    Local $sourceHandle = DllStructGetData($notificationHeader, "sourceHandle")
    Local $notificationCode = DllStructGetData($notificationHeader, "notificationCode")

    If $sourceHandle = GUICtrlGetHandle($GUI_TreeView_Components) Then
        Switch $notificationCode
            Case $NM_CLICK
                Local $mousePos = _WinAPI_GetMousePos(True, $sourceHandle)
                Local $hitTestResult = _GUICtrlTreeView_HitTestEx($sourceHandle, DllStructGetData($mousePos, 1), DllStructGetData($mousePos, 2))
                Local $clickedItem = DllStructGetData($hitTestResult, "Item")
                Local $hitFlags = DllStructGetData($hitTestResult, "Flags")

                If $clickedItem <> 0 And BitAND($hitFlags, $TVHT_ONITEMSTATEICON) Then
                    toggleCheckboxCascade($sourceHandle, $clickedItem, True)
                EndIf

            Case $TVN_KEYDOWN
                Local $keyInfo = DllStructCreate("hwnd;int;int;short key;uint", $paramNotifyStruct)
                Local $selectedItem = _GUICtrlTreeView_GetSelection($sourceHandle)
				; Spacebar pressed
                If DllStructGetData($keyInfo, "key") = 0x20 And $selectedItem Then
                    toggleCheckboxCascade($sourceHandle, $selectedItem, True)
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
        Do
            _GUICtrlTreeView_SetChecked($treeViewHandle, $childHandle, $isChecked)
            If _GUICtrlTreeView_GetChildren($treeViewHandle, $childHandle) Then
                toggleCheckboxCascade($treeViewHandle, $childHandle)
            EndIf
            $childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
        Until $childHandle = 0
    EndIf
EndFunc


;~ Cascading checks in the treeview - unused for now
Func CascadeSetChecked($nodeHandle, $checked)
	If Not IsInt($nodeHandle) Then Return
	_GUICtrlTreeView_SetChecked($GUI_TreeView_Components, $nodeHandle, $checked)
	If MapExists($GUI_HandleTree, $nodeHandle) Then
		For $child In $GUI_HandleTree[$nodeHandle]
			CascadeSetChecked($child, $checked)
		Next
	EndIf
EndFunc


;~ Handle start button usage
Func GuiButtonHandler()
	Switch @GUI_CtrlId
		Case $GUI_Tabs_Parent
			TabHandler()
		Case $GUI_Combo_FarmChoice
			UpdateFarmDescription(GUICtrlRead($GUI_Combo_FarmChoice))
		Case $GUI_Input_BagNumber
			$BAG_NUMBER = Number(GUICtrlRead($GUI_Input_BagNumber))
			$BAG_NUMBER = _Max($BAG_NUMBER, 1)
			$BAG_NUMBER = _Min($BAG_NUMBER, 5)
		Case $GUI_Combo_ConfigChoice
			LoadConfiguration(GUICtrlRead($GUI_Combo_ConfigChoice))
		Case $GUI_Combo_DistrictChoice
			$DISTRICT_NAME = GUICtrlRead($GUI_Combo_DistrictChoice)
		Case $GUI_Icon_SaveConfig
			GUICtrlSetState($GUI_Icon_SaveConfig, $GUI_DISABLE)
			Local $filePath = FileSaveDialog('', @ScriptDir & '\conf\characters', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to write JSON configuration.')
			Else
				SaveConfiguration($filePath)
			EndIf
			GUICtrlSetState($GUI_Icon_SaveConfig, $GUI_ENABLE)
		Case $GUI_ExpandComponentsButton
			_GUICtrlTreeView_Expand(GUICtrlGetHandle($GUI_TreeView_Components), 0, True)
		Case $GUI_ReduceComponentsButton
			_GUICtrlTreeView_Expand(GUICtrlGetHandle($GUI_TreeView_Components), 0, False)
		Case $GUI_LoadComponentsButton
			Local $filePath = FileOpenDialog('Please select a valid components file', @ScriptDir & '\conf\loot', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to read JSON components configuration.')
			Else
				$GUI_JSON_Components = LoadUpgradeComponents($filePath)
				_GUICtrlTreeView_DeleteAll($GUI_TreeView_Components)
				BuildTreeViewFromJSON($GUI_TreeView_Components, $GUI_JSON_Components)
			EndIf
		Case $GUI_SaveComponentsButton
			Local $jsonObject = BuildJSONFromTreeView($GUI_TreeView_Components)
			Local $jsonString = _JSON_Generate($jsonObject)
			Local $filePath = FileSaveDialog('', @ScriptDir & '\conf\loot', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to write JSON components configuration.')
			Else
				Local $configFile = FileOpen($filePath, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
				FileWrite($configFile, $jsonString)
				FileClose($configFile)
				Info('Saved components configuration ' & $configFile)
			EndIf
		Case $GUI_ApplyComponentsButton
			RefreshValuableListsFromInterface()
		Case $GUI_Button_DynamicExecution
			DynamicExecution(GUICtrlRead($GUI_Input_DynamicExecution))
		Case $GUI_StartButton
			StartButtonHandler()
		Case $GUI_EVENT_CLOSE
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
		Case 'STOPPED'
			Info('Initializing...')
			If (Authentification() <> 0) Then Return
			$STATUS = 'INITIALIZED'
			Info('Starting...')
			$STATUS = 'RUNNING'
			GUICtrlSetData($GUI_StartButton, 'Pause')
			GUICtrlSetBkColor($GUI_StartButton, $GUI_RED_COLOR)
		Case 'INITIALIZED'
			Info('Starting...')
			$STATUS = 'RUNNING'
		Case 'RUNNING'
			Info('Pausing...')
			GUICtrlSetData($GUI_StartButton, 'Will pause after this run')
			GUICtrlSetState($GUI_StartButton, $GUI_Disable)
			GUICtrlSetBkColor($GUI_StartButton, $GUI_YELLOW_COLOR)
			$STATUS = 'WILL_PAUSE'
		Case 'WILL_PAUSE'
			MsgBox(0, 'Error', 'You should not be able to press Pause when bot is already pausing.')
		Case 'PAUSED'
			Info('Restarting...')
			GUICtrlSetData($GUI_StartButton, 'Pause')
			GUICtrlSetBkColor($GUI_StartButton, $GUI_RED_COLOR)
			$STATUS = 'RUNNING'
		Case Else
			MsgBox(0, 'Error', 'Unknown status "' & $STATUS & '"')
	EndSwitch
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
				$logColor = $GUI_CONSOLE_GREEN_COLOR
			Case $LVL_INFO
				$logColor = $GUI_CONSOLE_GREY_COLOR
			Case $LVL_NOTICE
				$logColor = $GUI_CONSOLE_BLUE_COLOR
			Case $LVL_WARNING
				$logColor = $GUI_CONSOLE_YELLOW_COLOR
			Case $LVL_ERROR
				$logColor = $GUI_CONSOLE_RED_COLOR
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
		$GUI_Combo_CharacterChoice = GUICtrlCreateInput('Character Name Input', 10, 420, 136, 20)
	EndIf
	FillConfigurationCombo()
	LoadDefaultConfiguration()
	BotHubLoop()
EndFunc


;~ Main loop of the program
Func BotHubLoop()
	While True
		Sleep(1000)

		If ($STATUS == 'RUNNING') Then
			If GUICtrlRead($GUI_Checkbox_FarmMaterials) = $GUI_CHECKED Then
				Local $resetRequired = PassiveInventoryManagement()
				If $resetRequired Then ResetBotsSetups()
			EndIf
			Local $Farm = GUICtrlRead($GUI_Combo_FarmChoice)
			Local $success = RunFarmLoop($Farm)
			If ($success == 2 Or GUICtrlRead($GUI_Checkbox_LoopRuns) == $GUI_UNCHECKED) Then
				$STATUS = 'WILL_PAUSE'
			Else
				; During pickup, items will be moved to equipment bag (if used) when first 3 bags are full
				; So bag 5 will always fill before 4 - hence we can count items up to bag 4
				If (CountSlots(1, _Min($BAG_NUMBER, 4)) <= $INVENTORY_SPACE_NEEDED) Then
					ActiveInventoryManagement()
					ResetBotsSetups()
				EndIf
				If (CountSlots(1, $BAG_NUMBER) <= $INVENTORY_SPACE_NEEDED) Then
					Notice('Inventory full, pausing.')
					ResetBotsSetups()
					$STATUS = 'WILL_PAUSE'
				EndIf
			EndIf
		EndIf

		If ($STATUS == 'WILL_PAUSE') Then
			Warn('Paused.')
			$STATUS = 'PAUSED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			; Enabling changing account is non trivial
			;GUICtrlSetState($GUI_Combo_CharacterChoice, $GUI_Enable)
			GUICtrlSetState($GUI_Combo_FarmChoice, $GUI_Enable)
			GUICtrlSetState($GUI_StartButton, $GUI_Enable)
			GUICtrlSetBkColor($GUI_StartButton, $GUI_BLUE_COLOR)
		EndIf
	WEnd
EndFunc


;~ Main loop to run farms
Func RunFarmLoop($Farm)
	Local $result = 2
	Local $timePerRun = UpdateStats(-1, null)
	Local $timer = TimerInit()
	UpdateProgressBar(True, $timePerRun == 0 ? SelectFarmDuration($Farm) : $timePerRun)
	AdlibRegister('UpdateProgressBar', 5000)
	Switch $Farm
		Case 'Choose a farm'
			MsgBox(0, 'Error', 'No farm chosen.')
			$STATUS = 'INITIALIZED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetBkColor($GUI_StartButton, $GUI_BLUE_COLOR)
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
		Case 'Follow'
			$INVENTORY_SPACE_NEEDED = 15
			$result = FollowerFarm($STATUS)
		Case 'FoW'
			$INVENTORY_SPACE_NEEDED = 30
			$result = FoWFarm($STATUS)
		Case 'Froggy'
			$INVENTORY_SPACE_NEEDED = 10
			$result = FroggyFarm($STATUS)
		Case 'Gemstone'
			$INVENTORY_SPACE_NEEDED = 10
			$result = GemstoneFarm($STATUS)
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
		Case 'Luxon'
			$INVENTORY_SPACE_NEEDED = 10
			$result = LuxonFactionFarm($STATUS)
		Case 'Mantids'
			$INVENTORY_SPACE_NEEDED = 5
			$result = MantidsFarm($STATUS)
		Case 'Ministerial Commendations'
			$INVENTORY_SPACE_NEEDED = 5
			$result = MinisterialCommendationsFarm($STATUS)
		Case 'OmniFarm'
			$INVENTORY_SPACE_NEEDED = 5
			$result = OmniFarm($STATUS)
		Case 'Pongmei'
			$INVENTORY_SPACE_NEEDED = 5
			$result = PongmeiChestFarm($STATUS)
		Case 'Raptors'
			$INVENTORY_SPACE_NEEDED = 5
			$result = RaptorFarm($STATUS)
		Case 'SoO'
			$INVENTORY_SPACE_NEEDED = 15
			$result = SoOFarm($STATUS)
		Case 'SpiritSlaves'
			$INVENTORY_SPACE_NEEDED = 5
			$result = SpiritSlavesFarm($STATUS)
		Case 'Tasca'
			$INVENTORY_SPACE_NEEDED = 5
			$result = TascaChestFarm($STATUS)
		Case 'Vaettirs'
			$INVENTORY_SPACE_NEEDED = 5
			$result = VaettirFarm($STATUS)
		Case 'Voltaic'
			$INVENTORY_SPACE_NEEDED = 10
			$result = VoltaicFarm($STATUS)
		Case 'Storage'
			$INVENTORY_SPACE_NEEDED = 5
			ResetBotsSetups()
			$result = ManageInventory($STATUS)
		Case 'Dynamic'
			Info('Dynamic execution')
		Case 'Tests'
			RunTests($STATUS)
		Case Else
			MsgBox(0, 'Error', 'This farm does not exist.')
	EndSwitch
	AdlibUnRegister('UpdateProgressBar')
	GUICtrlSetData($GUI_FarmProgress, 100)
	UpdateStats($result, $timer)
	ClearMemory()
	; _PurgeHook()
	Return $result
EndFunc
#EndRegion Main loops


#Region Setup
;~ Reset the setups of the bots when porting to a city for instance
Func ResetBotsSetups()
	$RAPTORS_FARM_SETUP						= False
	$DM_FARM_SETUP							= False
	$IRIS_FARM_SETUP						= False
	$FEATHERS_FARM_SETUP					= False
	$FOW_FARM_SETUP							= False
	$FROGGY_FARM_SETUP						= False
	$JADE_BROTHERHOOD_FARM_SETUP			= False
	$KOURNANS_FARM_SETUP					= False
	$MANTIDS_FARM_SETUP						= False
	$SOO_FARM_SETUP							= False
	$SPIRIT_SLAVES_FARM_SETUP				= False
	$TASCA_FARM_SETUP						= False
	; Those don't need to be reset - group didn't change, build didn't change, and there is no need to refresh portal
	; BUT those bots MUST tp to the correct map on every loop
	;$FOLLOWER_SETUP						= False
	;$LIGHTBRINGER_FARM_SETUP				= False
	;$MINISTERIAL_COMMENDATIONS_FARM_SETUP	= False
	;$CORSAIRS_FARM_SETUP					= False
	;$PONGMEI_FARM_SETUP					= False
	;$VOLTAIC_FARM_SETUP					= False
EndFunc


;~ Update the farm description written on the rightmost tab
Func UpdateFarmDescription($Farm)
	Switch $Farm
		Case 'Corsairs'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $RACorsairsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $CorsairsFarmInformations)
		Case 'Dragon Moss'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $RADragonMossFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $DragonMossFarmInformations)
		Case 'Eden Iris'
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $EdenIrisFarmInformations)
		Case 'Feathers'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $DAFeathersFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $FeathersFarmInformations)
		Case 'Follow'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $FollowerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $FollowerInformations)
		Case 'FoW'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $FoWFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $FoWFarmInformations)
		Case 'Froggy'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $FroggyFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $FroggyFarmInformations)
		Case 'Gemstone'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $GemstoneFarmSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, $GemstoneHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $GemstoneFarmInformations)
		Case 'Jade Brotherhood'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $JB_Skillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, $JB_Hero_Skillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $JB_FarmInformations)
		Case 'Kournans'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $ElAKournansFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $KournansFarmInformations)
		Case 'Kurzick'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $KurzickFactionSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $KurzickFactionInformations)
		Case 'Lightbringer'
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $LightbringerFarmInformations)
		Case 'Luxon'
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $LuxonFactionInformations)
		Case 'Mantids'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $RAMantidsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, $MantidsHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $MantidsFarmInformations)
		Case 'Ministerial Commendations'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $DWCommendationsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $CommendationsFarmInformations)
		Case 'OmniFarm'
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, '')
		Case 'Pongmei'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $PongmeiChestRunnerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $PongmeiChestRunInformations)
		Case 'Raptors'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $WNRaptorFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, $PRunnerHeroSkillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $RaptorsFarmInformations)
		Case 'SoO'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $SoOFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $SoOFarmInformations)
		Case 'SpiritSlaves'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $SpiritSlaves_Skillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $SpiritSlavesFarmInformations)
		Case 'Tasca'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $TascaChestRunnerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $TascaChestRunInformations)
		Case 'Vaettirs'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $AMeVaettirsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $VaettirsFarmInformations)
		Case 'Voltaic'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $VoltaicFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $VoltaicFarmInformations)
		Case 'Storage'
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, '')
		Case Else
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, '')
	EndSwitch
EndFunc
#EndRegion Setup


#Region Configuration
;~ Fill the choice of configuration
Func FillConfigurationCombo($configuration = 'Default Configuration')
	Local $files = _FileListToArray(@ScriptDir & '/conf/characters/', '*.json', $FLTA_FILES)
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


;~ Load default configuration if it exists
Func LoadDefaultConfiguration()
	If FileExists(@ScriptDir & '/conf/Default Configuration.json') Then
		Local $configFile = FileOpen(@ScriptDir & '/conf/characters/Default Configuration.json' , $FO_READ + $FO_UTF8)
		Local $jsonString = FileRead($configFile)
		ReadConfigFromJson($jsonString)
		FileClose($configFile)
		Info('Loaded default configuration')
	EndIf
EndFunc


;~ Change to a different configuration
Func LoadConfiguration($configuration)
	Local $configFile = FileOpen(@ScriptDir & '/conf/characters/' & $configuration & '.json' , $FO_READ + $FO_UTF8)
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
	_JSON_addChangeDelete($jsonObject, 'run.loop_mode', GUICtrlRead($GUI_Checkbox_LoopRuns) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.hard_mode', GUICtrlRead($GUI_Checkbox_HM) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.store_unid', GUICtrlRead($GUI_Checkbox_StoreUnidentifiedGoldItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.sort_items', GUICtrlRead($GUI_Checkbox_SortItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.identify_items', GUICtrlRead($GUI_Checkbox_IdentifyGoldItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.collect_data', GUICtrlRead($GUI_Checkbox_CollectData) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.salvage_items', GUICtrlRead($GUI_Checkbox_SalvageItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.sell_materials', GUICtrlRead($GUI_Checkbox_SellMaterials) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.sell_items', GUICtrlRead($GUI_Checkbox_SellItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.buy_ectos', GUICtrlRead($GUI_Checkbox_BuyEctoplasm) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.store_leftovers', GUICtrlRead($GUI_Checkbox_StoreTheRest) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.store_gold', GUICtrlRead($GUI_Checkbox_StoreGold) == 1)
	_JSON_addChangeDelete($jsonObject, 'run.district', GUICtrlRead($GUI_Combo_DistrictChoice))
	_JSON_addChangeDelete($jsonObject, 'run.bag_number', Number(GUICtrlRead($GUI_Input_BagNumber)))
	_JSON_addChangeDelete($jsonObject, 'run.farm_materials', Number(GUICtrlRead($GUI_Checkbox_FarmMaterials)))
	_JSON_addChangeDelete($jsonObject, 'consumables.consume', GUICtrlRead($GUI_Checkbox_UseConsumables) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.everything', GUICtrlRead($GUI_Checkbox_LootEverything) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.nothing', GUICtrlRead($GUI_Checkbox_LootNothing) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.rare_materials', GUICtrlRead($GUI_Checkbox_LootRareMaterials) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.base_materials', GUICtrlRead($GUI_Checkbox_LootBasicMaterials) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.all_dyes', GUICtrlRead($GUI_Checkbox_LootDyes) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.salvageable_items', GUICtrlRead($GUI_Checkbox_LootSalvageItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.tomes', GUICtrlRead($GUI_Checkbox_LootTomes) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.scrolls', GUICtrlRead($GUI_Checkbox_LootScrolls) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.keys', GUICtrlRead($GUI_Checkbox_LootKeys) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.farm.glacial_stones', GUICtrlRead($GUI_Checkbox_LootGlacialStones) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.farm.map_pieces', GUICtrlRead($GUI_Checkbox_LootMapPieces) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.farm.trophies', GUICtrlRead($GUI_Checkbox_LootTrophies) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.rarities.white', GUICtrlRead($GUI_Checkbox_LootWhiteItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.rarities.blue', GUICtrlRead($GUI_Checkbox_LootBlueItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.rarities.purple', GUICtrlRead($GUI_Checkbox_LootPurpleItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.rarities.gold', GUICtrlRead($GUI_Checkbox_LootGoldItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.rarities.green', GUICtrlRead($GUI_Checkbox_LootGreenItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.consumables.sweets', GUICtrlRead($GUI_Checkbox_LootSweets) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.consumables.alcohols', GUICtrlRead($GUI_Checkbox_LootAlcohols) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.consumables.festive', GUICtrlRead($GUI_Checkbox_LootFestiveItems) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.consumables.trick_or_treat_bags', GUICtrlRead($GUI_Checkbox_LootToTBags) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.consumables.candy_cane_shards', GUICtrlRead($GUI_Checkbox_LootCandyCaneShards) == 1)
	_JSON_addChangeDelete($jsonObject, 'loot.consumables.lunar_tokens', GUICtrlRead($GUI_Checkbox_LootLunarTokens) == 1)
	Return _JSON_Generate($jsonObject)
EndFunc


;~ Read given config from JSON
Func ReadConfigFromJson($jsonString)
	Local $jsonObject = _JSON_Parse($jsonString)
	GUICtrlSetData($GUI_Combo_CharacterChoice, _JSON_Get($jsonObject, 'main.character'))
	GUICtrlSetData($GUI_Combo_FarmChoice, _JSON_Get($jsonObject, 'main.farm'))
	UpdateFarmDescription(_JSON_Get($jsonObject, 'main.farm'))
	GUICtrlSetState($GUI_Checkbox_LoopRuns, _JSON_Get($jsonObject, 'run.loop_mode') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_HM, _JSON_Get($jsonObject, 'run.hard_mode') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_StoreUnidentifiedGoldItems, _JSON_Get($jsonObject, 'run.store_unid') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_SortItems, _JSON_Get($jsonObject, 'run.sort_items') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_IdentifyGoldItems, _JSON_Get($jsonObject, 'run.identify_items') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_CollectData, _JSON_Get($jsonObject, 'run.collect_data') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_SalvageItems, _JSON_Get($jsonObject, 'run.salvage_items') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_SellMaterials, _JSON_Get($jsonObject, 'run.sell_materials') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_SellItems, _JSON_Get($jsonObject, 'run.sell_items') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_BuyEctoplasm, _JSON_Get($jsonObject, 'run.buy_ectos') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_StoreTheRest, _JSON_Get($jsonObject, 'run.store_leftovers') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_StoreGold, _JSON_Get($jsonObject, 'run.store_gold') ? $GUI_CHECKED : $GUI_UNCHECKED)
	Local $district = _JSON_Get($jsonObject, 'run.district')
	GUICtrlSetData($GUI_Combo_DistrictChoice, $AVAILABLE_DISTRICTS, $district)
	$DISTRICT_NAME = $district
	Local $bagNumber = _JSON_Get($jsonObject, 'run.bag_number')
	$bagNumber = _Max($bagNumber, 1)
	$bagNumber = _Min($bagNumber, 5)
	$BAG_NUMBER = $bagNumber
	GUICtrlSetData($GUI_Input_BagNumber, $bagNumber)
	GUICtrlSetState($GUI_Checkbox_FarmMaterials, _JSON_Get($jsonObject, 'run.farm_materials') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_UseConsumables, _JSON_Get($jsonObject, 'consumables.consume') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootEverything, _JSON_Get($jsonObject, 'loot.everything') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootNothing, _JSON_Get($jsonObject, 'loot.nothing') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootRareMaterials, _JSON_Get($jsonObject, 'loot.rare_materials') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootBasicMaterials, _JSON_Get($jsonObject, 'loot.base_materials') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootDyes, _JSON_Get($jsonObject, 'loot.all_dyes') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootSalvageItems, _JSON_Get($jsonObject, 'loot.salvageable_items') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootTomes, _JSON_Get($jsonObject, 'loot.tomes') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootScrolls, _JSON_Get($jsonObject, 'loot.scrolls') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootKeys, _JSON_Get($jsonObject, 'loot.keys') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootGlacialStones, _JSON_Get($jsonObject, 'loot.farm.glacial_stones') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootMapPieces, _JSON_Get($jsonObject, 'loot.farm.map_pieces') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootTrophies, _JSON_Get($jsonObject, 'loot.farm.trophies') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootWhiteItems, _JSON_Get($jsonObject, 'loot.rarities.white') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootBlueItems, _JSON_Get($jsonObject, 'loot.rarities.blue') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootPurpleItems, _JSON_Get($jsonObject, 'loot.rarities.purple') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootGoldItems, _JSON_Get($jsonObject, 'loot.rarities.gold') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootGreenItems, _JSON_Get($jsonObject, 'loot.rarities.green') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootSweets, _JSON_Get($jsonObject, 'loot.consumables.sweets') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootAlcohols, _JSON_Get($jsonObject, 'loot.consumables.alcohols') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootFestiveItems, _JSON_Get($jsonObject, 'loot.consumables.festive') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootToTBags, _JSON_Get($jsonObject, 'loot.consumables.trick_or_treat_bags') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootCandyCaneShards, _JSON_Get($jsonObject, 'loot.consumables.candy_cane_shards') ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($GUI_Checkbox_LootLunarTokens, _JSON_Get($jsonObject, 'loot.consumables.lunar_tokens') ? $GUI_CHECKED : $GUI_UNCHECKED)
EndFunc


;~ Creating a treeview from a JSON node
Func BuildTreeViewFromJSON($parentItem, $jsonNode)
	; Unused for now, but might become useful
	Local $GUI_HandleTree[]
	If IsMap($jsonNode) Then
		Local $keys = MapKeys($jsonNode)
		For $i = 0 To UBound($keys) - 1
			Local $keyHandle = GUICtrlCreateTreeViewItem($keys[$i], $parentItem)
			Local $valueHandle = BuildTreeViewFromJSON($keyHandle, $jsonNode[$keys[$i]])
			If $valueHandle == True Then
				_GUICtrlTreeView_SetChecked($GUI_TreeView_Components, $keyHandle, True)
			Else
				$GUI_HandleTree[$keyHandle] = $valueHandle
			EndIf
		Next
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


;~
Func GetComponentsTickedCheckboxes($startingPoint)
	Return BuildArrayFromTreeView($GUI_TreeView_Components, _GUICtrlTreeView_FindItem($GUI_TreeView_Components, $startingPoint))
EndFunc


;~ Creating a JSON node from a treeview
Func BuildJSONFromTreeView($treeViewHandle, $treeViewItem = Null, $currentPath = '')
	Local $jsonObject
	IterateOverTreeView($jsonObject, $treeViewHandle, $treeViewItem, $currentPath, AddLeavesToJSONObject)
	Return $jsonObject
EndFunc


;~ Utility function to add treeview elements to a JSON object
Func AddLeavesToJSONObject(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath)
	Out($currentPath)
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
	; Entry point: no item passed in
	If $treeViewItem == Null Then
		$treeViewItem = _GUICtrlTreeView_GetFirstItem($treeViewHandle)
		While $treeViewItem <> 0
			IterateOverTreeView($context, $treeViewHandle, $treeViewItem, '', $functionToApply)
			$treeViewItem = _GUICtrlTreeView_GetNextSibling($treeViewHandle, $treeViewItem)
		WEnd
		Return
	EndIf

	$currentPath &= ($currentPath = '') ? _GUICtrlTreeView_GetText($treeViewHandle, $treeViewItem) : '.' & _GUICtrlTreeView_GetText($treeViewHandle, $treeViewItem)

	Local $childrenCount = _GUICtrlTreeView_GetChildCount($treeViewHandle, $treeViewItem)
	; We are on a leaf
	If $childrenCount <= 0 Then
		If $functionToApply <> Null Then $functionToApply($context, $treeViewHandle, $treeViewItem, $currentPath)
	ElseIf $childrenCount == 1 Then
		IterateOverTreeView($context, $treeViewHandle, _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem), $currentPath, $functionToApply)
	Else
		Local $currentChild = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem)
		IterateOverTreeView($context, $treeViewHandle, $currentChild, $currentPath, $functionToApply)
		For $i = 1 To $childrenCount - 1
			$currentChild = _GUICtrlTreeView_GetNextChild($treeViewHandle, $currentChild)
			IterateOverTreeView($context, $treeViewHandle, $currentChild, $currentPath, $functionToApply)
		Next
	EndIf
EndFunc


;~ Load upgrade components file if it exists
Func LoadUpgradeComponents($filePath)
	If FileExists($filePath) Then
		Local $componentsFile = FileOpen($filePath, $FO_READ + $FO_UTF8)
		Local $jsonString = FileRead($componentsFile)
		FileClose($componentsFile)
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
			Return 1
		EndIf
	Else
		Local $clientIndex = FindClientIndexByCharacterName($characterName)
		If $clientIndex == -1 Then
			MsgBox(0, 'Error', 'Could not find a GW client with a character named <<' & $characterName & '>>')
			Return 1
		Else
			SelectClient($clientIndex)
			OpenDebugLogFile()
			If InitializeGameClientData(True, True, False) = 0 Then
				MsgBox(0, 'Error', 'Failed game initialisation')
				Return 1
			EndIf
		EndIf
	EndIf
	EnsureEnglish(True)
	GUICtrlSetState($GUI_Combo_CharacterChoice, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_FarmChoice, $GUI_Disable)
	WinSetTitle($GUI_GWBotHub, '', 'GW Bot Hub - ' & $characterName)
	Return 0
EndFunc


;~ Fill characters combobox
Func RefreshCharactersComboBox()
	Local $comboList = ''
	For $i = 1 To $gameClients[0][0]
		If $gameClients[$i][0] <> -1 Then $comboList &= '|' & $gameClients[$i][3]
	Next
	GUICtrlSetData($GUI_Combo_CharacterChoice, $comboList, $gameClients[0][0] > 0 ? $gameClients[1][3] : '')
EndFunc
#EndRegion Authentification and Login


#Region Statistics management
;~ Fill statistics
Func UpdateStats($success, $timer)
	Local Static $itemsToCount[5] = [$ID_Glob_Of_Ectoplasm, $ID_Margonite_Gemstone, $ID_Stygian_Gemstone, $ID_Titan_Gemstone, $ID_Torment_Gemstone]
	Local Static $runs = 0
	Local Static $failures = 0
	Local Static $time = 0

	Local Static $TotalGold = 0
	Local Static $InitialGold = 0
	Local Static $TotalEctos = 0
	Local Static $InitialEctos = 0
	Local Static $TotalGoldItems = 0
	Local Static $InitialGoldItems = 0
	Local Static $TotalChests = 0
	Local Static $ExperienceCount = GetExperience()
	Local Static $TotalMargoniteGemstones = 0
	Local Static $InitialMargoniteGemstones = 0
	Local Static $TotalStygianGemstones = 0
	Local Static $InitialStygianGemstones = 0
	Local Static $TotalTitanGemstones = 0
	Local Static $InitialTitanGemstones = 0
	Local Static $TotalTormentGemstones = 0
	Local Static $InitialTormentGemstones = 0

	Local Static $AsuraTitlePoints = GetAsuraTitle()
	Local Static $DeldrimorTitlePoints = GetDeldrimorTitle()
	Local Static $NornTitlePoints = GetNornTitle()
	Local Static $VanguardTitlePoints = GetVanguardTitle()
	Local Static $LightbringerTitlePoints = GetLightbringerTitle()
	Local Static $SunspearTitlePoints = GetSunspearTitle()
	Local Static $KurzickTitlePoints = GetKurzickTitle()
	Local Static $LuxonTitlePoints = GetLuxonTitle()

	Local $itemCounts = CountTheseItems($itemsToCount)
	Local $goldItemsCount = CountGoldItems()
	Local $goldCharacter = GetGoldCharacter()
	; -1 : Before every farm loop
	If $success == -1 Then
		$InitialGold = $goldCharacter
		$InitialGoldItems = $goldItemsCount
		$InitialEctos = $itemCounts[0]
		$InitialMargoniteGemstones = $itemCounts[1]
		$InitialStygianGemstones = $itemCounts[2]
		$InitialTitanGemstones = $itemCounts[3]
		$InitialTormentGemstones = $itemCounts[4]
	; 0 : Success
	ElseIf $success == 0 Then
		$runs += 1
		$time += TimerDiff($timer)
	; 1 : Failure
	ElseIf $success == 1 Then
		$failures += 1
		$runs += 1
		$time += TimerDiff($timer)
	EndIf
	; 2 : Pause

	; Global stats
	GUICtrlSetData($GUI_Label_Runs_Value, $runs)
	GUICtrlSetData($GUI_Label_Failures_Value, $failures)
	GUICtrlSetData($GUI_Label_Time_Value, Floor($time/3600000) & 'h ' & Floor(Mod($time, 3600000)/60000) & 'min ' & Floor(Mod($time, 60000)/1000) & 's')
	Local $timePerRun = $runs == 0 ? 0 : $time / $runs
	GUICtrlSetData($GUI_Label_TimePerRun_Value, Floor($timePerRun/60000) & 'min ' & Floor(Mod($timePerRun, 60000)/1000) & 's')
	Local $DiffGold = $goldCharacter - $InitialGold
	Local $DiffGoldDeposit = $DiffGold + ($TIMESDEPOSITED * 60000)
	GUICtrlSetData($GUI_Label_Gold_Value, Floor($DiffGoldDeposit/1000) & 'k' & Mod($DiffGoldDeposit, 1000) & 'g')
	$TotalEctos += $itemCounts[0] - $InitialEctos
	GUICtrlSetData($GUI_Label_Ectos_Value, $TotalEctos)
	$TotalGoldItems += $goldItemsCount - $InitialGoldItems
	GUICtrlSetData($GUI_Label_GoldItems_Value, $TotalGoldItems)
	$TotalChests += CountOpenedChests()
	ClearChestsMap()
	GUICtrlSetData($GUI_Label_Chests_Value, $TotalChests)
	GUICtrlSetData($GUI_Label_Experience_Value, (GetExperience() - $ExperienceCount))

	; Items stats
	$TotalMargoniteGemstones += $itemCounts[1] - $InitialMargoniteGemstones
	GUICtrlSetData($GUI_Label_MargoniteGemstone_Value, $TotalMargoniteGemstones)
	$TotalStygianGemstones += $itemCounts[2] - $InitialStygianGemstones
	GUICtrlSetData($GUI_Label_StygianGemstone_Value, $TotalStygianGemstones)
	$TotalTitanGemstones += $itemCounts[3] - $InitialTitanGemstones
	GUICtrlSetData($GUI_Label_TitanGemstone_Value, $TotalTitanGemstones)
	$TotalTormentGemstones += $itemCounts[4] - $InitialTormentGemstones
	GUICtrlSetData($GUI_Label_TormentGemstone_Value, $TotalTormentGemstones)

	; Title stats
	GUICtrlSetData($GUI_Label_AsuraTitle_Value, GetAsuraTitle() - $AsuraTitlePoints)
	GUICtrlSetData($GUI_Label_DeldrimorTitle_Value, GetDeldrimorTitle() - $DeldrimorTitlePoints)
	GUICtrlSetData($GUI_Label_NornTitle_Value, GetNornTitle() - $NornTitlePoints)
	GUICtrlSetData($GUI_Label_VanguardTitle_Value, GetVanguardTitle() - $VanguardTitlePoints)
	GUICtrlSetData($GUI_Label_KurzickTitle_Value, GetKurzickTitle() - $KurzickTitlePoints)
	GUICtrlSetData($GUI_Label_LuxonTitle_Value, GetLuxonTitle() - $LuxonTitlePoints)
	GUICtrlSetData($GUI_Label_LightbringerTitle_Value, GetLightbringerTitle() - $LightbringerTitlePoints)
	GUICtrlSetData($GUI_Label_SunspearTitle_Value, GetSunspearTitle() - $SunspearTitlePoints)

	Return $timePerRun
EndFunc


;~ Update the progress bar
Func UpdateProgressBar($resetTime = False, $totalDuration = 0)
	Local Static $timer
	Local Static $duration
	If IsDeclared('totalDuration') And $totalDuration <> 0 Then
		$duration = $totalDuration
	EndIf
	If IsDeclared('resetTime') And $resetTime Then
		$timer = TimerInit()
	EndIf
	Local $progress = Floor((TimerDiff($timer) / $duration) * 100)
	If $progress > 98 Then $progress = 98
	GUICtrlSetData($GUI_FarmProgress, $progress)
EndFunc


;~ Select correct farm duration
Func SelectFarmDuration($Farm)
	Switch $Farm
		Case 'Corsairs'
			Return $CORSAIRS_FARM_DURATION
		Case 'Dragon Moss'
			Return $DRAGONMOSS_FARM_DURATION
		Case 'Eden Iris'
			Return $IRIS_FARM_DURATION
		Case 'Feathers'
			Return $FEATHERS_FARM_DURATION
		Case 'Follow'
			Return 30 * 60 * 1000
		Case 'Gemstone'
			Return $GEMSTONE_FARM_DURATION
		Case 'Jade Brotherhood'
			Return $JADEBROTHERHOOD_FARM_DURATION
		Case 'Kournans'
			Return $KOURNANS_FARM_DURATION
		Case 'Kurzick'
			Return $KURZICKS_FARM_DURATION
		Case 'Lightbringer'
			Return $LIGHTBRINGER_FARM_DURATION
		Case 'Luxon'
			Return $LUXONS_FARM_DURATION
		Case 'Mantids'
			Return $MANTIDS_FARM_DURATION
		Case 'Ministerial Commendations'
			Return $COMMENDATIONS_FARM_DURATION
		Case 'OmniFarm'
			Return 5 * 60 * 1000
		Case 'Pongmei'
			Return $PONGMEI_FARM_DURATION
		Case 'Raptors'
			Return $RAPTORS_FARM_DURATION
		Case 'SpiritSlaves'
			Return $SPIRIT_SLAVES_FARM_DURATION
		Case 'Tasca'
			Return $TASCA_FARM_DURATION
		Case 'Vaettirs'
			Return $VAETTIRS_FARM_DURATION
		Case 'Voltaic'
			Return $VOLTAIC_FARM_DURATION
		Case 'Storage'
			Return 2 * 60 * 1000
		Case Else
			Return 2 * 60 * 1000
	EndSwitch

EndFunc
#EndRegion Statistics management

#Region Utils
Func IsHardmodeEnabled()
	Return GUICtrlRead($GUI_Checkbox_HM) == $GUI_CHECKED
EndFunc
#EndRegion Utils