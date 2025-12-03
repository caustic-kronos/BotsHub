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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $AMeVaettirsFarmerSkillbar = 'OwVU4lPL2hN8Id2BEBSANBLhbK'
Global Const $MeAVaettirsFarmerSkillbar = 'OQdUAMhOsPP8Id2BEBSANBLhbK'
Global Const $MoAVaettirsFarmerSkillbar = 'OwcU8UH6lPP8IdW9ABCRyi3D5B'
;Global Const $MoAVaettirsFarmerSkillbar = 'OwcT44P7nhHpzOgIQISW8eIPA'
Global Const $EMeVaettirsFarmerSkillbar = 'OgVFwDKJL7Uk0n2wXlLoBgJwSwNF'

Global Const $VaettirsFarmInformations = 'For best results, have :' & @CRLF _
	& '- +4 Shadow Arts (+3+1 headgear)' & @CRLF _
	& '- Armor with HP runes and 5 blessed insignias (+50 armor when enchanted)' & @CRLF _
	& '- A shield with the inscription ''Like a rolling stone'' (+10 armor against earth damage) and +45 health while enchanted' & @CRLF _
	& '- In case of Monk 55hp, recommended to use grim cesta -50hp and armor with 5*-75hp runes' & @CRLF _
	& '- In case of Obsidian Flesh Elementalist, recommended to have armor full with geomancer runes' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- Cupcakes' & @CRLF _
	& 'Recommended to have maxed out Norn title. If not maxed out then this farm is good for raising Norn rank' & @CRLF _
	& 'Vaettir farm can be a good way to max out survivor title' & @CRLF _
	& 'Can switch to normal mode in case of low success rate but hard mode has better loots' & @CRLF _
	& 'You can run this farm as Assassin or Mesmer or Monk or Elementalist. Bot will set up build automatically for these professions' & @CRLF _
	& 'This farm bot is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:A/Me_Vaettir_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Me/A_Vaettir_Farm' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Mo/A_55hp_Vaettir_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:E/Me_Obsidian_Flesh_Vaettir_Farmer'
; Average duration ~ 3m40 ~ First run is 6m30s with setup and run
Global Const $VAETTIRS_FARM_DURATION = 4 * 60 * 1000
Global $VAETTIRS_FARM_SETUP = False

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Vaettir_ShadowForm) is better than UseSkillEx(2))
Global Const $Vaettir_DeadlyParadox		= 1
Global Const $Vaettir_ShadowForm		= 2
Global Const $Vaettir_ShroudOfDistress	= 3
Global Const $Vaettir_HeartOfShadow		= 4
Global Const $Vaettir_WayOfPerfection	= 5
Global Const $Vaettir_Channeling		= 6
Global Const $Vaettir_ArcaneEcho		= 7
Global Const $Vaettir_WastrelsDemise	= 8

Global Const $Vaettir_Monk_ProtectiveSpirit	= 3
Global Const $Vaettir_Monk_BalthazarsAura	= 5
Global Const $Vaettir_Monk_KirinsWrath		= 6
Global Const $Vaettir_Monk_SymbolOfWrath	= 7
Global Const $Vaettir_Monk_BalthazarsSpirit	= 8

Global Const $Vaettir_Elementalist_GlyphOfSwiftness	= 1
Global Const $Vaettir_Elementalist_ObsidianFlesh	= 2
Global Const $Vaettir_Elementalist_StonefleshAura	= 3
Global Const $Vaettir_Elementalist_ElementalLord	= 4
Global Const $Vaettir_Elementalist_MantraOfEarth	= 5

; ==== Global variables ====
Global $VaettirsPlayerProfession = $ID_Assassin ; global variable to remember player's profession in setup to avoid creating Dll structs over and over
Global $Deadlocked = False
Global $VaettirShadowFormTimer = TimerInit()
Global $VaettirShroudOfDistressTimer = TimerInit()
Global $VaettirChannelingTimer = TimerInit()
Global $VaettirGlyphOfSwiftnessTimer = TimerInit()
Global $VaettirObsidianFleshTimer = TimerInit()
Global $VaettirStonefleshAuraTimer = TimerInit()
Global $VaettirMantraOfEarthTimer = TimerInit()
Global $VaettirProtectiveSpiritTimer = TimerInit()

