# Jordan's Scripts
A collection of Jordan's bash scripts that he's produced over the years for a
variety of purposes.

## gifme.sh (bash)
This script was made in order to try and produce small, sharable GIFs that came
out of an NLE much faster - There's no hard and fast way to generate small GIFs
(as it does depend on the content), but this was my quick and easy way to do it.

## gitlab_users.epp (python via puppet template)
A Puppet template that I created to:

* Generate a Python script to then;
* Generate a YAML file with the group membership information and SSH key data
from a self-hosted GitLab instance; then
* Feed that data into Hiera for use in access control mechanisms on VMs.

## levels.sh (bash)
A script I made to control audio levels on systems that used amixer to control
system audio levels.