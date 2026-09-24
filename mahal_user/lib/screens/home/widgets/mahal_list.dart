import 'package:flutter/material.dart';
import '../../../models/mahal_model.dart';
import '../../../services/mahal_service.dart';
import 'mahal_card.dart';

class MahalList extends StatefulWidget {
  final String searchQuery;

  const MahalList({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<MahalList> createState() => _MahalListState();
}

class _MahalListState extends State<MahalList> {
  final MahalService _mahalService = MahalService();
  List<MahalModel> _mahals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMahals();
  }

  void _fetchMahals() async {
    final mahals = await _mahalService.getAllMahals();
    if (!mounted) return;
    setState(() {
      _mahals = mahals;
      _isLoading = false;
    });
  }

  List<MahalModel> get _filteredMahals {
    final query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _mahals;
    }

    return _mahals.where((mahal) {
      final searchableText = '${mahal.mahalName} ${mahal.location} ${mahal.price}'.toLowerCase();
      return searchableText.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredMahals = _filteredMahals;
    if (filteredMahals.isEmpty) {
      return const Center(child: Text("No Mahals found."));
    }

    return ListView.builder(
      itemCount: filteredMahals.length,
      itemBuilder: (context, index) {
        return MahalCard(mahal: filteredMahals[index]);
      },
    );
  }
}

