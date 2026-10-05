import 'dart:io';
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
          'assets/models/best_Gender_classification_int8.tflite');
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
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final decoded = img.decodeImage(await x.readAsBytes());
      if (decoded == null) return;
      final r = img.copyResize(decoded, width: 224, height: 224);

      final inT = interp.getInputTensor(0);
      if (inT.type != TensorType.float32) {
        setState(() {
          _file = File(x.path);
          _result = 'Input type is ${inT.type}, send me this line';
        });
        return;
      }
      final nchw = inT.shape[1] == 3;

      double v(int px, int py, int c) {
        final p = r.getPixel(px, py);
        final num val = c == 0 ? p.r : (c == 1 ? p.g : p.b);
        return val / 255.0;
      }

      final input = nchw
          ? List.generate(1, (_) => List.generate(3, (c) =>
              List.generate(224, (y) => List.generate(224, (px) => v(px, y, c)))))
          : List.generate(1, (_) => List.generate(224, (y) =>
              List.generate(224, (px) => List.generate(3, (c) => v(px, y, c)))));

      final n = interp.getOutputTensor(0).shape[1];
      final output = List.generate(1, (_) => List.filled(n, 0.0));
      interp.run(input, output);

      final probs = output[0];
      setState(() {
        _file = File(x.path);
        _result = [
          for (int i = 0; i < probs.length; i++)
            'class $i: ${(probs[i] * 100).toStringAsFixed(1)}%'
        ].join('\n');
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
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