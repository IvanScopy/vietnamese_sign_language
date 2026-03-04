# 🧠 Kế Hoạch Training Toàn Bộ Mô Hình AI

## Tổng Quan

Dự án cần train/fine-tune **3 model chính** trên Google Colab:

| # | Model | Task | Input → Output |
|---|---|---|---|
| 1 | **LSTM** (custom) | Nhận diện ký hiệu | Landmarks (60×201) → Gloss ID |
| 2 | **ViT5** (fine-tune) | Dịch Gloss → Việt | "XIN_CHÀO BẠN" → "Xin chào bạn" |
| 3 | **ViT5** (fine-tune) | Dịch Việt → Gloss | "Bạn bị đau ở đâu?" → "BẠN ĐAU Ở_ĐÂU" |
| 4 | **PhoWhisper** | Speech → Text | Audio → "Bạn bị đau ở đâu?" (dùng pretrained, không cần train) |

### Thứ tự train

```
Bước 1: Chuẩn bị dataset
Bước 2: Train LSTM (Sign Recognition)
Bước 3: Tạo dataset Gloss↔Vietnamese
Bước 4: Fine-tune ViT5 Gloss→Vietnamese
Bước 5: Fine-tune ViT5 Vietnamese→Gloss
Bước 6: Test PhoWhisper (pretrained)
Bước 7: Test tích hợp toàn bộ pipeline
```

---

## Bước 1: Chuẩn bị Dataset Cho LSTM

### 1.1 Dữ liệu gốc (bạn đã có)

```
raw_data/
├── label.csv          # ID, VIDEO, LABEL (gloss tiếng Việt)
├── videos/
│   ├── video_001.mp4
│   ├── video_002.mp4
│   └── ...
```

**`label.csv` format:**
```csv
ID,VIDEO,LABEL
1,video_001.mp4,XIN_CHÀO
2,video_002.mp4,CẢM_ƠN
3,video_003.mp4,ĐAU_ĐẦU
...
```

### 1.2 Trích xuất landmarks (MediaPipe)

```python
# extract_landmarks.py — Chạy trên Colab
import cv2
import mediapipe as mp
import numpy as np
import pandas as pd
import os

mp_holistic = mp.solutions.holistic

def extract_landmarks(video_path, target_frames=60):
    """Trích xuất 67 landmarks từ video, nội suy về 60 frames."""
    cap = cv2.VideoCapture(video_path)
    all_frames = []

    with mp_holistic.Holistic(
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    ) as holistic:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = holistic.process(rgb)
            
            frame_landmarks = []
            
            # 25 pose landmarks (thân trên: 0-24)
            if results.pose_landmarks:
                for i in range(25):
                    lm = results.pose_landmarks.landmark[i]
                    frame_landmarks.extend([lm.x, lm.y, lm.z])
            else:
                frame_landmarks.extend([0.0] * 75)  # 25 * 3
            
            # 21 left hand landmarks
            if results.left_hand_landmarks:
                for lm in results.left_hand_landmarks.landmark:
                    frame_landmarks.extend([lm.x, lm.y, lm.z])
            else:
                frame_landmarks.extend([0.0] * 63)  # 21 * 3
            
            # 21 right hand landmarks
            if results.right_hand_landmarks:
                for lm in results.right_hand_landmarks.landmark:
                    frame_landmarks.extend([lm.x, lm.y, lm.z])
            else:
                frame_landmarks.extend([0.0] * 63)  # 21 * 3
            
            all_frames.append(frame_landmarks)
    
    cap.release()
    
    # Nội suy về target_frames (60) bằng cubic interpolation
    if len(all_frames) < 2:
        return None
    
    all_frames = np.array(all_frames)  # (n_frames, 201)
    from scipy.interpolate import interp1d
    
    x_old = np.linspace(0, 1, len(all_frames))
    x_new = np.linspace(0, 1, target_frames)
    interpolator = interp1d(x_old, all_frames, axis=0, kind='cubic')
    
    return interpolator(x_new)  # (60, 201)
```

