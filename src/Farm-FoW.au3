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
Global Const $FoWFarmerSkillbar = ''
Global Const $FoWFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'XXmn average in NM' & @CRLF _
	& 'YYmn  average in HM with consets (automatically used if HM is on)' & @CRLF _
	& 'If you add a summon to this farm, do it so that it despawned once doing green forest'

Global $FOW_FARM_SETUP = False
Global $FoWDeathsCount = 0
Global Const $ID_Quest_WailingLord = 0xCC
Global Const $Shard_Wolf_PlayerNumber = 2835
Global Const $ID_FoW_Unholy_Texts = 2619


; TODO:
; - open reward chests

;~ Main method to farm FoW
Func FoWFarm($STATUS)
	If Not $FOW_FARM_SETUP Then
		SetupFoWFarm()
		$FOW_FARM_SETUP = True
	EndIf

	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Temple_of_the_Ages Then DistrictTravel($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	Info('Making way to Balthazar statue')
	MoveTo(-2500, 18700)
	SendChat('/kneel', '')
	RndSleep(3000)
	GoToNPC(GetNearestNPCToCoords(-2500, 18700))
	RndSleep(GetPing() + 250)
	Dialog(0x85)
	RndSleep(GetPing() + 250)
	Dialog(0x86)
	RndSleep(GetPing() + 250)
	WaitMapLoading($ID_Fissure_of_Woe)

	If $STATUS <> 'RUNNING' Then Return 2

	Return FoWFarmLoop()
EndFunc


;~ FoW farm setup
Func SetupFoWFarm()
	Info('Setting up farm')
	; Make group
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func FoWFarmLoop()
	AdlibRegister('FoWGroupIsAlive', 10000)
	$FoWDeathsCount = 0
	If IsHardmodeEnabled() Then UseConset()

	If TowerOfCourage() Then Return 1
	If TheGreatBattleField() Then Return 1
	If TheTempleOfWar() Then Return 1
	If TheSpiderCave_and_FissureShore() Then Return 1
	If LakeOfFire() Then Return 1
	If TowerOfStrengh() Then Return 1
	If BurningForest() Then Return 1
	If ForestOfTheWailingLord() Then Return 1
	If GriffonRun() Then Return 1
	If TempleLoot() Then Return 1

	AdlibUnRegister('FoWGroupIsAlive')
	Return 0
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
	MoveAggroAndKill(-14000, -3000, '4')
	Local $me = GetMyAgent()
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), -15000, -2000) > $RANGE_ADJACENT
		MoveTo(-15000, -2000)
		Sleep(3000)
		$me = GetMyAgent()
	WEnd
	MoveAggroAndKill(-15500, -2000, '5')

	Info('Getting Tower of Courage quest and reward')
	MoveTo(-15700, -1700)
	Local $npc = GetNearestNPCToCoords(-15750, -1700)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80D401)
	RndSleep(GetPing() + 250)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80D407)
	RndSleep(GetPing() + 250)

	Info('Getting The Wailing Lord quest')
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80CC01)
	RndSleep(GetPing() + 250)
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
	RndSleep(GetPing() + 250)
	Dialog(0x80CB01)
	RndSleep(GetPing() + 250)

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
	RndSleep(GetPing() + 250)
	Dialog(0x80CB07)
	RndSleep(GetPing() + 250)

	Info('Getting the Eternal Forgemaster quest')
	MoveTo(-7400, 11700)
	GoToNPC(GetNearestNPCToCoords(-7450, 11700))
	RndSleep(GetPing() + 250)
	Dialog(0x80D101)
	RndSleep(GetPing() + 250)

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

	Info('Getting the Eternal Forgemaster quest reward')
	MoveTo(1850, -150)
	Local $npc = GetNearestNPCToCoords(1850, -200)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80D107)
	RndSleep(GetPing() + 250)

	Info('Getting the Defend the Temple of War quest')
	MoveTo(1850, -150)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80CA01)
	RndSleep(GetPing() + 250)

	Info('Waiting the defense, feeling cute, might optimise later')
	Info('Sleeping for 480s')
	Sleep(480000)

	Info('Getting the Defend the Temple of War quest reward')
	MoveTo(1850, -150)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80CA07)
	RndSleep(GetPing() + 250)

	Info('Getting the Restore the Temple of War quest')
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80CF03)
	RndSleep(GetPing() + 250)
	Dialog(0x80CF01)
	RndSleep(GetPing() + 250)

	Info('Getting the Khobay the Betrayer quest')
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80E003)
	RndSleep(GetPing() + 250)
	Dialog(0x80E001)
	RndSleep(GetPing() + 250)

	Info('Getting the Tower of Strength quest')
	MoveTo(200, -1900)
	GoToNPC(GetNearestNPCToCoords(150, -1950))
	RndSleep(GetPing() + 250)
	Dialog(0x80D301)
	RndSleep(GetPing() + 250)
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
	RndSleep(GetPing() + 250)
	Dialog(0x80D001)
	RndSleep(GetPing() + 250)

	KillShardWolf()

	Info('Clearing cave')
	MoveAggroAndKill(1400, -11600, '1')
	MoveAggroAndKill(-900, -9400, '2')
	Info('Sleeping for 20s')
	Sleep(20000)
	MoveAggroAndKill(-2500, -8500, '3')
	Info('Sleeping for 20s')
	Sleep(20000)
	MoveAggroAndKill(-4000, -9400, '4')
	Info('Sleeping for 20s')
	Sleep(20000)
	MoveAggroAndKill(-6100, -11400, '5')
	Info('Sleeping for 20s')
	Sleep(20000)
	MoveAggroAndKill(-7800, -13400, '6')
	Info('Sleeping for 20s')
	Sleep(20000)
	MoveAggroAndKill(-8400, -15800, '7')
	Info('Sleeping for 20s')
	Sleep(20000)
	MoveAggroAndKill(-8600, -17300, '5')
	Info('Sleeping for 60s')
	Sleep(60000)

	MoveTo(-10000, -18500)
	MoveTo(-12900, -18000)

	KillShardWolf()

	Info('Going back')
	MoveAggroAndKill(-8800, -18200, '1')
	MoveAggroAndKill(-8500, -16200, '2')

	MoveTo(-6700, -11750)
	MoveTo(-1600, -8750)
	MoveTo(1000, -11200)
