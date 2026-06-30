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

#include-once
#include 'GWA2.au3'
#include 'GWA2_ID.au3'
#include 'GWA2_ID_Maps.au3'
#include 'GWA2_ID_Skills.au3'
#include 'Utils.au3'
#include 'Utils-Agents.au3'

Global Const $BUILD_PW_HR_REFRAINS = 'OQCjUamLKTn19Y1YAh0b4ioYsYA'
Global Const $BUILD_PW_HR_ARIAS = 'OQCkUWm4Ziy0ZdPWNGQI9GuoHGHG'
Global Const $BUILD_PW_HR_ADRENALINE = 'OQGkURll5iy0ZdPWNGQYMIPxVh7G' ; +3+1 Leadership, +1 Spear, +1 Command, +Clarity

; Phase constants
Global Const $HR_PHASE_NOT_INITIALIZED = 0
Global Const $HR_PHASE_SELF_SETUP = 1
Global Const $HR_PHASE_APPLY_PARTY = 2

; Adlib interval constant
Global Const $HR_INTERVAL = 12000

; Default build
Global $BUILD_PW_HEROIC_REFRAIN = -1
Global $BUILD_PW_THEYRE_ON_FIRE = -1
Global $BUILD_PW_STAND_YOUR_GROUND = -1
Global $BUILD_PW_THERES_NOTHING_TO_FEAR = -1

; Options
;Global $BUILD_PW_LEADERS_COMFORT = -1						; not supported
Global $BUILD_PW_CANT_TOUCH_THIS = -1
Global $BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM = -1

; Aria build
Global $BUILD_PW_ARIA_OF_RESTORATION = -1
Global $BUILD_PW_BALLAD_OF_RESTORATION = -1
Global $BUILD_PW_ARIA_OF_ZEAL = -1

; Refrain build
;Global $BUILD_PW_MENDING_REFRAIN = -1						; not supported
;Global $BUILD_PW_HASTY_REFRAIN = -1						; not supported
Global $BUILD_PW_BURNING_REFRAIN = -1
Global $BUILD_PW_BLADETURN_REFRAIN = -1

; Adrenaline build
Global $BUILD_PW_SAVE_YOURSELVES = -1
Global $BUILD_PW_TO_THE_LIMIT = -1
Global $BUILD_PW_FOR_GREAT_JUSTICE = -1
Global $BUILD_PW_NATURAL_TEMPER = -1
Global $BUILD_PW_AGGRESSIVE_REFRAIN = -1


; ============================================================================
; HR build setup & callbacks
;
; Reusable setup and callback functions for any farm/mission script using HR
; Call SetupHRBuild() once during setup - build will be detected and used.
; HR maintenance runs automatically via AdlibRegister.
; Combat function is wired through the default move-aggro-kill option maps.
; ============================================================================

