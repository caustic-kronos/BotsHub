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

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $KournansBotVersion = '0.1'

; ==== Constants ====
Local Const $ElAKournansFarmerSkillbar = 'OgdTkYG/HCHMXctUVwHC3xVI1BA'
Local Const $RKournansHeroSkillbar = 'OgATYnLjZB6C+Zn76OzGAAAA'
Local Const $RtKournansHeroSkillbar = 'OACjAyhDJPBTy58M5CAAAAAAAA'
Local Const $PKournansHeroSkillbar = 'OQijEqmMKO84dM92HbiH26YcMA'
Local Const $KournansFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Magic' & @CRLF _
	& '- 13 in Energy Storage' & @CRLF _
	& '- 3 in Shadow Arts' & @CRLF _
	& '- Any weapon that gives you energy or maybe life' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- The quest Fish in a Barrel not completed'
; Average duration ~ 2m10s ~ First run is 2m40s with setup
Local Const $KOURNANS_FARM_DURATION = (2 * 60 + 25) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain) is better than UseSkillEx(1))
Local Const $Kournans_Intensity = 1
Local Const $Kournans_EbonBattleStandardOfHonor = 2
Local Const $Kournans_Mindbender = 3
Local Const $Kournans_Earthquake = 4
Local Const $Kournans_DragonsStomp = 5
Local Const $Kournans_DeathsCharge = 6
Local Const $Kournans_Aftershock = 7
Local Const $Kournans_Shockwave = 8

Local Const $Hero_Kournans_Margrid = 1
Local Const $Hero_Kournans_Xandra = 2

Local Const $Kournans_EdgeOfExtinction = 1
Local Const $Kournans_Lacerate = 2
Local Const $Kournans_Brambles = 3
Local Const $Kournans_NaturesRenewal = 4
Local Const $Kournans_MuddyTerrain = 5
Local Const $Kournans_Pestilence = 6

Local Const $Kournans_RitualLord = 1
Local Const $Kournans_EarthBind = 2
Local Const $Kournans_VitalWeapon = 3
Local Const $Kournans_DeathPactSignet = 4


Local $KOURNANS_FARM_SETUP = False

;~ Main method to farm Kournans
Func KournansFarm($STATUS)
	If Not $KOURNANS_FARM_SETUP Then
		SetupKournansFarm()
		$KOURNANS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return KournansFarmLoop()
EndFunc


;~ Kournans farm setup
Func SetupKournansFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Sunspear_Sanctuary Then DistrictTravel($ID_Sunspear_Sanctuary, $DISTRICT_NAME)

	SwitchMode($ID_HARD_MODE)
	LeaveGroup()
	RndSleep(50)
	AddHero($ID_Margrid_The_Sly)
	RndSleep(50)
	AddHero($ID_Xandra)
	RndSleep(50)
	AddHero($ID_General_Morgahn)
	RndSleep(50)

	LoadSkillTemplate($ElAKournansFarmerSkillbar)
	LoadSkillTemplate($RKournansHeroSkillbar, 1)
	LoadSkillTemplate($RtKournansHeroSkillbar, 2)
	LoadSkillTemplate($PKournansHeroSkillbar, 3)
	DisableAllHeroSkills(1)
	DisableAllHeroSkills(2)

	RndSleep(50)
	Info('Entering Command Post')
	MoveTo(-1500, 2000)
	MoveTo(0, 5000)
	WaitMapLoading($ID_Command_Post, 10000, 2000)
	MoveTo(-200, 4350)
	MoveTo(-500, 3500)
	WaitMapLoading($ID_Sunspear_Sanctuary, 10000, 2000)
	Info('Preparations complete')
EndFunc


