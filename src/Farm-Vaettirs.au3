#CS ===========================================================================
#################################
#								#
#			Vaettir Bot			#
#								#
#################################
Author: gigi
Modified by: Pink Musen (v.01), Deroni93 (v.02-3), Dragonel (with help from moneyvsmoney), Night, Gahais
#CE ===========================================================================

#include-once
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $AMeVaettirsFarmerSkillbar = 'OwVUI2h5lPP8Id2BkAiANBLhbKA'
Global Const $VaettirsFarmInformations = 'For best results, have :' & @CRLF _
	& '- +4 Shadow Arts' & @CRLF _
	& '- Blessed insignias'& @CRLF _
	& '- A shield with the inscription Like a rolling stone (+10 armor against earth damage)' & @CRLF _
	& '- A main hand with +20% enchantments duration' & @CRLF _
	& '- Cupcakes'
; Average duration ~ 3m40 ~ First run is 6m30s with setup and run
Global Const $VAETTIRS_FARM_DURATION = 4 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Skill_Shadow_Form) is better than UseSkillEx(2))
Global Const $Skill_Deadly_Paradox		= 1
Global Const $Skill_Shadow_Form			= 2
Global Const $Skill_Shroud_of_Distress	= 3
Global Const $Skill_Way_of_Perfection	= 4
Global Const $Skill_Heart_of_Shadow		= 5
Global Const $Skill_Channeling			= 6
Global Const $Skill_Arcane_Echo			= 7
Global Const $Skill_Wastrels_Demise		= 8

; ==== Global variables ====
Global $ChatStuckTimer = TimerInit()
Global $Deadlocked = False
Global $shadowFormTimer = TimerInit()
Global $shroudOfDistressTimer = TimerInit()
Global $channelingTimer = TimerInit()

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
Func VaettirFarm($STATUS)
	While $Deadlocked Or GetMapID() <> $ID_Jaga_Moraine
		$Deadlocked = False
		RunToJagaMoraine()
	WEnd

	If $STATUS <> 'RUNNING' Then Return $PAUSE
	Return VaettirsFarmLoop()
EndFunc


;~ Zones to Longeye if we are not there, and travel to Jaga Moraine
Func RunToJagaMoraine()
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Longeyes_Ledge Then TravelToOutpost($ID_Longeyes_Ledge, $DISTRICT_NAME)
	SwitchMode($ID_HARD_MODE)
	SetDisplayedTitle($ID_Norn_Title)
	LeaveParty() ; solo farmer
	Info('Setting up build skillbar')
	LoadSkillTemplate($AMeVaettirsFarmerSkillbar)

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

		If GetDistance($me, $target) < 1300 And GetEnergy() > 20 Then TryUseShadowForm()

		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') < 0.9 And GetEnergy() > 10 Then TryUseShroudOfDistress()
		If DllStructGetData($me, 'HealthPercent') < 0.5 And GetDistance($me, $target) < 500 And GetEnergy() > 5 And IsRecharged($Skill_Heart_of_Shadow) Then UseSkillEx($Skill_Heart_of_Shadow, $target)

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
	GetVaettirsNornBlessing()
	AggroAllMobs()
	;KillMobs()
	VaettirsKillSequence()
	Sleep(1000)
	VaettirsStayAlive()

	Info('Looting')
	PickUpItems()

	Return RezoneToJagaMoraine()
EndFunc


;~ Get Norn blessing only if title is not maxed yet
Func GetVaettirsNornBlessing()
	Local $nornTitlePoints = GetNornTitle()
	If $nornTitlePoints < 160000 Then
		Info('Getting norn title blessing')
		GoNearestNPCToCoords(13400, -20800)
		RandomSleep(300)
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
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
		UseSkillEx($Skill_Heart_of_Shadow, $target)
	Else
		UseSkillEx($Skill_Heart_of_Shadow, GetMyAgent())
	EndIf
	VaettirsSleepAndStayAlive(6000)

	Info('Aggroing right')
	If DoForArrayRows($vaettirs, 15, 25, VaettirsMoveDefending) == $FAIL Then Return $FAIL

	Info('Waiting for right ball')
	VaettirsSleepAndStayAlive(15000)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	If GetDistance(GetMyAgent(), $target) < $RANGE_SPELLCAST Then
		UseSkillEx($Skill_Heart_of_Shadow, $target)
	Else
		UseSkillEx($Skill_Heart_of_Shadow, GetMyAgent())
	EndIf
	VaettirsSleepAndStayAlive(5000)
	If DoForArrayRows($vaettirs, 26, 31, VaettirsMoveDefending) == $FAIL Then Return $FAIL
