class ReservationModel {
  final String id; // rezervasyon ID'si (tarih_saat formatında)
  final String userId; // rezervasyonu yapan kullanıcı ID'si
  final String date; // rezervasyon tarihi (YYYY-MM-DD formatında)
  final String timeSlot; // rezervasyon saati (örn: "09:00-10:00")
  final String
  createdAt; // rezervasyon oluşturma zamanı (YYYY-MM-DD formatında)
  final String?
  reservationId; // benzersiz rezervasyon ID'si (res_timestamp_1 formatında)
  final bool isActive; // rezervasyonun aktif olup olmadığı
  final String? notes; // ek notlar

  ReservationModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.createdAt,
    this.reservationId,
    this.isActive = true,
    this.notes,
  });

  // Firestore'dan gelen verilerle ReservationModel oluştur
  factory ReservationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReservationModel(
      id: id,
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      createdAt: data['createdAt'] ?? '',
      reservationId: data['reservationId'],
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
    );
  }

  // ReservationModel'i Firestore için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'timeSlot': timeSlot,
      'createdAt': createdAt,
      'reservationId': reservationId,
      'isActive': isActive,
      'notes': notes,
    };
  }

  // Güncellenmiş ReservationModel kopyası oluştur
  ReservationModel copyWith({
    String? userId,
    String? date,
    String? timeSlot,
    String? createdAt,
    String? reservationId,
    bool? isActive,
    String? notes,
  }) {
    return ReservationModel(
      id: this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      createdAt: createdAt ?? this.createdAt,
      reservationId: reservationId ?? this.reservationId,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}

// Timestamp sınıfı için basit bir tanımlama (firebase_core paketinden)
class Timestamp {
  final int seconds;
  final int nanoseconds;

  Timestamp(this.seconds, this.nanoseconds);

  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  static Timestamp fromDate(DateTime date) {
    final int milliseconds = date.millisecondsSinceEpoch;
    final int seconds = milliseconds ~/ 1000;
    final int nanoseconds = (milliseconds % 1000) * 1000000;
    return Timestamp(seconds, nanoseconds);
  }
}
