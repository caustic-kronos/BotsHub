#CS
#################################
#								#
#	Jade Brotherhood Bot 		#
#								#
#################################
Author: Night
#CE

#include-once
#RequireAdmin
#NoTrayIcon

#include "GWA2_Headers.au3"
#include "GWA2.au3"
#include "Utils.au3"

Opt("MustDeclareVars", 1)

Local Const $JB_VERSION = "0.1"
Local Const $JB_Timeout = 120000

; ==== Constants ====
Local Const $JB_Skillbar = "OgejkirMrSqimXfXfbrXaXNX4OA"
Local Const $JB_Hero_Skillbar = "OQijEqmMKODbe8O2Efjrx0bWMA"
Local Const $JB_FarmInformations = "For best results, have :" & @CRLF _
	& "- 16 in earth prayers" & @CRLF _
	& "- 11+ in mysticism" & @CRLF _
	& "- 9+ in scythe mastery (enough to use your scythe)"& @CRLF _
	& "- A scythe 'Guided by Fate', enchantements last 20% longer" & @CRLF _
	& "- Windwalker insignias on all the armor pieces" & @CRLF _
	& "- A superior vigor rune" & @CRLF _
	& "- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership" & @CRLF _
	& "- Golden Eggs"
; Skill numbers declared to make the code WAY more readable (UseSkill($MarkOfPain  is better than UseSkill(1))
Local Const $JB_DrunkerMaster = 1
Local Const $JB_SandShards = 2
Local Const $JB_MysticVigor = 3
Local Const $JB_VowOfStrength = 4
Local Const $JB_ArmorOfSanctity = 5
Local Const $JB_StaggeringForce = 6
Local Const $JB_EremitesAttack = 7
Local Const $JB_DeathsCharge = 8

; Hero Build
Local Const $Brotherhood_Mystic_Healing = 1
Local Const $Brotherhood_Incoming = 7
Local Const $Brotherhood_FallBack = 6
Local Const $Brotherhood_EnduringHarmony = 2
Local Const $Brotherhood_MakeHaste = 3

Local $DeadlockTimer
Local $Deadlocked = False

#Region GUI
Global $Jade_Brotherhood_Farm_Setup = False


;~ Main method to farm Jade Brotherhood for q8
Func JadeBrotherhoodFarm($STATUS)
	If $STATUS <> "RUNNING" Then Return

	If ($Deadlocked OR ((CountSlots() < 5) AND (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED))) Then
		Out("Inventory full, pausing.")
		$Deadlocked = False
		Return 2
	EndIf

	If $STATUS <> "RUNNING" Then Return

	If GetMapID() <> $ID_The_Marketplace Then
		TravelTo($ID_The_Marketplace)
	EndIf
	
	If Not $Jade_Brotherhood_Farm_Setup Then
		SetupJadeBrotherhoodFarm()
		$Jade_Brotherhood_Farm_Setup = True
	EndIf

	If $STATUS <> "RUNNING" Then Return 

	Return JadeBrotherhoodFarmLoop()
EndFunc


;~ Setup for the jade brotherhood farm
Func SetupJadeBrotherhoodFarm()
	Out("Setting up farm")
	SwitchMode($ID_HARD_MODE)
	AddHero($ID_General_Morgahn)
	MoveTo(16106, 18497)
	Move(16481, 19378)
	Move(16551, 19860)
	RndSleep(1000)
	UseHeroSkill(1, $Brotherhood_Incoming)
	WaitMapLoading($ID_Bukdek_Byway)
	RndSleep(50)
	UseHeroSkill(1, $Brotherhood_Incoming)
	Move(-13960, -11700)
	RndSleep(1000)
	WaitMapLoading($ID_The_Marketplace)
	Out("Jade Brotherhood farm setup")
EndFunc


;~ Farm loop
Func JadeBrotherhoodFarmLoop()
	Local $lme = GetAgentByID(-2)
	If Not $RenderingEnabled Then ClearMemory()
	Out("Abandonning quest")
	AbandonQuest(457)
	Out("Exiting to Bukdek Byway")
	Move(16551, 19860)
	RndSleep(1000)
	WaitMapLoading($ID_Bukdek_Byway)
	RndSleep(50)
	MoveToSeparationWithHero()
	$DeadlockTimer = TimerInit()
	TalkToAiko()
	If GetIsDead($lme) Then Return BackToTheMarketplace(1)
	WaitForBall()
	If GetIsDead($lme) Then Return BackToTheMarketplace(1)
	KillJadeBrotherhood()
	If GetIsDead($lme) Then Return BackToTheMarketplace(1)

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		RndSleep(50)
		Out("Looting")
		PickUpItems(null, AlsoPickLowReqItems)
	EndIf

	If ($Deadlocked) Then Return BackToTheMarketplace(1)
	Return BackToTheMarketplace(0)
EndFunc


Func MoveToSeparationWithHero()
	Local $lme = GetAgentByID(-2)
	Out("Moving to crossing")
	UseHeroSkill(1, $Brotherhood_Incoming)
	RndSleep(50)
	CommandAll(-10475, -9685)
	RndSleep(50)
	Move(-10475, -9685)
	RndSleep(7500)
	UseHeroSkill(1, $Brotherhood_EnduringHarmony, -2)
	RndSleep(1500)
	UseHeroSkill(1, $Brotherhood_MakeHaste, -2)
	RndSleep(50)
	Move(-11983, -6261, 40)
	RndSleep(300)
	Out("Moving Hero away")
	CommandAll(-8447, -10099)
	RndSleep(7000)
EndFunc


Func TalkToAiko()
	Out("Talking to Aiko")
	GoNearestNPCToCoords(-13923, -5098)
	RndSleep(1000)
	Out("Taking quest")
	AcceptQuest(457)
	Move(-11303, -6545, 40)
	RndSleep(4500)
EndFunc


Func WaitForBall()
	Local $lMe = GetAgentByID(-2)
	Out("Waiting for ball")
	If GetIsDead($lme) Then Return
	RndSleep(4500)
	Local $target, $foesBalled = 0, $peasantsAlive = 100, $countsDidNotChange = 0
	Local $prevFoesBalled = 0, $prevPeasantsAlive = 100
	; Aiko counts
	While ($foesBalled <> 8 Or $peasantsAlive > 1)
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		Out("Foes balled : " & $foesBalled)
		Out("Peasants alive : " & $peasantsAlive)
		RndSleep(4500)
		$target = GetNearestEnemyToCoords(-13262, -5486)
		$prevFoesBalled = $foesBalled
		$prevPeasantsAlive = $peasantsAlive
		$foesBalled = CountFoesInRangeOfAgent($target, 450)
		$peasantsAlive = CountAlliesInRangeOfAgent($target, 1600)
		If ($foesBalled = $prevFoesBalled And $peasantsAlive = $prevPeasantsAlive) Then
			$countsDidNotChange += 1
			If $countsDidNotChange > 2 Then Return
		Else 
			$countsDidNotChange = 0
		EndIf
	WEnd
EndFunc

Func KillJadeBrotherhood()
	Local $lMe = GetAgentByID(-2)
	Local $EnchantmentsTimer
	Local $target

	If GetIsDead($lme) Then Return

	Out("Clearing Jade Brotherhood")
	UseSkillEx($JB_DrunkerMaster, $lMe)
	RndSleep(50)
	UseSkillEx($JB_SandShards, $lMe)
	RndSleep(50)
	
	$target = GetNearestEnemyToCoords(-13262, -5486)
	$target = TargetMobInCenter($target, 360)
	GetAlmostInRangeOfAgent($target)
	UseSkillEx($JB_MysticVigor, $lMe)
	RndSleep(300)
	UseSkillEx($JB_ArmorOfSanctity, $lMe)
	RndSleep(300)
	UseSkillEx($JB_VowOfStrength, $lMe)
	RndSleep(500)
	$EnchantmentsTimer = TimerInit()
	While IsRecharged($JB_DeathsCharge)
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		UseSkillEx($JB_DeathsCharge, $target)
		RndSleep(50)
	WEnd
	UseSkillEx($JB_StaggeringForce, $lMe)
	RndSleep(50)
	UseSkillEx($JB_EremitesAttack, $target)
	While IsRecharged($JB_EremitesAttack)
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		UseSkillEx($JB_EremitesAttack, $target)
		RndSleep(50)
	WEnd
	
	While CountFoesInRangeOfAgent(-2, 1250) > 0
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		If GetEnergy($lMe) >= 6 And IsRecharged($JB_SandShards) Then
			UseSkillEx($JB_SandShards, $lMe)
			RndSleep(50)
		EndIf
		If GetEnergy($lMe) >= 6 And TimerDiff($EnchantmentsTimer) > 18000 Then
			UseSkillEx($JB_VowOfStrength, $lMe)
			RndSleep(300)
			UseSkillEx($JB_MysticVigor, $lMe)
			RndSleep(300)
			$EnchantmentsTimer = TimerInit()
		EndIf
		If GetEnergy($lMe) >= 3 And IsRecharged($JB_ArmorOfSanctity) Then
			UseSkillEx($JB_ArmorOfSanctity, $lMe)
			RndSleep(300)
		EndIf
		TargetNearestEnemy()
		RndSleep(250)
		ChangeTarget(-1)
		Attack(-1)
		RndSleep(250)
	WEnd
EndFunc


Func BackToTheMarketplace($success)
	Out("Porting to The Marketplace")
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_The_Marketplace)
	Return $success
