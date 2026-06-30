#include-once
#include 'GWA2_Assembly.au3'
#include 'Utils-Console.au3'
#include 'Utils.au3'

; Sentinel used by GWA2_Assembly.au3 to detect this module and call the Extend* hooks.
Global Const $CHAT_LOG_STRUCT = 'dword;wchar[256]'

Global $detours_map[]

Global $chat_log_counter_address
Global $chat_message_channel_address
Global $chat_message_ptr_address
Global $chat_message_data_address
Global $whisper_counter_address
Global $whisper_data_address
Global $chat_log_last_counter = 0
Global $chat_log_last_whisper_counter = 0

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
	$chat_message_data_address = GetLabel('ChatMessageData')
	$whisper_counter_address = GetLabel('WhisperCounter')
	$whisper_data_address = GetLabel('WhisperData')
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
	_('ChatMessageData/512')
	_('WhisperCounter/4')
	_('WhisperData/512')
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
	;	[ebp+8] = message ptr (wchar_t*)
	;	[ebp+C] = channel (uint32_t)
	_('mov edx,dword[ebp+C]')
	_('mov dword[ChatMessageChannel],edx')
	_('mov edx,dword[ebp+8]')
	_('mov dword[ChatMessagePtr],edx')
	; Copy message bytes into our owned buffer before incrementing the counter.
	; This ensures the data is in BotsHub-controlled memory by the time the AutoIt
	; poller detects the counter change — GW's source buffer may be freed within ~150ms.
	_('mov esi,dword[ebp+8]')
	_('mov edi,ChatMessageData')
	_('mov ecx,128 -> B980000000')
	_('rep movsd -> F3A5')
	_('mov edx,dword[ChatMessageCounter]')
	_('inc edx')
	_('mov dword[ChatMessageCounter],edx')
	; If channel == 14 (Received Whisper, decimal 0x0E), snapshot the copied data into
	; WhisperData and bump WhisperCounter. This isolates whisper state from subsequent
	; messages on other channels that would otherwise overwrite ChatMessageData.
	_('cmp dword[ebp+C],0E -> 837D0C0E')
	_('jnz skipWhisper')
	_('mov esi,ChatMessageData')
	_('mov edi,WhisperData')
	_('mov ecx,128 -> B980000000')
	_('rep movsd -> F3A5')
	_('mov edx,dword[WhisperCounter]')
	_('inc edx')
	_('mov dword[WhisperCounter],edx')
	_('skipWhisper:')

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
		$chat_log_last_whisper_counter = GetWhisperCounter()
		AdlibRegister('ChatLogPollCallback', 5000)
		OnAutoItExitRegister('ChatLogOnExit')
	Else
		MemoryRevertDetour('ChatLogStart')
		AdlibUnRegister('ChatLogPollCallback')
		OnAutoItExitUnRegister('ChatLogOnExit')
	EndIf

EndFunc

;------------------------------------------------------
; Title...........:	ChatLogPollCallback
; Description.....:	AdlibRegister callback that fires every 5000ms (5s). Detects incoming
;					whispers by comparing WhisperCounter against the last seen value.
;					WhisperCounter and WhisperData are written by the hook assembly only when
;					AddToChatLog fires on channel 14 (Received Whisper), so this callback
;					never needs to inspect the channel itself.
;
;					Zone transition area-name announcements also fire AddToChatLog on channel
;					14 using GW-encoded text tokens rather than plain Unicode. They are filtered
;					out here by checking for the whisper separator character 'Ĉ' (U+0108) which
;					is always present in real whisper messages and never in encoded GW strings.
;
;					LIMITATION: Currently only handles 'Received Whisper'. To add general-channel
;					alerting (e.g. scan Trade/All for 'WTB conset'), register a separate
;					AdlibRegister callback that polls GetChatMessageCounter(), reads
;					GetChannelName(GetChatMessageChannel()) to filter by channel, and reads
;					the message from ChatMessageData via $chat_message_data_address.
;					For collision safety between channels, mirror the WhisperCounter/WhisperData
;					pattern: add per-channel counter+data labels in AssemblerCreateEventData and
;					a conditional block in AssemblerCreateChatLog that snapshots on the desired
;					channel number.
;------------------------------------------------------
Func ChatLogPollCallback()
	Local $counter = GetWhisperCounter()
	If $counter = $chat_log_last_whisper_counter Then Return
	$chat_log_last_whisper_counter = $counter

	; Read from WhisperData — isolated to channel 14 only, copied at hook-fire time.
	; Zone transition messages lack the whisper separator 'Ĉ' and are filtered here.
	Local $message = MemoryRead(GetProcessHandle(), $whisper_data_address, 'wchar[256]')
	Local $separatorPos = StringInStr($message, 'Ĉ')
	If $separatorPos = 0 Then Return
	Local $sender = StringMid($message, 3, $separatorPos - 3)

	WhisperFlashCallback('Received Whisper', $sender, '', 'No')
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

Func GetWhisperCounter()
	Return MemoryRead(GetProcessHandle(), $whisper_counter_address)
EndFunc

; Maps a raw GW channel type integer to a human-readable name.
; Use with GetChatMessageCounter() + ChatMessageData to build general-channel alerting
; (e.g. scan Trade or All for keyword matches).
Func GetChannelName($channelType)
	Switch $channelType
		Case 0
			Return 'Alliance'
		Case 3
			Return 'All'
		Case 9
			Return 'Guild'
		Case 10
			Return 'Send Whisper'
		Case 11
			Return 'Team'
		Case 12
			Return 'Trade'
		Case 13
			Return 'Advisory'
		Case 14
			Return 'Received Whisper'
		Case Else
			Return 'Other'
	EndSwitch
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