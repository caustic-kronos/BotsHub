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
#include 'GWA2_ID_Skills.au3'
#include 'Utils.au3'
#include 'Utils-Agents.au3'

; ============================================================================
; Assassin's Promise build support - any primary profession with /A secondary
;
; https://gwpvx.fandom.com/wiki/Build:Me/A_Assassin%27s_Promise
; https://gwpvx.fandom.com/wiki/Build:N/A_Assassin%27s_Promise_Death_Magic
; https://gwpvx.fandom.com/wiki/Build:E/A_Assassin%27s_Promise
;
; Call SetupAPBuild() once during setup - SetupPlayerBuildOverrides does it automatically
; when Assassin's Promise is found on the skillbar. The combat routine APCombat then
; replaces the "cast from skill 1 to 8" routine on the move-aggro-kill option maps.
;
; Casting rules, one skill per loop iteration, highest priority first:
;	1. Assassin's Promise once the target is at or below $AP_CAST_HEALTH_THRESHOLD
;	   Never while Auspicious Incantation or Arcane Echo wait for a spell that Ebon Vanguard Assassin Support can provide
;	2. "Finish Him!" once the target is below 50% - it has no effect above that
;	3. "You Move Like a Dwarf!" after "Finish Him!" was used on the target, or when "Finish Him!" cannot be used,
;	   or when its damage would bring the target below 50% while keeping enough energy for "Finish Him!"
;	4. Mesmer: Auspicious Incantation, then Arcane Echo, then Ebon Vanguard Assassin Support and its echoed copy
;	   Auspicious Incantation is only cast when Arcane Echo or Ebon Vanguard Assassin Support will consume it
;	   Arcane Echo is only cast when Ebon Vanguard Assassin Support can follow immediately
;	5. Ebon Vanguard Assassin Support
;	6. Any other skill on the bar, from left to right, keeping an energy reserve for one shout
;
; Any non-spell skill ends Arcane Echo, so shouts are never used while Arcane Echo waits for
; a spell or holds an unused copy of Ebon Vanguard Assassin Support.
; ============================================================================

; Tunables
Global Const $AP_CAST_HEALTH_THRESHOLD			= 0.6	; Assassin's Promise is cast at or below this target health fraction
Global Const $AP_FINISH_HIM_HEALTH_THRESHOLD	= 0.5	; "Finish Him!" has no effect at or above this target health fraction
Global Const $AP_FILLER_ENERGY_RESERVE			= 10	; energy kept aside when casting non-core skills - enough for one shout
Global Const $AP_SHOUT_DAMAGE_CONFIDENCE		= 0.9	; safety factor on expected shout damage when predicting a drop below 50%
Global Const $AP_ENERGY_HEADROOM_FOR_REFUND		= 10	; Auspicious Incantation is not worth casting when this close to max energy
Global Const $AP_IDLE_SLEEP						= 250	; sleep when no skill can be used

; Damage of "Finish Him!" and "You Move Like a Dwarf!" per Norn rank, and title points needed to reach each rank
Global Const $AP_NORN_SHOUT_DAMAGE[]			= [44, 51, 58, 66, 73, 80, 80, 80, 80, 80, 80]
Global Const $AP_NORN_RANK_POINTS[]				= [1000, 2000, 4000, 8000, 16000, 25000, 40000, 65000, 100000, 160000]

; Skill slots detected by SetupAPBuild - -1 when the skill is not on the bar
Global $BUILD_XA_ASSASSINS_PROMISE				= -1
Global $BUILD_XA_FINISH_HIM						= -1
Global $BUILD_XA_YOU_MOVE_LIKE_A_DWARF			= -1
Global $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT	= -1
Global $BUILD_XA_ARCANE_ECHO					= -1
Global $BUILD_XA_AUSPICIOUS_INCANTATION			= -1


