#CS
#################################
#                               #
#          Vaettir Bot          #
#                               #
#################################
Author: gigi
Modified by: Pink Musen (v.01), Deroni93 (v.02-3), Dragonel (with help from moneyvsmoney), Night (v.0.4)
#CE

#include-once
#NoTrayIcon

#include <Date.au3>

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"

Opt("MustDeclareVars", 1)


Local Const $VaettirBotVersion = "0.4"

; ==== Constantes ====
Local Const $AMeVaettirsFarmerSkillbar = "OwVUI2h5lPP8Id2BkAiAvpLBTAA"
Local Const $VaettirsFarmInformations = "For best results, have :" & @CRLF _
	& "- +4 Shadow Arts" & @CRLF _
	& "- Blessed insignias"& @CRLF _
	& "- A shield with the inscription 'Like a rolling stone' (+10 armor against earth damage)" & @CRLF _
	& "- A main hand with +20% enchantments duration" & @CRLF _
	& "- Cupcakes"
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Skill_Shadow_Form)  is better than UseSkillEx(2))
Local Const $Skill_Deadly_Paradox = 1
Local Const $Skill_Shadow_Form  = 2
Local Const $Skill_Shroud_of_Distress = 3
Local Const $Skill_Way_of_Perfection = 4
Local Const $Skill_Heart_of_Shadow = 5
Local Const $Skill_Channeling = 6
Local Const $Skill_Arcane_Echo = 7
Local Const $Skill_Wastrels_Demise = 8

; ==== Global variables ====
Local Const $RenderingEnabled = True
Local $ChatStuckTimer = TimerInit()
Local $Deadlocked = False
Local $timer = TimerInit()


;~ Main method to farm Vaettirs
Func VaettirFarm($STATUS)
	If ($Deadlocked OR ((CountSlots() < 5) AND (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED))) Then
		Out("Inventory full, pausing.")
		$Deadlocked = False
		Return 2
	EndIf

	If $STATUS <> "RUNNING" Then Return 2

	If GetMapID() <> $ID_Jaga_Moraine Then RunToJagaMoraine()

	If $STATUS <> "RUNNING" Then Return 2

	Return VaettirsFarmLoop()
EndFunc


