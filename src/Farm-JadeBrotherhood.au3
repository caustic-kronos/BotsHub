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
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

Global Const $JB_Timeout = 120000

; ==== Constants ====
Global Const $JB_Skillbar = 'OgejkirMrSqimXfXfbrXaXNX4OA'
Global Const $JB_Hero_Skillbar = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $JB_FarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in earth prayers' & @CRLF _
	& '- 11+ in mysticism' & @CRLF _
	& '- 9+ in scythe mastery (enough to use your scythe)'& @CRLF _
	& '- A scythe Guided by Fate, enchantements last 20% longer' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership' & @CRLF _
	& '- The Missing Daughter quest not completed'
; Average duration ~ 3m ~ First run is 3m20s with setup
Global Const $JADEBROTHERHOOD_FARM_DURATION = (3 * 60 + 10) * 1000

; You can select which paragon hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
Global Const $JBHeroPartyID = $ID_General_Morgahn
;Global Const $JBHeroPartyID = $ID_Keiran_Thackeray
;Global Const $JBHeroPartyID = $ID_Hayda
Global Const $JBHeroIndex = 1 ; index of first hero party member in team, player index is 0

; Skill numbers declared to make the code WAY more readable (UseSkillEx($MarkOfPain) is better than UseSkillEx(1))
Global Const $JB_DrunkerMaster		= 1
Global Const $JB_SandShards			= 2
Global Const $JB_MysticVigor		= 3
Global Const $JB_VowOfStrength		= 4
Global Const $JB_ArmorOfSanctity	= 5
Global Const $JB_StaggeringForce	= 6
Global Const $JB_EremitesAttack		= 7
Global Const $JB_DeathsCharge		= 8

; Hero Build
Global Const $Brotherhood_Mystic_Healing	= 1
Global Const $Brotherhood_Incoming			= 7
Global Const $Brotherhood_FallBack			= 6
Global Const $Brotherhood_EnduringHarmony	= 2
Global Const $Brotherhood_MakeHaste			= 3

Global $DeadlockTimer
Global $Deadlocked = False

Global $JADE_BROTHERHOOD_FARM_SETUP = False


;~ Main method to farm Jade Brotherhood for q8
Func JadeBrotherhoodFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $JADE_BROTHERHOOD_FARM_SETUP And SetupJadeBrotherhoodFarm() == $FAIL Then Return $PAUSE

	GoToBukdekByway()
	Local $result = JadeBrotherhoodFarmLoop()
	ReturnBackToOutpost($ID_The_Marketplace)
	Return $result
EndFunc


;~ Setup for the jade brotherhood farm
Func SetupJadeBrotherhoodFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_The_Marketplace, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerJadeBrotherhoodFarm() == $FAIL Then Return $FAIL
	If SetupTeamJadeBrotherhoodFarm() == $FAIL Then Return $FAIL

	GoToBukdekByway()
	RandomSleep(50)
	UseHeroSkill($JBHeroIndex, $Brotherhood_Incoming)
	MoveTo(-14000, -11000)
	Move(-14000, -11700)
	RandomSleep(1000)
	WaitMapLoading($ID_The_Marketplace)
	$JADE_BROTHERHOOD_FARM_SETUP = True
	Info('Jade Brotherhood farm set up')
	Return $SUCCESS
EndFunc


Func SetupPlayerJadeBrotherhoodFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Dervish Then
		LoadSkillTemplate($JB_Skillbar)
    Else
    	Warn('Should run this farm as dervish')
    	Return $FAIL
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamJadeBrotherhoodFarm()
	Info('Setting up team')
	LeaveParty()
	Sleep(500 + GetPing())
	AddHero($JBHeroPartyID)
	Sleep(250 + GetPing())
	LoadSkillTemplate($JB_Hero_Skillbar, $JBHeroIndex)
	Sleep(250 + GetPing())
	DisableAllHeroSkills($JBHeroIndex)
	Sleep(500 + GetPing())
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Bukdek Byway
Func GoToBukdekByway()
	TravelToOutpost($ID_The_Marketplace, $DISTRICT_NAME)
	If GetQuestByID(0x1C9) <> Null Then
		Info('Abandoning quest')
		AbandonQuest(0x1C9)
	EndIf
	While GetMapID() <> $ID_Bukdek_Byway
		Info('Moving to Bukdek Byway')
		MoveTo(16106, 18497)
		MoveTo(16500, 19400)
		Move(16551, 19860)
		RandomSleep(1000)
		WaitMapLoading($ID_Bukdek_Byway)
	WEnd
EndFunc


