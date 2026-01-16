#CS ===========================================================================
#################################
#								#
#			Vaettir Bot			#
#								#
#################################
Author: gigi
Modified by: Pink Musen (v.01), Deroni93 (v.02-3), Dragonel (with help from moneyvsmoney), Night, Gahais
;
; Run this farm bot as Assassin or Mesmer or Monk or Elementalist
;
; Vaettir farms in Jaga Moraine based on below articles:
https://gwpvx.fandom.com/wiki/Build:A/Me_Vaettir_Farm
https://gwpvx.fandom.com/wiki/Build:Me/A_Vaettir_Farm
https://gwpvx.fandom.com/wiki/Build:Mo/A_55hp_Vaettir_Farmer
https://gwpvx.fandom.com/wiki/Build:E/Me_Obsidian_Flesh_Vaettir_Farmer
#CE ===========================================================================

#include-once
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $AME_VAETTIRS_FARMER_SKILLBAR = 'OwVU4lPL2hN8Id2BEBSANBLhbK'
Global Const $MEA_VAETTIRS_FARMER_SKILLBAR = 'OQdUAMhOsPP8Id2BEBSANBLhbK'
Global Const $MOA_VAETTIRS_FARMER_SKILLBAR = 'OwcU8UH6lPP8IdW9ABCRyi3D5B'
;Global Const $MOA_VAETTIRS_FARMER_SKILLBAR = 'OwcT44P7nhHpzOgIQISW8eIPA'
Global Const $EME_VAETTIRS_FARMER_SKILLBAR = 'OgVFwDKJL7Uk0n2wXlLoBgJwSwNF'

Global Const $VAETTIRS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- +4 Shadow Arts (+3 +1 headgear)' & @CRLF _
	& '- Armor with HP runes and 5 blessed/prodigy insignias (+50 armor when enchanted)' & @CRLF _
	& '- A shield with the inscription ''Like a rolling stone'' (+10 armor against earth damage) and +45 health while enchanted' & @CRLF _
	& '- In case of Monk 55hp, use grim cesta -50hp and armor with 5*-75hp runes' & @CRLF _
	& '- In case of Obsidian Flesh Elementalist, recommended to have armor full with geomancer runes' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- Cupcakes' & @CRLF _
	& 'Recommended to have maxed out Norn title. If not maxed out then this farm is good for raising Norn rank' & @CRLF _
	& 'Vaettir farm can be a good way to max out survivor title' & @CRLF _
	& 'You can run this farm as Assassin or Mesmer or Monk or Elementalist. Bot will set up build automatically for these professions' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/Me_Vaettir_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Me/A_Vaettir_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Mo/A_55hp_Vaettir_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:E/Me_Obsidian_Flesh_Vaettir_Farmer'
; Average duration ~ 3m40 ~ First run is 6m30s with setup and run
Global Const $VAETTIRS_FARM_DURATION = 4 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($VAETTIR_SHADOWFORM) is better than UseSkillEx(2))
Global Const $VAETTIR_DEADLY_PARADOX			= 1
Global Const $VAETTIR_SHADOWFORM				= 2
Global Const $VAETTIR_SHROUD_OF_DISTRESS		= 3
Global Const $VAETTIR_HEART_OF_SHADOW			= 4
Global Const $VAETTIR_WAY_OF_PERFECTION			= 5
Global Const $VAETTIR_CHANNELING				= 6
Global Const $VAETTIR_ARCANE_ECHO				= 7
Global Const $VAETTIR_WASTRELS_DEMISE			= 8

Global Const $VAETTIR_MONK_PROTECTIVE_SPIRIT	= 3
Global Const $VAETTIR_MONK_BALTHAZARS_AURA		= 5
Global Const $VAETTIR_MONK_KIRINS_WRATH			= 6
Global Const $VAETTIR_MONK_SYMBOL_OF_WRATH		= 7
Global Const $VAETTIR_MONK_BALTHAZARS_SPIRIT	= 8

