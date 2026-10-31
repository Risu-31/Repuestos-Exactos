import 'package:flutter/foundation.dart';
import 'package:autoscan/core/errors/app_failure.dart';

import '../../domain/entities/workshop_invitation.dart';
import '../../domain/repositories/team_repository.dart';

class TeamController extends ChangeNotifier {
  TeamController(this._repository);
  final TeamRepository _repository;
  List<WorkshopInvitation> invitations = [];
  String? error;
  String? invitationUrl;
  bool busy = false;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      final items = await _repository.invitations();
      if (!_disposed) invitations = items;
    } on AppFailure catch (e) {
      if (!_disposed) error = e.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> invite(String email) async {
    if (busy) return;
    busy = true;
    error = null;
    invitationUrl = null;
    _notify();
    try {
      final link = await _repository.invite(email);
      if (!_disposed) {
        invitationUrl = link;
        invitations = await _repository.invitations();
      }
    } on AppFailure catch (e) {
      if (!_disposed) error = e.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> revoke(String id) async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      await _repository.revoke(id);
      if (!_disposed) {
        invitationUrl = null;
        invitations = await _repository.invitations();
      }
    } on AppFailure catch (e) {
      if (!_disposed) error = e.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
