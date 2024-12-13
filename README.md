## toe-helm

### Run and debug toe locally

```bash
helm repo add toe https://teknoir.github.io/toe-helm
# target context should be a local cluster. ex: rancher-desktop, docker-desktop etc.
./helm_install_local.sh -c teknoir-poc -n demonstrations -d device -t rancher-desktop -m default
```

```bash
helm repo add toe https://teknoir.github.io/toe-helm
# install manifests without fetching the certificates
./helm_install_local.sh -c teknoir-poc -n demonstrations -d device -t rancher-desktop -m default --install-only
```

```bash
helm repo add toe https://teknoir.github.io/toe-helm
# generate only the manifests without applying
./helm_install_local.sh -c teknoir-poc -n demonstrations -d device -t rancher-desktop -m default --dry-run
```