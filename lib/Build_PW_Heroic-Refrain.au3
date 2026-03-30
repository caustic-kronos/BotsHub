#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2026 caustic-kronos
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

Global Const $BUILD_PW_HR_REFRAINS = 'OQCjUamLKTn19Y1YAh0b4ioYsYA'
Global Const $BUILD_PW_HR_ARIAS = 'OQCkUWm4Ziy0ZdPWNGQI9GuoHGHG'
Global Const $BUILD_PW_HR_ADRENALINE = 'OQGkURll5iy0ZdPWNGQYMIPxVh7G' ; +3+1 Leadership, +1 Spear, +1 Command, +Clarity

; Default build
Global Const $BUILD_PW_HEROIC_REFRAIN = 1
Global Const $BUILD_PW_THEYRE_ON_FIRE = 2
Global Const $BUILD_PW_STAND_YOUR_GROUND = 3					; 20s
Global Const $BUILD_PW_THERES_NOTHING_TO_FEAR = 4				; 20s

; Options
;Global Const $BUILD_PW_LEADERS_COMFORT = 5						; not supported
Global Const $BUILD_PW_CANT_TOUCH_THIS = 5						; 20s
Global Const $BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM = 6		; 20s

; Aria build
Global Const $BUILD_PW_ARIA_OF_RESTORATION = 7					; 20s
Global Const $BUILD_PW_BALLAD_OF_RESTORATION = 8				; 20s
Global Const $BUILD_PW_ARIA_OF_ZEAL = 8							; 20s

; Refrain build
;Global Const $BUILD_PW_MENDING_REFRAIN = 7						; not supported
;Global Const $BUILD_PW_HASTY_REFRAIN = 8						; not supported
Global Const $BUILD_PW_BURNING_REFRAIN = 7
Global Const $BUILD_PW_BLADETURN_REFRAIN = 8

; Adrenaline build - not tested
Global Const $BUILD_PW_SAVE_YOURSELVES = 5
Global Const $BUILD_PW_TO_THE_LIMIT = 6
Global Const $BUILD_PW_FOR_GREAT_JUSTICE = 7
Global Const $BUILD_PW_NATURAL_TEMPER = 7
Global Const $BUILD_PW_AGGRESSIVE_REFRAIN = 8

; Phase constants
Global Const $HR_PHASE_SELF_SETUP = 0
Global Const $HR_PHASE_APPLY_PARTY = 1
Global Const $HR_PHASE_MAINTENANCE = 2

; Adlib interval constants
Global Const $HR_INTERVAL_FAST = 3000
Global Const $HR_INTERVAL_SLOW = 12000

; HR state globals (replaces ctx dictionary for clarity)
Global $hr_phase = $HR_PHASE_SELF_SETUP
Global $hr_party_index = 1
Global $hr_last_tof_time = 0
Global $hr_initialized = False
Global $hr_self_cast_count = 0
Global $hr_last_map_id = 0

Global $registered_shouts = False

; ============================================================================
; Heroic Refrain AdlibRegister Utility
;
; State-machine-based utility for Heroic Refrain maintenance.
; Runs via AdlibRegister, keeping HR active on the entire party regardless
; of the current control flow (movement, combat, sleep, idle, etc.).
;
; Uses a fast interval (3s) during setup/application/pending TOF,
; then switches to a slow interval (12s) for steady-state maintenance.
;
; Phases:
;   SELF_SETUP   - Cast HR on self twice for max Leadership
;   APPLY_PARTY  - Cast HR on each party member (heroes)
;   MAINTENANCE  - Keep HR alive via "They're on Fire!" on cooldown, reapply on rezzed heroes
;
; State resets automatically on death or zone change.
; ============================================================================

