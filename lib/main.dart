import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isDataLoaded = false;
  List<AssetEntity> imageList = [];
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day - 1);
  DateTime endDate = DateTime.now();
  bool isEndDisabled = true;
  String status = "Please select start date and end date to show images!";

  Future<void> getAllImages() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    FilterOptionGroup filterOpt = new FilterOptionGroup(
      createTimeCond: DateTimeCond(min: startDate, max: endDate),
    );
   

    if (permitted.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
          onlyAll: true, type: RequestType.image, filterOption: filterOpt);
      if (albums.length == 0) {
        setState(() {
          status = "No Images found in the selected period ";
        });
        return;
      }
      final recentAlbum = albums.first;
      final recentAssets =
          await recentAlbum.getAssetListRange(start: 0, end: 100000000);
      setState(() {
        imageList = recentAssets;
        isDataLoaded = true;
      });
    } else {
      print("Permission denied..!");
    }
  }

  Future<void> getStartDate() async {
    final DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1980),
        lastDate: DateTime.now());
    if (date != null) {
      setState(() {
        startDate = date;
        isEndDisabled = false;
        print(date);
      });
    }
  }

  Future<void> getEndDate() async {
    final DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(startDate.year, startDate.month, startDate.day + 1),
        lastDate: DateTime.now());
    if (date != null) {
      setState(() {
        endDate = date;
        print(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FilterOption()
    // DateTimeCond.def()
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            "Gallery",
            style: TextStyle(fontSize: 24, color: Colors.black),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () async {
                                await getStartDate();
                              },
                              child: Text("start date", style: TextStyle(decoration: TextDecoration.underline),)),
                          TextButton(
                              onPressed: isEndDisabled
                                  ? null
                                  : () async {
                                      await getEndDate();
                                    },
                              child: Text("end date", style: TextStyle(decoration: TextDecoration.underline)))
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Center(
                          child: MaterialButton(
                            color: Colors.pink,
                            onPressed: () {
                              getAllImages();
                            },
                            child: Text("show photos", style: TextStyle(color: Colors.white),),
                          ),
                        ),
                      ),
                      isDataLoaded ? 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Start : ${startDate.day}/${startDate.month}/${startDate.year}"),
                          Text("End : ${endDate.day}/${endDate.month}/${startDate.year}"),
                      ],) : SizedBox(height: 0,)
                    ],
                  ),
                )
              ]),
            ),
            SliverList(
                delegate: SliverChildListDelegate([
              SizedBox(
                height: 50,
              )
            ])),
            !isDataLoaded
                ? SliverList(
                    delegate: SliverChildListDelegate([
                    Center(
                      child: Text(status),
                    )
                  ]))
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                      return (GestureDetector(
                        onTap: () {
                         
                        },
                        child: (Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            child: GridTile(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: AssetThumbnail(
                                    asset: imageList[index],
                                  )),
                            ))),
                      ));
                    }, childCount: imageList.length),
                  )
          ],
        ));
  }
}

class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    Key? key,
    required this.asset,
  }) : super(key: key);

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbData,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return Center(child: CircularProgressIndicator());
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }
}