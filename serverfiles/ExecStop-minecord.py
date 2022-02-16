#!/usr/bin/env python3
import os
from discord_webhook import DiscordWebhook
from dotenv import load_dotenv

# 環境変数を読み込む
load_dotenv()
WEBHOOK_URL = os.environ["WEBHOOK_URL"]

webhook = DiscordWebhook(url=WEBHOOK_URL, content="サーバを閉じます。")
webhook.execute()
