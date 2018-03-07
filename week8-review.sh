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
read -p "Press Enter when you're ready to begin!"
echo

clear

#Using variables and current date to make a directory and populate it with subfolders
#These folders will be used for logs, backups, and anything else the script wants to save.
echo "First the directory $name will be made in the ~home directory."
echo "Next directories ~/$name/Data and ~/$name/Data/$(date +%B%d) will be made."
echo "These directories will be where most commands focus output."

#By Using the mkdir -p (Parent) flag I will make all directories at once. I will then use
#ls with the -d (directory) flag and * wildcard to list the newly created directories.
mkdir -p ${name}/Data/$(date +%B%d)

echo
echo "List of our new directories - "
cd ~
ls -ld $name $name/* $name/*/*; echo


#Now I would like to gather hardware and software information using different commands
#and output them all to the same file and format it along the way so its easier to read.

echo "Using multiple commands to output various computer hardware and software information"
echo "to a file named compinfo.txt. Then pipe the data to the | less commmand."
echo; echo "Remember pressing Shift+Q at the same time will exit the less view."
echo; read -p "Press Enter when you're ready to continue."

echo "Computer Information -" > compinfo.txt; echo >> compinfo.txt
echo "[Operating System Release]" >> compinfo.txt; uname -vrm >> compinfo.txt; echo >> compinfo.txt
echo "[Kernel Name]" >> compinfo.txt; uname -s >> compinfo.txt; echo >> compinfo.txt
echo "[Username]" >> compinfo.txt; whoami >> compinfo.txt; echo >> compinfo.txt
echo "[CPU Model Info]" >> compinfo.txt; lscpu | grep -i 'model name\|MHz' >> compinfo.txt
echo -n "CPU Cores:           " >> compinfo.txt; nproc >> compinfo.txt; echo >> compinfo.txt

# The ramsize is returned in a kilobyte value and I want to convert it to gigabytes. I will assign the trimmed output of vmstat
#to a variable and then use the expr command to devide the variable with to get an approximate GB ram size.
echo "[RAM]" >> compinfo.txt; ram=$(vmstat -s | grep -i 'total m' | tr -dc 0-9); ramgb=$(expr $ram / 1024000)
echo "RAM Total in kilobytes: $ram" >> compinfo.txt; echo "RAM Total in gigabytes: $ramgb (Approximate)" >> compinfo.txt
freeram=$(vmstat -s | grep -i 'free m' | tr -dc 0-9); freeramgb=$(expr $freeram / 1024000)
echo "RAM Free in kilobytes: $freeram" >> compinfo.txt; echo "RAM Free in gigabytes: $freeramgb (Approximate)" >> compinfo.txt; echo >> compinfo.txt
echo "[Video Adapter And Display]" >> compinfo.txt; lspci | grep -i 'VGA\|3D' | cut -d" " -f 2-15 >> compinfo.txt; echo >> compinfo.txt
xrandr | grep -i 'disconnected\|connected\|*' >> compinfo.txt; echo >> compinfo.txt
echo "[Disks Information]" >> compinfo.txt
lsblk -o NAME,MODEL,LABEL,SIZE,TYPE,FSTYPE,MOUNTPOINT >> compinfo.txt; echo >> compinfo.txt; echo "[USB Devices]" >> compinfo.txt
lsusb >> compinfo.txt; echo >> compinfo.txt;

mv compinfo.txt $name/Data/
cat $name/Data/compinfo.txt | less -P "Use Space and b to scroll. Press Shift+Q to close"
echo
clear

echo "First using journalctl with the --priority=err flag we will display all error messages and above in the logs."
echo "Then using dmesg | grep Error to see if we get the same results."
echo "I am going to output the commands to two seperate files and run the diff command"

sudo journalctl --priority=err > $name/Data/journalerrorlogs.txt
dmesg | grep -i "Error" > $name/Data/dmesgerrorlogs.txt


read -p "Press Enter when you're ready to run the diff command."
diff -c $name/Data/journalerrorlogs.txt $name/Data/dmesgerrorlogs.txt | less -P "Use Space and b to scroll. Shift+Q to close"
echo

clear
#This one took a few hours of hair pulling but I finally got it working how I wanted it.
#Going to make and start a service to monitor udev and kernel events then make a file system and mount it.
#I may also plug in another usb drive to populate more events in the log.
#The service should log the changes with journald. I will then unmount it  and show the changes that udevad monitor found

echo "Creating a service to monitor kernel and udev events with udevadm monitor."
echo "You may be prompted for a sudo password multiple times during the process of creating, moving, and starting the service."
echo; read -p "Press Enter when you're ready to start the process."

#This might not work on other distros. Use ExecStart=/sbin/udevadm for Debian.
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
cd

echo "The compinfo.txt contents should of been visible part way down the hexdump."
echo "The newly created service has been stopped. The command journalctl is used to check the log to see the gathered data."
echo; echo "As always pressing Shift+Q at the same time will exit the less view."
echo; read -p "Press Enter when you're ready to view the UdevadmMonitor.service log. "
sudo journalctl --unit=UdevadmMonitor.service | less -P "Use Space and b to scroll. Press Shift+Q to close";
sudo journalctl --unit=UdevadmMonitor.service > $name/Data/UdevadmMonitor.log
echo; echo "Although they're hard to decipher, multiple events should've been captured."
echo "Some systemd units have symbolic links to different names for what appears to be compatability reasons."
echo "With grep to filter an ls command all the links in the /lib/systemd/system/ will appear."
read -p "Press Enter when youre ready to continue."
ls -la /lib/systemd/system/ | grep "\->" | less -p "Press Shift+Q to exit"; echo

clear

#The goal here is to archive and zip the contents of $name/Data/ and move the archive to the Data/*Currentdate*
#Once that is done the original files will be removed. 
echo "Current contents of $name/Data/ - "
ls -l $name/Data/; echo

echo "Archiving and compressing contents to $(date +%B%d)bak.tar.gz"; echo "Moving compressed archive to $name/Data/$(date +%B%d)"
echo "Clearing files out of $name/Data/ "
cd $name/Data/; tar cvf $(date +%B%d)bak.tar compinfo.txt journalerrorlogs.txt dmesgerrorlogs.txt UdevadmMonitor.log hexdump.txt
gzip $(date +%B%d)bak.tar ; mv $(date +%B%d)bak.tar.gz $(date +%B%d)/
rm compinfo.txt journalerrorlogs.txt dmesgerrorlogs.txt testimage.img UdevadmMonitor.log hexdump.txt 
cd
#removing and refreshing systemd services
sudo rm /etc/systemd/system/UdevadmMonitor.service; systemctl daemon-reload
echo; echo "Current contents of $name/Data and $name/Data/$(date +%B%d)"
ls -l $name/Data/ $name/Data/$(date +%B%d)
echo
echo "This is the end of the script. I hope you found it informative and helpful."; echo
echo "If you have any issues you want to open please do it at github.com/luschool"
