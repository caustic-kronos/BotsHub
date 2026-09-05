#include-once
#include <FileConstants.au3>
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'
#include '../../lib/ChestRunBenchmark.au3'


; Fast Cathedral of Flames level-one NM route recorded in-game over eleven runs.
; The route never persists instance-local agent IDs. Foes are reacquired by
; route phase, model family, location, allegiance, living state, and distance.
Global Const $COF_CHEST_DERVISH_SKILLBAR = 'Ogej4NfMLTjbHY3lsZ4OBMIQUQA'
; Reuse Tasca's proven stationary, unlimited-range support package. Hero seven
; is deliberately Ogden rather than Tasca's Paragon/Dervish support hero.
Global Const $COF_CHEST_DERVISH_SUPPORT_SKILLBAR = 'Ogmioys8cfpxAAAAAAAAAKvA'
Global Const $COF_CHEST_RANGER_SUPPORT_SKILLBAR = 'OgojYNYsKP3XAAAAAAAQObnyLA'
Global Const $COF_CHEST_NECROMANCER_SUPPORT_SKILLBAR = 'OApjQoGoKP3XAAAAAAAAA3hyLA'

Global Const $COF_CHEST_MONK_BUILD_DESCRIPTION = 'Prepared seven-hero support party required; see doc\CoF NM Chestrun.md.'

Global Const $COF_CHEST_INFORMATIONS = 'Fast Cathedral of Flames level-one chest run (Normal Mode).' & @CRLF _
	& '- Player: Dervish/Assassin, 3 Deadly Arts, 12 Shadow Arts, 12+ Mysticism' & @CRLF _
	& '- Automatically loads the player build and assembles the seven-hero support party' & @CRLF _
	& '- Party: Tasca support heroes in slots 1-6; Ogden Monk/Paragon in slot 7' & @CRLF _
	& '- Six stationary heroes provide unlimited-range Mystic Healing and Cautery Signet' & @CRLF _
	& '- Ogden follows only long enough to apply the opening protection, then returns to the support flag' & @CRLF _
	& '- Uses the two observed chest regions and never relies on runtime agent IDs' & @CRLF _
	& '- No cupcakes or other consumables are required' & @CRLF _
	& '- Writes benchmark and route diagnostics under logs\benchmarks'

Global Const $COF_CHEST_DURATION = 80 * 1000
Global Const $COF_CHEST_INSTANCE_WATCHDOG_MS = 96 * 1000
Global Const $COF_CHEST_WATCHDOG_ARM_MS = 80 * 1000
Global Const $COF_CHEST_DIAGNOSTIC_PATH = @ScriptDir & '\logs\benchmarks\cof-route-latest.csv'
Global Const $COF_CHEST_DIAGNOSTIC_DIRECTORY = @ScriptDir & '\logs\benchmarks'
Global Const $COF_CHEST_GADGET_ID = 8141
Global Const $COF_CHEST_AXEMASTER_MODEL_ID = 6681
Global Const $COF_CHEST_MOVE_TIMEOUT_MS = 12 * 1000
Global Const $COF_CHEST_EFFECT_WAIT_MS = 5 * 1000
Global Const $COF_CHEST_TARGET_ANCHOR_RANGE = 1800
Global Const $COF_CHEST_QUEST_DIALOG = 0x832103
Global Const $COF_CHEST_QUEST_ACCEPT_DIALOG = 0x832101
Global Const $COF_CHEST_ENTER_DIALOG = 0x832105
Global Const $COF_CHEST_ENTER_ACCEPT_DIALOG = 0x88
Global Const $COF_CHEST_GRON_X = -19166
Global Const $COF_CHEST_GRON_Y = 17980
Global Const $COF_CHEST_GRON_RESOLVE_RADIUS = 450
Global Const $COF_CHEST_GRON_READY_TIMEOUT_MS = 5000
Global Const $COF_CHEST_GRON_APPROACH_TIMEOUT_MS = 7000
Global Const $COF_CHEST_GRON_PROGRESS_TIMEOUT_MS = 1200
Global Const $COF_CHEST_HERO_DERVISH_1 = 1
Global Const $COF_CHEST_HERO_DERVISH_2 = 2
Global Const $COF_CHEST_HERO_DERVISH_3 = 3
Global Const $COF_CHEST_HERO_ZEPHYR_RANGER = 4
Global Const $COF_CHEST_HERO_BIP_NECRO_1 = 5
Global Const $COF_CHEST_HERO_BIP_NECRO_2 = 6
Global Const $COF_CHEST_HERO_OGDEN = 7

Global Const $COF_CHEST_SUPPORT_MYSTIC_HEALING = 1
Global Const $COF_CHEST_SUPPORT_CAUTERY_SIGNET = 2
Global Const $COF_CHEST_SUPPORT_SERPENTS_QUICKNESS = 6
Global Const $COF_CHEST_SUPPORT_BIP = 7
Global Const $COF_CHEST_SUPPORT_QUICKENING_ZEPHYR = 7
Global Const $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION = 8
Global Const $COF_CHEST_SUPPORT_HEAL_INTERVAL_MS = 1600
Global Const $COF_CHEST_SUPPORT_QZ_DURATION_MS = 75000
Global Const $COF_CHEST_SUPPORT_QZ_CAST_MS = 2000
Global Const $COF_CHEST_SUPPORT_READY_TIMEOUT_MS = 8000
Global Const $COF_CHEST_DROP_APPEAR_TIMEOUT_MS = 5000
Global Const $COF_CHEST_EXACT_PICKUP_TIMEOUT_MS = 2500
Global Const $COF_CHEST_DROP_RADIUS = 700

Global Const $COF_CHEST_ZEALOUS_RENEWAL = 1
Global Const $COF_CHEST_PIOUS_HASTE = 2
Global Const $COF_CHEST_DWARVEN_STABILITY = 3
Global Const $COF_CHEST_WASTRELS_COLLAPSE = 4
Global Const $COF_CHEST_DEATHS_CHARGE = 5
Global Const $COF_CHEST_VIPERS_DEFENSE = 6
Global Const $COF_CHEST_HEART_OF_SHADOW = 7
Global Const $COF_CHEST_DARK_PRISON = 8

Global Const $COF_CHEST_HERO_BLESSED_AURA = 1
Global Const $COF_CHEST_HERO_SPELL_BREAKER = 2
Global Const $COF_CHEST_HERO_FALL_BACK = 3
Global Const $COF_CHEST_HERO_BRACE_YOURSELF = 4

Global $cof_chest_setup = False
Global $cof_chest_diagnostic_capture_path = ''
Global $cof_chest_unblock_x = 0
Global $cof_chest_unblock_y = 0
Global $cof_chest_support_x = 0
Global $cof_chest_support_y = 0
Global $cof_chest_support_qz_timer = Null
Global $cof_chest_support_registered = False
Global $cof_chest_loot_blocked = False
Global $cof_chest_secured_loot_count = 0
Global $cof_chest_watchdog_timer = Null
Global $cof_chest_watchdog_registered = False
Global $cof_chest_watchdog_expired = False


;~ Run one complete Doomlore-to-Cathedral chest cycle and return to Doomlore.
Func CoFChestFarm()
	If Not $cof_chest_setup Then
		If SetupCoFChestFarm() == $FAIL Then Return $PAUSE
		; BotsHub starts its shared run clock before calling the farm. Exclude the
		; one-time return-point priming trip so GUI duration/progress for run 1
		; measures the same real chest cycle as every subsequent run.
		$run_timer = TimerInit()
	EndIf

	StartChestRunBenchmark('CoF NM')
	If EnterCoFChestInstance() == $FAIL Then
		FinishChestRunBenchmark($FAIL, 0, False)
		Return $FAIL
	EndIf

	$cof_chest_loot_blocked = False
	$cof_chest_secured_loot_count = 0
	CoFStartInstanceWatchdog()
	Local $result = CoFChestFarmLoop()
	CoFStopInstanceWatchdog()
	CoFStopSupportBattery()
	Local $openedChests = CountOpenedChests()
	Local $playerDied = IsPlayerDead()
	If $cof_chest_watchdog_expired Then $result = $FAIL
	ResignAndReturnToOutpost($ID_DOOMLORE_SHRINE)
	; For a chest/title route, opening at least one chest is productive even if
	; the player dies afterward. Preserve death as its own benchmark dimension.
	Local $benchmarkResult = ($openedChests > 0 And Not $cof_chest_loot_blocked And Not $cof_chest_watchdog_expired) ? $SUCCESS : $result
	If $cof_chest_loot_blocked Or $cof_chest_watchdog_expired Then $benchmarkResult = $FAIL
	FinishChestRunBenchmark($benchmarkResult, $openedChests, $playerDied)
	Return $benchmarkResult
EndFunc


;~ A one-minute farm must always have an exit. The configured 80-second route
;~ budget plus a 20% worst-case buffer gives every blocking helper 96 seconds
;~ total before /resign forces its IsPlayerAlive/MapID condition to unwind. Keep
;~ the watchdog dormant during the normal route: a 250 ms Adlib callback can
;~ perturb the latency-sensitive shadowstep/jaunt sequence even when its body is
;~ small. Arm the frequent check only after the ordinary 80-second route budget.
Func CoFStartInstanceWatchdog()
	CoFStopInstanceWatchdog()
	$cof_chest_watchdog_expired = False
	$cof_chest_watchdog_timer = TimerInit()
	$cof_chest_watchdog_registered = True
	AdlibRegister('CoFArmInstanceWatchdog', $COF_CHEST_WATCHDOG_ARM_MS)
EndFunc


Func CoFStopInstanceWatchdog()
	AdlibUnRegister('CoFArmInstanceWatchdog')
	AdlibUnRegister('CoFChestInstanceWatchdog')
	$cof_chest_watchdog_registered = False
	$cof_chest_watchdog_timer = Null
EndFunc


Func CoFArmInstanceWatchdog()
	AdlibUnRegister('CoFArmInstanceWatchdog')
	If Not $cof_chest_watchdog_registered Or $cof_chest_watchdog_timer == Null Then Return
	AdlibRegister('CoFChestInstanceWatchdog', 250)
	CoFChestInstanceWatchdog()
EndFunc


Func CoFChestInstanceWatchdog()
	If Not $cof_chest_watchdog_registered Or $cof_chest_watchdog_timer == Null Then Return
	If GetMapID() <> $ID_CATHEDRAL_OF_FLAMES Then Return
	If TimerDiff($cof_chest_watchdog_timer) < $COF_CHEST_INSTANCE_WATCHDOG_MS Then Return
	$cof_chest_watchdog_expired = True
	$cof_chest_watchdog_registered = False
	AdlibUnRegister('CoFChestInstanceWatchdog')
	Error('CoF instance exceeded 96 seconds; forcing /resign and failing the run')
	LogCoFRouteStage('instance-watchdog-resign')
	Resign()
