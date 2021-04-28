#!/bin/bash -eux
export DEBIAN_FRONTEND=noninteractive

# Memory and swap accounting require kernel command line parms
# for newer Ubuntu kernels

# The grub2 configuration is in /etc/default/grub
if [ -f /etc/default/grub ]; then
    sed -i -e 's/^GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/' /etc/default/grub
fi

# Update the grub configuration
/usr/sbin/update-grub
exit 0
