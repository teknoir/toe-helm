# Teknoir Orkestration Engine (TOE) Helm Chart

This chart deploys the Teknoir Orkestration Engine (TOE) to a Kubernetes cluster.

> The implementation of the Helm chart is right now the bare minimum to get it to work.

## Prerequisites
The host machine must have the following installed:
- The root CA certificate for Teknoir MQTT server in /etc/teknoir/roots.pem
- The private client certificate for the Device in /etc/teknoir/rsa_private.pem

> The dir on the host machine can be changed by setting the `configHostPath` in the `values.yaml` file.