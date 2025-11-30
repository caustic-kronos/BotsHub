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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include <File.au3>

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $DWCommendationsFarmerSkillbar = 'OgGlQlVp6smsJRg19RTKexTkL2XsDC'
Global Const $CommendationsFarmInformations = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- 13 Earth Prayers' &@CRLF _
	& '- 7 Mysticism' & @CRLF _
	& '- 4 Wind Prayers' & @CRLF _
	& '- 10 Tactics (shield req + weakness)' & @CRLF _
	& '- 10 Swordsmanship (sword req + weakness)' & @CRLF _
	& '- Blessed insignias or Windwalker insignias'& @CRLF _
	& '- A tactics shield q9 or less with the inscription Sleep now in the fire (+10 armor against fire damage)' & @CRLF _
	& '- A main hand with +20% enchantments duration and +5 armor' & @CRLF _
	& '- any PCons you wish to use' & @CRLF _
	& 'This bot doesn''t load hero builds - please use your own teambuild'
; Average duration ~ 3m20
Global Const $COMMENDATIONS_FARM_DURATION = (3 * 60 + 20) * 1000

; Dirty hack for Kaineng City changing ID during events - but the alternate solutions are dirtier
Global Const $ID_Current_Kaineng_City = $ID_Kaineng_City
;Local Const $ID_Current_Kaineng_City = $ID_Kaineng_City_Events
Global Const $ID_Miku_Agent = 58

Global $MINISTERIAL_COMMENDATIONS_FARM_SETUP = False

Global $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Skill_Conviction) is better than UseSkillEx(1))
Global Const $Skill_Conviction						= 1
Global Const $Skill_Grenths_Aura					= 2
Global Const $Skill_I_am_unstoppable				= 3
;Global Const $Skill_Healing_Signet					= 4
Global Const $Skill_Mystic_Regeneration				= 4
Global Const $Skill_Vital_Boon						= 4
Global Const $Skill_To_the_limit					= 5
Global Const $Skill_Ebon_Battle_Standard_of_Honor	= 6
Global Const $Skill_Hundred_Blades					= 7
Global Const $Skill_Whirlwind_Attack				= 8

; ESurge mesmers
Global Const $Energy_Surge_Skill_Position			= 1
Global Const $ESurge2_Mystic_Healing_Skill_Position = 8
; Ineptitude mesmer
Global Const $Stand_your_ground_Skill_position		= 6
Global Const $Make_Haste_Skill_position				= 7
; SoS Ritualist
Global Const $SoS_Skill_Position					= 1
Global Const $Splinter_Weapon_Skill_Position		= 2
Global Const $Essence_Strike_Skill_Position			= 3
Global Const $Mend_Body_And_Soul_Skill_Position		= 5
Global Const $Spirit_Light							= 6
Global Const $SoS_Mystic_Healing_Skill_Position		= 8
; Prot Ritualist
Global Const $Soul_Twisting_Skill_Position			= 1
Global Const $Shelter_Skill_Position				= 2
Global Const $Union_Skill_Position					= 3
Global Const $Displacement_Skill_Position			= 4
Global Const $Armor_of_Unfeeling_Skill_Position		= 5
Global Const $SBoon_of_creation_Skill_Position		= 6
Global Const $Prot_Mystic_Healing_Skill_Position	= 7
; BiP Necro
Global Const $Recovery_Skill_Position				= 8
Global Const $Blood_bond_Skill_Position				= 2
Global Const $Spirit_Transfer						= 4

; Order heros are added to the team
Global Const $Hero_Mesmer_DPS_1			= 1
Global Const $Hero_Mesmer_DPS_2			= 2
Global Const $Hero_Mesmer_DPS_3			= 3
Global Const $Hero_Mesmer_Ineptitude	= 4
Global Const $Hero_Ritualist_SoS		= 5
Global Const $Hero_Ritualist_Prot		= 6
Global Const $Hero_Necro_BiP			= 7

Global Const $ID_mesmer_mercenary_hero = $ID_Mercenary_Hero_1
Global Const $ID_ritualist_mercenary_hero = $ID_Mercenary_Hero_2

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

