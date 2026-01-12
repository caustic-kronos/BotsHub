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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Debugger.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
;Global Const $GEMSTONES_MESMER_SKILLBAR = 'OQBCAswDPVP/DMd5Zu2Nd6B'
Global Const $GEMSTONES_MESMER_SKILLBAR = 'OQBDAcMCT7iTPNB/AmO5ZcNyiA'
Global Const $GEMSTONES_HERO_1_SKILLBAR = 'OQNUAUBPwmMnAcqpb6lDyAXA0I'
Global Const $GEMSTONES_HERO_2_SKILLBAR = 'OQNUAUBPwmMnAcqpb6lDyAXA0I'
Global Const $GEMSTONES_HERO_3_SKILLBAR = 'OQNUAUBPwmMnAcqpb6lDyAXA0I'
Global Const $GEMSTONES_HERO_4_SKILLBAR = 'OAljUwGopSUBHVyBoBVVbh4B1YA'
Global Const $GEMSTONES_HERO_5_SKILLBAR = 'OAhjUwGYoSUBHVoBbhVVWbTODTA'
Global Const $GEMSTONES_HERO_6_SKILLBAR = 'OAhjQoGYIP3hhWVVaO5EeDzxJ'
Global Const $GEMSTONES_HERO_7_SKILLBAR = 'OACiAyk8gNtePuwJ00ZOPLYA'
Global Const $GEMSTONES_FARM_INFORMATIONS = 'Requirements:' & @CRLF _
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
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Gemstone_Farm' & @CRLF
; Average duration ~ 12m30sec
Global Const $GEMSTONES_FARM_DURATION = (12 * 60 + 30) * 1000
Global Const $MAX_GEMSTONES_FARM_DURATION = 25 * 60 * 1000

;=== Configuration / Globals ===
Global Const $GEMSTONES_DEFEND_X = -3432
Global Const $GEMSTONES_DEFEND_Y = -5564

; Skill numbers declared to make the code WAY more readable (UseSkill($SKILL_CONVICTION) is better than UseSkill(1))
Global Const $GEM_SYMBOLIC_CELERITY		= 1
Global Const $GEM_SYMBOLIC_POSTURE		= 2
Global Const $GEM_KEYSTONE_SIGNET		= 3
Global Const $GEM_UNNATURAL_SIGNET		= 4
Global Const $GEM_SIGNET_OF_CLUMSINESS	= 5
Global Const $GEM_SIGNET_OF_DISRUPTION	= 6
Global Const $GEM_WASTRELS_DEMISE		= 7
Global Const $GEM_MISTRUST				= 8

Global Const $GEM_SKILLS_ARRAY			= [$GEM_SYMBOLIC_CELERITY,	$GEM_SYMBOLIC_POSTURE,	$GEM_KEYSTONE_SIGNET,	$GEM_UNNATURAL_SIGNET,	$GEM_SIGNET_OF_CLUMSINESS,	$GEM_SIGNET_OF_DISRUPTION,	$GEM_WASTRELS_DEMISE,	$GEM_MISTRUST]
Global Const $GEM_SKILLS_COSTS_ARRAY	= [15,						10,						0,						0,						0,							0,							5,						10]
Global Const $GEM_SKILLS_COSTS_MAP		= MapFromArrays($GEM_SKILLS_ARRAY, $GEM_SKILLS_COSTS_ARRAY)

Global $gemstones_fight_options	= CloneDictMap($Default_MoveAggroAndKill_Options)
; == $RANGE_EARSHOT * 1.5 ; extended range to also target special foes, which can stand far away
$gemstones_fight_options.Item('fightRange')			= 1500
; heroes will be flagged before fight to defend the start location
$gemstones_fight_options.Item('flagHeroesOnFight')	= False
$gemstones_fight_options.Item('priorityMobs')			= True
$gemstones_fight_options.Item('skillsCostMap')		= $GEM_SKILLS_COSTS_MAP
$gemstones_fight_options.Item('lootInFights')			= False
; there are no chests in Ebony Citadel of Mallyx location
$gemstones_fight_options.Item('openChests')			= False

; in ebony citadel of Mallyx location, the agent ID of Zhellix is always assigned to 15, when party has 8 members (can be accessed in GWToolbox)
Global Const $AGENTID_ZHELLIX = 15
Global Const $MODELID_ZHELLIX = 5272

