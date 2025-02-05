#!/bin/bash
# upload_youtube_hls.sh
# Usage: ./upload_youtube_hls.sh <youtube_url> <video_name> <caption>

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <youtube_url> <video_name> <caption>"
    exit 1
fi

YOUTUBE_URL="$1"
VIDEO_NAME="$2"
CAPTION="$3"

# Define your Firebase Storage bucket.
FIREBASE_BUCKET="gs://finshield-d895d.firebasestorage.app"
DESTINATION="${FIREBASE_BUCKET}/videos/${VIDEO_NAME}/"

echo "[$(date)] Starting process."
echo "[$(date)] YouTube URL: $YOUTUBE_URL"
echo "[$(date)] Video name: $VIDEO_NAME"
echo "[$(date)] Caption: $CAPTION"

# Step 1: Download the video as MP4.
OUTPUT_VIDEO="video.mp4"
echo "[$(date)] Downloading video from: $YOUTUBE_URL"
yt-dlp -f bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4 "$YOUTUBE_URL" -o "$OUTPUT_VIDEO"
echo "[$(date)] Video downloaded to: $OUTPUT_VIDEO"

# Step 2: Convert the MP4 to an adaptive HLS package with five renditions (1080, 720, 480, 240, 144).
OUTPUT_DIR="hls_output"
MASTER_PLAYLIST="master.m3u8"
echo "[$(date)] Converting $OUTPUT_VIDEO to adaptive HLS format with multiple renditions..."
mkdir -p "$OUTPUT_DIR"
ffmpeg -i "$OUTPUT_VIDEO" -filter_complex "\
  [0:v]split=5[v1080][v720][v480][v240][v144]; \
  [v1080]scale=w=1920:h=1080:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[v1080out]; \
  [v720]scale=w=1280:h=720:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[v720out]; \
  [v480]scale=w=854:h=480:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[v480out]; \
  [v240]scale=w=426:h=240:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[v240out]; \
  [v144]scale=w=256:h=144:force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2[v144out]" \
  -map "[v1080out]" -c:v:0 libx264 -b:v:0 5000k -maxrate:v:0 5350k -bufsize:v:0 7500k \
  -map "[v720out]" -c:v:1 libx264 -b:v:1 2800k -maxrate:v:1 2996k -bufsize:v:1 4200k \
  -map "[v480out]" -c:v:2 libx264 -b:v:2 1400k -maxrate:v:2 1498k -bufsize:v:2 2100k \
  -map "[v240out]" -c:v:3 libx264 -b:v:3 700k -maxrate:v:3 749k -bufsize:v:3 1050k \
  -map "[v144out]" -c:v:4 libx264 -b:v:4 400k -maxrate:v:4 428k -bufsize:v:4 600k \
  -map a:0 -c:a:0 aac -b:a:0 128k \
  -map a:0 -c:a:1 aac -b:a:1 128k \
  -map a:0 -c:a:2 aac -b:a:2 128k \
  -map a:0 -c:a:3 aac -b:a:3 128k \
  -map a:0 -c:a:4 aac -b:a:4 128k \
  -f hls \
  -hls_time 10 \
  -hls_list_size 0 \
  -hls_flags independent_segments \
  -hls_segment_filename "$OUTPUT_DIR/stream_%v/segment_%d.ts" \
  -master_pl_name $MASTER_PLAYLIST \
  -var_stream_map "v:0,a:0 v:1,a:1 v:2,a:2 v:3,a:3 v:4,a:4" \
  "$OUTPUT_DIR/stream_%v.m3u8"
echo "[$(date)] Adaptive HLS conversion complete. Master manifest at: $OUTPUT_DIR/$MASTER_PLAYLIST"

# Step 2.5: Fix the manifest file so each TS (or variant playlist) line includes the full URL.
echo "[$(date)] Fixing manifest file to include full TS URLs..."
TMP_PY_SCRIPT=$(mktemp /tmp/fix_manifest.XXXX.py)
cat > "$TMP_PY_SCRIPT" <<'EOF'
import sys, urllib.parse
if len(sys.argv) < 3:
    sys.exit("Usage: fix_manifest.py <video_name> <manifest_file>")
video_name = sys.argv[1]
manifest_file = sys.argv[2]
# Base URL for Firebase Storage objects
base_url = "https://firebasestorage.googleapis.com/v0/b/finshield-d895d.firebasestorage.app/o/"
# Folder path where the video files are uploaded (needs URL encoding)
folder_path = f"videos/{video_name}/"
encoded_folder = urllib.parse.quote(folder_path)
with open(manifest_file, "r") as f:
    lines = f.readlines()
new_lines = []
for line in lines:
    stripped = line.strip()
    if stripped.endswith(".ts") or stripped.endswith(".m3u8"):
        full_url = f"{base_url}{encoded_folder}{stripped}?alt=media"
        new_lines.append(full_url + "\n")
    else:
        new_lines.append(line)
with open(manifest_file, "w") as f:
    f.writelines(new_lines)
EOF
python3 "$TMP_PY_SCRIPT" "$VIDEO_NAME" "$OUTPUT_DIR/$MASTER_PLAYLIST"
rm "$TMP_PY_SCRIPT"
echo "[$(date)] Manifest file updated."
echo "----- Manifest file content -----"
cat "$OUTPUT_DIR/$MASTER_PLAYLIST"
echo "-----------------------------------"

# Step 3: Upload the HLS package (manifest and TS segments) to Firebase Storage.
echo "[$(date)] Uploading files from $OUTPUT_DIR to $DESTINATION ..."
gsutil -m cp -r "$OUTPUT_DIR"/* "$DESTINATION"
echo "[$(date)] Upload complete."

# Step 4: Construct the public URL for the master manifest.
ENCODED_PATH=$(python3 -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))' "videos/${VIDEO_NAME}/${MASTER_PLAYLIST}")
echo "[$(date)] Encoded path: $ENCODED_PATH"
PUBLIC_URL="https://firebasestorage.googleapis.com/v0/b/finshield-d895d.firebasestorage.app/o/${ENCODED_PATH}?alt=media"
echo "[$(date)] Constructed public URL: $PUBLIC_URL"

# Step 5: Add a document to Firestore via the REST API.
PROJECT_ID="finshield-d895d"
FIRESTORE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/videos"
ACCESS_TOKEN=$(gcloud auth print-access-token)
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%SZ")
JSON_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "videoName": { "stringValue": "${VIDEO_NAME}" },
    "videoURL": { "stringValue": "${PUBLIC_URL}" },
    "caption": { "stringValue": "${CAPTION}" },
    "timestamp": { "timestampValue": "${TIMESTAMP}" }
  }
}
EOF
)
echo "[$(date)] Adding document to Firestore..."
curl -X POST "${FIRESTORE_URL}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${JSON_PAYLOAD}"
echo "[$(date)] Document added to Firestore."

echo "[$(date)] Process finished successfully."