;~ Main loop of the Ministerial Commendations farm
Func MinisterialCommendationsFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $MINISTERIAL_COMMENDATIONS_FARM_SETUP Then SetupMinisterialCommendationsFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Local $result = MinisterialCommendationsFarmLoop()
	TravelToOutpost($ID_Current_Kaineng_City, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Setup for the farm - load build and heroes, move in the correct zone
Func SetupMinisterialCommendationsFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Current_Kaineng_City, $DISTRICT_NAME)

	SetupTeamMinisterialCommendationsFarm()
	LoadSkillTemplate($DWCommendationsFarmerSkillbar)

	SwitchMode($ID_HARD_MODE)
	$MINISTERIAL_COMMENDATIONS_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func SetupTeamMinisterialCommendationsFarm()
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	AddHero($ID_Gwen)
	AddHero($ID_Norgu)
	AddHero($ID_Razah)
	AddHero($ID_mesmer_mercenary_hero)
	AddHero($ID_ritualist_mercenary_hero)
	AddHero($ID_Xandra)
	AddHero($ID_Olias)
	Sleep(1000)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


Func MinisterialCommendationsFarmLoop()
	If GetMapID() <> $ID_Current_Kaineng_City Then Return $FAIL
	If $LOG_LEVEL == 0 Then $loggingFile = FileOpen(@ScriptDir & '/logs/commendation_farm-' & GetCharacterName() & '.log', $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	Info('Entering quest')
	EnterAChanceEncounterQuest()
	If GetMapID() <> $ID_Kaineng_A_Chance_Encounter Then Return $FAIL

	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Info('Preparing to fight')
	PrepareToFight()
	If GetMapID() <> $ID_Kaineng_A_Chance_Encounter Then Return $FAIL

	If $STATUS <> 'RUNNING' Then Return $PAUSE

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

	If $LOG_LEVEL == 0 Then FileClose($loggingFile)
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
	GoToNPC(GetNearestNPCToCoords(2240, -1264))
	RandomSleep(250)
	Dialog(0x84)
	RandomSleep(500)
	WaitMapLoading($ID_Kaineng_A_Chance_Encounter)
EndFunc


;~ Prepare the party for the initial fight
Func PrepareToFight()
	;StartingPositions()
	StartingPositions()
	RandomSleep(1500)
	UseHeroSkill($Hero_Ritualist_SoS, $SoS_Skill_Position)						;SoS - SoS
	UseHeroSkill($Hero_Necro_BiP, $Recovery_Skill_Position)						;BiP - Recovery
	RandomSleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Shelter_Skill_Position)					;Prot - Shelter
	RandomSleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Union_Skill_Position)					;Prot - Union
	RandomSleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Displacement_Skill_Position)			;Prot - Displacement
	RandomSleep(2500)
	UseHeroSkill($Hero_Ritualist_Prot, $Soul_Twisting_Skill_Position)			;Prot - Soul Twisting
	RandomSleep(2500)
	UseHeroSkill($Hero_Ritualist_SoS, $Splinter_Weapon_Skill_Position, GetMyAgent())		;SoS - Splinter Weapon
	UseHeroSkill($Hero_Ritualist_SoS, $Armor_of_Unfeeling_Skill_Position)		;Prot - Armor of Unfeeling
	RandomSleep(11000)
	UseConsumable($ID_Birthday_Cupcake)
	UseHeroSkill($Hero_Mesmer_DPS_1, $Energy_Surge_Skill_Position)				;ESurge1 - ESurge
	UseHeroSkill($Hero_Mesmer_DPS_2, $Energy_Surge_Skill_Position)				;ESurge2 - ESurge
	UseHeroSkill($Hero_Mesmer_DPS_3, $Energy_Surge_Skill_Position)				;ESurge3 - ESurge
	UseHeroSkill($Hero_Ritualist_SoS, $Essence_Strike_Skill_Position)			;Sos - Essence Strike
	UseHeroSkill($Hero_Necro_BiP, $Blood_bond_Skill_Position)					;BiP - Blood Bond
	RandomSleep(2500)
	; Enemies turn hostile now
	UseHeroSkill($Hero_Mesmer_Ineptitude, $Stand_your_ground_Skill_position)	;Ineptitude - Stand your ground
	UseSkillEx($Skill_Ebon_Battle_Standard_of_Honor)
	RandomSleep(1000)
EndFunc


