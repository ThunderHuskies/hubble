import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hubble_client/messaging/chat.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';

import '../home/EditProfile.dart';
import '../home/Profile.dart';

Future<List<MatchRating>> findMatches(String uid) async {
  List<MatchRating> matchList = [];
  final response = await http.post(
    Uri.parse(
        'https://us-central1-c-students-b7a3d.cloudfunctions.net/findMatches'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(<String, String>{
      'uid': uid,
    }),
  );

  if (response.statusCode == 200) {
    var jsonList = jsonDecode(response.body);
    for (var match in jsonList) {
      matchList.add(MatchRating.fromJson(match));
    }
    return matchList;
  } else {
    throw Exception("failed");
  }
}

class MatchRating {
  final String? id;
  final double? rating;

  MatchRating({
    this.id,
    this.rating,
  });

  factory MatchRating.fromJson(Map<String, dynamic> json) {
    return MatchRating(
      id: json['uid'],
      rating: json['rating'].toDouble(),
    );
  }
}

class Home extends StatefulWidget {
  final User? user;
  Home({Key? key, @required this.user}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Home> {
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      UserCard(user: widget.user),
      Connections(user: widget.user),
      AccountPage(user: widget.user),
    ];
    return Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Connections',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded),
              label: 'Account',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onNavTapped,
        ));
  }
}

class UserCard extends StatelessWidget {
  final User? user;
  UserCard({this.user});
  // Home page
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Home',
        home: Scaffold(
          appBar: AppBar(
              title: Image.asset("assets/images/plane.png", scale: 16),
              bottomOpacity: 0,
              backgroundColor: Colors.white,
              toolbarHeight: 75.0,
              elevation: 0.0),
          body: UserCards(user: user),
        ));
  }
}

class UserCards extends StatefulWidget {
  final User? user;
  UserCards({this.user});

  @override
  State<StatefulWidget> createState() {
    return UserCardsState();
  }
}

class UserCardsState extends State<UserCards> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<List<MatchRating>>(
      future: findMatches(widget.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("${snapshot.error}");
        } else if (snapshot.hasData) {
          List<MatchRating> matchData = snapshot.data!;
          List<String> userUID = [];
          userUID.add(widget.user!.uid);
          return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where(FieldPath.documentId, whereNotIn: userUID)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError)
                  return new Center(child: Text('${snapshot.error}'));
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return new Center(child: new CircularProgressIndicator());
                  default:
                    if (!snapshot.hasData) {
                      return new Center(child: Text('No one...yet...'));
                    }
                    int n = -1;
                    List<Widget> widgetList =
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      n++;
                      return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context2) => Profile(
                                        document: document,
                                      ),
                                    ));
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              document.data()!['image']),
                                          fit: BoxFit.cover,
                                        )),
                                  ),
                                  Container(
                                      alignment: Alignment.bottomCenter,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            Colors.black.withAlpha(10),
                                            Colors.black12,
                                            Colors.black54
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(children: [
                                                    Container(
                                                        child: Text(
                                                      document.data()!['name'],
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'Open Sans',
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 25.0),
                                                    )),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(2.5),
                                                    ),
                                                    Text(
                                                      () {
                                                        if (matchData[n]
                                                                .rating! <
                                                            2) {
                                                          return "😃";
                                                        } else if (matchData[n]
                                                                .rating! <
                                                            4) {
                                                          return "😆";
                                                        } else {
                                                          return "🤩";
                                                        }
                                                      }(),
                                                      style: TextStyle(
                                                          fontSize: 25.0),
                                                    ),
                                                  ]),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(2.5),
                                                  ),
                                                  Text(
                                                      document.data()!['major'],
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      )),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(1.0),
                                                  ),
                                                  Text(
                                                      document
                                                          .data()!['yearLevel'],
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      )),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(20.0),
                                                  ),
                                                ]),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                    decoration: ShapeDecoration(
                                                      color: Colors.white,
                                                      shape: CircleBorder(),
                                                    ),
                                                    child: Transform.rotate(
                                                      angle: -(math.pi / 5.0),
                                                      child: IconButton(
                                                          iconSize: 30.0,
                                                          icon: const Icon(Icons
                                                              .insert_link_rounded),
                                                          onPressed: () {
                                                            var listid = [
                                                              document.id
                                                            ];
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    "users")
                                                                .doc(widget
                                                                    .user!.uid)
                                                                .update({
                                                                  'connections':
                                                                      FieldValue
                                                                          .arrayUnion(
                                                                              listid)
                                                                })
                                                                .then((value) =>
                                                                    print(
                                                                        "User Updated"))
                                                                .catchError(
                                                                    (error) =>
                                                                        print(
                                                                            "Failed to update user: $error"));
                                                          }),
                                                    )),
                                                Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                ),
                                              ],
                                            )
                                          ])),
                                ],
                              )));
                    }).toList();
                    return Column(children: [
                      CarouselSlider(
                          options: CarouselOptions(
                            height: 690,
                            enlargeCenterPage: true,
                          ),
                          items: widgetList)
                    ]);
                }
              });
        }
        return Center(child: CircularProgressIndicator());
      },
    ));
  }
}

