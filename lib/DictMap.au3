#CS ===========================================================================
; Replacement for Scripting.Dictionary — native AutoIt maps.
; Works on Windows and Wine/Linux (no COM; maps are passed by reference).
#CE ===========================================================================

#include-once


;~ Create a dictionary-like map passed by reference to functions
Func CreateDictMap()
	Local $map[]
	Return $map
EndFunc


;~ Add a key/value pair (init only — same usage as Scripting.Dictionary.Add)
Func DictAdd(ByRef $dict, $key, $value)
	$dict[$key] = $value
EndFunc


;~ Get or set a dictionary item (replaces .Item('key') and .Item('key') = value)
Func DictItem(ByRef $dict, $key, $value = Default)
	If $value = Default Then
		Return $dict[$key]
	EndIf
	$dict[$key] = $value
EndFunc


;~ Clone a dictionary map
Func CloneDictMap($original)
	Local $clone[]
	For $key In MapKeys($original)
		$clone[$key] = $original[$key]
	Next
	Return $clone
EndFunc
