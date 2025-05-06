# ubuntu-bedrock-server

Minecraft 統合版 (Bedrock Edition) および Java版サーバーを Ubuntu 上で簡単に管理するためのスクリプト群です。

## 特徴

- **systemd連携**: `systemctl` コマンドでサーバーの起動・停止・再起動を管理できます。サーバーがクラッシュした場合には自動的に再起動します。
- **コマンド実行**: `socket` を介して、いつでもサーバー権限でMinecraftコマンドを標準入力に送信できます。標準出力のログも取得可能です。
- **定期処理**: `cron` を利用して、定期的なバックアップとサーバー再起動を自動化します。
- **複数サーバー対応**: 同一ホスト上で複数のMinecraftサーバーを個別に設定・管理できます。
- **シンプルな構成**: `setup.sh` を除き、各スクリプトは比較的シンプルな構成になっています。
- **Discord連携**: Webhook を利用して、サーバーの起動・停止状況やプレイヤーの参加・退出をDiscordに通知できます。

## 動作要件

以下のPythonパッケージが必要です。

```sh
pip install watchdog discord_webhook dotenv
```

## セットアップ

1.  **リポジトリのクローンとセットアップスクリプトの実行**

    ```sh
    git clone https://github.com/あなたのユーザー名/ubuntu-bedrock-server.git # もしクローンしていない場合
    cd ubuntu-bedrock-server
    ./setup.sh
    ```

    セットアップスクリプトを実行すると、設定するサーバー名やDiscord Webhook URLなどを対話形式で入力します。

    **セットアップ例:**

    ```txt
    Enter the server name to be configured, separated by a space: KuuServer KuuPrivateServer GeyserMC
    Enter KuuServer execution command (LD_LIBRARY_PATH=. ./bedrock_server)
    Enter the webhook URL of the discord you want to output the status of KuuServer: https://discord.com/api/webhooks/your/webhook_url_1
    Install KuuServer.service into /etc/systemd/system/
    Install KuuServer.socket into /etc/systemd/system/
    Reload systemd manager configuration
    Enable KuuServer.service

    Enter KuuPrivateServer execution command (LD_LIBRARY_PATH=. ./bedrock_server)
    Enter the webhook URL of the discord you want to output the status of KuuPrivateServer: https://discord.com/api/webhooks/your/webhook_url_2
    Install KuuPrivateServer.service into /etc/systemd/system/
    Install KuuPrivateServer.socket into /etc/systemd/system/
    Reload systemd manager configuration
    Enable KuuPrivateServer.service

    Enter GeyserMC execution command (LD_LIBRARY_PATH=. ./bedrock_server) java -Xms1G -Xmx1G -jar paper-1.18.1-175.jar --nogui
    Enter the webhook URL of the discord you want to output the status of GeyserMC: https://discord.com/api/webhooks/your/webhook_url_3
    Install GeyserMC.service into /etc/systemd/system/
    Install GeyserMC.socket into /etc/systemd/system/
    Reload systemd manager configuration
    Enable GeyserMC.service

    Export the root crontab
    Completed setup
    ```

    上記の設定により、ホームディレクトリ (`~/`) 配下に各サーバー名のディレクトリ (例: `~/KuuServer`, `~/KuuPrivateServer`) が作成され、必要なファイルが配置されます。

2.  **サーバー本体の設置**

    各サーバーのディレクトリ (例: `~/KuuServer`) に、Minecraftサーバー本体のファイル群を配置します。
    -   **Bedrock Edition**: [Minecraft Bedrock Edition Server Download](https://www.minecraft.net/en-us/download/server/bedrock) からダウンロードしてください。
    -   **Java Edition**: PaperMC、SpigotMCなどのサーバーソフトウェアをダウンロードしてください。

    複数のサーバーを運用する場合は、`server.properties` ファイル内のポート番号 (`server-port`) が重複しないように設定してください。

3.  **【任意】複数サーバー起動順序の設定 (統合版)**

    複数の統合版サーバーを実行し、特定のサーバー (例: 19132ポートを使用するメインサーバー) を優先的に起動したい場合は、systemd のユニットファイル (`/etc/systemd/system/サーバー名.service`) に `After` または `Before` ディレクティブを追加して起動順序を制御してください。

    例: `KuuServer.service` が `AnotherServer.service` の後に起動する場合

    ```systemd
    [Unit]
    Description=KuuServer
    After=network-online.target AnotherServer.service
    ```

## 使い方

各コマンドの `servername` の部分は、セットアップ時に指定したサーバー名に置き換えてください。

-   **サーバーの起動**
    ```sh
    sudo systemctl start servername.service
    ```

-   **サーバーの停止 (バックアップなし)**
    ```sh
    sudo systemctl stop servername.service
    ```

-   **サーバーの再起動 (バックアップなし)**
    ```sh
    sudo systemctl restart servername.service
    ```

-   **サーバーの状態確認**
    ```sh
    sudo systemctl status servername.service
    ```
    ログは `~/servername/latest.log` にも出力されます。

-   **サーバーコマンドの実行**
    ```sh
    echo 'say Hello World' > /run/servername.stdin
    ```

-   **設定した全てのサーバーの停止・バックアップ・再起動 (cronで毎日実行される処理)**
    ```sh
    ~/.ubuntu-bedrock-server/stop-backup-and-restart.sh
    ```
    このスクリプトは、毎日午前4時30分 (2日目以降) に自動実行されるようcronに登録されます。 (初回セットアップ時)
    毎月1日の午前4時30分には `systemctl reboot` が実行されます。

-   **個別のサーバーの停止とバックアップ**
    ```sh
    ~/servername/stop-and-backup-for-restart.sh
    ```
    実行後、サーバーを再開するには以下のコマンドを実行してください。
    ```sh
    sudo systemctl start servername.service
    ```

## アンインストール

1.  **systemdサービスの無効化と削除**
    ```sh
    sudo systemctl stop 不要なサーバ名.service
    sudo systemctl disable 不要なサーバ名.service
    sudo rm /etc/systemd/system/不要なサーバ名.service
    sudo rm /etc/systemd/system/不要なサーバ名.socket
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    ```

2.  **サーバーディレクトリの削除**
    ```sh
    sudo rm -r ~/不要なサーバ名
    ```

3.  **cron設定の編集**

    *   **特定のサーバーのみをcronの対象から削除する場合:**
        `~/.ubuntu-bedrock-server/stop-backup-and-restart.sh` ファイルを編集し、該当するサーバーの以下の2行を削除します。
        ```sh
        /home/ユーザ名/不要なサーバ名/stop-and-backup-for-restart.sh
        systemctl restart 不要なサーバ名.service
        ```

    *   **全てのサーバーを削除し、cron設定も全て削除する場合:**
        まず、関連ディレクトリを削除します。
        ```sh
        sudo rm -r ~/.ubuntu-bedrock-server
        ```
        次に、rootユーザーのcrontabを編集します。
        ```sh
        sudo crontab -e
        ```
        以下の行を削除します。
        ```txt
        30 4 1 * * systemctl reboot
        30 4 2-31 * * /home/ユーザ名/.ubuntu-bedrock-server/stop-backup-and-restart.sh
        ```

## ライセンス

このプロジェクトは MIT License のもとで公開されています。詳細は `LICENSE` ファイルをご覧ください。
