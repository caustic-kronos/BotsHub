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

#include 'GWA2_Assembly.au3'
#include 'Utils-Console.au3'
#include 'Utils-Debugger.au3'

; Written by master, read by all slaves
Global Const $MASTER_BROADCAST = 'Local\MasterBroadcast_'
; Written by master, read by slave
Global Const $MASTER_TO_SLAVE = 'Local\MasterToSlave_'
; Written by slave, read by all slaves
Global Const $SLAVE_BROADCAST = 'Local\SlaveBroadcast_'
; Written by slave, read by master
Global Const $SLAVE_TO_MASTER = 'Local\SlaveToMaster_'

Global Const $SLAVE_BROADCAST_DATA_SIZE = 10 * 1024

Global Const $MASTER_SECTION			= 'uint	heartbeat;		byte	state'
Global Const $SLAVE_READ_SECTION		= 'byte	stateCommand;	byte	enableGUI'
Global Const $SLAVE_WRITE_SECTION		= 'uint	heartbeat;		byte	state'
Global Const $SLAVE_BROADCAST_SECTION	= 'uint	heartbeat;		byte	state;		byte	data[' & $SLAVE_BROADCAST_DATA_SIZE & ']'

; Constants required for memory access rights
;Global Const $PAGE_READWRITE = 0x04
;Global Const $FILE_MAP_ALL_ACCESS = 0xF001F
;Global Const $FILE_MAP_READ = 0x0001
;Global Const $FILE_MAP_WRITE = 0x0002
Global Const $ERROR_ALREADY_EXISTS = 183

Global Const $maxPeers = 10

; Maps containing handles and addresses of shared memory blocks
Global $sharedMemoryHandlesMap[]
Global $sharedMemoryStructuresMap[]

; Used by master to count its slaves
Global $slave_count = 0

; Used by clients to define their own peer index
Global $peerIndex = -1
Global $peers[10]

OnAutoItExitRegister('OnExitClosedSharedMemoryBlocks')

;~ Called by slaves to open other slaves shared memory - return first empty index found
Func OpenPeersSharedMemoryBlocks()
	Local $freeIndex = -1
	For $i = 0 To $maxPeers
		If Not OpenSharedMemory($SLAVE_BROADCAST & $i, $SLAVE_BROADCAST_SECTION, $FILE_MAP_READ) And $freeIndex < 0 Then $freeIndex = $i
	Next
	Return $freeIndex
EndFunc


;~ Called by master to create master shared memory block
Func CreateMasterSharedMemoryBlock()
	CreateSharedMemory($MASTER_BROADCAST, $MASTER_SECTION, $FILE_MAP_WRITE)
	WriteMasterBroadcast('state', $STATE_RUNNING)
EndFunc


;~ Called by slaves to create peer shared memory blocks
Func CreatePeerSharedMemoryBlock($index)
	$peerIndex = $index
	Return CreateSharedMemory($SLAVE_BROADCAST & $peerIndex, $SLAVE_BROADCAST_SECTION, $FILE_MAP_WRITE)
EndFunc


;~ Called by master to create slave shared memory blocks
Func CreateSlaveSharedMemoryBlock($slaveIndex)
	Local $slaveName = $MASTER_TO_SLAVE & $slaveIndex
	If Not CreateSharedMemory($slaveName, $SLAVE_READ_SECTION, $FILE_MAP_WRITE) Then
		Error('Failed to create master to slave shared memory block.')
		Return False
	EndIf

	$slaveName = $SLAVE_TO_MASTER & $slaveIndex
	If Not CreateSharedMemory($slaveName, $SLAVE_WRITE_SECTION, $FILE_MAP_READ) Then
		Error('Failed to create slave to master shared memory block.')
		Return False
	EndIf
	Return True
EndFunc


;~ Called by slave to open existing shared memory blocks created by master
Func OpenMasterSlaveSharedMemory($slaveIndex)
	If Not OpenSharedMemory($MASTER_BROADCAST, $MASTER_SECTION, $FILE_MAP_READ) Then
		Error('Failed to open master broadcast shared memory block.')
		Return False
	EndIf
	Local $slaveName = $MASTER_TO_SLAVE & $slaveIndex
	If Not OpenSharedMemory($slaveName, $SLAVE_READ_SECTION, $FILE_MAP_READ) Then
		Error('Failed to open master to slave shared memory block.')
		Return False
	EndIf
	$slaveName = $SLAVE_TO_MASTER & $slaveIndex
	If Not OpenSharedMemory($slaveName, $SLAVE_WRITE_SECTION, $FILE_MAP_WRITE) Then
		Error('Failed to open slave to master shared memory block.')
		Return False
	EndIf
	Return True
EndFunc