;~ Kournans farm loop
Func KournansFarmLoop()
	Info('Abandonning quest')
	AbandonQuest(0x23E)
	Info('Entering Command Post')
	MoveTo(0, 5000)
	WaitMapLoading($ID_Command_Post, 10000, 2000)
	MoveTo(1250, 7300)
	TalkToMargrid()
	MoveTo(800, 6500)
	MoveTo(-1000, 6300)
	MoveTo(-3000, 8800)
	MoveTo(-4000, 10000)
	WaitMapLoading($ID_Sunward_Marches, 10000, 2000)
	MoveTo(13500, -4000)
	MoveTo(11500, -2500)

	; Find the kournans and get in spirit range
	; Move to the correct range of the enemies (who are not enemies at this points)(close so that they are affected by spirits but not too close)
	Local $targetFoe = GetNearestNPCInRangeOfCoords(9600, -650, null, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe, $RANGE_SPIRIT - 500)
	Local $me = GetMyAgent()
	Local $X = DllStructGetData($me, 'X')
	Local $Y = DllStructGetData($me, 'Y')
	CommandAll($X, $Y)
	RndSleep(2000)
	CastOnlyNecessarySpiritsAndBoons($X, $Y)
	CommandAll(16000, -7000)

	UseSkillEx($Kournans_Intensity)
	UseSkillEx($Kournans_Mindbender)				;1s
	Local $positionToGo = FindMiddleOfFoes(9600, -650, $RANGE_EARSHOT)
	$targetFoe = BetterGetNearestNPCToCoords(3, $positionToGo[0], $positionToGo[1], $RANGE_SPELLCAST)
	GetAlmostInRangeOfAgent($targetFoe)
	RndSleep(50)
	UseSkillEx($Kournans_EbonBattleStandardOfHonor)	;1s
	;Sleep(1000)
	UseSkillEx($Kournans_Earthquake, $targetFoe)	;3s
	UseSkill($Kournans_DragonsStomp, $targetFoe)	;3s
	Sleep(1500)
	UseSkillEx($Kournans_Intensity)
	Sleep(1500)
	UseSkillEx($Kournans_DeathsCharge, $targetFoe)
	UseSkillEx($Kournans_Aftershock)
	UseSkillEx($Kournans_Shockwave)
	RndSleep(2000)
	Info('Looting')
	PickUpItems()
	Local $result = GetIsDead() ? 1 : 0
	BackToSunspearSanctuary()
	Return $result
EndFunc


;~ Cast the mandatory spirits and boons
Func CastOnlyNecessarySpiritsAndBoons($safeX, $safeY)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_EdgeOfExtinction)
	; Get closer to the non-enemies to trigger them into enemies
	Local $targetFoe = GetFurthestNPCInRangeOfCoords(null, 9600, -650, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe, $RANGE_EARSHOT - 50)
	; Move back to be safe for a few seconds
	MoveTo($safeX, $safeY)
	RndSleep(4000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_MuddyTerrain)
	RndSleep(6000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_Brambles)
	RndSleep(3000)
	UseHeroSkill($Hero_Kournans_Xandra, $Kournans_RitualLord)
	UseHeroSkill($Hero_Kournans_Xandra, $Kournans_EarthBind)
	RndSleep(1500)
	UseHeroSkill($Hero_Kournans_Xandra, $Kournans_VitalWeapon, GetMyAgent())
	RndSleep(1500)
EndFunc


;~ Cast all of the spirits and boons - it is not necessary
Func CastFullSpiritsAndBoons($safeX, $safeY)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_EdgeOfExtinction)
	; Get closer to the non-enemies to trigger them into enemies
	Local $targetFoe = GetFurthestNPCInRangeOfCoords(null, 9600, -650, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe, $RANGE_EARSHOT -100)
	; Move back to be safe for a few seconds
	MoveTo($safeX, $safeY)
	RndSleep(5000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_Brambles)
	RndSleep(6000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_Lacerate)
	RndSleep(4000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_NaturesRenewal)
	RndSleep(6000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_MuddyTerrain)
	RndSleep(6000)
	UseHeroSkill($Hero_Kournans_Margrid, $Kournans_Pestilence)
	RndSleep(3000)
	UseHeroSkill($Hero_Kournans_Xandra, $Kournans_RitualLord)
	UseHeroSkill($Hero_Kournans_Xandra, $Kournans_EarthBind)
	RndSleep(1500)
	UseHeroSkill($Hero_Kournans_Xandra, $Kournans_VitalWeapon, GetMyAgent())
	RndSleep(1500)
EndFunc


;~ Talk to Margrid and take her quest
Func TalkToMargrid()
	Info('Talking to Margrid')
	GoNearestNPCToCoords(1250, 7300)
	RndSleep(1000)
	Info('Taking quest')
	; QuestID 0x23E = 574
	AcceptQuest(0x23E)
	RndSleep(500)
EndFunc


;~ Return to Sunspear Sanctuary
Func BackToSunspearSanctuary()
	Info('Porting to Sunspear Sanctuary')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Sunspear_Sanctuary, 10000, 2000)
EndFunc