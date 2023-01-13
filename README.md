# Code runs on Hammerspoon Application

## What does it do?

This is the init file which is used from the Hammerspoon application. Currently, it is checking if given VPN applications are running when opening up or activating windows from the application Citrix

## What is Hammerspoon?

Hammerspoon is a tool for powerful automation of OS X. At its core, Hammerspoon is just a bridge between the operating system and a Lua scripting engine.

What gives Hammerspoon its power is a set of extensions that expose specific pieces of system functionality, to the user. With these, you can write Lua scripts to control many aspects of your OS X environment.

## Prerequisite
### Install Hammerspoon

#### Manually
 * Download the [latest release](https://github.com/Hammerspoon/hammerspoon/releases/latest)
 * Drag `Hammerspoon.app` from your `Downloads` folder to `Applications`

#### Homebrew
  * `brew install hammerspoon --cask`
  
## From this Repository

Add the init.lua file from this repository to  `~/.hammerspoon/init.lua` and add more useful code. 