;~ Create a shared memory block and map it to the process address space
Func CreateSharedMemory($memoryName, $structureTemplate, $accessRights)
	Local $memorySize = DllStructGetSize(DllStructCreate($structureTemplate))
	Local $handle = SafeDllCall15($kernel_handle, 'handle', 'CreateFileMappingW', _
		'handle', -1, _
		'ptr', 0, _
		'dword', $PAGE_READWRITE, _
		'dword', 0, _
		'dword', $memorySize, _
		'wstr', $memoryName)
	If @error Or $handle[0] = 0 Then
		Error('Could not create a shared memory at ' & $memoryName)
		Return False
	EndIf

	; CreateFileMappingW may succeed even if name already existed - we check using GetLastError()
	Local $lastError = SafeDllCall3($kernel_handle, 'dword', 'GetLastError')
	If Not @error And $lastError[0] == $ERROR_ALREADY_EXISTS Then
		Error('Shared memory already exists at ' & $memoryName)
		SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $handle[0])
		Return False
	EndIf

	Local $address = SafeDllCall13($kernel_handle, 'ptr', 'MapViewOfFile', _
		'handle', $handle[0], _
		'dword', $accessRights, _
		'dword', 0, _
		'dword', 0, _
		'dword', $memorySize)
	If @error Or $address[0] = 0 Then
		Error('Could not map shared memory at ' & $memoryName)
		SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $handle[0])
		Return False
	EndIf
	Info('Created a shared memory mapping at ' & $memoryName)
	$sharedMemoryHandlesMap[$memoryName] = $handle[0]
	$sharedMemoryStructuresMap[$memoryName] = DllStructCreate($structureTemplate, $address[0])
	Return True
EndFunc


;~ Open an existing shared memory block and map it to the process address space
Func OpenSharedMemory($memoryName, $structureTemplate, $accessRights)
	Local $handle = SafeDllCall9($kernel_handle, 'handle', 'OpenFileMappingW', _
		'dword', $accessRights, _
		'bool', False, _
		'wstr', $memoryName)
	If @error Or $handle[0] = 0 Then
		Debug('Could not open shared memory at ' & $memoryName)
		Return False
	EndIf

	Local $memorySize = DllStructGetSize(DllStructCreate($structureTemplate))
	Local $address = SafeDllCall13($kernel_handle, 'ptr', 'MapViewOfFile', _
		'handle', $handle[0], _
		'dword', $accessRights, _
		'dword', 0, _
		'dword', 0, _
		'dword', $memorySize)
	If @error Or $address[0] = 0 Then
		Error('Could not map shared memory at ' & $memoryName)
		SafeDllCall5($kernel_handle, 'int', 'CloseHandle', 'int', $handle[0])
		Return False
	EndIf
	Info('Opened existing shared memory mapping at ' & $memoryName)
	$sharedMemoryHandlesMap[$memoryName] = $handle[0]
	$sharedMemoryStructuresMap[$memoryName] = DllStructCreate($structureTemplate, $address[0])
	Return True
EndFunc


;~ Unmap the shared memory block from the process address space and close its handle
Func CloseSharedMemory($memoryName)
	SafeDllCall5($kernel_handle, 'bool', 'UnmapViewOfFile', 'ptr', DllStructGetPtr($sharedMemoryStructuresMap[$memoryName]))
	SafeDllCall5($kernel_handle, 'bool', 'CloseHandle', 'handle', $sharedMemoryHandlesMap[$memoryName])
    $sharedMemoryStructuresMap[$memoryName] = Null
    $sharedMemoryHandlesMap[$memoryName] = Null
EndFunc


;~ Close all the shared memory blocks
Func OnExitClosedSharedMemoryBlocks()
	For $key In MapKeys($sharedMemoryStructuresMap)
		CloseSharedMemory($key)
	Next
EndFunc


;~ ----------------------------------------------------------------------------------------
Func WriteMasterBroadcast($fieldName, $value)
	WriteToSharedMemory($MASTER_BROADCAST, $fieldName, $value)
EndFunc

Func ReadMasterBroadcast($fieldName)
	Return ReadFromSharedMemory($MASTER_BROADCAST, $fieldName)
EndFunc

Func WriteMasterToSlave($slaveIndex, $fieldName, $value)
	WriteToSharedMemory($MASTER_TO_SLAVE & $slaveIndex, $fieldName, $value)
EndFunc

Func ReadMasterToSlave($slaveIndex, $fieldName)
	Return ReadFromSharedMemory($MASTER_TO_SLAVE & $slaveIndex, $fieldName)
EndFunc

Func WriteSlaveToMaster($slaveIndex, $fieldName, $value)
	WriteToSharedMemory($SLAVE_TO_MASTER & $slaveIndex, $fieldName, $value)
EndFunc

Func ReadSlaveToMaster($slaveIndex, $fieldName)
	Return ReadFromSharedMemory($SLAVE_TO_MASTER & $slaveIndex, $fieldName)
EndFunc

Func WritePeerBroadcast($fieldName, $value)
	WriteToSharedMemory($SLAVE_BROADCAST & $peerIndex, $fieldName, $value)
