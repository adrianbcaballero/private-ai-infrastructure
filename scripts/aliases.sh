# Desktop aliases (~/.bashrc)
alias wake="python -c \"from wakeonlan import send_magic_packet; send_magic_packet('e0:d5:5e:68:7d:69', ip_address='192.168.1.255')\""
alias server="ssh sysadmin@192.168.1.XXX"
alias down="ssh -t sysadmin@192.168.1.XXX 'sudo shutdown -h now'"
alias aegis="ssh -p 2222 sysadmin@192.168.1.XXX"
alias wakeremote="ssh -p 2222 sysadmin@192.168.1.XXX '~/wake-server.sh'"

# Aegis aliases (~/.bashrc)
alias wake="~/wake-server.sh"
alias server="ssh sysadmin@192.168.1.XXX"
alias down="ssh -t sysadmin@192.168.1.XXX 'sudo shutdown -h now'"