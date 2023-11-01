#CS
#################################
#								#
#	Raptor Bot 
#								#
#################################
Author: Rattiev
Based on : Vaettir Bot by gigi
Modified by: Night
#CE

#include-once
#RequireAdmin
#NoTrayIcon

#include "GWA2_Headers.au3"
#include "GWA2.au3"
#include "Utils.au3"

Opt("MustDeclareVars", 1)

Local Const $RaptorBotVersion = "0.4"

; ==== Constantes ====
Local Const $WNRaptorFarmerSkillbar = "OQQTcYqVXySgmUlJvovYUbHctAA"
Local Const $PRunnerHeroSkillbar = "OQijEqmMKODbe8O2Efjrx0bWMA"
Local Const $RaptorsFarmInformations = "For best results, have :" & @CRLF _
	& "- 12 in curses" & @CRLF _
	& "- 12+ in tactics" & @CRLF _
	& "- 9+ in swordsmanship (enough to use your sword)"& @CRLF _
	& "- A Tactics shield with the inscription 'Through Thick and Thin' (+10 armor against Piercing damage)" & @CRLF _
	& "- A sword 'of Shelter', prefix and inscription do not matter" & @CRLF _
	& "- Knight insignias on all the armor pieces" & @CRLF _
	& "- A superior vigor rune" & @CRLF _
	& "- A superior Absorption rune" & @CRLF _
	& "- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership" & @CRLF _
	& "- Golden Eggs"
