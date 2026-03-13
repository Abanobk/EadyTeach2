import 'package:flutter/foundation.dart';

enum ProjectType { apartment, duplex, villa, office }

/// نوع نظام الاتصال الرئيسي للمشروع (Wifi أو Zigbee)
enum BusType { wifi, zigbee }

/// نوع نظام المفاتيح (سويتش عادي أو Mini Switch)
enum SwitchSystem { switchStandard, miniSwitch }

enum RoomType {
  bedroom,
  masterBedroom,
  kidsRoom,
  bathroom,
  kitchen,
  reception,
  livingRoom,
  hall,
  outdoor,
}

enum CurtainKind { single, double }

enum CurtainShape { straight, wave }

/// اتجاه فتح الستارة (يسار / منتصف / يمين)
enum CurtainDirection { left, center, right }

class SurveyProject {
  SurveyProject({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.busType = BusType.wifi,
    this.switchSystem = SwitchSystem.switchStandard,
    this.customerName,
    this.customerEmail,
    this.customerId,
    this.notes,
    List<SurveyFloor>? floors,
  }) : floors = floors ?? [];

  final String id;
  final String name;
  final ProjectType type;
  final DateTime createdAt;
  final BusType busType;
  final SwitchSystem switchSystem;
  final String? customerName;
   /// بريد العميل المستخدم للربط مع تطبيق العميل
  final String? customerEmail;
  /// معرّف العميل من قاعدة البيانات (إن وجد)
  final int? customerId;
  final String? notes;
  final List<SurveyFloor> floors;
}

class SurveyFloor {
  SurveyFloor({
    required this.id,
    required this.name,
    required this.index,
    List<SurveyRoom>? rooms,
  }) : rooms = rooms ?? [];

  final String id;
  final String name;
  final int index;
  final List<SurveyRoom> rooms;
}

class SurveyRoom {
  SurveyRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.floorIndex,
    this.area,
    this.hasLighting = true,
    this.hasCurtain = false,
    this.curtainKind,
    this.curtainShape,
    this.curtainDirection,
    this.hasAcIr = false,
    this.hasTvIr = false,
    this.acUnits = 0,
    this.tvUnits = 0,
    this.magicBoxesCount = 0,
    this.linesPerBox = 0,
    this.magicLinesManual = 0,
    this.curtainLengthCm,
    this.curtainLengthApproxM,
    this.switches1Line = 0,
    this.switches2Line = 0,
    this.switches3Line = 0,
    this.switches4Line = 0,
    this.motionSensors = 0,
    this.waterLeakSensors = 0,
    this.gasSensors = 0,
    this.temperatureSensors = 0,
    this.smartValves = 0,
    this.curtainSwitch1Ch = 0,
    this.curtainSwitch2Ch = 0,
    this.notes,
  });

  final String id;
  final String name;
  final RoomType type;
  final int floorIndex;
  final double? area;

  // Lighting / Magic Boxes
  final bool hasLighting;
  /// عدد علب الـ Magic Box في الغرفة (اختياري، 0 يعني يتم التقدير تلقائياً)
  final int magicBoxesCount;
  /// عدد الخطوط في كل علبة (من 1 إلى 4) عند استخدام نموذج بسيط (قد لا يُستخدم مع النموذج المتقدم)
  final int linesPerBox;
  /// إجمالي عدد الخطوط اليدوي لجميع علب Magic Box في الغرفة (يُستخدم مع واجهة العلب المتعددة)
  final int magicLinesManual;

  // Curtains
  final bool hasCurtain;
  final CurtainKind? curtainKind;
  final CurtainShape? curtainShape;
  final CurtainDirection? curtainDirection;
  /// طول الستارة بالسنتيمتر (اختياري)
  final double? curtainLengthCm;
  /// طول الستارة المستخدم في التسعير بالمتر بعد التقريب (0.5م / 1م)
  final double? curtainLengthApproxM;

  /// عدد مفاتيح 1 خط في الغرفة
  final int switches1Line;

  /// عدد مفاتيح 2 خط في الغرفة
  final int switches2Line;

  /// عدد مفاتيح 3 خطوط في الغرفة
  final int switches3Line;

  /// عدد مفاتيح 4 خطوط في الغرفة
  final int switches4Line;

  // IR control
  final bool hasAcIr;
  final bool hasTvIr;
  /// عدد وحدات التكييف في الغرفة
  final int acUnits;
  /// عدد وحدات التلفزيون في الغرفة
  final int tvUnits;

  /// عدد حساسات الحركة في الغرفة
  final int motionSensors;
  /// عدد حساسات تسريب المياه في الغرفة
  final int waterLeakSensors;
  /// عدد حساسات الغاز في الغرفة
  final int gasSensors;
  /// عدد حساسات الحرارة في الغرفة
  final int temperatureSensors;
  /// عدد المحابس الذكية (Smart Valve) في الغرفة
  final int smartValves;

  /// عدد مفاتيح ستارة 1 قناة (Curtain 1CH)
  final int curtainSwitch1Ch;

  /// عدد مفاتيح ستارة 2 قناة (Curtain 2CH)
  final int curtainSwitch2Ch;

  final String? notes;
}

@immutable
class SurveyTotals {
  const SurveyTotals({
    required this.magicBoxLines,
    required this.curtainMotors,
    required this.curtainPanels,
    required this.irControllers,
    required this.switches1Line,
    required this.switches2Line,
    required this.switches3Line,
    required this.switches4Line,
    required this.totalCurtains,
    required this.curtainMeters,
    required this.curtainCmActual,
    required this.motionSensors,
    required this.waterLeakSensors,
    required this.gasSensors,
    required this.temperatureSensors,
    required this.smartValves,
    required this.curtainSwitch1Ch,
    required this.curtainSwitch2Ch,
  });

  final int magicBoxLines;
  final int curtainMotors;
  final int curtainPanels;
  final int irControllers;
  final int switches1Line;
  final int switches2Line;
  final int switches3Line;
  final int switches4Line;
  final int totalCurtains;
  final double curtainMeters;
  final double curtainCmActual;
  final int motionSensors;
  final int waterLeakSensors;
  final int gasSensors;
  final int temperatureSensors;
  final int smartValves;
  final int curtainSwitch1Ch;
  final int curtainSwitch2Ch;
}

