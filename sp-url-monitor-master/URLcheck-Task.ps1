#Script that checks all URL in the list and sends an email when 1 fails
#Based on: 
#https://stackoverflow.com/questions/18500832/script-to-check-the-status-of-a-url
#http://gallery.technet.microsoft.com/scriptcenter/Powershell-Script-for-13a551b3#content 
#Add it as a scheduled task and run it every 5 minutes. 

#Only apply in office hours. Exclude nightly IISrecycle.   
if (((get-date).Hour -ge 6) -and ((get-date).Hour -le 23)) {

#Define a log file and write a first header row
$Logfile = "\\share\Monitoring\URLcheck-Log.csv"
if (-NOT (Test-Path $Logfile)) {
"URL;HH;MM;SS;ResponseTime;Date;Status" | Add-Content $LogFile
}

#Set script variables 
$URLListFile = "\\share\Monitoring\URLcheck-URL.csv"  
$URLList = Get-Content $URLListFile # -ErrorAction SilentlyContinue 
$URLResult = ""
$URLListIN = ""
$allOK =$true 
$bsend = $false
$WriteConfig = $false
$HTTPonError = ""
$HTTPup = ""

#Set proxy for the script
Set-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigURL -Value "http://proxypac.contoso.com/proxy.pac"

#Loop through the URL in the list    
ForEach ($key in $URLList) {
	#Check if URL starts with http 
    if ($key.Substring(0,4) -ne "http") 
    {
		#We use "+="" to add   
		#Notepad expects linebreaks to be encoded as `r`n 
		if ($URLresult -ne "") {
		$URLresult += "`r`n"
		} 
        $URLresult += $key 
    }
    else
    {  
	#key is the URL for this loop iteration 
    #k is used to split the entries in the input csv, using ; as seperator  
	$k = $key.Split(";")
    $url = $k.Item(0)
    $maxtime = $k.Item(1)
    [int]$maxerrorbeforesend = [convert]::ToInt32($k.Item(2))
    $alreadysend = $k.Item(3)
    [int]$numerror = [convert]::ToInt32($k.Item(4))
    $r1 = $k.Item(5)
    $r2 = $k.Item(6)
    $recipient =  $k.Item(7)

	#Region Get-Request URL
    $startTime = Get-Date
    $object = "" | Select URL, HH, MM, SS, ResponseTime, Date1, Status
    $object.Status = 0 

    Try {
    $req = Invoke-WebRequest $url -UseDefaultCredentials
    $object.Status = $request.StatusCode
    if ($req.Content.Contains('<img src="welcome.png" alt="IIS7"')) {
        $object.Status = 1001
        } 
    if ($req.Content.Contains('<img src="iis-85.png" alt="IIS"')) {
        $object.Status = 1002
        }
    }
    Catch {
    $object.Status = 999
    }
	#Endregion 

	#Process results  
    $url
    $object.Status
    $endTime = Get-Date
    $object.Url = $url 
    $object.HH = $startTime.Hour
    $object.MM = $startTime.Minute
    $object.SS = $startTime.Second
    $object.Date1 = $startTime.ToShortDateString()
    $a = ($endtime - $startTime).TotalSeconds
    $a = ("{0:N6}" -f $a).ToString()
    
	#Result ne 200 OK 
    if ($object.status -ne 200) 
    { 
        $HTTPonError += "`r`n" + $endtime + ", Status:" + $object.status+ " - " + $url  + " <br>"
        $numerror += 1
        if ($numerror -ge $maxerrorbeforesend) 
        {
            $allOK = $false
            if ($maxerrorbeforesend -eq 0){
            $bsend = $true
            }else{
                if ($alreadysend -eq "N") 
                {
                $alreadysend = "Y"
                $bsend = $true
                }
                else 
                {}
            }
        } 
    }

	#Result eq 200 OK 
    else 
    {
        $HTTPup += "`r`n" + $endtime + ", Status: OK" + " - " + $url  + " <br>"
        if ($alreadysend -eq "Y") {
        $alreadysend = "N"
        $bsend = $true
        $numerror = 0
        }   
    }
    $Line = $url + ";" +  $object.HH + ";" +  $object.MM + ";" +  $object.SS + ";" + "$a" + ";" + $object.Date1 + ";" + $object.Status  
	$Line | Add-Content $LogFile
    if ($URLResult -ne "") {$URLResult += "`r`n"} 
    $URLTest =  $url + ";" + $maxtime + ";" + $maxerrorbeforesend + ";" + $alreadysend + ";" + $numerror + ";" + $r1  + ";" + $r2  + ";" + $recipient
    $URLResult += $URLTest
		if ($URLTest -ne $key) {
			$WriteConfig = $true
		}
    }
}

if ($WriteConfig) {
	if ($bsend) {
		$recipient = $recipient.Split(",")
		$body = $HTTPonError + " <br> <br>"
		$body += $HTTPup + " <br> <br>"
		$body += "Click <a href=file:\\files\IO_CAE_TEAMAFS\02.Sharepoint\Monitoring\Montoring_URLs.xlsm>\\files\IO_CAE_TEAMAFS\02.Sharepoint\Monitoring\Montoring_URLs.xlsm</a> to view monitoring <br> <br>" 
		$body += "Config File : <a href=file:\\files\IO_CAE_TEAMAFS\02.Sharepoint\Monitoring>\\files\IO_CAE_TEAMAFS\02.Sharepoint\Monitoring\URLList.csv</a> <br> <br>" 
		$From = "FMB_8048316414.int@aginsurance.be"   
		if ($allOK) {
			"URLs are UP&Run! :)" 
			$body = "All URLs're Up <br> <br>" + $body
			Send-MailMessage -From $From -To $recipient -Subject "URLs are UP&Run! :)" -SmtpServer RELAYSERVER.contoso.com -Body $body -BodyAsHtml 
		}
		else {
        "URLs Failed! :("
        $body = "URL(s) are <b>not accessible !!!</b> <br> <br>" + $body
		Send-MailMessage -From $From -To $recipient -Subject "URLs Failed! :(" -SmtpServer RELAYSERVER.contoso.com -Body $body -BodyAsHtml -Priority high 
		}
}

if ($WriteConfig) {
Clear-Content -Path $URLListFile
$URLResult | Add-Content -Path $URLListFile
}

} #End For Each 
} #End If office hours   