EndFunc


Func GetAlmostInRangeOfAgent($tgtAgent)
	Local $lMe = GetAgentByID(-2)
	Local $xMe = DllStructGetData($lMe, 'X')
	Local $yMe = DllStructGetData($lMe, 'Y')
	Local $xTgt = DllStructGetData($tgtAgent, 'X')
	Local $yTgt = DllStructGetData($tgtAgent, 'Y')
	
	Local $distance = Sqrt(($xTgt - $xMe) ^ 2 + ($yTgt - $yMe) ^ 2)
	Local $ratio = ($RANGE_SPELLCAST + 100) / $distance
		
	Local $xGo = $xMe + ($xTgt - $xMe) * $ratio
	Local $yGo = $yMe + ($yTgt - $yMe) * $ratio
	Move($xGo, $yGo, 40)
	RndSleep(5000)
EndFunc


Func TargetMobInCenter($aAgent, $aRange)
	Local $lAgent, $lDistance
	Local $lCount = 0, $sumX = 0, $sumY = 0

	If Not IsDllStruct($aAgent) Then $aAgent = GetAgentByID($aAgent)

	For $i = 1 To GetMaxAgents()
		$lAgent = GetAgentByID($i)
		If DllStructGetData($lAgent, 'Type') <> 0xDB Then ContinueLoop
		If DllStructGetData($lAgent, 'Allegiance') <> 3 Then ContinueLoop
		If DllStructGetData($lAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($lAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		$lDistance = GetDistance($aAgent, $lAgent)
		If $lDistance > $aRange Then ContinueLoop
		$lCount += 1
		$sumX += DllStructGetData($lAgent, 'X')
		$sumY += DllStructGetData($lAgent, 'Y')
	Next
	$sumX = $sumX / $lCount
	$sumY = $sumY / $lCount

	$lAgent = GetNearestEnemyToCoords($sumX, $sumY)
	Return $lAgent
EndFunc