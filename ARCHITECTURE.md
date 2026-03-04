# 🏗️ Kiến Trúc Kỹ Thuật — Ứng Dụng Ngôn Ngữ Ký Hiệu Việt Nam

## Tổng Quan Kiến Trúc

Kiến trúc **Hybrid** (Client + Server): xử lý nhẹ trên client, AI inference trên server.

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT (Web / Mobile)                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │ MediaPipe    │  │ Three.js     │  │ UI (React/RN)          │  │
│  │ Holistic     │  │ 3D Avatar    │  │ Camera, Mic, Speaker   │  │
│  │ (Landmarks)  │  │ (Renderer)   │  │ WebRTC (Video Call)    │  │
│  └──────┬───────┘  └──────▲───────┘  └────────────────────────┘  │
│         │                 │                                      │
└─────────┼─────────────────┼──────────────────────────────────────┘
          │ landmarks       │ gloss + animation data
          ▼                 │
┌─────────────────────────────────────────────────────────────────┐
│                        SERVER (FastAPI + GPU)                    │
│                                                                 │
│  ┌──── Nhánh 1: Sign → Speech ────┐                            │
│  │ Landmarks → LSTM → Gloss       │                            │
│  │ Gloss → ViT5 → Tiếng Việt      │                            │
│  │ Tiếng Việt → Edge-TTS → Audio  │                            │
│  └─────────────────────────────────┘                            │
│                                                                 │
│  ┌──── Nhánh 2: Speech → Sign ────┐                            │
│  │ Audio → PhoWhisper → Tiếng Việt │                            │
│  │ Tiếng Việt → ViT5 → Gloss      │                            │
│  │ Gloss → Mapping Engine → Anim  │                            │
│  └─────────────────────────────────┘                            │
│                                                                 │
│  ┌──── Hạ tầng chung ────────────┐                              │
│  │ PostgreSQL │ WebSocket │ Auth  │                              │
│  └────────────────────────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Nhánh 1: Sign → Speech (Chi tiết)

### Pipeline

```
Camera (Client)
  → MediaPipe Holistic (Client-side) ✅
  → Trích xuất 67 landmarks / frame (25 pose + 21 tay trái + 21 tay phải)
  → Gửi landmarks lên Server (WebSocket, ~4KB/frame)
  → Nội suy về 60 frames, normalize (Server)
  → LSTM Model (Server, GPU)
  → Output: Chuỗi Gloss (VD: "XIN_CHÀO BẠN KHỎE KHÔNG")
  → ViT5 Gloss→Việt (Server)
  → Output: Câu tiếng Việt ("Xin chào, bạn có khỏe không?")
  → Edge-TTS (Server → API Microsoft)
  → Output: Audio WAV/MP3
  → Gửi Text + Audio về Client
  → Client hiển thị text + phát âm thanh
```

### Đánh giá lựa chọn

| Thành phần | Lựa chọn | Đánh giá |
|---|---|---|
| **MediaPipe client-side** | ✅ Hợp lý | Giảm tải server, giảm bandwidth (gửi landmarks thay vì video). MediaPipe JS/TFLite chạy tốt trên browser & mobile. Latency thấp (~30ms/frame) |
| **LSTM** | ✅ Chấp nhận | Nhẹ, phù hợp đồ án. Input: `(60, 67×3)` = `(60, 201)`. Có thể dùng Bidirectional LSTM + Attention để cải thiện |
| **ViT5** | ✅ Tốt | Model T5 tiếng Việt tốt nhất hiện tại. Encoder-Decoder, phù hợp cho task translation |
| **Edge-TTS** | ✅ Tốt | Miễn phí, giọng Việt tự nhiên, latency ~200-500ms |

### LSTM — Đề xuất chi tiết

> [!IMPORTANT]
> **Đề xuất Output của LSTM**: Output là **chuỗi gloss tokens** (sequence classification / CTC). Mỗi gesture segment → 1 gloss word. Dùng **Sliding Window** để detect liên tục.

**Kiến trúc đề xuất:**

```
Input: (batch, 60, 201)  # 60 frames × 67 landmarks × 3 coords
  → Bidirectional LSTM (2 layers, hidden=256)
  → Attention Layer
  → Dense → Softmax
  → Output: gloss_id (phân loại N lớp = N ký hiệu trong dataset)
```

**2 phương án cho LSTM output:**

| Phương án | Mô tả | Ưu điểm | Nhược điểm |
|---|---|---|---|
| **A: Isolated Sign (Đề xuất cho MVP)** | Mỗi lần nhận diện 1 ký hiệu → 1 gloss | Đơn giản, chính xác cao | Cần segment ký hiệu trước |
| **B: Continuous Sign** | Nhận diện liên tục chuỗi ký hiệu → chuỗi gloss | Tự nhiên hơn | Phức tạp, cần CTC loss |

