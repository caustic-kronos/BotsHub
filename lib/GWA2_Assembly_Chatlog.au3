#include-once
#include 'GWA2_Assembly.au3'
#include 'Utils-Console.au3'
#include 'Utils.au3'

Global Const $CHAT_LOG_STRUCT = 'dword;wchar[256]'

Global $detours_map[]

Global $chat_receive_function
Global $chat_log_base_address
Global $chat_log_counter_address
Global $chat_message_channel_address

Func ExtendAddPattern()
	AddScanPattern('PostMessage',	'6AFF6A00680180',	0x19,	'ptr')
	AddScanPattern('ChatLog',		'8B4508837D0C07',	-0x20,	'hook')
EndFunc

Func ExtendScannerWithChatLog()
	Local $postMessage = $scan_results['PostMessage']
	SetLabel('PostMessage', Ptr(MemoryRead(GetProcessID(), $postMessage, 'dword')))

	Local $tempValue = $scan_results['ChatLog']
	SetLabel('ChatLogStart', Ptr($tempValue))
	SetLabel('ChatLogReturn', Ptr($tempValue + 0x5))

	Debug('PostMessage: ' & GetLabel('PostMessage'))
	Debug('ChatLogStart: ' & GetLabel('ChatLogStart'))
	Debug('ChatLogReturn: ' & GetLabel('ChatLogReturn'))

	SetLabel('ChatLogCallbackEvent', '0x00000501')
	SetLabel('ChatLogSize', '0x00000010')
EndFunc

Func ExtendInitializeChatLogResult()
	Local $chatLogGUI = GUICreate('ChatLogGUI')
	GUIRegisterMsg(0x00000501, 'ChatLogEventCallback')
	MemoryWrite(GetProcessHandle(), GetLabel('ChatLogCallbackHandle'), $chatLogGUI)
	Debug('ChatLogCallbackHandle: ' & GetLabel('ChatLogCallbackHandle'))

	$chat_log_base_address = GetLabel('ChatLogBase')
	$chat_log_counter_address = GetLabel('ChatMessageCounter')
	$chat_message_channel_address = GetLabel('ChatMessageChannel')
EndFunc

Func ExtendAssembler()
	AssemblerCreateChatLog()
EndFunc

Func ExtendAssemblerData()
	AssemblerCreateEventData()
EndFunc

Func AssemblerCreateEventData()
	_('ChatLogCallbackHandle/4')
	_('ChatLogCallbackEvent/4')

	_('ChatLogLastMsg/4')
	_('ChatLogCounter/4')
	_('ChatMessageCounter/4')
	_('ChatMessageChannel/4')

	_('ChatLogBase/' & 512)
EndFunc

Func AssemblerCreateChatLog()
	_('ChatLogProc:')
	_('pushfd')
	_('pushad')
	_('mov ecx,dword[esp+30]')
	_('add ecx,4')
	_('xor ebx,ebx')
	_('mov eax,ChatLogBase')

	_('ChatLogCopyLoop:')
	_('mov dx,word[ecx]')
	_('mov word[eax],dx')
	_('add ecx,2')
	_('add eax,2')
	_('inc ebx')
	_('cmp ebx,FF')
	_('jz ChatLogCopyExit')
	_('test dx,dx')
	_('jnz ChatLogCopyLoop')

	_('ChatLogCopyExit:')
	_('mov edx,dword[esp+34]')
	_('mov dword[ChatMessageChannel],edx')
	_('push eax')
	_('mov eax,ChatLogBase')
	_('sub eax,4')
	_('mov dword[eax],edx')
	_('pop eax')
	_('mov edx,dword[ChatMessageCounter]')
	_('inc edx')
	_('mov dword[ChatMessageCounter],edx')
	_('push 1')
	_('mov edx,ChatLogBase')
	_('sub edx,4')
	_('push edx')
	_('push ChatLogCallbackEvent')
	_('push dword[ChatLogCallbackHandle]')
	_('call dword[PostMessage]')

	_('popad')
	_('popfd')

	_('mov eax,dword[ebp+8]')
	_('test eax,eax')
	_('ljmp ChatLogReturn')
EndFunc

Func MemoryWriteDetourEx($fromLabel, $toLabel)
	Local $labelPtr = GetLabel($fromLabel)
	Local $buffer = DllStructCreate('byte[5]')

	DllCall($kernel_handle, 'bool', 'ReadProcessMemory', _
		'handle', GetProcessHandle(), _
		'ptr', $labelPtr, _
		'ptr', DllStructGetPtr($buffer), _
		'ulong_ptr', 5, _
		'ulong_ptr*', 0)

	Local $originalOpCode = ''
	For $i = 1 To 5
		$originalOpCode &= Hex(DllStructGetData($buffer, 1, $i), 2)
	Next
	$detours_map[$fromLabel] = $originalOpCode

	WriteBinary(GetProcessHandle(), 'E9' & SwapEndian(Hex(GetLabel($toLabel) - GetLabel($fromLabel) - 5)), GetLabel($fromLabel))
