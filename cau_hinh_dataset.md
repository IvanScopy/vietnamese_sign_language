1️⃣ Nguồn trích xuất đặc trưng

Sử dụng MediaPipe Holistic

Trích xuất 67 landmark mỗi frame, gồm:

25 pose landmark (thân trên): đầu, vai, tay, hông

21 landmark bàn tay trái

21 landmark bàn tay phải

Không sử dụng landmark chân
→ Mục đích: tập trung chuyển động chi trên và giảm độ phức tạp dữ liệu

2️⃣ Tiền xử lý dữ liệu video

Mỗi video được sinh ra 40 sequence

Mỗi sequence:

Chọn ngẫu nhiên 1–3 phép tăng cường

Từ tổng cộng 5 kỹ thuật augmentation

Các phép tăng cường:

Scaling

Rotation

Translation

Temporal Stretching

Inter-hand Distance Adjustment

3️⃣ Chuẩn hóa độ dài chuỗi

Tất cả sequence được nội suy về 60 frame

Phương pháp nội suy: Cubic interpolation

4️⃣ Tóm tắt cấu trúc dữ liệu đầu vào

Mỗi sample sau xử lý có dạng:

60 frame

67 landmark / frame

Nếu mỗi landmark gồm (x, y, z) →
Kích thước đặc trưng = 60 × 67 × 3