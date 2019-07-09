# Install the LittoSIM environment
## STEP 1 - Install the Gama platform base

https://gama-platform.github.io/
downloald
download daily build
continous build
GAMA1.8_Continuous_withJDK
Unzip the file in a folder which is not the "dowload" folder
Click on Gama.exe or on Gama.app
Choose a workspace directory as you please, but on the same drive as the gama-platform
Click Yes if asked "Would you like to create a new workspace"

## STEP 2 - Install the Gama extensions
In Gama, click on "Help -> Install new plugins"
Choose Work with -> http://updates.gama-platform.org/experimental
Choose   Optional components of GAMA	
Select Gaming and RemoteGUI
Click on Next, and Next, then Accept the licence terms, then click on button Finish
Click on Install Anyway, and then Restart now
When Gama restarts, if requested, choose once again your Gama Workspace

## STEP3 - download LittoSIM 
Go to https://github.com/LittoSim/LittoSim_model
On the left side, click on the gray button called "Branch: master", and choose "LittoDev"
Then click "Clone or Download", then "download zip"
Unzip the file wherever you want
In Gama, right click on "User model", and choose Import->Gama Project
Choose the directory you just unzipped
Select the option "copy into workspace", then click on "Finish

## STEP4 - Download and Install ActiveMQ
Go to https://activemq.apache.org/
Under ActiveMQ 5 "classic", choose download latest
Choose adequateOS and download
Unzip the file where ever you like

Well done ! you just finished installing the LittoSIM environment

# Launch a littosim simulation
## STEP 1 - Start ActiveMQ
For a Windows version -> In your ActiveMQ folder, go to \bin\win64, and then launch wrapper.exe
For a MAC version -> launch a terminal, go to the folder of ActiveMQ, then go to the folder bin/macosx/ then type ./activemq start

## STEP 2 - option -> play Locally
In Gama, choose under your User Models/LittoSIM folder the folder "Models", then double click on "LittoSIM-GEN Player.gaml"
Click on the green button ">LittoSIM-GEN_Player"
On the top menu, above the map, "Click on the green Play Button"
Play!!

## STEP 2 - option -> connect to a remote Manager and play remotly
(we assume that someone has a launched littosim/manager remotly and has provided you with IP address)
### Specify the IP address
In Gama, choose under your User Models/LittoSIM folder the folder "Includes/config", then double click on "littosim.conf"
In line "SERVER_ADDRESS;localhost;", replace "localhost",  by "192.168.1.100" (or other IP address provided by the LittoSIM-Manager)
Save this modification by "right click/ save ", or ctrl+S
### Launch LittoSIM player
In Gama, choose under your User Models/LittoSIM folder the folder "Models", then double click on "LittoSIM-GEN Player.gaml"
Click on the green button ">LittoSIM-GEN_Player"
On the top menu, above the map, "Click on the green Play Button"
Play!!
