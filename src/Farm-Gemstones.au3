#CS ===========================================================================
; Author: Crux
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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils-Debugger.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $GemstonesFarmSkillbar = 'OQBCAswDPVP/DMd5Zu2Nd6B'
Global Const $GemstonesHeroSkillbar = 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Gemstone_Farm'
Global Const $GemstonesFarmInformations = 'Requirements:' & @CRLF _
	& '- Access to mallyx (finished all 4 doa parts)' & @CRLF _
	& '- Recommended to have maxed out Lightbringer title' & @CRLF _
	& '- Strong hero build' &@CRLF _
	& '- Hero order: 1. ST Ritu, 2. SoS Ritu, 3. BiP Necro, 4. MM Lich Necro, Rest - Energy Surge mesmers' &@CRLF _
	& ' ' & @CRLF _
	& 'Equipment:' & @CRLF _
	& '- 5x Artificer Rune' & @CRLF _
	& '- 1x Superior Vigor ' & @CRLF _
	& '- 1x Minor Fast Casting + 1x Major Fast Casting' & @CRLF _
	& '- 2x Vitae ' & @CRLF _
	& '- 40/40 DOM Set' & @CRLF _
	& '- Character Stats: 14 Fast Casting, 13 Domination Magic' & @CRLF _
	& ' ' & @CRLF _
	& 'Ebony Citadel of Mallyx location is unlocked after defeating all 4 Lords of Anguish in Mallyx the Unyielding quest.' & @CRLF _
	& 'Caution: do not defeat Mallyx the Unyielding, because this will finish the quest which would require to do 4 DoA parts all over again to get access to Ebony Citadel of Mallyx' & @CRLF _
	& 'This bot doesn''t defeat Mallyx the Unyielding, only attempts to defeat all 19 waves, which doesn''t finish the quest' & @CRLF _
; Average duration ~ 12m30sec
Global Const $GEMSTONES_FARM_DURATION = (12 * 60 + 30) * 1000
Global Const $MAX_GEMSTONES_FARM_DURATION = 25 * 60 * 1000
Global $GemstonesFarmTimer = Null

;=== Configuration / Globals ===
Global Const $GemstonesDefendX = -3432
Global Const $GemstonesDefendY = -5564

Global $GEMSTONES_FARM_SETUP = False

;Global Const $GemstonesMesmerSkillBar = 'OQBCAswDPVP/DMd5Zu2Nd6B'
Global Const $GemstonesMesmerSkillBar = 'OQBDAcMCT7iTPNB/AmO5ZcNyiA'

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction) is better than UseSkill(1))
Global Const $Gem_Symbolic_Celerity		= 1
Global Const $Gem_Symbolic_Posture		= 2
Global Const $Gem_Keystone_Signet		= 3
Global Const $Gem_Unnatural_Signet		= 4
Global Const $Gem_Signet_Of_Clumsiness	= 5
Global Const $Gem_Signet_Of_Disruption	= 6
Global Const $Gem_Wastrels_Demise		= 7
Global Const $Gem_Mistrust				= 8

Global Const $Gem_SkillsArray		= [$Gem_Symbolic_Celerity,	$Gem_Symbolic_Posture,	$Gem_Keystone_Signet,	$Gem_Unnatural_Signet,	$Gem_Signet_Of_Clumsiness,	$Gem_Signet_Of_Disruption,	$Gem_Wastrels_Demise,	$Gem_Mistrust]
Global Const $Gem_SkillsCostsArray	= [15,						10,						0,						0,						0,							0,							5,						10]
Global Const $GemSkillsCostsMap = MapFromArrays($Gem_SkillsArray, $Gem_SkillsCostsArray)

Global $GemstonesFightOptions = CloneDictMap($Default_MoveAggroAndKill_Options)
$GemstonesFightOptions.Item('fightRange') 		= 1500 ; == $RANGE_EARSHOT * 1.5 ; extended range to also target special foes, which can stand far away
$GemstonesFightOptions.Item('flagHeroesOnFight') = False ; heroes will be flagged before fight to defend the start location
$GemstonesFightOptions.Item('priorityMobs') 		= True
$GemstonesFightOptions.Item('skillsCostMap') 	= $GemSkillsCostsMap
$GemstonesFightOptions.Item('lootInFights') 		= False ; loot only when no foes are in range
$GemstonesFightOptions.Item('openChests') 		= False ; there are no chests in Ebony Citadel of Mallyx location

