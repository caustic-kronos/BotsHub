#CS ===========================================================================
; Author: TDawg
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $FroggyFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1 E-surge replaced by a ROJ, ineptitude replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '32mn average in NM' & @CRLF _
	& '41mn average in HM with consets (automatically used if HM is on)'

Global $FROGGY_FARM_SETUP = False
Global Const $froggyAggroRange = $RANGE_SPELLCAST + 100
Global Const $ID_Froggy_Quest = 0x339


;~ Main method to farm Froggy
Func FroggyFarm($STATUS)
	If Not $FROGGY_FARM_SETUP Then
		SetupFroggyFarm()
		$FROGGY_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return FroggyFarmLoop()
EndFunc


;~ Froggy farm setup
Func SetupFroggyFarm()
	Info('Setting up farm')
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Gadds_Camp Then DistrictTravel($ID_Gadds_Camp, $DISTRICT_NAME)

	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf

	ResetFailuresCounter()
	Info('Making way to portal')
	MoveTo(-10018, -21892)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(-9550, -20400)
		Move(-9451, -19766)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Sparkfly_Swamp)
	WEnd
	AdlibRegister('TrackGroupStatus', 10000)

	Info('Making way to Bogroot')
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 4671, 7094, 1250)
		MoveAggroAndKill(-4559, -14406, 'I majored in pain, with a minor in suffering', $froggyAggroRange)
		MoveAggroAndKill(-5204, -9831, 'Youre dumb! Youll die, and youll leave a dumb corpse!', $froggyAggroRange)
		MoveAggroAndKill(-928, -8699, 'I am fire! I am war! What are you?', $froggyAggroRange)
		MoveAggroAndKill(4200, -4897, 'Praise Joko!', $froggyAggroRange)
		MoveAggroAndKill(4671, 7094, 'I can outrun a centaur', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 12280, 22585, 1250)
		MoveAggroAndKill(11025, 11710, 'Wow. Thats quality armor.', $froggyAggroRange)
		MoveAggroAndKill(14624, 19314, 'By Ogdens Hammer, what savings!', $froggyAggroRange)
		MoveAggroAndKill(14650, 19417, 'More violets I say. Less violence', $froggyAggroRange)
		MoveAggroAndKill(12280, 22585, 'Guild wars 2 is actually great, you know?', $froggyAggroRange)
	WEnd
	If IsRunFailed() Then Return 1
	AdlibUnRegister('TrackGroupStatus')
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func FroggyFarmLoop()
	ResetFailuresCounter()
	AdlibRegister('TrackGroupStatus', 10000)

	GetRewardRefreshAndTakeFroggyQuest()
	If (ClearFroggyFloor1() == 1 Or ClearFroggyFloor2() == 1) Then
		$FROGGY_FARM_SETUP = False
		Return 1
	EndIf

	AdlibUnRegister('TrackGroupStatus')

	Info('Waiting for timer end')
	Sleep(190000)
	While Not WaitMapLoading($ID_Sparkfly_Swamp)
		Sleep(500)
	WEnd
	Info('Finished Run')
	Return 0
EndFunc


;~ Take quest rewards, refresh quest by entering dungeon and exiting it, then take quest again and reenter dungeon
Func GetRewardRefreshAndTakeFroggyQuest()
	Info('Get quest reward')
	MoveTo(12061, 22485)

	; Quest validation doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12500, 22648))
		RndSleep(250)
		Dialog(0x833907)
		RndSleep(500)
	Next

	Info('Get in dungeon to reset quest')
	MoveTo(12228, 22677)
	MoveTo(12470, 25036)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(12968, 26219)
		Move(13097, 26393)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Bogroot_lvl1)
	WEnd

	Info('Get out of dungeon to reset quest')
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(14876, 632)
		Move(14700, 450)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Sparkfly_Swamp)
	WEnd

	Info('Get quest')
	MoveTo(12061, 22485)
	; Quest validation doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12500, 22648))
		RndSleep(250)
		Dialog(0x833901)
		RndSleep(500)
	Next
	Info('Talk to Tekk if already had quest')
	; Quest pickup doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12500, 22648))
		RndSleep(250)
		Dialog(0x833905)
		RndSleep(500)
	Next

	Info('Get back in')
	MoveTo(12228, 22677)
	MoveTo(12470, 25036)
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(12968, 26219)
		Move(13097, 26393)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Bogroot_lvl1)
	WEnd
EndFunc