> [!TIP]
> **Đề xuất cho đồ án**: Bắt đầu với **Phương án A** (Isolated Sign). Người dùng ra 1 ký hiệu → nhận diện → hiển thị. Sau đó nâng cấp lên Continuous nếu có thời gian.

---

## Nhánh 2: Speech → Sign (Chi tiết)

### Pipeline

```
Microphone (Client)
  → Ghi âm + gửi audio chunks lên Server (WebSocket)
  → PhoWhisper Small (Server, GPU)
  → Output: Text tiếng Việt ("Bạn bị đau ở đâu?")
  → Hiển thị Text (subtitle) → gửi về Client
  → ViT5 Việt→Gloss (Server)
  → Output: Chuỗi Gloss ("BẠN ĐAU Ở_ĐÂU")
  → Mapping Engine (Server)
  → Lookup: Gloss → Animation clip ID
  → Gửi danh sách Animation IDs + timing → Client
  → Three.js (Client) render Avatar 3D thực hiện ký hiệu
  → Đồng thời hiển thị Text subtitle
```

### Đánh giá lựa chọn

| Thành phần | Lựa chọn | Đánh giá |
|---|---|---|
| **PhoWhisper Small** | ✅ Tốt | Model Whisper fine-tune cho tiếng Việt (VinAI). Small = ~244M params, cân bằng accuracy/speed |
| **ViT5 Việt→Gloss** | ⚠️ Cần dataset | Cùng kiến trúc T5, train chiều ngược. **Cần tạo dataset Vietnamese→Gloss** |
| **Mapping Engine** | ✅ Hợp lý | Lookup table: gloss → animation clip |
| **Three.js** | ✅ Hợp lý | Render 3D trên browser. Dùng glTF model export từ Blender |

### PhoWhisper — Xử lý Streaming

> [!IMPORTANT]
> **Đề xuất cho Real-time**: Dùng **chunked processing**. Client gửi audio chunks (mỗi 2-3 giây) → Server xử lý từng chunk → trả text dần dần. Không phải real-time streaming thuần (Whisper không hỗ trợ native streaming), nhưng đủ tốt cho UX.

### ViT5 — Vấn đề Dataset

> [!WARNING]
> **Đây là thách thức lớn nhất của dự án.** Bạn cần 2 dataset:
>
> 1. **Gloss→Việt**: Dịch chuỗi gloss thành câu tiếng Việt tự nhiên
> 2. **Việt→Gloss**: Dịch câu tiếng Việt thành chuỗi gloss
>
> Cả 2 dùng **cùng 1 dataset song song (parallel corpus)**, chỉ khác chiều train.

**Đề xuất tạo dataset Gloss↔Vietnamese:**

| Phương án | Mô tả |
|---|---|
| **1. Tự xây dựng** | Từ `label.csv` (đã có gloss), viết thêm câu tiếng Việt tương ứng cho mỗi gloss. Ưu: chính xác. Nhược: tốn thời gian |
| **2. Augmentation bằng LLM** | Dùng GPT/Gemini để sinh nhiều biến thể câu Việt từ gloss. VD: gloss `XIN_CHÀO BẠN` → "Xin chào bạn", "Chào bạn nhé", "Hello bạn". Ưu: nhanh. Nhược: cần kiểm tra |
| **3. Rule-based baseline** | Viết rule đơn giản: nối gloss thành câu + thêm từ nối. VD: `ĐAU ĐẦU` → "Tôi bị đau đầu". Ưu: nhanh cho MVP |

> [!TIP]
> **Đề xuất cho đồ án**: Kết hợp **Phương án 1 + 2**. Tự viết 500-1000 cặp cơ bản, sau đó dùng LLM augment lên 5000-10000 cặp. Hoặc nếu LSTM output chỉ là isolated gloss (1 từ), có thể **bỏ qua ViT5 cho MVP** và map trực tiếp gloss → câu đơn giản.

---

## 3D Avatar (Three.js + Blender)

### Kiến trúc

```
Blender (Offline)
  → Tạo 2 model: Nam & Nữ (glTF format)
  → Tạo animation clips cho mỗi ký hiệu (gloss)
  → Export: model.glb + animations.glb

Three.js (Client, Runtime)
  → Load glTF model
  → Nhận gloss sequence từ server
  → Play animation clips theo thứ tự
  → Blend giữa các clips (AnimationMixer)
```

### Về Animation Data — Vấn đề & Giải pháp

> [!WARNING]
> **Không thể** tạo animation 3D trực tiếp từ landmark data (67 keypoints × 60 frames). Landmark data là tọa độ 2D/3D từ MediaPipe, không phải bone rotation data của 3D skeleton. Cần quy trình riêng.

