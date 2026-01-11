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
; limitations under the License.d
#CE ===========================================================================

Global Const $LVL_DEBUG = 0
Global Const $LVL_INFO = 1
Global Const $LVL_NOTICE = 2
Global Const $LVL_WARNING = 3
Global Const $LVL_ERROR = 4

Global $log_level = $LVL_INFO

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
		_GUICtrlRichEdit_SetCharColor($GUI_Console, $logColor)
		_GUICtrlRichEdit_AppendText($GUI_Console, @HOUR & ':' & @MIN & ':' & @SEC & ' - ' & $TEXT & @CRLF)
	EndIf
EndFunc
#EndRegion Console