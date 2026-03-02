============================================================
  MARKET MONITOR — Setup Instructions
============================================================

REQUIREMENTS
------------
  - Bloomberg Terminal installed and running on this PC
  - Internet connection
  - Your Market Monitor username and password
    (visit https://your-app.vercel.app/register if needed)

FIRST TIME SETUP (do this once)
--------------------------------
  1. Download this repository as a ZIP from GitHub:
     - Click the green "Code" button
     - Select "Download ZIP"
     - Extract to a permanent location e.g.
       C:\Users\YourName\MarketMonitor\

  2. Open Bloomberg Terminal and log in fully

  3. Double-click SETUP.bat and follow the prompts
     - It will find Python and Bloomberg API automatically
     - You will only be asked for your username and password
     - Takes 2-5 minutes on first run

DAILY USE
---------
  1. Open Bloomberg Terminal and log in
  2. Double-click START.bat
  3. Your browser will open automatically
  4. Log in with your Market Monitor credentials

STOPPING
--------
  Double-click STOP.bat, or just close the START.bat window.

SWITCHING BETWEEN PCs
---------------------
  Run SETUP.bat once on each PC you want to use.
  After that, just START.bat each day on whichever
  PC has Bloomberg Terminal open.

TROUBLESHOOTING
---------------
  App not loading?
    - Make sure Bloomberg Terminal is open and logged in
    - Wait 15 seconds after START.bat before opening the app
    - Check the logs\ folder for details

  Setup failed?
    - Make sure you have an internet connection
    - Make sure Bloomberg Terminal is open during setup
    - Email logs\setup.log to: support@your-app.com

============================================================
  FILES IN THIS PACKAGE
============================================================

  SETUP.bat    — Run once on each PC
  START.bat    — Run daily before using the app
  STOP.bat     — Cleanly stops everything
  README.txt   — This file
  backend\     — Market Monitor server (do not modify)
  logs\        — Log files for troubleshooting

============================================================
