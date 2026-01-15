#CS ===========================================================================
; AutoIt Wrapper and Logging Framework for Memory Operations
; Use to debug GW crashes when using bot
; Main operations that can cause crash
; DllStructCreate
; DllCall

; This file offers wrapper alternatives to those operations that log the calls and potentially the errors
; This can then be used in conjunction with the crash log to see which call created the crash

; Additional elements to wrap or protect :
; - invalid memory access (ReadProcessMemory, WriteProcessMemory) -> use VirtualQueryEx to confirm memory is readable/writable
; - DllStructGetData
; - DllStructSetData
#CE ===========================================================================

#include-once

#include 'Utils.au3'

Global Const $DEBUG_MODE = False
Global Const $ADD_CONTEXT = False
Global Const $FUNCTION_NAMES = ['SetProcessWorkingSetSizeEx','VirtualQueryEx','VirtualFreeEx','VirtualAllocEx','ReadProcessMemory','WriteProcessMemory','CreateRemoteThread','CloseHandle','WaitForSingleObject','OpenProcess','SetProcessWorkingSetSize']
; VirtualQueryEx error code is 0 - but it shouldn't be caught
Global Const $ERROR_CODES = [0, -1, 0, Null, 0, 0, Null, 0, 0xFFFFFFFF, Null, 0]
Global Const $FUNCTION_ERROR_CODES = MapFromArrays($FUNCTION_NAMES, $ERROR_CODES)

Global $log_handle = -1
Global $context_stack[100]
Global $context_depth = 0

