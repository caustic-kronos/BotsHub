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

; Default build
Global Const $BUILD_PW_HEROIC_REFRAIN = 1
Global Const $BUILD_PW_THEYRE_ON_FIRE = 2
Global Const $BUILD_PW_STAND_YOUR_GROUND = 3					; 20s
Global Const $BUILD_PW_THERES_NOTHING_TO_FEAR = 4				; 20s

; Options
;Global Const $BUILD_PW_LEADERS_COMFORT = 5
Global Const $BUILD_PW_CANT_TOUCH_THIS = 5						; 20s
Global Const $BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM = 6		; 20s

; Aria build
Global Const $BUILD_PW_ARIA_OF_RESTORATION = 7					; 20s
Global Const $BUILD_PW_ARIA_OF_ZEAL = 8							; 20s
;Global Const $BUILD_PW_BALLAD_OF_RESTORATION = 8				; 20s

; Adrenaline build
;Global Const $BUILD_PW_SAVE_YOURSELVES = 6						; adrenaline
;Global Const $BUILD_PW_FOR_GREAT_JUSTICE = 7					; 45s
;Global Const $BUILD_PW_AGGRESSIVE_REFRAIN = 8

; Refrain build
;Global Const $BUILD_PW_MENDING_REFRAIN = 6
;Global Const $BUILD_PW_HASTY_REFRAIN = 7
;Global Const $BUILD_PW_BLADETURN_REFRAIN = 8

Global $registered_shouts = False

;~ This function should be put on a 11 to 15s adlibregister
Func MaintainHeroicRefrain()
	Local Static $castHRSecondTime = False
	If GetMapType() <> $ID_EXPLORABLE Then
		AdlibUnRegister('MaintainHeroicRefrain')
		$registered_shouts = False
		Return
	EndIf

	If IsRecharged($BUILD_PW_HEROIC_REFRAIN) Then
		For $i = 0 To 7
			If $castHRSecondTime Or GetEffectTimeRemaining(GetEffect($ID_HEROIC_REFRAIN, $i), $i) == 0 Then
				Local $target
				If $i == 0 Then
					$target = GetMyAgent()
					$castHRSecondTime = Not $castHRSecondTime
				Else
					Local $heroID = GetHeroID($i)
					$target = GetAgentByID($heroID)
				EndIf
				UseSkillEx($BUILD_PW_HEROIC_REFRAIN, $target)
				RandomSleep(20 + GetPing())
				ExitLoop
			EndIf
		Next
	EndIf
	UseSkillEx($BUILD_PW_THEYRE_ON_FIRE)
EndFunc


Func FightAsPWHeroicRefrain($target, $options = Null)
	; get as close as possible to target foe to have a surprise effect when attacking
	GetAlmostInRangeOfAgent($target)
	Attack($target)
	Sleep(1000)

	; Timer used for Stand your ground, there is nothing to fear and cant touch this
	Local Static $timer20s = Null

	If Not $registered_shouts And GetMapType() == $ID_EXPLORABLE Then
		AdlibRegister('MaintainHeroicRefrain')
		$registered_shouts = True
	EndIf

	; Aggressive refrain should only be casted once
	;~ If IsDeclared('BUILD_PW_AGGRESSIVE_REFRAIN') And GetEffectTimeRemaining(GetEffect($ID_AGGRESSIVE_REFRAIN, 0), 0) == 0 Then
	;~ 	UseSkillEx($BUILD_PW_AGGRESSIVE_REFRAIN)
	;~ 	RandomSleep(250)
	;~ EndIf

	If $timer20s == Null Or TimerDiff($timer20s) > 20000 Then
		MoveToMiddleOfPartyWithTimeout(5000)
		Local $ping = GetPing()
		UseSkillEx($BUILD_PW_STAND_YOUR_GROUND)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_THERES_NOTHING_TO_FEAR)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_CANT_TOUCH_THIS)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_ARIA_OF_RESTORATION)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_ARIA_OF_ZEAL)
		Sleep(20 + $ping)
		$timer20s = TimerInit()
	EndIf

	;~ If IsDeclared('BUILD_PW_SAVE_YOURSELVES') And GetSkillbarSkillAdrenaline($BUILD_PW_SAVE_YOURSELVES) >= 200 Then
	;~ 	UseSkillEx($BUILD_PW_SAVE_YOURSELVES)
	;~ EndIf
EndFunc