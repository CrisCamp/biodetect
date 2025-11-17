import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio centralizado para gestionar banners de anuncios
/// 
/// Este servicio maneja la creación, carga y dispose de banners de anuncios
/// de Google AdMob de manera centralizada para evitar duplicación de código.
class BannerAdService {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  VoidCallback? _onAdLoaded;
  Function(String)? _onAdFailedToLoad;
  
  // Sistema de notificación reactivo
  static final ValueNotifier<bool> _shouldShowAdsNotifier = ValueNotifier<bool>(true);
  static ValueNotifier<bool> get shouldShowAdsNotifier => _shouldShowAdsNotifier;

  // IDs de unidades de anuncios
  static const String _androidAdUnitId = 'ca-app-pub-2455614119782029/5903033792';
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  /// Verifica si se deben mostrar anuncios basándose en las preferencias del usuario
  /// 
  /// Verifica tanto SharedPreferences como Firestore para garantizar consistencia
  /// Retorna true si removeAds es false o no existe
  /// Retorna false si removeAds es true
  static Future<bool> shouldShowAds() async {
    try {
      bool removeAds = false;
      
      // Primero verificar SharedPreferences (más rápido)
      final prefs = await SharedPreferences.getInstance();
      removeAds = prefs.getBool('remove_ads') ?? false;
      
      // Si SharedPreferences dice que NO remover anuncios, verificar también Firestore
      // para asegurar consistencia (especialmente en el primer inicio después de compra)
      if (!removeAds) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            if (userDoc.exists) {
              final firestoreRemoveAds = userDoc.data()?['removeAds'] ?? false;
              
              // Si Firestore dice que SÍ remover anuncios pero SharedPreferences no está actualizado
              if (firestoreRemoveAds && !removeAds) {
                print('🔄 Sincronizando estado de anuncios: Firestore=true, SharedPreferences=false');
                // Actualizar SharedPreferences para que coincida con Firestore
                await prefs.setBool('remove_ads', true);
                removeAds = true;
              }
            }
          } catch (e) {
            print('⚠️ Error al verificar Firestore para anuncios: $e');
            // Si hay error con Firestore, usar valor de SharedPreferences
          }
        }
      }
      
      final shouldShow = !removeAds;
      
      // Actualizar el notificador si el valor cambió
      if (_shouldShowAdsNotifier.value != shouldShow) {
        _shouldShowAdsNotifier.value = shouldShow;
        print('📢 Estado de anuncios actualizado: mostrar=$shouldShow');
      }
      
      return shouldShow;
    } catch (e) {
      print('❌ Error al verificar preferencias de anuncios: $e');
      return true; // Por defecto, mostrar anuncios si hay error
    }
  }
  
  /// Notifica cambio en el estado de anuncios (para uso interno después de compras)
  static Future<void> notifyAdsStateChanged() async {
    print('🔔 Verificando cambio en estado de anuncios...');
    await shouldShowAds(); // Esto actualizará el notificador si es necesario
  }
  
  /// Fuerza la ocultación de anuncios y notifica el cambio
  static Future<void> forceHideAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remove_ads', true);
      _shouldShowAdsNotifier.value = false;
      print('🚫 Anuncios ocultados forzadamente');
    } catch (e) {
      print('❌ Error al forzar ocultación de anuncios: $e');
    }
  }

  /// Getter para verificar si el banner está listo
  bool get isBannerAdReady => _isBannerAdReady;
  
  /// Getter para obtener el banner ad
  BannerAd? get bannerAd => _bannerAd;

  /// Inicializa y carga el banner de anuncio
  /// 
  /// [onAdLoaded] - Callback que se ejecuta cuando el anuncio se carga correctamente
  /// [onAdFailedToLoad] - Callback que se ejecuta cuando falla la carga del anuncio
  Future<void> initializeBannerAd({
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    // Verificar si se deben mostrar anuncios
    final showAds = await shouldShowAds();
    if (!showAds) {
      print('🚫 Anuncios deshabilitados por preferencias del usuario');
      _isBannerAdReady = false;
      // Limpiar cualquier anuncio existente
      _bannerAd?.dispose();
      _bannerAd = null;
      return;
    }

    _onAdLoaded = onAdLoaded;
    _onAdFailedToLoad = onAdFailedToLoad;

    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          _onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ AdMob Error: ${error.message}');
          _onAdFailedToLoad?.call(error.message);
          ad.dispose();
          _isBannerAdReady = false;
        },
        onAdOpened: (ad) {
          print('📱 Banner ad opened');
        },
        onAdClosed: (ad) {
          print('📱 Banner ad closed');
        },
        onAdImpression: (ad) {
          print('📊 Banner ad impression recorded');
        },
      ),
    );

    _bannerAd?.load();
  }

  /// Widget que muestra el banner de anuncio
  /// 
  /// Retorna un Container con el banner si está listo, 
  /// o un Container vacío si no está disponible
  Widget buildBannerWidget() {
    // Verificar si se deben mostrar anuncios usando el notificador
    if (!_shouldShowAdsNotifier.value) {
      return const SizedBox.shrink();
    }
    
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink(); // Widget vacío si no hay anuncio
  }

  /// Widget que muestra el banner con margen personalizado
  /// 
  /// [margin] - EdgeInsets para el margen del banner
  Widget buildBannerWithMargin({EdgeInsets? margin}) {
    // Verificar si se deben mostrar anuncios usando el notificador
    if (!_shouldShowAdsNotifier.value) {
      return const SizedBox.shrink();
    }
    
    if (_isBannerAdReady && _bannerAd != null) {
      return Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  /// Libera los recursos del banner de anuncio
  /// 
  /// Debe ser llamado en el dispose() del widget que usa el servicio
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
    _onAdLoaded = null;
    _onAdFailedToLoad = null;
  }

  /// Recarga el banner de anuncio
  /// 
  /// Útil para refrescar el anuncio después de un error o para mostrar nuevo contenido
  Future<void> reloadBanner() async {
    dispose();
    await initializeBannerAd(
      onAdLoaded: _onAdLoaded,
      onAdFailedToLoad: _onAdFailedToLoad,
    );
  }
}

