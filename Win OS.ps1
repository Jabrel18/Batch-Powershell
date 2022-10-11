

$list = Get-clipboard

# What Operating SYstem ???
Foreach($l in $list){$compname = "";$compname = $l.ToUpper().Replace(" ","");(Write-host -BackgroundColor Black -ForegroundColor Green $compname   (get-wmiobject -computer $compname -class win32_operatingsystem).Caption)}


### VEEY VERY SIMPLE PING
$Count = 0
Foreach($l in $list){
	$Count = $Count + 1
	$compname = "";$compname = $l.Replace(" ","").ToUpper()
	#(Get-ADComputer $compname -Properties *).LastLogonDate.ToString("MM-dd-yyyy")
	$ping = "";$reply = "";$pingstatus = "";$pingaddress = ""
	$ping = new-object System.Net.Networkinformation.Ping;$reply = $ping.Send($compname,30,[byte]1);$pingstatus = $reply.status;$pingaddress = $reply.Address.IPAddressToString
	#write-host -backgroundcolor Black -foregroundcolor Yellow "$compname     -     $pingAddress     -     $pingstatus"
	If(-not($pingstatus -eq "Success")){Write-host -BackgroundColor Black -ForegroundColor Yellow "$compname    -    $PingStatus"}
	
	If($pingstatus -eq "Success"){(Write-host -BackgroundColor Black -ForegroundColor Green "$compname    -    $PingAddress    -    " (get-wmiobject -computer $compname -class win32_operatingsystem).Caption)}
}




# QUICK AD Last Logon
Foreach($l in $list){
	$compname = "";$compname = $l.Replace(" ","").ToUpper()
	$LastChanged = "";$LastChanged = (Get-ADComputer $compname -Properties *).LastLogonDate.ToString("MM-dd-yyyy")
	write-host -backgroundcolor Black -foregroundcolor Green "$compname   -   $LastChanged"
}

