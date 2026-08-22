#CS ===========================================================================
; Authors: DeeperBlue, unknown (Dervish original)
; Contributor: Gahais, GitHub Copilot (Assassin adaptation)
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
; Cathedral of Flames — Assassin variant using Deadly Paradox + Shadow Form
; for permanent spell immunity (replaces Dervish Vow of Silence).
; This "CA" variant trades "I Am Unstoppable!" for Critical Agility (IAS).
; Perma maintenance is adapted from FocusHanaku.au3.
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
Global Const $COFSINCA_PLAYER_SKILLBAR = 'Owpk8xjYaqWEPiOzB0YozV3XNImI'
Global Const $COFSINCA_FARM_INFORMATIONS = 'CoF Assassin CA variant — perma Shadow Form + Critical Agility (IAS).' & @CRLF _
	& '- Zealous Scythe of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- +1+3 Shadow Arts Rune' & @CRLF _
	& '- +1 Deadly Arts Rune' & @CRLF _
	& '- +1 Scythe Mastery Rune' & @CRLF _
	& '- +50 HP Rune' & @CRLF _
	& '- +2 Energy Rune' & @CRLF _
	& '- Windwalker or blessed insignias' & @CRLF _
	& '- This bot enters the Quest Temple of the Damned, but bot does not finish it' & @CRLF _
	& '- This bot farms Golden Rin Relics and Diessa Chalices and bones in the Cathedral of Flames' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:D/any_General_Vow_of_Silence_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/any_Perma_Shadow_Form'
Global Const $COFSINCA_FARM_DURATION = 5 * 60 * 1000


; === Dialogs (same as Dervish CoF) ===
Global Const $COFSINCA_QUEST_INIT_DIALOG = 0x832103
Global Const $COFSINCA_QUEST_ACCEPT_DIALOG = 0x832101
Global Const $COFSINCA_ENTER_INIT_DIALOG = 0x832105
Global Const $COFSINCA_ENTER_ACCEPT_DIALOG = 0x88

Global Const $COFSINCA_MODELID_MURAKAI_SERVANT	= 7069
Global Const $COFSINCA_MODELID_CRYPT_GHOUL		= 7075
Global Const $COFSINCA_MODELID_CRYPT_SLASHER	= 7077
Global Const $COFSINCA_MODELID_CRYPT_WRAITH		= 7079
Global Const $COFSINCA_MODELID_CRYPT_BANSHEE	= 7081
Global Const $COFSINCA_MODELID_SHOCK_PHANTOM	= 7083
Global Const $COFSINCA_MODELID_ASH_PHANTOM		= 7085

; Skill slots (template Owpk8xjYaqWEPiOzB0YozV3XNImI — CA replaces IAU at slot 7)
Global Const $COFSINCA_DEADLY_PARADOX			= 1
Global Const $COFSINCA_SHADOW_FORM				= 2
Global Const $COFSINCA_SHROUD_OF_DISTRESS		= 3
Global Const $COFSINCA_CRIPPLING_VICTORY		= 4
Global Const $COFSINCA_REAP_IMPURITIES			= 5
Global Const $COFSINCA_GRENTHS_AURA				= 6
Global Const $COFSINCA_CRITICAL_AGILITY			= 7
Global Const $COFSINCA_SIGNET_OF_MYSTIC_SPEED	= 8

; Perma SF+DP timing (same rhythm as FocusHanaku)
Global Const $COFSINCA_SF_DP_MIN_ENERGY = 20
Global Const $COFSINCA_DP_AFTER_SF_DELAY_MS = 500
Global Const $COFSINCA_SF_QUEUE_RETRY_MS = 1500
Global Const $COFSINCA_COMBAT_TIMEOUT_MS = 10 * 60 * 1000 ; Abort combat after 10 min
Global Const $COFSINCA_DEBUG_LOG = False ; Set to True to enable CSV debug logging (logs/cofsinca_debug-*.csv)

Global $cofsinca_farm_setup = False
Global $cofsinca_log_handle = -1
Global $cofsinca_log_timer = 0
Global $cofsinca_log_run = 0