Global Const $AgentID_Zhellix = 15 ; in ebony citadel of Mallyx location, the agent ID of Zhellix is always assigned to 15, when party has 8 members (can be accessed in GWToolbox)
Global Const $ModelID_Zhellix = 5221 ; unique Model ID of Zhellix NPC, that can be accessed in GWToolbox


;~ Main Gemstones farm entry function
Func GemstonesFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $GEMSTONES_FARM_SETUP Then SetupGemstonesFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Local $result = GemstonesFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared all 19 waves')
	If $result == $FAIL Then Info('Could not clear all 19 waves')
	TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Gemstones farm setup
Func SetupGemstonesFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Gate_Of_Anguish Then
		TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	Else ; resigning to return to outpost in case when player is in one of 4 DoA farm areas that have the same map ID as Gate of Anguish outpost (474)
		Resign()
		Sleep(4000)
		ReturnToOutpost()
		Sleep(6000)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	SetDisplayedTitle($ID_Lightbringer_Title)
	SetupPlayerGemstonesFarm()
	If SetupTeamGemstonesFarm() == $FAIL Then Return $FAIL
	$GEMSTONES_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerGemstonesFarm()
	Sleep(500 + GetPing())
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		Sleep(500 + GetPing())
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
	ElseIf DllStructGetData(GetMyAgent(), 'Primary') == $ID_Mesmer Then
		Info('Player''s profession is mesmer. Loading up recommended mesmer build automatically')
		LoadSkillTemplate($GemstonesMesmerSkillBar)
    Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
    EndIf
    ;ChangeWeaponSet(2) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamGemstonesFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Automatic team builds setup is disabled. Assuming that team builds are set up manually')
    EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Gemstones farm loop
Func GemstonesFarmLoop()
	If TalkToZhellix() == $FAIL Then Return $FAIL
	WalkToSpotGemstonesFarm()
	$GemstonesFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run
	UseConsumable($ID_Legionnaire_Summoning_Crystal, False)
	If Defend() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Talking to Zhellix
Func TalkToZhellix()
	If GetMapID() <> $ID_Gate_Of_Anguish Then Return $FAIL
	Local $Zhellix = GetNearestNpcToCoords(6081, -13314)
	ChangeTarget($Zhellix)
	GoToNPC($Zhellix)
	Dialog(0x84)
	WaitMapLoading($ID_Ebony_Citadel_Of_Mallyx)
	Return GetMapID() == $ID_Ebony_Citadel_Of_Mallyx? $SUCCESS : $FAIL
EndFunc


;~ Getting into positions
Func WalkToSpotGemstonesFarm()
	Info('Moving to defend position')
	GoToAgent(GetAgentByID($AgentID_Zhellix), Null) ; go close to Zhellix to let him start erforming the ritual, Null for no interaction
	MoveTo($GemstonesDefendX, $GemstonesDefendY) ; move to defending position
	FanFlagHeroes(260) ; spread out all heroes to avoid AoE damage, distance a bit larger than nearby range = 240, and still quite compact formation
EndFunc


;~ Defending function
Func Defend()
	Info('Defending...')
	Sleep(2000)

	While IsZhellixPerformingRitual()
		;If GetMapLoading() == 2 Then Disconnected()
		If TimerDiff($GemstonesFarmTimer) > $MAX_GEMSTONES_FARM_DURATION Then Return $FAIL
		If IsDoARunFailed() Then Return $FAIL
		Sleep(1000)
		KillFoesInArea($GemstonesFightOptions)
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
		MoveTo($GemstonesDefendX, $GemstonesDefendY)
	WEnd
	Return IsDoARunFailed()? $FAIL : $SUCCESS ; if ritual completed then successful run
EndFunc


;~ Check if run failed
Func IsDoARunFailed()
	Local $Zhellix = GetAgentByID($AgentID_Zhellix)
	If GetIsDead($Zhellix) Then Warn('Zhellix dead')
	If IsPlayerDead() Then Warn('Player dead')
	Return GetIsDead($Zhellix) Or Not HasRezMemberAlive()
EndFunc


;~ While Zhellix stays within area of citadel's entrance and performs opening ritual then farm run is still on
Func IsZhellixPerformingRitual()
	If IsDoARunFailed() Then Return False

	Local $me = GetMyAgent()
	Local $Zhellix = GetAgentByID($AgentID_Zhellix)
	Local $foesCount = CountFoesInRangeOfAgent($me, $GemstonesFightOptions.Item('fightRange'))
	; After all waves are finished, Zhellix leaves citadel's entrance area where player is, which makes below check False
	Return (Not GetIsDead($Zhellix) And GetDistance($me, $Zhellix) < 1500) Or $foesCount > 0
EndFunc