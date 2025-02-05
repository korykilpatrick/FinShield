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

# Step 2: Convert the MP4 to an HLS package.
OUTPUT_DIR="hls_output"
OUTPUT_PLAYLIST="output.m3u8"
echo "[$(date)] Converting $OUTPUT_VIDEO to HLS format..."
mkdir -p "$OUTPUT_DIR"
ffmpeg -i "$OUTPUT_VIDEO" -codec: copy -start_number 0 -hls_time 10 -hls_list_size 0 -f hls "$OUTPUT_DIR/$OUTPUT_PLAYLIST"
echo "[$(date)] HLS conversion complete. Manifest at: $OUTPUT_DIR/$OUTPUT_PLAYLIST"

# Step 2.5: Fix the manifest file so each TS reference is a full URL.
echo "[$(date)] Fixing manifest file to include full TS URLs..."
TMP_PY_SCRIPT=$(mktemp /tmp/fix_manifest.XXXX.py)
cat > "$TMP_PY_SCRIPT" <<'EOF'
import sys, urllib.parse
if len(sys.argv) < 3:
    sys.exit("Usage: fix_manifest.py <video_name> <manifest_file>")
video_name = sys.argv[1]
manifest_file = sys.argv[2]
base_url = "https://firebasestorage.googleapis.com/v0/b/finshield-d895d.firebasestorage.app/o/"
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
python3 "$TMP_PY_SCRIPT" "$VIDEO_NAME" "$OUTPUT_DIR/$OUTPUT_PLAYLIST"
rm "$TMP_PY_SCRIPT"
echo "[$(date)] Manifest file updated."

# Step 3: Upload the HLS package (manifest and TS segments) to Firebase Storage.
echo "[$(date)] Uploading files from $OUTPUT_DIR to $DESTINATION ..."
gsutil -m cp -r "$OUTPUT_DIR"/* "$DESTINATION"
echo "[$(date)] Upload complete."

# Step 4: Construct the public URL for the manifest.
ENCODED_PATH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('videos/${VIDEO_NAME}/output.m3u8'))")
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
