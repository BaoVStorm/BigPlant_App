# BigPlant Project Overview

## Product intent
- BigPlant la app Flutter gom 2 huong gia tri:
  - E-commerce cho cay/chau/phu kien.
  - AI scan cay de nhan dien nhanh va hien thi thong tin cay.

## Source architecture (current)
- Entrypoint: `lib/main.dart` -> `lib/app.dart`.
- Core layer: `lib/core` (routing, network, constants, localization).
- Feature layer:
  - `lib/features/auth`
  - `lib/features/shop`
  - `lib/features/scan`

## Main user flow
1. Splash kiem tra token trong local storage.
2. Token hop le -> vao main shell; khong hop le -> auth flow.
3. Main shell giu 4 tab: Home, Scan, Cart, Settings.

## Scan architecture (latest)
- Scan tab da tach 2 luong ro rang:
  - Camera: ONNX local realtime (`camera` + `onnxruntime`).
  - Gallery: giu logic upload backend multipart nhu truoc.
- Realtime camera khi vao `Open result details` se:
  - Tam dung infer realtime.
  - Goi backend scan API 1 lan de lay thong tin chi tiet cho result body.
  - Back ve camera thi infer realtime duoc bat lai.
- File chinh:
  - `lib/features/shop/presentation/screens/scan_tab.dart`
  - `lib/features/scan/presentation/screens/camera_realtime_scan_screen.dart`
  - `lib/features/scan/domain/local_onnx_scan_service.dart`
  - `lib/features/scan/data/scan_api.dart`

## API boundary (current truth)
- App hien tai chi dung `ApiConstants.baseUrl`, khong con base scan rieng.
- Scan backend endpoint dang dung:
  - `POST api/plant_detect?topk=5&two_pass=true`
  - multipart field: `file`
  - auth header: `Bearer <token>` neu co.

## ML asset boundary
- ONNX assets da duoc chuan hoa trong:
  - `assets/ml/configs/`
  - `assets/ml/models/<model_id>/`
- Catalog + policy:
  - `assets/ml/configs/model_catalog.json`
  - `assets/ml/configs/runtime_policy.json`
- Hien co 4 model:
  - `organ_aware_switch_vit`
  - `efficientnetv2_segformer`
  - `efficientnetv2_mask2former`
  - `mobilenetv3large_segformer` (default realtime)

## Current status notes
- Localization `vi/en` dang duoc duy tri, scan da them key cho realtime screen.
- Scan UI da duoc doi theo Stitch flow moi:
  - `Scan Tab`
  - `Scanning Tab - Pending`
  - `Scanning Tab - Complete`
  - `Plant Detail Tab`
  - `Plant Detail Tab - Distribution`
  - `Plant Detail Tab - Distribution Map`
- Flutter boundary hien tai van giu nguyen logic:
  - `ScanTab` vao camera hoac gallery.
  - Camera realtime van infer local ONNX.
  - Sau capture moi mo `Plant Detail` qua CTA `Open Full Analysis`.
  - `Plant Detail` van co enrich du lieu bang backend API khi can.
- Shop UI da bat dau doi theo Stitch cho `Home Tab` va `Product Detail`.
- Vi source hien tai chua co API shop/catalog, Flutter dang dung local catalog bám schema DB:
  - `product_categories`
  - `products`
  - `product_variants`
  - `product_images`
  - linked plant snapshot qua `plant_id`
- Cart/checkout UI da duoc mo rong theo Stitch flow moi:
  - `Cart Tab`
  - `Order Summary Tab`
  - `Payment Success Tab`
- Hien tai flow checkout van la local UI flow:
  - cart state local
  - order summary local
  - payment success local
  - chua co payment gateway hay order-history API thuc te
- AI Chat UI da duoc tach thanh feature rieng trong `lib/features/chat`:
  - screen chat mock theo kieu load tu db
  - bubble user/AI tach rieng
  - bubble text va bubble image tach rieng
  - composer co draft attachment preview
- Hien tai AI Chat chua duoc wire vao `MainShellScreen` hay route chinh theo yeu cau.
- `flutter analyze` va `flutter test` pass sau khi them ONNX + camera.
- APK debug rat lon do bundle nhieu ONNX files (~600MB), can quan tri release strategy.
- ONNX realtime da chot yeu cau tensor float32; neu dua tensor double se fail voi loi `Unexpected input data type`.

## Operational caveats
- Tren Windows + Android build co the gap Kotlin incremental cache issue voi plugin `camera_android_camerax` (C: pub cache vs D: project root).
- Tren emulator de cai APK can du data partition; neu sat nguong se fail install du build thanh cong.
- `10.0.2.2` chi dung cho Android emulator. Khi test may that qua USB, can dung `adb reverse` + base URL `127.0.0.1` neu goi backend local.
