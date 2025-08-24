import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats shimmer
        Container(
          margin: const EdgeInsets.all(24),
          child: Row(
            children: List.generate(
              5,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 16 : 0),
                  child: _buildShimmerCard(height: 120),
                ),
              ),
            ),
          ),
        ),

        // Filter bar shimmer
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildShimmerCard(height: 80),
        ),

        // Issue cards shimmer
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildShimmerCard(height: 200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
