import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/network/game_socket.dart';
import '../../data/models/stroke.dart';
import '../game/drawing_canvas.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final name = TextEditingController(),
      code = TextEditingController(),
      guess = TextEditingController();
  String language = 'en', endpoint = 'ws://10.0.2.2:3000';
  Map<String, dynamic>? room;
  String? error;
  String? selfId;
  List<Stroke> strokes = [];
  List<dynamic> choices = [];
  StreamSubscription? sub;
  bool connected = false;
  GameSocket get socket => ref.read(socketProvider);
  void connect(Map<String, Object?> message) {
    socket.connect(endpoint);
    sub?.cancel();
    sub = socket.messages?.listen((raw) {
      final m = jsonDecode(raw as String) as Map<String, dynamic>;
      if (m['type'] == 'error') setState(() => error = m['message'] as String);
      if (m['type'] == 'left_room') {
        setState(() {
          room = null;
          strokes.clear();
          choices.clear();
          connected = false;
        });
      }
      if (m['type'] == 'room_state') {
        setState(() => room = m['room'] as Map<String, dynamic>);
      }
      if (m['type'] == 'reconnect_success') {
        setState(() {
          connected = true;
          selfId = m['playerId'] as String?;
        });
      }
      if (m['type'] == 'word_choices' && m['choices'] != null) {
        setState(() => choices = m['choices'] as List);
      }
      if (m['type'] == 'stroke_batch') {
        setState(() => strokes.addAll((m['strokes'] as List)
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))));
      }
      if (m['type'] == 'clear') setState(strokes.clear);
      if (m['type'] == 'undo' && strokes.isNotEmpty) {
        setState(strokes.removeLast);
      }
    });
    socket.send(message);
  }

  @override
  void dispose() {
    sub?.cancel();
    name.dispose();
    code.dispose();
    guess.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = room;
    return Scaffold(body: SafeArea(child: r == null ? _home() : _room(r)));
  }

  Widget _home() => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 38),
                    Container(
                        height: 104,
                        width: 104,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: const Color(0xffffdfb1),
                            borderRadius: BorderRadius.circular(32)),
                        child:
                            const Text('✏️', style: TextStyle(fontSize: 52))),
                    const SizedBox(height: 20),
                    Text('blot',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xff302b3d),
                                letterSpacing: -3)),
                    const Text('Draw it. Guess it. Have a blast.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 16)),
                    const SizedBox(height: 34),
                    TextField(
                        controller: name,
                        decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person))),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                        initialValue: language,
                        decoration:
                            const InputDecoration(labelText: 'Word language'),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                          DropdownMenuItem(
                              value: 'hinglish', child: Text('Hinglish')),
                          DropdownMenuItem(value: 'mr', child: Text('मराठी'))
                        ],
                        onChanged: (v) => setState(() => language = v ?? 'en')),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add),
                        label: const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Create a room'))),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: code,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                  labelText: 'Room code', counterText: ''))),
                      const SizedBox(width: 10),
                      FilledButton.tonal(
                          onPressed: _join, child: const Text('Join'))
                    ]),
                    Text('●  ${connected ? 'Connected' : 'Ready to connect'}',
                        style: TextStyle(
                            color: connected ? Colors.green : Colors.black45)),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red))
                  ]))));
  void _create() {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Enter your name to continue');
      return;
    }
    connect({
      'type': 'create_room',
      'name': name.text.trim(),
      'language': language
    });
  }

  void _join() {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Enter your name to continue');
      return;
    }
    connect({
      'type': 'join_room',
      'name': name.text.trim(),
      'code': code.text.trim().toUpperCase(),
      'language': language
    });
  }

  Widget _room(Map<String, dynamic> r) {
    final players = (r['players'] as List? ?? []);
    final host =
        players.where((p) => p['id'] == r['hostId']).cast<Map>().firstOrNull;
    final isDrawer = selfId != null && selfId == r['drawerId'];
    return Scaffold(
        appBar: AppBar(
            title: Text(r['phase'] == 'LOBBY'
                ? 'Room ${r['code']}'
                : 'Round ${r['round'] + 1}'),
            actions: [
              IconButton(
                  onPressed: () => socket.send({'type': 'leave_room'}),
                  icon: const Icon(Icons.exit_to_app))
            ]),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (r['phase'] == 'LOBBY') ...[
                    Text('Share this code with your crew',
                        style: Theme.of(context).textTheme.titleMedium),
                    SelectableText('${r['code']}',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w900, letterSpacing: 8)),
                    Text('Host: ${host?['name'] ?? '—'}'),
                    const SizedBox(height: 14),
                    ...players.map((p) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(p['name'] as String),
                        trailing: Text(
                            p['id'] == r['hostId'] ? 'HOST' : '● online'))),
                    const Spacer(),
                    FilledButton(
                        onPressed: players.length >= 2
                            ? () => socket.send({'type': 'start_game'})
                            : null,
                        child: const Text('Start game · need 2+ players'))
                  ] else if (r['phase'] == 'GAME_END') ...[
                    Text('Game over! 🎉',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 18),
                    ...([...players]..sort((a, b) =>
                            (b['score'] as int).compareTo(a['score'] as int)))
                        .asMap()
                        .entries
                        .map((entry) => ListTile(
                            leading: Text('#${entry.key + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            title: Text(entry.value['name'] as String),
                            trailing: Text('${entry.value['score']} pts'))),
                    const Spacer(),
                    FilledButton(
                        onPressed: () => socket.send({'type': 'leave_room'}),
                        child: const Text('Back to home'))
                  ] else ...[
                    Text(
                        'Drawing: ${players.where((p) => p['id'] == r['drawerId']).map((p) => p['name']).firstOrNull ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium),
                    if (choices.isNotEmpty)
                      Wrap(
                          spacing: 8,
                          children: List.generate(
                              choices.length,
                              (i) => ActionChip(
                                  label: Text('${choices[i]}'),
                                  onPressed: () => socket.send(
                                      {'type': 'choose_word', 'wordId': i})))),
                    Expanded(
                        child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.black12)),
                            child: DrawingCanvas(
                                strokes: strokes,
                                onStroke: (s) => socket.send({
                                      'type': 'stroke_batch',
                                      'strokes': [s.toJson()]
                                    }),
                                readOnly: !isDrawer))),
                    Row(children: [
                      IconButton(
                          onPressed: () => socket.send({'type': 'undo'}),
                          icon: const Icon(Icons.undo)),
                      IconButton(
                          onPressed: () => socket.send({'type': 'clear'}),
                          icon: const Icon(Icons.delete_outline)),
                      Expanded(
                          child: TextField(
                              controller: guess,
                              decoration: const InputDecoration(
                                  hintText: 'Type your guess'))),
                      IconButton(
                          onPressed: () {
                            socket.send({'type': 'guess', 'text': guess.text});
                            guess.clear();
                          },
                          icon: const Icon(Icons.send))
                    ]),
                    ...players
                        .map((p) => Text('${p['name']}   ${p['score']} pts'))
                  ]
                ])));
  }
}