;~ Opens log file
Func OpenDebugLogFile()
	If Not $DEBUG_MODE Then Return
	Local $logFile = @ScriptDir & '/logs/dll_debug-' & GetCharacterName() & '.log'
	$log_handle = FileOpen($logFile, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	If $log_handle = -1 Then
		MsgBox(16, 'Error', 'Failed to open log file: ' & $logFile)
		Exit
	EndIf
	OnAutoItExitRegister('CloseLogFile')
	DebuggerLog('[STARTING UP DEBUGGER]')
EndFunc

;~ Closes log file
Func CloseLogFile()
	DebuggerLog('[CLOSING DEBUGGER]')
	If $log_handle <> -1 Then FileClose($log_handle)
EndFunc

;~ Log critical error in a OneShot way - only use for very specific usage
Func LogCriticalError($log)
	If $log_handle == -1 Then
		Local $logFile = @ScriptDir & '/logs/dll_debug-' & GetCharacterName() & '.log'
		$log_handle = FileOpen($logFile, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	EndIf
	DebuggerLog($log)
	If $log_handle <> -1 Then FileClose($log_handle)
EndFunc

;~ Write log in log file
Func DebuggerLog($msg)
	Local $log = '[' & @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @SEC & ':' & @MSEC & ']-'
	If $ADD_CONTEXT Then $log &= '[' & GetCurrentContext() & ']-'
	FileWriteLine($log_handle, $log & $msg)
	Debug($msg)
EndFunc

;~ Add context to create a simili stack trace
Func PushContext($label)
	If Not $DEBUG_MODE Or Not $ADD_CONTEXT Then Return False
	$context_stack[$context_depth] = $label
	$context_depth += 1
	Return True
EndFunc

;~ Pop last element from stack trace
Func PopContext($useless = '')
	If Not $DEBUG_MODE Or Not $ADD_CONTEXT Then Return False
	$context_depth -= 1
	$context_stack[$context_depth] = ''
	Return True
EndFunc

;~ Get current context
Func GetCurrentContext()
	If Not $DEBUG_MODE Or Not $ADD_CONTEXT Then Return ''
	Local $joined = ''
	For $i = 0 To $context_depth - 1
		$joined &= $context_stack[$i] & '|'
	Next
	If $joined <> '' Then $joined = StringTrimRight($joined, 1)
	Return $joined
EndFunc


;~ Dump bytes to see memory
Func MemoryDump($address, $size)
	Local $buffer = DllStructCreate('byte[' & $size & ']')
	DllCall($kernel_handle, 'bool', 'ReadProcessMemory', 'handle', GetProcessHandle(), 'ptr', $address, 'struct*', $buffer, 'ulong_ptr', $size, 'ptr', 0)
	Local $output = ''
	For $i = 1 To $size
		$output &= Hex(DllStructGetData($buffer, 1, $i), 2) & ' '
	Next
	Return $output
EndFunc


; === Wrapper Functions ===
;~ DllStructCreate wrapper
Func SafeDllStructCreate($type, $ptr = -1)
	If Not $DEBUG_MODE Then Return $ptr <> -1 ? DllStructCreate($type, $ptr) : DllStructCreate($type)
	Local $call = 'DllStructCreate(type=' & $type & ',ptr=' & $ptr & ')'
	If $ptr <> -1 And Not IsPtr($ptr) Then
		DebuggerLog('[ERROR] Invalid pointer passed to ' & $call)
	EndIf
	Local $struct
	If $ptr <> -1 Then
		$struct = DllStructCreate($type, $ptr)
	Else
		$struct = DllStructCreate($type)
	EndIf
	If @error Then DebuggerLog('[ERROR] Failure on ' & $call)
	Return $struct
EndFunc

;~ DllStructGetData wrapper
Func SafeDllStructGetData($struct, $element)
	If Not $DEBUG_MODE Then Return DllStructGetData($struct, $element)
	Local $call = 'DllStructGetData(struct=' & $struct & ',element=' & $element & ')'
	If Not IsDllStruct($struct) Then
		DebuggerLog('[ERROR] Invalid DllStruct passed to ' & $call)
	EndIf
	Local $data = DllStructGetData($struct, $element)
	If @error Then DebuggerLog('[ERROR] Failure on ' & $call)
	Return $data
EndFunc

;~ DllStructSetData wrapper
Func SafeDllStructSetData($struct, $element)
	If Not $DEBUG_MODE Then Return DllStructSetData($struct, $element)
	Local $call = 'DllStructSetData(struct=' & $struct & ',element=' & $element & ')'
	If Not IsDllStruct($struct) Then
		DebuggerLog('[ERROR] Invalid DllStruct passed to ' & $call)
	EndIf
	Local $data = DllStructSetData($struct, $element)
	If @error Then DebuggerLog('[ERROR] Failure on ' & $call)
	Return $data
EndFunc

;~ DllCall wrapper
Func SafeDllCall($dll, $retType, $function, $p4, $p5, $p6 = Null, $p7 = Null, $p8 = Null, $p9 = Null, $p10 = Null, $p11 = Null, $p12 = Null, $p13 = Null, $p14 = Null, $p15 = Null, $p16 = Null, $p17 = Null)
	Local $call = StringFormat('DllCall(dll=%s,retType=%s,fun=%s,p4=%s,p5=%s', $dll, $retType, $function, $p4, $p5)
	If $p6 <> Null Then
		$call &= StringFormat(',p6=%s,p7=%s', $p6, $p7)
		If Not IsValidType($p6, $p7) Then DebuggerLog('Error faulty value in call to ' & $call)
		If $p8 <> Null Then
			$call &= StringFormat(',p8=%s,p9=%s', $p8, $p9)
			If Not IsValidType($p8, $p9) Then DebuggerLog('Error faulty value in call to ' & $call)
			If $p10 <> Null Then
				$call &= StringFormat(',p10=%s,p11=%s', $p10, $p11)
				If Not IsValidType($p10, $p11) Then DebuggerLog('Error faulty value in call to ' & $call)
				If $p12 <> Null Then
					$call &= StringFormat(',p12=%s,p13=%s', $p12, $p13)
					If Not IsValidType($p12, $p13) Then DebuggerLog('Error faulty value in call to ' & $call)
					If $p14 <> Null Then
						$call &= StringFormat(',p14=%s,p15=%s', $p14, $p15)
						If Not IsValidType($p14, $p15) Then DebuggerLog('Error faulty value in call to ' & $call)
						If $p16 <> Null Then
							$call &= StringFormat(',p16=%s,p17=%s', $p16, $p17)
							If Not IsValidType($p16, $p17) Then DebuggerLog('Error faulty value in call to ' & $call)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	$call &= ')'

	If $function == 'ReadProcessMemory' Then IsMemoryReadable($p5, $p7, 0)
	If $function == 'WriteProcessMemory' Then IsMemoryWritable($p5, $p7, 0)

	;DebuggerLog('Call to ' & $call)
	;DebuggerLog('Context{' & GetCurrentContext() & '}')
	Local $result
	If $p16 <> Null Then
		If $p17 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
	ElseIf $p14 <> Null Then
		If $p15 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
	ElseIf $p12 <> Null Then
		If $p13 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
	ElseIf $p10 <> Null Then
		If $p11 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
	ElseIf $p8 <> Null Then
		If $p9 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9)
	ElseIf $p6 <> Null Then
		If $p7 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7)
	Else
		If $p5 == Null Then DebuggerLog('Error null value in call to ' & $call)
		$result = DllCall($dll, $retType, $function, $p4, $p5)
	EndIf
	If @error <> 0 Or $result[0] = $FUNCTION_ERROR_CODES[$function] Then
		Local $errorCode = DllCall($dll, 'dword', 'GetLastError')
		DebuggerLog('[ERROR] Code[' & $errorCode[0] & '] on ' & $call)
	EndIf
	Return $result
