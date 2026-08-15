#CS ===========================================================================
; Authors: DeeperBlue, unknown (Dervish original)
; Contributor: Gahais, GitHub Copilot (Assassin CA adaptation)
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
; Cathedral of Flames farm bot.
; Supports two builds:
;   - Dervish  : Vow of Silence farmer (original build, see article below)
;   - Assassin : Deadly Paradox + Shadow Form perma-invulnerability variant,
;                using Critical Agility instead of "I Am Unstoppable!"
; The active build is auto-detected from the player's primary profession;
; both builds share the same travel/quest/loot/mob-cleaning logic.
;
; Article references:
; https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer
; https://gwpvx.fandom.com/wiki/Build:A/any_Perma_Shadow_Form
#CE ===========================================================================

#include-once
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Quests.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $D_COF_SKILLBAR = 'OgCjkqqLrShXtX0kihYidfjhOXA'
Global Const $A_COF_SKILLBAR = 'Owpk8xjYaqW0BEPiOTNImY33YozF'
Global Const $COF_FARM_INFORMATIONS = 'For best results, have:' & @CRLF _
	& '- +1 +3 Wind Prayers/Shadow Arts' &@CRLF _
	& '- +1 Mysticism/Deadly Arts ' & @CRLF _
	& '- +1 Scythe Mastery (if dervish)' & @CRLF _
	& '- +50 HP Rune' & @CRLF _
	& '- +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias'& @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration) with a random inscription' & @CRLF _
	& '- This bot enters the Quest Temple of the Damned, but bot does not finish it' & @CRLF _
	& '- This bot farms Golden Rin Relics and Diessa Chalices and bones in the Cathedral of Flames' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/any_Perma_Shadow_Form'

Global Const $COF_FARM_DURATION = 2 * 60 * 1000
Global Const $COF_MAX_FARM_DURATION = 4 * 60 * 1000

; === Dialogs ===
Global Const $QUEST_INIT_DIALOG					= 0x832103
Global Const $QUEST_ACCEPT_DIALOG				= 0x832101
Global Const $ENTER_INIT_DIALOG					= 0x832105
Global Const $ENTER_ACCEPT_DIALOG				= 0x88

; === Undead model IDs ===
Global Const $MODELID_MURAKAI_SERVANT			= 7069
Global Const $MODELID_CRYPT_GHOUL				= 7075
Global Const $MODELID_CRYPT_SLASHER				= 7077
Global Const $MODELID_CRYPT_WRAITH				= 7079
Global Const $MODELID_CRYPT_BANSHEE				= 7081
Global Const $MODELID_SHOCK_PHANTOM				= 7083
Global Const $MODELID_ASH_PHANTOM				= 7085

; Common skills for both builds
Global Const $COF_SIGNET_OF_MYSTIC_SPEED		= 5
Global Const $COF_GRENTHS_AURA					= 6
Global Const $COF_CRIPPLING_VICTORY				= 7
Global Const $COF_REAP_IMPURITIES				= 8

; Skill slots for $D_COF_SKILLBAR
Global Const $COF_VOW_OF_PIETY					= 1
Global Const $COF_VOW_OF_SILENCE				= 2
Global Const $COF_I_AM_UNSTOPPABLE				= 3
Global Const $COF_PIOUS_FURY					= 4

; Skill slots for $A_COF_SKILLBAR
Global Const $COF_SHROUD_OF_DISTRESS			= 1
Global Const $COF_DEADLY_PARADOX				= 2
Global Const $COF_SHADOW_FORM					= 3
Global Const $COF_CRITICAL_AGILITY				= 4

Global $cof_farm_setup							= False
Global $cof_player_profession					= Null
Global $cof_vos_timer							= Null
Global $cof_shadowform_timer					= Null


;~ Main loop of the Cathedral of Flames farm
Func CoFFarm()
	If Not $cof_farm_setup And SetupCoFFarm() == $FAIL Then Return $PAUSE
	GoToCathedralOfFlames()
	Local $result = CoFFarmLoop()
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	Return $result
EndFunc


;~ Farm setup : going to the Doomlore Shrine
Func SetupCoFFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerCoFFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	GoToCathedralOfFlames()
	RandomSleep(2500)
	Move(-19300, -8250)
	RandomSleep(2500)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 2500)
	$cof_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Detects the player's profession, loads the matching skill bar and records which skill slots hold the two shared attack skills.
Func SetupPlayerCoFFarm()
	Info('Setting up player build skill bar')
	$cof_player_profession = DllStructGetData(GetMyAgent(), 'Primary')
	If $cof_player_profession == $ID_DERVISH Then
		If HeroHasTemplate(0, $D_COF_SKILLBAR) Then
			Info('CoF Dervish template already loaded, skipping')
		Else
			LoadSkillTemplate($D_COF_SKILLBAR)
			RandomSleep(250)
		EndIf
	ElseIf $cof_player_profession == $ID_ASSASSIN Then
		If HeroHasTemplate(0, $A_COF_SKILLBAR) Then
			Info('CoF Assassin template already loaded, skipping')
		Else
			LoadSkillTemplate($A_COF_SKILLBAR)
			RandomSleep(250)
		EndIf
	Else
		Warn('Should run this farm as dervish or assassin')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Exit outpost to enter Cathedral of Flames mission
