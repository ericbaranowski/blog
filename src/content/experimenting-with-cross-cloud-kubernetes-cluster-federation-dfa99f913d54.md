* * *

# Experimenting with Cross Cloud Kubernetes Cluster Federation

[![Go to the profile of Samuel Cozannet](https://cdn-images-1.medium.com/fit/c/100/100/0*rlmtyzemfYP6pjPS.)](https://medium.com/@samnco?source=post_header_lockup)[Samuel Cozannet](https://medium.com/@samnco)<span class="followState js-followState" data-user-id="484dbfca3cf"><button class="button button--smallest u-noUserSelect button--withChrome u-baseColor--buttonNormal button--withHover button--unblock js-unblockButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-block-user" data-requires-token="true" data-redirect="https://medium.com/google-cloud/experimenting-with-cross-cloud-kubernetes-cluster-federation-dfa99f913d54" data-action-source="post_header_lockup"><span class="button-label  button-defaultState">Blocked</span><span class="button-label button-hoverState">Unblock</span></button><button class="button button--primary button--smallest button--dark u-noUserSelect button--withChrome u-accentColor--buttonDark button--follow js-followButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-subscribe-user" data-requires-token="true" data-redirect="https://medium.com/_/subscribe/user/484dbfca3cf" data-action-source="post_header_lockup-484dbfca3cf-------------------------follow_byline"><span class="button-label  button-defaultState js-buttonLabel">Follow</span><span class="button-label button-activeState">Following</span></button></span><time datetime="2017-02-10T15:46:21.589Z">Feb 10, 2017</time><span class="middotDivider u-fontSize12"></span><span class="readingTime" title="18 min read"></span>

### What / why?

In a previous [post](about:invalid#zSoyz) I presented a way to deploy a cluster in an existing AWS environment as an answer to questions I got about integrability.

So what is the next most frequent question that I get? You read the title so you know:

> **Can we span Kubernetes across multiple clusters / clouds?**

As more and more people consider k8s as the next big platform, that allows them to abstract a lot of the cloud / bare metal infrastructure, it is only fair that this question pops up regularly.

It’s ever fairer since there is a huge community effort to make it happen, and huge progress has been made over the last 6 months.

So theoretically… Yes. Now, does it work in the real world? Let’s check it out!

Let me be clear about the rest of this article: we will unfortunately _not_ reach a complete automation of a multi-cloud Kubernetes. However, we will get to a point where you can at a moderate cost operate a multi-cloud federation, and manipulate most basic primitives. For the ones that do not work, we will see workarounds. 
At least, hopefully you’ll have learnt something about the current state of k8s Federation.

### Preliminary words about Federation

What is a Kubernetes Federation? To answer this question, let’s just say that spanning a unique cluster all over the world is, to say the least, absolutely impossible. That’s why clouds have regions, AZs, cells, racks… You have to split your infrastructure so that specific geographic areas are the unit of construction to build the bigger solution.

Nevertheless, when you connect on AWS, Azure or GCP, you can create and manage resources across all regions. Even better, some services are global (DNS, Object Storage…) and shared between the complete environment.

If as many, you consider Kubernetes as a solution to (your) scalability problems, then you have considered or will consider spinning several clusters in several regions and AZs. 
The “over the Kubernetes” plane to control all the clusters is the Federation. It provides a centralized control, and distributes commands across all the federated clouds.

TL;DR: if you use Kubernetes, if you want a World Wide App spread across many regions and clouds, Federation is how you do it.

Now Federation is also a very young subproject of the Kubernetes ecosystem, and there is a long road before it is mature enough. Let us see where we stand now for anyone starting up on k8s or considering it.

### The Plan

In this blog, we are going to do the following things:

1.  Deploy Kubernetes clusters in Amazon, Azure and GKE
2.  Create a Google Cloud DNS Zone with a domain we control
3.  Install a federation control plane in GKE
4.  Test what works and what doesn’t work out of the box

### Requirements

For what follows, it is important that:

*   You understand Kubernetes 101
*   You understand k8s Federation concepts
*   You have admin credentials for AWS, GCP and Azure
*   You are familiar with tooling available to deploy Kubernetes
*   You have notions of GKE and Google Cloud DNS (or route53 or Azure DNS)

### Foreplay

*   Make sure you have Juju installed.

On Ubuntu,

<pre name="e7eb" id="e7eb" class="graf graf--pre graf-after--p">sudo apt-add-repository ppa:juju/stable
sudo apt update && apt upgrade -yqq
sudo apt install -yqq juju </pre>

for other OSes, lookup the [official docs](https://jujucharms.com/docs/2.0/getting-started-general)

Then to connect to the AWS cloud with your credentials, read [this page](https://jujucharms.com/docs/2.0/help-aws)

Finally, connect to Azure via [this page](https://jujucharms.com/docs/2.0/help-azure)

*   Make sure you have the [Google Cloud SDK suite](https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu) installed
*   Finally copy the repo to have access to all the sources

<pre name="0125" id="0125" class="graf graf--pre graf-after--li">git clone [https://github.com/madeden/blogposts](https://github.com/madeden/blogposts) ./
cd blogposts/k8s-federation</pre>

OK! Let’s federate now!

* * *

### Deploying

In this section we will

*   Deploy k8s on Azure, AWS and GKE
*   Install tools for the federation
*   Deploy the Federation

#### Microsoft Azure

Let’s spawn a k8s cluster in Azure first:

<pre name="a455" id="a455" class="graf graf--pre graf-after--p"># Bootstrap the Juju Controller
juju bootstrap azure/westeurope azure \
  --bootstrap-constraints “root-disk=64G mem=8G” \
  --bootstrap-series xenial
# Deploy Canonical Distribution of Kubernetes
juju deploy src/bundle/k8s-azure.yaml</pre>

Azure is relatively slow to spin up the whole thing, so you can let it go and we’ll come back to it later.

#### Amazon AWS

Now same course of action on AWS

<pre name="4601" id="4601" class="graf graf--pre graf-after--p">juju bootstrap aws/us-west-2 aws \
  --bootstrap-constraints "root-disk=64G mem=8G" \
  --bootstrap-series xenial
# Deploy Canonical Distribution of Kubernetes
juju deploy src/bundle/k8s-aws.yaml</pre>

This takes about 10min, so let’s let it run and we’ll come back to it again later

#### GKE

Here we deploy a DNS Zone and a small GKE Cluster

<pre name="9815" id="9815" class="graf graf--pre graf-after--p"># Spin up the DNS Zone
gcloud dns managed-zones create federation \
  --description "Kubernetes federation testing" \
  --dns-name demo.madeden.com
# Spin up a GKE cluster
gcloud container clusters create gke \
  --zone=us-east1-b \
  --scopes "cloud-platform,storage-ro,service-control,service-management,[https://www.googleapis.com/auth/ndev.clouddns.readwrite](https://www.googleapis.com/auth/ndev.clouddns.readwrite)" \
  --num-nodes=2</pre>

You will need a globally available DNS, that you can programmatically drive, to operate the Federation, which is why we use this Google Cloud DNS. It also works with AWS Route53, but other integrations are in the works.

I had to configure it to delegate the sub domain from Gandi, which is reasonably easy as Google gives you all the instructions you need on their [help page](https://cloud.google.com/dns/zones/).

### Federation

#### Installing kubefed

Since 1.5 Kubernetes comes with a tool called [KubeFed](https://kubernetes.io/docs/admin/federation/kubefed/) which manages the lifecycle of federations.

Install it with:

<pre name="b95a" id="b95a" class="graf graf--pre graf-after--p">curl -O [https://storage.googleapis.com/kubernetes-release/release/v1.5.2/kubernetes-client-linux-amd64.tar.gz](https://storage.googleapis.com/kubernetes-release/release/v1.5.2/kubernetes-client-linux-amd64.tar.gz)
tar -xzvf kubernetes-client-linux-amd64.tar.gz
sudo cp kubernetes/client/bin/kubefed /usr/local/bin
sudo chmod +x /usr/local/bin/kubefed
sudo cp kubernetes/client/bin/kubectl /usr/local/bin
sudo chmod +x /usr/local/bin/kubectl
mkdir -p ~/.kube</pre>

#### Configuring kubectl

On Azure, check that your cluster is now up & running:

<pre name="c2db" id="c2db" class="graf graf--pre graf-after--p"># Switch Juju to the Azure cluster
juju switch azure
# Get status
juju status
# Which gets you (if finished)
Model    Controller        Cloud/Region      Version
default  azure             azure/westeurope  2.1-beta5</pre>

<pre name="f1a2" id="f1a2" class="graf graf--pre graf-after--pre">App                Version  Status  Scale  Charm              Store       Rev  OS      Notes
easyrsa            3.0.1    active      1  easyrsa            jujucharms    6  ubuntu  
etcd               2.2.5    active      3  etcd               jujucharms   23  ubuntu  
flannel            0.7.0    active      4  flannel            jujucharms   10  ubuntu  
kubernetes-master  1.5.2    active      1  kubernetes-master  jujucharms   11  ubuntu  exposed
kubernetes-worker  1.5.2    active      3  kubernetes-worker  jujucharms   13  ubuntu  exposed</pre>

<pre name="3104" id="3104" class="graf graf--pre graf-after--pre">Unit                  Workload  Agent  Machine  Public address  Ports           Message
easyrsa/0*            active    idle   0        40.114.244.142                  Certificate Authority connected.
etcd/0                active    idle   1        40.114.247.142  2379/tcp        Healthy with 3 known peers.
etcd/1*               active    idle   2        104.47.167.187  2379/tcp        Healthy with 3 known peers.
etcd/2                active    idle   3        104.47.163.137  2379/tcp        Healthy with 3 known peers.
kubernetes-master/0*  active    idle   4        40.114.243.251  6443/tcp        Kubernetes master running.
  flannel/2           active    idle            40.114.243.251                  Flannel subnet 10.1.96.1/24
kubernetes-worker/0   active    idle   5        104.47.162.134  80/tcp,443/tcp  Kubernetes worker running.
  flannel/1           active    idle            104.47.162.134                  Flannel subnet 10.1.94.1/24
kubernetes-worker/1*  active    idle   6        104.47.162.82   80/tcp,443/tcp  Kubernetes worker running.
  flannel/0*          active    idle            104.47.162.82                   Flannel subnet 10.1.58.1/24
kubernetes-worker/2   active    idle   7        104.47.160.138  80/tcp,443/tcp  Kubernetes worker running.
  flannel/3           active    idle            104.47.160.138                  Flannel subnet 10.1.43.1/24</pre>

<pre name="0f81" id="0f81" class="graf graf--pre graf-after--pre">Machine  State    DNS             Inst id    Series  AZ
0        started  40.114.244.142  machine-0  xenial  
1        started  40.114.247.142  machine-1  xenial  
2        started  104.47.167.187  machine-2  xenial  
3        started  104.47.163.137  machine-3  xenial  
4        started  40.114.243.251  machine-4  xenial  
5        started  104.47.162.134  machine-5  xenial  
6        started  104.47.162.82   machine-6  xenial  
7        started  104.47.160.138  machine-7  xenial</pre>

<pre name="9840" id="9840" class="graf graf--pre graf-after--pre">Relation      Provides           Consumes           Type
certificates  easyrsa            etcd               regular
certificates  easyrsa            kubernetes-master  regular
certificates  easyrsa            kubernetes-worker  regular
cluster       etcd               etcd               peer
etcd          etcd               flannel            regular
etcd          etcd               kubernetes-master  regular
cni           flannel            kubernetes-master  regular
cni           flannel            kubernetes-worker  regular
cni           kubernetes-master  flannel            subordinate
kube-dns      kubernetes-master  kubernetes-worker  regular
cni           kubernetes-worker  flannel            subordinate</pre>

Now download the config file

<pre name="cec3" id="cec3" class="graf graf--pre graf-after--p">juju scp kubernetes-master/0:/home/ubuntu/config ./config-azure</pre>

Repeat the operation on AWS

<pre name="beea" id="beea" class="graf graf--pre graf-after--p">juju switch aws
Model    Controller     Cloud/Region   Version
default  aws            aws/us-west-2  2.1-beta5</pre>

<pre name="c015" id="c015" class="graf graf--pre graf-after--pre">App                Version  Status  Scale  Charm              Store       Rev  OS      Notes
easyrsa            3.0.1    active      1  easyrsa            jujucharms    6  ubuntu  
etcd               2.2.5    active      3  etcd               jujucharms   23  ubuntu  
flannel            0.7.0    active      4  flannel            jujucharms   10  ubuntu  
kubernetes-master  1.5.2    active      1  kubernetes-master  jujucharms   11  ubuntu  exposed
kubernetes-worker  1.5.2    active      3  kubernetes-worker  jujucharms   13  ubuntu  exposed</pre>

<pre name="8f6b" id="8f6b" class="graf graf--pre graf-after--pre">Unit                  Workload  Agent  Machine  Public address  Ports           Message
easyrsa/0*            active    idle   2        10.0.251.198                    Certificate Authority connected.
etcd/0*               active    idle   1        10.0.252.237    2379/tcp        Healthy with 3 known peers.
etcd/1                active    idle   6        10.0.251.143    2379/tcp        Healthy with 3 known peers.
etcd/2                active    idle   7        10.0.251.31     2379/tcp        Healthy with 3 known peers.
kubernetes-master/0*  active    idle   0        35.164.145.16   6443/tcp        Kubernetes master running.
  flannel/0*          active    idle            35.164.145.16                   Flannel subnet 10.1.37.1/24
kubernetes-worker/0*  active    idle   3        52.27.16.150    80/tcp,443/tcp  Kubernetes worker running.
  flannel/3           active    idle            52.27.16.150                    Flannel subnet 10.1.11.1/24
kubernetes-worker/1   active    idle   4        52.10.62.234    80/tcp,443/tcp  Kubernetes worker running.
  flannel/1           active    idle            52.10.62.234                    Flannel subnet 10.1.43.1/24
kubernetes-worker/2   active    idle   5        52.27.1.171     80/tcp,443/tcp  Kubernetes worker running.
  flannel/2           active    idle            52.27.1.171                     Flannel subnet 10.1.68.1/24</pre>

<pre name="99f1" id="99f1" class="graf graf--pre graf-after--pre">Machine  State    DNS            Inst id              Series  AZ
0        started  35.164.145.16  i-0a3fdb3ce9590cb7e  xenial  us-west-2a
1        started  10.0.252.237   i-0dcbd977bee04563b  xenial  us-west-2b
2        started  10.0.251.198   i-04cedb17e22064212  xenial  us-west-2a
3        started  52.27.16.150   i-0f44e7e27f776aebf  xenial  us-west-2b
4        started  52.10.62.234   i-02ff8041a61550802  xenial  us-west-2a
5        started  52.27.1.171    i-0a4505185421bbdaf  xenial  us-west-2a
6        started  10.0.251.143   i-05a855d5c0c6f847d  xenial  us-west-2a
7        started  10.0.251.31    i-03f1aafe15d163a34  xenial  us-west-2a</pre>

<pre name="a147" id="a147" class="graf graf--pre graf-after--pre">Relation      Provides           Consumes           Type
certificates  easyrsa            etcd               regular
certificates  easyrsa            kubernetes-master  regular
certificates  easyrsa            kubernetes-worker  regular
cluster       etcd               etcd               peer
etcd          etcd               flannel            regular
etcd          etcd               kubernetes-master  regular
cni           flannel            kubernetes-master  regular
cni           flannel            kubernetes-worker  regular
cni           kubernetes-master  flannel            subordinate
kube-dns      kubernetes-master  kubernetes-worker  regular
cni           kubernetes-worker  flannel            subordinate</pre>

and

<pre name="683f" id="683f" class="graf graf--pre graf-after--p">juju scp kubernetes-master/0:/home/ubuntu/config ./config-aws</pre>

Now for GKE

<pre name="1a1b" id="1a1b" class="graf graf--pre graf-after--p">gcloud container clusters get-credentials gce --zone=us-east1-b</pre>

This last operation will actually create or modify your **~/.kube/config** file for GKE, so you can query the context directly from kubectl. GKE has this tendency of creating veryyyyyy looooong naaaaaames, and we just want a short one right now to ease our command lines foo.

<pre name="433c" id="433c" class="graf graf--pre graf-after--p"># Identify the cluster name
LONG_NAME=$(kubectl config view -o jsonpath='{.contexts[*].name}')
# Replace it in kubeconfig
sed -i "s/$LONG_NAME/gke/g" ~/.kube/config</pre>

Now modify the files that Juju downloaded to integrate them into this config file.

A few clever people built a tool to merge kubeconfig files together: [load-kubeconfig](https://github.com/Collaborne/load-kubeconfig)

<pre name="7777" id="7777" class="graf graf--pre graf-after--p"># Install tool 
sudo npm install -g load-kubeconfig
# Replace the username and context name with our cloud names in both files and combine
for cloud in aws azure
do
  sed -i -e "s/juju-cluster/${cloud}/g" \
    -e "s/juju-context/${cloud}/g" \
    -e "s/ubuntu/${cloud}/g" \
    ./config-${cloud}
  load-kubeconfig ./config-${cloud}
done</pre>

Excellent, you can now very easily switch between the 3 cluster by using — **context={gke | aws | azure }.**

#### Labelling Nodes

One of the goals of deploying Kubernetes federations is to ensure multi-region HA for the applications. Within regions, you would want also to have HA between AZs. As a result, you should consider deploying one cluster per AZ.

To a federation, nothing looks more like a k8s cluster than another k8s. You can’t expect it to be region-aware without giving it a few hints. That is what we will be doing here.

By default, Juju will give you the following labels:

<pre name="a880" id="a880" class="graf graf--pre graf-after--p"># AWS
kubectl --context=aws get nodes --show-labels
NAME           STATUS    AGE       LABELS
ip-10-0-1-54   Ready     1d        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=ip-10-0-1-54
ip-10-0-1-95   Ready     1d        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=ip-10-0-1-95
ip-10-0-2-43   Ready     1d        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=ip-10-0-2-43
# Azure
kubectl --context=azure get nodes --show-labels
NAME        STATUS    AGE       LABELS
machine-5   Ready     2h        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=machine-5
machine-6   Ready     2h        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=machine-6
machine-7   Ready     2h        beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=machine-7</pre>

You only have 3 clusters and different regions (AWS is US West 2, Azure is EU West 2, and GKE is US East 1), so we will fake a little bit

<pre name="4e8f" id="4e8f" class="graf graf--pre graf-after--p"># Labelling the nodes of AWS for US West 2a (random pick)
for node in $(kubectl - aws get nodes -o json | jq --raw-output '.items[].metadata.name')
do
  kubectl --context=aws label nodes \
    ${node} \
    failure-domain.beta.kubernetes.io/region=us-west-2
  kubectl --context=aws label nodes \
    ${node} \
    failure-domain.beta.kubernetes.io/zone=us-west-2a
done
# Labelling the nodes of Azure for EU West 2a (random pick)
for node in $(kubectl - azure get nodes -o json | jq --raw-output '.items[].metadata.name')
do
  kubectl --context=azure label nodes \
    ${node} \
    failure-domain.beta.kubernetes.io/region=eu-west-2
  kubectl --context=azure label nodes \
    ${node} \
    failure-domain.beta.kubernetes.io/zone=eu-west-2a
done</pre>

**Note**: In a real context, you would have a lot more nodes to configure and a better strategy to adopt. This is just to explain that setting this parameter in k8s is important when you federate clusters in order to manage failure of clusters and clouds.

#### Making sure clusters share the same GLBC

[This page](https://kubernetes.io/docs/user-guide/federation/federated-ingress/) clearly states that our GLBC must absolutely be the same across all clusters. As you deployed 2 clusters with Juju and one with GKE, this is not the case at this point. It is **almost** the case though as Canonical’s CDK is 100% upstream. It’s just labels and a few tags not being the same.

The following step is therefore optional. If you don’t do it, you will have to publish a DNS configuration and an ingress manually to all clusters. It’s the only difference.

Let’s delete the L7 LB on our Azure & AWS clusters to replace them with others similar to GKE

<pre name="5f0b" id="5f0b" class="graf graf--pre graf-after--p">for cluster in aws azure
do
  # Delete old ones
  kubectl --context ${cloud} delete \
    rc/default-http-backend \
    rc/nginx-ingress-controller \
    svc/default-http-backend
  # Replace by new ones taken from GKE
  kubectl --context ${cloud} create -f \
    src/manifests/l7-svc.yaml
  kubectl --context ${cloud} create -f \
    src/manifests/l7-deployment.yaml</pre>

<pre name="dd9a" id="dd9a" class="graf graf--pre graf-after--pre">done</pre>

#### Initializing the Federation

Now we are ready to federate our clusters, which essentially means we are adding a cross cluster control plane, itself hosted in a third Kubernetes cluster.

Federating clusters brings some goodness, such as

*   Ability to define multi-clusters services, replicasets/deployments, ingresses,
*   Failover of services between zones
*   Single point of service definition

Kubefed, which you installed earlier, is the official tool to the lifecycle of Federations, from init to destruction. We are going to use the GKE cluster to manage our 2 clusters in Azure and AWS.

Initialize the control plane of our “Magic Ring” with

<pre name="a486" id="a486" class="graf graf--pre graf-after--p">kubefed init magicring \
  --host-cluster-context=gke \
  --dns-zone-name="demo.madeden.net."
Federation API server is running at: 130.211.62.225</pre>

The command is simple, and takes care of installing

*   a new namespace in the host cluster (GKE) called federation-system
*   a new API server for the Federation
*   a new Controller Manager for the Federation
*   a new context in your kubeconfig file to interact specifically with this uber layer of Kubernetes, named after the Federation name

To control the Federation, we can now go back to kubectl and switch into its context

<pre name="764c" id="764c" class="graf graf--pre graf-after--p">kubectl config use-context magicring
Switched to context “magicring”.</pre>

Now add our 2 clusters to the Magic Ring

<pre name="9a27" id="9a27" class="graf graf--pre graf-after--p"># add AWS
kubefed join aws \
  --host-cluster-context=gke
cluster "aws" created
# Now Azure
kubefed join azure \
  --host-cluster-context=gke
cluster "azure" created</pre>

These commands will create a pair of secrets based on your kubeconfig into the Federation Control Plane, so that it can interact with individual Kube API Servers. If you are planning to build a federation across VPNs or complex networks, this means you will have to make sure the control plane can talk to the various API endpoints you deployed.

Finally we can query a new construct with kubectl, “clusters”:

<pre name="909a" id="909a" class="graf graf--pre graf-after--p">kubectl get clusters
NAME STATUS AGE
aws Ready 1m
azure Ready 1m</pre>

Congratulations, you have federated a pair of Kubernetes clusters in less than 30min!!!

Now let’s play with it

* * *

### Deploying a multi cloud application

Now that the federation is running, let us try to deploy all the primitives that Federations are supposed to manage:

*   NameSpaces for quotas / resource management
*   ConfigMaps and Secrets to share data
*   Deployments / ReplicaSets / Replication Controllers for apps
*   Services / Ingresses for exposition

#### Namespaces

Let us deploy a test NameSpace:

<pre name="8e1b" id="8e1b" class="graf graf--pre graf-after--p"># Creation
kubectl --context=magicring create -f src/manifests/test-ns.yaml 
namespace "test-ns" created</pre>

<pre name="0a76" id="0a76" class="graf graf--pre graf-after--pre"># Check AWS
kubectl --context=aws get ns
NAME             STATUS    AGE
ns/default       Active    3d
ns/kube-system   Active    3d
ns/test-ns       Active    50s</pre>

<pre name="b876" id="b876" class="graf graf--pre graf-after--pre"># Check Azure
kubectl --context=azure get ns
NAME             STATUS    AGE
ns/default       Active    2d
ns/kube-system   Active    2d
ns/test-ns       Active    1m</pre>

OK, the basic of quotas and resource management is globally available. That’s a win.

#### Config Maps / Secrets

Push a test configmap to the cluster to assert it works:

<pre name="5c5e" id="5c5e" class="graf graf--pre graf-after--p"># Publish
kubectl --context magicring create -f src/manifests/test-configmap.yaml 
configmap "test-configmap" created</pre>

<pre name="9461" id="9461" class="graf graf--pre graf-after--pre"># Check AWS
kubectl --context aws get cm 
NAME       DATA      AGE
test-configmap   1         55s</pre>

<pre name="5b66" id="5b66" class="graf graf--pre graf-after--pre"># Check Azure
kubectl --context azure get cm 
NAME       DATA      AGE
test-configmap   1         1m</pre>

OK, so our configmap has been shared across all the clouds. We can have a single point of control for configuration of CMs as expected.

This also works for secrets.

#### Deployments / ReplicaSets / DaemonSets

First of all, deploy 10 replicas of the microbots (demo app for CDK):

<pre name="5c02" id="5c02" class="graf graf--pre graf-after--p"># Note we are still in the Magic Ring context…
kubectl create -f src/manifests/microbots-deployment.yaml 
deployment “microbot” created</pre>

Let us see where they went:

<pre name="6d45" id="6d45" class="graf graf--pre graf-after--p"># Querying the Federation control planed does not work
kubectl get pods -o wide
the server doesn't have a resource type "pods"</pre>

<pre name="eaa4" id="eaa4" class="graf graf--pre graf-after--pre"># Querying AWS cluster directly
kubectl --context=aws get pods 
NAME                             READY     STATUS    RESTARTS   AGE
default-http-backend-wqrmm       1/1       Running   0          1d
microbot-1855935831-6n08n        1/1       Running   0          1m
microbot-1855935831-fvd7q        1/1       Running   0          1m
microbot-1855935831-gg5ql        1/1       Running   0          1m
microbot-1855935831-kltf0        1/1       Running   0          1m
microbot-1855935831-z7zp1        1/1       Running   0          1m</pre>

<pre name="8f8d" id="8f8d" class="graf graf--pre graf-after--pre"># Now querying Azure directly
kubectl --context=azure get pods 
NAME                             READY     STATUS    RESTARTS   AGE
default-http-backend-04njk       1/1       Running   0          1h
microbot-1855935831-19m1p        1/1       Running   0          1m
microbot-1855935831-2gwjt        1/1       Running   0          1m
microbot-1855935831-8k3hc        1/1       Running   0          1m
microbot-1855935831-fgrn0        1/1       Running   0          1m
microbot-1855935831-ggvvf        1/1       Running   0          1m</pre>

The federation shared our Microbots evenly between clouds. This is the expected behavior. If we had more clusters, each one would get a fair share of the pods.

However it is to be noted that not everything worked, though I am unclear at this stage what went wrong and the consequences. The logs show:

<pre name="ff9a" id="ff9a" class="graf graf--pre graf-after--p">E0210 10:35:53.691358 1 deploymentcontroller.go:516] Failed to ensure delete object from underlying clusters finalizer in deployment microbot: failed to add finalizer orphan to deployment : Operation cannot be fulfilled on deployments.extensions “microbot”: the object has been modified; please apply your changes to the latest version and try again
E0210 10:35:53.691566 1 deploymentcontroller.go:396] Error syncing cluster controller: failed to add finalizer orphan to deployment : Operation cannot be fulfilled on deployments.extensions “microbot”: the object has been modified; please apply your changes to the latest version and try again</pre>

You can test DaemonSets with:

<pre name="e52f" id="e52f" class="graf graf--pre graf-after--p">kubectl --context=magicring create -f src/manifests/microbots-ds.yaml 
daemonset "microbot-ds" created</pre>

<pre name="8da7" id="8da7" class="graf graf--pre graf-after--pre">kubectl --context aws get po -n test-ns
NAME                READY     STATUS    RESTARTS   AGE
microbot-ds-5c25n   1/1       Running   0          48s
microbot-ds-cmvtj   1/1       Running   0          48s
microbot-ds-lp0j0   1/1       Running   0          48s</pre>

<pre name="ea80" id="ea80" class="graf graf--pre graf-after--pre">kubectl --context azure get po -n test-ns
NAME                READY     STATUS    RESTARTS   AGE
microbot-ds-bkj34   1/1       Running   0          53s
microbot-ds-r85z4   1/1       Running   0          53s
microbot-ds-w8kxg   1/1       Running   0          53s</pre>

So we are good for application distribution. Only 2 more!

#### Services

Now let us create the service :

<pre name="b505" id="b505" class="graf graf--pre graf-after--p"># Service creation...
kubectl --context=magicring create -f src/manifests/microbots-svc.yaml 
service "microbot" created</pre>

Do not rush this, as it can take a few minutes…

<pre name="94d9" id="94d9" class="graf graf--pre graf-after--p"># On AWS
$ kubectl --context=aws get svc
NAME                   CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
default-http-backend   10.152.183.100   <none>        80/TCP         3d
kubernetes             10.152.183.1     <none>        443/TCP        3d
microbot               10.152.183.173   <none>        80/TCP         1m</pre>

<pre name="a275" id="a275" class="graf graf--pre graf-after--pre"># On Azure
$ kubectl --context=azure get svc
NAME                   CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
default-http-backend   10.152.183.103   <none>        80/TCP    2d
kubernetes             10.152.183.1     <none>        443/TCP   2d
microbot               10.152.183.153   <none>        80/TCP    1m</pre>

Good! We can see again that the service has been duplicated on both clusters as expected. The Federation is sharding services all over the place.

Even better, it also synchronized our DNS Zone in Google Cloud DNS:

<pre name="e11c" id="e11c" class="graf graf--pre graf-after--p">$ gcloud dns record-sets list  --zone demo-madeden
NAME TYPE TTL DATA
demo.madeden.net. NS 21600 ns-cloud-a1.googledomains.com.,ns-cloud-a2.googledomains.com.,ns-cloud-a3.googledomains.com.,ns-cloud-a4.googledomains.com.
demo.madeden.net. SOA 21600 ns-cloud-a1.googledomains.com. cloud-dns-hostmaster.google.com. 2 21600 3600 259200 300
microbot.default.magicring.svc.eu-west-2a.eu-west-2.demo.madeden.net. CNAME 180 microbot.default.magicring.svc.eu-west-2.demo.madeden.net.
microbot.default.magicring.svc.eu-west-2.demo.madeden.net. CNAME 180 microbot.default.magicring.svc.demo.madeden.net.
microbot.default.magicring.svc.us-west-2.demo.madeden.net. CNAME 180 microbot.default.magicring.svc.demo.madeden.net.
microbot.default.magicring.svc.us-west-2a.us-west-2.demo.madeden.net. CNAME 180 microbot.default.magicring.svc.us-west-2.demo.madeden.net.</pre>

So we can see our region configuration being used to create the records. If we had not configured these previously, the logs would have trashed a few errors, and these would not have been created.

Also worth nothing the change in the DNS structure from <service>.<namespace>.svc.cluster.local to <service>.<namespace>.<federation>.svc.<failure-zone>.<dns-zone>

So now, microbot.default.magicring.svc.demo.madeden.net connects to the 2 clusters transparently, meaning we have **global DNS resolution of the services across our clusters**. Pretty awesome!

#### Ingresses

Unfortunately this is not going to go as well…

<pre name="367a" id="367a" class="graf graf--pre graf-after--p"># deploying Ingress...
kubectl --context=magicring create -f 
  src/manifests/microbots-ing.yaml 
ingress "microbot-ingress" created</pre>

Checking the results:

<pre name="d525" id="d525" class="graf graf--pre graf-after--p"># Querying ing on AWS
kubectl --context=aws get ing
NAME               HOSTS                        ADDRESS            PORTS     AGE
microbot-ingress   microbots.demo.madeden.net   10.0.1.95,10....   80        1d
# On AWS
kubectl --context=azure get ing
No resources found.
# Oups!! 
kubectl --context=magicring get ing
NAME               HOSTS                        ADDRESS            PORTS     AGE
microbot-ingress   microbots.demo.madeden.net   10.0.1.95,10....   80        1d
kubectl --context=magicring describe ing microbot-ingress
Name:     microbot-ingress
Namespace:    default
Address:    10.0.1.95,10.0.2.43,10.0.2.43
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host        Path  Backends
  ----        ----  --------
  microbots.demo.madeden.net  
            /   microbot:80 (<none>)
Annotations:
  first-cluster:  aws
Events:
  FirstSeen LastSeen  Count From        SubObjectPath Type    Reason    Message
  --------- --------  ----- ----        ------------- --------  ------    -------
  1d    3m    2 {federated-ingress-controller }     Normal    CreateInCluster Creating ingress in cluster azure
  1d    1m    1 {federated-ingress-controller }     Normal    UpdateInCluster Updating ingress in cluster azure
  1d    1m    6 {federated-ingress-controller }     Normal    CreateInCluster Creating ingress in cluster aws</pre>

Clearly there is a problem here. The Ingress has **_not_** been pushed to all clusters.

This is a known bug when clusters are not deployed in GCE/GKE (which is to date the only environment where Federation is tested)

You can checkout

*   [https://github.com/kubernetes/kubernetes/issues/33943](https://github.com/kubernetes/kubernetes/issues/33943)
*   [https://github.com/kubernetes/kubernetes/issues/34291](https://github.com/kubernetes/kubernetes/issues/34291)

for more details about this.

If you want to intercept this error from the logs,

<pre name="2f57" id="2f57" class="graf graf--pre graf-after--p"># log from the Federation Controller Manager 
## And specific for the ingress creation
E0210 08:54:08.464928 1 ingress_controller.go:725] Failed to ensure delete object from underlying clusters finalizer in ingress microbot-ingress: failed to add finalizer orphan to ingress : Operation cannot be fulfilled on ingresses.extensions “microbot-ingress”: the object has been modified; please apply your changes to the latest version and try again
E0210 08:54:08.472338 1 ingress_controller.go:672] Failed to update annotation ingress.federation.kubernetes.io/first-cluster:aws on federated ingress “default/microbot-ingress”, will try again later: Operation cannot be fulfilled on ingresses.extensions “microbot-ingress”: the object has been modified; please apply your changes to the latest version and try again</pre>

It eventually gets worse if you try to delete your ingress, at which point it doesn’t disappear at all and you have to delete on each cluster.

You still want to have access to the Ingress Endpoint! Here is a manual workaround

<pre name="7c5c" id="7c5c" class="graf graf--pre graf-after--p">for cloud in aws azure
do
  kubectl --context=${cloud} create -f src/manifests/microbots-ing.yaml 
done</pre>

You can then expose this service directly in the managed zone

<pre name="c230" id="c230" class="graf graf--pre graf-after--p"># Identify the public addresses of the workers
juju switch aws
AWS_INSTANCES="$(juju show-status kubernetes-worker --format json | jq --raw-output '.applications.kubernetes-worker".units[]."public-address"' | tr '\n' ' ')"</pre>

<pre name="b462" id="b462" class="graf graf--pre graf-after--pre">juju switch azure
AZURE_INSTANCES="$(juju show-status kubernetes-worker --format json | jq --raw-output '.applications."kubernetes-worker".units[]."public-address"' | tr '\n' ' ')"</pre>

<pre name="8780" id="8780" class="graf graf--pre graf-after--pre"># Create the Zone File
touch /tmp/zone.list
for instance in ${AWS_INSTANCES} ${AZURE_INSTANCES}; 
do 
  echo "microbots.demo.madeden.net. IN A ${instance}" | tee -a /tmp/zone.list
done</pre>

<pre name="76bf" id="76bf" class="graf graf--pre graf-after--pre"># Add a A record to the zone
gcloud dns record-sets import -z demo-madeden \
      --zone-file-format \
      /tmp/zone.list</pre>

After a few minutes, when you point your browser to this endpoint, you will see the Microbot web page, evenly displaying podnames from AWS and Azure instances.

So you can create the world wide application!! It’s just that it is not as automated as we hoped for.

Anyway, it’s a 90% working, which is pretty amazing for a tech that is so young. Kudos to the devs!

* * *

### Tear Down

Before moving to the conclusion, let’s tear down the clusters.

Tearing down the federation is quick and simple: you just have to destroy the namespace! Efficient even if efforts are being done to make this process a bit nicer.

<pre name="e9a2" id="e9a2" class="graf graf--pre graf-after--p">kubectl --context=magicring delete clusters \
  aws azure
kubectl --context=gke delete namespace \
  federation-system</pre>

Destroy the GKE cluster and the DNS zone

<pre name="c84e" id="c84e" class="graf graf--pre graf-after--p">gcloud dns managed-zones delete demo-madeden
gcloud container clusters delete gce --zone=us-east1-b</pre>

Destroy the 2 Juju controllers

<pre name="a9f8" id="a9f8" class="graf graf--pre graf-after--p"># AWS
juju destroy-controller aws --destroy-all-models
WARNING! This command will destroy the "k8s-us-west-2" controller.
This includes all machines, applications, data and other resources.</pre>

<pre name="dd37" id="dd37" class="graf graf--pre graf-after--pre">Continue? (y/N):y
Destroying controller
Waiting for hosted model resources to be reclaimed
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines
Waiting on 1 model, 8 machines
Waiting on 1 model, 1 machine
Waiting on 1 model, 1 machine
Waiting on 1 model
Waiting on 1 model
All hosted models reclaimed, cleaning up controller machines

</pre>

<pre name="f64f" id="f64f" class="graf graf--pre graf-after--pre"># Azure
juju destroy-controller azure --destroy-all-models
WARNING! This command will destroy the "k8s-us-west-2" controller.
This includes all machines, applications, data and other resources.</pre>

<pre name="4c55" id="4c55" class="graf graf--pre graf-after--pre">Continue? (y/N):y
Destroying controller
Waiting for hosted model resources to be reclaimed
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines, 5 applications
Waiting on 1 model, 8 machines
Waiting on 1 model, 8 machines
Waiting on 1 model, 1 machine
Waiting on 1 model, 1 machine
Waiting on 1 model
Waiting on 1 model
All hosted models reclaimed, cleaning up controller machines</pre>

Et voilààà! You’re done with today’s experiment on Federating Kubernetes.

* * *

### Conclusion

Is it worth engaging with Federation right now on multicloud / world scale solutions? 
Definitely yes. This part of Kubernetes is **_the_** one any enterprise is looking at right now, and having understanding of its behavior and architecture is definitely a plus.

As a company, should you already prepare your production for this? At your own risks.

The Federation control plane that Kubefed deploys (as of this day) works, but relies on a single etcd pod, backed by a PV. Not good enough to ensure production stability and reliability. As a result, you would need engineering to make that more robust. 
It’s not so hard so, etcd being relatively easy to manage thanks to the [Juju charms](https://jujucharms.com/etcd/23) to deploy at scale. But it is still an effort.

Moreover, some of the key features such as ingress distribution are not ready yet for prime time out of AWS and GKE/GCE, meaning unless you put serious efforts into developing your own solution, there is a good chance you’ll suffer.

Finally, out of Google Cloud DNS or Route53, there is no solution available today. It’s coming, but it’s not there yet. Stay tuned*!

What you can and should do though is really add depth to your k8s by deploying on every single cloud using [CDK](https://jujucharms.com/canonical-kubernetes/), and learn how the solution adapts in these environments, the pros and cons of each cloud and types of machines.

As an individual in the DevOps community, should you engage with K8s and Federation? YES!!! 
First of all, it’s really a game changer for anyone who has any form of experience with releasing applications, and it’s not that hard to deploy, even at medium scale.

So what’s next? Until now, we have covered

*   [Building a DYI GPU cluster for k8s](https://hackernoon.com/installing-a-diy-bare-metal-gpu-cluster-for-kubernetes-364200254187)
*   [Integrating k8s with existing infrastructure](https://medium.com/@samnco/automate-the-deployment-of-kubernetes-in-existing-aws-infrastructure-aa369df2f651)
*   State of the art of Federation (this article)

Now I need more ideas. Another recurrent question is about identity management in k8s, that could be a subject.

But if you have any idea of something cool I should build… By all means, comment and find me on GitHub (SaMnCo) or the #kubernetes-users Slack (samuel-me)