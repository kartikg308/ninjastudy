import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ninjastudy/chat.dart';

void main() => runApp(const Home());

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeWidget(),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  Widget build(BuildContext context) {
    Timer.periodic(const Duration(seconds: 2), (t) {
      setState(() {});
    });
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 50,
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Hello! Kartik,",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Welcome I am Arya your personal AI english tutor",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const CustomContainer(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Conversation List",
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 600,
              child: chatHistory.isNotEmpty
                  ? const ConversationList()
                  : const Center(
                      child: Text(
                        "No Conversation",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationList extends StatefulWidget {
  const ConversationList({
    Key? key,
  }) : super(key: key);

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chatHistory.length,
      itemBuilder: (BuildContext context, int index) {
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {});
        });
        return ListTile(
          onTap: () {
            Get.to(() => Chatting(
                  index: index,
                  data: chatHistory[index],
                  isNew: false,
                ));
          },
          title: Text(
            "Conversation #${index + 1}",
            style: const TextStyle(
              fontSize: 25,
            ),
          ),
          subtitle: const Text(
            "How are you?",
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          trailing: IconButton(
            onPressed: () {
              chatHistory.removeAt(index);
              setState(() {});
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.chat,
            ),
          ),
        );
      },
    );
  }
}

class CustomContainer extends StatelessWidget {
  const CustomContainer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Get.to(() => Chatting(
                isNew: true,
                index: 0,
                data: chatHistory,
              ));
        },
        child: Container(
          height: 80,
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.blue[100],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Practice speaking with Arya",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.mic,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