;~ Set up HR build: learn the build, register HR maintenance, set combat function.
;~ Overwrites the default combat function on both option maps so all MoveAggro* calls use it.
Func SetupHRBuild()
	Local $skillbar = GetSkillbar(0)
	For $i = 1 To 8
		Local $skillID = DllStructGetData($skillbar, 'SkillID' & $i)
		Switch $skillID
			; HR build core skills
			Case $ID_HEROIC_REFRAIN
				$BUILD_PW_HEROIC_REFRAIN = $i
			Case $ID_THEYRE_ON_FIRE
				$BUILD_PW_THEYRE_ON_FIRE = $i
			Case $ID_STAND_YOUR_GROUND
				$BUILD_PW_STAND_YOUR_GROUND = $i
			Case $ID_THERES_NOTHING_TO_FEAR
				$BUILD_PW_THERES_NOTHING_TO_FEAR = $i
			; HR build options
			Case $ID_CANT_TOUCH_THIS
				$BUILD_PW_CANT_TOUCH_THIS = $i
			Case $ID_EBON_BATTLE_STANDARD_OF_WISDOM
				$BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM = $i
			; Aria build
			Case $ID_ARIA_OF_RESTORATION
				$BUILD_PW_ARIA_OF_RESTORATION = $i
			Case $ID_BALLAD_OF_RESTORATION
				$BUILD_PW_BALLAD_OF_RESTORATION = $i
			Case $ID_ARIA_OF_ZEAL
				$BUILD_PW_ARIA_OF_ZEAL = $i
			; Refrain build
			Case $ID_BURNING_REFRAIN
				$BUILD_PW_BURNING_REFRAIN = $i
			Case $ID_BLADETURN_REFRAIN
				$BUILD_PW_BLADETURN_REFRAIN = $i
			; Adrenaline build
			Case $ID_SAVE_YOURSELVES_LUXON
				$BUILD_PW_SAVE_YOURSELVES = $i
			Case $ID_SAVE_YOURSELVES_KURZICK
				$BUILD_PW_SAVE_YOURSELVES = $i
			Case $ID_TO_THE_LIMIT
				$BUILD_PW_TO_THE_LIMIT = $i
			Case $ID_FOR_GREAT_JUSTICE
				$BUILD_PW_FOR_GREAT_JUSTICE = $i
			Case $ID_NATURAL_TEMPER
				$BUILD_PW_NATURAL_TEMPER = $i
			Case $ID_AGGRESSIVE_REFRAIN
				$BUILD_PW_AGGRESSIVE_REFRAIN = $i
			Case Else
				Error('The skill ' & $i & ' is not recognised in a HR build.')
		EndSwitch
	Next

	OpenPeersSharedMemoryBlocks()
	; Faster setup by calling it directly (Adlib will wait HR_INTERVAL before first call)
	TickHeroicRefrain()
	AdlibRegister('TickHeroicRefrain', $HR_INTERVAL)

	$default_move_aggro_kill_options['combatFunction']	= HRCombat
	$flag_move_aggro_kill_options['combatFunction']		= HRCombat
EndFunc


; ============================================================================
; Heroic Refrain AdlibRegister Utility
;
; State-machine-based utility for Heroic Refrain maintenance.
; Runs via AdlibRegister, keeping HR active on the entire party regardless
; of the current control flow (movement, combat, sleep, idle, etc.).
;
; Phases:
;	NOT_INITIALIZED	- Waiting for first tick in explorable
;	SELF_SETUP		- Cast HR on self twice to hit the +4 breakpoint
;	APPLY_PARTY		- Apply/reapply HR on heroes, maintain via TOF
;
; Self-setup uses a binary check: no HR -> cast -> stay, has HR -> cast -> leave.
; This guarantees the double-cast needed for the Leadership breakpoint (+3 -> +4).
;
; State resets automatically on death or zone change.
; ============================================================================

;~ AdlibRegister target. Performs at most one phase action per call.
;~ TOF is cast unconditionally every tick to keep existing HR alive.
Func TickHeroicRefrain()
	Local Static $phase = $HR_PHASE_NOT_INITIALIZED
	Local Static $lastMapId = 0

	; Not in explorable or dead: reset to uninitialized
	If GetMapType() <> $ID_EXPLORABLE Or Not IsPlayerAlive() Then
		$phase = $HR_PHASE_NOT_INITIALIZED
		$lastMapId = 0
		Return
	EndIf

	; Detect map/floor change: restart self-setup
	Local $currentMap = GetMapID()
	If $lastMapId <> 0 And $lastMapId <> $currentMap Then $phase = $HR_PHASE_SELF_SETUP
	$lastMapId = $currentMap

	; First tick in explorable: start self-setup
	If $phase == $HR_PHASE_NOT_INITIALIZED Then $phase = $HR_PHASE_SELF_SETUP

	; Cast TOF unconditionally every tick to keep existing HR alive.
	; TOF is off the global cooldown so it can fire during other casts.
	; Leadership returns ~10e from party members affected by shouts.
	UseSkillEx($BUILD_PW_THEYRE_ON_FIRE)

	; If player lost HR at any phase, restart self-setup
	If $phase <> $HR_PHASE_SELF_SETUP And GetEffect($ID_HEROIC_REFRAIN) == Null Then
		$phase = $HR_PHASE_SELF_SETUP
	EndIf

	Switch $phase
		Case $HR_PHASE_SELF_SETUP
			$phase = HRPhaseSelfSetup()

		Case $HR_PHASE_APPLY_PARTY
			$phase = HRPhaseApplyParty()
	EndSwitch
EndFunc


