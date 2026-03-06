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

Global Const $BUILD_PW_HR_REFRAINS = 'OQCjUamLKTn19Y1YAh0b4ioYsYA'
Global Const $BUILD_PW_HR_ARIAS = 'OQCkUWm4Ziy0ZdPWNGQI9GuoHGHG'
Global Const $BUILD_PW_HR_ADRENALINE = 'OQGkURll5iy0ZdPWNGQI9WM4VBPB'

; Default build
Global Const $BUILD_PW_HEROIC_REFRAIN = 1
Global Const $BUILD_PW_THEYRE_ON_FIRE = 2
Global Const $BUILD_PW_STAND_YOUR_GROUND = 3					; 20s
Global Const $BUILD_PW_THERES_NOTHING_TO_FEAR = 4				; 20s

; Options
;Global Const $BUILD_PW_LEADERS_COMFORT = 5						; not supported
Global Const $BUILD_PW_CANT_TOUCH_THIS = 5						; 20s
Global Const $BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM = 6		; 20s

; Aria build
Global Const $BUILD_PW_ARIA_OF_RESTORATION = 7					; 20s
Global Const $BUILD_PW_BALLAD_OF_RESTORATION = 8				; 20s
Global Const $BUILD_PW_ARIA_OF_ZEAL = 8							; 20s

; Refrain build
;Global Const $BUILD_PW_MENDING_REFRAIN = 7						; not supported
;Global Const $BUILD_PW_HASTY_REFRAIN = 8						; not supported
Global Const $BUILD_PW_BURNING_REFRAIN = 7
Global Const $BUILD_PW_BLADETURN_REFRAIN = 8

; Adrenaline build - not tested
Global Const $BUILD_PW_SAVE_YOURSELVES = 6
;Global Const $BUILD_PW_FOR_GREAT_JUSTICE = 7					; not supported
Global Const $BUILD_PW_AGGRESSIVE_REFRAIN = 8
Global Const $BUILD_PW_NATURAL_TEMPER = 7
Global Const $BUILD_PW_TO_THE_LIMIT = 8

Global $registered_shouts = False

;~ This function should be put on a 11 to 15s adlibregister
Func MaintainHeroicRefrain()
	Local Static $castBladeturnRefrain = GetSkillbarSkillID($BUILD_PW_BLADETURN_REFRAIN) == $ID_BLADETURN_REFRAIN
	Local Static $castBurningRefrain = GetSkillbarSkillID($BUILD_PW_BURNING_REFRAIN) == $ID_BURNING_REFRAIN
	Local Static $castAggressiveRefrain = GetSkillbarSkillID($BUILD_PW_AGGRESSIVE_REFRAIN) == $ID_AGGRESSIVE_REFRAIN

	If GetMapType() <> $ID_EXPLORABLE Then
		AdlibUnRegister('MaintainHeroicRefrain')
		$registered_shouts = False
		Return
	EndIf

	; Maintaining
	UseSkillEx($BUILD_PW_THEYRE_ON_FIRE)
	RandomSleep(20 + GetPing())

	; Not casting refrains if not enough energy to guarantee the next theyre on fire
	Local $energy = GetEnergy()
	If $energy < 10 Then Return

	; Aggressive Refrain check
	If $castAggressiveRefrain And $energy > 15 Then
		If GetEffect($ID_AGGRESSIVE_REFRAIN, 0) == Null Then
			While IsPlayerAlive() And GetEnergy() < 25
				Sleep(1000)
			WEnd
			UseSkillEx($BUILD_PW_AGGRESSIVE_REFRAIN)
			RandomSleep(20 + GetPing())
			Return
		EndIf
	EndIf

	; Recasting HR on character to get max +4 stats
	Local Static $castHRSecondTime = False
	If $castHRSecondTime Then
		UseSkillEx($BUILD_PW_HEROIC_REFRAIN, GetMyAgent())
		RandomSleep(20 + GetPing())
		$castHRSecondTime = False
		Return
	EndIf

	; Checking if our characters have refrains on
	Local $missingRefrain = -1
	Local $missingCharacter = -1
	For $i = 0 To 7
		; Getting all effects is more efficient if we check several effects
		Local $effectsArray = GetEffect(0, $i)

		Local $heroicRefrain = False
		Local $bladeRefrain = $castBladeturnRefrain ? False : True
		Local $burningRefrain = $castBurningRefrain ? False : True
		For $effect In $effectsArray
			Local $effectID = DllStructGetData($effect, 'SkillID')
			If $effectID == $ID_HEROIC_REFRAIN Then
				$heroicRefrain = True
			ElseIf $effectID == $ID_BLADETURN_REFRAIN Then
				$bladeRefrain = True
			ElseIf $effectID == $ID_BURNING_REFRAIN Then
				$burningRefrain = True
			EndIf

			If $heroicRefrain And $bladeRefrain And $burningRefrain Then ExitLoop
		Next

		; Heroic Refrain is priority so it is instantly casted
		If Not $heroicRefrain Then
			$missingRefrain = $BUILD_PW_HEROIC_REFRAIN
			$missingCharacter = $i
			If $i == 0 Then $castHRSecondTime = True
			ExitLoop
		EndIf
		; If we already found a missing refrain no need to check more than HR
		If $missingRefrain <> -1 Then ContinueLoop

		; Other refrains must wait until we are sure we are not missing HR on someone
		If Not $bladeRefrain Then
			$missingRefrain = $BUILD_PW_BLADETURN_REFRAIN
			$missingCharacter = $i
		ElseIf Not $burningRefrain Then
			$missingRefrain = $BUILD_PW_BURNING_REFRAIN
			$missingCharacter = $i
		EndIf
	Next

	Local $target
	If $missingCharacter < 0 Then
		Return
	ElseIf $missingCharacter == 0 Then
		$target = GetMyAgent()
	Else
		$target = GetAgentByID(GetHeroID($missingCharacter))
	EndIf

	UseSkillEx($missingRefrain, $target)
	RandomSleep(20 + GetPing())
