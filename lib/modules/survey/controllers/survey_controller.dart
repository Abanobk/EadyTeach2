import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/survey_models.dart';

/// المتحكم الرئيسي لسير عمل Smart Survey
class SurveyController extends ChangeNotifier {
  SurveyController() {
    _createNewProject();
  }

  late SurveyProject _project;

  SurveyProject get project => _project;

  List<SurveyFloor> get floors => _project.floors;

  /// إنشاء مشروع جديد مبدئي
  void _createNewProject() {
    _project = SurveyProject(
      id: _randomId(),
      name: 'مشروع بدون اسم',
      type: ProjectType.apartment,
      createdAt: DateTime.now(),
      floors: [],
    );
  }

  void setProjectMeta({
    String? name,
    ProjectType? type,
    String? customerName,
    String? customerEmail,
    int? customerId,
    String? notes,
    BusType? busType,
    SwitchSystem? switchSystem,
  }) {
    _project = SurveyProject(
      id: _project.id,
      name: name ?? _project.name,
      type: type ?? _project.type,
      createdAt: _project.createdAt,
      busType: busType ?? _project.busType,
      switchSystem: switchSystem ?? _project.switchSystem,
      customerName: customerName ?? _project.customerName,
      customerEmail: customerEmail ?? _project.customerEmail,
      customerId: customerId ?? _project.customerId,
      notes: notes ?? _project.notes,
      floors: _project.floors,
    );
    notifyListeners();
  }

  void addFloor(String name) {
    final index = _project.floors.length;
    _project.floors.add(
      SurveyFloor(
        id: _randomId(),
        name: name.isEmpty ? 'دور ${index + 1}' : name,
        index: index,
        rooms: [],
      ),
    );
    notifyListeners();
  }

  void removeFloor(SurveyFloor floor) {
    _project.floors.removeWhere((f) => f.id == floor.id);
    notifyListeners();
  }

  void addRoom({
    required SurveyFloor floor,
    required String name,
    required RoomType type,
    double? area,
    bool hasLighting = true,
    bool hasCurtain = false,
    CurtainKind? curtainKind,
    CurtainShape? curtainShape,
    CurtainDirection? curtainDirection,
    bool hasAcIr = false,
    bool hasTvIr = false,
    int magicBoxesCount = 0,
    int linesPerBox = 0,
    int magicLinesManual = 0,
    double? curtainLengthCm,
    double? curtainLengthApproxM,
    int switches1Line = 0,
    int switches2Line = 0,
    int switches3Line = 0,
    int switches4Line = 0,
    int acUnits = 0,
    int tvUnits = 0,
    int motionSensors = 0,
    int waterLeakSensors = 0,
    int gasSensors = 0,
    int temperatureSensors = 0,
    int smartValves = 0,
    int curtainSwitch1Ch = 0,
    int curtainSwitch2Ch = 0,
    String? notes,
  }) {
    final room = SurveyRoom(
      id: _randomId(),
      name: name.isEmpty ? _autoRoomName(floor, type) : name,
      type: type,
      floorIndex: floor.index,
      area: area,
      hasLighting: hasLighting,
      hasCurtain: hasCurtain,
      curtainKind: curtainKind,
      curtainShape: curtainShape,
      curtainDirection: curtainDirection,
      hasAcIr: hasAcIr,
      hasTvIr: hasTvIr,
      magicBoxesCount: magicBoxesCount,
      linesPerBox: linesPerBox,
      magicLinesManual: magicLinesManual,
      curtainLengthCm: curtainLengthCm,
      curtainLengthApproxM: curtainLengthApproxM,
      switches1Line: switches1Line,
      switches2Line: switches2Line,
      switches3Line: switches3Line,
      switches4Line: switches4Line,
      acUnits: acUnits,
      tvUnits: tvUnits,
      motionSensors: motionSensors,
      waterLeakSensors: waterLeakSensors,
      gasSensors: gasSensors,
      temperatureSensors: temperatureSensors,
      smartValves: smartValves,
      curtainSwitch1Ch: curtainSwitch1Ch,
      curtainSwitch2Ch: curtainSwitch2Ch,
      notes: notes,
    );
    floor.rooms.add(room);
    notifyListeners();
  }

  void removeRoom(SurveyFloor floor, SurveyRoom room) {
    floor.rooms.removeWhere((r) => r.id == room.id);
    notifyListeners();
  }

