#!/bin/bash
# ============================================================
# かずクイズ Google Cloud TTS (Neural2) 音声ファイル生成スクリプト
#
# 事前準備:
#   1. https://console.cloud.google.com/ でプロジェクト作成
#   2. Cloud Text-to-Speech API を有効化
#   3. APIキーを作成し、下記 GCLOUD_API_KEY に設定
#      または: export GCLOUD_API_KEY="YOUR_KEY"
# ============================================================

API_KEY="${GCLOUD_API_KEY:-}"
if [ -z "$API_KEY" ]; then
  echo "❌ APIキーが設定されていません。"
  echo "   export GCLOUD_API_KEY=\"YOUR_API_KEY\" を実行してから再試行してください。"
  exit 1
fi

VOICE_NAME="ja-JP-Neural2-B"
LANG="ja-JP"
RATE_NUM=0.78
RATE_PHRASE=0.80
RATE_UI=0.90
PITCH=2.0
OUT="$(cd "$(dirname "$0")" && pwd)/sounds"
API_URL="https://texttospeech.googleapis.com/v1/text:synthesize"

mkdir -p "$OUT/nums"

gen_text() {
  local text="$1" file="$2" rate="${3:-$RATE_PHRASE}"
  printf "  %-36s → %s\n" "$text" "$(basename "$file")"
  local body
  body=$(cat <<EOF
{
  "input": { "text": "$text" },
  "voice": { "languageCode": "$LANG", "name": "$VOICE_NAME" },
  "audioConfig": { "audioEncoding": "LINEAR16", "sampleRateHertz": 22050, "speakingRate": $rate, "pitch": $PITCH }
}
EOF
)
  local audio
  audio=$(curl -s -X POST -H "Content-Type: application/json" -H "X-Goog-Api-Key: $API_KEY" \
    --data "$body" "$API_URL" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('audioContent',''))" 2>/dev/null)
  if [ -z "$audio" ]; then echo "    ⚠️  失敗: $text"; return 1; fi
  echo "$audio" | base64 --decode > "$file"
}

gen_ssml() {
  local ssml="$1" file="$2" rate="${3:-$RATE_PHRASE}"
  printf "  %-36s → %s\n" "(ssml)" "$(basename "$file")"
  local escaped
  escaped=$(echo "$ssml" | sed 's/"/\\"/g')
  local body
  body=$(cat <<EOF
{
  "input": { "ssml": "$escaped" },
  "voice": { "languageCode": "$LANG", "name": "$VOICE_NAME" },
  "audioConfig": { "audioEncoding": "LINEAR16", "sampleRateHertz": 22050, "speakingRate": $rate, "pitch": $PITCH }
}
EOF
)
  local audio
  audio=$(curl -s -X POST -H "Content-Type: application/json" -H "X-Goog-Api-Key: $API_KEY" \
    --data "$body" "$API_URL" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('audioContent',''))" 2>/dev/null)
  if [ -z "$audio" ]; then echo "    ⚠️  失敗"; return 1; fi
  echo "$audio" | base64 --decode > "$file"
}

num_word() {
  case $1 in
    1) echo "いち" ;; 2) echo "に" ;;   3) echo "さん" ;;
    4) echo "よん" ;; 5) echo "ご" ;;   6) echo "ろく" ;;
    7) echo "なな" ;; 8) echo "はち" ;; 9) echo "きゅう" ;;
    10) echo "じゅう" ;;
  esac
}

echo ""
echo "🎙  Google Cloud TTS (Neural2) で音声を生成しています..."

# ════════════════════════════════
# 数字 1-10
# ════════════════════════════════
echo ""
echo "【数字】"
gen_text "いち"   "$OUT/nums/1.wav"  $RATE_NUM
gen_text "に"     "$OUT/nums/2.wav"  $RATE_NUM
gen_text "さん"   "$OUT/nums/3.wav"  $RATE_NUM
gen_text "よん"   "$OUT/nums/4.wav"  $RATE_NUM
gen_text "ご"     "$OUT/nums/5.wav"  $RATE_NUM
gen_text "ろく"   "$OUT/nums/6.wav"  $RATE_NUM
gen_text "なな"   "$OUT/nums/7.wav"  $RATE_NUM
gen_text "はち"   "$OUT/nums/8.wav"  $RATE_NUM
gen_text "きゅう" "$OUT/nums/9.wav"  $RATE_NUM
gen_text "じゅう" "$OUT/nums/10.wav" $RATE_NUM

