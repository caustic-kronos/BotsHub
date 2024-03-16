#include-once
#RequireAdmin
#NoTrayIcon

#include 'GWA2_Headers.au3'
#include 'GWA2.au3'
#include 'Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $KurzickFactionBotVersion = '0.1'

; ==== Constantes ====
Local Const $KurzickFactionSkillbar = 'OgcTcZ88Z6u844AiHRnJuE3R4AA'
Local Const $KurzickFactionInformations = 'For best results, have :' & @CRLF _
	& '- '

Local $groupIsAlive = true
Local $DonatePoints = true

;~ Main loop
Func KurzickFactionFarm($STATUS)
	If Not $RenderingEnabled Then ClearMemory()
	
	If GetMapID() <> $ID_House_Zu_Heltzer Then
		Out('Moving to Outpost')
		DistrictTravel($ID_House_Zu_Heltzer, $ID_EUROPE, $ID_FRENCH)
		WaitMapLoading($ID_House_Zu_Heltzer, 10000, 2000)
	EndIf
	
	KurzickFarmSetup()
	
	If $STATUS <> 'RUNNING' Then Return 2
	AdlibRegister('CheckPartyWipeKurzick', 30000)
	Local $result = VanquishFerndale($STATUS)
	AdlibUnRegister('CheckPartyWipeKurzick')
	;Temporarily change a failure into a pause for debugging :
	If $result == 1 Then $result = 2
	Return $result
EndFunc


Func KurzickFarmSetup()
	If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then 
		Out('Turning in Kurzick faction')
		RndSleep(200)
		GoNearestNPCToCoords(5390, 1524)
	
		If $DonatePoints Then
			Do
				DonateFaction('kurzick')
				RndSleep(500)
			Until GetKurzickFaction() < 5000
		Else
			Out("Buying Amber fragments")
			Dialog(131)
			RndSleep(550)
			Local $temp = Floor(GetKurzickFaction() / 5000)
			Local $id = 8388609 + ($temp * 256)
			Dialog($id)
			RndSleep(550)
		EndIf
		RndSleep(500)
	EndIf
	
	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Out('Withdrawing gold for shrines benediction')
		RndSleep(250)
		WithdrawGold(100)
		RndSleep(250)
	EndIf
	
	SwitchMode($ID_HARD_MODE)
EndFunc


Func CheckPartyWipeKurzick()
	Local $deadMembers = 0
	For $i = 1 to GetHeroCount()
		If GetIsDead(GetHeroID($i)) = True Then
			$deadMembers += 1
		EndIf
		If $deadMembers >= 5 Then
			$groupIsAlive = false
			Out('Group wiped, back to oupost to save time.')
			ExitLoop
		EndIf
	Next
EndFunc