;~ Main loop of the Cathedral of Flames farm (Assassin CA)
Func CoFSinCAFarm()
	$cofsinca_log_run += 1
	CoFSinCALogInit()
	CoFSinCALogWrite('run_start')

	If Not $cofsinca_farm_setup And SetupCoFSinCAFarm() == $FAIL Then
		CoFSinCALogWrite('run_end', 'result=fail;reason=setup')
		CoFSinCALogClose()
		Return $PAUSE
	EndIf
	Sleep(10000)
	GoToCathedralOfFlamesSinCA()
	Local $result = CoFSinCAFarmLoop()
	CoFSinCALogWrite('run_end', 'result=' & $result)
	CoFSinCALogClose()
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	Return $result
EndFunc


;~ Farm setup : going to the Doomlore Shrine
Func SetupCoFSinCAFarm()
	Info('Setting up CoF Sin CA farm')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerCoFSinCAFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	GoToCathedralOfFlamesSinCA()
	RandomSleep(2500)
	Move(-19300, -8250)
	RandomSleep(2500)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 2500)
	$cofsinca_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerCoFSinCAFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ASSASSIN Then
		If HeroHasTemplate(0, $COFSINCA_PLAYER_SKILLBAR) Then
			Info('CoF Sin CA player: template already loaded, skipping')
		Else
			LoadSkillTemplate($COFSINCA_PLAYER_SKILLBAR)
		EndIf
		RandomSleep(250)
	Else
		Warn('Should run this farm as assassin')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Exit outpost to enter Cathedral of Flames mission
Func GoToCathedralOfFlamesSinCA()
	TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name)
	While GetMapID() <> $ID_CATHEDRAL_OF_FLAMES
		Info('Entering Cathedral of Flames')
		Local $gron = GetNearestNPCToCoords(-19166, 17980)
		GoToNPC($gron)
		If IsQuestNotFound($ID_QUEST_TEMPLE_OF_THE_DAMNED) Then
			TakeQuest($gron, $ID_QUEST_TEMPLE_OF_THE_DAMNED, $COFSINCA_QUEST_ACCEPT_DIALOG, $COFSINCA_QUEST_INIT_DIALOG)
			Sleep(1000)
		EndIf
		Dialog($COFSINCA_ENTER_INIT_DIALOG)
		Sleep(1000)
		Dialog($COFSINCA_ENTER_ACCEPT_DIALOG)
		WaitMapLoading($ID_CATHEDRAL_OF_FLAMES)
	WEnd
EndFunc


;~ Farm loop of Cathedral of Flames (Assassin CA)
Func CoFSinCAFarmLoop()
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-18250, -8595))
	Sleep(500)
	Dialog(0x84)
	Sleep(500)

	AggroAndPrepareSinCA()
	Info('Farming Cryptos')
	CleanCoFSinCAMobs()
	If IsPlayerDead() Then Return $FAIL

	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func AggroAndPrepareSinCA()
	MoveTo(-16850, -8930)
	; Open with SF + DP (the core perma chain from Hanaku).
	If IsRecharged($COFSINCA_SHADOW_FORM) Then UseSkill($COFSINCA_SHADOW_FORM)
	RandomSleep($COFSINCA_DP_AFTER_SF_DELAY_MS)
	If IsRecharged($COFSINCA_DEADLY_PARADOX) Then UseSkill($COFSINCA_DEADLY_PARADOX)
	; Shroud of Distress replaces Vow of Piety as the defensive layer.
	If IsRecharged($COFSINCA_SHROUD_OF_DISTRESS) Then UseSkillEx($COFSINCA_SHROUD_OF_DISTRESS)
	RandomSleep(80)
	; Critical Agility for IAS (replaces IAU).
	If IsRecharged($COFSINCA_CRITICAL_AGILITY) Then UseSkillEx($COFSINCA_CRITICAL_AGILITY)
	RandomSleep(80)
	; Signet of Mystic Speed.
	If IsRecharged($COFSINCA_SIGNET_OF_MYSTIC_SPEED) Then UseSkillEx($COFSINCA_SIGNET_OF_MYSTIC_SPEED)
	RandomSleep(80)
	MoveTo(-15220, -8950)
	Sleep(500)
EndFunc