### 1.3 Data Augmentation (40 sequences/video)

```python
# augmentation.py
import numpy as np

def augment_landmarks(landmarks, n_augments=40):
    """Sinh 40 augmented sequences từ 1 video."""
    augmented = [landmarks]  # bản gốc
    
    for _ in range(n_augments - 1):
        aug = landmarks.copy()
        
        # Chọn ngẫu nhiên 1-3 phép augmentation
        n_methods = np.random.randint(1, 4)
        methods = np.random.choice(
            ['scale', 'rotate', 'translate', 'temporal', 'inter_hand'],
            n_methods, replace=False
        )
        
        for method in methods:
            if method == 'scale':
                scale = np.random.uniform(0.8, 1.2)
                aug = aug * scale
            
            elif method == 'rotate':
                angle = np.random.uniform(-15, 15) * np.pi / 180
                cos_a, sin_a = np.cos(angle), np.sin(angle)
                # Rotate x, y (giữ z)
                for i in range(0, aug.shape[1], 3):
                    x, y = aug[:, i], aug[:, i+1]
                    aug[:, i] = x * cos_a - y * sin_a
                    aug[:, i+1] = x * sin_a + y * cos_a
            
            elif method == 'translate':
                shift_x = np.random.uniform(-0.05, 0.05)
                shift_y = np.random.uniform(-0.05, 0.05)
                for i in range(0, aug.shape[1], 3):
                    aug[:, i] += shift_x
                    aug[:, i+1] += shift_y
            
            elif method == 'temporal':
                # Temporal stretching
                factor = np.random.uniform(0.8, 1.2)
                n_frames = int(len(aug) * factor)
                from scipy.interpolate import interp1d
                x_old = np.linspace(0, 1, len(aug))
                x_new = np.linspace(0, 1, 60)  # always 60 frames
                interp = interp1d(x_old, aug, axis=0, kind='cubic')
                aug = interp(x_new)
            
            elif method == 'inter_hand':
                # Inter-hand distance adjustment
                # Shift left hand relative to right
                shift = np.random.uniform(-0.02, 0.02)
                aug[:, 75:138] += shift  # left hand indices
        
        augmented.append(aug)
    
    return np.array(augmented)  # (40, 60, 201)
```

### 1.4 Tạo dataset hoàn chỉnh

```python
# create_dataset.py
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# Load labels
df = pd.read_csv('raw_data/label.csv')

# Encode gloss labels
le = LabelEncoder()
df['label_encoded'] = le.fit_transform(df['LABEL'])
np.save('label_encoder_classes.npy', le.classes_)

print(f"Số lượng ký hiệu (classes): {len(le.classes_)}")
print(f"Số lượng video: {len(df)}")

# Trích xuất + augment
all_X = []
all_y = []

for idx, row in df.iterrows():
    video_path = f"raw_data/videos/{row['VIDEO']}"
    landmarks = extract_landmarks(video_path)
    
    if landmarks is None:
        print(f"Skipped: {row['VIDEO']}")
        continue
    
    augmented = augment_landmarks(landmarks, n_augments=40)
    
    for aug in augmented:
        all_X.append(aug)
        all_y.append(row['label_encoded'])

X = np.array(all_X)  # (N*40, 60, 201)
y = np.array(all_y)  # (N*40,)

print(f"Dataset shape: X={X.shape}, y={y.shape}")

# Split: 80% train, 10% val, 10% test
X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.2, stratify=y, random_state=42)
X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=42)

# Lưu dataset
np.save('X_train.npy', X_train)
np.save('y_train.npy', y_train)
np.save('X_val.npy', X_val)
np.save('y_val.npy', y_val)
np.save('X_test.npy', X_test)
np.save('y_test.npy', y_test)

print(f"Train: {X_train.shape}, Val: {X_val.shape}, Test: {X_test.shape}")
```

---

## Bước 2: Train LSTM Model

### 2.1 Kiến trúc model

