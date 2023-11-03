#include-once

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"
#include <File.au3>

; ==== Constantes ====
Local Const $DWCommendationsFarmerSkillbar = "OgGlQpVq6smsGFA0XwTsDmL29RTSgB"
Local Const $CommendationsFarmInformations = "For best results, have :" & @CRLF _
	& "- 13 Earth Prayers" &@CRLF _
	& "- 7 Mysticism" & @CRLF _
	& "- 4 Wind Prayers" & @CRLF _
	& "- 10 Tactics (shield req + weakness)" & @CRLF _
	& "- 10 Swordsmanship (sword req + weakness)" & @CRLF _
	& "- Blessed insignias or Windwalker insignias"& @CRLF _
	& "- A tactics shield q9 or less with the inscription 'Sleep now in the fire' (+10 armor against fire damage)" & @CRLF _
	& "- A main hand with +20% enchantments duration and +5 armor" & @CRLF _
	& "- any PCons you wish to use"

Local $Ministerial_Commendations_Farm_Setup = False

Local $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Local Const $Skill_Conviction = 1
Local Const $Skill_Grenths_Aura  = 2
Local Const $Skill_I_am_unstoppable = 3
;Local Const $Skill_Healing_Signet = 4
Local Const $Skill_Mystic_Regeneration = 4
Local Const $Skill_To_the_limit = 5
Local Const $Skill_Ebon_Battle_Standard_of_Honor = 6
Local Const $Skill_Hundred_Blades = 7
Local Const $Skill_Whirlwind_Attack = 8

; ESurge mesmers
Local Const $Energy_Surge_Skill_Position = 1
Local Const $ESurge2_Mystic_Healing_Skill_Position = 8
; Ineptitude mesmer
Local Const $Stand_your_ground_Skill_position = 6
Local Const $Make_Haste_Skill_position = 7
; SoS Ritualist
Local Const $SoS_Skill_Position = 1
Local Const $Splinter_Weapon_Skill_Position = 2
Local Const $Essence_Strike_Skill_Position = 3
Local Const $Mend_Body_And_Soul_Skill_Position = 5
Local Const $Spirit_Light = 6
Local Const $Strength_of_honor_Skill_Position = 8
Local Const $SoS_Mystic_Healing_Skill_Position = 8
; Prot Ritualist
Local Const $SBoon_of_creation_Skill_Position = 1
Local Const $Soul_Twisting_Skill_Position = 1
Local Const $Shelter_Skill_Position = 2
Local Const $Union_Skill_Position = 3
Local Const $Displacement_Skill_Position = 4
Local Const $Armor_of_Unfeeling_Skill_Position = 4
Local Const $Prot_Mystic_Healing_Skill_Position = 7
; BiP Necro
Local Const $Life_Skill_Position = 4
Local Const $Blood_bond_Skill_Position = 4
Local Const $Spirit_Transfer = 4

; Order heros are added to the team
Local Const $Hero_Mesmer_DPS_1 = 1
Local Const $Hero_Mesmer_DPS_2 = 2
Local Const $Hero_Mesmer_DPS_3 = 3
Local Const $Hero_Mesmer_Ineptitude = 4
Local Const $Hero_Ritualist_SoS = 5
Local Const $Hero_Ritualist_Prot = 6
Local Const $Hero_Necro_BiP = 7

Local Const $ID_mesmer_mercenary_hero = $ID_Mercenary_Hero_1
Local Const $ID_ritualist_mercenary_hero = $ID_Mercenary_Hero_2

#CS
Character location : 	X: -6322.51318359375, Y: -5266.85986328125
Heroes locations :
- Me1 dps				X: -6488.185546875, Y: -5084.078125
- Me2 dps				X: -6052.578125, Y: -5522.14208984375
- Me3 dps				X: -5820.1552734375, Y: -5309.80615234375
- Me1 ineptitude/speed	X: -6041.62353515625, Y: -5072.26220703125
- Rt SoS				X: -6307.7060546875, Y: -5273.31494140625
- Rt heal				X: -6244.70703125, Y: -4860.3154296875
- N BiP					X: -6004.0107421875, Y: -4620.87451171875

