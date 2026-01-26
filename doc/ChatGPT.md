# Project context:
- coding a bot for Guild Wars using AutoIt
- bot interacts with the game using:
* Memory scanning and pattern matching
* Injection of assembly routines, placed in memory using VirtualAllocEx
* Remote thread execution executed via CreateRemoteThread
* Memory reads/writes using DllCalls of ReadProcessMemory/WriteProcessMemory
- have been debugging game crashes by wrapping DllCalls and DllStructCreate in safe functions with error logs

# AutoIt work conventions for this project
- clear and descriptive variable names (e.g., processHandle, characterName, scanMemoryAddress)
- no AutoIt shorthand like hWnd, wParam, etc...
- no Hungarian notation ($iCounter, $sString, etc.)
- avoid short, cryptic names even if common in AutoIt community
- arrays should follow Java-style logic, not AutoIt conventions (no array count at index 0)