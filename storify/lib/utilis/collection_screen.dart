import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _collectionNameController =
      TextEditingController();
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _fieldValueController = TextEditingController();

  String _selectedCollection = 'users';
  List<String> _collections = ['users', 'notifications'];
  Map<String, dynamic> _newDocument = {};

  @override
  void initState() {
    super.initState();
    _firestoreService.signInAnonymously();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    // Firestore client SDK does not support listing collections, so using default collection names.
    setState(() {
      _collections = ['users', 'notifications'];
      _selectedCollection = _collections[0];
    });
  }

  void _addField() {
    if (_fieldNameController.text.isNotEmpty &&
        _fieldValueController.text.isNotEmpty) {
      setState(() {
        _newDocument[_fieldNameController.text] = _fieldValueController.text;
        _fieldNameController.clear();
        _fieldValueController.clear();
      });
    }
  }

  Future<void> _addDocument() async {
    if (_selectedCollection.isNotEmpty && _newDocument.isNotEmpty) {
      try {
        await _firestore.collection(_selectedCollection).add({
          ..._newDocument,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _newDocument = {};
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document added successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding document: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _collectionNameController.dispose();
    _fieldNameController.dispose();
    _fieldValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firebase Collections',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _collectionNameController,
                  decoration: const InputDecoration(
                    labelText: 'New Collection Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (_collectionNameController.text.isNotEmpty) {
                    try {
                      // Create a document in the new collection to ensure it exists
                      await _firestore
                          .collection(_collectionNameController.text)
                          .add({
                        'created': FieldValue.serverTimestamp(),
                      });

                      await _loadCollections();
                      setState(() {
                        _selectedCollection = _collectionNameController.text;
                        _collectionNameController.clear();
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Collection created successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error creating collection: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Collection',
              border: OutlineInputBorder(),
            ),
            value: _selectedCollection,
            items: _collections.map((String collection) {
              return DropdownMenuItem<String>(
                value: collection,
                child: Text(collection),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCollection = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Collection Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection(_selectedCollection).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No documents in this collection'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text('Document ID: ${doc.id}'),
                        children: data.entries.map<Widget>((entry) {
                          return ListTile(
                            title: Text(entry.key),
                            subtitle: Text(entry.value.toString()),
                          );
                        }).toList(),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _firestore
                                .collection(_selectedCollection)
                                .doc(doc.id)
                                .delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
