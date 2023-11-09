#include-once

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"
#include <File.au3>

; ==== Constantes ====
Local Const $SpiritSlaves_Skillbar = "OgCjkOrMLTmXfXfbkXcX0k5iibA"
Local Const $SpiritSlavesFarmInformations = "For best results, have :" & @CRLF _
	& "- 16 Earth Prayers" &@CRLF _
	& "- 13 Mysticism" & @CRLF _
	& "- 4 Scythe Mastery" & @CRLF _
	& "- Windwalker insignias"& @CRLF _
	& "- A scythe of enchanting q4 or less with the inscription 'I have the power' (+5 energy)" & @CRLF _
	& "- any PCons you wish to use"

Local $SpiritSlaves_Farm_Setup = False

Local $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Local Const $Skill_Sand_Shards = 1
Local Const $Skill_Mystic_Vigor  = 2
Local Const $Skill_Vow_of_Strength = 3
Local Const $Skill_Extend_Enchantments = 4
Local Const $Skill_Mirage_Cloak = 5
Local Const $Skill_I_am_unstoppable = 6
Local Const $Skill_Ebon_Battle_Standard_of_Honor = 7
Local Const $Skill_Heart_of_Fury = 8

#CS
Character location : 	X: , Y: 
-14520, 6009
-14620, 3500

-check Joko's Domain

-12657.97, 2609.43
Take wurm spoor at : 
-10938.24, 4254.83

-8255.75, 5320.06
(starting here use speed if needed)
-8624.96, 10636.63
-8261.47, 12808.57
-4422.35, 19422.67
-4522.72, 20622.68
(zoning)
-9557.11, -10798.98 (go back fast to avoid mobs)
-7416.00, -7822.87 (wait here for ball)
Mobs around -8598.36, -5810.52
Go and kill

-7606.49, -8441.14 (aggro)
-7929.09, -7803.91 (pull, wait)
	(-8219.03, -8150.75 alternative)
				   (target furthest ennemy and kill there)
				   
(repeat)

Then repeat the first, twice :
-7416.00, -7822.87 (wait here for ball)
Mobs around -8598.36, -5810.52
Go and kill


-8056.33, -9293.79
-10656.11, -11293.24
(zoning)
-4522.72, 20622.68

<repeat>