EndFunc


;~ Configure the player, Tasca's six-hero support battery, Ogden, NM, and the resign return point.
Func SetupCoFChestFarm()
	Info('Setting up Cathedral of Flames NM chest run')
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)

	If DllStructGetData(GetMyAgent(), 'Primary') <> $ID_DERVISH Then
		Warn('CoF NM chest run requires a primary Dervish')
		Return $FAIL
	EndIf
	Info('Loading the Cathedral of Flames NM player and hero setup')
	If Not CoFLoadRequiredTemplate($COF_CHEST_DERVISH_SKILLBAR, 0, 'player') Then Return $FAIL
	If SetupCoFChestSupportTeam() == $FAIL Then Return $FAIL
	For $heroIndex = 1 To $COF_CHEST_HERO_OGDEN
		SetHeroBehaviour($heroIndex, $ID_HERO_AVOIDING)
	Next
	DisableAllHeroSkills($COF_CHEST_HERO_OGDEN)
	RandomSleep(250)

	; Prime the resign return point once per BotsHub start: enter Cathedral, turn
	; around, and exit through its entrance portal. Subsequent /resign returns the
	; party beside Gron instead of Doomlore's ordinary spawn point.
	If EnterCoFChestInstance() == $FAIL Then Return $FAIL
	Move(-19300, -8250)
	WaitMapLoading($ID_DOOMLORE_SHRINE, 10000, 1000)
	If GetMapID() <> $ID_DOOMLORE_SHRINE Then
		Warn('CoF return-point priming did not exit back to Doomlore Shrine')
		Return $FAIL
	EndIf

	$cof_chest_setup = True
	Info('Cathedral of Flames NM chest setup complete')
	Return $SUCCESS
EndFunc


;~ Load Tasca's first six support heroes in their established positional order,
;~ replacing only its seventh Paragon/Dervish with the CoF Monk/Paragon Ogden.
Func SetupCoFChestSupportTeam()
	LeaveParty()
	Local $requiredHeroes[] = [$ID_MELONNI, $ID_MOX, $ID_KAHMU, $ID_PYRE_FIERCESHOT, $ID_OLIAS, $ID_LIVIA, $ID_OGDEN]
	For $heroID In $requiredHeroes
		If AddRequiredHero($heroID) == $FAIL Then Return $FAIL
	Next
	If GetPartySize() <> 8 Then
		Warn('CoF NM chest run requires the six Tasca support heroes and Ogden')
		Return $FAIL
	EndIf

	If Not CoFLoadRequiredTemplate($COF_CHEST_DERVISH_SUPPORT_SKILLBAR, $COF_CHEST_HERO_DERVISH_1, 'Melonni') Then Return $FAIL
	If Not CoFLoadRequiredTemplate($COF_CHEST_DERVISH_SUPPORT_SKILLBAR, $COF_CHEST_HERO_DERVISH_2, 'M.O.X.') Then Return $FAIL
	If Not CoFLoadRequiredTemplate($COF_CHEST_DERVISH_SUPPORT_SKILLBAR, $COF_CHEST_HERO_DERVISH_3, 'Kahmu') Then Return $FAIL
	If Not CoFLoadRequiredTemplate($COF_CHEST_RANGER_SUPPORT_SKILLBAR, $COF_CHEST_HERO_ZEPHYR_RANGER, 'Pyre Fierceshot') Then Return $FAIL
	If Not CoFLoadRequiredTemplate($COF_CHEST_NECROMANCER_SUPPORT_SKILLBAR, $COF_CHEST_HERO_BIP_NECRO_1, 'Olias') Then Return $FAIL
	If Not CoFLoadRequiredTemplate($COF_CHEST_NECROMANCER_SUPPORT_SKILLBAR, $COF_CHEST_HERO_BIP_NECRO_2, 'Livia') Then Return $FAIL
	If SetupCoFChestMonkBar($COF_CHEST_HERO_OGDEN) == $FAIL Then Return $FAIL
	RandomSleep(500)

	; Tasca controls these two Ranger skills explicitly so the spirit timing is
	; deterministic and the Ranger does not spend them before the run begins.
	DisableHeroSkillSlot($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_SERPENTS_QUICKNESS)
	DisableHeroSkillSlot($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_QUICKENING_ZEPHYR)
	Return $SUCCESS
EndFunc


Func CoFLoadRequiredTemplate($template, $heroIndex, $actorName)
	For $attempt = 1 To 3
		LoadSkillTemplateIfNeeded($template, $heroIndex)
		If HeroHasTemplate($template, $heroIndex) Then Return True
		RandomSleep(250)
	Next
	Error('Could not load and verify the required CoF NM template for ' & $actorName)
	Return False
EndFunc


;~ Park Tasca's six support heroes at the player's settled instance entrance, prepare their
;~ local BiP/QZ engine, and leave Ogden unflagged until Spell Breaker lands.
Func CoFStartSupportBattery()
	CoFStopSupportBattery()
	Local $me = GetMyAgent()
	If $me == Null Then Return $FAIL
	$cof_chest_support_x = DllStructGetData($me, 'X')
	$cof_chest_support_y = DllStructGetData($me, 'Y')

	; Hero agents can materialize several seconds after the player reports the
	; map loaded. Do not turn that transient state into a failed 12-second run.
	If Not CoFWaitForSupportTeam($COF_CHEST_SUPPORT_READY_TIMEOUT_MS) Then Return $FAIL
	For $heroIndex = $COF_CHEST_HERO_DERVISH_1 To $COF_CHEST_HERO_BIP_NECRO_2
		CommandHero($heroIndex, $cof_chest_support_x, $cof_chest_support_y)
	Next
	CancelHero($COF_CHEST_HERO_OGDEN)

	; This is Tasca's proven preparation sequence, restricted to heroes 1-6.
	UseHeroSkill($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION)
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_BIP_NECRO_1, $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION)
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_DERVISH_1, $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION)
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_DERVISH_2, $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION)
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_DERVISH_3, $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION)
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_BIP_NECRO_2, $COF_CHEST_SUPPORT_FAITHFUL_INTERVENTION)
	RandomSleep(2000)

	UseHeroSkill($COF_CHEST_HERO_BIP_NECRO_1, $COF_CHEST_SUPPORT_BIP, GetAgentByID(GetHeroID($COF_CHEST_HERO_ZEPHYR_RANGER)))
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_SERPENTS_QUICKNESS)
	RandomSleep(50)
	UseHeroSkill($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_QUICKENING_ZEPHYR)
	$cof_chest_support_qz_timer = TimerInit()
	RandomSleep($COF_CHEST_SUPPORT_QZ_CAST_MS + 500)

	AdlibRegister('CoFTwiceHealingUnit', $COF_CHEST_SUPPORT_HEAL_INTERVAL_MS)
	$cof_chest_support_registered = True
	LogCoFRouteStage('support-battery-ready')
	Return $SUCCESS
EndFunc


