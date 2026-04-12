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

#RequireAdmin
#NoTrayIcon

Opt('MustDeclareVars', True)

#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiRichEdit.au3>

#include 'lib/GWA2_Assembly.au3'
#include 'lib/Utils-Console.au3'
#include 'lib/Utils-Shared_Memory.au3'

Global Const $STATE_IDLE = 0
Global Const $STATE_RUNNING = 1
Global Const $STATE_STOPPED = 2

; ---- GUI ----
Global Const $GUI_WIDTH = 500
Global Const $GUI_HEIGHT = 350

Global $botPID = 0
Global $masterHeartbeat = 0
Global $lastSlaveHeartbeat = 0
Global $lastSlaveState = $STATE_STOPPED

LauncherTestMain()


Func LauncherTestMain()
	Local $gui = GUICreate('BotsHub Launcher', $GUI_WIDTH, $GUI_HEIGHT)

	GUICtrlCreateLabel('Character Name', 20, 20, 120, 20)
	Local $inputCharacter = GUICtrlCreateInput('', 150, 20, 200, 20)

	GUICtrlCreateLabel('Farm Name', 20, 55, 120, 20)
	Local $inputFarm = GUICtrlCreateInput('Tests', 150, 55, 200, 20)

	Local $checkboxGUI = GUICtrlCreateCheckbox('Enable Bot GUI', 150, 90, 150, 20)
	Local $buttonStart = GUICtrlCreateButton('Start', 60, 140, 100, 30)
	Local $buttonStop = GUICtrlCreateButton('Stop', 160, 140, 100, 30)
	Local $buttonKill = GUICtrlCreateButton('Kill', 260, 140, 100, 30)
	Local $buttonRefresh = GUICtrlCreateButton('Refresh Info', 360, 140, 100, 30)
	Local $labelStatus = GUICtrlCreateLabel('Bot State: N/A', 20, 180, 250, 20)
	Local $labelHeartbeat = GUICtrlCreateLabel('Slave HB: N/A', 220, 180, 150, 20)

	; Console area
	Local $console = _GUICtrlRichEdit_Create($gui, '', 20, 210, 460, 120, BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL))
	_GUICtrlRichEdit_SetCharColor($console, 0xFFFFFF)
	_GUICtrlRichEdit_SetBkColor($console, 0x000000)
	GUISetState(@SW_SHOW)
	SetConsole($console)

	CreateMasterSharedMemoryBlock()
	WriteMasterBroadcast('state', $STATE_RUNNING)
	ScanAndUpdateGameClients()
	SelectClient(1)

	AdlibRegister('UpdateMasterHeartbeat', 5000)

	While True
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				CloseSharedMemory($MASTER_BROADCAST)
				CloseSharedMemory($MASTER_TO_SLAVE & '_0')
				CloseSharedMemory($SLAVE_TO_MASTER & '_0')
				Exit
			Case $buttonStart
				StartBot(GUICtrlRead($inputCharacter), GUICtrlRead($inputFarm))

			Case $buttonStop
				WriteMasterToSlave(0, 'stateCommand', $STATE_STOPPED)

			Case $buttonKill
				WriteMasterToSlave(0, 'stateCommand', $STATE_STOPPED)

			Case $checkboxGUI
				WriteMasterToSlave(0, 'enableGUI', GUICtrlRead($checkboxGUI) == $GUI_CHECKED)

			Case $buttonRefresh
				UpdateSlaveConsole()
		EndSwitch
	WEnd
EndFunc


Func StartBot($character, $farm)
	Local $pid = GetPID()
	Local $slaveIndex = 0
	CreateSlaveSharedMemoryBlock($slaveIndex)

	Local $cmd = '"' & @AutoItExe & '" "' & @ScriptDir & '\BotsHub.au3" ' & $slaveIndex  & ' ' & $pid & ' "' & $character & '" "' & $farm & '"'
	Info($cmd)
	$botPID = Run($cmd)
EndFunc


Func GetSlaveInfos()
	$lastSlaveHeartbeat = ReadSlaveToMaster(0, 'heartbeat')
	$lastSlaveState = ReadSlaveToMaster(0, 'state')
EndFunc

Func UpdateSlaveConsole()
	GetSlaveInfos()
	Info(@HOUR & ':' & @MIN & ':' & @SEC & ' - Slave Heartbeat: ' & $lastSlaveHeartbeat & ' | State: ' & $lastSlaveState & @CRLF)
EndFunc


Func UpdateMasterHeartbeat()
	WriteMasterBroadcast('heartbeat', $masterHeartbeat)
	$masterHeartbeat += 1
EndFunc