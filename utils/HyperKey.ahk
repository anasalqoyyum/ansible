#Requires AutoHotkey v2.0
; recommended for performance and compatibility with future autohotkey releases.
#UseHook
#SingleInstance force

InstallKeybdHook()

SendMode "Input"

;; deactivate capslock completely
SetCapslockState("AlwaysOff")

global CapslockIsDown := false

SetTimer(HandleCapslock, 50)

HandleCapslock() {
    global CapslockIsDown

    if (!CapslockIsDown && GetKeyState("CapsLock", "P")) {
        CapslockIsDown := true
        Send("{Ctrl DownTemp}{Shift DownTemp}{Alt DownTemp}{LWin DownTemp}")
    } else if (CapslockIsDown && !GetKeyState("CapsLock", "P")) {
        CapslockIsDown := false
        Send("{Ctrl Up}{Shift Up}{Alt Up}{LWin Up}")

        if (A_PriorKey == "CapsLock") {
            Send("{Esc}")
        }
    }
}
