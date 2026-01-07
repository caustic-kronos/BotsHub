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

#include 'GWA2.au3'
#include 'GWA2_ID.au3'
#include 'Utils.au3'

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))

; Common skill to all heroes
Global Const $Mystic_Healing_Skill_Position = 1
; Except for the ranger and the necros
Global Const $Cautery_Signet_Skill_Position = 2
Global Const $Faithful_Intervention_Skill_Position = 8

; BiP Necro
Global Const $BiP_Skill_Position = 7

; Zephyr Ranger - Quickening Zephyr and serpent's quickness must be locked so hero doesn't use them
Global Const $Serpents_Quickness_Skill_Position = 6
Global Const $Quickening_Zephyr_Skill_Position = 7

; Order in which heroes are added to the team
Global Const $Hero_Dervish_1 = 1
Global Const $Hero_Dervish_2 = 2
Global Const $Hero_Dervish_3 = 3
Global Const $Hero_Zephyr_Ranger = 4
Global Const $Hero_BiP_Necro_1 = 5
Global Const $Hero_BiP_Necro_2 = 6
Global Const $Hero_Speed_Paragon = 7

Global Const $ID_necro_mercenary_hero = $ID_Mercenary_Hero_3

Global $Quickening_Zephyr_Cast_Timer

;~ Shouldn't be used - doesn't farm anything
Func OmniFarm($STATUS)
	;If Not($Farm_Setup) Then OmniFarmSetup()

	Info('Preparing the spirit setup')
	PrepareZephyrSpirit()

	HealingLoop()

	Return $SUCCESS
EndFunc

;~ Shouldn't be used
Func HealingLoop()
	While $STATUS == 'RUNNING'
		ManualFarmAutoHealingLoop()
	WEnd
EndFunc


;~ Can be used in other farm bots
Func OmniFarmSetupWithMandatoryHero($ID_Additional_Hero)
	LeaveParty()
	AddHero($ID_Additional_Hero)
	AddHero($ID_Kahmu)
	AddHero($ID_MOX)
	AddHero($ID_Melonni)
	AddHero($ID_Pyre_Fierceshot)
	AddHero($ID_Olias)
	AddHero($ID_necro_mercenary_hero)
EndFunc