EndFunc

Func ReadPeerBroadcast($slaveIndex, $fieldName)
	Return ReadFromSharedMemory($SLAVE_BROADCAST & $slaveIndex, $fieldName)
EndFunc


;~ Write to the given field of the given shared memory block
Func WriteToSharedMemory($memoryName, $fieldName, $value)
	DllStructSetData($sharedMemoryStructuresMap[$memoryName], $fieldName, $value)
EndFunc


;~ Read from the given field of the given shared memory block
Func ReadFromSharedMemory($memoryName, $fieldName)
	Return DllStructGetData($sharedMemoryStructuresMap[$memoryName], $fieldName)
EndFunc


;~ Get a pointer to the given field of the given shared memory block
Func GetSharedMemoryPointer($memoryName, $fieldName)
	Return DllStructGetPtr($sharedMemoryStructuresMap[$memoryName], $fieldName)
EndFunc


;~ ----------------------------------------------------------------------------------------
Func WriteHeroesEffectsToSharedMemory(ByRef $effectsMap)
	Local $pointer = GetSharedMemoryPointer($SLAVE_BROADCAST & $peerIndex, 'data')
	Info('Getting ptr to ' & $pointer)

	Local $offset = 0
	; reserve payload size
	$offset += 4

	Local $keys = MapKeys($effectsMap)
	$offset = BinaryWriterWriteUInt($pointer, $offset, UBound($keys))
	Info('Agent count ' & UBound($keys))

	For $agentID In $keys
		Local $effects = $effectsMap[$agentID]
		Info('Effect count ' & UBound($effects))

		$offset = BinaryWriterWriteUInt($pointer, $offset, $agentID)
		$offset = BinaryWriterWriteUInt($pointer, $offset, UBound($effects))

		For $effect In $effects
			$offset = BinaryWriterWriteStruct($pointer, $offset, $effect)
		Next
	Next

	; $offset now corresponds to the total size of what we have written
	BinaryWriterWriteUInt($pointer, 0, $offset)
	Info('Payload size ' & $offset)
EndFunc

Func ReadHeroesEffectsFromSharedMemory($memoryName)
	Local $effectsMap[]

	Local $pointer = GetSharedMemoryPointer($memoryName, 'data')
	Info('Getting ptr to ' & $pointer)
	Local $offset = 0
	Local $payloadSize = BinaryReaderReadUInt($pointer, $offset)
	Info('Payload size ' & $payloadSize)
	$offset += 4
	If $payloadSize = 0 Then Return $effectsMap

	Local $agentCount = BinaryReaderReadUInt($pointer, $offset)
	Info('Agent count ' & $agentCount)
	$offset += 4

	For $i = 1 To $agentCount
		Local $agentID = BinaryReaderReadUInt($pointer, $offset)
		$offset += 4
		Local $effectCount = BinaryReaderReadUInt($pointer, $offset)
		Info('Effect count ' & $agentCount)
		$offset += 4

		Local $effects[$effectCount]
		For $j = 0 To $effectCount - 1
			$effects[$j] = BinaryReaderReadStruct($pointer, $offset, $EFFECT_STRUCT_TEMPLATE)
			$offset += DllStructGetSize($effects[$j])
		Next

		$effectsMap[$agentID] = $effects
	Next

	If $offset > $payloadSize Then
		Warn("Shared memory over-read")
	ElseIf $offset < $payloadSize Then
		Warn("Shared memory under-read")
	EndIf

	Return $effectsMap
EndFunc

Func BinaryWriterWriteUInt($pointer, $offset, $value)
	If $offset + 4 > $SLAVE_BROADCAST_DATA_SIZE Then
		Error("Shared memory overflow")
		Return SetError(1, 0, $offset)
	EndIf

	Local $struct = SafeDllStructCreate('uint', $pointer + $offset)
	DllStructSetData($struct, 1, $value)
	Return $offset + 4
EndFunc

Func BinaryWriterWriteStruct($pointer, $offset, $struct)
	Local $size = DllStructGetSize($struct)
	If $offset + $size > $SLAVE_BROADCAST_DATA_SIZE Then
		Error("Shared memory overflow")
		Return SetError(1, 0, $offset)
	EndIf

	_WinAPI_MoveMemory($pointer + $offset, DllStructGetPtr($struct), $size)
	Return $offset + $size
EndFunc

Func BinaryReaderReadUInt($pointer, $offset)
	Local $struct = SafeDllStructCreate('uint', $pointer + $offset)
	Return DllStructGetData($struct, 1)
EndFunc

Func BinaryReaderReadStruct($pointer, $offset, $template)
	Local $struct = SafeDllStructCreate($template)
	_WinAPI_MoveMemory(DllStructGetPtr($struct), $pointer + $offset, DllStructGetSize($struct))
	Return $struct
EndFunc