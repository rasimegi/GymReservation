# GymReservation
A mobile app for reserving gym slots, built with Flutter and Firebase.

## Randevu Bildirimleri

Uygulama, kullanıcıların randevularından 1 gün önce hatırlatma bildirimleri gösterir. Bildirimler, uygulama kapalı olsa bile çalışır.

### Kurulum

1. Gerekli paketleri ekleyin:
```yaml
# Sadece örnek, uygulamada bu kodu kullanmayın
dependencies:
  flutter_local_notifications: ^16.2.0
  timezone: ^0.9.2
  workmanager: ^0.5.2
  flutter_native_timezone: ^2.0.0
```

2. Paketleri yükleyin:
```bash
# Sadece örnek, terminalde çalıştırılacak komut
flutter pub get
```

3. Bildirim servisini kullanmak için:
<!-- 
```dart
// main.dart dosyasında
final notificationService = NotificationService();
await notificationService.initialize()
```
-->

Bildirim servisini main.dart dosyasında initialize edin.

### Randevu Bildirimi Zamanlama

Bir randevu oluşturulduğunda otomatik olarak bildirim zamanlanır:

<!-- 
```dart
// Örnek kullanım
final notificationService = NotificationService();
await notificationService.scheduleAppointmentNotification(
  1,  // Bildirim ID'si
  'Yarın Randevunuz Var!',  // Bildirim başlığı
  'Randevu bilgileri...',  // Bildirim içeriği
  DateTime.now().add(Duration(days: 1)),  // Randevu tarihi ve saati
  {'gymName': 'Spor Salonu', 'serviceName': 'PT Seansı'},  // Randevu verileri
);
```
-->

### Arka Planda Çalışma

Uygulama, workmanager paketi sayesinde arka planda periyodik olarak çalışır ve yaklaşan randevuları kontrol eder. Bu sayede kullanıcılar, randevularından 1 gün önce bildirim alır.