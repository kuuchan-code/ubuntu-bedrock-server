#!/usr/bin/env python3
import signal
import time
import os
import re
from watchdog.events import RegexMatchingEventHandler
from watchdog.observers import Observer
from discord_webhook import DiscordWebhook
from dotenv import load_dotenv

# 環境変数を読み込む
load_dotenv()
WEBHOOK_URL = os.environ["WEBHOOK_URL"]

webhook = DiscordWebhook(url=WEBHOOK_URL, content="[Mohist] サーバを開始します。")
webhook.execute()


def on_modified(event):
    if os.path.getsize(event.src_path) != 0:
        with open(event.src_path, "r") as file:
            last_line = file.readlines()[-1]
            if re.match('\[\d{2}:\d{2}:\d{2} INFO\]: (.*) logged in', last_line):
                connected_player_name = re.search(
                    '(?<=\[\d{2}:\d{2}:\d{2} INFO\]: )(.*)(?=\[)', last_line).group()
                webhook = DiscordWebhook(
                    url=WEBHOOK_URL, content='[Mohist] '+connected_player_name+'がゲームに参加しました。')
                webhook.execute()
            elif re.match('\[\d{2}:\d{2}:\d{2} INFO\]: (.*) left the game', last_line):
                disconnected_player_name = re.search(
                    '(?<=\[\d{2}:\d{2}:\d{2} INFO\]: )(.*)(?= left the game)', last_line).group()
                webhook = DiscordWebhook(
                    url=WEBHOOK_URL, content='[Mohist] '+disconnected_player_name+'がゲームから退出しました。')
                webhook.execute()


def handler(_signum, _frame):
    observer.stop()
    observer.join()
    exit(0)


event_handler = RegexMatchingEventHandler('^\./latest\.log$')
event_handler.on_modified = on_modified
path = "."
observer = Observer()
observer.schedule(event_handler, path, recursive=False)
observer.start()
signal.signal(signal.SIGTERM, handler)
signal.signal(signal.SIGINT, handler)

while True:
    time.sleep(1)
