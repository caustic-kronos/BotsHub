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

#include-once
#include <WinAPI.au3>
#include <WinAPIMem.au3>
#include <WinAPIMem.au3>

#include 'GWA2_Assembly.au3'
#include 'Utils-Console.au3'
#include 'Utils-Debugger.au3'

; Written by master, read by all slaves
Global Const $MASTER_BROADCAST = 'Local\MasterBroadcast'
; Written by master, read by slave
Global Const $MASTER_TO_SLAVE = 'Local\MasterToSlave'
; Written by slave, read by master
Global Const $SLAVE_TO_MASTER = 'Local\SlaveToMaster'

Global Const $MASTER_SECTION		= 'uint	heartbeat;		byte	state'
Global Const $SLAVE_READ_SECTION	= 'byte	stateCommand;	byte	enableGUI'
Global Const $SLAVE_WRITE_SECTION	= 'uint	heartbeat;		byte	state'

; Constants required for memory access rights
;Global Const $PAGE_READWRITE = 0x04
;Global Const $FILE_MAP_ALL_ACCESS = 0xF001F
;Global Const $FILE_MAP_READ = 0x0001
;Global Const $FILE_MAP_WRITE = 0x0002

; Maps containing handles and addresses of shared memory blocks
Global $sharedMemoryHandlesMap[]
Global $sharedMemoryStructuresMap[]


; Called by master to create master shared memory block
Func CreateMasterSharedMemoryBlock()
	Return CreateSharedMemory($MASTER_BROADCAST, $MASTER_SECTION, $FILE_MAP_WRITE)
EndFunc


; Called by master to create slave shared memory blocks
Func CreateSlaveSharedMemoryBlock($slaveIndex)
	Local $slaveName = $MASTER_TO_SLAVE & '_' & $slaveIndex
	If Not CreateSharedMemory($slaveName, $SLAVE_READ_SECTION, $FILE_MAP_WRITE) Then
		Error('Failed to create master to slave shared memory block.')
		Return False
	EndIf

	$slaveName = $SLAVE_TO_MASTER & '_' & $slaveIndex
	If Not CreateSharedMemory($slaveName, $SLAVE_WRITE_SECTION, $FILE_MAP_READ) Then
		Error('Failed to create slave to master shared memory block.')
		Return False
	EndIf
	Return True
EndFunc


; Called by slave to open existing shared memory blocks created by master
Func OpenMasterSlaveSharedMemory($slaveIndex)
	If Not OpenSharedMemory($MASTER_BROADCAST, $MASTER_SECTION, $FILE_MAP_READ) Then
		Error('Failed to open master broadcast shared memory block.')
		Return False
	EndIf
	Local $slaveName = $MASTER_TO_SLAVE & '_' & $slaveIndex
	If Not OpenSharedMemory($slaveName, $SLAVE_READ_SECTION, $FILE_MAP_READ) Then
		Error('Failed to open master to slave shared memory block.')
		Return False
	EndIf
	$slaveName = $SLAVE_TO_MASTER & '_' & $slaveIndex
	If Not OpenSharedMemory($slaveName, $SLAVE_WRITE_SECTION, $FILE_MAP_WRITE) Then
		Error('Failed to open slave to master shared memory block.')
		Return False
	EndIf
	Return True
EndFunc


; Create a shared memory block and map it to the process address space
Func CreateSharedMemory($memoryName, $structureTemplate, $accessRights)
	Local $memorySize = DllStructGetSize(DllStructCreate($structureTemplate))
	Local $handle = SafeDllCall15($kernel_handle, 'handle', 'CreateFileMappingW', _
		'handle', -1, _
		'ptr', 0, _
		'dword', $PAGE_READWRITE, _
		'dword', 0, _
		'dword', $memorySize, _
		'wstr', $memoryName)
	If @error Or $handle[0] = 0 Then Return False
	$sharedMemoryHandlesMap[$memoryName] = $handle[0]

	Local $address = SafeDllCall13($kernel_handle, 'ptr', 'MapViewOfFile', _
		'handle', $handle[0], _
		'dword', $accessRights, _
		'dword', 0, _
		'dword', 0, _
		'dword', $memorySize)
	If @error Or $address[0] = 0 Then
		SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $handle[0])
		Return False
	EndIf
	$sharedMemoryStructuresMap[$memoryName] = DllStructCreate($structureTemplate, $address[0])
	Return True