EndFunc


Func VaettirsMoveDefending($destinationX, $destinationY)
	Local $result = Null
	If $VaettirsPlayerProfession == $ID_Elementalist Then
		$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $VaettirsMoveOptionsElementalist)
	Else
		$result = MoveAvoidingBodyBlock($destinationX, $destinationY, $VaettirsMoveOptions)
	EndIf
	If $result == $STUCK Then
		; When playing as Elementalist or other professions that don't have death's charge or heart of shadow skills, then fight Vaettirs whenever player got surrounded and stuck
		VaettirsKillSequence()
		If IsPlayerAlive() Then
			Info('Looting')
			PickUpItems(VaettirsStayAlive, DefaultShouldPickItem, $RANGE_EARSHOT)
		EndIf
		If IsPlayerDead() Then Return $FAIL
	Else
		Return $result
	EndIf
EndFunc


;~ Kill a mob group
Func VaettirsKillSequence()
	; Wait for shadow form to have been casted very recently
	While IsPlayerAlive() And TimerDiff($shadowFormTimer) > 5000
		If IsPlayerDead() Then Return
		Sleep(100)
		VaettirsStayAlive()
	WEnd

	Info('Killing')
	Local $deadlock = TimerInit()
	Local $target
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	If $foesCount > 0 Then
		; Echo the Wastrel's Demise
		UseSkillEx($Skill_Arcane_Echo)
		$target = GetWastrelsTarget()
		UseSkillEx($Skill_Wastrels_Demise, $target)
		While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 60000
			; Use echoed wastrel if possible
			If IsRecharged($Skill_Arcane_Echo) And GetSkillbarSkillID($Skill_Arcane_Echo) == $ID_Wastrels_Demise Then
				$target = GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($Skill_Arcane_Echo, $target)
			EndIf

			; Use wastrel if possible
			If IsRecharged($Skill_Wastrels_Demise) Then
				$target = GetWastrelsTarget()
				If $target <> Null Then UseSkillEx($Skill_Wastrels_Demise, $target)
			EndIf

			RandomSleep(100)
			VaettirsStayAlive()
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		WEnd
	EndIf
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

	If $foesNear And GetEnergy() > 20 Then TryUseShadowForm()
	If ($adjacentCount > 20 Or DllStructGetData(GetMyAgent(), 'HealthPercent') < 0.6 Or ($foesSpellRange And DllStructGetData(GetEffect($ID_Shroud_of_Distress), 'SkillID') == 0)) And GetEnergy() > 10 Then
		TryUseShroudOfDistress()
	EndIf
	If $foesNear And GetEnergy() > 20 Then TryUseShadowForm()
	If $areaCount > 5 Then TryUseChanneling()
	If $foesNear And GetEnergy() > 20 Then TryUseShadowForm()
EndFunc


;~ Uses Shadow Form if its recharged
Func TryUseShadowForm()
	If TimerDiff($shadowFormTimer) > 20000 Then
		UseSkillEx($Skill_Deadly_Paradox)
		UseSkillEx($Skill_Shadow_Form)
		UseSkillEx($Skill_Way_of_Perfection)
		$shadowFormTimer = TimerInit()
	EndIf
EndFunc


;~ Uses Shroud of distress if its recharged
Func TryUseShroudOfDistress()
	If TimerDiff($shroudOfDistressTimer) > 65000 And TimerDiff($shadowFormTimer) < 18000 Then
		UseSkillEx($Skill_Shroud_of_Distress)
		$shroudOfDistressTimer = TimerInit()
	EndIf
EndFunc


;~ Uses Channeling if its recharged
Func TryUseChanneling()
	If TimerDiff($channelingTimer) > 25000 And TimerDiff($shadowFormTimer) < 19000 Then
		UseSkillEx($Skill_Channeling)
		$channelingTimer = TimerInit()
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