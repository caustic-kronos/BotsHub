#CS ===========================================================================
; Author: Ian
; Contributor: ----
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

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Agents.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $KILROY_FARM_INFORMATIONS = 'This bot loops the Kilroy Stonekins' & @CRLF _
	& 'Punch Out Extravanganza Quest' & @CRLF _
	& 'Check the Maintain Survivor under Options to keep Survivor going.' & @CRLF _
	& 'Ensure your Brass Knuckcles are in Weapon Slot 1'
Global Const $KILROY_FARM_DURATION = 10000 ;sample time for now

Global $kilroy_farm_setup = False

Func KilroyFarm()
EndFunc