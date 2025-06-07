import 'package:flutter/material.dart';
import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';

class ComponentHelp extends StatelessWidget {
  final List<String> textList;

  const ComponentHelp({super.key, required this.textList});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: textList.map((text) => _text(text)).toList(),
    );
  }

  Widget _text(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}

class KritikContent extends StatelessWidget {
  const KritikContent({super.key});

  static const List<String> textList = [
    "Saya kira karena tgl recreat akan mudah",
    "ternyata mudah-mudah masih sehat dan berakal."
  ];

  @override
  Widget build(BuildContext context) => const ComponentHelp(textList: textList);
}

class SaranContent extends StatelessWidget {
  const SaranContent({super.key});

  static const List<String> textList = [
    "untuk diri kami satu sama lain aja jangan ngide' lg kalo projek banyak.",
    "Semoga kami dapat nilai baik dan menjadi modal kami untuk masa depan .",
    "dan semoga kami lancar dan bahagia hidupnya"
  ];

  @override
  Widget build(BuildContext context) => const ComponentHelp(textList: textList);
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const headerStyle = TextStyle(
    color: Color(0xffffffff),
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static const contentStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 246, 246),
      appBar: AppBar(title: const Text('Testimonial')),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Accordion(
          headerBackgroundColor: Colors.black,
          contentBackgroundColor: Colors.white,
          contentBorderColor: Colors.black,
          contentBorderWidth: 3,
          contentHorizontalPadding: 20,
          contentVerticalPadding: 20,
          scaleWhenAnimating: false,
          headerBorderRadius: 6,
          headerPadding: const EdgeInsets.all(18),
          sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
          sectionClosingHapticFeedback: SectionHapticFeedback.light,
          children: [
            AccordionSection(
              leftIcon: const Icon(Icons.favorite, color: Colors.white),
              header: const Text('Ungkapan', style: headerStyle),
              content: const Column(children: [KritikContent()]),
            ),
            AccordionSection(
              leftIcon: const Icon(Icons.mail, color: Colors.white),
              header: const Text('Pesan', style: headerStyle),
              content: const Column(children: [SaranContent()]),
            ),
          ],
        ),
      ),
    );
  }
}
