import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hr_beauty_cam_sdk/hr_beauty_cam_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const HrBeautyDemoApp());
}

class HrBeautyDemoApp extends StatelessWidget {
  const HrBeautyDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRBeautyCamSdk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const BeautyStudioPage(),
    );
  }
}

enum _MainTab { beauty, shape, makeup, filter, ar, shortEffect }

class _Tool {
  const _Tool({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
  });
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
}

class BeautyStudioPage extends StatefulWidget {
  const BeautyStudioPage({super.key});

  @override
  State<BeautyStudioPage> createState() => _BeautyStudioPageState();
}

class _BeautyStudioPageState extends State<BeautyStudioPage> {
  final sdk = HRBeautyCamSdk.instance;

  bool _ready = false;
  bool _recording = false;
  bool _compare = false;
  bool _filterMale = false;
  bool _switchingCamera = false;
  HrCameraFacing _facing = HrCameraFacing.front;
  String _status = 'Starting camera…';

  _MainTab _main = _MainTab.beauty;
  String _sub = 'Skin Tone';
  String _tool = 'smooth';
  double _intensity = 0.5;
  double _beautyMaster = 0.5;
  double _makeupMaster = 0.35;
  double _filterMaster = 0.45;

  static const _panel = Color(0xCC1A1A1A);
  static const _chip = Color(0x66FFFFFF);

