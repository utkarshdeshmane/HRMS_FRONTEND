import 'package:flutter/material.dart';
import 'package:blinkit/repository/widgets/uihelper.dart';

class Printscreen extends StatefulWidget{
  State<Printscreen> createState()=>_PrintcreenState();
}
class _PrintcreenState extends State<Printscreen>{
  TextEditingController searchController = TextEditingController();
  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
      children: [
        SizedBox(height: 40,),

        Stack(
          children: [
            Container(
              height: 190,
              width: double.infinity,
              color: Color(0XFFF7CB45),
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Uihelper.CustomText(
                          text: "Blinkit in",
                          color: Color(0XFF000000),
                          fontWeight: FontWeight.bold,
                          fontsize: 15,
                          fontfamily: "bold"),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Uihelper.CustomText(
                          text: "16 minutes",
                          color: Color(0XFF000000),
                          fontWeight: FontWeight.bold,
                          fontsize: 20,
                          fontfamily: "bold")
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      Uihelper.CustomText(
                          text: "HOME ",
                          color: Color(0XFF000000),
                          fontWeight: FontWeight.bold,
                          fontsize: 14),
                      Uihelper.CustomText(
                          text: "- belgaum (Karnataka)",
                          color: Color(0XFF000000),
                          fontWeight: FontWeight.bold,
                          fontsize: 14)
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              bottom: 100,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
            Positioned(
                bottom: 30,
                left: 20,
                child: Uihelper.CustomTextField(controller: searchController))
          ],
        ),

        SizedBox(height: 60,),
        Uihelper.CustomText(text: "Print Store", color: Color(0XFF000000), fontWeight: FontWeight.bold, fontsize: 26,fontfamily: "bold"),
        SizedBox(height: 5,),
        Uihelper.CustomText(text: "Choose your preferred print store", color: Color(0XFF9C9C9C), fontWeight: FontWeight.normal, fontsize: 14),
        SizedBox(height:60),

        Padding(padding: EdgeInsets.all(20),
          child:Card(
          elevation: 7,
          child: Container(
          height: 200,
          width: double.infinity,
          color: Colors.white,
          
          child: Column(
            
            children:[
              SizedBox(width: 20,),
              
              Uihelper.CustomText(text: "Documents", color: Colors.black, fontWeight: FontWeight.bold, fontsize: 14),
              SizedBox(height: 10,),
              Uihelper.CustomImaege(imageName: "star.png"),
              SizedBox(width: 5,),
              
            ]
          ),
        ),),
        ),
      ],
      ),
    );
  }
}