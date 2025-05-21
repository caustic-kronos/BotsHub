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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $FroggyFarmerSkillbar = ''
Global Const $FroggyFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1 E-surge replaced by a ROJ, ineptitude replaced by blinding surge)' & @CRLF _
	& '32m average in NM' & @CRLF _
	& '41m average in HM with consets (automatically used if HM is on)' & @CRLF _

Global $FROGGY_FARM_SETUP = False
Global $FroggyDeathsCount = 0


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

	$FroggyDeathsCount = 0
	Info('Making way to portal')
	MoveTo(-10018, -21892)
	MoveTo(-9550, -20400)
	Move(-9451, -19766)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Sparkfly_Swamp)
		Sleep(500)
		MoveTo(-9550, -20400)
		Move(-9451, -19766)
	WEnd
	AdlibRegister('FroggyGroupIsAlive', 10000)

	Local $aggroRange = $RANGE_SPELLCAST + 100
	Info('Making way to Bogroot')
	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (4671, 7094, 1250)
		MoveAggroAndKill(-4559, -14406, 'I majored in pain, with a minor in suffering', $aggroRange)
		MoveAggroAndKill(-5204, -9831, 'Youre dumb! Youll die, and youll leave a dumb corpse!', $aggroRange)
		MoveAggroAndKill(-928, -8699, 'I am fire! I am war! What are you?', $aggroRange)
		MoveAggroAndKill(4200, -4897, 'Praise Joko!', $aggroRange)
		MoveAggroAndKill(4671, 7094, 'I can outrun a centaur', $aggroRange)
		If FroggyIsFailure() Then Return 1
	WEnd

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (12280, 22585, 1250)
		MoveAggroAndKill(11570, 6120, 'More violets I say. Less violence', $aggroRange)
		MoveAggroAndKill(11025, 11710, 'Wow. Thats quality armor.', $aggroRange)
		MoveAggroAndKill(14624, 19314, 'By Ogdens Hammer, what savings!', $aggroRange)
		MoveAggroAndKill(14650, 19417, 'Night has a smol PP', $aggroRange)
		MoveAggroAndKill(12280, 22585, 'Guild wars 2 is actually great, you know?', $aggroRange)
		If FroggyIsFailure() Then Return 1
	WEnd
	AdlibUnRegister('FroggyGroupIsAlive')
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func FroggyFarmLoop()
	AdlibRegister('FroggyGroupIsAlive', 10000)

	Local $aggroRange = $RANGE_SPELLCAST + 100

	Info('Get quest reward')
	MoveTo(12061, 22485)
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x833907)
	RndSleep(500)
	; Quest validation doubled to secure bot
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x833907)
	RndSleep(500)

	Info('Get in dungeon to reset quest')
	MoveTo(12228, 22677)
	RndSleep(500)
	MoveTo(12470, 25036)
	RndSleep(500)
	MoveTo(12968, 26219)
	RndSleep(500)
	Move(13097, 26393)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Bogroot_lvl1)
		Sleep(500)
		MoveTo(12968, 26219)
		Move(13097, 26393)
	WEnd
	RndSleep(2000)

	Info('Get out of dungeon to reset quest')
	RndSleep(2000)
	MoveTo(14876, 632)
	RndSleep(500)
	Move(14700, 450)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Sparkfly_Swamp)
		Info('Stuck, retrying')
		Sleep(500)
		MoveTo(14876, 632)
		Move(14700, 450)
	WEnd
	RndSleep(2000)

	Info('Get quest')
	MoveTo(12061, 22485)
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x833901)
	RndSleep(500)
	; Quest pickup doubled to secure bot
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x833901)
	RndSleep(500)
	Info('Talk to Tekk if already had quest')
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x833905)
	RndSleep(500)
	; Quest pickup doubled to secure bot
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x833905)
	RndSleep(500)

	Info('Get back in')
	MoveTo(12228, 22677)
	RndSleep(500)
	MoveTo(12470, 25036)
	RndSleep(500)
	MoveTo(12968, 26219)
	RndSleep(500)
	Move(13097, 26393)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Bogroot_lvl1)
		Sleep(500)
		MoveTo(12968, 26219)
		Move(13097, 26393)
	WEnd
	RndSleep(2000)


	; Waiting to be alive before retrying
	While Not IsGroupAlive()
		Sleep(2000)
	WEnd
	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (6078, 4483, 1250)
		SafeMoveAggroAndKill(17619, 2687, 'Moving near duo', $aggroRange)
		SafeMoveAggroAndKill(18168, 4788, 'Killing one from duo', $aggroRange)
		SafeMoveAggroAndKill(18880, 7749, 'Triggering beacon 1', $aggroRange)

		Info('Getting blessing')
		MoveTo(19063, 7875)
		GoToNPC(GetNearestNPCToCoords(19058, 7952))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(250)

		SafeMoveAggroAndKill(13080, 7822, 'Moving towards nettles cave', $aggroRange)
		SafeMoveAggroAndKill(9946, 6963, 'Nettles cave', $aggroRange)
		SafeMoveAggroAndKill(6078, 4483, 'Nettles cave exit group', $aggroRange)
	WEnd

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (-1501, -8590, 1250)
		SafeMoveAggroAndKill(4960, 1984, 'Triggering beacon 2', $aggroRange)
		SafeMoveAggroAndKill(3567, -278, 'Massive frog cave', $aggroRange)
		SafeMoveAggroAndKill(1763, -607, 'Im getting buried here!', $aggroRange)
		SafeMoveAggroAndKill(224, -2238, 'Massive frog cave exit', $aggroRange)
		SafeMoveAggroAndKill(-1175, -4994, 'Moving through poison jets', $aggroRange)
		SafeMoveAggroAndKill(-115, -8569, 'Ragna-rock n roll!', $aggroRange)
		SafeMoveAggroAndKill(-1501, -8590, 'Triggering beacon 3', $aggroRange)
	WEnd

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (7171, -17934, 1250)
		SafeMoveAggroAndKill(-115, -8569, 'You played two hours and died like this?!', $aggroRange)
		SafeMoveAggroAndKill(1966, -11018, 'Last cave entrance', $aggroRange)
		SafeMoveAggroAndKill(5775, -12761, 'Youre interrupting my calculations', $aggroRange)
		SafeMoveAggroAndKill(6125, -15820, 'Commander, a word...', $aggroRange)
		Info('Last cave exit')
		MoveTo(7171, -17934)
	WEnd

	Info('Going through portal')
	Move(7600, -19100)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Bogroot_lvl2)
		MoveTo(7171, -17934)
		Move(7600, -19100)
		Sleep(500)
	WEnd
	RndSleep(2000)

	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (-719, 11140, 1250)
		Info('Getting blessing')
		MoveTo(-11072, -5522)
		GoToNPC(GetNearestNPCToCoords(-11055, -5533))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(250)

		SafeMoveAggroAndKill(-10931, -4584, 'Moving in cave', $aggroRange)
		SafeMoveAggroAndKill(-10121, -3175, 'Moving near river ', $aggroRange)
		SafeMoveAggroAndKill(-9646, -1005, 'Going through river ', $aggroRange)
		SafeMoveAggroAndKill(-8548, 601, 'Moving to incubus cave', $aggroRange)
		SafeMoveAggroAndKill(-7217, 3353, 'Incubus cave entrance', $aggroRange)
		SafeMoveAggroAndKill(-8229, 5519, 'Wololo', $aggroRange)
		SafeMoveAggroAndKill(-9434, 8479, 'Help! The crusaders are attacking our trade routes!', $aggroRange)
		SafeMoveAggroAndKill(-8182, 10187, 'La Hire wishes to kill something', $aggroRange)
		SafeMoveAggroAndKill(-6440, 11526, 'The blood on La Hires sword is almost dry!', $aggroRange)
		SafeMoveAggroAndKill(-3963, 10050, 'It is a good day for La Hire to die... ', $aggroRange)
		SafeMoveAggroAndKill(-1992, 11950, 'Ill be back, Saracen dogs!', $aggroRange)
		SafeMoveAggroAndKill(-719, 11140, 'Triggering incubus cave exit beacon', $aggroRange)
	WEnd

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (8398, 4358, 1250)
		SafeMoveAggroAndKill(3130, 12731, 'Beetle zone', $aggroRange)
		SafeMoveAggroAndKill(3535, 13860, 'Aiur will be restored', $aggroRange)
		SafeMoveAggroAndKill(5717, 13357, 'Eternal obedience', $aggroRange)
		SafeMoveAggroAndKill(6945, 9820, 'Beetle zone exit', $aggroRange)
		SafeMoveAggroAndKill(8117, 7465, 'Gokir fight', $aggroRange)
		SafeMoveAggroAndKill(8398, 4358, 'Triggering beacon 2', $aggroRange)
	WEnd

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (19597, -11553, 1250)
		SafeMoveAggroAndKill(9829, -1175, 'The Death Fleet descends', $aggroRange)
		SafeMoveAggroAndKill(10932, -5203, 'I hear and obey', $aggroRange)
		SafeMoveAggroAndKill(13305, -6475, 'Target in range.', $aggroRange)
		SafeMoveAggroAndKill(16841, -5619, 'Keyboss', $aggroRange)

		RndSleep(500)
		PickUpItems()

		Info('Open dungeon door')
		ClearTarget()
		RndSleep(500)
		Moveto(17888, -6243)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(17888, -6243)
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(17888, -6243)
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		ActionInteract()

		SafeMoveAggroAndKill(18363, -8696, 'Going to boss area', $aggroRange)
		SafeMoveAggroAndKill(16631, -11655, 'I will do all that must be done', $aggroRange)
		SafeMoveAggroAndKill(19122, -12284, 'Glory to the Firstborn', $aggroRange)
		SafeMoveAggroAndKill(19597, -11553, 'Triggering boss beacon', $aggroRange)
	WEnd

	Local $aggroRange = $RANGE_SPELLCAST + 300

	While $FroggyDeathsCount < 6 And Not FroggyIsInRange (16861, -19254, 1250)
		Info('------------------------------------')
		Info('Boss area')
		SafeMoveAggroAndKill(17494, -14149, 'Our enemies will be undone', $aggroRange)
		SafeMoveAggroAndKill(14641, -15081, 'I live to serve.', $aggroRange)
		SafeMoveAggroAndKill(13934, -17384, 'The mission is in peril!', $aggroRange)
		SafeMoveAggroAndKill(14365, -17681, 'Boss fight', $aggroRange)
		SafeMoveAggroAndKill(15286, -17662, 'All hail! King of the losers!', $aggroRange)
		SafeMoveAggroAndKill(15804, -19107, 'Oh fuck its huge', $aggroRange)
		SafeMoveAggroAndKill(16861, -19254, 'Move there for safer loop exit', $aggroRange)
	WEnd
	If FroggyIsFailure() Then Return 1

	; Chest
	MoveTo(15910, -19134)
	MoveTo(15329, -18948)
	MoveTo(15086, -19132)
	Info('Opening chest')
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()
	; Doubled to secure the looting
	MoveTo(15590, -18853)
	MoveTo(15027, -19102)
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()

	AdlibUnRegister('FroggyGroupIsAlive')
	Info('Chest looted')
	Info('Waiting for timer end + some more')
	Sleep(190000)
	While Not WaitMapLoading($ID_Sparkfly_Swamp)
		Sleep(500)
	WEnd
	Info('Finished Run')
	
	Return 0
EndFunc


;~ Did run fail ?
Func FroggyIsFailure()
	If ($FroggyDeathsCount > 5) Then
		AdlibUnregister('FroggyGroupIsAlive')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the groupIsAlive variable, this function is run on a fixed timer
Func FroggyGroupIsAlive()
	$FroggyDeathsCount += IsGroupAlive() ? 0 : 1
EndFunc


;~ Is in range of coordinates
Func FroggyIsInRange($X, $Y, $range)
	Local $myX = DllStructGetData(GetMyAgent(), 'X')
	Local $myY = DllStructGetData(GetMyAgent(), 'Y')

	If ($myX < $X + $range) And ($myX > $X - $range) And ($myY < $Y + $range) And ($myY > $Y - $range) Then
		Return True
	EndIf
	Return False
EndFunc