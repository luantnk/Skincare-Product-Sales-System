import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shopsmart_users_en/services/jwt_service.dart';
import 'package:flutter/services.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> addresses = [];

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    setState(() {
      isLoading = true;
    });
    final token = await JwtService.getStoredToken();
    final res = await http.get(
      Uri.parse(
        'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net/api/addresses/user?pageNumber=1&pageSize=10',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      addresses = (data['data']['items'] as List).cast<Map<String, dynamic>>();
    }
    setState(() {
      isLoading = false;
    });
  }

  void showAddressForm({Map<String, dynamic>? address}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => AddressForm(address: address, onSuccess: fetchAddresses),
    );
    if (result == true) fetchAddresses();
  }

  Future<void> deleteAddress(String id) async {
    final token = await JwtService.getStoredToken();
    final res = await http.delete(
      Uri.parse(
        'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net/api/addresses/$id',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      fetchAddresses();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa địa chỉ.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa thất bại!')));
    }
  }

  Future<void> setDefault(String id) async {
    final token = await JwtService.getStoredToken();
    final res = await http.patch(
      Uri.parse(
        'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net/api/addresses/$id/set-default',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      fetchAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đặt làm địa chỉ mặc định.')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thao tác thất bại!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Địa chỉ của tôi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddressForm(),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text(
          'Thêm địa chỉ mới',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : addresses.isEmpty
              ? const Center(child: Text('Bạn chưa có địa chỉ nào.'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final addr = addresses[idx];
                  return AddressCard(
                    address: addr,
                    onEdit: () => showAddressForm(address: addr),
                    onDelete: () => deleteAddress(addr['id']),
                    onSetDefault:
                        addr['isDefault'] == true
                            ? null
                            : () => setDefault(addr['id']),
                  );
                },
              ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;
  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8) ??
        Colors.grey[700];
    final cardBg = Theme.of(context).cardColor;
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cardBg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: primaryColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address['customerName'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ),
                if (address['isDefault'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Địa chỉ mặc định',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              address['phoneNumber'] ?? '',
              style: TextStyle(fontSize: 15, color: subTextColor),
            ),
            const SizedBox(height: 4),
            Text(
              _fullAddress(address),
              style: TextStyle(fontSize: 15, color: subTextColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            if (onSetDefault != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: onSetDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(color: primaryColor),
                  ),
                  child: const Text('Đặt làm mặc định'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fullAddress(Map<String, dynamic> a) {
    return [
      a['streetNumber'],
      a['addressLine1'],
      a['addressLine2'],
      a['ward'],
      a['city'],
      a['province'],
      a['countryName'],
      a['postCode'] ?? a['postcode'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
  }
}

class AddressForm extends StatefulWidget {
  final Map<String, dynamic>? address;
  final VoidCallback onSuccess;
  const AddressForm({super.key, this.address, required this.onSuccess});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _ctrl;
  bool isDefault = false;
  bool isLoading = false;
  bool _addressListEmpty = true;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _ctrl = {
      'customerName': TextEditingController(text: a?['customerName'] ?? ''),
      'phoneNumber': TextEditingController(text: a?['phoneNumber'] ?? ''),
      'streetNumber': TextEditingController(text: a?['streetNumber'] ?? ''),
      'addressLine1': TextEditingController(text: a?['addressLine1'] ?? ''),
      'addressLine2': TextEditingController(text: a?['addressLine2'] ?? ''),
      'city': TextEditingController(text: a?['city'] ?? ''),
      'ward': TextEditingController(text: a?['ward'] ?? ''),
      'postcode': TextEditingController(
        text: a?['postCode'] ?? a?['postcode'] ?? '',
      ),
      'province': TextEditingController(text: a?['province'] ?? ''),
      'countryName': TextEditingController(text: a?['countryName'] ?? ''),
    };

    if (a != null) {
      isDefault = a['isDefault'] ?? false;
    } else {
      _checkAddressListEmpty();
    }
  }

  Future<void> _checkAddressListEmpty() async {
    final token = await JwtService.getStoredToken();
    final res = await http.get(
      Uri.parse(
        'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net/api/addresses/user?pageNumber=1&pageSize=1',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = data['data']['items'] as List;

      if (mounted) {
        setState(() {
          _addressListEmpty = items.isEmpty;
          if (_addressListEmpty) {
            isDefault = true;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
    });
    final token = await JwtService.getStoredToken();
    final body = {
      'customerName': _ctrl['customerName']!.text,
      'phoneNumber': _ctrl['phoneNumber']!.text,
      'streetNumber': _ctrl['streetNumber']!.text,
      'addressLine1': _ctrl['addressLine1']!.text,
      'addressLine2': _ctrl['addressLine2']!.text,
      'city': _ctrl['city']!.text,
      'ward': _ctrl['ward']!.text,
      'postcode': _ctrl['postcode']!.text,
      'province': _ctrl['province']!.text,
      'countryId': 1, // mặc định Việt Nam
      'isDefault': isDefault,
    };
    http.Response res;
    if (widget.address == null) {
      res = await http.post(
        Uri.parse(
          'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net/api/addresses',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
    } else {
      res = await http.patch(
        Uri.parse(
          'https://spssapi-hxfzbchrcafgd2hg.southeastasia-01.azurewebsites.net/api/addresses/${widget.address!['id']}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
    }
    setState(() {
      isLoading = false;
    });
    if (res.statusCode == 200 || res.statusCode == 201) {
      widget.onSuccess();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu địa chỉ thành công!')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu địa chỉ thất bại!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.address == null ? 'Thêm địa chỉ mới' : 'Sửa địa chỉ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  'customerName',
                  'Tên khách hàng *',
                  Icons.person,
                ),
                _buildTextField('phoneNumber', 'Số điện thoại *', Icons.phone),
                _buildTextField('streetNumber', 'Số nhà *', Icons.home),
                _buildTextField('addressLine1', 'Đường *', Icons.location_on),
                _buildTextField(
                  'addressLine2',
                  'Địa chỉ chi tiết (tùy chọn)',
                  Icons.location_on_outlined,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'ward',
                        'Phường/Xã *',
                        Icons.apartment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'city',
                        'Quận/Huyện *',
                        Icons.location_city,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'province',
                        'Tỉnh/Thành phố *',
                        Icons.map,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        'postcode',
                        'Mã bưu điện',
                        Icons.markunread_mailbox,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isDefault,
                      onChanged: (v) => setState(() => isDefault = v ?? false),
                      activeColor: primaryColor,
                    ),
                    const Text('Đặt làm địa chỉ mặc định'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                widget.address == null
                                    ? 'Thêm địa chỉ'
                                    : 'Cập nhật',
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String key, String label, IconData icon) {
    final isPhone = key == 'phoneNumber';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _ctrl[key],
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: isPhone ? TextInputType.phone : null,
            inputFormatters:
                isPhone
                    ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]
                    : null,
            autovalidateMode:
                isPhone ? AutovalidateMode.onUserInteraction : null,
            onChanged: isPhone ? (value) => setState(() {}) : null,
            validator: (val) {
              if (label.contains('*') && (val == null || val.isEmpty)) {
                return 'Trường này là bắt buộc';
              }
              if (isPhone &&
                  val != null &&
                  val.isNotEmpty &&
                  !RegExp(r'^0\d{9,10}\u0000?$').hasMatch(val.trim())) {
                return 'Số điện thoại phải có 10 hoặc 11 chữ số';
              }
              return null;
            },
          ),
          if (isPhone && _ctrl[key]!.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  Icon(
                    RegExp(
                          r'^0\d{9,10}\u0000?$',
                        ).hasMatch(_ctrl[key]!.text.trim())
                        ? Icons.check_circle
                        : Icons.cancel,
                    color:
                        RegExp(
                              r'^0\d{9,10}\u0000?$',
                            ).hasMatch(_ctrl[key]!.text.trim())
                            ? Colors.green
                            : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    RegExp(
                          r'^0\d{9,10}\u0000?$',
                        ).hasMatch(_ctrl[key]!.text.trim())
                        ? 'Số điện thoại hợp lệ'
                        : 'Số điện thoại phải có 10 hoặc 11 chữ số',
                    style: TextStyle(
                      color:
                          RegExp(
                                r'^0\d{9,10}\u0000?$',
                              ).hasMatch(_ctrl[key]!.text.trim())
                              ? Colors.green
                              : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
