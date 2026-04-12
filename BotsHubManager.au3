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
;#NoTrayIcon

Opt('MustDeclareVars', True)

#Region Includes
#include-once
#include 'lib/BotsHubManager-GUI.au3'
#include 'lib/GWA2_Assembly.au3'
#include 'lib/Utils-Console.au3'
#include 'lib/Utils-Shared_Memory.au3'
#EndRegion Includes


Global Const $STATE_IDLE = 0
Global Const $STATE_RUNNING = 1
Global Const $STATE_STOPPED = 2

; ---- GUI ----
Global Const $GUI_WIDTH = 500
Global Const $GUI_HEIGHT = 350

Global $master_heartbeat = 0
Global $slave_count = 0
Global $slave_character[10]
Global $slave_farm[10]
Global $slave_game_PID[10]
Global $slave_bot_PID[10]
Global $slave_heartbeat[10]
Global $slave_state[10]

LauncherMain()

Func LauncherMain()
	Local $gui = CreateBotsHubManagerGUI()
	CreateMasterSharedMemoryBlock()
	WriteMasterBroadcast('state', $STATE_RUNNING)
	ScanAndUpdateGameClients()
	SelectClient(1)
	AdlibRegister('UpdateMasterHeartbeat', 5000)
	OnAutoItExitRegister('CloseManager')
	While True
		UpdateInstancesUptime()
		Sleep(1000)
	WEnd
EndFunc


Func CloseManager()
	AdlibUnregister('UpdateMasterHeartbeat')
	CloseSharedMemory($MASTER_BROADCAST)
	For $i = 0 To $slave_count - 1
		CloseSharedMemory($MASTER_TO_SLAVE & '_' & $i)
		CloseSharedMemory($SLAVE_TO_MASTER & '_' & $i)
	Next
EndFunc


Func StartBotInstance($character, $farm)
	Local $index = FindClientIndexByCharacterName($character)
	SelectClient($index)
	Local $pid = GetPID()
	Local $slaveIndex = $slave_count
	$slave_count += 1
	$slave_character[$slaveIndex] = $character
	$slave_farm[$slaveIndex] = $farm
	$slave_game_PID[$slaveIndex] = $pid
	CreateSlaveSharedMemoryBlock($slaveIndex)

	Local $cmd = '"' & @AutoItExe & '" "' & @ScriptDir & '\BotsHub.au3" ' & $slaveIndex  & ' ' & $pid & ' "' & $character & '" "' & $farm & '"'
	Info($cmd)
	$slave_bot_PID[$slaveIndex] = Run($cmd)
	Return $slaveIndex
EndFunc


Func StopBotInstance($slaveIndex)
	If ProcessExists($slave_bot_PID[$slaveIndex]) Then ProcessClose($slave_bot_PID[$slaveIndex])
EndFunc


Func UpdateMasterHeartbeat()
	WriteMasterBroadcast('heartbeat', $master_heartbeat)
	$master_heartbeat += 1
EndFunc