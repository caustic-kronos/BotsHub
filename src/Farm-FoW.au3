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
Global Const $FoWFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'XXmn average in NM' & @CRLF _
	& 'YYmn average in HM with consets (automatically used if HM is on)' & @CRLF _
	& 'If you add a summon to this farm, do it so that it despawned once doing green forest'
Global Const $FOW_FARM_DURATION = 75 * 60 * 1000

Global $FOW_FARM_SETUP = False
Global Const $ID_Quest_WailingLord = 0xCC
Global Const $ID_Quest_TheEternalForgemaster = 0xD1
Global Const $Shard_Wolf_ModelID = 2835
Global Const $ID_FoW_Unholy_Texts = 2619


; TODO:
; - open reward chests

;~ Main method to farm FoW
Func FoWFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $FOW_FARM_SETUP Then SetupFoWFarm()

	Local $result = EnterFissureOfWoe()
	If $result <> $SUCCESS Then Return $result
	$result = FoWFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared Fissure of Woe')
	If $result == $FAIL Then Info('Could not clear Fissure of Woe')
	TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	Return $result
EndFunc


;~ FoW farm setup
Func SetupFoWFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	SetupPlayerFoWFarm()
	SetupTeamFoWFarm()
	SwitchToHardModeIfEnabled()
	$FOW_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFoWFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
    Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
	EndIf
	Sleep(250 + GetPing())
	If GUICtrlRead($GUI_Checkbox_WeaponSlot) == $GUI_CHECKED Then
		Info('Setting player weapon slot to ' & $WEAPON_SLOT & ' according to GUI settings')
		ChangeWeaponSet($WEAPON_SLOT)
	Else
		Info('Automatic player weapon slot setting is disabled. Assuming that player sets weapon slot manually')
	EndIf
	Sleep(250 + GetPing())
EndFunc


Func SetupTeamFoWFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Automatic team builds setup is disabled. Assuming that team builds are set up manually')
    EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
    	Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


;~ Farm loop
Func FoWFarmLoop()
	If GetMapID() <> $ID_Fissure_of_Woe Then Return $FAIL
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = FoWFarmProcess()
	AdlibUnRegister('TrackPartyStatus')
	Return $result
EndFunc


;~ Farm exact process - wrapper needed to be able to deregister adlib functions
Func FoWFarmProcess()
	If IsHardmodeEnabled() Then UseConset()
	If TowerOfCourage() == $FAIL Then Return $FAIL
	; Fix : if unholy texts are not picked up, move to different place, and retry, until it works
	If TheGreatBattleField() == $FAIL Then Return $FAIL
	If TheTempleOfWar() == $FAIL Then Return $FAIL
	If TheSpiderCave_and_FissureShore() == $FAIL Then Return $FAIL
	; Fix: blocking point before the boss, either try to loot something unreachable or to open an unreachable chest
	If LakeOfFire() == $FAIL Then Return $FAIL
	If TowerOfStrengh() == $FAIL Then Return $FAIL
	; Fix : pathing should be updated to avoid over aggro
	If BurningForest() == $FAIL Then Return $FAIL
	; Fix : pathing incorrect making you potentially clear in front of Wailing Lord without the flags
	; Also makes you take griffons before clearing the path for them
	If ForestOfTheWailingLord() == $FAIL Then Return $FAIL
	If GriffonRun() == $FAIL Then Return $FAIL
	If TempleLoot() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func TowerOfCourage()
	Info('Pre-clearing west of tower')
	MoveAggroAndKill(-21000, 1500, '1')
	MoveAggroAndKill(-19500, 1000, '2')
	MoveAggroAndKill(-21000, 1500, '3')
	MoveAggroAndKill(-22000, -2000, '4')
	MoveAggroAndKill(-22000, -6000, '5')
	MoveAggroAndKill(-20000, -6000, '6')
	MoveAggroAndKill(-19000, -4000, '7')
	MoveAggroAndKill(-17000, -5000, '8')
	Info('Rastigan should start moving')
	MoveAggroAndKill(-17000, -2500, '1')
	MoveAggroAndKill(-14000, -3000, '2')
	Info('Pre-clearing east of tower')
	MoveAggroAndKill(-14000, -1000, '1')
	MoveAggroAndKill(-15000, 0, '2')
	MoveAggroAndKill(-14600, -2600, '3')
	Info('Waiting for door to open')
	Local $waitCount = 0
	Local $me = GetMyAgent()
	While Not IsRunFailed() And GetDistanceToPoint($me, -15000, -2000) > $RANGE_ADJACENT
		If $waitCount == 20 Then
			Info('Rastigan is not moving, lets nudge him')
			MoveAggroAndKill(-15500, -3500)
			MoveAggroAndKill(-17000, -3000)
			MoveAggroAndKill(-19000, -2100)
			MoveAggroAndKill(-17000, -3000)
			MoveAggroAndKill(-15500, -3500)
			MoveAggroAndKill(-14600, -2600)
			$waitCount = 0
		EndIf
		MoveTo(-15000, -2000)
		Sleep(3000)
		$waitCount += 1
		$me = GetMyAgent()
	WEnd
	MoveAggroAndKill(-15500, -2000)

	Info('Getting Tower of Courage quest and reward')
	MoveTo(-15700, -1700)
	Local $npc = GetNearestNPCToCoords(-15750, -1700)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80D401)
	RandomSleep(GetPing() + 750)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80D407)
	RandomSleep(GetPing() + 750)

	Info('Getting The Wailing Lord quest')
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CC01)
	RandomSleep(GetPing() + 750)
