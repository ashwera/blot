import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  String language = 'en',
      endpoint = kIsWeb ? 'ws://localhost:3001' : 'ws://10.0.2.2:3000';
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

  Widget _home() => LayoutBuilder(builder: (context, _) {
        return Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/game-night-hero.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66a83f24),
                  Color(0x99b64a29),
                  Color(0xeafff3e4),
                  Color(0xfffff8ed),
                ],
                stops: [0, .38, .70, 1],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
            child: Column(children: [
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(
                    radius: 19,
                    backgroundColor: Color(0xfffff4e3),
                    child: Icon(Icons.brush_rounded, color: Color(0xffe96e50))),
                SizedBox(width: 10),
                Text('BLOT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900))
              ]),
              const SizedBox(height: 82),
              const Text('Draw. Guess.\nLaugh together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                      shadows: [
                        Shadow(color: Color(0x55000000), blurRadius: 10)
                      ])),
              const SizedBox(height: 18),
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _welcomeCard()),
            ]),
          )
        ]);
      });

  Widget _welcomeCard() => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x160d3440), blurRadius: 30, offset: Offset(0, 12))
          ],
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Game night starts here',
              style: TextStyle(
                  color: Color(0xff173844),
                  fontSize: 27,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Create a private room or join your friends.',
              style: TextStyle(color: Color(0xff60727a), fontSize: 15)),
          const SizedBox(height: 26),
          TextField(
              controller: name,
              decoration: const InputDecoration(
                  labelText: 'Your name',
                  prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
              initialValue: language,
              decoration: const InputDecoration(
                  labelText: 'Word language',
                  prefixIcon: Icon(Icons.language_outlined)),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                DropdownMenuItem(value: 'hinglish', child: Text('Hinglish')),
                DropdownMenuItem(value: 'mr', child: Text('मराठी'))
              ],
              onChanged: (v) => setState(() => language = v ?? 'en')),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffe96e50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: _create,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create a room',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(children: [
                Expanded(child: Divider()),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR JOIN A ROOM',
                        style: TextStyle(
                            color: Color(0xff8b989d),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1))),
                Expanded(child: Divider()),
              ])),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: const InputDecoration(
                        labelText: 'Room code', counterText: ''))),
            const SizedBox(width: 10),
            SizedBox(
                height: 54,
                child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffd9f0eb),
                        foregroundColor: const Color(0xff173844)),
                    onPressed: _join,
                    child: const Text('Join',
                        style: TextStyle(fontWeight: FontWeight.w800))))
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Icon(Icons.circle,
                size: 9,
                color: connected
                    ? const Color(0xff33a474)
                    : const Color(0xffaeb7b7)),
            const SizedBox(width: 7),
            Text(connected ? 'Connected to game server' : 'Ready to connect',
                style: const TextStyle(color: Color(0xff738187), fontSize: 13))
          ]),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Colors.red))
          ]
        ]),
      );
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
