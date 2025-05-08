import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Bildirim sistemini etkinleştirmek için gerekli paketler henüz yüklenmedi
    // Bu, bildirim sisteminin basitleştirilmiş bir sürümüdür
    debugPrint('Bildirim servisi başlatıldı (basitleştirilmiş mod)');
  }

  // Randevu için bildirim zamanlama
  Future<void> scheduleAppointmentNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    Map<String, dynamic> appointmentData,
  ) async {
    // Geçmiş tarih kontrolü
    final now = DateTime.now();
    final notificationTime = scheduledDate.subtract(const Duration(days: 1));

    if (notificationTime.isBefore(now)) {
      debugPrint('Bildirim zamanı geçmiş: $notificationTime');
      return;
    }

    debugPrint('Bildirim zamanlandı: $notificationTime');
    debugPrint('Bildirim başlık: $title');
    debugPrint('Bildirim içerik: $body');

    // Bu noktada, planlanmış bildirimi SharedPreferences'e kaydediyoruz
    try {
      final prefs = await SharedPreferences.getInstance();

      // Daha önce kaydedilmiş bildirimleri al
      final savedNotifications =
          prefs.getStringList('scheduled_notifications') ?? [];

      // Yeni bildirimi ekle
      final notificationData = {
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate.toIso8601String(),
        'appointmentData': appointmentData,
      };

      savedNotifications.add(jsonEncode(notificationData));

      // Güncellenmiş listeyi kaydet
      await prefs.setStringList('scheduled_notifications', savedNotifications);

      debugPrint('Bildirim başarıyla kaydedildi');
    } catch (e) {
      debugPrint('Bildirim kaydedilirken hata: $e');
    }
  }

  // Randevuları kontrol et ve bildirimleri planla
  Future<void> checkAndScheduleAppointments() async {
    debugPrint('Randevular kontrol ediliyor...');

    final prefs = await SharedPreferences.getInstance();
    final appointmentsJson = prefs.getStringList('appointments') ?? [];

    if (appointmentsJson.isEmpty) {
      debugPrint('Kayıtlı randevu bulunamadı.');
      return;
    }

    // Daha önce bildirim gönderilmiş randevuları takip et
    final notifiedAppointments =
        prefs.getStringList('notified_appointments') ?? [];

    // Her randevu için kontrol et
    int notificationId = 0;
    for (var appointmentJson in appointmentsJson) {
      try {
        final appointmentData =
            json.decode(appointmentJson) as Map<String, dynamic>;
        final appointmentId = appointmentData['id'].toString();

        // Bu randevu için daha önce bildirim gönderilmiş mi kontrol et
        if (notifiedAppointments.contains(appointmentId)) {
          continue;
        }

        // Randevu tarihini parse et
        final appointmentDateStr = appointmentData['date'].toString();
        final appointmentTimeStr = appointmentData['time'].toString();

        // Tarih formatını kontrol et ve parse et
        DateTime appointmentDateTime;
        try {
          final dateFormat = DateFormat('dd.MM.yyyy');
          final date = dateFormat.parse(appointmentDateStr);

          // Saat formatını kontrol et
          final timeParts = appointmentTimeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          appointmentDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );
        } catch (e) {
          debugPrint('Tarih parse edilemedi: $e');
          continue;
        }

        // Randevu bilgilerini hazırla
        final gymName = appointmentData['gymName'] ?? 'Spor Salonu';
        final serviceName = appointmentData['serviceName'] ?? 'Hizmet';

        // Bildirim başlığı ve içeriği
        final title = 'Yarın Randevunuz Var!';
        final body =
            '$gymName - $serviceName için $appointmentTimeStr saatinde randevunuz var.';

        // Bildirimi planla
        await scheduleAppointmentNotification(
          notificationId++,
          title,
          body,
          appointmentDateTime,
          appointmentData,
        );

        // Bildirimi gönderilen randevuları kaydet
        notifiedAppointments.add(appointmentId);
      } catch (e) {
        debugPrint('Randevu kontrol edilirken hata: $e');
      }
    }

    // Güncellenen bildirimleri kaydet
    await prefs.setStringList('notified_appointments', notifiedAppointments);
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    debugPrint('Tüm bildirimler iptal edildi (geçici)');
    // Gerçek bildirim sistemi olmadığından, sadece SharedPreferences'teki verileri temizliyoruz
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_notifications');
  }

  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    debugPrint('$id ID\'li bildirim iptal edildi (geçici)');
  }
}
