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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include <File.au3>

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $DW_COMMENDATIONS_FARMER_SKILLBAR = 'OgGlQlVp6smsJRg19RTKexTkL2XsDC'
Global Const $COMMENDATIONS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- 13 Earth Prayers' &@CRLF _
	& '- 7 Mysticism' & @CRLF _
	& '- 4 Wind Prayers' & @CRLF _
	& '- 10 Tactics (shield Req + weakness)' & @CRLF _
	& '- 10 Swordsmanship (sword Req + weakness)' & @CRLF _
	& '- Blessed insignias or Windwalker insignias'& @CRLF _
	& '- A tactics shield q9 or less with the inscription Sleep now in the fire (+10 armor against fire damage)' & @CRLF _
	& '- A main hand with +20% enchantments duration and +5 armor' & @CRLF _
	& '- any PCons you wish to use' & @CRLF _
	& 'This bot does not load hero builds - please use your own teambuild'
; Average duration ~ 3m20
Global Const $COMMENDATIONS_FARM_DURATION = (3 * 60 + 20) * 1000

Global Const $ID_MIKU_AGENT = 58

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SKILL_CONVICTION) is better than UseSkillEx(1))
Global Const $SKILL_CONVICTION						= 1
Global Const $SKILL_GRENTHS_AURA					= 2
Global Const $SKILL_I_AM_UNSTOPPABLE				= 3
;Global Const $SKILL_HEALING_SIGNET					= 4
Global Const $SKILL_MYSTIC_REGENERATION				= 4
Global Const $SKILL_VITAL_BOON						= 4
Global Const $SKILL_TO_THE_LIMIT					= 5
Global Const $SKILL_EBON_BATTLE_STANDARD_OF_HONOR	= 6
Global Const $SKILL_HUNDRED_BLADES					= 7
Global Const $SKILL_WHIRLWIND_ATTACK				= 8

; ESurge mesmers
Global Const $ENERGY_SURGE_SKILL_POSITION			= 1
Global Const $ESURGE2_MYSTIC_HEALING_SKILL_POSITION = 8
; Ineptitude mesmer
Global Const $STAND_YOUR_GROUND_SKILL_POSITION		= 6
Global Const $MAKE_HASTE_SKILL_POSITION				= 7
; SoS Ritualist
Global Const $SOS_SKILL_POSITION					= 1
Global Const $SPLINTER_WEAPON_SKILL_POSITION		= 2
Global Const $ESSENCE_STRIKE_SKILL_POSITION			= 3
Global Const $MEND_BODY_AND_SOUL_SKILL_POSITION		= 5
Global Const $SPIRIT_LIGHT							= 6
Global Const $SOS_MYSTIC_HEALING_SKILL_POSITION		= 8
; Prot Ritualist
Global Const $SOUL_TWISTING_SKILL_POSITION			= 1
Global Const $SHELTER_SKILL_POSITION				= 2
Global Const $UNION_SKILL_POSITION					= 3
Global Const $DISPLACEMENT_SKILL_POSITION			= 4
Global Const $ARMOR_OF_UNFEELING_SKILL_POSITION		= 5
Global Const $SBOON_OF_CREATION_SKILL_POSITION		= 6
Global Const $PROT_MYSTIC_HEALING_SKILL_POSITION	= 7
; BiP Necro
Global Const $BLOOD_BOND_SKILL_POSITION = 2
Global Const $SPIRIT_TRANSFER			= 4
Global Const $RECOVERY_SKILL_POSITION	= 8

; Order heros are added to the team
Global Const $HERO_MESMER_DPS_1			= 1
Global Const $HERO_MESMER_DPS_2			= 2
Global Const $HERO_MESMER_DPS_3			= 3
Global Const $HERO_MESMER_INEPTITUDE	= 4
Global Const $HERO_RITUALIST_SOS		= 5
Global Const $HERO_RITUALIST_PROT		= 6
Global Const $HERO_NECRO_BIP			= 7

