import 'package:flutter/material.dart';
import '../sidebar/hrms_sidebar.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Color(0xffF5F6FA),
      drawer: HRMSSidebar(),

      // TOP APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        title: Text("HRMS Dashboard",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),

      // MAIN CONTENT
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------
            // HEADER STATISTICS
            // -------------------------------
            AnimatedOpacity(
              opacity: 1,
              duration: Duration(milliseconds: 800),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _statCard("New Joining Today", "0", Colors.green),
                  _statCard("New Joining This Week", "0", Colors.orange),
                  _statCard("Total Strength", "92", Colors.blue),
                ],
              ),
            ),

            SizedBox(height: 25),

            // -------------------------------
            // GRID LAYOUT CONTENT
            // -------------------------------
            isMobile
                ? Column(
                    children: [
                      _block(_attendanceAnalytics()),
                      SizedBox(height: 20),
                      _block(_overtimeToApprove()),
                      SizedBox(height: 20),
                      _block(_upcomingBirthday()),
                      SizedBox(height: 20),
                      _block(_announcements()),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT SIDE (LARGE)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _block(_attendanceAnalytics()),
                            SizedBox(height: 20),
                            _block(_overtimeToApprove()),
                          ],
                        ),
                      ),

                      SizedBox(width: 20),

                      // RIGHT SIDE (SMALL)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _block(_upcomingBirthday()),
                            SizedBox(height: 20),
                            _block(_announcements()),
                          ],
                        ),
                      )
                    ],
                  )
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER STAT CARD
  // ----------------------------------------------------------
  Widget _statCard(String title, String value, Color color) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(20),
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, color: Colors.black54)),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // REUSABLE BLOCK CARD
  // ----------------------------------------------------------
  Widget _block(Widget child) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 700),
      curve: Curves.fastOutSlowIn,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }

  // ----------------------------------------------------------
  // ATTENDANCE ANALYTICS (Dummy Graph)
  // ----------------------------------------------------------
  Widget _attendanceAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Attendance Analytics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        Row(
          children: [
            _bar(80, Colors.blue),
            SizedBox(width: 10),
            _bar(110, Colors.green),
            SizedBox(width: 10),
            _bar(60, Colors.orange),
            SizedBox(width: 10),
            _bar(90, Colors.red),
          ],
        )
      ],
    );
  }

  Widget _bar(double height, Color color) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      width: 35,
      height: height + 50,
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        width: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // OVERTIME APPROVAL
  // ----------------------------------------------------------
  Widget _overtimeToApprove() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Overtime To Approve",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        _approvalTile("Jérémy Cotte", "00:44"),
        _approvalTile("Ravi", "02:00"),
        _approvalTile("Rohit", "02:00"),
      ],
    );
  }

  Widget _approvalTile(String name, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: Colors.grey.shade300),
      title: Text(name),
      subtitle: Text("Overtime: $time"),
      trailing: Icon(Icons.check_circle, color: Colors.green),
    );
  }

  // ----------------------------------------------------------
  // UPCOMING BIRTHDAY
  // ----------------------------------------------------------
  Widget _upcomingBirthday() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Birthday",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        ListTile(
          leading: CircleAvatar(radius: 25, backgroundColor: Colors.orange),
          title: Text("Sahil Sharma"),
          subtitle: Text("22 Nov, Today"),
        )
      ],
    );
  }

  // ----------------------------------------------------------
  // ANNOUNCEMENTS
  // ----------------------------------------------------------
  Widget _announcements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Announcements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text("H", style: TextStyle(color: Colors.blue))),
          title: Text("HRMS Tour"),
          trailing: Icon(Icons.info_outline),
        ),
      ],
    );
  }
}
