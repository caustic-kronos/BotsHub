#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2026 caustic-kronos
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

Opt('GUIOnEventMode', True)
Opt('GUICloseOnESC', False)

#include-once
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <GuiRichEdit.au3>

#include '../BotsHubManager.au3'
#include 'BotsHub-GUI.au3'
#include 'Utils-Console.au3'

;; ============================================================
;;  GLOBALS
;; ============================================================

Global Const $GLOBAL_ROW_HEIGHT     = 50
Global Const $GLOBAL_GUIWIDTH       = 1600
Global Const $GLOBAL_GUIHEIGHT      = 900
Global Const $GLOBAL_CONSOLEWIDTH   = Int($GLOBAL_GUIWIDTH / 4)
Global Const $GLOBAL_TABLEOFFSETX   = $GLOBAL_CONSOLEWIDTH + 20

; Column indices for $client_row[id][col]
Global Const $ROW_SEPARATOR_INDEX       = 0
Global Const $ROW_STATUS_INDEX          = 1
Global Const $ROW_CHARACTER_INDEX       = 2
Global Const $ROW_FARM_INDEX            = 3
Global Const $ROW_CONFIGURATION_INDEX   = 4
Global Const $ROW_START_PAUSE_INDEX     = 5
Global Const $ROW_STOP_INDEX            = 6
Global Const $ROW_SHOW_GUI_INDEX        = 7
Global Const $ROW_UPTIME_INDEX          = 8
Global Const $ROW_HEARTBEAT_INDEX       = 9
Global Const $ROW_REMOVE_INDEX          = 10
Global Const $ROW_COL_COUNT             = 11

; Column indices for $client_data[id][col]
Global Const $DATA_ALIVE_INDEX      = 0
Global Const $DATA_SLAVE_INDEX      = 1
Global Const $DATA_TIMER_INDEX      = 2
Global Const $DATA_COL_COUNT        = 3

Global Const $COLOR_CHARCOAL = 0x444444

; $client_row[id][col]  - GUI control handles, indexed by permanent ID, never reordered
; $client_data[id][col] - [0]=alive, [1]=slave index, [2]=timer, indexed by permanent ID, never reordered
; $display_order[pos]   - ordered list of IDs, this is what gets sorted/filtered-repositioned
Global $client_row[0][$ROW_COL_COUNT]
Global $client_data[0][$DATA_COL_COUNT]
Global $display_order[0]
Global $next_client_id  = 0
Global $global_filter_state = 'ALL'
Global $global_sort_asc     = True

Global $manager_gui
Global $button_filter_all
Global $button_filter_running
Global $button_filter_stopped
Global $button_sort_name
Global $button_sort_farm
Global $button_sort_uptime
Global $button_add_client


;; ============================================================
;;  GUI CREATION
;; ============================================================

