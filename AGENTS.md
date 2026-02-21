# AGENTS.md

fumo homelab の Kubernetes platform 層マニフェスト管理リポジトリ。
k3d でローカル開発クラスタを立ち上げ、Kustomize overlay + k3s HelmChart CRD でミドルウェアをデプロイする。

## 技術スタック

- **Kustomize** — 環境別マニフェスト管理 (base + overlays)
- **k3s HelmChart CRD** — Helm CLI 不要の宣言的デプロイ
- **k3d** — ローカル開発用 k3s クラスタ
- **Sealed Secrets** — シークレット暗号化 (自動生成鍵)

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
│   │       ├── argocd-values.yaml
│   │       └── headlamp-values.yaml
│   └── production/               # 本番 k3s 用
│       ├── kustomization.yaml
│       ├── cert-manager-issuer.yaml
│       └── patches/
│           ├── argocd-values.yaml
│           └── headlamp-values.yaml
├── secrets/                      # (将来の拡張用)
├── k3d-config.yaml
├── Makefile
└── README.md
```

## Makefile ターゲット

- `make cluster-create` — kustomize build → k3d クラスタ作成
- `make cluster-delete` — クラスタ削除 + 一時ファイル cleanup
- `make manifests` — kustomize build 出力を表示

## コンポーネント追加

1. `base/<name>.yaml` に Namespace + HelmChart CRD を記述
2. `base/kustomization.yaml` の resources に追加
3. 環境固有の設定は `overlays/*/patches/<name>-values.yaml` にパッチとして記述

HelmChart CRD の基本形:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <namespace>
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: <app-name>
  namespace: kube-system
spec:
  repo: <helm-repo-url>
  chart: <chart-name>
  targetNamespace: <namespace>
```

## SealedSecret 作成

### ローカル環境
ローカル環境では暗号化不要。平文 Secret を overlay に直接配置する。

### 本番環境
本番クラスタから証明書を取得して暗号化する:

```bash
# 本番クラスタから証明書を取得
kubeseal --controller-namespace sealed-secrets --fetch-cert \
  --context fumo-k3s > /tmp/sealed-secrets-cert.pem

# 平文 Secret を作成 (apply しない)
kubectl create secret generic <name> --namespace <ns> \
  --from-literal=key=value --dry-run=client -o yaml > /tmp/secret.yaml

# 暗号化
kubeseal --format yaml --cert /tmp/sealed-secrets-cert.pem \
  < /tmp/secret.yaml > sealed-secret.yaml

# 一時ファイルを削除
rm /tmp/secret.yaml /tmp/sealed-secrets-cert.pem
```

## ローカル環境アクセス

- **ArgoCD**: http://argocd.localhost — `admin` / `admin`
- **Headlamp**: http://headlamp.localhost — トークン取得: `kubectl get secret headlamp-token -n headlamp -o jsonpath='{.data.token}' | base64 -d`

## コーディング規約

- 必要最小限の設定のみ記述し、デフォルト値は省略する (DP-1)
- Namespace はマニフェストで宣言的に定義する (DP-2)

## 言語

日本語
