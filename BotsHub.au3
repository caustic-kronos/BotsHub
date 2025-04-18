; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

;GUI built with GuiBuilderPlus

; TODO - important:
; - write small bot that : -salvage items -get material ID -write in file salvaged material

; TODO - secondary:
; - change bots to have cleaner return system
; - add option to choose between random travel and specific travel
; - add option for : running bot once, bot X times, bot until inventory full, or bot loop

; BUGLIST :
;

; Night's tips and tricks
; - Always refresh agents before getting data from them (agent = snapshot)
;		(so only use $me if you are sure nothing important changes between $me definition and $me usage)
; - AdlibRegister('NotifyHangingBot', 120000) can be used to simulate multithreading

#RequireAdmin
#NoTrayIcon

#Region Includes
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <ScrollBarsConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <FileConstants.au3>
#include <Date.au3>
#include <GuiEdit.au3>
#include <GuiTab.au3>
#include <GuiRichEdit.au3>

#include 'lib/GWA2_Headers.au3'
#include 'lib/GWA2.au3'
#include 'lib/GWA2_ID.au3'
#include 'src/Farm-Corsairs.au3'
#include 'src/Farm-DragonMoss.au3'
#include 'src/Farm-EdenIris.au3'
#include 'src/Farm-Feathers.au3'
#include 'src/Farm-Follower.au3'
#include 'src/Farm-JadeBrotherhood.au3'
#include 'src/Farm-Kournans.au3'
#include 'src/Farm-Kurzick.au3'
#include 'src/Farm-Lightbringer.au3'
#include 'src/Farm-Luxon.au3'
#include 'src/Farm-Mantids.au3'
#include 'src/Farm-MinisterialCommendations.au3'
;#include 'Farm-Pongmei.au3'
#include 'src/Farm-Raptors.au3'
#include 'src/Farm-SpiritSlaves.au3'
#include 'src/Farm-Vaettirs.au3'
#include 'lib/Utils.au3'
#include 'lib/Utils-OmniFarmer.au3'
#include 'lib/Utils-Storage-Bot.au3'

#EndRegion Includes

#Region Variables
Local Const $GW_BOT_HUB_VERSION = '1.0'
Local Const $GUI_LIGHT_GREY_COLOR = 16777215
Local Const $GUI_GREY_COLOR = 13158600
Local Const $GUI_BLUE_COLOR = 11192062
Local Const $GUI_RED_COLOR = 16751781
Local Const $GUI_YELLOW_COLOR = 16777192
Local Const $GUI_CONSOLE_BLUE_COLOR = 0xFF7000
Local Const $GUI_CONSOLE_GREEN_COLOR = 0xCA4FFF
Local Const $GUI_CONSOLE_YELLOW_COLOR = 0x00FFFF
Local Const $GUI_CONSOLE_RED_COLOR = 0x0000FF

;STOPPED -> INITIALIZED -> RUNNING -> WILL_PAUSE -> PAUSED -> RUNNING
Global $STATUS = 'STOPPED'
;-1 = did not start, 0 = ran fine, 1 = failed, 2 = pause
Local $RUN_MODE = 'AUTOLOAD'
Local $PROCESS_ID = ''
Local $CHARACTER_NAME = ''

Local $AVAILABLE_FARMS = 'Corsairs|Dragon Moss|Eden Iris|Feathers|Follow|Jade Brotherhood|Kournans|Kurzick|Lightbringer|Luxon|Mantids|Ministerial Commendations|OmniFarm|Pongmei|Raptors|SpiritSlaves|Vaettirs|Storage|Tests|Dynamic'
#EndRegion Variables

#Region GUI
Opt('GUIOnEventMode', 1)
Opt('GUICloseOnESC', 0)
Opt('MustDeclareVars', 1)

Local $GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_Tab_Main, $GUI_Tab_RunOptions, $GUI_Tab_LootOptions, $GUI_Tab_FarmInfos, $GUI_Tab_LootComponents
Local $GUI_Combo_CharacterChoice, $GUI_Combo_FarmChoice, $GUI_StartButton, $GUI_FarmProgress

Global $GUI_Console
Global $GUI_Group_RunInfos, $GUI_Label_Runs, $GUI_Label_Failures, $GUI_Label_Time, $GUI_Label_TimePerRun, $GUI_Label_Gold, $GUI_Label_GoldItems, $GUI_Label_Experience