**3 phương án tạo animation:**

| Phương án | Mô tả | Phù hợp đồ án? |
|---|---|---|
| **A: Thủ công trong Blender** | Animator tạo tay từng ký hiệu. Chất lượng cao nhất | ⚠️ Rất tốn thời gian |
| **B: Retarget từ MediaPipe → Blender** | Dùng tool chuyển landmark → bone animation (VD: MediaPipe2Blender addon). Chất lượng trung bình | ✅ Khả thi, cần chỉnh sửa thủ công |
| **C: Ý tưởng V-tuber (Đề xuất)** | Dùng thư viện như **Kalidokit** hoặc **MediaPipe → Three.js rigging** để drive avatar real-time từ landmarks. Không cần pre-made animation | ✅ Phù hợp nhất cho đồ án |

> [!IMPORTANT]
> **Đề xuất: Phương án C (V-tuber style)**
>
> Thay vì pre-made animation clips, dùng **landmark data để drive avatar trực tiếp** trong Three.js:
> 1. Server nhận text → dịch thành gloss → tìm **reference landmark sequence** tương ứng trong database
> 2. Gửi landmark sequence về client
> 3. Client dùng **Kalidokit / custom rigging** để áp landmark lên 3D avatar (giống V-tuber)
> 4. Avatar di chuyển theo landmark data
>
> **Ưu điểm**: Tận dụng được dataset landmark đã có, không cần tạo animation thủ công
> **Nhược điểm**: Chuyển động có thể không mượt bằng animation thủ công

### Transition giữa các ký hiệu

Dùng **lerp (linear interpolation)** giữa frame cuối của ký hiệu trước và frame đầu của ký hiệu sau. Thời gian blend: ~200-300ms.

---

## Tech Stack Tổng Hợp

### Frontend

| Thành phần | Công nghệ | Ghi chú |
|---|---|---|
| Web App | **React** + TypeScript | SPA, responsive |
| Mobile App | **React Native** | Cross-platform iOS/Android |
| 3D Avatar | **Three.js** + react-three-fiber | Render avatar, animation |
| Video Call | **WebRTC** (PeerJS / simple-peer) | P2P video/audio |
| Landmark Detection | **MediaPipe Holistic** (JS/TFLite) | Client-side |
| State Management | Zustand hoặc Redux Toolkit | Quản lý state |

> [!NOTE]
> **Về chia sẻ code**: React (web) và React Native (mobile) **không thể dùng chung UI components** nhưng có thể chia sẻ **business logic, API layer, types/interfaces** thông qua monorepo (nx hoặc turborepo). Khuyến nghị tách thành 3 packages: `@app/shared` (logic chung), `@app/web`, `@app/mobile`.

### Backend

| Thành phần | Công nghệ | Ghi chú |
|---|---|---|
| API Framework | **FastAPI** (Python) | Async, tốt cho ML serving |
| Database | **PostgreSQL** | Relational, hỗ trợ full-text search |
| Realtime | **WebSocket** (FastAPI WebSocket) | Stream landmarks, audio, results |
| Auth | **JWT** + bcrypt | Đơn giản, phù hợp đồ án |
| File Storage | **MinIO** (S3-compatible, self-hosted) | Lưu video, animation, audio |
| Task Queue | **Celery + Redis** (optional) | Nếu cần async tasks (TTS, batch) |
| SMS | **Twilio** hoặc **Vonage** | Gửi SMS cho SOS |
| Push Notification | **Firebase Cloud Messaging (FCM)** | Push notification mobile + web |

> [!TIP]
> **Về File Storage**: Cho đồ án, **MinIO** self-hosted trên VPS là lựa chọn tốt nhất — miễn phí, API giống S3, dễ setup. Nếu muốn đơn giản hơn, có thể lưu trực tiếp trên filesystem VPS + serve qua Nginx.

### AI Models (Server GPU)

| Model | Task | Size | Framework |
|---|---|---|---|
| **LSTM** (custom) | Landmarks → Gloss | ~5-10MB | PyTorch |
| **ViT5-base** | Gloss ↔ Vietnamese | ~900MB | HuggingFace Transformers |
| **PhoWhisper Small** | Speech → Vietnamese Text | ~244M params | HuggingFace Transformers |
| **Edge-TTS** | Text → Speech (API call) | N/A (cloud) | edge-tts Python lib |

---

## Luồng Dữ Liệu Real-time (WebSocket)

### Chế độ mặt đối mặt (1 thiết bị)