;~ Can be used in other farm bots
Func OmniFarmFullSetup()
	LeaveParty()
	AddHero($ID_Melonni)
	AddHero($ID_MOX)
	AddHero($ID_Kahmu)
	AddHero($ID_Pyre_Fierceshot)
	AddHero($ID_Olias)
	AddHero($ID_necro_mercenary_hero)
	AddHero($ID_General_Morgahn)
	DisableHeroSkillSlot($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
	DisableHeroSkillSlot($Hero_Zephyr_Ranger, $Serpents_Quickness_Skill_Position)
EndFunc


;~ Can be used in other farm bots
Func PrepareZephyrSpirit()
	UseHeroSkill($Hero_Zephyr_Ranger, $Faithful_Intervention_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_BiP_Necro_1, $Faithful_Intervention_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_Speed_Paragon, $Faithful_Intervention_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_Dervish_1, $Faithful_Intervention_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_Dervish_2, $Faithful_Intervention_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_Dervish_3, $Faithful_Intervention_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_BiP_Necro_2, $Faithful_Intervention_Skill_Position)
	RandomSleep(2000)
	UseHeroSkill($Hero_BiP_Necro_1, $BiP_Skill_Position, GetHeroID($Hero_Zephyr_Ranger))
	RandomSleep(10)
	UseHeroSkill($Hero_Zephyr_Ranger, $Serpents_Quickness_Skill_Position)
	RandomSleep(10)
	UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
	$Quickening_Zephyr_Cast_Timer = TimerInit()
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
	Local Static $steady_Healing_Healer_Index = 0
	Local Static $healerArray[6] = [$Hero_Dervish_1, $Hero_Dervish_2, $Hero_Dervish_3, $Hero_BiP_Necro_1, $Hero_BiP_Necro_2, $Hero_Speed_Paragon]

	If $adlibBusy Then Return
	$adlibBusy = True

	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 38000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
		$Quickening_Zephyr_Cast_Timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	UseHeroSkill($healerArray[$steady_Healing_Healer_Index], $Mystic_Healing_Skill_Position)
	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 And $steady_Healing_Healer_Index == 5 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
	EndIf

	If GetHasCondition(GetMyAgent()) Then
		Switch $steady_Healing_Healer_Index
			Case 3
				UseHeroSkill($healerArray[2], $Cautery_Signet_Skill_Position)
			Case 4
				UseHeroSkill($healerArray[5], $Cautery_Signet_Skill_Position)
			Case Else
				UseHeroSkill($healerArray[$steady_Healing_Healer_Index], $Cautery_Signet_Skill_Position)
		EndSwitch
	EndIf
	$steady_Healing_Healer_Index += 1
	$steady_Healing_Healer_Index = Mod($steady_Healing_Healer_Index, 6)
	$adlibBusy = False
EndFunc


;~ Can be used in other farm bots - has no latency - can be used at most once every 1600ms
Func TwiceHealingUnit()
	Local Static $adlibBusy = False
	Local Static $steady_Healing_Healer_Index = 0

	If $adlibBusy Then Return
	$adlibBusy = True

	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 38000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
		$Quickening_Zephyr_Cast_Timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	If $steady_Healing_Healer_Index == 0 Then
		UseHeroSkill($Hero_Dervish_1, $Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Dervish_2, $Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_BiP_Necro_1, $Mystic_Healing_Skill_Position)
		$steady_Healing_Healer_Index = 1
	Else
		UseHeroSkill($Hero_Speed_Paragon, $Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Dervish_3, $Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_BiP_Necro_2, $Mystic_Healing_Skill_Position)
		If TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 Then
			UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
		EndIf
		$steady_Healing_Healer_Index = 0
	EndIf

	$adlibBusy = False
EndFunc


;~ Can be used in other farm bots - has no latency - can be used at most once every 5s
Func BurstHealingUnit()
	Local Static $adlibBusy = False
	If $adlibBusy Then Return
	$adlibBusy = True

	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 38000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
		$Quickening_Zephyr_Cast_Timer = TimerInit()
	EndIf

	Local $lifeRatio = DllStructGetData(GetMyAgent(), 'HealthPercent')
	; Heroes with Mystic Healing provide additional long range support
	If $lifeRatio < 1 Then
		UseHeroSkill($Hero_Speed_Paragon, $Mystic_Healing_Skill_Position)
		If $lifeRatio < 0.9 Then
			UseHeroSkill($Hero_BiP_Necro_1, $Mystic_Healing_Skill_Position)
			If $lifeRatio < 0.8 Then
				UseHeroSkill($Hero_BiP_Necro_2, $Mystic_Healing_Skill_Position)
				If $lifeRatio < 0.7 Then
					UseHeroSkill($Hero_Dervish_1, $Mystic_Healing_Skill_Position)
					If $lifeRatio < 0.6 Then
						UseHeroSkill($Hero_Dervish_2, $Mystic_Healing_Skill_Position)
						If $lifeRatio < 0.5 Then
							UseHeroSkill($Hero_Dervish_3, $Mystic_Healing_Skill_Position)
							If $lifeRatio < 0.4 And TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 Then UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
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
	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 38000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
		$Quickening_Zephyr_Cast_Timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	UseHeroSkill($Hero_Speed_Paragon, $Mystic_Healing_Skill_Position)
	RandomSleep(430)
	UseHeroSkill($Hero_Dervish_1, $Mystic_Healing_Skill_Position)
	RandomSleep(430)
	UseHeroSkill($Hero_Dervish_2, $Mystic_Healing_Skill_Position)
	RandomSleep(430)
	UseHeroSkill($Hero_Dervish_3, $Mystic_Healing_Skill_Position)
	RandomSleep(430)
	UseHeroSkill($Hero_BiP_Necro_1, $Mystic_Healing_Skill_Position)
	RandomSleep(430)
	UseHeroSkill($Hero_BiP_Necro_2, $Mystic_Healing_Skill_Position)
	RandomSleep(430)
	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
		RandomSleep(430)
	Else
		RandomSleep(430)
	EndIf
	RandomSleep(70)
EndFunc