;~ Wait for the complete party agent table after zoning. GetHeroID can be
;~ populated before GetAgentByID is valid, and the old instance's death bit can
;~ briefly remain visible, so all three states must settle before preparation.
Func CoFWaitForSupportTeam($timeoutMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		Local $allReady = True
		For $heroIndex = $COF_CHEST_HERO_DERVISH_1 To $COF_CHEST_HERO_OGDEN
			Local $heroID = GetHeroID($heroIndex)
			If $heroID == 0 Then
				$allReady = False
				ExitLoop
			EndIf
			Local $hero = GetAgentByID($heroID)
			If $hero == Null Or BitAND(DllStructGetData($hero, 'Effects'), 0x0010) > 0 Then
				$allReady = False
				ExitLoop
			EndIf
		Next
		If $allReady Then
			LogCoFRouteStage('support-team-ready')
			Return True
		EndIf
		PingSleep(100)
	WEnd

	For $heroIndex = $COF_CHEST_HERO_DERVISH_1 To $COF_CHEST_HERO_OGDEN
		Local $finalHeroID = GetHeroID($heroIndex)
		If $finalHeroID == 0 Then
			Warn('CoF hero slot ' & $heroIndex & ' is absent after the post-zone readiness wait')
			ContinueLoop
		EndIf
		Local $finalHero = GetAgentByID($finalHeroID)
		If $finalHero == Null Then
			Warn('CoF hero slot ' & $heroIndex & ' has no live agent after the post-zone readiness wait')
		ElseIf BitAND(DllStructGetData($finalHero, 'Effects'), 0x0010) > 0 Then
			Warn('CoF hero slot ' & $heroIndex & ' is still dead after the post-zone readiness wait')
		EndIf
	Next
	Return False
EndFunc


;~ Always unregister the asynchronous support controller before zoning/resign.
Func CoFStopSupportBattery()
	If Not $cof_chest_support_registered Then Return
	AdlibUnRegister('CoFTwiceHealingUnit')
	$cof_chest_support_registered = False
EndFunc


;~ CoF adaptation of Tasca's twice-per-cycle healing unit. Ogden is excluded
;~ because slot one on his bar is Blessed Aura, not Mystic Healing. Cautery
;~ Signet is rotated across the three Dervishes to clear remote Cripple and
;~ other conditions without making the party follow the runner.
Func CoFTwiceHealingUnit()
	Local Static $adlibBusy = False
	Local Static $healerGroup = 0
	Local Static $cauteryHero = $COF_CHEST_HERO_DERVISH_1
	If $adlibBusy Or Not $cof_chest_support_registered Or Not IsPlayerAlive() Then Return
	$adlibBusy = True

	If $cof_chest_support_qz_timer <> Null And TimerDiff($cof_chest_support_qz_timer) > ($COF_CHEST_SUPPORT_QZ_DURATION_MS - 5000) Then
		UseHeroSkill($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_QUICKENING_ZEPHYR)
		$cof_chest_support_qz_timer = TimerInit()
	EndIf

	If GetHasCondition(GetMyAgent()) Then
		For $offset = 0 To 2
			Local $candidate = $COF_CHEST_HERO_DERVISH_1 + Mod(($cauteryHero - $COF_CHEST_HERO_DERVISH_1) + $offset, 3)
			If Not IsHeroDead($candidate) And IsRecharged($COF_CHEST_SUPPORT_CAUTERY_SIGNET, $candidate) Then
				UseHeroSkill($candidate, $COF_CHEST_SUPPORT_CAUTERY_SIGNET)
				$cauteryHero = $COF_CHEST_HERO_DERVISH_1 + Mod(($candidate - $COF_CHEST_HERO_DERVISH_1) + 1, 3)
				ExitLoop
			EndIf
		Next
	EndIf

	If DllStructGetData(GetMyAgent(), 'HealthPercent') < 1 Then
		If $healerGroup == 0 Then
			UseHeroSkill($COF_CHEST_HERO_DERVISH_1, $COF_CHEST_SUPPORT_MYSTIC_HEALING)
			UseHeroSkill($COF_CHEST_HERO_DERVISH_2, $COF_CHEST_SUPPORT_MYSTIC_HEALING)
			UseHeroSkill($COF_CHEST_HERO_BIP_NECRO_1, $COF_CHEST_SUPPORT_MYSTIC_HEALING)
			$healerGroup = 1
		Else
			UseHeroSkill($COF_CHEST_HERO_DERVISH_3, $COF_CHEST_SUPPORT_MYSTIC_HEALING)
			UseHeroSkill($COF_CHEST_HERO_BIP_NECRO_2, $COF_CHEST_SUPPORT_MYSTIC_HEALING)
			If $cof_chest_support_qz_timer <> Null And TimerDiff($cof_chest_support_qz_timer) > ($COF_CHEST_SUPPORT_QZ_CAST_MS + 500) Then _
				UseHeroSkill($COF_CHEST_HERO_ZEPHYR_RANGER, $COF_CHEST_SUPPORT_MYSTIC_HEALING)
			$healerGroup = 0
		EndIf
	EndIf

	$adlibBusy = False
EndFunc


;~ Enter Cathedral through Gron with bounded retries and a map-load postcondition.
Func EnterCoFChestInstance()
	If TravelToOutpost($ID_DOOMLORE_SHRINE, $district_name) == $FAIL Then Return $FAIL
	If GetMapID() == $ID_CATHEDRAL_OF_FLAMES Then Return $SUCCESS

	For $attempt = 1 To 3
		Info('Entering Cathedral of Flames, attempt ' & $attempt)
		Local $gron = ResolveReadyCoFGron($COF_CHEST_GRON_READY_TIMEOUT_MS)
		If $gron == Null Then
			Warn('Could not resolve a stable Gron Fierceclaw agent')
			Return $FAIL
		EndIf

		; Try the active-quest entry path first. This avoids relying on the quest
		; state reader, which can report Temple of the Damned as missing here.
		If TryEnterCoFChestWithGron($gron) Then Return $SUCCESS

		; The entry option was not active. Accept the quest opportunistically;
		; unavailable dialog packets are ignored by the client.
		If Not CoFApproachAndInteractGron($gron) Then ContinueLoop
		PingSleep(250)
		Dialog($COF_CHEST_QUEST_DIALOG)
		PingSleep(750)
		Dialog($COF_CHEST_QUEST_ACCEPT_DIALOG)
		PingSleep(1000)

		; Reopen the root dialog so an accept/quest-detail page cannot become
		; stale input for the dungeon-entry sequence.
		$gron = ResolveReadyCoFGron($COF_CHEST_GRON_READY_TIMEOUT_MS)
		If $gron <> Null And TryEnterCoFChestWithGron($gron) Then Return $SUCCESS
	Next

	Warn('Could not enter Cathedral of Flames after three dialogue attempts')
	Return $FAIL
EndFunc


;~ Select Temple of the Damned and confirm entry, returning only on map load.
Func TryEnterCoFChestWithGron($gron)
	If Not CoFApproachAndInteractGron($gron) Then Return False
	PingSleep(250)
	Dialog($COF_CHEST_ENTER_DIALOG)
	PingSleep(750)
	Dialog($COF_CHEST_ENTER_ACCEPT_DIALOG)
	Return WaitMapLoading($ID_CATHEDRAL_OF_FLAMES, 6000, 1000)
EndFunc


;~ Wait for Doomlore's NPC table to settle after ReturnToOutpost. A matching map
;~ ID can precede valid live agents; using that transient table once sent run 3
;~ toward a rock on the opposite side of Gron.
Func ResolveReadyCoFGron($timeoutMs)
	Local $timer = TimerInit()
	Local $stableAgentID = 0
	Local $stableSamples = 0
	While TimerDiff($timer) < $timeoutMs And GetMapID() == $ID_DOOMLORE_SHRINE
		Local $candidate = GetNearestNPCToCoords($COF_CHEST_GRON_X, $COF_CHEST_GRON_Y)
		If $candidate <> Null Then
			Local $candidateID = DllStructGetData($candidate, 'ID')
			Local $positionError = GetDistanceToPoint($candidate, $COF_CHEST_GRON_X, $COF_CHEST_GRON_Y)
			If $candidateID <> 0 And $positionError <= $COF_CHEST_GRON_RESOLVE_RADIUS Then
				If $candidateID == $stableAgentID Then
					$stableSamples += 1
				Else
					$stableAgentID = $candidateID
					$stableSamples = 1
				EndIf
				If $stableSamples >= 3 Then
					$candidate = GetAgentByID($stableAgentID)
					If $candidate <> Null And GetDistanceToPoint($candidate, $COF_CHEST_GRON_X, $COF_CHEST_GRON_Y) <= $COF_CHEST_GRON_RESOLVE_RADIUS Then
						Info('Resolved Gron agent ' & $stableAgentID & ' at (' & Round(DllStructGetData($candidate, 'X'), 0) & ', ' & Round(DllStructGetData($candidate, 'Y'), 0) & ')')
						Return $candidate
					EndIf
				EndIf
			Else
				$stableAgentID = 0
				$stableSamples = 0
			EndIf
		Else
			$stableAgentID = 0
			$stableSamples = 0
		EndIf
		PingSleep(100)
	WEnd
	Return Null
EndFunc


;~ Approach only the validated live Gron agent. Detect actual coordinate
;~ progress, because GW can report ordinary movement indefinitely while a bad
;~ command pushes the character against terrain.
Func CoFApproachAndInteractGron($gron)
	If $gron == Null Then Return False
	Local $targetID = DllStructGetData($gron, 'ID')
	Move(DllStructGetData($gron, 'X'), DllStructGetData($gron, 'Y'))
	GoNPC($gron)
	Local $timer = TimerInit()
	Local $progressTimer = TimerInit()
	Local $commandTimer = TimerInit()
	Local $lastDistance = 999999
	Local $recoveries = 0
	While TimerDiff($timer) < $COF_CHEST_GRON_APPROACH_TIMEOUT_MS And GetMapID() == $ID_DOOMLORE_SHRINE
		Local $liveGron = GetAgentByID($targetID)
		If $liveGron == Null Or DllStructGetData($liveGron, 'ID') == 0 _
			Or GetDistanceToPoint($liveGron, $COF_CHEST_GRON_X, $COF_CHEST_GRON_Y) > $COF_CHEST_GRON_RESOLVE_RADIUS Then
			$liveGron = ResolveReadyCoFGron(1500)
			If $liveGron == Null Then Return False
			$targetID = DllStructGetData($liveGron, 'ID')
		EndIf

		Local $distance = GetDistance(GetMyAgent(), $liveGron)
		If $distance <= 250 Then
			GoNPC($liveGron)
			PingSleep(150)
			Return True
		EndIf
		If $distance < $lastDistance - 35 Then
			$lastDistance = $distance
			$progressTimer = TimerInit()
		EndIf

		If TimerDiff($progressTimer) >= $COF_CHEST_GRON_PROGRESS_TIMEOUT_MS Then
			$recoveries += 1
			Warn('No positional progress toward Gron; cancelling and reacquiring (' & $recoveries & '/3)')
			CancelAction()
			PingSleep(100)
			$liveGron = ResolveReadyCoFGron(1500)
			If $liveGron == Null Then Return False
			$targetID = DllStructGetData($liveGron, 'ID')
			$lastDistance = 999999
			$progressTimer = TimerInit()
			If $recoveries >= 3 Then Return False
		EndIf

		If TimerDiff($commandTimer) >= 500 Then
			Move(DllStructGetData($liveGron, 'X'), DllStructGetData($liveGron, 'Y'))
			GoNPC($liveGron)
			$commandTimer = TimerInit()
		EndIf
		PingSleep(75)
	WEnd
	Warn('Timed out approaching validated Gron agent')
	Return False
EndFunc


;~ Load the observed opening support bar on the Monk/Paragon hero.
Func SetupCoFChestMonkBar($heroIndex = $COF_CHEST_HERO_OGDEN)
	Local $attributes[10][2]
	$attributes[0][0] = $ID_PARAGON
	$attributes[0][1] = 2
	$attributes[1][0] = $ID_DIVINE_FAVOR
	$attributes[1][1] = 12
	$attributes[2][0] = $ID_COMMAND
	$attributes[2][1] = 12
	LoadAttributes($attributes, $ID_PARAGON, $heroIndex)
	LoadSkillBar($ID_BLESSED_AURA, $ID_SPELL_BREAKER, $ID_FALL_BACK, $ID_BRACE_YOURSELF, 0, 0, 0, 0, $heroIndex)
	RandomSleep(250)
	If GetHeroProfession($heroIndex, True) <> $ID_PARAGON Then
		Error('Could not set Ogden secondary profession to Paragon')
		Return $FAIL
	EndIf
	Local $requiredSkills[] = [$ID_BLESSED_AURA, $ID_SPELL_BREAKER, $ID_FALL_BACK, $ID_BRACE_YOURSELF]
	For $slot = 1 To UBound($requiredSkills)
		If GetSkillbarSkillID($slot, $heroIndex) <> $requiredSkills[$slot - 1] Then
			Error('Could not verify Ogden CoF NM skill slot ' & $slot)
			Return $FAIL
		EndIf
	Next
	Return $SUCCESS
EndFunc


;~ Execute the recorded level-one route and search each chest region once.
Func CoFChestFarmLoop()
	If GetInventoryItemCount($ID_LOCKPICK) == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf
	If GetMapID() <> $ID_CATHEDRAL_OF_FLAMES Then Return $FAIL

	InitializeCoFRouteDiagnostic()
	LogCoFRouteStage('zoned')
	If CoFStartSupportBattery() == $FAIL Then Return $FAIL
	If CoFPrepareChestRun() == $FAIL Then Return $FAIL

	; Approach the Charr Axemaster observed at the first stable target region.
	If CoFChestMove(-17000, -8750, 'opening-run') == $FAIL Then Return $FAIL
	Local $firstTarget = CoFUseRequiredShadowStepWhileApproaching($COF_CHEST_WASTRELS_COLLAPSE, -15600, -6800, -15600, -6800, 'shadow-one', $COF_CHEST_AXEMASTER_MODEL_ID)
	If $firstTarget <> Null Then
		; The recorded route deliberately double-jaunts here. Reacquire the second
		; anchor only after the first displacement has settled so moving patrols do
		; not reuse stale pre-jaunt geometry.
		CoFUseJumpsOnTarget($firstTarget, 2, 'jump-one', -15000, -5450)
	Else
		; An Axemaster already fighting the undead can be covered by Ray of
		; Judgment. Running onward is safer than teleporting into that fight.
		LogCoFRouteStage('shadow-one-skipped')
	EndIf

	; Follow the corridor and reacquire the Charr at its current live position.
	If CoFChestMove(-15000, -5450, 'first-corridor') == $FAIL Then Return $FAIL
	If CoFChestMove(-13800, -3600, 'hallway-approach') == $FAIL Then Return $FAIL
	Local $secondTarget = CoFUseShadowStep($COF_CHEST_DEATHS_CHARGE, -13000, -2700, True, 'shadow-two')
	If $secondTarget == Null Then
		CoFTryForwardShadowStep(-12500, -1750, 'shadow-two-forward')
	Else
		; Take the hallway jaunt only when the live Axemaster is already safely
		; behind us. Never walk around a wall-side target merely to manufacture an
		; angle; that was the source of the repeatable corner traps.
		CoFUseJumpsOnTarget($secondTarget, 1, 'jump-two', -12500, -1750, False)
	EndIf

	; The third region is the Charr/undead fight at the end of the hallway.
	If CoFChestMove(-12500, -1750, 'hallway-end') == $FAIL Then Return $FAIL
	Local $thirdTarget = CoFUseShadowStep($COF_CHEST_DARK_PRISON, -11600, -700, False, 'shadow-three')
	Local $postHallAdvanced = $thirdTarget <> Null
	If $thirdTarget == Null Then
		; Patrol positions vary. Fall back to any clearly forward non-spirit foe
		; instead of silently walking the entire dangerous post-hall section.
		$postHallAdvanced = CoFTryForwardShadowStep(-10300, 700, 'shadow-three-forward', 150)
	EndIf
	Local $nearHallwayChest = FindCoFChestInRegion(-12500, -7500, -1500, 3000, $RANGE_EARSHOT)
	If $thirdTarget <> Null And $nearHallwayChest == Null Then CoFUseJumpsOnTarget($thirdTarget, 1, 'jump-three', -11400, -450)
	If Not $postHallAdvanced And $nearHallwayChest == Null Then CoFTryForwardJump(-10300, 700, 'shadow-three-jump-fallback')

	Local $openedZoneOne = CoFSearchAndOpenZoneOne()
	If IsPlayerDead() Then Return $FAIL
	If $cof_chest_loot_blocked Or $cof_chest_watchdog_expired Then Return $FAIL
	Local $openedZoneTwo = CoFSearchAndOpenZoneTwo()
	If IsPlayerDead() Then Return $FAIL
	If $cof_chest_loot_blocked Or $cof_chest_watchdog_expired Then Return $FAIL

	Local $openedChests = CountOpenedChests()
	LogCoFRouteStage('complete')
	Info('Opened ' & $openedChests & ' CoF NM chests')
	If Not $openedZoneOne And Not $openedZoneTwo Then
		Warn('No chest was found in either recorded CoF region')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Apply all required hero and player effects before the first shadow step.
Func CoFPrepareChestRun()
	Local $heroID = GetHeroID($COF_CHEST_HERO_OGDEN)
	If $heroID == 0 Or IsHeroDead($COF_CHEST_HERO_OGDEN) Then Return $FAIL

	; Blessed Aura must be effective before Spell Breaker is cast.
	If Not CoFUseHeroSkillWithRetry($COF_CHEST_HERO_BLESSED_AURA, Null, 'Blessed Aura') Then Return $FAIL
	If Not CoFWaitForEffect($ID_BLESSED_AURA, $heroID, $COF_CHEST_EFFECT_WAIT_MS) Then
		Warn('Blessed Aura did not become observable on the hero')
		Return $FAIL
	EndIf
	; These shouts may occur in either order. Cast them before Spell Breaker to
	; preserve as much of Spell Breaker as possible for the route.
	If Not CoFUseHeroSkillWithRetry($COF_CHEST_HERO_FALL_BACK, Null, 'Fall Back') Then Return $FAIL
	If Not CoFUseHeroSkillWithRetry($COF_CHEST_HERO_BRACE_YOURSELF, GetMyAgent(), 'Brace Yourself') Then Return $FAIL
	If Not UseSkillTimed($COF_CHEST_DWARVEN_STABILITY) Then Return $FAIL
	If Not UseSkillTimed($COF_CHEST_ZEALOUS_RENEWAL) Then Return $FAIL
	If Not UseSkillTimed($COF_CHEST_PIOUS_HASTE) Then Return $FAIL

	; No player skill is cast after movement begins, so the hero can apply Spell
	; Breaker without stopping the player's opening run.
	Move(-17000, -8750)
	LogCoFRouteStage('setup-run-started')
	If Not CoFUseHeroSkillWithRetry($COF_CHEST_HERO_SPELL_BREAKER, GetMyAgent(), 'Spell Breaker') Then Return $FAIL
	If Not CoFWaitForEffect($ID_SPELL_BREAKER, GetMyID(), $COF_CHEST_EFFECT_WAIT_MS) Then
		Warn('Spell Breaker did not become observable on the player')
		Return $FAIL
	EndIf
	; Ogden must follow long enough to cast Spell Breaker on the moving player.
	; Once the effect is confirmed, explicitly re-flag all seven heroes at the
	; entrance so Ogden cannot continue following and the battery stays parked.
	CommandAll($cof_chest_support_x, $cof_chest_support_y)
	LogCoFRouteStage('all-heroes-flagged')

	LogCoFRouteStage('prepared')
	Return $SUCCESS
EndFunc


;~ Retry a required manually controlled hero skill while energy recovers.
Func CoFUseHeroSkillWithRetry($skillSlot, $target, $skillName)
	Local $timer = TimerInit()
	While TimerDiff($timer) < 8000 And IsPlayerAlive() And Not IsHeroDead($COF_CHEST_HERO_OGDEN)
		If UseHeroSkillTimed($COF_CHEST_HERO_OGDEN, $skillSlot, $target) Then
			LogCoFRouteAction('HERO_SKILL', $skillName, GetHeroID($COF_CHEST_HERO_OGDEN), GetSkillbarSkillID($skillSlot, $COF_CHEST_HERO_OGDEN))
			Return True
		EndIf
		PingSleep(250)
	WEnd
	Warn('Hero could not use required skill: ' & $skillName)
	Return False
EndFunc


;~ Wait for an effect to become observable on a specific live agent.
Func CoFWaitForEffect($skillID, $agentID, $timeoutMs)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $timeoutMs And IsPlayerAlive()
		If GetEffect($skillID, $agentID) <> Null Then Return True
		PingSleep(50)
	WEnd
	Return False
EndFunc


;~ Move to a recorded route checkpoint with ordered speed maintenance.
Func CoFChestMove($x, $y, $stage, $arrivalRange = 250)
	Local $timer = TimerInit()
	Local $blocked = 0
	Local $progressTimer = TimerInit()
	Local $lastProgressDistance = GetDistanceToPoint(GetMyAgent(), $x, $y)
	Move($x, $y)
	While IsPlayerAlive() And GetDistanceToPoint(GetMyAgent(), $x, $y) > $arrivalRange
		If TimerDiff($timer) > $COF_CHEST_MOVE_TIMEOUT_MS Then
			Warn('Timed out at CoF route stage: ' & $stage)
			LogCoFRouteStage($stage & '-timeout')
			Return $FAIL
		EndIf
		CoFMaintainChestRunSkills()
		Local $currentDistance = GetDistanceToPoint(GetMyAgent(), $x, $y)
		If $currentDistance < $lastProgressDistance - 50 Then
			$lastProgressDistance = $currentDistance
			$progressTimer = TimerInit()
		ElseIf TimerDiff($progressTimer) >= 1500 Then
			; GW can report ordinary movement while the player is wedged against
			; terrain or rubberbanding. Coordinate progress is authoritative.
			LogCoFRouteStage($stage & '-no-progress-recovery')
			CancelAction()
			CoFRecoverFromBodyBlock($x, $y, $stage)
			Move($x, $y)
			$lastProgressDistance = GetDistanceToPoint(GetMyAgent(), $x, $y)
			$progressTimer = TimerInit()
			$blocked = 0
		EndIf
		If Not IsPlayerMoving() Then
			$blocked += 1
			Move($x, $y)
			If $blocked >= 3 Then
				CoFRecoverFromBodyBlock($x, $y, $stage)
				$blocked = 0
			EndIf
		Else
			$blocked = 0
		EndIf
		PingSleep(100)
	WEnd
	LogCoFRouteStage($stage)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Scan for one exact model while approaching; never substitute a nearby foe.
Func CoFUseRequiredShadowStepWhileApproaching($preferredSlot, $destinationX, $destinationY, $anchorX, $anchorY, $stage, $requiredModelID)
	Local $timer = TimerInit()
	Local $blocked = 0
	Local $lockedTargetID = 0
	Move($destinationX, $destinationY)
	While IsPlayerAlive() And TimerDiff($timer) < $COF_CHEST_MOVE_TIMEOUT_MS
		Local $target = Null
		If $lockedTargetID <> 0 Then
			$target = GetAgentByID($lockedTargetID)
			If $target == Null Or GetIsDead($target) Then
				$lockedTargetID = 0
				$target = Null
			EndIf
		EndIf
		If $target == Null Then $target = GetCoFShadowStepTarget($anchorX, $anchorY, $COF_CHEST_TARGET_ANCHOR_RANGE, True, $requiredModelID)
		If $target <> Null Then
			If IsCoFOpeningAxemasterUnsafe($target) Then
				LogCoFTarget($stage & '-unsafe-combat', $target, 0)
				Move($destinationX, $destinationY)
				Return Null
			EndIf
			$lockedTargetID = DllStructGetData($target, 'ID')
			If GetDistance(GetMyAgent(), $target) > 850 Then
				Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
				PingSleep(75)
				ContinueLoop
			EndIf
			Local $skillSlot = GetCoFReadyShadowStep($preferredSlot)
			If $skillSlot == 0 Then Return Null
			LogCoFTarget($stage & '-attempt', $target, $skillSlot)
			If UseSkillExNew($skillSlot, $target, 4000) Then
				$target = CoFWaitForShadowStepArrival($lockedTargetID)
				If $target == Null Or GetDistance(GetMyAgent(), $target) > 400 Then
					LogCoFRouteStage($stage & '-arrival-timeout')
					Return Null
				EndIf
				LogCoFTarget($stage & '-activated', $target, $skillSlot)
				LogCoFRouteStage($stage)
				Return $target
			EndIf
			LogCoFRouteStage($stage & '-cast-retry')
			Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
		EndIf

		If Not IsPlayerMoving() And GetDistanceToPoint(GetMyAgent(), $destinationX, $destinationY) > 250 Then
			$blocked += 1
			Move($destinationX, $destinationY)
			If $blocked >= 3 Then
				CoFRecoverFromBodyBlock($destinationX, $destinationY, $stage & '-approach')
				$blocked = 0
			EndIf
		Else
			$blocked = 0
		EndIf
		PingSleep(75)
	WEnd
	Warn('Required Axemaster did not enter range for ' & $stage)
	LogCoFRouteStage($stage & '-required-target-missing')
	Return Null
EndFunc


;~ Recharge begins at cast start; wait for the actual teleport before jaunting.
Func CoFWaitForShadowStepArrival($targetID)
	Local $timer = TimerInit()
	Local $target = GetAgentByID($targetID)
	While TimerDiff($timer) < 1800 And IsPlayerAlive()
		$target = GetAgentByID($targetID)
		If $target == Null Or GetIsDead($target) Then Return $target
		If Not IsCasting(GetMyAgent()) And GetDistance(GetMyAgent(), $target) <= 300 Then Return $target
		PingSleep(50)
	WEnd
	Return $target
EndFunc


;~ Use one available shadowstep only when a living foe is clearly forward.
Func CoFTryForwardShadowStep($destinationX, $destinationY, $stage, $minimumForward = 450)
	Local $target = GetCoFForwardShadowTarget($destinationX, $destinationY, $minimumForward)
	If $target == Null Then Return False
	Local $skillSlot = GetCoFReadyShadowStep($COF_CHEST_WASTRELS_COLLAPSE)
	If $skillSlot == 0 Then Return False
	Local $targetID = DllStructGetData($target, 'ID')
	If GetDistance(GetMyAgent(), $target) > 850 Then
		GetAlmostInRangeOfAgent($target, 850)
		$target = GetAgentByID($targetID)
		If $target == Null Or GetIsDead($target) Then Return False
	EndIf
	LogCoFTarget($stage & '-attempt', $target, $skillSlot)
	If Not UseSkillExNew($skillSlot, $target, 4000) Then
		LogCoFRouteStage($stage & '-not-activated')
		; A rejected/range-lost skill can leave the client chasing the former
		; target, pulling the route backward into terrain.
		CancelAction()
		Return False
	EndIf
	$target = CoFWaitForShadowStepArrival($targetID)
	If $target == Null Or GetDistance(GetMyAgent(), $target) > 400 Then
		LogCoFRouteStage($stage & '-arrival-timeout')
		CancelAction()
		Return False
	EndIf
	LogCoFTarget($stage & '-activated', $target, $skillSlot)
	CoFUseJumpsOnTarget($target, 1, $stage & '-jump', $destinationX, $destinationY)
	Return True
EndFunc


;~ Use a ready jaunt on a geometrically behind-left foe without shadowstepping.
Func CoFTryForwardJump($destinationX, $destinationY, $stage)
	Local $target = GetCoFBackLeftJumpTarget($destinationX, $destinationY)
	If $target == Null Then Return False
	Return CoFUseJumpsOnTarget($target, 1, $stage, $destinationX, $destinationY) > 0
EndFunc


;~ Select a phase-local foe that advances the player toward the destination.
Func GetCoFForwardShadowTarget($destinationX, $destinationY, $minimumForward)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $forwardX = $destinationX - $myX
	Local $forwardY = $destinationY - $myY
	Local $forwardLength = Sqrt($forwardX * $forwardX + $forwardY * $forwardY)
	If $forwardLength <= 0 Then Return Null
	$forwardX /= $forwardLength
	$forwardY /= $forwardLength
	Local $leftX = -$forwardY
	Local $leftY = $forwardX
	Local $bestTarget = Null
	Local $bestScore = -999999
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 350)
	If Not IsArray($foes) Then Return Null
	For $foe In $foes
		If GetIsDead($foe) Or DllStructGetData($foe, 'HealthPercent') <= 0 Then ContinueLoop
		If IsCoFInvalidShadowStepTargetModel(DllStructGetData($foe, 'ModelID')) Then ContinueLoop
		Local $relativeX = DllStructGetData($foe, 'X') - $myX
		Local $relativeY = DllStructGetData($foe, 'Y') - $myY
		Local $forwardProjection = $relativeX * $forwardX + $relativeY * $forwardY
		Local $lateralProjection = Abs($relativeX * $leftX + $relativeY * $leftY)
		If $forwardProjection < $minimumForward Or $lateralProjection > 900 Then ContinueLoop
		Local $score = $forwardProjection - ($lateralProjection * 0.35)
		If IsCoFDiscouragedShadowTargetModel(DllStructGetData($foe, 'ModelID')) Then $score -= 3000
		If $score > $bestScore Then
			$bestTarget = $foe
			$bestScore = $score
		EndIf
	Next
	Return $bestTarget
