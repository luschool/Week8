#!/bin/bash
# This script was made in arch linux. A few compadibility issues with other distros that I'm working on.

#Clear the current terminal and move to the ~home directory
clear
cd ~

#Ask user for name input and have second variable to save any data past the first word
#to ensure a single word is saved in the name variable
echo "Hello what is your first name?"
read -p "First Name: " name unwanted
echo

echo -n "Hello $name, I hope you're having a wonderful " && date +%A' '%B%e
echo 
echo -e "This script is intended to be as user friendly as possible. Each step and process \
\nshould have clear directions and output.\
\n \nIf you have any issues or questions please open an issue on github.com/luschool"; echo

#This will stop the script from executing to allow the user to read the text and 
#continuing when ready. Since no variable is assigned to the read command it saves no input
read -p "Press Enter when You're ready to begin!"
echo

clear

#Using variables and current date to make a directory and populate it with subfolders
#These folders will be used for logs, backups, and anything else the script wants to save.
echo "First it will make the directory $name in your ~home directory."
echo "Next it makes directories ~/$name/Data and ~/$name/Data/$(date +%B%d)"
echo "These directories will be where we focus most of our outputs and commands."

#By Using the mkdir -p (Parent) flag I will make all directories at once. I will then use
#ls with the -d (directory) flag and * wildcard to list the newly created directories.
mkdir -p ${name}/Data/$(date +%B%d)

echo
echo "Now I will list the new directories I just made - "
cd ~
ls -ld $name $name/* $name/*/*; echo


#Now I would like to gather hardware and software information using different commands
#and output them all to the same file and format it along the way so its easier to read.

echo "Using multiple commands I will output various computer hardware and software information"
echo "to a file named compinfo.txt. Then I will pipe the data using the | less commmand."
echo; echo "Don't forget that pressing Shift+Q at the same time will exit the less view."
echo; read -p "Press Enter when you're ready to continue."

echo -e "Computer Information -" > compinfo.txt; echo >> compinfo.txt
echo "[Operating System Release]" >> compinfo.txt; uname -vrm >> compinfo.txt; echo >> compinfo.txt
echo "[Kernel Name]" >> compinfo.txt; uname -s >> compinfo.txt; echo >> compinfo.txt
echo "[Username]" >> compinfo.txt; whoami >> compinfo.txt; echo >> compinfo.txt
echo "[CPU Model Info]" >> compinfo.txt; lscpu | grep -i 'model name\|MHz' >> compinfo.txt
echo -n "CPU Cores:           " >> compinfo.txt; nproc >> compinfo.txt; echo >> compinfo.txt;

# The ramsize is returned in a kilobyte value and I want to convert it to gigabytes. I will assign the trimmed output of vmstat
#to a variable and then use the expr command to devide the variable with to get an approximate GB ram size.
echo "[RAM]" >> compinfo.txt; ram=$(vmstat -s | grep -i 'total m' | tr -dc 0-9); ramgb=$(expr $ram / 1024000)
echo "RAM Total in kilobytes: $ram" >> compinfo.txt; echo "RAM Total in gigabytes: $ramgb (Approximate)" >> compinfo.txt
freeram=$(vmstat -s | grep -i 'free m' | tr -dc 0-9); freeramgb=$(expr $freeram / 1024000)
echo "RAM Free in kilobytes: $freeram" >> compinfo.txt; echo "RAM Free in gigabytes: $freeramgb" >> compinfo.txt; echo >> compinfo.txt
echo "[Video Adapter And Display]" >> compinfo.txt; lspci | grep -i 'VGA\|3D' | cut -d" " -f 2-15 >> compinfo.txt; echo >> compinfo.txt
xrandr | grep -i 'disconnected\|connected\|*' >> compinfo.txt; echo >> compinfo.txt
echo "[Disks Information]" >> compinfo.txt
lsblk -o NAME,MODEL,LABEL,SIZE,TYPE,FSTYPE,MOUNTPOINT >> compinfo.txt; echo >> compinfo.txt; echo "[USB Devices]" >> compinfo.txt
lsusb >> compinfo.txt; echo >> compinfo.txt;

mv compinfo.txt $name/Data/
cat $name/Data/compinfo.txt | less -P "Use Space and b to scroll. Press Shift+Q to close"
echo
clear


echo "First a search for domain name and related info in the NetworkManager.service log through two methods."
echo "Commands journalctl and systemctl status show log info. However journalctl shows everything and systemctl status"
echo "only shows the most recent entries to the file."; echo
echo "I am going to output the commands to two seperate files and also show the data here. I will then run the diff command"
echo "to compare the differences(If any)."

journalctl _SYSTEMD_UNIT=NetworkManager.service | grep -m 1 -C 1 'domain name' > $name/Data/journalnetman.txt
systemctl status NetworkManager.service | grep -m 1 -C 1 'domain name' > $name/Data/systemctlstatusnetman.txt
echo; echo "First lets view the systemctl status info - "; cat $name/Data/systemctlstatusnetman.txt
echo; echo "Now lets view the journalctl early log entries - "; cat $name/Data/journalnetman.txt; echo

