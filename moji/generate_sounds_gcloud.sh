#!/bin/bash
# ============================================================
# Google Cloud TTS (Neural2) 音声ファイル一括生成スクリプト
#
# 事前準備:
#   1. https://console.cloud.google.com/ でプロジェクト作成
#   2. Cloud Text-to-Speech API を有効化
#   3. APIキーを作成し、下記 GCLOUD_API_KEY に設定
#      または環境変数: export GCLOUD_API_KEY="YOUR_KEY"
# ============================================================

API_KEY="${GCLOUD_API_KEY:-}"
if [ -z "$API_KEY" ]; then
  echo "❌ APIキーが設定されていません。"
  echo "   export GCLOUD_API_KEY=\"YOUR_API_KEY\" を実行してから再試行してください。"
  exit 1
fi

VOICE_NAME="ja-JP-Neural2-B"   # 高品質女性音声
LANG="ja-JP"
RATE_WORD=0.85    # 単語: やや遅め (1.0=標準)
RATE_PHRASE=0.80  # フレーズ: ゆっくり
PITCH=2.0         # わずかに高め (子ども向け)
OUT="$(cd "$(dirname "$0")" && pwd)/sounds"
API_URL="https://texttospeech.googleapis.com/v1/text:synthesize"

mkdir -p "$OUT/words" "$OUT/chars"

# ── テキスト → WAV 生成ヘルパー ──
gen_text() {
  local text="$1"
  local file="$2"
  local rate="${3:-$RATE_WORD}"

  printf "  %-24s → %s\n" "$text" "$(basename "$file")"

  local body
  body=$(cat <<EOF
{
  "input": { "text": "$text" },
  "voice": { "languageCode": "$LANG", "name": "$VOICE_NAME" },
  "audioConfig": {
    "audioEncoding": "LINEAR16",
    "sampleRateHertz": 22050,
    "speakingRate": $rate,
    "pitch": $PITCH
  }
}
EOF
)

  local response
  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-Goog-Api-Key: $API_KEY" \
    --data "$body" \
    "$API_URL")

  local audio
  audio=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('audioContent',''))" 2>/dev/null)

  if [ -z "$audio" ]; then
    echo "    ⚠️  失敗: $text"
    echo "    レスポンス: $response" >&2
    return 1
  fi

  echo "$audio" | base64 --decode > "$file"
}

# ── SSML（ポーズ付き）→ WAV 生成ヘルパー ──
gen_ssml() {
  local ssml="$1"
  local file="$2"
  local rate="${3:-$RATE_PHRASE}"

  printf "  %-24s → %s\n" "(ssml)" "$(basename "$file")"

  # SSMLの特殊文字をエスケープ
  local escaped
  escaped=$(echo "$ssml" | sed 's/"/\\"/g')

  local body
  body=$(cat <<EOF
{
  "input": { "ssml": "$escaped" },
  "voice": { "languageCode": "$LANG", "name": "$VOICE_NAME" },
  "audioConfig": {
    "audioEncoding": "LINEAR16",
    "sampleRateHertz": 22050,
    "speakingRate": $rate,
    "pitch": $PITCH
  }
}
EOF
)

  local response
  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-Goog-Api-Key: $API_KEY" \
    --data "$body" \
    "$API_URL")

  local audio
  audio=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('audioContent',''))" 2>/dev/null)

  if [ -z "$audio" ]; then
    echo "    ⚠️  失敗"
    echo "    レスポンス: $response" >&2
    return 1
  fi

  echo "$audio" | base64 --decode > "$file"
}

echo ""
echo "🎙  Google Cloud TTS (Neural2) で音声を生成しています..."
echo ""

# ════════════════════════════════════
# UIフレーズ (SSML でポーズ制御)
# ════════════════════════════════════
echo "【フレーズ】"
gen_text "はじめのもじはどれかな？" "$OUT/q_hint.wav" 0.80
gen_ssml "<speak>ひらがな！<break time='200ms'/>はじめよう！</speak>"                                              "$OUT/start_hira.wav"  0.85
gen_ssml "<speak>カタカナ！<break time='200ms'/>はじめよう！</speak>"                                              "$OUT/start_kata.wav"  0.85
gen_text "すごい！"       "$OUT/praise_0.wav"    0.90
gen_text "やったー！"     "$OUT/praise_1.wav"    0.90
gen_text "えらい！"       "$OUT/praise_2.wav"    0.90
gen_text "かしこい！"     "$OUT/praise_3.wav"    0.90
gen_text "ばっちり！"     "$OUT/praise_4.wav"    0.90
gen_text "さいこう！"     "$OUT/praise_5.wav"    0.90
gen_text "よくできた！"   "$OUT/praise_6.wav"    0.90
gen_text "ぴんぽーん！"   "$OUT/praise_7.wav"    0.90
gen_text "せいかい！"     "$OUT/correct.wav"     0.88
gen_text "ちがうよ"       "$OUT/wrong.wav"       0.88
gen_text "こたえは"       "$OUT/answer_prefix.wav" 0.82

