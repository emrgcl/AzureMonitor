[CmdletBinding()]
Param(
    [string]$TenantId = '72f988bf-86f1-41af-91ab-2d7cd011db47',
    [string]$AppId = '8c3063cf-92a6-44c6-a9c0-22ed87058420',
    [string]$AppSecret = '1Gw.~zW~zlTCQ03WW~.824S9xwIVXl0.DE',
    [string]$logAnalyticsWorkspaceId = '4d7a58f4-dea3-4478-bc0d-c33542a77425',
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$ExportPath,
    [int32]$SampleCount=10

)
function Export-MultipleExcelSheets {
    <#
        .Synopsis
        Takes a hash table of scriptblocks and exports each as a sheet in an Excel file    

        .Example
$p = Get-Process

$InfoMap = @{
    PM                 = { $p | Select-Object company, pm }
    Handles            = { $p | Select-Object company, handles }
    Services           = { Get-Service }
}

Export-MultipleExcelSheets -Path $xlfile -InfoMap $InfoMap -Show -AutoSize        
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Path,
        [Parameter(Mandatory = $true)]
        [hashtable]$InfoMap,
        [string]$Password,
        [Switch]$Show,
        [Switch]$AutoSize
    )

    $parameters = @{ } + $PSBoundParameters
    $parameters.Remove("InfoMap")
    $parameters.Remove("Show")

    $parameters.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    foreach ($entry in $InfoMap.GetEnumerator()) {
        if ($entry.Value -is [scriptblock]) {
            Write-Progress -Activity "Exporting" -Status "$($entry.Key)"
            $parameters.WorkSheetname = $entry.Key

            & $entry.Value | Export-Excel @parameters
        }
        else {
            Write-Warning "$($entry.Key) not exported, needs to be a scriptblock"
        }
    }

    if ($Show) { Invoke-Item $Path }
}
Function Get-LAMetadata {
    [CmdletBinding()]
    Param(
        [string]$TenantId,
        [string]$AppId,
        [string]$AppSecret,
        [string]$logAnalyticsWorkspaceId
    )
        $loginURL = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        $resource = "https://api.loganalytics.io"
    
    $authbody = @{
        grant_type = "client_credentials"
        resource = $resource
        client_id = $AppId
        client_secret = $AppSecret 
    }
    
    $oauth = Invoke-RestMethod -Method Post -Uri $loginURL -Body $authbody
    $headerParams = @{'Authorization' = "$($oauth.token_type) $($oauth.access_token)" }
    $logAnalyticsBaseURI = "https://api.loganalytics.io/v1/workspaces"
    invoke-RestMethod -method Get -uri "$($logAnalyticsBaseURI)/$($logAnalyticsWorkspaceId)/metadata" -Headers $headerParams
}
Function Get-TableMetadata {
    [CmdletBinding()]
    Param(
        $Metadata,
        $TableID
    )
    $Metadata.Tables.where({$_.ID -eq $TableID}).Columns | Select-Object -Property Name,Type,Description
}
Function Get-TableSampleData {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$TableName,
        [Parameter(Mandatory=$true)]
        [int32]$SampleCount
    )
    $Query = "$TableName | take $SampleCount"
    Write-Verbose $Query
    Invoke-AzOperationalInsightsQuery -WorkspaceId $logAnalyticsWorkspaceId -Query $Query
}


#Requires -Module @{ModuleName='Az.Accounts';ModuleVersion ='2.2.3'},@{ModuleName='Az.OperationalInsights';ModuleVersion ='2.1.0'},@{ModuleName='ImportExcel';ModuleVersion ='7.1.1'}
Connect-AzAccount
$Metadata = Get-LAMetadata -TenantId $TenantId -AppId $AppId -logAnalyticsWorkspaceId $logAnalyticsWorkspaceId -AppSecret $AppSecret

Foreach ($TableGroup in $Metadata.tableGroups) {
    $SolutionDisplayname = $TableGroup.Displayname
    $TableIDs = $TableGroup.Tables
    $Path = "$ExportPath\$SolutionDisplayname.xlsx"
    Write-verbose "Started Working on $TableGroup with $($TableGroup.Tables.Count) tables which will be saved into '$Path'"

    Foreach ($TableID in $TableIDs) {
        
        $TableName = $tables.Where({$_.Id -eq $TableID}).Name
        Write-Verbose "Querying metadata and sampledata for table $TableName with ID $TableID"
        $DataToExort = @{

            "$($TableName)_Metadata" = {Get-TableMetadata -Metadata $Metadata -TableId $TableID}
            "$($TableName)_SampleData" = {Get-TableSampleData -TableName $TableName -SampleCount 100}
        }
        Export-MultipleExcelSheets -AutoSize $Path $DataToExort
    }
    Write-verbose "Ended Working on $TableGroup ."
}