class Connections extends StatefulWidget {
  final User? user;

  Connections({this.user});
  @override
  _ConnectionsState createState() => _ConnectionsState();
}

class _ConnectionsState extends State<Connections> {
  @override
  Widget build(BuildContext context) {
    Future<List> getConnectionsList() async {
      var connectionList = [];
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user!.uid)
          .get()
          .then((DocumentSnapshot document) {
        connectionList = document.data()!['connections'];
      });
      return connectionList;
    }

    return CupertinoPageScaffold(
        child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                CupertinoSliverNavigationBar(
                  automaticallyImplyLeading: false,
                  largeTitle: Text("Connections"),
                ),
              ];
            },
            body: FutureBuilder<List>(
              future: getConnectionsList(),
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.hasData) {
                  return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .where(FieldPath.documentId, whereIn: snapshot.data)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError)
                          return new Center(child: Text('${snapshot.error}'));
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                          case ConnectionState.waiting:
                            return new Center(
                                child: new CircularProgressIndicator());
                          default:
                            if (!snapshot.hasData) {
                              return new Center(child: Text('No matches!'));
                            }
                            return ListView(
                              children: snapshot.data!.docs
                                  .map((DocumentSnapshot document) {
                                return Card(
                                    child: InkWell(
                                        splashColor: Colors.blue.withAlpha(30),
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Chat(
                                                  user: widget.user,
                                                  friend:
                                                      document.data()!['uid'],
                                                ),
                                              ));
                                        },
                                        child: Column(children: <Widget>[
                                          ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  document.data()!['image']),
                                            ),
                                            title:
                                                Text(document.data()!['name']),
                                            subtitle:
                                                Text(document.data()!['major']),
                                            trailing: Icon(Icons
                                                .arrow_forward_ios_rounded),
                                          )
                                        ])));
                              }).toList(),
                            );
                        }
                      });
                }
                return Center(child: CircularProgressIndicator());
              },
            )));
  }
}

class AccountPage extends StatelessWidget {
  final User? user;

  AccountPage({this.user});
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                CupertinoSliverNavigationBar(
                  automaticallyImplyLeading: false,
                  largeTitle: Text("My Account"),
                ),
              ];
            },
            body: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(user!.uid)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError)
                    return new Center(child: Text('${snapshot.error}'));
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return new Center(child: new CircularProgressIndicator());
                    default:
                      if (!snapshot.hasData) {
                        return new Center(child: Text('No account?'));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(15.0),
                              ),
                              CircleAvatar(
                                radius: 75,
                                backgroundImage:
                                    NetworkImage(snapshot.data!['image']),
                              ),
                              Padding(
                                padding: EdgeInsets.all(10.0),
                              ),
                              Text(
                                snapshot.data!['name'],
                                style: TextStyle(fontSize: 30),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5.0),
                              ),
                              Text(snapshot.data!['major'],
                                  style: TextStyle(fontSize: 15)),
                              Padding(
                                padding: EdgeInsets.all(2.0),
                              ),
                              Text(snapshot.data!['yearLevel']),
                              Padding(
                                padding: EdgeInsets.all(2.0),
                              ),
                              Text("University of British Columbia"),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.all(30.0),
                          ),
                          Row(children: [
                            Flexible(
                                child: Card(
                                    child: InkWell(
                              splashColor: Colors.blue.withAlpha(30),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProfile(snapshot: snapshot.data!),
                                  )),
                              child: ListTile(
                                  title: Text("Edit Profile"),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                  )),
                            ))),
                          ]),
                          Flexible(
                            child: Card(
                                child: ListTile(
                              title: Text("Change Password"),
                              trailing: Icon(Icons.arrow_forward_ios_rounded),
                            )),
                          ),
                          Flexible(
                            child: Card(
                                child: ListTile(
                              title: Text("Change Schools"),
                              trailing: Icon(Icons.arrow_forward_ios_rounded),
                            )),
                          ),
                          Flexible(
                              child: Card(
                            child: ListTile(
                                title: Text("Sign Out"),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                )),
                          )),
                        ],
                      );
                  }
                })));
  }
}
