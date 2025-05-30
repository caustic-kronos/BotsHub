#CS
#################################
#								#
#			Vaettir Bot			#
#								#
#################################
Author: gigi
Modified by: Pink Musen (v.01), Deroni93 (v.02-3), Dragonel (with help from moneyvsmoney), Night
#CE

#include-once
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)


Global Const $VaettirBotVersion = '0.4'

; ==== Constantes ====
Global Const $AMeVaettirsFarmerSkillbar = 'OwVUI2h5lPP8Id2BkAiANBLhbKA'
Global Const $VaettirsFarmInformations = 'For best results, have :' & @CRLF _
	& '- +4 Shadow Arts' & @CRLF _
	& '- Blessed insignias'& @CRLF _
	& '- A shield with the inscription Like a rolling stone (+10 armor against earth damage)' & @CRLF _
	& '- A main hand with +20% enchantments duration' & @CRLF _
	& '- Cupcakes'
; Average duration ~ 3m40 ~ First run is 6m30s with setup and run
Global Const $VAETTIRS_FARM_DURATION = (6 * 60 + 30) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Skill_Shadow_Form) is better than UseSkillEx(2))
Global Const $Skill_Deadly_Paradox = 1
Global Const $Skill_Shadow_Form = 2
Global Const $Skill_Shroud_of_Distress = 3
Global Const $Skill_Way_of_Perfection = 4
Global Const $Skill_Heart_of_Shadow = 5
Global Const $Skill_Channeling = 6
Global Const $Skill_Arcane_Echo = 7
Global Const $Skill_Wastrels_Demise = 8

; ==== Global variables ====
Global $ChatStuckTimer = TimerInit()
Global $Deadlocked = False
Global $timer = TimerInit()


;~ Main method to farm Vaettirs
Func VaettirFarm($STATUS)
	If $Deadlocked Then Return 2

	While GetMapID() <> $ID_Jaga_Moraine
		RunToJagaMoraine()
	WEnd

	If $STATUS <> 'RUNNING' Then Return 2

	Return VaettirsFarmLoop()
EndFunc


;~ Zones to Longeye if we are not there, and travel to Jaga Moraine
Func RunToJagaMoraine()
	If GetMapID() <> $ID_Longeyes_Ledge Then
		Info('Travelling to Longeyes Ledge')
		DistrictTravel($ID_Longeyes_Ledge, $DISTRICT_NAME)
	EndIf

	SwitchMode($ID_HARD_MODE)
	LeaveGroup()

	LoadSkillTemplate($AMeVaettirsFarmerSkillbar)

	Info('Exiting Outpost')
	MoveTo(-26000, 16000)
	Move(-26472, 16217)
	RndSleep(1000)
	WaitMapLoading($ID_Bjora_Marches)

	RndSleep(500)
	UseConsumable($ID_Birthday_Cupcake)
	RndSleep(500)

	SetDisplayedTitle($ID_Norn_Title)

	Info('Running to Jaga Moraine')
	Local $Array_Longeyes_Ledge[31][3] = [ _
		[1, 15003.8,	-16598.1], _
		[1, 15003.8,	-16598.1], _
		[1, 12699.5,	-14589.8], _
		[1, 11628,		-13867.9], _
		[1, 10891.5,	-12989.5], _
		[1, 10517.5,	-11229.5], _
		[1, 10209.1,	-9973.1], _
		[1, 9296.5,		-8811.5], _
		[1, 7815.6,		-7967.1], _
		[1, 6266.7,		-6328.5], _
		[1, 4940,		-4655.4], _
		[1, 3867.8,		-2397.6], _
		[1, 2279.6,		-1331.9], _
		[1, 7.2,		-1072.6], _
		[1, 7.2,		-1072.6], _
		[1, -1752.7,	-1209], _
		[1, -3596.9,	-1671.8], _
		[1, -5386.6,	-1526.4], _
		[1, -6904.2,	-283.2], _
		[1, -7711.6,	364.9], _
		[1, -9537.8,	1265.4], _
		[1, -11141.2,	857.4], _
		[1, -12730.7,	371.5], _
		[1, -13379,		40.5], _
		[1, -14925.7,	1099.6], _
		[1, -16183.3,	2753], _
		[1, -17803.8,	4439.4], _
		[1, -18852.2,	5290.9], _
		[1, -19250,		5431], _
		[1, -19968,		5564], _
		[2, -20076,		5580] _
	]
	For $i = 0 To (UBound($Array_Longeyes_Ledge) -1)
		If ($Array_Longeyes_Ledge[$i][0] == 1) Then
			If Not MoveRunning($Array_Longeyes_Ledge[$i][1], $Array_Longeyes_Ledge[$i][2]) Then ExitLoop
		EndIf
		If ($Array_Longeyes_Ledge[$i][0] == 2) Then
			Move($Array_Longeyes_Ledge[$i][1], $Array_Longeyes_Ledge[$i][2], 30)
			WaitMapLoading($ID_Jaga_Moraine)
		EndIf
	Next