Global $VaettirsMoveOptions = CloneDictMap($Default_MoveDefend_Options)
$VaettirsMoveOptions.Item('defendFunction')			= VaettirsStayAlive
$VaettirsMoveOptions.Item('moveTimeOut')			= 100 * 1000 ; 100 seconds max for being stuck
$VaettirsMoveOptions.Item('randomFactor')			= 50
$VaettirsMoveOptions.Item('hosSkillSlot')			= $Vaettir_HeartOfShadow
$VaettirsMoveOptions.Item('deathChargeSkillSlot')	= 0
$VaettirsMoveOptions.Item('openChests')				= False
Global $VaettirsMoveOptionsElementalist = CloneDictMap($VaettirsMoveOptions)
$VaettirsMoveOptionsElementalist.Item('hosSkillSlot') = 0


;~ Main method to farm Vaettirs
Func VaettirsFarm($STATUS)
	While $Deadlocked Or GetMapID() <> $ID_Jaga_Moraine
		If Not $VAETTIRS_FARM_SETUP Then SetupVaettirsFarm()
		$Deadlocked = False
		RunToJagaMoraine()
	WEnd

	If $STATUS <> 'RUNNING' Then Return $PAUSE
	Return VaettirsFarmLoop()
EndFunc


Func SetupVaettirsFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Longeyes_Ledge Then TravelToOutpost($ID_Longeyes_Ledge, $DISTRICT_NAME)
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerVaettirsFarm() == $FAIL Then Return $FAIL
	LeaveParty() ; solo farmer
	$VAETTIRS_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerVaettirsFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_Assassin
			$VaettirsPlayerProfession = $ID_Assassin
			LoadSkillTemplate($AMeVaettirsFarmerSkillbar)
		Case $ID_Mesmer
			$VaettirsPlayerProfession = $ID_Mesmer
			LoadSkillTemplate($MeAVaettirsFarmerSkillbar)
		Case $ID_Monk
			$VaettirsPlayerProfession = $ID_Monk
			LoadSkillTemplate($MoAVaettirsFarmerSkillbar)
		Case $ID_Elementalist
			$VaettirsPlayerProfession = $ID_Elementalist
			LoadSkillTemplate($EMeVaettirsFarmerSkillbar)
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Monk or Elementalist')
			Return $FAIL
	EndSwitch
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	; giving more health to monk 55hp from norn title effect would screw up farm, therefore hiding displayed title for monk
	If $VaettirsPlayerProfession <> $ID_Monk Then SetDisplayedTitle($ID_Norn_Title)
	If $VaettirsPlayerProfession == $ID_Monk Then SetDisplayedTitle(0)
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


;~ Zones to Longeye if we are not there, and travel to Jaga Moraine
Func RunToJagaMoraine()
	If GetMapID() <> $ID_Longeyes_Ledge Then TravelToOutpost($ID_Longeyes_Ledge, $DISTRICT_NAME)

	Info('Exiting Outpost')
	MoveTo(-26000, 16000)
	Move(-26472, 16217)
	RandomSleep(1000)
	WaitMapLoading($ID_Bjora_Marches)

	RandomSleep(500)
	UseConsumable($ID_Birthday_Cupcake)
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
	WaitMapLoading($ID_Jaga_Moraine)
	Return GetMapID() == $ID_Jaga_Moraine ? $SUCCESS : $FAIL
EndFunc


