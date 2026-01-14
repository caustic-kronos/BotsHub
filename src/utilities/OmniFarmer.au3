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
; limitations under the License.
#CE ===========================================================================

#include-once
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; Skill numbers declared to make the code WAY more readable (UseSkill($SKILL_CONVICTION is better than UseSkill(1))

; Common skill to all heroes
Global Const $MYSTIC_HEALING_SKILL_POSITION = 1
; Except for the ranger and the necros
Global Const $CAUTERY_SIGNET_SKILL_POSITION = 2
Global Const $FAITHFUL_INTERVENTION_SKILL_POSITION = 8

; BiP Necro
Global Const $BIP_SKILL_POSITION = 7

; Zephyr Ranger - Quickening Zephyr and serpent's quickness must be locked so hero doesn't use them
Global Const $SERPENTS_QUICKNESS_SKILL_POSITION = 6
Global Const $QUICKENING_ZEPHYR_SKILL_POSITION = 7

; Order in which heroes are added to the team
Global Const $HERO_DERVISH_1 = 1
Global Const $HERO_DERVISH_2 = 2
Global Const $HERO_DERVISH_3 = 3
Global Const $HERO_ZEPHYR_RANGER = 4
Global Const $HERO_BIP_NECRO_1 = 5
Global Const $HERO_BIP_NECRO_2 = 6
Global Const $HERO_SPEED_PARAGON = 7

Global Const $ID_NECRO_MERCENARY_HERO = $ID_MERCENARY_HERO_3

Global $quickening_zephyr_cast_timer

;~ Shouldn't be used - doesn't farm anything
Func OmniFarm()
	;If Not($Farm_Setup) Then OmniFarmSetup()

	Info('Preparing the spirit setup')
	PrepareZephyrSpirit()

	HealingLoop()

	Return $SUCCESS
EndFunc

;~ Shouldn't be used
Func HealingLoop()
	While $runtime_status == 'RUNNING'
		ManualFarmAutoHealingLoop()
	WEnd
EndFunc


;~ Can be used in other farm bots
Func OmniFarmSetupWithMandatoryHero($ID_Additional_Hero)
	LeaveParty()
	AddHero($ID_Additional_Hero)
	AddHero($ID_KAHMU)
	AddHero($ID_MOX)
	AddHero($ID_MELONNI)
	AddHero($ID_PYRE_FIERCESHOT)
	AddHero($ID_OLIAS)
	AddHero($ID_NECRO_MERCENARY_HERO)
EndFunc


;~ Can be used in other farm bots
Func OmniFarmFullSetup()
	LeaveParty()
	AddHero($ID_MELONNI)
	AddHero($ID_MOX)
	AddHero($ID_KAHMU)
	AddHero($ID_PYRE_FIERCESHOT)
	AddHero($ID_OLIAS)
	AddHero($ID_NECRO_MERCENARY_HERO)
	AddHero($ID_GENERAL_MORGAHN)
	DisableHeroSkillSlot($HERO_ZEPHYR_RANGER, $QUICKENING_ZEPHYR_SKILL_POSITION)
	DisableHeroSkillSlot($HERO_ZEPHYR_RANGER, $SERPENTS_QUICKNESS_SKILL_POSITION)
EndFunc


;~ Can be used in other farm bots
Func PrepareZephyrSpirit()
	UseHeroSkill($HERO_ZEPHYR_RANGER, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_BIP_NECRO_1, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_SPEED_PARAGON, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_DERVISH_1, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_DERVISH_2, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_DERVISH_3, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_BIP_NECRO_2, $FAITHFUL_INTERVENTION_SKILL_POSITION)
	RandomSleep(2000)
	UseHeroSkill($HERO_BIP_NECRO_1, $BIP_SKILL_POSITION, GetHeroID($HERO_ZEPHYR_RANGER))
	RandomSleep(50)
	UseHeroSkill($HERO_ZEPHYR_RANGER, $SERPENTS_QUICKNESS_SKILL_POSITION)
	RandomSleep(50)
	UseHeroSkill($HERO_ZEPHYR_RANGER, $QUICKENING_ZEPHYR_SKILL_POSITION)
	$quickening_zephyr_cast_timer = TimerInit()
	RandomSleep(5500)
EndFunc


;~ Runs healing every 3100ms - burst heal every 3100ms, might be too slow
Func RegisterBurstHealingUnit()
	AdlibRegister('BurstHealingUnit', 3100)
EndFunc

;~ Unregister after previous function
Func UnregisterBurstHealingUnit()
	AdlibUnRegister('BurstHealingUnit')
EndFunc


;~ Runs healing every 1600ms - seems fine
Func RegisterTwiceHealingUnit()
	AdlibRegister('TwiceHealingUnit', 1600)
EndFunc

;~ Unregister after previous function
Func UnregisterTwiceHealingUnit()
	AdlibUnRegister('TwiceHealingUnit')
EndFunc


;~ Runs healing every 600ms - seems a bit too intensive, creates strain and issues in bots
Func RegisterSteadyHealingUnit()
	AdlibRegister('SteadyHealingUnit', 600)
EndFunc

;~ Unregister after previous function
Func UnregisterSteadyHealingUnit()
	AdlibUnRegister('SteadyHealingUnit')
EndFunc


;~ Can be used in other farm bots, might be too intensive (it needs to be called every 600ms)
Func SteadyHealingUnit()
	Local Static $adlibBusy = False
	Local Static $steadyHealingHealerIndex = 0
	Local Static $healerArray[6] = [$HERO_DERVISH_1, $HERO_DERVISH_2, $HERO_DERVISH_3, $HERO_BIP_NECRO_1, $HERO_BIP_NECRO_2, $HERO_SPEED_PARAGON]

	If $adlibBusy Then Return
	$adlibBusy = True

	If TimerDiff($quickening_zephyr_cast_timer) > 38000 Then
		UseHeroSkill($HERO_ZEPHYR_RANGER, $QUICKENING_ZEPHYR_SKILL_POSITION)
		$quickening_zephyr_cast_timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	UseHeroSkill($healerArray[$steadyHealingHealerIndex], $MYSTIC_HEALING_SKILL_POSITION)
	If TimerDiff($quickening_zephyr_cast_timer) > 6000 And $steadyHealingHealerIndex == 5 Then
		UseHeroSkill($HERO_ZEPHYR_RANGER, $MYSTIC_HEALING_SKILL_POSITION)
	EndIf

	If GetHasCondition(GetMyAgent()) Then
		Switch $steadyHealingHealerIndex
			Case 3
				UseHeroSkill($healerArray[2], $CAUTERY_SIGNET_SKILL_POSITION)
			Case 4
				UseHeroSkill($healerArray[5], $CAUTERY_SIGNET_SKILL_POSITION)
			Case Else
				UseHeroSkill($healerArray[$steadyHealingHealerIndex], $CAUTERY_SIGNET_SKILL_POSITION)
		EndSwitch
	EndIf
	$steadyHealingHealerIndex += 1
	$steadyHealingHealerIndex = Mod($steadyHealingHealerIndex, 6)
	$adlibBusy = False
EndFunc


;~ Can be used in other farm bots - has no latency - can be used at most once every 1600ms
Func TwiceHealingUnit()
	Local Static $adlibBusy = False
	Local Static $steadyHealingHealerIndex = 0

	If $adlibBusy Then Return
	$adlibBusy = True

	If TimerDiff($quickening_zephyr_cast_timer) > 38000 Then
		UseHeroSkill($HERO_ZEPHYR_RANGER, $QUICKENING_ZEPHYR_SKILL_POSITION)
		$quickening_zephyr_cast_timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	If $steadyHealingHealerIndex == 0 Then
		UseHeroSkill($HERO_DERVISH_1, $MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_DERVISH_2, $MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_BIP_NECRO_1, $MYSTIC_HEALING_SKILL_POSITION)
		$steadyHealingHealerIndex = 1
	Else
		UseHeroSkill($HERO_SPEED_PARAGON, $MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_DERVISH_3, $MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_BIP_NECRO_2, $MYSTIC_HEALING_SKILL_POSITION)
		If TimerDiff($quickening_zephyr_cast_timer) > 6000 Then
			UseHeroSkill($HERO_ZEPHYR_RANGER, $MYSTIC_HEALING_SKILL_POSITION)
		EndIf
		$steadyHealingHealerIndex = 0
	EndIf

	$adlibBusy = False
EndFunc


;~ Can be used in other farm bots - has no latency - can be used at most once every 5s
Func BurstHealingUnit()
	Local Static $adlibBusy = False
	If $adlibBusy Then Return
	$adlibBusy = True

	If TimerDiff($quickening_zephyr_cast_timer) > 38000 Then
		UseHeroSkill($HERO_ZEPHYR_RANGER, $QUICKENING_ZEPHYR_SKILL_POSITION)
		$quickening_zephyr_cast_timer = TimerInit()
	EndIf

	Local $lifeRatio = DllStructGetData(GetMyAgent(), 'HealthPercent')
	; Heroes with Mystic Healing provide additional long range support
	If $lifeRatio < 1 Then
		UseHeroSkill($HERO_SPEED_PARAGON, $MYSTIC_HEALING_SKILL_POSITION)
		If $lifeRatio < 0.9 Then
			UseHeroSkill($HERO_BIP_NECRO_1, $MYSTIC_HEALING_SKILL_POSITION)
			If $lifeRatio < 0.8 Then
				UseHeroSkill($HERO_BIP_NECRO_2, $MYSTIC_HEALING_SKILL_POSITION)
				If $lifeRatio < 0.7 Then
					UseHeroSkill($HERO_DERVISH_1, $MYSTIC_HEALING_SKILL_POSITION)
					If $lifeRatio < 0.6 Then
						UseHeroSkill($HERO_DERVISH_2, $MYSTIC_HEALING_SKILL_POSITION)
						If $lifeRatio < 0.5 Then
							UseHeroSkill($HERO_DERVISH_3, $MYSTIC_HEALING_SKILL_POSITION)
							If $lifeRatio < 0.4 And TimerDiff($quickening_zephyr_cast_timer) > 6000 Then UseHeroSkill($HERO_ZEPHYR_RANGER, $MYSTIC_HEALING_SKILL_POSITION)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	$adlibBusy = False
EndFunc


;~ Shouldn't be used in other farm bots - made to run continuously, so has strong latency (about 5s)
Func ManualFarmAutoHealingLoop()
	If TimerDiff($quickening_zephyr_cast_timer) > 38000 Then
		UseHeroSkill($HERO_ZEPHYR_RANGER, $QUICKENING_ZEPHYR_SKILL_POSITION)
		$quickening_zephyr_cast_timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	UseHeroSkill($HERO_SPEED_PARAGON, $MYSTIC_HEALING_SKILL_POSITION)
	RandomSleep(430)
	UseHeroSkill($HERO_DERVISH_1, $MYSTIC_HEALING_SKILL_POSITION)
	RandomSleep(430)
	UseHeroSkill($HERO_DERVISH_2, $MYSTIC_HEALING_SKILL_POSITION)
	RandomSleep(430)
	UseHeroSkill($HERO_DERVISH_3, $MYSTIC_HEALING_SKILL_POSITION)
	RandomSleep(430)
	UseHeroSkill($HERO_BIP_NECRO_1, $MYSTIC_HEALING_SKILL_POSITION)
	RandomSleep(430)
	UseHeroSkill($HERO_BIP_NECRO_2, $MYSTIC_HEALING_SKILL_POSITION)
	RandomSleep(430)
	If TimerDiff($quickening_zephyr_cast_timer) > 6000 Then
		UseHeroSkill($HERO_ZEPHYR_RANGER, $MYSTIC_HEALING_SKILL_POSITION)
		RandomSleep(430)
	Else
		RandomSleep(430)
	EndIf
	RandomSleep(70)
EndFunc