EndFunc


;~ Move to destX, destY. This is to be used in the run from across Bjora Marches
Func MoveRunning($destX, $destY)
	If GetIsDead() Then Return False

	Move($destX, $destY)

	Local $target
	Local $me = GetMyAgent()
	While ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $destX, $destY) > 250
		$target = GetNearestEnemyToAgent($me)

		If GetIsDead() Then Return False

		If GetDistance($me, $target) < 1300 And GetEnergy()>20 And IsRecharged($Skill_Deadly_Paradox) And IsRecharged($Skill_Shadow_Form ) Then
			UseSkillEx($Skill_Deadly_Paradox)
			UseSkillEx($Skill_Shadow_Form )
			$timer = TimerInit()
		EndIf

		$me = GetMyAgent()
		If DllStructGetData($me, 'HP') < 0.9 And GetEnergy() > 10 And IsRecharged($Skill_Shroud_of_Distress) And TimerDiff($timer) < 15000 Then UseSkillEx($Skill_Shroud_of_Distress)
		If DllStructGetData($me, 'HP') < 0.5 And GetDistance($me, $target) < 500 And GetEnergy() > 5 And IsRecharged($Skill_Heart_of_Shadow) Then UseSkillEx($Skill_Heart_of_Shadow, $target)

		$me = GetMyAgent()
		If DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0 Then
			Move($destX, $destY)
		EndIf
		RndSleep(500)
		$me = GetMyAgent()
	WEnd
	Return True
EndFunc


;~ Farm loop
Func VaettirsFarmLoop()
	RndSleep(2000)
	AggroAllMobs()
	;KillMobs()
	VaettirsKillSequence()
	WaitFor(1200)

	Info('Looting')
	PickUpItems()

	Return RezoneToJagaMoraine()
EndFunc


;~ Get Norn blessing only if title is not maxed yet
Func GetVaettirsNornBlessing()
	Local $norn = GetNornTitle()
	If $norn < 160000 Then
		Info('Getting norn title blessing')
		GoNearestNPCToCoords(13400, -20800)
		RndSleep(300)
		Dialog(132)
	EndIf
	RndSleep(350)
EndFunc


;~ Self explanatory
Func AggroAllMobs()
	Info('Aggroing left')
	GetVaettirsNornBlessing()
	MoveTo(13172, -22137)
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	MoveAggroing(12496, -22600, 150)
	MoveAggroing(11375, -22761, 150)
	MoveAggroing(10925, -23466, 150)
	MoveAggroing(10917, -24311, 150)
	MoveAggroing(9910, -24599, 150)
	MoveAggroing(8995, -23177, 150)
	MoveAggroing(8307, -23187, 150)
	MoveAggroing(8213, -22829, 150)
	MoveAggroing(8307, -23187, 150)
	MoveAggroing(8213, -22829, 150)
	MoveAggroing(8740, -22475, 150)
	MoveAggroing(8880, -21384, 150)
	MoveAggroing(8684, -20833, 150)
	MoveAggroing(8982, -20576, 150)

	Info('Waiting for left ball')
	WaitFor(12*1000)

	If GetDistance(GetMyAgent(), $target) < 1000 Then
		UseSkillEx($Skill_Heart_of_Shadow, $target)
	Else
		UseSkillEx($Skill_Heart_of_Shadow)
	EndIf

	WaitFor(6000)

	$target = GetNearestEnemyToAgent(GetMyAgent())

	Info('Aggroing right')
	MoveAggroing(10196, -20124, 150)
	MoveAggroing(9976, -18338, 150)
	MoveAggroing(11316, -18056, 150)
	MoveAggroing(10392, -17512, 150)
	MoveAggroing(10114, -16948, 150)
	MoveAggroing(10729, -16273, 150)
	MoveAggroing(10810, -15058, 150)
	MoveAggroing(11120, -15105, 150)
	MoveAggroing(11670, -15457, 150)
	MoveAggroing(12604, -15320, 150)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	MoveAggroing(12476, -16157)

	Info('Waiting for right ball')
	WaitFor(15*1000)

	If GetDistance(GetMyAgent(), $target) < 1000 Then
		UseSkillEx($Skill_Heart_of_Shadow, $target)
	Else
		UseSkillEx($Skill_Heart_of_Shadow, GetMyAgent())
	EndIf

	WaitFor(5000)

	MoveAggroing(12920, -17032, 30)
	MoveAggroing(12847, -17136, 30)
	MoveAggroing(12720, -17222, 30)
	WaitFor(300)
	MoveAggroing(12617, -17273, 30)
	WaitFor(300)
	MoveAggroing(12518, -17305, 20)
	WaitFor(300)
	MoveAggroing(12445, -17327, 10)
