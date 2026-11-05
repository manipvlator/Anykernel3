### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=sweet
device.name2=sweetin
supported.versions=11 - 17
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

choose_90hz() {
  local ge line pid wd key fifo;
  if [ "$BOOTMODE" = true ]; then
    ui_print "! App install: the 90Hz menu is only available in recovery";
    ui_print "! Using the stock DTBO";
    return 1;
  fi;
  if [ ! -f "$AKHOME/dtbo-90hz.img" ]; then
    ui_print "! dtbo-90hz.img is missing from this ZIP";
    ui_print "! Using the stock DTBO";
    return 1;
  fi;
  ge="";
  for ge in /sbin/getevent /system/bin/getevent /system/xbin/getevent /vendor/bin/getevent "$(command -v getevent 2>/dev/null)"; do
    [ -x "$ge" ] && break;
  done;
  if [ ! -x "$ge" ]; then
    ui_print "! getevent is not available in this recovery";
    ui_print "! Cannot read the volume keys, using the stock DTBO";
    return 1;
  fi;
  ui_print " ";
  ui_print "Volume Up   = 90Hz";
  ui_print "Volume Down = stock";
  ui_print "Press a volume key now (10s timeout)...";
  ui_print " ";
  fifo="$AKHOME/.ak3-key.$$";
  rm -f "$fifo";
  if ! "$BIN/busybox" mkfifo "$fifo" 2>/dev/null; then
    ui_print "! Cannot create the input pipe, using the stock DTBO";
    return 1;
  fi;
  # Read the event stream line by line so a key press is handled at once
  # instead of waiting for getevent to hit the timeout.
  "$ge" >"$fifo" 2>/dev/null &
  pid=$!;
  ( "$BIN/busybox" sleep 10; kill "$pid" 2>/dev/null ) &
  wd=$!;
  key="";
  while IFS= read -r line; do
    case "$line" in
      *VOLUMEUP*|*"0001 0073 "*) key=up; break;;
      *VOLUMEDOWN*|*"0001 0072 "*) key=down; break;;
    esac;
  done <"$fifo";
  kill "$pid" "$wd" 2>/dev/null;
  wait "$pid" 2>/dev/null;
  rm -f "$fifo";
  [ "$key" = "up" ];
}

# boot install
dump_boot;
cd $AKHOME;

if choose_90hz; then
  mv -f dtbo-90hz.img dtbo.img;
  ui_print "- 90Hz DTBO selected";
else
  rm -f dtbo-90hz.img;
  ui_print "- Stock DTBO selected";
fi;

write_boot;
## end boot install
