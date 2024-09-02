#!/bin/bash
set -e

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -c|--context)
    export CONTEXT="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--namespace)
    export NAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--device)
    export DEVICE="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--targetcontext)
    export TARGET_CONTEXT="$2"
    shift # past argument
    shift # past value
    ;;
    -m|--targetnamespace)
    export TARGET_NAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    -i|--install-only)
    export INSTALL_ONLY=1
    shift # past argument
    ;;
    -h|--help|*)
    echo "$0 -c(--context) <kubectl-context> -n(--namespace) <namespace> -d(--device) <device-name> -t(--targetcontext) <kubectl-context> -m(--targetnamespace) <namespace>"
    exit 0
    ;;
esac
done

export CONFIG_PATH=$(pwd)/tmp
mkdir -p ${CONFIG_PATH}

if [ ${INSTALL_ONLY} != 1 ]; then
  export ZONE=us-central1-c
  export _GCP_PROJECT=$(if [ "$CONTEXT" == "gke_teknoir-poc_us-central1-c_teknoir-dev-cluster" ]; then echo "teknoir-poc"; else echo "teknoir"; fi)
  export _DOMAIN=$([ "$_GCP_PROJECT" == 'teknoir' ] && echo "teknoir.cloud" || echo "teknoir.info")
  export _IOT_REGISTRY=${NAMESPACE}
  export _DEVICE_ID=${DEVICE}

  export DEVICE_MANIFEST="$(kubectl --context $CONTEXT -n $NAMESPACE get device $DEVICE -o yaml)"
  if [ -z ${DEVICE_MANIFEST+x} ] || [ "${DEVICE_MANIFEST}" = "" ]; then
    echo "DEVICE_MANIFEST not found"
    exit 1
  fi
  export _RSA_PRIVATE="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.rsa_private - | base64 -d)"
  export _FIRST_USER_NAME="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.username - | base64 -d)"
  export _FIRST_USER_PASS="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.userpassword - | base64 -d)"
  export _FIRST_USER_KEY="$(echo "$DEVICE_MANIFEST" | yq eval .spec.keys.data.publicsshkey - | base64 -d)"

  export AR_SECRET="$(kubectl --context $CONTEXT -n $NAMESPACE get secret artifact-registry-secret -o yaml)"
  export _AR_DOCKER_SECRET="$(echo "${AR_SECRET}" | yq eval '.data[".dockerconfigjson"]' -)"

  echo "GCP_PROJECT   = ${_GCP_PROJECT}"
  echo "DOMAIN        = ${_DOMAIN}"
  echo "TEAMSPACE     = ${_IOT_REGISTRY}"
  echo "DEVICE_ID     = ${_DEVICE_ID}"

  cat << EOF > ${CONFIG_PATH}/rsa_private.pem
${_RSA_PRIVATE}
EOF
  sudo chown 65532:$(id -gn) ${CONFIG_PATH}/rsa_private.pem
  sudo chmod 440 ${CONFIG_PATH}/rsa_private.pem

  curl -o ${CONFIG_PATH}/roots.pem -sSfL https://pki.goog/roots.pem
  sudo chown 65532:$(id -gn) ${CONFIG_PATH}/roots.pem
  sudo chmod 440 ${CONFIG_PATH}/roots.pem

  cat << EOF > ${CONFIG_PATH}/values.yaml
toe:
  deviceID: ${_DEVICE_ID}
  teamSpace: ${_IOT_REGISTRY}
  pullSecret: ${_AR_DOCKER_SECRET}
  gcpProject: ${_GCP_PROJECT}
  configHostPath: ${CONFIG_PATH}
  defaultNamespace: "teknoir"
EOF
  sudo chown 65532:$(id -gn) ${CONFIG_PATH}/values.yaml
  sudo chmod 440 ${CONFIG_PATH}/values.yaml
fi

export CHART_PATH=$(pwd)/charts/TOE
pushd ${CONFIG_PATH}
helm upgrade --install --kube-context=${TARGET_CONTEXT} --namespace=${TARGET_NAMESPACE} --create-namespace -f values.yaml toe ${CHART_PATH}
popd