EndFunc


;~ Kill mobs
Func KillMobs()
	; Starts by recasting Shadow Form to avoid interrupting the kill sequence with it
	Local $deadlockTimer = TimerInit()
	Local $Shadow_Form_Timer = TimerDiff($timer)
	Local $agentArray
	Local $target
	Local $targetID

	Info('Killing')
	While TimerDiff($timer) > $Shadow_Form_Timer And TimerDiff($deadlockTimer) < 20000
		WaitFor(100)
		If GetIsDead() Then Return
	WEnd

	UseShadowForm(True)

	If GetIsDead() Then Return

	StayAlive($agentArray)

	$deadlockTimer = TimerInit()
	$target = GetNearestEnemyToAgent(GetMyAgent())
	$targetID = DllStructGetData($target, 'ID')
	RndSleep(100)

	While GetAgentExists($targetID) And DllStructGetData($target, 'HP') > 0
		RndSleep(50)
		If GetIsDead() Then Return
		$agentArray = GetAgentArray(0xDB)
		StayAlive($agentArray)

		; Use echo if possible
		If GetSkillbarSkillRecharge($Skill_Shadow_Form ) > 5000 And GetSkillbarSkillID($Skill_Arcane_Echo) == $ID_Arcane_Echo Then
			If IsRecharged($Skill_Wastrels_Demise) And IsRecharged($Skill_Arcane_Echo) Then
				UseSkillEx($Skill_Arcane_Echo)
				UseSkillEx($Skill_Wastrels_Demise, GetGoodTarget())
				$agentArray = GetAgentArray(0xDB)
			EndIf
		EndIf

		UseShadowForm(True)

		; Use wastrel if possible
		If IsRecharged($Skill_Wastrels_Demise) Then
			UseSkillEx($Skill_Wastrels_Demise, GetGoodTarget())
			$agentArray = GetAgentArray(0xDB)
		EndIf

		UseShadowForm(True)

		; Use echoed wastrel if possible
		If IsRecharged($Skill_Arcane_Echo) And GetSkillbarSkillID($Skill_Arcane_Echo) == $ID_Wastrels_Demise Then
			UseSkillEx($Skill_Arcane_Echo, GetGoodTarget())
		EndIf

		; Check if target has ran away
		If GetDistance(GetMyAgent(), $target) > $RANGE_EARSHOT Then
			$target = GetNearestEnemyToAgent(GetMyAgent())
			$targetID = DllStructGetData($target, 'ID')
			RndSleep(100)
			If DllStructGetData($target, 'HP') = 0 Or GetDistance(GetMyAgent(), $target) > $RANGE_AREA Then ExitLoop
		EndIf

		If TimerDiff($deadlockTimer) > 60 * 1000 Then ExitLoop
	WEnd
EndFunc


