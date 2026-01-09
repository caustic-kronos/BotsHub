#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $TEST_SUITE_INFORMATIONS = 'Just a test suite.'
Global Const $RESURRECT_SIGNET_AND_IAU = 'OQQBcBBAAAAAIAQTCAAAAAA'
Global Const $RESURRECT_SIGNET_AND_FALLBACK = 'OQChYyDAAAAAEA7YAAAAAA'
Global Const $RESURRECTION_SIGNET_SKILLSLOT = 4
Global Const $IAU_SKILLSLOT = 5
Global Const $FALLBACK_SKILLSLOT = 5
;Global Const $HERO_TO_ADD = $ID_GENERAL_MORGAHN
Global Const $HERO_TO_ADD = $ID_HAYDA

;~ Main method to run the test suite
Func RunTestSuite()
	If TestMovement() == $FAIL Then Error('Movement test failed')

	If TestTeleport() == $FAIL Then Error('Teleport test failed')

	If TestPartyChanges() == $FAIL Then Error('Party changes test failed')

	If TestLoadingBuild() == $FAIL Then Error('Loading build failed')

	If TestSwitchingMode() == $FAIL Then Error('Mode switching failed')

	If TestTitles() == $FAIL Then Error('Title switching failed')

	If TestConsumables() == $FAIL Then Error('Using consumable failed')

	GoToRivenEarth()
	If GetMapID() <> $ID_RIVEN_EARTH Then Error('Couldn''t go to Riven Earth')

	If TestUseSkills() == $FAIL Then Error('Using skills failed')

	If TestCommandHero() == $FAIL Then Error('Commanding hero failed')

	If TestChat() == $FAIL Then Error('Chat test failed')

	If TestDeathRIP() == $FAIL Then Error('Death test failed')

	Return $PAUSE
EndFunc


Func TestMovement()
	Out('Testing movement')
	Local $me = GetMyAgent()

	Local $myX = DllStructGetData($me, 'X')
	Local $myY = DllStructGetData($me, 'Y')
	MoveTo($myX + 200, $myY + 200, 0)
	$me = GetMyAgent()
	If DllStructGetData($me, 'X') == $myX And DllStructGetData($me, 'Y') == $myY Then Return $FAIL

	$myX = DllStructGetData($me, 'X')
	$myY = DllStructGetData($me, 'Y')
	Move($myX + 200, $myY + 200)
	Sleep(250)
	$me = GetMyAgent()
	If DllStructGetData($me, 'X') == $myX And DllStructGetData($me, 'Y') == $myY Then Return $FAIL

	Return $SUCCESS
EndFunc


Func TestTeleport()
	Out('Testing teleportation to outposts')
	TravelToOutpost($ID_GUNNARS_HOLD, $district_name)
	Sleep(2500)
	If GetMapID() <> $ID_GUNNARS_HOLD Then Return $FAIL

	TravelToOutpost($ID_RATA_SUM, $district_name)
	Sleep(1000)
	If GetMapID() <> $ID_RATA_SUM Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestPartyChanges()
	Out('Testing party changes')
	LeaveParty()
	Sleep(500)
	Debug('Party size:' & GetPartySize())
	If GetPartySize() <> 1 Then Return $FAIL
	AddHero($HERO_TO_ADD)
	Sleep(500)
	Debug('Party size:' & GetPartySize())
	If GetPartySize() <> 2 Then Return $FAIL
	LeaveParty()
	Sleep(500)
	Debug('Party size:' & GetPartySize())
	If GetPartySize() <> 1 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestLoadingBuild()
	Out('Testing build loading')

	LoadSkillTemplate($RESURRECT_SIGNET_AND_IAU)
	Sleep(500)
	If GetSkillbarSkillID($RESURRECTION_SIGNET_SKILLSLOT) <> $ID_RESURRECTION_SIGNET Then Return $FAIL
	If GetSkillbarSkillID($IAU_SKILLSLOT) <> $ID_I_AM_UNSTOPPABLE Then Return $FAIL

	LeaveParty()
	Sleep(500)
	AddHero($HERO_TO_ADD)
	Sleep(500)

	LoadSkillTemplate($RESURRECT_SIGNET_AND_FALLBACK, 1)
	Sleep(500)
	If GetSkillbarSkillID($RESURRECTION_SIGNET_SKILLSLOT, 1) <> $ID_RESURRECTION_SIGNET Then Return $FAIL
	If GetSkillbarSkillID($FALLBACK_SKILLSLOT, 1) <> $ID_FALL_BACK Then Return $FAIL

	If GetIsHeroSkillSlotDisabled(1, $RESURRECTION_SIGNET_SKILLSLOT) Then Return $FAIL
	If GetIsHeroSkillSlotDisabled(1, $FALLBACK_SKILLSLOT) Then Return $FAIL
	Sleep(500)
	DisableAllHeroSkills(1)
	Sleep(500)
	If Not GetIsHeroSkillSlotDisabled(1, $RESURRECTION_SIGNET_SKILLSLOT) Then Return $FAIL
	If Not GetIsHeroSkillSlotDisabled(1, $FALLBACK_SKILLSLOT) Then Return $FAIL

	Return $SUCCESS