Platform center :		X: -6699.40966796875, Y: -5645.5556640625
Away from loot :		X: -7295.5771484375, Y: -6395.5556640625

Travel :
1st stairs : 			X: -4693.87451171875, Y: -3137.0244140625 (time : until all mobs are dead)
2nd stairs :			X: -4199.5126953125, Y: -1475.53430175781 (time : 6s no speed)
3rd stairs :			X: -4709.81005859375, Y: -609.159118652344 (3s)
1st corner :			X: -3116.35498046875, Y: 650.431457519531 (7s)
2nd corner :			X: -2518.41357421875, Y: 631.814453125 (1.5s)
4th stairs :			X: -2096.59228515625, Y: -1067.5732421875 (6s)
5th stairs :			X: -815.586608886719, Y: -1898.28894042969 (5s)
last stairs :			X: -690.559143066406, Y: -3769.5224609375 (6.5s)

DPS spot :				X: -850.958312988281, Y: -3961.001953125 (1s)
#CE

Func MinisterialCommendationsFarm($STATUS)
	If Not($Ministerial_Commendations_Farm_Setup) Then Setup()
	$loggingFile = FileOpen("commendation_farm.log" , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	If $STATUS <> "RUNNING" Then Return
	
	If CountSlots() < 5 Then
		Out("Inventory full, pausing.")
		Return 2
	EndIf
	
	Out("Entering quest")
	EnterQuest()
	
	If $STATUS <> "RUNNING" Then Return

	Out("Preparing to fight")
	PrepareToFight()
	
	If $STATUS <> "RUNNING" Then Return
	
	Out("Fighting the first group")
	InitialFight()

	If (IsFail()) Then Return ResignAndReturnToOutpost()

	Out("Running to kill spot")
	RunToKillSpot()

	If (IsFail()) Then Return ResignAndReturnToOutpost()

	Out("Waiting for spike")
	WaitForPurityBall()

	If (IsFail()) Then Return ResignAndReturnToOutpost()

	Out("Spiking the farm group")
	KillMinistryOfPurity()

	Out("Picking up loot")
	PickUpItems()
	
	RndSleep(1000)

	Out("Travelling back to KC")
	DistrictTravel($ID_Kaineng_City, $ID_EUROPE, $ID_FRENCH)
	FileClose($loggingFile)
	Return 0
EndFunc


Func Setup()
	If GetMapID() <> $ID_Kaineng_City Then
		Out("Travelling to Kaineng City")
		DistrictTravel($ID_Kaineng_City, $ID_EUROPE, $ID_FRENCH)
	EndIf
	LeaveGroup()
	
	AddHero($ID_Gwen)
	AddHero($ID_Norgu)
	AddHero($ID_Razah)
	AddHero($ID_mesmer_mercenary_hero)
	AddHero($ID_ritualist_mercenary_hero)
	AddHero($ID_Xandra)
	AddHero($ID_Olias)
	
	SwitchMode($ID_HARD_MODE)
	$Ministerial_Commendations_Farm_Setup = True
EndFunc


Func EnterQuest()
	Local $lMe, $coordsX, $coordsY
	$lMe = GetAgentByID(-2)
	$coordsX = DllStructGetData($lMe, 'X')
	$coordsY = DllStructGetData($lMe, 'Y')

	If -1400 < $coordsX And $coordsX < -550 And - 2000 < $coordsY And $coordsY < -1100 Then
		MoveTo(1474, -1197, 0)
	EndIf

	RndSleep(1000)
	GoToNPC(GetNearestNPCToCoords(2240, -1264))
	Sleep(250)
	Dialog(0x00000084)
	Sleep(500)
	WaitMapLoading($ID_Kaineng_A_Chance_Encounter)
EndFunc


Func PrepareToFight()
	RndSleep(16000)
	;StartingPositions()
	AlternateStartingPositions2()

	UseHeroSkill($Hero_Ritualist_Prot, $SBoon_of_creation_Skill_Position)		;Prot - Boon of Creation
	Sleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Soul_Twisting_Skill_Position)			;Prot - Soul Twisting
	Sleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Shelter_Skill_Position)					;Prot - Shelter
	UseHeroSkill($Hero_Ritualist_SoS, $Splinter_Weapon_Skill_Position, -2)		;SoS - Splinter Weapon
	Sleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Union_Skill_Position)					;Prot - Union
	UseHeroSkill($Hero_Necro_BiP, $Life_Skill_Position)							;BiP - Life
	UseHeroSkill($Hero_Ritualist_SoS, $SoS_Skill_Position)						;SoS - SoS
	Sleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Displacement_Skill_Position)			;Prot - Displacement
	UseHeroSkill($Hero_Mesmer_DPS_1, $Energy_Surge_Skill_Position)				;ESurge1 - ESurge
	UseHeroSkill($Hero_Mesmer_DPS_2, $Energy_Surge_Skill_Position)				;ESurge2 - ESurge
	UseHeroSkill($Hero_Mesmer_DPS_3, $Energy_Surge_Skill_Position)				;ESurge3 - ESurge
	UseHeroSkill($Hero_Ritualist_SoS, $Essence_Strike_Skill_Position)			;Sos - Essence Strike
	UseHeroSkill($Hero_Necro_BiP, $Blood_bond_Skill_Position)					;BiP - Blood Bond
	Sleep(2500)
	; Enemies turn hostile now
	UseEgg()
	UseHeroSkill($Hero_Mesmer_Ineptitude, $Stand_your_ground_Skill_position)	;Ineptitude - Stand your ground
	UseHeroSkill($Hero_Ritualist_SoS, $Armor_of_Unfeeling_Skill_Position)		;Prot - Armor of Unfeeling
	UseSkillEx($Skill_Ebon_Battle_Standard_of_Honor)
	Sleep(1000)
