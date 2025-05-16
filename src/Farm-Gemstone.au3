; Author: Crux
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHInfo WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

#include-once

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include '../lib/Utils-Debugger.au3'

; ==== Constants ====
Global Const $GemstoneFarmSkillbar = 'OQBCAswDPVP/DMd5Zu2Nd6B'
Global Const $GemstoneHeroSkillbar = 'https://gwpvx.fandom.com/wiki/Build:Team_-_7_Hero_AFK_Gemstone_Farm'
Global Const $GemstoneFarmInformations = 'Requirements:' & @CRLF _
	& '- Access to mallyx (finished all 4 doa parts)' & @CRLF _
	& '- Strong hero build' &@CRLF _
	& ' ' & @CRLF _
	& ' ' & @CRLF _
	& 'Usage:' & @CRLF _
	& '- travel DoA, select NM, start the bot' & @CRLF _
; Average duration ~ 12m30sec
Global Const $GEMSTONE_FARM_DURATION = (12 * 60 + 30) * 1000

;=== Configuration / Globals ===
Global $g_runs            = 0
Global $g_lastXP          = 0
Global Const $g_startX    = -3606    
Global Const $g_startY    = -5347    
Global Const $g_fightDist = 1500
Global $REMEMBEREXP = 0
Global $TOTALSKILLS = 7
Global $gemStoneDeathCount = 0

Global $GEMSTONE_FARM_SETUP = False

Global Const $ID_Zhellix_Agent  = 15

Func GemstoneFarm($STATUS)
    if Not $GEMSTONE_FARM_SETUP Then
        SetupGemstoneFarm()
        $GEMSTONE_FARM_SETUP = True
    EndIf
	
    If $STATUS <> 'RUNNING' Then Return 2

    Local $timePerRun = UpdateStats(-1, Null)
    Local $timer      = TimerInit()
    UpdateProgressBar(True, $timePerRun)
    AdlibRegister("UpdateProgressBar", 5000)
	AdlibRegister('GemStoneGroupIsAlive', 10000)
    
    Local $ret = GemstoneFarmLoop()
    AdlibUnRegister("UpdateProgressBar")
	Info("$ret: " & $ret)
    UpdateStats($ret, $timer)
    Return 0
EndFunc

;~ Gemstone farm setup
Func SetupGemstoneFarm()
    Info('Settup up farm')
    SwitchMode($ID_NORMAL_MODE)
    Info('Preparations complete')
EndFunc

;~ Gemstone farm loop
Func GemstoneFarmLoop()
    ; Need to be done here in case bot comes back from inventory management
	IF GETMAPID() <> 474 THEN
		DistrictTravel(474, $DISTRICT_NAME)
		WAITMAPLOADING()
	ENDIF

	TalkToZhellix()
	WalkToSpot()
	Defend()
ENDFUNC

FUNC TalkToZhellix()
	$g_runs += 1
    Info("Starting run " & $g_runs)
    Local $z = GETNEARESTNPCTOCOORDS(6086, -13397)
    ChangeTarget($z)
    GOTONPC($z)
    DIALOG(0x84)
    WAITMAPLOADING()
ENDFUNC

FUNC WalkToSpot()
    $g_lastXP = GetExperience()
    Sleep(2000)
    CommandHero(3,-3190,-4928)
    CommandHero(2,-3050,-5304)
    CommandAll(-3449,-5229)
    MoveTo($g_startX, $g_startY)

    UseLegionary()
ENDFUNC

FUNC UseLegionary()
	LOCAL $ABAG
	LOCAL $AITEM
	SLEEP(200)
	FOR $I = 1 TO 4
		$ABAG = GETBAG($I)
		FOR $J = 1 TO DLLSTRUCTGETDATA($ABAG, "Slots")
			$AITEM = GETITEMBYSLOT($ABAG, $J)
			IF DLLSTRUCTGETDATA($AITEM, "ModelID") = 37810 THEN
				USEITEM($AITEM)
				Info("Using Legionary Stone")
				RETURN TRUE
			ENDIF
		NEXT
	NEXT
ENDFUNC

; TODO add check if Group is still alive
Func RunFail()
	If GetIsDead($ID_Zhellix_Agent) Or GetIsDead(GetMyAgent()) Then Return 1
EndFunc

