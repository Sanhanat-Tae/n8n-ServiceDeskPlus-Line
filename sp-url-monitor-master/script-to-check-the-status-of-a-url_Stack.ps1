#https://stackoverflow.com/questions/18500832/script-to-check-the-status-of-a-url

## The URI list to test 
$URLListFile = "H:\xxx\xxx\urlList.txt"  

$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue 

  $Result = @()   #Create result as an empty array 

  ForEach($Uri in $URLList) { 
  $time = TRY{ 
    $request = $null 
    ## Request the URI, and measure how long the response took. 
    $result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri 
    } 
  $result1.TotalMilliseconds 
  }  

  CATCH 
  { 
   <# If the request generated an exception (i.e.: 500 server 
   error or 404 not found), we can pull the status code from the 
   Exception.Response property 
   #> 
   $request = $_.Exception.Response 
   $time = -1 
  }

  $result += [PSCustomObject] @{ 

  Time = Get-Date; 
  Uri = $uri; 
  StatusCode = [int] $request.StatusCode; 
  StatusDescription = $request.StatusDescription; 
  ResponseLength = $request.RawContentLength; 
  TimeTaken =  $time;  
  } 
} 

#Prepare email body in HTML format 
if($result -ne $null) 
{ 
    $Outputreport = "<HTML><TITLE>Website Availability Report</TITLE><BODY background-color:peachpuff><font color =""#99000"" face=""Microsoft Tai le""><H2> Website Availability Report </H2></font><Table border=1 cellpadding=0 cellspacing=0><TR bgcolor=gray align=center><TD><B>URL</B></TD><TD><B>StatusCode</B></TD><TD><B>StatusDescription</B></TD><TD><B>ResponseLength</B></TD><TD><B>TimeTaken</B></TD</TR>" 
    Foreach($Entry in $Result) 
    { 
        if($Entry.StatusCode -ne "200") 
        { 
            $Outputreport += "<TR bgcolor=red>" 
        } 
        else 
        { 
            $Outputreport += "<TR>" 
        } 
        $Outputreport += "<TD>$($Entry.uri)</TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.timetaken)</TD></TR>" 
    } 
    $Outputreport += "</Table></BODY></HTML>" 
} 

$Outputreport | out-file H:\xxx\xxx\test.htm 
Invoke-Expression H:\xxx\xxx\test.htm 
