* * *

# Running K3s with Multipass on Macbook

[![Go to the profile of Zhimin Wen](https://cdn-images-1.medium.com/fit/c/100/100/0*lgQhmUa1MnmLoXBm.)](https://medium.com/@zhimin.wen?source=post_header_lockup)[Zhimin Wen](https://medium.com/@zhimin.wen)<span class="followState js-followState" data-user-id="d50d713a1f06"><button class="button button--smallest u-noUserSelect button--withChrome u-baseColor--buttonNormal button--withHover button--unblock js-unblockButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-block-user" data-requires-token="true" data-redirect="https://medium.com/@zhimin.wen/running-k3s-with-multipass-on-mac-fbd559966f7c" data-action-source="post_header_lockup"><span class="button-label  button-defaultState">Blocked</span><span class="button-label button-hoverState">Unblock</span></button><button class="button button--primary button--smallest button--dark u-noUserSelect button--withChrome u-accentColor--buttonDark button--follow js-followButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-subscribe-user" data-requires-token="true" data-redirect="https://medium.com/_/subscribe/user/d50d713a1f06" data-action-source="post_header_lockup-d50d713a1f06-------------------------follow_byline"><span class="button-label  button-defaultState js-buttonLabel">Follow</span><span class="button-label button-activeState">Following</span></button></span><time datetime="2019-03-20T16:55:25.373Z">Mar 20</time><span class="middotDivider u-fontSize12"></span><span class="readingTime" title="2 min read"></span>

K3s is the lightweight Kubernetes distribution that is just freshly baked. As its lightweight, it’s ideal to run on a laptop for a developer to explore and experiment with it. But K3s is natively available for Linux. How can we run it on Mac?

Entering Multipass. First, let's install the multipass with the brew.

<pre name="bfb6" id="bfb6" class="graf graf--pre graf-after--p">brew search multipass
brew cask install multipass</pre>

Now create a VM with multipass, assuming 1GB memory and 5GB disk.

<pre name="c957" id="c957" class="graf graf--pre graf-after--p">multipass launch --name k3s --mem 1G --disk 5G
Launched: k3s</pre>

Wait for the VM created, then open a shell to the VM,

<pre name="02e5" id="02e5" class="graf graf--pre graf-after--p">multipass shell k3s</pre>

We have the shell for the VM then, run `curl -sfL [https://get.k3s.io](https://get.k3s.io) | sh -` to install K3s.

<pre name="3fab" id="3fab" class="graf graf--pre graf-after--p">[INFO]  Finding latest release
[INFO]  Using v0.2.0 as release
[INFO]  Downloading hash [https://github.com/rancher/k3s/releases/download/v0.2.0/sha256sum-amd64.txt](https://github.com/rancher/k3s/releases/download/v0.2.0/sha256sum-amd64.txt)
[INFO]  Downloading binary [https://github.com/rancher/k3s/releases/download/v0.2.0/k3s](https://github.com/rancher/k3s/releases/download/v0.2.0/k3s)
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  systemd: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s</pre>

Then we have K3s installed and running on Macbook. Validate it with kubectl

<pre name="c67f" id="c67f" class="graf graf--pre graf-after--p graf--trailing">multipass@k3s:~$ kubectl get nodes
NAME   STATUS   ROLES    AGE     VERSION
k3s    Ready    <none>   7m14s   v1.13.4-k3s.1

multipass@k3s:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                             READY   STATUS      RESTARTS   AGE
kube-system   coredns-7748f7f6df-dnsp2         1/1     Running     0          7m15s
kube-system   helm-install-traefik-nqvg8       0/1     Completed   0          7m15s
kube-system   svclb-traefik-6659944cc7-f6rdc   2/2     Running     0          6m53s
kube-system   traefik-5cc8776646-99c66         1/1     Running     0          6m53s</pre>