;~ AdlibRegister target. Performs at most one phase action per call.
;~ TOF is cast on cooldown at every tick (off global cooldown) to keep existing HR alive.
;~ Interval is dynamic: fast (3s) during setup/apply, slow (12s) during maintenance.
Func TickHeroicRefrain()
	; Leave explorable: unregister and reset
	If GetMapType() <> $ID_EXPLORABLE Or Not IsPlayerAlive() Then
		If $hr_initialized Then ResetHeroicRefrain()
		Return
	EndIf

	; Detect map/floor change and reset (all buffs drop on zone)
	Local $currentMap = GetMapID()
	If $hr_last_map_id <> 0 And $hr_last_map_id <> $currentMap Then
		Debug('HR Utility: Map changed (' & $hr_last_map_id & ' -> ' & $currentMap & '), resetting')
		ResetHeroicRefrain()
	EndIf
	$hr_last_map_id = $currentMap

	; Mark initialized on first successful tick
	If Not $hr_initialized Then
		$hr_initialized = True
		Debug('HR Utility: Initialized, starting self setup')
	EndIf

	; Always cast TOF on cooldown regardless of phase.
	; TOF is off the global cooldown so it can be cast during HR casts, while knocked down, etc.
	; Leadership returns ~10e from party members affected by shouts, making this energy-neutral.
	; Under Quickening Zephyr, TOF recharges before its buff expires. Recasting while active
	; does NOT trigger HR refresh, so we must wait for the old buff to expire first.
	If IsRecharged($BUILD_PW_THEYRE_ON_FIRE) Then
		Local $tofRemaining = GetEffectTimeRemaining($ID_THEYRE_ON_FIRE, 0)
		If $tofRemaining > 0 Then Sleep($tofRemaining + 50)
		UseSkillEx($BUILD_PW_THEYRE_ON_FIRE)
		$hr_last_tof_time = TimerInit()
	EndIf

	If IsCasting(GetMyAgent()) Then Return

	Switch $hr_phase
		Case $HR_PHASE_SELF_SETUP
			HRPhaseSelfSetup()

		Case $HR_PHASE_APPLY_PARTY
			HRPhaseApplyParty()

		Case $HR_PHASE_MAINTENANCE
			HRPhaseMaintenance()
	EndSwitch

	HRAdjustInterval()
EndFunc

;~ Re-register adlib at appropriate interval based on current phase.
;~ Fast (3s) during setup, apply, or pending TOF. Slow (12s) during steady maintenance.
Func HRAdjustInterval()
	If $hr_phase == $HR_PHASE_MAINTENANCE Then
		AdlibRegister('TickHeroicRefrain', $HR_INTERVAL_SLOW)
	Else
		AdlibRegister('TickHeroicRefrain', $HR_INTERVAL_FAST)
	EndIf
EndFunc

;~ Reset all HR state to restart the full application cycle.
;~ Called on zone change, death, or map transition.
Func ResetHeroicRefrain()
	$hr_phase = $HR_PHASE_SELF_SETUP
	$hr_party_index = 1
	$hr_last_tof_time = 0
	$hr_initialized = False
	$hr_self_cast_count = 0
	Debug('HR Utility: State reset')
EndFunc

;~ Cast HR on self twice, then advance to APPLY_PARTY.
;~ Tracked by counter, not effect checking. Resets on death/zone.
Func HRPhaseSelfSetup()
	If $hr_self_cast_count >= 2 Then
		$hr_phase = $HR_PHASE_APPLY_PARTY
		$hr_party_index = 1
		Debug('HR Utility: Self setup complete (' & $hr_self_cast_count & ' casts)')
		Return
	EndIf

	If Not IsRecharged($BUILD_PW_HEROIC_REFRAIN) Then Return
	If GetEnergy() < 5 Then Return

	Local $me = GetMyAgent()
	If UseSkillEx($BUILD_PW_HEROIC_REFRAIN, $me) Then
		$hr_self_cast_count += 1
		Debug('HR Utility: Self cast ' & $hr_self_cast_count & '/2')
	EndIf
EndFunc