Func VanquishFerndale($STATUS)
	MoveTo(7810, -726)
	MoveTo(10042, -1173)
	Move(10446, -1147, 5)
	WaitMapLoading($ID_Ferndale, 10000, 2000)
	$groupIsAlive = true

	Out('Taking blessing')
	GoNearestNPCToCoords(-12909, 15616)
	Dialog(0x81)
	Sleep(1000)
	Dialog(0x2)
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	Dialog(0x86)
	RndSleep(1000)

	If MoveToAndAggroAll(-11733, 16729, 'Mantis Group 1') Then Return 1
	If MoveToAndAggroAll(-11942, 18468, 'Mantis Group 2') Then Return 1
	If MoveToAndAggroAll(-11178, 20073, 'Mantis Group 3') Then Return 1
	If MoveToAndAggroAll(-11008, 16972, 'Mantis Group 4') Then Return 1
	If MoveToAndAggroAll(-11238, 15226, 'Mantis Group 5') Then Return 1
	If MoveToAndAggroAll(-9122, 14794, 'Mantis Group 6') Then Return 1
	If MoveToAndAggroAll(-10965, 13496, 'Mantis Group 7') Then Return 1
	If MoveToAndAggroAll(-10570, 11789, 'Mantis Group 8') Then Return 1
	If MoveToAndAggroAll(-10138, 10076, 'Mantis Group 9') Then Return 1
	If MoveToAndAggroAll(-10289, 8329, 'Mantis Group 10') Then Return 1
	
	If MoveToAndAggroAll(-8587, 8739, 'Dredge Boss Warrior 1') Then Return 1
	If MoveToAndAggroAll(-6853, 8496, 'Dredge Boss Warrior 2') Then Return 1
	
	If MoveToAndAggroAll(-5211, 7841, 'Dredge Patrol') Then Return 1
	
	If MoveToAndAggroAll(-4059, 11325, 'Missing Dredge Patrol') Then Return 1
	
	If MoveToAndAggroAll(-4328, 6317, 'Oni and Dredge Patrol 1') Then Return 1
	If MoveToAndAggroAll(-4454, 4558, 'Oni and Dredge Patrol 2') Then Return 1

	If MoveToAndAggroAll(-4650, 2812, 'Dredge Patrol Again') Then Return 1

	If MoveToAndAggroAll(-9326, 1601, 'Missing Patrol 1') Then Return 1
	If MoveToAndAggroAll(-11000, 2219, 'Missing Patrol 2', 5000) Then Return 1
	If MoveToAndAggroAll(-6313, 2778, 'Missing Patrol 3') Then Return 1

	If MoveToAndAggroAll(-4447, 1055, 'Dredge Patrol', 3000) Then Return 1

	If MoveToAndAggroAll(-3832, -586, 'Warden and Dredge Patrol 1', 3000) Then Return 1
	If MoveToAndAggroAll(-3143, -2203, 'Warden and Dredge Patrol 2', 3000) Then Return 1
	If MoveToAndAggroAll(-5780, -4665, 'Warden and Dredge Patrol 3', 3000) Then Return 1

	If MoveToAndAggroAll(-2541, -3848, 'Warden Group / Mesmer Boss 1', 3000) Then Return 1
	If MoveToAndAggroAll(-2108, -5549, 'Warden Group / Mesmer Boss 2', 3000) Then Return 1
	If MoveToAndAggroAll(-1649, -7250, 'Warden Group / Mesmer Boss 3', 2500) Then Return 1

	If MoveToAndAggroAll(0, -10000, 'Dredge Patrol and Mesmer Boss', $RANGE_SPIRIT) Then Return 1

	If MoveToAndAggroAll(526, -10001, 'Warden Group 1') Then Return 1
	If MoveToAndAggroAll(1947, -11033, 'Warden Group 2') Then Return 1
	If MoveToAndAggroAll(3108, -12362, 'Warden Group 3') Then Return 1

	If MoveToAndAggroAll(2932, -14112, 'Kirin Group 1') Then Return 1
	If MoveToAndAggroAll(2033, -15621, 'Kirin Group 2') Then Return 1
	If MoveToAndAggroAll(1168, -17145, 'Kirin Group 3') Then Return 1
	If MoveToAndAggroAll(-254, -18183, 'Kirin Group 4') Then Return 1
	If MoveToAndAggroAll(-1934, -18692, 'Kirin Group 5') Then Return 1

	If MoveToAndAggroAll(-3676, -18939, 'Warden Patrol 1') Then Return 1
	If MoveToAndAggroAll(-5433, -18839, 'Warden Patrol 2', 3000) Then Return 1
	If MoveToAndAggroAll(-3679, -18830, 'Warden Patrol 3') Then Return 1
	If MoveToAndAggroAll(-1925, -18655, 'Warden Patrol 4') Then Return 1
	If MoveToAndAggroAll(-274, -18040, 'Warden Patrol 5') Then Return 1
	If MoveToAndAggroAll(1272, -17199, 'Warden Patrol 6') Then Return 1
	If MoveToAndAggroAll(2494, -15940, 'Warden Patrol 7') Then Return 1
	If MoveToAndAggroAll(3466, -14470, 'Warden Patrol 8') Then Return 1
	If MoveToAndAggroAll(4552, -13081, 'Warden Patrol 9') Then Return 1
	If MoveToAndAggroAll(6279, -12777, 'Warden Patrol 10') Then Return 1
	If MoveToAndAggroAll(7858, -13545, 'Warden Patrol 11') Then Return 1
	If MoveToAndAggroAll(8396, -15221, 'Warden Patrol 12') Then Return 1
	If MoveToAndAggroAll(9117, -16820, 'Warden Patrol 13') Then Return 1
	If MoveToAndAggroAll(10775, -17393, 'Warden Patrol 14', 3000) Then Return 1
	If MoveToAndAggroAll(9133, -16782, 'Warden Patrol 15') Then Return 1
	If MoveToAndAggroAll(8366, -15202, 'Warden Patrol 16') Then Return 1
	If MoveToAndAggroAll(8083, -13466, 'Warden Patrol 17') Then Return 1
	If MoveToAndAggroAll(6663, -12425, 'Warden Patrol 18') Then Return 1
	If MoveToAndAggroAll(5045, -11738, 'Warden Patrol 19') Then Return 1
	If MoveToAndAggroAll(4841, -9983, 'Warden Patrol 20') Then Return 1
	If MoveToAndAggroAll(5262, -8277, 'Warden Patrol 21') Then Return 1
	If MoveToAndAggroAll(5726, -6588, 'Warden Patrol 22') Then Return 1

	If MoveToAndAggroAll(5076, -4955, 'Dredge Patrol / Bridge / Boss 1') Then Return 1
	If MoveToAndAggroAll(4453, -3315, 'Dredge Patrol / Bridge / Boss 2', 3000) Then Return 1

	If MoveToAndAggroAll(5823, -2204, 'Dredge Patrol 1') Then Return 1
	If MoveToAndAggroAll(7468, -1606, 'Dredge Patrol 2') Then Return 1
	If MoveToAndAggroAll(8591, -248, 'Dredge Patrol 3', 3000) Then Return 1
	If MoveToAndAggroAll(8765, 1497, 'Dredge Patrol 4') Then Return 1
	If MoveToAndAggroAll(9756, 2945, 'Dredge Patrol 5') Then Return 1
	If MoveToAndAggroAll(11344, 3722, 'Dredge Patrol 6') Then Return 1
	If MoveToAndAggroAll(14000, 1500, 'Oni Spot', $RANGE_SPIRIT) Then Return 1
	If MoveToAndAggroAll(12899, 2912, 'Dredge Patrol 7', 3000) Then Return 1
	If MoveToAndAggroAll(12663, 4651, 'Dredge Patrol 8') Then Return 1
	If MoveToAndAggroAll(13033, 6362, 'Dredge Patrol 9') Then Return 1
	If MoveToAndAggroAll(13018, 8121, 'Dredge Patrol 10') Then Return 1
	If MoveToAndAggroAll(11596, 9159, 'Dredge Patrol 11') Then Return 1
	If MoveToAndAggroAll(11880, 10895, 'Dredge Patrol 12') Then Return 1
	If MoveToAndAggroAll(11789, 12648, 'Dredge Patrol 13') Then Return 1
	If MoveToAndAggroAll(10187, 13369, 'Dredge Patrol 14') Then Return 1
	If MoveToAndAggroAll(8569, 14054, 'Dredge Patrol 15', 3000) Then Return 1
	If MoveToAndAggroAll(8641, 15803, 'Dredge Patrol 16', 3000) Then Return 1
	If MoveToAndAggroAll(10025, 16876, 'Dredge Patrol 17', 3000) Then Return 1
	If MoveToAndAggroAll(11318, 18944, 'Dredge Patrol 18', 3000) Then Return 1
	If MoveToAndAggroAll(8621, 15831, 'Dredge Patrol 19', 3000) Then Return 1
	If MoveToAndAggroAll(7382, 14594, 'Dredge Patrol 20', 3000) Then Return 1
	If MoveToAndAggroAll(6253, 13257, 'Dredge Patrol 21', 3000) Then Return 1
	If MoveToAndAggroAll(5531, 11653, 'Dredge Patrol 22', 3000) Then Return 1
	If MoveToAndAggroAll(6036, 8799, 'Dredge Patrol 23') Then Return 1
	If MoveToAndAggroAll(4752, 7594, 'Dredge Patrol 24') Then Return 1
	If MoveToAndAggroAll(3630, 6240, 'Dredge Patrol 25') Then Return 1
	If MoveToAndAggroAll(4831, 4966, 'Dredge Patrol 26') Then Return 1
	If MoveToAndAggroAll(6390, 4141, 'Dredge Patrol 27') Then Return 1
	If MoveToAndAggroAll(4833, 4958, 'Dredge Patrol 28') Then Return 1
	If MoveToAndAggroAll(3167, 5498, 'Dredge Patrol 29') Then Return 1
	If MoveToAndAggroAll(2129, 4077, 'Dredge Patrol 30', 3000) Then Return 1
	If MoveToAndAggroAll(3151, 5502, 'Dredge Patrol 31') Then Return 1
	If MoveToAndAggroAll(-2234, 311, 'Dredge Patrol 32', 3000) Then Return 1
	If MoveToAndAggroAll(2474, 4345, 'Dredge Patrol 33', 3000) Then Return 1
	If MoveToAndAggroAll(3294, 5899, 'Dredge Patrol 34', 3000) Then Return 1
	If MoveToAndAggroAll(3072, 7643, 'Dredge Patrol 35', 3000) Then Return 1
	If MoveToAndAggroAll(1836, 8906, 'Dredge Patrol 36', 3000) Then Return 1
	If MoveToAndAggroAll(557, 10116, 'Dredge Patrol 37', 3000) Then Return 1
	If MoveToAndAggroAll(-545, 11477, 'Dredge Patrol 38', 3000) Then Return 1
	If MoveToAndAggroAll(-1413, 13008, 'Dredge Patrol 39', 3000) Then Return 1
	If MoveToAndAggroAll(-2394, 14474, 'Dredge Patrol 40', 3000) Then Return 1
	If MoveToAndAggroAll(-3986, 15218, 'Dredge Patrol 41', 3000) Then Return 1
	If MoveToAndAggroAll(-5319, 16365, 'Dredge Patrol 42', 3000) Then Return 1
	If MoveToAndAggroAll(-5238, 18121, 'Dredge Patrol 43', 3000) Then Return 1
	If MoveToAndAggroAll(-7916, 19630, 'Dredge Patrol 44', 3000) Then Return 1
	If MoveToAndAggroAll(-3964, 19324, 'Dredge Patrol 45', 3000) Then Return 1
	If MoveToAndAggroAll(-2245, 19684, 'Dredge Patrol 46', 3000) Then Return 1
	If MoveToAndAggroAll(-802, 18685, 'Dredge Patrol 47', 3000) Then Return 1
	If MoveToAndAggroAll(74, 17149, 'Dredge Patrol 48', 3000) Then Return 1
	If MoveToAndAggroAll(611, 15476, 'Dredge Patrol 49', 4000) Then Return 1
	If MoveToAndAggroAll(2139, 14618, 'Dredge Patrol 50', 4000) Then Return 1
	If MoveToAndAggroAll(3883, 14448, 'Dredge Patrol 51', 4000) Then Return 1
	If MoveToAndAggroAll(5624, 14226, 'Dredge Patrol 52', 4000) Then Return 1
	If MoveToAndAggroAll(7384, 14094, 'Dredge Patrol 53', 4000) Then Return 1
	If MoveToAndAggroAll(8223, 12552, 'Dredge Patrol 54', 4000) Then Return 1
	If MoveToAndAggroAll(7148, 11167, 'Dredge Patrol 55', 4000) Then Return 1
	If MoveToAndAggroAll(5427, 10834, 'Dredge Patrol 56', 10000) Then Return 1
	Out('The end : zone should be vanquished')
	If $STATUS <> 'RUNNING' Then Return 2
	Return 0