EndFunc


;~ Refresh Dwarven Stability and the Zealous Renewal/Pious Haste pair in order.
Func CoFMaintainChestRunSkills()
	If GetEffectTimeRemaining($ID_PIOUS_HASTE) >= 1500 Then Return
	If GetEffectTimeRemaining($ID_DWARVEN_STABILITY) < 3000 And GetEnergy() >= 5 And IsRecharged($COF_CHEST_DWARVEN_STABILITY) Then
		UseSkillTimed($COF_CHEST_DWARVEN_STABILITY)
	EndIf
	If GetEnergy() < 10 Then Return
	If Not IsRecharged($COF_CHEST_ZEALOUS_RENEWAL) Or Not IsRecharged($COF_CHEST_PIOUS_HASTE) Then Return
	If Not UseSkillTimed($COF_CHEST_ZEALOUS_RENEWAL) Then Return
	UseSkillTimed($COF_CHEST_PIOUS_HASTE)
EndFunc


;~ Reacquire a phase-local foe and perform a preferred forward shadow step.
Func CoFUseShadowStep($preferredSlot, $anchorX, $anchorY, $preferCharr, $stage, $requiredModelID = 0)
	Local $target = GetCoFShadowStepTarget($anchorX, $anchorY, $COF_CHEST_TARGET_ANCHOR_RANGE, $preferCharr, $requiredModelID)
	If $target == Null Then
		Warn('No live target found for CoF route stage: ' & $stage)
		LogCoFRouteStage($stage & '-no-target')
		Return Null
	EndIf

	Local $skillSlot = GetCoFReadyShadowStep($preferredSlot)
	If $skillSlot == 0 Then
		Warn('No shadow step is recharged for CoF route stage: ' & $stage)
		Return Null
	EndIf

	Local $targetID = DllStructGetData($target, 'ID')
	If GetDistance(GetMyAgent(), $target) > 850 Then
		GetAlmostInRangeOfAgent($target, 850)
		$target = GetAgentByID($targetID)
		If $target == Null Or GetIsDead($target) Then Return Null
	EndIf
	LogCoFTarget($stage & '-attempt', $target, $skillSlot)
	If Not UseSkillExNew($skillSlot, $target, 4000) Then
		LogCoFRouteStage($stage & '-not-activated')
		CancelAction()
		Return Null
	EndIf
	$target = CoFWaitForShadowStepArrival($targetID)
	If $target == Null Or GetDistance(GetMyAgent(), $target) > 400 Then
		LogCoFRouteStage($stage & '-arrival-timeout')
		CancelAction()
		Return Null
	EndIf
	LogCoFTarget($stage & '-activated', $target, $skillSlot)
	LogCoFRouteStage($stage)
	Return $target