echo "You should be able to see any differences with the naked eye, but either way lets run a diff command to compare."
diff -c $name/Data/systemctlstatusnetman.txt $name/Data/journalnetman.txt; echo
read -p "Press Enter when you're ready to continue."
clear
#This one took a few hours of hair pulling but I finally got it working how I wanted it.
#Going to make and start a service to monitor udev and kernel events then make a file system and mount it.
#I may also plug in another usb drive to populate more events in the log.
#The service should log the changes with journald. I will then unmount it  and show the changes that udevad monitor found

echo "Creating a service to monitor kernel and udev events with udevadm monitor."
echo "You may be prompted for a sudo password multiple times during the process of creating, moving, and starting the service."
echo; read -p "Press Enter when you're ready to start the process."

echo "[Unit]" > UdevadmMonitor.service; echo "Description=Monitor udev and kernel events" >> UdevadmMonitor.service
echo >> UdevadmMonitor.service; echo "[Service]" >> UdevadmMonitor.service
echo "ExecStart=/usr/bin/udevadm monitor" >> UdevadmMonitor.service; chmod +x UdevadmMonitor.service;
sudo mv UdevadmMonitor.service /etc/systemd/system; systemctl start UdevadmMonitor.service; systemctl status UdevadmMonitor.service
echo; echo "As you can see we now have a working service using udevadm."; echo

echo "Using commands like dd , mkfs , and mount a blankimage.img will be created and mounted to $name/Data/filesysmnt/tmp "
echo "This should make events in the kernel and udev for the newly created service to gather."
echo "The compinfo.txt file that was created earlier will be copied to the mount location"; echo
echo "Expect a few more password prompts."; read -p "Press Enter when you're ready to continue."

mkdir -p $name/Data/filesysmnt/tmp; dd if=/dev/zero of=~/$name/Data/testimage.img bs=1M count=24; mkfs -t ext4 ~/$name/Data/testimage.img
cd $name/Data ; sudo mount testimage.img filesysmnt/tmp; echo "Our new mount -"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep -i "filesys\|NAME"; sudo cp compinfo.txt filesysmnt/tmp/compinfo.txt;
sudo umount filesysmnt/tmp; rm -r filesysmnt/; systemctl stop UdevadmMonitor.service

echo "Directory filesysmnt/tmp/ has been unmounted. Running hexdump of imagefile.img to see if it contains the compinfo.txt data."
echo "As always pressing Shift+Q at the same time will exit the less view."; echo; read -p "Press Enter when you're ready to view the hexdump: "
clear
hexdump -C testimage.img | less -P "Use Space and b to scroll. Press Shift+Q to close" ; hexdump -C testimage.img > hexdump.txt
dmesg | grep -i "Command " > dmesgcommandline.txt
cd

echo "The compinfo.txt contents should of been visible part way down the hexdump."
echo "The newly created service has been stopped. The command journalctl is used to check the log to see the gathered data."
echo; echo "As always pressing Shift+Q at the same time will exit the less view."
echo; read -p "Press Enter when you're ready to view the UdevadmMonitor.service log. "
journalctl --unit=UdevadmMonitor.service | less -P "Use Space and b to scroll. Press Shift+Q to close";
journalctl --unit=UdevadmMonitor.service > $name/Data/UdevadmMonitor.log
echo; echo "Although they're hard to decipher, multiple events should've been captured."
echo "Some systemd units have symbolic links to different names for what appears to be compatability reasons."
echo "With grep to filter an ls command all the links in the /usr/lib/systemd/system/ will appear -"
ls -la /usr/lib/systemd/system/ | grep "\->"; echo

read -P "Press Enter when you're ready to continue."
clear

#The goal here is to archive and zip the contents of $name/Data/ and move the archive to the Data/*Currentdate*
#Once that is done the original files will be removed. 
echo "Current contents of $name/Data/ - "
ls -l $name/Data/; echo

echo "Archiving and compressing contents to $(date +%B%d)bak.tar.gz"; echo "Moving compressed archive to $name/Data/$(date +%B%d)"
echo "Clearing files out of $name/Data/ "
cd $name/Data/; tar cvf $(date +%B%d)bak.tar compinfo.txt journalnetman.txt systemctlstatusnetman.txt UdevadmMonitor.log hexdump.txt dmesgcommandline.txt
gzip $(date +%B%d)bak.tar ; mv $(date +%B%d)bak.tar.gz $(date +%B%d)/
rm compinfo.txt journalnetman.txt systemctlstatusnetman.txt testimage.img UdevadmMonitor.log hexdump.txt dmesgcommandline.txt
cd
#removing and refreshing systemd services
sudo rm /etc/systemd/system/UdevadmMonitor.service; systemctl daemon-reload
echo; echo "Current contents of $name/Data and $name/Data/$(date +%B%d)"
ls -l $name/Data/ $name/Data/$(date +%B%d)
echo
echo "This is the end of the script. I hope you found it informative and helpful."; echo
echo "If you have any issues you want to open please do it at github.com/luschool"; echo
