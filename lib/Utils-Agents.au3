#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributors: Gahais, JackLinesMatthews
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

#include 'GWA2.au3'
#include 'Utils.au3'

Opt('MustDeclareVars', True)


#Region Agents distances
;~ Returns the distance between two agents.
Func GetDistance($agent1, $agent2)
	Return Sqrt((DllStructGetData($agent1, 'X') - DllStructGetData($agent2, 'X')) ^ 2 + (DllStructGetData($agent1, 'Y') - DllStructGetData($agent2, 'Y')) ^ 2)
EndFunc


;~ Returns the distance between agent and point specified by a coordinate pair.
Func GetDistanceToPoint($agent, $X, $Y)
	Return Sqrt(($X - DllStructGetData($agent, 'X')) ^ 2 + ($Y - DllStructGetData($agent, 'Y')) ^ 2)
EndFunc


;~ Returns the square of the distance between two agents.
Func GetPseudoDistance($agent1, $agent2)
	Return (DllStructGetData($agent1, 'X') - DllStructGetData($agent2, 'X')) ^ 2 + (DllStructGetData($agent1, 'Y') - DllStructGetData($agent2, 'Y')) ^ 2
EndFunc
#Region Agents distances


#Region Party
Global $party_failures_count = 0
Global $party_is_alive = True

;~ Count number of alive heroes of the player's party
Func CountAliveHeroes()
	Local $aliveHeroes = 0
	For $i = 1 to 7
		Local $heroID = GetHeroID($i)
		If GetAgentExists($heroID) And Not GetIsDead(GetAgentById($heroID)) Then $aliveHeroes += 1
	Next
	Return $aliveHeroes
EndFunc


;~ Count number of alive members of the player's party including 7 heroes and player
Func CountAlivePartyMembers()
	Local $alivePartyMembers = CountAliveHeroes()
	If Not IsPlayerDead Then $alivePartyMembers += 1
	Return $alivePartyMembers
EndFunc


Func IsPlayerAlive()
	Return BitAND(DllStructGetData(GetMyAgent(), 'Effects'), 0x0010) == 0
EndFunc


Func IsPlayerDead()
	Return BitAND(DllStructGetData(GetMyAgent(), 'Effects'), 0x0010) > 0
EndFunc


Func IsHeroAlive($heroIndex)
	Return BitAND(DllStructGetData(GetAgentById(GetHeroID($heroIndex)), 'Effects'), 0x0010) == 0
EndFunc


Func IsHeroDead($heroIndex)
	Return BitAND(DllStructGetData(GetAgentById(GetHeroID($heroIndex)), 'Effects'), 0x0010) > 0
EndFunc


Func IsPlayerAndPartyWiped()
	Return IsPlayerDead() And Not HasRezMemberAlive()
EndFunc


Func IsPlayerOrPartyAlive()
	Return IsPlayerAlive() Or HasRezMemberAlive()
EndFunc


;~ Did run fail ?
Func IsRunFailed()
	Local Static $MaxPartyWipesCount = 5
	If ($party_failures_count > $MaxPartyWipesCount) Then
		Notice('Party wiped ' & $party_failures_count & ' times, run is considered failed.')
		Return True
	EndIf
	Return False
EndFunc


;~ Is party alive right now
Func IsPartyCurrentlyAlive()
	Return $party_is_alive
EndFunc


;~ Reset the failures counter
Func ResetFailuresCounter()
	$party_failures_count = 0
	$party_is_alive = True
EndFunc


;~ Updates the party_is_alive variable, this function is run on a fixed timer (10s)
Func TrackPartyStatus()
	; If GetAgentExists(GetMyID()) is False, player is disconnected or between instances, do not track party status
	If GetAgentExists(GetMyID()) And IsPlayerAndPartyWiped() Then
		$party_failures_count += 1
		Notice('Party wiped for the ' & $party_failures_count & ' time')
		$party_is_alive = False
	Else
		$party_is_alive = True
	EndIf
EndFunc


;~ Returns True if the party is alive, that is if there is still an alive hero with resurrection skill
Func HasRezMemberAlive()
	Local Static $heroesWithRez
	If Not IsArray($heroesWithRez) Then $heroesWithRez = FindHeroesWithRez()
	For $i In $heroesWithRez
		Local $heroID = GetHeroID($i)
		If GetAgentExists($heroID) And Not GetIsDead(GetAgentById($heroID)) Then Return True
	Next
	Return False
EndFunc


;~ Return an array of heroes in the party with a resurrection skill, indexed from 0
Func FindHeroesWithRez()
	Local $heroes[7]
	Local $count = 0
	For $heroNumber = 1 To GetHeroCount()
		For $skillSlot = 1 To 8
			Local $skill = GetSkillbarSkillID($skillSlot, $heroNumber)
			If IsRezSkill($skill) Then
				$heroes[$count] = $heroNumber
				$count += 1
			EndIf
		Next
	Next
	Local $heroesWithRez[$count]
	For $i = 0 To $count - 1
		$heroesWithRez[$i] = $heroes[$i]
	Next
	Return $heroesWithRez
