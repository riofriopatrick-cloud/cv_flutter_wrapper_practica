import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const CvWrapperApp());

class CvWrapperApp extends StatefulWidget {
  const CvWrapperApp({super.key});

  @override
  State<CvWrapperApp> createState() => _CvWrapperAppState();
}

class _CvWrapperAppState extends State<CvWrapperApp> {
  ThemeMode _modo = ThemeMode.light;

  void _cambiarTema(bool oscuro) {
    setState(() => _modo = oscuro ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CV Wrapper',
      debugShowCheckedModeBanner: false,
      themeMode: _modo,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F3A5C),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F3A5C),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: CvPage(
        oscuro: _modo == ThemeMode.dark,
        onCambiarTema: _cambiarTema,
      ),
    );
  }
}

class CvPage extends StatefulWidget {
  final bool oscuro;
  final ValueChanged<bool> onCambiarTema;

  const CvPage({super.key, required this.oscuro, required this.onCambiarTema});

  @override
  State<CvPage> createState() => _CvPageState();
}

class _CvPageState extends State<CvPage> {
  static const _paginaLocal = 'assets/web/index.html';

  late final WebViewController _controller;
  int _progreso = 0;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Canal JS -> Flutter: la web avisa cuando el usuario cambia el tema.
      ..addJavaScriptChannel(
        'FlutterTema',
        onMessageReceived: (mensaje) {
          widget.onCambiarTema(mensaje.message == 'dark');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _error = false;
            _progreso = 0;
          }),
          onProgress: (p) => setState(() => _progreso = p),
          onPageFinished: (_) {
            setState(() => _progreso = 100);
            _aplicarTema();
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _error = true);
          },
          onNavigationRequest: (peticion) {
            final uri = Uri.parse(peticion.url);
            // tel:, mailto: y enlaces web se abren fuera del WebView.
            if (['tel', 'mailto', 'http', 'https'].contains(uri.scheme)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _cargar();
  }

  void _cargar() => _controller.loadFlutterAsset(_paginaLocal);

  // Flutter -> JS: sincroniza el tema nativo con la página.
  void _aplicarTema() {
    _controller.runJavaScript(
      "if (window.setTheme) { setTheme('${widget.oscuro ? 'dark' : 'light'}'); }",
    );
  }

  @override
  void didUpdateWidget(covariant CvPage anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.oscuro != widget.oscuro) _aplicarTema();
  }

  Future<void> _copiarPerfil() async {
    const texto = 'Patrick Jhosep Riofrío Elizalde\n'
        'Estudiante de Ingeniería en Ciencias de la Computación (UPEC)\n'
        'Correo: riofriopatrick@gmail.com\n'
        'Tel: 0992059950';
    await Clipboard.setData(const ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos de contacto copiados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi hoja de vida'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
          IconButton(
            tooltip: widget.oscuro ? 'Tema claro' : 'Tema oscuro',
            icon: Icon(widget.oscuro ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onCambiarTema(!widget.oscuro),
          ),
          IconButton(
            tooltip: 'Copiar contacto',
            icon: const Icon(Icons.copy),
            onPressed: _copiarPerfil,
          ),
        ],
        bottom: _progreso < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progreso / 100),
              )
            : null,
      ),
      body: _error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar la hoja de vida.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
