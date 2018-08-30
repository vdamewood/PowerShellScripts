#!/usr/bin/env pwsh
# UpdateRepos.ps1: Automate updating remote repositories
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
	[String]$InputFile="repos.json"
)

$BuildData = ConvertFrom-Json -InputObject (
	Get-Content $InputFile | Out-String)
foreach($i in $BuildData.Repos)
{
	Invoke-Command `
		-HostName $i.Host `
		-ArgumentList $i `
		-ScriptBlock {
	param($Repo)

		if(![string]::IsNullOrEmpty($Repo.Prep) `
			-and (Test-Path -PathType Leaf $Repo.Prep))
		{
			. $Repo.Prep
		}

		Set-Location $Repo.Location
		git fetch --all
		git checkout master
		git merge --ff-only
	}
}