EndFunc


;~ Return true if the provided skill is a rez skill - signets excluded
Func IsRezSkill($skill)
	Switch $skill
		Case $ID_BY_URALS_HAMMER, $ID_JUNUNDU_WAIL, _ ;$ID_RESURRECTION_SIGNET, $ID_SUNSPEAR_REBIRTH_SIGNET _
			$ID_ETERNAL_AURA, _
			$ID_WE_SHALL_RETURN, $ID_SIGNET_OF_RETURN, _
			$ID_DEATH_PACT_SIGNET, $ID_FLESH_OF_MY_FLESH, $ID_LIVELY_WAS_NAOMEI, $ID_RESTORATION, _
			$ID_LIGHT_OF_DWAYNA, $ID_REBIRTH, $ID_RENEW_LIFE, $ID_RESTORE_LIFE, $ID_RESURRECT, $ID_RESURRECTION_CHANT, $ID_UNYIELDING_AURA, $ID_VENGEANCE
			Return True
	EndSwitch
	Return False
EndFunc


;~ Returns array of party members
;~ Param: an array returned by GetAgentArray. This is totally optional, but can greatly improve script speed.
;~ Caution in outposts all players are matched as team members even when they are not in team
Func GetParty($agents = Null)
	If $agents == Null Then $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	; array of full party 8 members, indexed from 0
	Local $fullParty[8]
	Local $partySize = 0
	For $agent In $agents
		If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_TEAM Then ContinueLoop
		If Not BitAND(DllStructGetData($agent, 'TypeMap'), $ID_TYPEMAP_IDLE_ALLY) Then ContinueLoop
		$fullParty[$partySize] = $agent
		$partySize += 1
		; safeguard to not exceed party size, especially in towns with many players
		If $partySize == 8 Then ExitLoop
	Next
	; array of party members in case party is smaller than 8 members
	Local $party[$partySize]
	For $i = 0 To $partySize - 1
		$party[$i] = $fullParty[$i]
	Next
	Return $party
EndFunc


;~ Returns true if any party member is dead
Func CheckIfAnyPartyMembersDead()
	Local $party = GetParty()
	For $member In $party
		If GetIsDead($member) Then
			Return True
		EndIf
	Next
	Return False
EndFunc


;~ Return the number of enemy agents targeting the given party member.
Func GetPartyMemberDanger($agent, $agents = Null)
	If $agents == Null Then $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	$party = GetParty($agents)
	$partyMemberDangers = GetPartyDanger($agents)

	For $member In $party
		;If $member == $agent Then Return $partyMemberDangers[$i]
		If DllStructGetData($member, 'ID') == DllStructGetData($agent, 'ID') Then Return partyMemberDangers[$i]
	Next
	Return Null
EndFunc


;~ Returns the 'danger level' of each party member
;~ Param1: an array returned by GetAgentArray(). This is totally optional, but can greatly improve script speed.
;~ Param2: an array returned by GetParty() This is totally optional, but can greatly improve script speed.
Func GetPartyDanger($agents = Null, $party = Null)
	If $agents == Null Then $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	If $party == Null Then $party = GetParty($agents)

	Local $resultLevels[UBound($party)]
	FillArray($resultLevels, 0)

	For $i = 0 To UBound($agents) - 1
		Local $agent = $agents[$i]
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		Local $allegiance = DllStructGetData($agent, 'Allegiance')
		; ignore spirits (4), pets (4), minions (5), NPCs (6), which have allegiance number higher than foe (3)
		If $allegiance > $ID_ALLEGIANCE_FOE Then ContinueLoop

		Local $targetID = DllStructGetData(GetTarget($agent), 'ID')
		Local $team = DllStructGetData($agent, 'Team')
		For $member In $party
			If $targetID == DllStructGetData($member, 'ID') Then
				; can't target beyond compass range
				If GetDistance($agent, $member) < $RANGE_COMPASS Then
					If $team <> 0 Then
						; agent from different team targeting party member
						If $team <> DllStructGetData($member, 'Team') Then
							$resultLevels[$i] += 1
						EndIf
					; agent from different allegiance targeting party member
					ElseIf $allegiance <> DllStructGetData($member, 'Allegiance') Then
						$resultLevels[$i] += 1
					EndIf
				EndIf
			EndIf
		Next
	Next
	Return $resultLevels
EndFunc


;~ Return True if malus is -60 on player
Func IsPlayerAtMaxMalus()
	If GetMorale() == -60 Then Return True
	Return False
EndFunc


;~ Team member has too much malus
Func TeamHasTooMuchMalus()
	Local $party = GetParty()
	For $i = 0 To UBound($party)
		If GetMorale($i) < 0 Then Return True
	Next
	Return False
EndFunc
#EndRegion Party