Func CreateBotsHubManagerGUI()
    $manager_gui = GUICreate('BotsHub Manager', $GLOBAL_GUIWIDTH, $GLOBAL_GUIHEIGHT)

    Local $managerConsole = _GUICtrlRichEdit_Create($manager_gui, '', 10, 10, $GLOBAL_CONSOLEWIDTH - 20, $GLOBAL_GUIHEIGHT - 20, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
    _GUICtrlRichEdit_SetCharColor($managerConsole, $COLOR_WHITE)
    _GUICtrlRichEdit_SetBkColor($managerConsole, $COLOR_BLACK)
    _GUICtrlRichEdit_SetReadOnly($managerConsole, True)
    SetConsole($managerConsole)

    $button_filter_all      = GUICtrlCreateButton('All',         $GLOBAL_TABLEOFFSETX + 10,  20, 80,  30)
    $button_filter_running  = GUICtrlCreateButton('Running',     $GLOBAL_TABLEOFFSETX + 100, 20, 80,  30)
    $button_filter_stopped  = GUICtrlCreateButton('Stopped',     $GLOBAL_TABLEOFFSETX + 190, 20, 80,  30)
    $button_sort_name       = GUICtrlCreateButton('Sort Name',   $GLOBAL_TABLEOFFSETX + 310, 20, 100, 30)
    $button_sort_farm       = GUICtrlCreateButton('Sort Farm',   $GLOBAL_TABLEOFFSETX + 420, 20, 100, 30)
    $button_sort_uptime     = GUICtrlCreateButton('Sort Uptime', $GLOBAL_TABLEOFFSETX + 530, 20, 110, 30)
    $button_add_client      = GUICtrlCreateButton('Add Instance',$GLOBAL_TABLEOFFSETX + 680, 20, 120, 30)

    GUISetOnEvent($GUI_EVENT_CLOSE,     'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_filter_all,     'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_filter_running, 'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_filter_stopped, 'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_sort_name,      'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_sort_farm,      'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_sort_uptime,    'ManagerGuiButtonsHandler')
    GUICtrlSetOnEvent($button_add_client,     'GuiAddRow')

    Local $headerY = 70
    GUICtrlCreateLabel('Status',    $GLOBAL_TABLEOFFSETX + 10,   $headerY, 80,  20)
    GUICtrlCreateLabel('Character', $GLOBAL_TABLEOFFSETX + 100,  $headerY, 180, 20)
    GUICtrlCreateLabel('Farm',      $GLOBAL_TABLEOFFSETX + 290,  $headerY, 180, 20)
    GUICtrlCreateLabel('Config',    $GLOBAL_TABLEOFFSETX + 480,  $headerY, 180, 20)
    GUICtrlCreateLabel('Control',   $GLOBAL_TABLEOFFSETX + 670,  $headerY, 120, 20)
    GUICtrlCreateLabel('Stop',      $GLOBAL_TABLEOFFSETX + 800,  $headerY, 80,  20)
    GUICtrlCreateLabel('GUI',       $GLOBAL_TABLEOFFSETX + 890,  $headerY, 80,  20)
    GUICtrlCreateLabel('Uptime',    $GLOBAL_TABLEOFFSETX + 980,  $headerY, 120, 20)
    GUICtrlCreateLabel('Heartbeat', $GLOBAL_TABLEOFFSETX + 1050, $headerY, 120, 20)
    GUICtrlCreateLabel('Remove',    $GLOBAL_TABLEOFFSETX + 1110, $headerY, 80,  20)

    GuiAddRow()
    GUISetState(@SW_SHOW)
    Info('GW Bot Hub Manager 0.1')
EndFunc


;; ============================================================
;;  TOP BAR BUTTON HANDLER
;; ============================================================

Func ManagerGuiButtonsHandler()
    Switch @GUI_CtrlId
        Case $GUI_EVENT_CLOSE
            Exit
        Case $button_filter_all
            $global_filter_state = 'ALL'
            ApplyFilter()
        Case $button_filter_running
            $global_filter_state = 'Running'
            ApplyFilter()
        Case $button_filter_stopped
            $global_filter_state = 'Stopped'
            ApplyFilter()
        Case $button_sort_name
            SortRows($ROW_CHARACTER_INDEX)
        Case $button_sort_farm
            SortRows($ROW_FARM_INDEX)
        Case $button_sort_uptime
            SortRows($ROW_UPTIME_INDEX)
        Case Else
            MsgBox(0, 'Error', 'This button is not coded yet.')
    EndSwitch
EndFunc


;; ============================================================
;;  ROW CREATION
;; ============================================================

Func GuiAddRow()
    Local $id = $next_client_id
    $next_client_id += 1

    ;; Grow data arrays by one slot (indexed by permanent ID)
    ReDim $client_row[$next_client_id][$ROW_COL_COUNT]
    ReDim $client_data[$next_client_id][$DATA_COL_COUNT]

    ;; Initialise data for this ID
    $client_data[$id][$DATA_ALIVE_INDEX] = True
    $client_data[$id][$DATA_SLAVE_INDEX] = -1
    $client_data[$id][$DATA_TIMER_INDEX] = 0

    ;; Place the row at the bottom of whatever is currently visible
    Local $localY = _GetNextRowY()

    ;; Append ID to the display order
    Local $displayCount = UBound($display_order) + 1
    ReDim $display_order[$displayCount]
    $display_order[$displayCount - 1] = $id

    $client_row[$id][$ROW_SEPARATOR_INDEX] = GUICtrlCreateGraphic($GLOBAL_TABLEOFFSETX, $localY - 5, 1200, 1)
    GUICtrlSetGraphic(-1, $GUI_GR_COLOR, $COLOR_CHARCOAL)
    GUICtrlSetGraphic(-1, $GUI_GR_LINE, 0, 0, 1200, 0)

    $client_row[$id][$ROW_STATUS_INDEX] = GUICtrlCreateLabel('Stopped', $GLOBAL_TABLEOFFSETX + 10, $localY, 80, 30, $SS_CENTER)
    GUICtrlSetBkColor(-1, $COLOR_RED)

    $client_row[$id][$ROW_CHARACTER_INDEX] = GUICtrlCreateInput('No character selected', $GLOBAL_TABLEOFFSETX + 100, $localY, 180, 30)

    $client_row[$id][$ROW_FARM_INDEX] = GUICtrlCreateCombo('Choose a farm', $GLOBAL_TABLEOFFSETX + 290, $localY, 180, 30)
    GUICtrlSetData($client_row[$id][$ROW_FARM_INDEX], $AVAILABLE_FARMS, 'Choose a farm')

    $client_row[$id][$ROW_CONFIGURATION_INDEX] = GUICtrlCreateCombo('ConfigA', $GLOBAL_TABLEOFFSETX + 480, $localY, 180, 30)
    GUICtrlSetData($client_row[$id][$ROW_CONFIGURATION_INDEX], 'ConfigA|ConfigB|ConfigC', 'ConfigA')

    $client_row[$id][$ROW_START_PAUSE_INDEX] = GUICtrlCreateButton('Start', $GLOBAL_TABLEOFFSETX + 670, $localY, 100, 30)
    GUICtrlSetOnEvent($client_row[$id][$ROW_START_PAUSE_INDEX], 'HandleRowActions')

    $client_row[$id][$ROW_STOP_INDEX] = GUICtrlCreateButton('Stop', $GLOBAL_TABLEOFFSETX + 800, $localY, 80, 30)
    GUICtrlSetOnEvent($client_row[$id][$ROW_STOP_INDEX], 'HandleRowActions')

    $client_row[$id][$ROW_SHOW_GUI_INDEX] = GUICtrlCreateButton('Show GUI', $GLOBAL_TABLEOFFSETX + 890, $localY, 80, 30)
    GUICtrlSetOnEvent($client_row[$id][$ROW_SHOW_GUI_INDEX], 'HandleRowActions')

    $client_row[$id][$ROW_UPTIME_INDEX] = GUICtrlCreateLabel('00:00:00', $GLOBAL_TABLEOFFSETX + 980, $localY, 120, 30)

    $client_row[$id][$ROW_HEARTBEAT_INDEX] = GUICtrlCreateLabel('0', $GLOBAL_TABLEOFFSETX + 1050, $localY, 60, 30)

    $client_row[$id][$ROW_REMOVE_INDEX] = GUICtrlCreateButton('X', $GLOBAL_TABLEOFFSETX + 1110, $localY, 40, 30)
    GUICtrlSetOnEvent($client_row[$id][$ROW_REMOVE_INDEX], 'HandleRowActions')
    GUICtrlSetBkColor(-1, $COLOR_GRAY)
EndFunc


;; ============================================================
;;  ROW EVENT HANDLER
;; ============================================================

;; Searches all ever-created IDs; skips dead ones.
;; Data arrays are never reordered so ID = array index always holds.
Func HandleRowActions()
    For $id = 0 To $next_client_id - 1
        If Not $client_data[$id][$DATA_ALIVE_INDEX] Then ContinueLoop

        Switch @GUI_CtrlId
            Case $client_row[$id][$ROW_START_PAUSE_INDEX]
                ToggleStartPause($id)
                Return
            Case $client_row[$id][$ROW_STOP_INDEX]
                SetStopped($id)
                Return
            Case $client_row[$id][$ROW_SHOW_GUI_INDEX]
                ToggleInstanceGUI($id)
                Return
            Case $client_row[$id][$ROW_REMOVE_INDEX]
                RemoveRow($id)
                Return
        EndSwitch
    Next
    MsgBox(0, 'Error', 'Unhandled row action.')
EndFunc


;; ============================================================
;;  ROW ACTIONS
;; ============================================================

Func ToggleStartPause($id)
    If GUICtrlRead($client_row[$id][$ROW_START_PAUSE_INDEX]) = 'Start' Then
        GUICtrlSetData($client_row[$id][$ROW_START_PAUSE_INDEX], 'Pause')
        GUICtrlSetData($client_row[$id][$ROW_STATUS_INDEX], 'Running')
        GUICtrlSetBkColor($client_row[$id][$ROW_STATUS_INDEX], $COLOR_GREEN)
        $client_data[$id][$DATA_TIMER_INDEX] = TimerInit()
        $client_data[$id][$DATA_SLAVE_INDEX] = StartBotInstance( _
            GUICtrlRead($client_row[$id][$ROW_CHARACTER_INDEX]), _
            GUICtrlRead($client_row[$id][$ROW_FARM_INDEX]))
        Info('Instance started')
    Else
        _SetRowStopped($id)
        Info('Instance paused')
    EndIf
EndFunc

Func SetStopped($id)
    _SetRowStopped($id)
    Info('Instance stopped')
EndFunc

;; Shared visual reset used by both ToggleStartPause and SetStopped
Func _SetRowStopped($id)
    GUICtrlSetData($client_row[$id][$ROW_START_PAUSE_INDEX], 'Start')
    GUICtrlSetData($client_row[$id][$ROW_STATUS_INDEX], 'Stopped')
    GUICtrlSetBkColor($client_row[$id][$ROW_STATUS_INDEX], $COLOR_RED)
    GUICtrlSetData($client_row[$id][$ROW_UPTIME_INDEX], '00:00:00')
    StopBotInstance($client_data[$id][$DATA_SLAVE_INDEX])
EndFunc

Func ToggleInstanceGUI($id)
    Local $currentValue = ReadMasterToSlave($client_data[$id][$DATA_SLAVE_INDEX], 'enableGUI')
    WriteMasterToSlave($client_data[$id][$DATA_SLAVE_INDEX], 'enableGUI', Not $currentValue)
EndFunc


;; ============================================================
;;  ROW REMOVAL
;; ============================================================

Func RemoveRow($id)
    ;; Delete all GUI controls for this ID
    For $c = 0 To $ROW_COL_COUNT - 1
        GUICtrlDelete($client_row[$id][$c])
    Next

    ;; Mark as dead — data arrays keep their slots, ID is now a tombstone
    $client_data[$id][$DATA_ALIVE_INDEX] = False

    ;; Splice the ID out of display_order
    Local $displayCount = UBound($display_order)
    Local $newOrder[$displayCount - 1]
    Local $w = 0
    For $i = 0 To $displayCount - 1
        If $display_order[$i] <> $id Then
            $newOrder[$w] = $display_order[$i]
            $w += 1
        EndIf
    Next
    $display_order = $newOrder

    Info('Instance removed')
    RepositionAllRows()
EndFunc


;; ============================================================
;;  LAYOUT HELPERS
;; ============================================================

;; Returns Y position for a newly added row, placed after all currently visible rows
Func _GetNextRowY()
    Local $visibleCount = 0
    For $i = 0 To UBound($display_order) - 1
        Local $id = $display_order[$i]
        If BitAND(GUICtrlGetState($client_row[$id][$ROW_STATUS_INDEX]), $GUI_SHOW) Then
            $visibleCount += 1
        EndIf
    Next
    Return 100 + ($visibleCount * $GLOBAL_ROW_HEIGHT)
EndFunc

;; Repositions all rows in display_order order.
;; Hidden rows take no vertical space, so filter and sort compose cleanly.
Func RepositionAllRows()
    Local $visibleCount = 0
    For $i = 0 To UBound($display_order) - 1
        Local $id = $display_order[$i]
        Local $isVisible = BitAND(GUICtrlGetState($client_row[$id][$ROW_STATUS_INDEX]), $GUI_SHOW)
        Local $localY = 100 + ($visibleCount * $GLOBAL_ROW_HEIGHT)

        For $c = 0 To $ROW_COL_COUNT - 1
            Local $localPos = ControlGetPos($manager_gui, '', $client_row[$id][$c])
            If IsArray($localPos) Then
                GUICtrlSetPos($client_row[$id][$c], $localPos[0], $localY)
            EndIf
        Next

        If $isVisible Then $visibleCount += 1
    Next
EndFunc


;; ============================================================
;;  FILTER
;; ============================================================

;; Filter is purely a visibility operation — $display_order is never touched.
Func ApplyFilter()
    For $i = 0 To UBound($display_order) - 1
        Local $id = $display_order[$i]
        Local $localState = GUICtrlRead($client_row[$id][$ROW_STATUS_INDEX])
        Local $localVisible = ($global_filter_state = 'ALL') Or ($localState = $global_filter_state)
        _SetRowVisible($id, $localVisible)
    Next
    RepositionAllRows()
EndFunc

Func _SetRowVisible($id, $localVisible)
    Local $newState = $GUI_HIDE
    If $localVisible Then $newState = $GUI_SHOW
    For $c = 0 To $ROW_COL_COUNT - 1
        GUICtrlSetState($client_row[$id][$c], $newState)
    Next
EndFunc


;; ============================================================
;;  SORT
;; ============================================================

;; Reorders $display_order only, then repositions.
;; $client_row and $client_data are never touched.
Func SortRows($localColumn)
    Local $displayCount = UBound($display_order)
    Local $sortData[$displayCount][2]

    For $i = 0 To $displayCount - 1
        Local $id = $display_order[$i]
        If $localColumn = $ROW_UPTIME_INDEX Then
            $sortData[$i][0] = TimeToSeconds(GUICtrlRead($client_row[$id][$ROW_UPTIME_INDEX]))
        Else
            $sortData[$i][0] = GUICtrlRead($client_row[$id][$localColumn])
        EndIf
        $sortData[$i][1] = $id
    Next

    _ArraySort($sortData, $global_sort_asc, 0, 0, 0)
    $global_sort_asc = Not $global_sort_asc

    ;; Rebuild display_order from the sorted result
    For $i = 0 To $displayCount - 1
        $display_order[$i] = $sortData[$i][1]
    Next

    RepositionAllRows()
EndFunc


;; ============================================================
;;  UPTIME TICKER
;; ============================================================

Func UpdateInstancesUptime()
    For $id = 0 To $next_client_id - 1
        If Not $client_data[$id][$DATA_ALIVE_INDEX] Then ContinueLoop
        If GUICtrlRead($client_row[$id][$ROW_STATUS_INDEX]) <> 'Running' Then ContinueLoop

        Local $localDiff    = TimerDiff($client_data[$id][$DATA_TIMER_INDEX])
        Local $localSeconds = Int($localDiff / 1000)
        Local $localH = Int($localSeconds / 3600)
        Local $localM = Int(Mod($localSeconds, 3600) / 60)
        Local $localS = Mod($localSeconds, 60)
        GUICtrlSetData($client_row[$id][$ROW_UPTIME_INDEX], StringFormat('%02d:%02d:%02d', $localH, $localM, $localS))
        GUICtrlSetData($client_row[$id][$ROW_HEARTBEAT_INDEX], ReadSlaveToMaster($client_data[$id][$DATA_SLAVE_INDEX], 'heartbeat'))
    Next
EndFunc


;; ============================================================
;;  UTILITIES
;; ============================================================

Func TimeToSeconds($localTime)
    Local $localSplit = StringSplit($localTime, ':')
    If $localSplit[0] <> 3 Then Return 0
    Return ($localSplit[1] * 3600) + ($localSplit[2] * 60) + $localSplit[3]
EndFunc