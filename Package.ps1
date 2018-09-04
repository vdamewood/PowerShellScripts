#!/usr/bin/env pwsh
# Package.ps1: Build and upload packages for CMake-based projects
# Copyright 2018 Vincent Damewood
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# 	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.

param(
	[String]$File="builds.json",
	[String]$GitRef="master"
)

$BuildData = ConvertFrom-Json -InputObject (
	Get-Content $File | Out-String)
foreach($i in $BuildData.Builds)
{
	Invoke-Command `
		-HostName $i.Host `
		-ArgumentList $i, $BuildData.UploadPath `
		-ScriptBlock {
	param($B, $UplPth)
		if(![string]::IsNullOrEmpty($B.Prep) `
			-and (Test-Path -PathType Leaf $B.Prep))
		{
			. $B.Prep
		}

		$BldDir = [System.IO.Path]::GetTempFileName()
		Remove-Item -Force $BldDir
		New-Item -ItemType directory $BldDir
		Set-Location $BldDir

		cmake -GNinja -DCMAKE_BUILD_TYPE=$B.BuildType $B.SrcDir
		ninja package

		foreach ($pkg in Get-ChildItem `
			-Filter ((Get-Content CMakeCache.txt | Select-String -Pattern `
			"BIN_PACKAGE:").Tostring().Split("=")[1] + ".*"))
		{
			scp $pkg.Name $UplPth
		}
		set-location ~
		remove-item -Recurse -Force $BldDir
		if (Test-Path $BldDir)
		{
			Write-Output "!!!! Failed to delete: $BldDir"
		}
	}
}
