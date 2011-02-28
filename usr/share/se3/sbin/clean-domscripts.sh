#!/bin/bash

/usr/share/se3/sbin/update-share.sh -r netlogon logonpy.sh
/usr/share/se3/sbin/update-share.sh -r profiles logonpy-gpo.sh
rm -rf /etc/se3/python
rm -rf /usr/share/se3/logonpy
