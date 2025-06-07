import 'tiket_model.dart';

class OwnedTicket {
  final int ownedTicketID;
  final int userID;
  final int ticketID;
  final int transactionID;
  final String uniqueCode;
  String usageStatus;
  final DateTime validDate;
  final Ticket ticket;

  OwnedTicket({
    required this.ownedTicketID,
    required this.userID,
    required this.ticketID,
    required this.transactionID,
    required this.uniqueCode,
    required this.usageStatus,
    required this.validDate,
    required this.ticket,
  });

  factory OwnedTicket.fromJson(Map<String, dynamic> json) {
    return OwnedTicket(
      ownedTicketID: json['ownedTicketID'] is String
          ? int.parse(json['ownedTicketID'])
          : json['ownedTicketID'],
      userID:
          json['userID'] is String ? int.parse(json['userID']) : json['userID'],
      ticketID: json['ticketID'] is String
          ? int.parse(json['ticketID'])
          : json['ticketID'],
      transactionID: json['transactionID'] is String
          ? int.parse(json['transactionID'])
          : json['transactionID'],
      uniqueCode: json['uniqueCode'].toString(),
      usageStatus: json['usageStatus'].toString(),
      validDate: DateTime.parse(json['Transaction']['validDate']),
      ticket: Ticket.fromJson(json['Ticket']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownedTicketID': ownedTicketID,
      'userID': userID,
      'ticketID': ticketID,
      'transactionID': transactionID,
      'uniqueCode': uniqueCode,
      'usageStatus': usageStatus,
      'Transaction': {
        'validDate': validDate.toIso8601String(),
      },
      'Ticket': ticket.toJson(),
    };
  }
}
