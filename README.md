# U-boot (with network) for Meraki MR53

This is source code taken from here (thanks [Hal Martin](https://github.com/halmartin) ) and his work on getting ethernet going in the bootloader.

This version is destructive for existing meraki nand layout, but sets us up for easy provisioning.

Big thanks to all the other guys on that [Openwrt thread](https://forum.openwrt.org/t/adding-openwrt-support-for-meraki-mr53/67505/1) that contributed so far.
## Mods:
- modified ubootwrite-cryptid.py initial uploading image via serial, or getting console access from meraki bootloader.
- modified u-boot source with working networking
- build environment setup `. build.sh`
	- this will install the required gcc cross compiler to /opt if missing
	- run `makemr53` to do a clean .itb build
- latest u-boot.itb included here so you don't need to build it

## New u-boot commands:
### `run provision_all` 
Installs  `u-boot.itb` and `mr53-factory.bin` from your tftp server into nand. Do this after fist loading the u-boot.itb via `ubootwrite-cryptid.py` over serial port. Run `boot` to start the new image from nand.

You need to set up your IP addresses first- for example
```
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.254
run provision_all
boot
```
### `run provision_uboot`
- install `u-boot.itb` into `bootkernel1` and `bootkernel2` mtd partitions. Run `reset` to reboot the bootloader into our new one via nand.
```
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.254
run provision_uboot
reset
```
### `run provision_ubi`
- install  `mr53-factory.bin` into mtd `ubi` part. Run `boot` to start it
```
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.254
run provision_ubi
boot
```
### run tftpbootfit
- download and boot `mr53linux.itb` from tftp server- doesn't touch flash. Useful for development.
```
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.254
run tftpbootfit
```
## Using serial loader for initial uboot provisioning
MR53s are now e-waste, so no problems blowing away Meraki firmware.

### prerequisites
- 3.3V level USB-serial adapter soldered onto the MR53 serial pads.
	- avoid adapters with strong bus hold... these seem to not work.
	- I bought some really cheap ones with IDC flying leads that were like this. Fail.
- build dependencies (assuming debian environment)
```
sudo apt install build-essential gcc make \
    libssl-dev \
    python3 python3-dev python3-setuptools python3-serial \
    bc
```
### process
- Run this- it will put the u-boot.itb into RAM at 0x42000000.
	 **This is painfully slow... ~10minutes!**
```
python3 ubootwrite-cryptid.py --verbose --write=u-boot.itb
```
- when this is finished, we can access the serial console, eg:
```
picocom -b115200 /dev/ttyUSB0
```
**to exit picocom- *`ctrl-a-q`****

Boot into our new uboot:
```
bootm 0x42000000#config@3
```
Then follow the provisioning steps above- make sure the tftp server is up etc and run `run provision_all` in the console.
# Background of the mission:
- bought 4x MR53s a few years ago for peanuts thinking "how hard could it be?"
- Used ghidra to decompile [Hal Martin's](https://github.com/halmartin)itb file and find the missing switch init calls.
- then he appeared again (yay) and shared his patches- which revealed missing phy reset and the gmac1 to gmac3 init, and the source of the magic switch setup.
- modified u-boot build so it just works and gives us a shiny meraki u-boot compatible .itb and convenient bridge into openwrt land
## Next steps:
Openwrt integration... thats another repo coming *very* soon.