;~ Find next party member without HR and cast it on them.
;~ Skips dead, invalid, and out-of-range heroes; retries skipped heroes on next pass.
Func HRPhaseApplyParty()
	If Not IsRecharged($BUILD_PW_HEROIC_REFRAIN) Then Return

	Local $heroCount = GetHeroCount()
	Local $idx = $hr_party_index
	Local $me = GetMyAgent()
	Local $skippedOutOfRange = False

	While $idx <= $heroCount
		Local $agentID = GetHeroID($idx)
		If $agentID == 0 Then
			$idx += 1
			ContinueLoop
		EndIf

		Local $agent = GetAgentByID($agentID)
		; Skip dead or invalid heroes
		If $agent == Null Or GetIsDead($agent) Then
			$idx += 1
			ContinueLoop
		EndIf

		; Skip heroes that already have HR
		If GetEffect($ID_HEROIC_REFRAIN, $idx) <> Null Then
			$idx += 1
			ContinueLoop
		EndIf

		; Skip heroes too far away - try them on the next pass
		If GetDistance($me, $agent) > $RANGE_SPELLCAST Then
			$skippedOutOfRange = True
			$idx += 1
			ContinueLoop
		EndIf

		; Cast HR on this hero
		If UseSkillEx($BUILD_PW_HEROIC_REFRAIN, $agent) Then
			$hr_party_index = $idx + 1
			Debug('HR Utility: Cast HR on party member ' & $idx)
			Return
		EndIf

		; Cast failed (energy, etc.) - try again next tick
		$hr_party_index = $idx
		Return
	WEnd

	; Some heroes were out of range - loop back to try them again
	If $skippedOutOfRange Then
		$hr_party_index = 1
		Return
	EndIf

	; All party members processed - enter maintenance
	$hr_phase = $HR_PHASE_MAINTENANCE
	$hr_last_tof_time = TimerInit()
	Debug('HR Utility: All party buffed, entering maintenance')
EndFunc

;~ Maintenance phase: reapply HR on rezzed heroes. TOF is handled at top of tick.
Func HRPhaseMaintenance()
	; Recovery: if player lost HR (death/respawn, buff expiry), restart full cycle
	If GetEffect($ID_HEROIC_REFRAIN, 0) == Null Then
		$hr_phase = $HR_PHASE_SELF_SETUP
		$hr_self_cast_count = 0
		$hr_party_index = 1
		Debug('HR Utility: Player lost HR, restarting self setup')
		HRPhaseSelfSetup()
		Return
	EndIf

	; Recovery: check party members for dropped HR (e.g. hero was rezzed) and reapply
	Local $heroCount = GetHeroCount()
	For $i = 1 To $heroCount
		Local $agentID = GetHeroID($i)
		If $agentID == 0 Then ContinueLoop

		Local $agent = GetAgentByID($agentID)
		If $agent == Null Or GetIsDead($agent) Then ContinueLoop

		If GetEffect($ID_HEROIC_REFRAIN, $i) == Null Then
			If IsRecharged($BUILD_PW_HEROIC_REFRAIN) And GetDistance(GetMyAgent(), $agent) <= $RANGE_SPELLCAST Then
				If UseSkillEx($BUILD_PW_HEROIC_REFRAIN, $agent) Then
					Debug('HR Utility: Reapplied HR on party member ' & $i)
					Return
				EndIf
			EndIf
			Return
		EndIf
	Next
EndFunc


; ============================================================================
; Adrenaline Build Fight Function (non-blocking, tick-based)
;
; Skill priority (highest to lowest):
;   1. Aggressive Refrain (25e, once if not already buffed)
;   2. Auto-attack (always ensure attacking target)
;   3. "Stand Your Ground!" (only if party not already buffed)
;   4. "There's Nothing to Fear!" (15e)
;   5. "Save Yourselves!" (adrenaline >= 200)
;   6. "To the Limit!" (only if foes in earshot, adrenaline gain)
;   7. "For Great Justice!" (5e, lowest priority)
;
; Note: HR maintenance is handled by AdlibRegister, not by this function.
; ============================================================================