  /// حساب إجمالي الأجهزة المطلوبة بناءً على الغرف
  SurveyTotals calculateTotals() {
    int magicLines = 0;
    int curtainMotors = 0;
    int curtainPanels = 0;
    int irControllers = 0;
    int switches1 = 0;
    int switches2 = 0;
    int switches3 = 0;
    int switches4 = 0;
    int curtainSw1 = 0;
    int curtainSw2 = 0;
    int totalCurtains = 0;
    double curtainMeters = 0;
    double curtainCmActual = 0;
    int motionTotal = 0;
    int waterTotal = 0;
    int gasTotal = 0;
    int tempTotal = 0;
    int valveTotal = 0;

    for (final floor in _project.floors) {
      for (final room in floor.rooms) {
        if (room.hasLighting) {
          // أولوية الحساب:
          // 1) إذا كان هناك إجمالي خطوط يدوي (واجهة متعددة العلب)
          // 2) إذا حُدد عدد العلب × عدد الخطوط لكل علبة
          // 3) التقدير التلقائي من مساحة/نوع الغرفة
          if (room.magicLinesManual > 0) {
            magicLines += room.magicLinesManual;
          } else if (room.magicBoxesCount > 0 && room.linesPerBox > 0) {
            magicLines += room.magicBoxesCount * room.linesPerBox;
          } else {
            magicLines += _estimateLightingLines(room);
          }
        }
        if (room.hasCurtain && room.curtainKind != null) {
          final curtainsInRoom =
              room.curtainKind == CurtainKind.double ? 2 : 1;
          totalCurtains += curtainsInRoom;
          curtainMotors += curtainsInRoom;
          curtainPanels += curtainsInRoom;
          if (room.curtainLengthApproxM != null) {
            curtainMeters += room.curtainLengthApproxM! * curtainsInRoom;
          }
          if (room.curtainLengthCm != null) {
            curtainCmActual += room.curtainLengthCm! * curtainsInRoom;
          }
        }
        // وحدة IR واحدة تكفي للتكييف والتلفزيون معاً داخل نفس الغرفة
        if (room.hasAcIr || room.hasTvIr) {
          irControllers += 1;
        }
        if (room.hasLighting) {
          switches1 += room.switches1Line;
          switches2 += room.switches2Line;
          switches3 += room.switches3Line;
          switches4 += room.switches4Line;
        }
        curtainSw1 += room.curtainSwitch1Ch;
        curtainSw2 += room.curtainSwitch2Ch;
        motionTotal += room.motionSensors;
        waterTotal += room.waterLeakSensors;
        gasTotal += room.gasSensors;
        tempTotal += room.temperatureSensors;
        valveTotal += room.smartValves;
      }
    }

    return SurveyTotals(
      magicBoxLines: magicLines,
      curtainMotors: curtainMotors,
      curtainPanels: curtainPanels,
      irControllers: irControllers,
      switches1Line: switches1,
      switches2Line: switches2,
      switches3Line: switches3,
      switches4Line: switches4,
      totalCurtains: totalCurtains,
      curtainMeters: curtainMeters,
      curtainCmActual: curtainCmActual,
      motionSensors: motionTotal,
      waterLeakSensors: waterTotal,
      gasSensors: gasTotal,
      temperatureSensors: tempTotal,
      smartValves: valveTotal,
      curtainSwitch1Ch: curtainSw1,
      curtainSwitch2Ch: curtainSw2,
    );
  }

  /// تقدير عدد خطوط الإضاءة (Magic Box lines) للغرفة
  int _estimateLightingLines(SurveyRoom room) {
    if (room.area != null) {
      if (room.area! <= 12) return 1;
      if (room.area! <= 20) return 2;
      if (room.area! <= 30) return 3;
      return 4;
    }

    switch (room.type) {
      case RoomType.bathroom:
        return 1;
      case RoomType.kitchen:
      case RoomType.hall:
      case RoomType.kidsRoom:
        return 2;
      case RoomType.reception:
      case RoomType.livingRoom:
      case RoomType.masterBedroom:
        return 3;
      case RoomType.outdoor:
        return 2;
      case RoomType.bedroom:
        return 2;
    }
  }

  String _autoRoomName(SurveyFloor floor, RoomType type) {
    final sameTypeCount =
        floor.rooms.where((r) => r.type == type).length + 1;
    final prefix = _roomTypeToArabic(type);
    return '$prefix - طابق ${floor.index + 1} - $sameTypeCount';
  }

  String _roomTypeToArabic(RoomType type) {
    switch (type) {
      case RoomType.bedroom:
        return 'غرفة نوم';
      case RoomType.masterBedroom:
        return 'ماستر';
      case RoomType.kidsRoom:
        return 'أطفال';
      case RoomType.bathroom:
        return 'حمام';
      case RoomType.kitchen:
        return 'مطبخ';
      case RoomType.reception:
        return 'ريسيبشن';
      case RoomType.livingRoom:
        return 'معيشة';
      case RoomType.hall:
        return 'طرقة';
      case RoomType.outdoor:
        return 'خارجي';
    }
  }

  String _randomId() {
    final rnd = Random();
    final millis = DateTime.now().millisecondsSinceEpoch;
    return '${millis}_${rnd.nextInt(999999)}';
  }
}

