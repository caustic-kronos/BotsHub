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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $GlintChallengeInformations = 'Brotherhood armor farm in Glint''s challenge with 7 hero team'  & @CRLF _
	& 'It is advisable to unequip staves, wands and focuses from player and heroes so that foes won''t cast chaos storm on them:' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Glint%27s_Challenge_Farm'
; Average duration ~ 20m
Global Const $GLINT_CHALLENGE_DURATION = 20 * 60 * 1000
Global Const $MAX_GLINT_CHALLENGE_DURATION = 40 * 60 * 1000
Global $GlintChallengeTimer = Null
Global $GLINT_CHALLENGE_SETUP = False

Global Const $GlintRituSoulTwisterHeroSkillBar = 'OACjAyhDJPYTnp17xFOtmFsLG'
Global Const $GlintNecroFleshGolemHeroSkillBar = 'OAhjUsGWIPAtFBxTaO5EeDzxJ'
Global Const $GlintNecroHexerHeroSkillBar = 'OAVSIYDT1MJgVVmO4UyA5AXAA'
Global Const $GlintNecroBiPHeroSkillBar = 'OAVTIYCa05OMHqqmOc6NNHcBA'
Global Const $GlintMesmerPanicHeroSkillBar = 'OQBTAWBPshGM9yBmOcaGIudBA'
Global Const $GlintMesmerIneptitudeHeroSkillBar = 'OQNEAbwj1C9CgAmnRCwBlBE3gGB'

Global Const $Glint_Hero_Ritu_SoulTwister		= 1
Global Const $Glint_Hero_Necro_FleshGolem		= 2
Global Const $Glint_Hero_Necro_Hexer			= 3
Global Const $Glint_Hero_Necro_BiP				= 4
Global Const $Glint_Hero_Mesmer_Panic			= 5
Global Const $Glint_Hero_Mesmer_Ineptitude_1	= 6
Global Const $Glint_Hero_Mesmer_Ineptitude_2	= 7


;Global Const $GlintChallengeDefendX = -4700
Global Const $GlintChallengeDefendX = -4185
;Global Const $GlintChallengeDefendY = 5
Global Const $GlintChallengeDefendY = -75

Global Const $AgentID_BabyDragon = 19 ; in Glint Challenge location, the agent ID of Baby Dragon is always assigned to 19 (can be accessed in GWToolbox)
Global Const $ModelID_BabyDragon = 1813 ; unique Model ID of Baby Dragon NPC, that can be accessed in GWToolbox

Global $GlintChallengeFightOptions = CloneDictMap($Default_MoveAggroAndKill_Options)
$GlintChallengeFightOptions.Item('fightRange')			= 1250
$GlintChallengeFightOptions.Item('flagHeroesOnFight')	= False ; heroes will be flagged before fight to defend the start location
$GlintChallengeFightOptions.Item('lootInFights')		= False ; loot only when no foes are in range
$GlintChallengeFightOptions.Item('openChests')			= False ; there are no chests in Glint Challenge location


;~ Main loop for the Mysterious armor farm
Func GlintChallengeFarm($STATUS)
	If Not $GLINT_CHALLENGE_SETUP Then GlintChallengeSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	EnterGlintChallengeMission()
	Local $result = GlintChallenge()
	Sleep(15000) ; wait 15 seconds to ensure end mission timer of 15 seconds has elapsed
	TravelToOutpost($ID_Central_Transfer_Chamber, $DISTRICT_NAME)
	Return $result
EndFunc


