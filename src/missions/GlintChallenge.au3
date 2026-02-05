#CS ===========================================================================
; Author: Gahais
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
;
; This challenge farm is based on below article
https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Glint%27s_Challenge_Farm
;
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $GLINT_CHALLENGE_INFORMATIONS = 'Brotherhood armor farm in Glint''s challenge with 7 hero team' & @CRLF _
	& 'It is advisable to unequip staves, wands and focuses from player and heroes so that foes will not cast chaos storm on them:' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Glint%27s_Challenge_Farm'
; Average duration ~ 20m
Global Const $GLINT_CHALLENGE_DURATION = 20 * 60 * 1000
Global Const $MAX_GLINT_CHALLENGE_DURATION = 30 * 60 * 1000

Global Const $GLINT_MESMER_SKILLBAR_OPTIONAL = 'OQBDAcMCT7iTPNB/AmO5ZcNyiA'
Global Const $GLINT_RITU_SOUL_TWISTER_HERO_SKILLBAR = 'OACjAyhDJPYTnp17xFOtmFsLG'
Global Const $GLINT_NECRO_FLESH_GOLEM_HERO_SKILLBAR = 'OAhjUsGWIPAtFBxTaO5EeDzxJ'
Global Const $GLINT_NECRO_HEXER_HERO_SKILLBAR = 'OAVSIYDT1MJgVVmO4UyA5AXAA'
Global Const $GLINT_NECRO_BIP_HERO_SKILLBAR = 'OAVTIYCa05OMHqqmOc6NNHcBA'
Global Const $GLINT_MESMER_PANIC_HERO_SKILLBAR = 'OQBTAWBPshGM9yBmOcaGIudBA'
Global Const $GLINT_MESMER_INEPTITUDE_HERO_SKILLBAR = 'OQNEAbwj1C9CgAmnRCwBlBE3gGB'

Global Const $GLINT_HERO_RITU_SOULTWISTER		= 1
Global Const $GLINT_HERO_NECRO_FLESHGOLEM		= 2
Global Const $GLINT_HERO_NECRO_HEXER			= 3
Global Const $GLINT_HERO_NECRO_BIP				= 4
Global Const $GLINT_HERO_MESMER_PANIC			= 5
Global Const $GLINT_HERO_MESMER_INEPTITUDE_1	= 6
Global Const $GLINT_HERO_MESMER_INEPTITUDE_2	= 7

;Global Const $GLINT_CHALLENGE_DEFEND_X = -4700
Global Const $GLINT_CHALLENGE_DEFEND_X = -4185
;Global Const $GLINT_CHALLENGE_DEFEND_Y = 5
Global Const $GLINT_CHALLENGE_DEFEND_Y = -75

; in Glint Challenge location, the agent ID of Baby Dragon is always assigned to 19, when party has 8 members (can be accessed in GWToolbox)
Global Const $AGENTID_BABY_DRAGON = 19
Global Const $MODELID_BABY_DRAGON = 1816
Global Const $BROTHERHOOD_CHEST_X = -3184
Global Const $BROTHERHOOD_CHEST_Y = 908
Global Const $BROTHERHOOD_CHEST_GADGETID = 9157

Global $glint_challenge_fight_options = CloneDictMap($default_moveaggroandkill_options)
$glint_challenge_fight_options.Item('fightRange')			= 1500
; heroes will be flagged before fight to defend the start location
$glint_challenge_fight_options.Item('flagHeroesOnFight')	= False
$glint_challenge_fight_options.Item('lootInFights')			= False
; there are no chests in Glint Challenge location
$glint_challenge_fight_options.Item('openChests')			= False

Global $glint_challenge_setup = False

;~ Main loop for the Mysterious armor farm
Func GlintChallengeFarm()
	If Not $glint_challenge_setup And GlintChallengeSetup() == $FAIL Then Return $PAUSE

	EnterGlintChallengeMission()
	Local $result = GlintChallenge()
	; wait 15 seconds to ensure end mission timer of 15 seconds has elapsed
	Sleep(15000)
	TravelToOutpost($ID_CENTRAL_TRANSFER_CHAMBER, $district_name)
	Return $result