```python
# model_lstm.py
import torch
import torch.nn as nn

class SignLanguageLSTM(nn.Module):
    def __init__(self, input_size=201, hidden_size=256, num_layers=2, 
                 num_classes=100, dropout=0.3):
        super().__init__()
        
        # Batch Normalization đầu vào
        self.bn_input = nn.BatchNorm1d(60)
        
        # Bidirectional LSTM
        self.lstm = nn.LSTM(
            input_size=input_size,      # 67 landmarks × 3 = 201
            hidden_size=hidden_size,     # 256
            num_layers=num_layers,       # 2 layers
            batch_first=True,
            bidirectional=True,
            dropout=dropout
        )
        
        # Attention mechanism
        self.attention = nn.Sequential(
            nn.Linear(hidden_size * 2, 128),
            nn.Tanh(),
            nn.Linear(128, 1)
        )
        
        # Classifier
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(hidden_size * 2, 256),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(256, num_classes)
        )
    
    def forward(self, x):
        # x: (batch, 60, 201)
        x = self.bn_input(x)
        
        # LSTM
        lstm_out, _ = self.lstm(x)  # (batch, 60, 512)
        
        # Attention
        attn_weights = self.attention(lstm_out)  # (batch, 60, 1)
        attn_weights = torch.softmax(attn_weights, dim=1)
        context = torch.sum(lstm_out * attn_weights, dim=1)  # (batch, 512)
        
        # Classify
        output = self.classifier(context)  # (batch, num_classes)
        return output
```

### 2.2 Training script

```python
# train_lstm.py — Google Colab
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import TensorDataset, DataLoader
import numpy as np
from sklearn.metrics import accuracy_score, classification_report

# ===== CONFIG =====
BATCH_SIZE = 64
EPOCHS = 100
LEARNING_RATE = 1e-3
PATIENCE = 15  # Early stopping
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {DEVICE}")

# ===== LOAD DATA =====
X_train = torch.FloatTensor(np.load('X_train.npy'))
y_train = torch.LongTensor(np.load('y_train.npy'))
X_val = torch.FloatTensor(np.load('X_val.npy'))
y_val = torch.LongTensor(np.load('y_val.npy'))
X_test = torch.FloatTensor(np.load('X_test.npy'))
y_test = torch.LongTensor(np.load('y_test.npy'))

NUM_CLASSES = len(np.unique(y_train.numpy()))
print(f"Num classes: {NUM_CLASSES}")

train_loader = DataLoader(TensorDataset(X_train, y_train), batch_size=BATCH_SIZE, shuffle=True)
val_loader = DataLoader(TensorDataset(X_val, y_val), batch_size=BATCH_SIZE)
test_loader = DataLoader(TensorDataset(X_test, y_test), batch_size=BATCH_SIZE)

# ===== MODEL =====
model = SignLanguageLSTM(
    input_size=201,
    hidden_size=256,
    num_layers=2,
    num_classes=NUM_CLASSES,
    dropout=0.3
).to(DEVICE)

criterion = nn.CrossEntropyLoss()
optimizer = optim.AdamW(model.parameters(), lr=LEARNING_RATE, weight_decay=1e-4)
scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', patience=5, factor=0.5)

# ===== TRAINING LOOP =====
best_val_loss = float('inf')
patience_counter = 0

for epoch in range(EPOCHS):
    # Train
    model.train()
    train_loss = 0
    for X_batch, y_batch in train_loader:
        X_batch, y_batch = X_batch.to(DEVICE), y_batch.to(DEVICE)
        
        optimizer.zero_grad()
        output = model(X_batch)
        loss = criterion(output, y_batch)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        optimizer.step()
        train_loss += loss.item()
    
    # Validate
    model.eval()
    val_loss = 0
    val_preds = []
    val_labels = []
    with torch.no_grad():
        for X_batch, y_batch in val_loader:
            X_batch, y_batch = X_batch.to(DEVICE), y_batch.to(DEVICE)
            output = model(X_batch)
            loss = criterion(output, y_batch)
            val_loss += loss.item()
            val_preds.extend(output.argmax(dim=1).cpu().numpy())
            val_labels.extend(y_batch.cpu().numpy())
    
    val_acc = accuracy_score(val_labels, val_preds)
    avg_train_loss = train_loss / len(train_loader)
    avg_val_loss = val_loss / len(val_loader)
    
    scheduler.step(avg_val_loss)
    
    print(f"Epoch {epoch+1}/{EPOCHS} | "
          f"Train Loss: {avg_train_loss:.4f} | "
          f"Val Loss: {avg_val_loss:.4f} | "
          f"Val Acc: {val_acc:.4f} | "
          f"LR: {optimizer.param_groups[0]['lr']:.6f}")
    
    # Early stopping
    if avg_val_loss < best_val_loss:
        best_val_loss = avg_val_loss
        patience_counter = 0
        torch.save({
            'model_state_dict': model.state_dict(),
            'num_classes': NUM_CLASSES,
            'epoch': epoch,
            'val_acc': val_acc,
        }, 'best_lstm_model.pth')
        print(f"  ✅ Saved best model (val_acc={val_acc:.4f})")
    else:
        patience_counter += 1
        if patience_counter >= PATIENCE:
            print(f"  ⚠️ Early stopping at epoch {epoch+1}")
            break

# ===== EVALUATE =====
checkpoint = torch.load('best_lstm_model.pth')
model.load_state_dict(checkpoint['model_state_dict'])
model.eval()

test_preds = []
test_labels = []
with torch.no_grad():
    for X_batch, y_batch in test_loader:
        X_batch = X_batch.to(DEVICE)
        output = model(X_batch)
        test_preds.extend(output.argmax(dim=1).cpu().numpy())
        test_labels.extend(y_batch.numpy())

le_classes = np.load('label_encoder_classes.npy', allow_pickle=True)
print("\n===== TEST RESULTS =====")
print(f"Test Accuracy: {accuracy_score(test_labels, test_preds):.4f}")
print(classification_report(test_labels, test_preds, target_names=le_classes))
```

