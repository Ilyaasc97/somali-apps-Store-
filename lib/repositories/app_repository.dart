import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/app_info.dart';

class AppRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box _cacheBox = Hive.box('apps_cache');

  // جلب قائمة التطبيقات من Firestore بشكل Stream مع تحديث الذاكرة المحلية
  Stream<List<AppInfo>> getAppsStream() {
    return _firestore.collection('apps').snapshots().map((snapshot) {
      final apps = snapshot.docs
          .map((doc) => AppInfo.fromJson(doc.data()))
          .toList();
      // تحديث التخزين المحلي
      _cacheBox.put('all_apps', apps.map((e) => e.toMap()).toList());
      return apps;
    });
  }

  // جلب قائمة التطبيقات (يحاول من الذاكرة المحلية أولاً لسرعة الاستجابة)
  Future<List<AppInfo>> getApps() async {
    // حاول الجلب من التخزين المحلي أولاً
    if (_cacheBox.containsKey('all_apps')) {
      final cachedData = _cacheBox.get('all_apps') as List;
      return cachedData
          .map((e) => AppInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    try {
      final querySnapshot = await _firestore.collection('apps').get();
      final apps = querySnapshot.docs
          .map((doc) => AppInfo.fromJson(doc.data()))
          .toList();

      // حفظ في التخزين المحلي
      _cacheBox.put('all_apps', apps.map((e) => e.toMap()).toList());

      return apps;
    } catch (e) {
      print('Error fetching apps: $e');
      return [];
    }
  }

  // جلب إحصائيات تطبيق معين (مثل عدد التحميلات) بشكل Stream
  Stream<DocumentSnapshot> getAppStats(String packageName) {
    // استبدال النقاط بـ "_" كما هو متبع في структуру البيانات الحالية
    String docId = packageName.replaceAll('.', '_');
    return _firestore.collection('apps').doc(docId).snapshots();
  }

  // زيادة عدد التحميلات
  Future<void> incrementDownloadCount(String packageName) async {
    String docId = packageName.replaceAll('.', '_');
    await _firestore.collection('apps').doc(docId).update({
      'downloadCount': FieldValue.increment(1),
    });
  }

  // تحديث تقييم التطبيق باستخدام Transaction لضمان دقة البيانات
  Future<void> updateAppRating(String packageName, double newRating) async {
    String docId = packageName.replaceAll('.', '_');
    final docRef = _firestore.collection('apps').doc(docId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        transaction.set(docRef, {
          'ratingSum': newRating,
          'ratingCount': 1,
          'rating': newRating,
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        double currentSum = (data['ratingSum'] ?? 0).toDouble();
        int currentCount = (data['ratingCount'] ?? 0);

        double nextSum = currentSum + newRating;
        int nextCount = currentCount + 1;
        double nextAverage = nextSum / nextCount;

        transaction.update(docRef, {
          'ratingSum': nextSum,
          'ratingCount': nextCount,
          'rating': nextAverage,
        });
      }
    });
  }
}