EndFunc


Func FightAsPWHeroicRefrain($target, $options = Null)
	Local Static $castBattleStandard = GetSkillbarSkillID($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM) == $ID_EBON_BATTLE_STANDARD_OF_WISDOM
	Local Static $castCantTouchThis = GetSkillbarSkillID($BUILD_PW_CANT_TOUCH_THIS) == $ID_CANT_TOUCH_THIS
	Local Static $castAriaOfRestoration = GetSkillbarSkillID($BUILD_PW_ARIA_OF_RESTORATION) == $ID_ARIA_OF_RESTORATION
	Local Static $castAriaOfZeal = GetSkillbarSkillID($BUILD_PW_ARIA_OF_ZEAL) == $ID_ARIA_OF_ZEAL
	Local Static $castBalladOfRestoration = GetSkillbarSkillID($BUILD_PW_BALLAD_OF_RESTORATION) == $ID_BALLAD_OF_RESTORATION
	Local Static $castSaveYourselves = GetSkillbarSkillID($BUILD_PW_SAVE_YOURSELVES) == $ID_SAVE_YOURSELVES_KURZICK Or GetSkillbarSkillID($BUILD_PW_SAVE_YOURSELVES) == $ID_SAVE_YOURSELVES_LUXON
	Local Static $castNaturalTemper = GetSkillbarSkillID($BUILD_PW_NATURAL_TEMPER) == $ID_NATURAL_TEMPER
	Local Static $castToTheLimit = GetSkillbarSkillID($BUILD_PW_TO_THE_LIMIT) == $ID_TO_THE_LIMIT

	If Not $registered_shouts And GetMapType() == $ID_EXPLORABLE Then
		AdlibRegister('MaintainHeroicRefrain', 12000)
		$registered_shouts = True
	EndIf

	; get as close as possible to target foe to have a surprise effect when attacking
	GetAlmostInRangeOfAgent($target)
	Attack($target)
	Sleep(1500)

	; Timer used for Stand your ground, there is nothing to fear and cant touch this
	Local Static $timer20s = Null

	If $timer20s == Null Or TimerDiff($timer20s) > 20000 Then
		GetIntoTeamRange()
		Local $ping = GetPing()
		UseSkillEx($BUILD_PW_STAND_YOUR_GROUND)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_THERES_NOTHING_TO_FEAR)
		Sleep(20 + $ping)
		If $castBattleStandard And GetEnergy() >= 20 Then
			UseSkillEx($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM)
			Sleep(20 + $ping)
		EndIf
		If $castCantTouchThis Then
			UseSkillEx($BUILD_PW_CANT_TOUCH_THIS)
			Sleep(20 + $ping)
		EndIf
		If $castAriaOfRestoration Then
			UseSkillEx($BUILD_PW_ARIA_OF_RESTORATION)
			Sleep(20 + $ping)
		EndIf
		If $castBalladOfRestoration Then
			UseSkillEx($BUILD_PW_BALLAD_OF_RESTORATION)
			Sleep(20 + $ping)
		EndIf
		If $castAriaOfZeal Then
			UseSkillEx($BUILD_PW_ARIA_OF_ZEAL)
			Sleep(20 + $ping)
		EndIf
		If $castToTheLimit Then
			UseSkillEx($BUILD_PW_TO_THE_LIMIT)
			Sleep(20 + $ping)
		EndIf
		$timer20s = TimerInit()
	EndIf

	If $castSaveYourselves And GetSkillbarSkillAdrenaline($BUILD_PW_SAVE_YOURSELVES) >= 200 Then
		UseSkillEx($BUILD_PW_SAVE_YOURSELVES)
		Sleep(20 + GetPing())
	EndIf

	If $castNaturalTemper And GetSkillbarSkillAdrenaline($BUILD_PW_NATURAL_TEMPER) >= 75 Then
		UseSkillEx($BUILD_PW_NATURAL_TEMPER)
		Sleep(20 + GetPing())
	EndIf
EndFunc