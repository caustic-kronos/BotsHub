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

Local Const $JadeBrotherhoodBotVersion = "0.1"
Local Const $timeOut = 120000

; ==== Constants ====
Local Const $JadeBrotherhoodDervishFarmerSkillbar = "OgejkirMrSqimXfXfbrXaXNX4OA"
Local Const $PRunnerHeroSkillbar2 = "OQijEqmMKODbe8O2Efjrx0bWMA"
Local Const $JadeBrotherhoodFarmInformations = "For best results, have :" & @CRLF _
	& "- 16 in earth prayers" & @CRLF _
	& "- 11+ in mysticism" & @CRLF _
	& "- 9+ in scythe mastery (enough to use your scythe)"& @CRLF _
	& "- A scythe 'Guided by Fate', enchantements last 20% longer" & @CRLF _
	& "- Windwalker insignias on all the armor pieces" & @CRLF _
	& "- A superior vigor rune" & @CRLF _
	& "- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership" & @CRLF _
	& "- Golden Eggs"
; Skill numbers declared to make the code WAY more readable (UseSkill($MarkOfPain  is better than UseSkill(1))
Local Const $Brotherhood_DrunkenMaster = 1
Local Const $Brotherhood_SandShards = 2
Local Const $Brotherhood_MysticVigor = 3
Local Const $Brotherhood_VowOfStrength = 4
Local Const $Brotherhood_ArmorOfSanctity = 5
Local Const $Brotherhood_StaggeringForce = 6
Local Const $Brotherhood_EremitesAttack = 7
Local Const $Brotherhood_DeathsCharge = 8

; Hero Build
Local Const $Brotherhood_VocalWasSogolon = 1
Local Const $Brotherhood_Incoming = 2
Local Const $Brotherhood_FallBack = 3
Local Const $Brotherhood_EnduringHarmony = 4
Local Const $Brotherhood_MakeHaste = 5

Local $DeadlockTimer
Local $Deadlocked = False

#Region GUI
Global $Jade_Brotherhood_Farm_Setup = False

;~ Main method to farm Raptors
Func JadeBrotherhoodFarm($STATUS)
	If $STATUS <> "RUNNING" Then Return

	If ($Deadlocked OR ((CountSlots() < 5) AND (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED))) Then
		Out("Inventory full, pausing.")
		$Deadlocked = False
		;Inventory()
		$STATS_MAP["success_code"] = 2
		Return
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

	$STATS_MAP["success_code"] = JadeBrotherhoodFarmLoop()
	
	If $Deadlocked Then $STATS_MAP["success_code"] = 1
	
	Return
EndFunc


Func SetupJadeBrotherhoodFarm()
	Out("Setting up farm")
	GUICtrlSetState($LootBlueItemsCheckbox, $GUI_CHECKED)
	GUICtrlSetState($LootPurpleItemsCheckbox, $GUI_CHECKED)
	; TODO Display your Asura Title for the energy boost.
	;SetDisplayedTitle(0x29)
	SwitchMode($ID_HARD_MODE)
	AddHero($ID_General_Morgahn)
	MoveTo(16106, 18497)
	Move(16481, 19378)
	Move(16551, 19860)
	Sleep(1000)
	UseHeroSkill(1, $Brotherhood_Incoming)
	WaitMapLoading($ID_Bukdek_Byway)
	Sleep(Random(50, 80))
	UseHeroSkill(1, $Brotherhood_Incoming)
	Move(-13960, -11700)
	Sleep(1000)
	WaitMapLoading($ID_The_Marketplace)
	Out("Resign preparation complete")
EndFunc



;~ Farm loop
Func JadeBrotherhoodFarmLoop()
	Local $lme = GetAgentByID(-2)
	If Not $RenderingEnabled Then ClearMemory()
	Out("Abandonning quest")
	AbandonQuest(457)
	Out("Exiting to Bukdek Byway")
	Move(16551, 19860)
	Sleep(GetPing() + 1000)
	WaitMapLoading($ID_Bukdek_Byway)
	Sleep(Random(50, 80))
	MoveToSeparationWithHero()
	$DeadlockTimer = TimerInit()
	TalkToAiko()
	If GetIsDead($lme) Then Return BackToTheMarketplace(1)
	WaitForBall()
	If GetIsDead($lme) Then Return BackToTheMarketplace(1)
	KillJadeBrotherhood()
	If GetIsDead($lme) Then Return BackToTheMarketplace(1)

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		Sleep(Random(50, 80))
		Out("Looting")
		PickUpItems()
	EndIf

	Return BackToTheMarketplace(0)
EndFunc


Func MoveToSeparationWithHero()
	Local $lme = GetAgentByID(-2)
	Out("Moving to crossing")
	UseHeroSkill(1, $Brotherhood_VocalWasSogolon)
	Sleep(Random(50, 80))
	UseHeroSkill(1, $Brotherhood_Incoming)
	Sleep(Random(50, 80))
	CommandAll(-10475, -9685)
	Sleep(Random(50, 80))
	Move(-10475, -9685)
	Sleep(Random(6500, 7500))
	UseHeroSkill(1, $Brotherhood_EnduringHarmony, -2)
	Sleep(Random(1400, 1600))
	UseHeroSkill(1, $Brotherhood_MakeHaste, -2)
	Sleep(Random(50, 80))
	Move(-11983, -6261, 40)
	Sleep(Random(300, 400))
	Out("Moving Hero away")
	CommandAll(-8447, -10099)
	Sleep(7000)
EndFunc


Func TalkToAiko()
	Out("Talking to Aiko")
	GoNearestNPCToCoords(-13923, -5098)
	Sleep(Random(800, 1200))
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
	Local $target, $foesBalled = 0
	Local $niceBall = False
	While Not($foesBalled == 8 And $niceBall)
		$niceBall = $foesBalled == 8 ? True : False
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $timeOut Then Return
		Out("Not yet : " & $foesBalled)
		RndSleep(4500)
		$target = GetNearestEnemyToCoords(-13262, -5486)
		$foesBalled = GetNumberOfFoesInRangeOfAgent($target, 360)
	WEnd
EndFunc

Func KillJadeBrotherhood()
	Local $lMe = GetAgentByID(-2)
	Local $EnchantmentsTimer
	Local $target

	If GetIsDead($lme) Then Return

	Out("Clearing Jade Brotherhood")
	UseSkillEx($Brotherhood_DrunkenMaster, $lMe)
	Sleep(Random(40, 60))
	UseSkillEx($Brotherhood_SandShards, $lMe)
	Sleep(Random(40, 60))
	
	$target = GetNearestEnemyToCoords(-13262, -5486)
	$target = TargetMobInCenter($target, 360)
	GetAlmostInRangeOfAgent($target)
	UseSkillEx($Brotherhood_MysticVigor, $lMe)
	Sleep(GetPing() + Random(250, 300))
	UseSkillEx($Brotherhood_ArmorOfSanctity, $lMe)
	Sleep(GetPing() + Random(250, 300))
	UseSkillEx($Brotherhood_VowOfStrength, $lMe)
	Sleep(GetPing() + Random(450, 500))
	$EnchantmentsTimer = TimerInit()
	While IsRecharged($Brotherhood_DeathsCharge)
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $timeOut Then Return
		UseSkillEx($Brotherhood_DeathsCharge, $target)
		Sleep(Random(40, 60))
	WEnd
	UseSkillEx($Brotherhood_StaggeringForce, $lMe)
	Sleep(Random(40, 60))
	UseSkillEx($Brotherhood_EremitesAttack, $target)
	While IsRecharged($Brotherhood_EremitesAttack)
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $timeOut Then Return
		UseSkillEx($Brotherhood_EremitesAttack, $target)
		Sleep(Random(40, 60))
	WEnd
	
	While GetNumberOfFoesInRangeOfAgent(-2, 1250) > 0
		If GetIsDead($lme) Or TimerDiff($DeadlockTimer) > $timeOut Then Return
		If GetEnergy($lMe) >= 6 And IsRecharged($Brotherhood_SandShards) Then
			UseSkillEx($Brotherhood_SandShards, $lMe)
			Sleep(Random(40, 60))
		EndIf
		If GetEnergy($lMe) >= 6 And TimerDiff($EnchantmentsTimer) > 18000 Then
			UseSkillEx($Brotherhood_VowOfStrength, $lMe)
			Sleep(GetPing() + Random(250, 300))
			UseSkillEx($Brotherhood_MysticVigor, $lMe)
			Sleep(GetPing() + Random(250, 300))
			$EnchantmentsTimer = TimerInit()
		EndIf
		If GetEnergy($lMe) >= 3 And IsRecharged($Brotherhood_ArmorOfSanctity) Then
			UseSkillEx($Brotherhood_ArmorOfSanctity, $lMe)
			Sleep(GetPing() + Random(250, 300))
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
	Sleep(3400)
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


Func GetNumberOfFoesInRangeOfAgent($aAgent, $aRange)
	Local $lAgent, $lDistance
	Local $lCount = 0

	If Not IsDllStruct($aAgent) Then $aAgent = GetAgentByID($aAgent)

	For $i = 1 To GetMaxAgents()
		$lAgent = GetAgentByID($i)
		;If BitAND(DllStructGetData($lAgent, 'typemap'), 262144) Then ContinueLoop
		If DllStructGetData($lAgent, 'Type') <> 0xDB Then ContinueLoop
		If DllStructGetData($lAgent, 'Allegiance') <> 3 Then ContinueLoop
		If DllStructGetData($lAgent, 'HP') <= 0 Then ContinueLoop
		If BitAND(DllStructGetData($lAgent, 'Effects'), 0x0010) > 0 Then ContinueLoop
		$lDistance = GetDistance($aAgent, $lAgent)
		If $lDistance > $aRange Then ContinueLoop
		$lCount += 1
	Next

	Return $lCount
EndFunc