### 2.3 Mục tiêu
- **Accuracy tối thiểu**: ≥ 85% trên test set
- **Nếu thấp hơn**: tăng hidden_size, thêm data augmentation, thử thêm Conv1D trước LSTM

---

## Bước 3: Tạo Dataset Gloss↔Vietnamese (Cho ViT5)

### 3.1 Tại sao cần ViT5?

```
Sign language gloss:  "XIN_CHÀO BẠN KHỎE KHÔNG"
Vietnamese natural:   "Xin chào, bạn có khỏe không?"

Gloss KHÁC ngôn ngữ tự nhiên:
- Thiếu từ nối (có, là, được, của, ...)
- Thứ tự từ khác (VD: "NHÀ TÔI ĐẸP" → "Nhà của tôi rất đẹp")
- Không có dấu câu
→ CẦN ViT5 để dịch giữa 2 "ngôn ngữ" này
```

### 3.2 Tạo dataset bằng tay + LLM augmentation

**Bước 3.2.1: Tạo cặp cơ sở từ label.csv**

```python
# create_gloss_viet_pairs.py
"""
Từ label.csv, tạo cặp gloss-vietnamese.
Bước này CẦN LÀM THỦ CÔNG cho chính xác.
"""

# Ví dụ format output
pairs = [
    # Đơn giản (1 gloss = 1 câu)
    {"gloss": "XIN_CHÀO", "vietnamese": "Xin chào"},
    {"gloss": "CẢM_ƠN", "vietnamese": "Cảm ơn bạn"},
    {"gloss": "XIN_LỖI", "vietnamese": "Xin lỗi"},
    
    # Ghép nhiều gloss thành câu 
    {"gloss": "TÔI ĐAU ĐẦU", "vietnamese": "Tôi bị đau đầu"},
    {"gloss": "TÔI CẦN GIÚP", "vietnamese": "Tôi cần được giúp đỡ"},
    {"gloss": "BẠN TÊN GÌ", "vietnamese": "Bạn tên là gì?"},
    {"gloss": "TÔI MUỐN NƯỚC", "vietnamese": "Tôi muốn uống nước"},
    
    # Ngữ cảnh bệnh viện
    {"gloss": "TÔI ĐAU BỤNG", "vietnamese": "Tôi bị đau bụng"},
    {"gloss": "TÔI SỐT", "vietnamese": "Tôi bị sốt"},
    {"gloss": "BÁC_SĨ KHÁM", "vietnamese": "Bác sĩ khám cho tôi"},
]

# Lưu
import json
with open('gloss_viet_base.json', 'w', encoding='utf-8') as f:
    json.dump(pairs, f, ensure_ascii=False, indent=2)
```

