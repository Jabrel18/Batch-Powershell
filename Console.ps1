


$mask = "fe*"
$list = (Get-ADComputer -filter {Name -like $mask} -Properties * -searchbase $searchroot).Name | Sort-Object

$list = (Get-ADComputer * -Properties * -searchbase $searchroot) | where-object  | Sort-Object


ad.TexasChildrensHospital.org/Resource/Engineered Solutions/Website Kiosk Trackboard/Production/FE12-KSKEMRD10
	
	
	# GETTING WMI INFORMATION
	$primesw = [Diagnostics.Stopwatch]::StartNew()
	$hashcoll = "";$hashcoll = @();$Totalcount = 0;$WMIcount = 0m
foreach ($l in $list){

	#Region Clearing Variables
	#Clearing Data before next Name in List
		$compname = "";$Skip = "";$strUserName = "";$CompGroups = ""
		$strArchitecture = "";$strMACAddress = "";$strDHCPEnabled = "";$strCPUName = "";$strCPUSpeed = "";$hd1Model = "";$hd1Size = "";$hd1Freespace = "";$netlist = "";$netlist = "";$nic = ""
		$strCSDVersion = "";$strCSName = "";$strManufacturer = "";$strMemoryGB = "";$strModel = "";$strProductName = "";$strSerialNumber = "";$strCPUcount = "";$strCPUSpeed = ""
		$ArrMonManufacturerName = "";$ArrMonProductCodeID = "";$ArrMonSerialNumberID = "";$ArrMonUserFriendlyName = ""
		$MonMFG = "";$MonModel = "";$MonSerial = "";$MonFreindly = ""
		$Reply = "";$PingAddress = "";$PingStatus = "";$sp = ""
	#Finished Clearing Variables
	#Endregion
	
	$compname = $l.ToUpper().Replace(" ","")
	$TotalCount = $TotalCount + 1
	
	#Region Collecting AD Info
		$objComp = "";$objComp = (Get-ADComputer $compname -Properties *)
		$LastDate ="";$LastDate= $objComp.LastLogonDate.ToString("MM-dd-yyyy HH:mm:ss")
		$LastYear ="";$LastYear = $objComp.LastLogonDate.ToString("yyyy")
		$OU = "";$OU = ($objComp.CanonicalName).Replace("ad.TexasChildrensHospital.org/","").TrimEnd("/" + $compname)
		Write-Host;Write-Host -BackgroundColor DarkGreen -ForegroundColor White "$compname     $Lastyear     -  $TotalCount"
	#Endregion
	
if($compname -ne "B01-DIAGWOW001" -and
	$compname -ne "B01-DIAGWOW002" -and
	$compname -ne "B01-DIAGWOW003" -and
	$compname -ne "B01-DIAGIMAG025"
){

	#Region If Statement ($Lastyear -gt "2020")
		#If($Lastyear -gt "2020" -and $l -ne "WIN7UCCE129"){
		If($Lastyear -gt "2020"){
			#$WMICount = $WMICount + 1
			#Simple Ping test
				write-host -backgroundcolor Black -foregroundcolor Yellow  "Trying to Ping - $compname    #    $Totalcount"
				$ping = new-object System.Net.Networkinformation.Ping;$reply = $ping.Send($compname,30,[byte]1);$pingstatus = $reply.status;$pingaddress = $reply.Address
				write-host -backgroundcolor Black -foregroundcolor Yellow  "PingAddress - $PingAddress"
			Foreach($cg in $objcomp.MemberOf){$Global:CompGroups = $CompGroups + $cg.Replace(",","\").Replace("OU=","").Replace("LDAP://CN=","").Replace("CN=","").Replace("DC=","").Split("\")[0] + ";"}
			#Ping Return  - Timedout
			If ($pingstatus -eq "Timedout") {}	
			#Ping Return Status - Success
			If ($pingstatus -eq "Success") {$strCSName = (get-wmiobject -computer $compname -class win32_operatingsystem).CSName
				If ($compname -ne $strCSName){}
				If ($compname -eq $strCSName){
				
				#Region Collecting WMI Info
					Write-host -BackgroundColor Black -ForegroundColor Cyan $compname  -  Collecting WMI Info
					##OPERATING SYSTEM
						$memory = get-wmiobject -computer $compname -class win32_operatingsystem
						$strCSName = $memory.CSName;$strProductName = $memory.Caption;$strCSDVersion = $memory.CSDVersion;$strMemoryGB = $memory.TotalVisibleMemorySize/1000000;$strArchitecture = $memory.OSArchitecture
					#BIOS Information	
						$bios = get-wmiobject  -computer $compname -class win32_bios
						$strSerialNumber = $bios.SerialNumber 
                    #System Enclosure
                        $AssetTag = Get-WmiObject -computer $compname -class win32_SystemEnclosure
                        $strAssetTag = $AssetTag.SMBIOSAssetTag
					## COMPUTER SYSTEM$
						$comp = get-wmiobject -computer $compname -class win32_computersystem
						$strManufacturer = $comp.Manufacturer;$strModel = $comp.Model;$strUserName = $comp.UserName
					## MAC Address = IPAddress
						$netlist = get-wmiobject -computer $compname -class Win32_NetworkAdapterConfiguration
						foreach($nic in $netlist){If($nic.IPAddress -eq $PingAddress){$strMACAddress = $nic.MACAddress;$strDHCPEnabled = $nic.DHCPEnabled}}
					##CPU SPECIFICATIONS
						$cpuspecs = get-wmiobject -computer $compname -class win32_processor
						$strCPUcount = ($cpuspecs.DeviceID).Count;$strCPUName = $cpuspecs.Name
						If(-Not($strCPUcount -gt 1)){$strCPUSpeed = ($cpuspecs).MaxClockSpeed/1000};If($strCPUcount -gt 1){$strCPUSpeed = ($cpuspecs[0]).MaxClockSpeed/1000}
					#Collecting HardDrive Information
						$hd = get-wmiobject -class Win32_DiskDrive -computer $compname
						$lhd = get-wmiobject -class Win32_LogicalDisk -computer $compname
						If(-not(($hd.Count) -gt 1)){$hd1Model = $hd.Model};If(($hd.Count) -gt 1){$hd1Model = ($hd[0]).Model}
						If(-not(($lhd.Count) -gt 1)){$hd1Size = (([INT](($lhd).Size/1000000000)).ToString() + " GB");$hd1Freespace = (([INT](($lhd).Freespace/1000000000)).ToString() + " GB")}
						If(($lhd.Count) -gt 1){$hd1Size = (([INT](($lhd[0]).Size/1000000000)).ToString() + " GB");$hd1Freespace = (([INT](($lhd[0]).Freespace/1000000000)).ToString() + " GB")}
				#Endregion
				#>
				
				<#Region Collecting Monitor Logic
					$Monitors = get-wmiobject -class WmiMonitorID -computername $compname -namespace root\wmi
					foreach($m in $Monitors){
						Write-Host -BackgroundColor Black -ForegroundColor Magenta ([System.Text.Encoding]::ASCII.GetString($m.UserFriendlyName)).Replace("$([char]0x0000)","")
						$ArrMonManufacturerName = $ArrMonManufacturerName + ([System.Text.Encoding]::ASCII.GetString($m.ManufacturerName)).Replace("$([char]0x0000)","") + ";"
						$ArrMonProductCodeID = $ArrMonProductCodeID + ([System.Text.Encoding]::ASCII.GetString($m.ProductCodeID)).Replace("$([char]0x0000)","") + ";"
						$ArrMonSerialNumberID = $ArrMonSerialNumberID + ([System.Text.Encoding]::ASCII.GetString($m.SerialNumberID)).Replace("$([char]0x0000)","") + ";"
						$ArrMonUserFriendlyName = $ArrMonUserFriendlyName + ([System.Text.Encoding]::ASCII.GetString($m.UserFriendlyName)).Replace("$([char]0x0000)","") + ";"
					}#Ending Foreach ($m in $Monitors)
						$MonMFG = $ArrMonManufacturerName.Split(";")
						$MonModel = $ArrMonProductCodeID.Split(";")
						$MonSerial = $ArrMonSerialNumberID.Split(";")
						$MonFreindly = $ArrMonUserFriendlyName.Split(";")
				#Endregion
				#>

				<#Region Getting Spooler Status
					$sp = ""
					$sp = get-wmiobject -class win32_Service -computername "$compname" | where-object {$_.Name -like "*spooler*"}
						#Write-Host -BackgroundColor Black -ForegroundColor Yellow "ExitCode: " $sp.ExitCode
					Write-Host -BackgroundColor Black -ForegroundColor Yellow "Name: " $sp.Name
						#Write-Host -BackgroundColor Black -ForegroundColor Yellow "Process ID: " $sp.ProcessID
					Write-Host -BackgroundColor Black -ForegroundColor Yellow "StartMode: " $sp.StartMode
					Write-Host -BackgroundColor Black -ForegroundColor Yellow "State: " $sp.State
						#Write-Host -BackgroundColor Black -ForegroundColor Cyan "Status: " $sp.Status
				#Endregion
				#>
				
				} #Ending ($compname -eq $strCSName)	
			}# Ending If($Pingstatus -eq "Success")
		

		}#Ending If($Lastyear -eq 2020 or 2021)
	#Endregion		
	
		#Region Writing Hash
			$hashout = new-object System.Object
			$hashout | add-member NoteProperty TotalCount ($TotalCount)
			#$hashout | add-member NoteProperty WMICount ($WMICount)
			$hashout | add-member NoteProperty PingStatus ($pingstatus)
			$hashout | add-member NoteProperty ComputerName ($compname)
			$hashout | add-member NoteProperty Found ($strCSName)
			$hashout | add-member NoteProperty UserName ($strUserName)
			#$hashout | add-member NoteProperty SpoolerStart ($sp.StartMode)
			#$hashout | add-member NoteProperty SpoolerState ($sp.State)
			$hashout | add-member NoteProperty Manufacturer ($strManufacturer)
			$hashout | add-member NoteProperty Model ($strModel)
			$hashout | add-member NoteProperty FoundSerial ($strSerialNumber)
			$hashout | add-member NoteProperty AssetTag ($strAssetTag)
			$hashout | add-member NoteProperty DHCP ($strDHCPEnabled)
			$hashout | add-member NoteProperty IPAddress ($PingAddress)
			#$hashout | add-member NoteProperty MACAddress ($strMACAddress)
			$hashout | add-member NoteProperty Blank1 ""
			$hashout | add-member NoteProperty OperatingSystem ($strProductName)
			$hashout | add-member NoteProperty Architecture ($strArchitecture)
			#$hashout | add-member NoteProperty CPUCount ($strCPUcount)
			#$hashout | add-member NoteProperty CPUSpeed (($strCPUSpeed).ToString() + " GHZ")
			#$hashout | add-member NoteProperty CPUName ($strCPUName)
			#$hashout | add-member NoteProperty Memory ($strMemoryGB)
		# One Hard Disk Drive
			$hashout | add-member NoteProperty Blank2 ""
			#$hashout | add-member NoteProperty "HD-1-Model" ($hd1Model)
			#$hashout | add-member NoteProperty "HD-1-Size" ($hd1Size)
			$hashout | add-member NoteProperty "HD-1-Free" ($hd1Freespace)
		<# Monitors
			$hashout | add-member NoteProperty Blank3 ""
			$hashout | add-member NoteProperty Mon1-FriendlyName $MonFreindly[0] 
			$hashout | add-member NoteProperty Mon1-Serial $MonSerial[0]
			$hashout | add-member NoteProperty Mon2-FriendlyName $MonFreindly[1] 
			$hashout | add-member NoteProperty Mon2-Serial $MonSerial[1]
			$hashout | add-member NoteProperty Mon3-FriendlyName $MonFreindly[2] 
			$hashout | add-member NoteProperty Mon3-Serial $MonSerial[2]
			$hashout | add-member NoteProperty Mon4-FriendlyName $MonFreindly[3] 
			$hashout | add-member NoteProperty Mon4-Serial $MonSerial[3]
		#>	
		# AD Info
			$hashout | add-member NoteProperty Blank4 ""
			$hashout | add-member NoteProperty "LastLogonY" ($LastYear)
			$hashout | add-member NoteProperty "LastLogon" ($LastDate)
			$hashout | add-member NoteProperty "OU-Location" ($ou)			
			$hashout | add-member NoteProperty "ADGroups" ($Compgroups)			
			$hashcoll += $hashout
		#EndRegion

} # Ending ($compname -ne "B01-DIAGWOW001")
}#Ending foreach($l in $list)


	#Region Calculating Time
		#Stopwatch Times
		Write-host;Write-Host -BackgroundColor DarkMagenta -ForegroundColor Yellow Stopping the Timer
		$primesw.Stop()
		$Time = ($primesw.elapsed.ToString())
		If(($Time.Split(":")[-1]) -gt "00"){$timename = " Seconds"};If(($Time.Split(":")[-2]) -gt "00"){$timename = " Minutes"};If(($Time.Split(":")[-3]) -gt "00"){$timename = " Hours"}
		Write-Host -BackgroundColor DarkRed -ForegroundColor White ($primesw.elapsed.ToString() + "$TimeName")
	#Endregion	

	#Region Writing Data to File
		#$SDate = (Get-Date -Format "_yyyy-MM-dd.HHmmss")	
		$SDate = (Get-Date -Format "_yyyyMMdd.HHmmss")
#		$hashfile = "\\tcd6040n01\App_Packages\Regtools\Powershell.Scripts\!.Solutions\Imprivata\" + ($mask).ToUpper().Replace("*","") + "_WMI-Info.csv"
		$hashfile = "\\tccdav1b\global\ePlus\TCH Refresh\Refresh 2020\WMI-Info\" + ($mask).ToUpper().Replace("-*","") + "_WMI-Info.csv"
		$hashcoll | Export-Csv $hashfile -NoTypeInformation
		$hashcoll | Out-GridView -Title "WMI Results - $hashfile"
	#Endregion






##############################  BREAK  ###################################
Break			#####	###		#####	#####	#	#
Break			#	#	#  #	#		#	#	#  #
Break			#####	###		#####	#####	###
Break			#	#	#  #	#		#	#	#  #
Break			#####	#   #	#####	#	#	#	#
##############################  BREAK  ###################################




###############################################################################################################################################





	$Searchroot = "ou=Kiosk,ou=Clinical Workstations,ou=Departments,dc=ad,dc=texaschildrenshospital,dc=org"


# WHO is logged on these Machines
Foreach($l in $list){
	$compname = "";$compname = $l.ToUpper().Replace(" ","")
	$strCSName = (get-wmiobject -computer $compname -class win32_operatingsystem).CSName
	$username = (get-wmiobject -computer $compname -class win32_computersystem).username
	Write-Host "$compname     -     $strcsname     -      $Username"
}



$Count = 0
foreach($l in $list){
	if($Count -eq "4"){$one = "";$two = "";$three = "";$four = ""}
	$Count = $Count + 1
	if($Count -eq 1){$one = $l}
	if($Count -eq 2){$two = $l}
	if($Count -eq 3){$three = $l}
	if($Count -eq 4){$four = $l}
	if($Count -eq "4"){
		$Count = 0
		Write-Host "$three, $one $two, $four"
	}
}




foreach($l in $list){
if($l -like "*-ksk*" -and -not($l -like "*-trkopt*" -or $l -like "*-optime*" -or $l -like "*-trkftl*" -or $l -like "*-trkisafe*" -or $l -like "*-trkemon*" -or $l -like "*-trkstrk")){Write-Host "$l"}
}



foreach($l in $list){
if($l -like "*-ksk*" -and -not($l -like "*-QB*" -or $l -like "*-TRK*" -or $l -like "*-wlcm*" -or $l -like "*-kskemrd*" -or $l -like "*-ics*" -or $l -like "*-MYCHART*" -or $l -like "THP-*" -or $l -like "l*-*")){Write-Host "$l"}
#if($l -like "*-TRK*"){Write-Host "$l"}
}





#Setting Variables TCHP Thin Client Autologon
	$global:hives=@{HKLM=2147483650;HKCU=2147483649;HKCR=2147483648;HKEY_USERS=2147483651}
	$Count = 0;$regpath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
	$global:wsh = new-object -comobject wscript.shell
Foreach($l in $list){
	$Count = $Count + 1
	$strAutoAdminLogon = "";$strDefaultUserName = "";$strdefaultDomain = "";$strForceAutoLogon = "";$strIgnoreShiftOverride = "";$strShell = ""
	$listname = $l.Replace(" ","").ToUpper()
	$defaultusername = $l.ToLower() + "u"
	Write-Host;Write-Host -BackgroundColor Black -ForegroundColor Yellow $ListName - $Count

	<#Region Setting Autologon Values	
		$rwrite = [WMIClass]"\\$listname\root\default:StdRegProv"
		#Writing to the Registry and WMI - Remotely - Works
		$rwrite.SetDWORDValue($hives.HKLM,$regpath,"ForceAutoLogon",1)
		$rwrite.SetDWORDValue($hives.HKLM,$regpath,"IgnoreShiftOverride",0)
	#Endregion
	#>

	#Region Confirm Autologon
		# Reading registry and Confirming Changes
		$rread = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hives.HKLM, $listname)
		$regKey2= $rread.OpenSubKey($regpath)
		$Global:strAutoAdminLogon = $regKey2.GetValue("AutoAdminLogon")	
		$Global:strDefaultUserName = $regKey2.GetValue("DefaultUserName")
		$Global:strDefaultDomain =  $regKey2.GetValue("DefaultDomainName")
		$Global:strForceAutoLogon =  $regKey2.GetValue("ForceAutoLogon")
		$Global:strIgnoreShiftOverride =  $regKey2.GetValue("IgnoreShiftOverride")
		$strShell = $regKey2.GetValue("Shell")
	#Endregion

	Write-Host -BackgroundColor Black -ForegroundColor Green "AutoAdminLogon: $strAutoAdminLogon"
	Write-Host -BackgroundColor Black -ForegroundColor Green "DefaultUserName: $strDefaultUserName"
	Write-Host -BackgroundColor Black -ForegroundColor Green "DefaultDomain: $strDefaultDomain"
	Write-Host -BackgroundColor Black -ForegroundColor Green "ForceAutoLogon: $strForceAutoLogon"
	Write-Host -BackgroundColor Black -ForegroundColor Green "IgnoreShiftOverride: $strIgnoreShiftOverride"
	Write-Host -BackgroundColor Black -ForegroundColor Cyan "Shell Command: $strShell"
		#>
}


# What Operating SYstem ???
Foreach($l in $list){$compname = "";$compname = $l.ToUpper().Replace(" ","");(get-wmiobject -computer $compname -class win32_operatingsystem).Caption}














# Remote Powershell - Point and Print 
Foreach($l in $list){
	$Count = $Count + 1
	$compname = $l.Replace(" ","").ToUpper()
	Write-Host;Write-Host -BackgroundColor darkgreen -ForegroundColor White $compName - $Count

	#Region Setting Point and Print registry	
		$rwrite = [WMIClass]"\\$compname\root\default:StdRegProv"
		#Writing to the Registry and WMI - Remotely - Works
		$rwrite.CreateKey($hives.HKLM,"SOFTWARE\Policies\Microsoft\Windows NT\Printers")
		$rwrite.CreateKey($hives.HKLM,"SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint")
		$rwrite.SetDWORDValue($hives.HKLM,"SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint","NoWarningNoElevationOnInstall",0)
		$rwrite.SetDWORDValue($hives.HKLM,"SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint","UpdatePromptSettings",0)
	#Endregion

	#Region Confirming TLS Settings
		# Reading registry and Confirming Changes
		$rread = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hives.HKLM, $compname)

		$PointAndPrint="SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"

		$regKey= $rread.OpenSubKey($PointAndPrint)
		$Global:strNoWarning = $regKey.GetValue("NoWarningNoElevationOnInstall")
		$Global:strPromptSettings = $regKey.GetValue("UpdatePromptSettings")

		Write-Host -BackgroundColor Black -ForegroundColor Green $strNoWarning
		Write-Host -BackgroundColor Black -ForegroundColor Green $strPromptSetting
	#Endregion
	#>
}




