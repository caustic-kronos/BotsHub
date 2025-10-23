#CS ===========================================================================
; Author: Crux
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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils-Debugger.au3'

; ==== Constants ====
Global Const $GemstoneFarmSkillbar = 'OQBCAswDPVP/DMd5Zu2Nd6B'
Global Const $GemstoneHeroSkillbar = 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Gemstone_Farm'
Global Const $GemstoneFarmInformations = 'Requirements:' & @CRLF _
	& '- Access to mallyx (finished all 4 doa parts)' & @CRLF _
	& '- Strong hero build' &@CRLF _
	& '- Hero order: 1. ST Ritu, 2. SoS Ritu, 3. BiP Necro, Rest' &@CRLF _
	& ' ' & @CRLF _
	& 'Equipment:' & @CRLF _
	& '- 5x Artificer Rune' & @CRLF _
	& '- 1x Superior Vigor ' & @CRLF _
	& '- 1x Minor Fast Casting + 1x Major Fast Casting' & @CRLF _
	& '- 2x Vitae ' & @CRLF _
	& '- 40/40 DOM Set' & @CRLF _
	& '- Character Stats: 14 Fast Casting, 13 Domination Magic' & @CRLF _
; Average duration ~ 12m30sec
Global Const $GEMSTONE_FARM_DURATION = (12 * 60 + 30) * 1000

;=== Configuration / Globals ===
Global Const $StartX = -3606
Global Const $StartY = -5347
Global Const $FightDist = 1500

Global $GemstoneFarmSetup = False

;~ Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction) is better than UseSkill(1))
Global Const $Gem_Symbolic_Celerity 	= 1
Global Const $Gem_Symbolic_Posture 		= 2
Global Const $Gem_Keystone_Signet 		= 3
Global Const $Gem_Unnatural_Signet 		= 4
Global Const $Gem_Signet_Of_Clumsiness 	= 5
Global Const $Gem_Signet_Of_Disruption 	= 6
Global Const $Gem_Wastrels_Demise 		= 7
Global Const $Gem_Mistrust 				= 8

Global Const $Gem_SkillsArray =		[$Gem_Symbolic_Celerity, $Gem_Symbolic_Posture, $Gem_Keystone_Signet, $Gem_Unnatural_Signet, $Gem_Signet_Of_Clumsiness, $Gem_Signet_Of_Disruption, $Gem_Wastrels_Demise, $Gem_Mistrust]
Global Const $Gem_SkillsCostsArray =	[15,					10,						0,					0,						0,							0,							5,					10]
Global Const $gemSkillCostsMap = MapFromArrays($Gem_SkillsArray, $Gem_SkillsCostsArray)

Global Const $ID_ZhellixAgent = 15
Global Const $ID_Zhellix = 5221
Global Const $ID_Dryder = 5215
Global Const $ID_Dreamer = 5216
Global Const $ID_AnurKi = 5169


;~ Main Gemstone farm entry function
Func GemstoneFarm($STATUS)
	If Not $GemstoneFarmSetup Then
		SetupGemstoneFarm()
		$GemstoneFarmSetup = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	GemstoneFarmLoop()

	Return 0
EndFunc


;~ Gemstone farm setup
Func SetupGemstoneFarm()
	Info('Setting up farm')
	SwitchMode($ID_NORMAL_MODE)
	Info('Preparations complete')
EndFunc


