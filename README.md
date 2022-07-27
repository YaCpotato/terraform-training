# my-eco-ruler-terraform

## 概要

my-eco-ruler の qa(dev, stg)、production 環境のインフラ構築用 Terraform

## 構成

テンプレートから若干カスタムが入るので、TBW

## 環境

Terraform 1.1.8

## セットアップ

### コンテナのビルド(初回のみ)

```bash
$ cp -rp .env.default .env
$ docker compose build
```

### 環境変数設定

`.env`に AWS IAM ユーザーのアクセスキー、シークレットアクセスキーを設定

```
AWS_ACCESS_KEY_ID=HOGE
AWS_SECRET_ACCESS_KEY=FUGA
AWS_DEFAULT_REGION=ap-northeast-1
```

### コンテナの起動

```bash
$ docker compose up
```

### コンテナに入る

```bash
$ docker compose exec terraform /bin/ash
```

### tfstate 格納用の S3 バケット作成(初回のみ)

- チーム開発のため、`tfstate`は S3 バケットに**環境別**で保管
  - バケット名は`env/xx(環境別)/backend.tf`で指定
- `your-application-xx`バケットが存在しない場合、aws-cli から作成
  ```bash
  $ aws s3api create-bucket --bucket your-application-xx \
  --create-bucket-configuration LocationConstraint=ap-northeast-1
  ```
- バージョニング、暗号化(SSE-S3)、ブロックパブリックアクセスを設定

  ```
  # バージョニング
  $ aws s3api put-bucket-versioning --bucket your-application-xx \
    --versioning-configuration Status=Enabled

  # 暗号化
  $ aws s3api put-bucket-encryption --bucket your-application-xx \
    --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

  # パブリックアクセスブロック
  $ aws s3api put-public-access-block --bucket your-application-xx \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'
  ```

### tfstate 格納先設定の更新

- terraform 上の tfstate 格納先設定の記述を、新しく作成した tfstate 格納用の S3 バケットに更新する
  - `/env/xx(環境別)/backend.tf`
    - `bucket = "your-application-xx"`

### ドメイン取得

Route53 からドメインを取得する

### locals(変数)のセット

- `/env/xx(環境別)/locals.tf`にて、プロジェクトに合わせて各リソースのパラメーターを更新する
  - e.g.
    - リソースに一括付与するタグの更新
    - 作成する EC2 の基となる AMI の更新
    - 取得したドメインの記載
    - ネットワーク構成の変更
    - 各リソースのスペック変更

## リソース作成

```bash
# コンテナ内で
$ cd env/qa # もしくは cd env/production

# 作業ディレクトリの初期化
$ terraform init

# 実行内容の確認
$ terraform plan

# 実行
$ terraform apply
```

## リソース削除

```bash
# コンテナ内で
$ cd env/qa # もしくは cd env/production

# 実行内容の確認
$ terraform plan -destroy

# 実行
$ terraform destroy
```

## tips

### terraform apply について

#### 初回の`terraform apply`によるリソース作成後にやること

- RDS のパスワードを変更する
  - terraform 上に記載した値は、tfstate に平文で記載されるため、秘匿情報についてはリソース作成後に値を変更する
  - [参考](https://qiita.com/minamijoyo/items/1f57c62bed781ab8f4d7#%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%B7%AE%E5%88%86%E3%82%92%E7%84%A1%E8%A6%96%E3%81%99%E3%82%8B)
- SES の sandbox モードを解除する
- Amazon WorkMail の導入(現状、terraform では作成できない)

#### terraform で作成したリソースの更新について

terraform で作成されたリソースを更新する場合、コンソールから手動で更新することは非推奨。手動更新の場合は当然 tfstate が更新されず、terraform が把握している AWS の状態と実際の状態に差分が生まれ、エラーとなる

### locals(変数) について

- 変数を`env/xx(環境別)/locals.tf`で管理
- モジュール内の各設定値を変数に切り出したい場合は、`env/xx(環境別)/locals.tf`に追記

### terraform destroy について

#### `terraform destroy`時、`Error: deleting S3 Bucket (prologue-terraform-qa-s3-waf-log): BucketNotEmpty: The bucket you tried to delete is not empty`が発生する

バケットが空でない場合はバケットを削除できないため、コンソールからバケットの中身を削除し、改めて`terraform destroy`を実行する。

#### 削除保護について

production 環境については、削除保護を有効にしているリソース(ELB, RDS, EC2)がある。そのため、リソースを削除したい場合はまず削除保護を無効にして(`deletion_protection = false` → `terraform apply`)から、`terraform destroy`を行う。

### terraform plan 実行時の差分について

- 変更内容によっては既存のリソースを削除して新しいリソースを作成するケースがある。この場合、リソース削除により稼働中のサービスがダウンしてしまう等影響があるため、`terraform plan`を実行した場合は必ず変更内容を確認すること
  - 詳細は[Pragmatic Terraform on AWS](https://drive.google.com/file/d/1VN7Ibl_LkGQjfJpuh4DLgqgs-DGN05sz/view?usp=sharing)の第 3 章を確認すること

### qa(dev, stg)

- dev, stg 環境で共有するリソース
  - VPC 等ネットワーク
  - 各種セキュリティグループ
  - RDS
  - WAF(Kinesis Data Filehose 含む)
  - ElastiCache(Redis)