# Local Powershell - Point and Print
$LocalRegPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows NT\Printers"
New-Item -path "$LocalRegPath" -Force -erroraction 'silentlycontinue'
New-Item -path "$LocalRegPath\PointAndPrint" -Force -erroraction 'silentlycontinue'
New-ItemProperty -Path "$LocalRegPath\PointAndPrint" -Name "NoWarningNoElevationOnInstall" -Value "0" -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path "$LocalRegPath\PointAndPrint" -Name "UpdatePromptSettings" -Value "0" -PropertyType DWORD -Force | Out-Null

<# REG Command
reg ADD HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers /v NoWarningNoElevationOnInstall /t REG_DWORD /d 0 /f
reg ADD HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers /v UpdatePromptSettings /t REG_DWORD /d 0 /f
#>



# Append "C:\windows\System32\Drivers\etc\Hosts" File Remotely
Foreach($l in $list){
	$Count = $Count + 1
	$compname = $l.Replace(" ","").ToUpper()
	Write-Host;Write-Host -BackgroundColor darkgreen -ForegroundColor White $compName - $Count
	"207.231.32.35	fs.texaschildrens.org"  >> "\\$compname\c$\windows\system32\drivers\etc\hosts"
}




#Multi-User Desktop

#SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{3DD6481A-A712-4c4c-88FF-6DDCAB28DE86}

