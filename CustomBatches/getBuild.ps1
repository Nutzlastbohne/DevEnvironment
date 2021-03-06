#
# getBuild copies Client and Server Build files to the target folder, with optional handling of files already present.
# If no parameters are given, both client (win) and server are copied and files with identical names are preserverd.
#


####
#	! ATTENTION !
# The ear file may not be renamed! Otherwise it won't be usable for the Client.
# If version stamping should be implemented, a new folder needs to be created.
# (e.g. copy ear to ZibServerExport, overwrite possible confilcts and also create a folder with the suffix in which the ear is copied too)
####
#
# build and platform parameters should be switches, too
#

Param(
    [String[]]$p="win32",       #platform
	[String]$suffix="",			#instead of the date, use this string as a suffix. Practical for version stamping
	[String]$source="",
	[String]$target="",
    [Switch]$f,                 #force overwrite
    [Switch]$k,                 #keepOld
	[Switch]$forceDate,			#adds date to the given suffix, which would normally be ignored
	[Switch]$c,					#client
	[Switch]$s,					#server
	[Switch]$win,				#windows build
	[Switch]$linux				#linux build
)

$SysId = 0					#0 = win, 1 = linux			#deprecated
$BuildType = 0 				#0 = client, 1 = server		#deprecated
$ARCH_x86 = "x86"
$ARCH_x64 = "x86_x64"
$WINDOWMGR_WIN = "win32"
$WINDOWMGR_LINUX = "gtk"
$server_sourcePath = "C:\Users\empolis\git\ZIB\maven\zib.client.parent\zibRepository\target\products\"
$client_sourcePath = "C:\Users\empolis\git\ZIB\maven\zib.server\de.dand.zib\target\"
$server_sourceFile = "de.dand.zib.ear"
$client_sourceFile = "de.dand.zib.client.zib.product-" #client build convention: de.dand.zib.client.zib.product-PLATFORM.WINDOWMGR.ARCH.zip
$server_targetPath = "C:\Dev\ZibServerExport\"
$client_targetPath = "C:\Dev\ZibClientExport\"
$server_targetFile = "de.dand.zib_DATE.ear"
$client_targetFile = "zib_client_DATE.zip"

#Convenienceparams for debugging
$build = ""
$platform = ""

### check params ###
foreach($i in $p){
    if( !(($p -eq "win32") -or ($p -eq "linux")) ){
        Write-Error "Unknown Platform: " $i
        exit
    }
}


### Init ###
if($p -eq "win32" -or ($p))
    {$SysId=0}
else
    {$SysId=1}

if($win) $platform = "win"
if($linux) $platform = "linux"
if($win -and $linux) $platform = "win and linux"

if($c) $build = "client"
if($s) $build = "server"
if($c -and $s) $build = "client and server"

## functions ###
function copyBuild{
    Write-Host "-=== Start Copy ===-"
    Write-Host "####################################################################"
    Write-Host "-= Params build: $build, platform: $pl, force overwrite: $f, keep: $k"
    Write-Host "####################################################################"

    foreach($i in $build){
        Write-Host "-= Copy " $i " Build"
        if($i -eq "client"){
            $source = $client_sourcePath + (getBuildName(0))
            $target = $client_targetPath + (generateFileName(0))
        } elseif ($i -eq "server"){
            $source = $server_sourcePath + (getBuildName(1))
            $target = $server_targetPath + (generateFileName(1))
        }
        
        Write-Host "-= Source: " $source
        Write-Host "-= Target: " $target 
        if($f){
            Copy-Item $source -Force -destination $target
        }
        else{
            Copy-Item $source -destination $target
        }
    }
    return $True
}

######################################### Continue Rebuild here #########################################

function getBuildName($buildType){
    if($buildType -eq 0){
        $buildName = ($client_sourceFile)+$p+"."+$WINDOWMGR[$SysId]+"."+$ARCH[$SysId]+".zip"
    } elseif($buildType -eq 1){
        $buildName = $sourceFile[1]
    }
    return $buildName
}

# generates a file name based on 
function generateFileName($buildType){
    $index = 1
    $fileType = (".zip", ".ear")[$buildType]
    if($buildType -eq 0){
        $newname = ($targetFile[$buildType] -split "DATE")[0]+(Get-Date -uformat %Y%m%d)
    } else {
        $newname = ($targetFile[$buildType] -split "_DATE")[0]
    }
    
    if( (Test-Path ($targetPath[$buildType]+$newname+$fileType)) -and !($f) -AND $k -and ($buildType -eq 1)){
        Write-Host -Foregroundcolor RED "File " ($newname)$fileType " already exists in target directory. server build copy currently doesn't support -k"
        Write-Host
        exit;
    }
    
    #if file exists and "don't force" -> rename
    if( (Test-Path ($targetPath[$buildType]+$newname+$fileType)) -and !($f) ){
        Write-Host -Foregroundcolor RED "File " $newname".zip" " already exists in target directory and -f switch is false -> Skip Copy"
        Write-Host
        exit;
    } elseif ($f -and !$k){
       Write-Host -Foregroundcolor YELLOW "File " $newname $fileType " already exists in target directory and and will be overwritten"
    }
    
    #generate unused filename if f = false
    $suffix += $fileType
    while((Test-Path ($targetPath[$buildType]+$newname+$suffix+$fileType)) -and !($f)){
        $suffix = "_" + $index + $fileType
        $index++
    }
    
    return ($newname+$suffix)
}

### Start ###
Write-Host 
if (copyBuild){
    Write-Host -Foregroundcolor GREEN "-=== Copy Successful ===-"
} else {
    Write-Host -Foregroundcolor RED "-=== Copy Failed for some reason. And i'm not going to tell you Why! MUHAHAHAHA!!! ';..;' ===-"
}
Write-Host 