EndFunc


Func TheGreatBattleField()
	Info('Heading to forgeman')
	MoveAggroAndKill(-9500, -6000, '1')
	MoveAggroAndKill(-6300, 1700, '2')
	FlagMoveAggroAndKill(-4700, 2900, '3')
	FlagMoveAggroAndKill(-5000, 10000, '4')
	FlagMoveAggroAndKill(-7000, 11400, '5')

	Info('Getting the Army of Darkness quest')
	MoveTo(-7326, 11892)
	Local $npc = GetNearestNPCToCoords(-7400, 11950)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CB01)
	RandomSleep(GetPing() + 750)

	Info('Getting Unholy Texts')
	FlagMoveAggroAndKill(-1800, 14400, '1')
	FlagMoveAggroAndKill(1500, 16600, '2')
	MoveAggroAndKill(2800, 15900, '3')
	MoveAggroAndKill(2400, 14650, '4')

	PickUpUnholyTexts()
	MoveTo(2100, 16500)
	FlagMoveAggroAndKill(-3700, 13400, '5')
	FlagMoveAggroAndKill(-6700, 11200, '6')

	Info('Getting the Army of Darkness reward')
	MoveTo(-7300, 11900)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CB07)
	RandomSleep(GetPing() + 750)

	Info('Getting the Eternal Forgemaster quest')
	MoveTo(-7400, 11700)
	GoToNPC(GetNearestNPCToCoords(-7450, 11700))
	RandomSleep(GetPing() + 750)
	Dialog(0x80D101)
	RandomSleep(GetPing() + 750)

	Info('Heading to Forge')
	FlagMoveAggroAndKill(-4400, 10900, '1')
	FlagMoveAggroAndKill(700, 7600, '2')
	Info('Sleeping for 20s')
	Sleep(20000)
	FlagMoveAggroAndKill(2800, 7900, '3')
	FlagMoveAggroAndKill(700, 7600, '4')
	MoveAggroAndKill(1400, 6100, '5')
EndFunc


Func TheTempleOfWar()
	Info('Clearing area')
	MoveAggroAndKill(1800, 2100, '1')
	MoveAggroAndKill(4300, 800, '2')
	MoveAggroAndKill(4000, -1400, '3')
	MoveAggroAndKill(2500, -2700, '4')
	MoveAggroAndKill(1000, -2600, '5')
	MoveAggroAndKill(-600, -1500, '6')
	MoveAggroAndKill(-400, 800, '7')

	Info('Clearing center')
	MoveTo(300, 1300)
	MoveAggroAndKill(1000, 500, '1')
	MoveAggroAndKill(2000, 250, '2')
	MoveAggroAndKill(2500, -300, '3')
	MoveAggroAndKill(1850, -150, '4')

	Local $questState = 999
	While Not IsRunFailed() And $questState <> 0x13
		$questState = DllStructGetData(GetQuestByID($ID_Quest_TheEternalForgemaster), 'LogState')
		Info('The Eternal Forgemaster not finished yet : ' & $questState)
		Sleep(1000)
	WEnd

	Info('Getting the Eternal Forgemaster quest reward')
	Local $npc = GetNearestNPCToCoords(1850, -200)
	TakeQuestOrReward($npc, $ID_Quest_TheEternalForgemaster, 0x80D107, 0)

	Info('Getting the Defend the Temple of War quest')
	MoveTo(1850, -150)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CA01)
	RandomSleep(GetPing() + 750)

	Info('Waiting the defense, feeling cute, might optimise later')
	Info('Sleeping for 480s')
	Sleep(480000)

	Info('Getting the Defend the Temple of War quest reward')
	MoveTo(1850, -150)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CA07)
	RandomSleep(GetPing() + 750)

	Info('Getting the Restore the Temple of War quest')
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CF03)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CF01)
	RandomSleep(GetPing() + 750)

	Info('Getting the Khobay the Betrayer quest')
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80E003)
	RandomSleep(GetPing() + 750)
	Dialog(0x80E001)
	RandomSleep(GetPing() + 750)

	Info('Getting the Tower of Strength quest')
	MoveTo(200, -1900)
	GoToNPC(GetNearestNPCToCoords(150, -1950))
	RandomSleep(GetPing() + 750)
	Dialog(0x80D301)
	RandomSleep(GetPing() + 750)
	Return $SUCCESS
