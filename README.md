# fumo-k8s-platform

fumo homelab の Kubernetes platform 層 (ミドルウェア) マニフェスト管理リポジトリ。

## 前提条件

- Docker
- [k3d](https://k3d.io/)
- kubectl

> Helm CLI は不要。k3s HelmChart CRD でデプロイする。

## クイックスタート

```bash
make cluster-create   # k3d クラスタ作成 + ミドルウェアデプロイ
# ArgoCD:  http://argocd.localhost  (admin / admin)
# Headlamp: http://headlamp.localhost
make cluster-delete   # クラスタ削除
```

## Makefile ターゲット

| ターゲット | 説明 |
|---|---|
| `cluster-create` | kustomize build → k3d クラスタ作成 |
| `cluster-delete` | クラスタ削除 + 一時ファイル cleanup |
| `manifests` | kustomize build 出力を表示 |

## ディレクトリ構造

```
fumo-k8s-platform/
├── base/                         # 環境共通 HelmChart CRD
│   ├── kustomization.yaml
│   ├── argocd.yaml
│   ├── cert-manager.yaml
│   ├── sealed-secrets.yaml
│   └── headlamp.yaml
├── overlays/
│   ├── local/                    # ローカル k3d 用
│   │   ├── kustomization.yaml
│   │   ├── cert-manager-issuer.yaml
│   │   ├── headlamp-token.yaml
│   │   └── patches/
│   └── production/               # 本番 k3s 用
│       ├── kustomization.yaml
│       ├── cert-manager-issuer.yaml
│       ├── argocd-application.yaml
│       └── patches/
├── k3d-config.yaml
└── Makefile
```

## ローカル環境アクセス

| サービス | URL | ログイン方法 |
|---------|-----|-------------|
| ArgoCD | http://argocd.localhost | `admin` / `admin` |
| Headlamp | http://headlamp.localhost | `kubectl get secret headlamp-token -n headlamp -o jsonpath='{.data.token}' \| base64 -d` |

## 本番環境 (k3s)

### 前提条件

- kubectl (context: `fumo-k3s`)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets)
- [yq](https://github.com/mikefarah/yq)

### ブートストラップ手順

#### Phase 1: 基盤デプロイ

```bash
kubectl kustomize overlays/production | kubectl --context fumo-k3s apply -f -
kubectl --context fumo-k3s wait --for=condition=available deployment/sealed-secrets-controller -n sealed-secrets --timeout=300s
```

#### Phase 2: SealedSecret 作成

```bash
kubeseal --controller-namespace sealed-secrets --fetch-cert --context fumo-k3s > /tmp/sealed-secrets-cert.pem

# GitHub PAT
kubectl create secret generic github-repo-creds --namespace argocd \
  --from-literal=type=git --from-literal=url=https://github.com/chanyou0311 \
  --from-literal=username=chanyou0311 --from-literal=password=<GITHUB_PAT> \
  --dry-run=client -o yaml \
  | yq '.metadata.labels["argocd.argoproj.io/secret-type"] = "repo-creds"' \
  | kubeseal --format yaml --cert /tmp/sealed-secrets-cert.pem \
  > overlays/production/github-repo-creds-sealed.yaml

# Cloudflare API Token
kubectl create secret generic cloudflare-api-token --namespace cert-manager \
  --from-literal=api-token=<CLOUDFLARE_API_TOKEN> \
  --dry-run=client -o yaml \
  | kubeseal --format yaml --cert /tmp/sealed-secrets-cert.pem \
  > overlays/production/cloudflare-api-token-sealed.yaml

rm /tmp/sealed-secrets-cert.pem
```

SealedSecret を `overlays/production/kustomization.yaml` の resources に追加し、git commit & push。

#### Phase 3: 再 apply + 動作確認

```bash
kubectl kustomize overlays/production | kubectl --context fumo-k3s apply -f -
```

### 本番アクセス

| サービス | URL | ログイン方法 |
|---------|-----|-------------|
| ArgoCD | https://argocd.fumo.jp | `admin` / `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' --context fumo-k3s \| base64 -d` |
| Headlamp | https://headlamp.fumo.jp | ServiceAccount トークン |

## コンポーネント追加

1. `base/<name>.yaml` に Namespace + HelmChart CRD を記述
2. `base/kustomization.yaml` の resources に追加
3. 環境固有の設定は `overlays/*/patches/<name>-values.yaml` にパッチとして記述