Global Const $ID_MESMER_MERCENARY_HERO = $ID_MERCENARY_HERO_1
Global Const $ID_RITUALIST_MERCENARY_HERO = $ID_MERCENARY_HERO_2

#CS ===========================================================================
Character location :	X: -6322.51318359375, Y: -5266.85986328125
Heroes locations :
- Me1 dps				X: -6488.185546875, Y: -5084.078125
- Me2 dps				X: -6052.578125, Y: -5522.14208984375
- Me3 dps				X: -5820.1552734375, Y: -5309.80615234375
- Me1 ineptitude/speed	X: -6041.62353515625, Y: -5072.26220703125
- Rt SoS				X: -6307.7060546875, Y: -5273.31494140625
- Rt heal				X: -6244.70703125, Y: -4860.3154296875
- N BiP					X: -6004.0107421875, Y: -4620.87451171875

Platform center :		X: -6699.40966796875, Y: -5645.5556640625
Away from loot :		X: -7295.5771484375, Y: -6395.5556640625

Travel :
1st stairs :			X: -4693.87451171875, Y: -3137.0244140625 (time : until all mobs are dead)
2nd stairs :			X: -4199.5126953125, Y: -1475.53430175781 (time : 6s no speed)
3rd stairs :			X: -4709.81005859375, Y: -609.159118652344 (3s)
1st corner :			X: -3116.35498046875, Y: 650.431457519531 (7s)
2nd corner :			X: -2518.41357421875, Y: 631.814453125 (1.5s)
4th stairs :			X: -2096.59228515625, Y: -1067.5732421875 (6s)
5th stairs :			X: -815.586608886719, Y: -1898.28894042969 (5s)
last stairs :			X: -690.559143066406, Y: -3769.5224609375 (6.5s)

DPS spot :				X: -850.958312988281, Y: -3961.001953125 (1s)
#CE ===========================================================================

Global $ministerial_commendations_farm_setup = False
Global $logging_file


;~ Main loop of the Ministerial Commendations farm
Func MinisterialCommendationsFarm()
	If Not $ministerial_commendations_farm_setup Then SetupMinisterialCommendationsFarm()

	Local $result = MinisterialCommendationsFarmLoop()
	TravelToOutpost($ID_Kaineng_Center, $district_name)
	Return $result
EndFunc


;~ Setup for the farm - load build and heroes, move in the correct zone
Func SetupMinisterialCommendationsFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Kaineng_Center, $district_name)

	SetupPlayerMinisterialCommendationsFarm()
	SetupTeamMinisterialCommendationsFarm()

	SwitchMode($ID_HARD_MODE)
	$ministerial_commendations_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMinisterialCommendationsFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) <> $GUI_CHECKED Then
		If DllStructGetData(GetMyAgent(), 'Primary') == $ID_DERVISH Then
			Info('Player''s profession is dervish. Loading up recommended dervish build automatically')
			LoadSkillTemplate($DW_COMMENDATIONS_FARMER_SKILLBAR)
		Else
			Info('Assuming player build is set up manually')
		EndIf
	EndIf
	RandomSleep(250)
EndFunc


Func SetupTeamMinisterialCommendationsFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	RandomSleep(500)
	AddHero($ID_GWEN)
	AddHero($ID_NORGU)
	AddHero($ID_RAZAH)
	AddHero($ID_MESMER_MERCENARY_HERO)
	AddHero($ID_RITUALIST_MERCENARY_HERO)
	AddHero($ID_XANDRA)
	AddHero($ID_OLIAS)
	RandomSleep(500)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


