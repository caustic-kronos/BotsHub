#CS ===========================================================================
======================================
|  	 Underworld clearing farm bot	 |
|	 Authors: Akiro/The Great Gree   |
| Rewrite Author for BotsHub: Gahais |					 |
======================================
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

Opt('MustDeclareVars', True)

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $UnderworldFarmInformations = 'For best results, don''t cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'This bot is unfinished. Clearing remaining zones of UW and quests completion can still be added to this bot' & @CRLF
; Average duration ~ 5 minutes
Global Const $UW_FARM_DURATION = 60 * 60 * 1000
Global Const $MAX_UW_FARM_DURATION = 120 * 60 * 1000
Global $UWFarmTimer = Null
Global $UW_FARM_SETUP = False


;~ Main loop function for farming glob of ectoplasm
Func UnderworldFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $UW_FARM_SETUP Then SetupUnderworldFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Local $result = EnterUnderworld()
	If $result <> $SUCCESS Then Return $result
	$result = UnderworldFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared Underworld')
	If $result == $FAIL Then Info('Could not clear Underworld')
	TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	Return $result
EndFunc


Func SetupUnderworldFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	SwitchToHardModeIfEnabled()
	Sleep(500 + GetPing())
	If SetupPlayerUnderworldFarm() == $FAIL Then Return $FAIL
	If SetupTeamUnderworldFarm() == $FAIL Then Return $FAIL
	Sleep(500 + GetPing())
	$UW_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerUnderworldFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		Sleep(500 + GetPing())
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
	Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
	EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamUnderworldFarm()
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