;~ Kill a mob group
Func VaettirsKillSequence()
	Local $Shadow_Form_Timer = TimerDiff($timer)
	While TimerDiff($timer) > $Shadow_Form_Timer And TimerDiff($deadlockTimer) < 20000
		WaitFor(100)
		If GetIsDead() Then Return
	WEnd

	Info('Killing')

	Local $deadlock = TimerInit()
	Local $agentArray = GetAgentArray(0xDB)
	Local $target
	UseShadowForm(True)
	StayAlive($agentArray)
	If GetIsDead() Then Return

	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	If $foesCount > 0 Then
		; Echo the Wastrel's Demise
		UseSkillEx($Skill_Arcane_Echo)
		$target = GetGoodTarget()
		UseSkillEx($Skill_Wastrels_Demise, $target)
		While Not GetIsDead() And $foesCount > 0 And TimerDiff($deadlock) < 60000
			$agentArray = GetAgentArray(0xDB)
			; Use echoed wastrel if possible
			If IsRecharged($Skill_Arcane_Echo) And GetSkillbarSkillID($Skill_Arcane_Echo) == $ID_Wastrels_Demise Then
				$target = GetGoodTarget()
				If $target == Null Then ExitLoop
				UseSkillEx($Skill_Arcane_Echo, $target)
			EndIf

			; Use wastrel if possible
			If IsRecharged($Skill_Wastrels_Demise) Then
				$target = GetGoodTarget()
				If $target == Null Then ExitLoop
				UseSkillEx($Skill_Wastrels_Demise, $target)
			EndIf

			UseShadowForm(True)
			RndSleep(100)
			$agentArray = GetAgentArray(0xDB)
			StayAlive($agentArray)
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
		WEnd
	EndIf
EndFunc


;~ Exit Jaga Moraine to Bjora Marches and get back into Jaga Moraine
Func RezoneToJagaMoraine()
	Local $success = 0
	If GetIsDead() Then $success = 1
	If $Deadlocked Then $success 1

	Info('Zoning out and back in')
	MoveAggroing(12289, -17700)
	MoveAggroing(15318, -20351)

	Local $deadlockTimer = TimerInit()
	While GetIsDead()
		Info('Waiting for resurrection')
		RndSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$Deadlocked = True
			Return 1
		EndIf
	WEnd
	MoveTo(15600, -20500)
	Move(15865, -20531)
	WaitMapLoading($ID_Bjora_Marches)
	MoveTo(-19968, 5564)
	Move(-20076, 5580, 30)
	WaitMapLoading($ID_Jaga_Moraine)

	ClearMemory()
	; _PurgeHook()
	Return $success
EndFunc


;~ Move to destX, destY, while staying alive vs vaettirs
Func MoveAggroing($X, $Y, $random = 150)
	If GetIsDead() Then Return

	Local $agentArray
	Local $blockedCount
	Local $heartOfShadowUsageCount
	Local $angle
	Local $stuckTimer = TimerInit()

	Move($X, $Y, $random)

	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	While ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $X, $Y) > $random * 1.5
		$agentArray = GetAgentArray(0xDB)
		If GetIsDead() Then Return False
		StayAlive($agentArray)
		$me = GetMyAgent()
		If DllStructGetData($me, 'MoveX') == 0 And DllStructGetData($me, 'MoveY') == 0 Then
			If $heartOfShadowUsageCount > 6 Then
				While Not GetIsDead()
					RndSleep(1000)
				WEnd
				Return False
			EndIf

			$blockedCount += 1
			$me = GetMyAgent()
			If $blockedCount < 5 Then
				Move($X, $Y, $random)
			ElseIf $blockedCount < 10 Then
				$angle += 40
				Move(DllStructGetData($me, 'X')+300*sin($angle), DllStructGetData($me, 'Y')+300*cos($angle))
			ElseIf IsRecharged($Skill_Heart_of_Shadow) Then
				If $heartOfShadowUsageCount==0 And GetDistance($me, $target) < 1000 Then
					UseSkillEx($Skill_Heart_of_Shadow, $target)
				Else
					UseSkillEx($Skill_Heart_of_Shadow, $me)
				EndIf
				$blockedCount = 0
				$heartOfShadowUsageCount += 1
			EndIf
		Else
			If $blockedCount > 0 Then
				; use a timer to avoid spamming /stuck
				If TimerDiff($ChatStuckTimer) > 3000 Then
					SendChat('stuck', '/')
					$ChatStuckTimer = TimerInit()
				EndIf
				$blockedCount = 0
				$heartOfShadowUsageCount = 0
			EndIf

			; target is far, we probably got stuck
			If GetDistance($me, $target) > 1100 Then
				; dont spam
				If TimerDiff($ChatStuckTimer) > 3000 Then
					SendChat('stuck', '/')
					$ChatStuckTimer = TimerInit()
					RndSleep(GetPing() + 20)
					; we werent stuck, but target broke aggro. select a new one
					If GetDistance($me, $target) > 1100 Then
						$target = GetNearestEnemyToAgent($me)
					EndIf
				EndIf
			EndIf
		EndIf
		RndSleep(50)
		$me = GetMyAgent()
	WEnd
	Return True
