if ((pwd).Path.Contains("ConEmuPack")) {
	# only set Path to $HOME, if current path is the ConEmu-Directory. Thereby allowing 'Open Console Here' to function properly
	Set-Location $HOME
}

# Set Window and Buffer-Size
$ui = (Get-Host).UI.RawUI
$ui.WindowTitle = "conFoo"
$size = $ui.BufferSize
$size.width=200
$size.height=10000
$ui.BufferSize = $size
$size = $ui.WindowSize
$size.width=200
$size.height=40
$ui.WindowSize = $size

$global:message = ""

function appendMessage {
	$global:message += "$args`n"
}

## variables ##
$NOTEPAD_HOME = "C:\Tools\Notepad++\notepad++.exe"
$SUBLIME_HOME = "C:\Tools\Sublime3\sublime_text.exe"
$GIT_PATH = @(Get-Command git)[0]	# in case /cmd and /bin are listed => use first entry
$GIT_HOME = (get-item $GIT_PATH.Definition).Directory.Parent.FullName
$MONGO_REPO = "C:\Dev\db_repo"
$JBOSS_HOME = "C:\Dev\server\jboss-eap-6.2"

## 'ssh-copy-id' - copy own ssh identity to server to skip "enter pw" query
# usage: ssh-copy-id user@targetServer
# e.g. ssh-copy-id vagrant@192.168.56.52
function ssh-copy-id {cat ~/.ssh/id_rsa.pub | ssh $args "cat >> ~/.ssh/authorized_keys"}

## docker relevant ##
# depcrecated since docker machine
#$env:DOCKER_HOST = "tcp://192.168.59.103:2376"
#$env:DOCKER_CERT_PATH = "$env:USERPROFILE\.boot2docker\certs\boot2docker-vm"
#$env:DOCKER_TLS_VERIFY = 1
function nyan {docker run --rm -it supertest2014/nyan}
function docker-pwd{(pwd).Path | tr '\\' '/' | cut -b 3- | xargs echo /c | tr -d "[:space:]"} # returns the current path in a format as it would inside boot2docker

function docker-compose-old {
	# get current path and make it linux compliant (replace '\' with '/' and 'c:' with '/c'. 'echo' adds an unneded space which must be trimmed at the end)
	docker run --rm -v "$(docker-pwd):/app" -v /var/run/docker.sock:/var/run/docker.sock dduportal/docker-compose:latest $args
}

function docker-python {
	# docker run -it --rm --name my-running-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp python:2 python your-daemon-or-script.py
	docker run -it --rm --name pyContainer -v "$(docker-pwd):/app" -w /app python:2 python $args
}

## vagrant relevant
Set-Alias vg vagrant

Set-Alias dc docker-compose
Set-Alias dm docker-machine
Set-Alias eval Invoke-Expression

function export {
    $cutArgs = $args | tr '=' '\n'
    $varName = $cutArgs[0]
    $varValue = $cutArgs[1]
    Write-Host 'Set '$varName':'$varValue
    [Environment]::SetEnvironmentVariable($varName, $varValue, "User")
}

function envdock {
    # lists docker environment vars as valid windows "export" statements
    Write-Host @(dm env $args | grep -e "^[^#]" | sed "s/export /\$\env\:/g" | tr '\r' ';' | tr -d '\n')
}

######################################### ENV_VARS ########################################
#appendMessage("--- add env_vars ---")
#$env:MVN_DEFAULT="$HOME\.m2\settings.xml"

######################################### Aliases #########################################
appendMessage("--- add aliases & functions ---")
appendMessage("`t edit FILE - open FILE with Notepad")
Set-Alias edit $SUBLIME_HOME
appendMessage("`t find - Linux style 'find'")
Set-Alias -Name find -Value $GIT_HOME\usr\bin\find.exe -Option AllScope	# overwrite windows 'find' with Linux derivative
appendMessage("`t rm - Linux style 'rm'")
Set-Alias -Name rm -Value $GIT_HOME\usr\bin\rm.exe -Option AllScope	# overwrite windows 'rm' with Linux derivative
appendMessage("`t sort - Linux style 'sort'")
Set-Alias -Name srt -Value $GIT_HOME\usr\bin\sort.exe -Option AllScope	# linux sort ('sort' is reserved for windows sort)
appendMessage("`t ll - alias for 'ls'")
Set-Alias ll ls
appendMessage("`t np|vi FILE - alias for 'edit'")
Set-Alias np edit
Set-Alias vi edit

