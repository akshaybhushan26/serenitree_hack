import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TherapyExercisesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Therapeutic Exercises"),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
      child:Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Explore our library of therapy videos tailored to your needs.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            SizedBox(height: 20),
            Text(
              "Video Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _categoryIcon(Icons.favorite, "Stress Relief"),
                _categoryIcon(Icons.bolt, "Anxiety Management"),
                _categoryIcon(Icons.pause_circle, "Mindfulness"),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Featured Videos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _videoCard(context, "Understanding Anxiety", "Coping Techniques for Stress", "assets/images/anxiety.jpg", "xGb4fvfZpWM"),
            _videoCard(context, "Guided Meditation Oasis", "Helps improve focus and fosters calmness", "assets/images/meditation.jpg", "inpok4MKVLM"),
            _videoCard(context, "Relaxation Retreat", "Experience tranquility and peace", "assets/images/relaxation.jpg", "Jyy0ra2WcQQ"),
          ],
        ),
      ),
      ),
    );
  }

  Widget _categoryIcon(IconData icon, String title) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.lightBlue.withOpacity(0.2),
          child: Icon(icon, color: Colors.blue, size: 30),
        ),
        SizedBox(height: 5),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _videoCard(BuildContext context, String title, String subtitle, String imagePath, String videoId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoId: videoId)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.asset(imagePath, height: 200, width:500, fit: BoxFit.fill),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  VideoPlayerScreen({required this.videoId});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SerentiTree")),
      body: YoutubePlayer(controller: _controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
