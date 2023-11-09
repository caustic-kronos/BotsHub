#include-once

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"

; ==== Constantes ====
Local Const $FarmerSkillbar = ""
Local Const $FarmInformations = ""

Local $Farm_Setup = False

Local $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Local Const $Skill_ = 0

; Common skill to all heroes
Local Const $Mystic_Healing_Skill_Position = 1
Local Const $Faithful_Intervention_Skill_Position = 8

; Zephyr Ranger - Quickening Zephyr must be locked so hero doesn't use it
Local Const $Serpents_Quickness_Skill_Position = 6
Local Const $Quickening_Zephyr_Skill_Position = 7

; Order heros are added to the team
Local Const $Hero_Speed_Paragon = 1
Local Const $Hero_Dervish_1 = 2
Local Const $Hero_Dervish_2 = 3
Local Const $Hero_Dervish_3 = 4
Local Const $Hero_Zephyr_Ranger = 5
Local Const $Hero_BiP_Necro_1 = 6
Local Const $Hero_BiP_Necro_2 = 7

Local Const $ID_necro_mercenary_hero = $ID_Mercenary_Hero_3


Func OmniFarm($STATUS)
	;If Not($Farm_Setup) Then OmniFarmSetup()

	If $STATUS <> "RUNNING" Then Return

	If CountSlots() < 5 Then
		Out("Inventory full, pausing.")
		Return 2
	EndIf

	If $STATUS <> "RUNNING" Then Return

	Out("Preparing the spirit setup")
	PrepareZephyrSpirit()

	If $STATUS <> "RUNNING" Then Return

	HealingLoop()

	Return 0
EndFunc


Func OmniFarmSetup()
	LeaveGroup()

	AddHero($ID_General_Morgahn)
	AddHero($ID_Kahmu)
	AddHero($ID_MOX)
	AddHero($ID_Melonni)
	AddHero($ID_Pyre_Fierceshot)
	AddHero($ID_Olias)
	AddHero($ID_necro_mercenary_hero)

	SwitchMode($ID_HARD_MODE)
EndFunc


Func PrepareZephyrSpirit()
	UseHeroSkill($Hero_Speed_Paragon, $Faithful_Intervention_Skill_Position)
	UseHeroSkill($Hero_Dervish_1, $Faithful_Intervention_Skill_Position)
	UseHeroSkill($Hero_Dervish_2, $Faithful_Intervention_Skill_Position)
	UseHeroSkill($Hero_Dervish_3, $Faithful_Intervention_Skill_Position)
	UseHeroSkill($Hero_BiP_Necro_1, $Faithful_Intervention_Skill_Position)
	UseHeroSkill($Hero_BiP_Necro_2, $Faithful_Intervention_Skill_Position)
	UseHeroSkill($Hero_Zephyr_Ranger, $Faithful_Intervention_Skill_Position)
	RndSleep(2500)
	UseHeroSkill($Hero_Zephyr_Ranger, $Serpents_Quickness_Skill_Position)
	RndSleep(1000)
	UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
	RndSleep(7500)
EndFunc


Func HealingLoop()
	Local $Quickening_Zephyr_Cast_Timer = TimerInit()
	While True
		If GetSkillbarSkillRecharge($Quickening_Zephyr_Skill_Position, $Hero_Zephyr_Ranger) == 0 Then 
			UseHeroSkill($Hero_Zephyr_Ranger, $Quickening_Zephyr_Skill_Position)
			$Quickening_Zephyr_Cast_Timer = TimerInit()
		EndIf
		
		; Heroes with Mystic Healing provide additional long range support
		UseHeroSkill($Hero_Speed_Paragon, $Mystic_Healing_Skill_Position)
		RndSleep(300)
		UseHeroSkill($Hero_Dervish_1, $Mystic_Healing_Skill_Position)
		RndSleep(300)
		UseHeroSkill($Hero_Dervish_2, $Mystic_Healing_Skill_Position)
		RndSleep(300)
		UseHeroSkill($Hero_Dervish_3, $Mystic_Healing_Skill_Position)
		RndSleep(300)
		UseHeroSkill($Hero_BiP_Necro_1, $Mystic_Healing_Skill_Position)
		RndSleep(300)
		UseHeroSkill($Hero_BiP_Necro_2, $Mystic_Healing_Skill_Position)
		RndSleep(300)
		If TimerDiff($Quickening_Zephyr_Cast_Timer) > 6000 Then
			UseHeroSkill($Hero_Zephyr_Ranger, $Mystic_Healing_Skill_Position)
		EndIf
		RndSleep(300)
	WEnd
EndFunc