Func MinisterialCommendationsFarmLoop()
	If GetMapID() <> $ID_Kaineng_Center Then Return $FAIL
	If $log_level == 0 Then $logging_file = FileOpen(@ScriptDir & '/logs/commendation_farm-' & GetCharacterName() & '.log', $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	Info('Entering quest')
	EnterAChanceEncounterQuest()
	If GetMapID() <> $ID_KAINENG_A_CHANCE_ENCOUNTER Then Return $FAIL

	Info('Preparing to fight')
	PrepareToFight()

	Info('Fighting the first group')
	InitialFight()
	If (IsFail()) Then Return $FAIL

	Info('Running to kill spot')
	RunToKillSpot()
	If (IsFail()) Then Return $FAIL

	Info('Waiting for spike')
	LogIntoFile('Waiting for ball')
	WaitForPurityBall()
	If (IsFail()) Then Return $FAIL

	Info('Spiking the farm group')
	KillMinistryOfPurity()

	RandomSleep(1000)

	Info('Picking up loot')
	PickUpItems(HealWhilePickingItems)

	If $log_level == 0 Then FileClose($logging_file)
	Return $SUCCESS
EndFunc


;~ Enter the mission A Chance Encounter
Func EnterAChanceEncounterQuest()
	Local $me = GetMyAgent()
	Local $coordsX = DllStructGetData($me, 'X')
	Local $coordsY = DllStructGetData($me, 'Y')

	If -1400 < $coordsX And $coordsX < -550 And - 2000 < $coordsY And $coordsY < -1100 Then
		MoveTo(1474, -1197, 0)
	EndIf

	RandomSleep(1000)
	UseCitySpeedBoost()
	Local $npc = GetNearestNPCToCoords(2240, -1264)
	GoToNPC($npc)
	If GetDistance(GetMyAgent(), $npc) > $RANGE_ADJACENT Then 
		MoveTo(1474, -1197, 0)
		GoToNPC($npc)
	EndIf
	RandomSleep(250)
	Dialog(0x84)
	RandomSleep(500)
	WaitMapLoading($ID_KAINENG_A_CHANCE_ENCOUNTER)
EndFunc


;~ Prepare the party for the initial fight
Func PrepareToFight()
	StartingPositions()
	RandomSleep(1500)
	UseHeroSkill($HERO_RITUALIST_SOS, $SOS_SKILL_POSITION)
	UseHeroSkill($HERO_NECRO_BIP, $RECOVERY_SKILL_POSITION)
	RandomSleep(2500)
	UseHeroSkill($HERO_RITUALIST_PROT, $SHELTER_SKILL_POSITION)
	RandomSleep(2500)
	UseHeroSkill($HERO_RITUALIST_PROT, $UNION_SKILL_POSITION)
	RandomSleep(2500)
	UseHeroSkill($HERO_RITUALIST_PROT, $DISPLACEMENT_SKILL_POSITION)
	RandomSleep(2500)
	UseHeroSkill($HERO_RITUALIST_PROT, $SOUL_TWISTING_SKILL_POSITION)
	RandomSleep(2500)
	UseHeroSkill($HERO_RITUALIST_SOS, $SPLINTER_WEAPON_SKILL_POSITION, GetMyAgent())
	UseHeroSkill($HERO_RITUALIST_SOS, $ARMOR_OF_UNFEELING_SKILL_POSITION)
	RandomSleep(11000)
	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	UseHeroSkill($HERO_MESMER_DPS_1, $ENERGY_SURGE_SKILL_POSITION)
	UseHeroSkill($HERO_MESMER_DPS_2, $ENERGY_SURGE_SKILL_POSITION)
	UseHeroSkill($HERO_MESMER_DPS_3, $ENERGY_SURGE_SKILL_POSITION)
	UseHeroSkill($HERO_RITUALIST_SOS, $ESSENCE_STRIKE_SKILL_POSITION)
	UseHeroSkill($HERO_NECRO_BIP, $BLOOD_BOND_SKILL_POSITION)
	RandomSleep(2500)
	; Enemies turn hostile now
	UseHeroSkill($HERO_MESMER_INEPTITUDE, $STAND_YOUR_GROUND_SKILL_POSITION)
	UseSkillEx($SKILL_EBON_BATTLE_STANDARD_OF_HONOR)
	RandomSleep(1000)
EndFunc


;~ Move party into a good starting position
Func StartingPositions()
	CommandHero($HERO_MESMER_DPS_1, -6524, -5178)
	CommandHero($HERO_MESMER_DPS_2, -6165, -5585)
	CommandHero($HERO_MESMER_DPS_3, -6224, -5075)
	CommandHero($HERO_MESMER_INEPTITUDE, -6033, -5271)
	CommandHero($HERO_RITUALIST_SOS, -6524, -5178)
	CommandHero($HERO_RITUALIST_PROT, -5766, -5226)
	CommandHero($HERO_NECRO_BIP, -6170, -4792)
	MoveTo(-6285, -5343)
	RandomSleep(1000)
	CommandHero($HERO_RITUALIST_SOS, -6515, -5510)
EndFunc


;~ Move party into a good starting position
Func AlternateStartingPositions()
	CommandHero($HERO_MESMER_DPS_1, -6175, -6013)
	CommandHero($HERO_MESMER_DPS_2, -6151, -5622)
	CommandHero($HERO_MESMER_DPS_3, -6201, -5239)
	CommandHero($HERO_MESMER_INEPTITUDE, -5770, -5577)
	CommandHero($HERO_RITUALIST_SOS, -5898, -5836)
	CommandHero($HERO_RITUALIST_PROT, -5911, -5319)
	CommandHero($HERO_NECRO_BIP, -5687, -5155)
	MoveTo(-6322, -5266)
EndFunc


;~ Move party into a good starting position
Func AlternateStartingPositions2()
	CommandHero($HERO_MESMER_DPS_1, -6488, -5084)
	CommandHero($HERO_MESMER_DPS_2, -6052, -5522)
	CommandHero($HERO_MESMER_DPS_3, -5820, -5309)
	CommandHero($HERO_MESMER_INEPTITUDE, -6041, -5072)
	CommandHero($HERO_RITUALIST_SOS, -6488, -5084)
	CommandHero($HERO_RITUALIST_PROT, -6004, -4620)
	CommandHero($HERO_NECRO_BIP, -6244, -4860)
	MoveTo(-6322, -5266)
	CommandHero($HERO_RITUALIST_SOS, -6307, -5273)
EndFunc


;~ Deal with the initial group fight
Func InitialFight()
	Local $deadlock = TimerInit()
	LogIntoFile('New run started')
	RandomSleep(1000)
	Local $foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)

	; Wait until there are enemies
	While $foesInRange == 0 And TimerDiff($deadlock) < 10000
		RandomSleep(1000)
		$foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
		If IsFail() Then Return
	WEnd

	Local $deathTimer = Null
	; Now there are enemies let's fight until one mob is left
	While $foesInRange > 1 And TimerDiff($deadlock) < 80000
		HelpMikuAndCharacter()
		AttackOrUseSkill(1300, $SKILL_I_AM_UNSTOPPABLE, $SKILL_HUNDRED_BLADES, $SKILL_TO_THE_LIMIT)
		If IsFail() Then
			If $deathTimer = Null Then
				$deathTimer = TimerInit()
			ElseIf TimerDiff($deathTimer) > 10000 Then
				Return
			EndIf
		Else
			$foesInRange = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS)
			If $deathTimer <> Null Then $deathTimer = Null
		EndIf
	WEnd
	If (TimerDiff($deadlock) > 80000) Then Info('Timed out waiting for most mobs to be dead')

	PickUpItems(Null, PickOnlyImportantItem)

	; Unflag all heroes
	CancelAllHeroes()

	; Hero cast speed on character
	UseHeroSkill($HERO_MESMER_INEPTITUDE, $MAKE_HASTE_SKILL_POSITION, GetMyAgent())

	; Move all heroes to podium to kill last foes
	CommandAll(-6699, -5645)

	If IsRecharged($SKILL_I_AM_UNSTOPPABLE) Then UseSkillEx($SKILL_I_AM_UNSTOPPABLE)
	; Run to first stairs
	Move(-4693, -3137)

	$deadlock = TimerInit()
	; Wait for all foes in range of Miku to be dead
	While (CountFoesInRangeOfAgent($ID_MIKU_AGENT, $RANGE_SPELLCAST) > 0 And TimerDiff($deadlock) < 45000 And Not IsFail())
		Move(-4693, -3137)
		RandomSleep(750)
	WEnd
	RandomSleep(500)
	If (TimerDiff($deadlock) > 45000) Then Info('Timed out waiting for all mobs to be dead')

	UseHeroSkill($HERO_RITUALIST_SOS, $MEND_BODY_AND_SOUL_SKILL_POSITION, GetMikuAgentOrMine())
	UseHeroSkill($HERO_NECRO_BIP, $MEND_BODY_AND_SOUL_SKILL_POSITION, GetMikuAgentOrMine())
	LogIntoFile('Initial fight duration - ' & Round(TimerDiff($deadlock)/1000) & 's')

	; Move all heroes to not interfere with loot
	CommandAll(-7075, -5685)
