import 'dart:async';

import 'package:alifi/Utilities/theme_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Widgets/translated_text.dart';
import '../../../core/services/pet_reports_service.dart';
import 'unified_pet_card.dart';

/// Single list: lost + found pets, merged and sorted by [createdAt] (newest first).
class UnifiedLostFoundList extends StatefulWidget {
  const UnifiedLostFoundList({super.key});

  @override
  State<UnifiedLostFoundList> createState() => _UnifiedLostFoundListState();
}

class _UnifiedLostFoundListState extends State<UnifiedLostFoundList> {
  final List<Map<String, dynamic>> _lost = [];
  final List<Map<String, dynamic>> _found = [];
  bool _loadingLost = true;
  bool _loadingFound = true;
  StreamSubscription<List<Map<String, dynamic>>>? _lostSub;
  StreamSubscription<List<Map<String, dynamic>>>? _foundSub;

  @override
  void initState() {
    super.initState();
    _lostSub = PetReportsService.getLostPetsStream().listen((pets) {
      if (mounted) {
        setState(() {
          _lost
            ..clear()
            ..addAll(pets);
          _loadingLost = false;
        });
      }
    });
    _foundSub = PetReportsService.getFoundPetsStream().listen((pets) {
      if (mounted) {
        setState(() {
          _found
            ..clear()
            ..addAll(pets);
          _loadingFound = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _lostSub?.cancel();
    _foundSub?.cancel();
    super.dispose();
  }

  static DateTime _createdAt(Map<String, dynamic> pet) {
    final v = pet['createdAt'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<({Map<String, dynamic> pet, String reportType})> get _merged {
    final rows = <({Map<String, dynamic> pet, String reportType, DateTime t})>[];
    for (final p in _lost) {
      rows.add((pet: p, reportType: 'lost', t: _createdAt(p)));
    }
    for (final p in _found) {
      rows.add((pet: p, reportType: 'found', t: _createdAt(p)));
    }
    rows.sort((a, b) => b.t.compareTo(a.t));
    return [for (final r in rows) (pet: r.pet, reportType: r.reportType)];
  }

  bool get _isLoading => _loadingLost || _loadingFound;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _merged;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 64.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            TranslatedText(
              'lost_found.no_pets_combined',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final row = items[index];
        final pet = row.pet;
        return Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: UnifiedPetCard(
            color: index % 2 == 0
                ? ThemeClass.of(context).secondaryColor
                : ThemeClass.of(context).primaryColor,
            pet: pet,
            reportType: row.reportType,
          ),
        );
      },
    );
  }
}