EndFunc


Func GlintChallengeSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_CENTRAL_TRANSFER_CHAMBER, $district_name)
	SetDisplayedTitle($ID_DWARF_TITLE)
	SwitchMode($ID_NORMAL_MODE)
	If SetupTeamGlintChallengeFarm() == $FAIL Then Return $FAIL
	$glint_challenge_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupTeamGlintChallengeFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up using recommended team build')
	LeaveParty()
	RandomSleep(500)
	AddHero($ID_XANDRA)
	AddHero($ID_MASTER_OF_WHISPERS)
	AddHero($ID_OLIAS)
	AddHero($ID_LIVIA)
	AddHero($ID_GWEN)
	AddHero($ID_NORGU)
	AddHero($ID_RAZAH)
	RandomSleep(500)
	LoadSkillTemplate($GLINT_RITU_SOUL_TWISTER_HERO_SKILLBAR, $GLINT_HERO_RITU_SOULTWISTER)
	LoadSkillTemplate($GLINT_NECRO_FLESH_GOLEM_HERO_SKILLBAR, $GLINT_HERO_NECRO_FLESHGOLEM)
	LoadSkillTemplate($GLINT_NECRO_HEXER_HERO_SKILLBAR, $GLINT_HERO_NECRO_HEXER)
	LoadSkillTemplate($GLINT_NECRO_BIP_HERO_SKILLBAR, $GLINT_HERO_NECRO_BIP)
	LoadSkillTemplate($GLINT_MESMER_PANIC_HERO_SKILLBAR, $GLINT_HERO_MESMER_PANIC)
	LoadSkillTemplate($GLINT_MESMER_INEPTITUDE_HERO_SKILLBAR, $GLINT_HERO_MESMER_INEPTITUDE_1)
	LoadSkillTemplate($GLINT_MESMER_INEPTITUDE_HERO_SKILLBAR, $GLINT_HERO_MESMER_INEPTITUDE_2)
	RandomSleep(500)
	SetHeroBehaviour($GLINT_HERO_RITU_SOULTWISTER, $ID_HERO_FIGHTING)
	SetHeroBehaviour($GLINT_HERO_NECRO_FLESHGOLEM, $ID_HERO_FIGHTING)
	SetHeroBehaviour($GLINT_HERO_NECRO_HEXER, $ID_HERO_FIGHTING)
	SetHeroBehaviour($GLINT_HERO_NECRO_BIP, $ID_HERO_FIGHTING)
	SetHeroBehaviour($GLINT_HERO_MESMER_PANIC, $ID_HERO_FIGHTING)
	SetHeroBehaviour($GLINT_HERO_MESMER_INEPTITUDE_1, $ID_HERO_FIGHTING)
	SetHeroBehaviour($GLINT_HERO_MESMER_INEPTITUDE_2, $ID_HERO_FIGHTING)
	RandomSleep(500)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
		; Baby dragon agent ID will be lower if team size is lower than 8
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func EnterGlintChallengeMission()
	TravelToOutpost($ID_CENTRAL_TRANSFER_CHAMBER, $district_name)
	While GetMapID() <> $ID_GLINTS_CHALLENGE
		Info('Entering Glint mission')
		;MoveTo(300, 1500)
		MoveTo(2408, 3560)
		GoToNPC(GetNearestNPCToCoords(2480, 3586))
		Info('Talking to NPC')
		Sleep(1000)
		Dialog(0x86)
		Sleep(1000)
		WaitMapLoading($ID_GLINTS_CHALLENGE, 10000, 10000)
	WEnd
EndFunc