# ════════════════════════════════════
# 単語 (43語)
# ════════════════════════════════════
echo ""
echo "【単語】"
gen_text "あり"         "$OUT/words/あり.wav"
gen_text "いぬ"         "$OUT/words/いぬ.wav"
gen_text "うさぎ"       "$OUT/words/うさぎ.wav"
gen_text "えんぴつ"     "$OUT/words/えんぴつ.wav"
gen_text "おにぎり"     "$OUT/words/おにぎり.wav"
gen_text "かさ"         "$OUT/words/かさ.wav"
gen_text "きつね"       "$OUT/words/きつね.wav"
gen_text "くつ"         "$OUT/words/くつ.wav"
gen_text "ケーキ"       "$OUT/words/けーき.wav"
gen_text "コアラ"       "$OUT/words/こあら.wav"
gen_text "さかな"       "$OUT/words/さかな.wav"
gen_text "しんかんせん" "$OUT/words/しんかんせん.wav"
gen_text "すいか"       "$OUT/words/すいか.wav"
gen_text "せっけん"     "$OUT/words/せっけん.wav"
gen_text "そら"         "$OUT/words/そら.wav"
gen_text "たこ"         "$OUT/words/たこ.wav"
gen_text "ちょうちょ"   "$OUT/words/ちょうちょ.wav"
gen_text "つき"         "$OUT/words/つき.wav"
gen_text "てんとうむし" "$OUT/words/てんとうむし.wav"
gen_text "とり"         "$OUT/words/とり.wav"
gen_text "なす"         "$OUT/words/なす.wav"
gen_text "にじ"         "$OUT/words/にじ.wav"
gen_text "ぬいぐるみ"   "$OUT/words/ぬいぐるみ.wav"
gen_text "ねこ"         "$OUT/words/ねこ.wav"
gen_text "のりもの"     "$OUT/words/のりもの.wav"
gen_text "はな"         "$OUT/words/はな.wav"
gen_text "ひこうき"     "$OUT/words/ひこうき.wav"
gen_text "ふね"         "$OUT/words/ふね.wav"
gen_text "へび"         "$OUT/words/へび.wav"
gen_text "ほし"         "$OUT/words/ほし.wav"
gen_text "まる"         "$OUT/words/まる.wav"
gen_text "みかん"       "$OUT/words/みかん.wav"
gen_text "むし"         "$OUT/words/むし.wav"
gen_text "めがね"       "$OUT/words/めがね.wav"
gen_text "もも"         "$OUT/words/もも.wav"
gen_text "やま"         "$OUT/words/やま.wav"
gen_text "ゆき"         "$OUT/words/ゆき.wav"
gen_text "よる"         "$OUT/words/よる.wav"
gen_text "ライオン"     "$OUT/words/らいおん.wav"
gen_text "りんご"       "$OUT/words/りんご.wav"
gen_text "レモン"       "$OUT/words/れもん.wav"
gen_text "ロケット"     "$OUT/words/ろけっと.wav"
gen_text "わに"         "$OUT/words/わに.wav"

# ════════════════════════════════════
# ひらがな文字
# ════════════════════════════════════
echo ""
echo "【ひらがな文字】"
for char in あ い う え お か き く け こ さ し す せ そ た ち つ て と な に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ ろ わ を ん; do
  gen_text "$char" "$OUT/chars/${char}.wav" 0.75
done

# ════════════════════════════════════
# おぼえるモード: 文字＋単語を1ファイルに (SSML)
# 「あ」→ポーズ→「あり」を自然につなげる
# ════════════════════════════════════
echo ""
echo "【おぼえるモード：文字＋単語】"
mkdir -p "$OUT/learn"
RL=0.82   # おぼえるモード用レート