EndFunc


;~ Select the preferred shadow step, with deterministic recharged fallbacks.
Func GetCoFReadyShadowStep($preferredSlot)
	If IsRecharged($preferredSlot) Then Return $preferredSlot
	If IsRecharged($COF_CHEST_WASTRELS_COLLAPSE) Then Return $COF_CHEST_WASTRELS_COLLAPSE
	If IsRecharged($COF_CHEST_DEATHS_CHARGE) Then Return $COF_CHEST_DEATHS_CHARGE
	If IsRecharged($COF_CHEST_DARK_PRISON) Then Return $COF_CHEST_DARK_PRISON
	Return 0
EndFunc


;~ Choose a live foe near the phase anchor; runtime IDs are never reused.
Func GetCoFShadowStepTarget($anchorX, $anchorY, $anchorRange, $preferCharr, $requiredModelID = 0)
	Local $target = Null
	Local $bestScore = 999999
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 350)
	If Not IsArray($foes) Then Return Null

	For $foe In $foes
		If GetIsDead($foe) Or DllStructGetData($foe, 'HealthPercent') <= 0 Then ContinueLoop
		Local $modelID = DllStructGetData($foe, 'ModelID')
		If IsCoFInvalidShadowStepTargetModel($modelID) Then ContinueLoop
		If $requiredModelID <> 0 And $modelID <> $requiredModelID Then ContinueLoop
		If $preferCharr And Not IsCoFCharrModel($modelID) Then ContinueLoop
		Local $anchorDistance = GetDistanceToPoint($foe, $anchorX, $anchorY)
		If $anchorDistance > $anchorRange Then ContinueLoop
		Local $score = $anchorDistance
		If IsCoFDiscouragedShadowTargetModel($modelID) Then $score += 3000
		If $score < $bestScore Then
			$target = $foe
			$bestScore = $score
		EndIf
	Next
	Return $target
EndFunc


;~ Identify the Charr model family observed at the first two target regions.
Func IsCoFCharrModel($modelID)
	Switch $modelID
		Case 6668, 6671, 6681, 6682
			Return True
	EndSwitch
	Return False
EndFunc


;~ These summoned spirits have produced rejected onto-target shadowsteps in
;~ live CoF testing. They remain valid targets for away-from-target jaunts.
Func IsCoFInvalidShadowStepTargetModel($modelID)
	Switch $modelID
		Case 4266, 4278 ; Destruction and Bloodsong spirit models
			Return True
	EndSwitch
	Return False
EndFunc


