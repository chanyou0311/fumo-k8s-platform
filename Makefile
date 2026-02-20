CLUSTER_NAME := fumo-dev
K3D_CONFIG   := k3d-config.yaml

.PHONY: cluster-create cluster-delete

cluster-create:
	@if k3d cluster list $(CLUSTER_NAME) >/dev/null 2>&1; then \
		echo "Cluster '$(CLUSTER_NAME)' already exists."; \
	else \
		k3d cluster create --config $(K3D_CONFIG) \
			--volume "$(CURDIR)/platform:/var/lib/rancher/k3s/server/manifests/platform@server:0"; \
	fi

cluster-delete:
	@k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || true
