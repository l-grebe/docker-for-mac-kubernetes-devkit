# docker-for-mac-kubernetes-devkit

打通到Mac下Docker Desktop的DNS域名解析和网络访问。

在您的Mac上，Docker Desktop可以运行一个单节点的Kubernetes，具体可以参见：<https://docs.docker.com/docker-for-mac/#kubernetes>。

该Kubernetes其实是运行在Mac下的轻量虚拟机里，只通过和localhost的端口挂关联，让Mac用户能访问到，这里会记录打通到该kubernes的DNS解析，以及网络访问。



## 打通kubernetes DNS域名解析

思路：
- 将Kubernetes DNS服务提供的端口，暴露给Mac。
- Mac上通过brew运行一个dnsmasq服务，将含有`cluster.local`的域名转发到Kubernetes DNS服务，其它不变。
- Mac网络配置上，设置DNS服务器为`127.0.0.1`。

操作记录如下：

##### 暴露端口给Mac:
```bash
# 将kube-system该Namespace下kube-dns服务改为NodePort类型，并将53端口的nodePort设置为20053，保存。
kubectl --namespace kube-system edit svc kube-dns
# 可查看更改后的端口映射情况。
kubectl get svc --namespace kube-system
```

##### 配置dnsmasq服务：
```bash
# brew 安装 dnsmas：
brew install dnsmasq
# /opt/homebrew/etc/dnsmasq.conf配置文件更改如下：
```
```conf
#上游DNS路径
resolv-file=/etc/resolv.dnsmasq.conf
#取消strict-order注释
strict-order
#反劫持
# bogus-nxdomain=114.114.114.114
#指定域名解析到固定内部IP
#指定10.96网段使用kubernetes的DNS进行解析
server=/cluster.local/127.0.0.1#20053
```
```bash
# 启动dnsmasq服务
sudo brew service start dnsmasq
# 查看dnsmasq服务运行情况
sudo brew service list
```
##### 设置Mac DNS服务器：
Mac -> 系统偏好设置 -> 网络 -> 高级 -> DNS -> 添加DNS服务器 -> 127.0.0.1

##### 测试：
```bash
$ nslookup kube-dns.kube-system.svc.cluster.local

Server:		127.0.0.1
Address:	127.0.0.1#53

Name:	kube-dns.kube-system.svc.cluster.local
Address: 10.96.0.10
```

## 打通到Kubernetes的网络访问

由于 Docker for Mac 容器实际上运行在由 HyperKit 提供支持的 VM 中，因此您无法直接与容器进行交互。此处有更多详细信息: [Docker for Mac - Networking - Known limitations, use cases, and workarounds](https://docs.docker.com/docker-for-mac/networking/#known-limitations-use-cases-and-workarounds)。

为了解决这个问题，可以在虚拟机内部以host网络模式运行一个 OpenVPN 服务器容器，然后你就可以通过其内部 IP 访问容器。您可以使用 docker-compose 或在 Kubernetes 上运行 OpenVPN 服务器。

当然，您可以在没有 Kubernetes 的情况下遵循 docker-compose 方法。

一般来说，它是这样工作的：

```Text
Mac <-> Tunnelblick <-> socat/service <-> OpenVPN Server <-> Containers
```

### 准备工作

1. 安装 [`Tunnelblick`](https://tunnelblick.net/downloads.html) (一个开源的GUI OpenVPN client for Mac).

2. Change into the `docker-for-mac-openvpn` directory.

## 参考文档：
- <https://github.com/pengsrc/docker-for-mac-kubernetes-devkit>
- <https://github.com/kylemanna/docker-openvpn>