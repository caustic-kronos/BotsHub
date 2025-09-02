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
* `Eval('varName')` → Get value of a variable by name.
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

Happy scripting!