#Region NPCs
;~ Print NPC informations
Func PrintNPCInformations($npc)
	Info('ID: ' & DllStructGetData($npc, 'ID'))
	Info('X: ' & DllStructGetData($npc, 'X'))
	Info('Y: ' & DllStructGetData($npc, 'Y'))
	Info('HealthPercent: ' & DllStructGetData($npc, 'HealthPercent'))
	Info('TypeMap: ' & DllStructGetData($npc, 'TypeMap'))
	Info('ModelID: ' & DllStructGetData($npc, 'ModelID'))
	Info('Allegiance: ' & DllStructGetData($npc, 'Allegiance'))
	Info('Effects: ' & DllStructGetData($npc, 'Effects'))
	Info('ModelState: ' & DllStructGetData($npc, 'ModelState'))
	Info('NameProperties: ' & DllStructGetData($npc, 'NameProperties'))
	Info('Type: ' & DllStructGetData($npc, 'Type'))
	Info('ExtraType: ' & DllStructGetData($npc, 'ExtraType'))
	Info('GadgetID: ' & DllStructGetData($npc, 'GadgetID'))
EndFunc


#Region Counting NPCs
;~ Count foes in range of the given agent
Func CountFoesInRangeOfAgent($agent, $range = $RANGE_AREA, $condition = Null)
	Return CountNPCsInRangeOfAgent($agent, $ID_ALLEGIANCE_FOE, $range, $condition)
EndFunc


;~ Count foes in range of the given coordinates
Func CountFoesInRangeOfCoords($xCoord = Null, $yCoord = Null, $range = $RANGE_AREA, $condition = Null)
	Return CountNPCsInRangeOfCoords($xCoord, $yCoord, $ID_ALLEGIANCE_FOE, $range, $condition)
EndFunc


;~ Count allies in range of the given coordinates
Func CountAlliesInRangeOfCoords($xCoord = Null, $yCoord = Null, $range = $RANGE_AREA, $condition = Null)
	Return CountNPCsInRangeOfCoords($xCoord, $yCoord, $ID_ALLEGIANCE_NPC, $range, $condition)
EndFunc


;~ Count NPCs in range of the given agent
Func CountNPCsInRangeOfAgent($agent, $npcAllegiance = Null, $range = $RANGE_AREA, $condition = Null)
	Return CountNPCsInRangeOfCoords(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), $npcAllegiance, $range, $condition)
EndFunc


;~ Count NPCs in range of the given coordinates. If range is Null then all found NPCs are counted, as with infinite range
Func CountNPCsInRangeOfCoords($coordX = Null, $coordY = Null, $npcAllegiance = Null, $range = $RANGE_AREA, $condition = Null)
	;Return UBound(GetNPCsInRangeOfCoords($coordX, $coordY, $npcAllegiance, $range, $condition))
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $count = 0

	If $coordX == Null Or $coordY == Null Then
		Local $me = GetMyAgent()
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $agent In $agents
		If $npcAllegiance <> Null And DllStructGetData($agent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null Then ContinueLoop
		If $condition <> Null And $condition($agent) == False Then ContinueLoop
		If $range < GetDistanceToPoint($agent, $coordX, $coordY) Then ContinueLoop
		$count += 1
	Next
	Return $count
EndFunc
#EndRegion Counting NPCs


#Region Getting NPCs
;~ Move to the middle of the party team within specified limited timeout
Func MoveToMiddleOfPartyWithTimeout($timeOut)
	Local $me = GetMyAgent()
	Local $oldMapID, $mapID = GetMapID()
	Local $timer = TimerInit()
	Local $position = FindMiddleOfParty()
	Move($position[0], $position[1], 0)
	While GetDistanceToPoint($me, $position[0], $position[1]) > $RANGE_ADJACENT And TimerDiff($timer) > $timeOut
		If IsPlayerDead() Then ExitLoop
		$oldMapID = $mapID
		$mapID = GetMapID()
		If $mapID <> $oldMapID Then ExitLoop
		$position = FindMiddleOfParty()
		RandomSleep(200)
		$me = GetMyAgent()
	WEnd
EndFunc


;~ Returns the coordinates in the middle of the party team in 2 elements array
Func FindMiddleOfParty()
	Local $position[2] = [0, 0]
	Local $party = GetParty()
	Local $partySize = 0
	Local $me = GetMyAgent()
	Local $ownID = DllStructGetData($me, 'ID')
	For $member In $party
		If GetDistance($me, $member) < $RANGE_SPIRIT And DllStructGetData($member, 'ID') <> $ownID Then
			$position[0] += DllStructGetData($member, 'X')
			$position[1] += DllStructGetData($member, 'Y')
			$partySize += 1
		EndIf
	Next
	$position[0] = $position[0] / $partySize
	$position[1] = $position[1] / $partySize
	Return $position
EndFunc


;~ Returns the coordinates in the middle of a group of foes nearest to provided position
Func FindMiddleOfFoes($posX, $posY, $range = $RANGE_AREA)
	Local $position[2] = [0, 0]
	Local $nearestFoe = GetNearestEnemyToCoords($posX, $posY)
	Local $foes = GetFoesInRangeOfAgent($nearestFoe, $range)
	For $foe In $foes
		$position[0] += DllStructGetData($foe, 'X')
		$position[1] += DllStructGetData($foe, 'Y')
	Next
	$position[0] = $position[0] / Ubound($foes)
	$position[1] = $position[1] / Ubound($foes)
	Return $position
EndFunc


;~ Get foes in range of the given agent
Func GetFoesInRangeOfAgent($agent, $range = $RANGE_AREA, $condition = Null)
	Return GetNPCsInRangeOfAgent($agent, $ID_ALLEGIANCE_FOE, $range, $condition)
EndFunc


;~ Get foes in range of the given coordinates
Func GetFoesInRangeOfCoords($xCoord = Null, $yCoord = Null, $range = $RANGE_AREA, $condition = Null)
	Return GetNPCsInRangeOfCoords($xCoord, $yCoord, $ID_ALLEGIANCE_FOE, $range, $condition)
EndFunc


;~ Get NPCs in range of the given agent
Func GetNPCsInRangeOfAgent($agent, $npcAllegiance = Null, $range = $RANGE_AREA, $condition = Null)
	Return GetNPCsInRangeOfCoords(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), $npcAllegiance, $range, $condition)