EndFunc


;~ Move party into a good starting position
Func StartingPositions()
	CommandHero($Hero_Mesmer_DPS_1, -6488, -5084)
	CommandHero($Hero_Mesmer_DPS_2, -6052, -5522)
	CommandHero($Hero_Mesmer_DPS_3, -5820, -5309)
	CommandHero($Hero_Mesmer_Ineptitude, -6041, -5072)
	CommandHero($Hero_Ritualist_SoS, -6307, -5273)
	CommandHero($Hero_Ritualist_Prot, -6004, -4620)
	CommandHero($Hero_Necro_BiP, -6244, -4860)
	MoveTo(-6322, -5266)
EndFunc


;~ Move party into a good starting position
Func AlternateStartingPositions()
	CommandHero($Hero_Mesmer_DPS_1, -6175, -6013)
	CommandHero($Hero_Mesmer_DPS_2, -6151, -5622)
	CommandHero($Hero_Mesmer_DPS_3, -6201, -5239)
	CommandHero($Hero_Mesmer_Ineptitude, -5770, -5577)
	CommandHero($Hero_Ritualist_SoS, -5898, -5836)
	CommandHero($Hero_Ritualist_Prot, -5911, -5319)
	CommandHero($Hero_Necro_BiP, -5687, -5155)
	MoveTo(-6322, -5266)
EndFunc


;~ Move party into a good starting position
Func AlternateStartingPositions2()
	CommandHero($Hero_Mesmer_DPS_1, -6524, -5178)
	CommandHero($Hero_Mesmer_DPS_2, -6165, -5585)
	CommandHero($Hero_Mesmer_DPS_3, -6224, -5075)
	CommandHero($Hero_Mesmer_Ineptitude, -6033, -5271)
	CommandHero($Hero_Ritualist_SoS, -6515, -5510)
	CommandHero($Hero_Ritualist_Prot, -5766, -5226)
	CommandHero($Hero_Necro_BiP, -6170, -4792)
	MoveTo(-6285, -5343)
EndFunc


