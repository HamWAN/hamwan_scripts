#!/usr/bin/env python
#
# Copyright 2013 Tom Hayward <tom@tomh.us>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import paramiko
import socket
import sys

edge_router_ip = "198.178.136.80"
wan_router_ip ="192.178.136.80"
ssh_port = 22
username = ""
hamwan_dstaddresses = ["44.24.240.0/20", ]
hamwan_gateways = ["198.178.136.80", ]


def expand_cidr(short):
    ip, mask = short.split("/")
    ip = ip.split(".") + ["0"] * 4
    return "%s/%s" % (".".join(ip[0:4]), mask)


def test_expand_cidr():
    tests = [
        ("1.2/24", "1.2.0.0/24"),
        ("1.2.3/24", "1.2.3.0/24"),
    ]
    for short, expanded in tests:
        assert expand_cidr(short) == expanded


def parse_encap(line):
    if line.startswith("#"):
        return False

    route, addprivate, dstaddress, encap, gateway = line.split(" ")
    dstaddress = expand_cidr(dstaddress)
    gateway = gateway.strip()
    if (route, addprivate, encap) != ("route", "addprivate", "encap"):
        raise ValueError("Unknown line format:", line)

    if (dstaddress in hamwan_dstaddresses) or (gateway in hamwan_gateways):
        return False

    # return "/ip route add dst-address=%s gateway=ampr-%s" % (
    #     dstaddress, gateway)
    return (dstaddress, gateway)


def parse_ros_route(line):
    dstaddress, gateway = None, None
    for field in line.split(" "):
        try:
            param, val = field.split("=")
        except ValueError:
            continue
        if param == "dst-address":
            dstaddress = val
        elif param == "gateway" and val.startswith("ampr-"):
            gateway = val

    if dstaddress and gateway:
        return (dstaddress, gateway)
    else:
        return None


def parse_ros_ipip(line):
    name, remoteaddr = None, None
    for field in line.split(" "):
        try:
            param, val = field.split("=")
        except ValueError:
            continue
        if param == "name" and val.startswith("ampr-"):
            name = val
        elif param == "remote-address":
            remoteaddr = val

    if name and remoteaddr:
        return name, remoteaddr
    else:
        return None


def export_ros(ssh, command):
    stdin, stdout, stderr = ssh.exec_command(command)
    export = stdout.read()
    export = export.replace("\\\r\n    ", "")  # collapse line breaks
    return export.splitlines()


def export_ros_routes(ssh):
    return filter(None, map(parse_ros_route,
                            export_ros(ssh, "/ip route export")))


def export_ros_ipip_interfaces(ssh):
    return filter(None, map(parse_ros_ipip,
                            export_ros(ssh, "/interface ipip export")))


def main():
    encap_routes = filter(None, map(parse_encap, sys.stdin))

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(edge_router_ip, ssh_port, username)
        ros_routes = export_ros_routes(ssh)
        ros_ipips = export_ros_ipip_interfaces(ssh)

        unchanged = 0
        routes_to_add = set(encap_routes)
        routes_to_remove = list(ros_routes)
        ipips_to_remove = list(ros_ipips)
        for (dstaddress, gateway) in encap_routes:
            interface = "ampr-%s" % gateway
            if (dstaddress, interface) in ros_routes and \
               (interface, gateway) in ros_ipips:
                routes_to_add.remove((dstaddress, gateway))
                routes_to_remove.remove((dstaddress, interface))
                try:
                    ipips_to_remove.remove((interface, gateway))
                except ValueError:
                    # ignore multiple routes per interface
                    pass
                unchanged += 1

        commands = []
        commands.append("# %d routes unchanged" % unchanged)

        if routes_to_remove:
            commands.append("# removing old or modified routes")
        for route in routes_to_remove:
            commands.append("/ip route remove [find dst-address=\"%s\" gateway=\"%s\"]" % route)

        if ipips_to_remove:
            commands.append("# removing orphaned ipip interfaces")
        for interface, gateway in ipips_to_remove:
            commands.append("/interfaces ipip remove %s" % interface)

        if routes_to_add:
            commands.append("# adding new and modified routes")
        for dstaddress, interface in routes_to_add:
            commands.append("/interface ipip add local-address=%s name=ampr-%s remote-address=%s" % (wan_router_ip, interface, interface))
            commands.append("/ip route add dst-address=%s gateway=ampr-%s" % (dstaddress, interface))

        if "-v" in sys.argv:
            print "\n".join(commands)
        if "-n" not in sys.argv:
            for command in commands:
                ssh.exec_command(command)
    except socket.timeout:
        print "timeout"
    finally:
        ssh.close()


if __name__ == "__main__":
    main()
