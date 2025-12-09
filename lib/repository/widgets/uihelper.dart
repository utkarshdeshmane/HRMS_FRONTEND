import 'package:flutter/material.dart';

class Uihelper {
  static CustomImaege({
  required String imageName,
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.asset(
    'assets/images/$imageName',
    height: height,
    width: width,
    fit: fit,
  );
}

  static CustomText({required String text,required Color color,required FontWeight fontWeight,String? fontfamily,required double fontsize})
{
  return Text(
    text,
    style: TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontFamily: fontfamily?? "regular",
      fontSize: fontsize,
    ),

  
  );
}

static CustomButton(VoidCallback callback){
    return Container(
      height: 18,
      width: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Color(0XFF27AF34)
        ),
        borderRadius: BorderRadius.circular(4)
      ),
      child: Center(child: Text("Add",style: TextStyle(fontSize: 8,color: Color(0XFF27AF34)),),),
    );
  }

    static CustomTextField({required TextEditingController controller}){
    return Container(
      height: 40,
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(
          color: Color(0XFFC5C5C5)
        )
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Search 'ice-cream'",
          prefixIcon: Image.asset("assets/images/search.png"),
          suffixIcon: Image.asset("assets/images/mic1.png"),
          border: InputBorder.none
        ),
      ),
    );
  }
}