;~ Clear Froggy floor 1
Func ClearFroggyFloor1()
	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 6078, 4483, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(17619, 2687, 'Moving near duo', $froggyAggroRange)
		MoveAggroAndKill(18168, 4788, 'Killing one from duo', $froggyAggroRange)
		MoveAggroAndKill(18880, 7749, 'Triggering beacon 1', $froggyAggroRange)

		Info('Getting blessing')
		MoveTo(19063, 7875)
		GoToNPC(GetNearestNPCToCoords(19058, 7952))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(250)

		MoveAggroAndKill(13080, 7822, 'Moving towards nettles cave', $froggyAggroRange)
		MoveAggroAndKill(9946, 6963, 'Nettles cave', $froggyAggroRange)
		MoveAggroAndKill(6078, 4483, 'Nettles cave exit group', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -1501, -8590, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(4960, 1984, 'Triggering beacon 2', $froggyAggroRange)
		MoveAggroAndKill(3567, -278, 'Massive frog cave', $froggyAggroRange)
		MoveAggroAndKill(1763, -607, 'Im getting buried here!', $froggyAggroRange)
		MoveAggroAndKill(224, -2238, 'Massive frog cave exit', $froggyAggroRange)
		MoveAggroAndKill(-1175, -4994, 'Moving through poison jets', $froggyAggroRange)
		MoveAggroAndKill(-115, -8569, 'Ragna-rock n roll!', $froggyAggroRange)
		MoveAggroAndKill(-1501, -8590, 'Triggering beacon 3', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 7171, -17934, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(-115, -8569, 'You played two hours and died like this?!', $froggyAggroRange)
		MoveAggroAndKill(1966, -11018, 'Last cave entrance', $froggyAggroRange)
		MoveAggroAndKill(5775, -12761, 'Youre interrupting my calculations', $froggyAggroRange)
		MoveAggroAndKill(6125, -15820, 'Commander, a word...', $froggyAggroRange)
		Info('Last cave exit')
		MoveTo(7171, -17934)
	WEnd
	If IsRunFailed() Then Return 1

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(7171, -17934)
		Move(7600, -19100)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Bogroot_lvl2)
	WEnd
EndFunc


;~ Clear Froggy floor 2
Func ClearFroggyFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -719, 11140, 1250)
		Info('Getting blessing')
		MoveTo(-11072, -5522)
		GoToNPC(GetNearestNPCToCoords(-11055, -5533))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(250)

		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(-10931, -4584, 'Moving in cave', $froggyAggroRange)
		MoveAggroAndKill(-10121, -3175, 'Moving near river ', $froggyAggroRange)
		MoveAggroAndKill(-9646, -1005, 'Going through river ', $froggyAggroRange)
		MoveAggroAndKill(-8548, 601, 'Moving to incubus cave', $froggyAggroRange)
		MoveAggroAndKill(-7217, 3353, 'Incubus cave entrance', $froggyAggroRange)
		MoveAggroAndKill(-8229, 5519, 'Wololo', $froggyAggroRange)
		MoveAggroAndKill(-9434, 8479, 'Help! The crusaders are attacking our trade routes!', $froggyAggroRange)
		MoveAggroAndKill(-8182, 10187, 'La Hire wishes to kill something', $froggyAggroRange)
		MoveAggroAndKill(-6440, 11526, 'The blood on La Hires sword is almost dry!', $froggyAggroRange)
		MoveAggroAndKill(-3963, 10050, 'It is a good day for La Hire to die... ', $froggyAggroRange)
		MoveAggroAndKill(-1992, 11950, 'Ill be back, Saracen dogs!', $froggyAggroRange)
		MoveAggroAndKill(-719, 11140, 'Triggering incubus cave exit beacon', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 8398, 4358, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(3130, 12731, 'Beetle zone', $froggyAggroRange)
		MoveAggroAndKill(3535, 13860, 'Aiur will be restored', $froggyAggroRange)
		MoveAggroAndKill(5717, 13357, 'Eternal obedience', $froggyAggroRange)
		MoveAggroAndKill(6945, 9820, 'Beetle zone exit', $froggyAggroRange)
		MoveAggroAndKill(8117, 7465, 'Gokir fight', $froggyAggroRange)
		MoveAggroAndKill(8398, 4358, 'Triggering beacon 2', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 19597, -11553, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(9829, -1175, 'The Death Fleet descends', $froggyAggroRange)
		MoveAggroAndKill(10932, -5203, 'I hear and obey', $froggyAggroRange)
		MoveAggroAndKill(13305, -6475, 'Target in range.', $froggyAggroRange)
		MoveAggroAndKill(16841, -5619, 'Keyboss', $froggyAggroRange)

		RndSleep(500)
		PickUpItems()

		Info('Open dungeon door')
		ClearTarget()

		For $i = 1 To 3
			MoveTo(17888, -6243)
			Sleep(GetPing() + 500)
			TargetNearestItem()
			ActionInteract()
			Sleep(GetPing() + 500)
			TargetNearestItem()
			ActionInteract()
			Sleep(GetPing() + 500)
		Next

		MoveAggroAndKill(18363, -8696, 'Going to boss area', $froggyAggroRange)
		MoveAggroAndKill(16631, -11655, 'I will do all that must be done', $froggyAggroRange)
		MoveAggroAndKill(19122, -12284, 'Glory to the Firstborn', $froggyAggroRange)
		MoveAggroAndKill(19597, -11553, 'Triggering boss beacon', $froggyAggroRange)
	WEnd

	Local $largeFroggyAggroRange = $RANGE_SPELLCAST + 300
	Local $questState = 999
	While Not IsRunFailed() And $questState <> 3
		Info('------------------------------------')
		Info('Boss area')
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKill(17494, -14149, 'Our enemies will be undone', $largeFroggyAggroRange)
		MoveAggroAndKill(14641, -15081, 'I live to serve.', $largeFroggyAggroRange)
		MoveAggroAndKill(13934, -17384, 'The mission is in peril!', $largeFroggyAggroRange)
		MoveAggroAndKill(14365, -17681, 'Boss fight', $largeFroggyAggroRange)
		FlagMoveAggroAndKill(15286, -17662, 'All hail! King of the losers!', $largeFroggyAggroRange)
		FlagMoveAggroAndKill(15804, -19107, 'Oh fuck its huge', $largeFroggyAggroRange)

		$questState = DllStructGetData(GetQuestByID($ID_Froggy_Quest), 'LogState')
		Info('Quest state end of boss loop : ' & $questState)
	WEnd
	If IsRunFailed() Then Return 1

	; Chest
	MoveTo(15910, -19134)
	MoveTo(15329, -18948)
	MoveTo(15086, -19132)
	Info('Opening chest')
	; Doubled to secure the looting
	For $i = 1 To 2
		TargetNearestItem()
		ActionInteract()
		RndSleep(2500)
		PickUpItems()
		RndSleep(5000)
	Next
EndFunc