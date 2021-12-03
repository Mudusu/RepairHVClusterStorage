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

Get-Cluster

$ClusterNodes = Get-ClusterNode
if($ClusterNodes.State -contains "Paused")
{
		Get-ClusterNode | Where-Object {$_.State -eq "Paused"} | Resume-ClusterNode
}

Get-ClusterNode | Out-String

#Get Cluster Disks
Get-PhysicalDisk | Out-String

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
