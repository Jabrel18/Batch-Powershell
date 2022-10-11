

$list = Get-clipboard

# WHO is logged on these Machines with PING
$Totalcount = 0
$Count = 0
Foreach($l in $list){
	$Totalcount = $Totalcount + 1
	$compname = "";$compname = $l.ToUpper().Replace(" ","")
		$ping = "";$Reply = "";$PingAddress = "";$PingStatus = "";$strCSName = "";$username = ""
	#Simple Ping test
		$ping = new-object System.Net.Networkinformation.Ping;$reply = $ping.Send($compname,30,[byte]1);$pingstatus = $reply.status;$pingaddress = $reply.Address
		
		
	If ($pingstatus -eq "Success") {
	#$Count = $Count + 1
	$strCSName = (get-wmiobject -computer $compname -class win32_operatingsystem).CSName
	$username = (get-wmiobject -computer $compname -class win32_computersystem).username
}
	Write-Host "$compname  $TotalCount   $Pingstatus     -     $strcsname     -      $Username     $count"
}



# WHO is logged on these Machines without PING
$Count = 0
Foreach($l in $list){
	$Count = $Count + 1
	$compname = "";$compname = $l.ToUpper().Replace(" ","")
	$strCSName = (get-wmiobject -computer $compname -class win32_operatingsystem).CSName
	$username = (get-wmiobject -computer $compname -class win32_computersystem).username
	Write-Host "$compname   $Pingstatus     -     $strcsname     -      $Username     $count"
}