Global Const $VAETTIR_ELEMENTALIST_GLYPH_OF_SWIFTNESS	= 1
Global Const $VAETTIR_ELEMENTALIST_OBSIDIAN_FLESH		= 2
Global Const $VAETTIR_ELEMENTALIST_STONEFLESH_AURA		= 3
Global Const $VAETTIR_ELEMENTALIST_ELEMENTAL_LORD		= 4
Global Const $VAETTIR_ELEMENTALIST_MANTRA_OF_EARTH		= 5

; ==== Global variables ====
Global $vaettirs_move_options = CloneDictMap($default_movedefend_options)
$vaettirs_move_options.Item('defendFunction')				= VaettirsStayAlive
$vaettirs_move_options.Item('moveTimeOut')					= 100 * 1000
$vaettirs_move_options.Item('randomFactor')					= 50
$vaettirs_move_options.Item('hosSkillSlot')					= $VAETTIR_HEART_OF_SHADOW
$vaettirs_move_options.Item('deathChargeSkillSlot')			= 0
$vaettirs_move_options.Item('openChests')					= False

Global $vaettirs_move_options_elementalist = CloneDictMap($vaettirs_move_options)
$vaettirs_move_options_elementalist.Item('hosSkillSlot')	= 0

Global $vaettirs_farm_setup = False
Global $vaettirs_player_profession = $ID_ASSASSIN
Global $vaettirs_deadlocked = False
Global $vaettir_shadowform_timer = TimerInit()
Global $vaettir_shroud_of_distress_timer = TimerInit()
Global $vaettir_channeling_timer = TimerInit()
Global $vaettir_glyph_of_swiftness_timer = TimerInit()
Global $vaettir_obsidian_flesh_timer = TimerInit()
Global $vaettir_stoneflesh_aura_timer = TimerInit()
Global $vaettir_mantra_of_earth_timer = TimerInit()
Global $vaettir_protective_spirit_timer = TimerInit()

;~ Main method to farm Vaettirs
Func VaettirsFarm()
	If Not $vaettirs_farm_setup And SetupVaettirsFarm() == $FAIL Then Return $PAUSE
	Return VaettirsFarmLoop()
EndFunc


Func SetupVaettirsFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_LONGEYES_LEDGE, $district_name) == $FAIL Then Return $FAIL
	If SetupPlayerVaettirsFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	SwitchMode($ID_HARD_MODE)
	While $vaettirs_deadlocked Or GetMapID() <> $ID_JAGA_MORAINE
		$vaettirs_deadlocked = False
		If RunToJagaMoraine() == $FAIL Then ContinueLoop
		$vaettirs_farm_setup = True
	WEnd
	RandomSleep(1000)
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerVaettirsFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_ASSASSIN
			$vaettirs_player_profession = $ID_ASSASSIN
			LoadSkillTemplate($AME_VAETTIRS_FARMER_SKILLBAR)
		Case $ID_MESMER
			$vaettirs_player_profession = $ID_MESMER
			LoadSkillTemplate($MEA_VAETTIRS_FARMER_SKILLBAR)
		Case $ID_MONK
			$vaettirs_player_profession = $ID_MONK
			LoadSkillTemplate($MOA_VAETTIRS_FARMER_SKILLBAR)
		Case $ID_ELEMENTALIST
			$vaettirs_player_profession = $ID_ELEMENTALIST
			LoadSkillTemplate($EME_VAETTIRS_FARMER_SKILLBAR)
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Monk or Elementalist')
			Return $FAIL
	EndSwitch
	RandomSleep(250)
	; giving more health to monk 55hp from norn title effect would screw up farm, therefore hiding displayed title for monk
	If $vaettirs_player_profession == $ID_MONK Then
		SetDisplayedTitle(0)
	Else
		SetDisplayedTitle($ID_NORN_TITLE)
	EndIf
	RandomSleep(500)
	Return $SUCCESS
