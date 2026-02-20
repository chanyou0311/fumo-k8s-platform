# AGENTS.md

fumo homelab の Kubernetes platform 層マニフェスト管理リポジトリ。
k3d でローカル開発クラスタを立ち上げ、k3s HelmChart CRD でミドルウェアをデプロイする。

## 技術スタック

- **k3d** — ローカル開発用 k3s クラスタ
- **k3s HelmChart CRD** — Helm CLI 不要のアプリデプロイ

## ディレクトリ構造

```
fumo-k8s-platform/
├── k3d-config.yaml    # k3d クラスタ定義
├── Makefile            # cluster-create / cluster-delete
├── AGENTS.md           # (このファイル)
├── CLAUDE.md → AGENTS.md
├── README.md
└── platform/           # k3s HelmChart CRD マニフェスト
    └── *.yaml          # アプリごとに1ファイル
```

## Makefile ターゲット

- `make cluster-create` — k3d クラスタ作成 + `platform/` のアプリ自動デプロイ
- `make cluster-delete` — クラスタ削除

## platform/ へのアプリ追加

`platform/<name>.yaml` に HelmChart CRD を記述するだけでよい。Makefile の変更は不要。

k3s HelmChart CRD の基本形:

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: <app-name>
  namespace: kube-system
spec:
  repo: <helm-repo-url>
  chart: <chart-name>
  targetNamespace: <namespace>
  valuesContent: |-
    # 必要な values のみ記述
```

## コーディング規約

- 必要最小限の設定のみ記述し、デフォルト値は省略する (DP-1)

## 言語

日本語