;~ Cast HR on self until bootstrap is complete, then advance to APPLY_PARTY.
;~ No HR -> cast -> stay. Has HR -> cast again (boosted) -> leave.
;~ Guarantees two casts for the Leadership +3 -> +4 breakpoint.
Func HRPhaseSelfSetup()
	If GetEnergy() < 5 Then Return $HR_PHASE_SELF_SETUP

	Local $alreadyHadHR = GetEffect($ID_HEROIC_REFRAIN) <> Null
	UseSkillEx($BUILD_PW_HEROIC_REFRAIN, GetMyAgent())
	Return $alreadyHadHR ? $HR_PHASE_APPLY_PARTY : $HR_PHASE_SELF_SETUP
EndFunc


;~ Iterate player and his heroes and apply HR to anyone missing it.
;~ Full scan every tick to avoid stale state from deaths, movement, or buff expiry.
Func HRPhaseApplyParty()
	Local Static $next = 0
	Local $party = GetParty()
	Local $partySize = UBound($party)

	Local $refrain = Null
	Local $refrainTarget = Null
	For $offset = 0 To $partySize - 1
		Local $index = Mod($next + $offset, $partySize)
		Local $agent = $party[$index]
		Local $agentID = DllStructGetData($agent, 'ID')
		If $agentID == 0 Or GetIsDead($agent) Then ContinueLoop
		If GetDistance(GetMyAgent(), $agent) > $RANGE_SPELLCAST Then ContinueLoop
		Local $effects = Null
		If Not IsMine($agent) Then
			; If an agent is not ours (another player or his heroes) we try the shared memories
			For $key In MapKeys($sharedMemoryHandlesMap)
				Local $map = ReadHeroesEffectsFromSharedMemory($key)
				$effects = $map[$agentID]
				If $effects <> Null Then ExitLoop
			Next
			If $effects == Null Then ContinueLoop
		EndIf

		Local $refrainsByte = ScanAllyForRefrains($agentID, $effects)
		If BitAnd($refrainsByte, 0x1) == 0x0 Then
			UseSkillEx($BUILD_PW_HEROIC_REFRAIN, $agent)
			$next = Mod($index + 1, $partySize)
			Return $index == 0 ? $HR_PHASE_SELF_SETUP : $HR_PHASE_APPLY_PARTY
		EndIf
		If $refrainTarget == Null And BitAnd($refrainsByte, 0x6) <> 0x6 Then
			$refrainTarget = $agent
			$refrain = BitAnd($refrainsByte, 0x2) <> 0x2 ? $BUILD_PW_BLADETURN_REFRAIN : $BUILD_PW_BURNING_REFRAIN
		EndIf
	Next
	If $refrainTarget <> Null Then UseSkillEx($refrain, $refrainTarget)
	Return $HR_PHASE_APPLY_PARTY
EndFunc


;~ Scan a character and return a byte encoding which refrains are missing for that character
Func ScanAllyForRefrains($agentID, $effectsArray = Null)
	Local $refrainsByte = 0x0
	If $BUILD_PW_BLADETURN_REFRAIN < 0 Then $refrainsByte = BitOR($refrainsByte, 0x2)
	If $BUILD_PW_BURNING_REFRAIN < 0 Then $refrainsByte = BitOR($refrainsByte, 0x4)

	If $effectsArray == Null Then $effectsArray = GetEffect(0, $agentID)
	For $effect In $effectsArray
		Local $effectID = DllStructGetData($effect, 'SkillID')
		If $effectID == $ID_HEROIC_REFRAIN Then
			$refrainsByte = BitOR($refrainsByte, 0x1)
		ElseIf $effectID == $ID_BLADETURN_REFRAIN Then
			$refrainsByte = BitOR($refrainsByte, 0x2)
		ElseIf $effectID == $ID_BURNING_REFRAIN Then
			$refrainsByte = BitOR($refrainsByte, 0x4)
		EndIf
		If BitAnd($refrainsByte, 0x7) == 0x7 Then ExitLoop
	Next
	Return $refrainsByte
EndFunc


;~ Combat callback for KillFoesInArea: loops Attack + CastCombatShouts until target is dead.
Func HRCombat($target, $options)
	GetAlmostInRangeOfAgent($target)
	Attack($target)
	Sleep(250)
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		Attack($target)
		CastCombatShouts($target)
		Sleep(250)
		$target = GetCurrentTarget()
		If IsPlayerDead() Then ExitLoop
	WEnd