**Bước 3.2.2: Augment bằng LLM (Google Gemini / GPT)**

```python
# augment_with_llm.py
"""
Dùng LLM để sinh thêm biến thể câu Vietnamese từ mỗi gloss.
Chạy trên Colab, cần API key.
"""
import google.generativeai as genai
import json

genai.configure(api_key="YOUR_API_KEY")
model = genai.GenerativeModel('gemini-2.0-flash')

def augment_pair(gloss, vietnamese, n_variants=5):
    prompt = f"""
Tôi đang xây dựng dataset cho hệ thống dịch Ngôn Ngữ Ký Hiệu Việt Nam.

Gloss (ký hiệu): {gloss}
Câu tiếng Việt mẫu: {vietnamese}

Hãy tạo {n_variants} biến thể câu tiếng Việt tự nhiên khác nhau 
cho cùng gloss trên. Các biến thể phải:
- Nghĩa tương đương
- Ngữ pháp đúng tiếng Việt
- Đa dạng phong cách: trang trọng, thân mật, ngắn gọn

Trả về JSON array: ["câu 1", "câu 2", ...]
"""
    response = model.generate_content(prompt)
    # Parse response
    try:
        variants = json.loads(response.text)
        return variants
    except:
        return []

# Load base pairs
with open('gloss_viet_base.json', 'r', encoding='utf-8') as f:
    base_pairs = json.load(f)

# Augment
all_pairs = []
for pair in base_pairs:
    # Bản gốc
    all_pairs.append(pair)
    
    # Biến thể
    variants = augment_pair(pair['gloss'], pair['vietnamese'])
    for v in variants:
        all_pairs.append({
            "gloss": pair['gloss'],
            "vietnamese": v
        })

print(f"Total pairs: {len(all_pairs)}")

with open('gloss_viet_augmented.json', 'w', encoding='utf-8') as f:
    json.dump(all_pairs, f, ensure_ascii=False, indent=2)
```

**Bước 3.2.3: Tạo dataset chiều ngược (Việt → Gloss)**

```python
# Dùng chung dataset, chỉ đảo input/output khi train
# gloss_viet_augmented.json dùng cho CẢ 2 chiều:
#   - ViT5 Gloss→Việt: input=gloss, output=vietnamese
#   - ViT5 Việt→Gloss: input=vietnamese, output=gloss
```

### 3.3 Mục tiêu dataset
- **Tối thiểu**: 2,000-5,000 cặp (cho đồ án)
- **Lý tưởng**: 10,000+ cặp
- **Bao gồm**: đa dạng chủ đề (chào hỏi, y tế, trường học, gia đình, cảm xúc)

---

## Bước 4: Fine-tune ViT5 (Gloss → Vietnamese)

### 4.1 Setup Colab

```python
# Cell 1: Install
!pip install transformers datasets sentencepiece accelerate -q

# Cell 2: Check GPU
import torch
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"VRAM: {torch.cuda.get_device_properties(0).total_mem / 1e9:.1f} GB")
# Colab free: T4 (16GB) hoặc V100 (16GB)
```

### 4.2 Chuẩn bị data

```python
# Cell 3: Load dataset
import json
from sklearn.model_selection import train_test_split

with open('gloss_viet_augmented.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Format cho T5: "dịch gloss sang tiếng Việt: XIN_CHÀO BẠN"
train_data, temp_data = train_test_split(data, test_size=0.2, random_state=42)
val_data, test_data = train_test_split(temp_data, test_size=0.5, random_state=42)

print(f"Train: {len(train_data)}, Val: {len(val_data)}, Test: {len(test_data)}")
```

