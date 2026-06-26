# GWA2 Reverse Engineering

An explanation on how to reverse engineer GuildWars, through an example.

---

## Required tools

You will need :
- GW
- Ghidra
- Cheat Engine
- AutoIt or any other environment to code
- patience

## How GWA2 works

1. Allocate some memory inside the GW process
	```$memoryInterface = SafeDllCall13($kernelHandle, 'ptr', 'VirtualAllocEx', 'handle', GetProcessHandle(), 'ptr', 0, 'ulong_ptr', $asmInjectionSize, 'dword', 0x1000, 'dword', 0x40)```
2. Writes some patterns (literally pieces of code from the GW executable that should mostly not change) inside that newly allocated memory
	```_('ScanInstanceInfo:')
	AddPatternToInjection('85c07417ff7508e8')```
	```WriteBinary($asmInjectionString, $memoryInterface + $asmCodeOffset)```
3. Start a thread inside the GW process that will read each pattern, find it inside GW own memory, and write the corresponding address in the allocated memory
	```Local $thread = SafeDllCall17($kernelHandle, 'int', 'CreateRemoteThread', 'int', GetProcessHandle(), 'ptr', 0, 'int', 0, 'int', GetLabelInfo('ScanProc'), 'ptr', 0, 'int', 0, 'int', 0)```
4. Read the address corresponding to the pattern we provided it, potentially with some offset depending on what we want to read
	```	$tempValue = GetScannedAddress('ScanInstanceInfo', -0x04)```
5. Use this address to read the data we are interested in
	```	$instanceInfoPtr = MemoryRead($tempValue + MemoryRead($tempValue + 0x01) + 0x05 + 0x01, 'dword')```
	```;~ Returns the instance type (city, explorable, mission, etc ...)
	Func GetInstanceType()
		Local $offset[1] = [0x00]
		Local $result = MemoryReadPtr($instanceInfoPtr, $offset, 'dword')
		Return $result[1]
	EndFunc
	```

## An illustrated example

### Description of the issue

Instance informations (telling if the character is in an town, an explorable area or loading a map) were broken.
Those were the original relevant values in the different places of the code :
	```$instanceInfoPtr = MemoryRead(GetScannedAddress('ScanInstanceInfo', 0xE))```

	```_('ScanInstanceInfo:')
	AddPatternToInjection('6A2C50E80000000083C408C7')```

	```;~ Returns the instance type (city, explorable, mission, etc ...)
	Func GetInstanceType()
		Local $offset[1] = [0x4]
		Local $result = MemoryReadPtr($instanceInfoPtr, $offset, 'dword')
		Return $result[1]
	EndFunc```

By enabling debugger (cf: ../lib/Utils-Debugger.au3), we could see those errors :
```
[2025-05-10 18:01:489]-[RunFarmLoop|SetupRaptorFarm|MoveTo|GetInstanceType|MemoryReadPtr]-Read - Memory is not committed - 65536
```
This error meant that the $instanceInfoPtr was not properly set up because the MemoryRead function was reading a space in memory that was not committed.
```
[2025-05-10 18:01:489]-[RunFarmLoop|SetupRaptorFarm|MoveTo|GetInstanceType|MemoryReadPtr]-[ERROR] Code[299] on DllCall(dll=2,retType=int,fun=ReadProcessMemory,p4=int,p5=656,p6=int,p7=4,p8=ptr,p9=0x05A06918,p10=int,p11=4,p12=int,p13=0)
```
This error meant that the ReadProcessMemory completely failed and didn't return any correct result.

Both those errors together told us that the addresses used in those lines were not correct anymore.

### First step

To correct this, the first thing we need to do is find the proper address.
For that, we need to start CheatEngine and link it to our GW running instance.
Then, we need to find the variable that corresponds to our issue. In our case, it's a variable describing the instance type.
To do so, please refer to another guide, there are plenty of them on how to use CheatEngine. I'll refer you to this one : https://www.youtube.com/watch?v=4KJNM0FiE14

Using the methods described in this guide, by moving from a city (0) to an explorable (1) and back again and again, I found the address of the variable describing the InstanceInfo :
`Gw.exe+AD9EA8`

With this address, you can already verify that it is valid on your chosen bot, for instance :
```
;~ Alternate way to get instance infos, reads directly from game memory without call to Scan something
Func AlternateGetInstanceInfos()
	Local $baseAddress = ScanForProcess()
	; This address is relative to the CheatEngine GW base address
	; The GW base address we get from ScanForProcess() is 0x1000 after the one from CheatEngine
	; So we need to remove that 0x1000 if we want to have the correct value
	Local $relativePingAddress = 0xAD9EA8
	Local $pingAddress = $baseAddress + $relativePingAddress - 0x1000
	Local $pingBuffer = DllStructCreate('dword')
	Local $result = SafeDllCall13($kernelHandle, 'int', 'ReadProcessMemory', 'int', GetProcessHandle(), 'ptr', $pingAddress, 'ptr', DllStructGetPtr($pingBuffer), 'int', DllStructGetSize($pingBuffer), 'int', 0)
	Return DllStructGetData($pingBuffer, 1)
EndFunc
```