;~ Cleaning Glint challenge function
Func GlintChallenge()
	If GetMapID() <> $ID_GLINTS_CHALLENGE Then Return $FAIL
	WalkToSpotGlintChallenge()
	Info('Defending baby dragon')
	Sleep(5000)

	; Variables used to detect pathological situation in which single foes might be stuck in eternal combat loop with dwarven npcs far from baby dragon and the team
	Local $glitchTimer, $glitchTimerStarted = False
	; fight until Brotherhood chest spawns or until team or baby dragon is dead
	While Not IsBrotherhoodChestSpawned()
		If CheckStuck('Glint challenge fight', $MAX_GLINT_CHALLENGE_DURATION) == $FAIL Then Return $FAIL
		Sleep(5000)
		KillFoesInArea($glint_challenge_fight_options)
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)
		If CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS) <= 3 Then
			If Not $glitchTimerStarted Then
				$glitchTimer = TimerInit()
				$glitchTimerStarted = True
			ElseIf TimerDiff($glitchTimer) > 150000 Then ; 2,5 minutes max time for detection of pathological situation
				; in case pathological situation happened, make a full sweep with team around baby dragon's location
				SweepAroundBabyDragonLocation()
				$glitchTimerStarted = False
			EndIf
		Else
			$glitchTimerStarted = False
		EndIf
		MoveTo($GLINT_CHALLENGE_DEFEND_X, $GLINT_CHALLENGE_DEFEND_Y)
		If IsPlayerAndPartyWiped() Then Return $FAIL
		If GetIsDead(GetAgentByID($AGENTID_BABY_DRAGON)) Then Return $FAIL
	WEnd

	CancelAllHeroes()

	Info('Looting Chest of the Brotherhood')
	; Tripled to secure the looting of chest
	For $i = 1 To 3
		MoveAggroAndKill($BROTHERHOOD_CHEST_X, $BROTHERHOOD_CHEST_Y)
		Local $brotherhoodChest = ScanForChests($RANGE_COMPASS, True, $BROTHERHOOD_CHEST_X, $BROTHERHOOD_CHEST_Y, $BROTHERHOOD_CHEST_GADGETID)
		ChangeTarget($brotherhoodChest)
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next

	; wait 2 minutes for end mission timer to fully elapse
	Sleep(120000)
	WaitMapLoading($ID_CENTRAL_TRANSFER_CHAMBER)
	Return $SUCCESS
EndFunc


;~ Getting into positions
Func WalkToSpotGlintChallenge()
	Info('Moving to defend position')
	MoveTo($GLINT_CHALLENGE_DEFEND_X, $GLINT_CHALLENGE_DEFEND_Y)
	; spread out all heroes to avoid AoE damage, distance a bit larger than nearby range = 240, and still quite compact formation
	;FanFlagHeroes(260)
	CommandHero($GLINT_HERO_RITU_SOULTWISTER, -4300, 125)
	CommandHero($GLINT_HERO_NECRO_FLESHGOLEM, -4278, 346)
	CommandHero($GLINT_HERO_NECRO_HEXER, -3925, -200)
	CommandHero($GLINT_HERO_NECRO_BIP, -4120, 75)
	CommandHero($GLINT_HERO_MESMER_PANIC, -3960, 216)
	CommandHero($GLINT_HERO_MESMER_INEPTITUDE_1, -4065, 310)
	CommandHero($GLINT_HERO_MESMER_INEPTITUDE_2, -3912, -14)
EndFunc


Func SweepAroundBabyDragonLocation()
	CancelAllHeroes()
	MoveAggroAndKill(-3710, -635)
	MoveAggroAndKill(-3020, 20)
	MoveAggroAndKill(-3650, 775)
	MoveAggroAndKill(-4680, 775)
	WalkToSpotGlintChallenge()
EndFunc


Func IsBrotherhoodChestSpawned()
	Return Null <> ScanForChests($RANGE_COMPASS, True, $BROTHERHOOD_CHEST_X, $BROTHERHOOD_CHEST_Y, $BROTHERHOOD_CHEST_GADGETID)
EndFunc