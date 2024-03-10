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
; Skill numbers declared to make the code WAY more readable (UseSkillEx($KurzickFaction_SkillToMaintain1) is better than UseSkillEx(1))
Local Const $KurzickFaction_SkillToMaintain1 = 1
Local Const $KurzickFaction_SkillToMaintain2 = 2
Local Const $KurzickFaction_SkillToMaintain3 = 3
Local Const $KurzickFaction_SkillToRun = 4
Local Const $KurzickFaction_Skill1 = 5
Local Const $KurzickFaction_Skill2 = 6
Local Const $KurzickFaction_Pet = 7
Local Const $KurzickFaction_Rez = 8


Local $groupIsAlive = true
Local $DonatePoints = true

;~ Main loop
Func KurzickFactionFarm($STATUS)
	If Not $RenderingEnabled Then ClearMemory()
	
	If GetMapID() <> $ID_House_Zu_Heltzer Then
		Out("Moving to Outpost")
		DistrictTravel($ID_House_Zu_Heltzer, $ID_EUROPE, $ID_FRENCH)
		WaitMapLoading($ID_House_Zu_Heltzer, 10000, 2000)
	EndIf
	
	KurzickFarmSetup()
	GoOut()
	VQ()
	
	If $STATUS <> 'RUNNING' Then Return 2
	Return 0
EndFunc


Func KurzickFarmSetup()
	If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then 
		Out("Turning in Kurzick faction")
		RndSleep(200)
		GoNearestNPCToCoords(5390, 1524)
	
		If $DonatePoints Then
			Do
				DonateFaction("kurzick")
				RndSleep(500)
			Until GetKurzickFaction() < 5000
		Else
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
		Out("Withdrawing gold for shrine's benediction")
		RndSleep(250)
		WithdrawGold(100)
		RndSleep(250)
	EndIf
	
	SwitchMode($ID_HARD_MODE)
EndFunc


Func GoOut()
	Out("Going out")


EndFunc


Func VQ()
	MoveTo(7810, -726)
	MoveTo(10042, -1173)
	Move(10446, -1147, 5)
	WaitMapLoading($ID_Ferndale, 10000, 2000)
	$groupIsAlive = true
	AdlibRegister("CheckPartyWipe", 30000)
	VQKurzick()
	AdlibUnRegister("CheckPartyWipe")
EndFunc


Func CheckPartyWipe()
	Local $deadMembers = 0
	For $i = 1 to GetHeroCount()
		If GetIsDead(GetHeroID($i)) = True Then
			$deadMembers += 1
		EndIf
		If $deadMembers >= 5 Then
			$groupIsAlive = false
			Out("Group wiped, back to oupost to save time.")
		EndIf
	Next
EndFunc