;~ Avoid teleporting into the opening Charr/undead fight. Ray of Judgment on
;~ an engaged Axemaster caused repeatable large health losses and deaths.
Func IsCoFOpeningAxemasterUnsafe($target)
	If $target == Null Or GetIsDead($target) Then Return True
	If GetIsAttacking($target) Or DllStructGetData($target, 'HealthPercent') < 0.98 Then Return True

	Local $targetID = DllStructGetData($target, 'ID')
	Local $nearbyFoes = GetFoesInRangeOfAgent($target, 600)
	If Not IsArray($nearbyFoes) Then Return False
	For $foe In $nearbyFoes
		If DllStructGetData($foe, 'ID') == $targetID Or GetIsDead($foe) Then ContinueLoop
		Switch DllStructGetData($foe, 'ModelID')
			Case 7075, 7077, 7079, 7081, 7083, 7085
				Return True
		EndSwitch
	Next
	Return False
EndFunc


;~ Deprioritize the Crippling Slash warrior, but retain it as a last-resort target.
Func IsCoFDiscouragedShadowTargetModel($modelID)
	Switch $modelID
		Case 7077 ; Crypt Slasher
			Return True
	EndSwitch
	Return False
EndFunc


;~ Use forward-facing jumps and confirm that each skill actually activated.
Func CoFUseJumpsOnTarget($target, $maximumJumps, $stage, $destinationX = Null, $destinationY = Null, $allowAlignment = True)
	If $target == Null Or GetIsDead($target) Then Return 0
	Local $jumps = 0
	Local $originalTargetID = DllStructGetData($target, 'ID')
	Local $jumpTarget = $target
	Local $jumpSlots[2] = [$COF_CHEST_VIPERS_DEFENSE, $COF_CHEST_HEART_OF_SHADOW]
	Local $jumpNames[2] = ['vipers', 'heart']
	For $index = 0 To 1
		If $jumps >= $maximumJumps Then ExitLoop
		If $jumps > 0 And $destinationX <> Null Then
			$jumpTarget = GetCoFBackLeftJumpTarget($destinationX, $destinationY, $originalTargetID)
			If $jumpTarget == Null Then $jumpTarget = GetCoFBehindJumpTarget($destinationX, $destinationY, $originalTargetID)
			If $jumpTarget == Null Then
				Local $originalTarget = GetAgentByID($originalTargetID)
				If $originalTarget <> Null And Not GetIsDead($originalTarget) And GetDistance(GetMyAgent(), $originalTarget) <= 850 Then $jumpTarget = $originalTarget
			EndIf
		EndIf
		If $jumpTarget == Null Or GetIsDead($jumpTarget) Then ContinueLoop
		If $destinationX <> Null And Not CoFIsTargetSafelyBehind($jumpTarget, $destinationX, $destinationY) Then
			If Not $allowAlignment Or Not CoFAlignTargetBehind($jumpTarget, $destinationX, $destinationY) Then
				LogCoFRouteStage($stage & '-' & $jumpNames[$index] & '-unsafe-angle')
				ContinueLoop
			EndIf
		EndIf
		If CoFUseJumpConfirmed($jumpSlots[$index], $jumpTarget, $stage & '-' & $jumpNames[$index]) Then $jumps += 1
	Next
	Return $jumps
EndFunc


;~ Check jaunt geometry without issuing movement. Used where wall-side alignment
;~ is more dangerous than skipping the acceleration.
Func CoFIsTargetSafelyBehind($target, $destinationX, $destinationY)
	If $target == Null Or GetIsDead($target) Then Return False
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $forwardX = $destinationX - $myX
	Local $forwardY = $destinationY - $myY
	Local $forwardLength = Sqrt($forwardX * $forwardX + $forwardY * $forwardY)
	If $forwardLength <= 0 Then Return False
	$forwardX /= $forwardLength
	$forwardY /= $forwardLength
	Local $targetProjection = (DllStructGetData($target, 'X') - $myX) * $forwardX + (DllStructGetData($target, 'Y') - $myY) * $forwardY
	Return $targetProjection <= -150 And GetDistance($me, $target) <= 850
EndFunc


;~ Move just far enough forward that a jump travels toward the next route point.
Func CoFAlignTargetBehind($target, $destinationX, $destinationY)
	Local $timer = TimerInit()
	While TimerDiff($timer) < 1200 And IsPlayerAlive()
		Local $me = GetMyAgent()
		Local $liveTarget = GetAgentByID(DllStructGetData($target, 'ID'))
		If $liveTarget == Null Or GetIsDead($liveTarget) Then Return False
		Local $myX = DllStructGetData($me, 'X')
		Local $myY = DllStructGetData($me, 'Y')
		Local $forwardX = $destinationX - $myX
		Local $forwardY = $destinationY - $myY
		Local $forwardLength = Sqrt($forwardX * $forwardX + $forwardY * $forwardY)
		If $forwardLength <= 0 Then Return False
		$forwardX /= $forwardLength
		$forwardY /= $forwardLength
		Local $targetProjection = (DllStructGetData($liveTarget, 'X') - $myX) * $forwardX + (DllStructGetData($liveTarget, 'Y') - $myY) * $forwardY
		If $targetProjection <= -150 Then Return True
		Move($myX + $forwardX * 225, $myY + $forwardY * 225)
		PingSleep(50)
	WEnd
	Return False
EndFunc


;~ BotsHub's generic timed helper can report success after a failed range cast.
;~ A jump counts only when its skill slot actually begins recharging.
Func CoFUseJumpConfirmed($skillSlot, $target, $stage)
	If Not IsRecharged($skillSlot) Or GetEnergy() < 5 Then Return False
	Local $me = GetMyAgent()
	Local $startX = DllStructGetData($me, 'X')
	Local $startY = DllStructGetData($me, 'Y')
	LogCoFTarget($stage & '-attempt', $target, $skillSlot)
	If Not UseSkillExNew($skillSlot, $target, 4000) Then
		LogCoFRouteStage($stage & '-not-activated')
		Return False
	EndIf
	If Not CoFWaitForJumpDisplacement($startX, $startY) Then
		LogCoFRouteStage($stage & '-no-displacement')
		Return False
	EndIf
	Local $settleMs = GetPing() + 50
	If $settleMs < 100 Then $settleMs = 100
	If $settleMs > 300 Then $settleMs = 300
	PingSleep($settleMs)
	LogCoFTarget($stage & '-activated', $target, $skillSlot)
	Return True
EndFunc


;~ Recharge begins before the jaunt position is visible; wait for displacement.
Func CoFWaitForJumpDisplacement($startX, $startY)
	Local $timer = TimerInit()
	While TimerDiff($timer) < 1000 And IsPlayerAlive()
		If GetDistanceToPoint(GetMyAgent(), $startX, $startY) >= 125 Then Return True
		PingSleep(25)
	WEnd
	Return False
EndFunc


;~ Find a living jump anchor behind and left of the current travel direction.
Func GetCoFBackLeftJumpTarget($destinationX, $destinationY, $excludedAgentID = 0)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $forwardX = $destinationX - $myX
	Local $forwardY = $destinationY - $myY
	Local $forwardLength = Sqrt($forwardX * $forwardX + $forwardY * $forwardY)
	If $forwardLength <= 0 Then Return Null
	$forwardX /= $forwardLength
	$forwardY /= $forwardLength
	Local $leftX = -$forwardY
	Local $leftY = $forwardX

	Local $bestTarget = Null
	Local $bestScore = 999999
	Local $foes = GetFoesInRangeOfAgent($me, $RANGE_SPELLCAST + 350)
	If Not IsArray($foes) Then Return Null
	For $foe In $foes
		If GetIsDead($foe) Or DllStructGetData($foe, 'HealthPercent') <= 0 Then ContinueLoop
		If DllStructGetData($foe, 'ID') == $excludedAgentID Then ContinueLoop
		Local $relativeX = DllStructGetData($foe, 'X') - $myX
		Local $relativeY = DllStructGetData($foe, 'Y') - $myY
		Local $forwardProjection = $relativeX * $forwardX + $relativeY * $forwardY
		Local $leftProjection = $relativeX * $leftX + $relativeY * $leftY
		If $forwardProjection > -150 Or $leftProjection < -100 Then ContinueLoop
		Local $distance = GetDistance($me, $foe)
		Local $score = $distance + $forwardProjection - ($leftProjection * 0.25)
		If $score < $bestScore Then
			$bestTarget = $foe
			$bestScore = $score
		EndIf
	Next
	Return $bestTarget
EndFunc


;~ Broader escape anchor used only after the preferred behind-left geometry has
;~ no candidate. Either rear side is useful when the player is boxed by foes.
Func GetCoFBehindJumpTarget($destinationX, $destinationY, $excludedAgentID = 0)
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $forwardX = $destinationX - $myX
	Local $forwardY = $destinationY - $myY
	Local $forwardLength = Sqrt($forwardX * $forwardX + $forwardY * $forwardY)
	If $forwardLength <= 0 Then Return Null
	$forwardX /= $forwardLength
	$forwardY /= $forwardLength

	Local $bestTarget = Null
	Local $bestScore = 999999
	Local $foes = GetFoesInRangeOfAgent($me, 850)
	If Not IsArray($foes) Then Return Null
	For $foe In $foes
		If GetIsDead($foe) Or DllStructGetData($foe, 'HealthPercent') <= 0 Then ContinueLoop
		If DllStructGetData($foe, 'ID') == $excludedAgentID Then ContinueLoop
		Local $relativeX = DllStructGetData($foe, 'X') - $myX
		Local $relativeY = DllStructGetData($foe, 'Y') - $myY
		Local $forwardProjection = $relativeX * $forwardX + $relativeY * $forwardY
		If $forwardProjection > -75 Then ContinueLoop
		Local $score = GetDistance($me, $foe) + ($forwardProjection * 0.5)
		If $score < $bestScore Then
			$bestTarget = $foe
			$bestScore = $score
		EndIf
	Next
	Return $bestTarget
EndFunc


;~ Escape a bodyblock with a directional jump, falling back to a wide diagonal.
Func CoFRecoverFromBodyBlock($destinationX, $destinationY, $stage)
	Local $target = GetCoFBackLeftJumpTarget($destinationX, $destinationY)
	If $target == Null Then $target = GetCoFBehindJumpTarget($destinationX, $destinationY)
	If $target <> Null Then
		If IsRecharged($COF_CHEST_VIPERS_DEFENSE) And GetEnergy() >= 5 Then
			If CoFUseJumpConfirmed($COF_CHEST_VIPERS_DEFENSE, $target, $stage & '-unblock-vipers') Then Return True
		EndIf
		If IsRecharged($COF_CHEST_HEART_OF_SHADOW) And GetEnergy() >= 5 Then
			If CoFUseJumpConfirmed($COF_CHEST_HEART_OF_SHADOW, $target, $stage & '-unblock-heart') Then Return True
		EndIf
	EndIf

	Local Static $sidestepLeft = False
	$sidestepLeft = Not $sidestepLeft
	Local $me = GetMyAgent()
	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	Local $directionX = $destinationX - $myX
	Local $directionY = $destinationY - $myY
	Local $directionLength = Sqrt($directionX * $directionX + $directionY * $directionY)
	If $directionLength <= 0 Then Return False
	Local $side = $sidestepLeft ? 1 : -1
	; A 350-unit pure sidestep was too small for the portal/terrain pocket. Step
	; diagonally backward and sideways first, then retry the forward destination.
	Move($myX - ($directionX / $directionLength) * 225 - ($directionY / $directionLength) * 550 * $side, _
		$myY - ($directionY / $directionLength) * 225 + ($directionX / $directionLength) * 550 * $side)
	PingSleep(400)
	Move($destinationX, $destinationY)
	Return False
