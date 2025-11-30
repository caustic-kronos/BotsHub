#CS ===========================================================================
; Author: TDawg
; Contributor: Gahais
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

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $FroggyFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1 E-surge replaced by a ROJ, ineptitude replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '32mn average in NM' & @CRLF _
	& '41mn average in HM with consets (automatically used if HM is on)'

Global $FROGGY_FARM_SETUP = False
Global Const $froggyAggroRange = $RANGE_SPELLCAST + 100
Global Const $ID_Froggy_Quest = 0x322
;Tekk's war quest
;Global Const $ID_Froggy_Quest = 0x339


;~ Main method to farm Froggy
Func FroggyFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	While Not $FROGGY_FARM_SETUP
		SetupFroggyFarm()
	WEnd
	Return FroggyFarmLoop()
EndFunc


;~ Froggy farm setup
Func SetupFroggyFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_Gadds_Camp, $DISTRICT_NAME) == $FAIL Then Return
	; Assuming that team has been set up correctly manually
	SetDisplayedTitle($ID_Asura_Title)
	SwitchToHardModeIfEnabled()
	ResetFailuresCounter()
	RunToBogroot()
	If IsRunFailed() Then Return
	$FROGGY_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func RunToBogroot()
	Info('Making way to portal')
	MoveTo(-10018, -21892)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(-9550, -20400)
		Move(-9451, -19766)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Sparkfly_Swamp)
	WEnd
	Info('Making way to Bogroot')
	AdlibRegister('TrackPartyStatus', 10000)
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 4671, 7094, 1250)
		MoveAggroAndKillInRange(-4559, -14406, 'I majored in pain, with a minor in suffering', $froggyAggroRange)
		MoveAggroAndKillInRange(-5204, -9831, 'Youre dumb! Youll die, and youll leave a dumb corpse!', $froggyAggroRange)
		MoveAggroAndKillInRange(-928, -8699, 'I am fire! I am war! What are you?', $froggyAggroRange)
		MoveAggroAndKillInRange(4200, -4897, 'Praise Joko!', $froggyAggroRange)
		MoveAggroAndKillInRange(4671, 7094, 'I can outrun a centaur', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 12280, 22585, 1250)
		MoveAggroAndKillInRange(11025, 11710, 'Wow. Thats quality armor.', $froggyAggroRange)
		MoveAggroAndKillInRange(14624, 19314, 'By Ogdens Hammer, what savings!', $froggyAggroRange)
		MoveAggroAndKillInRange(14650, 19417, 'More violets I say. Less violence', $froggyAggroRange)
		MoveAggroAndKillInRange(12280, 22585, 'Guild wars 2 is actually great, you know?', $froggyAggroRange)
	WEnd
	AdlibUnRegister('TrackPartyStatus')
EndFunc


;~ Farm loop
Func FroggyFarmLoop()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	GetRewardRefreshAndTakeFroggyQuest()
	; Failure return delayed after adlib function deregistered
	If (ClearFroggyFloor1() == $FAIL Or ClearFroggyFloor2() == $FAIL) Then $FROGGY_FARM_SETUP = False
	AdlibUnRegister('TrackPartyStatus')
	If Not $FROGGY_FARM_SETUP Then Return $FAIL

	Info('Waiting for timer end')
	Sleep(190000)
	While Not WaitMapLoading($ID_Sparkfly_Swamp)
		Sleep(500)
	WEnd
	Info('Finished Run')
	Return $SUCCESS
EndFunc