Func GoToCathedralOfFlames()
	TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)
	While GetMapID() <> $ID_CATHEDRAL_OF_FLAMES
		Info('Entering Cathedral of Flames')
		Local $gron = GetNearestNPCToCoords(-19166, 17980)
		GoToNPC($gron)
		If IsQuestNotFound($ID_QUEST_TEMPLE_OF_THE_DAMNED) Then
			TakeQuest($gron, $ID_QUEST_TEMPLE_OF_THE_DAMNED, $QUEST_ACCEPT_DIALOG, $QUEST_INIT_DIALOG)
			Sleep(1000)
		EndIf
		Dialog($ENTER_INIT_DIALOG)
		Sleep(1000)
		Dialog($ENTER_ACCEPT_DIALOG)
		WaitMapLoading($ID_CATHEDRAL_OF_FLAMES)
	WEnd
EndFunc


;~ Farm loop of Cathedral of Flames
Func CoFFarmLoop()
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-18250, -8595))
	Sleep(500)
	Dialog(0x84)
	Sleep(500)

	AggroAndPrepare()
	Info('Farming Cryptos')
	CleanCoFMobs()
	If IsPlayerDead() Then Return $FAIL

	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Opening combo before pulling, dispatched to the active build.
Func AggroAndPrepare()
	MoveTo(-16850, -8930)
	If $cof_player_profession == $ID_DERVISH Then
		UseSkillEx($COF_VOW_OF_PIETY)
		While IsPlayerAlive() And IsRecharged($COF_GRENTHS_AURA)
			UseSkillEx($COF_GRENTHS_AURA)
			RandomSleep(50)
		WEnd
		UseSkillEx($COF_VOW_OF_SILENCE)
		$cof_vos_timer = TimerInit()
	Else
		; No point checking recharges - this is start, everything is recharged
		UseSkillEx($COF_SHROUD_OF_DISTRESS)
		; Getting back 6 energy before casting the rest
		Sleep(3000)
		UseSkillEx($COF_DEADLY_PARADOX)
		UseSkillEx($COF_SHADOW_FORM)
		$cof_shadowform_timer = TimerInit()
		UseSkillEx($COF_CRITICAL_AGILITY)
	EndIf
	UseSkillEx($COF_SIGNET_OF_MYSTIC_SPEED)
	MoveTo(-15220, -8950)
	If $cof_player_profession == $ID_DERVISH Then UseSkillEx($COF_I_AM_UNSTOPPABLE)
	Sleep(500)
EndFunc


;~ Mob-cleaning loop
Func CleanCoFMobs()
	Local $target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndead)
	Local $clock = False
	While $target <> Null And GetDistance(GetMyAgent(), $target) < $MOB_AGGRO_RANGE
		If CheckStuck('CoF', $COF_MAX_FARM_DURATION) == $FAIL Then Return $FAIL
		MaintainCoFBuffs()
		If Not $clock And GetSkillbarSkillAdrenaline($COF_CRIPPLING_VICTORY) >= 150 Then
			UseSkillEx($COF_CRIPPLING_VICTORY, $target)
			$clock = True
		ElseIf $clock And GetSkillbarSkillAdrenaline($COF_REAP_IMPURITIES) >= 120 Then
			UseSkillEx($COF_REAP_IMPURITIES, $target)
			$clock = False
		Else
			Attack($target)
			Sleep(200)
		EndIf
		MaintainCoFBuffs()
		Sleep(100)
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndead)
	WEnd
	RandomSleep(200)
EndFunc


;~ Keeps the build's defensive/offensive enchantments up
Func MaintainCoFBuffs()
	If $cof_player_profession == $ID_DERVISH Then
		If $cof_vos_timer == Null Or TimerDiff($cof_vos_timer) >= 10000 Then
			UseSkillEx($COF_PIOUS_FURY)
			While IsPlayerAlive() And IsRecharged($COF_GRENTHS_AURA)
				UseSkillEx($COF_GRENTHS_AURA)
				RandomSleep(50)
			WEnd
			UseSkillEx($COF_VOW_OF_SILENCE)
			$cof_vos_timer = TimerInit()
		EndIf
	Else
		If TimerDiff($cof_shadowform_timer) > 22000 Then
			UseSkillEx($COF_DEADLY_PARADOX)
			UseSkillEx($COF_SHADOW_FORM)
			$cof_shadowform_timer = TimerInit()
		EndIf

		If IsRecharged($COF_SHROUD_OF_DISTRESS) And GetEffectTimeRemaining(GetEffect($ID_SHROUD_OF_DISTRESS)) == 0 Then UseSkillEx($COF_SHROUD_OF_DISTRESS)

		If IsRecharged($COF_CRITICAL_AGILITY) And GetEffectTimeRemaining(GetEffect($ID_CRITICAL_AGILITY)) == 0 Then UseSkillEx($COF_CRITICAL_AGILITY)

		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 And IsRecharged($COF_GRENTHS_AURA) And GetEnergy() > 24 Then UseSkillEx($COF_GRENTHS_AURA)
	EndIf
EndFunc


Func IsUndead($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return Not GetIsDead($agent) And DllStructGetData($agent, 'HealthPercent') > 0 And _
		($modelID == $MODELID_MURAKAI_SERVANT Or $modelID == $MODELID_CRYPT_GHOUL _
		Or $modelID == $MODELID_CRYPT_SLASHER Or $modelID == $MODELID_CRYPT_WRAITH _
		Or $modelID == $MODELID_CRYPT_BANSHEE Or $modelID == $MODELID_SHOCK_PHANTOM _
		Or $modelID == $MODELID_ASH_PHANTOM)
EndFunc