EndFunc


;~ Zones to Longeye if we are not there, and travel to Jaga Moraine
Func RunToJagaMoraine()
	TravelToOutpost($ID_LONGEYES_LEDGE, $district_name)

	Info('Exiting Outpost')
	MoveTo(-26000, 16000)
	Move(-26472, 16217)
	RandomSleep(1000)
	WaitMapLoading($ID_BJORA_MARCHES)

	RandomSleep(500)
	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	RandomSleep(500)

	Info('Running to Jaga Moraine')
	Local $pathToJaga[30][2] = [ _
		[15003.8,	-16598.1], _
		[15003.8,	-16598.1], _
		[12699.5,	-14589.8], _
		[11628,		-13867.9], _
		[10891.5,	-12989.5], _
		[10517.5,	-11229.5], _
		[10209.1,	-9973.1], _
		[9296.5,	-8811.5], _
		[7815.6,	-7967.1], _
		[6266.7,	-6328.5], _
		[4940,		-4655.4], _
		[3867.8,	-2397.6], _
		[2279.6,	-1331.9], _
		[7.2,		-1072.6], _
		[7.2,		-1072.6], _
		[-1752.7,	-1209], _
		[-3596.9,	-1671.8], _
		[-5386.6,	-1526.4], _
		[-6904.2,	-283.2], _
		[-7711.6,	364.9], _
		[-9537.8,	1265.4], _
		[-11141.2,	857.4], _
		[-12730.7,	371.5], _
		[-13379,	40.5], _
		[-14925.7,	1099.6], _
		[-16183.3,	2753], _
		[-17803.8,	4439.4], _
		[-18852.2,	5290.9], _
		[-19250,	5431], _
		[-19968,	5564] _
	]
	For $i = 0 To UBound($pathToJaga) - 1
		If RunAcrossBjoraMarches($pathToJaga[$i][0], $pathToJaga[$i][1]) == $FAIL Then Return $FAIL
	Next
	Move(-20076, 5580, 30)
	WaitMapLoading($ID_JAGA_MORAINE)
	Return GetMapID() == $ID_JAGA_MORAINE ? $SUCCESS : $FAIL
EndFunc


;~ Move to X, Y. This is to be used in the run from across Bjora Marches
Func RunAcrossBjoraMarches($X, $Y)
	Move($X, $Y)

	Local $target
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $X, $Y) > $RANGE_NEARBY
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestEnemyToAgent($me)

		If GetDistance($me, $target) < 1300 And GetEnergy() > 20 Then VaettirsCheckBuffs()

		If $vaettirs_player_profession <> $ID_ELEMENTALIST Then
			$me = GetMyAgent()
			If DllStructGetData($me, 'HealthPercent') < 0.9 And GetEnergy() > 10 Then VaettirsCheckShroudOfDistress()
			If DllStructGetData($me, 'HealthPercent') < 0.5 And GetDistance($me, $target) < 500 And GetEnergy() > 5 And IsRecharged($VAETTIR_HEART_OF_SHADOW) Then UseSkillEx($VAETTIR_HEART_OF_SHADOW, $target)
		EndIf

		$me = GetMyAgent()
		If Not IsPlayerMoving() Then Move($X, $Y)
		RandomSleep(500)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


;~ Farm loop
Func VaettirsFarmLoop()
	; In case character died at previous loop
	While IsPlayerDead()
		Sleep(2500)
	WEnd
	If $vaettirs_player_profession == $ID_MONK Then UseSkillEx($VAETTIR_MONK_BALTHAZARS_SPIRIT, GetMyAgent())
	If $vaettirs_player_profession == $ID_ELEMENTALIST Then UseSkillEx($VAETTIR_ELEMENTALIST_ELEMENTAL_LORD)
	RandomSleep(500)
	GetVaettirsNornBlessing()
	If AggroAllMobs() == $FAIL Then Return $FAIL
	If VaettirsKillSequence() == $FAIL Then Return $FAIL
	Sleep(1000)

	If IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(VaettirsStayAlive)
			RandomSleep(50)
		Next
	EndIf

	Return RezoneToJagaMoraine()
