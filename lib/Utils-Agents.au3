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


#Region Party
Global $partyFailuresCount = 0
Global $partyIsAlive = True

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
	If ($partyFailuresCount > $MaxPartyWipesCount) Then
		Notice('Party wiped ' & $partyFailuresCount & ' times, run is considered failed.')
		Return True
	EndIf
	Return False
EndFunc


;~ Is party alive right now
Func IsPartyCurrentlyAlive()
	Return $partyIsAlive
EndFunc


;~ Reset the failures counter
Func ResetFailuresCounter()
	$partyFailuresCount = 0
	$partyIsAlive = True
EndFunc


;~ Updates the partyIsAlive variable, this function is run on a fixed timer (10s)
Func TrackPartyStatus()
	; If GetAgentExists(GetMyID()) is False, player is disconnected or between instances, do not track party status
	If GetAgentExists(GetMyID()) And IsPlayerAndPartyWiped() Then
		$partyFailuresCount += 1
		Notice('Party wiped for the ' & $partyFailuresCount & ' time')
		$partyIsAlive = False
	Else
		$partyIsAlive = True
	EndIf
EndFunc


;~ Returns True if the party is alive, that is if there is still an alive hero with resurrection skill
Func HasRezMemberAlive()
	Local Static $heroesWithRez = FindHeroesWithRez()
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
		Local $heroID = GetHeroID($heroNumber)
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
		If GetIsDead($agent) Then ContinueLoop
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


;~ Print Item informations
Func PrintItemInformations($item)
	Info('ID: ' & DllStructGetData($item, 'ID'))
	Info('ModStruct: ' & GetModStruct($item))
	Info('ModStructSize: ' & DllStructGetData($item, 'ModStructSize'))
	Info('ModelFileID: ' & DllStructGetData($item, 'ModelFileID'))
	Info('Type: ' & DllStructGetData($item, 'Type'))
	Info('DyeColor: ' & DllStructGetData($item, 'DyeColor'))
	Info('Value: ' & DllStructGetData($item, 'Value'))
	Info('Interaction: ' & DllStructGetData($item, 'Interaction'))
	Info('ModelId: ' & DllStructGetData($item, 'ModelId'))
	Info('ItemFormula: ' & DllStructGetData($item, 'ItemFormula'))
	Info('IsMaterialSalvageable: ' & DllStructGetData($item, 'IsMaterialSalvageable'))
	Info('Quantity: ' & DllStructGetData($item, 'Quantity'))
	Info('Equipped: ' & DllStructGetData($item, 'Equipped'))
	Info('Profession: ' & DllStructGetData($item, 'Profession'))
	Info('Type2: ' & DllStructGetData($item, 'Type2'))
	Info('Slot: ' & DllStructGetData($item, 'Slot'))
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
		Sleep(200)
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
#EndRegion Getting NPCs


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


;~ Get NPCs in range of the given coordinates. If range is Null then all found NPCs are retuned, as with infinite range
Func GetNPCsInRangeOfCoords($coordX = Null, $coordY = Null, $npcAllegiance = Null, $range = $RANGE_AREA, $condition = Null)
	Local $agents = GetAgentArray($ID_AGENT_TYPE_NPC)
	Local $allAgents[GetMaxAgents()]
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