import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:state_extended/state_extended.dart';

class AddAnimalController extends StateXController {

  /// singleton
  factory AddAnimalController() {
    _this ??= AddAnimalController._();
    return _this!;
  }

  static AddAnimalController? _this;

  AddAnimalController._();

  bool loading = false;
  int activeStep = 0;
  late TextEditingController nameController;
  late TextEditingController typeController;
  late TextEditingController colorController;

  int age = 1;
  String ageType = "Year";
  String gender = "Male";
}