EndFunc


Func TheSpiderCave_and_FissureShore()
	Info('Going to Nimros')
	MoveAggroAndKill(1800, -3700, '1')
	MoveAggroAndKill(1800, -6900, '2')
	Info('Sleeping for 30s')
	Sleep(30000)
	MoveAggroAndKill(2800, -9700, '3')
	MoveAggroAndKill(1800, -12000, '4')
	MoveAggroAndKill(1100, -13500, '5')

	Info('Getting The Hunt quest')
	MoveTo(3000, -14800)
	GoToNPC(GetNearestNPCToCoords(3000, -14850))
	RandomSleep(GetPing() + 750)
	Dialog(0x80D001)
	RandomSleep(GetPing() + 750)

	KillShardWolf()

	Info('Clearing cave')
	MoveAggroAndKill(1400, -11600, '1')
	MoveAggroAndKill(-900, -9400, '2')
	MoveAggroAndKill(-2500, -8500, '3')
	MoveAggroAndKill(-4000, -9400, '4')
	MoveAggroAndKill(-6100, -11400, '5')
	MoveAggroAndKill(-7800, -13400, '6')
	MoveAggroAndKill(-8400, -15800, '7')
	MoveAggroAndKill(-8600, -17300, '8')

	MoveTo(-10000, -18500)
	MoveTo(-12900, -18000)

	KillShardWolf()

	Info('Going back')
	MoveAggroAndKill(-8800, -18200, '1')
	MoveAggroAndKill(-8500, -16200, '2')

	MoveTo(-6700, -11750)
	MoveTo(-1600, -8750)
	MoveTo(1000, -11200)
	Return $SUCCESS
EndFunc


Func LakeOfFire()
	Info('Khobay murder time')
	MoveAggroAndKill(4500, -9800, '1')
	MoveAggroAndKill(7350, -11250, '2')
	MoveAggroAndKill(9600, -8500, '3')
	MoveAggroAndKill(15250, -9500, '4')
	MoveAggroAndKill(20500, -8100, '5')
	MoveAggroAndKillInRange(20500, -12400, '6', $RANGE_EARSHOT)
	MoveAggroAndKillInRange(18300, -14000, '7', $RANGE_EARSHOT)
	MoveAggroAndKillInRange(19500, -15000, '8', $RANGE_EARSHOT)
	Return $SUCCESS
EndFunc


Func TowerOfStrengh()
	Info('Clearing area of Tower of Strengh')
	MoveTo(18300, -14000)
	MoveTo(20500, -12400)
	MoveTo(20500, -8100)
	MoveTo(15250, -9500)
	MoveTo(9600, -8500)
	MoveAggroAndKill(11500, -4600, '1')
	MoveAggroAndKill(15000, -3100, '2')
	MoveAggroAndKill(15800, -300, '3')
	MoveAggroAndKill(17600, 2200, '4')
	MoveAggroAndKill(15000, 1000, '5')
	MoveAggroAndKill(13000, 500, '6')
	MoveAggroAndKill(12000, 0, '7')
	KillShardWolf()
	MoveAggroAndKill(15000, -1000, '7')

	Info('Going to trigger pnj')
	MoveAggroAndKill(10300, -5900, '1')
	MoveAggroAndKill(6500, -11200, '2')
	MoveAggroAndKill(1600, -7200, '3')

	Info('And back to tower')
	MoveAggroAndKill(6500, -12000, '1')
	MoveAggroAndKill(10300, -5900, '2')
	MoveAggroAndKill(15400, -1400, '3')
	; Entering the tower garantees the npc arrived
	Local $me = GetMyAgent()
	While Not IsRunFailed() And GetDistanceToPoint($me, 16700, -1700) > $RANGE_NEARBY
		MoveTo(16700, -1700)
		Sleep(1000)
		$me = GetMyAgent()
	WEnd
	Return $SUCCESS