Global $GUI_Group_ItemsLooted, $GUI_Label_ChunkOfDrakeFlesh, $GUI_Label_SkaleFins, $GUI_Label_GlacialStones, $GUI_Label_DiessaChalices, $GUI_Label_RinRelics, $GUI_Label_WintersdayGifts, $GUI_Label_MargoniteGemstone, $GUI_Label_StygianGemstone, $GUI_Label_TitanGemstone, $GUI_Label_TormentGemstone
Global $GUI_Group_Titles, $GUI_Label_AsuraTitle, $GUI_Label_DeldrimorTitle, $GUI_Label_NornTitle, $GUI_Label_VanguardTitle, $GUI_Label_KurzickTitle, $GUI_Label_LuxonTitle, $GUI_Label_LightbringerTitle, $GUI_Label_SunspearTitle
Global $GUI_Group_GlobalOptions, $GUI_Checkbox_LoopRuns, $GUI_Checkbox_HM, $GUI_Checkbox_StoreUnidentifiedGoldItems, $GUI_Checkbox_SortItems, $GUI_Checkbox_CollectData, $GUI_Checkbox_IdentifyGoldItems, $GUI_Checkbox_SalvageItems, $GUI_Checkbox_SellItems, $GUI_Checkbox_SellMaterials, $GUI_Checkbox_StoreTheRest, $GUI_Checkbox_BuyEctoplasm, $GUI_Input_DynamicExecution, $GUI_Button_DynamicExecution
Global $GUI_Group_ConsumableOptions, $GUI_Checkbox_UseConsumables
Global $GUI_Group_BaseLootOptions, $GUI_Checkbox_LootEverything, $GUI_Checkbox_LootNothing, $GUI_Checkbox_LootRareMaterials, $GUI_Checkbox_LootBasicMaterials, $GUI_Checkbox_LootKeys, $GUI_Checkbox_LootSalvageItems, $GUI_Checkbox_LootTomes, $GUI_Checkbox_LootDyes, $GUI_Checkbox_LootScrolls
Global $GUI_Group_RarityLootOptions, $GUI_Checkbox_LootGoldItems, $GUI_Checkbox_LootPurpleItems, $GUI_Checkbox_LootBlueItems, $GUI_Checkbox_LootWhiteItems, $GUI_Checkbox_LootGreenItems
Global $GUI_Group_FarmSpecificLootOptions, $GUI_Checkbox_LootGlacialStones, $GUI_Checkbox_LootMapPieces, $GUI_Checkbox_LootTrophies

Global $GUI_Group_ConsumablesLootOption, $GUI_Checkbox_LootCandyCaneShards, $GUI_Checkbox_LootLunarTokens, $GUI_Checkbox_LootToTBags, $GUI_Checkbox_LootFestiveItems, $GUI_Checkbox_LootAlcohols, $GUI_Checkbox_LootSweets