;~ Move party into a good starting position
Func StartingPositions()
	CommandHero($Hero_Mesmer_DPS_1, -6524, -5178)
	CommandHero($Hero_Mesmer_DPS_2, -6165, -5585)
	CommandHero($Hero_Mesmer_DPS_3, -6224, -5075)
	CommandHero($Hero_Mesmer_Ineptitude, -6033, -5271)
	CommandHero($Hero_Ritualist_SoS, -6524, -5178)
	CommandHero($Hero_Ritualist_Prot, -5766, -5226)
	CommandHero($Hero_Necro_BiP, -6170, -4792)
	MoveTo(-6285, -5343)
	RandomSleep(1000)
	CommandHero($Hero_Ritualist_SoS, -6515, -5510)
EndFunc


;~ Move party into a good starting position
Func AlternateStartingPositions2()
	CommandHero($Hero_Mesmer_DPS_1, -6488, -5084)
	CommandHero($Hero_Mesmer_DPS_2, -6052, -5522)
	CommandHero($Hero_Mesmer_DPS_3, -5820, -5309)
	CommandHero($Hero_Mesmer_Ineptitude, -6041, -5072)
	CommandHero($Hero_Ritualist_SoS, -6488, -5084)
	CommandHero($Hero_Ritualist_Prot, -6004, -4620)
	CommandHero($Hero_Necro_BiP, -6244, -4860)
	MoveTo(-6322, -5266)
	CommandHero($Hero_Ritualist_SoS, -6307, -5273)
EndFunc


;~ Move party into a good starting position
Func AlternateStartingPositions()
	CommandHero($Hero_Mesmer_DPS_1, -6175, -6013)
	CommandHero($Hero_Mesmer_DPS_2, -6151, -5622)
	CommandHero($Hero_Mesmer_DPS_3, -6201, -5239)
	CommandHero($Hero_Mesmer_Ineptitude, -5770, -5577)
	CommandHero($Hero_Ritualist_SoS, -5898, -5836)
	CommandHero($Hero_Ritualist_Prot, -5911, -5319)
	CommandHero($Hero_Necro_BiP, -5687, -5155)
	MoveTo(-6322, -5266)
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
		;RenewSpirits()
		AttackOrUseSkill(1300, $Skill_I_am_unstoppable, $Skill_Hundred_Blades, $Skill_To_the_limit)
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
	UseHeroSkill($Hero_Mesmer_Ineptitude, $Make_Haste_Skill_position, GetMyAgent())

	; Move all heroes to podium to kill last foes
	CommandAll(-6699, -5645)

	If IsRecharged($Skill_I_am_unstoppable) Then UseSkillEx($Skill_I_am_unstoppable)
	; Run to first stairs
	Move(-4693, -3137)

	; Wait for all foes in range of Miku to be dead
	While (CountFoesInRangeOfAgent($ID_Miku_Agent, $RANGE_SPELLCAST) > 0 And TimerDiff($deadlock) < 80000 And Not IsFail())
		Move(-4693, -3137)
		RandomSleep(750)
	WEnd
	If (TimerDiff($deadlock) > 80000) Then Info('Timed out waiting for all mobs to be dead')

	UseHeroSkill($Hero_Ritualist_SoS, $Mend_Body_And_Soul_Skill_Position, GetMikuAgentOrMine())
	UseHeroSkill($Hero_Necro_BiP, $Mend_Body_And_Soul_Skill_Position, GetMikuAgentOrMine())
	LogIntoFile('Initial fight duration - ' & Round(TimerDiff($deadlock)/1000) & 's')

	; Move all heroes to not interfere with loot
	CommandAll(-7075, -5685)
EndFunc


;~ Returns the agent of Miku or the character if Miku is too far
Func GetMikuAgentOrMine()
	If GetAgentExists($ID_Miku_Agent) Then Return GetAgentByID($ID_Miku_Agent)
	Return GetMyAgent()
EndFunc


;~ Heal Miku and character if they need it
Func HelpMikuAndCharacter()
	Local $me = GetMyAgent()
	If DllStructGetData(GetMikuAgentOrMine(), 'HealthPercent') < 0.50 Then
		UseHeroSkill($Hero_Ritualist_SoS, $Spirit_Light, GetMikuAgentOrMine())
		UseHeroSkill($Hero_Necro_BiP, $Spirit_Transfer, GetMikuAgentOrMine())
	ElseIf DllStructGetData($me, 'HealthPercent') < 0.40 Then
		UseHeroSkill($Hero_Ritualist_SoS, $Spirit_Light, $me)
		UseHeroSkill($Hero_Necro_BiP, $Spirit_Transfer, $me)
	EndIf
EndFunc


