#!/bin/bash
# The Trunk pod startup: fast local models, outputs saved to trunk, auto-sync to Google Drive.
M=/workspace/runpod-slim/ComfyUI; L=/workspace/ml; T=/trunk/models
cp /trunk/rc/*/rclone /usr/local/bin/
for d in diffusion_models text_encoders vae loras; do
  mkdir -p $L/$d; cp -n $T/$d/* $L/$d/ 2>/dev/null
  rm -rf $M/models/$d; ln -s $L/$d $M/models/$d
done
rm -rf $M/output; mkdir -p /trunk/output; ln -s /trunk/output $M/output
pkill -f "gdrive:TheTrunk"; sleep 1
nohup bash -c 'while true; do rclone --config /trunk/rclone.conf copy /trunk/output gdrive:TheTrunk/output; sleep 60; done' >/dev/null 2>&1 &
echo TRUNK READY
