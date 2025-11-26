#include <Array.au3>

Func VQSilentSurf($STATUS)
	If GetMapID() <> $ID_Leviathan_Pits Then
		Info('Moving to Outpost')
		DistrictTravel($ID_Leviathan_Pits, $DISTRICT_NAME)
		WaitMapLoading($ID_Leviathan_Pits, 10000, 2000)
	EndIf
	MoveTo(8800, -26150)
	Move(9000, -26600, 5)
	RandomSleep(1000)
	WaitMapLoading($ID_Silent_Surf, 10000, 2000)

	Local $vanquishRange = $RANGE_SPELLCAST + 400
	Local $waypoints[67][4] = [ _
		[12805, 20193, " "], _
		[11341, 16798, " "], _
		[11087, 13991, " "], _
		[11080, 9097, " "], _
		[9658, 5413, " "], _
		[10560, 749, " "], _
		[8586, 2593, " "], _
		[7046, -230, " "], _
		[5482, 2172, " "], _
		[6713, -3883, " "], _
		[8556, -5771, " "], _
		[8388, -7369, " "], _
		[5573, -7854, " "], _
		[9949, -10783, " "], _
		[7667, -13572, " "], _
		[7418, -163297, " "], _
		[9788, -17730, " "], _
		[9223, -18514, " "], _
		[6124, -13371, " "], _
		[8808, -12721, " "], _
		[10194, -16206, " "], _
		[4083, -15022, " "], _
		[1525, -14592, " "], _
		[-460, -18187, " "], _
		[-80, -13881, " "], _
		[1802, -11686, " "], _
		[-3053, -11475, " "], _
		[-4579, -10773, " "], _
		[-6200, -8096, " "], _
		[-3135, -6388, " "], _
		[-4144, -3728, " "], _
		[-4570, -2901, " "], _
		[-4941, -160, " "], _
		[-5722, 2696, " "], _
		[-3142, 3801, " "], _
		[-4469, 6183, " "], _
		[-2125, 6504, " "], _
		[-5109, 8999, " "], _
		[-5250, 9219, " "], _
		[-6784, 6498, " "], _
		[-6303, 14473, " "], _
		[-4104, 15650, " "], _
		[-1907, 12921, " "], _
		[1394, 15151, " "], _
		[4780, 15895, " "], _
		[6456, 20196, " "], _
		[6912, 22456, " "], _
		[4453, 16759, " "], _
		[2593, 11628, " "], _
		[1632, 8241, " "], _
		[7432.49, 8187.56, " "], _
		[7780.27, 10921.55, " "], _
		[2912, 9831, " "], _
		[5245, 8280, " "], _
		[4124, 6478, " "], _
		[6676, 6019, " "], _
		[9859, 6957, " "], _
		[9400, 5461, " "], _
		[4254, 4016, " "], _
		[558, 3252, " "], _
		[1563, 79, " "], _
		[-480, -1088, " "], _
		[-136, -4944, " "], _
		[124, -5285, " "], _
		[1837, -6615, " "], _
		[5287, -9242, " "], _
		[3288, -3142, " "] _
	]
	GoNearestNPCToCoords(11303, 24406)
	If GetKurzickFaction() > GetLuxonFaction() Then
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
		If MoveAggroAndKill($waypoints[0], $waypoints[1], $waypoints[2]) == $FAIL Then Return $FAIL
	Next
	For $i = UBound($waypoints) - 1 To 0 Step -1
		If MoveAggroAndKill($waypoints[$i][0], $waypoints[$i][1], $waypoints[$i][2]) == $FAIL Then Return $FAIL
	Next
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc
