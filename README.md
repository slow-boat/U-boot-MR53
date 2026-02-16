
# U-boot (with network) for Meraki MR53

This is source code taken from here (thanks [Hal Martin](https://github.com/halmartin) ) where he made [a great start](https://github.com/halmartin/meraki-openwrt-docs/tree/main/mr53). His u-boot.itb file works great- it brings up the GBe port so tftpboot works fine.

However, he [declared](https://forum.openwrt.org/t/adding-openwrt-support-for-meraki-mr53/67505/38)that he was done with it. Not surprising since its tedious work reverse engineering... there are only so many puzzles we have time to solve.

Big thanks to all the other guys on that [Openwrt thread](https://forum.openwrt.org/t/adding-openwrt-support-for-meraki-mr53/67505/1) that contributed so far.

This repo is my attempt at making a convenient development u-boot for the MR53, so we can speed up the hacking cycle.

## Mods:
- modified ubootwrite-cryptid.py initial uploading image via serial, or getting console access from meraki bootloader.
- modified u-boot source with working networking, and initially, boot to console.
- tarball of toolchain needed to cross compile this u-boot.

## Provisioning for development:
MR53s are now e-waste, so no problems blowing away Meraki firmware.

### prerequisites
- python3
- pyserial
- picocom (or similar tool for accessing serial port)
- 3.3V level USB-serial adapter soldered onto the MR53 serial pads.
	- avoid adapters with strong bus hold... these seem to not work.
	- I bought some really cheap ones with IDC flying leads that were like this. Fail.
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
If we want to be bold, skip the next step and write it straight to nand...
#### boot our new u-boot
```
bootm 0x42000000#config@3
```
- now we can get our itb file back over network to put into RAM:
  (adjust IP addresses for mr53 and your tftpserver which serves the new u-boot.itb)
```
setenv ipaddr 10.4.0.141; setenv serverip 10.4.0.140; tftpboot 0x42000000 u-boot.itb
```
#### replace bootkernel2 with our u-boot
```
setenv mtdids nand0=nand0; setenv mtdparts mtdparts=nand0:0x40000@0x2c40000(bootkernel2); nand erase.part bootkernel2;
nand write 0x42000000 bootkernel2 0x40000
reset
```
- this should first boot the Meraki uboot, which loads out itb from NAND at 0x2c40000 and boots our new u-boot into console with networking.

If we know our itb is OK, we can probably just load it into NAND from the very first loading via ubootwrite-cryptid.py via the meraki uboot. This will save a bit of time.

## Load new itbs to try
set your IPs up, and put your .itb file into your tftp server...
```
setenv ipaddr 10.4.0.141; setenv serverip 10.4.0.140; tftpboot 0x42000000 mr53linux.itb; bootm 0x42000000#config@3
```
note that the fit file should have config@3 defined since the goal is to eventually boot our openwrt image straight from the Meraki uboot.

## BUILD
- assumes we are on x86_64 linux host... extract toolchain:
```
wget https://releases.linaro.org/archive/14.04/components/toolchain/binaries/gcc-linaro-arm-none-eabi-4.8-2014.04_linux.tar.xz
tar -xf gcc-linaro-arm-none-eabi-4.8-2014.04_linux.tar.xz
```
- **build it**
```
export CROSS_COMPILE=gcc-linaro-arm-none-eabi-4.8-2014.04_linux/bin/arm-none-eabi-
make cryptid_defconfig
make
```
...and we have u-boot.itb for mr53
# Background of the mission:
- bought 4x MR53s a few years ago for peanuts thinking "how hard could it be?"
- Used ghidra to decompile [Hal Martin's](https://github.com/halmartin)itb file and find the missing switch init calls.
- modified u-boot build so it just works and gives us a shiny meraki u-boot compatible .itb

## Next steps:
Openwrt integration... thats another repo coming soon.