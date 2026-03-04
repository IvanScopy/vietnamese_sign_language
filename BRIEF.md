# 📋 Phân Tích Chức Năng - Ứng Dụng Ngôn Ngữ Ký Hiệu Việt Nam

## Tổng Quan

Ứng dụng **giao tiếp 2 chiều** giữa người khiếm thính và người bình thường, hỗ trợ trên **Web & Mobile**. Sử dụng **Ngôn ngữ Ký hiệu Việt Nam (VSL)**, hỗ trợ tiếng Việt.

### Hai tác nhân chính

| Tác nhân | Vai trò |
|---|---|
| **Người khiếm thính** | Thực hiện ký hiệu → hệ thống chuyển thành âm thanh + text |
| **Người bình thường** | Nói bằng giọng nói → hệ thống chuyển thành text + Avatar 3D thực hiện ký hiệu |

### Ngữ cảnh sử dụng chính
- **Bệnh viện**: Bệnh nhân khiếm thính giao tiếp với bác sĩ/nhân viên y tế
- **Trường học**: Học sinh khiếm thính giao tiếp với giáo viên/bạn bè; Học ngôn ngữ ký hiệu

---

## Luồng Giao Tiếp Chính

### Luồng 1: Người khiếm thính → Người bình thường

```
Người khiếm thính thực hiện ký hiệu trước camera
    → AI nhận diện ký hiệu (VSL)
    → Chuyển thành văn bản tiếng Việt
    → Hiển thị text trên màn hình
    → Đồng thời phát âm thanh giọng nói tự nhiên (TTS)
    → Người bình thường nghe + đọc
```

### Luồng 2: Người bình thường → Người khiếm thính

```
Người bình thường nói bằng giọng nói
    → AI nhận diện giọng nói (Speech-to-Text)
    → Chuyển thành văn bản tiếng Việt
    → Hiển thị text (subtitle) trên màn hình
    → Avatar 3D thực hiện cử chỉ ký hiệu tương ứng
    → Người khiếm thính xem text + avatar 3D
```

---

## Các Chế Độ Giao Tiếp

### 1. Chế độ Real-time (Mặt đối mặt) — 1 thiết bị

Hai người ngồi cạnh nhau, dùng chung **1 thiết bị**.

> [!IMPORTANT]
> **Đề xuất giao diện**: Sử dụng chế độ **"chia đôi màn hình xoay 180°"** (giống Google Translate conversation mode). Mỗi bên nhìn 1 nửa màn hình, nội dung xoay ngược để đọc thuận. Có nút chuyển lượt nói/ký hiệu rõ ràng. Thay phiên luồng input: camera (ký hiệu) ↔ microphone (giọng nói).

### 2. Chế độ Video Call — mỗi người 1 thiết bị

Cả 2 bên đều sử dụng app. Gọi video **trong app** (không qua nền tảng bên thứ 3).

- **Phía người khiếm thính**: Xem video đối phương + text subtitle + Avatar 3D ký hiệu
- **Phía người bình thường**: Xem video đối phương + nghe âm thanh TTS + đọc text

---

## Modules Chức Năng

### Module 1: Đăng ký & Quản lý Tài khoản

| Chức năng | Mô tả |
|---|---|
| Đăng ký | Tên, loại người dùng (khiếm thính / bình thường), tuổi, số điện thoại |
| Đăng nhập / Đăng xuất | Xác thực cơ bản |
| Chỉnh sửa hồ sơ | Cập nhật thông tin cá nhân |
| Liên kết người thân | Người khiếm thính khai báo SĐT người thân (bố mẹ) để nhận SMS khi SOS |

---

### Module 2: Nhận diện Ngôn ngữ Ký hiệu (VSL → Text → Audio)

| Chức năng | Mô tả |
|---|---|
| Nhận diện ký hiệu qua camera | AI xử lý video real-time, nhận diện cử chỉ VSL |
| Chuyển thành text | Hiển thị kết quả nhận diện dạng văn bản tiếng Việt |
| Text-to-Speech | Phát âm thanh giọng nói tự nhiên tiếng Việt |
| Độ chính xác | Phụ thuộc vào dữ liệu training (bao gồm cả biểu cảm khuôn mặt nếu data có) |

