#!/bin/bash
# ============================================================
# かずクイズ 音声ファイル一括生成スクリプト (macOS専用)
# 使用音声: Kyoko (macOS 高品質日本語音声)
#
# ■ 事前準備 (Kyoko がなければ)
#   システム設定 → アクセシビリティ → 読み上げ
#   → システム音声 → 管理... → Kyoko をダウンロード
#
# ■ 実行方法
#   chmod +x generate_sounds.sh
#   ./generate_sounds.sh
# ============================================================

VOICE="Kyoko"
RATE_NUM=118      # 数字: ゆっくりはっきり
RATE_PHRASE=142   # フレーズ: ゆっくり
RATE_UI=155       # UI応答: 少し速め
OUT="$(cd "$(dirname "$0")" && pwd)/sounds"

mkdir -p "$OUT/nums"

gen() {
  local text="$1"
  local file="$2"
  local rate="${3:-$RATE_PHRASE}"
  printf "  %-36s → %s\n" "$text" "$(basename "$file")"
  say -v "$VOICE" -r "$rate" "$text" -o /tmp/_kazu_tmp.aiff 2>/dev/null
  afconvert -f WAVE -d LEI16@22050 /tmp/_kazu_tmp.aiff "$file"
  rm -f /tmp/_kazu_tmp.aiff
}

if ! say -v "$VOICE" "" 2>/dev/null; then
  echo "❌ 音声「$VOICE」が見つかりません。"
  echo "   システム設定 → アクセシビリティ → 読み上げ → システム音声 → 管理"
  echo "   で Kyoko をダウンロードしてください。"
  exit 1
fi

num_word() {
  case $1 in
    1) echo "いち" ;; 2) echo "に" ;;   3) echo "さん" ;;
    4) echo "よん" ;; 5) echo "ご" ;;   6) echo "ろく" ;;
    7) echo "なな" ;; 8) echo "はち" ;; 9) echo "きゅう" ;;
    10) echo "じゅう" ;;
  esac
}

echo ""
echo "🎙  音声ファイルを生成しています..."

# ════════════════════════════════
# 数字 1-10
# ════════════════════════════════
echo ""
echo "【数字】"
gen "いち"   "$OUT/nums/1.wav"  $RATE_NUM
gen "に"     "$OUT/nums/2.wav"  $RATE_NUM
gen "さん"   "$OUT/nums/3.wav"  $RATE_NUM
gen "よん"   "$OUT/nums/4.wav"  $RATE_NUM
gen "ご"     "$OUT/nums/5.wav"  $RATE_NUM
gen "ろく"   "$OUT/nums/6.wav"  $RATE_NUM
gen "なな"   "$OUT/nums/7.wav"  $RATE_NUM
gen "はち"   "$OUT/nums/8.wav"  $RATE_NUM
gen "きゅう" "$OUT/nums/9.wav"  $RATE_NUM
gen "じゅう" "$OUT/nums/10.wav" $RATE_NUM

# ════════════════════════════════
# たしざん用フレーズ
# ════════════════════════════════
echo ""
echo "【たしざん用】"
gen "たす"              "$OUT/tasu.wav"    $RATE_PHRASE
gen "は"                "$OUT/wa.wav"      $RATE_NUM
gen "いくつ？"          "$OUT/ikutsu.wav"  $RATE_PHRASE
gen "いくつ　あるかな？" "$OUT/q_count.wav" $RATE_PHRASE

# ════════════════════════════════
# かずならべ用 (18パターン: start 1-6 × blankPos 1-3)
# ════════════════════════════════
echo ""
echo "【かずならべ用 (18パターン)】"
for start in 1 2 3 4 5 6; do
  for blankPos in 1 2 3; do
    phrase=""
    for i in 0 1 2 3 4; do
      n=$((start + i))
      if [ "$i" -eq "$blankPos" ]; then
        phrase="${phrase}なに　"
      else
        phrase="${phrase}$(num_word $n)　"
      fi
    done
    phrase="${phrase}の　なにに　はいるかな？"
    gen "$phrase" "$OUT/seq_${start}_${blankPos}.wav" $RATE_PHRASE
  done
done

# ════════════════════════════════
# UIフレーズ
# ════════════════════════════════
echo ""
echo "【UIフレーズ】"
gen "いくつかな！　はじめよう！"  "$OUT/start_count.wav"    $RATE_UI
gen "たしざん！　はじめよう！"    "$OUT/start_add.wav"      $RATE_UI
gen "かずならべ！　はじめよう！"  "$OUT/start_seq.wav"      $RATE_UI
gen "せいかい！"                  "$OUT/correct.wav"        $RATE_UI
gen "ちがうよ"                    "$OUT/wrong.wav"          $RATE_UI
gen "こたえは"                    "$OUT/answer_prefix.wav"  $RATE_PHRASE

# ════════════════════════════════
# 結果
# ════════════════════════════════
echo ""
echo "【結果】"
gen "ぜんぶ　せいかい！　かんぺき！"  "$OUT/result_score_6.wav" $RATE_PHRASE
gen "5もん　せいかい！"               "$OUT/result_score_5.wav" $RATE_PHRASE
gen "4もん　せいかい！"               "$OUT/result_score_4.wav" $RATE_PHRASE
gen "3もん　せいかい！"               "$OUT/result_score_3.wav" $RATE_PHRASE
gen "2もん　せいかい！"               "$OUT/result_score_2.wav" $RATE_PHRASE
gen "1もん　せいかい！"               "$OUT/result_score_1.wav" $RATE_PHRASE
gen "もう　いっかい　やってみよう！"  "$OUT/result_score_0.wav" $RATE_PHRASE
gen "かんぺき！"      "$OUT/result_title_0.wav" $RATE_UI
gen "すごい！"        "$OUT/result_title_1.wav" $RATE_UI
gen "よくできました！" "$OUT/result_title_2.wav" $RATE_PHRASE
gen "がんばれ！"      "$OUT/result_title_3.wav" $RATE_UI

echo ""
count=$(find "$OUT" -name "*.wav" | wc -l | tr -d ' ')
echo "✅ 完了！ ${count} ファイルを生成しました → sounds/"