EndFunc


;~ Returns the agent of Miku or the character if Miku is too far
Func GetMikuAgentOrMine()
	If GetAgentExists($ID_MIKU_AGENT) Then Return GetAgentByID($ID_MIKU_AGENT)
	Return GetMyAgent()
EndFunc


;~ Heal Miku and character if they need it
Func HelpMikuAndCharacter()
	Local $me = GetMyAgent()
	If DllStructGetData(GetMikuAgentOrMine(), 'HealthPercent') < 0.50 Then
		UseHeroSkill($HERO_RITUALIST_SOS, $SPIRIT_LIGHT, GetMikuAgentOrMine())
		UseHeroSkill($HERO_NECRO_BIP, $SPIRIT_TRANSFER, GetMikuAgentOrMine())
	ElseIf DllStructGetData($me, 'HealthPercent') < 0.40 Then
		UseHeroSkill($HERO_RITUALIST_SOS, $SPIRIT_LIGHT, $me)
		UseHeroSkill($HERO_NECRO_BIP, $SPIRIT_TRANSFER, $me)
	EndIf
EndFunc


;~ Replace Soul Twisting spirits if needed
Func RenewSpirits()
	If GetEffectTimeRemaining(GetEffect($SHELTER_SKILL_POSITION)) == 0 _
		Or GetEffectTimeRemaining(GetEffect($SHELTER_SKILL_POSITION)) == 0 Then
			SoulTwistingRitualistUseSoulTwisting()
			UseHeroSkill($HERO_RITUALIST_PROT, $SHELTER_SKILL_POSITION)
			RandomSleep(1250)
			SoulTwistingRitualistUseSoulTwisting()
			UseHeroSkill($HERO_RITUALIST_PROT, $UNION_SKILL_POSITION)
			RandomSleep(1250)
			UseHeroSkill($HERO_RITUALIST_SOS, $ARMOR_OF_UNFEELING_SKILL_POSITION)
			RandomSleep(50)
	EndIf
	If GetEffectTimeRemaining(GetEffect($DISPLACEMENT_SKILL_POSITION)) == 0 Then
		SoulTwistingRitualistUseSoulTwisting()
		UseHeroSkill($HERO_RITUALIST_PROT, $DISPLACEMENT_SKILL_POSITION)
		RandomSleep(1250)
		UseHeroSkill($HERO_RITUALIST_SOS, $ARMOR_OF_UNFEELING_SKILL_POSITION)
		RandomSleep(50)
	EndIf
	SoulTwistingRitualistUseSoulTwisting()
