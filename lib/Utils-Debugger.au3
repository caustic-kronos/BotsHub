; AutoIt Wrapper and Logging Framework for Memory Operations
; Use to debug GW crashes when using bot
; Main operations that can cause crash
; DllStructCreate
; DllCall
;
; Other operations that can also create crashes :
; DllStructGetData
; DllStructSetData
;
; This file offers wrapper alternatives to those operations that log the calls and potentially the errors
; This can then be used in conjunction with the crash log to see which call created the crash

Global Const $debugMode = True
Global $logHandle
Global $ContextStack[100]
Global $ContextDepth = 0

;~ Opens log file
Func OpenDebugLogFile()
	If Not $debugMode Then Return
	Local $logFile = @ScriptDir & '/logs/dll_debug-' & GetCharacterName() & '.log'
	$logHandle = FileOpen($logFile, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	If $logHandle = -1 Then
		MsgBox(16, 'Error', 'Failed to open log file: ' & $logFile)
		Exit
	EndIf
	OnAutoItExitRegister('CloseLogFile')
	DebuggerLog('[STARTING UP DEBUGGER]')
EndFunc

;~ Closes log file
Func CloseLogFile()
	DebuggerLog('[CLOSING DEBUGGER]')
	If $logHandle <> -1 Then FileClose($logHandle)
EndFunc

;~ Log critical error in a OneShot way - only use for very specific usage
Func LogCriticalError($log)
	Local $logFile = @ScriptDir & '/logs/dll_debug-' & GetCharacterName() & '.log'
	$logHandle = FileOpen($logFile, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	DebuggerLog($log)
	FileClose($logHandle)
EndFunc

;~ Write log in log file
Func DebuggerLog($msg)
	FileWriteLine($logHandle, '[' & @YEAR & '-' & @MON & '-' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @MSEC & '] - ' & $msg)
EndFunc

;~ Add context to create a simili stack trace
Func PushContext($label)
	If Not $debugMode Then Return
	$ContextStack[$ContextDepth] = $label
	$ContextDepth += 1
EndFunc

;~ Pop last element from stack trace
Func PopContext()
	If Not $debugMode Then Return
	$ContextDepth -= 1
	$ContextStack[$ContextDepth] = ''
EndFunc

;~ Get current context
Func GetCurrentContext()
	Local $joined = ''
	For $i = 0 To $ContextDepth - 1
		$joined &= $i & '-' & $ContextStack[$i] & ' | '
	Next
	Return $joined
EndFunc

; === Wrapper Functions ===
;~ DllStructCreate wrapper
Func SafeDllStructCreate($type, $ptr = -1)
	If Not $debugMode Then Return $ptr <> -1 ? DllStructCreate($type, $ptr) : DllStructCreate($type)
	Local $call = 'DllStructCreate(type=' & $type & ',ptr=' & $ptr & ')'
	;DebuggerLog('Call to ' & $call)
	;DebuggerLog('Context{' & GetCurrentContext() & '}')
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
	If Not $debugMode Then Return DllStructGetData($struct, $element)
	Local $call = 'DllStructGetData(struct=' & $struct & ',element=' & $element & ')'
	;DebuggerLog('Call to ' & $call)
	;DebuggerLog('Context{' & GetCurrentContext() & '}')
	If Not IsDllStruct($struct) Then
		DebuggerLog('[ERROR] Invalid DllStruct passed to ' & $call)
	EndIf
	Local $data = DllStructGetData($struct, $element)
	If @error Then DebuggerLog('[ERROR] Failure on ' & $call)
	Return $data
EndFunc

;~ DllCall wrapper
Func SafeDllCall($dll, $retType, $function, $p4, $p5, $p6 = Null, $p7 = Null, $p8 = Null, $p9 = Null, $p10 = Null, $p11 = Null, $p12 = Null, $p13 = Null, $p14 = Null, $p15 = Null, $p16 = Null, $p17 = Null)
	Local $call = StringFormat('DllCall(dll=%s,retType=%s,fun=%s,p4=%s,p5=%s', $dll, $retType, $function, $p4, $p5)
	If $p6 <> Null Then
		$call &= StringFormat(',p6=%s,p7=%s', $p6, $p7)
		If $p8 <> Null Then
			$call &= StringFormat(',p8=%s,p9=%s', $p8, $p9)
			If $p10 <> Null Then
				$call &= StringFormat(',p10=%s,p11=%s', $p10, $p11)
				If $p12 <> Null Then
					$call &= StringFormat(',p12=%s,p13=%s', $p12, $p13)
					If $p14 <> Null Then
						$call &= StringFormat(',p14=%s,p15=%s', $p14, $p15)
						If $p16 <> Null Then
							$call &= StringFormat(',p16=%s,p17=%s', $p16, $p17)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	$call &= ')'

	;DebuggerLog('Call to ' & $call)
	;DebuggerLog('Context{' & GetCurrentContext() & '}')
	Local $result
	If $p16 <> Null Then
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
	ElseIf $p14 <> Null Then
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
	ElseIf $p12 <> Null Then
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
	ElseIf $p10 <> Null Then
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
	ElseIf $p8 <> Null Then
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7, $p8, $p9)
	ElseIf $p6 <> Null Then
		$result = DllCall($dll, $retType, $function, $p4, $p5, $p6, $p7)
	Else
		$result = DllCall($dll, $retType, $function, $p4, $p5)
	EndIf

	If @error Then DebuggerLog('[ERROR] Failure on ' & $call)
	Return $result
EndFunc

;~ DllCall wrapper overload for 5 arguments
Func SafeDllCall5($p1, $p2, $p3, $p4, $p5)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5)
EndFunc

;~ DllCall wrapper overload for 7 arguments
Func SafeDllCall7($p1, $p2, $p3, $p4, $p5, $p6, $p7)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7)
EndFunc

;~ DllCall wrapper overload for 9 arguments
Func SafeDllCall9($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
EndFunc

;~ DllCall wrapper overload for 11 arguments
Func SafeDllCall11($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11)
EndFunc

;~ DllCall wrapper overload for 13 arguments
Func SafeDllCall13($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13)
EndFunc

;~ DllCall wrapper overload for 15 arguments
Func SafeDllCall15($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15)
EndFunc

;~ DllCall wrapper overload for 17 arguments
Func SafeDllCall17($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
	If Not $debugMode Then Return DllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
	Return SafeDllCall($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10, $p11, $p12, $p13, $p14, $p15, $p16, $p17)
EndFunc