This function already returns the correct results. So why go further ? Well, at the next update, this function will break, because the adress will be different.
So if you don't want to do the same job at every update, you need to go a bit deeper.

### Second step

In order to have a robust address, we need to anchor it to something in the code that we will find no matter the game's version.
For that, we will use the Pattern system of GWA2.
The idea is simple :
1- We find the address from CheatEngine inside Ghidra.
2- We then need to find bytes that are fixed (not depending on a variable/function value or position) and robust (not changing with updates) and that allow us to find the address we are interested in.

Functions using our variable :
```
address		variable		references		functions
00ed9ea8	DAT_00ed9ea8	XREF[3]:		FUN_0077b950:0077b982 (W) ,
											FUN_0077b9b0:0077b9b0 (R) ,
											FUN_0077ba30:0077bab4 (W)
```

Functions using that function 2 :
```
address		memory				instruction					function_name	references		functions
															FUN_0077b9b0	XREF[16]:		FUN_00776510:00776513 (c) ,
																							FUN_00776540:00776546 (c) ,
																							FUN_0077c180:0077c203 (c) ,
																							FUN_0077c180:0077c24d (c) ,
																							FUN_0077c330:0077c357 (c) ,
																							FUN_00783a50:00783a6c (c) ,
																							FUN_007879e0:00788020 (c) ,
																							FUN_0078b440:0078b497 (c) ,
																							FUN_0078b520:0078b570 (c) ,
																							FUN_0078b520:0078b5d8 (c) ,
																							FUN_0078d2a0:0078d2e6 (c) ,
																							FUN_0078d740:0078d750 (c) ,
																							FUN_0078fa00:0078fef8 (c) ,
																							FUN_00790bd0:00790cb2 (c) ,
																							FUN_00791780:007917b5 (c) ,
																							FUN_007935f0:0079367c (c)
0077b9b0	a1 a8 9e ed 00		MOV EAX,[DAT_00ed9ea8 ]
0077b9b5	c3					RET
```

Nice function using that function 2 :
```
															FUN_00776510	XREF[9]:		FUN_007eab20:007eac39 (c) ,
																							FUN_007eac50:007ead4f (c) ,
																							FUN_007eadc0:007eae8a (c) ,
																							FUN_007eaea0:007eaf2d (c) ,
																							FUN_007eaea0:007eaff1 (c) ,
																							FUN_007eba10:007ebb09 (c) ,
																							FUN_007ec2a0:007ec436 (c) ,
																							FUN_007ec450:007ec4c3 (c) ,
																							FUN_007ec450:007ec548 (c)
00776510	55					PUSH EBP
00776511	8b ec				MOV EBP ,ESP
00776513	e8 98 54 00 00		CALL FUN_0077b9b0											undefined FUN_0077b9b0()
00776518	85 c0				TEST EAX ,EAX
0077651a	74 17				JZ LAB_00776533
0077651c	ff 75 08			PUSH dword ptr [EBP  + Stack [0x4 ]]
0077651f	e8 4c 15 02 00		CALL FUN_00797a70											undefined FUN_00797a70()
00776524	83 c4 04			ADD ESP ,0x4
00776527	85 c0				TEST EAX ,EAX
00776529	74 08				JZ LAB_00776533
0077652b	8b c8				MOV ECX ,EAX
0077652d	5d					POP EBP
0077652e	e9 0d 72 01 00		JMP FUN_0078d740											undefined FUN_0078d740()
															LAB_00776533	XREF[2]:		0077651a (j) ,  00776529 (j)
00776533	5d					POP                     EBP
00776534	c3					RET
```
To choose the pattern, avoid CALLs, avoid variables and functions.



### Result

Once we have done all of those steps, everything comes together :

1. The robust, fixed, closest pattern we found in a function calling a function using our variable:
```
	_('ScanInstanceInfo:')
	AddPatternToInjection('85c07417ff7508e8')
```

2. The offset from this pattern in order to end exactly on the address to the function that uses our variable:
```
	Local $addressScanInstanceInfo = GetScannedAddress('ScanInstanceInfo', -0x04)
```

3. We can read the address from that E8 call, skipping the E8 call instruction, and we can print the memory at that location, to make sure we end where we want to.
```
	; Skipping the E8 call instruction
	Local $relativeAddress = MemoryRead($addressScanInstanceInfo + 0x01)
	Notice('Relative address only:' & Hex($relativeAddress, 8))
```

4. Build the absolute address : the address provided in a CALL is relative, and it's relative to the NEXT instruction.
So we need :
- our original address : $addressScanInstanceInfo
- our relative address present in CALL : $relativeAddress
- the offset to jump to the next instruction : 0x05 because there are 5 bytes (e8 98 54 00 00)
```
	Local $absoluteAddress = $addressScanInstanceInfo + $relativeAddress + 0x05
	$instanceInfoPtr = MemoryRead($absoluteAddress + 0x01, 'dword')
```