EndFunc


;~ The soul twisting ritualist uses soul twisting - sic
Func SoulTwistingRitualistUseSoulTwisting()
	If GetEffectTimeRemaining(GetEffect($SOUL_TWISTING_SKILL_POSITION, $HERO_RITUALIST_PROT)) == 0 Then
		UseHeroSkill($HERO_RITUALIST_PROT, $SOUL_TWISTING_SKILL_POSITION)
		RandomSleep(50)
	EndIf
EndFunc


;~ Run to farm spot
Func RunToKillSpot()
	MoveTo(-4199, -1475)
	MoveTo(-4709, -609)
	MoveTo(-3116, 650)
	MoveTo(-2518, 631)
	MoveTo(-2096, -1067)
	MoveTo(-815, -1898)
	MoveTo(-690, -3769)
	MoveTo(-850, -3961, 0)
	RandomSleep(500)
EndFunc


;~ Wait for all enemies to be balled
Func WaitForPurityBall()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)

	; Wait until an enemy is in range
	While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 55000
		RandomSleep(1000)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	WEnd

	LogIntoFile('Initial foes count - ' & CountFoesOnTopOfTheStairs())

	Local $ping = GetPing()
	While IsPlayerAlive() And TimerDiff($deadlock) < 75000 And (Not IsFurthestMobInBall() Or GetSkillbarSkillAdrenaline($SKILL_WHIRLWIND_ATTACK) < 130)
		If ($foesCount > 3 And IsRecharged($SKILL_TO_THE_LIMIT) And GetSkillbarSkillAdrenaline($SKILL_WHIRLWIND_ATTACK) < 130) Then
			UseSkillEx($SKILL_TO_THE_LIMIT)
			RandomSleep(50)
		EndIf

		; Use defensive and self healing skills
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 And IsRecharged($SKILL_I_AM_UNSTOPPABLE) Then
			UseSkillEx($SKILL_I_AM_UNSTOPPABLE)
			RandomSleep(50)
		EndIf
		If IsRecharged($SKILL_CONVICTION) And GetEffectTimeRemaining(GetEffect($ID_CONVICTION)) == 0 Then
			UseSkillEx($SKILL_CONVICTION)
			Sleep(100 + $ping)

			If IsRecharged($SKILL_VITAL_BOON) Then
				UseSkillEx($SKILL_VITAL_BOON)
				Sleep(20 + $ping)
			EndIf
		EndIf
		;If IsRecharged($SKILL_MYSTIC_REGENERATION) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_REGENERATION)) == 0 Then
		;	UseSkillEx($SKILL_MYSTIC_REGENERATION)
		;	Sleep(20 + $ping)
		;EndIf
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($SKILL_VITAL_BOON) And GetEffectTimeRemaining(GetEffect($ID_VITAL_BOON)) == 0 Then
			UseSkillEx($SKILL_VITAL_BOON)
			Sleep(20 + $ping)
		EndIf

		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.45 And IsRecharged($SKILL_GRENTHS_AURA) Then
			While IsPlayerAlive() And IsRecharged($SKILL_GRENTHS_AURA)
				UseSkillEx($SKILL_GRENTHS_AURA)
				RandomSleep(50)
			WEnd
		EndIf
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($HERO_MESMER_DPS_2, $ESURGE2_MYSTIC_HEALING_SKILL_POSITION)
			UseHeroSkill($HERO_RITUALIST_SOS, $SOS_MYSTIC_HEALING_SKILL_POSITION)
			UseHeroSkill($HERO_RITUALIST_PROT, $PROT_MYSTIC_HEALING_SKILL_POSITION)
		EndIf

		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
		RandomSleep(250)
	WEnd
	If (TimerDiff($deadlock) > 75000) Then Info('Timed out waiting for mobs to ball')
	LogIntoFile('Ball ready - ' & Round(TimerDiff($deadlock)/1000) & 's')
