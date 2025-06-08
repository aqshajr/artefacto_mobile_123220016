class OwnedTicketResponse {
  final String status;
  final String message;
  final OwnedTicketData data;

  OwnedTicketResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OwnedTicketResponse.fromJson(Map<String, dynamic> json) {
    return OwnedTicketResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: OwnedTicketData.fromJson(json['data'] ?? {}),
    );
  }
}

class OwnedTicketByIdResponse {
  final String status;
  final String message;
  final OwnedTicketByIdData data;

  OwnedTicketByIdResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OwnedTicketByIdResponse.fromJson(Map<String, dynamic> json) {
    return OwnedTicketByIdResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: OwnedTicketByIdData.fromJson(json['data'] ?? {}),
    );
  }
}

class OwnedTicketData {
  final List<OwnedTicket> ownedTickets;

  OwnedTicketData({required this.ownedTickets});

  factory OwnedTicketData.fromJson(Map<String, dynamic> json) {
    return OwnedTicketData(
      ownedTickets: json['ownedTickets'] != null
          ? List<OwnedTicket>.from(json['ownedTickets']
              .map((ticket) => OwnedTicket.fromJson(ticket)))
          : [],
    );
  }
}

class OwnedTicketByIdData {
  final OwnedTicket ownedTicket;

  OwnedTicketByIdData({required this.ownedTicket});

  factory OwnedTicketByIdData.fromJson(Map<String, dynamic> json) {
    return OwnedTicketByIdData(
      ownedTicket: OwnedTicket.fromJson(json['ownedTicket'] ?? {}),
    );
  }
}

class OwnedTicket {
  final int ownedTicketID;
  final int userID;
  final int ticketID;
  final int transactionID;
  final String uniqueCode;
  final DateTime validDate;
  final String usageStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Ticket ticket;

  OwnedTicket({
    required this.ownedTicketID,
    required this.userID,
    required this.ticketID,
    required this.transactionID,
    required this.uniqueCode,
    required this.validDate,
    required this.usageStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.ticket,
  });

  factory OwnedTicket.fromJson(Map<String, dynamic> json) {
    return OwnedTicket(
      ownedTicketID: json['ownedTicketID'] ?? 0,
      userID: json['userID'] ?? 0,
      ticketID: json['ticketID'] ?? 0,
      transactionID: json['transactionID'] ?? 0,
      uniqueCode: json['uniqueCode'] ?? '',
      validDate: json['validDate'] != null
          ? DateTime.parse(json['validDate'])
          : DateTime.now(),
      usageStatus: json['usageStatus'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      ticket: json['Ticket'] != null
          ? Ticket.fromJson(json['Ticket'])
          : Ticket(
              price: 0.0,
              description: '',
              temple: Temple(title: '', location: ''),
            ),
    );
  }
}

class Ticket {
  final double price;
  final String description;
  final Temple temple;

  Ticket({
    required this.price,
    required this.description,
    required this.temple,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      price: json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      description: json['description'] ?? '',
      temple: json['Temple'] != null
          ? Temple.fromJson(json['Temple'])
          : Temple(title: '', location: ''),
    );
  }
}

class Temple {
  final String title;
  final String location;

  Temple({
    required this.title,
    required this.location,
  });

  factory Temple.fromJson(Map<String, dynamic> json) {
    return Temple(
      title: json['title'] ?? '',
      location: json['location'] ?? '',
    );
  }
}
