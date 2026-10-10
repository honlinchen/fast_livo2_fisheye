#!/usr/bin/env bash
# 归档/清空 FAST-LIVO2 的 Log 输出
#   ./archive_log.sh [标签]          # 归档到 Log/archive/<标签>/ 并清空(默认)
#   ./archive_log.sh --clean-only    # 只清空,不归档(简写 -c)
#   LOG=路径 ./archive_log.sh ...    # 自定义 Log 目录
set -euo pipefail

LOG="${LOG:-/home/ws_livo/src/FAST-LIVO2/Log}"
CLEAN_ONLY=false
if [ "${1:-}" = "--clean-only" ] || [ "${1:-}" = "-c" ]; then
  CLEAN_ONLY=true
  shift 2>/dev/null || true
fi
TAG="${1:-$(date +%Y%m%d_%H%M%S)}"
DST="$LOG/archive/$TAG"

DIRS="image pcd Colmap result"
FILES="imu.txt mat_out.txt mat_pre.txt"

have_content=false
for d in $DIRS; do
  [ -d "$LOG/$d" ] && find "$LOG/$d" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' 2>/dev/null | grep -q . && have_content=true
done
for f in $FILES; do [ -s "$LOG/$f" ] && have_content=true; done

if ! $have_content; then
  echo "Log 已经是干净的,无需操作。"
  exit 0
fi

if $CLEAN_ONLY; then
  for d in $DIRS; do
    [ -d "$LOG/$d" ] || continue
    find "$LOG/$d" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
  done
  for f in $FILES; do rm -f "$LOG/$f"; done
  echo "已清空 Log(未归档,仅保留 .gitkeep)。"
  exit 0
fi

# ===== 归档 + 清空 =====
mkdir -p "$DST"
for d in $DIRS; do
  [ -d "$LOG/$d" ] || continue
  mkdir -p "$DST/$d"
  find "$LOG/$d" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec mv {} "$DST/$d/" \;
done
for f in $FILES; do [ -s "$LOG/$f" ] && mv "$LOG/$f" "$DST/"; done

echo "已归档到: $DST"
[ -d "$DST/image" ]  && echo "  image:   $(ls "$DST/image" 2>/dev/null | wc -l) 个文件"
[ -d "$DST/pcd" ]    && echo "  pcd:     $(ls "$DST/pcd" 2>/dev/null | wc -l) 个文件"
[ -d "$DST/Colmap" ] && echo "  Colmap:  $(du -sh "$DST/Colmap" | cut -f1)"
[ -d "$DST/result" ] && echo "  result:  $(ls "$DST/result" 2>/dev/null | wc -l) 个文件"
echo "Log 已清空(仅保留 .gitkeep),可以跑下一组数据了。"
