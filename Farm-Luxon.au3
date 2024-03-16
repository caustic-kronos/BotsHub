#include-once
#RequireAdmin
#NoTrayIcon

#include 'GWA2_Headers.au3'
#include 'GWA2.au3'
#include 'Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $LuxonFactionBotVersion = '0.1'

; ==== Constantes ====
Local Const $LuxonFactionSkillbar = ''
Local Const $LuxonFactionInformations = 'For best results, have :' & @CRLF _
	& '- '

Local $groupIsAlive = true
Local $DonatePoints = true


Local Const $ID_unknown_outpost_deposit_points = 193

;~ Main loop
Func LuxonFactionFarm($STATUS)
	If Not $RenderingEnabled Then ClearMemory()
	
	If GetMapID() <> $ID_Aspenwood_Gate_Luxon Then
		Out('Moving to Outpost')
		DistrictTravel($ID_Aspenwood_Gate_Luxon, $ID_EUROPE, $ID_FRENCH)
		WaitMapLoading($ID_Aspenwood_Gate_Luxon, 10000, 2000)
	EndIf
	
	LuxonFarmSetup()
	
	If $STATUS <> 'RUNNING' Then Return 2
	Return VanquishMountQinkai()
EndFunc


Func LuxonFarmSetup()
	If GetLuxonFaction() > (GetMaxLuxonFaction() - 25000) Then 
		Out('Turning in Luxon faction')
		DistrictTravel($ID_unknown_outpost_deposit_points, $ID_EUROPE, $ID_FRENCH)
		WaitMapLoading($ID_unknown_outpost_deposit_points, 10000, 2000)
		RndSleep(200)
		GoNearestNPCToCoords(9076, -1111)

		If $DonatePoints Then
			Do
				DonateFaction('Luxon')
				;DonateFaction(1) ;Could be this call ?
				RndSleep(500)
			Until GetLuxonFaction() < 5000
		Else
			Out('Buying Jade Shards')
			Dialog(131)
			RndSleep(500)
			$temp = Floor(GetLuxonFaction() / 5000)
			$id = 8388609 + ($temp * 256)
			Dialog($id)
			RndSleep(550)
		EndIf
		RndSleep(500)
		DistrictTravel($ID_Aspenwood_Gate_Luxon, $ID_EUROPE, $ID_FRENCH)
		WaitMapLoading($ID_Aspenwood_Gate_Luxon, 10000, 2000)
	EndIf
	
	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Out('Withdrawing gold for shrines benediction')
		RndSleep(250)
		WithdrawGold(100)
		RndSleep(250)
	EndIf
	
	SwitchMode($ID_HARD_MODE)
EndFunc

Func VanquishMountQinkai()
	MoveTo(-4268, 11628)
	MoveTo(-4980, 12425)
	MoveTo(-5493, 13712)
	WaitMapLoading($ID_Mount_Qinkai, 10000, 2000)
	$groupIsAlive = true
	AdlibRegister('CheckPartyWipe', 30000)
	Local $result = VQLuxon()
	AdlibUnRegister('CheckPartyWipe')
	Return $result
EndFunc


Func CheckPartyWipeLuxon()
	Local $deadMembers = 0
	For $i = 1 to GetHeroCount()
		If GetIsDead(GetHeroID($i)) = True Then
			$deadMembers += 1
		EndIf
		If $deadMembers >= 5 Then
			$groupIsAlive = false
			Out('Group wiped, back to oupost to save time.')
		EndIf
	Next
EndFunc


Func VQLuxon()
	Out('Taking blessing')
	GoNearestNPCToCoords(-8394, -9801)
	Dialog(0x85)
	RndSleep(1000)
	Dialog(0x86)
	RndSleep(1000)
	
	If LuxonMoveToAndAggroAll(-13046, -9347, 'Yeti 1') Then Return 1
	If LuxonMoveToAndAggroAll(-17348, -9895, 'Yeti 2') Then Return 1
	If LuxonMoveToAndAggroAll(-14702, -6671, 'Oni and Wallows 1') Then Return 1
	If LuxonMoveToAndAggroAll(-11080, -6126, 'Oni and Wallows 2', 2000) Then Return 1
	If LuxonMoveToAndAggroAll(-13426, -2344, 'Yeti') Then Return 1
	If LuxonMoveToAndAggroAll(-15055, -3226, 'TomTom') Then Return 1
	If LuxonMoveToAndAggroAll(-9448, -283, 'Guardian and Wallows') Then Return 1
	If LuxonMoveToAndAggroAll(-9918, 2826, 'Yeti 1', 2000) Then Return 1
	If LuxonMoveToAndAggroAll(-8721, 7682, 'Yeti 2') Then Return 1
	If LuxonMoveToAndAggroAll(-3250, 8400, 'Yeti 3', $RANGE_SPIRIT) Then Return 1
	If LuxonMoveToAndAggroAll(-7474, -1144, 'Guardian and Wallows 1') Then Return 1
	If LuxonMoveToAndAggroAll(-9666, 2625, 'Guardian and Wallows 2') Then Return 1
	If LuxonMoveToAndAggroAll(-5895, -3959, 'Guardian and Wallows 3') Then Return 1
	If LuxonMoveToAndAggroAll(-3509, -8000, 'Patrol') Then Return 1
	If LuxonMoveToAndAggroAll(-195, -9095, 'Oni 1') Then Return 1
	If LuxonMoveToAndAggroAll(6298, -8707, 'Oni 2') Then Return 1
	If LuxonMoveToAndAggroAll(3981, -3295, 'Bridge') Then Return 1
	If LuxonMoveToAndAggroAll(496, -2581, 'Naga 1', 2000) Then Return 1
	If LuxonMoveToAndAggroAll(2069, 1127, 'Guardian and Wallows 1') Then Return 1
	If LuxonMoveToAndAggroAll(5859, 1599, 'Guardian and Wallows 2') Then Return 1
	If LuxonMoveToAndAggroAll(6412, 6572, 'Guardian and Wallows 3') Then Return 1
	If LuxonMoveToAndAggroAll(8550, 7000, 'Naga 1', $RANGE_SPIRIT) Then Return 1
	If LuxonMoveToAndAggroAll(11000, 8250, 'Naga 2', $RANGE_SPIRIT) Then Return 1
	If LuxonMoveToAndAggroAll(14403, 6938, 'Oni 1') Then Return 1
	If LuxonMoveToAndAggroAll(18080, 3127, 'Oni 2') Then Return 1
	If LuxonMoveToAndAggroAll(13518, -35, 'Naga 1') Then Return 1
	If LuxonMoveToAndAggroAll(13450, -6084, 'Naga 2', 4000) Then Return 1
	If LuxonMoveToAndAggroAll(13764, -4816, 'Naga 3', 4000) Then Return 1
	If LuxonMoveToAndAggroAll(13450, -6084, 'Naga 4', 4000) Then Return 1
	If LuxonMoveToAndAggroAll(13764, -4816, 'Naga 5', 4000) Then Return 1
	Out('The end : zone should be vanquished')
	If $STATUS <> 'RUNNING' Then Return 2
	Return 0
EndFunc

Func LuxonMoveToAndAggroAll($x, $y, $s = '', $range = 1450)
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
		If GetDistance($nearestEnemy, -2) < $range And DllStructGetData($nearestEnemy, 'ID') <> 0 Then LuxonKillAllEnemies()
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


Func LuxonKillAllEnemies()
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