EndFunc


Func BurningForest()
	Info('Heading to Burning Forest')
	MoveAggroAndKill(15200, -1100, '1')
	MoveAggroAndKill(17400, 3300, '2')
	MoveAggroAndKill(14100, 4000, '3')
	MoveAggroAndKill(12100, 6750, '4')

	Info('Getting the Slaves of Menzies quest')
	MoveTo(12000, 6600)
	Local $npc = GetNearestNPCToCoords(12050, 6500)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CE01)
	RandomSleep(GetPing() + 750)

	Info('Clearing Burning Forest')
	FlagMoveAggroAndKill(12800, 7900, '1')
	FlagMoveAggroAndKill(14800, 8500, '2')
	FlagMoveAggroAndKill(16500, 9100, '3')
	FlagMoveAggroAndKill(19000, 8400, '4')
	FlagMoveAggroAndKill(20800, 8500, '5')
	FlagMoveAggroAndKill(21700, 12600, '6')
	FlagMoveAggroAndKill(22000, 15000, '7')
	FlagMoveAggroAndKill(19500, 14500, '8')
	FlagMoveAggroAndKill(17400, 13500, '9')
	KillShardWolf()
	FlagMoveAggroAndKill(16200, 11000, '10')
	FlagMoveAggroAndKill(15000, 92000, '11')
	FlagMoveAggroAndKill(13000, 7700, '12')

	Info('Getting the Slaves of Menzies quest reward')
	MoveTo(12000, 6600)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CE07)
	RandomSleep(GetPing() + 750)

	Info('Heading to Forest of the Wailing Lords')
	MoveAggroAndKill(9200, 12500, '1')
	FlagMoveAggroAndKill(1600, 12300, '2')
	KillShardWolf()
	FlagMoveAggroAndKill(-10750, 6300, '3')
	Return $SUCCESS
EndFunc


Func ForestOfTheWailingLord()
	Info('Clearing forest')
	; Seems to be a block at those coordinates
	MoveAggroAndKill(-17500, 9750, '1')
	MoveAggroAndKill(-20200, 9500, '2')
	MoveAggroAndKill(-22000, 11000, '3')
	MoveAggroAndKillInRange(-20000, 13000, '4', $RANGE_SPELLCAST + 200)
	MoveAggroAndKillInRange(-19000, 14500, '5', $RANGE_SPELLCAST + 200)
	MoveAggroAndKill(-18000, 15000, '6')
	MoveAggroAndKill(-16000, 13500, '7')

	KillShardWolf()

	; Safer moves
	MoveAggroAndKillInRange(-20000, 13000, '8', $RANGE_SPELLCAST + 200)
	MoveAggroAndKillInRange(-18000, 11000, '9', $RANGE_SPELLCAST + 200)
	MoveAggroAndKillInRange(-20200, 14000, '10', $RANGE_SPELLCAST + 200)

	Info('Safely pulling')
	CommandHero(1, -20200, 13600)
	CommandHero(2, -19900, 14000)
	CommandHero(3, -20400, 13500)
	CommandHero(4, -19900, 14250)
	CommandHero(5, -20000, 13800)
	CommandHero(6, -19750, 13800)
	CommandHero(7, -19900, 13600)

	Local $questState = 1
	While Not IsRunFailed() And $questState <> 19
		MoveTo(-21000, 14600)
		Sleep(3000)
		MoveTo(-20500, 14200)
		Sleep(17000)
		$questState = DllStructGetData(GetQuestByID($ID_Quest_WailingLord), 'LogState')
	WEnd
	CancelAllHeroes()

	Info('Getting the Gift of Griffons quest')
	MoveTo(-21500, 15000)
	GoToNPC(GetNearestNPCToCoords(-21600, 15050))
	RandomSleep(GetPing() + 750)
	Dialog(0x80CD01)
	RandomSleep(GetPing() + 750)
	Return $SUCCESS
EndFunc