;~ Set up the Assassin's Promise build: learn the skill slots and set the combat function.
;~ Overwrites the default combat function on the option maps so all MoveAggro* calls use it.
;~ Returns True if the build was recognised, False otherwise (default combat function is kept).
Func SetupAPBuild()
	$BUILD_XA_ASSASSINS_PROMISE				= -1
	$BUILD_XA_FINISH_HIM					= -1
	$BUILD_XA_YOU_MOVE_LIKE_A_DWARF			= -1
	$BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT	= -1
	$BUILD_XA_ARCANE_ECHO					= -1
	$BUILD_XA_AUSPICIOUS_INCANTATION		= -1

	Local $skillbar = GetSkillbar(0)
	Local $fillerSlots = ''
	For $i = 1 To 8
		Local $skillID = DllStructGetData($skillbar, 'SkillID' & $i)
		Switch $skillID
			Case $ID_ASSASSINS_PROMISE
				$BUILD_XA_ASSASSINS_PROMISE = $i
			Case $ID_FINISH_HIM
				$BUILD_XA_FINISH_HIM = $i
			Case $ID_YOU_MOVE_LIKE_A_DWARF
				$BUILD_XA_YOU_MOVE_LIKE_A_DWARF = $i
			Case $ID_EBON_VANGUARD_ASSASSIN_SUPPORT
				$BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT = $i
			Case $ID_ARCANE_ECHO
				$BUILD_XA_ARCANE_ECHO = $i
			Case $ID_AUSPICIOUS_INCANTATION
				$BUILD_XA_AUSPICIOUS_INCANTATION = $i
			Case 0
				; empty slot
			Case Else
				$fillerSlots &= ($fillerSlots == '' ? '' : ', ') & $i
		EndSwitch
	Next

	If $BUILD_XA_ASSASSINS_PROMISE < 0 Then
		Warn('Assassin''s Promise is not on the skillbar - keeping the default combat routine')
		Return False
	EndIf

	Info('Assassin''s Promise build detected - using the build-aware combat routine')
	Debug('AP build slots - Promise: ' & $BUILD_XA_ASSASSINS_PROMISE & ', Finish Him: ' & $BUILD_XA_FINISH_HIM _
		& ', Move Like a Dwarf: ' & $BUILD_XA_YOU_MOVE_LIKE_A_DWARF & ', Assassin Support: ' & $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT _
		& ', Arcane Echo: ' & $BUILD_XA_ARCANE_ECHO & ', Auspicious Incantation: ' & $BUILD_XA_AUSPICIOUS_INCANTATION _
		& ', other skills played from left to right: ' & ($fillerSlots == '' ? 'none' : $fillerSlots))
	If $BUILD_XA_FINISH_HIM < 0 Then Warn('"Finish Him!" is not on the skillbar - Assassin''s Promise build will be weaker')
	If $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT < 0 Then Warn('Ebon Vanguard Assassin Support is not on the skillbar - Assassin''s Promise build will be weaker')
	If $BUILD_XA_ARCANE_ECHO > 0 And $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT < 0 Then Warn('Arcane Echo has nothing to copy without Ebon Vanguard Assassin Support - it will not be used')

	$default_move_aggro_kill_options['killMethod']	= APCombat
	$flag_move_aggro_kill_options['killMethod']		= APCombat
	$optionsFollower['killMethod']					= APCombat
	Return True
EndFunc


;~ Combat callback for KillFoesInArea: attacks and uses one skill per iteration according to the Assassin's Promise rules until target is dead.
Func APCombat($target, $options)
	Local $abortCondition		= $options['abortCondition'] <> Null ?		$options['abortCondition'] : Null

	; get as close as possible to target foe to have a surprise effect when attacking
	GetAlmostInRangeOfAgent($target)
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		; Always ensure auto-attack is active before using skills - wand and staff hits add up
		Attack($target)
		PingSleep(100)
		If Not CastAssassinsPromiseSkill($target) Then RandomSleep($AP_IDLE_SLEEP)
		$target = GetCurrentTarget()
		If IsPlayerDead() Then ExitLoop
		If $abortCondition <> Null And $abortCondition() Then Return
	WEnd
EndFunc


