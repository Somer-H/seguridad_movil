import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screen_protector/screen_protector.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with WidgetsBindingObserver {
  final LoginViewModel _viewModel = LoginViewModel();

  // Controla si el diálogo ya está visible para no mostrarlo dos veces
  bool _alertaVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ScreenProtector.preventScreenshotOn();
    ScreenProtector.protectDataLeakageOn();
    // Listener para iOS
    ScreenProtector.addListener(
      _mostrarAlertaCaptura,
      null,
    );
    // Verificar GPS falso al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarGpsFalso();
    });
  }

  /// Verifica si el dispositivo está usando una ubicación falsa (Mock GPS)
  Future<void> _verificarGpsFalso() async {
    try {
      // Solicitar permisos de ubicación
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) return;

      // Obtener posición actual y verificar si es simulada
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (posicion.isMocked) {
        _mostrarAlertaGpsFalso();
      }

      // Seguir escuchando actualizaciones de ubicación
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen((pos) {
        if (pos.isMocked && mounted) {
          _mostrarAlertaGpsFalso();
        }
      });
    } catch (_) {
      // Si no se puede verificar, se permite continuar
    }
  }

  /// Muestra un diálogo bloqueante cuando se detecta GPS falso
  void _mostrarAlertaGpsFalso() {
    if (!mounted || _alertaVisible) return;
    _alertaVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.gps_off, color: Colors.orange, size: 48),
        title: const Text(
          'GPS falso detectado',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Se detectó que estás usando una ubicación simulada (Fake GPS).\n\n'
          'Por razones de seguridad, no puedes usar esta aplicación con un GPS falso activo.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              // Cierra la aplicación completamente
              SystemNavigator.pop();
            },
            icon: const Icon(Icons.close),
            label: const Text('Cerrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _alertaVisible = false);
  }

  /// Se llama cuando el ciclo de vida de la app cambia.
  /// En Android, al intentar capturar pantalla la app pasa a "inactive"
  /// y vuelve a "resumed" en menos de 1 segundo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Pequeño delay para distinguir captura de pantalla de cambio de app
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_alertaVisible) {
          _mostrarAlertaCaptura();
        }
      });
    }
  }

  /// Muestra un diálogo de alerta indicando que la captura está bloqueada
  void _mostrarAlertaCaptura() {
    if (!mounted || _alertaVisible) return;
    _alertaVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.no_photography, color: Colors.red, size: 48),
        title: const Text(
          'Captura bloqueada',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Esta pantalla está protegida.\nNo se permiten capturas de pantalla para proteger tus credenciales.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _alertaVisible = false;
            },
            icon: const Icon(Icons.check),
            label: const Text('Entendido'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _alertaVisible = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageOff();
    ScreenProtector.removeListener();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, child) {
              if (_viewModel.user != null) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      '¡Bienvenido!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${_viewModel.user!.email}'),
                  ],
                );
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
                  const SizedBox(height: 32),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    onChanged: _viewModel.setEmail,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_viewModel.isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    onChanged: _viewModel.setPassword,
                    obscureText: true,
                    enabled: !_viewModel.isLoading,
                  ),
                  const SizedBox(height: 24),
                  if (_viewModel.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _viewModel.login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _viewModel.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
