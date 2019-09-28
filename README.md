[![CircleCI](https://circleci.com/gh/giantswarm/kubernetes-elastic-stack.svg?style=shield)]()

# Honeypot stack in kubernetes

See [docs](docs/index.md) for full recipe content.


This setup is similar to the [`Docker-compose Stack Example`](), but adopted to be run on a Kubernetes cluster.

There is no access control for the Kibana web interface. If you want to run this in public you need to secure your setup. The provided manifests here are for demonstration purposes only.

## Honeypots

* [adbhoney](https://github.com/huuck/ADBHoney),
* [ciscoasa](https://github.com/Cymmetria/ciscoasa_honeypot),
* [conpot](http://conpot.org/),
* [cowrie](https://github.com/cowrie/cowrie),
* [dionaea](https://github.com/DinoTools/dionaea),
* [elasticpot](https://github.com/schmalle/ElasticpotPY),
* [glutton](https://github.com/mushorg/glutton),
* [heralding](https://github.com/johnnykv/heralding),
* [honeypy](https://github.com/foospidy/HoneyPy),
* [honeytrap](https://github.com/armedpot/honeytrap/),
* [mailoney](https://github.com/awhitehatter/mailoney),
* [medpot](https://github.com/schmalle/medpot),
* [rdpy](https://github.com/citronneur/rdpy),
* [snare](http://mushmush.org/),
* [tanner](http://mushmush.org/)

# Helm Chart Repository 


# Local Node Setup

## Start a local Kubernetes using minikube

> If some webpages don't show up immediately wait a bit and reload. Also the Kubernetes Dashboard needs reloading to update its view.

```bash
minikube start --memory 4096
minikube dashboard
# maybe wait a bit and retry
kubectl get --all-namespaces services,pods
```

# Multiple node cluster
## Storage

### Nfs provisioner
```
helm install stable/nfs-server-provisioner nfs-provisioner -n nfs
```

persistence:
enabled: true
storageClass: "-"
size: 200Gi

storageClass:
defaultClass: true

nodeSelector:
kubernetes.io/hostname: {node-name}

In this configuration, a PersistentVolume must be created for each replica to use. Installing the Helm chart, and then inspecting the PersistentVolumeClaim's created will provide the necessary names for your PersistentVolume's to bind to.

An example of the necessary PersistentVolume:

```
apiVersion: v1
kind: PersistentVolume
metadata:
name: data-nfs-server-provisioner-0
spec:
capacity:
    storage: 200Gi
accessModes:
    - ReadWriteOnce
hostPath:
    path: /srv/volumes/data-nfs-server-provisioner-0
claimRef:
    namespace: nfs
    name: data-nfs-server-provisioner-0
```

## Logging with Elasticsearch and Kibana

```bash
helm install -n bee elasticsearch .
helm install -n bee kibana .
helm install -n bee ewsposter .
```



To delete the whole local Kubernetes cluster use this:

```bash
minikube delete
```

# Credits
TpotCE [githu.com/dtag-dev-sec/tpotce]