;~ Move to X, Y. This is to be used in the run from across Bjora Marches
Func RunAcrossBjoraMarches($X, $Y)
	If IsPlayerDead() Then Return $FAIL

	Move($X, $Y)

	Local $target
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $X, $Y) > $RANGE_NEARBY
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestEnemyToAgent($me)

		If GetDistance($me, $target) < 1300 And GetEnergy() > 20 Then VaettirsCheckBuffs()

		If $VaettirsPlayerProfession <> $ID_Elementalist Then
			$me = GetMyAgent()
			If DllStructGetData($me, 'HealthPercent') < 0.9 And GetEnergy() > 10 Then VaettirsCheckShroudOfDistress()
			If DllStructGetData($me, 'HealthPercent') < 0.5 And GetDistance($me, $target) < 500 And GetEnergy() > 5 And IsRecharged($Vaettir_HeartOfShadow) Then UseSkillEx($Vaettir_HeartOfShadow, $target)
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
	RandomSleep(1000)
	If $VaettirsPlayerProfession == $ID_Monk Then UseSkillEx($Vaettir_Monk_BalthazarsSpirit, GetMyAgent())
	If $VaettirsPlayerProfession == $ID_Elementalist Then UseSkillEx($Vaettir_Elementalist_ElementalLord)
	GetVaettirsNornBlessing()
	If AggroAllMobs() == $FAIL Then Return $FAIL
	VaettirsKillSequence()
	Sleep(1000)

	If IsPlayerAlive() Then
		Info('Looting')
		PickUpItems(VaettirsStayAlive, DefaultShouldPickItem, $RANGE_EARSHOT)
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

	Local Static $vaettirs[31][2] = [ _ ; vaettirs locations
		_ ; left ball
		[12496, -22600], _
		[11375, -22761], _
		[10925, -23466], _
		[10917, -24311], _
		[9910, -24599], _
		[8995, -23177], _
		[8307, -23187], _
		[8213, -22829], _
		[8307, -23187], _
		[8213, -22829], _
		[8740, -22475], _
		[8880, -21384], _
		[8684, -20833], _
		[8982, -20576], _
		_ ; right ball
		[10196, -20124], _
		[9976, -18338], _
		[11316, -18056], _
		[10392, -17512], _
		[10114, -16948], _
		[10729, -16273], _
		[10810, -15058], _
		[11120, -15105], _
		[11670, -15457], _
		[12604, -15320], _
		[12476, -16157], _
		_ ; moving to spot
		[12920, -17032], _
		[12847, -17136], _
		[12720, -17222], _
		[12617, -17273], _
		[12518, -17305], _
		[12445, -17327] _
	]

	Info('Aggroing left')
	MoveTo(13172, -22137)
	If DoForArrayRows($vaettirs, 1, 14, VaettirsMoveDefending) == $FAIL Then Return $FAIL

	Info('Waiting for left ball')
	VaettirsSleepAndStayAlive(12000)
	If $VaettirsPlayerProfession <> $ID_Elementalist Then
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
			UseSkillEx($Vaettir_HeartOfShadow, $target)
		Else
			UseSkillEx($Vaettir_HeartOfShadow, GetMyAgent())
		EndIf
	EndIf
	VaettirsSleepAndStayAlive(6000)

	Info('Aggroing right')
	If DoForArrayRows($vaettirs, 15, 25, VaettirsMoveDefending) == $FAIL Then Return $FAIL

	Info('Waiting for right ball')
	VaettirsSleepAndStayAlive(15000)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If $VaettirsPlayerProfession <> $ID_Elementalist Then
		If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
			UseSkillEx($Vaettir_HeartOfShadow, $target)
		Else
			UseSkillEx($Vaettir_HeartOfShadow, GetMyAgent())
		EndIf
	EndIf
	VaettirsSleepAndStayAlive(5000)
	If DoForArrayRows($vaettirs, 26, 31, VaettirsMoveDefending) == $FAIL Then Return $FAIL
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func VaettirsMoveDefending($destinationX, $destinationY)
	Local $result = Null
	Switch $VaettirsPlayerProfession
		Case $ID_Assassin, $ID_Mesmer, $ID_Monk
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $VaettirsMoveOptions)
		Case $ID_Elementalist
			$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $VaettirsMoveOptionsElementalist)
	EndSwitch
	If $result == $STUCK Then
		; When playing as Elementalist or other professions that don't have death's charge or heart of shadow skills, then fight Vaettirs whenever player got surrounded and stuck
		VaettirsKillSequence()
		If IsPlayerAlive() Then
			Info('Looting')
			PickUpItems(VaettirsStayAlive, DefaultShouldPickItem, $RANGE_EARSHOT)
		EndIf
		Return IsPlayerAlive()? $SUCCESS : $FAIL
	Else
		Return $result
	EndIf
EndFunc


;~ Wait while staying alive at the same time (like Sleep(..), but without the dying part)
Func VaettirsSleepAndStayAlive($waitingTime)
	If IsPlayerDead() Then Return
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitingTime
		RandomSleep(100)
		If IsPlayerDead() Then Return
		VaettirsStayAlive()
	WEnd
EndFunc


;~ Use whatever skills you need to keep yourself alive.
Func VaettirsStayAlive()
	Local $adjacentCount, $areaCount, $foesSpellRange = False, $foesNear = False
	Local $distance
	Local $me = GetMyAgent()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), 1200)
	For $foe In $foes
		$distance = GetDistance($me, $foe)
		If $distance < 1200 Then
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
	If ($adjacentCount > 20 Or DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.6 Or _
			($foesSpellRange And GetEffect($ID_Shroud_of_Distress) == Null)) And _
			($VaettirsPlayerProfession == $ID_Assassin Or $VaettirsPlayerProfession == $ID_Mesmer) Then VaettirsCheckShroudOfDistress()
	If $foesNear Then VaettirsCheckBuffs()
	If $areaCount > 5 And $VaettirsPlayerProfession <> $ID_Monk Then VaettirsCheckChanneling()
	If $foesNear Then VaettirsCheckBuffs()
