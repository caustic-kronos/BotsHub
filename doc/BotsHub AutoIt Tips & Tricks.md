# AutoIt Coding Tricks, Tools & Hidden Gems

A concise cheat sheet of powerful functions, techniques, and utilities in AutoIt for efficient scripting.

---

## ⚛️ Execution Flow & Scheduling

* `AdlibRegister()` / `AdlibUnRegister()` → Simulate multithreading, e.g. background checks.
* `OnAutoItExitRegister()` → Clean-up actions on script exit.
* `TimerInit()` / `TimerDiff()` → Measure execution time, delay logic.

## 🧠 Dynamic Behavior & Reflection

* `Call('FuncName', ...)` → Run user-defined functions dynamically.
* `Execute('code')` → Run strings as code (dangerous, but powerful).
* `SafeEval('varName')` → Get value of a variable by name.
* `Assign('varName', $value)` → Set variable dynamically.

## 🛠️ Process, File & Resource Handling

* `Run()`, `RunWait()` → Launch and manage processes.
* `ShellExecute()` → Open files, folders, or URLs.
* `StdioRead()` / `StdioWrite()` → Communicate with console-based programs.
* `FileOpen()`, `FileReadLine()` → Sequential file processing.
* `FileFindFirstFile()` → Efficient directory iteration.

## 🧠 System Info & Diagnostics

* `@error`, `@extended` → Handle errors robustly.
* `@ScriptName`, `@ScriptLineNumber`, `@ScriptDir` → Debugging context.
* `ProcessExists()`, `WinExists()` → Monitor other processes or windows.
* `DllCall()` / `DllStructCreate()` → Use system DLLs, memory manipulation.

## 🔍 Debugging & Tracing

* `ConsoleWrite()` → Print debug output to SciTE.
* `AutoItSetOption('TrayIconDebug', 1)` → Enables tray icon debugging.
* `#AutoIt3Wrapper_Run_Debug_Mode=Y` → Debug mode directive.
* `HotKeySet()` → Register emergency stop or debugging shortcuts.

## 🔹 GUI & Input Control

* `GUICtrlCreateDummy()` → Create fake control for triggering events.
* `ControlSend()`, `ControlClick()` → Send input to background windows.
* `MouseMove()` / `PixelGetColor()` → Botting, automation, or detection tools.

## 🧹 Memory & Data Structures

* `MemoryRead()`, `MemoryWrite()` → Game hacking, memory patching.
* `MapCreate()` / `MapAdd()` / `MapExists()` → Fast key-value mapping.
* `DllStructGetData()` / `DllStructSetData()` → Binary or pointer manipulation.
* `BinaryToString()`, `StringToBinary()` → Useful for encoding/decoding.

### 📦 DllStruct Valid Types Reference

**Integer Types (Signed)**  
* `char` → 1 byte  
* `short` → 2 bytes  
* `int` → 4 bytes  
* `int64` → 8 bytes  

**Integer Types (Unsigned)**  
* `byte` → 1 byte  
* `ushort` → 2 bytes  
* `uint` → 4 bytes  
* `uint64` → 8 bytes  
* `ulong` → Alias of `uint`  

**Floating Point**  
* `float` → 4 bytes  
* `double` → 8 bytes  

**Boolean**  
* `bool` → 1 byte  

**Pointer-Sized (architecture dependent)**  
* `ptr`  
* `handle`  
* `hwnd`  
* `lparam`  
* `wparam`  
* `hresult`  

**String Types**  
* `str` → ANSI string  
* `wstr` → Unicode string  
* `char[n]` → Fixed-length ANSI buffer  
* `wchar[n]` → Fixed-length UTF-16 buffer  

**Alignment Control**  
* `align 1`  
* `align 2`  
* `align 4`  
* `align 8`

Order structures by decreasing alignement to reduce their size.

**Common WinAPI Aliases**  
* `dword` → `uint`  
* `word` → `ushort`  
* `long` → `int`

**Sub structure**
* `int int1;struct inStruct;int int2;int int3;endstruct;int int4`

> Not supported: `uint32`, `int32`, `uint16`, `int16`, `size_t`, `void`

## 🚀 Performance & Compilation

* `#pragma compile(Optimize, True)` → Improves execution speed.
* `#include-once` → Avoid duplicate includes.
* `#AutoIt3Wrapper_UseX64=y` → Compile for 64-bit compatibility.
* `Exit(n)` → Use non-zero code to indicate errors.

## ✨ Coding Style & Helpers

* Use `Boolean` returns for chaining: `If DoThis() And DoThat()`
* Group common timers/states via `Global` associative maps.
* Stub logging system with verbosity levels and `ConsoleWrite()`.

---

Keep this as a reference when building or reviewing your next AutoIt project. These tools can make a huge difference in maintainability, flexibility, and speed.