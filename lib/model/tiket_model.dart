import 'temple_model.dart';

class TicketRequest {
  final int templeID;
  final double price;
  final String description;

  TicketRequest({
    required this.templeID,
    required this.price,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'templeID': templeID,
      'price': price,
      'description': description,
    };
  }
}

class TicketResponse {
  final String status;
  final String? message;
  final TicketData? data;

  TicketResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? TicketData.fromJson(json['data']) : null,
    );
  }
}

class TicketError {
  String? param;
  String? msg;

  TicketError({this.param, this.msg});

  TicketError.fromJson(Map<String, dynamic> json) {
    param = json['param'];
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    return {
      'param': param,
      'msg': msg,
    };
  }
}

class TicketData {
  final List<Ticket>? tickets;
  final Ticket? ticket;

  TicketData({
    this.tickets,
    this.ticket,
  });

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      tickets: json['tickets'] != null
          ? List<Ticket>.from(json['tickets'].map((x) => Ticket.fromJson(x)))
          : null,
      ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    if (tickets != null) {
      result['tickets'] = tickets!.map((v) => v.toJson()).toList();
    }
    if (ticket != null) {
      result['ticket'] = ticket!.toJson();
    }
    return result;
  }
}

class Ticket {
  final int? ticketID;
  final int? templeID;
  final double? price;
  final String? description;
  final Temple? temple;

  Ticket({
    this.ticketID,
    this.templeID,
    this.price,
    this.description,
    this.temple,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Handle price parsing
    double? parsePrice(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        // Remove any currency symbols and whitespace
        final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleanValue);
      }
      return null;
    }

    return Ticket(
      ticketID: json['ticketID'],
      templeID: json['templeID'],
      price: parsePrice(json['price']),
      description: json['description'],
      temple: json['Temple'] != null
          ? Temple.fromJson(json['Temple'])
          : (json['temple'] != null ? Temple.fromJson(json['temple']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketID': ticketID,
      'templeID': templeID,
      'price': price,
      'description': description,
      'temple': temple?.toJson(),
    };
  }
}
