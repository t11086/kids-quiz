#!/bin/bash
# ============================================================
# ゲーム用 音声ファイル一括生成スクリプト (macOS専用)
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
RATE_WORD=148     # 単語: ゆっくり・はっきり
RATE_PHRASE=145   # フレーズ: ゆっくり
OUT="$(cd "$(dirname "$0")" && pwd)/sounds"

mkdir -p "$OUT/words" "$OUT/chars"

# ── AIFF → WAV 変換ヘルパー ──
gen() {
  local text="$1"
  local file="$2"
  local rate="${3:-$RATE_WORD}"
  printf "  %-24s → %s\n" "$text" "$(basename "$file")"
  say -v "$VOICE" -r "$rate" "$text" -o /tmp/_moji_tmp.aiff 2>/dev/null
  afconvert -f WAVE -d LEI16@22050 /tmp/_moji_tmp.aiff "$file"
  rm -f /tmp/_moji_tmp.aiff
}

# ── Kyoko が利用可能か確認 ──
if ! say -v "$VOICE" "" 2>/dev/null; then
  echo "❌ 音声「$VOICE」が見つかりません。"
  echo "   システム設定 → アクセシビリティ → 読み上げ → システム音声 → 管理"
  echo "   で Kyoko をダウンロードしてください。"
  exit 1
fi

echo ""
echo "🎙  音声ファイルを生成しています..."
echo ""

# ════════════════════════════════════
# 単語 (43語)
# ════════════════════════════════════
echo "【単語】"
gen "あり"         "$OUT/words/あり.wav"
gen "いぬ"         "$OUT/words/いぬ.wav"
gen "うさぎ"       "$OUT/words/うさぎ.wav"
gen "えんぴつ"     "$OUT/words/えんぴつ.wav"
gen "おにぎり"     "$OUT/words/おにぎり.wav"
gen "かさ"         "$OUT/words/かさ.wav"
gen "きつね"       "$OUT/words/きつね.wav"
gen "くつ"         "$OUT/words/くつ.wav"
gen "けーき"       "$OUT/words/けーき.wav"
gen "こあら"       "$OUT/words/こあら.wav"
gen "さかな"       "$OUT/words/さかな.wav"
gen "しんかんせん" "$OUT/words/しんかんせん.wav"
gen "すいか"       "$OUT/words/すいか.wav"
gen "せっけん"     "$OUT/words/せっけん.wav"
gen "そら"         "$OUT/words/そら.wav"
gen "たこ"         "$OUT/words/たこ.wav"
gen "ちょうちょ"   "$OUT/words/ちょうちょ.wav"
gen "つき"         "$OUT/words/つき.wav"
gen "てんとうむし" "$OUT/words/てんとうむし.wav"
gen "とり"         "$OUT/words/とり.wav"
gen "なす"         "$OUT/words/なす.wav"
gen "にじ"         "$OUT/words/にじ.wav"
gen "ぬいぐるみ"   "$OUT/words/ぬいぐるみ.wav"
gen "ねこ"         "$OUT/words/ねこ.wav"
gen "のりもの"     "$OUT/words/のりもの.wav"
gen "はな"         "$OUT/words/はな.wav"
gen "ひこうき"     "$OUT/words/ひこうき.wav"
gen "ふね"         "$OUT/words/ふね.wav"
gen "へび"         "$OUT/words/へび.wav"
gen "ほし"         "$OUT/words/ほし.wav"
gen "まる"         "$OUT/words/まる.wav"
gen "みかん"       "$OUT/words/みかん.wav"
gen "むし"         "$OUT/words/むし.wav"
gen "めがね"       "$OUT/words/めがね.wav"
gen "もも"         "$OUT/words/もも.wav"
gen "やま"         "$OUT/words/やま.wav"
gen "ゆき"         "$OUT/words/ゆき.wav"
gen "よる"         "$OUT/words/よる.wav"
gen "らいおん"     "$OUT/words/らいおん.wav"
gen "りんご"       "$OUT/words/りんご.wav"
gen "れもん"       "$OUT/words/れもん.wav"
gen "ろけっと"     "$OUT/words/ろけっと.wav"
gen "わに"         "$OUT/words/わに.wav"

# ════════════════════════════════════
# UIフレーズ
# ════════════════════════════════════
echo ""
echo "【フレーズ】"
gen "はじめのもじは　どれかな"  "$OUT/q_hint.wav"      $RATE_PHRASE
gen "ひらがな！　はじめよう"    "$OUT/start_hira.wav"  $RATE_PHRASE
gen "カタカナ！　はじめよう"    "$OUT/start_kata.wav"  $RATE_PHRASE
gen "すごい"                    "$OUT/praise_0.wav"    155
gen "やったー"                  "$OUT/praise_1.wav"    155
gen "えらい"                    "$OUT/praise_2.wav"    155
gen "かしこい"                  "$OUT/praise_3.wav"    155
gen "ばっちり"                  "$OUT/praise_4.wav"    155
gen "さいこう"                  "$OUT/praise_5.wav"    155
gen "よくできた"                "$OUT/praise_6.wav"    155
gen "ぴんぽーん"                "$OUT/praise_7.wav"    155
gen "せいかい"                  "$OUT/correct.wav"     148
gen "ちがうよ"                  "$OUT/wrong.wav"       148
gen "こたえは"                  "$OUT/answer_prefix.wav" 140

# ── 正解文字 (ひらがな全文字) ──
echo ""
echo "【ひらがな文字】"
for char in あ い う え お か き く け こ さ し す せ そ た ち つ て と な に ぬ ね の は ひ ふ へ ほ ま み む め も や ゆ よ ら り る れ ろ わ を ん; do
  gen "$char" "$OUT/chars/${char}.wav" 120
done

echo ""
count=$(find "$OUT" -name "*.wav" | wc -l | tr -d ' ')
echo "✅ 完了！ ${count} ファイルを生成しました → sounds/"