EndFunc


;~ Return True if mission failed (you or Miku died)
Func IsFail()
	If GetIsDead($ID_MIKU_AGENT) Then
		Warn('Miku died.')
		LogIntoFile('Miku died.')
		Return True
	ElseIf IsPlayerDead() Then
		Warn('Player died.')
		LogIntoFile('Player died.')
		Return True
	EndIf
	Return False
EndFunc


;~ Kill mobs
Func KillMinistryOfPurity()
	Local $deadlock
	Local $foesCount

	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($SKILL_GRENTHS_AURA) Then
		While IsPlayerAlive() And IsRecharged($SKILL_GRENTHS_AURA)
			UseSkillEx($SKILL_GRENTHS_AURA)
			RandomSleep(50)
		WEnd
	EndIf

	If IsPlayerDead() Then Return
	UseSkillEx($SKILL_EBON_BATTLE_STANDARD_OF_HONOR)
	RandomSleep(50)

	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
		; Heroes with Mystic Healing provide additional long range support
		UseHeroSkill($HERO_MESMER_DPS_2, $ESURGE2_MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_RITUALIST_SOS, $SOS_MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_RITUALIST_PROT, $PROT_MYSTIC_HEALING_SKILL_POSITION)
	EndIf

	If IsPlayerDead() Then Return
	UseSkillEx($SKILL_HUNDRED_BLADES)
	RandomSleep(50)

	If IsRecharged($SKILL_GRENTHS_AURA) Then
		While IsRecharged($SKILL_GRENTHS_AURA)
			UseSkillEx($SKILL_GRENTHS_AURA)
			RandomSleep(50)
			If IsPlayerDead() Then Return
		WEnd
	EndIf

	Local $initialFoeCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $initialAdrenaline = GetSkillbarSkillAdrenaline($SKILL_WHIRLWIND_ATTACK)
	Local $adrenaline = $initialAdrenaline
	; Whirlwind attack needs specific care to be used
	While IsRecharged($SKILL_WHIRLWIND_ATTACK) And $adrenaline >= $initialAdrenaline
		If IsPlayerDead() Then Return
		RandomSleep(200)

		; Heroes with Mystic Healing provide additional long range support
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($HERO_MESMER_DPS_2, $ESURGE2_MYSTIC_HEALING_SKILL_POSITION)
			UseHeroSkill($HERO_RITUALIST_SOS, $SOS_MYSTIC_HEALING_SKILL_POSITION)
			UseHeroSkill($HERO_RITUALIST_PROT, $PROT_MYSTIC_HEALING_SKILL_POSITION)
		EndIf

		$adrenaline = GetSkillbarSkillAdrenaline($SKILL_WHIRLWIND_ATTACK)
		If (IsRecharged($SKILL_TO_THE_LIMIT) And $adrenaline < 130) Then
			UseSkillEx($SKILL_TO_THE_LIMIT)
			RandomSleep(50)
		EndIf

		UseSkillEx($SKILL_WHIRLWIND_ATTACK, GetNearestEnemyToAgent(GetMyAgent()))
		RandomSleep(50)
	WEnd

	CancelAction()
	RandomSleep(250)
	CancelAction()

	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)

	; If some foes are still alive, we have 10s to finish them else we just pick up and leave
	$deadlock = TimerInit()
	While $foesCount > 0 And TimerDiff($deadlock) < 10000
		If IsPlayerDead() Then Return
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($HERO_MESMER_DPS_2, $ESURGE2_MYSTIC_HEALING_SKILL_POSITION)
			UseHeroSkill($HERO_RITUALIST_SOS, $SOS_MYSTIC_HEALING_SKILL_POSITION)
			UseHeroSkill($HERO_RITUALIST_PROT, $PROT_MYSTIC_HEALING_SKILL_POSITION)
		EndIf

		If (IsRecharged($SKILL_TO_THE_LIMIT) And GetSkillbarSkillAdrenaline($SKILL_WHIRLWIND_ATTACK) < 130) Then
			UseSkillEx($SKILL_TO_THE_LIMIT)
			RandomSleep(50)
		EndIf

		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($SKILL_VITAL_BOON) And GetEffectTimeRemaining(GetEffect($ID_VITAL_BOON)) == 0 Then
			UseSkillEx($SKILL_VITAL_BOON)
			RandomSleep(1000)
		;If IsRecharged($SKILL_MYSTIC_REGENERATION) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_REGENERATION)) == 0 Then
		;	UseSkillEx($SKILL_MYSTIC_REGENERATION)
		;	RandomSleep(300)
		ElseIf GetSkillbarSkillAdrenaline($SKILL_WHIRLWIND_ATTACK) == 130 Then
			While IsRecharged($SKILL_WHIRLWIND_ATTACK) And TimerDiff($deadlock) < 10000
				If IsPlayerDead() Then Return
				UseSkillEx($SKILL_WHIRLWIND_ATTACK, GetNearestEnemyToAgent(GetMyAgent()))
				RandomSleep(250)
			WEnd
		Else
			AttackOrUseSkill(1300, $SKILL_CONVICTION)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	WEnd
	CancelAction()

	If (TimerDiff($deadlock) > 10000) Then Info('Left ' & $foesCount & ' mobs alive out of ' & $initialFoeCount & ' foes')
	LogIntoFile('Mobs killed - ' & ($initialFoeCount - $foesCount))
	LogIntoFile('Mobs left alive - ' & $foesCount)

	Sleep(250)