EndFunc


;~ Get Norn blessing only if title is not maxed yet. Assuming that Norn has been already defeated
Func GetVaettirsNornBlessing()
	Local $nornTitlePoints = GetNornTitle()
	If $nornTitlePoints < 160000 Then
		Info('Getting norn title blessing')
		GoNearestNPCToCoords(13400, -20800)
		RandomSleep(500)
		Dialog(0x84)
	EndIf
	RandomSleep(350)
EndFunc


;~ Self explanatory
Func AggroAllMobs()
	Local $target
	; Vaettirs locations
	Local Static $vaettirs[30][2] = [ _
		_ ; left ball
		[12496,	-22600], _
		[11375,	-22761], _
		[10925,	-23466], _
		[10917,	-24311], _
		[9910,	-24599], _
		[8995,	-23177], _
		[8307,	-23187], _
		[8213,	-22829], _
		[8307,	-23187], _
		[8213,	-22829], _
		[8740,	-22475], _
		[8880,	-21384], _
		[8684,	-20833], _
		[8982,	-20576], _
		_ ; right ball
		[10196,	-20124], _
		[9976,	-18338], _
		[11316,	-18056], _
		[10392,	-17512], _
		[10114,	-16948], _
		[10729,	-16273], _
		[10810,	-15058], _
		[11120,	-15105], _
		[11670,	-15457], _
		[12604,	-15320], _
		[12476,	-16157], _
		_ ; moving to spot
		[12920,	-17032], _
		[12847,	-17136], _
		[12720,	-17222], _
		[12617,	-17273], _
		[12518,	-17305] _
	]

	Info('Aggroing left')
	MoveTo(13172, -22137)
	For $i = 0 To 13
		If VaettirsMoveDefending($vaettirs[$i][0], $vaettirs[$i][1]) == $FAIL Then Return $FAIL
	Next

	Info('Waiting for left ball')
	VaettirsSleepAndStayAlive(12000)
	If $vaettirs_player_profession <> $ID_ELEMENTALIST Then
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
			UseSkillEx($VAETTIR_HEART_OF_SHADOW, $target)
		Else
			UseSkillEx($VAETTIR_HEART_OF_SHADOW, GetMyAgent())
		EndIf
	EndIf
	VaettirsSleepAndStayAlive(6000)

	Info('Aggroing right')
	For $i = 14 To 24
		If VaettirsMoveDefending($vaettirs[$i][0], $vaettirs[$i][1]) == $FAIL Then Return $FAIL
	Next

	Info('Waiting for right ball')
	VaettirsSleepAndStayAlive(15000)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If $vaettirs_player_profession <> $ID_ELEMENTALIST Then
		If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
			UseSkillEx($VAETTIR_HEART_OF_SHADOW, $target)
		Else
			UseSkillEx($VAETTIR_HEART_OF_SHADOW, GetMyAgent())
		EndIf
	EndIf
	VaettirsSleepAndStayAlive(5000)
	For $i = 25 To 29
		If VaettirsMoveDefending($vaettirs[$i][0], $vaettirs[$i][1]) == $FAIL Then Return $FAIL
	Next

	; [12445,	-17327]
	; Final spot needs to be precise to avoid losing aggro (we need a right wall block)
	MoveTo(12480, -17336, 0)

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func VaettirsMoveDefending($destinationX, $destinationY)
	Local $result = Null
	Switch $vaettirs_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_MONK
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $vaettirs_move_options)
		Case $ID_ELEMENTALIST
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $vaettirs_move_options_elementalist)
	EndSwitch
	If $result == $STUCK Then
		; When playing as Elementalist or other professions that don't have death's charge or heart of shadow skills, then fight Vaettirs wherever player got surrounded and stuck
		VaettirsKillSequence()
		If IsPlayerDead() Then Return $FAIL
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(VaettirsStayAlive)
			RandomSleep(50)
		Next
		Return $SUCCESS
	Else
		Return $result
	EndIf