EndFunc


;~ Uses Shadow Form or other buffs like Obsidian Flesh or Protective Spirit if these are recharged
Func VaettirsCheckBuffs()
	Switch $VaettirsPlayerProfession
		Case $ID_Assassin, $ID_Mesmer, $ID_Monk
			VaettirsCheckShadowForm()
		Case $ID_Elementalist
			VaettirsCheckObsidianFlesh()
	EndSwitch
EndFunc


;~ Uses Shadow Form if its recharged
Func VaettirsCheckShadowForm()
	; Caution, if playing monk 55hp then protective spirit has to be already on player when casting shadow form, otherwise damage reduction to 0 won't be applied due to specific guild wars mechanics
	; Furthermore, due to specific guild wars mechanics casting protective spirit multiple times can remove damage reduction to 0 so protective spirit has to casted only once just before Shadow Form, otherwise player will die very fast
	If ($VaettirsPlayerProfession <> $ID_Monk And TimerDiff($VaettirShadowFormTimer) > 19000 And GetEnergy() > 20) Or _
		($VaettirsPlayerProfession == $ID_Monk And TimerDiff($VaettirShadowFormTimer) > 19500 And GetEnergy() > 30) Then
		If $VaettirsPlayerProfession == $ID_Monk Then UseSkillEx($Vaettir_Monk_ProtectiveSpirit)
		UseSkillEx($Vaettir_DeadlyParadox)
		While IsPlayerAlive() And Not IsRecharged($Vaettir_ShadowForm)
			Sleep(50)
		WEnd
		UseSkillEx($Vaettir_ShadowForm)
		If $VaettirsPlayerProfession <> $ID_Monk Then
			While IsPlayerAlive() And Not IsRecharged($Vaettir_WayOfPerfection)
				Sleep(50)
			WEnd
			UseSkillEx($Vaettir_WayOfPerfection)
		EndIf
		$VaettirShadowFormTimer = TimerInit()
	EndIf
EndFunc


;~ Maintaining Obsidian Flesh, Stoneflesh Aura, Elemental Lord, Mantra of Earth and Channeling
Func VaettirsCheckObsidianFlesh()
	If IsRecharged($Vaettir_Elementalist_ElementalLord) And Not IsRecharged($Vaettir_Elementalist_ObsidianFlesh) And Not IsRecharged($Vaettir_Elementalist_StonefleshAura) Then UseSkillEx($Vaettir_Elementalist_ElementalLord)
	If TimerDiff($VaettirObsidianFleshTimer) > 21000 And GetEnergy() > 30 Then
		UseSkillEx($Vaettir_Elementalist_GlyphOfSwiftness)
		While IsPlayerAlive() And Not IsRecharged($Vaettir_Elementalist_ObsidianFlesh)
			Sleep(50)
		WEnd
		UseSkillEx($Vaettir_Elementalist_ObsidianFlesh)
		$VaettirObsidianFleshTimer = TimerInit()
	EndIf
	If IsRecharged($Vaettir_Elementalist_StonefleshAura) And GetEnergy() > 15 Then UseSkillEx($Vaettir_Elementalist_StonefleshAura)
	If GetMapID() == $ID_Jaga_Moraine Then ; only cast energy accumulating skills when farming Vaettirs in jaga Moraine, not during run across Bjora Marches
		If TimerDiff($VaettirChannelingTimer) > 20000 And TimerDiff($VaettirObsidianFleshTimer) < 19000 And Not IsRecharged($Vaettir_Elementalist_StonefleshAura) And GetEnergy() > 5 Then
			UseSkillEx($Vaettir_Channeling)
			$VaettirChannelingTimer = TimerInit()
		EndIf
		If TimerDiff($VaettirMantraOfEarthTimer) > 40000 And GetEnergy() > 10 And TimerDiff($VaettirObsidianFleshTimer) < 19000 Then
			UseSkillEx($Vaettir_Elementalist_MantraOfEarth)
			$VaettirMantraOfEarthTimer = TimerInit()
		EndIf
	EndIf
EndFunc


;~ Uses Shroud of distress if its recharged
Func VaettirsCheckShroudOfDistress()
	If TimerDiff($VaettirShroudOfDistressTimer) > 50000 And TimerDiff($VaettirShadowFormTimer) < 18000 And GetEnergy() > 10 Then
		UseSkillEx($Vaettir_ShroudOfDistress)
		$VaettirShroudOfDistressTimer = TimerInit()
	EndIf
