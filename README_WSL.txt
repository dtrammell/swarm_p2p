WSL2 Swarm Install For x64 Windows 10:

Reference docs (return to if needed):
https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-4---download-the-linux-kernel-update-package
https://www.poftut.com/generate-rsa-keys-ssh-keygen/
Broken store?: https://answers.microsoft.com/en-us/windows/forum/windows_10-windows_store/why-is-my-microsoft-store-not-working/affc564f-edb4-41b9-b1b2-4b9cbca2ca65


1.> Open Power Shell (Admin) and enter the following (keep this window open).
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

2.> In Power shell, type “winver” and verify “Version 1903 or higher, with Build 18362 or higher.”  If version is below, update windows.

3.> In Power shell:
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

4.> Now reboot!

5.> Open Power Shell (Admin) and enter the following (keep this window open)
wsl --set-default-version 2

If you get an error on WSL kernel, upgrade via this URL: https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi

When done, repeat the command:
wsl --set-default-version 2

6.> Install Ubuntu:  https://www.microsoft.com/en-us/p/ubuntu-2004-lts/9n6svws3rx71?rtc=1&activetab=pivot:overviewtab

7.> Back in power shell, enter:
ubuntu2004

8.> Now you should have linux prompt!  Woot.  Run the following commands:

sudo apt git
sudo apt update
sudo apt install gcc
sudo apt install g++
sudo apt install make
sudo apt install pacman
sudo apt install ruby
sudo apt install ruby-dev
sudo apt install libruby2.7
sudo apt install sqlite3
sudo apt install libsqlite3-dev

9.> Now your linux should have the necessary tools and headers.  Now run:
ssh-keygen -t RSA
cat .ssh/id_rsa.pub

10.> You will now see a public key.  Add that key into your github account. Settings -> SSH and GPG keys -> New SSH Key.  Give it a title and paste the output from “cat .ssh/id_rsa.pub” into the key box.

11.> Back at the ubuntu prompt (was the power shell prompt):
git clone git@github.com:dtrammell/swarm_p2p.git

12.> Go into the swarm directory:
cd swarm_p2p/

13.> Edit the Gemfile and .gemspec (trying to figure out how to not require this step):
vim Gemfile
    Remove comment from the line below so it doesn’t start with #:
         # gem 'sqlite3', git: "https://github.com/sparklemotion/sqlite3-ruby
vim swarm_p2p.gemspec
    Comment out the line below so it looks like this (and starts with #):
# ['sqlite3','~> 1.4'],

14.> Update/Install required ruby gems
sudo gem install sqlite3 --platform=ruby
sudo gem install bundler
bundle update

15.> Run the queen and hopefully it will run and leave you with a command prompt.
ruby ./examples/bee_service.rb

16.> Now, open another terminal, run ubuntu2004, and run the following:
ruby ./examples/bee_irb.rb 1 0

16.> Now, open another terminal, run ubuntu2004, and run the following:
ruby ./examples/bee_irb.rb 1 1

17.> If worked, you will be back at a command prompt in the last client that looks sorta like:
irb(main):???> 
Type in:
irb(main):???> @bee.broadcast("Some Message Here")

18.> You should see the other client report the broadcast message.