Global $GUI_Label_CharacterBuild, $GUI_Label_HeroBuild, $GUI_Edit_CharacterBuild, $GUI_Edit_HeroBuild, $GUI_Label_FarmInformations

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
	$GUI_Console = _GUICtrlRichEdit_Create($GUI_GWBotHub, '', 20, 225, 271, 176, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	_GUICtrlRichEdit_SetCharColor($GUI_Console, $GUI_LIGHT_GREY_COLOR)
	_GUICtrlRichEdit_SetBkColor($GUI_Console, 0)

	$GUI_Group_RunInfos = GUICtrlCreateGroup('Infos', 21, 39, 271, 176)
	$GUI_Label_Runs = GUICtrlCreateLabel('Runs: 0', 31, 64, 246, 16)
	$GUI_Label_Failures = GUICtrlCreateLabel('Failures: 0', 31, 84, 246, 16)
	$GUI_Label_Time = GUICtrlCreateLabel('Time: 0', 31, 104, 246, 16)
	$GUI_Label_TimePerRun = GUICtrlCreateLabel('Time per run: 0', 31, 124, 246, 16)
	$GUI_Label_Gold = GUICtrlCreateLabel('Gold: 0', 31, 144, 246, 16)
	$GUI_Label_GoldItems = GUICtrlCreateLabel('Gold Items: 0', 31, 164, 246, 16)
	$GUI_Label_Experience = GUICtrlCreateLabel('Experience: 0', 31, 184, 246, 16)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_ItemsLooted = GUICtrlCreateGroup('Items', 306, 39, 271, 241)
	$GUI_Label_GlacialStones = GUICtrlCreateLabel('Glacial Stones: 0', 316, 64, 246, 16)
	$GUI_Label_ChunkOfDrakeFlesh = GUICtrlCreateLabel('Chunk Of Drake Flesh: 0', 316, 84, 246, 16)
	$GUI_Label_SkaleFins = GUICtrlCreateLabel('Skale Fins: 0', 316, 104, 246, 16)
	$GUI_Label_WintersdayGifts = GUICtrlCreateLabel('Wintersday Gifts: 0', 316, 124, 246, 16)
	$GUI_Label_DiessaChalices = GUICtrlCreateLabel('Diessa Chalices: 0', 316, 144, 246, 16)
	$GUI_Label_RinRelics = GUICtrlCreateLabel('Rin Relics: 0', 316, 164, 246, 16)
	$GUI_Label_MargoniteGemstone = GUICtrlCreateLabel('Margonite Gemstone: 0', 316, 184, 246, 16)
	$GUI_Label_StygianGemstone = GUICtrlCreateLabel('Stygian Gemstone: 0', 315, 205, 246, 16)
	$GUI_Label_TitanGemstone = GUICtrlCreateLabel('Titan Gemstone: 0', 314, 229, 246, 16)
	$GUI_Label_TormentGemstone = GUICtrlCreateLabel('Torment Gemstone: 0', 315, 250, 246, 16)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Group_Titles = GUICtrlCreateGroup('Titles', 306, 289, 271, 111)
	$GUI_Label_AsuraTitle = GUICtrlCreateLabel('Asura: 0', 316, 314, 121, 16)
	$GUI_Label_DeldrimorTitle = GUICtrlCreateLabel('Deldrimor: 0', 316, 334, 121, 16)
	$GUI_Label_NornTitle = GUICtrlCreateLabel('Norn: 0', 316, 354, 121, 16)
	$GUI_Label_VanguardTitle = GUICtrlCreateLabel('Vanguard: 0', 316, 374, 121, 16)
	$GUI_Label_KurzickTitle = GUICtrlCreateLabel('Kurzick: 0', 446, 314, 116, 16)
	$GUI_Label_LuxonTitle = GUICtrlCreateLabel('Luxon: 0', 446, 334, 116, 16)
	$GUI_Label_LightbringerTitle = GUICtrlCreateLabel('Lightbringer: 0', 446, 354, 116, 16)
	$GUI_Label_SunspearTitle = GUICtrlCreateLabel('Sunspear: 0', 446, 374, 116, 16)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$GUI_Tab_RunOptions = GUICtrlCreateTabItem('Run options')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)

	$GUI_Group_GlobalOptions = GUICtrlCreateGroup('Options', 21, 39, 271, 361)
	$GUI_Checkbox_LoopRuns = GUICtrlCreateCheckbox('Loop Runs', 31, 64, 156, 20)
	$GUI_Checkbox_HM = GUICtrlCreateCheckbox('HM', 31, 94, 156, 20)
	$GUI_Checkbox_StoreUnidentifiedGoldItems = GUICtrlCreateCheckbox('Store Unidentified Gold Items', 31, 124, 156, 20)
	$GUI_Checkbox_SortItems = GUICtrlCreateCheckbox('Sort Items', 31, 154, 156, 20)
	$GUI_Checkbox_IdentifyGoldItems = GUICtrlCreateCheckbox('Identify Gold Items', 31, 184, 156, 20)
	$GUI_Checkbox_CollectData = GUICtrlCreateCheckbox('Collect data', 31, 214, 156, 20)
	$GUI_Checkbox_SalvageItems = GUICtrlCreateCheckbox('Salvage items', 31, 244, 156, 20)
	$GUI_Checkbox_SellMaterials = GUICtrlCreateCheckbox('Sell Materials', 31, 274, 156, 20)
	$GUI_Checkbox_SellItems = GUICtrlCreateCheckbox('Sell Items', 31, 304, 156, 20)
	$GUI_Checkbox_BuyEctoplasm = GUICtrlCreateCheckbox('Buy ectoplasm', 31, 334, 156, 20)
	$GUI_Checkbox_StoreTheRest = GUICtrlCreateCheckbox('Store the rest', 31, 364, 156, 20)

	GUICtrlCreateGroup('', -99, -99, 1, 1)
	$GUI_Group_ConsumableOptions = GUICtrlCreateGroup('Consumables to consume', 305, 40, 271, 361)
	$GUI_Checkbox_UseConsumables = GUICtrlCreateCheckbox('Any consumable required by farm', 315, 65, 256, 20)
	$GUI_Input_DynamicExecution = GUICtrlCreateInput('', 315, 364, 156, 20)
	$GUI_Button_DynamicExecution = GUICtrlCreateButton('Run', 490, 364, 75, 20)
	GUICtrlSetBkColor($GUI_Button_DynamicExecution, $GUI_BLUE_COLOR)
	GUICtrlSetOnEvent($GUI_Button_DynamicExecution, 'GuiButtonHandler')
	GUICtrlCreateGroup('', -99, -99, 1, 1)

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

	$GUI_Tab_FarmInfos = GUICtrlCreateTabItem('Farm infos')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)
	$GUI_Label_CharacterBuild = GUICtrlCreateLabel('Character build:', 30, 55, 80, 21)
	$GUI_Edit_CharacterBuild = GUICtrlCreateEdit("", 115, 55, 446, 21, $ES_READONLY, $WS_EX_TOOLWINDOW)
	$GUI_Label_HeroBuild = GUICtrlCreateLabel('Hero build:', 30, 95, 80, 21)
	$GUI_Edit_HeroBuild = GUICtrlCreateEdit("", 115, 95, 446, 21, $ES_READONLY, $WS_EX_TOOLWINDOW)
	
	$GUI_Label_FarmInformations = GUICtrlCreateLabel('Farm informations:', 30, 135, 531, 156)
	$GUI_Tab_LootComponents = GUICtrlCreateTabItem('Loot components')
	_GUICtrlTab_SetBkColor($GUI_GWBotHub, $GUI_Tabs_Parent, $GUI_GREY_COLOR)
	$GUI_Label_ToDoList = GUICtrlCreateLabel('GUI TODO :' & @CRLF _
		& '- add option to choose between random travel and specific travel' & @CRLF _
		& '- add option for running bot once, bot X times, bot until inventory full, or bot loop' & @CRLF _
		& '- write small bot that salvage items (does not work for now), get material ID, write in file salvaged material' & @CRLF _
		& '- change bots to have cleaner return system' & @CRLF _
		& '- change system so that the checkbox are not read by other bots' & @CRLF _
	, 30, 95, 531, 26)
	GUICtrlCreateTabItem('')

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
EndFunc

