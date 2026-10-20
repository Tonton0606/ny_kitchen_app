import os
import time
from collections import defaultdict
from io import BytesIO
from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends, Request
try:
    import face_recognition
except BaseException:
    face_recognition = None
import numpy as np
from PIL import Image

app = FastAPI(title="N.Y Kitchen Face Recognition API")

EXPECTED_SERVICE_KEY_ENV = "AI_SERVICE_KEY"
MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB

def verify_service_key(x_service_key: str = Header(None, alias="X-Service-Key")):
    """Enforces shared-secret authentication on endpoints (Gap 14). Returns 401 when missing or wrong."""
    expected_key = os.getenv(EXPECTED_SERVICE_KEY_ENV)
    if not x_service_key or not expected_key or x_service_key != expected_key:
        raise HTTPException(
            status_code=401,
            detail="Unauthorized: Missing or invalid X-Service-Key header",
        )
    return x_service_key

class InMemoryRateLimiter:
    """Sliding-window rate limiter per client (Gap 16)."""
    def __init__(self, requests_per_minute: int = 120):
        self.requests_per_minute = requests_per_minute
        self.window_seconds = 60.0
        self.history = defaultdict(list)

    def check(self, client_id: str):
        now = time.time()
        cutoff = now - self.window_seconds
        
        # Keep only timestamps within the sliding window
        timestamps = [t for t in self.history[client_id] if t > cutoff]
        
        if len(timestamps) >= self.requests_per_minute:
            retry_after = int(self.window_seconds - (now - timestamps[0])) + 1
            raise HTTPException(
                status_code=429,
                detail=f"Too Many Requests: Rate limit exceeded ({self.requests_per_minute} req/min)",
                headers={"Retry-After": str(max(1, retry_after))},
            )
        
        timestamps.append(now)
        self.history[client_id] = timestamps

    def reset(self):
        self.history.clear()

_rpm = int(os.getenv("AI_RATE_LIMIT_PER_MINUTE", "120"))
rate_limiter = InMemoryRateLimiter(requests_per_minute=_rpm)

async def check_rate_limit(request: Request):
    client_ip = request.client.host if request.client else "127.0.0.1"
    rate_limiter.check(client_ip)

def validate_image_bytes(contents: bytes) -> None:
    """Validates that uploaded contents are non-empty, within size limits, and possess valid image magic bytes (Gap 19)."""
    if not contents:
        raise HTTPException(status_code=400, detail="Invalid image: empty payload")
    if len(contents) > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"Payload too large. Maximum image size is {MAX_IMAGE_SIZE_BYTES // (1024 * 1024)}MB",
        )
    
    # Check magic byte signatures
    # JPEG: starts with FF D8 FF
    # PNG: starts with 89 50 4E 47 0D 0A 1A 0A
    # WebP: starts with RIFF and bytes 8..12 are WEBP
    # BMP: starts with BM (42 4D)
    is_jpeg = contents.startswith(b"\xff\xd8\xff")
    is_png = contents.startswith(b"\x89PNG\r\n\x1a\n")
    is_webp = len(contents) >= 12 and contents.startswith(b"RIFF") and contents[8:12] == b"WEBP"
    is_bmp = contents.startswith(b"BM")

    if not (is_jpeg or is_png or is_webp or is_bmp):
        raise HTTPException(
            status_code=400,
            detail="Invalid image format: unsupported or missing magic bytes (only JPEG, PNG, WEBP, BMP allowed)",
        )

@app.post("/extract_encoding", dependencies=[Depends(verify_service_key), Depends(check_rate_limit)])
async def extract_encoding(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        validate_image_bytes(contents)
        image = Image.open(BytesIO(contents)).convert('RGB')
        image_np = np.array(image)
        
        # Detect face encodings in the image
        face_encodings = face_recognition.face_encodings(image_np)
        
        if len(face_encodings) == 0:
            raise HTTPException(status_code=400, detail="No face found in the image")
        if len(face_encodings) > 1:
            raise HTTPException(status_code=400, detail="Multiple faces found, please ensure only one face is visible")
            
        encoding = face_encodings[0].tolist()
        return {"encoding": encoding}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def eye_aspect_ratio(eye):
    A = np.linalg.norm(np.array(eye[1]) - np.array(eye[5]))
    B = np.linalg.norm(np.array(eye[2]) - np.array(eye[4]))
    C = np.linalg.norm(np.array(eye[0]) - np.array(eye[3]))
    return (A + B) / (2.0 * C)

@app.post("/check_liveness", dependencies=[Depends(verify_service_key), Depends(check_rate_limit)])
async def check_liveness(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        validate_image_bytes(contents)
        image = Image.open(BytesIO(contents)).convert('RGB')
        image_np = np.array(image)
        
        # Get facial landmarks
        landmarks_list = face_recognition.face_landmarks(image_np)
        
        if len(landmarks_list) == 0:
            return {"error": "No face found"}
            
        landmarks = landmarks_list[0]
        
        if "left_eye" not in landmarks or "right_eye" not in landmarks:
            return {"error": "Could not detect eyes"}
            
        left_ear = eye_aspect_ratio(landmarks["left_eye"])
        right_ear = eye_aspect_ratio(landmarks["right_eye"])
        
        # Average EAR
        ear = (left_ear + right_ear) / 2.0
        
        # Standard threshold for closed eyes is usually around 0.21 - 0.25
        eyes_closed = bool(ear < 0.24)
        
        return {"eyes_closed": eyes_closed, "ear": float(ear)}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5000)

