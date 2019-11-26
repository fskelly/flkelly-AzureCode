# How to use these scripts

These scripts are designed to deploy a demo environment based upon a naming convention.
All the variables can be changed as needed, stored in the settings.json file. You will need [JQ](https://stedolan.github.io/jq/) for this script to dunction properly.
I have split the script into smaller files to make it easier to use / follow, they can be easily combined into 1 single file. All settings are contained with the [settings.json](settings.json) file. Please check the file and change settings as needed.

## VPN settings

Please feel free to comment out line **48-55** of [script 2](2-createzanetwork.ps1) if a VPN is not needed, this will also save some time. Please also then modify the peerings as needed to comment out "-useremotegateways"

It creates the following

1. [Resource Groups as needed](1-creatergs.ps1)
2. [Creates a "hub" network, VPN gateway and Local Network gateway in South Africa North. (I am from South Africa)](2-createzanetwork.ps1)
3. [Creates an additional spoke in South Africa North and the required peerings.](3-createzaspoke.ps1)
4. [Creates an additional spoke in West Europe and the required peerings.](4-createwespoke.ps1)
5. [Creates an additional spoke in North Europe and the required peerings.](5-createnespoke.ps1)
6. [Creates VMs (Windows and Linux) in South Africa North.](6-createzanspokevms.ps1)
7. [Creates VMs (Windows and Linux) in West Europe.](7-createwespokevms.ps1)
8. [Creates VMs (Windows and Linux) in North Europe.](8-createnespokevms.ps1)

The script combined as one long script can be found [here](combined.ps1)

Please enjoy and hopefully this makes your life a little easier.