;~ Non-blocking fight tick for the HR Adrenaline build.
;~ Call every fight loop iteration. Performs at most one skill cast per call.
;~
;~ $target - current enemy agent (or Null for untargeted shouts)
Func FightAdrenalineTick($target = Null)
	; Guards
	If Not IsPlayerAlive() Then Return
	If IsCasting(GetMyAgent()) Then Return

	; Priority 1: Aggressive Refrain — only if not already active, costs 25e, only in combat
	If $target <> Null And GetEffect($ID_AGGRESSIVE_REFRAIN, 0) == Null Then
		If GetEnergy() >= 25 And IsRecharged($BUILD_PW_AGGRESSIVE_REFRAIN) Then
			UseSkillEx($BUILD_PW_AGGRESSIVE_REFRAIN)
			Return
		EndIf
	EndIf

	; Priority 2: Ensure we are attacking the target
	If $target <> Null Then Attack($target)

	; Priority 3: "Stand Your Ground!" — only if party not already buffed
	If IsRecharged($BUILD_PW_STAND_YOUR_GROUND) Then
		If GetEffect($ID_STAND_YOUR_GROUND, 0) == Null Then
			UseSkillEx($BUILD_PW_STAND_YOUR_GROUND)
			Return
		EndIf
	EndIf

	; Priority 4: "There's Nothing to Fear!" (15e)
	If IsRecharged($BUILD_PW_THERES_NOTHING_TO_FEAR) And GetEnergy() >= 15 Then
		UseSkillEx($BUILD_PW_THERES_NOTHING_TO_FEAR)
		Return
	EndIf

	; Priority 5: "Save Yourselves!" (adrenaline-based, 200 required)
	If GetSkillbarSkillAdrenaline($BUILD_PW_SAVE_YOURSELVES) >= 200 Then
		UseSkillEx($BUILD_PW_SAVE_YOURSELVES)
		Return
	EndIf

	; Priority 6: "To the Limit!" (only if foes nearby for adrenaline gain)
	If IsRecharged($BUILD_PW_TO_THE_LIMIT) And CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then
		UseSkillEx($BUILD_PW_TO_THE_LIMIT)
		Return
	EndIf

	; Priority 7: "For Great Justice!" (5e, lowest priority)
	If IsRecharged($BUILD_PW_FOR_GREAT_JUSTICE) And GetEnergy() >= 5 Then
		If GetEffect($ID_FOR_GREAT_JUSTICE, 0) == Null Then
			UseSkillEx($BUILD_PW_FOR_GREAT_JUSTICE)
			Return
		EndIf
	EndIf
EndFunc


; ============================================================================
; HR Adrenaline Build Setup & Callbacks
;
; Reusable setup and callback functions for any farm/mission script using
; the HR Adrenaline build. Call SetupHRAdrenalineBuild() once during setup.
; HR maintenance runs automatically via AdlibRegister.
; Combat function is wired through active build globals.
; ============================================================================

;~ Set up the HR Adrenaline build: load template, register HR maintenance, set combat globals.
;~ Paragon does not flag heroes, so both active options use the same non-flag dict.
Func SetupHRAdrenalineBuild()
	LoadSkillTemplate($BUILD_PW_HR_ADRENALINE)
	ResetHeroicRefrain()
	AdlibRegister('TickHeroicRefrain', $HR_INTERVAL_FAST)

	Local $fightOptions = CloneDictMap($default_move_aggro_kill_options)
	$fightOptions.Item('combatFunction') = HRAdrenalineCombat

	$active_fight_options = $fightOptions
	$active_flag_fight_options = $fightOptions
EndFunc

;~ Combat callback for KillFoesInArea: loops Attack + FightAdrenalineTick until target is dead.
Func HRAdrenalineCombat($target, $options)
	GetAlmostInRangeOfAgent($target)
	Attack($target)
	Sleep(100)
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		Attack($target)
		FightAdrenalineTick($target)
		Sleep(100)
		$target = GetCurrentTarget()
		If IsPlayerDead() Then ExitLoop
	WEnd
EndFunc


; ============================================================================
; Legacy functions below (AdlibRegister-based approach)
; ============================================================================