;~ Maintain permament Shadow Form via Deadly Paradox (adapted from FocusHanaku.au3).
;~ Also refreshes Shroud of Distress, Grenth's Aura and Critical Agility when needed.
;~ @param $allowUtilityCasts - when True, utility enchants are recast on expiry.
Func MaintainCoFSinCAPerma($allowUtilityCasts = True)
	If IsPlayerDead() Then Return
	Local Static $sfQueueTimer = Null

	Local $sfRechargedNow = IsRecharged($COFSINCA_SHADOW_FORM)
	Local $energyNow = GetEnergy()

	; Cast DP first, wait 0.5s, then cast SF — so SF snapshots DP's 33% faster recharge.
	If $sfRechargedNow And $energyNow >= $COFSINCA_SF_DP_MIN_ENERGY And ($sfQueueTimer == Null Or TimerDiff($sfQueueTimer) > $COFSINCA_SF_QUEUE_RETRY_MS) Then
		If IsRecharged($COFSINCA_DEADLY_PARADOX) Then
			CoFSinCALogWrite('dp_cast', 'e=' & Int($energyNow))
			UseSkill($COFSINCA_DEADLY_PARADOX)
			$sfQueueTimer = TimerInit()
			Local $sfTimer = TimerInit()
			While IsPlayerAlive() And TimerDiff($sfTimer) < $COFSINCA_DP_AFTER_SF_DELAY_MS
				Sleep(10)
			WEnd
			CoFSinCALogWrite('sf_cast', 'delta_ms=' & Int(TimerDiff($sfQueueTimer)) & ';e=' & Int(GetEnergy()))
			UseSkill($COFSINCA_SHADOW_FORM)
		Else
			CoFSinCALogWrite('sf_skip', 'reason=dp_not_ready;e=' & Int($energyNow))
		EndIf
		Return
	EndIf

	; Shroud of Distress — keep it up (replaces Vow of Piety).
	If $allowUtilityCasts And IsRecharged($COFSINCA_SHROUD_OF_DISTRESS) Then
		Local $sodRemaining = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
		If $sodRemaining <= 2500 Then
			CoFSinCALogWrite('sod_cast', 'remaining_ms=' & Int($sodRemaining))
			UseSkillEx($COFSINCA_SHROUD_OF_DISTRESS)
		EndIf
	EndIf

	; Critical Agility — IAS enchantment; self-renews on crit, but recast if it falls off.
	If $allowUtilityCasts And IsRecharged($COFSINCA_CRITICAL_AGILITY) And GetEnergy() > 12 Then
		If GetEffectTimeRemaining($ID_CRITICAL_AGILITY) <= 500 Then
			CoFSinCALogWrite('ca_cast')
			UseSkillEx($COFSINCA_CRITICAL_AGILITY)
		EndIf
	EndIf

	; Grenth's Aura for sustain — cast when health dips.
	If $allowUtilityCasts And IsRecharged($COFSINCA_GRENTHS_AURA) And GetEnergy() > 24 Then
		If DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.90 Then
			CoFSinCALogWrite('ga_cast', 'hp=' & StringFormat('%.2f', DllStructGetData(GetMyAgent(), 'HealthPercent')))
			UseSkillEx($COFSINCA_GRENTHS_AURA)
		EndIf
	EndIf
EndFunc


Func CleanCoFSinCAMobs()
	Local $target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndeadSinCA)
	Local $clock = False
	Local $logHeartbeat = TimerInit()
	Local $combatTimer = TimerInit()
	While $target <> Null And GetDistance(GetMyAgent(), $target) < $MOB_AGGRO_RANGE And TimerDiff($combatTimer) < $COFSINCA_COMBAT_TIMEOUT_MS
		If TimerDiff($logHeartbeat) > 3000 Then
			Local $sfMs = GetEffectTimeRemaining($ID_SHADOW_FORM)
			Local $dpReady = IsRecharged($COFSINCA_DEADLY_PARADOX)
			Local $sfReady = IsRecharged($COFSINCA_SHADOW_FORM)
			CoFSinCALogWrite('combat_tick', 'sf_ms=' & Int($sfMs) & ';sf_ready=' & $sfReady & ';dp_ready=' & $dpReady & ';e=' & Int(GetEnergy()) & ';hp=' & StringFormat('%.2f', DllStructGetData(GetMyAgent(), 'HealthPercent')) & ';a4=' & GetSkillbarSkillAdrenaline($COFSINCA_CRIPPLING_VICTORY) & ';a5=' & GetSkillbarSkillAdrenaline($COFSINCA_REAP_IMPURITIES))
			$logHeartbeat = TimerInit()
		EndIf
		; Check perma BEFORE blocking skill casts — SF window is tight (~1.4s)
		MaintainCoFSinCAPerma()
		If Not $clock And GetSkillbarSkillAdrenaline($COFSINCA_CRIPPLING_VICTORY) >= 150 Then
			CoFSinCALogWrite('cv_cast')
			UseSkillEx($COFSINCA_CRIPPLING_VICTORY, $target)
			$clock = True
		ElseIf $clock And GetSkillbarSkillAdrenaline($COFSINCA_REAP_IMPURITIES) >= 120 Then
			CoFSinCALogWrite('reap_cast')
			UseSkillEx($COFSINCA_REAP_IMPURITIES, $target)
			$clock = False
		Else
			Attack($target)
			Sleep(200)
		EndIf
		MaintainCoFSinCAPerma()
		Sleep(100)
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsUndeadSinCA)
	WEnd
	If TimerDiff($combatTimer) >= $COFSINCA_COMBAT_TIMEOUT_MS Then
		CoFSinCALogWrite('combat_timeout', 'elapsed_ms=' & Int(TimerDiff($combatTimer)))
		Warn('CoF Sin CA: combat timeout after ' & Int(TimerDiff($combatTimer) / 1000) & 's')
	EndIf
	RandomSleep(200)