;~ Updates the gemStoneDeathCount variable
Func GemStoneGroupIsAlive()
	$gemStoneDeathCount += IsGroupAlive() ? 0 : 1
EndFunc

;~ Return to outpost in case of failure
Func ResignAndReturnToGate()
	If GetIsDead($ID_Zhellix_Agent) Then
		Warn('Zhellix died.')
	ElseIf GetIsDead() Then
		Warn('Player died')
	EndIf
	DistrictTravel(474, $DISTRICT_NAME)
	Return 1
EndFunc

FUNC DEFEND()
	Info("Defending...")
	$TIMER = TIMERINIT()
	$REMEMBEREXP = GETEXPERIENCE()

	Sleep(5000)

	WHILE ZHELLIXWAITING()
		GemStoneGroupIsAlive()
		If (RunFail()) Then Return ResignAndReturnToGate()
		$REMEMBEREXP = GETEXPERIENCE()
		SLEEP(1000)
		FIGHT()
		PICKUPLOOTANDMOVEBACK()
	WEND
ENDFUNC

FUNC FIGHT()
	Info("Fighting!")
	IF GETISDEAD(-2) THEN RETURN
	IF GETDISTANCE(GetMyAgent(), GETNEARESTENEMYTOAGENT(GetMyAgent())) < $g_fightDist AND DLLSTRUCTGETDATA(GETNEARESTENEMYTOAGENT(GetMyAgent()), "ID") <> 0 THEN
		GemKill()
	ENDIF
ENDFUNC

FUNC GemKill()
	IF GETISDEAD(-2) THEN RETURN
	DO
		IF GETMAPLOADING() == 2 THEN DISCONNECTED()
		Local $USESKill = -1
		Local $TARGET = FindDryderOrDreamer()
		IF $TARGET = 0 THEN
			$TARGET = GETNEARESTENEMYTOAGENT(GetMyAgent())
			Local $DISTANCE = GETDISTANCE($TARGET, GetMyAgent())
		ELSE
			$DISTANCE = 0
			Local $SPECIALTARGET = TRUE
		ENDIF
		IF DLLSTRUCTGETDATA($TARGET, "ID") <> 0 AND $DISTANCE < $g_fightDist THEN
			CHANGETARGET($TARGET)
			RNDSLEEP(150)
			CALLTARGET($TARGET)
			RNDSLEEP(150)
			ATTACK($TARGET)
			RNDSLEEP(150)
		ELSEIF DLLSTRUCTGETDATA($TARGET, "ID") = 0 OR $DISTANCE > $g_fightDist OR GETISDEAD(-2) THEN
			EXITLOOP
		ENDIF
		FOR $I = 0 TO $TOTALSKILLS
			Local $TARGETHP = DLLSTRUCTGETDATA(GETCURRENTTARGET(), "HP")
			IF GETISDEAD(-2) THEN EXITLOOP
			IF $TARGETHP = 0 THEN EXITLOOP

			IF $DISTANCE > $g_fightDist AND NOT $SPECIALTARGET THEN EXITLOOP
			Local $ENERGY = GETENERGY(-2)
			Local $RECHARGE = DLLSTRUCTGETDATA(GetSkillbarSkillRecharge($I + 1, 0), 0)
			Local $ENERGYCOST = GETENERGYCOST(GetSkillbarSkillID($I + 1, 0))
			Local $ACTIVATIONTIME = GETACTIVATIONTIME(GetSkillbarSkillID($I + 1, 0))
			IF $RECHARGE = 0 AND $ENERGY >= $ENERGYCOST THEN
				$USESKill = $I + 1
				SLEEP(250)
				USESKILL($USESKill, $TARGET)
				SLEEP($ACTIVATIONTIME + 500)
			ENDIF
			IF $I = $TOTALSKILLS THEN $I = 0
		NEXT
	UNTIL DLLSTRUCTGETDATA($TARGET, "ID") = 0 OR $DISTANCE > $g_fightDist OR GETISDEAD(-2)
	IF NOT GETISDEAD(-2) THEN MOVETO($g_startX, $g_startY)
ENDFUNC

