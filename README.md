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
│       └── patches/
├── k3d-config.yaml
└── Makefile
```

## コンポーネント追加

1. `base/<name>.yaml` に Namespace + HelmChart CRD を記述
2. `base/kustomization.yaml` の resources に追加
3. 環境固有の設定は `overlays/*/patches/<name>-values.yaml` にパッチとして記述