Func GlintChallengeSetup()
	Info('Setting up farm')
	If GetMapID() <> $ID_Central_Transfer_Chamber Then TravelToOutpost($ID_Central_Transfer_Chamber, $DISTRICT_NAME)
	SetDisplayedTitle($ID_Dwarf_Title)
	SwitchMode($ID_NORMAL_MODE)
	;SetupPlayerGlintChallengeFarm()
	;SetupTeamGlintChallengeFarm()
	$GLINT_CHALLENGE_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerGlintChallengeFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		Sleep(500 + GetPing())
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
    Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamGlintChallengeFarm()
	Info('Setting up recommended team build skill bars automatically ignoring GUI settings')
	LeaveParty()
	Sleep(500 + GetPing())
	AddHero($ID_Xandra)
	AddHero($ID_Master_Of_Whispers)
	AddHero($ID_Olias)
	AddHero($ID_Livia)
	AddHero($ID_Gwen)
	AddHero($ID_Norgu)
	AddHero($ID_Razah)
	Sleep(500 + GetPing())
	LoadSkillTemplate($GlintRituSoulTwisterHeroSkillBar, $Glint_Hero_Ritu_SoulTwister)
	LoadSkillTemplate($GlintNecroFleshGolemHeroSkillBar, $Glint_Hero_Necro_FleshGolem)
	LoadSkillTemplate($GlintNecroHexerHeroSkillBar, $Glint_Hero_Necro_Hexer)
	LoadSkillTemplate($GlintNecroBiPHeroSkillBar, $Glint_Hero_Necro_BiP)
	LoadSkillTemplate($GlintMesmerPanicHeroSkillBar, $Glint_Hero_Mesmer_Panic)
	LoadSkillTemplate($GlintMesmerIneptitudeHeroSkillBar, $Glint_Hero_Mesmer_Ineptitude_1)
	LoadSkillTemplate($GlintMesmerIneptitudeHeroSkillBar, $Glint_Hero_Mesmer_Ineptitude_2)
	Sleep(500 + GetPing())
	SetHeroAggression($Glint_Hero_Ritu_SoulTwister, $ID_Hero_fighting)
	SetHeroAggression($Glint_Hero_Necro_FleshGolem, $ID_Hero_fighting)
	SetHeroAggression($Glint_Hero_Necro_Hexer, $ID_Hero_fighting)
	SetHeroAggression($Glint_Hero_Necro_BiP, $ID_Hero_fighting)
	SetHeroAggression($Glint_Hero_Mesmer_Panic, $ID_Hero_fighting)
	SetHeroAggression($Glint_Hero_Mesmer_Ineptitude_1, $ID_Hero_fighting)
	SetHeroAggression($Glint_Hero_Mesmer_Ineptitude_2, $ID_Hero_fighting)
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
    	Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


Func EnterGlintChallengeMission()
	If GetMapID() <> $ID_Central_Transfer_Chamber Then TravelToOutpost($ID_Central_Transfer_Chamber, $DISTRICT_NAME)
	While GetMapID() <> $ID_Glints_Challenge
		Info('Entering Glint mission')
		;MoveTo(300, 1500)
		MoveTo(2408, 3560)
		GoToNPC(GetNearestNPCToCoords(2480, 3586))
		Info('Talking to NPC')
		Sleep(1000)
		Dialog(0x86)
		Sleep(1000)
		WaitMapLoading($ID_Glints_Challenge)
	WEnd
EndFunc


;~ Cleaning Glint challenge function
Func GlintChallenge()
	If GetMapID() <> $ID_Glints_Challenge Then Return $FAIL
	Sleep(5000)
	WalkToSpotGlintChallenge()

	; Glint challenge lasts around 20 minutes, so after this time elapses and no foes are found in range then challenge is considered successful
	$GlintChallengeTimer = TimerInit() ; Starting run timer

	Info('Defending baby dragon')
	While IsPlayerAlive() And Not GetIsDead(GetAgentById($AgentID_BabyDragon) And _
			(TimerDiff($GlintChallengeTimer) < $GLINT_CHALLENGE_DURATION) Or CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS) > 0)
		Sleep(1000)
		KillFoesInArea($GlintChallengeFightOptions)
		If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_EARSHOT)
		MoveTo($GlintChallengeDefendX, $GlintChallengeDefendY)
	WEnd

	If IsPlayerAndPartyWiped() Or GetIsDead(GetAgentById($AgentID_BabyDragon) Then Return $FAIL

	; Tripled to try securing the looting of Chest of the Bortherhood
	For $i = 1 To 3
		MoveTo(-3220, 973)
		Info('Opening Chest of the Bortherhood')
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next

	Return $SUCCESS
EndFunc


;~ Getting into positions
Func WalkToSpotGlintChallenge()
	Info('Moving to defend position')
	MoveTo($GlintChallengeDefendX, $GlintChallengeDefendY) ; move to defending position
	;FanFlagHeroes(260) ; spread out all heroes to avoid AoE damage, distance a bit larger than nearby range = 240, and still quite compact formation
	CommandHero($Glint_Hero_Ritu_SoulTwister, -4300, 125)
	CommandHero($Glint_Hero_Necro_FleshGolem, -4278, 346)
	CommandHero($Glint_Hero_Necro_Hexer, -3925, -200)
	CommandHero($Glint_Hero_Necro_BiP, -4120, 75)
	CommandHero($Glint_Hero_Mesmer_Panic, -3960, 216)
	CommandHero($Glint_Hero_Mesmer_Ineptitude_1, -4065, 310)
	CommandHero($Glint_Hero_Mesmer_Ineptitude_2, -3912, -14)
EndFunc