### 4.3 Fine-tune

```python
# Cell 4: Fine-tune ViT5 Gloss → Vietnamese
from transformers import (
    AutoTokenizer, 
    AutoModelForSeq2SeqLM,
    Seq2SeqTrainingArguments, 
    Seq2SeqTrainer,
    DataCollatorForSeq2Seq
)
from datasets import Dataset
import numpy as np

MODEL_NAME = "VietAI/vit5-base"  # hoặc vit5-large nếu đủ VRAM

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME)

# Tạo HuggingFace Dataset
PREFIX = "dịch gloss sang tiếng Việt: "

def preprocess(example):
    input_text = PREFIX + example['gloss']
    target_text = example['vietnamese']
    
    model_inputs = tokenizer(
        input_text, max_length=128, truncation=True, padding='max_length'
    )
    labels = tokenizer(
        target_text, max_length=128, truncation=True, padding='max_length'
    )
    model_inputs['labels'] = labels['input_ids']
    return model_inputs

train_dataset = Dataset.from_list(train_data).map(preprocess, remove_columns=['gloss', 'vietnamese'])
val_dataset = Dataset.from_list(val_data).map(preprocess, remove_columns=['gloss', 'vietnamese'])

# Training arguments
training_args = Seq2SeqTrainingArguments(
    output_dir="./vit5_gloss2viet",
    num_train_epochs=30,
    per_device_train_batch_size=16,      # giảm nếu OOM
    per_device_eval_batch_size=16,
    learning_rate=3e-4,
    weight_decay=0.01,
    warmup_steps=500,
    eval_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
    metric_for_best_model="eval_loss",
    predict_with_generate=True,
    generation_max_length=128,
    fp16=True,                            # mixed precision
    save_total_limit=3,
    logging_steps=50,
    report_to="none",
)

data_collator = DataCollatorForSeq2Seq(tokenizer, model=model)

trainer = Seq2SeqTrainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=val_dataset,
    tokenizer=tokenizer,
    data_collator=data_collator,
)

trainer.train()

# Lưu model
trainer.save_model("./vit5_gloss2viet_best")
tokenizer.save_pretrained("./vit5_gloss2viet_best")
```

### 4.4 Evaluate

```python
# Cell 5: Test
from nltk.translate.bleu_score import corpus_bleu

model.eval()
predictions = []
references = []

for sample in test_data:
    input_text = PREFIX + sample['gloss']
    inputs = tokenizer(input_text, return_tensors="pt", max_length=128, truncation=True).to('cuda')
    
    outputs = model.generate(**inputs, max_length=128, num_beams=4)
    pred = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    predictions.append(pred)
    references.append(sample['vietnamese'])
    
    # In một số ví dụ
    if len(predictions) <= 10:
        print(f"Gloss: {sample['gloss']}")
        print(f"Pred:  {pred}")
        print(f"Ref:   {sample['vietnamese']}")
        print("---")

# BLEU score
bleu = corpus_bleu(
    [[ref.split()] for ref in references],
    [pred.split() for pred in predictions]
)
print(f"\nBLEU Score: {bleu:.4f}")
```

### 4.5 Mục tiêu
- **BLEU Score**: ≥ 0.5 (cho đồ án)
- **Kiểm tra thủ công**: phải đọc được, đúng ngữ pháp

---

## Bước 5: Fine-tune ViT5 (Vietnamese → Gloss)

### Giống Bước 4, chỉ đảo chiều

```python
# Thay đổi:
PREFIX = "dịch tiếng Việt sang gloss: "

def preprocess(example):
    input_text = PREFIX + example['vietnamese']  # ĐẢO: input = vietnamese
    target_text = example['gloss']               # ĐẢO: output = gloss
    
    model_inputs = tokenizer(input_text, max_length=128, truncation=True, padding='max_length')
    labels = tokenizer(target_text, max_length=128, truncation=True, padding='max_length')
    model_inputs['labels'] = labels['input_ids']
    return model_inputs

# Training tương tự
# Lưu vào folder khác: "./vit5_viet2gloss_best"
```

