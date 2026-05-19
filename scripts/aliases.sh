# Admin workstation aliases (~/.bashrc on aeglero-admin)
# Admin is on VLAN 20 (10.20.20.0/24), AI server is on VLAN 10.
# All inter-VLAN traffic routes through aegis (Pi).

alias server="ssh <user>@10.10.10.10"
alias down="ssh -t <user>@10.10.10.10 'sudo shutdown -h now'"
alias aegis="ssh -p 2222 <user>@10.20.20.1"
alias wake="ssh -p 2222 <user>@10.20.20.1 '~/wake-server.sh'"

# Note: admin is on VLAN 20,
# AI server is on VLAN 10, broadcasts don't cross. The 'wake' alias
# SSHes into aegis and runs the wake script there, which broadcasts
# the magic packet on the VLAN 10 segment.


# Aegis (Pi) aliases (~/.bashrc on aegis)
# Pi has direct eth1.10 access to the AI server's VLAN.

alias wake="~/wake-server.sh"
alias server="ssh <user>@10.10.10.10"
alias down="ssh -t <user>@10.10.10.10 'sudo shutdown -h now'"