;~ Zones to Longeye if we're not there, and travel to Jaga Moraine
Func RunToJagaMoraine()
	If GetMapID() <> $ID_Longeyes_Ledge Then
		Out("Travelling to Longeye's Ledge")
		;RandomDistrictTravel($ID_Longeyes_Ledge)
		DistrictTravel($ID_Longeyes_Ledge, $ID_EUROPE, $ID_FRENCH)
	EndIf

	SwitchMode($ID_HARD_MODE)

	Out("Exiting Outpost")
	MoveTo(-26472, 16217)
	WaitMapLoading($ID_Bjora_Marches)

	RndSleep(500)
	If (GUICtrlRead($ConsumeCupcakeCheckbox) == $GUI_CHECKED) Then UseCupcake()
	RndSleep(500)
	
	;~ TODO Display your Norn Title for the health boost.
	;SetDisplayedTitle(0x29)
	;RndSleep(500)

	Out("Running to Jaga Moraine")
	Local $Array_Longeyes_Ledge[31][3] = [ _
		[1, 15003.8, -16598.1], _
		[1, 15003.8, -16598.1], _
		[1, 12699.5, -14589.8], _
		[1, 11628,   -13867.9], _
		[1, 10891.5, -12989.5], _
		[1, 10517.5, -11229.5], _
		[1, 10209.1, -9973.1], _
		[1, 9296.5,  -8811.5], _
		[1, 7815.6,  -7967.1], _
		[1, 6266.7,  -6328.5], _
		[1, 4940,    -4655.4], _
		[1, 3867.8,  -2397.6], _
		[1, 2279.6,  -1331.9], _
		[1, 7.2,     -1072.6], _
		[1, 7.2,     -1072.6], _
		[1, -1752.7, -1209], _
		[1, -3596.9, -1671.8], _
		[1, -5386.6, -1526.4], _
		[1, -6904.2, -283.2], _
		[1, -7711.6, 364.9], _
		[1, -9537.8, 1265.4], _
		[1, -11141.2,857.4], _
		[1, -12730.7,371.5], _
		[1, -13379,  40.5], _
		[1, -14925.7,1099.6], _
		[1, -16183.3,2753], _
		[1, -17803.8,4439.4], _
		[1, -18852.2,5290.9], _
		[1, -19250,  5431], _
		[1, -19968, 5564], _
		[2, -20076,  5580] _
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


;~ Description: Move to destX, destY. This is to be used in the run from across Bjora Marches
Func MoveRunning($lDestX, $lDestY)
	If GetIsDead(-2) Then Return False

	Local $lTgt

	Move($lDestX, $lDestY)

	Do
		RndSleep(500)

		TargetNearestEnemy()
		$lTgt = GetAgentByID(-1)

		If GetIsDead(-2) Then Return False
		
		If GetDistance(GetAgentByID(-2), $lTgt) < 1300 And GetEnergy(-2)>20 And IsRecharged($Skill_Deadly_Paradox) And IsRecharged($Skill_Shadow_Form ) Then
			UseSkillEx($Skill_Deadly_Paradox)
			UseSkillEx($Skill_Shadow_Form )
			$timer = TimerInit()
		EndIf

		If DllStructGetData(GetAgentByID(-2), "HP") < 0.9 And GetEnergy(-2) > 10 And IsRecharged($Skill_Shroud_of_Distress) And TimerDiff($timer) < 15000 Then UseSkillEx($Skill_Shroud_of_Distress)

		If DllStructGetData(GetAgentByID(-2), "HP") < 0.5 And GetDistance(GetAgentByID(-2), $lTgt) < 500 And GetEnergy(-2) > 5 And IsRecharged($Skill_Heart_of_Shadow) Then UseSkillEx($Skill_Heart_of_Shadow, -1)

		If DllStructGetData(GetAgentByID(-2), 'MoveX') == 0 And DllStructGetData(GetAgentByID(-2), 'MoveY') == 0 Then
			Move($lDestX, $lDestY)
		EndIf

	Until ComputeDistance(DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $lDestX, $lDestY) < 250
	Return True
EndFunc


;~ Farm loop
Func VaettirsFarmLoop()
	If Not $RenderingEnabled Then ClearMemory()

	; TODO Display your Norn Title for the health boost.
	;SetDisplayedTitle(0x29)
	
	RndSleep(2000)

	AggroAllMobs()

	KillMobs()

	WaitFor(1200)

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		Out("Looting")
		PickUpItems()
	EndIf

	Return RezoneToJagaMoraine()
EndFunc


;~ Self explanatory
Func AggroAllMobs()
	Out("Aggroing left")
	MoveTo(13501, -20925)
	MoveTo(13172, -22137)
	TargetNearestEnemy()
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

	Out("Waiting for left ball")
	WaitFor(12*1000)

	If GetDistance() < 1000 Then
		UseSkillEx($Skill_Heart_of_Shadow, -1)
	Else
		UseSkillEx($Skill_Heart_of_Shadow, -2)
	EndIf

	WaitFor(6000)

	TargetNearestEnemy()

	Out("Aggroing right")
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
	TargetNearestEnemy()
	MoveAggroing(12476, -16157)

	Out("Waiting for right ball")
	WaitFor(15*1000)

	If GetDistance() < 1000 Then
		UseSkillEx($Skill_Heart_of_Shadow, -1)
	Else
		UseSkillEx($Skill_Heart_of_Shadow, -2)
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
	Local $lAgentArray
	
	Out("Killing")
	Do
		WaitFor(100)
		If GetIsDead(-2) Then Return
	Until (TimerDiff($timer)) < $Shadow_Form_Timer Or (TimerDiff($deadlockTimer) > 20000)

	UseShadowForm(True)

	If GetIsDead(-2) Then Return

	$deadlockTimer = TimerInit()
	TargetNearestEnemy()
	RndSleep(100)
	Local $lTargetID = GetCurrentTargetID()

	While GetAgentExists($lTargetID) And DllStructGetData(GetAgentByID($lTargetID), "HP") > 0
		RndSleep(50)
		If GetIsDead(-2) Then Return
		$lAgentArray = GetAgentArray(0xDB)
		StayAlive($lAgentArray)

		; Use echo if possible
		If GetSkillbarSkillRecharge($Skill_Shadow_Form ) > 5000 And GetSkillbarSkillID($Skill_Arcane_Echo) == $ID_Arcane_Echo Then
			If IsRecharged($Skill_Wastrels_Demise) And IsRecharged($Skill_Arcane_Echo) Then
				UseSkillEx($Skill_Arcane_Echo)
				UseSkillEx($Skill_Wastrels_Demise, GetGoodTarget($lAgentArray))
				$lAgentArray = GetAgentArray(0xDB)
			EndIf
		EndIf

		UseShadowForm(True)

		; Use wastrel if possible
		If IsRecharged($Skill_Wastrels_Demise) Then
			UseSkillEx($Skill_Wastrels_Demise, GetGoodTarget($lAgentArray))
			$lAgentArray = GetAgentArray(0xDB)
		EndIf

		UseShadowForm(True)

		; Use echoed wastrel if possible
		If IsRecharged($Skill_Arcane_Echo) And GetSkillbarSkillID($Skill_Arcane_Echo) == $ID_Wastrels_Demise Then
			UseSkillEx($Skill_Arcane_Echo, GetGoodTarget($lAgentArray))
		EndIf

		; Check if target has ran away
		If GetDistance(-2, $lTargetID) > $RANGE_EARSHOT Then
			TargetNearestEnemy()
			RndSleep(100)
			If GetAgentExists(-1) And DllStructGetData(GetAgentByID(-1), "HP") > 0 And GetDistance(-2, -1) < $RANGE_AREA Then
				$lTargetID = GetCurrentTargetID()
			Else
				ExitLoop
			EndIf
		EndIf

		If TimerDiff($deadlockTimer) > 60 * 1000 Then ExitLoop
	WEnd
EndFunc


;~ Exit Jaga Moraine to Bjora Marches and get back into Jaga Moraine
Func RezoneToJagaMoraine()
	Local $success = 0
	If GetIsDead(-2) Then $success = 1
	If $Deadlocked Then $success 1

	Out("Zoning out and back in")
	MoveAggroing(12289, -17700)
	MoveAggroing(15318, -20351)

	Local $deadlockTimer = TimerInit()
	While GetIsDead(-2)
		Out("Waiting for resurrection")
		RndSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$Deadlocked = True
			Return 1
		EndIf
	WEnd
	Move(15865, -20531)
	WaitMapLoading($ID_Bjora_Marches)
	MoveTo(-19968, 5564)
	Move(-20076,  5580, 30)
	WaitMapLoading($ID_Jaga_Moraine)

	ClearMemory()
	; _PurgeHook()
	Return $success
EndFunc


;~ Description: Move to destX, destY, while staying alive vs vaettirs
Func MoveAggroing($lDestX, $lDestY, $lRandom = 150)
	If GetIsDead(-2) Then Return

	Local $lAgentArray
	Local $lBlocked
	Local $lHosCount
	Local $lAngle
	Local $stuckTimer = TimerInit()

	Move($lDestX, $lDestY, $lRandom)

	Do
		RndSleep(50)
		$lAgentArray = GetAgentArray(0xDB)
		If GetIsDead(-2) Then Return False
		StayAlive($lAgentArray)

		If DllStructGetData(GetAgentByID(-2), 'MoveX') == 0 And DllStructGetData(GetAgentByID(-2), 'MoveY') == 0 Then
			If $lHosCount > 6 Then
				Do	; suicide
					RndSleep(1000)
				Until GetIsDead(-2)
				Return False
			EndIf

			$lBlocked += 1
			If $lBlocked < 5 Then
				Move($lDestX, $lDestY, $lRandom)
			ElseIf $lBlocked < 10 Then
				$lAngle += 40
				Move(DllStructGetData(GetAgentByID(-2), 'X')+300*sin($lAngle), DllStructGetData(GetAgentByID(-2), 'Y')+300*cos($lAngle))
			ElseIf IsRecharged($Skill_Heart_of_Shadow) Then
				If $lHosCount==0 And GetDistance() < 1000 Then
					UseSkillEx($Skill_Heart_of_Shadow, -1)
				Else
					UseSkillEx($Skill_Heart_of_Shadow, -2)
				EndIf
				$lBlocked = 0
				$lHosCount += 1
			EndIf
		Else
			If $lBlocked > 0 Then
				; use a timer to avoid spamming /stuck
				If TimerDiff($ChatStuckTimer) > 3000 Then	
					SendChat("stuck", "/")
					$ChatStuckTimer = TimerInit()
				EndIf
				$lBlocked = 0
				$lHosCount = 0
			EndIf

			; target is far, we probably got stuck
			If GetDistance() > 1100 Then
				; dont spam
				If TimerDiff($ChatStuckTimer) > 3000 Then
					SendChat("stuck", "/")
					$ChatStuckTimer = TimerInit()
					RndSleep(GetPing())
					; we werent stuck, but target broke aggro. select a new one
					If GetDistance() > 1100 Then
						TargetNearestEnemy()
					EndIf
				EndIf
			EndIf
		EndIf

	Until ComputeDistance(DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $lDestX, $lDestY) < $lRandom*1.5
	Return True
EndFunc


;~ Wait while staying alive at the same time (like Sleep(..), but without the dying part)
Func WaitFor($lMs)
	If GetIsDead(-2) Then Return
	Local $lAgentArray
	Local $lTimer = TimerInit()
	Do
		RndSleep(100)
		If GetIsDead(-2) Then Return
		$lAgentArray = GetAgentArray(0xDB)
		StayAlive($lAgentArray)
	Until TimerDiff($lTimer) > $lMs
EndFunc


;~ Description: use whatever skills you need to keep yourself alive.
;~ Take agent array as param to more effectively react to the environment (mobs)
Func StayAlive(Const ByRef $lAgentArray)
	If IsRecharged($Skill_Shadow_Form ) Then
		UseSkillEx($Skill_Deadly_Paradox)
		UseSkillEx($Skill_Shadow_Form )
		$timer = TimerInit()
	EndIf

	Local $lEnergy = GetEnergy(-2)
	Local $lAdjCount, $lAreaCount, $lSpellcastCount, $lProximityCount
	Local $lDistance
	For $i = 1 To $lAgentArray[0]
		If DllStructGetData($lAgentArray[$i], "Allegiance") <> 0x3 Then ContinueLoop
		If DllStructGetData($lAgentArray[$i], "HP") <= 0 Then ContinueLoop
		$lDistance = GetPseudoDistance(GetAgentByID(-2), $lAgentArray[$i])
		If $lDistance < 1200*1200 Then
			$lProximityCount += 1
			If $lDistance < $RANGE_SPELLCAST_2 Then
				$lSpellcastCount += 1
				If $lDistance < $RANGE_AREA_2 Then
					$lAreaCount += 1
					If $lDistance < $RANGE_ADJACENT_2 Then
						$lAdjCount += 1
					EndIf
				EndIf
			EndIf
		EndIf
	Next

	UseShadowForm($lProximityCount)

	If IsRecharged($Skill_Shroud_of_Distress) And TimerDiff($timer) < 15000 Then
		If $lSpellcastCount > 0 And DllStructGetData(GetEffect($ID_Shroud_of_Distress), "SkillID") == 0 Then
			UseSkillEx($Skill_Shroud_of_Distress)
		ElseIf DllStructGetData(GetAgentByID(-2), "HP") < 0.6 Then
			UseSkillEx($Skill_Shroud_of_Distress)
		ElseIf $lAdjCount > 20 Then
			UseSkillEx($Skill_Shroud_of_Distress)
			EndIf
		Else
	EndIf

	UseShadowForm($lProximityCount)

	If IsRecharged($Skill_Way_of_Perfection) And TimerDiff($timer) < 15000 Then
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.5 Then
			UseSkillEx($Skill_Way_of_Perfection)
		ElseIf $lAdjCount > 20 Then
			UseSkillEx($Skill_Way_of_Perfection)
			EndIf
		Else
	EndIf

	UseShadowForm($lProximityCount)

	If IsRecharged($Skill_Channeling) And TimerDiff($timer) < 15000 Then
		If $lAreaCount > 5 And GetEffectTimeRemaining($ID_Channeling) < 2000 Then
			UseSkillEx($Skill_Channeling)
			Else
		EndIf
	EndIf

	UseShadowForm($lProximityCount)
EndFunc


;~ Uses Shadow Form if there's anything close and if its recharged
Func UseShadowForm($lProximityCount)
	If $lProximityCount > 0 And IsRecharged($Skill_Shadow_Form ) Then
		UseSkillEx($Skill_Deadly_Paradox)
		UseSkillEx($Skill_Shadow_Form)
		$timer = TimerInit()
	EndIf
EndFunc


;~ Returns a good target for wastrels
;~ Takes the agent array as returned by GetAgentArray(..)
Func GetGoodTarget(Const ByRef $lAgentArray)
	For $i = 1 To $lAgentArray[0]
		If DllStructGetData($lAgentArray[$i], "Allegiance") <> 0x3 Then ContinueLoop
		If DllStructGetData($lAgentArray[$i], "HP") <= 0 Then ContinueLoop
		If GetDistance(GetAgentByID(-2), $lAgentArray[$i]) > $RANGE_NEARBY Then ContinueLoop
		If GetHasHex($lAgentArray[$i]) Then ContinueLoop
		If Not GetIsEnchanted($lAgentArray[$i]) Then ContinueLoop
		Return DllStructGetData($lAgentArray[$i], "ID")
	Next
EndFunc