######################################### Functions #########################################
$oldErrorActionPreferente = $ErrorActionPreference
$ErrorActionPreference = 'stop'								# All exceptions will be critical and step into the catch-block

appendMessage("`t jbcli - starts jboss console inside the current shell and renames it")
function jbcli {
	$ui.WindowTitle="JB-CLI"
	start $JBOSS_HOME\bin\jboss-cli.bat
}

appendMessage("`t man [COMMAND] - linux style 'man'")
function linuxStyleMan {Get-Help "$args" -full | less}							# windows default pager is lame... use less
Set-Alias -Name man -Value linuxStyleMan -Option AllScope				# get full windows help within pager

appendMessage("`t help [COMMAND] - Get onlinehelp")
function helpOnline {Get-Help "$args" -Online}
Set-Alias -Name help -Value helpOnline -Option AllScope					# open help web-site

appendMessage("`t rc STRING - rename console")
function rc {$ui.WindowTitle=$args}

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
function vim {bash $GIT_HOME/bin/vim @args}

function whichFctn {Get-Command "$args" | Format-Table -AutoSize DisplayName, Path, CommandType}

appendMessage("`t which COMMAND - alias for 'Get-Command'")
Set-Alias -Name which -Value whichFctn -Option AllScope

appendMessage("`t ssc X - create new console for ssh connection to server with alias X")
function ssc {
    ssh $args -new_console:t:$args
}

appendMessage("`t ssv - ssh to vagrant container")
function ssv {
    ssh vagrant@192.168.56.52
}

######################################### Maven Stuff #########################################

appendMessage("- add maven tooling -")
appendMessage("`t mvn-ci [OPTIONS] - run maven clean install in failFast-Mode without tests")
function mvn-ci {mvn -ff clean install -DskipTests @args}

appendMessage("`t mvn-cit [OPTIONS] - like mvn-ci, but with 8 Threads")
function mvn-cit {mvn -T 8 -ff clean install -DskipTests @args}

######################################### Mongoo #########################################

appendMessage("`t initMongo - start mongo with a fresh database")
function initMongo {
	$ui.WindowTitle="mongo"
	rmdir $MONGO_REPO
	mkdir $MONGO_REPO
	mongod --dbpath=$MONGO_REPO
}

######################################### Git Stuff #########################################
Try {
	appendMessage("- add git tooling -")
	
	Set-Alias gitk "$GIT_HOME\cmd\gitk.exe"					# in case /cmd is not part of $PATH, link gitk manually

	appendMessage("`t gdiff [COMMITS] [FILES] - git difftool -y")
	function gdiff() {git difftool -y @args	}
	
	appendMessage("`t gitg - git staging gui")
	function gitg {start $GIT_HOME\mingw64\bin\wish.exe "$GIT_HOME\mingw64\libexec\git-core\git-gui"}
	
	appendMessage("`t gmerge [FILES] - git mergetool -y")
	function gmerge() {git mergetool -y @args}

	appendMessage("`t bfg  - repo cleaner")
	function bfg() {java -jar "C:\Dev\bfg-1.12.3.jar" @args}

} Catch [System.Management.Automation.CommandNotFoundException] {
	appendMessage("`tGit doesnt seem to be installed - skipping related functions")
}

######################################### Load additional scripts ######################################### 
appendMessage("--- add shell extensions ---")
appendMessage("`tadd posh-git for great justice!")
# Load posh-git example profile
. "$env:USERPROFILE\\git\posh-git\profile.example.ps1"

######################################### ConEmu #########################################
# Set priority of each instance to 'normal'. May increase performance because it starts with 'low'
# get all instances of ConEmu64
function getEmu {gwmi win32_process -f "name='ConEmu64.exe'"}

# for debugging: pretty print for ConEmu Instances with handle and priority
function showEmuPrio {getEmu | Format-Table name, priority, Handle -AutoSize}

# if emu found, set priority to normal
if ((getEmu) -ne $NULL){@(getEmu) | foreach {$_.setPriority(32)}}

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