;~ Use at most one skill on the target according to the Assassin's Promise rules.
;~ Returns True if a skill was used, False if nothing could be used this iteration.
Func CastAssassinsPromiseSkill($target)
	Local Static $lastTargetID = 0
	Local Static $finishHimUsed = False

	; Per target state - "Finish Him!" is tracked per target so "You Move Like a Dwarf!" follows it
	Local $targetID = DllStructGetData($target, 'ID')
	If $targetID <> $lastTargetID Then
		$lastTargetID = $targetID
		$finishHimUsed = False
	EndIf

	; One snapshot of the skillbar and energy per iteration to limit memory reads
	Local $skillbar = GetSkillbar()
	Local $skillTimer = GetSkillTimer()
	Local $energy = GetEnergy()
	Local $targetHealth = DllStructGetData($target, 'HealthPercent')

	; Arcane Echo state - its slot shows the copied skill ID while a copy exists
	Local $echoSlotID = 0, $echoWaitingForSpell = False, $echoCopyReady = False
	If $BUILD_XA_ARCANE_ECHO > 0 Then
		$echoSlotID = DllStructGetData($skillbar, 'SkillID' & $BUILD_XA_ARCANE_ECHO)
		If $echoSlotID == $ID_ARCANE_ECHO Then $echoWaitingForSpell = GetEffect($ID_ARCANE_ECHO) <> Null
		If $echoSlotID == $ID_EBON_VANGUARD_ASSASSIN_SUPPORT Then $echoCopyReady = IsSkillRecharged($skillbar, $BUILD_XA_ARCANE_ECHO, $skillTimer)
	EndIf
	; Any non-spell skill ends Arcane Echo, so shouts wait until the copy has been created and spent
	Local $shoutsAllowed = Not $echoWaitingForSpell And Not $echoCopyReady
	Local $auspiciousActive = False
	If $BUILD_XA_AUSPICIOUS_INCANTATION > 0 Then $auspiciousActive = GetEffect($ID_AUSPICIOUS_INCANTATION) <> Null

	Local $canAssassinSupport = IsAPSlotUsable($skillbar, $skillTimer, $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT, $energy)
	Local $canArcaneEcho = CanCastArcaneEcho($skillbar, $skillTimer, $energy, $echoSlotID, $echoWaitingForSpell, $auspiciousActive)

	; 1. Assassin's Promise once the target is getting close to 50% - the kill then recharges everything and refunds energy
	If $targetHealth <= $AP_CAST_HEALTH_THRESHOLD And IsAPSlotUsable($skillbar, $skillTimer, $BUILD_XA_ASSASSINS_PROMISE, $energy) Then
		; Auspicious Incantation must never be spent on Assassin's Promise, and Arcane Echo should copy Ebon Vanguard Assassin Support
		; Both are only respected when the spell they wait for can actually be cast - otherwise the kill matters more
		Local $spellPending = ($auspiciousActive And ($canAssassinSupport Or $canArcaneEcho)) Or ($echoWaitingForSpell And $canAssassinSupport)
		If Not $spellPending Then Return UseAPSkill($BUILD_XA_ASSASSINS_PROMISE, $target, 'Assassin''s Promise')
	EndIf

	; 2. "Finish Him!" only below 50% - deep wound, cracked armor and damage
	If $shoutsAllowed And $targetHealth < $AP_FINISH_HIM_HEALTH_THRESHOLD And IsAPSlotUsable($skillbar, $skillTimer, $BUILD_XA_FINISH_HIM, $energy) Then
		If UseAPSkill($BUILD_XA_FINISH_HIM, $target, '"Finish Him!"') Then
			$finishHimUsed = True
			Return True
		EndIf
	EndIf

	; 3. "You Move Like a Dwarf!" after "Finish Him!", or when it would bring the target below 50% with energy left for "Finish Him!"
	If $shoutsAllowed And IsAPSlotUsable($skillbar, $skillTimer, $BUILD_XA_YOU_MOVE_LIKE_A_DWARF, $energy) Then
		Local $finishHimOnBar = $BUILD_XA_FINISH_HIM > 0
		Local $finishHimReady = False
		If $finishHimOnBar Then $finishHimReady = IsSkillRecharged($skillbar, $BUILD_XA_FINISH_HIM, $skillTimer)
		If $targetHealth < $AP_FINISH_HIM_HEALTH_THRESHOLD Then
			; "Finish Him!" had priority above - if it was not used here it is either done, recharging or missing
			If $finishHimUsed Or Not $finishHimReady Then Return UseAPSkill($BUILD_XA_YOU_MOVE_LIKE_A_DWARF, $target, '"You Move Like a Dwarf!"')
		Else
			Local $maxHealth = GetAgentMaxHealthEstimate($target)
			Local $expectedDamage = GetNornShoutDamage() * $AP_SHOUT_DAMAGE_CONFIDENCE
			Local $wouldDropBelowHalf = ($targetHealth * $maxHealth - $expectedDamage) < ($AP_FINISH_HIM_HEALTH_THRESHOLD * $maxHealth)
			Local $finishHimCost = $finishHimOnBar ? GetSkillEnergyCost($ID_FINISH_HIM) : 0
			Local $energyLeftForFinishHim = $energy >= GetSkillEnergyCost($ID_YOU_MOVE_LIKE_A_DWARF) + $finishHimCost
			If $wouldDropBelowHalf And (Not $finishHimOnBar Or $finishHimReady) And $energyLeftForFinishHim Then Return UseAPSkill($BUILD_XA_YOU_MOVE_LIKE_A_DWARF, $target, '"You Move Like a Dwarf!"')
		EndIf
	EndIf

	; 4. Mesmer energy and copy management - only worth starting while the target is still healthy, the spike takes a few seconds
	If $targetHealth > $AP_CAST_HEALTH_THRESHOLD And Not $echoWaitingForSpell And Not $echoCopyReady Then
		; Auspicious Incantation refunds more than the cost of the next spell - Arcane Echo is the best candidate, Ebon Vanguard Assassin Support is fine
		If Not $auspiciousActive And IsAPSlotUsable($skillbar, $skillTimer, $BUILD_XA_AUSPICIOUS_INCANTATION, $energy) And $energy <= GetMaxEnergy() - $AP_ENERGY_HEADROOM_FOR_REFUND Then
			Local $energyAfterIncantation = $energy - GetSkillEnergyCost($ID_AUSPICIOUS_INCANTATION)
			Local $echoAffordable = CanCastArcaneEcho($skillbar, $skillTimer, $energyAfterIncantation, $echoSlotID, $echoWaitingForSpell, True)
			Local $assassinSupportAffordable = IsAPSlotUsable($skillbar, $skillTimer, $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT, $energyAfterIncantation)
			If $echoAffordable Or $assassinSupportAffordable Then Return UseAPSkill($BUILD_XA_AUSPICIOUS_INCANTATION, Null, 'Auspicious Incantation')
		EndIf
		; Arcane Echo only right before Ebon Vanguard Assassin Support
		If $canArcaneEcho Then Return UseAPSkill($BUILD_XA_ARCANE_ECHO, Null, 'Arcane Echo')
	EndIf

	; 5. Ebon Vanguard Assassin Support - the original first so Arcane Echo gets its copy, then the copy on the same target for a double spike
	If $echoWaitingForSpell And $canAssassinSupport Then Return UseAPSkill($BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT, $target, 'Ebon Vanguard Assassin Support (to be echoed)')
	If $echoCopyReady And $energy >= GetSkillEnergyCost($ID_EBON_VANGUARD_ASSASSIN_SUPPORT) Then Return UseAPSkill($BUILD_XA_ARCANE_ECHO, $target, 'Ebon Vanguard Assassin Support (echoed copy)')
	If $canAssassinSupport Then Return UseAPSkill($BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT, $target, 'Ebon Vanguard Assassin Support')

	; 6. Anything else on the bar, from left to right
	Return UseAPFillerSkill($skillbar, $skillTimer, $energy, $target)