EndFunc


; Open an existing shared memory block and map it to the process address space
Func OpenSharedMemory($memoryName, $structureTemplate, $accessRights)
	Local $handle = SafeDllCall9($kernel_handle, 'handle', 'OpenFileMappingW', _
		'dword', $accessRights, _
		'bool', False, _
		'wstr', $memoryName)
	If @error Or $handle[0] = 0 Then Return False
	$sharedMemoryHandlesMap[$memoryName] = $handle[0]

	Local $memorySize = DllStructGetSize(DllStructCreate($structureTemplate))
	Local $address = SafeDllCall13($kernel_handle, 'ptr', 'MapViewOfFile', _
		'handle', $handle[0], _
		'dword', $accessRights, _
		'dword', 0, _
		'dword', 0, _
		'dword', $memorySize)
	If @error Or $address[0] = 0 Then
		SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $handle[0])
		Return False
	EndIf

	$sharedMemoryStructuresMap[$memoryName] = DllStructCreate($structureTemplate, $address[0])
	Return True
EndFunc


; Write to the given field of the given shared memory block
Func WriteToSharedMemory($memoryName, $fieldName, $value)
	DllStructSetData($sharedMemoryStructuresMap[$memoryName], $fieldName, $value)
EndFunc


; Read from the given field of the given shared memory block
Func ReadFromSharedMemory($memoryName, $fieldName)
	Return DllStructGetData($sharedMemoryStructuresMap[$memoryName], $fieldName)
EndFunc


; Unmap the shared memory block from the process address space and close its handle
Func CloseSharedMemory($memoryName)
	SafeDllCall5($kernel_handle, 'bool', 'UnmapViewOfFile', 'ptr', DllStructGetPtr($sharedMemoryStructuresMap[$memoryName]))
	SafeDllCall5($kernel_handle, 'bool', 'CloseHandle', 'handle', $sharedMemoryHandlesMap[$memoryName])
    $sharedMemoryStructuresMap[$memoryName] = Null
    $sharedMemoryHandlesMap[$memoryName] = Null
EndFunc

; ----------------------------------------------------------------------------------------
Func WriteMasterBroadcast($fieldName, $value)
	DllStructSetData($sharedMemoryStructuresMap[$MASTER_BROADCAST], $fieldName, $value)
EndFunc

Func ReadMasterBroadcast($fieldName)
	Return DllStructGetData($sharedMemoryStructuresMap[$MASTER_BROADCAST], $fieldName)
EndFunc

Func WriteMasterToSlave($slaveIndex, $fieldName, $value)
	DllStructSetData($sharedMemoryStructuresMap[$MASTER_TO_SLAVE & '_' & $slaveIndex], $fieldName, $value)	
EndFunc

Func ReadMasterToSlave($slaveIndex, $fieldName)
	Return DllStructGetData($sharedMemoryStructuresMap[$MASTER_TO_SLAVE & '_' & $slaveIndex], $fieldName)
EndFunc

Func WriteSlaveToMaster($slaveIndex, $fieldName, $value)
	DllStructSetData($sharedMemoryStructuresMap[$SLAVE_TO_MASTER & '_' & $slaveIndex], $fieldName, $value)	
EndFunc

Func ReadSlaveToMaster($slaveIndex, $fieldName)
	Return DllStructGetData($sharedMemoryStructuresMap[$SLAVE_TO_MASTER & '_' & $slaveIndex], $fieldName)
EndFunc