/// Mixin para widgets que necesitan usar banners de anuncios
/// 
/// Proporciona una implementación estándar para gestionar banners
/// en widgets con state.
mixin BannerAdMixin<T extends StatefulWidget> on State<T> {
  final BannerAdService _bannerAdService = BannerAdService();
  VoidCallback? _adsStateListener;

  /// Getter para acceder al servicio de banner
  BannerAdService get bannerAdService => _bannerAdService;

  /// Inicializa el banner con callbacks opcionales
  Future<void> initializeBanner({
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    await _bannerAdService.initializeBannerAd(
      onAdLoaded: onAdLoaded ?? _defaultOnAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad ?? _defaultOnAdFailedToLoad,
    );
    
    // Escuchar cambios en el estado de anuncios
    _adsStateListener = () {
      if (mounted) {
        setState(() {
          // Actualizar la UI cuando cambie el estado de anuncios
        });
      }
    };
    BannerAdService.shouldShowAdsNotifier.addListener(_adsStateListener!);
  }

  /// Callback por defecto cuando se carga el anuncio
  void _defaultOnAdLoaded() {
    if (mounted) {
      setState(() {
        // Actualizar el estado para mostrar el banner
      });
    }
  }

  /// Callback por defecto cuando falla la carga del anuncio
  void _defaultOnAdFailedToLoad(String error) {
    print('🔴 Banner ad failed to load: $error');
  }

  /// Widget para mostrar el banner (reactivo a cambios de estado)
  Widget buildBanner({EdgeInsets? margin}) {
    return ValueListenableBuilder<bool>(
      valueListenable: BannerAdService.shouldShowAdsNotifier,
      builder: (context, shouldShow, child) {
        if (!shouldShow) {
          return const SizedBox.shrink();
        }
        return _bannerAdService.buildBannerWithMargin(margin: margin);
      },
    );
  }

  /// Limpia los recursos del banner
  /// 
  /// Debe ser llamado en el dispose() del widget
  @mustCallSuper
  void disposeBanner() {
    _bannerAdService.dispose();
    if (_adsStateListener != null) {
      BannerAdService.shouldShowAdsNotifier.removeListener(_adsStateListener!);
      _adsStateListener = null;
    }
  }
}

/// Widget independiente para mostrar banners sin necesidad de mixin
/// 
/// Útil para casos donde no se puede usar el mixin o se necesita
/// un banner en widgets específicos
class BannerAdWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final VoidCallback? onAdLoaded;
  final Function(String)? onAdFailedToLoad;

  const BannerAdWidget({
    super.key,
    this.margin,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final BannerAdService _bannerAdService = BannerAdService();

  @override
  void initState() {
    super.initState();
    _initializeBanner();
  }

  Future<void> _initializeBanner() async {
    await _bannerAdService.initializeBannerAd(
      onAdLoaded: () {
        widget.onAdLoaded?.call();
        if (mounted) setState(() {});
      },
      onAdFailedToLoad: widget.onAdFailedToLoad,
    );
  }

  @override
  void dispose() {
    _bannerAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _bannerAdService.buildBannerWithMargin(margin: widget.margin);
  }
}