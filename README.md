[[_TOC_]]
# AutomatedSQLInstall
## Scenario
You're a DBA in your company. You look after all the database needs of your production application/service as well as lower environments such as Staging, Development, Pre-Prod etc. You also look after all the local SQL installs for all the Developers. To ensure identical tests in all environments these local installs should be alot more tightly administered. Things like:
* Authentication Types
* Collation
* Feature types

Sometimes having just a SOP in a wiki is open to interpretation, as well as getting out of date quick without always realising it. 

## Solution
An AutomatedSQLInstall can allow you to source control a specific local SQL configuration. You then tie it into a Dev new starter wiki and all users will just be able to run a batch file to install their SQL super quickly. 

This means when you migrate to a higher version you then change the download link and major version in the Batch file and Devs will run to upgrade their instance in minutes

## How to use
* Clone this solution
* The batch files in /Installation can be used to install either 2019 or 2022.
* All you need to change is the filepaths in the batch files to ensure you are using the correct directory you cloned to. 
* The batch files will:
   * Install if not installed
   * Update if a lower version than you want your users to have
   * Advise if a higher version than you want your users to have