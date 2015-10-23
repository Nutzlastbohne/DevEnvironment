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

## global constants ##
$NOTEPAD_HOME = "C:\Tools\Notepad++\notepad++.exe"
$JBOSS_HOME = "C:\Dev\server\jboss-eap-6.2"
$GIT_PATH = @(Get-Command git)[0]	# in case /cmd and /bin are listed => use first entry
$GIT_HOME = (get-item $GIT_PATH.Definition).Directory.Parent.FullName

######################################### ENV_VARS ######################################### 
#appendMessage("--- add env_vars ---")
#$env:MVN_DEFAULT="$HOME\.m2\settings.xml"

######################################### Aliases ######################################### 
appendMessage("--- add aliases & functions ---")
appendMessage("`t edit FILE - open FILE with Notepad")
Set-Alias edit $NOTEPAD_HOME
appendMessage("`t find - Linux style 'find'")
Set-Alias -Name find -Value $GIT_HOME\bin\find.exe -Option AllScope	# overwrite windows 'find' with Linux derivative
#appendMessage("`t ll - alias for 'ls'")
Set-Alias ll ls
appendMessage("`t np FILE - alias for 'edit'")
Set-Alias np edit
appendMessage("`t which COMMAND - alias for 'Get-Command'")
Set-Alias which Get-Command


######################################### Functions ######################################### 
$oldErrorActionPreferente = $ErrorActionPreference
$ErrorActionPreference = 'stop'								# All exceptions will be critical and step into the catch-block

appendMessage("`t jbcli - starts jboss console inside the current shell and renames it")
function jbcli {
	$ui.WindowTitle="JB-CLI"
	start $JBOSS_HOME\bin\jboss-cli.bat
}

appendMessage("`t man COMMAND - linux style 'man'")
function linuxStyleMan {
	Get-Help "$args" -full | less							# windows default pager is lame... use less
}

Set-Alias -Name man -Value linuxStyleMan -Option AllScope				# overwrite default 'man'

appendMessage("`t rc STRING - rename console")
function rc {
	$ui.WindowTitle=$args
}

appendMessage("`t testFiles FILES - prints out which of the given FILES exist/don't exist")
function testFiles {
	foreach ($i in $args) { 
		if (Test-Path $i) { 
			echo `n+$i
		} else {
			echo `n-$i
		}
	}
}

appendMessage("`t vim FILE - you know what that is...")
function vim {
	bash $GIT_HOME/bin/vim @args
}

######################################### Maven Stuff

appendMessage("- add maven tooling -")
appendMessage("`t mvn-ci [OPTIONS] - run maven clean install in failFast-Mode without tests")
function mvn-ci {
	mvn -ff clean install -DskipTests @args
}

appendMessage("`t mvn-cit [OPTIONS] - like mvn-ci, but with 8 Threads")
function mvn-cit {
	mvn -T 8 -ff clean install -DskipTests @args
}


######################################### Git Stuff
Try {
	appendMessage("- add git tooling -")
	
	Set-Alias gitk "$GIT_HOME\cmd\gitk.cmd"					# in case /cmd is not part of $PATH, link gitk manually

	appendMessage("`t gdiff [COMMITS] [FILES] - git difftool -y")
	function gdiff() {
		git difftool -y @args
	}
	
	appendMessage("`t gitg - git staging gui")
	function gitg {
		start $GIT_HOME\bin\wish.exe "$GIT_HOME\libexec\git-core\git-gui"
	}
	
	appendMessage("`t gmerge [FILES] - git mergetool -y")
	function gmerge() {
		git mergetool -y @args
	}
} Catch [System.Management.Automation.CommandNotFoundException] {
	appendMessage("`tGit doesnt seem to be installed - skipping related functions")
}

######################################### Load additional scripts ######################################### 
appendMessage("--- add shell extensions ---")
appendMessage("`tadd posh-git for great justice!")
# Load posh-git example profile
. "$HOME\git\posh-git\profile.example.ps1"

######################################### ConEmu
# Set priority of each instance to 'normal'. May increase performance because it starts with 'low'
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