#SOFTWARE\Policies\Microsoft\Windows\System    
#DefaultCredentialProvider = {11660363-781C-617B-0100-128274950001} 

Foreach($l in $list){
	$Count = $Count + 1
	$compname = $l.Replace(" ","").ToUpper()
	Write-Host;Write-Host -BackgroundColor darkgreen -ForegroundColor White $compName - $Count

	#Region Setting MUD registry	
		$rwrite = [WMIClass]"\\$compname\root\default:StdRegProv"
		#Writing to the Registry and WMI - Remotely - Works
		$rwrite.SetStringValue($hives.HKLM,"SOFTWARE\Policies\Microsoft\Windows\System","DefaultCredentialProvider","{11660363-781C-617B-0100-128274950001}")
		$rwrite.SetStringValue($hives.HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers\{3DD6481A-A712-4c4c-88FF-6DDCAB28DE86}","Disabled",1)
	#Endregion

	#Region Confirming TLS Settings
		# Reading registry and Confirming Changes
		$rread = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hives.HKLM, $compname)

		$PointAndPrint="SOFTWARE\Policies\Microsoft\Windows\System"

		$regKey= $rread.OpenSubKey($PointAndPrint)
		$Global:strNoWarning = $regKey.GetValue("NoWarningNoElevationOnInstall")
		$Global:strPromptSettings = $regKey.GetValue("UpdatePromptSettings")

		Write-Host -BackgroundColor Black -ForegroundColor Green $strNoWarning
		Write-Host -BackgroundColor Black -ForegroundColor Green $strPromptSetting
	#Endregion
	#>
}








