import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SimpleTeethDiagramPage extends StatefulWidget {
  @override
  _SimpleTeethDiagramPageState createState() => _SimpleTeethDiagramPageState();
}

class _SimpleTeethDiagramPageState extends State<SimpleTeethDiagramPage> {
  String? hoveredToothId;
  final Map<String, String> toothDetails = {
    "D1": "Tooth #1: Filling",
    "D2": "Tooth #2: Crown",
    "D3": "Tooth #3: Root Canal",
    "D4": "Tooth #4: Missing",
    "D5": "Tooth #5: Cleaning",
    // Add all D1 to D32 descriptions...
  };
  late Future<DrawableRoot> svgRootFuture;

  @override
  void initState() {
    super.initState();
    svgRootFuture = _loadSvg();
  }


  Future<DrawableRoot> _loadSvg() async {
    // Load the SVG and parse it into a DrawableRoot
    final svgData = await DefaultAssetBundle.of(context).loadString('assets/teeth.svg');
    return await svg.fromSvgString(svgData, svgData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teeth Diagram - DentMe'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<DrawableRoot>(
        future: svgRootFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading SVG: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final svgRoot = snapshot.data!;
            return Column(
              children: [
                // Teeth Diagram Section
                Expanded(
                  flex: 3,
                  child: Center(
                    child: GestureDetector(
                      onTapDown: (details) => _handleInteraction(details.localPosition, svgRoot, context),
                      child: CustomPaint(
                        size: Size(MediaQuery.of(context).size.width * 0.8,
                            MediaQuery.of(context).size.height * 0.5),
                        painter: TeethSvgPainter(
                          svgRoot: svgRoot,
                          hoveredToothId: hoveredToothId,
                        ),
                      ),
                    ),
                  ),
                ),
                // Display Details for Hovered Tooth
                Expanded(
                  flex: 1,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: hoveredToothId != null ? Colors.teal[100] : Colors.grey[200],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: Text(
                        hoveredToothId != null
                            ? toothDetails[hoveredToothId] ?? "No details available for this tooth."
                            : "Hover or tap on a tooth to see details.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hoveredToothId != null ? Colors.teal[900] : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('Unexpected error'));
          }
        },
      ),
    );
  }

void _handleInteraction(Offset position, DrawableRoot svgRoot, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(position);

    final viewBox = svgRoot.viewport.viewBoxRect;
    final renderBoxSize = renderBox.size;

    final scaleX = renderBoxSize.width / viewBox.width;
    final scaleY = renderBoxSize.height / viewBox.height;

    final svgPosition = Offset(
      (localPosition.dx / scaleX) + viewBox.left,
      (localPosition.dy / scaleY) + viewBox.top,
    );

    print('Local position: $localPosition');
    print('SVG position: $svgPosition');
    print('ViewBox: $viewBox');

    for (final child in svgRoot.children!) {
      if (child is DrawableGroup) {
        for (final element in child.children!) {
          if (element is DrawableShape) {
            print('Element ID: ${element.id}');
            final bounds = element.path.getBounds();
            print('Bounds: $bounds');
            if (element.id != null && bounds.contains(svgPosition)) {
              print('Tapped on element ${element.id}');
              setState(() {
                hoveredToothId = element.id; // Update the hovered tooth ID
              });
              return;
            }
          }
        }
      }
    }
}


}
class TeethSvgPainter extends CustomPainter {
  final DrawableRoot svgRoot;
  final String? hoveredToothId;

  TeethSvgPainter({required this.svgRoot, required this.hoveredToothId});

  @override
  void paint(Canvas canvas, Size size) {
    final viewBox = svgRoot.viewport.viewBoxRect;
    final renderBoxSize = size;

    final scaleX = renderBoxSize.width / viewBox.width;
    final scaleY = renderBoxSize.height / viewBox.height;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Highlight hovered tooth
    if (svgRoot.children != null) {
      for (final child in svgRoot.children!) {
        if (child is DrawableGroup && child.children != null) {
          for (final element in child.children!) {
            if (element is DrawableShape && element.id != null) {
              if (element.id == hoveredToothId) {
                final highlightPaint = Paint()
                  ..style = PaintingStyle.fill
                  ..color = Colors.blue.withOpacity(0.5);
                canvas.drawPath(element.path, highlightPaint);
              }
            }
          }
        }
      }
    }

    svgRoot.draw(canvas, Offset.zero & viewBox.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint when hoveredToothId changes
  }
}