EndFunc


;~ Wait while staying alive at the same time (like Sleep(..), but without the dying part)
Func VaettirsSleepAndStayAlive($waitingTime)
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitingTime And IsPlayerAlive()
		RandomSleep(100)
		VaettirsStayAlive()
	WEnd
EndFunc


;~ Use whatever skills you need to keep yourself alive.
Func VaettirsStayAlive()
	Local $adjacentCount, $areaCount, $foesSpellRange = False, $foesNear = False
	Local $distance
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), 1400)
	For $foe In $foes
		$distance = GetDistance($me, $foe)
		If $distance < 1400 Then
			$foesNear = True
			If $distance < $RANGE_SPELLCAST Then
				$foesSpellRange = True
				If $distance < $RANGE_AREA Then
					$areaCount += 1
					If $distance < $RANGE_ADJACENT Then
						$adjacentCount += 1
					EndIf
				EndIf
			EndIf
		EndIf
	Next

	If $foesNear Then VaettirsCheckBuffs()
	If ($vaettirs_player_profession == $ID_ASSASSIN Or $vaettirs_player_profession == $ID_MESMER) And _
		($adjacentCount > 20 Or DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.6 Or _
		($foesSpellRange And GetEffect($ID_SHROUD_OF_DISTRESS) == Null)) Then VaettirsCheckShroudOfDistress()
	If $foesNear Then VaettirsCheckBuffs()
	If $areaCount > 5 And $vaettirs_player_profession <> $ID_MONK Then VaettirsCheckChanneling()
	If $foesNear Then VaettirsCheckBuffs()
EndFunc


;~ Uses Shadow Form or other buffs like Obsidian Flesh or Protective Spirit if these are recharged
Func VaettirsCheckBuffs()
	Switch $vaettirs_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_MONK
			VaettirsCheckShadowForm()
		Case $ID_ELEMENTALIST
			VaettirsCheckObsidianFlesh()
	EndSwitch
EndFunc


;~ Uses Shadow Form if its recharged
Func VaettirsCheckShadowForm()
	; Caution, if playing monk 55hp then protective spirit has to be already on player when casting shadow form, otherwise damage reduction to 0 won't be applied due to specific guild wars mechanics
	; Furthermore, due to specific guild wars mechanics casting protective spirit multiple times can remove damage reduction to 0 so protective spirit has to casted only once just before Shadow Form, otherwise player will die very fast
	If ($vaettirs_player_profession <> $ID_MONK And TimerDiff($vaettir_shadowform_timer) > 19000 And GetEnergy() > 20) Or _
		($vaettirs_player_profession == $ID_MONK And TimerDiff($vaettir_shadowform_timer) > 19500 And GetEnergy() > 30) Then
		If $vaettirs_player_profession == $ID_MONK Then UseSkillEx($VAETTIR_MONK_PROTECTIVE_SPIRIT)
		UseSkillEx($VAETTIR_DEADLY_PARADOX)
		While IsPlayerAlive() And Not IsRecharged($VAETTIR_SHADOWFORM)
			Sleep(50)
		WEnd
		UseSkillEx($VAETTIR_SHADOWFORM)
		If $vaettirs_player_profession <> $ID_MONK Then
			While IsPlayerAlive() And Not IsRecharged($VAETTIR_WAY_OF_PERFECTION)
				Sleep(50)
			WEnd
			UseSkillEx($VAETTIR_WAY_OF_PERFECTION)
		EndIf
		$vaettir_shadowform_timer = TimerInit()
	EndIf
EndFunc


