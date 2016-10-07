Param(
	[String]$action,
	[String]$status
)

foreach ($i in $(git status --porcelain | grep -E "$status" | cut -b4-)){
		powershell $action $i
}



foreach ($i in $(git status --porcelain | grep -E "XX" | cut -b4-)){git rm }