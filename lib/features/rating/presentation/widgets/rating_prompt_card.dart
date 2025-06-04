import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:swapparel/app/config/theme/app_theme.dart';
import '../provider/rating_provider.dart';

class RatingPromptCard extends StatefulWidget {
  final String matchId;
  final String offerId;
  final String ratingUserId; 
  final String userToRateId;
  final String? userToRateName;


  const RatingPromptCard({
    super.key,
    required this.matchId,
    required this.offerId,
    required this.ratingUserId,
    required this.userToRateId,
    this.userToRateName,
  });

  @override
  State<RatingPromptCard> createState() => _RatingPromptCardState();
}

class _RatingPromptCardState extends State<RatingPromptCard> {
  double _currentRating =
      0.0; 
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _submitRating() async {
    if (_currentRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona al menos una estrella."),
           backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    print(
      "RatingPromptCard: Enviando valoración de ${widget.ratingUserId} para ${widget.userToRateId} (Match: ${widget.matchId}, Offer: ${widget.offerId}) - Rating: $_currentRating, Comment: ${_commentController.text.trim()}",
    );

    bool success = await context.read<RatingProvider>().submitRating(
      matchId: widget.matchId,
      offerId: widget.offerId,
      ratedUserId: widget.userToRateId,
      stars: _currentRating,
      comment: _commentController.text.trim(),
      ratedUserName: widget.userToRateName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Gracias por tu valoración!"),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al enviar la valoración."),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Intercambio completado con ${widget.userToRateName}",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text("¡Valora tu experiencia!", style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Center(
            child: RatingBar.builder(
              initialRating: _currentRating,
              minRating: 1,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder:
                  (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: "Añade un comentario (opcional)",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed:
                  _isSubmitting || _currentRating == 0.0 ? null : _submitRating,
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text("Enviar Valoración"),
            ),
          ),
        ],
      ),
    );
  }
}