;~ Replace Soul Twisting spirits if needed
Func RenewSpirits()
	If GetEffectTimeRemaining(GetEffect($Shelter_Skill_Position)) == 0 _
		Or GetEffectTimeRemaining(GetEffect($Shelter_Skill_Position)) == 0 Then
			SoulTwistingRitualistUseSoulTwisting()
			UseHeroSkill($Hero_Ritualist_Prot, $Shelter_Skill_Position)						;Prot - Shelter
			RandomSleep(1250)
			SoulTwistingRitualistUseSoulTwisting()
			UseHeroSkill($Hero_Ritualist_Prot, $Union_Skill_Position)						;Prot - Union
			RandomSleep(1250)
			UseHeroSkill($Hero_Ritualist_SoS, $Armor_of_Unfeeling_Skill_Position)			;Prot - Armor of Unfeeling
			RandomSleep(50)
	EndIf
	If GetEffectTimeRemaining(GetEffect($Displacement_Skill_Position)) == 0 Then
		SoulTwistingRitualistUseSoulTwisting()
		UseHeroSkill($Hero_Ritualist_Prot, $Displacement_Skill_Position)					;Prot - Displacement
		RandomSleep(1250)
		UseHeroSkill($Hero_Ritualist_SoS, $Armor_of_Unfeeling_Skill_Position)				;Prot - Armor of Unfeeling
		RandomSleep(50)
	EndIf
	SoulTwistingRitualistUseSoulTwisting()
EndFunc


;~ The soul twisting ritualist uses soul twisting - sic
Func SoulTwistingRitualistUseSoulTwisting()
	If GetEffectTimeRemaining(GetEffect($Soul_Twisting_Skill_Position, $Hero_Ritualist_Prot)) == 0 Then
		UseHeroSkill($Hero_Ritualist_Prot, $Soul_Twisting_Skill_Position)					;Prot - Soul Twisting
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


;~ Wait for all ennemies to be balled
Func WaitForPurityBall()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)

	; Wait until an enemy is in melee range
	While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 55000
		RandomSleep(1000)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	WEnd

	LogIntoFile('Initial foes count - ' & CountFoesOnTopOfTheStairs())

	While IsPlayerAlive() And TimerDiff($deadlock) < 75000 And (Not IsFurthestMobInBall() Or GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130)
		If ($foesCount > 3 And IsRecharged($Skill_To_the_limit) And GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130) Then
			UseSkillEx($Skill_To_the_limit)
			RandomSleep(50)
		EndIf

		; Use defensive and self healing skills
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 And IsRecharged($Skill_I_am_unstoppable) Then
			UseSkillEx($Skill_I_am_unstoppable)
			RandomSleep(50)
		EndIf
		If IsRecharged($Skill_Conviction) And GetEffectTimeRemaining(GetEffect($ID_Conviction)) == 0 Then
			UseSkillEx($Skill_Conviction)
			RandomSleep(GetPing() + 100)

			If IsRecharged($Skill_Vital_Boon) Then
				UseSkillEx($Skill_Vital_Boon)
				RandomSleep(GetPing() + 20)
			EndIf
		EndIf
		;If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
		;	UseSkillEx($Skill_Mystic_Regeneration)
		;	RandomSleep(GetPing() + 20)
		;EndIf
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($Skill_Vital_Boon) And GetEffectTimeRemaining(GetEffect($ID_Vital_Boon)) == 0 Then
			UseSkillEx($Skill_Vital_Boon)
			RandomSleep(GetPing() + 20)
		EndIf

		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.45 And IsRecharged($Skill_Grenths_Aura) Then
			UseSkillEx($Skill_Grenths_Aura)
			RandomSleep(250)
		EndIf
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf

		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
		RandomSleep(250)
	WEnd
	If (TimerDiff($deadlock) > 75000) Then Info('Timed out waiting for mobs to ball')
	LogIntoFile('Ball ready - ' & Round(TimerDiff($deadlock)/1000) & 's')
EndFunc


;~ Return True if mission failed (you or Miku died)
Func IsFail()
	If GetIsDead($ID_Miku_Agent) Then
		Warn('Miku died.')
		LogIntoFile('Miku died.')
		Return True
	ElseIf IsPlayerDead() Then
		Warn('Player died')
		LogIntoFile('Character died.')
		Return True
	EndIf
	Return False
EndFunc