;~ This function should be put on a 11 to 15s adlibregister
Func MaintainHeroicRefrain()
	Local Static $castBladeturnRefrain = GetSkillbarSkillID($BUILD_PW_BLADETURN_REFRAIN) == $ID_BLADETURN_REFRAIN
	Local Static $castBurningRefrain = GetSkillbarSkillID($BUILD_PW_BURNING_REFRAIN) == $ID_BURNING_REFRAIN
	Local Static $castAggressiveRefrain = GetSkillbarSkillID($BUILD_PW_AGGRESSIVE_REFRAIN) == $ID_AGGRESSIVE_REFRAIN

	If GetMapType() <> $ID_EXPLORABLE Then
		AdlibUnRegister('MaintainHeroicRefrain')
		$registered_shouts = False
		Return
	EndIf

	; Maintaining
	UseSkillEx($BUILD_PW_THEYRE_ON_FIRE)
	RandomSleep(20 + GetPing())

	; Not casting refrains if not enough energy to guarantee the next theyre on fire
	Local $energy = GetEnergy()
	If $energy < 10 Then Return

	; Aggressive Refrain check
	If $castAggressiveRefrain And $energy > 15 Then
		If GetEffect($ID_AGGRESSIVE_REFRAIN, 0) == Null Then
			While IsPlayerAlive() And GetEnergy() < 25
				Sleep(1000)
			WEnd
			UseSkillEx($BUILD_PW_AGGRESSIVE_REFRAIN)
			RandomSleep(20 + GetPing())
			Return
		EndIf
	EndIf

	; Recasting HR on character to get max +4 stats
	Local Static $castHRSecondTime = False
	If $castHRSecondTime Then
		UseSkillEx($BUILD_PW_HEROIC_REFRAIN, GetMyAgent())
		RandomSleep(20 + GetPing())
		$castHRSecondTime = False
		Return
	EndIf

	; Checking if our characters have refrains on
	Local $missingRefrain = -1
	Local $missingCharacter = -1
	For $i = 0 To 7
		; Getting all effects is more efficient if we check several effects
		Local $effectsArray = GetEffect(0, $i)

		Local $heroicRefrain = False
		Local $bladeRefrain = $castBladeturnRefrain ? False : True
		Local $burningRefrain = $castBurningRefrain ? False : True
		For $effect In $effectsArray
			Local $effectID = DllStructGetData($effect, 'SkillID')
			If $effectID == $ID_HEROIC_REFRAIN Then
				$heroicRefrain = True
			ElseIf $effectID == $ID_BLADETURN_REFRAIN Then
				$bladeRefrain = True
			ElseIf $effectID == $ID_BURNING_REFRAIN Then
				$burningRefrain = True
			EndIf

			If $heroicRefrain And $bladeRefrain And $burningRefrain Then ExitLoop
		Next

		; Heroic Refrain is priority so it is instantly casted
		If Not $heroicRefrain Then
			$missingRefrain = $BUILD_PW_HEROIC_REFRAIN
			$missingCharacter = $i
			If $i == 0 Then $castHRSecondTime = True
			ExitLoop
		EndIf
		; If we already found a missing refrain no need to check more than HR
		If $missingRefrain <> -1 Then ContinueLoop

		; Other refrains must wait until we are sure we are not missing HR on someone
		If Not $bladeRefrain Then
			$missingRefrain = $BUILD_PW_BLADETURN_REFRAIN
			$missingCharacter = $i
		ElseIf Not $burningRefrain Then
			$missingRefrain = $BUILD_PW_BURNING_REFRAIN
			$missingCharacter = $i
		EndIf
	Next

	Local $target
	If $missingCharacter < 0 Then
		Return
	ElseIf $missingCharacter == 0 Then
		$target = GetMyAgent()
	Else
		$target = GetAgentByID(GetHeroID($missingCharacter))
	EndIf

	UseSkillEx($missingRefrain, $target)
	RandomSleep(20 + GetPing())
EndFunc