EndFunc


;~ Get party members in range of the given agent
Func GetPartyInRangeOfAgent($agent, $range = $RANGE_AREA)
	Return GetNPCsInRangeOfCoords(DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'), $ID_ALLEGIANCE_TEAM, $range, PartyMemberFilter)
EndFunc


;~ Small helper to filter party members
Func PartyMemberFilter($agent)
	Return BitAND(DllStructGetData($agent, 'TypeMap'), $ID_TYPEMAP_IDLE_ALLY)
EndFunc


;~ Get NPCs in range of the given coordinates. If range is Null then all found NPCs are retuned, as with infinite range
Func GetNPCsInRangeOfCoords($coordX = Null, $coordY = Null, $npcAllegiance = Null, $range = $RANGE_AREA, $condition = Null)
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $allAgents[UBound($agents)]
	Local $npcCount = 0

	If $coordX == Null Or $coordY == Null Then
		Local $me = GetMyAgent()
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $agent In $agents
		If $npcAllegiance <> Null And DllStructGetData($agent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null Then ContinueLoop
		If $condition <> Null And $condition($agent) == False Then ContinueLoop
		If $range < GetDistanceToPoint($agent, $coordX, $coordY) Then ContinueLoop
		$allAgents[$npcCount] = $agent
		$npcCount += 1
	Next
	Local $npcAgents[$npcCount]
	For $i = 0 To $npcCount - 1
		$npcAgents[$i] = $allAgents[$i]
	Next
	Return $npcAgents
EndFunc


;~ Get NPC closest to the player and within specified range of the given coordinates. If range is Null then all found NPCs are checked, as with infinite range
Func GetNearestNPCInRangeOfCoords($coordX = Null, $coordY = Null, $npcAllegiance = Null, $range = $RANGE_AREA, $condition = Null)
	Local $me = GetMyAgent()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $smallestDistance = 99999
	Local $nearestAgent = Null

	If $coordX == Null Or $coordY == Null Then
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $agent In $agents
		If $npcAllegiance <> Null And DllStructGetData($agent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null Then ContinueLoop
		If $condition <> Null And $condition($agent) == False Then ContinueLoop
		If $range < GetDistanceToPoint($agent, $coordX, $coordY) Then ContinueLoop
		Local $curDistance = GetDistance($me, $agent)
		If $curDistance < $smallestDistance Then
			$nearestAgent = $agent
			$smallestDistance = $curDistance
		EndIf
	Next
	Return $nearestAgent
EndFunc


;~ Get NPC furthest to the player and within specified range of the given coordinates. If range is Null then all found NPCs are checked, as with infinite range
Func GetFurthestNPCInRangeOfCoords($npcAllegiance = Null, $coordX = Null, $coordY = Null, $range = $RANGE_AREA, $condition = Null)
	Local $me = GetMyAgent()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $furthestDistance = 0
	Local $furthestAgent = Null

	If $coordX == Null Or $coordY == Null Then
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $agent In $agents
		If $npcAllegiance <> Null And DllStructGetData($agent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null Then ContinueLoop
		If $condition <> Null And $condition($agent) == False Then ContinueLoop
		If $range < GetDistanceToPoint($agent, $coordX, $coordY) Then ContinueLoop
		Local $curDistance = GetDistance($me, $agent)
		If $curDistance > $furthestDistance Then
			$furthestAgent = $agent
			$furthestDistance = $curDistance
		EndIf
	Next
	Return $furthestAgent
EndFunc


;~ TODO: check that this method is still better, I improved the original
;~ Get NPC closest to the given coordinates and within specified range of the given coordinates. If range is Null then all found NPCs are checked, as with infinite range
Func BetterGetNearestNPCToCoords($npcAllegiance = Null, $coordX = Null, $coordY = Null, $range = $RANGE_AREA, $condition = Null)
	Local $me = GetMyAgent()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $smallestDistance = 99999
	Local $nearestAgent = Null

	If $coordX == Null Or $coordY == Null Then
		$coordX = DllStructGetData($me, 'X')
		$coordY = DllStructGetData($me, 'Y')
	EndIf
	For $agent In $agents
		If $npcAllegiance <> Null And DllStructGetData($agent, 'Allegiance') <> $npcAllegiance Then ContinueLoop
		If DllStructGetData($agent, 'HealthPercent') <= 0 Then ContinueLoop
		If GetIsDead($agent) Then ContinueLoop
		If $MAP_SPIRIT_TYPES[DllStructGetData($agent, 'TypeMap')] <> Null Then ContinueLoop
		If $condition <> Null And $condition($agent) == False Then ContinueLoop
		Local $curDistance = GetDistanceToPoint($agent, $coordX, $coordY)
		If $range < $curDistance Then ContinueLoop
		If $curDistance < $smallestDistance Then
			$nearestAgent = $agent
			$smallestDistance = $curDistance
		EndIf
	Next
	Return $nearestAgent
EndFunc


;~ Returns the highest priority foe around a target agent
Func GetHighestPriorityFoe($targetAgent, $range = $RANGE_SPELLCAST)
	Local Static $mobsPriorityMap = CreateMobsPriorityMap()
	Local $agents = GetFoesInRangeOfAgent(GetMyAgent(), $range)
	Local $highestPriorityTarget = Null
	Local $priorityLevel = 99999
	Local $agentID = DllStructGetData($targetAgent, 'ID')

	For $agent In $agents
		If Not EnemyAgentFilter($agent) Then ContinueLoop
		; This gets all mobs in fight, but also mobs that just used a skill, it's not completely perfect
		; TypeMap == 0 is only when foe is idle, not casting and not fighting, also prioritized for surprise attack
		; If DllStructGetData($agent, 'TypeMap') == 0 Then ContinueLoop
		If DllStructGetData($agent, 'ID') == $agentID Then ContinueLoop
		Local $distance = GetDistance($targetAgent, $agent)
		If $distance < $range Then
			Local $priority = $mobsPriorityMap[DllStructGetData($agent, 'ModelID')]
			; map returns Null for all other mobs that don't exist in map
			If ($priority == Null) Then
				If $highestPriorityTarget == Null Then $highestPriorityTarget = $agent
				ContinueLoop
			EndIf
			If ($priority == 0) Then Return $agent
			If ($priority < $priorityLevel) Then
				$highestPriorityTarget = $agent
				$priorityLevel = $priority
			EndIf
		EndIf
	Next
	Return $highestPriorityTarget
EndFunc
#EndRegion Getting NPCs
#EndRegion NPCs


#Region Agents
;~ Is agent in range of coordinates
Func IsAgentInRange($agent, $X, $Y, $range)
	If GetDistanceToPoint($agent, $X, $Y) < $range Then Return True
	Return False
EndFunc


;~ Returns the nearest signpost to an agent. Caution, chest can also be matched as static object agent
Func GetNearestSignpostToAgent($agent)
	Return GetNearestAgentToAgent($agent, $ID_AGENT_TYPE_STATIC)
EndFunc


;~ Returns the nearest NPC to an agent.
Func GetNearestNPCToAgent($agent)
	Return GetNearestAgentToAgent($agent, $ID_AGENT_TYPE_NPC, NPCAgentFilter)
EndFunc


;~ Return True if an agent is an NPC, False otherwise
Func NPCAgentFilter($agent)
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_NPC Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	If GetIsDead($agent) Then Return False
	Return True
EndFunc


;~ Returns the nearest enemy to an agent.
Func GetNearestEnemyToAgent($agent)
	Return GetNearestAgentToAgent($agent, $ID_AGENT_TYPE_NPC, EnemyAgentFilter)
EndFunc


;~ Return True if an agent is an enemy, False otherwise
Func EnemyAgentFilter($agent)
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then Return False
	Return True
EndFunc


;~ Returns the nearest agent to specified target agent. $agentFilter is a function which returns True for the agents that should be considered, False for those to skip
Func GetNearestAgentToAgent($targetAgent, $agentType = 0, $agentFilter = Null)
	Local $nearestAgent = Null, $distance = Null, $nearestDistance = 100000000
	Local $agents = GetAgentArray($agentType)
	Local $targetAgentID = DllStructGetData($targetAgent, 'ID')
	Local $ownID = DllStructGetData(GetMyAgent(), 'ID')

	For $agent In $agents
		If DllStructGetData($agent, 'ID') == $targetAgentID Then ContinueLoop
		If DllStructGetData($agent, 'ID') == $ownID Then ContinueLoop
		If $agentFilter <> Null And Not $agentFilter($agent) Then ContinueLoop
		$distance = GetDistance($targetAgent, $agent)
		If $distance < $nearestDistance Then
			$nearestAgent = $agent
			$nearestDistance = $distance
		EndIf
	Next

	SetExtended(Sqrt($nearestDistance))
	Return $nearestAgent
EndFunc


;~ Returns the nearest item to an agent.
Func GetNearestItemToAgent($agent, $canPickUp = True)
	If $canPickUp Then
		Return GetNearestAgentToAgent($agent, $ID_AGENT_TYPE_ITEM, GetCanPickUp)
	Else
		Return GetNearestAgentToAgent($agent, $ID_AGENT_TYPE_ITEM)
	EndIf
EndFunc


;~ Returns the nearest signpost to a set of coordinates. Caution, chest can also be matched as static object agent
Func GetNearestSignpostToCoords($X, $Y)
	Return GetNearestAgentToCoords($X, $Y, $ID_AGENT_TYPE_STATIC)
EndFunc


;~ Returns the nearest NPC to a set of coordinates.
Func GetNearestNPCToCoords($X, $Y)
	Return GetNearestAgentToCoords($X, $Y, $ID_AGENT_TYPE_NPC, NPCAgentFilter)
EndFunc


;~ Returns the nearest enemy to coordinates
Func GetNearestEnemyToCoords($X, $Y)
	Return GetNearestAgentToCoords($X, $Y, $ID_AGENT_TYPE_NPC, EnemyAgentFilter)
EndFunc


;~ Returns the nearest agent to a set of coordinates.
Func GetNearestAgentToCoords($X, $Y, $agentType = 0, $agentFilter = Null)
	Local $nearestAgent, $nearestDistance = 100000000
	Local $distance
	Local $agents = GetAgentArray($agentType)
	Local $ownID = DllStructGetData(GetMyAgent(), 'ID')

	For $agent In $agents
		If DllStructGetData($agent, 'ID') == $ownID Then ContinueLoop
		If $agentFilter <> Null And Not $agentFilter($agent) Then ContinueLoop
		$distance = GetDistanceToPoint($agent, $X, $Y)
		If $distance < $nearestDistance Then
			$nearestAgent = $agent
			$nearestDistance = $distance
		EndIf
	Next

	SetExtended(Sqrt($nearestDistance))
	Return $nearestAgent
EndFunc


;~ Returns agent corresponding to the given unique Model ID that specify every object in game, e.g. NPC (can be accessed with GWToolbox).
;~ There can be multiple same agents, e.g. NPCs in map that have same ModelID but different agent IDs. Each agent in map is assigned unique temporary agentID
Func GetAgentByModelID($modelID)
	Local $agents = GetAgentArray()
	For $agent In $agents
		If DllStructGetData($agent, 'ModelID') == $modelID Then Return $agent
	Next
	Return Null
EndFunc
#Region Agents


#Region AgentInfo
;~ Tests if an agent is alive NPC, like player, party members, allies, foes.
Func IsNPCAgentType($agent)
	Return DllStructGetData($agent, 'Type') = $ID_AGENT_TYPE_NPC
EndFunc


;~ Tests if an agent is a signpost/chest/etc.
Func IsStaticAgentType($agent)
	Return DllStructGetData($agent, 'Type') = $ID_AGENT_TYPE_STATIC
EndFunc


;~ Tests if an agent is an item.
Func IsItemAgentType($agent)
	Return DllStructGetData($agent, 'Type') = $ID_AGENT_TYPE_ITEM
EndFunc


;~ Returns energy of an agent. (Only self/heroes)
;~ If no agent is provided then returning current energy of player
;~ Provided agent parameter should be a struct, not numerical agent ID
Func GetEnergy($agent = Null)
	If $agent == Null Then $agent = GetMyAgent()
	Return DllStructGetData($agent, 'EnergyPercent') * DllStructGetData($agent, 'MaxEnergy')
EndFunc


;~ Returns health of an agent. (Must have caused numerical change in health)
;~ If no agent is provided then returning current health of player
;~ Provided agent parameter should be a struct, not numerical agent ID
Func GetHealth($agent = Null)
	If $agent == Null Then $agent = GetMyAgent()
	Return DllStructGetData($agent, 'HealthPercent') * DllStructGetData($agent, 'MaxHealth')
EndFunc


;~ Tests if an agent is moving.
Func GetIsMoving($agent)
	Return DllStructGetData($agent, 'MoveX') <> 0 Or DllStructGetData($agent, 'MoveY') <> 0
EndFunc


;~ Tests if player is moving.
Func IsPlayerMoving()
	Local $me = GetMyAgent()
	Return DllStructGetData($me, 'MoveX') <> 0 Or DllStructGetData($me, 'MoveY') <> 0
EndFunc


;~ Tests if an agent is knocked down.
Func GetIsKnocked($agent)
	Return DllStructGetData($agent, 'ModelState') = 0x450
EndFunc


;~ Tests if an agent is attacking.
Func GetIsAttacking($agent)
	Switch DllStructGetData($agent, 'ModelState')
		Case 0x60, 0x440, 0x460
			Return True
	EndSwitch
	Return False
EndFunc


;~ Tests if an agent is casting.
Func GetIsCasting($agent)
	Return DllStructGetData($agent, 'Skill') <> 0
EndFunc


;~ Tests if an agent is bleeding.
Func GetIsBleeding($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0001) > 0
EndFunc


;~ Tests if an agent has a condition.
Func GetHasCondition($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0002) > 0
EndFunc


;~ Tests if an agent is dead.
Func GetIsDead($agent)
	; nonexisting agents are considered dead (not alive), and recently deceased agents become Null too, therefore returning True
	If $agent == Null Then Return True
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0010) > 0
EndFunc

;~ Tests if an agent has a deep wound.
Func GetHasDeepWound($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0020) > 0
EndFunc


;~ Tests if an agent is poisoned.
Func GetIsPoisoned($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0040) > 0
EndFunc


;~ Tests if an agent is enchanted.
Func GetIsEnchanted($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0080) > 0
EndFunc


;~ Tests if an agent has a degen hex.
Func GetHasDegenHex($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0400) > 0
EndFunc


;~ Tests if an agent is hexed.
Func GetHasHex($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x0800) > 0
EndFunc


;~ Tests if an agent has a weapon spell.
Func GetHasWeaponSpell($agent)
	Return BitAND(DllStructGetData($agent, 'Effects'), 0x8000) > 0
EndFunc


;~ Tests if an agent is a boss.
Func GetIsBoss($agent)
	Return BitAND(DllStructGetData($agent, 'TypeMap'), 0x400) > 0
EndFunc
#EndRegion AgentInfo



; FIXME: change format of this function to build it with MapFromArrays or MapFromDoubleArray
;~ Create a map containing foes and their priority level
Func CreateMobsPriorityMap()
	; Voltaic farm foes model IDs
	Local $PN_SS_Dominator		= 6544
	Local $PN_SS_Dreamer		= 6545
	Local $PN_SS_Contaminator	= 6546
	Local $PN_SS_Blasphemer		= 6547
	Local $PN_SS_Warder			= 6548
	Local $PN_SS_Priest			= 6549
	Local $PN_SS_Defender		= 6550
	Local $PN_SS_Zealot			= 6557
	Local $PN_SS_Summoner		= 6558
	Local $PN_Modniir_Priest	= 6563

	; Gemstone farm foes model IDs
	Local $Gem_AnurKaya			= 5217
	;Local $Gem_AnurDabi		= 5218
	Local $Gem_AnurSu			= 5219
	Local $Gem_AnurKi			= 5220
	;Local $Gem_AnurTuk			= 5222
	;Local $Gem_AnurRund		= 5224
	;Local $Gem_MiseryTitan		= 5246
	Local $Gem_RageTitan		= 5247
	;Local $Gem_DementiaTitan	= 5248
	;Local $Gem_AnguishTitan	= 5249
	Local $Gem_FuryTitan		= 5251
	;Local $Gem_MindTormentor	= 5255
	;Local $Gem_SoulTormentor	= 5256
	Local $Gem_WaterTormentor	= 5257
	Local $Gem_HeartTormentor	= 5258
	;Local $Gem_FleshTormentor	= 5259
	Local $Gem_TortureWebDryder	= 5266
	Local $Gem_GreatDreamRider	= 5267

	; War Supply farm foes model IDs, why so many? (o_O)
	;Local $WarSupply_Peacekeeper_1	= 8146
	;Local $WarSupply_Peacekeeper_2	= 8147
	;Local $WarSupply_Peacekeeper_3	= 8148
	;Local $WarSupply_Peacekeeper_4	= 8170
	;Local $WarSupply_Peacekeeper_5	= 8171
	;Local $WarSupply_Marksman_1	= 8187
	;Local $WarSupply_Marksman_2	= 8188
	;Local $WarSupply_Marksman_3	= 8189
	;Local $WarSupply_Enforcer_1	= 8232
	;Local $WarSupply_Enforcer_2	= 8233
	;Local $WarSupply_Enforcer_3	= 8234
	;Local $WarSupply_Enforcer_4	= 8235
	;Local $WarSupply_Enforcer_5	= 8236
	Local $WarSupply_Sycophant_1	= 8237
	Local $WarSupply_Sycophant_2	= 8238
	Local $WarSupply_Sycophant_3	= 8239
	Local $WarSupply_Sycophant_4	= 8240
	Local $WarSupply_Sycophant_5	= 8241
	Local $WarSupply_Sycophant_6	= 8242
	Local $WarSupply_Ritualist_1	= 8243
	Local $WarSupply_Ritualist_2	= 8244
	Local $WarSupply_Ritualist_3	= 8245
	Local $WarSupply_Ritualist_4	= 8246
	Local $WarSupply_Fanatic_1		= 8247
	Local $WarSupply_Fanatic_2		= 8248
	Local $WarSupply_Fanatic_3		= 8249
	Local $WarSupply_Fanatic_4		= 8250
	Local $WarSupply_Savant_1		= 8251
	Local $WarSupply_Savant_2		= 8252
	Local $WarSupply_Savant_3		= 8253
	Local $WarSupply_Adherent_1		= 8254
	Local $WarSupply_Adherent_2		= 8255
	Local $WarSupply_Adherent_3		= 8256
	Local $WarSupply_Adherent_4		= 8257
	Local $WarSupply_Adherent_5		= 8258
	Local $WarSupply_Priest_1		= 8259
	Local $WarSupply_Priest_2		= 8260
	Local $WarSupply_Priest_3		= 8261
	Local $WarSupply_Priest_4		= 8262
	Local $WarSupply_Abbot_1		= 8263
	Local $WarSupply_Abbot_2		= 8264
	Local $WarSupply_Abbot_3		= 8265
	;Local $WarSupply_Zealot_1		= 8267
	;Local $WarSupply_Zealot_2		= 8268
	;Local $WarSupply_Zealot_3		= 8269
	;Local $WarSupply_Zealot_4		= 8270
	;Local $WarSupply_Knight_1		= 8273
	;Local $WarSupply_Knight_2		= 8274
	;Local $WarSupply_Scout_1		= 8275
	;Local $WarSupply_Scout_2		= 8276
	;Local $WarSupply_Scout_3		= 8277
	;Local $WarSupply_Scout_4		= 8278
	;Local $WarSupply_Seeker_1		= 8279
	;Local $WarSupply_Seeker_2		= 8280
	;Local $WarSupply_Seeker_3		= 8281
	;Local $WarSupply_Seeker_4		= 8282
	;Local $WarSupply_Seeker_5		= 8283
	;Local $WarSupply_Seeker_6		= 8284
	;Local $WarSupply_Seeker_7		= 8285
	;Local $WarSupply_Seeker_8		= 8286
	Local $WarSupply_Ritualist_5	= 8287
	Local $WarSupply_Ritualist_6	= 8288
	Local $WarSupply_Ritualist_7	= 8289
	Local $WarSupply_Ritualist_8	= 8290
	Local $WarSupply_Ritualist_9	= 8291
	Local $WarSupply_Ritualist_10	= 8292
	Local $WarSupply_Ritualist_11	= 8293
	;Local $WarSupply_Champion_1	= 8295
	;Local $WarSupply_Champion_2	= 8296
	;Local $WarSupply_Champion_3	= 8297
	;Local $WarSupply_Zealot_5		= 8392

	; Priority map : 0 highest kill priority, bigger numbers mean lesser priority
	Local $map[]
	$map[$PN_SS_Defender]		= 0
	$map[$PN_SS_Priest]			= 0
	$map[$PN_Modniir_Priest]	= 0
	$map[$PN_SS_Summoner]		= 1
	$map[$PN_SS_Warder]			= 2
	$map[$PN_SS_Dominator]		= 2
	$map[$PN_SS_Blasphemer]		= 2
	$map[$PN_SS_Dreamer]		= 2
	$map[$PN_SS_Contaminator]	= 2
	$map[$PN_SS_Zealot]			= 2

	$map[$Gem_TortureWebDryder]	= 0
	$map[$Gem_RageTitan]		= 1
	$map[$Gem_AnurKi]			= 2
	$map[$Gem_AnurSu]			= 3
	$map[$Gem_AnurKaya]			= 4
	$map[$Gem_GreatDreamRider]	= 5
	$map[$Gem_HeartTormentor]	= 6
	$map[$Gem_WaterTormentor]	= 7

	$map[$WarSupply_Savant_1]		= 0
	$map[$WarSupply_Savant_2]		= 0
	$map[$WarSupply_Savant_3]		= 0
	$map[$WarSupply_Adherent_1]		= 0
	$map[$WarSupply_Adherent_2]		= 0
	$map[$WarSupply_Adherent_3]		= 0
	$map[$WarSupply_Adherent_4]		= 0
	$map[$WarSupply_Adherent_5]		= 0
	$map[$WarSupply_Priest_1]		= 1
	$map[$WarSupply_Priest_2]		= 1
	$map[$WarSupply_Priest_3]		= 1
	$map[$WarSupply_Priest_4]		= 1
	$map[$WarSupply_Ritualist_1]	= 2
	$map[$WarSupply_Ritualist_2]	= 2
	$map[$WarSupply_Ritualist_3]	= 2
	$map[$WarSupply_Ritualist_4]	= 2
	$map[$WarSupply_Ritualist_5]	= 2
	$map[$WarSupply_Ritualist_6]	= 2
	$map[$WarSupply_Ritualist_7]	= 2
	$map[$WarSupply_Ritualist_8]	= 2
	$map[$WarSupply_Ritualist_9]	= 2
	$map[$WarSupply_Ritualist_10]	= 2
	$map[$WarSupply_Ritualist_11]	= 2
	$map[$WarSupply_Abbot_1]		= 3
	$map[$WarSupply_Abbot_2]		= 3
	$map[$WarSupply_Abbot_3]		= 3
	$map[$WarSupply_Sycophant_1]	= 4
	$map[$WarSupply_Sycophant_2]	= 4
	$map[$WarSupply_Sycophant_3]	= 4
	$map[$WarSupply_Sycophant_4]	= 4
	$map[$WarSupply_Sycophant_5]	= 4
	$map[$WarSupply_Sycophant_6]	= 4
	$map[$WarSupply_Fanatic_1]		= 5
	$map[$WarSupply_Fanatic_2]		= 5
	$map[$WarSupply_Fanatic_3]		= 5
	$map[$WarSupply_Fanatic_4]		= 5

	Return $map
EndFunc