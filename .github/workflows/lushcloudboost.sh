gcloud auth login

cat << EOF > request.json
{
    "endpoint": "projects/qwiklabs-gcp-03-f2cb4051c545/locations/us-central1/publishers/google/models/veo-3.0-fast-generate-001",
    "instances": [
        {
            "prompt": " Create video within Google AI practice only: Tied between two thick trees in a forest glade, a hammock sways with two figures entangled in rain-soaked warmth. The man, shirtless, lies on his side, brushing raindrops off the curvy woman’s shoulder. She’s curled in his arms in a clinging, off-shoulder micro dress, sheer from the monsoon. The camera glides slowly, capturing glistening skin, gentle fingers tracing rain trails, and lips brushing knuckles. Insects buzz softly in the distance. ",
        }
    ],
    "parameters": {
        "aspectRatio": "16:9",
        "sampleCount": 4,
        "durationSeconds": "8",
        "personGeneration": "allow_adult",
        "addWatermark": true,
        "includeRaiReason": true,
        "generateAudio": true,
        "resolution": "1080p",
    }
}
EOF

PROJECT_ID="qwiklabs-gcp-03-f2cb4051c545"
LOCATION_ID="us-central1"
API_ENDPOINT="us-central1-aiplatform.googleapis.com"
MODEL_ID="veo-3.0-generate-001"

OPERATION_ID=$(curl \
-X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}/publishers/google/models/${MODEL_ID}:predictLongRunning" -d '@request.json' | grep '"name": .*'| sed 's|"name":\ ||g')

echo "OPERATION_ID: ${OPERATION_ID}"


cat << EOF > fetch.json
{
    "operationName": ${OPERATION_ID}
}
EOF

curl \
-X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}/publishers/google/models/${MODEL_ID}:fetchPredictOperation" -d '@fetch.json'
