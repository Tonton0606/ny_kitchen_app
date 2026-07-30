import traceback
try:
    import face_recognition_models
    print("SUCCESS!")
except Exception:
    traceback.print_exc()