;~ Gemstone farm loop
Func GemstoneFarmLoop()
	; Ensure correct map
	If GetMapID() <> $ID_Gate_Of_Anguish Then
		DistrictTravel($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	EndIf
	TalkToZhellix()
	WalkToSpot()
	Defend()
EndFunc


;~ Talking to Zhellix
Func TalkToZhellix()
	Local $z = GetNearestNpcToCoords(6086, -13397)
	ChangeTarget($z)
	GoToNPC($z)
	Dialog(0x84)
	WaitMapLoading()
EndFunc


;~ Getting into positions
Func WalkToSpot()
	Sleep(2000)
	CommandHero(3, -3190, -4928)
	CommandHero(2, -3050, -5304)
	CommandAll(-3449, -5229)
	MoveTo($StartX, $StartY)

	UseConsumable($ID_Legionnaire_Summoning_Crystal, False)
EndFunc

;~ Check if run failed
Func DoARunFailed()
	If GetIsDead($ID_ZhellixAgent) Or Not HasRezMemberAlive() Then Return True
	Return False
EndFunc


;~ Return to outpost in case of failure
Func ResignAndReturnToGate()
	If GetIsDead($ID_ZhellixAgent) Then
		Warn('Zhellix died.')
	ElseIf GetIsDead() Then
		Warn('Player died')
	EndIf
	DistrictTravel($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	Return 1
EndFunc

;~ Defending function
Func Defend()
	Info('Defending...')
	Sleep(5000)

	While ZhellixWaiting()
		If DoARunFailed() Then Return ResignAndReturnToGate()
		Sleep(1000)
		Fight()
		PickUpItems()
		MoveTo($StartX, $StartY)
	WEnd
EndFunc


;~ Fighting!
Func Fight()
	Info('Fighting!')
	If GetIsDead() Then Return
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	If GetDistance(GetMyAgent(), $target) < $FightDist And DllStructGetData($target, 'ID') <> 0 Then GemKill()
EndFunc


;~ More fighting!
Func GemKill()
	If GetIsDead() Then Return
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	Local $distance = 0
	While Not GetIsDead() And DllStructGetData($target, 'ID') <> 0 And $distance < $FightDist
		If GetMapLoading() == 2 Then Disconnected()

		Local $targetsInRangeArr = GetFoesInRangeOfAgent(GetMyAgent(), 1700, IsDreamerDryderOrAnurKi)
		Local $specialTarget = False

		If IsArray($targetsInRangeArr) And UBound($targetsInRangeArr) > 0 Then
			$target = $targetsInRangeArr[0]
			$specialTarget = True
		EndIf

		;— if no special target, fall back
		If $target = 0 Then
			$target = GetNearestEnemyToAgent(GetMyAgent())
			$distance = GetDistance($target, GetMyAgent())
		EndIf

		If DllStructGetData($target, 'ID') <> 0 And $distance < $FightDist Then
			ChangeTarget($target)
			RandomSleep(150)
			CallTarget($target)
			RandomSleep(150)
			Attack($target)
			RandomSleep(150)
		ElseIf DllStructGetData($target, 'ID') = 0 Or $distance > $FightDist Or GetIsDead() Then
			ExitLoop
		EndIf

		For $i = 0 To UBound($Gem_SkillsArray) - 1
			Local $targetHp = DllStructGetData(GetCurrentTarget(), 'HP')
			If GetIsDead() Then ExitLoop
			If $targetHp = 0 Then ExitLoop
			If $distance > $FightDist And Not $specialTarget Then ExitLoop

			Local $skillPos = $Gem_SkillsArray[$i]
			Local $recharge = DllStructGetData(GetSkillbarSkillRecharge($skillPos, 0), 0)
			Local $energy = GetEnergy()

			If $recharge = 0 And $energy >= $gemSkillCostsMap[$skillPos] Then
				UseSkillEx($skillPos, $target)
				RandomSleep(500)
			EndIf
		Next
	WEnd

	If Not GetIsDead() Then MoveTo($StartX, $StartY)
EndFunc


;~ Utility to find priority targets
Func IsDreamerDryderOrAnurKi($agent)
	Local $modelType = DllStructGetData($agent, 'AgentModelType')
	Return $modelType == $ID_Dryder Or $modelType == $ID_Dreamer Or $modelType == $ID_AnurKi
EndFunc


;~ Find Zhellix
Func ZhellixWaiting()
	If GetMapLoading() == 2 Then
		Disconnected()
	EndIf

	If Not HasRezMemberAlive() Then ResignAndReturnToGate()

	Local $aNPCs = GetNPCsInRangeOfAgent(GetMyAgent(), Null, 1500)

	Local $zhellixAgent = 0
	If IsArray($aNPCs) Then
		For $i = 1 To $aNPCs[0]
			If DllStructGetData($aNPCs[$i], 'PlayerNumber') = $ID_Zhellix Then
				$zhellixAgent = $aNPCs[$i]
				ExitLoop
			EndIf
		Next
	EndIf

	If (IsDllStruct($zhellixAgent) And GetDistance(GetMyAgent(), $zhellixAgent) < 1500) Or CountFoesInRangeOfAgent(GetMyAgent(), 1300) > 0 Then
		Return True
	Else
		Return False
	EndIf
EndFunc