;~ Maintaining Obsidian Flesh, Stoneflesh Aura, Elemental Lord, Mantra of Earth and Channeling
Func VaettirsCheckObsidianFlesh()
	If IsRecharged($VAETTIR_ELEMENTALIST_ELEMENTAL_LORD) And Not IsRecharged($VAETTIR_ELEMENTALIST_OBSIDIAN_FLESH) And Not IsRecharged($VAETTIR_ELEMENTALIST_STONEFLESH_AURA) Then UseSkillEx($VAETTIR_ELEMENTALIST_ELEMENTAL_LORD)
	If TimerDiff($vaettir_obsidian_flesh_timer) > 21000 And GetEnergy() > 30 Then
		UseSkillEx($VAETTIR_ELEMENTALIST_GLYPH_OF_SWIFTNESS)
		While IsPlayerAlive() And Not IsRecharged($VAETTIR_ELEMENTALIST_OBSIDIAN_FLESH)
			Sleep(50)
		WEnd
		UseSkillEx($VAETTIR_ELEMENTALIST_OBSIDIAN_FLESH)
		$vaettir_obsidian_flesh_timer = TimerInit()
	EndIf
	If IsRecharged($VAETTIR_ELEMENTALIST_STONEFLESH_AURA) And GetEnergy() > 15 Then UseSkillEx($VAETTIR_ELEMENTALIST_STONEFLESH_AURA)
	; only cast energy accumulating skills when farming Vaettirs in jaga Moraine, not during run across Bjora Marches
	If GetMapID() == $ID_JAGA_MORAINE Then
		If TimerDiff($vaettir_channeling_timer) > 20000 And TimerDiff($vaettir_obsidian_flesh_timer) < 19000 And Not IsRecharged($VAETTIR_ELEMENTALIST_STONEFLESH_AURA) And GetEnergy() > 5 Then
			UseSkillEx($VAETTIR_CHANNELING)
			$vaettir_channeling_timer = TimerInit()
		EndIf
		If TimerDiff($vaettir_mantra_of_earth_timer) > 40000 And TimerDiff($vaettir_obsidian_flesh_timer) < 19000 And GetEnergy() > 10 Then
			UseSkillEx($VAETTIR_ELEMENTALIST_MANTRA_OF_EARTH)
			$vaettir_mantra_of_earth_timer = TimerInit()
		EndIf
	EndIf
EndFunc


;~ Uses Shroud of distress if its recharged
Func VaettirsCheckShroudOfDistress()
	If TimerDiff($vaettir_shroud_of_distress_timer) > 50000 And TimerDiff($vaettir_shadowform_timer) < 18000 And GetEnergy() > 10 Then
		UseSkillEx($VAETTIR_SHROUD_OF_DISTRESS)
		$vaettir_shroud_of_distress_timer = TimerInit()
	EndIf
EndFunc


;~ Uses Channeling if its recharged
Func VaettirsCheckChanneling()
	If TimerDiff($vaettir_channeling_timer) > 22000 And _
		(($vaettirs_player_profession <> $ID_ELEMENTALIST And TimerDiff($vaettir_shadowform_timer) < 19000) Or _
		($vaettirs_player_profession == $ID_ELEMENTALIST And TimerDiff($vaettir_obsidian_flesh_timer) < 19000)) Then
		UseSkillEx($VAETTIR_CHANNELING)
		$vaettir_channeling_timer = TimerInit()
	EndIf
EndFunc


;~ Returns a good target for wastrels
Func GetWastrelsTarget()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	For $foe In $foes
		If GetHasHex($foe) Then ContinueLoop
		If Not GetIsEnchanted($foe) Then ContinueLoop
		Return $foe
	Next
	Return Null
EndFunc


