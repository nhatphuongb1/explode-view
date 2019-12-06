import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _DemoPageState createState() => new _DemoPageState();

  DemoPage() {
    timeDilation = 1.0;
  }
}

class _DemoPageState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Flutter",
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new MyWidget(),
    );
  }
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    String imagePath = 'assets/images/swiggy.png';
    final size = MediaQuery.of(context).size;
    return new MaterialApp(
      home: new DemoBody(screenSize: size, imagePath: imagePath,),
    );
  }
}

class DemoBody extends StatefulWidget {
  final Size screenSize;
  final String imagePath;

  DemoBody({Key key, @required this.screenSize, @required this.imagePath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<DemoBody> with TickerProviderStateMixin{

  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  final List<Particle> particles = [];
  Random random;


  double leftPos=10.0, topPos=10.0;

  bool useSnapshot = true;
  bool isImage = true;
  double imageSize = 50.0;

  GlobalKey currentKey;

  AnimationController imageAnimationController;
  Animation<double> imageAnimation;

  final StreamController<Color> _stateController = StreamController<Color>.broadcast();
  img.Image photo;

  @override
  void initState() {
    super.initState();

    currentKey = useSnapshot ? paintKey : imageKey;
    random = new Random();

    imageAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    );

  }

  Vector3 _shake() {
    return Vector3(sin((imageAnimationController.value) * pi * 20.0) * 8, 0.0, 0.0);
  }

  @override
  void dispose(){
    imageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: Colors.black,
            appBar: PreferredSize(
              preferredSize: Size(double.infinity, 50),
              child: AppBar(
                title: Text("Explode View"),
                automaticallyImplyLeading: false,
              ),
            ),
            body: Container(
              child: Stack(
                children: <Widget>[
                  isImage
                      ? StreamBuilder(
                      initialData: Colors.green[500],
                      stream: _stateController.stream,
                      builder: (buildContext, snapshot) {
                        return Stack(
                          children: <Widget>[
                            RepaintBoundary(
                              key: paintKey,
                              child: GestureDetector(
                                onLongPress: () {

                                  imageAnimationController.forward();

                                  RenderBox box = imageKey.currentContext.findRenderObject();
                                  Offset position = box.localToGlobal(Offset.zero);
                                  double offsetX = position.dx;
                                  double offsetY = position.dy;


                                  double offsetXCenter = offsetX + (imageSize/2);
                                  double offsetYCenter = offsetY + (imageSize/2);

                                  final List<Color> colors = [];

                                  for(int i=0;i<64;i++){
                                    setState(() {
                                      leftPos = offsetX.toDouble();
                                      topPos = (offsetY-60).toDouble();
                                    });
                                    if(i<21){
                                      getPixel(position, Offset(offsetX+i*0.7, offsetY-(60)), box.size.width).then((value) {
                                        colors.add(value);
                                      });
                                    }else if(i>=21 && i<42){
                                      getPixel(position, Offset(offsetX+i*0.7, offsetY-(52)), box.size.width).then((value) {
                                        colors.add(value);
                                      });
                                    }else{
                                      getPixel(position, Offset(offsetX+i*0.7, offsetY-(68)), box.size.width).then((value) {
                                        colors.add(value);
                                      });
                                    }
                                  }


                                  Future.delayed(Duration(milliseconds: 3500), () {

                                    for(int i=0;i<64;i++){
                                      if(i<21){
                                        particles.add(Particle(id: i, screenSize: widget.screenSize, colors: colors[i].withOpacity(1.0), offsetX: (offsetXCenter-offsetX+i*0.7)*0.1, offsetY: (offsetYCenter-(offsetY-60))*0.1, newOffsetX: offsetX+i*0.7, newOffsetY: offsetY-60));
                                      }else if(i>=21 && i<42){
                                        particles.add(Particle(id: i, screenSize: widget.screenSize, colors: colors[i].withOpacity(1.0), offsetX: (offsetXCenter-offsetX+i*0.5)*0.1, offsetY: (offsetYCenter-(offsetY-52))*0.1, newOffsetX: offsetX+i*0.7, newOffsetY: offsetY-52));
                                      }else{
                                        particles.add(Particle(id: i, screenSize: widget.screenSize, colors: colors[i].withOpacity(1.0), offsetX: (offsetXCenter-offsetX+i*0.9)*0.1, offsetY: (offsetYCenter-(offsetY-68))*0.1, newOffsetX: offsetX+i*0.7, newOffsetY: offsetY-68));
                                      }
                                    }

                                    setState(() {
                                      isImage = false;
                                    });

                                  });

                                },
                                child: Container(
                                  alignment: FractionalOffset(0.35, 0.75),
                                  child: Transform(
                                    transform: Matrix4.translation(_shake()),
                                    child: Image.asset(
                                      widget.imagePath,
                                      key: imageKey,
                                      width: imageSize,
                                      height: imageSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }):
                  Container(
                    child: Stack(
                      children: <Widget>[
                        for(Particle particle in particles) particle.buildWidget(),
                        RaisedButton(
                          child: Text("Go Back"),
                          onPressed: () {
                            setState(() {
                              isImage = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              )

            )
        ),
      );
  }


  Future<void> loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(widget.imagePath);
    setImageBytes(imageBytes);
  }

  Future<void> loadSnapshotBytes() async {
    RenderRepaintBoundary boxPaint = paintKey.currentContext.findRenderObject();
    ui.Image capture = await boxPaint.toImage();
    ByteData imageBytes =
    await capture.toByteData(format: ui.ImageByteFormat.png);
    setImageBytes(imageBytes);
    capture.dispose();
  }

  void setImageBytes(ByteData imageBytes) {
    List<int> values = imageBytes.buffer.asUint8List();
    photo = img.decodeImage(values);
  }

  Future<Color> getPixel(Offset globalPosition, Offset position, double size) async {
    if (photo == null) {
      await (useSnapshot ? loadSnapshotBytes() : loadImageBundleBytes());
    }

    Color newColor = calculatePixel(globalPosition, position, size);
    return newColor;
  }

  Color calculatePixel(Offset globalPosition, Offset position, double size) {

    double px = position.dx;
    double py = position.dy;


    if (!useSnapshot) {
      double widgetScale = size / photo.width;
      px = (px / widgetScale);
      py = (py / widgetScale);

    }


    int pixel32 = photo.getPixelSafe(px.toInt()+1, py.toInt());

    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));

    Color returnColor = Color(hex);

    return returnColor;
  }

  // As image uses KML color format i.e. #AABBRRGG, convert this format to normal #AARRGGBB
  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

}



class Particle extends _MyHomePageState{
  int id;
  Size screenSize;
  Offset position;
  double offsetX=0.0, offsetY=0.0;
  static final randomValue = Random();
  AnimationController animationController;
  Animation translateXAnimation, negatetranslateXAnimation;
  Animation translateYAnimation, negatetranslateYAnimation;
  Animation fadingAnimation;
  Animation particleSize;
  double x,y;
  Color colors;
  double newOffsetX = 0.0, newOffsetY = 0.0;


  Particle({@required this.id, @required this.screenSize, this.colors, this.offsetX, this.offsetY, this.newOffsetX, this.newOffsetY}) {

    position = Offset(this.offsetX, this.offsetY);

    Random random = new Random();
    this.x = random.nextDouble() * 100;
    this.y = random.nextDouble() * 100;

    animationController = new AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500)
    );

    translateXAnimation = Tween(begin: position.dx, end: x).animate(animationController);
    translateYAnimation = Tween(begin: position.dy, end: y).animate(animationController);
    negatetranslateXAnimation = Tween(begin: -1 * position.dx, end: -1 * x).animate(animationController);
    negatetranslateYAnimation = Tween(begin: -1 * position.dy, end: -1 * y).animate(animationController);
    fadingAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(animationController);

    particleSize = Tween(begin: 5.0, end: random.nextDouble() * 20).animate(animationController);

  }

  buildWidget() {


    animationController.forward();

    return new Container(
      alignment: FractionalOffset((newOffsetX/screenSize.width), (newOffsetY/screenSize.height)),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget widget){
          if(id % 4 == 0){
            return Transform.translate(
                offset: Offset(translateXAnimation.value, translateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value>5 ? particleSize.value : 5,
                    height: particleSize.value>5 ? particleSize.value : 5,
                    decoration: BoxDecoration(
                        color: colors,
                        shape: BoxShape.circle
                    ),
                  ),
                )
            );
          }else if(id % 4 == 1){
            return Transform.translate(
                offset: Offset(negatetranslateXAnimation.value, translateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value>5 ? particleSize.value : 5,
                    height: particleSize.value>5 ? particleSize.value : 5,
                    decoration: BoxDecoration(
                        color: colors,
                        shape: BoxShape.circle
                    ),
                  ),
                )
            );
          }else if(id % 4 == 2){
            return Transform.translate(
                offset: Offset(translateXAnimation.value, negatetranslateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value>5 ? particleSize.value : 5,
                    height: particleSize.value>5 ? particleSize.value : 5,
                    decoration: BoxDecoration(
                        color: colors,
                        shape: BoxShape.circle
                    ),
                  ),
                )
            );
          }else{
            return Transform.translate(
                offset: Offset(negatetranslateXAnimation.value, negatetranslateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value>5 ? particleSize.value : 5,
                    height: particleSize.value>5 ? particleSize.value : 5,
                    decoration: BoxDecoration(
                        color: colors,
                        shape: BoxShape.circle
                    ),
                  ),
                )
            );
          }
        },
      ),
    );

  }
}