EndFunc


;~ Wait while staying alive at the same time (like Sleep(..), but without the dying part)
Func WaitFor($waitingTime)
	If GetIsDead() Then Return
	Local $agentArray
	Local $timer = TimerInit()
	While TimerDiff($timer) < $waitingTime
		RndSleep(100)
		If GetIsDead() Then Return
		$agentArray = GetAgentArray(0xDB)
		StayAlive($agentArray)
	WEnd
EndFunc


;~ Use whatever skills you need to keep yourself alive.
;~ Take agent array as param to more effectively react to the environment (mobs)
Func StayAlive(Const ByRef $agentArray)
	If IsRecharged($Skill_Shadow_Form ) Then
		UseSkillEx($Skill_Deadly_Paradox)
		UseSkillEx($Skill_Shadow_Form )
		$timer = TimerInit()
	EndIf

	Local $adjacentCount, $areaCount, $spellcastCount, $proximityCount
	Local $distance
	Local $me = GetMyAgent()
	For $i = 1 To $agentArray[0]
		If DllStructGetData($agentArray[$i], 'Allegiance') <> 0x3 Then ContinueLoop
		If DllStructGetData($agentArray[$i], 'HP') <= 0 Then ContinueLoop
		$distance = GetPseudoDistance($me, $agentArray[$i])
		If $distance < 1200*1200 Then
			$proximityCount += 1
			If $distance < $RANGE_SPELLCAST_2 Then
				$spellcastCount += 1
				If $distance < $RANGE_AREA_2 Then
					$areaCount += 1
					If $distance < $RANGE_ADJACENT_2 Then
						$adjacentCount += 1
					EndIf
				EndIf
			EndIf
		EndIf
	Next

	UseShadowForm($proximityCount)

	If IsRecharged($Skill_Shroud_of_Distress) And TimerDiff($timer) < 15000 Then
		If $spellcastCount > 0 And DllStructGetData(GetEffect($ID_Shroud_of_Distress), 'SkillID') == 0 Then
			UseSkillEx($Skill_Shroud_of_Distress)
		ElseIf DllStructGetData(GetMyAgent(), 'HP') < 0.6 Then
			UseSkillEx($Skill_Shroud_of_Distress)
		ElseIf $adjacentCount > 20 Then
			UseSkillEx($Skill_Shroud_of_Distress)
			EndIf
		Else
	EndIf

	UseShadowForm($proximityCount)

	If IsRecharged($Skill_Way_of_Perfection) And TimerDiff($timer) < 15000 Then
		If DllStructGetData(GetMyAgent(), 'HP') < 0.5 Then
			UseSkillEx($Skill_Way_of_Perfection)
		ElseIf $adjacentCount > 20 Then
			UseSkillEx($Skill_Way_of_Perfection)
			EndIf
		Else
	EndIf

	UseShadowForm($proximityCount)

	If IsRecharged($Skill_Channeling) And TimerDiff($timer) < 15000 Then
		If $areaCount > 5 And GetEffectTimeRemaining($ID_Channeling) < 2000 Then
			UseSkillEx($Skill_Channeling)
			Else
		EndIf
	EndIf

	UseShadowForm($proximityCount)
EndFunc


;~ Uses Shadow Form if there's anything close and if its recharged
Func UseShadowForm($proximityCount)
	If $proximityCount > 0 And IsRecharged($Skill_Shadow_Form) Then
		UseSkillEx($Skill_Deadly_Paradox)
		UseSkillEx($Skill_Shadow_Form)
		$timer = TimerInit()
	EndIf
EndFunc


;~ Returns a good target for wastrels
Func GetGoodTarget()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	For $foe In $foes
		If DllStructGetData($foe, 'HP') <= 0 Then ContinueLoop
		If DllStructGetData($foe, 'Allegiance') <> 0x3 Then ContinueLoop
		If GetHasHex($foe) Then ContinueLoop
		If Not GetIsEnchanted($foe) Then ContinueLoop
		Return $foe
	Next
	Return Null
EndFunc