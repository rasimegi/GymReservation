class ReservationModel {
  final String id;          // rezervasyon ID'si (tarih_saat formatında)
  final String userId;      // rezervasyonu yapan kullanıcı ID'si
  final String date;        // rezervasyon tarihi (YYYY-MM-DD formatında)
  final String timeSlot;    // rezervasyon saati (örn: "09:00-10:00")
  final String status;      // rezervasyon durumu (onaylandı, iptal edildi, beklemede)
  final DateTime createdAt; // rezervasyon oluşturma zamanı
  final String? notes;      // ek notlar
  
  ReservationModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
    this.notes,
  });
  
  // Firestore'dan gelen verilerle ReservationModel oluştur
  factory ReservationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReservationModel(
      id: id,
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      status: data['status'] ?? 'beklemede',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      notes: data['notes'],
    );
  }
  
  // ReservationModel'i Firestore için Map'e dönüştür
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'timeSlot': timeSlot,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }
  
  // Güncellenmiş ReservationModel kopyası oluştur
  ReservationModel copyWith({
    String? userId,
    String? date,
    String? timeSlot,
    String? status,
    DateTime? createdAt,
    String? notes,
  }) {
    return ReservationModel(
      id: this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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