EndFunc

;~ DllCall wrapper overload for 5 arguments
Func SafeDllCall5($p1, $p2, $p3, $p4, $p5)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5)
EndFunc

;~ DllCall wrapper overload for 7 arguments
Func SafeDllCall7($p1, $p2, $p3, $p4, $p5, $p6, $p7)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7)
EndFunc

;~ DllCall wrapper overload for 9 arguments
Func SafeDllCall9($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
EndFunc

;~ DllCall wrapper overload for 11 arguments
Func SafeDllCall11($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
EndFunc

;~ DllCall wrapper overload for 13 arguments
Func SafeDllCall13($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
EndFunc

;~ DllCall wrapper overload for 15 arguments
Func SafeDllCall15($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
EndFunc

;~ DllCall wrapper overload for 17 arguments
Func SafeDllCall17($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
	If Not $DEBUG_MODE Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
EndFunc


;~ Actively check types before running any DllCalls
Func IsValidType($type, $value)
	Local $typeLower = StringLower($type)
	Switch $typeLower
		Case 'ptr'
			; Accept both decimal and hex
			If IsDllStruct($value) Then
				If @error Or DllStructGetPtr($value) = 0 Then Return False
			EndIf
			If StringRegExp($value, '^(0x)?[0-9A-Fa-f]+$') Then Return True
			If IsNumber($value) Then Return True
			Return False
		Case 'int', 'uint', 'dword', 'long', 'ulong', 'ulong_ptr'
			If StringRegExp($value, '^(0x)?[0-9A-Fa-f]+$') Then Return True
			If IsNumber($value) Then Return True
			Return False
		Case 'str', 'wstr'
			Return IsString($value)
		Case 'byte'
			If IsNumber($value) And $value >= 0 And $value <= 255 Then Return True
			Return False
		Case 'float', 'double'
			Return IsFloat($value) Or IsNumber($value)
		Case 'bool'
			Return ($value = True Or $value = False Or $value = 0 Or $value = 1)
		Case 'handle'
			If Not IsInt($value) Or $value <= 0 Then Return False
		Case Else
			Return False
	EndSwitch
EndFunc


;~ Determine if the provided address is readable by the given process
Func IsMemoryReadable($processHandle, $address, $size)
	Local $memoryInfo = DllStructCreate($MEMORY_INFO_STRUCT_TEMPLATE)
	DllCall($kernel_handle, 'int', 'VirtualQueryEx', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($memoryInfo), 'int', DllStructGetSize($memoryInfo))
	If @error Then
		DebuggerLog('Read - VirtualQueryEx call failed')
		Return False
	EndIf

	; Check that the memory is committed (MEM_COMMIT = 0x1000)
	Local $state = DllStructGetData($memoryInfo, 'State')
	If DllStructGetData($memoryInfo, 'State') <> 0x1000 Then
		DebuggerLog('Read - Memory is not committed - ' & $state)
		Return False
	EndIf

	; Ensure the requested range fits inside the memory region
	Local $regionStart = DllStructGetData($memoryInfo, 'BaseAddress')
	Local $regionSize = DllStructGetData($memoryInfo, 'RegionSize')
	If ($address - $regionStart) + $size > $regionSize Then
		DebuggerLog('Read - Range doesnt fit in the memory region')
		Return False
	EndIf

	; Retrieve the protection flags and filter out the guard bit if present.
	Local $protect = DllStructGetData($memoryInfo, 'Protect')
	If BitAND($protect, 0x100) <> 0 Then
		; The PAGE_GUARD attribute is set – treat the region as non-accessible
		DebuggerLog('Read - Region page is guarded - ' & $protect)
		Return False
	EndIf

	; Remove any extra bits (like PAGE_GUARD) by masking with 0xFF.
	$protect = BitAND($protect, 0xFF)

	; Allowed readable protection values:
	; PAGE_READONLY (0x02), PAGE_READWRITE (0x04), PAGE_WRITECOPY (0x08),
	; PAGE_EXECUTE_READ (0x20), PAGE_EXECUTE_READWRITE (0x40), PAGE_EXECUTE_WRITECOPY (0x80)
	Switch $protect
		Case 0x02, 0x04, 0x08, 0x20, 0x40, 0x80
			Return True
		Case Else
			DebuggerLog('Read - Address is not readable - ' & $protect)
			Return False
	EndSwitch
EndFunc


;~ Determine if the provided address is writable by the given process
Func IsMemoryWritable($processHandle, $address, $size)
	Local $memoryInfo = DllStructCreate($MEMORY_INFO_STRUCT_TEMPLATE)
	DllCall($kernel_handle, 'int', 'VirtualQueryEx', 'int', $processHandle, 'int', $address, 'ptr', DllStructGetPtr($memoryInfo), 'int', DllStructGetSize($memoryInfo))
	If @error Then
		DebuggerLog('Write - VirtualQueryEx call failed')
		Return False
	EndIf

	; Check that the memory is committed (MEM_COMMIT = 0x1000)
	Local $state = DllStructGetData($memoryInfo, 'State')
	If $state <> 0x1000 Then
		DebuggerLog('Write - Memory is not committed - ' & $state)
		Return False
	EndIf

	; Ensure the requested range fits inside the memory region
	Local $regionStart = DllStructGetData($memoryInfo, 'BaseAddress')
	Local $regionSize = DllStructGetData($memoryInfo, 'RegionSize')
	If ($address - $regionStart) + $size > $regionSize Then
		DebuggerLog('Write - Range doesnt fit in the memory region')
		Return False
	EndIf

	; Retrieve the protection flags and filter out the guard bit
	Local $protect = DllStructGetData($memoryInfo, 'Protect')
	If BitAND($protect, 0x100) <> 0 Then
		DebuggerLog('Write - Region page is guarded - ' & $protect)
		Return False
	EndIf

	; Mask to get the base protection (ignore extra bits)
	$protect = BitAND($protect, 0xFF)

	; Allowed writable protection values:
	; PAGE_READWRITE (0x04), PAGE_WRITECOPY (0x08),
	; PAGE_EXECUTE_READWRITE (0x40), PAGE_EXECUTE_WRITECOPY (0x80)
	Switch $protect
		Case 0x04, 0x08, 0x40, 0x80
			Return True
		Case Else
			DebuggerLog('Write - Address is not writable - ' & $protect)
			Return False
	EndSwitch
EndFunc








#CS ===========================================================================
One of these is the cause of the crash
	BOOL ReadProcessMemory(
		HANDLE  hProcess,
		LPCVOID lpBaseAddress,
		LPVOID  lpBuffer,
		SIZE_T  nSize,
		SIZE_T  *lpNumberOfBytesRead
	);
	AutoIt: 'int', 'ReadProcessMemory', 'int', hProcess, 'int', address, 'ptr', buffer, 'int', size, 'int', ''

	BOOL WriteProcessMemory(
		HANDLE  hProcess,
		LPVOID  lpBaseAddress,
		LPCVOID lpBuffer,
		SIZE_T  nSize,
		SIZE_T  *lpNumberOfBytesWritten
	);

	LPVOID VirtualAllocEx(
		HANDLE hProcess,
		LPVOID lpAddress,
		SIZE_T dwSize,
		DWORD  flAllocationType,
		DWORD  flProtect
	);

	SIZE_T VirtualQueryEx(
		HANDLE                    hProcess,
		LPCVOID                   lpAddress,
		PMEMORY_BASIC_INFORMATION lpBuffer,
		SIZE_T                    dwLength
	);

	BOOL SetProcessWorkingSetSize(
		HANDLE hProcess,
		SIZE_T dwMinimumWorkingSetSize,
		SIZE_T dwMaximumWorkingSetSize
	);

	BOOL SetProcessWorkingSetSizeEx(
		HANDLE hProcess,
		SIZE_T dwMinimumWorkingSetSize,
		SIZE_T dwMaximumWorkingSetSize,
		DWORD  Flags
	);


SafeDllCall9($kernel_handle,		'int',	'SetProcessWorkingSetSize',		'int',		GetProcessHandle(),	'int',	-1,												'int',			-1)
SafeDllCall11($kernel_handle,	'int',	'SetProcessWorkingSetSizeEx',	'int',		GetProcessHandle(),	'int',	1,												'int',			$maxMemory,									'int',		6)
SafeDllCall11($kernel_handle,	'int',	'VirtualQueryEx',				'int',		$processHandle,		'int',	$currentSearchAddress,							'ptr',			DllStructGetPtr($mbiBuffer),				'int',		DllStructGetSize($mbiBuffer))

SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$handle,			'int',	$address,										'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'')	;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$address,										'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$address,										'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$buffStructAddress[0],							'ptr',			DllStructGetPtr($buffStruct),				'int',		DllStructGetSize($buffStruct),		'int',		'') ;16
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$buffStructAddress[0],							'ptr',			DllStructGetPtr($buffStruct),				'int',		DllStructGetSize($buffStruct),		'int',		'') ;16
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$buffStructAddress[0],							'ptr',			DllStructGetPtr($buffStruct),				'int',		DllStructGetSize($buffStruct),		'int',		'') ;16
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$currentSearchAddress,							'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$itemPtr[1],									'ptr',			DllStructGetPtr($itemStruct),				'int',		DllStructGetSize($itemStruct),		'int',		'') ;84
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$itemPtr[1],									'ptr',			DllStructGetPtr($itemStruct),				'int',		DllStructGetSize($itemStruct),		'int',		'') ;84
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$itemPtr[1],									'ptr',			DllStructGetPtr($itemStruct),				'int',		DllStructGetSize($itemStruct),		'int',		'') ;84
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$itemPtr[1],									'ptr',			DllStructGetPtr($itemStruct),				'int',		DllStructGetSize($itemStruct),		'int',		'') ;84
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	DllStructGetData($buffer,	1),					'ptr',			DllStructGetPtr($itemStruct),				'int',		DllStructGetSize($itemStruct),		'int',		'') ;84
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		$processHandle,		'int',	$tmpAddress	+	6,								'ptr',			DllStructGetPtr($tmpBuffer),				'int',		DllStructGetSize($tmpBuffer),		'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$agent_copy_base,									'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$agentPtr,										'ptr',			DllStructGetPtr($agentStruct),				'int',		DllStructGetSize($agentStruct),		'int',		'') ;448
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$areaInfoAddress,								'ptr',			DllStructGetPtr($areaInfoStruct),			'int',		DllStructGetSize($areaInfoStruct),	'int',		'') ;124
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$attributeStructAddress,						'ptr',			DllStructGetPtr($attributeStruct),			'int',		DllStructGetSize($attributeStruct),	'int',		'') ;20
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$bagPtr[1],										'ptr',			DllStructGetPtr($bagStruct),				'int',		DllStructGetSize($bagStruct),		'int',		'') ;36

SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$effectStructAddress[0]	+	24	*	$i,			'ptr',			DllStructGetPtr($effectStruct),				'int',		24,									'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$effectStructAddress[1],						'ptr',			DllStructGetPtr($resultArray[$i	+	1]),	'int',		24,									'int',		'') ;
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$itemPtr	+	4	*	($slot	-	1),			'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'') ;

SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$questPtr[0],									'ptr',			DllStructGetPtr($questStruct),				'int',		DllStructGetSize($questStruct),		'int',		'') ;52
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$skillbarStructAddress[0],						'ptr',			DllStructGetPtr($skillbarStruct),			'int',		DllStructGetSize($skillbarStruct),	'int',		'') ;188
SafeDllCall13($kernel_handle,	'int',	'ReadProcessMemory',			'int',		GetProcessHandle(),	'int',	$skillstructAddress,							'ptr',			DllStructGetPtr($skillStruct),				'int',		DllStructGetSize($skillStruct),		'int',		'') ;168

SafeDllCall13($kernel_handle,	'int',	'WriteProcessMemory',			'int',		GetProcessHandle(),	'int',	$address,										'ptr',			$SEND_CHAT_STRUCT_PTR,							'int',		8,									'int',		'')
SafeDllCall13($kernel_handle,	'int',	'WriteProcessMemory',			'int',		GetProcessHandle(),	'int',	$address,										'ptr',			$WRITE_CHAT_STRUCT_PTR,						'int',		4,									'int',		'')
SafeDllCall13($kernel_handle,	'int',	'WriteProcessMemory',			'int',		GetProcessHandle(),	'int',	$address,										'ptr',			DllStructGetPtr($buffer),					'int',		DllStructGetSize($buffer),			'int',		'')
SafeDllCall13($kernel_handle,	'int',	'WriteProcessMemory',			'int',		GetProcessHandle(),	'int',	256	*	$queue_counter	+	$queue_base_address,	'ptr',			$ptr,										'int',		$size,								'int',		'')
SafeDllCall13($kernel_handle,	'int',	'WriteProcessMemory',			'int',		GetProcessHandle(),	'ptr',	$address,										'ptr',			DllStructGetPtr($data),						'int',		DllStructGetSize($data),			'int',		0)
SafeDllCall13($kernel_handle,	'int',	'WriteProcessMemory',			'int',		$processHandle,		'int',	$memoryBuffer[0],								'ptr',			$craftingMaterialStructPtr,					'int',		$memorySize,						'int',		'')

SafeDllCall13($kernel_handle,	'ptr',	'VirtualAllocEx',				'handle',	GetProcessHandle(),	'ptr',	0,												'ulong_ptr',	$asm_injection_size,							'dword',	0x1000,								'dword',	0x40)
SafeDllCall13($kernel_handle,	'ptr',	'VirtualAllocEx',				'handle',	GetProcessHandle(),	'ptr',	0,												'ulong_ptr',	$asm_injection_size,							'dword',	0x1000,								'dword',	64)
SafeDllCall13($kernel_handle,	'ptr',	'VirtualAllocEx',				'handle',	$processHandle,		'ptr',	0,												'ulong_ptr',	$memorySize,								'dword',	0x1000,								'dword',	0x40)

#CE ===========================================================================