  bool get _showMasterSliders =>
      _main == _MainTab.beauty ||
      _main == _MainTab.makeup ||
      _main == _MainTab.filter;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    var cam = await Permission.camera.status;
    if (!cam.isGranted) {
      cam = await Permission.camera.request();
    }
    if (!cam.isGranted) {
      setState(() {
        _status = cam.isPermanentlyDenied
            ? 'Camera permission permanently denied — enable in Settings'
            : 'Camera permission denied';
      });
      return;
    }
    await Permission.microphone.request();
    try {
      final ok = await sdk.initialize(
        const HrBeautySdkOptions(
          facing: HrCameraFacing.front,
          rendering: RenderingConfig(
            backend: HrRenderBackend.openGLES,
            targetFps: HrTargetFps.fps30,
            ultraLowLatency: true,
          ),
          enableLogging: true,
        ),
      );
      if (!ok) {
        setState(() => _status = 'SDK init failed');
        return;
      }
      await _applyMasterDefaults();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _status = 'Ready';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Boot error: $e');
    }
  }

  Future<void> _applyMasterDefaults() async {
    await sdk.skin.setSmooth(_beautyMaster * 0.7);
    await sdk.skin.setWhitening(_beautyMaster * 0.35);
    await sdk.skin.setGlow(_beautyMaster * 0.25);
    await sdk.makeup.setFoundation(_makeupMaster * 0.4);
    await sdk.makeup.setBlush(_makeupMaster * 0.25);
    await sdk.filter.setFilter(HrFilterType.portrait, intensity: _filterMaster);
  }

  List<String> get _subs {
    switch (_main) {
      case _MainTab.beauty:
      case _MainTab.makeup:
        return const [
          'Skin Tone',
          'Hair Color',
          'Eye lens',
          'Eye Look',
          'Lip Stick',
        ];
      case _MainTab.shape:
        return const ['Face', 'Eyes', 'Nose', 'Mouth', 'Body', 'Waist'];
      case _MainTab.shortEffect:
        return const ['Popular', 'Funny', 'Festival'];
      case _MainTab.filter:
      case _MainTab.ar:
        return const [];
    }
  }

  List<_Tool> get _tools {
    switch (_main) {
      case _MainTab.beauty:
      case _MainTab.makeup:
        return _beautyTools;
      case _MainTab.shape:
        return _shapeTools;
      case _MainTab.filter:
        return _filterTools;
      case _MainTab.ar:
        return _arTools;
      case _MainTab.shortEffect:
        return _shortTools;
    }
  }

  List<_Tool> get _beautyTools {
    switch (_sub) {
      case 'Hair Color':
        return const [
          _Tool(id: 'hair_blonde', label: 'Blonde', icon: Icons.brush, color: Color(0xFFE8D5A3)),
          _Tool(id: 'hair_brown', label: 'Brown', icon: Icons.brush, color: Color(0xFF6B3F2A)),
          _Tool(id: 'hair_dark', label: 'Dark', icon: Icons.brush, color: Color(0xFF2B1A12)),
          _Tool(id: 'hair_red', label: 'Auburn', icon: Icons.brush, color: Color(0xFFA04020)),
        ];
      case 'Eye lens':
        return const [
          _Tool(id: 'lens_purple', label: 'Amethyst', icon: Icons.remove_red_eye, color: Color(0xFF9B59B6)),
          _Tool(id: 'lens_brown', label: 'Hazel', icon: Icons.remove_red_eye, color: Color(0xFF8B5A2B)),
          _Tool(id: 'lens_blue', label: 'Ocean', icon: Icons.remove_red_eye, color: Color(0xFF3498DB)),
          _Tool(id: 'lens_green', label: 'Emerald', icon: Icons.remove_red_eye, color: Color(0xFF27AE60)),
        ];
      case 'Eye Look':
        return const [
          _Tool(id: 'eye_soft', label: 'Soft Glam', icon: Icons.visibility, color: Color(0xFFB39DDB)),
          _Tool(id: 'eye_smoky', label: 'Smoky', icon: Icons.visibility, color: Color(0xFF455A64)),
          _Tool(id: 'eye_shimmer', label: 'Shimmer', icon: Icons.visibility, color: Color(0xFFFFF8E1)),
          _Tool(id: 'eye_bold', label: 'Bold Liner', icon: Icons.visibility, color: Color(0xFF212121)),
        ];
      case 'Lip Stick':
        return const [
          _Tool(id: 'lip_49', label: '#49 Magenta', icon: Icons.opacity, color: Color(0xFFC2185B)),
          _Tool(id: 'lip_47', label: '#47 Red', icon: Icons.opacity, color: Color(0xFFE53935)),
          _Tool(id: 'lip_35', label: '#35 Rose', icon: Icons.opacity, color: Color(0xFFAD1457)),
          _Tool(id: 'lip_12', label: '#12 Berry', icon: Icons.opacity, color: Color(0xFF6A1B9A)),
        ];
      default:
        return const [
          _Tool(id: 'smooth', label: 'Smooth', icon: Icons.blur_on),
          _Tool(id: 'whiten', label: 'Whitening', icon: Icons.wb_sunny_outlined),
          _Tool(id: 'glow', label: 'Glow', icon: Icons.auto_awesome),
          _Tool(id: 'acne', label: 'Acne Clear', icon: Icons.healing),
          _Tool(id: 'dark_circle', label: 'Dark Circles', icon: Icons.remove_red_eye_outlined),
          _Tool(id: 'clarity', label: 'Clarity', icon: Icons.high_quality),
        ];
    }
  }

  List<_Tool> get _shapeTools {
    switch (_sub) {
      case 'Eyes':
        return const [
          _Tool(id: 'eye_enlarge', label: 'Enlarge', icon: Icons.zoom_in),
          _Tool(id: 'eye_clarity', label: 'Clarity', icon: Icons.brightness_5),
          _Tool(id: 'eye_circle', label: 'Circle', icon: Icons.circle_outlined),
          _Tool(id: 'brow_shape', label: 'Brow Shape', icon: Icons.timeline),
          _Tool(id: 'brow_flick', label: 'Brow Flick', icon: Icons.gesture),
        ];
      case 'Nose':
        return const [
          _Tool(id: 'nose_narrow', label: 'Narrow', icon: Icons.compress),
          _Tool(id: 'nose_wrinkle', label: 'Wrinkles', icon: Icons.waves),
          _Tool(id: 'nose_tip', label: 'Nose-Tip', icon: Icons.south),
          _Tool(id: 'philtrum', label: 'Philtrum', icon: Icons.north),
          _Tool(id: 'nose', label: 'Nose', icon: Icons.face_retouching_natural),
          _Tool(id: 'bridge', label: 'Bridge', icon: Icons.height),
        ];
      case 'Mouth':
        return const [
          _Tool(id: 'lips_shape', label: 'Lips Shape', icon: Icons.favorite_border),
          _Tool(id: 'tooth_white', label: 'Tooth White', icon: Icons.sentiment_satisfied_alt),
        ];
      case 'Body':
        return const [
          _Tool(id: 'slim_body', label: 'Slim Body', icon: Icons.accessibility_new),
          _Tool(id: 'slim_arm', label: 'Slim Arm', icon: Icons.front_hand),
          _Tool(id: 'long_legs', label: 'Long Legs', icon: Icons.straighten),
          _Tool(id: 'hip', label: 'Hip', icon: Icons.airline_seat_legroom_extra),
        ];
      case 'Waist':
        return const [
          _Tool(id: 'slim_waist', label: 'Slim Waist', icon: Icons.compress),
          _Tool(id: 'body_ratio', label: 'Body Ratio', icon: Icons.aspect_ratio),
        ];
      default:
        return const [
          _Tool(id: 'face_slim', label: 'Face Slim', icon: Icons.face),
          _Tool(id: 'jaw_slim', label: 'Jaw Slim', icon: Icons.face_6),
          _Tool(id: 'chin_length', label: 'Chin Length', icon: Icons.vertical_align_center),
          _Tool(id: 'forehead', label: 'Forehead Size', icon: Icons.vertical_align_top),
        ];
    }
  }

  List<_Tool> get _filterTools {
    if (_filterMale) {
      return const [
        _Tool(id: 'm_natural', label: 'Natural', icon: Icons.filter, color: Color(0xFFCFD8DC)),
        _Tool(id: 'm_cool', label: 'Cool', icon: Icons.filter, color: Color(0xFF90CAF9)),
        _Tool(id: 'm_film', label: 'Film', icon: Icons.filter, color: Color(0xFFA1887F)),
        _Tool(id: 'm_hdr', label: 'HDR', icon: Icons.filter, color: Color(0xFFE0E0E0)),
        _Tool(id: 'm_male', label: 'Male Pro', icon: Icons.filter, color: Color(0xFF78909C)),
      ];
    }
    return const [
      _Tool(id: 'f_natural', label: 'Natural', icon: Icons.filter, color: Color(0xFFFFE0B2)),
      _Tool(id: 'f_portrait', label: 'Portrait', icon: Icons.filter, color: Color(0xFFFFCCBC)),
      _Tool(id: 'f_sweet', label: 'Sweet', icon: Icons.filter, color: Color(0xFFF8BBD0)),
      _Tool(id: 'f_warm', label: 'Warm', icon: Icons.filter, color: Color(0xFFFFE082)),
      _Tool(id: 'f_cinema', label: 'Cinema', icon: Icons.filter, color: Color(0xFFB0BEC5)),
      _Tool(id: 'f_vintage', label: 'Vintage', icon: Icons.filter, color: Color(0xFFD7CCC8)),
    ];
  }

  List<_Tool> get _arTools => const [
        _Tool(id: 'ar_none', label: 'Original', icon: Icons.block),
        _Tool(id: 'ar_glass', label: 'Glass', icon: Icons.visibility),
        _Tool(id: 'ar_cat', label: 'Cat Ears', icon: Icons.pets),
        _Tool(id: 'ar_angel', label: 'Angel Wings', icon: Icons.auto_awesome),
        _Tool(id: 'ar_hat', label: 'Hat', icon: Icons.beach_access),
        _Tool(id: 'ar_crown', label: 'Crown', icon: Icons.workspace_premium),
      ];

  List<_Tool> get _shortTools => const [
        _Tool(id: 's_pop', label: 'Pop Glow', icon: Icons.flash_on, color: Color(0xFFFF80AB)),
        _Tool(id: 's_funny', label: 'Funny Face', icon: Icons.emoji_emotions, color: Color(0xFFFFD54F)),
        _Tool(id: 's_fest', label: 'Festival', icon: Icons.celebration, color: Color(0xFFCE93D8)),
        _Tool(id: 's_anime', label: 'Anime', icon: Icons.animation, color: Color(0xFF80DEEA)),
      ];

  Future<void> _selectMain(_MainTab tab) async {
    setState(() {
      _main = tab;
      final subs = _subs;
      _sub = subs.isEmpty ? '' : subs.first;
      _tool = _tools.first.id;
    });
    await _applyTool(_tools.first.id, _intensity);
  }

  Future<void> _selectSub(String sub) async {
    setState(() {
      _sub = sub;
      _tool = _tools.first.id;
    });
    await _applyTool(_tools.first.id, _intensity);
  }

  Future<void> _selectTool(_Tool tool) async {
    setState(() => _tool = tool.id);
    await _applyTool(tool.id, _intensity);
  }

  Future<void> _onIntensity(double v) async {
    setState(() => _intensity = v);
    await _applyTool(_tool, v);
  }

  Future<void> _applyTool(String id, double v) async {
    final x = v.clamp(0.0, 1.0);
    final signed = x * 2 - 1;

    if (id == 'smooth') {
      await sdk.skin.setSmooth(x);
    } else if (id == 'whiten') {
      await sdk.skin.setWhitening(x);
    } else if (id == 'glow') {
      await sdk.skin.setGlow(x);
    } else if (id == 'acne') {
      await sdk.skin.setAcneRemoval(x);
    } else if (id == 'dark_circle') {
      await sdk.skin.setDarkCircleRemoval(x);
    } else if (id == 'clarity') {
      await sdk.skin.setClarity(x);
    } else if (id == 'hair_blonde') {
      await sdk.hair.setHairColor(x, color: 0xFFE8D5A3);
    } else if (id == 'hair_brown') {
      await sdk.hair.setHairColor(x, color: 0xFF6B3F2A);
    } else if (id == 'hair_dark') {
      await sdk.hair.setHairColor(x, color: 0xFF2B1A12);
    } else if (id == 'hair_red') {
      await sdk.hair.setHairColor(x, color: 0xFFA04020);
    } else if (id.startsWith('lens_')) {
      await sdk.makeup.setContactLens(x);
    } else if (id == 'eye_soft') {
      await sdk.makeup.setEyeshadow(x * 0.7, color: 0xFFB39DDB);
    } else if (id == 'eye_smoky') {
      await sdk.makeup.setEyeshadow(x, color: 0xFF455A64);
      await sdk.makeup.setEyeliner(x * 0.8);
    } else if (id == 'eye_shimmer') {
      await sdk.makeup.setEyeshadow(x * 0.6, color: 0xFFFFF8E1);
      await sdk.makeup.setHighlight(x * 0.4);
    } else if (id == 'eye_bold') {
      await sdk.makeup.setEyeliner(x);
      await sdk.makeup.setEyelash(x * 0.7);
    } else if (id == 'lip_49') {
      await sdk.makeup.setLipstick(x, color: 0xFFC2185B);
    } else if (id == 'lip_47') {
      await sdk.makeup.setLipstick(x, color: 0xFFE53935);
    } else if (id == 'lip_35') {
      await sdk.makeup.setLipstick(x, color: 0xFFAD1457);
    } else if (id == 'lip_12') {
      await sdk.makeup.setLipstick(x, color: 0xFF6A1B9A);
    } else if (id == 'face_slim') {
      await sdk.face.setSlimFace(x);
    } else if (id == 'jaw_slim') {
      await sdk.face.setJaw(signed * 0.6);
    } else if (id == 'chin_length') {
      await sdk.face.setChin(signed * 0.5);
    } else if (id == 'forehead') {
      await sdk.face.setForehead(signed * 0.5);
    } else if (id == 'eye_enlarge') {
      await sdk.face.setEyeSize(signed);
    } else if (id == 'eye_clarity') {
      await sdk.skin.setClarity(x);
    } else if (id == 'eye_circle') {
      await sdk.face.setEyeDistance(signed * 0.4);
    } else if (id == 'brow_shape' || id == 'brow_flick') {
      await sdk.face.setEyebrowHeight(signed * 0.5);
      await sdk.makeup.setEyebrow(x * 0.5);
    } else if (id == 'nose_narrow' || id == 'nose') {
      await sdk.face.setNoseWidth(-x);
    } else if (id == 'nose_wrinkle') {
      await sdk.skin.setWrinkleRemoval(x);
    } else if (id == 'nose_tip') {
      await sdk.face.setNoseTip(signed * 0.5);
    } else if (id == 'philtrum') {
      await sdk.face.setNoseLength(signed * 0.4);
    } else if (id == 'bridge') {
      await sdk.face.setNoseBridge(signed * 0.5);
    } else if (id == 'lips_shape') {
      await sdk.face.setLipThickness(signed);
      await sdk.face.setMouthWidth(signed * 0.4);
    } else if (id == 'tooth_white') {
      await sdk.skin.setWhitening(x * 0.3);
      await sdk.makeup.setLipGloss(x * 0.4);
    } else if (id == 'slim_body') {
      await sdk.body.setSlimBody(x);
    } else if (id == 'slim_arm') {
      await sdk.body.setSlimArm(x);
    } else if (id == 'long_legs') {
      await sdk.body.setLongLegs(x);
    } else if (id == 'hip') {
      await sdk.body.setHipEnhancement(x);
    } else if (id == 'slim_waist') {
      await sdk.body.setSlimWaist(x);
    } else if (id == 'body_ratio') {
      await sdk.body.setBodyRatio(x);
    } else if (id == 'f_natural' || id == 'm_natural') {
      await sdk.filter.setFilter(HrFilterType.natural, intensity: x);
    } else if (id == 'f_portrait') {
      await sdk.filter.setFilter(HrFilterType.portrait, intensity: x);
    } else if (id == 'f_sweet') {
      await sdk.filter.setFilter(HrFilterType.sweet, intensity: x);
    } else if (id == 'f_warm') {
      await sdk.filter.setFilter(HrFilterType.warm, intensity: x);
    } else if (id == 'f_cinema') {
      await sdk.filter.setFilter(HrFilterType.cinemaLut, intensity: x);
    } else if (id == 'f_vintage') {
      await sdk.filter.setFilter(HrFilterType.vintage, intensity: x);
    } else if (id == 'm_cool') {
      await sdk.filter.setFilter(HrFilterType.cool, intensity: x);
    } else if (id == 'm_film') {
      await sdk.filter.setFilter(HrFilterType.film, intensity: x);
    } else if (id == 'm_hdr') {
      await sdk.filter.setFilter(HrFilterType.hdr, intensity: x);
    } else if (id == 'm_male') {
      await sdk.filter.setFilter(HrFilterType.male, intensity: x);
    } else if (id == 'ar_none') {
      await sdk.ar.clear();
    } else if (id == 'ar_glass') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.virtualGlasses,
        effectId: 'glasses',
        intensity: x,
      );
    } else if (id == 'ar_cat') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.animalMask,
        effectId: 'cat_ears',
        intensity: x,
      );
    } else if (id == 'ar_angel') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.festival,
        effectId: 'angel_wings',
        intensity: x,
      );
    } else if (id == 'ar_hat') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.virtualHat,
        effectId: 'hat',
        intensity: x,
      );
    } else if (id == 'ar_crown') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.crown,
        effectId: 'crown',
        intensity: x,
      );
    } else if (id == 's_pop') {
      await sdk.filter.setFilter(HrFilterType.highSaturation, intensity: x);
      await sdk.skin.setGlow(x * 0.5);
    } else if (id == 's_funny') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.funnyFace,
        effectId: 'funny',
        intensity: x,
      );
      await sdk.face.setEyeSize(x * 0.6);
    } else if (id == 's_fest') {
      await sdk.ar.loadEffect(
        type: HrArEffectType.festival,
        effectId: 'fest',
        intensity: x,
      );
    } else if (id == 's_anime') {
      await sdk.filter.setFilter(HrFilterType.anime, intensity: x);
    }

    if (mounted) setState(() {});
  }

  Future<void> _resetAll() async {
    await sdk.resetBeauty();
    await sdk.ar.clear();
    setState(() {
      _intensity = 0.5;
      _beautyMaster = 0.5;
      _makeupMaster = 0.35;
      _filterMaster = 0.45;
      _tool = _tools.first.id;
    });
    await _applyMasterDefaults();
  }

  Future<void> _toggleCompare() async {
    final next = !_compare;
    await sdk.setBeforeAfter(next);
    setState(() => _compare = next);
  }

  Future<void> _toggleCamera() async {
    if (_switchingCamera) return;
    setState(() => _switchingCamera = true);
    try {
      final next = _facing == HrCameraFacing.front
          ? HrCameraFacing.back
          : HrCameraFacing.front;
      await sdk.switchCamera(next);
      if (!mounted) return;
      setState(() => _facing = next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera switch failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _switchingCamera = false);
    }
  }

  Future<void> _takePhoto() async {
    final path = await sdk.takePhoto();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(path == null ? 'Photo failed' : 'Photo saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await sdk.stopRecording();
      setState(() => _recording = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path == null ? 'Record failed' : 'Video saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await sdk.startRecording('');
      setState(() => _recording = true);
    }
  }

  @override
  void dispose() {
    sdk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready)
            const Positioned.fill(
              child: HrBeautyCameraPreview(
                facing: HrCameraFacing.front,
                fit: BoxFit.cover,
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(_status, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          _topBar(),
          if (_compare) _compareOverlay(),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomPanel()),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x88000000), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            const Text(
              'HR Beauty',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            _topIcon(
              icon: Icons.compare_arrows,
              active: _compare,
              onTap: _ready ? _toggleCompare : null,
            ),
            _topIcon(
              icon: Icons.cameraswitch_rounded,
              onTap: _ready && !_switchingCamera ? _toggleCamera : null,
            ),
            _topIcon(
              icon: _recording ? Icons.stop_circle : Icons.videocam,
              active: _recording,
              onTap: _ready ? _toggleRecord : null,
            ),
            _topIcon(
              icon: Icons.photo_camera,
              onTap: _ready ? _takePhoto : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: const Alignment(-0.35, 0.25),
                child: Text(
                  'After',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Container(width: 2, color: Colors.white70),
            Expanded(
              child: Align(
                alignment: const Alignment(0.35, 0.25),
                child: Text(
                  'Before',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topIcon({
    required IconData icon,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: active ? Colors.white24 : Colors.black38,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xF00A0A0A)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _intensitySlider()),
                  const SizedBox(width: 8),
                  _resetChip(),
                ],
              ),
            ),
            if (_showMasterSliders) _masterSliders(),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _mainTab('Beauty', _MainTab.beauty),
                  _mainTab('Shape', _MainTab.shape),
                  _mainTab('Makeup', _MainTab.makeup),
                  _mainTab('Filter', _MainTab.filter),
                  _mainTab('AR Effect', _MainTab.ar),
                  _mainTab('Short Effect', _MainTab.shortEffect),
                ],
              ),
            ),
            if (_main == _MainTab.filter)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _genderChip('Female', !_filterMale),
                      const Text('  |  ', style: TextStyle(color: Colors.white54)),
                      _genderChip('Male', _filterMale),
                    ],
                  ),
                ),
              )
            else if (_subs.isNotEmpty)
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [for (final s in _subs) _subTab(s)],
                ),
              ),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                itemCount: _tools.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _toolTile(_tools[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intensitySlider() {
    final label =
        _tools.where((t) => t.id == _tool).map((t) => t.label).firstOrNull ??
            'Intensity';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _intensity,
                onChanged: _ready ? (v) => _onIntensity(v) : null,
              ),
            ),
            Positioned(
              left: 12 + (_intensity * (MediaQuery.sizeOf(context).width - 140)).clamp(0, 400),
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(_intensity * 100).round()}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _masterSliders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        children: [
          _masterRow('Beauty', _beautyMaster, (v) async {
            setState(() => _beautyMaster = v);
            await sdk.skin.setSmooth(v * 0.75);
            await sdk.skin.setWhitening(v * 0.4);
            await sdk.skin.setGlow(v * 0.3);
            await sdk.skin.setAcneRemoval(v * 0.35);
          }),
          _masterRow('Makeup', _makeupMaster, (v) async {
            setState(() => _makeupMaster = v);
            await sdk.makeup.setFoundation(v * 0.45);
            await sdk.makeup.setBlush(v * 0.3);
            await sdk.makeup.setLipstick(v * 0.35);
            await sdk.makeup.setEyeshadow(v * 0.25);
          }),
          _masterRow('Filter', _filterMaster, (v) async {
            setState(() => _filterMaster = v);
            final t = sdk.filter.config.type;
            await sdk.filter.setFilter(
              t == HrFilterType.natural ? HrFilterType.portrait : t,
              intensity: v,
            );
          }),
        ],
      ),
    );
  }

  Widget _masterRow(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.5,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(value: value, onChanged: _ready ? onChanged : null),
          ),
        ),
      ],
    );
  }

  Widget _resetChip() {
    return Material(
      color: _chip,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _ready ? _resetAll : null,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text('Reset', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainTab(String label, _MainTab tab) {
    final selected = _main == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => _selectMain(tab),
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : Colors.white54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              width: selected ? 28 : 0,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subTab(String label) {
    final selected = _sub == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => _selectSub(label),
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : Colors.white54,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(left: 6),
                width: 2,
                height: 12,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterMale = label == 'Male';
          _tool = _tools.first.id;
        });
        _applyTool(_tools.first.id, _intensity);
      },
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _toolTile(_Tool tool) {
    final selected = _tool == tool.id;
    return GestureDetector(
      onTap: () => _selectTool(tool),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: tool.color?.withValues(alpha: 0.9) ?? _panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.white : Colors.white12,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(tool.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              tool.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