Func _GUICtrlTab_SetBkColor($gui, $parentTab, $color)
	Local $aTabPos = ControlGetPos($gui, '', $parentTab)
	Local $aTab_Rect = _GUICtrlTab_GetItemRect($parentTab, -1)

	GUICtrlCreateLabel('', $aTabPos[0]+2, $aTabPos[1]+$aTab_Rect[3]+4, $aTabPos[2]-6, $aTabPos[3]-$aTab_Rect[3]-7)
	GUICtrlSetBkColor(-1, $color)
	GUICtrlSetState(-1, $GUI_DISABLE)
EndFunc

;~ Handle start button usage
Func GuiButtonHandler()
	Switch @GUI_CtrlId
		Case $GUI_Tabs_Parent
			Switch GUICtrlRead($GUI_Tabs_Parent)
				Case 0
					ControlShow($GUI_GWBotHub, '', $GUI_Console)
				Case else
					ControlHide($GUI_GWBotHub, '', $GUI_Console)
			EndSwitch
		Case $GUI_Combo_FarmChoice
			Local $Farm = GUICtrlRead($GUI_Combo_FarmChoice)
			UpdateFarmDescription($Farm)
		Case $GUI_Button_DynamicExecution
			DynamicExecution(GUICtrlRead($GUI_Input_DynamicExecution))
		Case $GUI_StartButton
			If $STATUS == 'STOPPED' Then
				Out('Initializing...')
				If (Authentification() <> 0) Then Return
				$STATUS = 'INITIALIZED'

				Out('Starting...')
				$STATUS = 'RUNNING'
				GUICtrlSetData($GUI_StartButton, 'Pause')
				GUICtrlSetBkColor($GUI_StartButton, $GUI_RED_COLOR)
			ElseIf $STATUS == 'INITIALIZED' Then
				Out('Starting...')
				$STATUS = 'RUNNING'
			ElseIf $STATUS == 'RUNNING' Then
				Out('Pausing...')
				GUICtrlSetData($GUI_StartButton, 'Will pause after this run')
				GUICtrlSetState($GUI_StartButton, $GUI_Disable)
				GUICtrlSetBkColor($GUI_StartButton, $GUI_YELLOW_COLOR)
				$STATUS = 'WILL_PAUSE'
			ElseIf $STATUS == 'WILL_PAUSE' Then
				MsgBox(0, 'Error', 'You should not be able to press Pause when bot it already pausing.')
			ElseIf $STATUS == 'PAUSED' Then
				Out('Restarting...')
				GUICtrlSetData($GUI_StartButton, 'Pause')
				GUICtrlSetBkColor($GUI_StartButton, $GUI_RED_COLOR)
				$STATUS = 'RUNNING'
			Else
				MsgBox(0, 'Error', 'Unknown status '' & $STATUS & ''')
			EndIf
		Case $GUI_EVENT_CLOSE
			Exit
		Case else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc

Func TabEventManager()
	Switch GUICtrlRead($GUI_Tabs_Parent)
		Case 0
			ControlShow($GUI_GWBotHub, '', $GUI_Console)
		Case else
			ControlHide($GUI_GWBotHub, '', $GUI_Console)
	EndSwitch
EndFunc