EndFunc


Func LakeOfFire()
	Info('Khobay murder time')
	MoveAggroAndKill(4500, -9800, '1')
	MoveAggroAndKill(7350, -11250, '2')
	MoveAggroAndKill(9600, -8500, '3')
	MoveAggroAndKill(20500, -8100, '4')
	MoveAggroAndKill(20700, -12400, '5')
	MoveAggroAndKill(18300, -14000, '6')
	MoveAggroAndKill(19500, -15000, '7')
EndFunc


Func TowerOfStrengh()
	Info('Clearing area of Tower of Strengh')
	MoveTo(18250, -14000)
	MoveTo(20700, -12400)
	MoveTo(20500, -8100)
	MoveTo(9600, -8500)
	MoveAggroAndKill(11500, -4600, '3')
	MoveAggroAndKill(15000, -3100, '4')
	MoveAggroAndKill(15800, -300, '5')

	Info('Going to trigger pnj')
	MoveAggroAndKill(15300, -1400, '1')
	MoveAggroAndKill(10300, -5900, '2')
	MoveAggroAndKill(6500, -11200, '3')
	MoveAggroAndKill(1600, -7200, '4')

	Info('And back to tower')
	MoveAggroAndKill(6500, -12000, '1')
	MoveAggroAndKill(10300, -5900, '2')
	MoveAggroAndKill(15400, -1400, '3')
	MoveAggroAndKill(16750, -1750, '4')
	MoveAggroAndKill(12300, 250, '4')
	KillShardWolf()
	; Entering the tower garantees the npc arrived
	Local $me = GetMyAgent()
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), 16700, -1700) > $RANGE_NEARBY
		MoveTo(16700, -1700)
		Sleep(1000)
		$me = GetMyAgent()
	WEnd
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
	RndSleep(GetPing() + 250)
	Dialog(0x80CE01)
	RndSleep(GetPing() + 250)

	Info('Clearing Burning Forest')
	FlagMoveAggroAndKill(15000, 9000, '1')
	FlagMoveAggroAndKill(17500, 9500, '1')
	FlagMoveAggroAndKill(20000, 10000, '2')
	FlagMoveAggroAndKill(20000, 12000, '4')
	FlagMoveAggroAndKill(22500, 14000, '5')
	KillShardWolf()
	FlagMoveAggroAndKill(22500, 16000, '6')
	FlagMoveAggroAndKill(21000, 15000, '7')
	FlagMoveAggroAndKill(16000, 10000, '8')

	Info('Getting the Slaves of Menzies quest reward')
	MoveTo(12000, 6600)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80CE07)
	RndSleep(GetPing() + 250)

	Info('Heading to Forest of the Wailing Lords')
	MoveAggroAndKill(9200, 12500, '1')
	FlagMoveAggroAndKill(1600, 12300, '2')
	KillShardWolf()
	FlagMoveAggroAndKill(-10750, 6300, '3')
