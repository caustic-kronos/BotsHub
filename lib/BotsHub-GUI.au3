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
#CE ===========================================================================

#RequireAdmin
#NoTrayIcon

#Region Includes
#include <GUIConstantsEx.au3>
#include <GuiListBox.au3>
#include <StaticConstants.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>
#include <ComboConstants.au3>
#include <GuiTab.au3>
#include <GuiRichEdit.au3>
#include <GuiTreeView.au3>

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'
#include '../lib/JSON.au3'
#EndRegion Includes

Global Const $GUI_WA_INACTIVE = 0
Global Const $GUI_WM_ACTIVATE  = 0x0006
Global Const $GUI_WM_COMMAND = 0x0111
Global Const $GUI_COMBOBOX_DROPDOWN_OPENED = 7


Global Const $AVAILABLE_BAG_COUNTS = '|1|2|3|4|5'
Global Const $AVAILABLE_WEAPON_SLOTS = '|0|1|2|3|4'


#Region GUI
Opt('GUIOnEventMode', True)
Opt('GUICloseOnESC', False)
Opt('MustDeclareVars', True)

Global $GUI_ENABLEd = True

; TODO: rename GUI to lowercase snake_case - do it once we move GUI to a separate file
Global $gui_botshub, $gui_tabs_parent, $gui_tab_main, $gui_tab_runoptions, $gui_tab_lootoptions, $gui_tab_farminfos, $gui_tab_lootoptions, $gui_tab_teamoptions
Global $gui_console, $gui_combo_characterchoice, $gui_combo_farmchoice, $gui_startbutton, $gui_farmprogress
Global $gui_label_dynamicexecution, $gui_input_dynamicexecution, $gui_button_dynamicexecution, $gui_renderbutton, $gui_renderlabel, _
		$gui_label_bagscount, $gui_combo_bagscount, $gui_label_traveldistrict, $gui_combo_districtchoice, _
		$gui_label_weaponslot, $gui_combo_weaponslot, $gui_icon_saveconfig, $gui_combo_configchoice

Global $gui_group_runinfos, _
		$gui_label_runs_text, $gui_label_runs_value, $gui_label_successes_text, $gui_label_successes_value, $gui_label_failures_text, $gui_label_failures_value, $gui_label_successratio_text, $gui_label_successratio_value, _
		$gui_label_time_text, $gui_label_time_value, $gui_label_timeperrun_text, $gui_label_timeperrun_value, $gui_label_experience_text, $gui_label_experience_value, $gui_label_chests_text, $gui_label_chests_value, _
		$gui_label_gold_text, $gui_label_gold_value, $gui_label_golditems_text, $gui_label_golditems_value, $gui_label_ectos_text, $gui_label_ectos_value, $gui_label_obsidianshards_text, $gui_label_obsidianshards_value
Global $gui_group_itemslooted, _
		$gui_label_lockpicks_text, $gui_label_lockpicks_value, $gui_label_jadebracelets_text, $gui_label_jadebracelets_value, _
		$gui_label_glacialstones_text, $gui_label_glacialstones_value, $gui_label_destroyercores_text, $gui_label_destroyercores_value, _
		$gui_label_diessachalices_text, $gui_label_diessachalices_value, $gui_label_rinrelics_text, $gui_label_rinrelics_value, _
		$gui_label_warsupplies_text, $gui_label_warsupplies_value, $gui_label_ministerialcommendations_text, $gui_label_ministerialcommendations_value, _
		$gui_label_chunksofdrakeflesh_text, $gui_label_chunksofdrakeflesh_value, $gui_label_skalefins_text, $gui_label_skalefins_value, _
		$gui_label_wintersdaygifts_text, $gui_label_wintersdaygifts_value, $gui_label_deliciouscakes_text, $gui_label_deliciouscakes_value, _
		$gui_label_margonitegemstone_text, $gui_label_margonitegemstone_value, $gui_label_stygiangemstone_text, $gui_label_stygiangemstone_value, _
		$gui_label_titangemstone_text, $gui_label_titangemstone_value, $gui_label_tormentgemstone_text, $gui_label_tormentgemstone_value, _
		$gui_label_trickortreats_text, $gui_label_trickortreats_value, $gui_label_birthdaycupcakes_text, $gui_label_birthdaycupcakes_value, _
		$gui_label_goldeneggs_text, $gui_label_goldeneggs_value, $gui_label_pumpkinpieslices_text, $gui_label_pumpkinpieslices_value, _
		$gui_label_honeycombs_text, $gui_label_honeycombs_value, $gui_label_fruitcakes_text, $gui_label_fruitcakes_value, _
		$gui_label_sugarybluedrinks_text, $gui_label_sugarybluedrinks_value, $gui_label_chocolatebunnies_text, $gui_label_chocolatebunnies_value, _
		$gui_label_amberchunks_text, $gui_label_amberchunks_value, $gui_label_jadeiteshards_text, $gui_label_jadeiteshards_value
Global $gui_group_titles, _
		$gui_label_asuratitle_text, $gui_label_asuratitle_value, $gui_label_deldrimortitle_text, $gui_label_deldrimortitle_value, $gui_label_norntitle_text, $gui_label_norntitle_value, _
		$gui_label_vanguardtitle_text, $gui_label_vanguardtitle_value, $gui_label_kurzicktitle_text, $gui_label_kurzicktitle_value, $gui_label_luxontitle_text, $gui_label_luxontitle_value, _
		$gui_label_lightbringertitle_text, $gui_label_lightbringertitle_value, $gui_label_sunspeartitle_text, $gui_label_sunspeartitle_value
Global $gui_group_runoptions, _
		$gui_checkbox_loopruns, $gui_checkbox_hardmode, $gui_checkbox_automaticteamsetup, $gui_checkbox_useconsumables, $gui_checkbox_usescrolls
Global $gui_group_itemoptions, $gui_checkbox_sortitems, $gui_checkbox_collectdata, $gui_checkbox_farmmaterialsmidrun
Global $gui_group_factionoptions, $gui_label_faction, $gui_radiobutton_donatepoints, $gui_radiobutton_buyfactionresources, $gui_radiobutton_buyfactionscrolls
Global $gui_group_teamoptions, $gui_teamlabel, $gui_teammemberlabel, $gui_teammemberbuildlabel, _
		$gui_label_hero_1, $gui_label_hero_2, $gui_label_hero_3, $gui_label_hero_4, $gui_label_hero_5, $gui_label_hero_6, $gui_label_hero_7, _
		$gui_label_player, $gui_combo_hero_1, $gui_combo_hero_2, $gui_combo_hero_3, $gui_combo_hero_4, $gui_combo_hero_5, $gui_combo_hero_6, $gui_combo_hero_7, _
		$gui_checkbox_load_build_all, $gui_checkbox_load_build_player, $gui_checkbox_load_build_hero_1, $gui_checkbox_load_build_hero_2, $gui_checkbox_load_build_hero_3, _
		$gui_checkbox_load_build_hero_4, $gui_checkbox_load_build_hero_5, $gui_checkbox_load_build_hero_6, $gui_checkbox_load_build_hero_7, _
		$gui_label_build_hero_1, $gui_label_build_hero_2, $gui_label_build_hero_3, $gui_label_build_hero_4, $gui_label_build_hero_5, $gui_label_build_hero_6, $gui_label_build_hero_7, _
		$gui_input_build_player, $gui_input_build_hero_1, $gui_input_build_hero_2, $gui_input_build_hero_3, $gui_input_build_hero_4, $gui_input_build_hero_5, $gui_input_build_hero_6, $gui_input_build_hero_7
Global $gui_group_otheroptions
Global $gui_label_characterbuilds, $gui_label_heroesbuilds, $gui_edit_characterbuilds, $gui_edit_heroesbuilds, $gui_label_farminformations
Global $gui_treeview_lootoptions, $gui_label_lootoptionswarning, $gui_expandlootoptionsbutton, $gui_reducelootoptionsbutton, $gui_loadlootoptionsbutton, $gui_savelootoptionsbutton, $gui_applylootoptionsbutton