;~ Print to console with timestamp
Func Out($TEXT, $color = $GUI_LIGHT_GREY_COLOR)
	_GUICtrlRichEdit_SetCharColor($GUI_Console, $color)
	_GUICtrlRichEdit_AppendText($GUI_Console, @HOUR & ':' & @MIN & ':' & @SEC & ' - ' & $TEXT & @CRLF)
	UpdateLock()
EndFunc

#EndRegion GUI

main()

;------------------------------------------------------
; Title...........:	_main
; Description.....:	run the main program
;------------------------------------------------------
Func main()
	If @AutoItVersion < '3.3.16.0' Then
		MsgBox(16, 'Error', 'This bot requires AutoIt version 3.3.16.0 or higher. You are using ' & @AutoItVersion & '.')
		Exit
	EndIf

	createGUI()
	GUISetState(@SW_SHOWNORMAL)
	Out('GW Bot Hub ' & $GW_BOT_HUB_VERSION)

	If $CmdLine[0] <> 0 Then
		$RUN_MODE = 'CMD'
		If 1 > UBound($CmdLine)-1 Then
			MsgBox(0, 'Error', 'Element is out of the array bounds.')
			exit
		EndIf
		If 2 > UBound($CmdLine)-1 Then exit

		$CHARACTER_NAME = $CmdLine[1]
		$PROCESS_ID = $CmdLine[2]
		LOGIN($CHARACTER_NAME, $PROCESS_ID)
		$STATUS = 'INITIALIZED'
	ElseIf $RUN_MODE == 'AUTOLOAD' Then
		Local $loggedCharNames = ScanGameClientsForCharacters()
		If ($loggedCharNames[0] > 0) Then
			Local $comboChoices = '|' & _ArrayToString($loggedCharNames, '|', 1)
			GUICtrlSetData($GUI_Combo_CharacterChoice, $comboChoices, $loggedCharNames[1])
		EndIf
	Else
		GUICtrlDelete($GUI_Combo_CharacterChoice)
		$GUI_Combo_CharacterChoice = GUICtrlCreateInput('Character Name Input', 10, 420, 136, 20)
	EndIf

	BotHubLoop()
EndFunc

;~ Main loop of the program
Func BotHubLoop()
	While True
		Sleep(1000)

		If ($STATUS == 'RUNNING') Then
			Local $Farm = GUICtrlRead($GUI_Combo_FarmChoice)
			Local $timer = TimerInit()
			Local $success = RunFarmLoop($Farm)
			UpdateStats($success, $timer)
			
			If ($success == 2 Or GUICtrlRead($GUI_Checkbox_LoopRuns) == $GUI_UNCHECKED) Then
				$STATUS = 'WILL_PAUSE'
			Else
				If (CountSlots(4, 4) < 5) Then 
					PostFarmActions()
					ResetBotsSetups()
				EndIf
				If (CountSlots(4, 4) < 5) Then
					Out('Inventory full, pausing.', $GUI_CONSOLE_RED_COLOR)
					ResetBotsSetups()
					$STATUS = 'WILL_PAUSE'
				EndIf
			EndIf
		Else
			If Random(1, 10, 1) = 1 Then UpdateLock()
		EndIf

		If ($STATUS == 'WILL_PAUSE') Then
			Out('Paused.', $GUI_CONSOLE_BLUE_COLOR)
			$STATUS = 'PAUSED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetState($GUI_Combo_FarmChoice, $GUI_Enable)
			GUICtrlSetState($GUI_StartButton, $GUI_Enable)
			GUICtrlSetBkColor($GUI_StartButton, $GUI_BLUE_COLOR)
		EndIf
	WEnd
EndFunc


Func RunFarmLoop($Farm)
	UpdateStats(-1, null)
	Switch $Farm
		Case 'Choose a farm'
			MsgBox(0, 'Error', 'No farm chosen.')
			$STATUS = 'INITIALIZED'
			GUICtrlSetData($GUI_StartButton, 'Start')
			GUICtrlSetBkColor($GUI_StartButton, $GUI_BLUE_COLOR)
		Case 'Corsairs'
			Return CorsairsFarm($STATUS)
		Case 'Dragon Moss'
			Return DragonMossFarm($STATUS)
		Case 'Eden Iris'
			Return EdenIrisFarm($STATUS)
		Case 'Feathers'
			Return FeathersFarm($STATUS)
		Case 'Follow'
			Return FollowerFarm($STATUS)
		Case 'Jade Brotherhood'
			Return JadeBrotherhoodFarm($STATUS)
		Case 'Kournans'
			Return KournansFarm($STATUS)
		Case 'Kurzick'
			Return KurzickFactionFarm($STATUS)
		Case 'Lightbringer'
			Return LightbringerFarm($STATUS)
		Case 'Luxon'
			Return LuxonFactionFarm($STATUS)
		Case 'Mantids'
			Return MantidsFarm($STATUS)
		Case 'Ministerial Commendations'
			Return MinisterialCommendationsFarm($STATUS)
		Case 'OmniFarm'
			Return OmniFarm($STATUS)
		Case 'Pongmei'
			Return PongmeiChestFarm($STATUS)
		Case 'Raptors'
			Return RaptorFarm($STATUS)
		Case 'SpiritSlaves'
			Return SpiritSlavesFarm($STATUS)
		Case 'Vaettirs'
			Return VaettirFarm($STATUS)
		Case 'Storage'
			Return ManageInventory($STATUS)
		Case 'Dynamic'
			Out('Dynamic execution')
		Case 'Tests'
			RunTests($STATUS)
		Case else
			MsgBox(0, 'Error', 'This farm does not exist.')
	EndSwitch
	Return 2