EndFunc

Func MemoryRevertDetour($fromLabel)
	If Not MapExists($detours_map, $fromLabel) Then Return 0

	Local $originalOpCode = $detours_map[$fromLabel]
	Local $labelPtr = GetLabel($fromLabel)

	WriteBinary(GetProcessHandle(), $originalOpCode, $labelPtr)
	MapRemove($detours_map, $fromLabel)

	Return True
EndFunc

Func ChatLogSetEventCallback($chatReceive = '')
	If $chatReceive <> '' Then
		MemoryWriteDetourEx('ChatLogStart', 'ChatLogProc')
	Else
		MemoryRevertDetour('ChatLogStart')
	EndIf

	$chat_receive_function = $chatReceive

	Info('ChatLog event callbacks configured')
EndFunc

Func ChatLogEventCallback($handle, $uselessMessage, $param1, $param2)
	Switch $param2
		Case 0x1
			Local $chatLogStruct = DllStructCreate($CHAT_LOG_STRUCT)
			DllCall($kernel_handle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'int', $param1, 'ptr', DllStructGetPtr($chatLogStruct), 'int', 512, 'int', '')
			Local $channelType = DllStructGetData($chatLogStruct, 1)
			Local $message = DllStructGetData($chatLogStruct, 2)
			Local $channel = ''
			Local $sender = ''
			Local $guildTag = 'No'

			Switch $channelType
				Case 0
					$channel = 'Alliance'
					ChatLogParseAlliance($message, $sender, $guildTag, $message)
				Case 3
					$channel = 'All'
					ChatLogParseGeneral($message, $sender, $message)
				Case 9
					$channel = 'Guild'
					ChatLogParseGuild($message, $sender, $message)
				Case 11
					$channel = 'Team'
					ChatLogParseGeneral($message, $sender, $message)
				Case 12
					$channel = 'Trade'
					ChatLogParseGeneral($message, $sender, $message)
				Case 10
					$channel = 'Send Whisper'
					ParseWhisper($message, $sender, $message)
				Case 13
					$channel = 'Advisory'
					$sender = 'Guild Wars'
					$message = ''
				Case 14
					$channel = 'Received Whisper'
					ParseWhisper($message, $sender, $message, 1)
				Case Else
					$channel = 'Other'
					$sender = 'Other'
			EndSwitch

			Call($chat_receive_function, $channel, $sender, $message, $guildTag)
			Debug('Channel: ' & $channel & ' Sender: ' & $sender & ' Guild: ' & $guildTag & ' Message: ' & $message)
	EndSwitch

	Return 0
EndFunc

Func ChatLogParseAlliance($message, ByRef $sender, ByRef $tag, ByRef $text)
	Local $tagSeparator = 'Ĉ', $textSeparator = 'ċĈć'
	Local $tagSeparatorPos = StringInStr($message, $tagSeparator)
	Local $textSeparatorPos = StringInStr($message, $textSeparator)
	Local $tagStart = $tagSeparatorPos + StringLen($tagSeparator)
	Local $textStart = $textSeparatorPos + StringLen($textSeparator)

	$sender = StringMid($message, 3, $tagSeparatorPos - 3)
	$tag = StringMid($message, $tagStart, $textSeparatorPos - $tagStart)
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLogParseGuild($message, ByRef $sender, ByRef $text, $separator = 'ċĈć')
	Local $separatorPos = StringInStr($message, $separator)
	Local $textStart = $separatorPos + StringLen($separator)

	$sender = StringLeft($message, $separatorPos - 1)
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func ChatLogParseGeneral($message, ByRef $sender, ByRef $text, $separator = 'ċĈć')
	Local $separatorPos = StringInStr($message, $separator)
	If $separatorPos = 0 Then
		$separator = 'ċ脂໾ć'
		$separatorPos = StringInStr($message, $separator)
	EndIf
	Local $textStart = $separatorPos + StringLen($separator)

	$sender = StringMid($message, 3, $separatorPos - 3)
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func ParseWhisper($message, ByRef $sender, ByRef $text, $sendreceive = 0)
	Local $separatorPos = StringInStr($message, 'Ĉ')
	Local $textStart = $separatorPos + 2

	$sender = ($sendreceive = 0 ? StringMid($message, 3, $separatorPos - 3) : StringLeft($message, $separatorPos - 1))
	$text = StringMid($message, $textStart, StringInStr($message, '', 0, 1, $textStart) - $textStart)
EndFunc

Func GetChatMessageCounter()
	Return MemoryRead(GetProcessID(), $chat_log_counter_address)
EndFunc

Func GetChatMessageChannel()
	Return MemoryRead(GetProcessID(), $chat_message_channel_address)
EndFunc