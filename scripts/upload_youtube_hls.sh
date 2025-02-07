#!/bin/bash
# upload_youtube_hls.sh
# Usage: ./upload_youtube_hls.sh <youtube_url> <video_name>
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <youtube_url> <video_name>"
    exit 1
fi

PROJECT_ID="finshield-d895d" # Set your Firebase project ID here
FIREBASE_BUCKET="gs://${PROJECT_ID}.firebasestorage.app"

# Command-line arguments.
YOUTUBE_URL="$1"
VIDEO_NAME="$2" # Internal video name for storage

echo "[$(date)] Starting process."
echo "[$(date)] YouTube URL: $YOUTUBE_URL"
echo "[$(date)] Video name (internal): $VIDEO_NAME"

# Step 0: Extract metadata from YouTube.
echo "[$(date)] Extracting metadata from YouTube..."
TMP_METADATA=$(mktemp /tmp/metadata.XXXX.json)
yt-dlp --no-warnings --skip-download --dump-json "$YOUTUBE_URL" > "$TMP_METADATA"
echo "[$(date)] Metadata dumped to $TMP_METADATA"

VIDEO_TITLE=$(jq -r '.title' "$TMP_METADATA")
VIDEO_CAPTION=$(jq -r '.description' "$TMP_METADATA")
VIDEO_USERNAME=$(jq -r '.uploader' "$TMP_METADATA")
PROFILE_PICTURE=$(jq -r '.uploader_thumbnail // empty' "$TMP_METADATA")

# Extract timestamp (fallback to current date/time if missing)
YT_TIMESTAMP=$(jq -r '.timestamp' "$TMP_METADATA")
if [ "$YT_TIMESTAMP" == "null" ] || [ -z "$YT_TIMESTAMP" ]; then
    VIDEO_TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%SZ")
else
    if [ "$(uname)" == "Darwin" ]; then
        VIDEO_TIMESTAMP=$(date -u -r "$YT_TIMESTAMP" +"%Y-%m-%dT%H:%M:%SZ")
    else
        VIDEO_TIMESTAMP=$(date -u -d @"$YT_TIMESTAMP" +"%Y-%m-%dT%H:%M:%SZ")
    fi
fi

echo "[$(date)] Extracted Title: $VIDEO_TITLE"
echo "[$(date)] Extracted Caption: $VIDEO_CAPTION"
echo "[$(date)] Extracted Username: $VIDEO_USERNAME"
echo "[$(date)] Extracted Timestamp: $VIDEO_TIMESTAMP"

# Step 1: Download the video as MP4.
OUTPUT_VIDEO="video.mp4"
echo "[$(date)] Downloading video from: $YOUTUBE_URL"
yt-dlp -f bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4 "$YOUTUBE_URL" -o "$OUTPUT_VIDEO"
echo "[$(date)] Video downloaded to: $OUTPUT_VIDEO"

# Step 2: Convert MP4 to adaptive HLS with multiple renditions.
OUTPUT_DIR="hls_output"
MASTER_PLAYLIST="master.m3u8"
echo "[$(date)] Converting $OUTPUT_VIDEO to adaptive HLS..."
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

# Step 2.5: Fix manifest URLs via a Python helper script.
TMP_PY_SCRIPT=$(mktemp /tmp/fix_manifest.XXXX.py)
cat > "$TMP_PY_SCRIPT" <<'EOF'
import sys, urllib.parse, os
if len(sys.argv) < 3:
    sys.exit("Usage: fix_manifest.py <video_name> <manifest_file> [segment_prefix]")
video_name = sys.argv[1]
manifest_file = sys.argv[2]
segment_prefix = sys.argv[3] if len(sys.argv) >= 4 else ""
if segment_prefix and not segment_prefix.endswith("/"):
    segment_prefix += "/"
base_url = "https://firebasestorage.googleapis.com/v0/b/finshield-d895d.firebasestorage.app/o/"
basename = os.path.basename(manifest_file)
if basename == "master.m3u8":
    folder_path = f"videos/{video_name}/"
else:
    folder_path = f"videos/{video_name}/{segment_prefix}"
encoded_folder = urllib.parse.quote(folder_path, safe="")
with open(manifest_file, "r") as f:
    lines = f.readlines()
new_lines = []
for line in lines:
    stripped = line.strip()
    if not stripped.startswith("#") and (stripped.endswith(".ts") or stripped.endswith(".m3u8")):
        file_part = urllib.parse.quote(stripped, safe="")
        full_url = f"{base_url}{encoded_folder}{file_part}?alt=media"
        new_lines.append(full_url + "\n")
    else:
        new_lines.append(line)
with open(manifest_file, "w") as f:
    f.writelines(new_lines)
EOF

echo "[$(date)] Fixing master manifest..."
python3 "$TMP_PY_SCRIPT" "$VIDEO_NAME" "$OUTPUT_DIR/$MASTER_PLAYLIST"
for v in {0..4}; do
    VARIANT_MANIFEST="$OUTPUT_DIR/stream_${v}.m3u8"
    echo "[$(date)] Fixing variant manifest $VARIANT_MANIFEST..."
    python3 "$TMP_PY_SCRIPT" "$VIDEO_NAME" "$VARIANT_MANIFEST" "stream_${v}"
done
rm "$TMP_PY_SCRIPT"
echo "[$(date)] Manifest files updated."

# Step 3: Upload the HLS package to Firebase Storage.
DESTINATION="${FIREBASE_BUCKET}/videos/${VIDEO_NAME}/"
echo "[$(date)] Uploading files from $OUTPUT_DIR to $DESTINATION ..."
gsutil -m cp -r "$OUTPUT_DIR"/* "$DESTINATION"
echo "[$(date)] Upload complete."

# Step 4: Construct public URL for the master manifest.
ENCODED_PATH=$(python3 -c 'import urllib.parse, sys; print(urllib.parse.quote("videos/'"${VIDEO_NAME}"'/master.m3u8", safe=""))')
PUBLIC_URL="https://firebasestorage.googleapis.com/v0/b/finshield-d895d.firebasestorage.app/o/${ENCODED_PATH}?alt=media"
echo "[$(date)] Constructed public URL: $PUBLIC_URL"

# Step 5: Generate random engagement metrics.
LIKES=$(( RANDOM % 100000 + 100 ))
BOOKMARKS=$(( RANDOM % 10000 + 10 ))
SHARES=$(( RANDOM % 1000 + 1 ))

# Create Firestore document with additional engagement fields.
FIRESTORE_URL="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/videos"
ACCESS_TOKEN=$(gcloud auth print-access-token)
JSON_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "videoName": { "stringValue": "${VIDEO_NAME}" },
    "videoTitle": { "stringValue": "${VIDEO_TITLE}" },
    "videoURL": { "stringValue": "${PUBLIC_URL}" },
    "caption": { "stringValue": "${VIDEO_CAPTION}" },
    "username": { "stringValue": "${VIDEO_USERNAME}" },
    "timestamp": { "timestampValue": "${VIDEO_TIMESTAMP}" },
    "profilePicture": { "stringValue": "${PROFILE_PICTURE}" },
    "numLikes": { "integerValue": "${LIKES}" },
    "numBookmarks": { "integerValue": "${BOOKMARKS}" },
    "numShares": { "integerValue": "${SHARES}" }
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

# Cleanup temporary files.
rm -rf hls_output/
rm "$OUTPUT_VIDEO"
rm "$TMP_METADATA"
