import sys
!{sys.executable} -m pip install whisper

# Uninstall the currently installed 'whisper' package which is not the OpenAI version
print("Uninstalling potentially incorrect 'whisper' package...")
!{sys.executable} -m pip uninstall -y whisper

# Install the correct OpenAI 'whisper' package
print("Installing 'openai-whisper' package...")
!{sys.executable} -m pip install openai-whisper

# Remove existing 'whisper' module from sys.modules if it exists, to ensure the new package is loaded
if 'whisper' in sys.modules:
    del sys.modules['whisper']


import whisper
from google.colab import files
import os

print("upload file by ext. (mp3, wav, m4a, etc.):")
uploaded = files.upload()
file_name = list(uploaded.keys())[0] 

print(f"loading Whisper model...")
model = whisper.load_model("turbo")
my_prompt = "يا باشا، إحنا هنا بنتكلم مصري عادي، وبنقول كلام زي 'إزيك' و'عملت إيه' و'شغل الموتور'. ركز مع اللهجة المصرية."

print(f"جاري معالجة الملف: {file_name} ...")
result = model.transcribe(
    file_name,
    language="ar",
    initial_prompt=my_prompt
)

print("-" * 30)
print("speech to text:")
print(result["text"])

with open("transcription.txt", "w", encoding="utf-8") as f:
    f.write(result["text"])
print("-" * 30)
print("saveing transcription.txt")