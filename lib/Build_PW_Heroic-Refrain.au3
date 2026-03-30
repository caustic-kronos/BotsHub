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
Global Const $BUILD_PW_AGGRESSIVE_REFRAIN = 8
;Global Const $BUILD_PW_NATURAL_TEMPER = 7

; Phase constants
Global Const $HR_PHASE_SELF_SETUP = 0
Global Const $HR_PHASE_APPLY_PARTY = 1
Global Const $HR_PHASE_MAINTENANCE = 2

Global $registered_shouts = False
Global $hr_adrenaline_ctx = Null

; ============================================================================
; Heroic Refrain Tick-based Utility
;
; Non-blocking, state-machine-based utility for Heroic Refrain maintenance.
; Call HeroicRefrain_Init() once to create a context, then call
; HeroicRefrain_Tick($ctx) repeatedly from your fight/movement loop.
;
; Phases:
;   SELF_SETUP   - Cast HR on self twice for max Leadership
;   APPLY_PARTY  - Cast HR on each party member (heroes)
;   MAINTENANCE  - Keep HR alive via "They're on Fire!" on cooldown, reapply on rezzed heroes
;
; State resets automatically on death or zone change.
; ============================================================================

;~ Create and return a new Heroic Refrain context dictionary.
;~ Call this once before entering your fight loop.
Func HeroicRefrain_Init()
	Local $ctx = ObjCreate('Scripting.Dictionary')
	$ctx.Add('phase', $HR_PHASE_SELF_SETUP)
	$ctx.Add('pendingTOF', False)
	$ctx.Add('partyIndex', 1)
	$ctx.Add('lastTOFTime', 0)
	$ctx.Add('lastHRCastTime', 0)
	$ctx.Add('initialized', False)
	$ctx.Add('selfCastCount', 0)
	$ctx.Add('lastMapID', 0)
	Return $ctx
EndFunc

;~ Non-blocking tick function for Heroic Refrain management.
;~ Performs at most one skill cast per call. Returns immediately if nothing to do.
;~
;~ $ctx - context dictionary from HeroicRefrain_Init()
;~
;~ Returns:
;~   True  - an action was taken this tick (skill cast attempted)
;~   False - nothing to do this tick (idle / waiting for recharge)
Func HeroicRefrain_Tick($ctx)
	; Reset state on zone change or death
	If GetMapType() <> $ID_EXPLORABLE Or Not IsPlayerAlive() Then
		If $ctx.Item('initialized') Then HeroicRefrain_Reset($ctx)
		Return False
	EndIf

	; Detect map/floor change and reset (all buffs drop on zone)
	Local $currentMap = GetMapID()
	If $ctx.Item('lastMapID') <> 0 And $ctx.Item('lastMapID') <> $currentMap Then
		Debug('HR Utility: Map changed (' & $ctx.Item('lastMapID') & ' -> ' & $currentMap & '), resetting')
		HeroicRefrain_Reset($ctx)
	EndIf
	$ctx.Item('lastMapID') = $currentMap

	If IsCasting(GetMyAgent()) Then Return False

	; Mark initialized on first successful tick
	If Not $ctx.Item('initialized') Then
		$ctx.Item('initialized') = True
		Debug('HR Utility: Initialized, starting self setup')
	EndIf

	; Priority: cast "They are on Fire!" follow-up after any HR cast
	If $ctx.Item('pendingTOF') Then
		Return _HR_TryCastPendingTOF($ctx)
	EndIf

	Switch $ctx.Item('phase')
		Case $HR_PHASE_SELF_SETUP
			Return _HR_PhaseSelfSetup($ctx)

		Case $HR_PHASE_APPLY_PARTY
			Return _HR_PhaseApplyParty($ctx)

		Case $HR_PHASE_MAINTENANCE
			Return _HR_PhaseMaintenance($ctx)
	EndSwitch

	Return False
EndFunc

;~ Reset the context to restart the full HR application cycle.
;~ Useful when entering a new zone or after a wipe.
Func HeroicRefrain_Reset($ctx)
	$ctx.Item('phase') = $HR_PHASE_SELF_SETUP
	$ctx.Item('pendingTOF') = False
	$ctx.Item('partyIndex') = 1
	$ctx.Item('lastTOFTime') = 0
	$ctx.Item('lastHRCastTime') = 0
	$ctx.Item('initialized') = False
	$ctx.Item('selfCastCount') = 0
	Debug('HR Utility: Context reset')
EndFunc

; --- Internal helpers ---

