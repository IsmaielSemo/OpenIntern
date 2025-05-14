import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/internship.dart';
import 'ace_offer_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your favorites'),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final favoriteIds = List<String>.from(userData?['favorites'] ?? []);

        if (favoriteIds.isEmpty) {
          return const Center(
            child: Text('No favorites yet'),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('internships')
              .where(FieldPath.documentId, whereIn: favoriteIds)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final internships = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Internship.fromJson(data);
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: internships.length,
              itemBuilder: (context, index) {
                final internship = internships[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(internship.title),
                    subtitle: Text(internship.company),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () async {
                        // Remove from favorites
                        final favorites = List<String>.from(userData?['favorites'] ?? []);
                        favorites.remove(internship.id);
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'favorites': favorites});
                      },
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