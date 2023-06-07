Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File ""C:\Users\Admin\Desktop\PowerShell\progetto.ps1""", 0
Set objShell = Nothing