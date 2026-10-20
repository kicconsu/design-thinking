import 'package:get/get.dart';

import 'package:imker/core/roble/session_user.dart';
import 'package:imker/core/utils/error_message.dart';
import 'package:imker/features/trust/domain/models/trust_metrics.dart';
import 'package:imker/features/trust/domain/repositories/i_trust_repository.dart';
import 'package:imker/features/trust/domain/trust_failure.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/profile_failure.dart';
import '../../domain/repositories/i_profile_repository.dart';

/// Perfil de la sesión activa. Una sola instancia durante toda la app
/// (`registerProfileData`): auth lo carga al entrar y lo vacía al salir.
class ProfileController extends GetxController {
  /// [trust] y [currentUserId] sustituyen al repositorio registrado y a la
  /// sesión real: solo para pruebas.
  ProfileController(
    this._repository, {
    ITrustRepository? trust,
    String Function()? currentUserId,
  }) : _trustOverride = trust,
       _userIdOverride = currentUserId;

  final IProfileRepository _repository;
  final ITrustRepository? _trustOverride;
  final String Function()? _userIdOverride;

  final Rxn<UserProfile> _profile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  /// Mis indicadores de confianza. Nulos mientras no se hayan calculado o si el
  /// último intento falló: nunca se rellenan con ceros ([trustError] explica).
  final Rxn<TrustMetrics> trust = Rxn<TrustMetrics>();
  final RxBool isLoadingTrust = false.obs;
  final RxnString trustError = RxnString();

  /// Cambia al vaciar el controller. Una carga o un guardado que empezó con
  /// otra sesión no debe escribir el perfil de esa persona en la que entra.
  int _epoch = 0;

  UserProfile? get profile => _profile.value;

  /// El perfil con mis indicadores de confianza ya puestos (si se calcularon).
  UserProfile? get profileWithTrust {
    final base = _profile.value;
    final metrics = trust.value;
    if (base == null || metrics == null) return base;
    return base.copyWith(
      hasTrustHistory: metrics.hasHistory,
      commitmentScore: metrics.commitment,
      onTimeScore: metrics.onTime,
      fulfillmentScore: metrics.fulfillment,
      completedProjectsScore: metrics.completedProjects,
    );
  }

  /// Olvida el perfil de la sesión que se va.
  void clear() {
    _epoch++;
    _profile.value = null;
    error.value = null;
    isLoading.value = false;
    isSaving.value = false;
    trust.value = null;
    trustError.value = null;
    isLoadingTrust.value = false;
  }

  /// Calcula mis indicadores de confianza. Si falla, no deja números:
  /// [trustError] dice por qué y la pantalla ofrece reintentar.
  Future<void> loadTrust() async {
    final repository =
        _trustOverride ??
        (Get.isRegistered<ITrustRepository>()
            ? Get.find<ITrustRepository>()
            : null);
    final userId = (_userIdOverride ?? sessionUserId)();
    if (repository == null || userId.isEmpty) return;

    final epoch = _epoch;
    isLoadingTrust.value = true;
    trustError.value = null;
    try {
      final metrics = await repository.getTrustMetricsOf(userId);
      if (epoch != _epoch) return;
      trust.value = metrics;
    } on TrustFailure catch (e) {
      if (epoch != _epoch) return;
      trust.value = null;
      trustError.value = e.message;
    } catch (e) {
      if (epoch != _epoch) return;
      trust.value = null;
      trustError.value = errorMessage(
        e,
        fallback: 'No pudimos calcular los indicadores.',
      );
    } finally {
      if (epoch == _epoch) isLoadingTrust.value = false;
    }
  }

  Future<void> loadProfile() async {
    final epoch = _epoch;
    try {
      isLoading.value = true;
      error.value = null;
      final loaded = await _repository.getMyProfile();
      if (epoch != _epoch) return;
      _profile.value = loaded;
    } on ProfileFailure catch (e) {
      if (epoch == _epoch) error.value = e.message;
    } catch (e) {
      if (epoch == _epoch) {
        error.value = errorMessage(
          e,
          fallback: 'Ocurrió un error inesperado al cargar tu perfil.',
        );
      }
    } finally {
      if (epoch == _epoch) isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    required String program,
    required String institution,
    required String bio,
    required List<String> skills,
  }) async {
    final epoch = _epoch;
    try {
      isSaving.value = true;
      error.value = null;
      final saved = await _repository.updateMyProfile(
        program: program,
        institution: institution,
        bio: bio,
        skills: skills,
      );
      if (epoch != _epoch) return false;
      _profile.value = saved;
      return true;
    } on ProfileFailure catch (e) {
      if (epoch == _epoch) error.value = e.message;
      return false;
    } catch (e) {
      if (epoch == _epoch) {
        error.value = errorMessage(e, fallback: 'No se pudo actualizar tu perfil.');
      }
      return false;
    } finally {
      if (epoch == _epoch) isSaving.value = false;
    }
  }
}