; Skill numbers declared to make the code WAY more readable (UseSkill($MarkOfPain  is better than UseSkill(1))
Local Const $MarkOfPain = 1
Local Const $IAmUnstoppable = 2
Local Const $ProtectorsDefense = 3
Local Const $WaryStance = 4
Local Const $HundredBlades = 5
Local Const $SoldiersDefense = 6
Local Const $WhirlwindAttack = 7
Local Const $ShieldBash = 8

; Hero Build
Local Const $Raptors_VocalWasSogolon = 1
Local Const $Raptors_Incoming = 2
Local Const $Raptors_FallBack = 3
Local Const $Raptors_EnduringHarmony = 4
Local Const $Raptors_MakeHaste = 5
Local Const $Raptors_StandYourGround = 6
Local Const $Raptors_CantTouchThis = 7
Local Const $Raptors_BladeturnRefrain = 8


Local $PickUpSaurianBones = False


#Region GUI
Global $RAPTORS_FARM_SETUP = False

;~ Main method to farm Raptors
Func RaptorFarm($STATUS)
	If $STATUS <> "RUNNING" Then Return

	If ($Deadlocked OR ((CountSlots() < 5) AND (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED))) Then
		Out("Inventory full, pausing.")
		$Deadlocked = False
		;Inventory()
		$STATS_MAP["success_code"] = 2
		Return
	EndIf

	If $STATUS <> "RUNNING" Then Return

	If GetMapID() <> $ID_Rata_Sum Then
		TravelTo($ID_Rata_Sum)
	EndIf
	
	If Not $RAPTORS_FARM_SETUP Then 
		SetupRaptorFarm()
		$RAPTORS_FARM_SETUP = True
	EndIf

	If $STATUS <> "RUNNING" Then Return

	$STATS_MAP["success_code"] = RaptorsFarmLoop()
	
	If $Deadlocked Then $STATS_MAP["success_code"] = 1
	
	Return
EndFunc


Func SetupRaptorFarm()
	Out("Setting up farm")
	; TODO Display your Asura Title for the energy boost.
	;SetDisplayedTitle(0x29)
	SwitchMode($ID_HARD_MODE)
	AddHero($ID_General_Morgahn)
	;DisableHeroSkills()
	MoveTo(19649, 16791)
	Move(20084, 16854)
	Sleep(1000)
	WaitMapLoading($ID_Riven_Earth)
	Move(-26309, -4112)
	Sleep(1000)
	WaitMapLoading($ID_Rata_Sum)
	Out("Resign preparation complete")
EndFunc


Func DisableHeroSkills()
	For $i = 1 to 8
		DisableHeroSkillSlot(1, $i)
	Next
EndFunc


;~ Farm loop
Func RaptorsFarmLoop()
	If Not $RenderingEnabled Then ClearMemory()
	Out("Exiting to Riven Earth")
	Move(20084, 16854)
	Sleep(GetPing() + 1000)
	UseHeroSkill(1, $Raptors_Incoming)
	WaitMapLoading($ID_Riven_Earth)
	UseHeroSkill(1, $Raptors_Incoming)
	UseHeroSkill(1, $Raptors_VocalWasSogolon)
	GetBlessing()
	MoveToBaseOfCave()
	MoveHeroAway()
	GetRaptors()
	KillRaptors()

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		Out("Looting")
		PickUpItems(DefendWhilePickingUpItems)
	EndIf

	Return BackToTown()
EndFunc


Func DefendWhilePickingUpItems()
	Local $lme = GetAgentByID(-2)
	If GetEnergy($lMe) > 5 And IsRecharged($IAmUnstoppable) Then UseSkillEx($IAmUnstoppable)
	If GetEnergy($lMe) > 5 And IsRecharged($SoldiersDefense) Then UseSkillEx($SoldiersDefense)
	If GetEnergy($lMe) > 5 And IsRecharged($ShieldBash) Then UseSkillEx($ShieldBash)
	If GetEnergy($lMe) > 10 And IsRecharged($WaryStance) Then UseSkillEx($WaryStance)
EndFunc


Func GetBlessing()
	Local $Asura = GetAsuraTitle()
	If $Asura < 160000 Then
		Out("Getting asura title blessing")
		GoNearestNPCToCoords(-20000, 3000)
		Dialog(132)
	EndIf
	Sleep(250)
EndFunc

Func MoveToBaseOfCave()
	Local $lme = GetAgentByID(-2)
	If GetIsDead(-2) Then Return
	Out("Moving to Cave")
	Move(-22015, -7502)
	RndSleep(Random(500, 1000))
	UseHeroSkill(1, $Raptors_FallBack)
	RndSleep(Random(7000, 7800))
	UseSkill($IAmUnstoppable, $lMe)
	Moveto(-21333, -8384)
	UseHeroSkill(1, $Raptors_EnduringHarmony, -2)
	Sleep(1800)
	UseHeroSkill(1, $Raptors_MakeHaste, -2)
	RndSleep(Random(20, 50))
	UseHeroSkill(1, $Raptors_StandYourGround)
	RndSleep(Random(20, 50))
	UseHeroSkill(1, $Raptors_CantTouchThis)
	RndSleep(Random(20, 50))
	UseHeroSkill(1, $Raptors_BladeturnRefrain, -2)
	Move(-20930, -9480, 40)
EndFunc


Func MoveHeroAway()
	Out("Moving Hero away")
	CommandAll(-25309, -4212)
	Sleep(Random(250, 500))
EndFunc


Func GetRaptors()
	Out("Gathering Raptors")
	Local $MoPTarget = GetNearestEnemyToAgent(-2)
	Local $CheckTarget
	
	Move(-20695, -9900, 20)
	;Using the nearest to agent could result in targeting Angorodon if they are badly placed
	;$MoPTarget = GetNearestEnemyToAgent(-2)
	$MoPTarget = GetNearestEnemyToCoords(-20042, -10251)
	
	UseSkill($ShieldBash, -2)
	UseSkillEx($MarkOfPain, $MoPTarget)

	$CheckTarget = TargetNearestEnemy()
	MoveAggroingRaptors(-20042, -10251, 50, $CheckTarget)
	MoveTo(-19700, -10650, 50)
	MoveTo(-19650, -11500, 50)
	MoveTo(-20535, -12000, 50)
	MoveAggroingRaptors(-21490, -12175, 50, $CheckTarget)
	MoveTo(-22000, -11927, 50)
	TargetNearestEnemy()
	MoveTo(-22450, -11820, 20)
	MoveTo(-22450, -12460, 20)
EndFunc

Func KillRaptors()
	Local $MoPTarget
	Local $lMe = GetAgentByID(-2)
	Local $lRekoff

	If GetIsDead($lme) Then Return
	Out("Clearing Raptors")
	UseSkill($IAmUnstoppable, $lMe)
	RndSleep(Random(40, 60))
	UseSkill($ProtectorsDefense, $lMe)
	RndSleep(Random(40, 60))
	UseSkill($HundredBlades, $lMe)
	RndSleep(Random(1400, 1600))
	UseSkill($WaryStance, $lMe)
	RndSleep(Random(400, 600))

	$lRekoff = GetAgentByName("Rekoff Broodmother")

	If ComputeDistance(DllStructGetData($lMe, 'X'), DllStructGetData($lMe, 'Y'), DllStructGetData($lRekoff, 'X'), DllStructGetData($lRekoff, 'Y')) > 1500 Then
		$MoPTarget = GetNearestEnemyToAgent(-2)
	Else
		$MoPTarget = GetNearestEnemyToAgent($lRekoff)
	EndIf

	If GetHasHex($MoPTarget) Then
		TargetNextEnemy()
		$MoPTarget = GetCurrentTarget()
	EndIf

	Local $lDistance
	Local $lSpellCastCount
	Local $lAgentArray

	$lAgentArray = GetAgentArray(0xDB)

	For $i=1 To $lAgentArray[0]
	$lDistance = GetPseudoDistance($lMe, $lAgentArray[$i])
		If $lDistance < $RANGE_SPELLCAST_2 Then
			$lSpellCastCount += 1
		EndIf
	Next

	If $lSpellCastCount	> 20 Then
		Sleep(2500)
	Elseif $lSpellCastCount < 21 Then
		Sleep(4500)
	EndIf

	UseSkill($MarkOfPain, $MoPTarget)
	RndSleep(Random(1000, 1100))
	UseSkillEx($SoldiersDefense, $lMe)
	RndSleep(Random(30, 60))
	UseSkill($ShieldBash, $lMe)
	RndSleep(Random(30, 60))
	UseSkillEx($WhirlwindAttack, GetNearestEnemyToAgent(-2))
	Sleep(GetPing() + 1500)
	UseSkill($WhirlwindAttack, GetNearestEnemyToAgent(-2))
	Sleep(GetPing() + 250)
EndFunc


Func BackToTown()
	Local $result = AssertFarmResult()
	Out("Porting to Rata Sum")
	Resign()
	Sleep(3400)
	ReturnToOutpost()
	WaitMapLoading($ID_Rata_Sum)
	Return $result
EndFunc


Func AssertFarmResult()
	Local $lMe
	Local $lAdjacentCount, $lDistance
	Local $lAgentArray

	$lAgentArray = GetAgentArray(0xDB)

	For $i=1 To $lAgentArray[0]
	$lDistance = GetPseudoDistance($lMe, $lAgentArray[$i])
		If $lDistance < $RANGE_ADJACENT_2 Then
			$lAdjacentCount += 1
		EndIf
	Next

	If GetIsDead(-2) Then
		Out("Character died")
		Return 1
	ElseIf $lAdjacentCount > 0 Then
		Out("Some raptors survived")
		Return 1
	Else
		Return 0
	EndIf
EndFunc


;~ Description: Move to destX, destY, while staying alive vs vaettirs
Func MoveAggroingRaptors($lDestX, $lDestY, $lRandom, $CheckTarget)
	If GetIsDead(-2) Then Return

	Local $lMe, $lAgentArray
	Local $lBlocked
	Local $lAdjacentCount, $lDistance
	Local $timer = TimerInit()
	Local $timerCount

	Move($lDestX, $lDestY, $lRandom)

	$lMe = GetAgentByID(-2)
	$lAgentArray = GetAgentArray(0xDB)

	For $i=1 To $lAgentArray[0]
	$lDistance = GetPseudoDistance($lMe, $lAgentArray[$i])
		If $lDistance < $RANGE_ADJACENT_2 Then
			$lAdjacentCount += 1
		EndIf
	Next

	If $lAdjacentCount > 10 Then
		$timerCount += 1
	EndIf

	Do
		Sleep(50)

		$lMe = GetAgentByID(-2)

		If GetIsDead($lMe) Then Return

		If DllStructGetData($lMe, 'MoveX') == 0 And DllStructGetData($lMe, 'MoveY') == 0 Then
			$lBlocked += 1
			Move($lDestX, $lDestY, $lRandom)
		EndIf

		If $lBlocked > 3 Then
			If TimerDiff($timer) > 2500 Then	; use a timer to avoid spamming /stuck
				SendChat("stuck", "/")
				$timer = TimerInit()
				$timerCount += 1
			EndIf
		EndIf

		If GetDistance() > 1500 Then ; target is far, we probably got stuck.
			If TimerDiff($timer) > 2500 Then ; dont spam
				SendChat("stuck", "/")
				$timer = TimerInit()
				RndSleep(GetPing())
				Attack($CheckTarget)
				$timerCount += 1
			EndIf
		EndIf

		If $timerCount > 0 Then Return

	Until ComputeDistance(DllStructGetData($lMe, 'X'), DllStructGetData($lMe, 'Y'), $lDestX, $lDestY) < $lRandom*1.5
EndFunc