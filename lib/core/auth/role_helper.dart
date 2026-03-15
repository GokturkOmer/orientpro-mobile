class RoleHelper {
  // ===== TEMEL ROL KONTROLLERI =====

  /// Admin: sadece 'admin' rolu
  static bool isAdmin(String? role) => role == 'admin';

  /// Pro erisim: admin + tum teknik ekip
  static const _proRoles = {
    'admin', 'teknik_mudur',
    'elektrik_sefi', 'mekanik_sefi', 'tesisat_sefi',
    'elektrikci', 'mekanikci', 'tesisatci', 'teknik_staff',
  };
  static bool canAccessPro(String? role) => _proRoles.contains(role);

  /// Supervisor: mudur + sef roller (ekip takibi gorebilir)
  static const _supervisorRoles = {
    'admin', 'teknik_mudur',
    'resepsiyon_mudur', 'hk_mudur', 'guvenlik_mudur', 'mutfak_mudur',
    'fb_mudur', 'spa_mudur',
    'elektrik_sefi', 'mekanik_sefi', 'tesisat_sefi',
  };
  static bool isSupervisor(String? role) => _supervisorRoles.contains(role);

  /// Icerik duzenleme: admin + mudur + sef roller
  static const _contentEditorRoles = {
    'admin', 'teknik_mudur',
    'resepsiyon_mudur', 'hk_mudur', 'guvenlik_mudur', 'mutfak_mudur',
    'fb_mudur', 'spa_mudur',
    'elektrik_sefi', 'mekanik_sefi', 'tesisat_sefi',
  };
  static bool canEditContent(String? role) => _contentEditorRoles.contains(role);

  // ===== DEPARTMAN FILTRELEME =====

  /// Kullanicinin gorebilecegi departman code'lari.
  /// null = tum departmanlar (admin).
  /// GEN her zaman dahil.
  static const _roleDeptMap = <String, Set<String>>{
    'teknik_mudur':     {'teknik', 'GEN'},
    'resepsiyon_mudur': {'on_buro', 'GEN'},
    'hk_mudur':         {'hk', 'GEN'},
    'guvenlik_mudur':   {'guvenlik', 'GEN'},
    'mutfak_mudur':     {'mutfak', 'GEN'},
    'fb_mudur':         {'fb', 'GEN'},
    'spa_mudur':        {'spa', 'GEN'},
    'elektrik_sefi':    {'teknik', 'GEN'},
    'mekanik_sefi':     {'teknik', 'GEN'},
    'tesisat_sefi':     {'teknik', 'GEN'},
    'elektrikci':       {'teknik', 'GEN'},
    'mekanikci':        {'teknik', 'GEN'},
    'tesisatci':        {'teknik', 'GEN'},
    'teknik_staff':     {'teknik', 'GEN'},
    'hk_staff':         {'hk', 'GEN'},
    'resepsiyon_staff': {'on_buro', 'GEN'},
    'guvenlik_staff':   {'guvenlik', 'GEN'},
    'mutfak_staff':     {'mutfak', 'GEN'},
    'fb_staff':         {'fb', 'GEN'},
    'spa_staff':        {'spa', 'GEN'},
  };

  static Set<String>? visibleDepartments(String? role, String? userDept) {
    if (role == 'admin') return null;
    final mapped = _roleDeptMap[role];
    if (mapped != null) return mapped;
    return {if (userDept != null) userDept, 'GEN'};
  }

  // ===== TEKNIK ALT-DAL TAG FILTRELEME =====

  /// Teknik dept icerisinde gorulebilir tag'ler.
  /// null = tum tag'ler (teknik_mudur / admin).
  /// Bos set = teknik dept'e erismez.
  /// Tag'ler: 'elektrik', 'mekanik', 'tesisat', 'genel'
  /// Tag'siz route (null/[]) = 'genel' gibi degerlendirilir.
  static const _teknikTagMap = <String, Set<String>?>{
    'teknik_mudur':  null,
    'elektrik_sefi': {'elektrik', 'genel'},
    'mekanik_sefi':  {'mekanik', 'genel'},
    'tesisat_sefi':  {'tesisat', 'genel'},
    'elektrikci':    {'elektrik', 'genel'},
    'mekanikci':     {'mekanik', 'genel'},
    'tesisatci':     {'tesisat', 'genel'},
    'teknik_staff':  {'genel'},
  };

  static Set<String>? visibleTeknikTags(String? role) {
    if (role == 'admin') return null;
    if (_teknikTagMap.containsKey(role)) return _teknikTagMap[role];
    return const {};
  }

  /// Bir teknik route'un tag'lerinin kullanici tarafindan gorunup gorunmedigini kontrol eder.
  /// routeTags: route'un tags JSONB'den gelen listesi.
  static bool canSeeTeknikRoute(String? role, List<dynamic>? routeTags) {
    final allowed = visibleTeknikTags(role);
    if (allowed == null) return true; // tum tag'ler
    if (allowed.isEmpty) return false; // teknik degil
    if (routeTags == null || routeTags.isEmpty) return allowed.contains('genel');
    return routeTags.any((t) => allowed.contains(t.toString()));
  }

  // ===== ICERIK DUZENLEME DEPARTMAN/TAG =====

  /// Duzenlenebilir departmanlar. null = hepsi + GEN (admin).
  /// Bos set = duzenleme yok (staff).
  static Set<String>? editableDepartments(String? role) {
    if (role == 'admin') return null;
    const map = <String, Set<String>>{
      'teknik_mudur':     {'teknik'},
      'resepsiyon_mudur': {'on_buro'},
      'hk_mudur':         {'hk'},
      'guvenlik_mudur':   {'guvenlik'},
      'mutfak_mudur':     {'mutfak'},
      'fb_mudur':         {'fb'},
      'spa_mudur':        {'spa'},
      'elektrik_sefi':    {'teknik'},
      'mekanik_sefi':     {'teknik'},
      'tesisat_sefi':     {'teknik'},
    };
    return map[role] ?? const {};
  }

  /// Duzenlenebilir teknik tag'ler. null = hepsi (teknik_mudur / admin).
  static Set<String>? editableTeknikTags(String? role) {
    if (role == 'admin') return null;
    const map = <String, Set<String>?>{
      'teknik_mudur':  null,
      'elektrik_sefi': {'elektrik'},
      'mekanik_sefi':  {'mekanik'},
      'tesisat_sefi':  {'tesisat'},
    };
    return map.containsKey(role) ? map[role] : const {};
  }
}
