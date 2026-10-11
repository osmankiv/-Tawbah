import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MaterialApp(home: TestPage()));

class Det {
  final double x0, y0, x1, y1, score;
  Det(this.x0, this.y0, this.x1, this.y1, this.score);
}

class Res {
  final Det person;
  final bool isMale;
  final double conf;
  Res(this.person, this.isMale, this.conf);
}

double iou(Det a, Det b) {
  final ix = max(0.0, min(a.x1, b.x1) - max(a.x0, b.x0));
  final iy = max(0.0, min(a.y1, b.y1) - max(a.y0, b.y0));
  final inter = ix * iy;
  final ua = (a.x1 - a.x0) * (a.y1 - a.y0) + (b.x1 - b.x0) * (b.y1 - b.y0) - inter;
  return ua <= 0 ? 0 : inter / ua;
}

Uint8List toInput(img.Image src, int size) {
  final r = img.copyResize(src, width: size, height: size);
  final data = Float32List(3 * size * size);
  int k = 0;
  for (int c = 0; c < 3; c++) {
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final p = r.getPixel(x, y);
        final num v = c == 0 ? p.r : (c == 1 ? p.g : p.b);
        data[k++] = v / 255.0;
      }
    }
  }
  return data.buffer.asUint8List();
}

Float32List run(Interpreter it, Uint8List input) {
  it.getInputTensor(0).data = input;
  it.invoke();
  final b = it.getOutputTensor(0).data;
  return Uint8List.fromList(b).buffer.asFloat32List();
}

List<Det> decodeBoxes(Float32List o, int w, int h, {double thr = 0.4}) {
  const n = 2100;
  bool norm = true;
  for (int i = 0; i < n; i++) {
    if (o[2 * n + i] > 1.5) {
      norm = false;
      break;
    }
  }
  final s = norm ? 320.0 : 1.0;
  final raw = <Det>[];
  for (int i = 0; i < n; i++) {
    final score = o[4 * n + i];
    if (score < thr) continue;
    final cx = o[i] * s, cy = o[n + i] * s, bw = o[2 * n + i] * s, bh = o[3 * n + i] * s;
    raw.add(Det(
      ((cx - bw / 2) / 320 * w).clamp(0.0, w - 1.0).toDouble(),
      ((cy - bh / 2) / 320 * h).clamp(0.0, h - 1.0).toDouble(),
      ((cx + bw / 2) / 320 * w).clamp(0.0, w - 1.0).toDouble(),
      ((cy + bh / 2) / 320 * h).clamp(0.0, h - 1.0).toDouble(),
      score,
    ));
  }
  raw.sort((a, b) => b.score.compareTo(a.score));
  final keep = <Det>[];
  for (final d in raw) {
    if (keep.every((k) => iou(k, d) < 0.5)) keep.add(d);
  }
  return keep;
}

