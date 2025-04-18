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
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

Local Const $JB_VERSION = '0.1'
Local Const $JB_Timeout = 120000

; ==== Constants ====
Local Const $JB_Skillbar = 'OgejkirMrSqimXfXfbrXaXNX4OA'
Local Const $JB_Hero_Skillbar = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Local Const $JB_FarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in earth prayers' & @CRLF _
	& '- 11+ in mysticism' & @CRLF _
	& '- 9+ in scythe mastery (enough to use your scythe)'& @CRLF _
	& '- A scythe Guided by Fate, enchantements last 20% longer' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership' & @CRLF _
	& '- The Missing Daughter quest not completed'
; Skill numbers declared to make the code WAY more readable (UseSkillEx($MarkOfPain) is better than UseSkillEx(1))
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
Global $JADE_BROTHERHOOD_FARM_SETUP = False


;~ Main method to farm Jade Brotherhood for q8
Func JadeBrotherhoodFarm($STATUS)
	If GetMapID() <> $ID_The_Marketplace Then
		TravelTo($ID_The_Marketplace)
	EndIf

	If Not $JADE_BROTHERHOOD_FARM_SETUP Then
		SetupJadeBrotherhoodFarm()
		$JADE_BROTHERHOOD_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return

	Return JadeBrotherhoodFarmLoop()
EndFunc


;~ Setup for the jade brotherhood farm
Func SetupJadeBrotherhoodFarm()
	Out('Setting up farm')
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
	Out('Jade Brotherhood farm setup')
EndFunc


;~ Farm loop
Func JadeBrotherhoodFarmLoop()
	Out('Abandonning quest')
	AbandonQuest(457)
	Out('Exiting to Bukdek Byway')
	Move(16551, 19860)
	RndSleep(1000)
	WaitMapLoading($ID_Bukdek_Byway)
	RndSleep(50)
	MoveToSeparationWithHero()
	$DeadlockTimer = TimerInit()
	TalkToAiko()
	If GetIsDead(-2) Then Return BackToTheMarketplace(1)
	WaitForBall()
	If GetIsDead(-2) Then Return BackToTheMarketplace(1)
	KillJadeBrotherhood()
	If GetIsDead(-2) Then Return BackToTheMarketplace(1)

	RndSleep(1000)

	Out('Looting')
	PickUpItems(null, AlsoPickLowReqItems)

	If ($Deadlocked) Then Return BackToTheMarketplace(1)
	Return BackToTheMarketplace(0)
EndFunc


Func MoveToSeparationWithHero()
	Out('Moving to crossing')
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
	Out('Moving Hero away')
	CommandAll(-8447, -10099)
	RndSleep(7000)
EndFunc


Func TalkToAiko()
	Out('Talking to Aiko')
	GoNearestNPCToCoords(-13923, -5098)
	RndSleep(1000)
	Out('Taking quest')
	AcceptQuest(457)
	Move(-11303, -6545, 40)
	RndSleep(4500)
EndFunc


Func WaitForBall()
	Out('Waiting for ball')
	If GetIsDead(-2) Then Return
	RndSleep(4500)
	Local $foesBalled = 0, $peasantsAlive = 100, $countsDidNotChange = 0
	Local $prevFoesBalled = 0, $prevPeasantsAlive = 100
	; Aiko counts
	While ($foesBalled <> 8 Or $peasantsAlive > 1)
		If GetIsDead(-2) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		Out('Foes balled : ' & $foesBalled)
		Out('Peasants alive : ' & $peasantsAlive)
		RndSleep(4500)
		$prevFoesBalled = $foesBalled
		$prevPeasantsAlive = $peasantsAlive
		$foesBalled = CountFoesInRangeOfCoords(-13262, -5486, 450)
		$peasantsAlive = CountAlliesInRangeOfCoords(-13262, -5486, 1600)
		If ($foesBalled = $prevFoesBalled And $peasantsAlive = $prevPeasantsAlive) Then
			$countsDidNotChange += 1
			If $countsDidNotChange > 2 Then Return
		Else
			$countsDidNotChange = 0
		EndIf
	WEnd
EndFunc

Func KillJadeBrotherhood()
	Local $EnchantmentsTimer
	Local $target

	If GetIsDead(-2) Then Return

	Out('Clearing Jade Brotherhood')
	UseSkillEx($JB_DrunkerMaster)
	RndSleep(50)
	UseSkillEx($JB_SandShards)
	RndSleep(50)

	$target = GetNearestEnemyToCoords(-13262, -5486)
	$target = TargetMobInCenter($target, 360)
	GetAlmostInRangeOfAgent($target)
	UseSkillEx($JB_MysticVigor)
	RndSleep(300)
	UseSkillEx($JB_ArmorOfSanctity)
	RndSleep(300)
	UseSkillEx($JB_VowOfStrength)
	RndSleep(500)
	$EnchantmentsTimer = TimerInit()
	While IsRecharged($JB_DeathsCharge)
		If GetIsDead(-2) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		UseSkillEx($JB_DeathsCharge, $target)
		RndSleep(50)
	WEnd
	UseSkillEx($JB_StaggeringForce)
	RndSleep(50)
	UseSkillEx($JB_EremitesAttack, $target)
	While IsRecharged($JB_EremitesAttack)
		If GetIsDead(-2) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		UseSkillEx($JB_EremitesAttack, $target)
		RndSleep(50)
	WEnd

	While CountFoesInRangeOfAgent(-2, 1250) > 0
		If GetIsDead(-2) Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		If GetEnergy(-2) >= 6 And IsRecharged($JB_SandShards) Then
			UseSkillEx($JB_SandShards)
			RndSleep(50)
		EndIf
		If GetEnergy(-2) >= 6 And TimerDiff($EnchantmentsTimer) > 18000 Then
			UseSkillEx($JB_VowOfStrength)
			RndSleep(300)
			UseSkillEx($JB_MysticVigor)
			RndSleep(300)
			$EnchantmentsTimer = TimerInit()
		EndIf
		If GetEnergy(-2) >= 3 And IsRecharged($JB_ArmorOfSanctity) Then
			UseSkillEx($JB_ArmorOfSanctity)
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
	Out('Porting to The Marketplace')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_The_Marketplace)
	Return $success
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