EndFunc


;~ Arcane Echo is only cast when Ebon Vanguard Assassin Support is recharged and there is energy for Arcane Echo,
;~ Ebon Vanguard Assassin Support and its echoed copy. With Auspicious Incantation active the refund covers Arcane Echo itself.
Func CanCastArcaneEcho($skillbar, $skillTimer, $energy, $echoSlotID, $echoWaitingForSpell, $auspiciousActive)
	If $BUILD_XA_ARCANE_ECHO < 0 Or $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT < 0 Then Return False
	If $echoSlotID <> $ID_ARCANE_ECHO Or $echoWaitingForSpell Then Return False
	If Not IsSkillRecharged($skillbar, $BUILD_XA_ARCANE_ECHO, $skillTimer) Then Return False
	If Not IsSkillRecharged($skillbar, $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT, $skillTimer) Then Return False
	Local $echoCost = GetSkillEnergyCost($ID_ARCANE_ECHO)
	Local $assassinSupportCost = GetSkillEnergyCost($ID_EBON_VANGUARD_ASSASSIN_SUPPORT)
	Local $energyNeeded = $auspiciousActive ? _Max($echoCost, 2 * $assassinSupportCost) : $echoCost + 2 * $assassinSupportCost
	Return $energy >= $energyNeeded