EndFunc


;~ Search the recorded first spawn region from west to east and open one chest.
Func CoFSearchAndOpenZoneOne()
	Local $chest = FindCoFChestInRegion(-12500, -7500, -1500, 3000)
	If $chest <> Null And GetDistance(GetMyAgent(), $chest) > $RANGE_EARSHOT Then
		Local $chestX = DllStructGetData($chest, 'X')
		Local $chestY = DllStructGetData($chest, 'Y')
		If Not CoFTryForwardShadowStep($chestX, $chestY, 'post-hall-chest-forward') Then CoFTryForwardJump($chestX, $chestY, 'post-hall-chest-jump')
	EndIf
	If $chest == Null Then
		; Only teleport after confirming there is no currently visible hallway chest.
		If Not CoFTryForwardShadowStep(-10300, 700, 'post-hall-forward') Then CoFTryForwardJump(-11400, -450, 'post-hall-left-jump')
		$chest = FindCoFChestInRegion(-12500, -7500, -1500, 3000)
	EndIf
	If $chest == Null Then
		If CoFChestMove(-11400, -450, 'zone-one-west') == $FAIL Then Return False
		$chest = FindCoFChestInRegion(-12500, -7500, -1500, 3000)
	EndIf
	If $chest == Null Then
		If CoFChestMove(-10300, 700, 'zone-one-middle') == $FAIL Then Return False
		$chest = FindCoFChestInRegion(-12500, -7500, -1500, 3000)
	EndIf
	If $chest == Null Then
		If CoFChestMove(-9000, 1750, 'zone-one-east') == $FAIL Then Return False
		$chest = FindCoFChestInRegion(-12500, -7500, -1500, 3000)
	EndIf
	If $chest == Null Then
		If CoFChestMove(-7900, 2350, 'zone-one-end') == $FAIL Then Return False
		$chest = FindCoFChestInRegion(-12500, -7500, -1500, 3000)
	EndIf
	If $chest == Null Then Return False

	If CoFMoveToZoneOneChest($chest) == $FAIL Then Return False
	Return CoFOpenChestAgent($chest, 'zone-one-chest')
EndFunc


;~ Approach a first-region chest through the observed corridor geometry.
Func CoFMoveToZoneOneChest($chest)
	Local $x = DllStructGetData($chest, 'X')
	Local $y = DllStructGetData($chest, 'Y')
	; Do not walk away from a chest that is already safely reachable. The
	; branch waypoints below are only for navigating to distant spawn points.
	If GetDistance(GetMyAgent(), $chest) <= $RANGE_EARSHOT Then _
		Return CoFChestMove($x, $y, 'zone-one-chest-direct', $RANGE_EARSHOT)
	If $x < -11000 Then
		If CoFChestMove(-11600, -650, 'zone-one-chest-west') == $FAIL Then Return $FAIL
	ElseIf $x < -9000 Then
		If CoFChestMove(-10900, 0, 'zone-one-chest-middle') == $FAIL Then Return $FAIL
		; The first middle waypoint can pass directly beside western-middle
		; spawns. Stop routing as soon as the selected chest is reachable.
		If GetDistance(GetMyAgent(), $chest) <= $RANGE_EARSHOT Then _
			Return CoFChestMove($x, $y, 'zone-one-chest-direct', $RANGE_EARSHOT)
		If CoFChestMove(-10200, 750, 'zone-one-chest-middle-two') == $FAIL Then Return $FAIL
	Else
		If CoFChestMove(-10400, 800, 'zone-one-chest-east') == $FAIL Then Return $FAIL
		If GetDistance(GetMyAgent(), $chest) <= $RANGE_EARSHOT Then _
			Return CoFChestMove($x, $y, 'zone-one-chest-direct', $RANGE_EARSHOT)
		If CoFChestMove(-9200, 1600, 'zone-one-chest-east-two') == $FAIL Then Return $FAIL
	EndIf
	Return CoFChestMove($x, $y, 'zone-one-chest-approach', $RANGE_EARSHOT)
EndFunc


;~ Detect the second-region branch and open its single observed chest.
Func CoFSearchAndOpenZoneTwo()
	; A far eastern chest can already be visible from the end of region one.
	; Detect it before taking the northern detour, which would run backward.
	Local $chest = FindCoFChestInRegion(-11000, -5000, 2800, 6500, $RANGE_COMPASS)
	If $chest == Null Then
		; Stay left of the central Charr patrol while revealing the north.
		If CoFChestMove(-11000, 2100, 'zone-two-left-fork') == $FAIL Then Return False
		$chest = FindCoFChestInRegion(-11000, -5000, 2800, 6500, $RANGE_COMPASS)
	EndIf
	If $chest == Null Then
		; A movement timeout while still alive must not terminate chest coverage.
		; Run 12 was displaced east/north during this leg but could still have
		; revealed the visible eastern chest on the next recovery move.
		CoFChestMove(-10900, 3000, 'zone-two-left-search')
		$chest = FindCoFChestInRegion(-11000, -5000, 2800, 6500, $RANGE_COMPASS)
	EndIf
	If IsPlayerDead() Then Return False
	If $chest == Null Then
		; The far-right spawn can sit just outside compass range when zone one's
		; chest pulled the player west. Reveal the eastern half before resigning.
		CoFChestMove(-9000, 2650, 'zone-two-east-reveal')
		$chest = FindCoFChestInRegion(-11000, -5000, 2800, 6500, $RANGE_COMPASS)
	EndIf
	If IsPlayerDead() Then Return False
	If $chest == Null Then Return False

	LogCoFChest('zone-two-discovered', $chest)
	Local $x = DllStructGetData($chest, 'X')
	Local $y = DllStructGetData($chest, 'Y')
	CoFTryForwardShadowStep($x, $y, 'zone-two-forward')
	If $x > -7500 Then
		If DllStructGetData(GetMyAgent(), 'X') < -9000 Then
			If CoFChestMove(-9000, 2650, 'zone-two-east-one') == $FAIL Then Return False
		EndIf
		If DllStructGetData(GetMyAgent(), 'X') < -7800 Then
			If CoFChestMove(-7800, 2700, 'zone-two-east-two') == $FAIL Then Return False
		EndIf
		If DllStructGetData(GetMyAgent(), 'X') < -6600 Then
			If CoFChestMove(-6600, 3000, 'zone-two-east-three') == $FAIL Then Return False
		EndIf
	Else
		; Follow the in-game `CoF Chest Run Left Wall` capture. The earlier
		; guessed x=-11900 waypoint lies inside terrain; this recorded corridor
		; stays west of the patrol while remaining walkable.
		If DllStructGetData(GetMyAgent(), 'Y') < 4825 Then
			If CoFChestMove(-11188, 4829, 'zone-two-north-left-one') == $FAIL Then Return False
		EndIf
		If GetDistance(GetMyAgent(), $chest) <= $RANGE_EARSHOT Then _
			Return CoFOpenChestAgent($chest, 'zone-two-chest')
		If DllStructGetData(GetMyAgent(), 'Y') < 5350 Then
			If CoFChestMove(-10332, 5363, 'zone-two-north-left-two') == $FAIL Then Return False
		EndIf
		If GetDistance(GetMyAgent(), $chest) <= $RANGE_EARSHOT Then _
			Return CoFOpenChestAgent($chest, 'zone-two-chest')
		If DllStructGetData(GetMyAgent(), 'Y') < 5920 Then
			If CoFChestMove(-9494, 5924, 'zone-two-north-left-three') == $FAIL Then Return False
		EndIf
	EndIf
	If CoFChestMove($x, $y, 'zone-two-chest-approach', $RANGE_EARSHOT) == $FAIL Then Return False
	Return CoFOpenChestAgent($chest, 'zone-two-chest')
EndFunc


;~ Find the nearest unopened exact CoF chest inside a bounded route region.
Func FindCoFChestInRegion($minimumX, $maximumX, $minimumY, $maximumY, $maximumDistance = Null)
	Local $me = GetMyAgent()
	Local $nearestChest = Null
	Local $nearestDistance = 999999
	For $agent In GetAgentArray($ID_AGENT_TYPE_STATIC)
		If DllStructGetData($agent, 'GadgetID') <> $COF_CHEST_GADGET_ID Then ContinueLoop
		Local $agentID = DllStructGetData($agent, 'ID')
		If $chests_map[$agentID] == 2 Then ContinueLoop
		Local $x = DllStructGetData($agent, 'X')
		Local $y = DllStructGetData($agent, 'Y')
		If $x < $minimumX Or $x > $maximumX Or $y < $minimumY Or $y > $maximumY Then ContinueLoop
		Local $distance = GetDistance($me, $agent)
		If $maximumDistance <> Null And $distance > $maximumDistance Then ContinueLoop
		If $distance < $nearestDistance Then
			$nearestChest = $agent
			$nearestDistance = $distance
		EndIf
	Next
	Return $nearestChest
EndFunc


