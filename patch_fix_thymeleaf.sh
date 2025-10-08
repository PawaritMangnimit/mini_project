#!/usr/bin/env bash
set -euo pipefail

echo ">>> Patching Thymeleaf templates (replace 'layout :: content' with '~{layout :: content}')"

# ไปที่โฟลเดอร์ template
cd src/main/resources/templates

# ใช้ sed แก้ไขทุกไฟล์ html
for f in *.html; do
  echo " - Patching $f"
  sed -i 's/layout :: content/~{layout :: content}/g' "$f"
done

echo ">>> Patch complete!"
