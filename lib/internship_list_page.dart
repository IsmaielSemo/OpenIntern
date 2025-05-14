import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/internship.dart';
import 'ace_offer_page.dart';

class InternshipListPage extends StatelessWidget {
  const InternshipListPage({Key? key}) : super(key: key);

  Future<void> _toggleFavorite(String internshipId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final data = doc.data() ?? {};
    final favorites = List<String>.from(data['favorites'] ?? []);

    if (isFavorite) {
      favorites.remove(internshipId);
    } else {
      favorites.add(internshipId);
    }

    await userRef.update({'favorites': favorites});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('internships').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final internships = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Internship.fromJson(data);
        }).toList();

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
              : null,
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final favorites = List<String>.from(userData?['favorites'] ?? []);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: internships.length,
              itemBuilder: (context, index) {
                final internship = internships[index];
                final isFavorite = favorites.contains(internship.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(internship.title),
                    subtitle: Text(internship.company),
                    trailing: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(internship.id, isFavorite),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AceOfferPage(internship: internship),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
} 