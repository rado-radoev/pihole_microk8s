# PiHole on Ubuntu and Microk8s

1. Install microk8s
  > follow ubuntu instructions
  [instrctions here](https://ubuntu.com/tutorials/install-a-local-kubernetes-with-microk8s#1-overview)
1. Configure `kubectl` to work with microk8s 
  > follow [instructions here](https://microk8s.io/docs/working-with-kubectl)
1. Enable Ingress and Metallb on microk8s
```sh
  microk8s enable ingress metallb storage
```
When prompted for the Metallb network range, the easiest thing to do if you don't want to configure static routes is to just 
give it IPs from the same range as your home network

### Example. 
  > Your home network is 192.168.100.0/24. You have 30-40 devices that are most likely occupiying the first 30-40 IP addresses. 
  Make your metallb run on 192.168.100.240-192.168.100.250.
  You can also configure your DHCP to only lease addresses up to .240 and you should be good. 

You can have pihole run in the default namespace or create a separate nemaspace for it. 
My opinion if you don't want to go too crazy run it in the default namespace.
Running it there will mean that you can share the Metallb address that will be assigned to the piHole port 53 for other services too. 
1. Run [namespace.yml](../../pihole/namespace.yml) [optional]
1. Run [deployment.yml](../../pihole/deployment.yml)
  > You may or may not want to expose por 67 from piHole. You most likely have other DHCP already running.
1. Run [pvc.yml](../../pihole/pvc.yml)
  > This will create PVCs with your cluster and map them to your deployment.
1. The [service.yml](../../pihole/service.yml) is where gets interesting
  > You are fine running port 80 as `ClusterIP` (it will be exposed from the Ingress). Because you cannot expose UDP and TCP ports on the same service, you have to make two services. One for UDP port 53 (DNS) and one TCP port 53 (DNS). The caveat is you make them of type `LoadBalancer`. And to make them bind to the same IP address you need the metallb annotation:
  ```sh
    annotations:
    metallb.universe.tf/allow-shared-ip: pihole #<-- this can be anything as long as it matches on both services
  ```
  Now the IP that gets assigned to these two services will be what you will be setting as upstream DNS on your end user devices.
1. Now the Ingress [default-ingress](../../pihole/default-ingress.yml)
  > The Ingress in my case is listening for host header of pihole.lan (I have a `hosts` file entry pointing `pihole.lan` to the Ingress IP (the ingress IP is your host, running microk8s's IP. )). You can access your pihle admin interface on that IP.
  > Remember your DNS server IP will be the IP that your metallb set for the two port 53 services.

1. To test if port 53 TCP/UDP are opened on the IP address, assigned by Metallb, you can use nmap

```sh
  nmap -p 53 -sU 192.168.100.241 # UDP
  nmap -p 53 -sT 192.168.100.241 # TCP
```

This should output, something like this:
```sh
  PORT   STATE         SERVICE
  53/udp open|filtered domain

  PORT   STATE SERVICE
  53/tcp open  domain
```