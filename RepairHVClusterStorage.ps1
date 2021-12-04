﻿<#	
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

Get-Cluster
Get-ClusterNode | Out-String

#Get Cluster Disks
$badDisks = Get-PhysicalDisk | Where-Object { ($_.OperationalStatus -eq "Lost Communication") -and ($_.DeviceId -ne "0") }
if(($badDisks | Measure-Object) -eq 0)
{
	Write-Host "There are no Disks with Lost Communication Status"
}
else 
{
	$DeviceIds = $PhysicalDisks.DeviceId | ForEach-Object { $_[0] } | Select-Object -Unique

	#Get Nodes from registry
	$NodesReg = Get-ItemProperty HKLM:\Cluster\Nodes\* | Select-Object NodeName,PSChildName

	$badNode = @()
	ForEach ($n In $NodesReg)
	{
		if($DeviceIds -contains $n.PSChildName)
		{
			$badNode += $n.NodeName
		}
	}

	Write-Host ("Nodes with PhysicalDisk Lost Communication: " + $badNode)
}

if($badNode -notcontains $env:COMPUTERNAME)
{
	Write-Host "There are no Lost Communication disks on this Node."
	return;
}
else 
{
	## Remove below line in prod
	$badNode = "hyp02"

	#Get Virtual Disks
	Get-VirtualDisk | Out-String

	# Pause Node
	Suspend-ClusterNode -Name $badNode

	Get-ClusterGroup | Where-Object {($_.OwnerNode -eq $badNode) -and ($_.GroupType -eq "VirtualMachine")} | Move-ClusterVirtualMachineRole
	Get-ClusterGroup | Where-Object {$_.OwnerGroup -eq $badNode} | Move-ClusterGroup

	Get-Service -ComputerName $badNode | out-string
	#Get-Service -Name ClusSvc -ComputerName $badNode | Stop-Service
	#Start-Sleep -Seconds 5
	#Get-Service -Name ClusSvc -ComputerName $badNode | Start-Service

	Resume-ClusterNode $badNode

	#Get StorageJob
	Get-StorageJob | Out-String

	Get-ClusterNode | Out-String

	Get-Service -Name ClusSvc

}




