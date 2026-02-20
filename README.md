# fumo-k8s-platform

fumo homelab の Kubernetes platform 層 (ミドルウェア) マニフェスト管理リポジトリ。

## 前提条件

- Docker
- [k3d](https://k3d.io/)
- kubectl

> Helm CLI は不要。k3s HelmChart CRD でデプロイする。

## クイックスタート

```bash
make cluster-create   # k3d クラスタ作成 + アプリデプロイ
# Headlamp: http://headlamp.localhost
make cluster-delete   # クラスタ削除
```

## Makefile ターゲット

| ターゲット | 説明 |
|---|---|
| `cluster-create` | k3d クラスタ作成 + platform/ のアプリ自動デプロイ |
| `cluster-delete` | クラスタ削除 |

## ディレクトリ構造

```
fumo-k8s-platform/
├── k3d-config.yaml    # k3d クラスタ定義
├── Makefile
└── platform/           # k3s HelmChart CRD マニフェスト
    └── *.yaml          # アプリごとに1ファイル
```

## アプリ追加

`platform/<name>.yaml` に k3s HelmChart CRD を記述する。Makefile の変更は不要。
