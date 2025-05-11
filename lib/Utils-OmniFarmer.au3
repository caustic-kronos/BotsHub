; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include-once

#include 'GWA2.au3'
#include 'GWA2_ID.au3'
#include 'Utils.au3'

; ==== Constantes ====
Global Const $FarmerSkillbar = ''
Global Const $FarmInformations = ''

Global $Farm_Setup = False

Global $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Global Const $Skill_ = 0

; Common skill to all heroes
Global Const $Mystic_Healing_Skill_Position = 1
Global Const $Faithful_Intervention_Skill_Position = 8

; BiP Necro
Global Const $BiP_Skill_Position = 7

; Zephyr Ranger - Quickening Zephyr and serpent's quickness must be locked so hero doesn't use them
Global Const $Serpents_Quickness_Skill_Position = 6
Global Const $Quickening_Zephyr_Skill_Position = 7

Global $Quickening_Zephyr_Cast_Timer

; Order heros are added to the team
Global Const $Hero_Dervish_1 = 1
Global Const $Hero_Dervish_2 = 2
Global Const $Hero_Dervish_3 = 3
Global Const $Hero_Zephyr_Ranger = 4
Global Const $Hero_BiP_Necro_1 = 5
Global Const $Hero_BiP_Necro_2 = 6
Global Const $Hero_Speed_Paragon = 7

Global Const $ID_necro_mercenary_hero = $ID_Mercenary_Hero_3


;~ Shouldn't be used - doesn't farm anything
Func OmniFarm($STATUS)
	;If Not($Farm_Setup) Then OmniFarmSetup()

	Out('Preparing the spirit setup')
	PrepareZephyrSpirit()

	If $STATUS <> 'RUNNING' Then Return 2

	HealingLoop()

	Return 0
EndFunc

;~ Shouldn't be used
Func HealingLoop()
	While $STATUS == 'RUNNING'
		;RndSleep(5000)
		;HealingUnit()
		HealingUnitAutoLoop()
	WEnd
EndFunc


;~ Can be used in other farm bots
Func OmniFarmSetupWithMandatoryHero($ID_Additional_Hero)
	LeaveGroup()

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
	LeaveGroup()

	AddHero($ID_General_Morgahn)
	AddHero($ID_Kahmu)
	AddHero($ID_MOX)
	AddHero($ID_Melonni)
	AddHero($ID_Pyre_Fierceshot)
	AddHero($ID_Olias)
	AddHero($ID_necro_mercenary_hero)
EndFunc


;~ Can be used in other farm bots
Func PrepareZephyrSpirit()
	UseHeroSkill($Hero_Speed_Paragon, $Faithful_Intervention_Skill_Position)
	RndSleep(10)
	UseHeroSkill($Hero_Dervish_1, $Faithful_Intervention_Skill_Position)
	RndSleep(10)
	UseHeroSkill($Hero_Dervish_2, $Faithful_Intervention_Skill_Position)
	RndSleep(10)
	UseHeroSkill($Hero_Dervish_3, $Faithful_Intervention_Skill_Position)
	RndSleep(10)
	UseHeroSkill($Hero_BiP_Necro_1, $Faithful_Intervention_Skill_Position)
	RndSleep(10)
	UseHeroSkill($Hero_BiP_Necro_2, $Faithful_Intervention_Skill_Position)
	RndSleep(10)
	UseHeroSkill($Hero_Zephyr_Ranger, $Faithful_Intervention_Skill_Position)
	RndSleep(1000)
	UseHeroSkill($Hero_BiP_Necro_1, $BiP_Skill_Position, GetHeroID($Hero_Zephyr_Ranger))
	RndSleep(1500)
	UseHeroSkill($Hero_Zephyr_Ranger, $Serpents_Quickness_Skill_Position)
	RndSleep(1000)
	UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
	$Quickening_Zephyr_Cast_Timer = TimerInit()
	RndSleep(7500)
EndFunc


;~ Can be used in other farm bots - has no latency - can be used at most once every 5s
Func HealingUnit()
	If GetSkillbarSkillRecharge($Quickening_Zephyr_Skill_Position, $Hero_Zephyr_Ranger) == 0 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
		$Quickening_Zephyr_Cast_Timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	UseHeroSkill($Hero_Speed_Paragon, $Mystic_Healing_Skill_Position)
	UseHeroSkill($Hero_Dervish_1, $Mystic_Healing_Skill_Position)
	UseHeroSkill($Hero_Dervish_2, $Mystic_Healing_Skill_Position)
	UseHeroSkill($Hero_Dervish_3, $Mystic_Healing_Skill_Position)
	UseHeroSkill($Hero_BiP_Necro_1, $Mystic_Healing_Skill_Position)
	UseHeroSkill($Hero_BiP_Necro_2, $Mystic_Healing_Skill_Position)
	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
	EndIf
EndFunc


;~ Shouldn't be used in other farm bots - made to run continuously, so has strong latency (about 5s)
Func HealingUnitAutoLoop()
	If GetSkillbarSkillRecharge($Quickening_Zephyr_Skill_Position, $Hero_Zephyr_Ranger) == 0 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
		$Quickening_Zephyr_Cast_Timer = TimerInit()
	EndIf

	; Heroes with Mystic Healing provide additional long range support
	UseHeroSkill($Hero_Speed_Paragon, $Mystic_Healing_Skill_Position)
	RndSleep(430)
	UseHeroSkill($Hero_Dervish_1, $Mystic_Healing_Skill_Position)
	RndSleep(430)
	UseHeroSkill($Hero_Dervish_2, $Mystic_Healing_Skill_Position)
	RndSleep(430)
	UseHeroSkill($Hero_Dervish_3, $Mystic_Healing_Skill_Position)
	RndSleep(430)
	UseHeroSkill($Hero_BiP_Necro_1, $Mystic_Healing_Skill_Position)
	RndSleep(430)
	UseHeroSkill($Hero_BiP_Necro_2, $Mystic_Healing_Skill_Position)
	RndSleep(430)
	If TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 Then
		UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
		RndSleep(430)
	Else
		RndSleep(430)
	EndIf
	RndSleep(70)
EndFunc