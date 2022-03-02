# Bootstrap-Workstation
This repo contains all the scripts I use to get a new machine up and running as quickly as possible.
Right now it only supports Windows.

# Getting started
1. Download this repository to the machines (https://github.com/shoddyguard/Bootstrap-Workstation/archive/refs/heads/main.zip)
2. Run PowerShell as admin
3. Set execution policy `Set-ExecutionPolicy -ExecutionPolicy Bypass`
4. Navigate into the downloaded repo 
5. Run the prep script `& '.\Scripts\1 - Prep\prepare_windows.ps1'`
6. Load up PowerShell Core as an admin
7. Set execution policy for PoSh Core `Set-ExecutionPolicy -ExecutionPolicy Bypass`
8. Run the Bootstrap script passing any parameters that you care about `& '.\Scripts\2 - Bootstrap\bootstrap_windows.ps1'`