```
┌──────────────────────────────────────────────────┐
│              MÀN HÌNH CHIA ĐÔI                   │
│                                                   │
│  ┌─── Phía Người Khiếm Thính (xoay 180°) ───┐   │
│  │ [Avatar 3D]         [Text subtitle]        │   │
│  │ (xem ký hiệu)      (đọc nội dung)        │   │
│  └────────────────────────────────────────────┘   │
│  ─────────────── Đường chia ──────────────────    │
│  ┌─── Phía Người Bình Thường ────────────────┐   │
│  │ [Text]  [Nút: 🎤 Nói / Nghe]              │   │
│  │ (đọc ký hiệu đã nhận diện)               │   │
│  └────────────────────────────────────────────┘   │
│                                                   │
│         [📷 Camera chung ở giữa]                  │
│              [🆘 SOS]                             │
└──────────────────────────────────────────────────┘
```

**Luồng WebSocket:**
```
Client ←──WebSocket──→ Server

1. Người khiếm thính ra ký hiệu:
   Client → [landmarks 67×3 mỗi 33ms] → Server
   Server → LSTM → Gloss → ViT5 → Text
   Server → Edge-TTS → Audio
   Server → [text + audio] → Client
   Client → hiển thị text + phát audio

2. Người bình thường nói:
   Client → [audio chunks mỗi 2s] → Server
   Server → PhoWhisper → Text
   Server → ViT5 → Gloss
   Server → [text + gloss + landmark ref] → Client
   Client → hiển thị text + render avatar 3D
```

---

## Database Schema (PostgreSQL — Sơ bộ)

```sql
-- Người dùng
users (id, name, user_type, age, phone, password_hash, created_at)

-- Liên kết người thân
emergency_contacts (id, user_id → users, name, phone, relation)

-- Lịch sử hội thoại
conversations (id, user1_id, user2_id, mode, started_at, ended_at)
messages (id, conversation_id, sender_type, content_text, gloss, created_at)

-- Từ điển ký hiệu
glossary (id, gloss, vietnamese_text, category, video_url, landmark_data_url)

-- Bài học
lessons (id, title, category, order_index)
lesson_items (id, lesson_id, gloss_id → glossary, order_index)
user_progress (id, user_id, gloss_id, learned, learned_at)

-- Quiz
quizzes (id, lesson_id, question_type, question, correct_answer)

-- Admin
admins (id, name, email, password_hash, role, created_by)

-- SOS
sos_logs (id, user_id, latitude, longitude, triggered_at, sms_sent)

-- Thông báo
notifications (id, user_id, type, title, body, read, created_at)
```

---

## Ước Tính Latency

| Bước | Thời gian ước tính | Ghi chú |
|---|---|---|
| MediaPipe (client) | ~30ms/frame | Real-time |
| Gửi landmarks → server | ~50-100ms | WebSocket, ~4KB/frame |
| LSTM inference | ~50-100ms | GPU, batch 1 |
| ViT5 inference | ~200-500ms | GPU, sequence length phụ thuộc |
| Edge-TTS | ~200-500ms | API call, phụ thuộc network |
| **Tổng Nhánh 1** | **~500ms - 1.2s** | Chấp nhận được |
| PhoWhisper (2s chunk) | ~300-500ms | GPU |
| ViT5 Việt→Gloss | ~200-500ms | GPU |
| Mapping + gửi về client | ~50ms | Lookup table |
| Three.js render | ~16ms/frame | 60fps |
| **Tổng Nhánh 2** | **~600ms - 1.1s** | Chấp nhận được |

---

## Yêu Cầu VPS Tối Thiểu

| Tài nguyên | Đề xuất |
|---|---|
| GPU | NVIDIA T4 (16GB VRAM) hoặc RTX 3060 (12GB) |
| RAM | 16GB tối thiểu |
| CPU | 4 cores |
| Storage | 100GB SSD |
| OS | Ubuntu 22.04 |
| Providers | Vast.ai, RunPod (GPU rẻ), hoặc VPS GPU của FPT/Viettel |

---

## Tổng Kết Thứ Tự Phát Triển (Đề xuất)

| Phase | Nội dung | Mục tiêu |
|---|---|---|
| **Phase 1** | LSTM training + Sign recognition (isolated) | Nhận diện 1 ký hiệu → 1 gloss |
| **Phase 2** | ViT5 fine-tune Gloss↔Việt + Edge-TTS | Gloss → câu Việt → audio |
| **Phase 3** | PhoWhisper + ViT5 reverse | Speech → text → gloss |
| **Phase 4** | 3D Avatar (Three.js + V-tuber style) | Render ký hiệu trên avatar |
| **Phase 5** | Web app (React) + API (FastAPI) | Giao diện cơ bản |
| **Phase 6** | Video Call (WebRTC) | Giao tiếp từ xa |
| **Phase 7** | Mobile (React Native) | App di động |
| **Phase 8** | Từ điển, Học, SOS, Admin, Notifications | Chức năng phụ |
