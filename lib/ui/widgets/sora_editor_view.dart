import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoraEditorView extends StatefulWidget {
  const SoraEditorView({super.key});

  @override
  State<SoraEditorView> createState() => _SoraEditorViewState();
}

class _SoraEditorViewState extends State<SoraEditorView> {
  static const _channel = MethodChannel('sora_editor');

  @override
  void initState() {
    super.initState();
    _channel.invokeMethod('setText', {'text': sampleText});
    _channel.invokeMethod('setFontSize', {'size': 12.0});
    _channel.invokeMethod('setWrap', {'wrap': true});
    _channel.invokeMethod('setLineNumbers', {'enabled': true});
  }

  @override
  Widget build(BuildContext context) {
    return const AndroidView(
      viewType: 'sora_editor_view',
      layoutDirection: TextDirection.ltr,
    );
  }
}

const sampleText = '''# TODO: example
# game/script-ch1.rpy:9
translate spanish ch1_main_0f077782:

    # m "Hi again, [player]!"
    m "¡Hola de nuevo, [player]!"

# game/script-ch1.rpy:10
translate spanish ch1_main_95ea4bac:

    # m "Glad to see you didn't run away on us. Hahaha!"
    m "Qué bien, no has huido con el rabo entre las piernas. ¡Ja, ja, ja!"

# game/script-ch1.rpy:11
translate spanish ch1_main_ecaf5654:

    # mc "Nah, don't worry."
    mc "Qué va, yo no hago esas cosas."

# game/script-ch1.rpy:12
translate spanish ch1_main_a0e98f5a:

    # mc "This might be a little strange for me, but I at least keep my word."
    mc "Se me hace un poco raro, pero pienso cumplir mi palabra."

# game/script-ch1.rpy:15
translate spanish ch1_main_5bff8fb6:

    # "Well, I'm back at the Literature Club."
    "Bien, he vuelto al club de literatura."

# game/script-ch1.rpy:16
translate spanish ch1_main_0565e928:

    # "I was the last to come in, so everyone else is already hanging out."
    "He sido el último en llegar, así que las chicas ya están pasando el rato."

# game/script-ch1.rpy:18
translate spanish ch1_main_209577b0:

    # y "Thanks for keeping your promise, [player]."
    y "Gracias por mantener tu promesa, [player]."

# game/script-ch1.rpy:19
translate spanish ch1_main_fc35d1a5:

    # y "I hope this isn't too overwhelming of a commitment for you."
    y "Espero que este compromiso no se te haga muy cuesta arriba."

# game/script-ch1.rpy:20
translate spanish ch1_main_0b033aa0:

    # y 1u "Making you dive headfirst into literature when you're not accustomed to it..."
    y 1u "Es duro que te obliguen a zambullirte en la literatura cuando no estás acostumbrado..."

# game/script-ch1.rpy:22
translate spanish ch1_main_4bc8df14:

    # n "Oh, come on! Like he deserves any slack."
    n "¡Venga ya! No hace falta que te compadezcas de él."

# game/script-ch1.rpy:23
translate spanish ch1_main_54887548:

    # n "Sayori told me you didn't even want to join any clubs this year."
    n "Sayori me dijo que ni siquiera pensabas unirte a ningún club este año."

# game/script-ch1.rpy:24
translate spanish ch1_main_0e4e14ce:

    # n "And last year, too!"
    n "¡Ni el año pasado!"

# game/script-ch1.rpy:25
translate spanish ch1_main_131e8e4b:

    # n 4c "I don't know if you plan to just come here and hang out, or what..."
    n 4c "No sé si piensas venir a hacer el zángano..."
''';