;~ Take quest rewards, refresh quest by entering dungeon and exiting it, then take quest again and reenter dungeon
;~ This is Giriff's War version. To use Tekk's war quest instead, replace:
;~ GoToNPC(GetNearestNPCToCoords(12308, 22836)) -> GoToNPC(GetNearestNPCToCoords(12500, 22648))
;~ Dialog(0x832207) -> Dialog(0x833907)
;~ Dialog(0x832201) -> Dialog(0x833901)
;~ Dialog(0x832205) -> Dialog(0x833905)
Func GetRewardRefreshAndTakeFroggyQuest()
	Info('Get quest reward')
	MoveTo(12061, 22485)

	; Quest validation doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12308, 22836))
		RandomSleep(250)
		Dialog(0x832207)
		RandomSleep(500)
	Next

	Info('Get in dungeon to reset quest')
	MoveTo(12228, 22677)
	MoveTo(12470, 25036)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(12968, 26219)
		Move(13097, 26393)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Bogroot_lvl1)
	WEnd

	Info('Get out of dungeon to reset quest')
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(14876, 632)
		Move(14700, 450)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Sparkfly_Swamp)
	WEnd

	Info('Get quest')
	MoveTo(12061, 22485)
	; Quest validation doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12308, 22836))
		RandomSleep(250)
		Dialog(0x832201)
		RandomSleep(500)
	Next
	Info('Talk to Tekk if already had quest')
	; Quest pickup doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12308, 22836))
		RandomSleep(250)
		Dialog(0x832205)
		RandomSleep(500)
	Next

	Info('Get back in')
	MoveTo(12228, 22677)
	MoveTo(12470, 25036)
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(12968, 26219)
		Move(13097, 26393)
		RandomSleep(2000)
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
		MoveAggroAndKillInRange(17619, 2687, 'Moving near duo', $froggyAggroRange)
		MoveAggroAndKillInRange(18168, 4788, 'Killing one from duo', $froggyAggroRange)
		MoveAggroAndKillInRange(18880, 7749, 'Triggering beacon 1', $froggyAggroRange)

		Info('Getting blessing')
		MoveTo(19063, 7875)
		GoToNPC(GetNearestNPCToCoords(19058, 7952))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(250)

		MoveAggroAndKillInRange(13080, 7822, 'Moving towards nettles cave', $froggyAggroRange)
		MoveAggroAndKillInRange(9946, 6963, 'Nettles cave', $froggyAggroRange)
		MoveAggroAndKillInRange(6078, 4483, 'Nettles cave exit group', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -1501, -8590, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(4960, 1984, 'Triggering beacon 2', $froggyAggroRange)
		MoveAggroAndKillInRange(3567, -278, 'Massive frog cave', $froggyAggroRange)
		MoveAggroAndKillInRange(1763, -607, 'Im getting buried here!', $froggyAggroRange)
		MoveAggroAndKillInRange(224, -2238, 'Massive frog cave exit', $froggyAggroRange)
		MoveAggroAndKillInRange(-1175, -4994, 'Moving through poison jets', $froggyAggroRange)
		MoveAggroAndKillInRange(-115, -8569, 'Ragna-rock n roll!', $froggyAggroRange)
		MoveAggroAndKillInRange(-1501, -8590, 'Triggering beacon 3', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 7171, -17934, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-115, -8569, 'You played two hours and died like this?!', $froggyAggroRange)
		MoveAggroAndKillInRange(1966, -11018, 'Last cave entrance', $froggyAggroRange)
		MoveAggroAndKillInRange(5775, -12761, 'Youre interrupting my calculations', $froggyAggroRange)
		MoveAggroAndKillInRange(6125, -15820, 'Commander, a word...', $froggyAggroRange)
		Info('Last cave exit')
		MoveTo(7171, -17934)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(7171, -17934)
		Move(7600, -19100)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Bogroot_lvl2)
	WEnd
	Return $SUCCESS
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
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(250)

		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-10931, -4584, 'Moving in cave', $froggyAggroRange)
		MoveAggroAndKillInRange(-10121, -3175, 'Moving near river ', $froggyAggroRange)
		MoveAggroAndKillInRange(-9646, -1005, 'Going through river ', $froggyAggroRange)
		MoveAggroAndKillInRange(-8548, 601, 'Moving to incubus cave', $froggyAggroRange)
		MoveAggroAndKillInRange(-7217, 3353, 'Incubus cave entrance', $froggyAggroRange)
		MoveAggroAndKillInRange(-8229, 5519, 'Wololo', $froggyAggroRange)
		MoveAggroAndKillInRange(-9434, 8479, 'Help! The crusaders are attacking our trade routes!', $froggyAggroRange)
		MoveAggroAndKillInRange(-8182, 10187, 'La Hire wishes to kill something', $froggyAggroRange)
		MoveAggroAndKillInRange(-6440, 11526, 'The blood on La Hires sword is almost dry!', $froggyAggroRange)
		MoveAggroAndKillInRange(-3963, 10050, 'It is a good day for La Hire to die... ', $froggyAggroRange)
		MoveAggroAndKillInRange(-1992, 11950, 'Ill be back, Saracen dogs!', $froggyAggroRange)
		MoveAggroAndKillInRange(-719, 11140, 'Triggering incubus cave exit beacon', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 8398, 4358, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(3130, 12731, 'Beetle zone', $froggyAggroRange)
		MoveAggroAndKillInRange(3535, 13860, 'Aiur will be restored', $froggyAggroRange)
		MoveAggroAndKillInRange(5717, 13357, 'Eternal obedience', $froggyAggroRange)
		MoveAggroAndKillInRange(6945, 9820, 'Beetle zone exit', $froggyAggroRange)
		MoveAggroAndKillInRange(8117, 7465, 'Gokir fight', $froggyAggroRange)
		MoveAggroAndKillInRange(8398, 4358, 'Triggering beacon 2', $froggyAggroRange)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 19597, -11553, 1250)
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(9829, -1175, 'The Death Fleet descends', $froggyAggroRange)
		MoveAggroAndKillInRange(10932, -5203, 'I hear and obey', $froggyAggroRange)
		MoveAggroAndKillInRange(13305, -6475, 'Target in range.', $froggyAggroRange)
		MoveAggroAndKillInRange(16841, -5619, 'Keyboss', $froggyAggroRange)

		RandomSleep(500)
		PickUpItems()

		Info('Open dungeon door')
		ClearTarget()

		For $i = 1 To 3 ; Tripled to secure bot
			MoveTo(17888, -6243)
			Sleep(GetPing() + 500)
			TargetNearestItem()
			ActionInteract()
			Sleep(GetPing() + 500)
			TargetNearestItem()
			ActionInteract()
			Sleep(GetPing() + 500)
		Next

		MoveAggroAndKillInRange(18363, -8696, 'Going to boss area', $froggyAggroRange)
		MoveAggroAndKillInRange(16631, -11655, 'I will do all that must be done', $froggyAggroRange)
		MoveAggroAndKillInRange(19122, -12284, 'Glory to the Firstborn', $froggyAggroRange)
		MoveAggroAndKillInRange(19597, -11553, 'Triggering boss beacon', $froggyAggroRange)
	WEnd

	Local $largeFroggyAggroRange = $RANGE_SPELLCAST + 300
	Local $questState = 999
	While Not IsRunFailed() And $questState <> 3
		Info('------------------------------------')
		Info('Boss area')
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(17494, -14149, 'Our enemies will be undone', $largeFroggyAggroRange)
		MoveAggroAndKillInRange(14641, -15081, 'I live to serve.', $largeFroggyAggroRange)
		MoveAggroAndKillInRange(13934, -17384, 'The mission is in peril!', $largeFroggyAggroRange)
		MoveAggroAndKillInRange(14365, -17681, 'Boss fight', $largeFroggyAggroRange)
		FlagMoveAggroAndKillInRange(15286, -17662, 'All hail! King of the losers!', $largeFroggyAggroRange)
		FlagMoveAggroAndKillInRange(15804, -19107, 'Oh fuck its huge', $largeFroggyAggroRange)

		$questState = DllStructGetData(GetQuestByID($ID_Froggy_Quest), 'LogState')
		Info('Quest state end of boss loop : ' & $questState)
	WEnd
	If IsRunFailed() Then Return $FAIL

	; Chest
	MoveTo(15910, -19134)
	MoveTo(15329, -18948)
	MoveTo(15086, -19132)
	Info('Opening chest')
	; Doubled to secure the looting
	For $i = 1 To 2
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
		RandomSleep(5000)
	Next
	Return $SUCCESS
EndFunc