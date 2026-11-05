import 'package:flutter/material.dart';
import '../../../core/models/itinerary_place.dart';
import '../screens/place_edit_screen.dart';

class PlaceEditDialog extends StatelessWidget {
  final ItineraryPlace place;

  const PlaceEditDialog({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return PlaceEditScreen(place: place);
  }
}
