Notes to self:

you can build this firmware by running the following at the root of the repo
```
just \  test_keymap=keymap-48key-checkkeys \  dest_dir="firmware/ch32x035-usb-device-compositekm-c/libsmartkeymap/" \
  install && \
just firmware/ch32x035-usb-device-compositekm-c/flash
```


This is how to build the firmware with ARTSEY
```
just \
  test_keymap=keymap-9key-artseyio \
  dest_dir="firmware/ch32x035-usb-device-compositekm-c/libsmartkeymap/" \
  install && \
just firmware/ch32x035-usb-device-compositekm-c/flash
```