void blurRegion(img.Image dst, int x, int y, int w, int h) {
  x = x.clamp(0, dst.width - 1);
  y = y.clamp(0, dst.height - 1);
  w = w.clamp(1, dst.width - x);
  h = h.clamp(1, dst.height - y);

  final region = img.copyCrop(dst, x: x, y: y, width: w, height: h);
  final smallW = max(2, w ~/ 60);
  final smallH = max(2, h ~/ 60);
  final small = img.copyResize(region, width: smallW, height: smallH, interpolation: img.Interpolation.average);
  final big = img.copyResize(small, width: w, height: h, interpolation: img.Interpolation.nearest);
  img.compositeImage(dst, big, dstX: x, dstY: y);
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Interpreter? _cls, _det;
  String _info = 'Loading models...';
  String _result = '';
  Uint8List? _shown;
  bool _blurMale = true;
  static const platform = MethodChannel('com.osman.tawbah/screen');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      InterpreterOptions opts() => InterpreterOptions()..threads = 4;
      final cls = await Interpreter.fromAsset(
          'assets/models/gender_cls_float32.tflite', options: opts());
      final det = await Interpreter.fromAsset(
          'assets/models/person_det_320.tflite', options: opts());
      setState(() {
        _cls = cls;
        _det = det;
        _info = 'cls: ${cls.getInputTensor(0).shape} -> ${cls.getOutputTensor(0).shape}\n'
            'det: ${det.getInputTensor(0).shape} -> ${det.getOutputTensor(0).shape}';
      });
    } catch (e) {
      setState(() => _info = 'Load failed: $e');
    }
  }

  // طلب إذن التقاط الشاشة
  Future<void> _requestScreenPermission() async {
    try {
      final bool granted = await platform.invokeMethod('requestScreenCapture');
      if (granted) {
        setState(() => _info = 'تم منح إذن التقاط الشاشة بنجاح!');
      } else {
        setState(() => _info = 'تم رفض إذن التقاط الشاشة.');
      }
    } on PlatformException catch (e) {
      setState(() => _info = "خطأ النظام: '${e.message}'.");
    }
  }

  // التقاط ومعالجة الشاشة الحية
  Future<void> _captureAndProcessScreen() async {
    if (_cls == null || _det == null) return;
    try {
      final Uint8List? bytes = await platform.invokeMethod('captureScreen');
      if (bytes == null) {
        setState(() => _result = 'لم يتم استلام أي إطار من الشاشة.');
        return;
      }

      final total = Stopwatch()..start();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      final full = img.bakeOrientation(decoded);

      var persons = decodeBoxes(run(_det!, toInput(full, 320)), full.width, full.height);

      final results = <Res>[];
      for (final d in persons) {
        final crop = img.copyCrop(full,
            x: d.x0.toInt(),
            y: d.y0.toInt(),
            width: max(1, (d.x1 - d.x0).toInt()),
            height: max(1, ((d.y1 - d.y0) * 0.4).toInt()));
        
        final p = run(_cls!, toInput(crop, 224));
        results.add(Res(d, p[1] > p[0], max(p[0], p[1])));
      }

      final out = full.clone();
      for (final r in results) {
        if (r.isMale == _blurMale) {
          final px = r.person.x0.toInt(), py = r.person.y0.toInt();
          blurRegion(out, px, py,
              max(1, (r.person.x1 - r.person.x0).toInt()),
              max(1, (r.person.y1 - r.person.y0).toInt()));
        }
      }

      setState(() {
        _shown = Uint8List.fromList(img.encodeJpg(out, quality: 70));
        _result = 'معالجة الشاشة الحية: ${total.elapsedMilliseconds}ms\nالأشخاص: ${persons.length}';
      });
    } on PlatformException catch (e) {
      setState(() => _result = 'خطأ التقاط الشاشة: ${e.message}');
    }
  }

  Future<void> _pick() async {
    if (_cls == null || _det == null) return;
    String step = 'pick';
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
      );
      if (x == null) return;

      final total = Stopwatch()..start();
      final sw = Stopwatch()..start();
      int lap() {
        final t = sw.elapsedMilliseconds;
        sw.reset();
        return t;
      }

      step = 'decode';
      final decoded = img.decodeImage(await x.readAsBytes());
      if (decoded == null) return;
      final full = img.bakeOrientation(decoded);
      final tDecode = lap();

      step = 'detect';
      var persons = decodeBoxes(run(_det!, toInput(full, 320)), full.width, full.height);
      
      final centerX = full.width / 2.0;
      final centerY = full.height / 2.0;
      persons.sort((a, b) {
        final distA = ((a.x0 + a.x1) / 2 - centerX).abs() + ((a.y0 + a.y1) / 2 - centerY).abs();
        final distB = ((b.x0 + b.x1) / 2 - centerX).abs() + ((b.y0 + b.y1) / 2 - centerY).abs();
        return distA.compareTo(distB);
      });
      final tDet = lap();

      step = 'classify';
      final results = <Res>[];
      for (final d in persons) {
        final crop = img.copyCrop(full,
            x: d.x0.toInt(),
            y: d.y0.toInt(),
            width: max(1, (d.x1 - d.x0).toInt()),
            height: max(1, ((d.y1 - d.y0) * 0.4).toInt()));
        
        final p = run(_cls!, toInput(crop, 224));
        results.add(Res(d, p[1] > p[0], max(p[0], p[1])));
      }
      final tCls = lap();

      step = 'blur';
      final out = full.clone();
      for (final r in results) {
        if (r.isMale == _blurMale) {
          final px = r.person.x0.toInt(), py = r.person.y0.toInt();
          blurRegion(out, px, py,
              max(1, (r.person.x1 - r.person.x0).toInt()),
              max(1, (r.person.y1 - r.person.y0).toInt()));
        }
      }
      final tBlur = lap();

      step = 'draw';
      final th = max(2, full.width ~/ 300);
      final lines = <String>['persons: ${persons.length}'];
      for (final r in results) {
        final d = r.person;
        final label = r.isMale ? 'male' : 'female';
        final blurred = r.isMale == _blurMale;
        final color = r.isMale ? img.ColorRgb8(255, 140, 0) : img.ColorRgb8(255, 0, 255);
        img.drawRect(out, x1: d.x0.toInt(), y1: d.y0.toInt(),
            x2: d.x1.toInt(), y2: d.y1.toInt(), color: color, thickness: th);
        img.drawString(out,
            '$label ${r.conf.toStringAsFixed(2)}${blurred ? ' [blur]' : ''}',
            font: img.arial24, x: d.x0.toInt() + 4, y: d.y0.toInt() + 4, color: color);
        lines.add('$label ${(r.conf * 100).toStringAsFixed(0)}%  [upper]${blurred ? '  <- blurred' : ''}');
      }
      final tDraw = lap();

      lines.add('');
      lines.add('image: ${full.width}x${full.height}');
      lines.add('decode $tDecode ms | person-det $tDet ms');
      lines.add('classify $tCls ms | blur $tBlur ms | draw $tDraw ms');
      lines.add('TOTAL ${total.elapsedMilliseconds} ms');

      setState(() {
        _shown = Uint8List.fromList(img.encodeJpg(out, quality: 80));
        _result = lines.join('\n');
      });
    } catch (e) {
      setState(() => _result = 'Error at "$step": $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tawbah')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          Text(_info),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('تمويه الذكور')),
              ButtonSegment(value: false, label: Text('تمويه الإناث')),
            ],
            selected: {_blurMale},
            onSelectionChanged: (s) => setState(() => _blurMale = s.first),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _pick, child: const Text('Pick image')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _requestScreenPermission,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('طلب إذن التقاط الشاشة'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _captureAndProcessScreen,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('التقاط ومعالجة الشاشة الحالية'),
          ),
          const SizedBox(height: 12),
          if (_shown != null) Image.memory(_shown!),
          const SizedBox(height: 12),
          Text(_result, style: const TextStyle(fontSize: 16)),
        ]),
      ),
    );
  }
}