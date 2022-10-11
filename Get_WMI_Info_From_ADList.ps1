
#### STEP 1

	$Searchroot = "ou=Production,ou=BCA Computers,ou=Engineered Solutions,ou=Resource,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Kiosk Trackboard,ou=Engineered Solutions,ou=Resource,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Website Kiosk Trackboard,ou=Engineered Solutions,ou=Resource,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Clinical Workstation T&G,ou=Engineered Solutions,ou=Resource,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Production,ou=OBGYN Epidural,ou=Clinical Workstation T&G,ou=Engineered Solutions,ou=Resource,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=IS,ou=Departments,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Appsense,ou=Computers,ou=HealthCenters,ou=Departments,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Pathology,ou=Departments,dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "dc=ad,dc=texaschildrenshospital,dc=org"
	$Searchroot = "ou=Departments,dc=ad,dc=texaschildrenshospital,dc=org"



#### STEP 2	

$mask = "d17-*"
$list = (Get-ADComputer -filter {Name -like $mask} -Properties * -searchbase $searchroot).Name | Sort-Object
	

#### STEP 3	
	
	
	# GETTING WMI INFORMATION
	$primesw = [Diagnostics.Stopwatch]::StartNew()
	$hashcoll = "";$hashcoll = @();$Totalcount = 0
	foreach ($l in $list){
	
	#Region Clearing Variables
	#Clearing Data before next Name in List
		$compname = "";$Skip = "";$strUserName = "";$CompGroups = ""
		$strArchitecture = "";$strMACAddress = "";$strDHCPEnabled = "";$strCPUName = "";$strCPUSpeed = "";$hd1Model = "";$hd1Size = "";$hd1Freespace = "";$netlist = "";$netlist = "";$nic = ""
		$strCSDVersion = "";$strCSName = "";$strManufacturer = "";$strMemoryGB = "";$strModel = "";$strProductName = "";$strSerialNumber = "";$strAssetTag = "';$strCPUcount = "";$strCPUSpeed = ""
		$ArrMonManufacturerName = "";$ArrMonProductCodeID = "";$ArrMonSerialNumberID = "";$ArrMonUserFriendlyName = ""
		$MonMFG = "";$MonModel = "";$MonSerial = "";$MonFreindly = ""
		$Reply = "";$PingAddress = "";$PingStatus = ""
	#Finished Clearing Variables
	#Endregion
	
	#Region Collecting AD Info
		$compname = $l.ToUpper().Replace(" ","")
		$TotalCount = $TotalCount + 1
		$objComp = "";$objComp = (Get-ADComputer $compname -Properties *)
		$LastDate ="";$LastDate= $objComp.LastLogonDate.ToString("MM-dd-yyyy HH:mm:ss")
		$LastYear ="";$LastYear = $objComp.LastLogonDate.ToString("yyyy")
		$OU = "";$OU = ($objComp.CanonicalName).Replace("ad.TexasChildrensHospital.org/","").TrimEnd("/" + $compname)
		Write-Host;Write-Host -BackgroundColor DarkGreen -ForegroundColor White "$compname     $Lastyear     -  $TotalCount"
	#Endregion
	
	#Region If Statement
		If($Lastyear -gt "2020"){
			#Simple Ping test
				write-host -backgroundcolor Black -foregroundcolor Yellow  "Trying to Ping - $compname    #    $Totalcount"
				$ping = new-object System.Net.Networkinformation.Ping;$reply = $ping.Send($compname,30,[byte]1);$pingstatus = $reply.status;$pingaddress = $reply.Address
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
				
				#Region Collecting Monitor Logic
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
				
				} #Ending ($compname -eq $strCSName)	
			}# Ending If($Pingstatus -eq "Success")
		

		}#Ending If($Lastyear -eq 2020 or 2021)
	#EndRegion
		
		#Region Writing Hash
			$hashout = new-object System.Object
			$hashout | add-member NoteProperty TotalCount ($TotalCount)
			$hashout | add-member NoteProperty PingStatus ($pingstatus)
			$hashout | add-member NoteProperty ComputerName ($compname)
			$hashout | add-member NoteProperty Found ($strCSName)
			$hashout | add-member NoteProperty UserName ($strUserName)
			$hashout | add-member NoteProperty Manufacturer ($strManufacturer)
			$hashout | add-member NoteProperty Model ($strModel)
			$hashout | add-member NoteProperty FoundSerial ($strSerialNumber)
            $hashout | add-member NoteProperty AssetTag ($strAssetTag)
			$hashout | add-member NoteProperty DHCP ($strDHCPEnabled)
			$hashout | add-member NoteProperty IPAddress ($PingAddress)
			$hashout | add-member NoteProperty MACAddress ($strMACAddress)
			$hashout | add-member NoteProperty Blank1 ""
			$hashout | add-member NoteProperty OperatingSystem ($strProductName)
			$hashout | add-member NoteProperty Architecture ($strArchitecture)
			$hashout | add-member NoteProperty CPUCount ($strCPUcount)
			$hashout | add-member NoteProperty CPUSpeed (($strCPUSpeed).ToString() + " GHZ")
			$hashout | add-member NoteProperty CPUName ($strCPUName)
			$hashout | add-member NoteProperty Memory ($strMemoryGB)
		# One Hard Disk Drive
			$hashout | add-member NoteProperty Blank2 ""
			$hashout | add-member NoteProperty "HD-1-Model" ($hd1Model)
			$hashout | add-member NoteProperty "HD-1-Size" ($hd1Size)
			$hashout | add-member NoteProperty "HD-1-Free" ($hd1Freespace)
		# Monitors
			$hashout | add-member NoteProperty Blank3 ""
			$hashout | add-member NoteProperty Mon1-FriendlyName $MonFreindly[0] 
			$hashout | add-member NoteProperty Mon1-Serial $MonSerial[0]
			$hashout | add-member NoteProperty Mon2-FriendlyName $MonFreindly[1] 
			$hashout | add-member NoteProperty Mon2-Serial $MonSerial[1]
			$hashout | add-member NoteProperty Mon3-FriendlyName $MonFreindly[2] 
			$hashout | add-member NoteProperty Mon3-Serial $MonSerial[2]
			$hashout | add-member NoteProperty Mon4-FriendlyName $MonFreindly[3] 
			$hashout | add-member NoteProperty Mon4-Serial $MonSerial[3]
		# AD Info
			$hashout | add-member NoteProperty Blank4 ""
			$hashout | add-member NoteProperty "LastLogonY" ($LastYear)
			$hashout | add-member NoteProperty "LastLogon" ($LastDate)
			$hashout | add-member NoteProperty "OU-Location" ($ou)			
			$hashout | add-member NoteProperty "ADGroups" ($Compgroups)			
			$hashcoll += $hashout
		#EndRegion

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
		$SDate = (Get-Date -Format "_yyyy-MM-dd.HHmmss")	
		$hashfile = "\\tccdav1b\global\ePlus\TCH Refresh\Refresh 2020\WMI-Info\" + ($mask).ToUpper().Replace("-*","") + "_WMI-Info.csv"
		$hashcoll | Export-Csv $hashfile -NoTypeInformation
		$hashcoll | Out-GridView -Title "WMI Results"
	#Endregion