EndFunc


;~ Use the next non-core skill that is recharged and affordable, rotating from left to right across calls.
;~ Keeps $AP_FILLER_ENERGY_RESERVE energy aside so a shout stays available for the spike.
Func UseAPFillerSkill($skillbar, $skillTimer, $energy, $target)
	Local Static $nextSlot = 1
	For $offset = 0 To 7
		Local $slot = Mod($nextSlot - 1 + $offset, 8) + 1
		If IsAPCoreSlot($slot) Then ContinueLoop
		Local $skillID = DllStructGetData($skillbar, 'SkillID' & $slot)
		If $skillID == 0 Then ContinueLoop
		If Not IsSkillRecharged($skillbar, $slot, $skillTimer) Then ContinueLoop
		If $energy < GetSkillEnergyCost($skillID) + $AP_FILLER_ENERGY_RESERVE Then ContinueLoop
		$nextSlot = Mod($slot, 8) + 1
		Return UseAPSkill($slot, $target)
	Next
	Return False
EndFunc


;~ Return True if the slot holds one of the skills handled by the Assassin's Promise rules
Func IsAPCoreSlot($slot)
	Switch $slot
		Case $BUILD_XA_ASSASSINS_PROMISE, $BUILD_XA_FINISH_HIM, $BUILD_XA_YOU_MOVE_LIKE_A_DWARF, $BUILD_XA_EBON_VANGUARD_ASSASSIN_SUPPORT, $BUILD_XA_ARCANE_ECHO, $BUILD_XA_AUSPICIOUS_INCANTATION
			Return True
	EndSwitch
	Return False
EndFunc


;~ Return True if the slot exists, is recharged and its skill is affordable with the given energy
Func IsAPSlotUsable($skillbar, $skillTimer, $slot, $energy)
	If $slot < 1 Then Return False
	If Not IsSkillRecharged($skillbar, $slot, $skillTimer) Then Return False
	Return $energy >= GetSkillEnergyCost(DllStructGetData($skillbar, 'SkillID' & $slot))
EndFunc


;~ Use a skill and report whether it went off. UseSkillEx can time out on instant skills (shouts) before the
;~ recharge is visible, so the recharge state is checked again after a short delay.
Func UseAPSkill($slot, $target = Null, $name = '')
	If $name <> '' Then Debug('AP build - ' & $name)
	Local $used = UseSkillEx($slot, $target)
	If Not $used Then
		PingSleep(100)
		$used = Not IsRecharged($slot)
	EndIf
	Return $used
EndFunc


;~ Energy cost of a skill - the game stores 15 and 25 energy as special values
Func GetSkillEnergyCost($skillID)
	Local Static $costs[]
	If $skillID == 0 Then Return 0
	If MapExists($costs, $skillID) Then Return $costs[$skillID]
	Local $cost = DllStructGetData(GetSkillByID($skillID), 'EnergyCost')
	Switch $cost
		Case 11
			$cost = 15
		Case 12
			$cost = 25
	EndSwitch
	$costs[$skillID] = $cost
	Return $cost
EndFunc


;~ Maximum energy of the player
Func GetMaxEnergy()
	Return DllStructGetData(GetMyAgent(), 'MaxEnergy')
EndFunc


;~ Maximum health of an agent - foes do not always expose it, so fall back to the usual creature health for their level
Func GetAgentMaxHealthEstimate($agent)
	Local $maxHealth = DllStructGetData($agent, 'MaxHealth')
	If $maxHealth > 0 Then Return $maxHealth
	Return 100 + 20 * DllStructGetData($agent, 'Level')
EndFunc


;~ Norn title rank, derived from title points
Func GetNornRank()
	Local $points = GetNornTitle()
	Local $rank = 0
	For $threshold In $AP_NORN_RANK_POINTS
		If $points >= $threshold Then $rank += 1
	Next
	Return $rank
EndFunc


;~ Damage dealt by "Finish Him!" and "You Move Like a Dwarf!" at the current Norn rank
Func GetNornShoutDamage()
	Return $AP_NORN_SHOUT_DAMAGE[GetNornRank()]
EndFunc