;~ Kill mobs
Func KillMinistryOfPurity()
	Local $deadlock
	Local $foesCount

	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($Skill_Grenths_Aura) Then
		UseSkillEx($Skill_Grenths_Aura)
		RandomSleep(50)
	EndIf

	While IsRecharged($Skill_Ebon_Battle_Standard_of_Honor)
		If IsPlayerDead() Then Return
		UseSkillEx($Skill_Ebon_Battle_Standard_of_Honor)
		RandomSleep(50)

		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf
	WEnd

	While IsRecharged($Skill_Hundred_Blades)
		If IsPlayerDead() Then Return
		UseSkillEx($Skill_Hundred_Blades)
		RandomSleep(50)
	WEnd

	If IsRecharged($Skill_Grenths_Aura) Then
		If IsPlayerDead() Then Return
		UseSkillEx($Skill_Grenths_Aura)
		RandomSleep(50)
	EndIf

	Local $initialFoeCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)

	; Whirlwind attack needs specific care to be used
	While IsRecharged($Skill_Whirlwind_Attack)
		If IsPlayerDead() Then Return
		RandomSleep(200)

		; Heroes with Mystic Healing provide additional long range support
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf

		If (IsRecharged($Skill_To_the_limit) And GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130) Then
			UseSkillEx($Skill_To_the_limit)
			RandomSleep(50)
		EndIf

		UseSkillEx($Skill_Whirlwind_Attack, GetNearestEnemyToAgent(GetMyAgent()))
		RandomSleep(50)
	WEnd
	CancelAction()

	RandomSleep(250)
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_ADJACENT)

	; If some foes are still alive, we have 10s to finish them else we just pick up and leave
	$deadlock = TimerInit()
	While $foesCount > 0 And TimerDiff($deadlock) < 10000
		If IsPlayerDead() Then Return
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.70 Then
			; Heroes with Mystic Healing provide additional long range support
			UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
			UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
		EndIf

		If (IsRecharged($Skill_To_the_limit) And GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) < 130) Then
			UseSkillEx($Skill_To_the_limit)
			RandomSleep(50)
		EndIf

		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($Skill_Vital_Boon) And GetEffectTimeRemaining(GetEffect($ID_Vital_Boon)) == 0 Then
			UseSkillEx($Skill_Vital_Boon)
			RandomSleep(1000)
		;If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
		;	UseSkillEx($Skill_Mystic_Regeneration)
		;	RandomSleep(300)
		ElseIf GetSkillbarSkillAdrenaline($Skill_Whirlwind_Attack) == 130 Then
			While IsRecharged($Skill_Whirlwind_Attack) And TimerDiff($deadlock) < 10000
				If IsPlayerDead() Then Return
				UseSkillEx($Skill_Whirlwind_Attack, GetNearestEnemyToAgent(GetMyAgent()))
				RandomSleep(250)
			WEnd
		Else
			AttackOrUseSkill(1300, $Skill_Conviction)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_ADJACENT)
	WEnd
	If (TimerDiff($deadlock) > 10000) Then Info('Left ' & $foesCount & ' mobs alive out of ' & $initialFoeCount & ' foes')
	LogIntoFile('Mobs killed - ' & ($initialFoeCount - $foesCount))
	LogIntoFile('Mobs left alive - ' & $foesCount)

	RandomSleep(250)
EndFunc


;~ Heal the character while he is picking items
Func HealWhilePickingItems()
	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
		If IsRecharged($Skill_Conviction) And GetEffectTimeRemaining(GetEffect($ID_Conviction)) == 0 Then
			UseSkillEx($Skill_Conviction)
			RandomSleep(50)
		EndIf
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.60 And IsRecharged($Skill_Vital_Boon) And GetEffectTimeRemaining(GetEffect($ID_Vital_Boon)) == 0 Then
			UseSkillEx($Skill_Vital_Boon)
			RandomSleep(GetPing() + 20)
		;If IsRecharged($Skill_Mystic_Regeneration) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Regeneration)) == 0 Then
		;	UseSkillEx($Skill_Mystic_Regeneration)
		;	RandomSleep(GetPing() + 20)
		EndIf
		; Heroes with Mystic Healing provide additional long range support
		UseHeroSkill($Hero_Mesmer_DPS_2, $ESurge2_Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Ritualist_SoS, $SoS_Mystic_Healing_Skill_Position)
		UseHeroSkill($Hero_Ritualist_Prot, $Prot_Mystic_Healing_Skill_Position)
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
	If $LOG_LEVEL == 0 Then _FileWriteLog($loggingFile, $string)
EndFunc