Func InitialFight()
	Local $deadlock = TimerInit()
	Sleep(1000)
	Local $foesInRange = CountFoesInRangeOfAgent(-2, $RANGE_COMPASS)
	
	; Wait until there are enemies
	While $foesInRange == 0 And TimerDiff($deadlock) < 10000
		Sleep(1000)
		$foesInRange = CountFoesInRangeOfAgent(-2, $RANGE_COMPASS)
	WEnd
	
	; Now there are enemies let's fight until one mob is left
	While $foesInRange > 1 And TimerDiff($deadlock) < 120000
		HelpMiku()
		TargetNearestEnemy()
		AttackOrUseSkill(1300, $Skill_I_am_unstoppable, 50, $Skill_Hundred_Blades, 50, $Skill_To_the_limit, 50)
		$foesInRange = CountFoesInRangeOfAgent(-2, $RANGE_COMPASS)
		If IsFail() Then Return
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out("Timed out waiting for most mobs to be dead")

	PickUpItems()

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
	While (CountFoesInRangeOfAgent(58, $RANGE_SPELLCAST) > 0 And TimerDiff($deadlock) < 120000 And Not IsFail())
		Move(-4693, -3137)
		RndSleep(750)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out("Timed out waiting for all mobs to be dead")

	UseHeroSkill($Hero_Ritualist_SoS, $Mend_Body_And_Soul_Skill_Position, 58)
	UseHeroSkill($Hero_Necro_BiP, $Mend_Body_And_Soul_Skill_Position, 58)
	_FileWriteLog($loggingFile, "Initial fight lasted " & Round(TimerDiff($deadlock)/1000) & "s")

	; Move all heroes to not interfere with loot
	CommandAll(-7075, -5685)
EndFunc


;~ Heal Miku if she needs it
Func HelpMiku()
	If DllStructGetData(GetAgentByID(58), 'HP') < 0.50 Then		; Works for some reason (58 = Miku)
		UseHeroSkill($Hero_Ritualist_SoS, $Spirit_Light, 58)
		UseHeroSkill($Hero_Necro_BiP, $Spirit_Transfer, 58)
	EndIf
EndFunc


;~ Run to farm spot
Func RunToKillSpot()
	Local $lDeadLock = TimerInit()
	MoveTo(-4199, -1475)
	MoveTo(-4709, -609)
	MoveTo(-3116, 650)
	MoveTo(-2518, 631)
	MoveTo(-2096, -1067)
	MoveTo(-815, -1898)
	MoveTo(-690, -3769)
	MoveTo(-850, -3961, 0)
	Sleep(500)
EndFunc


;~ Wait for all ennemies to be balled
Func WaitForPurityBall()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)

	; Wait until an enemy is in melee range
	While $foesCount == 0 And TimerDiff($deadlock) < 55000
		Sleep(1000)
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	WEnd
	
	Local $spirit
	
	While Not GetisDead(-2) And TimerDiff($deadlock) < 90000 And Not IsFurthestMobInBall()
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
		EndIf
		If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
			UseSkillEx($Skill_Mystic_Regeneration)
			RndSleep(GetPing() + 300)
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
	If (TimerDiff($deadlock) > 90000) Then Out("Timed out waiting for mobs to ball")
	_FileWriteLog($loggingFile, "Waited for all " & Round(TimerDiff($deadlock)/1000) & "s")
EndFunc


;~ Return true if mission failed (you or Miku died)
Func IsFail()
	If GetIsDead(GetAgentByID(58)) Then
		_FileWriteLog($loggingFile, "Miku died.")
	ElseIf GetIsDead(GetAgentByID(-2)) Then
		_FileWriteLog($loggingFile, "Character died.")
	Else
		Return False
	EndIf
	Return True
EndFunc


;~ Return to outpost in case of failure
Func ResignAndReturnToOutpost()
	If GetIsDead(GetAgentByID(58)) Then
		Out("Miku died.")
	ElseIf GetIsDead(GetAgentByID(-2)) Then
		Out("Player died")
	EndIf
	Sleep(5000)
	Resign()
	Sleep(3400)
	ReturnToOutpost()
	WaitMapLoading($ID_Kaineng_City)
	Return 1
EndFunc


