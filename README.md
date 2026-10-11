# Bài 4: Custom Network & Named Volume bằng Docker CLI

## 1. Mục tiêu

- Tạo Custom Bridge Network `app-net`.
- Tạo Named Volume `db-data`.
- Kết nối Backend và PostgreSQL thông qua hostname `db-server`.
- Kiểm chứng dữ liệu còn nguyên sau khi xóa và tạo lại container PostgreSQL.

## 2. Công nghệ

- Docker CLI
- Docker Bridge Network
- Docker DNS
- Docker Named Volume
- PostgreSQL 15 Alpine
- Node.js Alpine

## 3. Các thành phần

| Thành phần | Tên             | Chức năng                                               |
| ---------- | --------------- | ------------------------------------------------------- |
| Network    | `app-net`       | Kết nối các container nội bộ                            |
| Volume     | `db-data`       | Lưu dữ liệu PostgreSQL bền vững                         |
| Database   | `db-server`     | PostgreSQL 15 Alpine                                    |
| Backend    | `app-container` | Container minh họa cấu hình kết nối DB và kiểm tra mạng |

## 4. Cách thực hiện

Chạy script:

```bash
bash commands.sh
```

Script tạo network và volume, khởi chạy PostgreSQL, cấu hình biến môi trường cho Backend, kiểm tra DNS, thêm dữ liệu, xóa container DB và tạo lại container với cùng volume.

## 5. Kiểm tra

### Network

```bash
docker network ls
docker network inspect app-net
```

### Volume

```bash
docker volume ls
docker volume inspect db-data
```

### DNS và kết nối DB

```bash
docker exec app-container ping -c 2 db-server
docker exec app-container pg_isready -h db-server -p 5432 -U appuser -d appdb
```

### Data Persistence

```bash
docker exec db-server psql -U appuser -d appdb -c "SELECT * FROM persistence_test;"
```

Sau khi xóa và tạo lại container PostgreSQL bằng cùng Named Volume, bản ghi đã tạo vẫn tồn tại.

## 6. Kết quả

- Custom Bridge Network `app-net` được tạo thành công.
- Named Volume `db-data` được mount vào thư mục dữ liệu PostgreSQL.
- Backend phân giải hostname `db-server` thông qua DNS nội bộ của Docker.
- PostgreSQL sẵn sàng nhận kết nối từ Backend container.
- Dữ liệu vẫn còn sau khi xóa và tạo lại container DB.

## 7. Kết luận

Custom Bridge Network cho phép các container giao tiếp nội bộ bằng tên container. Named Volume lưu dữ liệu độc lập với vòng đời container, giúp dữ liệu PostgreSQL tồn tại sau khi container bị xóa và tạo lại.