EndFunc


Func IsUndeadSinCA($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return Not GetIsDead($agent) And DllStructGetData($agent, 'HealthPercent') > 0 And _
		($modelID == $COFSINCA_MODELID_MURAKAI_SERVANT Or $modelID == $COFSINCA_MODELID_CRYPT_GHOUL _
		Or $modelID == $COFSINCA_MODELID_CRYPT_SLASHER Or $modelID == $COFSINCA_MODELID_CRYPT_WRAITH _
		Or $modelID == $COFSINCA_MODELID_CRYPT_BANSHEE Or $modelID == $COFSINCA_MODELID_SHOCK_PHANTOM _
		Or $modelID == $COFSINCA_MODELID_ASH_PHANTOM)
EndFunc


#Region Debug CSV logging
Func CoFSinCALogInit()
	If Not $COFSINCA_DEBUG_LOG Then Return
	Local $timestamp = @YEAR & @MON & @MDAY & '_' & @HOUR & @MIN & @SEC
	Local $path = @ScriptDir & '/logs/cofsinca_debug-' & GetCharacterName() & '-run' & $cofsinca_log_run & '-' & $timestamp & '.csv'
	$cofsinca_log_handle = FileOpen($path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	$cofsinca_log_timer = TimerInit()
	If $cofsinca_log_handle == -1 Then Return
	Info('CoF Sin CA CSV: ' & $path)
	FileWriteLine($cofsinca_log_handle, 'time_ms;run;event;energy;hp;sf_ms;sod_ms;ca_ms;sf_ready;dp_ready;sod_ready;a4;a5;note')
EndFunc

Func CoFSinCALogClose()
	If $cofsinca_log_handle == -1 Then Return
	FileClose($cofsinca_log_handle)
	$cofsinca_log_handle = -1
EndFunc

Func CoFSinCALogWrite($eventName, $note = '')
	If $cofsinca_log_handle == -1 Then Return
	Local $timeMs = Int(TimerDiff($cofsinca_log_timer))
	Local $me = GetMyAgent()
	Local $energy = GetEnergy()
	Local $hp = DllStructGetData($me, 'HealthPercent')
	Local $sfMs = GetEffectTimeRemaining($ID_SHADOW_FORM)
	Local $sodMs = GetEffectTimeRemaining($ID_SHROUD_OF_DISTRESS)
	Local $caMs = GetEffectTimeRemaining($ID_CRITICAL_AGILITY)
	Local $sfReady = IsRecharged($COFSINCA_SHADOW_FORM)
	Local $dpReady = IsRecharged($COFSINCA_DEADLY_PARADOX)
	Local $sodReady = IsRecharged($COFSINCA_SHROUD_OF_DISTRESS)
	Local $a4 = GetSkillbarSkillAdrenaline($COFSINCA_CRIPPLING_VICTORY)
	Local $a5 = GetSkillbarSkillAdrenaline($COFSINCA_REAP_IMPURITIES)
	Local $safeNote = StringReplace($note, ';', ',')
	FileWriteLine($cofsinca_log_handle, $timeMs & ';' & $cofsinca_log_run & ';' & $eventName & ';' & $energy & ';' & $hp & ';' & $sfMs & ';' & $sodMs & ';' & $caMs & ';' & $sfReady & ';' & $dpReady & ';' & $sodReady & ';' & $a4 & ';' & $a5 & ';' & $safeNote)
EndFunc
#EndRegion Debug CSV logging