;~ Try to cast pending "They're on Fire!" follow-up.
;~ If TOF is still recharging, waits up to 12s then gives up.
Func _HR_TryCastPendingTOF($ctx)
	If IsRecharged($BUILD_PW_THEYRE_ON_FIRE) Then
		UseSkillEx($BUILD_PW_THEYRE_ON_FIRE)
		$ctx.Item('lastTOFTime') = TimerInit()
		$ctx.Item('pendingTOF') = False
		Debug('HR Utility: TOF follow-up cast')
		Return True
	EndIf

	; If HR was cast more than 12s ago and TOF still not ready, give up waiting
	If $ctx.Item('lastHRCastTime') > 0 And TimerDiff($ctx.Item('lastHRCastTime')) > 12000 Then
		$ctx.Item('pendingTOF') = False
		Debug('HR Utility: TOF follow-up skipped (still recharging)')
	EndIf

	Return False
EndFunc

;~ Cast HR on self twice, then advance to APPLY_PARTY.
;~ Tracked by counter, not effect checking. Resets on death/zone.
Func _HR_PhaseSelfSetup($ctx)
	If $ctx.Item('selfCastCount') >= 2 Then
		$ctx.Item('phase') = $HR_PHASE_APPLY_PARTY
		$ctx.Item('partyIndex') = 1
		Debug('HR Utility: Self setup complete (' & $ctx.Item('selfCastCount') & ' casts)')
		Return False
	EndIf

	If Not IsRecharged($BUILD_PW_HEROIC_REFRAIN) Then Return False
	If GetEnergy() < 5 Then Return False

	Local $me = GetMyAgent()
	If UseSkillEx($BUILD_PW_HEROIC_REFRAIN, $me) Then
		$ctx.Item('selfCastCount') = $ctx.Item('selfCastCount') + 1
		$ctx.Item('pendingTOF') = True
		$ctx.Item('lastHRCastTime') = TimerInit()
		Debug('HR Utility: Self cast ' & $ctx.Item('selfCastCount') & '/2')
		Return True
	EndIf

	Return False
EndFunc

;~ Find next party member without HR and cast it on them.
;~ Skips out-of-range heroes and casts on nearby ones first.
Func _HR_PhaseApplyParty($ctx)
	If Not IsRecharged($BUILD_PW_HEROIC_REFRAIN) Then Return False

	Local $heroCount = GetHeroCount()
	Local $idx = $ctx.Item('partyIndex')
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
			$ctx.Item('pendingTOF') = True
			$ctx.Item('lastHRCastTime') = TimerInit()
			$ctx.Item('partyIndex') = $idx + 1
			Debug('HR Utility: Cast HR on party member ' & $idx)
			Return True
		EndIf

		; Cast failed (energy, etc.) - try again next tick
		$ctx.Item('partyIndex') = $idx
		Return False
	WEnd

	; Some heroes were out of range - loop back to try them again
	If $skippedOutOfRange Then
		$ctx.Item('partyIndex') = 1
		Return False
	EndIf

	; All party members processed - enter maintenance
	$ctx.Item('phase') = $HR_PHASE_MAINTENANCE
	$ctx.Item('lastTOFTime') = TimerInit()
	Debug('HR Utility: All party buffed, entering maintenance')
	Return False
EndFunc

;~ Maintenance phase: cast TOF on cooldown to keep HR alive, reapply HR on rezzed heroes.
Func _HR_PhaseMaintenance($ctx)
	; Recovery: if player lost HR (death/respawn, buff expiry), restart full cycle
	If GetEffect($ID_HEROIC_REFRAIN, 0) == Null Then
		$ctx.Item('phase') = $HR_PHASE_SELF_SETUP
		$ctx.Item('selfCastCount') = 0
		$ctx.Item('partyIndex') = 1
		Debug('HR Utility: Player lost HR, restarting self setup')
		Return _HR_PhaseSelfSetup($ctx)
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
					$ctx.Item('pendingTOF') = True
					$ctx.Item('lastHRCastTime') = TimerInit()
					Debug('HR Utility: Reapplied HR on party member ' & $i)
					Return True
				EndIf
			EndIf
			Return False
		EndIf
	Next

	; Steady state: cast TOF on cooldown to keep HR alive
	If IsRecharged($BUILD_PW_THEYRE_ON_FIRE) Then
		If UseSkillEx($BUILD_PW_THEYRE_ON_FIRE) Then
			$ctx.Item('lastTOFTime') = TimerInit()
			Debug('HR Utility: Maintenance TOF')
			Return True
		EndIf
	EndIf

	Return False
EndFunc