;~ Approach, target, open, and loot one explicitly selected nearby chest agent.
Func CoFOpenChestAgent($chest, $stage)
	If $chest == Null Or IsPlayerDead() Then Return False
	; A chest weapon needs a real bag slot. Do not spend the lockpick when an
	; exact desirable drop could not be stored.
	If CountSlots(1, $bags_count) < 1 Then
		$cof_chest_loot_blocked = True
		Error('No inventory slot available; leaving the chest unopened and pausing the run')
		LogCoFRouteStage($stage & '-inventory-full')
		Return False
	EndIf
	Local $chestID = DllStructGetData($chest, 'ID')
	Local $chestX = DllStructGetData($chest, 'X')
	Local $chestY = DllStructGetData($chest, 'Y')
	Local $itemsBefore = CoFSnapshotGroundItemIDs()
	LogCoFChest($stage, $chest)
	$cof_chest_unblock_x = DllStructGetData($chest, 'X')
	$cof_chest_unblock_y = DllStructGetData($chest, 'Y')
	GoToSignpostSafely($chest, CoFChestSurvivalForChest, CoFChestUnblock)
	If IsPlayerDead() Or GetDistance(GetMyAgent(), $chest) > 350 Then Return False

	; Low health is not a reason to skip a reached chest: opening it is the
	; route's objective. Confirm the native open command from title/lockpick
	; state so unattended runs never depend on Toolbox prompt automation.
	Local $treasureBefore = GetTreasureTitle()
	Local $lockpicksBefore = GetInventoryItemCount($ID_LOCKPICK)
	Local $opened = False
	For $attempt = 1 To 3
		Local $liveChest = GetAgentByID($chestID)
		If $liveChest == Null Then ExitLoop
		If GetDistance(GetMyAgent(), $liveChest) > 350 Then
			GoToSignpostSafely($liveChest, CoFChestSurvivalForChest, CoFChestUnblock)
			If IsPlayerDead() Or GetDistance(GetMyAgent(), $liveChest) > 350 Then ExitLoop
		EndIf
		ChangeTarget($liveChest)
		PingSleep(100)
		OpenChest()
		Local $confirmTimer = TimerInit()
		While TimerDiff($confirmTimer) < 2500
			If GetTreasureTitle() > $treasureBefore Or GetInventoryItemCount($ID_LOCKPICK) < $lockpicksBefore Then
				$opened = True
				ExitLoop
			EndIf
			If IsPlayerDead() Then ExitLoop
			PingSleep(50)
		WEnd
		If $opened Or IsPlayerDead() Then ExitLoop
		PingSleep(200)
	Next
	If Not $opened Then
		Warn('CoF chest open could not be confirmed after three attempts')
		LogCoFRouteStage($stage & '-open-unconfirmed')
		Return False
	EndIf
	$chests_map[$chestID] = 2
	Local $dropAgent = CoFWaitForNewChestDrop($itemsBefore, $chestX, $chestY, $stage)
	If $dropAgent == Null Then
		$cof_chest_loot_blocked = True
		Warn('Opened CoF chest, but its new drop was not observed; refusing to resign')
		LogCoFRouteStage($stage & '-drop-not-observed')
		Return False
	EndIf
	If Not CoFHandleExactChestDrop($dropAgent, $stage) Then Return False
	LogCoFRouteStage($stage & '-opened')
	Return True
EndFunc


;~ Snapshot preexisting item agents so an older drop can never be mistaken for
;~ the item produced by the chest currently being opened.
Func CoFSnapshotGroundItemIDs()
	Local $ids[0]
	For $agent In GetAgentArray($ID_AGENT_TYPE_ITEM)
		_ArrayAdd($ids, DllStructGetData($agent, 'ID'))
	Next
	Return $ids
EndFunc


Func CoFGroundItemIDWasPresent(ByRef $ids, $agentID)
	For $knownID In $ids
		If $knownID == $agentID Then Return True
	Next
	Return False
EndFunc


;~ Resolve the exact newly spawned item near the selected chest. Item agents
;~ commonly materialize after the title/lockpick open confirmation.
Func CoFWaitForNewChestDrop(ByRef $itemsBefore, $chestX, $chestY, $stage)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $COF_CHEST_DROP_APPEAR_TIMEOUT_MS And IsPlayerAlive()
		For $agent In GetAgentArray($ID_AGENT_TYPE_ITEM)
			Local $agentID = DllStructGetData($agent, 'ID')
			If $agentID == 0 Or CoFGroundItemIDWasPresent($itemsBefore, $agentID) Then ContinueLoop
			If GetDistanceToPoint($agent, $chestX, $chestY) > $COF_CHEST_DROP_RADIUS Then ContinueLoop
			Local $item = GetItemByAgentID($agentID)
			If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
			LogCoFLoot($stage & '-drop-observed', $agent, $item)
			Return $agent
		Next
		CoFChestSurvivalForChest()
		PingSleep(50)
	WEnd
	Return Null
EndFunc


;~ Apply the configured loot policy to one exact chest drop and prove pickup by
;~ disappearance of that same live agent before the route may continue.
Func CoFHandleExactChestDrop($dropAgent, $stage)
	Local $agentID = DllStructGetData($dropAgent, 'ID')
	Local $item = GetItemByAgentID($agentID)
	If DllStructGetData($item, 'ID') == 0 Then
		$cof_chest_loot_blocked = True
		LogCoFRouteStage($stage & '-drop-item-unresolved')
		Return False
	EndIf
	If Not DefaultShouldPickItem($item) Then
		LogCoFLoot($stage & '-loot-skipped-by-policy', $dropAgent, $item)
		Return True
	EndIf

	For $attempt = 1 To 3
		If Not GetAgentExists($agentID) Then
			$cof_chest_secured_loot_count += 1
			LogCoFRouteStage($stage & '-loot-secured')
			Return True
		EndIf
		Local $assignmentTimer = TimerInit()
		While GetAgentExists($agentID) And Not GetCanPickUp(GetAgentByID($agentID)) _
			And TimerDiff($assignmentTimer) < 1500 And IsPlayerAlive()
			CoFChestSurvivalForChest()
			PingSleep(50)
		WEnd
		If IsPlayerDead() Then ExitLoop
		If Not GetAgentExists($agentID) Then ContinueLoop
		$dropAgent = GetAgentByID($agentID)
		$item = GetItemByAgentID($agentID)
		If DllStructGetData($item, 'ID') == 0 Then ContinueLoop
		LogCoFLoot($stage & '-pickup-attempt-' & $attempt, $dropAgent, $item)
		CoFChestSurvivalForChest()
		PickUpItem($item)
		Local $pickupTimer = TimerInit()
		; Do not cast or move while the pickup is pending. A survival-skill command
		; can replace the queued interaction before the item disappears.
		While GetAgentExists($agentID) And TimerDiff($pickupTimer) < $COF_CHEST_EXACT_PICKUP_TIMEOUT_MS And IsPlayerAlive()
			PingSleep(50)
		WEnd
		If GetAgentExists($agentID) Then
			CancelAction()
			PingSleep(100)
		EndIf
	Next

	If Not GetAgentExists($agentID) Then
		$cof_chest_secured_loot_count += 1
		LogCoFRouteStage($stage & '-loot-secured')
		Return True
	EndIf
	$cof_chest_loot_blocked = True
	Warn('Desirable CoF chest loot remains after bounded retries; failing and resigning')
	LogCoFRouteStage($stage & '-loot-unsecured')
	Return False
EndFunc


;~ Maintain the run pair while walking to a chest or assigned loot.
Func CoFChestSurvivalForChest()
	CoFMaintainChestRunSkills()
EndFunc


;~ Record exact drop identity and position for post-run diagnosis.
Func LogCoFLoot($stage, $agent, $item)
	AppendCoFRouteDiagnostic('LOOT,' & $stage & ',' & DllStructGetData($agent, 'ID') & ',' _
		& DllStructGetData($item, 'ModelID') & ',' & Round(DllStructGetData($agent, 'X'), 0) & ',' _
		& Round(DllStructGetData($agent, 'Y'), 0) & ',' & GetRarity($item))
EndFunc


;~ Recover toward the selected chest if its approach becomes bodyblocked.
Func CoFChestUnblock()
	CoFRecoverFromBodyBlock($cof_chest_unblock_x, $cof_chest_unblock_y, 'chest-approach')
EndFunc


;~ Create a stable per-run diagnostic file for the next in-game validation.
Func InitializeCoFRouteDiagnostic()
	$cof_chest_diagnostic_capture_path = $COF_CHEST_DIAGNOSTIC_DIRECTORY & '\cof-route-' _
		& @YEAR & @MON & @MDAY & '-' & @HOUR & @MIN & @SEC & '-run-' & $chest_benchmark_run & '.csv'
	Local $file = FileOpen($COF_CHEST_DIAGNOSTIC_PATH, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	If $file == -1 Then Return
	FileWriteLine($file, 'kind,stage,id,model_or_skill,x,y,distance')
	FileClose($file)
	Local $captureFile = FileOpen($cof_chest_diagnostic_capture_path, $FO_OVERWRITE + $FO_CREATEPATH + $FO_UTF8)
	If $captureFile == -1 Then Return
	FileWriteLine($captureFile, 'kind,stage,id,model_or_skill,x,y,distance')
	FileClose($captureFile)
EndFunc


;~ Record the player's actual position at a named route stage.
Func LogCoFRouteStage($stage)
	Local $me = GetMyAgent()
	AppendCoFRouteDiagnostic('PLAYER,' & $stage & ',' & DllStructGetData($me, 'ID') & ',0,' _
		& Round(DllStructGetData($me, 'X'), 0) & ',' & Round(DllStructGetData($me, 'Y'), 0) & ',0')
EndFunc


;~ Record a selected target and the player skill slot used on it.
Func LogCoFTarget($stage, $target, $skillSlot)
	AppendCoFRouteDiagnostic('TARGET,' & $stage & ',' & DllStructGetData($target, 'ID') & ',' & DllStructGetData($target, 'ModelID') & ',' _
		& Round(DllStructGetData($target, 'X'), 0) & ',' & Round(DllStructGetData($target, 'Y'), 0) & ',' & $skillSlot)
EndFunc


;~ Record the selected chest's runtime ID and stable gadget ID.
Func LogCoFChest($stage, $chest)
	AppendCoFRouteDiagnostic('CHEST,' & $stage & ',' & DllStructGetData($chest, 'ID') & ',' & DllStructGetData($chest, 'GadgetID') & ',' _
		& Round(DllStructGetData($chest, 'X'), 0) & ',' & Round(DllStructGetData($chest, 'Y'), 0) & ',' & Round(GetDistance(GetMyAgent(), $chest), 0))
EndFunc


;~ Record a non-positional route action such as a hero skill.
Func LogCoFRouteAction($kind, $stage, $actorID, $skillID)
	Local $me = GetMyAgent()
	AppendCoFRouteDiagnostic($kind & ',' & $stage & ',' & $actorID & ',' & $skillID & ',' _
		& Round(DllStructGetData($me, 'X'), 0) & ',' & Round(DllStructGetData($me, 'Y'), 0) & ',0')
EndFunc


;~ Append one diagnostic line without affecting route control.
Func AppendCoFRouteDiagnostic($line)
	Local $file = FileOpen($COF_CHEST_DIAGNOSTIC_PATH, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	If $file == -1 Then Return
	FileWriteLine($file, $line)
	FileClose($file)
	If $cof_chest_diagnostic_capture_path == '' Then Return
	Local $captureFile = FileOpen($cof_chest_diagnostic_capture_path, $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)
	If $captureFile == -1 Then Return
	FileWriteLine($captureFile, $line)
	FileClose($captureFile)
EndFunc