---

## Bước 6: Test PhoWhisper (Pretrained)

### Không cần train, chỉ test

```python
# test_phowhisper.py
!pip install transformers librosa -q

from transformers import pipeline
import librosa

# Load model
asr = pipeline(
    "automatic-speech-recognition",
    model="vinai/PhoWhisper-small",
    device=0  # GPU
)

# Test với audio file
audio, sr = librosa.load("test_audio.wav", sr=16000)
result = asr(audio, generate_kwargs={"language": "vi"})

print(f"Recognized: {result['text']}")
```

### Test streaming (chunked)

```python
# Simulate chunked processing
import numpy as np

def process_audio_stream(audio_path, chunk_duration=3.0):
    """Xử lý audio theo chunks (mô phỏng streaming)."""
    audio, sr = librosa.load(audio_path, sr=16000)
    chunk_size = int(sr * chunk_duration)
    
    full_text = ""
    for i in range(0, len(audio), chunk_size):
        chunk = audio[i:i+chunk_size]
        if len(chunk) < sr * 0.5:  # quá ngắn
            continue
        
        result = asr(chunk, generate_kwargs={"language": "vi"})
        full_text += result['text'] + " "
        print(f"Chunk {i//chunk_size}: {result['text']}")
    
    print(f"\nFull text: {full_text.strip()}")
    return full_text.strip()
```

---

## Bước 7: Test Tích Hợp Pipeline

### 7.1 Test Nhánh 1: Sign → Speech (End-to-End)

```python
# test_pipeline_sign2speech.py
"""
Video → MediaPipe → LSTM → Gloss → ViT5 → Vietnamese → Edge-TTS → Audio
"""
import edge_tts
import asyncio

# 1. Extract landmarks
landmarks = extract_landmarks("test_video.mp4")  # (60, 201)

# 2. LSTM predict
model_lstm = SignLanguageLSTM(input_size=201, num_classes=NUM_CLASSES)
model_lstm.load_state_dict(torch.load('best_lstm_model.pth')['model_state_dict'])
model_lstm.eval()

input_tensor = torch.FloatTensor(landmarks).unsqueeze(0)  # (1, 60, 201)
with torch.no_grad():
    output = model_lstm(input_tensor)
    gloss_id = output.argmax(dim=1).item()

le_classes = np.load('label_encoder_classes.npy', allow_pickle=True)
gloss = le_classes[gloss_id]
print(f"Gloss: {gloss}")

# 3. ViT5 Gloss → Vietnamese
input_text = f"dịch gloss sang tiếng Việt: {gloss}"
inputs = tokenizer_g2v(input_text, return_tensors="pt", max_length=128, truncation=True)
outputs = model_g2v.generate(**inputs, max_length=128, num_beams=4)
vietnamese = tokenizer_g2v.decode(outputs[0], skip_special_tokens=True)
print(f"Vietnamese: {vietnamese}")

# 4. Edge-TTS
async def tts(text, output_file="output.mp3"):
    communicate = edge_tts.Communicate(text, "vi-VN-HoaiMyNeural")
    await communicate.save(output_file)

asyncio.run(tts(vietnamese))
print("✅ Audio saved to output.mp3")
```

### 7.2 Test Nhánh 2: Speech → Sign (End-to-End)

