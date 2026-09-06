import 'package:flutter/material.dart';

class ProyectCard extends StatelessWidget {
  const ProyectCard({super.key});

  @override
  Widget build(BuildContext context) {
    Color cardColor = Theme.of(context).colorScheme.onPrimaryContainer;
    Color textColor = Theme.of(context).colorScheme.onPrimary;
    String imageUrl =
        'https://fultoncountyvetclinic.com/wp-content/uploads/bb-plugin/cache/cat-stretching-panorama-fd4135722bc818a9db1debc7def411a0-4hg3jvxm67az.jpg';
    String title = 'Kirche: Proyecto de renovacion urbanana y sostenibilidad';
    String jobs =
        'Ing. Software - Ing. Ambiental - Ing. Electronica - Ing. Industrial';
    String skills =
        '-Modelación\n -Análisis de datos\n -Desarrollo de software\n -Diseño de software';
    String description =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: Colors.black),
      ),
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.05,
        right: MediaQuery.of(context).size.width * 0.05,
        top: MediaQuery.of(context).size.height * 0.05,
      ),
      child: Column(
        children: [
          //Jobs at top
          JobsAtTop(jobs: jobs, textColor: textColor),
          //Divider
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Divider(color: Colors.black, thickness: 2),
          ),
          //Image of project
          ImageOfProject(imageUrl: imageUrl),
          //Title of the project
          TitleOfProject(title: title, textColor: textColor),
          //Divider
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Divider(color: Colors.black, thickness: 2),
          ),
          //Skills required and description in two columns
          SkillsAndDescription(
            skills: skills,
            description: description,
            textColor: textColor,
          ),
          //Divider
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Divider(color: Colors.black, thickness: 2),
          ),
          //Buttons
          Buttons(textColor: textColor),
        ],
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  const Buttons({super.key, required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Row(
        spacing: MediaQuery.of(context).size.width * 0.04,
        children: [
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Colors.black, width: 1),
              ),
            ),
            label: Text("Leer más", style: TextStyle(color: textColor)),
            icon: Icon(Icons.menu_book),
          ),
          Flexible(
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              label: Text(
                "Estoy interesado!",
                style: TextStyle(color: textColor),
              ),
              icon: Icon(Icons.bookmark),
            ),
          ),
        ],
      ),
    );
  }
}

class SkillsAndDescription extends StatelessWidget {
  const SkillsAndDescription({
    super.key,
    required this.skills,
    required this.description,
    required this.textColor,
  });

  final String skills;
  final String description;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(MediaQuery.of(context).size.height * 0.005),
      width: MediaQuery.of(context).size.width * 0.8,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Text(
              "Habilidades requeridas:\n" + skills,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: TextStyle(color: textColor),
            ),
            VerticalDivider(color: Colors.black, thickness: 2),
            Flexible(
              child: Text(
                description,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleOfProject extends StatelessWidget {
  const TitleOfProject({
    super.key,
    required this.title,
    required this.textColor,
  });

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(MediaQuery.of(context).size.height * 0.005),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Text(
        title,
        textAlign: TextAlign.left,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.linear(2),
        style: TextStyle(color: textColor),
      ),
    );
  }
}

class ImageOfProject extends StatelessWidget {
  const ImageOfProject({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(MediaQuery.of(context).size.height * 0.005),
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.3,
      child: Image.network(imageUrl, fit: BoxFit.fill),
    );
  }
}

class JobsAtTop extends StatelessWidget {
  const JobsAtTop({super.key, required this.jobs, required this.textColor});

  final String jobs;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.04,
        right: MediaQuery.of(context).size.width * 0.04,
      ),
      child: Text(
        jobs,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: textColor),
      ),
    );
  }
}
