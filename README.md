# ubuntu-bedrock-server

Ubuntu の Minecraft 統合版サーバ管理のスクリプトです。サーバの実行コマンドを変えれば Java 版のサーバにも使えます。

## 出来ること

- systemctl でサーバを操作できます。もしクラッシュしたら自動的に再スタートされます。
- socket でサーバ権限の Minecraft コマンドをいつでも標準入力できます。標準出力のログをとれます。
- cron で定期的にバックアップ・再起動できます。
- 複数のサーバを建てられます。
- setup.sh 以外のコードは割とシンプルかなと思います。
- webhook でサーバの状況とユーザーの入退出を Discord に出せます。

## タスク

- 現在の設定を読み込めるようにする

## 要件

- `pip install watchdog discord_webhook dotenv`

## サーバの設定

1. サーバのセットアップを開始する

   ```sh
   cd ubuntu-bedrock-server
   ./setup.sh
   ```

   セットアップ例:

   ```txt
   Enter the server name to be configured, separated by a space: KuuServer KuuPrivateServer GeyserMC
   Enter KuuServer execution command (LD_LIBRARY_PATH=. ./bedrock_server)
   Enter the webhook URL of the discord you want to output the status of KuuServer: foo
   Install KuuServer.service into /etc/systemd/system/
   Install KuuServer.socket into /etc/systemd/system/
   Reload systemd manager configuration
   Enable KuuServer.service

   Enter KuuPrivateServer execution command (LD_LIBRARY_PATH=. ./bedrock_server)
   Enter the webhook URL of the discord you want to output the status of KuuPrivateServer: bar
   Install KuuPrivateServer.service into /etc/systemd/system/
   Install KuuPrivateServer.socket into /etc/systemd/system/
   Reload systemd manager configuration
   Enable KuuPrivateServer.service

   Enter GeyserMC execution command (LD_LIBRARY_PATH=. ./bedrock_server) java -Xms1G -Xmx1G -jar paper-1.18.1-175.jar --nogui
   Enter the webhook URL of the discord you want to output the status of GeyserMC: baz
   Install GeyserMC.service into /etc/systemd/system/
   Install GeyserMC.socket into /etc/systemd/system/
   Reload systemd manager configuration
   Enable GeyserMC.service

   Export the root crontab
   Completed setup
   ```

   ホームディレクトリにサーバディレクトリが作成される

2. 追加の設定

   統合版の複数のサーバを実行したい場合は先に 19132 ポートを使用するサーバを起動するように、systemd のユニットに After または Before ディレクティブでユニットを指定する。

3. サーバ本体を設置

   統合版<https://www.minecraft.net/en-us/download/server/bedrock>や Java 版のサーバ本体をダウンロードして、ホームのサーバ名ディレクトリ直下に展開する。複数サーバをたてる際にはポートが重複しないように注意して server.properties を設定する。

## 使い方

1. サーバの開始

   ```sh
   sudo systemctl start servername
   ```

2. サーバの状態をチェックする

   ```sh
   sudo systemctl status servername
   ```

3. サーバコマンドの入力
   ```sh
   echo 'servercommand' > /run/servername.stdin
   ```

- 設定した全サーバの停止とバックアップと再スタート

  ```sh
  ~/.ubuntu-bedrock-server/stop-backup-and-restart.sh
  ```

- 個別のサーバの停止とバックアップ

  ```sh
  ~/servername/stop-and-backup-for-restart.sh
  ```

- サーバの再スタートまたは再開

  ```sh
  sudo systemctl restart servername
  ```

- バックアップせずにサーバを停止

  ```sh
  sudo systemctl stop servername
  ```

## アンインストール

1. サーバデーモンの削除
   ```sh
    sudo systemctl disable 不要なサーバ名
    sudo rm /etc/systemd/system/不要なサーバ名.service
    sudo rm -r ~/不要なサーバ名
   ```
2. cron で行われる内容の編集
   - いくつかのサーバを削除したい場合
     ```sh
     vim ~/.ubuntu-bedrock-server/stop-backup-and-restart.sh
     ```
     以下の行を削除
     ```txt
     /home/ユーザー名/不要なサーバ名/stop-and-backup-for-restart.sh
     systemctl restart 不要なサーバ名
     ```
   - すべてのサーバを削除したい場合
     ```sh
     sudo rm -r ~/.ubuntu-bedrock-server
     ```
     ```sh
     sudo crontab -e
     ```
     以下の行を削除
     ```txt
     0 5 * * * /home/ユーザー名/.ubuntu-bedrock-server/stop-backup-and-restart.sh
     ```