---

### Module 3: Nhận diện Giọng nói (Audio → Text → Avatar 3D)

| Chức năng | Mô tả |
|---|---|
| Speech-to-Text | Nhận diện giọng nói tiếng Việt, chuyển thành text |
| Hiển thị subtitle | Text hiện trên màn hình cho người khiếm thính đọc |
| Avatar 3D | Avatar (nam hoặc nữ) thực hiện cử chỉ ký hiệu tương ứng với nội dung text |

**Avatar 3D**:
- 2 model: **Nam** và **Nữ**
- Thực hiện ký hiệu tương ứng với nội dung nhận diện được
- Mức độ chi tiết (tay, khuôn mặt, cơ thể) phụ thuộc vào dữ liệu training

---

### Module 4: Video Call

| Chức năng | Mô tả |
|---|---|
| Gọi video 1-1 | Gọi video trong app, cả 2 bên dùng app |
| Nhận diện ký hiệu trong cuộc gọi | Real-time, bên khiếm thính ra ký hiệu → bên kia nghe + đọc |
| Avatar 3D trong cuộc gọi | Bên bình thường nói → bên khiếm thính xem avatar + text |
| Thông báo cuộc gọi đến | Push notification khi có người gọi |

---

### Module 5: Lịch sử Hội thoại

| Chức năng | Mô tả |
|---|---|
| Lưu lịch sử | Lưu dạng **text** (không lưu video/audio) |
| Xem lại | Xem lịch sử theo thời gian, theo cuộc hội thoại |
| Tìm kiếm | Tìm kiếm nội dung trong lịch sử |
| Chia sẻ | Chia sẻ cuộc hội thoại cho người khác (ví dụ: gửi bác sĩ xem lại) |

---

### Module 6: Từ điển Ngôn ngữ Ký hiệu

| Chức năng | Mô tả |
|---|---|
| Tra cứu Text → Ký hiệu | Nhập từ/cụm từ → xem video/animation cử chỉ tương ứng |
| Tra cứu Ký hiệu → Text | Thực hiện ký hiệu trước camera → app nhận diện và hiển thị nghĩa |
| Phân loại theo chủ đề | Chào hỏi, y tế, trường học, gia đình, cảm xúc... |
| Đánh dấu đã học / chưa học | Theo dõi tiến trình cơ bản |

---

### Module 7: Học Ngôn ngữ Ký hiệu

| Chức năng | Mô tả |
|---|---|
| Bài học theo chủ đề | Học ký hiệu theo nhóm chủ đề (chào hỏi, số đếm, y tế...) |
| Quiz / Trắc nghiệm | Kiểm tra kiến thức đã học |
| Luyện tập qua camera | Người dùng làm ký hiệu → app nhận diện → chấm đúng/sai |
| Theo dõi tiến trình | Đánh dấu đã học / chưa học cho mỗi ký hiệu |

---

### Module 8: SOS — Khẩn cấp

| Chức năng | Mô tả |
|---|---|
| Nút SOS | Nút bấm nổi bật, dễ tiếp cận trên màn hình chính |
| Gửi SMS | Gửi tin nhắn SMS đến SĐT người thân đã khai báo |
| Gửi đến dịch vụ khẩn cấp | Liên hệ dịch vụ cấp cứu (tùy cấu hình) |
| Đính kèm vị trí | Gửi kèm vị trí GPS hiện tại |

---

### Module 9: Thông báo (Notifications)

| Loại thông báo | Mô tả |
|---|---|
| Cuộc gọi video đến | Push notification khi có người gọi |
| Tin nhắn | Thông báo tin nhắn mới (nếu có chat text) |
| Nhắc nhở học | Nhắc nhở người dùng học ký hiệu định kỳ |
| Thông báo từ Admin | Admin gửi thông báo đến người dùng |
| SOS | Thông báo đến người thân khi kích hoạt SOS |

> [!NOTE]
> Tất cả thông báo cho người khiếm thính cần dạng **visual** (rung, đèn flash, animation) thay vì âm thanh.