Func FightAsPWHeroicRefrain($target, $options = Null)
	Local Static $castBattleStandard = GetSkillbarSkillID($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM) == $ID_EBON_BATTLE_STANDARD_OF_WISDOM
	Local Static $castCantTouchThis = GetSkillbarSkillID($BUILD_PW_CANT_TOUCH_THIS) == $ID_CANT_TOUCH_THIS
	Local Static $castAriaOfRestoration = GetSkillbarSkillID($BUILD_PW_ARIA_OF_RESTORATION) == $ID_ARIA_OF_RESTORATION
	Local Static $castAriaOfZeal = GetSkillbarSkillID($BUILD_PW_ARIA_OF_ZEAL) == $ID_ARIA_OF_ZEAL
	Local Static $castBalladOfRestoration = GetSkillbarSkillID($BUILD_PW_BALLAD_OF_RESTORATION) == $ID_BALLAD_OF_RESTORATION
	Local Static $castSaveYourselves = GetSkillbarSkillID($BUILD_PW_SAVE_YOURSELVES) == $ID_SAVE_YOURSELVES_KURZICK Or GetSkillbarSkillID($BUILD_PW_SAVE_YOURSELVES) == $ID_SAVE_YOURSELVES_LUXON
	Local Static $castNaturalTemper = GetSkillbarSkillID($BUILD_PW_NATURAL_TEMPER) == $ID_NATURAL_TEMPER
	Local Static $castToTheLimit = GetSkillbarSkillID($BUILD_PW_TO_THE_LIMIT) == $ID_TO_THE_LIMIT

	If Not $registered_shouts And GetMapType() == $ID_EXPLORABLE Then
		AdlibRegister('MaintainHeroicRefrain', 12000)
		$registered_shouts = True
	EndIf

	; get as close as possible to target foe to have a surprise effect when attacking
	GetAlmostInRangeOfAgent($target)
	Attack($target)
	Sleep(1500)

	; Timer used for Stand your ground, there is nothing to fear and cant touch this
	Local Static $timer20s = Null

	If $timer20s == Null Or TimerDiff($timer20s) > 20000 Then
		GetIntoTeamRange()
		Local $ping = GetPing()
		UseSkillEx($BUILD_PW_STAND_YOUR_GROUND)
		Sleep(20 + $ping)
		UseSkillEx($BUILD_PW_THERES_NOTHING_TO_FEAR)
		Sleep(20 + $ping)
		If $castBattleStandard And GetEnergy() >= 20 Then
			UseSkillEx($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM)
			Sleep(20 + $ping)
		EndIf
		If $castCantTouchThis Then
			UseSkillEx($BUILD_PW_CANT_TOUCH_THIS)
			Sleep(20 + $ping)
		EndIf
		If $castAriaOfRestoration Then
			UseSkillEx($BUILD_PW_ARIA_OF_RESTORATION)
			Sleep(20 + $ping)
		EndIf
		If $castBalladOfRestoration Then
			UseSkillEx($BUILD_PW_BALLAD_OF_RESTORATION)
			Sleep(20 + $ping)
		EndIf
		If $castAriaOfZeal Then
			UseSkillEx($BUILD_PW_ARIA_OF_ZEAL)
			Sleep(20 + $ping)
		EndIf
		If $castToTheLimit Then
			UseSkillEx($BUILD_PW_TO_THE_LIMIT)
			Sleep(20 + $ping)
		EndIf
		$timer20s = TimerInit()
	EndIf

	If $castSaveYourselves And GetSkillbarSkillAdrenaline($BUILD_PW_SAVE_YOURSELVES) >= 200 Then
		UseSkillEx($BUILD_PW_SAVE_YOURSELVES)
		Sleep(20 + GetPing())
	EndIf

	If $castNaturalTemper And GetSkillbarSkillAdrenaline($BUILD_PW_NATURAL_TEMPER) >= 75 Then
		UseSkillEx($BUILD_PW_NATURAL_TEMPER)
		Sleep(20 + GetPing())
	EndIf
EndFunc
