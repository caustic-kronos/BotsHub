#include <Array.au3>

Func VQDrazachThicket($STATUS)
	If GetMapID() <> $ID_The_Eternal_Grove Then
		Info('Moving to Outpost')
		DistrictTravel($ID_The_Eternal_Grove, $DISTRICT_NAME)
		WaitMapLoading($ID_The_Eternal_Grove, 10000, 2000)
	EndIf
	MoveTo(-6300, 14050)
	Move(-6600, 14500, 5)
	RndSleep(1000)
	WaitMapLoading($ID_Drazach_Thicket, 10000, 2000)

	Local $vanquishRange = $RANGE_SPELLCAST + 400
	Local $waypoints[68][4] = [ _
		[-6506, -16099, " ", $vanquishRange], _
		[-8581, -15354, " ", $vanquishRange], _
		[-8627, -13151, " ", $vanquishRange], _
		[-6683, -12115, " ", $vanquishRange], _
		[-7474, -10044, " ", $vanquishRange], _
		[-6021, -8358, " ", $vanquishRange], _
		[-5184, -6307, " ", $vanquishRange], _
		[-4643, -5336, " ", $vanquishRange], _
		[-7368, -6043, " ", $vanquishRange], _
		[-9514, -6539, " ", $vanquishRange], _
		[-10988, -8177, " ", $vanquishRange], _
		[-11388, -7827, " ", $vanquishRange], _
		[-11291, -5987, " ", $vanquishRange], _
		[-11380, -3787, " ", $vanquishRange], _
		[-10641, -1714, " ", $vanquishRange], _
		[-7019.81, -976.18, " ", $vanquishRange], _
		[-4464.77, 780.87, " ", $vanquishRange], _
		[-7019.81, -976.18, " ", $vanquishRange], _
		[-10575, 489, " ", $vanquishRange], _
		[-11266, 2581, " ", $vanquishRange], _
		[-10444, 4234, " ", $vanquishRange], _
		[-12820, 4153, " ", $vanquishRange], _
		[-12804, 6357, " ", $vanquishRange], _
		[-12074, 8448, " ", $vanquishRange], _
		[-3750.24, 10567.87, " ", $vanquishRange], _
		[-7757.90, 10564.94, " ", $vanquishRange], _
		[637.81, 11362.58, " ", $vanquishRange], _
		[4102, 12772, " ", $vanquishRange], _
		[637.81, 11362.58, " ", $vanquishRange], _
		[-7757.90, 10564.94, " ", $vanquishRange], _
		[-5963, 8337, " ", $vanquishRange], _
		[-5085, 5948, " ", $vanquishRange], _
		[-11289, 10505, " ", $vanquishRange], _
		[-9193, 11175, " ", $vanquishRange], _
		[-7310, 10021, " ", $vanquishRange], _
		[-5196, 10638, " ", $vanquishRange], _
		[-4567, 12753, " ", $vanquishRange], _
		[-5154, 14878, " ", $vanquishRange], _
		[-3280, 16044, " ", $vanquishRange], _
		[-1272, 15113, " ", $vanquishRange], _
		[930, 15165, " ", $vanquishRange], _
		[3106, 14786, " ", $vanquishRange], _
		[5094, 13825, " ", $vanquishRange], _
		[7308, 13779, " ", $vanquishRange], _
		[8654, 12037, " ", $vanquishRange], _
		[8235, 9874, " ", $vanquishRange], _
		[7513, 7790, " ", $vanquishRange], _
		[7774, 5603, " ", $vanquishRange], _
		[9917, 5008, " ", $vanquishRange], _
		[11983, 5810, " ", $vanquishRange], _
		[10193, 4527, " ", $vanquishRange], _
		[10244, 2324, " ", $vanquishRange], _
		[10734, 174, " ", $vanquishRange], _
		[8531, 263, " ", $vanquishRange], _
		[6324, 132, " ", $vanquishRange], _
		[5427, -1890, " ", $vanquishRange], _
		[4553, -3915, " ", $vanquishRange], _
		[3930, -6028, " ", $vanquishRange], _
		[3094, -8066, " ", $vanquishRange], _
		[1736, -6672, " ", $vanquishRange], _
		[235, -5024, " ", $vanquishRange], _
		[985, -8475, " ", $vanquishRange], _
		[-2131, -3371, " ", $vanquishRange], _
		[-3055, 1867, " ", $vanquishRange], _
		[-2427, 5392, " ", $vanquishRange], _
		[-905, 8625, " ", $vanquishRange], _
		[3174, 10834, " ", $vanquishRange], _
		[4105, 9296, " ", $vanquishRange] _
	]
	GoNearestNPCToCoords(-5592, -16263)
	If GetLuxonFaction() > GetKurzickFaction() Then
		Dialog(0x81)
		Sleep(1000)
		Dialog(0x2)
		Sleep(1000)
		Dialog(0x84)
		Sleep(1000)
		Dialog(0x86)
		Sleep(1000)
	Else
		Dialog(0x85)
		Sleep(1000)
		Dialog(0x86)
		Sleep(1000)
	EndIf
	For $waypoint In $waypoints
		If MoveAggroAndKill($waypoints[0], $waypoints[1], $waypoints[2], $waypoints[3]) Then Return 1
	Next
	For $i = UBound($waypoints) - 1 To 0 Step -1
		If MoveAggroAndKill($waypoints[$i][0], $waypoints[$i][1], $waypoints[$i][2], $waypoints[$i][3]) Then Return 1
	Next
EndFunc