import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() => runApp(const MaterialApp(home: TestPage()));

class TestPage extends StatefulWidget {
  const TestPage({super.key});
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Interpreter? _interp;
  String _info = 'Loading model...';
  String _result = '';
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final interp = await Interpreter.fromAsset(
          'assets/models/gender_cls_float32.tflite');
      final i = interp.getInputTensor(0);
      final o = interp.getOutputTensor(0);
      setState(() {
        _interp = interp;
        _info = 'input: ${i.shape} ${i.type}\noutput: ${o.shape} ${o.type}';
      });
    } catch (e) {
      setState(() => _info = 'Load failed: $e');
    }
  }

  Future<void> _pick() async {
    final interp = _interp;
    if (interp == null) return;
    String step = 'pick';
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;

      step = 'decode';
      final decoded = img.decodeImage(await x.readAsBytes());
      if (decoded == null) {
        setState(() => _result = 'Could not decode image');
        return;
      }
      final r = img.copyResize(img.bakeOrientation(decoded),
          width: 224, height: 224);

      step = 'prepare';
      final data = Float32List(3 * 224 * 224);
      int k = 0;
      for (int c = 0; c < 3; c++) {
        for (int y = 0; y < 224; y++) {
          for (int px = 0; px < 224; px++) {
            final p = r.getPixel(px, y);
            final num val = c == 0 ? p.r : (c == 1 ? p.g : p.b);
            data[k++] = val / 255.0;
          }
        }
      }

      step = 'set input';
      interp.getInputTensor(0).data = data.buffer.asUint8List();

      step = 'invoke';
      interp.invoke();

      step = 'read output';
      final bytes = interp.getOutputTensor(0).data;
      final probs = Float32List.view(
          bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes ~/ 4);

      setState(() {
        _file = File(x.path);
        _result = [
          for (int i = 0; i < probs.length; i++)
            'class $i: ${(probs[i] * 100).toStringAsFixed(1)}%'
        ].join('\n');
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
          if (_file != null) Image.file(_file!, height: 250),
          const SizedBox(height: 12),
          Text(_result, style: const TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}