;------------------------------------------------------
; Title...........:	_guiCreate
; Description.....:	Create the main GUI
;------------------------------------------------------
Func CreateGUI()
	; -1, -1 automatically positions GUI in the middle of the screen, alternatively can do calculations with inbuilt @DesktopWidth and @DesktopHeight
	$gui_botshub = GUICreate('GW Bot Hub', 650, 500, -1, -1)
	GUISetBkColor($COLOR_SILVER, $gui_botshub)

	; === Buttons common to all tabs ===
	$gui_combo_characterchoice = GUICtrlCreateCombo('No character selected', 10, 470, 150, 20)
	$gui_combo_farmchoice = GUICtrlCreateCombo('Choose a farm', 170, 470, 150, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_startbutton = GUICtrlCreateButton('Start', 330, 470, 150, 21)
	$gui_farmprogress = GUICtrlCreateProgress(490, 470, 150, 21)
	$gui_combo_configchoice = GUICtrlCreateCombo('Default Farm Configuration', 400, 10, 210, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_icon_saveconfig = GUICtrlCreatePic(@ScriptDir & '/doc/save.jpg', 615, 12, 20, 20)
	GUICtrlSetData($gui_combo_farmchoice, $AVAILABLE_FARMS, 'Choose a farm')
	GUICtrlSetBkColor($gui_startbutton, $COLOR_LIGHTBLUE)

	GUISetOnEvent($gui_event_close, 'GuiMainButtonHandler')
	GUICtrlSetOnEvent($gui_startbutton, 'GuiStartButtonHandler')
	GUICtrlSetOnEvent($gui_combo_farmchoice, 'GuiMainButtonHandler')
	GUICtrlSetOnEvent($gui_combo_configchoice, 'GuiMainButtonHandler')
	GUICtrlSetOnEvent($gui_icon_saveconfig, 'GuiMainButtonHandler')

	; === Main tab ===
	$gui_tabs_parent = GUICtrlCreateTab(10, 10, 630, 450)
	$gui_tab_main = GUICtrlCreateTabItem('Main')
	_GUICtrlTab_SetBkColor($gui_botshub, $gui_tabs_parent, $COLOR_SILVER)
	GUICtrlSetOnEvent($gui_tabs_parent, 'GuiTabHandler')

	$gui_console = _GUICtrlRichEdit_Create($gui_botshub, '', 20, 190, 300, 255, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	_GUICtrlRichEdit_SetCharColor($gui_console, $COLOR_WHITE)
	_GUICtrlRichEdit_SetBkColor($gui_console, $COLOR_BLACK)

	; === Run Infos ===
	$gui_group_runinfos = GUICtrlCreateGroup('Informations', 21, 39, 300, 145)
	$gui_label_runs_text = GUICtrlCreateLabel('Runs:', 31, 64, 65, 16)
	$gui_label_runs_value = GUICtrlCreateLabel('0', 110, 64, 50, 16, $SS_RIGHT)
	$gui_label_successes_text = GUICtrlCreateLabel('Successes:', 31, 84, 65, 16)
	$gui_label_successes_value = GUICtrlCreateLabel('0', 110, 84, 50, 16, $SS_RIGHT)
	$gui_label_failures_text = GUICtrlCreateLabel('Failures:', 31, 104, 65, 16)
	$gui_label_failures_value = GUICtrlCreateLabel('0', 110, 104, 50, 16, $SS_RIGHT)
	$gui_label_successratio_text = GUICtrlCreateLabel('Success Ratio:', 31, 124, 85, 16)
	$gui_label_successratio_value = GUICtrlCreateLabel('0', 110, 124, 50, 16, $SS_RIGHT)
	$gui_label_time_text = GUICtrlCreateLabel('Time:', 31, 144, 45, 16)
	$gui_label_time_value = GUICtrlCreateLabel('0', 90, 144, 70, 16, $SS_RIGHT)
	$gui_label_timeperrun_text = GUICtrlCreateLabel('Time per run:', 31, 164, 65, 16)
	$gui_label_timeperrun_value = GUICtrlCreateLabel('0', 110, 164, 50, 16, $SS_RIGHT)

	$gui_label_experience_text = GUICtrlCreateLabel('Experience:', 180, 64, 65, 16)
	$gui_label_experience_value = GUICtrlCreateLabel('0', 260, 64, 50, 16, $SS_RIGHT)
	$gui_label_chests_text = GUICtrlCreateLabel('Chests:', 180, 84, 65, 16)
	$gui_label_chests_value = GUICtrlCreateLabel('0', 260, 84, 50, 16, $SS_RIGHT)
	$gui_label_gold_text = GUICtrlCreateLabel('Gold:', 180, 104, 65, 16)
	$gui_label_gold_value = GUICtrlCreateLabel('0', 260, 104, 50, 16, $SS_RIGHT)
	$gui_label_golditems_text = GUICtrlCreateLabel('Gold Items:', 180, 124, 65, 16)
	$gui_label_golditems_value = GUICtrlCreateLabel('0', 260, 124, 50, 16, $SS_RIGHT)
	$gui_label_ectos_text = GUICtrlCreateLabel('Ectos:', 180, 144, 65, 16)
	$gui_label_ectos_value = GUICtrlCreateLabel('0', 260, 144, 50, 16, $SS_RIGHT)
	$gui_label_obsidianshards_text = GUICtrlCreateLabel('Obsidian Shards:', 180, 164, 85, 16)
	$gui_label_obsidianshards_value = GUICtrlCreateLabel('0', 260, 164, 50, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	; === Items Looted ===
	$gui_group_itemslooted = GUICtrlCreateGroup('Items collected', 330, 39, 295, 290)
	$gui_label_lockpicks_text = GUICtrlCreateLabel('Lockpicks:', 341, 64, 140, 16)
	$gui_label_lockpicks_value = GUICtrlCreateLabel('0', 425, 64, 60, 16, $SS_RIGHT)
	$gui_label_margonitegemstone_text = GUICtrlCreateLabel('Margonite Gemstones:', 341, 84, 140, 16)
	$gui_label_margonitegemstone_value = GUICtrlCreateLabel('0', 425, 84, 60, 16, $SS_RIGHT)
	$gui_label_stygiangemstone_text = GUICtrlCreateLabel('Stygian Gemstones:', 341, 104, 140, 16)
	$gui_label_stygiangemstone_value = GUICtrlCreateLabel('0', 425, 104, 60, 16, $SS_RIGHT)
	$gui_label_titangemstone_text = GUICtrlCreateLabel('Titan Gemstones:', 341, 124, 140, 16)
	$gui_label_titangemstone_value = GUICtrlCreateLabel('0', 425, 124, 60, 16, $SS_RIGHT)
	$gui_label_tormentgemstone_text = GUICtrlCreateLabel('Torment Gemstones:', 341, 144, 140, 16)
	$gui_label_tormentgemstone_value = GUICtrlCreateLabel('0', 425, 144, 60, 16, $SS_RIGHT)
	$gui_label_glacialstones_text = GUICtrlCreateLabel('Glacial Stones:', 341, 164, 140, 16)
	$gui_label_glacialstones_value = GUICtrlCreateLabel('0', 425, 164, 60, 16, $SS_RIGHT)
	$gui_label_destroyercores_text = GUICtrlCreateLabel('Destroyer Cores:', 341, 184, 140, 16)
	$gui_label_destroyercores_value = GUICtrlCreateLabel('0', 425, 184, 60, 16, $SS_RIGHT)
	$gui_label_diessachalices_text = GUICtrlCreateLabel('Diessa Chalices:', 341, 204, 140, 16)
	$gui_label_diessachalices_value = GUICtrlCreateLabel('0', 425, 204, 60, 16, $SS_RIGHT)
	$gui_label_rinrelics_text = GUICtrlCreateLabel('Rin Relics:', 341, 224, 140, 16)
	$gui_label_rinrelics_value = GUICtrlCreateLabel('0', 425, 224, 60, 16, $SS_RIGHT)
	$gui_label_warsupplies_text = GUICtrlCreateLabel('War Supplies:', 341, 244, 140, 16)
	$gui_label_warsupplies_value = GUICtrlCreateLabel('0', 425, 244, 60, 16, $SS_RIGHT)
	$gui_label_ministerialcommendations_text = GUICtrlCreateLabel('Ministerial Commendations:', 341, 264, 140, 16)
	$gui_label_ministerialcommendations_value = GUICtrlCreateLabel('0', 425, 264, 60, 16, $SS_RIGHT)
	$gui_label_jadebracelets_text = GUICtrlCreateLabel('Jade Bracelets:', 341, 284, 140, 16)
	$gui_label_jadebracelets_value = GUICtrlCreateLabel('0', 425, 284, 60, 16, $SS_RIGHT)
	$gui_label_jadeiteshards_text = GUICtrlCreateLabel('Jadeite Shards:', 341, 304, 140, 16)
	$gui_label_jadeiteshards_value = GUICtrlCreateLabel('0', 425, 304, 60, 16, $SS_RIGHT)

	$gui_label_chunksofdrakeflesh_text = GUICtrlCreateLabel('Drake Flesh Chunks:', 495, 64, 140, 16)
	$gui_label_chunksofdrakeflesh_value = GUICtrlCreateLabel('0', 558, 64, 60, 16, $SS_RIGHT)
	$gui_label_skalefins_text = GUICtrlCreateLabel('Skale Fins:', 495, 84, 140, 16)
	$gui_label_skalefins_value = GUICtrlCreateLabel('0', 558, 84, 60, 16, $SS_RIGHT)
	$gui_label_wintersdaygifts_text = GUICtrlCreateLabel('Wintersday Gifts:', 495, 104, 140, 16)
	$gui_label_wintersdaygifts_value = GUICtrlCreateLabel('0', 558, 104, 60, 16, $SS_RIGHT)
	$gui_label_birthdaycupcakes_text = GUICtrlCreateLabel('Birthday Cupcakes:', 495, 124, 140, 16)
	$gui_label_birthdaycupcakes_value = GUICtrlCreateLabel('0', 558, 124, 60, 16, $SS_RIGHT)
	$gui_label_trickortreats_text = GUICtrlCreateLabel('Trick or Treat Bags:', 495, 144, 140, 16)
	$gui_label_trickortreats_value = GUICtrlCreateLabel('0', 558, 144, 60, 16, $SS_RIGHT)
	$gui_label_pumpkinpieslices_text = GUICtrlCreateLabel('Slices of Pumpkin Pie:', 495, 164, 140, 16)
	$gui_label_pumpkinpieslices_value = GUICtrlCreateLabel('0', 558, 164, 60, 16, $SS_RIGHT)
	$gui_label_goldeneggs_text = GUICtrlCreateLabel('Golden Eggs:', 495, 184, 140, 16)
	$gui_label_goldeneggs_value = GUICtrlCreateLabel('0', 558, 184, 60, 16, $SS_RIGHT)
	$gui_label_honeycombs_text = GUICtrlCreateLabel('Honey Combs:', 495, 204, 140, 16)
	$gui_label_honeycombs_value = GUICtrlCreateLabel('0', 558, 204, 60, 16, $SS_RIGHT)
	$gui_label_fruitcakes_text = GUICtrlCreateLabel('Fruit Cakes:', 495, 224, 140, 16)
	$gui_label_fruitcakes_value = GUICtrlCreateLabel('0', 558, 224, 60, 16, $SS_RIGHT)
	$gui_label_sugarybluedrinks_text = GUICtrlCreateLabel('Sugary Blue Drinks:', 495, 244, 140, 16)
	$gui_label_sugarybluedrinks_value = GUICtrlCreateLabel('0', 558, 244, 60, 16, $SS_RIGHT)
	$gui_label_chocolatebunnies_text = GUICtrlCreateLabel('Chocolate Bunnies:', 495, 264, 140, 16)
	$gui_label_chocolatebunnies_value = GUICtrlCreateLabel('0', 558, 264, 60, 16, $SS_RIGHT)
	$gui_label_deliciouscakes_text = GUICtrlCreateLabel('Delicious Cakes:', 495, 284, 140, 16)
	$gui_label_deliciouscakes_value = GUICtrlCreateLabel('0', 558, 284, 60, 16, $SS_RIGHT)
	$gui_label_amberchunks_text = GUICtrlCreateLabel('Amber Chunks:', 495, 304, 140, 16)
	$gui_label_amberchunks_value = GUICtrlCreateLabel('0', 558, 304, 60, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	; === Titles ===
	$gui_group_titles = GUICtrlCreateGroup('Titles', 330, 335, 295, 111)
	$gui_label_asuratitle_text = GUICtrlCreateLabel('Asura:', 341, 360, 60, 16)
	$gui_label_asuratitle_value = GUICtrlCreateLabel('0', 425, 360, 60, 16, $SS_RIGHT)
	$gui_label_deldrimortitle_text = GUICtrlCreateLabel('Deldrimor:', 341, 380, 60, 16)
	$gui_label_deldrimortitle_value = GUICtrlCreateLabel('0', 425, 380, 60, 16, $SS_RIGHT)
	$gui_label_norntitle_text = GUICtrlCreateLabel('Norn:', 341, 400, 60, 16)
	$gui_label_norntitle_value = GUICtrlCreateLabel('0', 425, 400, 60, 16, $SS_RIGHT)
	$gui_label_vanguardtitle_text = GUICtrlCreateLabel('Vanguard:', 341, 420, 60, 16)
	$gui_label_vanguardtitle_value = GUICtrlCreateLabel('0', 425, 420, 60, 16, $SS_RIGHT)

	$gui_label_kurzicktitle_text = GUICtrlCreateLabel('Kurzick:', 495, 360, 60, 16)
	$gui_label_kurzicktitle_value = GUICtrlCreateLabel('0', 558, 360, 60, 16, $SS_RIGHT)
	$gui_label_luxontitle_text = GUICtrlCreateLabel('Luxon:', 495, 380, 60, 16)
	$gui_label_luxontitle_value = GUICtrlCreateLabel('0', 558, 380, 60, 16, $SS_RIGHT)
	$gui_label_lightbringertitle_text = GUICtrlCreateLabel('Lightbringer:', 495, 400, 60, 16)
	$gui_label_lightbringertitle_value = GUICtrlCreateLabel('0', 558, 400, 60, 16, $SS_RIGHT)
	$gui_label_sunspeartitle_text = GUICtrlCreateLabel('Sunspear:', 495, 420, 60, 16)
	$gui_label_sunspeartitle_value = GUICtrlCreateLabel('0', 558, 420, 60, 16, $SS_RIGHT)
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	; === Options tab ===
	$gui_tab_runoptions = GUICtrlCreateTabItem('Options')
	_GUICtrlTab_SetBkColor($gui_botshub, $gui_tabs_parent, $COLOR_SILVER)

	$gui_group_runoptions = GUICtrlCreateGroup('Run options', 21, 39, 295, 155)
	$gui_checkbox_loopruns = GUICtrlCreateCheckbox('Loop Runs', 31, 60)
	$gui_checkbox_hardmode = GUICtrlCreateCheckbox('Hard Mode', 31, 85)
	$gui_checkbox_farmmaterialsmidrun = GUICtrlCreateCheckbox('Salvage during run', 31, 110)
	$gui_checkbox_useconsumables = GUICtrlCreateCheckbox('Use optional consumables', 31, 135)
	$gui_checkbox_usescrolls = GUICtrlCreateCheckbox('Use scrolls to enter elite zones', 31, 160)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$gui_group_itemoptions = GUICtrlCreateGroup('Loot management options', 21, 205, 295, 235)
	$gui_checkbox_sortitems = GUICtrlCreateCheckbox('Sort items', 31, 225)
	$gui_checkbox_collectdata = GUICtrlCreateCheckbox('Collect data into database', 31, 255)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$gui_group_factionoptions = GUICtrlCreateGroup('Faction options', 330, 39, 295, 155)
	$gui_radiobutton_donatepoints = GUICtrlCreateRadio('Donate Kurzick/Luxon points to alliance', 350, 70)
	$gui_radiobutton_buyfactionresources = GUICtrlCreateRadio('Buy Amber Chunks/Jadeite Shards', 350, 110)
	$gui_radiobutton_buyfactionscrolls = GUICtrlCreateRadio('Buy Urgoz''s Warren/The Deep Passage scrolls', 350, 150)
	GUICtrlSetState($gui_radiobutton_donatepoints, $GUI_CHECKED)
	GUICtrlCreateGroup('', -99, -99, 1, 1)

	$gui_group_otheroptions = GUICtrlCreateGroup('Other options', 330, 205, 295, 235)
	$gui_label_weaponslot = GUICtrlCreateLabel('Use weapon slot for farm:', 355, 228)
	$gui_combo_weaponslot = GUICtrlCreateCombo('0', 505, 225, 30, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($gui_combo_weaponslot, $AVAILABLE_WEAPON_SLOTS, '0')
	$gui_label_bagscount = GUICtrlCreateLabel('Use bags:', 355, 253)
	$gui_combo_bagscount = GUICtrlCreateCombo('5', 505, 250, 30, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($gui_combo_bagscount, $AVAILABLE_BAG_COUNTS, '5')
	$gui_label_traveldistrict = GUICtrlCreateLabel('Travel district:', 355, 278)
	$gui_combo_districtchoice = GUICtrlCreateCombo('Random EU', 440, 275, 95, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetData($gui_combo_districtchoice, $AVAILABLE_DISTRICTS, 'Random EU')

	$gui_renderbutton = GUICtrlCreateButton('Rendering enabled', 351, 325, 252, 25)
	GUICtrlSetBkColor($gui_renderbutton, $COLOR_YELLOW)

	GUICtrlSetTip($gui_checkbox_farmmaterialsmidrun, 'Salvage items during runs to save space. Bot will take some salvage kits in inventory for that.')
	GUICtrlSetTip($gui_checkbox_useconsumables, 'If bot can use consumables (consets, speed boosts, etc) to improve run efficiency, it will do it automatically.')
	GUICtrlSetTip($gui_checkbox_usescrolls, 'Automatically uses scrolls required to enter elite zones (UW, FoW, Urgoz, Deep)')
	GUICtrlSetTip($gui_checkbox_sortitems, 'Sorts items in inventory to optimize space before loot management.')
	GUICtrlSetTip($gui_checkbox_collectdata, 'Collects data into SQLite database. Requires SQLite to be installed and configured. Keep unticked if unsure.')
	Local $factionPointsUsageTooltip = 'Option on how to spend faction points earned in Kurzick/Luxon farms'
	GUICtrlSetTip($gui_radiobutton_donatepoints, $factionPointsUsageTooltip)
	GUICtrlSetTip($gui_radiobutton_buyfactionresources, $factionPointsUsageTooltip)
	GUICtrlSetTip($gui_radiobutton_buyfactionscrolls, $factionPointsUsageTooltip)
	Local $weaponSlotTooltip = 'Choose a weapon slot to use - 0 means it will use the current weapon slot'
	GUICtrlSetTip($gui_label_weaponslot, $weaponSlotTooltip)
	GUICtrlSetTip($gui_combo_weaponslot, $weaponSlotTooltip)
	GUICtrlSetTip($gui_renderbutton, 'Disabling rendering can reduce power consumption')

	GUICtrlSetOnEvent($gui_checkbox_loopruns, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_checkbox_hardmode, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_checkbox_farmmaterialsmidrun, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_checkbox_useconsumables, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_checkbox_usescrolls, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_checkbox_sortitems, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_checkbox_collectdata, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_radiobutton_donatepoints, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_radiobutton_buyfactionresources, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_radiobutton_buyfactionscrolls, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_combo_weaponslot, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_combo_bagscount, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_combo_districtchoice, 'GuiOptionsHandler')
	GUICtrlSetOnEvent($gui_renderbutton, 'GuiOptionsHandler')

	Local $dynamicExecutionTooltip = 'Dynamic execution. It allows to run a command with' & @CRLF _
							& 'any arguments on the fly by writing it in below field.' & @CRLF _
							& 'Syntax: fun(arg1, arg2, arg3, [...])'
	$gui_input_dynamicexecution = GUICtrlCreateInput('', 355, 405, 156, 20)
	$gui_button_dynamicexecution = GUICtrlCreateButton('Run', 530, 405, 75, 20)
	GUICtrlSetTip($gui_label_dynamicexecution, $dynamicExecutionTooltip)
	GUICtrlSetTip($gui_input_dynamicexecution, $dynamicExecutionTooltip)
	GUICtrlSetTip($gui_button_dynamicexecution, $dynamicExecutionTooltip)
	GUICtrlSetBkColor($gui_button_dynamicexecution, $COLOR_LIGHTBLUE)
	GUICtrlSetOnEvent($gui_button_dynamicexecution, 'GuiOptionsHandler')
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	; === Team tab ===
	$gui_tab_teamoptions = GUICtrlCreateTabItem('Team')
	_GUICtrlTab_SetBkColor($gui_botshub, $gui_tabs_parent, $COLOR_SILVER)
	$gui_group_teamoptions = GUICtrlCreateGroup('Team options', 21, 39, 604, 401)
	$gui_teamlabel = GUICtrlCreateLabel( _
		'Warning: enabling team setup overrides all bots team setup. Make sure your heroes have:' & @CRLF & _
		'- correct build' & @CRLF & _
		'- correct order' & @CRLF & _
		'- correct behaviour (passive/aggressive)' & @CRLF & _
		'If party size is 4 or 6, last heroes just won''t be added to party.', 40, 70)
	$gui_checkbox_automaticteamsetup = GUICtrlCreateCheckbox('Setup team automatically using team options section', 31, 140)
	$gui_teammemberlabel = GUICtrlCreateLabel('Team member', 147, 170, 100, 20)
	$gui_teammemberbuildlabel = GUICtrlCreateLabel('Team member build', 445, 170, 100, 20)
	$gui_checkbox_load_build_all = GUICtrlCreateCheckbox('Load all builds:', 254, 167)

	; Player build setup
	$gui_label_player = GUICtrlCreateLabel('Player', 125, 197, 114, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	$gui_checkbox_load_build_player = GUICtrlCreateCheckbox('Load Player Build:', 254, 197)
	$gui_input_build_player = GUICtrlCreateInput('', 375, 197, 236, 20)
	GUICtrlSetBkColor($gui_label_player, 0xFFFFFF)
	; Hero 1 setup
	$gui_label_hero_1 = GUICtrlCreateLabel('Selected Hero 1:', 31, 230, 100, 20)
	$gui_combo_hero_1 = GUICtrlCreateCombo('Master of Whispers', 125, 227, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_1 = GUICtrlCreateCheckbox('Load Hero 1 Build:', 254, 227)
	$gui_input_build_hero_1 = GUICtrlCreateInput('OAljUwGopSUBHVyBoBVVbh4B1YA', 375, 227, 236, 20)
	; Hero 2 setup
	$gui_label_hero_2 = GUICtrlCreateLabel('Selected Hero 2:', 31, 260, 100, 20)
	$gui_combo_hero_2 = GUICtrlCreateCombo('Livia', 125, 257, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_2 = GUICtrlCreateCheckbox('Load Hero 2 Build:', 254, 257)
	$gui_input_build_hero_2 = GUICtrlCreateInput('OAhjQoGYIP3hhWVVaO5EeDzxJ', 375, 257, 236, 20)
	; Hero 3 setup
	$gui_label_hero_3 = GUICtrlCreateLabel('Selected Hero 3:', 31, 290, 100, 20)
	$gui_combo_hero_3 = GUICtrlCreateCombo('Gwen', 125, 287, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_3 = GUICtrlCreateCheckbox('Load Hero 3 Build:', 254, 287)
	$gui_input_build_hero_3 = GUICtrlCreateInput('OQNEAqwD2ycC0AmupXOIDQEQj', 375, 287, 236, 20)
	; Hero 4 setup
	$gui_label_hero_4 = GUICtrlCreateLabel('Selected Hero 4:', 31, 320, 100, 20)
	$gui_combo_hero_4 = GUICtrlCreateCombo('Olias', 125, 317, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_4 = GUICtrlCreateCheckbox('Load Hero 4 Build:', 254, 317)
	$gui_input_build_hero_4 = GUICtrlCreateInput('OAhjUwGYoSUBHVoBbhVVWbTODTA', 375, 317, 236, 20)
	; Hero 5 setup
	$gui_label_hero_5 = GUICtrlCreateLabel('Selected Hero 5:', 31, 350, 100, 20)
	$gui_combo_hero_5 = GUICtrlCreateCombo('Norgu', 125, 347, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_5 = GUICtrlCreateCheckbox('Load Hero 5 Build:', 254, 347)
	$gui_input_build_hero_5 = GUICtrlCreateInput('OQNEAqwD2ycCwpmupXOIDcBQj', 375, 347, 236, 20)
	; Hero 6 setup
	$gui_label_hero_6 = GUICtrlCreateLabel('Selected Hero 6:', 31, 380, 100, 20)
	$gui_combo_hero_6 = GUICtrlCreateCombo('Xandra', 125, 377, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_6 = GUICtrlCreateCheckbox('Load Hero 6 Build:', 254, 377)
	$gui_input_build_hero_6 = GUICtrlCreateInput('OACiAyk8gNtePuwJ00ZOPLYA', 375, 377, 236, 20)
	; Hero 7 setup
	$gui_label_hero_7 = GUICtrlCreateLabel('Selected Hero 7:', 31, 410, 100, 20)
	$gui_combo_hero_7 = GUICtrlCreateCombo('Razah', 125, 407, 114, 20, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	$gui_checkbox_load_build_hero_7 = GUICtrlCreateCheckbox('Load Hero 7 Build:', 254, 407)
	$gui_input_build_hero_7 = GUICtrlCreateInput('OQNEAqwD2ycCaCmupXOIDMEQj', 375, 407, 236, 20)

	GUICtrlSetData($gui_combo_hero_1, $AVAILABLE_HEROES, 'Master of Whispers')
	GUICtrlSetData($gui_combo_hero_2, $AVAILABLE_HEROES, 'Livia')
	GUICtrlSetData($gui_combo_hero_3, $AVAILABLE_HEROES, 'Gwen')
	GUICtrlSetData($gui_combo_hero_4, $AVAILABLE_HEROES, 'Olias')
	GUICtrlSetData($gui_combo_hero_5, $AVAILABLE_HEROES, 'Norgu')
	GUICtrlSetData($gui_combo_hero_6, $AVAILABLE_HEROES, 'Xandra')
	GUICtrlSetData($gui_combo_hero_7, $AVAILABLE_HEROES, 'Razah')

	GUICtrlSetOnEvent($gui_checkbox_automaticteamsetup, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_1, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_2, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_3, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_4, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_5, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_6, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_combo_hero_7, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_all, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_player, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_1, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_2, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_3, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_4, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_5, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_6, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_checkbox_load_build_hero_7, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_player, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_1, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_2, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_3, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_4, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_5, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_6, 'GuiTeamTabButtonHandler')
	GUICtrlSetOnEvent($gui_input_build_hero_7, 'GuiTeamTabButtonHandler')
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	GUICtrlCreateTabItem('')

	; === Inventory tab ===
	$gui_tab_lootoptions = GUICtrlCreateTabItem('Inventory')
	$gui_treeview_lootoptions = GUICtrlCreateTreeView(80, 45, 545, 400, BitOR($TVS_HASLINES, $TVS_LINESATROOT, $TVS_HASBUTTONS, $TVS_CHECKBOXES, $TVS_FULLROWSELECT))
	Local $GuiJsonLootOptions = LoadLootOptions(@ScriptDir & '/conf/loot/Default Loot Configuration.json')
	BuildTreeViewFromJSON($gui_treeview_lootoptions, $GuiJsonLootOptions)
	; It's better to fill cache after tree is built rather than mix intents and do it all in one go
	FillInventoryCache($gui_treeview_lootoptions)

	$gui_expandlootoptionsbutton = GUICtrlCreateButton('Expand all', 21, 124, 55, 21)
	$gui_reducelootoptionsbutton = GUICtrlCreateButton('Reduce all', 21, 154, 55, 21)
	$gui_loadlootoptionsbutton = GUICtrlCreateButton('Load', 21, 184, 55, 21)
	$gui_savelootoptionsbutton = GUICtrlCreateButton('Save', 21, 214, 55, 21)
	$gui_label_lootoptionswarning = GUICtrlCreateLabel('Click apply to confirm your changes', 21, 244, 55, 84, $SS_CENTER)
	$gui_applylootoptionsbutton = GUICtrlCreateButton(@LF & 'Apply' & @LF & 'changes', 21, 304, 55, 63, $BS_MULTILINE)
	GUICtrlSetBkColor($gui_applylootoptionsbutton, $COLOR_YELLOW)

	GUICtrlSetOnEvent($gui_expandlootoptionsbutton, 'GuiLootTabButtonHandler')
	GUICtrlSetOnEvent($gui_reducelootoptionsbutton, 'GuiLootTabButtonHandler')
	GUICtrlSetOnEvent($gui_loadlootoptionsbutton, 'GuiLootTabButtonHandler')
	GUICtrlSetOnEvent($gui_savelootoptionsbutton, 'GuiLootTabButtonHandler')
	GUICtrlSetOnEvent($gui_applylootoptionsbutton, 'GuiLootTabButtonHandler')
	GUICtrlCreateTabItem('')

	; === Infos tab ===
	$gui_tab_farminfos = GUICtrlCreateTabItem('Farm infos')
	_GUICtrlTab_SetBkColor($gui_botshub, $gui_tabs_parent, $COLOR_SILVER)
	$gui_label_characterbuilds = GUICtrlCreateLabel('Recommended character builds:', 90, 40)
	$gui_edit_characterbuilds = GUICtrlCreateEdit('', 45, 60, 250, 105, BitOR($ES_MULTILINE, $ES_READONLY), $WS_EX_TOOLWINDOW)
	$gui_label_heroesbuilds = GUICtrlCreateLabel('Recommended Heroes builds:', 400, 40)
	$gui_edit_heroesbuilds = GUICtrlCreateEdit('', 350, 60, 250, 105, BitOR($ES_MULTILINE, $ES_READONLY), $WS_EX_TOOLWINDOW)
	$gui_label_farminformations = GUICtrlCreateLabel('Farm informations:', 30, 170, 575, 450)
	GUICtrlCreateTabItem('')

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
	If $notificationCode = $gui_combobox_dropdown_opened Then
		Switch $controlID
			Case $gui_combo_characterchoice
				ScanAndUpdateGameClients()
				RefreshCharactersComboBox()
		EndSwitch
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc


;~ Handles WM_NOTIFY elements, like treeview clicks
Func WM_NOTIFY_Handler($windowHandle, $messageCode, $unusedParam, $paramNotifyStruct)
	Local $notificationHeader = DllStructCreate('hwnd sourceHandle;int controlID;int notificationCode', $paramNotifyStruct)
	Local $sourceHandle = DllStructGetData($notificationHeader, 'sourceHandle')
	Local $notificationCode = DllStructGetData($notificationHeader, 'notificationCode')

	If $sourceHandle = GUICtrlGetHandle($gui_treeview_lootoptions) Then
		Switch $notificationCode
			Case $NM_CLICK
				Local $mousePos = _WinAPI_GetMousePos(True, $sourceHandle)
				Local $hitTestResult = _GUICtrlTreeView_HitTestEx($sourceHandle, DllStructGetData($mousePos, 1), DllStructGetData($mousePos, 2))
				Local $clickedItem = DllStructGetData($hitTestResult, 'Item')
				Local $hitFlags = DllStructGetData($hitTestResult, 'Flags')

				If $clickedItem <> 0 And BitAND($hitFlags, $TVHT_ONITEMSTATEICON) Then
					ToggleCheckboxCascade($sourceHandle, $clickedItem, True)
					ToggleCheckboxCascadeUpwards($sourceHandle, $clickedItem, True)
				EndIf

			Case $TVN_KEYDOWN
				Local $keyInfo = DllStructCreate('hwnd;int;int;short key;uint', $paramNotifyStruct)
				Local $selectedItem = _GUICtrlTreeView_GetSelection($sourceHandle)
				; Spacebar pressed
				If DllStructGetData($keyInfo, 'key') = 0x20 And $selectedItem Then
					ToggleCheckboxCascade($sourceHandle, $selectedItem, True)
					ToggleCheckboxCascadeUpwards($sourceHandle, $selectedItem, True)
				EndIf
		EndSwitch
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc


;~ Toggles checkbox state on a TreeView item and cascades it to children
Func ToggleCheckboxCascade($treeViewHandle, $itemHandle, $toggleFromRoot = False)
	Local $isChecked = _GUICtrlTreeView_GetChecked($treeViewHandle, $itemHandle)
	; Clicked item check status is only changed after WM_NOTIFY is handled, so it needs to be inverted
	If $toggleFromRoot Then $isChecked = Not $isChecked

	If _GUICtrlTreeView_GetChildren($treeViewHandle, $itemHandle) Then
		Local $childHandle = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $itemHandle)
		While $childHandle <> 0
			_GUICtrlTreeView_SetChecked($treeViewHandle, $childHandle, $isChecked)
			ToggleCheckboxCascade($treeViewHandle, $childHandle)
			$childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
		WEnd
	EndIf
EndFunc


;~ Toggles checkbox state on a TreeView item and cascades it to its parents
Func ToggleCheckboxCascadeUpwards($treeViewHandle, $itemHandle, $toggleFromRoot = False)
	Local $parentHandle = _GUICtrlTreeView_GetParentHandle($treeViewHandle, $itemHandle)
	If $parentHandle == 0 Or $parentHandle == $itemHandle Then Return

	Local $allChildrenChecked = True
	Local $childHandle = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $parentHandle)
	While $childHandle <> 0
		Local $childChecked = _GUICtrlTreeView_GetChecked($treeViewHandle, $childHandle)
		; Clicked item check status is only changed after WM_NOTIFY is handled, so it needs to be inverted
		If $toggleFromRoot And $childHandle == $itemHandle Then $childChecked = Not $childChecked
		If Not $childChecked Then
			$allChildrenChecked = False
			ExitLoop
		EndIf
		$childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
	WEnd
	_GUICtrlTreeView_SetChecked($treeViewHandle, $parentHandle, $allChildrenChecked)
	ToggleCheckboxCascadeUpwards($treeViewHandle, $parentHandle)
EndFunc


;~ Function handling tab changes
Func GuiTabHandler()
	Switch @GUI_CtrlId
		Case $gui_tabs_parent
			Switch GUICtrlRead($gui_tabs_parent)
				Case 0
					ControlEnable($gui_botshub, '', $gui_console)
					ControlShow($gui_botshub, '', $gui_console)
				Case Else
					ControlDisable($gui_botshub, '', $gui_console)
					ControlHide($gui_botshub, '', $gui_console)
			EndSwitch
		Case Else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc


;~ Handle main GUI buttons usage
Func GuiMainButtonHandler()
	Switch @GUI_CtrlId
		Case $gui_combo_farmchoice
			UpdateFarmDescription(GUICtrlRead($gui_combo_farmchoice))
		Case $gui_combo_configchoice
			LoadConfiguration(GUICtrlRead($gui_combo_configchoice))
		Case $gui_icon_saveconfig
			GUICtrlSetState($gui_icon_saveconfig, $GUI_DISABLE)
			Local $filePath = FileSaveDialog('', @ScriptDir & '\conf\farm', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to write JSON configuration.')
			Else
				SaveConfiguration($filePath)
			EndIf
			GUICtrlSetState($gui_icon_saveconfig, $GUI_ENABLE)
		Case $gui_event_close
			; restore rendering in case it was disabled
			EnableRendering()
			Exit
		Case Else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc


;~ Function handling start button
Func GuiStartButtonHandler()
	Switch $runtime_status
		Case 'UNINITIALIZED'
			If (Authentification() <> $SUCCESS) Then Return
			$runtime_status = 'INITIALIZED'
			GUICtrlSetData($gui_startbutton, 'Pause')
			GUICtrlSetBkColor($gui_startbutton, $COLOR_LIGHTCORAL)
			$runtime_status = 'RUNNING'
		Case 'INITIALIZED'
			$runtime_status = 'RUNNING'
		Case 'RUNNING'
			GUICtrlSetData($gui_startbutton, 'Will pause after this run')
			GUICtrlSetState($gui_startbutton, $GUI_DISABLE)
			GUICtrlSetBkColor($gui_startbutton, $COLOR_LIGHTYELLOW)
			$runtime_status = 'WILL_PAUSE'
		Case 'WILL_PAUSE'
			MsgBox(0, 'Error', 'You should not be able to press Pause when bot is already pausing.')
		Case 'PAUSED'
			GUICtrlSetData($gui_startbutton, 'Pause')
			GUICtrlSetBkColor($gui_startbutton, $COLOR_LIGHTCORAL)
			$runtime_status = 'RUNNING'
		Case Else
			MsgBox(0, 'Error', 'Unknown status <' & $runtime_status & '>')
	EndSwitch
EndFunc


;~ Handle main GUI buttons usage
Func GuiOptionsHandler()
	Switch @GUI_CtrlId
		Case $gui_checkbox_loopruns
			$run_options_cache['run.loop_mode'] = GUICtrlRead($gui_checkbox_loopruns) == $GUI_CHECKED
		Case $gui_checkbox_hardmode
			$run_options_cache['run.hard_mode'] = GUICtrlRead($gui_checkbox_hardmode) == $GUI_CHECKED
		Case $gui_checkbox_farmmaterialsmidrun
			$run_options_cache['run.farm_materials_mid_run'] = GUICtrlRead($gui_checkbox_farmmaterialsmidrun) == $GUI_CHECKED
		Case $gui_checkbox_useconsumables
			$run_options_cache['run.consume_consumables'] = GUICtrlRead($gui_checkbox_useconsumables) == $GUI_CHECKED
		Case $gui_checkbox_usescrolls
			$run_options_cache['run.use_scrolls'] = GUICtrlRead($gui_checkbox_usescrolls) == $GUI_CHECKED
		Case $gui_checkbox_sortitems
			$run_options_cache['run.sort_items'] = GUICtrlRead($gui_checkbox_sortitems) == $GUI_CHECKED
		Case $gui_checkbox_collectdata
			$run_options_cache['run.collect_data'] = GUICtrlRead($gui_checkbox_collectdata) == $GUI_CHECKED
		Case $gui_radiobutton_donatepoints
			$run_options_cache['run.donate_faction_points'] = True
			$run_options_cache['run.buy_faction_resources'] = False
			$run_options_cache['run.buy_faction_scrolls'] = False
		Case $gui_radiobutton_buyfactionresources
			$run_options_cache['run.donate_faction_points'] = False
			$run_options_cache['run.buy_faction_resources'] = True
			$run_options_cache['run.buy_faction_scrolls'] = False
		Case $gui_radiobutton_buyfactionscrolls
			$run_options_cache['run.donate_faction_points'] = False
			$run_options_cache['run.buy_faction_resources'] = False
			$run_options_cache['run.buy_faction_scrolls'] = True
		Case $gui_combo_weaponslot
			Local $weaponSlot = Number(GUICtrlRead($gui_combo_weaponslot))
			$weaponSlot = _Max($weaponSlot, 0)
			$weaponSlot = _Min($weaponSlot, 4)
			$run_options_cache['run.weapon_slot'] = $weaponSlot
		Case $gui_combo_bagscount
			$bags_count = Number(GUICtrlRead($gui_combo_bagscount))
			$bags_count = _Max($bags_count, 1)
			$bags_count = _Min($bags_count, 5)
			$run_options_cache['run.bags_count'] = $bags_count
		Case $gui_combo_districtchoice
			$district_name = GUICtrlRead($gui_combo_districtchoice)
			$run_options_cache['run.district'] = $district_name
		Case $gui_renderbutton
			$rendering_enabled = Not $rendering_enabled
			$run_options_cache['run.disable_rendering'] = Not $rendering_enabled
			RefreshRenderingButton()
			ToggleRendering()
		Case $gui_button_dynamicexecution
			DynamicExecution(GUICtrlRead($gui_input_dynamicexecution))
		Case Else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc


;~ Handle buttons in team tab
Func GuiTeamTabButtonHandler()
	Local $checked
	Switch @GUI_CtrlId
		Case $gui_checkbox_automaticteamsetup
			Local $autoTeamSetup = GUICtrlRead($gui_checkbox_automaticteamsetup) == $GUI_CHECKED
			$run_options_cache['team.automatic_team_setup'] = $autoTeamSetup
			UpdateTeamComboboxes($autoTeamSetup)
		; Saving the chosen heroes, in cache
		Case $gui_combo_hero_1
			$run_options_cache['team.hero_1'] = GUICtrlRead($gui_combo_hero_1)
		Case $gui_combo_hero_2
			$run_options_cache['team.hero_2'] = GUICtrlRead($gui_combo_hero_2)
		Case $gui_combo_hero_3
			$run_options_cache['team.hero_3'] = GUICtrlRead($gui_combo_hero_3)
		Case $gui_combo_hero_4
			$run_options_cache['team.hero_4'] = GUICtrlRead($gui_combo_hero_4)
		Case $gui_combo_hero_5
			$run_options_cache['team.hero_5'] = GUICtrlRead($gui_combo_hero_5)
		Case $gui_combo_hero_6
			$run_options_cache['team.hero_6'] = GUICtrlRead($gui_combo_hero_6)
		Case $gui_combo_hero_7
			$run_options_cache['team.hero_7'] = GUICtrlRead($gui_combo_hero_7)
		; Saving whether the player and hero builds are loaded, in cache
		Case $gui_checkbox_load_build_all
			Local $checked = GUICtrlRead($gui_checkbox_load_build_all) == $GUI_CHECKED
			$run_options_cache['team.load_all_builds'] = $checked
			; Setting all the run options to checked
			$run_options_cache['team.load_player_build'] = $checked
			$run_options_cache['team.load_hero_1_build'] = $checked
			$run_options_cache['team.load_hero_2_build'] = $checked
			$run_options_cache['team.load_hero_3_build'] = $checked
			$run_options_cache['team.load_hero_4_build'] = $checked
			$run_options_cache['team.load_hero_5_build'] = $checked
			$run_options_cache['team.load_hero_6_build'] = $checked
			$run_options_cache['team.load_hero_7_build'] = $checked
			; Setting all checkboxes checked/unchecked
			GUICtrlSetState($gui_checkbox_load_build_player, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_1, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_2, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_3, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_4, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_5, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_6, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			GUICtrlSetState($gui_checkbox_load_build_hero_7, $checked ? $GUI_CHECKED : $GUI_UNCHECKED)
			; Setting all inputs enabled/disabled
			GUICtrlSetState($gui_input_build_player, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_1, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_2, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_3, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_4, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_5, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_6, $checked ? $GUI_ENABLE : $GUI_DISABLE)
			GUICtrlSetState($gui_input_build_hero_7, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_player
			$checked = GUICtrlRead($gui_checkbox_load_build_player) == $GUI_CHECKED
			$run_options_cache['team.load_player_build'] = $checked
			GUICtrlSetState($gui_input_build_player, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_1
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_1) == $GUI_CHECKED
			$run_options_cache['team.load_hero_1_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_1, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_2
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_2) == $GUI_CHECKED
			$run_options_cache['team.load_hero_2_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_2, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_3
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_3) == $GUI_CHECKED
			$run_options_cache['team.load_hero_3_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_3, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_4
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_4) == $GUI_CHECKED
			$run_options_cache['team.load_hero_4_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_4, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_5
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_5) == $GUI_CHECKED
			$run_options_cache['team.load_hero_5_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_5, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_6
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_6) == $GUI_CHECKED
			$run_options_cache['team.load_hero_6_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_6, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		Case $gui_checkbox_load_build_hero_7
			$checked = GUICtrlRead($gui_checkbox_load_build_hero_7) == $GUI_CHECKED
			$run_options_cache['team.load_hero_7_build'] = $checked
			GUICtrlSetState($gui_input_build_hero_7, $checked ? $GUI_ENABLE : $GUI_DISABLE)
		; Saving the player and hero builds in cache
		Case $gui_input_build_player
			$run_options_cache['team.player_build'] = GUICtrlRead($gui_input_build_player)
		Case $gui_input_build_hero_1
			$run_options_cache['team.hero_1_build'] = GUICtrlRead($gui_input_build_hero_1)
		Case $gui_input_build_hero_2
			$run_options_cache['team.hero_2_build'] = GUICtrlRead($gui_input_build_hero_2)
		Case $gui_input_build_hero_3
			$run_options_cache['team.hero_3_build'] = GUICtrlRead($gui_input_build_hero_3)
		Case $gui_input_build_hero_4
			$run_options_cache['team.hero_4_build'] = GUICtrlRead($gui_input_build_hero_4)
		Case $gui_input_build_hero_5
			$run_options_cache['team.hero_5_build'] = GUICtrlRead($gui_input_build_hero_5)
		Case $gui_input_build_hero_6
			$run_options_cache['team.hero_6_build'] = GUICtrlRead($gui_input_build_hero_6)
		Case $gui_input_build_hero_7
			$run_options_cache['team.hero_7_build'] = GUICtrlRead($gui_input_build_hero_7)
		Case Else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc


;~ Handle loot tab buttons
Func GuiLootTabButtonHandler()
	Switch @GUI_CtrlId
		Case $gui_expandlootoptionsbutton
			_GUICtrlTreeView_Expand(GUICtrlGetHandle($gui_treeview_lootoptions), 0, True)
		Case $gui_reducelootoptionsbutton
			_GUICtrlTreeView_Expand(GUICtrlGetHandle($gui_treeview_lootoptions), 0, False)
		Case $gui_loadlootoptionsbutton
			Local $filePath = FileOpenDialog('Please select a valid loot options file', @ScriptDir & '\conf\loot', '(*.json)')
			If @error <> 0 Then
				Warn('Failed to read JSON loot options configuration.')
			Else
				Local $GuiJsonLootOptions = LoadLootOptions($filePath)
				_GUICtrlTreeView_DeleteAll($gui_treeview_lootoptions)
				BuildTreeViewFromJSON($gui_treeview_lootoptions, $GuiJsonLootOptions)
				FillInventoryCache($gui_treeview_lootoptions)
				Info('Loaded loot options configuration ' & $filePath)
			EndIf
		Case $gui_savelootoptionsbutton
			Local $jsonObject = BuildJSONFromTreeView($gui_treeview_lootoptions)
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
		Case $gui_applylootoptionsbutton
			FillInventoryCache($gui_treeview_lootoptions)
			Info('Refreshed inventory management options')
		Case Else
			MsgBox(0, 'Error', 'This button is not coded yet.')
	EndSwitch
EndFunc


;~ Refresh rendering button according to current rendering status - should be split from real rendering logic
Func RefreshRenderingButton()
	If $rendering_enabled Then
		GUICtrlSetBkColor($gui_renderbutton, $COLOR_YELLOW)
		GUICtrlSetData($gui_renderbutton, 'Rendering enabled')
	Else
		GUICtrlSetBkColor($gui_renderbutton, $COLOR_LIGHTGREEN)
		GUICtrlSetData($gui_renderbutton, 'Rendering disabled')
	EndIf
EndFunc


;~ Fill characters combobox
Func RefreshCharactersComboBox()
	Local $comboList = ''
	For $i = 1 To $game_clients[0][0]
		If $game_clients[$i][0] <> -1 Then $comboList &= '|' & $game_clients[$i][3]
	Next
	GUICtrlSetData($gui_combo_characterchoice, $comboList, $game_clients[0][0] > 0 ? $game_clients[1][3] : '')
	If ($game_clients[0][0] > 0) Then SelectClient(1)
EndFunc


;~ Update team comboboxes
Func UpdateTeamComboboxes($autoTeamSetup)
	If $autoTeamSetup Then
		EnableTeamComboboxes()
	Else
		DisableTeamComboboxes()
	EndIf
EndFunc


;~ Enable team comboboxes
Func EnableTeamComboboxes()
	GUICtrlSetState($gui_checkbox_load_build_all, $GUI_ENABLE)
	GUICtrlSetState($gui_label_player, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_1, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_2, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_3, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_4, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_5, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_6, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_hero_7, $GUI_ENABLE)

	GUICtrlSetState($gui_checkbox_load_build_all, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_player, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_1, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_2, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_3, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_4, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_5, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_6, $GUI_ENABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_7, $GUI_ENABLE)

	GUICtrlSetState($gui_input_build_player, GUICtrlRead($gui_checkbox_load_build_player) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_1, GUICtrlRead($gui_checkbox_load_build_hero_1) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_2, GUICtrlRead($gui_checkbox_load_build_hero_2) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_3, GUICtrlRead($gui_checkbox_load_build_hero_3) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_4, GUICtrlRead($gui_checkbox_load_build_hero_4) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_5, GUICtrlRead($gui_checkbox_load_build_hero_5) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_6, GUICtrlRead($gui_checkbox_load_build_hero_6) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_7, GUICtrlRead($gui_checkbox_load_build_hero_7) == $GUI_CHECKED ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc


;~ Disable team comboboxes
Func DisableTeamComboboxes()
	GUICtrlSetState($gui_label_player, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_1, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_2, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_3, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_4, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_5, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_6, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_hero_7, $GUI_DISABLE)

	GUICtrlSetState($gui_checkbox_load_build_all, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_player, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_1, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_2, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_3, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_4, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_5, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_6, $GUI_DISABLE)
	GUICtrlSetState($gui_checkbox_load_build_hero_7, $GUI_DISABLE)

	GUICtrlSetState($gui_checkbox_load_build_all, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_player, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_1, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_2, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_3, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_4, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_5, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_6, $GUI_DISABLE)
	GUICtrlSetState($gui_input_build_hero_7, $GUI_DISABLE)
EndFunc


;~ Enable most comboboxes
Func EnableGUIComboboxes()
	; Enabling changing account is non trivial
	;GUICtrlSetState($gui_combo_characterchoice, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_farmchoice, $GUI_ENABLE)
	GUICtrlSetState($gui_combo_configchoice, $GUI_ENABLE)
	EnableTeamComboboxes()
EndFunc


;~ Disable most comboboxes
Func DisableGUIComboboxes()
	GUICtrlSetState($gui_combo_characterchoice, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_farmchoice, $GUI_DISABLE)
	GUICtrlSetState($gui_combo_configchoice, $GUI_DISABLE)
	DisableTeamComboboxes()
EndFunc


;~ Update the progress bar
Func UpdateProgressBar($totalDuration = 0)
	Local Static $duration
	If IsDeclared('totalDuration') And $totalDuration <> 0 Then
		$duration = $totalDuration
	EndIf
	Local $progress = Floor((TimerDiff($run_timer) / $duration) * 100)
	; capping run progress at 98%
	If $progress > 98 Then $progress = 98
	GUICtrlSetData($gui_farmprogress, $progress)
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
;~ Don't overuse, warnings are stored in memory
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
	If $LOGLEVEL >= $log_level Then
		Local $logColor
		Switch $LOGLEVEL
			Case $LVL_DEBUG
				$logColor = $CLR_LIGHTGREEN	; CLR is reversed BGR color
			Case $LVL_INFO
				$logColor = $CLR_WHITE		; CLR is reversed BGR color
			Case $LVL_NOTICE
				$logColor = $CLR_TEAL		; CLR is reversed BGR color
			Case $LVL_WARNING
				$logColor = $CLR_YELLOW		; CLR is reversed BGR color
			Case $LVL_ERROR
				$logColor = $CLR_RED		; CLR is reversed BGR color
		EndSwitch
		_GUICtrlRichEdit_SetCharColor($gui_console, $logColor)
		_GUICtrlRichEdit_AppendText($gui_console, @HOUR & ':' & @MIN & ':' & @SEC & ' - ' & $TEXT & @CRLF)
	EndIf
EndFunc
#EndRegion Console
#EndRegion GUI


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
	GUICtrlSetData($gui_combo_configchoice, $comboList, $configuration)
EndFunc


;~ Load default farm configuration if it exists
Func LoadDefaultConfiguration()
	If FileExists(@ScriptDir & '/conf/farm/Default Farm Configuration.json') Then
		Local $configFile = FileOpen(@ScriptDir & '/conf/farm/Default Farm Configuration.json' , $FO_READ + $FO_UTF8)
		Local $jsonString = FileRead($configFile)
		ReadConfigFromJson($jsonString)
		ApplyConfigToGUI()
		FileClose($configFile)
		Info('Loaded default farm configuration')
	EndIf
EndFunc


;~ Change to a different configuration
Func LoadConfiguration($configuration)
	Local $configFile = FileOpen(@ScriptDir & '/conf/farm/' & $configuration & '.json' , $FO_READ + $FO_UTF8)
	Local $jsonString = FileRead($configFile)
	ReadConfigFromJson($jsonString)
	ApplyConfigToGUI()
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
	; TODO/FIXME: simplify by iterating over map keys
	_JSON_addChangeDelete($jsonObject, 'main.character', GUICtrlRead($gui_combo_characterchoice))
	_JSON_addChangeDelete($jsonObject, 'main.farm', GUICtrlRead($gui_combo_farmchoice))
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


;~ Read given config from JSON
Func ReadConfigFromJson($jsonString)
	Local $jsonObject = _JSON_Parse($jsonString)

	GUICtrlSetData($gui_combo_characterchoice, _JSON_Get($jsonObject, 'main.character'))
	GUICtrlSetData($gui_combo_farmchoice, $AVAILABLE_FARMS, _JSON_Get($jsonObject, 'main.farm'))
	UpdateFarmDescription(_JSON_Get($jsonObject, 'main.farm'))

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


;~ Read given config from JSON
Func ApplyConfigToGUI()
	;~ GUICtrlSetData($gui_combo_characterchoice, _JSON_Get($jsonObject, 'main.character'))
	;~ GUICtrlSetData($gui_combo_farmchoice, $AVAILABLE_FARMS, _JSON_Get($jsonObject, 'main.farm'))
	;~ UpdateFarmDescription(_JSON_Get($jsonObject, 'main.farm'))


	GUICtrlSetData($gui_combo_weaponslot, $run_options_cache['run.weapon_slot'])
	GUICtrlSetData($gui_combo_bagscount, $bags_count)
	GUICtrlSetData($gui_combo_districtchoice, $district_name)
	RefreshRenderingButton()
	GUICtrlSetState($gui_checkbox_loopruns, $run_options_cache['run.loop_mode'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_hardmode, $run_options_cache['run.hard_mode'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_farmmaterialsmidrun, $run_options_cache['run.farm_materials_mid_run'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_useconsumables, $run_options_cache['run.consume_consumables'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_usescrolls, $run_options_cache['run.use_scrolls'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_sortitems, $run_options_cache['run.sort_items'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_collectdata, $run_options_cache['run.collect_data'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_radiobutton_donatepoints, $run_options_cache['run.donate_faction_points'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_radiobutton_buyfactionresources, $run_options_cache['run.buy_faction_resources'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_radiobutton_buyfactionscrolls, $run_options_cache['run.buy_faction_scrolls'] ? $GUI_CHECKED : $GUI_UNCHECKED)

	GUICtrlSetState($gui_checkbox_automaticteamsetup, $run_options_cache['team.automatic_team_setup'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($gui_combo_hero_1, $run_options_cache['team.hero_1'])
	GUICtrlSetData($gui_combo_hero_2, $run_options_cache['team.hero_2'])
	GUICtrlSetData($gui_combo_hero_3, $run_options_cache['team.hero_3'])
	GUICtrlSetData($gui_combo_hero_4, $run_options_cache['team.hero_4'])
	GUICtrlSetData($gui_combo_hero_5, $run_options_cache['team.hero_5'])
	GUICtrlSetData($gui_combo_hero_6, $run_options_cache['team.hero_6'])
	GUICtrlSetData($gui_combo_hero_7, $run_options_cache['team.hero_7'])
	GUICtrlSetState($gui_checkbox_load_build_all, $run_options_cache['team.load_all_builds'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_player, $run_options_cache['team.load_player_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_1, $run_options_cache['team.load_hero_1_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_2, $run_options_cache['team.load_hero_2_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_3, $run_options_cache['team.load_hero_3_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_4, $run_options_cache['team.load_hero_4_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_5, $run_options_cache['team.load_hero_5_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_6, $run_options_cache['team.load_hero_6_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($gui_checkbox_load_build_hero_7, $run_options_cache['team.load_hero_7_build'] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($gui_input_build_player, $run_options_cache['team.player_build'])
	GUICtrlSetData($gui_input_build_hero_1, $run_options_cache['team.hero_1_build'])
	GUICtrlSetData($gui_input_build_hero_2, $run_options_cache['team.hero_2_build'])
	GUICtrlSetData($gui_input_build_hero_3, $run_options_cache['team.hero_3_build'])
	GUICtrlSetData($gui_input_build_hero_4, $run_options_cache['team.hero_4_build'])
	GUICtrlSetData($gui_input_build_hero_5, $run_options_cache['team.hero_5_build'])
	GUICtrlSetData($gui_input_build_hero_6, $run_options_cache['team.hero_6_build'])
	GUICtrlSetData($gui_input_build_hero_7, $run_options_cache['team.hero_7_build'])
	UpdateTeamComboboxes($run_options_cache['team.automatic_team_setup'])
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


#Region Loot Tree View Management
;~ Creating a treeview from a JSON node
Func BuildTreeViewFromJSON($parentItem, $jsonNode)
	If IsMap($jsonNode) Then
		Local $isChecked = True
		For $key In MapKeys($jsonNode)
			Local $keyHandle = GUICtrlCreateTreeViewItem($key, $parentItem)
			If Not BuildTreeViewFromJSON($keyHandle, $jsonNode[$key]) Then $isChecked = False
		Next
		_GUICtrlTreeView_SetChecked($gui_treeview_lootoptions, $parentItem, $isChecked)
		Return $isChecked
	EndIf
	; Leaf node: this node is true or false
	_GUICtrlTreeView_SetChecked($gui_treeview_lootoptions, $parentItem, $jsonNode)
	Return $jsonNode == True
EndFunc


;~ Fill the inventory cache with the treeview data
Func FillInventoryCache($treeViewHandle)
	IterateOverTreeView(Null, $treeViewHandle, Null, '', AddToInventoryCache)
	BuildInventoryDerivedFlags()
	RefreshValuableListsFromInterface()
EndFunc


;~ Utility function to add treeview elements to the inventory cache
Func AddToInventoryCache(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath)
	$inventory_management_cache[$currentPath] = _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem)
EndFunc


;~ Fill the inventory cache with additional derived data
Func BuildInventoryDerivedFlags()
	; -------- Pickup --------
	Local $pickupSomething = IsAnyLootOptionInBranchChecked('Pick up items')
	$inventory_management_cache['@pickup.something'] = $pickupSomething
	$inventory_management_cache['@pickup.nothing'] = Not $pickupSomething
	Local $pickupSomeWeapons = IsAnyLootOptionInBranchChecked('Pick up items.Weapons and offhands')
	$inventory_management_cache['@pickup.weapons.something'] = $pickupSomeWeapons
	$inventory_management_cache['@pickup.weapons.nothing'] = Not $pickupSomeWeapons

	; -------- Identify --------
	Local $identifySomething = IsAnyLootOptionInBranchChecked('Identify items')
	$inventory_management_cache['@identify.something'] = $identifySomething
	$inventory_management_cache['@identify.nothing'] = Not $identifySomething

	; -------- Salvage --------
	Local $salvageSomething = IsAnyLootOptionInBranchChecked('Salvage items')
	$inventory_management_cache['@salvage.something'] = $salvageSomething
	$inventory_management_cache['@salvage.nothing'] = Not $salvageSomething
	Local $salvageSomeWeapons = IsAnyLootOptionInBranchChecked('Salvage items.Weapons and offhands')
	$inventory_management_cache['@salvage.weapons.something'] = $salvageSomeWeapons
	$inventory_management_cache['@salvage.weapons.nothing'] = Not $salvageSomeWeapons
	Local $salvageSomeSalvageables = IsAnyLootOptionInBranchChecked('Salvage items.Armor salvageables')
	$inventory_management_cache['@salvage.salvageables.something'] = $salvageSomeSalvageables
	$inventory_management_cache['@salvage.salvageables.nothing'] = Not $salvageSomeSalvageables
	Local $salvageSomeTrophies = IsAnyLootOptionInBranchChecked('Salvage items.Trophies')
	$inventory_management_cache['@salvage.trophies.something'] = $salvageSomeTrophies
	$inventory_management_cache['@salvage.trophies.nothing'] = Not $salvageSomeTrophies
	Local $salvageSomeMaterials = IsAnyLootOptionInBranchChecked('Salvage items.Rare Materials')
	$inventory_management_cache['@salvage.materials.something'] = $salvageSomeMaterials
	$inventory_management_cache['@salvage.materials.nothing'] = Not $salvageSomeMaterials

	; -------- Sell --------
	Local $sellSomething = IsAnyLootOptionInBranchChecked('Sell items')
	$inventory_management_cache['@sell.something'] = $sellSomething
	$inventory_management_cache['@sell.nothing'] = Not $sellSomething
	Local $sellSomeWeapons = IsAnyLootOptionInBranchChecked('Sell items.Weapons and offhands')
	$inventory_management_cache['@sell.weapons.something'] = $sellSomeWeapons
	$inventory_management_cache['@sell.weapons.nothing'] = Not $sellSomeWeapons

	Local $sellSomeBasicMaterials = IsAnyLootOptionInBranchChecked('Sell items.Basic Materials')
	$inventory_management_cache['@sell.materials.basic.something'] = $sellSomeBasicMaterials
	$inventory_management_cache['@sell.materials.basic.nothing'] = Not $sellSomeBasicMaterials
	Local $sellSomeRareMaterials = IsAnyLootOptionInBranchChecked('Sell items.Rare Materials')
	$inventory_management_cache['@sell.materials.rare.something'] = $sellSomeRareMaterials
	$inventory_management_cache['@sell.materials.rare.nothing'] = Not $sellSomeRareMaterials
	Local $sellSomeMaterials = $sellSomeBasicMaterials Or $sellSomeRareMaterials
	$inventory_management_cache['@sell.materials.something'] = $sellSomeMaterials
	$inventory_management_cache['@sell.materials.nothing'] = Not $sellSomeMaterials

	; -------- Buy --------
	Local $buySomething = IsAnyLootOptionInBranchChecked('Buy items')
	$inventory_management_cache['@buy.something'] = $buySomething
	$inventory_management_cache['@buy.nothing'] = Not $buySomething

	Local $buySomeBasicMaterials = IsAnyLootOptionInBranchChecked('Buy items.Basic Materials')
	$inventory_management_cache['@buy.materials.basic.something'] = $buySomeBasicMaterials
	$inventory_management_cache['@buy.materials.basic.nothing'] = Not $buySomeBasicMaterials
	Local $buySomeRareMaterials = IsAnyLootOptionInBranchChecked('Buy items.Rare Materials')
	$inventory_management_cache['@buy.materials.rare.something'] = $buySomeRareMaterials
	$inventory_management_cache['@buy.materials.rare.nothing'] = Not $buySomeRareMaterials
	Local $buySomeMaterials = $buySomeBasicMaterials Or $buySomeRareMaterials
	$inventory_management_cache['@buy.materials.something'] = $buySomeMaterials
	$inventory_management_cache['@buy.materials.nothing'] = Not $buySomeMaterials

	; -------- Store --------
	Local $storeSomething = IsAnyLootOptionInBranchChecked('Store items')
	$inventory_management_cache['@store.something'] = $storeSomething
	$inventory_management_cache['@store.nothing'] = Not $storeSomething
	Local $storeSomeWeapons = IsAnyLootOptionInBranchChecked('Store items.Weapons and offhands')
	$inventory_management_cache['@store.weapons.something'] = $storeSomeWeapons
	$inventory_management_cache['@store.weapons.something'] = Not $storeSomeWeapons
EndFunc


;~ Getting ticked loot options from checkboxes as array
Func GetLootOptionsTickedCheckboxes($startingPoint, $treeViewHandle = $gui_treeview_lootoptions, $pathDelimiter = '.', $recursive = True)
	Local $treeViewItem = FindNodeInTreeView($treeViewHandle, Null, $startingPoint, $pathDelimiter)
	Return $treeViewItem == Null ? Null : BuildArrayFromTreeView($treeViewHandle, $treeViewItem, '', $recursive)
EndFunc


;~ Creating a JSON node from a treeview
Func BuildJSONFromTreeView($treeViewHandle, $treeViewItem = Null, $currentPath = '')
	Local $jsonObject
	IterateOverTreeView($jsonObject, $treeViewHandle, $treeViewItem, $currentPath, AddLeavesToJSONObject)
	Return $jsonObject
EndFunc


;~ Utility function to add treeview elements to a JSON object
Func AddLeavesToJSONObject(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath)
	; We are on a leaf
	If _GUICtrlTreeView_GetChildCount($treeViewHandle, $treeViewItem) <= 0 Then
		_JSON_addChangeDelete($context, $currentPath, _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem))
	EndIf
EndFunc


;~ Creating an array from a treeview
Func BuildArrayFromTreeView($treeViewHandle, $treeViewItem = Null, $currentPath = '', $recursive = True)
	Local $array[0]
	IterateOverTreeView($array, $treeViewHandle, $treeViewItem, $currentPath, AddLeafToArray, $recursive ? -1 : 2)
	Return $array
EndFunc


;~ Utility function to add treeview elements to an array
Func AddLeafToArray(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath)
	; We are on a leaf
	If _GUICtrlTreeView_GetChildCount($treeViewHandle, $treeViewItem) <= 0 Then
		If _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem) Then _ArrayAdd($context, $currentPath)
	EndIf
EndFunc


;~ Iterate over a treeview and make an operation on every node - can be called on root node (Null) or any other node
Func IterateOverTreeView(ByRef $context, $treeViewHandle, $treeViewItem = Null, $currentPath = '', $functionToApply = Null, $maxDepth = -1)
	If $treeViewItem == Null Then
		$treeViewItem = _GUICtrlTreeView_GetFirstItem($treeViewHandle)
		While $treeViewItem <> 0
			IterateOverTreeItem($context, $treeViewHandle, $treeViewItem, $currentPath, $functionToApply, 1, $maxDepth)
			$treeViewItem = _GUICtrlTreeView_GetNextSibling($treeViewHandle, $treeViewItem)
		WEnd
		Return
	EndIf
	IterateOverTreeItem($context, $treeViewHandle, $treeViewItem, $currentPath, $functionToApply, 1, $maxDepth)
EndFunc


;~ Iterate over a treeview item and make an operation on every node - cannot be called on root node (Null)
Func IterateOverTreeItem(ByRef $context, $treeViewHandle, $treeViewItem, $currentPath, $functionToApply, $currentDepth, $maxDepth)
	If $maxDepth <> -1 And $currentDepth > $maxDepth Then Return
	Local $treeViewItemName = _GUICtrlTreeView_GetText($treeViewHandle, $treeViewItem)
	Local $newPath = ($currentPath == '') ? $treeViewItemName : $currentPath & '.' & $treeViewItemName
	If $functionToApply <> Null Then $functionToApply($context, $treeViewHandle, $treeViewItem, $newPath)

	Local $child = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem)
	While $child <> 0
		IterateOverTreeItem($context, $treeViewHandle, $child, $newPath, $functionToApply, $currentDepth + 1, $maxDepth)
		$child = _GUICtrlTreeView_GetNextSibling($treeViewHandle, $child)
	WEnd
EndFunc


;~ Find a node in a treeview by its path as string
Func FindNodeInTreeView($treeViewHandle, $treeViewItem = Null, $path = '', $pathDelimiter = '.')
	Local $pathArray = StringSplit($path, $pathDelimiter)
	; Caution in AutoIT, StringSplit function returns array in which first element is count of items
	Local $pathArraySize = $pathArray[0]
	If $pathArraySize == 0 Or $path == '' Then Return Null
	If $treeViewItem == Null Then $treeViewItem = _GUICtrlTreeView_GetFirstItem($treeViewHandle)
	Return FindNodeInTreeViewHelper($treeViewHandle, $treeViewItem, $pathArray, 1)
EndFunc


;~ Find a node in a treeview by its path as string
Func FindNodeInTreeViewHelper($treeViewHandle, $treeViewItem, $pathArray, $pathArrayIndex)
	Local $treeViewItemName, $treeViewItemChildCount, $treeViewItemFirstChild
	While $treeViewItem <> 0
		$treeViewItemName = _GUICtrlTreeView_GetText($treeViewHandle, $treeViewItem)
		$treeViewItemChildCount = _GUICtrlTreeView_GetChildCount($treeViewHandle, $treeViewItem)
		If $treeViewItemName == $pathArray[$pathArrayIndex] Then
			If $pathArrayIndex == UBound($pathArray) - 1 Then
				Return $treeViewItem
			Else
				Return FindNodeInTreeViewHelper($treeViewHandle, _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem), $pathArray, $pathArrayIndex + 1)
			EndIf
		EndIf
		$treeViewItem = _GUICtrlTreeView_GetNextSibling($treeViewHandle, $treeViewItem)
	WEnd
	Return Null
EndFunc


;~ Check if a specific loot option is checked in treeview by providing its path as string
Func IsLootOptionChecked($itemPath, $treeViewHandle = $gui_treeview_lootoptions, $pathDelimiter = '.')
	Local $treeViewItem = FindNodeInTreeView($treeViewHandle, Null, $itemPath, $pathDelimiter)
	Return $treeViewItem == Null ? False : _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem)
EndFunc


;~ Function to check if any checkbox is checked in a branch starting in node provided as path string
Func IsAnyLootOptionInBranchChecked($startNodePath, $treeViewHandle = $gui_treeview_lootoptions, $pathDelimiter = '.')
	Local $treeViewItem = FindNodeInTreeView($treeViewHandle, Null, $startNodePath, $pathDelimiter)
	Return $treeViewItem == Null ? False : IsAnyChildInBranchChecked($treeViewHandle, $treeViewItem)
EndFunc


;~ Function to recursively traverse a branch in a tree view to check if any child in that branch is checked
Func IsAnyChildInBranchChecked($treeViewHandle, $treeViewItem)
	; Check if current tree node item is checked
	If _GUICtrlTreeView_GetChecked($treeViewHandle, $treeViewItem) Then Return True

	; Recursively check all child items of provided $treeViewItem
	If _GUICtrlTreeView_GetChildren($treeViewHandle, $treeViewItem) Then
		Local $childHandle = _GUICtrlTreeView_GetFirstChild($treeViewHandle, $treeViewItem)
		While $childHandle <> 0
			If IsAnyChildInBranchChecked($treeViewHandle, $childHandle) Then Return True
			$childHandle = _GUICtrlTreeView_GetNextChild($treeViewHandle, $childHandle)
		WEnd
	EndIf

	Return False
EndFunc
#EndRegion Loot Tree View Management


#Region GUI Settings
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


;~ Setup player build from GUI settings
Func SetupPlayerUsingGUISettings()
	If $run_options_cache['team.load_player_build'] Then
		Info('Loading player build from GUI')
		LoadSkillTemplate($run_options_cache['team.player_build'])
		RandomSleep(250)
	EndIf
EndFunc


Func SetupTeamUsingGUISettings($teamSize = $ID_TEAM_SIZE_LARGE)
	Info('Setting up team according to GUI settings')
	LeaveParty()
	RandomSleep(500)
	; Could use Eval(), it's shorter but it's kind of dirty
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
#EndRegion GUI Settings


Func RenameGUI($gui_title)
	WinSetTitle($gui_botshub, '', $gui_title)
EndFunc


Func ChangeCharacterNameBoxWithInput()
	GUICtrlDelete($gui_combo_characterchoice)
	$gui_combo_characterchoice = GUICtrlCreateCombo('Character Name Input', 10, 470, 150, 20)
EndFunc


Func EnableStartButton()
	GUICtrlSetData($gui_startbutton, 'Start')
	GUICtrlSetState($gui_startbutton, $GUI_ENABLE)
	GUICtrlSetBkColor($gui_startbutton, $COLOR_LIGHTBLUE)
EndFunc


#Region Dead GUI code but keep because it could come handy
;~ Create and destroy a temporary GUI hosting a list of things to pick from
Func OpenPickWindow()
	Local $windowWidth = 200
	Local $windowHeight = 500
	Local $mainPos = WinGetPos($gui_botshub)
	Local $windowXPos = $mainPos[0] + $mainPos[2] - $windowWidth - 75
	Local $windowYPos = $mainPos[1] + 25

	; need to be global
	$temporary_gui = GUICreate("List of stuff", $windowWidth, $windowHeight, $windowXPos, $windowYPos, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOOLWINDOW)
	Local $list = GUICtrlCreateList("", 8, 8, $windowWidth - 16, $windowHeight - 16, BitOR($LBS_EXTENDEDSEL, $WS_VSCROLL, $LBS_NOINTEGRALHEIGHT))

	; Fill list
	Local $alreadyPickedStuff = $map['pickedStuff']
	If $alreadyPickedStuff == Null Then
		Local $alreadyPickedStuff[]
		$map['pickedStuff'] = $alreadyPickedStuff
	EndIf
	For $i = 0 To UBound($ARRAY_STUFF) - 1
		GUICtrlSetData($list, $ARRAY_STUFF[$i])
		If $alreadyPickedStuff[$ARRAY_STUFF[$i]] <> Null Then _GUICtrlListBox_SetSel($list, $i, 1)
	Next

	; need to be global
	$temporary_gui_opened = True
	GUIRegisterMsg($GUI_WM_ACTIVATE, "TemporaryGUIWMActivateHandler")
	GUISetState(@SW_SHOW, $temporary_gui)

	While $temporary_gui_opened
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$temporary_gui_opened = False
		EndSwitch
	WEnd
	
	; harvest while GUI still exists
	Local $selectedStuff[]
	Local $selectedIndices = _GUICtrlListBox_GetSelItems($list)
	For $i = 1 To $selectedIndices[0]
		$selectedStuff[_GUICtrlListBox_GetText($list, $selectedIndices[$i])] = 1
	Next
	$map['pickedStuff'] = $selectedStuff
	GUIDelete($temporary_gui)
EndFunc


;~ Handler to catch clicks outside of temporary GUI
Func TemporaryGUIWMActivateHandler($handle, $message, $param)
	If $handle = $temporary_gui Then
		If BitAND($param, 0xFFFF) = $GUI_WA_INACTIVE Then
			$temporary_gui_opened = False
		EndIf
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc
#EndRegion Dead GUI code but keep because it could come handy