# Network Diagnostic: Layer-by-Layer Troubleshooting

This doc demonstrates network diagnostics on a Linux system using a bottom-up approach. Each layer depends on the one below it, so each is confirmed working before testing the next. When something fails, the first failing layer shows where the problem is, and every layer below it has already been ruled out.

## Environment

The system is a VirtualBox virtual machine using NAT networking, with Docker installed. This affects some results, noted where relevant.

## Objectives

- Confirm each network layer, from the interface up to the application
- Identify the environment from network information alone

## Layers tested

| # | Layer | Question | Tool |
|---|---|---|---|
| 1 | Interface | Is the network card up? | `ip link` |
| 2 | IP address | Does the machine have an address? | `ip addr` |
| 3 | Routing | Does it know where to send traffic? | `ip route` |
| 4 | Local network | Can it reach the gateway? | `ping` |
| 5 | Internet | Can it reach the outside world by IP? | `ping` |
| 6 | DNS | Can it turn names into addresses? | `resolvectl`, `getent`, `dig` |
| 7 | Path | Which route does traffic take? | `tracepath` |
| 8 | Ports | What is listening and connected? | `ss` |
| 9 | Application | Do the actual services respond? | `nc`, `curl`, `ssh` |

## Layer 1: Interface

```
$ ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
enp0s3           UP             08:00:27:d7:1c:07 <BROADCAST,MULTICAST,UP,LOWER_UP>
br-02f7b30dce9b  UP             e6:72:2e:00:5a:ae <BROADCAST,MULTICAST,UP,LOWER_UP>
docker0          DOWN           da:9c:71:39:9a:67 <NO-CARRIER,BROADCAST,MULTICAST,UP>
veth8aa0d53@if2  UP             d2:2b:3a:7a:52:0d <BROADCAST,MULTICAST,UP,LOWER_UP>
```

| Interface | Meaning |
|---|---|
| `lo` | Loopback: the machine talking to itself |
| `enp0s3` | The real network card, `UP` |
| `docker0` | Docker's default network, `DOWN` with no containers attached |
| `br-02f7b30dce9b` | A custom Docker network, `UP` |
| `veth8aa0d53@if2` | A virtual cable connecting a container to that network |

**Observation:** the main interface is up. The MAC address prefix `08:00:27` belongs to VirtualBox, which identifies this as a VirtualBox VM. The Docker interfaces show one container running on a custom network.

## Layer 2: IP address

```
$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp0s3           UP             10.0.2.7/24 fe80::a00:27ff:fed7:1c07/64
br-02f7b30dce9b  UP             172.18.0.1/16 fe80::e472:2eff:fe00:5aae/64
docker0          DOWN           172.17.0.1/16
veth8aa0d53@if2  UP             fe80::d02b:3aff:fe7a:520d/64
```

**Observation:** `enp0s3` has the address `10.0.2.7` on a `/24` network, meaning addresses `10.0.2.0` to `10.0.2.255` are local. All addresses are private, so none of this output identifies the machine publicly.

## Layer 3: Routing

```
$ ip route
default via 10.0.2.1 dev enp0s3 proto static
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.7
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.0.0/16 dev br-02f7b30dce9b proto kernel scope link src 172.18.0.1
$ ip route get 1.1.1.1
1.1.1.1 via 10.0.2.1 dev enp0s3 src 10.0.2.7 uid 1000
    cache
```

**Observation:** traffic for anywhere outside the local networks goes to the default gateway, `10.0.2.1`, through `enp0s3`. `proto static` shows the network is configured manually rather than by DHCP. `ip route get` confirms which route a packet to the internet would take.

## Layer 4: Local network

```
$ GW=$(ip route | awk '/^default/ {print $3; exit}')
$ echo "Gateway: $GW"
Gateway: 10.0.2.1
$ ping -c 4 "$GW"
PING 10.0.2.1 (10.0.2.1) 56(84) bytes of data.
64 bytes from 10.0.2.1: icmp_seq=1 ttl=64 time=0.854 ms
64 bytes from 10.0.2.1: icmp_seq=2 ttl=64 time=0.551 ms
64 bytes from 10.0.2.1: icmp_seq=3 ttl=64 time=0.590 ms
64 bytes from 10.0.2.1: icmp_seq=4 ttl=64 time=0.437 ms

--- 10.0.2.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3015ms
rtt min/avg/max/mdev = 0.437/0.608/0.854/0.152 ms
```

**Observation:** the gateway answers with no packet loss in under 1 ms, as expected for a gateway provided by VirtualBox on the same physical machine.

## Layer 5: Internet by IP

Pinging an IP address leaves DNS out of the test, so this checks internet routing alone.

```
$ ping -c 4 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=14.9 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=64 time=14.7 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=64 time=14.7 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=64 time=12.2 ms

--- 1.1.1.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3013ms
rtt min/avg/max/mdev = 12.234/14.131/14.914/1.099 ms
```

