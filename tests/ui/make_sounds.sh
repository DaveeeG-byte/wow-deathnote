#!/usr/bin/env bash
# Rebuilds the alarm sounds in DeathNote/Media/Sounds/ (ffmpeg only, fully synthetic, no third-party material).
# Five levels per sound: <name>_1.ogg (-24 dB) to <name>_5.ogg (0 dB = reference: RMS -17 dB, peak at most -2 dBFS, no clipping).
# Reproducible: fixed formulas, noise via random() with a fixed seed.
# Usage: bash tests/ui/make_sounds.sh [--check]   (--check only measures and creates nothing)
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")/../.." || exit 2
out=DeathNote/Media/Sounds
command -v ffmpeg >/dev/null || { echo "ffmpeg missing"; exit 2; }
RATE=22050
NAMES="glocke gong herzschlag feder sirene"
LEVELS=(-24 -18 -12 -6 0)

# Formulas (t in seconds). Envelopes with exp(), partials inharmonic as with metal.
expr_for() {
  case "$1" in
    glocke)  # deep bell strike: hum tone, prime, minor third, fifth, octave, nasard; hard attack
      echo "dur=1.40;e='0.30*sin(2*PI*98*t)*exp(-2.2*t)+0.55*sin(2*PI*196*t)*exp(-3.0*t)+0.30*sin(2*PI*233.5*t)*exp(-3.6*t)+0.22*sin(2*PI*294.7*t)*exp(-4.5*t)+0.18*sin(2*PI*392.8*t)*exp(-5.5*t)+0.12*sin(2*PI*494*t)*exp(-7*t)+0.10*sin(2*PI*1180*t)*exp(-30*t)'" ;;
    gong)    # gong: soft onset, beating partials, long decay
      echo "dur=1.50;e='(1-exp(-40*t))*(0.50*sin(2*PI*82*t)*exp(-1.6*t)+0.35*sin(2*PI*83.4*t)*exp(-1.8*t)+0.30*sin(2*PI*171*t+0.6*sin(2*PI*3*t))*exp(-2.4*t)+0.18*sin(2*PI*264*t)*exp(-3.2*t)+0.12*sin(2*PI*389*t)*exp(-4.5*t))'" ;;
    herzschlag) # heartbeat: two dull beats (lub-dub), falling pitch, a little overtone for small speakers
      echo "dur=0.85;e='if(lt(t,0.30),1,0)*(0.9*sin(2*PI*(58*t+40*(1-exp(-25*t))/25*1))*exp(-14*t)+0.35*sin(2*PI*116*t)*exp(-22*t))+if(gte(t,0.30),1,0)*(0.75*sin(2*PI*(52*(t-0.30)+40*(1-exp(-25*(t-0.30)))/25))*exp(-12*(t-0.30))+0.30*sin(2*PI*104*(t-0.30))*exp(-20*(t-0.30)))'" ;;
    feder)   # quill: short scratch, noise, trembling, two strokes
      echo "dur=0.50;e='(random(0)*2-1)*(0.5+0.5*sin(2*PI*37*t))*(if(lt(t,0.22),sin(PI*t/0.22),0)+0.7*if(between(t,0.26,0.46),sin(PI*(t-0.26)/0.20),0))'" ;;
    sirene)  # siren: short rising and falling tone, fundamental plus overtone
      # frequency 440 + 360*sin(pi*t): up and back down in 1 s; phase = its integral
      echo "dur=1.05;e='(1-exp(-30*t))*(0.8*sin(2*PI*(440*t+360*(1-cos(PI*t))/PI))+0.25*sin(4*PI*(440*t+360*(1-cos(PI*t))/PI)))'" ;;
  esac
}

peak_db() {   # peak level in dBFS
  ffmpeg -hide_banner -nostats -i "$1" -af astats=metadata=0:measure_overall=Peak_level,volumedetect -f null - 2>&1 \
    | sed -n 's/.*max_volume: \(-\?[0-9.]*\) dB.*/\1/p' | tail -1
}
rms_db() {
  ffmpeg -hide_banner -nostats -i "$1" -af volumedetect -f null - 2>&1 | sed -n 's/.*mean_volume: \(-\?[0-9.]*\) dB.*/\1/p' | tail -1
}

if [ "${1:-}" != "--check" ]; then
  mkdir -p "$out"
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  for n in $NAMES; do
    eval "$(expr_for "$n")"
    filt=""
    case "$n" in
      feder) filt=",highpass=f=2500,lowpass=f=7000" ;;
      herzschlag) filt=",lowpass=f=900" ;;
    esac
    ffmpeg -hide_banner -loglevel error -y -f lavfi -i "aevalsrc=exprs='$e':s=$RATE:d=$dur" \
      -af "volume=0.4,afade=t=out:st=$(awk -v d="$dur" 'BEGIN{print d-0.05}'):d=0.05$filt" -ac 1 -c:a pcm_f32le "$tmp/$n.wav"
    p=$(peak_db "$tmp/$n.wav")
    r=$(rms_db "$tmp/$n.wav")
    # sound equally loud (RMS -17 dB), but never peak above -2 dBFS
    gain=$(awk -v p="$p" -v r="$r" 'BEGIN{a=-2-p; b=-17-r; print (a<b)?a:b}')          # peak at -2 dBFS (headroom for the Vorbis overshoot)
    for i in 1 2 3 4 5; do
      g=$(awk -v a="$gain" -v b="${LEVELS[$((i-1))]}" 'BEGIN{print a+b}')
      ffmpeg -hide_banner -loglevel error -y -i "$tmp/$n.wav" -af "volume=${g}dB" -ac 1 -ar $RATE \
        -c:a libvorbis -q:a 3 -map_metadata -1 -fflags +bitexact -flags:a +bitexact "$out/${n}_$i.ogg"
    done
  done
fi

# Measurement: format, duration, peak and RMS per level (must rise strictly), total size
status=0
for n in $NAMES; do
  lastp=-999; lastr=-999; line="$n:"
  for i in 1 2 3 4 5; do
    f="$out/${n}_$i.ogg"
    [ -f "$f" ] || { echo "MISSING $f"; status=1; continue; }
    fmt=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels -of csv=p=0 "$f")
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
    p=$(peak_db "$f"); r=$(rms_db "$f")
    [ "$fmt" = "vorbis,1" ] || { echo "FORMAT $f: $fmt"; status=1; }
    awk -v d="$dur" 'BEGIN{exit !(d>=0.4 && d<=1.5)}' || { echo "DURATION $f: $dur"; status=1; }
    awk -v a="$p" -v b="$lastp" -v c="$r" -v e="$lastr" 'BEGIN{exit !(a>b && c>e && a<-0.1)}' || { echo "LEVEL $f: peak $p rms $r"; status=1; }
    lastp=$p; lastr=$r
    line="$line  $i: ${p}/${r} dB"
  done
  printf '%s  (%.2f s)\n' "$line" "$dur"
done
echo "Total: $(ls "$out"/*.ogg | wc -l) files, $(du -cb "$out"/*.ogg | tail -1 | cut -f1) bytes"
exit $status