# ════════════════════════════════
# たしざん用フレーズ
# ════════════════════════════════
echo ""
echo "【たしざん用】"
gen_text "たす"              "$OUT/tasu.wav"    $RATE_NUM
gen_text "は"                "$OUT/wa.wav"      $RATE_NUM
gen_text "いくつ？"          "$OUT/ikutsu.wav"  $RATE_PHRASE
gen_text "いくつ　あるかな？" "$OUT/q_count.wav" $RATE_PHRASE

# ════════════════════════════════
# かずならべ用 (18パターン: SSML でポーズ制御)
# ════════════════════════════════
echo ""
echo "【かずならべ用 (18パターン)】"
for start in 1 2 3 4 5 6; do
  for blankPos in 1 2 3; do
    ssml="<speak>"
    for i in 0 1 2 3 4; do
      n=$((start + i))
      if [ "$i" -eq "$blankPos" ]; then
        ssml="${ssml}なに<break time=\"180ms\"/>"
      else
        ssml="${ssml}$(num_word $n)<break time=\"180ms\"/>"
      fi
    done
    ssml="${ssml}<break time=\"300ms\"/>の　なにに　はいるかな？</speak>"
    gen_ssml "$ssml" "$OUT/seq_${start}_${blankPos}.wav" $RATE_PHRASE
  done
done

# ════════════════════════════════
# UIフレーズ
# ════════════════════════════════
echo ""
echo "【UIフレーズ】"
gen_ssml "<speak>いくつかな！<break time=\"200ms\"/>はじめよう！</speak>" "$OUT/start_count.wav"   $RATE_UI
gen_ssml "<speak>たしざん！<break time=\"200ms\"/>はじめよう！</speak>"   "$OUT/start_add.wav"     $RATE_UI
gen_ssml "<speak>かずならべ！<break time=\"200ms\"/>はじめよう！</speak>" "$OUT/start_seq.wav"     $RATE_UI
gen_text "せいかい！"   "$OUT/correct.wav"       $RATE_UI
gen_text "ちがうよ"     "$OUT/wrong.wav"          $RATE_UI
gen_text "こたえは"     "$OUT/answer_prefix.wav"  $RATE_PHRASE

# ════════════════════════════════
# 結果
# ════════════════════════════════
echo ""
echo "【結果】"
gen_text "ぜんぶ　せいかい！　かんぺき！"  "$OUT/result_score_6.wav" $RATE_PHRASE
gen_text "5もん　せいかい！"               "$OUT/result_score_5.wav" $RATE_PHRASE
gen_text "4もん　せいかい！"               "$OUT/result_score_4.wav" $RATE_PHRASE
gen_text "3もん　せいかい！"               "$OUT/result_score_3.wav" $RATE_PHRASE
gen_text "2もん　せいかい！"               "$OUT/result_score_2.wav" $RATE_PHRASE
gen_text "1もん　せいかい！"               "$OUT/result_score_1.wav" $RATE_PHRASE
gen_text "もう　いっかい　やってみよう！"  "$OUT/result_score_0.wav" $RATE_PHRASE
gen_text "かんぺき！"       "$OUT/result_title_0.wav" $RATE_UI
gen_text "すごい！"         "$OUT/result_title_1.wav" $RATE_UI
gen_text "よくできました！" "$OUT/result_title_2.wav" $RATE_PHRASE
gen_text "がんばれ！"       "$OUT/result_title_3.wav" $RATE_UI

echo ""
count=$(find "$OUT" -name "*.wav" | wc -l | tr -d ' ')
echo "✅ 完了！ ${count} ファイルを生成しました → sounds/"