EndFunc

Func MoveToAndAggroAll($x, $y, $s = '', $range = 1450)
	Out('Hunting ' & $s)
	Local $blocked = 0
	Local $me = GetAgentByID(-2)
	Local $coordsX = DllStructGetData($me, 'X')
	Local $coordsY = DllStructGetData($me, 'Y')
	
	Move($x, $y)

	Local $oldCoordsX
	Local $oldCoordsY
	Local $nearestEnemy
	While $groupIsAlive And ComputeDistance($coordsX, $coordsY, $x, $y) > $RANGE_NEARBY And $blocked < 10
		$oldCoordsX = $coordsX
		$oldCoordsY = $coordsY
		$nearestEnemy = GetNearestEnemyToAgent(-2)
		If GetDistance($nearestEnemy, -2) < $range And DllStructGetData($nearestEnemy, 'ID') <> 0 Then KillAllEnemies()
		$me = GetAgentByID(-2)
		$coordsX = DllStructGetData($me, 'X')
		$coordsY = DllStructGetData($me, 'Y')
		If $oldCoordsX = $coordsX And $oldCoordsY = $coordsY Then
			$blocked += 1
			Move($coordsX, $coordsY, 500)
			RndSleep(500)
			Move($x, $y)
		EndIf
		RndSleep(500)
		CheckForChests($RANGE_SPIRIT)
	WEnd
	If Not $groupIsAlive Then Return True
EndFunc


Func KillAllEnemies()
	Local $skillNumber = 1, $foesCount = 999, $target = GetNearestEnemyToAgent(-2), $targetId = -1
	GetAlmostInRangeOfAgent($target)

	While $groupIsAlive And $foesCount > 0
		$target = GetNearestEnemyToAgent(-2)
		If DllStructGetData($target, 'ID') <> $targetId Then
			$targetId = DllStructGetData($target, 'ID')
			CallTarget($target)
		EndIf
		RndSleep(50)
		While Not IsRecharged($skillNumber) And $skillNumber < 9
			$skillNumber += 1
		WEnd
		If $skillNumber < 9 Then 
			UseSkillEx($skillNumber, $target)
			RndSleep(50)
		Else
			Attack($target)
			RndSleep(1000)
		EndIf
		$skillNumber = 1
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST)
	WEnd
	RndSleep(50)
	PickUpItems()
EndFunc