;~ Jade Brotherhood farm loop
Func JadeBrotherhoodFarmLoop()
	If GetMapID() <> $ID_Bukdek_Byway Then Return $FAIL

	RandomSleep(50)
	MoveToSeparationWithHero()
	$DeadlockTimer = TimerInit()
	TalkToAiko()
	If IsPlayerDead() Then Return $FAIL
	WaitForBall()
	If IsPlayerDead() Then Return $FAIL
	KillJadeBrotherhood()
	If IsPlayerDead() Then Return $FAIL

	RandomSleep(1000)

	If IsPlayerAlive() Then
		Info('Looting')
		PickUpItems()
	EndIf

	If $Deadlocked Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Separate from paragon hero - you'll be missed Morgahn
Func MoveToSeparationWithHero()
	Info('Moving to crossing')
	UseHeroSkill($JBHeroIndex, $Brotherhood_Incoming)
	RandomSleep(50)
	CommandAll(-10475, -9685)
	RandomSleep(50)
	Move(-10475, -9685)
	RandomSleep(7500)
	UseHeroSkill($JBHeroIndex, $Brotherhood_EnduringHarmony, GetMyAgent())
	RandomSleep(1500)
	UseHeroSkill($JBHeroIndex, $Brotherhood_MakeHaste, GetMyAgent())
	RandomSleep(50)
	Move(-11983, -6261, 40)
	RandomSleep(300)
	Info('Moving Hero away')
	CommandAll(-8447, -10099)
	RandomSleep(7000)
EndFunc


;~ Talk to Aiko and take her quest
Func TalkToAiko()
	Info('Talking to Aiko')
	GoNearestNPCToCoords(-13923, -5098)
	RandomSleep(1000)
	Info('Taking quest')
	; QuestID 0x1C9 = 457
	AcceptQuest(0x1C9)
	Move(-11303, -6545, 40)
	RandomSleep(4500)
EndFunc


;~ Wait for mobs to be properly balled
Func WaitForBall()
	Info('Waiting for ball')
	If IsPlayerDead() Then Return
	RandomSleep(4500)
	Local $foesBalled = 0, $peasantsAlive = 100, $countsDidNotChange = 0
	Local $prevFoesBalled = 0, $prevPeasantsAlive = 100
	; Aiko counts
	While ($foesBalled <> 8 Or $peasantsAlive > 1)
		If IsPlayerDead() Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		Debug('Foes balled : ' & $foesBalled)
		Debug('Peasants alive : ' & $peasantsAlive)
		RandomSleep(4500)
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


;~ Kill the jade brotherhood group
Func KillJadeBrotherhood()
	Local $EnchantmentsTimer
	Local $target

	If IsPlayerDead() Then Return

	Info('Clearing Jade Brotherhood')
	UseSkillEx($JB_DrunkerMaster)
	RandomSleep(50)
	UseSkillEx($JB_SandShards)
	RandomSleep(50)

	$target = GetNearestEnemyToCoords(-13262, -5486)
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_ADJACENT)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	GetAlmostInRangeOfAgent($target)
	UseSkillEx($JB_MysticVigor)
	RandomSleep(300)
	UseSkillEx($JB_ArmorOfSanctity)
	RandomSleep(300)
	UseSkillEx($JB_VowOfStrength)
	RandomSleep(500)
	$EnchantmentsTimer = TimerInit()
	While IsRecharged($JB_DeathsCharge)
		If IsPlayerDead() Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		UseSkillEx($JB_DeathsCharge, $target)
		RandomSleep(50)
	WEnd
	UseSkillEx($JB_StaggeringForce)
	RandomSleep(50)
	UseSkillEx($JB_EremitesAttack, $target)
	While IsRecharged($JB_EremitesAttack)
		If IsPlayerDead() Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		UseSkillEx($JB_EremitesAttack, $target)
		RandomSleep(50)
	WEnd

	While CountFoesInRangeOfAgent(GetMyAgent(), 1250) > 0
		If IsPlayerDead() Or TimerDiff($DeadlockTimer) > $JB_Timeout Then Return
		If GetEnergy() >= 6 And IsRecharged($JB_SandShards) Then
			UseSkillEx($JB_SandShards)
			RandomSleep(50)
		EndIf
		If GetEnergy() >= 6 And TimerDiff($EnchantmentsTimer) > 18000 Then
			UseSkillEx($JB_VowOfStrength)
			RandomSleep(300)
			UseSkillEx($JB_MysticVigor)
			RandomSleep(300)
			$EnchantmentsTimer = TimerInit()
		EndIf
		If GetEnergy() >= 3 And IsRecharged($JB_ArmorOfSanctity) Then
			UseSkillEx($JB_ArmorOfSanctity)
			RandomSleep(300)
		EndIf
		$target = GetNearestEnemyToAgent(GetMyAgent())
		RandomSleep(250)
		ChangeTarget($target)
		Attack($target)
		RandomSleep(250)
	WEnd
EndFunc