EndFunc


; Function to deal with inventory during farm
Func DuringFarmActions()
	; This function means we need to have salvaging tools on during farm /!\
	; Not much that can be done during farm other than :
	;-identifying what can be identified
	;-salvaging what can be salvaged
EndFunc

; Function to deal with inventory after farm
Func PostFarmActions()
	; Operations order :
	; 1-Store unid if desired	-> not implemented
	; 2-Sort items
	; 3-Identify items
	; 4-Collect data
	; 5-Salvage ?				-> doesn't work yet
	; 6-Sell materials
	; 7-Sell items
	; 8-Buy ectos with excedent
	; 9-Store items

	If GUICtrlRead($GUI_Checkbox_StoreUnidentifiedGoldItems) == $GUI_CHECKED Then Out("Storing unidentified gold items is not a functionality for now.", $GUI_CONSOLE_RED_COLOR)
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	If GUICtrlRead($GUI_Checkbox_IdentifyGoldItems) == $GUI_CHECKED Then IdentifyAllItems()
	If GUICtrlRead($GUI_Checkbox_CollectData) == $GUI_CHECKED Then 
		ConnectToDatabase()
		InitializeDatabase()
		CompleteModelLookupTable()
		CompleteUpgradeLookupTable()
		StoreAllItemsData()
		DisconnectFromDatabase()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SalvageItems) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Eye_of_the_North Then
			DistrictTravel($ID_Eye_of_the_North, $ID_EUROPE, $ID_FRENCH)
		EndIf
		
		MoveItemsOutOfEquipmentBag()
		;SalvageInscriptions()
		;UpgradeWithSalvageInscriptions()
		;SalvageItems()
		;StoreInXunlaiStorage()
		; Need a second pass at merchant after recycling the inscriptions out
		;If GUICtrlRead($GUI_Checkbox_SellItems) == $GUI_CHECKED Then
		;	SellEverythingToMerchant()
		;EndIf
	EndIf
	If GUICtrlRead($GUI_Checkbox_SellMaterials) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Eye_of_the_North Then
			DistrictTravel($ID_Eye_of_the_North, $ID_EUROPE, $ID_FRENCH)
		EndIf
		
		SellMaterialsToMerchant()
		SellRareMaterialsToMerchant()
	EndIf
	If GUICtrlRead($GUI_Checkbox_SellItems) == $GUI_CHECKED Then
		If GetMapID() <> $ID_Eye_of_the_North Then
			DistrictTravel($ID_Eye_of_the_North, $ID_EUROPE, $ID_FRENCH)
		EndIf
	
		; Can't sell gold scrolls since the function crash
		;If (FindAnyInInventory($Gold_Scrolls_Array)) Then SellGoldScrolls()
		SellEverythingToMerchant()
	EndIf
	If GUICtrlRead($GUI_Checkbox_BuyEctoplasm) == $GUI_CHECKED Then BuyRareMaterialFromMerchantUntilPoor($ID_Glob_of_Ectoplasm, 10000)
	If GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED Then StoreEverythingInXunlaiStorage()
EndFunc


Func ResetBotsSetups()
	$RAPTORS_FARM_SETUP = False
	$DM_FARM_SETUP = False
	$IRIS_FARM_SETUP = False
	$FEATHERS_FARM_SETUP = False
	$FOLLOWER_SETUP = False
	$JADE_BROTHERHOOD_FARM_SETUP = False
	$KOURNANS_FARM_SETUP = False
	$LIGHTBRINGER_FARM_SETUP = False
	$MANTIDS_FARM_SETUP = False
	$MINISTERIAL_COMMENDATIONS_FARM_SETUP = False
	$SPIRIT_SLAVES_FARM_SETUP = False
	$CORSAIRS_FARM_SETUP = False
