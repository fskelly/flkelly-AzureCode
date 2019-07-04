**How to use these scripts**

These scripts are designed to deploy a demo environment based upon a naming convention.
All the variables can be changed as needed, stored in the settings.json file. You will need [JQ](https://stedolan.github.io/jq/) for this script to dunction properly.
I have split the script into smaller files to make it easier to use / follow, they can be easily combined into 1 single file. All settings are contained with the [settings.json](powershell/demoEnvironmentBuild/settings.json) file.

It creates the following
1. Resource Groups as needed
2. Creates a "hub" network, VPN gateway and Local Network gateway in South Africa North. (I am from South Africa)
3. Creates an additional spoke in South Africa North and the required peerings.
4. Creates an additional spoke in West Europe and the required peerings.
5. Creates an additional spoke in North Europe and the required peerings.
6. Creates VMs (Windows and Linux) in South Africa North.
7. Creates VMs (Windows and Linux) in West Europe.
8. Creates VMs (Windows and Linux) in North Europe.

Please enjoy and hopefully this makes your life a little easier.
