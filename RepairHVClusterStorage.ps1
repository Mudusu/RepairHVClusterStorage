<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.172
	 Created on:   	04-12-2021 00:29
	 Created by:   	venu
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>


# Repair storage

Write-Host (Get-Cluster | Out-String)
Write-Host (Get-ClusterNode | Out-String)
Write-Host (Get-PhysicalDisk | Out-String)
Write-host (Get-VirtualDisk | Out-String)

#Get Cluster Disks
$badDisks = Get-PhysicalDisk | Where-Object { ($_.OperationalStatus -eq "Lost Communication") -and ($_.DeviceId -ne "0") }
if(($badDisks | Measure-Object).Count -eq 0)
{
	Write-Host "There are no Disks with Lost Communication Status"
	return
}
else 
{
	$lostDeviceIds = $badDisks.DeviceId | Where-Object {($_.DeviceId -ne 0) -and ($_.DeviceId -ne $null)} | ForEach-Object { $_[0] } | Select-Object -Unique
	#Get Nodes from registry
	$NodesReg = Get-ItemProperty HKLM:\Cluster\Nodes\* | Select-Object NodeName,PSChildName
	$badNode = @()

	if($lostDeviceIds)
	{
		ForEach ($n In $NodesReg)
			{
				if($lostDeviceIds -contains $n.PSChildName)
				{
					$badNode += $n.NodeName
				}
			}

		Write-Host ("Nodes with PhysicalDisk Lost Communication: " + $badNode)
	}
	else ## if device ids are blank
	{
		#$DeviceIds = (Get-PhysicalDisk | Where-Object {($_.DeviceId -ne 0) -and ($_.DeviceId -ne $null)}).DeviceId | ForEach-Object {$_[0]} | Select-Object -Unique
		$PhysicalDisks = Get-PhysicalDisk | Where-Object { $_.DeviceId -ne "0" }

		$disksperNode = ($PhysicalDisks.Count / $NodesReg.Count)

		foreach($n in $NodesReg)
		{
			$nDisks = (($PhysicalDisks | Where-Object { ($_.DeviceId) -and ($_.DeviceId[0] -eq $n.PSChildName[0]) }) | Measure-Object).Count
			if($nDisks -lt $disksperNode)
			{
				$badNode += $n.NodeName
			}
		}

		if($badNode)
		{
			Write-Host ("Nodes with Physical Disks Lost Communication: " + $badNode)
		}
	}
}


if($badNode -notcontains $env:COMPUTERNAME)
{
	Write-Host "There are no Lost Communication disks on this Node."
	return;
}
else 
{
	## Remove below line in prod
	#$badNode = "hyp02"

	# Pause Node
	Suspend-ClusterNode -Name $badNode

	Get-ClusterGroup | Where-Object {($_.OwnerNode -eq $badNode) -and ($_.GroupType -eq "VirtualMachine")} | Move-ClusterVirtualMachineRole
	Get-ClusterGroup | Where-Object {$_.OwnerGroup -eq $badNode} | Move-ClusterGroup

	Stop-Service ClusSvc -Verbose
	Start-Sleep -Seconds 5
	Start-Service ClusSvc -Verbose
	Start-Sleep -Seconds 60
	
	Resume-ClusterNode $badNode

	#Get StorageJob
	Get-StorageJob | Out-String

	Get-ClusterNode | Out-String
	Get-PhysicalDisk | Out-String
	Get-VirtualDisk | Out-String

}