```python
# test_pipeline_speech2sign.py
"""
Audio → PhoWhisper → Vietnamese → ViT5 → Gloss → Mapping
"""

# 1. PhoWhisper
result = asr("test_audio.wav", generate_kwargs={"language": "vi"})
vietnamese = result['text']
print(f"Vietnamese: {vietnamese}")

# 2. ViT5 Vietnamese → Gloss
input_text = f"dịch tiếng Việt sang gloss: {vietnamese}"
inputs = tokenizer_v2g(input_text, return_tensors="pt", max_length=128, truncation=True)
outputs = model_v2g.generate(**inputs, max_length=128, num_beams=4)
gloss = tokenizer_v2g.decode(outputs[0], skip_special_tokens=True)
print(f"Gloss: {gloss}")

# 3. Mapping (lookup landmark reference)
gloss_tokens = gloss.split()
for token in gloss_tokens:
    # Tìm landmark data tương ứng trong database
    landmark_ref = lookup_landmark_by_gloss(token)  # từ database
    print(f"  {token} → landmark sequence found: {landmark_ref is not None}")

print("✅ Pipeline complete — sẵn sàng gửi cho Three.js render")
```

---

## Export Model Cho Production

### Lưu tất cả models

```python
# export_all.py
import shutil

# 1. LSTM
shutil.copy('best_lstm_model.pth', 'production_models/lstm/')
shutil.copy('label_encoder_classes.npy', 'production_models/lstm/')

# 2. ViT5 Gloss→Viet
shutil.copytree('./vit5_gloss2viet_best', 'production_models/vit5_gloss2viet/')

# 3. ViT5 Viet→Gloss
shutil.copytree('./vit5_viet2gloss_best', 'production_models/vit5_viet2gloss/')

# 4. PhoWhisper (download pretrained)
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor
model = AutoModelForSpeechSeq2Seq.from_pretrained("vinai/PhoWhisper-small")
processor = AutoProcessor.from_pretrained("vinai/PhoWhisper-small")
model.save_pretrained('production_models/phowhisper/')
processor.save_pretrained('production_models/phowhisper/')

print("✅ All models exported to production_models/")
```

### Cấu trúc thư mục model

```
production_models/
├── lstm/
│   ├── best_lstm_model.pth
│   └── label_encoder_classes.npy
├── vit5_gloss2viet/
│   ├── config.json
│   ├── pytorch_model.bin (hoặc model.safetensors)
│   ├── tokenizer.json
│   └── ...
├── vit5_viet2gloss/
│   ├── config.json
│   ├── pytorch_model.bin
│   ├── tokenizer.json
│   └── ...
└── phowhisper/
    ├── config.json
    ├── pytorch_model.bin
    ├── preprocessor_config.json
    └── ...
```

---

## Checklist Tổng Hợp

- [ ] **Bước 1**: Trích xuất landmarks từ tất cả video
- [ ] **Bước 1**: Augment data (40 sequences/video)
- [ ] **Bước 1**: Split train/val/test (80/10/10)
- [ ] **Bước 2**: Train LSTM → accuracy ≥ 85%
- [ ] **Bước 3**: Tạo dataset Gloss-Vietnamese (≥ 2000 cặp)
- [ ] **Bước 3**: Augment bằng LLM (→ ≥ 5000 cặp)
- [ ] **Bước 4**: Fine-tune ViT5 Gloss→Việt → BLEU ≥ 0.5
- [ ] **Bước 5**: Fine-tune ViT5 Việt→Gloss → BLEU ≥ 0.5
- [ ] **Bước 6**: Test PhoWhisper pretrained
- [ ] **Bước 7**: Test end-to-end cả 2 pipeline
- [ ] **Export**: Lưu tất cả models cho production

---

## Lưu Ý Google Colab

| Vấn đề | Giải pháp |
|---|---|
| **Session timeout** (Colab free: ~12h) | Lưu checkpoint thường xuyên vào Google Drive |
| **RAM giới hạn** (12GB) | Dùng `fp16`, giảm batch size, load data lazy |
| **GPU VRAM** (T4 = 16GB) | ViT5-base fit, nếu OOM dùng gradient accumulation |
| **Lưu model** | Mount Google Drive: `drive.mount('/content/drive')` |
| **Colab Pro** | Nên dùng nếu dataset lớn (A100 40GB, longer runtime) |

```python
# Mount Google Drive (chạy đầu tiên)
from google.colab import drive
drive.mount('/content/drive')

# Lưu vào Drive
SAVE_DIR = '/content/drive/MyDrive/vsl_models/'
```
