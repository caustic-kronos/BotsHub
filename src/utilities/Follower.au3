#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'

; Possible improvements :
; - Correct a crash happening when someone picks up items the bot wanted to pick up
; - speed up the bot by all ways possible (since it casts shouts it is always lagging behind)
;		- using a cupcake and a pumpkin pie might be a good idea


; ==== Constants ====
Global Const $FOLLOWER_INFORMATIONS = 'This bot makes your character follow the first other player in party.' & @CRLF _
	& 'It will attack everything that gets in range.' & @CRLF _
	& 'It will loot all items it can loot.' & @CRLF _
	& 'It will also loot all chests in range.'

Global Const $FOLLOWER_LEASH_RANGE = $RANGE_SPELLCAST - 200

Global $optionsFollower					= CloneMap($default_move_aggro_kill_options)
$optionsFollower['fightRange']			= $MOB_AGGRO_RANGE
$optionsFollower['callTarget']			= False
$optionsFollower['priorityTargeting']	= False
$optionsFollower['skillsCostMap']		= Null
;$optionsFollower['skillsCastTimeMap']	= Null
$optionsFollower['lootInCombat']		= False
$optionsFollower['openChests']			= True
$optionsFollower['chestOpenRange']		= $MOB_AGGRO_RANGE
$optionsFollower['killMethod']			= UseSkillSequentially
$optionsFollower['abortCondition']		= FollowerNotInRangeOfLeader

Global $leaderID = Null

;~ Main loop
Func FollowerFarm()
	While $runtime_status == 'RUNNING'
		FollowerLoop()
	WEnd
	Return $runtime_status <> 'RUNNING' ? $PAUSE : $SUCCESS
EndFunc


;~ Follower loop
Func FollowerLoop($options = $optionsFollower)
	Local Static $currentMap = Null, $resigned = False

	; Map change detection (even in outposts !)
	Local $mapID = GetMapID()
	If $mapID <> $currentMap Then
		$currentMap = $mapID
		$leaderID = Null
		$resigned = False
		SkipCinematic()
		WaitMapLoading($mapID)
	EndIf

	; If map is not explorable, no following happening
	If GetMapType() <> $ID_EXPLORABLE Then
		Sleep(1000)
		Return
	EndIf

	; Resolving leaderID if needed
	If $leaderID == Null Then $leaderID = FollowerResolveLeaderID()
	; If no leader found, wait, try next time
	If $leaderID == Null Then
		Sleep(1000)
		Return
	EndIf

	; Auto resigning
	If Not $resigned Then
		Info('Auto-resigning on explorable entry')
		Resign()
		$resigned = True
		RandomSleep(500)
	EndIf

	; Could set a run function to speed up team/follower
	If $options['runFunction'] <> Null Then $options['runFunction']()

	; Getting leader and moving to him
	Local $leader = GetAgentByID($leaderID)
	Local $me = GetMyAgent()

	; Trigger fight only if extremely close to leader - but leave fight if leader is far away
	If FollowerInRangeOfLeader($leader, $me, $RANGE_NEARBY) Then
		Local $fightRange			= $options['fightRange'] <> Null ?			$options['fightRange'] : $WIDE_PLAYER_AGGRO_RANGE
		Local $fightHandler			= $options['fightHandler'] <> Null ?		$options['fightHandler'] : KillFoesInArea
		Local $unstuckHandler		= $options['unstuckHandler'] <> Null ?		$options['unstuckHandler'] : TryToGetUnstuck
		Local $openChests			= $options['openChests'] <> Null ?			$options['openChests'] : True
		Local $chestOpenRange		= $options['chestOpenRange'] <> Null ?		$options['chestOpenRange'] : $RANGE_SPIRIT

		Local $target = GetNearestEnemyToAgent($me)
		If DllStructGetData($target, 'ID') <> 0 And GetDistance($me, $target) < $fightRange Then
			; No checks required on failure - follower just follows
			$fightHandler($options)
			; FIXME: add rezzing dead party members here

			; Refresh leader if fight happened
			$leader = GetAgentByID($leaderID)
		EndIf

		; Chest part
		If $openChests Then
			Local $chest = FindChest($chestOpenRange)
			If $chest <> Null Then
				FindAndOpenChests($chestOpenRange)

				; Refresh leader if chest opening happened
				$leader = GetAgentByID($leaderID)
			EndIf
		EndIf

		; Loot part
		PickUpItems(Null, DefaultShouldPickItem, $MOB_AGGRO_RANGE)
	EndIf

	GoPlayer($leader)
	Sleep(1000)
EndFunc


;~ Override for callback calls
Func FollowerNotInRangeOfLeader()
	Return Not FollowerInRangeOfLeader(GetAgentByID($leaderID), GetMyAgent())
EndFunc


Func FollowerInRangeOfLeader($leader = GetAgentByID($leaderID), $me = GetMyAgent(), $range = $FOLLOWER_LEASH_RANGE)
	Return $leader == Null Or GetDistance($me, $leader) < $range
EndFunc


;~ Resolve the leader's agent struct by reading the agent ID directly out of the player record array.
;~ Works in both outposts and explorables. Bypasses the lib's GetFirstPlayerOfParty, which fails in
;~ outposts because party agent structs report LoginNumber=0 there.
;~ Player records are 80 bytes wide; agent ID is at offset 0 of each record.
Func FollowerResolveLeaderID()
	Local $myLoginNumber = DllStructGetData(GetMyAgent(), 'LoginNumber')
	Local $partyMembers = GetParty()
	For $member In $partyMembers
		Local $loginNumber = DllStructGetData($member, 'LoginNumber')
		If $loginNumber <= 0 Then ContinueLoop
		If $loginNumber == $myLoginNumber Then ContinueLoop
		Return DllStructGetData($member, 'ID')
	Next
	Return Null
EndFunc