EndFunc


Func TestSwitchingMode()
	Out('Testing mode switching')
	SwitchMode($ID_NORMAL_MODE)
	Sleep(500)
	If GetIsHardMode() Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	Sleep(500)
	If Not GetIsHardMode() Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestTitles()
	Out('Testing titles')
	SetDisplayedTitle($ID_NORN_TITLE)
	Sleep(500)
	Local $energy = GetEnergy(GetMyAgent())
	SetDisplayedTitle($ID_ASURA_TITLE)
	Sleep(500)
	Local $asuraTitlePoints = GetAsuraTitle()
	If $asuraTitlePoints == 0 Then Return $FAIL
	If GetEnergy(GetMyAgent()) == $energy Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestConsumables()
	Out('Testing consumables')
	If FindInInventory($ID_CHOCOLATE_BUNNY)[0] == 0 Then
		Local $chestAndSlot = FindInXunlaiStorage($ID_CHOCOLATE_BUNNY)
		Local $item = GetItemBySlot($chestAndSlot[0], $chestAndSlot[1])
		Local $bagAndSlot = FindFirstEmptySlot(1, 1)
		MoveItem($item, $bagAndSlot[0], $bagAndSlot[1])
		Sleep(250)
	EndIf

	UseConsumable($ID_CHOCOLATE_BUNNY)
	Sleep(250)
	If GetEffectTimeRemaining(GetEffect($ID_SUGAR_JOLT_5)) == 0 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestUseSkills()
	Out('Testing using skills')
	UseSkillEx($IAU_SKILLSLOT)
	Sleep(250)
	If IsRecharged($IAU_SKILLSLOT) Then Return $FAIL

	UseHeroSkill(1, $FALLBACK_SKILLSLOT, GetMyAgent())
	Sleep(250)
	If GetSkillbarSkillRecharge($FALLBACK_SKILLSLOT, 1) == 0 Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestCommandHero()
	Local $heroAgent = GetAgentById(GetHeroID(1))
	Local $heroX = DllStructGetData($heroAgent, 'X')
	Local $heroY = DllStructGetData($heroAgent, 'Y')
	CommandAll(-25309, -4212)
	Sleep(500)
	$heroAgent = GetAgentById(GetHeroID(1))
	If DllStructGetData($heroAgent, 'X') == $heroX And DllStructGetData($heroAgent, 'Y') == $heroY Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestChat()
	SendChat('Hello !')
	Return $SUCCESS
EndFunc


Func TestDeathRIP()
	Out('Testing death - RIP')
	If Not IsPlayerAlive() Then Return $FAIL
	; Please die
	MoveToBaseOfCave()
	GetRaptors()
	Sleep(2000)
	If Not IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TestGetTitlePoints()
	Out('Hero title: ' & GetHeroTitle())
	Out('Gladiator title: ' & GetGladiatorTitle())
	Out('Codex title: ' & GetCodexTitle())
	Out('Kurzick title: ' & GetKurzickTitle())
	Out('Luxon title: ' & GetLuxonTitle())
	Out('Drunkard title: ' & GetDrunkardTitle())
	Out('Survivor title: ' & GetSurvivorTitle())
	Out('Max titles: ' & GetMaxTitles())
	Out('Lucky title: ' & GetLuckyTitle())
	Out('Unlucky title: ' & GetUnluckyTitle())
	Out('Sunspear title: ' & GetSunspearTitle())
	Out('Lightbringer title: ' & GetLightbringerTitle())
	Out('Commander title: ' & GetCommanderTitle())
	Out('Gamer title: ' & GetGamerTitle())
	Out('Legendary Guardian title: ' & GetLegendaryGuardianTitle())
	Out('Sweet title: ' & GetSweetTitle())
	Out('Asura title: ' & GetAsuraTitle())
	Out('Deldrimor title: ' & GetDeldrimorTitle())
	Out('Vanguard title: ' & GetVanguardTitle())
	Out('Norn title: ' & GetNornTitle())
	Out('Mastery of the North title: ' & GetNorthMasteryTitle())
	Out('Party title: ' & GetPartyTitle())
	Out('Zaishen title: ' & GetZaishenTitle())
	Out('Treasure Hunter title: ' & GetTreasureTitle())
	Out('Wisdom title: ' & GetWisdomTitle())
	Return $SUCCESS
EndFunc