**Observation:** the internet is reachable, with around 14 ms latency. The TTL is 64, the same as the gateway, although each router on a real path would reduce it by 1. This happens because VirtualBox NAT sends its own ping from the host and passes the reply back, rather than forwarding the original packet.

## Layer 6: DNS

```
$ resolvectl dns
Global:
Link 2 (enp0s3): 8.8.8.8 1.1.1.1
Link 3 (br-02f7b30dce9b):
Link 4 (docker0):
Link 5 (veth8aa0d53):
$ getent hosts github.com
20.26.156.215   github.com
$ dig +short github.com
20.26.156.215
$ ping -c 2 github.com
PING github.com (20.26.156.215) 56(84) bytes of data.
64 bytes from 20.26.156.215: icmp_seq=1 ttl=64 time=13.7 ms
64 bytes from 20.26.156.215: icmp_seq=2 ttl=64 time=14.6 ms

--- github.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1577ms
rtt min/avg/max/mdev = 13.687/14.163/14.640/0.476 ms
```

**Observation:** the system uses Google (`8.8.8.8`) and Cloudflare (`1.1.1.1`) for DNS. `getent` (the system resolver) and `dig` (a direct DNS query) return the same address for `github.com`, and pinging by name succeeds, so DNS and internet access both work.

## Layer 7: Path

```
$ tracepath -n -m 15 github.com
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.0.2.1                                              1.150ms
 1:  10.0.2.1                                              2.058ms
 2:  no reply
 3:  no reply
...
15:  no reply
     Too many hops: pmtu 1500
     Resume: pmtu 1500
```

**Observation:** only the gateway replies. VirtualBox NAT does not pass trace probes beyond itself, so the route past the VM is hidden. This is a limitation of the environment, not a fault: the next layers confirm GitHub is reachable.

## Layer 8: Ports

Listening ports are limited to SSH to avoid publishing the server's full set of open services.

```
$ ss -tln 'sport = :22'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*
LISTEN 0      4096            [::]:22           [::]:*
```

**Observation:** the SSH server listens on port 22 on all IPv4 (`0.0.0.0`) and IPv6 (`[::]`) addresses.

```
$ ss -tn state established '( sport = :22 or dport = :22 )'
Recv-Q  Send-Q   Local Address:Port   Peer Address:Port Process
0       0             10.0.2.7:22         10.0.2.1:4634
0       0             10.0.2.7:22         10.0.2.1:4636
```

**Observation:** two SSH sessions are connected to the VM. Both appear to come from the gateway, `10.0.2.1`, because VirtualBox forwards connections from the host through NAT, so the host's real address is not visible inside the VM.

## Layer 9: Application

**Port checks:**

```
$ nc -zv -w 3 github.com 22
Connection to github.com (20.26.156.215) 22 port [tcp/ssh] succeeded!
$ nc -zv -w 3 github.com 443
Connection to github.com (20.26.156.215) 443 port [tcp/https] succeeded!
```

**HTTPS request timing:**

```
$ curl -sS -o /dev/null -w 'dns: %{time_namelookup}s\n...' https://github.com
dns:     0.023660s
connect: 0.040713s
tls:     0.111958s
total:   0.212030s
http:    200
```

The timings are cumulative from the start of the request:

| Stage | Time taken |
|---|---|
| DNS lookup | 24 ms |
| TCP connection | 17 ms |
| TLS handshake | 71 ms |
| Response | 100 ms |

**SSH authentication:**

```
$ ssh -T git@github.com
Hi ayo-adeboyejo! You've successfully authenticated, but GitHub does not provide shell access.
```

**Observation:** GitHub's SSH and HTTPS ports are open, an HTTPS request returns `200 OK` in about 0.2 seconds, and SSH key authentication works. The TLS handshake is the slowest stage, because it needs several round trips to agree on encryption. Every service this repo depends on is working.

## Summary

- Every layer from the interface to the application works.
- The network information alone identifies the system as a VirtualBox VM using NAT, running one Docker container.
- VirtualBox NAT hides the route beyond the gateway and alters ping TTLs. Knowing the environment prevents these from being mistaken for faults.

## Further checks

Not covered here, as they require root access and reveal the system's security setup:

- Firewall rules: `sudo ufw status verbose` or `sudo nft list ruleset`
- The full list of listening services: `sudo ss -tlnp`

## Commands used

| Command | Purpose |
|---|---|
| `ip -br link` / `ip -br addr` | Interfaces and addresses |
| `ip route` / `ip route get` | Routing table and the route to a destination |
| `ping -c` | Reachability and latency |
| `resolvectl dns` | DNS servers in use |
| `getent hosts` / `dig +short` | Resolve a name via the system or via DNS directly |
| `tracepath -n` | Route to a destination |
| `ss -tln` / `ss -tn state established` | Listening ports and live connections |
| `nc -zv -w` | Test whether a port is open |
| `curl -w` | Time each stage of an HTTPS request |
| `ssh -T git@github.com` | Test SSH authentication to GitHub |
