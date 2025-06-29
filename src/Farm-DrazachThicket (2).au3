#include <Array.au3>
; Factions
Global Const $ID_Drazach_Thicket            = 195
Global Const $ID_Silent_Surf                = 203
Global Const $ID_The_Eternal_Grove          = 222
Global Const $ID_Leviathan_Pits             = 279

Func VQDrazachThicket($STATUS)

    ; Travel to House zu Heltzer to donate Kurzick faction if needed
    If GetMapID() <> $ID_House_zu_Heltzer Then
        Info('Moving to House zu Heltzer to donate Kurzick faction')
        DistrictTravel($ID_House_zu_Heltzer, $DISTRICT_NAME)
        WaitMapLoading($ID_House_zu_Heltzer, 10000, 2000)
    EndIf

    ; Donation block
    If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then
        Info('Turning in Kurzick faction')
        GoNearestNPCToCoords(5390, 1524) ;  NPC in House zu Heltzer
        While GetKurzickFaction() >= 5000
            DonateFaction('kurzick')
            RndSleep(500)
        WEnd
    EndIf

    ; Then travel to Eternal Grove outpost if not there yet
    If GetMapID() <> $ID_The_Eternal_Grove Then
        Info('Moving to Outpost (The Eternal Grove)')
        DistrictTravel($ID_The_Eternal_Grove, $DISTRICT_NAME)
        WaitMapLoading($ID_The_Eternal_Grove, 10000, 2000)
    EndIf

    ; Switch to hard mode if needed
    SwitchMode($ID_HARD_MODE)

    ; Now go into Drazach Thicket and start vanquish
    MoveTo(-6300, 14050)
    Move(-6600, 14500, 5)
    RndSleep(1000)
    WaitMapLoading($ID_Drazach_Thicket, 10000, 2000)

    ; Use consumables
    UseConsumable($ID_Birthday_Cupcake)
    UseConsumable($ID_Candy_Apple)
    UseConsumable($ID_Candy_Corn)
    UseConsumable($ID_Golden_Egg)
    UseConsumable($ID_Honeycomb)
    UseConsumable($ID_Essence_of_Celerity)
    UseConsumable($ID_Armor_of_Salvation)
    UseConsumable($ID_Grail_of_Might)											

    ; Dialog with NPC before vanquish
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

    ; Vanquish waypoints
    Local $vanquishRange = $RANGE_SPELLCAST + 400
    If MoveAggroAndKill(-6506, -16099, "Waypoint 1") Then Return 1
    If MoveAggroAndKill(-8581, -15354, "Waypoint 2") Then Return 1
    If MoveAggroAndKill(-8627, -13151, "Waypoint 3") Then Return 1
    If MoveAggroAndKill(-6683, -12115, "Waypoint 4") Then Return 1
    If MoveAggroAndKill(-7474, -10044, "Waypoint 5") Then Return 1
    If MoveAggroAndKill(-6021, -8358, "Waypoint 6") Then Return 1
    If MoveAggroAndKill(-5184, -6307, "Waypoint 7") Then Return 1
    If MoveAggroAndKill(-4643, -5336, "Waypoint 8") Then Return 1
    If MoveAggroAndKill(-7368, -6043, "Waypoint 9") Then Return 1
    If MoveAggroAndKill(-9514, -6539, "Waypoint 10") Then Return 1
    If MoveAggroAndKill(-10988, -8177, "Waypoint 11") Then Return 1
    If MoveAggroAndKill(-11388, -7827, "Waypoint 12") Then Return 1
    If MoveAggroAndKill(-11291, -5987, "Waypoint 13") Then Return 1
    If MoveAggroAndKill(-11380, -3787, "Waypoint 14") Then Return 1
    If MoveAggroAndKill(-10641, -1714, "Waypoint 15") Then Return 1
    If MoveAggroAndKill(-7019.81, -976.18, "Waypoint 16") Then Return 1
    If MoveAggroAndKill(-4464.77, 780.87, "Waypoint 17") Then Return 1
    If MoveAggroAndKill(-7019.81, -976.18, "Waypoint 18") Then Return 1
    If MoveAggroAndKill(-10575, 489, "Waypoint 19") Then Return 1
    If MoveAggroAndKill(-11266, 2581, "Waypoint 20") Then Return 1
    If MoveAggroAndKill(-10444, 4234, "Waypoint 21") Then Return 1
    If MoveAggroAndKill(-12820, 4153, "Waypoint 22") Then Return 1
    If MoveAggroAndKill(-12804, 6357, "Waypoint 23") Then Return 1
    If MoveAggroAndKill(-12074, 8448, "Waypoint 24") Then Return 1
    If MoveAggroAndKill(-3750.24, 10567.87, "Waypoint 25") Then Return 1
    If MoveAggroAndKill(-7757.90, 10564.94, "Waypoint 26") Then Return 1
    If MoveAggroAndKill(637.81, 11362.58, "Waypoint 27") Then Return 1
    If MoveAggroAndKill(4102, 12772, "Waypoint 28") Then Return 1
    If MoveAggroAndKill(637.81, 11362.58, "Waypoint 29") Then Return 1
    If MoveAggroAndKill(-7757.90, 10564.94, "Waypoint 30") Then Return 1
    If MoveAggroAndKill(-5963, 8337, "Waypoint 31") Then Return 1
    If MoveAggroAndKill(-5085, 5948, "Waypoint 32") Then Return 1
    If MoveAggroAndKill(-11289, 10505, "Waypoint 33") Then Return 1
    If MoveAggroAndKill(-9193, 11175, "Waypoint 34") Then Return 1
    If MoveAggroAndKill(-7310, 10021, "Waypoint 35") Then Return 1
    If MoveAggroAndKill(-5196, 10638, "Waypoint 36") Then Return 1
    If MoveAggroAndKill(-4567, 12753, "Waypoint 37") Then Return 1
    If MoveAggroAndKill(-5154, 14878, "Waypoint 38") Then Return 1
    If MoveAggroAndKill(-3280, 16044, "Waypoint 39") Then Return 1
    If MoveAggroAndKill(-1272, 15113, "Waypoint 40") Then Return 1
    If MoveAggroAndKill(930, 15165, "Waypoint 41") Then Return 1
    If MoveAggroAndKill(3106, 14786, "Waypoint 42") Then Return 1
    If MoveAggroAndKill(5094, 13825, "Waypoint 43") Then Return 1
    If MoveAggroAndKill(7308, 13779, "Waypoint 44") Then Return 1
    If MoveAggroAndKill(8654, 12037, "Waypoint 45") Then Return 1
    If MoveAggroAndKill(8235, 9874, "Waypoint 46") Then Return 1
    If MoveAggroAndKill(7513, 7790, "Waypoint 47") Then Return 1
    If MoveAggroAndKill(7774, 5603, "Waypoint 48") Then Return 1
    If MoveAggroAndKill(9917, 5008, "Waypoint 49") Then Return 1
    If MoveAggroAndKill(11983, 5810, "Waypoint 50") Then Return 1
    If MoveAggroAndKill(10193, 4527, "Waypoint 51") Then Return 1
    If MoveAggroAndKill(10244, 2324, "Waypoint 52") Then Return 1
    If MoveAggroAndKill(10734, 174, "Waypoint 53") Then Return 1
    If MoveAggroAndKill(8531, 263, "Waypoint 54") Then Return 1
    If MoveAggroAndKill(6324, 132, "Waypoint 55") Then Return 1
    If MoveAggroAndKill(5427, -1890, "Waypoint 56") Then Return 1
    If MoveAggroAndKill(4553, -3915, "Waypoint 57") Then Return 1
    If MoveAggroAndKill(3930, -6028, "Waypoint 58") Then Return 1
    If MoveAggroAndKill(3094, -8066, "Waypoint 59") Then Return 1
    If MoveAggroAndKill(1736, -6672, "Waypoint 60") Then Return 1
    If MoveAggroAndKill(235, -5024, "Waypoint 61") Then Return 1
    If MoveAggroAndKill(985, -8475, "Waypoint 62") Then Return 1
    If MoveAggroAndKill(-2131, -3371, "Waypoint 63") Then Return 1
    If MoveAggroAndKill(-3055, 1867, "Waypoint 64") Then Return 1
    If MoveAggroAndKill(-2427, 5392, "Waypoint 65") Then Return 1
    If MoveAggroAndKill(-905, 8625, "Waypoint 66") Then Return 1
    If MoveAggroAndKill(3174, 10834, "Waypoint 67") Then Return 1
    If MoveAggroAndKill(4105, 9296, "Waypoint 68") Then Return 1
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return 1
	EndIf
	Return 0
    EndFunc