#!/usr/bin/env python3
"""
かずクイズ Google Cloud TTS (Neural2) 音声ファイル生成スクリプト

使い方:
  export GCLOUD_API_KEY="YOUR_API_KEY"
  python3 generate_sounds_gcloud.py
"""

import urllib.request
import urllib.error
import json
import base64
import os
import sys
import time

# ── 設定 ──────────────────────────────────────────
API_KEY    = os.environ.get("GCLOUD_API_KEY", "")
VOICE      = "ja-JP-Neural2-B"
LANG       = "ja-JP"
PITCH      = 2.0
RATE_NUM    = 0.78   # 数字
RATE_PHRASE = 0.80   # フレーズ
RATE_UI     = 0.90   # UI応答
URL = "https://texttospeech.googleapis.com/v1/text:synthesize"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sounds")

NUM_WORDS = ["", "いち", "に", "さん", "よん", "ご", "ろく", "なな", "はち", "きゅう", "じゅう"]

# ── ヘルパー ──────────────────────────────────────
def gen(text, filepath, rate=None, ssml=False):
    if rate is None:
        rate = RATE_PHRASE
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    label = text[:40]
    print(f"  {label:<40} → {os.path.basename(filepath)}")

    body = json.dumps({
        "input": {"ssml": text} if ssml else {"text": text},
        "voice": {"languageCode": LANG, "name": VOICE},
        "audioConfig": {
            "audioEncoding": "LINEAR16",
            "sampleRateHertz": 22050,
            "speakingRate": rate,
            "pitch": PITCH,
        },
    }).encode()

    req = urllib.request.Request(
        URL, data=body,
        headers={"Content-Type": "application/json", "X-Goog-Api-Key": API_KEY},
    )
    try:
        with urllib.request.urlopen(req) as res:
            d = json.load(res)
            audio = base64.b64decode(d["audioContent"])
            with open(filepath, "wb") as f:
                f.write(audio)
    except urllib.error.HTTPError as e:
        body_err = e.read().decode()
        print(f"    ❌ HTTPエラー {e.code}: {body_err[:120]}")
    except Exception as e:
        print(f"    ❌ エラー: {e}")

def p(path):
    return os.path.join(OUT, path)

# ── メイン ──────────────────────────────────────────
if not API_KEY:
    print("❌ GCLOUD_API_KEY が設定されていません。")
    print("   export GCLOUD_API_KEY=\"YOUR_KEY\" を実行してから再試行してください。")
    sys.exit(1)

print()
print("🎙  Google Cloud TTS (Neural2) で音声を生成しています...")

# ── 数字 1–10 ──────────────────────────────────────
print("\n【数字】")
for i in range(1, 11):
    gen(NUM_WORDS[i], p(f"nums/{i}.wav"), RATE_NUM)

# ── たしざん用フレーズ ─────────────────────────────
print("\n【たしざん用】")
gen("たす",              p("tasu.wav"),    RATE_NUM)
gen("は",                p("wa.wav"),      RATE_NUM)
gen("いくつ？",          p("ikutsu.wav"),  RATE_PHRASE)
gen("いくつ　あるかな？", p("q_count.wav"), RATE_PHRASE)

# ── かずならべ用 (18パターン、SSMLでポーズ制御) ────
print("\n【かずならべ用 (18パターン)】")
for start in range(1, 7):
    for blank in range(1, 4):
        parts = []
        for i in range(5):
            n = start + i
            word = "なに" if i == blank else NUM_WORDS[n]
            parts.append(f'{word}<break time="180ms"/>')
        ssml = f'<speak>{"".join(parts)}<break time="300ms"/>の　なにに　はいるかな？</speak>'
        gen(ssml, p(f"seq_{start}_{blank}.wav"), RATE_PHRASE, ssml=True)

# ── UIフレーズ ─────────────────────────────────────
print("\n【UIフレーズ】")
gen('<speak>いくつかな！<break time="200ms"/>はじめよう！</speak>', p("start_count.wav"), RATE_UI,  ssml=True)
gen('<speak>たしざん！<break time="200ms"/>はじめよう！</speak>',   p("start_add.wav"),   RATE_UI,  ssml=True)
gen('<speak>かずならべ！<break time="200ms"/>はじめよう！</speak>', p("start_seq.wav"),   RATE_UI,  ssml=True)
gen("せいかい！",   p("correct.wav"),        RATE_UI)
gen("ちがうよ",     p("wrong.wav"),           RATE_UI)
gen("こたえは",     p("answer_prefix.wav"),   RATE_PHRASE)

# ── 結果 ───────────────────────────────────────────
print("\n【結果】")
gen("ぜんぶ　せいかい！　かんぺき！",  p("result_score_6.wav"), RATE_PHRASE)
gen("5もん　せいかい！",               p("result_score_5.wav"), RATE_PHRASE)
gen("4もん　せいかい！",               p("result_score_4.wav"), RATE_PHRASE)
gen("3もん　せいかい！",               p("result_score_3.wav"), RATE_PHRASE)
gen("2もん　せいかい！",               p("result_score_2.wav"), RATE_PHRASE)
gen("1もん　せいかい！",               p("result_score_1.wav"), RATE_PHRASE)
gen("もう　いっかい　やってみよう！",  p("result_score_0.wav"), RATE_PHRASE)
gen("かんぺき！",       p("result_title_0.wav"), RATE_UI)
gen("すごい！",         p("result_title_1.wav"), RATE_UI)
gen("よくできました！", p("result_title_2.wav"), RATE_PHRASE)
gen("がんばれ！",       p("result_title_3.wav"), RATE_UI)

count = sum(1 for _, _, files in os.walk(OUT) for f in files if f.endswith(".wav"))
print(f"\n✅ 完了！ {count} ファイルを生成しました → sounds/")
