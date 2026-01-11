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
Global Const $FROGGY_FARM_INFORMATIONS = 'For best results, don''t cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1 E-surge replaced by a ROJ, ineptitude replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '32mn average in NM' & @CRLF _
	& '41mn average in HM with consets (automatically used if HM is on)'

Global Const $FROGGY_AGGRO_RANGE = $RANGE_SPELLCAST + 100
Global Const $ID_FROGGY_QUEST = 0x322
;Tekk's war quest
;Global Const $ID_FROGGY_QUEST = 0x339

Global Const $MAX_FROGGY_FARM_DURATION = 60 * 60 * 1000

Global $froggy_farm_setup = False

;~ Main method to farm Froggy
Func FroggyFarm()
	If Not $froggy_farm_setup Then SetupFroggyFarm()
	Return FroggyFarmLoop()
EndFunc


;~ Froggy farm setup
Func SetupFroggyFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_GADDS_CAMP, $district_name)

	TrySetupPlayerUsingGUISettings()
	TrySetupTeamUsingGUISettings()
	SetDisplayedTitle($ID_ASURA_TITLE)
	SwitchToHardModeIfEnabled()
	While Not $froggy_farm_setup
		If RunToBogroot() == $FAIL Then ContinueLoop
		$froggy_farm_setup = True
	WEnd
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func RunToBogroot()
	TravelToOutpost($ID_GADDS_CAMP, $district_name)
	ResetFailuresCounter()
	Info('Making way to portal')
	MoveTo(-10018, -21892)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(-9550, -20400)
		Move(-9451, -19766)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SPARKFLY_SWAMP)
	WEnd
	Info('Making way to Bogroot')
	AdlibRegister('TrackPartyStatus', 10000)
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 4671, 7094, 1250)
		MoveAggroAndKillInRange(-4559, -14406, 'I majored in pain, with a minor in suffering', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-5204, -9831, 'Youre dumb! Youll die, and youll leave a dumb corpse!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-928, -8699, 'I am fire! I am war! What are you?', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(4200, -4897, 'Praise Joko!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(4671, 7094, 'I can outrun a centaur', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 12280, 22585, 1250)
		MoveAggroAndKillInRange(11025, 11710, 'Wow. Thats quality armor.', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(14624, 19314, 'By Ogdens Hammer, what savings!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(14650, 19417, 'More violets I say. Less violence', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(12280, 22585, 'Guild wars 2 is actually great, you know?', $FROGGY_AGGRO_RANGE)
	WEnd
	AdlibUnRegister('TrackPartyStatus')
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Farm loop
Func FroggyFarmLoop()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	GetRewardRefreshAndTakeFroggyQuest()
	; Failure return delayed after adlib function deregistered
	If (ClearFroggyFloor1() == $FAIL Or ClearFroggyFloor2() == $FAIL) Then $froggy_farm_setup = False
	AdlibUnRegister('TrackPartyStatus')
	If Not $froggy_farm_setup Then Return $FAIL

	Info('Waiting for timer end')
	Sleep(190000)
	While Not WaitMapLoading($ID_SPARKFLY_SWAMP)
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
		$mapLoaded = WaitMapLoading($ID_BOGROOT_LVL1)
	WEnd

	Info('Get out of dungeon to reset quest')
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(14876, 632)
		Move(14700, 450)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SPARKFLY_SWAMP)
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
		$mapLoaded = WaitMapLoading($ID_BOGROOT_LVL1)
	WEnd
EndFunc


;~ Clear Froggy floor 1
Func ClearFroggyFloor1()
	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 6078, 4483, 1250)
		If CheckStuck('Froggy Floor 1 - First loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(17619, 2687, 'Moving near duo', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(18168, 4788, 'Killing one from duo', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(18880, 7749, 'Triggering beacon 1', $FROGGY_AGGRO_RANGE)

		Info('Getting blessing')
		MoveTo(19063, 7875)
		GoToNPC(GetNearestNPCToCoords(19058, 7952))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(250)

		MoveAggroAndKillInRange(13080, 7822, 'Moving towards nettles cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(9946, 6963, 'Nettles cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(6078, 4483, 'Nettles cave exit group', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -1501, -8590, 1250)
		If CheckStuck('Froggy Floor 1 - Second loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(4960, 1984, 'Triggering beacon 2', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(3567, -278, 'Massive frog cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(1763, -607, 'Im getting buried here!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(224, -2238, 'Massive frog cave exit', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1175, -4994, 'Moving through poison jets', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-115, -8569, 'Ragna-rock n roll!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1501, -8590, 'Triggering beacon 3', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 7171, -17934, 1250)
		If CheckStuck('Froggy Floor 1 - Third loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-115, -8569, 'You played two hours and died like this?!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(1966, -11018, 'Last cave entrance', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(5775, -12761, 'Youre interrupting my calculations', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(6125, -15820, 'Commander, a word...', $FROGGY_AGGRO_RANGE)
		Info('Last cave exit')
		MoveTo(7171, -17934)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('Froggy Floor 1 - Getting through portal', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(7171, -17934)
		Move(7600, -19100)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_BOGROOT_LVL2)
	WEnd
	Return $SUCCESS
EndFunc


;~ Clear Froggy floor 2
Func ClearFroggyFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -719, 11140, 1250)
		If CheckStuck('Froggy Floor 2 - First loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		Info('Getting blessing')
		MoveTo(-11072, -5522)
		GoToNPC(GetNearestNPCToCoords(-11055, -5533))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(250)

		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-10931, -4584, 'Moving in cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10121, -3175, 'Moving near river ', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9646, -1005, 'Going through river ', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8548, 601, 'Moving to incubus cave', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7217, 3353, 'Incubus cave entrance', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8229, 5519, 'Wololo', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9434, 8479, 'Help! The crusaders are attacking our trade routes!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8182, 10187, 'La Hire wishes to kill something', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6440, 11526, 'The blood on La Hires sword is almost dry!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3963, 10050, 'It is a good day for La Hire to die... ', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1992, 11950, 'Ill be back, Saracen dogs!', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(-719, 11140, 'Triggering incubus cave exit beacon', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 8398, 4358, 1250)
		If CheckStuck('Froggy Floor 2 - Second loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(3130, 12731, 'Beetle zone', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(3535, 13860, 'Aiur will be restored', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(5717, 13357, 'Eternal obedience', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(6945, 9820, 'Beetle zone exit', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(8117, 7465, 'Gokir fight', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(8398, 4358, 'Triggering beacon 2', $FROGGY_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 19597, -11553, 1250)
		If CheckStuck('Froggy Floor 2 - Third loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(9829, -1175, 'The Death Fleet descends', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(10932, -5203, 'I hear and obey', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(13305, -6475, 'Target in range.', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(16841, -5619, 'Keyboss', $FROGGY_AGGRO_RANGE)

		RandomSleep(500)
		PickUpItems()

		Info('Open dungeon door')
		ClearTarget()

		; Tripled to secure bot
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

		MoveAggroAndKillInRange(18363, -8696, 'Going to boss area', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(16631, -11655, 'I will do all that must be done', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(19122, -12284, 'Glory to the Firstborn', $FROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(19597, -11553, 'Triggering boss beacon', $FROGGY_AGGRO_RANGE)
	WEnd

	Local $largeFROGGY_AGGRO_RANGE = $RANGE_SPELLCAST + 300
	Local $questState = 999
	While Not IsRunFailed() And $questState <> 3
		If CheckStuck('Froggy Floor 2 - Fourth loop', $MAX_FROGGY_FARM_DURATION) == $FAIL Then Return $FAIL
		Info('------------------------------------')
		Info('Boss area')
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(17494, -14149, 'Our enemies will be undone', $largeFROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(14641, -15081, 'I live to serve.', $largeFROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(13934, -17384, 'The mission is in peril!', $largeFROGGY_AGGRO_RANGE)
		MoveAggroAndKillInRange(14365, -17681, 'Boss fight', $largeFROGGY_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(15286, -17662, 'All hail! King of the losers!', $largeFROGGY_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(15804, -19107, 'Oh fuck its huge', $largeFROGGY_AGGRO_RANGE)

		$questState = DllStructGetData(GetQuestByID($ID_FROGGY_QUEST), 'LogState')
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