Func EnterUnderworld()
	If GetMapID() <> $ID_Temple_of_the_Ages Then TravelToOutpost($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	If GUICtrlRead($GUI_Checkbox_UseScrolls) == $GUI_CHECKED Then
		Info('Using scroll to enter Underworld')
		Local $uwScroll = GetItemByModelID($ID_UW_Scroll)
		If DllStructGetData($uwScroll, 'Slot') > 0 Then ; slots are numbered from 1, if scroll is not in any bag then Slot is 0
			UseItem($uwScroll)
			WaitMapLoading($ID_Underworld)
			If GetMapID() <> $ID_Underworld Then
				Warn('Used scroll but still could not enter Underworld. Ensure that player has correct scroll in inventory')
				Return $PAUSE
			EndIf
		Else
			Warn('Could not find scroll to enter Underworld in player''s inventory')
			Return $PAUSE
		EndIf
	Else ; not using scroll method to enter Underworld
		Info('Moving to Grenth statue to enter Underworld')
		MoveTo(-4170, 19759)
		MoveTo(-4124, 19829)
		SendChat('/kneel', '')
		RandomSleep(GetPing() + 3000)
		GoToNPC(GetNearestNPCToCoords(-4124, 19829))
		RandomSleep(GetPing() + 750)
		Dialog(0x85) ; entering UW dialog option
		RandomSleep(GetPing() + 750)
		Dialog(0x86) ; accepting dialog option
		RandomSleep(GetPing() + 750)
		WaitMapLoading($ID_Underworld)
		If GetMapID() <> $ID_Underworld Then
			Info('Could not enter Underworld. Ensure that it''s Pantheon bonus week or that player has enough gold in inventory')
			Return $FAIL
		EndIf
	EndIf
	Return $SUCCESS
EndFunc


Func UnderworldFarmLoop()
	Sleep(2000)
	If IsPlayerDead() Then Return $FAIL
	Info('Starting Farm')
	$UWFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run

	ClearTheChamberUnderworld()

	; killing right side
	MoveAggroAndKill(-5897, 12496)
	Info('moving to smites')
	MoveAggroAndKill(-5129, 13248)
	MoveAggroAndKill(-4, 13337)
	MoveAggroAndKill(978, 12601)
	MoveAggroAndKill(1263, 10332)
	MoveAggroAndKill(1703, 10411)
	MoveAggroAndKill(2521, 10263)
	MoveAggroAndKill(3189, 9148)
	; killing skeletons
	MoveAggroAndKill(3255, 8279)
	MoveAggroAndKill(3960, 7966)
	Info('Killing Aatxes and Grasping Darkness')
	MoveAggroAndKill(3960, 7966)
	MoveAggroAndKill(5286, 7761)
	MoveAggroAndKill(5590, 8664)
	MoveAggroAndKill(5662, 9962)
	MoveAggroAndKill(6399, 10817)
	MoveAggroAndKill(7459, 11497)
	MoveAggroAndKill(8610, 12048)
	; killing skeletons
	MoveAggroAndKill(8966, 12885)
	MoveAggroAndKill(8893, 13807)
	MoveAggroAndKill(8480, 14491)
	MoveAggroAndKill(7321, 15188)
	Info('Killing Smite mob 1')
	MoveAggroAndKill(7722, 16315)
	MoveAggroAndKill(8881, 17134)
	MoveAggroAndKill(9142, 16760)
	Info('Killing Smite mob 2')
	MoveAggroAndKill(10193, 15872)
	MoveAggroAndKill(11159, 15195)
	MoveAggroAndKill(12473, 15153)
	Info('Killing Smite mob 3')
	MoveAggroAndKill(13973, 17130)
	MoveAggroAndKill(13920, 19641)
	MoveAggroAndKill(12576, 20212)
	MoveAggroAndKill(11829, 20188)
	MoveAggroAndKill(11829, 20188)
	Info('Killing Smite mob 4')
	MoveAggroAndKill(11125, 20565)
	MoveAggroAndKill(9660, 21593)
	MoveAggroAndKill(8277, 22011)
	Info('Killing Smite mob 5')
	MoveAggroAndKill(7785, 21633)
	MoveAggroAndKill(6229, 20807)
	MoveAggroAndKill(6034, 19970)
	MoveAggroAndKill(5635, 18749)
	Info('Killing Smite mob 6')
	MoveAggroAndKill(5175, 17857)
	MoveAggroAndKill(4217, 16400)
	Info('Killing Smite mob 7')
	MoveAggroAndKill(4121, 15928)
	MoveAggroAndKill(2643, 16990)
	MoveAggroAndKill(2754, 18508)
	MoveAggroAndKill(2827, 19050)
	Info('Killing Smite mob 8')
	MoveAggroAndKill(2253, 19856)
	MoveAggroAndKill(784, 19901)
	MoveAggroAndKill(-498, 18792)
	Info('Killing Smite mob 9')
	MoveAggroAndKill(-837, 18762)
	MoveAggroAndKill(884, 20412)
	MoveAggroAndKill(418, 21487)
	MoveAggroAndKill(-1481, 20952)
	Info('Killing Smite mob 10')
	MoveAggroAndKill(-2031, 20595)
	MoveAggroAndKill(-2568, 18775)
	MoveAggroAndKill(-4033, 18700)
	MoveAggroAndKill(-4701, 19366)

	Info('move to planes')
	MoveAggroAndKill(-3924, 18667)
	MoveAggroAndKill(-2977, 18708)
	MoveAggroAndKill(-2444, 19337)
	MoveAggroAndKill(-2015, 20593)
	MoveAggroAndKill(-1365, 21015)
	MoveAggroAndKill(398, 21353)
	MoveAggroAndKill(892, 20300)
	MoveAggroAndKill(2128, 19929)
	MoveAggroAndKill(2799, 18863)
	MoveAggroAndKill(2514, 17133)
	MoveAggroAndKill(3828, 15754)
	MoveAggroAndKill(4514, 15732)
	MoveAggroAndKill(4718, 16549)
	MoveAggroAndKill(6093, 19040)
	MoveAggroAndKill(8715, 18244)
	MoveAggroAndKill(8929, 17621)
	MoveAggroAndKill(7131, 15463)
	MoveAggroAndKill(8670, 14309)
	MoveAggroAndKill(8888, 13504)
	MoveAggroAndKill(8599, 12367)
	MoveAggroAndKill(7594, 11607)
	MoveAggroAndKill(5472, 10107)
	MoveAggroAndKill(5572, 8107)
	MoveAggroAndKill(4374, 7121)
	MoveAggroAndKill(4144, 5637)
	MoveAggroAndKill(3131, 5571)
	MoveAggroAndKill(2179, 4514)
	MoveAggroAndKill(1545, 4634)
	MoveAggroAndKill(217, 3801)
	Info('Killing skeletons')
	MoveAggroAndKill(123, 3678)
	Info('Moving to worms')
	MoveTo(-61, 2300)
	MoveAggroAndKill(691, 1431)
	Info('wait for traps')
	RandomSleep(2000)
	; redoing from traps
	MoveAggroAndKill(1835, 2562)
	MoveAggroAndKill(2851, 2886)
	MoveAggroAndKill(3592, 2494)
	Info('Killing Worm Mob 1')
	MoveAggroAndKill(3295, 1343)
	MoveAggroAndKill(4075, 1205)
	MoveAggroAndKill(4792, 1990)
	Info('Killing Worm Mob 2')
	MoveAggroAndKill(4865, 550)
	Info('Killing Worm Mob 3')
	MoveAggroAndKill(5643, 618)
	MoveAggroAndKill(6585, 1508)
	Info('kill charged blackness')
	MoveAggroAndKill(7277, 2079)
	MoveAggroAndKill(7983, 938)
	MoveAggroAndKill(7865, 136)
	Info('Killing Worm Mob 4')
	MoveAggroAndKill(8477, -626)
	MoveAggroAndKill(8706, -1135)
	; popup
	MoveAggroAndKill(7896, -1886)
	MoveAggroAndKill(8114, -3608)
	MoveAggroAndKill(7934, -4267)
	MoveAggroAndKill(8781, -4834)
	MoveAggroAndKill(8186, -6531)
	MoveAggroAndKill(8040, -7296)
	; kill mobs
	MoveAggroAndKill(7966, -7743)
	MoveAggroAndKill(8484, -8004)
	; kill mobs
	MoveAggroAndKill(9747, -8488)
	MoveAggroAndKill(9621, -9465)
	Info('At planes')
	Info('Collecting Lords')
	MoveAggroAndKill(9153, -10780)
	MoveAggroAndKill(10020, -11292)
	MoveAggroAndKill(10533, -10474)
	; kill mobs
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(10753, -11413)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(11809, -10680)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(10555, -10746)
	MoveAggroAndKill(9166, -11161)
	Info('Moving to spot two')
	MoveAggroAndKill(10469, -10241)
	MoveAggroAndKill(12146, -10312)
	MoveAggroAndKill(12852, -9597)
	MoveAggroAndKill(13227, -9181)
	Info('Killing...')
	MoveAggroAndKill(13192, -9027)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(13102, -9902)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(12702, -9263)
	MoveAggroAndKill(11573, -8295)
	MoveAggroAndKill(11150, -8305)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(11850, -8248)
	MoveAggroAndKill(13077, -7583)
	Info('Moving to spot 3')
	MoveAggroAndKill(13280, -9025)
	MoveAggroAndKill(13668, -12144)
	MoveAggroAndKill(12009, -13476)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(13019, -12773)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(10652, -14686)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(11164, -13191)
	Info('Moving to spot 4')
	MoveAggroAndKill(10641, -11650)
	MoveAggroAndKill(8618, -11218)
	MoveAggroAndKill(7515, -12059)
	MoveAggroAndKill(8327, -13146)
	MoveAggroAndKill(8272, -14002)
	Info('Killing Mindblade Mob 1')
	MoveAggroAndKill(8283, -13214)
	Info('Killing Mindblade Mob 2')
	MoveAggroAndKill(8098, -13962)
	MoveAggroAndKill(7496, -15081)
	Info('Killing Mindblade Mob 3')
	MoveAggroAndKill(8268, -13928)
	MoveAggroAndKill(7807, -12111)
	MoveAggroAndKill(9218, -11620)
	Info('Moving to spot 5')
	MoveAggroAndKill(7322, -12220)
	MoveAggroAndKill(6825, -13247)
	MoveAggroAndKill(7392, -14467)
	MoveAggroAndKill(6896, -15201)
	MoveAggroAndKill(5986, -14869)
	Info('Killing Skeletons Mob')
	MoveAggroAndKill(6971, -16245)
	MoveAggroAndKill(6519, -17280)

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


Func ClearTheChamberUnderworld()
	Info('Moving to left of the stairs')
	MoveAggroAndKill(-495, 6509)
	MoveAggroAndKill(-2191, 5688)
	Info('Moving to the middle of the chamber')
	MoveAggroAndKill(-1371, 7179)
	MoveAggroAndKill(-1244, 7835)
	Info('Killing Pop-Up')
	MoveAggroAndKill(-862, 8923)
	Info('Going up Middle of chamber stairs')
	MoveAggroAndKill(-1669, 10631)

	Info('Going for skeletons')
	MoveAggroAndKill(-2706, 10149)
	Info('Killing skeletons')
	MoveAggroAndKill(-1767, 10583)
	MoveAggroAndKill(-694, 8957)

	Info('Moving to Aatxes at top right of stairs')
	MoveAggroAndKill(-106, 9116)
	MoveAggroAndKill(848, 9720)
	Info('Killing pop-up')
	MoveAggroAndKill(1204, 10380)

	Info('Bottom Stairs right side chamber')
	MoveAggroAndKill(1119, 12220)
	MoveAggroAndKill(1659, 12775)
	MoveAggroAndKill(2503, 13092)
	MoveAggroAndKill(3242, 12862)
	MoveAggroAndKill(2252, 13197)
	MoveAggroAndKill(1146, 12451)

	Info('Going back for quest')
	MoveAggroAndKill(1196, 10567)
	MoveAggroAndKill(461, 9219)
	MoveAggroAndKill(879, 7759)
	MoveAggroAndKill(910, 7115)
	MoveTo(378, 7209)

	Info('Taking ''Clear the Chamber'' Quest')
	Local $Lost_Soul
	$Lost_Soul = GetNearestNPCToCoords(246, 7177)
	GoToNPC($Lost_Soul)
	Dialog(0x0806501)

	; bottem left stairs
	MoveAggroAndKill(187, 6606)
	; check top left side
	MoveAggroAndKill(-1977, 5802)
	; going to right side
	MoveAggroAndKill(-1207, 6524)
	MoveAggroAndKill(-1361, 7832)

	MoveAggroAndKill(-805, 8886)
	MoveAggroAndKill(553, 9338)
	; wait at top right stairs for grasping darkness
	Sleep(30000)
	; top middle chamber stairs
	MoveAggroAndKill(-1495, 10562)
	MoveAggroAndKill(-2824, 10222)

	; doing 'Clear the Chamber' quest
	MoveAggroAndKill(-4210, 11372)
	MoveAggroAndKill(-4675, 11733)
	; doing left side
	MoveAggroAndKill(-4186, 12722)
	MoveAggroAndKill(-4050, 13182)
	MoveAggroAndKill(-5572, 13250)
	Info('Killing Dryders')
	; accept reward
	MoveAggroAndKill(-5694, 12772)
	MoveAggroAndKill(-5922, 11468)
	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc