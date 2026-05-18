#include-once

; Sentinel used by GWA2_Assembly.au3 to detect this module and call the Extend* hooks.
Global Const $CHAT_LOG_STRUCT = 'dword;wchar[256]'

Global $detours_map[]

Global $chat_log_counter_address
Global $chat_message_channel_address
Global $chat_message_ptr_address
Global $chat_log_last_counter = 0

Func AddChatLogScanPattern()
	AddScanPattern('ChatLog',		'8B4508837D0C07',	-0x20,	'hook')
EndFunc

Func ExtendScannerWithChatLog()
	Local $tempValue = $scan_results['ChatLog']
	SetLabel('ChatLogStart', Ptr($tempValue))
	SetLabel('ChatLogReturn', Ptr($tempValue + 0x5))
EndFunc

Func ExtendInitializeChatLogResult()
	$chat_log_counter_address = GetLabel('ChatMessageCounter')
	$chat_message_channel_address = GetLabel('ChatMessageChannel')
	$chat_message_ptr_address = GetLabel('ChatMessagePtr')
EndFunc

Func ExtendAssembler()
	AssemblerCreateChatLog()
EndFunc

Func ExtendAssemblerData()
	AssemblerCreateEventData()
EndFunc

Func AssemblerCreateEventData()
	_('ChatMessageCounter/4')
	_('ChatMessageChannel/4')
	_('ChatMessagePtr/4')
EndFunc

Func AssemblerCreateChatLog()
	; ChatLogProc label BEFORE nop x4: GetLabel('ChatLogProc') = physical_nop_start+4 = pushfd address.
	; The entry JMP targets GetLabel('ChatLogProc') and lands correctly at pushfd.
	_('ChatLogProc:')
	_('nop x4')
	_('pushfd')
	_('pushad')
	; AddToChatLog uses EBP-relative argument access (inherited from caller frame).
	; Original first instruction: MOV EAX,[EBP+8] confirms EBP is valid at hook point.
	;   [ebp+8] = message ptr (wchar_t*)
	;   [ebp+C] = channel (uint32_t)
	_('mov edx,dword[ebp+C]')
	_('mov dword[ChatMessageChannel],edx')
	_('mov edx,dword[ebp+8]')
	_('mov dword[ChatMessagePtr],edx')
	_('mov edx,dword[ChatMessageCounter]')
	_('inc edx')
	_('mov dword[ChatMessageCounter],edx')

	_('popad')
	_('popfd')
	_('ljmp ChatLogTrampoline')

	; ChatLogTrampoline label BEFORE nop x4: GetLabel('ChatLogTrampoline') = nop_start+4 = nop_x5 address.
	; WriteBinary writes the 5 original function bytes at exactly nop_x5, not 4 bytes into it.
	; ljmp ChatLogReturn is at nop_x5+5, safe from overflow.
	_('ChatLogTrampoline:')
	_('nop x4')
	_('nop x5')
	_('ljmp ChatLogReturn')
EndFunc

Func MemoryWriteDetourEx($fromLabel, $toLabel, $trampolineLabel)
	Local $labelPtr = GetLabel($fromLabel)
	Local $buffer = DllStructCreate('byte[5]')

	DllCall($kernel_handle, 'bool', 'ReadProcessMemory', _
		'handle', GetProcessHandle(), _
		'ptr', $labelPtr, _
		'ptr', DllStructGetPtr($buffer), _
		'ulong_ptr', 5, _
		'ulong_ptr*', 0)

	; Detect stale hook: if the first byte is E9 (JMP), a previous BotsHub session installed
	; this hook and did not revert it before closing. The trampoline slot already holds the
	; correct original GW bytes from that session. Read from there instead of using the stale
	; JMP bytes at fromLabel, which would produce a garbage trampoline and crash GW.
	Local $isStale = (DllStructGetData($buffer, 1, 1) = 0xE9)
	If $isStale Then
		DllCall($kernel_handle, 'bool', 'ReadProcessMemory', _
			'handle', GetProcessHandle(), _
			'ptr', GetLabel($trampolineLabel), _
			'ptr', DllStructGetPtr($buffer), _
			'ulong_ptr', 5, _
			'ulong_ptr*', 0)
	EndIf

	Local $originalOpCode = ''
	For $i = 1 To 5
		$originalOpCode &= Hex(DllStructGetData($buffer, 1, $i), 2)
	Next
	$detours_map[$fromLabel] = $originalOpCode

	If Not $isStale Then
		; Write original bytes into trampoline, replacing CC (INT 3 hotpatch byte) with 90 (NOP)
		; to prevent GW from closing when the trampoline executes with no debugger attached
		Local $trampolineBytes = $originalOpCode
		If StringLeft($trampolineBytes, 2) = 'CC' Then
			$trampolineBytes = '90' & StringMid($trampolineBytes, 3)
		EndIf
		WriteBinary(GetProcessHandle(), $trampolineBytes, GetLabel($trampolineLabel))
	EndIf

	Local $jmpOffset = GetLabel($toLabel) - GetLabel($fromLabel) - 5
	WriteBinary(GetProcessHandle(), 'E9' & SwapEndian(Hex($jmpOffset, 8)), GetLabel($fromLabel))
EndFunc

Func MemoryRevertDetour($fromLabel)
	If Not MapExists($detours_map, $fromLabel) Then Return 0

	Local $originalOpCode = $detours_map[$fromLabel]
	Local $labelPtr = GetLabel($fromLabel)

	WriteBinary(GetProcessHandle(), $originalOpCode, $labelPtr)
	MapRemove($detours_map, $fromLabel)

	Return True
EndFunc

;------------------------------------------------------
; Title...........:	ChatLogOnExit
; Description.....:	OnAutoItExitRegister handler. Reverts the ChatLog detour whenever
;					BotsHub exits (normal close, error, or tray exit) so GW's code at
;					ChatLogStart is restored to its original bytes. Without this, a
;					subsequent BotsHub session would find a stale JMP at ChatLogStart and
;					crash GW the next time a chat message arrives.
;------------------------------------------------------
Func ChatLogOnExit()
	AdlibUnRegister('ChatLogPollCallback')
	MemoryRevertDetour('ChatLogStart')
EndFunc

Func ChatLogSetEventCallback($chatReceive = '')
	If $chatReceive <> '' Then
		MemoryWriteDetourEx('ChatLogStart', 'ChatLogProc', 'ChatLogTrampoline')
		$chat_log_last_counter = GetChatMessageCounter()
		; NOTE: Polling interval cannot exceed ~100ms. GW's internal message buffer is small;
		; slower polling causes the pointer at $msgPtr to become stale/invalid before it's read,
		; resulting in silent failure (whisper notifications never fire).
		; Further testing and debugging will be required to implement a more conservative frequency.
		AdlibRegister('ChatLogPollCallback', 100)
		OnAutoItExitRegister('ChatLogOnExit')
	Else
		MemoryRevertDetour('ChatLogStart')
		AdlibUnRegister('ChatLogPollCallback')
		OnAutoItExitUnRegister('ChatLogOnExit')
	EndIf

EndFunc

;------------------------------------------------------
; Title...........:	ChatLogPollCallback
; Description.....:	AdlibRegister callback that fires every 100ms. Detects new chat
;					messages by comparing ChatMessageCounter against the last seen value,
;					then reads the message from GW memory and dispatches to
;					$chat_receive_function. Replaces the PostMessage/GUIRegisterMsg approach
;					to avoid cross-thread Windows API calls from inside the GW hook.
;
;					Zone transition area-name announcements also fire AddToChatLog on channel
;					14 (the same slot as Received Whisper) using GW-encoded text tokens rather
;					than plain Unicode. They are filtered out here by checking for the whisper
;					separator character 'Ĉ' (U+0108) which is always present in real whisper
;					messages and never in encoded GW strings.
;
;					LIMITATION: Currently only extracts sender name for 'Received Whisper'
;					channel. Other channels (Alliance, Guild, Trade, All, etc.) dispatch with
;					empty $message and $guildTag = 'No'. If callbacks need to parse message
;					content from other channels, this function must be refactored to:
;					- Read message pointer for all channels (not just whisper)
;					- Call ChatLogParseAlliance/ChatLogParseGuild/etc. per channel type
;					- Pass extracted message and sender to callback
;------------------------------------------------------
Func ChatLogPollCallback()
	Local $counter = GetChatMessageCounter()
	If $counter = $chat_log_last_counter Then Return
	$chat_log_last_counter = $counter

	Local $channelType = GetChatMessageChannel()
	Local $channel = ''
	Switch $channelType
		Case 0
			$channel = 'Alliance'
		Case 3
			$channel = 'All'
		Case 9
			$channel = 'Guild'
		Case 10
			$channel = 'Send Whisper'
		Case 11
			$channel = 'Team'
		Case 12
			$channel = 'Trade'
		Case 13
			$channel = 'Advisory'
		Case 14
			$channel = 'Received Whisper'
		Case Else
			$channel = 'Other'
	EndSwitch

	Local $sender = ''
	If $channel = 'Received Whisper' Then
		; Read the GW message string from the pointer stored by the hook.
		; Zone transition messages also arrive on channel 14 as GW-encoded text tokens
		; (e.g. 8102 0000) and will not contain the whisper separator 'Ĉ'. If the
		; separator is absent the event is not a real player whisper — skip it.
		Local $msgPtr = GetChatMessagePtr()
		If $msgPtr = 0 Then Return
		Local $message = MemoryRead(GetProcessHandle(), $msgPtr, 'wchar[64]')
		Local $separatorPos = StringInStr($message, 'Ĉ')
		If $separatorPos = 0 Then Return
		$sender = StringMid($message, 3, $separatorPos - 3)
	EndIf

	WhisperFlashCallback($channel, $sender, '', 'No')
EndFunc

Func ChatLogParseAlliance($message, ByRef $sender, ByRef $tag, ByRef $text)
	Local $tagSeparator = 'Ĉ', $textSeparator = 'ċĈć'
	Local $tagSeparatorPos = StringInStr($message, $tagSeparator)
	Local $textSeparatorPos = StringInStr($message, $textSeparator)
	Local $tagStart = $tagSeparatorPos + StringLen($tagSeparator)
	Local $textStart = $textSeparatorPos + StringLen($textSeparator)

	$sender = StringMid($message, 3, $tagSeparatorPos - 3)
	$tag = StringMid($message, $tagStart, $textSeparatorPos - $tagStart)
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLogParseGuild($message, ByRef $sender, ByRef $text, $separator = 'ċĈć')
	Local $separatorPos = StringInStr($message, $separator)
	Local $textStart = $separatorPos + StringLen($separator)

	$sender = StringLeft($message, $separatorPos - 1)
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLogParseGeneral($message, ByRef $sender, ByRef $text, $separator = 'ċĈć')
	Local $separatorPos = StringInStr($message, $separator)
	If $separatorPos = 0 Then
		$separator = 'ċ脂໾ć'
		$separatorPos = StringInStr($message, $separator)
	EndIf
	Local $textStart = $separatorPos + StringLen($separator)

	$sender = StringMid($message, 3, $separatorPos - 3)
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func ParseWhisper($message, ByRef $sender, ByRef $text, $sendreceive = 0)
	Local $separatorPos = StringInStr($message, 'Ĉ')
	Local $textStart = $separatorPos + 2

	$sender = ($sendreceive = 0 ? StringMid($message, 3, $separatorPos - 3) : StringLeft($message, $separatorPos - 1))
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func GetChatMessageCounter()
	Return MemoryRead(GetProcessHandle(), $chat_log_counter_address)
EndFunc

Func GetChatMessageChannel()
	Return MemoryRead(GetProcessHandle(), $chat_message_channel_address)
EndFunc

Func GetChatMessagePtr()
	Return MemoryRead(GetProcessHandle(), $chat_message_ptr_address)
EndFunc

;------------------------------------------------------
; Title...........:	FlashGWWindow
; Description.....:	Flash the GW taskbar button until the user focuses the window.
;					Uses FlashWindowEx with FLASHW_TRAY | FLASHW_TIMERNOFG (0xE).
;------------------------------------------------------
Func FlashGWWindow()
	Local Const $FLASHW_TRAY = 0x2
	Local Const $FLASHW_TIMERNOFG = 0xC
	Local $flashwInfo = DllStructCreate('uint;hwnd;dword;uint;dword')
	DllStructSetData($flashwInfo, 1, DllStructGetSize($flashwInfo))
	DllStructSetData($flashwInfo, 2, GetWindowHandle())
	DllStructSetData($flashwInfo, 3, BitOR($FLASHW_TRAY, $FLASHW_TIMERNOFG))
	DllStructSetData($flashwInfo, 4, 0)
	DllStructSetData($flashwInfo, 5, 0)
	DllCall('user32.dll', 'bool', 'FlashWindowEx', 'ptr', DllStructGetPtr($flashwInfo))
EndFunc

;------------------------------------------------------
; Title...........:	WhisperFlashCallback
; Description.....:	Chat log callback that flashes the GW taskbar button when a whisper is received.
;------------------------------------------------------
Func WhisperFlashCallback($channel, $sender, $message, $guildTag)
	If $channel = 'Received Whisper' Then
		Info('[ChatLog] Whisper from ' & $sender)
		FlashGWWindow()
	EndIf
EndFunc

;------------------------------------------------------
; Title...........:	EnableWhisperFlash
; Description.....:	Installs the chat log hook and registers WhisperFlashCallback so the
;					GW taskbar button flashes whenever an incoming whisper is intercepted.
;					Requires GWA2 to be fully initialized before calling.
;------------------------------------------------------
Func EnableWhisperFlash()
	ChatLogSetEventCallback('WhisperFlashCallback')
EndFunc