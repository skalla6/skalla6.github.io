#!/bin/bash
# The Trunk auto-setup. Runs by itself on every pod start (from "The Trunk" template).
# Log: /workspace/boot.log
M=/workspace/runpod-slim/ComfyUI; L=/workspace/ml; T=/trunk/models
PY=$M/.venv-cu128/bin/python
# wait until the template has installed and started ComfyUI
until [ -x $PY ] && pgrep -f "main.py" >/dev/null; do sleep 5; done
cp /trunk/rc/*/rclone /usr/local/bin/
# copy models to the fast local disk, then point ComfyUI at them
for d in diffusion_models text_encoders vae loras; do
  mkdir -p $L/$d; cp -n $T/$d/* $L/$d/ 2>/dev/null
  [ -L $M/models/$d ] || { rm -rf $M/models/$d; ln -s $L/$d $M/models/$d; }
done
# save every output to the trunk
mkdir -p /trunk/output
[ -L $M/output ] || { cp -rn $M/output/. /trunk/output/ 2>/dev/null; rm -rf $M/output; ln -s /trunk/output $M/output; }
# photo describer
[ -d $M/custom_nodes/ComfyUI-QwenVL ] || git clone -q https://github.com/1038lab/ComfyUI-QwenVL.git $M/custom_nodes/ComfyUI-QwenVL
$PY -m pip install -q -r $M/custom_nodes/ComfyUI-QwenVL/requirements.txt
# copy outputs to Google Drive every minute
pkill -f "gdrive:TheTrunk"
nohup bash -c 'while true; do rclone --config /trunk/rclone.conf copy -L /trunk/output gdrive:TheTrunk/output; sleep 60; done' >/dev/null 2>&1 &
# restart ComfyUI so it sees everything
pkill -f "main.py"; sleep 5
cd $M && nohup $PY main.py --listen 0.0.0.0 --port 8188 --enable-cors-header $(grep -v '^#' /workspace/runpod-slim/comfyui_args.txt 2>/dev/null) >/workspace/comfy.log 2>&1 &
echo TRUNK READY