EndFunc


Func ForestOfTheWailingLord()
	Info('Clearing forest')
	MoveAggroAndKill(-17500, 9750, '1')
	MoveAggroAndKill(-20200, 9500, '2')
	MoveAggroAndKill(-20750, 12200, '3')
	MoveAggroAndKill(-18200, 15000, '4')
	MoveAggroAndKill(-15900, 13100, '5')

	KillShardWolf()

	; Safer move
	MoveAggroAndKill(-20200, 14000, '6', $RANGE_SPELLCAST)

	Info('Safely pulling')
	CommandHero(1, -20200, 13600)
	CommandHero(2, -19900, 14000)
	CommandHero(3, -20400, 13500)
	CommandHero(4, -19900, 14250)
	CommandHero(5, -20000, 13800)
	CommandHero(6, -19750, 13800)
	CommandHero(7, -19900, 13600)

	Local $questState = 1
	While Not GetIsDead() And $questState <> 19
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
	RndSleep(GetPing() + 250)
	Dialog(0x80CD01)
	RndSleep(GetPing() + 250)
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
	Exit
	RndSleep(GetPing() + 250)
	;Dialog(0x80D401)
	RndSleep(GetPing() + 250)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	;Dialog(0x80D407)
	RndSleep(GetPing() + 250)
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
	For $i = 0 To 1
		MoveTo(1800, 400)
		RndSleep(5000)
		TargetNearestItem()
		ActionInteract()
		RndSleep(2500)
		PickUpItems()
	Next

	Info('Getting Restore the Temple of War and Khobay the Betrayer quests rewards')
	Local $npc = GetNearestNPCToCoords(1850, -200)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80CF06)
	RndSleep(GetPing() + 250)
	Dialog(0x80CF07)
	RndSleep(GetPing() + 500)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80E006)
	RndSleep(GetPing() + 250)
	Dialog(0x80E007)
	RndSleep(GetPing() + 250)

	Info('Getting the Tower of Strength quest reward')
	Local $npc = GetNearestNPCToCoords(200, -1900)
	GoToNPC($npc)
	RndSleep(GetPing() + 250)
	Dialog(0x80D307)
	RndSleep(GetPing() + 250)
EndFunc


;~ Did run fail ?
Func FoWIsFailure()
	If ($FoWDeathsCount > 5) Then
		AdlibUnregister('FoWGroupIsAlive')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the groupIsAlive variable, this function is run on a fixed timer
Func FoWGroupIsAlive()
	$FoWDeathsCount += IsGroupAlive() ? 0 : 1
EndFunc


;~ Pick up the Unholy Texts
Func PickUpUnholyTexts()
	Local $agent
	Local $item
	Local $deadlock
	For $i = 1 To GetMaxAgents()
		$agent = GetAgentByID($i)
		If (DllStructGetData($agent, 'Type') <> 0x400) Then ContinueLoop
		$item = GetItemByAgentID($i)
		If (DllStructGetData(($item), 'ModelID') == $ID_FoW_Unholy_Texts) Then
			Info('Unholy Texts: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			$deadlock = TimerInit()
			While Not GetIsDead() And GetAgentExists($i)
				If TimerDiff($deadlock) > 20000 Then
					Error('Could not get Unholy Texts at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
					Return False
				EndIf
				RndSleep(500)
			WEnd
			Return True
		EndIf
	Next
	Return False
EndFunc


; Return true if agent is a shardwolf
Func IsShardWolf($agent)
	Return DllStructGetData($agent, 'PlayerNumber') == $Shard_Wolf_PlayerNumber
EndFunc


; Kill shardwolf if found
Func KillShardWolf()
	Local $agents = GetFoesInRangeOfAgent(GetMyAgent(), $RANGE_COMPASS, IsShardWolf)
	; Shard Wolf found
	If $agents[0] > 0 Then
		Local $shardWolf = $agents[1]
		MoveAggroAndKill(DllStructGetData($shardWolf, 'X'), DllStructGetData($shardWolf, 'Y'))
	EndIf
EndFunc