EndFunc


;~ Cast one combat shout per call based on priority.
;~ $target - current enemy agent (or Null for untargeted shouts)
Func CastCombatShouts($target = Null)
	Local $energy = GetEnergy()
	; Priority 1: Ensure we are attacking the target
	If $target <> Null Then Attack($target)

	; Priority 2: Aggressive Refrain — only if not already active, only in combat
	If $BUILD_PW_AGGRESSIVE_REFRAIN > 0 And GetEffect($ID_AGGRESSIVE_REFRAIN) == Null And $energy >= 15 And IsRecharged($BUILD_PW_AGGRESSIVE_REFRAIN) Then Return UseSkillEx($BUILD_PW_AGGRESSIVE_REFRAIN)
	
	; Priority 3: Stand Your Ground!
	If $BUILD_PW_STAND_YOUR_GROUND > 0 And IsRecharged($BUILD_PW_STAND_YOUR_GROUND) And $energy >= 10 Then Return UseSkillEx($BUILD_PW_STAND_YOUR_GROUND)

	; Priority 4: Ebon Battle Standard of Wisdom
	If $BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM > 0 And IsRecharged($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM) And $energy >= 10 Then Return UseSkillEx($BUILD_PW_EBON_BATTLE_STANDARD_OF_WISDOM)

	; Priority 5: There's Nothing to Fear!
	If $BUILD_PW_THERES_NOTHING_TO_FEAR > 0 And IsRecharged($BUILD_PW_THERES_NOTHING_TO_FEAR) And $energy >= 15 Then Return UseSkillEx($BUILD_PW_THERES_NOTHING_TO_FEAR)

	; Priority 6: Save Yourselves! (adrenaline-based, 200 required)
	If $BUILD_PW_SAVE_YOURSELVES > 0 And GetSkillbarSkillAdrenaline($BUILD_PW_SAVE_YOURSELVES) >= 200 Then Return UseSkillEx($BUILD_PW_SAVE_YOURSELVES)

	; Priority 7: Aria of Restoration
	If $BUILD_PW_ARIA_OF_RESTORATION > 0 And IsRecharged($BUILD_PW_ARIA_OF_RESTORATION) And $energy >= 10 Then Return UseSkillEx($BUILD_PW_ARIA_OF_RESTORATION)

	; Priority 8: Ballad of Restoration
	If $BUILD_PW_BALLAD_OF_RESTORATION > 0 And IsRecharged($BUILD_PW_BALLAD_OF_RESTORATION) And $energy >= 10 Then Return UseSkillEx($BUILD_PW_BALLAD_OF_RESTORATION)

	; Priority 9: Aria of Zeal
	If $BUILD_PW_ARIA_OF_ZEAL > 0 And IsRecharged($BUILD_PW_ARIA_OF_ZEAL) And $energy >= 5 Then Return UseSkillEx($BUILD_PW_ARIA_OF_ZEAL)

	; Priority 10: Cant touch this
	If $BUILD_PW_CANT_TOUCH_THIS > 0 And IsRecharged($BUILD_PW_CANT_TOUCH_THIS) And $energy >= 5 Then Return UseSkillEx($BUILD_PW_CANT_TOUCH_THIS)

	; Priority 11: Natural Temper
	If $BUILD_PW_NATURAL_TEMPER > 0 And GetSkillbarSkillAdrenaline($BUILD_PW_NATURAL_TEMPER) >= 75 Then Return UseSkillEx($BUILD_PW_NATURAL_TEMPER)

	; Priority 12: For Great Justice!
	If $BUILD_PW_FOR_GREAT_JUSTICE > 0 And IsRecharged($BUILD_PW_FOR_GREAT_JUSTICE) And $energy >= 5 Then Return UseSkillEx($BUILD_PW_FOR_GREAT_JUSTICE)

	; Priority 13: To the Limit! (no need to check for foes presence - if there were no foes we would not be in this function)
	If $BUILD_PW_TO_THE_LIMIT > 0 And IsRecharged($BUILD_PW_TO_THE_LIMIT) And $energy >= 5 Then Return UseSkillEx($BUILD_PW_TO_THE_LIMIT)
EndFunc