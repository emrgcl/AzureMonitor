# AzureMonitor

# Prerequisites
- Install Azure Powershell

# Operations

## Creating a Workspace

```PowerShell
# Set variables
$ResourceGroupName = 'ContosoAll'
$WorkspaceName = 'ArcForServersWS'

# We need a location, in this case we will use the location of the resource group. Lets get the resoruce group object to use later.
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName

# create the Workspace.
New-AzOperationalInsightsWorkspace -Location ($ResourceGroup.Location) -Name $WorkspaceName -Sku Standard -ResourceGroupName $ResourceGroupName

```





# Solutions

## List enabled solutions
```PowerShell
(Get-AzOperationalInsightsIntelligencePack -ResourceGroupName ContosoAll -WorkspaceName ArcForServersWS).Where({$_.Enabled -eq $true})
```

Result will look like
```
Name           Enabled
----           -------
LogManagement     True
AzureResources    True     
```

# Log Analtitcs Data Sources

Below is a table of default Data Sources in Log analytics and CmdLets to manage them. 


| Data Source                  | CmdLets                                                      | Notes                          |
|------------------------------|--------------------------------------------------------------|--------------------------------| 
| Windows Event Logs           | New-AzOperationalInsightsWindowsEventDataSource              |                                |
| Windows Performance Counters | New-AzOperationalInsightsWindowsPerformanceCounterDataSource | Some notes those are important |
| Linux Performance Counters   | New-AzOperationalInsightsLinuxPerformanceObjectDataSource    |                                |
| IIS Logs                     | Enable-AzOperationalInsightsIISLogCollection,Disable-AzOperationalInsightsIISLogCollection                 |                                |
| Custom Logs                  | New-AzOperationalInsightsCustomLogDataSource                 |                                |
| Syslog                       | New-AzOperationalInsightsLinuxSyslogDataSource               |                                |
# References

- [Create and configure a Log Analytics workspace in Azure Monitor using PowerShell](https://docs.microsoft.com/tr-tr/azure/azure-monitor/platform/powershell-workspace-configuration)
- [Install Azure PowerShell ](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.1.0)