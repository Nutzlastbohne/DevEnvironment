if ((pwd).Path.Contains("ConEmuPack")) {
	# only set Path to $HOME, if current path is the ConEmu-Directory. Thereby allowing 'Open Console Here' to function properly
	Set-Location $HOME
}

# Set Window and Buffer-Size
$ui = (Get-Host).UI.RawUI
$ui.WindowTitle = "conFoo"
$size = $ui.BufferSize
$size.width=220
$size.height=10000
$ui.BufferSize = $size
$size = $ui.WindowSize
$size.width=220
$size.height=40
$ui.WindowSize = $size

$global:message = ""

function appendMessage {
	$global:message += "$args`n"
}

######################################### Aliases ######################################### 
appendMessage("--- add aliases ---")
Set-Alias np "D:\Programme\Notepad++\notepad++.exe"
Set-Alias edit np
Set-Alias ll ls
Set-Alias which Get-Command

######################################### Functions ######################################### 
appendMessage("--- add functions ---")
$oldErrorActionPreferente = $ErrorActionPreference
$ErrorActionPreference = 'stop'								# All exceptions will be critical and step into the catch-block

appendMessage("`t overwerite windows-style 'man' with linux style 'man'")
function linuxStyleMan {
	Get-Help "$args" -full | less							# windows default pager is lame... use less
}

Set-Alias -Name man -Value linuxStyleMan -Option AllScope	# overwrite default 'man'

appendMessage("`t add jbcli - starts jboss console and renames current shell")
function jbcli {
	$ui.WindowTitle="JB-CLI"
	C:\Dev\server\jboss-as-7.1.3.Final\bin\jboss-cli.bat
}


appendMessage("`t testFiles - given a list of files, checks for existence")
function testFiles {
	foreach ($i in $args) { 
		if (Test-Path $i) { 
			echo `n+$i
		} else {
			echo `n-$i
		}
	}
}

######################################### ConEmu
# get all instances of ConEmu64
function getEmu {
	gwmi win32_process -f "name='ConEmu64.exe'"
}

# for debugging: pretty print for ConEmu Instances with handle and priority
function showEmuPrio {
	getEmu | Format-Table name, priority, Handle -AutoSize
}

# if emu found, set priority to normal
if ((getEmu) -ne $NULL){
	@(getEmu) | foreach {$_.setPriority(32)}				# set priority of each instance to 'Normal'
}

######################################### Git Stuff
Try {
	appendMessage("- initializing git tooling -")
	$GIT_PATH = @(which git)[0]	# in case /cmd and /bin are listed => use first entry
	$GIT_HOME = (get-item $GIT_PATH.Definition).Directory.Parent.FullName
	
	# Set-Alias gitk "$GIT_HOME\cmd\gitk.cmd"					# in case /cmd is not part of $PATH, link gitk manually
	
	appendMessage("`tadd gitg - git staging gui")
	function gitg {
		start $GIT_HOME\bin\wish.exe "$GIT_HOME\libexec\git-core\git-gui"
	}

	appendMessage("`tadd gdiff - git difftool -y")
	function gdiff() {
		git difftool -y @args
	}
	
	appendMessage("`tadd gmerge - git mergetool -y")
	function gmerge() {
		git mergetool -y @args
	}
} Catch [System.Management.Automation.CommandNotFoundException] {
	appendMessage("`tGit doesnt seem to be installed - skipping related functions")
}

######################################### Load additional scripts ######################################### 

# Load posh-git example profile
. "$HOME\git\posh-git\profile.example.ps1"

######################################### Cleanup ######################################### 
# clear screen after all this mess
Clear-Host
appendMessage("--- done ---")
appendMessage("")

$ErrorActionPreference = $oldErrorActionPreferente 

if ( @(gwmi win32_process -f "name='powershell.exe'").length -eq 1 ) {		# only print debug stuff if first powershell-instance
	Write-Host -fore Cyan $global:message
} else {
	Clear-Host
}