; TODO: Fix - currently doesnt detect prio enemys
FUNC FINDDRYDERORDREAMER()
	Local $SEARCHDISTANCE = 1700
	FOR $I = 0 TO GetMaxAgents()
		Local $AGENT = GetAgentByID($I)
		IF GETISDEAD($AGENT) THEN CONTINUELOOP
		IF DLLSTRUCTGETDATA($AGENT, "Allegiance") <> 3 OR GETISDEAD($AGENT) OR GETDISTANCE(-2, $AGENT) > $SEARCHDISTANCE THEN CONTINUELOOP
		Local $MODELID = DLLSTRUCTGETDATA($AGENT, "AgentModelType")
		SWITCH $MODELID
			CASE 5216
				Info("Targeting Dreamy")
				RETURN $AGENT
		ENDSWITCH
	NEXT
	FOR $I = 0 TO GetMaxAgents()
		$AGENT = GetAgentByID($I)
		IF GETISDEAD($AGENT) OR GETISDEAD($AGENT) OR GETDISTANCE(-2, $AGENT) > $SEARCHDISTANCE THEN CONTINUELOOP
		IF DLLSTRUCTGETDATA($AGENT, "Allegiance") <> 3 THEN CONTINUELOOP
		Local $MODELID = DLLSTRUCTGETDATA($AGENT, "AgentModelType")
		SWITCH $MODELID
			CASE 5215
				Info("Targeting Dryder")
				RETURN $AGENT
		ENDSWITCH
	NEXT
	FOR $I = 0 TO GetMaxAgents()
		$AGENT = GetAgentByID($I)
		IF GETISDEAD($AGENT) OR GETISDEAD($AGENT) OR GETDISTANCE(-2, $AGENT) > $SEARCHDISTANCE THEN CONTINUELOOP
		IF DLLSTRUCTGETDATA($AGENT, "Allegiance") <> 3 THEN CONTINUELOOP
		Local $MODELID = DLLSTRUCTGETDATA($AGENT, "AgentModelType")
		SWITCH $MODELID
			CASE 5169
				Info("Targeting Anur Ki")
				RETURN $AGENT
		ENDSWITCH
	NEXT
	RETURN 0
ENDFUNC

FUNC GemKillBOW()
	Info("GemKilling bow")
	IF GETISDEAD(-2) THEN RETURN
	CANCELALL()
	$TARGET = GETNEARESTENEMYTOAGENT(-2)
	CALLTARGET($TARGET)
	WHILE NOT GETISDEAD(-1) AND NOT GETISDEAD(-1)
		ATTACK($TARGET)
		SLEEP(200)
	WEND
	MOVETO($g_startX, $g_startY)
	COMMANDALL(-3449, -5229)
ENDFUNC

FUNC PICKUPLOOTANDMOVEBACK()
	IF GETISDEAD(-2) THEN RETURN
	PickUpItems() 
	MOVETO($g_startX, $g_startY)
ENDFUNC

Func GETENERGYCOST($skillID)
    Local $skill = GetSkillByID($skillID)
    Return DllStructGetData($skill, "EnergyCost")
EndFunc

Func GETACTIVATIONTIME($skillID)
    Local $skill = GetSkillByID($skillID)
    Return DllStructGetData($skill, "Activation") * 1000
EndFunc

FUNC GemKillTHEBOWGUY()
	Info("Enemy Info of range, hunting!")
	CANCELALL()
	$AGENT = GETNEARESTENEMYTOAGENT(GetMyAgent())
	CHANGETARGET($AGENT)
	CALLTARGET($AGENT)
	DO
		Info("attackin the bow")
		ATTACK($AGENT)
	UNTIL GETISDEAD($AGENT) OR GETISDEAD(GetMyAgent()) OR DLLSTRUCTGETDATA($AGENT, "ID") = 0
	COMMANDALL(-3449, -5229)
	MOVETO($g_startX, $g_startY)
ENDFUNC

Func ZHELLIXWAITING()
    If GETMAPLOADING() == 2 Then DISCONNECTED()
    Local $ZHELLIX = GETZHELLIX()
    If GETDISTANCE(GetMyAgent(), $ZHELLIX) < 1500 Or CountFoesInRangeOfAgent(GetMyAgent(), 1300) > 0 Then
        Return True
    Else
        Return False
    EndIf
EndFunc

FUNC GETZHELLIX()
	FOR $I = 0 TO GETMAXAGENTS()
		Local $AGENT = GetAgentByID($I)
		IF DLLSTRUCTGETDATA($AGENT, "PlayerNumber") = 5221 THEN
			RETURN $AGENT
		ENDIF
	NEXT
ENDFUNC