Killing sequence : 
Get close (but don't aggro)
Sand Shards
Wait for mana 3s
Mystic Vigor
Wait for mana 1.5s
Vow of Strength
Run towards mobs
Extends Enchantments
(small wait)
Mirage Cloak
IAU
EBSH (Once Melee)
(Heart of Fury as soon as available)
Attack twice
Sand Shards

#CE

Func SpiritSlavesFarm($STATUS)
	$loggingFile = FileOpen("spiritslaves_farm.log" , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	If CountSlots() < 5 Then
		Out("Inventory full, pausing.")
		Return 2
	EndIf
	
	If $STATUS <> "RUNNING" Then Return
	
	If Not($SpiritSlaves_Farm_Setup) Then SpiritSlavesFarmSetup()
	If (IsFail()) Then Return ResignAndReturnToOutpost()

	If $STATUS <> "RUNNING" Then Return

	Out("Starting a new farm")
	Patati()

	Out("Picking up loot")
	PickUpItems()

	RndSleep(1000)
	
	Out ("Moving out of the zone and back again")
	Patata()
	FileClose($loggingFile)
	Return 0
EndFunc


Func SpiritSlavesFarmSetup()
	If GetMapID() <> $ID_The_Shattered_Ravines Then
		If GetMapID() <> $ID_Bone_Palace Then
			Out("Travelling to Bone Palace")
			DistrictTravel($ID_Kaineng_City, $ID_EUROPE, $ID_FRENCH)
		EndIf
		SwitchMode($ID_HARD_MODE)
		
		; TODO : make all the travel to The Shattered Ravines
	EndIf
	$SpiritSlaves_Farm_Setup = True
EndFunc


















Func tata1()
	Local $lMe, $coordsX, $coordsY
	$lMe = GetAgentByID(-2)
	$coordsX = DllStructGetData($lMe, 'X')
	$coordsY = DllStructGetData($lMe, 'Y')

	If -1400 < $coordsX And $coordsX < -550 And - 2000 < $coordsY And $coordsY < -1100 Then
		MoveTo(1474, -1197, 0)
	EndIf

	RndSleep(1000)
	GoToNPC(GetNearestNPCToCoords(2240, -1264))
	RndSleep(250)
	Dialog(0x00000084)
	RndSleep(500)
	WaitMapLoading($ID_Kaineng_A_Chance_Encounter)
EndFunc


Func tata2()
	Local $deadlock = TimerInit()
	_FileWriteLog($loggingFile, "New run started")
	RndSleep(1000)
	Local $foesInRange = CountFoesInRangeOfAgent(-2, $RANGE_COMPASS)

	; Wait until there are enemies
	While $foesInRange == 0 And TimerDiff($deadlock) < 10000
		RndSleep(1000)
		$foesInRange = CountFoesInRangeOfAgent(-2, $RANGE_COMPASS)
		If IsFail() Then Return
	WEnd

	Local $deathTimer = null
	; Now there are enemies let's fight until one mob is left
	While $foesInRange > 1 And TimerDiff($deadlock) < 80000
		HelpMikuAndCharacter()
		;RenewSpirits()
		TargetNearestEnemy()
		AttackOrUseSkill(1300, $Skill_I_am_unstoppable, 50, $Skill_Hundred_Blades, 50, $Skill_To_the_limit, 50)
		If IsFail() Then
			If $deathTimer = null Then
				$deathTimer = TimerInit()
			ElseIf TimerDiff($deathTimer) > 10000 Then
				Return
			EndIf
		Else
			$foesInRange = CountFoesInRangeOfAgent(-2, $RANGE_COMPASS)
			If $deathTimer <> null Then $deathTimer = null
		EndIf
	WEnd
	If (TimerDiff($deadlock) > 80000) Then Out("Timed out waiting for most mobs to be dead")

	PickUpItems(null, PickOnlyImportantItem)

	; Unflag all heroes
	;CancelAll()
	CancelHero(1)
	CancelHero(2)
	CancelHero(3)
	CancelHero(4)
	CancelHero(5)
	CancelHero(6)
	CancelHero(7)

	; Hero cast speed on character
	UseHeroSkill($Hero_Mesmer_Ineptitude, $Make_Haste_Skill_position, -2)

	; Move all heroes to podium to kill last foes
	CommandAll(-6699, -5645)

	If IsRecharged($Skill_I_am_unstoppable) Then UseSkillEx($Skill_I_am_unstoppable)
	; Run to first stairs
	Move(-4693, -3137)

	; Wait for all foes in range of Miku to be dead
	While (CountFoesInRangeOfAgent(58, $RANGE_SPELLCAST) > 0 And TimerDiff($deadlock) < 80000 And Not IsFail())
		Move(-4693, -3137)
		RndSleep(750)
	WEnd
	If (TimerDiff($deadlock) > 80000) Then Out("Timed out waiting for all mobs to be dead")

	UseHeroSkill($Hero_Ritualist_SoS, $Mend_Body_And_Soul_Skill_Position, 58)
	UseHeroSkill($Hero_Necro_BiP, $Mend_Body_And_Soul_Skill_Position, 58)
	_FileWriteLog($loggingFile, "Initial fight duration - " & Round(TimerDiff($deadlock)/1000) & "s")

	; Move all heroes to not interfere with loot
	CommandAll(-7075, -5685)
EndFunc


;~ Run to farm spot
Func tata3()
	Local $lDeadLock = TimerInit()
	MoveTo(-4199, -1475)
	MoveTo(-4709, -609)
	MoveTo(-3116, 650)
	MoveTo(-2518, 631)
	MoveTo(-2096, -1067)
	MoveTo(-815, -1898)
	MoveTo(-690, -3769)
	MoveTo(-850, -3961, 0)
	RndSleep(500)
EndFunc


;~ Wait for all ennemies to be balled
Func tata4()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)

	; Wait until an enemy is in melee range
	While Not GetisDead(-2) And $foesCount == 0 And TimerDiff($deadlock) < 55000
		RndSleep(1000)
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	WEnd

	UseEgg()

	_FileWriteLog($loggingFile, "Initial foes count - " & GetFoesOnTopOfTheStairs()[0])

	While Not GetisDead(-2) And TimerDiff($deadlock) < 75000 And Not IsFurthestMobInBall()
		If ($foesCount > 3 And IsRecharged($Skill_To_the_limit) And GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130) Then
			UseSkillEx($Skill_To_the_limit)
			RndSleep(50)
		EndIf

		; Use defensive and self healing skills
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.90 And IsRecharged($Skill_I_am_unstoppable) Then
			UseSkillEx($Skill_I_am_unstoppable)
			RndSleep(50)
		EndIf
		If IsRecharged($Skill_Conviction) And GetEffectTimeRemaining(GetEffect($ID_Conviction)) == 0 Then
			UseSkillEx($Skill_Conviction)
			RndSleep(50)
			
			If IsRecharged($Skill_Vital_Boon) Then
				UseSkillEx($Skill_Vital_Boon)
				RndSleep(GetPing() + 1000)
			EndIf
		EndIf
		;If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
		;	UseSkillEx($Skill_Mystic_Regeneration)
		;	RndSleep(GetPing() + 300)
		;EndIf
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.60 And IsRecharged($Skill_Vital_Boon) And GetEffectTimeRemaining(GetEffect($ID_Vital_Boon)) == 0 Then
			UseSkillEx($Skill_Vital_Boon)
			RndSleep(GetPing() + 1000)
		EndIf
		
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.45 And IsRecharged($Skill_Grenths_Aura) Then
			UseSkillEx($Skill_Grenths_Aura)
			RndSleep(250)
		EndIf
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf

		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
		RndSleep(250)
	WEnd
	If (TimerDiff($deadlock) > 75000) Then Out("Timed out waiting for mobs to ball")
	_FileWriteLog($loggingFile, "Ball ready - " & Round(TimerDiff($deadlock)/1000) & "s")
EndFunc


;~ Return true if mission failed (you or Miku died)
Func tata5()
	If GetIsDead(GetAgentByID(58)) Then
		Return True
	Elseif GetIsDead(GetAgentByID(-2)) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Return to outpost in case of failure
Func tata6()
	If GetIsDead(GetAgentByID(58)) Then
		Out("Miku died.")
		_FileWriteLog($loggingFile, "Miku died.")
	ElseIf GetIsDead(GetAgentByID(-2)) Then
		Out("Player died")
		_FileWriteLog($loggingFile, "Character died.")
	EndIf
	RndSleep(5000)
	Resign()
	RndSleep(3400)
	ReturnToOutpost()
	WaitMapLoading($ID_Kaineng_City)
	Return 1
EndFunc


;~ Kill mobs
Func tata7()
	Local $me = GetAgentByID(-2)
	Local $deadlock
	Local $foesCount

	If DllStructGetData($me, "HP") < 0.60 And IsRecharged($Skill_Grenths_Aura) Then
		UseSkillEx($Skill_Grenths_Aura)
		RndSleep(50)
	EndIf

	Out("EBSO")
	While IsRecharged($Skill_Ebon_Battle_Standard_of_Honor)
		If GetIsDead($me) Then Return
		UseSkillEx($Skill_Ebon_Battle_Standard_of_Honor)
		RndSleep(50)

		If DllStructGetData(GetAgentByID(-2), "HP") < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf
	WEnd

	Out("100B")
	While IsRecharged($Skill_Hundred_Blades)
		If GetIsDead($me) Then Return
		UseSkillEx($Skill_Hundred_Blades)
		RndSleep(50)
	WEnd

	Out("Grenth Aura")
	If IsRecharged($Skill_Grenths_Aura) Then
		If GetIsDead($me) Then Return
		UseSkillEx($Skill_Grenths_Aura)
		RndSleep(50)
	EndIf

	Local $initialFoeCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)

	;~ Whirlwind attack needs specific care to be used
	Out("Whirlwind")
	While IsRecharged($Skill_Whirlwind_Attack)
		If GetIsDead($me) Then Return

		; Heroes with Mystic Healing provide additional long range support
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf

		If (IsRecharged($Skill_To_the_limit) And GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130) Then
			UseSkillEx($Skill_To_the_limit)
			RndSleep(50)
		EndIf

		UseSkillEx($Skill_Whirlwind_Attack, GetNearestEnemyToAgent(-2))
		RndSleep(250)
	WEnd
	$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_ADJACENT)

	RndSleep(250)

	; If some foes are still alive, we have 10s to finish them else we just pick up and leave
	$deadlock = TimerInit()
	Out("Finish")
	While $foesCount > 0 And TimerDiff($deadlock) < 10000
		If GetIsDead($me) Then Return
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf

		If (IsRecharged($Skill_To_the_limit) And GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130) Then
			UseSkillEx($Skill_To_the_limit)
			RndSleep(50)
		EndIf
		
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.60 And IsRecharged($Skill_Vital_Boon) And GetEffectTimeRemaining(GetEffect($ID_Vital_Boon)) == 0 Then
			UseSkillEx($Skill_Vital_Boon)
			RndSleep(1000)
		;If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
		;	UseSkillEx($Skill_Mystic_Regeneration)
		;	RndSleep(300)
		ElseIf GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) == 130 Then
			Out("Finish with Whirlwind")
			While IsRecharged($Skill_Whirlwind_Attack) And TimerDiff($deadlock) < 10000
				If GetIsDead($me) Then Return
				UseSkillEx($Skill_Whirlwind_Attack, GetNearestEnemyToAgent(-2))
				RndSleep(250)
			WEnd
		Else
			AttackOrUseSkill(1300, $Skill_Conviction, 50)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_ADJACENT)
	WEnd
	If (TimerDiff($deadlock) > 10000) Then Out("Left " & $foesCount & " mobs alive out of " & $initialFoeCount & " foes")
	_FileWriteLog($loggingFile, "Mobs killed - " & ($initialFoeCount - $foesCount))
	_FileWriteLog($loggingFile, "Mobs left alive - " & $foesCount)

	RndSleep(250)
