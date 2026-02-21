CLUSTER_NAME := fumo-dev
K3D_CONFIG   := k3d-config.yaml
OVERLAY      := local
MANIFEST_DIR := /tmp/fumo-k8s-platform-manifests

.PHONY: cluster-create cluster-delete manifests

manifests:
	@kubectl kustomize overlays/$(OVERLAY)

cluster-create:
	@if k3d cluster list $(CLUSTER_NAME) >/dev/null 2>&1; then \
		echo "Cluster '$(CLUSTER_NAME)' already exists."; \
	else \
		mkdir -p $(MANIFEST_DIR) && \
		kubectl kustomize overlays/$(OVERLAY) > $(MANIFEST_DIR)/manifests.yaml && \
		k3d cluster create --config $(K3D_CONFIG) \
			--volume "$(MANIFEST_DIR):/var/lib/rancher/k3s/server/manifests/platform@server:0" && \
		echo "Waiting for sealed-secrets namespace..." && \
		kubectl wait --for=jsonpath='{.status.phase}'=Active namespace/sealed-secrets --timeout=120s && \
		sops decrypt secrets/sealed-secrets-key.pem.enc > $(MANIFEST_DIR)/sealed-secrets-key.pem && \
		kubectl -n sealed-secrets create secret tls sealed-secrets-byoc \
			--cert=secrets/sealed-secrets-cert.pem \
			--key=$(MANIFEST_DIR)/sealed-secrets-key.pem && \
		kubectl -n sealed-secrets label secret sealed-secrets-byoc \
			sealedsecrets.bitnami.com/sealed-secrets-key=active && \
		rm -f $(MANIFEST_DIR)/sealed-secrets-key.pem; \
	fi

cluster-delete:
	@k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || true
	@rm -rf $(MANIFEST_DIR)