Func VQKurzick();
	Out("Taking blessing")
	GoNearestNPCToCoords(-12909, 15616)
	Dialog(0x81)
	Sleep(1000)
	Dialog(0x2)
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	Dialog(0x86)
	RndSleep(1000)

	Local $enemy = "Mantis Group"
	If MoveToAndAggroAll(-11733, 16729, $enemy) Then Return 1

	If $groupIsAlive Then MoveToAndAggroAll(-11733, 16729, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-11942, 18468, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-11178, 20073, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-11008, 16972, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-11238, 15226, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-9122, 14794, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-10965, 13496, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-10570, 11789, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-10138, 10076, $enemy)

	$enemy = "Dredge Boss Warrior"
	If $groupIsAlive Then MoveToAndAggroAll(-10289, 8329, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-8587, 8739, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-6853, 8496, $enemy)

	$enemy = "Dredge Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-5211, 7841, $enemy)

	$enemy = "Missing Dredge Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-4059, 11325, $enemy)

	$enemy = "Oni and Dredge Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-4328, 6317, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-4454, 4558, $enemy)

	$enemy = "Dredge Patrol Again"
	If $groupIsAlive Then MoveToAndAggroAll(-4650, 2812, $enemy)

	$enemy = "Missing Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-9326, 1601, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-11000, 2219, $enemy, 5000)
	If $groupIsAlive Then MoveToAndAggroAll(-6313, 2778, $enemy)

	$enemy = "Dredge Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-4447, 1055, $enemy, 3000)

	$enemy = "Warden and Dredge Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-3832, -586, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-3143, -2203, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-5780, -4665, $enemy, 3000)

	$enemy = "Warden Group / Mesmer Boss"
	If $groupIsAlive Then MoveToAndAggroAll(-2541, -3848, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-2108, -5549, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-1649, -7250, $enemy, 2500)

	$enemy = "Dredge Patrol and Mesmer Boss"
	If $groupIsAlive Then MoveToAndAggroAll(-666, -8708, $enemy, 2500)

	$enemy = "Warden Group"
	If $groupIsAlive Then MoveToAndAggroAll(526, -10001, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(1947, -11033, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(3108, -12362, $enemy)

	$enemy = "Kirin Group"
	If $groupIsAlive Then MoveToAndAggroAll(2932, -14112, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(2033, -15621, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(1168, -17145, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-254, -18183, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-1934, -18692, $enemy)

	$enemy = "Warden Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(-3676, -18939, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-5433, -18839, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-3679, -18830, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-1925, -18655, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-274, -18040, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(1272, -17199, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(2494, -15940, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(3466, -14470, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(4552, -13081, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(6279, -12777, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(7858, -13545, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(8396, -15221, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(9117, -16820, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(10775, -17393, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(9133, -16782, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(8366, -15202, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(8083, -13466, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(6663, -12425, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(5045, -11738, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(4841, -9983, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(5262, -8277, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(5726, -6588, $enemy)

	$enemy = "Dredge Patrol / Bridge / Boss"
	If $groupIsAlive Then MoveToAndAggroAll(5076, -4955, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(4453, -3315, $enemy, 3000)

	$enemy = "Dredge Patrol"
	If $groupIsAlive Then MoveToAndAggroAll(5823, -2204, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(7468, -1606, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(8591, -248, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(8765, 1497, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(9756, 2945, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(11344, 3722, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(12899, 2912, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(12663, 4651, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(13033, 6362, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(13018, 8121, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(11596, 9159, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(11880, 10895, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(11789, 12648, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(10187, 13369, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(8569, 14054, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(8641, 15803, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(10025, 16876, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(11318, 18944, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(8621, 15831, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(7382, 14594, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(6253, 13257, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(5531, 11653, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(6036, 8799, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(4752, 7594, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(3630, 6240, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(4831, 4966, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(6390, 4141, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(4833, 4958, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(3167, 5498, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(2129, 4077, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(3151, 5502, $enemy)
	If $groupIsAlive Then MoveToAndAggroAll(-2234, 311, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(2474, 4345, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(3294, 5899, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(3072, 7643, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(1836, 8906, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(557, 10116, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-545, 11477, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-1413, 13008, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-2394, 14474, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-3986, 15218, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-5319, 16365, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-5238, 18121, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-7916, 19630, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-3964, 19324, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-2245, 19684, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(-802, 18685, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(74, 17149, $enemy, 3000)
	If $groupIsAlive Then MoveToAndAggroAll(611, 15476, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(2139, 14618, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(3883, 14448, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(5624, 14226, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(7384, 14094, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(8223, 12552, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(7148, 11167, $enemy, 4000)
	If $groupIsAlive Then MoveToAndAggroAll(5427, 10834, $enemy, 10000)
EndFunc

Func MoveToAndAggroAll($x, $y, $s = "", $z = 1450)
	Out("Hunting " & $s)
	Local $iBlocked = 0
	Local $lMe = GetAgentByID(-2)
	Local $coordsX = DllStructGetData($lMe, "X")
	Local $coordsY = DllStructGetData($lMe, "Y")
	
	Move($x, $y)

	Local $oldCoordsX
	Local $oldCoordsY
	Local $nearestEnemy
	While $groupIsAlive And ComputeDistance($coordsX, $coordsY, $x, $y) > 250 And $iBlocked < 20
		$oldCoordsX = $coordsX
		$oldCoordsY = $coordsY
		$nearestEnemy = GetNearestEnemyToAgent(-2)
		If GetDistance($nearestEnemy, -2) < $z And DllStructGetData($nearestEnemy, 'ID') <> 0 Then FightEx($z)
		$lMe = GetAgentByID(-2)
		$coordsX = DllStructGetData($lMe, "X")
		$coordsY = DllStructGetData($lMe, "Y")
		If $oldCoordsX = $coordsX And $oldCoordsY = $coordsY Then
			$iBlocked += 1
			Move($coordsX, $coordsY, 500)
			Sleep(350)
			Move($x, $y)
		EndIf
	WEnd
EndFunc


Func FightEx($z)
	Local $lastId = 99999, $coordinate[2], $timer, $target = GetNearestEnemyToAgent(-2), $targetHP
	Local $distance

	While $groupIsAlive And DllStructGetData($target, 'Id') <> 0 And $distance < $z
		If $target = 0 Then TargetNearestEnemy()
		$distance = GetDistance($target, -2)
		
		If DllStructGetData($target, 'ID') <> 0 And $distance < $z Then
			ChangeTarget($target)
			Sleep(50)
			CallTarget($target)
			Sleep(50)
			Attack($target)
			Sleep(50)
		Else
			$lastId = DllStructGetData($target, 'Id')
			$coordinate[0] = DllStructGetData($target, 'X')
			$coordinate[1] = DllStructGetData($target, 'Y')
			$timer = TimerInit()
			$distance = GetDistance($target, -2)
			While $distance > 1100 And TimerDiff($timer) < 10000
				Move($coordinate[0], $coordinate[1])
				RndSleep(500)
				$distance = GetDistance($target, -2)
			WEnd
		EndIf
		RndSleep(50)
		$timer = TimerInit()
		$target = GetNearestEnemyToAgent(-2)
		$targetHP = DllStructGetData(GetCurrentTarget(), 'HP')
		Local $skillNumber = 1
		While $groupIsAlive And $targetHP > 0.005 And $distance < $z And TimerDiff($timer) < 5000
			If $target <> 0 Then UseSkillEx($skillNumber, $target)
			If $target <> 0 Then Attack($target)
			Sleep(50)
			$target = GetNearestEnemyToAgent(-2)
			$targetHP = DllStructGetData(GetCurrentTarget(), 'HP')
			$distance = GetDistance($target, -2)
			$skillNumber = Mod($skillNumber, 8) + 1
		WEnd
	WEnd
	Sleep(200)
	If GetIsDead(-2) Then Out("Died")
	PickUpItems()
EndFunc