EndFunc


Func tata8()
	If DllStructGetData(GetAgentByID(-2), "HP") < 0.90 Then
		If IsRecharged($Skill_Conviction) And GetEffectTimeRemaining(GetEffect($ID_Conviction)) == 0 Then
			UseSkillEx($Skill_Conviction)
			RndSleep(50)
		EndIf
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.60 And IsRecharged($Skill_Vital_Boon) And GetEffectTimeRemaining(GetEffect($ID_Vital_Boon)) == 0 Then
			UseSkillEx($Skill_Vital_Boon)
			RndSleep(GetPing() + 1000)
		;If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
		;	UseSkillEx($Skill_Mystic_Regeneration)
		;	RndSleep(GetPing() + 300)
		EndIf
		; Heroes with Mystic Healing provide additional long range support
		UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
	EndIf
EndFunc


Func tata9($attackSleep, $skill = null, $skillSleep = 0, $skill2 = null, $skill2Sleep = 0,  $skill3 = null, $skill3Sleep = 0)
	If ($skill <> null And IsRecharged($skill)) Then
		UseSkillEx($skill)
		RndSleep($skillSleep)
	ElseIf ($skill2 <> null And IsRecharged($skill2)) Then
		UseSkillEx($skill2)
		RndSleep($skill2Sleep)
	ElseIf ($skill3 <> null And IsRecharged($skill3)) Then
		UseSkillEx($skill3)
		RndSleep($skill3Sleep)
	Else
		Attack(GetNearestEnemyToAgent(-2))
		RndSleep($attackSleep)
	EndIf
EndFunc