Global $gemstones_farm_setup = False

;~ Main Gemstones farm entry function
Func GemstonesFarm()
	If Not $gemstones_farm_setup Then SetupGemstonesFarm()

	Local $result = GemstonesFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared all 19 waves')
	If $result == $FAIL Then Info('Could not clear all 19 waves')
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Return $result
EndFunc


;~ Gemstones farm setup
Func SetupGemstonesFarm()
	Info('Setting up farm')
	; the 4 DoA farm areas have the same map ID as Gate of Anguish outpost (474)
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Else
		ResignAndReturnToOutpost()
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	SetupPlayerGemstonesFarm()
	; Zhellix agent ID will be lower if team size is lower than 8, therefore checking for fail
	If TrySetupTeamUsingGUISettings() == $FAIL Then Return $FAIL
	$gemstones_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerGemstonesFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
	ElseIf DllStructGetData(GetMyAgent(), 'Primary') == $ID_MESMER Then
		Info('Player''s profession is mesmer. Loading up recommended mesmer build automatically')
		LoadSkillTemplate($GEMSTONES_MESMER_SKILLBAR)
	Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
	EndIf
	Sleep(250 + GetPing())
EndFunc


;~ Gemstones farm loop
Func GemstonesFarmLoop()
	If TalkToZhellix() == $FAIL Then Return $FAIL
	WalkToSpotGemstonesFarm()
	UseConsumable($ID_LEGIONNAIRE_SUMMONING_CRYSTAL, False)
	Sleep(2000)
	If Defend() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Talking to Zhellix
Func TalkToZhellix()
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then Return $FAIL
	Local $Zhellix = GetNearestNpcToCoords(6081, -13314)
	ChangeTarget($Zhellix)
	GoToNPC($Zhellix)
	Dialog(0x84)
	WaitMapLoading($ID_THE_EBONY_CITADEL_OF_MALLYX)
	Return GetMapID() == $ID_THE_EBONY_CITADEL_OF_MALLYX? $SUCCESS : $FAIL
EndFunc


;~ Getting into positions
Func WalkToSpotGemstonesFarm()
	Info('Moving to defend position')
	; go close to Zhellix to let him start erforming the ritual, Null for no interaction
	GoToAgent(GetAgentByID($AGENTID_ZHELLIX), Null)
	MoveTo($GEMSTONES_DEFEND_X, $GEMSTONES_DEFEND_Y)
	; spread out all heroes to avoid AoE damage, distance a bit larger than nearby range = 240, and still quite compact formation
	FanFlagHeroes(260)
EndFunc


;~ Defending function
Func Defend()
	Info('Defending...')

	While IsZhellixPerformingRitual()
		;If GetMapLoading() == 2 Then Disconnected()
		If CheckStuck('Gemstones fight', $MAX_GEMSTONES_FARM_DURATION) == $FAIL Then Return $FAIL
		If IsDoARunFailed() Then Return $FAIL
		Sleep(1000)
		KillFoesInArea($gemstones_fight_options)
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
		MoveTo($GEMSTONES_DEFEND_X, $GEMSTONES_DEFEND_Y)
	WEnd
	; if ritual completed then successful run
	Return IsDoARunFailed()? $FAIL : $SUCCESS
EndFunc


;~ Check if run failed
Func IsDoARunFailed()
	Local $Zhellix = GetAgentByID($AGENTID_ZHELLIX)
	If GetIsDead($Zhellix) Then Warn('Zhellix dead')
	If IsPlayerDead() Then Warn('Player dead')
	Return GetIsDead($Zhellix) Or Not HasRezMemberAlive()
EndFunc


;~ While Zhellix stays within area of citadel's entrance and performs opening ritual then farm run is still on
Func IsZhellixPerformingRitual()
	If IsDoARunFailed() Then Return False

	Local $me = GetMyAgent()
	Local $Zhellix = GetAgentByID($AGENTID_ZHELLIX)
	Local $foesCount = CountFoesInRangeOfAgent($me, $gemstones_fight_options.Item('fightRange'))
	; After all waves are finished, Zhellix leaves citadel's entrance area where player is, which makes below check False
	Return (Not GetIsDead($Zhellix) And GetDistance($me, $Zhellix) < 1500) Or $foesCount > 0
EndFunc