EndFunc


;~ Heal the character while he is picking items
Func HealWhilePickingItems()
	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
		If IsRecharged($SKILL_CONVICTION) And GetEffectTimeRemaining(GetEffect($ID_CONVICTION)) == 0 Then
			UseSkillEx($SKILL_CONVICTION)
			RandomSleep(50)
		EndIf
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($SKILL_VITAL_BOON) And GetEffectTimeRemaining(GetEffect($ID_VITAL_BOON)) == 0 Then
			UseSkillEx($SKILL_VITAL_BOON)
			Sleep(20 + GetPing())
		;If IsRecharged($SKILL_MYSTIC_REGENERATION) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_REGENERATION)) == 0 Then
		;	UseSkillEx($SKILL_MYSTIC_REGENERATION)
		;	Sleep(20 + GetPing())
		EndIf
		; Heroes with Mystic Healing provide additional long range support
		UseHeroSkill($HERO_MESMER_DPS_2, $ESURGE2_MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_RITUALIST_SOS, $SOS_MYSTIC_HEALING_SKILL_POSITION)
		UseHeroSkill($HERO_RITUALIST_PROT, $PROT_MYSTIC_HEALING_SKILL_POSITION)
	EndIf
EndFunc


;~ Return True if the furthest foe from the player (direction center of Kaineng) is adjacent
Func IsFurthestMobInBall()
	Local $furthestEnemy = GetNearestEnemyToCoords(1817, -798)
	Return GetDistance($furthestEnemy, GetMyAgent()) <= $RANGE_NEARBY
EndFunc


;~ Count number of foes on top of the stairs
Func CountFoesOnTopOfTheStairs()
	Return CountFoesInRangeOfAgent(GetMyAgent(), 0, IsOnTopOfTheStairs)
EndFunc


;~ Count number of foes under the stairs
Func CountFoesUnderTheStairs()
	Return CountFoesInRangeOfAgent(GetMyAgent(), 0, IsUnderTheStairs)
EndFunc


;~ Returns whether an agent is on top of the stairs
Func IsOnTopOfTheStairs($agent)
	Return IsOverLine(1, 1, 4800, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc


;~ Returns whether an agent is under the stairs
Func IsUnderTheStairs($agent)
	Return Not IsOverLine(1, 1, 4800, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc


;~ Log string into the log file
Func LogIntoFile($string)
	If $log_level == 0 Then _FileWriteLog($logging_file, $string)
EndFunc