;~ Kill a mob group
Func VaettirsKillSequence()
	; Wait for shadow form or other buffs to have been casted very recently
	While (($vaettirs_player_profession <> $ID_ELEMENTALIST And TimerDiff($vaettir_shadowform_timer) > 5000) Or _
			($vaettirs_player_profession == $ID_ELEMENTALIST And TimerDiff($vaettir_obsidian_flesh_timer) > 5000)) And _
		CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA) > 0
			Sleep(100)
			VaettirsStayAlive()
			If IsPlayerDead() Then Return $FAIL
	WEnd

	Info('Killing Vaettirs')
	Switch $vaettirs_player_profession
		Case $ID_ASSASSIN, $ID_MESMER, $ID_ELEMENTALIST
			KillVaettirsUsingWastrelSkills()
		Case $ID_MONK
			KillVaettirsUsingSmitingSkills()
	EndSwitch
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KillVaettirsUsingWastrelSkills()
	Local Static $MaxKillTime = 100000
	Local $deadlock = TimerInit()
	Local $target
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	If $foesCount > 0 Then
		; Echo the Wastrel's Demise
		UseSkillEx($VAETTIR_ARCANE_ECHO)
		$target = GetWastrelsTarget()
		UseSkillEx($VAETTIR_WASTRELS_DEMISE, $target)
		While $foesCount > 0 And TimerDiff($deadlock) < $MaxKillTime And IsPlayerAlive()
			VaettirsStayAlive()

			; Use echoed wastrel if possible
			If IsRecharged($VAETTIR_ARCANE_ECHO) And GetSkillbarSkillID($VAETTIR_ARCANE_ECHO) == $ID_WASTRELS_DEMISE Then
				$target = GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($VAETTIR_ARCANE_ECHO, $target)
			EndIf

			; Use wastrel's demise if possible
			If IsRecharged($VAETTIR_WASTRELS_DEMISE) Then
				$target = GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($VAETTIR_WASTRELS_DEMISE, $target)
			EndIf

			RandomSleep(100)
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		WEnd
	EndIf
EndFunc


Func KillVaettirsUsingSmitingSkills()
	Local Static $MaxKillTime = 120000
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	While $foesCount > 0 And TimerDiff($deadlock) < $MaxKillTime And IsPlayerAlive()
		VaettirsStayAlive()

		If TimerDiff($vaettir_shadowform_timer) < 16000 And IsRecharged($VAETTIR_MONK_BALTHAZARS_AURA) And GetEnergy() > 25 Then
			UseSkillEx($VAETTIR_MONK_BALTHAZARS_AURA)
		EndIf

		If TimerDiff($vaettir_shadowform_timer) < 16000 And IsRecharged($VAETTIR_MONK_KIRINS_WRATH) And GetEnergy() > 5 Then
			UseSkillEx($VAETTIR_MONK_KIRINS_WRATH)
		EndIf

		If TimerDiff($vaettir_shadowform_timer) < 16000 And IsRecharged($VAETTIR_MONK_SYMBOL_OF_WRATH) And GetEnergy() > 5 Then
			UseSkillEx($VAETTIR_MONK_SYMBOL_OF_WRATH)
		EndIf

		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	WEnd
EndFunc


;~ Exit Jaga Moraine to Bjora Marches and get back into Jaga Moraine
Func RezoneToJagaMoraine()
	Local $result = $SUCCESS

	Info('Zoning out and back in')
	VaettirsMoveDefending(12289, -17700)
	VaettirsMoveDefending(15318, -20351)

	Local $deadlockTimer = TimerInit()
	While IsPlayerDead()
		Info('Waiting for resurrection')
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$vaettirs_deadlocked = True
			Return $FAIL
		EndIf
	WEnd
	MoveTo(15600, -20500)
	Move(15865, -20531)
	WaitMapLoading($ID_BJORA_MARCHES)
	MoveTo(-19968, 5564)
	Move(-20076, 5580, 30)
	WaitMapLoading($ID_JAGA_MORAINE)
	RandomSleep(1000)
	Return $result
EndFunc