EndFunc


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
		Case 'Jade Brotherhood'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $JB_Skillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, $JB_Hero_Skillbar)
			GUICtrlSetData($GUI_Label_FarmInformations, $JB_FarmInformations)
		Case 'Kournans'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $ElAKournansFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $CorsairsFarmInformations)
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
		Case 'SpiritSlaves'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $SpiritSlaves_Skillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $SpiritSlavesFarmInformations)
		Case 'Vaettirs'
			GUICtrlSetData($GUI_Edit_CharacterBuild, $AMeVaettirsFarmerSkillbar)
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, $VaettirsFarmInformations)
		Case 'Storage'
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, '')
		Case else
			GUICtrlSetData($GUI_Edit_CharacterBuild, '')
			GUICtrlSetData($GUI_Edit_HeroBuild, '')
			GUICtrlSetData($GUI_Label_FarmInformations, '')
	EndSwitch
EndFunc


#Region Authentification and Login
;~ Initialize connection to GW with the character name or process id given
Func Authentification()
	Local $CharacterName = GUICtrlRead($GUI_Combo_CharacterChoice)
	If ($CharacterName == '') Then
		MsgBox(0, 'Error', 'No character name given.')
		Return 1
	ElseIf($CharacterName == 'No character selected') Then
		Out('Running without authentification.')
	ElseIf $PROCESS_ID And $RUN_MODE == 'CMD' Then
		$proc_id_int = Number($PROCESS_ID, 2)
		Out('Running via pid ' & $proc_id_int)
		If InitializeGameClientData($proc_id_int, True, True, False) = 0 Then
			MsgBox(0, 'Error', 'Could not find a ProcessID or somewhat "' & $proc_id_int & '" ' & VarGetType($proc_id_int) & '')
			Return 1
		EndIf
	Else
		If InitializeGameClientData($CharacterName, True, True, False) = 0 Then
			MsgBox(0, 'Error', 'Could not find a GW client with a character named "' & $CharacterName & '"')
			Return 1
		EndIf
	EndIf
	EnsureEnglish(True)
	GUICtrlSetState($GUI_Combo_CharacterChoice, $GUI_Disable)
	GUICtrlSetState($GUI_Combo_FarmChoice, $GUI_Disable)
	WinSetTitle($GUI_GWBotHub, '', 'GW Bot Hub - ' & GetCharname())
	Return 0
EndFunc

;~ Lock an account for multiboxing
Func UpdateLock()
	Local $characterName = GetCharname()
	If $characterName Then
		Local $fileName = @ScriptDir & '\lock\' & $characterName & '.lock'
		Local $fileHandle = FileOpen($fileName, $FO_OVERWRITE)
		FileWrite($fileHandle, @HOUR & ':' & @MIN)
		FileClose($fileHandle)
	EndIf
EndFunc

; Function to login from cmd, not tested
; TODO: test it
Func LOGIN($char_name = 'fail', $ProcessID = False)
	If $char_name = '' Then
		MsgBox(0, 'Error', 'char_name' & $char_name)
		Exit
	EndIf

	If $ProcessID = False Then
		MsgBox(0, 'Error', 'ProcessID' & $ProcessID)
		Exit
	EndIf

	RndSleep(1000)

	Local $WindowList=WinList('Guild Wars')
	Local $WinHandle = False;

	For $i = 1 to $WindowList[0][0]
		If WinGetProcess($WindowList[$i][1])= $ProcessID Then
			$WinHandle=$WindowList[$i][1]
		EndIf
	Next

	If $WinHandle = False Then
		MsgBox(0, 'Error', 'WinHandle' & $WinHandle)
		Exit
	EndIf

	Local $lCheck = False
	Local $lDeadLock = Timerinit()

	ControlSend($WinHandle, '', '', '{enter}')
	RndSleep(1000)
	WinSetTitle($WinHandle, '', $char_name & ' - Guild Wars')
	Do
		RndSleep(50)
		$lCheck = GetMapLoading() <> 2
	Until $lCheck Or TimerDiff($lDeadLock)>15000

	If $lCheck = False Then
		ControlSend($WinHandle, '', '', '{enter}')
		$lDeadLock = Timerinit()
		Do
			RndSleep(50)
			$lCheck = GetMapLoading() <> 2
		Until $lCheck Or TimerDiff($lDeadLock)>15000
	EndIf

	If $lCheck = False Then
		ControlSend($WinHandle, '', '', '{enter}')
		$lDeadLock = Timerinit()
		Do
			RndSleep(50)
			$lCheck = GetMapLoading() <> 2
		Until $lCheck Or TimerDiff($lDeadLock)>15000
	EndIf

	If $lCheck = False Then
		ControlSend($WinHandle, '', '', '{enter}')
		$lDeadLock = Timerinit()
		Do
			RndSleep(50)
			$lCheck = GetMapLoading() <> 2
		Until $lCheck Or TimerDiff($lDeadLock)>15000
	EndIf

	If $lCheck = False Then
		MsgBox(0, 'Error', 'lcheck')

		ProcessClose($ProcessID)
		Exit
	Else
		RndSleep(3000)
	EndIf
