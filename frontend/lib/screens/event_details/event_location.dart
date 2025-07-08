import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/event_model.dart';

class EventLocation extends StatelessWidget {
  final Event event;
  final Set<Marker> markers;

  const EventLocation({super.key, required this.event, required this.markers});

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.location_on_rounded,
              color: const Color(0xFFE65100),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF27264A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = event.location != null && event.location!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            context,
            "Event Location",
            icon: Icons.place_rounded,
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFE65100).withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE65100).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Location text section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: hasLocation
                              ? const LinearGradient(
                                  colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF626C7A).withValues(alpha: 0.3),
                                    const Color(0xFF626C7A).withValues(alpha: 0.2),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: hasLocation
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE65100).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          hasLocation
                              ? Icons.place_rounded
                              : Icons.location_off_rounded,
                          color: hasLocation 
                              ? Colors.white 
                              : const Color(0xFF626C7A),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasLocation ? 'Address' : 'Location',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.location ?? 'No location specified',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: hasLocation
                                    ? const Color(0xFF27264A)
                                    : const Color(0xFF626C7A).withValues(alpha: 0.8),
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasLocation && markers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.directions_rounded,
                            color: const Color(0xFF2196F3),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),

                // Map section
                if (markers.isNotEmpty) ...[
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE65100).withValues(alpha: 0.1),
                          const Color(0xFFE65100).withValues(alpha: 0.3),
                          const Color(0xFFE65100).withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE65100).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 220,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: markers.first.position,
                            zoom: 15,
                          ),
                          markers: markers
                              .map(
                                (marker) => Marker(
                                  markerId: marker.markerId,
                                  position: marker.position,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueOrange,
                                  ),
                                ),
                              )
                              .toSet(),
                          onMapCreated: (controller) {
                            // Map controller not needed for this static display
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                          scrollGesturesEnabled: true,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                        ),
                      ),
                    ),
                  ),
                ] else if (hasLocation) ...[
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE65100).withValues(alpha: 0.1),
                          const Color(0xFFE65100).withValues(alpha: 0.3),
                          const Color(0xFFE65100).withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF626C7A).withValues(alpha: 0.05),
                            const Color(0xFF626C7A).withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF626C7A).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF626C7A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.map_outlined,
                                size: 32,
                                color: const Color(0xFF626C7A).withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Map not available',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
