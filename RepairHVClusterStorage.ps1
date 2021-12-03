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



Get-PhysicalDisk | Out-String

Get-VirtualDisk | Out-String

Get-StorageJob | Out-String

Get-Service -Name ClusSvc