EndFunc


;~ Uses Channeling if its recharged
Func VaettirsCheckChanneling()
	If TimerDiff($VaettirChannelingTimer) > 22000 And _
		(($VaettirsPlayerProfession <> $ID_Elementalist And TimerDiff($VaettirShadowFormTimer) < 19000) Or _
		($VaettirsPlayerProfession == $ID_Elementalist And TimerDiff($VaettirObsidianFleshTimer) < 19000)) Then
		UseSkillEx($Vaettir_Channeling)
		$VaettirChannelingTimer = TimerInit()
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
	While IsPlayerAlive() And CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA) > 0 And _
			(((TimerDiff($VaettirShadowFormTimer) > 5000) And ($VaettirsPlayerProfession <> $ID_Elementalist)) Or _
			((TimerDiff($VaettirObsidianFleshTimer) > 5000) And ($VaettirsPlayerProfession == $ID_Elementalist)))
		If IsPlayerDead() Then Return
		Sleep(100)
		VaettirsStayAlive()
	WEnd

	Info('Killing Vaettirs')
	Switch $VaettirsPlayerProfession
		Case $ID_Assassin, $ID_Mesmer, $ID_Elementalist
			KillVaettirsUsingWastrelSkills()
		Case $ID_Monk
			KillVaettirsUsingSmitingSkills()
	EndSwitch
EndFunc


Func KillVaettirsUsingWastrelSkills()
	Local Static $MaxKillTime = 100000 ; 100 seconds max fight time
	Local $deadlock = TimerInit()
	Local $target
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	If $foesCount > 0 Then
		; Echo the Wastrel's Demise
		UseSkillEx($Vaettir_ArcaneEcho)
		$target = GetWastrelsTarget()
		UseSkillEx($Vaettir_WastrelsDemise, $target)
		While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < $MaxKillTime
			VaettirsStayAlive()

			; Use echoed wastrel if possible
			If IsRecharged($Vaettir_ArcaneEcho) And GetSkillbarSkillID($Vaettir_ArcaneEcho) == $ID_Wastrels_Demise Then
				$target = GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($Vaettir_ArcaneEcho, $target) ; here Arcane echo is echoed wastrel skill
			EndIf

			; Use wastrel's demise if possible
			If IsRecharged($Vaettir_WastrelsDemise) Then
				$target = GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($Vaettir_WastrelsDemise, $target)
			EndIf

			RandomSleep(100)
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		WEnd
	EndIf
EndFunc


Func KillVaettirsUsingSmitingSkills()
	Local Static $MaxKillTime = 120000 ; 2 minutes max fight time
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < $MaxKillTime
		VaettirsStayAlive()

		If IsRecharged($Vaettir_Monk_BalthazarsAura) And TimerDiff($VaettirShadowFormTimer) < 16000 And GetEnergy() > 25 Then
			UseSkillEx($Vaettir_Monk_BalthazarsAura)
		EndIf

		If IsRecharged($Vaettir_Monk_KirinsWrath) And TimerDiff($VaettirShadowFormTimer) < 16000 And GetEnergy() > 5 Then
			UseSkillEx($Vaettir_Monk_KirinsWrath)
		EndIf

		If IsRecharged($Vaettir_Monk_SymbolOfWrath) And TimerDiff($VaettirShadowFormTimer) < 16000 And GetEnergy() > 5 Then
			UseSkillEx($Vaettir_Monk_SymbolOfWrath)
		EndIf

		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	WEnd
EndFunc


;~ Exit Jaga Moraine to Bjora Marches and get back into Jaga Moraine
Func RezoneToJagaMoraine()
	Local $result = $SUCCESS
	If IsPlayerDead() Then $result = $FAIL

	Info('Zoning out and back in')
	VaettirsMoveDefending(12289, -17700)
	VaettirsMoveDefending(15318, -20351)

	Local $deadlockTimer = TimerInit()
	While IsPlayerDead()
		Info('Waiting for resurrection')
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$Deadlocked = True
			Return $FAIL
		EndIf
	WEnd
	MoveTo(15600, -20500)
	Move(15865, -20531)
	WaitMapLoading($ID_Bjora_Marches)
	MoveTo(-19968, 5564)
	Move(-20076, 5580, 30)
	WaitMapLoading($ID_Jaga_Moraine)

	Return $result
EndFunc