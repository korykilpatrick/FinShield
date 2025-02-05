#!/bin/bash
# upload_youtube_hls.sh (Modified)
# Usage: ./upload_youtube_hls.sh <youtube_url> <video_name> <caption>
# This script downloads a YouTube video as an MP4 named after the video name,
# uploads it to the root of the Firebase Storage bucket with a download token,
# and creates a corresponding document in the Firestore "videos" collection.

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <youtube_url> <video_name> <caption>"
    exit 1
fi

YOUTUBE_URL="$1"
VIDEO_NAME="$2"
CAPTION="$3"

# Define the Firebase Storage bucket.
FIREBASE_BUCKET="gs://finshield-d895d.firebasestorage.app"
DESTINATION="${FIREBASE_BUCKET}/${VIDEO_NAME}.mp4"

echo "[$(date)] Starting process."
echo "[$(date)] YouTube URL: $YOUTUBE_URL"
echo "[$(date)] Video name: $VIDEO_NAME"
echo "[$(date)] Caption: $CAPTION"

# Step 1: Download the video as an MP4 named after the video name.
OUTPUT_VIDEO="${VIDEO_NAME}.mp4"
echo "[$(date)] Downloading video from: $YOUTUBE_URL"
yt-dlp -f 'bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]' "$YOUTUBE_URL" -o "$OUTPUT_VIDEO"
echo "[$(date)] Video downloaded to: $OUTPUT_VIDEO"

# Generate a download token.
TOKEN=$(uuidgen)
echo "[$(date)] Generated download token: $TOKEN"

# Step 2: Upload the MP4 file to the root of the Firebase Storage bucket,
# setting the content type and the firebaseStorageDownloadTokens metadata.
echo "[$(date)] Uploading $OUTPUT_VIDEO to $DESTINATION ..."
gsutil -h "Content-Type: video/mp4" \
       -h "x-goog-meta-firebaseStorageDownloadTokens:$TOKEN" \
       cp "$OUTPUT_VIDEO" "$DESTINATION"
echo "[$(date)] Upload complete."

# Step 3: Construct the public URL for the uploaded MP4 including the token.
ENCODED_PATH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${VIDEO_NAME}.mp4'))")
PUBLIC_URL="https://firebasestorage.googleapis.com/v0/b/finshield-d895d.firebasestorage.app/o/${ENCODED_PATH}?alt=media&token=${TOKEN}"
echo "[$(date)] Constructed public URL: $PUBLIC_URL"

# Step 4: Add a document to Firestore via the REST API.
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

# Optional: Cleanup local file.
# rm "$OUTPUT_VIDEO"

echo "[$(date)] Process finished successfully."
