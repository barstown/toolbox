#!/usr/bin/env python3
import asyncio
import ipaddress
import socket
import subprocess
import sys

# Usage: ./subnet_scan.py <subnet>
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <subnet>")
    sys.exit(1)

subnet = sys.argv[1]

async def ping_host(ip):
    proc = await asyncio.create_subprocess_exec(
        "ping", "-c", "1", "-W", "1", ip,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    await proc.wait()
    if proc.returncode == 0:
        try:
            dns = socket.gethostbyaddr(ip)[0]
            print(f"- {ip}    # {dns}")
        except socket.herror:
            print(f"- {ip}")

async def main():
    tasks = [ping_host(str(ip)) for ip in ipaddress.IPv4Network(subnet, strict=False)]
    await asyncio.gather(*tasks)

asyncio.run(main())