;~ Kill mobs
Func KillMinistryOfPurity()
	Local $me = GetAgentByID(-2)
	Local $deadlock
	Local $foesCount

	If DllStructGetData($me, "HP") < 0.60 And IsRecharged($Skill_Grenths_Aura) Then
		UseSkillEx($Skill_Grenths_Aura)
		Sleep(GetPing() + Random(40, 60))
	EndIf

	While IsRecharged($Skill_Ebon_Battle_Standard_of_Honor)
		If GetIsDead($me) Then Return
		UseSkillEx($Skill_Ebon_Battle_Standard_of_Honor)
		Sleep(GetPing() + Random(40, 60))
		
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf
	WEnd

	While IsRecharged($Skill_Hundred_Blades)
		If GetIsDead($me) Then Return
		UseSkillEx($Skill_Hundred_Blades)
		Sleep(GetPing() + Random(40, 60))
	WEnd

	If IsRecharged($Skill_Grenths_Aura) Then
		If GetIsDead($me) Then Return
		UseSkillEx($Skill_Grenths_Aura)
		Sleep(GetPing() + Random(40, 60))
	EndIf
	
	Local $initialFoeCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	
	;~ Whirlwind attack needs specific care to be used
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
		Sleep(GetPing() + 250)
	WEnd
	
	Sleep(GetPing() + 250)

	; If some foes are still alive, we have 10s to finish them else we just pick up and leave
	$deadlock = TimerInit()
	$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_ADJACENT)
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
		If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
			UseSkillEx($Skill_Mystic_Regeneration)
			RndSleep(GetPing() + 300)
		ElseIf GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) == 130 Then
			While IsRecharged($Skill_Whirlwind_Attack) And TimerDiff($deadlock) < 10000
				If GetIsDead($me) Then Return
				UseSkillEx($Skill_Whirlwind_Attack, GetNearestEnemyToAgent(-2))
				Sleep(GetPing() + 250)
			WEnd
		Else
			AttackOrUseSkill(1300, $Skill_Conviction, 50)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_ADJACENT)
	WEnd
	If (TimerDiff($deadlock) > 10000) Then Out("Left " & $foesCount & " mobs alive out of " & $initialFoeCount & "foes")
	_FileWriteLog($loggingFile, "Mobs killed " & ($initialFoeCount - $foesCount))
	_FileWriteLog($loggingFile, "Mobs alive " & $foesCount)

	If DllStructGetData(GetAgentByID(-2), "HP") < 0.90 Then
		If IsRecharged($Skill_Conviction) And GetEffectTimeRemaining(GetEffect($ID_Conviction)) == 0 Then
			UseSkillEx($Skill_Conviction)
			RndSleep(50)
		EndIf
		If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
			UseSkillEx($Skill_Mystic_Regeneration)
			RndSleep(GetPing() + 300)
		EndIf
		; Heroes with Mystic Healing provide additional long range support
		UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
	EndIf

	RndSleep(250)
EndFunc


Func AttackOrUseSkill($attackSleep, $skill = null, $skillSleep = 0, $skill2 = null, $skill2Sleep = 0,  $skill3 = null, $skill3Sleep = 0)
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


Func IsFurthestMobInBall()
	Local $furthestEnemy = GetNearestEnemyToCoords(1817, -798)
	If GetDistance($furthestEnemy, -2) > $RANGE_NEARBY Then Return False
	Return True
EndFunc

Func GetPercentageMobsNearPlayer()
	Local $foesOnGoodSide = GetFoesOnTopOfTheStairs()
	Local $adjacentFoes = GetFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	Return $adjacentFoes[0] / $foesOnGoodSide[0]
EndFunc


Func GetFoesOnTopOfTheStairs()
	Return GetFoesInRangeOfAgent(-2, 0, IsOnTopOfTheStairs)
EndFunc

Func GetFoesUnderTheStairs()
	Return GetFoesInRangeOfAgent(-2, 0, IsUnderTheStairs)
EndFunc

Func IsOnTopOfTheStairs($agent)
	Return IsOverLine(1, 4800, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc

Func IsUnderTheStairs($agent)
	Return Not IsOverLine(1, 4800, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc
#EndRegion Functions