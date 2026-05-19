#!/usr/bin/env sh
powershell.exe -nologo -noprofile Get-Clipboard | sed 's/\r$//'
