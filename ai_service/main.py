import os
from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends
import face_recognition
import numpy as np
from io import BytesIO
from PIL import Image

app = FastAPI(title="N.Y Kitchen Face Recognition API")

EXPECTED_SERVICE_KEY_ENV = "AI_SERVICE_KEY"

def verify_service_key(x_service_key: str = Header(None, alias="X-Service-Key")):
    """Enforces shared-secret authentication on endpoints (Gap 14). Returns 401 when missing or wrong."""
    expected_key = os.getenv(EXPECTED_SERVICE_KEY_ENV)
    if not x_service_key or not expected_key or x_service_key != expected_key:
        raise HTTPException(
            status_code=401,
            detail="Unauthorized: Missing or invalid X-Service-Key header",
        )
    return x_service_key

@app.post("/extract_encoding", dependencies=[Depends(verify_service_key)])
async def extract_encoding(file: UploadFile = File(...)):

    try:
        contents = await file.read()
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
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def eye_aspect_ratio(eye):
    A = np.linalg.norm(np.array(eye[1]) - np.array(eye[5]))
    B = np.linalg.norm(np.array(eye[2]) - np.array(eye[4]))
    C = np.linalg.norm(np.array(eye[0]) - np.array(eye[3]))
    return (A + B) / (2.0 * C)

@app.post("/check_liveness", dependencies=[Depends(verify_service_key)])
async def check_liveness(file: UploadFile = File(...)):

    try:
        contents = await file.read()
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
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5000)