Func GriffonRun()
	Info('Preclearing area for griffons')
	MoveAggroAndKill(-17000, 10000, '1')
	MoveAggroAndKill(-7500, 5000, '2')
	MoveAggroAndKill(-6750, -4250, '3')
	MoveAggroAndKill(-9500, -6000, '4')
	MoveAggroAndKill(-13750, -2750, '5')
	MoveAggroAndKill(-18000, -3500, '6')

	KillShardWolf()

	Info('Grabbing griffons')
	MoveAggroAndKill(-13750, -2750, '1')
	MoveAggroAndKill(-9500, -6000, '2')
	MoveAggroAndKill(-6750, -4250, '3')
	MoveAggroAndKill(-7500, 5000, '4')
	MoveAggroAndKill(-18250, 9500, '5')
	MoveAggroAndKill(-20000, 9500, '6')
	MoveAggroAndKill(-22000, 11000, '7')

	Info('Leading griffons back')
	MoveAggroAndKill(-17500, 9750, '1')
	MoveAggroAndKill(-12750, 6750, '2')
	MoveAggroAndKill(-9500, 6250, '3')
	MoveAggroAndKill(-7500, 5000, '4')
	MoveAggroAndKill(-6500, -3500, '5')
	MoveAggroAndKill(-7250, -4750, '6')
	MoveAggroAndKill(-10000, -5000, '7')
	MoveAggroAndKill(-12500, -3250, '8')
	MoveAggroAndKill(-15750, -1750, '9')

	Info('Getting the Wailing Lord and the Gift of Griffons quests rewards')
	Local $npc = GetNearestNPCToCoords(-15750, -1700)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CC06)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CC07)
	RandomSleep(GetPing() + 750)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CD07)
	RandomSleep(GetPing() + 750)
	Return $SUCCESS
EndFunc


Func TempleLoot()
	MoveTo(-9800, -4800)
	MoveTo(-6800, -3800)
	MoveTo(-8000, 5100)
	MoveTo(1550, 5200)
	MoveTo(1700, 2400)
	MoveTo(1800, 400)
	Info('Opening chest')
	; Doubled to secure looting
	For $i = 1 To 2
		MoveTo(1800, 400)
		RandomSleep(5000)
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next

	Info('Getting Restore the Temple of War and Khobay the Betrayer quests rewards')
	Local $npc = GetNearestNPCToCoords(1850, -200)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CF06)
	RandomSleep(GetPing() + 750)
	Dialog(0x80CF07)
	RandomSleep(GetPing() + 750)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80E006)
	RandomSleep(GetPing() + 750)
	Dialog(0x80E007)
	RandomSleep(GetPing() + 750)

	Info('Getting the Tower of Strength quest reward')
	Local $npc = GetNearestNPCToCoords(200, -1900)
	GoToNPC($npc)
	RandomSleep(GetPing() + 750)
	Dialog(0x80D307)
	RandomSleep(GetPing() + 750)
	Return $SUCCESS
EndFunc


;~ Pick up the Unholy Texts
Func PickUpUnholyTexts()
	Local $agent
	Local $item
	Local $attempts = 1
	For $i = 1 To GetMaxAgents()
		$agent = GetAgentByID($i)
		If (DllStructGetData($agent, 'Type') <> 0x400) Then ContinueLoop
		$item = GetItemByAgentID($i)
		If (DllStructGetData($item, 'ModelID') == $ID_FoW_Unholy_Texts) Then
			Info('Unholy Texts: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			While IsPlayerAlive() And Not IsRunFailed() And GetAgentExists($i)
				If Mod($attempts, 20) == 0 Then
					Local $attempt = Floor($attempts / 20)
					Error('Could not get Unholy Texts at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
					Error('Attempt ' & $attempt)
					Local $attemptPlaces[8] = [2300, 14700, 1800, 16500, 4400, 15800, 1900, 13800]
					MoveTo($attemptPlaces[Floor($attempts / 10)] - 2, $attemptPlaces[Floor($attempts / 10) - 1])
				EndIf
				$attempts += 1
				RandomSleep(1000)
			WEnd
			Return True
		EndIf
	Next
	Return False
EndFunc


;~ Return true if agent is a shardwolf
Func IsShardWolf($agent)
	Return DllStructGetData($agent, 'ModelID') == $Shard_Wolf_ModelID
EndFunc


;~ Kill shardwolf if found
Func KillShardWolf()
	Local $foes = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS, IsShardWolf)
	If IsArray($foes) And UBound($foes) > 0 Then ; Shard Wolf found
		Local $shardWolf = $foes[0]
		MoveAggroAndKill(DllStructGetData($shardWolf, 'X'), DllStructGetData($shardWolf, 'Y'))
	EndIf
	Return $SUCCESS
EndFunc