# あ行
gen_ssml '<speak>あ<break time="500ms"/>あり</speak>'             "$OUT/learn/あ.wav" $RL
gen_ssml '<speak>い<break time="500ms"/>いぬ</speak>'             "$OUT/learn/い.wav" $RL
gen_ssml '<speak>う<break time="500ms"/>うさぎ</speak>'           "$OUT/learn/う.wav" $RL
gen_ssml '<speak>え<break time="500ms"/>えんぴつ</speak>'         "$OUT/learn/え.wav" $RL
gen_ssml '<speak>お<break time="500ms"/>おにぎり</speak>'         "$OUT/learn/お.wav" $RL
# か行
gen_ssml '<speak>か<break time="500ms"/>かさ</speak>'             "$OUT/learn/か.wav" $RL
gen_ssml '<speak>き<break time="500ms"/>きつね</speak>'           "$OUT/learn/き.wav" $RL
gen_ssml '<speak>く<break time="500ms"/>くつ</speak>'             "$OUT/learn/く.wav" $RL
gen_ssml '<speak>け<break time="500ms"/>ケーキ</speak>'           "$OUT/learn/け.wav" $RL
gen_ssml '<speak>こ<break time="500ms"/>コアラ</speak>'           "$OUT/learn/こ.wav" $RL
# が行
gen_ssml '<speak>が<break time="500ms"/>学校</speak>'             "$OUT/learn/が.wav" $RL
gen_ssml '<speak>ぎ<break time="500ms"/>牛乳</speak>'             "$OUT/learn/ぎ.wav" $RL
gen_ssml '<speak>ぐ<break time="500ms"/>グミ</speak>'             "$OUT/learn/ぐ.wav" $RL
gen_ssml '<speak>げ<break time="500ms"/>ゲーム</speak>'           "$OUT/learn/げ.wav" $RL
gen_ssml '<speak>ご<break time="500ms"/>ゴリラ</speak>'           "$OUT/learn/ご.wav" $RL
# さ行
gen_ssml '<speak>さ<break time="500ms"/>さかな</speak>'           "$OUT/learn/さ.wav" $RL
gen_ssml '<speak>し<break time="500ms"/>新幹線</speak>'           "$OUT/learn/し.wav" $RL
gen_ssml '<speak>す<break time="500ms"/>すいか</speak>'           "$OUT/learn/す.wav" $RL
gen_ssml '<speak>せ<break time="500ms"/>せっけん</speak>'         "$OUT/learn/せ.wav" $RL
gen_ssml '<speak>そ<break time="500ms"/>そら</speak>'             "$OUT/learn/そ.wav" $RL
# ざ行
gen_ssml '<speak>ざ<break time="500ms"/>ザリガニ</speak>'         "$OUT/learn/ざ.wav" $RL
gen_ssml '<speak>じ<break time="500ms"/>自転車</speak>'           "$OUT/learn/じ.wav" $RL
gen_ssml '<speak>ず<break time="500ms"/>ズボン</speak>'           "$OUT/learn/ず.wav" $RL
gen_ssml '<speak>ぜ<break time="500ms"/>ゼリー</speak>'           "$OUT/learn/ぜ.wav" $RL
gen_ssml '<speak>ぞ<break time="500ms"/>ぞう</speak>'             "$OUT/learn/ぞ.wav" $RL
# た行
gen_ssml '<speak>た<break time="500ms"/>たこ</speak>'             "$OUT/learn/た.wav" $RL
gen_ssml '<speak>ち<break time="500ms"/>ちょうちょ</speak>'       "$OUT/learn/ち.wav" $RL
gen_ssml '<speak>つ<break time="500ms"/>つき</speak>'             "$OUT/learn/つ.wav" $RL
gen_ssml '<speak>て<break time="500ms"/>てんとうむし</speak>'     "$OUT/learn/て.wav" $RL
gen_ssml '<speak>と<break time="500ms"/>とり</speak>'             "$OUT/learn/と.wav" $RL
# だ行
gen_ssml '<speak>だ<break time="500ms"/>だんご</speak>'           "$OUT/learn/だ.wav" $RL
gen_text  "ぢ"                                                     "$OUT/learn/ぢ.wav" 0.75
gen_text  "づ"                                                     "$OUT/learn/づ.wav" 0.75
gen_ssml '<speak>で<break time="500ms"/>でんしゃ</speak>'         "$OUT/learn/で.wav" $RL
gen_ssml '<speak>ど<break time="500ms"/>どんぐり</speak>'         "$OUT/learn/ど.wav" $RL
# な行
gen_ssml '<speak>な<break time="500ms"/>なす</speak>'             "$OUT/learn/な.wav" $RL
gen_ssml '<speak>に<break time="500ms"/>にじ</speak>'             "$OUT/learn/に.wav" $RL
gen_ssml '<speak>ぬ<break time="500ms"/>ぬいぐるみ</speak>'       "$OUT/learn/ぬ.wav" $RL
gen_ssml '<speak>ね<break time="500ms"/>ねこ</speak>'             "$OUT/learn/ね.wav" $RL
gen_ssml '<speak>の<break time="500ms"/>のりもの</speak>'         "$OUT/learn/の.wav" $RL
# は行
gen_ssml '<speak>は<break time="500ms"/>はな</speak>'             "$OUT/learn/は.wav" $RL
gen_ssml '<speak>ひ<break time="500ms"/>飛行機</speak>'           "$OUT/learn/ひ.wav" $RL
gen_ssml '<speak>ふ<break time="500ms"/>ふね</speak>'             "$OUT/learn/ふ.wav" $RL
gen_ssml '<speak>へ<break time="500ms"/>へび</speak>'             "$OUT/learn/へ.wav" $RL
gen_ssml '<speak>ほ<break time="500ms"/>ほし</speak>'             "$OUT/learn/ほ.wav" $RL
# ば行
gen_ssml '<speak>ば<break time="500ms"/>バナナ</speak>'           "$OUT/learn/ば.wav" $RL
gen_ssml '<speak>び<break time="500ms"/>ビー玉</speak>'           "$OUT/learn/び.wav" $RL
gen_ssml '<speak>ぶ<break time="500ms"/>ぶどう</speak>'           "$OUT/learn/ぶ.wav" $RL
gen_ssml '<speak>べ<break time="500ms"/>べんとう</speak>'         "$OUT/learn/べ.wav" $RL
gen_ssml '<speak>ぼ<break time="500ms"/>ボール</speak>'           "$OUT/learn/ぼ.wav" $RL
# ぱ行
gen_ssml '<speak>ぱ<break time="500ms"/>パイナップル</speak>'     "$OUT/learn/ぱ.wav" $RL
gen_ssml '<speak>ぴ<break time="500ms"/>ピアノ</speak>'           "$OUT/learn/ぴ.wav" $RL
gen_ssml '<speak>ぷ<break time="500ms"/>プレゼント</speak>'       "$OUT/learn/ぷ.wav" $RL
gen_ssml '<speak>ぺ<break time="500ms"/>ペンギン</speak>'         "$OUT/learn/ぺ.wav" $RL
gen_ssml '<speak>ぽ<break time="500ms"/>ポスト</speak>'           "$OUT/learn/ぽ.wav" $RL
# ま行
gen_ssml '<speak>ま<break time="500ms"/>まる</speak>'             "$OUT/learn/ま.wav" $RL
gen_ssml '<speak>み<break time="500ms"/>みかん</speak>'           "$OUT/learn/み.wav" $RL
gen_ssml '<speak>む<break time="500ms"/>むし</speak>'             "$OUT/learn/む.wav" $RL
gen_ssml '<speak>め<break time="500ms"/>めがね</speak>'           "$OUT/learn/め.wav" $RL
gen_ssml '<speak>も<break time="500ms"/>もも</speak>'             "$OUT/learn/も.wav" $RL
# や行
gen_ssml '<speak>や<break time="500ms"/>やま</speak>'             "$OUT/learn/や.wav" $RL
gen_ssml '<speak>ゆ<break time="500ms"/>ゆき</speak>'             "$OUT/learn/ゆ.wav" $RL
gen_ssml '<speak>よ<break time="500ms"/>よる</speak>'             "$OUT/learn/よ.wav" $RL
# ら行
gen_ssml '<speak>ら<break time="500ms"/>ライオン</speak>'         "$OUT/learn/ら.wav" $RL
gen_ssml '<speak>り<break time="500ms"/>りんご</speak>'           "$OUT/learn/り.wav" $RL
gen_text  "る"                                                     "$OUT/learn/る.wav" 0.75
gen_ssml '<speak>れ<break time="500ms"/>レモン</speak>'           "$OUT/learn/れ.wav" $RL
gen_ssml '<speak>ろ<break time="500ms"/>ロケット</speak>'         "$OUT/learn/ろ.wav" $RL
# わ行
gen_ssml '<speak>わ<break time="500ms"/>わに</speak>'             "$OUT/learn/わ.wav" $RL
gen_text  "を"                                                     "$OUT/learn/を.wav" 0.75
gen_text  "ん"                                                     "$OUT/learn/ん.wav" 0.75

echo ""
count=$(find "$OUT" -name "*.wav" | wc -l | tr -d ' ')
echo "✅ 完了！ ${count} ファイルを生成しました → sounds/"
