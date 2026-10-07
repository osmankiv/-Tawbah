import 'dart:math';
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() => runApp(const MaterialApp(home: TestPage()));

class Det {
  final double x0, y0, x1, y1, score;
  Det(this.x0, this.y0, this.x1, this.y1, this.score);
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

// مخرج الكاشف [1,84,2100]: الصفوف 0..3 للمربع، والصف 4 للصنف person
List<Det> decodePersons(Float32List o, int w, int h, {double thr = 0.4}) {
  const n = 2100;
  bool norm = true;
  for (int i = 0; i < n; i++) {
    if (o[2 * n + i] > 1.5) { norm = false; break; }
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cls = await Interpreter.fromAsset('assets/models/gender_cls_float32.tflite');
      final det = await Interpreter.fromAsset('assets/models/person_det_320.tflite');
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

  Future<void> _pick() async {
    if (_cls == null || _det == null) return;
    String step = 'pick';
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;

      step = 'decode';
      final decoded = img.decodeImage(await x.readAsBytes());
      if (decoded == null) return;
      final full = img.bakeOrientation(decoded);

      step = 'detect';
      final persons = decodePersons(run(_det!, toInput(full, 320)), full.width, full.height);

      final out = full.clone();
      final lines = <String>['persons: ${persons.length}'];

      for (final d in persons) {
        step = 'classify';
        final px = d.x0.toInt(), py = d.y0.toInt();
        final pw = max(1, (d.x1 - d.x0).toInt()), ph = max(1, (d.y1 - d.y0).toInt());
        // مؤقتاً: أعلى 40% من الشخص بدل كاشف الوجه
        final crop = img.copyCrop(full, x: px, y: py, width: pw, height: max(1, (ph * 0.4).toInt()));
        final p = run(_cls!, toInput(crop, 224));
        final isMale = p[1] > p[0];
        final label = isMale ? 'male' : 'female';
        final conf = max(p[0], p[1]);
        final color = isMale ? img.ColorRgb8(255, 140, 0) : img.ColorRgb8(255, 0, 255);

        step = 'draw';
        img.drawRect(out, x1: px, y1: py, x2: px + pw, y2: py + ph, color: color, thickness: 4);
        img.drawString(out, '$label ${conf.toStringAsFixed(2)}',
            font: img.arial24, x: px + 6, y: py + 6, color: color);
        lines.add('$label ${(conf * 100).toStringAsFixed(0)}%  (person ${(d.score * 100).toStringAsFixed(0)}%)');
      }

      setState(() {
        _shown = Uint8List.fromList(img.encodeJpg(out));
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
          ElevatedButton(onPressed: _pick, child: const Text('Pick image')),
          const SizedBox(height: 12),
          if (_shown != null) Image.memory(_shown!),
          const SizedBox(height: 12),
          Text(_result, style: const TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}