EndFunc

#EndRegion Authentification and Login


#Region Statistics management
;~ Fill statistics
Func UpdateStats($success, $timer)
	Local Static $runs = 0
	Local Static $failures = 0
	Local Static $time = 0

	Local Static $GoldCount = GetGoldCharacter()
	Local Static $ExperienceCount = GetExperience()

	Local Static $AsuraTitlePoints = GetAsuraTitle()
	Local Static $DeldrimorTitlePoints = GetDeldrimorTitle()
	Local Static $NornTitlePoints = GetNornTitle()
	Local Static $VanguardTitlePoints = GetVanguardTitle()
	Local Static $LightbringerTitlePoints = GetLightbringerTitle()
	Local Static $SunspearTitlePoints = GetSunspearTitle()
	Local Static $KurzickTitlePoints = GetKurzickTitle()
	Local Static $LuxonTitlePoints = GetLuxonTitle()
	Local Static $GoldItemsCount = CountGoldItems()
	;Local Static $ItemStacks = CountItemStacks()

	;Either bot did not run yet or ran but was paused
	If $success == 0 Then
		$runs += 1
		$time += TimerDiff($timer)
	ElseIf $success == 1 Then
		$failures += 1
		$runs += 1
		$time += TimerDiff($timer)
	EndIf

	;Global stats
	GUICtrlSetData($GUI_Label_Runs, 'Runs: ' & $runs)
	GUICtrlSetData($GUI_Label_Failures, 'Failures: ' & $failures)
	GUICtrlSetData($GUI_Label_Time, 'Time: ' & Floor($time/3600000) & 'h' & Floor(Mod($time, 3600000)/60000) & 'min' & Floor(Mod($time, 60000)/1000) & 's')
	Local $timePerRun = $runs == 0 ? 0 : $time / $runs
	GUICtrlSetData($GUI_Label_TimePerRun, 'Time per run: ' & Floor($timePerRun/60000) & 'min' & Floor(Mod($timePerRun, 60000)/1000) & 's')
	GUICtrlSetData($GUI_Label_Gold, 'Gold: ' & Floor((GetGoldCharacter() - $GoldCount)/1000) & 'k' & Mod((GetGoldCharacter() - $GoldCount), 1000) & 'g')
	GUICtrlSetData($GUI_Label_GoldItems, 'Gold Items: ' & CountGoldItems() - $GoldItemsCount)
	GUICtrlSetData($GUI_Label_Experience, 'Experience: ' & (GetExperience() - $ExperienceCount))

	;Title stats
	GUICtrlSetData($GUI_Label_AsuraTitle, 'Asura: ' & GetAsuraTitle() - $AsuraTitlePoints)
	GUICtrlSetData($GUI_Label_DeldrimorTitle, 'Deldrimor: ' & GetDeldrimorTitle() - $DeldrimorTitlePoints)
	GUICtrlSetData($GUI_Label_NornTitle, 'Norn: ' & GetNornTitle() - $NornTitlePoints)
	GUICtrlSetData($GUI_Label_VanguardTitle, 'Vanguard: ' & GetVanguardTitle() - $VanguardTitlePoints)
	GUICtrlSetData($GUI_Label_KurzickTitle, 'Kurzick: ' & GetKurzickTitle() - $KurzickTitlePoints)
	GUICtrlSetData($GUI_Label_LuxonTitle, 'Luxon: ' & GetLuxonTitle() - $LuxonTitlePoints)
	GUICtrlSetData($GUI_Label_LightbringerTitle, 'Lightbringer: ' & GetLightbringerTitle() - $LightbringerTitlePoints)
	GUICtrlSetData($GUI_Label_SunspearTitle, 'Sunspear: ' & GetSunspearTitle() - $SunspearTitlePoints)
EndFunc


Func CountGoldItems()
	Local $goldItemsCount = 0
	Local $item
	For $bagIndex = 1 To 5
		Local $bag = GetBag($bagIndex)
		For $i = 1 To DllStructGetData($bag, 'slots')
			$item = GetItemBySlot($bagIndex, $i)
			If DllStructGetData($item, 'ID') = 0 Then ContinueLoop
			If ((IsWeapon($item) Or IsArmorSalvageItem($item)) And GetRarity($item) == $RARITY_Gold) Then $goldItemsCount += 1
		Next
	Next
	Return $goldItemsCount
EndFunc
#EndRegion Statistics management