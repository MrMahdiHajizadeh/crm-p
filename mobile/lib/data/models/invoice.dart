import 'package:flutter/material.dart';

/// Invoice status enumeration matching backend STATUS_CHOICES
enum InvoiceStatus {
  draft('Draft', 'Draft', Icons.edit_note),
  sent('Sent', 'Sent', Icons.send),
  viewed('Viewed', 'Viewed', Icons.visibility),
  paid('Paid', 'Paid', Icons.check_circle),
  partiallyPaid('Partially_Paid', 'Partially Paid', Icons.payment),
  overdue('Overdue', 'Overdue', Icons.warning),
  pending('Pending', 'Pending', Icons.schedule),
  cancelled('Cancelled', 'Cancelled', Icons.cancel);

  final String value;
  final String label;
  final IconData icon;

  const InvoiceStatus(this.value, this.label, this.icon);

  static InvoiceStatus fromString(String? value) {
    if (value == null) return InvoiceStatus.draft;
    return InvoiceStatus.values.firstWhere(
      (s) => s.value.toLowerCase() == value.toLowerCase().replaceAll(' ', '_'),
      orElse: () => InvoiceStatus.draft,
    );
  }
}

/// Payment terms enumeration
enum PaymentTerms {
  dueOnReceipt('DUE_ON_RECEIPT', 'Due on Receipt'),
  net15('NET_15', 'Net 15'),
  net30('NET_30', 'Net 30'),
  net45('NET_45', 'Net 45'),
  net60('NET_60', 'Net 60'),
  custom('CUSTOM', 'Custom');

  final String value;
  final String label;
  const PaymentTerms(this.value, this.label);

  static PaymentTerms fromString(String? value) {
    if (value == null) return PaymentTerms.net30;
    return PaymentTerms.values.firstWhere(
      (p) => p.value == value,
      orElse: () => PaymentTerms.net30,
    );
  }
}

/// Invoice model (list-level, matching InvoiceListSerializer)
class Invoice {
  final String id;
  final String invoiceNumber;
  final String invoiceTitle;
  final InvoiceStatus status;
  final String? accountId;
  final String? accountName;
  final String? contactId;
  final String? contactName;
  final String clientName;
  final String clientEmail;
  final DateTime issueDate;
  final DateTime? dueDate;
  final double totalAmount;
  final double amountDue;
  final double amountPaid;
  final String currency;
  final bool isOverdue;
  final int lineItemsCount;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceTitle,
    required this.status,
    this.accountId,
    this.accountName,
    this.contactId,
    this.contactName,
    required this.clientName,
    required this.clientEmail,
    required this.issueDate,
    this.dueDate,
    required this.totalAmount,
    required this.amountDue,
    required this.amountPaid,
    required this.currency,
    this.isOverdue = false,
    this.lineItemsCount = 0,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    String? accountId;
    String? accountName;
    if (json['account'] is Map<String, dynamic>) {
      accountId = (json['account'] as Map<String, dynamic>)['id']?.toString();
      accountName = (json['account'] as Map<String, dynamic>)['name'] as String?;
    } else if (json['account'] is String) {
      accountId = json['account'] as String;
    }
    accountName ??= json['account_name'] as String?;

    String? contactId;
    String? contactName;
    if (json['contact'] is Map<String, dynamic>) {
      contactId = (json['contact'] as Map<String, dynamic>)['id']?.toString();
      contactName = (json['contact'] as Map<String, dynamic>)['name'] as String?;
    } else if (json['contact'] is String) {
      contactId = json['contact'] as String;
    }
    contactName ??= json['contact_name'] as String?;

    double parseAmount(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      invoiceTitle: json['invoice_title'] as String? ?? '',
      status: InvoiceStatus.fromString(json['status'] as String?),
      accountId: accountId,
      accountName: accountName,
      contactId: contactId,
      contactName: contactName,
      clientName: json['client_name'] as String? ?? '',
      clientEmail: json['client_email'] as String? ?? '',
      issueDate: DateTime.tryParse(json['issue_date']?.toString() ?? '') ?? DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      totalAmount: parseAmount(json['total_amount']),
      amountDue: parseAmount(json['amount_due']),
      amountPaid: parseAmount(json['amount_paid']),
      currency: json['currency'] as String? ?? 'USD',
      isOverdue: json['is_overdue'] as bool? ?? false,
      lineItemsCount: json['line_items_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_title': invoiceTitle,
      'status': status.value,
      'client_name': clientName,
      'client_email': clientEmail,
      'account': accountId,
      'contact': contactId,
      'issue_date':
          '${issueDate.year}-${issueDate.month.toString().padLeft(2, '0')}-${issueDate.day.toString().padLeft(2, '0')}',
      if (dueDate != null)
        'due_date':
            '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
      'currency': currency,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Invoice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