; ============================================================================
; Adrenaline Build Fight Function (non-blocking, tick-based)
;
; Skill priority (highest to lowest):
;   1. Heroic Refrain / They're on Fire! (via HeroicRefrain_Tick)
;   2. Aggressive Refrain (25e, once if not already buffed)
;   3. Auto-attack (always ensure attacking target)
;   4. "Stand Your Ground!" (only if party not already buffed)
;   5. "There's Nothing to Fear!" (15e)
;   6. "Save Yourselves!" (adrenaline >= 200)
;   7. "To the Limit!" (only if foes in earshot, adrenaline gain)
;   8. "For Great Justice!" (5e, lowest priority)
; ============================================================================

;~ Non-blocking fight tick for the HR Adrenaline build.
;~ Call every fight loop iteration. Performs at most one skill cast per call.
;~
;~ $hrCtx  - context dictionary from HeroicRefrain_Init()
;~ $target - current enemy agent (or Null for untargeted shouts)
Func FightAdrenaline_Tick($hrCtx, $target = Null)
	; Guards
	If Not IsPlayerAlive() Then Return
	If IsCasting(GetMyAgent()) Then Return

	; Priority 1: HR maintenance (includes TOF follow-up)
	If HeroicRefrain_Tick($hrCtx) Then Return

	; Priority 2: Aggressive Refrain — only if not already active, costs 25e, only in combat
	If $target <> Null And GetEffect($ID_AGGRESSIVE_REFRAIN, 0) == Null Then
		If GetEnergy() >= 25 And IsRecharged($BUILD_PW_AGGRESSIVE_REFRAIN) Then
			UseSkillEx($BUILD_PW_AGGRESSIVE_REFRAIN)
			Return
		EndIf
	EndIf

	; Priority 3: Ensure we are attacking the target
	If $target <> Null Then Attack($target)

	; Priority 4: "Stand Your Ground!" — only if party not already buffed
	If IsRecharged($BUILD_PW_STAND_YOUR_GROUND) Then
		If GetEffect($ID_STAND_YOUR_GROUND, 0) == Null Then
			UseSkillEx($BUILD_PW_STAND_YOUR_GROUND)
			Return
		EndIf
	EndIf

	; Priority 5: "There's Nothing to Fear!" (15e)
	If IsRecharged($BUILD_PW_THERES_NOTHING_TO_FEAR) And GetEnergy() >= 15 Then
		UseSkillEx($BUILD_PW_THERES_NOTHING_TO_FEAR)
		Return
	EndIf

	; Priority 6: "Save Yourselves!" (adrenaline-based, 200 required)
	If GetSkillbarSkillAdrenaline($BUILD_PW_SAVE_YOURSELVES) >= 200 Then
		UseSkillEx($BUILD_PW_SAVE_YOURSELVES)
		Return
	EndIf

	; Priority 7: "To the Limit!" (only if foes nearby for adrenaline gain)
	If IsRecharged($BUILD_PW_TO_THE_LIMIT) And CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 Then
		UseSkillEx($BUILD_PW_TO_THE_LIMIT)
		Return
	EndIf

	; Priority 8: "For Great Justice!" (5e, lowest priority)
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
; the HR Adrenaline build. Call SetupHRAdrenalineBuild() once during setup,
; then pass the returned option dicts to MoveAggroAndKillInRange.
; ============================================================================

;~ Set up the HR Adrenaline build: load template, init context, set active build globals.
;~ Paragon does not flag heroes, so both active options use the same non-flag dict.
Func SetupHRAdrenalineBuild()
	LoadSkillTemplate($BUILD_PW_HR_ADRENALINE)
	$hr_adrenaline_ctx = HeroicRefrain_Init()

	Local $fightOptions = CloneDictMap($default_move_aggro_kill_options)
	$fightOptions.Item('combatFunction') = HRAdrenalineCombat
	$fightOptions.Item('doWhileMoving') = HRAdrenalineDoWhileMoving

	$active_fight_options = $fightOptions
	$active_flag_fight_options = $fightOptions
	$active_do_while_moving = HRAdrenalineDoWhileMoving
EndFunc

;~ Combat callback for KillFoesInArea: loops Attack + FightAdrenaline_Tick until target is dead.
Func HRAdrenalineCombat($target, $options)
	GetAlmostInRangeOfAgent($target)
	Attack($target)
	Sleep(100)
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		Attack($target)
		FightAdrenaline_Tick($hr_adrenaline_ctx, $target)
		Sleep(100)
		$target = GetCurrentTarget()
		If IsPlayerDead() Then ExitLoop
	WEnd
EndFunc

;~ DoWhileMoving callback: ticks HR maintenance during movement between waypoints.
Func HRAdrenalineDoWhileMoving()
	HeroicRefrain_Tick($hr_adrenaline_ctx)
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