---

### Module 10: Trang Quản trị (Admin Panel) — Chỉ Web

| Chức năng | Mô tả |
|---|---|
| **Quản lý người dùng** | Xem danh sách, khóa, xóa tài khoản |
| **Quản lý từ điển** | Thêm / sửa / xóa ký hiệu trong từ điển |
| **Quản lý bài học** | Thêm / sửa / xóa bài học, chủ đề, quiz |
| **Thống kê** | Số người dùng, lượng sử dụng, ký hiệu phổ biến |
| **Quản lý SOS** | Xem lịch sử khẩn cấp |
| **Gửi thông báo** | Gửi thông báo đến người dùng |
| **Phân quyền Admin** | Nhiều admin, phân quyền khác nhau, 1 Super Admin tối cao |

---

## Nền tảng

| Nền tảng | Chức năng |
|---|---|
| **Mobile App** | Đầy đủ chức năng (giao tiếp, video call, từ điển, học, SOS...) |
| **Web App** | Đầy đủ chức năng như mobile + Trang quản trị Admin |
| **Camera** | Cả webcam (web) và camera điện thoại (mobile) đều hỗ trợ nhận diện |

---

## Tổng Kết Use Cases Chính

```
┌─────────────────────────────────────────────────────────┐
│                    USE CASES CHÍNH                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  👤 Người dùng (Khiếm thính + Bình thường)              │
│  ├── Đăng ký / Đăng nhập                               │
│  ├── Giao tiếp Real-time (1 thiết bị, mặt đối mặt)     │
│  ├── Video Call 1-1                                     │
│  ├── Tra cứu Từ điển Ký hiệu                           │
│  ├── Học Ngôn ngữ Ký hiệu                              │
│  ├── Xem Lịch sử Hội thoại                             │
│  ├── SOS Khẩn cấp                                      │
│  └── Liên kết Người thân                                │
│                                                         │
│  🔧 Admin                                               │
│  ├── Quản lý Người dùng                                │
│  ├── Quản lý Từ điển                                    │
│  ├── Quản lý Bài học                                    │
│  ├── Thống kê                                           │
│  ├── Quản lý SOS                                        │
│  ├── Gửi Thông báo                                     │
│  └── Phân quyền Admin                                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Các Tình Huống Sử Dụng Điển Hình

### 💬 Tình huống 1: Giao tiếp hàng ngày
> Người khiếm thính gặp người bình thường (ở nhà, ngoài đường, quán cà phê...) → mở app trên 1 thiết bị → đặt giữa 2 người (chia đôi màn hình) → người khiếm thính ra ký hiệu → app phát âm thanh + text cho người bình thường → người bình thường nói lại → app hiện text + avatar 3D cho người khiếm thính.

### 🏥 Tình huống 2: Bệnh viện
> Bệnh nhân khiếm thính đến khám → mở app → ra ký hiệu mô tả triệu chứng → app phát âm thanh + hiển thị text cho bác sĩ → bác sĩ nói lại → app hiện text + avatar 3D cho bệnh nhân hiểu.

### 🏫 Tình huống 3: Trường học (hòa nhập)
> Học sinh khiếm thính muốn phát biểu → mở app → ra ký hiệu → app phát âm thanh cho cả lớp → giáo viên/bạn bè trả lời bằng giọng nói → app hiện text + avatar 3D cho học sinh khiếm thính. Dùng 1 thiết bị.

### 🏫 Tình huống 4: Trường học (học ký hiệu)
> Học sinh/giáo viên muốn học ngôn ngữ ký hiệu → vào mục Học → chọn chủ đề → xem video hướng dẫn → luyện tập qua camera → app chấm đúng/sai → làm quiz.

### 📞 Tình huống 5: Video Call
> Người khiếm thính gọi video cho người thân bình thường → ra ký hiệu → người thân nghe âm thanh + đọc text → người thân nói → người khiếm thính xem text + avatar 3D.

### 🆘 Tình huống 6: Khẩn cấp
> Người khiếm thính gặp nguy hiểm → bấm nút SOS → app gửi SMS kèm vị trí GPS đến người thân đã khai báo.
